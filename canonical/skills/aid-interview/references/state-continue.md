# State: CONTINUE

Resume the conversational interview; STATE.md shows In Progress with at least one section still Pending or Partial.

This state covers both the opening question (when all sections are Pending after FIRST-RUN + TRIAGE)
and ongoing interview turns. If all sections are Pending, ask the opening question:

```
What are we building? Tell me the goal and what success looks like.
```

Otherwise: resume the conversational interview — assess sections, ask next question, update files.
The Interview Loop below applies.

Read STATE.md `## Interview Status` section status table to know where to continue.
Read REQUIREMENTS.md to know what's already captured.

---

**See `references/interview-loop.md`** for the loop body (shared between FIRST-RUN and CONTINUE).

**Advance:** Next state is `COMPLETION` — when all sections are Complete or N/A, print `Next: [State: COMPLETION] — run /aid-interview again` and exit.
