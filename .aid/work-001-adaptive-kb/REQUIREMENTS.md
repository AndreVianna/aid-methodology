# Requirements

## Change Log

> **Note:** the 2026-05-30 rows for Q1–Q8 record the *original* design decisions. Several were
> **superseded by the same-day RE-SCOPED row** (dropped: dedicated `.aid/doc-set.yml`+parser,
> archetype classifier, `discovery-generalist`, INDEX section-nesting; dropped: P2 sources
> (out of scope); deferred: P3). The current design is the post-re-scope state in §§1–10.

| Date | Change | Source |
|------|--------|--------|
| 2026-05-30 | Initial interview started | /aid-interview |
| 2026-05-30 | Captured full intent brief into §§1–10; sections with open design questions marked Partial | /aid-interview (user brief) |
| 2026-05-30 | Q1 resolved: registry lives at `.aid/doc-set.yml` (dedicated YAML) | /aid-interview |
| 2026-05-30 | Q2 resolved: archetype-seeded derivation keyed on project-index.md signals | /aid-interview |
| 2026-05-30 | Q3 resolved: no fixed source-folder convention — discovery identifies sources from the tree | /aid-interview |
| 2026-05-30 | Q4 resolved: extract-on-read via host-native file reading; no shipped extractor / no CI extractor wiring | /aid-interview |
| 2026-05-30 | Q5 resolved: extend INDEX.md with nested per-doc section lists (single always-loaded index) | /aid-interview |
| 2026-05-30 | Q6 resolved: owner enum = 5 specialists + new discovery-generalist fallback | /aid-interview |
| 2026-05-30 | Q7 resolved: P4 (vector/RAG/MCP) DROPPED as non-goal; distillation scales retrieval | /aid-interview |
| 2026-05-30 | Q8 resolved: P0 standalone first → P1 → P2 → P3; deliverable breakdown deferred to /aid-plan. All 8 open questions resolved | /aid-interview |
| 2026-05-30 | Interview complete — approved | /aid-interview |
| 2026-05-30 | Cross-reference (reviewer) A+: all codebase claims confirmed; fixed §3 "6+ files"→"several files" + two-source expectations (#4), and §4/FR-P1-3 project-index.md as file-inventory-requiring-inference (#5) | /aid-interview (cross-reference) |
| 2026-05-31 | work-002 eliminated — P2 (heterogeneous sources) dropped entirely (out of scope), not a planned future work (user decision). L6 resolved + removed per kb-authoring P9. | user + /aid-execute |
| 2026-05-31 | Full independent review (grade D→fixes): added **FR-P0-4** (reconcile 14-vs-16 doc-count drift + pin canonical default set, enumerated in §8) addressing the HIGH undefined-standard-set finding; §3 ownership spread "~12 locations"; FR-P1-6 retargeted at the agent-to-file mapping (gate already soft); AC4 reworded to a mechanical invariant; FR-P1-3 user-confirm-as-safety-net; suite-count wording de-pinned; clarified change-log supersession. Feature SPECs: F1 +external-sources strand; F2 canonical-source + reviewer-loads-file; F4 atomic ACs + /aid-plan split note; tech-debt H5 note refreshed | /aid-interview (full review) |
| 2026-05-30 | **RE-SCOPED after over-scope analysis** (independent adversarial review + user decision): trimmed to P0 + lean P1. Dropped the dedicated `.aid/doc-set.yml`+parser, archetype classifier/seeds/fixtures, and the mandated new `discovery-generalist` agent. **P2 (heterogeneous sources) dropped (out of scope, not a planned future work); P3 (section-index, runtime retrieval surface, freshness guard) deferred.** Rationale: much of the intended flexibility already exists unenforced (`extension` kb-category, list-valued settings, "not every doc required" doctrine); H5 is one non-urgent High item and the original cure was heavier than the disease. | /aid-interview |

## 1. Objective

Make the Knowledge Base (KB) **doc-set shape itself to the project it describes**, instead of
forcing every project into the fixed software-development doc-set. AID applies far beyond
software (this meta-repo is itself proof), so the **set of authored KB docs** must faithfully
represent whatever the project actually is — added, removed, renamed, or repurposed from the
standard default, with that deviation expressed as **configuration**, not an undocumented
exception.

> **Scope note (post re-scope):** the broader original vision also included referencing
> arbitrary raw sources (PDFs/spreadsheets/data) and section-granular retrieval upgrades. Those
> are **real and intent-aligned but orthogonal to doc-set rigidity (H5)** and are out of
> scope here — heterogeneous sources **dropped**, retrieval upgrades **deferred** — so
> this work stays the smallest proportionate fix for H5. See §4 Out of Scope.

## 2. Problem Statement

- The KB's "standard" doc-set (architecture, schemas, test-landscape, …) is the right
  default for the majority case — software development — but it is just **one project
  type's profile**. Non-software projects (methodology/meta-repos, research, docs-only,
  data, business/ops) need a different set, and there is **no supported mechanism to declare
  that deviation**.
