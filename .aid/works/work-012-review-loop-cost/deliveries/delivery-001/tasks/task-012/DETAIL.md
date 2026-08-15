# task-012: Scoped-cycle convention in the criteria tables

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

**Depends on:** task-008

**Scope:**
- `.aid/knowledge/authoring-conventions.md` -- **C-5 authorized, enumerated**: the scoped-cycle note only.
- State that cycle 1 reads everything, cycles 2+ verify the ledger in full but hunt only in what the previous FIX changed, and that a scoped cycle never approves.
- NOT in scope: the `Match` column and `oracle:` field (task-004's edit, already landed), or any other `.aid/knowledge/` change.

**Acceptance Criteria:**
- [ ] The note is added to `authoring-conventions.md` and states all three parts: full cycle 1, full verification, scoped hunt
- [ ] It cross-references `reviewer-ledger-schema.md` rather than restating the clause, so there is no second definition to drift
- [ ] No other `.aid/knowledge/` file is touched, and no other section of this file is modified
- [ ] The criteria cascade itself is unchanged (C-4, §4)
- [ ] **The edit introduces no work id and no work-folder path into `.aid/knowledge/`** -- not `work-012`, not `.aid/works/work-012-*/`, not "added by work-012", in prose, table cell, heading or frontmatter. `AGENTS.md` forbids it because a work folder is pruned when the work ships, making the cite a dangling pointer by design. This is stated as a task criterion because **no criterion id covers the rule** (see Q-06) -- a reviewer could not otherwise file a finding for it, and PR #195 had to clean exactly this by hand
- [ ] All REQUIREMENTS.md §6 quality gates pass
