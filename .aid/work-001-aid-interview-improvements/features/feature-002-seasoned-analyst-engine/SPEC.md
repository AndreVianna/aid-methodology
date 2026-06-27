# Seasoned-Analyst Elicitation Engine

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-2, §6 NFR-1, §6 NFR-7, §9 AC-3/AC-4, §10 P1 | /aid-interview |
| 2026-06-27 | Technical Specification authored: engine = D1 fixed opener + D2 adaptive next-move loop (5-step selector), move playbook, read+ask calibration (AC-4 vs D1 reconciled), expert-advisor stance, NFR-7 question-envelope contract, in-place extension of aid-interview spine (C-2), consumption contract for 003/004 (D3), AI+human-review DoD | /aid-specify |
| 2026-06-27 | Gate A+ (1 MINOR locator fixed). Post-gate reconciliation with feature-004: the `state-continue.md` D1 opener is emitted CONDITIONALLY (skipped when TRIAGE already captured it via `## Triage **Opener:**`), not unconditionally — the fire-once de-dup placement is feature-004's, the opener content stays feature-002's | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-2, §6 NFR-1, §6 NFR-7, §9 AC-3 / AC-4, §10 P1

## Description

The shared conversational substrate that makes the skill behave like a seasoned system analyst
rather than a passive transcriber or a rigid one-question machine. It is one reusable component
consumed by greenfield seed authoring and by guided triage. Three behaviors define it. First,
**calibration**: the engine assumes nothing about the user; early on it asks the user's level
and type of knowledge (domain familiarity, software / requirements practice, AID itself) and
then shapes question depth and style to match — lighter confirmation for an expert, heavier
drawing-out for a novice. Second, the **conversational expert advisor** stance: it gracefully
supports "I don't know," "what's your recommendation?," "explain the pros and cons," and
"explain it like I'm a junior"; it guides an unsure user, recommends as a real expert when
asked, explains trade-offs at the right depth, and cordially disagrees with reasons when the
user is mistaken — while still deferring the final decision to the user. Third, the
**suggested-answer-and-rationale contract**: every question the analyst asks carries a concrete
suggested answer plus the rationale behind it, so the user always decides but never from a
blank prompt. Discipline lives in the process (visible state, recorded decisions, one confirmed
decision at a time), not in restricting the dialogue.

## User Stories

- As the work-definer (human) of unknown expertise, I want the analyst to ask my knowledge level
  and adapt so that the questioning matches how much help I actually need.
- As an unsure work-definer, I want to say "I don't know" or "what do you recommend?" and get a
  real expert answer with trade-offs explained at my level so that I can make an informed call.
- As a work-definer who is mistaken, I want the analyst to cordially push back with reasons so
  that I correct course rather than being yes-manned into a bad decision.
- As any work-definer, I want every question to come with a suggested answer and its rationale so
  that I can knowingly agree or disagree instead of starting from a blank prompt.

## Priority

Must

## Acceptance Criteria

- [ ] Given the skill is running, when the analyst asks any question, then that question carries
  a concrete suggested answer plus the rationale behind it (no bare, suggestion-less questions
  ever). *(AC-3)*
- [ ] Given a new session, when the interview begins, then the skill asks the user's knowledge
  level/type and demonstrably adapts subsequent question depth and style. *(AC-4)*
- [ ] Given an unsure or mistaken user, when they respond "I don't know," "what do you
  recommend?," or "explain like a junior" — or assert something incorrect — then the analyst
  guides, recommends, explains at the right depth, and cordially disagrees while still deferring
  the decision to the user. *(AC-4)*

---

## Technical Specification

