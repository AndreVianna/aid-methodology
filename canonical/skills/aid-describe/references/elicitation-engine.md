# Elicitation Engine

The engine driver for the seasoned-analyst interview: one fixed opener (D1) plus a
deterministic five-step next-move selector that runs every subsequent turn (D2). This
is NOT a question list -- it is an adaptive analyst. Three parameters supplied by the
caller let feature-003 (greenfield seed authoring) CONSUME this engine without
re-implementing it (D3). The standalone `/aid-triage` router (feature-014,
work-001-lite-aid-skills) reuses the D1 opener's reflect-back-turn UX shape as a
precedent, not as a live three-parameter consumer -- see "Consumption Contract" below.

**Audience.** Two readers at once: a junior maintainer learning how the interview
works, and the feature implementations that invoke or extend the engine.

**Cross-references.**
- `canonical/skills/aid-describe/references/move-playbook.md` -- the ten moves and
  the gap-type -> move firing table that Step 3 (MOVE SELECTION) reads each turn.
- `canonical/skills/aid-describe/references/calibration.md` -- the continuous
  read+ask design, the `Unknown | Expert | Mixed | Novice` state, and the
  depth-shaping rules that Step 4 (CALIBRATION SHAPING) applies.
- `canonical/skills/aid-describe/references/advisor-stance.md` -- the NFR-7
  question-envelope template, the pre-emit self-check, and the five expert-advisor
  user-move handlers that Step 5 (ENVELOPE + EMIT) applies.

---

## Contents

