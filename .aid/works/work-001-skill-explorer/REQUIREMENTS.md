# Requirements

- **Name:** Skill Explorer
- **Description:** A generated section of the product site that pairs every AID skill's frontmatter with a flow chart derived from its own instructions, so a reader can understand what a skill does step-by-step without reading its source.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Initial interview started | /aid-describe |
| 2026-07-25 | D1 opener captured: objective, problem statement, initial scope and constraints | /aid-describe |
| 2026-07-25 | Delivery vehicle decided: new published `/skills/` section of the existing `site/` app | /aid-describe |
| 2026-07-25 | Derivation decided: charts derived for all skills, best-effort; no hand-authored charts | /aid-describe |
| 2026-07-25 | Index shape decided: all 111 cards, grouped by skill group; family-collapse rejected | /aid-describe |
| 2026-07-25 | Node content decided: short derived label in-node, verbatim fragment in a click panel + source deep link | /aid-describe |
| 2026-07-25 | Acceptance criteria AC-1..AC-7 adopted as written; section complete | /aid-describe |
| 2026-07-25 | Priority set High ("must be done now"), overriding the Medium straw-man | /aid-describe |
| 2026-07-25 | Index taxonomy decided: two-level — curated four, `Definition` subdivided by verb family | /aid-describe |
| 2026-07-25 | Audience decided: maintainer-first, one shared view; §7 constraints extended; all sections complete | /aid-describe |
| 2026-07-25 | Quality check found FR-5 unverifiable → AC-8 added | /aid-describe |
| 2026-07-25 | KB check corrected §8 structural taxonomy (4 shapes, not 3); AC-4 gained a kind-sibling fixture | /aid-describe |
| 2026-07-25 | FR-6 added (doorway pages render the shared engine flow) — interviewer default, owner skipped the question | /aid-describe |
| 2026-07-25 | KB hydrated from interview — `module-map.md` rev 1.5, Skill Structural Shapes (additive) | /aid-describe |
| 2026-07-25 | Identity set: Name "Skill Explorer" (owner-chosen), Description as composed | /aid-describe |
| 2026-07-25 | Interview complete — approved | /aid-describe |
| 2026-07-25 | Decomposed into 6 features | /aid-define |
| 2026-07-25 | Cross-reference (grade C vs A+ min): §8 corrected — `astro-mermaid` is in active use, not unused | /aid-define |
| 2026-07-25 | Cross-reference: §8 stops asserting a doorway count; exact figure is now a classifier output | /aid-define |
| 2026-07-25 | Cross-reference: FR-3's three layers re-traced across features 003/005/006 | /aid-define |
| 2026-07-25 | Q1 answered by owner — `aid-triage` is Support; full path is 5 skills; deploy/monitor are shortcuts. FR-5 + AC-8 rewritten | /aid-define |
| 2026-07-25 | Q2 answered by owner — FR-6 confirmed as written; no longer an interviewer default | /aid-define |
| 2026-07-25 | Cross-reference re-graded A+ (all 5 findings Fixed, 2 routed OOS) | /aid-define |
| 2026-07-30 | **§7 SECOND AMENDMENT (owner decision, work-level Q4).** Lifted the `gen-reference.mjs` freeze and the "four generated reference pages keep working unchanged" constraint; added **delivery-006** (tasks 054–057) to hollow out `reference/skills.md`, repointing readers at `/skills/`. Superseded §4's "the two coexist rather than one replacing the other" (:109-116) and FR-5's "the existing generator and its output are not modified by this work" (:184-203) — both struck in place with the amendment cited. Unlike the first amendment this is a deliberate scope addition, not a correction. | owner / /aid-execute |
| 2026-07-30 | Change Log gap closed at the work-level final gate: the amendment above had been narrated inline at §7 but never logged here, so this table understated the document's revision history by its largest post-approval change. | /aid-execute |

## 1. Objective

An internal, browsable catalog of every AID skill that lets a reader understand what a
skill does **step-by-step** without reading its `SKILL.md` source.

- An index page presents one card per skill, carrying enough to pick one (name, one-line
  intent, group/family).
