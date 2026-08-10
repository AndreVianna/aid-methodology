---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-08-08"
minimum_grade: "A"
user_approved: yes
lifecycle: Running
phase: Detail
active_skill: none
updated: '2026-08-10T19:05:00Z'
pause_reason: --
block_reason: --
block_artifact: --
---

# Work State -- work-006-design-phase-skills

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

**State:** Complete  **Date:** 2026-08-09  **Grade:** A+ (initial pass D — 4 HIGH, 6 MEDIUM, 6 LOW, 1 MINOR; all resolved)
**Ledger:** deleted at DONE (all 18 rows closed: 16 Fixed, 1 Accepted, 1 OOS)

### Review History

| Date | Reviewer | Outcome | Notes |
|------|----------|---------|-------|
| 2026-08-08 | user | Approved | Whole-picture read-back accepted; 4 re-confirmable assumptions surfaced and accepted |
| 2026-08-09 | aid-architect | Feature Decomposition | 10 features proposed; simplified to 6 and approved by user |
| 2026-08-09 | aid-reviewer | Cross-Reference: D → A+ | 18 rows; 4 HIGH all confirmed against disk. Q1/Q2 answered by owner; FR-9, FR-10, AC-10, AC-11 added; FR-5's uniformity claim corrected |

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-08-08 |
| 2 | Problem Statement | Complete | 2026-08-08 |
| 3 | Users & Stakeholders | Complete | 2026-08-08 |
| 4 | Scope | Complete | 2026-08-08 |
| 5 | Functional Requirements | Complete | 2026-08-08 |
| 6 | Non-Functional Requirements | Complete | 2026-08-08 |
| 7 | Constraints | Complete | 2026-08-08 |
| 8 | Assumptions & Dependencies | Complete | 2026-08-08 |
| 9 | Acceptance Criteria | Complete | 2026-08-08 |
| 10 | Priority | Complete | 2026-08-08 |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-08-08 | Work created | -- | Initial scaffold by aid-describe (FIRST-RUN) |
| 2026-08-08 | Describe — requirements approved | -- | All 10 sections Complete; user approved at COMPLETION |
| 2026-08-09 | Define — feature decomposition | -- | 6 features created; simplified from a 10-feature proposal |
| 2026-08-09 | Define — cross-reference complete | A+ | 18 findings resolved; FR-9/FR-10/AC-10/AC-11 added. Ready for /aid-specify |
| 2026-08-09 | Specify — all 6 feature specs Ready | -- | 126 review findings closed across the gate round (18/17/21/26/21/23; 1 rejected Invalid on refuted evidence). Requirements corrected twice: 3 self-contradictions struck, then FR-11's nine cross-feature contracts added after reviews showed the surviving CRITICAL/HIGH findings were cross-spec disagreement, not within-spec defects |
| 2026-08-09 | Plan — PLAN.md + 3 delivery folders written | -- | Grouped by skill family per owner decision; both mutual dependency pairs (001↔003, 004↔005) absorbed inside a delivery. FR-10's engine-reach figure corrected 58 → 34 generated doorways (26 firing) |
| 2026-08-09 | Plan — review close-out | A+ | 14 findings closed (13 Fixed, 1 Accepted); ledger `.aid/.temp/review-pending/plan-work-006.md` grades A+. The CRITICAL resolved by owner decision Q6: `kb.html` **is** regenerated (`/aid-summarize` re-run, delivery-003), the "unregenerable" premise having been verified false; `.aid/knowledge/tech-debt.md` W1-11 corrected. Row 14 Accepted — the self-referential "section-6 quality gates" criterion is schema-mandated by `pipeline-contracts.md` and already recorded as tech-debt W5-6 |
| 2026-08-09 | Plan → Detail | -- | `/aid-detail` opened on delivery-001; deliveries 002 and 003 remain `Pending-Spec` and gain their task sets when detailed |
| 2026-08-10 | Detail — delivery-001 task set cut | -- | 25 tasks (2 CONFIGURE, 16 DOCUMENT, 1 IMPLEMENT, 1 MIGRATE, 5 TEST) with `DETAIL.md` + `STATE.md` each; `PLAN.md § Execution Graph` gained the dependency table, the `wave-map` (24 waves, one parallel point) and the `rw-sets` block; `deliveries/delivery-001/STATE.md` advanced to `Specified` |
| 2026-08-10 | Detail — review rounds 1–8 | D → D+ → C → C+ → D+ → C+ → C → D+ | Eight rounds, ledgers `.aid/.temp/review-pending/detail.md` and `detail-001-r2`..`r8`. Rounds 1–4 fixed the executable content: the interleave carried by edges rather than numbering, the shared-render hazard cut into one renderer and one reverter, and the read/write model corrected to mixed granularity under a path-prefix meet rule. Owner decisions Q7 (backlog column mapping, derive-from-shipped) and Q8 (SPEC `find` oracles narrowed) applied; Q9 raised (two canonical templates disagree on the task `Source:` field). Rounds 5–8 were bookkeeping, and each round's enforcement apparatus became the next round's findings — closed by owner decision at round 8: **strip the enforcement layer** (see `PLAN.md § Revision History`) |
| 2026-08-10 | Detail — review round 9 | C | Ledger `detail-001-r9.md`: 4 findings (0 CRITICAL, 0 HIGH, 2 MEDIUM, 1 LOW, 1 MINOR), down from 20 after the strip. All 4 Fixed. The load-bearing one: six under-declared read sets in the `rw-sets` block made the zero-conflict result true by luck rather than by declaration — the fix added **15** read entries across 9 tasks (003, 014, 015, 018, 019, 021, 022, 024, 025), found by a two-pass sweep (literal paths, then bare script basenames resolved against disk). No new unordered pair resulted |
| 2026-08-10 | Detail — delivery-001 close-out | A+ | Ledger `detail-work-006-delivery-001-r10.md` is empty (0 findings); `grade.sh --explain` returns A+. Narrowed final round under a pre-committed stopping rule. The reviewer re-implemented all three checkers from scratch and independently confirmed: 25 tasks, acyclic, 24 waves, root task-001, leaf task-020, `rw-sets` totality, **0** unordered write/write, **0** read/write, **0** same-wave across all 300 pairs, 8 forward edges partitioned 5/3 disjoint, all 11 derived shared-resource cells recomputing identically, and every `PLAN §`/`BLUEPRINT §`/`REQUIREMENTS §` pointer resolving. Two items considered and rejected under the filing test (a stale pointer count in historical ledger evidence; a pre-existing narrative sentence no checker consumes). Surface stayed frozen at three checkers, two fenced blocks, and the dependency table |
| 2026-08-10 | Detail — delivery-002 task set cut | -- | 24 tasks, `task-026`..`task-049` (13 DOCUMENT, 2 CONFIGURE, 9 TEST), continuing delivery-001's numbering. `PLAN.md § Execution Graph` gained `### delivery-002 execution graph` (dependency table + parallel table + a second `wave-map` instance) and a second `rw-sets` block; delivery-001's table, `wave-map` and `rw-sets` are byte-unchanged. Combined graph: **45 waves**, delivery-002 occupying 25–45, entering through the single edge `026 → 020`; combined leaf moves to `task-049` while `task-020` stays delivery-001's own leaf. One parallel wave (43): tasks 044–047, all `W= --` (runs confined to `mktemp -d`). Across all 49 tasks: **0** unordered write/write, **0** read/write, **0** same-wave. Forward edges stay at 8 (delivery-002 contributes none — ids allocated in execution order); partition invariant restated over the combined table. `deliveries/delivery-002/STATE.md` advanced `Pending-Spec` → `Specified`. Authored in two passes after the first agent run was killed by a mid-stream API error at 10 of 24 `DETAIL.md` files; `PLAN.md` was untouched at that point, so recovery was purely additive and delivery-001's A+ numbers were never at risk |
| 2026-08-10 | Detail — delivery-002 review | D+ → A+ | Ledger `detail-work-006-delivery-002.md`: **one** [HIGH] and nothing else. `BLUEPRINT criterion N` citations were off by one from the BLUEPRINT's positional checkbox order from criterion 9 onward — criteria 1–8 correct, then criterion 10 (bare `/aid-design`) cited as 9 and criterion 11 (shared contract) cited as 10, leaving criterion 9 (description negative routing) verified in substance but with no ordinal pointing at it. Fixed as a **class**: all citations across both deliveries were enumerated, six retargeted, and criterion 9 given its ordinal in two places. Textual only — no dependency, wave or read/write declaration changed, so the verified 49-task / 45-wave / 0-0-0 / 8-edge numbers stand untouched. Round 2 ledger `detail-work-006-delivery-002-r2.md` is empty; `grade.sh` returns **A+**. The verifier independently re-established the 11-checkbox order and confirmed all **28** citations resolve correctly, that delivery-001's two citations are correct, and that criterion 6's content — the one criterion with no dedicated ordinal citation — is covered in substance by 11 tasks, so its absence from the ordinal set is a citation-style gap, not a coverage gap |
| 2026-08-10 | Requirements amended — AC-12 added | -- | Owner-requested scope addition: a **triggering-quality sweep over all 112 skill descriptions** (34 generated + 78 hand-authored, old and new). Added as `AC-12` with five mechanical checks plus a recorded rationale, and as an In-Scope bullet stating why it is admitted here rather than deferred. Sourced from an audit of the roster against the Agent Skills standard (agentskills.io): AID passes every strictly-required rule, but only **2** of 76 descriptions carry a trigger clause, **34** open with `Direct-entry Lite-path shortcut` boilerplate, **54** leak state-machine text, and one (`aid-update-ticket`, 1096 chars) breaches the hard 1024 cap. The 34 generated descriptions come from a single f-string in `build-shortcut-skills.py`, so they are one edit. Explicitly excluded from the amendment: `SKILL.md` **body** size (3 skills, a `references/` restructuring job), `argument-hint` → `metadata:`, and skill self-containment. Owner separately ruled that third-party **skill vetting** is the adopter's responsibility and not an AID gap |
| 2026-08-10 | Detail — delivery-003 task set cut | -- | 25 tasks, `task-050`..`task-074` (14 DOCUMENT, 6 TEST, 3 CONFIGURE, 2 IMPLEMENT). Work total **74**. Combined graph: 74 tasks, acyclic, root `task-001`, leaf `task-074`, **70 waves**, delivery-003 in 46–70, entering through the single edge `050 → 049`. Across all 74: **0** unordered write/write, **0** read/write, **0** same-wave — only 7 of 2,701 pairs are unordered at all, every one predating this delivery. Forward edges stay at 8; delivery-003 contributes none, so the 5/3 partition is byte-unchanged. Deliveries 001 and 002 verified verbatim. AC-12 structured as **one** sweep: authoring in 8 tasks (`task-051` = the single f-string covering all 34 generated doorways and sole writer of `build-shortcut-skills.py`; `task-052`–`058` = the 78 hand-authored in seven slices cut on real seams — 18 curated / 24 existing `repurpose` / 36 new), verification in `task-072` alongside criterion 11's pair matrix. Eight findings surfaced against disk rather than relitigated, four of them corrections to feature-006's SPEC: `setup.sh` does not exist (the installers are `install.sh`/`install.ps1`); two of §7's "hand-maintained" site edit sites are generated by `sync-docs.mjs`; the site commits roster-derived generated content §5's "nothing to build" did not cover; and three suites pin description literals (two using U+2192), so the sweep must **relocate** text into the body, never delete it |
| 2026-08-10 | Detail — delivery-003 review | D+ → fix applied | Ledger `detail-work-006-delivery-003.md`: 2 findings (1 HIGH, 1 MEDIUM). The HIGH inverted a diagnosis the authoring agent had filed as tech-debt against two shipped scripts. Root cause was **this PLAN's own heading shape**: `compute-block-radius.sh` and `complexity-score.sh` both scope a multi-delivery PLAN by `### delivery-NNN` then an `Execution Graph` heading — the latter requiring level **four** — which is the shape both suites test (`test-complexity-score.sh:71-85`, `test-compute-block-radius.sh:361-368`) and which `state-delivery-gate.md:105-106` documents. PLAN.md carried `### delivery-NNN execution graph` at level three instead, so `compute-block-radius.sh` saw only delivery-001 and `complexity-score.sh` captured **zero** rows for every delivery, 001 included — the second failure being undisclosed and contradicting PLAN.md's own claim that it was unaffected. Fixed by restructuring to `### delivery-NNN` + `#### Execution Graph`; verified by re-implementing both awk state machines against the file rather than running either script — 25/24/25 nodes with a 74-node union, and `parsed_rows` 25/24/25 under `complexity-score.sh`'s own two-column row regex (`:120`), which correctly ignores a parallel table's one-column row. **No shipped-script defect survives and none is recorded.** Pointer cost was 4 references. The MEDIUM was a false factual premise — that the numbered phase sequence uses U+2192 in all three carriers; `pipeline-contracts.md:450-451` uses ASCII `->` and writes *"six numbered phases"* with `Describe/Define (Phase 2a/2b)` merged, while `CLAUDE.md:74`/`AGENTS.md:74` use `→` and name seven. Fixed as a class: the sweep found the same premise recurring in **task-066**, and confirmed task-055's separate U+2192 claim about two `test-deploy-monitor-repurpose.sh` pins is true. Graph integrity re-verified after the edits: 74 dependency rows, 74 `rw-sets` lines, no trailing whitespace. Note for readers of the earlier *delivery-002 task set cut* row above: the `### delivery-NNN execution graph` heading it names was renamed by this fix and no longer exists under that text — that row is left as the dated record of what was written then |
| 2026-08-10 | Detail — delivery-003 fix verification | 2 further findings, fixed | Round 2 (`detail-work-006-delivery-003-r2.md`) confirmed rows 1–2 Fixed and independently reproduced both parser results (25/24/25, union 74; `parsed_rows` 25/24/25), including a replay against the **reconstructed pre-fix** heading shape that matched the corrected paragraph's historical claims exactly. It then filed **two findings of my own making**, both incomplete-sweep errors rather than new defects: a [HIGH] stale present-tense claim in `PLAN.md § Revision History` still asserting the withdrawn `compute-block-radius.sh` defect, contradicting the paragraph I had just rewritten twelve lines above it; and a [LOW] two surviving references to the renamed heading at `PLAN.md:573` and `deliveries/delivery-003/BLUEPRINT.md:132`. Root cause of both: my pointer and claim sweeps were scoped to the 74 `DETAIL.md` files and did not include `PLAN.md` and the BLUEPRINT files themselves. Re-swept across the **whole** work folder and fixed all three sites; both classes now return clean |
| 2026-08-10 | Detail — delivery-003 fix verification round 2 | 0 findings, closed | Round 3 (`detail-work-006-delivery-003-r3.md`, empty ledger of 4 total rows, all Fixed) confirmed both round-2 findings hold: `PLAN.md § Revision History`'s delivery-003 row (:673) now agrees sentence-by-sentence with the `§ Shared-state safety` paragraph (:629-654) — heading shape was the root cause, diagnosed at first as a script defect and was not one, fixed, no shipped-script defect survives or is recorded — and both fixed heading pointers (`PLAN.md:573`, `deliveries/delivery-003/BLUEPRINT.md:132`) now resolve to the real `### delivery-003` / `#### Execution Graph` pair. Whole-work-folder sweeps (not scoped to DETAIL.md) found: zero surviving present-tense defect claims against either script outside the two already-resolved historical narrative rows; exactly one surviving `delivery-00N execution graph` hit, `STATE.md:165`'s dated *delivery-002 task set cut* row, correctly retained as an append-only historical record given the forward note at this file's own round-1 row above; and every `PLAN §`/`BLUEPRINT §`/`REQUIREMENTS §`/feature-`SPEC §` pointer across all 74 `DETAIL.md` files, `PLAN.md`, all three `BLUEPRINT.md` files and all four `STATE.md` files resolving to a real heading. Both parsers re-run directly against disk (not merely re-implemented): `complexity-score.sh --delivery-id {1,2,3}` → tasks=25/24/25; `compute-block-radius.sh --failed-task task-050 --delivery-id 3` → correctly reaches and blocks all 24 downstream delivery-003 tasks. Structural counts unchanged: 74 dependency rows, 3 `wave-map` blocks (74 lines), 3 `rw-sets` blocks (74 task lines), no trailing whitespace in `PLAN.md` or `deliveries/delivery-003/BLUEPRINT.md`. delivery-003 review closes A+ |
| 2026-08-10 | **Detail — phase complete** | A+ / A+ / A+ | All three deliveries detailed, reviewed and closed at A+ against a minimum grade of A: delivery-001 25 tasks (ten rounds, D → A+), delivery-002 24 tasks (one [HIGH], D+ → A+), delivery-003 25 tasks (four findings across three cycles, D+ → A+). **74 tasks total**, one combined graph: acyclic, 70 waves, root `task-001`, leaf `task-074`, parallelism only at waves 6 and 43. Across all 2,701 pairs — **0** unordered write/write, **0** unordered read/write, **0** same-wave conflicts; 8 forward edges partitioned 5/3. All three `deliveries/delivery-NNN/STATE.md` are `Specified`; `gate_tier`/`gate_grade` remain untouched, as those belong to `aid-execute`'s delivery gate. `active_skill` set to `none`; `phase` stays `Detail` until `/aid-execute` advances it. Nothing is committed — the work folder and branch are unpushed pending owner approval |

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. Future work
     may migrate this to a per-delivery hierarchy view, but until then it is AUTHORED here.
     One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- OMITTED: `## Delivery Lifecycle`, its `### Tasks lifecycle` subsection and
     `## Delivery Gate` are FLATTENED single-delivery sections only. This is a full
     multi-delivery work (PLAN.md declares three deliveries), so each delivery's lifecycle
     and gate live in its own `deliveries/delivery-NNN/STATE.md`, and each task's mutable
     state in `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`. The templates instruct
     exactly this: "Left absent (section omitted) for full multi-delivery works". The
     DERIVED `## Plan / Deliveries`, `## Tasks State` and `## Delivery Gates` views below
     union those child files at read time. -->

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

