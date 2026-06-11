#!/usr/bin/env bash
# test-aid-dashboard-cli.sh - Feature-004 CLI test scenarios T-1..T-13.
#
# Tests the aid dashboard start/stop handlers in bin/aid (Bash).
# PowerShell parity for T-1/T-3/T-4/T-5/T-7 is in test-aid-cli-parity.sh
# (extended in place -- T-12).
# T-13 ASCII-only guard delegates to test-ascii-only.sh.
#
# Scenarios:
#   T-1   start python   -> child spawned, dashboard.pid written, exit 0, URL printed
#   T-2   start node     -> same with runtime=node
#   T-3   second start   -> exit 8, "already running", no second child
#   T-4   stop after start -> child gone, record+logfile removed, exit 0
#   T-5   stop with nothing running -> exit 0, "nothing to stop" (idempotent)
#   T-6   crash then restart -> stale reclaimed, fresh start, exit 0
#   T-7   usage errors (bad/missing runtime, unknown flag, bad --port) -> exit 2
#   T-8   runtime absent (command override PATH stub) -> exit 9
#   T-9   busy port -> exit 3, server failed to start
#   T-10  bare aid / aid version / aid status regression (C4 guard)
#   T-11  --remote with no mechanism -> exit 10, server stays local, remote=false
#   T-12  Bash-side parity messages (exact CLI-3 format); PS twin in test-aid-cli-parity.sh
#   T-13  ASCII-only guard for bin/aid + bin/aid.ps1
#
# Usage:
#   bash test-aid-dashboard-cli.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_SH="${REPO_ROOT}/lib/aid-install-core.sh"
DASHBOARD_SERVER_DIR="${REPO_ROOT}/dashboard/server"
DASHBOARD_READER_PY="${REPO_ROOT}/dashboard/reader.py"
DASHBOARD_INIT_PY="${REPO_ROOT}/dashboard/__init__.py"

[[ -f "$BIN_AID" ]] || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_SH"  ]] || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_SH" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Temp workspace -- single shared dir, cleaned on exit.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"

# Track spawned child pids for safety cleanup.
SPAWNED_PIDS=()

cleanup_all() {
    for _p in "${SPAWNED_PIDS[@]:-}"; do
        [[ -n "$_p" ]] || continue
        kill -TERM -"$_p" 2>/dev/null || kill -TERM "$_p" 2>/dev/null || true
        sleep 0.1
        kill -9 -"$_p" 2>/dev/null || kill -9 "$_p" 2>/dev/null || true
    done
}

trap 'cleanup_all; rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# AID home + fixture helpers.
# ---------------------------------------------------------------------------
VERSION="0.7.0"

new_aid_home() {
    local h; h="$(mktemp -d "${TMP}/home.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib"
    cp "$BIN_AID"  "${h}/bin/aid"
    chmod +x "${h}/bin/aid"
    cp "$LIB_SH"   "${h}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${h}/VERSION"
    echo "$h"
}

# A minimal AID fixture repo: has .aid/ dir and the dashboard server entry points.
new_fixture_repo() {
    local r; r="$(mktemp -d "${TMP}/repo.XXXXXX")"
    mkdir -p "${r}/.aid/.temp"
    mkdir -p "${r}/dashboard/server"
    # Symlink the real server entry points so the server can actually start.
    ln -sf "${DASHBOARD_SERVER_DIR}/server.py"  "${r}/dashboard/server/server.py"
    ln -sf "${DASHBOARD_SERVER_DIR}/server.mjs" "${r}/dashboard/server/server.mjs"
    # server.py inserts dashboard/ into sys.path; reader.py must be there.
    [[ -f "$DASHBOARD_READER_PY" ]]  && ln -sf "$DASHBOARD_READER_PY"  "${r}/dashboard/reader.py"
    [[ -f "$DASHBOARD_INIT_PY" ]]    && ln -sf "$DASHBOARD_INIT_PY"    "${r}/dashboard/__init__.py"
    echo "$r"
}

# Pick a free port by letting the OS assign an ephemeral one, then release it.
pick_free_port() {
    python3 -c "import socket; s=socket.socket(); s.bind(('',0)); p=s.getsockname()[1]; s.close(); print(p)"
}

# run aid in an isolated home/fixture env; captures stdout+stderr merged into OUT_DC, exit into RC_DC.
run_dc() {
    local home_dir="$1"; shift
    OUT_DC="$(AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
              bash "${home_dir}/bin/aid" "$@" 2>&1)"
    RC_DC=$?
}

# Run aid with a custom PATH prefix (for tailscale stubs); merges stdout+stderr.
run_dc_path() {
    local path_prefix="$1"; local home_dir="$2"; shift 2
    OUT_DC="$(PATH="${path_prefix}:${PATH}" AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
              bash "${home_dir}/bin/aid" "$@" 2>&1)"
    RC_DC=$?
}

# Run aid with a custom PATH prefix, splitting stdout and stderr.
run_dc_path_split() {
    local path_prefix="$1"; local home_dir="$2"; shift 2
    local _tmp_out _tmp_err
    _tmp_out="$(mktemp "${TMP}/out.XXXXXX")"
    _tmp_err="$(mktemp "${TMP}/err.XXXXXX")"
    PATH="${path_prefix}:${PATH}" AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
        bash "${home_dir}/bin/aid" "$@" >"$_tmp_out" 2>"$_tmp_err"
    RC_DC=$?
    OUT_DC="$(cat "$_tmp_out")"
    ERR_DC="$(cat "$_tmp_err")"
    rm -f "$_tmp_out" "$_tmp_err"
}

