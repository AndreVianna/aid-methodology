#!/usr/bin/env bash
# test-kb-forward-authored-marker.sh -- end-to-end suite for the
# source: forward-authored marker (feature-003) through all three KB-authoring
# scripts, plus brownfield-intact regression for existing hand-authored behavior.
#
# Test IDs:
#   FA01  Git fixture setup: two commits C1 (baseline) + C2 (drift)
#   FA02  Freshness TSV: forward-authored doc folds to verdict=current; 7-column row
#   FA03  Freshness TSV: n_current=0, n_suspect=0, n_unknown=0; approved_at_commit empty
#   FA04  Freshness text: forward-authored emits "current" + design-authoritative reason
#   FA05  Freshness TSV: hand-authored control (same drifted source) reads suspect
#         -- proves short-circuit is what saves the forward-authored doc
#   FA06  Freshness --doc filter: single-doc returns correct 1-row TSV + text
#   FA07  Isolation canary: no new .aid directory under real HOME
#
#   FL01  Lint: source: forward-authored with complete f001 fields passes (exit 0)
#   FL02  Lint: source: forward-authored missing objective: -> [FM-MISSING], exit nonzero
#         -- proves forward-authored is LINTED (not skipped)
#   FL03  Lint: source: forward-authored with valid approved_at_commit passes (no FM-INVALID)
#
#   FI01  Index: source: forward-authored primary doc appears in Primary table
#   FI02  Index: forward-authored and hand-authored peers both in Primary table (source-agnostic)
#   FI03  Index: 6-column header emitted for Primary section (schema unchanged)
#   FI04  Index: forward-authored row has non-empty Objective and Summary cells
#
#   BD01  Brownfield: existing test-kb-freshness-check.sh still passes unchanged
#   BD02  Brownfield: existing test-frontmatter-lint.sh still passes unchanged
#   BD03  Brownfield: existing test-build-kb-index.sh still passes unchanged
#
# ISOLATION:
#   HOME pinned to a throwaway dir before any freshness invocation (FA tests).
#   Real HOME .aid snapshot taken before/after for the isolation canary (FA07).
#   All freshness invocations pass explicit --root / --repo to the mktemp fixture.
#   The fixture git repo lives entirely in scratch; AID repo git history is never touched.
#
# Fixture git repo (FA tests):
#   .aid/knowledge/
#     fa-doc.md      -- source: forward-authored, sources: [docs/drifted.md], approved_at_commit: C1
#     ha-control.md  -- source: hand-authored,    sources: [docs/drifted.md], approved_at_commit: C1
#   docs/
#     drifted.md     -- modified in C2 (after C1 = approval baseline)
#
#   C1: initial commit (all files at baseline; approved_at_commit set to C1 hash)
#   C2: docs/drifted.md updated -- source drifts after C1
#
#   Expected after C2:
#     fa-doc.md     -> current  (short-circuit: forward-authored is design-authoritative)
#     ha-control.md -> suspect  (drifted.md last-changed=C2, NOT ancestor of C1)
#
# Usage:
#   bash tests/canonical/test-kb-forward-authored-marker.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRESHNESS="${REPO_ROOT}/canonical/aid/scripts/kb/kb-freshness-check.sh"
LINT="${REPO_ROOT}/canonical/aid/scripts/kb/lint-frontmatter.sh"
INDEX_GEN="${REPO_ROOT}/canonical/aid/scripts/kb/build-kb-index.sh"

for script in "$FRESHNESS" "$LINT" "$INDEX_GEN"; do
    if [[ ! -f "$script" ]]; then
        fail "FM00 setup -- script not found: $script"
        test_summary; exit 1
    fi
done

# ---------------------------------------------------------------------------
# Global tmpdir -- all scratch and fixture repos live here; cleaned on EXIT.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# HOME pin: redirect all home-relative IO to a throwaway dir.
# Save REAL_HOME for the isolation canary (FA07).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | LC_ALL=C sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ===========================================================================
# FA01 -- Build git fixture repo with scripted two-commit history
# ===========================================================================
FIXREPO="${TMP}/fixture-repo"
mkdir -p "${FIXREPO}/.aid/knowledge"
mkdir -p "${FIXREPO}/docs"

cd "${FIXREPO}"
git init -q
git config user.email "test@aid-suite"
git config user.name "AID Test"

