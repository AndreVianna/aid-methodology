# Requirements

- **Name:** Knowledge Relationship Graph
- **Description:** Adds the `/aid-graph` skill, which runs after the Knowledge Base is approved to extract every relationship among KB concepts, project source, and external sources into a verifiable `relationships.md` table and render it as an interactive, self-contained graph view.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Initial interview started | /aid-describe |
| 2026-07-28 | Objective captured; three relationship sources and the `relationships.md` table schema recorded | /aid-describe |
| 2026-07-28 | Node identity confirmed: id + display name per endpoint; `kb:` / `int:` / `ext:<key>` prefixes | /aid-describe |
| 2026-07-28 | Relation vocabulary confirmed closed + research-defined + categorized (FR-4..FR-6) | /aid-describe |
| 2026-07-28 | Skill named /aid-graph; on-demand, KB-approval-gated, read-only, idempotent (FR-7..FR-11) | /aid-describe |
| 2026-07-28 | Confirmed separate skill sharing /aid-summarize scripts; merge alternative rejected (FR-12) | /aid-describe |
| 2026-07-28 | Problem Statement captured — all four purposes equally primary | /aid-describe |
| 2026-07-28 | Graph view: four preset lenses + always-available manual controls (FR-13..FR-15) | /aid-describe |
| 2026-07-28 | Self-containment confirmed (FR-16/FR-17); rendering approach deferred to RESEARCH (FR-18, Q2) | /aid-describe |
| 2026-07-28 | Unrepresented source concept reframed as a KB defect; source-driven enumeration (FR-19/FR-20) | /aid-describe |
| 2026-07-28 | Significance rule, exclusions, granularity, derivability confirmed (FR-21..FR-24) | /aid-describe |
| 2026-07-28 | Gap handling: report to reviewer ledger + route, never gate (FR-25..FR-28) | /aid-describe |
| 2026-07-28 | Accessibility: WCAG AA via first-class accessible table view (NFR-1..NFR-6) | /aid-describe |
| 2026-07-28 | Extraction: script-majority two-pass with bounded agent pass; reproducibility (FR-29..FR-32) | /aid-describe |
| 2026-07-28 | Derived §3 Users, §4 Scope, §7 Constraints, §8 Assumptions, §9 Acceptance Criteria | /aid-describe |
| 2026-07-28 | Priority set to Immediate; three-deliverable shape proposed for /aid-plan | /aid-describe |
| 2026-07-28 | Quality check: added AC-16..AC-18; sharpened C-7; raised Q3 (KB-index pickup of relationships.md) | /aid-describe |
| 2026-07-28 | Identity header confirmed (Name + Description) | /aid-describe |
| 2026-07-28 | Interview complete — approved | /aid-describe |
| 2026-07-28 | KB hydration assessed — no KB writes: all 19 docs already Generated with no Pending/Partial rows, and every fact captured here describes an unbuilt capability, so writing it now would document something that does not exist. KB update deferred to ship. | /aid-describe |
| 2026-07-28 | Decomposed into 11 features | /aid-define |
| 2026-07-28 | Cross-reference complete — Grade A+; FR-1..FR-3 draft labels removed; Q4 raised (external-sources.md has zero entries) | /aid-define |
| 2026-07-28 | **Owner decision — packaging restrictions dropped.** FR-16 rewritten to prioritise interaction quality over packaging; C-1 withdrawn; FR-18's option space unrestricted (multi-file, CDN, and build step all permitted); AC-6 rewritten; four consequences recorded at §5.6 | /aid-specify |
| 2026-07-28 | Q1 resolved — `Strength` column dropped; table is eight columns | /aid-specify |
| 2026-07-28 | Q3 resolved — `relationships.md` is a generated, KB-indexed document with valid frontmatter; C-7 and AC-18 hold | /aid-specify |
| 2026-07-28 | Q4 resolved — `ext:` branch of AC-1 validated against a synthetic fixture, not this project's empty external-sources.md; A-6 added | /aid-specify |
| 2026-07-28 | **Correction** — §5.6 consequence 1 named the wrong validator. `validate-visuals.mjs` T2 (sibling `<g>` overlap) is the real by-design collision for an SVG graph; `NM` is `mermaid`-keyed and passes unchanged; `S2` fails only if the packaging uses a CDN. Verified against the scripts | /aid-specify |
| 2026-07-28 | AC-15 scope clarified — the lens/ledger equality binds the `int:` class only; unbacked `kb:` nodes are a lens-only signal | /aid-specify |
| 2026-07-28 | Q5 raised — `graph.html` is unreachable through the dashboard (leaf allowlist + CSP); entry point scoped to a local file open | /aid-specify |
| 2026-07-28 | **Correction** — FR-30's `Evidence:` carrier does not exist in this KB (2 prose-label hits in one doc). Replaced with the verified carriers: `sources:` frontmatter, inline `CONFIRMED <path> (search: "…")` anchors (7–30 per doc), frontmatter cross-references, external-source keys | /aid-specify |
| 2026-07-28 | Q8 raised — the shared reviewer-ledger lifecycle deletes ledgers at DONE, which would destroy the gap findings FR-26 delivers; needs a retention carve-out at the methodology level | /aid-specify |
| 2026-07-28 | `generator` frontmatter conflict between feature-003 and feature-010 reconciled to the script name, per the `build-kb-index.sh` precedent | /aid-specify |
| 2026-07-28 | Q6/Q7 raised and D-4/D-5 added — FR-22's ignore-list setting does not exist (settings at `format_version: 3`); the external-sources file has no machine-readable entry format and `/aid-graph` may not author one under FR-10 | /aid-specify |

