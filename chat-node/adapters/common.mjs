// chat-node/adapters/common.mjs -- what every waker adapter shares.
//
// The contract is one sentence: WAIT WITHOUT SPENDING MODEL TOKENS, AND TURN AN ARRIVING MESSAGE
// INTO A TURN. Everything below is the part of that which is the same on every host. What differs
// per host -- the payload it sends, the shape it expects back, and the signal it offers for
// re-entry -- lives in the per-host file and nowhere else, because the moment shared code branches
// on which host it is serving, "only the adapter differs" stops being true.
//
// Five rules came out of the P0 spike and four of them are implemented here. Rule 4 (the host's
// documented shape) is the one that cannot be shared, by definition.

import { readFileSync } from 'node:fs';
import { UNKNOWN_TIMEOUT_BLOCK_MS } from '../server/waiters.mjs';
import { limits } from '../server/settings.mjs';
import { request } from 'node:http';

// --- Rule 4, the half that IS shared: tolerate a byte-order mark ------------
//
// RFC 8259 does not permit a BOM in JSON, so a strict parser rejects an otherwise valid document
// at its FIRST character and reports it as malformed -- an error that points at the payload when
// the problem is the encoding. One host prefixes its stdin payload with one. This is a real
// interoperability constraint and not a spike artefact, so every adapter decodes this way whether
// its own host is known to send a BOM or not: an adapter that tolerates it costs nothing, and one
// that does not fails in a way whose error message actively misleads.
export function readHostPayload() {
    let raw;
    try {
        raw = readFileSync(0);          // fd 0, so this works whether stdin is a pipe or a file
    } catch {
        return {};                      // no payload at all is a legitimate way to be invoked
    }
    if (!raw || raw.length === 0) return {};
    // 'utf-8-sig' has no direct equivalent in Node, so strip U+FEFF explicitly. Same effect,
    // and visible rather than hidden behind an encoding name.
    const text = raw.toString('utf8').replace(/^\uFEFF/, '');
    if (!text.trim()) return {};
    try {
        return JSON.parse(text);
    } catch (err) {
        // A malformed payload is the host's, not ours. Returning empty means "no reason to think
        // this stop should wait", which is the safe direction: a missed wake is recoverable by the
        // next message, a crash in a stop hook is not.
        return { _parse_error: String(err && err.message || err) };
    }
}

// --- Rule 5: assume nothing about shells ------------------------------------
//
// TWO SEPARATE QUESTIONS, and measurement found a machine where the answers differed: the host ran
// its hook through bash while running the woken turn's command through PowerShell. The two shells
// disagree about a leading quoted path -- bash treats a quoted word in command position as the
// command, PowerShell treats it as a string expression and errors.
//
// The call operator is NOT the fix: in bash `&` means background. What is portable is an UNQUOTED
// path, correct in both, and it breaks only when the path contains a space -- which is the one case
// where the adapter must know which host it is talking to, because a product cannot choose its
// users' install paths and `C:\Program Files\` is where Windows puts things.
export function shellSafePath(p, { quoteStyle = 'none' } = {}) {
    // Forward slashes throughout. A backslash is an escape character in bash, so a Windows-style
    // path handed to a hook running under bash loses its separators silently.
    const forward = String(p).replace(/\\/g, '/');
    if (!/\s/.test(forward)) return forward;
    switch (quoteStyle) {
        case 'powershell': return `& '${forward.replace(/'/g, "''")}'`;
        case 'posix':      return `'${forward.replace(/'/g, "'\\''")}'`;
        default:           return `"${forward}"`;
    }
}

// The interpreter is resolved FROM THE RUNNING PROCESS, never from `PATH`. A `PATH` entry may be a
// shim that re-launches the real interpreter as a child, which leaves the process the host is
// watching unrelated to the process that actually blocks -- so the host watches a parent that has
// already exited while the real waiter runs on unobserved.
export function ownInterpreter({ quoteStyle = 'none' } = {}) {
    return shellSafePath(process.execPath, { quoteStyle });
}

