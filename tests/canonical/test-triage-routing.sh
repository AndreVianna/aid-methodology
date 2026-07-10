#!/usr/bin/env bash
# test-triage-routing.sh -- task-028 (work-001-lite-aid-skills, feature-014 AC-13/FR-13):
# aid-triage routing-mapping test.
#
# `/aid-triage` is agent-executed PROSE (INTAKE -> CLASSIFY -> SUGGEST -> HALT) -- a
# deterministic canonical test cannot "run" the router. This suite is therefore CONTRACT +
# FIXTURE-SHAPE, matching the other work-001 shortcut-engine/router suites
# (test-catalog-dirs-parity.sh, test-fix-family-scaffold.sh):
#
#   1. Fixture mapping table -- for each of the 6 representative descriptions in
#      feature-014/SPEC.md's own testing-strategy table, assert that BOTH (a) the
#      state-classify.md/state-suggest.md heuristic tables contain the rule that would fire
#      for that description, AND (b) the catalog carries the expected resolved target as a
#      canonical (non-alias) row whose `intent:` text plausibly matches the description.
#   2. Routes-only proof (FR-13) -- `allowed-tools` frontmatter excludes Write/Edit; no file
#      under `canonical/skills/aid-triage/` describes creating a `.aid/work-*/` folder or a
#      `STATE.md` (every mention is a descriptive NEGATION -- "no work folder", "no
#      STATE.md" -- never an instruction to create one).
#   3. Catalog resolution -- every non-full-path fixture target exists as a canonical
#      (`alias_of: null`) row in shortcut-catalog.yml (never an alias row).
#
# No agent is invoked; nothing here dispatches aid-interviewer.
#
# Usage:
#   bash tests/canonical/test-triage-routing.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRIAGE_DIR="${REPO_ROOT}/canonical/skills/aid-triage"
SKILL_MD="${TRIAGE_DIR}/SKILL.md"
CLASSIFY_MD="${TRIAGE_DIR}/references/state-classify.md"
SUGGEST_MD="${TRIAGE_DIR}/references/state-suggest.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"

echo "=== aid-triage routing-mapping test (task-028, feature-014 AC-13/FR-13) ==="

assert_file_exists "$SKILL_MD" "TR00a aid-triage/SKILL.md exists"
assert_file_exists "$CLASSIFY_MD" "TR00b state-classify.md exists"
assert_file_exists "$SUGGEST_MD" "TR00c state-suggest.md exists"
assert_file_exists "$CATALOG" "TR00d shortcut-catalog.yml exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

SKILL_TXT=$(cat "$SKILL_MD")
CLASSIFY_TXT=$(cat "$CLASSIFY_MD")
SUGGEST_TXT=$(cat "$SUGGEST_MD")
CATALOG_TXT=$(cat "$CATALOG")

# ===========================================================================
# Part 1 -- Routes-only proof (FR-13)
# ===========================================================================
echo "--- Part 1: routes-only proof (FR-13) ---"

FM_ALLOWED=$(awk '/^allowed-tools:/{print; exit}' "$SKILL_MD")
assert_output_contains "$FM_ALLOWED" "Read, Glob, Grep" "TR01a allowed-tools is exactly Read, Glob, Grep"
if echo "$FM_ALLOWED" | grep -qE 'Write|Edit'; then
    fail "TR01b allowed-tools excludes Write/Edit -- found: ${FM_ALLOWED}"
else
    pass "TR01b allowed-tools excludes Write/Edit"
fi

# No file under aid-triage/ ever INSTRUCTS creation of a work folder or STATE.md -- every
# mention is a descriptive negation. Assert no "Write(" tool-call form and no directive verb
# (create/write/mkdir) immediately paired with ".aid/work" or "STATE.md" anywhere in the skill.
if grep -rEq '\bWrite\(' "$TRIAGE_DIR"; then
    fail "TR02a no Write( tool-invocation form anywhere under aid-triage/"
else
    pass "TR02a no Write( tool-invocation form anywhere under aid-triage/"
fi
# Excludes lines carrying the standalone word "no" -- every real hit in this small,
# hand-authored corpus is a descriptive negation ("no scaffold, no work folder, no
# STATE.md"); a genuine directive ("Create .aid/work-NNN/...") would carry no such negation.
DIRECTIVE_HITS=$(grep -rEi '(create|write|scaffold|mkdir)[^.]{0,40}(\.aid/work|STATE\.md)' "$TRIAGE_DIR" --include='*.md' | grep -viE '\bno\b' || true)
if [[ -n "$DIRECTIVE_HITS" ]]; then
    fail "TR02b no directive verb (create/write/scaffold/mkdir) paired with .aid/work-*/ or STATE.md -- found: ${DIRECTIVE_HITS}"
