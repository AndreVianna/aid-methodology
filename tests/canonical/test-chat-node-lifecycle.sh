#!/usr/bin/env bash
# test-chat-node-lifecycle.sh — the chat node's lifecycle, through the CLI that owns it.
#
# The node is a service with no operator surface of its own, so every case here goes through
# `aid chat node ...` rather than poking the process directly — that is the surface the
# requirement describes and therefore the surface worth testing.
#
#   LC01  status on a machine where the node has never run: not running, exit 0
#   LC02  start works with the NETWORK DISABLED — proving nothing is fetched, resolved,
#         verified or installed (the substance of "no installation step")
#   LC03  status while running reports the pid and the loopback URL
#   LC04  start again exits 8 and changes nothing — reusing the dashboard's already-running
#         code rather than minting a second one for the same condition
#   LC05  the listening socket is bound to 127.0.0.1 and NOT to 0.0.0.0
#   LC06  the node outlives the shell that started it
#   LC07  stop stops it; stop again is clean and exits 0
#   LC08  a stale pid record is reclaimed silently rather than reported as running
#   LC09  with no Node on PATH, start exits 9 with an explicit message naming Node, no stack
#         trace, and a runtime-free `aid` verb still works
#   LC10  an out-of-range --port is a usage error (exit 2), before any side effect
#
# LC02 and LC09 are the two that carry requirements rather than mechanics: the first is what
# "ships inside the aid payload" means operationally, and the second is the prerequisite rule
# that keeps a missing runtime from breaking the runtime-free CLI.
#
# Hermetic: every case runs against a temp runtime dir and a temp store, on an ephemeral port.
#
# Usage: bash test-chat-node-lifecycle.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not available" >&2
    exit 0
fi

_TMPD="$(mktemp -d)"
export AID_CODE_HOME="$REPO_ROOT"
export AID_CHAT_RUNTIME="${_TMPD}/rt"
export AID_CHAT_STORE="${_TMPD}/rt/chat.db"
_cleanup() {
    AID_CHAT_RUNTIME="${_TMPD}/rt" bash "${REPO_ROOT}/bin/aid" chat node stop >/dev/null 2>&1 || true
    rm -rf "${_TMPD}"
}
trap _cleanup EXIT

AID="bash ${REPO_ROOT}/bin/aid"

# LC01 — never run.
out=$($AID chat node status 2>&1); rc=$?
assert_eq "$rc" "0" "LC01 status exits 0 when the node has never run"
assert_output_contains "$out" "not running" "LC01 status says it is not running"

# LC02 — start with the network disabled. `unshare -rn` gives a network namespace with only
# loopback; where it is unavailable the case is reported as skipped rather than silently passed.
if unshare -rn true 2>/dev/null; then
    out=$(unshare -rn env AID_CODE_HOME="$AID_CODE_HOME" AID_CHAT_RUNTIME="$AID_CHAT_RUNTIME" \
              AID_CHAT_STORE="$AID_CHAT_STORE" bash "${REPO_ROOT}/bin/aid" chat node start --port 0 2>&1); rc=$?
    if [[ $rc -eq 0 ]]; then
        pass "LC02 start succeeds with the network disabled (nothing is fetched)"
    else
        fail "LC02 start failed with the network disabled: ${out}"
    fi
    # That node lived in the namespace and is gone with it; clear the record it left.
    rm -f "${AID_CHAT_RUNTIME}/hub.pid" "${AID_CHAT_RUNTIME}/hub.port" 2>/dev/null || true
else
    log "LC02 SKIPPED: unshare unavailable, cannot disable the network hermetically"
fi

# LC03 — start for real, then status.
out=$($AID chat node start --port 0 2>&1); rc=$?
assert_eq "$rc" "0" "LC03 start exits 0"
PORT="$(tr -d '[:space:]' < "${AID_CHAT_RUNTIME}/hub.port" 2>/dev/null || echo '')"
HUBPID="$(tr -d '[:space:]' < "${AID_CHAT_RUNTIME}/hub.pid" 2>/dev/null || echo '')"
out=$($AID chat node status 2>&1)
assert_output_contains "$out" "running (pid ${HUBPID}" "LC03 status reports the running pid"
assert_output_contains "$out" "http://127.0.0.1:${PORT}" "LC03 status reports the loopback URL"

