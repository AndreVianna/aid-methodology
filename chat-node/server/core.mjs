// chat-node/server/core.mjs -- the one core (FR-0.1).
//
// Every face is the `aid` CLI and every CLI verb is one call into this module. The HTTP layer
// parses and serialises; it holds no rules. This module holds every rule and is the only thing
// that touches the store.
//
// It is HOST-BLIND, deliberately and permanently (FR-5.11). A session declares which `tool`
// hosts it, and that value is recorded for the operator's benefit -- never read as a switch.
// If the core branched per host, every new host would touch the core and the store, and
// "only the adapter differs" would be false.
//
// REFUSALS ARE RETURN VALUES, NOT EXCEPTIONS. Every rule that can decline returns
// `{ ok: false, reason: '<stable-token>' }`, because a refusal here is an expected outcome a
// caller must be able to branch on -- "is the agent I want busy?" -- rather than a fault.
// A thrown error from this module means the core is broken; a refusal means it is working.

import { nowMs } from './store.mjs';
import { limits } from './settings.mjs';

// The stable stderr tokens, in one place so the CLI, the tests and the taxonomy cannot drift.
export const REFUSAL = {
    NOT_REGISTERED:        'not_registered',
    NO_CHANNEL:            'no_channel',
    ALREADY_IN_CHANNEL:    'already_in_channel',
    SOLO_CHANNEL:          'solo_channel',
    OVERFLOW:              'overflow',
    CHANNEL_UNKNOWN:       'channel_unknown',
    ACK_AHEAD:             'ack_ahead_of_delivered',
    MENTION_AND_WHISPER:   'mention_and_whisper',
    WHISPER_NOT_MEMBER:    'whisper_target_not_member',
    TARGET_UNAVAILABLE:    'target_unavailable',
    TARGET_IS_SELF:        'target_is_self',
};

const ok = (value = {}) => ({ ok: true, ...value });
const no = (reason, detail = null) => ({ ok: false, reason, ...(detail ? { detail } : {}) });

// ---------------------------------------------------------------------------
// Identity.
//
// The product mints its own conversation id and adopts no host's (FR-2.4). The reason is
// immutability and it is the product's to guarantee: an identifier the product does not issue
// is one whose stability it cannot promise, because another program may re-issue, re-scope or
// reuse it on its own schedule. A host-supplied id is recorded as correlation metadata beside
// it, so the product's log can be reconciled against the host's, and nothing keys on it.
export function mintConversationId() {
    return `cv_${globalThis.crypto.randomUUID()}`;
}

export function thisMachine() {
    return process.env.AID_CHAT_MACHINE || 'local';
}

// ---------------------------------------------------------------------------
// Sessions: registration, liveness, reattachment.

export function register(db, { name, tool, cwd, capabilities = {}, hostConversationId = null }) {
    if (!name || typeof name !== 'string') return no('bad_request', 'name is required');
    if (!tool || typeof tool !== 'string') return no('bad_request', 'tool is required');
    const caps = JSON.stringify(capabilities || {});
    const t = nowMs();

    const existing = db.prepare('SELECT * FROM session WHERE name = ?').get(name);
    if (!existing) {
        const conversationId = mintConversationId();
        db.prepare(`INSERT INTO session
            (name, conversation_id, tool, cwd, capabilities, host_conversation_id,
             registered_at, last_heartbeat_at)
            VALUES (?,?,?,?,?,?,?,?)`)
          .run(name, conversationId, tool, cwd || '', caps, hostConversationId, t, t);
        return ok({ conversation_id: conversationId, reattached: false, channel: null });
    }

    // Re-registering an existing name REATTACHES it -- but only to a channel that is still
    // open. Where the channel closed while the session was gone the name is re-registered with
    // no channel: reattachment restores a place in a conversation that still exists, and never
    // resurrects one that ended (FR-2.2). `channel_id` is already null in that case, because
    // closing a channel sets it null through the foreign key.
    db.prepare(`UPDATE session
                SET tool = ?, cwd = ?, capabilities = ?, host_conversation_id = ?,
                    last_heartbeat_at = ?
                WHERE id = ?`)
      .run(tool, cwd || '', caps, hostConversationId, t, existing.id);

    const row = db.prepare('SELECT * FROM session WHERE id = ?').get(existing.id);
    const channel = row.channel_id
        ? db.prepare('SELECT name FROM channel WHERE id = ?').get(row.channel_id)
        : null;
    return ok({
        conversation_id: row.conversation_id,   // unchanged: the id is the product's, and stable
        reattached: true,
        channel: channel ? channel.name : null,
        acked_seq: row.acked_seq,
    });
}

