#!/usr/bin/env bash
# test-calibration-fixtures.sh -- AC6 calibration regression suite (f012 TEST-B).
#
# Exercises f004's shipped closure-check.sh (outputs (b) coverage table + (c)
# transcription-ratio hint -- f005 ships no coverage script) over the task-032
# calibration fixture and asserts the V-B1/V-B2/V-B4/V-B5 mechanical ACs from
# feature-012 SPEC TEST-B.
#
# Assertions:
#   T01  V-B1  CAL-3 coverage gap flagged (MECHANICAL): closure-check output (b) reports
#              the planted salient term "audit-record contract" as an absent row for
#              coverage-gap.md.
#   T02  V-B2  CAL-1 transcription flagged (MECHANICAL): closure-check output (c)
#              transcription-ratio for transcription-fat.md >= CAL-1 floor (0.500).
#   T03  V-B4  Precision -- control is clean (MECHANICAL): well-calibrated.md produces
#              no absent row in output (b) AND its output (c) ratio < CAL-1 floor (0.500).
#              The calibrated floors do NOT false-positive a good doc.
#   T04  V-B4b Precision -- control ratio separates cleanly from fat: the
#              well-calibrated.md ratio (empirically ~0.266) is < CAL-1 floor (0.500).
#   T05  V-B5  Determinism: two successive closure-check runs over the same fixture
#              copy produce byte-identical output across all three outputs.
#   T06  Hollow substrate shape: hollow-thin.md has sources: [] in frontmatter
#              (the mechanical substrate of the CAL-2 hollowness fixture is present;
#              CI does NOT assert a numeric hollowness score -- that is LLM judgment).
#   ISO-CANARY  Real HOME gained no .aid dirs during the suite run.
#
# Mechanical-vs-judgment boundary (load-bearing):
#   CAL-2 hollowness (V-B3) is NOT a mechanical assertion -- no shipped script emits
#   a hollowness signal. closure-check.sh's 3 outputs are (a) ungrounded, (b) coverage,
#   (c) transcription; none is a hollowness ratio. hollow-thin.md is planted as the
#   runtime-anchored substrate for the Calibration reviewer M5 to grade -- CI only
#   confirms the doc exists with sources: [] (the shape the reviewer reads). No numeric
#   pass/fail is asserted for hollowness.
#
# SPIKE-C1 floor pinned (the oracle contract):
#   CAL-1 transcription-ratio floor = 0.500 (empirically measured 2026-06-23).
#   Empirical evidence:
#     transcription-fat.md overlap-ratio = 0.704  (HIGH -- must be >= floor)
#     well-calibrated.md  overlap-ratio = 0.266  (LOW  -- must be <  floor)
#   The floor value 0.500 cleanly separates the fat doc from the control.
#   V-B2 (flag fat) + T04 V-B4 (do-not-flag control) jointly PIN this floor.
#   Hollowness has NO mechanical floor -- it is LLM judgment (not pinned here).
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
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob, line 33).
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
# SPIKE-C1: CAL-1 transcription-ratio severity floor (empirically pinned).
# This value separates the transcription-fat.md control (0.704) from the
# well-calibrated.md control (0.266). Measured 2026-06-23 via closure-check.sh
# output (c) salient-token overlap ratio on the planted fixture.
# CAL-2 hollowness has NO mechanical floor (LLM judgment, not pinned here).
# ---------------------------------------------------------------------------
CAL1_FLOOR="0.500"

# ---------------------------------------------------------------------------
# Planted salient term for V-B1 (CAL-3 coverage gap).
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
# Sets:  OUT_A, OUT_B, OUT_C (absolute paths to the output files for outputs (a)/(b)/(c)).
run_closure() {
  local kb_copy="$1"
  local suffix="${2:-}"
  OUT_A="${TMP}/out_a${suffix}.md"
  OUT_B="${TMP}/out_b${suffix}.md"
  OUT_C="${TMP}/out_c${suffix}.md"
  HOME="$FAKE_HOME" \
  bash "$SUT" \
    --root "$REPO" \
    --concepts "$FX_CANDIDATES" \
    --kb-dir "$kb_copy" \
    --denylist "$DENYLIST" \
    --output-a "$OUT_A" \
    --output-b "$OUT_B" \
    --output-c "$OUT_C" \
    2>/dev/null
}

