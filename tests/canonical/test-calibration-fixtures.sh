#!/usr/bin/env bash
# test-calibration-fixtures.sh -- AC6 altitude/coverage regression suite (f012 TEST-B,
# revised for the delivery-009 panel simplification).
#
# Exercises f004's shipped closure-check.sh (output (b) coverage table) over the
# task-032 calibration fixture and asserts the mechanical coverage AC that survives
# the simplification. The former output (c) transcription-ratio (and its CAL-1 floor)
# was RETIRED: transcription ("too fat" / verbatim source copy) is now a runtime M2
# Anatomy reviewer judgment from the doc text + output (b)'s coverage signal, NOT a
# mechanical lexical ratio. So this suite no longer asserts any numeric overlap ratio.
#
# Assertions:
#   T01  CAL-3 coverage gap flagged (MECHANICAL): closure-check output (b) reports
#        the planted salient term "audit-record contract" as an absent row for
#        coverage-gap.md.
#   T03  Precision -- control is clean (MECHANICAL): well-calibrated.md produces
#        no absent row in output (b). The coverage check does NOT false-positive a
#        good doc.
#   T05  Determinism: two successive closure-check runs over the same fixture copy
#        produce byte-identical output across both outputs (a) and (b).
#   T06  Hollow substrate shape: hollow-thin.md has sources: [] in frontmatter
#        (the mechanical substrate of the CAL-2 hollowness fixture; CI does NOT
#        assert a numeric hollowness score -- that is LLM judgment).
#   T07  Transcription substrate shape: transcription-fat.md exists with a local-file
#        sources: entry (the runtime substrate the M2 Anatomy reviewer judges for
#        CAL-1 transcription; CI does NOT assert a numeric overlap ratio -- after the
#        delivery-009 simplification, CAL-1 is LLM judgment, not a mechanical ratio).
#   ISO-CANARY  Real HOME gained no .aid dirs during the suite run.
#
# Mechanical-vs-judgment boundary (load-bearing, post-delivery-009):
#   CAL-3 coverage-vs-source (V-B1) is the ONLY mechanical assertion -- closure-check
#   output (b)'s absent rows. CAL-1 transcription AND CAL-2 hollowness are BOTH runtime
#   LLM judgments the M2 Anatomy reviewer makes; no shipped script emits a numeric
#   signal for either. transcription-fat.md and hollow-thin.md are planted as the
#   runtime-anchored substrates for that reviewer -- CI only confirms the doc shapes
#   the reviewer reads (no numeric pass/fail asserted for transcription or hollowness).
#
# Isolation discipline (load-bearing):
#   - HOME is pinned to a throwaway dir before any script invocation.
#   - Real-HOME .aid canary snapshot taken before/after (ISO-CANARY assertion).
#   - closure-check.sh runs over a mktemp copy of the calibration/knowledge/ dir
#     with --root REPO (required for sources: path resolution against the repo root),
#     explicit --concepts / --kb-dir / --denylist -- no cwd/$HOME default.
#   - The committed fixture is NEVER mutated: each run uses a fresh mktemp copy.
#   - The repo root is passed ONLY as --root for sources: resolution (the fixture's
#     sources: entries reference REPO-relative paths). No harvest/scan of the repo.
#
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob).
# Pattern: test-doc-set-mapping.sh (set -u, source assert.sh, numbered Ts, mktemp,
#           trap EXIT, test_summary / exit $?).
#
# Usage:
#   bash tests/canonical/test-calibration-fixtures.sh [--verbose]
#   HOME=$(mktemp -d) bash tests/canonical/test-calibration-fixtures.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/closure-check.sh"
DENYLIST="${REPO}/canonical/aid/scripts/kb/coined-term-denylist.txt"

# Committed fixture directories (read-only inputs -- never written to).
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/kb-essence"
FX_CALIBRATION="${FIXTURES_BASE}/calibration"
FX_KB="${FX_CALIBRATION}/knowledge"
FX_CANDIDATES="${FX_CALIBRATION}/generated/candidate-concepts.md"

# ---------------------------------------------------------------------------
# Planted salient term for T01 (CAL-3 coverage gap).
# coverage-gap.md declares sources: [payment-engine.ts] but OMITS this term.
# The term appears in candidate-concepts.md (synthesis row) and in
# well-calibrated.md (which DOES cover it -- the control doc is clean).
# ---------------------------------------------------------------------------
PLANTED_ABSENT_TERM="audit-record contract"
COVERAGE_GAP_DOC="coverage-gap.md"
TRANSCRIPTION_FAT_DOC="transcription-fat.md"
WELL_CALIBRATED_DOC="well-calibrated.md"
HOLLOW_THIN_DOC="hollow-thin.md"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-calibration-fixtures.sh =="

