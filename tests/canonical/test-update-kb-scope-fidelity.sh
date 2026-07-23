#!/usr/bin/env bash
# test-update-kb-scope-fidelity.sh -- structural/consistency guard suite for
# work-020-update-kb-intent-alignment's aid-update-kb Scope-Fidelity redesign.
#
# Pure grep/structure assertions over canonical/skills/aid-update-kb/ -- no
# behavioral runs, no port-binding, no server startup. Confirms the redesign's
# governing hard limits (HL-1..HL-8) and acceptance criteria (AC-1..AC-10,
# REQUIREMENTS.md §9) are actually ENCODED in the shipped markdown, not just
# described in SPEC.md. Canonical byte-identity/parity with profiles/* and the
# dogfood .claude/ copy is deferred to CI (test-dogfood-byte-identity /
# render-drift), per work-020 task-004's local-test-safety constraint.
#
# Traces (grouped by governing AC/HL, per work-020 task-004 DETAIL.md):
#   UK01-UK09   AC-10/FR-11 -- Pre-flight ISOLATE: own worktree off master via
#               plain `git worktree add -b`, entered per the generic
#               worktree-lifecycle.md contract, fail-closed, NOT the
#               work-NNN-keyed worktree-lifecycle.sh (verified both by prose
#               negation AND mechanically -- no bash block invokes the script)
#   UK10-UK17   DONE branch invariant -- state-done.md commits on the
#               Pre-flight worktree's branch (no `git checkout -b` / "Ensure
#               branch" step, mechanically verified over its own bash blocks),
#               never pushes `master`; SKILL.md's commit-convention note agrees
#   UK18-UK25   AC-9/HL-8 -- ANALYZE/SCOPE wired as clean-context dispatches
#               (verbatim instruction only, never the session transcript); the
#               orchestrator must not enrich either prompt
#   UK26-UK30   AC-1/HL-1 -- no path from SCOPE/CONFIRM to APPLY without a
#               frozen `Confirmed: yes`; only CONFIRM's [1] (plus the
#               already-confirmed REVIEW/DONE re-entries) ever writes
#               `**State:** APPLY` -- never ANALYZE/SCOPE directly
#   UK31-UK36   AC-2/HL-2/HL-5 -- no tag-overlap candidate net in ANALYZE;
#               SCOPE requires a non-empty Traces-to per item + emits
#               Not-Changing
#   UK37-UK40   AC-3/HL-4 -- contradictions surfaced as CONFIRM questions,
#               never silently "corrected"
#   UK41-UK48   AC-4 -- REVIEW's scope-diff guard is disk-derived (`git status
#               --porcelain` / `git diff --name-only` against the pre-APPLY
#               baseline), hard fail, never trusts APPLY's self-report; the
#               hunk-level [TRACE-1] traceability mandate is present
#   UK49-UK55   AC-5/HL-7 -- FIX loop + DONE closure bounded to Confirmed
#               Scope with user-escalation (never auto-expand); the post-APPLY
#               re-scope revert (`git restore`) is documented at both ends
#   UK56-UK58   AC-6/HL-6 -- new-file creation gated on a `new-file` Kind
#               confirmed at CONFIRM, never a silent side effect
#   UK59-UK60   AC-8/HL-3 -- LIKELY/UNCERTAIN inference is never promoted to
#               Scope Plan on SCOPE's own authority; routed to CONFIRM instead
#   UK61-UK77   Structural 7-state consistency -- exactly 7 reference docs
#               (incl. the 2 NEW ones), the Dispatch table's per-state row
#               cites the matching reference doc, the Resume-detection table
#               covers all 7 states, and the ASCII diagram lists all 7 in order
#   UK78-UK80   "four-mandate" consistent; no "five-mandate" residue anywhere
#               under canonical/skills/aid-update-kb
#   UK81-UK87   Source-doc sweep -- no residual "Change Plan" string in any of
#               the 7 reference docs (SKILL.md's own historical/negation
#               mentions of the old name are expected and out of scope here)
#   UK88-UK91   Settings-floor -- `.aid/settings.yml` has no per-skill
#               `update-kb`/`update_kb` override; the floor still resolves
#               (via read-setting.sh) to the project's global `minimum_grade`
#
# Usage:
#   bash tests/canonical/test-update-kb-scope-fidelity.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-update-kb-scope-fidelity.sh =="