- Opening a card shows that skill's detail page.
- The detail page **header** shows the skill's frontmatter (`name`, `description`,
  `allowed-tools`, `argument-hint`, and whatever else the file carries).
- The detail page **body** shows a **flowchart of the skill's instructions** — the steps in
  order, plus its loops, decision branches, and exit points. Each box holds the fragment of
  the prompt that composes that step, so the chart is a faithful rendering of the skill's
  control flow rather than a hand-written summary.

**Outcome sought:** a reader can look at the chart and say "I understand what this skill
does and in what order" without opening the markdown.

## 2. Problem Statement

Understanding what an AID skill actually does today requires reading its `SKILL.md` — and,
for the fat pipeline skills, the per-state `references/*.md` files it dispatches to. A
skill's control flow (ordered steps, loops, decision branches, exit points) is expressed in
prose, tables, and ASCII state maps spread across multiple files, so comprehension is slow
and easy to get wrong.

The existing generated `site/src/content/docs/reference/skills.md` lists skills with their
frontmatter descriptions, but shows no skill's internal flow at all — and it deliberately
collapsed the direct-entry shortcuts into family summary tables rather than describing
them individually. *(Past tense as of delivery-006: that family table is deleted — see
§ Constraints, §7's second amendment. The page keeps only the shortcut-engine narrative.)*
individually.

## 3. Users & Stakeholders

Published with the rest of the product documentation, so there are three reader groups. The
design is centred on the first; there is **one shared view**, not per-audience renderings.

1. **AID maintainers (primary).** Need a skill's real control flow in order to change it
   safely — the fat pipeline skills are the ones nobody can hold in their head.
2. **Contributors and newcomers to the repo.** Onboarding.
3. **Adopters and evaluators reading the public docs.** Want to know what a skill will do
   before running it.

A single faithful flow chart answers both "what will this do to my repo" and "how do I change
it", so no editorial second view is introduced. If adopters later need something gentler, that
is an **additive page**, not a reason to fork the derivation.

**Accepted risk:** charts pitched at maintainers may read as intimidating internals to an
evaluator arriving from the public site.

**Approver / owner:** the repo owner, who set the priority and every design decision recorded
in this document.

## 4. Scope

### In Scope

- A card index over the skill set.
- A per-skill detail page: frontmatter header + flowchart body.
- A flowchart representation covering ordered steps, loops, decisions, and exit points,
  with the composing prompt fragment shown inside each node.
- **Delivery vehicle:** a new top-level `/skills/` section of the existing `site/` Astro
  Starlight app, published alongside the rest of the docs — not a separate internal app.
- **Coverage:** every skill in `canonical/skills/` (111 directories at time of writing), with
  no skill left chart-less.

Accepted with the straw-man's conventions *(assumed from acceptance of the recommended
option; confirm at read-back)*:

- Generated by a **sibling of `gen-reference.mjs`** following the same conventions: reads
  `canonical/`, emits pages carrying "generated — do not edit", records a manifest, throws
  on drift, and runs from `prebuild`/`predev`.
- ~~The existing `reference/skills.md` is **retained as the terse family summary**; the new
  `/skills/` section is the deep dive. The two coexist rather than one replacing the other.~~
  **Superseded 2026-07-30 by work-level Q4 / §7's second amendment, executed as delivery-006.**
  The two did NOT coexist as equals: they duplicated the same roster under the same four
  groups, one derived and one hand-maintained. Q4 resolved that by repointing readers at
  `/skills/` and **hollowing out** `reference/skills.md` — it keeps the shortcut-engine
  narrative, which lives nowhere else, and sheds the roster. So `/skills/` **does** replace
  it as the roster; what survives on the old page is the mechanism, not a summary.

### Out of Scope

- A second, separate app for this purpose (explicitly rejected — it would duplicate the
  generator, the content collection, and the Mermaid rendering already present in `site/`,
  and add a second parser over `canonical/skills/`).
- Hand-authoring flowcharts, per skill or otherwise (explicitly rejected — see FR-2).

## 5. Functional Requirements

- **FR-1 — Derived, not authored.** Each skill's flowchart is **derived from that skill's own
  files at build time**. No chart is hand-written and stored for the site to render.
