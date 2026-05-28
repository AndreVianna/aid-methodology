---
kb-category: primary
source: hand-authored
intent: |
  Describes all test suites and coverage for the AID-methodology repo. Covers: 6 canonical
  bash helper unit-test suites in tests/canonical/ (297 tests total across writeback-task-status,
  delivery-gate-aggregate, compute-block-radius, pool-dispatch, parse-recipe, read-setting),
  2 skill-level end-to-end suites in tests/skills/ (aid-interview lite-path routing and
  escalation), and 5 Python renderer self-tests. No coverage tooling; no CI. Read this to
  know what tests exist and how to run them.
contracts:
  - "6 suites in tests/canonical/"
  - "2 suites in tests/skills/"
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Test Landscape

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27
> **Scope:** This repo ships a methodology + a multi-tool distribution; there is no application code (`CLAUDE.md:24-25`). "Tests" here means the canonical-helper bash test suites + skill-level end-to-end scripts + the renderer's Python self-tests.

---

## Test Frameworks

| Framework | Version | Config | Where used |
|-----------|---------|--------|------------|
| Bash (pure POSIX, no test harness) | n/a — uses inline `PASS=`/`FAIL=` counters + `set -u` | none (no `bats`, no `shunit2`, no `pytest.ini`) | `tests/canonical/*.sh` (6 suites), `tests/skills/*.sh` (2 suites) |
| Python `argparse` self-tests | Python 3.11+ (stdlib `tomllib`) per `.claude/skills/aid-generate/scripts/harness.py:15` | flag-based: `--self-test --canonical-root <repo>` | 5 renderer modules under `.claude/skills/aid-generate/scripts/` |

No `pytest`, no `unittest`, no `jest`, no `mocha`. Test discovery is **manual** — each suite is invoked one at a time per `CLAUDE.md:43-49`.

---

## Test Types Found

- **Unit tests (helper-script granularity):** `tests/canonical/` — 6 suites, each targeting ONE canonical bash helper:
  - `tests/canonical/read-setting.sh` (360 lines) — 17+ numbered scenarios for the settings-resolution helper (see `tests/canonical/read-setting.sh:101-332`)
  - `tests/canonical/writeback-task-status.sh` (535 lines) — 69 tests per `CLAUDE.md:43`
  - `tests/canonical/delivery-gate-aggregate.sh` (535 lines) — 18 tests per `CLAUDE.md:44`
  - `tests/canonical/compute-block-radius.sh` (345 lines) — 17 tests per `CLAUDE.md:45`
  - `tests/canonical/pool-dispatch.sh` (153 lines) — 7 scenarios T1..T7 per `CLAUDE.md:46` (`tests/canonical/pool-dispatch.sh:9-15`)
  - `tests/canonical/parse-recipe.sh` (1,002 lines — the single largest source file in the repo) — 113 tests per `CLAUDE.md:47`; 19 numbered "Unit" scenarios per `tests/canonical/parse-recipe.sh:11-29`
- **End-to-end / skill-level tests:** `tests/skills/` — 2 suites that exercise an entire skill flow:
  - `tests/skills/lite-subpaths.sh` (415 lines) — `aid-interview` TRIAGE → LITE-{BUG-FIX,DOC,REFACTOR,FEATURE} routing
  - `tests/skills/lite-to-full-escalation.sh` (565 lines) — escalation from a lite sub-path back to the full Interview→Specify→Plan→Detail pipeline
- **Generator self-tests (Python):** 5 renderer modules + `harness.py` + `test_manifest_safety.py` invoked via `--self-test` (see `.claude/skills/aid-generate/scripts/render_agents.py:410-467`, `render_recipes.py:167-205`)
- **Integration tests (cross-component):** none — the canonical/renderer split has no integration harness beyond the deterministic-render verification (see Coverage below)
- **Snapshot / contract / performance tests:** none found

---

## Coverage

No coverage tool is configured. There is no `.coveragerc`, no `coverage.xml`, no `nyc`, no `c8`, no `jacoco`. Coverage is **assessed by inspection**, not measured.

The closest equivalents are the **renderer determinism checks** (functional coverage of the build pipeline):

- `python .claude/skills/aid-generate/scripts/verify_deterministic.py` — **VERIFY-4a (strict)** — byte-identical re-render guarantee per `CLAUDE.md:33-34` and `run_generator.py:75-80`. Re-renders the entire `canonical/` source twice and asserts every output file is bit-for-bit identical.
- `python .claude/skills/aid-generate/scripts/verify_advisory.py` — **VERIFY-4b (advisory)** invoked from `run_generator.py:82-84`. Soft checks (skipped/checked counts reported).

⚠️ **Inferred from code — needs confirmation:** since coverage tooling is absent, statement/branch coverage of helper scripts is unknown. The high test-line-to-source-line ratio for `parse-recipe.sh` (test 1,002 / source 540 = 1.86×) and `writeback-task-status.sh` (test 535 / source 627 = 0.85×) is the only proxy.

---

## Test Commands

