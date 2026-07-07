#!/usr/bin/env bash
# test-path-fixtures.sh -- AC7 path-classification regression suite (f012 TEST-D).
#
# Exercises f006's shipped recon-classify.sh over the task-033 path fixtures and
# asserts V-D1..V-D7 from feature-012 SPEC TEST-D.
#
# Assertions:
#   T01  V-D1  Greenfield DETECTION (classification only): greenfield (~0-source)
#              fixture -> recon proposes GREENFIELD. This is the ONLY greenfield
#              assertion -- greenfield is detect-and-signpost; there is no greenfield
#              path-runs/closure assertion (the old V-D1 greenfield path assertion
#              collapses into this detection-only check).
#   T02  V-D2  brownfield-small fixture -> recon proposes BROWNFIELD-SMALL.
#   T03  V-D3  brownfield-loc-only fixture (single-dimension LOC): recon proposes
#              BROWNFIELD-LARGE and ONLY RM2 >= large_min_source_loc (20000) trips.
#              RM3 < 25 and RM4 < 40: the other two OR-branches do NOT fire.
#              This independently proves the LOC OR-branch flips small->large.
#   T04  V-D4  brownfield-dirs-only fixture (single-dimension dirs): recon proposes
#              BROWNFIELD-LARGE and ONLY RM3 >= large_min_dirs (25) trips independently.
#              RM2 < 20000 and RM4 < 40: the other two OR-branches do NOT fire.
#              This independently proves the dirs OR-branch flips small->large.
#   T05  V-D5  brownfield-concepts-only fixture (single-dimension concepts): recon proposes
#              BROWNFIELD-LARGE and ONLY RM4 >= large_min_concepts (40) trips independently.
#              RM2 < 20000 and RM3 < 25: the other two OR-branches do NOT fire.
#              This independently proves the concepts OR-branch flips small->large.
#   T06  V-D6  Determinism: two successive recon-classify runs over the same
#              fixture copy produce byte-identical output (diff clean).
#   T07  V-D7  Shipped-defaults parity: the fixture paths/settings.yml triage.*
#              values are byte-identical to the shipped canonical/aid/templates/settings.yml
#              triage.* block -- so V-D1..V-D5 pin the SHIPPED defaults, not a
#              drifted fixture copy.
#   ISO-CANARY  Real HOME gained no .aid dirs during the suite run.
#
# f006 SPIKE-T1 floor values pinned (the oracle contract):
#   greenfield_max_source_files: 5   -- greenfield fixture RM1=2 (2 <= 5, gate satisfied)
#   greenfield_max_source_loc:   500 -- greenfield fixture RM2=100 (100 <= 500, gate satisfied)
#   large_min_source_loc:        20000 -- brownfield-loc-only RM2=25000 (25000 >= 20000); ONLY LOC trips
#   large_min_dirs:              25   -- brownfield-dirs-only RM3=30 (30 >= 25); ONLY dirs trips
#   large_min_concepts:          40   -- brownfield-concepts-only RM4=45 (45 >= 40); ONLY concepts trips
#   brownfield-small RM1=15,RM2=5000,RM3=8,RM4=10: above greenfield ceilings, below all large floors
#
# Per-dimension isolation contract (load-bearing for T03/T04/T05):
#   brownfield-loc-only:      RM2=25000 (>= 20000 TRIPS), RM3=5  (< 25 NO), RM4=10 (< 40 NO)
#   brownfield-dirs-only:     RM2=15000 (< 20000 NO),     RM3=30 (>= 25 TRIPS), RM4=10 (< 40 NO)
#   brownfield-concepts-only: RM2=5000  (< 20000 NO),     RM3=8  (< 25 NO), RM4=45 (>= 40 TRIPS)
# Each T03/T04/T05 asserts both the POSITIVE (the one OR-branch fires) and NEGATIVE (other
# two OR-branches below floor). A regression where one OR-branch stops contributing the LARGE
# verdict is caught: removing the LOC branch from the classifier would fail T03 negative
# assertions but T04/T05 would still pass -- the isolation catches which branch broke.
#
# These floors are NOT held in this file -- they live in canonical/aid/templates/settings.yml
# (f006, delivery-004). V-D7 keeps the fixture settings.yml honest against the shipped values.
# If a shipped default mis-bins a fixture, the default is changed in f006's shipped file; this
# suite re-asserts. This task only PINS via assertions; it never holds or edits the default.
#
# Isolation discipline (load-bearing):
#   - HOME is pinned to a throwaway dir before any script invocation.
#   - Real-HOME .aid canary snapshots taken before/after (ISO-CANARY).
#   - recon-classify.sh invoked with explicit --index/--candidates/--settings
#     (never cwd/$HOME defaults, never live .aid/settings.yml).
#   - --settings resolves to the mktemp copy of paths/settings.yml (shipped defaults,
#     parity-guarded by V-D7/T07). No suite ever reads the live repo settings.
#   - mktemp -d scratch + trap EXIT cleanup; committed fixtures are never mutated.
#   - Repo root is never used as --root (no repo scan).
#
# Scope boundary -- greenfield is DETECTION-ONLY:
#   Greenfield was de-scoped to detect-and-signpost on 2026-06-23. T01 asserts
#   the classifier detects the ~0-source fixture as GREENFIELD (classification only).
#   There is NO greenfield path-runs/closure assertion -- greenfield is detect-and-
#   signpost, not a generation path. No reference to the defunct pre-act-back
#   greenfield-path delivery-009 (distinct from the current live delivery-009 Governance).
#
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob, line 33).
# Pattern: test-doc-set-mapping.sh (set -u, source assert.sh, numbered Ts, mktemp,
#           trap EXIT, test_summary / exit $?).
#
# Usage:
#   bash tests/canonical/test-path-fixtures.sh [--verbose]
#   HOME=$(mktemp -d) bash tests/canonical/test-path-fixtures.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/recon-classify.sh"