# LC04 — start again: exit 8, and the pid must not change.
out=$($AID chat node start --port 0 2>&1); rc=$?
assert_eq "$rc" "8" "LC04 start on a running node exits 8 (the established already-running code)"
assert_output_contains "$out" "already running" "LC04 start on a running node says so"
assert_eq "$(tr -d '[:space:]' < "${AID_CHAT_RUNTIME}/hub.pid")" "$HUBPID" "LC04 the running pid is unchanged"

# LC05 — loopback only.
if command -v ss >/dev/null 2>&1 || command -v netstat >/dev/null 2>&1; then
    listeners=$( (ss -ltn 2>/dev/null || netstat -ltn 2>/dev/null) | grep ":${PORT}\b" || true)
    if grep -q "127\.0\.0\.1:${PORT}" <<<"$listeners" && ! grep -qE "0\.0\.0\.0:${PORT}|\*:${PORT}" <<<"$listeners"; then
        pass "LC05 the node listens on 127.0.0.1 only, not on every interface"
    else
        fail "LC05 unexpected listener set for port ${PORT}: ${listeners}"
    fi
else
    log "LC05 SKIPPED: neither ss nor netstat available"
fi

# LC06 — outlives its starting shell. The start above already ran in a subshell that exited;
# assert the process is still alive now.
if kill -0 "$HUBPID" 2>/dev/null; then
    pass "LC06 the node outlives the shell that started it"
else
    fail "LC06 the node died with its starting shell"
fi

# LC07 — stop, then stop again.
out=$($AID chat node stop 2>&1); rc=$?
assert_eq "$rc" "0" "LC07 stop exits 0"
assert_output_contains "$out" "stopped" "LC07 stop says it stopped"
out=$($AID chat node stop 2>&1); rc=$?
assert_eq "$rc" "0" "LC07 stop on an already-stopped node exits 0 (idempotent)"

# LC08 — a stale pid record is reclaimed, not reported as running.
mkdir -p "$AID_CHAT_RUNTIME"
echo "999999" > "${AID_CHAT_RUNTIME}/hub.pid"
out=$($AID chat node status 2>&1)
assert_output_contains "$out" "not running" "LC08 a stale pid record reports not running"
out=$($AID chat node start --port 0 2>&1); rc=$?
assert_eq "$rc" "0" "LC08 start reclaims a stale record instead of refusing with 8"
$AID chat node stop >/dev/null 2>&1

# LC09 — no Node on PATH.
NONODE="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "$(dirname "$(command -v node)")" | paste -sd:)"
if env PATH="$NONODE" bash -c 'command -v node >/dev/null 2>&1'; then
    log "LC09 SKIPPED: node is reachable by more than one PATH entry; cannot hide it"
else
    out=$(env PATH="$NONODE" AID_CODE_HOME="$AID_CODE_HOME" AID_CHAT_RUNTIME="$AID_CHAT_RUNTIME" \
              bash "${REPO_ROOT}/bin/aid" chat node start 2>&1); rc=$?
    assert_eq "$rc" "9" "LC09 start with no Node on PATH exits 9 (the established runtime-missing code)"
    assert_output_contains "$out" "requires a Node runtime" "LC09 the error names Node as the prerequisite"
    if grep -qE '^[[:space:]]+at |node:internal|Traceback' <<<"$out"; then
        fail "LC09 the error carried a stack trace"
    else
        pass "LC09 the error carries no stack trace"
    fi
    env PATH="$NONODE" bash "${REPO_ROOT}/bin/aid" version >/dev/null 2>&1
    assert_eq "$?" "0" "LC09 a runtime-free aid verb still works with no Node present"
fi

# LC10 — an out-of-range port is a usage error, before any side effect.
rm -f "${AID_CHAT_RUNTIME}/hub.pid" "${AID_CHAT_RUNTIME}/hub.port" 2>/dev/null || true
out=$($AID chat node start --port 80 2>&1); rc=$?
assert_eq "$rc" "2" "LC10 an out-of-range --port is a usage error (exit 2)"
if [[ -f "${AID_CHAT_RUNTIME}/hub.pid" ]]; then
    fail "LC10 a rejected --port still started something"
else
    pass "LC10 a rejected --port started nothing"
fi

test_summary
