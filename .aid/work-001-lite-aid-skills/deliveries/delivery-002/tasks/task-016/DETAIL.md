# task-016: Create family scaffold + alias-equivalence test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-015

**Scope:**
- Fixture: `aid-create-api "orders resource"` produces a flattened Lite work whose `SPEC.md` has `### API Contracts` activated and whose `tasks/` are `001` IMPLEMENT (schema) -> `002` IMPLEMENT (handler+persistence) -> `003` TEST (integration), with the `## Execution Graph` carrying that chain; halts pre-Execute (FR-10).
- Second fixture: `aid-create-data-model` asserts a `MIGRATE`-typed `task-001` (the feature-003 reclassification).
- Alias equivalence: `aid-add-api` scaffolds the byte-identical work shape as `aid-create-api`.

**Acceptance Criteria:**
- [ ] create-api -> IMPLEMENT/IMPLEMENT/TEST chain + `### API Contracts`; create-data-model -> MIGRATE `task-001`; both halt pre-Execute.
- [ ] `aid-add-api` produces the byte-identical work shape as `aid-create-api` (alias resolution, AC-1).
- [ ] Test is deterministic with clean setup/teardown; covers feature-006 ACs.
- [ ] All §6 quality gates pass.