# Committed fixture directories (read-only inputs -- never written to).
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/kb-essence"
FX_PATHS="${FIXTURES_BASE}/paths"
FX_GREENFIELD="${FX_PATHS}/greenfield/generated"
FX_SMALL="${FX_PATHS}/brownfield-small/generated"
FX_LARGE="${FX_PATHS}/brownfield-large/generated"
FX_LOC_ONLY="${FX_PATHS}/brownfield-loc-only/generated"
FX_DIRS_ONLY="${FX_PATHS}/brownfield-dirs-only/generated"
FX_CONCEPTS_ONLY="${FX_PATHS}/brownfield-concepts-only/generated"
FX_SETTINGS="${FX_PATHS}/settings.yml"

# Shipped settings for V-D7 parity check.
SHIPPED_SETTINGS="${REPO}/canonical/aid/templates/settings.yml"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-path-fixtures.sh =="

# ---------------------------------------------------------------------------
# Guard: required scripts and fixtures must exist.
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: recon-classify.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "${FX_GREENFIELD}/project-index.md" ]]; then
  echo "FATAL: greenfield project-index.md not found at ${FX_GREENFIELD}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_GREENFIELD}/candidate-concepts.md" ]]; then
  echo "FATAL: greenfield candidate-concepts.md not found at ${FX_GREENFIELD}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "${FX_SMALL}/project-index.md" ]]; then
  echo "FATAL: brownfield-small project-index.md not found at ${FX_SMALL}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_SMALL}/candidate-concepts.md" ]]; then
  echo "FATAL: brownfield-small candidate-concepts.md not found at ${FX_SMALL}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "${FX_LARGE}/project-index.md" ]]; then
  echo "FATAL: brownfield-large project-index.md not found at ${FX_LARGE}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_LARGE}/candidate-concepts.md" ]]; then
  echo "FATAL: brownfield-large candidate-concepts.md not found at ${FX_LARGE}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "${FX_LOC_ONLY}/project-index.md" ]]; then
  echo "FATAL: brownfield-loc-only project-index.md not found at ${FX_LOC_ONLY}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_LOC_ONLY}/candidate-concepts.md" ]]; then
  echo "FATAL: brownfield-loc-only candidate-concepts.md not found at ${FX_LOC_ONLY}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "${FX_DIRS_ONLY}/project-index.md" ]]; then
  echo "FATAL: brownfield-dirs-only project-index.md not found at ${FX_DIRS_ONLY}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_DIRS_ONLY}/candidate-concepts.md" ]]; then
  echo "FATAL: brownfield-dirs-only candidate-concepts.md not found at ${FX_DIRS_ONLY}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "${FX_CONCEPTS_ONLY}/project-index.md" ]]; then
  echo "FATAL: brownfield-concepts-only project-index.md not found at ${FX_CONCEPTS_ONLY}/project-index.md" >&2
  exit 2
fi
if [[ ! -f "${FX_CONCEPTS_ONLY}/candidate-concepts.md" ]]; then
  echo "FATAL: brownfield-concepts-only candidate-concepts.md not found at ${FX_CONCEPTS_ONLY}/candidate-concepts.md" >&2
  exit 2
fi
if [[ ! -f "$FX_SETTINGS" ]]; then
  echo "FATAL: fixture paths/settings.yml not found at $FX_SETTINGS" >&2
  exit 2
