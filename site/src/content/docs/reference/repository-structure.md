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
|   |-- skills/                 <- 14 skill definitions
|   |-- agents/                 <- 9 agent definitions
|   `-- aid/                    <- AID toolkit root
|       |-- templates/          <- KB templates and document templates
|       |-- recipes/            <- 52 lite-path recipes (add-/change-/fix- families)
|       `-- scripts/            <- helper scripts by phase
|-- profiles/                   <- rendered install trees (generated -- do not edit)
|   |-- claude-code/
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

All skill, agent, template, and recipe content lives here. The generator (`run_generator.py`) renders `canonical/` into the five `profiles/` install trees. **Never edit `profiles/` directly** — your changes will be overwritten on the next generator run.

- `canonical/skills/` — 14 skill definitions, one directory per skill
- `canonical/agents/` — 9 agent definitions
- `canonical/aid/templates/` — KB document templates, grading rubric, and task templates
- `canonical/aid/recipes/` — 52 pre-filled lite-path recipe files
- `canonical/aid/scripts/` — helper scripts invoked by skills at runtime (interview, summarize, release, kb-hygiene)

### `profiles/` — generated install trees

Each subdirectory is one rendered tool profile. The layout inside mirrors what `aid add <tool>` copies into a project:

| Profile | Installs into | Root agent file |
|---------|--------------|-----------------|
| `claude-code/` | `.claude/` | `CLAUDE.md` |
| `codex/` | `.codex/` | `AGENTS.md` |
| `cursor/` | `.cursor/` | `AGENTS.md` |
| `copilot-cli/` | `.github/` | `AGENTS.md` |
| `antigravity/` | `.agent/` | `AGENTS.md` |

All five profiles contain byte-identical skill and agent bodies — only the wrapper format differs per tool. A deterministic-verify gate enforces this after every generator run.

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
| A KB template | `canonical/aid/templates/knowledge-base/` |
| A recipe | `canonical/aid/recipes/` |
| The `aid` CLI or install logic | `bin/`, `lib/`, `install.sh`, `install.ps1` |
| User-facing documentation | `docs/` |
| An example | `examples/` |

See [CONTRIBUTING.md](https://github.com/AndreVianna/aid-methodology/blob/master/CONTRIBUTING.md) for the full guide.