## 1. Objective

Add a new AID skill that — like `/aid-summarize` — runs **after the Knowledge Base is
complete** and generates two artifacts from it:

1. **`relationships.md`** — all relationships between the concepts and facts held in the
   Knowledge Base and in the project source.
2. **An HTML graph view** of those relationships, interactive: the reader can change
   groupings, adjust density, zoom, and similar view controls.

## 2. Problem Statement

The Knowledge Base is a lossy summary of the project source, informed by external sources. Today
that wiring is implicit: nothing records which source artifact generated which KB fact, or which
external source contributed it, in a form anyone can check. Four consequences follow, and all four
are in scope as purposes of this work — the owner rated them equally important:

1. **Drift and coverage detection.** A KB doc can go stale after the code it describes changes,
   and nothing surfaces it. Unbacked KB claims (a `kb:` node with no `int:` edge) and
   undocumented source (an `int:` node no KB doc points at) are both invisible today.

   **A source concept important enough to appear in the graph but absent from the KB is a gap in
   the KB — a defect, not merely a missing edge.** The graph is therefore a KB *quality* signal,
   not only a navigation aid: it reveals what the KB failed to capture. This raises the bar on
   source enumeration (§5.7), because an enumeration that never surfaces such a concept cannot
   detect the defect.
2. **Navigation and onboarding.** There is no overview of how the KB's concepts and the project's
   parts relate; a newcomer must read documents serially to build that map mentally.
3. **Impact analysis.** Answering "what does this change touch" — across KB docs, source
   artifacts, and external dependencies — is manual today.
4. **Agent/RAG routing.** Agents route over the KB via `INDEX.md`; explicit relationships give a
   richer structure to route on.

Because all four are primary, the artifacts must serve verification *and* comprehension — which
is a design constraint on the view, not just a list of benefits (see §5.6).

## 3. Users & Stakeholders

*Derived from §2; confirm at read-back.*

| Stakeholder | Interest |
|-------------|----------|
| **Maintainer / architect** | Primary human consumer. Uses the graph for structural inspection, impact analysis before a change, and reading the gap list. |
| **KB reviewer** | Consumes the gap ledger (FR-26) as review input; needs each finding to arrive with checkable evidence (FR-24). |
| **Newcomer to the project** | Uses the Overview lens to build a mental map without reading documents serially. |
| **AI agents** | Consume `relationships.md` as structure to route over, richer than `INDEX.md` alone (§2 item 4). Also the reason the artifact must stay machine-parseable, not merely human-readable. |
| **AID methodology owner** | Owns whether the KB-gap signal is trustworthy; affected by any incentive to weaken the significance rule (FR-25 rationale). |

## 4. Scope

*Derived from §5; confirm at read-back.*

### In Scope

