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

import { hostname } from 'node:os';
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

// The announcement seam. The core does not know what a held HTTP response is, and must not: the
// registry of who is currently listening belongs to the transport, because that is where the
// connections are. So the core states what happened and the transport decides whether anybody
// cares -- and it is a no-op when nothing is listening, which is what makes the store usable from a
// test with no server at all.
//
// ADDITIVE, not a single slot. A single slot is silently wrong the moment a process holds two
// routers -- a second server, or a test building one alongside another -- because the second
// registration would replace the first and the first router's channels would go quiet with nothing
// reporting why. Each listener gets its own registration and its own way to remove it.
const announcers = new Set();
function announce(event) {
    for (const fn of announcers) {
        // One listener throwing must not stop the others being told, and must not fail the write
        // that triggered it: the message is already committed by this point.
        try { fn(event); } catch { /* a listener's fault is not the sender's */ }
    }
}
export function setAnnouncer(fn) {
    if (typeof fn !== 'function') return () => {};
    announcers.add(fn);
    return () => announcers.delete(fn);
}

const ok = (value = {}) => ({ ok: true, ...value });
// `extra` carries fields a caller needs in order to ACT on a refusal (a retry hint, say) as
// opposed to merely report it. Kept as a third parameter rather than folded into `detail`,
// because `detail` is prose for a human and these are values for a program.
const no = (reason, detail = null, extra = null) => ({
    ok: false, reason, ...(detail ? { detail } : {}), ...(extra || {}),
});

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

// This hub's own identity, and the default MATTERS more than it looks.
//
// It used to be the literal 'local', which meant two hubs that nobody configured shared an identity
// -- and sharing it fails SILENTLY in the worst possible way: `applyMembership` treats a peer's
// announcement as its own machine and ignores it, so each hub sees a channel with no remote members
// and every send is refused as `solo_channel`. An operator would see a refusal with no path to the
// cause.
//
// So the default is the HOSTNAME, which is unique on a LAN by the same convention that makes the LAN
// navigable at all, and the link refuses a peer that announces the same identity as ours rather than
// letting the collision turn into an unexplainable refusal later.
export function thisMachine() {
    if (process.env.AID_CHAT_MACHINE) return process.env.AID_CHAT_MACHINE;
    // `require` does not exist in an ES module, so an earlier version of this silently fell through
    // to 'local' -- which is the exact failure it was written to prevent, dressed as a fix.
    try {
        const h = hostname();
        if (h && h !== 'localhost') return h;
    } catch { /* fall through */ }
    return 'local';
}

// ---------------------------------------------------------------------------
// Sessions: registration, liveness, reattachment.

// --- Naming -----------------------------------------------------------------
//
// A name is `<adjective>-<noun>` -- `green-giraffe`, `proud-thistle` -- minted at random.
//
// It is NOT derived from the working directory, and three separate things rule that out. A directory
// basename collides constantly within one machine, where every checkout has a `src`. It collides
// ACROSS machines almost by construction, since two developers with the same project laid out the same
// way both produce `api`, and the federated roster then shows two identical names for two distinct
// sessions. And it says nothing about WHICH session it is when two tools run from one folder, which is
// an ordinary thing to do.
//
// A random name is opaque -- `proud-thistle` tells you nothing about what it is working on -- and that
// is the accepted cost. Uniqueness and memorability are worth more here: a name is something an agent
// has to type at another agent, and `aid chat rename` is one command away when the opacity bites.
//
// WHAT UNIQUENESS MEANS EXACTLY. `session.name` is UNIQUE, so a collision cannot happen on one hub:
// minting retries until it finds a free name. Across hubs it is improbable rather than impossible --
// roughly 11,000 combinations, so a handful of sessions collide with vanishing probability, and the
// addressing layer already treats a bare name as machine-qualifiable (`machine/name`) precisely
// because "the same short name on two machines is two distinct sessions" was always true.
const NAME_ADJECTIVES = [
    'amber', 'ancient', 'autumn', 'blue', 'bold', 'brave', 'bright', 'brisk', 'calm', 'candid',
    'cheerful', 'clever', 'cobalt', 'cool', 'coral', 'cosmic', 'crimson', 'crisp', 'curious', 'daring',
    'dawn', 'deep', 'deft', 'diligent', 'eager', 'early', 'easy', 'elder', 'electric', 'emerald',
    'fair', 'fearless', 'fleet', 'fond', 'frank', 'gentle', 'giddy', 'glad', 'golden', 'grand',
    'green', 'happy', 'hardy', 'hidden', 'honest', 'humble', 'indigo', 'ivory', 'jolly', 'keen',
    'kind', 'lively', 'lofty', 'loyal', 'lucid', 'lucky', 'merry', 'mighty', 'mild', 'modest',
    'noble', 'olive', 'patient', 'placid', 'polite', 'proud', 'quick', 'quiet', 'rapid', 'ready',
    'restless', 'rosy', 'royal', 'ruby', 'rustic', 'sage', 'scarlet', 'sharp', 'silent', 'silver',
    'sleek', 'slender', 'smart', 'smooth', 'snug', 'solemn', 'solid', 'spry', 'steady', 'stout',
    'sunny', 'swift', 'teal', 'tidy', 'tranquil', 'true', 'valiant', 'violet', 'vivid', 'warm',
    'watchful', 'willing', 'wise', 'witty', 'yellow', 'zesty',
];

