# Analysis — work-004 worktree-aware tracking + state partition

> Read-only grounded map. Confidence: CONFIRMED / LIKELY / UNCERTAIN.

## The two coupled problems
- **Worktree blindness.** The reader resolves ONE `.aid/` per registered repo root and globs only `<root>/.aid/work-[0-9]*-*` (`dashboard/reader/locator.py:46,85`); it never enumerates worktrees. mas main checkout `.aid/` has no work folder; the in-flight works live in `.claude/worktrees/*/​.aid/`.
- **Monolithic STATE.md collides on parallel branches.** The whole `## Tasks Status` table + `## Pipeline Status` + `## Quick Check Findings` + `## Calibration Log` + `## Dispatches` live in one file; every task of every delivery writes into it via `writeback-state.sh --field` (`canonical/scripts/execute/writeback-state.sh:197-351`). Two delivery branches → divergent copies + git merge conflict on merge-back. An intra-process sentinel lock (`:156-188`) serializes the SAME-filesystem pool but cannot help cross-branch.

## Collision surface (CONFIRMED, written during execution)
`## Tasks Status` (CRITICAL), `## Pipeline Status` (HIGH), `## Quick Check Findings` (HIGH), `## Calibration Log` (HIGH, append), `## Dispatches` (HIGH, append), `## Delivery Gates` (per-delivery-keyed, shared file). Already-disjoint (safe): `tasks/task-NNN.md` (definitions, no status), `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md`.

## Worktree mechanics — TWO conflicting conventions (decision needed)
| Source | Path | Branch | Lifetime |
|---|---|---|---|
| aid-execute PD-2 spec (`state-execute.md:142,243`) | `.aid/.worktrees/task-NNN/` | shared delivery branch | ephemeral (deleted on completion) |
| Real host (mas, `git worktree list`) | `.claude/worktrees/<name>` | `aid/{work}-delivery-NNN` | persistent |
→ worktree path is NOT an AID constant; a fixed glob is fragile. The dashboard needs the PERSISTENT host worktrees.

## Discovery options (reader extension)
- **A. `git worktree list --porcelain`** (recommended): authoritative paths + branch labels, host-agnostic, omits pruned worktrees. Precedent: the reader ALREADY runs read-only git for KB freshness via a fixed-argv / no-shell subprocess (rev-parse/symbolic-ref/log; Node twin `reader.mjs:525-544`). Cost: relaxes `locator.py:1-7` "stat+iterdir only" contract; degrade to main root if git/non-git unavailable. CORRECTION: there is NO enforced git-verb allow-list to extend — Node `runGitCommand` has none, and Python `_GIT_ALLOWED_VERBS` (`derivation.py:101`) is defined but never referenced (documentary). Safety comes from the hard-coded argv, not an allow-list; adding/enforcing a verb-guard is OPTIONAL hardening (see SPEC SD-3).
- **B. filesystem glob** of a worktree parent: stays filesystem-only but fragile (the two path conventions differ; misses worktrees elsewhere; races ephemeral per-task ones).
- Insertion: locator layer (additive enumeration of `(branch, aid_dir)` roots); `read_repo` per root + merge. Server unchanged if enumeration lives in `read_repo`. **Node twin `reader.mjs` must mirror.**

## Same-work reconcile (no "winner")
When a `work_id` appears in N worktrees/main: MERGE. Per task → most-advanced status; work-level `## Pipeline Status` → newest `Updated:`. Status enum (`writeback-state.sh:225`): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled. Advancement ordering must be DEFINED (proposed: Done > In Review > In Progress > Blocked/Failed > Pending — confirm).

## Placement options + the minimal call
| Level | Path | Content | Disjoint per branch? |
|---|---|---|---|
| Task status (recommended) | `tasks/task-NNN.status.md` | the 4 mutable cells: Status / Review / Elapsed / Notes | YES (a task lives on one delivery branch) |
| Task status (alt) | append `## Status` to `tasks/task-NNN.md` | same | yes, but mixes mutable state into the immutable definition (smell) |
| Delivery rollup | `delivery-NNN/STATE.md` | delivery lifecycle/gate | yes — but only-unique content (gate) already in `delivery-NNN-issues.md` + `## Delivery Gates` → **redundant** |
| Work header | keep `STATE.md` `## Pipeline Status`, Triage | unchanged | no — work-level; newest-`Updated:` merge rule |
| Work `## Tasks Status` | becomes a **derived/read-only** view assembled from per-task files | — | N/A (never write-merged) |

**Minimal (recommended):** move the 4 mutable per-task cells → `tasks/task-NNN.status.md` (one writer per task, one branch → no collision); make `## Tasks Status` a DERIVED read-only view (answers "which wins" = the union, no winner). Keep `## Pipeline Status` work-level + newest-wins. Leave already-disjoint files. **Avoid:** a full per-delivery `STATE.md` hierarchy (duplicates the gate) and storing status in BOTH the per-task file AND the table (re-introduces drift/conflict — the table MUST be derived, never a second write target).

## Blast radius (status partition)
Status is READ by 4 consumers — dashboard reader (Py `reader.py:381` + Node twin `reader.mjs`), aid-execute STATE routing (`SKILL.md:75,110-120`), PD-1 ready-set (`state-execute.md:114-120`) — and WRITTEN by 1 (`writeback-state.sh --field`). Plus `schemas.md` (KB contract), reader test fixtures, and the 5 profile copies of the EXECUTE `writeback-state.sh` + the `.claude/scripts/execute/` dogfood copy (render-drift). Moving status touches all of these. CORRECTION: `canonical/scripts/summarize/writeback-state.sh` is NOT an identical copy of the execute script — it is a separate ~5 KB script that only appends `## Summarization History` to `.aid/knowledge/STATE.md` (no `--field`/`--findings`/`--block`/`--pipeline` modes; `diff` => DIFFER). It is EXCLUDED from the status-partition blast radius and from the task-003 retarget.

## Migration / coexistence
All existing works are monolithic (work-001/002/003/004 + mas's worktree works). Reader rule: if per-task status files exist → derive from them; else parse the inline table (reader is already fallback-tolerant, `reader.py:363-377`). No DB / no data migration — markdown layout + reader tolerance. New works adopt per-task files; legacy keep working.

## Open SPEC decisions
1. Discovery: A (`git worktree list`) vs B (glob). [recommend A]
2. Partition granularity: per-task-status-file + derived table (minimal) vs explicit per-delivery file too. [recommend minimal]
3. Same-work reconcile ordering (define the Status advancement order).
4. `## Pipeline Status` granularity: work-level + newest-wins (minimal) vs per-delivery. [recommend work-level]
5. Append-only logs (`## Calibration Log`, `## Dispatches`, `## Lifecycle History`) ALSO conflict cross-branch — partition them per-task/delivery, or accept mechanical append-merge? [secondary; lower stakes]
