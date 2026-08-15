# task-014: Close-out render and dogfood resync

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml.

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

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-013

**Scope:**
- Run the FULL generator: `python .claude/skills/generate-profile/scripts/run_generator.py`. Never a per-script renderer -- a partial render leaves stale emission manifests and fails the render-drift gate (`tech-debt.md § Gotchas`).
- Resync the two tracked dogfood trees from the rendered profiles.
- This is the work's ONE render (NFR-5), covering every `canonical/` edit from tasks 003, 006, 008, 009, 010 and 011.

**Acceptance Criteria:**
- [ ] AC-12: the render-drift gate and the dogfood byte-identity gate are both green
- [ ] The full generator was used, not a per-script renderer
- [ ] Exactly one render is performed for the whole work; mid-work staleness before this task is expected and not a defect
- [ ] No hand-edit is made to any file under `profiles/` -- it is generated output
- [ ] All REQUIREMENTS.md §6 quality gates pass