- This repo itself required an **undocumented one-time carve-out** in cycle-1: rename
  `api-contracts → pipeline-contracts`, rename `data-model → schemas`, replace
  `ui-architecture → repo-presentation`, delete `security-model`. Concrete proof the fixed
  set doesn't fit — done by hand, with no way to express it as config.
- The flexibility is **partly present but unenforced** today: `build-kb-index.sh` already has
  an `extension` kb-category for project-specific docs; the frontmatter schema + tier model
  already govern extension docs; the KB templates README already says *"not every document is
  required."* What's missing is a **declared doc-set the completeness gate honors** (instead
  of hard-coding the standard filenames) and the **de-duplication of triplicated ownership +
  expectations**.
- Tracked as tech-debt **H5 (High)** — currently the entire High-severity backlog (0
  Critical, 1 High, 0 Medium, 0 Low). Not urgent; the fix must not cost more than the debt.

## 3. Users & Stakeholders

- **AID adopters / project teams** — get a KB whose doc-set matches their project type instead
  of a software-dev-only template; can add / remove / rename / repurpose docs as config.
- **Discovery sub-agents** (the 5: scout, architect, analyst, integrator, quality) — gain a
  single declarative doc-set + ownership source instead of ownership hard-coded in **~12
  locations** (the 5 agent definitions — each in its frontmatter line *and* body — plus the
  `state-generate.md` mapping table and the SKILL.md ownership table), and per-doc
  expectations duplicated between two sources (`document-expectations.md` and
  `discovery-reviewer`).
- **Discovery reviewer** — validates exactly the declared set (no hang on intentionally
  omitted docs).
- **The AID meta-repo maintainers** — this repo is the primary acceptance test (its cycle-1
  carve-out must become reproducible configuration) and they carry the methodology's
  maintenance cost, so the fix must honor convention-over-infrastructure.

## 4. Scope

### In Scope

- **P0 — Pre-work / correctness** (real bugs surfaced by analysis):
  - Reconcile the self-contradictory `discovery-scout` doc ownership (it claims
    `infrastructure.md`/`project-structure.md` while `state-generate.md` + SKILL.md assign
    `infrastructure.md` to quality and `external-sources.md` to scout).
  - Consolidate the per-doc "expectations" currently duplicated near-verbatim in
    `document-expectations.md` and `discovery-reviewer` into **one source**.
  - Remove the orphaned `canonical/templates/ui-architecture.md` stub (and its rendered
    copies / stragglers) left from the cycle-1 `→ repo-presentation` rename.
  - **Remove the fixed doc-count assumption** (the 14-vs-16 literals across the tooling) so
    the doc set/count varies by the declared set; the default seed set (§8) is the fallback.
    Realized with the P1 declared-set work (same surface).

