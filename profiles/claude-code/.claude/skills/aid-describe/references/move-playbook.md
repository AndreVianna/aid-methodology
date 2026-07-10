# Move Playbook

The ten elicitation moves the seasoned-analyst engine draws on, plus the gap-type -> move
firing table that Step 3 of the next-move selector (see
`.claude/skills/aid-describe/references/elicitation-engine.md`) keys on.

**Audience.** Two readers at once: a junior maintainer who has never run an elicitation
workshop, and the engine driver that selects a move each turn.

**Grounding.** All ten moves trace to findings.md Section 5 RQ-B1 ("Elicitation moves --
the FR-2 seasoned-analyst playbook"), each sourced from one of the eight surveyed
elicitation / domain-discovery families.

**Cross-references.**
- `.claude/skills/aid-describe/references/elicitation-engine.md` -- the engine driver
  that runs the five-step next-move selector; the firing table below is its Step 3 input.
- `.claude/skills/aid-describe/references/advisor-stance.md` -- the NFR-7
  question-envelope template and expert-advisor behaviors; straw-man-first and
  mediate-then-defer & scribe (the delivery envelope) are fully specified there.

---

## Contents

- [Delivery Envelope -- Moves 1 and 10](#delivery-envelope----moves-1-and-10)
- [Gap-Response Moves -- Moves 2 through 9](#gap-response-moves----moves-2-through-9)
- [Gap-Type to Move Firing Table](#gap-type-to-move-firing-table)
- [Sequence Rule: Default, Not a Script](#sequence-rule-default-not-a-script)

---

## Delivery Envelope -- Moves 1 and 10

Moves 1 and 10 are **not** standalone gap responses. They are the **delivery envelope**
that every other move is emitted through: Move 1 opens the question; Move 10 closes the
decision and writes it to the record. Every turn uses both. The NFR-7 question-envelope
template (the `Suggested:` / `Why:` / `[1] Accept` block) is specified in
`.claude/skills/aid-describe/references/advisor-stance.md`.

---

### Move 1 -- Straw-man-first (Family 6: JAD)

**What it is.** Open every topic with a proposed answer and its rationale before asking
the user to accept, override, or correct. Never present a blank page or a bare question.
This is the delivery mechanism for NFR-7 (every question carries a concrete suggested
answer plus the rationale behind it).

**When it fires.** Every turn, unconditionally. Wraps the gap-response move chosen in
Step 3.

**Conversational pattern.**

```
[1-2 sentences of context, e.g. why this topic matters or what the KB suggests]

[the question]

Suggested: [a concrete proposed answer -- never blank, never "-"]
Why: [the rationale grounded in the user's prior words, the KB, or expert judgment]

[1] Accept this
[2] Not applicable
[3] Your answer: ___
```

The straw-man guarantees a suggestion always exists, even for genuinely open creative
questions (propose the best current straw-man and state the uncertainty in `Why:`).

---

### Move 10 -- Mediate-then-defer & scribe (Family 6: JAD)

**What it is.** When a decision is confirmed -- or when disagreement is surfaced -- the
analyst (a) mediates by naming the positions and proposing a resolution, (b) defers the
final call to the user, and (c) immediately writes the resolved point to the record.
Discipline lives in process transparency: every confirmed decision is recorded before the
conversation moves on.

**When it fires.** Every turn that closes a decision; with particular emphasis on any turn
where disagreement is present. Closes the envelope.

**Conversational pattern.**

```
[On disagreement:] You've expressed [position A] and [concern B]. My recommendation is
[proposed resolution] because [rationale] -- but this is your call.

[User decides.]

Got it: recording "[decision]" in [REQUIREMENTS.md section / STATE.md Cross-phase Q&A].
```

If the user accepts the straw-man suggestion, the analyst records the accepted answer
immediately (one confirmed decision at a time -- NFR-1 process discipline).

---

## Gap-Response Moves -- Moves 2 through 9

These eight moves are the **gap-specific** responses. The engine selects one based on the
gap type (see the firing table below). Each is still delivered through the Move 1 / Move 10
envelope.

---

### Move 2 -- Term-capture + disambiguation (Family 1: DDD/UL)

**What it is.** When the user introduces a noun or verb, the analyst immediately pins one
canonical label for it, defines it as the user uses it (not a generic dictionary meaning),
records its relationships to other terms, and checks it against earlier terms to prevent
silent synonyms.

**When it fires.** Gap type: **undefined or ambiguous term** the user has used.

**Conversational pattern.**

```
You used the term "[X]." By that do you mean [proposed definition, as the user seems to
use it]? Is this the same concept as "[Y]" you mentioned earlier, or a different one?

Suggested: [proposed canonical label and one-sentence definition]
Why: keeping one label per concept prevents the "same thing, two names" confusion that
     breaks requirements downstream.
```

**Verbatim-wording rule (G3).** The canonical label proposed here MUST use or closely echo
the user's own term -- not a paraphrase from the analyst's vocabulary. The D1 opener
commits the analyst to "I will use your terms, not impose mine"; Move 2 is where that
promise is honoured in practice. If the user's term is unclear or would benefit from a
cleaner label, the analyst proposes the alternative EXPLICITLY with rationale (for example:
"You said 'job runner' -- I'd suggest calling this 'task executor' because it aligns with
the existing codebase naming; does that work for you?"). Silent substitution is not
permitted; a rename requires the user's explicit confirmation.

---

### Move 3 -- Boundary-elicitation (Family 2: Context Modeling)

**What it is.** Name where one model or part stops and another begins, then name the
relationship across that boundary. Stays at sketch altitude -- not a full design diagram,
just "what we build" vs "what we integrate with" and how they talk.

**When it fires.** Gap type: **unnamed boundary or relationship** in the architecture.

**Conversational pattern.**

```
It sounds like [Part A] and [Part B] are separate things. Where exactly does [Part A] end?

Suggested: [Part A] handles [proposed scope]; [Part B] handles [proposed scope]; they
           interact via [proposed mechanism].
Why: naming boundaries and relationships now prevents the "whose responsibility is it"
     argument later.
```

---

### Move 4 -- Event-first, propose-timeline-back (Family 3: Event Storming)

**What it is.** Ask the user to walk through what happens step by step, then propose an
ordered sequence of events back to them and probe for the gaps between steps.

**When it fires.** Gap type: **unknown behavior or flow** in a process-heavy domain.

**Conversational pattern.**

```
Walk me through what happens when [trigger / starting point]. What is the first thing
that occurs?

[After hearing the answer:]

So the sequence looks like: [proposed ordered event timeline]. Does that match? What
happens between [step N] and [step N+1]?

Suggested: [proposed timeline]
Why: events reveal hidden states and decision points that noun-first descriptions miss.
```

---

### Move 5 -- Backbone-first + walking-skeleton (Family 4: User-Story Mapping)

**What it is.** Ask the user to outline all the high-level activities in the user journey
from start to finish (the backbone), then ask which subset is essential for the first
version (the walking skeleton -- the thinnest possible end-to-end slice). This is the
primary full-path scope-sizing move (full-vs-lite routing has left `aid-describe`
entirely -- work-001-lite-aid-skills feature-013; this move now sizes the backbone for
the full-path interview itself, not a path decision).

**When it fires.** Gap type: **unknown scope size** -- the backbone/skeleton sizing
signal for the full-path interview.

**Conversational pattern.**

```
What does a user do with [this thing] from the very beginning to the very end? Let's
list all the activities in order.

[Backbone elicited.]

Which of those activities are absolutely necessary for the first working version -- the
simplest end-to-end slice that would still be genuinely useful?

Suggested: [proposed skeleton -- the activities that seem essential vs deferrable]
Why: a small end-to-end slice suggests a lite/short path; a sprawling multi-step backbone
     suggests a full path.
```

---

### Move 6 -- Rationale + testability probe (Family 5: Volere)

**What it is.** For any stated requirement, ask why it matters and how you would know
when it is satisfied. Surfaces the fit criterion -- the concrete success check that
distinguishes "done" from "close enough."

**When it fires.** Gap type: **missing fit criterion** or requirement with no testability.

**Conversational pattern.**

```
Why does [requirement] matter for this project specifically?

And how will you know when it is satisfied -- what is a concrete check you could run
to confirm it?

Suggested: [proposed fit criterion grounded in what the user has said]
Why: a requirement with no measurable fit criterion cannot be reliably accepted or
     rejected.
```

---

### Move 7 -- Bounded why-probe (Family 7: Five-Whys / Laddering)

**What it is.** Climb 2-3 levels of "why," propose the inferred terminal motive back to
the user, and stop when the motive is confirmed. NEVER the rote "five whys" ritual -- the
"exactly five whys" count is arbitrary and documented as shallow (Toyota's own Minoura;
findings.md Section 2). The move stops at the terminal value, not at a preset depth.

**When it fires.** Gap type: **missing "why"** behind a stated intent.

**Conversational pattern.**

```
You said you want [X]. Why is that important for this project?

[Hear first why.]

And underlying that -- is the real driver [proposed inferred motive]?

Suggested: [proposed terminal motive / decision rationale]
Why: knowing the real driver lets us propose the right design decision and record it in
     decisions.md rather than just recording what was asked for.

[Stop here if the motive is confirmed. Do NOT continue asking "why" mechanically.]
```

---

### Move 8 -- Concrete-example probe (Family 8: Example Mapping)

**What it is.** Ask for a specific concrete example to test whether a term or claim is
well-defined or under-pinned. A term the user cannot illustrate with an example is not
yet load-bearing in the concept-spine.

**When it fires.** Gap type: **a claim or term asserted with no concrete example** (a
"Partial" gap -- the term exists but has no example to anchor it).

**Conversational pattern.**

```
Can you give me a specific example of [term / claim] in use? Walk me through a real
or imagined scenario where this applies.

Suggested: [proposed example inferred from the user's prior description]
Why: if [term] cannot be illustrated concretely, it is probably under-defined and will
     cause confusion downstream.
```

---

### Move 9 -- Capture-and-defer (red-card) (Family 8: Example Mapping)

**What it is.** When a point cannot be settled in the current conversation -- it needs
more research, a third party, or is genuinely unresolvable now -- record it as an open
question and move on. This is the "red card" from Example Mapping: flag it, do not block.
The sink is `STATE.md ## Cross-phase Q&A` (the open-question register the engine driver
maintains).

**When it fires.** Gap type: **a point that cannot be settled now**.

**Conversational pattern.**

```
This one we cannot resolve right now -- [brief reason: needs more research / needs
decision from [party] / genuinely unclear at this stage].

I will record it in STATE.md ## Cross-phase Q&A as an open question with its downstream
risk noted, and we will revisit it.

[Records: open question text, who needs to resolve it, downstream impact on the work.]

Let us continue with what we can settle.
```

The capture-and-defer move never blocks the engine loop. The loop re-reads the gap
inventory on the next turn and picks the next highest-priority open gap.

---

## Gap-Type to Move Firing Table

Step 3 of the next-move selector in
`.claude/skills/aid-describe/references/elicitation-engine.md` reads this table. The
selected gap's type determines the move drawn from the playbook. The delivery envelope
(Moves 1 and 10) always wraps the chosen gap-response move.

| Gap type | Playbook move | From (family) |
|----------|---------------|---------------|
| Undefined or ambiguous term the user used | Move 2: Term-capture + disambiguation | DDD/UL (1) |
| Unnamed boundary or relationship in the architecture | Move 3: Boundary-elicitation | Context Modeling (2) |
| Unknown behavior or flow in a process-heavy domain | Move 4: Event-first, propose-timeline-back | Event Storming (3) |
| Unknown scope size (backbone size, sprawl) | Move 5: Backbone-first + walking-skeleton | User-Story Mapping (4) |
| Missing fit criterion or testability of a requirement | Move 6: Rationale + testability probe | Volere (5) |
| Missing "why" behind a stated intent | Move 7: Bounded why-probe -- climb 2-3 whys, propose the inferred motive back, stop at the terminal value; NEVER the rote "five whys" | Five-Whys / Laddering (7) |
| A claim or term asserted with no concrete example | Move 8: Concrete-example probe | Example Mapping (8) |
| A point that cannot be settled now | Move 9: Capture-and-defer (red-card) -- record to STATE.md ## Cross-phase Q&A and move on | Example Mapping (8) |
| Disagreement surfaced, or any turn at all | Delivery envelope: Move 1 (straw-man-first) + Move 10 (mediate-then-defer & scribe) -- these always wrap the chosen gap-response move; see advisor-stance.md | JAD (6) |

---

## Sequence Rule: Default, Not a Script

The numbered sequence in findings.md Section 5 RQ-B1 (straw-man-first -> term-capture ->
boundary-elicitation -> event-first -> backbone-first -> rationale probe -> why-probe ->
example probe -> capture-and-defer -> mediate-then-defer) is a **recommended default**,
not a fixed script. The engine driver does not march through the moves in order.

Each turn, the engine:

1. Checks the stop condition (is the work minimal-but-sufficient?).
2. Selects the highest-priority open gap from the gap inventory.
3. Reads this table to pick the move for that gap type.
4. Shapes the move depth via calibration state.
5. Wraps the move in the delivery envelope and emits.

The sequence emerges from the gap inventory (supplied by the consumer: REQUIREMENTS
sections or the Rec-A seed doc-set), not from a preset move order. NFR-1
("latitude in dialogue, discipline in process") is the reason: the analyst follows the
conversation, not a questionnaire.

See `.claude/skills/aid-describe/references/elicitation-engine.md` for the full
five-step next-move selector and the stop check.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | task-011 (IMPLEMENT) | Initial authoring: ten moves + gap-type firing table, grounded in findings.md RQ-B1 and feature-002 SPEC. |
| 1.1 | 2026-06-27 | work-001-aid-describe-improvements delivery-003 task-041 | G3 verbatim-wording rule added to Move 2: canonical label must echo the user's term; explicit rename with rationale required; silent substitution not permitted |
