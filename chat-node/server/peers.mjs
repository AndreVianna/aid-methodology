// chat-node/server/peers.mjs -- the peer registry, and how a hub learns about another hub.
//
// DISCOVERY IS STATED AS AN OUTCOME WITH TWO PATHS, and the distinction between them is the whole
// design rather than a detail:
//
//   The GUARANTEED path is a static peer list plus heartbeat. It depends on NO network feature --
//   no multicast, no mDNS, no broadcast domain, no cooperating router. An operator names the
//   addresses and it works, on any network that carries TCP between the two machines. Every gate
//   criterion is satisfied by this path alone, deliberately, so that no criterion can be failed by
//   a network the product does not control.
//
//   Zero-configuration discovery sits ABOVE it as best-effort. It carries no criterion and is never
//   load-bearing: where it works an operator is spared typing an address, and where it does not
//   nothing degrades except convenience. It is allowed to fail silently, which is only safe
//   BECAUSE the guaranteed path exists underneath.
//
// Getting this the wrong way round is the common failure: build on mDNS, discover late that a
// corporate network blocks multicast, and then have no answer at all. Here the fallback is the
// foundation and the convenience is the addition.

import { networkInterfaces } from 'node:os';
import { nowMs } from './store.mjs';

// A peer is identified by the address it is reached at, so `machine` is the natural key and is
// UNIQUE in the schema: two rows for one address would mean two links, two outboxes, and two
// answers to "is it reachable".
export function normalizeMachine(addr) {
    const raw = String(addr || '').trim();
    if (!raw) return null;
    // Accept `host`, `host:port`, or a full URL, and store the host:port form. A caller that
    // pasted a URL and a caller that typed a bare host must not become two peers.
    let host = raw.replace(/^[a-z]+:\/\//i, '').replace(/\/.*$/, '');
    if (!host) return null;
    // Defaults to the LINK port, not the HTTP one. A peer address names where PEERS connect, and
    // that is a different listener from the loopback HTTP the sessions use -- the two cannot share a
    // port, and conflating them would have an operator naming an address nothing is listening on.
    if (!/:\d+$/.test(host)) host = `${host}:${process.env.AID_CHAT_LINK_PORT || 8814}`;
    return host.toLowerCase();
}

export function addPeer(db, { machine, source = 'configured' }) {
    const m = normalizeMachine(machine);
    if (!m) return { ok: false, reason: 'bad_request', detail: 'a machine address is required' };
    if (source !== 'configured' && source !== 'discovered') {
        return { ok: false, reason: 'bad_request', detail: "source must be 'configured' or 'discovered'" };
    }
    const existing = db.prepare('SELECT * FROM peer WHERE machine = ?').get(m);
    if (existing) {
        // An address arriving twice is not an error, and a CONFIGURED source upgrades a DISCOVERED
        // one: an operator who names a peer explicitly has said something stronger than a broadcast
        // did, and that statement should survive the next discovery sweep.
        if (source === 'configured' && existing.source === 'discovered') {
            db.prepare("UPDATE peer SET source = 'configured' WHERE id = ?").run(existing.id);
        }
        return { ok: true, machine: m, added: false, source: source === 'configured' ? 'configured' : existing.source };
    }
    db.prepare('INSERT INTO peer(machine, source, state, last_seen_at) VALUES (?,?,?,NULL)')
      .run(m, source, 'unreachable');
    // A new peer starts UNREACHABLE rather than reachable. Nothing has been heard from it yet, and
    // assuming otherwise would let a message be attempted-and-lost instead of queued on the very
    // first send after an operator adds an address.
    return { ok: true, machine: m, added: true, source };
}

export function removePeer(db, { machine }) {
    const m = normalizeMachine(machine);
    if (!m) return { ok: false, reason: 'bad_request', detail: 'a machine address is required' };
    const row = db.prepare('SELECT id FROM peer WHERE machine = ?').get(m);
    if (!row) return { ok: false, reason: 'peer_unknown' };
    // The outbox cascades away with it, which is the right call: an operator removing a peer is
    // saying they no longer expect to reach it, and keeping a queue for an address nobody will
    // contact again is a queue that only ever grows.
    const queued = db.prepare('SELECT COUNT(*) AS n FROM outbox WHERE peer_id = ?').get(row.id).n;
    db.prepare('DELETE FROM peer WHERE id = ?').run(row.id);
    return { ok: true, removed: m, discarded_queued: queued };
}

export function listPeers(db) {
    // One query, not one per peer. This is called on every roster request, so a COUNT per peer row
    // turned a peer list into N+1 statements against a table that grows during an outage -- exactly
    // when an operator is most likely to be asking.
    return db.prepare(`SELECT p.*, COUNT(o.id) AS queued
                       FROM peer p
                       LEFT JOIN outbox o ON o.peer_id = p.id
                       GROUP BY p.id
                       ORDER BY p.machine`).all().map((p) => ({
        machine: p.machine,
        machine_id: p.machine_id,
        source: p.source,
        state: p.state,
        protocol_major: p.protocol_major,
        last_seen_at: p.last_seen_at,
        // Reported so an operator can see a queue building against a peer that never returns,
        // rather than discovering it when the disk fills.
        queued: p.queued,
    }));
}

export function getPeer(db, machine) {
    const m = normalizeMachine(machine);
    return m ? (db.prepare('SELECT * FROM peer WHERE machine = ?').get(m) || null) : null;
}

// Reachability is STORED here, unlike a session's staleness which is derived. The difference is
// that a peer's reachability is not derivable from anything this hub holds: there is no heartbeat
// arriving from a peer to compare a clock against, only the outcome of the last thing we tried. So
// it is a record of what happened, written by whoever tried.
export function markReachable(db, machine, { protocolMajor = null, machineId = null } = {}) {
    const p = getPeer(db, machine);
    if (!p) return false;
    db.prepare(`UPDATE peer
                SET state = 'reachable', last_seen_at = ?,
                    protocol_major = COALESCE(?, protocol_major),
                    machine_id = COALESCE(?, machine_id)
                WHERE id = ?`)
      .run(nowMs(), protocolMajor, machineId, p.id);
    return true;
}

// Resolve an ADDRESS from a logical machine name.
//
// Two namespaces meet here, and keeping them straight is the whole point of this function. A peer is
// REACHED at an address (`peer.machine`); a member is IDENTIFIED by the logical name of the machine
// it sits on (`channel_member.machine`, and `message.sender_machine`). Those are different kinds of
// thing that a shared column name makes look identical, and conflating them silently breaks
// replication: the routing lookup finds no peer for the name, so nothing is sent and nothing errors.
//
// The mapping is LEARNED at handshake, where a hub announces its own logical name, rather than
// configured -- an operator who had to state both would have two chances to state them
// inconsistently.
export function addressForMachineId(db, machineId) {
    if (!machineId) return null;
    const row = db.prepare('SELECT machine FROM peer WHERE machine_id = ?').get(machineId);
    return row ? row.machine : null;
}

export function markUnreachable(db, machine) {
    const p = getPeer(db, machine);
    if (!p) return false;
    db.prepare("UPDATE peer SET state = 'unreachable' WHERE id = ?").run(p.id);
    return true;
}

export function reachablePeers(db) {
    return db.prepare("SELECT * FROM peer WHERE state = 'reachable' ORDER BY machine").all();
}

// ---------------------------------------------------------------------------
// Zero-configuration discovery: best-effort, above the guaranteed path.
//
// A UDP broadcast on the local segment, answered by any hub that hears it. Chosen over mDNS
// deliberately: mDNS needs a responder library or a system daemon, and a dependency whose absence
// disables discovery is a dependency the guaranteed path is supposed to make unnecessary. A raw
// broadcast needs nothing but a socket.
//
// EVERY failure here is swallowed. A network with broadcast disabled, a permission refusal, a
// firewall -- all of them mean "discovered nobody", which is a legitimate outcome because the
// operator can always name addresses. This function may therefore return an empty list on a
// perfectly healthy network, and that is not a fault.

// Every address this host answers on, so a hub can recognise its own broadcast whichever interface
// it comes back through.
function localAddresses() {
    const out = new Set(['127.0.0.1', '::1', 'localhost']);
    try {
        for (const list of Object.values(networkInterfaces() || {})) {
            for (const iface of list || []) out.add(iface.address);
        }
    } catch { /* an unenumerable stack is not fatal: the port check still applies */ }
    return out;
}

export const DISCOVERY_PORT = 8813;
const DISCOVERY_MAGIC = 'aid-chat-hub/1';

export async function announceAndDiscover(db, { myPort, timeoutMs = 1500 } = {}) {
    let dgram;
    try {
        dgram = await import('node:dgram');
    } catch {
        return { ok: true, discovered: [], note: 'no datagram support' };
    }

    return new Promise((resolve) => {
        const found = new Set();
        let socket;
        const finish = (note = null) => {
            try { socket && socket.close(); } catch { /* already closed */ }
            const added = [];
            for (const m of found) {
                const r = addPeer(db, { machine: m, source: 'discovered' });
                if (r.ok && r.added) added.push(m);
            }
            resolve({ ok: true, discovered: [...found], newly_added: added, ...(note ? { note } : {}) });
        };

        try {
            socket = dgram.createSocket({ type: 'udp4', reuseAddr: true });
        } catch {
            return resolve({ ok: true, discovered: [], note: 'socket unavailable' });
        }

        socket.on('error', () => finish('broadcast unavailable'));
        socket.on('message', (buf, rinfo) => {
            const text = buf.toString('utf8');
            if (!text.startsWith(DISCOVERY_MAGIC)) return;
            const port = text.split(' ')[1];
            if (!port || !/^\d+$/.test(port)) return;
            const m = normalizeMachine(`${rinfo.address}:${port}`);
            // Do not discover yourself. A hub hearing its own broadcast would add itself as a peer and
            // then replicate every message to itself, which is a loop with a database at both ends.
            //
            // The port alone is not enough: on a host with several interfaces a hub hears its own
            // broadcast back on a DIFFERENT source address, so the address matched nothing while the
            // port matched exactly. Both are checked, and the local addresses are enumerated rather
            // than guessed.
            const selfAddresses = localAddresses();
            const isSelf = String(port) === String(myPort) && selfAddresses.has(rinfo.address);
            if (m && !isSelf) found.add(m);
        });

        try {
            socket.bind(DISCOVERY_PORT, () => {
                try {
                    socket.setBroadcast(true);
                    const probe = Buffer.from(`${DISCOVERY_MAGIC} ${myPort}`);
                    socket.send(probe, 0, probe.length, DISCOVERY_PORT, '255.255.255.255');
                } catch {
                    return finish('broadcast refused');
                }
                const t = setTimeout(() => finish(), timeoutMs);
                if (t.unref) t.unref();
            });
        } catch {
            finish('bind refused');
        }
    });
}
