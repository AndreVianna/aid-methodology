#!/usr/bin/env bash
# test-recon-classify.sh -- Canonical tests for recon-classify.sh (feature-006).
#
# Tests (RC01-RC13) cover all acceptance criteria from task-024 / feature-006:
#   RC01  Greenfield: near-empty index (RM1<=5, RM2<=500) => GREENFIELD
#   RC02  Brownfield-large by LOC: RM2 >= large_min_source_loc => BROWNFIELD-LARGE
#   RC03  Brownfield-large by dirs: RM3 >= large_min_dirs => BROWNFIELD-LARGE
#   RC04  Brownfield-large by concepts: RM4 >= large_min_concepts => BROWNFIELD-LARGE
#   RC05  Brownfield-small: source present but all large thresholds under floor => BROWNFIELD-SMALL
#   RC06  Conjunctive greenfield gate: 3-file / 50k-LOC is NOT greenfield (=>large)
#   RC07  Threshold override flips verdict on a fixed fixture
#   RC08  Missing/empty candidates => RM4=0, non-error classify (exit 0)
#   RC09  Missing index => warn + BROWNFIELD-SMALL proposal, exit 0
#   RC10  Byte-reproducibility: two runs on same inputs => sha256-identical recon.md (NFR-3)
#   RC11  is_source lockstep: IS_SOURCE_LANGUAGES in recon-classify.sh equals is_source()
#         case labels in build-project-index.sh (drift guard)
#   RC12  Output shape: recon.md has the documented sections and table fields
#   RC13  Tripped-threshold reporting: LOC-trip records correct threshold name
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# HOME-pinned (mktemp -d) to avoid touching the developer's real .aid/.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-recon-classify.sh [--verbose]
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
BPI="${REPO}/canonical/aid/scripts/kb/build-project-index.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-recon-classify.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: recon-classify.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "$BPI" ]]; then
  echo "FATAL: build-project-index.sh not found at $BPI" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Shared setup/teardown
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Helper: build a minimal settings.yml with default triage thresholds
# ---------------------------------------------------------------------------
make_settings() {
  local dir="$1"
  # Optionally override any of the 5 triage keys via additional args:
  #   make_settings DIR [key=val ...]
  # Defaults match the script's built-in defaults.
  local gf_files=5
  local gf_loc=500
  local lg_loc=20000
  local lg_dirs=25
  local lg_concepts=40
  shift
  for kv in "$@"; do
    local k="${kv%%=*}" v="${kv#*=}"
    case "$k" in
      gf_files)    gf_files=$v   ;;
      gf_loc)      gf_loc=$v     ;;
      lg_loc)      lg_loc=$v     ;;
      lg_dirs)     lg_dirs=$v    ;;
      lg_concepts) lg_concepts=$v ;;
    esac
  done
  cat > "${dir}/settings.yml" << EOF
triage:
  greenfield_max_source_files: ${gf_files}
  greenfield_max_source_loc:   ${gf_loc}
  large_min_source_loc:        ${lg_loc}
  large_min_dirs:              ${lg_dirs}
  large_min_concepts:          ${lg_concepts}
EOF
}

# ---------------------------------------------------------------------------
# Helper: build a minimal candidate-concepts.md with a given cross-source count
# ---------------------------------------------------------------------------
make_candidates() {
  local path="$1"
  local cross_source_count="$2"
  cat > "$path" << EOF
# Candidate Concepts

## Summary

| Metric | Value |
|--------|-------|
| Cross-source (spread >= 2) | ${cross_source_count} |
| Total candidates | ${cross_source_count} |
EOF
}