fi
if [[ ! -f "$SHIPPED_SETTINGS" ]]; then
  echo "FATAL: shipped canonical/aid/templates/settings.yml not found at $SHIPPED_SETTINGS" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# HOME pin + isolation canary setup.
# Snapshot real-HOME .aid dirs BEFORE the suite runs so the canary can detect
# any escape. Real HOME may already hold .aid dirs under CI -- per
# [[ci-runs-as-root-repo-under-home]] the CI checkout lives under $HOME.
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"

TMP="$(mktemp -d)"
FAKE_HOME="${TMP}/fakehome"
mkdir -p "$FAKE_HOME"

# Cleanup: remove scratch AND the throwaway HOME on exit.
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Helper: make a fresh mktemp copy of the paths/ fixture tree.
# The copy includes settings.yml and all three fixture subdirs.
# The committed fixture tree is NEVER written to; runs use this scratch copy.
# ---------------------------------------------------------------------------
_COPY_N=0
make_paths_copy() {
  _COPY_N=$((_COPY_N + 1))
  local dest="${TMP}/paths-copy-${_COPY_N}"
  mkdir -p "${dest}/greenfield/generated"
  mkdir -p "${dest}/brownfield-small/generated"
  mkdir -p "${dest}/brownfield-large/generated"
  mkdir -p "${dest}/brownfield-loc-only/generated"
  mkdir -p "${dest}/brownfield-dirs-only/generated"
  mkdir -p "${dest}/brownfield-concepts-only/generated"
  cp "${FX_GREENFIELD}/project-index.md"              "${dest}/greenfield/generated/"
  cp "${FX_GREENFIELD}/candidate-concepts.md"         "${dest}/greenfield/generated/"
  cp "${FX_SMALL}/project-index.md"                   "${dest}/brownfield-small/generated/"
  cp "${FX_SMALL}/candidate-concepts.md"              "${dest}/brownfield-small/generated/"
  cp "${FX_LARGE}/project-index.md"                   "${dest}/brownfield-large/generated/"
  cp "${FX_LARGE}/candidate-concepts.md"              "${dest}/brownfield-large/generated/"
  cp "${FX_LOC_ONLY}/project-index.md"                "${dest}/brownfield-loc-only/generated/"
  cp "${FX_LOC_ONLY}/candidate-concepts.md"           "${dest}/brownfield-loc-only/generated/"
  cp "${FX_DIRS_ONLY}/project-index.md"               "${dest}/brownfield-dirs-only/generated/"
  cp "${FX_DIRS_ONLY}/candidate-concepts.md"          "${dest}/brownfield-dirs-only/generated/"
  cp "${FX_CONCEPTS_ONLY}/project-index.md"           "${dest}/brownfield-concepts-only/generated/"
  cp "${FX_CONCEPTS_ONLY}/candidate-concepts.md"      "${dest}/brownfield-concepts-only/generated/"
  cp "$FX_SETTINGS"                                   "${dest}/settings.yml"
  echo "$dest"
}

# Helper: run recon-classify.sh over a fixture copy.
# Usage: run_recon <fixture_copy> <variant> <output_suffix>
# Sets: RECON_OUT (absolute path to output file).
# variant: greenfield | brownfield-small | brownfield-large
run_recon() {
  local copy="$1"
  local variant="$2"
  local suffix="${3:-}"
  RECON_OUT="${TMP}/recon-${variant}${suffix}.md"
  HOME="$FAKE_HOME" \
  bash "$SUT" \
    --index     "${copy}/${variant}/generated/project-index.md" \
    --candidates "${copy}/${variant}/generated/candidate-concepts.md" \
    --settings  "${copy}/settings.yml" \
    --output    "$RECON_OUT" \
    2>/dev/null
}

# Helper: extract the Proposed path value from a recon.md output.
# Usage: get_proposed_path <recon_output_file>
get_proposed_path() {
  local file="$1"
  # Row format: | Proposed path | GREENFIELD |
  LC_ALL=C awk -F'|' '
    /Proposed path/ {
      for (i=1; i<=NF; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        if ($i ~ /^(GREENFIELD|BROWNFIELD-SMALL|BROWNFIELD-LARGE)$/) {
          print $i; exit
        }
      }
    }
  ' "$file"
}

# Helper: extract a RM metric value from the recon output.
# Usage: get_rm_value <recon_output_file> <rm_label>
# e.g. get_rm_value file "RM2 (source LOC)"
get_rm_value() {
  local file="$1"
  local label="$2"
  # Row format: | RM2 (source LOC) | 25000 |
  LC_ALL=C awk -v lbl="$label" -F'|' '
    index($0, lbl) > 0 {
      for (i=1; i<=NF; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        if ($i ~ /^[0-9]+$/) { print $i+0; exit }
      }
    }
  ' "$file"
}

