#!/usr/bin/env bash
# test-describe-full-only.sh -- task-032 (work-001-lite-aid-skills, feature-013 AC-14/C-3):
# aid-describe full-only + engine-preserved test.
#
# `aid-describe` is agent-executed PROSE (FIRST-RUN -> Q-AND-A -> CONTINUE -> [DESCRIBE-SEED]
# -> COMPLETION) -- a deterministic canonical test cannot "run" the interview. This suite is
# therefore CONTRACT + FIXTURE-SHAPE, matching the other work-001 shortcut-engine suites.
#
#   Part 1 -- Full-only assertion (AC-14):
#     - frontmatter `State machine:` line has no TRIAGE/CONDENSED-INTAKE/LITE- token.
#     - the `## Dispatch` table has no row whose Detail path resolves to any of the 7
#       deleted reference files.
#     - FIRST-RUN and Q-AND-A both advance to CONTINUE (scripted read of each reference
#       doc's own `**Advance:**` line -- the direct, deterministic proxy for "no lite
#       branch, no triage prompt").
#
#   Part 2 -- Engine-preserved assertion (C-3):
#     - all 13 surviving reference files exist (6 untouched + 7 rewired; 20 - 7 deleted).
#     - the D1 opener text is byte-identical between `elicitation-engine.md` (the
#       canonical source) and `state-continue.md` (the new invocation site, per feature-013
#       "the D1 opener relocation").
#     - the five-step selector's step headings are present, unchanged, in order.
#     - fixture-shape: a hand-authored "all sections Pending" STATE.md proves the documented
#       fire-once condition that makes CONTINUE emit the D1 opener; a second fixture ("one
#       section Partial") proves the same condition correctly does NOT re-fire it.
#
# No agent is invoked; nothing here dispatches aid-interviewer/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-describe-full-only.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESCRIBE_DIR="${REPO_ROOT}/canonical/skills/aid-describe"
SKILL_MD="${DESCRIBE_DIR}/SKILL.md"
REFS_DIR="${DESCRIBE_DIR}/references"
ENGINE_MD="${REFS_DIR}/elicitation-engine.md"
CONTINUE_MD="${REFS_DIR}/state-continue.md"
FIRST_RUN_MD="${REFS_DIR}/state-first-run.md"
QANDA_MD="${REFS_DIR}/state-q-and-a.md"

echo "=== aid-describe full-only + engine-preserved (task-032, feature-013 AC-14/C-3) ==="

assert_file_exists "$SKILL_MD" "DFO00a aid-describe/SKILL.md exists"
assert_dir_exists "$REFS_DIR" "DFO00b aid-describe/references/ exists"
assert_file_exists "$ENGINE_MD" "DFO00c elicitation-engine.md exists"
assert_file_exists "$CONTINUE_MD" "DFO00d state-continue.md exists"
assert_file_exists "$FIRST_RUN_MD" "DFO00e state-first-run.md exists"
assert_file_exists "$QANDA_MD" "DFO00f state-q-and-a.md exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

SKILL_TXT=$(cat "$SKILL_MD")

# ===========================================================================
# Part 1 -- Full-only assertion (AC-14)
# ===========================================================================
echo "--- Part 1: full-only assertion (AC-14) ---"

# DFO-01: frontmatter State machine line has no TRIAGE/CONDENSED-INTAKE/LITE- token.
STATE_MACHINE_LINE=$(awk '/State machine:/{print; exit}' "$SKILL_MD")
if [[ -z "$STATE_MACHINE_LINE" ]]; then
    fail "DFO01a frontmatter carries a 'State machine:' line"
else
    pass "DFO01a frontmatter carries a 'State machine:' line"
fi
if echo "$STATE_MACHINE_LINE" | grep -qE 'TRIAGE|CONDENSED-INTAKE|LITE-'; then
    fail "DFO01b State machine line has no TRIAGE/CONDENSED-INTAKE/LITE- token -- found: ${STATE_MACHINE_LINE}"
else
    pass "DFO01b State machine line has no TRIAGE/CONDENSED-INTAKE/LITE- token"
fi
assert_output_contains "$STATE_MACHINE_LINE" "FIRST-RUN -> Q-AND-A -> CONTINUE" \
    "DFO01c State machine line is the full-only spine (FIRST-RUN -> Q-AND-A -> CONTINUE)"

# DFO-02: no Dispatch-table row's Detail path resolves to a deleted reference file.
DELETED_REFS=(state-triage.md state-condensed-intake.md state-task-breakdown.md \
              state-lite-review.md state-lite-done.md recipe-to-lite-escalation.md \
              lite-to-full-escalation.md)
DISPATCH_BLOCK=$(awk '/^## Dispatch$/{f=1} f{print} f && /^---$/ && NR>1 && seen{exit} f && /^\|/{seen=1}' "$SKILL_MD")
for ref in "${DELETED_REFS[@]}"; do
    if echo "$DISPATCH_BLOCK" | grep -q "$ref"; then
        fail "DFO02 [${ref}] Dispatch table carries no row resolving to this deleted reference"
    else
        pass "DFO02 [${ref}] Dispatch table carries no row resolving to this deleted reference"
    fi
