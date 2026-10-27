# Repository Structure

Contributor-oriented map of the AID repository. Tells you where things live and why.

## Top-level layout

The tree lists the tracked top-level entries. Files you will rarely open (`.gitattributes`, `.gitguardian.yaml`, `.gitignore`, `.mcp.json`, `package.json`) are left out of it.

```text
aid-methodology/
|-- bin/                  aid CLI dispatchers: aid (Bash), aid.ps1, aid.cmd
|-- lib/                  install-core libraries: aid-install-core.sh, AidInstallCore.psm1
|-- packages/             npm/ and pypi/ wrappers, both published as aid-installer
|-- canonical/            single source of truth for skills, agents, runtime
|   |-- skills/           one folder per skill (SKILL.md and references/)
|   |-- agents/           one folder per agent (AGENT.md)
|   `-- aid/              toolkit installed as .aid/runtime/
|       |-- rules.md      the AID rules every tool reads through AGENTS.md
|       |-- templates/    KB, work, task, rubric, shortcut and connector templates
|       `-- scripts/      helper scripts, grouped by area
|-- profiles/             per-tool install descriptors (claude-code, codex, cursor,
|                         copilot-cli, antigravity: a .toml and an aid-tool.conf each)
|-- dashboard/            local pipeline dashboard: Python reader, Node and Python servers, UI
|-- chat-node/            agent chat node behind "aid chat": server, adapters, hook installer
|-- site/                 the product website (Astro Starlight)
|-- docs/                 user and maintainer documentation (Markdown)
|-- examples/             worked examples: greenfield, brownfield-full-path, brownfield-lite-path
|-- tests/                canonical suites, installer and UI tests, measurement tools
|-- scripts/              repository checks (checks/) and usage tools (usage/)
|-- design/               design notes kept for maintainers
|-- recovery/             partial files restored from a crashed session; not product code
|-- .aid/                 this repo's own AID project: settings, KB, works, design seeds
|-- .claude/              Claude Code settings and output style for this repo
|-- .cursor/              Cursor agents and rules for this repo
|-- .github/              workflows/, ISSUE_TEMPLATE/, dependabot.yml
|-- install.sh            curl | bash bootstrap installer (Linux / macOS)
|-- install.ps1           irm | iex bootstrap installer (Windows PowerShell)
|-- release.sh            maintainer release script
|-- VERSION               single source of the version number
|-- README.md, CONTRIBUTING.md, AGENTS.md, CLAUDE.md, LICENSE
```

AID is installed in this repo for its own development (dogfooding), so `.aid/` holds a real Knowledge Base and work folders. The shared `.agents/skills/` and `.aid/runtime/` folders that `aid add` creates in an adopter's project are not committed here.

---

## Where things live

### The `aid` CLI (`bin/`, `lib/`, `install.sh`, `install.ps1`)

`bin/aid` (with `bin/aid.ps1` and `bin/aid.cmd` for Windows) is the dispatcher that users run. Its commands are `add`, `status`, `update`, `remove`, `version`, `dashboard`, `projects` and `chat`. It uses the install-core library in `lib/` for download, checksum, extract and manifest work.

`install.sh` and `install.ps1` are the bootstrap entry points. In piped mode they fetch and checksum-verify the install-core library from the GitHub release tag before using it.

`packages/npm/` and `packages/pypi/` are thin wrappers published as `aid-installer`. At pack or build time they vendor `bin/`, `lib/`, `dashboard/`, `chat-node/` and `VERSION`; those vendored copies are not committed.

### `canonical/`: the source of truth

All skill, agent, runtime and template content lives here. Skills and runtime are packaged byte for byte into the shared payload by `release.sh`. Agents are rendered per tool by the maintainer generator (`generate-profile`, run by CI as `run_generator.py`). Never edit generated output; edit `canonical/` and regenerate.

