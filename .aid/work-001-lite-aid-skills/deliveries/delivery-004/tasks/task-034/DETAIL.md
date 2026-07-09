# task-034: Deploy/Monitor shortcut mode-branch + repurpose rows (Could)

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-008, task-033

**Scope:**
- Add the invocation-context mode-branch to `canonical/skills/aid-deploy/SKILL.md` (`## Arguments`/`## Pre-flight`) and `canonical/skills/aid-monitor/SKILL.md`: `work-NNN` argument present -> the existing pipeline path runs unchanged (aid-deploy: IDLE->SELECTING->VERIFYING->PACKAGING->DONE; aid-monitor: OBSERVE->CLASSIFY->ROUTE->DONE); no `work-NNN` + free-form description -> the shortcut-scaffold path (bind `VERB=deploy`/`VERB=monitor`, delegate to `canonical/aid/templates/shortcut-engine.md`, scaffold a flattened lite work, run the gates, halt at approval; never executes). The pipeline states + their reference docs are byte-preserved.
- Add the 2 `repurpose: true` catalog rows (`aid-deploy` G9, `aid-monitor` G10) to `canonical/aid/templates/shortcut-catalog.yml` so the parity check + `/aid-triage` recognise them (the build helper already skips repurpose rows; the parity test already exempts them -- built in task-009/task-010).

**Acceptance Criteria:**
- [ ] Mode-branch added to both skills: `work-NNN` present -> pipeline unchanged; description-only -> shortcut-engine scaffold + halt (never executes); pipeline states/reference docs byte-preserved (NFR-7/C-6).
- [ ] 2 `repurpose: true` rows added; the helper skips them; the catalog registers deploy/monitor (enables the full 69-row parity in task-035).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
