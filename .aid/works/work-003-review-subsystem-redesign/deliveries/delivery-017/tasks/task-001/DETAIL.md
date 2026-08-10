# task-001: The attributed-quote check

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

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** --

**Scope:**
- The check: a string presented as verbatim from a named file must **mean what that file means**. The substring test is a **cheap pre-filter** -- a hit proves fidelity and exits early; a miss escalates to reviewer judgment and does **not** fail the run (`Q25`, 2026-08-09; this read *"must appear in that file"*)
- Emphasis normalisation on both sides before comparison -- mandatory
- Advisory handling for an unattributed quote and for an elided one
- Its test suite, including the AC-14 fixtures: work artifacts of each type AC-14 names -- `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md` and task `DETAIL.md` -- failing in both directions

**Acceptance Criteria:**
- [ ] A quote present passes and exits early; one **differing only in markdown emphasis passes**; one **absent does NOT fail** -- it escalates to reviewer judgment (`Q25`). Without the **second**, the check ships with false positives on this repository's own specs; without the **third**, it re-enforces the byte criterion `Q25` retires
- [ ] An unattributed quote is advisory and does not change the exit code, so the coverage boundary is reported rather than hidden
- [ ] AC-14 holds in both directions on every artifact type it names: one fixture of each carrying a broken citation exits 1, while a fixture carrying only a **drifted quote** does not -- a reword that preserves meaning is not a defect (`Q25`), and the same fixture with both corrected exits 0. A suite asserting only the failure direction is satisfied by a check that flags everything, and one asserting only the pass direction by a check that flags nothing
- [ ] All section-6 quality gates pass
