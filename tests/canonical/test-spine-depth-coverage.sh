#!/usr/bin/env bash
# test-spine-depth-coverage.sh -- FR-52 depth-contract coverage guard.
#
# Asserts every doc the domain-doc-matrix can emit resolves to a non-empty
# depth contract via its spine dimension, closing the 36-doc dangling-anchor gap.
#
# Tests (SD01-SD12):
#
#   Spine-Dimension Depth Standards block presence + non-empty:
#   SD01  ## Spine-Dimension Depth Standards section present in document-expectations.md
#   SD02  All 11 C<N>/D standard blocks (C0-C9 + D) present in document-expectations.md
#   SD03  All 11 C<N>/D standard blocks are non-empty (contain "MUST carry" text)
#
#   Every matrix doc resolves to a non-empty depth contract (FR-52 core assertion):
#   SD04  Every non-meta matrix doc's spine-dimension maps to a present C<N>/D block
#   SD05  Every non-meta matrix doc's spine-dimension maps to a non-empty C<N>/D block
#   SD06  Meta docs (README.md, external-sources.md) have per-filename entries
#   SD07  Total emittable-doc count is >=58 (sanity check; count from actual matrix)
#
#   Optional-refinement non-regression:
#   SD08  Existing per-filename entry ### architecture.md still present (representative)
#   SD09  Existing per-filename entry ### technology-stack.md still present (representative)
#   SD10  Per-filename entries are additive (do not replace dimension standard)
#         Verified by asserting "does not replace the floor" (or equivalent) appears in
#         the header commentary of document-expectations.md
#
#   Custom-doc prompt alignment (prompt points at C<N>, not bare ### <filename>):
#   SD11  state-generate.md custom-doc prompt references C<N> Spine-Dimension Depth Standard
#   SD12  agent-prompts.md custom-doc prompt references C<N> Spine-Dimension Depth Standard
#
# Usage:
#   bash tests/canonical/test-spine-depth-coverage.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-spine-depth-coverage.sh =="

MATRIX="${REPO}/canonical/aid/templates/kb-authoring/domain-doc-matrix.md"
DOC_EXPECTATIONS="${REPO}/canonical/skills/aid-discover/references/document-expectations.md"
STATE_GENERATE="${REPO}/canonical/skills/aid-discover/references/state-generate.md"
AGENT_PROMPTS="${REPO}/canonical/skills/aid-discover/references/agent-prompts.md"

# Guard: required files must exist
for f in "$MATRIX" "$DOC_EXPECTATIONS" "$STATE_GENERATE" "$AGENT_PROMPTS"; do
  if [[ ! -f "$f" ]]; then
    echo "FATAL: required file not found: $f" >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Extract block content between a heading pattern and the next --- delimiter.
# Returns the non-whitespace content lines (empty string if block is empty).
extract_block_content() {
  local heading_pattern="$1"
  local file="$2"
  awk -v pat="$heading_pattern" '
    $0 ~ pat { found=1; next }
    found && /^---/ { exit }
    found { print }
  ' "$file" | grep -v '^[[:space:]]*$' || true
}

# Test whether a dimension block (C0..C9, D) exists in document-expectations.md.
dim_block_exists() {
  local dim="$1"
  if [[ "$dim" == "D" ]]; then
    grep -q "^### D " "$DOC_EXPECTATIONS" 2>/dev/null
  else
    grep -q "^### ${dim} " "$DOC_EXPECTATIONS" 2>/dev/null
  fi
}

# Test whether a dimension block has non-empty MUST-carry content.
dim_block_nonempty() {
  local dim="$1"
  local content
  if [[ "$dim" == "D" ]]; then
    content="$(extract_block_content "^### D " "$DOC_EXPECTATIONS")"
  else
    content="$(extract_block_content "^### ${dim} " "$DOC_EXPECTATIONS")"
  fi
  [[ -n "$content" ]]
}

