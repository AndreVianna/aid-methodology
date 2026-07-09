# State: CONTINUE

Resume the conversational interview; STATE.md shows In Progress with at least one section still Pending or Partial. This is the **only** entry point into the full-path interview -- `FIRST-RUN` and `Q-AND-A` both advance directly here (there is no TRIAGE state to route through first).

## Entry: opener fire-once check

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

Read the answer, then enter the adaptive loop at STOP-CHECK / GAP-SELECTION
(`references/elicitation-engine.md` "Adaptive Loop").

**Otherwise** (at least one section is already Partial or Complete -- the opener already
fired on an earlier CONTINUE entry, in this session or a prior one): resume the
engine-driven interview directly -- assess sections, run the five-step next-move selector,
emit the next question, update files. Do NOT re-emit the D1 opener; "all sections Pending"
is itself the fire-once signal, so no separate opener-captured field needs to be tracked.
The Interview Loop below applies.

Read STATE.md `## Interview State` section status table to know where to continue.
Read REQUIREMENTS.md to know what's already captured.

---

**See `references/interview-loop.md`** for the loop body (shared between FIRST-RUN and CONTINUE),
which delegates next-move selection to `references/elicitation-engine.md`.

**Advance:** **CHAIN** → [State: COMPLETION] when all sections are Complete or N/A (continue inline).
