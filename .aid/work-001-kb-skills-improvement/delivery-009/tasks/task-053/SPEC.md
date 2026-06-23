# task-053: V-D1 greenfield assertion in test-path-fixtures.sh (AC7 greenfield path-classification)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-009

**Depends on:** task-052, task-032 (delivery-005), task-023 (delivery-004)

**Scope:**
- Add the **V-D1 greenfield path-classification assertion** to the EXISTING
  `tests/canonical/test-path-fixtures.sh` suite (f012 SPEC TEST-D). task-032 (delivery-005) authored
  this suite with the brownfield subset (V-D2..V-D7) and explicitly stated "No greenfield fixture is
  referenced and no V-D1 greenfield assertion is authored (greenfield is delivery-009)". This task
  adds that carved-out V-D1 assertion -- it does NOT re-author the suite, the brownfield assertions,
  or the isolation scaffolding (those are task-032's; this task EXTENDS the existing file with one
  numbered assertion + the greenfield fixture copy into scratch).
- The added assertion runs f006's SHIPPED `recon-classify.sh` (delivery-004) over the task-052
  `paths/greenfield/generated/` fixture (a `mktemp -d` copy), invoking it as
  `recon-classify.sh --index <fx>/project-index.md --candidates <fx>/candidate-concepts.md
  --settings <scratch>/paths/settings.yml` (the SAME checked-in `paths/settings.yml` task-029
  authored and task-032 already copies into scratch -- never the live repo `.aid/settings.yml`), and
  asserts:
  - **V-D1** -- the greenfield fixture -> recon proposes **greenfield** (grep the proposed path out
    of recon's output / `recon.md`).
- Fold the greenfield fixture into the suite's existing determinism check where task-032 already runs
  V-D6 (re-run byte-identical): the greenfield run must also be byte-identical on re-run, consistent
  with the brownfield determinism assertion (extend V-D6 to cover the greenfield fixture -- no new
  isolation scaffolding).
- **f006 SPIKE-T1 greenfield floor pinning (the oracle contract):** V-D1 PINS the f006 greenfield
  `triage.*` thresholds (`greenfield_max_source_files`, `greenfield_max_source_loc`) -- the greenfield
  shape MUST bin greenfield under the shipped defaults. Per [SPIKE-V2], if a shipped f006 greenfield
  default mis-bins the fixture, the default is changed in **f006's shipped file** (delivery-004,
  `canonical/aid/templates/settings.yml`) and this suite re-asserts; task-032's V-D7 parity check
  already keeps `paths/settings.yml` honest against the shipped value. This task only PINS via the
  V-D1 assertion; it never holds or edits the default in f012, and it does not author/edit
  `recon-classify.sh` or `paths/settings.yml`.

**Scope boundary -- GREENFIELD ONLY:** this task adds ONLY the V-D1 greenfield assertion (and its
fixture-copy + determinism coverage). The brownfield assertions (V-D2..V-D5), the parity assertion
(V-D7), and the suite scaffolding are task-032's (delivery-005) -- consumed, not re-authored.
`--settings` always resolves to the checked-in `paths/settings.yml` copied into scratch; it NEVER
points at the live repo `.aid/settings.yml`.

**Isolation discipline (load-bearing acceptance criteria, reusing task-032's scaffolding):** the
greenfield fixture run is subject to the SAME isolation contract task-032 established -- HOME pinned
to a throwaway dir before any script run; the `_CANARY_BEFORE`/`_CANARY_AFTER` real-HOME `.aid`
snapshot from `test-aid-migrate.sh` (snapshot BEFORE, per [[ci-runs-as-root-repo-under-home]]);
always pass explicit `--index`/`--candidates`/`--settings` at the `mktemp` fixture copy (never a
cwd/`$HOME` default, never the live `.aid/settings.yml`, never the repo root); `mktemp -d` scratch +
`trap ... EXIT` cleanup; never mutate the committed greenfield fixture.

**Boundary:** f012 EXERCISES f006's classifier -- this task does NOT author/edit `recon-classify.sh`,
`paths/settings.yml`, or the `triage.*` thresholds (f006/task-029). The "the greenfield path reaches
teach-back closure" half of AC7 is the judgment boundary (a full GENERATE method run with LLM
dispatch -- the behavior task-051 wires), NOT a CI assertion; this suite asserts only the greenfield
path-classification half.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-path-fixtures.sh` gains a numbered **V-D1** assertion: the task-052
  greenfield fixture classifies **greenfield** when `recon-classify.sh` runs over it with
  `--settings paths/settings.yml`; the suite remains auto-discovered by `tests/run-all.sh` (no edit
  to run-all.sh) and follows the existing `test-doc-set-mapping.sh` pattern.
- [ ] The greenfield fixture is copied into the `mktemp -d` scratch and run with explicit
  `--index`/`--candidates`/`--settings` at the scratch copy; `--settings` resolves only to the
  checked-in `paths/settings.yml` (never the live repo settings); the committed greenfield fixture is
  never mutated.
- [ ] The greenfield run is byte-identical on re-run (V-D6 extended to cover the greenfield fixture,
  consistent with V-D6's brownfield byte-identity check).
- [ ] The f006 greenfield `triage.*` thresholds (`greenfield_max_source_files`,
  `greenfield_max_source_loc`) are pinned by V-D1 under the shipped defaults; any needed change is
  made in f006's shipped delivery-004 file, not in f012 (V-D7 parity, task-032, anchors the fixture
  to the shipped value).
- [ ] The brownfield assertions (V-D2..V-D5), V-D7, and the suite scaffolding are NOT re-authored or
  modified beyond adding the V-D1 assertion + greenfield fixture copy; `recon-classify.sh` and
  `paths/settings.yml` are not authored/edited.
- [ ] Isolation: HOME pinned to a throwaway dir; the real-HOME `.aid` canary snapshots before/after
  and asserts no `.aid` appeared; the repo root is never used as a script input.
- [ ] Tests are deterministic with clean setup/teardown; the AC7-greenfield path-classification
  acceptance criterion from feature-012 (V-D1) is covered; all section-6 quality gates pass.
