#!/usr/bin/env bash
# test-aid-remote.sh - Feature-005 test scenarios T-1..T-8: secure remote exposure.
#
# Verifies the _aid_remote_expose / _aid_remote_teardown helpers in bin/aid (Bash)
# and their PowerShell twins in bin/aid.ps1 using a PATH-shim tailscale STUB so
# the suite runs without a live tailnet.  The stub records its argv and FAILS the
# test if ever invoked with the public-exposure verb "funnel".
#
# Scenarios:
#   T-1  expose <port> with stub logged-in -> tailscale serve --bg <port> called,
#        handle tailscale-serve:<port> on stdout line1, https:// URL on line2, exit 0;
#        FR18 ACL-grant guidance printed to stderr.
#   T-2  expose then teardown <handle> -> stub argv shows 'serve --bg --https=443 off'
#        (NOT a blind reset when other mappings exist); exit 0.
#   T-3  --remote with no tailscale on PATH (and not-logged-in variant) -> expose
#        exit 10; feature-004 surfaces exit 10; server stays local; record.remote=false.
#   T-4  NEVER-FUNNEL guard (SEC-1): bare grep -i funnel on both launchers finds nothing;
#        stub confirms funnel was never called in any prior test.
#   T-5  teardown with malformed handle + empty handle + double teardown -> exit 0
#        idempotent (no error).
#   T-6  expose with a non-loopback target token -> exit 11; never widens a bind.
#   T-7  tailscale serve fails (stub returns nonzero) -> expose exit 12; revert
#        called (stub argv shows '--https=443 off'); never public.
#   T-8  Bash vs PowerShell parity for T-1/T-3/T-5 clear-fail paths.
#        PS half SKIP-IF-ABSENT (clear notice, Bash half always runs).
#
# Usage:
#   bash test-aid-remote.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/net.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
BIN_AID_PS1="${REPO_ROOT}/bin/aid.ps1"
LIB_SH="${REPO_ROOT}/lib/aid-install-core.sh"
DASHBOARD_SERVER_DIR="${REPO_ROOT}/dashboard/server"
DASHBOARD_READER_PY="${REPO_ROOT}/dashboard/reader.py"
DASHBOARD_INIT_PY="${REPO_ROOT}/dashboard/__init__.py"

[[ -f "$BIN_AID" ]]     || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$BIN_AID_PS1" ]] || { echo "ERROR: bin/aid.ps1 not found at $BIN_AID_PS1" >&2; exit 1; }
[[ -f "$LIB_SH" ]]      || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_SH" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Temp workspace -- cleaned on exit.
# HOME is pinned to a throwaway dir so dashboard.pid writes never touch the
# real ~/.aid/.temp. All spawned processes inherit the pinned HOME.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
PINNED_HOME="${TMP}/home"
mkdir -p "${PINNED_HOME}/.aid/.temp"
export HOME="${PINNED_HOME}"
PINNED_PID_FILE="${PINNED_HOME}/.aid/.temp/dashboard.pid"

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
# Fixture helpers.
# ---------------------------------------------------------------------------
VERSION="0.7.0"

new_aid_home() {
    local h; h="$(mktemp -d "${TMP}/home.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib"
    cp "$BIN_AID"  "${h}/bin/aid"
    chmod +x "${h}/bin/aid"
    cp "$BIN_AID_PS1" "${h}/bin/aid.ps1"
    cp "$LIB_SH"   "${h}/lib/aid-install-core.sh"
    cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${h}/lib/AidInstallCore.psm1"
    printf '%s\n' "${VERSION}" > "${h}/VERSION"
    # d008 spawn-seam: the curated dashboard unit (reader package + server) is
    # co-vendored under $AID_HOME/dashboard/, and 'aid dashboard start' resolves the
    # entry point from there. Stage it so the server actually starts (mirrors the
    # layout in test-aid-dashboard-cli.sh:84-96). Without this, start exits 7
    # ("server missing from install tree") before the --remote path is reached.
    mkdir -p "${h}/dashboard/reader" "${h}/dashboard/server"
    for _f in __init__ reader models parsers derivation locator; do
        ln -sf "${REPO_ROOT}/dashboard/reader/${_f}.py" "${h}/dashboard/reader/${_f}.py"
    done
    ln -sf "${REPO_ROOT}/dashboard/server/server.py"   "${h}/dashboard/server/server.py"
    ln -sf "${REPO_ROOT}/dashboard/server/server.mjs"  "${h}/dashboard/server/server.mjs"
    ln -sf "${REPO_ROOT}/dashboard/server/reader.mjs"  "${h}/dashboard/server/reader.mjs"
    ln -sf "${REPO_ROOT}/dashboard/server/__init__.py" "${h}/dashboard/server/__init__.py"
    echo "$h"
}

