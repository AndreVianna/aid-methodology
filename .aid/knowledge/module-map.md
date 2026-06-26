---
kb-category: primary
source: hand-authored
objective: Component map of the AID repository -- every major module, its purpose, dependencies, test coverage, and the wiring sequence for adding a new one.
summary: Read this to navigate AID's parts (installer, CLI, canonical toolkit, profile renderer, packages, dashboard, site, tests) and learn how they depend on each other before any module-touching change.
sources:
  - bin/
  - lib/
  - install.sh
  - install.ps1
  - canonical/
  - .claude/skills/generate-profile/scripts/
  - profiles/
  - packages/
  - dashboard/
  - site/
  - tests/
  - canonical/EMISSION-MANIFEST.md
tags: [C2, modules, dependencies, components, wiring, test-coverage]
see_also: [project-structure.md, architecture.md, artifact-schemas.md, integration-map.md]
owner: architect
audience: [developer, architect]
contracts:
  - "canonical/ is the single source of truth; profiles/ and packages/_vendor are rendered/vendored copies"
  - "13 skill directories under canonical/skills/; 9 agent directories under canonical/agents/"
  - "5 render profiles (profiles/*.toml)"
changelog:
  - 2026-06-25: Initial authoring (aid-discover brownfield deep-dive / Analyst)
---

# Module Map

This document maps the parts of the AID repository and how they depend on each
other. AID is not one application -- it is a **toolkit factory** plus the toolkit
it produces. The modules fall into four planes:

1. **Distribution plane** -- how the toolkit reaches a user's machine (installers,
   CLI, install-core, packages, release tooling).
2. **Toolkit plane** -- the AID content itself, authored once in `canonical/`
   (skills, agents, scripts, templates, recipes).
3. **Render plane** -- the profile renderer that mirrors `canonical/` into five
   per-tool `profiles/` trees under an emission-manifest safety boundary.
4. **Observation plane** -- read-only consumers of pipeline state (the dashboard)
   and the standalone marketing/docs website (`site/`).

## Contents

