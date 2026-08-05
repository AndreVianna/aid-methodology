---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-28"
minimum_grade: B-
user_approved: yes
lifecycle: Running
phase: Specify
active_skill: aid-specify
updated: '2026-07-31T02:50:40Z'
pause_reason: --
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
| 2026-07-29 | Owner decisions invalidate delivery-001 rendering + vocabulary scope | -- | Live graph mandated (d3-force + PixiJS/WebGL); standards-grounded vocabulary; widened node model; ten-column schema. REQUIREMENTS reopened three times; all defects fixed; re-gated **A+**. |
| 2026-07-29 | Re-spec Wave 1 — feature-003 schema spine | **A+** | 1,813 lines; reopened twice (extra-row ordering, FR-11 input 6); loader sync with feature-001 **still open** (Q20). |
| 2026-07-29 | Re-spec Wave 2 — features 001–005 | **A+** | All five re-specified and gated. feature-004 reopened once (qualifier map); fixed through re-gate round 3; **final A+ re-gate pending**. |
| 2026-07-29 | Re-spec Wave 3a — features 006–007 drafted | -- | feature-006 re-specified (573 → 1,162 lines); feature-007 re-specified (925 → 1,707 lines). **A+ gates not yet run.** Features 008–013 still on pre-decision specs. |
| 2026-07-29 | **Paused — session handoff** | -- | Orchestrator pauses before Wave 3a gates and Wave 3b–3d. PLAN.md + 96 tasks are **stale** until re-spec completes. delivery-001 research **invalidated** — replacement research not started. Resume per **Q24**. |
| 2026-07-30 | Resumed in Claude Code — Q24 queue | -- | Worktree `work-005-knowledge-graph` (branch `aid/work-005-delivery-001`) confirmed as the live tree holding the Wave-3a working set — proved by content, not by name: feature-006's SPEC is **1,162 lines** here (the re-spec) versus **573** in the sibling (pre-redesign). |
| 2026-07-30 | **A+ gate feature-006 — first pass** (Q24 item 2) | **D** | FAILED the A+ minimum. 15 rows (14 counted + 1 OOS): 0 CRITICAL, **2 HIGH**, 6 MEDIUM, 4 LOW, 2 MINOR. Ledger `.aid/.temp/review-pending/feature-006-spec.md`. Both HIGHs are seam defects, and **both are ordering artifacts of the wave**: feature-006 was written 21:30 and feature-004's re-gate fixes landed 23:29, so (1) Open Item 2 still routes a reopen+re-gate of the 2,381-line gated feature-004 for work its D3a has **already discharged in full** (feature-004's own Open Item 14 says so and asks feature-006 to close it), and (2) L2 claims `coverage-predicate.mjs` "already exports" `keys(RELATION_CATEGORY)` when feature-007 puts that constant in `graph-model.js` — which feature-006's own D6 forbids the Node side importing — leaving the F6 counter (step 4 / AC-G5 / GL17 / GL12) with **no reachable data source**, and contradicting this SPEC's own lines 993/1039. Four MEDIUMs verified on disk by the orchestrator before any fix: the feature-004 D1 quotation is the **exact negation** of the cited text (strongest-applicable, not first-matching); the `kb_gaps` worked example ranks a shebang-carrying `test-*.sh` `named-unit`/`LOW` where D3a makes it `entry-point`/`[HIGH]`; F2's directory id lacks the grammar-required trailing `/`; and **feature-010 retains `graph-kb-gaps.md` past DONE on the stated authority of "feature-006 §D7", which as re-specified withdraws exactly that retention** (row 8 in-scope, row 15 OOS). Reviewer read all 1,162 lines plus REQUIREMENTS in full, all five mandated check classes completed, and verified the first line of each of the 133 `tests/canonical/test-*.sh` by reading rather than counting (Q23). No spurious rows: every claim the orchestrator spot-checked held. |
| 2026-07-30 | **feature-003 cycle-3 gate — A+ (Q24 item 3 COMPLETE; Q20 loader sync CLOSED)** | **A+** | 12 ledger rows `Fixed`, **0** counting toward the grade, no `Recurred` across three cycles. One new finding, `[MINOR]` **editorial** → routed as **E2**, not charged. **The substantive contract change was verified by construction, not by reading:** the reviewer built its own case — `kb:zebra.md` (document) `defines` `kb:concept:alpha` (concept), where `z` 0x7A > `c` 0x63 so D7 stores the row **flipped** — and showed both-readings accumulation yields `{(defined-by, concept->document), (defines, document->concept)}` **byte-identically** to the unflipped storage. It further showed the per-row advisory is invariant *because pair coherence is gating* and forces `endpoint_kinds(r')` to be the exact transpose, and that the partition predicate is equivalent to "observed set non-empty" under both-readings accumulation. Nothing crossed the gate/advisory line in either direction. It also upheld the author's refusal to adopt the ledger's suggested remedy: feature-001`:458` scopes W4's decidability to "the vocabulary + a generated `relationships.md`" and feature-005`:1162` says its own report depends on map and vocabulary alone, "never on a generated table (that is W4, feature-003's)" — so computing from the map would have been W3. And it confirmed the cost note is honest: feature-001`:493`'s "one set insert per row" is a **prose estimate inside D3a, not a contract clause**, so correcting it with attribution reopens nothing. Three further candidates were **considered and declined with reasons** rather than recorded — the third reviewer in a row to decline rather than pad. |
| 2026-07-30 | **A+ gate feature-007 — CLOSED at A+ (Q24 item 4 COMPLETE)** | **A+** | Four cycles: **E+ → D+ → B → A+**. 35 ledger rows — **34 `Fixed`, 1 `OOS`, 0 counting, 0 `Recurred`**. Grew 1,707 → **1,992** lines. **Delta discipline is the story of this feature:** cycle 1's fix was **+263** lines and produced **10** findings; cycle 2's was **+19** and produced **3**; cycle 3's was **+2** and produced **0**. New prose is unreviewed prose, and the correlation held monotonically across four cycles. Two rulings settled by the gate rather than asserted: **(1) row 24's justify-not-re-key call upheld** — Q21's own worked example is decisive, since FR-19's `int:` is held *correct* for naming the discovery mechanism, which legitimately yields both `source-artifact` and in-repo `image`; a prefix spanning two kinds is not disqualified, *standing in for the kind* is, and REQUIREMENTS FR-14a and AC-1 key the identical split. Cycle 2's contrary reading conflated a UI partition with Q21's closed `Kind` enum. **(2) row 33's `grouping: 'none'` scope is a scope, not an evasion** — collapse is decided by the grouping, not the filter, so AC-8a's equality against `relationships.md` is **ill-posed under a folding dimension for any implementation** once a same-group row exists; no field choice rescues it, and the new sentence quantifies the shortfall rather than denying it. Also settled: the `ViewModel` count discrepancy between two cycles' reports — **19 fields, and the SPEC asserts no numeral for it**, so there was nothing to reconcile (`integrity` is a `GraphModel` field). The fold carrier redesign holds: drill-in two-way, D3's "interpreted exactly once in `project()`" promise now **true** rather than merely unchanged, `LensState` total at 14 matching GV25 item-for-item. |
| 2026-07-30 | **Wave 3b — 008 and 009 authored fresh, first gates C- and C** | **C- / C** | Both **authored fresh** against the frozen spine per Q26, replacing their 2026-07-28 pre-decision drafts. **feature-008** 365 → **722** lines, gate **C-** (0 CRITICAL, 0 HIGH, 6 MEDIUM, 7 LOW, 2 MINOR). **feature-009** 375 → **665** lines, gate **C** (0 CRITICAL, 0 HIGH, 2 MEDIUM, 4 LOW, 1 MINOR). **Fresh authoring is measurably cheaper than re-specification:** the two re-specified siblings' first gates were **D (14 findings)** and **E+ (21, incl. 1 CRITICAL and 6 HIGH)**; these two came in with **no CRITICAL and no HIGH between them**, and neither carries a single legacy proxy defect — the class has zero instances by construction, exactly as Q26 predicted. Between them the two authors caught **17 defects in their own drafts** pre-handoff, including feature-009 removing the withdrawn 784/616 figures it had initially reproduced. Both reviewers reported **zero line-number drift** across ~60 and ~40 checked citations respectively. **feature-009's author also caught an orchestrator error** — the authoring brief named **AC-6a** as the canvas/table parity criterion; AC-6a (`REQUIREMENTS.md:917–919`) is NFR-7's **≥30fps floor** with no parity clause, and the mutual criteria are **AC-7, AC-8a, AC-21 and AC-9**. It verified by reading and **flagged rather than complying**; the orchestrator corrected feature-008's already-running gate mid-flight so it would not grade against the false premise. Fourth orchestrator error of the day, same shape as the other three: a fact asserted that one command would have checked. |
| 2026-07-30 | **master merged (131 commits, PR #174) — 1 conflict resolved; CITATION SWEEP now owed** | -- | `origin/master` merged into `aid/work-005-delivery-001` as `00194684`. **Assessed before merging, not after** — the four things that would have invalidated in-flight work are **untouched**: `canonical/aid/scripts/summarize/` (all of feature-011's subject), `tests/canonical/test-contrast-check.sh` and `.github/workflows/test.yml` (feature-011's CRITICAL fixture table and its dead-CI-lane Open Item), `render.py`/`render_lib.py`/`run_generator.py` (feature-012's core), and `reviewer-ledger-schema.md`/`grade.sh`/`.aid-manifest.json` (feature-010's authorities). **Exactly one conflict**, previewed with `git merge-tree` before touching the working tree: `site/scripts/__tests__/gen-reference.test.mjs`. **Resolved in master's favour, and it was not a close call** — master's task-057 **deleted the artifacts this branch's version asserts about** (the family table and the per-skill `### \`aid-…\`` sections; the roster moved to `/skills/`), so those assertions would fail against the current `skills.md`. Master also went further in the same direction this branch was heading: counts replaced by **set equality in both directions with no counts at all** (Q19's own principle), a **clamp that fails BY NAME** for any on-disk skill directory that is neither a catalog row nor curated, and **KI-009 closed by deleting the table** rather than repairing arithmetic that interpolated against an empty row set. Verified after resolving: no markers, `parseShortcutCatalogEmitted`/`catalogEmitted` orphan nothing (0 refs), `SHORTCUT_CATALOG_FILE` coherent (defined `:23`, used `:170`), `node --check` passes. **Consequence for feature-012:** master's clamp means the moment `canonical/skills/aid-graph/` exists, that suite **fails by name** until `aid-graph` is a catalog row or a curated entry — a registration obligation with a new consumer. **THE OWED WORK — a citation sweep, and it is the class that has cost this work more re-gates than any other.** The merge moved eleven `.aid/knowledge/` docs and `.aid/settings.yml`: **module-map.md +77 (350→427), tech-debt.md +98 (288→386), test-landscape.md +21 (371→392)**, architecture +4, decisions +5, infrastructure +4, integration-map +3, pipeline-contracts +1, README +2, knowledge/STATE +1, and `settings.yml` 112→127. **Every line-numbered citation into those twelve files, across all thirteen SPECs, is now suspect** — and three agents were mid-flight across the merge boundary, so some of their verifications were made against pre-merge line numbers. The sweep must be run before any of the affected SPECs' grades are relied upon. |
| 2026-07-30 | **Post-merge citation sweep — 9 of 10 stale; verified first-hand, map recorded** | -- | The sweep the merge owed, run by the orchestrator rather than delegated, because the oracle is mechanical and first-hand verification is the standing correction from error 4. **Scope was smaller than feared: ten distinct citations in the form `<doc>:<line>` into the twelve moved files, across four SPECs** (008×1, 010×4, 011×1, 012×6). **Nine shifted; one survived.** Each new anchor was found by taking the **pre-merge text** at the old line and locating it in the post-merge file, so the *fact* is confirmed present — not the offset arithmetic. **Verified map:** `module-map.md` `:235→:310`, `:253→:328`, `:262→:337`; `test-landscape.md` `:111→:113`, `:258→:279`, and **`:29` UNCHANGED** (the sole survivor); `tech-debt.md` `:143→:233`, `:253→:350`; `infrastructure.md` `:88→:89`. **`.aid/settings.yml:6` is a content change, not a position change** — the key is still `minimum_grade`, but **master independently lowered its value `A+` → `B-`**, converging on this work's own Q27 decision; that is agreement, not a conflict, and feature-010's judgment call 1 (`--grade` does not persist, because the file is FR-11 input 4) is unaffected. **Applied directly to the two settled SPECs** — feature-008's `:262→:337` and feature-011's `:111→:113`, both re-read on disk after editing to confirm they land on the claimed facts, and feature-011's uncited "not machine-tested by design" claim re-confirmed present. **Handed as a verified map to the two mid-flight agents** (feature-010's fix, feature-012's cycle-3) rather than edited under them, with the instruction to **read each new line before writing it** — `tech-debt.md` grew by 98 lines, so an item may have been reworded or closed, not merely moved, and a shifted number is not the same as a still-true claim. Ranges (`module-map.md:235–273`, `tech-debt.md:83–85`/`:253–256`) were **excluded from the map and routed back** for first-hand re-derivation, since only the range start was mechanically locatable. **Also flagged to feature-010:** `HEAD` now points at the merge commit, so row 4's inherited-diagram oracle must use `git show 3fc7cdb4:` rather than a bare `git show HEAD:`. |
| 2026-07-30 | **Orchestrator errors 5 and 6 — two gaps in the post-merge sweep, both found by the agents it briefed** | -- | The sweep in the row above was **correct as far as it went and wrong about how far that was**. Both gaps are recorded because each is a distinct failure of scoping a verification, and together they are the fifth and sixth instance of the session's recurring shape. **Error 5 — the sweep tested the wrong property.** It verified whether a citation **resolves**; it never asked whether an **argument resting on the cited content still holds**. Found by feature-010's fix: `.aid/settings.yml:6` changed value `A+` → `B-`, and **three clauses silently became false while their citations stayed perfectly valid** — most sharply D4's "any row at any severity gates", true at `A+` and **false at `B-`** because a `[LOW]` row grades in `grade.sh`'s `B` band (`:242–243`), with a second clause resting on that same claim in a way that at `B-` would have **permitted exactly what it existed to forbid**. Re-grounded on the rubric's **emitted range** (only `[HIGH]`/`[MEDIUM]`, bands `D` and `C`), so it no longer depends on this project's setting at all. **Error 6 — the sweep's scope was too narrow twice over.** It keyed on the literal `<doc>:<line>` form, so **ranges and section references were invisible** (feature-010 found **three** `module-map.md` sites where the sweep found one, "two of which were outside your verified set"); and it covered only the eleven `.aid/knowledge/` docs plus `settings.yml`, when **the merge changed 504 files** including `site/` and `.claude/skills/generate-profile/`. Found by feature-012, which turned up **three claims that were FALSE rather than mis-numbered**: `SKILL_GROUPS` had **moved to a new module** (`curated-roster.mjs`), `gen-reference.test.mjs:188`'s section-count assertion was **deleted by task-057**, and Open Item 3's whole premise was falsified because master re-anchored and gated those literals. **Blast radius then verified and found contained:** a check across all thirteen SPECs for line citations into every non-KB file master touched returned **none** outside feature-012 — and the one that looked dangerous was not: feature-010 cites `canonical/aid/scripts/**summarize**/writeback-state.sh:204`, a **different file** from the `execute/` copy master changed, confirmed unchanged and confirmed to still be the `GRADE` regex validation. **Standing correction, generalising all six errors:** a verification's scope is itself a claim that needs checking — state what the sweep covers, what it cannot see, and which property it tests, so the gap is visible rather than assumed absent. |
| 2026-07-30 | **★ feature-007 reopen COMPLETE — re-gated B; no downstream contract weakened** | **B** | Freeze exception 1 executed and closed at **+25 lines exactly** (1,992 → **2,017**). Fresh ledger `feature-007-reopen.md` (the four A+ cycles' ledger untouched and still grading A+): **0 CRITICAL/HIGH/MEDIUM, 4 LOW + 3 MINOR deferred**, 2 `OOS`. **The first duty was answered: nothing downstream was weakened.** AC-15 verified against REQUIREMENTS`:954` as the highest authority — it is a **set** equality, and `coverageGaps.artifactUndocumented` is computed **once per load** inside `createStore` keyed over neither `visibleNodes` nor `LensState`, so it binds unconditionally; the withdrawn D1a exemption was a promise about *marks* that its own contract made unimplementable. **Seam 1** found a third witness the brief had not cited — D4`:626` already said these records are "grouped, **thinned** and filtered exactly like any other node" — so it was two clauses to one. **Seam 2** put the preferences on the **store**, refusing a `ViewModel` field, specifically to preserve `:1699`'s gated "the store is pure and headless" (a store calling `matchMedia` would have falsified it); GV27 now *hooks* that sentence. **Seam 3** chose "canvas computes, shell writes" because D8 assertion 3 asserts each manifest entry's effect on `LensState`, so the effect must come from that entry's own handler. **Seam 4's edge axis needs no precedence, and the reviewer re-derived it independently** by case analysis over `emphasis`'s three values rather than by occurrence count — **which mattered, because the orchestrator's own recorded derivation was invalid**: "`edgeEmphasis` occurs at exactly two lines, so D6f is the only clause assigning any edge class" is false (neither occurrence *is* D6f, and D6f classifies rows without naming the field). Right answer, wrong proof, propagated by the orchestrator into two briefs before being caught — logged LOW. **Fifth-seam ruling:** `kbUnbacked`'s unstated computation point is the same *class* but materially weaker (no gated criterion touches it; `edges` is already pinned to the whole table) — **not worth a freeze exception**; one clause in D10 closes it and the Q24 item-9 pass is the carrier. |
| 2026-07-30 | feature-008 impact sweep — **+9 lines**; AC-15's canvas half repaired | -- | Three Open Items closed as answered; **the gap badge moved off the emphasis axis onto `coverageGaps`**, which was the one real mechanism consequence of the precedence ruling: a selected gap node reads `'focus'`, so a badge derived from the emphasis class disappears exactly when a reader selects the gap they are inspecting — and GC11 ran under Coverage with `focus.nodeId: null`, so **no hook could see it**. GC11 now runs **both** states and fails **five** distinct ways (badge from `emphasis`; badge on every node; badge keyed on the id prefix, caught because the neither-list pair is `kb:` + `int:`; badges permuted across lists; badge equal to a kind glyph). `gapBadge` was deliberately made a **sibling** of `emphasisDraw` rather than a key inside it — "a `badge` key inside a structure named `emphasisDraw` would be grammatical and false", which is this work's proxy lesson applied to a field name. **141 distinct feature-007 anchors re-pointed** via a shift map derived from `git diff -U0` against the 1,992-line revision the old anchors were verified against, every one checked in-range and off blank lines. Two ranges needed correcting **beyond** their mechanical shift because the shifted target was a blank line, and one rule's shift was `+19` not `+10` — caught by that blank-line check. **Judgment calls that went beyond the brief and were right to:** GC08 was amended although unlisted, because under the new preference route an emulation no longer reaches the module directly and leaving GC08 as written would have left the seam **reading as tested while untested**; and two inventory rows were added, since the SPEC gained a consumed store surface and lost a responsibility, and the two inventories that exist to enumerate exactly those would otherwise have been silently incomplete. |
| 2026-07-30 | **Orchestrator error 4 (a pattern, named once) — relaying agent-reported line numbers as verified** | -- | Recorded because it is now the **fifth** instance of one shape and the pattern matters more than any single case. Resuming the stalled feature-008 sweep, the orchestrator supplied a list of feature-007 anchors described as "already verified on disk by feature-007's re-gate reviewer this session". **Three were wrong**: D10's density row is `:1451` (given `:1454`), § API Contracts are `:1656`/`:1660` (given `:1657`/`:1661`), and the given D3 range `:609–616` would have landed on a **blank line**. Root cause: the reopen author's report and the re-gate reviewer's report **disagreed by 1–3 lines** on several anchors, and the orchestrator merged both without reading either against disk. The sweep agent **used the disk and reported the corrections** — the fourth time in this session a dispatched agent has correctly refused an orchestrator premise. **Standing correction:** cite only anchors read first-hand, or mark them explicitly unverified so the recipient knows to check. The earlier instances of the same shape: the missed fourth inbound citation (error 1), the 119-minute figure (error 2), the grep-count false negatives on feature-006 (error 3), and the invalid `edgeEmphasis` occurrence-count derivation propagated into two briefs. |
| 2026-07-30 | feature-009 impact sweep — **net −2 lines**, verified | -- | Ratified rather than corrected: its Open Item 5 was answered **with** its own stated assumption, so `AC-S5`, `AC-S8` and `TV18` are **confirmed**. The only substantive edit was **provenance** — three sites re-attributed from "this feature's assumption" to the upstream contract, substance unchanged. Three of the four upstream decisions needed **no change, each stated explicitly rather than silently**: it reads no preference (its motion claim is unconditional, strictly stronger than a preference-gated one), emits no zoom control, and no clause depended on a renderer-side density exemption (swept "exempt": three hits, all unrelated). **All 83 line-number tokens in the document were enumerated and resolved on disk**; 14 sites held stale feature-007 anchors over 6 distinct anchors — 10 re-pointed, 3 retired with the closed item, and **1 deliberately de-numbered** because re-pointing it would have made the citation land on the very line that now contradicts the claim it supports. `GV` cites were re-checked **for meaning, not position**, since feature-007 appended GV27/GV28. Orchestrator verified all six re-pointed anchors on disk. One pre-existing MINOR **exposed rather than fixed** for item 9: its Open Item 4 claims feature-011 carries feature-007's Open Item 4 "against the same file", but feature-007's is against `contrast-check.mjs` while this item's subject is `validate-html-output.sh` (all 13 of feature-007's items swept). |
| 2026-07-30 | **★ feature-008 PASSES — B- (Q24 item 6 COMPLETE; Wave 3b done)** | **B-** | Five cycles: **C- → C → C → C → B-**, MEDIUM count 6 → 4 → 4 → 2 → **0**. 35 ledger rows: 28 `Fixed`, **7 `Pending` (all LOW)** deferred under Q27. 365 → **770** lines. **The decisive discovery of Wave 3b, and it was invisible to four consecutive gates: the wrong-content adversary.** A canvas publishing a *fully populated, internally self-consistent* record whose **per-id content is wrong** — glyphs permuted between ids, or an encoding keyed on the **id prefix** rather than `Kind` — **passed all nineteen hooks**. That is Q21's proxy class, the exact defect this entire work exists to prevent, shipping green through a complete test suite. Root cause: GC13 compared `glyph` to `KIND_ENCODING[kind]` where `kind` was **the record's own sibling field**, and `nodeEncoding`/`edgeEncoding` appeared in **no hook at all**. Closed by binding every mark entry to the `ViewModel` entry for **its own id or key**, with the discriminating fixture **mirroring feature-007's own AC-S3 construction** (two `ext:` nodes, one `web-page` and one `image`) over the draw record rather than the projection — complements rather than duplicates. Post-fix the adversary fails GC13 on both variants, GC10 on the prefix variant, GC12 on a wrong transform; the reviewer independently ruled **all sixteen remaining passes genuinely content-free by subject**, including the two that *delegate* (GC11, GC14) — a delegation being only as sound as GC13, which quantifies over every id and key. **A refusal worth recording:** the author **declined** a suggested third-lens carrier for GC14's edge order, because `edgeEmphasis` occurs in feature-007 at exactly two lines so **D6f is the only clause assigning any edge class**, and D7a's "dims the rest" composes into `nodeEmphasis` alone — asserting `'dimmed'` edges under `emphasis: 'none'` would have **invented frozen-SPEC behaviour**. `'normal'` co-occurs with neither other class in any projection, so the edge `'dimmed'`-vs-`'normal'` order is recorded as **unreachable rather than unasserted** — a fact stated, not a step dropped. Cycle-5 delta: **+1 line**. |
| 2026-07-30 | **★ feature-009 PASSES — B against the B- bar (Q24 item 6, half complete)** | **B** | Three cycles: **C → C → B**. 17 ledger rows — **13 `Fixed`, 4 `Pending` (2 LOW, 2 MINOR) deferred under Q27**. 375 → **692** lines. **Zero CRITICAL, zero HIGH, zero MEDIUM**, so it clears B-. **The grade change is what closed it:** under the old A+ bar this needed at least two more cycles for four findings that change nothing an implementer builds. **The vacuity audit found a nineteenth instance the author's own sweep missed** — `TV15`, AC-S7's **sole** hook, still passes against an implementation that renders nothing, because its only positive clause is a conditional over rendered cells; six sibling rows in the same table already name their fixture condition, so the stronger form was available in this SPEC's own vocabulary. Deferred as LOW, and the sharpest item on the item-9 list. Also deferred: the **edge-axis analogue of the precedence gap** — `edgeEmphasis` gives one key one value with no upstream precedence between `'chain'` and `'dimmed'`, and D6a's Provenance patch (feature-007`:808`) **does not clear `focus.nodeId`** the way `:805–806` do, so Provenance-with-a-live-selection is one gesture away. Rated LOW correctly: no antecedent goes vacuous, no gesture is lost, D3's mapping stays total. **Two upstream claims independently confirmed:** row 8's GV22 grounding is sound — feature-007`:1795` is a genuine *instance* of "the resolved focused id carries `'focus'`" and the reviewer read every `precedence` / "takes priority" / "dims the rest" occurrence in feature-007 to confirm **nothing ranks a coverage class above `'focus'`**, so the silence is real rather than a missed citation; and `component-css.css:67`'s `html { scroll-behavior: smooth }` is real, so per CSSOM-View a default-`behavior` `scrollIntoView` **would** have animated the reveal — which is why `behavior: 'instant'` is normative, and `'instant'` is a real `ScrollBehavior` enum member the CSS property itself does not accept, making the JS option the one route no CSS grep can reach. |
| 2026-07-30 | **★ OWNER DECISION — freeze exception 1 widened to a FOURTH seam: `nodeEmphasis` precedence** | -- | Found by feature-009's cycle-2 gate; same class as the other three (feature-007 naming an obligation and leaving the rule a consumer needs unstated). **The gap:** `nodeEmphasis` is `Map<id, 'normal' \| 'dimmed' \| 'kb-unbacked' \| 'artifact-undocumented' \| 'focus'>` — **one class per node** — while **two independent inputs produce classes**: `LensState.emphasis` (`'coverage'` / `'provenance-chain'`, which marks gap nodes and dims the rest) and `LensState.focus.nodeId` (which marks the selection). feature-007`:580` asserts "**the two compose in `nodeEmphasis`**" and **never states how**. Note the asymmetry that makes this an omission rather than a design choice: feature-007 **did** settle the neighbouring precedence — GV22 (`:1795`) rules that a `section` which is `focus.nodeId` when the fold applies leaves `visibleNodes` with `'focus'` moving to its document — so fold-vs-focus is decided and **coverage-vs-focus is not**. **The concrete failure:** with Coverage active, clicking an undocumented source file makes that node qualify twice; if the composition resolves to the coverage class then **no node carries `'focus'` at all**, so feature-009's reveal never fires, the `selected` badge never renders — and that badge is **AC-S5's text carrier**, so a screen-reader user loses the only indication of what they selected — and `AC-S8`'s antecedent is **vacuously satisfied so `TV18` passes green**. An ordinary action, silently doing nothing on the accessible surface, with the suite reporting success. **Why the fix is near-free, and why that argues for doing it now rather than later:** both facts are *already* published independently — the gap set as `coverageGaps: {kbUnbacked, artifactUndocumented}` (`:627`) and the selection as `focus.nodeId` (`:578`, marked `both`) — so **no information is lost whichever way precedence goes**, and a renderer wanting both can draw the badge from `coverageGaps` and the focus treatment from `focus`. **Owner ruling: `'focus'` takes precedence in `nodeEmphasis`; gap marking is read from `coverageGaps`.** One clause, no new field, no mechanism change. **The cost of leaving it open was the deciding factor:** features 008 and 009 already read the same field and would each have picked a precedence, making **AC-7 and AC-8a** ("each applies to **both** renderings") unverifiable — a parity defect that only materialises once both renderers exist, i.e. during execution. |
| 2026-07-30 | Wave 3b cycle-2 gates — **008 C, 009 C**; both in cycle 3 | **C / C** | Both closed every cycle-1 finding (**15/15** and **7/7**, no `Recurred`), and both drew new findings **concentrated in the prose their own fix added** — 008 +30 → 7 new, 009 +15 → 6 new. Converging, but the correlation is now observed on four consecutive features. 008's +30 delta was **ruled justified** by its reviewer and its new group-attraction mechanism was attacked four ways and held. **A NEW DEFECT CLASS, and the most important methodology finding of Wave 3b: the vacuous hook.** feature-008's `GC13`/`GC14` **passed while the behaviour they assert was absent** — the emphasis redesign chose stroke weight as its forced-colours ordinal channel, justified as "free because no relation property uses it", but that premise is **edge-scoped and was never re-derived over feature-007's node glyph table**, where six of seven kinds are *filled* shapes with no stroke to grade and the seventh (`web-page`) **is** a stroke, so raising weight closes it into `document`'s filled circle. Field-equality on `marks[].glyph` kept both hooks green regardless. feature-009 produced the same class independently: `AC-S8`'s antecedent can go **vacuous** when no id is `'focus'`-marked, so `TV18` passes when the reveal never fires. **Consequence, now standing in every fix brief: run a vacuity audit over every assertion — "would an implementation that does nothing at all pass this?" — because a hook that passes on absent behaviour makes a green suite meaningless, and it is invisible to a gate that only checks each hook reads a declared field.** Both reviewers also confirmed a shared limitation: with the re-spec uncommitted, neither could diff its own subject, so "which prose is new" rests on the dispatch account (the cost STATE.md E9 records). |
| 2026-07-30 | **★ OWNER DECISION — freeze exception 1: feature-007 reopened, scoped to three seams** | -- | The first exercise of Q26 § Freeze. feature-008's gate confirmed **two mechanism defects in frozen feature-007**, both verified on disk, and the owner elected to **reopen scoped to exactly three seams — nothing else**. **(1) The density exemption is unimplementable under feature-007's own contract**: thinning happens in `project()` (D3`:572`), the canvas draws `visibleNodes` (D4`:617`), consumer rule 1 (`:1653`) forbids a renderer deciding membership from `LensState`, and D3`:604–606` interprets the lens exactly once — so a canvas-side exemption would have to re-add nodes `project()` removed. **And feature-007's own D10`:1432` decides it the other way** ("thinned at `2`–`5` like any node below the threshold"), contradicting D1a`:386–387`: a self-contradiction inside a gated A+ SPEC. **(2) `prefers-reduced-motion` / `forced-colors` have no carrier** — absent from all fourteen `LensState` fields (`:569–582`) and all nineteen `ViewModel` fields (`:616–634`), `project()` is pure with no DOM (`:610`, rule 2 `:1656`), and the store surface (`:1636–1644`) exposes no preference getter, **yet D5d`:792` and `:1757` assign detection and exposure to feature-007 itself**. NFR-4 is a requirement, so this is not cosmetic. **(3)** reset-to-fit and the zoom step factors need a shell/canvas interface no document names — the values live only in canvas-private `positions`. *Note the reviewer's finer ruling: `CONTROL_MANIFEST` itself is **already satisfied** (D8`:1121–1128` authors zoom/pan keyboard equivalents with `requirement: NFR-6`), so feature-008's "may need no change at all" is the part that was false.* **Rationale for reopening rather than carrying as debt:** feature-007 is the shared authority for 008, 009 **and the un-authored 010–013**, so a self-contradiction there propagates to six features — and this work has already paid four times for a stale or contradictory shared input (Q20, Q22, Q25, and feature-007's own missed Q21). **Sequencing, deliberately serialised:** the reopen is **NOT dispatched while 008 and 009 are mid-fix**, because both read feature-007 as a fixed input and feature-008's interim positions are built on the current text — editing it now would invalidate in-flight work, which is the exact wave-ordering defect that produced both of feature-006's HIGH findings. Order: land 008's and 009's fixes → reopen feature-007 for the three seams → re-gate → targeted impact sweep of 008 and 009. |
| 2026-07-30 | **★ FREEZE — features 001–007 all gated A+ (Q24 item 5 COMPLETE)** | **A+** | The 001–007 spine is **frozen** per Q26 § Freeze. Grades: feature-001 A+, feature-002 A+, feature-003 A+ (reopened for Q20's loader sync, re-gated over three cycles), feature-004 A+ (reopened for Q22's `qualifier` map, confirmed), feature-005 A+, feature-006 A+ (five cycles), feature-007 A+ (four cycles). **After this point a change to any of the seven requires an explicit owner decision — not an automatic reopen.** A downstream feature that finds a genuine mechanism defect in a frozen SPEC still reports it (that reporting is what has been working), but the owner decides: fix now, defer to the editorial pass, or carry as tech-debt against the shipped design. Without this the six remaining features could each reopen any of the first seven and the sequence would have no fixed point. **Editorial queue carries nine items (E1–E9), all batched for Q24 item 9.** Next: Wave 3b — **AUTHOR FRESH** features 008 and 009 against the frozen spine (Q26 § Fresh authoring — the old pre-decision SPECs are checklists of concerns, never base documents). |
| 2026-07-30 | Routed: a real defect in `canonical/`, found by feature-007's gate | -- | **`canonical/aid/scripts/summarize/validate-html-output.sh` documents behaviour it does not implement.** `--help` (`:9`) says "Resolve relative .md links against this dir" and the header comment (`:28`) says "every `href="./X.md"` exists in --kb-dir", and the help branch at `:38–40` prints exactly those lines — but `KB_DIR` occurs at only three sites (`:35` default, `:43` flag, `:384` progress echo) and never in the resolution, which is `HTML_DIR=$(dirname "$HTML")` at `:62`, consumed at `:391`. So `--kb-dir` **sets no resolution basis at all**. Found because feature-007 cited the flag as its authority for AC-9's mapping and a reviewer read the script rather than its help text. `[CODE]`, OOS to this work — recorded in ledger row 34's evidence. Fix is either correcting the help text or wiring `KB_DIR` into `:391`; **not** work-005's to make. |
| 2026-07-30 | **A+ gate feature-007 — first pass E+**; fix dispatched | **E+** | 21 counted (1 CRITICAL, 6 HIGH, 7 MEDIUM, 5 LOW, 2 MINOR) + 1 OOS. **Q26 split: 15 mechanism, 6 editorial** (+ the OOS). First gate in this work to run against a **fully frozen A+ spine** (001, 003, 004, 005, 006). **Root cause identified, and it explains the framing cluster: this SPEC never consumed Q21.** Its change log cites "Q9–Q20" and § Source stops at Q19/Q20 — yet **Q21 is the owner's ruling on feature-007's own two findings**. So D6d quotes FR-13's **superseded** wording and Open Item 2 routes the lens narrowing as an *unmade* author decision the owner had already made. **The CRITICAL is an unapplied owner decision, not a design error:** Q25 item 2 moved `RELATION_CATEGORY` into `coverage-predicate.mjs`, but the constant still sits in browser-only `graph-model.js` (`:291`, `:1334`, `:1434`) and is absent from the export table (`:1105–1110`) — leaving gated feature-006's F6 counter, AC-G5, GL12 and GL17 **unimplementable**, exactly as Q25 predicted. **AC-15's view side is SATISFIED** — verified clause by clause against feature-006's D6/D6a (`artifact-undocumented` keyed on `kind`, the sorted union `R ∪ G`, `ledgerOnly = (G ∩ T) \ R` so `orphans` cannot fire the alarm, `kb-unbacked` lens-only): **no finding raised against it**, the mutual obligation is met from both sides. Six findings are **expired citations into upstreams re-specified after this SPEC was drafted** (`clause`→`qualifier`; an Open Item naming feature-004 as reopened when feature-004 refuted it; a selection feature-006's D2a already made; `detect-kb-gaps.sh` and "shape (a)"; "two reopens" when it is four; § Source omitting feature-006). Reviewer falsified one finding **by execution** rather than reading — re-running the script's own regex over both the canonical CSS and the live `kb.html` — and declined three candidates after verifying them. One check honestly left unrecorded: whether the graph's `--gk-*`/`--gc-*` dark values get checked once feature-011 parameterises the extractor is **unverifiable today**, since neither `graph-css.css` nor the parameterised call exists yet. |
| 2026-07-30 | **A+ gate feature-006 — CLOSED at A+ (Q24 item 2 COMPLETE)** | **A+** | Five cycles: **D → D+ → B+ → B+ → A+**. 25 ledger rows — **23 `Fixed`, 2 `OOS`, 0 counting**. Grew 1,162 → **1,426** lines. Row 25 verified `Fixed`, and the gate re-derived the load-bearing inference itself rather than accepting it: given only snapshot S(N−1), present→present is `Pending` and present→absent is `Fixed` (both straight from D5`:512`), while **absent→present is either a first-time gap or a `Recurred` whose prior `Fixed` was written at run N−1** — separating them needs S(N−2) or that run's ledger `Status` column, neither of which a single-snapshot stash holds. So `Fixed` is decidable and `Recurred` is not. Class sweep re-derived from the **class**, not the token, and confirmed complete with **no fourth site**; it also verified that D7 obligation 2's "feature-007 already reads it" is **not** a second instance of row 2's "already exports" defect, because feature-007 genuinely does read `kb_gaps` (its `:294`, `:1162–1196`, `:1296–1299`). Both left-standing candidates upheld, with a stronger ground than the author's: `:801` already marks the reviewer-reaching obligation **"Not met"**, so the document claims no obligation it cannot meet. Two further candidates examined and declined inside the evidence cell — the fifth consecutive reviewer to decline rather than pad. **Cost of the five cycles, worth recording:** the two cycle-1 HIGHs were wave-ordering artifacts, cycles 2–3 found only defects in prose that earlier fixes had written, and cycle 4's sole finding was **pre-existing** text no gate had caught in four passes. |
| 2026-07-30 | **feature-006 cycle-4 gate — B+** (rows 23–24 `Fixed`); one new `[LOW]`, fix dispatched | **B+** | Tightly scoped gate (rows 23–24 + the 13 new lines only; three prior reviewers had each read all 1,415 lines). Both fixed, verified at source. **One new `[LOW]` mechanism finding, and the reviewer was candid that it is NOT in the new prose** — it is pre-existing text, so the three-cycles-running pattern is broken. **Row 25:** D7's cheaper-alternative paragraph (`:824–826`) and Open Item 2 (`:1191–1193`) both claim a stashed `kb_gaps` "would give `--previous` an input" and "restore the Status transitions". Both halves are false against this SPEC's own text: `--previous` takes its own prior **ledger** (`:198`, `:816`, L2`:1023`), and `Recurred` is defined at D5`:511` as a node that was `Fixed` and is uncovered again — so it needs the previous ledger's **`Status` column**, while `kb_gaps` is four keys with **no status** (L3`:1088`, D6`:633–640`). From one snapshot: present→present `Pending`, present→absent `Fixed`, **absent→present indistinguishable between a first-time gap and a recurrence**. So `Fixed` is derivable and **`Recurred` is not, under any single-snapshot stash**. Nothing built depends on it (the option is unadopted, and the fix *strengthens* the decline), but it mis-sizes a live owner decision at `:1196–1197` and feature-010's Wave 3c re-spec will read it. **Why cycle 3's sweep missed it:** that sweep keyed on the *printed command*; the real class is **a capability claim about a mechanism, stated without checking the mechanism's declared inputs** — this SPEC's own `:1396` lesson, sweep for the shape not the token. The reviewer also corrected the prior ledger's own evidence on disk (feature-013 is **not** unauthored — a 293-line pre-decision draft exists — but is **ungated**, which is the basis the conclusion actually needed) and declined two further candidates after verifying them. |
| 2026-07-30 | **feature-006 cycle-3 gate — B+**; fix dispatched | **B+** | All 6 cycle-2 findings verified `Fixed`, rows 1–14 re-verified, **no `Recurred`**. Two new: **row 23 `[LOW]` mechanism** — `:104` and `:550` claim the interim reproduce path regenerates the ledger *from* the durable `kb_gaps` carrier, but the printed `/aid-graph --reset` re-runs the pipeline and **overwrites** `kb_gaps` rather than reading it (feature-010`:138`, L2`:1029`); D7 obligation 3 already states it correctly, so the document asserts it two ways. **Row 24 `[MINOR]` editorial** — Open Item 8 routes into gated REQUIREMENTS with no reopen disposition while the preamble promises "each such item says so". Both in prose earlier fixes added — the pattern has now held **three cycles running**. Row 16's nine-item sweep **re-derived independently and upheld**: exactly two live reopen consequences, both feature-003, both unrefuted (item 6 needs an extension-format carrier against D4`:934`'s fixed key set; item 7 needs a fourth reserved frontmatter key against D8`:1640`'s enumerated three). No feature-003 citation drifted against the frozen file. The reviewer caught **its own** false positive mid-check — a substring grep matched `source-arti`**`fact->source-artifact`** — and re-derived the 13-candidate enumeration with exact token matching, getting 13 with the 10/3 split. Two candidates declined after verification. |
| 2026-07-30 | feature-006 cycle-2 fix complete (**+13 lines**) — awaiting cycle-3 gate | -- | All six closed in **+13** against a +65 bar; one new prose block, the rest in-place clause surgery. Row 16's fix **adopts feature-004's composed ownership verbatim** rather than authoring a competing one — feature-004 is named the source with **no reopen**, while feature-003 **keeps** its reopen consequence (a genuine D4/D8 change). Class sweep confirmed only **two** live reopen consequences survive, both at feature-003, both **unrefuted on disk** (feature-003's only four mentions of this feature address neither) — so no third instance of the false-reopen class. Row 19 resolved the other way from the guess in the brief: **D5's string was right and GL13's suffix was short a `)`**. Beyond the six, the author gave every bare `Q20` its subject suffix across 7 sites at zero line cost, closing the ambiguity flagged the same day. § Figures now sweeps to **zero** unit-bearing measured quantities, with the non-instances ("fifty gaps", "five hundred") confirmed hypothetical **by reading, not counting**. |
| 2026-07-30 | **Orchestrator error 3 — verified by counting, again; the fix author caught it** | -- | Recorded because it is the **same class as error 1 the same day**, and because the standing rule it breaks is one this orchestrator had just quoted to three reviewers. On resuming the 529-interrupted fix author, the orchestrator reported rows 16, 17 and 20 as "**still present on disk**" from `grep -c` counts. **All three verdicts were false.** Read rather than counted: rows 16 and 17 matched only the new change-log entry **quoting the withdrawn claims in past tense** (this SPEC's established annotate-rather-than-delete practice, which cycle 1 was credited for following), and row 20's surviving `its line 104` is the **corrected** citation — the author had swapped the wrong *section label* and kept the correct line. The file was already at its final 1,402 lines when the check ran; the 529 struck during read-back only, so **all six edits had already landed**. This is exactly **Q20 (A-5 figure)**'s documented failure mode — *"to verify a figure is gone, read every occurrence; a count of occurrences is not evidence about their nature"* — and Q23's third instance one level up. **The author declined to comply and pushed back with evidence rather than re-applying finished work**, which is the behaviour that prevented a double-application; the author's added one-clause reading note now names the hazard inline. Two orchestrator *instructions* were also wrong and correctly overridden: (i) "cite the real line for § File Header Convention" would have replaced a wrong label with a **false claim**, since that section (`coding-standards.md:61`) requires a full header block "not just a shebang"; (ii) the brief presumed GL13's string was the correct one. **Standing consequence:** when verifying that a string is gone from a document that *quotes its own withdrawn text by convention*, `grep -c` is structurally incapable of answering — read every hit with its line number, or the annotate-not-delete practice guarantees a false positive. |
| 2026-07-30 | feature-003 cycle-2 fix complete — **awaiting cycle-3 gate** | -- | All six closed in **+65 lines** (1,966 → **2,031**) with exactly one new prose block — the minimal-addition instruction, given because every cycle-2 finding on both features was in prose a cycle-1 fix wrote. Class sweeps found **five siblings the ledger had not cited**: row 9's exposure line was short **two** keys, not one (`definition` as well as `passes`, plus the same omission in D4's fields bullet); row 7's orientation defect recurred in the **partition predicate** in the same paragraph ("whether the relation appears on any row at all" → "either relation column"); and row 11's class covered **two pre-existing cycle-0 fixture gaps** (a label breaking `[a-z][a-z0-9-]*`, a restricted-subset violation). Author removed **two of its own** cardinality numerals before handoff. **The substantive change, and its judgment call worth recording:** the ledger suggested feature-005's "compute from the map rather than from emitted rows"; the author **declined it with a reason** — W4 *is* observed coverage of an emitted table, so computing from the map would make it W3 — and instead accumulated **pair-level over both readings a row asserts**, achieving the same orientation-invariance. It then surfaced rather than buried the consequence: **feature-001 `:491–497` prices W4 at "one set insert per row"; pair-level makes it one per *reading*, two per row** — recorded inline as a **cost note, not a contract change**, so feature-001 remains the fixed input under Q18 ruling 3. That is the correct way to handle a gated input you have made more expensive: state it, do not silently contradict it, and do not reopen it for a non-contract figure. |
| 2026-07-30 | **feature-006 re-gate — 14/14 cycle-1 findings CONFIRMED Fixed; new prose graded D+** | **D+** | Every one of the 14 counted cycle-1 findings verified resolved **at the source it cites, not against the author's report** — the check that exists because an author's self-report is what carried the original two HIGHs. 6 new findings in the added prose (**1 HIGH**, 1 LOW, 4 MINOR) → **D+**. The HIGH is **the same false-reopen class as cycle-1 row 1, one Open Item over**: Open Item 7 still asserts "**both gated A+; scheduling reopens and re-gates both**" for feature-003 *and* feature-004, but feature-004's Open Item **13** (`:2315–2325`) reconciles all three owner records and concludes "**it needs no change here and makes none** … on the composition above this SPEC is not one of them" — and feature-006's own `:1303` already says "No reopen of feature-004 is scheduled or needed", so the document contradicts itself. The fix author read feature-004's Open Item **14** in detail and **stopped one item short of the paragraph that refutes its own item 7**. Also: GL20 attributes a no-ticket obligation to AC-13, which is only "No KB file is modified by any run" (the obligation is REQUIREMENTS:166 §4, which § Source cites correctly); one feature-003 line cite drifted under that SPEC's own re-spec; GL13's asserted `Description` ending disagrees with D5's zero-row form (the only **mechanism** row); a `coding-standards.md` line cite lands on the wrong section; and the "ninety minutes" figure is both a measured quantity that falsifies the SPEC's own Figures claim **and wrong** — see the two orchestrator errors below. The reviewer also **declined four candidate findings** after verifying them (the numbering note reproduces the on-disk order exactly when applied in order; the relative import resolves; the GV01 framing mirrors feature-007's own; "31 pairs" is a contract count) — the Q23 posture working in the direction that costs nothing. Prediction tested and largely upheld: feature-003's re-spec falsified **exactly one** thing in feature-006, a line range — its `endpoint_kinds` reasoning was written kind-keyed and was *strengthened* by the re-key, and D2a's "enumerated, not sampled" claim was independently re-derived from feature-001's 31 pairs to **exactly** the 13 tabled candidates with the 10/3 split correct. |
| 2026-07-30 | **Two orchestrator errors, found by the re-gate** | -- | Recorded because this work's Q-log is candid about whose defect is whose. **(1) The renumbering cross-check missed the fourth inbound citation.** feature-004`:2326` cites "feature-006's Open Item **2**" for the `qualifier`-mapping discharge; after the renumber that resolves to the unrelated declined-restoration item. **The line was present in the orchestrator's own grep output and was mis-analysed** — reasoning that the *old* item 2 was closed, without noticing that the citation now lands on the *new* item 2. The check ran and its evidence was read wrongly, which is Q23's exact failure shape one level up: not a truncated search, but a correct search whose output was classified by assumption. Routed to the **editorial queue as E1** (low harm, resolves by subject) rather than reopening gated feature-004 — Q26 applied to the orchestrator's own defect. **(2) A wrong measured figure, propagated.** Q25 asserted "ninety minutes" between feature-006's drafting and feature-004's fixes; 21:30 → 23:29 is **119 minutes**. It was wrong, and it should never have reached a feature SPEC at all, since that SPEC's Figures claim forbids measured quantities. Q25 corrected in place with the correction annotated; the SPEC's copy is charged as ledger row 21 and is being removed rather than corrected. |
| 2026-07-30 | Orchestrator corrections applied ahead of cycle 2 | -- | Four surgical fixes made directly, so both fix authors read settled files: **(a)** REQUIREMENTS **FR-4** corrected — "the same **five** inverse-pair rules" (naming five) → "the same cross-entry inverse-pair rules … **this list is the authority, not its length**" enumerating all **six** including pair coherence. Classified **mechanism**: an extension author reading the old text would apply five rules and silently omit pair coherence. This reopens REQUIREMENTS' A+ a **fourth** time, for one line, applying the count→citation remedy REQUIREMENTS had already adopted elsewhere. **(b)** Q25's 119-minute correction. **(c)** A disambiguation blockquote over the **two entries both numbered Q20** — flagged by the re-gate as making every bare "Q20" citation ambiguous by inheritance; neither renumbered (both are cited by number across SPECs), with a mandatory suffix convention going forward. **(d)** New **§ Editorial queue (Q26)** opened with **E1**, giving the item-9 batched pass a real home instead of leaving editorial items scattered across per-feature ledgers. |
| 2026-07-30 | **feature-003 re-gate — Q20's four items CLOSED; new prose graded C** | **C** | All four loader items independently verified closed at their lines, and **Q20 is dischargeable**: the reviewer confirmed the loader can no longer reject the vocabulary by checking that all **34** distinct `<kind>-><kind>` tokens in feature-001 have both sides in `relationship-schema.yml`'s `kinds:`, and all **69** distinct standard tokens match the `derived_from` grammar. The original 6 ledger rows all re-verified `Fixed` at their shifted locations — **no `Recurred`**. But the fix added 153 lines and **6 new findings landed in that new prose** (3 MEDIUM, 3 LOW; 0 CRITICAL, 0 HIGH) → **C**. All six classified **mechanism** under Q26, so they are fixed now rather than batched. Two verified by the orchestrator before accepting: **(row 7)** V12's new unobserved-token accumulation is **not orientation-safe** — D7 (:1259–1267) swaps the `(Id, Kind, Name)` triples **and** the `S2T`/`T2S` labels, and rows are *emitted* normalised, so a swapped row accumulates the **inverse** relation's token and the forward token reads as unexercised on ~half of every asymmetric pair; feature-005 (:1177–1180) meets the identical hazard and routes around it by computing "from the map rather than from emitted rows". **(row 9)** `rel_load_vocabulary`'s exposure list omits `passes`, which feature-005 (:642–657) reads through this loader. Also: pair coherence's `derived_from`/`passes` "equal" is undefined as sequence-vs-set while the transpose clause beside it *is* element-wise (row 8, a gating exit-2 verdict left implementation-defined); the stated residual names AC-S2 as catching a mistyped standard key when AC-S2 is **core-scoped**, so an extension's is caught by nothing (row 10); no rejection-class fixture for the `derived_from` token grammar though the other three clauses each got one (row 11); and category-name uniqueness folded into property 5, which feature-001 (:595–602) says property 5 does not cover (row 12). Reviewer verified ~20 feature-001 citations, 4 `canonical/` script citations and 10 KB line citations — **every one resolves exactly** — and correctly reported two things it could **not** do: no test suite exists to run (feature-003 ships no code yet, so fixture claims are reviewable only as specification), and it did not re-derive feature-001's vocabulary content against the six standards, checking only its *interface* with this loader, since feature-001 is a fixed input under Q18 ruling 3. |
| 2026-07-30 | REQUIREMENTS defect found by feature-003's re-gate (**OOS, queued**) | -- | Ledger row 13 `[MEDIUM]` OOS: **FR-4** (REQUIREMENTS.md:293–294) still says extension pairs satisfy "the same **five** inverse-pair rules" while **six** now bind after pair coherence landed — a Q17 count-as-proxy at the requirements level, and the remedy is the one REQUIREMENTS already adopted elsewhere: cite the set, never a numeral. Classified **mechanism** under Q26, not editorial: an extension author reading FR-4 would apply five rules and omit pair coherence, so the numeral changes what gets built. Under Q18 ruling 3 this reopens REQUIREMENTS' A+ a **fourth** time, for one line. **Owner: the work owner.** Not applied yet — deliberately deferred while feature-006's re-gate reviewer is still reading REQUIREMENTS.md; editing an input mid-review is the mistake this session has been avoiding all along. |
| 2026-07-30 | feature-003 loader fix complete (Q20) — **awaiting re-gate** | -- | 1,813 → **1,966** lines. Of feature-001's four routed items, **two were fully owed** (the `endpoint_kinds` prefix→`Kind` re-key, and V12's re-key plus its unobserved-token advisory) and **two only partly** — items 1 and 3 were owed a table row, a value rule and the pair-coherence property itself, but **not a single count edit**, because this SPEC's earlier Q17 count-as-proxy sweep had already replaced those numerals with citations ("this list is the authority, not its length"; "**every declared** key is validated"). The standing rule held under pressure: no clause added says "eight". Author self-caught two of its own regressions before handoff — it had reintroduced `Kind`-enum cardinality numerals ("3 × 3 to 7 × 7", "49-token space" ×2), exactly what the Q17 sweep removed, now citations to feature-001 :387–389; and had put a count in the fixed `Checked: N rows \| Findings: M` trailer. It also **declined to ship an unverified claim** — that "three sibling SPECs cite Open Item 12" — on finding that feature-002's and feature-004's Open Item 12s are their own, and only feature-001 cites feature-003's. Orchestrator spot-verification: 1,966 lines; the 3 surviving `"kb:->kb:"` strings are all narrative (the old form, the defect, Open Item 12's history) with no live rule or example; V12 re-keyed and still `[LOW]` in both directions with `V1`–`V15` all intact; pair coherence present and **gating** ("Any violation → exit 2"), stated as transpose for asymmetric and closure-under-transposition for symmetric; zero reintroduced cardinality numerals. **Open Item 12 closed in place with its number retained** — the opposite call from feature-006's renumber, and correct for the opposite reason: feature-001 cites it by number four times. |
| 2026-07-30 | Renumbering cross-check — **one broken inbound reference found and fixed** | -- | feature-006's fix renumbered its Open Items while feature-003's fix deliberately refused to; both calls were right for their own file, which made a check mandatory rather than optional. Enumerated every inbound citation to feature-006's item numbers across the whole work: feature-004's **three** citations to "feature-006's Open Item 7" (:13, :63, :2293) still resolve, because only old item 3 → new item 2 moved and items 4–9 kept their numbers. **One reference was broken, and it was the orchestrator's own** — Q25's citation of "feature-006's Open Item 3" for the declined partial restoration, written before the renumber and now pointing at the new feature-010 item instead. Corrected in place, annotated with the move. Recorded because it is the Q20 hazard committed by the very entry that names Q20: a cross-reference outlives the text it cites unless someone checks, and the fix author's numbering note was a warning, not a verification. |
| 2026-07-30 | feature-006 fix pass complete — **awaiting re-gate** | -- | All **14** counted findings closed, none deferred, none judged invalid; 1,162 → **1,389** lines. Author also closed **6 defects of the same classes that the gate did not raise**, rather than leaving one instance of each — including **three further copies of F2's false necessity claim** (D2 condition 1, D2a's `documents` verdict cell, Open Item 9), which is the fix-everywhere discipline working. Proxy sweep re-run: rows 6 and 9 extended, **five rows added (14–18)**, with the author's own note that all five came from the gate rather than from its sweep, and the lesson stated — *sweep for the shape, not the token*. Orchestrator spot-verification before accepting: only the target file was written (no stray edits); all three surviving "already exports" mentions are non-live (change log, an explicit withdrawal, and the sweep row quoting it); no live reopen-and-re-gate aimed at feature-004 survives; both `kb_gaps` entries now agree at `entry-point`/`HIGH`; the directory id carries its trailing `/`; Open Items = 9, `GL01`–`GL20` contiguous, sweep table = 18 rows. The author also corrected an imprecision in the orchestrator's own brief — `coverage-predicate.mjs` is **inlined byte-identically** in the browser, not imported. Ledger Status deliberately **left `Pending`**: only the verifying reviewer may mark a row `Fixed`, since an author's self-report is exactly what the two HIGHs passed through. |
| 2026-07-30 | Q24 items 2 + 3 dispatched **in parallel** (fix authors) | -- | feature-006's 14-finding fix and feature-003's loader reopen run concurrently on **disjoint files**. This is **not** a breach of Q26 § Dependency-ordered gating — that rule forbids *gating* downstream of a known-open upstream, and forbids *drafting* against a moving sibling. Neither applies, and the exemption was **verified rather than assumed**: feature-006 takes no runtime dependency on the loader (its SPEC.md:365 "**GV04** asserts the two are equal. It therefore **needs no loader**"; :1064 `coverage-bearing.yml` "no loader reads it"; :320 is already written to hold "**in either reading**" of `endpoint_kinds`), and the citation sets are disjoint — feature-006 cites feature-003 **D1/D1a/D2/D8**, while the four loader items touch **D4/D9/V12**. Item 3's closing impact sweep of feature-006 therefore has a predicted result of *no change*; it is run anyway, because that prediction is exactly the kind of claim this work has learned not to trust. |
| 2026-07-30 | Stale sibling worktree removed (hygiene) | -- | `/aid-specify`'s mandatory `locate work-005` pre-flight re-materialised `.claude/worktrees/work-005` from branch `work-005`, producing a **clean twin holding the pre-redesign specs for all 13 features** — Q24's "do not execute against" set, with no dirty-tree signal to betray it. It also **shadowed the live work in `enumerate-works.sh`, which returned two `work-005` records with the stale one first** (`Detail`/`Paused` vs the live `Specify`/`Running`). Worktree directory removed via `git worktree remove` (no `--force`). Verified before: 0 porcelain entries incl. untracked, 0 commits unique to `work-005`, `work-005` == `origin/work-005` == live branch @ `7c2b5115`, no process bound, 0 repo references to the path. Verified after: **branch `work-005` intact and still published on origin**, enumeration back to one record, live tree unchanged (19 dirty entries, SPEC still 1,162 lines). |
| 2026-08-05 | **An unrequested production edit checked, and it is a REAL FIX — plus a methodological trap that cost me three FALSE verdicts in a row** | `grade-graph.sh:474-501` | `git status` showed `grade-graph.sh` modified, which I had not authorised. Given that a live `return 0` mutation once reached a production script in this same build, I checked it before anything else. **It is a genuine defect fix, verified on both sides.** The write side (`escape_cell`, `:455`) escapes every pipe in every cell (`sed 's/|/\\|/g'` — confirmed by sourcing the real function off disk: `a \| b`). The OLD reader split on `-F'|'`, i.e. on EVERY pipe including the escaped ones, rejoining only the trailing cell. Measured on a row whose Description legitimately quotes the seven-column header: Description came back as `header is \` and Evidence as `# \| Sev \| Doc \| wrong \| ev-anchor` — **so the row's identity differs between the run that WROTE it and the run that READ it, and since identity is `Doc+Description+Evidence`, the cycle marks the row Fixed while the defect persists AND appends a duplicate. A gate reporting a live defect as repaired, and double-counting it.** The new reader protects escaped pipes with a `\x01` sentinel, splits, then restores; round trip holds byte-exact. **THE TRAP, worth more than the fix: I produced three consecutive "ROUND TRIP BROKEN" verdicts that were all artifacts of MY OWN transcription.** Retyping an awk program inline inside a single-quoted Bash argument COLLAPSES its backslashes, so I was testing `/\|/` — which in ERE is `\` **alternated with empty**, matching at every position (100 substitutions on a 4-pair line) — instead of the file's `/\\\|/`. The same collapse made my retyped `escape_cell` emit no backslash at all, which briefly convinced me the write side never escaped. A third instance: I counted pairs with `grep -o '\\|'`, and **BRE `\|` is GNU grep's alternation operator**, so it reported 0 pairs on a file holding 4 — the counting tool fell to the identical bug class it was being used to investigate. **The only faithful oracle for escaping-sensitive code is to run the bytes off disk — `sed -n` the block to a file and `awk -f` it, `.` the extracted function, `grep -o -F` for literal counts — never retype the program into the shell.** Every wrong turn here was mine; the delivered fix was correct from the start. |
| 2026-08-05 | **Enumeration suite — 189 assertions; and MUTATION TESTING HAS NOW CAUGHT A VACUOUS SUITE THREE TIMES, ALWAYS THE SAME WAY** | -- | `test-graph-source-enumeration.sh`, **1,171 lines, 189 assertions, 0 failures** — orchestrator-verified independently, with both subject scripts confirmed **byte-identical to `c6f70b1c`** afterwards, so no mutation residue. Nice design touch: the mutation harness lives *inside* the file behind `--self-mutate`, so CI with no arguments runs assertions only. **7 mutants, 7 killed, 0 survived** at the end — but **M5 survived the first attempt, and that is the third instance of one pattern.** *The three instances, all found only by mutation, never by review:* **(1)** a gap-ledger suite passed **294** assertions against an implementation reading node kinds from the `kb:` id prefix; **(2)** three validator assertions checked for the **absence of a message shape** that a broken validator also does not emit; **(3)** here, an assertion that a gitignored `.pyc` is absent from `nodes.tsv` could not fail, because **a `.pyc` cannot qualify under any clause even when the leak admits it** — it lands in `candidates.tsv` and `nodes.tsv` never changes. **THE COMMON ROOT CAUSE, now established beyond coincidence: the broken and the correct implementation AGREE ON ORDINARY DATA.** Every one of these suites was written by a competent author who had just written the subject, and every one was green. **Review cannot find this class; only mutation can.** The fix here was made twice over — a gitignored file that *would* qualify on its own merits (a shebang-carrying `.sh`), plus an assertion on the **candidate** set, which is where a leaked path actually surfaces. **Its runtime account is a model of honest measurement rather than excuse:** it could not reach a sibling's 23 s and says why with numbers — the subject costs **~14 s per invocation regardless of tree size** (a 3-file fixture scans as slowly as a 30-file one, because the cost is a fixed set of batched processes), so scan count is the only lever and it cut nine scans to **five**; 5 × 14 s ≈ 70 s is the floor and the suite's own overhead is ~6 s. It separately measured **300 command substitutions at 20.7 s against 300 plain calls at 0.16 s** and made every helper fork-free. **Vacuity discipline applied inside the suite itself:** `R-SHEBANG-12` proves `named-unit` is genuinely *reachable* so that `R-SHEBANG-03`'s assertion of its absence is not vacuous; `R-PREMISE-06` asserts the premise (`git check-ignore` returns 0 paths) *before* the group leans on it; `assert_set_all` counts its own rows and **fails** with "the set is EMPTY, so the universal would pass vacuously". And `R-IGN-01` **asserts** that the real resolver lacks `--probe` rather than assuming it. The substring-vs-cell distinction mattered concretely: `src/cited.sh` appears inside another row's evidence anchor, so a substring grep would be true with no such id present. |
| 2026-08-05 | **Q24 item 12, STAGE 1 COMPLETE — WebGL-under-headless probe: L1/L2/L3 all PASS; feature-008 UNBLOCKED** | -- | Owner-directed: replacement research before the canvas. 734-line report at `deliveries/delivery-001/research/rendering-stage1-webgl-probe.md`. **Three verdicts kept separate, as D1 demands** — the SPEC's whole point being that C-5 conflates three independently-checkable conditions and collapsing them yields "a single pass/fail whose failure mode is unknown". **ENV-2 (dev + Playwright, Windows 11): L1 PASS, L2 PASS, L3 PASS.** ENV-1 (CI `ubuntu-24.04`): **NOT VERIFIED** — not simulated, not extrapolated, with the reason given (per-platform ANGLE backend selection makes the identity string non-transferable, and D1 says a verdict is uninterpretable without it). ENV-3 (unprovisioned): **NOT DETERMINABLE** — the intended C-5 degradation, `SKIP`/exit 0, verified **before** the install and **re-verified after cleanup**. *"`NOT DETERMINABLE` and `NOT VERIFIED` are not passes."* **Renderer identity, verbatim, and it is the most consequential fact in the report:** `ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)` — **every pass was produced by a CPU software rasteriser, not a GPU.** **§ D1a rows 2–4 do not fire**; the applicable row is `L1 ✓ L2 ✓ L3 ✓`: C-5 satisfied by the existing shape, FR-12's reuse intact, the renderer decision untouched. **Nothing is handed to the owner for decision, and Stage 2 is unblocked.** **A DEFECT IN D1 ITSELF, found by executing it (S1-1).** D1 says to read `UNMASKED_RENDERER_STRING` / `UNMASKED_VENDOR_STRING`; the extension defines `UNMASKED_RENDERER_WEBGL` / `UNMASKED_VENDOR_WEBGL` — **orchestrator-verified at SPEC `:380`**. Taking D1 literally reported the identity as `null` **and** poisoned the L2 error reading with a spurious `1280` that looked like a `readPixels` failure: **one cause, two wrong numbers, both false.** Sharpest of all — **D1's own clause "where the extension is not exposed, that absence is itself recorded as the value" would have absorbed it and dressed the bug as a finding.** **The L3 qualification is stated loudly rather than buried:** `toDataURL()` on a default-attribute canvas called in a *later task* returns an all-transparent buffer — `preserveDrawingBuffer: false` semantics, not a capture failure, since the same canvas passes when captured inside the frame. So L3 is PASS **with a synchronisation obligation**, flagged because *"that column failing is exactly what an unsynchronised harness would see and then misread as 'WebGL does not capture headless'"* — the false negative that would have killed the live renderer. **Its vacuity audit of its own probe is the standard to hold:** L2 requires **13 of 19** sampled coordinates to be background, with an **asymmetric, non-square** figure so a y-flip, x-flip or transpose is detectable, plus exact pixel count and exact bounding box independent of the sample list; and **L3 ran a blank, never-drawn canvas through the same analysis and it FAILS both capture routes** — plus a per-canvas identity mark, so a capture returning the wrong element cannot pass (without which three canvases drawing the same figure would have made L3 vacuous). Stated residual it cannot close: every control ran in ENV-2 only. **`scale-ceiling.yml` re-verified untouched at `{'node_ceiling': None}` — no ceiling invented.** Installs disclosed and reverted: `package.json`/`package-lock.json` untouched, both `node_modules` trees and the scratch harness removed, ENV-3's SKIP re-verified afterwards to prove the machine was returned to the unprovisioned state. |
| 2026-08-05 | **Q28 D2 ESCALATED — the CI visual-fidelity gate has been broken since the day it was added** | -- | Independently re-found by the Stage-1 probe (its S1-2) and **orchestrator-verified with provenance this time.** `.github/workflows/test.yml:105` sets `SUMMARY=".aid/dashboard/kb.html"` and short-circuits `exit 0` when absent — and **`.aid/dashboard/` exists nowhere in `origin/master`'s tree (0 entries)**; the real artifact is `.aid/knowledge/kb.html`, which is what `playwright-provisioning.md:53` documents. **Introduced by `5f2b3682`, dated 2026-06-26, titled *"ci(test): drop dead Mermaid pre-seed step + add visual-fidelity gate"* — so the gate has never validated anything, from the moment it was created.** The `npm ci` and `playwright install` steps *do* run, so provisioning is exercised while the gate step always short-circuits — which is why it has looked green for forty days. **New consequence the probe drew that the earlier finding missed:** this **invalidates D1's stated basis for ENV-1** being *"where FR-12's gate actually runs, and the only environment whose configuration the project controls"* — it is not where the gate runs, because the gate does not run. **Owner: CI maintainer / repo owner.** Deliberately not fixed: a one-line change to a shared workflow whose blast radius is a gate that starts failing the moment it starts working. **And it bears on the ENV-1 decision** — the probe's own recommendation is that adding a probe step should follow the fix, since *"a job whose gate step never executes is a weak place to add a second one."* |
| 2026-08-05 | **Gap-ledger + registration suites — 510 assertions; and MUTATION TESTING CAUGHT A LIVE VACUOUS SUITE. This is the finding of the build.** | -- | `test-graph-gap-ledger.sh` **1,165 lines / 303 assertions / 71.6 s** and `test-graph-skill-registration.sh` **526 lines / 207 assertions / 23.3 s**. Orchestrator-verified independently: **303/0** and **207/0**. Both glob-discovered, no runner edit. Suite 2 went 84 s → 23 s by batching per-record shell-outs at **identical** assertion count. **THE HEADLINE: mutation M2 SURVIVED the first draft — 294 assertions, 0 failures, against an implementation that inferred endpoint kinds from the `kb:` id prefix.** That is the exact proxy-defect class (Q21) this entire work exists to prevent, and **the suite could not see it.** The reason is subtle and worth preserving: on a *well-formed* table all four Knowledge-Base kinds carry `kb:`, so prefix-inference and the correct reading **agree on every ordinary row** — the defect is invisible to any fixture built from realistic data. In the author's own words: *"the kind-as-data pair you asked me to commit was the thing I had left out, and only mutation testing found it."* The fix is `KIND01`–`KIND09`: one candidate, one row, **one cell varied at a time, in both orientations**. Replayed against M2 it now fires **4 failures** — a prefix-inferring implementation gets all four backwards, a correct one passes all four, and **neither probe alone separates them.** **17 mutations total, every one reverted and sha256-verified.** The second-best is **R8** in suite 2: adding a file to `canonical/` fails in **all five profiles AND the dogfood tree simultaneously** — and had the expectation been derived from a manifest or a sibling tree, which is precisely tech-debt **L4**'s recorded failure, **R8 would have been invisible.** That is the anchoring rule proved rather than asserted. **A FOURTH false-PASS shape found and closed:** `assert_file_not_contains LEDGER 'bin/entry.sh'` failed because that path appears inside *another row's* Evidence anchor — **a bare substring absence is not a Doc-cell absence.** All three sites now assert `'| bin/entry.sh |'`. It also audited itself against the three shapes it had already hit: **zero** numeric-line `sed` addresses in either suite, **zero** `grep -c … || echo 0` (the single hit is the header comment documenting the anti-pattern), and **every set comparison asserts its own set non-empty first** — 20 named sites. **`GL03`/`GL09`/`GL15` are now genuinely exercised**, the three it had itself reported as unexercised anywhere: GL09 ships a probe that imports the module and calls **`detectArtifactGaps` and `kbUnbacked` directly**, then asserts their intersection empty; GL15 **reads `image_extensions` from the carrier rather than restating it** and asserts `LOGO.PNG` is in the table but absent from the ledger — so a prefix-keyed reading would have reported it. **The parser trap is committed** with a third guard (`TRAP.c`) asserting the trap really does repeat the ten-column header, *"otherwise it would fail loudly instead of silently"*. **It independently flagged the concurrent agent's live mutation** in `validate-relationships.sh` — *"Do not commit that line"* — from a run in which its own write surface was scratch only. **Honest non-assertions:** `GR07(a)`/`GR08`'s per-site *placement* checks left to feature-013's documentation pass rather than guessed at; `NEG35` **skips loudly** where `chmod 444` does not take (it added a skip outcome to `assert.sh`, which had none); and `GR05`'s residual left exactly as the contract states it, declining to add a byte assertion the contract itself declines. |
| 2026-08-05 | **Concurrent-agent mutation REVERTED; and a self-falsifying KB claim (Q28 D9)** | -- | The `+ return 0` in `advisory()` is **gone** — `git diff --exit-code canonical/` clean. The agent complied, and a sibling had independently flagged it in the same window from a run whose write surface was scratch only. Two agents catching one another's contamination is the redundancy working. **New live repo defect, found by the gap-ledger author:** `.aid/knowledge/test-landscape.md:88` states the bash harness has **"134 suites"** — and the row **carries its own oracle**, `CONFIRMED via ls tests/canonical/test-*.sh \| wc -l = 134`. Orchestrator-ran that exact command: it returns **140**. So the claim is falsified by the very command it cites as its confirmation, and it was already stale before this work's five suites landed. **Not machine-enforced** — `check-skill-counts.mjs` guards skill counts only and is green. The author flagged rather than fixed it, correctly, since editing a KB doc was outside "add only test files". **Owner: the work owner.** Ninth live repo defect this work has surfaced. |
| 2026-08-05 | **First committed test suite — the view, 1,828 lines / 175 assertions; and the non-vacuity discipline encoded STRUCTURALLY** | -- | `test-graph-view.sh` plus four `.mjs` helpers, auto-discovered by the `tests/canonical/test-*.sh` glob with no runner or workflow edit. **175 assertions, 0 failures; 119 need nothing but `node`.** Orchestrator-verified independently in the CI shape: **119 passed / 0 failed / 22 skipped.** **Two design choices make this suite better than the harness it came from.** *(1) The concatenation oracle is asserted as a RELATIONSHIP, not a magic number* — bundle = the four files' sum + 3 join separators — because a hard-coded 4,739 would have to be re-typed on every edit to any of the four files. That is Q19 applied to a test rather than to prose. *(2) The 15 non-vacuity controls mutate a COPY in a `mktemp -d`, by exact-string replacement that fails loudly if the pattern is absent or non-unique* — in the author's words, the `sed`-against-shifted-lines failure mode becomes **structurally impossible**. The lesson is encoded in the mechanism instead of trusted to care. **The strongest single assertion needs no mutation at all:** `GT23` computes what a **prefix-deriving implementation would produce** and asserts that it *collides* the different-kind pair and *splits* the same-kind pair — so the three encoding assertions **cannot be satisfied by any id-reading implementation**. That closes feature-008's nineteen-vacuous-hooks defect by construction rather than by inspection. **It then found three further vacuity holes in its own new suite:** a set-equality check that two empty sets would have passed (the one state where an empty listing is correct is now asserted separately), and two checks where a **crashed helper emitting nothing would have contributed no assertion while the suite stayed green** — now guarded, and the guard verified to fire. **The `id=""` validator bug is skipped LOUDLY, not worked around**: one check names feature-011 on the `bad array subscript` signature, the anchor obligation is asserted over the same rendered markup by a different check, and **if feature-011 fixes the bug the skipped check simply passes** — the defect is not encoded as required behaviour. **A new finding, honestly handled:** the skeleton carries **three** `aria-live` regions, not two — the view's own two plus the reused lightbox caption inside the `aria-hidden` dialog. feature-007's "exactly two and no more" counts only its own. The suite asserts the **true** state, pins the total so a fourth would fail, and prints the discrepancy as a NOTE rather than encoding a clause that does not hold. Likewise the two **false** SPEC clauses (TV07's "row set unchanged" and TV01's pristine-state preset) are **not encoded**; the true behaviour is asserted with a NOTE naming the clause to re-word. Deliberately excluded and stated as uncovered rather than approximated: every browser check, every layout assertion (jsdom implements no layout), and 21 recorded SKIPs where jsdom is absent — **never a pass**. |
| 2026-08-05 | **PROCESS DEFECT — a live mutation left in production code, by the agent testing for exactly that defect class** | -- | Caught by the orchestrator reading `git status` rather than trusting a report. `canonical/aid/scripts/graph/validate-relationships.sh` had gained **one line**: `return 0` inserted at the top of `advisory()`, which makes **every advisory silently dead** — `V12`'s endpoint advisories, `V15`'s concept ambiguity, the unobserved-token direction, all counting nothing and reporting nothing. **The script still exits 0 and still prints `Findings: N`, so nothing in its output announces that a whole class of checks stopped working.** It is a check that passes because it is not looking — **the exact defect class this entire work has been auditing for**, left behind by the agent whose task was to prove its checks non-vacuous, almost certainly an unreverted mutation test. **The failure mode is the method, not the agent:** mutating a file **in place** under `canonical/` is unsafe by construction, because a timeout, a quota kill, or a crash between mutate and restore leaves precisely this. A sibling agent solved the same problem correctly in the same hour — mutate a **copy** in a `mktemp -d`, by exact-string replacement that fails loudly if the pattern is absent or non-unique. That method was relayed as the required approach. **Not reverted under the agent**, since it may be mid-test and only it knows; it was asked to revert first and to state whether the edit was a test or an intended change. Also corrected in the same message: the orchestrator's own brief had told it to add only test files, and four sibling suites had since landed concurrently — **completeness is not inferred from a file existing**, so it was asked to say which of its two suite files are complete and where any partial one stops. |
| 2026-08-05 | **`aid-graph` REGISTERED — repo GREEN; committed `55453fd3`; Q28 D4 CLOSED** | -- | 331 paths. **Every suite run, not sampled:** `test-doc-counts.sh` **31/0**; `check-skill-counts.mjs` **175 claims agree** (it had reported **`WRONG COUNTS: 61`** beforehand); the site vitest run **whole** rather than single-file — **50 files / 2,695 tests**, exit 0, with the clamp naming `aid-graph` **zero** times; render VERIFY **1,785 files byte-identical**; dogfood byte-identity **1,442/0**. Orchestrator-verified independently: 175 agree, 31/0, and **`relation-vocabulary.yml` now present in 7 rendered locations where it was 0** — **Q28 defect D4, which was the orchestrator's own, is CLOSED**, confirmed per-path by sha256 across five profiles, five manifests and both dogfood trees. **The value-keyed sweep earned its redesign on first real use.** Four fields move when a curated skill lands (`directories`, `curated`, `classic`, `curatedOnly`), so the needle set was `{75, 20, 18, 17}` in digits and words — and the phrasing-keyed rule it replaced was proven blind to a whole class: **`17 curated +` is invisible because the pattern's lookahead admits `)` but not `+`**, and **`(75)` is invisible because a lookbehind kills it**. Eight further sites were found that way. It also reports that `curated` and `classic` have **no `CLAIMS` pattern at all**, so their needles produced only false positives. **The per-site judgment is the part worth keeping, because not every stale-looking number is stale:** `"corpus 111 → 75"` is **history** and keeps its values — but the sentence *also* claimed to be a live guarded figure and could not be both, so it was repaired rather than renumbered, and the `count-history` marker route was **explicitly rejected** because the marker would have falsified the row's own claim; `"47 of the 75"` is a **dated measurement snapshot** left alone, since bumping only its denominator would assert a count nobody took; and ~40 hits are genuine false positives (Node floors, `W1-17` ids, grading thresholds, dates) left untouched. **Two hard blockers had to be fixed inside feature-010's shipped content, both delimiter defects no parser survives:** a **comma is not in the state-table separator set**, so one Advance cell parsed with an unreachable target and V9 **threw**; and **` then ` split another cell and built a SPURIOUS state edge** — a wrong flow diagram would have shipped. **The allow-list escape was available and deliberately not taken**; the edge was moved onto the state that actually takes it. Both are content edits in another feature's file — flagged for that owner. **Six stale SPEC citation sets reported and not edited**, plus three structural gaps the merge opened: feature-013's D1 classifies **three** hand-authored site surfaces nowhere and misses **all five `profiles/*/README.md`** (hand-maintained — zero README records in any manifest — yet gated by `test-doc-counts.sh`), and feature-012's Flow step 8 names only the claude-code dogfood resync where the suite checks **two** trees. **Disclosed judgment calls:** it staged all 331 paths because the drift oracle is `git diff --exit-code` over generated pages; it ran `npm install --no-save jsdom` (declared at `package.json:36` but missing from `node_modules`) rather than honestly reporting only 46 of 50 files; and it found the mandated regen had corrected **pre-existing** drift in `aid-summarize.flow.json` (a stale `Node >= 18` against canonical `>= 20`) — exactly the "nothing gates a stale committed copy" hole feature-012's L1 names. |
| 2026-08-05 | **BUILD COMMITTED `c6f70b1c` — 39 new files, 20,863 insertions; 4 stray fixture files caught before they shipped** | -- | The whole build committed after a full inventory: **40 files, ~20,000 lines, all syntax-clean** (`bash -n` ×18, `node --check` ×4). **`git add -A` staged four zero-byte strays that had leaked into the REPO ROOT from agent fixture runs** — `-`, `ZZZ`, `kindz`, `section`, all products of misquoted redirects. Confirmed absent from `HEAD`, unstaged and deleted before the commit. **This is the "no crud outputs" rule catching a real escape**, and it argues for fixtures under `.aid/.temp/` without exception. The commit message records the defect *classes* rather than a file list, because the classes are the transferable part: awk's `NR==FNR` true on an empty first file; `local a="$1" b="$a"` reading an unset local (hit independently by **two** builders); `node --check` blind to a missing catch; three vacuous checks; and **vacuous fixtures** built with `sed` against shifted line numbers. It also states what is *not* done — no canvas, no end-to-end run, no committed tests, `shellcheck` not installed — rather than implying completeness. |
| 2026-08-05 | **master MERGED again (76 commits, 1,201 files) — ZERO conflicts, but work-004's ALIAS RETIREMENT lands and changes every count** | -- | Owner-directed pull. **Previewed with `git merge-tree --write-tree --name-only` before touching the working tree** — exit 0, **zero conflicted paths** — then merged as `c87e80ae`. The headline is not the conflict count but the **54,811 deletions against 12,608 insertions**: master carries **work-004's alias retirement**, which **deleted 36 alias skills** from `canonical/skills/` and every profile and dogfood tree. **A clean textual merge that still invalidates work semantically — exactly the error-5 class — so it was assessed rather than assumed.** Verified after: **all 40 build files intact, all syntax clean**, `canonical/aid/templates/graph/` untouched, and critically **`canonical/aid/scripts/summarize/` untouched**, so Q28 defects **D1/D3/D8** all still stand and the view's 21/21 `validate-html-output.sh` run remains valid. **`.aid/works/work-005-knowledge-graph/` survives** (141 work-folder deletions, none of them ours). **What it did invalidate: the entire registration brief.** The corpus is now **76** (master's 75 + `aid-graph`), not 112, and the derivation's *shape* changed too — `catalogAliases` **36 → 0**, `shortcuts` 64 → **34**, `catalogRows` 94 → **58**, `repurposed` 30 → **24**, `curated` 21 → **20**, `classic` 19 → **18**. The registration agent was **stopped the instant the owner's message arrived**, before it had written anything (`git status` clean, 0 entries) — it was about to edit docs, the site roster and the profile render, which is precisely what this merge rewrote. Re-run of `test-doc-counts.sh` post-merge: the same **eleven `DC02` failures**, now demanding **76**. `aid-graph` still appears **zero** times in `site/scripts/`. **Also owed again: a KB citation sweep.** Eleven `.aid/knowledge/` docs changed in this merge, including every one the SPECs cite by line. The standing correction applies — test whether the **arguments** still hold, not merely whether the citations resolve, and sweep **all** citation forms rather than the literal `<doc>:<line>` shape. Deferred to the end-of-build fix pass with the rest. |
| 2026-08-05 | **Accessible table view COMPLETE — 999 lines, 145 assertions; and an 8th live repo defect proved empirically** | -- | `graph-table.js`, 47 top-level names all `tbl`-prefixed against the shared module scope. **The duplicate-name oracle matches the orchestrator's own baseline exactly**: concatenation 3,740 → **4,739** lines, `node --check` clean both ways. **`validate-html-output.sh` 21/21 against the BOOTED-AND-SERIALIZED page** — the markup a reader actually receives, which is a stronger subject than the static file — with the L2 target set unchanged by its new caption link. **The self-found defect is one that would have quietly destroyed the feature's accessibility argument:** `dimmed` was taken from either emphasis map unconditionally, so under the Coverage lens a row carrying a `no KB doc` badge was **also** `data-emphasis="dimmed"` — because its *other* endpoint is dimmed. That inverts the SPEC's definition, in which `dimmed` is the **complement** of the marked set, and the complement is precisely what the "no colour-only encoding" argument rests on. Found by reading the rendered lens, not by a test; closed with two assertions (`5 marked + 8 dimmed = 13`). **Its zero-row derivation is over the FOLD, never over `degree`, and the fixture proves why that matters:** population 2 is `kb:beta.md` with **degree 1**, whose every row the `document` fold collapses — a `degree === 0` test would miss it entirely. All three populations exercised. **The prefix fixture passes in both directions** — same prefix + different kind ⇒ different kind text, glyph and colour class; different prefix + same kind ⇒ identical on all three — plus a source-level assertion that the file contains **no `'kb'`/`'int'`/`'ext'` literal at all**. **Parity is claimed honestly:** exact set equality at `grouping: 'none'`, and under a folding dimension the shortfall is **quantified (3 of 5)** rather than denied. **Two SPEC assertions found FALSE against the frozen upstream, both routed rather than worked around:** TV07 (SPEC`:536`) claims the listed row set is "unchanged" after selecting a gap endpoint, but `project()` restricts `visibleEdges` to the focus ball (`graph-model.js:1561`), so a measured run went **13 rows → 1**; and TV01 for the `impact` preset **cannot pass from a pristine state**, because that patch differs from `INITIAL_LENS` only on `focus.depth`, which with no selection reaches no `ViewModel` field at all. Both need re-wording before feature-013 writes them. Honest non-verifications: **TV16 not verified and not claimed** (jsdom implements no layout, Playwright not installed); browser evaluation of the inline module block untested; native `Enter`/`Space` inferred from button-ness plus effect, since jsdom synthesises no click from a keydown. |
| 2026-08-05 | **Q28 D8 — `validate-html-output.sh`'s L1 check ABORTS on any `id=""` substring; proved empirically** | -- | Found by the table-view builder, **orchestrator-verified by running it**. `:355-358` harvests ids with `grep -oE 'id="[^"]*"'` — a **substring** match, not an attribute match — then does `ID_SET["$_id"]=1`. Two facts, both demonstrated: on markup containing `data-controls-grid=""` the grep yields **`id=""`** (the substring `id=""` sits at the tail of `grid=""`), and `declare -A S=(); id=""; S["$id"]=1` produces **`bash: S["$id"]: bad array subscript`**. So **any HTML with an attribute whose name ends in `id` and whose value is empty aborts the anchor check** rather than failing it gracefully — and feature-007's own `data-controls-grid=""` is exactly such an attribute. The delivered static page does not trigger it and nothing the table view emits does; the builder worked around it **in its scratchpad copy only** and reported both runs. **This validator is on the required path for `/aid-summarize`.** Owner: **feature-011** (which parameterises this script) or the work owner. Eighth live repo defect this work has surfaced, and the second in this one file — `--kb-dir` being write-only (Q28 D3) is the other. |
| 2026-08-05 | **`aid-graph` SKILL + runtime COMPLETE — 18 files, 2,939 lines; and it refused to claim an end-to-end run** | -- | The skill: `SKILL.md` **196** + **12** reference files (1,014 lines total), one per state plus `agent-pass.md`. The five scripts: `grade-graph.sh` **671**, `graph-stale-check.sh` **503**, `assemble-coverage-notes.sh` **308**, `kb-write-fence.sh` **256**, `graph-preflight.sh` **187**. Frontmatter parsed through **`render.py`'s own `_split_frontmatter_raw`** as well as `yaml.safe_load` — all four required keys, no extras. **The states match mechanically: 11/11 identical and in identical order**, with all nine departures from spine order implemented and each tied to an *observable*. **No diagram was reintroduced** — verified zero multi-node diagrams in any reference doc, with one "you are here" map template plus a marking rule instead of eleven near-copies. Thin-router discipline held: three routers at 35/34/61 lines restate no mechanic of the scripts they invoke; `state-extract.md` (124) is the one genuine body, as the SPEC says it should be. Verification is the deepest of the build: the **full SR04 mutation matrix** (all six digest components, both arms of `src`, `vocab` and `tool`, plus two negative controls that correctly stay `CURRENT`), the fence's four properties and **all three violation directions**, the rubric over a deliberately-broken page producing 21 rows at exactly the HIGH/MEDIUM range D4 assigns, **SR13's two worked grade examples reproduced exactly**, the resolver's four-step order proven against four fixture settings files, and the full four-cycle ledger lifecycle including a hand-set `Accepted` left untouched. **`--grade` proven non-persisting**: `settings.yml` byte-identical before and after. **A real determinism defect found by its own twice-run check and fixed as a class:** the ledger row key did not round-trip — Evidence was written with the validator's leading indentation but read back trimmed — so **every re-run marked the old row `Fixed` and appended a duplicate**. Root cause was asymmetric whitespace handling between write and read; fixed in `escape_cell` and re-verified over three runs. **It also proved a scoping fix live** by building the fixture that separates the two readings: a KB that is unapproved while a summary block records approval **passes the unscoped grep that `summarize-preflight.sh` uses** and is correctly refused here. **`scale-ceiling.yml`'s unset value handled on all three arms** — absent, set, and malformed (`not-a-number` treated as unset, never as 0) — with no invented number. **The headline honesty: "No end-to-end `/aid-graph` run passed, and I am not reporting one. Four of eleven states cannot complete today."** It published a state-by-state exercised/not table and named the blocker for each. |
| 2026-08-05 | **TWO BLOCKING SEAM GAPS + a 7th live repo defect, all verified first-hand** | -- | **(1) `rel_fence_mask` and `rel_fact_records` do not exist** — orchestrator-verified: `grep -c '^rel_fence_mask()'` → **0**, `rel_fact_records` → **0**, while `rel_fact_tokens` → 1 (it returns the token alone, without the cited path FR-30 needs, the anchor string D2c needs, or the block range D2e needs). **Two independent agents reported this gap from opposite sides** — the extraction builder documented it as an ask on feature-003 and shimmed it for its E2E; the runtime builder hit `harvest-declared.sh` **exit 2** naming the same two functions. **Pass 1a is blocked, and so is everything downstream of it** (`build-relationships.sh` then fails for want of the node stream). Neither agent reimplemented the rules locally, which was the right call and is why the gap is visible rather than silently duplicated. **Owner: feature-003** — the two functions must be added to its published surface. **(2) NOBODY writes `graph_inputs_digest` / `graph_generated_at`.** `build-relationships.sh:841` explicitly declines them as outside the byte-identity boundary; feature-010's D2 says feature-003's emitter writes them. The runtime builder closed the gap in `state-emit.md` step 3 (legitimate — `relationships.md` is W1, so the fence permits it) but flagged that the clean fix is a `--digest` / `--generated-at` flag pair, **a cross-feature contract change it was not authorised to make. Owner call.** **(3) Two renderers of one section:** `assemble-coverage-notes.sh` renders the coverage notes *and* `build-relationships.sh` renders them directly from the two TSVs. Same shape, so nothing is broken today — but two renderers of one section is precisely the divergence the SPECs warn about, and today the assembler's output is **unconsumed**, running only as a fail-fast seam check. **One of the two must go; needs a coordination decision with feature-005.** **(4) NEW LIVE REPO DEFECT — Q28 D7: eleven shipped `SKILL.md` files carry a relative link that resolves nowhere.** The runtime builder found it by *checking the sibling convention instead of copying it*, and used the correct form. Orchestrator-verified: **11** skills link `](../../templates/state-machine-chaining.md)` against **3** using `](../../aid/templates/…)`; all eleven are at `skills/<name>/SKILL.md`, so the link resolves to `canonical/templates/` (or `.claude/templates/` when rendered) and **neither directory exists** — only `canonical/aid/templates/` and `.claude/aid/templates/` do. **The affected files are the core pipeline skills**: `aid-define`, `aid-deploy`, `aid-describe`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-housekeep`, `aid-monitor`, `aid-plan`, `aid-specify` and one more. User-visible, and the majority form is the broken one. **Owner: the work owner** — not work-005's to fix. |
| 2026-08-05 | **Two-pass extraction COMPLETE — 3,203 lines; six bugs found by RUNNING it, and one cross-feature conflict refused rather than worked around** | -- | `report-endpoint-satisfiability.sh` **560** (dual-mode: hosts `load_edge_relation_map` + the shared load sequence), `harvest-declared.sh` **1,330** (Pass 1a), `derive-edges.sh` **319** (Pass 1b), `build-relationships.sh` **994** (steps 11–16). End-to-end against a hand-built 8-document fixture and the **real** `relationship-schema.sh`: 50 class-0 + 2 class-1 rows, exit 0; `diff -r` **empty** across two full runs with identical md5. Self-validated by the **real** `validate-relationships.sh`: **zero findings from V1–V10, V13, V14.** **The orientation hazard is closed by construction and shown, not asserted.** Marks are computed **from the map and the vocabulary, never from emitted rows** — a pair registers its producer *and* its transpose in the same step, so no stored orientation can reach the classification; and D2f's detector, which must read frozen rows, tests **both readings** of every row rather than the stored `S2T` alone. Demonstrated on a real flipped pair: harvested `section→concept mentions`, stored flipped as `concept→section mentioned-in`, and the report still marks **both** directions as produced. **Six bugs found by running it, four of them classic bash traps the author hit and then swept as classes:** `. "$lib"` **inside a function** made the library's `declare -A` function-local, so loaded state vanished on return; `local a="$1" b="$a"` reads an **unset** local, because bash declares all names before assigning any; **rejection 2 never fired** — a colliding class-1 key was silently absorbed by the shared dedup index instead of being rejected and dispositioned, a vacuous check that would have passed forever; and `br_reject` appended unconditionally, so a re-run duplicated disposition rows. Also 45 s → 32 s by removing per-row command substitutions. **It rebound to the real library surface mid-run** rather than to the brief's assumed one, and documented **two genuinely missing functions as asks on feature-003** (`rel_fence_mask`, `rel_fact_records`) instead of reimplementing their rules locally — using a clearly-labelled shim for the E2E only. That is the no-second-copy discipline holding under schedule pressure. |
| 2026-08-05 | **NEW CROSS-FEATURE CONFLICT (functional, blocks image relationships) — V11 cannot admit an image path** | -- | Found by the extraction builder, **refused rather than worked around**, and **orchestrator-verified down to the constant**. Chain: V11 → `durable_anchor()` (`validate-relationships.sh:464`) → `rel__is_citation_path()` (`relationship-schema.sh:1515`) → `rel__has_word "$REL_CITE_EXTENSIONS" "$ext"`, where **`REL_CITE_EXTENSIONS='md sh py mjs js ts yml yaml json toml txt ps1'`** (`:156`) — **twelve extensions, zero image extensions**; a grep for any of the nine image extensions across the whole validator returns **nothing**. Meanwhile `relationship-schema.yml` carries `image_extensions: [png, jpg, jpeg, gif, svg, webp, avif, bmp, ico]`. **So every `illustrated-by` row fails V11 at `[HIGH]`**: feature-005 step 10 mandates carrying feature-004's evidence **verbatim**, feature-004's template 13 leads that evidence with the **image path**, and V11 then rejects it as not a durable anchor. Confirmed precisely scoped — the `dependency` and `invocation` rows pass; only the two image rows fail. **Two candidate fixes, and it is an owner call which is right:** widen the cite set to admit `image_extensions:` — **the data is already loaded**, so this is nearly free and arguably correct since an image path *is* grep-recoverable (**owner: feature-003**) — or lead template 13 with the *citing* file's path instead (**owner: feature-004**). Deferred to the end-of-build fix pass per the owner's standing direction, but flagged as **functional rather than editorial**: shipped as-is, image relationships fail validation at HIGH. |
| 2026-08-05 | **Graph view shell COMPLETE — 4,638 lines; `validate-html-output.sh` 21/21 exit 0, nothing deferred** | -- | Six files: `graph-model.js` **2,179**, `graph-controls.js` **979**, `graph-css.css` **648**, `graph-skeleton.html` **286**, `lens-presets.md` **349**, `accessibility-checklist.md` **197**. **All eleven FAIL-setting blocks of `validate-html-output.sh` pass against a really-assembled 246 KB page, exit 0, with no check pushed to a later feature** — including `[H1]` under the real `html-validate` rather than the regex fallback. Orchestrator-verified: **no `package.json` at any level** from the predicate's directory to the repo root, so the marker-free import condition still holds; and the three-file **concatenation is a valid module** (3,740 lines, `node --check` clean, no duplicate top-level name). **It measured the dark theme itself and published the numbers, because the repo's own checker cannot:** worst light **5.02:1**, worst dark **7.89:1** across all fifteen palette tokens against `--bg-elev`; every pair clears 3:1 *and* 4.5:1. **It then reproduced Q28 defect D1 exactly**, independently of the orchestrator's earlier finding — `contrast-check.mjs` reports `11/11 (light) + 11/11 (dark)` exit 0 while **every dark ratio is byte-identical to its light ratio** (`16.83, 7.15, 4.97, …` printed twice), because the dark lookup resolves a `color-scheme` block, harvests zero custom properties, and computes `dark = {...light, ...{}}`. It nevertheless shaped its palette blocks to be extractable once feature-011 parameterises that script. **The prefix-defect proof is the best construction this build has produced:** two `ext:` ids with different kinds — one `web-page`, one `image` — get **different colour tokens and different glyphs while sharing the prefix**, and the converse holds too (an in-repo `image` and an external `image` share both). No prefix-deriving implementation can pass that fixture. Every legitimate prefix read is enumerated in-code with a comment naming which of the five sites it is. **It confirmed the orchestrator's usage-shaped-check note empirically:** `graph-model.js` has **zero** real DOM usages and its two `document.` hits are prose sentence-endings — so a bare-substring `document` check would false-positive. Contract counts match the SPEC exactly: **19 `ViewModel` fields** with `integrity` correctly a `GraphModel` field, **14 `LensState` members**, 43 controls all keyboard-driven with their `LensState` effect asserted, and `INITIAL_LENS` stating all fourteen. **`scale-ceiling.yml`'s unset value is handled without inventing a number** — the footer states no ceiling is declared. **Two interface additions disclosed rather than buried** (`window.aidGraphView`, `registerRendering`), both because a consumer had no sanctioned route. **One coordination item for feature-013's suite:** the two JS files **cannot be imported standalone** — they resolve `RELATION_CATEGORY`, `COVERAGE_BEARING`, `BACKING_KIND` and `KB_UNBACKED_KINDS` by plain reference from the predicate's segment, so the suite must concatenate exactly as the page does. **Honest non-verifications:** jsdom does not execute inline `type="module"` scripts, so browser module evaluation is unproven and Playwright is not installed; GV19 needs real KB `## Contents` anchors; assembly and the profile render belong to features 010/012. |
| 2026-08-05 | **Source enumeration COMPLETE (807 + 1,203 lines) — and a latent bug that would have shipped broken to every clean-tree adopter** | -- | `significance-rules.sh` **807** lines (library) and `scan-source.sh` **1,203** lines (the single walk, five output streams), both confirmed complete rather than truncated, both `bash -n` clean. Real run over this repo: **1,187 source-artifact + 4 image + 0 web-page nodes, 10,879 observations, 3,954 candidates, 15 unqualified**, exit 0. **The headline defect is the kind that passes every test on the developer's machine and fails on arrival.** `NR==FNR` was used to distinguish awk's first input file from its second — but **when the first file is empty, awk still sees `NR==FNR` true on the second file's first record.** `excl.git` is empty on any repository with nothing gitignored, so **every candidate path would be silently lost**. It is invisible on *this* repo, which has gitignored content. The author **fixed all five instances as a class rather than the one it tripped over** — F1 applied without being told. Three more self-found: gitignored `__pycache__/*.pyc` became nodes because Class 5 was allowed to override *every* exclusion when D4 re-admits from Class 1 only; D5's bare relative-reference rule **never fired**, so both SPEC-cited instances fell through to `ambiguous-basename`; and `--external-sources` **leaked an absolute path into evidence**, which D1a forbids outright and FR-32 breaks on. **Its determinism handling is a model for how to treat a surprising measurement.** Two live-repo runs disagreed — 1,203 vs 1,204 nodes — and rather than reporting nondeterminism or quietly re-running, it **found the cause**: peer agents wrote seven files into `canonical/aid/scripts/graph/` *during its verification*, and the single diff was one peer's `graph-stale-check.sh`. It then re-proved determinism on a **frozen 4,209-file snapshot of `1446eb3c`**, where the premise it was testing actually holds — `diff -r` empty, all five streams `cmp`-identical, every sha256 appearing exactly twice. **The shebang case is closed in both directions:** the library's decision chain shows Q1 beating Q3, and the real output has **all 134** shebang-carrying `test-*.sh` nodes as `entry-point` with **zero** `named-unit` — the rejected reading that yields `named-unit`/`[LOW]` shown explicitly as *not* what the code does. The ignore list was exercised in **all three states** plus a comma-splitting case. **`shellcheck` is NOT installed and it declined to claim otherwise** — stated plainly rather than reported as passing. It also flagged a peer's `relationship-schema.sh` as failing `bash -n` at line 1044 and **correctly refused to edit another agent's file**, noting its own loader-first path failed closed with exit 2 as designed; **orchestrator-verified since fixed** — all thirteen shell scripts in the directory now pass. |
| 2026-08-05 | **BUILD STATUS — `scripts/graph/` is COMPLETE at 15 files; the view is materialising** | -- | Inventory taken on disk. **`canonical/aid/scripts/graph/` now holds all fifteen specified files and every one is syntax-clean** (`bash -n` ×13, `node --check` ×2): `coverage-predicate.mjs`, `detect-kb-gaps.mjs`, `scan-source.sh`, `significance-rules.sh` (**verified**); `harvest-declared.sh`, `derive-edges.sh`, `build-relationships.sh`, `report-endpoint-satisfiability.sh` (extraction, agent still running); `relationship-schema.sh` (**90 KB**), `validate-relationships.sh` (schema, still running); `graph-preflight.sh`, `graph-stale-check.sh`, `kb-write-fence.sh`, `grade-graph.sh`, `assemble-coverage-notes.sh` (feature-010 runtime, still running). **`canonical/aid/templates/graph/` complete and verified** — five carriers. **`canonical/aid/templates/knowledge-graph/` has six files appearing**: `graph-model.js` (**93 KB**), `graph-controls.js` (45 KB), `graph-css.css`, `graph-skeleton.html`, plus `accessibility-checklist.md` and `lens-presets.md`; both JS files `node --check` clean. **Still absent:** `canonical/skills/aid-graph/` entirely (SKILL.md + 12 references), feature-008's canvas, feature-009's table view, every test suite, and all of feature-012's registration. **Standing caution, unchanged:** syntax-clean is not verified, and four of the fifteen scripts plus all six view files carry no verification report yet. The four completed ones between them found **eleven** defects in their own output — so the unreported files should be assumed to hold defects at a similar rate, not assumed clean. |
| 2026-07-31 | **`detect-kb-gaps.mjs` COMPLETE — 1,021 lines; its 3 self-found defects vindicate the "syntax ≠ verification" rule exactly** | -- | Resumed from transcript after the quota kill and finished. **Defect D1 is the perfect case for this project's standing rule.** The author had converted `fail()` from `process.exit(2)` to `throw new InputError(...)` to fix a flush hazard **and never added the catch** — so *every* input-contract error would have exited **1 with a stack trace** instead of the contracted **2**, and **`node --check` passed the whole time.** That is precisely the gap the resume brief was built around, and it was found by reading the code back rather than by any test failing. **D2 is a fix-everywhere miss the author caught on itself:** `valueFlags` was an object literal, so `valueFlags['--toString']` returned `Object.prototype.toString` rather than `undefined`, skipping the unknown-flag branch and misreporting the flag as *"given more than once"* — exit 2 either way, so **no test could have caught it; only the message lied.** The author noted it had already guarded this same class one screen earlier (`CORE_RELATIONS` is a `Set` of own keys precisely because `'constructor' in RELATION_CATEGORY` is `true`) — *"I applied the rule in one place and not the other."* **D3:** `id.startsWith('int:')` admitted the bare string `int:`, whose stripped path is empty. **Orchestrator-verified independently:** `--bogus-flag` → exit **2** with a clean diagnostic; `--toString` → correctly reported *unknown*, exit **2**; `--help` → exit **0**. **A FOURTH defect, in its own verification harness, is the most valuable finding of the run:** two negative fixtures were built with `sed '13s/…'` and `sed '14d'` against line numbers that had shifted once the fixture gained `kb_gaps`, so **both reported `exit=0 ledger=WRITTEN` — the tests were vacuous.** Rebuilt by pattern; both now fire. A third harness bug (`grep -c … \|\| echo 0` emitting `0\n0`) had mislabelled every COVERED case as GAP. **The vacuity class living in the harness rather than the code is exactly what four consecutive gates missed on feature-008.** **Adversarial fixture design worth keeping:** a **parser trap** — a column-compatible ten-column table planted in the `## Coverage notes` section that would silently mark the zero-row node COVERED, making the worst finding vanish without an error. It did not fire. **The kind-as-data proof is decisive:** changing *only* a `Kind` cell flips COVERED→GAP, while keeping `document` and stripping the `kb:` prefix entirely stays COVERED — an implementation inferring kind from the id prefix would have got **both** backwards. **A genuine new finding about feature-003's D7:** because `int:` (0x69) sorts before `kb:` (0x6b) under `LC_ALL=C`, normalisation puts the artifact in `Source` on **every** artifact↔KB row, so the KB→artifact relation is **always `T2S`** and condition 3's reading-A arm is **unreachable on any conforming table**. It exercised the arm anyway, because the predicate implements it for totality. Verification totals: **27 `fail()` sites all reached**, ledger absent on every one; **51 schema assertions PASS**; determinism proved by **identical md5s across the first-insert run and both replace-in-place runs**, so the frontmatter rewrite is idempotent and not merely stable; `grade.sh` reads the emitted ledger as **D**, and **A+** both with every row `Fixed` and on the zero-row ledger. Honest non-verifications: `tests/canonical/test-graph-gap-ledger.sh` **does not exist**, so GL03/GL09/GL15 are unexercised anywhere today; feature-007's lens half and the profile-generator run are others' obligations. |
| 2026-07-31 | **BUILD HALTED MID-FLIGHT — workspace API quota exhausted; all 5 builders killed at once** | -- | `API Error: 400 You have reached your specified workspace API usage limits. You will regain access on 2026-08-01 at 00:00 UTC.` **All five concurrent builders terminated simultaneously**, none of them by choice. **Resume state established by inspecting disk, not by trusting the reports** — three tiers, and the distinction matters because two files carry defects their own authors declared and did not get to fix. **TIER 1 — verified complete (6):** `coverage-predicate.mjs` and the five `templates/graph/` carriers, each with reported literal verification output. **TIER 2 — on disk, syntax-clean, NOT verified (5):** `detect-kb-gaps.mjs` (40 KB), `harvest-declared.sh` (55 KB), `report-endpoint-satisfiability.sh` (23 KB), `scan-source.sh` (53 KB), `significance-rules.sh` (36 KB). All six files pass `bash -n` / `node --check`, **which proves only that they parse.** **Two carry SELF-DECLARED UNFIXED DEFECTS**, named in their authors' final words before the kill: the gap detector's author said *"Self-review found three defects in my own code. Let me fix them"* — the fix never ran; the extraction author said *"The first draft has correctness and performance defects I need to fix (duplicated region derivation, lost name cache, broken `..` normalisation, non-deterministic map iteration). Let me rewrite it properly"* — `harvest-declared.sh`'s mtime (01:32) is later than its sibling's (01:21), so it may be the rewrite, a partial rewrite, or the defective draft. **Nothing distinguishes those cases from the outside; the file must be re-verified, not resumed on faith.** **TIER 3 — never written:** `derive-edges.sh`, `build-relationships.sh` (extraction never reached them); `relationship-schema.sh`, `validate-relationships.sh` (that builder died while still reading `significance-rules.sh` for the house YAML approach — **zero** bytes written); the five feature-010 runtime scripts (never dispatched); `canonical/aid/templates/knowledge-graph/` (**directory created, empty** — the view builder died while reading its SPEC); `canonical/skills/aid-graph/` (absent); every test suite; and all of feature-012's registration. **Standing correction that applies directly here:** a syntax check is not a verification, and an author's self-report is not a verification either — the two are exactly the evidence grades this work has learned to keep apart. Tier 2 must be treated as **unreviewed draft**, and the three named defect classes plus the non-deterministic map iteration are the first things to re-check on resume. |
| 2026-07-31 | **Root vocabulary REBUILT (269 → 1,010 lines) — and an orchestrator DISPATCH DEFECT: two agents wrote one file** | -- | `relation-vocabulary.yml` re-authored from feature-001 § D5/D6, header comment included, as `feature-003:1873` says is feature-001's execution work. **Measured from the file: 57 entries, 31 pairs (26 asymmetric + 5 symmetric), 14 categories, pairs-per-category matching D5's own column exactly.** All **six** properties computed and holding — closure, totality, involution, symmetric consistency, category totality, and **pair coherence** with `endpoint_kinds(r')` the exact transpose. **The prefix-for-kind defect is gone and proved gone by the strong form:** every side of every arrow token *anywhere in the file, comments included*, is one of the seven names read out of `relationship-schema.yml` — not a hardcoded list. Cross-checks all empty in both directions against the peer `RELATION_CATEGORY`, category **order** identical, both coverage-bearing sets subsets of its keys; and a diff against **D6 parsed straight out of the SPEC** across all seven authored fields returned **nothing**. **THE DISPATCH DEFECT IS THE ORCHESTRATOR'S.** Having named the stale file as "the authority", the correction message offered the carriers builder a *choice* — re-author it or hand it on — and then a dedicated agent was dispatched for the same file **without waiting for that answer**. Both wrote it. The second read the first's 871-line version in full, **verified it rather than assuming it wrong**, and overwrote it on one substantive ground: category order. **That divergence was the right call and is now confirmed on disk** — the first chose alphabetical, citing feature-001's own parse contract; the second chose **D5's declared order**, because `coverage-predicate.mjs` states its order *is* the vocabulary's declared order, and alphabetical would have made that peer's comment false. Verified: the file's category order and the module's are identical. Cost: one wasted build. Cause: an orchestrator race, not an agent error. **It also CONFIRMED the D6d discrepancy independently** — five tokens are cited twice, not four; `skos:related` is the omission; 59 distinct, not 60. **NEW SPEC DEFECT — `AC-S11` is unsatisfiable as written, and the conflict is structural.** It requires a grep of the shipped `graph/` script tree to find no relation label and no category name; `coverage-predicate.mjs` contains **all 57 labels and all 14 category names** — orchestrator-verified. It has no choice: feature-006 D6 makes it pure, dual-runtime and file-access-free, so it *must* carry the map inline. **The module is right and the criterion is wrong.** The builder handled it honestly rather than hiding it — it removed its own header's absolute grep claim, replaced it with a stated exception, and added a rule requiring the frozen map to be updated whenever a pair is renamed or re-categorised, without which a rename would silently break the predicate. **Owner: feature-001** (AC-S11's text). |
| 2026-07-31 | **BUILD wave 1 landed — `coverage-predicate.mjs` + 4 data carriers; the root vocabulary found STALE** | -- | **First shipping artifacts of work-005.** `coverage-predicate.mjs` **582 lines** — the one module executed in **both** runtimes — plus `relationship-schema.yml` (153), `coverage-bearing.yml` (126), `edge-relation-map.yml` (123) and `scale-ceiling.yml` (77, **one key and deliberately no value**, since feature-002's measurement has not run). **Both builders verified by construction rather than by reading, and independently of each other.** The predicate builder parsed feature-001 D6's tables **out of the SPEC** and diffed them against its own module — 31 pairs, 57 entries, 14 categories, **zero missing, zero extra, zero category disagreements** — with the expectation derived independently of the code. It then ran the **real `render_lib.py` transforms** and proved the rendered copy byte-identical in **all five profiles**, the property GV02/GV08 rest on; confirmed no `package.json` exists at any level up to the repo root, so the marker-free import condition holds today; and exercised the **zero-row node**, showing the candidate set comes from the inventory and never from the table's node column. The carriers builder then used the *peer's* module as an oracle — GV04 set-equal, GV05 subset, 19 edge-map entries with zero unknown relation labels and zero unknown kind sides. **Two disclosed judgment calls worth keeping:** the predicate defines its own `CoverageEdge` (six consumed cells of the ten-column row) because the view-model `Edge` carries no kinds, and documents the consequence at the typedef rather than burying it; and the carriers builder **declined to add `derived_from`/`endpoint_kinds`/`passes` to `relationship-schema.yml`**, because D1's YAML block is a normative seven-key literal and those rules belong to the loader — adding them would have created data no specified loader reads. **THE BLOCKER: `relation-vocabulary.yml` on disk is superseded** — see Q28 **D4**, escalated. **The orchestrator's build brief named that stale file as "the authority" the other carriers must agree with**, which was false and was corrected mid-flight; both builders had already ignored it in favour of the SPEC, which is why nothing was corrupted. **The carriers builder also challenged the orchestrator's figures and was right to:** the brief's "34 `<kind>-><kind>` tokens / 69 standard tokens" (carried from feature-003's gate record) measure as **33 declared / 45 including transposes**, and **59** distinct standard tokens — *"neither of my numbers is 34 or 69 under any counting convention I could construct."* No mechanism depends on it, because both built to **the set and not the count** (Q19 working as designed), but one of the two measurements is wrong and the gate's went into this file as fact. It further found a **defect in feature-001's own text**: D6d's "64 occurrences … each count twice" list implies 60 distinct where the true figure is 59, omitting `skos:related` (cited by both `related-concept` and `lockstep-with`). Recorded for feature-001; changes no mechanism. |
| 2026-07-31 | **OWNER DIRECTION — spec-gate cycles HALTED; build the mechanisms, write the tests, fix everything at the end** | -- | Owner: *"please let's stop ruminating on those cycles. build all the missing mechanisms. write the tests. and let's fix everything in the end."* **Both in-flight fix agents stopped immediately** (feature-012 cycle-9, feature-013 cycle-4); both were killed before their first write, so no partial edits — `git status` shows only the three files already modified. **The two features still cycling are precisely the ones whose work comes LAST** — 012 is packaging/registration and 013 is tests/docs — so their open residue blocks no construction. Eleven SPECs are settled at B- or better and are the build instructions. **What this changes:** Q24 items 9–12 (editorial sweep, PLAN regeneration, task-graph regeneration) are **deferred behind construction**, not cancelled; the accumulated defect inventory — 37+ deferred ledger rows, E1–E9, feature-012's rows 17–20, feature-013's rows 17–22 — is carried to the single end-of-build fix pass the owner named. **Inventory taken before starting, and the answer is that almost nothing exists:** `canonical/aid/scripts/graph/` **absent**, `canonical/skills/aid-graph/` **absent**, `canonical/aid/templates/knowledge-graph/` **absent**; the sole delivered artifact is `canonical/aid/templates/graph/relation-vocabulary.yml`, itself still unrendered (Q28 D4). The build manifest was **extracted from the SPECs rather than guessed** — feature-010's own file tree plus a path sweep across all thirteen — giving ~15 scripts under `scripts/graph/`, 4 further `templates/graph/` carriers, the `knowledge-graph/` view set, `SKILL.md` + 12 reference files, and the test suites. |
| 2026-07-31 | **feature-013 cycle-3 gate — D+; all EIGHT in-scope rows `Fixed`, one new `[HIGH]`; cycle-4 dispatched** | **D+** | 22 rows: 0 CRITICAL, **1 HIGH**, 0 MEDIUM, 6 LOW, 7 MINOR. **Both HIGHs, all five MEDIUMs and the mechanism LOW verified closed** — and the gate re-derived rather than read: row 5's shared-line set **independently re-derived to the same three lines** by reading every candidate line for a moving numeral, non-movers included; row 2's 14-hit partition checked as **defensible and legible** with no hit unhomed and no clause unhit; row 7's oracle run **across all 48 `012` references**, with every by-section anchor resolving in feature-012's *current* 842-line text — the citation-form change earning its keep against a sibling that moved twice during the review. **The +48 was ruled EARNED**: ~40 new or re-pointed citations checked first-hand with **zero inexact**, which the reviewer called the strongest citation quality it had seen on this work, and § Figures' self-counts reconcile against the body in every case. **The vacuity audit passed by transfer, not by description** — substituting ∅ makes `GR01(a)`/`(b)` fail first, so the suite fails by name at the preflight before any derived comparison runs. Two rows survive the do-nothing case **by design, correctly, as guards**. **The new `[HIGH]` (row 17) is F1 with an unusually clean signature:** `.aid/knowledge/architecture.md:214–216` and `pipeline-contracts.md:94–96` each carry an `aid-summarize` **member-of-a-skill-list** slot — the identical shape D1 class 1 already owns at `aid-methodology.md:408` and `glossary.md:54` — and **both files appear ZERO times in the SPEC**. Orchestrator-verified: `architecture.md:214–216` names the **Knowledge Base Maintenance group** by name, the exact group `aid-graph` joins, so shipping would leave the KB's own architecture describing a group that omits a member; and **both passages close "CONFIRMED in `docs/aid-methodology.md`"**, so this feature's own `:408` edit *falsifies* them — the very pathology the SPEC already diagnoses for `quality-gates.md` at `:478–:479`. **The signature is the contrast:** the *script-area* class **was** swept KB-wide (AC-T8's sweep found a second and third site); the *skill-list* class got no equivalent sweep. Same documents, same slot kind, one class swept and one not. The gate **checked the full tree rather than sampling** — of the twelve KB files naming the sibling, every other hit is D3-covered, a dated release record, a producer list for a different artifact, or class-2-shaped — and confirmed **no other owner exists** in any sibling SPEC, `PLAN.md` or `REQUIREMENTS.md`, so cycle 4's fix is bounded to two sites plus the class rule. Six candidates **declined with reasons**. |
| 2026-07-31 | **feature-012 cycle-7 fix — the STRUCTURAL jump: a value-keyed sweep replaces the phrasing-keyed one; +10** | -- | 832 → **842**, and **the rule proper is SHORTER than the three-shape rule it replaces** — the positive delta is entirely corrections and one disclosure, with the regex detail folded into Open Item 7 rather than stated twice. **This is the cycle that had to break a three-gate loop rather than iterate it**, so the brief forbade a fourth shape outright. The new rule keys on **values**: capture `deriveSkillCounts` before and after the landing, and every field whose value differs contributes its **before** value — in digits **or words** — as a needle to be found and replaced across the corpus the gate walks. **The termination argument is what makes it different in kind:** staleness *is* the presence of an old value, so a stale line necessarily contains the needle, and no phrasing — noun, operator, emphasis run, line wrap — can hold a value outside it. Three normalisations close the ways digits hide (de-emphasis for `**111**`, needle-alone matching for wraps, the word form), and **history stops being a skip-by-shape and becomes a dismissal decided by reading**, so the gate's own documented evasion is not inherited. The sweep has a fixed point: re-run the *before* needles afterwards and every survivor is one already dismissed. **The author then attacked its own rule and found five candidate escapes** — three closed in the rule, one (`1<!---->11`) not authorable prose, and **one LIVE**: `.aid/knowledge/kb.html:2586` states a skill count inside a scanned tree that the walk's extension filter never opens. It enumerated all 13 such files to bound the class and found `kb.html` the only one, already Open Item 6's. **A relative claim ("the corpus grew by two") is stated as NOT closable by any value rule** and routed as prose — an honest residual rather than a silent gap. Orchestrator-verified: **`--list` exists at `check-skill-counts.mjs:309`, is documented at `:47`, and runs**, emitting the derivation as JSON — so the rule is executable, not aspirational — and the derivation carries **ten** scalar fields, which by itself falsifies D4's former "Exactly one derived quantity moves". **The author found that one itself, by checking its own premises rather than the ledger's list**, along with Open Item 7's title being narrower than its own class. **Ownership is now a partition rather than a seal** — cycle 6's six orphaned lines were the defect, and every region now has a named owner. |
| 2026-07-31 | **feature-013 cycle-2 fix — all eight in-scope rows closed; +48** | -- | 760 → **808**. The two HIGHs, five MEDIUMs and the one mechanism LOW all closed. **Row 1's fix inverts the class-4 rows**: `skills/aid-graph.md` + `skills/index.md` become the roster and `reference/skills.md` is declared **owed nothing**, with generator behaviour as the reason. **Row 2's fix re-quantifies `GR07(a)` from files to sites**, one clause per site, each anchored to the sibling's own occurrence — and the orchestrator verified its oracle exactly: `grep -c aid-summarize README.md docs/*.md` returns **14** hits across five files, the author's figure precisely. **Both fixes swept past the ledger's cited sites**, which is the F1 lesson landing: row 1's class turned up `GR09`'s third clause carrying the same defect in the *synced* copy, and row 3's turned up a **`GR*` pin that was a skip rather than an assertion** — a vacuous row the gate had not named. Row 3's remedy is a **`GR01(b)` preflight** asserting the canonical directories present and non-empty *before* any derived set is compared, so ∅ = ∅ can no longer pass; `GR06`'s presence-precondition pattern generalised rather than described. **Row 5 was derived rather than sampled** — every class-1 line read for a numeral that moves, movers and **non**-movers both recorded, with a fourth table column capturing the No answers *with reasons* so the negatives are checkable too. **Row 9 removed weaknesses rather than documenting them**, raising two assertions to set equality instead of writing residuals for them. **Row 7 made the practice match the claim** rather than softening the claim: all ten feature-012 line citations converted to section/row-name form, which also bounds the exposure to a sibling that is still moving. **+48 is a large delta and the gate is briefed to read it as new material.** |
| 2026-07-31 | **feature-013 first gate — D (2 HIGH); AC structure UPHELD; cycle-2 fix dispatched** | **D** | 16 rows, all `Pending`: 2 HIGH, 5 MEDIUM, 4 LOW, 5 MINOR; **6 mechanism / 10 editorial**. Fix scope is **eight** rows — everything at MEDIUM or above (which gates the grade regardless of Q26 class, so the two *editorial* MEDIUMs are in) plus the one LOW that is mechanism. **The feature's central structural claim was independently confirmed:** REQUIREMENTS.md contains **no** acceptance criterion this feature restates — §9 read end to end, and `readme`, `catalogue`, `catalog`, `discoverab`, `docs/` all return **zero** hits, the only two "documentation" hits being "documentation viewer". So declaring `AC-T1`–`AC-T9` as the feature's own is correct, **nothing is smuggled in, and nothing REQUIREMENTS demands is dropped**. **Row 1 `[HIGH]` is the one no amount of reading would have caught, and the orchestrator confirmed it on disk:** `site/src/content/docs/reference/skills.md` is **23 lines titled "Shortcut engine" with zero occurrences of `aid-summarize`** — its own description ends "*where to find* the full skill roster" — because the roster moved to a **112-entry** `site/src/content/docs/skills/` page tree. Three clauses still call the old page the catalogue, and **`GR09` clause 1 would fail against a correct implementation**: a test that fails when the code is right is worse than no test. It is an **F1 failure by the author's own hand** — its hand-off *noted* the new tree existed, then corrected the instance and not the class. **Row 3 makes the vacuity audit the ledger's theme:** the Tests preamble's "a do-nothing implementation fails every one" is false for **four** assertions, each quantified over a set derived from an undelivered directory, so ∅ = ∅ satisfies them; `GR06` is the model, carrying a presence precondition. The reviewer graded per row in both directions — do-nothing *and* populated-but-wrong — and singled out **`GR04` as the best row in the table** for naming its own record-internal half, the exact defect that made feature-008's nineteen hooks vacuous. **Nine candidates were declined with reasons**, including the delivery-006 BLUEPRINT contradictions (a pre-decision artifact; PLAN is being regenerated — but flagged for that regeneration, since the SPEC is right on disk and no feature owns the FR-28 rubric run). ~70 line citations verified exact, including four ranges bracketing their construct precisely. |
| 2026-07-31 | **feature-012 cycle-6 gate — D+; rows 7 + 8 `Fixed`, but a NEW `[HIGH]` that is row 7's own shape one level down** | **D+** | 16 rows: 0 CRITICAL, **1 HIGH**, 0 MEDIUM, 4 LOW, 6 MINOR. Rows 7 and 8 **both `Fixed`**, and re-derived rather than read — the reviewer re-parsed the `CLAIMS` array out of the script (26 entries, matching the 26 literals), replayed it over a faithful reconstruction of the gate's own 541-file walk, compared the retracted quote **character by character including the em dash**, and tested row 8's "cannot fire" claim **adversarially** (the only evasion is an `Object.prototype` key, which is not a real shape). It ruled the **+45 earned** and the deletions lossless. **But row 12 `[HIGH]` is the same defect one level down, and this is now the third consecutive HIGH of one shape:** cycle 4 found that the *gates* are phrasing-keyed; cycle 5 replaced them with *gates ∪ a hand sweep*; **cycle 6 finds the sweep is phrasing-keyed too.** Six lines inside the gate's own corpus carry a live `111` or `17`, match **no** `CLAIMS` pattern in any form — forward join and backward join both tested, strictly more permissive than the script — are not history-shaped, and match **none of the sweep's three shapes**. All six orchestrator-verified on disk. **The extent evidence is unanswerable: cycle-4's row 7 Evidence named `generate-profile/SKILL.md` `:107` AND `:112`; the fix recovered `:107` and still cannot see `:112`** — under-delivery against the extent the finding itself specified, which is F1 exactly. None is in a NOT-YET-SCANNED tree, so Open Item 3 does not reach them, and L3 gives 013 only "a surface *outside*" the corpus — **the six are owned by nobody.** **Cycle 7's brief therefore forbids adding a fourth shape** and requires the structural jump to a **value-keyed** sweep — every occurrence of the literal digits of any `deriveSkillCounts` quantity, minus history-marked lines — which terminates by construction because there is no phrasing left to miss, and which trades false positives (cheap: one read) for the absence of false negatives (expensive: a shipped stale artifact). The reviewer also **declined four candidates with reasons**, one because the sub-decomposition's failure runs the *other* way and only strengthens the case, and **noted without recording** that the fix deleted a verification-scope disclosure — "every line citation re-read on disk after the merge" — which this work's own standing rule makes load-bearing. |
| 2026-07-31 | **feature-012 cycle-5 fix — rows 7 + 8 closed; +45; cycle-6 gate dispatched** | -- | 787 → **832** lines. Rows 9–11 left untouched as deferred editorial, which the gate is asked to confirm. **The fix's best move was to distrust the list it was handed.** Rather than editing the surfaces named in the brief, it **rebuilt the gate's own `CLAIMS` array by parsing the script** and replayed it over the exact corpus (same `INCLUDE_*` sets, same walk, same history-shape skip). That replay confirmed 8 handed surfaces, **added five the brief omitted**, found a **third blind shape nobody had named** — bare arithmetic, `architecture.md:194`'s `17 + 94 = 111`, no noun for any pattern to match — and **correctly excluded three true negatives** (`8 curated domains` ×2, `feature-014 curated them`) that a path list would have sent an implementer to edit. The Q19 remedy follows: the SPEC states **the rule and the command**, not the list and not its length. **Its own vacuity audit killed its first oracle.** It had proposed *summing* as the check — and caught that summing cannot see a lone operand on a line carrying no total, which `generate-profile/SKILL.md:122` is; the shipped oracle is equality against the derivation, with summing as a consequence. It also **re-grounded two claims it had inherited from the cycle-4 reviewer as a coincidence** (111 sidecars for 111 skills) into mechanism, and found `gen-skills.mjs:196–197`'s "charted subset" comment stale as a by-product. **The F1 class sweep ran**: the same false framing was corrected at nine further sites, and AC-R6 was **materially falsified** by the new edit set — a hand-reconciled operand is neither machine-gated nor names a derivation — so it gained a third disjunct. **It also declined to state an ordinal it could not verify**, dropping "the fifth live repo defect" from the SPEC because the count would be a measured quantity under the document's own Figures rule. Everything is first-hand except the cycle-4 landing simulation and mutation, which it labels as reported and did **not** re-run — the evidence-grading discipline stated rather than blurred. |
| 2026-07-31 | **Wave 3d — feature-013 AUTHORED FRESH (293 → 759 lines); gate dispatched** | -- | The last of the thirteen, and it **retro-justifies the whole Q26 fresh-authoring decision in one finding**: the pre-decision draft's § Source cited `REQUIREMENTS.md §9` for two acceptance criteria **that do not exist**. **Verified first-hand by the orchestrator before accepting** — `readme`, `catalogue` and `skill catalog` appear **nowhere** in REQUIREMENTS.md, and §9's only uses of "documented" concern runtime prerequisites and node kinds. **The entire feature had been scoped on a phantom**, and *no* amount of editing that document would have surfaced it, because the defect was in the foundation the edits would have preserved. The new ACs are declared as **this feature's own** (`AC-T1`–`AC-T9`), grounded in §5.9's Decision paragraph, C-2/C-3, FR-7 and the KB — an honest structure in place of a false traceability. **All four post-merge facts changed the content, and re-locating the surfaces surfaced six more errors in the old draft:** `docs/install.md` names **no** skill (count-only, so it is feature-012's); README's `R1` diagram **has no `/aid-summarize` node at all**, so no node is owed and it is the maintenance contract's trigger row that moves; the generated per-skill page tree `site/src/content/docs/skills/` **did not exist** when the draft was written; and the "deliberately open" question of which methodology table to use **is decidable** — table A, since B/C/D are the router, the alias and the catalog. Also falsified: tech-debt **L4** is the *test-effectiveness gap* (the manifest story is evidence *inside* it, not its subject); feature-010 ships **one** suite, not three; feature-011 ships **one unconditional** suite, not two contingent ones; `GR05`'s unconditional byte-identity contradicts feature-012's D3 for a *transformed* file; and "nothing mechanical guards the KB" is **half**-false, since `check-skill-counts.mjs` walks `.aid/knowledge/` for counts (a missing *row* is still unguarded). **The task-057 clamp forced a structural correction:** it lives in `site/` vitest, which `tests/run-all.sh` **never reaches**, so the ship gate is **two commands, not one** — the old draft's single-command aggregate gate was wrong. The author's own vacuity audit and proxy sweep caught **eleven** defects in its own draft pre-hand-off, including a self-contradiction between its Description and its own Change Log, an AC over-claiming relative to the assertion meant to discharge it, a preamble claiming *every* assertion catches a wrong-but-populated implementation when five rows carry residuals, a raw count of an externally-owned set (Q19), and three citations off by a line or a range. It **routed rather than fixed** two real defects: `works/` missing from **three** enumerations rather than the one it first saw (fix-everywhere applied to its own observation), and a live contradiction between `docs/diagram-content-reference.md`'s described `G1–G5` flow and the diagram's actual `GE/GS/G1/G2/G4` — which is the very `G1` node its own class-1 edit targets. ~~**Three claims are explicitly labelled as resting on a sibling's account rather than first-hand**, which is the disclosure discipline working.~~ **CORRECTED 2026-07-31 by feature-013's own gate — and the correction is the orchestrator's seventh error of the same shape.** The SPEC carries **two *first-hand* labels and one blanket "undelivered ⇒ specification only" block**; there is **no per-claim second-hand label anywhere in it.** The claim above was lifted from the author's hand-off report and written into this audit trail **without opening the document** — the identical mistake as errors 4 and 5, committed in the very row praising a disclosure discipline. The gate's verdict on the substance is nevertheless favourable: no load-bearing conclusion rests on an unlabelled second-hand claim, because feature-012's trigger table is cited **by section** (so it self-updates) with the primary source `render.py:77-79` cited and independently verifiable, and it verified `PV20` directly. **The defect was in this record, not in the SPEC.** |
| 2026-07-31 | **feature-012 cycle-4 gate — D+; row 6 `Fixed` but a new `[HIGH]`; cycle 5 dispatched** | **D+** | 11 rows: the cycle-3 MEDIUM closed and **all three merge-falsified claims verified true against source rather than against the author's account**, but **one new `[HIGH]` (row 7) puts the feature below the Q27 floor** — 0 CRITICAL, **1 HIGH**, 0 MEDIUM, 3 LOW, 4 MINOR. Split 2 mechanism / 3 editorial; only rows 7 and 8 are in cycle 5's scope. **Row 7 is the vacuity audit turned on a gate rather than on a test suite, and it is the sharpest instance this work has produced.** D4 Class 1 rests on "the gates decide the edit set"; the reviewer refused to accept a green run as evidence and instead **simulated the landing** — created `canonical/skills/aid-graph/`, added the roster entry, ran the gate, restored the worktree. The gate exits 1 with 62 wrong counts, reports `generate-profile/SKILL.md:106` and **not** `:107` or `:112`, so an implementer who fixes exactly what the gate reports leaves the file reading `112 skill directories = 17 curated + 94 catalog rows` — **a decomposition that does not sum**, which that file's own comment says "is how this file was wrong twice." It then mutation-proved the mechanism with the corpus untouched: injecting `99 curated` / `77 catalog rows` still prints "All 204 stated skill counts agree", exit 0. **The orchestrator confirmed it first-hand by an independent route — reading the regexes rather than re-running the mutation — and found it BROADER than the ledger states.** `check-skill-counts.mjs:97`'s lookahead class `[-—,.)]` holds the **closing** paren, not the opening one, so `17 curated (` matches neither `:97` nor `:96`; and separately **no pattern exists for the bare phrase `N catalog rows`** (`:108–:111` cover `N-row catalog`, `N catalog skills`, `N shortcut-catalog skills`, `(N rows total`). **Both operands of the decomposition are invisible while the total on the line above is checked** — the fifth live repo defect this work has surfaced, routed to the work owner, not fixed here. Second limb: the script's own header comment lists `site/scripts/, tests/, dashboard/, lib/, bin/, packages/` as **NOT YET SCANNED**, flatly contradicting the SPEC's `:435` claim that the gate "reaches them repo-wide" — **on the strength of which Open Item 3 had been withdrawn with the words "none to defer."** The reviewer's ruling on that withdrawal is exact: sound for the item's narrow *body*, unsound for its broad *title*. Also accepted after verification: the empty Class 3 (kept, because CR10 cross-references it), the `dependabot.yml` exclusion (not a `canonical/` path, so D3's render-blind hazard structurally cannot arise), and **+44 as mostly merge-forced** — two-thirds is the D4 Class 2 rewrite against three modules that did not exist pre-merge. It swept for a **fourth roster surface and found none** (three), and found a **third count gate** (`site/scripts/__tests__/skill-counts.test.mjs`) that adds no unique edit. One check it could not complete: no cycle-3 → cycle-4 diff exists, because cycle 3 was never committed — **the third gate in a row to hit that wall**, which is what prompted the commit at `1446eb3c`. It noted the mid-review commit and re-confirmed the reviewed text byte-identical to `HEAD` at 787 lines. |
| 2026-07-30 | **feature-010 cycle-2 gate — B; CLEARS the Q27 floor** | **B** | 10 rows: **all four MEDIUMs `Fixed`**, 0 CRITICAL / 0 HIGH / **0 MEDIUM**, 3 LOW + 2 MINOR uncharged under Q27, 1 OOS. Net **−1** line on the fix (1,113 → 1,112) — the delta discipline from feature-007 held: a fix that adds nothing adds no findings, and this cycle produced exactly **one** new item, `[LOW]` and editorial. **Every one of the four closures was re-derived first-hand rather than read.** Row 2 is the model: instead of checking that the three named checks were added, the reviewer **enumerated every `FAIL`-setting site in `validate-html-output.sh`** — eleven blocks, all funnelling to `:410-413` — confirmed D4 now maps all eleven, then **extended the same oracle to the rest of the invoked set** (`contrast-check.mjs` one exit-1 class; `validate-visuals.mjs` one `process.exit(1)` at `:560`), establishing the invoked set is genuinely five and that feature-007's "S7" label names a check that **appears nowhere** in the script. It also confirmed `check_count()` (`:80-92`) is **truly unreachable** — a grep returns only its definition line — so V-ST correctly grounds on `check()` alone. Row 3's universal rule was upheld by **walking all eighteen SR rows** and finding **eleven** members of the deleted-path class, proving a parenthetical list would itself have been the F1 defect one level up. Row 4's diagram deletion was verified by re-running the structural diff with `SequenceMatcher(autojunk=False)` **plus an order-free shared-line pass** — because a greedy matcher hides re-ordered blocks, and it did hide one (`:570`); result **zero** shared multi-line non-heading blocks. **The three merge-broken clauses are all soundly re-grounded**, and the reviewer swept **all citation forms, not just `<doc>:<line>`** — catching that the orchestrator's own twelve-file list **omitted `INDEX.md`** (harmless: no line citation into it), and confirming both **section-quoted** references at `:573` survive, the form most likely to evade a line sweep. It further **intersected the merge's full 504-file list against every canonical path the SPEC cites**: only two canonical files moved and the SPEC cites neither — its `writeback-state.sh:204` is qualified to the `summarize/` twin. **Two things it correctly reported it could not do:** the −1 delta is unverifiable from git, because cycle 1's fresh authoring was never committed (`HEAD` and `3fc7cdb4` are byte-identical for this path), so the itemised payment rests on the author's account; and the D4 rubric could not be executed against a real run, since `scripts/graph/` is undelivered — the `R*` severities are adopted from feature-003 as a *document*, not as behaviour. **Three candidate findings declined with reasons** after verification, including a `state-*.md` naming collision that dissolved on reading § Source's own scoping sentence. |
| 2026-07-30 | **A+ gate feature-004** (Q24 item 1) | **A+** | Confirmed. Re-gate round-3/4 fixes verified landed: ledger `feature-004-spec.md` carries 19 rows, **all `Fixed`**, `grade.sh --explain` → **A+** with 0 findings at every severity. Q22's reopen (the half-unreachable `qualifier` value space) is closed by D3a's four assigning rules + total carrier→value map. feature-004 is now a **confirmed** immutable input for features 006 and 007. |

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
  The table was eight columns at the time of this resolution. **Superseded 2026-07-29 (Q14): the
  table is now TEN columns** — `Source Kind` and `Target Kind` were added by owner decision. Dropping
  `Strength` still stands and is not reinstated. Recorded at REQUIREMENTS.md §5.2.
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

### Q9

- **Category:** Architecture
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — **the graph must be LIVE.** A continuously
  simulating force-directed graph in the style of Obsidian's core graph view (nodes drift and
  settle, dragging pulls neighbours, hover focuses a neighbourhood and dims the rest, depth via
  glow and size), built on `d3-force` for physics + **PixiJS (WebGL)** for drawing. True 3D with an
  orbit camera was considered and **not** adopted. NFR-4's settled render is the **reduced-motion
  fallback**, not the default. The canvas is **visual-only**: WCAG AA is met by the accessible table
  view as the conforming equivalent (NFR-2), with no DOM proxy over the canvas.
- **Context:** task-005's decision record recommended a **static** SVG graph that settles once
  before first paint with no animation. That is a picture of a graph, not a graph. It contradicted
  two requirements already on the books: NFR-4 ("reduced-motion **disables layout animation**")
  only means something if the default path animates, and FR-16 directs the research to "optimise
  for **interaction quality**." The record instead optimised for payload size and free
  accessibility, landing back on the pre-amendment answer that FR-16 was rewritten to move away
  from. Three review cycles and an A+ delivery gate did not catch this, because all eleven gate
  criteria tested the record's **completeness and traceability** — fifteen parts present, exactly
  one approach named, rejections stated — and none tested whether the recommended artifact is
  alive. Raised by the owner on reading delivery-001's findings report.
- **Consequence:** feature-002's decision record is superseded; feature-008's ~279-line estimate is
  void; and two conditional verdicts flip — a WebGL canvas matches none of `validate-visuals.mjs`'s
  three selectors, so tasks 084/085 become a recorded no-op instead of live work, while task-083
  still fires (PixiJS and d3-force are both vendored third-party code).

### Q10

- **Category:** Requirements
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — **the vocabulary must be generic and the node
  model must widen.** (a) The vocabulary is derived from **standards** — SKOS, Dublin Core, PROV-O,
  schema.org, IANA link relations, CiTO — verified expressible against a real repository but not
  limited to what this repository contains. (b) **Concepts and facts are first-class nodes,
  distinct from the files that define them**, as are images, web pages, and sub-file anchors
  (sections, code snippets, symbols). (c) The vocabulary is a generic **core plus a per-project
  extension**, validated by the same five inverse-pair rules.
- **Context:** The shipped vocabulary has 8 pairs / 15 entries / 5 categories, harvested **only**
  from this repository's own frontmatter carriers (`see_also:`, `sources:`, `CONFIRMED` anchors,
  `generated-files.txt`). Its own evidence file records decisions of the form "Keep
  `["int:->int:"]` only — the only harvested instance is script→data file," which is fitting a
  shipped artifact to one repo's observed instances. **No standard relation vocabulary was
  consulted anywhere** in the research or feature-001's SPEC (verified by search: zero hits for
  SKOS, Dublin Core, dcterms, PROV-O, schema.org, RDF, OWL, CiTO, RFC 8288, ontology). Whole
  families are absent: part–whole, concept hierarchy (broader/narrower), versioning/supersession,
  provenance/derivation, representation/format, depiction (images), implements/tests,
  defines/exemplifies, identity/similarity, contradiction/support, sequence, alternatives,
  annotation. The root cause is the node model: nodes are **files**, and file-to-file relations are
  inherently few, which is why 8 pairs looked sufficient. A corroborating tell — the measured graph
  has **zero `ext:` nodes**, so the external half of the vocabulary was closed with no real
  instance to test against. Raised by the owner: "did you check if it is generic enough to cover
  any repo?"
