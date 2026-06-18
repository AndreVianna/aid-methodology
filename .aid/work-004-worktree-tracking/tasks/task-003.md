# task-003: writeback-state.sh canonical — retarget to per-unit STATE; state naming

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001

**Scope:**
- Retarget `canonical/scripts/execute/writeback-state.sh` write modes to per-unit `STATE.md` files (Pillar 2):
  - `--task-id NNN --field FIELD --value VALUE` → write the named field (State/Review/Elapsed/Notes) into `delivery-NNN/tasks/task-NNN/STATE.md` (a one-writer-per-branch file), NOT a row in the work `STATE.md` table. Resolve the delivery from the task's Source or a `--delivery-id` argument; keep the field name "State" (was "Status") and the closed enum validation.
  - `--task-id NNN --findings BLOCK` → write the `### task-NNN` Quick Check Findings block into the task's `STATE.md`.
  - `--delivery-id NNN --block MARKDOWN_BLOCK` (gate) → write into `delivery-NNN/STATE.md` (SD-5), not the shared work file.
  - `--pipeline --field ...` → continues to target the work `STATE.md` header `## Pipeline State` (rename from `## Pipeline Status`); single writer (work active branch).
  - `--delivery-id NNN --append-issue ROW` → unchanged (already disjoint).
- Rename the affected section/field strings to "state" (`## Pipeline State`, field "State") consistent with task-001; keep enum values.
- Preserve the sentinel-lock, the `|`/newline rejection, the empty-output/sanity guards, and exit-code contract. Keep ASCII-only. **Lock scope note:** the existing lock is work-level (`LOCK_DIR` defaults to `.aid/work`, `writeback-state.sh:60,156`). Under disjoint per-task writes the cross-task lock is mostly moot (one writer per branch), but the lock still serializes the intra-branch parallel task pool, so it is preserved. Where practical, scope the lock to follow the per-unit write target (per-task/per-delivery `STATE.md`) rather than the work dir; this is a clarity refinement, not a correctness blocker.
- Add path-resolution that tolerates the new per-unit layout and is overridable via the existing `AID_*` env vars (extend with `AID_DELIVERY_DIR`/task-path vars as needed for testability).
- Do NOT touch the profile copies here (task-004 propagates).

**Acceptance Criteria:**
- [ ] `--field` writes State/Review/Elapsed/Notes into `delivery-NNN/tasks/task-NNN/STATE.md`; the work `STATE.md` is not modified by this mode.
- [ ] `--findings` writes the per-task block into the task `STATE.md`; `--block` writes the gate into `delivery-NNN/STATE.md`; `--pipeline` updates the work `## Pipeline State` header.
- [ ] Field/section names use "state"; closed enum validation and values preserved; lock, pipe/newline rejection, sanity guards, and exit codes preserved.
- [ ] Script is ASCII-only; `bash -n` clean.
- [ ] All §6 quality gates pass.
