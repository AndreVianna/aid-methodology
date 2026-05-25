# Infrastructure

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-23 (cycle 11 FIX: canonical/ + run_generator.py noted in §§1-2; skill-loading cache subsection added to §3.1)
> **Cross-references:** `project-index.md`, `project-structure.md:222-232` (Build/Test/CI absence), `test-landscape.md` (overlapping CI gap), `security-model.md` (supply-chain trust chain), `tech-debt.md` (H2: no CI, H5: orphan-detection gap)

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
| Branching | Inferred GitHub-flow (PRs to `master`) | Current branch per git status: `master`. ⚠️ Inferred from code — needs confirmation. The fact that `master` (not `main`) is the default branch is documented in the agent context |
| Release artifacts | None visible | No `releases/` directory; no GitHub Release artifacts mentioned in repo. `setup.sh` and `setup.ps1` are the entry points |
| Version file | None | No `VERSION`, no `package.json` version field, no `aid-version.txt`. The "V3" designation lives only in `methodology/aid-methodology.md` prose |
| Git tags | Not visible from this worktree | The worktree shows `master` HEAD with no tags annotated in `git log` output |
| LICENSE | MIT | `LICENSE` (21 lines), confirmed by `project-index.md:345` |
| **Single source of truth** | `canonical/` top-level directory (new post work-002 — 2026-05-22) | `ls canonical/` shows `agents/`, `skills/`, `templates/`, `rules/`, `EMISSION-MANIFEST.md`. Authoritative source for all 22 agent definitions, 10 skill bodies, and template assets. The three install trees under `profiles/{claude-code,codex,cursor}/` are **generator output**, not hand-maintained |
| **Propagation mechanism** | `run_generator.py` (top-level, ~83 lines Python, new post work-002) | Reads profile TOMLs from `profiles/*.toml`, invokes per-profile renderers (`render_agents`, `render_skills`, `render_templates` under `.claude/skills/aid-generate/scripts/`), emits files into each install tree, writes an `emission-manifest.jsonl` per profile, prunes empty directories on delete, and runs VERIFY-4a (deterministic) + VERIFY-4b (advisory) gates. Exit 1 on VERIFY-4a failure |
| **Pre-canonical era artifacts** | Top-level `skills/` and `agents/` directories — DELETED 2026-05-22 | Verified: `ls skills/` and `ls agents/` both error "No such file or directory". Their content was promoted into `canonical/{skills,agents}/` and the human READMEs were retired in favor of the canonical sources being the single readable form |

**Implication:** Distribution is `git clone` only. Users do not download a tagged tarball; they pull the tip of `master`. This is the most common pattern for methodology / template repos but it has consequences for adopters who want reproducibility — see `tech-debt.md` H2.

**Canonical authority (post work-002):** Contributors edit `canonical/{skills,agents,templates}/`, then run `python run_generator.py` to regenerate the three profile trees deterministically. The pre-work-002 CONTRIBUTING.md "update all 3 trees by hand" rule is obsolete. See `tech-debt.md H5` for the residual orphan-detection gap (`run_generator.py` VERIFY-4a checks canonical → profile propagation but does not flag templates that exist in profile trees and not in `canonical/templates/`; 6 such orphans existed pre-cycle-11, resolved by KB-F1).

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
  - Codex: `cp -r profiles/codex/.codex/ $TARGET/.codex/` + `cp -r profiles/codex/.agents/ $TARGET/.agents/` + `cp profiles/codex/AGENTS.md $TARGET/AGENTS.md`. (Pre-2026-05-22 the `.agents/` line was missing — Q70/H6 — now fixed.)
  - Cursor: `cp -r profiles/cursor/.cursor/ $TARGET/.cursor/` + `cp profiles/cursor/AGENTS.md $TARGET/AGENTS.md`.
- **Source = generator output, not canonical/:** `setup.sh` installs from `profiles/{claude-code,codex,cursor}/`, which are themselves the output of `python run_generator.py` applied to `canonical/`. The installer does **not** read `canonical/` directly — adopters get the staged per-tool layout already shaped by the generator (paths like `.claude/skills/`, `.codex/agents/`, `.cursor/rules/`).
- **Post-install message:** Prints "Next steps: 1. Run /aid-init ... 2a. Brownfield: /aid-discover ... 2b. Greenfield: /aid-interview".