- **Consequence:** feature-001 must be re-researched standards-first; features 003 (table schema
  and node identity), 004 (source enumeration) and 005 (extraction) must be re-specified — the
  spine of delivery-002. A **genericity FR is owed**: no requirement ever asked the vocabulary or
  node model to generalise beyond this repository, which is why the narrowing violated nothing.

### Q11

- **Category:** Architecture
- **Impact:** High
- **Status:** Resolved 2026-07-29 by owner decision — **directed, labelled, colour-coded edges.**
  The graph diverges deliberately from Obsidian's in three ways: edges carry **direction** (an
  arrowhead read Source→Target for asymmetric relations), each edge shows its **relationship
  name**, and **colour** distinguishes node types and relationship categories. Obsidian's graph is
  undirected, unlabelled, and coloured only by user-defined groups, so none of this is inherited
  from the reference architecture.
- **Context:** The eight-column schema (§5.2) already carries both directions per row (`S2T
  Relation` / `T2S Relation`), so direction is information the data has and the view was discarding.
- **Consequence — this is now the binding rendering cost.** Edge labels are per-edge text objects
  (~750 at bench scale) redrawn every simulation tick, requiring overlap management, and in WebGL
  each label becomes a texture. Obsidian is fast partly *because* it draws no edge labels, so its
  performance is not evidence that labelled edges perform. The superseded research measured node
  and edge paint only and **never measured text at all**. It also satisfies **NFR-5** structurally:
  node shape carries type alongside colour, and the edge label carries relationship category
  alongside colour, so colour is never the sole carrier.