# Initial source file (the one that will drift)
printf 'initial content of drifted source\n' > "${FIXREPO}/docs/drifted.md"

# Forward-authored seed doc (full f001 frontmatter, approved_at_commit filled after C1)
printf -- '---\nkb-category: primary\nsource: forward-authored\nobjective: Design-authoritative greenfield KB seed for the forward-authored marker.\nsummary: Documents target system design before any implementation exists.\nsources:\n  - docs/drifted.md\napproved_at_commit: PLACEHOLDER\n---\n\n# Forward-Authored Doc\n\nBody.\n' \
    > "${FIXREPO}/.aid/knowledge/fa-doc.md"

# Hand-authored control doc (identical sources and approved_at_commit; differs only in source:)
printf -- '---\nkb-category: primary\nsource: hand-authored\nobjective: Hand-authored control tracking the same drifted source as fa-doc.md.\nsummary: Used to prove the forward-authored short-circuit is what saves fa-doc from suspect.\nsources:\n  - docs/drifted.md\napproved_at_commit: PLACEHOLDER\n---\n\n# Hand-Authored Control Doc\n\nBody.\n' \
    > "${FIXREPO}/.aid/knowledge/ha-control.md"

# Stage and commit C1 (baseline)
git add .
git commit -q -m "C1: initial commit -- all sources at baseline"
C1="$(git rev-parse HEAD)"

# Replace PLACEHOLDER with the real C1 hash in both KB docs
for doc in fa-doc ha-control; do
    f="${FIXREPO}/.aid/knowledge/${doc}.md"
    tmp_f="${TMP}/tmp-doc.md"
    sed "s/PLACEHOLDER/${C1}/" "$f" > "$tmp_f"
    mv "$tmp_f" "$f"
done

# Create C2: modify docs/drifted.md AFTER the baseline C1
printf 'modified content -- drifted after C1 baseline\n' > "${FIXREPO}/docs/drifted.md"
git add .
git commit -q -m "C2: docs/drifted.md changed after baseline (ha-control should go suspect)"
C2="$(git rev-parse HEAD)"

# Sanity checks on commit history (required for the short-circuit proof)
rc_ancestor=0
git -C "${FIXREPO}" merge-base --is-ancestor "$C1" "$C2" 2>/dev/null || rc_ancestor=$?
if [[ "$rc_ancestor" -eq 0 ]]; then
    pass "FA01 git fixture: C1 is ancestor of C2 (commit history correct)"
else
    fail "FA01 git fixture: C1 should be ancestor of C2 (rc=$rc_ancestor)"
fi

rc_not_ancestor=0
git -C "${FIXREPO}" merge-base --is-ancestor "$C2" "$C1" 2>/dev/null || rc_not_ancestor=$?
if [[ "$rc_not_ancestor" -eq 1 ]]; then
    pass "FA01 git fixture: C2 is NOT ancestor of C1 (merge-base direction correct)"
else
    fail "FA01 git fixture: C2 should NOT be ancestor of C1 (rc=$rc_not_ancestor)"
fi

KB_ROOT="${FIXREPO}/.aid/knowledge"

# Full TSV scan (reused across FA02-FA05)
tsv_out="$(bash "$FRESHNESS" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv)"

# ===========================================================================
# FA02 -- Forward-authored doc TSV: verdict=current + 7-column row
# ===========================================================================
fa_row="$(echo "$tsv_out" | grep '^fa-doc\.md' || true)"

if [[ -n "$fa_row" ]]; then
    fa_verdict="$(echo "$fa_row" | cut -f2)"
    assert_eq "$fa_verdict" "current" \
        "FA02 forward-authored TSV: verdict=current"
    col_count="$(echo "$fa_row" | awk -F'\t' '{print NF}')"
    assert_eq "$col_count" "7" \
        "FA02 forward-authored TSV: exactly 7 tab-separated columns"
else
    fail "FA02 forward-authored TSV -- fa-doc.md not found in output"
fi