### `setup.ps1` (PowerShell, 156 lines)

**Read in full from `setup.ps1:1-157`.** Key behavior:

- **Parameters:** `$TargetDirectory` (positional, mandatory), `-Force` switch.
- **Requires PowerShell 5.1+** (`#Requires -Version 5.1`).
- **Same menu** as Bash version. Identical output strings.
- **Copy semantics** (`setup.ps1:67-99`): uses `Get-FileHash` (MD5) to compare files for parity (Bash version uses `cmp -s`). Otherwise functionally identical.
- **Per-tool copy rules** (`setup.ps1:130-148`): same as Bash; both installers carry the `.agents/` copy step in the Codex branch post-2026-05-22 H6 fix. Same `profiles/`-as-source contract (canonical/ is invisible to the adopter).

[INFO — RESOLVED Q70/H6] Both installers correctly copy `.agents/` in the Codex branch as of 2026-05-22 (task-030 smoke test passed: 10 Codex SKILL.md files placed under `<target>/.agents/skills/aid-*/SKILL.md`). The pre-fix variant was [CONFIRMED HIGH BUG] until then.

## 3. User-Side Runtime Requirements

The AID skills, once installed, depend on the user's machine having the following:

### 3.1 Host AI Tool (one or more)

| Tool | Why | Where required |
|------|-----|----------------|
| Claude Code CLI | To run `.claude/skills/aid-*` and dispatch `.claude/agents/*` | Anywhere the Claude Code install tree is used |
| OpenAI Codex CLI | To run `.agents/skills/aid-*` and dispatch `.codex/agents/*` | Anywhere the Codex install tree is used |
| Cursor IDE | To honor `.cursor/rules/*.mdc`, `.cursor/agents/*`, `.cursor/skills/*` | Anywhere the Cursor install tree is used |

GitHub Copilot and Google Antigravity are mentioned in `README.md:267`, `CONTRIBUTING.md:58`, and `docs/faq.md` as future-supported but have no install tree (`external-sources.md:101-120`).

#### 3.1.1 Host harness skill-loading behavior (per Q192)

**Observation (verified for Claude Code 2026-05-22):** the host harness loads `SKILL.md` text **once at session start** and serves the cached body for the remainder of the session. If a maintainer edits a skill body mid-session (e.g., during dogfood work), the running session continues to dispatch the **pre-edit** SKILL.md until the host is restarted or a fresh session is opened.

**Symptoms of stale skill cache:**
- Heartbeat (FR1) `[State: ...]` markers expected after an edit are absent from agent output.
- Area-STATE file references (FR2) match a pre-FR2 filename even though disk has been updated.
- New step numbers / new bracket-pair labels in the on-disk SKILL.md are not reflected in the agent's behavior.

**Recommendation:** After any mid-session edit to a `canonical/skills/aid-*/SKILL.md`, restart the host (or open a new conversation/CLI session) before re-invoking the skill. Re-running `python run_generator.py` propagates the edit to the install trees but does **not** by itself flush the host's skill cache.

**Scope:**
- ✅ **Verified for Claude Code** (Q192 evidence trail: `/aid-deploy work-003` session showed PRE-FR2 cached SKILL.md body despite on-disk file being post-F1-F9).
- ⚠️ **Presumed for Codex and Cursor** — same per-session-cache pattern is the default for slash-command-style hosts; spot-check needed when convenient. File an upstream issue only if behavior diverges from Claude Code.

This is treated as **host-platform behavior**, not an AID bug. Documentation only.

### 3.2 Shell Requirements

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| Bash 4+ | `setup.sh` uses associative arrays (`declare -A`, line 27); `build-project-index.sh` uses `set -euo pipefail`, process substitution `< <(...)`, and bash arrays | `setup.sh`, `build-project-index.sh`, `grade.sh`, `verify-kb.sh`, `check-preflight.sh`, all `aid-summarize` `validate-*.sh` and `*-check.sh` scripts | `setup.sh:1` `#!/usr/bin/env bash`; bash-4 features used throughout |
| GNU coreutils | `find -print0`, `cp -r`, `cmp -s`, `chmod +x` (Windows git-bash typically includes these) | Same as Bash | `setup.sh:122,127` `find ... -print0` |
| `curl` or `wget` | Network reachability check in `check-preflight.sh` for `aid-summarize` | `aid-summarize` PREFLIGHT state | `canonical/templates/knowledge-summary/scripts/check-preflight.sh` |
| `awk`, `sed`, `grep` (BSD or GNU) | Validation scripts; KB writeback | `aid-summarize`, `stale-check.sh` | `canonical/templates/knowledge-summary/scripts/stale-check.sh:31-41` (uses awk for table parsing) |

