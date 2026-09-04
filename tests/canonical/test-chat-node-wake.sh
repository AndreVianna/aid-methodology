#!/usr/bin/env bash
# test-chat-node-wake.sh — the wake: the held wait, the subscriber, and both adapters.
#
# WHAT THIS SUITE CANNOT DO, stated first because it decides what everything below is worth: two of
# this delivery's criteria require a LIVE HOST SESSION, and no host session runs in this
# environment. `AC-1` needs a real Cursor session and a real Claude Code session exchanging a
# message; `AC-24` needs a host whose default is to gate an agent's privileged actions, in order to
# observe that no approval prompt appears. Neither can be simulated: a stub that never prompts
# proves nothing about a host that would. Both are recorded by name and steps in
# `chat-node/tests/MANUAL-PROCEDURES.md`, and the spike already ran both on two machines.
#
# What IS automatable is everything between the node and the adapter's stdout, and that is what
# these cases cover — driving each adapter exactly as its host would, by piping a stop payload to it.
#
# Held wait (task-016)
#   WK01  a message arriving while a wait is held resolves it, and the message is still in the store
#   WK02  a wait that times out returns cleanly and consumes nothing
#   WK03  a connect outcome resolves a held wait, tagged so it is distinguishable from a message
#   WK04  a client killed mid-wait leaves no held response: the count returns to where it started
#   WK05  restarting the node loses the registry and no message
#
# Subscriber (task-017, AC-12)
#   WK06  the block is min(long-poll, host_timeout - margin): 60 -> 30s, 20 -> 15s
#   WK07  with no flag it does not inherit a platform default, and reports what it used
#   WK08  messages arriving between arms are all delivered, in order, on the next arm
#   WK09  the wait holds in a process with no model in its path
#
# Adapters (tasks 018/019, AC-23, AC-25, AC-26)
#   WK10  Cursor: a BOM-prefixed payload is parsed and acted on
#   WK11  Cursor: the documented shape is `followup_message`, carrying the message text
#   WK12  Cursor: `loop_count` > 0 returns at once and starts no wait
#   WK13  Cursor: `decision: block` is never emitted, though it is known to work
#   WK14  Claude Code: the documented shape is `decision` + `reason`
#   WK15  Claude Code: `stop_hook_active` returns at once
#   WK16  Claude Code: the adapter's own count caps re-entry where the host caps nothing
#   WK17  both: the emitted acknowledge command has no backslash and names no interpreter
#   WK18  both: an over-running wake leaves no adapter process and no inflated waiter count
#   WK19  a connect outcome reaches an IDLE target through the wake, having called nothing first
#   WK20  the busy path: a message that arrived before the hook fired is found, not waited past
#
# Skill (task-020, AC-15)
#   WK21  the skill's verb list is exactly what the surface boundary permits
#   WK22  the skill documents no `wait`, and no administrative operation
#   WK23  it renders into all five profiles with a byte-identical body
#
# WK20 is the regression test for a defect this suite found: the adapters waited for a message to
# ARRIVE and never noticed one already pending, which broke the entire busy path.
#
# Usage: bash test-chat-node-wake.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not available" >&2; exit 0; }

_TMPD="$(mktemp -d)"

# Count only THIS suite's own hub processes, by matching its private runtime dir in each process's
# environment. A machine-wide count is unusable: run-all.sh dispatches suites concurrently, so a
# sibling's healthy node would read as this suite's leak.
_own_hubs() {
    local n=0 p
    for p in $(pgrep -f 'server/hub.mjs' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}"; then
            n=$((n + 1))
        fi
    done
    printf '%s\n' "$n"
}
# The adapter processes this suite started, counted the same way and for the same reason.
_own_adapters() {
    local n=0 p
    for p in $(pgrep -f 'chat-node/adapters/' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}"; then
            n=$((n + 1))
        fi
    done
    printf '%s\n' "$n"
}