CANONICAL="${REPO_ROOT}/canonical"
SKILL_DIR="${CANONICAL}/skills/aid-update-kb"
SKILL_MD="${SKILL_DIR}/SKILL.md"
REFS="${SKILL_DIR}/references"

ANALYZE_MD="${REFS}/state-analyze.md"
SCOPE_MD="${REFS}/state-scope.md"
CONFIRM_MD="${REFS}/state-confirm.md"
APPLY_MD="${REFS}/state-apply.md"
REVIEW_MD="${REFS}/state-review.md"
APPROVAL_MD="${REFS}/state-approval.md"
DONE_MD="${REFS}/state-done.md"

SETTINGS_YML="${REPO_ROOT}/.aid/settings.yml"
READ_SETTING="${CANONICAL}/aid/scripts/config/read-setting.sh"

for f in "$SKILL_MD" "$ANALYZE_MD" "$SCOPE_MD" "$CONFIRM_MD" "$APPLY_MD" "$REVIEW_MD" "$APPROVAL_MD" "$DONE_MD"; do
  if [[ ! -f "$f" ]]; then
    echo "FATAL: expected canonical file not found: $f" >&2
    exit 2
  fi
done

# Extracts the content of every ```bash ... ``` fenced block from a markdown
# file (column-0 fences only -- the skill's indented/blockquoted fences are
# never "```bash"-tagged, so this cleanly isolates real, executable shell from
# prose that merely *mentions* a command in backticks).
extract_bash_blocks() {
    awk '/^```bash/{f=1;next} /^```$/{f=0} f' "$1"
}

# =============================================================================
# UK01-UK09 -- AC-10/FR-11: Pre-flight ISOLATE (own worktree off master)
# =============================================================================

assert_file_contains "$SKILL_MD" 'git worktree add "$UPDATEKB_WT" -b "$BRANCH" master' \
  "UK01 SKILL.md Pre-flight creates the worktree via plain 'git worktree add -b ... master'"

assert_file_contains "$SKILL_MD" 'BRANCH="aid/update-kb-${TS}"' \
  "UK02 SKILL.md Pre-flight branch follows the aid/update-kb-<ts> convention"

assert_file_contains "$SKILL_MD" 'Fail-closed (FR-11 / AC-10)' \
  "UK03 SKILL.md Pre-flight documents the fail-closed invariant"

assert_file_contains "$SKILL_MD" 'fail-closed -- never run in the caller' \
  "UK04 SKILL.md Pre-flight worktree-creation failure never falls back to the caller's tree"

assert_file_contains "$SKILL_MD" '**not** use `canonical/aid/scripts/works/worktree-lifecycle.sh`' \
  "UK05 SKILL.md Pre-flight explicitly does NOT use the work-NNN-keyed worktree-lifecycle.sh"

SKILL_BASH="$(extract_bash_blocks "$SKILL_MD")"
assert_output_not_contains "$SKILL_BASH" 'worktree-lifecycle.sh' \
  "UK06 SKILL.md's executable bash blocks never invoke worktree-lifecycle.sh (mechanical, not just prose)"

assert_file_contains "$SKILL_MD" 'worktree-lifecycle.md § Step 2' \
  "UK07 SKILL.md Pre-flight enters the worktree via the generic worktree-lifecycle.md § Step 2 contract"

assert_file_contains "$SKILL_MD" 'EnterWorktree' \
  "UK08 SKILL.md Pre-flight uses the EnterWorktree tool for claude-code entry"

assert_file_contains "$SKILL_MD" 'Pre-flight ISOLATE runs first, every invocation' \
  "UK09 SKILL.md banner states Pre-flight ISOLATE runs before any state, every invocation"

# =============================================================================
# UK10-UK17 -- DONE branch invariant (no new branch at DONE; never push master)
# =============================================================================

assert_file_contains "$DONE_MD" 'Confirm the working branch (no new branch created)' \
  "UK10 state-done.md Step 2 title is 'no new branch created' (not the old 'Ensure branch')"

assert_file_contains "$DONE_MD" 'DONE creates no separate branch of' \
  "UK11 state-done.md states DONE creates no separate branch of its own"

