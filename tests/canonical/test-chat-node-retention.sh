#!/usr/bin/env bash
# test-chat-node-retention.sh — directed messages, retention, and operator visibility.
#
# Everything that only becomes meaningful once a channel has more than two members and a history.
# All of it is automatable: nothing here needs a live host or a second machine, so nothing here is
# deferred to a manual procedure.
#
# Directed messages (AC-17, AC-18)
#   RT01  a whispered message reaches only its target, in a channel of three
#   RT02  and is absent from every other member's HISTORY as well as their delivery
#   RT03  the sender can see its own whisper, because a message you cannot see having sent is
#         a message you cannot tell you sent
#   RT04  a whisper naming a non-member is refused
#   RT05  a whisper naming yourself is refused
#   RT06  a mentioned message reaches every member, and the mentioned one can tell it was aimed there
#   RT07  a mention of a non-member is WARNED about, not refused
#   RT08  mention and whisper on one message is refused
#   RT09  in a two-member channel a whisper is accepted and simply has no one to hide from
#
# The audit log
#   RT10  a whisper appears in the audit log with its parties
#   RT11  and NO message body appears anywhere in it, whispered or not
#   RT12  the audit schema has nowhere to put a body: the guarantee is structural, not a policy
#
# Retention (AC-11)
#   RT13  a message past its TTL that every live local member acknowledged is removed
#   RT14  a message past its TTL that a live member has NOT acknowledged is kept
#   RT15  an acknowledged message younger than the TTL is kept
#   RT16  a reaped member stops counting toward the trim point
#   RT17  the trim index exists, since the trim job is its only reader
#   RT18  the unread-depth bound is enforced, and is operator-settable
#
# Reaping (AC-11's last clause)
#   RT19  reaping the last member and closing its channel is one transaction
#   RT20  the reap threshold and the job interval come from settings, not from constants
#
# Operator visibility (AC-14)
#   RT21  the view shows machines, sessions, channels and members
#   RT22  with per-member unread depth and idle time, the input to eviction
#   RT23  a remote member's unread depth is reported as unknown rather than guessed
#   RT24  eviction removes a session from its channel and is audited
#   RT25  retention policy is settable through the CLI, and a bad value is refused
#
# Usage: bash test-chat-node-retention.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not available" >&2; exit 0; }

_TMPD="$(mktemp -d)"
export AID_CODE_HOME="$REPO_ROOT"
export AID_CHAT_RUNTIME="${_TMPD}/rt"
export AID_CHAT_STORE="${_TMPD}/rt/chat.db"
# The periodic jobs are OFF for this suite. Retention is exercised by invoking it directly, so a
# background timer firing mid-assertion would make results depend on wall-clock luck.
export AID_CHAT_JOB_INTERVAL_MS=0
AID="bash ${REPO_ROOT}/bin/aid"

_own_hubs() {
    local n=0 p
    for p in $(pgrep -f 'server/hub.mjs' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}"; then
            n=$((n + 1))
        fi
    done
    printf '%s\n' "$n"
}
_cleanup() { $AID chat node stop >/dev/null 2>&1 || true; rm -rf "${_TMPD}"; }
trap _cleanup EXIT

_j() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1]))" "$1"; }
_node() { { printf 'import * as S from %s;\nimport * as C from %s;\n' \
              "'${REPO_ROOT}/chat-node/server/store.mjs'" "'${REPO_ROOT}/chat-node/server/core.mjs'"
            cat; } > "${_TMPD}/t.mjs"; node "${_TMPD}/t.mjs"; }

$AID chat node start --port 0 >/dev/null 2>&1
for n in alice bob carol; do $AID chat register --name "$n" --tool cursor >/dev/null 2>&1; done
$AID chat open --name alice --channel team >/dev/null 2>&1
$AID chat join --name bob --channel team >/dev/null 2>&1
$AID chat join --name carol --channel team >/dev/null 2>&1

# --- directed messages ------------------------------------------------------
$AID chat send --name alice --body 'everyone sees this' >/dev/null 2>&1
$AID chat send --name alice --body 'only bob sees this' --whisper-to bob >/dev/null 2>&1
$AID chat send --name alice --body 'aimed at carol' --mention carol >/dev/null 2>&1

