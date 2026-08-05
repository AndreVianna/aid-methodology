---
kb-category: primary
source: hand-authored
objective: The automated test suites, frameworks, CI lanes, and runnable commands that gate AID's shippable artifacts (the CLI installer, the multi-profile render, the dashboard, and the site).
summary: Read this before writing or changing a test, or before relying on CI — it maps every automated suite to its framework, the single run-all entrypoint (now bounded-parallel with a coverage-parity gate), which lanes run where (and which heavy gates are master-only), the exact commands to run them, and the S1-S5 / T1-T6 conventions for how a suite is structured and when it is run (including change-set selection via `# COVERS:` headers, and why local slowness is process-spawn cost rather than input size).
sources:
  - tests/run-all.sh
  - tests/canonical/
  - tests/canonical/select-suites.sh
  - tests/coverage-parity.sh
  - tests/lib/
  - tests/windows/Test-AidInstaller.ps1
  - .github/workflows/test.yml
  - .github/workflows/installer-tests.yml
  - .github/workflows/release.yml
  - .github/workflows/docs.yml
  - .github/workflows/coverage-parity.yml
  - dashboard/reader/tests/
  - dashboard/server/tests/
  - .claude/skills/generate-profile/scripts
tags: [C6, testing, coverage, frameworks, ci, gaps]
see_also: [quality-gates.md, technology-stack.md, infrastructure.md, tech-debt.md]
owner: developer
audience: [developer, architect]
intent: |
  The automated test landscape: frameworks, the canonical helper suites, installer
  tests, CI lanes (test/docs/installer-tests/release), the WinPS 5.1 compat lane,
  render-drift, and where heavy gates run. Read before writing or modifying tests.
contracts:
  - "tests/run-all.sh discovers suites by glob tests/canonical/test-*.sh — adding a suite needs no runner edit"
  - "Every canonical suite runs under `timeout 300` in an isolated bash process"
  - "node and pwsh must be present in CI or environment-dependent suites silently skip (CI fails loudly if absent)"
  - "A suite with no `# COVERS:` header is treated by select-suites.sh as covering EVERYTHING and is always selected — forgetting the header costs time, never coverage"
  - "select-suites.sh is not itself a counted suite: its name falls outside the tests/canonical/test-*.sh glob, so run-all.sh never runs it"
  - "A suite never mutates the source tree: mutation runs operate on a copy in mktemp -d and assert the subject is byte-identical to HEAD afterwards (S5)"
changelog:
  - 2026-08-05: work-005 test-strategy update -- added the S1-S5 suite-authoring and T1-T6 run-cadence conventions and the `select-suites.sh` / `# COVERS:` change-set selection mechanism; documented the measured cause of local suite slowness (a process spawn costs ~105-137ms against ~3.4ms for a bash builtin, so wall time tracks spawn count rather than input size, with Defender-without-exclusions as the amplifier); corrected the canonical suite count 134 -> 144 and split the two quantities that had been conflated into a single self-contradicting `134` (live total vs pre-work-024 total).
  - 2026-07-30: work-001 final gate -- corrected the `docs.yml` CI-lane row (closing KI-007 / W1-4). It omitted the `canonical/**` path filter, carried a `release: published` trigger the workflow does not have, and answered "feature branches? No -- master only" although `pull_request` to master is live and is the site's test gate. Re-verified against the `on:` block and dated the CONFIRMED claim. Split the master-only gotcha so the site is stated as the exception it is.
  - 2026-07-30: work-001 delivery-006 gate -- corrected the stale shortcut counts in the body; restored the 1.3 Change Log row, which an earlier pass in this same cycle had edited (falsifying a dated audit record).
  - 2026-06-25: Initial discovery (aid-discover quality deep-dive)
---

# Test Landscape

This document covers AID's **automated** checks — the test suites and CI lanes that
machine-verify the shippable artifacts. The **methodology's** review/grade gates (the
A-grade gating, the reviewer ledger, per-phase REVIEW loops) are a separate concern and
live in `quality-gates.md`.

## Contents