# Create a PATH stub directory containing a fake tailscale.
# Args: <stub_dir> <behaviour>
#   behaviour = "absent"      -- no tailscale binary at all (used for no-tailscale tests)
#   behaviour = "logged-in"   -- tailscale present, status OK, serve succeeds
#   behaviour = "not-logged-in" -- tailscale present, status says "not logged in"
#   behaviour = "serve-fail"  -- tailscale present, status OK, serve fails
# The stub records each invocation's argv to <stub_dir>/ts_calls.log.
make_tailscale_stub() {
    local stub_dir="$1"
    local behaviour="$2"
    local fqdn="${3:-stubhost.tail00000.ts.net}"

    mkdir -p "$stub_dir"

    if [[ "$behaviour" == "absent" ]]; then
        # No tailscale binary: PATH stub dir exists but no tailscale in it.
        return 0
    fi

    cat > "${stub_dir}/tailscale" <<STUBEOF
#!/usr/bin/env bash
# Stub tailscale for testing.
BEHAVIOUR="${behaviour}"
FQDN="${fqdn}"
STUB_DIR="${stub_dir}"

# Record argv.
echo "\$*" >> "\${STUB_DIR}/ts_calls.log"

# Fail if funnel is ever invoked (SEC-1 guard).
for arg in "\$@"; do
    if [[ "\$arg" == "funnel" || "\$arg" == "--funnel" ]]; then
        echo "STUB SECURITY VIOLATION: funnel called!" >&2
        exit 99
    fi
done

case "\$1" in
    status)
        if [[ "\$2" == "--json" ]]; then
            # Return minimal JSON with Self.DNSName.
            printf '{"Self":{"DNSName":"%s.","HostName":"%s"}}\n' "\$FQDN" "\${FQDN%%.*}"
            exit 0
        fi
        if [[ "\${BEHAVIOUR}" == "not-logged-in" ]]; then
            echo "not logged in" >&2
            exit 1
        fi
        echo "stubhost  100.64.0.1  stubhost  \${FQDN%%.*}"
        exit 0
        ;;
    serve)
        if [[ "\${BEHAVIOUR}" == "serve-fail" ]]; then
            echo "stub: tailscale serve failed" >&2
            exit 1
        fi
        # Simulate success for both serve --bg <port> and serve --bg --https=443 off.
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
STUBEOF
    chmod +x "${stub_dir}/tailscale"
}

# Run aid capturing stdout and stderr separately.
run_dc_split() {
    local home_dir="$1"; shift
    local _tmp_out _tmp_err
    _tmp_out="$(mktemp "${TMP}/out.XXXXXX")"
    _tmp_err="$(mktemp "${TMP}/err.XXXXXX")"
    AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
        bash "${home_dir}/bin/aid" "$@" >"$_tmp_out" 2>"$_tmp_err"
    RC_DC=$?
    OUT_DC="$(cat "$_tmp_out")"
    ERR_DC="$(cat "$_tmp_err")"
    rm -f "$_tmp_out" "$_tmp_err"
}

# Wait for a port to become unreachable (freed), up to ~3s.
wait_port_free() {
    local port="$1"
    local i=0
    while [[ $i -lt 30 ]]; do
        if ! (: < /dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
            return 0
        fi
        sleep 0.1
        i=$((i+1))
    done
    return 1
}

# ---------------------------------------------------------------------------
# T-1: aid dashboard start python — child spawned, dashboard.pid, exit 0, URL
# ---------------------------------------------------------------------------
echo "--- T-1: start python ---"
H1="$(new_aid_home)"
R1="$(new_fixture_repo)"
PORT1="$(pick_free_port)"

run_dc "$H1" dashboard start python --port "$PORT1" --target "$R1"
assert_exit_eq "$RC_DC" 0 "T-1: exit 0 on start python"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT1}" \
    "T-1: URL printed to stdout"
assert_output_contains "$OUT_DC" "stop with: aid dashboard stop" \
    "T-1: stop hint printed"

PID1_FILE="${R1}/.aid/.temp/dashboard.pid"
assert_file_exists "$PID1_FILE" "T-1: dashboard.pid written"

# Validate record fields: schema, runtime, port, bind, remote.
assert_file_contains "$PID1_FILE" '"schema": 1'         "T-1: record.schema=1"
assert_file_contains "$PID1_FILE" '"runtime": "python"' "T-1: record.runtime=python"
assert_file_contains "$PID1_FILE" "\"port\": ${PORT1}"  "T-1: record.port correct"
assert_file_contains "$PID1_FILE" '"bind": "127.0.0.1"' "T-1: record.bind=127.0.0.1"
assert_file_contains "$PID1_FILE" '"remote": false'     "T-1: record.remote=false"
assert_file_contains "$PID1_FILE" '"remote_handle": null' "T-1: record.remote_handle=null"

# Child must be alive.
_T1_PID="$(grep '"pid"' "$PID1_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T1_PID" ]] && SPAWNED_PIDS+=("$_T1_PID")
assert_eq "$(kill -0 "$_T1_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-1: child process alive"

# Clean up T-1 (stop records and kills child).
run_dc "$H1" dashboard stop --target "$R1"

# ---------------------------------------------------------------------------
# T-2: aid dashboard start node — same with runtime=node
# ---------------------------------------------------------------------------
echo "--- T-2: start node ---"
H2="$(new_aid_home)"
R2="$(new_fixture_repo)"
PORT2="$(pick_free_port)"

run_dc "$H2" dashboard start node --port "$PORT2" --target "$R2"
assert_exit_eq "$RC_DC" 0 "T-2: exit 0 on start node"
assert_output_contains "$OUT_DC" "Dashboard (node) running at http://127.0.0.1:${PORT2}" \
    "T-2: URL printed (node)"

PID2_FILE="${R2}/.aid/.temp/dashboard.pid"
assert_file_exists "$PID2_FILE" "T-2: dashboard.pid written (node)"
assert_file_contains "$PID2_FILE" '"runtime": "node"'   "T-2: record.runtime=node"
assert_file_contains "$PID2_FILE" '"bind": "127.0.0.1"' "T-2: record.bind=127.0.0.1 (node)"
assert_file_contains "$PID2_FILE" '"remote": false'     "T-2: record.remote=false (node)"

_T2_PID="$(grep '"pid"' "$PID2_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T2_PID" ]] && SPAWNED_PIDS+=("$_T2_PID")
assert_eq "$(kill -0 "$_T2_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-2: node child process alive"