# ---------------------------------------------------------------------------
# Helper: compare two awk-format decimal strings.
# awk_ge A B: returns 0 (true) if A >= B, 1 (false) otherwise.
# Uses awk to avoid bash floating-point unavailability.
# ---------------------------------------------------------------------------
awk_ge() {
  local a="$1" b="$2"
  awk -v a="$a" -v b="$b" 'BEGIN { exit (a >= b) ? 0 : 1 }'
}

awk_lt() {
  local a="$1" b="$2"
  awk -v a="$a" -v b="$b" 'BEGIN { exit (a < b) ? 0 : 1 }'
}

# ---------------------------------------------------------------------------
# Run 1: the primary oracle run (used by T01, T02, T03, T04).
# Run 2: the determinism run (used by T05).
# ---------------------------------------------------------------------------
KB_COPY_R1="$(make_kb_copy)"
log "Running closure-check (run 1) over calibration fixture copy..."
run_closure "$KB_COPY_R1" "_r1"
OUT_A_R1="$OUT_A"
OUT_B_R1="$OUT_B"
OUT_C_R1="$OUT_C"

# ============================================================
# T01 -- V-B1: CAL-3 coverage gap flagged (MECHANICAL).
#
# closure-check output (b) must contain an absent row for the planted salient
# term "audit-record contract" in coverage-gap.md.
#
# Planted: coverage-gap.md declares sources: [payment-engine.ts] but its body
# omits "audit-record contract". The term IS in candidate-concepts.md (synthesis
# row) and in the source file's auditability commentary. Output (b) must flag it.
# ============================================================
log "T01: V-B1 -- output (b) reports 'audit-record contract' as absent in coverage-gap.md"
if [[ ! -f "$OUT_B_R1" ]]; then
  fail "T01 V-B1 -- closure-check did not produce output (b)"
else
  # Look for a row: | audit-record contract | coverage-gap.md | ... | absent |
  absent_row="$(grep -iF "$PLANTED_ABSENT_TERM" "$OUT_B_R1" | grep -F "$COVERAGE_GAP_DOC" | grep -v '^#' | grep -v '^|---' || true)"
  if [[ -z "$absent_row" ]]; then
    fail "T01 V-B1 -- no row for '${PLANTED_ABSENT_TERM}' in ${COVERAGE_GAP_DOC} found in output (b)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  elif echo "$absent_row" | grep -qF "absent"; then
    pass "T01 V-B1 -- output (b) reports '${PLANTED_ABSENT_TERM}' as absent in ${COVERAGE_GAP_DOC} (CAL-3 coverage gap flagged)"
  else
    fail "T01 V-B1 -- row for '${PLANTED_ABSENT_TERM}' in ${COVERAGE_GAP_DOC} is not 'absent': ${absent_row}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  fi
fi

# ============================================================
# T02 -- V-B2: CAL-1 transcription flagged (MECHANICAL).
#
# closure-check output (c) transcription-ratio for transcription-fat.md must
# be >= CAL-1 floor (0.500).
#
# Empirically measured: transcription-fat.md overlap-ratio = 0.704.
# SPIKE-C1 floor = 0.500 (cleanly above control ratio of 0.266).
# ============================================================
log "T02: V-B2 -- output (c) transcription-ratio for ${TRANSCRIPTION_FAT_DOC} >= ${CAL1_FLOOR} (CAL-1 floor)"
if [[ ! -f "$OUT_C_R1" ]]; then
  fail "T02 V-B2 -- closure-check did not produce output (c)"
