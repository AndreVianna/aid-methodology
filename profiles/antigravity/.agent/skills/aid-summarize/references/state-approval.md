# State: APPROVAL

APPROVAL presents the graded summary to the user for final sign-off; it is selected when both Machine Grade and Human Grade meet the minimum, or when STALE-CHECK finds the HTML is current but not yet approved.

**Pre-condition:** Both Machine Grade AND Human Grade must already be computed and ≥ minimum. If Human Grade is `Pending`, refuse to enter APPROVAL — print: `❌ Cannot approve: Human Grade not yet scored. Run /aid-summarize again to enter MANUAL-CHECKLIST.`

Print summary in the standard format:

```
✅ kb.html ready for approval
   Path:           .aid/dashboard/kb.html
   Size:           {MB}
   Domain:         {domain value from .aid/knowledge/STATE.md ## Discovery Domain}
   Doc-set:        {N resolved} of {M total} docs covered
   Machine Grade:  {grade} ({score}/68) — script-verified AUTO_POOL (COV + D1/D2/L1/L2/H1/A1-A5/C1/C2/S2)
   Human Grade:    {grade} ({score}/30) — manual-checklist MANUAL_POOL (K1+K2+V1)
   Overall Grade:  {min of above} (target: {min})
   Theme:          light + dark, both pass WCAG AA
   Trigger:        {reason}

Preview:  python -m http.server 8000   # then open
          http://localhost:8000/.aid/dashboard/kb.html
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
bash .agent/aid/scripts/summarize/writeback-state.sh --set summary_approved yes --set last_summary "$(date -u +%Y-%m-%d)"
```
then transition to WRITEBACK.

On rejection:
```bash
bash .agent/aid/scripts/summarize/writeback-state.sh --set summary_approved no
```
exit. `## Summarization History` is NOT updated.

On changes-needed: capture the user's notes in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Pending Changes` (unaffected markdown-body content), transition to FIX.

Print: `[State: APPROVAL] complete.`

**Advance:** If user approved: **CHAIN** → [State: WRITEBACK] (continue inline). If user rejected: **HALT** (exit; no writeback). If user said "changes needed": **CHAIN** → [State: FIX] (continue inline).
