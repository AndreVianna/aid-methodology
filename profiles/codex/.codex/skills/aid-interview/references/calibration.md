# Calibration

The engine's continuous read-and-ask process for inferring the user's knowledge level and
role. Called by Step 4 (CALIBRATION SHAPING) of the five-step selector in
`references/elicitation-engine.md` to shape move depth. The NFR-7 envelope applied to the
calibration ASK is defined in `references/advisor-stance.md`.

---

## AC-4 and D1: The Opener is Never the Calibration Question

AC-4 requires the skill to ask the user's knowledge level and type and then demonstrably
adapt subsequent question depth. D1 (the owner decision that fixed the opener) rejected
"how experienced are you?" as the first question, requiring instead a what+why
example-anchored opener.

These two requirements are reconciled by separating the opener from calibration entirely:

- Turn 1 is ALWAYS the D1 fixed opener (the what+why question). It is not the calibration
  question.
- Calibration is a distinct two-part behavior -- continuous READ plus an explicit ASK as an
  early follow-up -- that begins after the opener answer arrives.
- The calibration ASK is NEVER turn 1. It is a follow-up, not the opener.

---

## Part A -- READ: Continuous Signal from Turn 1

The engine infers expertise from HOW the user answers, starting with the opener and
continuing every turn. This read is continuous (not a one-time gate): calibration state is
updated after every answer.

### Expert signals

| Signal type | What it looks like |
|-------------|-------------------|
| Jargon fluency | Uses domain-specific or technical terms accurately and without prompting |
| Precision | Names boundaries, roles, or concepts exactly; stays consistent across turns |
| Decisiveness | States preferences directly; gives concrete answers without hedging |
| Self-classification | Names their role or domain experience explicitly |

### Novice / unsure signals

| Signal type | What it looks like |
|-------------|-------------------|
| Hedging | "I think...", "maybe...", "I'm not sure but..." qualifiers on basic points |
| "I don't know" | Explicit admission of not knowing an answer to a foundational question |
| Asking for term definitions | "What do you mean by X?" when X is a standard term |
| Requesting recommendations | "What would you suggest?" before any context is given |

### Mixed signals

A user may be expert in the domain but unfamiliar with software-requirements practice,
or fluent in AID's process but new to the specific domain. When expert and novice signals
coexist across different dimensions, the calibration state is Mixed.

---

## Calibration State

Four states. Re-read after every answer (continuous):

| State | Meaning |
|-------|---------|
| Unknown | Not enough signal yet to determine expertise level |
| Expert | Consistently expert signals; few or no novice signals |
| Mixed | Expert in some dimensions; novice or uncertain in others |
| Novice | Predominantly novice or unsure signals |

The state starts as **Unknown** at turn 1 and updates with each incoming answer.

---

## Part B -- ASK: Explicit Early Follow-up (Not Turn 1)

When calibration state is still **Unknown** after at least one substantive answer (Gap rank
2 in `references/elicitation-engine.md`), the engine MAY emit an explicit knowledge-level
question. This is the calibration ASK.

### Gating rule

The ASK fires only when ALL of the following hold:

1. Calibration state is `Unknown`.
2. At least one substantive answer has been received -- meaning NOT turn 1.

This guarantees the ASK is never the opener (D1 preserved) and is never cold (the analyst
has at least one reading from which to form a straw-man before asking).

### What the ASK probes

The calibration ASK may probe any of:

- Domain familiarity -- how well does the user know this problem space?
- Software / requirements practice -- have they done this kind of work before?
- AID familiarity -- have they used AID's pipeline before?

### NFR-7 envelope on the calibration ASK

Like every question the engine emits, the calibration ASK MUST carry the full NFR-7
envelope (defined in `references/advisor-stance.md`): a concrete `Suggested:` inferred
from what the analyst has already read, and a `Why:` explaining why that level fits and
why knowing it matters to the conversation.

