#!/usr/bin/env bash
# test-chat-node-integration.sh — delivery-001's thirteen criteria, end to end.
#
# Every case here runs against a REAL node process through the REAL `aid` CLI. The unit-level
# suites (store, core, lifecycle) prove the parts; this one proves the product, which is why it
# uses no internal imports at all.
#
# Each criterion of delivery-001 is named in the assertion label so the mapping is checkable by
# grepping this file for the ids:
#
#   AC-9   the CLI stands the node up with nothing fetched, and a second start is safe
#   AC-22  a missing runtime fails clearly and only for the component that needs one
#   AC-33  the conversation id is the product's; a host-supplied one is metadata only
#   AC-29  an agent opens its own channel and holds at most one
#   AC-30  a channel ends when its last member is gone, and not because it fell quiet
#   AC-3   a restart resumes at the acknowledged position; a quiet member is not a departed one
#   AC-7   a two-member channel is a direct message
#   AC-13  a message reaches every member, two or many
#   AC-6   with no subscriber armed, a message is readable at the next turn
#   AC-31  per-speaker order holds; cross-speaker order is not claimed
#   AC-32  a delivered-but-unacknowledged message is presented again
#   AC-8   a duplicate is deduped by key; a reply correlates to its request
#   AC-10  unacknowledged messages and every position survive a NODE restart
#
# AC-31's second half is asserted as a PASS rather than a defect: two members observing two
# speakers in a different relative order is conformant, and a test that forbade it would be
# testing a guarantee the requirements decline to make.
#
# Usage: bash test-chat-node-integration.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not available" >&2; exit 0; }

_HUBS_AT_START="$(ps -eo args | grep -c '[s]erver/hub.mjs')"
_TMPD="$(mktemp -d)"
export AID_CODE_HOME="$REPO_ROOT"
export AID_CHAT_RUNTIME="${_TMPD}/rt"
export AID_CHAT_STORE="${_TMPD}/rt/chat.db"
AID="bash ${REPO_ROOT}/bin/aid"
_cleanup() { $AID chat node stop >/dev/null 2>&1 || true; rm -rf "${_TMPD}"; }
trap _cleanup EXIT

# `jq` is not a dependency of this repository, so read JSON with python3 -- which is.
_field() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval('d'+sys.argv[1]))" "$1"; }

# --- AC-9 --------------------------------------------------------------------
$AID chat node start --port 0 >/dev/null 2>&1
assert_eq "$?" "0" "AC-9 the CLI stands the node up from the shipped payload"
$AID chat node start --port 0 >/dev/null 2>&1
assert_eq "$?" "8" "AC-9 a second start is safe: it changes nothing and reports already-running"

# --- AC-33 -------------------------------------------------------------------
out=$($AID chat register --name alice --tool cursor 2>/dev/null)
cid=$(printf '%s' "$out" | _field "['conversation_id']")
case "$cid" in cv_*) pass "AC-33 the conversation id is product-minted" ;;
               *)    fail "AC-33 unexpected conversation id: ${cid}" ;; esac
$AID chat register --name bob --tool claude >/dev/null 2>&1
# A host-supplied id goes in as metadata and must not become the identity.
curl -sS -X POST "http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")/session" \
     --data-binary '{"name":"carol","tool":"cursor","cwd":"/z","host_conversation_id":"host-xyz"}' >/dev/null
out=$(curl -sS "http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")/sessions" 2>/dev/null)
carol_cid=$(printf '%s' "$out" | python3 -c "import json,sys; print([s['conversation_id'] for s in json.load(sys.stdin)['sessions'] if s['name']=='carol'][0])")
if [[ "$carol_cid" == cv_* && "$carol_cid" != "host-xyz" ]]; then
    pass "AC-33 a host-supplied id does not become the identity"
else
    fail "AC-33 the host id leaked into the identity: ${carol_cid}"
fi

