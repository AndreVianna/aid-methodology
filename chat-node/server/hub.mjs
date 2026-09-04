// chat-node/server/hub.mjs -- the hub process: an HTTP server over loopback and its lifecycle.
//
// The hub has one responsibility, message exchange, and ships no operator surface of its own
// (FR-7.5): `start`, `stop` and `status` are `aid` subcommands that talk to this process, and
// this file implements the process, not the commands.
//
// Loopback only at this stage. Opening it to a LAN interface belongs to federation, and
// arrives with the trust model that justifies it -- binding wider before that exists would
// make the network reachable before anything decided it should be.
//
// The transport is the built-in HTTP server: no framework, no third-party dependency (FR-7.6).

import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';

import { nowMs, openStore, stateHome } from './store.mjs';
import * as core from './core.mjs';
import { blockMsFor, createRegistry } from './waiters.mjs';
import * as peers from './peers.mjs';

export const DEFAULT_PORT = 8812;   // 8787 is the dashboard's; 8799 and 8811 are also taken
export const LOOPBACK = '127.0.0.1';

export function runtimeDir() {
    return process.env.AID_CHAT_RUNTIME || join(stateHome(), 'chat');
}
export function pidFilePath() { return join(runtimeDir(), 'hub.pid'); }
export function portFilePath() { return join(runtimeDir(), 'hub.port'); }

// ---------------------------------------------------------------------------
// Liveness of a recorded pid, without the POSIX `kill(pid, 0)` idiom.
//
// On Windows `kill(pid, 0)` TERMINATES the process rather than probing it. That is not a
// hypothetical: it silently corrupted a measurement during this product's own feasibility
// spike, and the wrong answer looked plausible. `process.kill(pid, 0)` in Node is safe on
// both platforms because Node maps signal 0 to a permission probe, but the reason it must
// not become a bare `kill` in a shell wrapper is recorded here rather than rediscovered.
export function pidAlive(pid) {
    if (!Number.isInteger(pid) || pid <= 0) return false;
    try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
}

export function readPid() {
    try {
        const pid = Number(readFileSync(pidFilePath(), 'utf8').trim());
        return Number.isInteger(pid) && pid > 0 ? pid : null;
    } catch { return null; }
}

export function readPort() {
    try {
        const p = Number(readFileSync(portFilePath(), 'utf8').trim());
        return Number.isInteger(p) && p > 0 ? p : null;
    } catch { return null; }
}

export function hubStatus() {
    const pid = readPid();
    if (pid === null) return { running: false, reason: 'no pid file' };
    if (!pidAlive(pid)) return { running: false, pid, reason: 'stale pid file' };
    return { running: true, pid, port: readPort() };
}

function writeRuntimeFiles(pid, port) {
    const dir = runtimeDir();
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true, mode: 0o700 });
    writeFileSync(pidFilePath(), `${pid}\n`, { mode: 0o600 });
    writeFileSync(portFilePath(), `${port}\n`, { mode: 0o600 });
}

export function clearRuntimeFiles() {
    for (const f of [pidFilePath(), portFilePath()]) {
        try { rmSync(f, { force: true }); } catch { /* nothing to remove */ }
    }
}

// ---------------------------------------------------------------------------
// Routes. Later tasks add the message plane and the hub plane; this file owns only the
// server, its lifecycle and the one route the operator needs to see it is alive.

function json(res, status, body) {
    const text = JSON.stringify(body);
    res.writeHead(status, {
        'content-type': 'application/json; charset=utf-8',
        'content-length': Buffer.byteLength(text),
    });
    res.end(text);
}

// A refused request is answered with 409 and its stable token, not 400 and not 500. 400 would
// say the caller sent something malformed, which it did not; 500 would say the hub broke, which
// it did not. The CLI maps this status to exit 14 -- one shape, one meaning, all the way out.
function answer(res, result) {
    if (result && result.ok) return json(res, 200, result);
    const status = result && result.reason === 'bad_request' ? 400 : 409;
    return json(res, status, result);
}

