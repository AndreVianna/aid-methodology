---
kb-category: primary
source: hand-authored
intent: |
  Concrete inventory of languages, runtimes, libraries, build tools, and dev tooling used
  by the AID-methodology repository. Covers: Markdown (872 files), Bash (109 files), Python
  3.11+ (stdlib only, no third-party deps), JavaScript/ES modules (Node built-ins only),
  PowerShell 5.1+, CSS3, HTML5, TOML 1.0, YAML 1.2, JSON, and JSON Lines. The only runtime
  library is Mermaid (fetched dynamically from npm/jsdelivr). Read this to understand what
  toolchain is required to build, run, or contribute to AID.
contracts:
  - "Python 3.11+ required (tomllib stdlib dependency)"
  - "No third-party Python packages (stdlib only)"
  - "No npm package.json at any level"
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Technology Stack

> Concrete inventory of languages, runtimes, libraries, build tools, and dev tooling used
> by the AID-methodology repository. There is no shipped application — this repo is a
> code/document generator + a multi-tool install bundle. Versions come from the source
> files where they are declared; "unpinned" means the tool/library version is unstated
> and resolved at run time from the host environment.

## Languages

| Language | Version | Source file / evidence |
|----------|---------|------------------------|
| **Markdown** | CommonMark + GFM tables (assumed; no validator pinned) | 872 files / 97,689 lines (`.aid/generated/project-index.md:19`). All docs, skills, agents, templates, recipes. |
| **Bash (shell)** | bash 4+ (uses `declare -A` associative arrays, `[[ ]]`, `${var:-}`) | 109 files / 30,887 lines. Example: `setup.sh:27` declares `declare -A selected`. |
| **Python** | 3.11+ (required for `tomllib` stdlib) | 11 files / 4,232 lines. Pinned by `.claude/skills/aid-generate/scripts/harness.py:15` "Requirements: Python 3.11+ (tomllib is stdlib; no third-party deps)" and `profile.py:12`. |
| **JavaScript (ES modules + plain)** | ES2020+ (no explicit pin); `.mjs` for ESM scripts | 20 files / 5,685 lines. `canonical/scripts/summarize/validate-diagrams.mjs` (574 lines), `contrast-check.mjs` (151 lines); `canonical/templates/knowledge-summary/lightbox.js` (359 lines), `mermaid-init.js` (53 lines). |
| **PowerShell** | 5.1+ | 6 files / 337 lines. `setup.ps1`, `canonical/scripts/summarize/concatenate.ps1`. Version requirement from `README.md:325`. |
| **CSS** | CSS3 (custom properties, `:focus-visible`, `@media (forced-colors)`, `@media (prefers-reduced-motion)`) | 5 files / 3,285 lines. Single canonical source `canonical/templates/knowledge-summary/component-css.css` (657 lines) × 4 mirrors (canonical + .claude + 3 profile trees). |
| **HTML** | HTML5 (semantic landmarks: `<header role="banner">`, `<main>`, `<nav>`, `<footer>`) | 5 files / 505 lines. `canonical/templates/knowledge-summary/html-skeleton.html` (101 lines) + 4 mirrors. |
| **TOML** | TOML 1.0 (Python `tomllib` parser implies 1.0) | 25 files / 2,888 lines. 3 profile config files + 22 Codex agent definitions (`profiles/codex/.codex/agents/*.toml`). |
| **YAML** | YAML 1.2 (per `canonical/templates/settings.yml:8`) | 5 files / 405 lines. `canonical/templates/settings.yml` (81 lines) + 4 mirrors. Also used as Markdown frontmatter throughout. |
| **JSON** | RFC 8259 (Claude Code uses standard JSON) | 2 files / 28 lines. `.claude/settings.json` (15 lines), `.claude/settings.local.json` (13 lines). |
| **JSON Lines** | Per `canonical/EMISSION-MANIFEST.md:51-55` — LF-only, one record per line | Used by `profiles/{tool}/emission-manifest.jsonl`. |

Language source: `.aid/generated/project-index.md:17-29`.

## Frameworks & Libraries

This repository has **no application-language frameworks** (no React, no Spring, no
Django, etc.). The only runtime libraries are:

