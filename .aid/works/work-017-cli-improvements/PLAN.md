# Plan -- Interactive AID Dashboard (work-017)

## Deliverables

### delivery-001: Editable Project & Pipeline/Task Surface
- **What it delivers:** On loopback, a user can edit a project's name, description, and global minimum-grade from the redesigned `home.html` header, rename a pipeline and a task (display-only, with slug / `short_name` fallback), and edit a task's notes -- every edit persisted to disk through the canonical writers and truthfully re-rendered from disk with no drift. This delivery also lands the write foundation every later delivery builds on: the server op-endpoints, the `OP_TABLE` (incl. the per-op `status_map` hook), the `--allow-writes` / `write_enabled` gate, `writeback-state.sh` wiring, the new `write-setting.sh` / `write-requirement.sh` writers, the worktree-aware `resolve_work_dir` (WT-1), and reader-twin byte-parity.
- **Features:** feature-001-write-infrastructure, feature-002-project-header-edit, feature-005-display-rename, feature-006-task-notes
- **Depends on:** --
- **Priority:** Must

### delivery-002: Registry & Tooling Management
- **What it delivers:** From the all-projects `index.html` grid, a user can Add and Remove tracked projects (typed absolute path; Remove is untrack-only, no files removed) and Update Tools per-project (`aid update`) plus a global Update CLI (`aid update self`), seeing the CLI version pill and per-repo tool-version chips refresh from a post-op `/api/home` read.
- **Features:** feature-003-project-registry, feature-004-update-tools _(sequence 003 before 004; they share the single `aid`-CLI resolver + `card-actions` scaffold, KI-004)_
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: List Management
- **What it delivers:** On the project page (`home.html`), a user can view, add, and remove both connectors (`.aid/connectors/`) and external sources (`.aid/knowledge/external-sources.md`) through a shared list-CRUD UI, dispatched to atomic single-entry writers (`write-connector.sh`, `write-external-source.sh`); connectors regenerate their `INDEX.md`. Both registries follow the discover-authoritative + dashboard-atomic ownership model (STATE.md Q6 & Q7, both Answered) -- no `/aid-discover` change is required, so nothing is EXECUTE-gated.
- **Features:** feature-007-connectors-list, feature-010-external-sources-list
- **Depends on:** delivery-001
- **Priority:** Should

### delivery-004: Delete Pipeline (guarded)
- **What it delivers:** From a pipeline's detail view, a user can delete a pipeline (its work folder and, for a worktree-isolated pipeline, its dedicated worktree; the git branch is retained) behind a type-to-confirm Danger-zone modal, with Running and current-worktree guards that refuse an unsafe delete.
- **Features:** feature-009-pipeline-delete
- **Depends on:** delivery-001
- **Priority:** Should

### delivery-005: Execution Control
- **What it delivers:** A user can Finish a running pipeline (`lifecycle = Completed`) and Stop/Resume the currently-executing task from the dashboard, via a cooperative heartbeat-cadence stop-signal that the running `aid-execute` session polls (the server is LLM-free and cannot kill a separate agent session). The Stop/Resume control appears only for the currently-running task.
- **Features:** feature-008-execution-control
- **Depends on:** delivery-001
- **Priority:** Should

## Execution Graphs

