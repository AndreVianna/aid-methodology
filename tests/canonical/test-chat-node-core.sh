#!/usr/bin/env bash
# test-chat-node-core.sh — the one core: registration, channels, send, ordering, positions.
#
# These are the rules the store cannot enforce on its own, so each is asserted against a real
# database through the core's own API rather than by reading the SQL.
#
# Registration and identity (task-004)
#   CO01  a product-minted conversation id; a host-supplied one is metadata nothing keys on
#   CO02  re-registering reattaches and KEEPS the same conversation id
#   CO03  re-registering after the channel closed reattaches to no channel
#   CO04  stale is derived from the heartbeat, not stored
#
# Channels and the one-channel bound (task-005)
#   CO05  open is create-and-join; a second join is refused with already_in_channel
#   CO06  join-at-head: a joiner gets what is said after it arrives, and no history
#   CO07  the creator leaving does not close the channel
#   CO08  the LAST member leaving closes it and its messages go with it
#   CO09  reaping the last member closes the channel in one transaction
#
# Send (task-006)
#   CO10  a send by the only member is refused with solo_channel
#   CO11  a send by a session in no channel is refused with no_channel
#   CO12  an idempotency retry is absorbed and returns the original position
#   CO13  the key is SENDER-SCOPED: two senders may use the same key
#   CO14  the unread bound refuses with overflow rather than dropping anything
#
# Ordering and positions (tasks 007, 008)
#   CO15  per-speaker FIFO holds even when a speaker's messages arrive out of order
#   CO16  a gap holds its successor back, and delivered stops BELOW the held-back message
#   CO17  a gap older than the grace period releases the successor and records the skip
#   CO18  a filtered-away message does not stall its speaker
#   CO19  delivered advances on an all-filtered window
#   CO20  a cursor override re-reads and moves neither position
#   CO21  an ack ahead of delivered is refused, not clamped
#   CO22  a delivered-but-unacknowledged message is presented again
#
# CO15 is the one that caught a real defect: an earlier read path sorted the whole result by
# arrival order, which silently replaced the per-speaker guarantee with the arrival guarantee
# the requirements decline to make.
#
# Usage: bash test-chat-node-core.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }

_TMPD="$(mktemp -d)"; trap 'rm -rf "${_TMPD}"' EXIT
_run() {  # stdin = module body; S = store, C = core
    { printf 'import * as S from %s;\nimport * as C from %s;\n' \
        "'${REPO_ROOT}/chat-node/server/store.mjs'" "'${REPO_ROOT}/chat-node/server/core.mjs'"
      cat; } > "${_TMPD}/t.mjs"
    node "${_TMPD}/t.mjs"
}

# ---- registration ----------------------------------------------------------
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
const r = C.register(db, { name: 'a', tool: 'cursor', cwd: '/x', hostConversationId: 'host-1' });
const row = db.prepare('SELECT conversation_id, host_conversation_id FROM session WHERE name=?').get('a');
process.stdout.write([
    r.conversation_id.startsWith('cv_'),
    row.conversation_id !== 'host-1',
    row.host_conversation_id === 'host-1',
].join(','));
JS
)
assert_eq "$out" "true,true,true" "CO01 the conversation id is product-minted; the host's is metadata only"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
const a = C.register(db, { name: 'a', tool: 't', cwd: '/' });
C.register(db, { name: 'b', tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' });
const again = C.register(db, { name: 'a', tool: 't', cwd: '/' });
process.stdout.write([again.reattached, again.channel, again.conversation_id === a.conversation_id].join(','));
JS
)
assert_eq "$out" "true,ch,true" "CO02 re-registering reattaches to the open channel and keeps the same conversation id"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'a', tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.leaveChannel(db, { name: 'a' });               // last member out: channel closes
const again = C.register(db, { name: 'a', tool: 't', cwd: '/' });
process.stdout.write([again.reattached, String(again.channel)].join(','));
JS
)
assert_eq "$out" "true,null" "CO03 re-registering after the channel closed reattaches to no channel"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'a', tool: 't', cwd: '/' });
const cols = db.prepare("SELECT name FROM pragma_table_info('session')").all().map(r => r.name);
db.prepare('UPDATE session SET last_heartbeat_at = ? WHERE name = ?').run(Date.now() - 3600e3, 'a');
const stale = C.listSessions(db)[0].stale;
process.stdout.write([cols.includes('stale'), stale].join(','));
JS
)
assert_eq "$out" "false,true" "CO04 stale is derived from the heartbeat and stored nowhere"

