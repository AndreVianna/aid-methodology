# task-031: Executor-poll baseline in state-execute.md across all profiles

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** feature-008-execution-control -> delivery-005

**Depends on:** task-028

**Scope:**
- Edit canonical `canonical/skills/aid-execute/references/state-execute.md` to add the orchestrator
  BASELINE poll (SPEC §Feature Flow "Baseline -- the orchestrator `aid-execute`"). At every
  task-dispatch boundary (between tasks / between reviewer-fix cycles) AND at the existing
  heartbeat-read point (~line 349, where it already "reads heartbeat files for each in-flight task"):
  - **(1) Pipeline Finish** -- re-read the work `lifecycle`; any NON-`Running` value ⇒ STOP: dispatch
    no new tasks, let in-flight sub-agents reach their next safe checkpoint, and do NOT advance the
    pipeline.
  - **(2) Task Stop/Resume** -- `stat` each in-flight task's `.stop` file at
    `<work_dir>/../../.control/<work_id>/task-<NNN>.stop` (worktree-relative, WT-1); present ⇒
    dispatch no next reviewer/fix cycle for that task; absent again ⇒ resume.
- Read the poll interval exactly as the heartbeat does:
  `read-setting.sh --path traceability.heartbeat_interval --default 1`.
- Task `State` is NEVER mutated by a pause -- a stopped task stays `In Progress`; the pause is the
  derived `stop_requested` overlay only.
- Document the poll-cadence degradation: if heartbeat is disabled
  (`traceability.heartbeat_interval: 0`), stop takes effect at the orchestrator's next task-dispatch
  BOUNDARY rather than mid-task -- still takes effect, just less promptly (documented, not a failure).
- Render the canonical edit ACROSS all 5 profiles in lockstep --
  `profiles/{antigravity,claude-code,codex,copilot-cli,cursor}/<agent-dir>/skills/aid-execute/references/state-execute.md`
  -- AND resync the dogfood repo-root `.claude/` from `profiles/claude-code/`. Keep the render/twin
  parity green (`tests/canonical/test-dogfood-byte-identity.sh` + the profile-render parity check).
- Edits are ADDITIVE (new reads at ticks that already fire); no new poll infrastructure is introduced.

**Acceptance Criteria:**
- [ ] `state-execute.md` (canonical) re-reads `lifecycle` at the task-dispatch boundary and the
      existing heartbeat-read point, and treats any non-`Running` value as STOP (no new dispatch, no
      pipeline advance) -- Pipeline Finish.
- [ ] `state-execute.md` stats each in-flight task's `.stop` file at the work-dir-relative control
      path (`<work_dir>/../../.control/<work_id>/task-<NNN>.stop`, WT-1) and declines the next
      reviewer/fix cycle when present, resuming when absent -- Task Stop/Resume.
- [ ] The interval is sourced via `read-setting.sh --path traceability.heartbeat_interval --default 1`,
      and the `heartbeat_interval: 0` degradation (stop at next boundary) is documented.
- [ ] No task `State` write occurs on pause (the task stays `In Progress`).
- [ ] The canonical edit is rendered byte-consistent across all 5 profiles
      (antigravity, claude-code, codex, copilot-cli, cursor) AND the dogfood repo-root `.claude/`;
      `tests/canonical/test-dogfood-byte-identity.sh` and the profile-render parity check pass.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
