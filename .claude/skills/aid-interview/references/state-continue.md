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

## Escalation Carry (post-escalation entry)

If entering CONTINUE after a lite→full escalation (i.e., `**Path:** escalated` in STATE.md
`## Triage`), check for an `## Escalation Carry` block in STATE.md **before** asking any
questions.

**If `## Escalation Carry` is present:**

1. Read the `### Captured Slot Values` sub-section.
2. Map carried slots to REQUIREMENTS.md sections (see `lite-to-full-escalation.md` § Step 7
   seed table). Those sections are already pre-seeded as `Partial`.
3. **Do NOT re-ask questions whose answers are already present in the carry block.**
   Instead, surface the carried values to the user for confirmation:

   ```
   I carried the following information from your lite-path session:

   - {slot-name}: {slot-value}
   - {slot-name}: {slot-value}
   ...

   These have been pre-filled into REQUIREMENTS.md. Shall I continue with the
   remaining sections, or would you like to adjust any of these?
   ```

4. If the user confirms → proceed to the first Pending section (not the already-Partial ones).
5. If the user wants to adjust → treat the adjustment as the answer to that section and
   update REQUIREMENTS.md, then continue.

**If `## Escalation Carry` is absent** → treat CONTINUE as a standard post-TRIAGE entry
(full-path interview from scratch, or loopback re-entry).

---

**See `references/interview-loop.md`** for the loop body (shared between FIRST-RUN and CONTINUE).

**Advance:** **CHAIN** → [State: COMPLETION] when all sections are Complete or N/A (continue inline).