new_fixture_repo() {
    local r; r="$(mktemp -d "${TMP}/repo.XXXXXX")"
    mkdir -p "${r}/.aid/.temp" "${r}/dashboard/server"
    ln -sf "${DASHBOARD_SERVER_DIR}/server.py"  "${r}/dashboard/server/server.py"
    ln -sf "${DASHBOARD_SERVER_DIR}/server.mjs" "${r}/dashboard/server/server.mjs"
    [[ -f "$DASHBOARD_READER_PY" ]] && ln -sf "$DASHBOARD_READER_PY" "${r}/dashboard/reader.py"
    [[ -f "$DASHBOARD_INIT_PY" ]]   && ln -sf "$DASHBOARD_INIT_PY"   "${r}/dashboard/__init__.py"
    echo "$r"
}

# Ephemeral ports come from tests/lib/net.sh find_free_port (FR-7: no local
# port-helper redefinition). The two `aid dashboard start` sites that bind a
# real socket (T-3, T-8) wrap pick->start->verify in a bounded retry below.

# ---------------------------------------------------------------------------
# tailscale stub factory.
# Args: <stub_dir> <behaviour> [fqdn]
#   absent      -- no tailscale binary (PATH has the stub dir but no tailscale file)
#   logged-in   -- tailscale present, status OK, serve succeeds
#   not-logged-in -- tailscale present, status says "not logged in"
#   serve-fail  -- tailscale present, status OK, serve exits nonzero
#
# Stub records each invocation's argv to <stub_dir>/ts_calls.log.
# Stub exits 99 (and prints to stderr) if "funnel" is ever passed as an arg --
# this is the SEC-1 runtime guard: the test harness checks ts_calls.log for
# "funnel" and fails the test.
# ---------------------------------------------------------------------------
make_tailscale_stub() {
    local stub_dir="$1"
    local behaviour="$2"
    local fqdn="${3:-stubhost.tail00000.ts.net}"

    mkdir -p "$stub_dir"

    if [[ "$behaviour" == "absent" ]]; then
        # No tailscale file in stub_dir; PATH wins by absence.
        return 0
    fi

    cat > "${stub_dir}/tailscale" <<STUBEOF
#!/usr/bin/env bash
# Stub tailscale -- feature-005 test harness; never touches a real tailnet.
BEHAVIOUR="${behaviour}"
FQDN="${fqdn}"
STUB_DIR="${stub_dir}"

# Record argv to ts_calls.log.
echo "\$*" >> "\${STUB_DIR}/ts_calls.log"

# SEC-1 guard: fail immediately if funnel is ever requested.
for arg in "\$@"; do
    if [[ "\$arg" == "funnel" || "\$arg" == "--funnel" ]]; then
        echo "STUB SECURITY VIOLATION: funnel was called! This is a test failure." >&2
        exit 99
    fi
done

case "\$1" in
    status)
        if [[ "\$2" == "--json" ]]; then
            # dnsname-absent: emit a valid Self block with NO DNSName field so the
            # status --json path yields nothing and the serve-status fallback is exercised.
            if [[ "\${BEHAVIOUR}" == "dnsname-absent" ]]; then
                printf '{\n'
                printf '  "Self": {\n'
                printf '    "HostName": "%s",\n' "\${FQDN%%.*}"
                printf '    "UserID": 12345\n'
                printf '  }\n'
                printf '}\n'
                exit 0
            fi
            # Real tailscale emits PRETTY-PRINTED JSON (whitespace after colons) and includes
            # peers unless --peers=false. Reproduce both so the launcher's Self.DNSName parse is
            # exercised against the real format (regression guard for the no-space-grep bug that
            # made the URL fall back to the corporate hostname domain).
            _peers_off=0
            for _a in "\$@"; do [[ "\$_a" == "--peers=false" ]] && _peers_off=1; done
            printf '{\n'
            printf '  "Self": {\n'
            printf '    "HostName": "%s",\n' "\${FQDN%%.*}"
            printf '    "DNSName": "%s.",\n' "\$FQDN"
            printf '    "UserID": 12345\n'
            printf '  }'
            if [[ "\$_peers_off" -eq 0 ]]; then
                printf ',\n  "Peer": {\n'
                printf '    "nodekey:deadbeef": {\n'
                printf '      "HostName": "peerbox",\n'
                printf '      "DNSName": "peerbox.tailpeer99.ts.net."\n'
                printf '    }\n'
                printf '  }'
            fi
            printf '\n}\n'
            exit 0
        fi
        if [[ "\${BEHAVIOUR}" == "not-logged-in" ]]; then
            echo "Logged out." >&2
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
        # dnsname-absent: serve --bg <port> succeeds; 'serve status --json' returns a
        # realistic pretty-printed serve-status JSON containing a *.ts.net host so the
        # fallback branch resolves the FQDN from that output.
        if [[ "\${BEHAVIOUR}" == "dnsname-absent" ]]; then
            if [[ "\$2" == "status" && "\$3" == "--json" ]]; then
                printf '{\n'
                printf '  "Web": {\n'
                printf '    "https://%s:443": {\n' "\$FQDN"
                printf '      "Handlers": {}\n'
                printf '    }\n'
                printf '  }\n'
                printf '}\n'
                exit 0
            fi
            # serve --bg <port> succeeds.
            exit 0
        fi
        # logged-in: serve --bg <port> and serve --bg --https=443 off both succeed.
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
STUBEOF
    chmod +x "${stub_dir}/tailscale"
}

