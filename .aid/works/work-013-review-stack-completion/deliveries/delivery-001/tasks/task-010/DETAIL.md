# task-010: Settings schema of record corrected and format_version templated

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

**Depends on:** task-009

**Scope:**
- `.aid/knowledge/artifact-schemas.md` § settings.yml: documented keys that no longer resolve become optional-with-fallback or are removed; keys stored but undocumented are documented.
- Stop the grade domain naming `F`, which `grade.sh` cannot emit.
- `canonical/aid/templates/settings.yml` gains `format_version`, which it ships without today.

**Acceptance Criteria:**
- [ ] Re-running the documented-key probe leaves no resolving key undocumented and no documented key without a stated fallback, with the command recorded.
- [ ] `grep -c format_version canonical/aid/templates/settings.yml` returns `1`, measured at `0` before, and its value equals the version `bin/aid` expects.
- [ ] The generator is re-run in the same commit and the render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
