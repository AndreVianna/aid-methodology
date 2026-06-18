# task-015: Cross-cutting — disjoint-merge proof, parity, render-drift, run-all green

**Type:** TEST

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-004, task-007, task-008, task-012, task-013, task-014

**Scope:**
- Prove the disjoint-write property end-to-end: a fixture with two delivery branches each writing only their own task/delivery `STATE.md` — INCLUDING each branch's own delivery gate block AND its own `## Cross-phase Q&A` entries (the formerly-shared work-level section) — merged back, produces ZERO conflict on state files (AC-Disjoint). A scripted test creating the branches + merging is acceptable; keep it HOME/sandbox-pinned.
- Confirm Node↔Python reader parity on the full new fixture set (AC-Parity).
- Confirm render-drift is clean via the FULL generator `run_generator.py` (skill + writeback-state.sh copies + templates) — not per-script renderers.
- Confirm shipped scripts (writeback-state.sh copies, migration helper) are ASCII-only.
- Run the full `tests/run-all.sh` (HOME-pinned) green; ensure Windows-only installer/CLI tests are updated if any CLI path changed (likely none here, but verify).
- This is the final gate task; it does not introduce new product behavior.

**Acceptance Criteria:**
- [ ] A two-branch fixture (each branch with its own delivery gate + `## Cross-phase Q&A`) merges back with zero conflict on `STATE.md` files (disjoint-write property proven, incl. the formerly-shared Q&A section).
- [ ] Node↔Python reader parity passes on all new fixtures.
- [ ] Render-drift is clean via the full generator; all shipped scripts ASCII-only.
- [ ] `tests/run-all.sh` is green (HOME-pinned); any affected Windows test updated.
- [ ] All §6 quality gates pass.