DONE_BASH="$(extract_bash_blocks "$DONE_MD")"
assert_output_not_contains "$DONE_BASH" 'checkout -b' \
  "UK12 state-done.md's executable bash blocks never run 'git checkout -b' (mechanical, not just prose)"

assert_output_not_contains "$DONE_BASH" 'git push' \
  "UK13 state-done.md's executable bash blocks never run 'git push' (commit-only, never publish)"

assert_file_not_contains "$DONE_MD" 'push origin master' \
  "UK14 state-done.md never pushes to origin master (literal string absent)"

assert_file_contains "$DONE_MD" 'NEVER pushes -- to this branch or to `master`' \
  "UK15 state-done.md explicitly states the skill NEVER pushes to master"

assert_file_contains "$SKILL_MD" 'creates **no** separate branch' \
  "UK16 SKILL.md's DONE (commit convention) note agrees: no separate branch is created at DONE"

assert_file_contains "$SKILL_MD" 'never pushes -- and never to `master`' \
  "UK17 SKILL.md's DONE (commit convention) note agrees: the skill never pushes to master"

# =============================================================================
# UK18-UK25 -- AC-9/HL-8: clean-context dispatch (ANALYZE/SCOPE)
# =============================================================================

assert_file_contains "$SKILL_MD" 'aid-researcher` (clean-context dispatch, HL-8/AC-9)' \
  "UK18 SKILL.md Dispatch table marks ANALYZE's aid-researcher as clean-context dispatch"

assert_file_contains "$SKILL_MD" 'aid-architect` (clean-context dispatch, HL-8/AC-9)' \
  "UK19 SKILL.md Dispatch table marks SCOPE's aid-architect as clean-context dispatch"

assert_file_contains "$ANALYZE_MD" 'Clean-context dispatch (HL-8/AC-9).' \
  "UK20 state-analyze.md declares itself a clean-context dispatch"

assert_file_contains "$SCOPE_MD" 'Clean-context dispatch (HL-8/AC-9).' \
  "UK21 state-scope.md declares itself a clean-context dispatch"

assert_file_contains "$ANALYZE_MD" 'session transcript' \
  "UK22 state-analyze.md states the sub-agent never receives the session transcript"

assert_file_contains "$SCOPE_MD" 'session transcript' \
  "UK23 state-scope.md states the sub-agent never receives the session transcript"

assert_file_contains "$SCOPE_MD" 'never "the session" or prior discussion' \
  "UK24 state-scope.md's Traces-to guidance forbids citing 'the session' as a source"

assert_file_contains "$SKILL_MD" 'The orchestrator MUST NOT enrich either dispatch prompt with' \
  "UK25 SKILL.md forbids the orchestrator from enriching ANALYZE/SCOPE dispatches with session context"

# =============================================================================
# UK26-UK30 -- AC-1/HL-1: no APPLY without a frozen Confirmed: yes
# =============================================================================

assert_file_contains "$CONFIRM_MD" '**Confirmed:** yes' \
  "UK26 state-confirm.md's [1] Confirm writes **Confirmed:** yes"

assert_file_contains "$CONFIRM_MD" '**State:** APPLY' \
  "UK27 state-confirm.md's [1] Confirm is the state transition that unlocks APPLY"

assert_file_contains "$SKILL_MD" 'APPLY is unreachable without `**Confirmed:** yes` in run-state.' \
  "UK28 SKILL.md's HL-1 states APPLY is unreachable without Confirmed: yes"

assert_file_not_contains "$ANALYZE_MD" '**State:** APPLY' \
  "UK29 state-analyze.md never writes **State:** APPLY directly (no CONFIRM bypass)"

assert_file_not_contains "$SCOPE_MD" '**State:** APPLY' \
  "UK30 state-scope.md never writes **State:** APPLY directly (no CONFIRM bypass)"

# =============================================================================
# UK31-UK36 -- AC-2/HL-2/HL-5: no tag-overlap net; Traces-to; Not-Changing
# =============================================================================

assert_file_contains "$ANALYZE_MD" 'no tag-overlap candidate net -- HL-5' \
  "UK31 state-analyze.md explicitly states there is no tag-overlap candidate net"

