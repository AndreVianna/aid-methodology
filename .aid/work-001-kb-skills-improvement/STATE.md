# Work State -- work-NNN-{name}

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single-writer) -- Pipeline State, Triage, Escalation Carry, Interview State, Lifecycle History,
    Deploy State.
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.

<!-- SD-2 STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

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

> **State:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
> **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-06-22
> **User Approved:** yes | no

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task SPEC.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

---

## Pipeline State

<!-- AUTHORED -- written ONLY by `writeback-state.sh --pipeline ...` at every phase/state
     transition the pipeline performs. Never hand-edited. All values are closed enums so a
     deterministic reader needs no inference. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Running
- **Phase:** Specify
- **Active Skill:** none
- **Updated:** 2026-06-23T03:47:36Z
- **Pause Reason:** Specify phase complete (12/12 features Ready/A+) — awaiting /aid-plan
- **Block Reason:** —
- **Block Artifact:** —

---

## Triage

<!-- AUTHORED -- populated by `aid-interview` TRIAGE state for lite-path works.
     Left empty for full-path works (aid-interview runs the full interview flow instead). -->

- **Path:** full
- **Decision rationale:** large multi-skill effort (5 KB-facing skills + new aid-update-kb) with multiple sub-features; no single lite recipe fits + user-directed full path

---

## Escalation Carry

<!-- AUTHORED -- written by `aid-interview` lite to full escalation (Steps 3-9 of
     `lite-to-full-escalation.md`). Present only when a work started on the lite path
     and was escalated to full. The CONTINUE state reads this section to avoid re-asking
     questions already answered during the lite-path session. See
     `references/state-continue.md # Escalation Carry`. -->

- **Escalated from:** {state name} (Sub-path: {sub-path value})
- **Escalated at:** {YYYY-MM-DDTHH:MM:SSZ}
- **Escalation rationale:** {one sentence}

### Captured Slot Values

