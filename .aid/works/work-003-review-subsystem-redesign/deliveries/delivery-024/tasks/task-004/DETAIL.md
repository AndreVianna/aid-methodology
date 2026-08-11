# task-004: The corpus changes no existing grade

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-003-review-subsystem-redesign -> delivery-024

**Depends on:** task-002

**Scope:**
- `tests/canonical/test-recall-grade-neutrality.sh` -- **its own suite file, not an addition to `task-003`'s.** The two run wave-parallel with no edge between them, and the ready set is computed from `Depends on` alone with no wave barrier at runtime (`aid-execute/references/state-execute.md`, PD-1), so sharing a file would put two concurrent agents in one suite
- An assertion that adding this corpus changes no letter `grade.sh` computes for any ledger that existed before it
- The pre-change letters captured by running `grade.sh` rather than transcribed

**Acceptance Criteria:**
- [ ] For every fixture ledger in the tree, `grade.sh` returns the same letter before and after the corpus exists
- [ ] The comparison is reproducible from the recorded inputs -- the baseline is a file the suite writes, not a number pasted into a document
- [ ] The assertion fails if a corpus fixture is ever placed where `grade.sh` would read it as a ledger, which is the one way this delivery could move a grade
- [ ] All section-6 quality gates pass