- **Amended 2026-07-29 — persistent edge labels dropped.** The owner offered to drop the label
  requirement in exchange for colour-coding. Settled encoding: relationship category carried by
  **colour + line style** (solid/dashed/dotted/dash-dot), the relationship **name shown on hover or
  selection**, and full names always present as text in the accessible table view. This removes the
  per-tick text cost — the actual bottleneck — while keeping the information reachable.
- **NFR-5 was considered for relaxation and retained, on evidence.** The owner offered to relax
  "colour is never the sole carrier." Verified against w3.org/TR/WCAG22 (accessed 2026-07-29):
  this is **SC 1.4.1 Use of Color, Level A** — the lowest tier — and AA conformance requires all
  Level A criteria (or a Level AA conforming alternate version). Relaxing it would forfeit NFR-1's
  AA claim, the bar `kb.html` already holds, and would buy **no performance**: line-dash patterns
  are set once per line and cost nothing per frame. Declined. The conforming-alternate-version
  route (the table view) stays available but unused for colour, so the graph itself remains
  conformant rather than resting conformance entirely on the table.
- **Open sub-questions for the replacement research:** how symmetric relations render, given they
  have no direction; and whether colour keys on relationship **category** rather than individual
  relation **type** (thirty-plus would exceed any palette). **Design ceiling:** beyond roughly 8
  colours and 4 line styles simultaneous distinction fails for all users, so a high category count
  must be answered by interactive filtering/highlighting by category, not more visual channels.

