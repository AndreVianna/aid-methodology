# Elicitation Research Spike -- Findings & Recommendations

> **What this is.** The single gated deliverable of feature-001 (the elicitation
> research spike). It synthesizes two research notes -- `research/technique-survey.md`
> (8 elicitation / domain-discovery families, rubric-scored) and
> `research/grillme-comparative.md` (the `grill-me` head-to-head) -- into a recommended
> **seed-content set** (Recommendation A) and a recommended **analyst conversation
> design** (Recommendation B), each formed so the downstream elicitation features can be
> specified directly from it. It answers every research question (RQ-A1..A5, RQ-B1..B4)
> with a justified, actionable answer, and flags every unresolved risk for features
> 002-005.
>
> **Audience.** Two readers at once: a junior maintainer who has never run an
> elicitation workshop, and the downstream AID agent that will specify features 002-005.
> Plain language, tables over prose, every recommendation grounded in a surveyed
> technique or a sourced requirement.
>
> **Scope (C-6).** Research and recommendation only. No production code, KB doc, skill,
> tooling, or schema change is produced here -- those are features 002-005's work. The
> two `research/*.md` notes remain as standalone appendices; this report is the gated
> artifact. `grill-me` is treated as inspiration-only: no prompt or code is copied; its
> license is captured in Section 7.

## Contents