// The session name, when the host's hook line did not give one.
//
// THE SAME DERIVATION `bin/aid` USES, and it must be, or the two disagree about who this session is --
// which shows up as a session that registered fine and never wakes. That is what removing `--name`
// from the documented hook line would have caused if this were missing, and it was missing until a
// review walked the operator's path instead of reading it.
//
// The host runs a stop hook with the session's own working directory as the cwd, which is the same
// directory the session registered from, which is why both sides land on the same name.
export function defaultSessionName() {
    if (process.env.AID_CHAT_SESSION) return process.env.AID_CHAT_SESSION;
    const base = (process.cwd().split(/[\\/]/).filter(Boolean).pop() || 'session')
        .replace(/[^A-Za-z0-9._-]/g, '-')
        .replace(/^-+|-+$/g, '');
    return base || 'session';
}

// --- Rule 1: re-entry -------------------------------------------------------
//
// Waking is inherently a loop: the wake ends a turn, ending a turn fires the stop hook, and the
// stop hook wakes the session again. Measured at 6.3 s and 6.6 s on the two proving hosts. "Block
// on every stop event" is therefore not an implementable adapter.
//
// Where the host reports how many automatic follow-ups a conversation has already triggered, the
// adapter reads it. Where the host offers no such signal -- or documents its cap as `null`, meaning
// uncapped -- the adapter carries the count itself, and on that host the rule is load-bearing
// rather than belt-and-braces because there is no host-side backstop at all.
export function ownCountPath(sessionKey) {
    const dir = process.env.AID_CHAT_RUNTIME || `${process.env.HOME || '.'}/.aid/chat`;
    // Keyed by the host's own conversation id where it gives one, so two conversations in the same
    // host do not share a counter and starve each other.
    const safe = String(sessionKey || 'default').replace(/[^A-Za-z0-9_.-]/g, '_');
    return `${dir}/wake-${safe}.count`;
}

// The count EXPIRES. Where the host supplies no conversation id, the key falls back to the session
// name -- and a name is reused across conversations, so a counter left behind by an earlier one
// would decline a new conversation's wake for a loop it was not part of. The count only means
// anything within one wake chain, and a wake chain is short: measurement put the stop-hook re-fire
// at 6.3 s and 6.6 s on the two proving hosts. Anything older than a minute is therefore not part of
// the current chain and is treated as absent.
const OWN_COUNT_TTL_MS = 60_000;

export function readOwnCount(sessionKey) {
    try {
        const raw = readFileSync(ownCountPath(sessionKey), 'utf8').trim();
        const [nRaw, tsRaw] = raw.split(/\s+/);
        const n = Number(nRaw);
        if (!Number.isFinite(n) || n < 0) return 0;
        const ts = Number(tsRaw);
        // No timestamp means a file from an older format; treat it as expired rather than trusted.
        if (!Number.isFinite(ts)) return 0;
        if (Date.now() - ts > OWN_COUNT_TTL_MS) return 0;
        return n;
    } catch {
        return 0;
    }
}

export async function writeOwnCount(sessionKey, n) {
    const { writeFile, mkdir } = await import('node:fs/promises');
    const path = ownCountPath(sessionKey);
    await mkdir(path.replace(/\/[^/]+$/, ''), { recursive: true });
    // The timestamp is what makes the count expirable, so it is written with it rather than beside it.
    await writeFile(path, `${n} ${Date.now()}`, 'utf8');
}

export async function clearOwnCount(sessionKey) {
    const { unlink } = await import('node:fs/promises');
    try { await unlink(ownCountPath(sessionKey)); } catch { /* already gone */ }
}