| Library | Version | Purpose | Source file / evidence |
|---------|---------|---------|------------------------|
| **Mermaid** | Pinned to v11.15.0 (constant `PINNED_VERSION`); downloaded once from jsdelivr CDN and cached; SHA-verified against `EXPECTED_SHA256` on both cache-hit and post-download paths | Diagram rendering inside `/aid-summarize`-generated HTML; inlined into the single-file output so the viewer works fully offline | `canonical/scripts/summarize/fetch-mermaid.sh:20-21, 52-64, 84-91` |
| **(Implicit) jsdelivr CDN** | n/a — download URL: `https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js` | Source of the pinned Mermaid bundle that gets cached + inlined | `canonical/scripts/summarize/fetch-mermaid.sh:67` |

Python uses **stdlib only** — `tomllib`, `hashlib`, `json`, `pathlib`, `re`, `dataclasses`,
`argparse`, `tempfile`, `filecmp`, `sys`. Confirmed by `harness.py:18-25` and the absence
of any `requirements.txt`, `pyproject.toml`, or `setup.py` at any level.

JavaScript uses **no npm dependencies** — `canonical/templates/knowledge-summary/lightbox.js`
is a self-contained IIFE; `canonical/scripts/summarize/validate-diagrams.mjs` and
`contrast-check.mjs` run with Node's built-in modules only. No `package.json` exists at any
level (verified absent in `.aid/generated/project-index.md`).

## Package Manager

| Tool | Version | Lock file |
|------|---------|-----------|
| **None for application code** | — | — |
| **Implicit: npm registry HTTP API** (used only by `/aid-summarize` to discover the latest Mermaid version) | n/a | No `package-lock.json`, no `package.json` anywhere. Mermaid version metadata is cached at `.aid/knowledge/.cache/mermaid.min.js.meta` (per `state-generate.md:21-22`). |

Per `project-structure.md:96-97`: "no `package.json`, no `pyproject.toml`, no `Cargo.toml`,
no `go.mod`, no `requirements.txt`, no `pom.xml`."

## Runtime

| Runtime | Version | How detected |
|---------|---------|--------------|
| **Python** | 3.11+ | `.claude/skills/aid-generate/SKILL.md:32-36` Pre-flight check (`python --version`); `harness.py:15`; `profile.py:12`. Required for `tomllib` stdlib. |
| **Bash** | 4+ (associative arrays) | `setup.sh:1` shebang `#!/usr/bin/env bash`, `set -euo pipefail`; `setup.sh:27` uses `declare -A`. Per `README.md:325`: "Bash (or git-bash on Windows) for scripts". |
| **PowerShell** | 5.1+ | `README.md:325` explicit pin: "PowerShell 5.1+ for setup.ps1". |
| **Node.js** | 18+ (optional — only for `/aid-summarize` diagram validators) | `README.md:326`: "Node 18+ is optional — only `/aid-summarize` uses it, for diagram validation." `.mjs` files imply ESM support (Node 14+ minimum). |
| **Git** | unpinned (any modern version) | `README.md:326`: "Git" listed as a runtime requirement; `.claude/skills/aid-generate/SKILL.md:48-50` Pre-flight runs `git rev-parse --git-dir`. |
| **One of: Claude Code / OpenAI Codex CLI / Cursor IDE** | unpinned (host-tool-specific) | `README.md:324`: "One or more host AI tools." End-user runtime; required to invoke the slash commands. |

## Build System

| Tool | Config file location | Purpose |
|------|----------------------|---------|
| **`run_generator.py`** | `run_generator.py` (87 lines, repo root) | The build. Iterates `profiles/*.toml`, calls each renderer per profile, performs the pure-mirror deletion pass, writes one emission manifest per profile, then runs VERIFY-4a (hard) and VERIFY-4b (advisory). |
| **Per-tool profile TOMLs** | `profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml` | Per-host conventions: `[layout]`, `[agent.frontmatter]`, `[skill.frontmatter]`, `[model_tiers]`, `[tool_names]`, `[filename_map]`, `[extras]`, `[capabilities]`. |
| **Emission manifest spec** | `canonical/EMISSION-MANIFEST.md` (152 lines) | Authoritative spec for the manifest format (JSONL, LF-only, sentinel first line `{"_manifest_version": 1}`, sorted by `dst`). |
| **End-user installer** | `setup.sh` (162 lines) / `setup.ps1` (157 lines) | Cross-platform install scripts that copy a built profile tree into a target project (not a build per se — runs after `run_generator.py`). |

