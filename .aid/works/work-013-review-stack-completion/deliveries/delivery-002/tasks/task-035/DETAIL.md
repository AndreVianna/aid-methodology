# task-035: test-ledger-isolation.sh and the three recorded attempts

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-034

**Scope:**
- New suite in the canary shape the output-root isolation suite already uses: assert the literal-path count is zero in the instruction surface, and exercise the cycle-1 preflight against a seeded leftover inside a temporary copy.
- Record the three attempts to reach a prior cycle's ledger, with their exit codes.

**Acceptance Criteria:**
- [ ] The third attempt — the preflight against a seeded leftover — fails and names the file, and the assertion itself fails if the preflight is removed.
- [ ] The temporary copy is what gets mutated, and the source tree is asserted byte-identical afterwards.
- [ ] Attempts one and two are recorded against a path a **prior cycle of this delivery actually used**, not an arbitrarily absent one: a path that was never written proves nothing about reachability.
- [ ] The record states plainly that the design closes the naming, not the filesystem, and that the structural claim rests on the CI hygiene step rather than on ignore rules.
- [ ] Deterministic, fixtures cleaned up, baseline failure count unchanged.
- [ ] All section-6 quality gates pass
