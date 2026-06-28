# Greenfield KB-Seed Authoring

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-1 (impl), §5 FR-3, §6 NFR-3/NFR-4, §9 AC-2/AC-5, §10 P1 | /aid-interview |
| 2026-06-27 | Technical Specification authored: seed-content model (5 elements + `source: forward-authored` marker + schema/lint/index/freshness edits), forward-authoring flow, greenfield-mode review gate, layered coherence check, sufficiency bar, exclusions, DoD; grounded in feature-001 findings.md Rec A + owner decisions D1/D2/D3 | /aid-specify |
| 2026-06-27 | Gate cycle-1 fixes: (MEDIUM) added the panel-exclusion reconciliation — `state-review.md:117-118` "Greenfield never reaches the panel" carved into two cases (discovery-triage skip stays; `greenfield:true` seed-review reaches the full panel per NFR-3); (LOW) corrected the schema-edit grounding (enum is table-only, no prose note; unknown values retained not coerced) | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-1 (impl), §5 FR-3, §6 NFR-3 / NFR-4, §9 AC-2 / AC-5, §10 P1

## Description

When a project has no code yet, the skill forward-authors a minimal-but-sufficient Knowledge-Base
seed by eliciting it from the user the way a seasoned analyst would — the inverse of the
brownfield extraction model, where the authored design docs ARE the source of truth and the code
is later built to conform to them. Grounded in the research spike, the seed's keystone is the
declared concept-spine / ubiquitous language, plus intended architecture, conventions and
standards, and technology stack — explicitly not the full brownfield doc-set (no module-map or
test-landscape, since there is no code). Like brownfield discovery, the seed's exact shape adapts
to the project's domain rather than being a fixed list. The sufficiency bar is the minimum needed
for the downstream phases (aid-specify / aid-plan / aid-execute) to act — no more, no bloat. As
part of authoring, the analyst runs an interview-time coherence check: it validates that the
forward-authored seed and the gathered requirements are mutually coherent (same work, no
contradictions) and surfaces any gaps or conflicts to the user for resolution before the work
proceeds. The finished seed must pass the same KB review / calibration gate (grade ≥ A) as an
extracted KB.

## User Stories

- As the work-definer (human) starting a from-scratch project, I want the skill to draw out and
  author a minimal KB seed from my intent so that the downstream phases have the knowledge they
  need even though no code exists yet.
- As a downstream AI agent (aid-specify / aid-plan / aid-execute), I want a seed that conforms to
  the existing KB contract and is sufficient to act on so that I can proceed without KB-gap
  loopbacks.
- As the work-definer, I want the analyst to check the seed and my requirements for coherence and
  flag conflicts so that contradictions are resolved before the work moves forward.

## Priority

Must

## Acceptance Criteria

- [ ] Given a code-less project, when the skill is run, then it yields a forward-authored KB seed
  that passes the KB review gate (≥ A) and is sufficient for aid-specify to proceed — measured by
  a clean aid-specify run with zero KB-gap loopbacks. *(AC-2)*
- [ ] Given a forward-authored seed and gathered requirements, when authoring completes, then the
  skill validates seed ↔ requirements coherence and surfaces any conflicts before proceeding.
  *(AC-5)*
- [ ] Given the sufficiency bar, when the seed is authored, then it contains the minimum needed
  for the downstream phases — not the full brownfield doc-set. *(AC-2, NFR-4)*

---

## Technical Specification

> Authored by `/aid-specify` from feature-001 `findings.md` (Rec A: RQ-A1..A5 + the D-5
> review-gate note), REQUIREMENTS.md (FR-1, FR-3, NFR-3, NFR-4, C-1, AC-2, AC-5), and the
> owner-ratified decisions D1/D2/D3 in `STATE.md ## Cross-phase Q&A`. Every design choice
> here is bounded by those sources; the elicitation *conversation* that produces the seed is
> NOT specified here -- it is feature-002's seasoned-analyst engine (see Scope boundary).

### Scope boundary (what this feature owns vs delegates)

