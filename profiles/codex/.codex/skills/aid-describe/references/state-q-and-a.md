# State: Q-AND-A

STATE.md `## Cross-phase Q&A` has entries with `**Status:** Pending`; resolve them one at a time before continuing.

These may come from:
- Cross-reference analysis (State 6)
- Loopback from downstream phases (e.g., `/aid-specify` injected a question)
- Review findings

### Step 1: Load and Filter

Read `## Cross-phase Q&A` section of STATE.md. Collect all entries with `**Status:** Pending`.

**Before presenting each question, filter:**

1. **Already answered in REQUIREMENTS.md?** → Set status to `Answered`, fill answer,
   cite the section. Skip to next.
2. **Answered in KB?** → Set status to `Answered`, fill answer, cite KB document. Skip.
3. **Inferrable from context?** → Keep but ensure `**Suggested:**` answer exists.

After filtering, sort remaining Pending by impact: **High → Medium → Low**.

If zero remain: `[Q&A] All questions resolved from existing material.` and exit.

Print: `[Q&A] {N} questions for user input.`

### Step 2: Ask One at a Time

For each Pending question:

```
IQ{N}: [{Category}: {Impact}] {question text}

Context: {why this matters}
Source: {who injected this — /aid-specify feature-001, cross-reference, etc.}

Suggested: {suggestion if present}

[1] Skip / Not applicable
[2] Accept suggestion (only if Suggested exists)
[3] Your answer: ___
```

**Wait for the user's response before asking the next.**

### Step 3: Record

Based on the user's response, update the entry in STATE.md `## Cross-phase Q&A`:

- **[1] Skip:** Set `**Status:** Skipped`
- **[2] Accept suggestion:** Set `**Status:** Answered`, copy suggestion to `**Answer:**`
- **[3] Answer:** Set `**Status:** Answered`, record text in `**Answer:**`

**Write immediately.** Also update REQUIREMENTS.md with the answer content where relevant.

If the answer affects a feature that already exists, update that feature's SPEC.md too
and add a Change Log entry.

### Step 4: Continue Until Done

When all questions addressed:
`[Q&A] Complete. {answered} answered, {skipped} skipped.`

**Advance:** **CHAIN** → [State: CONTINUE] (continue inline).
