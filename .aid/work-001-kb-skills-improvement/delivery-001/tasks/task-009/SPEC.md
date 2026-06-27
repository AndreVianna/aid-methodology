# task-009: test-closure-check.sh + fixtures (3-output)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-008

**Scope:**
- Author `tests/canonical/test-closure-check.sh` (numbered `C01..C08`, `set -u`, sourced
  `assert.sh`), against small in-suite fixture trees under `tests/canonical/fixtures/` with planted
  `candidate-concepts.md`, spine, KB docs, and KB-doc `sources:` frontmatter (local files + a URL).
  Assertions:
  - C01-C02 output (a) termination: a planted used-but-undefined term is reported; a fully closed
    fixture reports empty (a).
  - C03-C05 output (b) coverage: a candidate present in a doc whose local-file `sources:` contains it
    emits `present`; a candidate ABSENT from a doc anchoring it via local-file `sources:` emits the
    `absent` finding (polarity); a doc whose only relevant `sources:` is a URL yields
    `anchoring-source = N/A` and NO `absent` finding (URL scoping).
  - C06-C07 output (c) transcription: a near-verbatim local-source doc emits a high `overlap-ratio`;
    a URL-only-sourced doc emits `N/A`.
  - C08 determinism: a re-run is byte-identical across all three outputs (NFR-3).
- Auto-discovered by `tests/run-all.sh`'s glob; runs in the `canonical-tests` job.
- Test-split convention (deliberate sizing choice): this suite is SPLIT into its own TEST task
  (separate from the task-008 IMPLEMENT) because it is SUBSTANTIAL -- C01-C08 plus 3-output
  fixtures. Small self-tests (lint -> task-003, teach-back -> task-012) stay bundled in their
  IMPLEMENT task.

**Acceptance Criteria:**
- [ ] `test-closure-check.sh` implements C01-C08 with `set -u` and sourced `assert.sh`,
  auto-discovered by `tests/run-all.sh`.
- [ ] Output (a) termination (present/empty), output (b) coverage (present / `absent` finding /
  URL-N/A), output (c) transcription (high overlap / URL-N/A), and C08 byte-reproducibility are all
  asserted.
- [ ] Fixtures include both local-file and URL `sources:` so the URL-N/A scoping is exercised in
  both (b) and (c).
- [ ] Tests are deterministic with clean setup/teardown; fixtures live under
  `tests/canonical/fixtures/`.
- [ ] All acceptance criteria from feature-004's `closure-check.sh` 3-output contract are covered.
- [ ] All existing tests still pass; all section-6 quality gates pass.
