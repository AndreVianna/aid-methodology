# State: PREFLIGHT

PREFLIGHT is the synchronous gate that verifies all prerequisites before any summarization state runs; it is selected on every invocation before state detection proceeds.

Run `canonical/scripts/summarize/preflight.sh` before any state. It verifies:

1. `.aid/knowledge/STATE.md` exists.
2. `**User Approved:** yes` is present in `.aid/knowledge/STATE.md`.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in Plan Mode (need write access).
5. Network reachable to `registry.npmjs.org` (skipped if `--cdn-mermaid`).

If any check fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files.

Print: `[State: PREFLIGHT] complete.`

**Advance:** Next: [State: STALE-CHECK] — run /aid-summarize again