done

# DFO-03: the Dispatch table carries exactly the 5 surviving states, no more, no fewer.
for state in FIRST-RUN Q-AND-A CONTINUE DESCRIBE-SEED COMPLETION; do
    assert_output_contains "$DISPATCH_BLOCK" "| ${state} |" "DFO03 [${state}] Dispatch table carries this state's row"
done
if echo "$DISPATCH_BLOCK" | grep -qE '\| *TRIAGE *\||CONDENSED-INTAKE|TASK-BREAKDOWN|LITE-REVIEW|LITE-DONE'; then
    fail "DFO03b Dispatch table carries no TRIAGE/lite-path row"
else
    pass "DFO03b Dispatch table carries no TRIAGE/lite-path row"
fi

# DFO-04: FIRST-RUN and Q-AND-A both advance to CONTINUE (scripted read of each reference
# doc's own **Advance:** line).
FIRST_RUN_ADVANCE=$(grep -m1 '\*\*Advance:\*\*' "$FIRST_RUN_MD")
assert_output_contains "$FIRST_RUN_ADVANCE" "[State: CONTINUE]" \
    "DFO04a state-first-run.md **Advance:** targets [State: CONTINUE]"
QANDA_ADVANCE=$(grep -m1 '\*\*Advance:\*\*' "$QANDA_MD")
assert_output_contains "$QANDA_ADVANCE" "[State: CONTINUE]" \
    "DFO04b state-q-and-a.md **Advance:** targets [State: CONTINUE]"

# DFO-05: no residual "you are here" map anywhere under aid-describe/ carries a TRIAGE node
# or a "(lite path)" map line.
if grep -rEq '\[.\] *TRIAGE *\]|\(lite path\)' "$DESCRIBE_DIR" --include='*.md'; then
    fail "DFO05 no residual you-are-here map carries a TRIAGE node or a (lite path) line"
else
    pass "DFO05 no residual you-are-here map carries a TRIAGE node or a (lite path) line"
fi

# DFO-06: no ## Scripts section (parse-recipe.sh / test-parse-recipe.sh retired by feature-002).
if grep -q '^## Scripts$' "$SKILL_MD"; then
    fail "DFO06 SKILL.md carries no ## Scripts section (parse-recipe.sh rows retired)"
else
    pass "DFO06 SKILL.md carries no ## Scripts section (parse-recipe.sh rows retired)"
fi

# ===========================================================================
# Part 2 -- Engine-preserved assertion (C-3)
# ===========================================================================
echo ""
echo "--- Part 2: engine-preserved assertion (C-3) ---"

# DFO-10: all 13 surviving reference files exist (6 untouched + 7 rewired).
UNTOUCHED=(advisor-stance.md coherence-check.md interview-loop.md interview-strategies.md \
           kb-hydration.md state-completion.md)
REWIRED=(state-first-run.md state-q-and-a.md state-continue.md state-describe-seed.md \
         elicitation-engine.md move-playbook.md calibration.md)
for f in "${UNTOUCHED[@]}" "${REWIRED[@]}"; do
    assert_file_exists "${REFS_DIR}/${f}" "DFO10 [${f}] surviving reference file exists"
done