# ===========================================================================
# FA03 -- Forward-authored doc TSV: n_current=0, n_suspect=0, n_unknown=0
#         approved_at_commit field empty (short-circuit fires before reading it)
# ===========================================================================
if [[ -n "$fa_row" ]]; then
    fa_ncurrent="$(echo "$fa_row" | cut -f4)"
    fa_nsuspect="$(echo "$fa_row" | cut -f5)"
    fa_nunknown="$(echo "$fa_row" | cut -f6)"
    fa_col3="$(echo "$fa_row" | cut -f3)"
    fa_col7="$(echo "$fa_row" | cut -f7)"

    assert_eq "$fa_ncurrent" "0" "FA03 forward-authored TSV: n_current=0"
    assert_eq "$fa_nsuspect" "0" "FA03 forward-authored TSV: n_suspect=0"
    assert_eq "$fa_nunknown" "0" "FA03 forward-authored TSV: n_unknown=0"
    assert_eq "$fa_col3" "" \
        "FA03 forward-authored TSV: approved_at_commit empty (short-circuit fires before reading)"
    assert_eq "$fa_col7" "" "FA03 forward-authored TSV: suspect_sources_csv empty"
else
    fail "FA03 forward-authored counters -- fa-doc.md row absent"
fi

# ===========================================================================
# FA04 -- Forward-authored doc text format: verdict "current" + design-authoritative reason
# ===========================================================================
text_out="$(bash "$FRESHNESS" --root "$KB_ROOT" --repo "$FIXREPO" --format text)"
fa_text_line="$(echo "$text_out" | grep 'fa-doc' || true)"

if [[ -n "$fa_text_line" ]]; then
    if echo "$fa_text_line" | grep -qF "current"; then
        pass "FA04 forward-authored text: verdict 'current' in text output"
    else
        fail "FA04 forward-authored text: 'current' not found in line: $fa_text_line"
    fi
    if echo "$fa_text_line" | grep -qF "design-authoritative"; then
        pass "FA04 forward-authored text: design-authoritative reason present"
    else
        fail "FA04 forward-authored text: design-authoritative reason not found in: $fa_text_line"
    fi
    if echo "$fa_text_line" | grep -qF "forward-authored"; then
        pass "FA04 forward-authored text: 'forward-authored' token in reason"
    else
        fail "FA04 forward-authored text: 'forward-authored' token not found in: $fa_text_line"
    fi
else
    fail "FA04 forward-authored text -- fa-doc.md line not found in text output"
fi

# ===========================================================================
# FA05 -- Hand-authored control reads suspect (proves short-circuit saves forward-authored)
#
# The forward-authored and hand-authored docs share the SAME sources: entry
# (docs/drifted.md) and the SAME approved_at_commit: (C1). After C2 the only
# difference is source: forward-authored vs source: hand-authored. The
# hand-authored doc must read suspect to prove the short-circuit (not a
# degenerate setup) is what gives the forward-authored doc its current verdict.
# ===========================================================================
ha_row="$(echo "$tsv_out" | grep '^ha-control\.md' || true)"

if [[ -n "$ha_row" ]]; then
    ha_verdict="$(echo "$ha_row" | cut -f2)"
    assert_eq "$ha_verdict" "suspect" \
        "FA05 hand-authored control reads suspect (short-circuit proof: setup is not degenerate)"
    ha_nsuspect="$(echo "$ha_row" | cut -f5)"
    assert_eq "$ha_nsuspect" "1" "FA05 hand-authored control: n_suspect=1"
    ha_csv="$(echo "$ha_row" | cut -f7)"
    assert_eq "$ha_csv" "docs/drifted.md" \
        "FA05 hand-authored control: suspect_sources_csv=docs/drifted.md"
else
    fail "FA05 hand-authored control -- ha-control.md not found in TSV output"
fi

# ===========================================================================
# FA06 -- --doc single-filter on forward-authored doc: 1-row TSV + text both correct
# ===========================================================================
# TSV mode --doc
doc_tsv="$(bash "$FRESHNESS" --root "$KB_ROOT" --repo "$FIXREPO" \
    --format tsv --doc "fa-doc.md")"
doc_rows="$(echo "$doc_tsv" | grep -c '.' || true)"

assert_eq "$doc_rows" "1" "FA06 --doc filter TSV: exactly 1 row returned"
doc_verdict="$(echo "$doc_tsv" | cut -f2)"
assert_eq "$doc_verdict" "current" "FA06 --doc filter TSV: verdict=current"
assert_output_not_contains "$doc_tsv" "ha-control" \
    "FA06 --doc filter TSV: ha-control.md absent from single-doc output"

# Text mode --doc
doc_text="$(bash "$FRESHNESS" --root "$KB_ROOT" --repo "$FIXREPO" \
    --format text --doc "fa-doc.md")"