<!-- NOTE (work-006): the template above declares this section DERIVED and never
     written directly, but aid-specify's State Detection reads Feature State rows from
     THIS table (state-initialize.md Step 3 instructs writing them here). Skill and
     template disagree. Rows are written here so feature state is tracked at all;
     the contradiction is logged as a backlog item rather than silently resolved. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-kb-doc-set-restructure | Ready | E → E → E+ → r5 closed | 2 | r5: 18 Fixed, 1 Invalid (reviewer evidence refuted on disk). `release-tracking.md` registration restored; AC-9 moved to a surface adopters receive |
| 2 | feature-002-design-lifecycle-machinery | Ready | E+ → E → D → r5 closed | 0 | 17/17 Fixed. Two surviving statements of the old create-rule swept; AC-11/G3 stop denying the real build; 15 citations corrected |
| 3 | feature-003-planning-artifact-skills | Ready | r1 → r2 closed | 0 | 21/21 Fixed. ACs 5 → 12; all 40 cross-spec cites converted to section anchors; doc_set presence corrected to `required` per CC-1 |
| 4 | feature-004-foundation-artifact-skills | Ready | r1 → r2 closed | 1 | 26/26 Fixed. CC-3 propagated; fabricated feature-001 quote deleted; a 4th content collision found and assigned |
| 5 | feature-005-design-grid-and-brainstorm | Ready | r1 closed | 0 | 21/21 Fixed. Unpaired-artifact rule deleted per CC-8; derivation pinned to the pre-work catalog; 15 SKILL.md bodies now specified |
| 6 | feature-006-integration-and-close-out | Ready | r1 closed | 0 | 23/23 Fixed. Card count 15 → 22; count-guard procedure rebuilt on a 36-occurrence replay; **`coverage-baseline.tsv` +144 rows found — would have broken CI** |

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

