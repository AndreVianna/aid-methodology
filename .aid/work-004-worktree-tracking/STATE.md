# Work State — work-004-worktree-tracking

> **Status:** Implementation complete — run-all 52/52; delivery A+ gate pending
> **Phase:** Execute
> **Minimum Grade:** A+ (per user directive)
> **Started:** 2026-06-18
> **User Approved:** pending

Worktree-aware pipeline tracking + state-file partitioning (per work → delivery → task) so branch-isolated work is discoverable, and parallel delivery branches don't collide on one monolithic `STATE.md`.

## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-18T16:00:00Z
- **Pause Reason:** —
- **Block Reason:** —
- **Block Artifact:** —

## Triage

- **Path:** lite
- **Work Type:** feature
- **Sub-path:** LITE-FEATURE
- **Sub-path (auto):** LITE-FEATURE
- **Decision rationale:** A new tracking capability (worktree-aware discovery) plus a contained state-model refactor (granularity split); requirements are clear from the design discussion, no full interview needed.
- **Override:** no
- **Recipe:** none

## Scope (provisional — pending SPEC)

1. **Worktree-aware discovery.** The dashboard reader enumerates a repo's worktrees (`git worktree list`) and aggregates each worktree's `.aid/work-*/` pipelines under the project, labeled by branch/worktree.
2. **Same-work merge rule.** When the same `work_id` appears across worktrees/main, MERGE rather than pick a winner: most-advanced status per task; newest `Pipeline Status` (`Updated:`) for the work-level lifecycle.
3. **State partition (per work → delivery → task).** Split the monolithic per-work `STATE.md` so parallel delivery branches write DISJOINT files (no merge conflict, no winner to choose). Careful placement + minimal schema; the work `STATE.md` stays the header + a derived/aggregated view. **Explicitly avoid overengineering.**

## Tasks Status

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| 1 | Per-level STATE/SPEC template set + naming contract | DESIGN | 1 | Done | clean | — | foundation; 5 templates; 80/80 test; render-drift+§7a clean |
| 2 | KB: schemas.md + project-structure.md | DOCUMENT | 2 | Done | clean | — | deps 001; schemas §4 rebuilt; 2 doc nits (pre-gate sweep) |
| 3 | writeback-state.sh canonical: retarget to per-unit STATE | REFACTOR | 2 | Done | clean | — | disjoint writes VERIFIED; 1 cosmetic nit |
| 4 | Propagate EXECUTE writeback to 5 profile copies + dogfood (summarize EXCLUDED) | REFACTOR | 3 | Done | clean | — | full regen; render-drift + §7a clean; summarize unchanged |
| 5 | aid-detail: create task folders (SPEC+STATE) | REFACTOR | 3 | Done | clean | — | nested folders; derived view; globs retargeted |
| 6 | aid-plan: create delivery folders (SPEC+STATE) | REFACTOR | 3 | Done | clean | — | Pending-Spec authored; zero-task ok; derived view |
| 7 | aid-execute: new task SPEC path, write task STATE, routing | REFACTOR | 4 | Done | clean | — | +delivery-lifecycle writeback mode; residual naming → task-016 |
| 8 | aid-interview lite path: scaffold work folder | REFACTOR | 4 | Done | clean | — | lite scaffold; full-path naming → task-016 |
| 9 | Reader (Py): hierarchy derivation + legacy fallback | IMPLEMENT | 3 | Done | clean | — | hierarchy+legacy; delivery enum surfaced; 410 tests; never-throws |
| 10 | Reader (Py): worktree enumeration (fixed-argv) + degrade + optional verb-guard | IMPLEMENT | 4 | Done | clean | — | fixed-argv; degrade; 410 tests; cross-root merge → task-011 |
| 16 | Complete state-naming sweep across remaining skills (interview-full, specify, deploy, residual detail/plan/execute) | REFACTOR | 4 | Done | clean | — | sweep + wave-4 fixups (snapshot cols, Deploy State→AUTHORED, NNN/DDD, awk); repo-wide grep-clean |
| 11 | Reader (Py): same-work reconcile | IMPLEMENT | 5 | Done | clean | — | SD2_RANK + reconcile + tie-break; MEDIUM #3 cache fixed; 442 tests (32 new) |
| 12 | Reader (Node reader.mjs): mirror 009-011 (parity) | IMPLEMENT | 6 | Done | clean | — | parity 15/15 + 117/117; home.html anchor; State/Status dual |
| 13 | Idempotent migration helper (bash + PS) + fixture | MIGRATE | 3 | Done | clean | — | bash+PS twins; round-trip verified; LOW: relocate fixture out of canonical (wave 4) |
| 14 | Reader fixtures: hierarchy/legacy/multi-worktree/reconcile | TEST | 6 | Done | clean | — | 77 new tests (519 total); all scenarios + SD-2 boundaries + parity; task-010 LOW #4 covered |
| 15 | Cross-cutting: disjoint-merge proof, parity, render-drift, run-all | TEST | 7 | Done | clean | — | A-E all done; run-all 52/52; disjoint-merge proof 23/23; render-drift+§7a clean; parity green |

