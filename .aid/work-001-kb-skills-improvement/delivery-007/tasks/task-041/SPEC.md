# task-041: test-kb-freshness-check.sh -- canonical staleness suite + fixtures

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-007

**Depends on:** task-040

**Scope:**
- Author `tests/canonical/test-kb-freshness-check.sh` -- the f007 staleness-check regression suite
  (f007 SPEC "Affected components" NEW canonical test suite), auto-discovered by `tests/run-all.sh`'s
  `tests/canonical/test-*.sh` glob (NO edit to run-all.sh). Follow the established canonical-test
  pattern: `set -u`, `source ../lib/assert.sh`, numbered `T01..` assertions, `mktemp -d` scratch,
  `trap ... EXIT` cleanup, `test_summary` + `exit $?`.
- The suite builds a throwaway **git fixture repo** (`git init` inside the `mktemp -d` scratch, with
  scripted commits so `merge-base --is-ancestor` ancestry is deterministic) carrying a fixture KB and
  runs the SHIPPED `kb-freshness-check.sh` (task-040) over it, asserting each verdict class:
  - **suspect** -- a doc whose `sources:` path was last changed by a commit that is NOT an ancestor of
    its `approved_at_commit:` (source changed after the baseline) -> verdict `suspect`, and the drifted
    path appears in `suspect_sources_csv`.
  - **current** -- a doc whose `sources:` last-changed commit is an ancestor of (or equal to) its
    `approved_at_commit:` (at-or-before baseline) -> verdict `current`, empty `suspect_sources_csv`.
  - **unknown (URL source)** -- a doc whose only `sources:` entry is a URL -> verdict `unknown`.
  - **unknown (pre-migration)** -- a doc with `sources:` but NO `approved_at_commit:` -> verdict
    `unknown` (degrade-gracefully, never `suspect` on a missing baseline).
  - **unknown (untracked source)** -- a doc whose `sources:` path was never committed to the fixture
    repo (empty `git log`) -> verdict `unknown` (never a false `suspect`).
  - **current (no sources)** -- a pure-synthesis/glossary doc with `sources:` absent or `[]` ->
    verdict `current`.
- Assert **TSV byte-stability**: two consecutive runs over the unchanged fixture repo produce
  byte-identical `--format tsv` output (`diff` clean) -- the NFR-3/C5 determinism gate.
- Assert the **default `text` format** (task-040 ships `text` as the DEFAULT `--format`): a smoke
  assertion that a default invocation (no `--format`, i.e. `text`) renders a verdict line for each
  verdict class -- `current`, `suspect`, and `unknown` docs all surface in the human-formatted output
  (verdict parity with the tsv rows over the same fixture).
- Assert the **`--doc <relpath>` single-doc filter**: invoking with `--doc <relpath>` for one fixture
  doc returns ONLY that doc's verdict (the other fixture docs are absent from the output).
- Assert **routing**: `meta` / `source: generated` / `INDEX.md` / `README.md` / `STATE.md` fixtures
  are excluded from the output (same routing as `build-kb-index.sh`).
- Assert **exit codes**: `0` on a successful scan even when a doc is `suspect` (suspect != error);
  `1` on an argument error.

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir
(`export HOME="${TMP}/fakehome"`) before any script run; carry the `_CANARY_BEFORE`/`_CANARY_AFTER`
real-HOME `.aid` snapshot pattern from `test-aid-migrate.sh` (snapshot BEFORE -- the real `$HOME` may
already hold a `.aid` under CI, per [[ci-runs-as-root-repo-under-home]]) and assert no `.aid` appeared;
always pass explicit fixture paths (`--root`/`--repo` at the `mktemp` fixture repo, never a cwd/`$HOME`
default, never the repo root); `mktemp -d` scratch + `trap ... EXIT` cleanup; the fixture git repo is
built inside scratch (never the AID repo's own git history).

**Boundary:** f007 EXERCISES the task-040 script. This task does NOT author/edit
`kb-freshness-check.sh` (task-040), the dashboard readers (task-042), or the reader-parity suite
(task-044 -- the Python===Node parity gate is a separate suite). It asserts only the script's per-doc
verdicts and determinism over fixtures.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-kb-freshness-check.sh` exists, is auto-discovered by `tests/run-all.sh`
  (no edit to run-all.sh), and follows the canonical-test pattern (`set -u`, `source ../lib/assert.sh`,
  numbered Ts, `mktemp -d`, `trap EXIT`, `test_summary`/`exit $?`).
- [ ] Verdict-class assertions all hold over a scripted git fixture repo: suspect (source changed after
  baseline, drifted path in `suspect_sources_csv`); current (source at-or-before baseline); unknown for
  each of URL-source, pre-migration (no `approved_at_commit:`), and untracked-source; current for a
  no-/empty-`sources:` doc.
- [ ] Routing assertion: meta / `source: generated` / INDEX.md / README.md / STATE.md fixtures are
  excluded from the output.
- [ ] Determinism assertion: two consecutive `--format tsv` runs over the unchanged fixture are
  byte-identical (`diff` clean). Exit-code assertions: `0` on a scan that yields a suspect doc; `1` on
  arg error.
- [ ] Default `text`-format smoke assertion: a default invocation (no `--format`, i.e. `text`) renders
  a verdict line for each of `current` / `suspect` / `unknown` (verdict parity with the tsv rows over
  the same fixture).
- [ ] `--doc <relpath>` single-doc-filter assertion: invoking with `--doc <relpath>` returns ONLY that
  doc's verdict and excludes the other fixture docs.
- [ ] Isolation: HOME is pinned to a throwaway dir; the real-HOME `.aid` canary snapshots before/after
  and asserts no `.aid` appeared; every invocation passes explicit `--root`/`--repo` at the `mktemp`
  fixture repo; the fixture git repo lives in scratch and the AID repo's git history is never touched.
- [ ] Tests are deterministic with clean setup/teardown; all f007 script acceptance criteria are
  covered; all section-6 quality gates pass.
