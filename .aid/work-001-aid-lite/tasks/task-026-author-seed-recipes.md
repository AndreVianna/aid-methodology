# task-026: Author 5 seed recipes

**Type:** DOCUMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** task-025

**Scope:**
- Author `canonical/recipes/bug-fix.md` (applies-to: bug-fix; 4 slots; 1 task) — slots: bug-title, bug-description-one-sentence, reproduction-steps, intended-behavior; task: Apply the fix + unit test.
- Author `canonical/recipes/method-refactor.md` (applies-to: small-refactor; 5 slots; 1 task) — slots: class-name, method-name, before-shape, after-shape, refactor-rationale; task: Apply the refactor + update/add tests.
- Author `canonical/recipes/add-crud-endpoint.md` (applies-to: small-new-feature; 6 slots; 3 tasks) — slots: resource-name, endpoint-path, request-schema, response-schema, persistence-layer-notes, security-notes; tasks: Define schema/migration · Implement handler/persistence · Integration tests.
- Author `canonical/recipes/write-release-note.md` (applies-to: single-doc; 4 slots; 1 task) — slots: release-version, headline-changes, breaking-changes, upgrade-notes; task: Draft + edit release-notes-{version}.md.
- Author `canonical/recipes/add-unit-test.md` (applies-to: *; 4 slots; 1 task) — slots: target-class, target-method, behavior-under-test, test-framework; task: Write the test + verify pre-fix-fail (if any).

**Acceptance Criteria:**
- [ ] All 5 recipe files exist under `canonical/recipes/` with the names above.
- [ ] Each has correct YAML front-matter matching the seed-catalog shapes table in feature-011 SPEC.
- [ ] Each body has both `## spec` and `## tasks` blocks with the documented slot tokens.
- [ ] Slot count in each YAML matches actual slot tokens in body (parse-recipe.sh validation passes when shipped in task-027).
- [ ] `add-unit-test` is the only recipe with `applies-to: *` in the seed catalog.
- [ ] Accuracy verified against feature-011 SPEC's seed-catalog table.
- [ ] All §6 quality gates pass.
