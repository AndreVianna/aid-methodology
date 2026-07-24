#!/usr/bin/env bash
# test-install-ps1.sh — integration tests for install.ps1's own usage/mode-detection
# surface (usage errors, help, piped/scriptblock host-survival), the PowerShell mirror
# of test-install.sh.
#
# NOTE (legacy excision, tech-debt L3): install.ps1's flag-style direct project-install
# path (-Tool/-Update/-Uninstall/-TargetDirectory) has been removed.  Functional coverage
# of the shared install/uninstall/manifest/prune/root-agent-merge core logic
# (lib/AidInstallCore.psm1) that used to be driven through that legacy path now lives
# in tests/canonical/test-aid-cli-ps1.sh, which drives the same core logic through the
# persistent `aid` CLI's `add`/`remove`/`update` subcommands instead.
#
# Usage:
#   bash test-install-ps1.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/install.ps1"

[[ -f "$SUT" ]] || { echo "ERROR: install.ps1 not found at $SUT" >&2; exit 1; }

# Resolve pwsh via the shared helper (tests/lib/pwsh.sh), same as every other pwsh suite.
PWSH="$(detect_pwsh || true)"

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping install.ps1 suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }

# Helper: run install.ps1 and capture output + exit code.
# Usage: run_install [ps1-args...]
# ISOLATION: unset AID_LIB_PATH so a parent-exported Bash .sh path does not bleed into
# install.ps1 which expects a .psm1 module.  install.ps1 finds its sibling lib/AidInstallCore.psm1.
run_install() {
    OUT=$(env -u AID_LIB_PATH "$PWSH" -NoProfile -File "$SUT" "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
}

# ---------------------------------------------------------------------------
# IN01 – unknown parameter → exit 2 (usage error, FR9 parity with bash)
# ---------------------------------------------------------------------------
run_install -UnknownParam
assert_exit_eq "$RC" 2 "IN01 unknown parameter → exit 2"
assert_output_contains "$OUT" "unrecognized parameter" \
    "IN01b error message mentions 'unrecognized parameter'"
assert_output_contains "$OUT" "Usage" "IN01c usage printed on unrecognized parameter"

# ---------------------------------------------------------------------------
# IN02–IN05 – Removed legacy parameters now fall through to the
#         unknown-parameter / unknown-positional case → usage error, exit 2
#         (locks in the L3 excision: -Tool / -Update / -Uninstall /
#         -TargetDirectory are no longer recognized by install.ps1).
# ---------------------------------------------------------------------------
run_install -Tool codex
assert_exit_eq "$RC" 2 "IN02 -Tool codex (removed legacy param) → exit 2"

run_install -Update
assert_exit_eq "$RC" 2 "IN03 -Update (removed legacy param) → exit 2"

# -Uninstall (without "Cli") must NOT silently alias to -UninstallCli.
run_install -Uninstall
assert_exit_eq "$RC" 2 "IN04 -Uninstall (removed legacy param, must not alias -UninstallCli) → exit 2"
assert_output_contains "$OUT" "Uninstall" "IN04b error message names the rejected -Uninstall param"

T=$(newtarget)
run_install -TargetDirectory "$T"
assert_exit_eq "$RC" 2 "IN05 -TargetDirectory <dir> (removed legacy param) → exit 2"

# ---------------------------------------------------------------------------
# IN06 – Help flag exits 0.
# ---------------------------------------------------------------------------
run_install -Help
assert_exit_eq "$RC" 0 "IN06 -Help → exit 0"
assert_output_contains "$OUT" "Usage" "IN06b -Help prints Usage"

# ---------------------------------------------------------------------------
# IN33 – Host-survival (piped/iex mode): the key regression guard.
#
# When install.ps1 is run as a scriptblock (simulating `irm <url> | iex` or
# `& ([scriptblock]::Create(...))`), `exit` would normally kill the HOST
# session.  The fix routes all exits through script:Exit-Install which, in
# piped mode, sets $global:LASTEXITCODE and throws a sentinel exception that
# unwinds cleanly — the host session SURVIVES.
#
# Verifies:
#   IN33  success path: -UninstallCli -Force -NoPath exits 0, HOST-SURVIVED
#         printed, parent's exit 7 wins.  (-UninstallCli needs no bin/aid.ps1
#         resolution, so it exercises the same script:Exit-Install path
#         without requiring a CLI-bundle fixture.)
#   IN33b failure path: bad flag exits 2, HOST-SURVIVED printed, parent's exit 7 wins.
#   IN33c/f LASTEXITCODE from install is visible to caller after scriptblock returns.
#
# AID_HOME points at a throwaway, never-installed dir so -UninstallCli is a
# harmless no-op (nothing to remove; PATH never contains the throwaway bin dir
# so the PATH-unwiring branch is a no-op too even before -NoPath is considered).
# ---------------------------------------------------------------------------

# Scriptblock helper: invokes install.ps1 as a raw scriptblock (simulating iex).
# The parent pwsh session is the outer `pwsh -NoProfile -Command ...`.
# After the scriptblock returns, we write HOST-SURVIVED and exit 7.
# PARENT-EXIT must be 7 (parent's own exit) not the install code.
_run_scriptblock_host_test() {
    local extra_args="$1"   # extra install.ps1 args (quoted as PS literal)
    local extra_vars="$2"   # extra env-var assignments for env(...)
    local extra_env=""
    [[ -n "$extra_vars" ]] && extra_env="$extra_vars"

    # Write a small wrapper PS1 that runs the install scriptblock and reports results.
    local wrapper
    wrapper=$(cat <<PSEOF
\$ErrorActionPreference = 'Continue'
& ([scriptblock]::Create((Get-Content '${SUT}' -Raw))) ${extra_args} 2>&1
\$code = \$LASTEXITCODE
Write-Output "INSTALL-LASTEXITCODE=\$code"
Write-Output 'HOST-SURVIVED'
exit 7
PSEOF
)
    env $extra_env "$PWSH" -NoProfile -Command "$wrapper" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
}

_HS_HOME="${TMP}/hs-home"
_hs_out=$(_run_scriptblock_host_test \
    "-UninstallCli -Force -NoPath" \
    "AID_HOME=${_HS_HOME}")
_hs_parent_exit=$?

assert_exit_eq "$_hs_parent_exit" 7 \
    "IN33 host-survival success: parent exit 7 wins (install did NOT kill host)"
assert_output_contains "$_hs_out" "HOST-SURVIVED" \
    "IN33b host-survival success: HOST-SURVIVED printed after scriptblock returns"
assert_output_contains "$_hs_out" "INSTALL-LASTEXITCODE=0" \
    "IN33c host-survival success: install LASTEXITCODE=0 visible to caller"

# Failure path: bad flag → install exits 2, host still survives.
_hs_fail_out=$(_run_scriptblock_host_test \
    "-BadFlag" \
    "")
_hs_fail_parent=$?

assert_exit_eq "$_hs_fail_parent" 7 \
    "IN33d host-survival failure: parent exit 7 wins (bad-flag install did NOT kill host)"
assert_output_contains "$_hs_fail_out" "HOST-SURVIVED" \
    "IN33e host-survival failure: HOST-SURVIVED printed after bad-flag scriptblock returns"
assert_output_contains "$_hs_fail_out" "INSTALL-LASTEXITCODE=2" \
    "IN33f host-survival failure: install LASTEXITCODE=2 (usage error) visible to caller"

test_summary
