#!/usr/bin/env bash
# test-domain-doc-matrix.sh -- Canonical tests for canonical/aid/templates/kb-authoring/domain-doc-matrix.md
#
# Tests (MT01-MT18):
#
#   Software seed parity:
#   MT01  software-cli required docs == exactly the 15 synth_default_seed filenames
#   MT02  software-web required docs == exactly the 15 synth_default_seed filenames
#   MT03  software-cli and software-web required sets are byte-identical
#   MT04  decisions.md is conditional (not required) in software-cli
#   MT05  decisions.md is conditional (not required) in software-web
#   MT06  the 15-doc seed table in the Seed-consistency section lists exactly 15 rows
#
#   Domain row coverage invariant (every row covers all 11 spine dimensions or marks conditional):
#   MT07  software-cli row covers all 11 spine dimensions (C0-C9 + D as conditional)
#   MT08  software-web row covers all 11 spine dimensions
#   MT09  data-ml row covers all 11 spine dimensions
#   MT10  content row covers all 11 spine dimensions
#   MT11  research row covers all 11 spine dimensions
#   MT12  design row covers all 11 spine dimensions
#   MT13  ops row covers all 11 spine dimensions
#   MT14  methodology-tooling row covers all 11 spine dimensions
#
#   Structural:
#   MT15  all 8 curated domain sections are present
#   MT16  no mermaid fences appear anywhere in the matrix file
#   MT17  the Seed-consistency section explicitly names decisions.md as NOT in the seed
#   MT18  provenance: curated marker appears for every domain section
#
# Usage:
#   bash tests/canonical/test-domain-doc-matrix.sh [--verbose]
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

echo "== test-domain-doc-matrix.sh =="

MATRIX="${REPO}/canonical/aid/templates/kb-authoring/domain-doc-matrix.md"
KB_TEMPLATES="${REPO}/canonical/aid/templates/knowledge-base"
DOC_SET_RESOLVE="${REPO}/canonical/skills/aid-discover/references/doc-set-resolve.md"

# Guard: matrix file must exist
if [[ ! -f "$MATRIX" ]]; then
  echo "FATAL: domain-doc-matrix.md not found at $MATRIX" >&2
  exit 2
fi

# Guard: doc-set-resolve.md must exist (for synth_default_seed comparison)
if [[ ! -f "$DOC_SET_RESOLVE" ]]; then
  echo "FATAL: doc-set-resolve.md not found at $DOC_SET_RESOLVE" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Extract the required docs from a given domain section (### Domain: `<name>`).
# Prints one filename per line (no backticks, no spaces).
extract_required_docs_for_domain() {
  local domain="$1"
  local file="$2"
  awk -v dom="$domain" '
    # Detect domain section start (tolerant of whitespace and backtick wrapping)
    /^### Domain:/ {
      in_dom = 0
      if ($0 ~ dom) in_dom = 1
      next
    }
    # Stop at the next ### section heading
    /^### / && in_dom { exit }
    # Inside the section, extract table rows with "required" in col 4
    # Table format: | `filename` | spine | owner | required |
    in_dom && /^\|/ && /\| required/ {
      # Extract the filename from the first pipe-delimited column (strip backticks and spaces)
      match($0, /\| *`([^`]+\.md)`/, arr)
      if (arr[1] != "") print arr[1]
    }
  ' "$file"
}

# Extract ALL docs (required + conditional) from a given domain section.
extract_all_docs_for_domain() {
  local domain="$1"
  local file="$2"
  awk -v dom="$domain" '
    /^### Domain:/ {
      in_dom = 0
      if ($0 ~ dom) in_dom = 1
      next
    }
    /^### / && in_dom { exit }
    in_dom && /^\|/ && /\.md/ {
      match($0, /\| *`([^`]+\.md)`/, arr)
      if (arr[1] != "") print arr[1]
    }
  ' "$file"
}

# Get spine dimensions covered by a domain section (the spine-dimension column).
# Returns one dimension per line (C0, C1, ..., C9, D, meta).
extract_spine_dims_for_domain() {
  local domain="$1"
  local file="$2"
  awk -v dom="$domain" '
    /^### Domain:/ {
      in_dom = 0
      if ($0 ~ dom) in_dom = 1
      next
    }
    /^### / && in_dom { exit }
    # Table rows: | `filename` | SPINE | owner | presence |
    in_dom && /^\|/ && /\.md/ {
      # The second pipe-delimited field is the spine-dimension
      n = split($0, fields, "|")
      if (n >= 4) {
        dim = fields[3]
        gsub(/^[ \t]+|[ \t]+$/, "", dim)
        if (dim != "" && dim != "spine-dimension" && dim != "-") print dim
      }
    }
  ' "$file"
}

