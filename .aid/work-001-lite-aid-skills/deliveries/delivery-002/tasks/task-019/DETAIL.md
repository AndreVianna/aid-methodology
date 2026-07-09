# task-019: Test+Experiment family -- catalog rows + test-experiment.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-008, task-009

**Scope:**
- Add 5 rows to `canonical/aid/templates/shortcut-catalog.yml` (no aliases): `aid-test` (bare, TEST), `aid-test-security`, `aid-test-performance`, `aid-test-data-quality` (TEST), `aid-experiment` (bare, RESEARCH).
- Create `canonical/aid/templates/shortcut-scaffolding/test-experiment.md`: per-skill SPEC activation + minimal CAPTURE + task templates -- `aid-test` functional mode (single TEST tracing each test to an AC) and model-eval mode (TEST running the eval harness against the eval-dataset, asserting metric meets threshold); `aid-test-security` (TEST SAST/DAST/fuzz/audit; findings route to `aid-fix`); `aid-test-performance` (TEST benchmark/load/stress vs threshold); `aid-test-data-quality` (TEST schema/freshness/completeness/uniqueness); `aid-experiment` (`001` RESEARCH design + optional `002` IMPLEMENT variants + `003` RESEARCH analysis/recommendation).
- Generate the 5 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 5 rows/dirs added (test + 3 kinds + experiment); `test`/`test-*` -> TEST, `experiment` -> RESEARCH (AC-1 G7 subset).
- [ ] `test-experiment.md` covers functional + model-eval modes, the 3 test-kinds (findings route to `aid-fix`), and the experiment RESEARCH chain.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
