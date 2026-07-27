---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-25"
minimum_grade: "A+"
user_approved: no
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-07-26T21:06:07Z'
pause_reason: --
block_reason: --
block_artifact: --
---

# Work State -- work-001-skill-explorer

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/works/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task DETAIL.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

This is a **full** multi-delivery work: the flattened-only `delivery_state` / `gate_tier` /
`gate_grade` / `gate_timestamp` frontmatter keys and the singular `## Delivery Lifecycle` /
`### Tasks lifecycle` / `## Delivery Gate` sections are intentionally absent -- each delivery's
lifecycle and gate live in its own `delivery-NNN/STATE.md`, and each task's state in its
`delivery-NNN/tasks/task-NNN/STATE.md`, unioned by the DERIVED views below.

---

## Pipeline State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`,
     `block_artifact`), written ONLY by `writeback-state.sh --pipeline ...` at every
     phase/state transition the pipeline performs (surgical frontmatter rewrite; never
     hand-edited). All values are closed enums so a deterministic reader needs no
     inference. This section retains the enum reference below for human readability. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**State:** Approved  **Grade:** A+  **Minimum:** A+  **Grade Source:** aid-define CROSS-REFERENCE — first pass C (3 MEDIUM, 1 LOW, 1 MINOR); all five Fixed, 2 rows routed OOS, re-graded A+ (ledger `.aid/.temp/review-pending/interview-work-001-skill-explorer-cross-ref.md`)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-07-25 |
| 2 | Problem Statement | Complete | 2026-07-25 |
| 3 | Users & Stakeholders | Complete | 2026-07-25 |
| 4 | Scope | Complete | 2026-07-25 |
| 5 | Functional Requirements | Complete | 2026-07-25 |
| 6 | Non-Functional Requirements | Complete | 2026-07-25 |
| 7 | Constraints | Complete | 2026-07-25 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-25 |
| 9 | Acceptance Criteria | Complete | 2026-07-25 |
| 10 | Priority | Complete | 2026-07-25 |

### Review History