### Q12

- **Category:** Requirements
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — **granularity is asymmetric: deep in the
  Knowledge Base, whole-artifact in code.** Concepts, facts and document sections are first-class
  nodes; images and web pages are nodes with their own kinds; source files remain whole artifacts
  with **no** function/symbol nodes.
- **Context:** The widened node model (Q10) collided head-on with two existing requirements.
  **FR-23** stated granularity is "the **whole artifact** — a script, a skill, a template — never
  individual functions or lines," which cannot coexist with sections and snippets as nodes.
  **A-5** asserted "node counts land in the hundreds, not tens of thousands," and that assumption
  is what the entire rendering bench was built on.
- **Consequence — the scale basis of all prior rendering work is void.** Measured on this
  repository under the new model: 21 KB documents + 32 glossary concepts + 227 `CONFIRMED` facts +
  336 sections + 25 fenced snippets = **641 nodes from 21 files**, before adding 583 whole-artifact
  source nodes — so **~1,200+ nodes**, not 784. FR-23 is rewritten and A-5 is voided. The
  replacement rendering research must derive its own bench from the widened model and may not
  inherit the 784-node figure or the "bounded to the hundreds" premise; layout tractability is now
  a finding it owes rather than an assumption granted to it.

### Q13

- **Category:** Requirements
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — **node semantics, dedup, performance floor and
  click behaviour settled.** (a) A **fact** is a claim carrying a checkable source anchor — the
  inline `CONFIRMED <path> (search: "…")` anchor in an AID repo, or generically any statement with
  an explicit resolvable reference to its supporting source; its provenance is therefore always
  `declared` or `derived`, never `inferred`. (b) A **concept** named in five documents is **one**
  node, merged on its normalised defined term and keyed to the glossary entry where one exists;
  each mention is an **edge**, so mention count becomes degree rather than duplicate nodes.
  (c) The performance floor is **≥30fps sustained at the derived bench during steady simulation and
  node drag**, measured headless via the Playwright harness FR-12 reuses; settle time is reported,
  not gated. (d) Clicking a **concept** node opens its **defining document**, falling back to the
  highest-provenance mentioning document (`declared` > `derived` > `inferred`).