- [1. Summary & Recommendations](#1-summary--recommendations)
- [2. Technique Survey](#2-technique-survey)
- [3. grill-me Comparative](#3-grill-me-comparative)
- [4. Recommendation A -- Seed-Content Set (RQ-A1..A5)](#4-recommendation-a----seed-content-set-rq-a1a5)
- [5. Recommendation B -- Analyst Conversation Design (RQ-B1..B4)](#5-recommendation-b----analyst-conversation-design-rq-b1b4)
- [6. Open Questions / Risks for Downstream](#6-open-questions--risks-for-downstream)
- [7. Sources](#7-sources)
- [Change Log](#change-log)

---

## 1. Summary & Recommendations

The spike surveyed **8 established elicitation / domain-discovery technique families** on
one fixed rubric and ran a **head-to-head comparison** of the web-trending `grill-me`
skill against AID's seasoned-analyst elicitation. Two findings dominate:

1. **The seed backbone is the declared ubiquitous language.** Domain-Driven Design's
   ubiquitous language is the keystone seed element; intended architecture, conventions,
   and technology stack hang off it; the elicited "why" extends it. The brownfield
   *harvested* spine (AID f004) and the greenfield *declared* spine reach the **same
   minimum** -- the difference is that greenfield authors it from intent instead of
   mining it from code.
2. **AID's elicitation invariants are externally validated, not invented.** Both the
   **Volere** requirements process ("every requirement carries a rationale") and **JAD**
   facilitation (open with a straw-man, never a blank page) independently corroborate
   NFR-7 (every question carries a suggested answer + rationale). `grill-me` *converges*
   on AID's two best instincts (one-question-at-a-time, a recommended answer per
   question) but is deliberately *weaker* on three axes AID already gets right.

### Recommended seed-content set (Rec A headline -- grounds features 003 + 002)

| # | Seed element | KB doc | Concern | `kb-category` | Status vs candidate |
|---|--------------|--------|---------|---------------|---------------------|
| 1 | Declared **concept-spine / ubiquitous language** (keystone) | `domain-glossary.md` | C4 | `primary` | CONFIRMED -- keystone |
| 2 | **Intended architecture** (boundaries + relationships, sketch altitude) | `architecture.md` | C1 | `primary` | CONFIRMED |
| 3 | **Conventions & standards** (declared, thinnest element) | `coding-standards.md` (+ `authoring-conventions.md` for methodology projects) | C3 | `primary` | CONFIRMED, lighter-weight |
| 4 | **Technology stack / medium** | `technology-stack.md` | C0 | `primary` | CONFIRMED |
| 5 | **Decisions & rationale** (the elicited "why") | `decisions.md` | D | `extension` | **ADDED** (conditional) |

Excluded from the seed (no greenfield source): the **as-built** docs --
`module-map.md` (C2), `test-landscape.md` (C6), `schemas.md` (C5), `infrastructure.md`
(C8), `feature-inventory.md` (C9), `integration-map.md` / `pipeline-contracts.md` (C2),
and `project-structure.md` (C1 as-built layout). Rationale in
[Section 4 / RQ-A2](#4-recommendation-a----seed-content-set-rq-a1a5).

### Recommended analyst conversation design (Rec B headline -- grounds features 002 + 004)

A **straw-man-first facilitator** (from JAD) that opens every topic with a proposed
answer + rationale (this *is* NFR-7), calibrates to the user's knowledge level early
(from JAD "read the room" + laddering depth-calibration), and runs a sequenced playbook
of concrete moves -- term-capture, boundary-elicitation, event-first, bounded why-probe,
concrete-example probe, and capture-and-defer -- drawn one-for-one from the survey. It
stops at **minimal-but-sufficient** (NFR-4), the exact discipline `grill-me` lacks. The
**same engine** drives calibration (FR-2) and guided triage (FR-5); triage reuses the
backbone-first / walking-skeleton sizing move for full-vs-lite routing.

---

## 2. Technique Survey

Eight families, each scored on the fixed per-technique rubric -- (a) KB-seed content it
surfaces, (b) conversational moves it contributes, (c) fit with AID's process (NFR-1 /
NFR-7), (d) adopt / adapt / avoid verdict. Lifted and condensed from
`research/technique-survey.md` (which carries the full per-dimension findings and the RQ
map for each family).

| # | Family | Primary KB-seed contribution (a) | Signature move (b) | AID fit (c) | Verdict (d) | Strongest RQ links |
|---|--------|----------------------------------|--------------------|-------------|-------------|--------------------|
| 1 | **DDD / Ubiquitous Language** | Concept-spine -> `domain-glossary.md` (C4) | Term-capture + disambiguation | Strong; propose-then-confirm by nature | **ADOPT** (keystone) | A1, A3, B1, B4 |
| 2 | **Context & Domain Modeling** | Intended architecture -> `architecture.md` (C1) | Boundary + relationship elicitation | Good if bounded to sketch altitude | **ADAPT** | A1, A2, A4, B1 |
| 3 | **Event Storming** | Domain behavior / flows | Event-first, propose-timeline-back | Partial (workshop ritual drops; move transfers) | **ADAPT** | A1, A4, B1, B3 |
| 4 | **User-Story Mapping** | Scope / shape (sizing, not seed) | Backbone-first + walking-skeleton | Good for triage, not seed | **ADAPT** | B1, B3 (A2) |
| 5 | **Volere / RE process** | Sufficiency bar (fit criterion) | Rationale + testability probe | Very strong on NFR-7 | **ADAPT** | A5, B1, B4 |
| 6 | **JAD-style Facilitation** | (process, not content) | Straw-man-first; mediate-then-defer | Excellent; closest to AID's analyst | **ADOPT** (move set) | B1, B2, B4, NFR-1 |
| 7 | **Five-Whys / Laddering** | The "why" -> spine + `decisions.md` (D) | Bounded why-probe; triadic sort | Good in moderation (documented caution) | **ADAPT** | A1, A3, B1, B2, B4 |
| 8 | **Example Mapping / SbE** | Concrete examples + open-questions | Example probe; capture-and-defer | Very strong (defer-and-flag = DoD-5) | **ADAPT** | A5, B1, B3, B4 |

**Headline.** The seed-content backbone comes from **DDD/UL** (the keystone spine),
**Context Modeling** (boundaries, lightly), and the **Volere sufficiency discipline**.
The analyst conversation design comes mainly from **JAD facilitation** (straw-man-first,
mediate-then-defer), reinforced by **Five-Whys / Laddering** (bounded why-probe +
calibration), **Event Storming** (event-first sequencing), **User-Story Mapping** (triage
sizing), and **Example Mapping** (concrete-example probe + capture-and-defer). Two
families -- **Volere** and **JAD** -- independently corroborate NFR-7, showing the
suggested-answer-with-rationale invariant is established practice, not an AID invention.

**Confidence.** CONFIRMED for all eight verdicts -- each is grounded in the family's
canonical source plus a practitioner reference (see Section 7). The one caution carried
forward: Five-Whys is widely criticized as too shallow / arbitrary (Toyota's own Minoura),
so it is adopted only as a **bounded** probe, never the rote "exactly five whys" ritual.

---

## 3. grill-me Comparative

Lifted from `research/grillme-comparative.md`.

### What it is

`grill-me` is an agent **skill** (a reusable prompt + behavior contract) by **Matt
Pocock**, published in the public `mattpocock/skills` GitHub repo; it went viral in the
AI-coding community in 2026 [S2][S6]. Its core move **inverts** the normal flow: the
human states a rough plan, and the **agent interrogates the human** question by question
until they reach shared understanding, then emits a distilled session log (Intent /
Constraints / Decisions / Assumptions / Open questions / Out-of-scope) [S1][S8]. The
contract is tiny (~3 sentences) with three load-bearing rules: **one question at a
time**, **a recommended answer per question**, and **codebase-first resolution** (read
the code before asking) [S1][S4][S8]. An evolved variant, `/grill-with-docs`, validates
the emerging plan against project docs and updates artifacts as decisions finalize
[S2][S8]. A pattern catalog situates it as the *proactive, exhaustive* member of a small
family alongside two *reactive, narrow* cousins (Agent Pushback Protocol, Interactive
Clarification) [S4].

### Strengths and weaknesses

| Strengths [S1][S2][S4][S8] | Weaknesses [S4][S8] |
|----------------------------|---------------------|
| Surfaces hidden assumptions before implementation | Time cost / high mental load on the human |
| Keeps the human in control via two-way Q&A | Passive-user failure: rubber-stamping defaults (one anecdote: **540+ questions**) |
| Low instruction overhead (~3 sentences, portable) | No stopping criterion; unbounded breadth can blow the context window |
| Produces a durable artifact (session log) | Weak on high-fidelity questions that really need a prototype |
| Domain-agnostic (works for non-coding ideas) | Poor fit when requirements are externally fixed (becomes confirmation theater) |
| Recommended answers cut interrogation fatigue | Stateless -- findings lost unless written down (the gap `/grill-with-docs` closes) |

### Head-to-head vs AID's seasoned-analyst elicitation

For **general** requirements gathering (brownfield and greenfield alike), `grill-me` and
AID's analyst (NFR-1 / NFR-7) **converge** on two best ideas -- one-question-at-a-time and
a recommended answer per question -- which is strong external validation of AID's
instincts. They **diverge** on three axes where AID is deliberately stronger:

| Axis | `grill-me` | AID analyst | Winner |
|------|-----------|-------------|--------|
| Rationale with the suggestion | Not required; recommendation can stand bare [S8] | **Mandatory** -- the *why* on every question (NFR-7) | AID |
| Expert latitude | Asks and recommends; does not teach / explain / disagree | Guides, teaches, explains pros-cons, cordially disagrees, adapts depth (NFR-1) | AID |
| Stopping rule / quality | Unbounded ("every branch"); no inherent gate | **Minimal-but-sufficient** (NFR-4) + >= A review gate (NFR-3) | AID |

Conversely, `grill-me` is **leaner and more portable**, and its inverted
"user-states-then-agent-grills" framing is a clean conversational on-ramp AID can borrow
as a stance.

### Adopt vs avoid (inspiration-only, C-6)

| Adopt (reimplement in AID idiom) | AID idiom it maps to |
|----------------------------------|----------------------|
| One question at a time | Reinforces NFR-1's one-confirmed-decision-at-a-time |
| A recommended answer per question | Already NFR-7 -- adopt as external validation, keep AID's stricter form |
| Codebase-first resolution | Generalize to **KB-first + codebase-first + in-flight-work-first** |
| Inverted on-ramp (user states rough plan, analyst interrogates) | Conversational entry stance for the engine (esp. greenfield) |
| Distilled session log, not a transcript | Maps onto AID's tracked artifacts (REQUIREMENTS / SPEC / KB seed) |
| `/grill-with-docs` update-docs-as-decided | Aligns with AID's forward-authored, quality-gated seed (NFR-3 / NFR-5) |

| Avoid (consciously reject) | AID's stronger choice |
|----------------------------|------------------------|
| Unbounded "ask every branch" with no budget | Minimal-but-sufficient stopping rule (NFR-4) |
| Bare recommended answer (no rationale) | Suggested answer **+ rationale** on every question (NFR-7) |
| Pure interrogator stance | Expert-advisor latitude (NFR-1) |
| No quality gate (quality hinges on engagement) | >= A review / calibration gate (NFR-3) |
| Copying the prompt or skill code verbatim | Re-author in AID's idiom; cite, don't copy (C-6) |

### License and A-1 disclosure

- **License: MIT** (`mattpocock/skills`, SPDX `MIT`, confirmed via the GitHub API)
  [S6][S9]. MIT permits reuse with attribution; AID nonetheless treats it as
  inspiration-only per C-6 (no prompt/code copied), so the obligation is to **credit the
  source** (Section 7).
- **A-1 fallback did NOT fire** -- public material was adequate for a head-to-head. The
  **visible gap**: there is no peer-reviewed or empirical study of `grill-me`; all
  sources are practitioner blogs, skill directories, and one pattern catalog
  (secondary / anecdotal). Failure-mode claims (the 540+-question run) are single
  anecdotes, not data. The canonical per-skill README could not be fetched (404 at access
  time), so the contract is characterized from the author's announcement and an
  independent walkthrough. **Downstream features should treat the adopt/avoid verdicts as
  grounded recommendations, not measured guarantees** -- carried forward as a risk in
  Section 6.

---

## 4. Recommendation A -- Seed-Content Set (RQ-A1..A5)

> **Grounds feature-003** (the seed model -- which docs the seed produces and what each
> must pin) **and feature-002** (the engine that elicits them). Every kept element maps
> to an existing KB doc + concern + `kb-category`, so feature-003 can specify the seed's
> shape and feature-002 can specify what the analyst draws out, directly from this
> section.

### RQ-A1 -- Validate / revise the candidate seed set

**Candidate set (from FR-1 / the design seed):** declared concept-spine / ubiquitous
language (keystone) + intended architecture + conventions & standards + technology stack.

**Verdict: confirmed, with one addition and one weighting note.** Each element maps to an
existing KB doc and `kb-category` (the enum from `frontmatter-schema.md`:
`primary` | `meta` | `extension`):

| Seed element | KB doc | Concern | `kb-category` | Justification (surveyed technique / source) | Actionable bar |
|--------------|--------|---------|---------------|---------------------------------------------|----------------|
| Concept-spine / ubiquitous language (keystone) | `domain-glossary.md` | C4 | `primary` | DDD/UL **ADOPT** (Family 1): the load-bearing nouns/verbs defined *as this project uses them*, with relationships -- exactly AID's existing "Concept Spine" shape | Every load-bearing term defined; term-boundary invariants surfaced (C4 depth floor) |
| Intended architecture | `architecture.md` | C1 | `primary` | Context & Domain Modeling **ADAPT** (Family 2): name the boundaries + the relationships across them, at sketch altitude | Major parts + boundaries + relationships named, with the invariants a change must not break (C1 `## Invariants`) |
| Conventions & standards (thinnest element) | `coding-standards.md` (+ `authoring-conventions.md` for methodology projects) | C3 | `primary` | Volere principles (Family 5): declared standards / rules the work will follow; the least technique-sourced element -- often partly emergent | The project's own declared rules stated, or an explicit "standard for <stack>, no project-specific deviations yet" |
| Technology stack / medium | `technology-stack.md` | C0 | `primary` | Context Modeling "what we build vs integrate with" (Family 2) + the sufficiency need: `aid-specify`/`aid-plan`/`aid-execute` cannot act without the chosen language/runtime | The chosen language / runtime / framework named (version may be deferred -- see RQ-A5 + Section 6) |
| **Decisions & rationale (the elicited "why")** -- ADDED | `decisions.md` | D | `extension` (conditional) | Five-Whys / Laddering (Family 7) elicits the "why" behind intent; Volere's rationale-always discipline (Family 5) makes it durable | Present only when rationale-bearing choices were made (the propose->confirm gate); not forced when empty |

**Note on weighting.** Elements 1-2 are **keystones** (the seed is not load-bearing
without them); elements 3-4 are **lighter-weight and more deferrable** (conventions are
often emergent; the stack may be a single line); element 5 is **conditional**. This
weighting is the input feature-003 needs to decide which docs are mandatory vs
proposed-when-relevant.

### RQ-A2 -- What is explicitly excluded and why

**Excluded: the as-built, code-derived docs that have no greenfield source.** There is no
code yet, so these dimensions document *what code does* and cannot be authored from
intent:

| Excluded doc | Concern | Why excluded |
|--------------|---------|--------------|
| `module-map.md` | C2 | No modules exist yet (parts & dependencies are as-built) |
| `test-landscape.md` | C6 | No tests exist yet |
| `schemas.md` | C5 | As-built data shapes; intended shapes are minimal and deferrable (domain-adaptive exception -- see RQ-A4) |
| `infrastructure.md` | C8 | Nothing ships or runs yet |
| `feature-inventory.md` | C9 | Scope / capabilities are **governance**, owned by the pipeline (`REQUIREMENTS.md` / `SPEC.md`), not the KB |
| `integration-map.md`, `pipeline-contracts.md` | C2 | As-built connections; intended integrations are thin and deferrable |
| `project-structure.md` | C1 | As-built layout (the real on-disk tree); nothing on disk yet |

**Sufficiency rationale (justified + actionable).** Three surveyed / model sources back
the exclusion: (1) Context & Domain Modeling **ADAPT** (Family 2) explicitly excludes
tactical DDD detail from a seed as *premature design*; (2) User-Story Mapping **ADAPT**
(Family 4) routes scope/story-map detail to *pipeline content*, not the KB seed; (3) the
concern-model "Why product-concerns, not governance-artifacts" rule routes governance
(plans, backlogs, registers) to the pipeline. NFR-4 (minimal, not bloated) is the bar:
the as-built docs are authored later by `aid-discover` / `aid-update-kb` once code exists.
The seed carries **intent**, not **inventory**. *Actionable for feature-003:* the seed's
default doc-set is the five Rec-A docs; the excluded docs are produced post-code.

### RQ-A3 -- Declared vs harvested spine

AID's f004 essence engine **harvests** the Concept Spine from source (reading the nouns /
terms in code -- the "Relative bus" failure is what it guards against). Greenfield has no
code, so the spine must be **declared** from intent.

**What changes (justified by DDD/UL Family 1 + the C4 depth floor):**

- **Sourcing flips.** Harvested = mined by reading code; declared = the analyst
  *proposes* terms (a straw-man definition) and the user confirms/corrects. The move is
  term-capture + disambiguation (Family 1): when the user uses a noun, pin one canonical
  label and ask "is this the same as X you said earlier?".
- **What makes a declared spine SOUND.** It reaches the **same minimum** the harvested
  spine reaches, only authored from intent. Each keystone term pins: (a) one canonical
  label, (b) its definition **as this project uses it** (not generic), (c) its
  relationships to other terms, (d) the term-boundary invariants -- the distinctions a
  newcomer must never conflate (the C4 `## Invariants` floor).
- **The minimum to be load-bearing.** Enough terms that the work can be explained "using
  only defined native terms plus general knowledge" (the C4 stopping bar). An
  undefined-but-used term is a gap, not noise.
- **The risk unique to a declared spine.** No code to cross-check, so the analyst must
  keep declared terms honest with the concrete-example probe (Family 8): if the user
  cannot give an example of a term in use, the term is under-pinned.

*Actionable:* feature-003 specifies the declared-spine doc (`domain-glossary.md`) with the
four-part per-term contract above; feature-002 specifies the term-capture +
example-probe moves that produce it.

### RQ-A4 -- Domain-adaptive shape

The seed's exact shape should flex by domain (like `aid-discover`'s domain-driven
doc-set), **without** changing the fixed dimension spine.

**What flexes (justified):**

- Process / workflow-heavy domain -> **event-flow / behavior** content becomes
  load-bearing (Event Storming, Family 3 -- the event timeline is a domain-adaptive shape
  the seed can take); it lands in `architecture.md` or a domain-rendered
  `process-architecture.md`.
- Data / ML domain -> an **intended schema** (C5) becomes load-bearing rather than
  excluded.
- Integration-heavy domain -> an **intended integration-map** (C2) becomes relevant.
- Non-software domain -> the `domain-doc-matrix.md` renders different doc *names* for the
  same dimensions (the concern-model's domain-agnostic spine).

**What stays INVARIANT:**

- The **concept-spine (C4) is always present** (concern-model invariant: C4 is always
  covered by `domain-glossary.md`).
- The **dimension spine (C0-C9 + D) is fixed** (the T2 cardinality contract -- exactly 11
  dimensions; adaptivity is in doc *realization*, never in the dimension list).
- "Name boundaries + relationships" stays the invariant shape for architecture (Family 2).

*Actionable:* the seed = an **invariant core** (concept-spine + intended architecture +
minimal conventions + tech/medium) **plus domain-selected extensions**, surfaced through
the same propose->confirm gate `aid-discover` already uses. Feature-003 specifies the core
as mandatory and the extensions as proposed-when-the-domain-warrants.

### RQ-A5 -- Sufficiency test

**Objective bar (justified by Volere's fit-criterion, Family 5, + AC-2):** the seed is
minimal-but-sufficient when `aid-specify` runs with **zero KB-gap loopbacks** (the AC-2
measure for the downstream seed feature). Operationalize it with a per-element fit
criterion -- each kept element has a concrete pass test:

| Seed element | Fit criterion (pass test) | Technique grounding |
|--------------|---------------------------|---------------------|
| Concept-spine | The work can be explained using only defined native terms + general knowledge; every term has a concrete example | C4 floor + Example Mapping (Family 8) |
| Intended architecture | Major parts + boundaries + relationships named, with the invariants a change must not break | C1 floor + Context Modeling (Family 2) |
| Conventions | The project's own declared rules stated, or an explicit "no project-specific deviations yet" | C3 floor + Volere (Family 5) |
| Technology stack | The chosen language / runtime / framework named (version may be "latest at init" -- see Section 6) | C0 floor (with a flagged tension) |
| Decisions (if present) | Each decision states what + why + the rejected alternative | D floor + Five-Whys (Family 7) |

**Deferable to later phases:** as-built inventory (`module-map`, `test-landscape`,
`infrastructure`), exact schemas, and feature-inventory (the pipeline owns scope). The
stopping rule is **sufficiency, not completeness** (NFR-4) -- the deliberate opposite of
`grill-me`'s unbounded "every branch" breadth (Section 3). *Actionable:* feature-003
adopts the per-element fit-criterion table as its sufficiency definition and the zero
KB-gap-loopback run as its acceptance measure.

### D-5 note -- what the greenfield review gate implies (for feature-003)

NFR-3 requires the forward-authored seed to pass the **same KB review gate (>= A)** as an
`aid-discover` KB, reusing `aid-discover`'s review subsystem
(`references/{state-review,reviewer-brief,document-expectations}.md`, doc-set
parameterized per D-5). **But `document-expectations.md`'s depth standards are written for
brownfield extraction** -- they demand **code/config evidence** that a greenfield seed
cannot supply:

- C0 "**every ... version extracted from the config files** ... the exact **runnable build
  command**" -- there is no config file and nothing to build yet.
- C3 "each [rule] with a **concrete example from this project's code or files**" -- there
  is no code.
- `architecture.md` "**Ground every claim in a file or path**" / C1 "the real layout, not
  a generic skeleton" -- nothing is on disk.

A forward-authored doc would trip the brownfield red flags ("Version TBD", "convention
named but no example from code", "generic descriptions without file paths") even when it
is correctly authored from intent. **Implication for feature-003:** the review
expectations must be **parameterized for greenfield** -- substitute *intent-evidence* (the
user's confirmed statements + the gathered REQUIREMENTS) for *code-evidence*, and relax
the as-built red flags (a not-yet-pinned stack version is acceptable; "example from
intended use" replaces "example from code"). The gate still checks the **same dimensions**
and the **same operational-structure floors** (C4 term-boundary invariants, C1
`## Invariants`, etc.), only sourced from intent. Whether feature-003 forks a greenfield
`document-expectations` variant or adds a greenfield-mode flag is left open in Section 6.

---

## 5. Recommendation B -- Analyst Conversation Design (RQ-B1..B4)

> **Grounds feature-002** (the shared seasoned-analyst elicitation engine -- one reusable
> component per the FR-5 emergent-design note) **and feature-004** (guided triage). Every
> move below names the family it comes from, so feature-002 can specify the playbook and
> feature-004 the triage path directly from this section.

### RQ-B1 -- Elicitation moves (the FR-2 seasoned-analyst playbook)

Ten concrete moves, each from a surveyed family, in a recommended sequence:

| # | Move | From | What it draws out |
|---|------|------|-------------------|
| 1 | **Straw-man-first** -- open every topic with a proposed answer + rationale, never a blank page | JAD (Family 6) | *Is* NFR-7; lowers user load |
| 2 | **Term-capture + disambiguation** -- pin one canonical label per noun the user uses | DDD/UL (Family 1) | The concept-spine |
| 3 | **Boundary-elicitation** -- "name the boundary, then the relationship across it" | Context Modeling (Family 2) | Intended architecture |
| 4 | **Event-first, propose-timeline-back** -- "walk me through what happens step by step," then propose the ordered events back and probe gaps | Event Storming (Family 3) | Domain behavior / flows |
| 5 | **Backbone-first + walking-skeleton** -- the user's journey in order, then "which is essential for a first version?" | User-Story Mapping (Family 4) | Scope / sizing (feeds triage, RQ-B3) |
| 6 | **Rationale + testability probe** -- "why does this matter? how will we know it's satisfied?" | Volere (Family 5) | The fit-criterion / sufficiency bar |
| 7 | **Bounded why-probe + triadic sort** -- climb 2-3 whys, propose the inferred motive back, stop at the terminal value | Five-Whys / Laddering (Family 7) | The "why" -> `decisions.md`; disambiguation |
| 8 | **Concrete-example probe** -- ask for an example to test any claim | Example Mapping (Family 8) | Sufficiency check (under-pinned terms surface) |
| 9 | **Capture-and-defer (red-card)** -- when a point cannot be settled, record it as a STATE.md Q&A / downstream-risk and move on | Example Mapping (Family 8) | Honors human-gating + DoD-5 |
| 10 | **Mediate-then-defer + scribe** -- surface disagreement, defer the call to the human, write resolved points immediately | JAD (Family 6) | NFR-1 process discipline / visible state |

**Recommended sequence:** calibrate (RQ-B2) -> straw-man the spine (terms) -> boundaries /
architecture -> behavior / flow (if a process domain) -> conventions + stack -> rationale /
why -> sufficiency check (example-probe per element) -> capture open questions. *Actionable:*
feature-002 specifies this as the engine's move set; the sequence is a default, not a rigid
script (NFR-1 latitude).

### RQ-B2 -- Calibration

**Justified by JAD "draw out the quiet / read the room" (Family 6) + laddering
depth-calibration (Family 7) + FR-2 / NFR-1.**

- **Early move:** ask the user's knowledge level / type -- domain familiarity, software /
  requirements practice, AID familiarity -- itself a straw-man question carrying a
  suggested answer (NFR-7).
- **Shape downstream questioning:** expert -> lighter confirmation, fewer why-steps (an
  expert states the terminal value directly, Family 7); novice -> heavier drawing-out,
  more scaffolding / teaching, more why-steps and example-probes.
- **NFR-1 latitude:** gracefully support "I don't know", "what do you recommend?",
  "explain like a junior", and cordial disagreement. Calibration is **continuous** --
  re-read from the user's answers, not a one-time gate.
- **Contrast (justification by gap):** `grill-me` has **no calibration** -- a pure
  interrogator that does not teach or adapt (Section 3 head-to-head). AID's calibration is
  a deliberate divergence and a key reason it is stronger for unsure users (A-3).

*Actionable:* feature-002 specifies the calibration probe + the depth-shaping rule;
feature-004 inherits it for triage (an unsure user needs more drawing-out to route
correctly).

### RQ-B3 -- Triage elicitation

**Justified by User-Story Mapping (Family 4) + Event Storming (Family 3) + Example Mapping
(Family 8) + FR-5.** The *same* engine draws out the path-deciding (full vs lite) and
recipe-deciding signals:

- **Primary signal:** backbone-first + walking-skeleton sizing (Family 4) -- a small
  end-to-end slice suggests **lite**; a sprawling multi-activity backbone suggests
  **full**.
- **Secondary signals:** event-timeline length (Family 3) and example-coverage breadth
  (Family 8) reveal scope size.
- **KB-context-aware (FR-5):** with a **full KB** (brownfield, post-`aid-discover`) the
  analyst uses the existing KB to ask sharper, gap-targeted questions; with only a
  **seed KB** (greenfield) it uses the just-authored spine + architecture as context.
  Either way it leverages whatever KB exists.
- **NFR-7 holds:** every triage question carries a suggested answer + rationale -- e.g.
  "this looks like a *lite* work because the backbone is a single end-to-end slice;
  agree?".
- **Borrowed stance:** `grill-me`'s inverted on-ramp (user states a rough plan, analyst
  interrogates it) is a clean entry for the triage conversation (Section 3 adopt list).

*Actionable:* feature-004 specifies triage as a thin path over the shared engine -- reuse
moves 1, 5, 8 and the calibration probe; output is the path + recipe decision, human-gated.

### RQ-B4 -- Suggested-answer-with-rationale (NFR-7)

**The invariant survives and is strengthened.** Justified by JAD straw-man (Family 6) +
Volere rationale-always (Family 5) + the `grill-me` convergence (Section 3):

- **JAD's straw-man move IS the delivery mechanism** -- every question opens with a
  proposed answer + rationale (Family 6). NFR-7 is therefore not an add-on; it is how the
  best-matched technique already works.
- **Volere independently corroborates it** -- "capture the rationale with the requirement"
  is essentially NFR-7, arrived at independently. External validation that the invariant
  is established practice, not invented (Family 5).
- **`grill-me` converges but is weaker** -- it has a recommended answer per question but
  does **not** require the rationale; its documented failure mode (passive rubber-stamping
  -> 540+ questions [S8]) is exactly what the **mandatory rationale prevents**: informed
  agreement, not auto-accept.
- **Techniques that strengthen it:** Five-Whys / Laddering "propose the inferred why back"
  (Family 7) keeps even the why-probe suggestion-bearing rather than a blank
  interrogation; the concrete-example probe (Family 8) makes each suggestion checkable.
- **No surveyed technique tensions with NFR-7.**

*Actionable:* feature-002 specifies straw-man-first as a hard invariant of every move in
the playbook -- no bare, suggestion-less question is ever emitted (AC-3).

---

## 6. Open Questions / Risks for Downstream

Explicit flags for features 002-005 -- not left implicit (DoD-5).

| # | Item | Type | For feature(s) | Detail |
|---|------|------|----------------|--------|
| 1 | **`source:` marker addition** | A-2 schema gap (the ONE permitted) | 003, 005 | The seed needs a new `source:` value (e.g. `forward-authored`) to mark greenfield-origin docs. `frontmatter-schema.md` currently allows `hand-authored` \| `generated`; `lint-frontmatter.sh` enforces it. C-1 permits exactly this one addition (touching `lint-frontmatter.sh` / `build-kb-index.sh` / `kb-freshness-check.sh`). **The rest of the seed IS expressible in the existing schema:** `kb-category` (`primary`\|`meta`\|`extension`) needs **no** change -- the five Rec-A docs are `primary` (4) + `extension` (`decisions.md`). |
| 2 | **Greenfield review-gate parameterization** | Unresolved design | 003 | Per the D-5 note in Section 4, `document-expectations.md`'s depth standards assume code/config evidence a greenfield seed cannot supply. **Open:** does feature-003 fork a greenfield `document-expectations` variant, or add a greenfield-mode flag to the existing (doc-set-parameterized) one? Either way the gate must accept intent-evidence and relax the as-built red flags while keeping the same dimension floors. |
| 3 | **Tech-stack version tension** | Unresolved sufficiency detail | 003 | The C0 depth floor demands a version "extracted from config files" + a runnable build command. A greenfield stack may have neither yet. **Open:** is "latest at init" / "TBD until scaffolded" acceptable for the sufficiency bar, or must the user pin versions up front? |
| 4 | **Conventions (C3) thinness** | Unresolved scope detail | 003 | Conventions are the thinnest, most emergent seed element. **Open:** how much must be *declared* at seed time vs *deferred* until code conventions emerge? Default recommendation: accept an explicit "standard for <stack>, no project-specific deviations yet." |
| 5 | **Seed <-> requirements coherence mechanism** | Surfaced, out of spike scope | 002, 003 | FR-3 requires a coherence check between the seed and the gathered requirements. The concrete-example probe (Family 8) is a candidate mechanism, but the check itself is unspecified here. Flagged for the engine / seed-model features. |
| 6 | **`grill-me` evidence is anecdotal** | Sourcing caveat (A-1) | 002-005 | A-1 did not fire, but no empirical study of `grill-me` exists -- all evidence is practitioner / anecdotal (e.g. the 540+-question failure is one anecdote). Treat the adopt/avoid verdicts as **grounded recommendations, not measured guarantees**. |
| 7 | **Code->design conformance check is unbuilt** | Dependency surfaced (D-4) | 005 | FR-4's build-time conformance lifecycle needs a **new** check (code diverged from a forward-authored doc), flagged for human reconciliation (NFR-5). f007 freshness cannot do it (read-only, source->doc directional, and a declared seed has no file-sources). Out of this spike's scope; flagged for feature-005. |

---

## 7. Sources

Consolidated and de-duplicated from both research notes. **All web sources accessed
2026-06-27.** The two source sets do not overlap; original IDs are preserved
(`[1]`-`[19]` from the technique survey; `[S1]`-`[S9]` from the `grill-me` comparative).
Licenses are recorded for C-6 attribution discipline; both notes paraphrase and cite,
copying no prompts or code.

### Technique survey sources (`research/technique-survey.md`)

| # | Family | Source (title) | URL | License / note |
|---|--------|----------------|-----|----------------|
| 1 | DDD / UL | Martin Fowler, bliki: *Ubiquitous Language* | https://martinfowler.com/bliki/UbiquitousLanguage.html | Site copyright; reference-only |
| 2 | DDD / UL | Martin Fowler, bliki: *Domain Driven Design* | https://martinfowler.com/bliki/DomainDrivenDesign.html | Site copyright; reference-only |
| 3 | DDD / UL | Eric Evans, *Domain-Driven Design Reference* (2015) | https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf | CC BY (per the Reference's stated license) |
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
| 15 | Five-Whys | Wikipedia: *Five whys* | https://en.wikipedia.org/wiki/Five_whys | CC BY-SA 4.0 |
| 16 | Laddering | Reynolds & Gutman / SAGE: *An Adaptation of the Laddering Interview Method* (PDF) | https://journals.sagepub.com/doi/pdf/10.1177/1094428105280118 | Publisher copyright; reference-only |
| 17 | Laddering | UXmatters: *Laddering -- A Research Interview Technique for Uncovering Core Values* | https://www.uxmatters.com/mt/archives/2009/07/laddering-a-research-interview-technique-for-uncovering-core-values.php | Site copyright; reference-only |
| 18 | Example Mapping | Matt Wynne / Cucumber: *Introducing Example Mapping* | https://cucumber.io/blog/bdd/example-mapping-introduction/ | Site copyright; reference-only |
| 19 | Example Mapping | Cucumber docs: *Example Mapping* | https://cucumber.io/docs/bdd/example-mapping/ | Site copyright; reference-only |

### grill-me comparative sources (`research/grillme-comparative.md`)

| # | Source (title) | URL | License / note |
|---|----------------|-----|----------------|
| S1 | "grill-me - AI Agent skill," eliteai.tools | https://eliteai.tools/agent-skills/grill-me-2 | Site copyright; reference-only |
| S2 | Matt Pocock, "My 'Grill Me' Skill Has Gone Viral," aihero.dev | https://www.aihero.dev/my-grill-me-skill-has-gone-viral | Site copyright; reference-only |
| S3 | "Grill Me - Career Agent Skill," AI UX Playground | https://aiuxplayground.com/skills/grill-me/ | Site copyright; reference-only |
| S4 | "Grill Me: Developer-Initiated Plan Interrogation," AgentPatterns.ai | https://www.agentpatterns.ai/agent-design/grill-me-technique/ | Site copyright; reference-only |
| S5 | "grill-me - skills" (mattpocock mirror), explainx.ai | https://explainx.ai/skills/mattpocock/skills/grill-me | Site copyright; reference-only |
| S6 | `mattpocock/skills` (canonical repository; install source), GitHub | https://github.com/mattpocock/skills | **MIT** (repo `LICENSE`) -- the technique's implementation; inspiration-only per C-6 |
| S7 | "[Feature] Deep Interview skill," Issue #484, `Yeachan-Heo/oh-my-codex`, GitHub | https://github.com/Yeachan-Heo/oh-my-codex/issues/484 | Site copyright; reference-only |
| S8 | "The /grill-me Skill for Thoroughly Interviewing a Design ...," azukiazusa.dev | https://azukiazusa.dev/en/blog/before-implementation-interview-design-requirements-grill-me/ | Site copyright; reference-only |
| S9 | License confirmation: GitHub API `repos/mattpocock/skills` -> `license.spdx_id = MIT` | https://github.com/mattpocock/skills/blob/main/LICENSE | MIT (SPDX) -- attribution captured per C-6 |

### AID-internal references (not web sources)

REQUIREMENTS.md (FR-1, FR-2, FR-5, NFR-1, NFR-3, NFR-4, NFR-5, NFR-7, C-1, C-6, D-4, D-5,
A-1, A-2, A-3, AC-1, AC-2, AC-3); feature-001 SPEC.md (Research Questions, Methodology,
Deliverable structure, DoD-1..6); `canonical/aid/templates/kb-authoring/concern-model.md`
(the 11-dimension spine, the 15-doc seed, the T2 cardinality contract);
`canonical/aid/templates/kb-authoring/frontmatter-schema.md` (the `kb-category` and
`source:` enums); `.aid/knowledge/authoring-conventions.md` (the dual-audience standard);
`canonical/skills/aid-discover/references/document-expectations.md` (the Spine-Dimension
Depth Standards reused by the NFR-3 review gate).

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | task-003 (RESEARCH synthesis) | Initial findings: 7 sections assembled from the two research notes; all RQ-A1..A5 and RQ-B1..B4 answered (justified + actionable); Rec A + Rec B formed for direct downstream consumption; A-2 gap + D-5 review-gate tension + 7 downstream risks flagged; sources consolidated and de-duped. |