# ---------------------------------------------------------------------------
# Helper: build a project-index.md with given language breakdown + file inventory
#
# Usage: make_index PATH LANG FILES LOC [DIR_LIST...]
#   LANG      - the source language name (e.g. "TypeScript")
#   FILES     - number of source files
#   LOC       - total lines of source
#   DIR_LIST  - optional additional inventory paths (each becomes a row)
#               used to produce distinct top-2-level dir prefixes
# ---------------------------------------------------------------------------
make_index_simple() {
  local path="$1"
  local lang="$2"
  local files="$3"
  local loc="$4"
  shift 4
  local inventory_rows=("$@")

  {
    echo "# Project Index"
    echo ""
    echo "## Language Breakdown"
    echo ""
    echo "| Language | Files | Lines |"
    echo "|----------|-------|-------|"
    echo "| ${lang} | ${files} | ${loc} |"
    echo "| Markdown | 5 | 200 |"
    echo "| YAML | 3 | 80 |"
    echo ""
    echo "## Full File Inventory"
    echo ""
    echo "| Path | Language | Lines | Modified |"
    echo "|------|----------|-------|----------|"
    # Add default rows matching the language/files declared
    for i in $(seq 1 "$files"); do
      echo "| \`src/module${i}/file.${lang,,}\` | ${lang} | $((loc / files)) | 2026-01-01 |"
    done
    # Add extra inventory rows (for RM3 directory breadth tests)
    for row in "${inventory_rows[@]+"${inventory_rows[@]}"}"; do
      echo "$row"
    done
    echo ""
    echo "## Summary"
    echo ""
    echo "Source files: ${files}"
  } > "$path"
}

# ---------------------------------------------------------------------------
# Helper: run recon-classify and return the output file path
# ---------------------------------------------------------------------------
run_recon() {
  local index="$1"
  local candidates="$2"
  local settings="$3"
  local out
  out=$(mktemp -p "$TMPDIR_BASE" recon_out_XXXXXX.md)
  HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
    --index     "$index" \
    --candidates "$candidates" \
    --settings  "$settings" \
    --output    "$out" \
    2>/dev/null || true
  echo "$out"
}

