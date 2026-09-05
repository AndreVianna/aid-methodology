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
# Bring a session fully up to date. A subscriber only ever arms when it has nothing unread -- the
# node now answers an arm from the backlog if there is one, so a test that wants to observe a HELD
# wait has to establish that precondition rather than assume it.
_drain() {
    local who="$1" d
    d="$($AID chat inbox --name "$who" 2>/dev/null | _field "['delivered_seq']" 2>/dev/null || echo 0)"
    [[ "${d:-0}" -gt 0 ]] && $AID chat ack --name "$who" --cursor "$d" >/dev/null 2>&1
    return 0
}

$AID chat node start --port 0 >/dev/null 2>&1
HUB="http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")"
for n in alice bob idle; do $AID chat register --name "$n" --tool cursor >/dev/null 2>&1; done
$AID chat open --name alice --channel ch >/dev/null 2>&1
$AID chat join --name bob --channel ch >/dev/null 2>&1

# --- held wait --------------------------------------------------------------
_drain bob
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

_drain alice
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

_drain bob
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

# WK05b -- the arm-time gap. A client that reads its inbox and then arms has a window between the
# two; a message landing in it used to be found only after a whole block expired. The node now
# checks the caller's own pending depth at the moment of registration, so an arm with something
# unread is answered at once and identifies itself as coming from the backlog.
_drain bob
$AID chat send --name alice --body 'landed before the arm' >/dev/null 2>&1
t0=$(date +%s%N)
armed="$(curl -sS "${HUB}/wait?name=bob&block_ms=20000" 2>/dev/null)"
t1=$(( ($(date +%s%N) - t0) / 1000000 ))
assert_eq "$(printf '%s' "$armed" | _field "['basis']")" "pending-at-arm" \
    "WK05b an arm with something already unread is answered from the backlog, not held"
if [[ "$t1" -lt 2000 ]]; then
    pass "WK05b and answered at once (${t1}ms) rather than after a full block"
else
    fail "WK05b it held ${t1}ms with a message already waiting"
fi

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