else
    pass "TR02b no directive verb (create/write/scaffold/mkdir) paired with .aid/work-*/ or STATE.md"
fi
assert_output_contains "$SKILL_TXT" "no \`.aid/work-*/\`" "TR02c SKILL.md explicitly states no .aid/work-*/ folder is created"
assert_output_contains "$SKILL_TXT" "no \`STATE.md\`" "TR02d SKILL.md explicitly states no STATE.md is created"

# ===========================================================================
# Part 2 -- Fixture mapping table (AC-13)
# feature-014/SPEC.md Testing strategy's own 6-row table, re-checked against the classify/
# suggest prose tables + the real catalog.
# ===========================================================================
echo ""
echo "--- Part 2: fixture mapping table (AC-13) ---"

# TR-10: workType heuristic table -- Step 1 of state-classify.md (3 rows, all present).
assert_output_contains "$CLASSIFY_TXT" \
    'Broken / observed-wrong behaviour; something worked before | `bug-fix`' \
    "TR10a workType heuristic: broken/observed-wrong -> bug-fix"
assert_output_contains "$CLASSIFY_TXT" \
    'Net-new capability or net-new artifact (incl. new docs, reports, ADRs) | `new-feature`' \
    "TR10b workType heuristic: net-new capability/artifact -> new-feature"
assert_output_contains "$CLASSIFY_TXT" \
    'Change / rename / improve an existing working artifact (incl. editing existing docs) | `refactor`' \
    "TR10c workType heuristic: change/rename/improve -> refactor"

# TR-11: scope-judgment signals -- Step 2 (single well-scoped vs broad/multi-activity).
assert_output_contains "$CLASSIFY_TXT" \
    'One concrete target artifact (an endpoint, entity, class, rule, doc, page, dataset...) and one clear action on it | Single well-scoped change' \
    "TR11a scope signal: one concrete target + one action -> single well-scoped"
assert_output_contains "$CLASSIFY_TXT" \
    'Multiple unrelated targets, a whole subsystem, "and" chains of distinct activities, or no concrete target named at all | Broad / multi-activity / ambiguous' \
    "TR11b scope signal: whole subsystem/no concrete target -> broad/multi-activity/ambiguous"
assert_output_contains "$CLASSIFY_TXT" \
    "Broad or ambiguous always" \
    "TR11c broad/ambiguous always recommends the full path (conservative short-circuit)"

# TR-12: narrow-by-workType table -- Step 3 (bug-fix->G6, refactor->G5, new-feature->G4/G3/G7/G8/G11).
assert_output_contains "$CLASSIFY_TXT" '| `bug-fix` | G6 (`aid-fix`)' "TR12a narrowing: bug-fix -> G6 (aid-fix)"
assert_output_contains "$CLASSIFY_TXT" '| `refactor` | G5 (`aid-change[-artifact]`, `aid-refactor`)' "TR12b narrowing: refactor -> G5"
assert_output_contains "$CLASSIFY_TXT" 'G4 (`aid-create[-artifact]`), G3' "TR12c narrowing: new-feature -> G4 (+G3/G7/G8/G11)"
# TR-12d/e: widened narrowing (v2.1.0 coverage-gap follow-on) surfaces the new-family verbs --
# refactor's G5 hint widens to aid-remove/aid-deprecate/aid-migrate, and both refactor's and
# new-feature's G11 hint widens to aid-review/aid-research.
assert_output_contains "$CLASSIFY_TXT" "G5's \`aid-remove\`, \`aid-deprecate\`, \`aid-migrate\`" \
    "TR12d widened narrowing: refactor -> G5 also surfaces aid-remove/aid-deprecate/aid-migrate"
assert_output_contains "$CLASSIFY_TXT" "G11 (\`aid-review\`, \`aid-research\`)" \
    "TR12e widened narrowing: refactor -> G11 surfaces aid-review/aid-research"
assert_output_contains "$CLASSIFY_TXT" 'G11 (`aid-report`, `aid-show-dashboard`, `aid-review`, `aid-research`)' \
    "TR12f widened narrowing: new-feature -> G11 surfaces aid-review/aid-research"