> Per-delivery task ordering read by `/aid-execute` and the dashboard reader. Deps annotated
> `(delivery-NNN)` are cross-delivery prerequisites already satisfied before the delivery starts
> (guaranteed by the delivery's `Depends on` in the roadmap above); they do NOT count toward the
> delivery's internal waves. Each `wave-map` block is the machine-readable lane map; the
> dependency / parallel tables above it are human-facing.

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001, task-002, task-003 |
| task-005 | task-001 |
| task-006 | task-004, task-005 |
| task-007 | task-003 |
| task-008 | task-003, task-004, task-007 |
| task-009 | task-004, task-006, task-008 |
| task-010 | task-004, task-006 |
| task-011 | task-001, task-002, task-003, task-004 |
| task-012 | task-005, task-006, task-008, task-009, task-010 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003, task-005 |
| task-004, task-007 |
| task-006, task-008, task-011 |
| task-009, task-010 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003, task-005
wave 3: task-004, task-007
wave 4: task-006, task-008, task-011
wave 5: task-009, task-010
wave 6: task-012
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-013 | task-004 (delivery-001) |
| task-014 | task-013 |
| task-015 | task-013 |
| task-016 | task-014, task-015 |
| task-017 | task-013, task-014, task-015, task-016 |

| Can Be Done In Parallel |
|------------------------|
| task-014, task-015 |

```wave-map
delivery: 002
wave 1: task-013
wave 2: task-014, task-015
wave 3: task-016
wave 4: task-017
```

### delivery-003 execution graph

> Two independent tracks -- connectors (task-018 -> task-019) and external sources
> (task-020 -> task-021) -- run in parallel and converge at the shared list-CRUD UI (task-022);
> the wave-map emits one line per track for the parallel waves.

| Task | Depends On |
|------|-----------|
| task-018 | task-004 (delivery-001) |
| task-019 | task-018, task-004 (delivery-001) |
| task-020 | task-004 (delivery-001) |
| task-021 | task-020, task-004 (delivery-001) |
| task-022 | task-019, task-021 |
| task-023 | task-018, task-019, task-020, task-021, task-022 |

| Can Be Done In Parallel |
|------------------------|
| task-018, task-020 |
| task-019, task-021 |

```wave-map
delivery: 003
wave 1: task-018
wave 1: task-020
wave 2: task-019
wave 2: task-021
wave 3: task-022
wave 4: task-023
```

### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-024 | — |
| task-025 | task-024, task-004 (delivery-001) |
| task-026 | task-025 |
| task-027 | task-024, task-025, task-026 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 004
wave 1: task-024
wave 2: task-025
wave 3: task-026
wave 4: task-027
```

### delivery-005 execution graph

> After the shared writer (task-028), two tracks run in parallel -- the dashboard op/UI track
> (task-029 -> task-030, round-trip-tested by task-033) and the executor cooperative-poll track
> (task-031 -> task-032, verified by its own canonical-render / twin-parity ACs, not by task-033).
> task-033's TEST scope covers the dashboard-op round-trips only (its deps are task-028/029/030);
> the wave-map emits one line per track for the parallel waves.

| Task | Depends On |
|------|-----------|
| task-028 | task-002 (delivery-001) |
| task-029 | task-028, task-004 (delivery-001) |
| task-030 | task-029, task-004 (delivery-001) |
| task-031 | task-028 |
| task-032 | task-031 |
| task-033 | task-028, task-029, task-030 |

| Can Be Done In Parallel |
|------------------------|
| task-029, task-031 |
| task-030, task-032 |

```wave-map
delivery: 005
wave 1: task-028
wave 2: task-029
wave 2: task-031
wave 3: task-030
wave 3: task-032
wave 4: task-033
```

## Cross-Cutting Risks

| # | Risk | Spans | Severity | Mitigation |
|---|------|-------|----------|------------|
| 1 | **Worktree topology / WT-1.** work-017 runs from its own git worktree, so every pipeline-scoped write op MUST target `resolve_work_dir` output (the reader-reconciled winner), never a reconstructed `<served-root>/.aid/works/<work_id>` path -- else it 404s or writes the wrong tree. Sub-risk KI-007 (Low, latent): the reader reconciles task rows per-task-most-advanced, independent of the work-level winner, so a duplicated `work_id` across worktrees could read back a task field from a different copy than the write targeted. | delivery-001 (owns `resolve_work_dir`), delivery-004 (delete: folder+worktree via `enumerate_worktree_roots` hand-off), delivery-005 (stop-signal + `stop_requested` read-back) | High (KI-007: Low) | `resolve_work_dir`/WT-1 is a delivery-001 foundation contract reused verbatim by all consumers; KI-007 not present in work-017's live topology (no duplicate `work_id`), any fix belongs in feature-001's reconcile/resolve alignment. |
| 2 | **KI-004 shared `aid`-CLI helper + `card-actions` scaffold.** features 003 and 004 both shell out to the `aid` CLI and both add a per-repo-card action row; the resolver, the `card-actions` sibling-row scaffold, and the per-op `status_map` override must be single-sourced, not re-invented. | delivery-002 (003 introduces, 004 reuses); the `status_map` hook must ship in delivery-001's `OP_TABLE` (the `aid`-CLI exit alphabet differs from `writeback-state.sh`'s) | Medium | Sequence 003 before 004 within delivery-002; delivery-001 ships the `status_map` hook so delivery-002 can override the exit-to-HTTP map. |
| 3 | **KI-001 settings-reader divergence.** `project.name` / `project.description` are read by four divergent ad-hoc parsers; `write-setting.sh`'s output and feature-002's new DM-1 exposure must round-trip byte-identically through all of them or AC2 shows a wrong value after a write. | delivery-001 (feature-001 writer + feature-002 read exposure) | Medium | Constrain the writer's output alphabet to what every reader strips identically (reject embedded `"`/`\`/newline); underlying parser unification is a post-ship follow-up. |
| 4 | **feature-008 executor render blast-radius.** Beyond the dashboard write, the cooperative stop-signal only bites once the `aid-execute` poll edit is rendered canonical -> 5 profiles -> dogfood + parity; this is the single largest render surface in the work. | delivery-005 | Medium-High | Isolated as the last deliverable so its risk cannot delay simpler deliverables; the dashboard side satisfies AC-EC1/AC2/AC3/AC6 on its own, and the baseline orchestrator poll is separable from the recommended sub-agent `STOP_FILE` enhancement. |

## Deferred

_None -- all 10 features are assigned to a deliverable._