- **FR-2 — Best-effort coverage of the whole corpus.** Derivation runs against **every** skill,
  including those with no machine-readable flow structure today. Where the source is
  unstructured, a **rough or approximate chart is acceptable** — the explicitly chosen
  trade-off is imperfect coverage of all skills over precise coverage of a structured subset.
  There is no "no flow derivable" fallback state and no normalization of the skill files as a
  precondition.
- **FR-3 — Node content, two layers.** The node itself carries a **short derived label** — an
  imperative phrase of roughly 60 characters. Selecting a node opens a panel showing the
  **verbatim prompt fragment** for that step plus a **deep link to the exact lines in
  `canonical/`**. The chart carries shape; the panel carries exact wording; the source link is
  the final authority.
- **FR-4 — Control-flow fidelity.** The chart represents ordered steps, loops, decision
  branches, and exit points.
- **FR-5 — Index shape.** The index lists **a card for every skill** (all 111), **grouped
  under the four skill groups** so the repetition among the thin doorways is visually
  contained rather than removed. Every card links to that skill's own detail page.

  Resolved conflict (recorded, decided by the owner): grouping-with-full-listing was chosen
  over collapsing the ~90 doorways into family cards, and therefore **knowingly diverges**
  from the existing `gen-reference.mjs` decision to summarize shortcuts by family because
  individually they would be "near-identical blocks of pure noise". The two surfaces may
  legitimately differ: ~~`reference/skills.md` stays a terse summary~~ *(superseded — delivery-006 hollowed it out; it now carries only the shortcut-engine narrative. See § Constraints, §7 second amendment)*, `/skills/` lists
  everything.

  **Grouping taxonomy — two levels.** The top level is the curated four (`Support`,
  `Knowledge Base Maintenance`, `Definition`, `Execution`), matching how the docs already
  describe AID. Within `Definition`, cards are subdivided by **verb family** (create, change,
  fix, refactor, test, document, remove, deprecate, migrate, review, research, prototype,
  design, report, dashboard) — the same split `gen-reference.mjs` already derives from the
  catalog's `verb` field for ~~its family table~~ *(that table was deleted by delivery-006 —
  the split is still derived from `verb`, now only by `gen-skills.mjs`)*, so it cannot drift
  from the catalog. This is a
  nesting-depth decision only: no card is removed, and the all-111 coverage of FR-5 is intact.
  The catalog's `group:` field (`G3`–`G11`) is **not** used as the index taxonomy.

  **Placement rules (owner-corrected at cross-reference, Q1).** The `Definition` group is not
  the eight-skill set `gen-reference.mjs` ~~currently lists~~ *listed at the time this was
  written* (it lists no skills at all since delivery-006 hollowed its page out; the curated
  roster it read from now lives at `site/scripts/skills/curated-roster.mjs`):
  - **`aid-triage` is a Support skill**, not a Definition skill. It sits under `Support`.
  - **`Definition` opens with the five full-path skills**, in pipeline order and
    **un-subdivided**: `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`.
    These have **no shortcut-catalog row at all**, so no verb family can be derived for them and
    none is invented.
  - **`aid-deploy` and `aid-monitor` are ordinary shortcut skills now** — no longer part of the
    main full path. They are placed with the other shortcuts, under their own `deploy` and
    `monitor` verb families (each a family of one). They are **not** listed among the full-path
    skills.
  - The verb-family subsections follow the five full-path skills.

  ⚠️ **This knowingly diverges from the curated roster's `SKILL_GROUPS`**, which puts
  `aid-triage` in `Definition` (see its own comment, "include `aid-triage` in the Definition
  group") and lists `aid-deploy`/`aid-monitor` as curated `Definition` members. That grouping is
  **stale**; `/skills/` uses the corrected taxonomy above.

  ~~Per §7 the existing generator and its output are **not** modified by this work, so
  `reference/skills.md` will visibly group these three skills differently from `/skills/` until
  it is separately corrected — an accepted, recorded inconsistency, logged as an observation for
  the existing page rather than fixed here.~~
  **Superseded 2026-07-30 by work-level Q4 / §7's second amendment, executed as delivery-006**
  (same amendment that superseded §4:107-114). Two clauses of the struck text are now false and
  one locator in the paragraph above it had moved:
  - The generator **was** modified: `gen-reference.mjs` no longer emits a roster or a family
    table, and `SKILL_GROUPS` was extracted out of it into
    `site/scripts/skills/curated-roster.mjs` by task-054. References to "`gen-reference.mjs`'s
    `SKILL_GROUPS`" — including the one in the paragraph above, corrected in the same pass —
    should read the curated roster module.
  - `reference/skills.md` no longer groups these three skills at all, so it is not where the
    divergence is visible. **The divergence itself survives**, because the competing grouping was
    never the reference *page* — it is the curated roster, which still exists, still files
    `aid-triage` under `Definition`, and is still what the methodology's published skill
    inventory shows. `/skills/` therefore **discloses** the divergence in a derived note and
    declares itself authoritative, rather than leaving it unrecorded
    (`site/scripts/skills/render-index.mjs § findGroupingDivergence`). Closing it for real means
    correcting the roster, which is **KI-010**, carried forward open.

- **FR-6 — Doorway pages render the shared engine flow.** A skill whose body only delegates
  (shapes 3 and 4 in §8, ~94 of 111) renders the **full shared shortcut-engine chart inline**
  on its own detail page — `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT` —
  with that doorway's `{verb, artifact}` binding shown at the entry node, and kind-siblings
  additionally showing the parent-skill hop. Derived once from `shortcut-engine.md`, emitted
  per page.

  Rationale: it preserves §1's promise that a skill's own page explains that skill
  step-by-step, with no click-through required. Accepted cost: ~94 pages share a chart shape,
  which is truthful — they differ only in binding.

  ✅ **Owner-confirmed at cross-reference (Q2, 2026-07-25).** Originally adopted as an
  interviewer default when the question was skipped during the interview, and explicitly
  confirmed by the owner once cross-reference showed the alternatives were not equal in cost.
  Rejected alternatives: a stub page linking to one shared Engine page (DRY, but breaks the
  standalone promise **and** forces re-scoping of features 005 and 006, since a stub page has
  no chart nodes for AC-5 to attach to or feature-006 to interact with); no detail page for
  doorways at all (reverses part of the all-111 decision); and staying literal with a single
  "delegates to engine" box (truthful but useless on the large majority of the corpus).
  Consequently features 005 and 006 keep their "every node in every chart" scope unchanged.

## 6. Non-Functional Requirements

- **NFR-1 — Comprehensibility over completeness in the chart.** The chart must be scannable at
  a glance; node labels are short (~60 chars) rather than verbatim. Legibility of the diagram
  outranks textual completeness *within the diagram* — completeness is served by the panel.
- **NFR-2 — Nothing lost.** Every derived label is backed by the verbatim fragment in the
  panel and by a deep link to the exact `canonical/` lines, so no reader is ever stuck with
  only the interpretation.
- **NFR-3 — Interpretation risk is acknowledged.** A derived label is an interpretation and can
  therefore be wrong in a way verbatim text cannot. The source deep link is the accepted
  corrective; the alternative (verbatim-in-node) was rejected for NFR-1.
- **NFR-4 — Deterministic, build-time generation.** Generation runs from `prebuild`/`predev`
  like the existing generators and is idempotent — running it twice produces byte-identical
  output.

Known implementation cost accepted with FR-3: node selection requires **custom JavaScript**
on top of `astro-mermaid`, which renders diagrams but provides no node interaction.

## 7. Constraints

- `canonical/` is the source of truth; `profiles/*` are renders of it. The catalog must read
  `canonical/`, never a profile copy.
- No permanent artifact may depend on the contents of a `.aid/works/work-NNN-*/` folder —
  those are transient.
- Existing generated reference pages carry "generated — do not edit" markers plus a
  manifest; anything new should follow that same pattern.
- The existing `site/` build and its four generated reference pages must keep working unchanged.
  In particular, `gen-reference.mjs`'s throw-on-drift guard over the `canonical/skills/` set must
  continue to pass — adding a second generator must not fight it. ~~**`gen-reference.mjs` itself is
  frozen by this work.**~~ — **superseded by the second amendment below.**
- **Amended 2026-07-30 (owner decision, work-level Q4 — the SECOND amendment).** The freeze on
  `gen-reference.mjs` is **lifted**, deliberately and as a scope addition rather than a
  correction. Q4 resolved to unify the site's two skill sections: readers are repointed at the
  derived `/skills/` section and `reference/skills.md` is **hollowed out** — it sheds the
  duplicated roster and keeps the shortcut-engine narrative, which lives nowhere else. That is not
  possible without editing the frozen file, so the freeze had to go. Executed as **delivery-006**
  (tasks 054–057). The bound that replaces the freeze: the other three generated pages
  (`agents.md`, `kb.md`, `settings.md`) stay byte-unchanged, all 111 skill detail pages and their
  sidecars stay byte-unchanged, and the generator stays idempotent — see
  `deliveries/delivery-006/BLUEPRINT.md § Gate Criteria`.
  **Consumers of the un-amended text:** `known-issues.md` **KI-010** and
  `features/feature-002-grouped-skill-index/SPEC.md` both still reason from "the older generator is
  frozen". Their conclusions are re-derived against this amendment rather than left standing on a
  premise that no longer holds.
- **Amended 2026-07-25 (owner decision at Specify review).** The original wording — "its vitest
  suites must keep passing unchanged" — was **unsatisfiable**: two assertions in
  `site/scripts/__tests__/gen-reference.test.mjs` hard-code a 94-directory corpus and a
  76-shortcut total against a real 111 and 64, so they **already fail** before this work touches
  anything (KI-005). Worse, `.github/workflows/docs.yml` runs only `npm ci` and `npm run build`,
  so **no CI workflow runs the site's vitest suite at all** (KI-006) — which would leave AC-2,
  AC-4 and AC-6, all specified as vitest tests, unenforced on every pull request.
  The owner therefore brought both into scope:
  1. **Correct the two stale assertions** (test-file only; `gen-reference.mjs` stays frozen).
  2. **Add an `npm test` step to `docs.yml`** so the site suite actually runs in CI.
  Both land in **feature-001**, which owns build integration. The constraint now reads: the site
  vitest suite must be **green and running in CI** by the end of this work.
- Node >= 22.12 (the site's declared engine); no new runtime beyond what `site/` already
  depends on, except where FR-3's node interaction requires it.

## 8. Assumptions & Dependencies

Existing-state facts this work must reconcile with (captured from the opener, not yet
confirmed as decisions):

- `site/` is an Astro 6 + Starlight 0.39 docs site (`aid-product-site`, Node >= 22.12,
  vitest), and `astro-mermaid` 2.0.2 is **already configured and in active use** — imported in
  `site/astro.config.mjs` with a custom dark-theme palette, deliberately ordered before
  `starlight()` so it transforms fenced mermaid blocks first, and currently rendering 11 blocks
  across four pages (`concepts/methodology.md` 7, `guides/maintainer.mdx` 2,
  `guides/pipeline.mdx` 1, `index.mdx` 1). *(Corrected at cross-reference: this was recorded as
  "apparently unused", which was false.)* The rendering choice for `/skills/` is therefore
  between **following the site's established runtime `astro-mermaid` path** and **D-012's
  build-time pre-rendered inline SVG** — not between adopting a dormant dependency and
  something else.
- `site/scripts/gen-reference.mjs` already generates four reference pages from `canonical/`
  plus `canonical/aid/templates/shortcut-catalog.yml`, has its own frontmatter and catalog
  parsers, throws on skill-set drift, runs from `prebuild`/`predev`, and records its output
  in `scripts/.reference-manifest.json`.
- `dashboard/` is a separate local app (Python reader + Node server + static HTML) — the
  other precedent in this repo for an "internal" tool.
- The skill corpus is structurally heterogeneous, in **four** shapes — corrected at the
  COMPLETION KB check, which found the earlier "15 / 9 / ~90" estimate wrong. The KB's own
  ownership taxonomy (`module-map.md`, `project-structure.md`) is 111 = **17** curated pipeline
  / on-demand / router skills + the 94-row catalog's **64** generated verb-first doorways +
  **30** hand-authored `repurpose` skills. Verified structural shapes:
  1. **Fat pipeline skill** — `## Dispatch` table in `SKILL.md` mapping states to
     `references/state-*.md` workers and `Advance` targets; no inline `## State:` sections
     (`aid-describe`, 308 lines, 0 inline states).
  2. **Hand-authored collapse skill** — six inline `## State:` sections in `SKILL.md` itself,
     self-contained, no delegation (`aid-review` 221, `aid-research` 181, `aid-prototype` 129,
     `aid-test` 131, `aid-design` 120 lines — all exactly 6 inline states).
  3. **Generated shortcut doorway** — ~18 lines binding `{verb, artifact}` and delegating to
     `canonical/aid/templates/shortcut-engine.md` (`aid-create-api`, `aid-fix`).
  4. **Kind-sibling doorway** — ~24 lines delegating to a **sibling skill**, not to the engine
     (`aid-test-security` → `aid-test`). Per the catalog's own comments, the `test-*` and
     `create-diagram`/`create-document` clusters work this way.
- **`repurpose: true` in the catalog is a generator-ownership flag, not a structural signal.**
  `aid-review` (shape 2, fat) and `aid-test-security` (shape 4, thin) are both `repurpose: true`.
  Derivation must therefore classify by inspecting the file, never by reading the catalog flag.
- **Shapes 3 and 4 carry no flow of their own** — their real control flow lives in the shared
  shortcut engine (`INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT`). Resolved
  in FR-6.

  **How many skills that is, is not yet exactly known and must not be asserted.** The catalog
  has 64 non-`repurpose` emitting rows (all shape 3) plus 30 `repurpose: true` rows that mix
  shapes 2 and 4 — at least five of those 30 are confirmed shape 2 (`aid-review` 221 lines,
  `aid-research` 181, `aid-test` 131, `aid-prototype` 129, `aid-design` 120). The delegating
  population is therefore in the low-to-mid 80s, not 94. **Measured at Specify (2026-07-25):
  83–84 delegating** — 64 engine doorways plus 19–20 kind-siblings, the split moving with the
  classifier's discriminators — and **8** inline-state skills rather than 5, since
  `aid-change-document`, `aid-create-document` and `aid-report` also carry six `## State:`
  sections. *(Corrected at cross-reference: the earlier "roughly 94" was inherited from
  `module-map.md` without independent verification; refined again at Specify by direct scan.)*
  The exact figure is an **output of feature-003's shape classifier**, which inspects each body;
  no requirement or SPEC should hard-code a count.
- The KB records a directly relevant precedent: decision **D-012** removed the Mermaid runtime
  engine from `kb.html` in favour of **inline SVG pre-rendered at build time** (faster load, no
  external dependency, offline-safe), guarded by a visual-fidelity gate. Whether `/skills/`
  renders via `astro-mermaid` at runtime or follows D-012 and pre-renders is left to
  `/aid-specify`; it is noted here because it interacts with FR-3's node interaction.
  `authoring-conventions.md`'s "no diagrams in KB `.md` docs" rule governs the Knowledge Base,
  **not** the published site, so it does not block this work.
- There is **no single reliable parse marker** for a skill's state machine: skills variously use
  frontmatter `State machine:`, a `## Dispatch` table, inline `## State:` sections, a literal
  `## State Machine` heading, or ASCII state maps.
- ⚠️ **`aid-triage` is a Dispatch-shape skill, not the residual case** *(corrected at Specify by
  direct measurement; it had been cited here as the skill "matching neither shape")*. It carries
  a `## State Machine` heading at line 58 **and** a `## Dispatch` table with `State`/`Advance`
  columns at line 73, plus two inline `## State:` sections. Under any body-inspection classifier
  it lands in shape 1. The genuine residual population is a handful of curated on-demand skills
  (`aid-config`, the ticket skills, the connector skills) whose exact membership depends on the
  classifier's discriminators — which is precisely why no count or membership list is fixed here.
- In the ~15 Dispatch-table skills, chart **nodes and edges** are mechanically extractable
  from the table's `State` and `Advance` columns, but **branch conditions are prose** inside
  parentheses (e.g. `→ DESCRIBE-SEED (greenfield: no brownfield KB on disk and seed not yet
  complete) / → COMPLETION (brownfield or seed already complete)`), so edge labelling is a
  best-effort extraction rather than a parse.

## 9. Acceptance Criteria

- **AC-1 — Coverage.** Every directory under `canonical/skills/` has a generated detail page.
  The generator **throws** when the generated page set diverges from the on-disk skill set
  (same guard shape `gen-reference.mjs` already applies).
- **AC-2 — Header completeness.** Each detail page renders every frontmatter key present in
  that skill's `SKILL.md`; no key is silently dropped.
- **AC-3 — Chart well-formedness.** Every chart has at least one entry node and at least one
  exit node, and every edge target resolves to a node in the same chart (no dangling edges).
- **AC-4 — Feature coverage per structural class.** For a fixture set naming one skill from
  each of the **four** verified structural shapes — `aid-describe` (Dispatch table),
  `aid-review` (inline `## State:`), `aid-create-api` (generated doorway → engine),
  `aid-test-security` (kind-sibling → sibling skill) — the generated chart contains the loop,
  branch, and exit the source expresses. Tested with **vitest**, already the site's test
  runner. *(Fourth fixture added at the COMPLETION KB check, which found the kind-sibling
  shape had been missed.)*
- **AC-5 — Verbatim reachability.** Every node exposes its verbatim prompt fragment and a
  source deep link that resolves to real lines in `canonical/`.
- **AC-6 — Idempotence.** Two consecutive generator runs produce byte-identical output.
- **AC-7 — Comprehension spot-check.** A reader unfamiliar with a given skill can state its
  step order and exit points correctly from the chart alone. **Non-blocking** — a judgement
  check, not a CI gate — but recorded because it is the only criterion that tests the stated
  outcome directly.

- **AC-8 — Index shape.** The index renders one card per skill for every skill in
  `canonical/skills/`, nested under the four curated groups, with the cards inside
  `Definition` subdivided by the verb family derived from the shortcut catalog. A skill whose
  card is missing fails the check. *(Added at the COMPLETION quality check, which found FR-5
  unverifiable.)*

  **Catalog agreement is scoped to catalog-keyed cards** *(refined at cross-reference, Q1 —
  the original wording had no verdict for a skill absent from the catalog)*: a card **with** a
  shortcut-catalog row fails if its verb family disagrees with that row. The **five full-path
  skills** (`aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`) have no
  catalog row and are exempt from the family check; instead the check asserts they appear in
  `Definition`, in pipeline order, in the un-subdivided opening block, and carry no family.
  `aid-triage` must appear under `Support`. `aid-deploy` and `aid-monitor` must appear under
  their own `deploy` and `monitor` verb families, **not** in the full-path block.

AC-1, AC-3, AC-5, and AC-6 are the criteria that keep FR-2's "best-effort" from degrading
silently: they verify something coherent was produced for every skill without asserting that
the derived interpretation is correct.

## 10. Priority

**High — must be done now.** Owner-set at the interview (overriding the interviewer's
straw-man of Medium): this work takes precedence and should be picked up next rather than
queued behind other in-flight work.

Internal Must/Should split *(straw-manned, NOT yet confirmed — the owner answered the
priority question but not this split; confirm at read-back)*:

- **Must** — FR-1 (derived), FR-2 (whole-corpus coverage), FR-4 (control-flow fidelity),
  FR-5 (grouped index), AC-1/2/3/5/6.
- **Should** — FR-3's click-to-open panel. A chart plus a below-chart ordered list of verbatim
  fragments already satisfies AC-5; the custom-JS node interaction is polish on top of that.
- **Could** — formalizing AC-7 into a repeatable review step; navigation polish.
- **Won't** — normalizing the 111 skill files onto a machine-readable convention (rejected at
  the derivation decision and staying out).

Given the High priority, the Should/Could items may warrant promotion — worth revisiting when
the requirements are read back for approval.
