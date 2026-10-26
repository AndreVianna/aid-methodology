---
title: 'Repository Structure'
description: 'How the AID repository is laid out and where things live.'
sourceDoc: 'docs/repository-structure.md'
---

Contributor-oriented map of the AID repository. Tells you where things live and why.

---

## Top-level layout

```
aid-methodology/
|-- bin/                        <- aid CLI dispatcher (installed to PATH)
|   |-- aid                     <- Bash dispatcher (Linux / macOS)
|   |-- aid.ps1                 <- PowerShell dispatcher (Windows)
|   `-- aid.cmd                 <- cmd.exe shim (Windows fallback)
|-- lib/                        <- install-core libraries (sourced/imported by installers)
|   |-- aid-install-core.sh     <- Bash install-core (sourced by install.sh in piped mode)
|   `-- AidInstallCore.psm1     <- PowerShell install-core module
|-- packages/                   <- published package wrappers
|   |-- npm/                    <- npm: aid-installer (Node wrapper that puts aid on PATH)
|   `-- pypi/                   <- PyPI: aid-installer (Python wrapper that puts aid on PATH)
|-- canonical/                  <- single source of truth (never edit profiles/ directly)
|   |-- skills/                 <- 37 skill definitions (18 curated + 19 catalog skills)
|   |-- agents/                 <- 9 agent definitions
|   `-- aid/                    <- AID toolkit root (installed at .aid/runtime/)
|       |-- rules.md            <- the AID rules every tool reads through AGENTS.md
|       |-- templates/          <- KB templates, document templates, shortcut engine + catalog
|       `-- scripts/            <- helper scripts by phase
|-- profiles/                   <- rendered per-tool agent trees (generated -- do not edit)
|   |-- claude-code/            <- agents + aid-tool.conf
|   |-- codex/
|   |-- cursor/
|   |-- copilot-cli/
|   `-- antigravity/
|-- docs/                       <- user-facing documentation
|   |-- aid-methodology.md      <- the complete methodology (~40 min read)
|   |-- install.md              <- full install guide
|   |-- repository-structure.md <- this file
|   |-- release.md              <- maintainer release runbook
|   |-- faq.md                  <- frequently asked questions
|   |-- glossary.md             <- term definitions
|   `-- images/                 <- documentation images
|-- examples/                   <- step-by-step worked examples
|   |-- greenfield/
|   |-- brownfield-full-path/
|   `-- brownfield-lite-path/
|-- .agents/skills/             <- dogfood install: the shared skills (written by aid; do not edit)
|-- .claude/skills/             <- dogfood install: Claude Code mirror of the shared skills (do not edit)
|-- .aid/runtime/               <- dogfood install: the shared runtime (do not edit)
|-- .github/workflows/          <- CI and release automation
|   |-- test.yml                <- PR / push tests (render-drift, canonical suites, installer)
|   |-- installer-tests.yml     <- cross-platform installer smoke tests
|   `-- release.yml             <- tag-triggered release (GitHub + npm + PyPI)
|-- install.sh                  <- curl | bash bootstrap installer (Linux / macOS)
|-- install.ps1                 <- irm | iex bootstrap installer (Windows PowerShell)
|-- release.sh                  <- manual release script (maintainer runbook path)
|-- VERSION                     <- single source of version truth (e.g. 1.0.0)
|-- CONTRIBUTING.md
`-- LICENSE
```

---

## Where things live

### The `aid` CLI (`bin/`, `lib/`, `install.sh`, `install.ps1`)

`bin/aid` (and its Windows siblings `bin/aid.ps1` / `bin/aid.cmd`) is the CLI dispatcher — the persistent global command users run. It delegates to the install-core library in `lib/` for all network, verify, extract, and manifest operations.

`install.sh` and `install.ps1` are the `curl | bash` / `irm | iex` bootstrap entry points. In piped mode they fetch and checksum-verify the install-core library from the GitHub release tag before sourcing it.

`packages/npm/` and `packages/pypi/` are thin wrappers that publish to npm and PyPI under the package name `aid-installer`. Their sole job is to vendor the `bin/` payload and wire it onto PATH.

### `canonical/` — the source of truth

