# Repository Structure

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
|   |-- skills/                 <- 92 skill definitions (14 classic + aid-triage + aid-ask + 76 shortcuts)
|   |-- agents/                 <- 9 agent definitions
|   `-- aid/                    <- AID toolkit root
|       |-- templates/          <- KB templates, document templates, shortcut engine + catalog
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

All skill, agent, and template content lives here. The generator (`run_generator.py`) renders `canonical/` into the five `profiles/` install trees. **Never edit `profiles/` directly** — your changes will be overwritten on the next generator run.

- `canonical/skills/` — 92 skill definitions, one directory per skill: 14 classic pipeline / on-demand skills, the standalone `aid-triage` router, `aid-ask` (a Q&A alias of the classic `aid-query-kb`), and 76 verb-first Lite-Path shortcut skills (`aid-fix`, `aid-create-api`, `aid-change-ui`, …)
- `canonical/agents/` — 9 agent definitions
- `canonical/aid/templates/` — KB document templates, grading rubric, task templates, `delivery-blueprint-template.md` and `task-detail-template.md` (delivery/task definitions), plus the shortcut system: `shortcut-catalog.yml` (the 80-row catalog every shortcut and `aid-triage` resolve against), `shortcut-engine.md` (the shared state machine every shortcut delegates to), and `shortcut-scaffolding/` (family-specific SPEC/PLAN/DETAIL scaffolding)
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
| A shortcut (new/changed verb-artifact combo) | `canonical/aid/templates/shortcut-catalog.yml` + `canonical/aid/templates/shortcut-scaffolding/` — then run the generator |
| The `aid` CLI or install logic | `bin/`, `lib/`, `install.sh`, `install.ps1` |
| User-facing documentation | `docs/` |
| An example | `examples/` |

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full guide.
