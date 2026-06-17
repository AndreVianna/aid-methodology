---
kb-category: primary
source: hand-authored
intent: |
  Concrete inventory of languages, runtimes, libraries, build tools, and dev tooling used
  by the AID-methodology repository. Covers: Markdown, Bash, Python 3.11+ (stdlib only,
  no third-party deps), JavaScript/ES modules (Node built-ins only), PowerShell 5.1+,
  CSS3, HTML5, TOML 1.0, YAML 1.2, JSON, and JSON Lines. The only runtime library is
  Mermaid (fetched dynamically from npm/jsdelivr). Read this to understand what toolchain
  is required to build, run, or contribute to AID. For file and line counts see
  `.aid/generated/project-index.md` `## Language Breakdown`.
contracts:
  - "Python 3.11+ required by the generator pipeline (tomllib stdlib dependency)"
  - "No third-party Python packages in the generator (stdlib only)"
  - "The PyPI `aid-installer` package requires Python >=3.8 and builds with hatchling; the npm `aid-installer` package requires Node >=18. Both have zero runtime dependencies."
  - "package.json + pyproject.toml exist ONLY under `packages/npm/` and `packages/pypi/` (the published installer shims); none exists for application code"
changelog:
  - 2026-06-05: work-002-auto-installer — the repo gained its first `package.json` (`packages/npm/package.json`) and `pyproject.toml` (`packages/pypi/pyproject.toml`, hatchling build), so the former "no package.json/pyproject at any level" claim is now FALSE and was corrected; added Node 18+ (npm `aid-installer`) and Python 3.8+ (PyPI `aid-installer`, hatchling) as build/packaging tooling, both zero runtime deps; replaced setup.sh/setup.ps1 evidence with the new `aid` CLI (`bin/aid` + `install.sh` / `bin/aid.ps1` + `install.ps1`).
  - 2026-06-03: §9a T3-count strip — removed all hardcoded file-count and line-count figures from frontmatter intent, Languages table, Development Tools table, Build System table, Configuration Files table, and Testing Infrastructure; replaced aggregate counts with pointer to `.aid/generated/project-index.md`; removed stale branch name
  - 2026-06-01: post-merge update for work-001-add-providers (PRs #42/#43/#44) — generator Python files 11→12 (added test_copilot_emitter.py + test_antigravity_emitter.py); TOML config files 3→5 profiles (added copilot-cli + antigravity); byte-identical mirror count canonical+.claude+3 → canonical+.claude+5 profiles
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
| **Markdown** | CommonMark + GFM tables (assumed; no validator pinned) | All docs, skills, agents, templates, recipes. For counts see `.aid/generated/project-index.md` `## Language Breakdown`. |
| **Bash (shell)** | bash 4+ (uses `declare -A` associative arrays, `[[ ]]`, `${var:-}`) | Example: `lib/aid-install-core.sh` (the install-core engine sourced by `bin/aid`); every `canonical/scripts/**/*.sh`. |
| **Python** | 3.11+ (required for `tomllib` stdlib) | Includes `test_copilot_emitter.py` and `test_antigravity_emitter.py` (added by work-001). Pinned by `.claude/skills/generate-profile/scripts/render_lib.py` "Requirements: Python 3.11+ (tomllib is stdlib; no third-party deps)" and `aid_profile.py` "Requirements: Python 3.11+ (tomllib is stdlib from 3.11)". |
| **JavaScript (ES modules + plain)** | ES2020+ (no explicit pin); `.mjs` for ESM scripts | `canonical/scripts/summarize/validate-diagrams.mjs`, `contrast-check.mjs`; `canonical/templates/knowledge-summary/lightbox.js`, `mermaid-init.js`. |
| **PowerShell** | 5.1+ | `bin/aid.ps1`, `install.ps1`, `lib/AidInstallCore.psm1`, `canonical/scripts/summarize/assemble-3part.ps1`. PowerShell 5.1+ pin from `README.md` `### Bootstrap the `aid` CLI` (Windows). |
| **CSS** | CSS3 (custom properties, `:focus-visible`, `@media (forced-colors)`, `@media (prefers-reduced-motion)`) | Single canonical source `canonical/templates/knowledge-summary/component-css.css` rendered into the render-target trees: canonical + `.claude` dogfood + 5 profile trees = **7 copies** on disk (a runtime `.aid/templates/` copy makes 8 total). |
| **HTML** | HTML5 (semantic landmarks: `<header role="banner">`, `<main>`, `<nav>`, `<footer>`) | `canonical/templates/knowledge-summary/html-skeleton.html` rendered into canonical + `.claude` dogfood + 5 profile trees = **7 copies** on disk (a runtime `.aid/templates/` copy makes 8). |
| **TOML** | TOML 1.0 (Python `tomllib` parser implies 1.0) | 5 profile config files (`profiles/*.toml`) + 22 Codex agent definitions (`profiles/codex/.codex/agents/*.toml`). |
| **YAML** | YAML 1.2 (per `canonical/templates/settings.yml` "Format: YAML 1.2.") | `canonical/templates/settings.yml` + mirrors. Also used as Markdown frontmatter throughout. |
| **JSON** | RFC 8259 (Claude Code uses standard JSON) | `.claude/settings.json`, `.claude/settings.local.json`. |
| **JSON Lines** | Per `canonical/EMISSION-MANIFEST.md` `## Line-Ending and Trailing-Newline Rule` — LF-only, one record per line | Used by `profiles/{tool}/emission-manifest.jsonl`. |

File and line counts for all languages live in `.aid/generated/project-index.md` `## Language Breakdown` (regenerated by `build-project-index.sh`). Do not hand-maintain counts in this document.

## Frameworks & Libraries

This repository has **no application-language frameworks** (no React, no Spring, no
Django, etc.). The only runtime libraries are:

| Library | Version | Purpose | Source file / evidence |
|---------|---------|---------|------------------------|
| **Mermaid** | Pinned to v11.15.0 (constant `PINNED_VERSION`); downloaded once from jsdelivr CDN and cached; SHA-verified against `EXPECTED_SHA256` on both cache-hit and post-download paths | Diagram rendering inside `/aid-summarize`-generated HTML; inlined into the single-file output so the viewer works fully offline | `canonical/scripts/summarize/fetch-mermaid.sh` `PINNED_VERSION` / `EXPECTED_SHA256` |
| **(Implicit) jsdelivr CDN** | n/a — download URL: `https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js` | Source of the pinned Mermaid bundle that gets cached + inlined | `canonical/scripts/summarize/fetch-mermaid.sh` `URL=` |

The **generator** uses Python **stdlib only** — `tomllib`, `hashlib`, `json`, `pathlib`, `re`, `dataclasses`,
`argparse`, `tempfile`, `filecmp`, `sys`. Confirmed by `render_lib.py` `import` block; there is no
`requirements.txt` or `setup.py`, and the only `pyproject.toml` in the repo belongs to the
**published installer package** (`packages/pypi/pyproject.toml`, hatchling build), not to the generator.

JavaScript uses **no npm dependencies** — `canonical/templates/knowledge-summary/lightbox.js`
is a self-contained IIFE; `canonical/scripts/summarize/validate-diagrams.mjs` and
`contrast-check.mjs` run with Node's built-in modules only. The **only** `package.json` in the repo
is the **published installer package** (`packages/npm/package.json`), which declares an empty
`"dependencies": {}` — its `bin/aid.js` shim runs on Node built-ins (`child_process`, `path`, `os`, `fs`)
with zero third-party packages.

## Package Manager

| Tool | Version | Lock file |
|------|---------|-----------|
| **None for application code** | — | — |
| **npm** (publishes the `aid-installer` shim; not used to install application deps) | declares `"dependencies": {}` | No `package-lock.json` is committed; the package vendors `bin/` + `lib/` via its `prepack` hook (`packages/npm/scripts/vendor.js`). `packages/npm/package.json`. |
| **pip / pipx + hatchling** (builds + publishes the `aid-installer` shim) | `requires-python >=3.8`; build via `hatchling` | No lock file; `packages/pypi/pyproject.toml` `[build-system] requires = ["hatchling"]`, with a custom build hook (`scripts/vendor.py`) that force-vendors the CLI payload into the sdist. |
| **Implicit: jsDelivr CDN (pinned)** (used only by `/aid-summarize` to download the **pinned** Mermaid release `v11.15.0`, SHA-256-verified; the prior npm-registry "discover latest" call was removed when C1 was resolved 2026-05-29) | n/a | The SHA-verified library is cached at `.aid/knowledge/.cache/mermaid.min.js` (per `canonical/scripts/summarize/fetch-mermaid.sh`). |

A `package.json` and a `pyproject.toml` **do** exist — but **only** under `packages/npm/` and
`packages/pypi/` (the published installer shims). There is still no `package.json`/`pyproject.toml`
for application code, and no `Cargo.toml`, `go.mod`, `requirements.txt`, or `pom.xml` anywhere
(see `project-structure.md` `## Languages NOT Present`).

## Runtime

| Runtime | Version | How detected |
|---------|---------|--------------|
| **Python** | 3.11+ | `.claude/skills/generate-profile/SKILL.md` "Python 3.11+ is available" Pre-flight check (`python --version`); `render_lib.py` "Requirements: Python 3.11+"; `aid_profile.py` "Requirements: Python 3.11+". Required for `tomllib` stdlib. |
| **Bash** | 4+ (associative arrays) | `bin/aid` shebang `#!/usr/bin/env bash`; `lib/aid-install-core.sh` engine; every `canonical/scripts/**/*.sh`. Per `README.md` Linux/macOS bootstrap: `curl … \| bash`. |
| **PowerShell** | 5.1+ | `README.md` Windows bootstrap pin "Windows (PowerShell 5.1+)"; `bin/aid.ps1` + `install.ps1` + `lib/AidInstallCore.psm1`. |
| **Node.js** | 18+ (optional — only for `/aid-summarize` diagram validators) | `README.md` `### Runtime requirements`: "Node 18+ is optional — only `/aid-summarize` uses it, for diagram validation." `.mjs` files imply ESM support (Node 14+ minimum). |
| **Git** | unpinned (any modern version) | `README.md` `### Runtime requirements`: "Git" listed as a runtime requirement; `.claude/skills/generate-profile/SKILL.md` "git working tree" Pre-flight runs `git rev-parse --git-dir`. |
| **One of: Claude Code / OpenAI Codex CLI / Cursor IDE / GitHub Copilot CLI / Antigravity** | unpinned (host-tool-specific) | `README.md` `### Runtime requirements`: "One or more host AI tools." End-user runtime; required to invoke the slash commands. The 5 install profiles map 1:1 to these host tools (`profiles/*.toml`). |

## Build System

| Tool | Config file location | Purpose |
|------|----------------------|---------|
| **`run_generator.py`** | `.claude/skills/generate-profile/scripts/run_generator.py` | The build. Iterates `profiles/*.toml` (5 profiles), calls each renderer per profile, performs the pure-mirror deletion pass, writes one emission manifest per profile, then runs VERIFY (deterministic) (hard) and VERIFY (advisory) (advisory). |
| **Per-tool profile TOMLs** | `profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml`, `profiles/copilot-cli.toml`, `profiles/antigravity.toml` (5 profiles) | Per-host conventions: `[layout]`, `[agent.frontmatter]` (incl. `format` ∈ markdown/toml/copilot-agent/antigravity-rule), `[skill.frontmatter]`, `[model_tiers]`, `[tool_names]`, `[filename_map]`, `[extras]` (incl. `rules_frontmatter` + per-rule `output_filename`), `[capabilities]`. |
| **Emission manifest spec** | `canonical/EMISSION-MANIFEST.md` | Authoritative spec for the manifest format (JSONL, LF-only, sentinel first line `{"_manifest_version": 1}`, sorted by `dst`). |
| **End-user installer** | `bin/aid` (Bash) / `bin/aid.ps1` (PowerShell) | The persistent global `aid` CLI that copies a built profile tree into a target project (not a build per se — consumes the rendered `profiles/` trees). |
| **Installer-package builds** | `packages/npm/scripts/vendor.js` (npm `prepack`) / `packages/pypi/scripts/vendor.py` (hatchling build hook) | Vendor the `bin/` + `lib/` CLI payload into the published npm / PyPI `aid-installer` packages. |
| **Release packager** | `release.sh` | Builds the five per-profile tarballs + the `aid-cli-v<VERSION>.tar.gz` CLI bundle + the two libs + `SHA256SUMS`, then `gh release create`. Tag-triggered via `.github/workflows/release.yml`. |

### Build Commands

```bash
# Full build (renders canonical → all 5 install trees + runs VERIFY (deterministic)/(advisory))
python .claude/skills/generate-profile/scripts/run_generator.py

# Build one tree only (rare)
python .claude/skills/generate-profile/scripts/render_skills.py \
    --canonical-root . \
    --profile profiles/claude-code.toml \
    --output-root profiles/claude-code/.claude

# Build verification (byte-identical re-render audit; hard gate)
python .claude/skills/generate-profile/scripts/verify_deterministic.py
```

Source: `run_generator.py`.

### Lint Commands

This repository has **no language linters** (no ESLint, no flake8, no shellcheck config; the
only `pyproject.toml` is the PyPI `aid-installer` build manifest under `packages/pypi/`, which
declares no linter `[tool.*]` config). Quality is enforced by:

```bash
# Rebuild file inventory used by Discovery
bash canonical/scripts/kb/build-project-index.sh --root . --output .aid/generated/project-index.md

# Canonical helper-script test suites (currently 24 suites) — run all via the aggregator
bash tests/run-all.sh                                 # discovers tests/canonical/test-*.sh by glob

# Or run an individual suite
bash tests/canonical/test-writeback-state.sh
bash tests/canonical/test-delivery-gate-aggregate.sh
bash tests/canonical/test-compute-block-radius.sh
bash tests/canonical/test-parse-recipe.sh             # slowest suite — needs timeout ≥180s
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-fetch-mermaid.sh
bash tests/canonical/test-grade.sh
```

**KB claim verification** is performed by `aid-reviewer` dispatched from
`/aid-discover REVIEW` state (see `canonical/agents/aid-reviewer/AGENT.md`).
The former `canonical/scripts/kb/verify-claims.sh` was deleted in cycle-1 (closure
recorded in `tech-debt.md` changelog).

There is **no auto-fix linter**. Quality gates are the AID skills themselves: `aid-discover`
adversarial review, `aid-execute` two-tier review per task + per delivery, `aid-deploy`
verification step.

Source: `project-structure.md` `## Build & Test System`; `tests/README.md`.

## Development Tools

| Tool | Version | Purpose | Config file |
|------|---------|---------|-------------|
| **Git** | unpinned | VCS — working branch is the current working branch (`git branch --show-current`) | `.git/`; `.gitignore` (repo root) |
| **`build-project-index.sh`** | `canonical/scripts/kb/build-project-index.sh` | Pre-builds the file inventory consumed by the 5 discovery sub-agents | — |
| **`grade.sh`** | `canonical/scripts/grade.sh` | Deterministic severity-tag → letter-grade scorer used by the review state of every skill | — |
| **`parse-recipe.sh`** | `canonical/scripts/interview/parse-recipe.sh` | Parses recipe `{{slot}}` placeholders; emits lite-path artifacts | — |
| **`writeback-state.sh`** | `canonical/scripts/execute/writeback-state.sh` | Updates per-area `STATE.md` after a task completes | — |
| **`compute-block-radius.sh`** | `canonical/scripts/execute/compute-block-radius.sh` | BFS over the task dependency graph to compute failure block radius (pool dispatch) | — |
| **`read-setting.sh`** | `canonical/scripts/config/read-setting.sh` | Reads a dotted-path key from `.aid/settings.yml` with default fallback | — |
| **`fetch-mermaid.sh`** | `canonical/scripts/summarize/fetch-mermaid.sh` | Downloads + caches the pinned Mermaid release (`v11.15.0`, SHA-256-verified) for offline inlining | — |
| **`validate-diagrams.mjs`** | `canonical/scripts/summarize/validate-diagrams.mjs` | Mermaid syntax validation for the generated HTML | — |
| **`contrast-check.mjs`** | `canonical/scripts/summarize/contrast-check.mjs` | WCAG AA color-contrast audit on the design tokens; runs against both light + dark themes | — |
| **`validate-html-output.sh`** | `canonical/scripts/summarize/validate-html-output.sh` | HTML output validation for `/aid-summarize` | — |
| **`grade-summary.sh`** | `canonical/scripts/summarize/grade-summary.sh` | Aggregates the summarize-phase validators into a single Machine-Grade score | — |
| **`manual-checklist.sh`** | `canonical/scripts/summarize/manual-checklist.sh` | Drives the K1/K2/V1 interactive Human-Grade checklist for `/aid-summarize` | — |
| **`spot-check-facts.sh`** | `canonical/scripts/summarize/spot-check-facts.sh` | Spot-checks KB facts against source citations | — |
| **`stale-check.sh`** | `canonical/scripts/summarize/stale-check.sh` | Detects stale KB sections | — |
| **`assemble-3part.sh` / `assemble-3part.ps1`** | `canonical/scripts/summarize/assemble-3part.sh` / `assemble-3part.ps1` | Assembles the final single-file `knowledge-summary.html` by concatenating `part1.html` + cached Mermaid + `part2.html` (PowerShell version uses byte-level concat to avoid CRLF interpretation, see `assemble-3part.ps1` `# Use byte-level concat`) | — |
| **`discover-preflight.sh`** | `canonical/scripts/kb/discover-preflight.sh` | Verifies `.aid/knowledge/STATE.md` exists + not in Plan Mode before any `/aid-discover` state | — |
| **`summarize-preflight.sh`** | `canonical/scripts/summarize/summarize-preflight.sh` | Verifies KB is User-Approved before `/aid-summarize` runs | — |
| **`build-kb-index.sh`** | `canonical/scripts/kb/build-kb-index.sh` | Builds `.aid/knowledge/INDEX.md` from KB sources | — |
| **`build-metrics.sh`** | `canonical/scripts/kb/build-metrics.sh` | KB doc-size metrics | — |
| **`writeback-state.sh`** | `canonical/scripts/summarize/writeback-state.sh` | Writes summarize-phase state back to `.aid/knowledge/STATE.md` | — |
| **`complexity-score.sh`** | `canonical/scripts/execute/complexity-score.sh` | Task complexity scoring used by `/aid-execute` | — |

Each script above has **seven byte-identical copies** on disk (canonical + dogfood `.claude/`
+ 5 profile trees: claude-code, codex, cursor, copilot-cli, antigravity) — the high shell-file
count relative to the unique script count is by design (per-tool mirroring); see
`project-structure.md` `## Unusual Structure Notes` "mirror" note. For current shell-file totals
see `.aid/generated/project-index.md` `## Language Breakdown`.

## Testing Infrastructure

| Tool | Version | Purpose | Config / location |
|------|---------|---------|---------|
| **Pure bash test suites** | bash 4+ | All tests are plain bash scripts (no pytest, no jest, no junit); aggregated by `tests/run-all.sh` + shared `tests/lib/assert.sh` | `tests/canonical/test-*.sh` (currently 35 suites — see `tests/README.md`) |
| **Native Windows installer test** | PowerShell 5.1+ | Real-Windows installer/CLI coverage (run by `installer-tests.yml` on `windows-latest`) | `tests/windows/Test-AidInstaller.ps1` |
| **Generator self-tests** | Python 3.11+ | Manifest-safety unit tests | `.claude/skills/generate-profile/scripts/test_manifest_safety.py` |
| **CI** | **GitHub Actions (enforced)** | `.github/workflows/test.yml` runs render-drift + all canonical suites (via `tests/run-all.sh`) + generator self-tests + hygiene on PR/push (required status check on `master`). `installer-tests.yml` runs the cross-platform installer/CLI matrix (ubuntu + windows); `release.yml` is the tag-triggered gate+publish pipeline. | See `test-landscape.md`, `infrastructure.md` `## CI / CD Pipeline` |

Source: `project-structure.md` `## Build & Test System`; `tests/README.md`.

## Configuration Files

| File | Format | Purpose |
|------|--------|---------|
| `profiles/claude-code.toml` | TOML | Claude Code host conventions |
| `profiles/codex.toml` | TOML | Codex CLI host conventions (split-root layout) |
| `profiles/cursor.toml` | TOML | Cursor IDE host conventions (adds `[extras.rules]` for `.mdc` files) |
| `profiles/copilot-cli.toml` | TOML | GitHub Copilot CLI host conventions (`output_root .github`, `[agent].format = copilot-agent`, `Bash → shell` remap) |
| `profiles/antigravity.toml` | TOML | Antigravity host conventions (`output_root .agent`, `[agent].format = antigravity-rule`, `[model_tiers.large/medium/small]` detailed Gemini-3 form, empty `[tool_names]`) |
| `.claude/settings.json` | JSON | Claude Code permission allow-list |
| `.claude/settings.local.json` | JSON | Personal Claude Code overrides (gitignored per `.gitignore` `.claude/settings.local.json`) |
| `.aid/settings.yml` | YAML 1.2 | AID runtime config — project identity, review minimum_grade, parallelism, heartbeat interval, per-skill overrides |
| `canonical/templates/settings.yml` | YAML 1.2 | Settings template shipped via render |
| `packages/npm/package.json` | JSON | npm `aid-installer` package manifest — `bin.aid` → `bin/aid.js`, `engines.node >=18`, empty `dependencies`, `prepack` vendoring hook |
| `packages/pypi/pyproject.toml` | TOML | PyPI `aid-installer` package manifest — hatchling build, `requires-python >=3.8`, empty `dependencies`, `[project.scripts] aid`, custom vendoring build hook |
| `VERSION` | plain text | Single-source release version (`1.1.0`); FR10 version-sync asserts it equals both package manifests + the release tag |
| `.gitignore` | gitignore patterns | Excludes Python/Node caches, IDE files, `.aid/knowledge/.cache/`, `.claude/worktrees/`, `.aid/.heartbeat/` |

## Languages NOT Present

For completeness — none of these are used anywhere in the repository:

- No **Java**, **C#**, **Go**, **Rust**, **C++**, **Ruby**, **PHP**, **Swift**, **Kotlin**
  source files.
- No **SQL** files.
- No **XML** configuration files (no Maven `pom.xml`, no .NET `.csproj`).
- No **HCL**/Terraform, **Dockerfile**, **Kubernetes** manifests.

Source: `project-structure.md` `## Languages NOT Present`.
