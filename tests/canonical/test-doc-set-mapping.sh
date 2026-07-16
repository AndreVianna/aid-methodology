#!/usr/bin/env bash
# test-doc-set-mapping.sh — MECHANICAL mapping-honors-declared-set tests.
#
# All assertions are mechanical set-difference checks — no "appropriateness" claim.
#
# Tests:
#   T01  no-hang-on-omission: omit test-landscape.md → quality dispatch list excludes it
#   T02  no-hang-on-omission: declared count drops by 1 (verify target lowers)
#   T03  dispatch-on-addition: added repo-presentation.md (architect) → in architect list
#   T04  dispatch-on-addition: architect target count rises vs baseline
#   T05  carve-out-as-config (AC3): §1.4 set contains pipeline-contracts.md
#   T06  carve-out-as-config (AC3): §1.4 set contains schemas.md
#   T07  carve-out-as-config (AC3): §1.4 set contains repo-presentation.md
#   T08  carve-out-as-config (AC3): §1.4 set excludes api-contracts.md
#   T09  carve-out-as-config (AC3): §1.4 set excludes data-model.md
#   T10  carve-out-as-config (AC3): §1.4 set excludes ui-architecture.md
#   T11  carve-out-as-config (AC3): §1.4 set excludes security-model.md
#   T12  non-software fixture differs from default seed (≥1 omission and/or ≥1 addition)
#   T13  non-software fixture: omitted standard doc absent from list-filenames
#   T14  non-software fixture: added custom doc present in list-filenames
#   T15  non-software fixture: user edit honored verbatim (equals list-filenames)
#
# Usage:
#   bash tests/canonical/test-doc-set-mapping.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT_SCRIPT="${REPO}/canonical/aid/scripts/config/read-setting.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-doc-set-mapping.sh =="

# ---------------------------------------------------------------------------
# Extract and source the resolve_doc_set / synth_default_seed functions
# from the canonical doc-set-resolve.md prose (function-definition fences only).
# ---------------------------------------------------------------------------
DOC_SET_RESOLVE="${REPO}/canonical/skills/aid-discover/references/doc-set-resolve.md"

if [[ ! -f "$DOC_SET_RESOLVE" ]]; then
  echo "FATAL: doc-set-resolve.md not found at $DOC_SET_RESOLVE" >&2
  exit 2
fi

FUNCS_FILE=$(mktemp)
trap 'rm -f "$FUNCS_FILE"' EXIT

awk '
  /^```bash/ { in_fence=1; buffer=""; next }
  /^```/ && in_fence {
    in_fence=0
    if (buffer ~ /synth_default_seed\(\)/ || buffer ~ /resolve_doc_set\(\)/) {
      print buffer
    }
    next
  }
  in_fence { buffer = buffer $0 "\n" }
' "$DOC_SET_RESOLVE" > "$FUNCS_FILE"

# shellcheck disable=SC1090
source "$FUNCS_FILE"

# ---------------------------------------------------------------------------
# Fixture setup
# ---------------------------------------------------------------------------
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"; rm -f "$FUNCS_FILE"' EXIT

# Helper: read raw from a settings file.
read_raw() {
  local file="$1"
  bash "$SUT_SCRIPT" --file "$file" --path discovery.doc_set 2>/dev/null || true
}

# Baseline: the standard software-dev seed minus test-landscape.md (omission fixture)
settings_omit_test_landscape() {
  cat <<'EOF'
discovery:
  doc_set:
    - project-structure.md|aid-researcher-scout|required
    - external-sources.md|aid-researcher-scout|required
    - architecture.md|aid-researcher-architecture|required
    - technology-stack.md|aid-researcher-architecture|required
    - module-map.md|aid-researcher-analyst|required
    - coding-standards.md|aid-researcher-analyst|required
    - schemas.md|aid-researcher-analyst|required
    - pipeline-contracts.md|aid-researcher-integrator|required
    - integration-map.md|aid-researcher-integrator|required
    - domain-glossary.md|aid-researcher-integrator|required
    - tech-debt.md|aid-researcher-quality|required
    - infrastructure.md|aid-researcher-quality|required
    - feature-inventory.md|orchestrator|required
EOF
  # Note: test-landscape.md deliberately OMITTED (README.md retired from the seed in work-005)
}

