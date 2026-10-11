#!/usr/bin/env bash
# test-ps51-compat.sh - Guard: shipped PowerShell stays Windows PowerShell 5.1 compatible.
#
# The repo advertises "PowerShell 5.1+" (README, docs/install.md) and the shipped
# PS files declare "#Requires -Version 5.1". This suite runs an AST-based lint
# (ps51-compat-check.ps1) that fails on any PowerShell 6.0/7-only construct -
# 3-arg Join-Path, utf8NoBOM encoding, $IsWindows, web-calls-without-TLS12, etc.
#
# Why a custom lint and not PSScriptAnalyzer: PSSA's PSUseCompatible* rules
# silently MISS 3-arg Join-Path, utf8NoBOM, $IsWindows and 3-arg String.Replace
# (verified), so a PSSA-only gate gives false confidence. This catches them.
#
# NOTE: this is a STATIC lint. Runtime 5.1 behavior (BOM divergence, the actual
# TLS handshake, FileSystem-provider semantics) is covered by the real WinPS 5.1
# CI lane in .github/workflows/installer-tests.yml.
#
# Usage:  bash test-ps51-compat.sh [-v]
# Exit:   0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECK="$(dirname "${BASH_SOURCE[0]}")/ps51-compat-check.ps1"

# ---------------------------------------------------------------------------
# STATIC per-function check (task-023) -- runs BEFORE the pwsh gate, so the
# install-core PowerShell functions added by the shared layout are checked on
# every host. Each name below is a PowerShell twin from the install-core table in
# REQUIREMENTS.md section 11 Feature 001 > Layers & Components. For each one the body is
# extracted (definition line through its column-0 closing brace) from
# lib/AidInstallCore.psm1 or bin/aid.ps1, and the check fails on: the `??`
# operator, a ternary (a `?` outside strings and comments), `-AsHashtable`, or any
# non-ASCII byte. The AST lint below remains the authority; this is the host-independent
# guard that names the offending function.
# ---------------------------------------------------------------------------
PS51_LIB="${REPO_ROOT}/lib/AidInstallCore.psm1"
PS51_BIN="${REPO_ROOT}/bin/aid.ps1"
PS51_NEW_FUNCTIONS=(
    Read-AidKvConf Fetch-AidArtifact Expand-AidPayload Prepare-AidReleaseStaging
    Copy-AidFileGuarded Move-AidToTrash Install-AidShared Install-AidTool
    Write-AidHostConf Write-AidManifestV3 Read-AidManifestShared Read-AidManifestToolFiles
    Read-AidManifestHost Read-AidUpgradeRecovery Write-AidUpgradeRecovery Clear-AidUpgradeRecovery
    Invoke-RetireV3Layout Invoke-MigrateRetiredLayout Test-AidOwnedPath Repair-AidRootRegion
    Invoke-EnsureClaudeMdRegion Invoke-RemoveClaudeMdRegion Invoke-PruneShared Get-AidDriftReport
    Uninstall-AidTool Detect-Tool Get-RootAgentFile Copy-RootAgentFile Get-AidGitignoreBlock
    Get-AidGitattributesBlock Update-AidGitattributes Remove-AidGitattributesBlock
    Initialize-AidSettingsFile Test-AidLayoutGate Test-StagedVersion Invoke-AidScaffoldBareProject
)

# ps51_fn_body <name>: one function's source, from its definition to the first column-0 "}".
ps51_fn_body() {
    local f b body=""
    for f in "$PS51_LIB" "$PS51_BIN"; do
        b="$(awk -v name="$1" '
            on == 0 && $0 ~ ("^[[:space:]]*function[[:space:]]+((script|global):)?" name "[[:space:]]*\\{") { on = 1 }
            on == 1 { print; if ($0 ~ /^}/) exit }
        ' "$f")"
        [[ -n "$b" ]] && body="$b"
    done
    printf '%s\n' "$body"
}

# ps51_code_only: drop quoted strings and comments so only code remains.
ps51_code_only() { sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g' -e 's/#.*$//'; }

for _ps51_name in "${PS51_NEW_FUNCTIONS[@]}"; do
    _ps51_body="$(ps51_fn_body "$_ps51_name")"
    if [[ -z "$_ps51_body" ]]; then
        fail "PS51 ${_ps51_name}: PowerShell function not found in lib/AidInstallCore.psm1 or bin/aid.ps1"
        continue
    fi
    _ps51_bad=""
    grep -q -- '??' <<< "$_ps51_body" && _ps51_bad+=" '??' operator;"
    grep -q -- '-AsHashtable' <<< "$_ps51_body" && _ps51_bad+=" -AsHashtable;"
    ps51_code_only <<< "$_ps51_body" | grep -q '?' && _ps51_bad+=" ternary (a '?' outside strings and comments);"
    grep -qP '[^\x00-\x7F]' <<< "$_ps51_body" && _ps51_bad+=" non-ASCII byte;"
    if [[ -z "$_ps51_bad" ]]; then
        pass "PS51 ${_ps51_name}: no ?? operator, no ternary, no -AsHashtable, ASCII-only"
    else
        fail "PS51 ${_ps51_name}:${_ps51_bad}"
    fi
done

# Gate: skip when pwsh is absent (CI always has it; see the runtime-assert step).
PWSH="$(detect_pwsh || true)"
if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH - skipping WinPS 5.1 compatibility lint (needs PowerShell)."
    # The per-function static check above is host-independent: a failure there is a real failure.
    if [[ $FAIL -gt 0 ]]; then test_summary; exit 1; fi
    exit 0
fi

out="$("$PWSH" -NoProfile -File "$CHECK" "$REPO_ROOT" 2>&1)"
rc=$?

if [[ $rc -eq 0 ]]; then
    pass "shipped PowerShell is Windows PowerShell 5.1-compatible (AST lint)"
    [[ "$VERBOSE" -eq 1 ]] && echo "$out"
else
    fail "shipped PowerShell has WinPS 5.1 incompatibilities:"$'\n'"$out"
fi

test_summary
