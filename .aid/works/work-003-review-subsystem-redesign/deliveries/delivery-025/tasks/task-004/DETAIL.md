# task-004: Render the changed reference to five profiles

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-003-review-subsystem-redesign -> delivery-025

**Depends on:** task-002

**Scope:**
- The five-profile render of `state-fix.md`, plus the dogfood `.claude/` resync
- Nothing else: this task changes no behaviour and authors no content

**Acceptance Criteria:**
- [ ] `/generate-profile` run and all five rendered trees carry the changed file
- [ ] Dogfood byte-identity passes after the resync -- `.claude/` matches `profiles/claude-code/`
- [ ] The render is deterministic: re-running it produces no diff
- [ ] No file outside the render set changed -- checked with `git diff --name-only`, not asserted
- [ ] All section-6 quality gates pass
