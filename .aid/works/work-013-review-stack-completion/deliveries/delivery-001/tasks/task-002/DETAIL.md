# task-002: Rubric-catalog framing removed from the dispatch protocol

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

**Depends on:** task-001

**Scope:**
- `canonical/aid/templates/reviewer-dispatch.md`: remove the rubric-catalog framing and the dead `(future)` rubric pointers, leaving the composition rule verbatim.
- `canonical/agents/aid-reviewer/AGENT.md`: correct the `content-isolation.md` reference, which resolves to no file.
- Re-run the full generator in the same commit so no render is left stale.

**Acceptance Criteria:**
- [ ] `grep -rn 'rubric catalog' canonical tests scripts docs .aid/knowledge` returns `0`, measured at `2` before.
- [ ] `grep -rn 'content-isolation\.md' canonical` returns `0`, measured at `1` before.
- [ ] The three-spelling 7-column grep still returns `2` in each of the six per-skill briefs and `1` in `/aid-review` — this task changes no ledger-shape prose.
- [ ] `run_generator.py` re-run in the same commit and `verify_deterministic.py` reports PASS.
- [ ] All section-6 quality gates pass
