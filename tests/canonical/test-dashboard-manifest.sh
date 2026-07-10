#!/usr/bin/env bash
# test-dashboard-manifest.sh — guards the single-source dashboard file manifest (tech-debt H1).
#
# dashboard/MANIFEST is the ONE list of the curated dashboard "server + reader" unit.
# Five channels vendor/provision that unit (install.sh, install.ps1,
# packages/npm/scripts/vendor.js, packages/pypi/scripts/vendor.py, release.sh); before
# this manifest each hard-coded its own copy, so a source file could be silently omitted
# from one channel while the others looked healthy (the real home.html and io_bounds.py
# incidents — H1). This suite makes such drift a loud CI failure instead:
#
#   DM01  dashboard/MANIFEST exists and is non-empty
#   DM02  every path in MANIFEST resolves to a real file under dashboard/
#   DM03  MANIFEST == the curated dashboard/ tree (no missing, no extra)
#         curated = all files under dashboard/ MINUS tests/, __pycache__, *.pyc,
#         README.md, and MANIFEST itself
#   DM04  reader/io_bounds.py is listed (regression guard: it shipped imported by
#         reader.py but was absent from every manifest)
#   DM05  each of the five consumers references dashboard/MANIFEST (i.e. derives its
#         file set from the manifest rather than re-inlining a hand-maintained list)
#
# Fast + hermetic: reads files only, binds no port, mutates nothing, git-independent.
#
# Usage: bash test-dashboard-manifest.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DASH="${REPO_ROOT}/dashboard"
MANIFEST="${DASH}/MANIFEST"

# DM01 — manifest present.
assert_file_exists "$MANIFEST" "DM01 dashboard/MANIFEST exists"
if [[ ! -f "$MANIFEST" ]]; then
    test_summary; exit 1
fi

# Parse MANIFEST -> declared set (strip #-comments, blank lines, all whitespace).
declared=$(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "$MANIFEST" | grep -v '^$' | sort -u)
if [[ -n "$declared" ]]; then
    pass "DM01b MANIFEST is non-empty after stripping comments"
else
    fail "DM01b MANIFEST is empty after stripping comments"
    test_summary; exit 1
fi

# DM02 — every declared path is a real dashboard file.
_missing=""
while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    [[ -f "${DASH}/${rel}" ]] || _missing+="${rel} "
done <<< "$declared"
if [[ -z "$_missing" ]]; then
    pass "DM02 every MANIFEST path resolves to a real dashboard file"
else
    fail "DM02 MANIFEST lists non-existent files: ${_missing}"
fi

# Curated tree from the filesystem (dashboard-relative), git-independent.
curated=$(cd "$DASH" && find . -type f \
    -not -path '*/tests/*' \
    -not -path '*/__pycache__/*' \
    -not -name '*.pyc' \
    -not -name 'README.md' \
    -not -name 'MANIFEST' \
    | sed 's|^\./||' | sort -u)

# DM03 — MANIFEST is exactly the curated tree, both directions.
only_curated=$(comm -13 <(echo "$declared") <(echo "$curated"))
only_declared=$(comm -23 <(echo "$declared") <(echo "$curated"))
if [[ -z "$only_declared" && -z "$only_curated" ]]; then
    pass "DM03 MANIFEST matches the curated dashboard/ tree"
else
    [[ -n "$only_curated"  ]] && fail "DM03 dashboard files NOT in MANIFEST (would be omitted from install channels): $(echo $only_curated)"
    [[ -n "$only_declared" ]] && fail "DM03 MANIFEST lists files not present in dashboard/: $(echo $only_declared)"
fi

# DM04 — io_bounds.py regression guard.
if echo "$declared" | grep -qx "reader/io_bounds.py"; then
    pass "DM04 reader/io_bounds.py is listed in MANIFEST"
else
    fail "DM04 reader/io_bounds.py missing from MANIFEST (it is imported by reader.py at runtime)"
fi

# DM05 — every consumer derives from the manifest (references dashboard/MANIFEST).
for consumer in \
    "install.sh" \
    "install.ps1" \
    "packages/npm/scripts/vendor.js" \
    "packages/pypi/scripts/vendor.py" \
    "release.sh"
do
    f="${REPO_ROOT}/${consumer}"
    if [[ -f "$f" ]] && grep -qF "dashboard/MANIFEST" "$f"; then
        pass "DM05 ${consumer} references dashboard/MANIFEST"
    else
        fail "DM05 ${consumer} does not reference dashboard/MANIFEST (reverted to an inline list?)"
    fi
done

test_summary
