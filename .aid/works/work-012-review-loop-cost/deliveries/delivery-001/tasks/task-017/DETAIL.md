# task-017: AC-1 evidence: the paired within-task control

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

**Depends on:** task-016

**Scope:**
- Run the paired control AC-1 now specifies, over **at least three** subject artifacts.
- For each subject: cycle 1 as normal, then cycle 2 declared TWICE -- a CONTROL arm declaring the full surface (the pre-FR-3 rule) and a TREATMENT arm declaring the scoped surface (FR-3). Same task, same artifact, same reviewer, same rubric.
- Record every arm with `review-cost-meter.sh record` and report with `report`.
- Report BOTH metrics per arm: the within-task re-read ratio, and cycles-to-close, each with its row count.
- Rewrite `MEASUREMENT.md` section AC-1 with the result, whatever it shows.
- Read-only on the product: this task measures and reports; it fixes nothing.

**Acceptance Criteria:**
- [ ] At least three subjects are measured, so no single artifact carries the result
- [ ] Both arms are recorded for every subject, and the arms differ ONLY in which rule the brief follows -- same task, same artifact, same reviewer
- [ ] The control arm's ratio is at or near 1.000, confirming the old rule re-declares the whole surface; if it is not, the control is wrong and the comparison is void
- [ ] The treatment arm's ratio is materially lower, OR the shortfall is reported honestly with its sample size rather than presented as a result
- [ ] Cycles-to-close is reported per arm with row counts (the metric the delivery gate found missing)
- [ ] `MEASUREMENT.md` states the design, the numbers, the command that produced each, and the limits -- including that the control arm is a constructed comparison rather than a historical observation
- [ ] No product file is modified by this task
- [ ] All REQUIREMENTS.md §6 quality gates pass