- A new on-demand skill, `/aid-graph`, gated on an approved KB (FR-7, FR-8).
- Two generated artifacts: `relationships.md` and the interactive `graph.html` (FR-1, FR-2, FR-9).
- Source enumeration by structural significance, independent of the KB (FR-19 – FR-24).
- Two-pass extraction: deterministic scan plus a bounded agent pass (FR-29 – FR-32).
- Four preset lenses plus always-available manual controls (FR-13 – FR-15).
- An accessible table view as a peer rendering of the graph (NFR-2).
- A KB-gap reviewer ledger, routed onward (FR-25 – FR-28).
- Research to define the relation vocabulary (FR-5) and to choose the rendering approach (FR-18).
- Reuse of `/aid-summarize`'s HTML toolchain at the script layer (FR-12).

### Out of Scope

- **Fixing KB gaps.** Findings route to `/aid-update-kb` / `/aid-housekeep` (FR-27).
- **Any mutation of KB content.** The skill is read-only with respect to the KB (FR-10).
- **Gating on KB completeness.** The run never fails because gaps exist (FR-25, FR-28).
- **Merging into `/aid-summarize`.** Considered and rejected; sharing is at the script layer (FR-12).
- **Automatic ticket creation** for detected gaps.
- **Function- or line-level granularity** in the graph (FR-23).
- **Enumerating generated/derived trees or vendored code** (FR-22).
- **Validating KB content quality** beyond the structural gap signal — that remains discovery's job.

## 5. Functional Requirements

*(confirmed)*

- **FR-1:** Emit `relationships.md` capturing relationships between KB concepts/facts and the
  project source.
- **FR-2:** Emit a single-file interactive HTML graph view of those relationships with controls
  for grouping, density, and zoom.

### 5.1 Relationship sources (confirmed)

Relationships are drawn from exactly three sources:

1. **The Knowledge Base documents** — relationships among the concepts and facts the KB holds.
2. **The project source the KB represents** — the KB is a summary of information contained in
   the project source, so every KB fact is expected to connect to the source that generated it.
3. **The external sources the KB references** — the KB carries a document listing the external
   sources that contributed information to it (`external-sources.md`), so KB info is expected to
   connect to its contributing external source.

### 5.2 `relationships.md` table schema (proposed by owner; open to alternatives)

One table; each row is a single relationship, recorded once (never twice) because both
directions are named on the same row. Each endpoint is carried as **both** a machine-verifiable
id and a human-friendly display name. Eight columns.

| Column | Required | Meaning |
|--------|----------|---------|
| Source Id | required | Machine-verifiable identifier of the originating node (see §5.3). |
| Source Name | required | Human-friendly display name for the source node. |
| Target Id | required | Machine-verifiable identifier of the other node (see §5.3). |
| Target Name | required | Human-friendly display name for the target node. |
| S2T Relation | required | The type of relationship read Source → Target. |
| T2S Relation | required | The type of relationship read Target → Source — present so the inverse never needs a second row. |
| Provenance | required | How the relationship was established: `declared` (explicitly stated in the KB or source), `derived` (computed by a deterministic scan, no judgment), or `inferred` (concluded by the agent from reading content). |
| Observation | optional | A description or comment about the relationship. |

**`Strength` is dropped** *(Q1 resolved 2026-07-28)*. The column was retained as a possible
confidence-or-distance measure, but `Provenance` carries trust and the graph layout already conveys
distance through hop count, so a per-row number would duplicate what the picture shows while being
unreproducible across runs. The table is therefore **eight columns**, not nine.

### 5.3 Node identity (confirmed)

Every node id carries a prefix naming which of the three sources it belongs to, and resolves to
something a validator can check:

| Prefix | Refers to | Id form |
|--------|-----------|---------|
| `kb:` | A Knowledge Base concept, fact, or document | Reference into the KB doc (doc plus the concept/heading within it) |
| `int:` | An artifact in the project source the KB represents | **Repo-relative path** (optionally narrowed to a symbol within the file) |
| `ext:` | An external source that contributed information to the KB | **`ext:<key>`**, where `<key>` references the entry in the KB's external-sources file |

Because the KB already maintains a file mapping each external source to its origin (path or
URL), `relationships.md` rows never carry a raw absolute path or URL for external nodes — they
carry only the key, and the external-sources file remains the single place that resolves it.

### 5.4 Relation vocabulary (confirmed)