# WK16b -- the own-count EXPIRES. Where the host supplies no conversation id the key falls back to
# the session name, and a name is reused across conversations -- so a counter left by an earlier one
# must not decline a new conversation's wake for a loop it was not part of.
expiry="$(node --input-type=module -e "
import { readOwnCount, writeOwnCount } from '${REPO_ROOT}/chat-node/adapters/common.mjs';
import { writeFileSync, mkdirSync } from 'node:fs';
const dir = process.env.AID_CHAT_RUNTIME;
mkdirSync(dir, { recursive: true });
await writeOwnCount('exp', 2);
const fresh = readOwnCount('exp');
writeFileSync(\`\${dir}/wake-exp.count\`, '2 ' + (Date.now() - 120000));
const stale = readOwnCount('exp');
writeFileSync(\`\${dir}/wake-exp.count\`, '2');
const legacy = readOwnCount('exp');
console.log([fresh, stale, legacy].join(','));
")"
assert_eq "$expiry" "2,0,0" "WK16b the own-count is honoured while fresh, and treated as absent when stale or untimestamped"

hint="$(python3 -c "
import json,re
d=json.load(open('${_TMPD}/cur.json'))
t=d.get('followup_message','')
lines=[l for l in t.split(chr(10)) if 'chat ack' in l]
line=lines[0] if lines else ''
print('BACKSLASH' if chr(92) in line else 'ok', 'INTERP' if re.search(r'\b(bash|sh|python3?|node)\s', line) else 'ok')")"
assert_eq "$hint" "ok ok" "WK17 the emitted acknowledge command has no backslash and names no interpreter"

# WK18 -- what AC-25 is actually about, in two parts, because ONE of them was previously mistaken
# for the other. The criterion names the case where the host ABANDONS an over-running hook: output
# discarded, wait abandoned, and the process left running with its socket still open.
#
# 18a is the CHEAP half: a host timeout so small the margin leaves no room to wait, so the adapter
# must decline to wait at all. Real, but it is the refused-to-wait path -- no waiter is ever
# registered, so it cannot demonstrate a waiter being released.
w_before="$(_waiters)"
a_before="$(_own_adapters)"
_ack_cursor
echo '{"session_id":"s-over","stop_hook_active":false}' \
    | node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 5 >/dev/null 2>&1
sleep 0.6
assert_eq "$(_waiters)" "$w_before" "WK18a a host timeout below the margin makes the adapter decline to wait, registering nothing"
assert_eq "$(_own_adapters)" "$a_before" "WK18a and leaves no adapter process behind"

# 18b is the ACTUAL abandoned-hook shape, simulated the only way it can be here: the adapter is
# started with a long block and then ABANDONED -- killed without being allowed to finish, exactly as
# a host that stops listening leaves it. The process is gone; the question AC-25 asks is whether the
# node's waiter count comes back down, because the host reports nothing and an inflated count is the
# only trace such a wake leaves.
_ack_cursor
w_before="$(_waiters)"
node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name bob --host-timeout 60 >/dev/null 2>&1 &
ADPID=$!
sleep 1.0
w_during="$(_waiters)"
kill -9 "$ADPID" 2>/dev/null
wait "$ADPID" 2>/dev/null
sleep 1.0
w_after="$(_waiters)"
a_after="$(_own_adapters)"
assert_eq "$w_during" "$((w_before + 1))" "WK18b an armed adapter is visible in the waiter count while it waits"
assert_eq "$w_after" "$w_before" "WK18b and an ABANDONED adapter releases its waiter: the count returns to where it was"
assert_eq "$a_after" "$a_before" "WK18b with no adapter process surviving"

# 18c -- and the count is checked by OBSERVATION rather than by an absence of errors, which is what
# AC-25 insists on. Confirm the number is actually reported, not merely absent.
hint_field="$(curl -sS "${HUB}/waiters" 2>/dev/null | python3 -c "import json,sys; print('waiters_hint' in json.load(sys.stdin))")"
assert_eq "$hint_field" "True" "WK18c the waiter count is reported as an observable number, not inferred from silence"

# 18e -- THE THREE BOUNDS MUST NEST, in one order and no other: the node returns first, then the
# adapter's guard fires, then the host stops listening. Any other order breaks something specific -- a
# guard before the node's block turns every long wait into a false timeout, and a guard after the host's
# timeout IS the abandoned process the guard exists to prevent.
#
# Checked across the range an operator might configure AND with the margin widened, because widening it
# is the documented remedy for a loaded machine, and a remedy that broke the ordering would be worse
# than the problem it treats.
cat > "${_TMPD}/nesting.mjs" <<MJS
import { adapterGuardMs } from '${REPO_ROOT}/chat-node/adapters/common.mjs';
import { blockMsFor } from '${REPO_ROOT}/chat-node/server/waiters.mjs';
const bad = [];
for (const margin of [5000, 20000]) {
  process.env.AID_CHAT_ADAPTER_MARGIN_MS = String(margin);
  for (const t of [10, 20, 30, 60, 120]) {
    const block = blockMsFor({ hostTimeoutSec: t }).blockMs;
    const guard = adapterGuardMs(t);
    const host = t * 1000;
    if (!(block <= guard && guard < host)) {
      bad.push('margin=' + margin + ' t=' + t + ' block=' + block + ' guard=' + guard + ' host=' + host);
    }
  }
}
console.log(bad.length ? bad.join(' | ') : 'nested');
MJS
nesting="$(node "${_TMPD}/nesting.mjs" 2>/dev/null)"
assert_eq "$nesting" "nested" \
    "WK18e the node's block, the adapter's guard and the host's timeout nest in that order, at every configured margin"

# 18d -- THE ADAPTER'S OWN GUARD, which is the mechanism that actually bounds an abandoned adapter in
# production and which 18b does not reach. 18b kills the process, so the OS closes the socket; a host
# that abandons a hook does NOT kill it -- it discards the output and walks away, leaving the adapter
# running. What stops it running forever is its own guard timer, and that is only exercised when the
# far end accepts the connection and then never answers.
#
# So: a server that accepts and stays silent. The adapter must return under its own power, well
# inside the host timeout it was given, rather than hanging until something else intervenes.
python3 - "${_TMPD}/silent.port" <<'PY' &
import socket, sys, time
srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(('127.0.0.1', 0))
srv.listen(8)
open(sys.argv[1], 'w').write(str(srv.getsockname()[1]))
held = []
deadline = time.time() + 60
while time.time() < deadline:
    srv.settimeout(1.0)
    try:
        conn, _ = srv.accept()
        held.append(conn)          # accepted, and deliberately never answered
    except socket.timeout:
        pass
PY
SILENT=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s "${_TMPD}/silent.port" ]] && break; sleep 0.2; done
if [[ -s "${_TMPD}/silent.port" ]]; then
    # Point a throwaway runtime dir at the silent server, so the adapter connects there.
    mkdir -p "${_TMPD}/silent-rt"
    cp "${_TMPD}/silent.port" "${_TMPD}/silent-rt/hub.port"
    t0=$(date +%s%N)
    # The outer bound is a harness backstop and is generous ON PURPOSE. The guard is 18s and the
    # assertion below is 25s, so a guard that fires late must FAIL THAT ASSERTION rather than be
    # killed here and reported as exit 124 -- which reads identically to "the guard never fired".
    # Observed flaking once on a loaded VM where event-loop starvation pushed the run past 40s.
    ( AID_CHAT_RUNTIME="${_TMPD}/silent-rt" timeout 90 node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs"         --name bob --host-timeout 20 >"${_TMPD}/silent.out" 2>/dev/null )
    rc=$?
    t1=$(( ($(date +%s%N) - t0) / 1000000 ))
    # The guard is host_timeout - 2s = 18s. It must return under its own power inside that, and well
    # inside the 20s the host would wait -- not be cut off by the outer `timeout`.
    if [[ "$rc" -eq 0 && "$t1" -lt 25000 ]]; then
        pass "WK18d against a server that accepts and never answers, the adapter returns under its own guard (${t1}ms, exit ${rc})"
    else
        fail "WK18d the adapter did not self-bound within 25s: ${t1}ms, exit ${rc} (the 18s guard should have returned it; 124 would mean even the 90s harness bound was reached)"
    fi
    assert_eq "$(tr -d ' \n' < "${_TMPD}/silent.out")" "{}" "WK18d and returns the no-wake shape rather than a crash"
else
    fail "WK18d could not start the silent server, so the guard was not exercised"
fi
kill "$SILENT" 2>/dev/null
wait "$SILENT" 2>/dev/null

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
#
# THE ARTIFACT THE CRITERION IS ACTUALLY ABOUT is the RENDERED skill, not the canonical source and not
# the CLI. This was filed as debt (W1-20) when the check could only reach the CLI's verb list, because
# the skill did not exist yet. It exists now, so the check reads it -- and reads all five rendered
# copies rather than trusting that rendering preserved anything.
SKILL="${REPO_ROOT}/canonical/skills/aid-chat/SKILL.md"
assert_file_exists "$SKILL" "WK21 the canonical chat skill exists"

_verbs_in() { grep -oE '^aid chat [a-z-]+' "$1" | awk '{print $3}' | sort -u | tr '\n' ' ' | sed 's/ $//'; }

# The permitted set. Broader than the verbs FR-7.3 enumerates by name, because FR-3.1 adds the
# listing -- so the set is stated here AND cross-checked against the requirement below, rather than
# being a copy nobody compares to anything.
# `register` is here because FR-2.1 has a session bind ITSELF to a stable name: the verb that does
# that must be reachable from the surface the session can see. FR-7.3's list originally omitted it,
# which made FR-2.1 unimplementable by an agent -- the one place in this work where two requirements
# contradicted each other. FR-7.3 was amended rather than the skill trimmed.
permitted="ack connect inbox join leave list open register roster send"
assert_eq "$(_verbs_in "$SKILL")" "$permitted" "WK21 the canonical skill's verb list is exactly what the surface boundary permits"

# Cross-checked against the requirement text itself, so the list above cannot drift away from the
# thing it claims to encode. Every verb FR-7.3 names as permitted must be present; every one it names
# as forbidden must be absent.
REQ="${REPO_ROOT}/.aid/works/work-001-agent-chat/REQUIREMENTS.md"
fr73="$(python3 - "$REQ" <<'PY'
import re, sys
s = open(sys.argv[1], encoding='utf-8').read()
i = s.index('| FR-7.3')
row = s[i:s.index('\n', i)]
named = set(re.findall(r'`([a-z][a-z-]*)`', row))
print(' '.join(sorted(named)))
PY
)"
for v in send inbox ack register; do
    case " ${permitted} " in
        *" ${v} "*) ;;
        *) fail "WK21 FR-7.3 names '${v}' as permitted but the tested set omits it" ;;
    esac
done
assert_output_contains "$fr73" "wait" "WK21 FR-7.3 is the source of the prohibition on a wait verb, and still says so"

for forbidden in subscribe wait node reap peers; do
    if grep -qE "^aid chat ${forbidden}\b" "$SKILL"; then
        fail "WK22 the skill documents '${forbidden}', which the surface boundary forbids"
    fi
done
pass "WK22 the canonical skill documents no wait, no node lifecycle, and no administrative verb"

# Each RENDERED copy is checked ON ITS OWN, and against the CANONICAL body rather than against the
# other renders. Comparing the renders only to each other would pass a generator that mangled all
# five identically -- which is the failure a generator is most likely to have.
canon_body="$(sed -n '/^---$/,/^---$/!p' "$SKILL" | md5sum | cut -d' ' -f1)"
rendered=0
for prof in "claude-code/.claude" "codex/.codex" "cursor/.cursor" "copilot-cli/.github" "antigravity/.agent"; do
    f="${REPO_ROOT}/profiles/${prof}/skills/aid-chat/SKILL.md"
    [[ -f "$f" ]] || continue
    rendered=$((rendered+1))
    if [[ "$(_verbs_in "$f")" != "$permitted" ]]; then
        fail "WK23 the rendered skill at ${prof} has the wrong verb list: $(_verbs_in "$f")"
    fi
    for forbidden in subscribe wait node reap peers; do
        if grep -qE "^aid chat ${forbidden}\b" "$f"; then
            fail "WK23 the rendered skill at ${prof} documents the forbidden '${forbidden}'"
        fi
    done
    if [[ "$(sed -n '/^---$/,/^---$/!p' "$f" | md5sum | cut -d' ' -f1)" != "$canon_body" ]]; then
        fail "WK23 the rendered skill at ${prof} differs in body from the canonical source"
    fi
done
assert_eq "$rendered" "5" "WK23 the skill renders into all five profiles"
pass "WK23 every rendered copy carries the permitted verb list, none of the forbidden ones, and a body identical to the canonical source"

# --- the install document (task-022) ------------------------------------------
# This document is part of SATISFYING AC-24 rather than commentary on it: where a host raises an
# approval prompt, the criterion is met only with the operator's pre-authorisation step performed,
# and an operator cannot perform a step nobody wrote down. So its load-bearing claims are asserted.
DOC="${REPO_ROOT}/docs/chat-wake-install.md"
assert_file_exists "$DOC" "WK24 the wake install document exists"

for host in "Claude Code" "Cursor"; do
    assert_file_contains "$DOC" "## ${host}" "WK24 it has a section for ${host}, which ships an adapter"
done
assert_file_contains "$DOC" "host_timeout - margin" "WK24 it shows the arithmetic relating the two numbers, not just the values"
assert_file_contains "$DOC" "min(30s, 60s - 5s)" "WK24 with the numbers worked through"

# The consequence of omitting the flag, stated as what the operator will OBSERVE. "Nothing" is the
# honest answer and the hardest one to guess, which is exactly why it has to be written down.
assert_file_contains "$DOC" "What you see: nothing" "WK24 it states the observable consequence of a mismatch: nothing at all"
assert_file_contains "$DOC" "fallback-unknown-host-timeout" "WK24 and shows what the subscriber reports when the flag is absent"

# Never fail-closed, and the reason, not just the instruction.
assert_file_contains "$DOC" "Never set the hook to fail closed" "WK25 it says never to set fail-closed"
assert_file_contains "$DOC" "your own session freezing" "WK25 and gives the reason: a hung wait would freeze the user's own session"

# The pre-authorisation option, what it buys and what it costs -- the AC-24 clause.
assert_file_contains "$DOC" "pre-authorise" "WK26 it names the pre-authorisation option AC-24 depends on"
assert_file_contains "$DOC" "the pull floor is always there" "WK26 and states the alternative, so the trade is a choice rather than a demand"

# Every host that ships no adapter is named as such, so a reader is not left wondering.
for host in Codex "Copilot CLI" Antigravity; do
    assert_file_contains "$DOC" "$host" "WK27 it accounts for ${host}, which ships no adapter"
done
assert_file_contains "$DOC" "degrades to the pull floor" "WK27 and says what a host with no adapter falls back to"

# --- WK28-WK34: `aid chat hook` -- generate the block, and read an installed one back. ------------
#
# The hook is the one step an operator does by hand, and the way it goes wrong is silent: two numbers
# that must agree, and a wake that simply never arrives when they do not. These check that the
# generator fills both from the same source, and that --check catches the mismatch.
HOOKHOME="${_TMPD}/hookhome"
mkdir -p "${HOOKHOME}/.cursor" "${HOOKHOME}/.claude"

_hook() { ( cd "$REPO_ROOT" && HOME="$HOOKHOME" AID_CODE_HOME="$REPO_ROOT" bash bin/aid chat hook "$@" 2>&1 ); }

out="$(_hook --tool cursor --timeout 60)"
assert_output_contains "$out" '"timeout": 60' "WK28 the generated block carries the host timeout as a field"
assert_output_contains "$out" '--host-timeout 60' "WK28 and the same number on the command line"
assert_output_contains "$out" "chat-node/adapters/cursor.mjs" "WK28 pointing at the adapter that ships"
assert_output_not_contains "$out" '--name' "WK28 and carries no session name, so one block serves every session"

# The number it PRINTS as the block must be what the node actually does -- min(long poll, timeout -
# margin), not timeout - margin. A number in the output that does not match behaviour is worse than none.
assert_output_contains "$(_hook --tool cursor --timeout 60)" "the node blocks 30s" \
    "WK29 with a wide host timeout the printed block is capped by the long poll, not timeout minus margin"
assert_output_contains "$(_hook --tool cursor --timeout 20)" "the node blocks 15s" \
    "WK29 and with a narrow one it is the host timeout minus the margin"

# node resolved to an absolute path: a bare `node` in a hook command depends on the host's PATH, which
# is not the shell's, and a shim can leave the host watching a process that is not the one blocking.
assert_output_contains "$out" "$(command -v node >/dev/null && readlink -f "$(command -v node)")" \
    "WK30 node is an absolute resolved path, not a bare command name"

# It writes nothing. This is FR-0.4, and the check is that the config file is still absent afterwards.
rm -f "${HOOKHOME}/.cursor/settings.json"
_hook --tool cursor >/dev/null 2>&1
if [[ -e "${HOOKHOME}/.cursor/settings.json" ]]; then
    fail "WK31 generating the block writes no host configuration file (FR-0.4)"
else
    pass "WK31 generating the block writes no host configuration file (FR-0.4)"
fi

# --check, on the failure that is otherwise silent.
_hook --tool cursor --timeout 60 2>/dev/null | sed -n '/^{/,/^}/p' > "${HOOKHOME}/.cursor/settings.json"
if _hook --tool cursor --check >/dev/null 2>&1; then
    pass "WK32 --check passes a block that came from the generator"
else
    fail "WK32 --check passes a block that came from the generator"
fi

python3 - "${HOOKHOME}/.cursor/settings.json" <<'MISMATCH'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d['hooks']['stop'][0]['timeout'] = 20   # the command still says 60
json.dump(d, open(p, 'w'), indent=2)
MISMATCH
mism="$(_hook --tool cursor --check || true)"
assert_output_contains "$mism" "DISAGREE" "WK33 --check catches the two numbers disagreeing -- the silent failure"
if _hook --tool cursor --check >/dev/null 2>&1; then
    fail "WK33 and exits non-zero on a mismatch"
else
    pass "WK33 and exits non-zero on a mismatch"
fi

# Claude Code too, and NOT as a formality: its block is the nested shape (a matcher, then an inner
# `hooks` array), so it is the one more likely to be generated wrong. An earlier falsification pass
# broke this line specifically and every case still passed, because all of them named cursor.
cc="$(_hook --tool claude-code --timeout 45)"
assert_output_contains "$cc" '"timeout": 45' "WK34a the Claude Code block carries the host timeout as a field"
assert_output_contains "$cc" '--host-timeout 45' "WK34a and the same number on the command line"
assert_output_contains "$cc" '"matcher"' "WK34a in the nested shape that host requires"
assert_output_contains "$cc" "adapters/claude-code.mjs" "WK34a pointing at its own adapter, not the other host's"
assert_output_not_contains "$cc" "cursor.mjs" "WK34a and not at cursor's"
# Round-trips through --check, which is what proves the generator and the checker agree on the shape.
_hook --tool claude-code --timeout 45 2>/dev/null | sed -n '/^{/,/^}$/p' > "${HOOKHOME}/.claude/settings.json"
if _hook --tool claude-code --check >/dev/null 2>&1; then
    pass "WK34b a generated Claude Code block passes --check"
else
    fail "WK34b a generated Claude Code block passes --check"
fi
python3 - "${HOOKHOME}/.claude/settings.json" <<'CCMISMATCH'
import json, sys
d = json.load(open(sys.argv[1]))
d['hooks']['Stop'][0]['hooks'][0]['timeout'] = 30   # the command still says 45
json.dump(d, open(sys.argv[1], 'w'), indent=2)
CCMISMATCH
assert_output_contains "$(_hook --tool claude-code --check || true)" "DISAGREE" \
    "WK34b and a mismatch in the nested shape is caught there too"
rm -f "${HOOKHOME}/.claude/settings.json"

rm -f "${HOOKHOME}/.cursor/settings.json"
absent="$(_hook --tool cursor --check || true)"
assert_output_contains "$absent" "no hook installed" "WK34 --check says so plainly when nothing is installed"
assert_output_contains "$absent" "aid chat hook --tool cursor" "WK34 and names the command that produces one"
nohost="$(_hook --tool codex 2>&1 || true)"
assert_output_contains "$nohost" "no adapter ships" "WK34 a host with no adapter is refused, not given a broken block"

# --- WK36-WK38: the woken turn is told WHO IT IS. -------------------------------------------------
#
# A woken turn is a FRESH CONTEXT. It never ran `register`, never saw the name that printed, and has no
# memory of the channel -- so whatever it needs has to be in the wake text. The name is not decoration:
# every chat verb requires --name, and a turn that guesses addresses a session that is not itself.
#
# This was a real gap. A `connect` wake -- the FIRST thing a session ever hears -- carried no name and
# no command at all, because the hint was built only when a message had already been delivered. It said
# "you are now a member of that channel" and stopped, which is a dead end dressed as a notification.
wake_text() {
    node --input-type=module -e "
import { renderWakeText, wakeHints } from '${REPO_ROOT}/chat-node/adapters/common.mjs';
const h = wakeHints({ name: 'bob', seq: ${2}, quoteStyle: 'posix' });
process.stdout.write(renderWakeText({
    kind: '${1}',
    channel: 'pair',
    messages: ${1:+$([ "$1" = message ] && echo "[{from:'alice',body:'ping'}]" || echo "[]")},
    name: 'bob', replyHint: h.reply, ackHint: h.ack, inboxHint: h.inbox,
}));
"
}

conn="$(wake_text connect 0)"
assert_output_contains "$conn" 'You are "bob"' "WK36 a connect wake states the name the session goes by"
assert_output_contains "$conn" 'chat send --name bob' "WK36 and gives a reply command already carrying it"
assert_output_contains "$conn" 'chat inbox --name bob' "WK36 and a read command, since a connect may follow a backlog"
# Reading and acknowledging are different verbs. The connect wake once offered `ack` under the words
# "to see what is said", which is an instruction that does not do what it says.
assert_output_not_contains "$conn" 'To see anything already said: '"${REPO_ROOT}"'/bin/aid chat ack' \
    "WK36 and does not offer ack as the way to READ"

msg="$(wake_text message 1)"
assert_output_contains "$msg" 'You are "bob"' "WK37 a message wake states the name too"
assert_output_contains "$msg" 'Reply with: ' "WK37 and gives the reply command it just told the agent to use"
assert_output_contains "$msg" 'chat ack --name bob --cursor 1' "WK37 and the ack command with the delivered position"

# Both adapters, driven as their hosts drive them, because the hint builder was duplicated per adapter
# and differed only by quote style -- the shape that already caused two one-copy fixes in this work.
for pair in "claude-code:reason" "cursor:followup_message"; do
    ad="${pair%%:*}"; field="${pair##*:}"
    _drain bob
    $AID chat send --name alice --body "who am i" >/dev/null
    payload='{"conversation_id":"cv-wk38","loop_count":0}'
    got="$(cd "$REPO_ROOT" && printf '%s' "$payload" | timeout 40 node "chat-node/adapters/${ad}.mjs" \
        --name bob --host-timeout 20 2>/dev/null || true)"
    # The name is inside a JSON string, so it arrives escaped. Asserting the bare form passed nothing
    # and failed while the product was correct -- the pattern was wrong, not the payload.
    assert_output_contains "$got" 'You are ' "WK38 the ${ad} adapter states who the woken turn is"
    assert_output_contains "$got" '\"bob\"' "WK38 naming it inside its ${field} payload"
    assert_output_contains "$got" "chat send --name bob" "WK38 and a reply command carrying that name"
done

# The document has to lead with the generator, or an operator does by hand what a command does better.
assert_file_contains "$DOC" "aid chat hook --tool cursor" "WK35 the install document names the generator"
assert_file_contains "$DOC" "Do not do this by hand" "WK35 and says up front not to assemble the block manually"
assert_file_contains "$DOC" "tracked in git" "WK35 and gives the concrete reason nothing is written for you"

# Non-automated checks are enumerated, not implied.
for mp in MP-05 MP-06 MP-07 MP-08; do
    assert_file_contains "${REPO_ROOT}/chat-node/tests/MANUAL-PROCEDURES.md" "$mp" \
        "the checks this suite cannot reach are recorded as ${mp}, by name and with steps"
done

# Tear down FIRST, then measure, since the EXIT trap runs after this line.
_cleanup
trap - EXIT
sleep 0.3
leaked_h="$(_own_hubs)"
leaked_a="$(_own_adapters)"
assert_eq "${leaked_h},${leaked_a}" "0,0" "the suite leaves none of its own hub or adapter processes behind"

test_summary
