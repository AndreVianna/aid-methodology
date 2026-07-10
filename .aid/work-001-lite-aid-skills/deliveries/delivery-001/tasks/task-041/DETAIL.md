# task-041: Switch the canonical + reader tests to the new full-path layout

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-037, task-038, task-039, task-040

**Scope:**
- Switch the named canonical tests to the new layout (A-10 clean switch — no mixed-vintage fixture):
  - `tests/canonical/test-work-state-template.sh`: assertions referencing `delivery-spec-template.md` / `task-spec-template.md` -> `delivery-blueprint-template.md` / `task-detail-template.md`.
  - `tests/canonical/test-writeback-state.sh`: fixture `delivery-NNN/…` paths -> `deliveries/delivery-NNN/…`; delivery-def / task-def filenames -> `BLUEPRINT.md` / `DETAIL.md`.
  - `tests/canonical/test-delivery-gate-aggregate.sh`: same fixture path/name switch; assert the gate reads its criteria from `BLUEPRINT.md § Gate Criteria`.
  - `tests/canonical/test-disjoint-merge.sh`: fixture `delivery-NNN/…/SPEC.md` -> `deliveries/delivery-NNN/…/DETAIL.md`.
  - `tests/canonical/test-actback-fixtures.sh`: same fixture path/name switch.
- Switch the reader tests: `dashboard/reader/tests/test_fixtures.py`, `test_reader.py`, `test_task014_fixtures.py`, and `dashboard/server/tests/test_server_node.mjs` (+ its `fixtures/`) -> hierarchical fixtures on `deliveries/…/{BLUEPRINT,DETAIL}.md`; NO mixed-vintage old-nested fixture (A-10). (The short/flat `work-006-lite-sample` Node fixture is feature-001's — not touched here.)
- Add the AC-15/AC-16 structure assertions: a planned -> detailed work produces `deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`; a no-dangling grep asserts no `delivery-NNN/SPEC.md`, task `SPEC.md`, `delivery-spec-template.md`, or `task-spec-template.md` survives in the full-path files (scope excludes the `aid-describe` lite refs, which are feature-002/013's).
- SCOPE JUDGMENT — `tests/canonical/test-migrate-hierarchy.sh` (+ `tests/canonical/fixtures/migrate/…/work-999-migration-test/`): repoint its hierarchical **target** to `deliveries/…/{BLUEPRINT,DETAIL}.md` (this exercises the pre-existing monolithic -> hierarchical migration, which is distinct from the A-10-forbidden pre-rename -> post-rename migration). Whether the monolithic -> hierarchical capability itself survives A-10 is an OPEN owner decision (tracked in the amendment design-judgment flag); if the owner retires it, drop this test instead of repointing — do not build it out further here.

**Acceptance Criteria:**
- [ ] The named canonical tests (`test-work-state-template.sh`, `test-writeback-state.sh`, `test-delivery-gate-aggregate.sh`, `test-disjoint-merge.sh`, `test-actback-fixtures.sh`) assert the renamed template names + `deliveries/…/{BLUEPRINT,DETAIL}.md` fixtures; the gate-aggregate test asserts criteria are read from `BLUEPRINT.md § Gate Criteria` (AC-16).
- [ ] The reader tests (`test_fixtures.py`, `test_reader.py`, `test_task014_fixtures.py`, `test_server_node.mjs` + fixtures) use hierarchical fixtures on the new paths; no mixed-vintage old-nested fixture (A-10); reader parity holds (both twins read one new-layout fixture identically).
- [ ] A structure test asserts a produced full-path work is `deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`; a no-dangling grep finds no `delivery-NNN/SPEC.md`, task `SPEC.md`, `delivery-spec-template.md`, or `task-spec-template.md` in the full-path files (AC-15 / A-10).
- [ ] `test-migrate-hierarchy.sh` hierarchical target is repointed to `deliveries/…/{BLUEPRINT,DETAIL}.md` (or the test is retired per the open owner decision on the monolithic -> hierarchical capability — not resolved in this task).
- [ ] All existing tests still pass (`tests/run-all.sh` green); `render-drift` green.
- [ ] All §6 quality gates pass.