| Owned by feature-003 (this spec) | Delegated to feature-002 (engine) |
|----------------------------------|------------------------------------|
| The **seed-content model** -- the 5 elements, their KB docs, `kb-category`, and per-element sufficiency criterion | The **conversation** that elicits each element (the move playbook, calibration, NFR-7, the single fixed opener then adaptive next-move selection -- D1/D2) |
| The `source: forward-authored` marker and the schema / lint / index / freshness edits (C-1) | The stopping rule's *conversational* enforcement (engine halts at minimal-but-sufficient) |
| The **greenfield-mode review gate** (the flag on `document-expectations.md`) | -- |
| The **layered coherence check** (FR-3 / AC-5) | The *act* of surfacing a conflict to the user as an NFR-7 question |
| The **sufficiency bar** (RQ-A5) and the **domain-adaptive shape** (RQ-A4) | -- |
| The **exclusions** (RQ-A2) | -- |

**Placement.** Per C-2 the seed-authoring logic is an additive state inside the existing
`canonical/skills/aid-interview/` skill (extend, do not fork). Per D3 (a future re-spec of
feature-006) the elicitation half of that skill becomes **`aid-describe`**; where placement
matters below, the seed-authoring step is named the `aid-describe` step, executed today by
`aid-interview`. The seed-authoring step runs AFTER the engine has gathered enough intent and
BEFORE `REQUIREMENTS.md` is approved.

### Data Model -- the seed-content model

The seed is **not** the 15-doc default; it is an invariant core of 4 docs plus 1 conditional
doc, each mapping to an existing KB document, concern dimension, and `kb-category`. The
per-element "sufficient" column is the objective fit criterion the seed-authoring step checks
before handing the seed to the review gate (RQ-A5).

| # | Seed element | KB doc | Concern | `kb-category` | Weight | "Sufficient" means (fit criterion) |
|---|--------------|--------|---------|---------------|--------|-------------------------------------|
| 1 | Declared concept-spine / ubiquitous language (keystone) | `domain-glossary.md` | C4 | `primary` | MANDATORY | Every load-bearing term defined **as this project uses it** (not generic), with its relationships and the term-boundary invariants (`## Invariants`); each term carries a concrete example; the work is explainable using only defined native terms + general knowledge (the C4 stopping bar). |
| 2 | Intended architecture (boundaries + relationships, sketch altitude) | `architecture.md` | C1 | `primary` | MANDATORY | Major parts + boundaries + relationships named, with the invariants a change must not break (`## Invariants`). Sketch altitude -- not an as-built layout. |
| 3 | Conventions & standards (thinnest element) | `coding-standards.md` (+ `authoring-conventions.md` for methodology projects) | C3 | `primary` | DEFERRABLE | The project's own declared rules stated, OR an explicit "standard for `<stack>`, no project-specific deviations yet" (owner decision D4-default). |
| 4 | Technology stack / medium | `technology-stack.md` | C0 | `primary` | DEFERRABLE | The chosen language / runtime / framework named. Version MAY be recorded as "latest-at-init / TBD-until-scaffolded" and the build command as "TBD" (owner decision 2); feature-005 reconciles once code exists. |
| 5 | Decisions & rationale (the elicited "why") | `decisions.md` | D | `extension` | CONDITIONAL | Present ONLY when rationale-bearing choices were made (propose->confirm gate); each decision states what + why + the rejected alternative (the D floor). Not forced when empty. |

**`kb-category` needs NO change.** The five docs are already classified by the existing
default-seed in `canonical/aid/templates/kb-authoring/concern-model.md`: elements 1-4 are
`kb-category: primary` (in `synth_default_seed`), and `decisions.md` is the conditional
`kb-category: extension` (an ADR-log, explicitly NOT in `synth_default_seed`). No `kb-category`
enum value is added or changed; the seed is fully expressible with `{primary, extension}`.

#### The `source: forward-authored` marker (the ONE permitted schema addition, C-1)

Every seed doc carries `source: forward-authored` in its frontmatter -- a new third value
beside the existing `hand-authored | generated` enum. Semantics: *authored from intent before
any code exists; the doc is design-authoritative (it leads, code conforms -- FR-4); it receives
full content review (same as `hand-authored`) but is exempt from source->doc freshness staleness
because it has no code-sources that lead it.* This is the single schema change C-1 permits; the
rest of the seed reuses the unchanged f001 frontmatter contract (`objective:`, `summary:`,
`sources:`, `tags:`, etc.). A seed doc's `sources:` is typically `sources: []` (pure intent) or
points at the elicited intent record (the gathered REQUIREMENTS / design note), never at code.

