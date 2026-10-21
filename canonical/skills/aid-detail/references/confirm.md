# CONFIRM — Reopen Existing Tasks?

Existing task files found, and the task list was previously completed; ask whether to reopen it for review.

---

`tasks/` has files and were previously completed.

**Ask first**, as one question in the protocol's form, recorded first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Tasks --impact Low --context '<the question, as shown>' --suggested 'Leave it' --asked-by aid-detail --step CONFIRM` (it prints the question's id), and answered with `--answer --id <id>`:

```text
Tasks -- question 1 of 1 -- importance: low
The tasks for this work are already complete. Do you want to reopen them for review?
Why I ask: nothing is re-examined unless you ask, and a review may change tasks that are already written.
My recommendation: leave them as they are -- they are complete and graded.
  1. Leave them as they are (recommended)
  2. Reopen them for review (tell me if there is something specific to re-examine)
Or answer in your own words, or ask me to explain.
```

The question is blocking: this step pauses on it until the user answers.

A specific concern the user gives is recorded as context for the review.

**Advance:** **CHAIN** → [State: REVIEW] when the user confirms the reopen; **CHAIN** → [State: DONE] when the user keeps the task list as it is.