| Date | Reviewer | Outcome | Notes |
|------|----------|---------|-------|
| 2026-07-25 | 6× aid-architect + 6× aid-reviewer (Large) + owner | Specify — all 6 features A+ | Owner-chosen **dependency-wave** parallelism: `{001,003}` → `{002,004,005}` → `{006}`, each feature independently gated to the A+ floor. First-pass grades C+, C, A+, A, A, B+; all closed at **A+** across 1–3 review rounds each; 6 ledgers clean, then deleted per the DONE contract. Owner decisions taken mid-phase: §7 amended (correct the stale `gen-reference.test.mjs` roster **and** add `npm test` to `docs.yml`), and KI-008 routed to feature-003 as an amendment rather than a downstream patch. 14 known issues registered (KI-001..KI-014), 4 pre-existing defects in `site/` among them. 10 Open Questions remain, all non-blocking — no reviewer found one that leaves an acceptance criterion unverifiable. |
| 2026-07-25 | aid-reviewer (Large) + owner | Cross-Reference — A+ | First pass graded **C** against an A+ minimum: 3 MEDIUM, 1 LOW, 1 MINOR. Three fixed directly as factual/logical errors (`astro-mermaid` recorded as unused when it is the site's live diagram pipeline; an unverified "~94 doorways" count; FR-3's layers mis-traced across features 003/005/006). Two needed owner decisions and got them — **Q1** re-set the taxonomy (`aid-triage` is Support; the full path is 5 skills; deploy/monitor are ordinary shortcuts), **Q2** confirmed FR-6 as an owner decision. Re-graded **A+**; 2 rows routed OOS (stale `gen-reference.mjs` comment and its stale `SKILL_GROUPS` grouping). |
| 2026-07-25 | aid-architect + owner | Feature Decomposition | 6 features created in `features/`: 001 skill-detail-pages, 002 grouped-skill-index, 003 authored-flow-charts, 004 doorway-engine-charts, 005 verbatim-source-provenance, 006 interactive-node-panel (Should). Coverage matrix maps every FR-1..FR-6 and AC-1..AC-8 to an owner; nothing orphaned. Order: 001 → {002, 003}; 003 → 004 → 005 → 006. FR-6 isolated in feature-004 so a reversal touches only that SPEC. |
| 2026-07-25 | Work owner (human) | Approved | Approved at COMPLETION read-back. Name "Skill Explorer" owner-chosen; Description as composed. Quality check added AC-8 (FR-5 was unverifiable); KB check corrected the §8 structural taxonomy to four shapes and added AC-4's kind-sibling fixture. **FR-6 is an interviewer default** — the owner skipped that question and did not convert it to an owner decision at approval; re-confirm before /aid-specify commits to it. |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-25 | Work created | -- | Initial scaffold by aid-describe (FIRST-RUN); worktree `work-001` |
| 2026-07-26 | Detail -- 53 tasks written (A+) | A+ | 53 tasks across the 5 deliveries (D1 4, D2 14, D3 21, D4 5, D5 9), each a folder with `DETAIL.md` + `STATE.md` at `state: Pending`. Owner took both recommended splits (the Advance-clause parser and the client controller), which is why the count is 53 rather than 51. Per-delivery gates: **D2 and D5 A+ first pass**; D1 B+ → A → A+, D3 C+ → A+, D4 C+ → A+. Execution graphs written into PLAN.md with `wave-map` blocks, then reviewed clean-context: B+ → **A+**; totality verified mechanically (53 ids, each in exactly one wave, matching disk). Detail surfaced one **contract gap** the Specify reviews missed — validator rule **V9 was unevaluable** as specified — escalated and answered as work **Q3**. Also logged **KI-015**: AID's two task templates disagree on four points and one claims conformance to the other. |
| 2026-07-26 | Plan -- roadmap approved (A+) | A+ | 5 deliveries sequenced from 6 features, each gated per-deliverable then re-graded whole-plan by a clean-context reviewer. D1 Green CI-gated test suite (feature-001 §7 part) → D2 Browsable `/skills/` catalog (001 remainder + 002) → D3 Chart on every page (003 + 004) → D4 Verbatim fragments + deep links (005) → D5 Node panel (006, Should, **droppable at D4's gate**). feature-001 deliberately split across D1/D2. Nothing deferred out of plan; 7 cross-cutting risks and 8 adjacent deferred items recorded. Grades: D1 A → A+ (4 MINOR, orchestrator-authored artifacts), D2–D5 A+ first pass, whole-plan A+. |
| 2026-07-25 | Describe -- requirements approved | -- | All 10 sections Complete; 6 FRs, 4 NFRs, 8 ACs. KB hydrated (`module-map.md` rev 1.5). Paused for /aid-define. |
| 2026-07-26 | Execute -- delivery-001 gate (A+) | A+ | **Green, CI-gated site test suite shipped.** `npm test` in `site/` exits 0 for the whole suite (8 files, **305** tests) and `docs.yml` runs it on every pull request between `npm ci` and `npm run build`. **218 of those tests live in the five TypeScript suites that had never executed anywhere** -- not locally, not in CI, not once. **KI-005 and KI-006 closed.** Four tasks: 001 replaced all eight stale roster items with source-derived checks plus a drift clamp that fails **by name**; 002 triaged the whole suite on a clean `npm ci` and found exactly one genuine defect; 003 absorbed it -- an AC5 guard pinning a pipeline diagram superseded by commit `ca4aad21` -- and rebuilt it as a topological comparison against README; 004 wired CI and applied the OQ-3 answer. Gate took **7 cycles: E+ -> C -> C+ -> C+ -> B -> B+ -> A+**, 25 issue rows closed (23 Fixed, 2 Accepted). The [CRITICAL] was a scope leak -- 354 owner-added `.cursor/`/`AGENTS.md` paths swept into a task commit by a `git add -A`; the content stays (owner-confirmed) but now lands in its own commit. Six of the MEDIUM/HIGH rows were successive lexical holes in one hand-written Mermaid parser, closed as a class by rewriting it to **fail closed**. Owner decisions taken: OQ-3 **yes** (`canonical/**` on both `docs.yml` path filters, closing risk R6). Escalations E-1 (`index.mdx` prose counts stale at 92/14/76 vs a measured 111/21/64), E-2, E-3 recorded and open for the owner. |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. Future work
     may migrate this to a per-delivery hierarchy view, but until then it is AUTHORED here.
     One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     Dashboard readers union the child contributions; no agent writes to these sections.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress.
     Never written here; feature progress is tracked via /aid-specify per-feature.
     One row per feature. Tracks /aid-specify progress per feature. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-skill-detail-pages | **Ready** | **A+** | 1 | Wave 1 ✅. Owns the generator-harness contract consumed by 002-006. Grades C+ → A → **A+** over 3 review rounds, ledger clean. Owner expanded scope: correct the stale `gen-reference.test.mjs` assertions (8 items, all re-derived from source — no new literals) **and** add `npm test` to `docs.yml` (§7 amended). |
| 2 | feature-002-grouped-skill-index | **Ready** | **A+** | 1 | Wave 2 ✅ — **A+ first pass, zero findings**. Consumes 001's page + manifest contract; `catalog.mjs` is a deliberate one-way re-implementation because `gen-reference.mjs` calls `main()` at module scope (:707), so importing it would regenerate all four reference pages. Card = markdown list item, not Starlight `LinkCard` (70/111 descriptions carry code spans, 15 carry `"`, 3 carry a pipe). OQ-1 open but non-blocking: `aid-query-kb`/`aid-ask` stay in KB Maintenance. |
| 3 | feature-003-authored-flow-charts | **Ready** | **A+** | 1 | Wave 1 ✅. Owns the flow-graph model + substrate decision consumed by 004-006: runtime `astro-mermaid` (D18/"D-012" pre-render rejected — no Mermaid→SVG compiler exists in-repo). C → B+ → A+, then **reopened** by owner decision for **KI-008** (advance parser dropped the `X (optional) then Y` edge in 5 skills, silently). Amendment closed the class: 139 advance blocks swept, 4 more separator forms found, advances proven to be **blocks not lines** (19 wrap; one hides a whole clause), validator rule **V9** added as an anti-silence guard. Re-gate B → **A+**, 8 rows Fixed. |
| 4 | feature-004-doorway-engine-charts | **Ready** | **A+** | 1 | Wave 2 ✅. Kind-sibling hop **inlines the parent's chart spliced whole**, no feature-004 rule applied to the segment. Engine derived once into a deep-frozen `EngineCore`, cloned per page; offset is always 1 node, giving a byte-identity AC-6 guard stronger than a two-run diff. Found **KI-008** in 003's closed spec. A → **A+**. |
| 5 | feature-005-verbatim-source-provenance | **Ready** | **A+** | 3 | Wave 2 ✅. Verbatim fragments in dynamically sized **tilde fences** with `title=` set — which disarms Expressive Code's file-name-comment line deletion that would otherwise silently delete 4 corpus lines. Deep links reuse the existing `BLOB` constant pinned to `master`; range/excerpt mismatch **throws**. A → **A+**, and it converted every cross-SPEC citation to **stable anchors** after line-pin drift cost two review rounds. |
| 6 | feature-006-interactive-node-panel | **Ready** | **A+** | 4 | Wave 3 ✅. Route-gated Starlight `Head` override + `public/` vanilla-ESM controller over a build-time JSON projection of 003's sidecar; gate is a `generatedFrom` data test, not a path test. Disclosure pattern, **no focus trap** (deliberate — trapping would break comparison against 005's list). Readiness predicate is three-part because mermaid sets `data-processed` on **failed** renders too (KI-011). Takes one new devDependency (`jsdom`); rejects Playwright as an automated gate. B+ → **A+**. Registered KI-011..KI-014. Priority Should. |

