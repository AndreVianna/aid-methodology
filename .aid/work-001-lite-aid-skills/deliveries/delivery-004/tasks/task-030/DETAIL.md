# task-030: Recipe subsystem removal + reference scrub

**Type:** REFACTOR

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-029, task-027

**Scope:**
- Delete: `canonical/aid/recipes/` (51 `.md`), `canonical/aid/scripts/interview/parse-recipe.sh`, `canonical/aid/templates/recipe-template.md`, `canonical/aid/templates/specs/lite-spec-template.md`, and the 7 aid-describe lite/triage refs (`state-triage.md`, `state-condensed-intake.md`, `state-task-breakdown.md`, `state-lite-review.md`, `state-lite-done.md`, `recipe-to-lite-escalation.md`, `lite-to-full-escalation.md`).
- Scrub canonical references: `canonical/aid/templates/work-state-template.md` (remove the `## Triage` + `## Escalation Carry` blocks + the AUTHORED-zone note; coordinate with feature-001's delivery-block addition in task-001); `canonical/aid/scripts/execute/complexity-score.sh` (retire the flat `- Type:` recipe branch + drop the `recipes/*.md` comment); `canonical/aid/scripts/execute/compute-block-radius.sh` (reword "lite/recipe SPEC" -> "flattened single-delivery SPEC"); `canonical/agents/aid-reviewer/AGENT.md` (drop `recipes/` from the dir list); `canonical/EMISSION-MANIFEST.md` (remove the Recipes asset-kind section/row/example); `canonical/skills/aid-discover/references/state-generate.md` (reword the `state-triage.md` citation).
- Retire the dead recipe test harness so the suite stays green: delete `tests/canonical/test-parse-recipe.sh`, de-register it in `tests/README.md`, re-point the 4 recipe fixtures in `tests/canonical/test-multitool-isolation.sh` to surviving passthrough assets, update the `{scripts,templates,recipes}` comment in `tests/canonical/test-install.sh`.
- Deletion flows through the emission-manifest pure-mirror-deletion boundary (C-4).

**Acceptance Criteria:**
- [ ] `canonical/aid/recipes/` deleted; `parse-recipe.sh` + `recipe-template.md` + `lite-spec-template.md` + the 7 aid-describe lite/triage refs deleted (AC-5/FR-14).
- [ ] The 6 canonical reference surfaces scrubbed; work-state-template Triage/Escalation blocks removed.
- [ ] Recipe test harness retired: `test-parse-recipe.sh` deleted + de-registered; `test-multitool-isolation.sh` re-pointed; `test-install.sh` comment updated.
- [ ] All tests pass before AND after (`tests/run-all.sh` green); no behavior change to the surviving full path (the consumer was removed by feature-013/task-029).
- [ ] Mirror-deletion: no recipes in the 5 profiles/dogfood after `run_generator.py`; `render-drift` green.
- [ ] All §6 quality gates pass.
