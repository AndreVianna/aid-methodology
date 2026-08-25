# task-038: review-recall.sh — the report subcommand

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-036, task-037

**Scope:**
- A sibling of the cost meter in the same directory: the `report` subcommand, bash and awk only, with the required header block and status-aware matching.
- A row counts as found only when its status is one that still counts toward a grade, its document matches, and its signature appears in the row.

**Acceptance Criteria:**
- [ ] `report` prints one row per criterion scope prefix plus a total, each carrying seeded and found as **raw counts, never a stored ratio** — a ratio hides which half moved.
- [ ] A group with nothing seeded prints as **missing**, never as complete: an empty denominator is not a perfect score.
- [ ] The header cites task-036's measured re-derivation, and the figure reproduces when re-run.
- [ ] Escaped delimiters are masked before splitting, so a cell's own content cannot shift the columns.
- [ ] Two consecutive runs are byte-identical.
- [ ] **If task-036's measurement fell below the floor, this task ships no script and records the discharge with its measurement instead** — a recorded non-merge, not a skipped criterion.
- [ ] All section-6 quality gates pass