// --- Rule 3: stay inside the host's hook timeout ----------------------------
//
// Measured: on timeout the host ABANDONS the hook rather than killing it -- output discarded, wait
// abandoned, process left running with its socket still open -- and nothing in the host reports it.
// Each such wake leaks a process and inflates the node's waiter count.
//
// So the block must end strictly before the host stops listening, and the number is NOT the
// adapter's to discover. Ownership is split three ways: the operator writes it in the host
// configuration only they touch, the product states the value it needs, and the adapter is TOLD it
// and bounds its own block by what it was told. Where it is told nothing it must not inherit the
// platform default -- measurement bounded one host's default at under 60 s and no tighter, and
// whether that is also under this product's long poll was never established.
// The adapter's OWN guard, derived from the configurable margin rather than a hardcoded number.
//
// Three bounds sit inside the host's timeout, and they have to nest: the node blocks for
// `host_timeout - margin`, the adapter guards at `host_timeout - margin/2`, and the host stops
// listening at `host_timeout`. So the adapter's guard fires after the node would have returned and
// before the host gives up, which is the only ordering that makes a late answer still an answer.
//
// WHAT THIS CANNOT PROTECT AGAINST, stated because an operator on a busy machine will meet it: these
// are event-loop timers, and a machine under enough CPU contention will run them late. The adapter
// itself does no long synchronous work -- it reads stdin, makes at most two requests, writes stdout --
// so it cannot starve its own loop; only the machine can. No in-process mechanism survives an OS that
// will not schedule the process, so the remedy is the margin, and the margin is configurable for
// exactly this reason: on a loaded machine, widen it.
export function adapterGuardMs(hostTimeoutSec) {
    const { adapterMarginMs, longPollMs } = limits();
    if (!hostTimeoutSec) {
        // Told nothing: guard just past the fallback block, so an unanswered wait still ends.
        return Math.min(longPollMs, UNKNOWN_TIMEOUT_BLOCK_MS) + Math.floor(adapterMarginMs / 2);
    }
    return Math.max(1000, (hostTimeoutSec * 1000) - Math.floor(adapterMarginMs / 2));
}

export function hostTimeoutFromArgs(argv) {
    const i = argv.indexOf('--host-timeout');
    if (i === -1 || i + 1 >= argv.length) return null;
    const n = Number(argv[i + 1]);
    return Number.isFinite(n) && n > 0 ? n : null;
}

function runtimeDir() {
    return process.env.AID_CHAT_RUNTIME || `${process.env.HOME || '.'}/.aid/chat`;
}

export function hubBaseUrl() {
    try {
        const port = readFileSync(`${runtimeDir()}/hub.port`, 'utf8').trim();
        return port ? `http://127.0.0.1:${port}` : null;
    } catch {
        return null;
    }
}