## Lifecycle History

| Date | Event |
|------|-------|
| 2026-06-18 | Work created; TRIAGE → lite (LITE-FEATURE) |
| 2026-06-18 | ANALYSIS dispatched (researcher) |
| 2026-06-18 | ANALYSIS complete (ANALYSIS.md); paused for 2 design decisions before SPEC |
| 2026-06-18 | Decisions LOCKED: uniform work/delivery/task folder hierarchy (each = SPEC.md + STATE.md, tasks nested under delivery); "state" naming; git worktree list discovery. SPEC drafting (architect). |
| 2026-06-18 | TASK-BREAKDOWN complete — SPEC.md + 15 tasks (7 waves). A+ gate dispatched. |
| 2026-06-18 | A+ gate #1: NOT clean (2 CRITICAL + 2 HIGH + minors); fix cycle dispatched. SD-5 hierarchy-justification confirmed. |
| 2026-06-18 | Fix cycle applied: #1 summarize-EXCLUDED (execute-only propagation), #2 no-allow-list premise corrected (fixed-argv pattern + optional hardening), #3 Cross-phase Q&A partitioned to delivery STATE, #4 task-014 re-waved to W6, #5 task-013 delivery-derivation from Source line, #6 home.html added, #7 Pipeline tiebreak, #8 lock-scope note. Folded SD-8 (delivery lifecycle enum) + SD-9 (independent delivery lifecycle / SPIKE-defines-sibling scenario). |
| 2026-06-18 | A+ gate #2: CLEAN — all 8 findings Fixed, refinement sound, disjoint-writes verified. Ready for /aid-execute. |
| 2026-06-18 | #93 (work-003) merged → work-004 plan path-refreshed onto post-#93 nested layout (EXECUTE writeback copies now `.../aid/scripts/execute/`; task-004 + SPEC + ANALYSIS). /aid-execute started in worktree aid/work-004-delivery-001 (off updated master). Version stays 1.1.0 (no bump — user directive). Wave 1: task-001 dispatched. |
| 2026-06-18 | Wave 1 complete (task-001): 5 per-level templates (work/delivery/task STATE + delivery/task SPEC), state-naming contract (no Status remains), SD-8 enum, SD-2 authoritative ordering; render-drift + §7a clean; template test 80/80. Committed (5052bdd4). Wave 2: task-002 (KB) + task-003 (writeback retarget) dispatched. |
| 2026-06-18 | task-003 complete (writeback retarget): 5 modes → per-unit STATE (--field/--findings→task, --block→delivery SD-5, --pipeline→work ## Pipeline State); delivery auto-resolve from Source; guards/enum/exit-codes preserved; 10/10 ad-hoc fixtures; bash -n + ASCII clean. test-writeback-state.sh DEFERRED to task-015 (91 fails = clean retarget consequences, NOT gutted). Awaiting task-002. |
| 2026-06-18 | task-002 complete (KB: schemas §4.0-4.7 rebuilt + project-structure hierarchy tree + SD-1/2/3/5/6/8/9 + INDEX regen; KB-hygiene green). Wave-1-2 review CLEAN — disjoint writes adversarially VERIFIED (each mode writes only its per-unit target). Wave 2 committed. KNOWN NITS for pre-gate sweep: schemas.md stale Foreign-keys note (LOW) + ER-diagram detail (MINOR); writeback missing-blank-line before a trailing heading (MINOR). Wave 3 (004,005,006,009,013) next; regen (004) serialized after the canonical edits (005,006,013). |
| 2026-06-18 | Wave 3a dispatched (canonical/dashboard edits, NO generator run — 3 tasks call the full generator so regen is serialized to 3b): task-005 (aid-detail task folders), task-006 (aid-plan delivery folders), task-009 (reader Py hierarchy), task-013 (migration helper). task-004 (single full regen propagating all pending canonical changes + dogfood sync) runs alone as 3b after 3a. |
| 2026-06-18 | Wave 3a complete (005 aid-detail, 006 aid-plan, 009 reader-Py, 013 migration) — all clean, scoped, no-generator. Cross-task heading coherence VERIFIED: `## Delivery Lifecycle`/`## Delivery Gate`/`## Cross-phase Q&A`/`## Tasks State`/`## Task State` identical across template(001) ↔ reader(009) ↔ aid-plan(006) ↔ migration(013); reader 410 tests pass. Wave 3b: task-004 (single full regen + dogfood sync) dispatched. |
| 2026-06-18 | Wave 3 complete (004,005,006,009,013). Wave-3 review CLEAN — integration round-trip PASSED (migration→reader chain: cells, delivery SD-8 enums, Q&A partition, zero-task Pending-Spec sibling, idempotent, PS-twin equivalent); heading consistency end-to-end; 410 reader tests; §7a+render-drift clean. Committed. NITS (pre-gate sweep): LOW migration fixture/ ships to adopters → relocate out of canonical/scripts/migrate to tests/ during wave 4 edit phase (regen cleans profiles); MINOR partial-ASCII in a non-gated skill md. Wave 4 (007,008,010) next. |
| 2026-06-18 | Wave 3 committed (d0d35a44). Wave 4 dispatched (parallel, NO regen — deferred to task-015 final regen): task-007 (aid-execute hierarchy + per-task State routing + delivery-gate Q&A retarget to delivery STATE [SD-5, fixes cross-branch hazard] + delivery lifecycle SD-8 advance; likely adds a delivery-lifecycle writeback mode), task-008 (aid-interview lite scaffold), task-010 (reader worktree enum via git worktree list --porcelain, fixed-argv/no-shell, 2s degrade). All canonical-skill regen + the deferred test fixes + fixture relocation consolidated into task-015. |
| 2026-06-18 | Wave 4 complete (007 aid-execute + writeback --lifecycle mode, 008 aid-interview lite scaffold, 010 reader worktree-enum). FINDING (dogfood): state-not-status rename UNDER-SCOPED by the SPEC — real bug in aid-interview full path (FIRST-RUN seeds `## Interview State`, full-path states write `## Interview Status`) + inconsistency in aid-deploy/aid-specify + residual refs in detail/plan/execute. USER DECISION: comprehensive sweep. Added task-016 (naming sweep across all 6 affected skills, template-aligned, reader keeps legacy coexistence); dispatched as 4 parallel agents (interview-full / specify / deploy / residual). |
| 2026-06-18 | task-016 sweep complete (4 agents): aid-interview full-path bug fixed (FIRST-RUN↔full-path both `## Interview State`); aid-specify (## Features State + field labels); aid-deploy (## Deploy/Tasks/Pipeline State; state-machine run-state labels preserved); residual detail/plan/execute. All grep-clean per skill. Wave-4 review (007/008/010/016) dispatched — repo-wide grep-clean + reader↔skill name alignment + specify-vs-deploy field consistency. |
| 2026-06-18 | Wave 4 + sweep review CLEAN (no CRITICAL/HIGH). 5 findings fixed (task-016b): MEDIUM drilldown+delivery-gate snapshot `Status`→`State` columns (sweep had missed them); LOW `## Deploy State` reclassified DERIVED→AUTHORED (deploy not hierarchy-migrated; template+schemas); MINOR NNN→DDD delivery-id placeholder; MINOR awk rewrites only first State line. Routed: MEDIUM #3 reader state_text_cache→task-011 (cross-root reconcile); LOW #4 task-010 coverage→task-014. Wave 4 committed. Wave 5: task-011 (reconcile + cache fix). |
| 2026-06-18 | Wave 4 committed (12f46a0d, 50 files). Wave 5: task-011 dispatched (reader same-work reconcile: most-advanced State by SD-2 + newest Updated w/ deterministic branch-label tie-break + unioned derived views; ALSO fixes MEDIUM #3 state_text_cache). |
| 2026-06-18 | Wave 5 complete (task-011, 442 tests). Committed (489b71e9). Wave 6a: task-012 (Node reader.mjs mirror of 009-011 + home.html _anchorRawState tolerate State/Status) dispatched alone; task-014 (fixtures, tests under BOTH twins) follows as 6b after 012. dashboard/ is vendored (no regen); test-dashboard-parity.sh in run-all checks Py↔Node parity. |
| 2026-06-18 | Wave 6 complete (012 parity, 014 fixtures 519 tests). Committed (597bfc15). Wave 7 task-015 (multi-step): 015-A dispatched — relocate migration fixtures out of canonical/scripts/migrate→tests/ (wave-3 LOW; don't ship), then single FULL regen propagating all wave-4→6 canonical changes (aid-execute/writeback/interview/specify/deploy/residual/templates/migrate) + dogfood sync + render-drift + §7a. |
| 2026-06-18 | 015-A complete (fixtures relocated, regen clean, §7a clean). 015-B triage (run-all HOME-pinned): 9/51 suites fail. Cause map: (naming/schema) test-writeback-state (91: --field State + per-unit), test-work-state-template WS17 (Deploy State now AUTHORED not DERIVED per 016b), test-pipeline-status-walkthrough (## Pipeline State), test-delivery-gate-aggregate (--block→per-delivery ## Delivery Gate, work view derived); (home.html VND sync cascade) test-home-html-source-sync + test-aid-migrate-trigger + test-release + test-release-install-e2e + test-install-parity (dashboard/home.html edited by 012, vendored copies not synced → VND guard fails release.sh). 015-C: 3 cluster-agents dispatched (writeback test / schema-naming tests / home.html-VND-release). |
| 2026-06-18 | 015-C complete: writeback test rewritten to per-unit contract (245/0); schema/naming suites fixed (WS17 Deploy-State-AUTHORED, ## Pipeline State, per-delivery gate; 79/166/19); home.html vendored copy synced (HS03 + VND-D01 + install-parity 84/84). test-release "failure" diagnosed as HEAD-render-drift (015-A regen was uncommitted) — RESOLVED by committing. Wave-7 part 1 committed (a9eb855f, 418 files: regen + fixes + home.html). 015-D dispatched (disjoint-merge proof test + schemas.md doc nits). Then 015-E final run-all + delivery A+ gate. |
| 2026-06-18 | 015-D complete (disjoint-merge proof test-disjoint-merge.sh 23/23 — two-branch zero-conflict merge, SD-5 Q&A partition; schemas.md FK+ER nits). Committed (074e435b). 015-E: FINAL run-all ALL 52 CANONICAL SUITES PASSED (incl. disjoint-merge), exit 0. ALL 16 TASKS DONE. → delivery A+ gate. 1 accepted non-blocking MINOR (pre-existing aid-housekeep partial-ASCII, regen-gated). |
