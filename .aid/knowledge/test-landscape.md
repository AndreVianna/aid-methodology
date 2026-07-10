---
kb-category: primary
source: hand-authored
objective: The automated test suites, frameworks, CI lanes, and runnable commands that gate AID's shippable artifacts (the CLI installer, the multi-profile render, the dashboard, and the site).
summary: Read this before writing or changing a test, or before relying on CI — it maps every automated suite to its framework, the single run-all entrypoint, which lanes run where (and which heavy gates are master-only), and the exact commands to run them.
sources:
  - tests/run-all.sh
  - tests/canonical/
  - tests/windows/Test-AidInstaller.ps1
  - .github/workflows/test.yml
  - .github/workflows/installer-tests.yml
  - .github/workflows/release.yml
  - .github/workflows/docs.yml
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
changelog:
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
| Bespoke Bash test harness | Unit + integration | `tests/canonical/test-*.sh` (118 suites) | The dominant suite; run via `tests/run-all.sh`. CONFIRMED via `ls tests/canonical/test-*.sh \| wc -l` = 118. |
| Bespoke PowerShell test (`T<NN>` IDs) | Installer integration | `tests/windows/Test-AidInstaller.ps1` (~2406 lines) | Windows-only; not in `run-all.sh`. |
| `pytest` | Unit | `dashboard/reader/tests/`, `dashboard/server/tests/` | Python reader/server parsers + fixtures. |
| Node built-in test | Unit | `dashboard/server/tests/test_server_node.mjs` | Node `.mjs` server tests. |
| Playwright (Chromium, headless) | Visual fidelity (E2E render) | `.claude/aid/scripts/summarize/validate-visuals.mjs` | Validates `kb.html` authored visuals; gated in CI. |
| Generator `--self-test` harness | Self-test | `.claude/skills/generate-profile/scripts/*.py` | `render_lib`, `render`, `verify_deterministic`, `verify_advisory`, `test_manifest_safety`. |
| Astro / TypeScript tests | Unit | `site/src/data/__tests__/`, `site/scripts/__tests__/` | Site data + docs-sync tests (separate build). |

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
- **Isolation + timeout.** Each suite runs under `timeout 300` in its own bash process, so
  one suite cannot leak state into another.
- **Exec-bit fix.** The repo is authored on Windows (committed `100644`); the runner
  `chmod +x`'s `canonical/aid/scripts` and `tests/canonical` `.sh` files first (idempotent).
- **Exit contract.** Exit 0 only if every suite passes; exit 1 if any suite fails (or if no
  suites are found). Under CI it emits `::group::` / `::error::` annotations.

Representative suite families (the 118 cover far more than these):

| Family | Example suites | What they protect |
|---|---|---|
| Installer / CLI | `test-install.sh`, `test-install-ps1.sh`, `test-install-parity.sh`, `test-aid-cli.sh`, `test-aid-cli-ps1.sh`, `test-aid-cli-parity.sh` | bash↔PowerShell behavior parity |
| Release / packaging | `test-release.sh`, `test-release-install-e2e.sh`, `test-release-migrate-smoke.sh`, `test-version-sync.sh`, `test-npm-installer.sh`, `test-pypi-installer.sh` | the 3 publish channels + version-sync |
| KB / discovery engine | `test-kb-citation-lint.sh`, `test-frontmatter-lint.sh`, `test-build-kb-index.sh`, `test-closure-check.sh`, `test-harvest-coined-terms.sh`, `test-spine-depth-coverage.sh`, `test-dual-intent-self-eval.sh` | the discovery/KB tooling |
| Pipeline / execute | `test-writeback-state.sh`, `test-complexity-score.sh`, `test-compute-block-radius.sh`, `test-delivery-gate-aggregate.sh`, `test-grade.sh` | state writeback + delivery gating |
| Shortcut / Lite path (work-001, +v2.1.0 follow-on) | `test-catalog-dirs-parity.sh`, `test-triage-routing.sh`, `test-describe-full-only.sh`, `test-cutover-no-dangling.sh`, `test-deploy-monitor-repurpose.sh`, `test-executor-graph-flat-plan.sh`, `test-shortcut-gate-halt-batching.sh`, and the seven `test-*-family-scaffold.sh` suites (`create`, `change-refactor`, `fix`, `document`, `prototype`, `test-experiment`, `analyze-report`) | the 76 verb-first shortcut skills, the shortcut engine's GATE/APPROVAL-HALT batching, `/aid-triage` routing, the recipe-removal cutover (no dangling `recipes/`/`parse-recipe.sh`), `/aid-describe` full-only, and the flattened Lite work layout. The 5 families the v2.1.0 follow-on added (`remove`, `deprecate`, `migrate`, `review`, `research`) have no dedicated `test-*-family-scaffold.sh` of their own yet — they're covered by `test-catalog-dirs-parity.sh`'s count-agnostic catalog↔dirs parity check instead. |
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