# Get the default seed filenames from synth_default_seed (via the ownership map).
# The seed ownership map in doc-set-resolve.md has rows like:
#   | `filename` | owner | required |
# We rely on the template count (matching what test-doc-set-read.sh T02 checks).
get_seed_filenames() {
  # Extract all .md filenames from the knowledge-base templates directory
  find "$KB_TEMPLATES" -maxdepth 1 -name '*.md' -exec basename {} \; | sort
}

# ---------------------------------------------------------------------------
# Build the canonical seed set (sorted) from the knowledge-base templates
# ---------------------------------------------------------------------------
SEED_FILES="$(get_seed_filenames)"
SEED_COUNT="$(echo "$SEED_FILES" | grep -c .)"

# ---------------------------------------------------------------------------
# MT01: software-cli required docs == the 15-doc synth_default_seed set
# ---------------------------------------------------------------------------
CLI_REQUIRED="$(extract_required_docs_for_domain "software-cli" "$MATRIX" | sort)"
CLI_COUNT="$(echo "$CLI_REQUIRED" | grep -c .)"
assert_eq "$CLI_COUNT" "$SEED_COUNT" \
  "MT01 software-cli required doc count == seed count ($SEED_COUNT)"

CLI_DIFF="$(diff <(echo "$CLI_REQUIRED") <(echo "$SEED_FILES") || true)"
assert_eq "$CLI_DIFF" "" \
  "MT01 software-cli required docs == synth_default_seed filenames (byte-exact)"

# ---------------------------------------------------------------------------
# MT02: software-web required docs == the 15-doc synth_default_seed set
# ---------------------------------------------------------------------------
WEB_REQUIRED="$(extract_required_docs_for_domain "software-web" "$MATRIX" | sort)"
WEB_COUNT="$(echo "$WEB_REQUIRED" | grep -c .)"
assert_eq "$WEB_COUNT" "$SEED_COUNT" \
  "MT02 software-web required doc count == seed count ($SEED_COUNT)"

WEB_DIFF="$(diff <(echo "$WEB_REQUIRED") <(echo "$SEED_FILES") || true)"
assert_eq "$WEB_DIFF" "" \
  "MT02 software-web required docs == synth_default_seed filenames (byte-exact)"

# ---------------------------------------------------------------------------
# MT03: software-cli and software-web required sets are byte-identical
# ---------------------------------------------------------------------------
CLI_WEB_DIFF="$(diff <(echo "$CLI_REQUIRED") <(echo "$WEB_REQUIRED") || true)"
assert_eq "$CLI_WEB_DIFF" "" \
  "MT03 software-cli and software-web required sets are byte-identical"

# ---------------------------------------------------------------------------
# MT04: decisions.md is conditional (not required) in software-cli
# ---------------------------------------------------------------------------
CLI_DECISIONS_COND="$(awk '/^### Domain:.*software-cli/{in_dom=1;next}
  /^### /{in_dom=0}
  in_dom && /decisions\.md/ && /conditional/{found=1}
  END{print found+0}' "$MATRIX")"
assert_eq "$CLI_DECISIONS_COND" "1" \
  "MT04 decisions.md is conditional in software-cli"

CLI_DECISIONS_REQ="$(extract_required_docs_for_domain "software-cli" "$MATRIX" | grep -c 'decisions.md' || true)"
assert_eq "$CLI_DECISIONS_REQ" "0" \
  "MT04 decisions.md is NOT in software-cli required set"

# ---------------------------------------------------------------------------
# MT05: decisions.md is conditional (not required) in software-web
# ---------------------------------------------------------------------------
WEB_DECISIONS_COND="$(awk '/^### Domain:.*software-web/{in_dom=1;next}
  /^### /{in_dom=0}
  in_dom && /decisions\.md/ && /conditional/{found=1}
  END{print found+0}' "$MATRIX")"
assert_eq "$WEB_DECISIONS_COND" "1" \
  "MT05 decisions.md is conditional in software-web"

WEB_DECISIONS_REQ="$(extract_required_docs_for_domain "software-web" "$MATRIX" | grep -c 'decisions.md' || true)"
assert_eq "$WEB_DECISIONS_REQ" "0" \
  "MT05 decisions.md is NOT in software-web required set"