OLD_TAG_NET=$(grep -rF 'Every doc whose Objective or Tags overlaps' "$SKILL_DIR" 2>/dev/null || true)
assert_eq "$OLD_TAG_NET" "" \
  "UK32 the old tag-overlap-candidate sentence is gone from canonical/skills/aid-update-kb"

assert_file_contains "$SCOPE_MD" '| # | Doc | Change-type | Description | Traces-to | Kind |' \
  "UK33 state-scope.md's Scope Plan table header includes Traces-to and Kind columns"

assert_file_contains "$SCOPE_MD" 'Every row MUST have a non-empty `Traces-to`.' \
  "UK34 state-scope.md mandates a non-empty Traces-to per Scope Plan row"

assert_file_contains "$SCOPE_MD" '**Not-Changing:**' \
  "UK35 state-scope.md emits an explicit Not-Changing list"

assert_file_contains "$SCOPE_MD" 'or `suspect` per the freshness advisory, but not itself named or implied' \
  "UK36 state-scope.md excludes domain-adjacent/suspect-but-uninstructed docs to Not-Changing (HL-5)"

# =============================================================================
# UK37-UK40 -- AC-3/HL-4: contradictions surfaced as questions, never resolved
# =============================================================================

assert_file_contains "$ANALYZE_MD" 'surfaced for CONFIRM to ask, never' \
  "UK37 state-analyze.md routes contradictions to CONFIRM, never resolves them itself"

assert_file_contains "$CONFIRM_MD" 'Open questions:' \
  "UK38 state-confirm.md presents Open questions to the user"

assert_file_contains "$SKILL_MD" 'never silently "corrects" either side' \
  "UK39 SKILL.md's HL-4 states the skill never silently corrects either side"

assert_file_contains "$CONFIRM_MD" 'CONFIRM does not advance past unanswered' \
  "UK40 state-confirm.md does not advance past unanswered contradictions/open questions"

# =============================================================================
# UK41-UK48 -- AC-4: disk-derived scope-diff guard, hard fail, hunk traceability
# =============================================================================

assert_file_contains "$REVIEW_MD" 'git status --porcelain -- .aid/knowledge/' \
  "UK41 state-review.md derives the edited-doc set via git status --porcelain (disk-derived)"

assert_file_contains "$REVIEW_MD" 'git diff --name-only "$BASELINE" -- .aid/knowledge/' \
  "UK42 state-review.md derives the edited-doc set via git diff --name-only against the baseline"

assert_file_contains "$REVIEW_MD" 'It never trusts APPLY' \
  "UK43 state-review.md states the scope-diff guard never trusts APPLY's self-report"

assert_file_contains "$REVIEW_MD" '**HARD FAIL**' \
  "UK44 state-review.md's scope-diff guard is a HARD FAIL on an out-of-scope disk edit"

assert_file_contains "$REVIEW_MD" 'Traceability mandate (hunk-level, AC-4)' \
  "UK45 state-review.md defines the hunk-level traceability mandate"

assert_file_contains "$REVIEW_MD" 'hunk by hunk' \
  "UK46 state-review.md's traceability mandate diffs each doc hunk by hunk"

assert_file_contains "$REVIEW_MD" '[TRACE-1] Untraceable hunk' \
  "UK47 state-review.md flags an untraceable hunk as [TRACE-1]"

assert_file_contains "$SKILL_MD" 'Step 0a scope-diff guard (`git status --porcelain` / `git diff` against the' \
  "UK48 SKILL.md's REVIEW-reuse note agrees the guard is disk-derived, never APPLY's self-report"

# =============================================================================
# UK49-UK55 -- AC-5/HL-7: FIX/DONE bounded to Confirmed Scope; re-scope revert
# =============================================================================

assert_file_contains "$REVIEW_MD" 'FIX-loop constraint (HL-7)' \
  "UK49 state-review.md's FIX loop carries an explicit HL-7 scope-bound constraint"

assert_file_contains "$REVIEW_MD" 'user escalation, never auto-decided (HL-7)' \
  "UK50 state-review.md escalates an out-of-scope disk edit to the user, never auto-decides"

assert_file_contains "$DONE_MD" 'Needs an out-of-scope addition (HL-7)' \
  "UK51 state-done.md's closure re-check names the out-of-scope-addition escalation branch (HL-7)"

