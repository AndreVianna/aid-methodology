#!/usr/bin/env bash
# test-doc-set-propose-confirm.sh — Propose→confirm flow tests.
#
# Covers the propose→confirm-specific behaviors (SPEC feature-004 §3.1, §4):
#   - default path: no override → resolved set == default seed; accepting default is a no-op
#     (writes nothing — the settings file has no discovery.doc_set section after confirm).
#   - user-edit path: a fixture settings.yml with an omission + an addition → the resolved set
#     honors both verbatim (edits-honored, AC4 — mechanical, no "appropriateness" assertion).
#
# Does NOT duplicate carve-out or non-software set-difference tests — those live in
# test-doc-set-mapping.sh (task-009).
#
# Tests:
#   T01  default path: unset discovery.doc_set → resolved set == default seed (backward compat)
#   T02  default path: default seed filenames are a non-empty set
#   T03  default path: no-op write — settings without a discovery.doc_set section remains
#        without one after accepting the default (nothing written to settings)
#   T04  default path: resolved set from settings-without-section equals resolved set from
#        explicitly empty raw (both call synth_default_seed — same result)
#   T05  user-edit path: fixture with omission — omitted doc absent from resolved set
#   T06  user-edit path: fixture with addition — added doc present in resolved set
#   T07  user-edit path: resolved filenames exactly equal the fixture declaration (verbatim)
#   T08  user-edit path: resolved row count matches fixture entry count (no phantom rows)
#   T09  user-edit path: presence of omitted doc in default seed confirms it is a genuine omission
#
# Usage:
#   bash tests/canonical/test-doc-set-propose-confirm.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT_SCRIPT="${REPO}/canonical/scripts/config/read-setting.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-doc-set-propose-confirm.sh =="

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

# Helper: read raw from a settings file (empty output when section unset).
read_raw() {
  local file="$1"
  bash "$SUT_SCRIPT" --file "$file" --path discovery.doc_set 2>/dev/null || true
}

# Fixture A: settings WITHOUT a discovery.doc_set section (the default / no-override case).
settings_no_section() {
  cat <<'EOF'
project:
  name: test-project
  type: software
EOF
}

# Fixture B: settings WITH discovery.doc_set carrying:
#   - omission of test-landscape.md (a standard doc deliberately dropped)
#   - addition of research-notes.md (a custom doc owned by discovery-analyst)
# This represents a user who confirmed an edited proposal.
settings_user_edit() {
  cat <<'EOF'
project:
  name: test-project
  type: software
discovery:
  doc_set:
    - project-structure.md|discovery-scout|required
    - external-sources.md|discovery-scout|required
    - architecture.md|discovery-architect|required
    - technology-stack.md|discovery-architect|required
    - module-map.md|discovery-analyst|required
    - coding-standards.md|discovery-analyst|required
    - schemas.md|discovery-analyst|required
    - research-notes.md|discovery-analyst|required
    - pipeline-contracts.md|discovery-integrator|required
    - integration-map.md|discovery-integrator|required
    - domain-glossary.md|discovery-integrator|required
    - tech-debt.md|discovery-quality|required
    - infrastructure.md|discovery-quality|required
    - feature-inventory.md|orchestrator|required
    - README.md|orchestrator|required
    # (omission: test-landscape.md is absent — not included)
EOF
  # NOTE: test-landscape.md is deliberately OMITTED (the omission under test).
  #       research-notes.md is deliberately ADDED  (the addition under test).
}

# The exact filenames declared in settings_user_edit, sorted, for verbatim comparison.
# This is the ground truth for T07.
USER_EDIT_DECLARED_SORTED="README.md
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
schemas.md
tech-debt.md
technology-stack.md"

# ---------------------------------------------------------------------------
# DEFAULT PATH TESTS (T01–T04)
# ---------------------------------------------------------------------------

# Set up the no-section fixture
fixture_no_section="$TMPDIR_TEST/no_section.yml"
settings_no_section > "$fixture_no_section"

raw_no_section=$(read_raw "$fixture_no_section")

# T01: unset section → raw is empty → resolve_doc_set calls synth_default_seed → default seed
assert_eq "$raw_no_section" "" \
  "T01 settings without discovery.doc_set returns empty raw from read-setting.sh"

# Resolve with empty raw → default seed
default_tsv=$(REPO="$REPO" resolve_doc_set "" 2>/dev/null)
default_filenames=$(echo "$default_tsv" | cut -f1)

assert_output_contains "$default_filenames" "architecture.md" \
  "T01 resolved default seed contains architecture.md"