# Extract all unique (filename, spine-dimension) pairs from all domain sections.
# Prints one "filename|spine-dimension" pair per line.
extract_all_matrix_pairs() {
  awk '
    /^### Domain:/ { in_dom = 1; next }
    /^## /          { in_dom = 0 }
    /^### / && !/^### Domain:/ { in_dom = 0 }
    in_dom && /^\|/ && /\.md/ {
      n = split($0, fields, "|")
      if (n >= 4) {
        fname = fields[2]
        dim   = fields[3]
        gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", fname)
        gsub(/^[[:space:]]+|[[:space:]]+$/,   "", dim)
        if (fname != "filename" && fname != "" && dim != "spine-dimension" && dim != "")
          print fname "|" dim
      }
    }
  ' "$MATRIX" | sort -u
}

# ---------------------------------------------------------------------------
# SD01: ## Spine-Dimension Depth Standards section present
# ---------------------------------------------------------------------------
assert_file_contains "$DOC_EXPECTATIONS" "## Spine-Dimension Depth Standards" \
  "SD01 document-expectations.md contains ## Spine-Dimension Depth Standards section"

# ---------------------------------------------------------------------------
# SD02: All 11 C<N>/D blocks present
# ---------------------------------------------------------------------------
ALL_DIMS="C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 D"
for dim in $ALL_DIMS; do
  if dim_block_exists "$dim"; then
    pass "SD02 ### ${dim} block present in document-expectations.md"
  else
    fail "SD02 ### ${dim} block MISSING from document-expectations.md"
  fi
done

# ---------------------------------------------------------------------------
# SD03: All 11 C<N>/D blocks are non-empty
# ---------------------------------------------------------------------------
for dim in $ALL_DIMS; do
  if dim_block_nonempty "$dim"; then
    pass "SD03 ### ${dim} block is non-empty (contains MUST-carry content)"
  else
    fail "SD03 ### ${dim} block is EMPTY -- no work-actionable content"
  fi
done

# ---------------------------------------------------------------------------
# SD04 + SD05: Every non-meta matrix doc resolves to an existing, non-empty
#              C<N>/D dimension block.
#
# For each unique (filename, spine-dimension) pair from the matrix:
#   - if spine-dimension is meta: skip (handled by SD06)
#   - otherwise: assert the dimension block exists (SD04) and is non-empty (SD05)
# ---------------------------------------------------------------------------
ALL_PAIRS="$(extract_all_matrix_pairs)"
PAIR_COUNT="$(echo "$ALL_PAIRS" | grep -c .)"
NON_META_FAIL_EXIST=0
NON_META_FAIL_CONTENT=0

while IFS='|' read -r fname dim; do
  [[ -z "$fname" ]] && continue
  [[ "$dim" == "meta" ]] && continue

  if dim_block_exists "$dim"; then
    pass "SD04 ${fname} -> ${dim}: dimension block present"
  else
    fail "SD04 ${fname} -> ${dim}: dimension block MISSING (dangling anchor)"
    NON_META_FAIL_EXIST=$((NON_META_FAIL_EXIST + 1))
  fi

  if dim_block_nonempty "$dim"; then
    pass "SD05 ${fname} -> ${dim}: dimension block non-empty"
  else
    fail "SD05 ${fname} -> ${dim}: dimension block EMPTY"
    NON_META_FAIL_CONTENT=$((NON_META_FAIL_CONTENT + 1))
  fi
done <<< "$ALL_PAIRS"

# Confirm the zero-dangling summary
if [[ $NON_META_FAIL_EXIST -eq 0 ]]; then
  pass "SD04 zero dangling anchors: all non-meta matrix docs resolve to a present dimension block"
else
  fail "SD04 ${NON_META_FAIL_EXIST} non-meta matrix doc(s) have no dimension block (dangling)"
fi

if [[ $NON_META_FAIL_CONTENT -eq 0 ]]; then
  pass "SD05 zero empty blocks: all non-meta matrix docs resolve to a non-empty dimension standard"
else
  fail "SD05 ${NON_META_FAIL_CONTENT} non-meta matrix doc(s) resolve to an EMPTY dimension block"
fi

# ---------------------------------------------------------------------------
# SD06: Meta docs have per-filename entries (their depth contract path)
# ---------------------------------------------------------------------------
for meta_doc in "README.md" "external-sources.md"; do
  assert_file_contains "$DOC_EXPECTATIONS" "### ${meta_doc}" \
    "SD06 meta doc ${meta_doc} has per-filename entry in document-expectations.md"
done