export AID_CODE_HOME="$REPO_ROOT"
export AID_CHAT_RUNTIME="${_TMPD}/rt"
export AID_CHAT_STORE="${_TMPD}/rt/chat.db"
AID="bash ${REPO_ROOT}/bin/aid"
HUB=""
_cleanup() { $AID chat node stop >/dev/null 2>&1 || true; rm -rf "${_TMPD}"; }
trap _cleanup EXIT

_field() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval('d'+sys.argv[1]))" "$1"; }
_waiters() { curl -sS "${HUB}/waiters" 2>/dev/null | _field "['waiters_hint']"; }

$AID chat node start --port 0 >/dev/null 2>&1
HUB="http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")"
for n in alice bob idle; do $AID chat register --name "$n" --tool cursor >/dev/null 2>&1; done
$AID chat open --name alice --channel ch >/dev/null 2>&1
$AID chat join --name bob --channel ch >/dev/null 2>&1

# --- held wait --------------------------------------------------------------
curl -sS "${HUB}/wait?name=bob&block_ms=8000" > "${_TMPD}/w1.json" 2>/dev/null &
W=$!
sleep 0.5
held="$(_waiters)"
$AID chat send --name alice --body 'resolves the wait' >/dev/null 2>&1
wait $W 2>/dev/null
assert_eq "$held" "1" "WK01 a held wait is registered while it is held"
assert_eq "$(_field "['kind']" < "${_TMPD}/w1.json")" "message" "WK01 an arriving message resolves the held wait"
still="$($AID chat inbox --name bob 2>/dev/null | _field "['messages'].__len__()")"
if [[ "$still" -ge 1 ]]; then
    pass "WK01 and the message is still in the store: resolving a wait consumes nothing"
else
    fail "WK01 the message vanished when the wait resolved"
fi

t0=$(date +%s%N)
out="$(curl -sS "${HUB}/wait?name=alice&block_ms=800" 2>/dev/null)"
t1=$(( ($(date +%s%N) - t0) / 1000000 ))
assert_eq "$(printf '%s' "$out" | _field "['kind']")" "timeout" "WK02 a wait that expires returns kind=timeout"
assert_eq "$(printf '%s' "$out" | _field "['ok']")" "True" "WK02 and reports ok: a quiet minute is not a fault"
if [[ "$t1" -ge 700 && "$t1" -lt 3000 ]]; then
    pass "WK02 it blocked for about the requested time (${t1}ms)"
else
    fail "WK02 unexpected block duration: ${t1}ms for an 800ms request"
fi

curl -sS "${HUB}/wait?name=idle&block_ms=8000" > "${_TMPD}/w2.json" 2>/dev/null &
W2=$!
sleep 0.5
$AID chat connect --name alice --target idle >/dev/null 2>&1
wait $W2 2>/dev/null
assert_eq "$(_field "['kind']" < "${_TMPD}/w2.json")" "connect" "WK03 a connect outcome resolves a held wait, tagged as its own kind"
$AID chat leave --name idle >/dev/null 2>&1

before="$(_waiters)"
curl -sS "${HUB}/wait?name=bob&block_ms=30000" >/dev/null 2>&1 &
W3=$!
sleep 0.6
during="$(_waiters)"
kill -9 $W3 2>/dev/null; wait $W3 2>/dev/null
sleep 0.8
after="$(_waiters)"
assert_eq "${before},${during},${after}" "0,1,0" "WK04 a client killed mid-wait leaves no held response"

$AID chat node stop >/dev/null 2>&1
$AID chat node start --port 0 >/dev/null 2>&1
HUB="http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")"
assert_eq "$(_waiters)" "0" "WK05 restarting the node rebuilds the registry from nothing"
$AID chat send --name alice --body 'sent with nobody listening' >/dev/null 2>&1
got="$($AID chat inbox --name bob 2>/dev/null | python3 -c "import json,sys; print(any(m['body']=='sent with nobody listening' for m in json.load(sys.stdin)['messages']))")"
assert_eq "$got" "True" "WK05 and loses no message"

