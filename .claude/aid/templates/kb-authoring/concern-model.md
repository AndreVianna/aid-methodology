# KB Authoring -- Concern Model

> Normative model for deriving a project's KB doc set from a stable, universal set of
> concerns (the durable questions a newcomer must answer). Consumed by `aid-discover`
> (doc-set proposal), `aid-config` (scaffold), and `aid-summarize` (concept-spine section).
> See [README.md](README.md) for the full kb-authoring index.

---

## Why concerns, not project types

A doc set derived from project types (web-app, library, CLI...) requires a new enum
value for every hybrid; one sized to fit "how a newcomer thinks" scales to any project.
REQUIREMENTS §1.3 identifies the stable, cross-cutting questions a newcomer must answer
regardless of project type. This model makes those questions the derivation spine.

The doc set is **proposed -> confirmed** with the user (see *Propose->confirm rules*
below). A concern may split into several docs, or a project-specific doc may be added;
the confirmed set is persisted in `discovery.doc_set` (`.aid/settings.yml`). The concern
list itself is fixed (T2 cardinality contract -- see below); only the doc realization
varies per project, and every variation is human-confirmed.

---

## The domain-agnostic dimension spine

The concern list is the **software rendering** of a deeper, domain-agnostic structure: a
fixed **dimension spine** -- the set of **universal questions any digital deliverable must
answer about itself**, regardless of whether it is software, data/ML, content, research,
design, or ops. AID helps with *any kind of digital work*; the spine is what makes the
doc-set derivation generalize beyond software (feature-014). Only the spine's *realization*
(which docs, named how) varies per domain; the dimensions themselves do not.

The numbered concerns below (C0-C9, + D) are how the spine **renders for a software
project**. A non-software project answers the *same dimensions* with a domain-appropriate
doc set, resolved via the domain->doc-set matrix (see
`.claude/aid/templates/kb-authoring/domain-doc-matrix.md`); "did we cover everything?"
is always answered by walking the fixed spine.

**Standards grounding.** The spine is the cross-standard recurring-concern set distilled
from the software/architecture documentation standards. Each dimension is attested by one
or more published standards:

| Spine dimension (domain-agnostic) | Software rendering (concern) | Grounded in |
|---|---|---|
| What it does for users (capabilities, context, scope) | C9 feature-inventory | arc42 §1/§3, C4-L1, ISO/IEC/IEEE 42010 (entity/stakeholders) |
| What it is made of (structure / anatomy) | C1 project-structure, architecture | arc42 §5, C4-L1..3, IEEE 1016 composition |
| How the parts connect | C2 module-map, integration-map, pipeline-contracts | arc42 §5, C4, IEEE 1016 dependency/interface |
| What it is built with (technology / medium) | C0 technology-stack | arc42 §4, C4-L2 |
| Conventions & cross-cutting approaches | C3 coding-standards | arc42 §2/§8, IEEE 1016 patterns |
| Vocabulary / glossary | C4 domain-glossary | arc42 §12 |
| Deliverables, data & contracts | C5 schemas | arc42 §3/§8, IEEE 1016 information/interface |
| Quality & how it is checked | C6 test-landscape | arc42 §10, IEEE 1016 |
| Risk & debt | C7 tech-debt | arc42 §11 (uniquely explicit) |
| How it ships & operates | C8 infrastructure | arc42 §7, C4-deployment |
| **Decisions & rationale** | **D** decisions (conditional -- see below) | arc42 §9, ADR, ISO/IEC/IEEE 42010 decision annex |
| Stakeholders & concerns (meta) | (interview / requirements -- pipeline, not KB) | ISO/IEC/IEEE 42010 root |

The last row -- *stakeholders & concerns* -- is a **meta** dimension answered by AID's
interview/requirements pipeline, not by a KB doc; it anchors the spine in ISO/IEC/IEEE
42010 but is out of KB scope (see the governance note below).

### Why product-concerns, not governance-artifacts

The spine and the KB capture what a deliverable **is** -- its durable product/architecture
concerns. They deliberately exclude the **governance** layer: project-management artifacts
such as a project charter, schedule/plan, risk and stakeholder registers, or a sprint
backlog (PMBOK / PRINCE2 / Scrum). Those frameworks are real and necessary, but they
describe *how the work is run*, not *what the deliverable is*, and they map to AID's own
**pipeline artifacts** (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, the per-work `STATE.md`
tracking), which already exist. The KB is the product layer; the pipeline is the governance
layer. A doc proposed for the KB that is really a governance artifact (a plan, a backlog, a
register) is a scope smell -- route it to the pipeline, not the doc-set.

---

## The 11 universal concerns (C1-C9 + C0 + D)