- **Category:** Scope / Distribution
- **Impact:** Required
- **State:** Resolved 2026-08-09, then **partly superseded by Q5** — ship all three stages to adopters (this half stands). The seed-count half — "canonical seed 14 → 17" — is **superseded**: Q5 made `roadmap.md`, `backlog.md` and `release-tracking.md` conditional documents with no template, so the canonical seed stays at **14**. Recorded in REQUIREMENTS.md §5.1 / FR-9 / AC-3.
- **Context:** Surfaced by /aid-define (cross-reference). §3 claims adopters benefit from `roadmap.md` and `backlog.md`, but the KB doc-set has 14 canonical templates under `canonical/aid/templates/knowledge-base/` and `release-tracking.md` is **not** among them — it is AID-dogfood-only, as are `quality-gates.md` and `decisions.md`. So §5.1's four-stage lifecycle terminates in a document adopters do not have. Admitting the two new docs to the adopter seed also touches `synth_default_seed`'s ownership map (`doc-set-resolve.md:64-126`), `test-kb-template-authoring-standard.sh:53` (asserts exactly 14), and `concern-model.md`'s Seed-coverage check. Blocks ledger rows 3, 4, 16.
- **Suggested:** —

### Q5

- **Category:** Scope / Architecture
- **Impact:** Required
- **State:** Resolved 2026-08-09 — accept the re-scope. (a) `roadmap.md`, `backlog.md`, `quality-gates.md`, `release-tracking.md` become **conditional** documents (the `decisions.md` precedent), **created on demand by their own `create` skill**; the canonical seed stays at 14. (b) The `## Change Log` doctrine conflict leaves this work (supersedes Q3). (c) The spec gate target drops from A+ to **A**, the configured minimum.
- **Context:** Surfaced by /aid-specify after four spec-review rounds. feature-001 graded E twice with **zero recurrences** — every fix landed, and each round exposed a deeper layer, because the feature was carrying three independent feature-sized changes (the doctrine change, the seed migration, and the actual requirement). feature-002 graded E+ then E with **12 recurrences** — fixes applied at the cited line rather than to the finding's full extent. Conditional membership dissolves seven of feature-001's eleven CRITICAL/HIGH findings at once: the matrix byte-exact required-row conflict, the hollowness gate, the D-concern contradiction, and four count-migration surfaces. A+ is documented non-terminating in this repo, which is why the configured floor is A.
- **Suggested:** —

