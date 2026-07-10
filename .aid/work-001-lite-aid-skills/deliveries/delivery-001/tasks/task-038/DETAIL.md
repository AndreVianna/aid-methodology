# task-038: aid-detail writes deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-036

**Scope:**
- Edit `canonical/skills/aid-detail/SKILL.md`: the State Detection rules (`No delivery-NNN/tasks/task-NNN/SPEC.md -> FIRST-RUN`; `At least one … SPEC.md -> REVIEW`) -> `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; the `--reset` `argument-hint` (`clear delivery-NNN/tasks/`) -> `deliveries/delivery-NNN/tasks/`.
- Edit `canonical/skills/aid-detail/references/first-run.md`: the task-def write path `delivery-NNN/tasks/task-NNN/SPEC.md` -> `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; repoint the task template to `task-detail-template.md`.
- Edit `canonical/skills/aid-detail/references/task-decomposition.md`: same task-def path switch + template repoint.
- Edit `canonical/skills/aid-detail/references/review.md`: the task-def read path -> `.../DETAIL.md` under `deliveries/`.
- Edit `canonical/skills/aid-detail/references/reviewer-brief.md`: the task-def path in the reviewer brief -> `.../DETAIL.md` under `deliveries/`.
- A-10 clean switch: no surviving `task-spec-template.md` reference and no task `SPEC.md` write path in any aid-detail file.

**Acceptance Criteria:**
- [ ] aid-detail writes task definitions to `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` — SKILL.md State Detection + the `--reset` argument-hint repointed (AC-16 / FR-16).
- [ ] `first-run.md` + `task-decomposition.md` reference `task-detail-template.md` (not `task-spec-template.md`) and write `.../DETAIL.md`; `review.md` + `reviewer-brief.md` read task defs from `.../DETAIL.md` under `deliveries/`.
- [ ] No surviving task `SPEC.md` or `task-spec-template.md` reference in any aid-detail file (grep; A-10 clean switch).
- [ ] `aid-detail` re-reviewed >= A+ (AC-7 subset); renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