# Baseline: standard set + repo-presentation.md (addition fixture)
settings_add_repo_presentation() {
  cat <<'EOF'
discovery:
  doc_set:
    - project-structure.md|aid-researcher-scout|required
    - external-sources.md|aid-researcher-scout|required
    - architecture.md|aid-researcher-architecture|required
    - technology-stack.md|aid-researcher-architecture|required
    - repo-presentation.md|aid-researcher-architecture|required
    - module-map.md|aid-researcher-analyst|required
    - coding-standards.md|aid-researcher-analyst|required
    - schemas.md|aid-researcher-analyst|required
    - pipeline-contracts.md|aid-researcher-integrator|required
    - integration-map.md|aid-researcher-integrator|required
    - domain-glossary.md|aid-researcher-integrator|required
    - test-landscape.md|aid-researcher-quality|required
    - tech-debt.md|aid-researcher-quality|required
    - infrastructure.md|aid-researcher-quality|required
    - feature-inventory.md|orchestrator|required
    - README.md|orchestrator|required
EOF
  # Note: repo-presentation.md added under aid-researcher-architecture
}

# The §1.4 carve-out encoding from SPEC.md
settings_carveout() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - technology-stack.md|aid-researcher-architecture|required
    - module-map.md|aid-researcher-analyst|required
    - coding-standards.md|aid-researcher-analyst|required
    - integration-map.md|aid-researcher-integrator|required
    - domain-glossary.md|aid-researcher-integrator|required
    - test-landscape.md|aid-researcher-quality|required
    - tech-debt.md|aid-researcher-quality|required
    - infrastructure.md|aid-researcher-quality|required
    - project-structure.md|aid-researcher-scout|required
    - external-sources.md|aid-researcher-scout|required
    - feature-inventory.md|orchestrator|required
    - schemas.md|aid-researcher-analyst|required
    - pipeline-contracts.md|aid-researcher-integrator|required
    - repo-presentation.md|aid-researcher-architecture|required
    # (drop: security-model.md is simply absent — no entry)
EOF
}

# Non-software fixture: a docs-only project
# Omits: test-landscape.md, schemas.md (software-specific)
# Adds: research-notes.md (custom, owned by aid-researcher-analyst)
settings_non_software() {
  cat <<'EOF'
discovery:
  doc_set:
    - project-structure.md|aid-researcher-scout|required
    - external-sources.md|aid-researcher-scout|required
    - architecture.md|aid-researcher-architecture|required
    - module-map.md|aid-researcher-analyst|required
    - coding-standards.md|aid-researcher-analyst|required
    - research-notes.md|aid-researcher-analyst|required
    - pipeline-contracts.md|aid-researcher-integrator|required
    - integration-map.md|aid-researcher-integrator|required
    - domain-glossary.md|aid-researcher-integrator|required
    - tech-debt.md|aid-researcher-quality|required
    - infrastructure.md|aid-researcher-quality|required
    - feature-inventory.md|orchestrator|required
    - README.md|orchestrator|required
EOF
  # Note: test-landscape.md and schemas.md OMITTED (software-specific)
  #       research-notes.md ADDED (custom, docs-only project)
  #       technology-stack.md OMITTED (software-specific)
}

# The declared filenames from the non-software fixture, verbatim, sorted.
# Used in T15 to confirm list-filenames == what was declared.
NON_SOFTWARE_DECLARED_SORTED="README.md
architecture.md
coding-standards.md
domain-glossary.md
external-sources.md
feature-inventory.md
infrastructure.md
integration-map.md
module-map.md
pipeline-contracts.md
project-structure.md
research-notes.md
tech-debt.md"

# ---------------------------------------------------------------------------
# T01 + T02: no-hang-on-omission — omit test-landscape.md
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/omit_tl.yml"
settings_omit_test_landscape > "$fixture"
raw=$(read_raw "$fixture")
tsv=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

# T01: quality dispatch list must NOT contain test-landscape.md
quality_files=$(echo "$tsv" | awk -F'\t' -v a="aid-researcher-quality" '$2==a{print $1}')
assert_output_not_contains "$quality_files" "test-landscape.md" \
  "T01 omitted test-landscape.md absent from quality dispatch list"

# T01: quality dispatch list still contains the other quality docs
assert_output_contains "$quality_files" "tech-debt.md"    "T01 tech-debt.md still in quality list"
assert_output_contains "$quality_files" "infrastructure.md" "T01 infrastructure.md still in quality list"

# T02: declared count (14 = 15 default minus 1) drops from default seed count
default_tsv=$(REPO="$REPO" resolve_doc_set "" 2>/dev/null)
default_count=$(echo "$default_tsv" | grep -c .)
declared_count=$(echo "$tsv" | grep -c .)
expected_count=$(( default_count - 1 ))
assert_eq "$declared_count" "$expected_count" \
  "T02 declared count is default($default_count) - 1 = $expected_count after omission"

# ---------------------------------------------------------------------------
# T03 + T04: dispatch-on-addition — add repo-presentation.md (architect)
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/add_rp.yml"
settings_add_repo_presentation > "$fixture"
raw=$(read_raw "$fixture")
tsv=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