async function readJsonBody(req) {
    const chunks = [];
    for await (const c of req) chunks.push(c);
    if (!chunks.length) return {};
    // Decode with utf-8 BOM tolerance. RFC 8259 does not permit a BOM in JSON, so a strict
    // parser rejects an otherwise valid document at its FIRST character -- an error that reads
    // as malformed JSON rather than as an encoding problem. The spike lost two runs to exactly
    // that, and any client of this hub could hit it, so the tolerance lives here rather than in
    // each caller.
    const text = Buffer.concat(chunks).toString('utf8').replace(/^\uFEFF/, '');
    try { return JSON.parse(text); }
    catch (err) { const e = new Error(`malformed JSON body: ${err.message}`); e.badRequest = true; throw e; }
}

export function makeRouter({ db, startedAt, onReady = null }) {
    const routes = new Map();
    const waiters = createRegistry();
    // The core announces; the transport decides who cares. Wiring it here rather than inside the
    // core is what keeps the core transport-blind.
    // The unregister is KEPT, not discarded. Additive announcers fixed the clobbering problem but
    // introduced the mirror of it: a router that never unregisters leaves its listener attached to
    // the core for the life of the process, so a second router's arrival no longer breaks the first
    // and the first's departure no longer stops it being told. Holding the handle is what makes a
    // router's lifetime symmetric -- it registers when built and detaches when torn down.
    const detachAnnouncer = core.setAnnouncer((event) => {
        if (event.kind === 'message') waiters.announceMessage(event);
        else if (event.kind === 'connect') waiters.announceConnect(event);
    });

    // Handed back to the caller AFTER both handles exist, so shutdown can detach the announcer and
    // drain held waits. Calling this any earlier reads `detachAnnouncer` before its declaration --
    // which is a temporal dead zone error that takes the whole node down at startup, and did.
    if (onReady) onReady({ waiters, detachAnnouncer });

    // The held wait. One connection, held open, resolved by whichever comes first: a message in
    // the caller's channel, a change in the caller's own situation, or the block expiring.
    //
    // It answers 200 in EVERY case including the timeout, because a timeout is not an error -- it
    // is the normal outcome of an idle period, and a non-2xx would make an ordinary quiet minute
    // look like a fault to every client and every log.
    routes.set('GET /wait', (req, res, url) => {
        const name = url.searchParams.get('name');
        const session = name ? core.getSession(db, name) : null;
        if (!session) return answer(res, { ok: false, reason: 'not_registered' });

        const hostTimeout = url.searchParams.get('host_timeout');
        const explicit = url.searchParams.get('block_ms');
        const { blockMs, basis } = explicit !== null
            ? { blockMs: Math.max(0, Number(explicit)), basis: 'explicit-block-ms' }
            : blockMsFor({ hostTimeoutSec: hostTimeout === null ? null : Number(hostTimeout) });

        // Close the read-then-wait window HERE, which is the only place it can be closed. A client
        // that reads its inbox and then arms has a gap between the two, and a message landing in
        // that gap is not lost -- it is simply not pushed, so the client waits out a whole block
        // before finding it. Checking the caller's own pending depth at the moment of registration
        // removes the gap: by then the client cannot have anything unread that this does not see.
        const pending = core.inbox(db, { name, cursor: session.acked_seq });
        if (pending.ok && pending.messages && pending.messages.length > 0) {
            return json(res, 200, {
                ok: true, kind: 'message', from_backlog: true,
                arrival_seq: pending.messages[pending.messages.length - 1].arrival_seq,
                block_ms: 0, basis: 'pending-at-arm', waiters: waiters.count(),
            });
        }

        // A zero block is answered at once rather than registered. Registering a waiter that is
        // due to expire immediately would put a reader in the count for no purpose.
        if (blockMs <= 0) {
            return json(res, 200, {
                ok: true, kind: 'timeout', block_ms: 0, basis,
                waiters: waiters.count(),
            });
        }

        const settle = (outcome) => {
            if (res.writableEnded) return;
            json(res, 200, {
                ok: true,
                kind: outcome.kind,
                ...(outcome.arrival_seq !== undefined ? { arrival_seq: outcome.arrival_seq } : {}),
                ...(outcome.channel !== undefined ? { channel: outcome.channel } : {}),
                block_ms: blockMs,
                basis,
                waiters: waiters.count(),
            });
        };

        const waiter = waiters.register({
            sessionName: name,
            channelId: session.channel_id,
            timeoutMs: blockMs,
            settle,
        });
        // The abandoned-client path. A host that abandons an over-running hook leaves this socket
        // open with nobody reading it, and `close` is the only notice that ever comes -- so it is
        // wired to the same release path as every other ending, which is what makes the waiter
        // count return to where it started instead of drifting upward with each abandoned wake.
        req.on('close', () => waiter.abandon());
        req.on('aborted', () => waiter.abandon());
    });

    // The count, so AC-25 can be checked by observation rather than by trusting an absence of
    // errors. Deliberately reports it as a HINT, in the field name, because that is what it is.
    routes.set('GET /waiters', (_req, res) => json(res, 200, {
        ok: true, waiters_hint: waiters.count(),
    }));

    // The requirements' API table promises this route, so it exists rather than leaving a caller
    // that follows the spec to receive a 404. It answers first and shuts down after, so the
    // caller gets a reply rather than a dropped connection.
    routes.set('POST /stop', (_req, res) => {
        waiters.drain();
        // Shut down only once the response has actually been written. A timer would be a race:
        // `json()` buffers, the socket write is asynchronous, and the SIGTERM handler exits
        // immediately without draining -- so a busy event loop could drop the reply the caller
        // is waiting for. `finish` fires when the last byte has been handed to the socket.
        res.on('finish', () => process.kill(process.pid, 'SIGTERM'));
        json(res, 200, { ok: true, stopping: true, pid: process.pid });
    });

    routes.set('GET /status', (_req, res) => json(res, 200, {
        running: true,
        pid: process.pid,
        started_at: startedAt,
        uptime_ms: nowMs() - startedAt,
        store: db ? 'open' : 'closed',
    }));

    // Session plane.
    routes.set('POST /session', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.register(db, {
            name: b.name, tool: b.tool, cwd: b.cwd,
            capabilities: b.capabilities, hostConversationId: b.host_conversation_id || null,
        }));
    });
    routes.set('POST /session/heartbeat', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.heartbeat(db, b.name));
    });
    routes.set('GET /sessions', (_req, res) => json(res, 200, { ok: true, sessions: core.listSessions(db) }));

    // Peers. Operator-facing: an operator names the addresses, which is the guaranteed discovery
    // path and depends on no network feature at all.
    routes.set('GET /peers', (_req, res) => json(res, 200, { ok: true, peers: peers.listPeers(db) }));
    routes.set('POST /peers', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, peers.addPeer(db, { machine: b.machine, source: b.source || 'configured' }));
    });
    routes.set('POST /peers/remove', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, peers.removePeer(db, { machine: b.machine }));
    });
    // Best-effort, above the guaranteed path. Carries no criterion: where broadcast is blocked this
    // finds nobody, and an operator can always name addresses instead.
    routes.set('POST /peers/discover', async (_req, res) => {
        const port = Number(process.env.AID_CHAT_ADVERTISED_PORT || 0) || null;
        answer(res, await peers.announceAndDiscover(db, { myPort: port }));
    });

    // Hub plane -- signalling, not messaging. Separate from the channel and message planes
    // because hub membership is registration plus liveness rather than a held socket, which is
    // what lets a connect request reach an agent that is in no channel at all.
    routes.set('GET /roster', (req, res, url) =>
        answer(res, core.roster(db, { name: url.searchParams.get('name') })));
    routes.set('POST /connect', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.connect(db, { name: b.name, target: b.target }));
    });

    // Channel plane.
    routes.set('POST /channel', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.openChannel(db, { name: b.name, channelName: b.channel }));
    });
    routes.set('POST /channel/join', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.joinChannel(db, { name: b.name, channelName: b.channel }));
    });
    routes.set('POST /channel/leave', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.leaveChannel(db, { name: b.name }));
    });
    routes.set('GET /channels', (req, res, url) =>
        json(res, 200, { ok: true, channels: core.listChannels(db, { name: url.searchParams.get('name') }) }));

    // Retention trigger. The rule lives in the core and the SCHEDULE is retention's; this route
    // is what makes the reap-driven channel close reachable through the product instead of only
    // from inside the process.
    routes.set('POST /session/reap', async (req, res) => {
        const b = await readJsonBody(req);
        if (b && b.name) return answer(res, core.reapSession(db, { name: b.name }));
        answer(res, core.reapStale(db));
    });

    // Message plane.
    routes.set('POST /messages', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.send(db, {
            name: b.name, body: b.body, kind: b.kind,
            idempotencyKey: b.idempotency_key || null,
            mention: b.mention || null, whisperTo: b.whisper_to || null,
            correlationId: b.correlation_id || null, replyTo: b.reply_to || null,
        }));
    });
    routes.set('GET /messages', (req, res, url) => {
        const cursor = url.searchParams.get('cursor');
        answer(res, core.inbox(db, {
            name: url.searchParams.get('name'),
            cursor: cursor === null ? null : Number(cursor),
        }));
    });
    routes.set('POST /messages/ack', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.ack(db, { name: b.name, cursor: b.cursor }));
    });

    return async function route(req, res) {
        const url = new URL(req.url, `http://${LOOPBACK}`);
        const key = `${req.method} ${url.pathname}`;
        const handler = routes.get(key);
        if (!handler) return json(res, 404, { error: 'no_such_route', route: key });
        try {
            await handler(req, res, url);
        } catch (err) {
            if (err && err.badRequest) {
                return json(res, 400, { ok: false, reason: 'bad_request', detail: String(err.message) });
            }
            // A handler fault is the hub's fault, not the caller's: report it as one rather
            // than leaking a stack trace over the wire.
            json(res, 500, { ok: false, reason: 'internal', detail: String(err && err.message || err) });
        }
    };
}

