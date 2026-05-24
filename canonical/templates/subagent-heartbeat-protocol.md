# Subagent Heartbeat Protocol

When an AID skill (an "orchestrator") dispatches a subagent that may run longer
than 5 minutes, the orchestrator MAY pass a `HEARTBEAT_FILE=...` +
`HEARTBEAT_INTERVAL=Nm` parameter to the subagent. If passed, the subagent MUST
write periodic progress notes to that file. The orchestrator can then read the
file when its L2 check-in timer fires (see `long-wait-protocol.md`) to surface
real progress rather than just elapsed time.

This protocol is the L3 layer of the subagent-visibility scheme. L1 = honest
ETAs (`rough-time-hints.md`); L2 = orchestrator check-in timers
(`long-wait-protocol.md`); L3 = this doc (subagent self-reporting).

## Configuration

The heartbeat interval is configured in `.aid/knowledge/STATE.md` top-of-file
metadata as `**Heartbeat Interval:** N minutes`. Default value = **1 minute**.

`aid-init` writes this line during initial scaffolding (asking the user if they
want to override the default). If the line is absent from STATE.md, dispatchers
fall back to 1 minute. Orchestrators reading the value MUST tolerate the line
being absent — never error on it.

To change the interval after init:
1. Edit the line in `.aid/knowledge/STATE.md` to a new value (e.g. `2 minutes`)
2. The change takes effect on the next dispatched subagent

To disable heartbeat entirely (e.g., for noise reduction in slow-progress
work):
1. Set `**Heartbeat Interval:** 0` — dispatchers MUST NOT pass `HEARTBEAT_FILE`

## Orchestrator-side responsibilities (dispatcher)

Before dispatching a subagent that will run > 5 min:

1. **Read the heartbeat interval** from `.aid/knowledge/STATE.md`. If absent,
   default to `1 minute`. If `0`, skip heartbeat entirely (no parameters
   passed; subagent runs without self-reporting).

2. **Pre-create the heartbeat directory + file:**
   ```bash
   mkdir -p .aid/.heartbeat
   HEARTBEAT_FILE=".aid/.heartbeat/<agent-name>-$(date +%s).txt"
   touch "$HEARTBEAT_FILE"
   ```
   The `<agent-name>-<unix-timestamp>` name is unique per dispatch.

3. **Pass parameters to subagent.** Include in the dispatch prompt:
   ```
   HEARTBEAT_FILE=.aid/.heartbeat/<agent-name>-<ts>.txt
   HEARTBEAT_INTERVAL=Nm
   ```
   The subagent's AGENT.md tells it how to use these.

4. **Read on L2 timer fire.** When the L2 check-in timer fires, also read the
   heartbeat file and include its contents in the user-facing narration:
   ```
   ... <agent-name> still running (Xm elapsed of ~<eta>)
       [from heartbeat] state: <state> · progress: <progress> · activity: <activity>
   ```

5. **Clean up after completion.** On the `✓` or `✗` notification, delete the
   heartbeat file (or move to `.aid/.heartbeat/.archive/` if the dispatcher
   wants to preserve the trail).

## Subagent-side responsibilities (the dispatched agent)

If the dispatch prompt includes `HEARTBEAT_FILE=...`:

1. **Every N minutes of work** (where N = `HEARTBEAT_INTERVAL` value, default
   1 min if not specified), write a fresh status block to the heartbeat file:
   ```
   state: <current state name; e.g., GENERATE, REVIEW, FIX>
   progress: <e.g., "4/16 docs read", "3/13 tasks complete", "validating arch.md">
   eta-remaining: <e.g., "~5m", "unknown", "almost done">
   activity: <one-line description of what you are CURRENTLY doing>
   updated: <ISO-8601 timestamp; e.g., 2026-05-23T14:32:08Z>
   ```

2. **Overwrite, don't append.** Only the latest state matters. The orchestrator
   only reads the most recent contents.

3. **If you can't predict ETA-remaining**, use `unknown`. Never lie.

4. **The activity line should change between updates** — if you write the same
   activity line twice, you're probably stuck. The orchestrator may interpret
   identical consecutive updates as "subagent may be hung."

5. **If you finish before the next heartbeat interval**, no need to write a
   final heartbeat — your completion notification suffices.

6. **If `HEARTBEAT_FILE` is not in the dispatch prompt**, do nothing. Don't
   write speculatively. Don't error.

## Example heartbeat file

```
state: REVIEW
progress: 14/21 KB docs reviewed
eta-remaining: ~8m
activity: Reading data-model.md §3 (Mermaid dataflow); cross-checking against current code
updated: 2026-05-23T14:32:08Z
```

## File lifecycle

- **Created:** by dispatcher just before dispatch (empty file)
- **Updated:** by subagent every N minutes
- **Read:** by dispatcher when L2 timer fires
- **Deleted:** by dispatcher on completion notification
- **Location:** `.aid/.heartbeat/` (subdir under gitignored `.aid/`)
- **Stale-file cleanup:** dispatchers SHOULD delete `.aid/.heartbeat/*.txt`
  older than 24h at the START of any dispatch (covers crashed/abandoned
  subagents from prior sessions)

## Why this design

- **Pure file-based:** no event streams, no schemas requiring host-tool
  cooperation. Works on every host (Claude Code, Codex, Cursor).
- **Opt-in via parameter:** subagents that don't get `HEARTBEAT_FILE` do
  nothing — no behavior change for hosts/tools that haven't been updated.
- **Key:value text:** human-readable AND machine-parseable via grep/awk.
- **Overwrite-not-append:** unbounded file growth is not a concern.
- **1-minute default:** the user (work-003 PR #9 review) flagged the
  visibility gap; 1 minute gives the user a strong signal that the subagent
  is alive without overwhelming the narration. Users can override per-project
  via STATE.md.

## Pitfalls

- **Don't dispatch L3 without L2.** The heartbeat file alone gives no
  signal — only the L2 timer triggers a read. Pair them.
- **Don't reuse heartbeat filenames across dispatches.** Unique per dispatch
  (via unix timestamp suffix) avoids collision when the orchestrator
  dispatches multiple subagents in parallel.
- **Subagent must write key:value lines, not free prose.** The orchestrator
  parses by field name. Free prose breaks the grep/awk parsing.
- **Don't echo the heartbeat to the user on every read.** Surface it only
  when the L2 timer fires (i.e., once per check-in interval), not on every
  Read tool call.