AID has four GitHub Actions workflows. Critically, the heavy correctness gates run on
**master and release tags only** — feature branches get the installer matrix instead.

| Workflow | Trigger | Jobs / gates | Runs on feature branches? |
|---|---|---|---|
| `.github/workflows/test.yml` (CI) | push + PR to `master`; `workflow_dispatch` | `render-drift`, `canonical-tests` (full `run-all.sh`), `visual-fidelity` (Playwright), `generator-selftests`, `kb-hygiene` | No — master only |
| `.github/workflows/installer-tests.yml` (Installer CI) | push to any branch **except** master (`branches-ignore: [master]`); `workflow_dispatch` | cross-platform installer/CLI/release matrix (ubuntu + windows) | Yes — feature branches only |
| `.github/workflows/release.yml` (Release) | push of a `v*` tag; `workflow_dispatch` | `gate` (re-runs render-drift + version-sync + full `run-all.sh` + generator self-tests on the tagged commit), then `github-release`, `npm-publish`, `pypi-publish` | No — tag only |
| `.github/workflows/docs.yml` (Docs) | push to `master` touching `site/**`, `docs/**`, `VERSION`, or the workflow; `release: published`; `workflow_dispatch` | Astro Starlight build → GitHub Pages deploy | No — master only (+ path filter) |

CONFIRMED by the `on:` blocks of each workflow.

**Why this matters (gotcha).** The full canonical suite and the Astro site build run only on
`master` (test.yml / docs.yml) and on release tags (release.yml `gate`). A feature branch
sees only `installer-tests.yml`, so a change that breaks the canonical suite or the site
build can pass all feature-branch checks and only fail after merge to master. Run
`bash tests/run-all.sh` (HOME-pinned) and the `site` build locally before claiming green.
See `tech-debt.md` Gotchas.

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
  runs `validate-visuals.mjs` against `.aid/dashboard/kb.html`. It **gracefully degrades** —
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
| Shortcut engine / Lite path | Strong | catalog↔dirs parity, `/aid-triage` routing, the seven family-scaffold suites, GATE/APPROVAL-HALT batching, flat-plan execution graph, recipe-removal cutover, describe-full-only |
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

# Visual-fidelity gate (requires a generated .aid/dashboard/kb.html)
node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/dashboard/kb.html

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

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial test-landscape analysis (quality deep-dive) |
| 1.1 | 2026-07-09 | aid-housekeep | connectors subsystem + release-drift refresh (housekeep KB-DELTA) |
| 1.2 | 2026-07-09 | work-001 lite-skills refresh | Corrected canonical suite count 105 → 118 (verified `ls tests/canonical/test-*.sh \| wc -l`); added the Shortcut / Lite path suite family and Coverage row (catalog↔dirs parity, triage routing, the seven family-scaffold suites, GATE/APPROVAL-HALT batching, flat-plan graph, recipe-removal cutover, describe-full-only). |
| 1.3 | 2026-07-09 | v2.1.0 skill-count sync | Updated the Shortcut / Lite path row to the current 76 verb-first shortcuts (up from 67); noted the 5 new families (remove, deprecate, migrate, review, research) are covered by `test-catalog-dirs-parity.sh`'s count-agnostic check, with no dedicated family-scaffold suite of their own yet. Canonical suite count unchanged at 118. |
