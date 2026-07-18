# Delivery BLUEPRINT -- delivery-001: Editable Project & Pipeline/Task Surface

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-017-cli-improvements
> **Created:** 2026-07-18

---

## Objective

Turn the read-only dashboard into an editable control surface for a project and its
pipelines/tasks, and lay the write foundation the whole work depends on. On loopback a user
edits a project's name, description, and global minimum-grade from the redesigned `home.html`
header; renames a pipeline (via the `REQUIREMENTS.md **Name:**` title) and a task (via a mutable
`display_name` cell), both display-only with a slug / `short_name` fallback; and edits a task's
notes. Every edit is dispatched to a canonical child-process writer (`write-setting.sh`,
`write-requirement.sh`, or the existing single writer `writeback-state.sh`), never written
in-process, and the view re-renders truthfully from a post-write read off disk. This delivery is
scoped as the foundation because feature-001 delivers no standalone interaction on its own -- it
ships the server op-endpoints, the closed `OP_TABLE` (with the per-op `status_map` hook later
deliveries need), the `--allow-writes` / `write_enabled` gate, the worktree-aware
`resolve_work_dir` (invariant WT-1, required by work-017's own worktree topology), the reader-twin
byte-parity discipline, and the shared `home.html` `write_enabled` graft -- so it is bundled with
the first usable home.html edit interactions to be a functional MVP.

## Scope

In scope:
- **feature-001-write-infrastructure** -- server POST op-endpoints (`/r/<id>/api/op` + `/api/op`), `OP_TABLE` + per-op `status_map`, `--allow-writes` / `write_enabled` gate, `writeback-state.sh` wiring, new `write-setting.sh` and `write-requirement.sh` writers (co-vendored via `dashboard/MANIFEST`), worktree-aware `resolve_work_dir` (WT-1), additive `write_enabled` envelope key, reader-twin byte-parity.
- **feature-002-project-header-edit** -- `home.html` project-header redesign (name / description / global grade + KB button); additive DM-1 reader exposure of `project.description` and global `review.minimum_grade`; consumes the `settings.set` op; introduces the shared `envelope.write_enabled -> model.write_enabled` graft.
- **feature-005-display-rename** -- `pipeline.rename` (consumes `write-requirement.sh`) + `task.rename` (extends `writeback-state.sh` with a `Name -> display_name` field + flat-table `Name` column); reader-twin `TaskModel.display_name`; `home.html` rename controls.
- **feature-006-task-notes** -- concrete `task.set-notes` argv-builder + arg-schema; `home.html` task drill-view Notes card.

**Out of scope:** all index.html registry/tooling ops (delivery-002); connectors + external-sources lists (delivery-003); pipeline delete (delivery-004); pipeline finish + task stop/resume (delivery-005).

## Gate Criteria

- [ ] AC1 (header) -- editing name / description / global minimum-grade from the header persists to `.aid/settings.yml` via `write-setting.sh` and is performed entirely from the dashboard.
- [ ] AC1 (rename) -- renaming a pipeline (`REQUIREMENTS.md **Name:**`) and a task (`display_name` cell) from the dashboard persists to disk; AC5 -- only the shown label changes (folder, branch, worktree, `DETAIL.md`, task structure untouched).
- [ ] AC1 (notes) -- editing a task's notes from the dashboard persists to disk.
- [ ] AC2 -- after any of the above writes, the view re-renders from a post-write read off disk with no drift (rename shows the new title with slug / `short_name` fallback when cleared).
- [ ] AC3 -- every Pipeline/Task STATE write goes through `writeback-state.sh`; no DERIVED union view is ever hand-written.
- [ ] AC4 -- the Python reader and `reader.mjs` stay byte-consistent (parity suites green; golden fixtures regenerated in lockstep for the additive `write_enabled`, `project_description`, `minimum_grade`, and `display_name` keys).
- [ ] AC8 -- on loopback writes work; under `--remote` the dashboard is read-only unless `--allow-writes` (+ tailnet ACL), and the UI hides controls the server would refuse.
- [ ] WT-1 -- every pipeline-scoped op targets the exact on-disk work dir the reader resolved via `resolve_work_dir` (incl. a worktree-isolated pipeline), never a reconstructed served-tree path; 404 when no worktree holds the `work_id`.
- [ ] OP-SM -- the `OP_TABLE` row schema exposes the OPTIONAL per-op `status_map` override (dispatcher uses `op.status_map or DEFAULT_MAP`); default-preserving for feature-001's own STATE/settings/requirement ops. This is a foundation contract **delivery-002 (features 003/004) depends on** to map the `aid` CLI's differing exit alphabet (feature-003 integration requirement / KI-004).
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | --allow-writes write gate + write_enabled envelope signal |
| task-002 | IMPLEMENT | Worktree-aware resolve_work_dir resolver (WT-1) |
| task-003 | IMPLEMENT | Foundation writers write-setting.sh + write-requirement.sh + MANIFEST co-vendor |
| task-004 | IMPLEMENT | POST op-router + closed OP_TABLE + op.status_map or DEFAULT_MAP dispatch |
| task-005 | IMPLEMENT | DM-1 reader exposure of project_description + global minimum_grade |
| task-006 | IMPLEMENT | home.html project-header edit panel + settings.set client |
| task-007 | IMPLEMENT | writeback-state.sh Name->display_name task-field extension |
| task-008 | IMPLEMENT | TaskModel.display_name reader twins + task.rename & pipeline.rename op argv-builders |
| task-009 | IMPLEMENT | Pipeline + task rename UI |
| task-010 | IMPLEMENT | Task Notes card + task.set-notes handler |
| task-011 | TEST | Foundation parity + dispatch round-trip suite |
| task-012 | TEST | Consuming-op round-trips + model-field parity |

## Dependencies

- **Depends on:** -- (none; foundation)
- **Blocks:** delivery-002, delivery-003, delivery-004, delivery-005

## Notes

Cross-cutting: KI-001 (settings-reader divergence) is contained here -- constrain the
`write-setting.sh` output alphabet to what all four settings readers strip identically. The
per-op `status_map` hook on `OP_TABLE` must ship in this delivery so delivery-002's `aid`-CLI ops
can override the exit-to-HTTP map. The shared `home.html` `write_enabled` graft (feature-002
introduces it; features 005/006 reuse it) is intra-delivery coordination.
