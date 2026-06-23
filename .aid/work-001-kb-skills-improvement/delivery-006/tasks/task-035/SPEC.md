# task-035: test-calibration-fixtures.sh + f005 SPIKE-C1 floor pinning

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-032, task-008 (delivery-001)

**Scope:**
- Author `tests/canonical/test-calibration-fixtures.sh` -- the AC6 calibration regression suite
  (f012 SPEC TEST-B), auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob (no
  edit to run-all.sh). Follow the `test-doc-set-mapping.sh` pattern (`set -u`,
  `source ../lib/assert.sh`, numbered `T01..`, `mktemp -d` scratch, `trap ... EXIT`, `test_summary`
  + `exit $?`).
- The suite runs f004's SHIPPED MERGED `closure-check.sh` (delivery-001 task-008) -- outputs (b)
  per-doc `sources:`-anchored coverage table + (c) per-doc transcription-ratio hint; f005 ships NO
  coverage script (`kb-salient-coverage.sh` was dropped) -- over the task-032 `calibration/` fixture
  (a `mktemp -d` copy) and asserts the MECHANICAL subset V-B1/V-B2/V-B4/V-B5 (f012 SPEC TEST-B):
  - V-B1 (MECHANICAL) -- CAL-3 coverage gap: `closure-check.sh` output (b) reports the planted
    salient term as an `absent` row for `coverage-gap.md`.
  - V-B2 (MECHANICAL) -- CAL-1 transcription: `closure-check.sh` output (c) transcription-ratio hint
    for `transcription-fat.md` (vs its `sources:` file) reads `>=` the CAL-1 floor.
  - **V-B3 is NOT a mechanical assertion (DROPPED from CI).** CAL-2 hollowness is irreducible LLM
    judgment (f005 SPEC L455/L474 -- no shipped script emits a hollowness signal; `closure-check.sh`'s
    3 outputs are (a) ungrounded, (b) coverage, (c) transcription, none a hollowness ratio). The
    `hollow-thin.md` doc is exercised + ANCHORED at runtime (the Calibration reviewer M5 grades it);
    this suite asserts NO mechanical hollowness signal.
  - V-B4 (MECHANICAL) -- precision: `well-calibrated.md` produces NO `absent` row in output (b) and a
    transcription ratio `<` the CAL-1 floor in output (c) (the calibrated floors do not false-positive
    the control).
  - V-B5 -- determinism: re-run byte-identical (`diff` two runs).
- **f005 SPIKE-C1 floor pinning (the oracle contract):** V-B2 (flag the fat doc) + V-B4 (do NOT
  flag the control) jointly PIN the f005 CAL-1 transcription-ratio severity floor (read off
  `closure-check.sh` output (c)); V-B1 pins the coverage signal (output (b)) analogously. **CAL-2
  hollowness has no mechanical floor to pin** -- it is LLM judgment (no shipped signal), so V-B3 is
  not a pinned threshold. Per [SPIKE-V2], the empirical transcription-ratio floor VALUE that cleanly
  separates fat-from-control is MEASURED during implementation; if the current shipped f005 default
  mis-separates, the default is changed in **f005's shipped file** (delivery-001) and this suite
  re-asserts. This task only PINS via assertions; it never holds or edits the floor in f012.

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir before
any script run; the `_CANARY_BEFORE`/`_CANARY_AFTER` real-HOME `.aid` snapshot from
`test-aid-migrate.sh` (snapshot BEFORE, per [[ci-runs-as-root-repo-under-home]]); run
`closure-check.sh` only over the `mktemp` fixture copy (explicit fixture paths, never a
cwd/`$HOME` default, never the repo root); `mktemp -d` scratch + `trap ... EXIT` cleanup; never
mutate the committed fixture.

**Boundary:** f012 EXERCISES f004's merged coverage oracle -- this task does NOT author/edit
`closure-check.sh` (f004, delivery-001) or the f005 Calibration rubric / CAL-N floors (f005,
delivery-001). f005 ships NO coverage script; the coverage/transcription evidence is f004's
`closure-check.sh` outputs (b)/(c). The reviewer's MEDIUM/HIGH `[CAL-*]` verdict -- and CAL-2
hollowness in full -- is the judgment half (NOT a CI assertion); this suite asserts only the
MECHANICAL evidence the reviewer grades against (CAL-1 transcription via (c), CAL-3 coverage via
(b)) and pins the transcription-ratio severity floor that verdict uses.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-calibration-fixtures.sh` exists, is auto-discovered by `tests/run-all.sh` (no edit), and follows the `test-doc-set-mapping.sh` pattern.
- [ ] V-B1: asserts the planted salient term + `coverage-gap.md` appear as an `absent` row in `closure-check.sh` output (b). V-B2: asserts the fat doc's transcription ratio in output (c) `>=` the CAL-1 floor.
- [ ] **V-B3 (CAL-2 hollowness) is DROPPED from the mechanical assertion set** -- hollowness is LLM judgment (no shipped script emits a hollowness signal); the hollow doc is runtime-anchored (the Calibration reviewer M5 grades it), not CI-asserted. V-B4: asserts `well-calibrated.md` produces no `absent` row in output (b) AND its transcription ratio in output (c) is below the CAL-1 floor.
- [ ] V-B5: `closure-check.sh` run twice over the same fixture copy is byte-identical (`diff` clean).
- [ ] The f005 SPIKE-C1 CAL-1 transcription-ratio severity floor is pinned by V-B2 (flag) + V-B4 (do-not-flag control); the floor VALUE is measured empirically and recorded as f005's default (any needed change is made in f005's shipped delivery-001 file, not in f012); this suite only asserts the flag-vs-control separation. CAL-2 hollowness has no mechanical floor (judgment, not pinned).
- [ ] Isolation: HOME pinned to a throwaway dir; real-HOME `.aid` canary snapshots before/after and asserts no `.aid` appeared; `closure-check.sh` runs only over the `mktemp` fixture copy with explicit paths; the committed fixture is never mutated; the repo root is never scanned.
- [ ] Tests are deterministic with clean setup/teardown; all AC6 acceptance criteria from feature-012 are covered; all section-6 quality gates pass.
