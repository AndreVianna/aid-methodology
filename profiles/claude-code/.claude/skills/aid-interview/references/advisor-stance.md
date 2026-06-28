# Advisor Stance and Question-Envelope Contract

Two inseparable engine behaviors: every question is wrapped in the NFR-7
question envelope (AC-3), and every user move is handled with the
expert-advisor stance (NFR-1 / AC-4). This doc defines both and is consumed
by the engine driver at `references/elicitation-engine.md`.

---

## Contents

- [NFR-7 Question-Envelope Contract](#nfr-7-question-envelope-contract)
  - [The Envelope Template](#the-envelope-template)
  - [Enforcement 1: Structural](#enforcement-1-structural)
  - [Enforcement 2: Self-Check (Pre-Emit Gate)](#enforcement-2-self-check-pre-emit-gate)
  - [D1 Opener: NFR-7-Compliant by Construction](#d1-opener-nfr-7-compliant-by-construction)
- [Expert-Advisor Stance](#expert-advisor-stance)
  - [The Five User-Move Handlers](#the-five-user-move-handlers)
  - [Discipline Lives in Process, Not Restriction](#discipline-lives-in-process-not-restriction)
- [Change Log](#change-log)

---

## NFR-7 Question-Envelope Contract

**Invariant: no bare, suggestion-less question is ever emitted.**

Every question the engine asks in Step 5 of the next-move loop is wrapped in
a fixed envelope. This is the formalization of the existing suggested-answer
pattern in `references/interview-strategies.md`, extended with a mandatory
rationale field.

### The Envelope Template

```
{1-2 sentences of context, optionally [From: .aid/knowledge/<doc>.md] when KB-inferred}

{the question}

Suggested: {a concrete proposed answer -- never blank, never "-"}
Why: {the rationale -- why this is suggested, grounded in the user's prior words, the KB, or
     the analyst's expert judgment}

[1] Accept this
[2] Not applicable
[3] Your answer: ___
```

All five parts are non-optional. `Suggested:` and `Why:` accept no
placeholder, dash, or empty value. A turn that omits or blanks either field
is a malformed emission.

### Enforcement 1: Structural

The engine driver (`references/elicitation-engine.md`) emits questions ONLY
through this envelope. There is no secondary emission path. Because the
template requires `Suggested:` and `Why:`, a bare question -- one without
both fields -- is structurally unconstructable within the engine.

This is a prose-execution invariant, not a machine check. The reviewer
confirms the envelope is the only emission path when reviewing the engine
driver.

### Enforcement 2: Self-Check (Pre-Emit Gate)

Before the engine emits a question, it verifies two conditions:

1. `Suggested:` is present and concrete (not blank, not "-", not a
   placeholder).
2. `Why:` is present and grounded in the user's prior words, the KB, or
   expert judgment.

If the engine cannot form a concrete suggestion -- because the question is
genuinely open-ended and the answer space is wide -- it still proposes its
best straw-man and states the uncertainty in `Why:`. It does NOT fall back
to a bare question.

The straw-man-first move (Family 6 in `references/move-playbook.md`)
guarantees a suggestion always exists: even on an open creative question,
the analyst proposes one concrete interpretation and invites the user to
accept, reject, or substitute it.

**Self-check summary:**

| Condition | Action |
|-----------|--------|
| Both fields present and concrete | Emit normally |
| `Suggested:` is blank or missing | Form a straw-man; re-check |
| `Why:` is vague or missing | Ground it in prior words, KB, or judgment; re-check |
| Genuinely open question | Propose best straw-man; state uncertainty in `Why:` |

### D1 Opener: NFR-7-Compliant by Construction

The fixed D1 opener (the first turn of every session) carries an NFR-7
envelope by construction. Its baked-in concrete example fills the
`Suggested:` slot; its cue -- "describe the pieces the way you'd naturally
name them; I'll work from your words" -- fills the `Why:` slot (calibration
rationale). The opener therefore needs no self-check: both fields are
hardwired into its text.

The same holds for the why-probe move (Family 7): the engine proposes the
inferred motive back to the user as the `Suggested:` value. NFR-7 is
verified at the concrete-example probe (Family 8), not assumed.

---

## Expert-Advisor Stance

The engine is a conversational advisor, not a passive transcriber. It
recommends, explains trade-offs, teaches, and cordially disagrees -- but it
NEVER makes a decision on the user's behalf. Every handler below explicitly
returns the call to the user.

Calibration shapes the depth of every response in this section. Expert users
receive lighter treatment; novice or unsure users receive heavier drawing-out
and scaffolding. See `references/calibration.md` for the `Unknown | Expert |
Mixed | Novice` state and depth rules.

### The Five User-Move Handlers

| User move | Engine behavior | Final decision deferred to user? |
|-----------|-----------------|----------------------------------|
| "I don't know" | **Guide and scaffold.** Offer the straw-man suggestion as the concrete default. Explain why it fits (the `Why:` field does this). Mark the answer as an assumption in STATE.md if the user accepts the default without change. Never record a blank answer. | Yes -- user accepts the offered default or substitutes their own |
| "What do you recommend?" | **Recommend as a real expert.** Give the correct expert answer with its full rationale. Do not punt with "it depends" when a best answer exists. Surface the recommendation as a `Suggested:` value with a grounded `Why:` so the user can knowingly accept or override it. | Yes -- presented as a recommendation to accept or override, not as a decision |
| "Explain the pros and cons" | **Explain trade-offs** at the user's calibrated depth: lighter summary for an expert (list the key axes), fuller breakdown for a novice (walk through each option's upside and downside). End with the question re-offered so the user makes the call. | Yes -- the explanation feeds the user's choice; the analyst does not choose |
| "Explain it like I'm a junior" | **Teach at novice depth for this turn.** Drop jargon; use analogies and concrete examples. Treat this as a temporary user-requested calibration shift (do not permanently downgrade calibration state from this signal alone). Re-offer the original question after the explanation. | Yes -- the teaching turn prepares the user to answer; the analyst then re-asks |
| User asserts something the analyst judges mistaken | **Cordially disagree with reasons.** Push back directly: "X tends to break Y because ...; I'd lean toward Z -- but it's your call." Never yes-man a mistaken assertion. State the analyst's position and rationale, then explicitly return the decision to the user. | Yes -- the analyst states its view and returns the call explicitly; the user decides |

### Discipline Lives in Process, Not Restriction

The advisor stance does not restrict the dialogue -- it enriches it. The
discipline is carried by the process:

- **Every resolved point is recorded immediately.** The mediate-then-defer
  and scribe move (Family 6 in `references/move-playbook.md`) captures each
  confirmed answer right away; no answer drifts into ambiguity.
- **One confirmed decision at a time.** The engine asks one question per
  turn (NFR-1; `references/interview-loop.md` Rules). No batching.
- **Unsettleable points are captured and deferred.** If a question cannot be
  resolved now, the capture-and-defer move (Family 8) routes it to
  `STATE.md ## Cross-phase Q&A` and the loop continues.
- **Silent assumptions are banned.** A blank or "I don't know" answer is
  never silently recorded as empty. The handler above converts it to an
  explicit assumption, marked as such, so the user can revisit it.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | work-001-aid-interview-improvements delivery-003 task-010 | Initial authoring: NFR-7 question-envelope contract + expert-advisor stance |
