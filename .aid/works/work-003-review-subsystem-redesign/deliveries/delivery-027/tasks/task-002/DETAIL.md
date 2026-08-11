# task-002: The two-term report and the series

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-027

**Depends on:** task-001

**Scope:**
- The report `SPEC.md § 3` step 4 specifies: one line per rule set, then one OVERALL line, each carrying the terms that apply
- `tests/recall-baseline.tsv`: every line step 5 emits -- one per rule set **and the OVERALL line** -- appended and run-stamped, written by this script and no other

**Acceptance Criteria:**
- [ ] Both terms of `FR-H2` are produced: a figure **per rule set** and an **overall** figure, the second in addition to the first and never instead of it
- [ ] Either term may print `--`; **neither is ever `0/0`**, which would read as a measured zero
- [ ] The two terms are printed **side by side and never blended**, on the per-rule-set lines and on the OVERALL line. A blend would be the second grading arithmetic `FR-F6` retires, and would hide which lane moved
- [ ] The OVERALL line is persisted to the series, because `FR-H3` reads a drop over time and `FR-H2`'s overall term would otherwise have no baseline
- [ ] The script creates and appends the series itself: no other writer, and no per-close duty anywhere
- [ ] All section-6 quality gates pass