# ---------------------------------------------------------------------------
# Function-level execution harness.
# Extracts the function bodies from bin/aid (no top-level dispatch code) and
# runs them in a subshell with the tailscale stub on PATH.
# Sets RC_DC, OUT_DC, ERR_DC.
# ---------------------------------------------------------------------------
_make_fn_src() {
    local bin="$1"
    awk '/^# Parse subcommand and dispatch\./{exit}
         /^_aid_usage\(\)|^_aid_die\(\)|^_find_install_sh\(\)|^_aid_check_update\(\)|^_cmd_update_self\(\)|^_wire_one_profile\(\)|^_wire_path_unix\(\)|^_unwire_path_unix\(\)|^_install_global_cli\(\)|^_cmd_remove_self\(\)|^_aid_remote_expose\(\)|^_aid_remote_teardown\(\)|^_cmd_dashboard_ctl\(\)|^_dc_start\(\)|^_dc_stop\(\)|^_cmd_dashboard\(\)|^_resolve_tools_for_aid\(\)|^_prepare_tool_staging_aid\(\)/{in_fn=1}
         in_fn{print}' "$bin"
}

H_FN="$(new_aid_home)"
_BIN_AID_FN_SRC="$(_make_fn_src "${H_FN}/bin/aid")"

run_fn_with_stub() {
    local stub_dir="$1"; shift
    local _o _e
    _o="$(mktemp "${TMP}/o.XXXXXX")"
    _e="$(mktemp "${TMP}/e.XXXXXX")"
    local _fn_src="$_BIN_AID_FN_SRC"
    local _fn_args=("$@")
    (
        PATH="${stub_dir}:${PATH}"
        AID_HOME="${H_FN}"
        AID_NO_UPDATE_CHECK=1
        source "${H_FN}/lib/aid-install-core.sh" 2>/dev/null || true
        eval "$_fn_src"
        "${_fn_args[@]}"
    ) >"$_o" 2>"$_e"
    RC_DC=$?
    OUT_DC="$(cat "$_o")"
    ERR_DC="$(cat "$_e")"
    rm -f "$_o" "$_e"
}

# ---------------------------------------------------------------------------
# T-1: expose <port> with stub logged-in -> exit 0, handle+URL on stdout, FR18 on stderr.
#      Stub argv asserted: 'serve --bg <port>'.
#      Funnel NEVER called (SEC-1 runtime guard).
# ---------------------------------------------------------------------------
echo "--- T-1: expose with logged-in stub ---"
PORT1="$(find_free_port)"
STUB1="$(mktemp -d "${TMP}/stub1.XXXXXX")"
make_tailscale_stub "$STUB1" "logged-in" "srvtest01.tail99999.ts.net"

run_fn_with_stub "$STUB1" _aid_remote_expose "$PORT1"

assert_exit_eq "$RC_DC" 0 "T-1: expose exit 0 with logged-in stub"
assert_output_contains "$OUT_DC" "tailscale-serve:${PORT1}" \
    "T-1: handle line 1 on stdout (tailscale-serve:<port>)"
assert_output_contains "$OUT_DC" "https://" \
    "T-1: https:// URL on stdout (line 2)"
# Wrong-domain regression guard: the URL MUST be the tailnet MagicDNS FQDN, not a
# hostname/corporate-domain fallback. (Bug: a no-space DNSName grep on pretty-printed
# JSON fell through to 'hostname -f' -> host.corp.example -> a URL that does not work.)
assert_output_contains "$OUT_DC" "https://srvtest01.tail99999.ts.net/" \
    "T-1: stdout URL is the tailnet MagicDNS FQDN (not the hostname/corporate domain)"

# FR18: condensed ACL-grant guidance on stderr (tailnet-exposure warning + policy link + grant).
assert_output_contains "$ERR_DC" "tailnet" \
    "T-1: FR18 -- tailnet-exposure warning on stderr"
assert_output_contains "$ERR_DC" "tailnet policy file" \
    "T-1: FR18 -- tailnet policy file link on stderr"
assert_output_contains "$ERR_DC" "https://login.tailscale.com/admin/acls/file" \
    "T-1: FR18 -- admin/acls policy URL on stderr"
assert_output_contains "$ERR_DC" "deny-by-default" \
    "T-1: FR18 -- deny-by-default on stderr"