# ---- channels --------------------------------------------------------------
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'a', tool: 't', cwd: '/' });
const o = C.openChannel(db, { name: 'a', channelName: 'one' });
const j = C.joinChannel(db, { name: 'a', channelName: 'two' });
process.stdout.write([o.ok, j.ok, j.reason].join(','));
JS
)
assert_eq "$out" "true,false,already_in_channel" "CO05 open is create-and-join; a second join is refused"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b','late']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' });
C.send(db, { name: 'a', body: 'before' });
C.joinChannel(db, { name: 'late', channelName: 'ch' });
C.send(db, { name: 'a', body: 'after' });
const got = C.inbox(db, { name: 'late' }).messages.map(m => m.body);
process.stdout.write(got.join('|'));
JS
)
assert_eq "$out" "after" "CO06 join-at-head: a joiner receives only what was said after it arrived"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' });
const l = C.leaveChannel(db, { name: 'a' });     // the CREATOR leaves
process.stdout.write([l.channel_closed, C.listChannels(db).length].join(','));
JS
)
assert_eq "$out" "false,1" "CO07 the creator leaving does not close the channel"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' });
C.send(db, { name: 'a', body: 'x' });
C.leaveChannel(db, { name: 'a' });
const l = C.leaveChannel(db, { name: 'b' });     // the LAST member leaves
const msgs = db.prepare('SELECT COUNT(*) AS n FROM message').get().n;
process.stdout.write([l.channel_closed, C.listChannels(db).length, msgs].join(','));
JS
)
assert_eq "$out" "true,0,0" "CO08 the last member leaving closes the channel and its messages go with it"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'a', tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
const r = C.reapSession(db, { name: 'a' });
const orphan = db.prepare('SELECT COUNT(*) AS n FROM channel').get().n;
process.stdout.write([r.channel_closed, orphan].join(','));
JS
)
assert_eq "$out" "true,0" "CO09 reaping the last member closes its channel, leaving no zero-member channel"

# ---- send ------------------------------------------------------------------
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'a', tool: 't', cwd: '/' });
C.register(db, { name: 'lonely', tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
const solo = C.send(db, { name: 'a', body: 'anyone?' });
const none = C.send(db, { name: 'lonely', body: 'x' });
process.stdout.write([solo.reason, none.reason].join(','));
JS
)
assert_eq "$out" "solo_channel,no_channel" "CO10/CO11 a solo send and a send with no channel are both refused"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
const r1 = C.send(db, { name: 'a', body: 'm', idempotencyKey: 'k' });
const r2 = C.send(db, { name: 'a', body: 'm', idempotencyKey: 'k' });
const rb = C.send(db, { name: 'b', body: 'm', idempotencyKey: 'k' });
const n = db.prepare('SELECT COUNT(*) AS n FROM message').get().n;
process.stdout.write([r1.arrival_seq === r2.arrival_seq, r2.absorbed, rb.ok, n].join(','));
JS
)
assert_eq "$out" "true,true,true,2" "CO12/CO13 a retry is absorbed at the original position; the key is sender-scoped"

out=$(AID_CHAT_MAX_UNREAD=2 _run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
const rs = [C.send(db,{name:'a',body:'1'}), C.send(db,{name:'a',body:'2'}), C.send(db,{name:'a',body:'3'})];
const before = db.prepare('SELECT COUNT(*) AS n FROM message').get().n;
process.stdout.write([rs.filter(r=>r.ok).length, rs.find(r=>!r.ok) ? rs.find(r=>!r.ok).reason : 'none', before].join(','));
JS
)
assert_eq "$out" "2,overflow,2" "CO14 the unread bound refuses with overflow and drops nothing"

# ---- ordering and positions ------------------------------------------------
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
const id = db.prepare('SELECT id FROM channel WHERE name=?').get('ch').id;
const put = (who, sseq, aseq) => db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (?,?,?,?,?,?,?,1,?)')
    .run(id, aseq, who, 'local', sseq, who + sseq, who + sseq, Date.now());
put('a',1,1); put('a',3,2); put('b',1,3); put('a',2,4);   // a's seq 3 arrives before its seq 2
db.prepare('UPDATE channel SET next_seq=5 WHERE id=?').run(id);
const got = C.inbox(db, { name: 'r' }).messages.filter(m => m.from === 'a').map(m => m.sender_seq);
process.stdout.write(JSON.stringify(got));
JS
)
assert_eq "$out" "[1,2,3]" "CO15 per-speaker FIFO holds when a speaker's messages arrive out of order"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
const id = db.prepare('SELECT id FROM channel WHERE name=?').get('ch').id;
const put = (sseq, aseq) => db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (?,?,?,?,?,?,?,1,?)')
    .run(id, aseq, 'a', 'local', sseq, 'k' + sseq, 'm' + sseq, Date.now());
