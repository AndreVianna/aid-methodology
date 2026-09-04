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

# --- AC-8 -------------------------------------------------------------------
s1=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['arrival_seq']")
s2=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['arrival_seq']")
assert_eq "$s1" "$s2" "AC-8 a duplicate send is deduped by idempotency key, at the original position"
absorbed=$($AID chat send --name alice --body dup --key fixed 2>/dev/null | _field "['absorbed']")
assert_eq "$absorbed" "True" "AC-8 the retry is reported as absorbed rather than silently repeated"

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
NONODE="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "$(dirname "$(command -v node)")" | paste -sd:)"
if env PATH="$NONODE" bash -c 'command -v node >/dev/null 2>&1'; then
    log "AC-22 SKIPPED: node is reachable by more than one PATH entry here"
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

test_summary
