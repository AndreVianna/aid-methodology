# task-036: Corpus size, the NFR-3 floor, and the recall-regression route

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-026

**Scope:**
- Decide how many defects the corpus seeds by measuring what settles it: the pair-check count and the read surface per cycle at candidate sizes, against the script's upkeep.
- Recommend whether a recall regression gets a criterion id or routes to tech debt — without allocating an id.
- State the NFR-3 floor as a number with the command that produces it.

**Acceptance Criteria:**
- [ ] At least two candidate corpus sizes are compared, each with its command, plus the by-hand alternative — the option NFR-3 forces onto the table.
- [ ] The floor is a number produced by a command, so "the script does not merge" is decidable rather than arguable.
- [ ] The re-derivation the script would remove is reproduced as one that is **wrong** by default rather than merely tedious — the naive count and the status-aware count disagree on a real ledger.
- [ ] **"The script does not merge" is recorded as an admissible outcome of this task**, with the discharge wording agreed in advance.
- [ ] No criterion id is allocated; the recall-regression route is raised as a Q&A entry in this delivery's own state file, because the allocation is out of scope pending an owner decision.
- [ ] All section-6 quality gates pass
