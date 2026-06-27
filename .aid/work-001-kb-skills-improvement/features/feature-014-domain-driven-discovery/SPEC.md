# Domain-driven, source-first KB discovery (+ dual-audience authoring)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-24 | Feature authored (lite path) to generalize `/aid-discover` beyond software to **any digital work**: the KB doc-set is derived from the project's **domain** (a generic dimension spine + a curated domain→doc-set matrix, with a research fallback), established **from the existing source** (brownfield-first, user-on-uncertainty), and every doc is authored for **two audiences** (junior humans + AI agents). Adds FR-37–FR-44. Grounded in a 3-part standards research pass (arc42/C4/IEEE1016/ISO42010/ADR for the product layer; PMBOK/PRINCE2/Scrum confirmed as the governance layer → AID pipeline, not the KB). | user decision |

## Source

- REQUIREMENTS.md §5.J (FR-37–FR-44, NEW)
- REQUIREMENTS.md §1.2 (KB value = the *delta* from what a generalist knows), §1.3 (the universal newcomer concerns — the spine), §1.6 (mechanical/judgment floor)
- §5.D (FR-12–FR-19 essence + panel — the spine is generalized here), §5.E (FR-20–FR-22 recon triage — the domain classifier is its sibling; see the Step 0f reconciliation), §9 (NEW AC), §10 (Must)
- **Extends**: f003 (KB document model — adds the dual-audience authoring standard + layout), f004 (essence/concept spine — generalizes the concept model into the domain-agnostic generic core), f005 (review panel — the Anatomy mandate enforces the authoring standard), f006 (recon triage — the domain classifier is a sibling source-driven classification)
- **Evidence**: three research reports (software/architecture doc standards · PMBOK/PRINCE2 · Agile/Scrum/SAFe/Lean/XP) — folded into the Technical Specification's design rationale below

## Description

`/aid-discover` today forces a **fixed 15-doc software taxonomy** onto every project (when
`discovery.doc_set` is unset) and **requires** an `/aid-config` init scaffold to start. AID,
however, is meant to help with **any kind of digital work** — software, data/ML, content,
research, design, ops — and for non-software work that taxonomy is simply wrong; even for a
software project it both over-generates (forces empty buckets) and under-generates (misses
project-specific concepts).

feature-014 makes discovery **domain-driven and source-first**:

- A **generic core** — a domain-agnostic *dimension spine* (the universal questions any
  deliverable must answer about itself) — is always present and anchors every doc-set. The
  current C0–C9 concern model is the *software rendering* of this spine.
- Discovery **establishes the project's domain by analyzing the existing source** (we are
  brownfield: the source is there to be read). When the source is decisive it classifies;
  when insufficient/uncertain/dubious it **asks the user**.
- The confirmed domain resolves to a doc-set via a **curated domain→doc-set matrix** (fast
  path) or, on a miss, by **researching the domain's documentation practices** and
  synthesizing a set (fallback) — always anchored to the spine, **composable** for hybrids,
  and **proposed→confirmed** with the user. The legacy 15-doc seed becomes the *software row*
  of the matrix.
- Every document is filled **from the source first**, with the user consulted only to fill
  gaps and resolve uncertainties — and is authored for **two audiences at once**: small,
  single-concern, junior-clear, tables/bullets (no diagrams), and machine-consumable
  (classified frontmatter, named greppable sections, summary+pointer), laid out
  **frontmatter → index → content → change-log-last**.

The matrix is a shipped `canonical/` artifact updated by release/curation; a project's
confirmed set persists locally; there is **no automatic install→canonical feedback** (the
install boundary is one-directional). The dogfood loop closes by hand — maintainers curate
matrix rows into `canonical/`.

## User Stories

- As an **AID adopter doing non-software digital work**, I want discovery to give me the
  documents *my* kind of project needs — not a software architecture taxonomy — so the KB is
  relevant from the first run.
- As an **AID adopter on a brownfield project**, I want discovery to learn my project's nature
  and content **from the existing source** and only ask me about what it genuinely cannot
  determine, so I am not re-interviewed about facts the code already states.
- As an **AI agent consuming the KB**, I want each document to be small, single-concern, and
  classified (frontmatter, named sections, summary+pointer) so I can load exactly the relevant
  piece into my context without wading through a large mixed document or an unreadable diagram.
- As a **junior professional**, I want the KB written in plain, clear language with tables and
  bullets so I can understand the project without decoding jargon.
