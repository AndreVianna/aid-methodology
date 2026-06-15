#!/usr/bin/env bash
# test-self-commands.sh -- Channel-routing dry-run parity for `aid update self` and
# `aid remove self` across bash (bin/aid) and PowerShell (bin/aid.ps1).
#
# For each channel in {npm, pypi, curl/default} asserts that --dry-run prints the
# exact command string the shell WOULD run, prefixed with `+ `, then exits 0.
#
# Design notes:
#   - HOME is pinned to a throwaway so no migration scan can touch real repos.
#   - AID_HOME points at a writable throwaway dir so bash never injects `sudo`.
#   - AID_NO_UPDATE_CHECK=1 and AID_NO_MIGRATE=1 suppress background checks.
#   - PowerShell cases are SKIPPED when pwsh is absent (CI's Windows runner runs them).
#
# Usage:
#   bash tests/canonical/test-self-commands.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BIN_AID_SH="${REPO_ROOT}/bin/aid"
BIN_AID_PS1="${REPO_ROOT}/bin/aid.ps1"
LIB_SH="${REPO_ROOT}/lib/aid-install-core.sh"
LIB_PS1="${REPO_ROOT}/lib/AidInstallCore.psm1"

[[ -f "$BIN_AID_SH" ]]  || { echo "ERROR: bin/aid not found at $BIN_AID_SH" >&2; exit 1; }
[[ -f "$BIN_AID_PS1" ]] || { echo "ERROR: bin/aid.ps1 not found at $BIN_AID_PS1" >&2; exit 1; }
[[ -f "$LIB_SH" ]]      || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_SH" >&2; exit 1; }
[[ -f "$LIB_PS1" ]]     || { echo "ERROR: lib/AidInstallCore.psm1 not found at $LIB_PS1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Gate: detect pwsh
# ---------------------------------------------------------------------------
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi
HAS_PWSH=0
[[ -n "$PWSH" ]] && HAS_PWSH=1

# ---------------------------------------------------------------------------
# Isolated temp environment
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Pin HOME so migration scan never touches real repos.
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

# ---------------------------------------------------------------------------
# Build a minimal AID_HOME with a writable bin/ so bash never needs sudo.
# ---------------------------------------------------------------------------
setup_sh_home() {
    local d="$1"
    mkdir -p "${d}/bin" "${d}/lib"
    cp "${BIN_AID_SH}" "${d}/bin/aid"
    chmod +x "${d}/bin/aid"
    cp "${LIB_SH}" "${d}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${d}/VERSION"
}

setup_ps1_home() {
    local d="$1"
    mkdir -p "${d}/bin" "${d}/lib"
    cp "${BIN_AID_PS1}" "${d}/bin/aid.ps1"
    cp "${LIB_PS1}" "${d}/lib/AidInstallCore.psm1"
    printf '%s\n' "${VERSION}" > "${d}/VERSION"
}

# ---------------------------------------------------------------------------
# Runners
# ---------------------------------------------------------------------------
run_sh() {
    local home_dir="$1"; shift
    OUT=$(AID_HOME="$home_dir" \
          AID_LIB_PATH="${home_dir}/lib/aid-install-core.sh" \
          AID_NO_UPDATE_CHECK=1 \
          AID_NO_MIGRATE=1 \
          bash "${home_dir}/bin/aid" "$@" 2>&1); RC=$?
}

run_ps1() {
    local home_dir="$1"; shift
    OUT=$( AID_HOME="$home_dir" \
           AID_LIB_PATH="${home_dir}/lib/AidInstallCore.psm1" \
           AID_NO_UPDATE_CHECK=1 \
           AID_NO_MIGRATE=1 \
           "$PWSH" -NoProfile -File "${home_dir}/bin/aid.ps1" "$@" 2>&1 | \
           sed 's/\x1b\[[0-9;]*m//g' ); RC=$?
}

echo "=== test-self-commands: channel-routing dry-run parity ==="

# ===========================================================================
# SELF001 -- npm channel: update self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=npm \
      bash "${H}/bin/aid" update self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF001-SH01 bash: npm update self --dry-run exits 0"
# bash may prefix `sudo` when the npm global prefix is root-owned; match on the
# command body (without the `+ ` / `+ sudo ` decoration) so the test is portable.
assert_output_contains "$OUT" "npm install -g aid-installer@latest" \
    "SELF001-SH02 bash: npm update self --dry-run prints npm install command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF001-SH03 bash: npm update self --dry-run prints migration scan notice"

# ===========================================================================
# SELF002 -- npm channel: remove self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=npm \
      bash "${H}/bin/aid" remove self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF002-SH01 bash: npm remove self --dry-run exits 0"
# bash may prefix `sudo` when the npm global prefix is root-owned; match on the
# command body (without the `+ ` / `+ sudo ` decoration) so the test is portable.
assert_output_contains "$OUT" "npm uninstall -g aid-installer" \
    "SELF002-SH02 bash: npm remove self --dry-run prints npm uninstall command"

# ===========================================================================
# SELF003 -- pypi channel: update self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=pypi \
      bash "${H}/bin/aid" update self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF003-SH01 bash: pypi update self --dry-run exits 0"
assert_output_contains "$OUT" "+ pipx upgrade aid-installer" \
    "SELF003-SH02 bash: pypi update self --dry-run prints pipx upgrade command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF003-SH03 bash: pypi update self --dry-run prints migration scan notice"

# ===========================================================================
# SELF004 -- pypi channel: remove self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=pypi \
      bash "${H}/bin/aid" remove self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF004-SH01 bash: pypi remove self --dry-run exits 0"
assert_output_contains "$OUT" "+ pipx uninstall aid-installer" \
    "SELF004-SH02 bash: pypi remove self --dry-run prints pipx uninstall command"

# ===========================================================================
# SELF005 -- curl/default channel: update self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL="" \
      AID_INSTALL_URL="https://example.com/install.sh" \
      bash "${H}/bin/aid" update self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF005-SH01 bash: curl update self --dry-run exits 0"
assert_output_contains "$OUT" "+ curl -fsSL" \
    "SELF005-SH02 bash: curl update self --dry-run prints curl bootstrap command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF005-SH03 bash: curl update self --dry-run prints migration scan notice"

# ===========================================================================
# SELF006 -- curl/default channel: remove self --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL="" \
      bash "${H}/bin/aid" remove self --dry-run 2>&1); RC=$?

