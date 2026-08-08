#!/usr/bin/env bash
# test-skill-counts.sh -- repo-wide guard: every stated skill count equals the ONE derivation.
#
# Thin wrapper so `run-all.sh` (which globs tests/canonical/test-*.sh) picks this up. The
# checker itself is Node, because the derivation it must agree with is a Node module --
# site/scripts/skills/skill-counts.mjs -- and re-implementing that derivation in Bash would
# create the very second source of truth this guard exists to prevent.
#
# RELATIONSHIP TO test-doc-counts.sh (which predates this and stays).
# That suite asserts README + docs/ + the five profile READMEs state the current counts, and
# its header records a deliberate exclusion:
#
#     "The KB under .aid/knowledge/ is intentionally NOT asserted here -- it carries heavy
#      version-history sections and is reconciled by /aid-housekeep; guarding it by
#      prose-grep would false-positive."
#
# That reasoning was correct for a prose-grep. It is also exactly why work-001's two delivery
# gates found 55 wrong counts sitting unguarded, most of them in the KB: nothing was watching.
# This checker removes the objection rather than the exclusion -- it separates a claim about
# NOW from a record of a MOMENT by the line's SHAPE (a dated changelog row or `- YYYY-MM-DD:`
# bullet is history), plus an explicit per-line `count-history` marker for the handful of
# historical clauses that sit in ordinary prose. On the corpus that produced those 55
# findings it skips 185 history lines and reports zero false positives.
#
# The two suites overlap on README + docs/ and that is fine -- both derive from the same
# canonical tree, so they cannot disagree; they differ in mechanism (assert-expected-phrase
# vs. scan-every-claim) and this one additionally covers .aid/knowledge/, canonical/,
# site/src/content/docs/ and the repo-local maintainer skills.
#
# Fast + hermetic: reads files only, binds no port, mutates nothing.
#
# Usage: bash test-skill-counts.sh [--verbose]

set -euo pipefail

_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo="$(cd "${_here}/../.." && pwd)"

_passed=0
_failed=0

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not available -- repo-wide skill-count guard not run"
    echo "Tests passed: 0"
    echo "Tests failed: 0"
    exit 0
fi

_out="$(cd "$_repo" && node tests/canonical/check-skill-counts.mjs 2>&1)" && _rc=0 || _rc=$?

if [[ "${1:-}" == "--verbose" || "$_rc" -ne 0 ]]; then
    echo "$_out"
fi

if [[ "$_rc" -eq 0 ]]; then
    # Report the count the checker compared. The pass count here is always 1, so a shrinking
    # corpus does not show up as a falling pass count -- the guard against that lives in the
    # checker itself (CLAIM_FLOOR), set near the live figure rather than at a token value.
    _n="$(printf '%s\n' "$_out" | sed -n 's/^Claims checked: *\([0-9]\+\).*/\1/p' | head -1)"
    _n="${_n:-0}"
    # Echo the marker lines even on success -- the checker header promises exemptions are
    # reported, and suppressing stdout here is what made that promise false.
    printf '%s
' "$_out" | grep -E '^\s+\[history\]' || true
    echo "PASS SC01 every stated skill count agrees with the derivation (${_n} claims compared)"
    _passed=$((_passed + 1))
else
    echo "FAIL SC01 at least one stated skill count disagrees with the derivation (see above)"
    _failed=$((_failed + 1))
fi

# ── mutation controls ────────────────────────────────────────────────────────────────────────
#
# SC01 proves the checker RUNS CLEAN. On its own it cannot distinguish "every stated count agrees"
# from "no pattern matched anything" -- and that distinction is not hypothetical here: four of this
# guard's patterns were added *because* they matched nothing while live falsehoods sat in the very
# files it scans. `canonical/skills/* (111)` was rejected by a lookbehind meant to exclude
# site/scripts/; `(111 total:` had no pattern at all; the first term of every `A + B + C`
# decomposition fell outside the bare-curated follow set; and `generated doorways` was not among the
# recognised doorway adjectives. Two of those hid a wrong number for three days.
#
# So each control below plants ONE wrong count in the exact shape that survived, and requires the
# guard to report it. The tree is copied once and the mutated file restored between runs.

_scratch="$(mktemp -d)"
trap 'rm -rf "$_scratch"' EXIT
mkdir -p "$_scratch/tests/canonical" "$_scratch/.aid" "$_scratch/site/src/content"
cp -r "$_repo/canonical" "$_scratch/" 2>/dev/null || true
cp -r "$_repo/.aid/knowledge" "$_scratch/.aid/" 2>/dev/null || true
cp -r "$_repo/docs" "$_scratch/" 2>/dev/null || true
cp -r "$_repo/site/scripts" "$_scratch/site/" 2>/dev/null || true
cp -r "$_repo/site/src/content/docs" "$_scratch/site/src/content/" 2>/dev/null || true
cp "$_repo/README.md" "$_scratch/" 2>/dev/null || true
cp "$_here/check-skill-counts.mjs" "$_scratch/tests/canonical/"

_plant() {   # _plant ID REL SED_EXPR EXPECTED_SUBSTRING DESCRIPTION
    local id="$1" rel="$2" expr="$3" want="$4" desc="$5" out rc
    cp "$_repo/$rel" "$_scratch/$rel"
    sed -i "$expr" "$_scratch/$rel"
    out="$(cd "$_scratch" && node tests/canonical/check-skill-counts.mjs 2>&1)" && rc=0 || rc=$?
    cp "$_repo/$rel" "$_scratch/$rel"
    if [[ "$rc" -ne 0 ]] && printf '%s' "$out" | grep -qF "$want"; then
        echo "PASS $id $desc"
        _passed=$((_passed + 1))
    else
        echo "FAIL $id $desc -- planted defect NOT reported (rc=$rc)"
        _failed=$((_failed + 1))
    fi
}

_mm=".aid/knowledge/module-map.md"
_plant SC02 "$_mm" 's/(113) | Toolkit/(111) | Toolkit/' 'corpus total should be 113' \
    'a corpus total stated as `canonical/skills/* (N)` is checked'
_plant SC03 "$_mm" 's/(113 total/(111 total/' 'corpus total should be 113' \
    'a corpus total stated as the header of a decomposition `(N total: ...)` is checked'
_plant SC04 "$_mm" 's/19 curated + 64/17 curated + 64/' 'curated (non-catalog) should be 19' \
    'the first term of an `A + B + C` decomposition is checked'
_plant SC05 "$_mm" 's/64 generated doorways/63 generated doorways/' 'emitting shortcuts should be 64' \
    'a doorway count carrying the `generated` adjective is checked'

echo ""
echo "=== Summary ==="
echo "  Tests passed: ${_passed}"
echo "  Tests failed: ${_failed}"

if [[ "$_failed" -gt 0 ]]; then
    echo ""
    echo "Some tests failed."
    exit 1
fi
echo ""
echo "All tests passed."
