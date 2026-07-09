# task-006: Executor-graph flattened-PLAN parse test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-001

**Scope:**
- Add a canonical test with a flattened `PLAN.md` fixture (top-level `## Execution Graph`; `### Task Dependencies` + `### Can Be Done In Parallel`; zero `### delivery-` headings).
- Assert `compute-block-radius.sh --plan-file <fixture> --failed-task <id>` (the required `--failed-task` arg) and `complexity-score.sh --plan-file <fixture>` parse the top-level graph with NO `--delivery-id` and return the expected radius/score (the scripts already support the shape; the fixture locks it in).

**Acceptance Criteria:**
- [ ] Both scripts parse the flattened top-level graph without `--delivery-id` and return expected values.
- [ ] Fixture carries zero `### delivery-` headings (keeps the no-`--delivery-id` path).
- [ ] Test is deterministic with clean setup/teardown.
- [ ] Covers feature-001's executor-graph strategy (AC-8 executor half).
- [ ] All §6 quality gates pass.