# TR-13: Case C (broad/ambiguous/no-candidate) recommends /aid-describe.
assert_output_contains "$SUGGEST_TXT" "This looks broad or ambiguous for a single direct-entry shortcut." \
    "TR13a Case C emits the broad/ambiguous framing"
assert_output_contains "$SUGGEST_TXT" "Full path via /aid-describe (recommended)" \
    "TR13b Case C recommends /aid-describe"

# TR-14: Case A (single clear winner) emits the /{best-row.name} straw-man.
assert_output_contains "$SUGGEST_TXT" "best entry: /{best-row.name}" \
    "TR14 Case A proposes /{best-row.name} as the reflect-back straw-man"

# --- The 6-row fixture table itself: each row cross-checked against classify.md's rules
#     (already asserted above) AND the real catalog row's {group, intent}. ---
declare -A FIXTURES=(
    ["fix the login crash"]="aid-fix|G6|Diagnose and correct a defect, regression, incident, or vulnerability."
    ["add a /orders REST endpoint"]="aid-create-api|G4|Create an API endpoint / middleware (contract, handler, validation)."
    ["rename OrderSvc everywhere"]="aid-refactor|G5|Restructure or optimize code without changing behavior (rename, restructure, or improve performance)."
    ["write an ADR for the DB choice"]="aid-document-decision|G8|Write an ADR: context, decision, alternatives, consequences."
    # v2.1.0 coverage-gap follow-on: new-family verbs surfaced by the widened narrowing
    # (TR12d/TR12e/TR12f above) -- G5's aid-remove and G11's aid-review.
    ["remove the /orders endpoint"]="aid-remove|G5|Remove or delete a code artifact, endpoint, dependency, feature, or dead code; update dependents, tests, and docs."
    ["review this change"]="aid-review|G11|Review/assess an existing artifact -- code, a change/diff, or a design -- against criteria; produce findings + recommendations."
)