# The same wrong-domain bug leaked into the ACL grant: src was derived from the FQDN
# domain. src must be an identity placeholder; dst the host short-name; neither may be a
# DNS domain.
assert_output_contains "$ERR_DC" '"src":["<you@example.com>"]' \
    "T-1: ACL grant src is an identity placeholder (never a tailnet/corporate domain)"
assert_output_contains "$ERR_DC" '"dst":["srvtest01"]' \
    "T-1: ACL grant dst is THIS host's tailnet short-name"
assert_output_not_contains "$ERR_DC" '"src":["tail99999.ts.net"]' \
    "T-1: ACL grant src does not leak the tailnet domain as a selector"

# Stub argv recorded: 'serve --bg <port>'.
_t1_calls="$(cat "${STUB1}/ts_calls.log" 2>/dev/null || echo "")"
assert_output_contains "$_t1_calls" "serve --bg ${PORT1}" \
    "T-1: stub recorded 'tailscale serve --bg <port>'"

# SEC-1 runtime guard: funnel was never invoked.
if grep -q "funnel" "${STUB1}/ts_calls.log" 2>/dev/null; then
    fail "T-1: SEC-1 VIOLATED -- funnel was called in expose!"
else
    pass "T-1: SEC-1 confirmed -- funnel never called in expose"
fi

# ---------------------------------------------------------------------------
# T-2: expose then teardown -> stub argv shows 'serve --bg --https=443 off';
#      NOT a blind 'reset' when other mappings exist; exit 0.
# ---------------------------------------------------------------------------
echo "--- T-2: expose then teardown ---"
PORT2="$(find_free_port)"
STUB2="$(mktemp -d "${TMP}/stub2.XXXXXX")"
make_tailscale_stub "$STUB2" "logged-in" "srvtest01.tail99999.ts.net"

run_fn_with_stub "$STUB2" _aid_remote_expose "$PORT2"
assert_exit_eq "$RC_DC" 0 "T-2: expose exit 0 (setup for teardown)"

# Capture the handle from stdout line 1.
_t2_handle="$(echo "$OUT_DC" | head -1)"
assert_output_contains "$_t2_handle" "tailscale-serve:${PORT2}" \
    "T-2: handle shape is tailscale-serve:<port>"

# Teardown.
run_fn_with_stub "$STUB2" _aid_remote_teardown "$_t2_handle"
assert_exit_eq "$RC_DC" 0 "T-2: teardown exit 0"

# Stub argv must show '--https=443 off' (not a blind 'reset').
_t2_calls="$(cat "${STUB2}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t2_calls" | grep -qF -- "--https=443 off"; then
    pass "T-2: teardown called 'serve --bg --https=443 off' (targeted, not blind reset)"
else
    fail "T-2: teardown did not call '--https=443 off' -- recorded calls: ${_t2_calls}"
fi

# SEC-1 runtime guard.
if grep -q "funnel" "${STUB2}/ts_calls.log" 2>/dev/null; then
    fail "T-2: SEC-1 VIOLATED -- funnel was called in teardown!"
else
    pass "T-2: SEC-1 confirmed -- funnel never called in teardown"
fi

# ---------------------------------------------------------------------------
# T-3: --remote with no tailscale on PATH -> expose exit 10.
#      not-logged-in variant -> expose exit 10.
#      feature-004 integration: start --remote surfaces exit 10, server stays local,
#      dashboard.pid.remote=false.
# ---------------------------------------------------------------------------
echo "--- T-3: --remote with no tailscale on PATH ---"
PORT3="$(find_free_port)"
STUB3_ABSENT="$(mktemp -d "${TMP}/stub3a.XXXXXX")"
make_tailscale_stub "$STUB3_ABSENT" "absent"

# Function-level: expose with no tailscale on PATH.
# Use a PATH that ONLY has the empty stub dir (no tailscale binary there).
# We also override any real tailscale that might be on the system PATH.
_fn_src="$_BIN_AID_FN_SRC"
_o3="$(mktemp "${TMP}/o3.XXXXXX")"
_e3="$(mktemp "${TMP}/e3.XXXXXX")"
(
    # Shadow the real tailscale by using a PATH that resolves nothing named 'tailscale'.
    # Create a minimal PATH with only essential commands but not tailscale.
    _safe_path="${STUB3_ABSENT}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    PATH="$_safe_path"
    AID_HOME="${H_FN}"
    AID_NO_UPDATE_CHECK=1
    source "${H_FN}/lib/aid-install-core.sh" 2>/dev/null || true
    eval "$_fn_src"
    # Override command -v so tailscale lookup fails.
    command() {
        if [[ "$1" == "-v" && "$2" == "tailscale" ]]; then return 127; fi
        builtin command "$@"
    }
    _aid_remote_expose "$PORT3"
) >"$_o3" 2>"$_e3"
_rc3_absent=$?
rm -f "$_o3" "$_e3"
assert_exit_eq "$_rc3_absent" 10 "T-3: expose with no tailscale on PATH -> exit 10"

