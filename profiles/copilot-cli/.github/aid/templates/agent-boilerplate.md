## Heartbeat protocol

If your dispatcher passed `HEARTBEAT_FILE=...` + `HEARTBEAT_INTERVAL=Nm` in
your prompt, write a single-line status to that file every N minutes of work
using a shell command (NOT direct text — the timestamp MUST be shell-generated):

```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] <STATE> | <progress> | <activity> (~<eta-remaining>)" > "$HEARTBEAT_FILE"
```

Example output line:
```
[2026-05-23T20:35:05Z] REVIEW | 4/21 docs | Checking line-count drift (~12m remaining)
```

Use `>` (overwrite) not `>>` (append). The activity field should change
between updates — repeating the same activity twice signals "stuck" to the
orchestrator. Use `unknown` if you can't predict eta-remaining.

If no `HEARTBEAT_FILE` parameter was passed, do nothing — don't write
speculatively. See `.github/aid/templates/subagent-heartbeat-protocol.md` for
the full contract.

If your dispatcher ALSO passed `STOP_FILE=...` (opt-in, independent of
heartbeat), at that SAME tick also `stat` your own `.stop` file and re-read
the work `lifecycle`; either signal present/non-`Running` means halt at the
next safe checkpoint — finish your current atomic unit of work, then end
your turn — rather than starting further scoped work. Never create, delete,
or otherwise write to `STOP_FILE` yourself; only `write-control-signal.sh`
does. If no `STOP_FILE` was passed, do nothing. See
`.github/aid/templates/subagent-heartbeat-protocol.md` §Cooperative
stop-poll for the full contract.