# Helper: run recon and capture exit code separately
run_recon_exit() {
  local index="$1"
  local candidates="$2"
  local settings="$3"
  local out="$4"
  local rc=0
  HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
    --index     "$index" \
    --candidates "$candidates" \
    --settings  "$settings" \
    --output    "$out" \
    2>/dev/null || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# RC01: Greenfield -- near-empty index (RM1=3, RM2=150) => GREENFIELD
# ---------------------------------------------------------------------------

DIR_RC01=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC01"
make_index_simple "${DIR_RC01}/project-index.md" "TypeScript" 3 150
make_candidates  "${DIR_RC01}/candidate-concepts.md" 2

OUT_RC01=$(run_recon "${DIR_RC01}/project-index.md" \
                     "${DIR_RC01}/candidate-concepts.md" \
                     "${DIR_RC01}/settings.yml")

assert_output_contains "$(cat "$OUT_RC01")" "GREENFIELD" \
  "RC01 near-empty index (RM1=3<=5, RM2=150<=500) classifies GREENFIELD"
assert_output_not_contains "$(cat "$OUT_RC01")" "BROWNFIELD" \
  "RC01 GREENFIELD verdict does not contain BROWNFIELD"

# ---------------------------------------------------------------------------
# RC02: Brownfield-large by LOC -- RM2 >= large_min_source_loc => BROWNFIELD-LARGE
# (RM1=10 > greenfield_max; RM2=25000 >= 20000; RM3 small; RM4 small)
# ---------------------------------------------------------------------------

DIR_RC02=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC02"
make_index_simple "${DIR_RC02}/project-index.md" "Java" 10 25000
make_candidates  "${DIR_RC02}/candidate-concepts.md" 5

OUT_RC02=$(run_recon "${DIR_RC02}/project-index.md" \
                     "${DIR_RC02}/candidate-concepts.md" \
                     "${DIR_RC02}/settings.yml")

assert_output_contains "$(cat "$OUT_RC02")" "BROWNFIELD-LARGE" \
  "RC02 RM2=25000 >= large_min_source_loc=20000 classifies BROWNFIELD-LARGE"
assert_output_not_contains "$(cat "$OUT_RC02")" "BROWNFIELD-SMALL" \
  "RC02 LOC-trip does not yield BROWNFIELD-SMALL"

# ---------------------------------------------------------------------------
# RC03: Brownfield-large by dirs -- RM3 >= large_min_dirs => BROWNFIELD-LARGE
# (RM1=10, RM2=1000 -- under LOC threshold; 30 distinct top-2 dir prefixes; RM4 small)
# ---------------------------------------------------------------------------

DIR_RC03=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC03"

# Build index with 30 distinct top-2-level directories (RM3=30 >= 25)
# Each dir gets one TypeScript file with 30 LOC
{
  echo "# Project Index"
  echo ""
  echo "## Language Breakdown"
  echo ""
  echo "| Language | Files | Lines |"
  echo "|----------|-------|-------|"
  echo "| TypeScript | 30 | 900 |"
  echo ""
  echo "## Full File Inventory"
  echo ""
  echo "| Path | Language | Lines | Modified |"
  echo "|------|----------|-------|----------|"
  for i in $(seq 1 30); do
    echo "| \`src/module${i}/core.ts\` | TypeScript | 30 | 2026-01-01 |"
  done
  echo ""
} > "${DIR_RC03}/project-index.md"

make_candidates "${DIR_RC03}/candidate-concepts.md" 5

OUT_RC03=$(run_recon "${DIR_RC03}/project-index.md" \
                     "${DIR_RC03}/candidate-concepts.md" \
                     "${DIR_RC03}/settings.yml")

assert_output_contains "$(cat "$OUT_RC03")" "BROWNFIELD-LARGE" \
  "RC03 RM3=30 distinct dirs >= large_min_dirs=25 classifies BROWNFIELD-LARGE"
assert_output_not_contains "$(cat "$OUT_RC03")" "BROWNFIELD-SMALL" \
  "RC03 dir-trip does not yield BROWNFIELD-SMALL"

# ---------------------------------------------------------------------------
# RC04: Brownfield-large by concepts -- RM4 >= large_min_concepts => BROWNFIELD-LARGE
# (RM1=8, RM2=800 -- under LOC threshold; RM3 small; RM4=45 >= 40)
# ---------------------------------------------------------------------------

DIR_RC04=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC04"
make_index_simple "${DIR_RC04}/project-index.md" "Python" 8 800
make_candidates  "${DIR_RC04}/candidate-concepts.md" 45

OUT_RC04=$(run_recon "${DIR_RC04}/project-index.md" \
                     "${DIR_RC04}/candidate-concepts.md" \
                     "${DIR_RC04}/settings.yml")

assert_output_contains "$(cat "$OUT_RC04")" "BROWNFIELD-LARGE" \
  "RC04 RM4=45 >= large_min_concepts=40 classifies BROWNFIELD-LARGE (small-but-dense)"
assert_output_not_contains "$(cat "$OUT_RC04")" "BROWNFIELD-SMALL" \
  "RC04 concept-trip does not yield BROWNFIELD-SMALL"

# ---------------------------------------------------------------------------
# RC05: Brownfield-small -- has source but all large thresholds under floor
# (RM1=10, RM2=5000 -- over greenfield ceiling but under large; RM3 small; RM4 small)
# ---------------------------------------------------------------------------

DIR_RC05=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC05"
make_index_simple "${DIR_RC05}/project-index.md" "Go" 10 5000
make_candidates  "${DIR_RC05}/candidate-concepts.md" 10

OUT_RC05=$(run_recon "${DIR_RC05}/project-index.md" \
                     "${DIR_RC05}/candidate-concepts.md" \
                     "${DIR_RC05}/settings.yml")

assert_output_contains "$(cat "$OUT_RC05")" "BROWNFIELD-SMALL" \
  "RC05 RM1=10>5, RM2=5000 (under 20000), RM3 small, RM4=10<40 => BROWNFIELD-SMALL"
assert_output_not_contains "$(cat "$OUT_RC05")" "BROWNFIELD-LARGE" \
  "RC05 BROWNFIELD-SMALL verdict does not contain BROWNFIELD-LARGE"
assert_output_not_contains "$(cat "$OUT_RC05")" "GREENFIELD" \
  "RC05 BROWNFIELD-SMALL verdict does not contain GREENFIELD"

# ---------------------------------------------------------------------------
# RC06: Conjunctive greenfield gate -- 3-file / 50k-LOC is NOT greenfield
# RM1=3 (<= 5) BUT RM2=50000 (> 500 greenfield ceiling) => greenfield gate fails => LARGE
# ---------------------------------------------------------------------------

DIR_RC06=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC06"
make_index_simple "${DIR_RC06}/project-index.md" "Rust" 3 50000
make_candidates  "${DIR_RC06}/candidate-concepts.md" 2

OUT_RC06=$(run_recon "${DIR_RC06}/project-index.md" \
                     "${DIR_RC06}/candidate-concepts.md" \
                     "${DIR_RC06}/settings.yml")

assert_output_not_contains "$(cat "$OUT_RC06")" "GREENFIELD" \
  "RC06 3-file/50k-LOC is NOT greenfield (greenfield gate is conjunctive: RM1 AND RM2)"
assert_output_contains "$(cat "$OUT_RC06")" "BROWNFIELD-LARGE" \
  "RC06 3-file/50k-LOC classifies BROWNFIELD-LARGE (RM2=50000 >= 20000)"

# ---------------------------------------------------------------------------
# RC07: Threshold override flips verdict
# Same fixture as RC05 (brownfield-small at defaults), but with lowered LOC threshold
# => same fixture now classifies BROWNFIELD-LARGE when lg_loc=4000 (below fixture's 5000)
# ---------------------------------------------------------------------------

DIR_RC07=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC07" "lg_loc=4000"
make_index_simple "${DIR_RC07}/project-index.md" "Go" 10 5000
make_candidates  "${DIR_RC07}/candidate-concepts.md" 10

OUT_RC07=$(run_recon "${DIR_RC07}/project-index.md" \
                     "${DIR_RC07}/candidate-concepts.md" \
                     "${DIR_RC07}/settings.yml")

assert_output_contains "$(cat "$OUT_RC07")" "BROWNFIELD-LARGE" \
  "RC07 threshold override (lg_loc=4000 < fixture LOC=5000) flips verdict to BROWNFIELD-LARGE"
assert_output_not_contains "$(cat "$OUT_RC07")" "BROWNFIELD-SMALL" \
  "RC07 overridden threshold yields LARGE not SMALL"

# Also verify the reverse: raise greenfield ceiling so same fixture classifies greenfield
DIR_RC07B=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC07B" "gf_files=15" "gf_loc=10000"
# Use a small fixture that would normally be brownfield-small
make_index_simple "${DIR_RC07B}/project-index.md" "Go" 10 5000
make_candidates  "${DIR_RC07B}/candidate-concepts.md" 5

OUT_RC07B=$(run_recon "${DIR_RC07B}/project-index.md" \
                      "${DIR_RC07B}/candidate-concepts.md" \
                      "${DIR_RC07B}/settings.yml")

assert_output_contains "$(cat "$OUT_RC07B")" "GREENFIELD" \
  "RC07b raised greenfield ceilings (gf_files=15, gf_loc=10000) reclassify small fixture as GREENFIELD"

# ---------------------------------------------------------------------------
# RC08: Missing/empty candidates => RM4=0, non-error classify (exit 0)
#
# Sub-case A: --candidates points to a non-existent file => RM4=0, exit 0
# Sub-case B: --candidates points to an empty file => RM4=0, exit 0
# ---------------------------------------------------------------------------

DIR_RC08=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC08"
# Use a fixture with 10 files/5000 LOC (brownfield-small at defaults)
make_index_simple "${DIR_RC08}/project-index.md" "TypeScript" 10 5000

# Sub-case A: nonexistent candidates file
OUT_RC08A=$(mktemp -p "$TMPDIR_BASE" recon_rc08a_XXXXXX.md)
RC_RC08A=0
HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
  --index     "${DIR_RC08}/project-index.md" \
  --candidates "${DIR_RC08}/nonexistent-candidates.md" \
  --settings  "${DIR_RC08}/settings.yml" \
  --output    "$OUT_RC08A" \
  2>/dev/null || RC_RC08A=$?

assert_exit_zero "$RC_RC08A" "RC08a missing candidates file => exit 0 (degrade gracefully)"
assert_output_contains "$(cat "$OUT_RC08A")" "BROWNFIELD" \
  "RC08a missing candidates => classifies (no error; RM4=0)"
# Verify RM4=0 is recorded in the output
assert_output_contains "$(cat "$OUT_RC08A")" "RM4 (concepts) | 0" \
  "RC08a missing candidates => RM4=0 in recon.md"

# Sub-case B: empty candidates file
touch "${DIR_RC08}/empty-candidates.md"
OUT_RC08B=$(mktemp -p "$TMPDIR_BASE" recon_rc08b_XXXXXX.md)
RC_RC08B=0
HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
  --index     "${DIR_RC08}/project-index.md" \
  --candidates "${DIR_RC08}/empty-candidates.md" \
  --settings  "${DIR_RC08}/settings.yml" \
  --output    "$OUT_RC08B" \
  2>/dev/null || RC_RC08B=$?

assert_exit_zero "$RC_RC08B" "RC08b empty candidates file => exit 0 (degrade gracefully)"
assert_output_contains "$(cat "$OUT_RC08B")" "RM4 (concepts) | 0" \
  "RC08b empty candidates => RM4=0 in recon.md"

# ---------------------------------------------------------------------------
# RC09: Missing index => warn (stderr) + BROWNFIELD-SMALL proposal + exit 0
# ---------------------------------------------------------------------------

DIR_RC09=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC09"
make_candidates "${DIR_RC09}/candidate-concepts.md" 10

OUT_RC09=$(mktemp -p "$TMPDIR_BASE" recon_rc09_XXXXXX.md)
STDERR_RC09=$(mktemp -p "$TMPDIR_BASE" recon_rc09_err_XXXXXX.txt)
RC_RC09=0
HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
  --index     "${DIR_RC09}/nonexistent-index.md" \
  --candidates "${DIR_RC09}/candidate-concepts.md" \
  --settings  "${DIR_RC09}/settings.yml" \
  --output    "$OUT_RC09" \
  2>"$STDERR_RC09" || RC_RC09=$?

assert_exit_zero "$RC_RC09" "RC09 missing index => exit 0 (conservative degradation)"
assert_output_contains "$(cat "$OUT_RC09")" "BROWNFIELD-SMALL" \
  "RC09 missing index => BROWNFIELD-SMALL proposal in recon.md"
assert_output_contains "$(cat "$STDERR_RC09")" "WARNING" \
  "RC09 missing index => WARNING emitted to stderr"

# ---------------------------------------------------------------------------
# RC10: Byte-reproducibility (NFR-3) -- two runs on same inputs emit sha256-identical recon.md
# ---------------------------------------------------------------------------

DIR_RC10=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC10"
make_index_simple "${DIR_RC10}/project-index.md" "Java" 10 25000
make_candidates  "${DIR_RC10}/candidate-concepts.md" 5

OUT_RC10A=$(mktemp -p "$TMPDIR_BASE" recon_rc10a_XXXXXX.md)
OUT_RC10B=$(mktemp -p "$TMPDIR_BASE" recon_rc10b_XXXXXX.md)

HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
  --index     "${DIR_RC10}/project-index.md" \
  --candidates "${DIR_RC10}/candidate-concepts.md" \
  --settings  "${DIR_RC10}/settings.yml" \
  --output    "$OUT_RC10A" \
  2>/dev/null

HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" \
  --index     "${DIR_RC10}/project-index.md" \
  --candidates "${DIR_RC10}/candidate-concepts.md" \
  --settings  "${DIR_RC10}/settings.yml" \
  --output    "$OUT_RC10B" \
  2>/dev/null

HASH_A=$(sha256sum "$OUT_RC10A" | cut -d' ' -f1)
HASH_B=$(sha256sum "$OUT_RC10B" | cut -d' ' -f1)

if [[ "$HASH_A" == "$HASH_B" ]]; then
  pass "RC10 byte-reproducibility: two runs produce sha256-identical recon.md (NFR-3)"
else
  fail "RC10 byte-reproducibility: sha256 differs between runs (NFR-3 violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    diff "$OUT_RC10A" "$OUT_RC10B" || true
  fi
fi

# ---------------------------------------------------------------------------
# RC11: is_source lockstep -- IS_SOURCE_LANGUAGES in recon-classify.sh must equal
# the case labels in build-project-index.sh's is_source() function.
#
# Extract both sets, normalize to sorted pipe-delimited tokens, compare.
# A drift in either script makes this assertion fail.
# ---------------------------------------------------------------------------

# Extract IS_SOURCE_LANGUAGES from recon-classify.sh
RECON_LANG_LINE=$(grep '^IS_SOURCE_LANGUAGES=' "$SUT" | head -1)
# Strip: IS_SOURCE_LANGUAGES="..." -> the quoted value
RECON_LANGS=$(echo "$RECON_LANG_LINE" | sed 's/IS_SOURCE_LANGUAGES="\(.*\)"/\1/')

# Extract the case labels from build-project-index.sh's is_source() function.
# The function block:
#   is_source() {
#     case "$1" in
#       Java|Kotlin|...|Svelte)
# We grab the line between "is_source()" and "esac" that contains the pipe-joined names.
BPI_LANG_LINE=$(awk '/^is_source\(\)/{found=1} found && /Java/{print; exit}' "$BPI")
# The line looks like: Java|Kotlin|...|Svelte)
# Strip leading spaces, trailing ) and quote characters
BPI_LANGS=$(echo "$BPI_LANG_LINE" \
  | sed 's/^[[:space:]]*//' \
  | sed 's/)$//' \
  | tr -d '"')

# Normalize both: split on |, sort, rejoin on |
normalize_langs() {
  echo "$1" | tr '|' '\n' | LC_ALL=C sort | tr '\n' '|' | sed 's/|$//'
}

RECON_SORTED=$(normalize_langs "$RECON_LANGS")
BPI_SORTED=$(normalize_langs "$BPI_LANGS")

if [[ "$RECON_SORTED" == "$BPI_SORTED" ]]; then
  pass "RC11 is_source lockstep: recon-classify.sh IS_SOURCE_LANGUAGES is identical to build-project-index.sh is_source() set"
else
  fail "RC11 is_source lockstep: language sets DIFFER (drift detected)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "  recon-classify.sh: $RECON_SORTED"
    echo "  build-project-index.sh: $BPI_SORTED"
    diff <(normalize_langs "$RECON_LANGS" | tr '|' '\n') \
         <(normalize_langs "$BPI_LANGS"   | tr '|' '\n') || true
  fi
fi

# ---------------------------------------------------------------------------
# RC12: Output shape -- recon.md has documented sections and table fields
# ---------------------------------------------------------------------------

DIR_RC12=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC12"
make_index_simple "${DIR_RC12}/project-index.md" "TypeScript" 10 5000
make_candidates  "${DIR_RC12}/candidate-concepts.md" 10

OUT_RC12=$(run_recon "${DIR_RC12}/project-index.md" \
                     "${DIR_RC12}/candidate-concepts.md" \
                     "${DIR_RC12}/settings.yml")
content_RC12=$(cat "$OUT_RC12")

assert_output_contains "$content_RC12" "# Recon Classification" \
  "RC12a output has '# Recon Classification' title"
assert_output_contains "$content_RC12" "## Result" \
  "RC12b output has '## Result' section"
assert_output_contains "$content_RC12" "Proposed path" \
  "RC12c output has 'Proposed path' field"
assert_output_contains "$content_RC12" "RM1 (source files)" \
  "RC12d output has 'RM1 (source files)' field"
assert_output_contains "$content_RC12" "RM2 (source LOC)" \
  "RC12e output has 'RM2 (source LOC)' field"
assert_output_contains "$content_RC12" "RM3 (directories)" \
  "RC12f output has 'RM3 (directories)' field"
assert_output_contains "$content_RC12" "RM4 (concepts)" \
  "RC12g output has 'RM4 (concepts)' field"
assert_output_contains "$content_RC12" "Tripped thresholds" \
  "RC12h output has 'Tripped thresholds' field"
assert_output_contains "$content_RC12" "## Thresholds" \
  "RC12i output has '## Thresholds' section"
assert_output_contains "$content_RC12" "## Rationale" \
  "RC12j output has '## Rationale' section"

# ---------------------------------------------------------------------------
# RC13: Tripped-threshold reporting -- LOC-trip records correct threshold name
# ---------------------------------------------------------------------------

DIR_RC13=$(mktemp -d -p "$TMPDIR_BASE")
make_settings "$DIR_RC13"
make_index_simple "${DIR_RC13}/project-index.md" "Java" 10 25000
make_candidates  "${DIR_RC13}/candidate-concepts.md" 5

OUT_RC13=$(run_recon "${DIR_RC13}/project-index.md" \
                     "${DIR_RC13}/candidate-concepts.md" \
                     "${DIR_RC13}/settings.yml")

assert_output_contains "$(cat "$OUT_RC13")" "large_min_source_loc" \
  "RC13 LOC-trip records 'large_min_source_loc' in Tripped thresholds"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
