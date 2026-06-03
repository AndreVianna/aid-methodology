# Subagent Heartbeat Protocol

When an AID skill (an "orchestrator") dispatches a subagent, the orchestrator
MUST pass `HEARTBEAT_FILE=...` + `HEARTBEAT_INTERVAL=Nm` parameters to every
subagent dispatch (unless heartbeat is explicitly disabled via
`traceability.heartbeat_interval: 0` in `.aid/settings.yml`, resolved by
`bash canonical/scripts/config/read-setting.sh --path traceability.heartbeat_interval`).
The subagent MUST
write periodic progress notes to that file. The orchestrator reads the file
when its L2 check-in timer fires (see `long-wait-protocol.md`) to surface real
progress rather than just elapsed time. Heartbeat is unconditional: never gate
on ETA threshold or task type.

**Exempt (shell-less) agents.** The heartbeat requires a shell-generated
timestamp, so an agent without the `Bash` tool cannot comply. The only such
agent is **`simple-formatter`** (`Read, Write, Edit` — intentionally shell-less;
short-lived single template fill). Orchestrators MUST NOT pass `HEARTBEAT_FILE` /
`HEARTBEAT_INTERVAL` to an exempt agent, and the agent ignores them if passed.
Every other heartbeat-enabled agent grants `Bash`.

This protocol is the L3 layer of the subagent-visibility scheme. L1 = honest
ETAs (`rough-time-hints.md`); L2 = orchestrator check-in timers
(`long-wait-protocol.md`); L3 = this doc (subagent self-reporting).

## Configuration

The heartbeat interval is configured in `.aid/settings.yml` under
`traceability.heartbeat_interval` (integer minutes). Default value = **1 minute**.

`aid-config` writes this key during initial scaffolding (asking the user if they
want to override the default). If `.aid/settings.yml` is absent or the key
is missing, dispatchers fall back to 1 minute via `read-setting.sh --default 1`.
Orchestrators reading the value MUST tolerate the file/key being absent —
never error on it.

To change the interval after init:
1. Run `/aid-config` (recommended), OR edit `.aid/settings.yml` directly to
   set `traceability.heartbeat_interval: <N>` (integer minutes)
2. The change takes effect on the next dispatched subagent

To disable heartbeat entirely (e.g., for noise reduction in slow-progress
work):
1. Set `traceability.heartbeat_interval: 0` in `.aid/settings.yml` —
   dispatchers MUST NOT pass `HEARTBEAT_FILE`

## Orchestrator-side responsibilities (dispatcher)

Before dispatching any subagent (always, regardless of ETA):

1. **Read the heartbeat interval** via
   `bash canonical/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`.
   If `0`, skip heartbeat entirely (no parameters passed; subagent runs without
   self-reporting).

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
   1 min if not specified), write a single-line status to the heartbeat file
   using a shell command (NOT direct LLM text — the timestamp MUST be shell-generated):
   ```bash
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] <STATE> | <progress> | <activity> (~<eta-remaining>)" > "$HEARTBEAT_FILE"
   ```

   Field meanings:
   - `<STATE>`: current state name; e.g., `GENERATE`, `REVIEW`, `FIX`
   - `<progress>`: e.g., `4/16 docs read`, `3/13 tasks complete`, `validating arch.md`
   - `<activity>`: one-line description of what you are CURRENTLY doing
   - `<eta-remaining>`: e.g., `~5m`, `unknown`, `almost done`

   Example output line:
   ```
   [2026-05-23T20:35:05Z] REVIEW | 4/21 docs | Checking line-count drift across module-map/architecture (~12m remaining)
   ```

2. **Use `> "$HEARTBEAT_FILE"` (overwrite), NOT `>> "$HEARTBEAT_FILE"` (append).**
   Only the latest state matters. The orchestrator reads with `cat` and expects
   a single line.