- **FR-4:** `S2T Relation` and `T2S Relation` draw from a **well-defined closed vocabulary of
  relation/inverse pairs**, not free text. Free-text nuance that no pair captures belongs in
  `Observation`.
- **FR-5:** The vocabulary is to be established by **dedicated research** producing a
  comprehensive set of relationship types with their inverses. A large vocabulary is acceptable
  and expected — comprehensiveness is preferred over brevity.
- **FR-6:** Relationship types are **categorized**, and the category is available as a grouping
  dimension for the graph view (see §5.5).

### 5.5 Skill shape and placement (confirmed)

- **FR-7:** The skill is named **`/aid-graph`** and is a standalone, on-demand skill — a sibling
  of `/aid-summarize` occupying the same post-KB slot in the lifecycle, not a phase of it and not
  auto-triggered by `/aid-discover`.
- **FR-8:** Preflight gates on a **completed, approved KB** — `.aid/knowledge/STATE.md` present
  with `User Approved: yes` — so it never runs mid-discovery.
- **FR-9:** Both artifacts land in `.aid/knowledge/`, alongside `kb.html`:
  `.aid/knowledge/relationships.md` and the graph view at `.aid/knowledge/graph.html`.
  `relationships.md` carries **valid KB frontmatter and is indexed like any other KB document**
  *(Q3 resolved 2026-07-28)* — consistent with `INDEX.md` itself being generated. If the graph view
  ships as multiple files (permitted by FR-16), its companion assets live in a subdirectory under
  `.aid/knowledge/` and must be named so the KB index generator does not treat them as KB documents.
- **FR-10:** The skill is **read-only with respect to KB content** — it reads the KB, the project
  source, and the external-sources file, and writes only its own two artifacts. It never edits
  the KB.
- **FR-11:** The skill is **idempotent** — a staleness check makes re-running on an unchanged KB
  a no-op, with `--reset` to force regeneration. Its staleness input set is **wider** than
  `/aid-summarize`'s: the KB, the project source, and the external-sources file.
- **FR-12:** `/aid-graph` **reuses `/aid-summarize`'s HTML toolchain at the script layer** rather
  than reimplementing it — single-file assembly, contrast checking, HTML output validation, and
  Playwright-backed visual validation. Sharing happens through the scripts, not by merging the
  skills.

### 5.6 Graph view — presets and controls (confirmed)

- **FR-13:** The view ships **four named preset lenses**, one per purpose in §2, each a saved
  configuration of the same underlying controls over the same table:
  - **Coverage** — highlights unbacked `kb:` nodes and undocumented `int:` nodes; dims
    well-formed structure. Serves purpose 1 (drift/coverage).
  - **Overview** — collapsed to categories and doc-level groups at low density. Serves purpose 2
    (navigation/onboarding).
  - **Impact** — select a node, show its neighborhood to an adjustable depth. Serves purpose 3
    (impact analysis).
  - **Provenance** — `kb:` → `int:`/`ext:` chains only, colored by the `Provenance` column.
    Serves purposes 1 and 4.
- **FR-14:** **Full manual controls remain available at all times** — grouping, density, filters,
  and zoom — whether the user arrived via a preset or started from scratch. Presets are entry
  points, not modes that lock the view.
- **FR-15:** No purpose is privileged by being the default layout; because all four purposes are
  equally primary (§2), acceptance criteria are stated per lens.
- **FR-16:** **Quality and interaction take priority over packaging constraints**
  *(owner decision 2026-07-28 — supersedes the original self-containment requirement).* The graph
  view is **no longer required** to be a single self-contained file. All three original packaging
  restrictions are dropped: it **may** ship as multiple files, it **may** fetch from a CDN or the
  network, and it **may** be produced by a real build step with third-party dependencies. The
  rendering research (FR-18) is to optimise for interaction quality and graph legibility, and is
  explicitly **not** to narrow its option space to preserve packaging purity.
- **FR-17:** Interactivity (grouping, density, zoom) makes **runtime JS mandatory**, so
  `kb.html`'s "no runtime diagram engine" rule does not apply to this artifact. That rule remains
  in force for diagrams in `kb.html`; the graph is a documented exception.
