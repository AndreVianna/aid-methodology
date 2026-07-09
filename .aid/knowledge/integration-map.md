---
kb-category: primary
source: hand-authored
objective: The external systems AID consumes and exposes — version control, GitHub, package registries, host AI-tool harnesses, MCP/Playwright, the connectors registry, the dashboard server, and the canonical→profiles→packages build chain.
summary: Read this for any integration-touching work. AID is a distributed toolkit, not a networked service — most "integrations" are developer-side tools (git, gh, npm, pypi, GitHub Actions) and the five host AI harnesses it installs into. The only runtime HTTP surface is the loopback-bound dashboard server; the connectors registry is a catalog, not a connection manager.
sources:
  - install.sh
  - install.ps1
  - bin/aid
  - release.sh
  - packages/npm/package.json
  - packages/pypi/pyproject.toml
  - .github/workflows/
  - dashboard/server/server.mjs
  - canonical/aid/scripts/summarize/validate-visuals.mjs
  - .aid/connectors/INDEX.md
  - .mcp.json
  - .gitguardian.yaml
  - canonical/aid/scripts/connectors/
  - canonical/aid/templates/connectors/preset-catalog.md
tags: [C2, integrations, external-deps, git, github, npm, pypi, host-tools, dashboard, connectors]
see_also: [pipeline-contracts.md, external-sources.md, infrastructure.md, architecture.md]
owner: architect
audience: [developer, architect]
intent: |
  External integration topology — what AID consumes, what it exposes, and how. Read this for
  integration-touching work (install channels, CI, distribution, host-tool profiles, dashboard,
  connectors).
contracts: []
changelog:
  - 2026-07-09: connectors subsystem refresh (housekeep KB-DELTA) — added the Connectors section (catalog model, .aid/connectors/ home, tool-managed vs aid-managed, .mcp.json, .gitguardian.yaml).
  - 2026-06-25: Initial generation (aid-discover brownfield deep-dive / Integrator lane)
---

# Integration Map

> **Source:** aid-discover (brownfield deep-dive — Integrator)
> **Status:** Complete
> **Last Updated:** 2026-07-09

AID is a methodology delivered as a multi-profile CLI installer. It has no application
backend and almost no network surface. Its integrations are of three kinds: **developer-side
tools** it invokes (git, the `gh` CLI), **distribution channels** it ships through (npm, PyPI,
GitHub Releases, GitHub Actions), and the **five host AI-tool harnesses** it installs its
toolkit into. The single runtime HTTP surface is the read-only dashboard server, bound to
loopback only.

## Contents

