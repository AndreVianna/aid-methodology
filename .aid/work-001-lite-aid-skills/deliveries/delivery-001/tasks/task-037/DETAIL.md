# task-037: aid-plan writes deliveries/delivery-NNN/BLUEPRINT.md

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-036

**Scope:**
- Edit `canonical/skills/aid-plan/SKILL.md`: the Workspace diagram (`delivery-NNN/` -> `deliveries/delivery-NNN/`; its `SPEC.md <- OUTPUT: delivery definition (scope, gate criteria, tasks, dependencies)` line -> `BLUEPRINT.md`); the State Detection `DONE` rule (`delivery-NNN/SPEC.md` + `delivery-NNN/STATE.md` -> `deliveries/delivery-NNN/BLUEPRINT.md` + `.../STATE.md`); the `### 2. .aid/{work}/delivery-NNN/SPEC.md (delivery definition)` output section -> `deliveries/delivery-NNN/BLUEPRINT.md`; the completion checklist (`delivery-NNN/SPEC.md written for every delivery`) -> `BLUEPRINT.md`. Leave the `features/*/SPEC.md` scan (Check 2) UNCHANGED — that is the **feature** spec.
- Edit `canonical/skills/aid-plan/references/first-run-loop.md`: repoint the `delivery-spec-template.md` reference to `delivery-blueprint-template.md`; the `delivery-NNN/SPEC.md` write paths -> `deliveries/delivery-NNN/BLUEPRINT.md`.
- Edit `canonical/skills/aid-plan/references/review-deliverables.md`: `delivery-NNN/` path references -> `deliveries/delivery-NNN/`; delivery-def reads -> `BLUEPRINT.md`.
- A-10 clean switch: no surviving `delivery-NNN/SPEC.md` (old-nested) write path in any aid-plan file.

**Acceptance Criteria:**
- [ ] aid-plan writes the delivery definition to `deliveries/delivery-NNN/BLUEPRINT.md` — SKILL.md Workspace diagram, State-Detection `DONE` rule, the `### 2 …` output section, and the completion checklist are all repointed (AC-16 structure half / FR-16).
- [ ] `first-run-loop.md` references `delivery-blueprint-template.md` (not `delivery-spec-template.md`) and writes `deliveries/delivery-NNN/BLUEPRINT.md`; `review-deliverables.md` reads the delivery def from `deliveries/delivery-NNN/BLUEPRINT.md`.
- [ ] The `features/*/SPEC.md` feature-spec scan (Check 2) is unchanged.
- [ ] No surviving `delivery-NNN/SPEC.md` or `delivery-spec-template.md` reference in any aid-plan file (grep; A-10).
- [ ] `aid-plan` re-reviewed >= A+ (AC-7 subset); renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