- **Context:** Q10 made concepts and facts first-class nodes without defining either, which left
  four implementer-blocking questions. The "fact" definition additionally had to survive in a
  repository that does not use AID's citation convention, since Q10 also made genericity binding.
  A concept node, unlike an Obsidian note, owns no single file, so Obsidian's click-to-open has no
  direct translation. And **no requirement stated any performance target**, which made "live"
  — the entire point of Q9 — unverifiable by any acceptance criterion.
- **Consequence:** the fact definition bounds the node count and keeps FR-24 intact, and its
  graceful degradation is *itself* the §2 purpose-1 signal: a KB making unanchored claims yields no
  fact nodes, which is exactly the "unbacked KB claim" defect the gap ledger reports. The concept
  merge rule converts duplication into degree, which materially changes the graph's shape and hub
  distribution — so the replacement rendering bench must be derived **after** this rule is
  implemented, not before.
- **Sub-rules still owed to the SPEC (author-level, not owner-level):** the exact concept-label
  normalisation (case, whitespace, punctuation, plurals); a disambiguation rule for two distinct
  concepts sharing one label; and confirmation that gating frame rate while only reporting settle
  time is the intended split.
- **Scope note:** **FR-13's Impact lens already is the "local graph"** — "select a node, show its
  neighborhood to an adjustable depth." It was nearly re-proposed as new scope. The open question is
  only whether each of the four lenses still means the same thing over concept nodes.

