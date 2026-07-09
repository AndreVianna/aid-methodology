#!/usr/bin/env bash
# test-cutover-no-dangling.sh -- task-031 (work-001-lite-aid-skills, feature-002 AC-5/C-4):
# broadened no-dangling + mirror-deletion guard test.
#
# The recipe-catalog removal (feature-002) deletes canonical/aid/recipes/,
# parse-recipe.sh, recipe-template.md, specs/lite-spec-template.md, and 7
# canonical/skills/aid-describe/references/*.md lite/triage reference files, and edits
# work-state-template.md to drop the `## Triage` / `## Escalation Carry` STATE blocks.
# Because a `canonical/` deletion flows through the emission-manifest pure-mirror-deletion
# boundary (C-4), the same absence must hold in every rendered profile and the dogfood
# `.claude/`.
#
# Two parts:
#   1. No-dangling grep over ALL of `canonical/` (not just skills/scripts/templates) -- the
#      scope is deliberately broad because the precedent dangling `state-triage.md` cite
#      lived in `aid-discover/references/state-generate.md`, which a narrower scope missed
#      (feature-002/SPEC.md). The `## Triage` / `## Escalation Carry` STATE-block check
#      excludes matches preceded by a THIRD `#` (i.e. a `### Triage (...)` heading-format
#      EXAMPLE elsewhere in aid-discover's glossary-authoring instructions is a different,
#      unrelated concept that happens to share the word "Triage" -- not a dangling
#      reference to the deleted STATE.md block).
#   2. Mirror-deletion assertion -- inspects the ALREADY-RENDERED `profiles/*/` and the
#      dogfood `.claude/` directly on disk (this suite never invokes `run_generator.py`);
#      none of the 5 profiles nor dogfood contain `aid/recipes/`,
#      `aid/scripts/interview/parse-recipe.sh`, `recipe-template.md`, or
#      `specs/lite-spec-template.md`.
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer. Does NOT run
# `run_generator.py` -- mirror-deletion is checked against whatever render is currently on
# disk, corroborated by the existing `test-dogfood-byte-identity.sh` suite (run separately,
# discovered by the same `tests/run-all.sh` glob).
#
# Usage:
#   bash tests/canonical/test-cutover-no-dangling.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL="${REPO_ROOT}/canonical"

echo "=== Broadened no-dangling + mirror-deletion guard (task-031, feature-002 AC-5/C-4) ==="

assert_dir_exists "$CANONICAL" "CND00 canonical/ exists"
if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ===========================================================================
# Part 1 -- No-dangling grep over ALL of canonical/
# ===========================================================================
echo "--- Part 1: no-dangling grep (ALL of canonical/) ---"

# CND-01..07: the 7 deleted aid-describe lite/triage reference filenames.
for fname in state-triage.md state-condensed-intake.md state-task-breakdown.md \
             state-lite-review.md state-lite-done.md recipe-to-lite-escalation.md \
             lite-to-full-escalation.md; do
    HITS=$(grep -rn --include='*.md' --include='*.sh' --include='*.yml' -- "$fname" "$CANONICAL" 2>/dev/null || true)
    if [[ -n "$HITS" ]]; then
        fail "CND01 [${fname}] no surviving canonical/ reference -- found: ${HITS}"
    else
        pass "CND01 [${fname}] no surviving canonical/ reference"
    fi
done