# ---------------------------------------------------------------------------
# SD07: Total matrix emittable doc count sanity check (>=58)
# ---------------------------------------------------------------------------
EMITTABLE_COUNT="$(echo "$ALL_PAIRS" | grep -c .)"
if [[ "$EMITTABLE_COUNT" -ge 58 ]]; then
  pass "SD07 matrix emittable doc count is ${EMITTABLE_COUNT} (>= 58)"
else
  fail "SD07 matrix emittable doc count is ${EMITTABLE_COUNT} -- expected >= 58"
fi

# ---------------------------------------------------------------------------
# SD08 + SD09: Optional-refinement non-regression (per-filename entries present)
# ---------------------------------------------------------------------------
assert_file_contains "$DOC_EXPECTATIONS" "### architecture.md" \
  "SD08 per-filename entry ### architecture.md still present (additive refinement)"

assert_file_contains "$DOC_EXPECTATIONS" "### technology-stack.md" \
  "SD09 per-filename entry ### technology-stack.md still present (additive refinement)"

# ---------------------------------------------------------------------------
# SD10: Per-filename entries are additive (header commentary confirms they do not
#        replace the dimension standard)
# ---------------------------------------------------------------------------
assert_file_contains "$DOC_EXPECTATIONS" \
  "never replaces" \
  "SD10 document-expectations.md states per-filename entries never replace the dimension floor"

# ---------------------------------------------------------------------------
# SD11: state-generate.md custom-doc prompt references C<N> Spine-Dimension
#        Depth Standard (not a bare ### <filename> anchor as the MUST-floor)
# ---------------------------------------------------------------------------
assert_file_contains "$STATE_GENERATE" "Spine-Dimension Depth Standard" \
  "SD11 state-generate.md custom-doc prompt references Spine-Dimension Depth Standard"

# Also verify it explicitly references the C<N> heading form (not just generic text)
assert_file_contains "$STATE_GENERATE" '### C<N>' \
  "SD11 state-generate.md custom-doc prompt references ### C<N> block form"

# ---------------------------------------------------------------------------
# SD12: agent-prompts.md custom-doc prompt references C<N> Spine-Dimension
#        Depth Standard (not a bare ### <filename> anchor as the MUST-floor)
# ---------------------------------------------------------------------------
assert_file_contains "$AGENT_PROMPTS" "Spine-Dimension Depth Standard" \
  "SD12 agent-prompts.md custom-doc prompt references Spine-Dimension Depth Standard"

assert_file_contains "$AGENT_PROMPTS" '### C<N>' \
  "SD12 agent-prompts.md custom-doc prompt references ### C<N> block form"

# ---------------------------------------------------------------------------
# SD13: Single-source guard -- every ### C<N> "Owns named section(s)" cell in
#        document-expectations.md matches concern-model.md's owning-table.
#
# Algorithm:
#   1. Parse concern-model.md's owning-table: for each row extract which C<N>
#      dimensions appear in the "Owning concern(s)" column.
#   2. Invert to a per-dimension expected set of owned classes.
#   3. For each C<N> block in document-expectations.md, extract the
#      "Owns named section(s)" value and assert it matches the expected set.
#
# Expected mapping (from concern-model.md owning-table, hard-coded as the
# canonical truth this test is validating against):
#   C0  -> (none)
#   C1  -> Invariants
#   C2  -> Conventions, Invariants, Contracts
#   C3  -> Conventions
#   C4  -> Invariants
#   C5  -> Contracts, Conventions
#   C6  -> (none)
#   C7  -> Gotchas
#   C8  -> (none)
#   C9  -> (none)
# ---------------------------------------------------------------------------
CONCERN_MODEL="${REPO}/canonical/aid/templates/kb-authoring/concern-model.md"
if [[ ! -f "$CONCERN_MODEL" ]]; then
  echo "FATAL: concern-model.md not found: $CONCERN_MODEL" >&2
  exit 2
fi