else
  # Find the transcription-fat.md row in output (c).
  fat_row="$(grep -F "$TRANSCRIPTION_FAT_DOC" "$OUT_C_R1" | grep -v '^#' | grep -v '^|---' || true)"
  if [[ -z "$fat_row" ]]; then
    fail "T02 V-B2 -- no output (c) row found for ${TRANSCRIPTION_FAT_DOC}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (c) ---" && cat "$OUT_C_R1" && echo "---"
  else
    # Extract the overlap-ratio column (last pipe-delimited field before the trailing |).
    fat_ratio="$(echo "$fat_row" | awk -F'|' '{
      for (i=NF; i>=1; i--) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        if ($i ~ /^[0-9]+\.[0-9]+$/) { print $i; exit }
      }
    }')"
    if [[ -z "$fat_ratio" ]]; then
      fail "T02 V-B2 -- could not parse overlap-ratio from output (c) row for ${TRANSCRIPTION_FAT_DOC}: ${fat_row}"
    elif awk_ge "$fat_ratio" "$CAL1_FLOOR"; then
      pass "T02 V-B2 -- ${TRANSCRIPTION_FAT_DOC} overlap-ratio=${fat_ratio} >= CAL-1 floor=${CAL1_FLOOR} (transcription flagged)"
    else
      fail "T02 V-B2 -- ${TRANSCRIPTION_FAT_DOC} overlap-ratio=${fat_ratio} < CAL-1 floor=${CAL1_FLOOR} (fat doc should be flagged but is below floor)"
      [[ "$VERBOSE" -eq 1 ]] && echo "--- output (c) ---" && cat "$OUT_C_R1" && echo "---"
    fi
  fi
fi

# ============================================================
# T03 -- V-B4a: Precision -- control has no absent row in output (b).
#
# well-calibrated.md is the CONTROL doc. It covers all salient terms including
# "audit-record contract" (the term IS present in its body). Output (b) must
# produce NO absent row for well-calibrated.md.
# ============================================================
log "T03: V-B4a -- output (b) has no absent row for ${WELL_CALIBRATED_DOC} (control is clean)"
if [[ ! -f "$OUT_B_R1" ]]; then
  fail "T03 V-B4a -- closure-check did not produce output (b)"
else
  # Check for any absent row whose doc column is well-calibrated.md.
  control_absent_rows="$(grep -F "$WELL_CALIBRATED_DOC" "$OUT_B_R1" | grep -v '^#' | grep -v '^|---' | grep -F "absent" || true)"
  if [[ -z "$control_absent_rows" ]]; then
    pass "T03 V-B4a -- output (b) has no absent row for ${WELL_CALIBRATED_DOC} (calibrated floors do not false-positive the control)"
  else
    fail "T03 V-B4a -- output (b) has absent row(s) for ${WELL_CALIBRATED_DOC} (precision violation): ${control_absent_rows}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (b) ---" && cat "$OUT_B_R1" && echo "---"
  fi
fi

# ============================================================
# T04 -- V-B4b: Precision -- control ratio is below CAL-1 floor.
#
# well-calibrated.md output (c) overlap-ratio must be < CAL-1 floor (0.500).
#
# Empirically measured: well-calibrated.md overlap-ratio = 0.266.
# Together with T02, this pins the SPIKE-C1 floor at 0.500: fat >= floor,
# control < floor -- the floor cleanly separates the two docs.
# ============================================================
log "T04: V-B4b -- output (c) transcription-ratio for ${WELL_CALIBRATED_DOC} < ${CAL1_FLOOR} (control below floor)"
if [[ ! -f "$OUT_C_R1" ]]; then
  fail "T04 V-B4b -- closure-check did not produce output (c)"