```bash
# Run all canonical helper unit tests (expected 297/297 passing per CLAUDE.md:42)
# NOTE: There is no single aggregator script; invoke each suite separately:
bash tests/canonical/writeback-task-status.sh    # 69 tests
bash tests/canonical/delivery-gate-aggregate.sh  # 18 tests
bash tests/canonical/compute-block-radius.sh     # 17 tests
bash tests/canonical/pool-dispatch.sh            #  7 tests
bash tests/canonical/parse-recipe.sh             # 113 tests
bash tests/canonical/read-setting.sh             # additional (count not declared in CLAUDE.md; 17+ scenarios)

# Run the skill-level end-to-end suites
bash tests/skills/lite-subpaths.sh
bash tests/skills/lite-to-full-escalation.sh

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

**None.** Confirmed by absence of `.github/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.circleci/`, `.travis.yml`, and `bitbucket-pipelines.yml` in the repository tree (verified by directory search at scout time). `CLAUDE.md:52` states explicitly: *"There is no CI — see `tech-debt.md` H2."* The two cited e2e runner scripts (`bash .aid/work-001-aid-lite/test-reports/e2e-{two-tier,lite-path}-runner.sh`) at `CLAUDE.md:48-49` are referenced but the `.aid/work-001-aid-lite/` directory does not exist on disk on the `kb-overhaul` branch — see `tech-debt.md` H1.

Quality gating is therefore **in-loop, agent-mediated**, not pre-merge automated:
- `aid-discover` runs adversarial review of KB drafts
- `aid-execute` runs two-tier review per task (small-tier reviewer) + per-delivery quality gate with `grade.sh` determinism
- `aid-deploy` runs a verification step
- Maintainer is expected to run the canonical suites manually before merging

---

## Testing Patterns

- **Pattern — Inline counter + `pass`/`fail` helpers:** every `tests/canonical/*.sh` declares `PASS=0`, `FAIL=0`, and helpers `pass() { PASS=$((PASS+1)); ... }` / `fail() { FAIL=$((FAIL+1)); ... }`. Example: `tests/canonical/parse-recipe.sh:46-52`, `tests/canonical/read-setting.sh:29-30`. No `BATS_RUN` or framework macros.
- **Pattern — Numbered scenario comments:** suites enumerate cases in the header (e.g., `tests/canonical/parse-recipe.sh:11-29`, `tests/canonical/read-setting.sh:101-332`, `tests/canonical/pool-dispatch.sh:9-15`). This is the de-facto test-case index since there's no framework auto-discovery.
- **Pattern — `set -u` not `set -e`:** suites use `set -u` only (e.g., `tests/canonical/parse-recipe.sh:35`, `tests/canonical/pool-dispatch.sh:19`); a failing assertion increments the counter rather than aborting the run — lets each suite report all failures in one pass.
- **Pattern — Embedded simulator (Python heredoc):** `tests/canonical/pool-dispatch.sh:22-50` writes a Python pool-dispatch simulator to a `mktemp` file, runs it, and asserts on stdout. The bash test is the harness; the Python is the SUT-substitute. This works because the production `pool-dispatch.sh` invokes subagents, which cannot run in a CI-style isolated test.
- **Pattern — Fixture recipes for `parse-recipe.sh`:** the 5 production recipes in `canonical/recipes/` double as `parse-recipe.sh` test fixtures (Units 15–19 per `tests/canonical/parse-recipe.sh:25-29`). Dogfood pattern.
- **Test data setup:** tests create fixtures inline via heredoc (`cat > $TMPDIR/foo.yml <<EOF ... EOF`); no shared `fixtures/` directory, no factory functions.
- **Mocking:** none in bash tests (helpers are real shell scripts run against real tmpdirs). The Python pool-dispatch simulator IS a mock of the live dispatch loop.

---

## Gaps

- **No CI execution of any test.** Every test pass requires manual local invocation. ⚠️ Inferred: drift between the cited 297-test total and current reality is likely; no automated record of the last green run.
- **No coverage measurement.** Statement/branch coverage of the 21 unique canonical helper scripts is unknown. ⚠️ Inferred.
- **No integration tests for the full skill pipeline.** Each skill is tested in isolation (or not at all); no end-to-end test runs Discover→Interview→Specify→Plan→Detail→Execute→Deploy across the live skills with a dummy project.
- **No tests for the renderer integration with `run_generator.py`.** The five `render_*.py` modules each have `--self-test`, but `run_generator.py` itself (which orchestrates them + runs VERIFY-4a/4b) has no test fixture.
- **The 2 broken citations** `bash .aid/work-001-aid-lite/test-reports/e2e-{two-tier,lite-path}-runner.sh` in `CLAUDE.md:48-49` are not just stale references — they are **untestable claims** (35 + 38 tests = 73 tests inflating the "297 expected" total). See `tech-debt.md` H1. If those scripts existed they would be the only E2E coverage; their absence is the largest single test-coverage gap.
- **No tests for the 4 PowerShell scripts** (`setup.ps1`, `concatenate.ps1`, plus 2 install-tree mirrors). The bash equivalents are tested by `tests/canonical/`; the PowerShell paths are not.
- **No tests for `setup.sh` / `setup.ps1` end-user install flow.** A user installing claude-code+codex+cursor into a target project has no automated verification that the install succeeded.
- **No tests for `canonical/scripts/summarize/*.mjs`** (`validate-diagrams.mjs` 574 lines, `contrast-check.mjs` 151 lines) — JavaScript validators have no Node test harness.
