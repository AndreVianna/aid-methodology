# State: APPROVAL

APPROVAL presents the graded summary to the user for final sign-off; it is selected when the grade meets the minimum, or when STALE-CHECK finds the HTML is current but not yet approved.

**Pre-condition:** The grade must already be computed and ≥ minimum, AND the human checklist must have
been completed. **The checklist gates by the EXISTENCE of its artifact, not by a score** — that is the
whole substance of the change, so make it a file test rather than a judgement:

```bash
test -f .aid/.temp/summarize/manual-checklist.json
```

Absent → refuse to enter APPROVAL and print:
`❌ Cannot approve: the human checklist has not been completed (.aid/.temp/summarize/manual-checklist.json absent). Run /aid-summarize again to enter MANUAL-CHECKLIST.`

The `Checklist` field in `.aid/knowledge/STATE.md § Knowledge Summary Status` takes exactly two forms, and
GENERATE, `discovery-state-template.md` and this state all carry the same two: **`Not run`** (as
GENERATE initialises it) or **`Completed YYYY-MM-DD`**. Nothing else -- an explanatory parenthetical
inside the value, or a `Completed` with no date, is a third form that a reader cannot parse. It is an agent-written body line, exactly like the two retired grade
lines it replaces — `summarize/writeback-state.sh --set` owns only the five frontmatter scalars
(`kb_status`, `kb_grade`, `last_kb_review`, `summary_approved`, `last_summary`) and deliberately not
this one.

Print summary in the standard format:

```
✅ kb.html ready for approval
   Path:           .aid/knowledge/kb.html
   Size:           {MB}
   Domain:         {domain value from .aid/knowledge/STATE.md ## Discovery Domain}
   Doc-set:        {N resolved} of {M total} docs covered
   Grade:          {grade} (target: {min}) — grade.sh over the review ledger
   Findings:       {n} ({worst severity} worst)
   Checklist:      Completed {YYYY-MM-DD} — the human visual check is recorded, not scored
   Theme:          light + dark, both pass WCAG AA
   Trigger:        {reason}

Preview:  python -m http.server 8000   # then open
          http://localhost:8000/.aid/knowledge/kb.html
   Or open the file directly in your browser.
```

Use `AskUserQuestion` to ask:
> Approve this summary?
> - **Approve** — record approval and update `.aid/knowledge/STATE.md` `## Summarization History`
> - **Reject** — exit without recording
> - **Changes needed** — describe what to change, transition to FIX

The summary's approval scalar (`summary_approved`) and its last-run date (`last_summary`)
live in `.aid/knowledge/STATE.md`'s leading YAML frontmatter block (relocated by
work-003-state-schema task-001/004 from the old `## Knowledge Summary Status` ad hoc
`**User Approved:** yes (date)` bold line -- the exact table-row-vs-bold-line misparse
this delivery exists to fix). Write via the surgical frontmatter helper (never hand-edit
the bold line again):

On approval:
```bash
bash .cursor/aid/scripts/summarize/writeback-state.sh --set summary_approved yes --set last_summary "$(date -u +%Y-%m-%d)"
```
then transition to WRITEBACK.

On rejection:
```bash
bash .cursor/aid/scripts/summarize/writeback-state.sh --set summary_approved no
```
exit. `## Summarization History` is NOT updated.

On changes-needed: capture the user's notes in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Pending Changes` (unaffected markdown-body content), transition to FIX.

Print: `[State: APPROVAL] complete.`

**Advance:** If user approved: **CHAIN** → [State: WRITEBACK] (continue inline). If user rejected: **HALT** (exit; no writeback). If user said "changes needed": **CHAIN** → [State: FIX] (continue inline).