# ---------------------------------------------------------------------------
# Guard: required scripts and fixtures must exist.
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: closure-check.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "$DENYLIST" ]]; then
  echo "FATAL: coined-term-denylist.txt not found at $DENYLIST" >&2
  exit 2
fi
if [[ ! -d "$FX_KB" ]]; then
  echo "FATAL: calibration/knowledge/ fixture not found at $FX_KB" >&2
  exit 2
fi
if [[ ! -f "$FX_CANDIDATES" ]]; then
  echo "FATAL: calibration candidate-concepts.md not found at $FX_CANDIDATES" >&2
  exit 2
fi
if [[ ! -f "${FX_KB}/${TRANSCRIPTION_FAT_DOC}" ]]; then
  echo "FATAL: transcription-fat.md fixture not found at ${FX_KB}/${TRANSCRIPTION_FAT_DOC}" >&2
  exit 2
fi
if [[ ! -f "${FX_KB}/${COVERAGE_GAP_DOC}" ]]; then
  echo "FATAL: coverage-gap.md fixture not found at ${FX_KB}/${COVERAGE_GAP_DOC}" >&2
  exit 2
fi
if [[ ! -f "${FX_KB}/${WELL_CALIBRATED_DOC}" ]]; then
  echo "FATAL: well-calibrated.md fixture not found at ${FX_KB}/${WELL_CALIBRATED_DOC}" >&2
  exit 2
fi
if [[ ! -f "${FX_KB}/${HOLLOW_THIN_DOC}" ]]; then
  echo "FATAL: hollow-thin.md fixture not found at ${FX_KB}/${HOLLOW_THIN_DOC}" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# HOME pin + isolation canary setup.
# Snapshot real-HOME .aid dirs BEFORE the suite runs so the canary can detect
# any escape (real HOME may already hold .aid dirs under CI -- per
# [[ci-runs-as-root-repo-under-home]] the CI checkout lives under $HOME).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"

TMP="$(mktemp -d)"
FAKE_HOME="${TMP}/fakehome"
mkdir -p "$FAKE_HOME"

# Cleanup: remove scratch AND the throwaway HOME on exit.
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Helper: make a fresh mktemp copy of the calibration/knowledge/ dir.
# The closure-check runs over this copy; the committed fixture is never mutated.
# We pass --root REPO so that sources: paths (which are REPO-relative) resolve
# correctly -- closure-check uses --root only for sources: file resolution, not
# for any directory scan.
# ---------------------------------------------------------------------------
_COPY_N=0
make_kb_copy() {
  _COPY_N=$((_COPY_N + 1))
  local dest="${TMP}/calibration-kb-${_COPY_N}"
  mkdir -p "$dest"
  cp "${FX_KB}/"*.md "$dest/"
  echo "$dest"
}

# Helper: run closure-check over a knowledge copy.
# Usage: run_closure <kb_copy_dir> <suffix>
# Sets:  OUT_A, OUT_B (absolute paths to the output files for outputs (a)/(b)).
run_closure() {
  local kb_copy="$1"
  local suffix="${2:-}"
  OUT_A="${TMP}/out_a${suffix}.md"
  OUT_B="${TMP}/out_b${suffix}.md"
  HOME="$FAKE_HOME" \
  bash "$SUT" \
    --root "$REPO" \
    --concepts "$FX_CANDIDATES" \
    --kb-dir "$kb_copy" \
    --denylist "$DENYLIST" \
    --output-a "$OUT_A" \
    --output-b "$OUT_B" \
    2>/dev/null
}

# ---------------------------------------------------------------------------
# Run 1: the primary oracle run (used by T01, T03).
# Run 2: the determinism run (used by T05).
# ---------------------------------------------------------------------------
KB_COPY_R1="$(make_kb_copy)"
log "Running closure-check (run 1) over calibration fixture copy..."
run_closure "$KB_COPY_R1" "_r1"
OUT_A_R1="$OUT_A"
OUT_B_R1="$OUT_B"

# ============================================================
# T01 -- CAL-3 coverage gap flagged (MECHANICAL).
#
# closure-check output (b) must contain an absent row for the planted salient
# term "audit-record contract" in coverage-gap.md.
#
# Planted: coverage-gap.md declares sources: [payment-engine.ts] but its body
# omits "audit-record contract". The term IS in candidate-concepts.md (synthesis
# row) and in the source file's auditability commentary. Output (b) must flag it.
# ============================================================
log "T01: output (b) reports 'audit-record contract' as absent in coverage-gap.md"
if [[ ! -f "$OUT_B_R1" ]]; then
  fail "T01 -- closure-check did not produce output (b)"
