#!/usr/bin/env bash
# test-essence-capture.sh -- AC2/AC3 essence-capture regression suite (f012 TEST-A).
#
# Exercises f004's shipped harvest-coined-terms.sh and closure-check.sh over the
# task-031 kb-essence fixtures (relative-bus / closed-kb / unclosed-kb) and asserts
# the V-A1..V-A6 acceptance criteria from feature-012 SPEC TEST-A.
#
# Assertions:
#   T01  V-A1: harvest surfaces "Relative Bus" in candidate-concepts.md with Spread >= 2.
#   T02  V-A2: "Relative Bus" row is present (phrase-salience escape, NOT joined token).
#   T03  V-A3: "Relative Bus" is emitted and single-channel capitalized noise stays below
#              the candidate-count cap (precision / SPIKE-H2 floor pinning).
#   T04  V-A4: closure-check over closed-kb/ reports ZERO ungrounded terms.
#   T05  V-A5: closure-check over unclosed-kb/ reports "Relative Bus" as ungrounded.
#   T06  V-A6: re-running harvest is byte-identical (determinism, NFR-3).
#   ISO-CANARY: real HOME gained no .aid dirs during the suite run.
#
# SPIKE-H2 floor pinned: the phrase-salience escape floor is spread >= 2.
#   - Recall:    "Relative Bus" survives at spread >= 2 (empirically: spread=3 on
#                code+comments+docs channels in the planted fixture).
#   - Precision: single-channel capitalized common-word phrases (e.g. "The System",
#                "Widget Core") have spread=1 and do NOT survive the phrase floor.
#   The floor value (spread >= 2) is f004's shipped default and is pinned by T01/T02/T03.
#   The single-channel noise count within the candidate list cap (default --top 60)
#   is the V-A3 candidate-count cap assertion.
#
# Isolation discipline (load-bearing):
#   - HOME is pinned to a throwaway dir before any script invocation.
#   - Real-HOME .aid canary snapshot taken before/after (ISO-CANARY assertion).
#   - Every invocation passes an explicit --root / --concepts / --spine / --kb-dir.
#   - The committed fixtures are NEVER mutated: the harvest writes into a mktemp copy.
#   - The repo root is NEVER used as --root.
#
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob, line 33).
# Pattern: test-doc-set-mapping.sh (set -u, source assert.sh, numbered Ts, mktemp,
#           trap EXIT, test_summary / exit $?).
#
# Usage:
#   bash tests/canonical/test-essence-capture.sh [--verbose]
#   HOME=$(mktemp -d) bash tests/canonical/test-essence-capture.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT_HARVEST="${REPO}/canonical/aid/scripts/kb/harvest-coined-terms.sh"
SUT_CLOSURE="${REPO}/canonical/aid/scripts/kb/closure-check.sh"
DENYLIST="${REPO}/canonical/aid/scripts/kb/coined-term-denylist.txt"

# Committed fixture directories (read-only inputs -- never written to).
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/kb-essence"
FX_RELATIVE_BUS="${FIXTURES_BASE}/relative-bus"
FX_CLOSED_KB="${FIXTURES_BASE}/closed-kb"
FX_UNCLOSED_KB="${FIXTURES_BASE}/unclosed-kb"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-essence-capture.sh =="

# ---------------------------------------------------------------------------
# Guard: required scripts and fixtures must exist.
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT_HARVEST" ]]; then
  echo "FATAL: harvest-coined-terms.sh not found at $SUT_HARVEST" >&2
  exit 2
fi
if [[ ! -f "$SUT_CLOSURE" ]]; then
  echo "FATAL: closure-check.sh not found at $SUT_CLOSURE" >&2
  exit 2
fi
if [[ ! -f "$DENYLIST" ]]; then
  echo "FATAL: coined-term-denylist.txt not found at $DENYLIST" >&2
  exit 2
fi
if [[ ! -d "$FX_RELATIVE_BUS" ]]; then
  echo "FATAL: relative-bus fixture not found at $FX_RELATIVE_BUS" >&2
  exit 2
fi
if [[ ! -d "$FX_CLOSED_KB" ]]; then
  echo "FATAL: closed-kb fixture not found at $FX_CLOSED_KB" >&2
  exit 2
fi
if [[ ! -d "$FX_UNCLOSED_KB" ]]; then
  echo "FATAL: unclosed-kb fixture not found at $FX_UNCLOSED_KB" >&2
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