bob_sees="$($AID chat inbox --name bob --cursor 0 2>/dev/null | _j "[m['body'] for m in d['messages']]")"
carol_sees="$($AID chat inbox --name carol --cursor 0 2>/dev/null | _j "[m['body'] for m in d['messages']]")"
alice_sees="$($AID chat inbox --name alice --cursor 0 2>/dev/null | _j "[m['body'] for m in d['messages']]")"

assert_output_contains "$bob_sees" "only bob sees this" "RT01 a whisper reaches its target"
if printf '%s' "$carol_sees" | grep -q 'only bob sees this'; then
    fail "RT01 a third member saw a whisper that was not for them"
else
    pass "RT01 and reaches nobody else in a channel of three"
fi
# RT02 -- the SAME rule on history. Read from cursor 0, which re-reads everything the channel holds.
assert_eq "$carol_sees" "['everyone sees this', 'aimed at carol']" \
    "RT02 the whisper is absent from a non-target's HISTORY too, not only from delivery"
assert_output_contains "$alice_sees" "only bob sees this" \
    "RT03 the sender sees its own whisper: a message you cannot see having sent is one you cannot tell you sent"

err="$($AID chat send --name alice --body x --whisper-to nobody 2>&1 >/dev/null)"; rc=$?
assert_eq "$rc" "14" "RT04 a whisper naming a non-member is refused"
assert_output_contains "$err" "whisper_target_not_member" "RT04 with the reason named"
err="$($AID chat send --name alice --body x --whisper-to alice 2>&1 >/dev/null)"; rc=$?
assert_eq "$rc" "14" "RT05 a whisper naming yourself is refused: it has no other reader"

for who in bob carol; do
    got="$($AID chat inbox --name "$who" --cursor 0 2>/dev/null | _j "any(m['body']=='aimed at carol' for m in d['messages'])")"
    assert_eq "$got" "True" "RT06 a mentioned message still reaches ${who}: a mention changes attention, not visibility"
done
aimed="$($AID chat inbox --name carol --cursor 0 2>/dev/null | _j "[m['mention'] for m in d['messages'] if m['mention']]")"
assert_eq "$aimed" "[['carol']]" "RT06 and the mentioned member can tell it was aimed at them"

warned="$($AID chat send --name alice --body 'to a ghost' --mention ghost 2>/dev/null)"
assert_eq "$(printf '%s' "$warned" | _j "d['ok']")" "True" "RT07 a mention of a non-member is not refused"
assert_eq "$(printf '%s' "$warned" | _j "[w['mention'] for w in d['warnings']]")" "['ghost']" \
    "RT07 but it IS warned about, so a typo is visible rather than silent"

both="$(printf '%s' "$($AID chat send --name alice --body x --mention bob --whisper-to carol 2>&1 >/dev/null)")"
assert_output_contains "$both" "mention_and_whisper" "RT08 mention and whisper on one message is refused"

# RT09 -- two members. A whisper is still accepted; it simply has nobody to hide from, which is the
# irrelevance the requirement describes rather than a case to reject.
$AID chat register --name dan --tool cursor >/dev/null 2>&1
$AID chat register --name erin --tool cursor >/dev/null 2>&1
$AID chat open --name dan --channel pair >/dev/null 2>&1
$AID chat join --name erin --channel pair >/dev/null 2>&1
two="$($AID chat send --name dan --body 'pointless but legal' --whisper-to erin 2>/dev/null)"
assert_eq "$(printf '%s' "$two" | _j "d['ok']")" "True" "RT09 a whisper in a two-member channel is accepted: it has nobody to hide from"

# --- the audit log ----------------------------------------------------------
log="$($AID chat audit --limit 50 2>/dev/null)"
assert_eq "$(printf '%s' "$log" | _j "any(e['event']=='whisper' and e['actor']=='alice' and e['subject']=='bob' for e in d['entries'])")" \
    "True" "RT10 the audit log records that a whisper happened and between whom"

