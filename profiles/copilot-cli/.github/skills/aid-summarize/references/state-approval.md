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

On approval: write `**User Approved:** yes` + timestamp to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`, transition to WRITEBACK.

On rejection: write `**User Approved:** no` to `## Knowledge Summary Status`, exit. `## Summarization History` is NOT updated.

On changes-needed: capture the user's notes in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Pending Changes`, transition to FIX.

Print: `[State: APPROVAL] complete.`

**Advance:** If user approved: **CHAIN** → [State: WRITEBACK] (continue inline). If user rejected: **HALT** (exit; no writeback). If user said "changes needed": **CHAIN** → [State: FIX] (continue inline).
