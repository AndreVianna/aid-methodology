# Elicitation Research Spike

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-1, §8 D-2/A-1, §9 AC-1, §10 P0 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-1 (spike scope), §8 D-2 / A-1, §9 AC-1, §10 P0

## Description

Before any elicitation design begins, run a RESEARCH spike to ground the work in proven
practice rather than guesswork. The spike surveys established Requirements Elicitation and
Domain Discovery techniques (candidates such as Domain-Driven Design / ubiquitous language,
Event Storming, User-Story Mapping, the Volere / requirements-engineering process, context
and domain modeling, JAD-style facilitation, and "five whys" / laddering) and maps each to
two questions: what a minimal-but-sufficient KB seed should contain, and how the analyst
should drive the conversation to extract it. It also runs a comparative analysis of the
web-trending "grill-me" question-driven elicitation approach (and similar variants) for
general requirements gathering — not only greenfield — assessing its strengths and weaknesses
against AID's seasoned-analyst elicitation and distilling what to adopt versus avoid. The
spike's findings gate the entire elicitation design: the seed-content set, the analyst
calibration behavior, and the guided-triage conversation all depend on its recommendations.

## User Stories

- As a downstream AID maintainer designing the elicitation engine, I want a findings report
  that recommends a proven seed-content set and analyst conversation design so that I build on
  established elicitation practice instead of guessing.
- As the work-definer (human) who will later run the skill, I want the questioning approach
  grounded in real analyst techniques so that the interview genuinely draws out the right
  information.
- As an AID maintainer evaluating "grill-me," I want a strengths/weaknesses/adopt-vs-avoid
  comparison so that we reuse good ideas in AID's own idiom and consciously avoid the bad ones.

## Priority

Must

## Acceptance Criteria

- [ ] Given the work has started, when the spike completes, then it produces a findings report
  covering classic elicitation / domain-discovery techniques. *(AC-1)*
- [ ] Given the spike's research, when the report is delivered, then it includes the "grill-me"
  comparative (strengths / weaknesses / adopt-vs-avoid). *(AC-1)*
- [ ] Given the surveyed techniques, when the report concludes, then it recommends a specific
  seed-content set and an analyst conversation design that ground FR-1 impl, FR-2 calibration,
  and FR-5 guided triage. *(AC-1)*

---

## Technical Specification

> **Nature of this feature.** This is a **RESEARCH spike**, not an implementation. Its technical
> specification is therefore the spike's **execution plan** — the research questions it must answer,
> the sources/methods it uses, the report it produces, and the bar for "done." It writes **no
> production code and no KB docs** (C-6); it produces one Markdown **findings report** that
> features 002–005 consume as their grounding input. The standard core sections (Data Model,
> Feature Flow, Layers & Components) and every conditional section (API, UI, Events, …) are **N/A**
> — there is no schema, runtime, layer, or interface here. The sections below replace them.

### Applicable Sections (override of the default section set)

| Section | Why it applies here |
|---------|---------------------|
| Research Questions | The spike's deliverable is answers, not artifacts — these are the testable units. |
| Methodology & Sources | Defines what is surveyed and how, incl. the `grill-me` comparative + A-1 fallback. |
| Deliverable: Findings Report | The single output artifact: location, structure, and consumption contract. |
| Scope Boundaries | Research/recommendation only; no code; `grill-me` inspiration-only (C-6). |
| Acceptance & Definition of Done | Operationalizes AC-1 into a checkable completion bar. |
| Dependencies & Risks | Foundations consumed (D-1/D-5) and the grill-me-thin-sources risk (A-1). |

### Research Questions

The spike answers two top-level questions (the two halves of FR-1), each decomposed into concrete,
individually-answerable sub-questions. Every answer must be **justified** (cite the surveyed
technique/source) and **actionable** (state a recommendation a downstream feature can build from).

**RQ-A — What should the minimal-but-sufficient greenfield KB seed contain?** *(grounds features 003 + 002)*

- **RQ-A1 — Validate/revise the candidate seed set.** The interview captured a candidate set:
  declared **concept-spine / ubiquitous language** (keystone) + **intended architecture** +
  **conventions & standards** + **technology stack** (FR-1; design seed §Thread-1 "Open"). Confirm,
  add to, or trim this set against established practice. Map each kept element to the existing AID KB
  doc that would carry it (e.g. `domain-glossary.md` for the concept-spine, `architecture.md`,
  `authoring-conventions.md` / `coding-standards.md`, `technology-stack.md`) and to its `kb-category`.
- **RQ-A2 — What is explicitly excluded and why.** Confirm the exclusion of the code-derived
  `aid-discover` docs that have no greenfield source (`module-map.md`, `test-landscape.md`, and the
  as-built portions of others) — there is no code yet. State the sufficiency rationale.
