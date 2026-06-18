# task-008: aid-interview lite path — scaffold work folder per uniform pattern

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-005, task-006

**Scope:**
- Update the `canonical/skills/aid-interview/` lite path so a new lite-path work is scaffolded per the uniform pattern: work folder with `SPEC.md` (lite definition) + `STATE.md` (work header + Pipeline State + Triage + derived views, from the task-001 work-level template). The lite path uses `delivery-001`; ensure the lite SPEC's `## Tasks` note and `**Source:**` line reference `delivery-001` and the nested task path.
- Use the renamed "state" section names from task-001 in the seeded STATE.md.
- Confirm coexistence: scaffolding produces the hierarchy for NEW works; nothing migrates existing works (SD-6).
- Regenerate profile copies via the full generator. ASCII-only.

**Acceptance Criteria:**
- [ ] A new lite-path work is scaffolded as a folder with `SPEC.md` + `STATE.md`; the STATE.md uses the work-level template with "state" naming and derived views.
- [ ] The lite SPEC references `delivery-001` and the nested task path; aid-detail/aid-plan can build on it.
- [ ] No existing-work migration is triggered by interview scaffolding.
- [ ] Skill + profile copies regenerated (full generator); render-drift clean; ASCII-only.
- [ ] All §6 quality gates pass.