const NAME_NOUNS = [
    'acorn', 'anchor', 'antler', 'anvil', 'arbor', 'arrow', 'badger', 'basin', 'beacon', 'beetle',
    'bison', 'blossom', 'boulder', 'branch', 'bridge', 'brook', 'burrow', 'canyon', 'cedar', 'chair',
    'cinder', 'cliff', 'clover', 'comet', 'compass', 'coral', 'cove', 'crane', 'crest', 'crow',
    'dolphin', 'donkey', 'dragon', 'ember', 'falcon', 'fathom', 'fennel', 'fern', 'ferry', 'fjord',
    'forge', 'fossil', 'fountain', 'garnet', 'gazelle', 'geyser', 'giraffe', 'glacier', 'glade',
    'granite', 'grotto', 'harbor', 'hazel', 'heron', 'hollow', 'ibis', 'island', 'jackal', 'jasmine',
    'kestrel', 'lagoon', 'lantern', 'ledger', 'lemur', 'lichen', 'lizard', 'lodge', 'lupine', 'magpie',
    'manor', 'maple', 'marble', 'meadow', 'mesa', 'minnow', 'mongoose', 'moth', 'nectar', 'nettle',
    'oriole', 'osprey', 'otter', 'panther', 'pebble', 'pelican', 'pillar', 'pinion', 'plateau',
    'quarry', 'quail', 'quartz', 'raven', 'reef', 'ridge', 'river', 'rookery', 'saffron', 'sparrow',
    'spruce', 'summit', 'thicket', 'thistle', 'tundra', 'valley', 'walrus', 'willow', 'yarrow',
];

export function mintSessionName(attempt = 0) {
    const adj = NAME_ADJECTIVES[Math.floor(Math.random() * NAME_ADJECTIVES.length)];
    const noun = NAME_NOUNS[Math.floor(Math.random() * NAME_NOUNS.length)];
    // The numeric tail appears only after random draws have repeatedly lost, so the common case stays
    // clean and the pathological one still terminates.
    return attempt > 0 ? `${adj}-${noun}-${attempt + 1}` : `${adj}-${noun}`;
}

// The name a session in THIS directory under THIS tool already goes by, or null.
//
// Keyed on the tool as well as the directory, and that is a correctness matter rather than a
// refinement: keyed on directory alone, starting Claude Code and Cursor from one folder made the
// second one REATTACH to the first one's session -- same name, same conversation id, one identity
// silently shared by two agents.
//
// Two sessions of the SAME tool in the SAME directory still cannot be told apart here, and that is a
// stated limit rather than a solved problem: pass `--name`, or set `AID_CHAT_SESSION`.
// The tool is OPTIONAL, because only `register` is told one -- `aid chat send` is not. So:
//
//   tool given     -> the session in this directory under that tool
//   tool omitted    -> the session in this directory, IF THERE IS EXACTLY ONE
//   two candidates  -> no answer, and the candidates are returned so the caller can say which
//
// Guessing when there are two would silently make one agent speak as another, which is the same defect
// as keying on the directory alone; refusing with the list is the only honest third case.
export function namesForCwd(db, cwd, tool = null) {
    if (!cwd) return { name: null, candidates: [] };
    const rows = tool
        ? db.prepare('SELECT name, tool FROM session WHERE cwd = ? AND tool = ? ORDER BY registered_at DESC').all(cwd, tool)
        : db.prepare('SELECT name, tool FROM session WHERE cwd = ? ORDER BY registered_at DESC').all(cwd);
    if (rows.length === 1) return { name: rows[0].name, candidates: rows };
    // More than one under a GIVEN tool means two sessions of that tool in one directory, which this
    // cannot resolve either -- the stated limit, reported rather than guessed at.
    return { name: null, candidates: rows };
}

