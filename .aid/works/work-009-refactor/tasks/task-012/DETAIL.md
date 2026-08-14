# task-012: Exclude state files from the reviewable-artifact surface

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-012/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-001

**Scope:**
- Three canonical edits, one rule, one filter, one home (`SPEC.md § L-8`), modeled on the KB
  precedent where `list_reviewable` lives as a shell function inside the reference doc
  `canonical/skills/aid-discover/references/doc-set-resolve.md`:
  1. `canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` -- in the single
     upstream doc every brief derives from -- gains the rule and the filter: a state file is NEVER
     listed in `{{ARTIFACTS}}`; state churn appearing in a reviewed diff is not a finding and is
     not an OOS row either (it is not an observation about an artifact). That doc's
     `## Brief generation` (`:200`) already mandates deriving the list from a deterministic source
     (`git diff --name-only <base>..HEAD`), so the filter is
     defined once here and applied at that derivation point, as a shell function extractable by a
     test, covering every state-file path shape: all three levels, both layouts, `.md` legacy and
     `.yml`.
  2. `canonical/skills/aid-execute/references/reviewer-brief.md` -- line 66 stops naming "every
     task's `STATE.md` row" in the per-delivery `{{ARTIFACTS}}`, and the per-task `DELIVERABLES`
     output location (line 54) is restated so it no longer implies the state file is reviewed
     content. While editing line 54, fix its target: it currently names `STATE.md ## Tasks State`,
     a DERIVED section -- which is wrong today independent of this refactor. The correct target is
     the `tasks_lifecycle` entry on the flat path, or the per-task state file on the full path.
  3. `canonical/aid/templates/shortcut-engine.md § GATE` -- each pass's `OUT OF SCOPE` bullet
     (`:720`, `:751`) states the state-file exclusion explicitly so it cannot regress. Both passes
     already exclude state files by listing only REQUIREMENTS/SPEC/PLAN/BLUEPRINT (Pass 1) and the
     `DETAIL.md` set (Pass 2); this makes the exclusion explicit rather than incidental.
- The reviewer still WRITES its outcome into state (A-3): every edit preserves that, and none
  touches the reviewer's state-write instructions.
- Not added, deliberately (FR-10d): no new ledger column, no new severity, no new grade mechanism,
  and no change to `canonical/aid/scripts/grade.sh` -- it grades a ledger and reads no state file.
- Note for the executor: `shortcut-engine.md` is also edited by task-014, in different sections
  (INTAKE Step 4's template `cp`, the `--pipeline` recipes and the lifecycle-history append
  instructions). task-014 depends on this task so the two edits serialize on one file.
- Canonical only (C-1); the renders are regenerated in task-017.
- OUT of this task: the test that asserts the exclusion (task-013), and `grade.sh`.

**Acceptance Criteria:**
- [ ] `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` states the exclusion rule AND carries the
      filter as a single extractable shell function, defined exactly once in the repository
      (SP-13, FR-10a).
- [ ] The filter drops every state-file path shape -- work-level, `deliveries/delivery-NNN/`, and
      `deliveries/delivery-NNN/tasks/task-NNN/`, in both layouts, both `STATE.md` and `STATE.yml` --
      and keeps every authored-artifact path (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`,
      `BLUEPRINT.md`, `tasks/task-NNN/DETAIL.md`) (SP-13).
- [ ] The rule states that state churn in a reviewed diff is neither a finding nor an OOS row
      (FR-10a).
- [ ] `reviewer-brief.md` no longer names a state row as reviewed content at line 66 or line 54,
      and line 54's output target names `tasks_lifecycle` (flat) or the per-task state file (full)
      instead of the DERIVED `## Tasks State` (SP-13, FR-10b).
- [ ] Both `shortcut-engine.md § GATE` passes' `OUT OF SCOPE` bullets name the state-file exclusion
      explicitly (FR-10c).
- [ ] Every edited surface still states that the reviewer writes its outcome into state (A-3).
- [ ] `canonical/aid/scripts/grade.sh` is byte-unchanged, and no ledger column, severity or gate is
      added anywhere (FR-10d, SP-13).
- [ ] The `.aid/knowledge/STATE.md` discovery ledger's own exclusion path (`list_reviewable` in
      `doc-set-resolve.md`) is unchanged -- this task adds the work-tree rule beside it, it does not
      re-home the KB one.
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` is edited by this task (C-1).
- [ ] All section-6 quality gates pass.