- **P1 (lean) — Declared, project-shaped doc-set:**
  - A **declared doc-set** the discovery completeness gate honors — a minimal list of
    `{filename, owner, presence (required/conditional, + optional when)}`, defaulting to the
    current standard set. It **replaces the hard-coded doc-filename list** in
    SKILL.md/state-generate.md and the triplicated ownership map. *Reuse what already exists*:
    `kb-category` lives in each doc's frontmatter; per-doc expectations live in the P0-
    consolidated source keyed by filename — the declared set does **not** re-declare them.
    Implementation form (a section in the existing `settings.yml` vs. a small dedicated file)
    is decided in `/aid-specify`, kept as light as possible; **no bespoke parser** unless
    `owner`/`presence` genuinely cannot fit the existing list-valued settings form.
  - **Discovery proposes the doc-set and the user confirms** — discovery reads
    `project-index.md` (a regenerated **file inventory** of the whole tree: paths, sizes,
    languages — *not* a ready-made project-type label) and **infers** a proposed doc-set from
    it (default = standard; deltas for non-software projects), which the user confirms or edits.
    The inference is an LLM judgment step (its concrete heuristics are for `/aid-specify`).
    **The user-confirm step is the safety net** — because inferring "this is a research /
    docs-only project" from file/language ratios is a heuristic, correctness does not depend on
    the inference being right, only on the human catching a wrong proposal.
    **No archetype taxonomy/classifier, no per-archetype seed files, no archetype fixtures** —
    the propose+confirm step is the derivation.
  - **Custom docs get an owner + expectations and are actually generated + reviewed.** The
    `owner` resolves to an existing discovery agent (a doc that fits no specialist is assigned
    to a suitable existing agent, e.g. architect, via its prompt). **No mandated new agent**;
    if a dedicated "generalist" mode proves necessary, `/aid-specify` decides — it is not a
    requirement here.
  - **The cycle-1 carve-out is reproducible as configuration**, validated on this repo.

### Out of Scope

- **P2 — Heterogeneous (non-code) sources** → **dropped (out of scope).** Real and
  intent-aligned (referencing PDFs/spreadsheets/data via durable anchors, host-native
  extract-on-read, source-synthesis doc) but orthogonal to doc-set rigidity; bundling it
  inflates this work.
- **P3 — Retrieval upgrades** → **deferred** (no current evidence of need): runtime retrieval
  surface, section-level INDEX.md nesting, freshness guard. The section-index in particular
  would inflate the always-loaded INDEX.md for every agent/phase to fix a blind-grep cost
  nobody has shown is real.
- **P4 — vector / RAG / semantic-retrieval / MCP backend** → **dropped as a non-goal** (not a
  default, opt-in, or seam): it conflicts with the KB-as-distillation thesis — the KB is
  already a curated synthesis; semantic search over raw content bypasses the synthesis layer
  the KB exists to provide. Large corpora scale by **distilling harder** (a future work may
  add a source-synthesis/index doc), not by indexing raw bytes.
- Refreshing the root `.claude/` dogfood install (separate maintenance task).

## 5. Functional Requirements

> Trimmed to P0 + lean P1. To be decomposed into features after approval.

- **FR-P0-1** Reconcile contradictory `discovery-scout` doc ownership to a single truth.
- **FR-P0-2** Consolidate per-doc expectations into one source (de-duplicate
  `document-expectations.md` ↔ `discovery-reviewer`).
- **FR-P0-3** Remove the orphaned `ui-architecture.md` template stub + stragglers (and
  rendered copies across the 3 profiles + dogfood tree).
- **FR-P0-4** **Remove the fixed doc-count assumption from the tooling.** Strip the hardcoded
  doc-count/doc-list literals (the "14"/"16" in `SKILL.md`, `state-generate.md`,
  `state-review.md`, `build-kb-index.sh:169`, `README`) and replace them with references to the
  declared (default-seed-or-derived) set, so the count/identity of docs is never hardcoded and
  varies by project. The default seed set (enumerated in §8) remains the fallback when no
  override is declared. *(Realized together with FR-P1-1/FR-P1-6 — same surface; lives in the
  declared-doc-set feature, not a separate one.)*