#### Exact schema / lint / index / freshness edits

These four files are the complete blast radius of the marker (C-1 enumerates exactly these three
scripts plus the schema doc):

1. **`canonical/aid/templates/kb-authoring/frontmatter-schema.md`** -- add a third row to the
   `source:` enum table (currently `hand-authored` | `generated`):

   | Value | Meaning |
   |-------|---------|
   | `forward-authored` | Authored from intent before code exists (the greenfield KB seed). **Full content review applies** (same rubric as `hand-authored`). The doc is **design-authoritative** (design->code, FR-4): freshness treats it as never-stale-from-source; code->design divergence is detected by feature-005's separate conformance check, NOT by f007. |

   Adding this third enum-table row is the **complete** schema-doc edit -- the `source:` values
   live ONLY in that table (there is no separate prose sentence enumerating them to update). The
   schema's existing parsing rules are left unchanged and already degrade safely: unknown `source:`
   VALUES are tolerated/retained (not coerced), and the only fallback-to-`hand-authored` cases are a
   hard parse FAILURE or an ABSENT `source:` field -- neither of which applies to a doc that
   explicitly carries `source: forward-authored`.

2. **`canonical/aid/scripts/kb/lint-frontmatter.sh`** -- the lint's in-scope predicate is
   `kb-category in {primary, extension} AND source != generated`. `forward-authored` is therefore
   **already in-scope** and receives the full presence + shape lint (objective/summary/sources
   required, etc.) -- which is exactly what we want (seed docs MUST be linted). The lint performs
   **no `source:`-enum membership check**, so `forward-authored` is accepted today without code
   change. The edit is: update the in-scope comment (header, lines ~5-8) to enumerate
   `forward-authored` alongside `hand-authored`/promoted; and IF a future `source:` allow-list
   check is ever added, it MUST include `forward-authored`. No skip branch is added (a seed doc
   must never be skipped).

3. **`canonical/aid/scripts/kb/build-kb-index.sh`** -- index generation groups strictly by
   `kb-category` (primary/meta/extension) and is **source-value-agnostic**; a `source:
   forward-authored` + `kb-category: primary` doc renders in the Primary table identically to a
   hand-authored one. **No generator logic change is required**, and the INDEX table schema stays
   at its 6 columns (Document / Objective / Summary / Tags / See-instead / Audience) -- adding a
   column would exceed C-1's "one source value" addition. The only edit is a header-comment note
   that `forward-authored` is a pass-through source value.

