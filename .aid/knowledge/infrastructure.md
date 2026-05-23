# Infrastructure

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21
> **Cross-references:** `project-index.md`, `project-structure.md:222-232` (Build/Test/CI absence), `test-landscape.md` (overlapping CI gap), `security-model.md` (supply-chain trust chain), `tech-debt.md` (H2: no CI, H4: duplication)

## Framing

**There is no deployed infrastructure.** This repository ships no servers, no containers, no cloud resources, no orchestration manifests. The "infrastructure" here is:

1. **Source distribution** — how the repo gets to a user (git clone from GitHub).
2. **Installer mechanism** — how a user populates their project with AID skills (`setup.sh` / `setup.ps1`).
3. **User-side runtime requirements** — what tools must be installed on the user's machine for the skills to function.
4. **The dogfooded `.aid/` workspace** — how this repo uses its own methodology against itself.

Each of these is examined below.

## 1. Source Distribution

| Aspect | Value | Evidence |
|--------|-------|----------|
| VCS | Git | `.gitignore` exists; git worktree is the current execution context |
| Host | GitHub | `README.md:267` and `profiles/codex/AGENTS.md:24` reference `https://github.com/AndreVianna/aid-methodology` |
| Branching | Inferred GitHub-flow (PRs to `master`) | Current branch per git status: `master`. Recent merge commits (`af5b942`, `fda9063`) follow PR-merge style. ⚠️ Inferred from code — needs confirmation. The fact that `master` (not `main`) is the default branch is documented in the agent context |
| Release artifacts | None visible | No `releases/` directory; no GitHub Release artifacts mentioned in repo. `setup.sh` and `setup.ps1` are the entry points |
| Version file | None | No `VERSION`, no `package.json` version field, no `aid-version.txt`. The "V3" designation lives only in `methodology/aid-methodology.md` prose |
| Git tags | Not visible from this worktree | The worktree shows `master` HEAD at `af5b942` with no tags annotated in `git log` output |
| LICENSE | MIT | `LICENSE` (21 lines), confirmed by `project-index.md:345` |

**Implication:** Distribution is `git clone` only. Users do not download a tagged tarball; they pull the tip of `master`. This is the most common pattern for methodology / template repos but it has consequences for adopters who want reproducibility — see `tech-debt.md` H2.

## 2. Installer Scripts

### `setup.sh` (Bash, 161 lines)

**Read in full from `setup.sh:1-162`.** Key behavior:

- **Usage:** `setup.sh <target-directory> [--force]`. Target directory must already exist.
- **Interactive menu:** Numbered toggle (`[1] Claude Code`, `[2] Codex`, `[3] Cursor`, `[4] Done`). User selects any subset. Toggling is supported (selecting the same number twice deselects).
- **Copy semantics** (`setup.sh:87-128`):
  - New file: copy.
  - Identical file (verified via `cmp -s`): skip with "Up to date" message.
  - Different file: prompt `y/N` to overwrite, unless `--force` is set.
  - Directory tree: copy via `find -mindepth 1 -type d` to recreate structure, then `find -type f` to copy each file through `copy_file()`.
- **Per-tool copy rules** (`setup.sh:135-153`):
  - Claude Code: `cp -r profiles/claude-code/.claude/ $TARGET/.claude/` + `cp profiles/claude-code/CLAUDE.md $TARGET/CLAUDE.md`.
  - Codex: `cp -r profiles/codex/.codex/ $TARGET/.codex/` + `cp profiles/codex/AGENTS.md $TARGET/AGENTS.md`. Note: does NOT copy `profiles/codex/.agents/` (skills + templates), which is a documented omission to verify — the Codex tree's skills live under `.agents/` not `.codex/` per `profiles/codex/README.md:12-15`, and `setup.sh:144` only copies `.codex/`.
- **Post-install message:** Prints "Next steps: 1. Run /aid-init ... 2a. Brownfield: /aid-discover ... 2b. Greenfield: /aid-interview".