# --- subscriber -------------------------------------------------------------
arith="$(node --input-type=module -e "
import { blockMsFor } from '${REPO_ROOT}/chat-node/server/waiters.mjs';
console.log([60,20].map(t => blockMsFor({hostTimeoutSec:t}).blockMs).join(','));
")"
assert_eq "$arith" "30000,15000" "WK06 the block is min(long-poll, host_timeout - margin): 60 -> 30s, 20 -> 15s"

fallback="$(node --input-type=module -e "
import { blockMsFor, UNKNOWN_TIMEOUT_BLOCK_MS } from '${REPO_ROOT}/chat-node/server/waiters.mjs';
const r = blockMsFor({});
console.log([r.blockMs, r.basis, r.blockMs < 30000].join(','));
")"
assert_eq "$fallback" "10000,fallback-unknown-host-timeout,true" \
    "WK07 with no host timeout it uses a short fallback rather than inheriting a platform default, and names the basis"

# WK08 -- the re-arm window. Nothing is armed; three messages are sent; then one arm must return
# all of them, in order, from the store rather than waiting for a push.
$AID chat ack --name bob --cursor "$($AID chat inbox --name bob 2>/dev/null | _field "['delivered_seq']")" >/dev/null 2>&1
for i in 1 2 3; do $AID chat send --name alice --body "between-${i}" >/dev/null 2>&1; done
$AID chat subscribe --name bob --host-timeout 60 > "${_TMPD}/arm.json" 2>/dev/null
bodies="$(_field "[m['body'] for m in d['messages']]" < "${_TMPD}/arm.json" 2>/dev/null || python3 -c "
import json; print([m['body'] for m in json.load(open('${_TMPD}/arm.json'))['messages']])")"
assert_eq "$bodies" "['between-1', 'between-2', 'between-3']" \
    "WK08 messages arriving between arms are all delivered, in order, on the next arm"

$AID chat subscribe --name bob --host-timeout 60 >/dev/null 2>&1 &
W4=$!
sleep 0.6
model_calls="$(ps -o args= -p $W4 2>/dev/null | grep -ciE 'openai|anthropic|api\.|model' || true)"
assert_eq "$model_calls" "0" "WK09 the wait holds in a process with no model call in its path"
kill $W4 2>/dev/null; wait $W4 2>/dev/null

# --- adapters ---------------------------------------------------------------
_ack_cursor() { $AID chat ack --name bob --cursor "$($AID chat inbox --name bob 2>/dev/null | _field "['delivered_seq']")" >/dev/null 2>&1; }

_ack_cursor
$AID chat send --name alice --body 'text for cursor' >/dev/null 2>&1
printf '\xef\xbb\xbf{"loop_count":0,"conversation_id":"cv-1"}' \
    | node "${REPO_ROOT}/chat-node/adapters/cursor.mjs" --name bob --host-timeout 60 > "${_TMPD}/cur.json" 2>/dev/null
keys="$(python3 -c "import json; print(sorted(json.load(open('${_TMPD}/cur.json')).keys()))")"
assert_eq "$keys" "['followup_message']" "WK10/WK11 Cursor: a BOM-prefixed payload is parsed, and the reply is the documented shape"
carries="$(python3 -c "import json; print('text for cursor' in json.load(open('${_TMPD}/cur.json'))['followup_message'])")"
assert_eq "$carries" "True" "WK11 and it carries the message text, so the session need not call anything"

_ack_cursor
$AID chat send --name alice --body 'should not wake a follow-up' >/dev/null 2>&1
t0=$(date +%s%N)
printf '\xef\xbb\xbf{"loop_count":1,"conversation_id":"cv-1"}' \
    | node "${REPO_ROOT}/chat-node/adapters/cursor.mjs" --name bob --host-timeout 60 > "${_TMPD}/cur2.json" 2>/dev/null