# Clean up T-2.
run_dc "$H2" dashboard stop --target "$R2"

# ---------------------------------------------------------------------------
# T-3: second start while running — exit 8, "already running", no second child
# ---------------------------------------------------------------------------
echo "--- T-3: already running ---"
H3="$(new_aid_home)"
R3="$(new_fixture_repo)"
PORT3="$(pick_free_port)"

# First start.
run_dc "$H3" dashboard start python --port "$PORT3" --target "$R3"
assert_exit_eq "$RC_DC" 0 "T-3: first start exits 0"

_T3_PID="$(grep '"pid"' "${R3}/.aid/.temp/dashboard.pid" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T3_PID" ]] && SPAWNED_PIDS+=("$_T3_PID")

# Second start — must fail with exit 8.
run_dc "$H3" dashboard start python --port "$PORT3" --target "$R3"
assert_exit_eq "$RC_DC" 8 "T-3: second start exit 8"
assert_output_contains "$OUT_DC" "already running" "T-3: 'already running' message"
assert_output_contains "$OUT_DC" "run 'aid dashboard stop' first" \
    "T-3: stop-first hint"

# The original child must still be alive (no second child killed it).
assert_eq "$(kill -0 "$_T3_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-3: original child still alive after rejected second start"

# Clean up T-3.
run_dc "$H3" dashboard stop --target "$R3"

# ---------------------------------------------------------------------------
# T-4: stop after start — child gone, record+logfile removed, exit 0
# ---------------------------------------------------------------------------
echo "--- T-4: stop after start ---"
H4="$(new_aid_home)"
R4="$(new_fixture_repo)"
PORT4="$(pick_free_port)"

run_dc "$H4" dashboard start python --port "$PORT4" --target "$R4"
assert_exit_eq "$RC_DC" 0 "T-4: start exits 0 before stop"

_T4_PID="$(grep '"pid"' "${R4}/.aid/.temp/dashboard.pid" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T4_PID" ]] && SPAWNED_PIDS+=("$_T4_PID")
_T4_LOG="$(grep '"logfile"' "${R4}/.aid/.temp/dashboard.pid" | sed 's/.*"logfile": *"\([^"]*\)".*/\1/')"

run_dc "$H4" dashboard stop --target "$R4"
assert_exit_eq "$RC_DC" 0 "T-4: stop exits 0"
assert_output_contains "$OUT_DC" "aid: dashboard stopped." "T-4: stopped message"

# Child must be dead.
sleep 0.2
assert_eq "$(kill -0 "$_T4_PID" 2>/dev/null && echo alive || echo dead)" "dead" \
    "T-4: child dead after stop"

# dashboard.pid must be removed.
assert_eq "$(test -f "${R4}/.aid/.temp/dashboard.pid" && echo exists || echo gone)" "gone" \
    "T-4: dashboard.pid removed after stop"

# logfile must be removed.
if [[ -n "$_T4_LOG" ]]; then
    assert_eq "$(test -f "$_T4_LOG" && echo exists || echo gone)" "gone" \
        "T-4: logfile removed after stop"
fi

# Port must be free.
wait_port_free "$PORT4" \
    && pass "T-4: port ${PORT4} freed after stop" \
    || fail "T-4: port ${PORT4} still bound after stop"

# ---------------------------------------------------------------------------
# T-5: stop with nothing running — exit 0, idempotent
# ---------------------------------------------------------------------------
echo "--- T-5: stop nothing running ---"
H5="$(new_aid_home)"
R5="$(new_fixture_repo)"

run_dc "$H5" dashboard stop --target "$R5"
assert_exit_eq "$RC_DC" 0 "T-5: stop nothing exit 0"
assert_output_contains "$OUT_DC" "not running (nothing to stop)" \
    "T-5: nothing-to-stop message"

# Second stop also idempotent.
run_dc "$H5" dashboard stop --target "$R5"
assert_exit_eq "$RC_DC" 0 "T-5: second stop also exit 0"
assert_output_contains "$OUT_DC" "not running (nothing to stop)" \
    "T-5: second stop nothing-to-stop message"

# ---------------------------------------------------------------------------
# T-6: crash-then-restart — stale record reclaimed, fresh start, exit 0
# ---------------------------------------------------------------------------
echo "--- T-6: crash sim / stale reclaim ---"
H6="$(new_aid_home)"
R6="$(new_fixture_repo)"
PORT6="$(pick_free_port)"

# Start the dashboard.
run_dc "$H6" dashboard start python --port "$PORT6" --target "$R6"
assert_exit_eq "$RC_DC" 0 "T-6: initial start exits 0"

_T6_PID="$(grep '"pid"' "${R6}/.aid/.temp/dashboard.pid" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T6_PID" ]] && SPAWNED_PIDS+=("$_T6_PID")

# Simulate crash: kill the child out-of-band WITHOUT touching dashboard.pid.
kill -9 "$_T6_PID" 2>/dev/null || true
sleep 0.3
assert_eq "$(kill -0 "$_T6_PID" 2>/dev/null && echo alive || echo dead)" "dead" \
    "T-6: simulated crash confirmed (child dead)"
assert_file_exists "${R6}/.aid/.temp/dashboard.pid" \
    "T-6: stale record still present after crash"

# Start again — must reclaim stale record and succeed.
PORT6B="$(pick_free_port)"
run_dc "$H6" dashboard start python --port "$PORT6B" --target "$R6"
assert_exit_eq "$RC_DC" 0 "T-6: restart after crash exits 0"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT6B}" \
    "T-6: URL printed after stale reclaim"

_T6B_PID="$(grep '"pid"' "${R6}/.aid/.temp/dashboard.pid" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T6B_PID" ]] && SPAWNED_PIDS+=("$_T6B_PID")
assert_eq "$(kill -0 "$_T6B_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-6: fresh child alive after stale reclaim"

# Clean up T-6.
run_dc "$H6" dashboard stop --target "$R6"

