# Technique Survey -- Classic Elicitation & Domain-Discovery Families

> **What this note is.** A standalone research artifact for task-001 of the elicitation
> research spike (feature-001). It surveys established Requirements-Elicitation and
> Domain-Discovery technique families, scores each on the feature's fixed per-technique
> rubric, and maps each finding to the spike's Research Questions (RQ-A1..A5, RQ-B1..B4).
> It is an **input** consumed by task-003, which lifts it into `findings.md` Section 2 and
> answers the RQs from it. It is **research only** -- no production code, KB doc, skill, or
> schema change is produced here (Scope Boundary C-6).
>
> **Audience.** Two readers at once: a junior maintainer who has never run an elicitation
> workshop, and the downstream AID agent that will specify features 002-005 from the
> synthesis. Plain language, tables over prose, every claim carries a real source.

## Contents

- [Method](#method)
- [The Rubric and the RQ Map](#the-rubric-and-the-rq-map)
- [Family 1 -- Domain-Driven Design / Ubiquitous Language](#family-1--domain-driven-design--ubiquitous-language)
- [Family 2 -- Context & Domain Modeling (Bounded Context / Context Mapping)](#family-2--context--domain-modeling-bounded-context--context-mapping)
- [Family 3 -- Event Storming](#family-3--event-storming)
- [Family 4 -- User-Story Mapping](#family-4--user-story-mapping)
- [Family 5 -- Volere / Requirements-Engineering Process](#family-5--volere--requirements-engineering-process)
- [Family 6 -- JAD-style Facilitation](#family-6--jad-style-facilitation)
- [Family 7 -- Five-Whys / Laddering](#family-7--five-whys--laddering)
- [Family 8 -- Example Mapping / Specification by Example (bonus)](#family-8--example-mapping--specification-by-example-bonus)
- [Cross-family Summary Table](#cross-family-summary-table)
- [Sources](#sources)

---

## Method

Desk research (web/literature survey) grounded in the canonical source for each family
(book author, originator's own writing, or a recognized reference) plus at least one
secondary practitioner reference. Each family is scored on the same four-dimension rubric
so the comparison is apples-to-apples (eight families compared on one rubric -- well past
the two-alternative floor the task requires). Every factual claim cites a real URL with an
access date in the [Sources](#sources) section; all access dates are **2026-06-27**.

Where a technique was born outside software (Five-Whys, laddering, JAD) the survey reports
its origin honestly and judges only its **elicitation** value, not its original purpose.

---

## The Rubric and the RQ Map

Each family is scored on the feature's fixed rubric:

| Dim | Question |
|-----|----------|
| (a) **KB-seed content** | What seed/document content does the technique surface? Feeds **RQ-A** (A1 validate seed set; A2 exclusions; A3 declared-vs-harvested spine; A4 domain-adaptive shape; A5 sufficiency bar). |
| (b) **Conversational moves** | What concrete questioning/sequencing moves does it contribute? Feeds **RQ-B** (B1 elicitation moves; B2 calibration; B3 triage elicitation; B4 suggested-answer-with-rationale). |
| (c) **AID-process fit** | Does it fit NFR-1 (one-decision-at-a-time, human-gated, propose-don't-assume) and NFR-7 (every question carries a concrete suggested answer + rationale)? |
| (d) **Verdict** | **adopt** (use largely as-is) / **adapt** (reshape into AID's idiom) / **avoid** (do not use), with a reason. |

AID-anchor reminder for dimension (a): the candidate greenfield seed is **concept-spine /
ubiquitous language** -> `domain-glossary.md` (kb-category `primary`, C4); **intended
architecture** -> `architecture.md` (C1); **conventions & standards** ->
`authoring-conventions.md` / `coding-standards.md` (C3); **technology stack** ->
`technology-stack.md` (C0). Families are mapped onto these docs below.

---

## Family 1 -- Domain-Driven Design / Ubiquitous Language

**What it is.** Eric Evans' practice (2003) of building one rigorous, shared language
between domain experts and developers, used identically in conversation, models, and the
source code itself -- a *ubiquitous* language scoped to a bounded context. Martin Fowler's
bliki gives the canonical short definition.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Directly sources the **concept-spine / ubiquitous language** seed element -> `domain-glossary.md` (C4). UL says the seed must pin: the load-bearing nouns/verbs of the domain, each defined *as this project uses it* (not generic), with relationships. This is exactly AID's existing "Concept Spine" section shape. |
| (b) Moves | "Define the term as you use it, on first use, and refuse synonyms." The analyst's move is **term-capture + disambiguation**: when the user uses a word, ask "is this the same as X you said earlier?" and pin one canonical label. Surfaces hidden glossary entries by listening for nouns. |
| (c) AID fit | Strong. UL is propose-then-confirm by nature (you propose a definition, the expert corrects it) -- matches propose-don't-assume. The "one canonical term per concept" decision is a clean one-decision-at-a-time gate. Supports NFR-7: a proposed definition *is* a suggested answer; its rationale is "this is how you used it / this is the established meaning." |
| (d) **Verdict** | **ADOPT.** It is the keystone of the seed. The declared greenfield spine is UL authored from *intent* rather than mined from code -- see RQ-A3 note below. |

**RQ map:** **RQ-A1** (validates concept-spine as the keystone seed element, doc =
`domain-glossary.md`, C4) - **RQ-A3** (the declared-spine question: greenfield must
*declare* the UL up front, since there is no code to mine; a sound declared spine pins each
keystone term + its definition-as-used + its relationships, the same minimum the harvested
spine reaches but authored from intent) - **RQ-B1** (term-capture / disambiguation move) -
**RQ-B4** (a proposed definition is a suggested-answer-with-rationale).

---

## Family 2 -- Context & Domain Modeling (Bounded Context / Context Mapping)

**What it is.** The *strategic* half of DDD: a **Bounded Context** draws a border around
where one model/language is valid; a **Context Map** sketches the relationships between
contexts (Partnership, Customer/Supplier, Conformist, Open Host Service / Published
Language, Anti-Corruption Layer, Separate Ways). Fowler's bliki and the Avanscoperta
reference treat the map as a quick sketch, not a heavyweight diagram.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Sources the **intended architecture** seed element -> `architecture.md` (C1): what the major parts are, where the boundaries fall, and how they relate. Context-map relationship vocabulary gives a ready checklist for "what boundaries to pin in a seed" without forcing a full design. |
| (b) Moves | "Name the boundary, then name the relationship across it." The analyst move is **boundary-elicitation**: ask where one model stops and another starts, and how they talk. Good for separating "what we build" from "what we integrate with." |
| (c) AID fit | Good but must be **bounded** (pun intended). Full strategic DDD is a design activity; a seed only needs the *intended* boundaries and their relationships at sketch altitude, proposed for confirmation. Fits propose-don't-assume if the analyst proposes a boundary sketch and lets the human gate it. |
| (d) **Verdict** | **ADAPT.** Take the boundary + relationship vocabulary as a lightweight prompt for the architecture seed; **avoid** importing tactical DDD (entities, aggregates, value objects) into a seed -- that is downstream design, not minimal-but-sufficient seed content (RQ-A2 exclusion logic). |

**RQ map:** **RQ-A1** (intended-architecture seed element, doc = `architecture.md`, C1) -
**RQ-A2** (tactical-DDD detail is explicitly *excluded* from the seed as premature design) -
**RQ-A4** (domain-adaptive shape: the *number* and *kind* of boundaries flex by domain;
what stays invariant is "name boundaries + their relationships") - **RQ-B1**
(boundary-elicitation move).

---

## Family 3 -- Event Storming

**What it is.** Alberto Brandolini's workshop format (c. 2013): a long timeline and colored
sticky notes; participants brainstorm **domain events** (orange notes) first, in the
language of both technical and non-technical stakeholders, surfacing how the business works
fast (hours). "Big Picture" Event Storming runs deliberately *before and apart from*
software design.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Surfaces **domain behavior / flows** -- the verbs and sequence of the domain. Feeds the concept-spine (events name domain verbs) and the intended-architecture seed (event flow hints at boundaries). Less about static vocabulary, more about dynamics. |
| (b) Moves | Its core contribution is a **structure-proposing** move: "let's list what *happens* in the domain, as events in past tense, then order them." For a one-on-one AI interview this becomes "walk me through what happens, step by step" then the analyst proposes the ordered event line back for confirmation. Strong gap-detection: gaps in the timeline are visible holes to probe. |
| (c) AID fit | Partial. The full method is a **group, co-located, sticky-note** ritual -- AID's elicitation is a **one-on-one, text** conversation with an AI analyst, so the literal format does not transfer. But the *event-first, propose-the-timeline-back* move fits propose-don't-assume well and is naturally human-gated (the human confirms each ordering). |
| (d) **Verdict** | **ADAPT.** Reuse the *event-first elicitation move* and the timeline-gap-probe; **drop** the workshop apparatus (room, 15-30 people, sticky walls). Reframe as a sequenced "what happens next?" elicitation thread the AI analyst proposes and the human gates. |

**RQ map:** **RQ-A1/A4** (domain-behavior content; the event flow is one of the
domain-adaptive shapes the seed can take for process-heavy domains) - **RQ-B1**
(event-first, propose-the-timeline-back move; timeline-gap detection) - **RQ-B3** (an event
timeline quickly reveals scope size -> a triage signal for full-vs-lite).

---

## Family 4 -- User-Story Mapping

**What it is.** Jeff Patton's technique (codified 2014): arrange user activities
left-to-right as the **backbone** (narrative order), hang detailed stories as **ribs**
beneath each, and slice the thinnest end-to-end **walking skeleton** (Cockburn's term) as
the first viable release.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Surfaces the **scope and shape** of the work -- what the user is trying to do, end to end. Less a KB-seed source, more a **scoping** instrument: it frames how big the work is and what the minimal end-to-end slice is. |
| (b) Moves | The **backbone-first** move: "tell me the high-level steps of the user's journey in order, before any detail." Then "which of these is essential for a first working version?" -- a direct prioritization / sizing conversation. |
| (c) AID fit | Good for triage, not for seed content. The walking-skeleton question is a natural **path-sizing** move (small end-to-end slice -> maybe lite; sprawling multi-activity backbone -> full). Propose-don't-assume fits: propose the backbone back, let the human reorder/gate. |
| (d) **Verdict** | **ADAPT.** Adopt the backbone-first + walking-skeleton **sizing move** for triage (full-vs-lite); do **not** treat the full story map as seed content -- it is governance/planning shape that belongs to the pipeline (REQUIREMENTS / SPEC), not the KB seed. |

**RQ map:** **RQ-B1** (backbone-first elicitation move) - **RQ-B3** (the
walking-skeleton/backbone-size question is a primary triage signal for full-vs-lite path and
recipe sizing) - feeds **RQ-A2** indirectly (story-map detail is *excluded* from the seed as
pipeline content, reinforcing the exclusion rationale).

---

## Family 5 -- Volere / Requirements-Engineering Process

**What it is.** Suzanne & James Robertson's requirements framework (*Mastering the
Requirements Process*, 1st ed. 1999) plus the **Volere template** and the atomic
**requirement shell** ("snow card"): each requirement carries a description, rationale,
**fit criterion** (a measurable test written *as you write the requirement*), originator,
and type. Volere also defines a taxonomy of non-functional requirement types.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Contributes the **sufficiency + completeness** discipline rather than a content area. The fit-criterion idea ("a requirement isn't done until it has a measurable pass test") is the model for AID's **sufficiency bar** (RQ-A5): the seed is minimal-but-sufficient when each kept element has an objective "is this pinned down enough?" test. The NFR taxonomy is a checklist of what a seed might need to mention (security, performance, usability...) but most is deferred to later phases for a *seed*. |
| (b) Moves | "Capture the **rationale** with the requirement, and a **fit criterion** before moving on." The analyst move is **rationale + testability probing**: for each elicited element, ask "why does this matter?" and "how will we know it's satisfied?" |
| (c) AID fit | Very strong on NFR-7. Volere's "every requirement has a rationale" is essentially AID's "every question carries a rationale," arrived at independently -- Volere is **citable external validation** that NFR-7 is sound practice. The shell's one-requirement-at-a-time discipline matches one-decision-at-a-time. |
| (d) **Verdict** | **ADAPT.** Adopt the **fit-criterion -> sufficiency-bar** mapping and the rationale-always discipline (validates NFR-7). **Avoid** importing the heavyweight full template/snow-card schema into the seed -- the seed is not a requirements spec, so use Volere's *principles*, not its document format. |

**RQ map:** **RQ-A5** (fit-criterion is the model for the objective minimal-but-sufficient
bar; "the seed element is sufficient when it has a pass test") - **RQ-B1** (rationale +
testability probe) - **RQ-B4** (Volere's rationale-always rule is external corroboration that
NFR-7's suggested-answer-with-rationale invariant is established practice, not invented).

---

## Family 6 -- JAD-style Facilitation

**What it is.** Joint Application Development (IBM, late 1970s): structured, facilitator-led
workshops bringing users, SMEs, analysts, and IT together to define requirements. Defines
clear **roles** (facilitator, executive sponsor, users, IT reps, scribe, observer) and
facilitator duties: drive an agenda, mediate disputes, ensure quiet voices are heard, build
interim deliverables, and stay impartial. Often starts from a pre-built **straw man** to
focus the session.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | No specific content area -- JAD is about *how* you elicit, not *what*. Its contribution is process, mapped almost entirely to dimension (b). |
| (b) Moves | The richest source of **facilitator moves** for the analyst persona (FR-2 "seasoned analyst"): (1) **straw-man-first** -- open with a proposed draft, not a blank page (this *is* propose-don't-assume + NFR-7); (2) **agenda/sequencing** -- one structured topic at a time; (3) **dispute mediation** -- surface disagreement, then defer the call to the decision-owner; (4) **draw out the quiet** -- actively probe rather than accept silence; (5) **scribe** -- capture decisions immediately (the AID analog: write to STATE/REQUIREMENTS as you go). |
| (c) AID fit | Excellent, and the closest match to AID's intended analyst behavior. The straw-man move is literally NFR-7 (propose an answer + rationale, let the human gate). "Mediate then defer the decision to the owner" is exactly AID's human-gated, propose-don't-assume stance. One-topic-at-a-time agenda = one-decision-at-a-time. |
| (d) **Verdict** | **ADOPT** (the facilitator-move set), reframed for a one-on-one AI-to-human dialogue. The single human plays sponsor + user; the AI plays facilitator + scribe + straw-man author. Drop the multi-room logistics; keep the move vocabulary. |

**RQ map:** **RQ-B1** (the core facilitator-move playbook the FR-2 analyst enacts) -
**RQ-B2** (calibration: JAD's "draw out the quiet / read the room" duty maps to assessing
the user and adjusting probe depth) - **RQ-B4** (the straw-man move *is* the mechanism that
delivers NFR-7 -- every question opens with a suggested answer + rationale) - **NFR-1**
(mediate-then-defer = human-gated decision ownership).

---

## Family 7 -- Five-Whys / Laddering

**What it is.** Two related "ask why repeatedly" probes. **Five-Whys** (Sakichi Toyoda /
Toyota Production System) iteratively asks "why?" to walk from a symptom to a root cause;
Toyota itself notes it was first used to understand *why a new feature was needed* -- an
elicitation use, not only defect analysis. **Laddering** (means-end theory, Reynolds &
Gutman) is a semi-structured interview that climbs a "ladder of abstraction" from concrete
attributes -> consequences -> core values by repeatedly asking "why is that important to
you?", and elicits the starting attributes via triadic sorting ("which two of these three
are alike, and how do they differ from the third?").

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Surfaces the **why behind stated intent** -- the rationale and goals that belong in `decisions.md` (extension, D dimension) and that sharpen the concept-spine and architecture seed by exposing the real driver. Laddering's attribute level also helps name concrete features; its value level helps name the project's actual goal. |
| (b) Moves | The **why-laddering probe**: when the user states a want, climb 2-3 "why does that matter?" steps to reach the real need; stop at the terminal value (do not over-drill). Triadic sorting is a useful **disambiguation move** when the user lists several similar items. |
| (c) AID fit | Good in moderation, with a documented caution. Five-Whys is widely **criticized as too shallow / arbitrary** (Toyota's own Minoura) -- a single linear chain can miss multiple causes and bias toward the first answer. So adopt it as a *bounded* probe, not a mechanical "always ask five times." Fits propose-don't-assume only if the analyst proposes the inferred "why" back for confirmation rather than asserting it (avoids putting words in the user's mouth). |
| (d) **Verdict** | **ADAPT.** Adopt a **bounded why-probe** (climb until the rationale is clear, typically 2-3 steps, then confirm) and triadic-sort disambiguation; **avoid** the rote "exactly five whys" ritual and avoid single-chain over-narrowing -- propose the inferred motive back rather than asserting it. |

**RQ map:** **RQ-A1/A3** (the elicited "why" enriches the declared spine and gives
`decisions.md` content) - **RQ-B1** (bounded why-probe; triadic-sort disambiguation) -
**RQ-B2** (calibration: how far to climb depends on the user's depth -- stop sooner with an
expert who states the value directly) - **RQ-B4** (propose-the-inferred-why-back keeps the
suggested-answer-with-rationale invariant intact instead of interrogating blindly).

---

## Family 8 -- Example Mapping / Specification by Example (bonus)

**What it is.** Matt Wynne's **Example Mapping** (Cucumber/BDD): in ~25 minutes the "three
amigos" break a story into colored cards -- yellow **story**, blue **rules** (acceptance
criteria), green **concrete examples** under each rule, and red **questions** for anything
nobody can answer in the room. The red-card rule -- "turn an unknown unknown into a known
unknown, capture it and move on" -- is the load-bearing idea. Added because it is a genuinely
load-bearing, modern, conversation-driven elicitation technique directly relevant to AID's
question-with-suggested-answer model and to capturing open questions for downstream.

| Dim | Finding |
|-----|---------|
| (a) KB-seed | Surfaces **concrete examples + rules**, which sharpen the ubiquitous language (examples force precise definitions) and feed the sufficiency test. Its biggest contribution is the **red-card / open-question** discipline -> maps cleanly onto AID's "Open Questions / Risks for Downstream" and the STATE.md Q&A-pending backlog. |
| (b) Moves | The **rule -> example -> question** move: for any claim, ask for a concrete example; when consensus fails, *capture the question and move on* instead of stalling. Excellent **gap-detection** and pace control. |
| (c) AID fit | Very strong. "Capture the open question and move on" is exactly how AID defers a decision it cannot settle (NFR-1 human-gating + the spike's own DoD-5 "flag for downstream"). Concrete-example probing supports propose-don't-assume (an example is a checkable proposal). |
| (d) **Verdict** | **ADAPT.** Adopt the **concrete-example probe** and the **red-card open-question capture** (reframed as STATE.md Q&A entries / downstream-risk flags); drop the physical card ritual and the three-person quorum (AID is one human + AI). |

**RQ map:** **RQ-A5** (concrete examples are a sufficiency test -- if you cannot give an
example, the element is under-pinned) - **RQ-B1** (rule->example->question move,
gap-detection) - **RQ-B3** (example coverage reveals scope -> triage signal) - **RQ-B4 /
DoD-5** (the capture-and-defer move is the mechanism for honoring human-gating and flagging
open questions downstream).

---

## Cross-family Summary Table

| # | Family | Primary KB-seed contribution (a) | Signature move (b) | Verdict (d) | Strongest RQ links |
|---|--------|----------------------------------|--------------------|-------------|--------------------|
| 1 | DDD / Ubiquitous Language | Concept-spine -> `domain-glossary.md` (C4) | Term-capture + disambiguation | **ADOPT** | A1, A3, B1, B4 |
| 2 | Context & Domain Modeling | Intended architecture -> `architecture.md` (C1) | Boundary + relationship elicitation | **ADAPT** | A1, A2, A4, B1 |
| 3 | Event Storming | Domain behavior / flows | Event-first, propose-timeline-back | **ADAPT** | A1, A4, B1, B3 |
| 4 | User-Story Mapping | Scope/shape (sizing, not seed) | Backbone-first + walking-skeleton | **ADAPT** | B1, B3 (A2) |
| 5 | Volere / RE process | Sufficiency bar (fit criterion) | Rationale + testability probe | **ADAPT** | A5, B1, B4 |
| 6 | JAD-style Facilitation | (process, not content) | Straw-man-first; mediate-then-defer | **ADOPT** | B1, B2, B4, NFR-1 |
| 7 | Five-Whys / Laddering | The "why" -> spine + `decisions.md` (D) | Bounded why-probe; triadic sort | **ADAPT** | A1, A3, B1, B2, B4 |
| 8 | Example Mapping / SbE | Concrete examples + open-questions | Example probe; capture-and-defer | **ADAPT** | A5, B1, B3, B4, DoD-5 |

**Headline for task-003.** The seed-content backbone comes from **DDD/UL** (the keystone
spine), **Context Modeling** (boundaries, lightly), and the **Volere sufficiency
discipline**; the analyst conversation design comes mainly from **JAD facilitation**
(straw-man-first, mediate-then-defer) reinforced by **Five-Whys/Laddering** (bounded
why-probe + calibration), **Event Storming** (event-first sequencing), **User-Story Mapping**
(triage sizing), and **Example Mapping** (concrete-example probe + capture-and-defer for
open questions). Two families validate AID's invariants externally: **Volere** and **JAD**
both independently corroborate NFR-7 (suggested-answer/straw-man + always-a-rationale),
showing the invariant is established practice rather than an AID invention.

---

## Sources

All URLs accessed **2026-06-27**. Licenses noted where the source is a reusable artifact;
narrative articles carry standard site copyright (reference-only, no content copied).

| # | Family | Source (title) | URL | License / note |
|---|--------|----------------|-----|----------------|
| 1 | DDD / UL | Martin Fowler, bliki: *Ubiquitous Language* | https://martinfowler.com/bliki/UbiquitousLanguage.html | Site copyright; reference-only |
| 2 | DDD / UL | Martin Fowler, bliki: *Domain Driven Design* | https://martinfowler.com/bliki/DomainDrivenDesign.html | Site copyright; reference-only |
| 3 | DDD / UL | Eric Evans, *Domain-Driven Design Reference* (definitions, 2015) | https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf | CC BY (per the Reference's stated license) |
| 4 | DDD / UL | Agile Alliance glossary: *Ubiquitous Language* | https://agilealliance.org/glossary/ubiquitous-language/ | Site copyright; reference-only |
| 5 | Context modeling | Martin Fowler, bliki: *Bounded Context* | https://martinfowler.com/bliki/BoundedContext.html | Site copyright; reference-only |
| 6 | Context modeling | Avanscoperta: *Context Mapping in Domain-Driven Design* | https://www.avanscoperta.it/en/context-mapping/ | Site copyright; reference-only |
| 7 | Event Storming | Alberto Brandolini, *EventStorming* (official site) | https://www.eventstorming.com/ | Site copyright; reference-only |
| 8 | Event Storming | Qlerify: *What is Big Picture Event Storming* | https://www.qlerify.com/event-storming-concepts/what-is-big-picture-event-storming | Site copyright; reference-only |
| 9 | User-Story Mapping | Jeff Patton, *The New Backlog is a Map* | https://jpattonassociates.com/the-new-backlog/ | Site copyright; reference-only |
| 10 | User-Story Mapping | Jeff Patton, *Story Map Concepts* (PDF) | https://jpattonassociates.com/wp-content/uploads/2015/03/story_mapping.pdf | Site copyright; reference-only |
| 11 | Volere / RE | Volere: *Requirements Specification Template* | https://www.volere.org/templates/volere-requirements-specification-template/ | Volere template license (free for use, attribution to the Robertsons) |
| 12 | Volere / RE | Volere template Edition 16, 2012 (PDF mirror) | https://www.cs.uic.edu/~i440/VolereMaterials/templateArchive16/c%20Volere%20template16.pdf | Volere template license (attribution required) |
| 13 | JAD | TechTarget: *What is Joint Application Development (JAD)?* | https://www.techtarget.com/searchsoftwarequality/definition/JAD | Site copyright; reference-only |
| 14 | JAD | Wikipedia: *Joint application design* | https://en.wikipedia.org/wiki/Joint_application_design | CC BY-SA 4.0 |
| 15 | Five-Whys | Wikipedia: *Five whys* (origin, TPS, Minoura critique) | https://en.wikipedia.org/wiki/Five_whys | CC BY-SA 4.0 |
| 16 | Laddering | Reynolds & Gutman / SAGE: *An Adaptation of the Laddering Interview Method* (PDF) | https://journals.sagepub.com/doi/pdf/10.1177/1094428105280118 | Publisher copyright; reference-only |
| 17 | Laddering | UXmatters: *Laddering -- A Research Interview Technique for Uncovering Core Values* | https://www.uxmatters.com/mt/archives/2009/07/laddering-a-research-interview-technique-for-uncovering-core-values.php | Site copyright; reference-only |
| 18 | Example Mapping | Matt Wynne / Cucumber: *Introducing Example Mapping* | https://cucumber.io/blog/bdd/example-mapping-introduction/ | Site copyright; reference-only |
| 19 | Example Mapping | Cucumber docs: *Example Mapping* | https://cucumber.io/docs/bdd/example-mapping/ | Site copyright; reference-only |

> Note: licenses are recorded for the spike's C-6 attribution discipline. This survey
> paraphrases and cites; it copies no prompts or code from any source. The `grill-me`
> comparative (the other C-6-sensitive artifact) is owned by a parallel task
> (`grillme-comparative.md`) and is intentionally out of scope here.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | task-001 (RESEARCH) | Initial technique survey: 8 families rubric-scored + RQ-mapped + sourced. |