### Q14

- **Category:** Requirements
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — eight open items settled after a clause-by-clause
  impact map (85 clauses examined; 27 affected, 58 surviving) and a 28-row completeness review.
  1. **Genericity scope** — any project with an **approved AID Knowledge Base**. FR-7/FR-8 already
     gate on one, so the claim is bounded and testable and the KB's conventions are usable carriers.
  2. **"Concept"** — a glossary entry or convention-marked defined term, and nothing else. No
     glossary ⇒ no concept nodes, which is itself a quality signal. Chosen partly because a concept
     id then resolves by grepping its definition, keeping AC-1 mechanically checkable.
  3. **Node kind** — carried by **explicit `Source Kind` / `Target Kind` columns**. The author
     recommended splitting the id prefix instead; that was **not** adopted, and `kb:`/`int:`/`ext:`
     stands unchanged.
  4. **Fenced code blocks** — not nodes; content within a section.
  5. **Symmetric relations** — render with **no arrowhead**.
  6. **Filtering by category** — a **required** feature with its own acceptance criterion, not
     advisory, because it is what keeps a large vocabulary usable past the ~8-colour ceiling.
  7. **Scale** — degradation is **out of scope**: measure the ceiling, document it, warn past it,
     build no degraded mode. This replaces voided A-5.
  8. **Parked questions** — **Q5** resolved: `graph.html` stays deliberately unreachable from the
     dashboard, with the local-file entry point recorded as intended. **Q8** resolved: ledger
     retention is lifted out of this work into its **own methodology work item**, raised now.
