#!/usr/bin/env bash
# test-home-html-source-sync.sh — CI equality gate for home.html source sync.
#
# Asserts that dashboard/home.html (the single committed source of truth for the
# per-repo SPA shell) is byte-identical to .aid/dashboard/home.html (the derived
# dogfood copy).  Any divergence between them means the dogfood copy has drifted
# from the source — a developer accidentally edited the copy instead of the source,
# or a change to the source was not synced back (DD-5 / LC-HSRC / R20).
#
# The comparison uses `cmp -s` (binary byte-by-byte) so the check catches any diff
# including Unicode glyphs that appear identical in a text diff but differ at byte
# level.  home.html itself is NOT subject to the ASCII-only gate (it is a served
# static asset with unicode glyphs) — this test only enforces equality, not charset.
#
# Registered automatically: tests/run-all.sh discovers all tests/canonical/test-*.sh
# by glob, so no manual wiring is needed.
#
# Usage:
#   bash tests/canonical/test-home-html-source-sync.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SOURCE="${REPO_ROOT}/dashboard/home.html"
COPY="${REPO_ROOT}/.aid/dashboard/home.html"

echo "=== home.html source-sync equality gate ==="

# HS01: dashboard/home.html exists (the new committed source)
assert_file_exists "$SOURCE" "HS01 dashboard/home.html exists as committed source"

# HS02: .aid/dashboard/home.html exists (the derived dogfood copy; R18 server contract)
assert_file_exists "$COPY" "HS02 .aid/dashboard/home.html exists as derived dogfood copy (R18)"

# HS03: the two files are byte-identical (cmp -s; R20 / DD-5)
if [[ -f "$SOURCE" && -f "$COPY" ]]; then
    if cmp -s "$SOURCE" "$COPY"; then
        pass "HS03 dashboard/home.html and .aid/dashboard/home.html are byte-identical"
    else
        # Show sizes so the developer can see how far apart they are.
        SRC_BYTES="$(wc -c < "$SOURCE" | tr -d ' ')"
        CPY_BYTES="$(wc -c < "$COPY"   | tr -d ' ')"
        fail "HS03 files have diverged (source=${SRC_BYTES}B copy=${CPY_BYTES}B) -- edit dashboard/home.html (source) and sync to .aid/dashboard/home.html"
    fi
fi

# HS04: dashboard/home.html is absent from canonical/EMISSION-MANIFEST.md (C8 / not render-drift)
MANIFEST="${REPO_ROOT}/canonical/EMISSION-MANIFEST.md"
if [[ -f "$MANIFEST" ]]; then
    if grep -qF "home.html" "$MANIFEST"; then
        fail "HS04 dashboard/home.html found in canonical/EMISSION-MANIFEST.md -- it must NOT be a render-drift artifact (C8)"
    else
        pass "HS04 dashboard/home.html absent from canonical/EMISSION-MANIFEST.md (C8 compliant)"
    fi
else
    pass "HS04 canonical/EMISSION-MANIFEST.md not found -- skipping emission-manifest check"
fi

test_summary