- **RQ-A3 — Declared vs harvested spine.** AID's f004 essence/concept-spine engine *harvests* the
  Concept Spine from source (`domain-glossary.md` "## Concept Spine"; brownfield deep-dive). Greenfield
  must **declare** it up front. Determine what changes when the spine is authored from intent rather
  than mined — what makes a declared spine sound, and what minimum it must pin down to be load-bearing.
- **RQ-A4 — Domain-adaptive shape.** Like `aid-discover`'s domain-driven doc-set
  (`pipeline-contracts.md`), the seed's exact shape should adapt to the project's domain. Recommend
  how the seed flexes by domain rather than being a fixed checklist, and what stays invariant.
- **RQ-A5 — Sufficiency test.** Define an objective bar for "minimal-but-sufficient": what must the
  seed contain so `aid-specify` runs with **zero KB-gap loopbacks** (the AC-2 measure for f003) — and
  what is deferable to later phases.

**RQ-B — How should the analyst drive the conversation to elicit it?** *(grounds features 002 + 004)*

- **RQ-B1 — Elicitation moves.** From the surveyed techniques, distill the concrete conversational
  moves (question patterns, sequencing, gap-detection, structure-proposing) that draw out each seed
  element — the playbook the FR-2 "seasoned analyst" enacts.
- **RQ-B2 — Calibration.** How to assess the user's knowledge level/type early and shape question
  depth/style accordingly (FR-2) — grounded in real facilitation practice, not invented.
- **RQ-B3 — Triage elicitation.** How the same elicitation engine draws out the path-deciding (full
  vs lite) and recipe-deciding signals (FR-5), in both full-KB and seed-KB contexts.
- **RQ-B4 — Suggested-answer-with-rationale.** How surveyed techniques support (or tension with)
  AID's NFR-7 invariant that **every** question carries a concrete suggested answer + rationale —
  confirm the invariant survives the new dialogue design and note any technique that strengthens it.

### Methodology & Sources

**Method.** Desk research (literature/web survey) → structured comparison → synthesis into
recommendations. No interviews, no prototypes, no code. Each surveyed technique is assessed on a
fixed rubric so the comparison is apples-to-apples:

> **per-technique rubric:** *what KB-seed content it surfaces (→ RQ-A)* · *what conversational moves
> it contributes (→ RQ-B)* · *fit with AID's one-decision-at-a-time, human-gated, propose-don't-assume
> process (NFR-1/NFR-7)* · *adopt / adapt / avoid verdict with reason.*

**Technique families to survey** (the FR-1 candidates — treat as a starting set, not a ceiling):

| Family | What the spike mines it for |
|--------|------------------------------|
| Domain-Driven Design / **ubiquitous language** | Declared concept-spine sourcing; how ubiquitous language is established up front (RQ-A1/A3). |
| **Event Storming** | Eliciting domain behavior/flows before code; structure-proposing moves (RQ-A4, RQ-B1). |
| **User-Story Mapping** | Eliciting scope/shape of work; framing for triage sizing (RQ-B1, RQ-B3). |
| **Volere / RE process** | Canonical requirements-elicitation framework; sufficiency + completeness bars (RQ-A5). |
| **Context & domain modeling** | What "intended architecture" + boundaries to pin in a seed (RQ-A1). |
| **JAD-style facilitation** | Facilitator moves: guiding, gap-filling, disagreeing, deferring the call (RQ-B1/B2, NFR-1). |
| **Five-whys / laddering** | Drawing out the *why* behind stated intent; calibrating depth (RQ-B1/B2). |

**Comparative — `grill-me` and variants** *(the distinct second half of FR-1, AC-1)*. Research the
web-trending **`grill-me`** question-driven elicitation approach and similar variants. Deliver:
(1) what it is and how it works; (2) **strengths + weaknesses**; (3) a **head-to-head comparison with
AID's seasoned-analyst elicitation** for **general requirements gathering — not only greenfield**;
(4) an explicit **adopt-vs-avoid** list — which ideas to reimplement in AID's own idiom and which to
consciously reject. Per **C-6**, adoption is **inspiration-only**: no copying of `grill-me` prompts or
code, reimplement in AID's state machine, and respect its license/attribution (capture the license +
source URL in the report).

**Fallback (A-1).** If solid public material on `grill-me` is thin, do not block: lean on the
established RE / domain-discovery literature above and treat the `grill-me` comparative as best-effort
— but **state explicitly in the report** what was/wasn't found and how the fallback was applied, so the
gap is visible to downstream features rather than silently papered over.

### Deliverable: Findings Report

**One artifact:** a structured Markdown findings report at
`.aid/work-001-aid-interview-improvements/features/feature-001-elicitation-research-spike/findings.md`
(feature-scoped; referenced by features 002–005 as their grounding input). Written to AID's
dual-audience authoring standard (`authoring-conventions.md`).

**Required structure:**