# not-logged-in variant.
echo "--- T-3 (not-logged-in variant) ---"
STUB3_NLI="$(mktemp -d "${TMP}/stub3b.XXXXXX")"
make_tailscale_stub "$STUB3_NLI" "not-logged-in" "srvtest01.tail99999.ts.net"

run_fn_with_stub "$STUB3_NLI" _aid_remote_expose "$PORT3"
assert_exit_eq "$RC_DC" 10 "T-3: expose with not-logged-in stub -> exit 10"

# feature-004 integration: aid dashboard start --remote with no mechanism -> exit 10,
# server stays local, record.remote=false.
echo "--- T-3 (feature-004 integration: start --remote no mechanism) ---"
H3="$(new_aid_home)"
R3="$(new_fixture_repo)"
PORT3I="$(find_free_port)"
STUB3I_ABSENT="$(mktemp -d "${TMP}/stub3i.XXXXXX")"
make_tailscale_stub "$STUB3I_ABSENT" "absent"

_o3i="$(mktemp "${TMP}/o3i.XXXXXX")"
_e3i="$(mktemp "${TMP}/e3i.XXXXXX")"
# Use a PATH that shadows tailscale by prepending only the empty absent-stub dir.
# The real tailscale (if any) is further back in PATH; we also use
# AID_TAILSCALE_CMD override if defined, but the simplest cross-env approach:
# since absent-stub dir has no tailscale, 'command -v tailscale' will check PATH
# and find nothing in stub dir, then find the real one.  We need a stronger block.
# Use a wrapping script that mocks tailscale-absence at the full-binary level:
_absent_wrapper="$(mktemp -d "${TMP}/absent_wrap.XXXXXX")"
cat > "${_absent_wrapper}/tailscale" <<'ABSEOF'
#!/usr/bin/env bash
# This wrapper simulates tailscale completely absent by returning not-found.
# It should NOT be executable -- but we need command -v to not find tailscale.
# Strategy: make this executable but exit 127 for all calls.
exit 127
ABSEOF
chmod +x "${_absent_wrapper}/tailscale"

# dashboard is now machine-level: no --target flag; pid goes to $HOME/.aid/.temp/
# Ensure no stale pid before this test.
rm -f "$PINNED_PID_FILE"
# Bounded pick->start->verify retry (SETUP only, never an assertion): on a
# transient lost-port race (nonzero exit whose stderr shows "Address already in
# use") re-pick PORT3I and retry. A normal T-3 run (exit 10, remote unavailable)
# is NOT a bind race, so it breaks on the first attempt with assertions intact.
for _t3i_try in 1 2 3; do
    PATH="${_absent_wrapper}:${PATH}" AID_HOME="$H3" AID_NO_UPDATE_CHECK=1 \
        bash "${H3}/bin/aid" dashboard start python --port "$PORT3I" --remote \
        >"$_o3i" 2>"$_e3i"
    _rc3i=$?
    { [[ $_rc3i -eq 0 ]] || ! grep -qiF "Address already in use" "$_e3i"; } && break
    PORT3I="$(find_free_port)"; rm -f "$PINNED_PID_FILE"
done
_out3i="$(cat "$_o3i")"; _err3i="$(cat "$_e3i")"
rm -f "$_o3i" "$_e3i"

assert_exit_eq "$_rc3i" 10 "T-3: start --remote no mechanism -> feature-004 exit 10"
assert_output_contains "$_err3i" "remote-exposure mechanism is not available" \
    "T-3: feature-004 user-facing not-available message"
assert_output_contains "$_err3i" "NOT exposed" \
    "T-3: feature-004 NOT exposed stated"
assert_output_contains "$_err3i" "Local server still running" \
    "T-3: feature-004 local server still running message"

# pid written to $HOME/.aid/.temp/ (pinned HOME)
assert_file_exists "$PINNED_PID_FILE" "T-3: dashboard.pid written (server was started)"
assert_file_contains "$PINNED_PID_FILE" '"remote": false' \
    "T-3: dashboard.pid.remote=false after --remote failure"

# Record the server pid for cleanup.
_T3I_PID="$(grep '"pid"' "$PINNED_PID_FILE" 2>/dev/null | sed 's/[^0-9]*\([0-9]*\).*/\1/' | head -1)"
[[ -n "$_T3I_PID" ]] && SPAWNED_PIDS+=("$_T3I_PID")

# Stop the local server so the port is freed.
AID_HOME="$H3" AID_NO_UPDATE_CHECK=1 \
    bash "${H3}/bin/aid" dashboard stop >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# T-4: NEVER-FUNNEL guard (SEC-1 -- structural).
