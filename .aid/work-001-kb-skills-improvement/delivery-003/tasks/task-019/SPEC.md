# task-019: canonical test suite for migrate-kb-frontmatter.sh

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-003

**Depends on:** task-018

**Scope:**
- Add the canonical suite `tests/canonical/test-migrate-kb-frontmatter.sh` (auto-discovered by
  `tests/run-all.sh`'s glob, run in the `canonical-tests` job), mirroring `test-aid-migrate.sh`'s
  pattern. **The suite MUST pin `HOME`** (`export HOME=<throwaway>`, plus an escape canary) and run
  ENTIRELY against a throwaway fixture KB root it builds in a temp dir -- NEVER against
  `.aid/knowledge/` ([[aid-scan-tests-must-pin-home]]).
- Build a **fixture old-format KB** in the temp root: at minimum one `primary` `intent:`-only doc, one
  `extension` `intent:`-only doc, a pure-synthesis doc (its true `sources:` is `[]`), a `meta` doc
  (must be skipped), a `source: generated` doc (must be skipped), and a `source: promoted from ...`
  doc (must be IN scope under the widened predicate). Provide a pre-confirmed worksheet fixture so
  `--apply` can run unattended.
- Assert (mechanical, deterministic):
  - `--propose` writes the worksheet and leaves every doc on disk byte-unchanged.
  - `--apply` migrates a fixture old-format doc to **lint-clean** (re-run `lint-frontmatter.sh` over
    the migrated fixture -> no `[FM-MISSING]`/`[FM-INVALID]`); `objective:`/`summary:`/`sources:`/
    `approved_at_commit:` present in f001 canonical order; `intent:` retired; a `changelog:` row added.
  - **Idempotent re-run is a no-op**: a second `--apply` over the migrated KB changes no doc
    byte-for-byte (no re-stamp, no double `changelog:` row) -- including the pure-synthesis
    `sources: []` doc (the `sources:`-KEY-presence skip predicate, NOT value-presence).
  - **`--dry-run`** on `--propose` AND on `--apply` writes nothing (no worksheet, no doc edit, no
    backup tree).
  - **`--rollback` restores byte-identity**: snapshot each doc before `--apply`, run `--apply`, run
    `--rollback`, assert each doc is byte-identical to its pre-apply snapshot and the backup tree is
    removed.
  - **`intent:`-retire ordering**: a doc whose `objective:`/`summary:` would resolve empty does NOT
    have its `intent:` retired (degrade-safe).
  - **Scope totality**: the `source: promoted from ...` fixture IS migrated; `meta` and
    `source: generated` fixtures are untouched.
  - **Verification-pass failure**: a deliberately-broken migrated doc (e.g. malformed
    `approved_at_commit:`) makes `--apply` exit non-zero and point at the backup.
  - **Exit codes**: bad/absent KB root, no in-scope docs, and `--apply` with no worksheet each return
    their distinct non-zero code.
- Add NO new test infrastructure beyond the existing canonical-suite harness; trivial state/arg work
  in prose, not bespoke scaffolding ([[prose-over-scripts]]).
- **Boundary:** this task OWNS the script's test coverage. It does NOT modify the script (task-018),
  the lint (task-020), the ASCII guard / SHIPPED_SCRIPTS allow-list (task-020), the glossary content
  (task-021), or AID's real KB (task-022).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-migrate-kb-frontmatter.sh` is auto-discovered by `tests/run-all.sh` and
  passes in the `canonical-tests` job.
- [ ] The suite pins `HOME` to a throwaway dir (with an escape canary) and runs only against a temp
  fixture KB root -- it never reads or writes `.aid/knowledge/`.
- [ ] Assertions cover: propose-writes-nothing-to-docs; apply-migrates-to-lint-clean; idempotent
  no-op re-run (incl. a `sources: []` pure-synthesis doc); `--dry-run` writes nothing; `--rollback`
  restores byte-identity; `intent:` retired only after objective/summary present; `promoted from ...`
  in-scope while `meta`/`generated` skipped; verification-pass failure on a broken doc; the distinct
  exit codes.
- [ ] Tests are deterministic with clean setup/teardown (temp dirs removed; no residue under the real
  `HOME` or `.aid/`).
- [ ] All acceptance criteria from feature-011 covered by at least one assertion (idempotency,
  dry-run, rollback, lint-clean, scope totality, safe/reversible).
- [ ] All section-6 quality gates pass.