if echo "$doc_text" | grep -qF "current"; then
    pass "FA06 --doc filter text: verdict 'current' present"
else
    fail "FA06 --doc filter text: verdict 'current' not found"
fi
if echo "$doc_text" | grep -qF "design-authoritative"; then
    pass "FA06 --doc filter text: design-authoritative reason present"
else
    fail "FA06 --doc filter text: design-authoritative reason not found"
fi

# ===========================================================================
# FA07 -- Isolation canary: no .aid directory appeared under real HOME
# ===========================================================================
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | LC_ALL=C sort || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]]; then
    pass "FA07 isolation canary: no new .aid directory appeared under real HOME"
else
    fail "FA07 isolation canary: new .aid directories detected under real HOME"
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "BEFORE: $_CANARY_BEFORE"
        echo "AFTER:  $_CANARY_AFTER"
    fi
fi

# ===========================================================================
# Section B -- Lint: forward-authored doc is in-scope (full linting applied)
# ===========================================================================

make_kb() {
    # make_kb <dir> <filename> <frontmatter-content>
    # Wraps content in --- delimiters and adds a stub body.
    local dir="$1" name="$2" fm="$3"
    mkdir -p "$dir"
    printf -- '---\n%s\n---\n\n# Body\n' "$fm" > "${dir}/${name}"
}

run_lint() { bash "$LINT" --root "$1" 2>&1; }

# ---------------------------------------------------------------------------
# FL01 -- source: forward-authored with complete f001 fields passes lint
# ---------------------------------------------------------------------------
D="${TMP}/fl01"; mkdir -p "$D"
make_kb "$D" "fa-full.md" "kb-category: primary
source: forward-authored
objective: Design-authoritative greenfield KB seed objective.
summary: Documents the target system design before any implementation code exists.
sources:
  - canonical/aid/scripts/kb/kb-freshness-check.sh
approved_at_commit: a1b2c3d"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code" "FL01 forward-authored complete fields -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL01 forward-authored complete fields -- no FM-MISSING"
assert_output_not_contains "$out" "[FM-INVALID]" "FL01 forward-authored complete fields -- no FM-INVALID"

# ---------------------------------------------------------------------------
# FL02 -- source: forward-authored missing objective: -> [FM-MISSING], exit nonzero
#
# This proves the forward-authored doc is LINTED (not skipped).
# If forward-authored were skipped, exit 0 with no findings.
# We expect exit nonzero and [FM-MISSING] -- confirming full lint is applied.
# ---------------------------------------------------------------------------
D="${TMP}/fl02"; mkdir -p "$D"
make_kb "$D" "fa-noobjective.md" "kb-category: primary
source: forward-authored
summary: One sentence summary of the greenfield seed scope.
sources: []"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code" "FL02 forward-authored missing objective -- exit nonzero (not skipped)"
assert_output_contains "$out" "[FM-MISSING]" \
    "FL02 forward-authored missing objective -- [FM-MISSING] emitted (linted, not skipped)"
assert_output_contains "$out" "objective" \
    "FL02 forward-authored missing objective -- mentions 'objective' field name"

# ---------------------------------------------------------------------------
# FL03 -- source: forward-authored with valid approved_at_commit passes (no FM-INVALID)
# ---------------------------------------------------------------------------
D="${TMP}/fl03"; mkdir -p "$D"
make_kb "$D" "fa-withcommit.md" "kb-category: primary
source: forward-authored
objective: Greenfield seed with a commit stamp for freshness baseline.
summary: Describes system design intent committed before implementation starts.
sources: []
approved_at_commit: deadbeef1a2b3c4"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code" "FL03 forward-authored with approved_at_commit -- exit 0"
assert_output_not_contains "$out" "[FM-INVALID]" \
    "FL03 forward-authored with approved_at_commit -- no FM-INVALID"

# ===========================================================================
# Section C -- Index: source: value is a pass-through (source-agnostic grouping)
# ===========================================================================
IKBROOT="${TMP}/fi-kb"
IOUT="${TMP}/fi-index/INDEX.md"
mkdir -p "$IKBROOT"

# Forward-authored primary doc
printf -- '---\nkb-category: primary\nsource: forward-authored\nobjective: Greenfield architecture plan for the target system.\nsummary: Describes the intended architecture before implementation code exists.\ntags: [architecture, greenfield]\n---\n\n# Forward-Authored Primary Doc\n' \
    > "${IKBROOT}/fa-primary.md"