### Q4

- **Category:** Scope / Doc-set
- **Impact:** Required
- **State:** Resolved 2026-08-09, then REVISED by Q5. Option A (join the seed, 17 → 18) is superseded: `quality-gates.md` is admitted as a **conditional** document created on demand by `/aid-create-testing-strategy`, like the other three. The seed count does not move at all. The intent of Option A — that adopters get the document rather than only AID — is preserved, because conditional means created-when-applicable, not withheld.
- **Context:** Surfaced by /aid-specify (feature-004). REQUIREMENTS §5.3 gives `testing-strategy` two destinations: `test-landscape.md` and `quality-gates.md`. Verified: `test-landscape.md` is one of the 14 canonical templates, but `quality-gates.md` is **not** — no template under `canonical/aid/templates/knowledge-base/`, zero entries in `doc-set-resolve.md`'s ownership map, and `kb-category: extension` in this repo's own KB. Same defect class feature-001 found for `release-tracking.md`: a destination that exists for AID but not for adopters. Blocks feature-004 §5, and Option A would move feature-001's seed count 17 → 18 across ~10 already-specified surfaces.
- **Suggested:** —

### Q3

- **Category:** Scope / Conventions
- **Impact:** Required
- **State:** SUPERSEDED 2026-08-09 by Q5. The original resolution (strip everywhere, invert AS03) proved far larger than represented when the decision was taken: nine carriers rather than two, two of them self-restoring (`build-kb-index.sh`, `agent-prompts.md`), one behavioral (`state-apply.md:186` uses the section as an idempotency probe). Deferred to its own work; the new documents carry a `## Change Log` like every other KB document, so this work is consistent with shipped doctrine.
- **Context:** Surfaced by /aid-specify (feature-001). The project rule added during this work states a KB doc carries no `## Change Log` and no `changelog:` frontmatter. Disk contradicts it in three places: all 19 `.aid/knowledge/*.md` docs carry `## Change Log`; all 14 canonical templates under `canonical/aid/templates/knowledge-base/` carry it; and `tests/canonical/test-kb-template-authoring-standard.sh` assertion AS03 **requires** `## Change Log` to be the last top-level section of every template. The template standard therefore mandates exactly what the project rule forbids. feature-001 authors three new templates and cannot proceed without a decision. Blocks feature-001 §5.
- **Suggested:** —