leaked=""
for body in 'only bob sees this' 'everyone sees this' 'aimed at carol' 'pointless but legal'; do
    if printf '%s' "$log" | grep -qF "$body"; then leaked="${leaked} [${body}]"; fi
done
if [[ -n "$leaked" ]]; then
    fail "RT11 a message body appeared in the audit log:${leaked}"
else
    pass "RT11 no message body appears in the audit log, whispered or not"
fi

cols="$(python3 -c "
import sqlite3
c=sqlite3.connect('${AID_CHAT_STORE}')
print(','.join(r[1] for r in c.execute(\"PRAGMA table_info('audit')\")))")"
case ",${cols}," in
    *",body,"*) fail "RT12 the audit table has a 'body' column, so the guarantee is a policy rather than a structure" ;;
    *) pass "RT12 the audit schema has nowhere to put a body: the guarantee is structural (columns: ${cols})" ;;
esac

# --- retention --------------------------------------------------------------
# Driven through the core against a scratch store, because the conditions involve ages and positions
# that are far cleaner to construct directly than to reach through the wire.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['a', 'b']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'a', channelName: 'ch' });
C.joinChannel(db, { name: 'b', channelName: 'ch' });
for (let i = 0; i < 4; i++) C.send(db, { name: 'a', body: 'm' + i });
// The first two are old; the last two are fresh.
db.prepare('UPDATE message SET received_at = ? WHERE arrival_seq <= 2').run(Date.now() - 90_000_000);
const ackAll = (who) => C.ack(db, { name: who, cursor: C.inbox(db, { name: who }).delivered_seq });
const count = () => db.prepare('SELECT COUNT(*) AS n FROM message').get().n;

ackAll('b');                    // only ONE of the two live members has acknowledged
C.trim(db);
const heldForUnacked = count();

ackAll('a');                    // now both have
C.trim(db);
const afterBothAcked = count();
process.stdout.write([heldForUnacked, afterBothAcked].join(','));
JS
)
assert_eq "$out" "4,2" "RT13/RT14/RT15 age alone removes nothing: an unacknowledged message is kept, and only acknowledged messages past the TTL go"

out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
for (const n of ['x', 'y']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'x', channelName: 'c2' });
C.joinChannel(db, { name: 'y', channelName: 'c2' });
C.send(db, { name: 'x', body: 'old' });
db.prepare('UPDATE message SET received_at = ?').run(Date.now() - 90_000_000);
C.ack(db, { name: 'x', cursor: C.inbox(db, { name: 'x' }).delivered_seq });
const count = () => db.prepare('SELECT COUNT(*) AS n FROM message').get().n;
C.trim(db);
const heldByY = count();        // y has acknowledged nothing, so it holds the point back
C.reapSession(db, { name: 'y' });
C.trim(db);
process.stdout.write([heldByY, count()].join(','));
JS
)
assert_eq "$out" "1,0" "RT16 a reaped member stops counting toward the trim point"

