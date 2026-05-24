# Long-Wait Protocol (orchestrator-side subagent dispatch heartbeat)

When an AID skill (an "orchestrator") dispatches a subagent that may run longer
than 5 minutes, the orchestrator MUST follow this protocol so the user sees
steady progress signal instead of going silent for 10–25 minutes between the
opening `▶` and the completion notification.

This protocol is the L2 layer of the subagent-visibility scheme introduced in
the `subagent-visibility-patch`. L1 = honest ETAs (see `rough-time-hints.md`);
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
▶ <agent-name> starting (~<low>–<high>) — arming check-ins at <low/2>, <low>, <1.5×low>
```

Then arm THREE backgrounded shell timers (using `run_in_background: true`):

```bash
sleep <low/2 in seconds> && echo "... <agent-name> still running (<low/2>m elapsed of ~<low>–<high>)"
sleep <low in seconds>   && echo "... <agent-name> at estimated time (<low>m elapsed of ~<low>–<high>; awaiting completion)"
sleep <1.5×low in seconds> && echo "⚠️  <agent-name> EXCEEDED estimate (<1.5×low>m elapsed of ~<low>–<high>); consider checking on it or cancelling"
```

Each timer fires independently of the others and of the subagent. If the
subagent completes BEFORE a timer fires, the timer fires harmlessly and the
orchestrator includes it in narration as historical context ("subagent
completed at 4m; the 5m check-in fired afterward").

### Step 3 — Dispatch the subagent

Standard dispatch. If using L3 (subagent self-reporting), include
`HEARTBEAT_FILE=...` + `HEARTBEAT_INTERVAL=N` parameters in the prompt per
`subagent-heartbeat-protocol.md`.

### Step 4 — On each timer fire (mid-wait)

When a timer fires, surface its output to the user. If L3 is active, also read
the heartbeat file and append its latest state:

```
... <agent-name> still running (<m> elapsed of ~<low>–<high>)
    [from heartbeat] <single line from heartbeat file, e.g., '[2026-05-23T20:35:05Z] REVIEW | 4/21 docs | Reading data-model.md (~12m remaining)'>
```

### Step 5 — On completion notification

Emit the closing bracket with ACTUAL elapsed time and log it for L1 calibration:

```
✓ <agent-name> done in <actual>m <actual>s (estimated <low>–<high>; observed +<delta> over LOW)
```

Add a row to `STATE.md ## Calibration Log` (or equivalent) so the next refresh
of `rough-time-hints.md` has a data point.

### Step 6 — On crash / abnormal completion

If the host notification reports a non-success status (network error, timeout,
explicit failure), emit:

```
✗ <agent-name> FAILED after <elapsed> (reason: <one-line>; <N> tool uses logged)
```

…and decide based on context whether to re-dispatch, fall back to manual work,
or surface to the user.

## Example (from work-003 cycle-12 reviewer dispatch)

```
[Look up: discovery-reviewer ETA = 18–25 min from rough-time-hints.md]
▶ discovery-reviewer (cycle-12 confirm A+) starting (~18–25 min) — arming check-ins at 9m, 18m, 27m

[9 minutes pass; first timer fires]
... discovery-reviewer still running (9m elapsed of ~18–25)
    [from heartbeat] [2026-05-23T14:32:08Z] REVIEW | 14/21 KB docs reviewed | Reading data-model.md §3 (Mermaid dataflow); cross-checking against current code (~8m remaining)

[14 more minutes pass; subagent notification arrives at 23m30s before second timer fires]
✓ discovery-reviewer done in 23m30s (estimated 18–25; within band)

[Subsequent 18m + 27m timers fire harmlessly; orchestrator narration includes them as historical context]
```

## Why three timers and not one

A single timer at ETA/2 catches the common case but provides no signal when
the subagent runs LONGER than expected. The three-tier ladder (ETA/2, ETA,
1.5×ETA):

- ETA/2 = "I haven't gone silent on you"
- ETA = "the estimate is exhausted; subagent should be wrapping up"
- 1.5×ETA = "something is wrong; investigate"

This catches runaway / hung subagents without requiring the orchestrator to
actively poll (which is hard in a pure-skill-body design).

## Pitfalls

- **Don't arm timers if ETA < 5 min.** The mid-wait check-in adds noise; the
  user will get the completion notification before the timer fires anyway.
- **Always emit `✗` on failure.** A silent failure (no `✓`, no `✗`) is worse
  than the original silent wait — it suggests the subagent is still running.
- **Calibrate.** When `rough-time-hints.md` has a row marked `(gut estimate)`
  with `Samples: 0`, the first 3 observations should immediately update the
  table. Stale ETAs are the root cause of the visibility gap this protocol
  exists to fix.
