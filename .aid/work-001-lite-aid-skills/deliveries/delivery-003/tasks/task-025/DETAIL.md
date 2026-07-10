# task-025: Analyze/Report family -- catalog rows + analyze-report.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-008, task-009

**Scope:**
- Add 2 rows to `canonical/aid/templates/shortcut-catalog.yml` (no aliases): `aid-report` (bare, `default_type: RESEARCH`) and `aid-show-dashboard` (bare, `default_type: IMPLEMENT`), group G11. The verb for `aid-show-dashboard` is `show-dashboard` (whole name is the verb; no artifact suffix).
- Create `canonical/aid/templates/shortcut-scaffolding/analyze-report.md`: `aid-report` = `001` RESEARCH (EDA + metrics + >=2 interpretations + recommendation) + optional `002` DOCUMENT (write up); `aid-show-dashboard` = `001` IMPLEMENT (source -> viz -> publish/refresh) + optional `002` TEST (validate data accuracy/refresh), with `### Telemetry & Tracking` + `### UI Specs` activation. Encodes the legacy add-report analytical -> G11 RESEARCH reclassification and the ownership boundary vs `aid-document`/`aid-experiment`/`aid-create-data-pipeline`.
- Generate the 2 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 2 rows/dirs added; `report -> RESEARCH`, `show-dashboard -> IMPLEMENT` (AC-1 G11 subset).
- [ ] `analyze-report.md` defines both task templates + SPEC activation + the ownership boundary.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