4. **`canonical/aid/scripts/kb/kb-freshness-check.sh`** -- the one **behavioral** edit. Today
   `should_check()` returns "check" for any `primary|extension` doc whose source is not
   `generated`, so a forward-authored doc would be run through the source->doc drift algorithm. A
   forward-authored doc is design-authoritative (design->code), so source-drift staleness does not
   apply and a listed intent-source changing must NOT flip it to `suspect`. Edit: in `check_doc()`
   (before the absence gate), read `source`; when `source == forward-authored`, emit verdict
   `current` with `n_current=n_suspect=n_unknown=0` and a detail/reason string
   `"design-authoritative (forward-authored): source-drift N/A -- see feature-005 conformance
   check"`, then return. This folds to a non-stale verdict using the **existing** verdict enum
   `{current, suspect, unknown}` (no enum break, existing TSV consumers keep working) while
   documenting why the doc is intentionally not freshness-tracked. (Rationale: f007 is read-only
   and source->doc directional per D-4; the inverse code->design check is feature-005's new work.)

### Feature Flow -- the forward-authoring sequence

Human gates are marked **[HUMAN GATE]**. The engine (feature-002) drives steps 1-2; this feature
owns steps 3-6.

```
1. Triage detects greenfield                 (no code on disk + no aid-discover KB)
   -> route to the forward-authoring path     [feature-004 / engine]
        |
2. Elicit intent via the seasoned-analyst engine
   - single fixed opener (D1) then adaptive next-move selection (D2)
   - next-move driven by SEED-GAP: which of the 5 elements is still under-pinned
   - NFR-7 on every question                  [feature-002 engine]
        |
3. Author the seed docs            <-- feature-003
   - materialize elicited content into the 4 core docs (+ decisions.md if rationale-bearing)
   - stamp source: forward-authored + the full f001 frontmatter
   - apply the domain-adaptive shape (core + domain-selected extensions)
        |
4. Layered coherence check (FR-3 / AC-5)      <-- feature-003
   (a) interview-time concrete-example probe  (conversational, surfaces mismatches)
   (b) structural cross-check                 (every requirement term -> a seed concept)
   -> any conflict surfaced to the user as an NFR-7 question   [HUMAN GATE: resolve before proceeding]
        |
5. Greenfield-mode review gate (NFR-3 / AC-2) <-- feature-003
   - invoke aid-discover's review subsystem with greenfield: true
   - same dimension floors; as-built red flags relaxed; intent-evidence substituted
   -> grade >= work minimum (A+; TOTAL 0)     [loop back to step 3 on findings]
        |
6. Seed approved + REQUIREMENTS approved      [HUMAN GATE: D4 human approval]
   -> seed is now a forward-authored KB the downstream phases read unchanged (C-1)
```

The sufficiency bar (step 5's precondition) is enforced both by the engine's stopping rule (D2)
and re-checked structurally at step 4(b); the objective acceptance measure is a downstream
`aid-specify` run with zero KB-gap loopbacks (AC-2 / RQ-A5).

### Layers & Components -- files touched

| Layer | File (real on-disk path) | Change |
|-------|--------------------------|--------|
| Schema | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | Add `forward-authored` as a third row to the `source:` enum table (table-only; no prose note exists to update) |
| Lint | `canonical/aid/scripts/kb/lint-frontmatter.sh` | In-scope comment + (future) allow-list inclusion; no skip; no behavior change (already in-scope) |
| Index | `canonical/aid/scripts/kb/build-kb-index.sh` | Header-comment note only; source-agnostic, 6 columns unchanged |
| Freshness | `canonical/aid/scripts/kb/kb-freshness-check.sh` | `check_doc()` short-circuit for `source: forward-authored` -> verdict `current`, drift skipped |
| Review gate | `canonical/skills/aid-discover/references/document-expectations.md` | Add a **Greenfield mode** parameterization block (flag, suppressed red flags, retained floors) -- NOT a forked variant |
| Review wiring | `canonical/skills/aid-discover/references/reviewer-brief.md`, `state-review.md` | Thread a `greenfield: true|false` review parameter (default false) into the reviewer brief, alongside the existing doc-set parameterization (D-5). **MUST reconcile the existing `state-review.md:117-118` "Greenfield never reaches the panel" exclusion** -- see the reconciliation note below |
| Seed-authoring step | `canonical/skills/aid-interview/` (the `aid-describe` step per D3) | New additive state: author the seed docs, run the coherence check, invoke the gate in greenfield mode |
| Classification (reference, no edit) | `canonical/aid/templates/kb-authoring/concern-model.md` | None -- already classifies the 5 docs (4 primary + decisions.md extension) |

The seed-authoring step reuses the existing review subsystem (`state-review.md`,
`reviewer-brief.md`, `document-expectations.md`) per D-5 rather than introducing a parallel
reviewer; the only new review-side artifact is the greenfield-mode parameterization.

**Panel-exclusion reconciliation (REQUIRED -- closes the load-bearing NFR-3/AC-2 path).**
`state-review.md:117-118` today asserts "Greenfield never reaches the panel": in **aid-discover's
brownfield-discovery triage** (Step 0f), a project *classified* greenfield has nothing extracted to
deeply review, so its `panel:` branch collapses and it skips the review panel. That exclusion is
correct **for discovery** and stays. feature-003's forward-authored **seed review is a DISTINCT
path** -- it is NOT entered via aid-discover Step 0f triage; it is invoked from the `aid-describe`
seed-authoring step (flow step 5) with `greenfield: true`, and per NFR-3 the seed MUST traverse the
**full** panel (same dimension floors). So the edit MUST carve the two cases explicitly: keep the
"discovery-triage greenfield -> collapsed panel" branch, AND add that a **`greenfield: true`
seed-review invocation reaches the full panel in greenfield mode** (intent-evidence substituted,
as-built red flags relaxed, floors retained). Without this carve the seed-review path contradicts
the existing exclusion; with it, the two greenfield contexts (discovery-skip vs seed-review-full)
are disambiguated and NFR-3's "same gate" holds. The reviewer must confirm `state-review.md`'s
greenfield branch is updated to this two-case form, not left as the blanket "never reaches the
panel."

### Domain-adaptive shape (RQ-A4)

The seed = an **invariant core** + **domain-selected extensions**, surfaced through the same
propose->confirm gate `aid-discover` uses for its domain-driven doc-set.

**What flexes (proposed when the domain warrants):**
- Process / workflow-heavy domain -> event-flow / behavior content becomes load-bearing; lands in
  `architecture.md` or a domain-rendered `process-architecture.md`.
- Data / ML domain -> an intended schema (C5, `schemas.md`) is promoted from excluded to included.
- Integration-heavy domain -> an intended integration-map (C2) becomes relevant.
- Non-software domain -> `domain-doc-matrix.md` renders different doc *names* for the same
  dimensions (e.g. `authoring-conventions.md` for C3 on a methodology project).

**What stays INVARIANT (never flexes):**
- The concept-spine (C4 / `domain-glossary.md`) is ALWAYS present (concern-model invariant).
- The dimension spine (C0-C9 + D, exactly 11) is fixed (the T2 cardinality contract); adaptivity is
  in doc *realization*, never in the dimension list.
- "Name boundaries + relationships" stays the invariant shape for architecture.
- The mandatory core (elements 1-2) and the per-element fit criteria are unchanged across domains.

### Greenfield review gate (the flag, parameterizing the EXISTING expectations -- owner decision 1)

A single boolean review parameter `greenfield: true|false` (default `false`, preserving
brownfield behavior unchanged -- NFR-2) is threaded into the reviewer brief by the seed-authoring
step. `document-expectations.md` gains one **Greenfield mode** block (not a forked file) that the
`aid-reviewer` sub-agent honors when the flag is set:

**Evidence substitution (when `greenfield: true`):** wherever a depth standard or red flag demands
code/config evidence, substitute *intent-evidence* -- the user's confirmed elicited statements +
the gathered REQUIREMENTS:
- C3 "concrete example from this project's code or files" -> "concrete example **from intended use**".
- `architecture.md` "Ground every claim in a file or path" -> "ground every claim **in a confirmed
  requirement or elicited statement**".
- C4 "where it lives in the code" -> "where it lives **in the intended design / domain**".

**As-built red flags RELAXED (suppressed in greenfield mode):**
- C0 / `technology-stack.md`: "Version TBD" and "missing runnable build command" are **accepted** as
  "latest-at-init / TBD-until-scaffolded" + build "TBD" (owner decision 2).
- C1 / `architecture.md`: "Generic descriptions without file paths" / "the real layout, not a generic
  skeleton" are **relaxed** to sketch-altitude intended boundaries (and `project-structure.md` is
  excluded entirely -- see Exclusions).
- C3 / `coding-standards.md`: "A convention named but no example from code" is **accepted** when the
  doc declares "standard for `<stack>`, no project-specific deviations yet" (owner decision 4).

**Dimension floors KEPT (same bar, sourced from intent -- these still MUST pass):**
- C4 term-boundary invariants -- every load-bearing term defined as this project uses it + the
  distinctions a newcomer must never conflate (`## Invariants`).
- C1 architecture `## Invariants` -- the invariants a change must not break.
- The operational-structure floors / owned named sections per `concern-model.md`.
- The same dimensions are reviewed (no dimension is skipped); only the *evidence source* changes and
  the *as-built* red flags are suppressed.

### Coherence check (FR-3 / AC-5) -- layered, both layers run

Inputs: the just-authored seed docs (the 5 elements) + the gathered REQUIREMENTS.

**(a) Interview-time concrete-example probe (conversational).** The analyst tests the seed against a
real requirement example -- it takes a concrete requirement and walks it through the seed (its terms,
boundaries, stack), surfacing any mismatch in dialogue (Example Mapping, findings Family 8). A
requirement the seed cannot express, or that contradicts a declared term/boundary, is a flagged
mismatch.

**(b) Structural cross-check (deterministic).** Every load-bearing term used in the REQUIREMENTS
maps to a seed concept (a `domain-glossary.md` entry or a named architecture part); every seed
concept is reachable from a requirement. Outputs two orphan sets:
- **Requirement orphan** -- a REQUIREMENTS term with no seed concept (a seed gap; the seed is
  under-pinned).
- **Seed orphan** -- a seed concept no requirement references (possible scope drift or an unstated
  requirement).

**Conflict surfacing.** Any mismatch (a) or orphan (b) is surfaced to the user as an NFR-7 question
(suggested resolution + rationale) and MUST be resolved before the work proceeds [HUMAN GATE].
Resolution is recorded (engine scribe move); the check re-runs after the seed is amended.

### Sufficiency bar (RQ-A5)

The seed is minimal-but-sufficient when every **kept** element meets its fit criterion (Data Model
table, "Sufficient" column) AND the structural cross-check (b) yields zero requirement orphans. The
**objective acceptance measure** is downstream: a clean `aid-specify` run on the seed with **zero
KB-gap loopbacks** (AC-2). The stopping rule is sufficiency, not completeness (NFR-4) -- the
deliberate opposite of an unbounded "ask every branch" sweep. Deferrable to later phases: as-built
inventory (`module-map`, `test-landscape`, `infrastructure`), exact schemas (unless the domain
promotes them per RQ-A4), and feature-inventory (the pipeline owns scope).

### Exclusions (RQ-A2) -- as-built docs NOT in the seed

These document *what code does* and have no greenfield source; they are authored later by
`aid-discover` / `aid-update-kb` once code exists:

| Excluded doc | Concern | Why excluded |
|--------------|---------|--------------|
| `module-map.md` | C2 | No modules exist yet (parts & dependencies are as-built) |
| `test-landscape.md` | C6 | No tests exist yet |
| `schemas.md` | C5 | As-built data shapes; intended shapes are minimal/deferrable (domain-adaptive exception, RQ-A4) |
| `infrastructure.md` | C8 | Nothing ships or runs yet |
| `feature-inventory.md` | C9 | Scope/capabilities are governance, owned by the pipeline (`REQUIREMENTS.md` / `SPEC.md`), not the KB |
| `integration-map.md`, `pipeline-contracts.md` | C2 | As-built connections; intended integrations are thin/deferrable (domain-adaptive exception) |
| `project-structure.md` | C1 | As-built on-disk layout; nothing on disk yet |

The seed carries **intent**, not **inventory**. NFR-4 (minimal, not bloated) is the bar; excluding
these is what keeps the seed minimal-but-sufficient.

### Definition of Done / Verification

| DoD | Operationalization | Source AC |
|-----|--------------------|-----------|
| **D1 -- Marker shipped** | `source: forward-authored` is in the `frontmatter-schema.md` enum; `lint-frontmatter.sh` accepts a forward-authored seed doc (full lint, no skip); `build-kb-index.sh` indexes it in its `kb-category` table unchanged; `kb-freshness-check.sh` returns `current` (drift skipped) for it. Verified by a fixture seed doc through all three scripts. | C-1 |
| **D2 -- Seed model authored** | A code-less project yields the 4 core docs (+ `decisions.md` iff rationale-bearing), each meeting its fit criterion; excluded docs are absent; domain extensions appear only when the domain warrants. | FR-1, NFR-4, RQ-A2/A4 |
| **D3 -- Passes the greenfield-mode gate** | The seed passes the review subsystem with `greenfield: true` at **>= the work minimum grade (A+, TOTAL 0)** -- same dimension floors, as-built red flags relaxed, intent-evidence accepted. Brownfield review with `greenfield: false` is byte-unchanged (NFR-2). | AC-2, NFR-3 |
| **D4 -- Zero-loopback sufficiency** | A downstream `aid-specify` run on the approved seed completes with **zero KB-gap loopbacks**. | AC-2, RQ-A5 |
| **D5 -- Coherence check runs + surfaces conflicts** | Both layers execute; a deliberately-injected mismatch (a requirement term with no seed concept) is surfaced as an NFR-7 question and blocks progress until resolved. | AC-5, FR-3 |
| **D6 -- Brownfield intact** | `lint-frontmatter.sh`, `build-kb-index.sh`, `kb-freshness-check.sh`, and the brownfield review path still pass their existing tests (the marker and the flag are additive). | NFR-2, AC-10 |
