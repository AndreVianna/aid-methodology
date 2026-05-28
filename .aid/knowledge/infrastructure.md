---
kb-category: primary
source: hand-authored
intent: |
  Describes the hosting, runtime, build pipeline, and dev tooling for the AID-methodology
  repo. There is no conventional runtime infrastructure (no Docker, no cloud, no Terraform).
  "Infrastructure" here means: install scripts (setup.sh / setup.ps1) that put AID into a
  target project, the canonical→3-profiles render pipeline driven by run_generator.py, and
  the local-filesystem conventions for runtime state. Read this to understand how AID is
  built, installed, and operated on a local workstation.
contracts: []
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Infrastructure

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27
> **Scope:** This repo ships a methodology + a multi-tool distribution. There is **no runtime infrastructure** in the conventional sense — no Docker, no Terraform, no Kubernetes, no cloud account, no managed services. "Infrastructure" here means: the install scripts that put AID into a target project, the canonical → 3-profiles render pipeline, the supporting toolchain (git, gh, python, bash), and the local-filesystem conventions for runtime state.

---

## Hosting & Runtime Environment

**Local-only.** AID runs on the maintainer's or end user's workstation, inside whichever AI host tool they have installed (Claude Code / Codex CLI / Cursor IDE). There is no server, no daemon, no port, no cloud presence owned by this project.

| Environment | Where it runs | Operated by |
|-------------|---------------|-------------|
| Maintainer build | Local workstation (Windows, macOS, Linux) | The maintainer |
| End-user runtime | Local workstation, inside Claude Code / Codex / Cursor host | The end user |
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

**No CI exists.** See `tech-debt.md H2` and `test-landscape.md § CI/CD Integration` for the full statement.

There is also no **release pipeline** — the project distributes via:
1. End users cloning the repo and running `setup.sh` / `setup.ps1` against a target directory, OR
2. End users invoking `gh` CLI commands manually (see `gh` Tool below).

There is no published package on npm, PyPI, Homebrew, Chocolatey, or any other package registry.

---

## Build Pipeline (the "infrastructure" of this repo)

The canonical → 3-profiles render is the **only build artifact pipeline** in the codebase. It is fully local, fully deterministic, and has no external dependencies beyond Python 3.11+.

| Component | Path | Lines | Purpose |
|-----------|------|-------|---------|
| Top-level entrypoint | `run_generator.py` | 87 | Loops `profiles/*.toml`, calls each renderer, runs VERIFY-4a/4b |
| Profile parser | `.claude/skills/aid-generate/scripts/profile.py` | 550 | Parses TOML, validates schema |
| Manifest harness | `.claude/skills/aid-generate/scripts/harness.py` | 756 | Emission-manifest implementation; pure-mirror deletion logic |
| Agent renderer | `.claude/skills/aid-generate/scripts/render_agents.py` | 522 | Renders `canonical/agents/` per profile |
| Skill renderer | `.claude/skills/aid-generate/scripts/render_skills.py` | 469 | Renders `canonical/skills/` per profile (Thin-Router + references/) |
| Recipe renderer | `.claude/skills/aid-generate/scripts/render_recipes.py` | 261 | Renders `canonical/recipes/` (passthrough) |
| Script renderer | `.claude/skills/aid-generate/scripts/render_scripts.py` | 224 | Renders `canonical/scripts/` per profile |
| Template renderer | `.claude/skills/aid-generate/scripts/render_templates.py` | 252 | Renders `canonical/templates/` per profile |
| Strict verifier | `.claude/skills/aid-generate/scripts/verify_deterministic.py` | 515 | VERIFY-4a — re-run byte-identical guarantee |
| Advisory verifier | `.claude/skills/aid-generate/scripts/verify_advisory.py` | 343 | VERIFY-4b — advisory checks |
| Generator self-tests | `.claude/skills/aid-generate/scripts/test_manifest_safety.py` | 254 | Internal correctness tests |

Pipeline flow (per `run_generator.py:24-87`):

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
   VERIFY-4a (strict — must pass, exits 1 on failure: run_generator.py:78-80)
                 ▼
   VERIFY-4b (advisory — reports counts only: run_generator.py:82-84)