- **FR-18:** *How* the graph is rendered is **deferred to a RESEARCH task**, alongside the
  relation-vocabulary research (FR-5). Under FR-16 the option space is **unrestricted** — SVG,
  Canvas, and WebGL renderers are all admissible, at any payload size, with or without a build
  step. The research recommends on interaction quality, legibility at this project's node counts,
  accessibility support, and maintenance cost. See STATE.md § Cross-phase Q&A Q2.

**Consequences of dropping the packaging restrictions.** Recorded here because they change work
that was already scoped, and none of them are optional to handle:

1. **One reused validator collides with the graph by design, and it is not the one first assumed.**
   *(Corrected 2026-07-28 after reading the scripts.)*
   - `validate-visuals.mjs` is the real collision. It collects **every** `<svg>` in the document
     and applies its T2 check — sibling `<g>` bounding boxes may not overlap by more than 20% of
     the smaller element's area. A force-directed graph drawn as SVG with a `<g>` per node
     **overlaps by nature**, so it fails T2 by design and needs an explicit, parameterised
     exclusion. A `<canvas>` or WebGL surface matches none of that script's three selectors
     (`.diagram-box`, `.infographic`, `svg`) and needs no exemption at all.
   - `validate-html-output.sh`'s **NM** assertion does *not* fail by design: all three sub-checks
     are keyed on the literal token `mermaid` (an inline engine bundle, a `mermaid.initialize()`
     call, or a CDN Mermaid `<script src>`), so a non-Mermaid renderer passes it unchanged.
   - Its **S2** CDN-free assertion fails only *if* the selected packaging actually fetches from a
     CDN — a conditional consequence of the packaging choice, not an automatic one.

   In every case `kb.html` must keep all checks unchanged; any exemption is per-artifact and
   parameterised, never achieved by weakening the shared script (feature-011).

   **Note the trade-off this creates:** SVG is the cheaper renderer for accessibility (NFR-1) but
   is the one that trips T2; Canvas/WebGL avoid the validator entirely but raise the accessibility
   cost. Neither choice is free, and FR-18's research must weigh both together.
2. **A build step, if adopted, adds a generate-time dependency chain** — `node_modules`, a lockfile,
   and a bundler — to a repository whose CLI is currently pure Bash/Node-stdlib. That touches
   `technology-stack.md`, `infrastructure.md`, CI, and the skill's own preflight (C-5), and it means
   `/aid-graph` can fail for reasons unrelated to the KB.
3. **A CDN dependency makes the artifact non-portable and network-dependent**, so a graph generated
   today may not render later or offline. The research must state this cost plainly for whichever
   option it recommends, and prefer vendoring when the interaction quality is comparable.
4. **Third-party code acquires licence, attribution, and update obligations** regardless of how it
   is delivered.

### 5.7 Source enumeration (confirmed)

- **FR-19:** `int:` nodes are discovered by enumerating the project source **independently of the
  KB** — not only where a KB doc happens to reference something. KB-driven enumeration is rejected
  because it structurally cannot surface the defect described in §2 item 1: a source concept the
  KB never mentions would never become a node.
- **FR-20:** A source concept that appears in the graph with no KB representation is reported as a
  **KB gap** (a defect), not silently dropped and not merely rendered as an unconnected node.
- **FR-21:** A source artifact qualifies as a node by **structural significance**, not by mere
  file existence. It qualifies if any of the following holds:
  - it is an **entry point or public surface** — a skill, a CLI command, a template, or a script
    another script invokes;
  - it is **depended upon** by another source artifact;
  - it is a **named unit the project's own conventions treat as a unit** — a test suite, a
    manifest, a settings schema.
- **FR-22:** Excluded from enumeration: **generated/derived trees** (rendered profile and package
  outputs, which are mechanically produced from the canonical tree and would multiply every node
  and every reported gap by the number of profiles), **vendored third-party code**, and anything
  matched by an **ignore list in `.aid/settings.yml`**.
- **FR-23:** Enumeration granularity is the **whole artifact** — a script, a skill, a template —
  never individual functions or lines.
- **FR-24:** Significance must be **derivable rather than judged** wherever possible, so that a
  reported KB gap carries `declared` or `derived` provenance and arrives with evidence a reviewer
  can check. The skill must not manufacture defects from `inferred` opinion alone.

### 5.8 Extraction pipeline (confirmed)

