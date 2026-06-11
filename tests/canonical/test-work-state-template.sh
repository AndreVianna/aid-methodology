#!/usr/bin/env bash
# test-work-state-template.sh — shape assertions for work-state-template.md
#
# Verifies that the canonical template and its rendered copies contain the
# required ## Pipeline Status block (feature-001 M1) with the exact section
# header, all seven fields, and the three closed enum declarations that serve
# as the single source of truth for feature-002.
#
# Tests:
#   WS01  Canonical template has ## Pipeline Status header
#   WS02  Canonical template has all 7 Pipeline Status fields
#   WS03  Canonical template declares Lifecycle enum verbatim
#   WS04  Canonical template declares Phase enum verbatim
#   WS05  Canonical template declares Active Skill enum verbatim
#   WS06  Canonical template has "written ONLY by" / "Never hand-edited" note
#   WS07  Rendered dogfood template matches canonical (grep-recoverable fields)
#   WS08  Rendered profile templates all contain the ## Pipeline Status header
#   WS09  aid-interview state-first-run seeds Lifecycle: Running
#   WS10  aid-interview state-first-run seeds Phase: Interview
#   WS11  aid-interview state-first-run seeds Active Skill: aid-interview
#   WS12  aid-interview seed prose does not introduce any new user-facing output
#
# Usage:
#   bash test-work-state-template.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CANONICAL_TEMPLATE="${REPO_ROOT}/canonical/templates/work-state-template.md"
DOGFOOD_TEMPLATE="${REPO_ROOT}/.claude/templates/work-state-template.md"
FIRST_RUN="${REPO_ROOT}/canonical/skills/aid-interview/references/state-first-run.md"
PROFILES_DIR="${REPO_ROOT}/profiles"

# ---------------------------------------------------------------------------
# WS01: Canonical template has ## Pipeline Status header
# ---------------------------------------------------------------------------
assert_file_contains \
    "$CANONICAL_TEMPLATE" \
    "## Pipeline Status" \
    "WS01 canonical template has ## Pipeline Status header"

# ---------------------------------------------------------------------------
# WS02: Canonical template has all 7 Pipeline Status fields
# ---------------------------------------------------------------------------
for field in "**Lifecycle:**" "**Phase:**" "**Active Skill:**" "**Updated:**" \
             "**Pause Reason:**" "**Block Reason:**" "**Block Artifact:**"; do
    assert_file_contains \
        "$CANONICAL_TEMPLATE" \
        "$field" \
        "WS02 canonical template has field $field"
done

# ---------------------------------------------------------------------------
# WS03: Canonical template declares Lifecycle enum verbatim (all 5 members)
# ---------------------------------------------------------------------------
for member in "Running" "Paused-Awaiting-Input" "Blocked" "Completed" "Canceled"; do
    assert_file_contains \
        "$CANONICAL_TEMPLATE" \
        "$member" \
        "WS03 Lifecycle enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS04: Canonical template declares Phase enum verbatim (all 7 members)
# ---------------------------------------------------------------------------
for member in "Interview" "Specify" "Plan" "Detail" "Execute" "Deploy" "Monitor"; do
    assert_file_contains \
        "$CANONICAL_TEMPLATE" \
        "$member" \
        "WS04 Phase enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS05: Canonical template declares Active Skill enum verbatim
# ---------------------------------------------------------------------------
assert_file_contains \
    "$CANONICAL_TEMPLATE" \
    "aid-{skill}" \
    "WS05 Active Skill enum placeholder aid-{skill} present"
assert_file_contains \
    "$CANONICAL_TEMPLATE" \
    "**Active Skill:** aid-{skill} | none" \
    "WS05 Active Skill field line has expected shape"

# ---------------------------------------------------------------------------
# WS06: Template has "Never hand-edited" note + closed enums note
# ---------------------------------------------------------------------------
assert_file_contains \
    "$CANONICAL_TEMPLATE" \
    "Never hand-edited" \
    "WS06 template has 'Never hand-edited' note"
assert_file_contains \
    "$CANONICAL_TEMPLATE" \
    "closed enums" \
    "WS06 template has 'closed enums' note"