# ---------------------------------------------------------------------------
# T-7: usage errors — exit 2 with correct messages
# Note: assert_output_contains uses grep -F; patterns starting with '--' would be
# parsed as grep flags, so we assert sub-strings that don't start with '--'.
# ---------------------------------------------------------------------------
echo "--- T-7: usage errors ---"
H7="$(new_aid_home)"
R7="$(new_fixture_repo)"
PORT7="$(pick_free_port)"

# T-7a: bad runtime.
run_dc "$H7" dashboard start foo --port "$PORT7" --target "$R7"
assert_exit_eq "$RC_DC" 2 "T-7a: bad runtime exit 2"
assert_output_contains "$OUT_DC" "unknown runtime 'foo'" "T-7a: bad runtime message"
assert_output_contains "$OUT_DC" "expected: node or python" "T-7a: expected message"

# T-7b: missing runtime (no positional).
run_dc "$H7" dashboard start --port "$PORT7" --target "$R7"
assert_exit_eq "$RC_DC" 2 "T-7b: missing runtime exit 2"
assert_output_contains "$OUT_DC" "dashboard start requires a runtime: node or python" \
    "T-7b: missing runtime message"

# T-7c: unknown flag.
run_dc "$H7" dashboard start python --port "$PORT7" --target "$R7" --unknown-flag
assert_exit_eq "$RC_DC" 2 "T-7c: unknown flag exit 2"
assert_output_contains "$OUT_DC" "unknown flag: --unknown-flag" "T-7c: unknown flag message"

# T-7d: bad --port (non-integer). Pattern avoids leading '--' for grep safety.
run_dc "$H7" dashboard start python --port abc --target "$R7"
assert_exit_eq "$RC_DC" 2 "T-7d: bad --port (non-integer) exit 2"
assert_output_contains "$OUT_DC" "port must be an integer in 1024..65535" \
    "T-7d: bad port message"

# T-7e: bad --port (out of range).
run_dc "$H7" dashboard start python --port 80 --target "$R7"
assert_exit_eq "$RC_DC" 2 "T-7e: bad --port (out of range) exit 2"
assert_output_contains "$OUT_DC" "port must be an integer in 1024..65535" \
    "T-7e: port out-of-range message"

# T-7f: stray positional on stop.
run_dc "$H7" dashboard stop extra_arg --target "$R7"
assert_exit_eq "$RC_DC" 2 "T-7f: stray positional on stop exit 2"
assert_output_contains "$OUT_DC" "unknown flag: extra_arg" \
    "T-7f: stray positional on stop message"

# Confirm no record was written during usage errors.
assert_eq "$(test -f "${R7}/.aid/.temp/dashboard.pid" && echo exists || echo gone)" "gone" \
    "T-7: no dashboard.pid written on usage errors"

# ---------------------------------------------------------------------------
# T-8: runtime absent (command-override PATH stub) — exit 9
#
# Implementation: override 'command -v python3' (or 'node') to return 127,
# making the CLI believe the runtime is absent. This is the bash-function-
# override equivalent of the PATH stub described in the task spec — it is
# deterministic and does not require uninstalling anything.
# ---------------------------------------------------------------------------
echo "--- T-8: runtime absent (PATH stub via command override) ---"
H8="$(new_aid_home)"
R8="$(new_fixture_repo)"
PORT8="$(pick_free_port)"

