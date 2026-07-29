---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-28"
minimum_grade: "A+"
user_approved: yes
lifecycle: Paused-Awaiting-Input
phase: Detail
active_skill: none
updated: '2026-07-29T00:11:00Z'
pause_reason: '96 tasks detailed and gated at A+ - run /aid-execute work-005-knowledge-graph to begin delivery-001'
block_reason: --
block_artifact: --
ticket_ref: --
---

# Work State -- work-005-knowledge-graph

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into three zones:
  FRONTMATTER (single-writer, machine-parsed scalars) -- the YAML block above: pipeline
    identity, work-level lifecycle/phase/approval scalars, and (for flattened single-delivery
    works only) the delivery lifecycle/gate scalars. Written ONLY by `writeback-state.sh`
    (surgical YAML-block rewrite; the markdown body is never touched by that write).
  AUTHORED (single-writer, markdown body) -- Interview State, Lifecycle History,
    Deploy State, the narrative remainder of Delivery Lifecycle (incl. its Tasks lifecycle
    subsection) and Delivery Gate (Updated/Block Reason/Block Artifact/Issue List -- the
    values that don't fit a flat frontmatter scalar).
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.
Inferred values (`number` from the folder name, `branch` from the git worktree,
`title`/`description`/`objective` from REQUIREMENTS/SPEC content files) and derived values
(counts, readiness/execution %, `source_mode`) are NEVER authored here -- computed at read time.

The AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` sections
(singular) apply ONLY to single-delivery flattened works (no `deliveries/`/`delivery-NNN/`
wrapper -- see each section's own note). They are promoted verbatim from
`delivery-state-template.md` / `task-state-template.md` and are distinct from the plural DERIVED
`## Delivery Gates` / `## Plan / Deliveries` / `## Tasks State` union views below -- no heading
collision (singular vs. plural, and `### Tasks lifecycle` differs in both text and heading level
from `## Tasks State`). Left unused for full multi-delivery works, where each delivery's own
lifecycle/gate lives in its `delivery-NNN/STATE.md` and each task's own state lives in its
`delivery-NNN/tasks/task-NNN/STATE.md` instead.

Optional `ticket_ref` scalar (frontmatter, top-level, both layouts): links this work to an
external tracker item (`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`). Left `--` when
this work is not linked; readers/dashboard ignore it. Nearest-ancestor resolution + MCP-first
consumption contract: `.claude/aid/templates/connectors/consumption-protocol.md`. Coordinate
with the in-flight `work-003-state-schema` frontmatter conventions when both touch this file's
frontmatter block. `ticket_ref` is a lifecycle-unit field only -- the connector descriptor schema
is unchanged.

<!-- STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

Ordered from most-advanced to least-advanced:
  1. Done           -- task completed and accepted; all subtasks resolved
  2. Canceled       -- resolved terminal (explicitly abandoned); ranks just below Done
  3. In Review      -- work submitted; awaiting reviewer decision
  4. In Progress    -- actively being executed on its delivery branch
  5. Blocked        -- attempted but impeded; recoverable-in-place; more actionable than Failed
  6. Failed         -- completed attempt rejected; a parallel branch may have superseded
  7. Pending        -- not yet started

Rationale: the dashboard "most-advanced wins" reconcile answers "how far has this work
gotten across all worktree branches." Done/Canceled are terminal-resolved and rank highest.
In Review outranks In Progress (review is a later pipeline stage). Blocked outranks Failed
because a blocked task is recoverable-in-place and signals "needs attention now," whereas a
failed task represents a completed-but-rejected attempt that a parallel branch may have already
superseded -- surfacing "blocked" is the more actionable signal. Both Blocked and Failed rank
above Pending because they represent work that was attempted and surfaced information (more
informative than "not started").

Closed enum VALUES (unchanged): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

This ordering is encoded ONCE here. Both reader twins (Python + Node) reference schemas.md for
the ordered list at runtime; schemas.md carries an inline copy derived from this source.
-->

> **State:** Describing | Defining | Specifying | Planning | Detailing | Executing
> **Phase:** Describe | Define | Specify | Plan | Detail | Execute

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/works/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task DETAIL.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

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

**Interview State:** Approved  **Grade:** A+

### Cross-Reference

**State:** Complete  **Grade:** A+  **Date:** 2026-07-28

Validated REQUIREMENTS.md and the 11 feature SPEC scaffolds against 19 KB documents and the
live codebase. Contradictions: 0. Gaps: 0. Unverified claims: 0. Feature-alignment issues: 0.
Two MINOR documentation findings were raised: one fixed (stale `(draft)` labels on FR-1..FR-3),
one disproved as Invalid (C-5's Node >= 20 floor is declared by the validator tooling's own
`package.json`, not inferred from the CI pin). Disproving it surfaced one OOS finding routed
upstream: `/aid-summarize`'s preflight asserts Node >= 18 while its validators require >= 20.
Ledger: `.aid/.temp/review-pending/interview-work-005-knowledge-graph-cross-ref.md`.

### Review History

| Date | Reviewer | Outcome | Notes |
|------|----------|---------|-------|
| 2026-07-28 | User (owner) | Approved | Whole-picture read-back confirmed at COMPLETION Step 4. Identity header confirmed. Three items parked as Q1–Q3 for /aid-specify. |
| 2026-07-28 | aid-architect | — | Feature Decomposition — 11 features created |
| 2026-07-28 | aid-reviewer (Large) | A+ | Cross-Reference — 0 contradictions/gaps/unverified/alignment issues; 1 MINOR fixed, 1 MINOR invalid, 1 OOS routed upstream; Q4 raised |

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Partial | 2026-07-28 |
| 2 | Problem Statement | Complete | 2026-07-28 |
| 3 | Users & Stakeholders | Complete | 2026-07-28 |
| 4 | Scope | Complete | 2026-07-28 |
| 5 | Functional Requirements | Complete | 2026-07-28 |
| 6 | Non-Functional Requirements | Complete | 2026-07-28 |
| 7 | Constraints | Complete | 2026-07-28 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-28 |
| 9 | Acceptance Criteria | Complete | 2026-07-28 |
| 10 | Priority | Complete | 2026-07-28 |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-28 | Work created | -- | Initial scaffold by /aid-describe |
| 2026-07-28 | Describe → approved | A+ | REQUIREMENTS.md approved after whole-picture read-back; cross-reference validated at A+ |
| 2026-07-28 | Define → 11 features | A+ | Decomposed into 11 features; 0 contradictions/gaps/unverified claims/alignment issues |
| 2026-07-28 | Specify → specs written | -- | Technical specifications authored for all 11 features by 4 parallel aid-architect agents |
| 2026-07-28 | Specify gate (batch A: features 001–005) | **E+** | FAILED A+ gate. 1 CRITICAL (vocabulary file/format contradiction across 001/003/005), 1 MEDIUM, 1 LOW. Features 004, 005 clean. Fix dispatched. |
| 2026-07-28 | Specify gate (batch B: features 006–011) | **E+** | FAILED A+ gate. 1 CRITICAL (AC-15 coverage-predicate mechanism contradiction between 006 and 007), 3 HIGH, 1 MEDIUM. Features 008, 009 clean. Fix dispatched. |
| 2026-07-28 | Specify FIX — both CRITICALs resolved | -- | Vocabulary unified to one seven-key YAML file with ownership corrected to feature-001; coverage predicate unified into one shared ESM module (`coverage-predicate.mjs`) executed in both runtimes, `kb_gaps` demoted to a verified record. All 4 HIGHs and both lower findings fixed. |
| 2026-07-28 | Specify FIX — design hole closed | -- | Zero-row `int:` nodes (a source artifact with no relationships — the worst-case gap FR-19 exists to catch) were invisible to both lens and ledger; now emit an ordinary ledger row and materialise in both renderings. feature-009 gained a dedicated region since its table is one row per edge. |
| 2026-07-28 | Pre-existing defect fixes (owner-directed, off-scope) | -- | Three verified repo defects fixed in `canonical/` with clean re-render (1765 files, deterministic VERIFY pass, dogfood byte-identity 711/711): summarize preflight Node floor 18→20; `grade-summary.sh` now scores `NM` (max 68→70); `gen-reference.test.mjs` re-anchored to derived set comparisons (its 94 **and** 76 literals were both wrong). `technology-stack.md` updated to four Node contexts. |
| 2026-07-28 | feature-011 split three ways (owner decision) | -- | `feature-011-validator-parameterisation` (renamed, retitled) + new `feature-012-canonical-registration` + new `feature-013-tests-and-docs`. 14 cross-references repointed across features 001, 002, 008. Feature count 11 → 13. |
| 2026-07-28 | Specify final gate (batch A: features 001–006) | C+ → **A+** | First pass C+ (1 MEDIUM, 2 LOW), all three in feature-003 and all one root cause: it still carried "residual mismatch" notes about feature-001 that had been fixed, one of which was never true. Features 001, 002, 004, 005, 006 clean first pass. Fixed and regraded to A+ (0 findings). |
| 2026-07-28 | Specify final gate (batch B: features 007–013) | B+ → **A+** | First pass B+ (1 LOW, 2 MINOR; zero CRITICAL/HIGH/MEDIUM). Features 008, 009, 010, 013 clean; 012 and 013 reviewed for the first time including their fresh requirements halves. Fixed a stale title string, an incomplete `render.py` skills-branch description (in two specs), and a missing test-suite filename. Regraded to A+ (0 findings). |
| 2026-07-28 | **Specify phase complete** | **A+** | All 13 feature specifications gated at A+ with zero findings. All 8 post-fix resolutions independently confirmed by both reviewers. Ready for /aid-plan. |
| 2026-07-28 | Plan → 6 deliveries sequenced | -- | PLAN.md written with 6 deliveries; all 13 features and all 18 acceptance criteria assigned exactly once (independently verified); 7 cross-cutting risks, all substantiated. Delivery folders created with BLUEPRINT + STATE at `Pending-Spec`. Flattened-single-delivery-only sections removed from this file, per the template, now that the work is confirmed multi-delivery. |
| 2026-07-28 | Plan gate (per-deliverable, all 6) | B+ → **A+** | First pass B+ (1 LOW, 2 MINOR); deliveries 001, 002, 004, 005 clean. Fixed: delivery-003's gate omitted the `GL10`/`GL11` ledger-lifecycle sentinels; the `io_bounds.py` L4 quotation was softened to "stale" in three files when the KB records a missing security-relevant file; delivery-006's Must-after-Should inversion lacked a recorded deviation. Regraded A+ (0 findings). |
| 2026-07-28 | **Plan phase complete** | **A+** | Dependency graph verified acyclic with no understated edges; every gate identifier cited (`V1`–`V12`, `R1`–`R5`, `GL01`–`GL13`, `GV01`–`GV08`) verified present in its SPEC. Ready for /aid-detail. |
| 2026-07-28 | Detail → 96 tasks written | -- | Owner reviewed a merge-to-89 option and kept 96: 5/39/11/22/12/7 across the six deliveries. By type: 48 IMPLEMENT, 30 TEST, 8 DOCUMENT, 6 RESEARCH, 6 CONFIGURE, 2 DESIGN, 0 MIGRATE, 0 REFACTOR. Written by 5 parallel writers from one shared brief; 192 files. Execution graphs + `wave-map` blocks derived **mechanically** by script and appended to PLAN.md. |
| 2026-07-28 | Detail — orchestrator corrections during writing | -- | 15 corrections applied. Nine dependency edges wrong in the proposed table (eight missing, one spurious — task 013 was gating task 017 and putting the Q6 decision on the critical path of the whole enumeration spine). Three identifiers had no name in any SPEC yet were needed by 2+ tasks (`coverage-bearing.yml`, `edge-relation-map.sh`, `graph-live-surface`). The state machine needed an Advance re-point chain across three deliveries, unspecified because feature-010's table describes only the final shape — which also corrected the final count to **eleven** states. |
| 2026-07-28 | Detail gate (per-deliverable, all 6) | D → **A+** | First pass D (2 HIGH, 3 MEDIUM, 1 LOW); deliveries 005 and 006 clean. **Both HIGHs shared one root cause: the orchestrator edited task Scope without editing the Acceptance Criteria in the same file**, so tasks 051 and 067 each instructed an executor to undo the correction directly above. Also fixed: tasks 021/022 not naming the loader they must source, an unresolvable `ext:` key forward-reference between tasks 002 and 035, and 19 state files using quoted dashes. Regraded A+ (0 findings). |
| 2026-07-28 | **Detail phase complete** | **A+** | 96 tasks, all typed single-type, all traced to a feature and delivery. Graph independently verified acyclic; all six `wave-map` blocks total (96 tasks mapped exactly once). Ready for /aid-execute. |

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
<!-- FLATTENED-ONLY SECTIONS OMITTED (2026-07-28, /aid-plan): this is a FULL multi-delivery work
     with six deliveries, so the singular `## Delivery Lifecycle` / `### Tasks lifecycle` /
     `## Delivery Gate` sections do not apply and are absent by the work-state template's own
     instruction. Each delivery's lifecycle and gate live in its own
     `deliveries/delivery-NNN/STATE.md`, unioned by the DERIVED `## Plan / Deliveries` and
     `## Delivery Gates` views below. The matching frontmatter scalars (delivery_state,
     gate_tier, gate_grade, gate_timestamp) were likewise omitted at scaffold time. -->


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
| _none yet_ | | | | | |

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

- **Category:** Requirements
- **Impact:** Low
- **Status:** Resolved 2026-07-28 — **`Strength` dropped.** `Provenance` carries trust and layout
  hops convey distance, so a per-row number would duplicate the picture while being unreproducible.
  The table is eight columns. Recorded at REQUIREMENTS.md §5.2.
- **Original status:** Deferred
- **Context:** The `relationships.md` schema keeps a `Strength` column as TBD. `Provenance`
  (`declared`/`derived`/`inferred`) was adopted to carry trust, which was `Strength`'s main
  candidate meaning; what remains for `Strength` is an optional confidence or distance measure.
  Owner chose to retain the column as a possibility rather than settle or drop it now. Raised
  during /aid-describe work-005 interview.
- **Suggested:** Decide at /aid-specify: either an optional numeric weight used only for graph
  layout tuning, or drop the column. Graph distance is already conveyed by layout hops, so the
  bar for keeping it is a use the layout cannot express.

### Q2

- **Category:** Architecture
- **Impact:** High
- **Status:** Deferred to RESEARCH — **scope widened 2026-07-28.** The owner dropped all three
  packaging restrictions (FR-16 rewritten, C-1 withdrawn), so the option space is no longer bounded
  by self-containment: multi-file output, CDN delivery, and a real build step with third-party
  dependencies are all admissible, at any payload size. SVG, Canvas, and WebGL renderers are all in
  scope. The research optimises for interaction quality and legibility, not packaging purity.
- **Context:** The rendering approach is undecided. It was originally bounded by a single-file
  self-containment constraint; that constraint is withdrawn. The remaining tension is that
  hand-rolling a force-directed layout with stable grouping and sane density is a
  physics-simulation tuning problem and a classic time sink, while adopting third-party code
  creates licence, attribution, and update obligations — and a CDN or build-step dependency either
  makes the artifact non-portable or adds a generate-time toolchain to a repo whose CLI is
  currently pure Bash/Node-stdlib. Raised during /aid-describe work-005; widened during
  /aid-specify.
- **Suggested:** Resolve in the same RESEARCH wave as the relation-vocabulary research (FR-5).
  Deliverable: a recommendation covering interaction quality, legibility at this project's node
  counts, accessibility support, packaging/payload cost, licence and attribution obligations, an
  update story, and the `technology-stack.md` / `infrastructure.md` entries any adoption requires.

### Q3

- **Category:** Architecture
- **Impact:** Medium
- **Status:** Resolved 2026-07-28 — **KB-indexed.** `relationships.md` carries valid KB frontmatter
  and is indexed like any other generated KB document; C-7 and AC-18 hold as written, and
  feature-003 needs no rework. Recorded at REQUIREMENTS.md FR-9 and C-7.
- **Original status:** Pending
- **Context:** FR-9 places `relationships.md` in `.aid/knowledge/`, but the KB index generator emits
  one entry per non-dot KB document in that folder — so the file would be indexed and would need
  valid KB frontmatter (`kb-category`, `objective`, `summary`, `tags`). Surfaced by the COMPLETION
  quality check during /aid-describe work-005.
- **Suggested:** Give `relationships.md` proper KB frontmatter and let it be indexed as a generated
  KB document (consistent with `INDEX.md` itself being generated), rather than hiding it from the
  generator. Decide at /aid-specify.
- **Note:** `feature-003`'s SPEC warns that this must be resolved **before that SPEC is graded**,
  or the SPEC needs rework. Resolve it as the first action when `/aid-specify` opens feature-003.

### Q8

- **Category:** Process
- **Impact:** High
- **Status:** Pending
- **Context:** The reviewer-ledger lifecycle **deletes ledgers at a skill's DONE state**, but FR-26
  makes the ledger `/aid-graph`'s *deliverable* — the gap findings are the product, not scratch
  review state. Under the current lifecycle the skill would emit its findings and then destroy them.
  This is not hypothetical: during this same work, `/aid-define`'s DONE state deleted the
  cross-reference ledger as designed, leaving the A+ evidence trail only in STATE.md's summary.
  feature-006's spec specifies a named retention carve-out written into the shared ledger schema
  rather than as local skill behaviour. Surfaced by /aid-specify work-005 (skill features).
- **Suggested:** Amend the shared ledger schema to distinguish **transient review state** (deleted
  at DONE, the current behaviour) from a **delivered findings ledger** (retained). This is a
  methodology-level change beyond work-005's scope, so it likely wants its own work — but
  feature-006 cannot satisfy FR-26 until it lands.

### Q6

- **Category:** Configuration
- **Impact:** Medium
- **Status:** Pending
- **Context:** FR-22 assumes an ignore list in `.aid/settings.yml`, but **no such setting exists** —
  neither the live file nor its template declares one. feature-004's spec introduces `graph.ignore`
  read via the existing settings reader. The live file declares `format_version: 3`, so adding a new
  top-level section raises two questions the spec cannot answer alone: whether it requires a
  `format_version` bump, and what reconcile rule applies to installs that predate it. Surfaced by
  /aid-specify work-005 (data features).
- **Suggested:** Decide at /aid-detail or /aid-plan, since it is a settings-schema change with a
  migration dimension rather than a graph concern. If a bump is required, it should be sequenced
  ahead of feature-004's implementation.

### Q7

- **Category:** Integration
- **Impact:** Medium
- **Status:** Pending
- **Context:** `ext:<key>` resolution depends on the KB's external-sources file, but that file has
  **no machine-readable entry format** — and `/aid-graph` cannot define one by authoring it, because
  FR-10 makes the skill read-only with respect to KB content and `/aid-discover` ELICIT owns that
  file. Q4's synthetic fixture covers *testing* the `ext:` branch, but real-world resolution against
  a populated file still needs an agreed entry shape upstream. Surfaced by /aid-specify work-005
  (data features).
- **Suggested:** Define the entry format as an upstream change to `/aid-discover`'s external-sources
  authoring, then have feature-003's resolver bind to it. Until then the `ext:` resolver is
  specified against the fixture's shape, which risks divergence if the upstream format differs.

### Q5

- **Category:** Architecture
- **Impact:** Medium
- **Status:** Pending
- **Context:** `graph.html` cannot be reached through the AID dashboard as it stands. The
  dashboard's leaf allowlist admits only `home.html` and `kb.html`, and its Content-Security-Policy
  is `default-src 'self'` — which also means a CDN-fetching graph would be blocked there even if the
  route existed. feature-007's spec therefore scopes the entry point to opening the file locally and
  treats adding a dashboard route as out of scope. Surfaced by /aid-specify work-005 (view features).
- **Suggested:** Decide whether the graph should be reachable from the dashboard. If yes, it is a
  separate change to the dashboard's allowlist and CSP, and it constrains FR-16's packaging freedom
  in practice (a CDN-fetching artifact would violate the existing CSP). If no, record the local-file
  entry point as the intended access path so the limitation is deliberate rather than incidental.

### Q4

- **Category:** Testing
- **Impact:** Low
- **Status:** Resolved 2026-07-28 — **synthetic fixture.** The `ext:` branch of AC-1 is validated
  against a self-built test fixture supplying a controlled external-sources file with both
  resolvable and deliberately unresolvable keys, so the check is proven to fire rather than passing
  vacuously. Recorded at REQUIREMENTS.md AC-1 and A-6.
- **Original status:** Pending
- **Context:** `.aid/knowledge/external-sources.md` exists but has **zero entries registered** for
  this project — AID recorded no external sources during discovery. The `ext:` relationship source
  (§5.1 item 3) therefore cannot be exercised when dogfooding `/aid-graph` against AID itself, and
  AC-1's `ext:` branch is vacuously satisfied. Surfaced by /aid-define cross-reference (work-005).
- **Suggested:** Decide at /aid-specify: either register one or more representative external
  sources in `external-sources.md` before acceptance testing, or explicitly document that AC-1's
  `ext:` branch is validated against a different target project. Do not leave it implicit.

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