### Q2

- **Category:** Scope / Authorization
- **Impact:** Required
- **State:** Resolved 2026-08-09 — authorized; narrow amendment (project-level docs admissible, per-work sprint artifacts still banned). Recorded in REQUIREMENTS.md §4 In Scope and C-6.
- **Context:** Surfaced by /aid-define (cross-reference). `canonical/aid/templates/kb-authoring/concern-model.md:63-73` bans governance artifacts from the KB, naming "a plan, a backlog, a register" explicitly; `authoring-conventions.md:239` restates it. Amending it is currently scope invented by feature-001, absent from §4 In Scope and from C-6's release-impact analysis. `concern-model.md` is a canonical template rendering to all five profiles, so amending it changes adopter-facing doctrine. Blocks ledger row 2.
- **Suggested:** —

### Q6

- **Category:** Scope / Close-out
- **Impact:** Required
- **State:** Resolved 2026-08-09 — **regenerate `kb.html` in this work** (the alternative, dropping it from scope, was rejected). It is regenerated by re-running `/aid-summarize`, once, in delivery-003's final-state-summary step, and is never hand-patched. The run's two costs are recorded rather than assumed: ~24 minutes, and an **orchestrator-run** V1 visual gate, because `validate-visuals.mjs` is SKIPPED for want of Playwright in the summarize package. Recorded in REQUIREMENTS.md §4 In Scope; feature-006 SPEC § *KB and methodology refresh* + § *Verification*; feature-001 SPEC § *Sequencing* step 6, § *Dependencies* and AC-6; delivery-003 BLUEPRINT Scope + Gate Criteria; PLAN.md cross-cutting risk 5. `.aid/knowledge/tech-debt.md` W1-11 corrected in the same pass.
- **Context:** Surfaced by the plan review as its CRITICAL: delivery-001's `## Unreleased` criterion required the section gone from every carrier that described it, and one carrier is `.aid/knowledge/kb.html`, which delivery-003 and feature-006 both declared unregenerable — so no delivery owned a path that could clear it. The premise was traced to `tech-debt.md` W1-11 ("cannot be regenerated — the assembler's `.aid/.temp/summarize/` input tree no longer exists") and verified **false**: `canonical/skills/aid-summarize/references/state-generate.md` § 2 reads `.aid/knowledge/{doc}.md` directly, and § 5 / § 8 *write* `.aid/.temp/summarize/summary-src/` during the run; `.aid/.temp/` is gitignored, so its absence between runs is the expected end-state, not a missing input. The file was stale, not unregenerable.
- **Suggested:** —

