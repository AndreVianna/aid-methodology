# task-005: aid-detail — create task folders (SPEC.md + STATE.md) under delivery

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Update `canonical/skills/aid-detail/` (SKILL.md + references) so task creation produces the hierarchy: for each task, create `delivery-NNN/tasks/task-NNN/SPEC.md` (the former flat `tasks/task-NNN.md` definition, 6-section schema) + `delivery-NNN/tasks/task-NNN/STATE.md` (seeded from the task `STATE.md` template: State=Pending, empty Review/Elapsed/Notes).
- Update the FIRST-RUN/REVIEW state detection (`SKILL.md:41-42`: `tasks/` empty vs has files) to detect the new nested path.
- Update `references/reviewer-brief.md:61` and `references/review.md:40` whole-list scope globs from `.aid/{work}/tasks/task-*.md` to the new `delivery-NNN/tasks/task-NNN/SPEC.md` path.
- The work `STATE.md` `## Tasks State` view is DERIVED — aid-detail does NOT write task rows into the work STATE.md (parents derive).
- Regenerate profile copies of the skill via the full generator. ASCII-only.

**Acceptance Criteria:**
- [ ] aid-detail creates `delivery-NNN/tasks/task-NNN/{SPEC.md,STATE.md}` per task; task SPEC.md keeps the 6-section schema; task STATE.md seeds State=Pending.
- [ ] FIRST-RUN/REVIEW detection and the reviewer-brief/review globs reference the new nested path.
- [ ] aid-detail does not write task rows into the work `STATE.md` (derived view).
- [ ] Skill + profile copies regenerated (full generator); render-drift clean; ASCII-only.
- [ ] All §6 quality gates pass.
