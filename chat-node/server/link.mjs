// chat-node/server/link.mjs -- the long-lived link between two hubs.
//
// ONE connection per peer, carrying everything that crosses machines: replication, roster queries,
// and connect relays. One link rather than a connection per operation, because the property that
// matters most here is the one nothing upstream has measured -- whether it survives an idle network
// -- and that property only exists if the connection is long-lived in the first place.
//
// A RAW TCP SOCKET with newline-delimited JSON, on its own listener. Three reasons, in order:
//
//   The trust boundary is different. The HTTP API binds loopback only and serves SESSIONS; this
//   listener faces the LAN and serves PEERS. They cannot share a port, and conflating them would put
//   the session API on the network a whole trust model early.
//
//   Keepalive is the point. The requirement is an interval well under the shortest plausible network
//   idle timeout, and a socket lets that be exactly what it says rather than whatever an HTTP
//   agent's connection pool decides.
//
//   Nothing is held in the link. Everything not yet delivered is in the outbox, which is what makes
//   a reconnect lose nothing -- the link can be dropped and rebuilt without consulting anybody.
//
// WHAT IS DELIBERATELY ABSENT: authentication. There is none anywhere in this product, and v1
// assumes a flat trusted LAN. Membership of the network IS the trust model, stated rather than
// implied, and the hosting server stays in reserve for when that is not enough.

import { createConnection, createServer } from 'node:net';
import { nowMs } from './store.mjs';
import { PROTOCOL_VERSION, checkCompatibility } from './protocol.mjs';
import * as peers from './peers.mjs';

export const DEFAULT_LINK_PORT = 8814;

// Keepalive well under the shortest plausible network idle timeout. Many NATs and stateful firewalls
// drop an idle flow at 60 s and some at 30 s, so 15 s leaves room for one to be missed without the
// flow going quiet long enough to be reaped.
const KEEPALIVE_MS = 15_000;
// A peer that has not answered two keepalives is treated as gone. Two rather than one so a single
// dropped datagram or a moment of scheduling delay does not tear down a healthy link.
const KEEPALIVE_GRACE = 2;

// Reconnect backoff, JITTERED. Two hubs that lost each other will both try to reconnect, and with a
// fixed schedule they can settle into lockstep -- each retrying exactly when the other is between
// attempts, indefinitely. The jitter is what breaks that, and it is the same reasoning as the connect
// request's retry hint.
const BACKOFF_BASE_MS = 500;
const BACKOFF_MAX_MS = 30_000;
function backoffFor(attempt) {
    const capped = Math.min(BACKOFF_MAX_MS, BACKOFF_BASE_MS * (2 ** Math.min(attempt, 6)));
    return Math.floor(capped / 2) + Math.floor(Math.random() * (capped / 2));
}

// --- framing ----------------------------------------------------------------
// Newline-delimited JSON. A message body can contain a newline, so it is JSON-escaped by
// `JSON.stringify` before it ever reaches the wire -- which is exactly why the delimiter is safe.
function makeFramer(onFrame) {
    let buf = '';
    return (chunk) => {
        buf += chunk.toString('utf8');
        let nl;
        while ((nl = buf.indexOf('\n')) !== -1) {
            const line = buf.slice(0, nl);
            buf = buf.slice(nl + 1);
            if (!line.trim()) continue;
            let frame;
            try { frame = JSON.parse(line); } catch { continue; }   // a bad frame is dropped, not fatal
            onFrame(frame);
        }
    };
}

function send(socket, frame) {
    if (!socket || socket.destroyed) return false;
    try {
        socket.write(`${JSON.stringify(frame)}\n`);
        return true;
    } catch {
        return false;
    }
}

// ---------------------------------------------------------------------------
// The link manager: one outbound link per peer, plus the listener for inbound ones.

