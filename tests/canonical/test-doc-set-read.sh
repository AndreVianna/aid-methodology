#!/usr/bin/env bash
# test-doc-set-read.sh — Unit tests for the doc-set resolve/accessor logic.
#
# Exercises the resolve_doc_set / synth_default_seed functions and all 4 accessors
# sourced inline from canonical/skills/aid-discover/references/doc-set-resolve.md.
#
# Tests:
#   T01  unset discovery.doc_set → synth_default_seed synthesizes default seed from templates
#   T02  default seed contains expected standard docs (spot-check)
#   T03  default seed does NOT contain category or expectations fields
#   T04  present section → resolve accessor returns exact filename/owner/presence rows
#   T05  list-filenames accessor returns only filenames (no owner/presence)
#   T06  owner-of accessor returns correct owner for a named file
#   T07  owns-<agent> accessor returns correct files for aid-researcher-quality
#   T08  trailing inline # comment on an item is stripped (provenance text does not leak)
#   T09  full-line comment after last item does NOT truncate the list
#   T10a comma-in-when: fragment 1 survives as valid record (infrastructure.md → aid-researcher-quality)
#   T10b comma-in-when: trailing fragments (no pipe) emit warn to stderr and are skipped in TSV
#   T10c comma-in-when: no wrong/unknown-owner dispatch (only legitimate owners in TSV)
#   T11  comma-free semicolon rephrase parses cleanly as a single well-formed record
#   T12  no category field appears in any resolve_doc_set output
#   T13  no expectations field appears in any resolve_doc_set output
#   T14  unknown owner → routed to aid-researcher-architecture with a warning (non-fatal)
#   T15  dependency-free: only bash+awk used (no yq, no python, no new script)
#
# Usage:
#   bash tests/canonical/test-doc-set-read.sh [--verbose]
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

echo "== test-doc-set-read.sh =="

# ---------------------------------------------------------------------------
# Extract and source the resolve_doc_set / synth_default_seed functions
# directly from the canonical doc-set-resolve.md prose (code fences).
# This exercises exactly the canonical snippet, not a paraphrase.
# ---------------------------------------------------------------------------
DOC_SET_RESOLVE="${REPO}/canonical/skills/aid-discover/references/doc-set-resolve.md"

if [[ ! -f "$DOC_SET_RESOLVE" ]]; then
  echo "FATAL: doc-set-resolve.md not found at $DOC_SET_RESOLVE" >&2
  exit 2
fi

# Extract the two bash code blocks that contain the actual function definitions
# (synth_default_seed and resolve_doc_set). We want only fences that declare
# a function (match "function_name()") — not the accessor usage snippets.
FUNCS_FILE=$(mktemp)
trap 'rm -f "$FUNCS_FILE"' EXIT

awk '
  /^```bash/ { in_fence=1; buffer=""; next }
  /^```/ && in_fence {
    in_fence=0
    # Only emit fences that contain actual function declarations (name + parentheses)
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

# A minimal settings.yml with NO discovery.doc_set section.
settings_unset() {
  cat <<'EOF'
project:
  name: test-project
EOF
}

# A settings.yml with a concrete doc_set (3 entries).
settings_present() {
  cat <<'EOF'
project:
  name: test-project
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - schemas.md|aid-researcher-analyst|required
    - tech-debt.md|aid-researcher-quality|conditional:has legacy issues
EOF
}

# Settings with inline provenance comments on items.
settings_with_inline_comments() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - schemas.md|aid-researcher-analyst|required               # rename: data-model.md -> schemas.md
    - pipeline-contracts.md|aid-researcher-integrator|required # rename: api-contracts.md
EOF
}

# Settings where the full-line comment is AFTER the last item.
settings_comment_after_last() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - tech-debt.md|aid-researcher-quality|required
    # (drop: security-model.md is simply absent — no entry)
EOF
}

# Settings with a comma in a `when` hint (the corrupted/forbidden form).
settings_comma_in_when() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - infrastructure.md|aid-researcher-quality|conditional:has CI, CD, or deploy config
    - tech-debt.md|aid-researcher-quality|required
EOF
}

# Settings with the comma-free semicolon rephrase (the correct shipping form).
settings_semicolon_when() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - infrastructure.md|aid-researcher-quality|conditional:has CI; CD; or deploy config
    - tech-debt.md|aid-researcher-quality|required
EOF
}

# Settings with an unknown owner.
settings_unknown_owner() {
  cat <<'EOF'
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - custom-doc.md|some-unknown-agent|required
    - tech-debt.md|aid-researcher-quality|required
EOF
}