# Helper: check if a pattern appears in the Tripped thresholds row.
tripped_contains() {
  local file="$1"
  local pattern="$2"
  grep -F "Tripped thresholds" "$file" | grep -qF "$pattern"
}

# ---------------------------------------------------------------------------
# Primary run: used by T01..T05 (path classification assertions).
# One copy, five assertions (greenfield, small, large x3 OR-branches).
# ---------------------------------------------------------------------------
log "Setting up primary fixture copy..."
PATHS_COPY_R1="$(make_paths_copy)"

# ============================================================
# T01 -- V-D1: Greenfield DETECTION (classification only).
#
# The greenfield (~0-source) fixture has RM1=2, RM2=100 (both under the
# greenfield ceilings: greenfield_max_source_files=5, greenfield_max_source_loc=500).
# recon-classify.sh must propose GREENFIELD.
#
# DETECTION-ONLY: this is the only greenfield assertion. Greenfield is detect-and-
# signpost (aid-discover signposts to /aid-describe and halts). There is NO greenfield
# path-runs/closure assertion -- the old greenfield path assertion (formerly carved to
# the defunct pre-act-back greenfield-path delivery-009) collapses into this
# detection-only check. No reference to the defunct delivery is made.
#
# SPIKE-T1 greenfield thresholds pinned:
#   greenfield_max_source_files=5   (RM1=2 satisfies RM1 <= 5)
#   greenfield_max_source_loc=500   (RM2=100 satisfies RM2 <= 500)
# ============================================================
log "T01: V-D1 -- greenfield fixture -> recon proposes GREENFIELD (detection only)"
run_recon "$PATHS_COPY_R1" "greenfield" "_r1"
RECON_GF_R1="$RECON_OUT"

if [[ ! -f "$RECON_GF_R1" ]]; then
  fail "T01 V-D1 -- recon-classify.sh did not produce output for greenfield fixture"
else
  gf_path="$(get_proposed_path "$RECON_GF_R1")"
  if [[ "$gf_path" == "GREENFIELD" ]]; then
    pass "T01 V-D1 -- greenfield fixture classified GREENFIELD (detection confirmed; SPIKE-T1 floors: max_files=5, max_loc=500)"
  else
    fail "T01 V-D1 -- greenfield fixture classified '${gf_path}' instead of GREENFIELD (SPIKE-T1 greenfield detection thresholds: max_files=5, max_loc=500)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_GF_R1" && echo "---"
  fi
fi

# ============================================================
# T02 -- V-D2: brownfield-small fixture -> recon proposes BROWNFIELD-SMALL.
#
# The brownfield-small fixture has RM1=15, RM2=5000, RM3=8, RM4=10.
# - Not greenfield: RM1=15 > 5 and RM2=5000 > 500.
# - Not large: RM2=5000 < 20000, RM3=8 < 25, RM4=10 < 40.
# -> BROWNFIELD-SMALL.
#
# SPIKE-T1 brownfield floors pinned (all under their large floors):
#   large_min_source_loc=20000  (RM2=5000 < 20000: LOC floor not tripped)
#   large_min_dirs=25           (RM3=8 < 25: dirs floor not tripped)
#   large_min_concepts=40       (RM4=10 < 40: concepts floor not tripped)
# ============================================================
log "T02: V-D2 -- brownfield-small fixture -> recon proposes BROWNFIELD-SMALL"
run_recon "$PATHS_COPY_R1" "brownfield-small" "_r1"
RECON_SMALL_R1="$RECON_OUT"

if [[ ! -f "$RECON_SMALL_R1" ]]; then
  fail "T02 V-D2 -- recon-classify.sh did not produce output for brownfield-small fixture"
else
  sm_path="$(get_proposed_path "$RECON_SMALL_R1")"
  if [[ "$sm_path" == "BROWNFIELD-SMALL" ]]; then
    pass "T02 V-D2 -- brownfield-small fixture classified BROWNFIELD-SMALL (SPIKE-T1 brownfield floors: loc=20000, dirs=25, concepts=40)"
  else
    fail "T02 V-D2 -- brownfield-small fixture classified '${sm_path}' instead of BROWNFIELD-SMALL"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_SMALL_R1" && echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T03: V-D3 -- brownfield-loc-only (single-dimension LOC fixture).