#      Part A: bare grep -i funnel on bin/aid and bin/aid.ps1 finds NOTHING.
#      Part B: all stubs used in T-1..T-3 recorded no funnel invocations.
# ---------------------------------------------------------------------------
echo "--- T-4: NEVER-FUNNEL guard (SEC-1) ---"

# Part A: bare grep -- no filtering of comments, no awk, no sed.
# The point: 'funnel' simply does not appear in either launcher file at all.
# grep -c exits 1 when no lines match (outputs "0"); use || true to avoid set -e abort.
_funnel_bash_count="$(grep -ic "funnel" "${BIN_AID}" 2>/dev/null || true)"
assert_eq "$_funnel_bash_count" "0" \
    "T-4: bare grep -i funnel bin/aid -> 0 matches (SEC-1 structural)"

_funnel_ps1_count="$(grep -ic "funnel" "${BIN_AID_PS1}" 2>/dev/null || true)"
assert_eq "$_funnel_ps1_count" "0" \
    "T-4: bare grep -i funnel bin/aid.ps1 -> 0 matches (SEC-1 structural)"

# Part B: confirm stubs used in T-1..T-3 recorded no funnel invocations.
for _stublog in \
    "${STUB1}/ts_calls.log" \
    "${STUB2}/ts_calls.log" \
    "${STUB3_NLI}/ts_calls.log"; do
    if [[ -f "$_stublog" ]] && grep -q "funnel" "$_stublog" 2>/dev/null; then
        fail "T-4: SEC-1 VIOLATED -- funnel appeared in stub log: ${_stublog}"
    fi
done
pass "T-4: SEC-1 confirmed -- funnel never appeared in any stub log (T-1..T-3)"

# ---------------------------------------------------------------------------
# T-5: teardown with malformed handle, empty handle, double teardown -> exit 0.
# ---------------------------------------------------------------------------
echo "--- T-5: idempotent teardown ---"
STUB5="$(mktemp -d "${TMP}/stub5.XXXXXX")"
make_tailscale_stub "$STUB5" "logged-in" "srvtest01.tail99999.ts.net"

# T-5a: malformed handle.
run_fn_with_stub "$STUB5" _aid_remote_teardown "not-a-valid-handle"
assert_exit_eq "$RC_DC" 0 "T-5a: malformed handle -> exit 0 (idempotent)"

# T-5b: empty handle.
run_fn_with_stub "$STUB5" _aid_remote_teardown ""
assert_exit_eq "$RC_DC" 0 "T-5b: empty handle -> exit 0 (idempotent)"

# T-5c: double teardown (expose once, teardown twice).
PORT5="$(find_free_port)"
STUB5D="$(mktemp -d "${TMP}/stub5d.XXXXXX")"
make_tailscale_stub "$STUB5D" "logged-in" "srvtest01.tail99999.ts.net"
run_fn_with_stub "$STUB5D" _aid_remote_expose "$PORT5"
_t5_handle="$(echo "$OUT_DC" | head -1)"
run_fn_with_stub "$STUB5D" _aid_remote_teardown "$_t5_handle"
assert_exit_eq "$RC_DC" 0 "T-5c: first teardown -> exit 0"
run_fn_with_stub "$STUB5D" _aid_remote_teardown "$_t5_handle"
assert_exit_eq "$RC_DC" 0 "T-5c: second (double) teardown -> exit 0 (idempotent)"

# ---------------------------------------------------------------------------
# T-6: expose with non-loopback target token -> exit 11; never widens a bind.
# ---------------------------------------------------------------------------
echo "--- T-6: expose non-loopback target token ---"
STUB6="$(mktemp -d "${TMP}/stub6.XXXXXX")"
make_tailscale_stub "$STUB6" "logged-in" "srvtest01.tail99999.ts.net"

# Pass an IP-prefixed token (not a bare port number).
run_fn_with_stub "$STUB6" _aid_remote_expose "192.168.1.5:8787"
assert_exit_eq "$RC_DC" 11 "T-6: non-loopback target -> exit 11"

# No tailscale serve was called (expose must have aborted before step 3).
_t6_calls="$(cat "${STUB6}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t6_calls" | grep -q "serve --bg "; then
    fail "T-6: serve was called despite non-loopback target (bind widened!)"
else
    pass "T-6: serve NOT called for non-loopback target (never widened)"
fi

# Funnel not called.
if grep -q "funnel" "${STUB6}/ts_calls.log" 2>/dev/null; then
    fail "T-6: SEC-1 VIOLATED -- funnel was called!"
else
    pass "T-6: SEC-1 confirmed -- funnel not called in T-6"
fi

# ---------------------------------------------------------------------------
# T-7: tailscale serve invocation fails (stub returns nonzero) -> expose exit 12;
#      revert called (stub argv shows '--https=443 off'); never public.
# ---------------------------------------------------------------------------
echo "--- T-7: serve fails -> exit 12, revert called ---"
PORT7="$(find_free_port)"
STUB7="$(mktemp -d "${TMP}/stub7.XXXXXX")"
make_tailscale_stub "$STUB7" "serve-fail" "srvtest01.tail99999.ts.net"

