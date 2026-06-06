---
kb-category: primary
source: hand-authored
intent: |
  Describes the hosting, runtime, build pipeline, distribution, CI/CD, and dev tooling for
  the AID-methodology repo. There is no conventional runtime infrastructure (no Docker, no
  cloud, no Terraform). "Infrastructure" here means: the persistent global `aid` CLI (and
  its four install channels) that puts AID into a target project, the canonical→5-profiles
  render pipeline driven by run_generator.py, the tag-triggered release pipeline (release.sh
  + release.yml that cut GitHub Releases and publish the npm/PyPI packages), and the
  local-filesystem conventions for runtime state. Read this to understand how AID is built,
  installed, released, and operated on a local workstation.
contracts: []
changelog:
  - 2026-06-05: work-002-auto-installer — installer evolved from setup.sh/setup.ps1 clone+run to a persistent global `aid` CLI (`bin/aid` + `bin/aid.ps1` + `bin/aid.cmd`, shared libs `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`, bootstrap `install.sh` / `install.ps1`); four install channels (curl/irm bootstrap, npm `aid-installer`, PyPI `aid-installer`, offline `--from-bundle`); added the release pipeline (`release.sh` + `.github/workflows/release.yml`, tag-triggered, OIDC publish) and the cross-platform installer CI (`.github/workflows/installer-tests.yml`); GitHub Releases v0.7.0-v0.7.5 now exist (`VERSION` = 0.7.5). `setup.sh`/`setup.ps1` removed.
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — canonical render pipeline 3→5 profiles (added copilot-cli + antigravity); install menu now 5 tools with the Option-A AGENTS.md last-installed-wins non-interactive collision handler; build-pipeline component table gained the 2 new emitter self-tests (test_copilot_emitter.py, test_antigravity_emitter.py) now wired into the CI generator-selftests step. Verified profiles=5 (`ls profiles/*.toml`).
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Infrastructure

