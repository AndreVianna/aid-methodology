# Technology Stack

> **Source:** aid-discover (discovery-architect)
> **Status:** Populated (initial dogfood pass, 2026-05-21)
> **Companions:** `project-index.md` (file inventory + language breakdown), `project-structure.md` (per-tool tree layout), `architecture.md` (why this stack).

This document inventories every language, tool, and runtime dependency that this repository contains, ships, or expects to find on a contributor's or adopter's machine. It is structured as **what the repo IS** (its own toolchain), **what the repo SHIPS** (what it embeds in install payloads), and **what it EXPECTS** (the host AI tool and helper runtimes on the user's machine).

For raw file counts and line totals see `project-index.md` § "Language Breakdown". The numbers below are reproduced for convenience but `project-index.md` is the source of truth.

---

## 1. Primary content: Markdown (this repo IS a document)

| Files | Lines | % of repo |
|---|---|---|
| **249** | **33,022** | ~67% of total lines |

Per `project-index.md` Language Breakdown (line 19). Markdown is the primary content language because AID is a methodology specification.

**What is Markdown used for:**

| Purpose | Where | Example |
|---|---|---|
| Normative methodology spec | `methodology/aid-methodology.md` (1,158 lines) | The single source of truth for what AID is. |
| Skill bodies for LLM consumption | `claude-code/.claude/skills/aid-*/SKILL.md`, `codex/.agents/skills/aid-*/SKILL.md`, `cursor/.cursor/skills/aid-*/SKILL.md` | The 10 skills triplicated across three install trees. |
| Agent definitions (Claude Code / Cursor) | `claude-code/.claude/agents/*.md` (22), `cursor/.cursor/agents/*.md` (22) | Markdown + YAML frontmatter. |
| Human-readable skill / agent READMEs | `skills/<name>/README.md` (10), `agents/<name>/README.md` (17) | Rich prose for humans. |
| KB document templates | `templates/knowledge-base/*.md` (16) | The shape every AID Knowledge Base follows. |
| Adopter docs and examples | `docs/` (2 files), `examples/` (9 files), `README.md`, `CONTRIBUTING.md` | |
| `.aid/knowledge/` outputs (this dogfood) | this very file | |

**Frontmatter conventions** (full inventory at `coding-standards.md §1-§4`):

- Claude Code / Cursor agents: YAML between `---` lines with `name`, `description`, `tools`, `model`, optional `permissionMode`, `background`. Example at `claude-code/.claude/agents/architect.md:1-6`. (Cursor uses `Terminal` instead of `Bash` for shell-tool — see `tech-debt.md M6` for the internal-inconsistency cleanup tracked in DISCOVERY-STATE Q52.)
- Claude Code / Cursor skills: YAML with `name`, `description`, `allowed-tools`, optional `argument-hint`, `context`, `agent` (the `context: fork` and `agent:` fields are Claude-Code-specific harness hints; Codex omits them by design per Q51).
- Codex agents: TOML with `name`, `description`, `model`, `model_reasoning_effort`, multi-line `developer_instructions = """..."""`. Example at `codex/.codex/agents/architect.toml:1-39`.
- Cursor `.mdc` rules: YAML with `description`, optional `globs`, `alwaysApply: true|false`.

**No build, no compile.** Markdown is shipped as-is. There is no static-site generator, no markdown-to-HTML pipeline in CI, no `.markdownlint` config anywhere in the tree.

---

## 2. Shell / Bash (the helper scripts)

| Files | Lines |
|---|---|
| **43** | **5,490** |

Per `project-index.md` Language Breakdown (line 20). The high file count comes from the triplication pattern (`project-structure.md` §"Per-Tool Installation Trees", line 68): every Bash script under `templates/` is copied verbatim into each of the three install trees, so almost every script counts four times.

**Distinct script bodies** (each appears 4 times across the trees):

| Script | Lines | Purpose |
|---|---|---|
| `setup.sh` | 161 | Top-level installer. **Single copy** — not triplicated. |
| `templates/scripts/build-project-index.sh` | 368 | `aid-discover` Step 0c pre-pass: emits `.aid/knowledge/project-index.md` with file inventory, sizes, language detection, mtimes. Largest single file in the repo. Run before the 5 sub-agents to eliminate duplicated `find` / `wc` work. |
| `templates/scripts/grade.sh` | 141 | Deterministic grading: reads `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` / `[MINOR]` severity tags from a REVIEW.md, computes a letter grade per the rubric in `templates/grading-rubric.md`. Same input → same grade. |
| `templates/knowledge-summary/scripts/grade.sh` | 194 | Variant for `aid-summarize` HTML quality gating. Slightly more elaborate rubric (a11y, contrast, mermaid validity). |
| `templates/knowledge-summary/scripts/check-preflight.sh` | 100 | `aid-summarize` PREFLIGHT mode entry. |
| `templates/knowledge-summary/scripts/stale-check.sh` | 93 | `aid-summarize` STALE-CHECK mode: compare KB mtime vs last summary mtime. |
| `templates/knowledge-summary/scripts/validate-html.sh` | 94 | HTML structure validation for generated `knowledge-summary.html`. |
| `templates/knowledge-summary/scripts/validate-links.sh` | 78 | Link integrity check. |
| `templates/knowledge-summary/scripts/fetch-mermaid.sh` | 77 | Downloads latest Mermaid library for inlining. |
| `templates/knowledge-summary/scripts/concatenate.sh` | 23 | Inlines CSS + JS + Mermaid into the single HTML output. |
| `templates/knowledge-summary/scripts/writeback-discovery-state.sh` | 138 | Updates `DISCOVERY-STATE.md ## Summarization History` after a successful generate. |
| `claude-code/.claude/skills/aid-discover/scripts/check-preflight.sh` | 45 | `aid-discover` PREFLIGHT (Claude Code only — Codex / Cursor inline this). |
| `claude-code/.claude/skills/aid-discover/scripts/verify-kb.sh` | 60 | Verifies all 16 KB files exist after agent dispatch. |

All shell scripts are **Bash**, not POSIX `sh`. They use Bash-specific features (arrays, `[[ ]]`, parameter expansion). No `#!/bin/sh` shebangs.

**No shellcheck config** (`.shellcheckrc` absent). No `.editorconfig`. No CI that runs shellcheck.

---

## 3. PowerShell (Windows installer parity)

| Files | Lines |
|---|---|
| **5** | **300** |

Per `project-index.md` Language Breakdown (line 26).

| Script | Lines | Purpose |
|---|---|---|
| `setup.ps1` | 156 | Windows port of `setup.sh`. Identical menu, identical copy semantics, identical "Next steps" message. Single copy at repo root. |
| `templates/knowledge-summary/scripts/concatenate.ps1` | 36 (× 4 copies = 144 lines) | Windows port of `concatenate.sh` for the `aid-summarize` HTML output. Triplicated like all knowledge-summary assets. |

The PowerShell scripts target PowerShell 5+ (Windows PowerShell or PowerShell 7). They use PowerShell-specific syntax: `$null`, `$env:VAR`, backtick line continuation.

---

## 4. JavaScript (the offline HTML KB summary viewer)

| Files | Lines |
|---|---|
| **16** | **3,428** |

Per `project-index.md` Language Breakdown (line 21). All JavaScript belongs to the `aid-summarize` HTML viewer pipeline (templates `knowledge-summary/`).

**Distinct files** (each copied 4 times across trees):

| File | Lines | Purpose |
|---|---|---|
| `templates/knowledge-summary/lightbox.js` | 359 | Theme toggle, Mermaid init, click-to-expand lightbox, breadcrumb scrollspy, focus trap, skip-link a11y. Self-contained — no external deps. Inlined into the generated HTML. |
| `templates/knowledge-summary/mermaid-init.js` | 53 | Reference-only standalone copy of the Mermaid theming config. The actual runtime init lives inside `lightbox.js` (see `mermaid-init.js:1-7`). |
| `templates/knowledge-summary/scripts/validate-diagrams.mjs` | 294 | Node-based validator: parses every Mermaid block in `knowledge-summary.html`, attempts to render via Mermaid CLI (`mmdc`), fails the build if any diagram does not parse. Run during `aid-summarize` VALIDATE mode. |
| `templates/knowledge-summary/scripts/contrast-check.mjs` | 151 | Node-based WCAG-AA contrast checker. Verifies the token pairs declared in `accessibility-checklist.md ## Color contrast` for both light and dark themes. |

Total distinct JS source: 359 + 53 + 294 + 151 = **857 lines** × 4 trees = 3,428 lines (matches the language total).

**Module format:** Two `.js` (browser, inlined into HTML at generation time) + two `.mjs` (Node ESM, executed via `node --experimental-vm-modules` or directly on Node >= 18).

---

## 5. CSS (offline HTML KB summary viewer styling)

| Files | Lines |
|---|---|
| **4** | **2,568** |

Per `project-index.md` Language Breakdown (line 22). Single file `templates/knowledge-summary/component-css.css` (642 lines) × 4 copies.

**Architecture:**
- CSS custom properties (variables) for theming, scoped via `html[data-theme="light"]` and `html[data-theme="dark"]` (see `component-css.css:6-63`).
- No preprocessor. No PostCSS pipeline. No autoprefixer. Hand-authored.
- Tokens documented in `templates/knowledge-summary/design-tokens.md` (124 lines) — this is **documentation**, not a build input. ⚠️ The drift question of "is the CSS or the tokens doc the source of truth" is recorded by scout as Q14 in `DISCOVERY-STATE.md`.

---

## 6. HTML (single skeleton, inlined assets)

| Files | Lines |
|---|---|
| **4** | **404** |

Per `project-index.md` Language Breakdown (line 25). Single file `templates/knowledge-summary/html-skeleton.html` (101 lines) × 4 copies.

The skeleton uses Mustache-style `{{PLACEHOLDER}}` substitution (`{{LANG}}`, `{{PROJECT_NAME}}`, `{{INLINE_CSS}}`, `{{BODY_CONTENT}}`, `{{GENERATION_DATE}}`, `{{MERMAID_VERSION}}`, `{{INLINE_LIGHTBOX_JS}}`, `{{MERMAID_VERSION_COMMENT}}`) — replacement is performed by `aid-summarize` at generation time, not by a templating engine. See `aid-summarize/SKILL.md:198-200` (Step 4 "Build the HTML").

---

## 7. TOML (OpenAI Codex agent definitions)

| Files | Lines |
|---|---|
| **22** | **1,522** |

Per `project-index.md` Language Breakdown (line 24). All 22 files live under `codex/.codex/agents/` — one per agent. Schema per `codex/.codex/agents/architect.toml`:

```toml
name = "architect"
description = "..."
model = "gpt-5.5"
model_reasoning_effort = "high"
developer_instructions = """
... (body identical to the Claude Code agent .md body, minus YAML headers) ...
"""
```

Models per Codex tier (per `agents/README.md:13-19` and `codex/README.md:35`):

| Tier | Codex model | reasoning_effort |
|---|---|---|
| Opus | `gpt-5.5` | `high` |
| Sonnet | `gpt-5.4` | `medium` |
| Haiku | `gpt-5.4-mini` | `low` |

**Sonnet tier mapping VERIFIED** per DISCOVERY-STATE Q36 + reviewer spot-check #17: `grep model codex/.codex/agents/{orchestrator,operator,researcher,developer,interviewer,architect,reviewer}.toml` all return `model = "gpt-5.4"` and `model_reasoning_effort = "medium"`. Quality agent also verified tier-consistency across all 22 agents × 3 trees (`tech-debt.md L6`). No exceptions found. The `model_reasoning_effort` field is honored by current Codex CLI versions per the AID install design; vendor-doc cross-reference still pending (see `external-sources.md` §3-4 "Still requires vendor docs").

---

## 8. JSON (this repo's own Claude Code settings)

| Files | Lines |
|---|---|
| **2** | **23** |

Per `project-index.md` Language Breakdown (line 27).

| File | Lines | Notes |
|---|---|---|
| `.claude/settings.json` | 11 | Narrow Bash permission allow-list scoped to this dogfood worktree. Not shipped in the install payload. |
| `.claude/settings..json` | 12 | ⚠️ **Typo file (double dot in name).** Sits alongside `settings.json` with similar contents. See `project-structure.md` Anomaly #2 (line 255) and `DISCOVERY-STATE.md` Q7 — recommended action is to delete it. |

---

## 9. Other / Images / Licenses (8 files, 2,469 lines)

Per `project-index.md` Language Breakdown (line 23):

| Item | Files | Notes |
|---|---|---|
| `methodology/images/*.png` | 4 | The four canonical pipeline diagrams. Binary; line counts in `project-index.md` are byte-derived placeholders, not real lines. |
| `LICENSE` | 1 | MIT, 21 lines. |
| `.gitignore` | 1 | One line: `.aid/`. |
| `cursor/.cursor/rules/aid-methodology.mdc` | 1 | 29 lines. Always-on Cursor rule. |
| `cursor/.cursor/rules/aid-review.mdc` | 1 | 11 lines. Glob-scoped rule (`globs: "**/*.{java,py,ts,js,cs,go,rs}"`). |

---

## 10. Package Manager

**None.**

Verified absences (no file of the following name appears anywhere in `project-index.md`):

- `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` (Node ecosystem)
- `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock` (Python)
- `Cargo.toml`, `Cargo.lock` (Rust)
- `*.csproj`, `*.sln`, `packages.config` (.NET)
- `pom.xml`, `build.gradle`, `build.gradle.kts`, `gradle.properties` (Java)
- `go.mod`, `go.sum` (Go)
- `composer.json` (PHP)
- `Gemfile`, `Gemfile.lock` (Ruby)

Confirmed by `project-index.md ## Notable Files` (line 29-37): the only files there are `CONTRIBUTING.md`, `LICENSE`, `README.md`. No manifest.

The repository ships as a git repository. Distribution = `git clone` + `setup.sh` per `README.md:31-53`. There is no npm / pip / Homebrew / winget package; no curl-pipe-bash bootstrap; no published tarball. The open question of "what is the canonical distribution model beyond git-clone" is recorded by scout as Q2 in `DISCOVERY-STATE.md`.

---

## 11. Runtime / Language Version

**None declared.** No `runtime.txt`, no `.nvmrc`, no `.python-version`, no `.tool-versions`, no `mise.toml`, no `asdf` config.

What the install payloads *expect on the user's machine*:

| Capability | Expected by | Hard or soft? |
|---|---|---|
| **The host AI tool itself** — Claude Code, OpenAI Codex CLI, or Cursor | Everything | Hard. AID cannot function without one of these. |
| **Bash** (Linux / macOS / WSL / Git Bash on Windows) | `aid-discover` (`build-project-index.sh`, `verify-kb.sh`), `aid-summarize` (`validate-html.sh`, `validate-links.sh`, `check-preflight.sh`, `stale-check.sh`, `fetch-mermaid.sh`, `concatenate.sh`, `writeback-discovery-state.sh`, `grade.sh`) | Hard for those skills. Windows-only users without Bash can use `setup.ps1` + Cursor / Codex's own runners, but `aid-discover` Step 0c will not run on pure-PowerShell. |
| **PowerShell 5+** | `setup.ps1`, `concatenate.ps1` | Soft. Bash equivalents exist. Required only for Windows-without-Bash users. |
| **Node.js >= 18** (verified at `templates/knowledge-summary/scripts/check-preflight.sh:87-96` which enforces the version per DISCOVERY-STATE Q54) | `aid-summarize` (`validate-diagrams.mjs`, `contrast-check.mjs` — both use ES module syntax + top-level `await` stable from Node 18 LTS) | Soft. Only `aid-summarize` needs it; skipping these validators means skipping the HTML quality gate. |
| **Mermaid CLI `mmdc`** | `aid-summarize` validate-diagrams step | Soft. Optional per `validate-diagrams.mjs` heuristics. |
| **Network egress to `registry.npmjs.org` + `cdn.jsdelivr.net`** | `aid-summarize` `fetch-mermaid.sh` (only on first run or when Mermaid version is stale) | Soft. Bypassable with `--cdn-mermaid` flag per `aid-summarize/SKILL.md:175-179`. |
| **`git`** | The whole repo is distributed via `git clone` | Hard for installation. |
| **`curl`, `tar`, `find`, `wc`, `awk`, `grep`, `sed`** — standard POSIX utils | Various scripts | Hard for users on Bash-based skills. |

---

## 12. Build System

**None.**

Verified absences:
- No `Makefile` at any directory level (verified by absence from `project-index.md ## Notable Files`).
- No `build.sh`, `build.ps1`, `compile.sh` at any directory level.
- No `.github/workflows/`, no `.gitlab-ci.yml`, no `.circleci/`, no `Jenkinsfile`, no `azure-pipelines.yml`, no `bitbucket-pipelines.yml`.
- No `Dockerfile`, no `docker-compose.yml`, no Helm chart, no Kubernetes manifest, no Terraform / Pulumi / CDK.

This repo has **no build step**. Distribution = checked-in source files. The only "transforms" performed in the codebase are:

1. The host AI tool's own loader reads `*.md` / `*.toml` / `*.mdc` files at startup.
2. `aid-summarize` concatenates CSS + JS + Mermaid into the single `knowledge-summary.html` at user runtime, **not** at repo build time.
3. `setup.sh` / `setup.ps1` performs a literal `cp -r` of the chosen tree into the target project.

### 12.1 Build Commands

There is no compile / transpile / package step. The canonical "build" is the **install step** — copying the chosen tree(s) into a target project:

```bash
# Install AID into a target project (interactive menu)
bash setup.sh /path/to/your/project            # Linux / macOS / git-bash on Windows
pwsh setup.ps1 C:\path\to\your\project         # PowerShell 5.1+ on Windows

# Force overwrite without prompts
bash setup.sh /path/to/your/project --force
pwsh setup.ps1 C:\path\to\your\project -Force
```

Additional commands that run at user / contributor time (not as part of a release artifact):

```bash
# Generate the file inventory consumed by every discovery sub-agent (run by aid-discover Step 0c)
bash templates/scripts/build-project-index.sh --root . --output .aid/knowledge/project-index.md

# Concatenate knowledge-summary assets into a single HTML (run by aid-summarize)
bash .aid/templates/knowledge-summary/scripts/concatenate.sh
pwsh .aid/templates/knowledge-summary/scripts/concatenate.ps1

# Compute KB grade deterministically from a Reviewer issue list (run by aid-discover / aid-summarize)
bash templates/scripts/grade.sh <issue-list-file>
```

**Future build** (per DISCOVERY-STATE Q3 / Q73 resolution): a `tools/propagate-skills.{sh,py}` will derive Codex / Cursor SKILL.md from the canonical Claude Code source + linked `references/` content. Not yet authored — tracked in `tech-debt.md`.

### 12.2 Lint Commands

There is no repo-level linter wired up today (no `.shellcheckrc`, no `.markdownlint*`, no `.eslintrc`, no `.editorconfig`, no `.stylelintrc`). The closest analogues are the **validation scripts shipped with `aid-summarize`** for quality-gating user-generated HTML:

```bash
# Validate the generated knowledge-summary.html
bash templates/knowledge-summary/scripts/validate-html.sh <html-file>
bash templates/knowledge-summary/scripts/validate-links.sh <html-file>
node templates/knowledge-summary/scripts/validate-diagrams.mjs <html-file>     # requires Node 18+; optional mmdc
node templates/knowledge-summary/scripts/contrast-check.mjs <html-file>        # WCAG AA contrast check

# Pre-flight (Node version + curl reachability)
bash templates/knowledge-summary/scripts/check-preflight.sh

# KB freshness check (regen needed?)
bash templates/knowledge-summary/scripts/stale-check.sh

# Verify all 16 KB doc files exist (used by aid-discover)
bash templates/scripts/verify-kb.sh .aid/knowledge/
```

**Future lint** (per DISCOVERY-STATE Q4 + Q35 resolution): a minimal `.github/workflows/ci.yml` adding `shellcheck` on `*.sh`, `markdownlint` on docs, link-check on README + methodology, a structural cross-tree-parity test, and JSON-Schema validation for SKILL.md + agent frontmatter. Not yet authored — tracked in `tech-debt.md`.

---

## 13. Development Tools

| Tool | Required? | Config file |
|---|---|---|
| `git` | Yes (the whole repo is git-distributed) | `.gitignore` (1 line: `.aid/`) |
| Bash | Yes (for any contributor who wants to test discovery against the repo itself) | — |
| PowerShell 5+ | Optional (Windows contributors who want to verify `setup.ps1`) | — |
| Node.js | Optional (only for `aid-summarize` validation) | — |
| Claude Code | Optional but recommended (to test the `claude-code/` install tree end-to-end and to dogfood discovery) | This repo's own `.claude/settings.json` |
| OpenAI Codex CLI | Optional (to test the `codex/` install tree) | — |
| Cursor | Optional (to test the `cursor/` install tree) | — |

A "complete" contributor environment for this repo includes all three host AI tools plus Bash + Node + git + PowerShell. None of this is documented in `CONTRIBUTING.md:1-116`; that file covers PR mechanics and the triplication rule, not toolchain.

---

## 14. Gap: this repo has no traditional build/test pipeline

To call out the omission explicitly (as required by this discovery's brief):

- **No CI configuration** anywhere in the tree. No `.github/workflows/`, no GitLab, Jenkins, CircleCI, Azure Pipelines configs.
- **No test runner config**. No `jest.config.*`, `pytest.ini`, `vitest`, `mocha`, `tap`, `karma`, `playwright.config`, `cypress.json`. No `__tests__/` directory. No `tests/` directory.
- **No lint config**. No `.shellcheckrc`, `.markdownlint.*`, `.eslintrc.*`, `.stylelintrc.*`, `.editorconfig`, `.prettierrc.*`.
- **No pre-commit / pre-push hooks** (no `.husky/`, no `.pre-commit-config.yaml`, no `lefthook.yml`).
- **No structural parity test** verifying the cross-tree duplication is complete (every skill / agent / template exists in all three install trees with no drift).

The only quality-gating mechanism that exists in this repo is the suite of **runtime validation scripts under `templates/knowledge-summary/scripts/`** (`validate-diagrams.mjs`, `validate-html.sh`, `validate-links.sh`, `contrast-check.mjs`, `check-preflight.sh`, `stale-check.sh`). These are invoked from inside the `aid-summarize` skill at runtime against a *user's* KB — not against this repository's own correctness.

The closest thing to a "test of this repo" is the current dogfood discovery: if `/aid-discover` cannot complete a clean pass on the methodology repo itself, that is a structural regression. **Resolution per DISCOVERY-STATE Q12:** adopt the dogfood discovery as a CI smoke test alongside unit tests on `grade.sh` and `build-project-index.sh` (pure Bash, easy to fixture). Tracked in `tech-debt.md`.

---

## 15. Cross-references

- File counts and language breakdown: `project-index.md ## Language Breakdown` (line 17-27).
- Triplication math (why every script appears four times): `project-structure.md ## Per-Tool Installation Trees` (line 58-72).
- Anomalies (double-dot settings file, missing templates, `aid-correct` stub): `project-structure.md ## Anomalies and Things to Flag` (line 252-263).
- Vendor docs not yet fetched (Claude Code, Codex, Cursor, Copilot, Antigravity): `external-sources.md` (full document).
- Distribution / versioning / CI / cross-tree-sync open questions: `DISCOVERY-STATE.md` Q1 (SemVer + VERSION file — user-confirmed), Q2 (git-clone + tagged releases — user-confirmed), Q3 (propagation script + CI drift-check — auto-resolved), Q4 (minimal CI workflow — auto-resolved).
- HTML viewer specifics: `ui-architecture.md`.