- **Consequence — the table is now TEN columns and this is the widest ripple of the redesign.**
  Shape: `Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T
  Relation | T2S Relation | Provenance | Observation`. A search across the work finds **34 void
  "eight-column" references in 23 files** — feature SPECs, task DETAILs, delivery BLUEPRINTs and
  PLAN.md — including a literal test assertion in task-063 ("Exactly eight columns are rendered …
  with **no ninth**") that would now fail by design.
- **Consequence — `Kind` is a second closed vocabulary.** Enum: `document`, `concept`, `fact`,
  `section`, `source-artifact`, `image`, `web-page`, each pinned to a required prefix, loaded
  fail-closed, with a **new cross-consistency validator** asserting kind and prefix agree so the
  two cannot drift.
- **Amendment sequencing decision (author's).** The 34 references are **not** being patched
  individually. `REQUIREMENTS.md` and `PLAN.md` are hand-amended because they are the source of
  truth; the feature SPECs and task DETAILs are **regenerated** by re-specification and
  re-detailing, so editing them now would be discarded work.
- **Standing technical risk to check first.** C-5 requires Playwright visual validation to degrade
  gracefully when the browser is unprovisioned. A WebGL canvas adds an unconsidered failure mode:
  Playwright provisioned but the headless browser has **no GPU/WebGL support**, which would break
  FR-12's reuse of `/aid-summarize`'s visual-validation toolchain outright. The replacement
  rendering research must resolve this **before** any performance work, since it could invalidate
  the renderer choice a second time.

### Q15

- **Category:** Process
- **Impact:** High
- **Status:** Resolved 2026-07-29 — **REQUIREMENTS.md re-graded A+ after the redesign.** Six adversarial
  review cycles over the amended document; **46 findings, all Fixed, zero Pending or Recurred**
  (`grade.sh` over `.aid/.temp/review-pending/requirements-completeness.md`). The document grew from
  ~530 to 939 lines and from 74 to 94 clauses.
- **How the cycles went, since the pattern is the useful record:** 28 findings (11 CRITICAL, 8 HIGH)
  → 7 → 4 → 3 → 1 → 1. Severity fell from CRITICAL/HIGH to LOW as the work shifted from contradictions
  and undefined artifacts to acceptance-criteria gaps. The reviewer was asked directly whether
  continuing had value and answered that the remaining items were SPEC-author work; the last two were
  fixed anyway because the owner's bar is a clean ledger.
- **What the cycles caught that a single pass would not have:**
  - **Two unreliable numbers.** A KB node count of 641 that wrongly included the 25 excluded snippets
    (correct: 616), and a source-artifact count of **583 that is unreproducible** — inherited from the
    superseded research, which is known to have contained fabricated figures. Both had already
    propagated into NFR-7 and AC-6a as a performance target. Every node count is now withdrawn from
    the requirements and the bench is a research deliverable.
  - **A bound that would have deleted a capability.** A first draft of FR-31a forbade Pass 2 to "look
    for additional relationships" — which reads as rigour but would have banned the `inferred`
    concept-to-concept edges the two-pass design exists to produce. Rewritten to bound what Pass 2 may
    **read** and **create**, never whether it may discover.
  - **A phantom artifact.** FR-8a and AC-19 reported convention absences to a "run summary" that **no
    requirement created**. Replaced by FR-9a's `## Coverage notes` inside `relationships.md` — an
    artifact that already exists, is schema-validated, indexed, and covered by FR-32.
  - **Two WCAG Level A criteria that would have been missed.** SC 1.4.1 (colour not the sole carrier)
    was considered for relaxation and retained on evidence; SC 2.1.1 (keyboard) was uncovered for the
    new select/open/filter gestures until NFR-6 was widened and AC-21 added — because AC-7/AC-8/AC-8a
    test whether controls *work*, not whether they can be *reached*.
  - **Three requirements that were satisfiable while wrong.** FR-9a produced notes only on failure;
    AC-12 named two of five staleness inputs; FR-32/AC-5 said "unchanged repository" while the
    vocabulary ships inside the tool.
- **Two author errors worth recording rather than hiding:** D-6 was **deleted** by a two-step move whose
  re-insertion silently failed, caught only by a shell count afterwards; and new clauses were twice
  inserted out of numeric order after the reviewer had already flagged that same defect. Both argue for
  verifying with independent counts after every edit batch rather than trusting edit-tool success
  reports, and for never doing a move as remove-then-insert on a large file.
- **Still owed to the SPEC (author-level, deliberately deferred):** heading slugification; the
  `<anchor-token>` format; concept-label normalisation and a same-label disambiguation rule;
  section-id stability under heading renames; the vocabulary extension file's location, format and
  precedence; and the mechanism by which a test harness patches the tool-internal vocabulary to
  exercise AC-12's fifth input.

### Q16

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Resolved 2026-07-29 by owner decision — **no `agent` node kind.** The agent-half relations
  of the standards (PROV-O `wasAttributedTo`, DCMI `creator`, CiTO's author network) are **not
  imported**, and **the graph deliberately cannot answer "who wrote this."**
- **Context:** Surfaced by feature-001's standards-first re-specification, which found that these are
  perfectly expressible *relations* whose *endpoints* `Kind` cannot name — the enum has seven values
  and none is an agent. It is a node-model limit, not a traversal gap.
- **Grounds:** none of §2's four purposes (drift/coverage detection, onboarding, impact analysis, RAG
  routing) needs authorship; no resolvable agent registry exists in this project, so AC-1's
  resolvability could not be satisfied for such a node; and adding one would touch §5.2, §5.3,
  feature-003's loader and feature-004's enumeration.
- **Recorded as a boundary rather than an omission** — in the change log and inline at §5.2 — so a
  later reader does not mistake it for an oversight and re-open it.

### Q17

- **Category:** Process
- **Impact:** High
- **Status:** Recorded 2026-07-29 — **a defect class worth hunting deliberately: clauses whose MEANING
  changed while their WORDING did not.**
- **Context:** AC-15 and FR-20 scoped the KB-gap class to the **`int:` prefix**, which was exact while
  `int:` meant source artifacts alone. The widened node model put in-repo `image` nodes on the same
  prefix, silently making both clauses wrong — an unreferenced picture would be either lens-highlighted
  with no ledger row (breaking AC-15's equality) or reported as undocumented project source. Both are
  now keyed on **`Kind = source-artifact`**.
- **Why it matters as process:** the impact map classified AC-15 as **SURVIVES**, and six adversarial
  review cycles passed over it. Nothing that reads a document in isolation catches this, because the
  text never changed — it surfaced only when feature-004 tried to implement it. Load-bearing detail:
  FR-26 derives gap severity from FR-21's significance qualifier, and an `image` qualifies **by kind**
  under FR-21a and so carries no qualifier at all.
- **Standing instruction for the remaining re-specification:** when a model changes, sweep for clauses
  that are keyed on a **proxy** for the thing that changed (a prefix standing in for a kind, a count
  standing in for a set, a path standing in for a role) — those are the clauses that break without
  editing.

### Q18

- **Category:** Process
- **Impact:** Critical
- **Status:** Resolved 2026-07-29 by owner decision — three rulings from feature-005's re-specification,
  one of which is a standing principle that binds every gate in this work.
  1. **Unreachable relations are kept; W3 reports reachability per project.** Ten of 31 pairs have no
     producer. Pruning to what this repository can produce would repeat the fit-to-this-repo error the
     re-specification exists to correct, and FR-5 prefers comprehensiveness.
  2. **The undetectable false merge must be CLOSED before A+** — the owner **overrode** the author's
     recommendation to accept it as a bounded, recorded blind spot. Silent wrong edges corrupt the
     trustworthiness the tool exists to provide. The detection mechanism must respect FR-24: decidable,
     and surfacing *candidates* advisorily rather than asserting a defect it cannot prove.
  3. **"If there is a defect, the A+ is false."** A gated SPEC is reopened whenever a real defect is
     found in it. The cost of reopening is never an argument against it.
- **Why ruling 3 matters beyond this decision:** it changes what a gate grade *is*. Not a milestone
  banked and then defended, but a live claim about the artifact — so a grade that coexists with a known
  defect was never true, and "it already passed" is not a defence. feature-004 is gated A+ and is
  **reopened** if the gate confirms its `dependency` observation conflates six semantics and thereby
  denies `generated-by` and `has-member` their producers.
- **Author-side note on ruling 2.** The author's argument for accepting was that the underlying
  condition — an ambiguous glossary — is itself the KB defect §2 purpose 1 exists to surface, and that a
  heuristic would hide the hole rather than close it. That reasoning was not wrong about the risk of a
  heuristic; the owner's ruling is that the risk must be managed rather than used as grounds to leave
  the defect undetected. Both concerns are satisfiable by an advisory candidate report, which is what
  the constraint on the mechanism encodes.

### Q19

- **Category:** Process
- **Impact:** High
- **Status:** **CLOSED 2026-07-29 — reopened, fixed, re-gated A+.** First application of "if there is a
  defect, the A+ is false" to a grade already awarded, and it worked as intended: the grade was
  withdrawn, the defect fixed in two cycles, and the grade re-earned rather than restored by assertion.
  The SPEC went 1,642 → 1,813 lines; the ledger closed at 6 rows, all Fixed.
- **What the reopen produced beyond its own fix** — the reason this cycle paid for itself several times
  over:
  - **A requirements defect.** Chasing the wave-3 justification revealed that **FR-11's staleness set
    omitted the tool itself**, so a tool upgrade changing what is emitted would trip no staleness check
    and the artifact would go silently stale. **Input 6 added.** That was the *third* instance of the
    same omission after `settings.yml` and the vocabulary.
  - **A proxy defect committed by the orchestrator.** "Five" was hardcoded in FR-11, FR-32, AC-5 and
    AC-12 — a **count standing in for a set**, the exact Q17 pattern, written hours after Q17 recorded
    the warning. All four now cite the set; FR-11 states the list is authoritative, not its cardinality.
  - **Eleven further count-as-proxy instances** removed across feature-003, spanning FR-11's inputs,
    feature-001's entry keys and cross-entry properties, §5.2's `Kind` cardinality and the profile set.
  - **A refinement to Q17 itself:** not every numeral is a proxy. A count that **is** the contract stays
    — D1's ten columns, where the number is normative and changing it is a breaking change by design.
    The standing rule now carries that exemption explicitly, and the sweep was verified in **both**
    directions: no normative count weakened, no real proxy left standing.
- **A fourth defect class, from the same finding:** *a sound conclusion resting on a false premise.* The
  wave-3 argument's conclusion was correct throughout, which is why it passed a gate — only checking the
  justification found the mechanism did not exist. The false premise is preserved in an inline
  correction box rather than overwritten, because the transferable lesson is how it survived review.
  Joins fabricated figures, proxy-keyed clauses and phantom artifacts; all four survive any check that
  stops at "does this read correctly."
- **The defect.** feature-003 D7a permits **extra rows** below the fixed coverage-note rows and has V14
  check only the fixed part, ignoring the rest. But AC-5 **byte-compares the whole `## Coverage notes`
  section**. Those two statements cannot both hold safely: the byte-identity guarantee is contingent on
  an ordering feature-003 never specifies, so **its own guarantee is unachievable as written**.
- **How it surfaced — an accumulation no single feature could see.** Six extra rows now exist across
  three specs: feature-003 requires two (`fact-unanchored`, `section-empty-slug`), feature-004 adds two
  (`image-external`, `source-artifact-dropped`) to `coverage.tsv`, feature-005 adds two
  (`concept-qualified`, `concept-merge-candidates`) to `kb-coverage.tsv`. feature-010 assembles the two
  files, and **no gated SPEC states the order of extra rows across them**. Every individual decision was
  reasonable and locally invisible; the aggregate breaks FR-32/AC-5 reproducibility. Nobody owned the
  total.
- **Remedy.** Reopen feature-003 for a surgical change: require extra rows to carry a **defined total
  order** so byte-identity holds regardless of how feature-010 assembles them. feature-005 files the
  aggregate Open Item naming feature-003 (ordering contract) and feature-010 (assembly) with the
  reopen consequence stated; it deliberately does **not** specify the ordering itself, which would be
  the silent divergence the routing discipline exists to prevent.
- **Process note worth keeping.** This is the third defect class found only by cross-feature reading,
  after Q17's proxy-keyed clauses and feature-005's disposition-versus-byte-identity collision. All
  three were invisible to document-scoped review and surfaced when a later feature consumed an earlier
  one — evidence that the wave ordering is doing real work, not ceremony.
- **A second finding from the same gate, resolved by precedent rather than by weakening a check.** The
  false-merge detector's condition 4 will rarely fire on this well-connected KB, risking AC-S7 passing
  **vacuously**. Handled the way **A-6/AC-1** already handles the `ext:` branch — validated against a
  synthetic fixture *because* the real repository cannot exercise it — plus a diagnostic reporting how
  many pairs satisfy conditions 1–3 but fail condition 4, which quantifies the detector's reach instead
  of hiding it. Condition 4 was **not** relaxed: trading a silent under-report for a stream of false
  positives is the thing FR-24 forbids more strongly.

> **Disambiguation (added 2026-07-30).** **Two entries below are numbered Q20** — this one
> (*feature-003 loader sync*) and *REQUIREMENTS A-5 figure* — so a bare "Q20" citation is ambiguous by
> inheritance. Flagged by feature-006's re-gate. Neither is renumbered, because both are cited by number
> across several SPECs and renumbering would break live inbound references for no correctness gain — the
> same call feature-003 made for its own Open Item 12. **Every future citation must carry the suffix:**
> `Q20 (loader sync)` or `Q20 (A-5 figure)`. Existing bare citations resolve by content: the
> **standing correction about checking the inbound open-item queue** is *this* entry (loader sync), and
> the **read-every-occurrence practice** is the A-5 entry.

### Q20 — feature-003 loader sync (CLOSED)

- **Category:** Process
- **Impact:** Critical
- **Status:** **CLOSED 2026-07-30 — feature-003 reopened, fixed over two cycles, and re-gated A+.**
  *(Was: OPEN 2026-07-29 — verified on disk at handoff: feature-003 loader example still seven-key /
  prefix-keyed `endpoint_kinds`; feature-001 ships eight-key + `derived_from` + `<kind>-><kind>`.
  "Reopen feature-003 before relying on its grade for loader work." Found by open-item triage, not by
  any gate.)*
  **How it closed.** All four inbound items landed; cycle 2 found 6 further defects **in the prose
  cycle 1 added** (grade C) and cycle 3 cleared them at **A+** — 12 ledger rows `Fixed`, 0 counting.
  The defect this entry was opened for is now **disproved rather than asserted fixed**: the reviewer
  re-derived feature-001's declared token sets mechanically and confirmed **every** `<kind>-><kind>`
  side is in `relationship-schema.yml`'s `kinds:` enum (the only outliers being `a`/`b` metavariables
  and the deliberately-illegal `document->agent` counter-example) and that **no** standard token
  violates the `derived_from` grammar — so the loader can no longer reject the vocabulary it exists to
  load. Two items were only **partly** owed, because this SPEC's earlier Q17 count-as-proxy sweep had
  already replaced the relevant numerals with citations; the standing rule paid for itself
  prospectively. **Ledger retention note:** two `OOS` rows remain by design — FR-4's five-vs-six count
  (fixed by the orchestrator in REQUIREMENTS) and E2 below.
- **The contradiction, verified on disk.** feature-003's loader contract specifies a **seven-key** entry
  in fixed order (lines 926, 959, 1001), carries a **prefix-keyed** `endpoint_kinds` example
  (`["kb:->int:", "kb:->ext:"]`, line 986), and mentions `derived_from` **zero times**. feature-001 now
  ships an **eight-key** entry with `derived_from` required at position 5 and `endpoint_kinds` re-keyed
  to `<kind>-><kind>` — and states "eight keys required → exit 2". **The loader as specified would
  reject the vocabulary it is meant to load**, on an unknown key and on totality.
- **Both specs are gated A+.** Under Q18 ruling 3 the grade is false and feature-003 is reopened.
- **This is an orchestration failure, not a subagent's.** feature-001 correctly routed **four** loader
  changes to feature-003 (the eighth key, the token re-key, a sixth contract property, and V12's
  re-key plus the unobserved-token report). The orchestrator then reopened feature-003 **twice** — for
  the extra-row ordering (Q19) and for the wave-3 prose correction — and re-gated it both times
  **without scheduling those four items**. The earlier gate's ruling that "feature-003 can be A+ while
  `endpoint_kinds` remains open; feature-001 cannot" was correct **when made**, because V12 was
  advisory and the vocabulary had not yet changed. It expired silently when feature-001 shipped the
  re-key.
- **Why no gate caught it.** Each gate reviewed one SPEC against the requirements and its declared
  inputs. Nothing in either document is internally wrong; the defect exists only in the **relationship
  between two specs**, and it was created by a change to the *later* one after the *earlier* one had
  been gated. This is the fourth cross-feature defect class in this work, and the first that a gate
  could not in principle have found.
- **Standing correction to orchestration.** An Open Item routed **into** a gated SPEC is a **pending
  reopen**, not a note. It must be scheduled before that SPEC's grade is relied upon, and reopening
  that SPEC for an unrelated fix is **not** an opportunity to leave it unscheduled. Concretely: before
  any re-gate, check the inbound open-item queue for that SPEC — not just the ledger.
- **Remedy.** Reopen feature-003 for all four loader changes together with the row-6 prose fix already
  in flight, then re-gate against feature-001 as a fixed input rather than against the requirements
  alone.

### Q20 — REQUIREMENTS A-5 figure (CLOSED)

- **Category:** Process
- **Impact:** Critical
- **Status:** **CLOSED 2026-07-29 — REQUIREMENTS.md's A+ reopened, corrected, and re-verified.** Five
  defects were fixed, all of them the orchestrator's: A-5's forbidden-count figure, its root in
  change-log line 55, FR-18 item 2's copy of the figure, a duplicated §5.2 `agent` paragraph (one copy
  saying the enum was "closed at seven" — a count-as-proxy), and **NFR-5's unmeasured "line style costs
  nothing per frame"**, now a verdict the FR-18 research owes. Two change-log entries asserting
  withdrawn figures were annotated. Re-verified by reading **every** occurrence of 616/422/583/784/1,200
  in full rather than counting them: no live clause asserts a bench size, and the requirements ledger
  grades **A+**.
- **A verification lesson, separate from the defects.** The first correction was checked by grepping for
  the phrasing the author remembered; the number still appeared four times and those occurrences were
  classified **by count rather than by reading**. Two were live assertions, and the gate caught them.
  That is the same error as counting bare `CONFIRMED` tokens and assuming they were anchored — one level
  up. **Standing practice: to verify a figure is gone, read every occurrence; a count of occurrences is
  not evidence about their nature.**
  Second application of Q18 ruling 3, and the first to the document every other artifact is graded
  against — ruling 3 grants it no exemption.
- **The defect, and it was the orchestrator's.** A-5 asserted "**616** KB nodes … each figure verified by
  count." Its fact term was **227 occurrences of the bare token `CONFIRMED`**. But Q13 defines a fact as
  a claim carrying a **checkable source anchor**, and feature-003's gated D2a-2 states that counting
  every `CONFIRMED` occurrence "would manufacture nodes that resolve to nothing." Only **33** lines in
  this KB carry both `CONFIRMED` and an anchor string. So the total was built from **precisely the count
  the schema forbids** — recomputed on the anchored definition it is ~422 — and it was presented to the
  owner as verified.
- **Why it survived.** The arithmetic was checked and the input never was: 21 + 32 + 227 + 336 = 616 is
  correct, and 227 is a real count of a real token. Verifying that a sum adds up says nothing about
  whether the right quantities were summed. This is Q17's fourth instance and the first hiding **inside a
  figure presented as verified**, which makes it the most dangerous variant so far — a stated
  verification suppresses exactly the scrutiny that would catch it.
- **The remedy is to state no figure.** A-5 now gives the **derivation** — documents + glossary concepts +
  H2–H6 sections + facts-as-Q13-defines-them, snippets excluded — and asserts no total for either the KB
  or the source-artifact term. The fact term is owned by feature-003's definition and the bench is a
  research deliverable (FR-18), so a requirement hardcoding a derived quantity is wrong the moment the
  derivation moves. That is the general lesson: **requirements state derivations, research states
  figures.**
- **Also corrected:** D-2a understated its prerequisite set, naming only feature-005 when the bench has
  three terms and two producing features (feature-004's enumerator supplies the non-KB term). Mitigation
  recorded — feature-002 splits measurement into a parametric response surface measurable *before*
  extraction lands plus a later project-specific lookup, so the serialisation delays a verdict rather
  than all measurement.
- **Standing consequence:** every remaining figure in the requirements is now suspect by default. Wave 3
  reviewers should treat "verified by count" as a claim to re-derive, not a credential.

### Q21

- **Category:** Requirements
- **Impact:** High
- **Status:** Resolved 2026-07-29 by owner decision — **REQUIREMENTS' A+ reopened a third time**, both
  defects found by feature-007's re-specification. feature-007 itself re-specified 925 → 1,707 lines.
  1. **FR-13's Coverage lens carried TWO proxy defects in one clause.** It read "unbacked `kb:` nodes and
     undocumented `int:` nodes". `kb:` now spans four kinds, so read literally the lens floods with
     `section` and includes `fact` — which is **structurally unbackable**, since FR-30 emits a fact node
     and its anchor edge together, so an unbacked fact means corrupt extraction rather than a KB gap.
     **Owner: narrow to `{document, concept}`; an unbacked `fact` is an integrity warning.** The clause's
     `int:` half is the *same* defect already corrected in AC-15 and FR-20 — **this clause was missed** —
     now keyed on **`Kind = source-artifact`**.
  2. **FR-14a specified an unachievable open target.** A `web-page` node was to open "its resolved URL",
     but FR-3 forbids it: §5.3 keeps raw URLs out of the table, so the view holds an opaque `ext:<key>`.
     **Owner: open `./external-sources.md`**, the file that resolves the key — honest, mechanically
     checkable, FR-3 intact. Rejected: carrying the URL, which contradicts §5.3 and reopens features 003
     and 005.
- **Sweep consequence.** Chasing these found two further clauses needing attention: **AC-15's
  cross-reference** to FR-13's domain was stale and is updated, and **FR-19's `int:`** is now annotated as
  **deliberate prefix scoping rather than a proxy** — it names the discovery mechanism (a walk of the
  project source, which legitimately yields both `source-artifact` and in-repo `image`), not the gap
  class. That distinction is the refinement Q17 needed: **a prefix is correct when the clause is about
  where nodes come from, and wrong when it is about what class they belong to.**
- **Running tally of the proxy pattern: six instances, three of them the `int:`-for-`source-artifact`
  substitution** (FR-20, AC-15, FR-13). Each was found by a different downstream feature attempting to
  implement the clause, never by reading the requirements alone.
- **A monitoring note on the author's own diagnosis.** feature-007's agent was mid-task declared "stuck"
  after ~100 minutes of silence, on the evidence of an unwritten transcript and an unmodified SPEC. It
  was not stuck — it was reading ~9,000 lines of required input before its first write, and it completed
  successfully. **Absence of output is not evidence of absence of progress when the input load is large**;
  the correct signal would have been a growing transcript over a longer window, not a snapshot.

### Q22

- **Category:** Process
- **Impact:** High
- **Status:** **feature-004's A+ REOPENED 2026-07-29** — third application of Q18 ruling 3 to an awarded
  grade, found by feature-006's re-specification. feature-006 itself re-specified 573 → 1,162 lines.
- **The defect: a declared value space that is half unreachable.** feature-004's `qualifier` field
  declares four values — `entry-point`, `public-surface`, `depended-upon`, `named-unit` — but
  independently verified across its 1,521 lines: **`public-surface` and `named-unit` each occur exactly
  once**, only in the field's own value-space cell (line 350). **No rule assigns either.** By contrast
  `depended-upon` occurs 14 times with real assigning rules and `entry-point` twice.
- **Why it matters beyond tidiness.** feature-006's severity function is a **total function of that
  field** — `entry-point`/`public-surface` → `[HIGH]`, `depended-upon` → `[MEDIUM]`, `named-unit` →
  `[LOW]` — and FR-26's ledger severity derives from it. So half the severity domain is unreachable, and
  a reviewer reading feature-006 would expect `[HIGH]` and `[LOW]` rows that the enumerator cannot
  produce. The two specs are individually coherent and jointly wrong, which is the same shape as the
  disposition-versus-byte-identity collision and the coverage-row accumulation.
- **Two further reopen candidates from the same review, not yet actioned:** the **F6 false gap** — a
  project extension cannot widen coverage, so a project-defined coverage-bearing relation yields a false
  gap (owner + feature-003); and **zero-row media nodes** needing a carrier that must not be `kb_gaps`
  (owner + feature-003 + feature-004).
- **Two defects feature-006 found in its own previously-gated text**, both fixed in this pass: a severity
  tie-break stated as "highest applicable severity" that is **unimplementable** because feature-004
  assigns exactly one qualifier per node, so there is nothing to break a tie between; and an `Evidence`
  recheck command that contradicted its own row.
- **A correct withdrawal worth recording.** The previous revision had written a retention carve-out into
  the **shared** ledger schema — precisely the local workaround Q8 lifted out of this work. feature-006
  withdrew it and instead names the consequence plainly: until D-6 lands the ledger does not survive
  DONE, so **`Fixed` and `Recurred` are unreachable and every run is cycle 1**. Durable carrier is
  `kb_gaps` in `relationships.md` frontmatter, which feature-003 already reserves outside the
  byte-identity boundary.

### Q23

- **Category:** Process
- **Impact:** High
- **Status:** Recorded 2026-07-29 — **a recurring orchestrator failure mode: truncating or counting
  evidence, then reasoning as if the sample were the whole.** Three instances today, each caught by a
  reviewer rather than by the author:
  1. **The fact count.** Counted occurrences of the bare token `CONFIRMED` (227) and treated them as
     anchored markers (33). Produced A-5's "verified" 616 and a performance target built on it.
  2. **The figure sweep.** Grepped for a remembered phrasing, saw "616" still appearing four times, and
     classified those occurrences **by count** without reading them. Two were live assertions.
  3. **A false finding injected into a review.** Told the feature-004 re-gate that the SPEC's citation of
     `check-version-sync.sh:151` was imprecise because "the actual references are at 6, 106 and 149".
     Both halves were wrong: the search ran against the **`.claude/` render** rather than the
     `canonical/` path the SPEC cites, and `Select-String` output was truncated to the **first three of
     nine** matches. Line 151 is exactly `NPM_JSON="${REPO_ROOT}/packages/npm/package.json"` — the
     citation was correct. The reviewer verified and **declined to record the row**.
- **Standing practice, now three times earned:**
  - To verify a figure or reference, **read every occurrence**; a count is not evidence about the nature
    of what was counted, and a truncated list is not evidence about the rest.
  - Never pass `-First N` on a search whose completeness the conclusion depends on.
  - Search the **path the artifact cites**, not the nearest equivalent — `canonical/` and its five
    profile renders are different artifacts, and one of them is excluded from enumeration by design.
  - When handing a suspicion to a reviewer, mark it as **unverified suspicion**, not as a finding —
    instance 3 cost review effort and could have introduced a spurious ledger row.
- **The counterweight worth recording too:** the same pressure produced a genuine defect. Asking whether
  feature-004's evaluation order was **severity-monotone**, rather than accepting first-match as a
  design, surfaced that it was **not** — `packages/npm/package.json` satisfies `named-unit` (P3/LOW) via
  `integration-map.md:11`'s `sources:` and `depended-upon` (P2/MEDIUM) via `check-version-sync.sh:151`,
  so locality-ordered first-match would have silently downgraded a ledger finding. Verified on disk.
  Scepticism aimed at a **design claim** paid; scepticism aimed at a **citation** without reading it
  cost.

### Q24

- **Category:** Process
- **Impact:** High
- **Status:** **Session handoff 2026-07-29** — resume in Claude Code from this queue, in order.
- **Worktree:** `C:\Projects\Personal\AID\.claude\worktrees\work-005-knowledge-graph`
- **Branch:** current worktree branch (aid/work-005-*)
- **Constraints:** PowerShell only — **do not use WSL/bash**. Standing rules: Q18 (defect ⇒ A+ false),
  Q17 (proxy-keyed clauses), Q23 (read every occurrence; never truncate search output).
- **Resume queue:**
  1. **A+ gate feature-004** — re-gate round 3 fixes landed (rows 14–19 closed by subagent ab70f87d before usage limit; orchestrator fixed D5 nested-backtick typo). Confirm grade.
  2. **A+ gate feature-006** — re-spec done; gate the 1,162-line SPEC.
  3. **A+ gate feature-007** — re-spec done; gate the 1,707-line SPEC.
  4. **Reopen + fix feature-003 loader** — four inbound items from feature-001 (Q20): eighth key
     `derived_from`, `<kind>-><kind> `endpoint_kinds`, V12 re-key; then re-gate.
  5. ~~**FREEZE the 001–007 spine**~~ — **DONE 2026-07-30.** All seven gated A+; spine frozen per Q26 § Freeze.
  6. **Wave 3b — AUTHOR FRESH** feature-008 (canvas) + feature-009 (table view); consume 007.
  7. **Wave 3c — AUTHOR FRESH** feature-010 (runtime), feature-011 (validators), feature-012 (packaging).
     feature-010 additionally carries the Q25-1 retention correction.
  8. **Wave 3d — AUTHOR FRESH** feature-013 (tests + docs).
  9. **Editorial sweep** — the single batched pass over every non-mechanism routed item accumulated
     across items 1–8, then ONE confirmatory gate over only the touched SPECs (Q26 § Mechanism vs
     editorial). Not a per-item reopen cycle.
  10. **REGENERATE PLAN.md** from the frozen SPEC set — not patched (D-2a: delivery-002 depends on
      004+005; delivery-001 research invalidated).
  11. **REGENERATE the task graph** from the regenerated PLAN — not patched. The existing 96 tasks are
      **discarded**, not edited; expect a different count and shape.
  12. **Replacement research** — WebGL-headless probe **first**, then live-renderer bench + vocabulary
      ship (delivery-001 redo).

  **Items 6–8 say AUTHOR FRESH, and the wording is binding (Q26 § Fresh authoring).** Features 008–013
  still carry their **pre-decision** SPECs. Do **not** edit those documents into shape: open the old
  SPEC as a *checklist of concerns only*, never as a base document, and write the new one against the
  amended REQUIREMENTS and the frozen 001–007 contracts. Editing a document keyed on the superseded
  node model is the mechanical cause of the proxy-defect class (Q17/Q21 — six instances, three of them
  the same `int:`-for-`source-artifact` substitution) and of stale change-log rows becoming findings in
  their own right (feature-006 gate rows 13, 14). Authored fresh, that entire defect class has **zero**
  instances by construction. Same reasoning promotes items 10–11 from "re-" to **regenerate**.

  **Order changed 2026-07-30:** the feature-003 loader reopen was item 4 and is now **item 3, ahead of
  feature-007's gate**. Reason: feature-003 has a **known-open** defect (Q20) and is upstream of
  everything, while feature-007 holds **no grade yet** — so gating 007 first would spend a gate that
  003's fix could invalidate. Standing rule: **never gate a SPEC that sits downstream of a known-open
  upstream defect.** feature-006 is the one unavoidable exception — its fix loop was already in flight
  when this was settled — so item 3 ends with a *targeted impact sweep* of 006 against the corrected
  loader contract, not a re-gate.
- **Stale artifacts (do not execute against):** delivery-001 FINDINGS/decision record (static SVG);
  PLAN.md task graph; pre-2026-07-29 feature specs for 008–013.
- **Key files:** `REQUIREMENTS.md` (A+), `STATE.md` Q9–Q23, `features/feature-*/SPEC.md`.
- **Queue progress (2026-07-30, latest):** items **1–5 CLOSED** — feature-004 **A+** (confirmed),
  feature-006 **A+** (5 cycles, D→D+→B+→B+→A+), feature-003 **A+** with Q20 (loader sync) **closed**,
  feature-007 **A+** then reopened and settled at **B**, spine **frozen**. Item **6 CLOSED** — 008 **B-**,
  009 **B**. Item **7 CLOSED except 012** — 010 **B**, 011 **B-**, 012 gated **D+** on a new `[HIGH]` and
  now at **cycle-5 fix** (rows 7 + 8 only; rows 9–11 are editorial and deferred). Item **8 IN FLIGHT** —
  feature-013 **authored fresh** (293 → 759 lines) and its **first gate is running**. Items 9–12 unchanged
  and unstarted.

  **All thirteen SPECs are now authored against the post-decision model.** What remains is convergence on
  two features, then the batched editorial pass and the two regenerations.

  **Every grade from item 6 onward is a B-floor clearance under Q27, not an A+.** The deferred LOW/MINOR
  rows live in their per-feature ledgers under `.aid/.temp/review-pending/` and are item 9's input
  alongside E1–E9; **the ledgers are the authority for that list, not this queue.** Item 9 must run the
  *class* sweeps, not merely edit the cited sites (Q27).

  **A verification's scope is itself a claim.** Recorded after orchestrator errors 5 and 6: state what a
  check covers, what it cannot see, and **which property it tests**. Error 5 tested whether citations
  *resolve* and never whether the *arguments resting on them still hold*; error 6 keyed on the literal
  `<doc>:<line>` form, so ranges and section references were invisible, and swept 12 files when the merge
  had changed **504**. Both were caught by the agents the sweep briefed, not by the sweep.

### Q25

- **Category:** Design / Process
- **Impact:** High
- **Status:** **Resolved 2026-07-30 by owner decision**, on four questions raised by feature-006's first
  A+ gate (grade **D**; ledger `.aid/.temp/review-pending/feature-006-spec.md`).
- **1. The gap ledger dies at skill DONE — feature-006's D7 stands; feature-010 carries the defect.**
  feature-010 retains `graph-kb-gaps.md` past DONE (its SPEC.md:138, :497–498) on the stated authority of
  "feature-006 §D7". That authority is a citation to feature-006's **previous** revision, which did carry a
  retention carve-out in the shared ledger schema and which this revision **withdrew** (Q22). The citation
  is therefore **expired, not wrong when made** — the same Q20 failure class as the feature-003 loader
  contradiction, and the second instance in this work of a cross-reference outliving the text it cited.
  **Why the alternatives were rejected, both against Q8:** having feature-010's retention win contradicts
  Q8's **substance** — a skill exempting one file from the shared lifecycle is precisely the local
  workaround Q8 lifted out, and is *worse* than the withdrawn carve-out, since a schema amendment is
  visible to everyone reading the schema while a skill-local skipped delete is invisible from it.
  *(Correction 2026-07-30: this entry originally said feature-006 was drafted "ninety minutes" before
  feature-004's fixes landed. 21:30 → 23:29 is **119 minutes**. The figure was wrong and — being a
  measured quantity — should never have been asserted in a feature SPEC at all; feature-006's re-gate
  charged it as a finding against its own Figures claim, correctly. The orchestrator wrote it here and
  propagated it into that SPEC's change log.)* Blocking
  both features on D-6 contradicts Q8's **purpose** — Q8 lifted D-6 out so this work would not wait on it.
  Decisive third ground: feature-006's Open Item **2** — numbered **3** when this entry was first written,
  renumbered the same day by the fix pass that closed the old item 2; the hazard its own numbering note
  warns about, caught here by checking every inbound citation rather than trusting the note — had
  **already considered and declined** the partial
  restoration, predicting that "a partial substitute presented as a fix is how D-6 would quietly stop being
  scheduled" — and feature-010's retention is that substitute, so the prediction had already come true
  once. **Consequence:** D7, AC-G6 and Open Items 1 and 3 are correct and unchanged; the defect was a
  **missing route**, and feature-006 gains an Open Item recording the feature-010 correction. **Owner:
  feature-010 — ungated; no reopen consequence.** Scheduled with its Wave 3c re-spec (Q24 item 6).
  The interim shortfall is unchanged and stated rather than hidden: findings reach a reviewer only via the
  durable `kb_gaps` frontmatter carrier plus the printed reproduce command, and `Fixed`/`Recurred` remain
  unreachable, so every run is cycle 1 until D-6 lands.
- **2. `RELATION_CATEGORY` moves into `coverage-predicate.mjs`; `graph-model.js` re-exports it.** feature-006
  L2 claimed the predicate module "already exports" `keys(RELATION_CATEGORY)`; feature-007 in fact places
  the constant in `graph-model.js` (:291, :1334, :1434), which feature-006's own D6 (:514) forbids the Node
  side importing — so the F6 false-gap counter (step 4, AC-G5, GL17, GL12) had **no reachable data source**,
  and the claim contradicted this SPEC's own :993/:1039. Resolved by the precedent this work already set for
  the identical problem: the coverage predicate itself was unified into one shared ESM module executed in
  both runtimes (Lifecycle History 2026-07-28). The constant is frozen and build-time, the predicate module
  is already imported by both runtimes, and `graph-model.js` is browser-only — so the move strictly reduces
  duplication and makes **GV05** (`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`) checkable inside one file.
  **Owner: feature-007 — ungated; no reopen consequence.** Recorded as a MOVE between two of its files, with
  the GV01/GV05 consequence named, not as an export-surface confirmation.
- **3. A `[HIGH]` ledger row for an undocumented test suite is intended.** feature-004's Open Item 14(ii)
  (:2358–2363) explicitly handed this phrasing call to feature-006. The derived severity **stays**: severity
  is a total function of feature-004's `qualifier`, D4 already voided a tie-break for being unimplementable,
  and a carve-out for test files would break that totality and manufacture exactly the under-reporting
  incentive the Description exists to prevent. The `kb_gaps` worked example was wrong, not the rule — a
  shebang-carrying `tests/canonical/test-*.sh` is `entry-point` under D3a (:1321–1328) and therefore
  `[HIGH]`, and the block applied one gated rule two ways in two adjacent entries.
- **4. F2's ancestor-matching condition is kept; its necessity argument is deleted.** The gate showed the
  argument false under **both** readings of the `sources:` carrier: feature-004's Feature Flow step 6
  (:1965–1974) collapses only `canonical/skills/<name>/**` and `canonical/agents/<name>/**` and suppresses
  their member files, so no enumerated `source-artifact` node has an ancestor that is also a node, and the
  condition is **currently unreachable**. It stays because removing it would make the predicate wrong for
  directory nodes generally; what changes is that the SPEC now says it is unreachable today and exists to
  keep the predicate total if those collapse rules ever emit an ancestor and a descendant together.
- **A gate-design lesson, and the first of its kind here.** **Both** HIGH findings were *ordering artifacts
  of the wave, not authoring errors.* feature-006 was written at 21:30 and feature-004's re-gate fixes landed
  at 23:29 — so feature-006 faithfully described a feature-004 that ceased to exist ninety minutes later, and
  one of its two HIGHs was an Open Item demanding a reopen of work that had **already been delivered**. Q20's
  standing correction says to check the inbound queue before a re-gate; this adds the converse — **when an
  upstream SPEC is re-gated, every downstream SPEC already drafted against its previous revision must be
  re-swept before its own gate**, because a faithful citation silently becomes a false one. Cheap mitigation
  for the remaining waves: gate in dependency order, and never draft two dependent SPECs against a sibling
  whose own gate is still open.

### Q26 — the completion discipline (how this redesign terminates)

- **Category:** Process
- **Impact:** Critical
- **Status:** **Adopted 2026-07-30 by owner decision** — "avoid going in circles forever; let's finish this
  redesign." Binding on every remaining Q24 item. Q26 does not relax any correctness standard; it bounds
  **when** a correction is scheduled, and replaces editing with authoring where editing is the defect source.

- **Fresh authoring (Q24 items 6–8).** Features 008–013 are **authored fresh** against the amended
  REQUIREMENTS and the frozen 001–007 contracts. The pre-decision SPEC is a checklist of concerns, never a
  base document. Rationale, and it is mechanical rather than aesthetic: the proxy-defect class exists only
  because clauses keyed on the superseded model stayed **grammatical while becoming false** — `int:` meant
  `source-artifact` and now spans `source-artifact` and in-repo `image`, so six clauses broke **without being
  edited** (Q17, Q21; three were the same substitution). A document authored against the new model cannot
  carry that defect, cannot carry a change-log row asserting a withdrawn claim, and cannot carry a
  discharge list that has drifted out of sync — three of feature-006's fourteen gate findings were exactly
  those residues. Same argument promotes **PLAN.md and the task graph to regeneration** (items 10–11): a
  96-task graph whose model moved is the highest-risk edit left in this work, and patching it preserves
  every assumption the model change invalidated.

- **Mechanism vs editorial — the anti-circling lever.** Q18 ruling 3 (a defect makes an awarded A+ false)
  and Q20 (an inbound item on a gated SPEC is a pending reopen) are both correct and are **retained**. But
  applied to *every* routed item they form an unbounded cascade: five awarded A+ grades have already been
  reopened, and a large share of the routed queue is explicitly self-described as **"wording only"**,
  **"no mechanism change in either"**, **"optional wording"**, or **"wording and item closure only"**.
  From now on:
  - A **mechanism** item — one that changes a contract, a field, an id grammar, a predicate, an interface, an
    exit code, an emitted value, or an acceptance criterion's truth — **reopens its SPEC and forces a
    re-gate**, exactly as Q18/Q20 require. Unchanged.
  - An **editorial** item — a stale quotation, a cross-reference, a superseded change-log row, a missing
    discharge-list entry, a prose annotation, a renumbering — is a **real defect that still gets fixed**, but
    it is **collected, not chased**: it goes onto the editorial queue and is fixed in the single batched pass
    at Q24 item 9, followed by **one** confirmatory gate over only the SPECs that pass touched.
  - The classification is recorded **when the item is routed**, by the routing SPEC, in the item's own text.
    An item that cannot be classified confidently is treated as **mechanism** — the conservative default.
  This is the difference between N reopen cycles and one. It denies no defect; it stops each one from
  restarting the sequence.

- **Freeze (Q24 item 5).** When features 001–007 are all A+ and the editorial queue is recorded, the spine is
  **frozen**. After the freeze, a change to any of the seven requires an **explicit owner decision** — not an
  automatic reopen. A downstream feature that finds a genuine mechanism defect in a frozen SPEC still
  reports it (that reporting is what has been working), but the owner decides whether it is fixed now,
  deferred to the editorial pass, or carried as tech-debt against the shipped design. Without this, every
  one of the six remaining features can reopen any of the first seven, and the sequence has no fixed point.

- **Definition of done for the redesign** — the redesign is complete, and `/aid-execute` may begin, when all
  five hold: (1) all thirteen SPECs gated **A+**; (2) the editorial queue is **empty**; (3) PLAN.md
  **regenerated** from the frozen SPEC set and gated; (4) the task graph **regenerated** and gated, with the
  old 96 tasks discarded; (5) delivery-001's replacement research complete, so no SPEC rests on a withdrawn
  figure. Anything discovered after that point is tech-debt or a new work item — **not** a reopen of this
  redesign.

- **Dependency-ordered gating (standing).** Never gate a SPEC downstream of a known-open upstream defect,
  and never draft two mutually dependent SPECs against a sibling whose own gate is still open. Wave 3a
  violated the second half — 006 and 007 were drafted simultaneously while 004 was mid-re-gate — and it
  cost both of feature-006's HIGH findings, which were staleness artifacts rather than authoring errors
  (Q25 § gate-design lesson). This is the converse of Q20: check the inbound queue before a re-gate, **and**
  re-sweep every downstream draft when an upstream is re-gated.

### Q27 — minimum grade lowered to B-; LOW and MINOR deferred

- **Category:** Process
- **Impact:** High
- **Status:** **Adopted 2026-07-30 by owner decision** — "change the minimum grade … let's take care of the
  LOW and MINOR issues only at the end", corrected by the owner from an initial C+ to **B-**. Applies to
  every remaining gate in this work.
- **What B- means here, and why it is the exact expression of the instruction.** The rubric grades by
  *worst* issue (`grading-rubric.md:39–54`), and the LOW-worst band is B+ / B / **B-**, with B- its floor
  (">5 lows"). So a B- minimum is **zero CRITICAL, zero HIGH, zero MEDIUM — and any number of LOWs and
  MINORs**. That is cleaner than the C+ first proposed, which would have tolerated one MEDIUM: the bar now
  says *fix every mechanism-grade defect, defer the entire cosmetic tail*, with no ambiguous middle.
- **Where deferred findings live: nowhere new.** LOW and MINOR rows stay `Pending` **in their own feature
  ledgers**, which already hold them with severity, evidence and a named oracle. The **Q24 item-9 pass**
  now sweeps those rows alongside the § Editorial queue below. No second register is created — a parallel
  list would be bookkeeping that drifts from the ledgers it copies.
- **Scope of the change.** Set on this work only: `STATE.md` frontmatter `minimum_grade: B-`.
  *(Corrected 2026-07-30: this bullet read `C+` — the value from the owner's first instruction — after the
  owner corrected the decision to `B-` and the frontmatter was updated. Found by feature-010's gate, which
  read the frontmatter against the prose rather than trusting either. The same class as the errors logged
  above: a value restated in two places and updated in one.)*
  **`.aid/settings.yml` is deliberately left at `A+`** — it is the repo-wide default for every skill and
  every future work, and the owner's instruction was about this work's remaining gates, not about AID's
  standard.
- **What it does NOT do.** It does not lower any grade already awarded: features 001–007 are gated **A+**
  and 008/009 are being driven to the same standard for MEDIUM-and-above. It does not reclassify anything —
  a MEDIUM stays a MEDIUM. And it does not touch **Q26's mechanism/editorial split**, which governs
  *scheduling* independently: a MEDIUM classified editorial still batches, and a LOW classified mechanism
  still defers under this rule. The two rules compose; neither overrides the other.
- **Why this is a reasonable trade, stated so the cost is visible.** The LOW/MINOR tail is where the last
  three cycles of features 006 and 007 went, for findings that changed no mechanism. But the tail is not
  free to defer: cycle 3 of feature-008 showed a `[LOW]` (row 21, a struck figure surviving 40 lines away)
  that was the *class* of a defect, not an instance — so the item-9 sweep must still run the class sweeps,
  not just edit the cited sites.

### Q28 — live repo defects found by this work (register; NOT this work's to fix)

- **Category:** Process / quality
- **Impact:** High
- **Status:** **Open — needs a permanent home before this work folder is pruned.**

Specifying work-005 required reading large parts of the live repository closely, and that reading turned up
**six defects in shipped code that have nothing to do with this work**. They are recorded here because
they were found here — but **this is the wrong place for them.** CLAUDE.md's own rule is that work folders
are transient and no permanent artifact may depend on one. **Owner: the work owner** — each needs either a
`tech-debt.md` entry or a fix, before `.aid/works/work-005-knowledge-graph/` is pruned. **All five were
re-verified on disk on 2026-07-31, after the 504-file master merge**, because four of them were found
before it and a merge can fix a defect as easily as it can move a line.

| # | Defect | Verified how |
|---|---|---|
| **D1** | **The dark theme is never contrast-checked.** `canonical/aid/scripts/summarize/contrast-check.mjs:21–22` builds its block regex with flags `'m'` only and calls `html.match(re)` — **no `g` flag** — so the dark lookup resolves the *first* matching block, `component-css.css:4`'s `color-scheme` block, instead of the real dark block at `:37`. `:40`'s `const dark = { ...light, ...darkVars }` then re-checks the light values. The dark theme has never been measured | **Executed twice** against shipped `kb.html`: dark ratios identical to light **pair-for-pair** (16.83 / 7.15 / 4.97 / …), exit 0. Re-read post-merge: flags still `'m'` |
| **D2** | **A CI lane never runs.** `.github/workflows/test.yml:105` sets `SUMMARY=".aid/dashboard/kb.html"`, a path that does not exist post-relocation, so `:106`'s guard SKIPs and `exit 0`s **every run**. The visual-fidelity gate is green because it never fires | Read `:100–110` post-merge; `ls .aid/dashboard/kb.html` → no such file. feature-011 carries it as an Open Item |
| **D3** | **`validate-html-output.sh`'s `--kb-dir` is write-only, and the run displays it.** `--help:9` and the L2 description at `:28` both say relative `.md` links resolve against `--kb-dir`. The flag **is** parsed (`:42–43`) and defaulted (`:35`), and `:384` **prints `kb-dir=$KB_DIR` in the L2 banner** — but the actual resolution at `:391` is `target="$HTML_DIR/$mdlink"`, where `HTML_DIR=$(dirname "$HTML")` (`:62`). `KB_DIR` is never read after being echoed | `grep -n "KB_DIR\|kb-dir\|HTML_DIR"` returns every occurrence — 7 sites, complete, no truncation (Q23). **Sharper than first recorded:** the original note said the docs describe unimplemented behaviour; in fact the banner actively reports a directory that is not the one checked |
| **D4** | **`relation-vocabulary.yml` is BOTH unrendered AND stale in content — the orchestrator's own, and worse than first recorded.** `canonical/aid/templates/graph/relation-vocabulary.yml` was committed in `3fc7cdb4` but the profile generator was never run, so it is absent from **every** profile tree, the manifest and the dogfood tree. **Escalated 2026-07-31 during construction:** the file also **predates feature-001's re-specification** — it carries **15** relation entries across **5** categories, where the gated SPEC § D5/D6 specifies **14 categories** and ~**31 pairs / 57 directed entries**. It has **no `cites-as-evidence` and no `derived-from`**, both members of `COVERAGE_BEARING`, so it **cannot satisfy GV05** (which requires `COVERAGE_BEARING ⊆ keys(vocabulary)`) against any correct build | Render drift: `find profiles .claude -name relation-vocabulary.yml` → **zero** hits against one in `canonical/`. Content staleness: found **independently by the `coverage-predicate.mjs` builder**, which parsed feature-001 D6's tables out of the SPEC and cross-checked its module token-by-token (31 pairs / 57 entries / 14 categories; zero missing, zero extra, zero category disagreements) — **it authored against the SPEC rather than the file, which was the correct call.** Orchestrator-confirmed three ways: 15 entries on disk, 14 category headers in the SPEC, and the two missing coverage-bearing relations. **This became urgent because the orchestrator's own build brief named the stale file as "the authority" the other carriers must agree with** — the eighth instance of asserting a file's contents without opening it. Corrected mid-flight |
| **D5** | **The skill-count gate is blind to both operands of a decomposition while checking its total.** `tests/canonical/check-skill-counts.mjs:97`'s lookahead class `[-—,.)]` contains the **closing** paren, not the opening one, so `17 curated (…` matches neither `:97` nor `:96`; and **no pattern matches the bare phrase `N catalog rows`** (`:108–:111` cover only `N-row catalog`, `N catalog skills`, `N shortcut-catalog skills`, `(N rows total`). So `= 17 curated (NOT catalog rows…) + 94 catalog rows` is entirely unchecked while `111 skill directories` on the line above is checked — a decomposition can stop summing and the gate still reports agreement. Compounding it, the script's own header lists `site/scripts/, tests/, dashboard/, lib/, bin/, packages/` as **NOT YET SCANNED** | **Two independent routes.** feature-012's cycle-4 gate mutation-proved it — injecting `99 curated` / `77 catalog rows` still printed "All 204 stated skill counts agree", exit 0 — and **separately** simulated the `aid-graph` landing, where the gate reports `generate-profile/SKILL.md:106` but not `:107`, leaving `112 = 17 + 94`. The orchestrator then confirmed it **by reading the regexes rather than re-running the mutation**, and found it *broader* than reported: the ledger named only the `curated` gap, not the `catalog rows` one. **A third blind shape was then found by feature-012's cycle-5 fix, which rebuilt the `CLAIMS` array by parsing the script and replayed it over the exact corpus rather than working from a handed list: bare arithmetic with no noun at all.** Orchestrator-confirmed on disk — `.aid/knowledge/architecture.md:194` reads `` `repurpose` skills; 17 + 94 = 111): ``, invisible to every pattern while a total two lines away is checked. That replay also **added five surfaces** the earlier list omitted and correctly **excluded true negatives** (`8 curated domains` ×2, `feature-014 curated them`), which a path list would have sent an implementer to edit |

| **D6** | **The diagram maintenance contract describes a diagram that does not exist.** `docs/diagram-content-reference.md:126–129` requires §1 The Pipeline to show phase groups `G1 Prepare · G2 Describe → Define · G3 Map · G4 Execute · G5 Deliver`. The diagram declares `GE` (Entry), `GS` (Support), `G1` (**Knowledge Base Maintenance**), `G2` (Definition), `G4` (Execution) — **no `G3`, no `G5`, and `G1` names a different group entirely.** This is the document that tells a maintainer which group to add a new skill to, so it actively misdirects | Found by feature-013's author; **confirmed first-hand, including the check that could have made it a false positive**: `docs/aid-methodology.md` holds **six** mermaid blocks, so the risk was comparing the wrong one. `## 1. The Pipeline` is at `:24`, its block opens at `:26`, and the next section is at `:151` — the subgraphs at `:37–:59` are inside the governed block. Almost certainly PR #174 (`work-001-skill-diagrams`) reworking the diagram without fully updating its contract. **Directly in feature-013's path**: its class-1 edit adds `aid-graph` to `G1` |

**Why this register exists at all.** Each of these was found by *reading source to verify a citation* — never by a
test, and never by the gate that owns the area. D1 and D5 are the same shape one level up: **a check that
passes because it is not looking**, which is exactly the vacuity class this work learned to audit for in its
own SPECs. That the audit kept paying out against shipped code is the strongest available argument that the
discipline is worth its cost.

### Editorial queue (Q26)

Cross-feature **editorial** items — real defects, deliberately **collected rather than chased**, fixed in
the single batched pass at **Q24 item 9** followed by one confirmatory gate over only the SPECs that pass
touches. A **mechanism** item never lands here; it reopens its SPEC immediately (Q26 § Mechanism vs
editorial). Each row names the artifact, the defect, and how it was found.

**Item 9's full input is this table PLUS every `Pending` row in the per-feature ledgers, and the ledgers
are the authority for those — not this table, which holds only the cross-feature items.** Scope index,
enumerated 2026-07-30 by walking **all 21 ledgers** under `.aid/.temp/review-pending/` rather than the six
expected — the "state your scope" correction applied to itself. Fifteen carry **zero** open rows; the six
that carry any:

| Ledger | Pending | Severities | OOS |
|---|---|---|---|
| `feature-007-reopen.md` | 7 | 4 LOW, 3 MINOR | 2 |
| `feature-008-spec.md` | 7 | 7 LOW | 0 |
| `feature-009-spec.md` | 4 | 2 LOW, 2 MINOR | 0 |
| `feature-010-spec.md` | 5 | 3 LOW, 2 MINOR | 1 |
| `feature-011-spec.md` | 10 | 7 LOW, 3 MINOR | 2 |
| `feature-012-spec.md` | 4 | 2 LOW, 1 MINOR, **1 MEDIUM** | 0 |
| **Total** | **37** | **24 LOW, 12 MINOR, 1 MEDIUM** | **5** |

Five further `OOS` rows sit in the already-closed `feature-003-spec.md` (2), `feature-006-spec.md` (2) and
`feature-007-spec.md` (1) — **10 OOS in total.** Those are **not** item 9's to fix, but each must be
confirmed still routed to a named owner before the work ships.

**The single MEDIUM is feature-012's row 6, and it is in flight rather than deferred** — Q27 defers LOW and
MINOR only. Establishing that every *other* open row across features 007–011 is LOW or MINOR is what makes
the B- floor a verified fact rather than an inference from the grade letters.

| # | Artifact | Defect | Found by | Notes |
|---|---|---|---|---|
| E9 | `features/feature-007-graph-view-shell/SPEC.md` — change-log row 15 | Says `INITIAL_LENS` "gains the `focus.depth`, `zoom` and `sort` values" — **three**, but **four** were missing: `filters.text` is omitted from the list | feature-007 cycle-3 gate (declined as unverifiable) + orchestrator confirmation | Editorial. The reviewer **correctly declined to record it**: `HEAD` holds only the 925-line pre-re-spec file, so neither the 1,707- nor 1,970-line revision was ever committed and **no diff exists** — it refused to build a finding on an unverifiable premise (Q23 instance 3's lesson). Confirmed instead from the fix author's own report, which lists all four. A concrete cost of the deferred commit: with the re-spec uncommitted, a reviewer cannot diff its own subject |
| E7 | `features/feature-007-graph-view-shell/SPEC.md` — Open Item 2 | The item states it "belongs on STATE.md's § Editorial queue"; **no row existed** | feature-007 cycle-2 gate, orchestrator note | Row added on the **E3 precedent** — when a SPEC says an item belongs on this queue, the row is owed or the disposition is a promise nothing keeps. Editorial; batched for the item-9 pass |
| E8 | `features/feature-007-graph-view-shell/SPEC.md` — Open Item 10 | Same: says it belongs on this queue, **no row existed**. Self-describes as "no mechanism… changes", which is what makes it editorial | feature-007 cycle-2 gate, orchestrator note | Same precedent and disposition as E7 |
| E4 | `features/feature-006-kb-gap-ledger/SPEC.md`:~D6a | D6a's row still spells the `kb-unbacked` test with the **`int:` prefix**, now stale after feature-007 re-keyed the test to `kind === 'source-artifact'` | feature-007 cycle-1 fix, judgment call 6 (recorded at feature-007`:956`) | Editorial. feature-006 is **gated A+** — batched, not reopened, on the E1 precedent. Its own proxy-sweep row 13 **pre-declared** this deferral and **GL09 holds under either keying**, so nothing operative is wrong. Fixing it as a numbered item would renumber live inbound citations for no gain |
| E5 | `features/feature-007-graph-view-shell/SPEC.md` — 3 sites | Bare `Q20` citations with no disambiguating suffix (the ledger found two; the fix author's sweep found a **third** at `:295`) | feature-007 gate ledger row 22 (OOS) + fix-author sweep | Editorial, same class as E2. The three sites the author **wrote or touched** (`:13`, `:77`, `:1852`) already carry suffixes; these three predate the convention |
| E6 | `features/feature-007-graph-view-shell/SPEC.md` — § Figures | Classifies "**seven kinds**" as a *contract count* under Q19's exemption, while REQUIREMENTS`:238–240` **struck** "closed at seven" as a count-as-proxy. The two documents label the same numeral opposite ways | feature-007 cycle-1 fix, judgment call 1 — raised for an owner ruling, **no reviewer finding** | Needs a one-line **owner ruling**, not a fix: is the `Kind` enum normatively fixed at seven (count stays) or open to widening (cite the set)? The author correctly declined to re-litigate a labelled classification unasked |
| E3 | `REQUIREMENTS.md` — FR-26 / AC-14 wording | The `int:`-for-kind family's last unannotated member: FR-26's and AC-14's "the offending `int:` node" is satisfiable-while-wrong (an in-repo `image` id satisfies the words), needing the one-clause annotation FR-19 received under Q21. **Not a defect** — FR-20 and AC-15 scope the class — so it is a prose annotation, not a mechanism change | feature-006 Open Item 8; disposition added in its cycle-3 fix | Target is **gated A+ and already reopened four times**, so this is a **pending reopen whose scheduling Q26 batches rather than avoids**: the item-9 pass edits REQUIREMENTS.md and carries one confirmatory gate, making that a **fifth** re-gate of the document every other artifact is graded against. Row added by the orchestrator because the SPEC says the item "belongs on" this queue — without it the disposition would be a promise nothing keeps (flagged by the fix author) |
| E2 | `features/feature-003-relationship-table-schema/SPEC.md`:18 | The cycle-2 change-log row cites **"Q20" twice with no disambiguating suffix**, which the 2026-07-30 convention requires of every citation authored from that date onward, since two Q&A entries carry that number | feature-003 cycle-3 gate, ledger row 14 (OOS) | `[MINOR]`, editorial, routed on the E1 precedent so it is **not charged** to feature-003's A+. Fix: `Q20 (loader sync)` at both sites. Notable as a **convention outrunning its own adoption** — the entry was authored in the same hours the suffix rule was written, and feature-006's author retrofitted seven of its own sites unprompted while feature-003's predates the rule |
| E1 | `features/feature-004-source-enumeration/SPEC.md`:2326 | Cites "feature-006's Open Item **2**" for the `qualifier`-mapping discharge; after feature-006's 2026-07-30 renumber that number resolves to the unrelated *declined-restoration* item, so a reader checking the discharge finds the wrong subject | feature-006 re-gate, ledger row 22 (OOS) | **The fourth inbound citation — the one the orchestrator's cross-check missed.** It appeared in the grep output and was mis-analysed as harmless because the *old* item 2 was closed; what was overlooked is that the citation now points at the *new* item 2. Low harm (no build impact, resolves by subject), so Q26 says batch — and batching it rather than chasing it is the rule being followed on its first real test. Fix: cite by **subject**, not number. feature-004 is gated A+; as editorial this does **not** reopen it |

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