// One armed wait plus, on a message, the inbox read that goes with it.
//
// The inbox read is here rather than left to the woken session because of the single most
// consequential thing the spike found: on one host the woken turn's own shell command raised an
// approval prompt and waited for a human click, and an autonomous channel cannot wait on a person.
// So the wake carries the message body as TEXT and the session simply continues with it as context.
//
// This advances `delivered` and NOT `acked`. If it advanced both, a crash between the hand-off and
// the turn would mark a message read that no model ever saw. The session advances `acked` when it
// next calls anything; redelivery keys on `acked`.
export async function armOnce({ name, hostTimeoutSec, timeoutGuardMs = null }) {
    const base = hubBaseUrl();
    if (!base) return { ok: false, reason: 'node_not_running' };

    // ONE DEADLINE FOR THE WHOLE RUN, not one per request. This function makes up to two calls -- the
    // pending read and then the wait -- and giving each its own guard means the adapter can take
    // TWICE the guard. Against a far end that accepts and never answers, that is exactly the orphan
    // the guard exists to prevent: measured at 36s for an 18s guard, comfortably past the host
    // timeout it was told about. Each request now gets whatever is LEFT of the one budget.
    const deadline = timeoutGuardMs ? Date.now() + timeoutGuardMs : null;
    const remaining = () => (deadline === null ? null : Math.max(1, deadline - Date.now()));

    // READ BEFORE WAITING. This is what makes idle and busy ONE implementation rather than two, and
    // leaving it out breaks the busy path completely: the hook fires at the end of a turn, so a
    // message that arrived DURING that turn is already in the store and is not going to "arrive"
    // again. An adapter that went straight to the wait would block, time out, and leave that
    // message unread until some later message happened to come in while it was listening.
    //
    // So the pending read is the busy path, and it needs no push at all. The wait below is only for
    // the idle case -- which is exactly when a push is the only thing that would work.
    const pending = await getJson(`${base}/messages?name=${encodeURIComponent(name)}`, remaining());
    if (pending && pending.ok && Array.isArray(pending.messages) && pending.messages.length > 0) {
        return {
            ok: true, kind: 'message', from_backlog: true,
            messages: pending.messages, delivered_seq: pending.delivered_seq,
        };
    }

    const q = new URLSearchParams({ name });
    if (hostTimeoutSec !== null && hostTimeoutSec !== undefined) {
        q.set('host_timeout', String(hostTimeoutSec));
    }
    // Out of budget before even arming: return without waiting rather than start a wait that cannot
    // finish before the host stops listening.
    const leftToWait = remaining();
    if (leftToWait !== null && leftToWait <= 1) return { ok: true, kind: 'timeout', self_bounded: true };

    const wake = await getJson(`${base}/wait?${q}`, leftToWait);
    if (!wake.ok) return wake;
    if (wake.kind !== 'message') return wake;

    const inbox = await getJson(`${base}/messages?name=${encodeURIComponent(name)}`, remaining());
    return { ...wake, messages: inbox.messages || [], delivered_seq: inbox.delivered_seq };
}

function getJson(url, timeoutMs) {
    return new Promise((resolve) => {
        const req = request(url, { method: 'GET' }, (res) => {
            const chunks = [];
            res.on('data', (c) => chunks.push(c));
            res.on('end', () => {
                const text = Buffer.concat(chunks).toString('utf8').replace(/^\uFEFF/, '');
                try { resolve(JSON.parse(text)); }
                catch { resolve({ ok: false, reason: 'bad_response', detail: text.slice(0, 200) }); }
            });
        });
        req.on('error', (err) => resolve({ ok: false, reason: 'unreachable', detail: String(err.message) }));
        // A guard the adapter sets for ITSELF, independent of the node's block. The node bounding
        // its own wait is not enough: if the node stops answering mid-wait, the adapter would sit
        // past the host's timeout and become exactly the abandoned process rule 3 is about.
        if (timeoutMs) {
            req.setTimeout(timeoutMs, () => {
                req.destroy();
                resolve({ ok: true, kind: 'timeout', self_bounded: true });
            });
        }
        req.end();
    });
}

// The text a woken session reads. Shared, because it is the canonical message rendered for a human
// or a model to read -- the HOST-SPECIFIC part is only the envelope it gets wrapped in.
export function renderWakeText({ kind, messages = [], channel = null, ackHint = null }) {
    if (kind === 'connect') {
        return [
            `You have been connected to the chat channel "${channel}".`,
            'Another agent asked to talk with you. You are now a member of that channel.',
            ackHint ? `To see what is said and reply: ${ackHint}` : '',
        ].filter(Boolean).join('\n');
    }
    if (!messages.length) return '';
    const lines = messages.map((m) => `[${m.from}] ${m.body}`);
    return [
        `New message${messages.length > 1 ? 's' : ''} on the agent chat channel:`,
        '',
        ...lines,
        '',
        'Do not stop yet. Consider whether this needs a reply, and reply if it does.',
        ackHint ? `Acknowledge with: ${ackHint}` : '',
    ].filter(Boolean).join('\n');
}