export function heartbeat(db, name) {
    const s = db.prepare('SELECT id FROM session WHERE name = ?').get(name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    db.prepare('UPDATE session SET last_heartbeat_at = ? WHERE id = ?').run(nowMs(), s.id);
    return ok();
}

// Stale is DERIVED, never stored: a stored flag and a missed heartbeat desynchronise, and then
// two places disagree about whether an agent is there.
export function isStale(row, now = nowMs()) {
    return (now - row.last_heartbeat_at) > limits().staleMs;
}
export function isReapable(row, now = nowMs()) {
    return (now - row.last_heartbeat_at) > limits().reapMs;
}

export function getSession(db, name) {
    return db.prepare('SELECT * FROM session WHERE name = ?').get(name) || null;
}

export function listSessions(db) {
    const now = nowMs();
    return db.prepare('SELECT * FROM session ORDER BY name').all().map((r) => ({
        name: r.name,
        tool: r.tool,
        cwd: r.cwd,
        capabilities: JSON.parse(r.capabilities || '{}'),
        conversation_id: r.conversation_id,
        stale: isStale(r, now),
        channel_id: r.channel_id,
        delivered_seq: r.delivered_seq,
        acked_seq: r.acked_seq,
    }));
}

// ---------------------------------------------------------------------------
// Channels (task-005).
//
// A channel is a NAME, not an object a machine owns: one name on every hub, replicated to
// each hub with a member in it, authoritative nowhere. Its life is bounded by its membership
// and never by a clock -- idle waiting is this product's normal state, so a timer here would
// destroy a conversation during exactly the case the product exists for.
//
// Membership is `session.channel_id`, a COLUMN rather than a join table, so the one-channel
// bound is a thing the store cannot represent otherwise. That is also why `send` needs no
// channel parameter.

function channelByName(db, name) {
    return db.prepare('SELECT * FROM channel WHERE name = ?').get(name) || null;
}

function membersOf(db, channelId) {
    return db.prepare('SELECT * FROM session WHERE channel_id = ? ORDER BY name').all(channelId);
}

// Joining sets BOTH positions to the channel's head, which is what implements join-at-head:
// a member receives what is said after it arrives and no history from before. Leaving them at
// 0 would hand a new member the entire backlog, which is the opposite of the rule.
function placeInChannel(db, sessionId, channelId) {
    const head = db.prepare('SELECT next_seq FROM channel WHERE id = ?').get(channelId).next_seq - 1;
    db.prepare(`UPDATE session
                SET channel_id = ?, delivered_seq = ?, acked_seq = ?, next_sender_seq = 1
                WHERE id = ?`).run(channelId, head, head, sessionId);
    return head;
}

export function openChannel(db, { name, channelName }) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (s.channel_id) return no(REFUSAL.ALREADY_IN_CHANNEL);
    if (!channelName) return no('bad_request', 'channel name is required');

    let ch = channelByName(db, channelName);
    const created = !ch;
    if (!ch) {
        db.prepare('INSERT INTO channel(name, opened_at) VALUES (?,?)').run(channelName, nowMs());
        ch = channelByName(db, channelName);
    }
    const head = placeInChannel(db, s.id, ch.id);
    // `created` reports which of the two things happened. Always answering true would make the
    // second agent to `open` the same name believe it had created the channel, which is exactly
    // the kind of small lie that a later reader builds on.
    return ok({ channel: ch.name, joined_at_seq: head, created });
}

export function joinChannel(db, { name, channelName }) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (s.channel_id) return no(REFUSAL.ALREADY_IN_CHANNEL);
    const ch = channelByName(db, channelName);
    if (!ch) return no(REFUSAL.CHANNEL_UNKNOWN);
    const head = placeInChannel(db, s.id, ch.id);
    return ok({ channel: ch.name, joined_at_seq: head });
}