**Windows users** typically have git-bash from Git for Windows, which provides all the above. `setup.sh` will work in git-bash; native Windows users may prefer `setup.ps1`.

### 3.3 PowerShell

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| PowerShell 5.1+ | `setup.ps1` and `concatenate.ps1` | Windows native install | `setup.ps1:1` `#Requires -Version 5.1` |

### 3.4 Python

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| Python 3.x | `run_generator.py` (top-level propagator) | Maintainer-side only: regenerating install trees from `canonical/` | `run_generator.py:1` `#!/usr/bin/env python3`. Adopters do **not** need Python — they consume the generator output via `setup.sh` / `setup.ps1` |

### 3.5 Node.js

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| Node.js 18+ | `validate-diagrams.mjs` (294 lines), `contrast-check.mjs` (151 lines), `mermaid-init.js`, `lightbox.js` (in user's generated HTML) | `aid-summarize` VALIDATE state | `canonical/templates/knowledge-summary/scripts/check-preflight.sh` checks `node -v` and rejects less than 18 |

### 3.6 Mermaid CLI (optional)

| Tool | Why | Required for | Evidence |
|------|-----|--------------|----------|
| `mmdc` (mermaid-cli) | Full Mermaid diagram validation (parse + render). Falls back to regex sanity check if absent | `aid-summarize` VALIDATE state, optional | `canonical/templates/knowledge-summary/scripts/validate-diagrams.mjs:7-12` |

### 3.7 Network

| Resource | Why | Required for | Evidence |
|----------|-----|--------------|----------|
| `registry.npmjs.org` | Fetch Mermaid library for inlining | `aid-summarize` GENERATE state (skippable with `--cdn-mermaid`) | `canonical/templates/knowledge-summary/scripts/check-preflight.sh` |
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

[INFO] **No containerization, no IaC.** Consistent with the methodology-only nature of this repo. Methodology *describes* infrastructure best practices and ships a `devops` agent for users (`canonical/agents/devops/` per work-002 promotion) but does not itself contain any of those artifacts.

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

[HIGH GAP] No automated check exists for installer correctness, frontmatter validity, shell-syntax correctness, canonical-vs-generator-output parity, link rot, or example anonymization. The maintainer is the only quality gate. See `tech-debt.md` H2.

## 6. Monitoring / Observability

**Not applicable.** No deployed system means nothing to monitor.

The methodology defines a `Monitor` phase (`aid-monitor` skill, 223 lines per `canonical/skills/aid-monitor/SKILL.md` post work-002, propagated identically to all 3 install trees), but this is a phase the *user* runs against *their* production system, not anything this repo runs.

[INFO] **The `aid-monitor` skill is uniform** across the three install trees (223 lines each, identical content). Verified by line count.

## 7. Branching and Release Strategy

| Aspect | Value | Confidence |
|--------|-------|------------|
| Default branch | `master` | High — `git status` shows "Current branch: master" and "Main branch (you will usually use this for PRs): master" |
| Worktree branch | Per-work-item branch (e.g., `work-003` for current work) | High |
| PR-based merges | Likely (GitHub-flow) | Medium — recent commit log shows merge commits like `Merge pull request #4` and `Merge pull request #3` |
| Release tags | None visible from this worktree | Medium — `git log` shows no annotated-tag markers; the lack of a `VERSION` file is consistent |
| Release artifacts | None | High — no `dist/` or `releases/` directory; `setup.sh` operates on the source tree directly |

⚠️ Inferred from code — needs confirmation. The worktree may not have all remote tags fetched. A maintainer can confirm by running `git tag --list` against a fresh clone.

## 8. Environments

**Not applicable.** There is no dev / staging / prod for this repo.

The closest concept is "which install tree a user activates" (Claude Code, Codex, Cursor) — but this is a per-user decision at install time, not an environment in the conventional sense.

## 9. The Dogfooded `.aid/` Workspace

`project-structure.md:35-36` documents the dogfood pattern. This repo's own `.aid/` directory:

- Was scaffolded by `aid-init` (creating `.aid/knowledge/` with 16 KB templates + the consolidated `STATE.md`).
- Is being populated by `aid-discover` (running discovery sub-agents against this repo's source tree to produce the KB).
- Is **gitignored** via `.gitignore` (47 lines) (single line: `.aid/`).

**Implication for contributors:** running `/aid-discover` in a worktree of this repo will regenerate the KB. The KB is not committed (gitignored) — it is regenerated on demand. A future contributor who wants to share their discovery output for a feature branch must either:

1. Commit `.aid/` against `.gitignore` (manual override), or
2. Share the regeneration commands and rely on each reviewer running discovery themselves.

[INFO] **Dogfood discovery is non-deterministic in output but deterministic in process.** Different LLM runs of the discovery sub-agents may produce different prose, but the file *set* is fixed and the grading is deterministic.

## 10. Distribution Mechanism Summary

```
Maintainer-side
   canonical/{skills,agents,templates,rules}/
                |
                | python run_generator.py
                v
   profiles/{claude-code,codex,cursor}/   <-- generator output (deterministic)
                |
                | git commit + push to GitHub (master)
                v
GitHub (origin)
   |
   | git clone
   v
User's workstation
   |
   | bash setup.sh /path/to/their/project [--force]
   | OR powershell setup.ps1 -TargetDirectory C:\Path\To\Project -Force
   |
   | (copies from profiles/<tool>/, NOT from canonical/)
   v
User's project
   +-- .claude/                (if Claude Code selected)
   |    +-- agents/
   |    +-- skills/
   |    +-- templates/
   +-- .codex/                 (if Codex selected) — agent TOMLs
   +-- .agents/                (if Codex selected) — skills + templates
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
| 3 | No canonical-vs-generator-output parity check in CI | HIGH | `test-landscape.md` HIGH gap 2 (post-cycle-11) |
| 4 | Generator orphan-detection gap (VERIFY-4a checks canonical→profile only, not profile-only orphans) | HIGH | `tech-debt.md` H5 (Q190 generalization) |
| 5 | No installer smoke test | MEDIUM | `test-landscape.md` MEDIUM gap 2 |
| 6 | No containerization (intentional, not a gap per se for a methodology repo) | INFO | Section 4 above |
| 7 | Web fetch of vendor docs deferred | INFO | `external-sources.md` |
| 8 | No automatic update mechanism (users must `git pull` and re-run `setup.sh`) | LOW | Section 1 above |
| 9 | Host harness caches SKILL.md per session — mid-session edits require restart | LOW (documented behavior) | §3.1.1 above (Q192) |

## Verification Spot-Checks (cycle-11 FIX)

| # | Claim | Evidence |
|---|-------|----------|
| 1 | `canonical/` top-level dir exists with `agents/`, `skills/`, `templates/`, `rules/`, `EMISSION-MANIFEST.md` | `ls canonical/` |
| 2 | `run_generator.py` exists at top level | `ls run_generator.py` (~83 lines Python) |
| 3 | `canonical/skills/aid-discover/SKILL.md` and all 3 profile copies are 258 lines each (uniform) | `wc -l canonical/skills/aid-discover/SKILL.md profiles/*/skills/aid-discover/SKILL.md` returns 258 four times |
| 4 | Top-level `skills/` and `agents/` dirs are GONE | `ls skills/`, `ls agents/` both error |
| 5 | `setup.sh` and `setup.ps1` install from `profiles/<tool>/`, not from `canonical/` | `grep -nE "canonical/" setup.sh setup.ps1` returns 0 matches |
| 6 | `aid-monitor` SKILL.md is 223 lines (not the obsolete 242 cited pre-cycle-11) | `wc -l canonical/skills/aid-monitor/SKILL.md` |

WARNING: The Q192 skill-loading-cache observation is verified for Claude Code only. The Codex/Cursor presumption is based on the per-session-cache pattern being the standard for slash-command-style hosts; explicit verification is pending. File an upstream issue only if behavior diverges from Claude Code.