ACTUAL_REF_COUNT=$(find "$REFS_DIR" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
assert_eq "$ACTUAL_REF_COUNT" "13" "DFO11 aid-describe/references/ carries exactly 13 files (6 untouched + 7 rewired)"

# DFO-12: the D1 opener text is byte-identical between elicitation-engine.md (canonical
# source) and state-continue.md (the relocated invocation site).
read -r -d '' OPENER_TEXT <<'OPENER_EOF' || true
In a sentence or two -- what do you want to build or change, and what outcome
are you after?

Suggested: For example: "I want a small CLI tool that parses a config file and
           validates it against a schema, so that our team stops manually
           checking config files before each deploy."
Why: Describing the pieces in your own words gives me the working vocabulary
     for this project. I will use your terms, not impose mine -- so the more
     naturally you name the pieces, the more useful what follows will be.

[1] Use the form above and share yours
[2] Your answer: ___
OPENER_EOF

assert_file_contains "$ENGINE_MD" "$OPENER_TEXT" "DFO12a elicitation-engine.md carries the D1 opener text verbatim"
assert_file_contains "$CONTINUE_MD" "$OPENER_TEXT" "DFO12b state-continue.md carries the SAME D1 opener text verbatim (relocation, not rewrite)"

# extract_fenced_block_after <file> <anchor-substring> -- the fenced block (fences
# excluded) that follows the first line containing <anchor-substring>.
extract_fenced_block_after() {
    local file="$1" anchor="$2"
    awk -v anchor="$anchor" '
        index($0, anchor) { after = 1 }
        after && /^```$/ { fence++; if (fence == 1) { next } else { exit } }
        after && fence == 1 { print }
    ' "$file"
}

ENGINE_OPENER_BLOCK=$(extract_fenced_block_after "$ENGINE_MD" "### Opener text")
CONTINUE_OPENER_BLOCK=$(extract_fenced_block_after "$CONTINUE_MD" "emit the D1 fixed opener")
if [[ "$ENGINE_OPENER_BLOCK" == "$CONTINUE_OPENER_BLOCK" ]]; then
    pass "DFO12c the fenced opener blocks in both files are byte-identical"
else
    fail "DFO12c the fenced opener blocks in both files are byte-identical -- they differ"
fi

# DFO-13: the five-step selector's step headings, present + unchanged + in order.
STEP_HEADINGS=(
    "## Step 1 -- STOP CHECK"
    "## Step 2 -- GAP SELECTION"
    "## Step 3 -- MOVE SELECTION"
    "## Step 4 -- CALIBRATION SHAPING"
    "## Step 5 -- ENVELOPE + EMIT"
)
PREV_LINE=0
ORDER_OK=1
for heading in "${STEP_HEADINGS[@]}"; do
    LINE=$(grep -nF -- "$heading" "$ENGINE_MD" | head -1 | cut -d: -f1)
    if [[ -z "$LINE" ]]; then
        fail "DFO13 [${heading}] five-step selector heading present in elicitation-engine.md"
        ORDER_OK=0
        continue
    fi
    pass "DFO13 [${heading}] five-step selector heading present in elicitation-engine.md"
    if [[ "$LINE" -le "$PREV_LINE" ]]; then
        ORDER_OK=0
    fi
    PREV_LINE="$LINE"
done
if [[ "$ORDER_OK" -eq 1 ]]; then
    pass "DFO14 the five step headings appear in strict ascending order (unchanged sequence)"
else
    fail "DFO14 the five step headings appear in strict ascending order -- order violated"
fi

# DFO-15: the "ONLY fixed turn" invariant text is unchanged (D1 opener discipline).
assert_output_contains "$(cat "$ENGINE_MD")" \
    "The D1 opener is the single fixed turn in the entire interview. No other turn is" \
    "DFO15 the D1-opener-is-the-only-fixed-turn invariant sentence is present, unchanged"

# ===========================================================================
# Part 3 -- Fixture-shape: opener fire-once condition (D1 opener at CONTINUE)
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape -- opener fire-once at CONTINUE ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_interview_state_fixture <path> <mode: all-pending|one-partial>
# Mirrors work-state-template.md's ## Interview State section shape.
build_interview_state_fixture() {
    local path="$1" mode="$2"
    local s1_state="Pending" s2_state="Pending"
    if [[ "$mode" == "one-partial" ]]; then
        s1_state="Partial"
    fi
    cat > "$path" <<EOF
# Work State -- work-999-fixture

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Interview
- **Active Skill:** aid-describe
- **Updated:** 2026-07-08T12:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Interview State

**State:** In Progress  **Grade:** Pending

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | ${s1_state} | -- |
| 2 | Problem Statement | ${s2_state} | -- |
EOF
}

# detect_opener_fires <interview-state-fixture> -- mechanical transcription of
# state-continue.md's own documented rule: "If all REQUIREMENTS.md sections are Pending,
# emit the D1 fixed opener ... Otherwise ... do NOT re-emit."
detect_opener_fires() {
    local fixture="$1"
    local non_pending
    # Row shape: | # | Section | State | Last Updated | -- split("|") yields an empty
    # leading field, so column 4 (not 3) is the State cell.
    non_pending=$(awk '
        /^\| [0-9]+ \|/ {
            n = split($0, f, "|")
            state = f[4]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
            if (state != "Pending") print state
        }
    ' "$fixture" | grep -c . || true)
    if [[ "$non_pending" -eq 0 ]]; then
        echo "FIRES"
    else
        echo "SKIPPED"
    fi
}

ALL_PENDING="${TMP}/state-all-pending.md"
ONE_PARTIAL="${TMP}/state-one-partial.md"
build_interview_state_fixture "$ALL_PENDING" "all-pending"
build_interview_state_fixture "$ONE_PARTIAL" "one-partial"

assert_eq "$(detect_opener_fires "$ALL_PENDING")" "FIRES" \
    "DFO20 fixture 'all sections Pending' -> D1 opener FIRES at CONTINUE entry (per state-continue.md rule)"
assert_eq "$(detect_opener_fires "$ONE_PARTIAL")" "SKIPPED" \
    "DFO21 fixture 'one section Partial' -> D1 opener SKIPPED (fire-once already consumed)"

# Cross-check the rule itself is what state-continue.md documents (not reimplemented drift).
assert_file_contains "$CONTINUE_MD" "If all REQUIREMENTS.md sections are Pending, emit the D1 fixed opener" \
    "DFO22 state-continue.md documents the exact fire-once condition the fixture detector transcribes"
assert_file_contains "$CONTINUE_MD" "Do NOT re-emit the D1 opener" \
    "DFO23 state-continue.md documents the no-re-emit rule for the Partial/Complete case"

echo ""
test_summary