# Hand-authored primary doc (peer -- both should appear in Primary table)
printf -- '---\nkb-category: primary\nsource: hand-authored\nobjective: Hand-authored implementation guide for the module.\nsummary: Documents how to implement the module after code exists.\ntags: [implementation]\n---\n\n# Hand-Authored Primary Doc\n' \
    > "${IKBROOT}/ha-primary.md"

idx_code=0
bash "$INDEX_GEN" --root "$IKBROOT" --output "$IOUT" >/dev/null 2>&1 || idx_code=$?
assert_exit_zero "$idx_code" "FI00 build-kb-index.sh: exits 0 with mixed-source primary docs"

if [[ -f "$IOUT" ]]; then

    # FI01 -- forward-authored primary doc appears in Primary table
    if grep -qF "fa-primary.md" "$IOUT"; then
        pass "FI01 forward-authored primary doc appears in Primary table"
    else
        fail "FI01 forward-authored primary doc not found in INDEX output"
        [[ "$VERBOSE" -eq 1 ]] && grep "Primary" "$IOUT" || true
    fi

    # FI02 -- hand-authored peer also in Primary table (source-agnostic grouping confirmed)
    if grep -qF "ha-primary.md" "$IOUT"; then
        pass "FI02 hand-authored peer also appears in Primary table (source-agnostic)"
    else
        fail "FI02 hand-authored peer not found in INDEX output"
    fi

    # FI03 -- 6-column table header present (schema unchanged)
    if grep -qF "| Document | Objective | Summary | Tags | See-instead | Audience |" "$IOUT"; then
        pass "FI03 6-column table header present in Primary section (schema unchanged)"
    else
        fail "FI03 6-column table header not found in INDEX output"
    fi

    # FI04 -- forward-authored row has non-empty Objective and Summary cells
    fa_row_idx="$(grep 'fa-primary' "$IOUT" || true)"
    if [[ -n "$fa_row_idx" ]]; then
        if echo "$fa_row_idx" | grep -qF "Greenfield architecture plan for the target system"; then
            pass "FI04 forward-authored row: Objective cell populated"
        else
            fail "FI04 forward-authored row: Objective cell not populated (row: $fa_row_idx)"
        fi
        if echo "$fa_row_idx" | grep -qF "Describes the intended architecture"; then
            pass "FI04 forward-authored row: Summary cell populated"
        else
            fail "FI04 forward-authored row: Summary cell not populated (row: $fa_row_idx)"
        fi
    else
        fail "FI04 forward-authored row -- fa-primary.md row not found in INDEX"
    fi

else
    fail "FI00 INDEX.md not created at $IOUT"
fi

# ===========================================================================
# Section D -- Brownfield regression: existing suites still pass unchanged
# ===========================================================================
FRESHNESS_SUITE="${REPO_ROOT}/tests/canonical/test-kb-freshness-check.sh"
LINT_SUITE="${REPO_ROOT}/tests/canonical/test-frontmatter-lint.sh"
INDEX_SUITE="${REPO_ROOT}/tests/canonical/test-build-kb-index.sh"

# ---------------------------------------------------------------------------
# BD01 -- existing test-kb-freshness-check.sh still passes unchanged
# ---------------------------------------------------------------------------
bd01_rc=0
bash "$FRESHNESS_SUITE" >/dev/null 2>&1 || bd01_rc=$?
assert_exit_zero "$bd01_rc" "BD01 brownfield: test-kb-freshness-check.sh still passes unchanged"

# ---------------------------------------------------------------------------
# BD02 -- existing test-frontmatter-lint.sh still passes unchanged
# ---------------------------------------------------------------------------
bd02_rc=0
bash "$LINT_SUITE" >/dev/null 2>&1 || bd02_rc=$?
assert_exit_zero "$bd02_rc" "BD02 brownfield: test-frontmatter-lint.sh still passes unchanged"

# ---------------------------------------------------------------------------
# BD03 -- existing test-build-kb-index.sh still passes unchanged
# ---------------------------------------------------------------------------
bd03_rc=0
bash "$INDEX_SUITE" >/dev/null 2>&1 || bd03_rc=$?
assert_exit_zero "$bd03_rc" "BD03 brownfield: test-build-kb-index.sh still passes unchanged"

# ---------------------------------------------------------------------------
test_summary
exit $?