else
  # Look for a row: | audit-record contract | coverage-gap.md | ... | absent |
  absent_row="$(grep -iF "$PLANTED_ABSENT_TERM" "$OUT_B_R1" | grep -F "$COVERAGE_GAP_DOC" | grep -v '^#' | grep -v '^|---' || true)"
  if [[ -z "$absent_row" ]]; then
    fail "T01 -- no row for '${PLANTED_ABSENT_TERM}' in ${COVERAGE_GAP_DOC} found in output (b)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  elif echo "$absent_row" | grep -qF "absent"; then
    pass "T01 -- output (b) reports '${PLANTED_ABSENT_TERM}' as absent in ${COVERAGE_GAP_DOC} (CAL-3 coverage gap flagged)"
  else
    fail "T01 -- row for '${PLANTED_ABSENT_TERM}' in ${COVERAGE_GAP_DOC} is not 'absent': ${absent_row}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  fi
fi

# ============================================================
# T03 -- Precision -- control has no absent row in output (b).
#
# well-calibrated.md is the CONTROL doc. It covers all salient terms including
# "audit-record contract" (the term IS present in its body). Output (b) must
# produce NO absent row for well-calibrated.md.
# ============================================================
log "T03: output (b) has no absent row for ${WELL_CALIBRATED_DOC} (control is clean)"
if [[ ! -f "$OUT_B_R1" ]]; then
  fail "T03 -- closure-check did not produce output (b)"
else
  # Check for any absent row whose doc column is well-calibrated.md.
  control_absent_rows="$(grep -F "$WELL_CALIBRATED_DOC" "$OUT_B_R1" | grep -v '^#' | grep -v '^|---' | grep -F "absent" || true)"
  if [[ -z "$control_absent_rows" ]]; then
    pass "T03 -- output (b) has no absent row for ${WELL_CALIBRATED_DOC} (coverage check does not false-positive the control)"
  else
    fail "T03 -- output (b) has absent row(s) for ${WELL_CALIBRATED_DOC} (precision violation): ${control_absent_rows}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  fi
fi

# ============================================================
# T05 -- Determinism -- two successive closure-check runs are byte-identical.
#
# Run closure-check a second time over a separate fresh copy of the fixture.
# diff both outputs (a) and (b). Any difference is a non-determinism bug.
# ============================================================
log "T05: closure-check is byte-identical on re-run (determinism)"
KB_COPY_R2="$(make_kb_copy)"
run_closure "$KB_COPY_R2" "_r2"
OUT_A_R2="$OUT_A"
OUT_B_R2="$OUT_B"
if [[ ! -f "$OUT_A_R1" || ! -f "$OUT_A_R2" || \
      ! -f "$OUT_B_R1" || ! -f "$OUT_B_R2" ]]; then
  fail "T05 -- one or both runs did not produce all outputs; cannot compare"
else
  a_diff=0; b_diff=0
  diff -q "$OUT_A_R1" "$OUT_A_R2" >/dev/null 2>&1 || a_diff=1
  diff -q "$OUT_B_R1" "$OUT_B_R2" >/dev/null 2>&1 || b_diff=1
  if [[ "$a_diff" -eq 0 && "$b_diff" -eq 0 ]]; then
    pass "T05 -- closure-check outputs (a) and (b) are byte-identical across two runs (determinism confirmed)"
  else
    [[ "$a_diff" -eq 1 ]] && fail "T05 -- output (a) differs between run 1 and run 2 (non-determinism)"
    [[ "$b_diff" -eq 1 ]] && fail "T05 -- output (b) differs between run 1 and run 2 (non-determinism)"
    if [[ "$VERBOSE" -eq 1 ]]; then
      [[ "$a_diff" -eq 1 ]] && echo "--- output (a) diff ---" && diff "$OUT_A_R1" "$OUT_A_R2" || true
      [[ "$b_diff" -eq 1 ]] && echo "--- output (b) diff ---" && diff "$OUT_B_R1" "$OUT_B_R2" || true
    fi
  fi
fi