// Leaving removes only this member. The channel closes when the LAST member is gone -- and
// closing deletes the row, which cascades its messages away and sets every former member's
// channel_id null. There is no closed state to observe: a closed channel is an absent one,
// which is what makes "reattaches only if the channel is still open" a null check.
//
// The creator holds no lasting claim: a channel does not close because whoever opened it left.
export function leaveChannel(db, { name }) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (!s.channel_id) return no(REFUSAL.NO_CHANNEL);
    const channelId = s.channel_id;
    db.prepare('UPDATE session SET channel_id = NULL, delivered_seq = 0, acked_seq = 0 WHERE id = ?')
      .run(s.id);
    const remaining = membersOf(db, channelId).length;
    let closed = false;
    if (remaining === 0) {
        db.prepare('DELETE FROM channel WHERE id = ?').run(channelId);
        closed = true;
    }
    return ok({ left: true, channel_closed: closed, remaining_members: remaining });
}

// Reaping is the RULE here; the periodic job that decides WHEN to reap is delivery-005's.
// FR-2.3 puts tracking with registration and reaping with retention, so this owns the effect
// and that owns the schedule. Deleting the member and closing its channel is ONE transaction:
// a crash between them would leave a channel with no members that nothing would ever close.
export function reapSession(db, { name }) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    const channelId = s.channel_id;
    let closed = false;
    db.exec('BEGIN IMMEDIATE');
    try {
        db.prepare('DELETE FROM session WHERE id = ?').run(s.id);
        if (channelId && membersOf(db, channelId).length === 0) {
            db.prepare('DELETE FROM channel WHERE id = ?').run(channelId);
            closed = true;
        }
        db.exec('COMMIT');
    } catch (err) {
        db.exec('ROLLBACK');
        throw err;
    }
    return ok({ reaped: name, channel_closed: closed });
}

// Reap every member quiet past the threshold. This is the RULE with a surface, so the criterion
// that says a channel closes when its last member is reaped can be exercised through the
// product rather than only through this module. The SCHEDULE -- deciding when to run this -- is
// still retention's, and nothing here runs it on a timer.
export function reapStale(db, { now = nowMs() } = {}) {
    const reaped = [];
    const closed = [];
    for (const row of db.prepare('SELECT * FROM session').all()) {
        if (!isReapable(row, now)) continue;
        const r = reapSession(db, { name: row.name });
        if (r.ok) {
            reaped.push(row.name);
            if (r.channel_closed) closed.push(row.name);
        }
    }
    return ok({ reaped, channels_closed: closed.length });
}

export function listChannels(db, { name = null } = {}) {
    const mine = name ? getSession(db, name) : null;
    return db.prepare('SELECT * FROM channel ORDER BY name').all().map((c) => ({
        name: c.name,
        opened_at: c.opened_at,
        members: membersOf(db, c.id).map((m) => m.name),
        is_mine: !!(mine && mine.channel_id === c.id),
    }));
}

// ---------------------------------------------------------------------------
// Sending (task-006).

function otherMemberCount(db, channelId, selfId) {
    const local = db.prepare('SELECT COUNT(*) AS n FROM session WHERE channel_id = ? AND id != ?')
                    .get(channelId, selfId).n;
    // The remote half is a SEAM, returning zero while federation's `channel_member` table does
    // not exist. Writing the count as one function from the start is what stops it being
    // quietly wrong the day federation lands; querying a table that is absent for three
    // deliveries would be the other, worse way to read "counts remote members from the start".
    const remote = remoteMemberCount(db, channelId);
    return local + remote;
}

// Filled in by federation. Until then a channel's membership is entirely local, so zero is
// the correct answer rather than a placeholder.
export function remoteMemberCount(db, channelId) {
    const hasTable = db.prepare(
        "SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name='channel_member'"
    ).get().n > 0;
    if (!hasTable) return 0;
    return db.prepare('SELECT COUNT(*) AS n FROM channel_member WHERE channel_id = ?')
             .get(channelId).n;
}

function maxUnreadDepth(db, channelId, headSeq) {
    const rows = db.prepare('SELECT acked_seq FROM session WHERE channel_id = ?').all(channelId);
    let worst = 0;
    for (const r of rows) worst = Math.max(worst, headSeq - r.acked_seq);
    return worst;
}