<!-- NOTE: this section's header comment marks it DERIVED, but `/aid-specify`'s
     `state-initialize.md` Step 3 instructs the skill to write the feature's row here directly,
     and the tracking-discipline rule requires state to be written the instant it changes. The
     skill's explicit instruction is followed; rows are written by /aid-specify (this run) using
     the column set already present in this file rather than the skill's differing column list. -->

**Wave plan (owner-chosen):** `{001, 003}` → `{002, 004, 005}` → `{006}`, parallel within each
wave, each feature gated by an independent `aid-reviewer` pass that must reach **A+**.

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields.
     Never written here; the delivery-level STATE.md is the authoritative source.
     One row per delivery from PLAN.md. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     The state reader unions all delivery branches using the ordering (most-advanced wins).
     One row per task from PLAN.md execution graph.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section.
     The per-delivery gate block is the authoritative source (single writer per delivery branch).
     Never written here. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Q1

- **Category:** Requirements / Index design (FR-5 taxonomy)
- **Impact:** Required — blocks `/aid-specify` for feature-002
- **Status:** Answered (2026-07-25, work owner)
- **Answer:** `aid-triage` is a **Support** skill. The full path is exactly five skills —
  `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail` — which open `Definition`
  un-subdivided, with no verb family. `aid-deploy` and `aid-monitor` **used to** be main-path but
  are now ordinary shortcut skills like the others, so they sit under their own `deploy` /
  `monitor` verb families, not in the full-path block. Recorded in FR-5, AC-8, and
  feature-002's SPEC; `gen-reference.mjs`'s `SKILL_GROUPS` is stale on all three points and is
  **not** changed by this work (§7), so `reference/skills.md` will differ until separately fixed.
