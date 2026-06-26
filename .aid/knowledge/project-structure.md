---
kb-category: primary
source: hand-authored
objective: Repository layout, top-level directory purposes, detected technologies, and file-inventory shape for the AID project.
summary: Read this first to understand the on-disk organization of AID — a methodology delivered as a multi-profile CLI installer — before navigating any subtree.
sources:
  - .
  - README.md
  - docs/repository-structure.md
  - canonical/
  - profiles/
tags: [C1, structure, layout, directories, files]
see_also: [module-map.md, architecture.md, technology-stack.md]
owner: architect
audience: [developer, architect]
intent: |
  Repository layout, top-level directory purposes, and file-inventory shape. Read this to understand the on-disk organization of the project before navigating any subtree.
contracts: []
changelog:
  - 2026-06-25: Initial pre-scan (aid-discover Phase 1 / Scout)
---

# Project Structure

> **Source:** aid-discover (Phase 1 -- Pre-scan)
> **Status:** Complete
> **Last Updated:** 2026-06-25

## Contents

- [Repository Overview](#repository-overview)
- [What This Project Is](#what-this-project-is)
- [Directory Tree](#directory-tree)
- [Top-Level Directory Purposes](#top-level-directory-purposes)
- [Key Files](#key-files)
- [Detected Technologies](#detected-technologies)
- [Entry Points](#entry-points)
- [Test Directories](#test-directories)
- [Documentation Found in Repository](#documentation-found-in-repository)
- [Unusual Structure Notes](#unusual-structure-notes)
- [Change Log](#change-log)

---

## Repository Overview

| Property | Value |
|----------|-------|
| **Root directory** | `/home/andre.vianna/projects/AID` |
| **Project version** | `1.1.1` (see `VERSION`) |
| **Primary language(s)** | Markdown, Shell, Python, JavaScript, PowerShell (most-used first) |
| **Build / package systems** | npm (`packages/npm/package.json`), PyPI (`packages/pypi/pyproject.toml`), Astro (`site/package.json`) |
| **License** | MIT (`LICENSE`) |

CONFIRMED. Languages and counts are derived from `.aid/generated/project-index.md`
(its `## Language Breakdown` table). For exact file counts at any moment, run `find`
rather than trusting a frozen number.

---

## What This Project Is

AID ("AI Integrated Development") is a **methodology**, not a runtime application. It
ships as a multi-profile **CLI installer** that drops an AID toolkit (skills, agents,
templates, scripts) into a user's repository for whichever AI coding tool they use.

The repository has two faces, and understanding the split is the key to navigating it:

1. **The product** — the installable AID toolkit, authored once in `canonical/` and
   rendered into five tool-specific copies under `profiles/`, then wrapped for
   distribution in `packages/`.
2. **The dogfood install** — AID installed *into its own repository* so the maintainers
   use AID to build AID. This lives in `.claude/` (the rendered claude-code profile) and
   `.aid/` (pipeline state, work tracking, and the Knowledge Base you are reading).

CONFIRMED. The dual nature is stated in `README.md` ("12-skill pipeline · 9 specialized
agents · 5 AI tools") and confirmed by the `canonical/` -> `profiles/` -> `packages/`
layout plus the dogfood `.claude/` install. See [Unusual Structure Notes](#unusual-structure-notes).

---

## Directory Tree

> Top 3-4 levels with annotations. File counts drift — run `find <dir>` for live counts.

```
AID/
├── bin/                      # aid CLI dispatchers (Bash, PowerShell, cmd shim)
├── lib/                      # install-core engines (Bash .sh + PowerShell .psm1)
├── install.sh                # Bash bootstrap installer (curl | bash)
├── install.ps1               # PowerShell bootstrap installer (irm | iex)
├── release.sh                # maintainer release-packaging runbook script
├── VERSION                   # single-line version string (1.1.1)
├── canonical/                # SOURCE OF TRUTH for the AID toolkit
│   ├── skills/               # skill definitions (aid-config, aid-discover, ...)
│   ├── agents/               # agent role definitions (AGENT.md + README.md each)
│   ├── aid/                  # toolkit payload installed under the tool's aid/ subtree
│   │   ├── scripts/          # helper scripts grouped by phase (kb, execute, ...)
│   │   ├── templates/        # KB + document + authoring templates
│   │   └── recipes/          # lite-path recipe library (add-/change-/fix- families)
│   └── EMISSION-MANIFEST.md  # declares what the renderer emits per profile
├── profiles/                 # RENDERED install trees (generated; do not hand-edit)
│   ├── claude-code/          # → .claude/{agents,skills,aid}, CLAUDE.md, README
│   ├── codex/                # → .codex/..., AGENTS.md
│   ├── cursor/               # → .cursor/..., AGENTS.md
│   ├── copilot-cli/          # → .github/..., AGENTS.md
│   ├── antigravity/          # → .agent/..., AGENTS.md
│   └── <profile>.toml        # per-profile render config (5 files)
├── packages/                 # published distribution wrappers
│   ├── npm/                  # npm 'aid-installer' (vendors bin/lib/dashboard)
│   └── pypi/                 # PyPI 'aid-installer' (aid_installer/ + _vendor/)
├── dashboard/                # read-only local web dashboard (Python + Node readers)
│   ├── reader/               # Python KB/state parsers + tests
│   ├── server/               # Node (.mjs) + Python servers + index/home HTML
│   └── *.html                # index.html, home.html
├── site/                     # Astro marketing/docs website (separate build)
│   ├── src/                  # Astro pages, components, content, data
│   ├── scripts/              # docs/reference sync + release-data fetch
│   └── dist/                 # built site output (generated)
├── docs/                     # user-facing documentation (methodology, install, faq)
├── examples/                 # walkthrough samples (greenfield, brownfield full/lite)
├── tests/                    # test suites
│   ├── canonical/            # cross-platform shell test suites + fixtures
│   └── windows/              # Windows-only PowerShell installer tests
├── .github/                  # GitHub config + CI workflows
│   └── workflows/            # docs.yml, test.yml, installer-tests.yml, release.yml
├── .claude/                  # DOGFOOD install (rendered claude-code profile)
│   ├── agents/  skills/  aid/ # the AID toolkit, used on this repo itself
│   └── settings.json
└── .aid/                     # DOGFOOD pipeline state + Knowledge Base
    ├── knowledge/            # the Knowledge Base (KB docs + INDEX + STATE)
    ├── work-001-*/  work-002-*/  # tracked works (pipeline state per work)
    ├── generated/            # discovery scratch (project-index, candidate-concepts)
    ├── design/               # design notes for in-flight features
    ├── dashboard/            # generated dashboard artifacts (kb.html)
    └── settings.yml          # AID pipeline configuration (single source of truth)
```

CONFIRMED by direct `find` traversal of each subtree.

---

## Top-Level Directory Purposes

| Directory | Purpose | Edit here? |
|-----------|---------|-----------|
| `bin/` | The `aid` CLI dispatchers installed onto PATH: `aid` (Bash), `aid.ps1` (PowerShell), `aid.cmd` (cmd.exe shim). | Yes |
| `lib/` | Shared install-core engines sourced by the installers: `aid-install-core.sh`, `AidInstallCore.psm1`. | Yes |
| `canonical/` | The single source of truth for everything AID installs: `skills/`, `agents/`, `aid/{scripts,templates,recipes}`. Edit AID content **here**, never in `profiles/`. | Yes |
| `profiles/` | Five rendered, per-tool copies of the canonical toolkit (claude-code, codex, cursor, copilot-cli, antigravity). Generated by the profile renderer; treated as build output. | No (regenerate) |
| `packages/` | Distribution wrappers that vendor `bin/`, `lib/`, and `dashboard/` for npm and PyPI publication. | Partially (wrapper code yes, vendored copies regenerated) |
| `dashboard/` | A local, read-only web dashboard that reads `.aid/` state across projects. Has both a Python reader/server and a Node server (`.mjs`). | Yes |
| `site/` | A standalone Astro website (marketing + docs). Independent build from the CLI/toolkit. | Yes |
| `docs/` | User-facing documentation: methodology, install guide, repo map, release runbook, FAQ, glossary. | Yes |
| `examples/` | Step-by-step sample artifacts for greenfield, brownfield-full, and brownfield-lite paths. | Yes |
| `tests/` | `canonical/` cross-platform shell suites (+ fixtures) and `windows/` PowerShell installer tests. | Yes |
| `.github/` | Issue templates, dependabot config, and four CI workflows. | Yes |
| `.claude/` | The **dogfood** AID install for this repo (a rendered claude-code profile). | No (regenerate via install) |
| `.aid/` | The **dogfood** AID pipeline state: the Knowledge Base, tracked works, settings, and discovery scratch. | Yes (state-managed) |

CONFIRMED. The "edit in canonical, not profiles" rule is stated in
`docs/repository-structure.md` ("single source of truth (never edit profiles/ directly)").

---

## Key Files

| File | Purpose |
|------|---------|
| `install.sh` | Bash bootstrap installer — installs the global `aid` CLI to `~/.aid/` (curl \| bash entry). |
| `install.ps1` | PowerShell bootstrap installer — installs to `%LOCALAPPDATA%\aid\` (irm \| iex entry). |
| `bin/aid` | The persistent `aid` CLI dispatcher (Bash); parses subcommands and calls the install-core. |
| `lib/aid-install-core.sh` | The shared Bash install/update/remove engine (the largest shell file). |
| `lib/AidInstallCore.psm1` | The PowerShell equivalent install-core module. |
| `release.sh` | Maintainer-only script that packages the five per-profile tarballs and cuts a GitHub Release. |
| `VERSION` | Single-line canonical version string; kept in sync across packages and `.aid/.aid-version`. |
| `packages/npm/package.json` | npm `aid-installer` manifest. |
| `packages/pypi/pyproject.toml` | PyPI `aid-installer` build config. |
| `site/package.json` | Astro website build config (separate from the CLI). |
| `canonical/EMISSION-MANIFEST.md` | Declares which files the profile renderer emits per profile. |
| `.aid/settings.yml` | AID pipeline configuration — the authoritative settings other skills read. |
| `tests/run-all.sh` | Aggregate runner for the canonical test suites. |
| `.github/workflows/test.yml` | CI for the canonical helper suites (runs on master). |
| `.github/workflows/release.yml` | CI release pipeline. |
| `CLAUDE.md` | Repo-level agent instructions (with an AID:BEGIN/END managed region). |
| `README.md` | Project overview, install instructions, pipeline diagram. |

CONFIRMED. Purpose lines verified by reading each file's header comment (e.g.
`install.sh` "AID installer bootstrap", `release.sh` "Package the five per-profile AID
tarballs", `bin/aid` "AID CLI dispatcher (Bash side)").

---

## Detected Technologies

| Category | Technology | Evidence |
|----------|-----------|----------|
| Docs / content | Markdown (the dominant language by file count and lines) | `.aid/generated/project-index.md` Language Breakdown |
| Scripting | Bash / Shell | `install.sh`, `lib/aid-install-core.sh`, `canonical/aid/scripts/**/*.sh` |
| Scripting (Windows) | PowerShell | `install.ps1`, `lib/AidInstallCore.psm1`, `bin/aid.ps1` |
| Language | Python (>=3.8) | `packages/pypi/pyproject.toml`, `dashboard/reader/*.py`, `.claude/skills/generate-profile/scripts/*.py` |
| Runtime | Node.js (>=18) | `packages/npm/package.json`, `dashboard/server/reader.mjs` |
| Web framework | Astro | `site/astro.config.mjs`, `site/package.json` |
| Web | HTML / CSS | `dashboard/index.html`, `.aid/dashboard/`, `site/src/styles/` |
| Language (site) | TypeScript | `site/tsconfig.json`, `site/src/**/*.ts` |
| Config | YAML / JSON / TOML | `.aid/settings.yml`, `.claude/settings.json`, `profiles/*.toml` |
| CI | GitHub Actions | `.github/workflows/*.yml` |
| Browser testing | Playwright | `.claude/aid/scripts/summarize/validate-visuals.mjs`, `.playwright-mcp/` |

CONFIRMED. AID is polyglot by design: it must install through Bash and PowerShell hosts
and ship via both npm and PyPI, so the same logic exists in multiple languages.

---

## Entry Points

There is no single application entry point — AID is a toolkit with several distinct entries:

1. **Installer bootstrap** — `install.sh` (Linux/macOS) and `install.ps1` (Windows) install the CLI.
2. **The CLI** — `bin/aid` (Bash) / `bin/aid.ps1` + `bin/aid.cmd` (Windows) dispatch user commands.
3. **Package wrappers** — `packages/npm/bin/` and `packages/pypi/aid_installer/__main__.py` put `aid` on PATH after `npm i -g` / `pipx install`.
4. **Skills (user-facing)** — slash commands like `/aid-discover` resolve to `canonical/skills/<name>/SKILL.md` (installed copies under each profile).
5. **Dashboard servers** — `dashboard/server/server.mjs` (Node) and `dashboard/server/server.py` (Python).
6. **Website** — `site/` builds independently via Astro.

CONFIRMED by file headers (`bin/aid` usage block) and `README.md` install/quick-start sections.

---

## Test Directories

| Location | Contents |
|----------|----------|
| `tests/canonical/` | Cross-platform shell test suites (`test-*.sh`) plus `fixtures/` and `ps51-compat-check.ps1`. Run via `tests/run-all.sh`. |
| `tests/windows/` | Windows-only PowerShell installer tests (`Test-AidInstaller.ps1`), run only on the Windows CI lane. |
| `dashboard/reader/tests/` | Python `pytest` suites for the KB/state reader. |
| `dashboard/server/tests/` | Node + Python tests for the dashboard server. |
| `site/scripts/__tests__/` | Tests for the website's docs/reference sync scripts. |
| `site/src/data/__tests__/` | TypeScript tests for site data (e.g. version injection). |
| `.claude/skills/generate-profile/scripts/test_*.py` / `verify_*.py` | Profile-renderer determinism and safety checks. |

CONFIRMED. Run `find tests -name 'test-*.sh' | wc -l` for the live canonical-suite count
(do not rely on a frozen number).

---

## Documentation Found in Repository

| File/Directory | Content |
|----------------|---------|
| `README.md` | Project overview, install (4 channels), pipeline diagram, "Why AID", feature highlights. |
| `docs/aid-methodology.md` | The complete methodology (~40-minute read). |
| `docs/install.md` | Full install guide — all channels, offline bundles, update/remove. |
| `docs/repository-structure.md` | Contributor-oriented repo map (cross-checked here; see [Unusual Structure Notes](#unusual-structure-notes) for a stale count). |
| `docs/release.md` | Maintainer release runbook. |
| `docs/faq.md` | How-to questions. |
| `docs/glossary.md` | Term definitions. |
| `docs/images/` | Documentation images. |
| `CONTRIBUTING.md` | How to contribute skills, templates, examples. |
| `CLAUDE.md` | Repo agent instructions with an AID-managed region. |
| `examples/` | Walkthrough samples (greenfield, brownfield full-path, brownfield lite-path). |
| `dashboard/README.md`, `tests/README.md`, `canonical/.../README.md` | Subsystem-local READMEs. |

CONFIRMED by direct listing of `docs/`, root, and `examples/`.

---

## Unusual Structure Notes

These are intentional or notable layout traits a newcomer will trip over:

1. **Heavy, deliberate file duplication.** Several files appear three to six times across
   the repo (e.g. `reader.mjs` and `parsers.py` exist in `dashboard/`, `packages/npm/`,
   and `packages/pypi/aid_installer/_vendor/`; the canonical toolkit is re-rendered into
   five `profiles/` and again into `.claude/`). This is by design — `canonical/` is the
   source of truth and the rest are rendered/vendored copies. Do not "deduplicate" them;
   edit `canonical/` and regenerate. CONFIRMED via the project-index "Top 20 Largest
   Source Files" table (same path basenames repeated).

2. **The repo dogfoods itself.** `.claude/` (a rendered claude-code profile) and `.aid/`
   (pipeline state + this Knowledge Base) are AID *installed into AID*. They are real
   working state, not examples. CONFIRMED by `.aid/settings.yml` (`project.name: AID`,
   `project.type: brownfield`).

3. **The website (`site/`) is a separate build.** It has its own `package.json`,
   `node_modules`, and `dist/` and is unrelated to the CLI/toolkit build. CONFIRMED.

4. **Loose screenshot PNGs at the repo root.** Many `kb-*.png` and `p3-*.png` files sit
   at the top level (e.g. `kb-dark.png`, `p3-v6.png`). These appear to be working/scratch
   artifacts from dashboard-summary visual work, not committed product assets. Flagged for
   confirmation — see `.scout-questions.tmp` Q3. CONFIRMED they exist; purpose UNCERTAIN.

5. **Stale counts in `docs/repository-structure.md`.** That contributor doc says
   "12 skill definitions" and "51 lite-path recipes" and references the path
   `canonical/recipes/`. Reality: `canonical/skills/` holds 13 skill directories,
   `canonical/aid/recipes/` (note the `aid/` segment) holds 52 recipe files. This is a
   documentation drift, flagged as Q1/Q2 — not reconciled here.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial pre-scan inventory (Scout) |