[CONFIRMED HIGH BUG — Q70] `setup.sh:142-145` (the Codex branch) copies `.codex/` and `AGENTS.md` but **not `.agents/`**. Per `profiles/codex/README.md:12-15`, manual install uses `cp -r path/to/aid-methodology/profiles/codex/.codex .codex/` AND `cp -r path/to/aid-methodology/profiles/codex/.agents .agents/`. The `setup.sh` script omits the second copy. This means a user who runs `setup.sh` for Codex gets the agent TOML definitions but NOT the skills or templates. **Confirmed via reviewer static-analysis spot-check #20** (`sed -n '140,155p' setup.sh` shows only `.codex` and `AGENTS.md` referenced). Patch tracked as `tech-debt.md H6`.

### `setup.ps1` (PowerShell, 156 lines)

**Read in full from `setup.ps1:1-157`.** Key behavior:

- **Parameters:** `$TargetDirectory` (positional, mandatory), `-Force` switch.
- **Requires PowerShell 5.1+** (`#Requires -Version 5.1`).
- **Same menu** as Bash version. Identical output strings.
- **Copy semantics** (`setup.ps1:67-99`): uses `Get-FileHash` (MD5) to compare files for parity (Bash version uses `cmp -s`). Otherwise functionally identical.
- **Per-tool copy rules** (`setup.ps1:130-148`): same as Bash. **Same omission**: the Codex branch (`setup.ps1:137-141`) copies `.codex\` and `AGENTS.md` but not `.agents\`.

[CONFIRMED HIGH BUG — Q70] Same Codex `.agents/` omission as `setup.sh`. Both installer scripts agree, so this is consistent — but consistently *missing* the Codex skills + templates copy step that the documentation says is required. Patch tracked as `tech-debt.md H6`.

## 3. User-Side Runtime Requirements

The AID skills, once installed, depend on the user's machine having the following:

### 3.1 Host AI Tool (one or more)

| Tool | Why | Where required |
|------|-----|----------------|
| Claude Code CLI | To run `.claude/skills/aid-*` and dispatch `.claude/agents/*` | Anywhere the Claude Code install tree is used |
| OpenAI Codex CLI | To run `.agents/skills/aid-*` and dispatch `.codex/agents/*` | Anywhere the Codex install tree is used |
| Cursor IDE | To honor `.cursor/rules/*.mdc`, `.cursor/agents/*`, `.cursor/skills/*` | Anywhere the Cursor install tree is used |

GitHub Copilot and Google Antigravity are mentioned in `README.md:267`, `CONTRIBUTING.md:58`, and `docs/faq.md` as future-supported but have no install tree (`external-sources.md:101-120`).

### 3.2 Shell Requirements

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| Bash 4+ | `setup.sh` uses associative arrays (`declare -A`, line 27); `build-project-index.sh` uses `set -euo pipefail`, process substitution `< <(...)`, and bash arrays | `setup.sh`, `build-project-index.sh`, `grade.sh`, `verify-kb.sh`, `check-preflight.sh`, all `aid-summarize` `validate-*.sh` and `*-check.sh` scripts | `setup.sh:1` `#!/usr/bin/env bash`; bash-4 features used throughout |
| GNU coreutils | `find -print0`, `cp -r`, `cmp -s`, `chmod +x` (Windows git-bash typically includes these) | Same as Bash | `setup.sh:122,127` `find ... -print0` |
| `curl` or `wget` | Network reachability check in `check-preflight.sh` for `aid-summarize` | `aid-summarize` PREFLIGHT state | `templates/knowledge-summary/scripts/check-preflight.sh:71-84` |
| `awk`, `sed`, `grep` (BSD or GNU) | Validation scripts; KB writeback | `aid-summarize`, `stale-check.sh` | `templates/knowledge-summary/scripts/stale-check.sh:31-41` (uses awk for table parsing) |

**Windows users** typically have git-bash from Git for Windows, which provides all the above. `setup.sh` will work in git-bash; native Windows users may prefer `setup.ps1`.

### 3.3 PowerShell

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| PowerShell 5.1+ | `setup.ps1` and `concatenate.ps1` | Windows native install | `setup.ps1:1` `#Requires -Version 5.1` |

### 3.4 Node.js

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| Node.js 18+ | `validate-diagrams.mjs` (294 lines), `contrast-check.mjs` (151 lines), `mermaid-init.js`, `lightbox.js` (in user's generated HTML) | `aid-summarize` VALIDATE state | `templates/knowledge-summary/scripts/check-preflight.sh:87-96` checks `node -v` and rejects less than 18 |

### 3.5 Mermaid CLI (optional)

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| `mmdc` (mermaid-cli) | Full Mermaid diagram validation (parse + render). Falls back to regex sanity check if absent | `aid-summarize` VALIDATE state, optional | `templates/knowledge-summary/scripts/validate-diagrams.mjs:7-12` |

### 3.6 Network

| Resource | Why | Required for | Evidence |
|----------|-----|--------------|----------|
| `registry.npmjs.org` | Fetch Mermaid library for inlining | `aid-summarize` GENERATE state (skippable with `--cdn-mermaid`) | `templates/knowledge-summary/scripts/check-preflight.sh:69-85` |
| Vendor doc URLs (8) | `external-sources.md` registers vendor docs to fetch during downstream discovery | Optional — current discovery deferred web fetch | `external-sources.md:15-24` |

## 4. Containers / IaC

**None.** Searched:

| Artifact | Found | Source |
|----------|-------|--------|
| `Dockerfile` | None | `project-index.md` Notable Files; `Glob **/Dockerfile` returns nothing |
| `docker-compose.yml` / `compose.yaml` | None | Same |
| Terraform (`*.tf`, `*.tfvars`) | None | `project-index.md` language breakdown shows no HCL |
| Pulumi (`Pulumi.yaml`, `*.cs/ts/py` with `@pulumi/*`) | None | No JS/TS project metadata anywhere |
| Helm (`Chart.yaml`, `values.yaml`) | None | — |
| Kubernetes manifests | None | — |
| Ansible (`playbook.yml`) | None | — |
| CDK (`cdk.json`) | None | — |

[INFO] **No containerization, no IaC.** Consistent with the methodology-only nature of this repo. Methodology *describes* infrastructure best practices and ships a `devops` agent for users (`profiles/claude-code/.claude/agents/devops.md:11-15`: "Configure CI/CD pipelines ... Write Dockerfiles ... Create and manage infrastructure-as-code") but does not itself contain any of those artifacts.

## 5. CI / CD

**None.** See `test-landscape.md` "CI/CD Integration" section and `tech-debt.md` H2 for full analysis.

| Pipeline | Present | Evidence |
|----------|---------|----------|
| GitHub Actions (`.github/workflows/*.yml`) | None | No `.github/` directory exists at all |
| GitLab CI (`.gitlab-ci.yml`) | None | — |
| Jenkins (`Jenkinsfile`) | None | — |
| Azure Pipelines (`azure-pipelines.yml`) | None | — |
| CircleCI (`.circleci/config.yml`) | None | — |
| Travis (`.travis.yml`) | None | — |

[HIGH GAP] No automated check exists for installer correctness, frontmatter validity, shell-syntax correctness, triplication drift, link rot, or example anonymization. The maintainer is the only quality gate. See `tech-debt.md` H2.

## 6. Monitoring / Observability

**Not applicable.** No deployed system means nothing to monitor.

The methodology defines a `Monitor` phase (`aid-monitor` skill, 242 lines across all three trees — identical), but this is a phase the *user* runs against *their* production system, not anything this repo runs.

[INFO] **The `aid-monitor` skill is uniform** across the three install trees (242 lines, identical content). Verified by line count.

## 7. Branching and Release Strategy

| Aspect | Value | Confidence |
|--------|-------|------------|
| Default branch | `master` | High — `git status` shows "Current branch: master" and "Main branch (you will usually use this for PRs): master" |
| Worktree branch | `master` (this dogfood discovery is on `master`) | High |
| PR-based merges | Likely (GitHub-flow) | Medium — recent commit log shows merge commits like `af5b942 Merge pull request #4` and `fda9063 Merge pull request #3` |
| Release tags | None visible from this worktree | Medium — `git log` shows no annotated-tag markers; the lack of a `VERSION` file is consistent |
| Release artifacts | None | High — no `dist/` or `releases/` directory; `setup.sh` operates on the source tree directly |

⚠️ Inferred from code — needs confirmation. The worktree may not have all remote tags fetched. A maintainer can confirm by running `git tag --list` against a fresh clone.

## 8. Environments

**Not applicable.** There is no dev / staging / prod for this repo.

The closest concept is "which install tree a user activates" (Claude Code, Codex, Cursor) — but this is a per-user decision at install time, not an environment in the conventional sense.

## 9. The Dogfooded `.aid/` Workspace

`project-structure.md:35-36` documents the dogfood pattern. This repo's own `.aid/` directory:

- Was scaffolded by `aid-init` (creating `.aid/knowledge/` with 16 KB templates + `DISCOVERY-STATE.md`).
- Is being populated by `aid-discover` (running discovery sub-agents against this repo's source tree to produce the KB).
- Is **gitignored** via `.gitignore:1` (single line: `.aid/`).

**⚠️ Note (per DISCOVERY-STATE Q125):** the byte-count listing previously shown here was a snapshot from BEFORE the KB was populated. It is now stale by multiple orders of magnitude (e.g., `tech-debt.md` was 155 bytes; current state is 423 lines / ~25 KB). For current state, see `project-index.md` (regenerated every `/aid-discover` run) or the completeness table in `.aid/knowledge/README.md`. The dogfood workspace is gitignored, so the only durable snapshot is via `git stash` or by manually committing against `.gitignore`.

**Implication for contributors:** running `/aid-discover` in a worktree of this repo will regenerate the KB. The KB is not committed (gitignored) — it is regenerated on demand. A future contributor who wants to share their discovery output for a feature branch must either:

1. Commit `.aid/` against `.gitignore` (manual override), or
2. Share the regeneration commands and rely on each reviewer running discovery themselves.

[INFO] **Dogfood discovery is non-deterministic in output but deterministic in process.** Different LLM runs of the discovery sub-agents may produce different prose, but the file *set* is fixed and the grading is deterministic.

## 10. Distribution Mechanism Summary

```
GitHub (origin)
  |
  | git clone
  v
User's workstation
  |
  | bash setup.sh /path/to/their/project [--force]
  | OR powershell setup.ps1 -TargetDirectory C:\Path\To\Project -Force
  v
User's project
  +-- .claude/                (if Claude Code selected)
  |    +-- agents/
  |    +-- skills/
  |    +-- templates/
  +-- .codex/                 (if Codex selected) [WARNING: setup.sh omits .agents/]
  +-- .cursor/                (if Cursor selected)
  +-- CLAUDE.md               (if Claude Code selected)
  +-- AGENTS.md               (if Codex or Cursor selected)
  +-- (user's existing code, untouched)

User then runs the host tool against their project.
The first command is /aid-init (per setup.sh post-install message).
```

## Gaps

| # | Gap | Severity | See |
|---|-----|----------|-----|
| 1 | No CI / automated quality gates | HIGH | `tech-debt.md` H2, `test-landscape.md` HIGH gap 1 |
| 2 | No version file / no release tags / no manifest | HIGH | `tech-debt.md` H2 |
| 3 | `setup.sh` and `setup.ps1` CONFIRMED to omit Codex `.agents/` copy step | HIGH — CONFIRMED via reviewer static-analysis (`sed -n '140,155p' setup.sh`) and tracked in `tech-debt.md H6`. Patch trivial (~10 min). | Section 2 above, DISCOVERY-STATE Q70 (Answered) |
| 4 | No installer smoke test | MEDIUM | `test-landscape.md` HIGH gap 3 |
| 5 | No containerization (intentional, not a gap per se for a methodology repo) | INFO | Section 4 above |
| 6 | Web fetch of vendor docs deferred | INFO | `external-sources.md` |
| 7 | No automatic update mechanism (users must `git pull` and re-run `setup.sh`) | LOW | Section 1 above |

WARNING: Several findings here (especially the Codex `.agents/` omission in `setup.sh` / `setup.ps1`) are based on static reading of the scripts against the documentation. They should be validated with a real `setup.sh tmp-test/` run before being escalated. These are forwarded as questions to `DISCOVERY-STATE.md`.
