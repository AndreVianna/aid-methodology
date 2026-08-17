# task-018: BLUEPRINT.md on the 7-column ledger and grade.sh path

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-010

**Scope:**
- Give `BLUEPRINT.md` a declared ledger scope and a `grade.sh` invocation on the full path, per FR-B4 as narrowed by the owner's answer to Q6 — the specify half is already satisfied and is not touched.
- Correct the schema claim that `aid-specify` refines the blueprint, which no skill file currently does.
- Recommended home: `aid-specify`, which is already on the ledger and `grade.sh` path, so the wiring closes the documentation conflict at the same time.

**Acceptance Criteria:**
- [ ] `grep -rn 'review-pending/blueprint' canonical tests scripts | wc -l` returns at least `1`, measured at `0` before — the corpus deliberately excludes `.aid/works/` so the check cannot match this task's own prose.
- [ ] The chosen home runs `grade.sh --explain` against that ledger scope.
- [ ] `grep -rn BLUEPRINT canonical/skills/aid-specify/` no longer returns `0`, so the schema's claim and the skills agree.
- [ ] The Lite path's existing blueprint review is unchanged, verified by diff.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