export function nameForCwdTool(db, cwd, tool) {
    return namesForCwd(db, cwd, tool).name;
}

// Renaming is a rename of the SESSION and its MEMBERSHIP, and deliberately not of history.
//
// `message.sender_name` is left alone. The log records who said a thing at the time they said it, and
// that stays true after a rename; rewriting it would also break the idempotency and per-speaker
// uniqueness keys that include the sender name. So the roster shows the new name and the transcript
// keeps the old one, which is the honest reading of both.
export function rename(db, { name, to }) {
    if (!name || typeof name !== 'string') return no('bad_request', 'name is required');
    if (!to || typeof to !== 'string') return no('bad_request', 'to is required');
    if (!/^[A-Za-z0-9._-]{1,64}$/.test(to)) {
        return no('bad_request', 'a name may hold letters, digits, dot, underscore and hyphen, up to 64');
    }
    if (to === name) return ok({ renamed: false, name, reason: 'already_named_that' });

    const self = db.prepare('SELECT * FROM session WHERE name = ?').get(name);
    if (!self) return no(REFUSAL.NOT_REGISTERED);
    if (db.prepare('SELECT 1 FROM session WHERE name = ?').get(to)) {
        return no('name_taken', `"${to}" is already registered on this machine`);
    }

    const channelRow = self.channel_id
        ? db.prepare('SELECT name FROM channel WHERE id = ?').get(self.channel_id)
        : null;

    // LOCAL membership needs no rewrite, and it is worth being exact about why: `channel_member` holds
    // REMOTE members only -- a local session's membership IS `session.channel_id`. An earlier version
    // updated `channel_member` here under a comment about preventing ghost rows, which was dead code
    // making a false claim; on this machine there is no row to update.
    //
    // Peers are the ones holding a `channel_member` row under the old name, so the caller replicates
    // the change. That is returned rather than done here because core does no I/O.
    // PER-SPEAKER ORDERING KEYS ON THE NAME, so a rename mid-sequence has to restart the sequence or
    // it leaves a gap no message can ever fill.
    //
    // Readers hold an expected next `sender_seq` per (machine, sender_name) and HOLD BACK anything
    // ahead of it, on the sound assumption that a gap means a message still in flight. A rename breaks
    // that assumption: renaming after saying one thing made the next message (alice, seq 2) while
    // nothing had ever been (alice, seq 1), so the reader waited out the full gap grace on a message
    // that had already arrived. Measured: held_back true, and the message invisible until the grace
    // expired.
    //
    // The sequence continues from whatever this NAME has already said in this channel, which is right
    // in every direction: a fresh name starts at 1, and a name renamed BACK resumes above its own
    // earlier messages instead of colliding with them on the uniqueness key.
    //
    // The deeper fix is for the ordering key to be the session's stable id rather than its display
    // name; that is a schema change across the message table, the reorder path and replication, and is
    // recorded as debt rather than smuggled into a rename.
    try {
        db.exec('BEGIN IMMEDIATE');
        db.prepare('UPDATE session SET name = ? WHERE id = ?').run(to, self.id);
        if (self.channel_id) {
            const prior = db.prepare(
                `SELECT COALESCE(MAX(sender_seq), 0) AS hi FROM message
                 WHERE channel_id = ? AND sender_machine = ? AND sender_name = ?`,
            ).get(self.channel_id, thisMachine(), to);
            db.prepare('UPDATE session SET next_sender_seq = ? WHERE id = ?')
              .run(prior.hi + 1, self.id);
        }
        db.exec('COMMIT');
    } catch (e) {
        try { db.exec('ROLLBACK'); } catch { /* the failure below is the one that matters */ }
        return no('rename_failed', String(e && e.message ? e.message : e));
    }
    return ok({
        renamed: true,
        from: name,
        name: to,
        channel: channelRow ? channelRow.name : null,
    });
}

