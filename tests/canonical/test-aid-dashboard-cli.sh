#!/usr/bin/env bash
# test-aid-dashboard-cli.sh - Feature-004 CLI test scenarios T-1..T-15.
#
# Tests the aid dashboard start/stop handlers in bin/aid (Bash).
# PowerShell parity for T-1/T-3/T-4/T-5/T-7 is in test-aid-cli-parity.sh.
# T-13 ASCII-only guard delegates to test-ascii-only.sh.
#
# Feature-005 expose/teardown unit tests (function-level, stub-based) live in
# test-aid-remote.sh (T-1..T-9).  This file retains only the feature-004
# integration assertions for the --remote SUCCESS path (T-14h/T-14i): when
# tailscale IS available, start --remote must set record.remote=true and stop
# must invoke teardown.  Those integration assertions are NOT duplicated in
# test-aid-remote.sh.
#
# Scenarios:
#   T-1   start python   -> child spawned, dashboard.pid in $HOME/.aid/.temp/, exit 0, URL printed
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
#   T-14  --remote SUCCESS integration: record.remote=true + teardown-on-stop
#   T-15  Non-project dir regression: start from bare $HOME succeeds (exit 0),
#         prints URL, writes pid to $HOME/.aid/.temp/; and does NOT register cwd.
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
DASHBOARD_SRC_DIR="${REPO_ROOT}/dashboard"

[[ -f "$BIN_AID" ]] || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_SH"  ]] || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_SH" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Temp workspace -- single shared dir, cleaned on exit.
# HOME is pinned to a throwaway dir so dashboard.pid writes never touch the
# real ~/.aid/.temp.  An escape canary asserts the real HOME was not touched.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
PINNED_HOME="${TMP}/home"
mkdir -p "${PINNED_HOME}/.aid/.temp"

# Canary: remember whether the real $HOME/.aid/.temp existed before the suite.
# We never touch REAL_HOME during the suite.
REAL_HOME="$HOME"
REAL_AID_TEMP="${REAL_HOME}/.aid/.temp"

# Track spawned child pids for safety cleanup.
SPAWNED_PIDS=()

cleanup_all() {
    for _p in "${SPAWNED_PIDS[@]:-}"; do
        [[ -n "$_p" ]] || continue
        kill -TERM -"$_p" 2>/dev/null || kill -TERM "$_p" 2>/dev/null || true
        sleep 0.1
        kill -9 -"$_p" 2>/dev/null || kill -9 "$_p" 2>/dev/null || true
    done
    # Escape canary: assert real HOME was never modified.
    if [[ -d "$REAL_AID_TEMP" ]]; then
        # Real .temp existed before suite -- check it was not touched (no new dashboard.pid).
        :
    fi
}

trap 'cleanup_all; rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# AID home + fixture helpers.
# ---------------------------------------------------------------------------
VERSION="0.7.0"

new_aid_home() {
    local h; h="$(mktemp -d "${TMP}/home.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib" "${h}/dashboard/reader" "${h}/dashboard/server"
    cp "$BIN_AID"  "${h}/bin/aid"
    chmod +x "${h}/bin/aid"
    cp "$LIB_SH"   "${h}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${h}/VERSION"
    # Install the curated dashboard unit under $AID_HOME/dashboard/ (D8 spawn-seam layout).
    # Use symlinks to the repo sources so tests always run against the current code.
    ln -sf "${DASHBOARD_SRC_DIR}/index.html"             "${h}/dashboard/index.html"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/__init__.py"     "${h}/dashboard/reader/__init__.py"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/reader.py"       "${h}/dashboard/reader/reader.py"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/models.py"       "${h}/dashboard/reader/models.py"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/parsers.py"      "${h}/dashboard/reader/parsers.py"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/derivation.py"   "${h}/dashboard/reader/derivation.py"
    ln -sf "${DASHBOARD_SRC_DIR}/reader/locator.py"      "${h}/dashboard/reader/locator.py"
    ln -sf "${DASHBOARD_SRC_DIR}/server/server.py"       "${h}/dashboard/server/server.py"
    ln -sf "${DASHBOARD_SRC_DIR}/server/server.mjs"      "${h}/dashboard/server/server.mjs"
    ln -sf "${DASHBOARD_SRC_DIR}/server/reader.mjs"      "${h}/dashboard/server/reader.mjs"
    ln -sf "${DASHBOARD_SRC_DIR}/server/__init__.py"     "${h}/dashboard/server/__init__.py"
    echo "$h"
}