#
# This fixture has RM2=25000 (>= 20000 TRIPS), RM3=5 (< 25 NO), RM4=10 (< 40 NO).
# The LOC OR-branch independently flips small->large; the other two do NOT fire.
# recon-classify.sh must propose BROWNFIELD-LARGE with ONLY large_min_source_loc tripped.
#
# Positive assertion (LOC branch fires):
#   - Proposed path == BROWNFIELD-LARGE
#   - RM2 >= 20000
#   - "large_min_source_loc" in Tripped thresholds
# Negative assertions (other two branches do NOT fire):
#   - RM3 < 25 (dirs below floor)
#   - RM4 < 40 (concepts below floor)
#   - "large_min_dirs" NOT in Tripped thresholds
#   - "large_min_concepts" NOT in Tripped thresholds
#
# SPIKE-T1 LOC floor pinned:
#   large_min_source_loc=20000 (brownfield-loc-only RM2=25000 >= 20000: LOC variant trips ALONE)
# ---------------------------------------------------------------------------
log "T03: V-D3 -- brownfield-loc-only (single-dimension LOC): BROWNFIELD-LARGE; only LOC OR-branch fires"
run_recon "$PATHS_COPY_R1" "brownfield-loc-only" "_r1"
RECON_LOC_ONLY_R1="$RECON_OUT"

if [[ ! -f "$RECON_LOC_ONLY_R1" ]]; then
  fail "T03 V-D3 -- recon-classify.sh did not produce output for brownfield-loc-only fixture"
else
  loc_path="$(get_proposed_path "$RECON_LOC_ONLY_R1")"
  loc_rm2="$(get_rm_value "$RECON_LOC_ONLY_R1" "RM2 (source LOC)")"
  loc_rm3="$(get_rm_value "$RECON_LOC_ONLY_R1" "RM3 (directories)")"
  loc_rm4="$(get_rm_value "$RECON_LOC_ONLY_R1" "RM4 (concepts)")"

  # Positive: BROWNFIELD-LARGE + LOC branch trips
  if [[ "$loc_path" != "BROWNFIELD-LARGE" ]]; then
    fail "T03a V-D3 -- brownfield-loc-only classified '${loc_path}' instead of BROWNFIELD-LARGE"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_LOC_ONLY_R1" && echo "---"
  elif [[ -z "$loc_rm2" ]] || [[ "$loc_rm2" -lt 20000 ]]; then
    fail "T03b V-D3 -- RM2=${loc_rm2:-missing} < 20000 (LOC floor not reached in loc-only fixture)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_LOC_ONLY_R1" && echo "---"
  elif ! tripped_contains "$RECON_LOC_ONLY_R1" "large_min_source_loc"; then
    fail "T03c V-D3 -- 'large_min_source_loc' not in Tripped thresholds (LOC OR-branch not reported)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_LOC_ONLY_R1" && echo "---"
  else
    pass "T03+ V-D3 -- brownfield-loc-only classified BROWNFIELD-LARGE; RM2=${loc_rm2} >= 20000 (LOC OR-branch fires; SPIKE-T1 large_min_source_loc=20000 pinned)"
    # Negative: dirs and concepts branches do NOT fire
    if [[ -n "$loc_rm3" ]] && [[ "$loc_rm3" -ge 25 ]]; then
      fail "T03d V-D3 -- RM3=${loc_rm3} >= 25 in loc-only fixture (dirs branch should NOT fire; fixture is misconfigured)"
    else
      pass "T03d V-D3 -- RM3=${loc_rm3:-0} < 25 (dirs OR-branch does NOT fire in LOC-only fixture)"
    fi
    if [[ -n "$loc_rm4" ]] && [[ "$loc_rm4" -ge 40 ]]; then
      fail "T03e V-D3 -- RM4=${loc_rm4} >= 40 in loc-only fixture (concepts branch should NOT fire; fixture is misconfigured)"
    else
      pass "T03e V-D3 -- RM4=${loc_rm4:-0} < 40 (concepts OR-branch does NOT fire in LOC-only fixture)"
    fi
    if tripped_contains "$RECON_LOC_ONLY_R1" "large_min_dirs"; then
      fail "T03f V-D3 -- 'large_min_dirs' unexpectedly in Tripped thresholds for loc-only fixture"
    else
      pass "T03f V-D3 -- 'large_min_dirs' absent from Tripped thresholds (single-dimension LOC isolation confirmed)"
    fi
    if tripped_contains "$RECON_LOC_ONLY_R1" "large_min_concepts"; then
      fail "T03g V-D3 -- 'large_min_concepts' unexpectedly in Tripped thresholds for loc-only fixture"
    else
      pass "T03g V-D3 -- 'large_min_concepts' absent from Tripped thresholds (single-dimension LOC isolation confirmed)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# T04: V-D4 -- brownfield-dirs-only (single-dimension dirs fixture).
