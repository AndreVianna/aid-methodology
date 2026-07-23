---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-22"
minimum_grade: "A+"
user_approved: yes
lifecycle: Paused-Awaiting-Input
phase: Execute
active_skill: none
updated: '2026-07-23T07:16:52Z'
pause_reason: 'Execute complete -- all 3 deliveries A+; awaiting owner on commit/PR + pre-ship merge of origin/master then re-render/re-verify'
block_reason: --
block_artifact: --
ticket_ref: "--"
---

# Work State -- work-023-ticket-integration

> **State:** Execute COMPLETE — all 3 deliveries Done at A+ (drive-all, per-delivery A+ gate). Code-complete on branch work-023-ticket-integration; Paused-Awaiting-Input for owner ship decision (commit/PR + pre-ship merge of origin/master).
> **Phase:** Execute

Add three explicit ticket-tracker skills -- `/aid-read-ticket`, `/aid-create-ticket`,
`/aid-update-ticket` -- as the single, tool-agnostic, user-invoked surface for interacting
with whatever tracker the project has integrated (via the connector layer), and retire every
automated ("PM-Tool") ticket write embedded in other skills so no skill silently touches a
tracker. Internal `ticket_ref` traceability is kept; any outward interaction not started via
the three skills must be validated with the user.

---

## Pipeline State

> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Objective / Context

**Origin.** Owner requested a new AID skill (set) for ticket-tracker integration. Design was
gathered and locked interactively in the originating session (this is the FULL pipeline on the
**seeded** path -- requirements captured directly from that conversation, no redundant re-interview).

**Locked design decisions (owner-confirmed).**
- Naming: verb-first `aid-<verb>-ticket` -- `aid-read-ticket` / `aid-create-ticket` / `aid-update-ticket`
  (consistent with the existing one-pass `aid-create-document` / `aid-update-document` family).
- Grammar: `read [<connector>:]<ticket-id>` · `create [<connector>] <description>` ·
  `update <part> [<connector>:]<ticket-id> <content>`, `part ∈ {description, comment, status}`.
- Connector-resolution ladder: explicit `<connector>` → single `issue-tracker` connector (silent) →
  2+ (ask) → host-tool MCP → notify missing.