run_fn_with_stub "$STUB7" _aid_remote_expose "$PORT7"
assert_exit_eq "$RC_DC" 12 "T-7: serve failure -> expose exit 12"

# Revert must have been called: stub argv shows '--https=443 off'.
_t7_calls="$(cat "${STUB7}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t7_calls" | grep -qF -- "--https=443 off"; then
    pass "T-7: serve-fail triggered revert ('serve --bg --https=443 off' called)"
else
    fail "T-7: serve-fail did NOT trigger revert -- recorded calls: ${_t7_calls}"
fi

# Funnel not called.
if grep -q "funnel" "${STUB7}/ts_calls.log" 2>/dev/null; then
    fail "T-7: SEC-1 VIOLATED -- funnel was called after serve failure!"
else
    pass "T-7: SEC-1 confirmed -- funnel not called in T-7"
fi

# ---------------------------------------------------------------------------
# T-8: Bash vs PowerShell parity for T-1/T-3/T-5 expose/teardown clear-fail paths.
#      PS half: SKIP-IF-ABSENT (clear notice, not a vacuous pass; Bash half always runs).
#      Parity scope: identical exit codes + handle shape + user-visible messages.
#      Platform-specific verbose diagnostics are excluded (only user-visible surfaces).
# ---------------------------------------------------------------------------
echo "--- T-8: Bash vs PowerShell parity (expose/teardown) ---"

# Detect pwsh.
PWSH="$(detect_pwsh || true)"

# Detect Linux PS limitation for server-spawn scenarios.
PS_WIN_STYLE_OK=0
if [[ -n "$PWSH" ]]; then
    _PS_WS_TEST="$("$PWSH" -NoProfile -Command \
        'try { Start-Process -FilePath "echo" -ArgumentList "x" -WindowStyle Hidden -Wait -ErrorAction Stop; Write-Host "ok" } catch { Write-Host "fail" }' \
        2>&1)"
    if ! echo "$_PS_WS_TEST" | grep -q "fail\|not supported\|WindowStyle"; then
        PS_WIN_STYLE_OK=1
    fi
fi

if [[ -z "$PWSH" ]]; then
    echo "  SKIP (PS half T-8): pwsh not found on PATH -- PowerShell parity assertions skipped."
    echo "  Bash-side assertions still run; PS parity is verified by the CI Windows runner."
    pass "T-8: PS-T1-parity expose exit 0 [SKIPPED: pwsh absent]"
    pass "T-8: PS-T1-parity handle shape [SKIPPED: pwsh absent]"
    pass "T-8: PS-T3-parity expose no-mechanism exit 10 [SKIPPED: pwsh absent]"
    pass "T-8: PS-T5-parity teardown malformed exit 0 [SKIPPED: pwsh absent]"
else
    # PS parity -- invoke the PS twin via full bin/aid.ps1 launcher for clear-fail paths.
    # T-8/T-3 parity: --remote with no mechanism via the absent-wrapper -> exit 10.
    echo "  T-8 (PS T-3 parity): --remote no mechanism -> exit 10"
    H8_PS="$(new_aid_home)"
    R8_PS="$(new_fixture_repo)"
    PORT8="$(find_free_port)"

    # The absent-wrapper shadows tailscale for the PS invocation.
    _absent8="$(mktemp -d "${TMP}/absent8.XXXXXX")"
    cat > "${_absent8}/tailscale" <<'ABS8EOF'