# ============================================================
# T06 -- Hollow substrate shape (mechanical substrate only; NOT a numeric score).
#
# CAL-2 hollowness is irreducible LLM judgment -- no shipped script emits a
# hollowness signal. CI asserts ONLY the mechanical substrate: hollow-thin.md
# exists with sources: [] in its frontmatter (the shape the M2 Anatomy reviewer
# reads at runtime). No numeric pass/fail for hollowness is asserted here.
# ============================================================
log "T06: hollow-thin.md exists with sources: [] (mechanical substrate for CAL-2; no numeric hollowness score asserted)"
HOLLOW_FILE="${FX_KB}/${HOLLOW_THIN_DOC}"
if [[ ! -f "$HOLLOW_FILE" ]]; then
  fail "T06 -- ${HOLLOW_THIN_DOC} does not exist at ${HOLLOW_FILE} (hollow fixture missing)"
else
  # Assert the empty-sources marker is present in frontmatter (sources: []).
  if grep -qF "sources: []" "$HOLLOW_FILE" 2>/dev/null; then
    pass "T06 -- ${HOLLOW_THIN_DOC} has sources: [] in frontmatter (hollow-thin substrate present; CAL-2 judgment boundary respected -- no numeric hollowness score asserted)"
  else
    fail "T06 -- ${HOLLOW_THIN_DOC} does not contain 'sources: []' in frontmatter (fixture shape mismatch)"
    [[ "$VERBOSE" -eq 1 ]] && head -10 "$HOLLOW_FILE" || true
  fi
fi

# ============================================================
# T07 -- Transcription substrate shape (runtime-judgment substrate; NOT a ratio).
#
# Post-delivery-009, CAL-1 transcription is a runtime M2 Anatomy reviewer judgment
# from the doc text (corroborated by output (b)), NOT a mechanical overlap ratio.
# The retired output (c) used to emit a numeric ratio; it no longer exists.
# CI asserts ONLY that the transcription substrate the reviewer reads is present:
# transcription-fat.md exists with a non-empty (local-file) sources: frontmatter.
# No numeric overlap ratio is asserted.
# ============================================================
log "T07: transcription-fat.md exists with a sources: frontmatter (runtime substrate for CAL-1; no numeric overlap ratio asserted)"
FAT_FILE="${FX_KB}/${TRANSCRIPTION_FAT_DOC}"
if [[ ! -f "$FAT_FILE" ]]; then
  fail "T07 -- ${TRANSCRIPTION_FAT_DOC} does not exist at ${FAT_FILE} (transcription fixture missing)"
else
  # The doc must declare a sources: entry (so the reviewer has a source to judge
  # transcription against). Accept either an inline list with a non-empty entry or
  # a block list; reject an empty 'sources: []'.
  fat_sources_line="$(grep -E '^sources:' "$FAT_FILE" 2>/dev/null | head -1 || true)"
  if [[ -z "$fat_sources_line" ]]; then
    fail "T07 -- ${TRANSCRIPTION_FAT_DOC} has no 'sources:' frontmatter line (cannot anchor CAL-1 judgment)"
    [[ "$VERBOSE" -eq 1 ]] && head -12 "$FAT_FILE" || true
  elif echo "$fat_sources_line" | grep -qE 'sources:[[:space:]]*\[\][[:space:]]*$'; then
    fail "T07 -- ${TRANSCRIPTION_FAT_DOC} has empty 'sources: []' (a transcription substrate needs a source to copy from)"
  else
    pass "T07 -- ${TRANSCRIPTION_FAT_DOC} declares a non-empty sources: (runtime substrate for CAL-1 transcription judgment; no mechanical ratio asserted after delivery-009)"
  fi
fi

# ---------------------------------------------------------------------------
# ISO-CANARY: assert no .aid dir escaped from the throwaway HOME into real HOME.
# Real HOME may already contain .aid dirs (CI: repo checkout under $HOME).
# We assert the SET of .aid dirs in real HOME did not GROW during this suite.
# ---------------------------------------------------------------------------
echo ""
echo "=== Isolation canary: real HOME untouched ==="
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_AFTER}" == "${_CANARY_BEFORE}" ]]; then
  pass "ISO-CANARY -- real HOME (${REAL_HOME}) gained no .aid dirs (no scan escaped throwaway HOME)"
else
  _CANARY_NEW="$(comm -13 <(printf '%s\n' "${_CANARY_BEFORE}") <(printf '%s\n' "${_CANARY_AFTER}") 2>/dev/null || true)"
  fail "ISO-CANARY -- real HOME blast surface: NEW .aid dirs appeared under ${REAL_HOME}: ${_CANARY_NEW}"
fi

# ---------------------------------------------------------------------------
test_summary
exit $?