# Helper: read raw from a settings file.
read_raw() {
  local file="$1"
  bash "$SUT_SCRIPT" --file "$file" --path discovery.doc_set 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# T01: unset discovery.doc_set → synth_default_seed synthesizes default seed
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/unset.yml"
settings_unset > "$fixture"
raw=$(read_raw "$fixture")
# raw must be empty (section absent)
assert_eq "$raw" "" "T01 unset section returns empty string from read-setting.sh"

# Now call resolve_doc_set with empty raw; it should call synth_default_seed.
tsv=$(REPO="$REPO" resolve_doc_set "" 2>/dev/null)
filenames=$(echo "$tsv" | cut -f1)

assert_output_contains "$filenames" "architecture.md"      "T01 default seed contains architecture.md"
assert_output_contains "$filenames" "project-structure.md" "T01 default seed contains project-structure.md"
assert_output_contains "$filenames" "schemas.md"           "T01 default seed contains schemas.md"
assert_output_contains "$filenames" "pipeline-contracts.md" "T01 default seed contains pipeline-contracts.md"
assert_output_contains "$filenames" "feature-inventory.md" "T01 default seed contains feature-inventory.md"

# ---------------------------------------------------------------------------
# T02: default seed count matches templates on disk
# ---------------------------------------------------------------------------
template_count=$(find "$REPO/canonical/aid/templates/knowledge-base" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
seed_count=$(echo "$tsv" | grep -c .)
assert_eq "$seed_count" "$template_count" "T02 default seed row-count matches template count ($template_count)"

# ---------------------------------------------------------------------------
# T03: default seed output has exactly 3 tab-separated columns (filename owner presence)
# ---------------------------------------------------------------------------
bad_cols=$(echo "$tsv" | awk -F'\t' 'NF!=3 {print NR": "$0}')
assert_eq "$bad_cols" "" "T03 all default-seed rows have exactly 3 tab-separated columns"

# ---------------------------------------------------------------------------
# T04: present section → resolve returns exact rows
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/present.yml"
settings_present > "$fixture"
raw=$(read_raw "$fixture")
tsv=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

# Expect exactly 3 rows
row_count=$(echo "$tsv" | grep -c .)
assert_eq "$row_count" "3" "T04 present 3-entry section → 3 resolved rows"

# Row 1: architecture.md aid-researcher-architecture required
row1=$(echo "$tsv" | sed -n '1p')
assert_eq "$row1" "architecture.md	aid-researcher-architecture	required" "T04 row1 exact match"

# Row 2: schemas.md aid-researcher-analyst required
row2=$(echo "$tsv" | sed -n '2p')
assert_eq "$row2" "schemas.md	aid-researcher-analyst	required" "T04 row2 exact match"

# Row 3: tech-debt.md aid-researcher-quality conditional:has legacy issues
row3=$(echo "$tsv" | sed -n '3p')
assert_eq "$row3" "tech-debt.md	aid-researcher-quality	conditional:has legacy issues" "T04 row3 exact match"

# ---------------------------------------------------------------------------
# T05: list-filenames accessor returns filenames only (tab col1)
# ---------------------------------------------------------------------------
filenames=$(echo "$tsv" | cut -f1)
assert_output_contains "$filenames" "architecture.md"  "T05 list-filenames contains architecture.md"
assert_output_contains "$filenames" "schemas.md"       "T05 list-filenames contains schemas.md"
assert_output_contains "$filenames" "tech-debt.md"     "T05 list-filenames contains tech-debt.md"
# No owner in filenames output
assert_output_not_contains "$filenames" "aid-researcher-architecture" "T05 list-filenames has no owner field"
assert_output_not_contains "$filenames" "aid-researcher-analyst"      "T05 list-filenames has no owner field"

# ---------------------------------------------------------------------------
# T06: owner-of accessor returns correct owner for a named file
# ---------------------------------------------------------------------------
fn="schemas.md"
owner_of=$(echo "$tsv" | awk -F'\t' -v f="$fn" '$1==f{print $2}')
assert_eq "$owner_of" "aid-researcher-analyst" "T06 owner-of schemas.md is aid-researcher-analyst"

fn="architecture.md"
owner_of=$(echo "$tsv" | awk -F'\t' -v f="$fn" '$1==f{print $2}')
assert_eq "$owner_of" "aid-researcher-architecture" "T06 owner-of architecture.md is aid-researcher-architecture"

# ---------------------------------------------------------------------------
# T07: owns-<agent> accessor returns correct files for aid-researcher-quality
# ---------------------------------------------------------------------------
agent="aid-researcher-quality"
owns=$(echo "$tsv" | awk -F'\t' -v a="$agent" '$2==a{print $1}')
assert_output_contains "$owns" "tech-debt.md" "T07 owns-aid-researcher-quality contains tech-debt.md"
assert_output_not_contains "$owns" "schemas.md" "T07 owns-aid-researcher-quality does not contain schemas.md"

# ---------------------------------------------------------------------------
# T08: trailing inline # comment on an item is stripped
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/inline_comments.yml"
settings_with_inline_comments > "$fixture"
raw=$(read_raw "$fixture")
tsv_c=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

# schemas.md row: owner must be exactly aid-researcher-analyst (no comment leaked into owner)
owner_schemas=$(echo "$tsv_c" | awk -F'\t' '$1=="schemas.md"{print $2}')
assert_eq "$owner_schemas" "aid-researcher-analyst" "T08 inline comment stripped — owner is clean"

# presence must be exactly 'required' (not 'required               # rename...')
pres_schemas=$(echo "$tsv_c" | awk -F'\t' '$1=="schemas.md"{print $3}')
assert_eq "$pres_schemas" "required" "T08 inline comment stripped — presence is clean"

# pipeline-contracts.md: no provenance text in presence
pres_pc=$(echo "$tsv_c" | awk -F'\t' '$1=="pipeline-contracts.md"{print $3}')
assert_eq "$pres_pc" "required" "T08 inline comment stripped from pipeline-contracts.md presence"

# ---------------------------------------------------------------------------
# T09: full-line comment AFTER last item does NOT truncate the list
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/comment_after.yml"
settings_comment_after_last > "$fixture"
raw=$(read_raw "$fixture")
tsv_ca=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

# Must have both items present (comment after last item must not truncate)
assert_output_contains "$tsv_ca" "architecture.md" "T09 architecture.md present despite trailing comment"
assert_output_contains "$tsv_ca" "tech-debt.md"    "T09 tech-debt.md present despite trailing comment"
rows_ca=$(echo "$tsv_ca" | grep -c .)
assert_eq "$rows_ca" "2" "T09 both rows resolved — comment after last item does not truncate"

# ---------------------------------------------------------------------------
# T10a: comma-in-when — fragment 1 survives as valid aid-researcher-quality record
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/comma_when.yml"
settings_comma_in_when > "$fixture"
raw=$(read_raw "$fixture")
tsv_cw=$(REPO="$REPO" resolve_doc_set "$raw" 2>&1)
tsv_cw_stdout=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

infra_row=$(echo "$tsv_cw_stdout" | awk -F'\t' '$1=="infrastructure.md"')
assert_output_contains "$infra_row" "infrastructure.md" \
  "T10a fragment-1 infrastructure.md survives in TSV"
infra_owner=$(echo "$infra_row" | cut -f2)
assert_eq "$infra_owner" "aid-researcher-quality" \
  "T10a fragment-1 infrastructure.md resolves to aid-researcher-quality (not wrong/unknown)"

# ---------------------------------------------------------------------------
# T10b: comma-in-when — trailing fragments (no pipe) emit warn to stderr and are skipped
# ---------------------------------------------------------------------------
stderr_cw=$(REPO="$REPO" resolve_doc_set "$raw" 2>&1 >/dev/null)
# The fragments " CD" and " or deploy config" must produce warnings
assert_output_contains "$stderr_cw" "warn: malformed doc_set record" \
  "T10b malformed fragments produce warn on stderr"
# The TSV output must NOT contain a row whose filename field is a fragment (not *.md)
# Fragments " CD" and " or deploy config" must NOT appear as filenames (field 1) in the TSV.
frag_rows_cw=$(echo "$tsv_cw_stdout" | awk -F'\t' '$1 !~ /\.md$/{print $1}')
assert_eq "$frag_rows_cw" "" \
  "T10b no non-.md filename rows in resolved TSV (fragments are skipped)"
# Row count must be exactly 3 (architecture + infrastructure + tech-debt), not 5
rows_cw=$(echo "$tsv_cw_stdout" | grep -c . || true)
assert_eq "$rows_cw" "3" \
  "T10b resolved row count is 3 (fragments not added as spurious rows)"

# ---------------------------------------------------------------------------
# T10c: comma-in-when — no wrong/unknown-owner dispatch
# ---------------------------------------------------------------------------
# Every owner in the TSV must be a valid enum member (no bogus owner from the fragments)
bad_owners=$(echo "$tsv_cw_stdout" | cut -f2 | grep -vE '^(aid-researcher-scout|aid-researcher-architecture|aid-researcher-analyst|aid-researcher-integrator|aid-researcher-quality|orchestrator)$' || true)
assert_eq "$bad_owners" "" \
  "T10c all resolved owners are valid enum values (no wrong/unknown-owner dispatch)"

# ---------------------------------------------------------------------------
# T11: comma-free semicolon rephrase parses cleanly as single well-formed record
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/semicolon_when.yml"
settings_semicolon_when > "$fixture"
raw=$(read_raw "$fixture")
tsv_sw=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)
stderr_sw=$(REPO="$REPO" resolve_doc_set "$raw" 2>&1 >/dev/null)

# Must have exactly 3 rows (no extra fragments from the semicolons)
rows_sw=$(echo "$tsv_sw" | grep -c .)
assert_eq "$rows_sw" "3" "T11 semicolon rephrase gives exactly 3 rows (no extra fragments)"

infra_sw=$(echo "$tsv_sw" | awk -F'\t' '$1=="infrastructure.md"')
assert_output_contains "$infra_sw" "infrastructure.md" \
  "T11 infrastructure.md present in semicolon-rephrased output"
# Full when hint is intact
pres_sw=$(echo "$infra_sw" | cut -f3)
assert_eq "$pres_sw" "conditional:has CI; CD; or deploy config" \
  "T11 full when-hint intact in semicolon rephrase"
# No malformed warnings
assert_eq "$stderr_sw" "" "T11 no warn on stderr for semicolon rephrase"

# ---------------------------------------------------------------------------
# T12 + T13: no category or expectations in any output
# ---------------------------------------------------------------------------
# Test against present fixture (3-entry)
fixture="$TMPDIR_TEST/present.yml"
settings_present > "$fixture"
raw=$(read_raw "$fixture")
tsv_nd=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)