- **FR-29:** Extraction is **script-majority, agent-in-the-gaps** — two passes, not one mechanism.
- **FR-30:** **Pass 1 — deterministic scan.** Harvests what is already declared and what is
  mechanically derivable. Rows are stamped `declared` or `derived`.
  **Declared carriers corrected 2026-07-28** — an earlier draft named `Evidence:` citations, which
  do not exist in this KB (two occurrences, both prose labels in a single document). The real
  carriers, verified present across the KB, are:
  - **`sources:` frontmatter lists** — one per KB document, naming the files that document draws on;
  - **inline durable anchors** of the form `CONFIRMED <path> (search: "<token>")` — between 7 and 30
    per document;
  - **frontmatter cross-references** (`see_also`, `contracts`) and the generated routing index;
  - **external-source keys** resolved through the KB's external-sources file.

  Mechanically derivable edges remain file references, invocations, and dependency relations.
- **FR-31:** **Pass 2 — bounded agent pass.** Runs only over what the scan could not settle: the
  concept-level `kb:` nodes that require reading to identify, and candidate edges the scan surfaced
  but could not type. Rows are stamped `inferred`.
- **FR-32:** On an unchanged repository the deterministic majority of `relationships.md` is
  **byte-identical across runs**. This is what makes FR-11's staleness check meaningful: without a
  reproducible majority, the staleness check could not distinguish real drift from model
  nondeterminism and the artifact would churn on every invocation.

### 5.9 Gap reporting and routing (confirmed)

- **FR-25:** `/aid-graph` **reports gaps, it does not gate on them.** The run completes
  successfully regardless of how many KB gaps it finds.
- **FR-26:** Gap findings are written as a **reviewer ledger** in the project-wide 7-column shape
  (`# | Severity | Status | Doc | Line | Description | Evidence`) at
  `.aid/.temp/review-pending/<scope>.md`, one row per gap, each carrying the offending `int:` node
  as evidence.
- **FR-27:** Fixing gaps is **out of scope for this skill**. Findings route to `/aid-update-kb` or
  `/aid-housekeep`, which already own targeted KB updates and re-discovery.
- **FR-28:** The skill's own quality gate covers **its own artifacts only** — id resolvability,
  inverse-pair consistency, provenance population, and the HTML view's validity — never the KB's
  completeness.

**Rationale.** Gating on KB completeness would fail `/aid-graph` for reasons outside its own
control, and would create an incentive to tune the significance rule (FR-21) downward until gaps
disappear — corrupting the signal the artifact exists to produce. Reporting-only also preserves the
one-way trust direction set by FR-10: the tool observes and cannot alter what it observes.

**Decision — separate skill, shared scripts.** Folding this into `/aid-summarize` was considered
and rejected. The two artifacts differ in audience (`kb.html` targets a non-technical newcomer and
forbids KB authoring-rule leakage; the graph targets a maintainer doing structural inspection), in
grading model (`relationships.md` grades as *data* — id resolvability, inverse-pair consistency,
provenance coverage — while `kb.html` grades on visual fidelity behind a mandatory human visual
gate), and in staleness inputs (see FR-11). The reuse argument is satisfied at the script layer
because the HTML machinery already lives outside the skill, in `aid/scripts/summarize/`. Accepted
cost: one more skill in the canonical→profiles render and the install manifests, plus some
duplicated preflight/writeback prose.

- **FR-3:** This table is the **single input** to the graph display — the HTML view renders from
  it rather than from an independent extraction pass.

## 6. Non-Functional Requirements

### 6.1 Accessibility (confirmed)

- **NFR-1:** `graph.html` meets **WCAG AA**, matching the bar `kb.html` already holds.
- **NFR-2:** AA is satisfied by shipping **two first-class renderings of the same data**: the
  interactive graph, and an **accessible table view** — sortable, filterable, keyboard-navigable,
  screen-reader friendly — which is the `relationships.md` content rendered as real HTML. The
  table is not a hidden fallback; it is a peer view.
- **NFR-3:** Every preset lens (FR-13) applies to **both** renderings. "Coverage" in table form
  lists exactly the gap rows the graph highlights.
- **NFR-4:** **Reduced-motion** preference disables layout animation and renders a settled graph.
- **NFR-5:** **Colour is never the sole carrier of meaning** — node type and provenance are also
  conveyed by shape and/or label.