#
# This fixture has RM2=15000 (< 20000 NO), RM3=30 (>= 25 TRIPS), RM4=10 (< 40 NO).
# The dirs OR-branch independently flips small->large; the other two do NOT fire.
# recon-classify.sh must propose BROWNFIELD-LARGE with ONLY large_min_dirs tripped.
#
# Positive assertion (dirs branch fires):
#   - Proposed path == BROWNFIELD-LARGE
#   - RM3 >= 25
#   - "large_min_dirs" in Tripped thresholds
# Negative assertions (other two branches do NOT fire):
#   - RM2 < 20000 (LOC below floor)
#   - RM4 < 40 (concepts below floor)
#   - "large_min_source_loc" NOT in Tripped thresholds
#   - "large_min_concepts" NOT in Tripped thresholds
#
# SPIKE-T1 dirs floor pinned:
#   large_min_dirs=25 (brownfield-dirs-only RM3=30 >= 25: dirs variant trips ALONE)
# ---------------------------------------------------------------------------
log "T04: V-D4 -- brownfield-dirs-only (single-dimension dirs): BROWNFIELD-LARGE; only dirs OR-branch fires"
run_recon "$PATHS_COPY_R1" "brownfield-dirs-only" "_r1"
RECON_DIRS_ONLY_R1="$RECON_OUT"

if [[ ! -f "$RECON_DIRS_ONLY_R1" ]]; then
  fail "T04 V-D4 -- recon-classify.sh did not produce output for brownfield-dirs-only fixture"
else
  dirs_path="$(get_proposed_path "$RECON_DIRS_ONLY_R1")"
  dirs_rm2="$(get_rm_value "$RECON_DIRS_ONLY_R1" "RM2 (source LOC)")"
  dirs_rm3="$(get_rm_value "$RECON_DIRS_ONLY_R1" "RM3 (directories)")"
  dirs_rm4="$(get_rm_value "$RECON_DIRS_ONLY_R1" "RM4 (concepts)")"

  # Positive: BROWNFIELD-LARGE + dirs branch trips
  if [[ "$dirs_path" != "BROWNFIELD-LARGE" ]]; then
    fail "T04a V-D4 -- brownfield-dirs-only classified '${dirs_path}' instead of BROWNFIELD-LARGE"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_DIRS_ONLY_R1" && echo "---"
  elif [[ -z "$dirs_rm3" ]] || [[ "$dirs_rm3" -lt 25 ]]; then
    fail "T04b V-D4 -- RM3=${dirs_rm3:-missing} < 25 (dirs floor not reached in dirs-only fixture)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_DIRS_ONLY_R1" && echo "---"
  elif ! tripped_contains "$RECON_DIRS_ONLY_R1" "large_min_dirs"; then
    fail "T04c V-D4 -- 'large_min_dirs' not in Tripped thresholds (dirs OR-branch not reported)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_DIRS_ONLY_R1" && echo "---"
  else
    pass "T04+ V-D4 -- brownfield-dirs-only classified BROWNFIELD-LARGE; RM3=${dirs_rm3} >= 25 (dirs OR-branch fires; SPIKE-T1 large_min_dirs=25 pinned)"
    # Negative: LOC and concepts branches do NOT fire
    if [[ -n "$dirs_rm2" ]] && [[ "$dirs_rm2" -ge 20000 ]]; then
      fail "T04d V-D4 -- RM2=${dirs_rm2} >= 20000 in dirs-only fixture (LOC branch should NOT fire; fixture is misconfigured)"
    else
      pass "T04d V-D4 -- RM2=${dirs_rm2:-0} < 20000 (LOC OR-branch does NOT fire in dirs-only fixture)"
    fi
    if [[ -n "$dirs_rm4" ]] && [[ "$dirs_rm4" -ge 40 ]]; then
      fail "T04e V-D4 -- RM4=${dirs_rm4} >= 40 in dirs-only fixture (concepts branch should NOT fire; fixture is misconfigured)"
    else
      pass "T04e V-D4 -- RM4=${dirs_rm4:-0} < 40 (concepts OR-branch does NOT fire in dirs-only fixture)"
    fi
    if tripped_contains "$RECON_DIRS_ONLY_R1" "large_min_source_loc"; then
      fail "T04f V-D4 -- 'large_min_source_loc' unexpectedly in Tripped thresholds for dirs-only fixture"
    else
      pass "T04f V-D4 -- 'large_min_source_loc' absent from Tripped thresholds (single-dimension dirs isolation confirmed)"
    fi
    if tripped_contains "$RECON_DIRS_ONLY_R1" "large_min_concepts"; then
      fail "T04g V-D4 -- 'large_min_concepts' unexpectedly in Tripped thresholds for dirs-only fixture"
    else
      pass "T04g V-D4 -- 'large_min_concepts' absent from Tripped thresholds (single-dimension dirs isolation confirmed)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# T05: V-D5 -- brownfield-concepts-only (single-dimension concepts fixture).
