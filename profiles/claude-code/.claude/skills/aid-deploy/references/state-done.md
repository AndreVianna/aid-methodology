# State: DONE

Release complete. Emit the normalized Completed lifecycle state.

### Step 10: Emit Completed lifecycle state

Emit the normalized Completed lifecycle state (silent state-write only — no output, no gate):

```
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value none
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

This is the **M6 normalized-Completed emit**: it writes the authoritative `Lifecycle: Completed`
literal to `## Pipeline Status` so the dashboard reader can derive Completed from the normalized
block (not from legacy fallback signals). It mirrors the same silent-state-write pattern that
M4/M5 use for Running/Paused/Blocked — existing transition, no new prompt, no new gate,
no observable behavior change.

### Step 11: Summary

Print the release summary:
```
Release complete.
  Package: package-NNN ({version})
  Deliveries shipped: {count}
  Tasks shipped: {total count}
  All lifecycle state updated.
```

**Advance:** **HALT** (terminal — work is complete; user re-invokes /aid-deploy to start a new release).
