# Requirements

- **Name:** Design Phase Skill Family
- **Description:** Adds a uniform design → create → update lifecycle across the AID skill roster, together with roadmap.md and backlog.md, so pre-implementation thinking is incubated in .aid/design/ and promoted into the Knowledge Base instead of happening informally.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-08 | Initial interview started | /aid-describe |
| 2026-08-08 | KB hydration assessed — no writes (brownfield; all captured content is intended future state) | /aid-describe |
| 2026-08-08 | Interview complete — approved | /aid-describe |
| 2026-08-09 | Cross-reference fixes: FR-9 (adopter seed 14→17), FR-10 (engine reads seed), AC-10/AC-11 added; FR-5 uniformity claim corrected to two artifact classes; doctrine amendment added to §4 In Scope and C-6 | /aid-define |
| 2026-08-09 | Re-scope after 4 spec-review rounds: FR-9 rewritten — new docs are CONDITIONAL and created on demand, seed stays 14; the `## Change Log` doctrine conflict deferred to its own work; AC-3 rewritten, AC-3a added; C-6 reduced to two adopter-facing changes | /aid-specify |
| 2026-08-09 | Internal contradictions surfaced by spec review r4 corrected: AC-3's surviving "each has a template" clause struck (it contradicted FR-9's re-scope); C-6 item 1's surviving "14 → 17 canonical templates" struck for the same reason; FR-1 gained the region-level rule for populated destinations and AC-6b makes the brownfield case checkable | /aid-specify |
| 2026-08-09 | FR-11 added — nine cross-feature contracts (CC-1..CC-9) settled once, after five spec reviews found the surviving CRITICAL/HIGH findings concentrated in cross-spec disagreement rather than within-spec defects. FR-1's `update` Reads column amended per CC-3; C-6 gains a third adopter-facing change (three new canonical templates); FR-1 gains the region-owning-skill rule (CC-5) | /aid-specify |
| 2026-08-09 | **Owner decision: regenerating `.aid/knowledge/kb.html` is IN SCOPE** (§4 In Scope). The alternative — dropping it — was rejected. The premise that it could not be regenerated (`tech-debt.md` W1-11's "the assembler's `.aid/.temp/summarize/` input tree no longer exists") is false: `/aid-summarize` reads the KB directly and writes that gitignored scratch tree itself during a run, so a fresh run recreates it; W1-11 is corrected. The file is **stale, not unregenerable**. Recorded with its two real costs rather than as a free step: the run is ~24 minutes, and its visual gate is an orchestrator step because Playwright is not installed in the summarize package. Consequences downstream: feature-001's AC-6 `kb.html` oracle becomes satisfiable and no carrier is dropped; feature-006 owns the single re-run, last of all; delivery-003 carries it as a Scope item and a gate criterion | owner decision / /aid-plan |

## 1. Objective

Add a set of skills to the AID roster covering the work that happens **before
implementation** — brainstorming the solution, building a roadmap, defining an
MVP, and pinning down foundations (tech stack, architecture, testing standards,
CI/CD).

The outcome sought: make the up-front thinking a first-class, tracked part of the
AID methodology, rather than something that happens in someone's head or a scratch
document.

The set is defined in § 5.3: a `design → create → update` lifecycle applied to seven
new design artifacts (21 skills), a `design` stage added to the fourteen artifacts
that already have a create/update pair (14 skills), and `/aid-brainstorm`, which is
exploratory and has no create/update counterpart — 36 new skills in total.

## 2. Problem Statement

AID's numbered pipeline begins at Describe, which presumes the shape of the thing
being built is already known. The reasoning that produces that shape — exploring
solution options, sequencing them into a roadmap, drawing the MVP line, and
choosing the foundational technical standards — has no phase, no skill, and no
tracked artifact in the methodology today.

The consequence: these decisions are made informally, are not graded, are not
reviewable, and do not reach the Knowledge Base — so no downstream agent can read
them, and no gate can catch a bad one.

A second, narrower gap sits alongside it: the KB can describe what a project *is*
but not what it has *committed to* or what it has *defined but not scheduled*.

## 3. Users & Stakeholders

| Stakeholder | Interest |
|-------------|----------|
| **Adopters starting a new project** | The primary beneficiary — they gain a tracked, gated way to do inception work that currently happens informally. |
| **Adopters on an existing project** | Use the same skills to author foundations that were never written down, and to keep roadmap/backlog current. |
| **AI agents consuming the KB** | Gain two new documents (`roadmap.md`, `backlog.md`) answering "what is committed" and "what is defined but unscheduled" — questions the KB cannot answer today. |
| **AID maintainer** | Absorbs the roster growth (76 → 112) and the render/catalog/test consequences. |

## 4. Scope

### In Scope

- **The design skill family.** Today this family holds three skills: `/aid-design`
  (a kept design artifact), `/aid-prototype` (a throwaway model), and
  `/aid-prototype-ui`.
  This work extends that family with new skills covering pre-implementation
  thinking (§ 5.3).
- **`.aid/design/` as the artifact home.** A sibling of `.aid/knowledge/`, holding
  design artifacts *under construction*. The folder is an existing, documented
  convention (see § 8), currently filled by hand; this work makes the new skills
  produce and mature its contents.

- **A narrow amendment to the KB's doc-admission doctrine.**
  `canonical/aid/templates/kb-authoring/concern-model.md` § "Why product-concerns,
  not governance-artifacts" bans governance artifacts from the KB, naming *"a plan,
  a backlog, a register"* explicitly; `authoring-conventions.md` § Concern Model
  restates it. Both are amended so that **project-level** forward-looking documents
  are admissible while the ban on **per-work** sprint artifacts stands.

  The reasoning to be recorded: the rule's own escape hatch is that governance
  artifacts "map to AID's own pipeline artifacts (`REQUIREMENTS.md`, `SPEC.md`,
  `PLAN.md`, the per-work `STATE.md`), which already exist." That premise fails —
  every one of those is per-work and transient, pruned when the work ships — so no
  durable, project-level home exists for a cross-work roadmap or backlog.

  This is **adopter-facing**: `concern-model.md` is a canonical template rendering to
  all five profiles. Without the amendment, an adopter's KB review would reject the
  two documents AID itself installed (FR-9).