#
# This fixture has RM2=5000 (< 20000 NO), RM3=8 (< 25 NO), RM4=45 (>= 40 TRIPS).
# The concepts OR-branch independently flips small->large; the other two do NOT fire.
# recon-classify.sh must propose BROWNFIELD-LARGE with ONLY large_min_concepts tripped.
#
# Positive assertion (concepts branch fires):
#   - Proposed path == BROWNFIELD-LARGE
#   - RM4 >= 40
#   - "large_min_concepts" in Tripped thresholds
# Negative assertions (other two branches do NOT fire):
#   - RM2 < 20000 (LOC below floor)
#   - RM3 < 25 (dirs below floor)
#   - "large_min_source_loc" NOT in Tripped thresholds
#   - "large_min_dirs" NOT in Tripped thresholds
#
# SPIKE-T1 concepts floor pinned:
#   large_min_concepts=40 (brownfield-concepts-only RM4=45 >= 40: concepts variant trips ALONE)
# ---------------------------------------------------------------------------
log "T05: V-D5 -- brownfield-concepts-only (single-dimension concepts): BROWNFIELD-LARGE; only concepts OR-branch fires"
run_recon "$PATHS_COPY_R1" "brownfield-concepts-only" "_r1"
RECON_CONCEPTS_ONLY_R1="$RECON_OUT"

if [[ ! -f "$RECON_CONCEPTS_ONLY_R1" ]]; then
  fail "T05 V-D5 -- recon-classify.sh did not produce output for brownfield-concepts-only fixture"
else
  con_path="$(get_proposed_path "$RECON_CONCEPTS_ONLY_R1")"
  con_rm2="$(get_rm_value "$RECON_CONCEPTS_ONLY_R1" "RM2 (source LOC)")"
  con_rm3="$(get_rm_value "$RECON_CONCEPTS_ONLY_R1" "RM3 (directories)")"
  con_rm4="$(get_rm_value "$RECON_CONCEPTS_ONLY_R1" "RM4 (concepts)")"

  # Positive: BROWNFIELD-LARGE + concepts branch trips
  if [[ "$con_path" != "BROWNFIELD-LARGE" ]]; then
    fail "T05a V-D5 -- brownfield-concepts-only classified '${con_path}' instead of BROWNFIELD-LARGE"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_CONCEPTS_ONLY_R1" && echo "---"
  elif [[ -z "$con_rm4" ]] || [[ "$con_rm4" -lt 40 ]]; then
    fail "T05b V-D5 -- RM4=${con_rm4:-missing} < 40 (concepts floor not reached in concepts-only fixture)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_CONCEPTS_ONLY_R1" && echo "---"
  elif ! tripped_contains "$RECON_CONCEPTS_ONLY_R1" "large_min_concepts"; then
    fail "T05c V-D5 -- 'large_min_concepts' not in Tripped thresholds (concepts OR-branch not reported)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- recon output ---" && cat "$RECON_CONCEPTS_ONLY_R1" && echo "---"
  else
    pass "T05+ V-D5 -- brownfield-concepts-only classified BROWNFIELD-LARGE; RM4=${con_rm4} >= 40 (concepts OR-branch fires; SPIKE-T1 large_min_concepts=40 pinned)"
    # Negative: LOC and dirs branches do NOT fire
    if [[ -n "$con_rm2" ]] && [[ "$con_rm2" -ge 20000 ]]; then
      fail "T05d V-D5 -- RM2=${con_rm2} >= 20000 in concepts-only fixture (LOC branch should NOT fire; fixture is misconfigured)"
    else
      pass "T05d V-D5 -- RM2=${con_rm2:-0} < 20000 (LOC OR-branch does NOT fire in concepts-only fixture)"
    fi
    if [[ -n "$con_rm3" ]] && [[ "$con_rm3" -ge 25 ]]; then
      fail "T05e V-D5 -- RM3=${con_rm3} >= 25 in concepts-only fixture (dirs branch should NOT fire; fixture is misconfigured)"
    else
      pass "T05e V-D5 -- RM3=${con_rm3:-0} < 25 (dirs OR-branch does NOT fire in concepts-only fixture)"
    fi
    if tripped_contains "$RECON_CONCEPTS_ONLY_R1" "large_min_source_loc"; then
      fail "T05f V-D5 -- 'large_min_source_loc' unexpectedly in Tripped thresholds for concepts-only fixture"
    else
      pass "T05f V-D5 -- 'large_min_source_loc' absent from Tripped thresholds (single-dimension concepts isolation confirmed)"
    fi
    if tripped_contains "$RECON_CONCEPTS_ONLY_R1" "large_min_dirs"; then
      fail "T05g V-D5 -- 'large_min_dirs' unexpectedly in Tripped thresholds for concepts-only fixture"
    else
      pass "T05g V-D5 -- 'large_min_dirs' absent from Tripped thresholds (single-dimension concepts isolation confirmed)"
    fi
  fi