# T03: architect list contains repo-presentation.md
arch_files=$(echo "$tsv" | awk -F'\t' -v a="aid-researcher-architecture" '$2==a{print $1}')
assert_output_contains "$arch_files" "repo-presentation.md" \
  "T03 added repo-presentation.md appears in architect dispatch list"

# T03: the baseline architect docs still present
assert_output_contains "$arch_files" "architecture.md"    "T03 architecture.md still in architect list"
assert_output_contains "$arch_files" "technology-stack.md" "T03 technology-stack.md still in architect list"

# T04: architect target count is higher than default
default_arch=$(echo "$default_tsv" | awk -F'\t' -v a="aid-researcher-architecture" '$2==a{print $1}' | grep -c .)
added_arch=$(echo "$arch_files" | grep -c .)
if [[ "$added_arch" -gt "$default_arch" ]]; then
  pass "T04 architect count rose after addition ($default_arch → $added_arch)"
else
  fail "T04 architect count — expected > $default_arch, got $added_arch"
fi

# ---------------------------------------------------------------------------
# T05–T11: carve-out-as-config (AC3) — §1.4 carve-out mechanical assertions
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/carveout.yml"
settings_carveout > "$fixture"
raw=$(read_raw "$fixture")
tsv=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)
filenames=$(echo "$tsv" | cut -f1)

# T05-T07: renamed/replaced docs PRESENT
assert_output_contains "$filenames" "pipeline-contracts.md" \
  "T05 carve-out: pipeline-contracts.md present (rename from api-contracts.md)"
assert_output_contains "$filenames" "schemas.md" \
  "T06 carve-out: schemas.md present (rename from data-model.md)"
assert_output_contains "$filenames" "repo-presentation.md" \
  "T07 carve-out: repo-presentation.md present (replace of ui-architecture.md)"

# T08-T11: old/dropped names ABSENT
assert_output_not_contains "$filenames" "api-contracts.md" \
  "T08 carve-out: api-contracts.md absent (renamed to pipeline-contracts.md)"
assert_output_not_contains "$filenames" "data-model.md" \
  "T09 carve-out: data-model.md absent (renamed to schemas.md)"
assert_output_not_contains "$filenames" "ui-architecture.md" \
  "T10 carve-out: ui-architecture.md absent (replaced by repo-presentation.md)"
assert_output_not_contains "$filenames" "security-model.md" \
  "T11 carve-out: security-model.md absent (dropped)"

# ---------------------------------------------------------------------------
# T12–T15: non-software fixture (AC4) — MECHANICAL set-difference checks
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/non_sw.yml"
settings_non_software > "$fixture"
raw=$(read_raw "$fixture")
tsv=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)
filenames=$(echo "$tsv" | cut -f1)

# T12: declared set differs from default seed (≥1 omission and/or ≥1 addition)
# Compute symmetric difference: lines in default but not in declared, and vice versa.
default_filenames=$(echo "$default_tsv" | cut -f1 | sort)
declared_sorted=$(echo "$filenames" | sort)

only_in_default=$(comm -23 <(echo "$default_filenames") <(echo "$declared_sorted") | head -1 || true)
only_in_declared=$(comm -13 <(echo "$default_filenames") <(echo "$declared_sorted") | head -1 || true)

if [[ -n "$only_in_default" ]] || [[ -n "$only_in_declared" ]]; then
  pass "T12 non-software fixture differs from default seed (symmetric difference non-empty)"
else
  fail "T12 non-software fixture — expected difference from default seed, but sets are identical"
fi

# T13: omitted standard docs absent from list-filenames
assert_output_not_contains "$filenames" "test-landscape.md" \
  "T13 test-landscape.md omitted from non-software fixture list-filenames"
assert_output_not_contains "$filenames" "schemas.md" \
  "T13 schemas.md omitted from non-software fixture list-filenames"
assert_output_not_contains "$filenames" "technology-stack.md" \
  "T13 technology-stack.md omitted from non-software fixture list-filenames"

# T14: added custom doc present in list-filenames
assert_output_contains "$filenames" "research-notes.md" \
  "T14 added research-notes.md present in non-software fixture list-filenames"

# T15: user edit honored verbatim — list-filenames exactly equals the fixture declaration
# The fixture declares 13 docs; sort both and compare.
if [[ "$(echo "$filenames" | sort)" == "$NON_SOFTWARE_DECLARED_SORTED" ]]; then
  pass "T15 list-filenames equals fixture declaration verbatim (user edit honored)"
else
  fail "T15 list-filenames mismatch — fixture declaration not honored verbatim"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "  Expected (sorted): $NON_SOFTWARE_DECLARED_SORTED"
    echo "  Got (sorted):      $(echo "$filenames" | sort)"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
test_summary
exit $?
