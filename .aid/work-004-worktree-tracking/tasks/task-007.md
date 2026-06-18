# task-007: aid-execute — read task SPEC at new path, write task STATE, routing

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-003, task-005, task-006

**Scope:**
- Update `canonical/skills/aid-execute/` to operate on the hierarchy:
  - Primary prompt path (`SKILL.md:128`) `.aid/{work}/tasks/task-NNN.md` → `.aid/{work}/delivery-NNN/tasks/task-NNN/SPEC.md`.
  - STATE-detection routing (`SKILL.md:75,110-120`): read the task's `State` from `delivery-NNN/tasks/task-NNN/STATE.md` (not the work `## Tasks Status` table); map No file / In Progress / In Review+issues / Done to EXECUTE / resume / FIX / RE-RUN.
  - Writes go through `writeback-state.sh --field` (now retargeted to the task STATE.md by task-003).
  - PD-1 ready-set / PD-2 worktree references (`references/state-execute.md:114-120,142,243`): update to read per-task State; reconcile the `.aid/.worktrees/task-NNN/` ephemeral-worktree spec note with the persistent-worktree discovery (clarify these are distinct; the dashboard targets persistent ones per Pillar 4).
  - **Delivery-gate Cross-phase Q&A retarget (fixes the cross-branch hazard).** `references/state-delivery-gate.md:278` currently writes SPEC Q&A to the SHARED work `STATE.md` `## Cross-phase Q&A` from a delivery branch (two delivery branches → conflict). Retarget it to the delivery's OWN `delivery-NNN/STATE.md` `## Cross-phase Q&A` (one writer per branch, per SD-5). KB Q&A (`:280`, → `.aid/knowledge/STATE.md`) is unchanged. The work-level `## Cross-phase Q&A` view is then DERIVED at read time (reader tasks 009/012).
  - **Advance the delivery's INDEPENDENT lifecycle (SD-8).** aid-execute writes the delivery-state enum into `delivery-NNN/STATE.md`: `Executing` when the delivery's tasks start, `Gated` when the delivery gate runs, `Done` on gate pass, `Blocked` on impediment. This is authored delivery state, distinct from the per-task rollup (a delivery in `Executing` may have tasks in mixed states; a sibling delivery may remain `Pending-Spec` with zero tasks).
- Regenerate profile copies via the full generator. ASCII-only.

**Acceptance Criteria:**
- [ ] aid-execute reads the task definition from `delivery-NNN/tasks/task-NNN/SPEC.md` and the task State from the sibling `STATE.md`.
- [ ] STATE-detection routing (EXECUTE/resume/FIX/RE-RUN) is driven by the per-task `State` field; writes route through the retargeted `writeback-state.sh`.
- [ ] The PD-1 ready-set and PD-2 worktree references are updated/clarified for the new layout.
- [ ] The delivery gate writes SPEC Q&A to `delivery-NNN/STATE.md` `## Cross-phase Q&A` (not the shared work STATE.md); KB Q&A unchanged. aid-execute advances the delivery lifecycle enum (`Executing`/`Gated`/`Done`/`Blocked`) in `delivery-NNN/STATE.md`.
- [ ] Skill + profile copies regenerated (full generator); render-drift clean; ASCII-only.
- [ ] All §6 quality gates pass.