```

**Note (Q2 resolution, cycle-1):** `run_generator.py` previously wrote VERIFY-4a/4b reports to `.aid/work-002-canonical-generator/`. That write was eliminated by passing `report_path=None`; the directory is no longer created or required.

---

## Install Pipeline (end-user installer)

The **`setup.sh` / `setup.ps1` pair** is the end-user-facing install entrypoint. It is the "infrastructure" that delivers AID into a new project.

| Script | Path | Lines | Platform |
|--------|------|-------|----------|
| Bash installer | `setup.sh` | 162 | macOS, Linux, WSL |
| PowerShell installer | `setup.ps1` | 157 | Windows |

Both scripts accept a target directory and an interactive menu (1 = Claude Code, 2 = Codex, 3 = Cursor; multi-select). They copy the matching `profiles/<tool>/` tree into the target. See `setup.sh:7-37` and `setup.ps1:1-40` for the argument-parsing and menu-state code.

There is **no test for the install flow** — see `tech-debt.md` L2.

---

## Source Control

**Git + GitHub.**

| Aspect | Value | Evidence |
|--------|-------|----------|
| VCS | Git | `.git/` directory present |
| Hosting | GitHub | per user memory `reference_repo-push-access.md` (account `AndreVianna`) |
| Repo URL | `github.com/AndreVianna/aid-methodology` | per user memory |
| Default branch | `master` | git remote info |
| Current working branch | `kb-overhaul` | git status at session start |
| Branch convention | Per-`work-NNN` persistent branch off master; no per-task / per-feature branches | `coding-standards.md §7f`; user memory `feedback_single-branch-work.md` |

Recent merge history (`git log --oneline -20`):
- PR #17 "remove work" — merged 2026-05-27
- PR #16 "aid-config: collapse 6-state machine to 2-mode skill" — merged 2026-05-27
- PR #15 "kb-overhaul Phase A+B" — merged 2026-05-27
- PR #14 "kb cycle-17 refresh" — merged 2026-05-26
- PR #13 "RECOVERY: restore lost work-001 implementation" — merged 2026-05-25

Branch protection on `master` (per `gh api repos/AndreVianna/aid-methodology/branches/master/protection` 2026-05-28):
- **Required pull request reviews:** 1 approving review required; stale reviews dismissed on new push; code-owner reviews NOT required; last-push approval NOT required
- **Required signatures:** disabled
- **Enforce admins:** disabled (admins can bypass)
- **Required linear history:** disabled (merge commits allowed)
- **Force pushes:** blocked
- **Branch deletion:** blocked
- **Conversation resolution required before merge:** disabled
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
| Python | 3.11+ (stdlib `tomllib`) | Generator pipeline | `.claude/skills/aid-generate/scripts/harness.py:15` |
| Bash | POSIX-compatible | All `canonical/scripts/` + `tests/canonical/` + `setup.sh` | `#!/usr/bin/env bash` at top of every script |
| PowerShell | 5.1+ | `setup.ps1` + `concatenate.ps1` | `setup.ps1:1` (`#Requires -Version 5.1`) |
| Node | 18+ | `aid-summarize` validators (`*.mjs`) + Mermaid CLI | `README.md:326` (per scout) |
| Git | any modern | VCS | implicit |
| GitHub CLI (`gh`) | any modern | PR/issue/release operations | user memory; called by AID docs |
| curl | any modern | `fetch-mermaid.sh` outbound HTTPS | `canonical/scripts/summarize/fetch-mermaid.sh:16, 43` |
| sha256sum or shasum | any | `fetch-mermaid.sh` cache fingerprint | `canonical/scripts/summarize/fetch-mermaid.sh:59-65` |
| yq (optional) | any | `read-setting.sh` defers to it for complex YAML | `canonical/scripts/config/read-setting.sh:42` |

---

## Runtime State / Local Filesystem Conventions

These directories function as "infrastructure" at runtime — they hold ephemeral or per-project state:

| Path | Purpose | Gitignored? |
|------|---------|-------------|
| `.aid/knowledge/` | Knowledge Base output (this scout's target) | **No** — KB is committed |
| `.aid/.heartbeat/` | Per-subagent heartbeat files (visibility patch L3) | Yes — `.gitignore:46-47` (explicit) |
| `.aid/.temp/` | Scratch | Yes — `.gitignore:21` (via `*.temp` glob — fragile per `tech-debt.md` M3) |
| `.aid/generated/` | Build outputs the maintainer wants to track (`project-index.md`) | **No** — selectively committed |
| `.aid/templates/` | Runtime template copies | **No** — committed |
| `.aid/settings.yml` | AID pipeline configuration (single source of truth) | **No** — committed |
| `.aid/knowledge/.cache/` | Mermaid JS cache (per `fetch-mermaid.sh`) | Yes — `.gitignore:40` |
| `.claude/worktrees/` | Claude Code worktree state (legacy; worktrees are RETIRED per `coding-standards.md §7f`) | Yes — `.gitignore:43` |
| `.claude/settings.local.json` | Per-developer Claude Code overrides | Yes — `.gitignore:44` |

---

## Network Egress

The **single outbound HTTP call** in the entire codebase is `canonical/scripts/summarize/fetch-mermaid.sh`:

- `https://registry.npmjs.org/mermaid/latest` (line 16) — version lookup
- `https://cdn.jsdelivr.net/npm/mermaid@<ver>/dist/mermaid.min.js` (line 41) — JS download

No other script makes outbound HTTPS. No telemetry, no analytics, no auto-update check.

⚠️ **Security risk:** these calls are unpinned — see `tech-debt.md` C1 for the supply-chain debt item.

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
- **L3 traceability** — heartbeat files in `.aid/.heartbeat/` updated by every long-running subagent at a configurable interval (default 1 minute per `.aid/settings.yml:50`).

Calibration is logged unconditionally — per `coding-standards.md §5c` and user memory `feedback_traceability-unconditional.md`. This is observability of the *agentic pipeline itself*, not of any deployed system.