export function send(db, { name, body, kind = 'message', idempotencyKey = null,
                           mention = null, whisperTo = null, correlationId = null,
                           replyTo = null } = {}) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (!s.channel_id) return no(REFUSAL.NO_CHANNEL);
    if (typeof body !== 'string' || body.length === 0) return no('bad_request', 'body is required');
    if (mention && whisperTo) return no(REFUSAL.MENTION_AND_WHISPER);

    // Nobody else here: REFUSED rather than accepted. A message with no recipient that is
    // neither delivered nor reported as undelivered is the failure the overflow rule exists to
    // prevent, and accepting it silently would let that failure in by another door.
    if (otherMemberCount(db, s.channel_id, s.id) === 0) return no(REFUSAL.SOLO_CHANNEL);

    // The unread check reads `next_seq` only to compute the current head. The authoritative read
    // of that counter happens inside the transaction below, and nothing between the two writes
    // it -- but taking a second read across a transaction boundary is the shape that becomes a
    // race the moment this core is not single-threaded, so the boundary is named rather than
    // relied on: `BEGIN IMMEDIATE` takes the write lock before re-reading, and the value used
    // for the insert is only ever the one read inside.
    const headForDepth = db.prepare('SELECT next_seq FROM channel WHERE id = ?').get(s.channel_id).next_seq - 1;
    if (maxUnreadDepth(db, s.channel_id, headForDepth) >= limits().maxUnread) return no(REFUSAL.OVERFLOW);

    // The key is the caller's if given and minted here if not: FR-4.1 marks it optional, and a
    // NOT NULL column with no generation rule would turn an omitted optional into a constraint
    // violation. It is SENDER-SCOPED, so two senders numbering their own messages from 1
    // cannot swallow each other's.
    const key = idempotencyKey || `im_${globalThis.crypto.randomUUID()}`;
    const machine = thisMachine();

    const dup = db.prepare(`SELECT arrival_seq FROM message
                            WHERE channel_id = ? AND sender_machine = ? AND sender_name = ?
                              AND idempotency_key = ?`)
                  .get(s.channel_id, machine, s.name, key);
    if (dup) {
        // A retry must be SAFE, not visible. Answering with the original's position lets a
        // caller tell it was absorbed by comparing what came back.
        return ok({ arrival_seq: dup.arrival_seq, idempotency_key: key, absorbed: true });
    }

    const t = nowMs();
    let arrivalSeq;
    db.exec('BEGIN IMMEDIATE');
    try {
        // Both counters are COLUMNS, never a MAX() over the log: a MAX over a trimmed log
        // restarts at a number already used.
        arrivalSeq = db.prepare('SELECT next_seq FROM channel WHERE id = ?').get(s.channel_id).next_seq;
        const senderSeq = db.prepare('SELECT next_sender_seq FROM session WHERE id = ?').get(s.id).next_sender_seq;
        db.prepare(`INSERT INTO message
            (channel_id, arrival_seq, sender_name, sender_machine, sender_seq, idempotency_key,
             kind, body, correlation_id, reply_to, mention, whisper_to, sent_at, received_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
          .run(s.channel_id, arrivalSeq, s.name, machine, senderSeq, key, kind, body,
               correlationId, replyTo, mention ? JSON.stringify(mention) : null, whisperTo, t, t);
        db.prepare('UPDATE channel SET next_seq = next_seq + 1 WHERE id = ?').run(s.channel_id);
        db.prepare('UPDATE session SET next_sender_seq = next_sender_seq + 1 WHERE id = ?').run(s.id);
        db.exec('COMMIT');
    } catch (err) {
        db.exec('ROLLBACK');
        throw err;
    }
    return ok({ arrival_seq: arrivalSeq, idempotency_key: key, absorbed: false });
}

// ---------------------------------------------------------------------------
// Reading (tasks 007 and 008).
//
// Per-speaker FIFO is produced HERE, on read, not stored. Ordering is a delivery property:
// the store keeps each sender's own `sender_seq`, and this is what hands a sender's messages
// over in that sender's order even when they arrived interleaved.

function reorderPerSpeaker(rows, { graceMs, now, lastSeqBySender }) {
    // Group by speaker, then walk each speaker's messages in sender_seq order, holding back
    // at the first gap. Nothing is held back ACROSS speakers -- which is precisely why no
    // cross-speaker order is promised.
    const bySpeaker = new Map();
    for (const r of rows) {
        const k = `${r.sender_machine}/${r.sender_name}`;
        if (!bySpeaker.has(k)) bySpeaker.set(k, []);
        bySpeaker.get(k).push(r);
    }
    const releasable = [];
    const tooLate = [];
    let firstHeldBack = null;
    for (const [k, msgs] of bySpeaker) {
        msgs.sort((a, b) => a.sender_seq - b.sender_seq);
        let expected = (lastSeqBySender.get(k) || 0) + 1;
        for (const m of msgs) {
            if (m.sender_seq === expected) {
                releasable.push(m);
                expected += 1;
                continue;
            }
            if (m.sender_seq < expected) {
                // Not a gap: this message arrived BEHIND the point already reached, which
                // happens when a grace skip moved past it and the predecessor then turned up
                // after all. Releasing it here would hand the caller a message out of that
                // speaker's order, and treating it as a forward gap would stall the speaker
                // waiting for a predecessor that has already been passed. It is genuinely too
                // late: the skip was recorded when it happened, so the loss is on the record
                // rather than silent, and the position must never move backwards.
                m._arrived_too_late = expected;
                tooLate.push(m);
                continue;
            }
            // A gap. Normally the predecessor is in flight; hold this message back so the
            // answer is per-speaker FIFO rather than arrival order.
            //
            // But the rule MUST TERMINATE. A predecessor can be permanently absent -- trimmed
            // on the sending hub before it replicated, or lost with a hub that never came
            // back -- and without a bound every later message from that speaker would be held
            // on this hub forever, silently. So a gap older than the grace period is declared
            // permanent: the successor is released and the skip is recorded. Losing a message
            // is bad; losing a speaker is worse, and doing it with no error at all is worst.
            const age = now - m.received_at;
            if (age > graceMs) {
                m._skipped_from = expected;
                releasable.push(m);
                expected = m.sender_seq + 1;
                continue;
            }
            if (firstHeldBack === null || m.arrival_seq < firstHeldBack) firstHeldBack = m.arrival_seq;
            break;  // this speaker stalls here; later speakers are unaffected
        }
    }
    // Presentation order, and this is where a plausible-looking bug lived: sorting the whole
    // set by `arrival_seq` UNDOES the per-speaker ordering just computed. A message that
    // arrived out of order has a lower arrival_seq than its own predecessor, so a global
    // arrival sort hands one speaker's messages over in arrival order -- which is exactly the
    // guarantee section 6 declines to make, offered by accident in place of the one it does.
    //
    // What is both correct and useful: keep the ARRIVAL SLOTS the set occupies, and fill each
    // speaker's slots with that speaker's messages in `sender_seq` order. The result reads
    // roughly chronologically, and every speaker's own sequence is intact.
    const slotted = [];
    const released = new Set(releasable);   // O(1) lookup; the array scan was O(n*m)
    for (const msgs of bySpeaker.values()) {
        const mine = msgs.filter((m) => released.has(m));
        if (!mine.length) continue;
        const slots = mine.map((m) => m.arrival_seq).sort((a, b) => a - b);
        const inOrder = [...mine].sort((a, b) => a.sender_seq - b.sender_seq);
        inOrder.forEach((m, i) => slotted.push({ slot: slots[i], msg: m }));
    }
    slotted.sort((a, b) => a.slot - b.slot);
    return { releasable: slotted.map((x) => x.msg), firstHeldBack, tooLate };
}

function lastSeqPerSender(db, channelId, uptoSeq) {
    const rows = db.prepare(`SELECT sender_machine, sender_name, MAX(sender_seq) AS s
                             FROM message WHERE channel_id = ? AND arrival_seq <= ?
                             GROUP BY sender_machine, sender_name`).all(channelId, uptoSeq);
    const m = new Map();
    for (const r of rows) m.set(`${r.sender_machine}/${r.sender_name}`, r.s);
    return m;
}

export function inbox(db, { name, cursor = null } = {}) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (!s.channel_id) return no(REFUSAL.NO_CHANNEL);

    const override = cursor !== null && cursor !== undefined;
    const baseline = override ? Number(cursor) : s.acked_seq;
    if (override && (!Number.isInteger(baseline) || baseline < 0)) {
        return no('bad_request', 'cursor must be a non-negative integer');
    }

    const rows = db.prepare(`SELECT * FROM message
                             WHERE channel_id = ? AND arrival_seq > ?
                             ORDER BY arrival_seq`).all(s.channel_id, baseline);
    const now = nowMs();
    const { releasable, firstHeldBack, tooLate } = reorderPerSpeaker(rows, {
        graceMs: limits().gapGraceMs,
        now,
        lastSeqBySender: lastSeqPerSender(db, s.channel_id, baseline),
    });

    // Whisper filtering runs AFTER ordering, so a message this caller cannot see never creates
    // a gap for that speaker. The rule itself is delivery-005's; the point at which it applies
    // is fixed here.
    const visible = releasable.filter((m) => !m.whisper_to || m.whisper_to === s.name || m.sender_name === s.name);

    // `delivered_seq` advances to the END OF THE CONTIGUOUS PREFIX -- one below the first
    // held-back message, or the highest arrival_seq EXAMINED when nothing was held back.
    // Not to the last message returned: a held-back message has a LOWER arrival_seq than the
    // ones released after it, so advancing past it would strand it behind the cursor forever.
    //
    // "Examined" rather than "returned" is what covers the all-filtered case: a window whose
    // every message was somebody else's whisper is fully handed over as far as this caller is
    // concerned, and leaving the position behind would re-scan those rows on every later call.
    let prefixEnd;
    if (firstHeldBack !== null) {
        prefixEnd = firstHeldBack - 1;
    } else {
        prefixEnd = rows.length ? rows[rows.length - 1].arrival_seq : baseline;
    }

    // A cursor override is for RE-READING: it moves neither position, and therefore confers no
    // right to acknowledge. Making progress is what a bare inbox() is for.
    if (!override && prefixEnd > s.delivered_seq) {
        db.prepare('UPDATE session SET delivered_seq = ? WHERE id = ?').run(prefixEnd, s.id);
    }

    return ok({
        messages: visible.map((m) => ({
            arrival_seq: m.arrival_seq,
            from: m.sender_name,
            machine: m.sender_machine,
            sender_seq: m.sender_seq,
            kind: m.kind,
            body: m.body,
            idempotency_key: m.idempotency_key,
            correlation_id: m.correlation_id,
            reply_to: m.reply_to,
            mention: m.mention ? JSON.parse(m.mention) : null,
            whisper_to: m.whisper_to,
            sent_at: m.sent_at,
            ...(m._skipped_from ? { skipped_from_sender_seq: m._skipped_from } : {}),
        })),
        delivered_seq: override ? s.delivered_seq : Math.max(prefixEnd, s.delivered_seq),
        acked_seq: s.acked_seq,
        held_back: firstHeldBack !== null,
        // A message discarded for arriving behind a point already passed is REPORTED, not just
        // flagged on an object nobody reads. It is the only loss this design can produce, so the
        // caller learns of it in the same answer rather than never: the skip was recorded when
        // the grace period expired, and this is the other half of that record.
        discarded_too_late: tooLate.map((m) => ({
            from: m.sender_name, machine: m.sender_machine,
            sender_seq: m.sender_seq, expected_at_least: m._arrived_too_late,
        })),
        cursor_override: override,
    });
}

export function ack(db, { name, cursor }) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (!s.channel_id) return no(REFUSAL.NO_CHANNEL);
    const c = Number(cursor);
    if (!Number.isInteger(c) || c < 0) return no('bad_request', 'cursor must be a non-negative integer');
    // `acked` may never exceed `delivered`, and an ack beyond it FAILS rather than being
    // clamped: a session acknowledging what was never handed to it is a caller defect, and
    // silently clamping would hide the defect while skipping the messages in between.
    if (c > s.delivered_seq) return no(REFUSAL.ACK_AHEAD, `delivered_seq is ${s.delivered_seq}`);
    if (c > s.acked_seq) db.prepare('UPDATE session SET acked_seq = ? WHERE id = ?').run(c, s.id);
    return ok({ acked_seq: Math.max(c, s.acked_seq) });
}