t1=$(( ($(date +%s%N) - t0) / 1000000 ))
assert_eq "$(cat "${_TMPD}/cur2.json" | tr -d ' \n')" "{}" "WK12 Cursor: loop_count>0 declines to wake"
if [[ "$t1" -lt 2000 ]]; then
    pass "WK12 and returns at once (${t1}ms) rather than holding a wait"
else
    fail "WK12 it held a wait for ${t1}ms on the tail of a wake it had already served"
fi

emitted="$(grep -c '"decision"' "${_TMPD}/cur.json" "${_TMPD}/cur2.json" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')"
assert_eq "$emitted" "0" "WK13 Cursor: decision:block is never emitted, though it is known to work undocumented"

_ack_cursor
$AID chat send --name alice --body 'text for claude' >/dev/null 2>&1
echo '{"session_id":"s-1","stop_hook_active":false}' \
    | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 60 > "${_TMPD}/cc.json" 2>/dev/null
keys="$(python3 -c "import json; print(sorted(json.load(open('${_TMPD}/cc.json')).keys()))")"
assert_eq "$keys" "['decision', 'reason']" "WK14 Claude Code: the reply is that host's documented shape"

_ack_cursor
$AID chat send --name alice --body 'tail of a wake' >/dev/null 2>&1
echo '{"session_id":"s-1","stop_hook_active":true}' \
    | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 60 > "${_TMPD}/cc2.json" 2>/dev/null
assert_eq "$(cat "${_TMPD}/cc2.json" | tr -d ' \n')" "{}" "WK15 Claude Code: stop_hook_active declines to wake"

# WK16 -- the adapter's own count. On this host `loop_limit` is documented null, meaning uncapped,
# so this ceiling is the only backstop in existence.
rm -f "${AID_CHAT_RUNTIME}"/wake-*.count
declines=0
for i in 1 2 3; do
    _ack_cursor
    $AID chat send --name alice --body "loop-${i}" >/dev/null 2>&1
    echo '{"session_id":"s-count","stop_hook_active":false}' \
        | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 60 > "${_TMPD}/loop.json" 2>/dev/null
    if [[ "$(tr -d ' \n' < "${_TMPD}/loop.json")" == "{}" ]]; then declines=$((declines+1)); fi
done
if [[ "$declines" -ge 1 ]]; then
    pass "WK16 Claude Code: the adapter's own count caps re-entry where the host caps nothing (${declines} of 3 declined)"
else
    fail "WK16 the adapter woke on every attempt; with loop_limit null there is then no cap at all"
fi

hint="$(python3 -c "
import json,re
d=json.load(open('${_TMPD}/cur.json'))
t=d.get('followup_message','')
lines=[l for l in t.split(chr(10)) if 'chat ack' in l]
line=lines[0] if lines else ''
print('BACKSLASH' if chr(92) in line else 'ok', 'INTERP' if re.search(r'\b(bash|sh|python3?|node)\s', line) else 'ok')")"
assert_eq "$hint" "ok ok" "WK17 the emitted acknowledge command has no backslash and names no interpreter"

# WK18 -- an over-running wake leaves nothing behind. The adapter is given a host timeout it cannot
# satisfy, so it must decline to wait at all rather than block past what the host will wait for.
w_before="$(_waiters)"
a_before="$(_own_adapters)"
_ack_cursor
echo '{"session_id":"s-over","stop_hook_active":false}' \
    | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 5 >/dev/null 2>&1
sleep 0.6
assert_eq "$(_waiters)" "$w_before" "WK18 an over-running wake leaves the waiter count where it was"
assert_eq "$(_own_adapters)" "$a_before" "WK18 and leaves no adapter process behind"

# WK19 -- a connect outcome reaching an IDLE target through the wake, with the target having called
# nothing. This is the case the plan carries as its own criterion because no section-9 one covers it.
$AID chat register --name sleeper --tool cursor >/dev/null 2>&1
(printf '\xef\xbb\xbf{"loop_count":0,"conversation_id":"cv-sleep"}' \
    | node "${REPO_ROOT}/chat-node/adapters/cursor.mjs" --name sleeper --host-timeout 60 > "${_TMPD}/sleep.json" 2>/dev/null) &