### Q7

- **Category:** Scope / Migration
- **Impact:** Required
- **State:** Resolved 2026-08-09 — **shape (a), derive-from-shipped.** One schema, no exemption arm: a row migrated from `## Unreleased` carries all seven columns, each derived from the item rather than invented. `Definition & done-condition` = the bullet's own text with the done-condition read as *shipped, pending tag*; `Location` = the durable anchor the bullet already names; `Risk if not done` = *ships untagged / absent from the next release notes*; `Priority` = `P1`, the next-release slice being committed by definition. Rejected (b) exempt-migrated-rows because an exemption forks the row schema permanently and every later consumer would have to handle two shapes; rejected reversing AC-4 because that is a scope change, not a fill-in. **Applies to:** feature-003 §5's column mapping gains a release-note-bullet arm, and task-018 is unblocked and carries the rule. Applied in the fix pass following delivery-001 review round 2.
- **Context:** REQUIREMENTS AC-4 and feature-001 §4a require `release-tracking.md`'s `## Unreleased` content to **move into `backlog.md`**, and feature-003 §3b makes every `backlog.md` item section an ID-keyed table of **seven** columns (`ID`, `Tag`, `Title`, `Definition & done-condition`, `Location`, `Risk if not done`, `Priority`). The live source is a single `[NEW]` release-note bullet at `.aid/knowledge/release-tracking.md:26` (the shipped `/aid-graph` skill) and it supplies **two** of the seven — a tag and a title. feature-003 §3b's derivation rules cover only a promotion from `tech-debt.md` (which supplies four more) and an item **born in the backlog** (which supplies the `ID` minting rule only); §5's column mapping has no arm for a release-note bullet, and feature-001 §4a's carrier table says only *"`## Unreleased` to `backlog.md`"*. So `Definition & done-condition`, `Location`, `Risk if not done` and `Priority` have no stated source for an item that is **already built and merely unreleased**. Detail cannot resolve this: authoring four of seven fields from nothing is a design decision, and Detail slices rather than designs. Blocks task-018's data-integrity criterion.
- **Suggested:** Two shapes are available without new doctrine. (a) **Derive-from-shipped:** `Definition & done-condition` = the bullet's own text with the done-condition read as *shipped, pending tag*; `Location` = the durable anchor the bullet already names (for the live item, `canonical/skills/aid-graph/SKILL.md`); `Risk if not done` = *the item ships untagged / is absent from the next release notes*; `Priority` = `P1`, since `## Next Release` is by definition the committed slice. (b) **Exempt the migrated slice:** state in feature-003 §3b that `## Next Release` rows migrated from `## Unreleased` carry `ID`, `Tag` and `Title` only, since they record already-built work rather than work to be done. (a) keeps one schema; (b) keeps the schema honest about what it can know. Owner decision required either way.

