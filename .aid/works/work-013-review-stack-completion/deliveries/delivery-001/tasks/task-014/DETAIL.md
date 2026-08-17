# task-014: The eight live citation violations fixed so the new CI step is green

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

**Depends on:** task-013

**Scope:**
- Fix the eight bare line-number citations `kb-citation-lint.sh` currently reports in `.aid/knowledge/tech-debt.md`, replacing each with a durable anchor.
- Do not reword the surrounding rows — these are historical debt entries; only the citation form changes.

**Acceptance Criteria:**
- [ ] `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge; echo $?` returns `0`, measured at exit `1` with eight violations before.
- [ ] The CI step added by the previous task is green as a result, so the wiring is proven by a real pass rather than asserted.
- [ ] Each replaced citation still resolves to the thing it pointed at, checked by running the anchor grep.
- [ ] All section-6 quality gates pass
