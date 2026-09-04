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
import { thisMachine } from './core.mjs';
import { blockMsFor, createRegistry } from './waiters.mjs';
import * as settings from './settings.mjs';
import * as peers from './peers.mjs';
import * as outbox from './outbox.mjs';
import { createLinkManager } from './link.mjs';
import * as fed from './federation.mjs';
import { PROTOCOL_VERSION } from './protocol.mjs';

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

    // NOTE: the caller is handed these at the END of this function, not here. See the comment on the
    // `onReady` call at the bottom -- this position is where it used to be, and it was wrong twice.

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

    // The link manager. Built here so the routes can reach it, and handed to the caller through
    // `onReady` so shutdown can stop it. The handler table is what a PEER may ask of this hub, and it
    // is deliberately small: the same table serves inbound and outbound links, so whichever hub
    // dialled first does not determine which one can ask questions.
    // Federation borrows the core's roster rather than importing the whole core surface, which also
    // keeps the local half of a federated answer visibly the same shape as the remote half.
    fed.setCoreRoster(core.roster);

    const link = createLinkManager({
        db,
        handlers: {
            // A peer announcing who is on it. Answered from live state, never from a stored copy.
            roster: async () => ({ ok: true, agents: core.roster(db).agents, machine: thisMachine() }),
            // A relayed connect request, answered against THIS hub's state at the moment it arrives.
            connect: async (body) => fed.applyRelayedConnect(db, body, {
                joinLocal: ({ target, channel }) => {
                    // Availability FIRST, and only then the replica. Creating the channel before this
                    // check left an orphan behind every refused relay.
                    const t = core.getSession(db, target);
                    if (!t) return { ok: false, reason: 'target_unavailable', detail: 'unknown' };
                    if (t.channel_id !== null) return { ok: false, reason: 'target_unavailable', detail: 'already in a channel' };
                    if (core.isStale(t)) return { ok: false, reason: 'target_unavailable', detail: 'stale' };

                    // A hub asked for a name it has never seen CREATES its local replica: a channel is
                    // a name, there is nothing to look up and no authority to consult, so refusing
                    // would mean inventing an authority the model deliberately does not have (FR-9.7).
                    const known = db.prepare('SELECT id FROM channel WHERE name = ?').get(channel);
                    if (!known) {
                        db.prepare('INSERT INTO channel(name, opened_at) VALUES (?,?)').run(channel, nowMs());
                    }
                    // Uses the ordinary join, so a relayed request reaches the same rules a local one
                    // does -- including joining at the channel's head. A separate path here would be
                    // a second implementation of membership for one caller.
                    return core.joinChannel(db, { name: target, channelName: channel });
                },
            }),
            // Does this hub know a channel name? Asked by a peer whose local session is trying to join
            // a name it has never seen -- a channel is authoritative nowhere, so any hub that has it
            // is sufficient authority to join it.
            has_channel: async (body) => {
                const ch = db.prepare('SELECT id FROM channel WHERE name = ?').get(body.channel);
                if (!ch) return { ok: true, exists: false, members: [] };
                // Both halves of the roll, expressed the same way: this hub's own sessions carry its
                // machine id, and the remote ones carry theirs. The asker needs the whole roll, not
                // the part that happens to be local here.
                const local = db.prepare('SELECT name FROM session WHERE channel_id = ?').all(ch.id)
                    .map((r) => ({ machine: thisMachine(), name: r.name }));
                // Remote members are passed on as this hub knows them. It may be slightly behind --
                // a `leave` from a third hub can still be in flight -- and that is accepted rather
                // than papered over: the joining hub would learn the same thing from the same
                // announcement, and a member believed present when it has gone costs at most one
                // send that should have been refused as solo. The alternative, asking every peer to
                // confirm every member, makes one join an O(peers) round trip to remove a window that
                // closes itself.
                const remote = db.prepare('SELECT machine, name FROM channel_member WHERE channel_id = ?')
                    .all(ch.id).map((r) => ({ machine: r.machine, name: r.name }));
                return { ok: true, exists: true, members: [...local, ...remote] };
            },
            // A membership change on another hub. Applied to the remote half of the roll.
            membership: async (body) => fed.applyMembership(db, body),
            // A message from another hub, stored with OUR arrival order and THEIR sender_seq.
            message: async (body) => {
                const result = fed.applyMessage(db, body);
                // A replicated message wakes local listeners exactly as a local one does. Without
                // this a federated message would be durable and unnoticed -- readable on the next
                // pull and never pushed -- which is the wake working on one machine only.
                if (result.ok && !result.absorbed && !result.ignored) {
                    const ch = db.prepare('SELECT id FROM channel WHERE name = ?').get(body.channel);
                    if (ch) {
                        waiters.announceMessage({
                            channel_id: ch.id, arrival_seq: result.arrival_seq, from: body.sender_name,
                        });
                    }
                }
                return result;
            },
            onLinkUp: async (machine) => { await drainTo(machine); },
        },
    });

    async function drainTo(machine) {
        const p = peers.getPeer(db, machine);
        if (!p) return { ok: false, reason: 'peer_unknown' };
        return outbox.drain(db, {
            peerId: p.id,
            machine,
            deliver: async ({ kind, payload }) => link.request(machine, kind, payload),
        });
    }

    // Operator visibility: what is in the store, plus the derived numbers an operator acts on.
    routes.set('GET /status/detail', (_req, res) => answer(res, core.operatorView(db)));
    routes.set('GET /audit', (req, res, url) =>
        answer(res, core.readAudit(db, { limit: Number(url.searchParams.get('limit')) || 100 })));

    // Eviction: removing a session from its channel. The ONE remedy this design leaves a human, which
    // is why it is here and not on the agent surface -- an agent manages its own membership only.
    routes.set('POST /evict', async (req, res) => {
        const b = await readJsonBody(req);
        const target = core.getSession(db, b.name);
        if (!target) return answer(res, { ok: false, reason: 'not_registered' });
        if (!target.channel_id) return answer(res, { ok: false, reason: 'no_channel' });
        const ch = db.prepare('SELECT name FROM channel WHERE id = ?').get(target.channel_id);
        const r = core.leaveChannel(db, { name: b.name });
        if (r.ok) {
            core.audit(db, { event: 'evict', subject: b.name, channel: ch && ch.name,
                             detail: r.channel_closed ? 'channel closed with them' : 'channel remains' });
            if (ch) {
                fed.replicateMembership(db, link, {
                    channelName: ch.name, name: b.name,
                    event: r.channel_closed ? 'close' : 'leave',
                }).catch(() => {});
            }
        }
        answer(res, r);
    });

    // Retention policy, settable at runtime. The values live in the settings registry and are read on
    // every use, so setting one takes effect without a restart.
    routes.set('GET /retention', (_req, res) => json(res, 200, { ok: true, limits: settings.limits() }));
    routes.set('POST /retention', async (req, res) => {
        const b = await readJsonBody(req);
        const applied = {};
        for (const key of Object.keys(settings.LIMIT_ENV)) {
            if (b[key] === undefined) continue;
            const n = Number(b[key]);
            if (!Number.isFinite(n) || n < 0) {
                return answer(res, { ok: false, reason: 'bad_request', detail: `${key} must be a non-negative number` });
            }
            applied[key] = n;
        }
        if (!Object.keys(applied).length) {
            return answer(res, { ok: false, reason: 'bad_request', detail: `nothing to set; known keys: ${Object.keys(settings.LIMIT_ENV).join(', ')}` });
        }
        // Persisted, not merely applied. An operator who set a value and found it reverted after a
        // restart would have been given half a feature, and the evidence would arrive hours later.
        const wrote = settings.persistOverrides(applied);
        core.audit(db, { event: 'retention', detail: Object.entries(applied).map(([k, v]) => `${k}=${v}`).join(' ') });
        answer(res, { ok: true, applied, persisted: true, limits: settings.limits(), ...(wrote.warning ? { warning: wrote.warning } : {}) });
    });

    routes.set('GET /protocol', (_req, res) => json(res, 200, {
        ok: true, protocol: PROTOCOL_VERSION, machine: thisMachine(), link_port: link.linkPort(),
    }));
    routes.set('GET /links', (_req, res) => json(res, 200, { ok: true, links: link.status() }));
    routes.set('POST /peers/connect', async (req, res) => {
        const b = await readJsonBody(req);
        const m = peers.normalizeMachine(b.machine);
        if (!m) return answer(res, { ok: false, reason: 'bad_request', detail: 'a machine address is required' });
        peers.addPeer(db, { machine: m, source: 'configured' });
        answer(res, await link.connect(m));
    });
    routes.set('GET /outbox', (_req, res) => json(res, 200, {
        ok: true,
        total: outbox.depth(db),
        by_peer: peers.listPeers(db).map((p) => ({ machine: p.machine, queued: p.queued })),
    }));

    // Replication rides the core's announcement seam as a SECOND listener, which is only possible
    // because that seam is additive. The alternative -- calling replication from inside `core.send` --
    // would put the network in the core and make it aware of peers, which is the thing the whole
    // design keeps out of it.
    const detachFederation = core.setAnnouncer((event) => {
        if (event.kind !== 'message') return;
        const ch = db.prepare('SELECT id, name FROM channel WHERE id = ?').get(event.channel_id);
        if (!ch) return;
        const msg = db.prepare('SELECT * FROM message WHERE channel_id = ? AND arrival_seq = ?')
                      .get(event.channel_id, event.arrival_seq);
        // Only replicate what originated HERE. A message that arrived from a peer is already on its
        // way to everyone that peer could reach, and forwarding it again would multiply every message
        // by the number of hubs it passed through.
        if (!msg || msg.sender_machine !== thisMachine()) return;
        fed.replicateMessage(db, link, { channelId: ch.id, channelName: ch.name, message: msg })
           .catch(() => {});
    });

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
    // Federated, and its partial-answer shape is the point: an agent must be able to tell "there is
    // nobody" from "I could not see one of the places somebody might be".
    routes.set('GET /roster', async (req, res, url) =>
        answer(res, await fed.federatedRoster(db, link, { name: url.searchParams.get('name') })));
    routes.set('POST /connect', async (req, res) => {
        const b = await readJsonBody(req);
        // Try locally first. A target on this machine needs no network at all, and reaching for the
        // relay before checking here would make a local connect depend on a link being up.
        const local = core.connect(db, { name: b.name, target: b.target });
        if (local.ok || local.reason !== 'target_unavailable') return answer(res, local);

        // Not here, or not available here. `target` may be plain or machine-qualified; a bare name is
        // tried against every peer, because a name alone is not a destination and the asker may not
        // know which machine its peer is on.
        const asker = core.getSession(db, b.name);
        if (!asker || !asker.channel_id) return answer(res, local);
        const chRow = db.prepare('SELECT name FROM channel WHERE id = ?').get(asker.channel_id);
        if (!chRow) return answer(res, local);

        const [qualMachine, qualName] = String(b.target).includes('/')
            ? String(b.target).split('/', 2)
            : [null, b.target];

        // REACHABLE peers only. An unreachable peer cannot be hosting the target, so asking it costs a
        // round trip to learn nothing -- and, worse, its "peer unreachable" answer used to overwrite
        // the informative refusal a peer that DID answer had already given.
        const candidates = qualMachine
            ? [qualMachine]
            : peers.listPeers(db).filter((p) => p.state === 'reachable').map((p) => p.machine_id || p.machine);

        let lastRelayed = null;
        for (const machineId of candidates) {
            const relayed = await fed.relayConnect(db, link, {
                targetMachineId: machineId, target: qualName,
                channelName: chRow.name,
                askerMachine: thisMachine(), askerName: b.name,
            });
            if (relayed.ok) {
                // The target's hub joined it; record it here as a remote member so replication knows
                // where to send, without waiting for its membership announcement to arrive.
                fed.applyMembership(db, {
                    channel: chRow.name, machine: machineId, name: qualName, event: 'join',
                });
                return answer(res, { ok: true, connected: qualName, machine: machineId, channel: chRow.name, relayed: true });
            }
            // Keep the MOST INFORMATIVE refusal, not the most recent one. A peer that answered and
            // said "already in a channel" knows something; a peer that could not be reached knows
            // nothing. Taking the last answer meant one unreachable peer later in the list erased the
            // real reason an earlier peer had given, and the asker was told its target did not exist
            // when in fact it was merely busy.
            if (relayed && relayed.detail && relayed.detail !== 'no peer for that machine') {
                const informative = (r) => !String(r.detail || '').startsWith('peer unreachable');
                if (!lastRelayed || (informative(relayed) && !informative(lastRelayed))) {
                    lastRelayed = relayed;
                }
            }
        }
        // Nothing anywhere. Prefer a relayed reason over the local one, and keep the retry hint --
        // which the local refusal carries and a relayed one does not, because the jitter is minted by
        // whichever hub refuses.
        if (lastRelayed) {
            return answer(res, { ...local, detail: lastRelayed.detail, relayed: true });
        }
        answer(res, local);
    });

    // Channel plane.
    routes.set('POST /channel', async (req, res) => {
        const b = await readJsonBody(req);
        const r = core.openChannel(db, { name: b.name, channelName: b.channel });
        if (r.ok) fed.replicateMembership(db, link, { channelName: r.channel, name: b.name, event: 'join' }).catch(() => {});
        answer(res, r);
    });
    routes.set('POST /channel/join', async (req, res) => {
        const b = await readJsonBody(req);
        let r = core.joinChannel(db, { name: b.name, channelName: b.channel });
        // A name unknown HERE may exist on a peer. Refusing without asking would make a channel a
        // per-machine thing, which is precisely what "replicated, authoritative nowhere" denies. The
        // lookup happens only on the miss, so the ordinary join costs no network at all.
        if (!r.ok && r.reason === 'channel_unknown') {
            const found = await fed.peerKnowsChannel(db, link, b.channel);
            if (found.known) {
                db.prepare('INSERT INTO channel(name, opened_at) VALUES (?,?)').run(b.channel, nowMs());
                // Record who is already there, from the answer. Without this the new member joins a
                // channel it believes is empty, and its first send is refused as solo.
                for (const m of found.members || []) {
                    fed.applyMembership(db, { channel: b.channel, machine: m.machine, name: m.name, event: 'join' });
                }
                r = core.joinChannel(db, { name: b.name, channelName: b.channel });
            }
        }
        if (r.ok) fed.replicateMembership(db, link, { channelName: r.channel, name: b.name, event: 'join' }).catch(() => {});
        answer(res, r);
    });
    routes.set('POST /channel/leave', async (req, res) => {
        const b = await readJsonBody(req);
        // The channel name has to be read BEFORE leaving, because leaving may close the channel and
        // then there is nothing left to name in the announcement.
        const before = core.getSession(db, b.name);
        const chRow = before && before.channel_id
            ? db.prepare('SELECT name FROM channel WHERE id = ?').get(before.channel_id) : null;
        const r = core.leaveChannel(db, { name: b.name });
        if (r.ok && chRow) {
            fed.replicateMembership(db, link, {
                channelName: chRow.name, name: b.name,
                event: r.channel_closed ? 'close' : 'leave',
            }).catch(() => {});
        }
        answer(res, r);
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
        const sent = core.send(db, {
            name: b.name, body: b.body, kind: b.kind,
            idempotencyKey: b.idempotency_key || null,
            mention: b.mention || null, whisperTo: b.whisper_to || null,
            correlationId: b.correlation_id || null, replyTo: b.reply_to || null,
        });
        if (sent.ok && !sent.absorbed) {
            const who = core.getSession(db, b.name);
            const ch = who && who.channel_id
                ? db.prepare('SELECT name FROM channel WHERE id = ?').get(who.channel_id) : null;
            // A whisper is its own event, so the log shows one happened and between whom -- and the
            // `detail` carries a length, not a body. There is nowhere in the schema to put a body.
            core.audit(db, b.whisper_to
                ? { event: 'whisper', actor: b.name, subject: b.whisper_to, channel: ch && ch.name,
                    detail: `${String(b.body || '').length} chars` }
                : { event: 'send', actor: b.name, channel: ch && ch.name,
                    detail: `seq ${sent.arrival_seq}` });
        }
        answer(res, sent);
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

    // ---------------------------------------------------------------------------
    // The periodic jobs (tasks 033 and 034). The RULES live in the core; this is only the schedule,
    // which is the split the earlier deliveries deliberately left: reaping's effect was built with
    // channel lifecycle, trimming's with retention, and neither ran on a clock until now.
    //
    // TWO JOBS, ONE TIMER, and in this order. Reaping first, because it removes members, and a member
    // removed is a member no longer holding the trim point back -- running trim first would keep
    // everything a just-departed session had not acknowledged for one more interval, every interval.
    //
    // What this timer must NEVER do is close a channel because the CHANNEL fell quiet. It closes one
    // only as a consequence of reaping its last MEMBER, which keys on that member's heartbeat and not
    // on the channel's activity. The distinction is the whole of the no-inactivity-timeout rule, and
    // the test that guards it checks exactly that difference.
    let jobTimer = null;
    const runJobs = () => {
        try {
            core.reapStale(db);
        } catch (err) {
            process.stderr.write(`chat-node: reaping failed: ${err && err.message}\n`);
        }
        try {
            core.trim(db);
        } catch (err) {
            process.stderr.write(`chat-node: trim failed: ${err && err.message}\n`);
        }
    };
    const startJobs = () => {
        const { jobIntervalMs } = settings.limits();
        if (jobIntervalMs <= 0) return null;   // 0 disables them, which a test needs
        jobTimer = setInterval(runJobs, jobIntervalMs);
        if (jobTimer.unref) jobTimer.unref();
        return jobTimer;
    };
    const stopJobs = () => { if (jobTimer) clearInterval(jobTimer); jobTimer = null; };

    // Operator-triggered, so the schedule is never the only way to make them happen -- an operator
    // debugging a retention question should not have to wait an interval to see the effect.
    routes.set('POST /jobs/run', (_req, res) => {
        runJobs();
        json(res, 200, { ok: true, ran: ['reap', 'trim'] });
    });

    // EVERY handle the caller needs, passed at the point where all of them exist.
    //
    // This call has now been in the wrong place TWICE, for the same reason each time: it sat near the
    // top of the function and passed a `const` declared further down, which is a temporal dead zone
    // error that takes the whole node down at startup with a message nowhere near the cause. The
    // first time it was the announcer handle; the second time, with the identical fix applied, it was
    // the link. Moving it here makes the class of mistake impossible rather than fixing one instance
    // of it: nothing is declared after this point, so nothing can be referenced too early.
    if (onReady) onReady({ waiters, detachAnnouncer, detachFederation, link, startJobs, stopJobs });

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
    let detachFed = null;
    let linkMgr = null;
    let startJobs = null;
    let stopJobs = null;
    const server = createServer(makeRouter({
        db, startedAt,
        onReady: (h) => {
            registry = h.waiters; detach = h.detachAnnouncer;
            detachFed = h.detachFederation; linkMgr = h.link;
            startJobs = h.startJobs; stopJobs = h.stopJobs;
        },
    }));

    await new Promise((resolve, reject) => {
        server.once('error', reject);
        // Bind loopback explicitly. Omitting the host binds every interface, which would put
        // the hub on the network a whole stage before the trust model that permits it.
        server.listen(port, LOOPBACK, resolve);
    });

    const actualPort = server.address().port;
    writeRuntimeFiles(process.pid, actualPort);

    // The LAN-facing listener. Started only when federation is asked for, so a single-machine install
    // binds nothing beyond loopback -- which keeps delivery-001's trust boundary intact for anybody
    // who never sets up a peer.
    if (linkMgr && process.env.AID_CHAT_LINK_PORT !== 'off') {
        try {
            const info = await linkMgr.listen();
            // Dial every peer already known, so a restart re-establishes its links without an
            // operator doing anything. A failure here is not fatal: the peer is marked unreachable
            // and the reconnect schedule takes over.
            for (const p of peers.listPeers(db)) {
                linkMgr.connect(p.machine).catch(() => {});
            }
            if (process.env.AID_CHAT_VERBOSE) {
                process.stderr.write(`chat-node: link listening on ${info.port}\n`);
            }
        } catch (err) {
            process.stderr.write(`chat-node: link listener unavailable: ${err && err.message}\n`);
        }
    }

    if (startJobs) startJobs();

    const shutdown = () => {
        try { if (stopJobs) stopJobs(); } catch { /* already stopped */ }
        // Settle held waits BEFORE closing the server, so each client gets an answer rather than
        // a dropped connection it has to time out on.
        // Detach first, so nothing can be announced to a registry that is about to be drained.
        try { if (linkMgr) linkMgr.stop(); } catch { /* already stopped */ }
        try { if (detach) detach(); } catch { /* already detached */ }
        try { if (detachFed) detachFed(); } catch { /* already detached */ }
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
