# KB Document Model

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-8, FR-9, FR-11, FR-29) | /aid-interview |

## Source

- REQUIREMENTS.md §5.C (FR-8, FR-9, FR-11), §5.H (FR-29)
- REQUIREMENTS.md §1.3 (the KB model: summary+pointer, concerns-driven, audience/ownership), §2.1/§2.3/§2.7 (P1, P3, P7)
- §4 S3, S9

## Description

This feature defines *what a KB document is* under the new model, and aligns the
visual rendering to match. Documents are derived from a small, universal, stable
set of **concerns** (how is it built? what are the parts? what conventions? what
vocabulary? how is it tested? what's risky? how does it ship? what does it do for
users?) rather than from an enumeration of project types. The concrete doc set is
**proposed → confirmed** with the user: a concern may split into several docs, or
a project-specific doc may be added.

Each doc follows the **summary + pointer** model: it synthesizes the durable,
cross-cutting understanding (the *why*, the *how parts interact*, the gotchas) and
points to its `sources:` for volatile detail — neither a fat transcription nor a
hollow link-farm. Document boundaries fall where coverage, fit, and
audience/ownership agree, so audience and ownership become first-class dimensions.
Per-doc research expectations are phrased as **open questions** ("describe how this
is structured and why") rather than fill-in templates that invite generic bending.
Finally, `aid-summarize` is updated to render this new model (concept spine,
summary+pointer, audience) in the visual summary.

## User Stories

- As a **senior architect**, I want each doc to synthesize the conceptual model and
  point me to source for detail so that I get the *why* without a stale transcription.
- As a **junior developer**, I want docs sized to a coherent concern with a clear
  audience so that I get orientation at my level and know where to go deeper.
- As an **AID adopter**, I want the doc set derived from my project's concerns and
  confirmed with me so that I get the right documents, not a fixed one-size seed.
- As a **researcher (AI agent)**, I want expectations phrased as open questions so
  that I report what is actually in the source instead of bending it to a template.

## Priority

Should

## Acceptance Criteria

- [ ] Given a project, when the doc set is determined, then it is derived from the
  universal concern set (not a project-type enumeration) and proposed → confirmed
  with the user, allowing concern splits and project-specific docs. *(FR-8)*
- [ ] Given a KB doc, when it is authored, then it follows the summary + pointer
  model — durable synthesis in the doc, volatile detail left in `sources:`. *(FR-9)*
- [ ] Given a doc with `owner:`/`audience:`, when boundaries are drawn, then the
  audience/ownership dimension informs the boundary and the INDEX audience filter.
  *(FR-10 consumed here; primary in f001)*
- [ ] Given per-doc research, when expectations are issued, then they are phrased
  as open questions, not fill-in templates. *(FR-11)*
- [ ] Given the new KB model, when `aid-summarize` runs, then the visual summary
  renders the concept spine, summary+pointer, and audience. *(FR-29)*

---

## Technical Specification

> Methodology/conventions feature. It establishes *what a KB document is* under the new
> model: a canonical **concern model** (a kb-authoring doc enumerating the universal
> concerns), a **concern->doc default mapping** that reframes the existing 15-doc seed
> without breaking it, **expectations rephrased as open questions**, the
> **audience/ownership** boundary dimension (built on f001's `owner:`/`audience:` fields),
> and the **`aid-summarize` alignment** (FR-29). "Components" here are kb-authoring
> templates, `aid-discover` reference snippets, `document-expectations.md`, and
> `aid-summarize`'s `state-generate.md` — not application code. Every claim is grounded
> against the files cited inline; genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (not absorbed here).** The **concept spine persisted as a KB doc** is
> **f004**'s deliverable (FR-31 — the upgraded ubiquitous-language/glossary doc) and
> **f005** reviews it; f003 only *references that it exists* and makes `aid-summarize`
> *surface* it. The **migration** of AID's own existing docs to the new model is **f011**
> (FR-30). The **frontmatter field schema** (`owner:`/`audience:`/`sources:`/`objective:`/
> `summary:`) is **f001**'s; f003 *consumes* those fields, it does not (re)define them. The
> **INDEX routing table** + audience column rendering is **f002**'s; f003 supplies the
> *audience-as-boundary-dimension* rationale that f001/f002 plumb.

### Overview

The current doc-set machinery (`aid-discover`'s `doc-set-resolve.md`) is already adaptive:
`discovery.doc_set` in `.aid/settings.yml` declares the per-project doc set, and when it is
absent a deterministic `synth_default_seed` enumerates the 15 `knowledge-base/*.md`
templates against a fixed ownership map (the **default seed**). This feature does **not**
replace that machinery. It **adds a concept layer above it**:

1. A new canonical doc, **`concern-model.md`** under `kb-authoring/`, enumerates the ~8
   universal **concerns** (the questions a newcomer must answer) — the stable thing the
   doc set is *derived from* (FR-8, REQUIREMENTS §1.3).
2. The existing 15-doc seed is **reframed as the concern->doc default mapping**: each seed
   doc is annotated with the concern it covers. `discovery.doc_set` + `synth_default_seed`
   keep working byte-for-byte as the **deterministic fallback** ("default concern
   coverage"). The concern layer **adds adaptivity** — propose project-specific docs, or
   split a large concern across docs — through the existing **propose->confirm** gate.
3. `document-expectations.md` is **transformed from fill-in templates into open questions**
   (FR-11), so a researcher reports what is in the source rather than bending it to a
   skeleton.
4. `owner:`/`audience:` (f001 fields) become a **first-class boundary dimension** (FR-10):
   a doc boundary falls where coverage, fit, and audience/ownership agree.
5. **`aid-summarize`** (FR-29) is pointed at `objective`/`summary`/`audience` (with the
   same `intent:` coexistence fallback f002 uses) and gains **one concept-spine section**;
   no full visual redesign; `assemble.sh` + the hand-authored `summary-src/` sections stay.

### Concern Model

**The canonical concern-list doc.** This feature authors a new normative doc:

- **File:** `canonical/aid/templates/kb-authoring/concern-model.md` (rendered to the 5 host
  trees + the repo `.claude/` working copy, like its siblings `principles.md` /
  `tier-model.md` / `frontmatter-schema.md`).
- **Why `kb-authoring/` and this filename.** The concerns are a **normative authoring
  rule** ("which durable questions a project's KB must answer"), the same class of artifact
  as `principles.md` (how to author) and `tier-model.md` (how to classify a fact). It is
  *not* a per-project KB doc (it does not live in `knowledge-base/`, which holds doc
  *templates*), and *not* an `aid-discover` reference (those are state-machine snippets, not
  cross-skill normative rules — `aid-config` scaffolding and `aid-summarize` also consume
  the model). Placing it beside `tier-model.md` and naming it `concern-model.md` mirrors the
  established "*-model.md" convention (tier-model = fact axis; concern-model = document
  axis) and is the natural home `aid-discover`'s doc-set proposal, `aid-config`'s scaffold,
  and the reviewer all reference. It is registered in the `kb-authoring/README.md` index
  table (a new row) and in the README "9 principles / 4 tiers" quick-reference area as the
  document-derivation model.

**The ~8 universal concerns.** `concern-model.md` enumerates the concerns verbatim from
REQUIREMENTS §1.3 (the newcomer's questions). Each concern has: an id, the question it
answers, its definition (what belongs / what does not), and its **default doc(s)** (the
seed mapping below). The concern set is a **T2 cardinality contract** — a fixed, stable list
(per `tier-model.md` T2) that downstream proposal logic depends on:

| # | Concern | The question a newcomer must answer | Default doc(s) (seed) |
|---|---------|-------------------------------------|-----------------------|
| C1 | **Build & shape** | How is it built? What is its overall structure/anatomy? | `project-structure.md`, `architecture.md` |
| C2 | **Parts & connections** | What are the parts and how do they connect? | `module-map.md`, `integration-map.md`, `pipeline-contracts.md` |
| C3 | **Conventions** | What conventions/standards does it follow? | `coding-standards.md` |
| C4 | **Vocabulary** | What is its native vocabulary / ubiquitous language? | `domain-glossary.md` (the **concept spine** doc, persisted by f004) |
| C5 | **Data & contracts** | What are its data shapes and structural contracts? | `schemas.md` |
| C6 | **Quality & testing** | How is it tested? How healthy is it? | `test-landscape.md` |
| C7 | **Risk & debt** | What is risky, owed, or worked-around? | `tech-debt.md` |
| C8 | **Shipping & operation** | How does it ship and run? | `infrastructure.md` |
| C9 | **What it does for users** | What does it do for its users / what are its capabilities? | `feature-inventory.md` |
| C0 | **Technology** | What is it built *with* (languages, frameworks, runtime)? | `technology-stack.md` |
| -- | *(orientation / source registry — cross-cutting, not a concern)* | -- | `external-sources.md`, `README.md`, `INDEX.md` (skill-self / meta) |

> This is the **~8 concerns** of §1.3 made concrete. §1.3's bracketed list has **eight**
> newcomer questions: "how built? / what parts & how connect? / what conventions? / what
> vocabulary? / how tested? / what's risky/owed? / how ships? / what for users?". They map to
> the rows above as: built->**C1**, parts&connect->**C2**, conventions->**C3**,
> vocabulary->**C4**, tested->**C6**, risky/owed->**C7**, ships->**C8**, for-users->**C9**.
> Two rows are **derived, not in §1.3's eight**: **C5 (data & contracts)** is split out of
> "parts" because the existing seed dedicates `schemas.md` to it, and **C0 (technology)** is
> split out of "built" because the seed dedicates `technology-stack.md` to it. The split is
> deliberate: the concern map MUST cover all 15 seed docs to stay a *total* reframe (no seed
> doc left unmapped), so where the seed already separates a doc, the concern map separates the
> concern. **Seed-coverage check (literal):** the table's "Default doc(s) (seed)" column maps
> exactly the **15** `synth_default_seed` docs — `project-structure.md`, `architecture.md`
> (C1); `module-map.md`, `integration-map.md`, `pipeline-contracts.md` (C2);
> `coding-standards.md` (C3); `domain-glossary.md` (C4); `schemas.md` (C5); `test-landscape.md`
> (C6); `tech-debt.md` (C7); `infrastructure.md` (C8); `feature-inventory.md` (C9);
> `technology-stack.md` (C0); and the orientation row's `external-sources.md` + `README.md`.
> That is 15 distinct seed docs (`INDEX.md` is generated meta, not a `knowledge-base/*.md`
> template, per `doc-set-resolve.md` §2.2) — none unmapped, none duplicated. `repo-presentation.md`
> is **NOT** a default seed (it is absent from the `synth_default_seed` MAP); it is a
> **conditional doc-set extension *example*** (`doc-set-resolve.md` line 20:
> `repo-presentation.md|aid-researcher-architecture|conditional`) that a project MAY add under
> C9 via the propose->confirm gate — it is named only as such in `concern-model.md`, never as a
> default. The orientation row (`external-sources.md`/`README.md`/`INDEX.md`) is cross-cutting
> meta, not a newcomer concern. The exact concern count (§1.3's 8 + C0/C5 = **10 numbered
> concerns**) is fixed in `concern-model.md` as the T2 contract; the table above is the
> committed mapping.

**How `aid-discover` maps concerns -> docs (and proposes splits / project-specific docs).**
The default mapping above is the **deterministic fallback**: with no `discovery.doc_set`
override, every concern's default doc(s) are produced — exactly today's `synth_default_seed`
output (so the reframe is byte-compatible; see *Doc-Set Derivation*). The **adaptivity** the
concern layer adds is a **propose->confirm** step the recon/triage phase (f006) drives,
expressed against the concern list:

- **Split a large concern.** When a concern is oversized for the project (e.g. a monorepo
  whose C2 "parts & connections" spans several subsystems), `aid-discover` proposes one doc
  *per subsystem* under that concern, e.g. `module-map-frontend.md` + `module-map-backend.md`
  — each declared in `discovery.doc_set` with its owner + a `conditional:<when>` hint, and
  each still *tagged to concern C2*. The user confirms.
- **Add a project-specific doc.** When the project has a concern-relevant area no seed doc
  covers (e.g. a `ml-pipeline.md` for a data project under C2/C5), `aid-discover` proposes a
  new `discovery.doc_set` row mapped to the nearest concern. The user confirms.
- **Drop / mark conditional.** A concern whose default doc does not apply (e.g.
  `infrastructure.md`/C8 for a library with no deployment) is proposed as `conditional` (the
  existing presence field) — the user confirms presence at the gate.

The **concern is the stable spine; the docs are derived per project** (REQUIREMENTS §1.3,
FR-8). The proposal logic never invents a doc that is not anchored to a concern, which keeps
"did we cover everything?" answerable: *every concern must be covered by >=1 confirmed doc*
(the C4-Vocabulary concern is always covered by the concept-spine doc f004 persists). This is
the determinism anchor — the concern list is fixed; only the doc realization varies, and
every variation is human-confirmed.

### Doc-Set Derivation

**The reframe is additive, not a rewrite.** `doc-set-resolve.md`'s machinery
(`discovery.doc_set` schema, `synth_default_seed`, `resolve_doc_set`, the 4 accessors) is
**unchanged in behavior**. What changes:

1. **The ownership map gains a concern column (documentation only).**
   `synth_default_seed`'s `MAP` array (the §2.2 single-source ownership map in
   `doc-set-resolve.md`) and its companion table get a **third annotation — the concern id**
   — for each of the 15 templates, matching the C1-C9/C0 mapping above. This is a
   *documentation/comment* addition: the emitted TSV stays `filename<TAB>owner<TAB>presence`
   (the concern is **not** a 4th machine field, to avoid touching `resolve_doc_set`'s
   comma/pipe parsing and the 4 accessors). The concern annotation lives as an inline
   comment on each `MAP` entry and in the prose ownership table, so a maintainer reads
   "which concern does this doc serve" at the source of truth. **The seed output is
   byte-identical** to today — this satisfies decision 2 (backward-compatible; do not break
   the existing mechanism) and NFR-3 (determinism: `synth_default_seed` is still a pure
   function of the templates on disk).

   *(If a future feature wants the concern to be a machine-routable field — e.g. to assert
   "every concern is covered" mechanically in CI — it must add a 4th pipe field to the
   `discovery.doc_set` grammar and extend `resolve_doc_set` + a 5th accessor. That is
   **[SPIKE-1, deferred]**: not needed for f003's propose->confirm flow, which is
   human-gated, and it would touch f001's/the resolver's parsing contract. v1 keeps the
   concern as an authored annotation, not a parsed field.)*

2. **The propose->confirm flow is documented against the concern model.**
   `aid-discover`'s doc-set proposal step (the recon/triage front-half, f006) is pointed at
   `concern-model.md`: it walks the concern list, and for each concern proposes the default
   doc(s), a split, a project-specific addition, or `conditional`. The proposal is written
   into `discovery.doc_set` (the existing schema — no new persistence) and confirmed by the
   user (C4 human-gated). **The fallback path is untouched:** a project that accepts the
   defaults (or never runs the propose step) gets `synth_default_seed`'s 15 docs exactly as
   today. This is the "default concern coverage" — adaptivity is opt-in via the gate, never
   forced.

3. **Expectations as open questions (FR-11).** `document-expectations.md` is **transformed
   from fill-in templates into open questions**. The transform rule:

   - **Before (fill-in template):** a "Must have:" enumeration of named slots the researcher
     fills, which §1.4/§1.5 identify as the **rigid-template trap** — it invites a generic
     doc that bends the source to the skeleton ("Layers/Components/Diagram" -> a layered-
     architecture boilerplate that is true but says nothing project-specific).
   - **After (open questions):** for each doc, **the question(s) the doc must answer**,
     phrased to elicit *what is actually there and why*, plus the **red-flags kept as a
     calibration aid** (the red-flags are diagnostic, not a fill-in skeleton, so they stay).
     The "Must have" slots become **prompts to investigate**, not boxes to tick.

   **Before/after example 1 — `architecture.md`:**
   - *Before:* "Must have: project type, folder structure (annotated), architectural
     patterns with evidence, module boundaries, data flow (entry->processing->persistence),
     DI registration, entry points."
   - *After:* "**Describe how this system is built and why it is shaped this way.** What
     kind of system is it, and what shape did its builders give it? Where are its boundaries
     and why do they fall there? How does work/data flow from entry to outcome, and what is
     non-obvious about that flow? What did the builders decide that a newcomer could not
     guess from the code alone? Ground every claim in a file/path. *(Investigate: project
     type, the load-bearing boundaries, the real data path, the entry points and DI wiring
     — but report what this project actually does, not a generic architecture checklist.)*"

   **Before/after example 2 — `domain-glossary.md`** (the C4 concept-spine doc, the
   'Relative bus' failure case):
   - *Before:* "Must have: business-specific terms, technical terms unique to this project,
     abbreviations, product names with explanations."
   - *After:* "**What is the project's own language — the terms you must understand to
     understand the system?** For each native/coined term: what does it mean *here*
     (not in general), where does it live, and why does the project need it? Reach for the
     term while explaining the system; if you cannot define it from general knowledge, it is
     a *mandatory* investigation, never noise. Keep going until you can explain the system
     using only defined native terms + general knowledge. *(The 'Relative bus' failure: a
     load-bearing coined concept treated as noise. This doc closes that gap; it is the
     concept spine f004 persists.)*"

   The transform is applied to **every entry** in `document-expectations.md` (all **19**
   `### <filename>` entries — the ~13 seed-doc entries plus the meta/extra entries
   `external-sources.md`, `INDEX.md`, `README.md`, `repo-presentation.md`,
   `{reviewer_output_file}`, `{project_context_file}`), not just these two. The mechanical pattern is uniform:
   *lead with the open question(s); retain the slot list as a parenthetical "investigate:"
   prompt; keep the red-flags.* This is a **prose rewrite of an `aid-discover` reference**,
   not a schema change — `document-expectations.md` is still keyed `### <filename>` and is
   still resolved by the existing doc-set machinery (per `doc-set-resolve.md` line 24: "expectations resolve from `references/document-expectations.md` keyed by `### <filename>`"). No
   parser change; the consumer (the reviewer / FIX mode) reads richer prose.

### Audience/Ownership

**`owner:`/`audience:` (from f001) become a boundary dimension.** f001 adds `owner:` (free
string, the accountable owner-role) and `audience:` (free list, who the doc is for) to the
frontmatter schema. f003 supplies the **normative rule for how they shape document
boundaries** (FR-10, REQUIREMENTS §1.3): this rule is authored into `concern-model.md` (the
"Document boundaries" section) and cross-referenced from `principles.md`.

- **The three-force boundary rule.** A document boundary should fall where **three forces
  agree** (§1.3): **coverage** (a coherent concern — the concern model above), **fit**
  (right-sized for this project — the split/add adaptivity above), and **audience &
  ownership** (a natural owner-role + an audience who can read *and* maintain it). When a
  single concern serves two distinct audiences who cannot share one doc (e.g. a C9
  capabilities view for a non-technical PM vs. an architect's C2 internals), that is a
  **signal to split** — and the split is proposed at the doc-set gate with distinct
  `audience:`/`owner:` per resulting doc.
- **Audience is a new axis, distinct from `tier-model.md`.** §1.3 notes AID's existing
  `tier-model.md` ranks by *agent load-bearingness* — a different axis from *human
  audience*. f003 records this explicitly in `concern-model.md`: the **concern** axis =
  *which question* the doc answers; the **audience** axis = *for whom* (and at what
  altitude); the **tier** axis (existing) = *how load-bearing a fact is to an agent*. The
  three are orthogonal. The audience axis is the one §1.3 flags as missing today; f001 adds
  the field, f002 renders the INDEX audience column, and f003 makes it a boundary driver.
- **Summary+pointer keeps audiences from forking the doc.** Per §1.3, the summary+pointer
  model dissolves the agent-vs-human "fork": *both* want small chunks; a PM stops at the
  `summary:`, an architect follows `sources:` into code/spec. `concern-model.md` states this
  as the rule that prevents duplicate audience docs — audience decides *which* chunks exist
  (the split rule above), **not** layered-depth-within-a-doc or duplicate per-audience docs.
- **Ownership feeds freshness, not the INDEX.** `owner:` is the freshness-accountability
  field (consumed by f007), not an INDEX column (f001/f002 confirm `owner:` is parsed but
  not rendered in the table). f003 only uses `owner:` as the *third boundary force* — a doc
  must have a natural owner-role who can maintain it; a concern that no one can own is a
  boundary smell raised at the gate.

### `aid-summarize` Alignment (FR-29)

The exact change is to `aid-summarize`'s `state-generate.md` (rendered to the 5 trees). It is
a **field-source repoint + one new section**, not a visual redesign. The hand-authored
`summary-src/sections/*.html` files and `assemble.sh` are **unchanged in mechanism**.

1. **Repoint section-description source `intent:` -> `objective`/`summary`** (with `intent:`
   coexistence fallback). `state-generate.md` Step 3 currently reads the frontmatter
   `intent:` field as "the authoritative source for the doc's section description," falling
   back to "first paragraph after H1." The change makes it read **`objective:` (the
   section's purpose noun-phrase) + `summary:` (one-sentence scope)** as the authoritative
   source, **falling back to `intent:`** when `objective:`/`summary:` are absent (the
   *exact same coexistence rule f002 uses* for the INDEX, and the same one f001 establishes:
   `objective`->`intent` fallback during the f011 migration window), and only then to "first
   paragraph after H1." This keeps an un-migrated KB rendering correctly (degrade-gracefully,
   NFR-7) while a migrated KB uses the precise new fields. **No `assemble.sh` change** — this
   is a change to *how the section author reads the KB*, the same authoring step that already
   reads `intent:`.

2. **Add one concept-spine section.** A new `summary-src/sections/NN-concept-spine.html`
   surfaces the **concept spine** (the C4 ubiquitous-language/glossary doc f004 persists):
   the project's native terms with one-line definitions, rendered as a scannable
   spine/glossary block. f003 **references** the spine (it is f004's KB doc); it does not
   build the spine. The section is authored from that doc's content (the same "drawn from KB"
   rule as every other section, Step 4) and `assemble.sh` concatenates it unchanged (it
   globs `sections/*.html` — confirmed `state-generate.md` Step 5; a new numbered file is
   picked up with no script change). **Delivered to all profiles.** The section structure is
   defined in `knowledge-summary/section-templates/{profile}.md`, and there are **7** such
   profile templates on disk (`agentic-pipeline.md`, `auto-detect.md`, `cli.md`,
   `data-pipeline.md`, `library.md`, `microservices.md`, `web-app.md`); `state-generate.md`
   Step 4 (line 72) selects the **one** profile that matches a given project, and authors that
   project's `summary-src/sections/` from it. So the concept-spine section MUST be added to
   **all 7** profile templates — otherwise a project on any of the 6 unedited profiles would
   not gain the section, under-delivering FR-29. The wording/diagram of the spine block MAY be
   tailored per profile (e.g. a `cli` glossary vs. a `data-pipeline` term map), but every
   profile gets a concept-spine section entry. **Scope guard:** this is **one section per
   profile**, not a redesign — the hero, nav, CSS, Mermaid pipeline, lightbox, and the other
   ~13 sections are untouched (decision 3: NO full visual redesign).

3. **Surface `audience:` (light touch).** Where a section renders a doc's metadata,
   `state-generate.md` may surface the doc's `audience:` as a small role badge (the same data
   f002 renders in the INDEX audience column). This is additive and optional — no layout
   change; if `audience:` is absent (un-migrated), nothing renders. *(This is the minimal
   "render the audience" satisfaction of FR-29; it rides on the existing per-section metadata
   line, not a new component.)*

**What does NOT change:** `assemble.sh`, `fetch-mermaid.sh`, the skeleton-head/foot
structure, the CSS/JS templates, the grade/validate/approval states, and the
parallel-safe per-section authoring model. FR-29 is satisfied by (1)+(2)+(3): the visual
summary renders summary+pointer (via `objective`/`summary`), the concept spine (new
section), and audience (badge) — exactly the three things §1.3/FR-29 name.

### Constraints

- **NFR-3 / C5 — determinism.** The concern->doc default mapping is a *fixed list*;
  `synth_default_seed`'s output stays byte-identical (the concern annotation is comment-only,
  not a parsed field), so the deterministic fallback is unchanged and CI-stable. The
  propose->confirm adaptivity is **human-gated** (C4), so it introduces no non-deterministic
  machine decision. `document-expectations.md` is consumed by the (judgment-bearing)
  reviewer, which is already the irreducible-judgment surface — the transform changes the
  *prompt*, not the determinism budget.
- **NFR-8 / C1 — no new runtime.** f003 adds **no script and no dependency**: it authors a
  markdown doc (`concern-model.md`), rewrites prose in two existing references
  (`doc-set-resolve.md` comments, `document-expectations.md`), and edits one `aid-summarize`
  reference (`state-generate.md`). No new binary, interpreter, or `python3`/`pwsh` escalation.
- **C3 / NFR-4 — render-drift green.** Every file f003 touches is canonical and renders to
  the 5 host trees: `concern-model.md` (new, under `kb-authoring/`), `principles.md` (under
  `kb-authoring/` — the boundary-rule cross-ref, deliverable #4), `doc-set-resolve.md` and
  `document-expectations.md` (under `aid-discover/references/`), `state-generate.md` (under
  `aid-summarize/references/`), the `kb-authoring/README.md` index row, and the concept-spine
  entry added to all 7 `knowledge-summary/section-templates/*.md` profile files. f003 MUST edit **canonical only**
  and re-run `python .claude/skills/generate-profile/scripts/run_generator.py`, committing the
  regenerated `profiles/`, or render-drift goes red (render-drift-full-generator precedent).
  **[SPIKE-2]** — adding a *new* canonical doc (`concern-model.md`) may require the renderer's
  emission manifest to learn the new file; verify the full generator picks up a net-new
  `kb-authoring/*.md` automatically (it enumerates the tree) and regen, never hand-place the
  rendered copies.
- **C2 — ASCII-only (N/A for shipped scripts here).** f003 touches **no `.sh`/`.ps1` shipped
  script** (it edits comments inside `doc-set-resolve.md`, which is a markdown *reference*
  embedding a bash snippet, not a vendored script; the snippet's *behavior* is unchanged and
  its comment additions MUST stay ASCII to match the file's existing ASCII body). The markdown
  docs themselves are not ASCII-gated, but f003 SHOULD keep them ASCII for consistency with
  the kb-authoring siblings. No `test-ascii-only.sh` allow-list change is needed (no new
  script).
- **C8 — skill conventions.** No skill router changes; f003 edits `references/` snippets and
  templates only, preserving the thin-router `SKILL.md` + `references/` state-machine pattern.

### f003 deliverables (acceptance criteria for the gate)

1. **Concern model doc.** `canonical/aid/templates/kb-authoring/concern-model.md` authored:
   the ~8 (C1-C9 + C0) universal concerns with id/question/definition/default-doc(s), the
   T2-contract concern count, the three-force boundary rule, the audience-axis distinction
   from tier-model, and the propose->confirm split/add rules. Registered in
   `kb-authoring/README.md`. *(FR-8, FR-10, FR-11 anchor)*
2. **Seed reframed as concern->doc mapping.** `doc-set-resolve.md`'s ownership map +
   `synth_default_seed` `MAP` gain the concern annotation (comment-only; emitted TSV
   byte-identical); the propose->confirm flow is documented against `concern-model.md`.
   Backward-compat verified: default seed output unchanged. *(FR-8, decision 2)*
3. **Expectations -> open questions.** `document-expectations.md` rewritten: every `###
   <filename>` entry leads with the open question(s), retains the slot list as an
   "investigate:" parenthetical, keeps the red-flags. *(FR-11)*
4. **Audience/ownership boundary rule** authored into `concern-model.md` + cross-ref in
   `principles.md`. *(FR-10)*
5. **`aid-summarize` alignment.** `state-generate.md` repoints to `objective`/`summary`
   (intent fallback), adds the concept-spine section to **all 7** `section-templates/*.md`
   profile files (`agentic-pipeline`, `auto-detect`, `cli`, `data-pipeline`, `library`,
   `microservices`, `web-app`), and an optional `audience:` badge; `assemble.sh` +
   hand-authored sections unchanged. *(FR-29)*
6. **Re-rendered profiles.** `run_generator.py` re-run; regenerated `profiles/` committed
   (render-drift green). *(C3, NFR-4)*

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-1 — deferred]** Concern as a *machine-routable* field. v1 keeps the concern as an
  authored annotation (comment + prose), not a parsed `discovery.doc_set` field, to avoid
  touching `resolve_doc_set`'s comma/pipe parsing + the 4 accessors. A future "every concern
  covered" CI assertion would need a 4th pipe field + a 5th accessor — deferred, not needed
  for the human-gated propose->confirm flow.
- **[SPIKE-2]** Net-new canonical doc render. Verify `run_generator.py` auto-discovers a new
  `kb-authoring/concern-model.md` (it enumerates the tree, so expected yes) and emits it to
  all 5 trees; if any emission manifest pins the `kb-authoring/` file list, update it in
  canonical and regen — never hand-place rendered copies (render-drift-full-generator
  precedent).
- **[SPIKE-3 — sequencing]** f003 consumes f001's `owner:`/`audience:`/`objective:`/`summary:`
  fields and references f004's persisted concept-spine doc. If the plan sequences f003 before
  f001/f004 land, the `aid-summarize` repoint must keep its `intent:` fallback active (it
  already does) and the concept-spine section degrades to "no spine doc yet" gracefully.
  Confirm the f001->f003 and f004->f003 ordering with PLAN.md (consume-after-define).