assert_output_not_contains "$tsv_nd" "category"     "T12 no 'category' in resolved output"
assert_output_not_contains "$tsv_nd" "expectations" "T13 no 'expectations' in resolved output"
# Also verify default seed
tsv_def=$(REPO="$REPO" resolve_doc_set "" 2>/dev/null)
assert_output_not_contains "$tsv_def" "category"     "T12 no 'category' in default seed output"
assert_output_not_contains "$tsv_def" "expectations" "T13 no 'expectations' in default seed output"

# ---------------------------------------------------------------------------
# T14: unknown owner → routed to aid-researcher-architecture with a warning
# ---------------------------------------------------------------------------
fixture="$TMPDIR_TEST/unknown_owner.yml"
settings_unknown_owner > "$fixture"
raw=$(read_raw "$fixture")
tsv_uo=$(REPO="$REPO" resolve_doc_set "$raw" 2>/dev/null)
stderr_uo=$(REPO="$REPO" resolve_doc_set "$raw" 2>&1 >/dev/null)

# custom-doc.md must appear in the TSV (not dropped)
assert_output_contains "$tsv_uo" "custom-doc.md" \
  "T14 unknown-owner doc appears in resolved TSV (non-fatal)"
# Owner must be remapped to aid-researcher-architecture
custom_owner=$(echo "$tsv_uo" | awk -F'\t' '$1=="custom-doc.md"{print $2}')
assert_eq "$custom_owner" "aid-researcher-architecture" \
  "T14 unknown owner remapped to aid-researcher-architecture"
