# task-011: settings-schema-check.sh — the mechanical settings gate

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

**Depends on:** task-010

**Scope:**
- New `scripts/checks/settings-schema-check.sh` taking a `--path`, asserting the settings file's shape without any agent judgment.
- A header block citing the measured re-derivation it removes.

**Acceptance Criteria:**
- [ ] Exits `0` on the corrected real settings file.
- [ ] Exits `1`, naming the offending key, for each of: a missing `format_version`, a `minimum_grade` value `grade.sh` cannot emit, and an undocumented top-level key.
- [ ] **Exits `1` on a settings file with zero keys** — examining nothing is a failure, never a pass.
- [ ] Prints what it examined beside what it expected.
- [ ] The header's cited re-derivation reproduces the read-setting call-site counts and the default-value split when re-run.
- [ ] Two consecutive runs produce identical output.
- [ ] All section-6 quality gates pass