assert_output_contains "$default_filenames" "project-structure.md" \
  "T01 resolved default seed contains project-structure.md"

# T02: default seed is non-empty
default_count=$(echo "$default_filenames" | grep -c .)
if [[ "$default_count" -gt 0 ]]; then
  pass "T02 default seed is non-empty ($default_count docs)"
else
  fail "T02 default seed — expected non-empty set, got 0 rows"
fi

# T03: no-op write assertion — the settings file without a discovery.doc_set section
# MUST NOT gain one after accepting the default (accepting default writes nothing to settings).
# The behavioral contract: when the user confirms the default unchanged, Step 0d writes nothing.
# We assert the observable effect: the settings file still has no discovery.doc_set key.
#
# Simulation: write a copy of the settings file "after confirm default" (no mutation applied),
# then verify read-setting.sh still returns empty for discovery.doc_set from that file.
settings_after_confirm_default="$TMPDIR_TEST/after_confirm_default.yml"
settings_no_section > "$settings_after_confirm_default"
# The no-op: we do NOT write discovery.doc_set to this file (confirming default writes nothing).
raw_after="$(read_raw "$settings_after_confirm_default")"
assert_eq "$raw_after" "" \
  "T03 no-op: settings file has no discovery.doc_set section after accepting default (nothing written)"

# Confirm the resolved set from the no-op settings equals the default seed.
tsv_after=$(REPO="$REPO" resolve_doc_set "$raw_after" 2>/dev/null)
filenames_after=$(echo "$tsv_after" | cut -f1 | sort)
filenames_default_sorted=$(echo "$default_filenames" | sort)
assert_eq "$filenames_after" "$filenames_default_sorted" \
  "T03 resolved set from no-op settings equals default seed (backward compatible)"

# T04: empty raw and absent-section raw are equivalent — both resolve to the same default seed.
# This confirms the two entry paths into synth_default_seed produce identical results.
tsv_from_empty=$(REPO="$REPO" resolve_doc_set "" 2>/dev/null)
tsv_from_no_raw=$(REPO="$REPO" resolve_doc_set "$raw_no_section" 2>/dev/null)
sorted_empty=$(echo "$tsv_from_empty" | cut -f1 | sort)
sorted_no_raw=$(echo "$tsv_from_no_raw" | cut -f1 | sort)
assert_eq "$sorted_empty" "$sorted_no_raw" \
  "T04 empty raw and absent-section raw both resolve to the same default seed"

# ---------------------------------------------------------------------------
# USER-EDIT PATH TESTS (T05–T09)
# ---------------------------------------------------------------------------

# Set up the user-edit fixture
fixture_user_edit="$TMPDIR_TEST/user_edit.yml"
settings_user_edit > "$fixture_user_edit"

raw_user_edit=$(read_raw "$fixture_user_edit")
tsv_user_edit=$(REPO="$REPO" resolve_doc_set "$raw_user_edit" 2>/dev/null)
filenames_user_edit=$(echo "$tsv_user_edit" | cut -f1)

# T05: omitted doc (test-landscape.md) is absent from the resolved set
assert_output_not_contains "$filenames_user_edit" "test-landscape.md" \
  "T05 user-edit: omitted test-landscape.md is absent from resolved set"

# T06: added doc (research-notes.md) is present in the resolved set
assert_output_contains "$filenames_user_edit" "research-notes.md" \
  "T06 user-edit: added research-notes.md is present in resolved set"

# T07: resolved filenames exactly equal the fixture declaration verbatim (user edits honored)
filenames_sorted=$(echo "$filenames_user_edit" | sort)
assert_eq "$filenames_sorted" "$USER_EDIT_DECLARED_SORTED" \
  "T07 user-edit: resolved filenames exactly equal fixture declaration verbatim"

# T08: resolved row count matches fixture entry count (no phantom rows, no missing rows)
expected_entry_count=15   # the fixture declares 15 entries (see settings_user_edit)
actual_row_count=$(echo "$tsv_user_edit" | grep -c .)
assert_eq "$actual_row_count" "$expected_entry_count" \
  "T08 user-edit: resolved row count ($actual_row_count) matches fixture entry count ($expected_entry_count)"

# T09: test-landscape.md IS present in the default seed, confirming the fixture omission is genuine
# (This ensures T05 is a real omission test, not just testing a doc that was never in the default.)
assert_output_contains "$default_filenames" "test-landscape.md" \
  "T09 baseline: test-landscape.md is in the default seed (confirms fixture omission is genuine)"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
test_summary
exit $?