### Q8

- **Category:** Requirements / Oracle integrity
- **Impact:** Medium
- **State:** Resolved 2026-08-10 — **the SPECs are corrected at source, not only in the consuming tasks.** All four printed instances are narrowed to `find canonical/aid/templates -type f \( -iname … \)`: feature-001 AC-2 and §1a, feature-003 §3 lede and §9 *Depends on feature-001*. In **three** of the four, the surrounding criterion text was already scoped to `canonical/aid/templates/`, so the narrowed oracle asserts the same proposition and nothing less. The **fourth** — feature-003 §3's lede — claimed *"no template anywhere under `canonical/`"*, which is **broader than any oracle can check** and would be falsified by this feature's own six `canonical/skills/aid-*-{roadmap,backlog}` directories; there the **claim** was narrowed to the template tree to match, rather than the oracle broadened to match the claim. Each SPEC carries a Change Log row recording why. No owner decision was needed: the correction is forced by the criterion text the oracle was printed under, so this entry is an escalation record rather than an open question. **Applies to:** feature-001 SPEC AC-2 + §1a, feature-003 SPEC §3 + §9, task-007 and task-020 (which already ran the narrowed form and disclosed the divergence).
- **Context:** Surfaced by /aid-detail while slicing delivery-001. feature-001 AC-2 states its criterion as *"None has a file anywhere under `canonical/aid/templates/`"* but printed `find canonical -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*'`. `-iname` matches **basenames**, so once feature-003 lands `canonical/skills/aid-{design,create,update}-roadmap` and the three `*-backlog` siblings, the printed oracle returns six directories while the criterion demands nothing — **unsatisfiable by a correct implementation**. All four instances return nothing today, which is why the defect survived spec review; only the narrowed form still returns nothing after feature-003 lands. task-007 and task-020 had narrowed it locally, but a task-local fix leaves the authoritative source printing a command that yields a false failure for the next reader, so the correction is made in the SPECs.
- **Suggested:** —

