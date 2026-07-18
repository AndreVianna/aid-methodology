# Delivery BLUEPRINT -- delivery-004: Delete Pipeline (guarded)

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-004
> **Work:** work-017-cli-improvements
> **Created:** 2026-07-18

---

## Objective

Let a user completely remove a pipeline from the dashboard behind a strong confirmation gate.
From the pipeline detail view (`home.html` `#/work/<work_id>`), a Danger-zone control opens a
type-to-confirm modal (the user must type the `work_id` to arm the destructive button); on
confirm, `pipeline.delete` dispatches the new `delete-pipeline.sh` writer, which removes the work
folder (`rm -rf`) and, when the pipeline occupies a dedicated worktree, that worktree
(`git worktree remove --force`) -- while retaining the git branch as the recovery anchor. The
target on-disk directory and its owning worktree root+branch are resolved worktree-aware via
feature-001's `resolve_work_dir` + the `enumerate_worktree_roots` `(branch_label, aid_dir)`
hand-off (WT-1), so a worktree-isolated pipeline (work-017's own topology) is targeted correctly.
A Running guard and a current-worktree guard refuse an unsafe delete (409). This is a
self-contained destructive MVP, kept separate from execution control so its shippability is not
coupled to feature-008's larger render blast-radius.

## Scope

In scope:
- **feature-009-pipeline-delete** -- one `pipeline.delete` `OP_TABLE` row (both server twins); one new co-vendored writer `delete-pipeline.sh` (`set -euo pipefail`, fixed-argv git, realpath containment, single-reconciled-winner removal); one exit-7 -> HTTP 409 `pipeline-active` status-map row; a Danger-zone Delete control + type-to-confirm modal on `home.html`; branch retained.

**Out of scope:** deleting the git branch (retained by policy, OQ-PL3); Remove Project (that is feature-003's untrack-only op in delivery-002, categorically distinct -- no files removed); every other delivery's surface. No reader/parser change.

## Gate Criteria

- [ ] AC-PD1 -- confirming deletion from the dashboard removes the on-disk artifacts (work folder, and the dedicated worktree when present); no hand-removal by the user.
- [ ] AC2 -- after delete, the view re-renders from a post-op `/r/<id>/api/model` read; the pipeline no longer appears and the view matches disk with no drift.
- [ ] AC7 -- delete requires explicit confirmation (type-to-confirm the `work_id`) and removes the work folder + associated worktree; the branch is retained.
- [ ] Guards -- a `lifecycle == Running` pipeline and the current worktree both refuse deletion (409 `pipeline-active`); the main worktree is never removed (only the folder within it).
- [ ] WT-1 -- the target is resolved via `resolve_work_dir` (single reconciled winner); a `work_id` in no enumerated worktree root yields 404; realpath containment fences the `rm -rf` under `.aid/works/`.
- [ ] AC4 / AC8 (inherited) -- one identical `OP_TABLE` row + status-map row per twin (no parser change, no fixture bytes change); the Delete affordance and server both honour `write_enabled`.
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-024 | IMPLEMENT | delete-pipeline.sh guarded destructive writer |
| task-025 | IMPLEMENT | pipeline.delete op row + exit-7->409 map |
| task-026 | IMPLEMENT | Danger-zone Delete UI + type-to-confirm modal |
| task-027 | TEST | Delete round-trips + guard coverage |

## Dependencies

- **Depends on:** delivery-001 (write foundation: `OP_TABLE`, write gate, `resolve_work_dir` + the `enumerate_worktree_roots` worktree-root/branch hand-off, co-vendor mechanism)
- **Blocks:** -- (none)

## Notes

Edge case (candidate KI, surfaced not gating): a `work_id` shadowed across multiple worktrees --
delete removes only the reconciled winner, so a shadowed copy becomes the new winner and the
pipeline re-surfaces on the next render (truthful to disk, re-deletable). The type-to-confirm
modal is worktree-agnostic (keyed only on `work_id`; the JSON envelope carries no `branch_label`).
