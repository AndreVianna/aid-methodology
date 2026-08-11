# task-003: Lane A and the three section-6 checks

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
- `tests/canonical/test-recall-corpus.sh`, carrying Lane A's assertions and all three checks in `SPEC.md § 6`
- Lane A: for each `enforcement = script` row, run its `oracle` over its `fixture` and assert the run **reports** the defect -- always a positive assertion, whatever `polarity` says
- Section-6 checks 1, 2 and 3, all in the default pass

**Acceptance Criteria:**
- [ ] Check 1 holds in the direction `polarity` declares: a `present` row's `locator` is found in its fixture, an `absent` row's is not, and a `fixture = --` row is exempt but must carry a `summary`
- [ ] Check 2 fails when an in-domain rule set's every row is a `--` exemption -- proved by making one so and watching the suite fail
- [ ] Check 3 fails when a rule row has no catalogue row at all -- proved the same way, by adding a rule row and not seeding it
- [ ] Lane A asserts and never averages: a miss is a failure, not a lowered fraction
- [ ] The suite carries **no mutation-of-the-mutation check**. `SPEC.md § 6` records why: the draft that had one traced to no requirement and nothing was specified to pass its flag
- [ ] All section-6 quality gates pass
