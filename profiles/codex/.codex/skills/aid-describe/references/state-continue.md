# State: CONTINUE

Resume the conversational interview; STATE.md shows In Progress with at least one section still Pending or Partial.

## Entry: opener skip check

Before asking any question, read STATE.md for two signals:

- `**Opener:**` field in the `## Triage` block -- written by TRIAGE Step 6 when the D1
  opener already fired there.
- `## Escalation Carry` block -- written by the lite-to-full escalation procedure.

**If `## Escalation Carry` is present** -> follow the Escalation Carry section below. The
D1 opener is skipped; the carry block is surfaced for confirmation instead.

**If the `**Opener:**` field is present in `## Triage` (and `## Escalation Carry` is absent)**
-> the D1 opener already fired in TRIAGE. Seed the adaptive engine loop with the captured
opener answer as the first captured intent (vocabulary and calibration already read). Enter
the loop at STOP-CHECK / GAP-SELECTION (`references/elicitation-engine.md` "Adaptive Loop").
Do NOT re-emit the D1 opener.

**If NEITHER signal is present** (legacy direct-CONTINUE entry, pre-TRIAGE in-flight work,
or loopback with no triage record):

If all REQUIREMENTS.md sections are Pending, emit the D1 fixed opener
(`references/elicitation-engine.md` "D1 Fixed Opener -- The Only Fixed Turn"):

```
In a sentence or two -- what do you want to build or change, and what outcome
are you after?

Suggested: For example: "I want a small CLI tool that parses a config file and
           validates it against a schema, so that our team stops manually
           checking config files before each deploy."
Why: Describing the pieces in your own words gives me the working vocabulary
     for this project. I will use your terms, not impose mine -- so the more
     naturally you name the pieces, the more useful what follows will be.

[1] Use the form above and share yours
[2] Your answer: ___
```

Otherwise: resume the engine-driven interview -- assess sections, run the five-step
next-move selector, emit the next question, update files.
The Interview Loop below applies.

Read STATE.md `## Interview State` section status table to know where to continue.
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

**See `references/interview-loop.md`** for the loop body (shared between FIRST-RUN and CONTINUE),
which delegates next-move selection to `references/elicitation-engine.md`.

**Advance:** **CHAIN** → [State: COMPLETION] when all sections are Complete or N/A (continue inline).