# --- AC-29 -------------------------------------------------------------------
$AID chat open --name alice --channel standup >/dev/null 2>&1
assert_eq "$?" "0" "AC-29 an agent opens its own channel"
err=$($AID chat join --name alice --channel other 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "AC-29 a second channel is refused (exit 14)"
assert_output_contains "$err" "already_in_channel" "AC-29 the refusal names the one-channel bound"

# --- AC-7 / AC-6 -------------------------------------------------------------
$AID chat join --name bob --channel standup >/dev/null 2>&1
$AID chat send --name alice --body 'private to bob' >/dev/null 2>&1
assert_eq "$?" "0" "AC-7 a two-member channel carries an ordinary message"
n=$($AID chat inbox --name bob 2>/dev/null | _field "['messages'].__len__()")
assert_eq "$n" "1" "AC-6 with no subscriber armed, the message is readable at the next turn"

# --- AC-13 -------------------------------------------------------------------
$AID chat join --name carol --channel standup >/dev/null 2>&1
$AID chat send --name alice --body 'to everyone' >/dev/null 2>&1
got_bob=$($AID chat inbox --name bob 2>/dev/null | python3 -c "import json,sys; print(any(m['body']=='to everyone' for m in json.load(sys.stdin)['messages']))")
got_carol=$($AID chat inbox --name carol 2>/dev/null | python3 -c "import json,sys; print(any(m['body']=='to everyone' for m in json.load(sys.stdin)['messages']))")
assert_eq "${got_bob},${got_carol}" "True,True" "AC-13 a message reaches every member of a channel of three"

# AC-13's other half, through the CLI rather than only at the core: a send with nobody to
# receive it, and a send by a session in no channel, must each fail explicitly.
$AID chat register --name solo --tool codex >/dev/null 2>&1
err=$($AID chat send --name solo --body 'nobody there' 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "AC-13 a send by a session in no channel fails with exit 14"
assert_output_contains "$err" "no_channel" "AC-13 that refusal names no_channel"
$AID chat open --name solo --channel empty >/dev/null 2>&1
err=$($AID chat send --name solo --body 'still nobody' 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "AC-13 a send by a channel's only member fails with exit 14"
assert_output_contains "$err" "solo_channel" "AC-13 that refusal names solo_channel"
$AID chat leave --name solo >/dev/null 2>&1

# --- AC-8 -------------------------------------------------------------------
s1=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['arrival_seq']")
s2=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['arrival_seq']")
assert_eq "$s1" "$s2" "AC-8 a duplicate send is deduped by idempotency key, at the original position"
absorbed=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['absorbed']")
assert_eq "$absorbed" "True" "AC-8 the retry is reported as absorbed rather than silently repeated"

# AC-8's other half: a reply correlates to its originating request -- sent through the CLI's own
# --reply-to and --correlation-id, which is the surface a session actually has. An earlier
# version reached past the CLI to curl because those flags did not exist; leaving the curl in
# after adding them would have left the flags themselves untested.
orig_key=$($AID chat send --name alice --body 'a question' --key q1 2>/dev/null | _field "['idempotency_key']")
$AID chat send --name bob --body 'an answer' --reply-to "$orig_key" --correlation-id c-1 >/dev/null 2>&1
assert_eq "$?" "0" "AC-8 the CLI accepts --reply-to and --correlation-id"
corr=$($AID chat inbox --name carol 2>/dev/null | python3 -c "
import json,sys
ms=[m for m in json.load(sys.stdin)['messages'] if m['body']=='an answer']
print(f\"{ms[0]['reply_to']}|{ms[0]['correlation_id']}\" if ms else 'NONE')")
assert_eq "$corr" "${orig_key}|c-1" "AC-8 a reply carries reply_to and correlation_id back to its request"

# --- AC-32 -------------------------------------------------------------------
before=$($AID chat inbox --name carol 2>/dev/null | _field "['messages'].__len__()")
again=$($AID chat inbox --name carol 2>/dev/null | _field "['messages'].__len__()")
if [[ "$before" -gt 0 && "$again" == "$before" ]]; then
    pass "AC-32 a delivered but unacknowledged message is presented again"
else
    fail "AC-32 expected the same unacknowledged set twice, got ${before} then ${again}"
fi

# --- AC-31 -------------------------------------------------------------------
$AID chat send --name bob   --body 'b-one' >/dev/null 2>&1
$AID chat send --name alice --body 'a-one' >/dev/null 2>&1
$AID chat send --name bob   --body 'b-two' >/dev/null 2>&1
seq=$($AID chat inbox --name carol 2>/dev/null | python3 -c "
import json,sys
ms=[m for m in json.load(sys.stdin)['messages'] if m['from']=='bob']
s=[m['sender_seq'] for m in ms]
print('ordered' if s==sorted(s) else 'OUT-OF-ORDER')")
assert_eq "$seq" "ordered" "AC-31 one speaker's messages arrive in that speaker's own order"
pass "AC-31 no cross-speaker order is claimed: two members seeing two speakers differently is conformant, and nothing here asserts otherwise"

# --- AC-3 --------------------------------------------------------------------
cur=$($AID chat inbox --name carol 2>/dev/null | _field "['delivered_seq']")
$AID chat ack --name carol --cursor "$cur" >/dev/null 2>&1
$AID chat send --name alice --body 'while carol was away' >/dev/null 2>&1
out=$($AID chat register --name carol --tool cursor 2>/dev/null)     # the restart
reattached=$(printf '%s' "$out" | _field "['reattached']")
chan=$(printf '%s' "$out" | _field "['channel']")
assert_eq "${reattached},${chan}" "True,standup" "AC-3 a restarting session reattaches to its still-open channel"
body=$($AID chat inbox --name carol 2>/dev/null | python3 -c "import json,sys; ms=json.load(sys.stdin)['messages']; print(ms[0]['body'] if ms else 'NONE')")
assert_eq "$body" "while carol was away" "AC-3 it resumes at its acknowledged position and gets what it missed"

# --- AC-30 -------------------------------------------------------------------
$AID chat leave --name alice >/dev/null 2>&1
open_after_creator=$($AID chat list --name bob 2>/dev/null | _field "['channels'].__len__()")
assert_eq "$open_after_creator" "1" "AC-30 the channel survives its creator leaving"
$AID chat leave --name bob >/dev/null 2>&1
$AID chat leave --name carol >/dev/null 2>&1
open_after_last=$($AID chat list --name bob 2>/dev/null | _field "['channels'].__len__()")
assert_eq "$open_after_last" "0" "AC-30 the channel closes when its last member leaves"

# AC-30's negative, which the criterion states explicitly: a channel does NOT close because it
# fell quiet. An earlier version of this case slept 1.1s against the 24h default and asserted
# survival -- which an inactivity timer of two seconds would also have passed. It proved the
# channel survived 1.1s and nothing more.
#
# This version makes the condition real in the only way that is honest: the hub runs with a
# REAP THRESHOLD OF 300 ms, both members keep heartbeating, and the channel is then quiet for
# many multiples of that threshold. If anything closed a channel on elapsed silence, this would
# close it. The members' heartbeats are what separate the two ideas the criterion distinguishes
# -- a quiet channel is not a departed member.
# On its OWN node, with its own runtime dir and store. The first version of this case reaped
# every session on the shared node, which destroyed the sessions AC-10 needs later -- a test that
# breaks another test is a test that has to be isolated, not reordered around.
QRT="${_TMPD}/quiet-rt"; QST="${_TMPD}/quiet-rt/chat.db"
QQ() { env AID_CHAT_RUNTIME="$QRT" AID_CHAT_STORE="$QST" AID_CHAT_REAP_MS=300 bash "${REPO_ROOT}/bin/aid" "$@"; }
QQ chat node start --port 0 >/dev/null 2>&1
QQ chat register --name q1 --tool t >/dev/null 2>&1
QQ chat register --name q2 --tool t >/dev/null 2>&1
QQ chat open --name q1 --channel quiet >/dev/null 2>&1
QQ chat join --name q2 --channel quiet >/dev/null 2>&1
for _ in 1 2 3 4 5 6; do
    sleep 0.25
    QQ chat heartbeat --name q1 >/dev/null 2>&1
    QQ chat heartbeat --name q2 >/dev/null 2>&1
done
still=$(QQ chat list --name q1 2>/dev/null | python3 -c "import json,sys; print(any(c['name']=='quiet' for c in json.load(sys.stdin)['channels']))")
assert_eq "$still" "True" "AC-30 a channel quiet for many multiples of the reap threshold is STILL THERE while its members live"

# And the complement, which is what makes the case above mean something: with the same low
# threshold, members that STOP heartbeating are reapable, and reaping the last one does close it.
sleep 0.5
QQ chat reap --name --all >/dev/null 2>&1
gone_after_silence=$(QQ chat register --name probe --tool t >/dev/null 2>&1; QQ chat list --name probe 2>/dev/null | python3 -c "import json,sys; print(not any(c['name']=='quiet' for c in json.load(sys.stdin)['channels']))")
assert_eq "$gone_after_silence" "True" "AC-30 the same channel DOES close once its members stop heartbeating and are reaped -- so the case above tests the distinction, not the absence of any mechanism"

# No timer targets channel closure anywhere in the node: the absence is asserted, not assumed.
timers=$(grep -nE 'setInterval|setTimeout' "${REPO_ROOT}"/chat-node/server/*.mjs | grep -viE 'SIGTERM|process\.kill' | wc -l | tr -d ' ')
assert_eq "$timers" "0" "AC-30 no timer in the node targets channel closure (grepped, not assumed)"
QQ chat node stop >/dev/null 2>&1

# AC-30's TARGETED reap path (`reap --name <session>` rather than the bulk `--all`), end to end
# through the CLI. This block previously ran against the MAIN node using sessions that had been
# moved to the quiet node, so it asserted the absence of a channel that had never been there --
# it would have passed with reaping deleted entirely. It now builds its own channel here, on the
# node the assertion reads, and checks the channel is present BEFORE the reap so that the
# after-state means something.
$AID chat register --name r1 --tool t >/dev/null 2>&1
$AID chat register --name r2 --tool t >/dev/null 2>&1
$AID chat open --name r1 --channel reaped >/dev/null 2>&1
$AID chat join --name r2 --channel reaped >/dev/null 2>&1
present=$($AID chat list --name r1 2>/dev/null | python3 -c "import json,sys; print(any(c['name']=='reaped' for c in json.load(sys.stdin)['channels']))")
assert_eq "$present" "True" "AC-30 the channel to be reaped exists first, so its later absence means something"
$AID chat leave --name r2 >/dev/null 2>&1
out=$($AID chat reap --name r1 2>/dev/null)
closed=$(printf '%s' "$out" | _field "['channel_closed']")
assert_eq "$closed" "True" "AC-30 a targeted reap of the last member reports closing the channel"
gone=$($AID chat list --name r2 2>/dev/null | python3 -c "import json,sys; print(not any(c['name']=='reaped' for c in json.load(sys.stdin)['channels']))")
assert_eq "$gone" "True" "AC-30 reaping the last member closes the channel, exercised through the CLI"

# --- AC-10 -------------------------------------------------------------------
$AID chat open --name alice --channel durable >/dev/null 2>&1
$AID chat join --name bob --channel durable >/dev/null 2>&1
$AID chat send --name alice --body 'survives a restart' >/dev/null 2>&1
pos_before=$($AID chat inbox --name bob 2>/dev/null | _field "['delivered_seq']")
$AID chat ack --name bob --cursor "$pos_before" >/dev/null 2>&1
$AID chat send --name alice --body 'unacknowledged' >/dev/null 2>&1
$AID chat node stop >/dev/null 2>&1
$AID chat node start --port 0 >/dev/null 2>&1
out=$($AID chat inbox --name bob 2>/dev/null)
surv_body=$(printf '%s' "$out" | python3 -c "import json,sys; ms=json.load(sys.stdin)['messages']; print(ms[0]['body'] if ms else 'NONE')")
surv_ack=$(printf '%s' "$out" | _field "['acked_seq']")
assert_eq "$surv_body" "unacknowledged" "AC-10 an unacknowledged message survives a restart of the NODE"
assert_eq "$surv_ack" "$pos_before" "AC-10 every member's position survives a restart of the NODE"

# --- AC-22 -------------------------------------------------------------------
# Strip EVERY path entry that can reach node, not just the first. An earlier version dropped
# only `dirname $(command -v node)`, which left this criterion SKIPPED on any machine with more
# than one node on PATH -- and a gate criterion that skips is a gate criterion that did not run.
NONODE="$(printf '%s' "$PATH" | tr ':' '\n' | while IFS= read -r d; do
    [[ -n "$d" && -x "${d}/node" ]] || printf '%s\n' "$d"
done | paste -sd:)"
if env PATH="$NONODE" bash -c 'command -v node >/dev/null 2>&1'; then
    fail "AC-22 could not hide node from PATH; the criterion did not run"
else
    err=$(env PATH="$NONODE" AID_CODE_HOME="$AID_CODE_HOME" AID_CHAT_RUNTIME="${_TMPD}/rt2" \
              bash "${REPO_ROOT}/bin/aid" chat node start 2>&1 >/dev/null); rc=$?
    assert_eq "$rc" "9" "AC-22 with no runtime present, starting the node exits 9"
    assert_output_contains "$err" "requires a Node runtime" "AC-22 the error names Node as the prerequisite"
    env PATH="$NONODE" bash "${REPO_ROOT}/bin/aid" version >/dev/null 2>&1
    assert_eq "$?" "0" "AC-22 every aid command that needs no runtime keeps working"
fi

# Non-automated checks are enumerated, not implied.
assert_file_exists "${REPO_ROOT}/chat-node/tests/MANUAL-PROCEDURES.md" \
    "the manual-procedures record exists, so the set of non-automated checks is enumerable"
assert_file_contains "${REPO_ROOT}/chat-node/tests/MANUAL-PROCEDURES.md" "MP-01" \
    "the record names the PowerShell twin as the one unexecuted surface"

# The suite leaves no hub process behind. It starts three nodes over its lifetime (the main one,
# a restarted one, and the isolated quiet-case node), so this is worth asserting rather than
# assuming -- the lifecycle suite was found leaking one per run.
# Tear down FIRST, then measure. The EXIT trap runs after this line, so measuring before
# stopping would count this suite's own still-running node and report a leak that is not one.
_cleanup
trap - EXIT
sleep 0.3
_leaked="$(ps -eo args | grep -c '[s]erver/hub.mjs')"
if [[ "$_leaked" -le "${_HUBS_AT_START:-0}" ]]; then
    pass "the suite leaves no hub process behind (${_leaked} running, ${_HUBS_AT_START:-0} at start)"
else
    fail "the suite leaked $(( _leaked - ${_HUBS_AT_START:-0} )) hub process(es)"
fi

test_summary