Each concern has an id, the question it answers, its definition (what belongs / what does
not), and its **default doc(s)**. C0-C9 (ten concerns) are the **15-doc default seed**;
**D (Decisions)** is the eleventh dimension, realized as a **conditional** doc -- it is part
of the fixed spine but is **not** one of the 15 seed docs (see *Seed-coverage check* below).

| Id | Concern | The question a newcomer must answer | Default doc(s) |
|----|---------|--------------------------------------|----------------|
| C1 | **Build & shape** | How is it built? What is its overall structure/anatomy? | `project-structure.md`, `architecture.md` |
| C2 | **Parts & connections** | What are the parts and how do they connect? | `module-map.md`, `integration-map.md`, `pipeline-contracts.md` |
| C3 | **Conventions** | What conventions and standards does it follow? | `coding-standards.md` |
| C4 | **Vocabulary** | What is its native vocabulary / ubiquitous language? | `domain-glossary.md` |
| C5 | **Data & contracts** | What are its data shapes and structural contracts? | `schemas.md` |
| C6 | **Quality & testing** | How is it tested? How healthy is it? | `test-landscape.md` |
| C7 | **Risk & debt** | What is risky, owed, or worked around? | `tech-debt.md` |
| C8 | **Shipping & operation** | How does it ship and run? | `infrastructure.md` |
| C9 | **What it does for users** | What does it do for its users / what are its capabilities? | `feature-inventory.md` |
| C0 | **Technology** | What is it built *with* (languages, frameworks, runtime)? | `technology-stack.md` |
| D | **Decisions & rationale** | Why is it the way it is -- what was decided, why, and what was rejected? | `decisions.md` (ADR-log) -- **conditional**, not a seed doc |

### D -- Decisions & rationale (the eleventh dimension)

**Decisions** answers *why the deliverable is the way it is*: the significant choices made,
their context and rationale, and the alternatives rejected. It is the one
evidence-attested dimension absent from the original software concern list, and it is
attested across the standards (arc42 §9 "Architecture Decisions", the ADR / decision-record
practice, and the ISO/IEC/IEEE 42010 decision/rationale annex).

It is promoted to the spine as a **conditional** doc (`decisions.md`, an ADR-log) rather
than a seed doc: many projects record no durable architecture decisions, and forcing an
empty ADR-log onto every project would over-generate. A project that has made significant,
rationale-bearing decisions adds `decisions.md` under D via the propose->confirm gate; a
project that has not leaves D covered-by-conditional. Because `decisions.md` is **not**
added to `synth_default_seed`, the byte-stable 15-doc software seed is unchanged (see
*Seed-coverage check*). In `doc-set-resolve.md`-style declarations it appears as
`decisions.md|aid-researcher-architecture|conditional`.

**Orientation / meta (cross-cutting, not a newcomer concern):**
`external-sources.md`, `README.md` (owned by `skill-self`) are cross-cutting registry /
completeness docs, not newcomer concerns. `INDEX.md` is generated meta. None are mapped
to a concern; they are produced by the skill itself.

> **Note on C5 and C0.** REQUIREMENTS §1.3 names eight concerns: "how built / what parts
> and how connect / what conventions / what vocabulary / how tested / what's risky-owed /
> how ships / what for users." C0 (technology) and C5 (data & contracts) are derived, not
> in §1.3's eight: C0 is split out of "built" because the seed dedicates
> `technology-stack.md` to it; C5 is split out of "parts" because the seed dedicates
> `schemas.md` to it. The split ensures the concern map is **total** -- every seed doc
> maps to exactly one concern (none unmapped, none duplicated).

---

## T2 cardinality contract

The concern list is a **T2 Structure** (per [tier-model.md](tier-model.md)): fixed and
stable (weeks-to-months horizon), not per-project-variable. Downstream proposal logic
depends on iterating a closed list of concerns ("have we covered every concern?"), so the
count MUST NOT grow by project-level adaptation. Adaptivity is in the *doc realization*
(split, add, conditional), never in the concern list itself.

**Contract:** exactly **11 dimensions** -- the ten numbered concerns (C0, C1 through C9)
plus **D (Decisions)**. A dimension is never added per project; a doc may be added under an
existing dimension. The spine grows only by deliberate, standards-grounded revision of this
model (as when D was added from arc42 §9 / ADR / ISO 42010), never by project-level
adaptation.

**Seed vs. spine.** Of the 11 dimensions, C0-C9 (ten) are realized by the 15-doc default
seed (`synth_default_seed`); **D is realized by a conditional doc** (`decisions.md`) and is
**not** part of the seed. Adding D to the spine therefore changes the dimension count
(10->11) **without** changing the byte-stable software seed -- the seed is still exactly the
15 docs (see *Seed-coverage check*).

---

