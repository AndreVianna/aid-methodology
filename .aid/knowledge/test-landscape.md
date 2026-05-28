---
kb-category: primary
source: hand-authored
intent: |
  Describes all test suites and coverage for the AID-methodology repo. Covers: 5 canonical
  bash helper unit-test suites in tests/canonical/ (writeback-task-status, delivery-gate-aggregate,
  compute-block-radius, parse-recipe, read-setting) and Python renderer self-tests. No coverage
  tooling; no CI. Read this to know what tests exist and how to run them.
contracts:
  - "5 suites in tests/canonical/"
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
  - 2026-05-27: Updated in cycle-2 FIX Phase A to reflect post-Q6 cleanup (5 suites; tests/skills/ removed; pool-dispatch.sh removed)
---
# Test Landscape

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27
> **Scope:** This repo ships a methodology + a multi-tool distribution; there is no application code (see `architecture.md §Project Type`). "Tests" here means the canonical-helper bash test suites and the renderer's Python self-tests.

---

## Test Frameworks

| Framework | Version | Config | Where used |
|-----------|---------|--------|------------|
| Bash (pure POSIX, no test harness) | n/a — uses inline `PASS=`/`FAIL=` counters + `set -u` | none (no `bats`, no `shunit2`, no `pytest.ini`) | `tests/canonical/*.sh` (5 suites — see `tests/README.md`) |
| Python `argparse` self-tests | Python 3.11+ (stdlib `tomllib`) per `.claude/skills/aid-generate/scripts/harness.py:15` | flag-based: `--self-test --canonical-root <repo>` | 5 renderer modules under `.claude/skills/aid-generate/scripts/` |

No `pytest`, no `unittest`, no `jest`, no `mocha`. Test discovery is **manual** — each suite is invoked one at a time (see `tests/README.md`).

---

## Test Types Found

- **Unit tests (helper-script granularity):** `tests/canonical/` — 5 suites, each targeting ONE canonical bash helper:
  - `tests/canonical/read-setting.sh` (360 lines) — 17+ numbered scenarios for the settings-resolution helper
  - `tests/canonical/writeback-task-status.sh` (535 lines) — 69 tests
  - `tests/canonical/delivery-gate-aggregate.sh` (535 lines) — 18 tests
  - `tests/canonical/compute-block-radius.sh` (345 lines) — 17 tests
  - `tests/canonical/parse-recipe.sh` (1,002 lines — the largest test file) — 113 tests; 19 numbered "Unit" scenarios per `tests/canonical/parse-recipe.sh:11-29`

> **Post-Q6-cleanup (cycle-1):** `tests/canonical/pool-dispatch.sh` and the `tests/skills/` directory (2 suites: `lite-subpaths.sh`, `lite-to-full-escalation.sh`) were deleted. See `tests/README.md` for current suite list.
- **Generator self-tests (Python):** 5 renderer modules + `harness.py` + `test_manifest_safety.py` invoked via `--self-test` (see `.claude/skills/aid-generate/scripts/render_agents.py:410-467`, `render_recipes.py:167-205`)
- **Integration tests (cross-component):** none — the canonical/renderer split has no integration harness beyond the deterministic-render verification (see Coverage below)
- **Snapshot / contract / performance tests:** none found

---

## Coverage

No coverage tool is configured. There is no `.coveragerc`, no `coverage.xml`, no `nyc`, no `c8`, no `jacoco`. Coverage is **assessed by inspection**, not measured.

The closest equivalents are the **renderer determinism checks** (functional coverage of the build pipeline):

- `python .claude/skills/aid-generate/scripts/verify_deterministic.py` — **VERIFY-4a (strict)** — byte-identical re-render guarantee per `run_generator.py:75-80`. Re-renders the entire `canonical/` source twice and asserts every output file is bit-for-bit identical.
- `python .claude/skills/aid-generate/scripts/verify_advisory.py` — **VERIFY-4b (advisory)** invoked from `run_generator.py:82-84`. Soft checks (skipped/checked counts reported).

⚠️ **Inferred from code — needs confirmation:** since coverage tooling is absent, statement/branch coverage of helper scripts is unknown. The high test-line-to-source-line ratio for `parse-recipe.sh` (test 1,002 / source 540 = 1.86×) and `writeback-task-status.sh` (test 535 / source 627 = 0.85×) is the only proxy.

---

## Test Commands

