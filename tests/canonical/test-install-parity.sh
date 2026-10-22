#!/usr/bin/env bash
# test-install-parity.sh — Cross-platform static parity between install.sh and install.ps1.
#
# NOTE (legacy excision, tech-debt L3): install.sh/install.ps1's flag-style direct
# project-install path (--tool/-Tool, --target/-TargetDirectory, etc.) has been removed,
# so the PAR01-PAR12 scenarios that used to drive both installers through that path
# (fresh install per tool, idempotent re-install, protect-on-diff, --force, uninstall,
# auto-detect ambiguity, comma-list) have been retired along with it.  Cross-platform
# functional parity for the shared install/uninstall/manifest core logic
# (lib/aid-install-core.sh vs lib/AidInstallCore.psm1) is now exercised independently
# on each platform via tests/canonical/test-aid-cli.sh and test-aid-cli-ps1.sh (the
# `aid add`/`aid remove`/`aid update` subcommands), rather than via a single
# side-by-side diff in this file.
#
# Scenario covered:
#   PAR13 — Static: dashboard file enumeration is identical between install.sh and
#           install.ps1 (no installer invocation; source-text extraction only).
#   PAR14 -- Static (task-023): every install-core twin pair whose halves both live in
#           lib/ (aid-install-core.sh <-> AidInstallCore.psm1) is defined on both sides.
#
# SKIP (exit 0) when `pwsh` is absent, after the static PAR14 checks have run (exit 1
# if they failed) -- CI asserts pwsh IS present.
#
# Usage:
#   bash test-install-parity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT_SH="${REPO_ROOT}/install.sh"
SUT_PS1="${REPO_ROOT}/install.ps1"