## Seed-coverage check

The **C0-C9** "Default doc(s)" entries map exactly the **15** `synth_default_seed`
templates -- none unmapped, none duplicated:

- **C1:** `project-structure.md`, `architecture.md`
- **C2:** `module-map.md`, `integration-map.md`, `pipeline-contracts.md`
- **C3:** `coding-standards.md`
- **C4:** `domain-glossary.md` (the concept-spine doc)
- **C5:** `schemas.md`
- **C6:** `test-landscape.md`
- **C7:** `tech-debt.md`
- **C8:** `infrastructure.md`
- **C9:** `feature-inventory.md`
- **C0:** `technology-stack.md`
- **Orientation (not a concern):** `external-sources.md`, `README.md`

That is 15 distinct seed docs. `INDEX.md` is generated meta, not a `knowledge-base/*.md`
template, so it is excluded from the seed count.

**D (Decisions) is conditional, NOT a seed doc.** The eleventh dimension is realized by
`decisions.md` (an ADR-log), which is **not** in `synth_default_seed` and is **not** one of
the 15 docs above. It is proposed only when a project has rationale-bearing decisions to
record (the propose->confirm gate), mirroring `repo-presentation.md` below. The spine count
is 11 dimensions; the byte-stable software seed remains exactly 15 docs. FR-37's
*covered-or-conditional* rule is satisfied: every spine dimension is covered by >=1 seed doc
**or** explicitly conditional (D).

`repo-presentation.md` is **NOT** a default seed doc. It is a conditional extension
example that a project MAY add under C9 (capabilities / user-facing presentation) via the
propose->confirm gate. It appears in `doc-set-resolve.md` as
`repo-presentation.md|aid-researcher-architecture|conditional`. Name it only as a
conditional extension example, never as a default.

---

## Document boundaries -- the three-force rule

A document boundary should fall where **three forces agree** (REQUIREMENTS §1.3):

1. **Coverage** -- a coherent concern: the doc answers one concern's question without
   mixing unrelated concerns. Mixing concerns is a boundary smell.
2. **Fit** -- right-sized for the project: not so large that no one reads it; not so small
   that the overhead exceeds the value. Use the propose->confirm gate to split oversized
   concerns.