idx="$(python3 -c "
import sqlite3
c=sqlite3.connect('${AID_CHAT_STORE}')
print(bool(c.execute(\"SELECT 1 FROM sqlite_master WHERE type='index' AND name='message_trim'\").fetchone()))")"
assert_eq "$idx" "True" "RT17 the trim index exists, since the trim job is its only reader"

# RT18 -- the unread bound. The MECHANISM is delivery-001's send path; what this delivery adds is that
# the value is operator-settable, so both halves are checked together.
$AID chat retention --set maxUnread=2 >/dev/null 2>&1
assert_eq "$($AID chat retention 2>/dev/null | _j "d['limits']['maxUnread']")" "2" "RT18 the unread bound is operator-settable"
$AID chat register --name fred --tool cursor >/dev/null 2>&1
$AID chat register --name gina --tool cursor >/dev/null 2>&1
$AID chat open --name fred --channel bound >/dev/null 2>&1
$AID chat join --name gina --channel bound >/dev/null 2>&1
$AID chat send --name fred --body one >/dev/null 2>&1
$AID chat send --name fred --body two >/dev/null 2>&1
over="$($AID chat send --name fred --body three 2>&1 >/dev/null)"
assert_output_contains "$over" "overflow" "RT18 and is enforced: a third message past a bound of two is refused, not dropped"
$AID chat retention --set maxUnread=1000 >/dev/null 2>&1

# RT19 -- reaping the last member and closing its channel in one transaction. Asserted by outcome:
# no channel may survive with neither a local nor a remote member.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
C.register(db, { name: 'solo', tool: 't', cwd: '/' });
C.openChannel(db, { name: 'solo', channelName: 'lonely' });
const r = C.reapSession(db, { name: 'solo' });
const channels = db.prepare('SELECT COUNT(*) AS n FROM channel').get().n;
const sessions = db.prepare('SELECT COUNT(*) AS n FROM session').get().n;
process.stdout.write([r.channel_closed, channels, sessions].join(','));
JS
)
assert_eq "$out" "true,0,0" "RT19 reaping the last member closes its channel: no orphan can survive between the two"

settings_read="$(node --input-type=module -e "
import { LIMIT_ENV, limits } from '${REPO_ROOT}/chat-node/server/settings.mjs';
const need = ['ttlMs', 'maxUnread', 'reapMs', 'jobIntervalMs'];
console.log(need.every(k => k in LIMIT_ENV) && need.every(k => typeof limits()[k] === 'number'));
")"
assert_eq "$settings_read" "true" "RT20 the retention and reap parameters are read from the settings registry, not from constants"

# --- operator visibility ----------------------------------------------------
view="$($AID chat show 2>/dev/null)"
assert_eq "$(printf '%s' "$view" | _j "'machine' in d and 'sessions' in d and 'channels' in d")" "True" \
    "RT21 the operator view shows the machine, its sessions and its channels"
assert_eq "$(printf '%s' "$view" | _j "any(c['name']=='team' and len(c['members'])>=3 for c in d['channels'])")" "True" \
    "RT21 with each channel's members"
shape="$(printf '%s' "$view" | python3 -c "
import json,sys
s=[x for x in json.load(sys.stdin)['sessions'] if x['name']=='bob'][0]
need=('unread','idle_ms','stale','reapable')
print(','.join(k for k in need if k not in s) or 'complete')")"
assert_eq "$shape" "complete" "RT22 with per-member unread depth and idle time, the input to eviction"

# RT23 -- a remote member's unread depth is not this hub's to know, so it is reported as unknown.
remote_unread="$(python3 - "$AID_CHAT_STORE" "$AID" <<'PY'
import json, sqlite3, subprocess, sys
db, aid = sys.argv[1], sys.argv[2]
c = sqlite3.connect(db)
cid = c.execute("SELECT id FROM channel WHERE name='team'").fetchone()[0]
c.execute("INSERT OR REPLACE INTO channel_member(channel_id, machine, name, joined_at) VALUES (?,?,?,?)",
          (cid, 'elsewhere', 'faraway', 0))
c.commit(); c.close()
out = subprocess.run(aid.split() + ['chat', 'show'], capture_output=True, text=True).stdout
d = json.loads(out)
m = [x for x in next(ch for ch in d['channels'] if ch['name'] == 'team')['members'] if x['name'] == 'faraway']
print(m[0]['unread'] if m else 'ABSENT')
PY
)"
assert_eq "$remote_unread" "None" "RT23 a remote member's unread depth is reported as unknown rather than guessed at"

$AID chat evict --name carol >/dev/null 2>&1
assert_eq "$($AID chat show 2>/dev/null | _j "[s['channel'] for s in d['sessions'] if s['name']=='carol']")" "[None]" \
    "RT24 eviction removes a session from its channel"
assert_eq "$($AID chat audit --limit 5 2>/dev/null | _j "any(e['event']=='evict' and e['subject']=='carol' for e in d['entries'])")" \
    "True" "RT24 and is recorded in the audit log"

bad="$($AID chat retention --set ttlMs=-1 2>&1 >/dev/null)"
assert_output_contains "$bad" "non-negative" "RT25 a bad retention value is refused with a reason"
assert_eq "$($AID chat retention --set ttlMs=7000 2>/dev/null | _j "d['applied']['ttlMs']")" "7000" \
    "RT25 and a good one is applied and reported back"

