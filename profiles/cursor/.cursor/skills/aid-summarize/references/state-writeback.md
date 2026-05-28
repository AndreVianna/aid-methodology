# State: WRITEBACK

WRITEBACK atomically records the approved summarization entry in STATE.md Summarization History; it is selected after the user approves in APPROVAL.

▶ writeback-state.sh starting (~5 s)
Run `.cursor/scripts/summarize/writeback-state.sh`. It atomically:

1. Acquires `.aid/knowledge/.state.lock` (file rename sentinel, 5s timeout).
2. Reads `.aid/knowledge/STATE.md`.
3. Locates `## Review History`. If `## Summarization History` does not exist, inserts
   it immediately after the Review History table.
4. Computes next `#` (last entry + 1, or 1 if first).
5. Appends a new row to `## Summarization History`:
   - **#:** {next}
   - **Date:** {YYYY-MM-DD}
   - **Grade:** {final}
   - **Profile:** {profile}
   - **Mermaid:** {version}
   - **Output:** `knowledge-summary.html ({size})`
   - **Notes:** {one-liner — "Initial generation" or "Regenerated after KB review cycle N (date)"}
6. Writes back, preserving everything else byte-for-byte.
7. Releases lock.

✓ writeback done (record actual time) — or ✗ writeback failed: {reason}
On failure (lock timeout, write error): mark `**Writeback Status:** failed` in
`.aid/knowledge/STATE.md` `## Knowledge Summary Status`, instruct the user to manually add the entry, exit non-zero.

On success: mark `**Writeback Status:** ok` in `## Knowledge Summary Status`, transition to DONE.

Print: `[State: WRITEBACK] complete.`

**Advance:** **CHAIN** → [State: DONE] (continue inline).