### Build Commands

```bash
# Full build (renders canonical → all 3 install trees + runs VERIFY-4a/4b)
python run_generator.py

# Build one tree only (rare)
python .claude/skills/aid-generate/scripts/render_skills.py \
    --canonical-root . \
    --profile profiles/claude-code.toml \
    --output-root profiles/claude-code/.claude

# Build verification (byte-identical re-render audit; hard gate)
python .claude/skills/aid-generate/scripts/verify_deterministic.py
```

Source: `run_generator.py:1-87`.

### Lint Commands

This repository has **no language linters** (no ESLint, no flake8, no shellcheck config,
no `pyproject.toml`). Quality is enforced by:

```bash
# Rebuild file inventory used by Discovery
bash canonical/scripts/kb/build-project-index.sh --root . --output .aid/generated/project-index.md

# Canonical helper-script test suites (5 suites, 235 tests total)
bash tests/canonical/writeback-task-status.sh    # 69 tests
bash tests/canonical/delivery-gate-aggregate.sh  # 18 tests
bash tests/canonical/compute-block-radius.sh     # 17 tests
bash tests/canonical/parse-recipe.sh             # 113 tests (runtime ~150s — needs timeout ≥180s)
bash tests/canonical/read-setting.sh             # 18 tests
```

**KB claim verification** is performed by the `discovery-reviewer` sub-agent in
`/aid-discover REVIEW` state (see `canonical/agents/discovery-reviewer/AGENT.md`).
The former `canonical/scripts/kb/verify-claims.sh` was deleted in cycle-1 (see
`tech-debt.md H6`).

There is **no auto-fix linter**. Quality gates are the AID skills themselves: `aid-discover`
adversarial review, `aid-execute` two-tier review per task + per delivery, `aid-deploy`
verification step.

Source: `project-structure.md §Build Commands`; `tests/README.md`.

## Development Tools

| Tool | Version | Purpose | Config file |
|------|---------|---------|-------------|
| **Git** | unpinned | VCS — branch `kb-overhaul` per current working tree | `.git/`; `.gitignore` (47 lines, repo root) |
| **`build-project-index.sh`** | `canonical/scripts/kb/build-project-index.sh` (368 lines) | Pre-builds the file inventory consumed by the 5 discovery sub-agents | — |
| **`grade.sh`** | `canonical/scripts/grade.sh` (141 lines) | Deterministic severity-tag → letter-grade scorer used by the review state of every skill | — |
| **`parse-recipe.sh`** | `canonical/scripts/interview/parse-recipe.sh` (540 lines) | Parses recipe `{{slot}}` placeholders; emits lite-path artifacts | — |
| **`writeback-task-status.sh`** | `canonical/scripts/execute/writeback-task-status.sh` (627 lines) | Updates per-area `STATE.md` after a task completes | — |
| **`compute-block-radius.sh`** | `canonical/scripts/execute/compute-block-radius.sh` (293 lines) | BFS over the task dependency graph to compute failure block radius (pool dispatch) | — |
| **`read-setting.sh`** | `canonical/scripts/config/read-setting.sh` (263 lines) | Reads a dotted-path key from `.aid/settings.yml` with default fallback | — |
| **`fetch-mermaid.sh`** | `canonical/scripts/summarize/fetch-mermaid.sh` (77 lines) | Discovers + caches the latest Mermaid release for offline inlining | — |
| **`validate-diagrams.mjs`** | `canonical/scripts/summarize/validate-diagrams.mjs` (574 lines) | Mermaid syntax validation for the generated HTML | — |
| **`contrast-check.mjs`** | `canonical/scripts/summarize/contrast-check.mjs` (151 lines) | WCAG AA color-contrast audit on the design tokens; runs against both light + dark themes | — |
| **`validate-html-output.sh`** | `canonical/scripts/summarize/validate-html-output.sh` (321 lines) | HTML output validation for `/aid-summarize` | — |
| **`run-validators.sh`** | `canonical/scripts/summarize/run-validators.sh` (518 lines) | Aggregates the summarize-phase validators into a single Machine-Grade score | — |
| **`manual-checklist.sh`** | `canonical/scripts/summarize/manual-checklist.sh` (269 lines) | Drives the K1/K2/V1 interactive Human-Grade checklist for `/aid-summarize` | — |
| **`spot-check-facts.sh`** | `canonical/scripts/summarize/spot-check-facts.sh` (176 lines) | Spot-checks KB facts against source citations | — |
| **`stale-check.sh`** | `canonical/scripts/summarize/stale-check.sh` (107 lines) | Detects stale KB sections | — |
| **`concatenate.sh` / `concatenate.ps1`** | 23 / 36 lines respectively | Assembles the final single-file `knowledge-summary.html` by concatenating `part1.html` + cached Mermaid + `part2.html` (PowerShell version uses byte-level concat to avoid CRLF interpretation, see `concatenate.ps1:29-32`) | — |
| **`preflight.sh` (KB)** | `canonical/scripts/kb/preflight.sh` (46 lines) | Verifies `.aid/knowledge/STATE.md` exists + not in Plan Mode before any `/aid-discover` state | — |
| **`preflight.sh` (summarize)** | `canonical/scripts/summarize/preflight.sh` (101 lines) | Verifies KB is User-Approved before `/aid-summarize` runs | — |
| **`build-index.sh`** | `canonical/scripts/kb/build-index.sh` (203 lines) | Builds `.aid/knowledge/INDEX.md` from KB sources | — |
| **`build-metrics.sh`** | `canonical/scripts/kb/build-metrics.sh` (213 lines) | KB doc-size metrics | — |
| **`writeback-state.sh`** | `canonical/scripts/summarize/writeback-state.sh` (173 lines) | Writes summarize-phase state back to `.aid/knowledge/STATE.md` | — |
| **`complexity-score.sh`** | `canonical/scripts/execute/complexity-score.sh` (209 lines) | Task complexity scoring used by `/aid-execute` | — |