- Scope: **MCP-first**; `api`-type connectors (Jira's default preset) are not live-consumable here
  and fall through the ladder -- aid-managed `api`/`ssh`/`cli` consumption stays the deferred follow-up.
- Writes preview + confirm; reads non-destructive.
- **Retire the PM-TOOL generation completely** (owner ruling) -- it is the source of the silent
  writes and duplicates the connectors model (3 skills carry both; `aid-execute` double-pushes status).

**Audit (2026-07-22).** ~40 integration sites classified WRITE/READ/LOCAL-LINK × PM-TOOL/CONNECTORS
(the authoritative site list for the retract/reroute work; see REQUIREMENTS §5 FR-7..FR-10).

---

## Interview State

**State:** Approved  **Grade:** A+ (cross-reference cleared, 2 cycles)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-07-22 |
| 2 | Problem Statement | Complete | 2026-07-22 |
| 3 | Users & Stakeholders | Complete | 2026-07-22 |
| 4 | Scope | Complete | 2026-07-22 |
| 5 | Functional Requirements | Complete | 2026-07-22 |
| 6 | Non-Functional Requirements | Complete | 2026-07-22 |
| 7 | Constraints | Complete | 2026-07-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-22 |
| 9 | Acceptance Criteria | Complete | 2026-07-22 |
| 10 | Priority | Complete | 2026-07-22 |

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-22 | Work created | -- | Seeded (full pipeline, seeded path). Worktree + branch `work-023-ticket-integration` off master `60a3c70f` |
| 2026-07-22 | Requirements captured + owner-approved (Describe, seeded) | -- | 3 ticket skills + full PM-TOOL retirement. Design locked interactively (naming, grammar, connector ladder, MCP-first scope, PM-TOOL retire). REQUIREMENTS.md authored; Interview State → Approved. Ready for /aid-define |
| 2026-07-22 | Feature Decomposition (Describe → Define) | -- | 5 features created (001 skills → {002,003,004} → 005 propagation); every FR-1..13 + AC-1..13 mapped |
| 2026-07-22 | CROSS-REFERENCE gate cycle 1 graded | D+ | aid-reviewer (Large, adversarial, disk-verified): 1 HIGH + 2 MED + 1 LOW + 2 Q&A vs A+ floor → FAIL. HIGH = FR-7 over-generalizes "printed suggestion" (aid-deploy Release/Epic-link have no ticket analog); MED = AC-7 grep-list misses aid-execute wording; MED = §7 site list omits document-expectations.md PM entity-mapping residue; LOW = §-heading citation imprecise. Q&A = aid-plan read/write split, create-grammar separator. All resolvable via prior owner rulings. FIX pending |
| 2026-07-22 | CROSS-REFERENCE cycle-1 FIX applied | -- | All 4 findings + 2 Q&A resolved (each traced to a prior owner ruling): REQUIREMENTS.md FR-2/FR-4/FR-7/FR-8/FR-9/FR-13 + §7 + AC-2/AC-7/AC-8/AC-9/AC-13 + Change Log; feature-001/002/003/005 SPECs updated to match. Re-review cycle-2 dispatched (same reviewer) |
| 2026-07-22 | CROSS-REFERENCE cycle-2 re-review graded | A+ | Same reviewer, adversarial: all 4 cycle-1 findings verified Fixed against disk; 0 new findings (Q1 aid-plan split + Q2 create-grammar checked internally coherent; feature-004 confirmed correctly unchanged); grade.sh 0/0/0/0/0 → PASS |
| 2026-07-22 | CROSS-REFERENCE gate CLEARED → DONE (Define complete) | A+ | Definition set gated A+ (2 cycles): REQUIREMENTS.md + 5 feature SPEC scaffolds. Review ledger cleaned. Lifecycle → Paused-Awaiting-Input; ready for /aid-specify (per-feature A+ SPEC gates) |
| 2026-07-22 | Specify started — feature-001 (Define → Specify) | -- | INITIALIZE: KB context loaded (architecture.md — canonical-authoring + render invariants; connectors = catalog); section plan proposed, adapted for a markdown-state-machine skill feature; feature-001 → In Discussion (foundation for 002/003) |
| 2026-07-22 | Specify REVIEW cycle-1 graded — feature-001 | C | aid-reviewer (Large): 4 MED + 2 LOW vs A+ floor → FAIL. AC/FR coverage + all grounding claims verified clean; failures = spec form/completeness: allowed-tools missing AskUserQuestion; non-standard TS-1..8 headings vs mandated Data Model/Feature Flow/Layers; re-deferred FR-2 override; no general MCP-failure policy; unacknowledged no-mcp-preset reality; PAUSE mislabel. All fixable by architect, no owner decision |
| 2026-07-22 | Specify REVIEW cycle-1 FIX applied — feature-001 | -- | Restructured tech spec under mandated core headings + standard conditionals; AskUserQuestion added to allowed-tools; confirm reworded as in-invocation gate (not PAUSE) + state-machine-chaining.md cited; --connector create override decided (FR-2); general MCP-failure policy added; catalog-reality acknowledged. Re-review cycle-2 dispatched (same reviewer) |
| 2026-07-22 | Specify REVIEW cycle-2 graded — feature-001 | A+ | Same reviewer: all 6 cycle-1 findings verified Fixed against disk (content-preservation traced line-by-line; AC-2↔API-Contracts consistent; no orphaned TS-N refs); 0 recurred, 0 new; grade.sh → PASS |
| 2026-07-22 | feature-001 SPEC gate CLEARED → Ready (Specify DONE for 001) | A+ | Tech spec A+ (2 cycles). Ledger cleaned. 4 feature specs remain (002/003/004/005) before /aid-plan |
| 2026-07-22 | Specify — features 002-005 authoring dispatched (parallel) | -- | Owner chose drive-all-to-A+. 4 aid-architect agents authoring tech specs concurrently (002 retraction, 003 reroute, 004 protocol, 005 KB+render), using feature-001's A+ spec as the format template + the 6 review-lessons; a per-feature A+ aid-reviewer gate follows each |
| 2026-07-22 | Specify — 002/003/004/005 tech specs authored; A+ reviews dispatched | -- | All 4 architects returned (sites confirmed on disk; each applied the 6 lessons; f004 flagged nearest-ancestor-consumer + 004↔003 lockstep watch-items). A+ aid-reviewer gates dispatched for 002/003/004; 005 gate to follow. Fix-loop each to A+ |
| 2026-07-22 | feature-004 SPEC review cycle-1 graded | E | 2 CRIT (both objective, no Q&A): (1) internal E4↔E6 contradiction — E4 claims enrich seams resolve nearest-ancestor, E6 correctly says they don't; (2) E4/E7 reference a unit-scoped /aid-read-ticket that feature-001's grammar (`[stem:]id` only) does not define. Codebase-reality + templates-untouched verified clean. FIX dispatched to same architect: keep nearest-ancestor per FR-10/11 as consumer-less inheritance/traceability semantics; drop false enrich-resolver claim; reframe worked example to id-based reads |
| 2026-07-22 | feature-002 + feature-003 SPEC reviews cycle-1 graded | E+ / E+ | f002 [CRIT]: NFR-3/AC-10 violation — the retraction's replacement suggestion was specified unconditional, but a no-tracker project must stay silent (the aid-report/aid-research precedent is "(optional)"); +1 LOW (test-landscape mischaracterization) +1 MINOR. f003 [CRIT]: "ten canonical files" contradicts 11 listed; +2 MED (overclaims Wired-seams table as authoritative; aid-review INTAKE edit misclassified read-vs-write) +1 LOW (quote drift). All objective/no-Q&A; codebase-reality verified clean on both. FIX dispatched to each author (f002: gate suggestion on a catalogued issue-tracker connector = silent when none) |
| 2026-07-22 | feature-005 SPEC review cycle-1 graded | C | 2 MED (citation-attribution, not plan errors): no-context-file rule mis-attributed to authoring-conventions.md Citation Rule (that section = durable-anchor form only) → reground in AC-13; test-aid-cli-parity.sh wrongly claimed to run a Windows native-ps1 lane (runs ubuntu bash-harness + canonical-tests). Plan/render/sequencing verified clean. 1 MINOR OOS → REQUIREMENTS §8 setup.sh wording fixed by orchestrator. FIX dispatched to author |
| 2026-07-22 | feature-003 SPEC review cycle-2 → A+ → Ready | A+ | Same reviewer: all 4 cycle-1 findings Fixed (recount 11 files/13 edits verified; Wired-seams table demoted to one-input; aid-review read/write split consistent across Feature Flow ↔ tables; verbatim quote); 0 new; grade.sh 0/0/0/0/0. feature-003 spec Ready; ledger cleaned. Specify: 2/5 A+ (001, 003) |
| 2026-07-22 | feature-004 + feature-005 SPEC reviews cycle-2 → A+ → Ready | A+ / A+ | Both cycle-1 fixes verified Fixed, 0 new. f004: consumer-less-inheritance framing honestly satisfies FR-11 (dimension-3 re-judged PASS); worked example id-based. f005: citation regrounded in AC-13; CI lanes corrected. Ledgers cleaned. Specify: 4/5 A+ (001,003,004,005); feature-002 in cycle-2 fix (1 LOW parity nit) |
| 2026-07-22 | feature-002 SPEC review cycle-3 → A+ → Ready; **SPECIFY PHASE COMPLETE** | A+ | feature-002 cycle-2 LOW fixed (gate type-agnostic; false f001-parity dropped); 0 new → A+. All 5 feature SPECs now A+ (001/002/003/004/005). All ledgers cleaned. Lifecycle → Paused-Awaiting-Input; ready for /aid-plan |
| 2026-07-22 | Post-Specify CHANGE REQUEST — feature-001 re-opened (--level/--parent) | -- | Owner: add `--level` (epic\|story\|task; **no default → ask at confirm gate**; canonical tier resolved to tracker issue-type at runtime, graceful degradation) + `--parent` (native hierarchy link) to /aid-create-ticket; flag grammar. REQUIREMENTS FR-2 + new FR-2a/FR-2b + AC-2 updated. feature-001 → In Discussion; lifecycle → Running; aid-architect enhancing SPEC → re-gate to A+ → Specify re-completes. 4/5 (002-005) stay A+ |
| 2026-07-22 | feature-001 re-gate cycle-1 graded (--level/--parent) | E+ | 1 CRIT (`level_map` needs a connector-descriptor field → contradicts Data-Model "no schema changes" + §4 out-of-scope) + 2 MED (create leading-token general-rule-vs-carve-out contradiction; gitlab mislabeled `issue-tracker` in Catalog-reality — only jira carries the tag) + 1 MINOR (create now 2 MCP calls, not 1). No regression (prior 6 fixes intact); FR-2/FR-2a/FR-2b/AC-2 else faithfully realized. FIX: REQUIREMENTS FR-2a defers level_map + FR-2 drops create leading-token heuristic (done by orchestrator); SPEC fixes dispatched to architect (defer level_map, drop heuristic, fix gitlab catalog + call-count). No owner escalation |
| 2026-07-22 | feature-001 re-gate cycle-2 graded + FIX | C+ | 4 cycle-1 findings all Fixed; 1 residual MED (#5: create AC checkbox still read "leading arg" — a missed spot of the heuristic removal) + 1 OOS (#6: REQUIREMENTS FR-4/AC-5 not synced to FR-2). Fixed SPEC checkbox + REQUIREMENTS FR-4/AC-5 (orchestrator). No regression. Re-gate cycle-3 dispatched |
| 2026-07-22 | feature-001 re-gate cycle-3 → A+ → Ready; SPECIFY COMPLETE (again) | A+ | Residual MED (#5 create AC checkbox) Fixed; all re-gate findings verified against disk; grade.sh A+. REQUIREMENTS FR-4 opening parenthetical also synced (completed the #6 OOS follow-up). All 5 feature SPECs A+ incl. `--level`/`--parent` on aid-create-ticket (level_map deferred — needs a connector-descriptor field per §4). Ledger cleaned; Lifecycle → Paused-Awaiting-Input; ready for /aid-plan |
| 2026-07-22 | Plan FIRST-RUN — PLAN.md + 3 delivery folders authored | -- | 3 deliveries: 001 skills → 002 retire+consolidate (feat 002/003/004) → 003 KB+render (feat 005); all 5 features assigned; 3 real cross-cutting risks (R1 terminal-render completeness, R2 dual-generation coordination in d-002, R3 deferred-parity scoped to d-003); each delivery folder BLUEPRINT+STATE at Pending-Spec, branch aid/work-023-delivery-NNN. A+ review dispatched |
| 2026-07-22 | Detail review cycle-1 graded + FIX | B+ | aid-reviewer (Large, disk-verified): 13/14 clean (type/coverage/deps/graphs/flagged-decisions all verified); 1 LOW — task-008 REFACTOR neither overrides nor affirms the "no behavior change" type-default though it retires behavior (inconsistent w/ siblings 006 supersede / 007 affirm). Objective, no owner decision. FIX dispatched: add the supersede sentence to task-008 ACs (task-006 pattern) |
| 2026-07-22 | Detail review cycle-1 FIX applied | -- | task-008 gained an explicit REFACTOR-defaults-superseded AC (intentional behavior retirement; correctness via its own removal/reroute ACs + task-010 tests); no other file changed. Re-review cycle-2 dispatched |
| 2026-07-22 | Detail review cycle-2 → A+ → DONE; **DEFINITION COMPLETE — HALT pre-execute** | A+ | task-008 LOW verified Fixed (sole changed file, mtime-confirmed); grade.sh A+. All definition phases now A+: Describe/Define/Specify/Plan/Detail. Ledger cleaned. Lifecycle → Paused-Awaiting-Input; **AWAITING OWNER APPROVAL before /aid-execute** (writes production code: 3 skills + shared ref, retractions/reroutes across ~11 files, protocol revision, KB edit, terminal render + dogfood resync) |
| 2026-07-23 | Execute started (owner-approved drive-all, per-delivery A+ gate) — delivery-001 tasks 001-005 Done | -- | On branch work-023-ticket-integration (single-branch; no per-delivery branches; no commits — working tree). task-001 shared ticket-resolution.md + 002/003/004 skills + task-005 tests (89/89). Per-task quick-checks clean; 1 MED (parent/connector cross-tracker rule) + argument-hint LOW fixed on-spot |
| 2026-07-23 | delivery-001 gate cycle-1 graded | A | Medium-tier gate (complexity 12): 89/89 tests pass; canonical-only / DRY / content-isolation / cross-task coherence / no-silent-default all clean; **1 MINOR** — the 3 skills use different `##`/`###` section-header conventions for the identical state chain. A < A+ floor → FIX. Header-normalization fix dispatched; re-gate pending |
| 2026-07-23 | delivery-001 gate cycle-1 FIX applied | -- | 3 skills normalized to `## States` + `### State N — TOKEN` (identical across the trio); state TOKENs/body/Advance unchanged; tests 89/89 (assert_header token-tolerant — no test change). Re-gate cycle-2 dispatched |
| 2026-07-23 | delivery-001 gate cycle-2 → A+ → DONE | A+ | MINOR Fixed + verified regression-free (dropped header annotations confirmed still in state bodies; 89/89 tests; only the 5 delivery-001 files touched). Gate recorded (Medium tier, 2 cycles). **delivery-001 Done.** delivery-002 started (serial 006→010); task-006 (retire 6 PM-TOOL write sites) In Progress |
| 2026-07-23 | delivery-002 tasks 006-010 executed + gate cycle-1 graded | D+ | Serial 006→010 all Done: 006 retired 6 PM-TOOL write sites (grep-zero), 007 rerouted 6 read seams → /aid-read-ticket, 008 removed aid-execute Connector-Mirroring + split aid-plan Step 4c + rerouted comment writes, 009 revised consumption-protocol.md (E1-E7), 010 test-ticket-retirement-structural.sh (98/98). Large-tier gate (complexity 17): scope clean, AC-7/8/9/11 + FR-6 single-outward-surface invariant hold, both suites green; **1 HIGH** — aid-plan first-run-loop.md Step 4c create-suggestion printed unconditionally (missing connector-gate; NFR-3/AC-10 regression vs the 6 sibling task-006 sites). D+ < A+ floor → FIX |
| 2026-07-23 | delivery-002 gate cycle-2 → A+ → DONE | A+ | HIGH Fixed (create-half gated to the sibling task-006 pattern; both Step-4c halves now silent-skip on a no-connector project) + T093 guard added (suite 99/99); independent re-gate confirmed RESOLVED, found **1 MINOR** (header trace-range T087-T099 overlapped the T099 self-check) → Fixed → T087-T098; grade.sh → A+; delivery-001 89/89 no-regression; only delivery-002's own files touched. Gate recorded (Large tier, 2 cycles). **delivery-002 Done.** Starting delivery-003 (feature-005 KB+propagation, tasks 011-014); task-011 next |
| 2026-07-23 | delivery-003 tasks 011-014 executed + gate cycle-1 graded | B+ | task-011 (canonical document-expectations: dropped `, entity mapping if applicable`, kept lead Q + red flag) + task-012 (dogfood KB infrastructure.md § Project Management Tooling: connectors + dedicated-skills model, KB->KB integration-map §Connectors + KB->source 3 skills/ladder, 0 context-file cites, Change Log last) + task-013 (terminal render: run_generator.py once -> 1765 files/0 deleted, VERIFY PASS; manifest-driven dogfood resync) + task-014 (gate suites). Large-tier terminal gate independently re-verified ALL technical ACs clean (render across 5 profiles + dogfood, byte-identity 711/711, citation-lint 8/8, frontmatter-lint 57/57, R1 completeness, 0 PM-TOOL residue); **1 LOW [TASK]** — all 4 task STATE.md `review:` fields left at default `--`. B+ < A+ floor → FIX |
| 2026-07-23 | delivery-003 gate → A+ → DONE; **EXECUTE COMPLETE** | A+ | LOW Fixed (all 4 `review:` fields populated with substantive self-verification notes matching the tasks 001-010 convention); grade.sh → A+. Gate recorded (Large tier, 1 cycle). **delivery-003 Done.** All 3 deliveries Done at A+ → Execute phase complete; work code-complete on branch work-023-ticket-integration. Lifecycle → Paused-Awaiting-Input for owner ship decision. Reviewer process-note: local master diverged (PR #167 da66a79a) from branch-point 60a3c70f → merge origin/master + re-render/re-verify before shipping. cli-parity CI-deferred (no CLI file touched) |
| 2026-07-22 | Plan gate → A+ → DONE (Plan complete) | A+ | aid-reviewer (Large, adversarial, disk-verified): 0 findings — coverage 5/5 assigned; acyclic 001→002→003; delivery-002 grouping independently verified (both write-generations live in distinct files, must retire together for FR-6); gate criteria trace to feature ACs (AC-1..6 / 7..11 / 12..13); 3 risks real; single-branch/one-render matches architecture invariants. grade.sh 0/0/0/0/0 → PASS (1 cycle). Ledger cleaned. Next: /aid-detail |
| 2026-07-22 | Detail FIRST-RUN — 14 tasks authored across 3 deliveries | -- | aid-architect: 14 tasks (d-001: task-001..005 = 4 IMPLEMENT + 1 TEST; d-002: 006..010 = 3 REFACTOR/IMPLEMENT + 1 TEST; d-003: 011..014 = 2 DOCUMENT + 1 CONFIGURE + 1 TEST). DETAIL.md+STATE.md (Pending) each; execution graphs appended to PLAN.md. Decisions: task-009 IMPLEMENT (protocol contract); task-012 KB edit in .aid/knowledge (not canonical) per feat-005; feature-003 split 007/008 on dual-anchor files; d-002 serialized. A+ review dispatched |

---

## Deploy State

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS -- assembled at read time from per-feature/per-delivery/per-task
     files. Never written directly here. Full multi-delivery layout: the flattened-only
     Delivery Lifecycle / Tasks lifecycle / Delivery Gate sections are intentionally absent.
     ============================================================ -->

## Features State

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-dedicated-ticket-skills | Ready | A+ | 0 | Tech spec A+ incl. --level/--parent enhancement (re-gate: E+ → C+ → A+); SPEC gate CLEARED |
| 2 | feature-002-pm-tool-write-retirement | Ready | A+ | 0 | Tech spec A+ (3 cycles: E+ → fix → B+ → fix → A+); SPEC gate CLEARED |
| 3 | feature-003-connector-seam-consolidation | Ready | A+ | 0 | Tech spec A+ (2 cycles: E+ → fix-all → A+); SPEC gate CLEARED |
| 4 | feature-004-consumption-protocol-revision | Ready | A+ | 0 | Tech spec A+ (2 cycles: E → fix-all → A+); SPEC gate CLEARED |
| 5 | feature-005-kb-update-and-propagation | Ready | A+ | 0 | Tech spec A+ (2 cycles: C → fix-all → A+); SPEC gate CLEARED |

## Plan / Deliveries

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

_None yet._

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