- **NFR-6:** Zoom and pan have **keyboard equivalents**.

**Rationale.** The table carries the accessibility burden the canvas cannot, without fighting the
medium — and for verification work a filterable list of gap rows is often the better tool anyway.
It is also mechanically validatable, so it can inherit `validate-html-output.sh` and the existing
a11y checks, leaving the human visual gate to judge whether the graph is legible. Because the
table *is* the single input to the view (FR-3), this adds no second data path.

## 7. Constraints

*Derived from the existing codebase and KB; confirm at read-back.*

- **C-1:** ~~`graph.html` must be a single self-contained file~~ — **withdrawn 2026-07-28** per the
  owner's decision recorded at FR-16. No packaging constraint binds the graph view. `kb.html`'s own
  S2 self-containment gate is unaffected and remains in force for that artifact.
- **C-2:** The skill is authored in the canonical tree and rendered to every host profile by the
  existing profile renderer; it must not be hand-maintained per profile.
- **C-3:** Adding a skill touches the install and emission manifests, which the KB already flags as
  lockstep hazards — the change must keep them consistent.
- **C-4:** Reuse rather than reimplement `/aid-summarize`'s HTML scripts (FR-12); do not fork them.
- **C-5:** Existing validator tooling requires Node.js ≥ 20, and Playwright-based visual validation
  must degrade gracefully when the browser is not provisioned (as `/aid-summarize` already does).
- **C-6:** Reviewer output must use the project-wide 7-column ledger schema written to
  `.aid/.temp/review-pending/` (FR-26) — no bespoke findings format.
- **C-7:** `relationships.md` lives in the KB folder and is a KB-adjacent artifact, so it must obey
  KB authoring conventions where they apply (frontmatter, machine-parseability). **Specifically:**
  the KB index generator emits one entry per non-dot KB document, so a `relationships.md` placed in
  `.aid/knowledge/` will be picked up by the index and must therefore carry valid KB frontmatter
  (`kb-category`, `objective`, `summary`, `tags`). **Resolved 2026-07-28 (Q3):** it satisfies that
  contract — `relationships.md` is a generated, indexed KB document.

## 8. Assumptions & Dependencies

*Confirm at read-back.*

- **A-1:** The KB maintains a file mapping each external source to its origin (path or URL), so
  `ext:` rows carry only a key and never a raw URL (§5.3).
- **A-2:** The KB is complete and approved before this skill runs; it does not validate KB content.
- **A-3:** `Provenance` is a required column — every row has a provenance by construction (§5.2).
- **A-4:** The graph view's entry point is `graph.html` (FR-9); companion assets, if the selected
  packaging produces any, sit beside it under `.aid/knowledge/`.
- **A-6:** Test fixtures are self-built and do not depend on any work folder's contents, per the
  project's transient-work-folder rule — this binds the Q4 `ext:` fixture (AC-1).
- **A-5:** Node counts land in the hundreds, not tens of thousands, given FR-22/FR-23 — this is what
  makes the layout tractable. If a target project violates it, the density controls alone will not
  rescue the view.
- **D-1:** Depends on the relation-vocabulary research (FR-5) completing before implementation.
- **D-2:** Depends on the rendering-approach research (FR-18, Q2) completing before implementation.
- **D-3:** Depends on `/aid-summarize`'s script layer remaining stable, or on extracting the shared
  pieces to a neutral location.
- **D-4:** FR-22's ignore list depends on a **new settings section that does not yet exist**
  (`.aid/settings.yml` is at `format_version: 3`); adding it may require a version bump and a
  reconcile rule — see STATE.md Q6.
- **D-5:** Real-world `ext:` resolution depends on an **entry format for the KB's external-sources
  file that does not yet exist**, and which `/aid-graph` may not author itself under FR-10 — see
  STATE.md Q7.

## 9. Acceptance Criteria

*Derived; per-lens per FR-15. Confirm at read-back.*

**`relationships.md`**

- **AC-1:** Every `Source Id` and `Target Id` resolves — a `kb:` id to an existing KB doc and
  heading/concept, an `int:` id to an existing repo-relative path, an `ext:` id to an entry in the
  external-sources file. **The `ext:` branch is validated against a synthetic test fixture**
  *(Q4 resolved 2026-07-28)*, because this project's own `external-sources.md` has zero entries and
  would satisfy the criterion vacuously. The fixture supplies a controlled external-sources file
  with both resolvable and deliberately unresolvable keys, so the check is proven to fire.
