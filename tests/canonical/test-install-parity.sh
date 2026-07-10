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
# PAR13 — Static: dashboard file enumeration is identical between install.sh and install.ps1.
#
# Extracts the curated dashboard file list from each installer's source, normalises
# path separators (PS1 uses backslash, sh uses forward slash), and asserts:
#   a) Both lists are identical after normalisation.
#   b) home.html is present in the install.sh list.
#   c) home.html is present in the install.ps1 list.
# This is a static check that runs without PowerShell and catches payload divergence
# before any installer invocation.
# ---------------------------------------------------------------------------

# Extract dashboard filenames from install.sh.
# The curated list appears as a series of quoted strings in the for-loop body between
# "home.html" and "server/__init__.py".  We pull every double-quoted path token in that
# region and normalise to forward-slash.
SH_DASH_FILES=$(python3 - "$SUT_SH" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
# Find the section header comment and grab everything up to the "do" keyword
m = re.search(r'Stage dashboard server\+reader unit.*?(?=\s*do\b)', text, re.DOTALL)
if not m:
    # Try the install section (second occurrence)
    m = re.search(r'Install the dashboard unit.*?(?=\s*do\b)', text, re.DOTALL)
# Collect all for-loop iterations: grab quoted paths from both loops (stage + install)
paths = re.findall(r'"([a-z/_A-Z.]+(?:/[a-z_A-Z.]+)*)"', text)
# Filter to dashboard-shaped paths only (have no spaces, are paths in the dashboard unit)
dashboard = [p for p in paths if any(p.endswith(x) for x in [
    'home.html','index.html','__init__.py','reader.py','models.py',
    'parsers.py','derivation.py','locator.py','server.py','server.mjs','reader.mjs'
])]
# Deduplicate preserving order
seen = set(); unique = []
for p in dashboard:
    if p not in seen:
        seen.add(p); unique.append(p)
for p in sorted(unique):
    print(p)
PY
)

# Extract dashboard filenames from install.ps1.
# The array uses single-quoted strings with backslash separators.
PS1_DASH_FILES=$(python3 - "$SUT_PS1" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
# Grab all single-quoted paths inside the $bsDashFiles array
paths = re.findall(r"'([a-zA-Z_./\\]+)'", text)
# Normalise backslash to forward slash and filter to dashboard-shaped paths
dashboard_exts = {'home.html','index.html','__init__.py','reader.py','models.py',
    'parsers.py','derivation.py','locator.py','server.py','server.mjs','reader.mjs'}
result = []
for p in paths:
    pn = p.replace('\\', '/')
    if any(pn.endswith(x) for x in dashboard_exts):
        result.append(pn)
seen = set(); unique = []
for p in result:
    if p not in seen:
        seen.add(p); unique.append(p)
for p in sorted(unique):
    print(p)
PY
)

assert_eq "$SH_DASH_FILES" "$PS1_DASH_FILES" \
    "PAR13a dashboard file enumeration identical between install.sh and install.ps1"

if echo "$SH_DASH_FILES" | grep -qF "home.html"; then
    pass "PAR13b install.sh lists home.html in dashboard files"
else
    fail "PAR13b install.sh does NOT list home.html in dashboard files"
fi

if echo "$PS1_DASH_FILES" | grep -qF "home.html"; then
    pass "PAR13c install.ps1 lists home.html in dashboard files"
else
    fail "PAR13c install.ps1 does NOT list home.html in dashboard files"
fi

test_summary
