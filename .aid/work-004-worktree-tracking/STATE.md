# Work State — work-004-worktree-tracking

> **Status:** Executing — delivery-001 (worktree aid/work-004-delivery-001)
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
| 2 | KB: schemas.md + project-structure.md | DOCUMENT | 2 | Pending | — | — | deps 001 |
| 3 | writeback-state.sh canonical: retarget to per-unit STATE | REFACTOR | 2 | Pending | — | — | deps 001; `--delivery-id` contract |
| 4 | Propagate EXECUTE writeback to 5 profile copies + dogfood (summarize EXCLUDED) | REFACTOR | 3 | Pending | — | — | deps 003; render-drift |
| 5 | aid-detail: create task folders (SPEC+STATE) | REFACTOR | 3 | Pending | — | — | deps 001,002 |
| 6 | aid-plan: create delivery folders (SPEC+STATE) | REFACTOR | 3 | Pending | — | — | deps 001,002 |
| 7 | aid-execute: new task SPEC path, write task STATE, routing | REFACTOR | 4 | Pending | — | — | deps 003,005,006 |
| 8 | aid-interview lite path: scaffold work folder | REFACTOR | 4 | Pending | — | — | deps 005,006 |
| 9 | Reader (Py): hierarchy derivation + legacy fallback | IMPLEMENT | 3 | Pending | — | — | deps 001,002 |
| 10 | Reader (Py): worktree enumeration (fixed-argv) + degrade + optional verb-guard | IMPLEMENT | 4 | Pending | — | — | deps 009 |
| 11 | Reader (Py): same-work reconcile | IMPLEMENT | 5 | Pending | — | — | deps 009,010 |
| 12 | Reader (Node reader.mjs): mirror 009-011 (parity) | IMPLEMENT | 6 | Pending | — | — | deps 009,010,011 |
| 13 | Idempotent migration helper (bash + PS) + fixture | MIGRATE | 3 | Pending | — | — | deps 001,002 |
| 14 | Reader fixtures: hierarchy/legacy/multi-worktree/reconcile | TEST | 6 | Pending | — | — | deps 009-011,013 |
| 15 | Cross-cutting: disjoint-merge proof, parity, render-drift, run-all | TEST | 7 | Pending | — | — | deps 004,007,008,012,013,014 |

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
| 2026-06-18 | Wave 1 complete (task-001): 5 per-level templates (work/delivery/task STATE + delivery/task SPEC), state-naming contract (no Status remains), SD-8 enum, SD-2 authoritative ordering; render-drift + §7a clean; template test 80/80. Committed. Wave 2: task-002 (KB) + task-003 (writeback retarget) dispatched. |
