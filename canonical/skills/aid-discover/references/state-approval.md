# State: APPROVAL

APPROVAL presents the KB summary and asks the user to confirm it is ready for the Definition phase; it is selected when the KB meets minimum grade, **`## Q&A (Pending)` has ZERO Pending entries** (every question was self-answered from source or answered by the user in Q-AND-A — discovery is not complete while any question is unanswered), and it has not yet received user approval.

### Step 1: Present Summary

- Overall grade and minimum
- Total Q&A items (answered/skipped/pending)
- Fix cycles completed
- Remaining [MINOR] issues

### Step 2: Ask for User Approval

Show the summary above, then ask one approval question, in the protocol's form. It is an approval, so it
offers no skip and stays open until the user approves or declines. Record it first, as the SKILL's recording
paragraph says (Category: `Approval`, Impact: `High`), and record the answer when it comes.

```text
Knowledge base -- question 1 of 1 -- importance: high
The Knowledge Base has reached the minimum grade of {minimum} (current: {grade}). Do you approve it as ready for the next phase?
Why I ask: approval is what lets the work move on to the Definition phase.
My recommendation: approve it -- it meets the grade and no question is left pending.
  1. Approve (recommended)
  2. Not yet -- I have something more to consider (tell me what)
Or answer in your own words or ask me to explain. An approval cannot be skipped.
```

### Step 3: Process Response

- **Approve:** Add `**User Approved:** yes` to `.aid/knowledge/STATE.md` (the
  header-blockquote doc-set-level approval line; distinct from the KB summary's own
  `summary_approved` frontmatter scalar, set separately by `/aid-summarize`'s own APPROVAL state).
  Also set the KB status scalar in the run-state frontmatter (relocated from the
  old header-blockquote `**Status:**` line by task-001/004):
  ```bash
  bash .aid/runtime/scripts/summarize/writeback-state.sh --set kb_status Approved
  ```
  Add Review History entry under `## Review History`.
  Print: `✅ Discovery complete. Grade: {grade}. KB approved and ready for the Definition phase.`
- **Not yet (a consideration):** Add as new Q&A entry in STATE.md `## Q&A (Pending)` (Category: `User Feedback`, Impact: `High`, Status: `Pending`).
  Say in one plain line that the consideration is recorded as Q{N}. The pending Q&A is addressed by the Q-AND-A state of the next run.

The approval is a blocking question: this step pauses on it until the user answers.

**Advance:** **CHAIN** → [State: DONE] on approval; **HALT** on a consideration.
