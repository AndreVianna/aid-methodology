# task-015: Final measurement and reporting

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

**Depends on:** task-014

**Scope:**
- Take AC-1's after reading with `review-cost-meter.sh report --split-at-task task-008` and report both metrics per side, with row counts.
- Measure AC-9's byte reduction: the requirements slice a real feature's specify gate receives, against the whole `REQUIREMENTS.md` at the same commit.
- Confirm AC-10: `grade.sh` byte-identical to its state at the start of the work.
- Report AC-11's net trade: the oracle's decided-versus-undecided counts against the re-derivation it replaces.
- Read-only on the source; this task measures and reports, it does not fix.

**Acceptance Criteria:**
- [ ] AC-1: both metrics reported for the before and after sides -- cycles-to-close and the within-task re-read ratio -- each with the command that produced it and the row count behind it
- [ ] The after figure is lower on both metrics, OR the shortfall is reported honestly with its sample size rather than presented as a result
- [ ] A raw cross-task byte comparison is NOT offered as evidence (§9 AC-1 refuses it)
- [ ] AC-9: the slice-versus-whole-document byte reduction is stated as a measured figure on a named feature
- [ ] AC-10: `git diff` shows `canonical/aid/scripts/grade.sh` unchanged since the work's first commit
- [ ] AC-11: every oracle shipped names the recurring re-derivation it replaces and its measured per-cycle cost; the net is reported
- [ ] The measurement is reproducible: re-running `report` over the same tree and the same `--split-at-task` yields the same figures (the TEST default "deterministic" applies here)
- [ ] The TEST defaults "clean setup/teardown" and "all acceptance criteria from source feature covered" are **N/A for this task and recorded as such**: it authors no fixture and mutates nothing, and its job is to REPORT the criteria other tasks proved, not to re-prove them
- [ ] All REQUIREMENTS.md §6 quality gates pass