fi

# ============================================================
# T06 -- V-D6: Determinism -- two successive recon-classify runs are byte-identical.
#
# Run recon-classify.sh a second time over a separate fresh copy of the greenfield
# fixture (the simplest deterministic case). diff the two outputs.
# Any difference is a non-determinism bug.
# ============================================================
log "T06: V-D6 -- recon-classify is byte-identical on re-run (determinism)"
PATHS_COPY_R2="$(make_paths_copy)"
run_recon "$PATHS_COPY_R2" "greenfield" "_r2"
RECON_GF_R2="$RECON_OUT"

if [[ ! -f "${RECON_GF_R1:-}" || ! -f "${RECON_GF_R2:-}" ]]; then
  fail "T06 V-D6 -- one or both runs did not produce output; cannot compare"
else
  if diff -q "$RECON_GF_R1" "$RECON_GF_R2" >/dev/null 2>&1; then
    pass "T06 V-D6 -- recon-classify.sh output is byte-identical across two runs (determinism confirmed)"
  else
    fail "T06 V-D6 -- recon-classify.sh output differs between run 1 and run 2 (non-determinism)"
    [[ "$VERBOSE" -eq 1 ]] && echo "--- diff ---" && diff "$RECON_GF_R1" "$RECON_GF_R2" || true && echo "---"
  fi
fi

# ============================================================
# T07 -- V-D7: Shipped-defaults parity.
#
# The fixture paths/settings.yml triage.* values must be byte-identical to the
# shipped canonical/aid/templates/settings.yml triage.* block.
# This assertion keeps the fixture honest against the shipped defaults, ensuring
# V-D1..V-D5 pin the SHIPPED defaults (not a drifted fixture copy).
#
# Extraction: grep all lines from "^triage:" to the last "large_min_concepts:"
# line (the full triage block) from both files and compare.
# ============================================================
log "T07: V-D7 -- fixture paths/settings.yml triage.* is byte-identical to shipped settings.yml triage.*"

# Extract the triage block from both files.
# Approach: print from "^triage:" until the next top-level key (^[a-z]) or EOF.
# We then strip trailing comments (the # ... parts differ only in whitespace, but
# the actual key: value pairs must match). To be precise: extract the full triage
# block lines verbatim and compare byte-for-byte.
extract_triage_block() {
  local file="$1"
  # Compare the triage key:value pairs only -- NOT comments. Tests must not assert
  # comment text, and the shipped file's inline/standalone comments are free to
  # change; V-D7 pins the shipped DEFAULT VALUES, so strip comments before diffing.
  LC_ALL=C awk '
    /^triage:/ { in_triage=1; print; next }
    in_triage && /^[[:space:]]/ {
      line=$0; sub(/[[:space:]]*#.*$/, "", line); sub(/[[:space:]]+$/, "", line)
      if (line !~ /^[[:space:]]*$/) print line
      next
    }
    in_triage { in_triage=0 }
  ' "$file"
}

TRIAGE_FIXTURE="$(extract_triage_block "$FX_SETTINGS")"
TRIAGE_SHIPPED="$(extract_triage_block "$SHIPPED_SETTINGS")"

if [[ -z "$TRIAGE_FIXTURE" ]]; then
  fail "T07 V-D7 -- no triage block found in fixture paths/settings.yml (extraction failed)"
elif [[ -z "$TRIAGE_SHIPPED" ]]; then
  fail "T07 V-D7 -- no triage block found in shipped canonical/aid/templates/settings.yml (extraction failed)"
elif [[ "$TRIAGE_FIXTURE" == "$TRIAGE_SHIPPED" ]]; then
  pass "T07 V-D7 -- fixture triage.* is byte-identical to shipped triage.* (V-D1..V-D5 pin shipped defaults; no drift)"
else
  fail "T07 V-D7 -- fixture triage.* differs from shipped triage.* (fixture has drifted from shipped defaults -- update fixture or shipped file)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- fixture triage block ---"
    echo "$TRIAGE_FIXTURE"
    echo "--- shipped triage block ---"
    echo "$TRIAGE_SHIPPED"
    echo "---"
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