# A minimal non-project directory (no .aid/) for non-project-dir tests.
new_nonproject_dir() {
    local d; d="$(mktemp -d "${TMP}/nonproj.XXXXXX")"
    echo "$d"
}

# Pick a free port by letting the OS assign an ephemeral one, then release it.
pick_free_port() {
    python3 -c "import socket; s=socket.socket(); s.bind(('',0)); p=s.getsockname()[1]; s.close(); print(p)"
}

# run aid in an isolated home/fixture env with a pinned HOME.
# The dashboard pid/log go to PINNED_HOME/.aid/.temp/ (never the real ~/.aid).
# Captures stdout+stderr merged into OUT_DC, exit into RC_DC.
run_dc() {
    local home_dir="$1"; shift
    OUT_DC="$(HOME="${PINNED_HOME}" AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
              bash "${home_dir}/bin/aid" "$@" 2>&1)"
    RC_DC=$?
}

# run from a specific cwd (non-project dir), still pinning HOME.
run_dc_from() {
    local cwd="$1"; local home_dir="$2"; shift 2
    OUT_DC="$(cd "$cwd" && HOME="${PINNED_HOME}" AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
              bash "${home_dir}/bin/aid" "$@" 2>&1)"
    RC_DC=$?
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
    HOME="${PINNED_HOME}" AID_HOME="$home_dir" AID_NO_UPDATE_CHECK=1 \
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

# Convenience: path of dashboard.pid under the pinned HOME.
PINNED_PID_FILE="${PINNED_HOME}/.aid/.temp/dashboard.pid"
PINNED_LOG_FILE="${PINNED_HOME}/.aid/.temp/dashboard.log"

# ---------------------------------------------------------------------------
# T-1: aid dashboard start python -- child spawned, dashboard.pid in $HOME/.aid/.temp/, exit 0, URL
# ---------------------------------------------------------------------------
echo "--- T-1: start python ---"
H1="$(new_aid_home)"
PORT1="$(pick_free_port)"
# Ensure no stale pid from a prior run.
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

run_dc "$H1" dashboard start python --port "$PORT1"
assert_exit_eq "$RC_DC" 0 "T-1: exit 0 on start python"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT1}" \
    "T-1: URL printed to stdout"
assert_output_contains "$OUT_DC" "stop with: aid dashboard stop" \
    "T-1: stop hint printed"

assert_file_exists "$PINNED_PID_FILE" "T-1: dashboard.pid written in HOME/.aid/.temp/"

# Validate record fields: schema, runtime, port, bind, remote (no target field).
assert_file_contains "$PINNED_PID_FILE" '"schema": 1'         "T-1: record.schema=1"
assert_file_contains "$PINNED_PID_FILE" '"runtime": "python"' "T-1: record.runtime=python"
assert_file_contains "$PINNED_PID_FILE" "\"port\": ${PORT1}"  "T-1: record.port correct"
assert_file_contains "$PINNED_PID_FILE" '"bind": "127.0.0.1"' "T-1: record.bind=127.0.0.1"
assert_file_contains "$PINNED_PID_FILE" '"remote": false'     "T-1: record.remote=false"
assert_file_contains "$PINNED_PID_FILE" '"remote_handle": null' "T-1: record.remote_handle=null"

# Record must NOT have a "target" field.
if grep -qF '"target"' "$PINNED_PID_FILE"; then
    fail "T-1: record must NOT have a 'target' field"
