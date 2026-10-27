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
review-criteria:
  - id: F-01
    kind: validate
    criterion: >
      Every top-level directory present in the repository appears in the directory tree here.
    severity: MEDIUM
    why: >
      This tree is how an agent orients before it edits; a directory missing from it reads as
      one that does not exist.
---

# Project Structure

> **Source:** aid-discover (Phase 1 -- Pre-scan)
> **Status:** Complete

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
- [Invariants](#invariants)

---

## Repository Overview

| Property | Value |
|----------|-------|
| **Root directory** | the local checkout root (machine-specific path; not a stable fact) |
| **Project version** | see `VERSION` (single canonical string; kept in sync across `packages/` and the `aid_version` key in `.aid/.aid-manifest.json`; the standalone `.aid/.aid-version` marker file is retired) |
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
   rendered into five per-tool agent trees under `profiles/` (its skills and runtime are
   copied into a shared payload), then wrapped for distribution in `packages/`.
2. **The dogfood install** — AID installed *into its own repository* so the maintainers
   use AID to build AID. This lives in `.agents/`, `.claude/`, `.cursor/` (the CLI-installed
   trees) and `.aid/` (pipeline state, work tracking,
   and the Knowledge Base you are reading).

CONFIRMED. The dual nature is stated in `README.md` (a multi-skill pipeline across 9
specialized agents and 5 AI tools) and confirmed by the `canonical/` -> `profiles/` ->
`packages/` layout plus the dogfood installs. See [Unusual Structure Notes](#unusual-structure-notes).

---

## Directory Tree

> Top 3-4 levels with annotations. File counts drift — run `find <dir>` for live counts.

```
AID/
├── .agents/                  # DOGFOOD shared skills: the aid-* skill directories the CLI installs
│   └── skills/
├── bin/                      # aid CLI dispatchers (Bash, PowerShell, cmd shim)
├── lib/                      # install-core engines (Bash .sh + PowerShell .psm1)
├── install.sh                # Bash bootstrap installer (curl | bash)
├── install.ps1               # PowerShell bootstrap installer (irm | iex)
├── release.sh                # maintainer release-packaging runbook script
├── VERSION                   # single-line canonical version string
├── canonical/                # SOURCE OF TRUTH for the AID toolkit
│   ├── skills/               # 37 skill definitions (18 curated + 19 catalog skills)
│   ├── agents/               # agent role definitions (one AGENT.md each)
│   └── aid/                  # runtime payload, installed at .aid/runtime/
│       ├── scripts/          # helper scripts grouped by phase (kb, execute, ...)
│       ├── templates/        # KB seeds, doc/state templates, schemas, shortcut catalog + engine + scaffolding
│       └── rules.md          # the AID rules every tool reads through AGENTS.md
├── profiles/                 # RENDERED per-tool agent trees (generated; do not hand-edit)
│   ├── claude-code/          # .claude/agents/ + aid-tool.conf
│   ├── codex/                # .codex/agents/ + aid-tool.conf
│   ├── cursor/               # .cursor/agents/ + aid-tool.conf
│   ├── copilot-cli/          # .github/agents/ + aid-tool.conf
│   ├── antigravity/          # .agent/agents/ + aid-tool.conf
│   └── <profile>.toml        # per-profile render config (5 files)
├── packages/                 # published distribution wrappers
│   ├── npm/                  # npm 'aid-installer' (vendors bin/lib/dashboard)
│   └── pypi/                 # PyPI 'aid-installer' (aid_installer/ + _vendor/)
├── dashboard/                # read-only local web dashboard (Python + Node readers)
│   ├── reader/               # Python KB/state parsers + tests
│   ├── server/               # Node (.mjs) + Python servers + index/home HTML
│   └── *.html                # index.html, home.html
├── chat-node/                # chat-node hub, adapters, server and scripts (with its own tests/)
├── design/                   # design notes (STATE-yml-target.md)
├── recovery/                 # recovery records (partial/)
├── scripts/                  # repo maintenance scripts (checks/, usage/)
├── site/                     # Astro marketing/docs website (separate build)
│   ├── src/                  # Astro content, pages and components
│   ├── scripts/              # gen-facts.mjs: skill, agent and settings pages from canonical/
│   └── dist/                 # built site output (generated)
├── docs/                     # user-facing documentation (methodology, install, faq)
├── examples/                 # walkthrough samples (greenfield, brownfield full/lite)
├── tests/                    # test suites
│   ├── canonical/            # cross-platform shell test suites + fixtures
│   ├── lib/                  # shared test helpers (bundle.sh stages a release for the suites)
│   └── windows/              # Windows-only PowerShell installer tests
├── .github/                  # GitHub config + CI workflows
│   └── workflows/            # docs.yml, test.yml, installer-tests.yml, release.yml, coverage-parity.yml
├── .claude/                  # DOGFOOD: Claude Code agents, the aid-* skill mirror, maintainer skills, settings
│   ├── agents/               # installed aid-*.md agents
│   ├── skills/               # aid-* mirror of .agents/skills/ + maintainer skills (generate-profile, release-aid)
│   └── settings.json
├── .cursor/                  # DOGFOOD: installed Cursor agents (agents/) + rules/
└── .aid/                     # DOGFOOD pipeline state + Knowledge Base
    ├── runtime/              # CLI-installed runtime: scripts/, templates/, rules.md, host.conf
    ├── knowledge/            # the Knowledge Base (KB docs + INDEX + STATE + kb.html)
    ├── design/               # design seeds under construction (.aid/design/README.md defines the convention)
    ├── works/                # tracked work folders
    ├── generated/            # discovery scratch (project-index, candidate-concepts)
    ├── connectors/           # connector catalog: descriptors + INDEX.md + git-ignored .secrets/
    └── settings.yml          # AID pipeline configuration (single source of truth)
```

CONFIRMED by direct `find` traversal of each subtree.

---

## Top-Level Directory Purposes

| Directory | Purpose | Edit here? |
|-----------|---------|-----------|
| `bin/` | The `aid` CLI dispatchers installed onto PATH: `aid` (Bash), `aid.ps1` (PowerShell), `aid.cmd` (cmd.exe shim). | Yes |
| `lib/` | Shared install-core engines sourced by the installers: `aid-install-core.sh`, `AidInstallCore.psm1`. | Yes |
| `canonical/` | The single source of truth for everything AID installs: `skills/`, `agents/`, `aid/{scripts,templates}`. Edit AID content **here**, never in `profiles/`. | Yes |
| `profiles/` | Five rendered, per-tool agent trees (claude-code, codex, cursor, copilot-cli, antigravity). Generated by the profile renderer; treated as build output. | No (regenerate) |
| `packages/` | Distribution wrappers that vendor `bin/`, `lib/`, and `dashboard/` for npm and PyPI publication. | Partially (wrapper code yes, vendored copies regenerated) |
| `dashboard/` | A local, read-only web dashboard that reads `.aid/` state across projects. Has both a Python reader/server and a Node server (`.mjs`). | Yes |
| `site/` | An Astro website (marketing + docs). Separate build from the CLI/toolkit; its skill, agent and settings pages are generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed, and every other page is hand-written. | Yes |
| `docs/` | User-facing documentation: methodology, install guide, repo map, release runbook, FAQ, glossary. | Yes |
| `examples/` | Step-by-step sample artifacts for greenfield, brownfield-full, and brownfield-lite paths. | Yes |
| `tests/` | `canonical/` cross-platform shell suites (+ fixtures) and `windows/` PowerShell installer tests. | Yes |
| `.github/` | Issue templates, dependabot config, and five CI workflows. | Yes |
| `.agents/` | A **dogfood** install of the shared `aid-*` skills. | No (regenerate via install) |
| `.claude/` | A **dogfood** AID install for this repo: the Claude Code agents and the `aid-*` skill mirror. | No (regenerate via install) |
| `.cursor/` | A **dogfood** AID install for this repo: the Cursor agents. | No (regenerate via install) |
| `.aid/` | The **dogfood** AID pipeline state: the installed runtime (`runtime/`), the Knowledge Base, tracked works (under `works/`), settings, and discovery scratch. | Yes (state-managed) |

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
| `release.sh` | Maintainer-only script that packages the shared payload, the five per-tool agent artifacts and the CLI bundle, then cuts a GitHub Release. |
| `VERSION` | Single-line canonical version string; kept in sync across packages and the `aid_version` key in `.aid/.aid-manifest.json` (the standalone `.aid/.aid-version` marker file is retired). |
| `packages/npm/package.json` | npm `aid-installer` manifest. |
| `packages/pypi/pyproject.toml` | PyPI `aid-installer` build config. |
| `site/package.json` | Astro website build config (separate from the CLI). |
| `canonical/aid/templates/shortcut-catalog.yml` | Single-source 94-row manifest, every row a canonical invocation name, that generates the 8 shortcut doorway directories, alongside 11 hand-authored `repurpose` skills; its 75 `kind_of` rows own no directory and are invoked through their family; read by the maintainer build helper (`build-shortcut-skills.py`) and by `/aid-triage`. |
| `canonical/aid/templates/shortcut-engine.md` | The shared state machine every shortcut skill delegates to (INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT). |
| `canonical/aid/templates/shortcut-scaffolding/` | Per-family SPEC/PLAN/DETAIL scaffolding the shortcut engine consults (one file per verb family: create, change-refactor, fix, document, prototype, test-experiment, analyze-report). |
| `canonical/aid/templates/task-detail-template.md` | Template for a task definition (`DETAIL.md`, formerly the task-level `SPEC.md` / `task-NNN.md`). |
| `.aid/settings.yml` | AID pipeline configuration — the authoritative settings other skills read. |
| `tests/run-all.sh` | Aggregate runner for the canonical test suites. |
| `.github/workflows/test.yml` | CI for the canonical helper suites (runs on master). |
| `.github/workflows/release.yml` | CI release pipeline. |
| `CLAUDE.md` | Repo-level Claude Code instructions: an AID:BEGIN/END managed region (the `@.aid/runtime/rules.md` import line, plus `@.aid/knowledge/PROJECT.md` when the card exists), plus the user's own text. |
| `README.md` | Project overview, install instructions, pipeline diagram. |

CONFIRMED. Purpose lines verified by reading each file's header comment (e.g.
`install.sh` "AID installer bootstrap", `release.sh` "Package the shared payload, five tool artifacts, and CLI bundle", `bin/aid` "AID CLI dispatcher (Bash side)").

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
| Web | HTML / CSS | `dashboard/index.html`, `.aid/knowledge/kb.html`, `site/src/styles/` |
| Language (site) | TypeScript | `site/tsconfig.json`, `site/src/**/*.ts` |
| Config | YAML / JSON / TOML | `.aid/settings.yml`, `.claude/settings.json`, `profiles/*.toml` |
| CI | GitHub Actions | `.github/workflows/*.yml` |
| Browser testing | Playwright | `canonical/aid/scripts/summarize/validate-visuals.mjs`, `.playwright-mcp/` |

CONFIRMED. AID is polyglot by design: it must install through Bash and PowerShell hosts
and ship via both npm and PyPI, so the same logic exists in multiple languages.

---

## Entry Points

There is no single application entry point — AID is a toolkit with several distinct entries:

1. **Installer bootstrap** — `install.sh` (Linux/macOS) and `install.ps1` (Windows) install the CLI.
2. **The CLI** — `bin/aid` (Bash) / `bin/aid.ps1` + `bin/aid.cmd` (Windows) dispatch user commands.
3. **Package wrappers** — `packages/npm/bin/` and `packages/pypi/aid_installer/__main__.py` put `aid` on PATH after `npm i -g` / `pipx install`.
4. **Skills (user-facing)** — slash commands like `/aid-discover` resolve to `canonical/skills/<name>/SKILL.md` (installed copies under `.agents/skills/`).
5. **Dashboard servers** — `dashboard/server/server.mjs` (Node) and `dashboard/server/server.py` (Python).
6. **Website** — `site/` builds via Astro on its own toolchain (hand-written pages, plus pages generated from `canonical/` and committed).

CONFIRMED by file headers (`bin/aid` usage block) and `README.md` install/quick-start sections.

---

## Test Directories

| Location | Contents |
|----------|----------|
| `tests/canonical/` | Cross-platform shell test suites (`test-*.sh`) plus `fixtures/` and `ps51-compat-check.ps1`. Run via `tests/run-all.sh`. |
| `tests/windows/` | Windows-only PowerShell installer tests (`Test-AidInstaller.ps1`), run only on the Windows CI lane. |
| `dashboard/reader/tests/` | Python `pytest` suites for the KB/state reader. |
| `dashboard/server/tests/` | Node + Python tests for the dashboard server. |
| `site/tests/` | The site suite (vitest): the build, internal links, the facts check, and accessibility and structure of the built pages. Run with `npm test` in `site/`. |
| `.claude/skills/generate-profile/scripts/verify_*.py` | Profile-renderer determinism and advisory checks. |

CONFIRMED. Run `find tests -name 'test-*.sh' | wc -l` for the live canonical-suite count
(do not rely on a frozen number).

---

## Documentation Found in Repository

| File/Directory | Content |
|----------------|---------|
| `README.md` | Project overview, install (4 channels), pipeline diagram, "Why AID", feature highlights. |
| `docs/aid-methodology.md` | The complete methodology (~40-minute read). |
| `docs/install.md` | Full install guide — all channels, offline bundles, update/remove. |
| `docs/repository-structure.md` | Contributor-oriented repo map (cross-checked here). |
| `docs/release.md` | Maintainer release runbook. |
| `docs/faq.md` | How-to questions. |
| `docs/glossary.md` | Term definitions. |
| `docs/images/` | Documentation images. |
| `CONTRIBUTING.md` | How to contribute skills, templates, examples. |
| `CLAUDE.md` | Repo agent instructions with an AID-managed region. |
| `examples/` | Walkthrough samples (greenfield, brownfield full-path, brownfield lite-path). |
| `dashboard/README.md`, `tests/README.md` | Subsystem-local READMEs. `canonical/` carries none: the per-skill and per-agent READMEs were removed, since nothing installed or ran resolved to them. |

CONFIRMED by direct listing of `docs/`, root, and `examples/`.

---

## Unusual Structure Notes

These are intentional or notable layout traits a newcomer will trip over:

1. **Heavy, deliberate file duplication.** Several files appear three to six times across
   the repo (e.g. `reader.mjs` and `parsers.py` exist in `dashboard/`, `packages/npm/`,
   and `packages/pypi/aid_installer/_vendor/`; the canonical toolkit is re-rendered into
   five `profiles/` agent trees, and its skills and runtime are copied into the dogfood trees).
   This is by design — `canonical/` is the source of truth and the rest are rendered, copied or
   vendored copies. Do not "deduplicate" them; edit `canonical/` and regenerate. CONFIRMED via the
   project-index "Top 20 Largest Source Files" table (same path basenames repeated).

2. **The repo dogfoods itself.** `.agents/`, `.claude/`, `.cursor/` (the CLI-installed trees) and `.aid/`
   (pipeline state + this Knowledge Base) are AID
   *installed into AID*. They are real working state, not examples. CONFIRMED by
   `.aid/settings.yml` (`project.name: AID`, `project.type: brownfield`).

3. **The website (`site/`) is a separate build, not a separate source.** It has its own `package.json`, `node_modules`, and `dist/`, and is not part of the CLI/toolkit build. Its skill, agent and settings pages are generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed. So a `canonical/` change that the committed pages do not reflect fails `node site/scripts/gen-facts.mjs --check` (a `docs.yml` step, and part of `npm test`), not the build. CONFIRMED (`site/scripts/gen-facts.mjs`; `.github/workflows/docs.yml`).

---

## Invariants

- **`canonical/` is the single source of truth** for everything AID installs; `profiles/` are
  render output and are **never hand-edited** -- the render-drift VERIFY gate enforces
  byte-identity. CONFIRMED in `docs/repository-structure.md`.
- **AID-delivered content is namespaced** (the `aid-` prefix on skills and agents, and the `.aid/runtime/`
  tree for toolkit scripts and templates) and never collides with user content; root-agent files
  (`CLAUDE.md`/`AGENTS.md`) are updated only inside the in-place AID:BEGIN/END region.
- **`.aid/` is per-project working state** (the Knowledge Base + pipeline run-state), not part
  of the shipped product; the dogfood installed trees and `.aid/` in this repo are
  real working state, not example data.