// ---------------------------------------------------------------------------
// Serving.

export async function serve({ port = DEFAULT_PORT, storeFile = null } = {}) {
    const db = await openStore(storeFile ? { path: storeFile } : {});
    const startedAt = nowMs();
    let registry = null;
    let detach = null;
    const server = createServer(makeRouter({
        db, startedAt,
        onReady: ({ waiters, detachAnnouncer }) => { registry = waiters; detach = detachAnnouncer; },
    }));

    await new Promise((resolve, reject) => {
        server.once('error', reject);
        // Bind loopback explicitly. Omitting the host binds every interface, which would put
        // the hub on the network a whole stage before the trust model that permits it.
        server.listen(port, LOOPBACK, resolve);
    });

    const actualPort = server.address().port;
    writeRuntimeFiles(process.pid, actualPort);

    const shutdown = () => {
        // Settle held waits BEFORE closing the server, so each client gets an answer rather than
        // a dropped connection it has to time out on.
        // Detach first, so nothing can be announced to a registry that is about to be drained.
        try { if (detach) detach(); } catch { /* already detached */ }
        try { if (registry) registry.drain(); } catch { /* nothing held */ }
        try { server.close(); } catch { /* already closing */ }
        try { db.close(); } catch { /* already closed */ }
        clearRuntimeFiles();
        process.exit(0);
    };
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

    return { server, db, port: actualPort };
}

// ---------------------------------------------------------------------------
// Entry point, used by the CLI's `start`. Not a supported direct invocation.

if (process.argv[1] && process.argv[1].endsWith('hub.mjs')) {
    const portArg = process.argv.indexOf('--port');
    const port = portArg > -1 ? Number(process.argv[portArg + 1]) : DEFAULT_PORT;
    serve({ port }).then(({ port: p }) => {
        process.stdout.write(`chat-node: listening on ${LOOPBACK}:${p}\n`);
    }).catch((err) => {
        process.stderr.write(`chat-node: ${err && err.message || err}\n`);
        process.exit(1);
    });
}