All skill, agent, runtime, and template content lives here. The generator (`run_generator.py`) renders the agents in `canonical/` into the five `profiles/` trees, and `release.sh` packages the skills and runtime byte-for-byte into the shared payload. **Never edit `profiles/` or the dogfood install directly** — your changes will be overwritten on the next generator run.

- `canonical/skills/` — 37 skill definitions, one directory per skill: 18 curated skills — the 7 pipeline-phase skills implementing the six numbered phases (`aid-discover`, `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute` — Describe/Define are Phase 2a/2b of the one Describe→Define phase), the `aid-config` bootstrap, and the optional `aid-summarize` viewer, 7 off-pipeline on-demand skills (`aid-housekeep`, `aid-update-kb`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket`), and the standalone `aid-triage` router — plus the 19 skills that own a row of the 94-row shortcut catalog: 8 generated Lite-Path shortcut doorways (`aid-fix`, `aid-create`, `aid-update`, …) and 11 hand-authored `repurpose` skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, `aid-brainstorm`, plus the re-registered `aid-deploy` / `aid-monitor` / `aid-ask`). The catalog's other 75 rows are kinds with no directory, run through their family (`/aid-create api`); a hand-authored kind lives at `<family>/references/<kind>.md`
- `canonical/agents/` — 9 agent definitions
- `canonical/aid/templates/` — KB document templates, grading rubric, task templates, `task-detail-template.md` (delivery/task definitions), plus the shortcut system: `shortcut-catalog.yml` (the 94-row catalog every shortcut and `aid-triage` resolve against), `shortcut-engine.md` (the shared state machine every shortcut delegates to), and `shortcut-scaffolding/` (family-specific SPEC/PLAN/DETAIL scaffolding)
- `canonical/aid/scripts/` — helper scripts invoked by skills at runtime (interview, summarize, release, kb-hygiene)
- `canonical/aid/rules.md` — the AID rules. It installs as `.aid/runtime/rules.md`, and the root `AGENTS.md` region points at it

### `profiles/` — generated agent trees

Each subdirectory holds one tool's rendered agents and its `aid-tool.conf` descriptor, and nothing else. Skills and runtime are not in `profiles/`: they ship once, in the shared payload. The layout mirrors where `aid add <tool>` places that tool's agents:

| Profile | Agents folder | Root instruction files |
|---------|---------------|------------------------|
| `claude-code/` | `.claude/agents/` | `AGENTS.md`, and `CLAUDE.md` (imports `AGENTS.md`) |
| `codex/` | `.codex/agents/` | `AGENTS.md` |
| `cursor/` | `.cursor/agents/` | `AGENTS.md` |
| `copilot-cli/` | `.github/agents/` | `AGENTS.md` |
| `antigravity/` | `.agent/agents/` | `AGENTS.md` |

The five agent folders differ only in model names and file format. A deterministic-verify gate checks them after every generator run.

### `docs/`

User-facing documentation. `docs/aid-methodology.md` is the flagship (~40 min read). The rest are reference and how-to docs for adopters and maintainers.

### `examples/`

Three tutorial-style worked examples — greenfield full-path, brownfield full-path, brownfield lite-path. Each walks through the relevant pipeline phases and shows the key artifacts produced.

### `.github/workflows/`

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `test.yml` | PR / push to master | Render-drift check, canonical suites, generator self-tests, kb-hygiene |
| `installer-tests.yml` | PR / push, scheduled | Cross-platform installer smoke tests (Linux, macOS, Windows) |
| `release.yml` | Push of a `v*` tag | Gate (re-runs test suite) then GitHub Release + npm publish + PyPI publish |

---

## Contributing in the right place

| Want to change... | Edit here |
|---|---|
| A skill or agent | `canonical/skills/` or `canonical/agents/` — then run the generator |
| The AID rules every tool reads | `canonical/aid/rules.md` — then run the generator |
| A KB template | `canonical/aid/templates/knowledge-base/` |
| A shortcut (new/changed verb-artifact combo) | `canonical/aid/templates/shortcut-catalog.yml` + `canonical/aid/templates/shortcut-scaffolding/` — then run the generator |
| The `aid` CLI or install logic | `bin/`, `lib/`, `install.sh`, `install.ps1` |
| User-facing documentation | `docs/` |
| An example | `examples/` |

See [CONTRIBUTING.md](https://github.com/AndreVianna/aid-methodology/blob/master/CONTRIBUTING.md) for the full guide.
