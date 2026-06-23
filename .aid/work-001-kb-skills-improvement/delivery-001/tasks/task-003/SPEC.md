# task-003: lint-frontmatter.sh (deterministic, soft-skip) + canonical test

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-002

**Scope:**
- Author the new `canonical/aid/scripts/kb/lint-frontmatter.sh`: a deterministic (no LLM)
  presence + shape check over `.aid/knowledge/`. For each `source: hand-authored` primary/extension
  doc, require non-empty `objective:`/`summary:` and a well-formed `sources:` (YAML list; each entry
  a path/glob/URL shape, not a free sentence); optional fields, if present, are well-shaped;
  `approved_at_commit:`, if present, is 7-40 lowercase hex. Emit the EXISTING rubric tags
  `[FM-MISSING]` (absent required field) / `[FM-INVALID]` (malformed shape/value) -- no new tag.
  Day-one SOFT-SKIP: skip any doc carrying NONE of the new fields (pre-migration); skip `meta` and
  `source: generated` docs. Path resolution is NOT checked (that is f007); prose quality is exempt.
- Add `lint-frontmatter.sh` AND the existing `build-kb-index.sh` to the
  `tests/canonical/test-ascii-only.sh` allow-list (resolves the SPIKE C2 gap that `build-kb-index.sh`
  is not currently covered; confirm both are already ASCII so adding them does not newly fail CI).
- Wire `lint-frontmatter.sh` into the `kb-hygiene` CI job (`.github/workflows/test.yml`) as a step
  over `.aid/knowledge/` -- stays green on day one because all of AID's un-migrated docs soft-skip.
- Author `tests/canonical/test-frontmatter-lint.sh`: assert each failure class
  (missing required field, malformed `sources:`, bad `approved_at_commit:`) is flagged and a
  well-formed fixture passes; auto-discovered by `tests/run-all.sh`.
- Test-split convention (deliberate sizing choice): a canonical test is BUNDLED into its IMPLEMENT
  task when SMALL (single-script + a few assertions -- e.g. this lint, and task-012's teach-back),
  and SPLIT into its own TEST task when SUBSTANTIAL (large fixture suites -- harvest T01-T10 +
  fixture trees -> task-007; closure C01-C08 + 3-output fixtures -> task-009).
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `lint-frontmatter.sh` is deterministic ASCII bash (coreutils only, no LLM/python3/pwsh),
  flags missing required fields with `[FM-MISSING]` and malformed shapes with `[FM-INVALID]`, and
  introduces NO new tag.
- [ ] Day-one soft-skip holds: a doc carrying none of the new fields, a `meta` doc, and a
  `source: generated` doc are all skipped; required-field checks fire only on docs that already
  declare a new field.
- [ ] `lint-frontmatter.sh` and `build-kb-index.sh` are both on the `test-ascii-only.sh` allow-list
  and both pass the ASCII guard.
- [ ] The `kb-hygiene` CI job runs the lint over `.aid/knowledge/` and stays green (all AID docs
  soft-skip on day one).
- [ ] `tests/canonical/test-frontmatter-lint.sh` asserts the three failure classes flag and a
  well-formed fixture passes; it is deterministic with clean setup/teardown and auto-discovered by
  `tests/run-all.sh`.
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
