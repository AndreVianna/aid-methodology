// chat-node/server/federation.mjs -- replication: what crosses machines, and what does not.
//
// The rule this whole module exists to preserve: A SESSION'S EXPERIENCE IS IDENTICAL whether its peer
// is on this machine or another. Nothing here changes a rule; it moves facts between hubs so that the
// rules in `core.mjs` reach the same answers on both.
//
// TWO THINGS REPLICATE AND ONE DOES NOT.
//
//   Membership replicates, because replication cannot work without it. A hub must know which peers
//   hold members of a channel in order to know where to send a message, and it cannot derive that
//   from `session.channel_id` once members are elsewhere.
//
//   Messages replicate, obviously.
//
//   The ROSTER does not. It is fetched when asked and merged for the answer, never stored -- because
//   a stored roster is a second source of truth for liveness that no heartbeat maintains, and a stale
//   row claiming an agent is available would send an asker after somebody who left an hour ago. A
//   slow answer beats a lying one.

import { nowMs } from './store.mjs';
import * as peers from './peers.mjs';
import * as outbox from './outbox.mjs';
import { thisMachine } from './core.mjs';

// The peers that hold a member of this channel, which is what decides where a message goes. Derived
// from `channel_member` because that is the only place the answer exists once members are remote.
export function peersForChannel(db, channelId) {
    return db.prepare(`SELECT DISTINCT cm.machine
                       FROM channel_member cm
                       WHERE cm.channel_id = ?`).all(channelId).map((r) => r.machine);
}

// Every peer we would tell about a channel's membership. Broader than `peersForChannel` on purpose:
// a hub that does not yet know it holds a member of this channel still needs to be told when one
// arrives, so a join is announced to every reachable peer rather than only to those already involved.
function announceTargets(db) {
    return peers.listPeers(db).map((p) => p.machine);
}

// --- outbound ---------------------------------------------------------------

// Send now if the peer is reachable; queue if it is not. The queue is the record of an outage and
// nothing else -- the ordinary path does not touch it.
//
// A send that FAILS is queued too, not dropped. "Reachable" is the state of the last thing we tried,
// so it can be stale by the time we act on it, and treating a failed write as delivered would lose
// exactly the message the outbox exists to protect.
async function deliverOrQueue(db, link, machine, kind, payload) {
    // `machine` here may be either an address or a logical machine id, because the two callers know
    // different things: a membership announcement goes to every peer (addresses), while a message
    // goes to the machines holding members (logical names). Resolving both to an address in one place
    // is what keeps that difference from becoming a routing bug -- and it WAS one: a message routed
    // by logical name found no peer, so it was neither sent nor queued nor reported.
    const peer = peers.getPeer(db, machine) || (() => {
        const addr = peers.addressForMachineId(db, machine);
        return addr ? peers.getPeer(db, addr) : null;
    })();
    if (!peer) return { ok: false, reason: 'peer_unknown', detail: `no peer for ${machine}` };
    machine = peer.machine;

    if (link && link.isUp(machine)) {
        const res = await link.request(machine, kind, payload);
        if (res && res.ok) return { ok: true, delivered: true };
        outbox.enqueue(db, { peerId: peer.id, kind, payload });
        return { ok: true, delivered: false, queued: true, reason: (res && res.reason) || 'deliver_failed' };
    }
    outbox.enqueue(db, { peerId: peer.id, kind, payload });
    return { ok: true, delivered: false, queued: true, reason: 'peer_unreachable' };
}

export async function replicateMembership(db, link, { channelName, name, event }) {
    const payload = { channel: channelName, machine: thisMachine(), name, event, at: nowMs() };
    const results = [];
    for (const machine of announceTargets(db)) {
        results.push({ machine, ...(await deliverOrQueue(db, link, machine, 'membership', payload)) });
    }
    return { ok: true, replicated_to: results };
}

export async function replicateMessage(db, link, { channelId, channelName, message }) {
    const targets = peersForChannel(db, channelId);
    const payload = {
        channel: channelName,
        sender_machine: message.sender_machine,
        sender_name: message.sender_name,
        // Carried VERBATIM. This is the one field a receiving hub must not regenerate: it is the
        // sender's own sequence, and per-speaker order is reconstructed from it on every hub. A hub
        // that renumbered it would silently replace the sender's order with its own arrival order.
        sender_seq: message.sender_seq,
        idempotency_key: message.idempotency_key,
        kind: message.kind,
        body: message.body,
        correlation_id: message.correlation_id,
        reply_to: message.reply_to,
        mention: message.mention,
        whisper_to: message.whisper_to,
        sent_at: message.sent_at,
    };
    const results = [];
    for (const machine of targets) {
        results.push({ machine, ...(await deliverOrQueue(db, link, machine, 'message', payload)) });
    }
    return { ok: true, replicated_to: results };
}

// --- inbound ----------------------------------------------------------------

// A hub asked about a channel name it has never seen CREATES its local replica. A channel is a name;
// there is nothing to look up and no authority to consult, so refusing would mean inventing an
// authority the model deliberately does not have.
function ensureChannel(db, channelName) {
    let ch = db.prepare('SELECT * FROM channel WHERE name = ?').get(channelName);
    if (!ch) {
        db.prepare('INSERT INTO channel(name, opened_at) VALUES (?,?)').run(channelName, nowMs());
        ch = db.prepare('SELECT * FROM channel WHERE name = ?').get(channelName);
    }
    return ch;
}

