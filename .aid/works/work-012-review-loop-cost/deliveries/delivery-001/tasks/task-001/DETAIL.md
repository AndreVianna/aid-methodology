# task-001: Review-cost meter: record and report

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

**Depends on:** -- (none)

**Scope:**
- `tests/review-cost-meter.sh`, bash + awk only (NFR-2), beside `coverage-parity.sh`.
- `record --task T --cycle N --brief <path>`: sum the on-disk sizes of the paths named under the brief's `ARTIFACTS UNDER REVIEW`, append one row `task / cycle / commit / surface_bytes` to `review-cost.tsv`.
- `report [--split-at-task task-NNN | --split-at <commit>]`: per task, cycles-to-close and the within-task re-read ratio `mean(surface_bytes[cycle>=2]) / surface_bytes[cycle 1]`; split the tasks into before/after sides and print both metrics per side.
- The `#run <run-id>` header line and the `.meta` sidecar, both created together on the first `record`.
- NOT in scope: any `canonical/` edit, any STATE schema change, any reader-twin change. feature-001 makes none.

**Acceptance Criteria:**
- [ ] `record` creates `review-cost.tsv` and `.meta` together on first call, stamping one run id into both
- [ ] A later `record` refuses to append when the two run ids disagree, when either file is missing, or when the `.tsv` has no `#run` line
- [ ] `report` refuses to compute on a run-id mismatch, and refuses a ratio for any task with fewer than two recorded cycles rather than averaging over the hole
- [ ] `report` prints the row count behind every figure, and shows a task with no rows as missing rather than as zero
- [ ] `report --split-at <commit>` fails loudly, naming the affected rows, when a recorded commit is unreachable (rebase/squash), instead of misclassifying
- [ ] No file outside `tests/` and the work folder is created or modified
- [ ] All REQUIREMENTS.md §6 quality gates pass