W5=$!
sleep 0.8
$AID chat connect --name alice --target sleeper >/dev/null 2>&1
wait $W5 2>/dev/null
woke="$(python3 -c "
import json
try:
    d=json.load(open('${_TMPD}/sleep.json'))
    t=d.get('followup_message','')
    print('connected' if 'connected to the chat channel' in t else 'no')
except Exception: print('empty')")"
assert_eq "$woke" "connected" "WK19 a connect outcome reaches an idle target through the wake, it having called nothing first"

# WK20 -- the busy path, and the regression test for a defect that broke it entirely.
$AID chat leave --name sleeper >/dev/null 2>&1
_ack_cursor
$AID chat send --name alice --body 'arrived before the hook fired' >/dev/null 2>&1
t0=$(date +%s%N)
echo '{"session_id":"s-busy","stop_hook_active":false}' \
    | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 60 > "${_TMPD}/busy.json" 2>/dev/null
t1=$(( ($(date +%s%N) - t0) / 1000000 ))
found="$(python3 -c "
import json
d=json.load(open('${_TMPD}/busy.json'))
print('arrived before the hook fired' in d.get('reason',''))")"
assert_eq "$found" "True" "WK20 the busy path: a message already in the store is found rather than waited past"
if [[ "$t1" -lt 3000 ]]; then
    pass "WK20 and found at once (${t1}ms), not after a full block: reading precedes waiting"
else
    fail "WK20 it blocked ${t1}ms before noticing a message that was already there"
fi

# --- the skill --------------------------------------------------------------
SKILL="${REPO_ROOT}/canonical/skills/aid-chat/SKILL.md"
assert_file_exists "$SKILL" "WK21 the canonical chat skill exists"

# The permitted list, from the surface boundary: the message plane, the session's own channel, and
# the hub verbs. Diffed both ways, so an extra verb fails as loudly as a missing one.
permitted="ack connect inbox join leave list open roster send"
present="$(grep -oE '^aid chat [a-z-]+' "$SKILL" | awk '{print $3}' | sort -u | tr '\n' ' ' | sed 's/ $//')"
assert_eq "$present" "$permitted" "WK21 the skill's verb list is exactly what the surface boundary permits"

for forbidden in subscribe wait node reap; do
    if grep -qE "^aid chat ${forbidden}\b" "$SKILL"; then
        fail "WK22 the skill documents '${forbidden}', which the surface boundary forbids"
    fi
done
pass "WK22 the skill documents no wait, no node lifecycle, and no administrative verb"

rendered=0
bodies_same=1
ref=""
for prof in "claude-code/.claude" "codex/.codex" "cursor/.cursor" "copilot-cli/.github" "antigravity/.agent"; do
    f="${REPO_ROOT}/profiles/${prof}/skills/aid-chat/SKILL.md"
    [[ -f "$f" ]] || continue
    rendered=$((rendered+1))
    body="$(sed -n '/^---$/,/^---$/!p' "$f" | md5sum | cut -d' ' -f1)"
    [[ -z "$ref" ]] && ref="$body"
    [[ "$body" == "$ref" ]] || bodies_same=0
done
assert_eq "$rendered" "5" "WK23 the skill renders into all five profiles"
assert_eq "$bodies_same" "1" "WK23 with a byte-identical body in each: no hand-authored per-host variant"

# Non-automated checks are enumerated, not implied.
assert_file_contains "${REPO_ROOT}/chat-node/tests/MANUAL-PROCEDURES.md" "MP-05" \
    "the live-host criteria this suite cannot reach are recorded as manual procedures"

# Tear down FIRST, then measure, since the EXIT trap runs after this line.
_cleanup
trap - EXIT
sleep 0.3
leaked_h="$(_own_hubs)"
leaked_a="$(_own_adapters)"
assert_eq "${leaked_h},${leaked_a}" "0,0" "the suite leaves none of its own hub or adapter processes behind"

test_summary