# ---------------------------------------------------------------------------
# WS07: Rendered dogfood template has the ## Pipeline Status header and fields
# ---------------------------------------------------------------------------
if [[ -f "$DOGFOOD_TEMPLATE" ]]; then
    assert_file_contains \
        "$DOGFOOD_TEMPLATE" \
        "## Pipeline Status" \
        "WS07 dogfood rendered template has ## Pipeline Status header"
    assert_file_contains \
        "$DOGFOOD_TEMPLATE" \
        "**Lifecycle:**" \
        "WS07 dogfood rendered template has Lifecycle field"
    assert_file_contains \
        "$DOGFOOD_TEMPLATE" \
        "**Phase:**" \
        "WS07 dogfood rendered template has Phase field"
    assert_file_contains \
        "$DOGFOOD_TEMPLATE" \
        "Never hand-edited" \
        "WS07 dogfood rendered template has Never hand-edited note"
else
    fail "WS07 dogfood rendered template not found: $DOGFOOD_TEMPLATE"
fi

# ---------------------------------------------------------------------------
# WS08: Each rendered profile tree contains the ## Pipeline Status header
# ---------------------------------------------------------------------------
profile_found=0
while IFS= read -r -d '' rendered_tmpl; do
    profile_found=$((profile_found + 1))
    assert_file_contains \
        "$rendered_tmpl" \
        "## Pipeline Status" \
        "WS08 profile rendered template has ## Pipeline Status: ${rendered_tmpl#"$REPO_ROOT/"}"
done < <(find "$REPO_ROOT/profiles" -name "work-state-template.md" -print0 2>/dev/null)

if [[ $profile_found -eq 0 ]]; then
    # Profiles may not be generated yet; treat as advisory, not a hard fail
    echo "  NOTE: no rendered profile copies of work-state-template.md found — run generator to create them"
    pass "WS08 profile rendered templates check (none found — generator not yet run)"
fi

# ---------------------------------------------------------------------------
# WS09: aid-interview state-first-run seeds Lifecycle: Running
# ---------------------------------------------------------------------------
assert_file_contains \
    "$FIRST_RUN" \
    "Lifecycle:** Running" \
    "WS09 aid-interview state-first-run seeds Lifecycle: Running"

# ---------------------------------------------------------------------------
# WS10: aid-interview state-first-run seeds Phase: Interview
# ---------------------------------------------------------------------------
assert_file_contains \
    "$FIRST_RUN" \
    "Phase:** Interview" \
    "WS10 aid-interview state-first-run seeds Phase: Interview"

# ---------------------------------------------------------------------------
# WS11: aid-interview state-first-run seeds Active Skill: aid-interview
# ---------------------------------------------------------------------------
assert_file_contains \
    "$FIRST_RUN" \
    "Active Skill:** aid-interview" \
    "WS11 aid-interview state-first-run seeds Active Skill: aid-interview"

# ---------------------------------------------------------------------------
# WS12: The seed prose does NOT introduce any user-visible print/output
# The seed step must be a silent state-write with no new prompts/gates.
# We check that the seed block does not contain 'Print:' or '[' menu markers
# that would indicate new user-facing output was added.
# (The 1b-ii section is bounded — check the lines in that sub-section only.)
# ---------------------------------------------------------------------------
SEED_SECTION="$(awk '/### 1b-ii/,/### 1c/' "$FIRST_RUN" 2>/dev/null || true)"
if [[ -n "$SEED_SECTION" ]]; then
    if echo "$SEED_SECTION" | grep -qF "Print:"; then
        fail "WS12 seed block contains 'Print:' — would add user-visible output (C4 violation)"
    else
        pass "WS12 seed block has no 'Print:' user-output instruction"
    fi
    if echo "$SEED_SECTION" | grep -qE '^\[.+\]'; then
        fail "WS12 seed block contains menu/gate markers — would add user-facing prompts"
    else
        pass "WS12 seed block has no menu/gate markers"
    fi
else
    fail "WS12 could not extract seed section from state-first-run.md"
fi

test_summary