- [How AID Is Tested](#how-aid-is-tested)
- [Test Framework Inventory](#test-framework-inventory)
- [The Canonical Helper Suites](#the-canonical-helper-suites)
- [Installer Tests (Linux + Windows)](#installer-tests-linux--windows)
- [CI Lanes and Where They Run](#ci-lanes-and-where-they-run)
- [The WinPS 5.1 Compat Lane](#the-winps-51-compat-lane)
- [Render-Drift and Generator Self-Tests](#render-drift-and-generator-self-tests)
- [Coverage Assessment](#coverage-assessment)
- [Test Data Strategy](#test-data-strategy)
- [Known Test Gaps](#known-test-gaps)
- [Test Commands](#test-commands)
- [Performance & Health](#performance--health)
- [Suite Authoring (S1-S5) and Run Cadence (T1-T6)](#suite-authoring-s1-s5-and-run-cadence-t1-t6)
- [Change Log](#change-log)

---

## How AID Is Tested

AID is not a runtime application, so there is no "unit test the business logic" story. The
shippable product is the **rendered install trees + the `aid` CLI installer + the
dashboard + the marketing site**. Testing therefore protects four things, in priority
order (stated in `.github/workflows/test.yml` header comment):

1. that committed `profiles/` stays byte-in-sync with `canonical/` (the core invariant);
2. the runtime helper scripts adopters depend on (the bash + node + Python suites);
3. the generator/build system itself (the Python self-tests);
4. cheap repo/KB hygiene (CRLF, gitignore, INDEX freshness, frontmatter).

CONFIRMED. Prompt-driven skills, the `aid-reviewer` semantic review, and `aid-summarize`'s
human visual gate require an AI host + human and are deliberately **not** machine-gated
(see `.github/workflows/test.yml` header — "dogfooding").

---

## Test Framework Inventory

There is no single off-the-shelf test framework. AID uses bespoke harnesses per language
because it must validate Bash, PowerShell, Python, and Node code paths.

| Framework / harness | Type | Location | Notes |
|---|---|---|---|
| Bespoke Bash test harness | Unit + integration | `tests/canonical/test-*.sh` (144 suites) | The dominant suite; run via `tests/run-all.sh`. CONFIRMED 2026-08-05 via `ls tests/canonical/test-*.sh \| wc -l` = 144. Re-run that command rather than trusting this number: it has been stale in this document twice. |
| Bespoke PowerShell test (`T<NN>` IDs) | Installer integration | `tests/windows/Test-AidInstaller.ps1` (~2406 lines) | Windows-only; not in `run-all.sh`. |
| `pytest` | Unit | `dashboard/reader/tests/`, `dashboard/server/tests/` | Python reader/server parsers + fixtures. |
| Node built-in test | Unit | `dashboard/server/tests/test_server_node.mjs` | Node `.mjs` server tests. |
| Playwright (Chromium, headless) | Visual fidelity (E2E render) | `.claude/aid/scripts/summarize/validate-visuals.mjs` | Validates `kb.html` authored visuals; gated in CI. |
| Generator `--self-test` harness | Self-test | `.claude/skills/generate-profile/scripts/*.py` | `render_lib`, `render`, `verify_deterministic`, `verify_advisory`, `test_manifest_safety`. |
| Astro / TypeScript tests | Unit | `site/src/data/__tests__/`, `site/scripts/__tests__/` | Site data + docs-sync tests (separate build). |

Of the 144 live suites, **132 are the surviving pre-existing suites** — the AC-2 must-pass
set, being the 134 that predated work-024 minus the 2 dead suites it removed. The other 12
were added since: work-024's `test-coverage-parity.sh` and work-001's `test-skill-counts.sh`
(the repo-wide count guard), `test-shortcut-builder-invariants.sh`, and work-005's **nine**
`test-graph-*.sh` suites.

> **Read the count as of a date, not as a fact.** The two numbers above were previously
> written as a single `134`, used simultaneously as the live total AND as the pre-work-024
> total — a pair that cannot both be true, which is how the staleness went unnoticed through
> two refreshes. They are different quantities and are now named separately.

CONFIRMED via `.aid/generated/project-index.md` (Top-20 Largest Source Files lists
`reader.mjs` 4012, `test-aid-cli-parity.sh` 3198, `Test-AidInstaller.ps1` 2406) and direct
directory listing.

---

## The Canonical Helper Suites

`tests/run-all.sh` is the single "run all tests" entrypoint shared by CI and local
development, so a contributor runs the exact same gate locally before pushing.

Key behaviors (CONFIRMED in `tests/run-all.sh`):

- **Glob discovery.** Suites are discovered by `tests/canonical/test-*.sh` — adding a suite
  requires no edit to the runner.
- **Isolation + timeout, now parallel.** Each suite runs under `timeout 300` in its own bash
  process; `run-all.sh` dispatches independent suites under bounded parallelism
  (`xargs -P $(nproc)`) to per-suite `.log`/`.rc` files, then replays them single-threaded —
  the isolation and the exact aggregate contract are preserved either way. `AID_TEST_JOBS=1`
  restores serial ordering for debugging. See [Performance & Health](#performance--health).
- **Exec-bit fix.** The repo is authored on Windows (committed `100644`); the runner
  `chmod +x`'s `canonical/aid/scripts` and `tests/canonical` `.sh` files first (idempotent).
- **Exit contract.** Exit 0 only if every suite passes; exit 1 if any suite fails (or if no
  suites are found). Under CI it emits `::group::` / `::error::` annotations.

Representative suite families (the 144 cover far more than these):

| Family | Example suites | What they protect |
|---|---|---|
| Installer / CLI | `test-install.sh`, `test-install-ps1.sh`, `test-install-parity.sh`, `test-aid-cli.sh`, `test-aid-cli-ps1.sh`, `test-aid-cli-parity.sh` | bash↔PowerShell behavior parity |
| Release / packaging | `test-release.sh`, `test-release-install-e2e.sh`, `test-release-migrate-smoke.sh`, `test-version-sync.sh`, `test-npm-installer.sh`, `test-pypi-installer.sh` | the 3 publish channels + version-sync |
| KB / discovery engine | `test-kb-citation-lint.sh`, `test-frontmatter-lint.sh`, `test-build-kb-index.sh`, `test-closure-check.sh`, `test-harvest-coined-terms.sh`, `test-spine-depth-coverage.sh`, `test-dual-intent-self-eval.sh` | the discovery/KB tooling |
| Pipeline / execute | `test-writeback-state.sh`, `test-complexity-score.sh`, `test-compute-block-radius.sh`, `test-delivery-gate-aggregate.sh`, `test-grade.sh` | state writeback + delivery gating |
| Shortcut / Lite path (work-001, +v2.1.0 follow-on) | `test-catalog-dirs-parity.sh`, `test-triage-routing.sh`, `test-describe-full-only.sh`, `test-cutover-no-dangling.sh`, `test-deploy-monitor-repurpose.sh`, `test-executor-graph-flat-plan.sh`, `test-shortcut-engine-contract.sh`, and the six `test-*-family-scaffold.sh` suites (`create`, `change-refactor`, `fix`, `document`, `prototype`, `test-experiment`) | the 34 verb-first shortcut skills, the shortcut engine's GATE/APPROVAL-HALT batching (`test-shortcut-engine-contract.sh` SEC00–SEC07), `/aid-triage` routing, the recipe-removal cutover (no dangling `recipes/`/`parse-recipe.sh`), `/aid-describe` full-only, and the flattened Lite work layout. The 5 families the v2.1.0 follow-on added (`remove`, `deprecate`, `migrate`, `review`, `research`) have no dedicated `test-*-family-scaffold.sh` of their own yet, and neither does the `analyze-report` scaffolding family — all six are covered by `test-catalog-dirs-parity.sh`'s count-agnostic catalog↔dirs parity check instead. |
| Dashboard | `test-dashboard-reader.sh`, `test-dashboard-parity.sh`, `test-dashboard-parity-h.sh`, `test-aid-dashboard-cli.sh` | reader/server parity |
| Connectors / reconcile | `test-connector-registry.sh`, `test-connectors-registry-integration.sh`, `test-build-connectors-index.sh`, `test-connector-secret.sh`, `test-connector-secret-ps1.sh`, `test-connector-secret-ac3-leak-sweep.sh` (security: no-leak sweep of AC-3), `test-connector-twins-ps1-parity.sh` (bash↔PowerShell twin parity), `test-reconcile-scenarios.sh` | the `.aid/connectors/` catalog + INDEX generation, registry accessor integration, no-echo/path-confined secret handling, and settings reconcile behavior |
| Compat / hygiene | `test-ps51-compat.sh`, `test-ascii-only.sh`, `test-payload-size.sh`, `test-multitool-isolation.sh`, `test-dogfood-byte-identity.sh` | portability + content isolation |

CONFIRMED by direct listing of `tests/canonical/`.

---

## Installer Tests (Linux + Windows)

The installer + `aid` CLI ship as both Bash (`install.sh`) and PowerShell (`install.ps1`)
and must work on real Linux/macOS **and** real Windows. `.github/workflows/installer-tests.yml`
splits coverage by OS:

| OS lane | Mode | What runs |
|---|---|---|
| `ubuntu-latest` | `bash-harness` | A curated subset of installer/CLI/release suites: `test-install`, `test-install-ps1`, `test-install-parity`, `test-aid-cli`, `test-aid-cli-ps1`, `test-aid-cli-parity`, `test-release`, `test-release-install-e2e`, `test-npm-installer`, `test-pypi-installer`. |
| `windows-latest` | `native-ps1` | `tests/windows/Test-AidInstaller.ps1` under both `pwsh` (7) and `powershell` (5.1); plus a dashboard-CLI smoke and npm + PyPI channel Windows smoke tests (pack/build → install → `aid status` / `aid add`). |

CONFIRMED in `.github/workflows/installer-tests.yml` (the `installer` matrix job). The bash
harness is deliberately **not** run on Windows to avoid Git-Bash path issues (stated in the
workflow header).

`tests/windows/Test-AidInstaller.ps1` runs **only** on the Windows CI lane; it is NOT
discovered by `tests/run-all.sh`. A green local `run-all.sh` does not exercise it — see
[Known Test Gaps](#known-test-gaps).

---

## CI Lanes and Where They Run

AID has five GitHub Actions workflows. The **canonical** correctness gates (`test.yml`) run on
`master` and release tags only, so a branch with no open PR gets the installer matrix instead.
**`docs.yml` is the exception** — it also gates pull requests to `master`, and its `build` job
runs the site vitest suite. Read the per-lane rows below rather than generalising from this
sentence; the exception is the whole reason KI-007 was raised against an earlier version of it.

| Workflow | Trigger | Jobs / gates | Runs on feature branches? |
|---|---|---|---|
| `.github/workflows/test.yml` (CI) | push + PR to `master`; `workflow_dispatch` | `render-drift`, `canonical-tests` (full `run-all.sh`), `visual-fidelity` (Playwright), `generator-selftests`, `kb-hygiene` | No — master only |
| `.github/workflows/installer-tests.yml` (Installer CI) | push to any branch **except** master (`branches-ignore: [master]`); `workflow_dispatch` | cross-platform installer/CLI/release matrix (ubuntu + windows) | Yes — feature branches only |
| `.github/workflows/release.yml` (Release) | push of a `v*` tag; `workflow_dispatch` | `gate` (re-runs render-drift + version-sync + full `run-all.sh` + generator self-tests on the tagged commit), then `github-release`, `npm-publish`, `pypi-publish` | No — tag only |
| `.github/workflows/docs.yml` (Docs) | push **and `pull_request`** to `master`, both path-filtered to `site/**`, `docs/**`, `canonical/**`, `VERSION`, or the workflow; `workflow_dispatch` | `npm ci` → **`npm test` (site vitest suite)** → Astro Starlight build; then GitHub Pages deploy (`deploy` job skipped on PRs) | **Yes, as a PR to master** — the build+test job is a live PR gate; only the `deploy` job is master-only |
| `.github/workflows/coverage-parity.yml` (Coverage Parity) | push + PR to `master`, path-filtered to `tests/**`; `workflow_dispatch` | Separate lane from `canonical-tests`: serially re-collects the executed-assertion inventory (~6-7 min) and diffs it against a committed baseline — advisory (warns, exits 0) until the baseline is bootstrapped, then enforces | No — master only (+ path filter) |

CONFIRMED by the `on:` blocks of each workflow — re-verified 2026-07-30 against
`.github/workflows/docs.yml`:10-29 (the whole `on:` block: `push`, `pull_request`,
`workflow_dispatch`), which has no `release:` key.

**Why this matters (gotcha).** The full canonical suite (test.yml) runs only on `master` and on
release tags (release.yml `gate`). A branch that has **no open PR to master** sees only
`installer-tests.yml`, so a change that breaks the canonical suite can pass all its checks and
only fail after merge. Run `bash tests/run-all.sh` (HOME-pinned) before claiming green.

**The site is the exception, and it is a PR gate.** `docs.yml` also triggers on
`pull_request` to `master` (delivery-001 of work-001 added the `npm test` step, closing KI-006),
so the site vitest suite **and** the Astro build do validate every PR that touches `site/**`,
`docs/**`, `canonical/**` or `VERSION`. Only the `deploy` job is master-only. Two consequences a
maintainer needs: a **canonical-only** commit still rebuilds the site, because the reference pages
and skill-page anchors are derived from `canonical/`; and the site suite is what catches a
`canonical/` edit that breaks *generated site content* — a drifted skill roster, a stale count, a
dangling deep-link anchor.

**It does NOT catch `canonical/` → `profiles/` render drift.** That is a different gate in a
different workflow: `test.yml`'s `render-drift` job, which re-runs
`.claude/skills/generate-profile/scripts/run_generator.py` and asserts `git diff --exit-code --
profiles/`. `site/` never reads `profiles/` at all, so the site build cannot observe that drift.
Both facts matter and they are easy to conflate; see `tech-debt.md` § Gotchas, "Master-only heavy
gates".

**CI must not silently skip.** Both `test.yml` (`canonical-tests`) and `release.yml`
(`gate`) assert `node` and `pwsh` are present and fail loudly if either is missing — because
the `.mjs` and `*-ps1` suites `exit 0` (skip) when their runtime is absent, which would be a
false green in CI. CONFIRMED in the "Assert test runtimes present" step.

---

## The WinPS 5.1 Compat Lane

AID advertises "PowerShell 5.1+", and a fresh Windows box ships Windows PowerShell 5.1
(not pwsh 7). Two complementary checks guard this:

1. **Static lint** — `tests/canonical/test-ps51-compat.sh` (in `run-all.sh`, so it runs in
   the master CI). It AST-lints the shipped `.ps1`/`.psm1` for 5.1 breaks that
   PSScriptAnalyzer misses: 3-arg `Join-Path`, `-Encoding utf8NoBOM`, `$IsWindows`, missing
   TLS 1.2, non-ASCII in no-BOM `.ps1`. CONFIRMED via `tests/canonical/ps51-compat-check.ps1`
   (the lint engine the suite drives).
2. **Runtime lane** — in `.github/workflows/installer-tests.yml`, the `native-ps1` job
   re-runs `Test-AidInstaller.ps1` under `shell: powershell` (real 5.1) in addition to
   `shell: pwsh` (7), to catch runtime 5.1 breaks (BOM divergence, TLS handshake,
   FileSystem-provider semantics) that static analysis cannot.

CONFIRMED. `test-ascii-only.sh` separately enforces ASCII-only shipped installer/CLI scripts
(Windows decodes no-BOM UTF-8 in the ANSI codepage and mis-parses non-ASCII).

---

## Render-Drift and Generator Self-Tests

The single most load-bearing gate is **render-drift**: it proves the committed `profiles/`
trees are exactly what the generator produces from `canonical/`.

- **Render-drift** (`test.yml` `render-drift` job, mirrored in `release.yml` `gate`): runs
  `python .claude/skills/generate-profile/scripts/run_generator.py`, then
  `git diff --exit-code -- profiles/`. Any drift fails the build with a remediation message.
  It first sets `git config core.fileMode false` so spurious exec-bit diffs do not trip it.
- **Generator self-tests** (`test.yml` `generator-selftests` job): five Python
  `--self-test` invocations — `render_lib.py`, `test_manifest_safety.py`, `render.py`,
  `verify_deterministic.py`, `verify_advisory.py`.
- **Visual fidelity** (`test.yml` `visual-fidelity` job): installs Playwright + Chromium and
  runs `validate-visuals.mjs` against `.aid/knowledge/kb.html`. It **gracefully degrades** —
  exits 0 with a SKIP if `kb.html` or the validator is absent (the gate only fires once a
  summary has been generated).

CONFIRMED in `.github/workflows/test.yml`.

---

## Coverage Assessment

There is **no line-coverage metric and no coverage threshold** anywhere in the pipeline, and
that specific choice is deliberate (see `decisions.md` **D26**): the shippable product is
overwhelmingly non-line-instrumentable (~1800 Markdown/prompt files + ~327 shell/PowerShell
installer files + a byte-identical multi-profile render), so a coverage `%` would instrument
only the small minority (`dashboard/reader` Python, `dashboard/server/reader.mjs`, `site/`
TypeScript) and report a misleadingly precise number that ignores the bulk of the product.

What remains today is **suite-presence per subsystem** (the table below) — but that has proven
**insufficient on its own**: the `io_bounds.py` incident showed suites can pass without
*biting* (five manifests asserted each other while all were stale). Measuring test-suite
**effectiveness** for the deterministic machinery — via **mutation testing, invariant-anchoring,
behavioral-surface coverage, and escaped-defect tracking** (dogfooding covers the prompt layer)
— is a committed **High-priority, next-release** program tracked as **tech-debt L4**. Until it
lands, suite-presence + dogfooding is the floor, not the target.

| Subsystem | Test health | Evidence |
|---|---|---|
| `aid` CLI + installer (bash) | Strong | `test-aid-cli.sh`, `test-install.sh`, parity suites, release-install E2E |
| `aid` CLI + installer (PowerShell) | Strong (Windows-CI only) | `Test-AidInstaller.ps1` under 5.1 + 7 |
| Profile renderer / generator | Strong | render-drift + 5 self-tests + `test-assemble-determinism.sh` |
| Discovery / KB engine | Strong | ~20 `test-*` suites (closure, harvest, citation/frontmatter lint, dual-intent, spine-depth) |
| Pipeline execute / state writeback | Strong | `test-writeback-state.sh`, `test-delivery-gate-aggregate.sh`, `test-complexity-score.sh` |
| Shortcut engine / Lite path | Strong | catalog↔dirs parity, `/aid-triage` routing, the seven family-scaffold suites, `test-shortcut-engine-contract.sh` (`SEC00`–`SEC07`) engine/gate/halt contract, flat-plan execution graph, recipe-removal cutover, describe-full-only |
| Dashboard reader/server | Strong | pytest suites + parity suites |
| Astro site | Moderate | `site/src/data/__tests__`, `site/scripts/__tests__`; build is the main gate |
| Prompt-driven skill state machines | Not machine-tested (by design) | dogfooding + human/AI review only |

**Coverage target:** not defined. **Coverage enforcement:** not enforced (no `%` gate).
CONFIRMED — no coverage tool (`nyc`, `coverage.py`, `--cov`) is invoked in any workflow.

---

## Test Data Strategy

| Approach | Used? | Notes |
|---|---|---|
| Fixtures | Yes | `tests/canonical/fixtures/` holds curated inputs (e.g. `kb-essence/calibration/`, `closure-check/`, `teachback-questions/`). The `PaymentEngine` / `Settlement Batch` / `ReconciliationCycle` terms in `.aid/generated/candidate-concepts.md` are these **test fixtures**, not AID product concepts. |
| Temp-dir isolation | Yes | Suites build throwaway `$AID_HOME` / target dirs via `mktemp -d`; installer tests pin a throwaway `HOME`. |
| Determinism fixtures | Yes | `test-assemble-determinism.sh`, `verify_deterministic.py` assert byte-identical output. |
| Mocks / network stubs | Mostly avoided | Release/publish suites build real tarballs/wheels locally; npm/PyPI publish is OIDC and not exercised in unit tests. |

**HOME-pinning hazard (gotcha).** The migration scan defaults its root to `$HOME`; any suite
firing it must `export HOME=<throwaway>` (not just `AID_HOME`) or it migrates the developer's
real repos. Also: CI checks out the repo (with its own `.aid/`) under `$HOME`, so isolation
canaries that scan `REAL_HOME` for `.aid` must snapshot before/after. See `tech-debt.md`.

---

## Known Test Gaps

| Area | Gap | Risk | Recommendation |
|---|---|---|---|
| Windows installer | `Test-AidInstaller.ps1` runs only on Windows CI, never in `run-all.sh` | Medium | CLI behavior changes must migrate this test too; a green local `run-all.sh` does not cover it. |
| Canonical suite on feature branches | Full `run-all.sh` runs on master/tag only | Medium | Run `bash tests/run-all.sh` + `site` build locally before merge. |
| Test-suite effectiveness | No line-coverage (deliberate, D26) AND no effectiveness measure for the deterministic machinery | **High** | Tracked as **tech-debt L4** (P1, next release): mutation testing + invariant-anchoring + behavioral-surface + escaped-defect ledger (dogfooding already covers the prompt layer). |
| Prompt-driven skills | State machines not machine-tested | Accepted (by design) | Covered by dogfooding + AI/human review; not automatable here. |
| Web-output review | Source inspection is not a valid review of rendered pages | High (process) | Any review touching `kb.html` / site MUST visually validate via Playwright (the `visual-fidelity` gate + reviewer rule). |

---

## Test Commands

Exact runnable commands (CONFIRMED against `tests/run-all.sh` and the workflows):

```bash
# Run the full canonical suite (the master-CI gate). Pin HOME to avoid scanning real repos.
HOME="$(mktemp -d)" bash tests/run-all.sh

# Verbose (pass --verbose through to each suite)
bash tests/run-all.sh -v

# Run one suite directly
bash tests/canonical/test-aid-cli.sh

# Render-drift check (must show no diff under profiles/)
python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/

# Generator unit self-tests (the generator-selftests CI job)
python .claude/skills/generate-profile/scripts/render_lib.py --self-test
python .claude/skills/generate-profile/scripts/test_manifest_safety.py --self-test
python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .
python .claude/skills/generate-profile/scripts/verify_deterministic.py --self-test --canonical-root .
python .claude/skills/generate-profile/scripts/verify_advisory.py --self-test --canonical-root .

# Visual-fidelity gate (requires a generated .aid/knowledge/kb.html)
node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html

# Version-sync assertion (the release gate)
bash canonical/aid/scripts/release/check-version-sync.sh --expect "$(tr -d '[:space:]' < VERSION)"

# Windows installer test (Windows host only; not in run-all.sh)
pwsh -NoProfile -File tests/windows/Test-AidInstaller.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/windows/Test-AidInstaller.ps1   # 5.1 lane

# Python dashboard tests
python -m pytest dashboard/reader/tests dashboard/server/tests

# Astro site build (the docs.yml gate)
cd site && npm ci && npm run build
```

> Note: when editing `canonical/` and re-checking render-drift, run the FULL
> `run_generator.py` (not a per-script renderer) or the drift check fails on stale emission
> manifests. See `tech-debt.md` Gotchas.

---

## Performance & Health

The `canonical helper suites` CI job's speed and hermeticity are tracked here so a future
change does not re-diagnose the same slowness (work-024-test-suite-improvement).

**Performance contract.** The job is committed to **≤ 3 minutes**, with a **~60–90s goal**
(NFR-1) — down from a **~690s (~11.5 min)** baseline (master CI run `29975142862`) before
work-024. 690s is retained only as a load-bearing before-state inflection marker; the exact
post-optimization wall-clock is not frozen here (it drifts) — the ≤3 min / ~90s contract is.

**Optimizations landed:**

| Area | What changed | Where |
|---|---|---|
| Parallel runner | `run-all.sh` dispatches independent suites under bounded parallelism (`xargs -P $(nproc)`) to per-suite `.log`/`.rc` files, then replays them single-threaded — preserving the exact aggregate contract (glob discovery, per-suite `timeout 300`, `::group::`/`::error::` folding, PASS/FAIL summary, nonzero exit on any failure). `AID_TEST_JOBS=1` restores serial ordering for debugging. | `tests/run-all.sh` |
| Hermeticity / port isolation | Each suite run uses a unique per-run temp dir; port-binding suites allocate an ephemeral port via a bounded pick→bind→verify retry, so concurrent suites cannot collide. | `tests/lib/net.sh` (`find_free_port`, `wait_for_port`) |
| Coverage-parity gate | A before/after multiset inventory of executed assertion IDs; fails mechanically on any un-excused net-removed/reduced assertion, so suites can be optimized without silently losing coverage. Lives at the `tests/` root, outside the `tests/canonical/test-*.sh` glob — not itself a counted suite. | `tests/coverage-parity.sh` (`collect`/`diff`) |
| Shared helpers | pwsh detection, the HOME escape-canary, and free-port logic live once and are sourced by every suite that needs them — no machine-specific absolute path remains in `tests/`. | `tests/lib/pwsh.sh`, `tests/lib/sandbox.sh`, `tests/lib/net.sh` |
| Hot-suite: byte-identity | Verifies the same three directions via a single manifest pass + batched hashing instead of repeated re-scans. | `test-dogfood-byte-identity.sh` |
| Hot-suite: CLI parity | Batches its pwsh invocations through one long-lived responder session instead of one cold start per assertion. | `test-aid-cli-parity.sh` |

### Why suites are slow on a Windows dev shell: process spawn cost

CI is not where this bites — it is the local edit/verify loop, and the cause is neither
algorithmic nor input-size-dependent.

**A process spawn costs ~30x a shell builtin on a Windows/MSYS shell.** Measured
2026-08-05, 50 iterations each, against a **three-line** input so no figure includes real
work:

| Command | ms per spawn | Command | ms per spawn |
|---|---|---|---|
| `sort` | 105.7 | `tr` | 120.1 |
| `cut` | 106.7 | `grep` | 136.5 |
| `wc` | 114.4 | `awk` | 137.5 |
| **bash parameter expansion** | **3.4** | | |

The consequence: **suite wall time tracks the number of external processes started, not the
size of the input.** `canonical/aid/scripts/graph/scan-source.sh` scanning a *two-file*
repository takes ~9.8s, flat across runs, of which ~8.4s is ~100 external spawns. A
`bash -x` trace of that run shows 1,734 command lines, but ~1,634 are cheap builtins — so
**count the spawns, not the traced lines**, when diagnosing this.

**Two independent levers, and the larger one is not code:**

1. **Antivirus exclusions (environment, no code change).** Defender real-time protection
   scans each process image at creation. On the machine measured above,
   `Get-MpComputerStatus` reported real-time protection enabled with `ExclusionPath`
   holding a single empty entry — no exclusions — while `C:\Program Files\Git\usr\bin`
   holds 249 executables that every pipeline stage relaunches. Excluding the repo root and
   the Git/node toolchain is the highest-leverage change available and needs no test edit.
   Measure before and after rather than assuming a figure.
2. **Fold pipelines (code).** In `scan-source.sh` the spawn budget was `sort` 23,
   `awk` 14, `tr` 10, `wc` 6, `cut` 5, `grep` 5. Dedup-only sorts become
   `awk '!seen[$0]++'` (no spawn); consecutive `awk` stages fold into one program;
   `wc`/`cut`/`grep` fold into a neighbouring pass; `dirname`/`realpath` become `${p%/*}`.
   Keep `xargs` — it *is* the batching mechanism — and keep `mv` for atomic writes.

**Measured full-set baseline for the work-005 graph suites** (2026-08-05, all passing;
1,150 assertions, ~460s total). Useful as the reference for what "slow" means here:

| Suite | Wall | Assertions | s / assertion |
|---|---|---|---|
| `test-graph-relationship-validator.sh` | 196s | 121 | 1.62 |
| `test-graph-gap-ledger.sh` | 79s | 303 | 0.26 |
| `test-graph-source-enumeration.sh` | 73s | 189 | 0.39 |
| `test-graph-schema-loader.sh` | 58s | 211 | 0.27 |
| `test-graph-view.sh` | 29s | 119 | 0.24 |
| `test-graph-skill-registration.sh` | 25s | 207 | 0.12 |

---

## Suite Authoring (S1-S5) and Run Cadence (T1-T6)

These are conventions for **writing** a suite and for **when to run** it. They exist because
of the spawn cost measured above: a habit that costs 100 ms per assertion is invisible on
Linux CI and dominates the local loop.

### S1-S5 — how a suite is structured

| # | Rule | Why |
|---|---|---|
| **S1** | Invoke each subject **once per distinct input**, never once per assertion group. Build the fixture once, run the pipeline once into a cached output dir, assert many times against those files. Declare the invocation count in the suite header. | Each subject invocation is a fixed ~10s toll before any assertion is evaluated. |
| **S2** | Load subject output into memory in **one pass** (`while IFS= read -r`, or one `awk` pass emitting a digest) into bash arrays, then assert with `[[ ]]` and `${var}` string ops. **No command substitution per assertion**, no per-assertion `grep`/`awk`/`cut`/`wc`. | Measured: 300 command substitutions **20.7s**; 300 builtin calls **0.16s**. |
| **S3** | Put the mutation matrix behind an explicit flag (`--self-mutate`). Default (no args) runs assertions only, so CI pays one pass. | A mutation matrix is N full suite runs. See `test-graph-source-enumeration.sh` for the pattern. |
| **S4** | **Never trade coverage for time.** If an assertion genuinely needs its own subject invocation, keep it and say so in the header. Report before/after wall time *and* before/after invocation count when optimizing. | The `tests/coverage-parity.sh` gate exists because optimization is exactly when coverage silently disappears. |
| **S5** | Mutate a **copy** in a `mktemp -d`, never the source tree, and assert the subject is byte-identical to `HEAD` afterwards. | A live mutation in a production script with a normal exit code is indistinguishable from a passing run. |

### T1-T6 — when a suite is run

| # | Rule |
|---|---|
| **T1** | The suite is authored **before or alongside** the mechanism and committed with it — never bolted on afterwards. |
| **T2** | Between edits, verification is **spawn-free**: `bash -n` / `node --check` for parse, plus a static grep for the invariant just changed. **A suite run is not a per-edit check.** |
| **T3** | **One focused run per milestone** (a feature, or one coherent mechanism): `select-suites.sh --run`. |
| **T4** | **One full run per deliverable**: `select-suites.sh --all --run`, plus `--self-mutate` on suites that carry a mutation matrix. |
| **T5** | The dispatch brief **declares a ceiling** on full-suite runs; the final report **states the actual count** per suite. |
| **T6** | Debug at the smallest granularity — re-run the **failing assertion group**, not the suite. This makes a group filter a design requirement on every suite, not a nicety. |

> **T5 is auditable, not an honour system.** Per-suite invocation counts are recoverable from
> an agent's own tool calls. This is how a single work-005 builder was found to have run one
> suite **33 times** and five suites it did not own **19 times** between them, against a
> sibling's 8 — a difference invisible in either final report.

### Running only the suites a change can affect

`tests/canonical/select-suites.sh` maps a change set to the suites that declare coverage of
it. Suites opt in with a manifest block in their header:

```bash
# COVERS: canonical/aid/scripts/graph/scan-source.sh
# COVERS: canonical/aid/templates/graph/
```

A trailing slash means the directory and everything under it. The matcher spawns no process:
one read per suite, matched with parameter expansion.

**The design is fail-safe in the direction that matters.** A suite with **no** `COVERS`
header is treated as covering everything and is **always selected**, so forgetting the header
can only cost time, never coverage. The single way to lose coverage is a **wrong** entry —
which is a reviewable one-line claim sitting in the suite it describes. Selection prints its
complement too: a selection whose complement you cannot see is a coverage claim you cannot
audit.

Like `tests/coverage-parity.sh`, this helper is **not** itself a counted suite — its name
falls outside the `tests/canonical/test-*.sh` glob, so `run-all.sh` never runs it.

```bash
# suites affected by the current working-tree change set
bash tests/canonical/select-suites.sh

# ...and run them (T3)
bash tests/canonical/select-suites.sh --run

# every suite, for a deliverable-end run (T4)
bash tests/canonical/select-suites.sh --all --run

# restrict the candidate set while the repo-wide rollout is incomplete
bash tests/canonical/select-suites.sh --glob 'test-graph-*.sh' --run
```

**Rollout status (the limit on the payoff).** Only work-005's committed graph suites carry a
`COVERS` header today. The remaining ~135 suites have none, so they are all selected
fail-safe on any change and `--glob` is currently needed to keep selection useful. Promoting
`COVERS` across `tests/canonical/` is what makes this pay off repo-wide; until then the
mechanism is correct but narrow. Tracked in `tech-debt.md`.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial test-landscape analysis (quality deep-dive) |
| 1.1 | 2026-07-09 | aid-housekeep | connectors subsystem + release-drift refresh (housekeep KB-DELTA) |
| 1.2 | 2026-07-09 | work-001 lite-skills refresh | Corrected canonical suite count 105 → 118 (verified `ls tests/canonical/test-*.sh \| wc -l`); added the Shortcut / Lite path suite family and Coverage row (catalog↔dirs parity, triage routing, the seven family-scaffold suites, GATE/APPROVAL-HALT batching, flat-plan graph, recipe-removal cutover, describe-full-only). |
| 1.3 | 2026-07-09 | v2.1.0 skill-count sync | Updated the Shortcut / Lite path row to the current 76 verb-first shortcuts (up from 67); noted the 5 new families (remove, deprecate, migrate, review, research) are covered by `test-catalog-dirs-parity.sh`'s count-agnostic check, with no dedicated family-scaffold suite of their own yet. Canonical suite count unchanged at 118. |
| 1.5 | 2026-08-05 | work-005 test-strategy update | Added **Suite Authoring (S1-S5) and Run Cadence (T1-T6)** — how a suite is structured (one subject invocation per distinct input; one in-memory load then builtin assertions; mutation behind `--self-mutate`; never trade coverage for time; mutate a copy and prove the tree untouched) and when it is run (spawn-free per-edit checks, one focused run per milestone, one full run per deliverable, a declared and reported run budget, debug at assertion-group granularity). Added the `select-suites.sh` / `# COVERS:` mechanism for running only the suites a change can affect, including its fail-safe direction and its glob exclusion from `run-all.sh`. Extended **Performance & Health** with the measured spawn-cost diagnosis (~105-137ms per spawn vs ~3.4ms per builtin; `scan-source.sh` at ~9.8s on a two-file repo, ~8.4s of it in ~100 spawns; Defender with no exclusions as the amplifier; the two levers, environment before code) and the six-suite baseline (1,150 assertions, ~460s). Corrected the canonical suite count **134 → 144** in three places and **split the two conflated quantities** — the same `134` had been used as both the live total and the pre-work-024 total, a pair that cannot both be true and the reason the staleness survived two refreshes. |
| 1.4 | 2026-07-24 | work-024 test-suite-improvement KB refresh | Corrected canonical suite count 118 → 133 (live total; 132 surviving pre-existing + work-024's own `test-coverage-parity.sh` keystone self-test); removed the dangling reference to feature-006's deleted GATE/APPROVAL-HALT batching suite, re-pointing shortcut-engine coverage to `test-shortcut-engine-contract.sh` (SEC00–SEC07); added the Performance & Health section (bounded-parallel `run-all.sh`, port isolation, coverage-parity gate, shared `tests/lib/` helpers, byte-identity + CLI-parity hot-suite optimizations). |