- **Promotion of settled foundational content into the Knowledge Base.**
  Once a foundational decision (tech stack, architecture, testing standards,
  CI/CD) is settled, it is promoted into `.aid/knowledge/`, placed in the correct
  existing KB document according to the KB's own authoring rules — because the KB
  is what agents ingest. `.aid/design/` holds it only while it is undecided.

- **Regenerating `.aid/knowledge/kb.html`.** The KB summary is a *generated* final-state
  artifact, and this work moves nearly every figure it states. It is therefore rebuilt by
  re-running `/aid-summarize` — once, after the roster and the KB have settled — rather
  than hand-patched, which would leave a copy that is neither current nor reproducible.

  This overturns a premise carried from `tech-debt.md` W1-11, which claimed the file
  "cannot be regenerated" because the assembler's `.aid/.temp/summarize/` input tree no
  longer exists. Verified false: `/aid-summarize`'s GENERATE state reads
  `.aid/knowledge/*.md` **directly** and *writes* that tree itself while a run is in
  flight; the path is gitignored scratch space, so a fresh run recreates it. W1-11 has
  been corrected accordingly.

  Two costs are in scope with it, and neither is hidden: the run is authored and long
  (~24 minutes on the last recorded full GENERATE), and its **visual** gate is an
  orchestrator step rather than an automated one, because Playwright is not installed in
  the summarize package. This work therefore promises the machine half plus a recorded
  human V1 verdict — not a passing automated visual gate.

- **A triggering-quality sweep over every skill description in the roster** (AC-12) —
  all 112, old and new: the 34 generated doorways via one template edit, plus the 78
  hand-authored bodies individually. Admitted into this work rather than deferred for
  three reasons. First, the work already touches every one of those files, so a separate
  later pass would re-open the whole roster to do a second edit to the same frontmatter
  blocks. Second, the 36 skills this work adds would otherwise ship carrying the very
  defect the sweep exists to remove, and would then need retrofitting. Third, feature-006
  already owns a whole-set description sweep for negative routing (AC-8), so the file set,
  the reviewer, and the re-render are shared — this widens an existing pass rather than
  adding one.

  What is **not** in scope with it: the `SKILL.md` **body** size guidance (three skills
  exceed it; that is a restructuring job into `references/`, a different kind of change
  with a different blast radius), moving `argument-hint` under `metadata:`, and making
  skills self-contained. Those are recorded as separate concerns and deliberately left
  out — this is a description-only sweep.

### Out of Scope

- Restructuring `canonical/skills/` into grouping folders. The flat 76-directory
  layout is unchanged; "design folder" refers to `.aid/design/` (an artifact home)
  and to the conceptual skill family, not to a directory under `canonical/skills/`.
- **Dictating a human-facing export format or location.** A user may extract KB
  content into a document format and folder of their choosing; that varies greatly
  per project and AID does not prescribe it. The authoritative copy is the KB.