put(1,1); put(3,2);          // seq 2 is in flight; seq 3 must be held back
db.prepare('UPDATE channel SET next_seq=3 WHERE id=?').run(id);
const r = C.inbox(db, { name: 'r' });
process.stdout.write([r.held_back, r.messages.length, r.delivered_seq].join(','));
JS
)
assert_eq "$out" "true,1,1" "CO16 a gap holds its successor back, and delivered stops below the held-back message"

out=$(AID_CHAT_GAP_GRACE_MS=1 _run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
const id = db.prepare('SELECT id FROM channel WHERE name=?').get('ch').id;
db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (?,1,?,?,5,?,?,1,?)')
    .run(id, 'a', 'local', 'k', 'orphan', Date.now() - 5000);
db.prepare('UPDATE channel SET next_seq=2 WHERE id=?').run(id);
const r = C.inbox(db, { name: 'r' });
process.stdout.write([r.messages.length, r.messages[0].skipped_from_sender_seq, r.held_back].join(','));
JS
)
assert_eq "$out" "1,1,false" "CO17 a gap older than the grace period releases the successor and records the skip"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
C.send(db, { name: 'a', body: 'secret', whisperTo: 'b' });   // r must not see it
C.send(db, { name: 'a', body: 'next' });                     // and must not be stalled by it
const r = C.inbox(db, { name: 'r' });
process.stdout.write([r.messages.map(m => m.body).join('|'), r.held_back].join(','));
JS
)
assert_eq "$out" "next,false" "CO18 a message filtered away for this caller does not stall its speaker"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
C.send(db, { name: 'a', body: 'secret', whisperTo: 'b' });
const r = C.inbox(db, { name: 'r' });   // every message filtered away
process.stdout.write([r.messages.length, r.delivered_seq].join(','));
JS
)
assert_eq "$out" "0,1" "CO19 delivered advances on a window whose every message was filtered away"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
C.send(db, { name: 'a', body: 'm1' });
const first = C.inbox(db, { name: 'b' });
C.ack(db, { name: 'b', cursor: first.delivered_seq });
const over = C.inbox(db, { name: 'b', cursor: 0 });
const row = db.prepare('SELECT delivered_seq, acked_seq FROM session WHERE name=?').get('b');
const ahead = C.ack(db, { name: 'b', cursor: 99 });
process.stdout.write([over.messages.length, over.cursor_override, row.delivered_seq, row.acked_seq, ahead.reason].join(','));
JS
)
assert_eq "$out" "1,true,1,1,ack_ahead_of_delivered" "CO20/CO21 a cursor override re-reads and moves nothing; an ack ahead of delivered is refused"

out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
const sent = C.send(db, { name: 'a', body: 'm1' });
C.inbox(db, { name: 'b' });                       // delivered advances; b never acknowledges
const again = C.inbox(db, { name: 'b' });         // a fresh read still returns it
process.stdout.write([again.messages.length, again.messages[0] ? again.messages[0].idempotency_key === sent.idempotency_key : false].join(','));
JS
)
assert_eq "$out" "1,true" "CO22 a delivered-but-unacknowledged message is presented again, identifiable by its key"