# RT26 -- A RETENTION SETTING SURVIVES A RESTART. Without this, "operator-settable" is half a feature:
# the setting appears to work, and the evidence that it did not arrives hours later when messages the
# operator expected to be gone are still there.
$AID chat retention --set ttlMs=4242 >/dev/null 2>&1
$AID chat node stop >/dev/null 2>&1
$AID chat node start --port 0 >/dev/null 2>&1
assert_eq "$($AID chat retention 2>/dev/null | _j "d['limits']['ttlMs']")" "4242" \
    "RT26 a retention value set through the CLI is still in force after the node restarts"

# And an explicit environment variable still WINS over a persisted one, because that is how a test or
# a one-off run says "just for now" -- a persisted value that could not be overridden would be a file
# somebody has to find and delete.
$AID chat node stop >/dev/null 2>&1
AID_CHAT_TTL_MS=999 $AID chat node start --port 0 >/dev/null 2>&1
assert_eq "$($AID chat retention 2>/dev/null | _j "d['limits']['ttlMs']")" "999" \
    "RT26 an explicit environment variable still overrides a persisted setting"

# RT27 -- A WHISPER BODY DOES NOT CROSS TO A HUB THAT HOLDS NO TARGET. The read filter was always
# right, but replicating the body to every hub with any member put the text in stores where nobody was
# permitted to read it -- and a guarantee that rests on every future reader remembering to filter is
# not a guarantee. Checked at the REPLICATION DECISION rather than over a live link, because what is
# being asserted is which hubs are chosen.
whisper_targets="$(node --input-type=module -e "
import { openStore } from '${REPO_ROOT}/chat-node/server/store.mjs';
import * as C from '${REPO_ROOT}/chat-node/server/core.mjs';
import * as fed from '${REPO_ROOT}/chat-node/server/federation.mjs';
const db = await openStore({ path: ':memory:' });
for (const n of ['here', 'alsohere']) C.register(db, { name: n, tool: 't', cwd: '/' });
C.openChannel(db, { name: 'here', channelName: 'w' });
C.joinChannel(db, { name: 'alsohere', channelName: 'w' });
const cid = db.prepare('SELECT id FROM channel WHERE name=?').get('w').id;
// Two remote hubs hold members; only one holds the whisper target.
for (const [m, n] of [['hubA', 'target'], ['hubB', 'bystander']]) {
  db.prepare('INSERT INTO channel_member(channel_id, machine, name, joined_at) VALUES (?,?,?,1)').run(cid, m, n);
}
const mk = (whisperTo) => ({
  sender_machine: 'local', sender_name: 'here', sender_seq: 1,
  idempotency_key: 'k' + String(whisperTo), kind: 'message', body: 'secret',
  correlation_id: null, reply_to: null, mention: null, whisper_to: whisperTo, sent_at: 1,
});
const link = { isUp: () => false };   // nothing delivers; only the CHOICE of targets is asserted
const plain   = await fed.replicateMessage(db, link, { channelId: cid, channelName: 'w', message: mk(null) });
const remote  = await fed.replicateMessage(db, link, { channelId: cid, channelName: 'w', message: mk('target') });
const localTo = await fed.replicateMessage(db, link, { channelId: cid, channelName: 'w', message: mk('alsohere') });
const names = (r) => (r.replicated_to || []).map(x => x.machine).sort().join('+') || 'none';
console.log([names(plain), names(remote), names(localTo)].join('|'));
" 2>/dev/null)"
assert_eq "$whisper_targets" "hubA+hubB|hubA|none" \
    "RT27 a plain message goes to every hub with a member; a whisper goes ONLY to its target's hub; a whisper to a local member leaves this machine at all"

# Tear down FIRST, then measure, since the EXIT trap runs after this line.
_cleanup
trap - EXIT
sleep 0.3
assert_eq "$(_own_hubs)" "0" "the suite leaves none of its own hub processes behind"

test_summary