- **{slot-name}:** {slot-value}
- (no slots captured -- escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

- **SPEC.md:** present | absent -- {notes on content available for seeding}
- **tasks/:** {N} task files present | absent

---

## Interview State

<!-- AUTHORED -- updated by `aid-interview` as each section is completed. -->

**State:** Approved  **Grade:** Pending

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-06-22 |
| 2 | Problem Statement | Complete | 2026-06-22 |
| 3 | Users & Stakeholders | Complete | 2026-06-22 |
| 4 | Scope | Complete | 2026-06-22 |
| 5 | Functional Requirements | Complete | 2026-06-22 |
| 6 | Non-Functional Requirements | Complete | 2026-06-22 |
| 7 | Constraints | Complete | 2026-06-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-22 |
| 9 | Acceptance Criteria | Complete | 2026-06-22 |
| 10 | Priority | Complete | 2026-06-22 |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-22 | Work created | -- | Initial scaffold by aid-interview |
| 2026-06-22 | Interview approved | -- | Requirements ready; 10 sections Complete; full path |
| 2026-06-22 | Feature decomposition | -- | 12 features created (f001–f012) |
| 2026-06-22 | Cross-reference validation | C | Grade C (min A); 2 MEDIUM → Q1/Q2 raised (Pending); LOW/MINOR fixes to fold inline |
| 2026-06-22 | Cross-reference re-grade | A+ | Q1/Q2 answered + folded; LOW fixed/accepted; migrate-name verified; clears the A bar |
| 2026-06-22 | aid-specify feature-001 | A+ | Ready — frontmatter + sources primitive; C→A+ (4 inline fixes) |
| 2026-06-22 | aid-specify feature-002 | A+ | Ready — INDEX routing table; C→A+ (2 MEDIUM fixed, 2 accepted) |
| 2026-06-22 | aid-specify feature-003 | A+ | Ready — KB document model + concern-model.md + summarize; D+→A+ (HIGH seed-list error fixed) |
| 2026-06-22 | aid-specify feature-004 | A+ | Ready — essence-capture engine (harvest + spine + closure + escalation); D+→A+ (HIGH salience arithmetic fixed) |
| 2026-06-22 | aid-specify feature-005 | A+ | Ready — review panel + teach-back gate + Calibration; C→A+ (3 MEDIUM fixed) |
| 2026-06-23 | re-gate feature-005 (f004-seam) | A+ | 2 contract fixes vs f004 3-output oracle: (HIGH) teach-back selection now `spread>=2 OR Source==synthesis` (synthesis rows have empty Spread); (HIGH/MED) M3/CAL-1/CAL-3/reverse+transcription passes re-pointed at f004 outputs (a)/(b)/(c) with matching schema+URL-N/A scoping. Core (5 mandates, merged ledger, teach-back limb, [TEACHBACK] encoding, calibration round-trip, f005↔f008 seam) intact |
| 2026-06-23 | whole-work review (3 lenses) | A-/B+ | Holistic gate: over-engineering (proportionate core/over-built periphery), intent (Aspect-2 essence delivered LEXICAL-only — tokenless 'Relative bus' class slipped), coherence (2 unowned seams + f008/f009 merge). 2 user decisions: add non-lexical limb; keep-but-simplify greenfield |
| 2026-06-23 | revise+re-gate feature-004 | A+ | Conceptual-synthesis channel (tokenless, evidence-anchored) + closure-cap arg ownership + merged closure-check.sh 3-output oracle (a/b/c). D+→A+ |
| 2026-06-23 | revise+re-gate feature-006 | A+ | Greenfield simplified (interview/specify reuse, verifier dropped, mini→collapsed) + P2 sequential-passes adjudication; REQUIREMENTS §1.5 matrix + seam cross-refs aligned. C→A+ |
| 2026-06-23 | whole-work revision COMPLETE | A+ | f004/f005/f006 re-gated A+; REQUIREMENTS/upper-sections consistent; 5 items carried to /aid-plan (f008+f009 merge, is_source/extract_list shared-lib, salience-validate, skill-count CI guard). All 12 features Ready/A+ |
| 2026-06-23 | aid-plan work-001 | A+ | PLAN.md + 9 deliveries written (D1 Essence Core foundation → D9 Greenfield Could); acyclic, MoSCoW-ordered, f008+f009 merged (D7), f006/f012 scope-split; C+→A+ (R3 calibration-back-patch risk + D4 attribution). Ready for /aid-detail |
| 2026-06-23 | aid-detail work-001 | A+ | 53 tasks across 9 deliveries (task-001..053), each deliverable A+ gated; global DAG acyclic + all cross-delivery deps backward-resolving; execution graphs in PLAN.md. Caught+fixed: f012 stale-oracle (merged-coverage propagation), AC1 teach-back gap, greenfield-behavior leaks. Ready for /aid-execute |
| 2026-06-22 | aid-specify feature-006 | A+ | Ready — recon triage + 3 paths + panel-scaling; A→A+ (2 MINOR fixed) |
| 2026-06-22 | aid-specify feature-007 | A+ | Ready — per-doc freshness loop; D+→A+ (cross-feature f001↔f007 absence-contract reconciled; f001 spec line aligned) |
| 2026-06-22 | aid-specify feature-008 | A+ | Ready — skill topology (aid-query-kb rename + aid-update-kb + gap-capture); A→A+ (3 MINOR fixed; SPIKE-2 f005-param seam → PLAN) |
| 2026-06-22 | aid-specify feature-009 | A+ | Ready — skill-change propagation; D+→A+ (HIGH: missed kb.html surface + count-label conflation fixed) |
| 2026-06-22 | aid-specify feature-010 | A+ | Ready — housekeep↔update-kb boundary + standing closure; D+→A+ (HIGH: AC1-narrowing resolved — whole-KB review retained) |
| 2026-06-22 | aid-specify feature-011 | A+ | Ready — KB migration; B→A+ (M5 resolved: shipped soft-skip retained per NFR-7 + AID-CI strict; sources:[] idempotency) |
| 2026-06-22 | aid-specify feature-012 | A+ | Ready — validation fixture (AC2 'Relative Bus' regression + calibration/teach-back/path); D+→A+ (HIGH: phrase-survival path corrected to f004) |
| 2026-06-22 | aid-specify ALL 12 features | A+ | All features Ready/A+ — Specify phase complete; ready for /aid-plan |
| 2026-06-23 | aid-plan PROPOSE (sequence) | -- | Dependency graph mapped (acyclic, single-producer primitives confirmed) + 7-delivery sequence proposed for user reaction. f008+f009 merged into one delivery (D5) per whole-work carry. NOT yet committed — PLAN.md unwritten; phase stays Specify/Paused pending user decision |

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
| 1 | feature-001-frontmatter-and-sources-primitive | Ready | A+ | 0 | C→A+: soft-skip lint until f011, reuse FM tags, external-sources seed, aid-config note |
| 2 | feature-002-index-routing-table | Ready | A+ | 0 | C→A+: bounded Summary split, f002 owns ASCII-clean of build-kb-index.sh, coexistence intent fallback |
| 3 | feature-003-kb-document-model | Ready | A+ | 0 | D+→A+: concern-model.md (10 concerns/15 seeds), byte-identical seed reframe, expectations→open-questions, summarize spine across 7 profiles |
| 4 | feature-004-essence-capture-research | Ready | A+ | 0 | D+→A+: harvest-coined-terms.sh (phrase-survival closes 'Relative bus'), glossary→spine, bounded closure-check.sh, Step-6b escalation; salience arithmetic fixed |
| 5 | feature-005-review-panel-and-rubric | Ready | A+ | 0 | C→A+: 5-mandate parallel panel→merged ledger, un-relaxable teach-back hard gate, Calibration dimension + round-trip; self-contained extraction |
| 6 | feature-006-recon-triage-and-paths | Ready | A+ | 0 | A→A+: recon-classify.sh + triage thresholds, 3-path config matrix, f005 panel-scaling (5→2), closure-cap runtime-arg seam |
| 7 | feature-007-per-doc-freshness-loop | Ready | A+ | 0 | D+→A+: kb-freshness-check.sh (merge-base ancestry), two-reader parity, degrade matrix; fixed f001↔f007 absence-contract contradiction |
| 8 | feature-008-skill-topology | Ready | A+ | 0 | A→A+: aid-ask→aid-query-kb rename (canonical-only, grep-0), new aid-update-kb thin-router (reuses f005 gate), gap-capture into Q&A; SPIKE-2 (f005 param seam) carried to PLAN |
| 9 | feature-009-skill-change-propagation | Ready | A+ | 0 | D+→A+: S1-S12 propagation table (orphan-prune verified), +.aid/dashboard/kb.html surface+Playwright, count labels (user-facing 12→13 vs total 13→14) |
| 10 | feature-010-housekeep-update-boundary-and-standing-closure | Ready | A+ | 0 | D+→A+: source-driven-global vs prompt-driven-targeted boundary; AC1 preserved (whole-KB review retained, staleness = prioritization); closure re-verify before commit |
| 11 | feature-011-kb-migration | Ready | A+ | 0 | B→A+: migrate-kb-frontmatter.sh (precedent-following, propose→confirm sources, --rollback), shipped soft-skip RETAINED (NFR-7) + AID-CI strict, sources:[] idempotency |
| 12 | feature-012-validation-fixture | Ready | A+ | 0 | D+→A+: planted 'Relative Bus' phrase-survival regression (AC2) + calibration/teach-back/path fixtures, threshold-pinning oracle, HOME-pinned isolation; phrase-floor path corrected to match f004 |

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
     The state reader unions all delivery branches using the SD-2 ordering (most-advanced wins).
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
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here (SD-5).
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Q1

- **Category:** Architecture (Freshness)
- **Impact:** Required
- **Status:** Answered (2026-06-22)
- **Answer:** (a) — a NEW per-doc **`approved_at_commit:`** frontmatter stamp, written on approval by `aid-discover`/`aid-update-kb`; FR-4 adds the field, FR-5 compares each doc's `sources:` against it. Folded into REQUIREMENTS.
- **Context:** Cross-reference (2026-06-22) found FR-5 / feature-007 per-doc staleness compares each doc's `sources:` against "that doc's **approval commit**," but **no per-doc approval-commit primitive exists or is created by any FR/feature** (`state-kb-delta.md` notes "no `Approved-At-Commit:` field"). The comparator's baseline is unbuilt and unowned — MEDIUM, grade-driving. Must be resolved before feature-007 is specifiable.
- **Suggested:** (a) a NEW per-doc `approved_at_commit:` frontmatter stamp written on KB approval by aid-discover/aid-update-kb.
- **Question:** How should FR-5's freshness comparator establish each doc's baseline — (a) a new per-doc `approved_at_commit:` frontmatter stamp, (b) git-blame of the doc's last approval commit, or (c) reuse the existing whole-KB `kb_baseline.tip_date`?

### Q2

- **Category:** Constraints (Packaging)
- **Impact:** Medium
- **Status:** Answered (2026-06-22)
- **Answer:** Yes — the new mechanical KB scripts are shipped/vendored → the ASCII-only guard applies (bash, so PS-5.1 N/A). Folded into C2.
- **Context:** Cross-reference (2026-06-22) — C2 (ASCII-only + WinPS-5.1) scope is ambiguous for the NEW mechanical KB scripts (coined-term scan, closure self-containment check, salience). They are bash (so PS-5.1 is N/A), but it is undecided whether they count as "shipped/vendored scripts" under the ASCII-only guard.
- **Suggested:** yes — if vendored into the install bundles they are "shipped" and the ASCII-only guard applies.
- **Question:** Do the new KB mechanical scripts count as "shipped scripts" subject to the ASCII-only guard (C2), and are they vendored into the 5 install bundles?

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