assert_exit_eq "$RC" 0 "SELF006-SH01 bash: curl remove self --dry-run exits 0"
assert_output_contains "$OUT" "+ rm -rf" \
    "SELF006-SH02 bash: curl remove self --dry-run prints rm command"

# ===========================================================================
# SELF007 -- update self: unknown flag exits 2 (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      bash "${H}/bin/aid" update self --bogus-flag 2>&1); RC=$?
assert_exit_eq "$RC" 2 "SELF007-SH01 bash: update self unknown flag exits 2"

# ===========================================================================
# SELF008 -- remove self: unknown flag exits 2 (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      bash "${H}/bin/aid" remove self --bogus-flag 2>&1); RC=$?
assert_exit_eq "$RC" 2 "SELF008-SH01 bash: remove self unknown flag exits 2"

# ===========================================================================
# SELF009 -- help text: `aid update -h` mentions --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      bash "${H}/bin/aid" update -h 2>&1); RC=$?
assert_exit_eq "$RC" 0 "SELF009-SH01 bash: update -h exits 0"
assert_output_contains "$OUT" "dry-run" \
    "SELF009-SH02 bash: update -h mentions dry-run"
assert_output_contains "$OUT" "from-bundle" \
    "SELF009-SH03 bash: update -h mentions from-bundle"

# ===========================================================================
# SELF010 -- help text: `aid remove -h` mentions --dry-run (bash)
# ===========================================================================
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_sh_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/aid-install-core.sh" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      bash "${H}/bin/aid" remove -h 2>&1); RC=$?
assert_exit_eq "$RC" 0 "SELF010-SH01 bash: remove -h exits 0"
assert_output_contains "$OUT" "dry-run" \
    "SELF010-SH02 bash: remove -h mentions dry-run"

