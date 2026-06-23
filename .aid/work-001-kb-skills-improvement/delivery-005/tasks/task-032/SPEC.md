# task-032: test-path-fixtures.sh (brownfield + greenfield-detection) + f006 SPIKE-T1 floor pinning

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-029, task-023 (delivery-004)

**Scope:**
- Author `tests/canonical/test-path-fixtures.sh` -- the AC7 path-classification regression suite
  (f012 SPEC TEST-D), auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob (no
  edit to run-all.sh). Follow the `test-doc-set-mapping.sh` pattern (`set -u`, `source
  ../lib/assert.sh`, numbered `T01..`, `mktemp -d` scratch, `trap ... EXIT`, `test_summary` +
  `exit $?`).
- The suite runs f006's SHIPPED `recon-classify.sh` (delivery-004) over the task-029 `paths/`
  fixtures (a `mktemp -d` copy), invoking it as
  `recon-classify.sh --index <fx>/project-index.md --candidates <fx>/candidate-concepts.md
  --settings <scratch>/paths/settings.yml`, and asserts V-D1..V-D7 (f012 SPEC TEST-D):
  - V-D1 -- **greenfield DETECTION (classification only).** greenfield (~0-source) fixture -> recon
    proposes **greenfield**. This is the ONLY greenfield assertion -- greenfield is
    detect-and-signpost, so there is NO greenfield path-runs/closure assertion. The old V-D1
    greenfield **path** assertion (formerly carved to delivery-009 / task-053) collapses into this
    detection-only check: recon-classify yields a greenfield verdict on the ~0-source fixture.
  - V-D2 -- brownfield-small fixture -> recon proposes **brownfield-small**.
  - V-D3 -- brownfield-large (LOC variant) -> **brownfield-large** (RM2 OR-branch).
  - V-D4 -- brownfield-large (dirs variant) -> **brownfield-large** (RM3 OR-branch, via Full File
    Inventory).
  - V-D5 -- brownfield-large (concepts variant) -> **brownfield-large** (RM4 OR-branch).
  - V-D6 -- determinism: re-run byte-identical (`diff` two runs).
  - V-D7 -- shipped-defaults parity: the `triage.*` values in `paths/settings.yml` are
    byte-identical to the shipped `canonical/aid/templates/settings.yml` `triage.*` block (grep both,
    assert identical) -- so V-D2..V-D5 pin the SHIPPED defaults, not a drifted fixture copy.
- **f006 SPIKE-T1 floor pinning (the oracle contract):** V-D1 pins the greenfield **detection**
  thresholds (`greenfield_max_source_files`/`_loc`); V-D2..V-D5 PIN the f006 `triage.*` brownfield
  thresholds (`large_min_source_loc`/`_dirs`/`_concepts`) -- each shape MUST bin correctly under the
  shipped defaults. Per [SPIKE-V2], if a shipped f006 default mis-bins a fixture, the default is
  changed in **f006's shipped file** (delivery-004) and this suite re-asserts; V-D7 keeps the fixture
  honest against the shipped value. This task only PINS via assertions; it never holds or edits the
  default in f012.

**Scope boundary -- greenfield is DETECTION-ONLY:** greenfield was de-scoped to detect-and-signpost
on 2026-06-23 (recon DETECTS greenfield; aid-discover signposts to `/aid-interview` + halts). This
suite asserts greenfield **classification only** (V-D1) -- there is **no greenfield path-runs /
greenfield-closure assertion** (no greenfield generation engine to exercise). The old greenfield
**path** assertion (formerly carved to delivery-009 / task-053) collapses into V-D1's detection-only
check; **delivery-009, task-052, and task-053 are deleted** and this suite references none of them.
`--settings` always resolves to the checked-in `paths/settings.yml` fixture copied into scratch; it
NEVER points at the live repo `.aid/settings.yml` (that would re-introduce a real-repo read and
couple the pin to mutable live settings).

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir before
any script run; the `_CANARY_BEFORE`/`_CANARY_AFTER` real-HOME `.aid` snapshot from
`test-aid-migrate.sh` (snapshot BEFORE, per [[ci-runs-as-root-repo-under-home]]); always pass
explicit `--index`/`--candidates`/`--settings` at the `mktemp` fixture copy (never a cwd/`$HOME`
default, never the live `.aid/settings.yml`, never the repo root); `mktemp -d` scratch +
`trap ... EXIT` cleanup; never mutate the committed fixture.

**Boundary:** f012 EXERCISES f006's classifier -- this task does NOT author/edit `recon-classify.sh`
or the `triage.*` thresholds (f006, delivery-004). The "each path reaches teach-back closure" half of
AC7 is the judgment boundary (a full method run with LLM dispatch), NOT a CI assertion; this suite
asserts only the path-classification half.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-path-fixtures.sh` exists, is auto-discovered by `tests/run-all.sh` (no edit), and follows the `test-doc-set-mapping.sh` pattern.
- [ ] V-D1: the greenfield (~0-source) fixture classifies **greenfield** (DETECTION only). V-D2: brownfield-small fixture classifies **brownfield-small**. V-D3/V-D4/V-D5: each brownfield-large variant (LOC / dirs / concepts) classifies **brownfield-large**, exercising the RM2 / RM3 / RM4 OR-branches independently.
- [ ] No greenfield **path-runs / greenfield-closure** assertion is authored -- greenfield is detect-and-signpost, so V-D1 is the only greenfield assertion (classification only). No reference to the deleted delivery-009 / task-052 / task-053.
- [ ] V-D6: `recon-classify.sh` run twice over the same fixture copy is byte-identical (`diff` clean).
- [ ] V-D7: the `triage.*` keys/values in `paths/settings.yml` are byte-identical to the shipped `canonical/aid/templates/settings.yml` `triage.*` block.
- [ ] The f006 SPIKE-T1 `triage.*` thresholds are pinned under the shipped defaults: V-D1 pins the greenfield detection thresholds (`greenfield_max_source_files`/`_loc`), V-D2..V-D5 pin the brownfield thresholds (`large_min_*`); V-D7 anchors the fixture to the shipped values; any needed change is made in f006's shipped delivery-004 file, not in f012.
- [ ] Isolation: HOME pinned to a throwaway dir; real-HOME `.aid` canary snapshots before/after and asserts no `.aid` appeared; `--settings` resolves only to the `mktemp` fixture copy (never the live repo settings); the committed fixture is never mutated; the repo root is never used.
- [ ] Tests are deterministic with clean setup/teardown; all AC7-brownfield acceptance criteria from feature-012 are covered; all section-6 quality gates pass.