# ---------------------------------------------------------------------------
# MT06: Seed-consistency section table has exactly 15 rows (the 15 seed docs)
# ---------------------------------------------------------------------------
SEED_TABLE_ROWS="$(awk '/^## Seed-consistency/{in_sec=1;next}
  /^## /{in_sec=0}
  in_sec && /^\| [0-9]/{print}' "$MATRIX" | grep -c .)"
assert_eq "$SEED_TABLE_ROWS" "15" \
  "MT06 Seed-consistency table has exactly 15 numbered rows"

# ---------------------------------------------------------------------------
# MT07-MT14: Domain coverage invariant.
#
# Every row must cover all 11 spine dimensions (C0-C9 + D). D is allowed to be
# conditional. Each domain section must have at least one doc for each of:
# C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, and D.
# ---------------------------------------------------------------------------

check_spine_coverage() {
  local domain_label="$1"
  local test_id="$2"
  local domain_pattern="$3"

  local dims
  dims="$(extract_spine_dims_for_domain "$domain_pattern" "$MATRIX")"

  local spine_dims="C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 D"
  local all_ok=0
  local missing=""
  for dim in $spine_dims; do
    if echo "$dims" | grep -qF "$dim"; then
      : # covered
    else
      all_ok=1
      missing="${missing} $dim"
    fi
  done

  if [[ $all_ok -eq 0 ]]; then
    pass "${test_id} ${domain_label} covers all 11 spine dimensions"
  else
    fail "${test_id} ${domain_label} missing spine dimensions:${missing}"
    [[ "$VERBOSE" -eq 1 ]] && echo "Dims found: $dims"
  fi
}

check_spine_coverage "software-cli"         "MT07" "software-cli"
check_spine_coverage "software-web"         "MT08" "software-web"
check_spine_coverage "data-ml"              "MT09" "data-ml"
check_spine_coverage "content"              "MT10" "content"
check_spine_coverage "research"             "MT11" "research"
check_spine_coverage "design"               "MT12" "design"
check_spine_coverage "ops"                  "MT13" "ops"
check_spine_coverage "methodology-tooling"  "MT14" "methodology-tooling"

# ---------------------------------------------------------------------------
# MT15: All 8 curated domain sections are present
# ---------------------------------------------------------------------------
EXPECTED_DOMAINS="software-cli software-web data-ml content research design ops methodology-tooling"
for dom in $EXPECTED_DOMAINS; do
  FOUND="$(grep -c "^### Domain:.*${dom}" "$MATRIX" || true)"
  assert_eq "$FOUND" "1" "MT15 domain section '${dom}' present in matrix"
done

# ---------------------------------------------------------------------------
# MT16: No mermaid fences appear in the matrix file
# ---------------------------------------------------------------------------
MERMAID_COUNT="$(grep -c '```mermaid' "$MATRIX" || true)"
assert_eq "$MERMAID_COUNT" "0" \
  "MT16 no mermaid fences in domain-doc-matrix.md"

# ---------------------------------------------------------------------------
# MT17: Seed-consistency section explicitly states decisions.md is NOT in the seed
# ---------------------------------------------------------------------------
SEED_SECTION="$(awk '/^## Seed-consistency/{in_sec=1;next} /^## /{in_sec=0} in_sec{print}' "$MATRIX")"
assert_output_contains "$SEED_SECTION" "decisions.md" \
  "MT17 Seed-consistency section mentions decisions.md"
# Must say it is NOT row 16 of the seed (various phrasings checked)
assert_output_contains "$SEED_SECTION" "NOT" \
  "MT17 Seed-consistency section states decisions.md is NOT part of the seed"

# ---------------------------------------------------------------------------
# MT18: provenance: curated marker appears for each domain section
# ---------------------------------------------------------------------------
for dom in $EXPECTED_DOMAINS; do
  # Each domain section must have 'provenance: curated' inside it
  PROV_FOUND="$(awk -v d="$dom" '
    /^### Domain:/ { in_dom = 0; if ($0 ~ d) in_dom = 1; next }
    /^### / && in_dom { exit }
    in_dom && /provenance.*curated/ { found = 1 }
    END { print found+0 }
  ' "$MATRIX")"
  assert_eq "$PROV_FOUND" "1" \
    "MT18 domain '${dom}' has provenance: curated marker"
done

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