1. **Summary & Recommendations** — the headline call: the recommended seed-content set and the
   recommended analyst conversation design, in one scannable place.
2. **Technique Survey** — one entry per surveyed family, each scored on the per-technique rubric above.
3. **`grill-me` Comparative** — what-it-is · strengths/weaknesses · head-to-head vs AID · adopt-vs-avoid
   list · license/attribution note · (if A-1 fired) the fallback disclosure.
4. **Recommendation A — Seed-Content Set** — the validated/revised seed (answers RQ-A1..A5): each
   element, the KB doc + `kb-category` that carries it, the declared-spine guidance (RQ-A3), the
   domain-adaptivity rule (RQ-A4), the exclusions + rationale (RQ-A2), and the sufficiency bar (RQ-A5).
   **Form it so feature-003 can specify the seed model and feature-002 the engine directly from it.**
5. **Recommendation B — Analyst Conversation Design** — the elicitation playbook (answers RQ-B1..B4):
   the conversational moves, the calibration approach, the triage-elicitation approach, and how NFR-7
   (suggested-answer-with-rationale) is honored. **Form it so feature-002 (engine) and feature-004
   (triage) can specify from it.**
6. **Open Questions / Risks for Downstream** — anything the spike could not settle, flagged for
   features 002–005 (e.g. an A-2 schema gap if the seed cannot be expressed in the existing KB schema).
7. **Sources** — every cited technique/article/repo with URL + access date + license where applicable.

**Consumption contract (traceability for the PLAN):** §4 → features 003 & 002 · §5 → features 002 & 004
· the report as a whole gates the design of features 002–005 (P0 in §10; D-2). No downstream
elicitation-design feature is specified until this report is delivered and accepted.

### Scope Boundaries

- **Research and recommendation only.** No production code, no KB docs, no skill edits, no schema
  changes are produced by this feature — those are features 002–005's work.
- **`grill-me` is inspiration-only (C-6).** Conclusions about `grill-me` feed AID's own idiom; no
  prompt/code reuse; license/attribution respected.
- **No tooling or test changes.** The spike does not touch `lint-frontmatter.sh` / `build-kb-index.sh`
  / `kb-freshness-check.sh` (that is the C-1 marker work, owned later by feature-003/005).
- The spike **recommends**; the human and downstream `aid-specify` runs **decide**. It does not
  finalize the seed schema or the skill design — it grounds them.

### Acceptance & Definition of Done

Operationalizes **AC-1**. The spike is **done** when `findings.md` exists at the path above and:

- [ ] **DoD-1** — Covers the classic elicitation / domain-discovery technique families (§Technique
  Survey populated, each scored on the rubric). *(AC-1 clause 1)*
- [ ] **DoD-2** — Includes the `grill-me` comparative with **strengths / weaknesses / adopt-vs-avoid**
  (or, if A-1 fired, the explicit fallback disclosure of what was/wasn't found). *(AC-1 clause 2)*
- [ ] **DoD-3** — Answers **all** RQ-A and RQ-B sub-questions, each with a **justified, actionable**
  answer (cites a source/technique; states a recommendation).
- [ ] **DoD-4** — Delivers a **specific, justified** recommended **seed-content set** (Rec A) and
  **analyst conversation design** (Rec B), forming each so features 002/003/004/005 can be specified
  directly from it. *(AC-1 clause 3; grounds FR-1 impl, FR-2 calibration, FR-5 triage)*
- [ ] **DoD-5** — Flags any A-2 (schema-expressibility) gap and any unresolved question for downstream,
  rather than leaving it implicit.
- [ ] **DoD-6** — Report passes the artifact review gate at the work's minimum grade (≥ A) — a
  *document* review for completeness/grounding/actionability, not a code review.

### Dependencies & Risks

- **D-1 (consumed).** Builds on work-001 foundations now on master: f001 (frontmatter/`source:`
  schema, incl. the `forward-authored` marker the seed will use), f003 (concern-model / doc-set),
  **f004 (concept-spine / essence engine)** — the spike studies the *harvested* spine to recommend the
  *declared* one — and f007 (freshness).
- **D-5 (surfaced for downstream).** NFR-3's "same KB review gate" reuses `aid-discover`'s review
  subsystem (`aid-discover/references/{state-review,reviewer-brief,document-expectations}.md`). The
  spike does not integrate it, but **its seed-content recommendation (Rec A) should note** what those
  expectations imply for a greenfield doc-set so feature-003 can wire the gate cleanly.
- **Risk — thin `grill-me` sources (A-1).** Mitigated by the literature fallback + explicit disclosure
  (DoD-2). Does not block the spike's primary RE/domain-discovery findings.
- **Risk — A-2 schema gap.** If the existing KB schema cannot express the recommended seed, the spike
  surfaces it (DoD-5) for feature-003 / a follow-on `aid-specify` decision rather than resolving it here.
