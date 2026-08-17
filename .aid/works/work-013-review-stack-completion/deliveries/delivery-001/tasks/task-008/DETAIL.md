# task-008: test-review-path-audit.sh — the audit fails on a rival-shaped tree

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

**Type:** TEST

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-007

**Scope:**
- New suite under `tests/canonical/`, discovered by the existing glob so `run-all.sh` needs no edit.
- Fixture cases proving each layer can fail, built in a temporary directory; the real tree is never mutated.

**Acceptance Criteria:**
- [ ] The suite passes against the real tree.
- [ ] It fails when given a second review-family skill directory.
- [ ] It fails when given an agent named `aid-screener` — the case the `*review*` glob misses, demonstrated on the canceled branch where that glob returns `1` while `aid-screener/AGENT.md` is present.
- [ ] It fails on the two vacuity cases: zero references extracted, and zero review-family references.
- [ ] The suite is deterministic across runs, cleans up its fixtures, and the repository's baseline failure count is unchanged.
- [ ] All section-6 quality gates pass