# CO23 — the complement of CO17. A grace skip releases a successor; the predecessor then turns
# up anyway. It must NOT be released (that would be out of that speaker's order), must NOT stall
# the speaker (it is already past), and must be REPORTED rather than silently dropped -- the
# discard is the only loss this design can produce, so it is the one that must be visible.
#
# The ACK in the middle is load-bearing, and writing this test is what established why: the
# discard happens only once the reader has ACKNOWLEDGED past the skip. Before that its baseline
# is still behind the gap, so a late predecessor is simply delivered in the right order and
# nothing is lost at all. The window for loss is therefore narrower than "a predecessor arrived
# late" -- it is "a predecessor arrived after the reader had already committed to a position past
# it", which is the only point at which taking it back would move a position backwards.
out=$(AID_CHAT_GAP_GRACE_MS=1 _run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','r']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'r', channelName: 'ch' });
const id = db.prepare('SELECT id FROM channel WHERE name=?').get('ch').id;
const put = (sseq, aseq, age) => db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (?,?,?,?,?,?,?,1,?)')
    .run(id, aseq, 'a', 'local', sseq, 'k' + sseq, 'm' + sseq, Date.now() - age);
put(2, 1, 5000);                 // seq 2 arrives with seq 1 missing and the grace long expired
db.prepare('UPDATE channel SET next_seq=2 WHERE id=?').run(id);
const first = C.inbox(db, { name: 'r' });        // releases seq 2, recording the skip
C.ack(db, { name: 'r', cursor: first.delivered_seq });   // and the reader ACKNOWLEDGES it
put(1, 2, 0);                                    // seq 1 turns up AFTER the skip passed it
db.prepare('UPDATE channel SET next_seq=3 WHERE id=?').run(id);
const second = C.inbox(db, { name: 'r' });
process.stdout.write([
    first.messages.length, first.messages[0].skipped_from_sender_seq,
    second.messages.length,                       // the late predecessor is NOT released
    second.discarded_too_late.length,              // it IS reported
    second.discarded_too_late[0] ? second.discarded_too_late[0].sender_seq : 'none',
    second.held_back,                              // and it does not stall the speaker
].join(','));
JS
)
assert_eq "$out" "1,1,0,1,1,false" "CO23 a predecessor arriving after a grace skip is not released, not stalling, and reported as discarded"

# CO24 -- connect's preconditions are re-read INSIDE the write lock rather than trusted from the
# checks that ran before it.
#
# Stated plainly: with foreign keys on and a single-threaded core, the interleaving this guards
# against CANNOT currently occur -- the schema will not even let the inconsistent state be
# constructed, which is why an earlier version of this test failed rather than passing. The guard
# is depth, not a fix for a live defect. To test it at all, the state has to be built with
# foreign keys briefly off, which is honest about what is being verified: not that the race
# happens, but that the guard would catch it if it ever could.
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['asker','target']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'asker', channelName: 'ch' });
const chId = db.prepare('SELECT id FROM channel WHERE name=?').get('ch').id;
db.exec('PRAGMA foreign_keys = OFF');
db.prepare('DELETE FROM channel WHERE id = ?').run(chId);
db.prepare('UPDATE session SET channel_id = ? WHERE name = ?').run(chId, 'asker');
db.exec('PRAGMA foreign_keys = ON');
const r = C.connect(db, { name: 'asker', target: 'target' });
const placed = db.prepare('SELECT channel_id FROM session WHERE name=?').get('target').channel_id;
process.stdout.write([r.ok, r.reason, String(placed)].join(','));
JS
)
assert_eq "$out" "false,channel_unknown,null" "CO24 connect re-reads under the lock: a vanished channel is refused and nobody is placed"

# CO25 -- heartbeat reports the caller's channel, so a connect outcome is learnable on the
# weakest call an agent can make.
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
const before = C.heartbeat(db, 'b');
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.connect(db, { name: 'a', target: 'b' });
const after = C.heartbeat(db, 'b');
process.stdout.write([String(before.channel), String(after.channel)].join(','));
JS
)
assert_eq "$out" "null,ch" "CO25 heartbeat reports the channel, so the outcome is learnable on the weakest call there is"

# CO26 -- two routers in one process must not clobber each other's announcer. A single slot is
# silently wrong here: the second registration would replace the first, and the first router's
# channels would go quiet with nothing reporting why.
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
const heard = [];
const offOne = C.setAnnouncer(() => heard.push('one'));
C.setAnnouncer(() => heard.push('two'));
C.send(db, { name: 'a', body: 'both listeners should hear this' });
// And removing one must leave the other working.
offOne();
C.send(db, { name: 'a', body: 'only the second now' });
process.stdout.write(heard.join(','));
JS
)
assert_eq "$out" "one,two,two" "CO26 two announcers both hear an event, and removing one leaves the other working"

# CO27 -- one listener throwing must not stop the others being told, and must not fail the send:
# the message is already committed by the time anybody is announced to.
out=$(_run <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a','b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' }); C.joinChannel(db, { name: 'b', channelName: 'ch' });
const heard = [];
C.setAnnouncer(() => { throw new Error('a listener fault'); });
C.setAnnouncer(() => heard.push('still told'));
const r = C.send(db, { name: 'a', body: 'x' });
const stored = db.prepare('SELECT COUNT(*) AS n FROM message').get().n;
process.stdout.write([r.ok, heard.join('|'), stored].join(','));
JS
)
assert_eq "$out" "true,still told,1" "CO27 a throwing announcer neither fails the send nor silences the others"

test_summary
