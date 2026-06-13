# State: STALE-CHECK

STALE-CHECK compares the KB review date against the last summary date to determine if regeneration is needed; it is selected immediately after PREFLIGHT passes.

Note: PREFLIGHT's FR31 migration step (step 6) relocates a pre-d009 `knowledge-summary.html`
to `.aid/dashboard/kb.html` before STALE-CHECK runs, so a just-migrated file is seen here
at the new path and treated as `CURRENT_APPROVED` when the summary is still current -- no
regeneration is needed.

Run `.claude/scripts/summarize/stale-check.sh`. It outputs one of:

- `STALE` — KB is newer than last summary (or first run). Continue to PROFILE/GENERATE.
- `CURRENT_APPROVED` — HTML is up-to-date and approved. Print:
  ```
  ✅ kb.html is already up-to-date with the current KB. Nothing to do.
  ```
  Exit cleanly.
- `CURRENT_UNAPPROVED` — HTML is up-to-date but not yet approved. Print:
  ```
  ℹ️  HTML is current with KB but pending your approval.
  ```
  Skip to APPROVAL.

If STALE: tell the user *why* it's stale:
```
ℹ️  KB was reviewed on {LAST_KB_CHANGE_DATE}, last summary was {LAST_SUMMARY_DATE}.
   Regenerating to match latest KB...
```

Print: `[State: STALE-CHECK] complete.`

**Advance:** **CHAIN** → [State: PROFILE] (continue inline). For DONE-IDEMPOTENT branch: **HALT**.
