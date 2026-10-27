---
title: 'Repository Structure'
description: 'This page maps the AID repository folder by folder, so you know where things live and where to make a change.'
sourceDoc: 'docs/repository-structure.md'
---

This page maps the AID repository folder by folder, so you know where things live and where to make a change.

## Top-level layout

The tree shows the main folders and files at the top of the repository.

```
aid-methodology/
|-- bin/                        <- aid CLI dispatchers
|   |-- aid                     <- Bash dispatcher (Linux / macOS)
|   |-- aid.ps1                 <- PowerShell dispatcher (Windows)
|   `-- aid.cmd                 <- cmd.exe shim (Windows)
|-- lib/                        <- install-core libraries the installers and the CLI use
|   |-- aid-install-core.sh     <- Bash install-core
|   `-- AidInstallCore.psm1     <- PowerShell install-core module
|-- packages/                   <- published package wrappers
|   |-- npm/                    <- npm: aid-installer
|   `-- pypi/                   <- PyPI: aid-installer
|-- canonical/                  <- the source of truth for everything AID installs
|   |-- skills/                 <- one directory for each skill
|   |-- agents/                 <- one directory for each agent
|   `-- aid/                    <- the AID toolkit root (installed at .aid/runtime/)
|       |-- rules.md            <- the AID rules, read through the AGENTS.md region
|       |-- templates/          <- Knowledge Base templates, document templates, shortcut engine and catalog
|       `-- scripts/            <- helper scripts, grouped by purpose
|-- profiles/                   <- rendered per-tool agent trees (generated; do not edit)
|   |-- claude-code/
|   |-- codex/
|   |-- cursor/
|   |-- copilot-cli/
|   `-- antigravity/
|-- dashboard/                  <- the local web dashboard
|-- chat-node/                  <- the chat node: adapters, server and scripts, with its own tests
|-- site/                       <- this documentation site (Astro)
|-- docs/                       <- Markdown documentation
|-- examples/                   <- step-by-step worked examples
|   |-- greenfield/
|   |-- brownfield-full-path/
|   `-- brownfield-lite-path/
|-- tests/                      <- test suites
|   |-- canonical/              <- test suites and fixtures
|   |-- lib/                    <- shared test helpers
|   `-- windows/                <- Windows PowerShell installer tests
|-- scripts/                    <- repository maintenance scripts (checks/, usage/)
|-- design/                     <- design notes
|-- recovery/                   <- recovery files (partial/)
|-- .agents/skills/             <- installed copy of the shared skills (written by aid; do not edit)
|-- .claude/                    <- Claude Code install of this repository, plus maintainer skills
|-- .cursor/                    <- Cursor install of this repository
|-- .aid/                       <- AID state of this repository (runtime, Knowledge Base, works)
|-- .github/workflows/          <- CI and release automation
|-- install.sh                  <- bootstrap installer (Linux / macOS)
|-- install.ps1                 <- bootstrap installer (Windows PowerShell)
|-- release.sh                  <- maintainer release script
|-- VERSION                     <- the product version
|-- package.json                <- Node tooling for scripts inside this repository
|-- README.md
|-- AGENTS.md
|-- CLAUDE.md
|-- CONTRIBUTING.md
`-- LICENSE
```

## Where things live

### The `aid` CLI

`bin/aid` is the CLI dispatcher. It has a PowerShell sibling, `bin/aid.ps1`, and a `bin/aid.cmd` shim for `cmd.exe`. The install-core libraries in `lib/` hold the install, update and remove logic.

`install.sh` and `install.ps1` are the bootstrap installers that put the `aid` CLI on your machine. The [Installation guide](/guides/installation/) walks you through them. The [CLI commands](/reference/cli/) page lists the commands.

`packages/npm/` and `packages/pypi/` are the wrappers published to npm and PyPI under the package name `aid-installer`. Each one puts an `aid` command on your PATH. Both copy the CLI source from the repository root when the package is built.

### `canonical/`: the source of truth

The AID skills, agents, runtime and templates that ship to users are authored here. The two maintainer-only skills, `generate-profile` and `release-aid`, live under `.claude/skills/`. The profile generator renders the agents in `canonical/` into the trees under `profiles/`. `release.sh` copies the skills and the runtime from `canonical/` into the shared payload as they are. Edit `canonical/`, never `profiles/` or the installed copies, because the next generator run overwrites them.

- `canonical/skills/` holds one directory per skill. See [Skills](/skills/) for the list.
- `canonical/agents/` holds one directory per agent. See [Agents](/reference/agents/) for the list.
- `canonical/aid/templates/` holds the Knowledge Base templates, the grading rubric and the task and state templates. It also holds the shortcut system: `shortcut-catalog.yml` (the catalog that shortcuts and `/aid-triage` resolve against), `shortcut-engine.md` (the shared state machine that shortcuts hand over to) and `shortcut-scaffolding/` (the scaffolding for each shortcut family).
- `canonical/aid/scripts/` holds the helper scripts that skills call at runtime. They sit in folders by purpose: `config`, `connectors`, `execute`, `housekeep`, `kb`, `migrate`, `release`, `summarize` and `works`. `grade.sh` sits beside them.
- `canonical/aid/rules.md` holds the AID rules. It installs as `.aid/runtime/rules.md`, and the `AGENTS.md` region points at it.

### `profiles/`: generated agent trees

Each subdirectory of `profiles/` holds one tool's rendered agents and its `aid-tool.conf` descriptor. Skills and runtime are not in `profiles/`, because they ship once, in the shared payload. The tree mirrors where `aid add <tool>` places that tool's agents.

| Profile | Agents folder | Root instruction files |
|---------|---------------|------------------------|
| `claude-code/` | `.claude/agents/` | `AGENTS.md`, and `CLAUDE.md` |
| `codex/` | `.codex/agents/` | `AGENTS.md` |
| `cursor/` | `.cursor/agents/` | `AGENTS.md` |
| `copilot-cli/` | `.github/agents/` | `AGENTS.md` |
| `antigravity/` | `.agent/agents/` | `AGENTS.md` |

Each profile is described by a `profiles/<tool>.toml` file. The generator renders the same canonical agents into every tree. It changes the model names, the tool names and the file format for each tool. A deterministic check runs after every generator run.

### The installed copy in this repository

This repository runs AID on itself. `.agents/skills/` holds the shared skills, `.claude/skills/aid-*` mirrors them for Claude Code, and `.aid/runtime/` holds the shared runtime. The `aid` CLI writes these folders. Do not edit them. `.claude/skills/` also holds the maintainer skills `generate-profile` and `release-aid`, which are written by hand.

### Other folders

- `dashboard/` is the local web dashboard. See [the dashboard guide](/guides/dashboard/).
- `site/` is this documentation site. Its pages live in `site/src/content/docs/`.
- `docs/` holds Markdown documentation: the methodology, the install guide, the release runbook, the FAQ, the glossary and this repository map.
- `examples/` holds three worked examples: greenfield, brownfield full path and brownfield Lite path. Each one walks through the pipeline and shows the artifacts it produces.
- `tests/` holds the test suites: `canonical/` for the suites and fixtures, `lib/` for shared helpers and `windows/` for the PowerShell installer tests.

### `.github/workflows/`

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `test.yml` | Pull request or push to `master`, or a manual run | Checks that `profiles/` matches `canonical/`, runs the canonical suites and the generator self-tests, and runs the repository hygiene checks |
| `installer-tests.yml` | Push to any branch except `master`, or a manual run | Runs the installer and CLI tests on Linux and Windows |
| `coverage-parity.yml` | Pull request or push to `master` that changes `tests/` or the workflow file, or a manual run | Checks that the test assertions still match a committed baseline |
| `docs.yml` | Pull request or push to `master` that changes the site inputs, or a manual run | Builds this site, and deploys it when run on `master` |
| `release.yml` | Push of a `v*` tag, or a manual run | Re-runs the checks, then publishes to GitHub Releases, npm and PyPI |

## Where to make a change

| Want to change... | Edit here |
|---|---|
| A skill or agent | `canonical/skills/` or `canonical/agents/`, then run the generator |
| The AID rules | `canonical/aid/rules.md`, then run the generator |
| A Knowledge Base template | `canonical/aid/templates/knowledge-base/` |
| A shortcut | `canonical/aid/templates/shortcut-catalog.yml` and `canonical/aid/templates/shortcut-scaffolding/`, then run the generator |
| The `aid` CLI or install logic | `bin/`, `lib/`, `install.sh`, `install.ps1` |
| A page of this site | `site/src/content/docs/` |
| Other documentation | `docs/` |
| An example | `examples/` |

See [the contributing guide](https://github.com/AndreVianna/aid-methodology/blob/master/CONTRIBUTING.md) for the full guide.