# CND-08: no surviving reference to recipes/ (the deleted catalog directory).
HITS=$(grep -rn --include='*.md' --include='*.sh' --include='*.yml' -- "recipes/" "$CANONICAL" 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
    fail "CND08 no surviving canonical/ reference to 'recipes/' -- found: ${HITS}"
else
    pass "CND08 no surviving canonical/ reference to 'recipes/'"
fi

# CND-09: no surviving reference to parse-recipe (the retired script + its test harness).
HITS=$(grep -rn --include='*.md' --include='*.sh' --include='*.yml' -- "parse-recipe" "$CANONICAL" 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
    fail "CND09 no surviving canonical/ reference to 'parse-recipe' -- found: ${HITS}"
else
    pass "CND09 no surviving canonical/ reference to 'parse-recipe'"
fi

# CND-09b..e: the deleted aid-describe lite-path STATE-NAME tokens as free text (not just
# filenames) -- closes the gap that let stale `LITE-REVIEW` / `TASK-BREAKDOWN` prose
# references survive the filename + block-heading greps. Scoped to the four UNAMBIGUOUS
# tokens (no legitimate surviving use anywhere in canonical/); `TRIAGE` is intentionally
# omitted because `aid-triage` and the title-case `### Triage (...)` heading-format examples
# are live, distinct concepts.
for tok in CONDENSED-INTAKE TASK-BREAKDOWN LITE-REVIEW LITE-DONE; do
    HITS=$(grep -rn --include='*.md' --include='*.sh' --include='*.yml' -- "$tok" "$CANONICAL" 2>/dev/null || true)
    if [[ -n "$HITS" ]]; then
        fail "CND09b [${tok}] no surviving canonical/ reference to the deleted lite-path state token -- found: ${HITS}"
    else
        pass "CND09b [${tok}] no surviving canonical/ reference to the deleted lite-path state token"
    fi
done

# CND-10/11: the deleted `## Triage` / `## Escalation Carry` work-state-template.md
# STATE blocks. Excludes any match immediately preceded by a third '#' (a `### Triage
# (...)` heading-format example is a DIFFERENT concept -- aid-discover's glossary-heading
# rules -- not a dangling reference to the deleted STATE.md section).
HITS=$(grep -rnE --include='*.md' '(^|[^#])## Triage' "$CANONICAL" 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
    fail "CND10 no surviving canonical/ reference to the deleted \`## Triage\` STATE block -- found: ${HITS}"
else
    pass "CND10 no surviving canonical/ reference to the deleted \`## Triage\` STATE block"
fi

HITS=$(grep -rnE --include='*.md' '(^|[^#])## Escalation Carry' "$CANONICAL" 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
    fail "CND11 no surviving canonical/ reference to the deleted \`## Escalation Carry\` STATE block -- found: ${HITS}"
else
    pass "CND11 no surviving canonical/ reference to the deleted \`## Escalation Carry\` STATE block"
fi

# CND-12: the actual `## Triage` / `## Escalation Carry` H2 headings no longer exist as
# real sections of work-state-template.md (positive confirmation the deletion landed, not
# just that nothing cites it).
TEMPLATE="${CANONICAL}/aid/templates/work-state-template.md"
assert_file_exists "$TEMPLATE" "CND12a work-state-template.md exists"
if [[ -f "$TEMPLATE" ]]; then
    if grep -qE '^## Triage$|^## Escalation Carry$' "$TEMPLATE"; then
        fail "CND12b work-state-template.md carries no literal ## Triage / ## Escalation Carry heading"
    else
        pass "CND12b work-state-template.md carries no literal ## Triage / ## Escalation Carry heading"
    fi
fi

# CND-13: sanity guard on the exclusion rule itself -- the unrelated "### Triage (full vs
# lite path)" heading-format example in aid-discover legitimately still exists (proves the
# exclusion above is filtering a real, intentional, unrelated occurrence -- not silently
# widening the pattern to hide a real miss).
if grep -rq '### Triage (full vs lite path)' "${CANONICAL}/skills/aid-discover/" 2>/dev/null; then
    pass "CND13 sanity: the unrelated aid-discover heading-format example still exists (exclusion is narrow, not a blanket skip)"
else
    fail "CND13 sanity: expected the unrelated aid-discover heading-format example to still be present"
fi

# ===========================================================================
# Part 2 -- Mirror-deletion assertion (inspect already-rendered profiles + dogfood;
# this suite never invokes run_generator.py).
# ===========================================================================
echo ""
echo "--- Part 2: mirror-deletion (5 profiles + dogfood; no run_generator.py) ---"

declare -A MIRROR_ROOTS=(
    ["claude-code"]="${REPO_ROOT}/profiles/claude-code/.claude"
    ["antigravity"]="${REPO_ROOT}/profiles/antigravity/.agent"
    ["codex"]="${REPO_ROOT}/profiles/codex/.codex"
    ["copilot-cli"]="${REPO_ROOT}/profiles/copilot-cli/.github"
    ["cursor"]="${REPO_ROOT}/profiles/cursor/.cursor"
    ["dogfood"]="${REPO_ROOT}/.claude"
)

for label in "${!MIRROR_ROOTS[@]}"; do
    root="${MIRROR_ROOTS[$label]}"
    if [[ ! -d "$root" ]]; then
        fail "CND20 [${label}] mirror root exists at ${root}"
        continue
    fi
    pass "CND20 [${label}] mirror root exists"

    FOUND=$(find "$root" -path '*aid/recipes*' -o -name 'parse-recipe.sh' -o -name 'recipe-template.md' -o -path '*specs/lite-spec-template.md' 2>/dev/null || true)
    if [[ -n "$FOUND" ]]; then
        fail "CND21 [${label}] no aid/recipes/, parse-recipe.sh, recipe-template.md, or specs/lite-spec-template.md -- found: ${FOUND}"
    else
        pass "CND21 [${label}] no aid/recipes/, parse-recipe.sh, recipe-template.md, or specs/lite-spec-template.md"
    fi
done

echo ""
test_summary
