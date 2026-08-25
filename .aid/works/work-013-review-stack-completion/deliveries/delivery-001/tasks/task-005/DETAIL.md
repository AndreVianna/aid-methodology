# task-005: Catalog screening — classes SUMMARY, DEF, AID and PRO

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

**Type:** RESEARCH

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-001

**Scope:**
- Read the SUMMARY, DEF, AID and PRO rule rows (29 of 85) from the canceled branch via `git show 8b9e62021:…`; never check that branch out.
- Screen each row against the four conditions: is the check uncovered by a current criterion, is it declarable, is it attachable to a type or to `*`, and is it priceable with a severity.
- For each admitted row, propose an id from the ledger, a severity and a one-line why.

**Acceptance Criteria:**
- [ ] All 29 rows carry a recorded outcome — `admit`, `covered by <id>`, `rubric-owned`, or `needs a new type — out of scope` — each with its evidence.
- [ ] Every claim cites `git show 8b9e62021:<path>` so a reader can reproduce it without the branch checked out.
- [ ] Where a row could attach either to `*` or to one type, both options are stated with the reason for the recommendation.
- [ ] Admitting zero rows is a valid outcome, provided the per-row table is recorded — the screen's value is the record, not the count.
- [ ] All section-6 quality gates pass