3. **The timestamp MUST come from `$(date -u +%Y-%m-%dT%H:%M:%SZ)`, not from
   your own text generation.** LLM-generated timestamps are placeholder-prone
   (e.g., `2026-05-23T00:00:00Z` midnight). The shell substitution guarantees a
   real, current UTC timestamp.

4. **If you can't predict eta-remaining**, use `unknown`. Never lie.

5. **The activity field should change between updates** — if you write the
   same activity twice in a row, you're probably stuck. The orchestrator may
   interpret identical consecutive updates as "subagent may be hung."

6. **If you finish before the next heartbeat interval**, no need to write a
   final heartbeat — your completion notification suffices.

7. **If `HEARTBEAT_FILE` is not in the dispatch prompt**, do nothing. Don't
   write speculatively. Don't error.

## Example heartbeat file

A single line, written by `echo "[$(date -u +...)] ..." > "$HEARTBEAT_FILE"`:

```
[2026-05-23T14:32:08Z] REVIEW | 14/21 KB docs reviewed | Reading schemas.md §3 (Mermaid dataflow); cross-checking against current code (~8m remaining)
```

Easy to scan; easy to parse (`head -1`, `awk -F'|'`).

## File lifecycle

- **Created:** by dispatcher just before dispatch (empty file)
- **Updated:** by subagent every N minutes
- **Read:** by dispatcher when L2 timer fires
- **Deleted:** by dispatcher on completion notification
- **Location:** `.aid/.heartbeat/` (always gitignored — see below)
- **Gitignore requirement:** because heartbeat files are ephemeral runtime
  artifacts, `.aid/.heartbeat/` MUST be present in the project's `.gitignore`
  regardless of whether `.aid/` itself is tracked. `/aid-config` INIT Step 7
  offers to append the managed block (Option 1 = explicit per-line entries;
  Option 2 = `.aid/` blanket; Option 3 = user manages manually). If the user
  picks Option 3, the dispatcher SHOULD ensure this exclusion exists before
  its first dispatch — and aid-config warns about this on Option 3 selection.
  For projects initialized before this protocol existed, run `/aid-config`
  again to surface the prompt.
- **Stale-file cleanup:** dispatchers SHOULD delete `.aid/.heartbeat/*.txt`
  older than 24h at the START of any dispatch (covers crashed/abandoned
  subagents from prior sessions)

## Why this design

- **Pure file-based:** no event streams, no schemas requiring host-tool
  cooperation. Works on every host (Claude Code, Codex, Cursor).
- **Opt-in via parameter:** subagents that don't get `HEARTBEAT_FILE` do
  nothing — no behavior change for hosts/tools that haven't been updated.
- **Single-line text:** human-readable AND machine-parseable via `head -1` / `awk -F'|'`. Compact enough to fit one terminal line.
- **Overwrite-not-append:** unbounded file growth is not a concern.
- **1-minute default:** the user (work-003 PR #9 review) flagged the
  visibility gap; 1 minute gives the user a strong signal that the subagent
  is alive without overwhelming the narration. Users can override per-project
  via `.aid/settings.yml` `traceability.heartbeat_interval` (set with
  `/aid-config`).

## Pitfalls

- **Don't dispatch L3 without L2.** The heartbeat file alone gives no
  signal — only the L2 timer triggers a read. Pair them.
- **Don't reuse heartbeat filenames across dispatches.** Unique per dispatch
  (via unix timestamp suffix) avoids collision when the orchestrator
  dispatches multiple subagents in parallel.
- **Subagent must use the single-line format with `|` delimiters.** Free
  prose breaks `awk -F'|'` parsing. Multi-line breaks `head -1`.
- **Don't echo the heartbeat to the user on every read.** Surface it only
  when the L2 timer fires (i.e., once per check-in interval), not on every
  Read tool call.
- **Always use `$(date -u +%Y-%m-%dT%H:%M:%SZ)` for the timestamp**, never
  hand-written ISO strings. LLMs often write plausible-looking placeholders
  (e.g., `2026-05-23T00:00:00Z` midnight) when asked to generate timestamps
  directly. The shell substitution side-steps this entirely.
