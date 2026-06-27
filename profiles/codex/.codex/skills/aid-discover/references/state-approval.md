# State: APPROVAL

APPROVAL presents the KB summary and asks the user to confirm it is ready for the Interview phase; it is selected when the KB meets minimum grade, **`## Q&A (Pending)` has ZERO Pending entries** (every question was self-answered from source or answered by the user in Q-AND-A — discovery is not complete while any question is unanswered), and it has not yet received user approval.

### Step 1: Present Summary

- Overall grade and minimum
- Total Q&A items (answered/skipped/pending)
- Fix cycles completed
- Remaining [MINOR] issues

### Step 2: Ask for User Approval

```
The Knowledge Base has reached the minimum grade of {minimum} (current: {grade}).
Please review .aid/knowledge/ and let us know if there is anything else to consider.
[1] Approved — KB is ready for the next phase
[2] Additional consideration: ___
```

### Step 3: Process Response

- **[1] Approved:** Add `**User Approved:** yes` to `.aid/knowledge/STATE.md`. Add Review History entry under `## Review History`.
  Print: `✅ Discovery complete. Grade: {grade}. KB approved and ready for the Interview phase.`
- **[2] Consideration:** Add as new Q&A entry in STATE.md `## Q&A (Pending)` (Category: `User Feedback`, Impact: `High`, Status: `Pending`).
  Print: `[Approval] Consideration recorded as Q{N}. Run /aid-discover again to address it.`

Print: `[State: APPROVAL] complete.`

**Advance:** **HALT** (user approval is the natural pause — once user approves, **CHAIN** → [State: DONE]).