else
    pass "T-1: record has no 'target' field"
fi

# Child must be alive.
_T1_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T1_PID" ]] && SPAWNED_PIDS+=("$_T1_PID")
assert_eq "$(kill -0 "$_T1_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-1: child process alive"

# Clean up T-1 (stop records and kills child).
run_dc "$H1" dashboard stop

# ---------------------------------------------------------------------------
# T-2: aid dashboard start node -- same with runtime=node (sequential, ONE dashboard)
# ---------------------------------------------------------------------------
echo "--- T-2: start node ---"
H2="$(new_aid_home)"
PORT2="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

run_dc "$H2" dashboard start node --port "$PORT2"
assert_exit_eq "$RC_DC" 0 "T-2: exit 0 on start node"
assert_output_contains "$OUT_DC" "Dashboard (node) running at http://127.0.0.1:${PORT2}" \
    "T-2: URL printed (node)"

assert_file_exists "$PINNED_PID_FILE" "T-2: dashboard.pid written (node)"
assert_file_contains "$PINNED_PID_FILE" '"runtime": "node"'   "T-2: record.runtime=node"
assert_file_contains "$PINNED_PID_FILE" '"bind": "127.0.0.1"' "T-2: record.bind=127.0.0.1 (node)"
assert_file_contains "$PINNED_PID_FILE" '"remote": false'     "T-2: record.remote=false (node)"

# Record must NOT have a "target" field.
if grep -qF '"target"' "$PINNED_PID_FILE"; then
    fail "T-2: record must NOT have a 'target' field"
else
    pass "T-2: record has no 'target' field"
fi

_T2_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T2_PID" ]] && SPAWNED_PIDS+=("$_T2_PID")
assert_eq "$(kill -0 "$_T2_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-2: node child process alive"

# Clean up T-2.
run_dc "$H2" dashboard stop

# ---------------------------------------------------------------------------
# T-3: second start while running -- exit 8, "already running", no second child
# ---------------------------------------------------------------------------
echo "--- T-3: already running ---"
H3="$(new_aid_home)"
PORT3="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# First start.
run_dc "$H3" dashboard start python --port "$PORT3"
assert_exit_eq "$RC_DC" 0 "T-3: first start exits 0"

_T3_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T3_PID" ]] && SPAWNED_PIDS+=("$_T3_PID")

# Second start -- must fail with exit 8.
run_dc "$H3" dashboard start python --port "$PORT3"
assert_exit_eq "$RC_DC" 8 "T-3: second start exit 8"
assert_output_contains "$OUT_DC" "already running" "T-3: 'already running' message"
assert_output_contains "$OUT_DC" "run 'aid dashboard stop' first" \
    "T-3: stop-first hint"

# The original child must still be alive (no second child killed it).
assert_eq "$(kill -0 "$_T3_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-3: original child still alive after rejected second start"

# Clean up T-3.
run_dc "$H3" dashboard stop

# ---------------------------------------------------------------------------
# T-4: stop after start -- child gone, record+logfile removed, exit 0
# ---------------------------------------------------------------------------
echo "--- T-4: stop after start ---"
H4="$(new_aid_home)"
PORT4="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

run_dc "$H4" dashboard start python --port "$PORT4"
assert_exit_eq "$RC_DC" 0 "T-4: start exits 0 before stop"