- **Context:** FR-5 subdivides the `Definition` group by the shortcut catalog's `verb` field, and
  AC-8 fails any card "filed under a group/family that disagrees with the catalog". But the
  `Definition` group also contains **eight curated skills with no catalog row at all** —
  `aid-triage`, `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail` (no catalog
  entry) and `aid-deploy`, `aid-monitor` (present only as `repurpose: true` rows). AC-8's failure
  condition is undefined for a skill absent from the catalog, so their placement is
  unspecified. Surfaced by /aid-define (cross-reference), [MEDIUM] #2.
- **Suggested:** Follow the existing `gen-reference.mjs` precedent — its `SKILL_GROUPS` lists the
  eight curated `Definition` skills first, then nests the shortcut families after `aid-detail`
  via `shortcutsAfter`. Mirror that: an un-subdivided block of the eight at the top of
  `Definition`, then the verb-family subsections, with AC-8's catalog check applying only to
  catalog-keyed cards.

### Q3

- **Category:** Specify / Contract gap in feature-003 (validator rule V9)
- **Impact:** Required — sets the task boundary between `advance.mjs` and `validate.mjs`
- **Status:** Answered (2026-07-26, work owner)
- **Context:** Surfaced by /aid-detail while slicing delivery-003. feature-003 declares
  `validateChart(chart) → {ok, errors}` as a pure function over a `FlowChart`, and rule **V9**
  fires on "residual text referencing a declared state". But `FlowChart` carries only `nodes`,
  `edges`, `entries`, `exits`, `sources` and `warnings` — **no field holds a residue**. The
  residue is leftover *source text* that exists only during parsing (rule 10 computes it), so a
  validator handed the finished chart cannot distinguish "this state was never mentioned" from
  "this state was mentioned and its edge was dropped" — which is exactly the KI-008 failure V9
  exists to catch. Both A+ reviews missed it because each read one document.