- **The KB edit-history (`## Change Log`) doctrine conflict — RESOLVED UPSTREAM, no
  longer in play.** This work briefly took on the conflict, then deferred it. Both are
  now moot: **master resolved it in PR #183** (`chore(kb): remove all work references
  and the KB history apparatus`, plus `chore(kb): close the regeneration hazards the
  first pass left open`), merged into this branch on 2026-08-09.

  Post-merge state, verified: zero `.aid/knowledge/*.md` docs and zero canonical
  templates carry a `## Change Log`; `AS03` now asserts its **absence**, joined by
  `AS03b` (no `changelog:` frontmatter field) and `AS03c` (no `work-NNN` reference);
  the review gate at `reviewer-prompt-anatomy.md` forbids rather than mandates it.

  Consequence for this work: the new documents must be authored **without** a Change
  Log and must satisfy `AS03`/`AS03b`/`AS03c`. Nothing is deferred and nothing is
  owed to a follow-on work.

## 5. Functional Requirements

### 5.1 Knowledge Base doc-set additions

Two new KB documents are added. **Items** move through three documents, never
duplicated across them:

```
observed but unscheduled  →  defined + prioritized  →  shipped
    tech-debt.md                  backlog.md          release-tracking.md
```

**`roadmap.md` is not a stage in that flow** — it holds *direction* at a coarser
granularity than items. A roadmap entry says where the project is going and why; a
backlog item is a specific, prioritized piece of work. Correcting an earlier draft
that placed `roadmap.md` between `backlog.md` and `release-tracking.md`: that made a
committed item live in two documents at once, contradicting the move-not-copy rule in
the same paragraph.

| Doc | Status | Holds |
|-----|--------|-------|
| `tech-debt.md` | exists | Open items that are **not** properly defined or inserted into the product roadmap — raw, unprioritized |
| `backlog.md` | **new** | Items that **have** been properly defined and prioritized — the internal tracker the project currently lacks (an external tracker exists; an internal one does not) |
| `roadmap.md` | **new** | Present commitment and future direction — what the project has decided to do and why |
| `release-tracking.md` | exists | History of what shipped, per past release |

An item's promotion criterion is explicit: it leaves `tech-debt.md` for `backlog.md`
exactly when it acquires a definition and a priority.

`release-tracking.md` becomes **purely historical**: every section is a shipped
version. Its `## Unreleased` section moves into `backlog.md` as the "next release"
slice. At tag time the release flow drains the committed items from `backlog.md`
into a new `release-tracking.md` version section.

**FR-9 — The new documents are CONDITIONAL, created on demand — the seed does not
move.** The KB doc-set has **14 canonical templates** under
`canonical/aid/templates/knowledge-base/`. `roadmap.md`, `backlog.md`,
`release-tracking.md`, and `quality-gates.md` are none of them — the last two are
AID-dogfood-only extension docs.

They are admitted as **conditional** documents, following the `decisions.md`
precedent (`concern-model.md:96` — *"conditional, not a seed doc"*), **not** as
required seed members. Each is **created on first use by its own `create` skill**:
`/aid-create-roadmap` creates `roadmap.md` if absent, `/aid-create-backlog` creates
`backlog.md`, and so on. A project that never runs those skills never acquires the
documents — which is correct, because not every project has a roadmap.

**The canonical seed stays at 14.** This is the point of the decision: nothing in the
seed-count machinery moves. Untouched as a result — `synth_default_seed`'s ownership
map and its 15-doc references, `AS06`, `test-doc-set-read.sh` T02,
`test-doc-set-mapping.sh` T02, `test-domain-doc-matrix.sh` MT01/MT02/MT06 and the
matrix's byte-exact required row, `site/scripts` reference generators, and the ~20
count-bearing "14 standard documents" statements across the docs and their site
mirrors.

Conditional membership also resolves two defects that required membership created: an
unpopulated `roadmap.md` no longer trips the review gate's hollowness check, and
concern **D (Decisions)** becomes a legitimate assignment for `roadmap.md`, since
conditional is precisely what D is.

**Adopter reach is preserved.** `decisions.md` is conditional and adopters still get
it. Conditional means *created when applicable*, not *withheld*.

Note: `release-aid` — the automated consumer of `## Unreleased` — is repo-local
(`.claude/skills/release-aid/`) and **not** in `canonical/skills/`, so the
adopter-facing drain behavior still needs its own home or must be documented as
manual.

### 5.2 Two classes of skill

The KB documents are how AID organizes and tracks the items in a project. The new
skills divide into two classes serving that:

| Class | Purpose | Direction |
|-------|---------|-----------|
| **Build** | Help the user construct the documents — elicit the thinking, draft the artifact in `.aid/design/`, and promote it into the KB once settled | design → KB |
| **Format** | Help the user render the information the KB holds into whatever output shape they want | KB → output |

The Format class is **not empty today** — `/aid-summarize` (KB → `kb.html`),
`/aid-graph` (KB → `relationships.md` + `graph.html`), and the
`/aid-create-document` + `/aid-document-*` genre family already render information
into chosen output shapes.

**No standalone Format-class skills are added.** The capability is absorbed into
the `create` and `update` verbs (FR-1): each writes the KB document *and* whatever
other output the user asks for in the same run. A separate render-from-the-KB skill
per artifact was considered and rejected — it would have produced near-synonym name
pairs (`/aid-design-roadmap` vs a renderer of the same name) on opposite sides of
the KB write boundary.

### 5.3 The skill set

The family uses AID's existing verb+artifact grid on the free verb `design`, whose
bare row (`/aid-design`) already exists — mirroring how `aid-create` extends into
`aid-create-api`, `aid-create-cli`, and so on. The verbs `define` and `plan` are
**unavailable**: `/aid-define` and `/aid-plan` are already pipeline phases, so
`aid-define-*` would read as a sub-command of phase 3.

**FR-1 — The three-verb lifecycle.** Each design artifact moves through three
skills, one per lifecycle stage. The verbs denote *stage*, not direction, which is
what removes the naming hazard that `design-` vs `document-` created:

| Verb | Reads | Writes | Purpose |
|------|-------|--------|---------|
| `design` | `.aid/design/` | `.aid/design/` **only** | Develop the idea. Never touches the KB. Iterate until satisfied. |
| `create` | the current design in `.aid/design/` | the KB document **and** any other output the user wants | The realization event: commit the idea and materialize it. |
| `update` | the KB document, **and its `.aid/design/` seed when one is present** (CC-3) | the KB document **and** any previously created outputs | Maintain what exists. |

This aligns with `.aid/design/`'s own documented lifecycle
(`seed written → work scoped → work ships → seed deleted`): `/aid-create-*` is the
realization event, so it is the natural point at which the seed is consumed.

**KB write ownership (resolved).** `/aid-create-*` and `/aid-update-*` writing into
`.aid/knowledge/` is **not** a boundary violation. Several skills already write the
KB legitimately — `/aid-discover` (GENERATE), `/aid-describe` (DESCRIBE-SEED
forward-authoring), `/aid-housekeep` (KB-DELTA), `/aid-graph` (`relationships.md`).
The bar applies specifically to the `document` / `create-document` family, which
produces user-facing output. No delegation shim to `/aid-update-kb` is required.

| Artifact | `design` | `create` | `update` | KB destination |
|----------|----------|----------|----------|----------------|
| roadmap | `/aid-design-roadmap` | `/aid-create-roadmap` | `/aid-update-roadmap` | `roadmap.md` |
| backlog | `/aid-design-backlog` | `/aid-create-backlog` | `/aid-update-backlog` | `backlog.md` |
| mvp | `/aid-design-mvp` | `/aid-create-mvp` | `/aid-update-mvp` | `roadmap.md` § MVP |
| architecture | `/aid-design-architecture` | `/aid-create-architecture` | `/aid-update-architecture` | `architecture.md` |
| stack | `/aid-design-stack` | `/aid-create-stack` | `/aid-update-stack` | `technology-stack.md` |
| test strategy | `/aid-design-testing-strategy` | `/aid-create-testing-strategy` | `/aid-update-testing-strategy` | `test-landscape.md`, `quality-gates.md` (conditional — created on demand, FR-9) |
| ci/cd | `/aid-design-cicd` | `/aid-create-cicd` | `/aid-update-cicd` | `infrastructure.md` |

Plus `/aid-brainstorm` (exploration, no fixed destination) and the existing
`/aid-design` bare row.

**One owning skill per destination region.** `mvp` and `roadmap` share
`roadmap.md`, so ownership is split by section rather than by document: the MVP is
the first committed slice — the near end of the roadmap, not a peer of it — so
`/aid-*-mvp` owns a named `## MVP` section and `/aid-*-roadmap` owns the remainder
and must not overwrite that section. Every other artifact owns its whole
destination. (`testing-strategy` writes two documents; each region still has a
single owning skill.)

**A populated destination is the NORMAL case, not a refusal condition.** Four of the
seven destinations — `architecture.md`, `technology-stack.md`, `test-landscape.md`,
`infrastructure.md` — are canonical seed documents that exist and carry content in
every project that has run `/aid-discover`. A `create` skill that stops when its
destination file is non-empty would therefore never run at all on a brownfield
project, and the seed it was supposed to consume would have no consumer. That is not
a hypothetical: it is the state of this repository today.

So the rule is stated at the **region** level, which is the level ownership was
already defined at:

- The destination **document** existing or being populated never blocks `create`.
- `create` refuses only when **its own owned region** already carries committed
  content — and the response is to route the user to the corresponding `update`
  skill, never to halt with nothing done.
- Where the owned region is absent, `create` adds it. Where the destination document
  itself is absent (`roadmap.md`, `backlog.md` — the two conditional docs), the skill
  that **owns the whole document** creates it, which is exactly what "created on first
  use" means in FR-9.
- **A region-owning skill never creates the document.** `/aid-*-mvp` owns the `## MVP`
  section of `roadmap.md`, not `roadmap.md` itself. Running `/aid-create-mvp` against an
  absent `roadmap.md` therefore **routes to `/aid-create-roadmap`**, naming it, and
  leaves the seed in place — it does not create the document. This is what keeps AC-6a's
  "`/aid-*-mvp` writes only that section" literally true: a skill that scaffolded the
  whole document would necessarily write its preamble and index too.

**FR-2 — One skill per foundation.** The four foundation concerns (architecture,
stack, testing strategy, CI/CD) are separate skills rather than one switch-driven
`/aid-design-foundations`, because each lands in a different destination document
with different content rules and asks genuinely different questions.

**FR-3 — On-demand skills, not a pipeline phase.** These are invoked on demand, in
the same shape `/aid-design` and `/aid-prototype` already have: allocate a
`work-NNN` folder, run single-shot, get graded. The numbered pipeline
(`Discover → Describe → Define → Specify → Plan → Detail → Execute`) is unchanged,
and the closed `phase:` enum is **not** extended — avoiding a coordinated change
across `work-state-template.md`, both dashboard reader twins, `artifact-schemas.md`,
`pipeline-contracts.md`, and the agent-context files (C-1).

The "first-class and tracked" outcome of § 1 is satisfied by the work folder,
`STATE.md`, and review gate an on-demand skill already receives — not by phase
membership. Sequence is deliberately not imposed: stack sometimes precedes the MVP
line and sometimes follows it, and most projects need a subset of these skills
rather than all of them.

**FR-4 — All three verbs ship together.** Each of the seven design artifacts
receives all three verbs in this work (21 skills), plus `/aid-brainstorm`. The
`update` verb ships alongside the others rather than being deferred. Skill count is
explicitly **not** a constraint: these are distinct artifact types with distinct
functionality, not aliases.

**FR-5 — The `design` verb extends across the full create/update grid.** Every
artifact that today has a create/update pair also receives a `design` row, so the
**`design` stage** is available for every artifact rather than being special to the
seven new ones:

`api`, `ui`, `theme`, `cli`, `data-model`, `data-pipeline`, `messaging`,
`integration`, `job`, `config`, `infra`, `test`, `document`, `dashboard` — 14 rows.

**The `create` stage is NOT uniform, and must not be described as such.** The
fourteen existing `create`/`update` skills are shortcut-engine doorways: they run
`shortcut-engine.md` (INTAKE → … → APPROVAL-HALT) to produce a flattened Lite work,
they read `.aid/knowledge/INDEX.md` read-only, and they contain **zero**
`.aid/design/` references. FR-1's `create` contract — *consume the seed, write the
KB document* — is therefore false for all fourteen. Two artifact classes exist:

| Class | `design` writes | `create` produces |
|-------|-----------------|-------------------|
| The 7 design artifacts | `.aid/design/` | a **Knowledge Base document** (+ user outputs) |
| The 14 code artifacts | `.aid/design/` | the **built artifact**, via the existing shortcut engine — unchanged |

**FR-10 — The shortcut engine reads the seed when one exists.** So that `design` and
`create` compose for the fourteen code artifacts, `shortcut-engine.md` gains **one
additive read** at INTAKE/CAPTURE: if a `.aid/design/` seed exists for the artifact
being created, load it as prior context. When no seed is present, behavior is
byte-for-byte unchanged. Without this, `/aid-design-api` would write a document that
`/aid-create-api` never reads, leaving the user to paste it in by hand — the informal
workflow § 1 exists to replace.

**Blast radius to carry into planning:** `shortcut-engine.md` is the shared template the
**34 generated thin doorways** depend on — not all 58 catalog rows. The other 24 rows are
`repurpose: true` hand-authored skills that never enter the engine at all, so they are
untouched by this change. Of the 34, the new read fires only on the **26** with a
non-empty `artifact`. This is still the only change in the work that touches shipped
behavior of existing skills, and it is why C-6's "additive" claim is about *names and
rows*, not about *untouched files*.

> An earlier draft of this paragraph said "every one of the 58 existing catalog rows".
> 58 is the catalog size, not the engine's reach; the correction is recorded here rather
> than silently applied, because the figure had already been cited downstream.

**Roster arithmetic:** 21 (FR-4) + 1 (`/aid-brainstorm`) + 14 (FR-5) = **36 new
skills**, roster 76 → 112.

**FR-6 — Overlap resolutions.**

- **Bare `/aid-design` becomes the catch-all**, matching the existing bare-verb
  convention (bare `/aid-create` is "a new internal code artifact (module,
  interface, type)" — the fallback for artifacts with no dedicated row). Its
  current "architecture sketch" framing narrows accordingly, removing the overlap
  with `/aid-design-architecture`.
- **`/aid-design-ui` vs `/aid-prototype-ui` is not a collision** — it is the
  existing `design` = *kept* vs `prototype` = *throwaway* distinction applied to
  the `ui` artifact, the same rule that already separates `/aid-design` from
  `/aid-prototype`.
- **`test-strategy` is named `testing-strategy`** so it reads as policy rather
  than test code, keeping it distinct from the `test` artifact.

**FR-7 — `/aid-brainstorm` is kept, with mutual negative routing.** It serves the
case `/aid-research` cannot: a problem not yet formed into a question. The two
skills' descriptions must each name the other as the negative route, following the
existing `/aid-design` ↔ `/aid-prototype` precedent.

| | `/aid-research` | `/aid-brainstorm` |
|---|---|---|
| Input | A well-formed question | An unformed problem |
| Motion | Converges — evidence to an answer | Diverges first, then converges |
| Grounding | KB + code authoritative; web supplementary, cited | Generative; grounding is a check, not the source |
| Output | An answer in the work folder | A seed in `.aid/design/` |

**FR-8 — Derived outputs are resolved by asking, always.** `/aid-update-*` does not
discover the user's other documents by any tracking mechanism — no frontmatter
backlink, no manifest, no registry. It **asks the user** which documents to update,
every time. Consequently `/aid-create-*` writes no tracking metadata into the
outputs it generates, and no state is kept between runs.

**Rationale for admitting forward-looking docs into a KB that "describes what is":**
a committed decision is a present fact. "We have decided to do X next" is true *now*
and is what an agent needs; a design seed is "we might do X", which is not yet a
fact and stays in `.aid/design/`. This keeps `.aid/design/` and `.aid/knowledge/`
cleanly separated without an exception to the KB's governing rule.

**FR-11 — Cross-feature contracts, settled here once.**

Six features specify parts of one mechanism. Where two of them describe the same thing,
they disagreed — five independent spec reviews found the surviving CRITICAL and HIGH
findings concentrated almost entirely in cross-spec claims rather than within-spec
defects. Restating a shared rule in six places guarantees drift, so each rule below is
**stated here and referred to, never restated**, by the feature specs.

- **CC-1 — Resolved doc-set presence is `required`.** When a `create` skill creates a
  conditional document, the entry it appends to `.aid/settings.yml` `knowledge.doc_set`
  carries presence **`required`**, not `conditional`. The per-domain matrix answers
  *"would this document apply to a project of this kind?"* and is conditional; the
  resolved doc-set answers *"is this document expected for THIS project?"* and once the
  document exists the answer is yes. Precedent, not invention: `decisions.md` is
  `conditional:<when>` in `domain-doc-matrix.md` and `required` in this repo's
  `.aid/settings.yml`, and all 19 live entries are `required`.

- **CC-2 — The `create` skill writes the registration; no feature hand-edits it.**
  Appending the `doc_set` entry, adding the `README.md` Completeness row, and
  incrementing its doc-set count are **effects of running the `create` skill**, not
  separate edits by the feature that defines doctrine. Both being specified would
  double-count.

- **CC-3 — `update` reads its seed when one exists.** This amends the FR-1 table's
  `update` Reads column from "the KB document" to "the KB document, and its
  `.aid/design/` seed when one is present — consuming it as `create` would". Without
  this, a repeat `create` that routes the user to `update` leaves a seed on disk that
  nothing ever consumes. `update` still never *requires* a seed.

- **CC-4 — The registration surfaces are exactly four**, defined once in feature-001 and
  identical for every conditional KB document this work admits:
  1. `domain-doc-matrix.md` — a four-field row per applicable domain
  2. `concern-model.md` — named as conditional, with its concern id
  3. `document-expectations.md` — a `### <filename>` block
  4. `_dim_of_filename` — an entry in **both** script twins

  CC-1's doc-set entry is a runtime write by the `create` skill, not a fifth surface.
  No feature may substitute a different set of four.

- **CC-5 — A region-owning skill never creates its destination document.** Stated in
  FR-1; the only instance is `/aid-create-mvp`, which routes to `/aid-create-roadmap`.

- **CC-6 — Foundation destinations resolve by concern, not by filename.** The four
  foundation artifacts land in whichever document realizes their concern **in the
  project's domain** — `test-landscape.md` appears in only 2 of the 8 domain sections;
  other domains realize the same concern under different filenames. A hardcoded filename
  would be correct in a minority of domains. `roadmap.md` and `backlog.md` are exempt:
  they are domain-agnostic and filename-stable by construction.

- **CC-7 — The `design` family has 22 rows** when this work lands: 1 existing
  (`/aid-design`) + 14 grid rows + 7 for the design artifacts. Every count-bearing claim
  about the design family uses 22. `/aid-brainstorm` is a separate single-row `brainstorm`
  family.

- **CC-8 — There is no "unpaired artifact" exclusion rule.** The 14 grid rows are the
  artifacts carrying **both** a `create` and an `update` row — that is a positive
  selection, not an exclusion. Artifacts appearing only on other verbs (`decision`,
  `security`, `runbook`, and eight more) are simply outside that selection, and some of
  them — `architecture` above all — **do** receive a `design` row, as one of the seven
  design artifacts. Any statement that a given artifact is "excluded because unpaired"
  is wrong.

- **CC-9 — Confusable-pair ownership.** Each pair's mutual negative routing is written by
  the feature that ships the *newer* side; where both sides are new, by the lower-numbered
  feature. The complete pair set is verified only in the close-out feature, because
  cross-feature pairs cannot be checked while one side is unwritten.

## 6. Non-Functional Requirements

- **NFR-1 — Render parity.** All 36 skills exist in `canonical/` and render to all
  five profiles (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`).
  The byte-identity gate must pass; the repo-root dogfood `.claude/` is resynced
  from `profiles/claude-code/` after the generator runs.
- **NFR-2 — Catalog integrity.** Every new skill is a catalog row whose `name`
  equals its directory name, with `alias_of: null`. Hand-authored rows carry
  `repurpose: true` so `build-shortcut-skills.py` does not overwrite them.
- **NFR-3 — No new pipeline concepts.** No new phase, no new `phase:` enum value,
  no change to the work/delivery/task hierarchy. The skills reuse the existing
  on-demand shape (`work-NNN` folder, `STATE.md`, review gate).
- **NFR-4 — Discoverability over count.** With 36 additions, every skill
  description must state what it does *and* name its nearest neighbour as a
  negative route wherever two skills could plausibly be confused.
- **NFR-5 — Grade floor.** Every artifact this work produces meets the configured
  minimum grade (currently `A`).

## 7. Constraints

- **C-1 — The `phase:` enum is closed and untouched.** It is defined at
  `canonical/aid/templates/work-state-template.md` (`phase: Describe | Define |
  Specify | Plan | Detail | Execute`). Extending it would require coordinated
  changes across that template, both dashboard reader twins, `artifact-schemas.md`,
  `pipeline-contracts.md`, and the agent-context files. (The KB's `schemas.md`
  carries no phase enum.)
- **C-2 — Verb availability.** `define` and `plan` are unavailable (existing
  pipeline phases). `render` is unavailable (a glossary spine concept — the
  Canonical-Source Render-and-Vendor Pipeline). `design`, `create`, and `update`
  are the verbs used.
- **C-3 — KB authoring rules bind the new documents.** `roadmap.md` and
  `backlog.md` must carry no work id and no work-folder path, and no
  `## Change Log` section or `changelog:` frontmatter field.
- **C-4 — `.aid/design/` is not on `master`.** It exists only on the
  `docs/graph-redesign-seed` branch and must be landed as part of this work.
- **C-5 — Generator discipline.** After any catalog edit, run
  `build-shortcut-skills.py` then the **full** `run_generator.py` — never a
  partial render.
- **C-6 — Release impact.** The skill-roster change is purely **additive** (36 new
  rows, no renames — the `/aid-document-architecture` rename disappeared when
  `create`/`update` was chosen over an `export` verb), so the roster alone does not
  force a major. Three changes **are** adopter-facing:
  1. **`release-tracking.md` loses its `## Unreleased` section**, whose content moves
     to `backlog.md` (AC-4). This is the only content migration in the work, and it
     touches only projects that actually have an `## Unreleased` section.
  2. **The doc-admission doctrine changes** (§4). `concern-model.md` and
     `authoring-conventions.md` render to all five profiles, so every adopter's KB
     authoring rules change — narrowly, but really.
  3. **Three new canonical templates ship** — `design-lifecycle.md`, `design-seed.md`,
     and `design-folder-readme.md` under `canonical/aid/templates/`. They render to all
     five profiles, so every adopter acquires them on upgrade. Additive and
     non-migration-bearing (nothing existing changes shape), but adopter-facing, and
     listing only two changes understated the surface.

  **The KB seed count does not move.** An earlier draft of this constraint said the
  doc-set grows 14 → 17 canonical templates; FR-9's re-scope removed that, and the
  clause is struck rather than softened — the new documents are conditional, carry no
  template, and add nothing to the seed. No adopter KB requires a structural migration.
  The edit-history doctrine conflict — which would have been genuinely breaking — was
  resolved upstream and is no longer part of this work (§4 Out of Scope).

## 8. Assumptions & Dependencies

- **`.aid/design/` is an established convention, not a new invention.** Its README
  defines a *seed* as a scoping note for not-yet-started work — problem, evidence,
  intended shape, constraints — with the lifecycle
  `seed written → work scoped → work ships → seed deleted`, and the governing
  distinction "the KB describes what **is**; a seed describes what **should be**."
- The folder is **not currently on `master`** — it lives on the
  `docs/graph-redesign-seed` branch (`README.md` + one seed). Landing it on master
  is a dependency of this work.
- The existing README refers to `/aid-interview` as the skill that picks a seed up.
  No such skill exists in the current 76-skill roster; the full-path entry is
  `/aid-describe`. The README needs correcting as part of this work.

## 9. Acceptance Criteria

- **AC-1** — All 36 skills exist in `canonical/skills/`, each with a catalog row,
  and render to all five profiles with the byte-identity gate green.
- **AC-2** — `.aid/design/` is on `master` with its README corrected (it currently
  names `/aid-interview`, which is not a skill in the roster; the full-path entry
  is `/aid-describe`).
- **AC-3** — `roadmap.md` and `backlog.md` are admitted as **conditional** documents,
  following the `decisions.md` precedent exactly: **neither has a template anywhere
  under `canonical/`**, each is carried as a row in `domain-doc-matrix.md` with a
  concern id, and each is created on first use by its own `create` skill. The absence
  of a template is not an omission — it is the mechanism by which the seed count stays
  at 14. The canonical seed count is **unchanged at 14**, and every count-bearing
  assertion listed in FR-9 remains green **without modification** — that is the
  checkable form of this decision.
- **AC-3a** — Given a project that has never run `/aid-create-roadmap`, when its KB is
  reviewed, then `roadmap.md` is absent and no gate reports a missing or hollow
  document.
- **AC-4** — `release-tracking.md` contains no `## Unreleased` section; its content
  has moved to `backlog.md`, and the release flow drains committed items from
  `backlog.md` into a new version section at tag time.
- **AC-5** — `tech-debt.md`'s work-named section is gone: its items either moved to
  `backlog.md` (defined and prioritized) or remain as compliant, work-anonymous
  debt entries.
- **AC-6** — For each of the seven design artifacts, running
  `design` → `create` → `update` in sequence produces a `.aid/design/` seed, then the
  KB document, then a revision of it — with the seed consumed at `create`.
- **AC-6b** — The sequence in AC-6 completes on a **brownfield** project, where the
  destination document already exists and carries content. Concretely: in this
  repository as it stands, `/aid-design-architecture` → `/aid-create-architecture`
  reaches the realization event and consumes the seed, rather than refusing because
  `architecture.md` is populated. A `create` skill that cannot fire on a populated
  destination fails this criterion.
- **AC-6a** — `/aid-create-roadmap` and `/aid-update-roadmap` leave `roadmap.md`'s
  `## MVP` section intact; `/aid-*-mvp` writes only that section.
- **AC-7** — `/aid-update-*` prompts for the user's derived documents on every
  run, and no tracking metadata is written into generated outputs (FR-8).
- **AC-8** — No skill pair that could be confused lacks mutual negative routing in
  its description (`/aid-brainstorm` ↔ `/aid-research`, `/aid-design-*` ↔
  `/aid-prototype-*`, bare `/aid-design` ↔ the artifact rows).
- **AC-9** — The `phase:` enum, the work/delivery/task hierarchy, and the numbered
  pipeline are unchanged (C-1, NFR-3).
- **AC-10** — Given a `.aid/design/` seed exists for an artifact, when its
  `/aid-create-*` engine doorway runs, then the seed is loaded as prior context; and
  given no seed exists, then engine behavior is unchanged (FR-10).
- **AC-11** — Every count-bearing catalog assertion moves together, not just the
  headline two: `TOTAL_ROWS`, `CANONICAL_ROWS`, the zero-alias assertion, and the
  `repurpose` decomposition (today `24 + 34 = 58`) in
  `tests/canonical/test-deploy-monitor-repurpose.sh` and
  `tests/canonical/test-catalog-dirs-parity.sh`.
- **AC-12** — Every skill description in the roster — the **34** generated doorways and
  the **78** hand-authored bodies, 112 in total, old and new alike — states **what the
  skill does and when to use it**, in the imperative form the Agent Skills standard
  requires ("Use this skill when…", not "This skill does…"). Checkable in five parts,
  each mechanical:
  1. `grep -c` of each `description:` block's character count is **≤ 1024** for all 112.
     Today one skill fails this outright (`aid-update-ticket`, 1096) and one sits 18
     characters from the cap (`aid-create-ticket`, 1006).
  2. No description contains a state-machine transition sequence, a `VERB=`/`ARTIFACT=`
     binding, or the phrase `Direct-entry Lite-path shortcut`. These are implementation
     mechanics; the standard's rule is to describe user intent instead. Today **54** of 76
     leak state-machine text and **34** open with the `Direct-entry` boilerplate.
  3. The generated-doorway description is produced from a template that **leads with the
     catalog row's `intent`** rather than burying it in parentheses. The template is a
     single f-string at `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`
     § the `frontmatter = (` assignment — one edit covers all 34, and hand-editing
     generated output instead would be overwritten on the next render.
  4. Every description names the user-facing outcome before any AID-internal vocabulary.
  5. The byte-identity gate is green after re-render, and the `shortcuts` (emitting) count
     is **still 34** — no description change may move a count-bearing assertion (AC-11).

  This extends feature-006 § *whole-set pair check*, which already owns the cross-skill
  negative-routing sweep over the 36 new skills (AC-8), from routing-completeness to
  **triggering quality over the whole roster**. The two are one sweep over one file set,
  so they are closed together rather than in two passes over the same 112 files.

  **Rationale (recorded because it is not derivable from the codebase).** An audit of the
  roster against the Agent Skills standard found AID compliant on every strictly-required
  rule — all 76 have a valid `name` matching their directory, a non-empty `description`,
  and correct frontmatter shape — but found the descriptions spending their budget on
  internals rather than on triggering. Only **2** of 76 carry an explicit trigger clause.
  The description is the sole mechanism an agent uses to decide whether a skill loads at
  all, so a description that does not say *when* leaves the skill unreachable no matter
  how good its body is. Median length is 450 characters against a 1024 cap, so the fix is
  a reallocation of the existing budget, not an expansion.

## 10. Priority

**High.** This work ships as part of **v3.0.0**, folded into that release rather
than deferred behind it.

The skill-roster change is additive (C-6), so it does not itself force the major;
it rides the major that the 111 → 76 migration already requires. Release cut
timing is the maintainer's decision.