- As an **AID maintainer**, I want the doc-set driven by a curated, standards-grounded matrix
  over a fixed dimension spine — extensible per project but deterministic per release — so the
  KB shape is predictable and defensible to skeptical adopters.

## Priority

Must

## Acceptance Criteria

- [ ] Given any project, when discovery runs, then the proposed doc-set is **anchored to a
  domain-agnostic dimension spine** (every spine dimension is covered by ≥1 doc or explicitly
  marked conditional); the spine is documented and **grounded in the cited standards**
  (arc42/C4/IEEE1016/ISO42010/ADR). *(FR-37)*
- [ ] Given a brownfield project, when discovery starts, then it **classifies the domain from
  the existing source**; when the source is decisive it classifies without asking, and when it
  is insufficient/uncertain/dubious it **raises a Q&A to the user** (measured-then-confirmed,
  never auto-final). *(FR-38)*
- [ ] Given a confirmed domain, when the doc-set is resolved, then a **matrix hit** yields the
  curated set and a **matrix miss** triggers a **domain-documentation research** step that
  synthesizes a set; both are **anchored to the spine**, **composable** for hybrids, and
  **proposed→confirmed**; the legacy 15-doc seed is the matrix's **software row**. *(FR-39)*
- [ ] Given a researched/confirmed doc-set, when discovery completes, then the set **persists
  locally** in `.aid/settings.yml → discovery.doc_set`; the matrix itself is a **`canonical/`
  artifact** changed only by release/curation; discovery MAY **emit a PR-candidate artifact**;
  there is **no automatic install→canonical propagation**. *(FR-40)*
- [ ] Given `.aid/knowledge/STATE.md` is absent, when `/aid-discover` runs, then it
  **self-creates STATE.md from its template** and proceeds (no "run /aid-config first"
  hard-stop). *(FR-41)*
- [ ] Given the existing source, when documents are filled, then content is **drawn from the
  source first**, with the user consulted **only** for gaps/uncertainties/clarifications/
  confirmations. *(FR-42)*
- [ ] Given a generated KB document, when it is authored, then it is **one concern, minimal
  overlap** (big docs split into small focused ones), in **simple junior-clear language**,
  using **tables/bullets and no diagrams**, and is **dual-audience classified** (frontmatter
  concern/tier/audience/owner/tags · named greppable sections · summary+pointer loadable via
  INDEX), laid out **frontmatter → index → content → change-log-last**; the review panel's
  **Anatomy mandate enforces** these. *(FR-43, FR-44)*
- [ ] All section-6 quality gates pass (canonical→render parity / DBI / ASCII-PS / suites).

---

## Technical Specification

> Design of record for feature-014. Realized as a **single delivery (delivery-010)** on
> branch `aid/work-001-delivery-010`. Reuses f003/f004/f005/f006 machinery; does **not**
> re-spec them. Canonical edits require regen + `.claude` dogfood sync + DBI (per the repo's
> standing build cornerstones).

### 1. The generic core (domain-agnostic dimension spine) — FR-37

