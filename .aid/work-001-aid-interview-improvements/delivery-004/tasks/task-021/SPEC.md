# task-021: Marker fixture-through-three-scripts test + brownfield-intact regression

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** task-019, task-020

**Scope:**
- Verify the `source: forward-authored` marker end-to-end through the three KB-authoring scripts using a
  fixture seed doc (DoD D1), AND confirm the three scripts are byte-behaviorally unchanged for
  hand-authored/generated docs (DoD D6). Add the test as a deterministic canonical bash suite
  (e.g. `tests/canonical/test-kb-forward-authored-marker.sh`) and wire it into `tests/run-all.sh`.
- **Fixture:** a minimal forward-authored seed doc (`source: forward-authored`, `kb-category: primary`,
  full f001 frontmatter incl. `objective:`/`summary:`/`sources:`, an `approved_at_commit:`) under a
  throwaway KB root, plus a tracked source file listed in its `sources:` that is committed AFTER the
  doc's `approved_at_commit` (so a hand-authored doc with the same setup WOULD read `suspect`).
- **Freshness (task-019):** `kb-freshness-check.sh --doc <fixture>` returns verdict `current` with
  `n_current=n_suspect=n_unknown=0` and the design-authoritative reason, in BOTH `--format tsv` (7-column
  row asserted) and `--format text`; a hand-authored control doc with the identical drifted source reads
  `suspect` (proving the short-circuit is what folds it to `current`, not a degenerate setup). HOME-pinned;
  use an isolated throwaway git repo/`HOME` per the scan-tests-must-pin-HOME rule.
- **Lint (task-020):** `lint-frontmatter.sh --root <fixture-root>` puts the forward-authored doc IN SCOPE
  and full-lints it (no skip) -- it PASSES with complete frontmatter and FAILS with `[FM-MISSING]` when a
  required field is removed (proving it is linted, not skipped).
- **Index (task-020):** `build-kb-index.sh` renders the forward-authored `kb-category: primary` doc in the
  Primary table identically to a hand-authored peer (same 6 columns; row present).
- **Brownfield-intact (D6):** run the EXISTING freshness/lint/index canonical suites (whatever
  `tests/canonical/` currently covers for these three scripts) and confirm they still pass unchanged.
- Record results to this task's STATE.md; file any [HIGH]/[CRITICAL] findings per the ledger schema.
- **Out of scope:** the greenfield-mode review gate / coherence / sufficiency verification (task-027); the
  generator render (task-026); fixing script defects (loop back to task-019/020).

**Acceptance Criteria:**
- [ ] The fixture forward-authored doc folds to `current` (0/0/0 + reason) in both tsv and text; an identically-drifted hand-authored control reads `suspect`. *(DoD D1; gate criterion 2)*
- [ ] `lint-frontmatter.sh` full-lints the forward-authored doc (in scope, no skip): passes complete, emits `[FM-MISSING]` when a required field is dropped. *(DoD D1)*
- [ ] `build-kb-index.sh` renders the forward-authored primary doc in the Primary table with the unchanged 6-column schema. *(DoD D1)*
- [ ] The existing freshness/lint/index canonical suites still pass unchanged (brownfield/hand-authored behavior intact). *(NFR-2, DoD D6; gate criterion 2)*
- [ ] Tests are deterministic with clean setup/teardown, HOME-pinned to a throwaway repo (no real-repo scan); the new suite is wired into `tests/run-all.sh`; all DoD-D1/D6 acceptance criteria from feature-003 are covered. *(TEST defaults)*
- [ ] All REQUIREMENTS.md §6 quality gates pass.