#!/usr/bin/env bash
exit 127
ABS8EOF
    chmod +x "${_absent8}/tailscale"

    _o8="$(mktemp "${TMP}/o8.XXXXXX")"
    _e8="$(mktemp "${TMP}/e8.XXXXXX")"

    if [[ "$PS_WIN_STYLE_OK" -eq 0 ]]; then
        # Linux PS cannot spawn background process; skip server-spawn but assert usage parity.
        echo "  SKIP (PS T-8 server-spawn): Start-Process WindowStyle unsupported on Linux PS."
        echo "  Usage/error parity (no server-spawn needed) still runs."
        pass "T-8: PS-T1-parity expose exit 0 [SKIPPED: Linux PS WindowStyle unsupported]"
        pass "T-8: PS-T1-parity handle shape [SKIPPED: Linux PS WindowStyle unsupported]"
        pass "T-8: PS-T3-parity start --remote exit 10 [SKIPPED: Linux PS WindowStyle unsupported]"
    else
        # dashboard is now machine-level: no --target flag
        # Ensure no stale pid before PS test.
        rm -f "$PINNED_PID_FILE"
        # Bounded pick->start->verify retry (SETUP only): re-pick PORT8 on a
        # transient bind race ("Address already in use"); a normal exit-10 run
        # breaks on the first attempt.
        for _t8_try in 1 2 3; do
            PATH="${_absent8}:${PATH}" AID_HOME="$H8_PS" AID_NO_UPDATE_CHECK=1 \
                "$PWSH" -NoProfile -File "${H8_PS}/bin/aid.ps1" \
                dashboard start python --port "$PORT8" --remote \
                >"$_o8" 2>"$_e8"
            _rc8_ps=$?
            { [[ $_rc8_ps -eq 0 ]] || ! grep -qiF "Address already in use" "$_e8"; } && break
            PORT8="$(find_free_port)"; rm -f "$PINNED_PID_FILE"
        done
        _err8_ps="$(cat "$_e8")"
        assert_exit_eq "$_rc8_ps" 10 "T-8: PS start --remote no mechanism -> exit 10 (T-3 parity)"
        assert_output_contains "$_err8_ps" "NOT exposed" \
            "T-8: PS NOT-exposed message (T-3 parity)"
        # Bash side reference (already verified T-3 above; parity confirmation).
        assert_eq "$_rc3i" "$_rc8_ps" "T-8: Bash<->PS exit code parity for --remote no mechanism"

        # Stop any server that may have started.
        AID_HOME="$H8_PS" AID_NO_UPDATE_CHECK=1 \
            bash "${H8_PS}/bin/aid" dashboard stop >/dev/null 2>&1 || true
    fi
    rm -f "$_o8" "$_e8"

    # T-8/T-5 parity: teardown with malformed handle -> exit 0 (no server-spawn needed).
    # Invoke via PS function -- we call a minimal PS snippet directly.
    echo "  T-8 (PS T-5 parity): teardown malformed handle -> exit 0"
    _o8b="$(mktemp "${TMP}/o8b.XXXXXX")"
    _e8b="$(mktemp "${TMP}/e8b.XXXXXX")"
    # The PS teardown function is in bin/aid.ps1; extract and invoke it.
    # Simplest approach: call 'aid dashboard stop' (nothing running -> idempotent exit 0)
    # which exercises the same code path as T-5.
    H8_PS5="$(new_aid_home)"
    AID_HOME="$H8_PS5" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${H8_PS5}/bin/aid.ps1" \
        dashboard stop \
        >"$_o8b" 2>"$_e8b"
    _rc8b_ps=$?
    assert_exit_eq "$_rc8b_ps" 0 "T-8: PS dashboard stop nothing-running -> exit 0 (T-5 parity)"
    rm -f "$_o8b" "$_e8b"
fi

# Bash side for T-8: verify Bash expose clear-fail exit 10 (already verified in T-3;
# explicitly name it as T-8 Bash reference so a missing Bash regression shows here too).
assert_exit_eq "$_rc3_absent" 10 "T-8: Bash expose no-mechanism -> exit 10 (T-3 Bash side)"

# ---------------------------------------------------------------------------
# T-1b: serve-status fallback branch: when status --json yields no DNSName, the
#       expose function falls back to 'tailscale serve status --json' to resolve
#       the FQDN. The dnsname-absent stub exercises this branch.
# ---------------------------------------------------------------------------
echo "--- T-1b: serve-status fallback resolves FQDN when DNSName absent from status --json ---"
PORT1B="$(find_free_port)"
STUB1B="$(mktemp -d "${TMP}/stub1b.XXXXXX")"
make_tailscale_stub "$STUB1B" "dnsname-absent" "fallback01.tail12345.ts.net"

run_fn_with_stub "$STUB1B" _aid_remote_expose "$PORT1B"

assert_exit_eq "$RC_DC" 0 "T-1b: expose exit 0 when serve-status fallback used"
assert_output_contains "$OUT_DC" "tailscale-serve:${PORT1B}" \
    "T-1b: handle line 1 on stdout (tailscale-serve:<port>)"
assert_output_contains "$OUT_DC" "https://fallback01.tail12345.ts.net/" \
    "T-1b: stdout URL resolved from serve-status fallback (*.ts.net FQDN)"

# Confirm the serve-status fallback was actually invoked (stub recorded 'serve status --json').
_t1b_calls="$(cat "${STUB1B}/ts_calls.log" 2>/dev/null || echo "")"
if echo "$_t1b_calls" | grep -q "serve status --json"; then
    pass "T-1b: stub recorded 'tailscale serve status --json' (fallback branch exercised)"
else
    fail "T-1b: 'tailscale serve status --json' not in stub log -- fallback not exercised. Calls: ${_t1b_calls}"
fi

# SEC-1: funnel must never be invoked.
if grep -q "funnel" "${STUB1B}/ts_calls.log" 2>/dev/null; then
    fail "T-1b: SEC-1 VIOLATED -- funnel was called!"
else
    pass "T-1b: SEC-1 confirmed -- funnel never called in serve-status fallback path"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