The spine is the set of **universal questions any digital deliverable must answer about
itself**. It is **fixed** (a T2 structure, like today's concern list) and project-type-
agnostic; only its *realization* (which docs, named how) varies per domain.

**Standards grounding (evidence).** The spine is the cross-standard recurring-concern set
distilled from the software/architecture documentation standards research:

| Spine dimension (domain-agnostic) | Software rendering (today's concern) | Grounded in |
|---|---|---|
| What it is / does for users (capabilities, context, scope) | C9 feature-inventory | arc42 §1/§3, C4-L1, ISO 42010 (entity/stakeholders) |
| What it is made of (structure / anatomy) | C1 project-structure, architecture | arc42 §5, C4-L1..3, IEEE1016 composition |
| How the parts connect | C2 module-map, integration-map, pipeline-contracts | arc42 §5, C4, IEEE1016 dependency/interface |
| What it is built with (technology / medium) | C0 technology-stack | arc42 §4, C4-L2 |
| Conventions & cross-cutting approaches | C3 coding-standards | arc42 §2/§8, IEEE1016 patterns |
| Vocabulary / glossary | C4 domain-glossary | arc42 §12 |
| Deliverables, data & contracts | C5 schemas | arc42 §3/§8, IEEE1016 information/interface |
| Quality & how it is checked | C6 test-landscape | arc42 §10, IEEE1016 |
| Risk & debt | C7 tech-debt | arc42 §11 (uniquely explicit) |
| How it ships & operates | C8 infrastructure | arc42 §7, C4-deployment |
| **Decisions & rationale** (NEW) | *(none today)* | arc42 §9, ADR, ISO 42010 decision annex |
| Stakeholders & concerns (meta) | (interview/requirements) | ISO 42010 root |

- The **governance** layer (PMBOK/PRINCE2/Scrum artifacts — charter, plan, registers,
  backlog) is **out of KB scope**; it maps to AID's **pipeline artifacts**
  (REQUIREMENTS/SPEC/PLAN/tracking), which already exist. `concern-model.md` gains a "Why
  product-concerns, not governance-artifacts" note + the standards citations.
- **Decisions** is the one evidence-attested **gap** in today's spine. The recommended
  resolution (delivery-010 STATE Q2) is to **promote it to an 11th spine dimension realized as
  a CONDITIONAL doc** (`decisions.md` / ADR-log): the byte-stable software **seed**
  (`synth_default_seed`'s 15 docs) stays **unchanged** — `decisions.md` is a *conditional*
  matrix entry, NOT added to the seed — so FR-37's *covered-or-conditional* holds for the
  software row **and** seed byte-stability is preserved. Promotion requires task-056 to update
  `concern-model.md`'s **T2 cardinality contract in lockstep** (10→11 concerns + the
  seed-coverage note that Decisions is conditional, not one of the 15 seed docs). If Q2
  declines promotion, Decisions stays a conditional matrix extension under an existing
  dimension — **either way the plan is internally consistent and the seed is byte-stable**.

### 2. Source-driven domain classification — FR-38

A new early GENERATE sub-step, sibling to the recon path-measure, run **after** the project
index is built (it reads the source, brownfield-first):

1. Read `.aid/generated/project-index.md` + harvested signals (languages, dir shapes, notable
   files, candidate concepts) for **domain signals**.
2. **Decisive** → classify the domain (e.g. software-cli, software-web, data/ML, content,
   research, design, ops, methodology/tooling, …) and record it.
3. **Insufficient / uncertain / dubious** → write a **Q&A (Impact: Required)** to
   `STATE.md ## Q&A (Pending)` and pause for the user (the existing Q&A gate).
4. Record the confirmed domain in `STATE.md` (a `## Discovery Domain` block — measured /
   proposed / decision-rationale / confirmed, mirroring the triage record), the anchor for
   idempotent re-entry.

Classification is **measured-then-confirmed** — never auto-final, never from `project.type`.

### 3. Doc-set = matrix-or-research — FR-39

The doc-set proposal (today GENERATE Step 0d "default seed + deltas") becomes
**matrix-lookup → (research on miss) → propose → confirm**:

- **Matrix** (`canonical/aid/templates/kb-authoring/domain-doc-matrix.md` — NEW, a structured
  data artifact): rows = `domain → [doc: filename | spine-dimension | owner | presence]`.
  Seeded with the common domains; the **software row is exactly today's 15-doc seed**, so the
  current behavior is preserved as one cached row.
- **Research fallback** (matrix miss / novel / hybrid): a research step gathers the domain's
  **product/deliverable documentation practices** (primary) and governance context
  (secondary) and **synthesizes** a doc-set, each doc mapped to a spine dimension. Output is
  flagged provenance `auto-researched`.
- **Compose** for hybrids: union the relevant domain rows over the single spine; dedupe by
  spine-dimension; never exclusive buckets. "Did we cover everything?" = walk the fixed spine.
- **Propose → confirm**: present the resolved set as a diff vs the spine defaults; user
  confirms/edits; the confirmed set is persisted (§4).

`synth_default_seed` is **retained** as the matrix's software-row generator (byte-stable for
existing tests). `resolve_doc_set` + the 4 accessors are unchanged (generic).

### 4. Matrix lifecycle — FR-40 (the install-boundary correction)

- **Global matrix** ships in `canonical/` → rendered → installed; updated only via
  **release / human curation**. One-directional (canonical → user). No telemetry.
- **Local persistence**: the confirmed/researched set writes to
  `.aid/settings.yml → discovery.doc_set` (mechanism already exists). Deterministic for that
  project across re-runs and multiple works.
- **Optional upstream contribution**: discovery MAY emit
  `.aid/generated/domain-doc-candidate.md` (proposed row + provenance) the user can PR to the
  AID repo. Manual, opt-in.
- **Dogfood loop closes by hand**: maintainers running discovery inside the AID repo curate a
  researched row into `canonical/` via a normal commit — the only place the loop closes.

### 5. Self-bootstrap start + source-first fill — FR-41, FR-42

- **FR-41**: `discover-preflight.sh` no longer hard-fails on a missing `STATE.md`; the skill
  (or preflight) **creates it from `discovery-state-template.md`** and continues. The State
  Detection legacy path already tolerates absence; this makes it self-seeding.
- **FR-42**: doc-fill is **source-first** (the existing brownfield researcher behavior),
  user-as-gap-filler via the existing Q&A loop. No new mechanism — reaffirmed as the doctrine
  for the domain-driven flow.

### 6. Dual-audience authoring standard — FR-43, FR-44

Written into **kb-authoring** (`principles.md`, `concern-model.md`, `frontmatter-schema.md`,
`tier-model.md`), baked into the **doc templates** + the **generation prompts**
(`agent-prompts.md`), and **enforced by the review panel's Anatomy mandate**:

- **Granularity**: one concern per doc, minimal overlap; small-and-focused is the default;
  split oversized docs (strengthens the existing three-force boundary rule).
- **Language**: simple, clear, junior-professional reading level; clarity over jargon.
- **Format**: tables + bullet points; **avoid diagrams** in KB `.md` docs. (The `kb.html`
  visual summary is a separate, deliberately-visual artifact — unchanged.)
- **Dual-audience classification**: machine-parseable frontmatter (concern/dimension, tier,
  audience, owner, tags) · named greppable sections (the operational-section model) ·
  summary+pointer chunks loadable via `INDEX.md`.
- **Layout (every doc)**: `frontmatter → index → content → change log (always last)`.

**Why it serves both audiences at once:** small + single-concern + tables/bullets +
classified frontmatter lets a junior human read a short focused doc and an agent load exactly
the relevant small doc/section into context; diagrams hurt both. This is the existing
"summary+pointer dissolves the agent-vs-human fork" insight made an enforced standard.

### 7. How it rewires the front of GENERATE (and the open reconciliation)

Today: `Step 0c index → Step 0d doc-set(seed+deltas) → Step 0e harvest → Step 0f path-triage
→ fan-out`. After f014: `index → domain-classify(§2) → doc-set via matrix-or-research(§3) →
harvest → path-measure → fan-out`, with the authoring standard applied in the fan-out + fill.

- **Step 0f reconciliation (RESOLVED — delivery-010 STATE Q1):** the existing GENERATE **Step
  0f path-triage** (greenfield/brownfield-small/large) **stays in discovery** — it scales the
  fan-out and is already measured-then-confirmed with FR-22 re-triage (the recommended answer
  is already shipped behavior, so this is a ratify/document step, not a new architecture
  decision). **Domain** (§2) and **path** (Step 0f) are the **two source-measured,
  human-confirmed classifications** at GENERATE's front. task-058 implements the domain
  classifier **alongside the unchanged Step 0f** and does not re-decide the boundary.

### 8. Scope boundaries (MVP for delivery-010)

**In scope (this delivery):** the generic-core spine (generalize + cite `concern-model.md`);
the `domain-doc-matrix.md` artifact seeded with the common domains (software = today's seed);
the source-driven domain classifier (FR-38) at GENERATE's front; the matrix-or-research
doc-set flow (FR-39) incl. the research-fallback step; matrix lifecycle + local persistence
(FR-40); self-bootstrap STATE (FR-41); source-first fill reaffirmation (FR-42); the
dual-audience authoring standard wired into kb-authoring + templates + generation prompts +
the Anatomy mandate (FR-43, FR-44); documenting the resolved Step 0f reconciliation (Q1).

**Deferred (flag, not built here):** full **downstream decoupling** of `aid-summarize`
section-templates + the explicit `doc.md § Section` lookups from fixed filenames (a follow-on
feature — only bites once doc-sets routinely diverge from the software row); the optional
contribution-candidate artifact MAY ship as a thin emit-only stub or defer.

**Won't (this work):** any telemetry / automatic install→canonical feedback; greenfield
forward-authoring (still O7).

### 9. Engineering constraints (reused)

- Any shipped script ASCII-only + WinPS-5.1-safe; deterministic where mechanical (matrix is
  data, classification proposes-then-confirms).
- Canonical edits → `run_generator.py` regen → `.claude` dogfood sync → DBI green.
- Anatomy-mandate checks for the authoring standard are mechanical where possible (layout
  order, presence of frontmatter fields + index + changelog-last, diagram-absence), judgment
  where not (reading level, single-concern coherence).