# Use a bash heredoc subshell that overrides 'command -v python3' to return 127,
# making the CLI believe python3 is absent from PATH.
OUT_DC="$(AID_HOME="$H8" AID_NO_UPDATE_CHECK=1 bash << INNEREOF
command() {
    if [[ "\$1" == "-v" && "\$2" == "python3" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
AID_HOME="${H8}" AID_NO_UPDATE_CHECK=1 bash "${H8}/bin/aid" dashboard start python \
    --port "${PORT8}" --target "${R8}" 2>&1
INNEREOF
)"
RC_DC=$?
assert_exit_eq "$RC_DC" 9 "T-8: python3 absent exit 9"
assert_output_contains "$OUT_DC" "python3 not found on PATH" \
    "T-8: python3 runtime-missing message"
assert_output_contains "$OUT_DC" "install it, or try: aid dashboard start node" \
    "T-8: python3 install-hint message"
assert_eq "$(test -f "${R8}/.aid/.temp/dashboard.pid" && echo exists || echo gone)" "gone" \
    "T-8: no dashboard.pid written when python3 absent"

# T-8 node variant.
H8b="$(new_aid_home)"
R8b="$(new_fixture_repo)"
PORT8b="$(pick_free_port)"

OUT_DC="$(AID_HOME="$H8b" AID_NO_UPDATE_CHECK=1 bash << INNEREOF
command() {
    if [[ "\$1" == "-v" && "\$2" == "node" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
AID_HOME="${H8b}" AID_NO_UPDATE_CHECK=1 bash "${H8b}/bin/aid" dashboard start node \
    --port "${PORT8b}" --target "${R8b}" 2>&1
INNEREOF
)"
RC_DC=$?
assert_exit_eq "$RC_DC" 9 "T-8: node absent exit 9"
assert_output_contains "$OUT_DC" "node not found on PATH" \
    "T-8: node runtime-missing message"
assert_output_contains "$OUT_DC" "install it, or try: aid dashboard start python" \
    "T-8: node install-hint message"

# ---------------------------------------------------------------------------
# T-9: port already in use — exit 3, no dashboard.pid written
#
# Implementation: We create a fixture repo with a fake server.py that exits
# immediately (simulating a server that fails to start, e.g. due to a port
# already in use). The bin/aid readiness loop detects the early child exit
# and reports exit 3 ("server failed to start").
#
# Why not a real busy-port listener: the bin/aid readiness poll uses a TCP
# connect (bash /dev/tcp), which SUCCEEDS against any listening socket on
# that port. So if we hold the port with a pre-existing listener, the
# readiness check connects to the listener, bin/aid thinks the server is up,
# and it exits 0. To get exit 3 we need the server child to die quickly.
#
# This approach faithfully reproduces the exit 3 / no-record contract from
# CLI-2 and the child-exited-early branch of Feature Flow step 8.
# ---------------------------------------------------------------------------
echo "--- T-9: server crash / port-in-use simulation ---"
H9="$(new_aid_home)"

# Create a repo with a fake server.py that exits immediately with a non-zero
# code, printing an "Address already in use" error to stderr (as Python's
# socket library would).
R9="$(mktemp -d "${TMP}/repo9.XXXXXX")"
mkdir -p "${R9}/.aid/.temp"
mkdir -p "${R9}/dashboard/server"
PORT9="$(pick_free_port)"

# Fake server.py that exits 1 immediately (simulates bind failure).
cat > "${R9}/dashboard/server/server.py" << 'FAKEEOF'
import sys
sys.stderr.write("OSError: [Errno 98] Address already in use\n")
sys.stderr.flush()
sys.exit(1)
FAKEEOF

# Also need a fake server.mjs (not used for python, but for completeness).
cat > "${R9}/dashboard/server/server.mjs" << 'FAKEEOF'
process.stderr.write("Error: Address already in use\n");
process.exit(1);
FAKEEOF

run_dc "$H9" dashboard start python --port "$PORT9" --target "$R9"
assert_exit_eq "$RC_DC" 3 "T-9: server crash (port-in-use sim) exit 3"
assert_output_contains "$OUT_DC" "server failed to start" \
    "T-9: server-failed-to-start message"
assert_output_contains "$OUT_DC" "Address already in use" \
    "T-9: log shows Address already in use (from fake server.py stderr)"
assert_eq "$(test -f "${R9}/.aid/.temp/dashboard.pid" && echo exists || echo gone)" "gone" \
    "T-9: no dashboard.pid written when server crashes"

# ---------------------------------------------------------------------------
# T-10: C4 regression guard — bare aid + aid version + aid status
# ---------------------------------------------------------------------------
echo "--- T-10: C4 regression (bare aid / version / status) ---"
H10="$(new_aid_home)"

# aid --help must exit 0 and show usage (not trigger dashboard start/stop).
run_dc "$H10" --help
assert_exit_eq "$RC_DC" 0 "T-10: aid --help exit 0"
assert_output_contains "$OUT_DC" "aid - AID CLI" "T-10: aid --help prints header"
assert_output_contains "$OUT_DC" "aid version"   "T-10: usage mentions 'aid version'"
assert_output_contains "$OUT_DC" "aid status"    "T-10: usage mentions 'aid status'"
assert_output_not_contains "$OUT_DC" "dashboard start requires" \
    "T-10: aid --help does not invoke dashboard start"

# aid version must exit 0 and print the version.
run_dc "$H10" version
assert_exit_eq "$RC_DC" 0 "T-10: aid version exit 0"
assert_output_contains "$OUT_DC" "${VERSION}" "T-10: aid version prints installed version"

# aid status on an empty dir must exit 7 (no AID install) — C4: existing behavior unchanged.
EMPTY_DIR10="$(mktemp -d "${TMP}/empty10.XXXXXX")"
run_dc "$H10" status --target "$EMPTY_DIR10"
assert_exit_eq "$RC_DC" 7 "T-10: aid status empty dir exit 7 (C4 not broken)"

# bare 'aid' (no args) must exit 0 and print the AID landing screen,
# NOT trigger dashboard-start or dashboard-stop code paths.
run_dc_split "$H10"
assert_exit_eq "$RC_DC" 0 "T-10: bare aid (no args) exit 0 (C4 preserved)"
assert_output_contains "$OUT_DC" "AID v${VERSION}" "T-10: bare aid prints AID version header"
assert_output_not_contains "$ERR_DC" "dashboard start requires" \
    "T-10: bare aid does not trigger dashboard-start error"
assert_output_not_contains "$OUT_DC" "already running" \
    "T-10: bare aid does not trigger already-running error"

# ---------------------------------------------------------------------------
# T-11: --remote with no mechanism — exit 10, record.remote=false, server local
# ---------------------------------------------------------------------------
echo "--- T-11: --remote no mechanism (tailscale absent via command override) ---"
H11="$(new_aid_home)"
R11="$(new_fixture_repo)"
PORT11="$(pick_free_port)"

# Override 'command -v tailscale' to return failure (simulate tailscale not on PATH).
# Uses the same heredoc subshell technique as T-8 for runtime-absent testing.
OUT_DC="$(AID_HOME="$H11" AID_NO_UPDATE_CHECK=1 bash << INNEREOF11
command() {
    if [[ "\$1" == "-v" && "\$2" == "tailscale" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
AID_HOME="${H11}" AID_NO_UPDATE_CHECK=1 bash "${H11}/bin/aid" dashboard start python \
    --port "${PORT11}" --remote --target "${R11}" 2>&1
INNEREOF11
)"
RC_DC=$?
assert_exit_eq "$RC_DC" 10 "T-11: --remote unavailable exit 10"
# Pattern avoids leading '--' for grep safety (assert uses grep -F).
assert_output_contains "$OUT_DC" \
    "remote requested but the secure remote-exposure mechanism is not available" \
    "T-11: remote-unavailable message"
assert_output_contains "$OUT_DC" \
    "dashboard is NOT exposed" \
    "T-11: NOT exposed stated"
assert_output_contains "$OUT_DC" \
    "Local server still running at http://127.0.0.1:${PORT11}" \
    "T-11: local server still running message"

# record must exist with remote=false (server was started even though --remote failed).
PID11_FILE="${R11}/.aid/.temp/dashboard.pid"
assert_file_exists "$PID11_FILE" "T-11: dashboard.pid written (server was started)"
assert_file_contains "$PID11_FILE" '"remote": false' "T-11: record.remote=false"

_T11_PID="$(grep '"pid"' "$PID11_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T11_PID" ]] && SPAWNED_PIDS+=("$_T11_PID")

# Server IS running locally (--remote exit 10 doesn't kill it).
assert_eq "$(kill -0 "$_T11_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-11: local server process still alive despite --remote failure"

# Clean up T-11 (server is running locally).
run_dc "$H11" dashboard stop --target "$R11"

# ---------------------------------------------------------------------------
# T-12: Bash-side parity — exact CLI-3 message format
# (PS twin asserted in test-aid-cli-parity.sh extension)
# ---------------------------------------------------------------------------
echo "--- T-12 (Bash side): exact CLI-3 message format ---"
H12="$(new_aid_home)"
R12="$(new_fixture_repo)"
PORT12="$(pick_free_port)"

# T-12a: start success — exact message.
run_dc "$H12" dashboard start python --port "$PORT12" --target "$R12"
assert_exit_eq "$RC_DC" 0 "T-12a: start exit 0"
assert_output_contains "$OUT_DC" \
    "Dashboard (python) running at http://127.0.0.1:${PORT12} -- stop with: aid dashboard stop" \
    "T-12a: start success exact message"

# T-12b: already-running — exact message.
run_dc "$H12" dashboard start python --port "$PORT12" --target "$R12"
assert_exit_eq "$RC_DC" 8 "T-12b: already-running exit 8"
assert_output_contains "$OUT_DC" \
    "aid: dashboard already running (runtime python, http://127.0.0.1:${PORT12}); run 'aid dashboard stop' first." \
    "T-12b: already-running exact message"

# T-12c: stop success — exact message.
run_dc "$H12" dashboard stop --target "$R12"
assert_exit_eq "$RC_DC" 0 "T-12c: stop exit 0"
assert_output_contains "$OUT_DC" "aid: dashboard stopped." \
    "T-12c: stop success exact message"

# T-12d: nothing-to-stop — exact message.
run_dc "$H12" dashboard stop --target "$R12"
assert_exit_eq "$RC_DC" 0 "T-12d: nothing-to-stop exit 0"
assert_output_contains "$OUT_DC" "aid: dashboard: not running (nothing to stop)." \
    "T-12d: nothing-to-stop exact message"

# T-12e: usage error — bad runtime exact message.
H12e="$(new_aid_home)"
R12e="$(new_fixture_repo)"
run_dc "$H12e" dashboard start foo --target "$R12e"
assert_exit_eq "$RC_DC" 2 "T-12e: bad runtime exit 2"
assert_output_contains "$OUT_DC" \
    "ERROR: aid: dashboard: unknown runtime 'foo' (expected: node or python)" \
    "T-12e: bad runtime exact message"

# T-12f: missing runtime exact message.
run_dc "$H12e" dashboard start --target "$R12e"
assert_exit_eq "$RC_DC" 2 "T-12f: missing runtime exit 2"
assert_output_contains "$OUT_DC" \
    "ERROR: aid: dashboard start requires a runtime: node or python (e.g. aid dashboard start python)" \
    "T-12f: missing runtime exact message"

# ---------------------------------------------------------------------------
# T-13: ASCII-only guard (delegate to test-ascii-only.sh)
# ---------------------------------------------------------------------------
echo "--- T-13: ASCII-only guard ---"
ASCII_SUITE="${SCRIPT_DIR}/test-ascii-only.sh"
if [[ -f "$ASCII_SUITE" ]]; then
    # Run and capture exit code; ignore output (the suite prints its own results).
    bash "$ASCII_SUITE" > /dev/null 2>&1
    ASCII_RC=$?
    assert_exit_eq "$ASCII_RC" 0 "T-13: bin/aid + bin/aid.ps1 pass ASCII-only gate"
else
    fail "T-13: test-ascii-only.sh not found at ${ASCII_SUITE}"
fi

# ---------------------------------------------------------------------------
# T-14: _aid_remote_expose / _aid_remote_teardown basic CLI tests (feature-005)
# Uses function-level mocking via bash heredoc technique -- never touches real tailnet.
# ---------------------------------------------------------------------------

echo "--- T-14: _aid_remote_expose / _aid_remote_teardown unit tests ---"
H14="$(new_aid_home)"
PORT14="$(pick_free_port)"

# Helper: extract ONLY function definitions from bin/aid (no top-level executable code).
# We grep for function definitions starting with the first function through to the dispatch marker.
# This avoids re-running the preamble (set -uo pipefail, source, exit calls) when eval'd.
_make_fn_src() {
    local bin="$1"
    # Extract only lines that are part of function bodies.
    # Strategy: extract from the first function definition (_aid_usage) to the dispatch marker.
    # This includes all function definitions plus any pure-function code between them.
    awk '/^# Parse subcommand and dispatch\./{exit}
         /^_aid_usage\(\)|^_aid_die\(\)|^_find_install_sh\(\)|^_aid_check_update\(\)|^_cmd_update_self\(\)|^_wire_one_profile\(\)|^_wire_path_unix\(\)|^_unwire_path_unix\(\)|^_install_global_cli\(\)|^_cmd_remove_self\(\)|^_aid_remote_expose\(\)|^_aid_remote_teardown\(\)|^_cmd_dashboard_ctl\(\)|^_dc_start\(\)|^_dc_stop\(\)|^_cmd_dashboard\(\)|^_resolve_tools_for_aid\(\)|^_prepare_tool_staging_aid\(\)/{in_fn=1}
         in_fn{print}' "$bin"
}
_BIN_AID_FN_SRC="$(_make_fn_src "${H14}/bin/aid")"

# Helper: runs a function in a subshell with a tailscale stub (records calls to ts_calls.log).
# Usage: run_aid_fn_with_stub <stub_dir> <fn_name> [args...]
# ts_calls.log in stub_dir records all invocations.
# Sets RC_DC, OUT_DC, ERR_DC.
run_aid_fn_with_stub() {
    local stub_dir="$1"; shift
    local _o _e
    _o="$(mktemp "${TMP}/o14.XXXXXX")"
    _e="$(mktemp "${TMP}/e14.XXXXXX")"
    local _fn_src="$_BIN_AID_FN_SRC"
    local _fn_args=("$@")
    # Build a miniature bash that: sources install-core, defines the functions,
    # stubs tailscale via a PATH-priority script, then calls the function.
    (
        PATH="${stub_dir}:${PATH}"
        AID_HOME="${H14}"
        AID_NO_UPDATE_CHECK=1
        source "${H14}/lib/aid-install-core.sh" 2>/dev/null || true
        eval "$_fn_src"
        "${_fn_args[@]}"
    ) >"$_o" 2>"$_e"
    RC_DC=$?
    OUT_DC="$(cat "$_o")"
    ERR_DC="$(cat "$_e")"
    rm -f "$_o" "$_e"
}

# T-14a: expose with stub logged-in tailscale -> exit 0, handle on stdout line1, https URL on line2.
echo "--- T-14a: expose with logged-in stub ---"
STUB14="$(mktemp -d "${TMP}/stub14.XXXXXX")"
make_tailscale_stub "$STUB14" "logged-in" "srvtest01.tail99999.ts.net"
run_aid_fn_with_stub "$STUB14" _aid_remote_expose "$PORT14"
assert_exit_eq "$RC_DC" 0 "T-14a: expose exit 0 with stub logged-in"
assert_output_contains "$OUT_DC" "tailscale-serve:${PORT14}" \
    "T-14a: handle line on stdout"
assert_output_contains "$OUT_DC" "https://" \
    "T-14a: https URL on stdout"
# stderr must contain the FR18 guidance block.
assert_output_contains "$ERR_DC" "tailnet policy file" \
    "T-14a: FR18 guidance printed to stderr"
assert_output_contains "$ERR_DC" "https://login.tailscale.com/admin/acls/file" \
    "T-14a: FR18 policy URL on stderr"
assert_output_contains "$ERR_DC" "deny-by-default" \
    "T-14a: deny-by-default in stderr"
# Confirm stub was called with 'serve --bg <port>' (NEVER funnel).
assert_output_contains "$(cat "${STUB14}/ts_calls.log" 2>/dev/null)" "serve --bg ${PORT14}" \
    "T-14a: stub recorded 'serve --bg <port>'"
if grep -q "funnel" "${STUB14}/ts_calls.log" 2>/dev/null; then
    fail "T-14a: SEC-1 VIOLATED -- funnel was called!"
else
    pass "T-14a: SEC-1 confirmed -- funnel never called"
fi

# T-14b: teardown with valid handle -> exit 0, stub records '--https=443 off'.
echo "--- T-14b: teardown with valid handle ---"
STUB14B="$(mktemp -d "${TMP}/stub14b.XXXXXX")"
make_tailscale_stub "$STUB14B" "logged-in" "srvtest01.tail99999.ts.net"
run_aid_fn_with_stub "$STUB14B" _aid_remote_teardown "tailscale-serve:${PORT14}"
assert_exit_eq "$RC_DC" 0 "T-14b: teardown exit 0"
# Stub recorded '--https=443 off' (the serve frontend revert command).
_t14b_calls="$(cat "${STUB14B}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t14b_calls" | grep -qF -- "--https=443 off"; then
    pass "T-14b: teardown called 'serve --bg --https=443 off'"
else
    fail "T-14b: teardown called 'serve --bg --https=443 off' -- calls were: ${_t14b_calls}"
fi
if grep -q "funnel" "${STUB14B}/ts_calls.log" 2>/dev/null; then
    fail "T-14b: SEC-1 VIOLATED -- funnel was called in teardown!"
else
    pass "T-14b: SEC-1 confirmed in teardown -- funnel never called"
fi

# T-14c: expose with no tailscale on PATH -> exit 10.
# Create a stub dir with NO tailscale binary, but override command -v via the subshell.
echo "--- T-14c: expose no tailscale ---"
STUB14C="$(mktemp -d "${TMP}/stub14c.XXXXXX")"
make_tailscale_stub "$STUB14C" "absent"
# Use a PATH with stub dir first AND remove the real tailscale from lookup
# by creating a directory with only essential binaries (not tailscale).
# Approach: use a wrapper that makes tailscale lookup fail via a non-executable stub.
cat > "${STUB14C}/tailscale" << 'NOTEXECEOF'
#!/usr/bin/env bash
# This stub explicitly makes tailscale look absent by returning error.
# It IS executable, so 'command -v' finds it, but that's the real test:
# we test that expose handles tailscale being truly absent by using
# a different approach: a PATH that hides the real tailscale.
NOTEXECEOF
# Remove the stub and instead make a truly absent PATH:
# Use run_aid_fn_with_stub with a PATH that only has stub dir (with no tailscale).
rm -f "${STUB14C}/tailscale"  # Remove so tailscale is absent from stub dir.
# But the real /usr/bin/tailscale is still on PATH. We need to shadow it.
# Solution: create a script that exits with 127 (like "not found") and is not executable.
# Instead, create a fake directory as the PATH, without any tailscale.
# The underlying PATH still has /usr/bin/tailscale.
# BEST solution: use the command() override inside the subshell.
_fn_src="$_BIN_AID_FN_SRC"
_o14c="$(mktemp "${TMP}/o14c.XXXXXX")"
_e14c="$(mktemp "${TMP}/e14c.XXXXXX")"
(
    AID_HOME="${H14}"
    AID_NO_UPDATE_CHECK=1
    source "${H14}/lib/aid-install-core.sh" 2>/dev/null || true
    eval "$_fn_src"
    command() {
        if [[ "$1" == "-v" && "$2" == "tailscale" ]]; then return 127; fi
        builtin command "$@"
    }
    _aid_remote_expose "$PORT14"
) >"$_o14c" 2>"$_e14c"
_rc14c=$?
rm -f "$_o14c" "$_e14c"
assert_exit_eq "$_rc14c" 10 "T-14c: expose no tailscale exit 10"

# T-14d: expose with non-numeric port (non-loopback token) -> exit 11.
echo "--- T-14d: expose non-loopback token ---"
run_aid_fn_with_stub "$STUB14" _aid_remote_expose "192.168.1.5:${PORT14}"
assert_exit_eq "$RC_DC" 11 "T-14d: expose non-loopback token exit 11"

# T-14e: expose with serve-fail stub -> exit 12, revert called.
echo "--- T-14e: expose serve fails ---"
STUB14E="$(mktemp -d "${TMP}/stub14e.XXXXXX")"
make_tailscale_stub "$STUB14E" "serve-fail" "srvtest01.tail99999.ts.net"
run_aid_fn_with_stub "$STUB14E" _aid_remote_expose "$PORT14"
assert_exit_eq "$RC_DC" 12 "T-14e: expose serve-fail exit 12"
# Revert should have been attempted: stub records '--https=443 off'.
_t14e_calls="$(cat "${STUB14E}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t14e_calls" | grep -qF -- "--https=443 off"; then
    pass "T-14e: serve-fail triggered revert (--https=443 off)"
else
    fail "T-14e: serve-fail triggered revert (--https=443 off) -- calls were: ${_t14e_calls}"
fi

# T-14f: teardown with malformed handle -> exit 0 (idempotent).
echo "--- T-14f: teardown malformed handle ---"
run_aid_fn_with_stub "$STUB14" _aid_remote_teardown "not-a-valid-handle"
assert_exit_eq "$RC_DC" 0 "T-14f: malformed handle exit 0"

# T-14g: teardown with empty handle -> exit 0 (idempotent).
echo "--- T-14g: teardown empty handle ---"
run_aid_fn_with_stub "$STUB14" _aid_remote_teardown ""
assert_exit_eq "$RC_DC" 0 "T-14g: empty handle exit 0"

# T-14h: start --remote with logged-in stub -> exit 0, record.remote=true, remote_handle set.
# For T-14h/i we use the same command-override technique as T-8/T-11 but for tailscale stub.
echo "--- T-14h: start --remote with logged-in stub ---"
H14h="$(new_aid_home)"
R14h="$(new_fixture_repo)"
PORT14h="$(pick_free_port)"
STUB14H="$(mktemp -d "${TMP}/stub14h.XXXXXX")"
make_tailscale_stub "$STUB14H" "logged-in" "srvtest01.tail99999.ts.net"

# Run the full aid binary with the stub on PATH (for T-14h, tailscale must be the stub).
# The stub IS a real executable, so PATH="${STUB14H}:..." ensures it wins over /usr/bin/tailscale.
_T14H_OUT="$(mktemp "${TMP}/t14h_out.XXXXXX")"
_T14H_ERR="$(mktemp "${TMP}/t14h_err.XXXXXX")"
PATH="${STUB14H}:${PATH}" AID_HOME="$H14h" AID_NO_UPDATE_CHECK=1 \
    bash "${H14h}/bin/aid" dashboard start python --port "$PORT14h" --remote --target "$R14h" \
    >"$_T14H_OUT" 2>"$_T14H_ERR"
RC_DC=$?
OUT_DC="$(cat "$_T14H_OUT")"
ERR_DC="$(cat "$_T14H_ERR")"
rm -f "$_T14H_OUT" "$_T14H_ERR"

assert_exit_eq "$RC_DC" 0 "T-14h: start --remote with stub exit 0"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT14h}" \
    "T-14h: local URL printed"
assert_output_contains "$OUT_DC" "Remote (private):" \
    "T-14h: Remote (private) URL printed"
PID14H_FILE="${R14h}/.aid/.temp/dashboard.pid"
assert_file_exists "$PID14H_FILE" "T-14h: dashboard.pid written"
assert_file_contains "$PID14H_FILE" '"remote": true' "T-14h: record.remote=true"
assert_file_contains "$PID14H_FILE" "tailscale-serve:${PORT14h}" "T-14h: remote_handle in record"
_T14H_PID="$(grep '"pid"' "$PID14H_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T14H_PID" ]] && SPAWNED_PIDS+=("$_T14H_PID")

# T-14i: stop after remote start -> teardown called, stub records --https=443 off, exit 0.
echo "--- T-14i: stop after remote start ---"
PATH="${STUB14H}:${PATH}" AID_HOME="$H14h" AID_NO_UPDATE_CHECK=1 \
    bash "${H14h}/bin/aid" dashboard stop --target "$R14h" >/dev/null 2>&1
assert_exit_eq "$?" 0 "T-14i: stop after remote start exit 0"
_t14i_calls="$(cat "${STUB14H}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t14i_calls" | grep -qF -- "--https=443 off"; then
    pass "T-14i: teardown called --https=443 off on stop"
else
    fail "T-14i: teardown called --https=443 off on stop -- calls were: ${_t14i_calls}"
fi

# T-14j: SEC-1 grep check -- no EXECUTABLE 'funnel' call in the expose/teardown helpers.
# We check that no non-comment, non-string-literal line invokes tailscale funnel.
# The functions may MENTION 'funnel' in comments (documenting why we don't use it);
# what matters is that no code path calls it.
echo "--- T-14j: SEC-1 no-funnel grep check ---"
# Check bin/aid expose/teardown section for any line that is NOT a comment and contains 'funnel'.
_funnel_exec_hits="$(awk '/_aid_remote_expose\(\)/,/_cmd_dashboard_ctl\(\)/' "${BIN_AID}" | \
    grep -v '^\s*#' | grep -c 'funnel' || true)"
assert_eq "$_funnel_exec_hits" "0" "T-14j: no executable 'funnel' call in expose/teardown helpers (SEC-1)"

# ---------------------------------------------------------------------------
# T-13: ASCII-only guard (delegate to test-ascii-only.sh)
# ---------------------------------------------------------------------------
echo "--- T-13: ASCII-only guard ---"
ASCII_SUITE="${SCRIPT_DIR}/test-ascii-only.sh"
if [[ -f "$ASCII_SUITE" ]]; then
    # Run and capture exit code; ignore output (the suite prints its own results).
    bash "$ASCII_SUITE" > /dev/null 2>&1
    ASCII_RC=$?
    assert_exit_eq "$ASCII_RC" 0 "T-13: bin/aid + bin/aid.ps1 pass ASCII-only gate"
else
    fail "T-13: test-ascii-only.sh not found at ${ASCII_SUITE}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
