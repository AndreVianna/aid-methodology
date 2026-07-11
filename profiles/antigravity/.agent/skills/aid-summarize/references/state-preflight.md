# State: PREFLIGHT

PREFLIGHT is the synchronous gate that verifies all prerequisites before any summarization state runs; it is selected on every invocation before state detection proceeds.

Run `.agent/aid/scripts/summarize/summarize-preflight.sh` before any state. It verifies:

1. `.aid/knowledge/STATE.md` exists.
2. `**User Approved:** yes` is present in `.aid/knowledge/STATE.md`.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in Plan Mode (need write access).
5. Node.js >= 18 is available (required for `validate-visuals.mjs` visual-fidelity validation; the Mermaid network-fetch check was removed in D-012 / Change 7).
6. **Migrate legacy summary path (FR31 migration):** if `.aid/knowledge/knowledge-summary.html`
   exists and `.aid/knowledge/kb.html` does not, `mkdir -p .aid/knowledge` and `mv -n` the old
   file to the new path so STALE-CHECK sees the existing approved summary and skips regeneration.
   Best-effort -- a failure prints a note and does not block. Idempotent: if the new path already
   exists the step is a no-op.

If any check (1-5) fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files. Step 6 is best-effort only and never blocks.

Print: `[State: PREFLIGHT] complete.`

**Advance:** **CHAIN** → [State: STALE-CHECK] (continue inline).