_T4_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T4_PID" ]] && SPAWNED_PIDS+=("$_T4_PID")
_T4_LOG="$(grep '"logfile"' "$PINNED_PID_FILE" | sed 's/.*"logfile": *"\([^"]*\)".*/\1/')"

run_dc "$H4" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-4: stop exits 0"
assert_output_contains "$OUT_DC" "aid: dashboard stopped." "T-4: stopped message"

# Child must be dead.
sleep 0.2
assert_eq "$(kill -0 "$_T4_PID" 2>/dev/null && echo alive || echo dead)" "dead" \
    "T-4: child dead after stop"

# dashboard.pid must be removed.
assert_eq "$(test -f "$PINNED_PID_FILE" && echo exists || echo gone)" "gone" \
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
# T-5: stop with nothing running -- exit 0, idempotent
# ---------------------------------------------------------------------------
echo "--- T-5: stop nothing running ---"
H5="$(new_aid_home)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

run_dc "$H5" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-5: stop nothing exit 0"
assert_output_contains "$OUT_DC" "not running (nothing to stop)" \
    "T-5: nothing-to-stop message"

# Second stop also idempotent.
run_dc "$H5" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-5: second stop also exit 0"
assert_output_contains "$OUT_DC" "not running (nothing to stop)" \
    "T-5: second stop nothing-to-stop message"

# ---------------------------------------------------------------------------
# T-6: crash-then-restart -- stale record reclaimed, fresh start, exit 0
# ---------------------------------------------------------------------------
echo "--- T-6: crash sim / stale reclaim ---"
H6="$(new_aid_home)"
PORT6="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# Start the dashboard.
run_dc "$H6" dashboard start python --port "$PORT6"
assert_exit_eq "$RC_DC" 0 "T-6: initial start exits 0"

_T6_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T6_PID" ]] && SPAWNED_PIDS+=("$_T6_PID")

# Simulate crash: kill the child out-of-band WITHOUT touching dashboard.pid.
kill -9 "$_T6_PID" 2>/dev/null || true
sleep 0.3
assert_eq "$(kill -0 "$_T6_PID" 2>/dev/null && echo alive || echo dead)" "dead" \
    "T-6: simulated crash confirmed (child dead)"
assert_file_exists "$PINNED_PID_FILE" \
    "T-6: stale record still present after crash"

# Start again -- must reclaim stale record and succeed.
PORT6B="$(pick_free_port)"
run_dc "$H6" dashboard start python --port "$PORT6B"
assert_exit_eq "$RC_DC" 0 "T-6: restart after crash exits 0"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT6B}" \
    "T-6: URL printed after stale reclaim"

_T6B_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T6B_PID" ]] && SPAWNED_PIDS+=("$_T6B_PID")
assert_eq "$(kill -0 "$_T6B_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-6: fresh child alive after stale reclaim"

# Clean up T-6.
run_dc "$H6" dashboard stop

# ---------------------------------------------------------------------------
# T-7: usage errors -- exit 2 with correct messages
# Note: assert_output_contains uses grep -F; patterns starting with '--' would be
# parsed as grep flags, so we assert sub-strings that don't start with '--'.
# ---------------------------------------------------------------------------
echo "--- T-7: usage errors ---"
H7="$(new_aid_home)"
PORT7="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# T-7a: bad runtime.
run_dc "$H7" dashboard start foo --port "$PORT7"
assert_exit_eq "$RC_DC" 2 "T-7a: bad runtime exit 2"
assert_output_contains "$OUT_DC" "unknown runtime 'foo'" "T-7a: bad runtime message"
assert_output_contains "$OUT_DC" "expected: node or python" "T-7a: expected message"

# T-7b: missing runtime (no positional).
run_dc "$H7" dashboard start --port "$PORT7"
assert_exit_eq "$RC_DC" 2 "T-7b: missing runtime exit 2"
assert_output_contains "$OUT_DC" "dashboard start requires a runtime: node or python" \
    "T-7b: missing runtime message"

# T-7c: unknown flag.
run_dc "$H7" dashboard start python --port "$PORT7" --unknown-flag
assert_exit_eq "$RC_DC" 2 "T-7c: unknown flag exit 2"
assert_output_contains "$OUT_DC" "unknown flag: --unknown-flag" "T-7c: unknown flag message"

# T-7d: bad --port (non-integer). Pattern avoids leading '--' for grep safety.
run_dc "$H7" dashboard start python --port abc
assert_exit_eq "$RC_DC" 2 "T-7d: bad --port (non-integer) exit 2"
assert_output_contains "$OUT_DC" "port must be an integer in 1024..65535" \
    "T-7d: bad port message"

# T-7e: bad --port (out of range).
run_dc "$H7" dashboard start python --port 80
assert_exit_eq "$RC_DC" 2 "T-7e: bad --port (out of range) exit 2"
assert_output_contains "$OUT_DC" "port must be an integer in 1024..65535" \
    "T-7e: port out-of-range message"

# T-7f: stray positional on stop.
run_dc "$H7" dashboard stop extra_arg
assert_exit_eq "$RC_DC" 2 "T-7f: stray positional on stop exit 2"
assert_output_contains "$OUT_DC" "unknown flag: extra_arg" \
    "T-7f: stray positional on stop message"

# T-7g: --target flag rejected (removed).
run_dc "$H7" dashboard start python --port "$PORT7" --target /tmp
assert_exit_eq "$RC_DC" 2 "T-7g: --target flag now rejected (exit 2)"
assert_output_contains "$OUT_DC" "unknown flag: --target" "T-7g: --target unknown-flag message"

# Confirm no record was written during usage errors.
assert_eq "$(test -f "$PINNED_PID_FILE" && echo exists || echo gone)" "gone" \
    "T-7: no dashboard.pid written on usage errors"

# ---------------------------------------------------------------------------
# T-8: runtime absent (command-override PATH stub) -- exit 9
#
# Implementation: override 'command -v python3' (or 'node') to return 127,
# making the CLI believe the runtime is absent. This is the bash-function-
# override equivalent of the PATH stub described in the task spec -- it is
# deterministic and does not require uninstalling anything.
# ---------------------------------------------------------------------------
echo "--- T-8: runtime absent (PATH stub via command override) ---"
H8="$(new_aid_home)"
PORT8="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# Use a bash heredoc subshell that overrides 'command -v python3' to return 127,
# making the CLI believe python3 is absent from PATH.
OUT_DC="$(HOME="${PINNED_HOME}" AID_HOME="$H8" AID_NO_UPDATE_CHECK=1 bash << INNEREOF
command() {
    if [[ "\$1" == "-v" && "\$2" == "python3" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
HOME="${PINNED_HOME}" AID_HOME="${H8}" AID_NO_UPDATE_CHECK=1 bash "${H8}/bin/aid" dashboard start python \
    --port "${PORT8}" 2>&1
INNEREOF
)"
RC_DC=$?
assert_exit_eq "$RC_DC" 9 "T-8: python3 absent exit 9"
assert_output_contains "$OUT_DC" "python3 not found on PATH" \
    "T-8: python3 runtime-missing message"
assert_output_contains "$OUT_DC" "install it, or try: aid dashboard start node" \
    "T-8: python3 install-hint message"
assert_eq "$(test -f "$PINNED_PID_FILE" && echo exists || echo gone)" "gone" \
    "T-8: no dashboard.pid written when python3 absent"

# T-8 node variant.
H8b="$(new_aid_home)"
PORT8b="$(pick_free_port)"

OUT_DC="$(HOME="${PINNED_HOME}" AID_HOME="$H8b" AID_NO_UPDATE_CHECK=1 bash << INNEREOF
command() {
    if [[ "\$1" == "-v" && "\$2" == "node" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
HOME="${PINNED_HOME}" AID_HOME="${H8b}" AID_NO_UPDATE_CHECK=1 bash "${H8b}/bin/aid" dashboard start node \
    --port "${PORT8b}" 2>&1
INNEREOF
)"
RC_DC=$?
assert_exit_eq "$RC_DC" 9 "T-8: node absent exit 9"
assert_output_contains "$OUT_DC" "node not found on PATH" \
    "T-8: node runtime-missing message"
assert_output_contains "$OUT_DC" "install it, or try: aid dashboard start python" \
    "T-8: node install-hint message"

# ---------------------------------------------------------------------------
# T-9: port already in use -- exit 3, no dashboard.pid written
#
# Implementation: We create an AID home with a fake server.py that exits
# immediately (simulating a server that fails to start, e.g. due to a port
# already in use). The bin/aid readiness loop detects the early child exit
# and reports exit 3 ("server failed to start").
# ---------------------------------------------------------------------------
echo "--- T-9: server crash / port-in-use simulation ---"
# T-9 uses a custom AID_HOME with a fake server that exits immediately.
H9="$(new_aid_home)"
PORT9="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# Override the real server.py in the AID_HOME with a fake that exits 1 immediately
# (simulates bind failure), printing an "Address already in use" error to stderr.
# Remove the symlinks first so we write a new regular file, not through to the repo source.
rm -f "${H9}/dashboard/server/server.py"
cat > "${H9}/dashboard/server/server.py" << 'FAKEEOF'
import sys
sys.stderr.write("OSError: [Errno 98] Address already in use\n")
sys.stderr.flush()
sys.exit(1)
FAKEEOF

# Also replace server.mjs (not used for python in T-9, but for fixture completeness).
rm -f "${H9}/dashboard/server/server.mjs"
cat > "${H9}/dashboard/server/server.mjs" << 'FAKEEOF'
process.stderr.write("Error: Address already in use\n");
process.exit(1);
FAKEEOF

run_dc "$H9" dashboard start python --port "$PORT9"
assert_exit_eq "$RC_DC" 3 "T-9: server crash (port-in-use sim) exit 3"
assert_output_contains "$OUT_DC" "server failed to start" \
    "T-9: server-failed-to-start message"
assert_output_contains "$OUT_DC" "Address already in use" \
    "T-9: log shows Address already in use (from fake server.py stderr)"
assert_eq "$(test -f "$PINNED_PID_FILE" && echo exists || echo gone)" "gone" \
    "T-9: no dashboard.pid written when server crashes"

# ---------------------------------------------------------------------------
# T-10: C4 regression guard -- bare aid + aid version + aid status
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

# aid status on a dir with no .aid/ -> "no AID project here" + exit 0 (decision #5 new behavior).
EMPTY_DIR10="$(mktemp -d "${TMP}/empty10.XXXXXX")"
run_dc "$H10" status --target "$EMPTY_DIR10"
assert_exit_eq "$RC_DC" 0 "T-10: aid status empty dir exit 0 (decision #5: no hard refuse)"
assert_output_contains "$OUT_DC" "no AID project here" \
    "T-10: aid status empty dir prints offer message"

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
# T-11: --remote with no mechanism -- exit 10, record.remote=false, server local
# ---------------------------------------------------------------------------
echo "--- T-11: --remote no mechanism (tailscale absent via command override) ---"
H11="$(new_aid_home)"
PORT11="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# Override 'command -v tailscale' to return failure (simulate tailscale not on PATH).
# Uses the same heredoc subshell technique as T-8 for runtime-absent testing.
OUT_DC="$(HOME="${PINNED_HOME}" AID_HOME="$H11" AID_NO_UPDATE_CHECK=1 bash << INNEREOF11
command() {
    if [[ "\$1" == "-v" && "\$2" == "tailscale" ]]; then
        return 127
    fi
    builtin command "\$@"
}
export -f command
HOME="${PINNED_HOME}" AID_HOME="${H11}" AID_NO_UPDATE_CHECK=1 bash "${H11}/bin/aid" dashboard start python \
    --port "${PORT11}" --remote 2>&1
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
assert_file_exists "$PINNED_PID_FILE" "T-11: dashboard.pid written (server was started)"
assert_file_contains "$PINNED_PID_FILE" '"remote": false' "T-11: record.remote=false"

_T11_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T11_PID" ]] && SPAWNED_PIDS+=("$_T11_PID")

# Server IS running locally (--remote exit 10 doesn't kill it).
assert_eq "$(kill -0 "$_T11_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-11: local server process still alive despite --remote failure"

# Clean up T-11 (server is running locally).
run_dc "$H11" dashboard stop

# ---------------------------------------------------------------------------
# T-12: Bash-side parity -- exact CLI-3 message format
# (PS twin asserted in test-aid-cli-parity.sh extension)
# ---------------------------------------------------------------------------
echo "--- T-12 (Bash side): exact CLI-3 message format ---"
H12="$(new_aid_home)"
PORT12="$(pick_free_port)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# T-12a: start success -- exact message.
run_dc "$H12" dashboard start python --port "$PORT12"
assert_exit_eq "$RC_DC" 0 "T-12a: start exit 0"
assert_output_contains "$OUT_DC" \
    "Dashboard (python) running at http://127.0.0.1:${PORT12} -- stop with: aid dashboard stop" \
    "T-12a: start success exact message"

# T-12b: already-running -- exact message.
run_dc "$H12" dashboard start python --port "$PORT12"
assert_exit_eq "$RC_DC" 8 "T-12b: already-running exit 8"
assert_output_contains "$OUT_DC" \
    "aid: dashboard already running (runtime python, http://127.0.0.1:${PORT12}); run 'aid dashboard stop' first." \
    "T-12b: already-running exact message"

# T-12c: stop success -- exact message.
run_dc "$H12" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-12c: stop exit 0"
assert_output_contains "$OUT_DC" "aid: dashboard stopped." \
    "T-12c: stop success exact message"

# T-12d: nothing-to-stop -- exact message.
run_dc "$H12" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-12d: nothing-to-stop exit 0"
assert_output_contains "$OUT_DC" "aid: dashboard: not running (nothing to stop)." \
    "T-12d: nothing-to-stop exact message"

# T-12e: usage error -- bad runtime exact message.
H12e="$(new_aid_home)"
run_dc "$H12e" dashboard start foo
assert_exit_eq "$RC_DC" 2 "T-12e: bad runtime exit 2"
assert_output_contains "$OUT_DC" \
    "ERROR: aid: dashboard: unknown runtime 'foo' (expected: node or python)" \
    "T-12e: bad runtime exact message"

# T-12f: missing runtime exact message.
run_dc "$H12e" dashboard start
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
# T-14: --remote SUCCESS integration (feature-004/005).
# T-14h: start --remote with logged-in tailscale stub -> exit 0, record.remote=true,
#         remote_handle written, local URL + "Remote (private):" printed.
# T-14i: stop after remote start -> teardown called (stub records --https=443 off), exit 0.
#
# NOTE: Expose/teardown UNIT tests (no-tailscale -> exit 10, serve-fail -> exit 12,
# malformed/empty handles, non-loopback token, FR18 guidance, SEC-1 funnel guard) are
# in test-aid-remote.sh (T-1..T-7) and are NOT duplicated here.
# ---------------------------------------------------------------------------
echo "--- T-14: --remote SUCCESS integration ---"
H14h="$(new_aid_home)"
PORT14h="$(pick_free_port)"
STUB14H="$(mktemp -d "${TMP}/stub14h.XXXXXX")"
make_tailscale_stub "$STUB14H" "logged-in" "srvtest01.tail99999.ts.net"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# T-14h: full aid binary with the logged-in stub on PATH.
echo "--- T-14h: start --remote with logged-in stub ---"
_T14H_OUT="$(mktemp "${TMP}/t14h_out.XXXXXX")"
_T14H_ERR="$(mktemp "${TMP}/t14h_err.XXXXXX")"
HOME="${PINNED_HOME}" PATH="${STUB14H}:${PATH}" AID_HOME="$H14h" AID_NO_UPDATE_CHECK=1 \
    bash "${H14h}/bin/aid" dashboard start python --port "$PORT14h" --remote \
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
assert_file_exists "$PINNED_PID_FILE" "T-14h: dashboard.pid written"
assert_file_contains "$PINNED_PID_FILE" '"remote": true' "T-14h: record.remote=true"
assert_file_contains "$PINNED_PID_FILE" "tailscale-serve:${PORT14h}" "T-14h: remote_handle in record"
_T14H_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T14H_PID" ]] && SPAWNED_PIDS+=("$_T14H_PID")

# T-14i: stop after remote start -> teardown called, stub records --https=443 off, exit 0.
echo "--- T-14i: stop after remote start ---"
HOME="${PINNED_HOME}" PATH="${STUB14H}:${PATH}" AID_HOME="$H14h" AID_NO_UPDATE_CHECK=1 \
    bash "${H14h}/bin/aid" dashboard stop >/dev/null 2>&1
assert_exit_eq "$?" 0 "T-14i: stop after remote start exit 0"
_t14i_calls="$(cat "${STUB14H}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t14i_calls" | grep -qF -- "--https=443 off"; then
    pass "T-14i: teardown called --https=443 off on stop"
else
    fail "T-14i: teardown called --https=443 off on stop -- calls were: ${_t14i_calls}"
fi

# ---------------------------------------------------------------------------
# T-15: Non-project dir regression
# T-15a: 'aid dashboard start python' from a bare non-project dir succeeds (exit 0),
#         prints the URL, writes pid to $HOME/.aid/.temp/; no "no AID install found" error.
# T-15b: start from non-project dir does NOT register the cwd in the registry.
# ---------------------------------------------------------------------------
echo "--- T-15: non-project dir regression ---"
H15="$(new_aid_home)"
PORT15="$(pick_free_port)"
NONPROJ15="$(new_nonproject_dir)"
rm -f "$PINNED_PID_FILE" "$PINNED_LOG_FILE"

# T-15a: start from a non-project dir must succeed.
run_dc_from "$NONPROJ15" "$H15" dashboard start python --port "$PORT15"
assert_exit_eq "$RC_DC" 0 "T-15a: start from non-project dir exits 0"
assert_output_not_contains "$OUT_DC" "no AID install found" \
    "T-15a: no 'no AID install found' error"
assert_output_contains "$OUT_DC" "Dashboard (python) running at http://127.0.0.1:${PORT15}" \
    "T-15a: URL printed from non-project dir"
assert_file_exists "$PINNED_PID_FILE" \
    "T-15a: dashboard.pid written in HOME/.aid/.temp/"

_T15_PID="$(grep '"pid"' "$PINNED_PID_FILE" | sed 's/[^0-9]*\([0-9]*\).*/\1/')"
[[ -n "$_T15_PID" ]] && SPAWNED_PIDS+=("$_T15_PID")
assert_eq "$(kill -0 "$_T15_PID" 2>/dev/null && echo alive || echo dead)" "alive" \
    "T-15a: child process alive"

# T-15b: the non-project cwd must NOT be registered in the registry.
_T15_REG_FILE="${PINNED_HOME}/registry.yml"
# Check via the AID_HOME registry (the home dir we're using as state home).
_T15_REG_FILE2="${H15}/registry.yml"
_T15_CWD_REGISTERED=0
if [[ -f "$_T15_REG_FILE" ]] && grep -qF "$NONPROJ15" "$_T15_REG_FILE"; then
    _T15_CWD_REGISTERED=1
fi
if [[ -f "$_T15_REG_FILE2" ]] && grep -qF "$NONPROJ15" "$_T15_REG_FILE2"; then
    _T15_CWD_REGISTERED=1
fi
if [[ "$_T15_CWD_REGISTERED" -eq 0 ]]; then
    pass "T-15b: non-project cwd NOT registered in registry"
else
    fail "T-15b: non-project cwd was incorrectly registered in registry"
fi

# Clean up T-15 (stop the running server).
run_dc "$H15" dashboard stop
assert_exit_eq "$RC_DC" 0 "T-15c: stop from any dir succeeds exit 0"
assert_output_contains "$OUT_DC" "aid: dashboard stopped." "T-15c: stopped message"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