- **Answer:** **Enforce V9 at extraction, in `advance.mjs`, where the residue still exists.**
  `validate.mjs` implements V1–V8 and **documents that V9 lives in the parser**. Rejected:
  adding a residue carrier to the model, because that field would flow into the
  `<skill>.flow.json` sidecar and then need explicit exclusion from feature-006's browser
  projection — widening three contracts to serve one rule.
- **Applied to:** delivery-003's BLUEPRINT (recorded as the **fifth** seam reconciliation),
  task-019 (which records all five contract decisions), task-022/task-023 (V9 enforced in the
  parser split) and task-024 (validator implements V1–V8 and documents V9's location).
  feature-003's SPEC text should be corrected to match when it is next opened.

### Q2

- **Category:** Requirements / Feature scope contracts (FR-6)
- **Impact:** High — constrains features 004, 005, 006 before they reach `/aid-specify`
- **Status:** Answered (2026-07-25, work owner)
- **Answer:** **FR-6 confirmed as written** — the full engine chart renders inline on each
  doorway page, bound to that doorway's `{verb, artifact}`. It is now an owner decision, not an
  interviewer default. Features 005 and 006 therefore keep their "every node in every chart"
  scope with no revision; feature-004 is specifiable without a pending decision. Propagated to
  FR-6 and the SPECs for features 004, 005, and 006.
- **Context:** FR-6 is an interviewer default; the owner skipped the question during
  `/aid-describe` and did not convert it at approval. Cross-reference found feature-004's
  "isolation" claim overstated: the single-box alternative is contained, but the stub-page
  alternative leaves doorway pages with no chart nodes, so AC-5 (feature-005) has nothing to
  attach to and feature-006's node interaction has no target. Both SPECs now carry explicit
  FR-6-dependency notes. Surfaced by /aid-define (cross-reference), [MEDIUM] #3.
- **Suggested:** Confirm FR-6 as written (full engine chart inline on every doorway page), which
  keeps features 005 and 006 scoped to "every node in every chart" and needs no revision. If
  instead reversed to stub pages, re-scope 005 and 006 to authored-flow charts only and decide
  AC-5's reach for doorway pages at the same time.

### Q4 — the two skill sections should be unified, in a new delivery after delivery-005

*(Work-level Q4. Distinct from delivery-002's own Q4, which asked the narrower question —
"should `/reference/skills/<name>` stop 404ing?" — and is **subsumed by this answer**.)*

- **Category:** Scope / Site information architecture; amends **§7**
- **Impact:** High — adds a delivery, and reopens a constraint this work froze
- **Status:** **Answered (2026-07-27, work owner)**
- **What was asked:** the owner reframed delivery-002's Q4. The presenting symptom was a 404 at
  `/reference/skills/aid-config`, but the underlying question is that **the site has two sections
  about skills** — `/skills/` and `/reference/skills/` — with different navigation, different
  content, and different presentation. Should they be unified?
- **Answer: yes, both halves, as a NEW DELIVERY sequenced after delivery-005.** Not a
  delivery-003 ride-along and not folded into delivery-004 — it is its own unit of work, planned
  and gated on its own, because the second half amends a constraint rather than implementing one.
- **Why unification is the right call, evidenced rather than asserted.** The two pages are not
  complementary views of different things; they are the **same roster**, under the **same four
  groups**, one derived and one hand-maintained:
  - `/reference/skills/` names the 21 curated skills with a description and a source link, then
    collapses the 64 shortcuts into a family summary table.
  - `/skills/` gives all 111 skills a card and a detail page, derived from `canonical/`, with
    `Definition` subdivided into 17 verb families.
  - The reference copy is **provably wrong in three already-catalogued ways**, none fixable while
    §7 holds: **KI-003** (header claims 94 directories / 16 classic / 76 shortcuts against a real
    111 / 19 / 64); **KI-009** (six family rows render a count of `0` while listing forms that
    exist; `Test + Experiment` renders "3 typed forms … **= 0**" and `Document` renders "**-1**
    typed forms"; the `Show dashboard` family matches a verb that does not exist — and the drift
    guard cannot catch any of it, because it only checks that the counts *sum*); **KI-010** (three
    skills in the wrong group per FR-5).
- **What must NOT be lost.** The **shortcut-engine narrative** — `INTAKE → CAPTURE → SPEC → PLAN →
  DETAIL → GATE → APPROVAL-HALT` and its surrounding explanation — exists **only** on
  `reference/skills.md` and appears nowhere on `/skills/` (verified: zero occurrences of
  `APPROVAL-HALT`, `INTAKE` or `shortcut-engine` in `skills/index.md`). So the page is **hollowed
  out, not deleted**: it keeps the narrative and sheds the duplicated roster.
- **The two halves, and why only one touches the freeze:**
  1. **Repoint the inbound links, and correct the stale roster prose — needs no §7 change.** Every
     link routing readers to the worse page is in a **hand-authored** file: seven in
     `guides/pipeline.mdx` and one in `reference/overview.md`, whose own sentence is stale in the
     same way ("All 92 AID skills … 76 verb-first shortcut skills"). Established by checking each
     reference page for its generated marker: `skills.md`, `agents.md`, `kb.md`, `settings.md` and
     `glossary.md` are generated; `overview.md`, `index.md`, `artifacts.md`,
     `repository-structure.md` and `guides/pipeline.mdx` are hand-authored and editable today.
     - **Extended 2026-07-27 to absorb delivery-001's escalation E-1** (owner decision, same
       sitting). `site/src/content/docs/index.mdx`:76-77 and :91-92 carry the **identical** claim —
       "92 skills — 14 classic … 76 verb-first shortcut skills" — against a measured **111 / 21 /
       64**. E-1 was raised at the delivery-001 gate and had stayed open because no task's Scope
       covered a content page. It is the same defect, in the same class of file, as
       `overview.md`'s line 16, so it is corrected in the same pass rather than as its own ticket.
     - **Consequence until this delivery lands:** the home page promises 92 skills while `/skills/`
       ships 111 cards. Known, dated and owned — not a discovery for a later reader.
     - **Derive the triple once.** The three quantities are one derived fact (directories under
       `canonical/skills/`, curated entries, emitting catalog rows), and **KI-003** reports the same
       triple stale in `gen-reference.mjs`'s header. Correcting each site by hand against a
       hand-counted number is how the KI-005 class gets reintroduced; derive it once and correct
       every site against that derivation.
  2. **Hollow out `reference/skills.md` — amends §7.** §7 currently reads "`gen-reference.mjs`
     itself is frozen by this work" and "the existing `site/` build and its four generated
     reference pages must keep working unchanged". Precedent exists: **§7 was already amended once
     by owner decision at the Specify review**, when its original "vitest suites must keep passing
     unchanged" wording proved unsatisfiable. This is the second amendment, and unlike the first
     it is a deliberate scope addition rather than a correction.
- **Sequencing and why it is not urgent.** Nothing in deliveries 003–005 depends on it, and it
  touches no file they touch — the chart and panel work lives under `site/scripts/` and
  `site/src/data/`, while this is content and one frozen generator. Deferring it costs nothing;
  doing it earlier would put a third editor on `astro.config.mjs` mid-flight (risk R1).
- **Interim disposition of delivery-002's Q4:** **option 1 — accept.** Its premise is now measured
  rather than predicted: Pagefind indexes all 111 detail pages (13 fragments mention `aid-config`),
  and the sidebar `Skills` group shipped in task-016. `/reference/skills/` remains a leaf with only
  an `index.html`, so child routes still 404 until half 1 lands.
- **Still to do:** this delivery is **not yet planned**. `PLAN.md` is an `aid-plan` artifact and is
  not edited here; the new delivery needs its own BLUEPRINT and task breakdown before execution.

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