- **AC-2:** Every row's `S2T Relation` and `T2S Relation` are a valid inverse pair from the closed
  vocabulary; no row's two directions disagree.
- **AC-3:** No relationship is recorded twice (once forward, once inverse) — one row per
  relationship.
- **AC-4:** Every row carries a `Provenance` value of `declared`, `derived`, or `inferred`.
- **AC-5:** Re-running on an unchanged repository leaves the deterministic (`declared` + `derived`)
  rows byte-identical (FR-32).

**`graph.html`**

- **AC-6:** *(rewritten 2026-07-28 — the original offline/no-CDN criterion is withdrawn with C-1.)*
  Given the artifact as delivered by whatever packaging the rendering research selected, when it is
  opened by its documented entry point, then it renders the graph successfully, and its runtime
  prerequisites (network access, companion asset files, or a build output) are **documented
  explicitly** so a reader knows what the artifact needs to work.
- **AC-7:** All four preset lenses are present and each visibly changes the view; each applies to
  both the graph and the table rendering.
- **AC-8:** Grouping, density, filter, and zoom controls remain usable after arriving via a preset.
- **AC-9:** Passes the existing HTML structural and a11y checks at WCAG AA; the table view is
  keyboard-navigable and screen-reader usable; reduced-motion yields a settled graph.
- **AC-10:** Renders from `relationships.md` alone — no second extraction path (FR-3).

**Skill behavior**

- **AC-11:** Preflight refuses to run without an approved KB, with an actionable message.
- **AC-12:** Re-running on an unchanged KB and source is a no-op; `--reset` forces regeneration.
- **AC-13:** No KB file is modified by any run.
- **AC-14:** Detected KB gaps appear as ledger rows with the offending `int:` node as evidence, and
  the run still completes successfully.
- **AC-15:** The Coverage lens surfaces exactly the gaps present in the ledger — the two agree.
  **Scope clarified 2026-07-28:** the equality binds the **`int:` class only** — undocumented source
  artifacts. That is the class FR-20 defines as a KB gap and the class FR-26 requires the ledger to
  carry as evidence. The Coverage lens additionally highlights unbacked `kb:` nodes per FR-13; that
  is a **lens-only signal** with no corresponding ledger row, and its presence does not breach this
  criterion. (The alternative reading — extending the ledger to emit `kb:`-unbacked rows too — was
  considered and not adopted, because FR-20 and FR-26 are explicitly source-artifact-keyed.)
- **AC-16:** Enumeration honours the exclusions in FR-22 — no node originates from a generated or
  derived tree, from vendored code, or from an ignore-listed path; and no node is finer-grained than
  a whole artifact (FR-23).
- **AC-17:** The HTML pipeline invokes `/aid-summarize`'s existing scripts rather than forked copies
  (FR-12) — verified by review, and by the absence of duplicated assembler/validator logic.
- **AC-18:** `relationships.md` carries KB frontmatter valid for the KB index generator, and
  regenerating the KB index leaves both the index and `relationships.md` consistent (C-7).

## 10. Priority

**Immediate — highest priority.** The owner directed that this work start now, ahead of other
candidate work.

Rationale: two of the four purposes in §2 are quality signals about the Knowledge Base itself, and
the KB is load-bearing for every downstream pipeline phase — a KB with undetected gaps degrades
everything built on it.

**Proposed delivery shape** (recommendation carried into `/aid-plan`, which owns final sequencing):

1. **Research** — the relation vocabulary (FR-5) and the rendering approach (FR-18). Both block
   implementation (D-1, D-2).
2. **`relationships.md` + gap ledger** — a functional MVP on its own: it delivers verification,
   impact analysis, and agent-routable structure with no view at all, because the table is readable
   as markdown. Nearly all the value and nearly all the risk live here — the extraction, the
   identity scheme, and the significance rule.
3. **`graph.html`** — the interactive view plus the accessible table view, built on deliverable 2's
   output. Comparatively contained once the table exists and the rendering research has landed.

Sequenced this way, the expensive research blocks nothing from being usable: if the rendering
research stalls, `relationships.md` and the gap ledger still ship.
