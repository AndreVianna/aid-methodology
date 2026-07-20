# task-032: Sub-agent STOP_FILE mid-task poll enhancement (separable)

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

**Depends on:** task-031

**Scope:**
- Extend the sub-agent heartbeat contract in canonical
  `canonical/aid/templates/subagent-heartbeat-protocol.md`: at the SAME per-N-minute tick where the
  sub-agent already WRITES its `.aid/.heartbeat/` line, it ALSO (a) stats its OWN `.stop` file and
  (b) re-reads the work `lifecycle`, halting at the next safe checkpoint -- giving mid-task
  responsiveness at exactly `heartbeat_interval` cadence.
- Introduce a new OPT-IN dispatch parameter
  `STOP_FILE=.aid/.control/<work_id>/task-<NNN>.stop` added to the dispatch prompt, directly
  analogous to the existing `HEARTBEAT_FILE=…` parameter. An ABSENT `STOP_FILE` disables the
  stop-poll for that sub-agent exactly as an absent `HEARTBEAT_FILE` disables heartbeat -- so no
  sub-agent ever guesses its own control path, and un-updated dispatch sites are unaffected.
- Update the agent boilerplate so it carries `STOP_FILE` alongside `HEARTBEAT_FILE`.
- Render the protocol + boilerplate edit ACROSS all 5 profiles in lockstep
  (`profiles/{antigravity,claude-code,codex,copilot-cli,cursor}/<agent-dir>/aid/templates/subagent-heartbeat-protocol.md`
  + each profile's agent boilerplate) AND resync the dogfood repo-root `.claude/`; keep the
  render/twin parity green (`tests/canonical/test-dogfood-byte-identity.sh` + profile-render parity).
- Edits are ADDITIVE and OPT-IN (no behavior change where `STOP_FILE` is not passed). This is the
  recommended, separable, deferrable enhancement -- NOT the MVP gate; its broad render-lockstep +
  parity blast radius is why it is scoped as a follow-on.

**Acceptance Criteria:**
- [ ] `subagent-heartbeat-protocol.md` (canonical) documents the per-tick self-`stat` of the
      sub-agent's OWN `.stop` file plus the `lifecycle` re-read, halting at the next safe checkpoint
      at `heartbeat_interval` cadence.
- [ ] The `STOP_FILE=` opt-in dispatch parameter is defined alongside `HEARTBEAT_FILE=`; an ABSENT
      `STOP_FILE` disables the stop-poll for that sub-agent (behavior parity with an absent
      `HEARTBEAT_FILE`), and no sub-agent derives its own control path.
- [ ] The agent boilerplate is updated to carry `STOP_FILE` alongside `HEARTBEAT_FILE`.
- [ ] The protocol + boilerplate edit is rendered byte-consistent across all 5 profiles
      (antigravity, claude-code, codex, copilot-cli, cursor) AND the dogfood repo-root `.claude/`;
      `tests/canonical/test-dogfood-byte-identity.sh` and the profile-render parity check pass.
- [ ] The change is additive and opt-in: dispatch sites that do not pass `STOP_FILE` are unaffected.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