- `canonical/skills/`: one directory per skill, 37 in all. 18 are curated skills: the seven pipeline phases (`aid-discover`, `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`), `aid-config`, `aid-summarize`, `aid-triage`, `aid-chat`, and the on-demand skills `aid-housekeep`, `aid-update-kb`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket`. The other 19 own a row of the shortcut catalog: 8 generated shortcut doorways (`aid-fix`, `aid-create`, `aid-update`, `aid-refactor`, `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`) and 11 hand-written skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, `aid-brainstorm`, `aid-deploy`, `aid-monitor`, `aid-ask`). The catalog also has kind rows (such as `/aid-create api`) that have no directory of their own and run through their family.
- `canonical/agents/`: 9 agents: architect, clerk, developer, interviewer, operator, orchestrator, researcher, reviewer, tech-writer.
- `canonical/aid/templates/`: the 14 Knowledge Base document templates (`knowledge-base/`), the project card, work, delivery and task state templates, the grading rubric, the reviewer ledger schema, the connector assets (`connectors/`), and the shortcut system: `shortcut-catalog.yml`, `shortcut-engine.md` and `shortcut-scaffolding/`.
- `canonical/aid/scripts/`: helper scripts that skills run, in folders `config`, `connectors`, `execute`, `housekeep`, `kb`, `migrate`, `release`, `summarize` and `works`, plus `grade.sh`, the scorer that turns issue tags into a letter grade.
- `canonical/aid/rules.md`: the AID rules. It installs as `.aid/runtime/rules.md`, and the root `AGENTS.md` region points at it.

### `profiles/`: per-tool descriptors

Each tool has a `<tool>.toml` (root folder, agent format, model names per tier) and a `<tool>/aid-tool.conf` (the descriptor `aid add` reads). The files are small; the agent files themselves are rendered at release time and are not stored here.

| Profile | Agents folder | Root instruction files |
|---------|---------------|------------------------|
| `claude-code` | `.claude/agents/` | `AGENTS.md`, and `CLAUDE.md` (imports `AGENTS.md`) |
| `codex` | `.codex/agents/` | `AGENTS.md` |
| `cursor` | `.cursor/agents/` | `AGENTS.md` |
| `copilot-cli` | `.github/agents/` | `AGENTS.md` |
| `antigravity` | `.agent/agents/` | `AGENTS.md` |

All five tools share the skills in `.agents/skills/` and the runtime in `.aid/runtime/`. Claude Code also gets a copy of the skills in `.claude/skills/`.

### `dashboard/` and `chat-node/`

`dashboard/` is the local dashboard started with `aid dashboard start`. It has a Python reader that turns `.aid/` files into a model (`reader/`), a Node server and a Python server (`server/`), the page (`index.html`, `home.html`) and write helper scripts (`scripts/`). `MANIFEST` lists the files that ship.

`chat-node/` is the agent chat component behind `aid chat` and the `aid-chat` skill: the hub and node code (`server/`), per-tool adapters for Claude Code and Cursor (`adapters/`), and a stop-hook installer (`scripts/`). `MANIFEST` lists the files that ship.

### `site/`: the website

An [Astro Starlight](https://starlight.astro.build/) site published at https://aid.casuloailabs.com by the `docs.yml` workflow.

- `astro.config.mjs`, `package.json`, `src/content.config.ts`: site configuration.
- `src/content/docs/`: hand-written pages (get started, guides, concepts, reference, releases, contact).
- `src/components/`: small Astro components, such as `Flow`, that draw diagrams as plain ordered lists.
- `scripts/`: a prebuild generator that runs before every build. It copies the Markdown in `docs/` into the site, builds the reference pages for skills and agents from `canonical/`. Its output is not committed.
- `src/data/`: the plain-language text for each skill (`skills.json`) and agent (`agents.json`). Tests fail if it drifts from `canonical/`.
- `public/`: static files (favicon, `CNAME`, `robots.txt`).
- Tests use Node's built-in test runner (`node:test`). They check the generator and the built pages.

The site reads `docs/` and `canonical/` at build time, so a change there reaches the site on the next build. See [Diagram content reference](diagram-content-reference.md) for how diagrams are kept true.

### `docs/`

User-facing and maintainer documentation. `aid-methodology.md` is the full methodology (about a 40-minute read). `faq.md`, `glossary.md` and `repository-structure.md` are imported into the site unchanged, so GitHub readers and site readers see the same text. The rest: `install.md` (install guide), `release.md` (release runbook), `chat-wake-install.md` (chat wake hook), `diagram-content-reference.md` (diagram upkeep) and `images/`.

### `examples/`

Three tutorial-style worked examples: greenfield, brownfield full path and brownfield lite path. Each walks through the relevant phases and shows the key files they produce.

### `tests/` and `scripts/`

`tests/canonical/` holds the bash suites (`test-*.sh`) for scripts, installers, the dashboard and chat node, with `fixtures/`. `tests/run-all.sh` runs them all and is what CI uses. `tests/windows/` holds the PowerShell installer tests, `tests/ui/` the browser tests for the dashboard, `tests/lib/` shared test helpers, and `tests/measure/` and the `*-baseline.*` files the cost and coverage measurements. See `tests/README.md`.

`scripts/checks/` holds repository-wide checks run from CI (settings schema, review path audit, selector partition). `scripts/usage/` holds a transcript usage roll-up tool.

### `.github/workflows/`

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `test.yml` | Pull request, push to master | Render-drift check, canonical suites, generator self-tests, KB hygiene |
| `installer-tests.yml` | Push to any branch except master, manual | Cross-platform installer smoke tests |
| `coverage-parity.yml` | Changes under `tests/` | Compares executed test assertions against a committed baseline |
| `docs.yml` | Push or pull request touching `site/`, `docs/`, `canonical/` or `VERSION`; manual | Builds and tests the site; deploys to GitHub Pages from master |
| `release.yml` | Push of a `v*` tag | Re-runs the test gate, then publishes the GitHub Release, npm and PyPI packages |

---

## Contributing in the right place

| Want to change... | Edit here |
|-------------------|-----------|
| A skill or agent | `canonical/skills/` or `canonical/agents/`, then run the generator |
| The AID rules every tool reads | `canonical/aid/rules.md`, then run the generator |
| A KB template | `canonical/aid/templates/knowledge-base/` |
| A shortcut (new or changed verb and artifact) | `canonical/aid/templates/shortcut-catalog.yml` and `canonical/aid/templates/shortcut-scaffolding/`, then run the generator |
| The `aid` CLI or install logic | `bin/`, `lib/`, `install.sh`, `install.ps1` |
| The dashboard or agent chat | `dashboard/`, `chat-node/` |
| User-facing documentation | `docs/` |
| A website page or component | `site/src/` |
| An example | `examples/` |

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full guide.