```bash
# Run canonical helper unit tests (5 suites — see tests/README.md)
bash tests/canonical/writeback-task-status.sh    # 69 tests
bash tests/canonical/delivery-gate-aggregate.sh  # 18 tests
bash tests/canonical/compute-block-radius.sh     # 17 tests
bash tests/canonical/parse-recipe.sh             # 113 tests
bash tests/canonical/read-setting.sh             # 17+ scenarios

# Verify the canonical → 3-profiles render is byte-correct + complete
python .claude/skills/aid-generate/scripts/verify_deterministic.py

# Run a single renderer's Python self-test
python .claude/skills/aid-generate/scripts/render_agents.py --self-test --canonical-root .
python .claude/skills/aid-generate/scripts/render_recipes.py --self-test --canonical-root .
python .claude/skills/aid-generate/scripts/harness.py --self-test
```

There is no `Makefile`, no `npm test`, no `pytest`, no `task` runner — every test command is the literal interpreter invocation above.

---

## CI/CD Integration

**None.** Confirmed by absence of `.github/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.circleci/`, `.travis.yml`, and `bitbucket-pipelines.yml` in the repository tree. See `tech-debt.md H2` for the formal debt item.

Quality gating is therefore **in-loop, agent-mediated**, not pre-merge automated:
- `aid-discover` runs adversarial review of KB drafts
- `aid-execute` runs two-tier review per task (small-tier reviewer) + per-delivery quality gate with `grade.sh` determinism
- `aid-deploy` runs a verification step
- Maintainer is expected to run the canonical suites manually before merging

---

## Testing Patterns

- **Pattern — Inline counter + `pass`/`fail` helpers:** every `tests/canonical/*.sh` declares `PASS=0`, `FAIL=0`, and helpers `pass() { PASS=$((PASS+1)); ... }` / `fail() { FAIL=$((FAIL+1)); ... }`. Example: `tests/canonical/parse-recipe.sh:46-52`, `tests/canonical/read-setting.sh:29-30`. No `BATS_RUN` or framework macros.
- **Pattern — Numbered scenario comments:** suites enumerate cases in the header (e.g., `tests/canonical/parse-recipe.sh:11-29`, `tests/canonical/read-setting.sh:101-332`). This is the de-facto test-case index since there's no framework auto-discovery.
- **Pattern — `set -u` not `set -e`:** suites use `set -u` only (e.g., `tests/canonical/parse-recipe.sh:35`); a failing assertion increments the counter rather than aborting the run — lets each suite report all failures in one pass.
- **Pattern — Fixture recipes for `parse-recipe.sh`:** the 5 production recipes in `canonical/recipes/` double as `parse-recipe.sh` test fixtures (Units 15–19 per `tests/canonical/parse-recipe.sh:25-29`). Dogfood pattern.
- **Test data setup:** tests create fixtures inline via heredoc (`cat > $TMPDIR/foo.yml <<EOF ... EOF`); no shared `fixtures/` directory, no factory functions.
- **Mocking:** none in bash tests (helpers are real shell scripts run against real tmpdirs). The Python pool-dispatch simulator IS a mock of the live dispatch loop.

---

## Gaps

- **No CI execution of any test.** Every test pass requires manual local invocation. No automated record of the last green run.
- **No coverage measurement.** Statement/branch coverage of the 21 unique canonical helper scripts is unknown. ⚠️ Inferred.
- **No integration tests for the full skill pipeline.** Each skill is tested in isolation (or not at all); no end-to-end test runs Discover→Interview→Specify→Plan→Detail→Execute→Deploy across the live skills with a dummy project.
- **No tests for the renderer integration with `run_generator.py`.** The five `render_*.py` modules each have `--self-test`, but `run_generator.py` itself (which orchestrates them + runs VERIFY-4a/4b) has no test fixture.
- **No E2E test coverage.** The `tests/canonical/` suites test individual helpers in isolation; no end-to-end runner exercises a full `/aid-discover` → `/aid-execute` → `/aid-deploy` cycle. The `.aid/work-001-aid-lite/test-reports/` runners were never committed as canonical artifacts — their absence is the largest single test-coverage gap (see `tech-debt.md H1`).
- **No tests for the 4 PowerShell scripts** (`setup.ps1`, `concatenate.ps1`, plus 2 install-tree mirrors). The bash equivalents are tested by `tests/canonical/`; the PowerShell paths are not.
- **No tests for `setup.sh` / `setup.ps1` end-user install flow.** A user installing claude-code+codex+cursor into a target project has no automated verification that the install succeeded.
- **No tests for `canonical/scripts/summarize/*.mjs`** (`validate-diagrams.mjs` 574 lines, `contrast-check.mjs` 151 lines) — JavaScript validators have no Node test harness.