> Grounded in `feature-001/findings.md` (Rec B, RQ-B1..B4; §1 finding-2; §6 #5), the work-owner
> decisions D1 / D2 / D3 in `STATE.md ## Cross-phase Q&A`, and the on-disk
> `canonical/skills/aid-interview/` state machine. Authoritative requirements: REQUIREMENTS.md
> FR-2, NFR-1, NFR-7, AC-3, AC-4.

### Engine Overview

feature-002 builds the **seasoned-analyst elicitation engine**: the shared conversational
substrate that turns the interview from a fixed questionnaire into an adaptive analyst. It is
**one fixed opener plus an adaptive next-move loop** (D1 + D2), not a question list. The engine
is the reusable component named by REQUIREMENTS.md FR-5's emergent-design note; feature-003
(greenfield seed authoring) and feature-004 (guided triage) **consume** it, they do not
re-implement it (D3).

Per **C-2 (extend, don't fork)**, the engine is an **in-place generalization** of the existing
adaptive one-question-at-a-time spine -- it does NOT add a parallel skill and does NOT introduce
a new top-level state. The four spine touch-points it extends, all under
`canonical/skills/aid-interview/`:

- `references/interview-loop.md` -- its `### Decide what to ask next` step becomes the explicit
  next-move selector (the engine driver).
- `references/interview-strategies.md` -- its `## Decide What to Ask Next -- Priority Order` and
  `## Question Design Principles` are the seed of the move playbook, the advisor stance, and the
  NFR-7 envelope; these are lifted into dedicated engine reference docs and this file delegates
  to them.
- `references/state-continue.md` -- its bare opener (`What are we building?...`) is replaced by
  the D1 fixed opener, emitted **conditionally**: skipped when TRIAGE already captured the opener
  answer (per feature-004's `## Triage **Opener:**` de-dup), emitted only on legacy/pre-TRIAGE/
  loopback entry where that field is absent. (The opener's *content* is feature-002's; the
  fire-once placement is feature-004's.)
- `references/state-triage.md` -- its Step 1 free-form-description prompt is re-pointed at the
  same D1 opener (feature-004 owns the routing decision that reads the answer; feature-002 owns
  the opener).

Per **D3**, the engine is authored in `canonical/skills/aid-interview/` now (features 002-004
edit this dir in place) and **migrates to the `aid-describe` skill dir later under feature-006**
(the split is sequenced after the content features). feature-002 introduces no rename.

### Feature Flow / State Model

The engine is a loop that lives **inside** the existing states `CONTINUE` (full-path interview)
and `TRIAGE` (the opener), and is parameterized by feature-003 for seed authoring. It does NOT
change the State Detection table in `SKILL.md`. The loop:

```
[FIRST-RUN scaffolding done]
        |
        v
  (turn 1, FIXED)  EMIT D1 OPENER  --- the single fixed "what + why" example-anchored question
        |          (NFR-7-compliant by construction: the baked-in concrete example IS the
        |           suggested answer; the cue "describe the pieces the way you'd naturally
        |           name them" IS the rationale)
        v
  READ answer  -> capture first vocabulary (term-capture) + seed calibration signal
        |
        v
  +------------------- ADAPTIVE LOOP (every subsequent turn, D2) -------------------+
  |                                                                                  |
  |  1. STOP CHECK ......... minimal-but-sufficient? (NFR-4 / RQ-A5)  --yes--> EXIT  |
  |  2. GAP SELECTION ...... pick highest-priority open gap (precedence below)       |
  |  3. MOVE SELECTION ..... gap-type -> playbook move (table below)                 |
  |  4. CALIBRATION SHAPE .. expert=light / novice=draw-out (calibration state)      |
  |  5. ENVELOPE + EMIT .... wrap in NFR-7 suggested-answer+rationale; self-check    |
  |        |                                                                          |
  |        v                                                                          |
  |  READ answer -> record (REQUIREMENTS / seed doc + STATE) -> re-read calibration   |
  |        |                                                                          |
  +--------+--------------------------------------------------------------------------+
        |
        v
  EXIT -> the host state's advance: full-path -> COMPLETION; triage -> feature-004
          routing decision; seed authoring -> feature-003 seed gate.
```

Two invariants carried from the current spine, both in `interview-loop.md`: **one question
per turn, never batch** (`### Rules`); **update files after each answer** (`### Update after each
answer`). The opener is the ONLY fixed turn (D2); every loop turn is engine-chosen.

### Next-Move Selection (the heart)

Each loop turn runs a deterministic five-step selection. The **inputs** are exactly D2's four
drivers: (1) seed-gap, (2) the move playbook, (3) calibration state, (4) the NFR-7 invariant.

**Step 1 -- STOP CHECK (precedes gap selection; NFR-4 / RQ-A5).** The loop halts when the work
is *minimal-but-sufficient* for its host purpose, NOT at the end of a list:

- Full-path interview: every REQUIREMENTS.md section is `Complete` or `N/A`
  (`interview-loop.md` Section State), and no unresolved coherence conflict is open.
- Seed authoring (feature-003 parameterization): every mandatory Rec-A seed element passes its
  per-element fit criterion (findings.md RQ-A5 table) and `aid-specify` would run with zero
  KB-gap loopbacks (AC-2). feature-003 supplies this checklist; the engine consumes it.
- Triage (feature-004 parameterization): enough path/recipe-deciding signal is present to route
  with confidence. feature-004 supplies the sufficiency predicate.

This is the discipline `grill-me` lacks (findings.md §3) -- the engine stops, it does not "ask
every branch."

**Step 2 -- GAP SELECTION (precedence order).** Among open gaps, pick the highest-priority one:

| Rank | Gap class | Why it wins | Source |
|------|-----------|-------------|--------|
| 1 | **Open coherence conflict / contradiction** | A contradiction must be resolved before more is added (analyst does not pile on a broken foundation) | NFR-1 process discipline; findings §6 #5 (the seed<->requirements coherence MECHANISM is feature-003's; the engine only *surfaces* a conflict it notices and routes it to capture-and-defer or a clarifying turn) |
| 2 | **Calibration unknown** (only if calibration state is still `Unknown` AND >= 1 substantive answer has been read -- i.e. NOT turn 1) | Knowing the user's level shapes every later turn's depth; cheap, high-leverage early | findings RQ-B2; reconciles AC-4 vs D1 (see Calibration) |
| 3 | **Missing keystone seed element / critical REQUIREMENTS gap** | Concept-spine and intended-architecture are load-bearing (Rec A weighting: elements 1-2 are keystones); pick the gap that depends on least and unblocks most | findings RQ-A1 weighting; `interview-strategies.md` priority #2 |
| 4 | **Missing lighter element** (conventions, stack, decisions) | Deferrable; ask after keystones | findings RQ-A1 ("lighter-weight, more deferrable") |
| 5 | **Under-pinned existing answer** (a term/claim with no concrete example) | Deepen a Partial before declaring done | `interview-strategies.md` priority #3; Example Mapping (Family 8) |

For feature-003, "seed element" gaps are concrete (the Rec-A doc-set); for the full-path
interview they are REQUIREMENTS.md sections; for feature-004 they are the path/recipe signals.
The **gap inventory is supplied by the consumer**; the precedence ranking is the engine's.

**Step 3 -- MOVE SELECTION (gap-type -> playbook move).** The selected gap's *type* determines
the move drawn from the playbook (the ten moves of findings.md RQ-B1, encoded in
`references/move-playbook.md`). The sequence in findings RQ-B1 is a *default*, not a script
(D2 / NFR-1 latitude) -- the table is the firing rule:

| Gap type | Playbook move | From (family) |
|----------|---------------|---------------|
| Undefined / ambiguous term the user used | **Term-capture + disambiguation** | DDD/UL (1) |
| Unnamed boundary or relationship in the architecture | **Boundary-elicitation** | Context Modeling (2) |
| Unknown behavior / flow in a process-heavy domain | **Event-first, propose-timeline-back** | Event Storming (3) |
| Unknown scope size (full-vs-lite / recipe signal) | **Backbone-first + walking-skeleton** | User-Story Mapping (4) -- the move feature-004 leans on |
| Missing fit criterion / testability of a requirement | **Rationale + testability probe** | Volere (5) |
| Missing "why" behind a stated intent | **Bounded why-probe** (climb 2-3 whys, propose the inferred motive back, stop at the terminal value -- NEVER the rote "five whys") | Five-Whys / Laddering (7) |
| A claim/term asserted with no concrete example | **Concrete-example probe** | Example Mapping (8) |
| A point that cannot be settled now | **Capture-and-defer (red-card)** -- record as a `STATE.md ## Cross-phase Q&A` entry / downstream-risk and move on | Example Mapping (8) |
| Disagreement surfaced, or any turn at all | **Straw-man-first** + **mediate-then-defer & scribe** -- always wraps the chosen move (see NFR-7 + advisor stance) | JAD (6) |

Straw-man-first (move 1) and mediate-then-defer (move 10) are not standalone gap responses;
they are the **delivery envelope** every other move is emitted through (Step 5).

**Step 4 -- CALIBRATION SHAPING.** The chosen move's depth is shaped by calibration state (next
section): expert -> lighter, fewer why-steps; novice -> heavier draw-out, more scaffolding and
example-probes.

**Step 5 -- ENVELOPE + EMIT.** The shaped question is wrapped in the NFR-7 envelope and
self-checked before emission (see NFR-7 Contract). After the user answers, the engine records
the result (REQUIREMENTS section / seed doc + STATE.md), re-reads the calibration signal, and
returns to Step 1.

### Calibration (read + ask) -- AC-4

This is the explicit reconciliation of **AC-4** (the skill "asks the user's knowledge level/type
and demonstrably adapts") with **D1** (which rejected "how experienced are you?" as the
*opener*). They are reconciled by separating the opener from calibration:

- **The opener is NEVER the calibration question.** Turn 1 is always the D1 what+why
  example-anchored question (D1). Calibration is a *distinct early behavior*, not turn 1.
- **(a) READ -- continuous, from turn 1 onward.** The engine infers the user's expertise/role
  from *how* they answer the opener and every subsequent turn -- jargon fluency, precision,
  decisiveness, and self-classification cues read as **expert**; hedging, "I don't know",
  requests for recommendations, or asking what a term means read as **novice/unsure** (findings
  RQ-B2; JAD "read the room", Family 6). Calibration state is one of `Unknown | Expert | Mixed |
  Novice` and is **re-read every turn** (continuous, not a one-time gate).
- **(b) ASK -- an explicit early follow-up, NOT turn 1.** When calibration state is still
  `Unknown` after >= 1 substantive answer (Gap-selection rank 2), the engine MAY emit an
  explicit knowledge-level/type question (domain familiarity, software/requirements practice,
  AID familiarity). This question **itself carries an NFR-7 suggested answer + rationale** (e.g.
  a straw-man inferred from the opener: "From how you described it, you sound comfortable with
  the domain but newer to AID -- does that match? [suggested] ... [rationale] knowing this lets
  me pitch the questions at the right level."). It is asked as a follow-up, never cold on turn 1
  (D1's "calibrate by reading the answer" -- the ask confirms the read, it does not replace it).

**How depth demonstrably changes (the AC-4 "adapts" bar):**

| Signal | Move depth | Concrete behavior |
|--------|-----------|-------------------|
| Expert | Lighter | Fewer why-steps (an expert states the terminal value directly -- Family 7); confirm-and-move (straw-man + "agree?"); skip teaching scaffolds |
| Mixed | Targeted | Confirm where fluent; draw out where hedging appears |
| Novice / unsure | Heavier | More drawing-out, teaching scaffolds, more example-probes and why-steps; offer recommendations proactively (advisor stance) |

Calibration is shared substrate: feature-004 inherits it (an unsure user needs more drawing-out
to route correctly -- findings RQ-B2 actionable).

### Expert-Advisor Stance -- NFR-1 / AC-4

The engine is a conversational advisor with latitude in dialogue and discipline in process
(NFR-1). Concrete handling of the user moves named in AC-4, each **still deferring the final
decision to the user** (the engine never silently assumes an answer or hides a decision):

| User move | Engine behavior | Defers decision? |
|-----------|-----------------|------------------|
| "I don't know" | **Guide / scaffold**: offer the straw-man suggestion as the default and explain why it fits; mark as assumption if the user accepts the default (`interview-strategies.md` "Respect I don't know"); never just record a blank | Yes -- user accepts/overrides the offered default |
| "What do you recommend?" | **Recommend as a real expert**: give the correct expert answer with its rationale, not a non-committal punt (NFR-1) | Yes -- surfaced as a recommendation to accept/override |
| "Explain the pros and cons" | **Explain trade-offs** at the user's calibrated depth (lighter for expert, fuller for novice) | Yes -- the explanation feeds the user's choice |
| "Explain it like I'm a junior" | **Teach**: drop to novice depth for this turn (a temporary, user-requested calibration shift), then re-offer the question | Yes |
| User asserts something the analyst judges mistaken | **Cordially disagree with reasons**: push back like a seasoned analyst ("X tends to break Y because...; I'd lean toward Z -- but it's your call"), never yes-man | Yes -- explicitly returns the call to the user |

The discipline lives in the **process**, not by restricting the dialogue: visible state, every
resolved point recorded immediately (mediate-then-defer & scribe, Family 6), one **confirmed**
decision at a time (NFR-1). The capture-and-defer move (Family 8) routes anything unsettleable
to `STATE.md ## Cross-phase Q&A` rather than blocking the loop.

### NFR-7 Question-Envelope Contract -- AC-3

**The invariant: no bare, suggestion-less question is EVER emitted.** Every question the engine
emits in Step 5 is wrapped in a fixed **question envelope** with three mandatory parts. This is
the AID-idiom formalization of the existing pattern in `interview-strategies.md` (the
`[From: ...] / question / suggested / [1] Accept / [2] N/A / [3] Your answer` block) plus the
mandatory rationale:

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

**Enforcement (two mechanisms, since skills are prose-executed, not machine-run):**

1. **Structural (template makes a bare question unconstructable).** The engine driver in
   `references/elicitation-engine.md` emits *only* through the envelope; `Suggested:` and `Why:`
   are non-optional fields. A turn with an empty `Suggested:` or `Why:` is a malformed emission.
2. **Self-check (pre-emit gate).** Before emitting, the engine verifies both fields are present
   and concrete; if it cannot form a concrete suggestion (genuinely open creative question), it
   still proposes its best straw-man and states the uncertainty in `Why:` -- it does NOT fall
   back to a bare question. The straw-man-first move (Family 6) guarantees a suggestion always
   exists.

The fixed D1 opener is NFR-7-compliant **by construction**: its baked-in concrete example is the
`Suggested:` and its cue ("describe the pieces the way you'd naturally name them -- I'll work
from your words") is the `Why:` (D1 rationale point 2). NFR-7 holds even for the why-probe
(propose the inferred motive back, Family 7) and is verified, not assumed, by the
concrete-example probe (Family 8). No surveyed technique tensions with NFR-7 (findings RQ-B4).

### Layers & Components

All paths under `canonical/skills/aid-interview/` (migrates to `aid-describe/` under feature-006,
D3). The engine renders to the 5 host trees via `generate-profile`; no schema or script change
is introduced by feature-002 (the `source:` marker is feature-003's, per C-1).

**Files extended in place (C-2):**

| File | Change |
|------|--------|
| `references/interview-loop.md` | `### Decide what to ask next` delegates to the five-step next-move selector; one-question-per-turn + update-after-answer rules retained |
| `references/interview-strategies.md` | `## Decide What to Ask Next -- Priority Order` becomes the gap-precedence ranking; `## Question Design Principles` folds into the move playbook + advisor stance; this file points at the new engine docs |
| `references/state-continue.md` | bare opener replaced by the D1 fixed opener, emitted **conditionally** (skipped when TRIAGE already captured it — feature-004 de-dup); CONTINUE loop body delegates to the engine |
| `references/state-triage.md` | Step 1 prompt re-pointed at the D1 opener (routing decision unchanged here -- owned by feature-004) |
| `SKILL.md` | description / state-summary prose updated to name the engine; the State Detection table and dispatch rows are unchanged |

**New reference docs (additive within the same skill dir -- not a fork):**

| New file | Concern |
|----------|---------|
| `references/elicitation-engine.md` | The engine driver: fixed opener, the five-step next-move selector, stop rule, the consumer-parameterization hooks |
| `references/move-playbook.md` | The ten moves (findings RQ-B1) + the gap-type -> move firing table |
| `references/calibration.md` | Read + ask design, the `Unknown\|Expert\|Mixed\|Novice` state, depth-shaping rules |
| `references/advisor-stance.md` | NFR-1 user-move handling + the NFR-7 question-envelope template and self-check |

(The exact file split is a Detail-phase concern; the four concerns above are the load-bearing
units and MUST each be addressed, single-concern per file per the authoring conventions.)

### Consumption Contract (features 003 + 004)

The engine is invoked by passing **three parameters**; it returns control to the host state when
its stop check fires. It does not own the host's terminal artifact.

| Parameter | Supplied by | Meaning |
|-----------|-------------|---------|
| **gap inventory** | consumer | the set of open gaps the loop draws out (REQUIREMENTS sections for full-path; the Rec-A seed doc-set for feature-003; path/recipe signals for feature-004) |
| **stop predicate** | consumer | the minimal-but-sufficient test (REQUIREMENTS all Complete/N/A; the per-element fit criteria for feature-003; route-with-confidence for feature-004) |
| **record sink** | consumer | where each confirmed answer is written (REQUIREMENTS.md sections; the seed KB docs for feature-003; the triage signal block for feature-004) |

- **feature-003 (greenfield seed authoring) CONSUMES the engine.** It supplies the Rec-A seed
  doc-set as the gap inventory, the RQ-A5 per-element fit criteria as the stop predicate, and the
  forward-authored KB docs as the record sink. feature-002 does **not** define the seed content
  model, the `source:` marker, the seed gate, or the seed<->requirements coherence *mechanism* --
  those are feature-003 (findings §6 #1, #5; this SPEC's scope boundary). The engine only
  surfaces a coherence conflict it notices (Gap rank 1) and routes it to capture-and-defer.
- **feature-004 (guided triage) CONSUMES the engine.** Triage is a thin path over the engine that
  reuses the opener, the backbone-first/walking-skeleton move (gap-type "unknown scope size"), the
  concrete-example probe, and calibration; its gap inventory is the path/recipe signals and its
  stop predicate is route-with-confidence. The **routing decision and confirmation turn**
  (`state-triage.md` Steps 2-4) remain feature-004's; feature-002 owns only the opener and loop it
  builds on. KB-context-awareness (full KB vs seed KB, FR-5) is feature-004's parameterization of
  the gap inventory.

### Out of Scope (referenced, not re-specified here)

- The seed content model, the `source: forward-authored` frontmatter marker, the >= A seed
  review gate, and the seed<->requirements coherence check -- **feature-003** (findings §6 #1, #2,
  #5; REQUIREMENTS FR-3, NFR-3, C-1).
- The full-vs-lite + recipe routing decision -- **feature-004** (REQUIREMENTS FR-5).
- The rename / skill split to `aid-describe` -- **feature-006** (D3; sequenced after 002-004).
- Build-time code<->design conformance -- **feature-005** (REQUIREMENTS FR-4).

### Definition of Done / Verification

Skills are prose-executed and not unit-tested; verification follows the AID **AI + human-review**
path (the `references/reviewer-brief.md` checklist + the `aid-specify`/work review gate at
`>= A`), supplemented by **dogfood transcripts**. The recipe-parse smoke harness is unaffected
(feature-002 adds no script).

**AC-3 -- No bare questions (NFR-7).**
- *Structural:* the question-envelope template in `references/advisor-stance.md` /
  `elicitation-engine.md` makes `Suggested:` and `Why:` non-optional; a bare question is
  unconstructable. Reviewer confirms the envelope is the only emission path.
- *Transcript scan:* in the AC-4 dogfood transcripts (below), every emitted question turn
  (every line ending in `?` that solicits a user answer) carries a non-empty `Suggested:` and
  `Why:`; the fixed opener carries its example + cue. Any bare question is a fail.
- *Reviewer checklist item:* "No suggestion-less question emitted; rationale present on every
  question, including the why-probe and the calibration ask."

**AC-4 -- Calibration + advisor behaviors (FR-2 / NFR-1).**
- *Calibration asked + adapts:* two dogfood transcripts on the same prompt -- one **expert**
  persona, one **novice** persona -- demonstrate (a) the explicit knowledge-level follow-up fired
  as an early follow-up (never turn 1) carrying an NFR-7 envelope, and (b) **demonstrable depth
  divergence** (the expert run uses fewer why-steps / lighter confirms; the novice run draws out,
  teaches, and uses more example-probes). The two transcripts read as different conversations.
- *Advisor behaviors exercised:* each of the five AC-4 user moves ("I don't know", "what do you
  recommend?", "explain pros/cons", "explain like a junior", a mistaken assertion) appears at
  least once across the transcripts, and each shows the engine guiding/recommending/explaining/
  disagreeing **while deferring the final decision** to the user.
- *Reviewer checklist items:* "Opener is the D1 what+why (never the calibration question)";
  "Calibration is read continuously AND confirmed by an early follow-up, not turn 1"; "Engine
  defers every decision; no silent assumption."

**Engine-integrity (D1 / D2 / NFR-4).**
- The interview has exactly ONE fixed turn (the D1 opener); every later turn is engine-selected
  (no hidden fixed questionnaire) -- reviewer reads `elicitation-engine.md` to confirm the loop is
  selector-driven, not a list.
- The loop halts at minimal-but-sufficient (stop check present and consumer-parameterized), not
  at the end of a list -- the `grill-me` "every branch" anti-pattern is absent (findings §3).
- **AC-10 (brownfield intact):** the existing full-path interview still completes; the engine is
  a generalization of the current spine, so existing aid-interview behavior is preserved or
  strictly improved (NFR-2).