# All cleanup: remove scratch AND the throwaway HOME.
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Copy the relative-bus fixture into a fresh scratch dir and run harvest.
# The harvest writes candidate-concepts.md inside the scratch.
# Usage: run_harvest <scratch_dir> <output_file>
run_harvest() {
  local root="$1"
  local out="$2"
  SOURCE_DATE_EPOCH=1750000000 \
  HOME="$FAKE_HOME" \
  bash "$SUT_HARVEST" \
    --root "$root" \
    --output "$out" \
    --denylist "$DENYLIST" \
    2>/dev/null
}

# Run closure-check against a fixture KB.
# Usage: run_closure <concepts_file> <spine_file> <kb_dir> <out_a_file>
run_closure() {
  local concepts="$1"
  local spine="$2"
  local kb_dir="$3"
  local out_a="$4"
  HOME="$FAKE_HOME" \
  bash "$SUT_CLOSURE" \
    --root "$TMP" \
    --concepts "$concepts" \
    --spine "$spine" \
    --kb-dir "$kb_dir" \
    --denylist "$DENYLIST" \
    --output-a "$out_a" \
    2>/dev/null
}

# ---------------------------------------------------------------------------
# Setup: make a mktemp copy of the relative-bus fixture for harvest to write into.
# The committed fixture tree is never mutated.
# ---------------------------------------------------------------------------
HARVEST_SCRATCH="${TMP}/relative-bus-copy"
cp -r "$FX_RELATIVE_BUS/." "$HARVEST_SCRATCH/"

CANDIDATES_R1="${TMP}/candidates_r1.md"

log "Running harvest (run 1) over relative-bus fixture copy..."
run_harvest "$HARVEST_SCRATCH" "$CANDIDATES_R1"

# ============================================================
# T01 -- V-A1: "Relative Bus" appears in candidate-concepts.md with Spread >= 2.
#
# SPIKE-H2 floor: the phrase-salience escape floor is spread >= 2.
# Empirically measured: "Relative Bus" surfaces with spread=3 (code+comments+docs)
# in the planted fixture. The assertion is spread >= 2 (the floor), not the
# specific spread=3 (which is fixture-specific count, not the floor contract).
# ============================================================
log "T01: V-A1 -- Relative Bus in candidates with Spread >= 2"
if [[ ! -f "$CANDIDATES_R1" ]]; then
  fail "T01 V-A1 -- candidate-concepts.md was not produced by harvest"
else
  # Find the Relative Bus row in the Ranked Candidates table.
  rb_row="$(grep -F 'Relative Bus' "$CANDIDATES_R1" | grep -v '^#' | grep -v '^>' | grep '|' | head -1 || true)"
  if [[ -z "$rb_row" ]]; then
    fail "T01 V-A1 -- 'Relative Bus' row not found in candidate-concepts.md"
  else
    # Extract the Spread column (field 7 in the pipe-table: # | Source | Term | Class | Freq | Spread | ...)
    rb_spread="$(echo "$rb_row" | awk -F'|' '{gsub(/[[:space:]]/,"",$7); print $7}')"
    if [[ -n "$rb_spread" ]] && [[ "$rb_spread" -ge 2 ]] 2>/dev/null; then
      pass "T01 V-A1 -- 'Relative Bus' present with Spread=${rb_spread} (>= 2)"
    else
      fail "T01 V-A1 -- expected Spread >= 2 for 'Relative Bus', got '${rb_spread}' (row: ${rb_row})"
    fi
  fi
fi