The straw-man is inferred from the opener answer and any subsequent turns: if the user
showed fluency, `Suggested:` leans Expert; if the user hedged or asked for definitions,
`Suggested:` leans Novice or Mixed. The ASK confirms and refines the read -- it does not
replace it.

Example calibration ASK (NFR-7-compliant):

```
From how you described it -- naming the payment processor and retry logic straight away
-- you seem comfortable with the domain. I want to make sure my questions land at the
right depth.

How familiar are you with requirements and design work of this kind?

Suggested: You are experienced in this domain and have done similar requirements work
before, so I will pitch questions at a technical level and skip the teaching scaffolds
unless you ask.
Why: Knowing your level lets me calibrate depth from the start rather than over- or
under-explaining; correct me if I have read this wrong.

[1] Accept this
[2] Not applicable
[3] Your answer: ___
```

After the user responds, the engine updates calibration state and records the answer before
returning to Step 1 of the selector.

---

## Depth-Shaping Table

Once calibration state is set, it shapes every move the engine draws from
`references/move-playbook.md`. An Expert session and a Novice session on the same prompt
must read as different conversations.

| Calibration state | Move depth | Concrete behaviors |
|-------------------|------------|-------------------|
| Expert | Lighter | Fewer why-steps (an expert states the terminal value directly -- stop when rationale is explicit); confirm-and-move (straw-man + "agree?" is sufficient); skip teaching scaffolds and extended examples; trust stated precision |
| Mixed | Targeted | Confirm where fluent (lighter treatment in that dimension); draw out where hedging appears (heavier treatment); split depth by dimension, not uniformly |
| Novice / unsure | Heavier | More drawing-out; teaching scaffolds (explain the "why" behind a question before asking it); more example-probes ("walk me through an example"); more why-steps (climb toward the terminal value, not just one rung); offer recommendations proactively when the user hedges (see advisor-stance.md for the "what do you recommend?" handler) |
| Unknown | Novice-adjacent default | Until resolved, treat as Heavier so no novice user is left unsupported; the Part B ASK is the fastest path to resolving Unknown |

**AC-4 divergence test:** two dogfood transcripts on the same prompt -- one Expert persona,
one Novice persona -- must demonstrate (a) the calibration ASK fired as an early follow-up
(never turn 1) carrying an NFR-7 envelope, and (b) the Expert run used fewer why-steps and
confirm-and-move while the Novice run drew out, taught, and used more example-probes. The
two transcripts must read as different conversations.

**Anti-anchoring implication of Novice state (G1):** for genuinely-open, high-stakes, or
creative gaps when calibration state is Novice (or the user is reading as deferential on
a given turn), apply the open-first question order defined in
`references/advisor-stance.md` Rule G1a, rather than the standard straw-man-first order.
The NFR-7 envelope (Suggested: and Why:) remains present in both orders; only the framing
of the context sentences and the Why: copy changes. Expert and Mixed states keep the
standard straw-man-first order. Low-stakes or convergent gaps keep the standard order
regardless of calibration state.

---

## Feature-004 Inheritance

Calibration is shared substrate. Feature-004 (guided triage) inherits it without
re-implementing it. An unsure user in triage needs more drawing-out to supply the scope and
type signals that route them correctly; the backbone-first and walking-skeleton moves that
feature-004 leans on (Gap rank 2 for scope-size unknowns) are shaped by calibration state
exactly as they are in the full-path interview.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | work-001-aid-interview-improvements delivery-003 task-013 | Initial authoring: AC-4/D1 reconciliation, continuous READ + explicit ASK, four-state calibration, depth-shaping table, feature-004 inheritance |
| 1.1 | 2026-06-27 | work-001-aid-interview-improvements delivery-003 task-041 | G1 anti-anchoring implication: open-first order for Novice/deferential on genuinely-open/high-stakes gaps (cross-reference to advisor-stance.md Rule G1a) |
