# task-001: M0 doc-reconcile — IMPEDIMENT path + Calibration Log/Dispatches schema (KI-001/KI-002)

**Type:** REFACTOR

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** —

**Scope:**
- Reconcile docs only — no behavior change (feature-001 §4 increment M0).
- Fix KI-002: change the IMPEDIMENT path in `.aid/knowledge/schemas.md §13` (currently `.aid/{work}/task-NNN/IMPEDIMENT.md`) to the producer's de-facto flat path `.aid/{work}/IMPEDIMENT-task-NNN.md` (matches `canonical/skills/aid-execute/references/state-execute.md:322,368` + `pipeline-contracts.md ### IMPEDIMENT-task-NNN.md Contract`).
- Fix KI-001: declare the `## Calibration Log` section and the task `## Dispatches` sub-column in `canonical/templates/work-state-template.md` so the producer-written sections (`aid-discover/SKILL.md:103,105`, `aid-monitor/SKILL.md:162-164`, `aid-housekeep/SKILL.md:89`, `aid-execute`) have a template home; reconcile with `pipeline-contracts.md` which already lists `## Calibration Log` as required.
- Re-run the FULL `run_generator.py` (template is a rendered artifact) so all five install trees + the `.claude/` dogfood stay byte-identical.

**Acceptance Criteria:**
- [ ] `schemas.md §13` declares exactly one canonical IMPEDIMENT path: the flat `.aid/{work}/IMPEDIMENT-task-NNN.md`, agreeing with the producer and `pipeline-contracts.md` (KI-002 closed on the doc side).
- [ ] `work-state-template.md` declares `## Calibration Log` + the task `## Dispatches` sub-column, eliminating the schema-orphan drift (KI-001 closed); `pipeline-contracts.md` and the template agree.
- [ ] FULL `python3 .claude/skills/aid-generate/scripts/run_generator.py` re-run; no render-drift; `verify_deterministic.py` exits 0; KB-hygiene CI passes.
- [ ] No producer behavior change — no skill/agent body altered beyond doc/template text; no test-observable output changes.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] **C4 behavior preservation:** tests pass before and after; no observable pipeline behavior change (phases/gates/outputs/decisions) — render-drift + FULL `run_generator.py` + `tests/run-all.sh` + Windows installer suite stay green.