- **FR-P1-1** Introduce a **declared doc-set** the completeness gate reads — a minimal list of
  `{filename, owner, presence (required/conditional, + optional when)}`, replacing the
  hard-coded doc-filename list and the triplicated ownership map. Does **not** re-declare
  `category` (in frontmatter) or `expectations` (in the P0-consolidated source). Form decided
  in `/aid-specify`; no bespoke parser unless the existing list-valued settings form cannot
  carry `owner`/`presence`.
- **FR-P1-2** Default the declared set to the current standard software-dev set (backward
  compatible — projects with no override behave unchanged).
- **FR-P1-3** Discovery **proposes** the doc-set by **inferring** it from `project-index.md`
  (a whole-tree file inventory, not a project-type signal — the inference is an LLM judgment
  step) (default = standard; deltas for the actual project) and the **user confirms/edits**.
  The user-confirm step is the safety net for the heuristic inference (correctness rests on the
  human catching a wrong proposal, not on the inference being perfect). No archetype
  classifier/seed-sets/fixtures.
- **FR-P1-4** Support **add / remove / rename / repurpose** of docs via the declared set; this
  repo's cycle-1 carve-out becomes reproducible configuration.
- **FR-P1-5** Custom docs receive an **owning agent (one of the existing discovery agents) +
  expectations** and are actually generated and reviewed. No new agent is required by this
  work.
- **FR-P1-6** Discovery honors the declared set end-to-end so an intentionally-omitted doc
  does not stall generation. (The completeness check is already a soft count, not a hard
  per-name hang — `state-generate.md` confirms `count == declared-set size`; the real risk is
  the **agent-to-file mapping table** in `state-generate.md` / SKILL.md not honoring
  omissions/additions. This FR targets that mapping table, not the count.)

## 6. Non-Functional Requirements

Principles to honor (the re-scope is itself in service of these):

- **Convention over infrastructure** — prefer reusing existing mechanisms (frontmatter,
  list-valued settings, the `extension` category) over new files/parsers/agents.
- **Dependency-free core** — zero pip/npm; no embedder/vector store/MCP introduced.
- **Tool-agnostic** — renders byte-identical across claude-code / codex / cursor (the
  generator enforces this); any change must keep render-drift clean across the 3 profiles.
- **Git-diffable, human-reviewable KB** — no opaque binaries in the core.
- **Reviewer-as-backstop / rigor-follows-value (P8)** — authoring agents own correctness; the
  reviewer spot-checks, doesn't grind.
- **Backward compatible** — existing software projects on the standard default keep working
  unchanged.

## 7. Constraints

- Core stays dependency-free; no new runtime/toolchain is added (no extractor, no vector/MCP).
- GitHub Actions stay SHA-pinned; dependabot unaffected.
- New canonical suites are auto-discovered by `run-all.sh` and wired into the existing
  canonical-tests gate. The existing suites (13 today) stay green and the new P1 suites are
  added — non-regression is "existing suites green + new suites pass," not a fixed total.
  Generator self-tests + render-drift stay green.
- Any new agent prompt or template change must render byte-identically across the 3 profiles
  **and** the dogfood `.claude/` tree (or the dogfood refresh is explicitly out of scope).

## 8. Assumptions & Dependencies

- **No fixed doc-count anywhere.** The number and identity of KB docs **vary by project
  type** — that is the whole point of this work, applied to its own tooling. There is a
  **default seed set** for software-dev projects (the docs that exist as templates in
  `canonical/templates/knowledge-base/`: `architecture`, `coding-standards`,
  `domain-glossary`, `external-sources`, `feature-inventory`, `infrastructure`,
  `integration-map`, `module-map`, `pipeline-contracts`, `project-structure`, `schemas`,
  `tech-debt`, `technology-stack`, `test-landscape`, plus meta `README` + generated `INDEX` +
  discovery `STATE`) — but this is a **seed, not a universal invariant**. The actual set is
  whatever the declared/derived set says.
