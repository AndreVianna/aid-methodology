# task-016: Standalone kb.html content check

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

**Depends on:** task-009

**Scope:**
- A check that reads what `kb.html` says and compares its project claims — names, paths, counts, grades — against the Knowledge Base.
- Deliberately **outside** the criteria registry, per the owner's answer to Q3: no registry type, no widening of the in-scope-markdown wording, no criterion id.
- Scope is project claims only — not layout, styling or wording.

**Acceptance Criteria:**
- [ ] The check reports the live defect present in today's `kb.html`, with both greps recorded — the generated tour still names the pre-rename state file throughout.
- [ ] No registry type is added, the `G-07` in-scope-markdown wording is untouched, and no criterion id is allocated — verified by diffing `.aid/knowledge/authoring-conventions.md`, which must show no registry change.
- [ ] Extracting zero claims is a failure, not a pass.
- [ ] Two consecutive runs produce identical output.
- [ ] All section-6 quality gates pass