### Q9

- **Category:** Architecture / Schema conflict
- **Impact:** Low
- **State:** Pending — flagged for human decision; **not blocking delivery-001**
- **Context:** Surfaced by /aid-detail. **Two canonical templates for the same artifact disagree on the `Source:` field of a task `DETAIL.md`.** `canonical/aid/templates/task-detail-template.md:23` prints `**Source:** work-NNN-{name} -> delivery-NNN`; `canonical/aid/templates/delivery-plans/task-template.md:5` prints `**Source:** feature-NNN-{name} → delivery-NNN`. `.aid/knowledge/artifact-schemas.md:285` names `task-detail-template.md` as the DETAIL file's source template and `:296` repeats the `work-NNN` form, so the KB sides with the first. All 25 DETAIL files in delivery-001 follow it, and reproduce that template's `[!NOTE]` verbatim — including the note's own cross-cite to the shape template, which is where the two forms sit side by side. The observable cost: this delivery spans three features, and the field schema'd for provenance names the work rather than the feature, so no *field* says which feature owns a task.
- **Suggested:** Make `task-detail-template.md` and `delivery-plans/task-template.md` agree, and have `artifact-schemas.md` state the winning form once. If the `feature-NNN` form wins, the DETAIL files' `Source:` values are a mechanical rewrite; if `work-NNN` wins, the shape template is the one that changes.
- **Answer:** — (open). Detail did not resolve it because picking a winner edits a shipped canonical template and its five profile renders (delivery-003 owns the render), and changes the schema for every AID adopter's task files — a repo-wide decision, not a slicing decision. Detail follows the KB, which is the designated source of truth, and records the conflict rather than choosing silently.
- **Applied to:** nothing yet — the question is open. The gap it names is mitigated rather than closed: every one of the 25 DETAIL files names its source feature in the first bullet of its `Scope`, verified on disk (`grep -l 'feature-00[1-9]'` over the 25 files returns all 25), so a reader can always see which feature owns a task; it is the schema'd *field* that names the work instead.

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