- [Overview](#overview)
- [Version Control (git)](#version-control-git)
- [GitHub (gh CLI, Releases, Actions)](#github-gh-cli-releases-actions)
- [Package Registries (npm and PyPI)](#package-registries-npm-and-pypi)
- [Host AI-Tool Harnesses (the five profiles)](#host-ai-tool-harnesses-the-five-profiles)
- [MCP and Playwright](#mcp-and-playwright)
- [Connectors](#connectors)
- [The Dashboard Server](#the-dashboard-server)
- [The Build and Distribution Chain](#the-build-and-distribution-chain)
- [Integration Health Risks](#integration-health-risks)
- [Contracts](#contracts)
- [Conventions](#conventions)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## Overview

> The blast-radius map. Each row is a failure domain.

| Integration | Type | Direction | Criticality | Notes |
|-------------|------|-----------|-------------|-------|
| git | version control | outbound (invokes) | Critical | branch isolation per delivery; release tagging; render-drift check |
| GitHub `gh` CLI | release tooling | outbound | High | `release.sh` cuts/uploads releases; site fetches release data |
| GitHub Releases | distribution | both | High | offline profile tarballs + `SHA256SUMS` |
| GitHub Actions | CI/CD | inbound (triggers) | High | four workflows: test, installer-tests, docs, release |
| npm registry | distribution | outbound (publish) | High | `aid-installer` package; `npm i -g` channel |
| PyPI | distribution | outbound (publish) | High | `aid-installer` package; `pipx install` channel |
| Claude Code / Codex / Cursor / Copilot CLI / Antigravity | host AI harness | outbound (installs into) | Critical | the five render profiles AID targets |
| Playwright (MCP + npm) | browser testing | outbound (invokes) | Medium | dashboard/summary visual-fidelity validation |
| Connectors registry (`.aid/connectors/`) | catalog (descriptors, not a connection manager) | n/a — records only, wires nothing | Medium | tool-managed (`mcp`) connectors are wired by the host tool itself; aid-managed (`api\|ssh\|url\|cli`) connectors resolve a local `secret_reference` at use-time |
| Dashboard HTTP server | local web UI | inbound (serves) | Low | read-only, loopback-bound (127.0.0.1) |

CONFIRMED by the per-integration sections below.

---

## Version Control (git)

AID drives git as a first-class part of the pipeline, not as an external API.

| Use | Where | Direction |
|-----|-------|-----------|
| Branch isolation — one branch per delivery (`aid/{work}-delivery-NNN`) | Execute | invokes `git` |
| Housekeep branch (`aid/housekeep-*`, one commit per stage, never pushes) | Housekeep | invokes `git` |
| Release tagging + clean-worktree + render-drift checks | `release.sh` | invokes `git tag`, `git diff`, `git rev-parse` |

CONFIRMED: `docs/aid-methodology.md` ("Branch isolation"); `release.sh` (`git diff --quiet`,
`git rev-parse -q --verify "refs/tags/${TAG}"`, "render drift (git diff -- profiles/)").

Repository-access note: in this project the agent pushes as a non-admin bot identity and
`master` is branch-protected (PR + checks required). See the project memory for the bot-identity
and PR-only rules — direct/force pushes to `master` are blocked.

---

## GitHub (gh CLI, Releases, Actions)

**`gh` CLI (outbound).** `release.sh` uses `gh release view` (idempotency check),
`gh release create`, and `gh release upload --clobber` to publish the five per-profile
tarballs and `SHA256SUMS`. The site's `gen-reference.mjs` also shells out to `gh`. CONFIRMED:
`release.sh` (`gh release create "${GH_ARGS[@]}"`); `site/scripts/gen-reference.mjs`.

**GitHub Releases (distribution surface).** Profile tarballs (`aid-cli-v*.tar.gz` /
per-profile bundles) plus a `SHA256SUMS` file are published per tag; the offline install path
(`aid add <tool> --from-bundle <file.tar.gz>`) consumes them with no network after download.
CONFIRMED: `docs/aid-methodology.md` ("Offline / air-gapped environments");
`docs/glossary.md` ("--from-bundle").

**GitHub Actions (inbound CI/CD).** Four workflows under `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test.yml` (CI) | push/PR to `master`, dispatch | canonical helper test suites (`tests/run-all.sh`) |
| `installer-tests.yml` | push to non-`master` branches, dispatch | cross-platform installer tests (incl. Windows lane) |
| `docs.yml` (Docs) | push to `master` under `site/`, `docs/`, `VERSION` | builds/deploys the Astro site |
| `release.yml` (Release) | push tag `v*`, dispatch | builds artifacts and cuts the GitHub Release |

CONFIRMED by the `on:` blocks of each file under `.github/workflows/`. Note: the heavy gates
(canonical suites, Astro build) run only on `master`; feature branches skip them — see project
memory on `master`-only CI.

---

## Package Registries (npm and PyPI)

AID ships the same persistent `aid` CLI through four bootstrap channels; two of them are
package registries. The channel is recorded in `AID_INSTALL_CHANNEL` so `aid update self`
prints the correct upgrade command. CONFIRMED: `bin/aid`
(`local channel="${AID_INSTALL_CHANNEL:-}"`); `docs/glossary.md` ("Install channel").

| Registry | Package | Channel command | Wrapper |
|----------|---------|-----------------|---------|
| npm (Node ≥ 18) | `aid-installer` | `npm i -g aid-installer` | `packages/npm/` — vendors `bin/`, `lib/`, `dashboard/`; `prepack` runs `vendor.js`, `postinstall` wires PATH |
| PyPI (Python ≥ 3.8) | `aid-installer` | `pipx install aid-installer` | `packages/pypi/` — `aid_installer/` + `_vendor/`; entry `aid = aid_installer.__main__:main` |

CONFIRMED: `packages/npm/package.json` (name `aid-installer`, `bin.aid`, `files` vendoring,
`prepack`/`postinstall` scripts); `packages/pypi/pyproject.toml` (`project.scripts`,
`artifacts = ["aid_installer/_vendor/**"]`).

The other two channels are `curl | bash` (`install.sh`) and `irm | iex` (`install.ps1`).
All four deliver an identical CLI; only the PATH-wiring method differs. CONFIRMED:
`docs/glossary.md` ("`aid` CLI", "Bootstrap").

---

## Host AI-Tool Harnesses (the five profiles)

AID's primary integration target is the host AI coding tool. The single canonical toolkit is
rendered into five format-adapted install trees, one per host. Bodies are byte-identical
across profiles; only the install root, context-file name, and agent format differ.

| Profile | Install root | Context file | Agent format |
|---------|--------------|--------------|--------------|
| Claude Code | `.claude/` | `CLAUDE.md` | markdown |
| Codex CLI | `.codex/` | `AGENTS.md` | TOML |
| Cursor | `.cursor/` | `AGENTS.md` | markdown |
| GitHub Copilot CLI | `.github/` | `AGENTS.md` | markdown |
| Antigravity | `.agent/` | `AGENTS.md` | markdown |

CONFIRMED: `docs/aid-methodology.md` ("The Five Profiles"); `profiles/` (five subtrees +
`<profile>.toml`); `docs/glossary.md` ("Install Profiles").

Integration mechanics: `aid add <tool>` installs one profile per invocation
(`--tool <name>`, or auto-detect). Root-agent files (`CLAUDE.md` for Claude Code; `AGENTS.md`
for the other four) are updated **in place** inside the `AID:BEGIN/END` region — the installer
replaces only the AID-managed region and preserves everything the user (or another tool)
authored outside it, so multiple `AGENTS.md`-writing tools coexist in one file. There is no
`.aid-new` sidecar and no protect-on-diff exit: the old `.aid-new` / exit-5 path was removed in
v1.1.0 (superseded by in-place region replacement — see `decisions.md` D11). CONFIRMED:
`lib/aid-install-core.sh` (`_copy_root_agent_file`); `decisions.md` D11. The tier→model mapping
per host is declared in `profiles/{tool}.toml`.

---

## MCP and Playwright

Playwright is used as a browser-rendering integration to validate the visual KB/summary
output (it is not a runtime dependency of the installed toolkit). Two surfaces:

- **The visual-fidelity gate** — `validate-visuals.mjs` Playwright-renders every authored
  visual in `kb.html` and asserts legibility, overlap, and layout. It is the S7 gate that
  replaced the prior Mermaid auto-layout guarantee. CONFIRMED:
  `canonical/aid/scripts/summarize/validate-visuals.mjs` (header "Playwright-render every
  authored visual"); `canonical/aid/scripts/summarize/playwright-provisioning.md`.
- **The Playwright MCP server** — the agent uses a Playwright MCP integration during dashboard
  review; its scratch artifacts (console logs + page snapshots) land under `.playwright-mcp/`.
  CONFIRMED: `.playwright-mcp/` (timestamped `console-*.log` / `page-*.yml` files). Per global
  project rule, any review of rendered web output must use Playwright visual validation.

---

## Connectors

The connectors registry (`.aid/connectors/`) is a **catalog**, not a connection manager: it
records which external tools a project's agents may use and how to reach them, but it never
wires a host tool's own configuration. CONFIRMED: `.aid/knowledge/STATE.md` (Q7, "the registry
is a **catalog** (lists what agents can use + how), NOT a connection manager (Q10)");
`canonical/skills/aid-discover/references/state-elicit.md` ("There is no wiring step — AID
neither writes nor triggers any host MCP configuration").

**Home and shape.** `.aid/connectors/` holds one `<stem>.md` descriptor per connector plus a
generated `INDEX.md` (routing table: Connector/Type/Endpoint/Auth/Secret Ref/Summary) and a
git-ignored `.secrets/` directory (`.aid/connectors/.gitignore` → `.secrets/`). The registry is
populated and reconciled by `aid-discover`'s ELICIT state (Step E2) — see
[pipeline-contracts.md](pipeline-contracts.md). The dedicated scripts under
`canonical/aid/scripts/connectors/` are bash+PowerShell twins: `connector-registry.{sh,ps1}`
(`list` / `read <stem> <field>` — the frontmatter accessor), `connector-secret.{sh,ps1}`
(`write <stem>` / `purge <stem>` — no-echo capture and exact-bytes store/delete under
`.secrets/<stem>`), and `build-connectors-index.{sh,ps1}` (deterministic `INDEX.md` builder).
CONFIRMED: `.aid/connectors/INDEX.md` (frontmatter "Routing table for the tool/integration
registry"); `canonical/aid/scripts/connectors/connector-registry.sh`;
`canonical/aid/scripts/connectors/connector-secret.sh`.

**Two management modes, keyed off the descriptor's `connection_type`:**

| Mode | `connection_type` | Auth | Wiring |
|------|--------------------|------|--------|
| Tool-managed | `mcp` | host tool provides its own MCP server/plugin and handles auth; AID stores no credential (`auth_method: none`, no `secret_reference` field) | none — the agent requests the connection from the host tool itself at use-time |
| Aid-managed | `api` \| `ssh` \| `url` \| `cli` | AID records a `secret_reference` (`env:<VAR>` / `file:.aid/connectors/.secrets/<stem>` / `keychain:`) resolved at use-time | none — AID never launches or wires the target; it only records how to reach it |

CONFIRMED: `canonical/aid/templates/connectors/preset-catalog.md` ("Management mode (STATE.md
Q10 — derived from `connection_type`)"); `canonical/skills/aid-discover/references/state-elicit.md`
("Management-mode branch"). The preset catalog (`github`, `gitlab`, `jira`, `slack`,
`confluence`, `notion`, `jenkins`, `docker`) pre-fills sensible defaults per tool; a tool not
listed is declared as `custom`. CONFIRMED: `canonical/aid/templates/connectors/preset-catalog.md`
("## Presets").

**`.mcp.json`** (repo root) is this project's *own* MCP client configuration — distinct from the
connectors registry above (that registry is a catalog for the pipeline's agents to discover and
request tool integrations; `.mcp.json` is the actual host-tool wiring for one specific
tool-managed integration). It configures a single stdio MCP server, `playwright-project`
(`npx @playwright/mcp@latest`, output dir `.aid/.temp/playwright`) — the same Playwright MCP
integration described above. CONFIRMED: `.mcp.json`.

**Secret scanning.** `.gitguardian.yaml` (repo root) configures GitGuardian's secret scan and
excludes the `connector-secret` test fixtures (`tests/canonical/test-connector-secret.sh`,
`test-connector-secret-ps1.sh`, `test-connector-secret-ac3-leak-sweep.sh`), which intentionally
carry fake secret values to exercise the no-echo write/purge/leak-sweep behavior. CONFIRMED:
`.gitguardian.yaml` ("The connector-secret test suites exist to exercise the secret-handling
twin … intentional FAKE secret values as test fixtures").

---

## The Dashboard Server

A local, read-only web dashboard reads `.aid/` state across registered repos. It has parity
implementations in Node (`server.mjs`) and Python (`server.py`). It exposes HTTP but is bound
to loopback only and never writes to disk.

| Property | Value |
|----------|-------|
| Bind | literal `127.0.0.1` only (SEC-1); never `0.0.0.0`/wildcard |
| Routes | `GET /` (CLI-home), `GET /api/home`, `GET /r/<id>/home.html`, `GET /r/<id>/kb.html`, `GET /r/<id>/api/model`; other path → 404; non-GET → 405 |
| State source | `AID_HOME/registry.yml` (primary) ∪ `$HOME/.aid/registry.yml` (user fallback) |
| Code/asset source | self-located from the install tree (`index.html`, `VERSION`), independent of `AID_HOME` |
| Write surface | none — no `fs` write/append/unlink primitives (SEC-3); no agent/LLM import (SEC-4) |

CONFIRMED: `dashboard/server/server.mjs` (header "Routes (NEW closed allowlist)",
"Binds literal 127.0.0.1 only (SEC-1)", "two-tier union of AID_HOME/registry.yml …").
The reader layer (`dashboard/reader/`) parses KB + work `STATE.md` files into the
`RepoModel`/`TaskStatus` models the API serves — see [domain-glossary.md](domain-glossary.md).

The server is launched via the `aid dashboard` subcommand, which sets
`AID_HOME=$AID_STATE_HOME` so the server resolves the registry through its env var, then runs
the interpreter on `127.0.0.1`. CONFIRMED: `bin/aid`
(`AID_HOME="$AID_STATE_HOME" setsid "$interp" "$entry_point" --host 127.0.0.1 --port`).

---

## The Build and Distribution Chain

This is the internal integration chain that turns the source of truth into shippable
artifacts. Each arrow is a hard, verified hand-off.

- **Render:** `run_generator.py` reads `canonical/` and `canonical/EMISSION-MANIFEST.md` and
  renders the five `profiles/` trees per `profiles/*.toml`. CONFIRMED:
  `.claude/skills/generate-profile/scripts/run_generator.py`;
  `.claude/skills/generate-profile/scripts/render.py` (imports `EmissionManifest`).
- **Verify:** a deterministic VERIFY gate re-renders into a scratch dir and byte-compares
  against the committed `profiles/`; any mismatch is a hard failure (also enforced as CI
  render-drift). CONFIRMED: `docs/aid-methodology.md` ("A VERIFY (deterministic) gate");
  `release.sh` ("render drift (git diff -- profiles/)").
- **Vendor + publish:** `packages/npm/` and `packages/pypi/` vendor `bin/`, `lib/`, and
  `dashboard/` and publish `aid-installer`; `release.sh` packages per-profile tarballs +
  `SHA256SUMS` to GitHub Releases. CONFIRMED: `packages/npm/package.json` (`prepack` vendor);
  `release.sh`.
- **Install:** `install.sh`/`install.ps1` (or the registry shims) put the persistent `aid`
  CLI on PATH; `aid add <tool>` copies a profile into the user project. CONFIRMED:
  `docs/aid-methodology.md` ("The build pipeline").

---

## Integration Health Risks

| Integration | Risk | Mitigation |
|-------------|------|-----------|
| Five-profile render | Editing `profiles/` directly diverges from `canonical/` | VERIFY byte-compare gate + CI render-drift fail on mismatch |
| Distribution manifests | npm/pypi/curl/release bundles can drift on the file set (e.g. a missing `dashboard/home.html`) | keep the install manifests in lockstep; install-migrate smoke tests (see project memory) |
| Version registries | npm/PyPI versions are immutable — a bad publish burns a version | rebuild bundle from clean HEAD; deprecate/yank on mistake (see release memory) |
| Windows host | shipped PS must stay Windows-PowerShell-5.1-compatible and ASCII-only | AST lint + real 5.1 CI lane; ASCII-only guard |
| Dashboard server | serving project state over HTTP | loopback-only bind (SEC-1) + read-only (SEC-3) by construction |
| `gh`/network in release | `gh release create` needs auth + network | `--dry-run` assembles artifacts with no network I/O |

CONFIRMED by the cited sources above and the project release/install memory notes.

---

## Contracts

> The structural shapes a change MUST satisfy at an integration boundary.

- **Profile render contract:** for all five profiles the skill/agent *bodies* are
  byte-identical; only install root, context-file name, and agent format vary. Any change must
  go through `canonical/` + re-render; the VERIFY gate binds every profile consumer.
- **Install-manifest contract:** the npm `files` list, the PyPI `artifacts`/wheel include, the
  `release.sh` tarball set, and `install.sh`/`install.ps1` must agree on the shipped file set
  (`bin/`, `lib/`, `dashboard/`, `VERSION`). A file added to one must be added to all.
- **Dashboard API contract:** the server emits the DM-1 (`/r/<id>/api/model`) and DM-2
  (`/api/home`) JSON envelopes with declared key order, compact, no trailing newline, UTF-8;
  the Node and Python servers must stay byte-identical. The `index.html` reader binds to these
  shapes — changing a key breaks the UI.
- **Channel contract:** all four bootstrap channels deliver the same `aid` CLI;
  `AID_INSTALL_CHANNEL` must be set correctly per channel so `aid update self` prints the right
  upgrade command. Compatibility rule: additive — adding a channel must not change the others'
  recorded channel value.

---

## Conventions

- **Integrations are developer-side tools, not networked services.** Every external system
  (git, gh, npm, PyPI, GitHub Actions, the five host AI tools) is a CLI/library AID invokes;
  there is no inbound network surface except the loopback dashboard.
- **Host tools are integrated by render, not adapter.** AID targets each of the five host AI
  harnesses by rendering byte-identical skill/agent bodies into that tool's install tree (its
  install root + context-file name + agent format); there is no per-tool runtime branching.

---

## Invariants

- **The dashboard HTTP server is loopback-bound (127.0.0.1) and read-only** -- it writes nothing
  to the repo and runs no LLM.
- **External tool versions are pinned where they gate shippable artifacts** (the PowerShell 5.1
  floor; the CI Node/Python pins); changing a pinned harness version is a lockstep change that
  the parity/compat suites guard.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial integration surface mapping (Integrator deep-dive) |
| 1.1 | 2026-07-09 | housekeep KB-DELTA | connectors subsystem refresh (housekeep KB-DELTA): added the Connectors section (catalog model, `.aid/connectors/` registry home, tool-managed vs aid-managed modes, `.mcp.json`, `.gitguardian.yaml` secret-scan exclusions), an Overview row, and refreshed Last Updated. |
