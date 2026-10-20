# State: Q-AND-A

Q-AND-A drives EVERY pending question to an answer or a skip. **Discovery is NOT finished while
any Q&A is Pending** — there is no "optional" or "low-impact" question that
may be left Pending. The `Impact` field is informational (it only ORDERS the work); it does NOT
gate completion. This state is selected whenever `## Q&A (Pending)` in `.aid/knowledge/STATE.md`
has ANY entry with `**Status:** Pending`, regardless of grade or Impact.

Each pending question is dealt with in ONE of exactly two ways:
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

For every question still Pending after Step 1, and each `Skipped` entry left by an earlier run (it
stays open and is offered again), sorted High → Medium → Low, group them by Category (3 to 5 to a group,
most important first) and ask each one, one per message, in the protocol's question form. The entry is
already `Pending` in `## Q&A (Pending)`, which is where it was recorded before it was shown.

```text
{Category} -- question {n} of {m} -- importance: {high|medium|low}
{the question text, short and plain}
Why I ask: {the entry's Context, in one short reason}
My recommendation: {your best READING of the evidence, and why -- explicitly NOT a decision}
  1. {the recommended answer} (recommended)
  2. {another valid answer, only when there is one}
Or answer in your own words, ask me to explain, or skip this question.
```

Offer "not applicable" only when it is a valid answer to that question. **Wait for the user's response
before asking the next question.** Offer a break after each group.

### Step 3: Record the answer

- **Answered** (the suggestion accepted, or the user's own words, or "not applicable" with the reason):
  set `**Status:** Answered`, record the answer in `**Answer:**` (`N/A — <user's reason>` for not
  applicable), and set `**Applied to:**`.
- **Skipped:** set `**Status:** Skipped`. A skipped question is **not** closed: it stays open and is offered
  again later, to the same user or to another one. It does not block APPROVAL; APPROVAL's summary lists it.

Write to STATE.md immediately after each answer.

### Step 4: Verify ZERO Pending, then continue

When the loop ends, CONFIRM `## Q&A (Pending)` has **zero** `**Status:** Pending` entries. If any
remain, they MUST be resolved (self-answered or asked) before leaving this state —
**APPROVAL is unreachable while any question is Pending** (a `Skipped` one stays open but does not block it).

Print: `{self} questions self-answered (confirmed from source), {asked} answered by you, {skipped} skipped, 0 pending.`

The questions in Step 2 pause this step until they are answered; with no question put to the user, the step continues at once.

**Advance:** **CHAIN** → [State: FIX] when any answer implies a doc change; **CHAIN** → [State: APPROVAL] when no answer does, zero questions are Pending and the grade is at least the minimum.