assert_file_contains "$DONE_MD" 'Do **NOT** auto-push this to APPLY' \
  "UK52 state-done.md never auto-pushes an out-of-scope closure need to APPLY"

assert_file_contains "$APPLY_MD" 'git restore -- "<doc>"' \
  "UK53 state-apply.md's re-scope revert step uses git restore against the pre-APPLY baseline"

assert_file_contains "$APPROVAL_MD" 'Re-scope revert (HL-7/AC-5)' \
  "UK54 state-approval.md documents the re-scope revert mechanism"

assert_file_contains "$APPROVAL_MD" 'state-apply.md § Step 0' \
  "UK55 state-approval.md points to state-apply.md's Step 0 as the revert's enforcement point"

# =============================================================================
# UK56-UK58 -- AC-6/HL-6: new-file gated on 'new-file' kind confirmed at CONFIRM
# =============================================================================

assert_file_contains "$SCOPE_MD" 'new-file' \
  "UK56 state-scope.md's Kind enum includes new-file"

assert_file_contains "$CONFIRM_MD" 'in-scope/closure/new-file' \
  "UK57 state-confirm.md's Confirmed Scope bullet convention carries the new-file kind"

assert_file_contains "$SKILL_MD" 'HL-6 New files require explicit confirmation' \
  "UK58 SKILL.md's HL-6 requires explicit confirmation for new files"

# =============================================================================
# UK59-UK60 -- AC-8/HL-3: LIKELY/UNCERTAIN routed to CONFIRM, never applied
# =============================================================================

assert_file_contains "$ANALYZE_MD" 'HL-3 -- forbid silent inference' \
  "UK59 state-analyze.md's HL-3 forbids silent inference of LIKELY/UNCERTAIN rows"

assert_file_contains "$SCOPE_MD" '-confidence Impact Finding is NEVER promoted to a' \
  "UK60 state-scope.md never promotes a LIKELY/UNCERTAIN finding to Scope Plan on its own authority"

# =============================================================================
# UK61-UK77 -- Structural 7-state consistency
# =============================================================================

