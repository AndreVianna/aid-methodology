---
kb-category: primary
source: hand-authored
intent: |
  Describes the hosting, runtime, build pipeline, and dev tooling for the AID-methodology
  repo. There is no conventional runtime infrastructure (no Docker, no cloud, no Terraform).
  "Infrastructure" here means: install scripts (setup.sh / setup.ps1) that put AID into a
  target project, the canonical→5-profiles render pipeline driven by run_generator.py, and
  the local-filesystem conventions for runtime state. Read this to understand how AID is
  built, installed, and operated on a local workstation.
contracts: []
changelog:
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — canonical render pipeline 3→5 profiles (added copilot-cli + antigravity); setup menu now 5 tools + Done=6 (4=GitHub Copilot CLI, 5=Antigravity) with the Option-A AGENTS.md last-installed-wins non-interactive collision handler; build-pipeline component table gained the 2 new emitter self-tests (test_copilot_emitter.py, test_antigravity_emitter.py) now wired into the CI generator-selftests step. Verified profiles=5 (`ls profiles/*.toml`), setup.sh menu options 1-5 + `[6] Done`.
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Infrastructure

> **Source:** `aid-researcher` (quality doc-set) (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27
> **Scope:** This repo ships a methodology + a multi-tool distribution. There is **no runtime infrastructure** in the conventional sense — no Docker, no Terraform, no Kubernetes, no cloud account, no managed services. "Infrastructure" here means: the install scripts that put AID into a target project, the canonical → 5-profiles render pipeline, the supporting toolchain (git, gh, python, bash), and the local-filesystem conventions for runtime state.

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
- No mention of Docker / container runtime in any setup script (`setup.sh`, `setup.ps1`) or in `CLAUDE.md`.

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

**CI is enforced** — `.github/workflows/test.yml` (added 2026-05-29) runs render-drift + canonical suites + generator self-tests + hygiene on every PR/push and is a required status check for merging to `master` (branch protection enabled 2026-05-29). The suite job invokes `tests/run-all.sh`, which discovers suites by glob (`tests/canonical/test-*.sh`), so the count is not hard-coded (currently 24; see `test-landscape.md`). The `generator-selftests` job additionally runs three Python generator self-tests with `--self-test` (`.github/workflows/test.yml`): `test_manifest_safety.py`, plus the two new emitter tests `test_copilot_emitter.py` (Copilot real-YAML round-trip) and `test_antigravity_emitter.py` (Antigravity rule reshape).

There is also no **release pipeline** — the project distributes via:
1. End users cloning the repo and running `setup.sh` / `setup.ps1` against a target directory, OR
2. End users invoking `gh` CLI commands manually (see `gh` Tool below).

There is no published package on npm, PyPI, Homebrew, Chocolatey, or any other package registry.

---

## Build Pipeline (the "infrastructure" of this repo)

The canonical → 5-profiles render is the **only build artifact pipeline** in the codebase (the 5 profiles: claude-code, codex, cursor, copilot-cli, antigravity — `ls profiles/*.toml`). It is fully local, fully deterministic, and has no external dependencies beyond Python 3.11+.

| Component | Path | Lines | Purpose |
|-----------|------|-------|---------|
| Top-level entrypoint | `run_generator.py` | 87 | Loops `profiles/*.toml` (5 profiles: claude-code, codex, cursor, copilot-cli, antigravity), calls each renderer, runs VERIFY (deterministic) + VERIFY (advisory) |
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

## Install Pipeline (end-user installer)

The **`setup.sh` / `setup.ps1` pair** is the end-user-facing install entrypoint. It is the "infrastructure" that delivers AID into a new project.

| Script | Path | Platform |
|--------|------|----------|
| Bash installer | `setup.sh` | macOS, Linux, WSL |
| PowerShell installer | `setup.ps1` | Windows |

Both scripts accept a target directory and an interactive menu with **5 tool options + Done**: `1 = Claude Code`, `2 = Codex`, `3 = Cursor`, `4 = GitHub Copilot CLI`, `5 = Antigravity`, `[6] Done` (multi-select). They copy the matching `profiles/<tool>/` tree into the target — Copilot installs a `.github/` subtree + root `AGENTS.md`, Antigravity installs a `.agent/` subtree (`.agent/skills`, `.agent/rules`) + root `AGENTS.md`. See `setup.sh` `tool_name()` / `print_menu()` and `setup.ps1` `Get-ToolName` / `Show-Menu` for the argument-parsing and menu-state code.

**Option-A AGENTS.md multi-install collision handler.** Four of the five tools (Codex, Cursor, Copilot CLI, Antigravity) write a root `AGENTS.md`; Claude Code uses `CLAUDE.md` only. When **≥2** AGENTS.md-writing tools are selected, `setup.sh` sets `AGENTS_COLLISION=1`, warns once (`Note: … all install a shared AGENTS.md; the last-installed tool's version wins …`), and resolves **non-interactively** with **last-installed-wins** — the survivor is the highest-numbered selected tool's per-tool install block (fixed order, not toggle order), reported as `Updated: … (AGENTS.md last-writer-wins …)`. The handler is **gated**: it fires only when `AGENTS_COLLISION=1` and the destination basename is `AGENTS.md` (see `setup.sh` the `AGENTS_COLLISION` block + the `_survivor` / `last-writer-wins` lines), so a single-AGENTS.md-writer install never triggers the auto-overwrite branch.

The install flow (incl. the new Copilot/Antigravity installs and the Option-A collision) is covered by `tests/canonical/test-setup.sh` (cases SU12-17/SU16b); `test-setup-ps1.sh` exercises `setup.ps1`'s platform-independent pre-install logic + menu/collision parity (cases SPS05-08) and **SKIPs (exit 0) when `pwsh` is absent** per the established repo contract (its Windows-only backslash-path file copy is not run on Linux CI). The CI `canonical-tests` job asserts `pwsh` IS present, so the skip cannot silently fire there.

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
| Bash | POSIX-compatible | All `canonical/scripts/` + `tests/canonical/` + `setup.sh` | `#!/usr/bin/env bash` at top of every script |
| PowerShell | 5.1+ | `setup.ps1` + `assemble-3part.ps1` | `setup.ps1` `#Requires -Version 5.1` |
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
