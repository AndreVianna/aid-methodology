# task-030: test-essence-capture.sh + f004 SPIKE-H2 floor pinning

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-027, task-006 (delivery-001), task-008 (delivery-001)

**Scope:**
- Author `tests/canonical/test-essence-capture.sh` -- the AC2/AC3 essence-capture regression suite
  (f012 SPEC TEST-A), auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob (line
  33; NO edit to run-all.sh). Follow the `test-doc-set-mapping.sh` pattern: `set -u`,
  `source ../lib/assert.sh`, numbered `T01..` assertions, `mktemp -d` scratch, `trap ... EXIT`
  cleanup, `test_summary` + `exit $?`.
- The suite runs f004's SHIPPED `harvest-coined-terms.sh` and `closure-check.sh` (delivery-001) over
  the task-027 fixtures (a `mktemp -d` copy of `relative-bus/` / `closed-kb/` / `unclosed-kb/`) and
  asserts V-A1..V-A6 (f012 SPEC TEST-A):
  - V-A1 -- harvest surfaces `Relative Bus` in `candidate-concepts.md` with Spread `>= 2`.
  - V-A2 -- the all-common-word phrase survives via f004's phrase-salience escape (phrase-as-a-unit
    clears the spread `>= 2` floor; the joined `RelativeBus` token never survives as a unit).
  - V-A3 -- the phrase is not buried: it is emitted while the incidental single-channel capitalized
    common-word noise (E4 class) stays below the candidate-count cap (the precision/noise assertion).
  - V-A4 -- `closure-check.sh` over `closed-kb/` reports ZERO ungrounded (captures AND defines / AC3).
  - V-A5 -- `closure-check.sh` over `unclosed-kb/` reports `Relative Bus` as ungrounded (the
    regression guard).
  - V-A6 -- determinism: re-running harvest is byte-identical (`diff` two runs).
- **f004 SPIKE-H2 floor pinning (the oracle contract):** V-A1/V-A2/V-A3 jointly PIN the f004
  denylist/phrase-salience floor -- recall (`Relative Bus` survives at spread `>= 2`) and precision
  (single-channel capitalized noise does not flood). Per [SPIKE-V2], the empirical floor VALUE is
  MEASURED during implementation (run the helper over the planted+noise fixture, pick the separating
  value); if the current shipped f004 default mis-classifies, the default is changed in **f004's
  shipped file** (delivery-001) and this suite re-asserts. This task only PINS via assertions; it
  never holds or edits the default in f012.

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir
(`export HOME="${TMP}/fakehome"`) before any script run; carry the `_CANARY_BEFORE`/`_CANARY_AFTER`
real-HOME `.aid` snapshot from `test-aid-migrate.sh` (snapshot BEFORE -- the real `$HOME` may already
hold a `.aid` under CI, per [[ci-runs-as-root-repo-under-home]]); always pass an explicit `--root`
pointing at the `mktemp` fixture copy (never a cwd/`$HOME` default, never the repo root);
`mktemp -d` scratch + `trap ... EXIT` cleanup; never mutate the committed fixture.

**Boundary:** f012 EXERCISES f004's scripts -- this task does NOT author/edit `harvest-coined-terms.sh`,
`closure-check.sh`, the denylist, or the phrase-survival rule (f004, delivery-001). The optional
history-channel assertion (via f004 `--history-file`, [SPIKE-V1]) is authored ONLY if f004's
`[SPIKE-H1]` `--history-file` arg shipped; otherwise it is dropped -- the load-bearing AC2 assertion
uses code+docs spread `>= 2` only and has no history dependency.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-essence-capture.sh` exists, is auto-discovered by `tests/run-all.sh` (no edit to run-all.sh), and follows the `test-doc-set-mapping.sh` pattern (`set -u`, `source ../lib/assert.sh`, numbered Ts, `mktemp -d`, `trap EXIT`, `test_summary`/`exit $?`).
- [ ] V-A1: asserts `Relative Bus` is present in the harvested `candidate-concepts.md` with Spread `>= 2`. V-A2: asserts the phrase row is present at spread `>= 2` (the phrase-salience survival condition), NOT a joined-token allowlist.
- [ ] V-A3: asserts the `Relative Bus` row is emitted AND the single-channel capitalized noise stays below the candidate-count cap (precision).
- [ ] V-A4: `closure-check.sh` over `closed-kb/` asserts an empty ungrounded set. V-A5: `closure-check.sh` over `unclosed-kb/` asserts `Relative Bus` is in the ungrounded set.
- [ ] V-A6: harvest run twice over the same fixture copy is byte-identical (`diff` clean).
- [ ] The f004 SPIKE-H2 phrase-salience floor is pinned by V-A1/V-A2/V-A3; the floor VALUE is measured empirically and recorded as f004's default (any needed change is made in f004's shipped delivery-001 file, not in f012); this suite only asserts the recall/precision separation.
- [ ] Isolation: HOME is pinned to a throwaway dir; the real-HOME `.aid` canary snapshots before/after and asserts no `.aid` appeared; every script invocation passes an explicit `--root` at the `mktemp` fixture copy; the committed fixture is never mutated; the repo root is never used as `--root`.
- [ ] Tests are deterministic with clean setup/teardown; all AC2/AC3 acceptance criteria from feature-012 are covered; all section-6 quality gates pass.
