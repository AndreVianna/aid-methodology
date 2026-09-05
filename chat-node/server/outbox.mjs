// chat-node/server/outbox.mjs -- what is owed to a peer that was not reachable.
//
// THE OUTBOX IS WHY A RECONNECT LOSES NOTHING. Everything not yet delivered lives in the store, not
// in the link, so the link can be dropped and rebuilt without consulting anybody. That is the whole
// reason a long-lived connection is safe to lose.
//
// QUEUE ONLY WHERE A PEER IS UNREACHABLE. A reachable peer is written to directly, and only a failure
// puts the item here -- so the ordinary path has no queue in it at all, and the queue exists solely
// as the record of an outage.
//
// THE ASYMMETRY WITH CONNECT REQUESTS IS DELIBERATE AND IS THE INTERESTING PART. Messages queue;
// connect requests do NOT. A message delivered late is still a message, and the conversation absorbs
// the delay. A connect request answered minutes later arrives after the asking agent's circumstances
// have changed -- it may have left, been reaped, or connected to somebody else -- which is precisely
// the pending state the no-accept-step design exists to avoid. So a connect request against an
// unreachable peer FAILS, and the asker decides what to do with that now rather than being committed
// to an outcome it can no longer want.

import { nowMs } from './store.mjs';

export function enqueue(db, { peerId, kind, payload }) {
    if (!peerId) return { ok: false, reason: 'peer_unknown' };
    if (!['message', 'membership', 'roster'].includes(kind)) {
        return { ok: false, reason: 'bad_request', detail: `unknown outbox kind: ${kind}` };
    }
    const info = db.prepare('INSERT INTO outbox(peer_id, kind, payload, queued_at, attempts) VALUES (?,?,?,?,0)')
                   .run(peerId, kind, JSON.stringify(payload), nowMs());
    return { ok: true, id: Number(info.lastInsertRowid), queued: true };
}

export function depth(db, peerId = null) {
    if (peerId === null) return db.prepare('SELECT COUNT(*) AS n FROM outbox').get().n;
    return db.prepare('SELECT COUNT(*) AS n FROM outbox WHERE peer_id = ?').get(peerId).n;
}

// Oldest first, by the surrogate key rather than by `queued_at`. Two items queued in the same
// millisecond have the same timestamp, and replaying them out of order would hand a peer a speaker's
// messages in the wrong sequence -- which is the one ordering property this product does promise.
export function pending(db, peerId, { limit = 500 } = {}) {
    return db.prepare('SELECT * FROM outbox WHERE peer_id = ? ORDER BY id LIMIT ?').all(peerId, limit);
}

export function forget(db, id) {
    db.prepare('DELETE FROM outbox WHERE id = ?').run(id);
}

export function countAttempt(db, id) {
    db.prepare('UPDATE outbox SET attempts = attempts + 1 WHERE id = ?').run(id);
}

// Replay everything owed to one peer, oldest first, stopping at the first failure.
//
// STOPPING IS THE POINT, not a shortcut. Skipping a failed item to try later ones would deliver them
// out of order, and the per-speaker order this product promises is the thing that would break. So a
// failure ends the drain and the rest stays queued, which also means a peer that comes back
// half-working does not get a scrambled backlog.
//
// `attempts` is counted per item so an operator can see a peer that never succeeds. A queue growing
// silently is the failure mode this exists to prevent: without the count, a peer that has been gone
// for a week and one that is merely slow look identical from the outside.
// How many times a peer may REFUSE one item before it is given up on. Only refusals count against
// this; an unreachable peer is not the item's fault and never will be.
export const MAX_ATTEMPTS = 5;

export async function drain(db, { peerId, machine, deliver }) {
    const items = pending(db, peerId);
    const dropped = [];
    let sent = 0;
    for (const item of items) {
        let payload;
        try {
            payload = JSON.parse(item.payload);
        } catch {
            // An unparseable payload cannot be delivered by any number of retries, so it is dropped
            // rather than blocking every item behind it forever.
            forget(db, item.id);
            continue;
        }
        countAttempt(db, item.id);
        const result = await deliver({ kind: item.kind, payload, machine });
        if (!result || !result.ok) {
            // A REFUSAL and a FAILURE are different, and treating them alike blocks the queue forever.
            // If the peer answered and rejected the item -- a malformed payload, a schema it cannot
            // read -- no number of retries will change its mind, and every item behind it waits on one
            // that can never leave. So a well-formed refusal past the attempt ceiling is dropped and
            // counted, while an unreachable peer still stops the drain: THAT one is transient, and
            // skipping past it would deliver a speaker's messages out of order.
            const refused = result && (result.reason === 'bad_request' || result.reason === 'handler_error'
                                       || result.reason === 'unknown_op');
            if (refused && item.attempts + 1 >= MAX_ATTEMPTS) {
                forget(db, item.id);
                dropped.push({ id: item.id, kind: item.kind, reason: result.reason, attempts: item.attempts + 1 });
                continue;
            }
            return {
                ok: false, sent, dropped, remaining: depth(db, peerId), stopped_on: item.id,
                reason: (result && result.reason) || 'deliver_failed',
            };
        }
        forget(db, item.id);
        sent += 1;
    }
    return { ok: true, sent, dropped, remaining: depth(db, peerId) };
}