- [Module Inventory](#module-inventory)
- [Dependency Graph](#dependency-graph)
- [Script Modules by Area](#script-modules-by-area)
- [Entry Points](#entry-points)
- [High-Churn Modules](#high-churn-modules)
- [Oversized Modules](#oversized-modules)
- [Conventions](#conventions)
- [Invariants](#invariants)
- [Contracts](#contracts)
- [Gotchas](#gotchas)
- [Change Log](#change-log)

---

## Module Inventory

> Size is qualitative (small/medium/large). Precise line/file counts drift -- run
> `find`/`wc -l` for live numbers (per kb-authoring P1). Test coverage is a health
> assessment, not a percentage.

| Module | Plane | Purpose | Depends on | Size | Test coverage | Notes |
|--------|-------|---------|-----------|------|---------------|-------|
| `install.sh` / `install.ps1` | Distribution | Bootstrap installer; downloads + verifies a release tarball, stages it, installs the CLI to the state-home. | install-core libs | large (`install.sh`) | tested (`tests/canonical/test-aid-cli-parity.sh`, `tests/windows/Test-AidInstaller.ps1`) | Two language twins that must stay behavior-equal. |
| `lib/aid-install-core.sh` | Distribution | Sourceable Bash library of pure install/update/remove functions (copy, manifest, root-agent region update). | none (pure functions) | large | tested (parity + migrate suites) | Largest shell file; no side effects on source. See header `Provides:` block. |
| `lib/AidInstallCore.psm1` | Distribution | PowerShell twin of the install-core library (`#Requires -Version 5.1`). | none | large | tested (`Test-AidInstaller.ps1`, `ps51-compat-check.ps1`) | Must stay WinPS-5.1 compatible (see coding-standards.md). |
| `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd` | Distribution | Persistent `aid` CLI dispatcher: parses subcommands (`update`, `remove`, `dashboard`, ...) and calls install-core. | install-core libs | medium | tested (cli-parity, registry) | `aid.cmd` is a thin cmd.exe shim over `aid.ps1`. |
| `release.sh` | Distribution | Maintainer runbook: packages the five per-profile tarballs + checksums and cuts a GitHub Release. | `canonical/`, `profiles/`, `check-version-sync.sh` | medium | indirectly (release.yml CI) | Maintainer-only; rebuild bundle from clean HEAD. |
| `canonical/skills/*` (13) | Toolkit | Slash-command definitions (`SKILL.md` + `references/*.md`) that drive the pipeline state machines. | `canonical/aid/scripts/*`, `templates/*` | large (collectively) | behavioral via fixtures | The user-facing surface; one dir per skill. |
| `canonical/agents/*` (9) | Toolkit | Sub-agent role definitions (`AGENT.md` + `README.md`); dispatched by skills. | `templates/agent-boilerplate.md` (include) | medium | n/a (prose) | Roles: architect, clerk, developer, interviewer, operator, orchestrator, researcher, reviewer, tech-writer. |
| `canonical/aid/scripts/*` | Toolkit | Helper scripts grouped by phase area (config, execute, housekeep, interview, kb, migrate, release, summarize) + top-level `grade.sh`. | `config/read-setting.sh`, `grade.sh` | large | partial (per-area suites + fixtures) | See [Script Modules by Area](#script-modules-by-area). |
| `canonical/aid/templates/*` | Toolkit | KB doc seeds, state-file templates, schemas, kb-authoring rules, recipe template. | none (consumed by skills) | large | n/a (data) | The artifact-schema source of truth (see artifact-schemas.md). |
| `canonical/aid/recipes/*` (52) | Toolkit | Pre-filled lite-path change templates with `{{slot}}` placeholders (add-/change-/fix- families). | `interview/parse-recipe.sh` consumes them | medium | parse coverage | Passthrough-rendered (no frontmatter injection). |
| `generate-profile` renderer | Render | Python renderer that mirrors `canonical/` into each `profiles/<tool>/` tree under an emission manifest. | `canonical/`, `profiles/*.toml` | large | tested (`test_manifest_safety.py`, `verify_deterministic.py`, `verify_advisory.py`) | Lives at `.claude/skills/generate-profile/scripts/`. |
| `profiles/<tool>/` (5) | Render | Rendered, per-tool copies of the toolkit (claude-code, codex, cursor, copilot-cli, antigravity) + `<tool>.toml` config. | output of the renderer | large | render-drift CI | Build output -- never hand-edit; regenerate. |
| `packages/npm` | Distribution | npm `aid-installer` wrapper; vendors `bin/`, `lib/`, `dashboard/`. | `bin/`, `lib/`, `dashboard/` | medium | release smoke | Vendored copies regenerate; edit the wrapper, not the vendor. |
| `packages/pypi` | Distribution | PyPI `aid-installer` wrapper (`aid_installer/` + `_vendor/`). | `bin/`, `lib/`, `dashboard/` | medium | release smoke | `__main__.py` puts `aid` on PATH. |
| `dashboard/reader/*` (Python) | Observation | Parses `.aid/` state (STATE.md hierarchy, settings, KB) into typed models. | `.aid/` artifact schemas | large | tested (`dashboard/reader/tests/`) | `parsers.py` + `derivation.py` + `models.py` + `locator.py`. |
| `dashboard/server/*` | Observation | Serves the dashboard: a Node `reader.mjs`/`server.mjs` twin of the Python reader, plus `server.py`, index/home HTML. | `dashboard/reader` semantics | large | tested (`dashboard/server/tests/`) | `reader.mjs` is the Node twin of `parsers.py` -- must stay parity. |
| `site/` | Observation | Standalone Astro marketing + docs website. | own `package.json` (independent build) | large | tested (`site/**/__tests__`) | Unrelated to the CLI build; separate `node_modules`/`dist`. |
| `tests/canonical/*` | Cross-cutting | Cross-platform shell test suites + `fixtures/`, run via `tests/run-all.sh`. | the modules under test | large | self | Heavy gates run on master CI only. |
| `tests/windows/*` | Cross-cutting | Windows-only PowerShell installer tests (`Test-AidInstaller.ps1`). | installers + install-core | large | windows CI lane | NOT in `run-all.sh`; needs a Windows runner. |

---

## Dependency Graph

> Arrows point from importer/consumer to its dependency (`A -> B` = A depends on B).
> Diagrams are avoided per kb-authoring P10; this is the plain-text form.

```
# Distribution plane
install.sh            -> lib/aid-install-core.sh
install.ps1           -> lib/AidInstallCore.psm1
bin/aid               -> lib/aid-install-core.sh
bin/aid.ps1           -> lib/AidInstallCore.psm1
bin/aid.cmd           -> bin/aid.ps1
release.sh            -> canonical/ , profiles/ , canonical/aid/scripts/release/check-version-sync.sh
packages/npm          -> bin/ , lib/ , dashboard/          (vendored)
packages/pypi         -> bin/ , lib/ , dashboard/          (vendored under _vendor/)

# Render plane (source-of-truth -> rendered copies)
generate-profile      -> canonical/ , profiles/<tool>.toml
profiles/<tool>/      -> generate-profile                  (emitted by)
profiles/<tool>/emission-manifest.jsonl -> generate-profile (safety boundary)

# Toolkit plane (internal wiring)
canonical/skills/*    -> canonical/aid/scripts/* , canonical/aid/templates/*
canonical/agents/*    -> canonical/aid/templates/agent-boilerplate.md   (include directive)
canonical/aid/scripts/* (most) -> canonical/aid/scripts/config/read-setting.sh
*/state-review.md (skills) -> canonical/aid/scripts/grade.sh
canonical/aid/recipes/* -> canonical/aid/scripts/interview/parse-recipe.sh (consumed by)

# Observation plane
dashboard/server/server.mjs -> dashboard/server/reader.mjs
dashboard/server/server.py  -> dashboard/reader/reader.py
dashboard/reader/reader.py  -> parsers.py , derivation.py , models.py , locator.py
dashboard/reader/*          -> .aid/ artifact schemas (STATE.md, settings.yml, KB)
dashboard/server/reader.mjs <parity> dashboard/reader/parsers.py   (twin -- no import; behavior-equal)
site/                       -> (independent; no dependency on the CLI/toolkit)
```

Key non-dependency (a thing that looks connected but is not):

```
site/  X  canonical/        (the website does NOT consume the toolkit; it has its own build)
```

---

## Script Modules by Area

The `canonical/aid/scripts/` tree is grouped by the pipeline phase that consumes
each area. Two scripts are cross-cutting and live where every skill can reach them:
`config/read-setting.sh` (settings resolver) and the top-level `grade.sh` (ledger
grader).

| Area | Scripts | Consumed by | Purpose |
|------|---------|-------------|---------|
| (root) | `grade.sh` | every skill REVIEW state | Reads the reviewer ledger, counts findings by severity, emits a grade. |
| `config/` | `read-setting.sh` | every skill | Resolves a setting from `.aid/settings.yml` (skill-override -> category -> default). |
| `execute/` | `complexity-score.sh`, `compute-block-radius.sh`, `writeback-state.sh` | `aid-execute` | Delivery-complexity scoring, failure block-radius (tasks transitively depending on a failed task), and locked per-unit STATE.md writeback. |
| `housekeep/` | `branch-commit.sh`, `cleanup-classify.sh`, `housekeep-state.sh` | `aid-housekeep` | Branch/commit helpers, orphan/cleanup classification, housekeep run-state. |
| `interview/` | `parse-recipe.sh` | `aid-interview` | Parses a recipe file's `{{slot}}` placeholders for the lite path. |
| `kb/` | `build-project-index.sh`, `build-metrics.sh`, `build-kb-index.sh`, `harvest-coined-terms.sh`, `closure-check.sh`, `discover-preflight.sh`, `kb-actback-task.sh`, `kb-citation-lint.sh`, `kb-dual-intent-probes.sh`, `kb-freshness-check.sh`, `kb-teachback-questions.sh`, `lint-frontmatter.sh`, `recon-classify.sh` | `aid-discover` (most), `aid-update-kb` (`kb-freshness-check.sh`) | The discovery/KB engine: index + metric generation, concept harvest, closure loop, frontmatter + citation lint, path classification, dual-intent self-eval. |
| `migrate/` | `migrate-kb-frontmatter.sh`, `migrate-work-hierarchy.sh`, `migrate-work-hierarchy.ps1` | `aid` CLI update path | One-time migrations (KB frontmatter v2; work-hierarchy restructure). Shell + PowerShell twin. |
| `release/` | `check-version-sync.sh` | `release.sh`, CI | Verifies the version string is in lockstep across all manifests. |
| `summarize/` | `assemble.sh`, `assemble-3part.sh`/`.ps1`, `grade-summary.sh`, `manual-checklist.sh`, `spot-check-facts.sh`, `stale-check.sh`, `summarize-preflight.sh`, `validate-html-output.sh`, `validate-visuals.mjs`, `contrast-check.mjs`, `writeback-state.sh` | `aid-summarize` | Builds + validates the `kb.html` visual summary (assembly, fact/stale checks, HTML + visual + contrast validation via Playwright/Node). |

> The installed copies under each profile (and the dogfood `.claude/aid/scripts/`)
> are rendered from these canonical sources. Edit `canonical/`, never the rendered
> copy.

---

## Entry Points

| Entry point | Module | Type | What it starts |
|-------------|--------|------|----------------|
| `install.sh` / `install.ps1` | Distribution | bootstrap | Downloads + installs the `aid` CLI (curl\|bash / irm\|iex). |
| `bin/aid` (+ `.ps1`/`.cmd`) | Distribution | CLI | Dispatches `aid <subcommand>` on PATH. |
| `packages/pypi/aid_installer/__main__.py` | Distribution | CLI | `aid` on PATH after `pipx install`. |
| `/aid-<skill>` slash commands | Toolkit | agent skill | Resolve to `canonical/skills/<name>/SKILL.md` (installed copy). |
| `.claude/skills/generate-profile/scripts/run_generator.py` | Render | build | Full profile render of `canonical/` -> `profiles/`. |
| `dashboard/server/server.mjs` / `server.py` | Observation | HTTP server | Serves the local read-only dashboard. |
| `site/` (Astro) | Observation | static build | Builds the marketing/docs website. |
| `tests/run-all.sh` | Cross-cutting | test runner | Aggregates the canonical shell suites. |

---

## High-Churn Modules

> Name + reason; the live churn number is point-in-time (run `git log`).

| Module | Why it churns | Risk |
|--------|---------------|------|
| `canonical/skills/aid-discover/` | The actively-developed discovery engine (work-001) -- large reference set, frequent feature additions. | High |
| `canonical/aid/scripts/kb/` | Backs aid-discover; new linters/checks land here often. | High |
| `lib/aid-install-core.sh` + PS twin | Install/migration semantics evolve with each release; twin must stay in sync. | High |
| `dashboard/reader` + `dashboard/server` | Reader/parser changes follow every STATE.md schema change; two twins to keep in parity. | Medium |

---

## Oversized Modules

**Modules to watch:**

- `dashboard/server/reader.mjs` and `dashboard/reader/parsers.py` -- the two
  largest source files; each is a full state-parsing engine. Large enough to hide
  complexity, and they are **twins** (a change in one must be mirrored in the
  other), doubling the risk.
- `lib/aid-install-core.sh` (and `AidInstallCore.psm1`) -- the largest shell file;
  install/update/remove/manifest logic concentrated in one library.
- `canonical/skills/aid-discover/references/state-generate.md` and
  `state-review.md` -- very large single reference files driving the discovery
  state machine.

---

## Conventions

> The project's own way of adding/wiring a part. State the rule, then the example.

- **Where a new skill goes:** create `canonical/skills/aid-<name>/SKILL.md` (+ a
  `references/` subdir for state files). Name it `aid-<verb>` (see
  `canonical/skills/aid-discover/`). The `SKILL.md` carries YAML frontmatter with
  `name:`, `description:`, `allowed-tools:`, `argument-hint:` (see
  `aid-config/SKILL.md`).
- **Where a new agent goes:** create `canonical/agents/aid-<role>/AGENT.md` (+
  `README.md`). The `AGENT.md` frontmatter carries `name:`, `description:`,
  `tier:` (large/medium/small), `tools:`. Include shared boilerplate with
  `{{include:agent-boilerplate}}` (see `canonical/agents/aid-architect/AGENT.md`).
- **Where a new helper script goes:** place it under the phase area it serves
  (`canonical/aid/scripts/<area>/`). Cross-cutting helpers go at the script root
  (`grade.sh`) or in `config/`. Read settings via `read-setting.sh`; do not parse
  `settings.yml` directly.
- **How a new generated file is registered:** add a `<output-path>|<build-command>`
  line to `canonical/aid/templates/generated-files.txt` (dependencies first); the
  renderer rewrites the `canonical/` path to each profile's install root.
- **How a new recipe goes:** add `canonical/aid/recipes/<verb>-<thing>.md` with
  `{{slot}}` placeholders; it is passthrough-rendered (no frontmatter injection).
- **Never edit a rendered copy.** Edit `canonical/` and regenerate; `profiles/*`,
  `packages/*/_vendor/`, and the dogfood `.claude/` are build output.

---

## Invariants

> Hard MUST/MUST-NOT rules the module graph enforces silently.

- **Single source of truth:** every shipped file originates in `canonical/`.
  `profiles/`, `packages/*/_vendor/`, and `.claude/` MUST be regenerated, never
  hand-edited. Hand-editing a rendered copy is lost on the next render.
- **Render is a pure mirror bounded by the emission manifest:** the renderer may
  only delete install-tree paths present in the previous run's
  `emission-manifest.jsonl` (`removed_dst`). Files outside any manifest are never
  touched. (See `canonical/EMISSION-MANIFEST.md`.)
- **Language twins stay behavior-equal:** `aid-install-core.sh` <-> `AidInstallCore.psm1`,
  `bin/aid` <-> `bin/aid.ps1`, `dashboard/reader/parsers.py` <-> `dashboard/server/reader.mjs`,
  and the migrate `.sh`/`.ps1` twins MUST change in lockstep. A change to one
  without the other is a defect.
- **Install manifests stay in lockstep:** the dashboard file set vendored into the
  five install manifests (npm, pypi, the three release paths) MUST match; a missing
  file in one channel is a ship bug (precedent: home.html omission).
- **Settings are read through `read-setting.sh`:** scripts MUST NOT hand-parse
  `.aid/settings.yml`; the resolver owns the override -> category -> default chain.
- **Derived STATE views are never written:** the work/delivery `## Tasks State`,
  `## Delivery Gates`, etc. are read-time unions over per-unit STATE.md files; only
  the per-unit files are write targets (see artifact-schemas.md).

---

## Contracts

> Structural shape a new part or connection MUST satisfy.

- **Skill contract:** `canonical/skills/aid-<name>/SKILL.md` MUST carry valid
  frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`) and resolve
  its config via `read-setting.sh`; any REVIEW state MUST emit a reviewer ledger
  and grade it via `grade.sh`.
- **Agent contract:** `canonical/agents/aid-<role>/AGENT.md` MUST carry `name`,
  `description`, `tier`, `tools` frontmatter and define What You Do / Don't Do /
  Key Constraints / When to Escalate sections (see any `AGENT.md`).
- **Emission-manifest record contract:** every rendered file is recorded as a JSONL
  object with exactly `{profile, src, dst, sha256}`, sorted by `dst`, LF-only, with
  a `{"_manifest_version": 1}` sentinel first line (see `canonical/EMISSION-MANIFEST.md`).
- **Generated-file registry contract:** each line is `<output-path>|<build-command>`,
  `canonical/`-rooted, ordered dependencies-first (see `generated-files.txt`).
- **Reader-parity contract:** the Node reader and the Python reader MUST produce the
  same model from the same `.aid/` state (the dashboard parity test suites enforce this).

---

## Gotchas

- **Heavy file duplication is intentional.** `reader.mjs`/`parsers.py` and the whole
  toolkit appear many times (dashboard + npm + pypi `_vendor` + five profiles +
  `.claude/`). Do NOT "deduplicate" -- they are rendered/vendored copies of
  `canonical/`.
- **Master-only CI gates.** `tests/run-all.sh` (canonical suites) and the Astro
  `site` build run only on push/PR to master; a green feature branch can still break
  master. Run them locally (HOME-pinned) before claiming green.
- **Windows installer tests are not in `run-all.sh`.** `tests/windows/Test-AidInstaller.ps1`
  runs only on the Windows CI lane; a CLI behavior change must update it too.
- **Scan tests must pin `$HOME`.** The migration scan defaults its root to `$HOME`;
  a test firing it without `export HOME=<throwaway>` will migrate the developer's
  real repos.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial module map (brownfield deep-dive / Analyst) |
