# State: Q-AND-A

Q-AND-A resolves pending questions with the user before attempting automated fixes; it is selected when the grade is below minimum and `## Q&A (Pending)` has Pending entries, or when any Pending entry has `Impact: Required`.

### Step 1: Load and Filter Questions

Read `## Q&A (Pending)` from `.aid/knowledge/STATE.md`. For each Pending entry:
1. **Check KB** — answer already in another KB doc? → Auto-answer, set `Answered`
2. **Check duplicates** — already answered in a previous cycle? → Skip
3. **Inferrable?** — ensure `**Suggested:**` is populated if possible

Sort remaining: **High → Medium → Low**.
Print: `[Q&A] {N} questions for user input. Asking one at a time...`

### Step 2: Ask One Question at a Time

```
Q{N}: [{Category}: {Impact}] {question text}
Context: {context}
Suggested: {suggested answer, if present}
[1] Skip / Not applicable
[2] Accept suggestion (only if Suggested exists)
[3] Your answer: ___
```

**Wait for user response before asking next question.**

### Step 3: Record the Answer

- **[1] Skip:** Set `**Status:** Skipped`
- **[2] Accept:** Set `**Status:** Answered`, copy suggested to `**Answer:**`
- **[3] Custom:** Set `**Status:** Answered`, record text in `**Answer:**`

**Write to `.aid/knowledge/STATE.md` immediately after each answer.**

### Step 4: Continue or Exit

Repeat for all Pending. When done:
Print: `[Q&A] Complete. {answered} answered, {skipped} skipped. Run /aid-discover again to fix.`

Print: `[State: Q-AND-A] complete.`

**Advance:** Next: [State: FIX] — run /aid-discover again