export function createLinkManager({ db, handlers = {}, linkPort = null, machineId = null }) {
    // machine -> { socket, state, attempt, timer, keepaliveTimer, missed, pending }
    const links = new Map();
    let server = null;
    let stopped = false;

    const myPort = linkPort || Number(process.env.AID_CHAT_LINK_PORT) || DEFAULT_LINK_PORT;
    const myMachine = machineId || process.env.AID_CHAT_MACHINE || 'local';

    function linkFor(machine) {
        if (!links.has(machine)) {
            links.set(machine, {
                socket: null, state: 'idle', attempt: 0,
                timer: null, keepaliveTimer: null, missed: 0,
                pending: new Map(), nextId: 1,
            });
        }
        return links.get(machine);
    }

    // Answer a frame that arrived from a peer. Both directions use the same handler table, so an
    // inbound link is as capable as an outbound one -- which matters because whichever hub dialled
    // first should not determine which one can ask questions.
    async function handleFrame(socket, frame, fromMachine) {
        if (frame.t === 'ping') return send(socket, { t: 'pong', id: frame.id });
        if (frame.t === 'pong') {
            const l = links.get(fromMachine);
            if (l) l.missed = 0;
            return true;
        }
        if (frame.t === 'reply') {
            const l = links.get(fromMachine);
            const waiter = l && l.pending.get(frame.id);
            if (waiter) {
                l.pending.delete(frame.id);
                clearTimeout(waiter.timer);
                waiter.resolve(frame.body);
            }
            return true;
        }
        if (frame.t === 'req') {
            const handler = handlers[frame.op];
            let body;
            if (!handler) {
                body = { ok: false, reason: 'unknown_op', detail: String(frame.op) };
            } else {
                try {
                    body = await handler(frame.body || {}, { fromMachine });
                } catch (err) {
                    body = { ok: false, reason: 'handler_error', detail: String(err && err.message || err) };
                }
            }
            return send(socket, { t: 'reply', id: frame.id, body });
        }
        return true;
    }

    function teardown(machine, { reconnect = true } = {}) {
        const l = links.get(machine);
        if (!l) return;
        if (l.keepaliveTimer) clearInterval(l.keepaliveTimer);
        l.keepaliveTimer = null;
        // Every in-flight request is failed rather than left hanging. A caller waiting on a reply
        // that will never come is worse than one told at once that the peer went away.
        for (const [, waiter] of l.pending) {
            clearTimeout(waiter.timer);
            waiter.resolve({ ok: false, reason: 'peer_unreachable' });
        }
        l.pending.clear();
        if (l.socket) { try { l.socket.destroy(); } catch { /* already gone */ } }
        l.socket = null;
        l.state = 'idle';
        peers.markUnreachable(db, machine);
        if (reconnect && !stopped) scheduleReconnect(machine);
    }

    function scheduleReconnect(machine) {
        const l = linkFor(machine);
        if (l.timer || stopped) return;
        l.attempt += 1;
        const delay = backoffFor(l.attempt);
        l.timer = setTimeout(() => { l.timer = null; connect(machine).catch(() => {}); }, delay);
        if (l.timer.unref) l.timer.unref();
    }

    function startKeepalive(machine) {
        const l = linkFor(machine);
        if (l.keepaliveTimer) clearInterval(l.keepaliveTimer);
        l.missed = 0;
        l.keepaliveTimer = setInterval(() => {
            if (!l.socket || l.socket.destroyed) return;
            l.missed += 1;
            if (l.missed > KEEPALIVE_GRACE) {
                // Two unanswered keepalives: treat the peer as gone and rebuild rather than sit on a
                // socket the network has already dropped without telling either end.
                teardown(machine);
                return;
            }
            send(l.socket, { t: 'ping', id: `ka-${l.nextId++}` });
        }, KEEPALIVE_MS);
        if (l.keepaliveTimer.unref) l.keepaliveTimer.unref();
    }

    async function connect(machine) {
        if (stopped) return { ok: false, reason: 'stopped' };
        const l = linkFor(machine);
        if (l.socket && !l.socket.destroyed && l.state === 'up') return { ok: true, already: true };

        const [host, portRaw] = machine.split(':');
        const port = Number(portRaw) || DEFAULT_LINK_PORT;

        return new Promise((resolve) => {
            let settled = false;
            const socket = createConnection({ host, port });
            socket.setNoDelay(true);
            // OS-level keepalive as well as the protocol one. They catch different things: this
            // notices a host that vanished, the protocol ping notices a path that silently stopped
            // forwarding while both ends still believe the socket is open.
            socket.setKeepAlive(true, KEEPALIVE_MS);

            const fail = (reason, detail = null) => {
                if (settled) return;
                settled = true;
                try { socket.destroy(); } catch { /* already gone */ }
                l.socket = null;
                l.state = 'idle';
                peers.markUnreachable(db, machine);
                if (!stopped) scheduleReconnect(machine);
                resolve({ ok: false, reason, ...(detail ? { detail } : {}) });
            };

            socket.setTimeout(5000, () => fail('connect_timeout'));
            socket.on('error', (err) => fail('unreachable', String(err.message)));

            socket.on('connect', () => {
                socket.setTimeout(0);
                // The handshake is the FIRST thing on the wire, before anything that could be
                // misread. A peer that speaks a different major version must be refused before it
                // sends a frame this hub would parse under the wrong rules.
                send(socket, { t: 'hello', protocol: PROTOCOL_VERSION, machine: myMachine, port: myPort });
            });

            const onFrame = makeFramer(async (frame) => {
                if (frame.t === 'hello' || frame.t === 'hello-ack') {
                    const verdict = checkCompatibility(frame.protocol);
                    if (!verdict.compatible) {
                        if (!settled) {
                            settled = true;
                            try { socket.destroy(); } catch { /* gone */ }
                            l.socket = null; l.state = 'refused';
                            peers.markUnreachable(db, machine);
                            // NOT rescheduled. A major mismatch is not a transient failure, and
                            // retrying it forever would be a reconnect loop that can never succeed.
                            resolve({ ok: false, reason: verdict.reason, detail: verdict.detail });
                        }
                        return;
                    }
                    if (frame.t === 'hello') send(socket, { t: 'hello-ack', protocol: PROTOCOL_VERSION, machine: myMachine, port: myPort });
                    l.socket = socket;
                    l.state = 'up';
                    l.attempt = 0;
                    peers.markReachable(db, machine, { protocolMajor: verdict.major, machineId: frame.machine });
                    startKeepalive(machine);
                    if (!settled) { settled = true; resolve({ ok: true, protocol: frame.protocol }); }
                    if (handlers.onLinkUp) handlers.onLinkUp(machine).catch(() => {});
                    return;
                }
                await handleFrame(socket, frame, machine);
            });

            socket.on('data', onFrame);
            socket.on('close', () => {
                if (!settled) return fail('closed_before_handshake');
                if (l.state === 'up') teardown(machine);
            });
        });
    }

    // A request over the link, with its reply correlated by id. Bounded, because a peer that accepts
    // a frame and never answers must not hold a caller forever.
    function request(machine, op, body, { timeoutMs = 5000 } = {}) {
        const l = linkFor(machine);
        if (!l.socket || l.socket.destroyed || l.state !== 'up') {
            return Promise.resolve({ ok: false, reason: 'peer_unreachable' });
        }
        const id = `r-${l.nextId++}`;
        return new Promise((resolve) => {
            const timer = setTimeout(() => {
                l.pending.delete(id);
                resolve({ ok: false, reason: 'peer_timeout' });
            }, timeoutMs);
            if (timer.unref) timer.unref();
            l.pending.set(id, { resolve, timer });
            if (!send(l.socket, { t: 'req', id, op, body })) {
                l.pending.delete(id);
                clearTimeout(timer);
                resolve({ ok: false, reason: 'peer_unreachable' });
            }
        });
    }

    async function listen() {
        server = createServer((socket) => {
            socket.setNoDelay(true);
            socket.setKeepAlive(true, KEEPALIVE_MS);
            let theirMachine = null;
            const onFrame = makeFramer(async (frame) => {
                if (frame.t === 'hello') {
                    const verdict = checkCompatibility(frame.protocol);
                    if (!verdict.compatible) {
                        // Refused explicitly and by name, rather than by dropping the socket. The
                        // dialling hub must be able to tell an incompatible peer from an absent one.
                        send(socket, { t: 'refused', reason: verdict.reason, detail: verdict.detail, protocol: PROTOCOL_VERSION });
                        try { socket.destroy(); } catch { /* gone */ }
                        return;
                    }
                    theirMachine = peers.normalizeMachine(`${socket.remoteAddress}:${frame.port || DEFAULT_LINK_PORT}`);
                    // An inbound peer is LEARNED. It dialled us, so it exists and is reachable, and
                    // requiring an operator to also name it on this side would make federation
                    // depend on configuring both ends identically.
                    if (theirMachine) {
                        peers.addPeer(db, { machine: theirMachine, source: 'discovered' });
                        peers.markReachable(db, theirMachine, { protocolMajor: verdict.major, machineId: frame.machine });

                        // AND THE SOCKET IS REGISTERED AS A USABLE LINK, which is what makes it
                        // genuinely bidirectional. Without this an inbound peer could be ANSWERED but
                        // never ASKED: this hub would reply to its requests and have no way to send it
                        // one, so whichever hub dialled first would silently be the only one able to
                        // replicate. Measured: a join on the dialled-to hub never reached the dialler,
                        // so its member stayed invisible and every send there was refused as solo.
                        //
                        // Registered only if there is no outbound link already up, so a hub that
                        // dialled and was dialled does not replace a working link with a second one.
                        const l = linkFor(theirMachine);
                        if (!l.socket || l.socket.destroyed) {
                            l.socket = socket;
                            l.state = 'up';
                            l.attempt = 0;
                            startKeepalive(theirMachine);
                            socket.on('close', () => {
                                if (l.socket === socket) teardown(theirMachine, { reconnect: false });
                            });
                        }
                    }
                    send(socket, { t: 'hello-ack', protocol: PROTOCOL_VERSION, machine: myMachine, port: myPort });
                    if (handlers.onLinkUp && theirMachine) handlers.onLinkUp(theirMachine).catch(() => {});
                    return;
                }
                await handleFrame(socket, frame, theirMachine);
            });
            socket.on('data', onFrame);
            socket.on('error', () => { try { socket.destroy(); } catch { /* gone */ } });
        });

        await new Promise((resolve, reject) => {
            server.once('error', reject);
            // The LAN-facing listener, and the only thing in this product that binds beyond
            // loopback. That is the trust boundary the requirements draw, made explicit here.
            server.listen(myPort, '0.0.0.0', resolve);
        });
        return { port: server.address().port };
    }

    function stop() {
        stopped = true;
        for (const [machine, l] of links) {
            if (l.timer) clearTimeout(l.timer);
            teardown(machine, { reconnect: false });
        }
        links.clear();
        if (server) { try { server.close(); } catch { /* already closing */ } }
    }

    function status() {
        return [...links.entries()].map(([machine, l]) => ({
            machine, state: l.state, attempt: l.attempt, in_flight: l.pending.size,
        }));
    }

    return { connect, request, listen, stop, status, linkPort: () => myPort, isUp: (m) => {
        const l = links.get(m);
        return !!(l && l.state === 'up' && l.socket && !l.socket.destroyed);
    } };
}