# ============================================================
# T02 -- V-A2: The phrase "Relative Bus" survives via f004's phrase-salience escape,
#   NOT a joined-token allowlist.
#
#   - "Relative Bus" must be present as a phrase row with spread >= 2.
#   - Both component words ("relative", "bus") are in the denylist.
#   - The joined token "RelativeBus" (CamelCase) may ALSO be emitted (E2 split-and-keep),
#     but the asserted survival mechanism is the phrase "Relative Bus" with spread >= 2.
#   - We confirm "Relative Bus" (the phrase) is in the candidates list; we do NOT require
#     that "RelativeBus" is absent (f004 legitimately emits the camel form too).
# ============================================================
log "T02: V-A2 -- phrase 'Relative Bus' survives via phrase-salience escape (spread >= 2)"
if [[ -f "$CANDIDATES_R1" ]]; then
  # The phrase row: look for a row where the Term column contains "Relative Bus" (quoted)
  # and the class is "phrase" (not camel).
  rb_phrase_row="$(grep '| harvest |' "$CANDIDATES_R1" | grep '`Relative Bus`' | grep 'phrase' | head -1 || true)"
  if [[ -n "$rb_phrase_row" ]]; then
    phrase_spread="$(echo "$rb_phrase_row" | awk -F'|' '{gsub(/[[:space:]]/,"",$7); print $7}')"
    if [[ -n "$phrase_spread" ]] && [[ "$phrase_spread" -ge 2 ]] 2>/dev/null; then
      pass "T02 V-A2 -- phrase 'Relative Bus' (class=phrase) survived at Spread=${phrase_spread} >= 2 (phrase-salience escape)"
    else
      fail "T02 V-A2 -- phrase 'Relative Bus' found but Spread='${phrase_spread}' < 2 (escape should not fire at spread < 2)"
    fi
  else
    fail "T02 V-A2 -- phrase 'Relative Bus' with class=phrase not found in candidates (phrase-salience escape may not have fired)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- candidates excerpt ---" && grep 'Relative Bus' "$CANDIDATES_R1" || true
  fi
fi

# ============================================================
# T03 -- V-A3: "Relative Bus" is emitted (not buried under noise); single-channel
#   capitalized common-word phrase noise stays below the candidate-count cap.
#
#   SPIKE-H2 precision assertion:
#   - The phrase-salience floor (spread >= 2) ensures that single-channel capitalized
#     common-word phrases (e.g. "The System", "Widget Core") do NOT survive the escape
#     because their spread = 1.
#   - Concrete cap: in the small relative-bus fixture the default --top 60 emits the
#     multi-channel cross-source candidates first; the emitted list must contain
#     "Relative Bus" AND must NOT contain single-channel E4 phrase noise as cross-source
#     (any single-channel phrase noise that appears will have spread=1 and is noise, not
#     a cross-source candidate).
#   - We assert:
#       (a) "Relative Bus" is present in the emitted table.
#       (b) No phrase row with spread=1 appears ABOVE "Relative Bus" in the ranked list
#           (i.e. "Relative Bus" is not buried under single-channel noise).
# ============================================================
log "T03: V-A3 -- 'Relative Bus' is not buried; single-channel phrase noise stays below floor"
if [[ -f "$CANDIDATES_R1" ]]; then
  # (a) Relative Bus must be present in emitted candidates.
  rb_present="$(grep -cF 'Relative Bus' "$CANDIDATES_R1" 2>/dev/null || true)"
  if [[ "$rb_present" -ge 1 ]]; then
    pass "T03a V-A3 -- 'Relative Bus' is emitted in the candidate list (not buried)"
  else
    fail "T03a V-A3 -- 'Relative Bus' not found in emitted candidates (buried or dropped)"
  fi

  # (b) Single-channel phrase noise must NOT appear above Relative Bus in the ranked list.
  # Find the rank (row number) of the "Relative Bus" phrase row.
  rb_rank="$(grep -n '`Relative Bus`' "$CANDIDATES_R1" | head -1 | cut -d: -f1 || true)"

  # Identify single-channel phrase noise rows (class=phrase, spread=1) that appear
  # before the Relative Bus row. These would violate the precision guarantee.
  # We grep for pipe rows before rb_rank that match phrase+spread=1.
  noise_above=0
  if [[ -n "$rb_rank" ]]; then
    # Extract rows before rb_rank, look for phrase rows with spread column = 1
    noise_above="$(head -n "$rb_rank" "$CANDIDATES_R1" | grep '| harvest |' | grep 'phrase' | awk -F'|' '{gsub(/[[:space:]]/,"",$7); if ($7=="1") print}' | wc -l | tr -d ' ' || true)"
  fi

  if [[ "$noise_above" -eq 0 ]]; then
    pass "T03b V-A3 -- no single-channel phrase noise appears above 'Relative Bus' in ranked output (phrase floor = spread >= 2 is sufficient)"
  else
    fail "T03b V-A3 -- $noise_above single-channel phrase noise row(s) appear above 'Relative Bus' (precision violation: phrase-salience floor may be too low)"
  fi
fi

