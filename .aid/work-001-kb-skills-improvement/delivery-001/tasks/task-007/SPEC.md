# task-007: test-harvest-coined-terms.sh + fixtures (planted 'Relative bus')

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-006

**Scope:**
- Author `tests/canonical/test-harvest-coined-terms.sh` (numbered `T01..T10`, `set -u`, sourced
  `assert.sh`, pattern mirroring `test-doc-set-mapping.sh`), with small in-suite fixture trees under
  `tests/canonical/fixtures/`. Assertions:
  - T01-T03 denylist filter: `UserService` dropped; `RelativeBus` survives; an all-common-word
    phrase `Relative Bus` recurring cross-source survives (phrase-survival rule).
  - T04-T06 ranking: a cross-source term outranks a same-frequency single-channel term; spread>=3
    candidates are never truncated by `--top`; a re-run is byte-identical (NFR-3 determinism).
  - T07-T08 channels: a commit-only term (history channel) is captured; a non-git fixture yields an
    empty history channel without error.
  - T09 the PLANTED cross-source 'Relative bus' fixture (a coined phrase across code+docs+comments)
    surfaces in the top rows -- the AC2 mechanical half (the full end-to-end capture-and-define is
    delivery-005).
  - T10 output shape: the emitted markdown has the documented columns and parses.
- Auto-discovered by `tests/run-all.sh`'s glob; runs in the `canonical-tests` job.
- Test-split convention (deliberate sizing choice): this suite is SPLIT into its own TEST task
  (separate from the task-006 IMPLEMENT) because it is SUBSTANTIAL -- T01-T10 plus fixture trees.
  Small self-tests (lint -> task-003, teach-back -> task-012) stay bundled in their IMPLEMENT task.

**Acceptance Criteria:**
- [ ] `test-harvest-coined-terms.sh` implements T01-T10 with `set -u` and sourced `assert.sh`,
  auto-discovered by `tests/run-all.sh`.
- [ ] The planted cross-source 'Relative bus' fixture (code+docs+comments) is asserted to surface in
  the harvest top rows (AC2 mechanical half).
- [ ] Denylist (T01-T03), ranking + byte-reproducibility (T04-T06), channel behavior incl. non-git
  empty-history (T07-T08), and output shape (T10) are all asserted.
- [ ] Tests are deterministic with clean setup/teardown; fixtures live under
  `tests/canonical/fixtures/`.
- [ ] All acceptance criteria from feature-004's harvest half are covered by the suite.
- [ ] All existing tests still pass; all section-6 quality gates pass.