# Warning must appear on stderr
assert_output_contains "$stderr_uo" "warn: unknown owner" \
  "T14 unknown owner produces warning on stderr"
# tech-debt.md (valid owner) still resolves correctly
td_owner=$(echo "$tsv_uo" | awk -F'\t' '$1=="tech-debt.md"{print $2}')
assert_eq "$td_owner" "aid-researcher-quality" \
  "T14 valid owners unaffected by unknown-owner fallback"

# ---------------------------------------------------------------------------
# T15: dependency-free — verify this suite uses only bash+awk (no yq/python/new script)
# ---------------------------------------------------------------------------
# Self-check: confirm yq and python3 are NOT invoked by the functions we sourced.
assert_output_not_contains "$(cat "$FUNCS_FILE")" "yq" \
  "T15 extracted functions contain no 'yq' invocation"
assert_output_not_contains "$(cat "$FUNCS_FILE")" "python" \
  "T15 extracted functions contain no 'python' invocation"
# The read-setting.sh SUT itself must not reference yq as a required binary
# (it mentions yq only in a comment about optional deferral; the core path uses awk)
assert_output_not_contains "$(grep -v '^#' "$SUT_SCRIPT")" "command -v yq" \
  "T15 read-setting.sh core path does not require yq"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
test_summary
exit $?
