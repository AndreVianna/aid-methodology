# State: Q-AND-A

Q-AND-A drives EVERY pending question to a terminal answer. **Discovery is NOT finished while
any Q&A is unanswered** — there is no "optional", "low-impact", or "non-Required" question that
may be left Pending. The `Impact` field is informational (it only ORDERS the work); it does NOT
gate completion. This state is selected whenever `## Q&A (Pending)` in `.aid/knowledge/STATE.md`
has ANY entry with `**Status:** Pending`, regardless of grade or Impact.

Each pending question reaches a terminal state ONE of exactly two ways:
- **(A) Confirmed self-answer** — the answer is verifiable from the source/KB with certainty
  (NO assumptions, NO "likely"). The orchestrator answers it itself and marks it `Answered`.
- **(B) Defer to the user** — the answer needs human judgment/input, or cannot be confirmed from
  the artifacts. Ask the user (Step 2). Per the NO-ASSUMPTIONS prime directive: when in doubt,
  defer — never guess to clear a question.

### Step 1: Self-answer every question you can CONFIRM from source

Read `## Q&A (Pending)`. For EACH Pending entry, attempt a confirmed answer:

1. **Ground it.** Is the answer verifiable from the KB docs or the codebase **with certainty**,
   citable to a durable `file:symbol` anchor? If yes → write the grounded answer to `**Answer:**`,
   set `**Status:** Answered`, set `**Applied to:**` (the doc(s) the answer reflects/updates),
   and move on. A confirmed answer is one you can PROVE from an artifact.
2. **Cannot confirm?** Leave it Pending; it goes to Step 2 (the user).

Be honest about the line: *"the code clearly shows X"* (citable) is a confirmed answer;
*"X is probably the case"* is NOT — that defers to the user. Never mark `Answered` anything you
cannot prove from an artifact. Write each self-answer to STATE.md immediately.

### Step 2: Ask the user — one question at a time (the rest)

For every question still Pending after Step 1 (sorted High → Medium → Low):

```
Q{N}: [{Category}: {Impact}] {question text}
Context: {context}
Suggested: {your best READING of the evidence — explicitly NOT a decision}
[1] Not applicable / no — you confirm it does not apply
[2] Accept the suggestion
[3] Your answer: ___
```

**Wait for the user's response before asking the next question.**

### Step 3: Record the answer (every question ends Answered)

- **[1] Not applicable:** Set `**Status:** Answered`, `**Answer:** N/A — <user's reason>`.
- **[2] Accept:** Set `**Status:** Answered`, copy the suggestion to `**Answer:**`.
- **[3] Custom:** Set `**Status:** Answered`, record the user's text in `**Answer:**`.

Write to STATE.md immediately after each answer. `Skipped` is **not** a terminal state for
completion — a question the user sets aside is recorded as `Answered: N/A` with the reason, so
no question is left Pending.

### Step 4: Verify ZERO Pending, then continue

When the loop ends, CONFIRM `## Q&A (Pending)` has **zero** `**Status:** Pending` entries. If any
remain, they MUST be resolved (self-answered or asked) before leaving this state —
**APPROVAL is unreachable while any question is Pending.**

Print: `[Q&A] Complete — {self} self-answered (confirmed from source), {asked} answered by user, 0 Pending.`
Print: `[State: Q-AND-A] complete.`

**Advance:** **CHAIN** → [State: FIX] when any answer implies a doc change; otherwise chain toward
APPROVAL once zero Pending and grade >= minimum.
