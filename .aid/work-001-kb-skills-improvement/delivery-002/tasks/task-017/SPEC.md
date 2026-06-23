# task-017: Canonical suite for the INDEX routing-table render + fallbacks

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-002

**Depends on:** task-015, task-016

**Scope:**
- Add a new canonical helper suite `tests/canonical/test-build-kb-index.sh` (auto-discovered by the
  `tests/run-all.sh` glob, run in the `canonical-tests` job) -- no existing `build-kb-index.sh`
  canonical suite exists. The suite drives `build-kb-index.sh` against a throwaway fixture KB root
  (NOT `.aid/knowledge/`) and MUST pin `HOME`/use a controlled fixture root so it asserts against
  controlled inputs.
- Assertions (per f002 SPEC "CI / canonical suite"):
  - (a) A doc with the full new fields (`objective`/`summary`/`tags`/`see_also`/`audience`) renders
    all 6 table cells populated.
  - (b) An un-migrated `intent:`-only doc renders Objective + Summary from the `intent:` fallback
    (Objective = collapsed `intent:`; Summary = first sentence via the `[.!?](?=[ \t]+[A-Z]|$)`
    predicate) and blank Tags / See-instead / Audience.
  - (c) A literal `|` in a field is escaped to `\|` in the rendered cell.
  - (d) `see_also` doc-name entries render as `[name](../knowledge/name)` links.
  - (e) The output is byte-stable across two consecutive runs (determinism), modulo the CI-filtered
    timestamp lines.
- Include focused fixtures for the Summary predicate edge cases the SPEC calls out: a `.` inside
  `v1.1.0` / `1.4` / `e.g.` / `i.e.` is NOT a boundary (token not truncated mid-string); a
  no-boundary single-sentence `intent:` returns the whole collapsed line; and a >200-char sentence is
  truncated to 200 chars + ASCII `...`.
- Deterministic, clean setup/teardown (create + remove the fixture KB root); all existing tests still
  pass.
- Boundary: this task OWNS the new canonical suite. It does NOT modify `build-kb-index.sh`
  (task-015/016) and does NOT add table logic -- it asserts the behavior tasks 015-016 produce.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-build-kb-index.sh` exists, is auto-discovered by `tests/run-all.sh`, and
  passes in the `canonical-tests` job.
- [ ] Assertion (a): full-field doc renders all 6 cells populated.
- [ ] Assertion (b): `intent:`-only doc renders Objective + first-sentence Summary from the fallback,
  with blank Tags / See-instead / Audience.
- [ ] Assertion (c): a literal `|` in a field is escaped to `\|`.
- [ ] Assertion (d): `see_also` doc-names render as `[name](../knowledge/name)` links.
- [ ] Assertion (e): output is byte-stable across two runs (determinism), timestamp lines filtered.
- [ ] Summary-predicate edge cases covered: `v1.1.0`/`1.4`/`e.g.`/`i.e.` not split mid-token;
  no-boundary => whole line; >200 chars => truncated to 200 + `...`.
- [ ] Suite pins `HOME`/uses a throwaway fixture KB root; is deterministic with clean
  setup/teardown; all acceptance criteria from f002 are covered; all existing tests still pass.
