# Dispatch Protocol Checklist

> Every AID skill that dispatches subagents follows this checklist (L1+L2+L3 traceability).

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `.agent/aid/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** via
   `bash .agent/aid/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
   (resolves from `.aid/settings.yml`; default 1; `0` = disabled).
3. **Pre-create heartbeat file** (always — unconditional):
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
4. **Arm 3 L2 timers** (via `run_in_background: true`), each interval capped at 4.5 min:
   - `sleep <min(LOW/2, 270) in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <min(LOW, 540) in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <min(1.5×LOW, 810) in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`
   - **Keep-warm re-arm:** when the last timer fires and the sub-agent is still running, arm one more `sleep 270 && echo "... <agent> still running (Xm elapsed)"`, and again on each fire, until the completion notification arrives. Every fire is a request that re-reads the cached context and refreshes its 5-minute prompt-cache TTL; a silent gap over 5 minutes re-writes the whole context at full price (measured: $2.18 for a 175k-token orchestrator context).

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time for L1
  calibration. When the dispatch is for a real `task-NNN`, append a
  `dispatch_log` entry to that task's own state (full path: its `STATE.yml`;
  flat path: `tasks_lifecycle.task-NNN.dispatch_log`) -- the work-level
  Calibration Log / Dispatches views are derived at read time from these
  entries (`work-state-template.yml`); there is no work-level section to
  write. When the dispatch is NOT task-scoped,
  there is no persisted target at all -- the console line above is the sole
  record. Delete heartbeat file.
- **Failure:** emit `✗ <agent> FAILED after <elapsed> (reason: <one-line>)`.
  Decide whether to re-dispatch, fall back, or surface to user. Delete
  heartbeat file.

**References:**

- `.agent/aid/templates/long-wait-protocol.md` — full L2 spec
- `.agent/aid/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `.agent/aid/templates/rough-time-hints.md` — current measured ETAs
- `.agent/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

