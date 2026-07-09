# task-031: Broadened no-dangling + mirror-deletion guard test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-030, task-029

**Scope:**
- Author/broaden the no-dangling grep test to cover ALL of `canonical/` (not just skills/scripts/templates): no surviving file references `recipes/`, `parse-recipe`, the `## Triage` STATE block, the `## Escalation Carry` block, or the filename of any of the 7 deleted aid-describe reference docs. (Scope is intentionally all of `canonical/` because the dangling `state-triage.md` cite lived in `aid-discover/references/state-generate.md`, which a narrower scope missed.)
- Mirror-deletion assertion: after `run_generator.py`, none of the 5 profiles nor the dogfood `.claude/` contains `aid/recipes/`, `aid/scripts/interview/parse-recipe.sh`, `recipe-template.md`, or `specs/lite-spec-template.md`; `render-drift` green; dogfood byte-identical.

**Acceptance Criteria:**
- [ ] No-dangling grep over all of `canonical/` is green (catches the `aid-discover/state-generate.md` class) (AC-5).
- [ ] Mirror-deletion: recipe assets absent from all 5 profiles + dogfood; `render-drift` green.
- [ ] `tests/run-all.sh` green.
- [ ] Test is deterministic with clean setup/teardown; covers feature-002 AC-5/C-4.
- [ ] All §6 quality gates pass.