3. **Audience & ownership** -- a natural owner-role who can maintain it, and an audience
   who can read it without needing another doc. When a single concern serves two distinct
   audiences who cannot share one doc (e.g. a C9 capabilities view for a non-technical PM
   vs. an architect's C2 internals), that is a **signal to split** -- propose distinct docs
   with distinct `audience:`/`owner:` per resulting doc at the gate.

A concern that no natural owner-role can maintain is a boundary smell raised at the gate.

### Audience axis vs. tier axis (orthogonal dimensions)

Three independent axes classify a KB doc:

| Axis | Question | Source |
|------|----------|--------|
| **Concern** | Which newcomer question does this doc answer? | This model |
| **Audience** | For whom is this doc written, at what altitude? | `owner:`/`audience:` frontmatter fields (f001) |
| **Tier** | How load-bearing is each fact to an agent? | [tier-model.md](tier-model.md) T1-T4 |

The **tier** axis (T1-T4) ranks by agent load-bearingness -- a different axis from human
audience. A senior-architect audience doc may carry T1 facts (concepts) without that
making it high-tier for agents. The audience axis is the one REQUIREMENTS §1.3 flags as
missing in the current model; f001 adds the fields, f002 renders the INDEX audience
column, and this model makes audience a boundary driver.

### Summary+pointer prevents audience duplication

The summary+pointer model (durable synthesis in the doc, volatile detail left in
`sources:`) dissolves the agent-vs-human fork: both want small chunks; a PM stops at
`summary:`, an architect follows `sources:` into code/spec. Audience decides *which* docs
exist (the split rule above), **not** layered-depth-within-a-doc or duplicate per-audience
docs.

---

## Propose->confirm rules

These rules govern how `aid-discover`'s recon/triage phase walks the concern list and
proposes the doc set for user confirmation:

### Split a large concern

When a concern is oversized for the project (e.g. a monorepo whose C2 "parts &
connections" spans several subsystems), propose one doc *per subsystem* under that concern:
`module-map-frontend.md` + `module-map-backend.md` -- each declared in
`discovery.doc_set` with its owner + a `conditional:<when>` hint, each tagged to C2. The
user confirms.

### Add a project-specific doc

When the project has a concern-relevant area no seed doc covers (e.g. `ml-pipeline.md`
for a data project under C2/C5), propose a new `discovery.doc_set` row mapped to the
nearest concern. The user confirms.

### Mark conditional / drop

A concern whose default doc does not apply (e.g. `infrastructure.md`/C8 for a library
with no deployment) is proposed as `conditional` (the existing `presence` field). The user
confirms presence at the gate.

### Invariant

The proposal logic MUST NOT invent a doc that is not anchored to a spine dimension. Every
dimension must be **covered by at least one confirmed doc or explicitly marked conditional**
(e.g. D / Decisions, which is conditional by default). The C4 Vocabulary concern is always
covered by the concept-spine doc (`domain-glossary.md`) -- see f004. "Did we cover
everything?" is answerable by iterating the fixed spine.

---

## Ownership (freshness, not INDEX)

`owner:` (from f001 frontmatter) is the freshness-accountability field: who is responsible
for keeping the doc current (consumed by f007). It is NOT rendered as an INDEX column
(f001/f002 confirm `owner:` is parsed but not rendered in the table). In the three-force
boundary rule, `owner:` is the third force: a doc must have a natural owner-role who can
maintain it; a concern that no one can own is a boundary smell raised at the gate.

---

---

## Operational guidance is first-class structure

A concern doc that carries operational guidance MUST express it as **named, greppable
sections** within the doc -- not interleaved prose. This rule extends the summary+pointer
model: just as summary+pointer prevents altitude drift, the named-section rule prevents
operational guidance (the conventions, invariants, gotchas, and contracts an agent acts
on) from being buried where it cannot be found or grepped.

**The rule:** where a doc carries operational guidance of class X, it carries it as the
named section for X. This is NOT "every doc carries all four sections" -- a glossary doc
(C4) need not carry `## Contracts`. The rule is: **if a doc owns guidance of class X
for its concern, that guidance lives in a named section for X**.

### The four operational-guidance classes and their owning section headings

| Class | Named section heading | What it states | Owning concern(s) | Default owning doc(s) |
|-------|-----------------------|----------------|-------------------|-----------------------|
| **Conventions** | `## Conventions` | The project's *own way* of doing a recurring change (naming, registration, wiring of a new endpoint/module/handler). Without it an agent invents a convention wrong for this project. | C3 Conventions; the relevant parts/contracts docs (C2, C5) | `coding-standards.md`; `module-map.md`, `pipeline-contracts.md` |
| **Invariants** | `## Invariants` | What MUST always hold (an ordering, a non-null, a single-source-of-truth rule). Without it an agent violates an invariant the source enforces silently. | C1 Build & shape; C2 Parts & connections; C4 Vocabulary (for conceptual invariants in the spine) | `architecture.md`; `module-map.md`; `domain-glossary.md` |
| **Gotchas** | `## Gotchas` | The non-obvious trap (a config that must change in lockstep, a build step, an ordering hazard) -- exactly the KB's §1.2 delta-value from what a newcomer cannot infer. | C7 Risk & debt; the concern the gotcha lives in | `tech-debt.md`; the relevant concern doc |
| **Contracts** | `## Contracts` | The structural shape a change must satisfy (a schema, an interface, a pipeline contract). Without it an agent's change breaks integration. | C5 Data & contracts; C2 Parts & connections | `schemas.md`; `pipeline-contracts.md`, `integration-map.md` |

**These headings are the single source of truth** for what `kb-actback-task.sh`'s
operational-structure presence check greps and what the M6 act-back mandate names in its
prompt. Any project-renamed equivalent (e.g. `## Naming rules` for Conventions in a
project where that framing is more natural) must be enumerated in the project's
`.aid/knowledge/.review-checklist.md` so the presence check can find it.

### Scoping rule (prevents over-reporting)

`kb-actback-task.sh`'s presence check consumes this owning-table to scope which classes
each doc is **expected** to carry. It reports `present|absent` **only for expected classes**.
A doc the table does not map as a Contracts owner (e.g. `domain-glossary.md`) is NOT
reported `## Contracts absent` -- only a doc the table maps as a Contracts owner (e.g.
`schemas.md`, `pipeline-contracts.md`) is checked for `## Contracts`. This prevents the
presence check from over-reporting legitimate absences.

---

## See also

- [tier-model.md](tier-model.md) -- T1-T4 fact stability tiers (the tier axis)
- [principles.md](principles.md) -- normative authoring rules (see "Document boundary rule" section for the cross-ref)
- [frontmatter-schema.md](frontmatter-schema.md) -- `owner:`/`audience:` field schema (f001)
- [README.md](README.md) -- index of all kb-authoring docs
- `.claude/skills/aid-discover/references/doc-set-resolve.md` -- `synth_default_seed` + concern annotations
- `.claude/skills/aid-discover/references/document-expectations.md` -- per-doc research expectations (open-question form) + `## Spine-Dimension Depth Standards` section (one `### C<N>` block per dimension, single-sourced from this owning-table for the "Owns named section(s)" column)