- The current "14 vs 16" disagreement in the tooling (`SKILL.md` "14" vs
  `state-generate.md` / `state-review.md` / `build-kb-index.sh:169` / `README` "16") is a
  symptom of the fixed-count assumption and is resolved by **removing the hardcoded count**
  (FR-P0-4), not by choosing a number. `repo-presentation.md` having no canonical template is
  **expected** — it is a per-project (this-repo) doc carried via the declared set as a custom
  doc, not a default-seed member.
- `read-setting.sh` already supports list values (verified) → the declared set can likely
  reuse it, minimizing new parsing code.
- `build-kb-index.sh` already supports an `extension` kb-category, and the frontmatter
  schema + tier model already govern extension docs → custom docs are already representable.
- `project-index.md` already inventories the whole tree → discovery already has the signal it
  needs to propose a doc-set.
- The 5 discovery sub-agents stay; their doc ownership becomes declared-set data. **No new
  agent is added by this work.**
- This meta-repo is available as the primary acceptance test.

## 9. Acceptance Criteria

1. A project can declare a doc-set that adds/removes/renames/repurposes docs; discovery
   generates and reviews exactly that set; the **completeness gate does not hang** on an
   intentionally-omitted doc.
2. Custom docs get an owning agent (an existing discovery agent) + expectations and are
   actually generated and reviewed.
3. This repo's cycle-1 carve-out is reproducible **as configuration** (rename
   `api-contracts→pipeline-contracts`, `data-model→schemas`, replace
   `ui-architecture→repo-presentation`, drop `security-model`) — not an undocumented
   exception.
4. A deliberately non-software project type (e.g. research / docs-only) goes through
   discovery's propose→confirm step and produces a declared set that **mechanically differs**
   from the standard default (omits ≥1 standard doc and/or adds ≥1 custom doc); the user's
   edits to the proposal are honored verbatim; and discovery then generates and reviews exactly
   that confirmed set. *(Stated as a mechanical invariant — "appropriate" is a human judgment
   made at the confirm step, not a machine assertion.)*
5. **No fixed doc-count in the tooling:** all hardcoded "14"/"16" literals are removed or
   replaced by references to the declared set, so the count/identity of docs varies by the
   declared (default-seed-or-derived) set; the default seed set (§8) is the fallback when no
   override is declared. (`repo-presentation` needs no canonical template — it is a per-project
   custom doc carried via the declared set.)
6. **Non-regression:** existing standard-default projects behave unchanged; all generator
   self-tests + the **existing canonical suites (13 today)** stay green and the **new P1 suites
   are added**; render-drift across the 3 profiles is clean. The scattered ownership +
   duplicated expectations are de-duplicated with no behavioral change to the standard set.

**Tests (planned):**

- New canonical suites: declared-set parse/resolve; the propose→default→confirm flow; the
  completeness gate reading the declared set (no-hang on omission).
- Fixtures: the standard-default (dev) set behaves unchanged + one non-software set
  (e.g. meta-repo or docs-only) resolves to an appropriate doc-set.
- Carve-out validation: this repo's cycle-1 deviation expressed as config and resolved.
- Regression: existing canonical suites (13 today) green + new P1 suites pass; render-drift
  across 3 profiles clean.

## 10. Priority

Phasing (to be finalized in `/aid-plan`):

1. **P0** correctness fixes (scout/quality ownership, expectations consolidation, orphan-stub
   removal) — ship first as a small non-regression baseline (de-risks P1: these are the exact
   surface the declared set replaces). FR-P0-4 (remove the fixed doc-count assumption) is
   realized with the P1 declared-set work since it's the same surface.
2. **P1 (lean)** declared doc-set + propose/confirm + custom-doc ownership, validated on this
   repo's carve-out and one non-software fixture.

*(P2 dropped (out of scope); P3 deferred; P4 dropped — see §4 Out of Scope.)*

**Detailed deliverable/task breakdown is deferred to `/aid-plan`.**