export function register(db, { name, tool, cwd, capabilities = {}, hostConversationId = null }) {
    if (!tool || typeof tool !== 'string') return no('bad_request', 'tool is required');
    // A missing name is RESOLVED, not refused: the directory's existing name if it has one, otherwise
    // a fresh minted one. Looking it up first is what makes a random name survive a restart.
    let minted = false;
    if (!name || typeof name !== 'string') {
        name = nameForCwdTool(db, cwd, tool);
        if (!name) {
            // Bounded, and the bound matters: UNIQUE on session.name means minting can lose a race,
            // and an unbounded retry would spin forever once the wordlist is exhausted.
            for (let attempt = 0; attempt < 64; attempt += 1) {
                const candidate = mintSessionName(attempt >= 32 ? attempt : 0);
                if (!db.prepare('SELECT 1 FROM session WHERE name = ?').get(candidate)) {
                    name = candidate;
                    break;
                }
            }
            if (!name) return no('name_exhausted', 'could not mint a free name for this directory');
            minted = true;
        }
    }
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
        return ok({ conversation_id: conversationId, name, minted, reattached: false, channel: null });
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
        name,
        minted: false,
        reattached: true,
        channel: channel ? channel.name : null,
        acked_seq: row.acked_seq,
    });
}

export function heartbeat(db, name) {
    const s = db.prepare('SELECT id FROM session WHERE name = ?').get(name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    db.prepare('UPDATE session SET last_heartbeat_at = ? WHERE id = ?').run(nowMs(), s.id);
    // Answers with the caller's current channel, because a connect outcome must be learnable on
    // its next call of ANY kind -- and heartbeat is the weakest call there is. Returning bare
    // `ok()` made that promise false for exactly the caller most likely to be relying on it: one
    // that is idle and doing nothing but keeping itself alive.
    const row = db.prepare('SELECT channel_id, delivered_seq, acked_seq FROM session WHERE id = ?').get(s.id);
    const ch = row.channel_id
        ? db.prepare('SELECT name FROM channel WHERE id = ?').get(row.channel_id)
        : null;
    return ok({
        channel: ch ? ch.name : null,
        delivered_seq: row.delivered_seq,
        acked_seq: row.acked_seq,
    });
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

// Is this name a CURRENT member of the channel, local or remote? Both halves, because a whisper to
// an agent on another machine is as legitimate as one to an agent here, and asking only about local
// sessions would refuse it.
function isMemberOf(db, channelId, who) {
    const local = db.prepare('SELECT 1 FROM session WHERE channel_id = ? AND name = ?').get(channelId, who);
    if (local) return true;
    const hasRemote = db.prepare(
        "SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name='channel_member'"
    ).get().n > 0;
    if (!hasRemote) return false;
    return !!db.prepare('SELECT 1 FROM channel_member WHERE channel_id = ? AND name = ?').get(channelId, who);
}

// THE ONE PLACE A WHISPER'S VISIBILITY IS DECIDED, and it exists as a named function precisely so
// there is nowhere else to decide it. The rule is the same on delivery and in history, and it has to
// be applied by every reader without exception -- including the operator's views, because an operator
// who could read whispers would make the guarantee a lie for everyone rather than just for them.
//
// A whisper is visible to its target and to its sender. The sender is included because a message you
// cannot see having sent is a message you cannot tell you sent.
export function whisperVisibleTo(message, viewerName) {
    if (!message.whisper_to) return true;
    return message.whisper_to === viewerName || message.sender_name === viewerName;
}

export function send(db, { name, body, kind = 'message', idempotencyKey = null,
                           mention = null, whisperTo = null, correlationId = null,
                           replyTo = null } = {}) {
    const s = getSession(db, name);
    if (!s) return no(REFUSAL.NOT_REGISTERED);
    if (!s.channel_id) return no(REFUSAL.NO_CHANNEL);
    if (typeof body !== 'string' || body.length === 0) return no('bad_request', 'body is required');
    if (mention && whisperTo) return no(REFUSAL.MENTION_AND_WHISPER);

    // A WHISPER IS REFUSED if its target is not a current member, and a MENTION of a non-member is
    // only WARNED about. The asymmetry is deliberate and follows from what each one promises: a
    // whisper narrows visibility to one named member, so a target who is not there means the message
    // has no reader at all and accepting it would be accepting a message nobody will ever see. A
    // mention only changes attention within full visibility -- everybody still receives it -- so a
    // stale or misspelled name costs nothing and refusing would throw away a message the channel can
    // still use.
    const warnings = [];
    if (whisperTo) {
        if (whisperTo === name) {
            return no(REFUSAL.WHISPER_NOT_MEMBER, 'a whisper to yourself has no other reader');
        }
        if (!isMemberOf(db, s.channel_id, whisperTo)) {
            return no(REFUSAL.WHISPER_NOT_MEMBER, `${whisperTo} is not a member of this channel`);
        }
    }
    if (mention) {
        const names = Array.isArray(mention) ? mention : [mention];
        for (const m of names) {
            if (!isMemberOf(db, s.channel_id, m)) {
                warnings.push({ mention: m, warning: 'not a member of this channel; the message was still sent' });
            }
        }
    }

    // Nobody else here: REFUSED rather than accepted. A message with no recipient that is
    // neither delivered nor reported as undelivered is the failure the overflow rule exists to
    // prevent, and accepting it silently would let that failure in by another door.
    if (otherMemberCount(db, s.channel_id, s.id) === 0) return no(REFUSAL.SOLO_CHANNEL);

    // The overflow check now happens INSIDE the transaction, with the same counter read the insert
    // uses. It was outside, with a comment explaining that the second read was safe because nothing
    // between them writes -- which was true and beside the point: two reads of a counter across a
    // transaction boundary is a shape that becomes a race the moment anything changes, and there was
    // no reason to keep it when one read serves both.

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
        if (maxUnreadDepth(db, s.channel_id, arrivalSeq - 1) >= limits().maxUnread) {
            db.exec('ROLLBACK');
            return no(REFUSAL.OVERFLOW);
        }
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
    // Announced AFTER the commit, so nothing can be woken to read a message that is not yet
    // durable. The announcement carries no body: a listener is told a channel advanced and reads
    // the store itself, which keeps one source of truth for what a message says.
    announce({ kind: 'message', channel_id: s.channel_id, arrival_seq: arrivalSeq, from: s.name });
    return ok({
        arrival_seq: arrivalSeq, idempotency_key: key, absorbed: false,
        ...(warnings.length ? { warnings } : {}),
    });
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
                // late, so it is discarded -- and reported, because the position must never
                // move backwards and a silent discard would be the one loss nobody could see.
                //
                // This is NARROWER than "the predecessor arrived late". It requires the reader
                // to have ACKNOWLEDGED past the skip: until it does, its baseline is still
                // behind the gap, the late predecessor is simply delivered in the right order,
                // and nothing is lost. The loss window is exactly "arrived after the reader
                // committed to a position past it" (see CO23).
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
    // Through `whisperVisibleTo` rather than an inline copy of the rule. An inline copy is how the
    // operator's views ended up needing their own, and two copies of a visibility rule is one too many.
    const visible = releasable.filter((m) => whisperVisibleTo(m, s.name));

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

// ---------------------------------------------------------------------------
// The hub plane (tasks 012 and 013).
//
// SEPARATE FROM THE MESSAGE PLANE, and separate for a reason that is easy to lose: this is
// SIGNALLING, not messaging. Hub membership is registration plus liveness -- not a held socket
// -- so an agent in no channel is still reachable, which is the whole point. Without this
// plane two idle agents deadlock: each is waiting to be told to talk, and neither can tell the
// other, because telling requires a channel and a channel requires somebody to have been told.

// `available` is COMPUTED at read time from three facts -- registered, not stale, not already
// in a channel -- and stored nowhere. A stored flag would need updating from every one of those
// three places, and the first one anybody forgets makes the roster lie about who can be reached.
function isAvailable(row, now) {
    return !isStale(row, now) && row.channel_id === null;
}

export function roster(db, { name = null } = {}) {
    const now = nowMs();
    const rows = db.prepare('SELECT * FROM session ORDER BY name').all();
    return ok({
        agents: rows.map((r) => ({
            name: r.name,
            tool: r.tool,
            capabilities: JSON.parse(r.capabilities || '{}'),
            // Liveness is reported as the observable fact (how long quiet) alongside the
            // derived judgement, so a caller can see WHY an agent is unavailable rather than
            // only that it is.
            quiet_for_ms: now - r.last_heartbeat_at,
            stale: isStale(r, now),
            in_channel: r.channel_id !== null,
            available: isAvailable(r, now),
            is_self: name !== null && r.name === name,
        })),
    });
}

// A directed connect request, answered FROM STATE with no accept step.
//
// The absence of an accept step is a measured decision, not a stylistic one: an accept would be
// a call the woken session makes, and on a host that gates an agent's calls behind human
// approval that call waits on a person. Answering from state removes the human from the path.
// Consent is not being modelled -- there is no authentication anywhere in this product, so a
// gate would be advisory at best. What the request supplies is NOTIFICATION, and availability
// is arbitrated by the one-channel bound.
//
// The channel is IMPLICIT: it is the asker's own, which is why the asker must already be in one.
// A request therefore always pulls a target into a conversation its asker is present in, never
// into an empty one.
export function connect(db, { name, target }) {
    const asker = getSession(db, name);
    if (!asker) return no(REFUSAL.NOT_REGISTERED);
    if (!target || typeof target !== 'string') return no('bad_request', 'target is required');
    // The asker must already be in the channel it names. This precondition is what makes
    // reciprocal arbitration free: see the comment on the two-failures case below.
    if (!asker.channel_id) return no(REFUSAL.NO_CHANNEL, 'open a channel before requesting a peer');
    if (target === name) return no(REFUSAL.TARGET_IS_SELF);

    const now = nowMs();
    const t = getSession(db, target);

    // Unknown, stale, and already-in-a-channel are ONE refusal with one token, deliberately --
    // but NOT for the reason first written here, which claimed the collapse denied an asker an
    // enumeration oracle over who exists on this hub. That claim was wrong, and wrong in a way
    // worth leaving recorded: the ROSTER already lists every session by name to every caller, so
    // there is nothing to withhold. Hiding "unknown" from "busy" here would have protected
    // nothing while making the refusal harder to act on.
    //
    // The real reason is simpler and honest: from the asker's side these are ONE fact -- that
    // agent cannot be pulled in right now -- so one token keeps a caller's branching to one
    // case, and `detail` says which, for whoever is reading.
    if (!t || isStale(t, now) || t.channel_id !== null) {
        const why = !t ? 'unknown' : (isStale(t, now) ? 'stale' : 'already in a channel');
        return no(REFUSAL.TARGET_UNAVAILABLE, why, {
            // Jittered, because two agents that each open a channel and then request the other
            // BOTH fail -- and if both then retried after the same fixed delay they would fail
            // each other again, indefinitely. That is a real livelock, not a theoretical one.
            // The hint is the node's, so the two ends cannot accidentally agree on a period.
            retry_after_ms: 250 + Math.floor(Math.random() * 750),
        });
    }

    // Joined in the SAME TRANSACTION that sets its positions to the channel head. Two statements
    // would leave a window where the target is a member with positions of 0 -- and a member at 0
    // in a channel whose head is 40 is owed forty messages it was never present for.
    //
    // Both preconditions are RE-READ inside the lock, not trusted from the checks above. Those
    // ran before `BEGIN IMMEDIATE` took the write lock, so between them and here the asker could
    // have left (closing the channel, if it was last) or the target could have been placed
    // elsewhere. Re-reading costs two statements and removes the window entirely; the alternative
    // is placing an agent into a channel that no longer exists.
    let channelName;
    db.exec('BEGIN IMMEDIATE');
    try {
        const chNow = db.prepare('SELECT * FROM channel WHERE id = ?').get(asker.channel_id);
        const askerNow = db.prepare('SELECT channel_id FROM session WHERE id = ?').get(asker.id);
        const targetNow = db.prepare('SELECT channel_id FROM session WHERE id = ?').get(t.id);
        if (!chNow || !askerNow || askerNow.channel_id !== asker.channel_id) {
            db.exec('ROLLBACK');
            return no(REFUSAL.CHANNEL_UNKNOWN, 'the channel closed while the request was in flight');
        }
        if (!targetNow || targetNow.channel_id !== null) {
            db.exec('ROLLBACK');
            return no(REFUSAL.TARGET_UNAVAILABLE, 'taken while the request was in flight', {
                retry_after_ms: 250 + Math.floor(Math.random() * 750),
            });
        }
        channelName = chNow.name;
        placeInChannel(db, t.id, asker.channel_id);
        db.exec('COMMIT');
    } catch (err) {
        db.exec('ROLLBACK');
        throw err;
    }

    // Nothing is recorded as pending, because there is nothing pending: being placed in the
    // channel IS the notification. That is what makes the outcome impossible to miss -- a
    // session between arms, mid-turn, or restarting reads it as state on its next call of any
    // kind, and there is no event to buffer or lose.
    // A connect outcome is announced FOR THE TARGET, not the channel: it is a change in that one
    // agent's own situation rather than content anybody else should be woken for.
    announce({ kind: 'connect', session_name: target, channel: channelName });
    return ok({
        connected: target,
        channel: channelName,
        joined_at_seq: db.prepare('SELECT acked_seq FROM session WHERE id = ?').get(t.id).acked_seq,
    });
}

// ---------------------------------------------------------------------------
// Retention (task-034).
//
// THE TRIM POINT IS PER HUB, and against THIS hub's own live members' acknowledged positions. Not
// against remote members: a hub cannot know whether an agent on another machine has read something,
// and waiting for an answer it cannot get would mean never trimming. Each hub keeps what its own
// members still need and no more, which is what makes retention a local decision rather than a
// distributed one.
//
// BOTH CONDITIONS ARE REQUIRED. Age alone never removes a message -- a message past its TTL that a
// live member has not acknowledged is KEPT, because "no message is lost while the conversation is
// live" is the durability promise and a clock is not a reader. And an acknowledged message younger
// than the TTL is kept too, so a reader that acknowledges instantly does not erase the history the
// others may still be reading.
export function trim(db, { now = nowMs() } = {}) {
    const { ttlMs } = limits();
    const cutoff = now - ttlMs;
    const removed = [];

    for (const ch of db.prepare('SELECT id, name FROM channel').all()) {
        // A REAPED member stops counting, and that falls out of reading the table rather than being
        // a rule of its own: reaping deletes the session row, so it is simply not here to hold the
        // point back. That is why reaping and trimming need no coordination.
        const positions = db.prepare('SELECT acked_seq FROM session WHERE channel_id = ?').all(ch.id);
        // No live local member: nothing here needs any of it, so the floor is the channel's own head
        // rather than a sentinel. Same effect and a real number -- MAX_SAFE_INTEGER was a value that
        // could never be a sequence, which is the sort of thing that reads as a bug to whoever finds
        // it next. The channel itself is closed by the reaping path, not by this one: trimming removes
        // messages, never channels.
        const head = db.prepare('SELECT next_seq FROM channel WHERE id = ?').get(ch.id).next_seq - 1;
        const floor = positions.length
            ? Math.min(...positions.map((p) => p.acked_seq))
            : head;

        const info = db.prepare(`DELETE FROM message
                                 WHERE channel_id = ? AND arrival_seq <= ? AND received_at < ?`)
                       .run(ch.id, floor, cutoff);
        if (info.changes > 0) {
            removed.push({ channel: ch.name, messages: info.changes, below_seq: floor });
        }
    }
    return ok({ trimmed: removed, ttl_ms: ttlMs });
}

// ---------------------------------------------------------------------------
// The audit log (task-035).
//
// THERE IS NO PLACE TO PUT A MESSAGE BODY, and that is the design rather than the discipline. The
// requirement is that an operator can see a whisper happened and between whom, and cannot read it --
// and a schema with a `body` column plus a rule saying "leave it null for whispers" is a rule one
// edit away from being broken by somebody who does not know why it is there. A schema with nowhere to
// put a body cannot be broken that way.
//
// `detail` is deliberately narrow: counts, reasons, positions. Never content.
export function audit(db, { event, actor = null, subject = null, channel = null, detail = null }) {
    // Never fatal. An audit write that failed and took the operation with it would make the log a
    // liability rather than a record -- the thing being recorded already happened.
    try {
        db.prepare('INSERT INTO audit(at, event, actor, subject, channel, detail) VALUES (?,?,?,?,?,?)')
          .run(nowMs(), event, actor, subject, channel, detail);
    } catch { /* the log is a record, not a precondition */ }
}

export function readAudit(db, { limit = 100 } = {}) {
    const rows = db.prepare('SELECT * FROM audit ORDER BY at DESC, id DESC LIMIT ?').all(limit);
    return ok({ entries: rows, note: 'this log records what happened; message bodies are not stored here' });
}

// ---------------------------------------------------------------------------
// Operator visibility (task-035).
//
// Reads what is in the store and computes what is derived, which is the same split as everywhere
// else: idle time is the observable fact, and it is the input to the one remedy this design leaves a
// human -- eviction. So it is reported as a number rather than a judgement.
// How many messages this member would actually be handed from here. Counted through the SAME
// visibility rule the read path uses, so the operator's number and the member's experience cannot
// disagree -- which they did when this was a subtraction.
function countVisibleAfter(db, channelId, ackedSeq, viewer) {
    const rows = db.prepare('SELECT sender_name, whisper_to FROM message WHERE channel_id = ? AND arrival_seq > ?')
                   .all(channelId, ackedSeq);
    return rows.filter((m) => whisperVisibleTo(m, viewer)).length;
}

export function operatorView(db) {
    const now = nowMs();
    const { staleMs, reapMs } = limits();

    const sessions = db.prepare('SELECT * FROM session ORDER BY name').all().map((r) => {
        const ch = r.channel_id
            ? db.prepare('SELECT name, next_seq FROM channel WHERE id = ?').get(r.channel_id)
            : null;
        return {
            name: r.name,
            tool: r.tool,
            cwd: r.cwd,
            machine: thisMachine(),
            channel: ch ? ch.name : null,
            // The two numbers an operator actually acts on -- and `unread` counts what this member
            // would ACTUALLY RECEIVE, not the positional gap. Those differ whenever somebody else's
            // whisper sits in the range: the positional gap would tell an operator a session is four
            // behind when `inbox` will hand it two, and an operator deciding whether to evict on that
            // number would be acting on a figure the session never sees.
            unread: ch ? countVisibleAfter(db, r.channel_id, r.acked_seq, r.name) : 0,
            idle_ms: now - r.last_heartbeat_at,
            stale: (now - r.last_heartbeat_at) > staleMs,
            reapable: (now - r.last_heartbeat_at) > reapMs,
            delivered_seq: r.delivered_seq,
            acked_seq: r.acked_seq,
        };
    });

    const hasRemote = db.prepare(
        "SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name='channel_member'"
    ).get().n > 0;

    const channels = db.prepare('SELECT * FROM channel ORDER BY name').all().map((c) => {
        const local = db.prepare('SELECT name, acked_seq FROM session WHERE channel_id = ? ORDER BY name')
                        .all(c.id);
        const remote = hasRemote
            ? db.prepare('SELECT machine, name FROM channel_member WHERE channel_id = ? ORDER BY machine, name').all(c.id)
            : [];
        const head = c.next_seq - 1;
        return {
            name: c.name,
            opened_at: c.opened_at,
            head_seq: head,
            stored_messages: db.prepare('SELECT COUNT(*) AS n FROM message WHERE channel_id = ?').get(c.id).n,
            members: [
                ...local.map((m) => ({
                    machine: thisMachine(), name: m.name,
                    unread: countVisibleAfter(db, c.id, m.acked_seq, m.name),
                })),
                // A remote member's unread depth is NOT reported, because this hub cannot know it --
                // acknowledged positions are local state on the machine that holds the member. Omitted
                // rather than guessed at, since a number an operator cannot trust is worse than none.
                ...remote.map((m) => ({ machine: m.machine, name: m.name, unread: null })),
            ],
        };
    });

    return ok({ machine: thisMachine(), sessions, channels });
}