- [Engine Overview](#engine-overview)
- [D1 Fixed Opener -- The Only Fixed Turn](#d1-fixed-opener----the-only-fixed-turn)
- [Adaptive Loop](#adaptive-loop)
- [Step 1 -- STOP CHECK](#step-1----stop-check)
- [Step 2 -- GAP SELECTION](#step-2----gap-selection)
- [Step 3 -- MOVE SELECTION](#step-3----move-selection)
- [Step 4 -- CALIBRATION SHAPING](#step-4----calibration-shaping)
- [Step 5 -- ENVELOPE + EMIT](#step-5----envelope--emit)
- [Consumption Contract](#consumption-contract)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## Engine Overview

The engine has exactly two parts:

1. **The D1 fixed opener.** One fixed turn. Every session starts here. It is the ONLY
   scripted turn in the entire interview. After the user answers it, control passes to
   the adaptive loop permanently.

2. **The adaptive loop (D2).** Every turn after the opener. The five-step next-move
   selector chooses the next question. No further turns are scripted; the sequence
   emerges from the gap inventory the consumer supplies.

```
[FIRST-RUN scaffolding done]
        |
        v
  (turn 1, FIXED)  EMIT D1 OPENER
        |          The single fixed "what + why" example-anchored question.
        |          NFR-7-compliant by construction:
        |            baked-in concrete example = Suggested:
        |            cue "describe the pieces the way you'd naturally name them" = Why:
        v
  READ answer --> capture first vocabulary (term-capture) + seed calibration signal
        |
        v
  +---------------------- ADAPTIVE LOOP (every subsequent turn, D2) ----------------------+
  |                                                                                       |
  |  1. STOP CHECK ......... minimal-but-sufficient? (NFR-4 / RQ-A5) --yes--> EXIT       |
  |  2. GAP SELECTION ...... pick highest-priority open gap (precedence table below)      |
  |  3. MOVE SELECTION ..... gap-type -> move-playbook.md firing table                   |
  |  4. CALIBRATION SHAPE .. calibration.md depth-shaping rules                          |
  |  5. ENVELOPE + EMIT .... advisor-stance.md NFR-7 envelope; self-check; emit          |
  |        |                                                                              |
  |        v                                                                              |
  |  READ answer --> record to record sink --> re-read calibration state                  |
  |        |                                                                              |
  +--------+------------------------------------------------------------------------------+
        |
        v
  EXIT --> host state advance:
           full-path interview  --> COMPLETION
           seed authoring (feature-003) --> seed gate
```

Two invariants from `references/interview-loop.md` hold for every loop turn:
(a) **one question per turn, never batch** (interview-loop.md Rules);
(b) **update files after each answer** before returning to Step 1
    (interview-loop.md "Update after each answer").

---

## D1 Fixed Opener -- The Only Fixed Turn

**The D1 opener is the single fixed turn in the entire interview. No other turn is
scripted.** The engine derives every subsequent turn from the gap inventory. This is
the discipline D2 requires: an adaptive analyst, not a fixed questionnaire.

### Opener text

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

### Why the opener is NFR-7-compliant by construction

The opener does not need a pre-emit self-check (advisor-stance.md Enforcement 2:
Self-Check) because both required fields are hardwired into its text:

- **Suggested:** the baked-in concrete example fills the `Suggested:` slot. The user
  sees a full model answer and can accept its structure or substitute their own.
- **Why:** the cue "describing the pieces in your own words gives me the working
  vocabulary... I will use your terms" fills the `Why:` slot. This is the calibration
  rationale from D1 (STATE.md ## Cross-phase Q&A, decision D1, rationale point 2).

No self-check is needed: both fields are present by construction, not by inspection.

### What the engine reads from the opener answer

The opener answer is the engine's first working dataset. Before entering the adaptive
loop, the engine extracts:

| Signal harvested | Used by |
|----------------|---------|
| Nouns and verbs the user introduced | Step 2 gap detection (rank-3 term-capture gap); Step 3 move-playbook.md Move 2 |
| Jargon fluency, precision, decisiveness | Calibration state initialization (calibration.md Part A -- continuous READ) |
| Scope cues (small/simple vs large/sprawling) | Step 2 gap detection (scope-size signal for Move 5, the full-path scope-sizing move) |

---

## Adaptive Loop

After the opener answer is read, the engine enters the five-step selector loop. It
runs Steps 1-5 on every turn until the stop check fires.

**The four inputs that drive every turn (D2):**

| Input | Source |
|-------|--------|
| Gap inventory | Supplied by the consumer at invocation time (see Consumption Contract) |
| Move playbook | `canonical/skills/aid-describe/references/move-playbook.md` |
| Calibration state | `canonical/skills/aid-describe/references/calibration.md` |
| NFR-7 invariant | `canonical/skills/aid-describe/references/advisor-stance.md` |

---

## Step 1 -- STOP CHECK

**Precedes gap selection. Fires every turn before any gap is examined.**

The engine halts when the work is **minimal-but-sufficient** for its host purpose --
NOT at the end of a list. This is the discipline grill-me lacks (findings.md Section 3):
the engine stops, it does not "ask every branch."

The stop condition is **consumer-parameterized** (see Consumption Contract). Each
consumer supplies its own stop predicate:

| Host context | Stop condition |
|-------------|----------------|
| Full-path interview | Every REQUIREMENTS.md section is `Complete` or `N/A` (interview-loop.md Section State), and no unresolved coherence conflict is open |
| Seed authoring (feature-003) | Every mandatory Rec-A seed element passes its per-element fit criterion (findings.md RQ-A5 table) and aid-specify would run with zero KB-gap loopbacks (AC-2) -- feature-003 supplies this checklist |

**When the stop check fires:** the engine exits and returns control to the host
state's advance. It does not emit another question.

**When the stop check does not fire:** execution falls through to Step 2.

---

## Step 2 -- GAP SELECTION

**Among all open gaps in the gap inventory, pick the highest-priority one.**

The precedence ranking is deterministic. Every open gap falls into exactly one rank.
The engine picks the rank-1 gap when one exists; it falls to rank 2 only when no
rank-1 gap is open, and so on down the table.

| Rank | Gap class | Why it wins | Source |
|------|-----------|-------------|--------|
| 1 | **Open coherence conflict or contradiction** | A contradiction must be resolved before more is added. The analyst does not pile on a broken foundation. The engine surfaces the conflict and routes it to a clarifying turn or to Move 9 (capture-and-defer). | NFR-1 process discipline; findings.md Section 6 item 5 |
| 2 | **Calibration unknown** -- only when calibration state is still `Unknown` AND at least one substantive answer has been received (NOT turn 1) | Knowing the user's level shapes every later turn's depth. This gap is cheap and high-leverage when resolved early. The "not turn 1" gate preserves D1: the calibration ASK is always a follow-up, never the opener. | findings.md RQ-B2; calibration.md Part B gating rule |
| 3 | **Missing keystone seed element or critical REQUIREMENTS gap** | Concept-spine and intended-architecture elements are load-bearing (findings.md Rec A weighting: elements 1-2 are keystones). Pick the gap that depends on the least and unblocks the most. | findings.md RQ-A1 weighting; interview-strategies.md priority 2 |
| 4 | **Missing lighter element** (conventions, stack, decisions) | Deferrable. Ask after keystones are addressed. | findings.md RQ-A1 ("lighter-weight, more deferrable") |
| 5 | **Under-pinned existing answer** -- a term or claim the user stated with no concrete example (a Partial gap) | Deepen a Partial before declaring done. | interview-strategies.md priority 3; move-playbook.md Move 8 |

**Gap inventory source:** the gap inventory is supplied by the consumer. Feature-003
supplies the Rec-A seed doc-set; the full-path interview draws from REQUIREMENTS.md
sections. The precedence ranking above is the engine's fixed logic; the inventory
contents vary by consumer.

---

## Step 3 -- MOVE SELECTION

**The selected gap's type determines the move.**

Delegate to `canonical/skills/aid-describe/references/move-playbook.md`. Read the
gap-type -> move firing table in that doc's section "Gap-Type to Move Firing Table."
The engine does not pick a move by position in a sequence; it reads the gap type and
looks up the table every turn.

| Gap type | Playbook move |
|----------|---------------|
| Undefined or ambiguous term the user used | Move 2: Term-capture + disambiguation |
| Unnamed boundary or relationship in the architecture | Move 3: Boundary-elicitation |
| Unknown behavior or flow in a process-heavy domain | Move 4: Event-first, propose-timeline-back |
| Unknown scope size (backbone size, sprawl) | Move 5: Backbone-first + walking-skeleton |
| Missing fit criterion or testability of a requirement | Move 6: Rationale + testability probe |
| Missing "why" behind a stated intent | Move 7: Bounded why-probe -- climb 2-3 whys, propose the inferred motive back, stop at the terminal value; NEVER the rote "five whys" |
| A claim or term asserted with no concrete example | Move 8: Concrete-example probe |
| A point that cannot be settled now | Move 9: Capture-and-defer (red-card) -- record to STATE.md ## Cross-phase Q&A and move on |

**Delivery envelope.** Move 1 (Straw-man-first) and Move 10 (Mediate-then-defer and
scribe) are not standalone gap responses. They are the delivery envelope that wraps
every gap-response move chosen above. Every turn uses both. See move-playbook.md
"Delivery Envelope -- Moves 1 and 10" for their specification.

**Numbered sequence is a default, not a script (D2 / NFR-1).** The sequence in
findings.md RQ-B1 is a recommended default. The engine does NOT march through moves
in that order. It picks the move for the highest-priority open gap, whatever that gap
is. The sequence emerges from the gap inventory, not from a preset move order.

---

## Step 4 -- CALIBRATION SHAPING

**The chosen move's depth is shaped by calibration state before it is emitted.**

Delegate to `canonical/skills/aid-describe/references/calibration.md`. Read the
Depth-Shaping Table in that doc. Apply depth shaping to the move chosen in Step 3
before proceeding to Step 5.

| Calibration state | Move depth applied |
|-------------------|--------------------|
| Expert | Lighter: fewer why-steps (an expert states the terminal value directly); confirm-and-move (straw-man + "agree?" is sufficient); skip teaching scaffolds and extended examples |
| Mixed | Targeted: confirm where the user is fluent (lighter); draw out where they hedge (heavier); split depth by dimension, not uniformly |
| Novice / unsure | Heavier: more drawing-out; teaching scaffolds; more example-probes; more why-steps; offer recommendations proactively when the user hedges |
| Unknown | Novice-adjacent default (heavier) until calibration is resolved; the Part B ASK (gap rank 2) is the fastest path to resolving Unknown |

**Calibration state is re-read every turn** (continuous, not a one-time gate). See
calibration.md Part A (continuous READ from every answer) and Part B (explicit ASK
as an early follow-up when state is still Unknown at gap rank 2, never on turn 1).
An Expert session and a Novice session on the same prompt must read as different
conversations (the AC-4 divergence test in calibration.md).

---

## Step 5 -- ENVELOPE + EMIT

**Wrap the shaped question in the NFR-7 envelope, run the pre-emit self-check, then
emit.**

Delegate to `canonical/skills/aid-describe/references/advisor-stance.md`:

- **NFR-7 envelope template** (advisor-stance.md "The Envelope Template"): every
  emitted question carries context, the question itself, a concrete `Suggested:`
  answer, a grounded `Why:` rationale, and the accept/override options. All five
  parts are non-optional.
- **Pre-emit self-check** (advisor-stance.md "Enforcement 2: Self-Check"): before
  emitting, verify `Suggested:` is present and concrete (not blank, not "-") and
  `Why:` is present and grounded. If a concrete suggestion cannot be formed, propose
  the best straw-man and state the uncertainty in `Why:` -- never fall back to a bare
  question.
- **Expert-advisor user-move handlers** (advisor-stance.md "The Five User-Move
  Handlers"): shape the response when the user signals "I don't know," "what do you
  recommend?," "explain the pros and cons," "explain it like I'm a junior," or asserts
  something the analyst judges mistaken.

**After the user answers, before returning to Step 1:**

1. Record the confirmed answer to the record sink supplied by the consumer (see
   Consumption Contract). No answer is recorded as blank: if the user accepted the
   straw-man default, record it with an assumption marker (advisor-stance.md handler
   for "I don't know").
2. Re-read calibration state using the signals in this answer (calibration.md Part A).
   Update calibration state if new evidence arrived.
3. Return to Step 1.

**Invariant: no bare, suggestion-less question is ever emitted (NFR-7 / AC-3).** A
turn that omits or blanks `Suggested:` or `Why:` is a malformed emission. The
straw-man-first move (move-playbook.md Move 1) guarantees a suggestion always exists.

---

## Consumption Contract

The engine is invoked by a consumer that supplies three parameters. It returns control
to the host state when its stop check fires (Step 1). It does not own the host's
terminal artifact.

| Parameter | Supplied by | Meaning |
|-----------|-------------|---------|
| **gap inventory** | consumer | The set of open gaps the adaptive loop draws out. Full-path interview: REQUIREMENTS.md sections. Feature-003: the Rec-A seed doc-set. |
| **stop predicate** | consumer | The minimal-but-sufficient test for this context. Full-path interview: all sections Complete/N/A with no open conflict. Feature-003: the RQ-A5 per-element fit criteria (aid-specify runs with zero KB-gap loopbacks). |
| **record sink** | consumer | Where each confirmed answer is written. Full-path interview: REQUIREMENTS.md sections. Feature-003: the forward-authored KB docs. |

**Consume, do not re-implement (D3).**

**feature-003 (greenfield seed authoring) CONSUMES this engine.** It supplies the
Rec-A seed doc-set as the gap inventory, the RQ-A5 per-element fit criteria as the
stop predicate, and the forward-authored KB docs as the record sink. Feature-002 does
not define the seed content model, the `source:` marker, the seed gate, or the
seed-to-requirements coherence mechanism -- those are feature-003's scope. The engine
only surfaces a coherence conflict it notices (gap rank 1) and routes it to
capture-and-defer via Move 9.

**The in-skill guided-triage consumer has been removed.** `aid-describe` no longer hosts
a TRIAGE state (work-001-lite-aid-skills feature-013) -- full-vs-lite routing has left this
skill entirely; `aid-describe` now runs the full-path interview only. The standalone
`/aid-triage` router (feature-014, work-001-lite-aid-skills) is the engine's external
reusability precedent for the reflect-back turn: it reuses the D1 opener's UX shape (one
fixed "what + why" example-anchored capture, `Suggested:`/`Why:` non-optional) as a
one-shot single-turn capture, but it does NOT run the adaptive loop -- it has no gap
inventory, no stop predicate, and no record sink of its own (it is suggest-only; see
`canonical/skills/aid-triage/SKILL.md`). It is a UX-shape consumer, not a three-parameter
consumer of this Consumption Contract.

**Opener de-dup.** The opener fires exactly once per work, at `state-continue.md`'s
entry: when all REQUIREMENTS.md sections are still `Pending`, `state-continue.md` emits
the D1 opener; once any section moves past `Pending`, every later CONTINUE entry (and the
DESCRIBE-SEED entry that follows it) skips straight to the adaptive loop / resume point
without re-emitting it. The opener content is feature-002's; the fire-once placement now
lives entirely in `state-continue.md`.

---

## Invariants

These invariants hold for every turn the engine runs, including the D1 opener.

| # | Invariant | Source |
|---|-----------|--------|
| 1 | One question per turn, never batch | interview-loop.md Rules |
| 2 | Update files (record sink + STATE.md) after each answer, before returning to Step 1 | interview-loop.md "Update after each answer" |
| 3 | No bare, suggestion-less question is ever emitted; `Suggested:` and `Why:` are non-optional on every emission | NFR-7 / AC-3; advisor-stance.md |
| 4 | The D1 opener is the ONLY fixed turn; every adaptive loop turn is engine-chosen from the gap inventory; no hidden question list exists | D2; feature-002/SPEC.md "Engine Overview" |
| 5 | The loop halts at minimal-but-sufficient (consumer's stop predicate fires), not at the end of a list | NFR-4 / RQ-A5; Step 1 stop check |
| 6 | The opener is NEVER the calibration question; the calibration ASK fires as a follow-up at gap rank 2, never on turn 1 | D1 / AC-4; calibration.md Part B gating rule |
| 7 | Every decision defers to the user; the engine recommends and guides but never decides silently | NFR-1; advisor-stance.md "Expert-Advisor Stance" |
| 8 | Before the host's approval gate, the assembled intent gathered across all turns is reflected back to the user for confirmation and correction (whole-picture read-back). Per-turn confirmations (Move 10 scribe) do not substitute for this -- the whole must be confirmed, not just individual decisions. In the full-path interview, state-completion.md Step 4 fulfils this invariant. Feature-003 consumers must define an equivalent confirmation step. | web-bestpractice-validation.md G2 (Mircea et al.: "validation loop"); state-completion.md Step 4 |

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | work-001-aid-describe-improvements delivery-003 task-013 | Initial authoring: D1 fixed opener + five-step next-move selector + three-parameter consumption contract, grounded in feature-002/SPEC.md and owner decisions D1/D2/D3 in STATE.md ## Cross-phase Q&A. |
| 1.1 | 2026-06-27 | work-001-aid-describe-improvements delivery-003 task-041 | G2 whole-picture read-back: Invariant 8 added (assembled-intent confirmation before approval gate; fulfilled by state-completion.md Step 4 for full-path interview) |