REF_COUNT=$(find "$REFS" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
assert_eq "$REF_COUNT" "7" \
  "UK61 exactly 7 reference docs exist under canonical/skills/aid-update-kb/references/"

assert_file_exists "$SCOPE_MD" "UK62a the new state-scope.md reference file exists"
assert_file_exists "$CONFIRM_MD" "UK62b the new state-confirm.md reference file exists"

STATES=(ANALYZE SCOPE CONFIRM APPLY REVIEW APPROVAL DONE)
REFDOCS=(state-analyze state-scope state-confirm state-apply state-review state-approval state-done)
for i in "${!STATES[@]}"; do
  st="${STATES[$i]}"
  doc="${REFDOCS[$i]}"
  pattern="| ${st} | \`references/${doc}.md\`"
  assert_file_contains "$SKILL_MD" "$pattern" \
    "UK6$((3+i)) SKILL.md Dispatch table's ${st} row cites references/${doc}.md"
done

assert_file_contains "$SKILL_MD" '[ ANALYZE ] -> [ SCOPE ] -> [ CONFIRM ] -> [ APPLY ] -> [ REVIEW ] -> [ APPROVAL ] -> [ DONE ]' \
  "UK70 SKILL.md's ASCII diagram lists all 7 states in the correct order"

assert_file_contains "$SKILL_MD" '`**State:** ANALYZE` present | ANALYZE |' \
  "UK71 SKILL.md Resume-detection table covers ANALYZE"
assert_file_contains "$SKILL_MD" '`**State:** SCOPE` present | SCOPE |' \
  "UK72 SKILL.md Resume-detection table covers SCOPE"
assert_file_contains "$SKILL_MD" '`**State:** CONFIRM` present | CONFIRM |' \
  "UK73 SKILL.md Resume-detection table covers CONFIRM"
assert_file_contains "$SKILL_MD" '`**State:** APPLY` present | APPLY |' \
  "UK74 SKILL.md Resume-detection table covers APPLY"
assert_file_contains "$SKILL_MD" '`**State:** REVIEW` or `**State:** FIX` present | REVIEW |' \
  "UK75 SKILL.md Resume-detection table covers REVIEW (incl. FIX)"
assert_file_contains "$SKILL_MD" '`**State:** APPROVAL` present | APPROVAL |' \
  "UK76 SKILL.md Resume-detection table covers APPROVAL"
assert_file_contains "$SKILL_MD" '`**State:** DONE` present | report "nothing to resume" -- HALT |' \
  "UK77 SKILL.md Resume-detection table covers DONE"

# =============================================================================
# UK78-UK80 -- "four-mandate" consistent; no "five-mandate" residue
# =============================================================================

assert_file_contains "$SKILL_MD" 'four-mandate' \
  "UK78 SKILL.md refers to the f005 panel as four-mandate"

assert_file_contains "$REVIEW_MD" 'four-mandate' \
  "UK79 state-review.md refers to the f005 panel as four-mandate"

FIVE_MANDATE=$(grep -ril 'five-mandate' "$SKILL_DIR" 2>/dev/null || true)
assert_eq "$FIVE_MANDATE" "" \
  "UK80 no 'five-mandate' residue anywhere under canonical/skills/aid-update-kb"

# =============================================================================
# UK81-UK87 -- Source-doc sweep: no residual "Change Plan" in any reference doc
# =============================================================================

for doc in state-analyze state-scope state-confirm state-apply state-review state-approval state-done; do
  assert_file_not_contains "${REFS}/${doc}.md" 'Change Plan' \
    "UK-CP no residual 'Change Plan' reference in ${doc}.md (renamed to Scope Plan)"
done

# =============================================================================
# UK88-UK91 -- Settings-floor: no per-skill update-kb override; floor unchanged
# =============================================================================

if [[ ! -f "$SETTINGS_YML" ]]; then
  echo "FATAL: .aid/settings.yml not found at $SETTINGS_YML" >&2
  exit 2
fi

assert_file_not_contains "$SETTINGS_YML" 'update-kb:' \
  "UK88 .aid/settings.yml has no per-skill update-kb: override section"

assert_file_not_contains "$SETTINGS_YML" 'update_kb:' \
  "UK89 .aid/settings.yml has no per-skill update_kb: override section (underscore variant)"

assert_file_contains "$SETTINGS_YML" 'minimum_grade: A+' \
  "UK90 .aid/settings.yml's global minimum_grade is unchanged (A+)"

if [[ ! -f "$READ_SETTING" ]]; then
  echo "FATAL: read-setting.sh not found at $READ_SETTING" >&2
  exit 2
fi

RESOLVED_FLOOR=$(bash "$READ_SETTING" --skill update-kb --key minimum_grade --default A --file "$SETTINGS_YML" 2>/dev/null)
assert_eq "$RESOLVED_FLOOR" "A+" \
  "UK91 aid-update-kb's floor resolves (via read-setting.sh) to the project's global minimum_grade (A+)"

# =============================================================================
# UK92-UK98 -- delivery-gate FIX cycle-2 (rows 7/8): APPROVAL row CHAIN-on-[1];
# re-plan Adjustments/Consideration channel wired to SCOPE/ANALYZE
# =============================================================================

assert_file_contains "$SKILL_MD" '`[1] Approved` -> CHAIN -> DONE' \
  "UK92 SKILL.md Dispatch table's APPROVAL row is CHAIN-on-[1] (matches state-approval.md's own Advance: CHAIN -> DONE)"

assert_file_not_contains "$SKILL_MD" 'PAUSE-FOR-USER-ACTION -> DONE on approval' \
  "UK93 regression guard: SKILL.md no longer mislabels APPROVAL's [1] as PAUSE-FOR-USER-ACTION"

assert_file_contains "$SCOPE_MD" 'the recorded `**Adjustments:**`/`**Consideration:**` field' \
  "UK94 state-scope.md's clean-context dispatch admits the recorded Adjustments/Consideration field on a re-plan loop-back"

assert_file_contains "$ANALYZE_MD" 'the recorded `**Adjustments:**` field' \
  "UK95 state-analyze.md's clean-context dispatch admits the recorded Adjustments field on a re-plan re-entry"

assert_file_contains "$SKILL_MD" 'authorized first-class scoping input' \
  "UK96 SKILL.md's HL-8 distinguishes the gate-recorded Adjustments/Consideration field as authorized scoping input"

assert_file_contains "$SKILL_MD" 'ambient session transcript' \
  "UK97 SKILL.md's HL-8 still names the ambient session transcript (not the gate-recorded field) as the forbidden source"

assert_file_contains "$REVIEW_MD" 'actually reads it' \
  "UK98 state-review.md's 4(b) accept branch confirms SCOPE's dispatch actually reads the Adjustments field it routes through CONFIRM to produce"

# =============================================================================
# UK99-UK109 -- delivery-gate FIX cycle-3 (row 9, owner-ruled): AC-9/HL-8
# own-dialogue-vs-prior-context distinction, asserted directly against the
# SHIPPED canonical/skills/aid-update-kb/ files (SKILL.md, state-scope.md) --
# NOT work-020's transient SPEC.md/REQUIREMENTS.md (those docs are pruned
# once shipped; a canonical test may never depend on a work-lifecycle folder).
# UK99/UK100/UK102/UK108 (originally the SHARED_PHRASE/clean-line asserted
# against SPEC.md) are collapsed here: grepping every shipped
# canonical/skills/aid-update-kb/ file confirms both phrases live ONLY in
# SKILL.md, so re-pointing them would duplicate UK103/UK109 verbatim --
# those two checks alone now carry that coverage.
# =============================================================================

SHARED_PHRASE='previous or unrelated conversation or instruction'

assert_file_contains "$SKILL_MD" 'HL-8 The instruction plus this run'"'"'s own confirmation dialogue' \
  "UK101 SKILL.md's HL-8 heading itself states the in-scope/banned distinction"

assert_file_contains "$SKILL_MD" "$SHARED_PHRASE" \
  "UK103 SKILL.md's HL-8 states the owner-ruled banned source: previous/unrelated conversation or instruction (row 9's cross-doc contradiction is closed in the shipped skill)"

OLD_AC9_PHRASE='Content present in the session conversation but absent from the instruction'
assert_file_not_contains "$SKILL_MD" "$OLD_AC9_PHRASE" \
  "UK104 regression guard: SKILL.md's HL-8 no longer uses the pre-fix wording that omitted the own-dialogue carve-out"

assert_file_not_contains "$SCOPE_MD" "$OLD_AC9_PHRASE" \
  "UK105 regression guard: state-scope.md no longer uses the pre-fix wording that omitted the own-dialogue carve-out either"

assert_file_contains "$SCOPE_MD" 'authorized, first-class scoping input' \
  "UK106 state-scope.md names the recorded Adjustments/Consideration field 'authorized, first-class scoping input', matching SKILL.md's own phrase (UK96) -- cross-file consistency holds within the shipped skill"

assert_file_contains "$SKILL_MD" 'that ban is unweakened' \
  "UK107 SKILL.md's HL-8 states the prior/unrelated-conversation ban stays unweakened by the own-dialogue carve-out"

assert_file_contains "$SKILL_MD" "skill-run's own instruction + confirmation dialogue = in-scope; anything from outside it = banned" \
  "UK109 SKILL.md's HL-8 states the owner's exact clean line (in-scope vs banned)"

# =============================================================================
# UK110-UK113 -- delivery-gate FIX cycle-3 (row 10): Run-state schema table
# gains the two real, previously-undocumented fields
# =============================================================================

assert_file_contains "$SKILL_MD" '`**Consideration:**` | APPROVAL' \
  "UK110 SKILL.md's Run-state schema table now has a **Consideration:** row"

assert_file_contains "$SKILL_MD" '`**Consideration:**` | APPROVAL (`[2]`, Step 3)' \
  "UK111 SKILL.md's **Consideration:** schema row correctly names APPROVAL's [2] (Step 3) as the writer"

assert_file_contains "$SKILL_MD" '`**Scope-diff:**` | REVIEW' \
  "UK112 SKILL.md's Run-state schema table now has a **Scope-diff:** row"

assert_file_contains "$SKILL_MD" 'read back by APPROVAL Step 1 for its summary banner' \
  "UK113 SKILL.md's **Scope-diff:** schema row documents that APPROVAL Step 1 reads it back for its summary banner"

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
