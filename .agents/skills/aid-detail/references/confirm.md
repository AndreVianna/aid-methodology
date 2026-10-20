# CONFIRM — Reopen Existing Tasks?

Existing task files found, and the task list was previously completed; ask whether to reopen it for review.

---

`tasks/` has files and were previously completed.

**Ask first:** _"Tasks for this work are already complete. Do you want to reopen for review?
Is there something specific you want to re-examine?"_

The question is blocking: this step pauses on it until the user answers.

A specific concern the user gives is recorded as context for the review.

**Advance:** **CHAIN** → [State: REVIEW] when the user confirms the reopen; **CHAIN** → [State: DONE] when the user keeps the task list as it is.
