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
#
# SKIP (exit 0) when `pwsh` is absent — CI asserts pwsh IS present.
#
# Usage:
#   bash test-install-parity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT_SH="${REPO_ROOT}/install.sh"
SUT_PS1="${REPO_ROOT}/install.ps1"

[[ -f "$SUT_SH" ]]  || { echo "ERROR: install.sh not found at $SUT_SH" >&2; exit 1; }
[[ -f "$SUT_PS1" ]] || { echo "ERROR: install.ps1 not found at $SUT_PS1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Gate: skip when pwsh is absent (CI asserts it IS present so this never fires).
# ---------------------------------------------------------------------------
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping install parity suite (needs PowerShell)."
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

if grep -qxF "home.html" <(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "$MANIFEST_FILE" 2>/dev/null); then
    pass "PAR13c dashboard/MANIFEST lists home.html (ships on both sh + ps1 channels)"
else
    fail "PAR13c dashboard/MANIFEST does NOT list home.html — migration/provisioning source at risk"
fi

test_summary