export function applyMembership(db, { channel, machine, name, event }) {
    if (!channel || !machine || !name) {
        return { ok: false, reason: 'bad_request', detail: 'channel, machine and name are required' };
    }
    // Never record a local member here. `channel_member` holds the REMOTE half only, so mirroring our
    // own members would create a second place for a fact `session.channel_id` already holds, and the
    // two would disagree the first time a transaction updated one and not the other.
    if (machine === thisMachine()) {
        return { ok: true, ignored: 'own machine' };
    }

    if (event === 'leave' || event === 'close') {
        const ch = db.prepare('SELECT id FROM channel WHERE name = ?').get(channel);
        if (!ch) return { ok: true, ignored: 'unknown channel' };
        if (event === 'close') {
            db.prepare('DELETE FROM channel_member WHERE channel_id = ? AND machine = ?').run(ch.id, machine);
        } else {
            db.prepare('DELETE FROM channel_member WHERE channel_id = ? AND machine = ? AND name = ?')
              .run(ch.id, machine, name);
        }
        // A channel with no local member and no remote member left is over on this hub too. Keeping
        // an empty replica would leave a name nothing will ever close.
        const localMembers = db.prepare('SELECT COUNT(*) AS n FROM session WHERE channel_id = ?').get(ch.id).n;
        const remoteMembers = db.prepare('SELECT COUNT(*) AS n FROM channel_member WHERE channel_id = ?').get(ch.id).n;
        if (localMembers === 0 && remoteMembers === 0) {
            db.prepare('DELETE FROM channel WHERE id = ?').run(ch.id);
            return { ok: true, applied: event, channel_closed: true };
        }
        return { ok: true, applied: event, channel_closed: false };
    }

    const ch = ensureChannel(db, channel);
    db.prepare('INSERT OR REPLACE INTO channel_member(channel_id, machine, name, joined_at) VALUES (?,?,?,?)')
      .run(ch.id, machine, name, nowMs());
    return { ok: true, applied: 'join', channel: ch.name };
}

// A replicated message, stored with THIS hub's own arrival order.
//
// `arrival_seq` is ours; `sender_seq` is theirs, verbatim. That split is the whole of the ordering
// design: each hub numbers what it receives in the order it receives it, and per-speaker order is
// reconstructed on read from the sender's own sequence. Neither hub needs to agree with the other
// about anything, which is why no consensus is required and why a scalar read position is exact.
export function applyMessage(db, payload) {
    const {
        channel, sender_machine, sender_name, sender_seq, idempotency_key,
        kind = 'message', body, correlation_id = null, reply_to = null,
        mention = null, whisper_to = null, sent_at = null,
    } = payload || {};

    if (!channel || !sender_machine || !sender_name || !idempotency_key || typeof body !== 'string') {
        return { ok: false, reason: 'bad_request', detail: 'channel, sender, key and body are required' };
    }
    // Our own message coming back to us. Dropped rather than stored: replication is not a loop, and a
    // hub that accepted its own send would double every message in a three-hub channel.
    if (sender_machine === thisMachine()) return { ok: true, ignored: 'own message' };

    const ch = ensureChannel(db, channel);

    // Dedupe on the SENDER-SCOPED key, which is what absorbs a replay after a reconnect. The outbox
    // may legitimately deliver an item twice -- it counts an attempt before delivering, so a failure
    // after the peer stored it looks identical to a failure before -- and this is where that becomes
    // harmless instead of a duplicate.
    const dup = db.prepare(`SELECT arrival_seq FROM message
                            WHERE channel_id = ? AND sender_machine = ? AND sender_name = ?
                              AND idempotency_key = ?`)
                  .get(ch.id, sender_machine, sender_name, idempotency_key);
    if (dup) return { ok: true, arrival_seq: dup.arrival_seq, absorbed: true };

    const t = nowMs();
    let arrivalSeq;
    db.exec('BEGIN IMMEDIATE');
    try {
        arrivalSeq = db.prepare('SELECT next_seq FROM channel WHERE id = ?').get(ch.id).next_seq;
        db.prepare(`INSERT INTO message
            (channel_id, arrival_seq, sender_name, sender_machine, sender_seq, idempotency_key,
             kind, body, correlation_id, reply_to, mention, whisper_to, sent_at, received_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
          .run(ch.id, arrivalSeq, sender_name, sender_machine, sender_seq, idempotency_key,
               kind, body, correlation_id, reply_to,
               mention ? (typeof mention === 'string' ? mention : JSON.stringify(mention)) : null,
               whisper_to, sent_at || t, t);
        db.prepare('UPDATE channel SET next_seq = next_seq + 1 WHERE id = ?').run(ch.id);
        db.exec('COMMIT');
    } catch (err) {
        db.exec('ROLLBACK');
        throw err;
    }
    return { ok: true, arrival_seq: arrivalSeq, absorbed: false, channel: ch.name };
}