# ============================================================
# T04 -- V-A4: closure-check over closed-kb/ reports ZERO ungrounded terms.
#
#   The closed-kb fixture defines "Relative Bus" and "RelativeME" in its spine.
#   Output (a) of closure-check must have no data rows (empty ungrounded set).
#   This is the AC2(b) "captures AND defines" + AC3 self-containment proof.
# ============================================================
log "T04: V-A4 -- closure-check over closed-kb reports zero ungrounded terms"
CLOSED_OUT_A="${TMP}/closed_out_a.md"
run_closure \
  "${FX_CLOSED_KB}/generated/candidate-concepts.md" \
  "${FX_CLOSED_KB}/knowledge/domain-glossary.md" \
  "${FX_CLOSED_KB}/knowledge" \
  "$CLOSED_OUT_A"

if [[ -f "$CLOSED_OUT_A" ]]; then
  # Count pipe rows in output (a): 2 header rows (columns + separator), 0 data rows expected.
  total_pipe_rows_closed="$(grep -cE '^\|' "$CLOSED_OUT_A" 2>/dev/null || true)"
  data_rows_closed=$(( total_pipe_rows_closed - 2 ))
  if [[ "$data_rows_closed" -le 0 ]]; then
    pass "T04 V-A4 -- closed-kb output (a) is empty (zero ungrounded terms: concept closure PASSES)"
  else
    fail "T04 V-A4 -- closed-kb expected 0 ungrounded rows, got ${data_rows_closed} (closure should PASS)"
    [[ "$VERBOSE" -eq 1 ]] && cat "$CLOSED_OUT_A"
  fi
else
  fail "T04 V-A4 -- closure-check did not produce output-a for closed-kb"
fi

# ============================================================
# T05 -- V-A5: closure-check over unclosed-kb/ reports "Relative Bus" as ungrounded.
#
#   The unclosed-kb spine OMITS the "Relative Bus" definition; architecture.md USES it.
#   Output (a) MUST report "relative bus" in the ungrounded set.
#   This is the regression guard: if a future change drops the concept from harvest/spine,
#   this test turns red.
# ============================================================
log "T05: V-A5 -- closure-check over unclosed-kb reports 'Relative Bus' as ungrounded"
UNCLOSED_OUT_A="${TMP}/unclosed_out_a.md"
run_closure \
  "${FX_UNCLOSED_KB}/generated/candidate-concepts.md" \
  "${FX_UNCLOSED_KB}/knowledge/domain-glossary.md" \
  "${FX_UNCLOSED_KB}/knowledge" \
  "$UNCLOSED_OUT_A"

if [[ -f "$UNCLOSED_OUT_A" ]]; then
  if grep -qiF "relative bus" "$UNCLOSED_OUT_A" 2>/dev/null; then
    pass "T05 V-A5 -- unclosed-kb output (a) reports 'relative bus' as ungrounded (regression guard ACTIVE)"
  else
    fail "T05 V-A5 -- unclosed-kb output (a) does NOT contain 'relative bus' (regression guard BROKEN)"
    [[ "$VERBOSE" -eq 1 ]] && cat "$UNCLOSED_OUT_A"
  fi
else
  fail "T05 V-A5 -- closure-check did not produce output-a for unclosed-kb"
fi

# ============================================================
# T06 -- V-A6: determinism -- re-running harvest is byte-identical.
#
#   Run harvest a second time over the same fixture copy (no mutation between runs).
#   diff the two output files. Any difference is a non-determinism bug.
#   SOURCE_DATE_EPOCH is pinned to suppress wall-clock date variance.
# ============================================================
log "T06: V-A6 -- harvest is byte-identical on re-run (determinism)"
HARVEST_SCRATCH2="${TMP}/relative-bus-copy2"
cp -r "$FX_RELATIVE_BUS/." "$HARVEST_SCRATCH2/"

CANDIDATES_R2="${TMP}/candidates_r2.md"
run_harvest "$HARVEST_SCRATCH2" "$CANDIDATES_R2"

if diff -q "$CANDIDATES_R1" "$CANDIDATES_R2" >/dev/null 2>&1; then
  pass "T06 V-A6 -- harvest output is byte-identical across two runs (determinism confirmed)"
else
  fail "T06 V-A6 -- harvest output differs between runs (non-determinism)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$CANDIDATES_R1" "$CANDIDATES_R2" || true
fi

# ============================================================
# ISO-CANARY: assert no .aid dir escaped from the throwaway HOME into the real HOME.
# Real HOME may already contain .aid dirs (CI: repo checkout under $HOME).
# We assert the set of .aid dirs in real HOME did not GROW during this suite.
# ============================================================
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
