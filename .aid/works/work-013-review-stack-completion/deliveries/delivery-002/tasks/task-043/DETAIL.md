# task-043: The observe-only boundary in the oracle contract

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

**Depends on:** task-028

**Scope:**
- Add three clauses to the oracle contract in the frontmatter schema: a check that emits no per-file verdict is not an oracle and produces no ledger row; the absence of a rule is gradeable only as an open criteria gap, because a finding must cite an id that resolves; and a violation is consumed as an ordinary finding.
- State the matching clause for authors in the KB.
- Re-run the generator in the same commit.

**Acceptance Criteria:**
- [ ] All three clauses resolve by grep.
- [ ] The cost meter and the recall script are named as examples of the observe-only kind, so the boundary has referents rather than being abstract.
- [ ] **No oracle key is added and no column is added to the criteria table** — its header is unchanged, verified by diff.
- [ ] The criteria table gains no row for this, so the partition claim the oracle checks is untouched.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