Each script above has **four byte-identical copies** on disk (canonical + dogfood `.claude/`
+ 3 profile trees) — the count discrepancy (109 shell files but ~21 unique scripts) is by
design per `project-structure.md:296`.

## Testing Infrastructure

| Tool | Version | Purpose | Config / location |
|------|---------|---------|---------|
| **Pure bash test suites** | bash 4+ | All tests are plain bash scripts (no pytest, no jest, no junit) | `tests/canonical/*.sh` (5 suites — see `tests/README.md`) |
| **Generator self-tests** | Python 3.11+ | Manifest-safety unit tests | `.claude/skills/aid-generate/scripts/test_manifest_safety.py` (254 lines) |
| **CI** | **None** | No `.github/`, no `.gitlab-ci.yml`, no `Jenkinsfile`, no `azure-pipelines.yml` | See `tech-debt.md H2` |

Source: `project-structure.md §Build Commands`; `tests/README.md`.

## Configuration Files

| File | Format | Purpose |
|------|--------|---------|
| `profiles/claude-code.toml` | TOML | Claude Code host conventions (64 lines) |
| `profiles/codex.toml` | TOML | Codex CLI host conventions (78 lines — split-root layout) |
| `profiles/cursor.toml` | TOML | Cursor IDE host conventions (75 lines — adds `[extras.rules]` for `.mdc` files) |
| `.claude/settings.json` | JSON | Claude Code permission allow-list (15 lines) |
| `.claude/settings.local.json` | JSON | Personal Claude Code overrides (13 lines, gitignored per `.gitignore:44`) |
| `.aid/settings.yml` | YAML 1.2 | AID runtime config — project identity, review minimum_grade, parallelism, heartbeat interval, per-skill overrides |
| `canonical/templates/settings.yml` | YAML 1.2 | Settings template (81 lines) shipped via render |
| `.gitignore` | gitignore patterns | 47 lines — excludes Python/Node caches, IDE files, `.aid/knowledge/.cache/`, `.claude/worktrees/`, `.aid/.heartbeat/` |

## Languages NOT Present

For completeness — none of these are used anywhere in the repository:

- No **Java**, **C#**, **Go**, **Rust**, **C++**, **Ruby**, **PHP**, **Swift**, **Kotlin**
  source files.
- No **SQL** files.
- No **XML** configuration files (no Maven `pom.xml`, no .NET `.csproj`).
- No **HCL**/Terraform, **Dockerfile**, **Kubernetes** manifests.

Source: `project-structure.md:91-97`.