else
  ctrl_row="$(grep -F "$WELL_CALIBRATED_DOC" "$OUT_C_R1" | grep -v '^#' | grep -v '^|---' || true)"
  if [[ -z "$ctrl_row" ]]; then
    fail "T04 V-B4b -- no output (c) row found for ${WELL_CALIBRATED_DOC}"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- output (c) ---" && cat "$OUT_C_R1" && echo "---"
  else
    ctrl_ratio="$(echo "$ctrl_row" | awk -F'|' '{
      for (i=NF; i>=1; i--) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        if ($i ~ /^[0-9]+\.[0-9]+$/) { print $i; exit }
      }
    }')"
    if [[ -z "$ctrl_ratio" ]]; then
      fail "T04 V-B4b -- could not parse overlap-ratio from output (c) row for ${WELL_CALIBRATED_DOC}: ${ctrl_row}"
    elif awk_lt "$ctrl_ratio" "$CAL1_FLOOR"; then
      pass "T04 V-B4b -- ${WELL_CALIBRATED_DOC} overlap-ratio=${ctrl_ratio} < CAL-1 floor=${CAL1_FLOOR} (control not false-positived: SPIKE-C1 floor=0.500 pinned)"
    else
      fail "T04 V-B4b -- ${WELL_CALIBRATED_DOC} overlap-ratio=${ctrl_ratio} >= CAL-1 floor=${CAL1_FLOOR} (precision violation: control falsely flagged)"
      [[ "$VERBOSE" -eq 1 ]] && echo "--- output (c) ---" && cat "$OUT_C_R1" && echo "---"
    fi
  fi
fi

# ============================================================
# T05 -- V-B5: Determinism -- two successive closure-check runs are byte-identical.
#
# Run closure-check a second time over a separate fresh copy of the fixture.
# diff all three outputs. Any difference is a non-determinism bug.
# ============================================================
log "T05: V-B5 -- closure-check is byte-identical on re-run (determinism)"
KB_COPY_R2="$(make_kb_copy)"
run_closure "$KB_COPY_R2" "_r2"
OUT_A_R2="$OUT_A"
OUT_B_R2="$OUT_B"
OUT_C_R2="$OUT_C"
if [[ ! -f "$OUT_A_R1" || ! -f "$OUT_A_R2" || \
      ! -f "$OUT_B_R1" || ! -f "$OUT_B_R2" || \
      ! -f "$OUT_C_R1" || ! -f "$OUT_C_R2" ]]; then
  fail "T05 V-B5 -- one or both runs did not produce all outputs; cannot compare"
else
  a_diff=0; b_diff=0; c_diff=0
  diff -q "$OUT_A_R1" "$OUT_A_R2" >/dev/null 2>&1 || a_diff=1
  diff -q "$OUT_B_R1" "$OUT_B_R2" >/dev/null 2>&1 || b_diff=1
  diff -q "$OUT_C_R1" "$OUT_C_R2" >/dev/null 2>&1 || c_diff=1
  if [[ "$a_diff" -eq 0 && "$b_diff" -eq 0 && "$c_diff" -eq 0 ]]; then
    pass "T05 V-B5 -- closure-check outputs (a), (b), and (c) are byte-identical across two runs (determinism confirmed)"
  else
    [[ "$a_diff" -eq 1 ]] && fail "T05 V-B5 -- output (a) differs between run 1 and run 2 (non-determinism)"
    [[ "$b_diff" -eq 1 ]] && fail "T05 V-B5 -- output (b) differs between run 1 and run 2 (non-determinism)"
    [[ "$c_diff" -eq 1 ]] && fail "T05 V-B5 -- output (c) differs between run 1 and run 2 (non-determinism)"
    if [[ "$VERBOSE" -eq 1 ]]; then
      [[ "$a_diff" -eq 1 ]] && echo "--- output (a) diff ---" && diff "$OUT_A_R1" "$OUT_A_R2" || true
      [[ "$b_diff" -eq 1 ]] && echo "--- output (b) diff ---" && diff "$OUT_B_R1" "$OUT_B_R2" || true
      [[ "$c_diff" -eq 1 ]] && echo "--- output (c) diff ---" && diff "$OUT_C_R1" "$OUT_C_R2" || true
    fi
  fi
fi

# ============================================================
# T06 -- Hollow substrate shape (mechanical substrate only; NOT a numeric score).
#
# CAL-2 hollowness is irreducible LLM judgment -- no shipped script emits a
# hollowness signal (closure-check.sh outputs (a)/(b)/(c) are ungrounded,
# coverage, transcription -- none is a hollowness ratio).
#
# CI asserts ONLY the mechanical substrate: hollow-thin.md exists with sources: []
# in its frontmatter (the shape the Calibration reviewer M5 reads at runtime).
# No numeric pass/fail for hollowness is asserted here.
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
