# task-018: Change/Refactor family scaffold + alias-equivalence test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-017

**Scope:**
- Fixture: `aid-change-data-model` produces a flattened work with `### Data Model` + `### Migration Plan` activated and `tasks/` `001` MIGRATE (forward+rollback) -> `002` IMPLEMENT (update readers/writers) -> `003` TEST; halts pre-Execute (FR-10).
- Refactor: `aid-refactor` performance mode scaffolds `001` REFACTOR + `002` TEST with a behavior-preservation AC; a rename-mode invocation scaffolds a single REFACTOR task (proves `aid-refactor` stays bare + behavior-preserving).
- Alias: `aid-update-api` produces the same shape as `aid-change-api`.

**Acceptance Criteria:**
- [ ] change-data-model -> MIGRATE + IMPLEMENT + TEST; refactor performance -> REFACTOR + TEST, rename -> single REFACTOR; all halt pre-Execute.
- [ ] `aid-refactor` stays bare + behavior-preserving (AC-4); `aid-update-api` equals `aid-change-api` shape (AC-1).
- [ ] Test is deterministic with clean setup/teardown; covers feature-007 ACs.
- [ ] All §6 quality gates pass.