> **Source:** `aid-researcher` (quality doc-set) (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-06-05
> **Scope:** This repo ships a methodology + a multi-tool distribution. There is **no runtime infrastructure** in the conventional sense — no Docker, no Terraform, no Kubernetes, no cloud account, no managed services. "Infrastructure" here means: the persistent global `aid` CLI (and its four install channels) that puts AID into a target project, the canonical → 5-profiles render pipeline, the tag-triggered release pipeline (GitHub Releases + npm/PyPI), the supporting toolchain (git, gh, python, bash, node, pwsh), and the local-filesystem conventions for runtime state.

---

## Hosting & Runtime Environment

**Local-only.** AID runs on the maintainer's or end user's workstation, inside whichever AI host tool they have installed (Claude Code / Codex CLI / Cursor IDE / GitHub Copilot CLI / Antigravity). There is no server, no daemon, no port, no cloud presence owned by this project.

| Environment | Where it runs | Operated by |
|-------------|---------------|-------------|
| Maintainer build | Local workstation (Windows, macOS, Linux) | The maintainer |
| End-user runtime | Local workstation, inside Claude Code / Codex / Cursor / Copilot CLI / Antigravity host | The end user |
| GitHub repo | `github.com/AndreVianna/aid-methodology` | GitHub (managed by AndreVianna account; see user memory `reference_repo-push-access.md`) |

No NAT, no VPN, no firewall rule lives in this repo. No production environment exists.

---

## Containerization

**None.**

- No `Dockerfile` anywhere in the repo (confirmed by file-system search).
- No `docker-compose.yml`, no `Containerfile`, no `.dockerignore`.
- No mention of Docker / container runtime in any installer (`bin/aid`, `install.sh`, `install.ps1`) or in `CLAUDE.md`.

End users install AID directly into a host filesystem; the host AI tool (Claude Code, etc.) provides whatever isolation it provides.

---

## Infrastructure-as-Code

**None.**

- No `*.tf` (Terraform) files.
- No `*.bicep`, no Pulumi (`*.ts`/`*.py` declaring `pulumi.Stack`), no CloudFormation YAML/JSON.
- No `serverless.yml`, no `sam.yaml`.
- No Ansible playbooks, no Chef cookbooks, no Puppet manifests.

The closest analog is the **profile-render pipeline** (see Build Pipeline below), which is declarative-ish (`profiles/*.toml` declare what each install tree should contain).

---

## Orchestration / Service Mesh

**None.** No Kubernetes, no Nomad, no service mesh — there are no services to orchestrate.

The closest analog is the **AID parallel pool dispatch model** (work-001 feature-009 — see `canonical/skills/aid-execute/SKILL.md §Pool Dispatch`): `aid-execute` runs a PD-0..PD-6 pool with `MaxConcurrent` capacity to dispatch subagents in parallel. This is in-process scheduling within a single AI host invocation, NOT an orchestration platform.

---

## CI / CD Pipeline

The repo runs **three GitHub Actions workflows**: the PR-gate (`test.yml`), the cross-platform installer suite (`installer-tests.yml`), and the tag-triggered release pipeline (`release.yml`).

**CI gate (enforced).** `.github/workflows/test.yml` (added 2026-05-29) runs render-drift + canonical suites + generator self-tests + hygiene on every PR/push and is a required status check for merging to `master` (branch protection enabled 2026-05-29). The suite job invokes `tests/run-all.sh`, which discovers suites by glob (`tests/canonical/test-*.sh`), so the count is not hard-coded (currently 35; see `test-landscape.md`). The `generator-selftests` job additionally runs three Python generator self-tests with `--self-test` (`.github/workflows/test.yml`): `test_manifest_safety.py`, plus the two emitter tests `test_copilot_emitter.py` (Copilot real-YAML round-trip) and `test_antigravity_emitter.py` (Antigravity rule reshape).

**Installer CI (cross-platform).** `.github/workflows/installer-tests.yml` (`name: Installer CI (cross-platform)`) runs a two-leg matrix: `ubuntu-latest` (`mode: bash-harness`) drives the bash installer/CLI/release suites, and `windows-latest` (`mode: native-ps1`) runs the native PowerShell installer test plus the npm + PyPI Windows channel smokes (pack/build → global install → `aid status`/`aid add`). Both legs assert `pwsh` is present so PowerShell coverage cannot silently skip (the `Assert pwsh present` step). This is the runner that exercises the real-Windows path the Linux bash harness cannot.

**Release pipeline (tag-triggered).** `.github/workflows/release.yml` (`name: Release`) fires on `push` of a `v*` tag (with a `workflow_dispatch` escape hatch carrying `ref` + `dry_run` inputs). A `gate` job re-runs the same correctness invariants as `test.yml` (render-drift + canonical suites + generator self-tests) plus the **FR10 version-sync** check (`VERSION` == `packages/npm/package.json` == `packages/pypi/pyproject.toml` == tag) on the tagged commit; all publish jobs sit behind `needs: [gate]` so nothing publishes from an ungated state. Three publish jobs follow: `github-release` (runs `release.sh` to build tarballs + `SHA256SUMS` and `gh release create`), `npm-publish` (gated on repo variable `NPM_ENABLED == 'true'`; `npm publish --provenance --access public`), and `pypi-publish` (gated on `PYPI_ENABLED == 'true'`; `pypa/gh-action-pypi-publish` via Trusted Publishing). The workflow declares least-privilege `permissions: contents: write` (release upload) + `id-token: write` (OIDC for npm provenance + PyPI Trusted Publishing); no long-lived PyPI token is stored. Real GitHub Releases **v0.7.0 through v0.7.5** exist (`gh release list`); `VERSION` = `1.0.0`.

**Published packages.** Two thin-shim packages are published from `packages/`: **npm** `aid-installer` (`packages/npm/package.json`) and **PyPI** `aid-installer` (`packages/pypi/pyproject.toml`). Both vendor the CLI payload (`bin/` + `lib/`) and spawn `bin/aid`; neither carries runtime dependencies. The npm/PyPI publish steps remain blocked behind the `NPM_ENABLED`/`PYPI_ENABLED` repo variables until the registry scope/org + credentials exist (see the external-setup blockers comment block atop `release.yml`); the GitHub Releases channel is live. No Homebrew or Chocolatey channel exists.

---

## Build Pipeline (the "infrastructure" of this repo)

The canonical → 5-profiles render is the **only build artifact pipeline** in the codebase (the 5 profiles: claude-code, codex, cursor, copilot-cli, antigravity — `ls profiles/*.toml`). It is fully local, fully deterministic, and has no external dependencies beyond Python 3.11+.

| Component | Path | Lines | Purpose |
|-----------|------|-------|---------|
| Generator entrypoint | `.claude/skills/aid-generate/scripts/run_generator.py` | 87 | Loops `profiles/*.toml` (5 profiles: claude-code, codex, cursor, copilot-cli, antigravity), calls each renderer, runs VERIFY (deterministic) + VERIFY (advisory) |
| Profile parser | `.claude/skills/aid-generate/scripts/aid_profile.py` | 550 | Parses TOML, validates schema |
| Manifest harness | `.claude/skills/aid-generate/scripts/render_lib.py` | 756 | Emission-manifest implementation; pure-mirror deletion logic |
| Agent renderer | `.claude/skills/aid-generate/scripts/render_agents.py` | 522 | Renders `canonical/agents/` per profile |
| Skill renderer | `.claude/skills/aid-generate/scripts/render_skills.py` | 469 | Renders `canonical/skills/` per profile (Thin-Router + references/) |
| Recipe renderer | `.claude/skills/aid-generate/scripts/render_recipes.py` | 261 | Renders `canonical/recipes/` (passthrough) |
| Script renderer | `.claude/skills/aid-generate/scripts/render_canonical_scripts.py` | 224 | Renders `canonical/scripts/` per profile |
| Template renderer | `.claude/skills/aid-generate/scripts/render_templates.py` | 252 | Renders `canonical/templates/` per profile |
| Strict verifier | `.claude/skills/aid-generate/scripts/verify_deterministic.py` | 515 | VERIFY (deterministic) — re-run byte-identical guarantee |
| Advisory verifier | `.claude/skills/aid-generate/scripts/verify_advisory.py` | 343 | VERIFY (advisory) — advisory checks |
| Generator self-tests | `.claude/skills/aid-generate/scripts/test_manifest_safety.py` | 254 | Internal correctness tests (pure-mirror deletion safety) |
| Copilot emitter self-test | `.claude/skills/aid-generate/scripts/test_copilot_emitter.py` | — | Copilot agent-format emitter — real-YAML round-trip (CI `generator-selftests`, `--self-test`) |
| Antigravity emitter self-test | `.claude/skills/aid-generate/scripts/test_antigravity_emitter.py` | — | Antigravity rule-format reshape (CI `generator-selftests`, `--self-test`) |

Pipeline flow (per `run_generator.py`, the `for profile_path in sorted(profiles_dir.glob('*.toml'))` loop):

```
profiles/*.toml ─┐
                 ▼
          load_profile + validate
                 ▼
   render_agents → render_skills → render_templates → render_scripts → render_recipes
                 ▼
   diff prev manifest → delete removed files → prune empty parents
                 ▼
       write emission-manifest.jsonl
                 ▼
   VERIFY (deterministic) (strict — must pass, exits 1 on failure: `run_generator.py` `run_verify` call)
                 ▼
   VERIFY (advisory) (advisory — reports counts only: `run_generator.py` `run_advisory` call)
```

**Note (Q2 resolution, cycle-1):** `run_generator.py` previously wrote VERIFY (deterministic) / VERIFY (advisory) reports to `.aid/work-002-canonical-generator/`. That write was eliminated by passing `report_path=None`; the directory is no longer created or required.

---

## Install Pipeline (the `aid` CLI + four channels)

The end-user install entrypoint is a **persistent global `aid` CLI**, not a clone-and-run script. It is bootstrapped once per machine, then invoked per project with subcommands. (The former `setup.sh` / `setup.ps1` clone+run installers were removed by work-002-auto-installer.)

**CLI layout.** The dispatcher and shared engine live at the repo root and are extracted into `$AID_HOME` (default `~/.aid` on Unix, `%LOCALAPPDATA%\aid` on Windows) at bootstrap:

| Component | Path | Platform |
|-----------|------|----------|
| Bash dispatcher | `bin/aid` | macOS, Linux, WSL, git-bash |
| PowerShell dispatcher | `bin/aid.ps1` | Windows |
| cmd.exe shim | `bin/aid.cmd` | Windows (resolves `aid` in cmd.exe; tries `pwsh` then `powershell`) |
| Bash install-core | `lib/aid-install-core.sh` | sourced by `bin/aid` and by `install.sh` in piped mode |
| PowerShell install-core | `lib/AidInstallCore.psm1` | imported by `bin/aid.ps1` and by `install.ps1` |
| Bash bootstrap | `install.sh` | curl-piped first install (`curl -fsSL …/install.sh \| bash`) |
| PowerShell bootstrap | `install.ps1` | irm-piped first install (`irm …/install.ps1 \| iex`) |

`bin/aid` parses the subcommand and dispatches into `lib/aid-install-core.sh`, operating on the current working directory (`--target` / `AID_TARGET` overrides). Subcommands: `aid` (bare → project dashboard), `aid status`, `aid add <tool>[,...]`, `aid update [<tool>... | self]`, `aid remove [<tool>... | self]`, `aid version`. Shared flags: `--from-bundle <path>` (offline install), `--version <v>` (pin a release), `--force`, `--target <dir>`, `--verbose`. The tools are the five profile names: `claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity` (`bin/aid` `_aid_usage`).

**Four install channels.** All four deliver the same `aid` CLI:

| Channel | First-install command | Source |
|---------|-----------------------|--------|
| curl/irm bootstrap | `curl -fsSL …/install.sh \| bash` / `irm …/install.ps1 \| iex` | `install.sh`, `install.ps1` |
| npm | `npm i -g aid-installer` (or `npx aid-installer add <tool>`) | `packages/npm/` → published `aid-installer` |
| PyPI | `pipx install aid-installer` (or `pip install --user aid-installer`) | `packages/pypi/` → published `aid-installer` |
| Offline / air-gapped | download a release tarball, verify against `SHA256SUMS`, then `aid add <tool> --from-bundle <path>` | GitHub Releases assets |

The npm and PyPI packages are **thin shims**: `packages/npm/bin/aid.js` and `packages/pypi/aid_installer/__main__.py` vendor the `bin/` + `lib/` payload and spawn `bin/aid` (Unix) or `bin/aid.ps1` (Windows, `pwsh` then `powershell`), injecting `AID_INSTALL_CHANNEL=npm`/`pypi` so that `aid update self` prints the channel-correct upgrade hint (`npm i -g aid-installer@latest` / `pipx upgrade aid-installer`) instead of re-bootstrapping (`bin/aid` `AID_INSTALL_CHANNEL` guard).

**Bootstrap trust model.** The piped bootstrap fetches the `aid-cli-v<VERSION>.tar.gz` bundle from the matching GitHub Release and verifies its SHA-256 against the release `SHA256SUMS` before extracting into `$AID_HOME` and wiring PATH (`install.sh` `_source_install_core` / bundle-verify block). `aid add` likewise verifies each downloaded profile tarball against `SHA256SUMS`.

**FR11 protect-on-diff.** When `aid add`/`aid update` would overwrite a root agent file (`CLAUDE.md` / `AGENTS.md`) the user authored themselves, the incoming version is written as `*.aid-new` for review rather than overwriting silently (per `docs/install.md` `## Protect-on-diff for root agent files`).

**FR12 invariant root `AGENTS.md`.** The four AGENTS.md-writing tools (Codex, Cursor, Copilot CLI, Antigravity) now ship a **byte-identical** root `AGENTS.md`; a CI guard (`tests/canonical/test-agents-md-invariant.sh`) asserts the four profile copies are identical, replacing the former last-installed-wins Option-A collision dance.

The install/CLI/release surface is covered by the `tests/canonical/test-install*.sh`, `test-aid-cli*.sh`, and `test-release*.sh` suites plus `tests/windows/Test-AidInstaller.ps1` (native Windows), all run by `installer-tests.yml` (see CI / CD Pipeline above and `test-landscape.md`).

---

## Source Control

**Git + GitHub.**

| Aspect | Value | Evidence |
|--------|-------|----------|
| VCS | Git | `.git/` directory present |
| Hosting | GitHub | per user memory `reference_repo-push-access.md` (account `AndreVianna`) |
| Repo URL | `github.com/AndreVianna/aid-methodology` | per user memory |
| Default branch | `master` | git remote info |
| Current working branch | current working branch — `git branch --show-current` (volatile; not pinned here) | git status |
| Branch convention | Per-`work-NNN` persistent branch off master; no per-task / per-feature branches | `coding-standards.md §7f`; user memory `feedback_single-branch-work.md` |

Recent merge history is volatile temporal data (T4) and is not pinned here — read it live with `git log --oneline --merges -20`.

Branch protection on `master` (per `gh api repos/AndreVianna/aid-methodology/branches/master/protection`, reconciled 2026-06-03):
- **Required pull request reviews:** 1 approving review required; stale reviews dismissed on new push; code-owner reviews NOT required; last-push approval NOT required
- **Required signatures:** disabled
- **Enforce admins:** disabled (admins can bypass)
- **Required linear history:** disabled (merge commits allowed)
- **Force pushes:** blocked
- **Branch deletion:** blocked
- **Conversation resolution required before merge:** enabled
- **Branch lock:** disabled

---

## Project Management

**Lives on GitHub.** Issues + Pull Requests are the project-management substrate; the repo carries no `JIRA`-style identifier, no `roadmap.md`, no Linear / Asana / Trello integration.

The `gh` CLI is the maintainer's primary tool for PR creation, issue triage, and release operations — confirmed by:
- User memory `reference_repo-push-access.md` (gh CLI account requirement).
- `canonical/templates/long-wait-protocol.md` and similar docs assume `gh` is available.

---

## Toolchain (the dev/runtime dependencies)

| Tool | Version | Used for | Evidence |
|------|---------|----------|----------|
| Python | 3.11+ (stdlib `tomllib`) | Generator pipeline | `.claude/skills/aid-generate/scripts/render_lib.py` `Requirements: Python 3.11+` |
| Python | 3.8+ (`requires-python`) | PyPI `aid-installer` package build (hatchling) + shim runtime | `packages/pypi/pyproject.toml` `requires-python = ">=3.8"`; `[build-system] requires = ["hatchling"]` |
| Node | 18+ (`engines.node`) | npm `aid-installer` package + shim runtime | `packages/npm/package.json` `"engines": { "node": ">=18" }` |
| Bash | POSIX-compatible | All `canonical/scripts/` + `tests/canonical/` + `bin/aid` + `install.sh` + `lib/aid-install-core.sh` | `#!/usr/bin/env bash` at top of every script |
| PowerShell | 5.1+ | `bin/aid.ps1` + `install.ps1` + `lib/AidInstallCore.psm1` + `assemble-3part.ps1` | `assemble-3part.ps1` `#Requires -Version 5.1`; the npm/PyPI shims try `pwsh` then `powershell` on Windows |
| Node | 18+ | `aid-summarize` validators (`*.mjs`) + Mermaid CLI | `README.md` `Node 18+` requirements bullet (per scout) |
| Git | any modern | VCS | implicit |
| GitHub CLI (`gh`) | any modern | PR/issue/release operations | user memory; called by AID docs |
| curl | any modern | `fetch-mermaid.sh` outbound HTTPS (pinned jsdelivr download only) | `canonical/scripts/summarize/fetch-mermaid.sh` `curl -sSf --max-time 120` |
| sha256sum or shasum | any | `fetch-mermaid.sh` SHA verify (cache-hit + post-download) | `canonical/scripts/summarize/fetch-mermaid.sh` `compute_sha256()` + the two `EXPECTED_SHA256` mismatch guards |
| yq (optional) | any | `read-setting.sh` defers to it for complex YAML | `canonical/scripts/config/read-setting.sh` `install yq and the script will defer to it` |

---

## Runtime State / Local Filesystem Conventions

These directories function as "infrastructure" at runtime — they hold ephemeral or per-project state:

| Path | Purpose | Gitignored? |
|------|---------|-------------|
| `.aid/knowledge/` | Knowledge Base output (this scout's target) | **No** — KB is committed |
| `.aid/.heartbeat/` | Per-subagent heartbeat files (visibility patch L3) | Yes — `.gitignore` `.aid/.heartbeat/` entry (explicit) |
| `.aid/.temp/` | Scratch | Yes — explicit `.gitignore` entry (`.aid/.temp/`) |
| `.aid/generated/` | Build outputs the maintainer wants to track (`project-index.md`) | **No** — selectively committed |
| `.aid/templates/` | Runtime template copies | **No** — committed |
| `.aid/settings.yml` | AID pipeline configuration (single source of truth) | **No** — committed |
| `.aid/knowledge/.cache/` | Mermaid JS cache (per `fetch-mermaid.sh`; cache file is SHA-verified before use) | Yes — `.gitignore` `.aid/knowledge/.cache/` entry |
| `.claude/worktrees/` | Claude Code worktree state (legacy; worktrees are RETIRED per `coding-standards.md §7f`) | Yes — `.gitignore` `.claude/worktrees/` entry |
| `.claude/settings.local.json` | Per-developer Claude Code overrides | Yes — `.gitignore` `.claude/settings.local.json` entry |

---

## Network Egress

The **single outbound HTTP call** in the entire codebase is `canonical/scripts/summarize/fetch-mermaid.sh`:

- `https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js` (the `URL=` assignment) — JS download for the pinned version

The npm registry (`registry.npmjs.org/mermaid/latest`) is no longer queried. The version is derived from the `PINNED_VERSION` constant; `LATEST` is set via `${PINNED_VERSION#v}` — no outbound lookup.

The download is SHA-verified against the `EXPECTED_SHA256` constant on the post-download path (the second `EXPECTED_SHA256` mismatch guard, just before the `# Write meta` block). The cached file is also SHA-verified before use on the cache-hit path (the first `EXPECTED_SHA256` mismatch guard, inside the cache-hit branch). A `.meta` file records version metadata but is treated as untrusted — only the SHA comparison is the actual trust boundary.

No other script makes outbound HTTPS. No telemetry, no analytics, no auto-update check.

**Supply-chain posture:** C1 (unpinned fetch) is resolved — see `tech-debt.md` C1 (RESOLVED 2026-05-29).

---

## Disaster Recovery / Backups

**Not applicable.** The repo IS the artifact; GitHub holds the canonical copy. There is no production database to back up. Recovery from a destructive local edit = `git reset` / `git checkout` against `origin/master`.

The relevant historical incident: PR #12 lost 63 commits via worktree sprawl, recovered via PR #13 (per user memory `feedback_single-branch-work.md`). The single-branch-work convention is the operational mitigation; no automated DR exists.

---

## Monitoring / Observability

**None at runtime** — there's no service to monitor.

In-loop observability (during an AID skill invocation):
- **L1 traceability** — `[State: NAME]` markers in every subagent dispatch (per `coding-standards.md §5a`).
- **L2 traceability** — ETA bracket pairs (▶/✓) on long-running dispatches (per `coding-standards.md §5b`).
- **L3 traceability** — heartbeat files in `.aid/.heartbeat/` updated by every long-running subagent at a configurable interval (default 1 minute per `.aid/settings.yml` `heartbeat_interval`).

Calibration is logged unconditionally — per `coding-standards.md §5c` and user memory `feedback_traceability-unconditional.md`. This is observability of the *agentic pipeline itself*, not of any deployed system.