[[ -f "$SUT_SH" ]]  || { echo "ERROR: install.sh not found at $SUT_SH" >&2; exit 1; }
[[ -f "$SUT_PS1" ]] || { echo "ERROR: install.ps1 not found at $SUT_PS1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# PAR14 (task-023) -- Static: every install-core twin pair whose two halves both live
# in the install core is DEFINED on both sides. Core = lib/aid-install-core.sh (which
# install.sh sources) and lib/AidInstallCore.psm1 (which install.ps1 loads). The pairs
# with a half in bin/aid or bin/aid.ps1 are guarded by the STATIC-TWIN check in
# test-aid-cli-parity.sh. Pair list kept here, in the suite (not in a work folder).
# Runs BEFORE the pwsh gate: source text only, no PowerShell needed.
# ---------------------------------------------------------------------------
CORE_SH="${REPO_ROOT}/lib/aid-install-core.sh"
CORE_PS1="${REPO_ROOT}/lib/AidInstallCore.psm1"
PAR14_PAIRS=(
    "read_kv_conf Read-AidKvConf"
    "fetch_artifact Fetch-AidArtifact"
    "extract_payload Expand-AidPayload"
    "copy_file_guarded Copy-AidFileGuarded"
    "trash_file Move-AidToTrash"
    "install_shared Install-AidShared"
    "install_tool Install-AidTool"
    "write_host_conf Write-AidHostConf"
    "manifest_write_v3 Write-AidManifestV3"
    "manifest_read_shared Read-AidManifestShared"
    "manifest_read_tool_files Read-AidManifestToolFiles"
    "manifest_read_host Read-AidManifestHost"
    "read_upgrade_recovery Read-AidUpgradeRecovery"
    "write_upgrade_recovery Write-AidUpgradeRecovery"
    "clear_upgrade_recovery Clear-AidUpgradeRecovery"
    "retire_v3_layout Invoke-RetireV3Layout"
    "_migrate_retired_layout Invoke-MigrateRetiredLayout"
    "_is_aid_owned_path Test-AidOwnedPath"
    "_repair_root_region Repair-AidRootRegion"
    "_ensure_claude_md_region Invoke-EnsureClaudeMdRegion"
    "_remove_claude_md_region Invoke-RemoveClaudeMdRegion"
    "prune_shared Invoke-PruneShared"
    "drift_report Get-AidDriftReport"
    "uninstall_tool Uninstall-AidTool"
    "detect_tool Detect-Tool"
    "_root_agent_file Get-RootAgentFile"
    "_copy_root_agent_file Copy-RootAgentFile"
    "_aid_gitignore_block Get-AidGitignoreBlock"
    "_aid_gitattributes_block Get-AidGitattributesBlock"
    "update_gitattributes Update-AidGitattributes"
    "_remove_gitattributes_block Remove-AidGitattributesBlock"
    "seed_settings_yml Initialize-AidSettingsFile"
    "_ensure_host_hooks Invoke-EnsureHostHooks"
    "_remove_host_hooks Invoke-RemoveHostHooks"
)
par14_bash_defined() { grep -Eq "^[[:space:]]*${1}[[:space:]]*\(\)" "$CORE_SH"; }
par14_ps_defined()   { grep -Eq "^[[:space:]]*function[[:space:]]+((script|global):)?${1}[[:space:]]*\{" "$CORE_PS1"; }
for _row in "${PAR14_PAIRS[@]}"; do
    read -r _bash_name _ps_name <<< "$_row"
    _b_ok=0; _p_ok=0
    par14_bash_defined "$_bash_name" && _b_ok=1
    par14_ps_defined "$_ps_name" && _p_ok=1
    if [[ $_b_ok -eq 1 && $_p_ok -eq 1 ]]; then
        pass "PAR14 ${_bash_name} <-> ${_ps_name}: both defined in the install core"
    else
        [[ $_b_ok -eq 1 ]] || fail "PAR14 ${_bash_name} <-> ${_ps_name}: bash twin '${_bash_name}' not defined in lib/aid-install-core.sh"
        [[ $_p_ok -eq 1 ]] || fail "PAR14 ${_bash_name} <-> ${_ps_name}: PowerShell twin '${_ps_name}' not defined in lib/AidInstallCore.psm1"
    fi
done

# ---------------------------------------------------------------------------
# Gate: skip when pwsh is absent (CI asserts it IS present so this never fires).
# ---------------------------------------------------------------------------
PWSH="$(detect_pwsh || true)"

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping install parity suite (needs PowerShell)."
    # PAR14 is host-independent: a failure there is a real failure even without pwsh.
    if [[ $FAIL -gt 0 ]]; then test_summary; exit 1; fi
    exit 0
fi

# ---------------------------------------------------------------------------
# PAR13 — Static: install.sh and install.ps1 provision the SAME dashboard file set.
#
# Since H1 (single-source dashboard/MANIFEST) neither installer inlines the file list --
# both DERIVE it from dashboard/MANIFEST. Cross-platform parity is therefore guaranteed by
# construction (one source), so the check is now: both installers reference the manifest,
# and the manifest carries home.html (the migration/provisioning source that must ship on
# every channel). test-dashboard-manifest.sh separately guards MANIFEST vs the curated tree.
#   a) install.sh derives its dashboard set from dashboard/MANIFEST.
#   b) install.ps1 derives its dashboard set from dashboard/MANIFEST.
#   c) home.html is present in dashboard/MANIFEST (so both channels ship it).
# Static check; runs without invoking either installer.
# ---------------------------------------------------------------------------
MANIFEST_FILE="${REPO_ROOT}/dashboard/MANIFEST"

if grep -qF "dashboard/MANIFEST" "$SUT_SH"; then
    pass "PAR13a install.sh derives its dashboard set from dashboard/MANIFEST"
else
    fail "PAR13a install.sh does NOT reference dashboard/MANIFEST (reverted to an inline list?)"
fi

if grep -qF "dashboard/MANIFEST" "$SUT_PS1"; then
    pass "PAR13b install.ps1 derives its dashboard set from dashboard/MANIFEST"
else
    fail "PAR13b install.ps1 does NOT reference dashboard/MANIFEST (reverted to an inline list?)"
fi

if grep -qxF "home.html" <(sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$MANIFEST_FILE" 2>/dev/null); then
    pass "PAR13c dashboard/MANIFEST lists home.html (ships on both sh + ps1 channels)"
else
    fail "PAR13c dashboard/MANIFEST does NOT list home.html — migration/provisioning source at risk"
fi

test_summary
