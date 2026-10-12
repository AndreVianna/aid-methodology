# Long-Wait Protocol (orchestrator-side subagent dispatch heartbeat)

When an AID skill (an "orchestrator") dispatches any subagent, the orchestrator
MUST follow this protocol so the user sees steady progress signal instead of
going silent for 10–25 minutes between the
opening `▶` and the completion notification.

This protocol is the L2 layer of the subagent-visibility scheme.
L1 = honest ETAs (see `rough-time-hints.md`);
L2 = this doc (orchestrator-side check-in timers); L3 = subagent self-reporting
via heartbeat file (see `subagent-heartbeat-protocol.md`).

## When to apply

Apply this protocol when ALL of the following are true:

1. The orchestrator is about to dispatch a subagent (via `Agent` / equivalent
   host-tool mechanism)
2. The subagent's expected ETA — looked up from `rough-time-hints.md` for the
   matching operation class — has a LOW-END value > 5 minutes
3. The host environment supports backgrounded shell commands (`run_in_background`
   in Claude Code's Bash tool; equivalent in Codex / Cursor)

If any of these is false, fall back to the basic FR1 AC2 bracket-pair (one `▶`
on dispatch, one `✓` on completion) without the timer protocol.

## Protocol

### Step 1 — Look up ETA

Before dispatching, read `rough-time-hints.md` and find the row matching the
subagent's operation class. Capture the LOW-END and HIGH-END of the ETA band.

For multi-subagent parallel dispatches (e.g., 4 parallel discovery sub-agents),
use the HIGHEST ETA from the parallel set (tail latency).

### Step 2 — Emit opening bracket + arm 3 timers

```
▶ <agent-name> starting (~<low>–<high>) — arming check-ins at <a>, <b>, <c> (each gap ≤ 4.5 min)
```

Then arm THREE backgrounded shell timers (using `run_in_background: true`):

```bash
sleep <a = min(low/2, 4.5 min) in seconds>    && echo "... <agent-name> still running (<a>m elapsed of ~<low>–<high>)"
sleep <b = min(low, 9 min) in seconds>        && echo "... <agent-name> at estimated time (<b>m elapsed of ~<low>–<high>; awaiting completion)"
sleep <c = min(1.5×low, 13.5 min) in seconds> && echo "⚠️  <agent-name> EXCEEDED estimate (<c>m elapsed of ~<low>–<high>); consider checking on it or cancelling"
```

Each timer fires independently of the others and of the subagent. If the
subagent completes BEFORE a timer fires, the timer fires harmlessly and the
orchestrator includes it in narration as historical context ("subagent
completed at 4m; the 5m check-in fired afterward").

**Keep-warm re-arm.** When the last timer fires and the subagent is still running, arm one
more 4.5-minute timer (`sleep 270 && echo "... <agent-name> still running (<elapsed>m)"`), and
again on each fire, until the completion notification arrives. Every fire is a request that
re-reads the orchestrator's cached context and refreshes its 5-minute prompt-cache TTL; a silent
gap over 5 minutes re-writes the whole context at full price (measured on a 175k-token
context: $2.18 for the re-write versus about $0.04 for a cache-read wake-up). The 4.5-minute cap
on every interval exists for the same reason.

### Step 3 — Dispatch the subagent

Standard dispatch. If using L3 (subagent self-reporting), include
`HEARTBEAT_FILE=...` + `HEARTBEAT_INTERVAL=N` parameters in the prompt per
`subagent-heartbeat-protocol.md`.

### Step 4 — On each timer fire (mid-wait)

When a timer fires, surface its output to the user. If L3 is active, also read
the heartbeat file and append its latest state:

```
... <agent-name> still running (<m> elapsed of ~<low>–<high>)
    [from heartbeat] <single line from heartbeat file, e.g., '[2026-05-23T20:35:05Z] REVIEW | 4/21 docs | Reading schemas.md (~12m remaining)'>
```

### Step 5 — On completion notification

Emit the closing bracket with ACTUAL elapsed time and log it for L1 calibration:

```
✓ <agent-name> done in <actual>m <actual>s (estimated <low>–<high>; observed +<delta> over LOW)
```

When the dispatch is for a real `task-NNN`, append a `dispatch_log` entry to
that task's own state (full path: its `STATE.yml`; flat path:
`tasks_lifecycle.task-NNN.dispatch_log`) so the next refresh of
`rough-time-hints.md` has a data point -- the work-level Calibration Log /
Dispatches views are derived at read time from these entries
(`work-state-template.yml`); there is no work-level section to write. When
the dispatch is NOT task-scoped,
there is no persisted target at all -- the actual-elapsed line above is the
sole record.

### Step 6 — On crash / abnormal completion

If the host notification reports a non-success status (network error, timeout,
explicit failure), emit:

```
✗ <agent-name> FAILED after <elapsed> (reason: <one-line>; <N> tool uses logged)
```

…and decide based on context whether to re-dispatch, fall back to manual work,
or surface to the user.

## Example (aid-reviewer dispatch)

```
[Look up: aid-reviewer ETA = 18–25 min from rough-time-hints.md]
▶ aid-reviewer (cycle-12 confirm A+) starting (~18–25 min) — arming check-ins at 9m, 18m, 27m

[9 minutes pass; first timer fires]
... aid-reviewer still running (9m elapsed of ~18–25)
    [from heartbeat] [2026-05-23T14:32:08Z] REVIEW | 14/21 KB docs reviewed | Reading schemas.md §3 (Mermaid dataflow); cross-checking against current code (~8m remaining)

[14 more minutes pass; subagent notification arrives at 23m30s before second timer fires]
✓ aid-reviewer done in 23m30s (estimated 18–25; within band)

[Subsequent 18m + 27m timers fire harmlessly; orchestrator narration includes them as historical context]
```

## Why three timers and not one

A single timer at ETA/2 catches the common case but provides no signal when
the subagent runs LONGER than expected. The three-tier ladder (ETA/2, ETA,
1.5×ETA):

- ETA/2 = "I haven't gone silent on you"
- ETA = "the estimate is exhausted; subagent should be wrapping up"
- 1.5×ETA = "something is wrong; investigate"
- every gap ≤ 4.5 min = "the cached context is still warm" (see Keep-warm re-arm above)

This catches runaway / hung subagents without requiring the orchestrator to
actively poll (which is hard in a pure-skill-body design).

## Pitfalls

- **Always arm timers, regardless of ETA.** Use sensible minimums for short
  ETAs (e.g., 60s / 120s / 180s for a < 3min dispatch). Mid-wait check-ins
  are unconditional — never gate on ETA
  threshold.
- **Always emit `✗` on failure.** A silent failure (no `✓`, no `✗`) is worse
  than the original silent wait — it suggests the subagent is still running.
- **Calibrate.** When `rough-time-hints.md` has a row marked `(gut estimate)`
  with `Samples: 0`, the first 3 observations should immediately update the
  table. Stale ETAs are the root cause of the visibility gap this protocol
  exists to fix.
