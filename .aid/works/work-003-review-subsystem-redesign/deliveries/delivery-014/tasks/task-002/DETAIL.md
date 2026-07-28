# task-002: The frontmatter runtime gate

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-014

**Depends on:** --

**Scope:**
- `lint-frontmatter.sh` gaining `--fail-on-skip`, additive and default-off
- The gate wired into the KB authoring state, in the shape the citation lint's step already models
- The M2 mandate's duplicate frontmatter hand-checks, retired
- The renderer-blind hardcoded install path in the adjacent invocation

**Acceptance Criteria:**
- [ ] The lint is invoked by a skill state, not only by tests and CI
- [ ] The M2 duplicate checks are gone **and** a pointer to the lint remains -- both halves, or the defect becomes unowned
- [ ] No canonical body carries a hardcoded install-root script path
- [ ] All section-6 quality gates pass