# ===========================================================================
# PowerShell tests (SKIPPED when pwsh absent)
# ===========================================================================
if [[ "$HAS_PWSH" -eq 0 ]]; then
    echo "SKIP (pwsh absent): SELF-PS1 suite -- static ps1 verified; full run on CI Windows runner."
else

# SELF011 -- npm channel: update self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=npm \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" update self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF011-PS01 ps1: npm update self --dry-run exits 0"
assert_output_contains "$OUT" "+ npm install -g aid-installer@latest" \
    "SELF011-PS02 ps1: npm update self --dry-run prints npm install command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF011-PS03 ps1: npm update self --dry-run prints migration scan notice"

# SELF012 -- npm channel: remove self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=npm \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" remove self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF012-PS01 ps1: npm remove self --dry-run exits 0"
assert_output_contains "$OUT" "+ npm uninstall -g aid-installer" \
    "SELF012-PS02 ps1: npm remove self --dry-run prints npm uninstall command"

# SELF013 -- pypi channel: update self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=pypi \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" update self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF013-PS01 ps1: pypi update self --dry-run exits 0"
assert_output_contains "$OUT" "+ pipx upgrade aid-installer" \
    "SELF013-PS02 ps1: pypi update self --dry-run prints pipx upgrade command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF013-PS03 ps1: pypi update self --dry-run prints migration scan notice"

# SELF014 -- pypi channel: remove self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL=pypi \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" remove self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF014-PS01 ps1: pypi remove self --dry-run exits 0"
assert_output_contains "$OUT" "+ pipx uninstall aid-installer" \
    "SELF014-PS02 ps1: pypi remove self --dry-run prints pipx uninstall command"

# SELF015 -- curl/default channel: update self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL="" \
      AID_INSTALL_URL="https://example.com/install.ps1" \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" update self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF015-PS01 ps1: curl update self --dry-run exits 0"
assert_output_contains "$OUT" "+ irm" \
    "SELF015-PS02 ps1: curl update self --dry-run prints irm bootstrap command"
assert_output_contains "$OUT" "(then) migration scan" \
    "SELF015-PS03 ps1: curl update self --dry-run prints migration scan notice"

# SELF016 -- curl/default channel: remove self --dry-run (ps1)
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" \
      AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 \
      AID_NO_MIGRATE=1 \
      AID_INSTALL_CHANNEL="" \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" remove self --dry-run 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?

assert_exit_eq "$RC" 0 "SELF016-PS01 ps1: curl remove self --dry-run exits 0"
assert_output_contains "$OUT" "+ Remove-Item" \
    "SELF016-PS02 ps1: curl remove self --dry-run prints Remove-Item command"

# SELF017 -- ps1: help mentions -DryRun for update
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" update -h 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?
assert_exit_eq "$RC" 0 "SELF017-PS01 ps1: update -h exits 0"
assert_output_contains "$OUT" "DryRun" \
    "SELF017-PS02 ps1: update -h mentions DryRun"
assert_output_contains "$OUT" "FromBundle" \
    "SELF017-PS03 ps1: update -h mentions FromBundle"

# SELF018 -- ps1: help mentions -DryRun for remove
H=$(mktemp -d "${TMP}/home.XXXXXX")
setup_ps1_home "$H"

OUT=$(AID_HOME="$H" AID_LIB_PATH="${H}/lib/AidInstallCore.psm1" \
      AID_NO_UPDATE_CHECK=1 AID_NO_MIGRATE=1 \
      "$PWSH" -NoProfile -File "${H}/bin/aid.ps1" remove -h 2>&1 | \
      sed 's/\x1b\[[0-9;]*m//g'); RC=$?
assert_exit_eq "$RC" 0 "SELF018-PS01 ps1: remove -h exits 0"
assert_output_contains "$OUT" "DryRun" \
    "SELF018-PS02 ps1: remove -h mentions DryRun"

fi  # end HAS_PWSH block

test_summary
