# task-002: Meter test suite

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

**Type:** TEST

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-001

**Scope:**
- A canonical suite covering `review-cost-meter.sh`'s contract.
- Fixtures build their own trees; no dependence on this work's own live `review-cost.tsv`.

**Acceptance Criteria:**
- [ ] Two `report` runs over an unchanged tree produce byte-identical output (NFR-3)
- [ ] A deliberately mismatched `.tsv`/`.meta` pair is refused by BOTH `record` and `report`
- [ ] A task with one recorded cycle yields no ratio and is reported as such
- [ ] A task with zero rows appears as missing, never as zero
- [ ] An unreachable `--split-at` commit produces a loud failure naming the rows, not a silent misclassification
- [ ] Tests are deterministic with clean setup/teardown
- [ ] All REQUIREMENTS.md §6 quality gates pass