for description in "${!FIXTURES[@]}"; do
    IFS='|' read -r expected_name expected_group expected_intent <<< "${FIXTURES[$description]}"

    # a) the catalog carries the expected row, canonical (alias_of: null), correct group.
    row_block=$(awk -v n="$expected_name" '
        BEGIN{on=0}
        /^  - name:/ {
            line=$0; sub(/^  - name:[[:space:]]*/, "", line);
            if (on) { on=0 }
            if (line == n) { on=1 }
        }
        on { print }
    ' "$CATALOG")

    if [[ -z "$row_block" ]]; then
        fail "TR20 [\"${description}\"] -> ${expected_name}: catalog row not found"
        continue
    fi
    pass "TR20 [\"${description}\"] -> ${expected_name}: catalog row exists"

    assert_output_contains "$row_block" "alias_of: null" \
        "TR21 [\"${description}\"] -> ${expected_name}: canonical row (alias_of: null)"
    assert_output_contains "$row_block" "group: ${expected_group}" \
        "TR22 [\"${description}\"] -> ${expected_name}: group ${expected_group}"
    assert_output_contains "$row_block" "intent: \"${expected_intent}\"" \
        "TR23 [\"${description}\"] -> ${expected_name}: intent matches expected semantic target"
done

# --- Broad/ambiguous fixtures: no single-row match; both resolve to /aid-describe. ---
BROAD_DESC="rewrite the billing subsystem across 4 services"
if echo "$BROAD_DESC" | grep -qiE 'subsystem|across [0-9]+ services'; then
    pass "TR30a [\"${BROAD_DESC}\"] carries the broad/multi-activity signal (whole subsystem, multiple services)"
else
    fail "TR30a [\"${BROAD_DESC}\"] expected to carry the broad/multi-activity signal"
fi
# Cross-check: the fired scope signal is documented in state-classify.md Step 2 (asserted at
# TR11b above) and its resolution is Case C -> /aid-describe (asserted at TR13a/TR13b above).

AMBIGUOUS_DESC="something with the reports maybe"
if echo "$AMBIGUOUS_DESC" | grep -qiE '^[a-z ]*$' && ! echo "$AMBIGUOUS_DESC" | grep -qiE 'endpoint|entity|class|rule|doc|page|dataset'; then
    pass "TR30b [\"${AMBIGUOUS_DESC}\"] names no concrete target artifact (ambiguous signal)"
else
    fail "TR30b [\"${AMBIGUOUS_DESC}\"] expected to name no concrete target artifact"
fi

# ===========================================================================
# Part 3 -- Catalog resolution: every fixture-suggested name is a canonical row.
# ===========================================================================
echo ""
echo "--- Part 3: catalog resolution (every suggested name is canonical) ---"

for expected_name in aid-fix aid-create-api aid-refactor aid-document-decision aid-remove aid-review; do
    ALIAS_CHECK=$(awk -v n="$expected_name" '
        BEGIN{on=0}
        /^  - name:/ {
            line=$0; sub(/^  - name:[[:space:]]*/, "", line);
            if (on) { on=0 }
            if (line == n) { on=1 }
        }
        on && /^    alias_of:/ { print; on=0 }
    ' "$CATALOG")
    assert_output_contains "$ALIAS_CHECK" "alias_of: null" \
        "TR40 [${expected_name}] resolves to a canonical (non-alias) catalog row"
done

# The broad/ambiguous fixtures resolve to /aid-describe -- a standalone skill, deliberately
# NOT a shortcut-catalog.yml row (feature-014/SPEC.md: "it reads the catalog, it is not in
# it"). Confirm that invariant directly.
if grep -qE '^  - name: aid-describe$' "$CATALOG"; then
    fail "TR41 aid-describe is deliberately NOT a shortcut-catalog.yml row"
else
    pass "TR41 aid-describe is deliberately NOT a shortcut-catalog.yml row (standalone full-path skill)"
fi
assert_file_exists "${REPO_ROOT}/canonical/skills/aid-describe/SKILL.md" \
    "TR42 aid-describe/SKILL.md exists (the full-path fallback target)"

# ===========================================================================
# Part 4 -- QUESTION route (v2.1.0 coverage-gap follow-on): Step 0 short-circuit ->
# Case D -> suggests /aid-ask.
# ===========================================================================
echo ""
echo "--- Part 4: QUESTION route -- Step 0 short-circuit -> Case D -> /aid-ask ---"

declare -A QUESTION_FIXTURES=(
    ["why does the login handler fail on unicode passwords?"]=1
    ["where is rate limiting handled in the API layer?"]=1
)
for description in "${!QUESTION_FIXTURES[@]}"; do
    if echo "$description" | grep -qiE '\?$' && echo "$description" | grep -qiE '^(why|where|how|what|does|is|can|should|which)\b'; then
        pass "TR50 [\"${description}\"] carries the QUESTION interrogative signal (state-classify.md Step 0)"
    else
        fail "TR50 [\"${description}\"] expected to carry the QUESTION interrogative signal"
    fi
done

assert_output_contains "$CLASSIFY_TXT" "Step 0: QUESTION short-circuit" \
    "TR51 state-classify.md documents the QUESTION short-circuit (Step 0)"
assert_output_contains "$CLASSIFY_TXT" "Hand off directly to" \
    "TR52 Step 0 hands off directly to SUGGEST Case D on a QUESTION match"
assert_output_contains "$SUGGEST_TXT" "Case D -- QUESTION" \
    "TR53 state-suggest.md documents Case D (the QUESTION route)"
assert_output_contains "$SUGGEST_TXT" '/aid-ask "{description}"' \
    "TR54 Case D suggests /aid-ask (not its canonical form /aid-query-kb)"

# aid-ask itself: a repurpose:true alias row (hand-authored Q&A entry point, not a
# generated thin doorway) resolving to the canonical aid-query-kb.
ASK_ROW=$(awk -v n="aid-ask" '
    BEGIN{on=0}
    /^  - name:/ {
        line=$0; sub(/^  - name:[[:space:]]*/, "", line);
        if (on) { on=0 }
        if (line == n) { on=1 }
    }
    on { print }
' "$CATALOG")
assert_output_contains "$ASK_ROW" "alias_of: aid-query-kb" \
    "TR55a aid-ask resolves to canonical aid-query-kb in the catalog"
assert_output_contains "$ASK_ROW" "repurpose: true" \
    "TR55b aid-ask is a repurpose:true row (hand-authored, not a generated doorway)"
assert_file_exists "${REPO_ROOT}/canonical/skills/aid-ask/SKILL.md" \
    "TR55c aid-ask/SKILL.md exists (hand-authored friendly alias)"

# The Case D exception to "canonical names only" is documented, not silently contradicted.
assert_output_contains "$SKILL_TXT" "Intended exception: Case D" \
    "TR56 SKILL.md documents Case D as an intended exception to the canonical-names-only rule"

echo ""
test_summary