# Extract the owning-table rows from concern-model.md.
# The table lives in the block "### The four operational-guidance classes".
# Each data row is a markdown table row with pipe-delimited columns:
#   | Class | Named section heading | What it states | Owning concern(s) | Default owning doc(s) |
# We extract: class name (col1) and owning concerns (col4).
extract_owning_table() {
  awk '
    /\| \*\*Conventions\*\*/ || /\| \*\*Invariants\*\*/ || /\| \*\*Gotchas\*\*/ || /\| \*\*Contracts\*\*/ {
      n = split($0, fields, "|")
      class_col = fields[2]
      owners_col = fields[5]
      # Strip markdown bold, leading/trailing space
      gsub(/\*\*/, "", class_col)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", class_col)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", owners_col)
      print class_col "|" owners_col
    }
  ' "$CONCERN_MODEL"
}

# Build inverted map: dimension -> sorted comma-separated list of class names
# Each dimension that owns a class gets it added to its set.
declare -A DIM_OWNS
for dim in C0 C1 C2 C3 C4 C5 C6 C7 C8 C9; do
  DIM_OWNS[$dim]=""
done

while IFS='|' read -r class owners; do
  [[ -z "$class" ]] && continue
  # Extract C<N> tokens from the owners column
  while IFS= read -r cdim; do
    [[ -z "$cdim" ]] && continue
    if [[ -n "${DIM_OWNS[$cdim]+_}" ]]; then
      if [[ -z "${DIM_OWNS[$cdim]}" ]]; then
        DIM_OWNS[$cdim]="$class"
      else
        DIM_OWNS[$cdim]="${DIM_OWNS[$cdim]}, $class"
      fi
    fi
  done < <(echo "$owners" | grep -oE 'C[0-9]')
done < <(extract_owning_table)

# Extract the "Owns named section(s)" value from a C<N> block in document-expectations.md.
extract_owns_cell() {
  local dim="$1"
  awk -v pat="^### ${dim} " '
    $0 ~ pat { found=1; next }
    found && /^---/ { exit }
    found && /\*\*Owns named section\(s\):\*\*/ {
      line = $0
      # Remove the label prefix
      sub(/.*\*\*Owns named section\(s\):\*\*[[:space:]]*/, "", line)
      # Strip trailing whitespace
      sub(/[[:space:]]+$/, "", line)
      print line
      exit
    }
  ' "$DOC_EXPECTATIONS"
}

# Normalize a "Owns" value: strip backticks, "## " prefixes, em-dashes, sort
# Returns a comma-space-separated sorted list of class names, or "(none)"
normalize_owns() {
  local raw="$1"
  # Handle explicit "none" markers: the cell may start with an em-dash (U+2014)
  # or a plain hyphen, followed by "(none" or just "none".
  # Use grep with -P or a broad pattern that catches the em-dash.
  if echo "$raw" | grep -qE '^\s*(—|-)\s*\(none' || echo "$raw" | grep -qE '^\s*-\s*(none)?\s*$'; then
    echo "(none)"
    return
  fi
  # Check for literal em-dash at start (multi-byte; grep -F to be safe)
  if echo "$raw" | grep -qF '— (none'; then
    echo "(none)"
    return
  fi
  # Extract class names: strip ## prefixes and backticks, split on comma
  echo "$raw" \
    | tr ',' '\n' \
    | sed 's/`//g; s/##[[:space:]]*//' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort \
    | tr '\n' ',' \
    | sed 's/,$//' \
    | sed 's/,/, /g'
}

# Build the expected set for each dimension using the same normalizer.
SD13_PASS=1
for dim in C0 C1 C2 C3 C4 C5 C6 C7 C8 C9; do
  raw_expected="${DIM_OWNS[$dim]}"

  # Normalize expected: if empty -> "(none)", else sort alphabetically
  if [[ -z "$raw_expected" ]]; then
    expected_norm="(none)"
  else
    expected_norm="$(echo "$raw_expected" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sort | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  fi

  # Extract and normalize actual cell from document-expectations.md
  actual_raw="$(extract_owns_cell "$dim")"
  actual_norm="$(normalize_owns "$actual_raw")"

  if [[ "$actual_norm" == "$expected_norm" ]]; then
    pass "SD13 ${dim} Owns cell matches concern-model.md (${expected_norm})"
  else
    fail "SD13 ${dim} Owns cell DRIFTED from concern-model.md: expected '${expected_norm}', got '${actual_norm}'"
    SD13_PASS=0
  fi
done

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
