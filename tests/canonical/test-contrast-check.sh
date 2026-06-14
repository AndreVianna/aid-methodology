#!/usr/bin/env bash
# test-contrast-check.sh — tests for canonical/scripts/summarize/contrast-check.mjs,
# the Node validator that extracts CSS custom properties from an inlined <style> block
# and verifies WCAG AA contrast ratios (>= 4.5:1) for known token pairs across the
# light and dark themes.
#
# Behavior locked in here:
#   - exit 0 when every RESOLVABLE pair meets target (unresolvable vars are skipped, not failed)
#   - exit 1 when any resolvable pair is below target
#   - exit 2 on missing argument
#   - hex (#rgb / #rrggbb) and rgb()/rgba() colors parse; var() chains do not resolve (skipped)
#
# Usage:
#   bash test-contrast-check.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail. Skips (exit 0) if Node is not on PATH.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/canonical/scripts/summarize/contrast-check.mjs"

[[ -f "$SUT" ]] || { echo "ERROR: contrast-check.mjs not found at $SUT" >&2; exit 1; }

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not found on PATH — skipping contrast-check suite (needs Node.js)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run() { OUT=$(node "$SUT" "$@" 2>&1); RC=$?; }

# --- Fixtures ---------------------------------------------------------------
# Only --text/--bg defined → 'body text on bg' is checked; all other token pairs are
# unresolvable and skipped. Black-on-white = 21:1 → pass.
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/pass-hex6.html"
# 3-digit hex must expand (#000 == #000000).
printf '<style>:root{--text:#000;--bg:#fff;}</style>\n' > "$TMP/pass-hex3.html"
# rgb() parsing path.
printf '<style>:root{--text:rgb(0,0,0);--bg:rgb(255,255,255);}</style>\n' > "$TMP/pass-rgb.html"
# #777 on #888 = 1.26:1 → fail.
printf '<style>:root{--text:#777777;--bg:#888888;}</style>\n' > "$TMP/fail.html"
# No text/bg vars at all → every pair unresolvable → skipped → exit 0.
printf '<style>:root{--unrelated:#123456;}</style>\n' > "$TMP/skip.html"
# Light passes; dark overrides text/bg to a failing pair → total fail > 0 → exit 1.
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{--text:#777777;--bg:#888888;}</style>\n' > "$TMP/dark-fail.html"

# --- Invocation paths -------------------------------------------------------
run
assert_exit_eq "$RC" 2 "CC01 no args → exit 2"
assert_output_contains "$OUT" "Usage" "CC01b no args → usage message"

run "$TMP/does-not-exist.html"
assert_exit_nonzero "$RC" "CC02 missing file → non-zero exit"

# --- Passing fixtures -------------------------------------------------------
run "$TMP/pass-hex6.html"
assert_exit_eq "$RC" 0 "CC03 #000 on #fff (6-hex) → exit 0"
assert_output_contains "$OUT" "All contrast checks passed" "CC03b pass summary line"

run "$TMP/pass-hex3.html"
assert_exit_eq "$RC" 0 "CC04 3-digit hex expands → exit 0"

run "$TMP/pass-rgb.html"
assert_exit_eq "$RC" 0 "CC05 rgb() colors parse → exit 0"

# --- Failing fixture --------------------------------------------------------
run "$TMP/fail.html"
assert_exit_eq "$RC" 1 "CC06 low-contrast pair → exit 1"
assert_output_contains "$OUT" "contrast check(s) failed" "CC06b failure summary line"
assert_output_contains "$OUT" "body text on bg" "CC06c names the offending pair"

# --- Unresolvable vars are skipped, not failed ------------------------------
run "$TMP/skip.html"
assert_exit_eq "$RC" 0 "CC07 unresolvable vars skipped → exit 0"
assert_output_contains "$OUT" "cannot resolve colors" "CC07b reports skipped pairs"

# --- Dark-theme extraction --------------------------------------------------
run "$TMP/dark-fail.html"
assert_exit_eq "$RC" 1 "CC08 dark-theme override fails while light passes → exit 1"

# --- Integration: the shipped summary must meet WCAG AA ---------------------
# d009 relocated the approved KB summary from .aid/knowledge/knowledge-summary.html
# to .aid/dashboard/kb.html (the path the dashboard serves at /r/<id>/kb.html);
# content was unchanged (a git mv). Follow it here so CC09 keeps gating the
# real shipped artifact instead of asserting a path that no longer exists.
SUMMARY="${REPO_ROOT}/.aid/dashboard/kb.html"
assert_file_exists "$SUMMARY" "CC09 shipped kb.html summary present"
if [[ -f "$SUMMARY" ]]; then
    run "$SUMMARY"
    assert_exit_eq "$RC" 0 "CC09b shipped summary passes WCAG AA contrast"
fi

test_summary
