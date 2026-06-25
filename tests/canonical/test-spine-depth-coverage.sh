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
echo
test_summary
exit $?
