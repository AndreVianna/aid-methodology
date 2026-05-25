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
| Normative methodology spec | `methodology/aid-methodology.md` (1,071 lines) | The single source of truth for what AID is. |
| Skill bodies for LLM consumption | `profiles/claude-code/.claude/skills/aid-*/SKILL.md`, `profiles/codex/.agents/skills/aid-*/SKILL.md`, `profiles/cursor/.cursor/skills/aid-*/SKILL.md` | The 10 skills triplicated across three install trees. |
| Agent definitions (Claude Code / Cursor) | `profiles/claude-code/.claude/agents/*.md` (22), `profiles/cursor/.cursor/agents/*.md` (22) | Markdown + YAML frontmatter. |
| Human-readable skill / agent READMEs | `skills/<name>/README.md` (10), `agents/<name>/README.md` (17) | Rich prose for humans. |
| KB document templates | `canonical/templates/knowledge-base/*.md` (16) | The shape every AID Knowledge Base follows. |
| Adopter docs and examples | `docs/` (2 files), `examples/` (9 files), `README.md`, `CONTRIBUTING.md` | |
| `.aid/knowledge/` outputs (this dogfood) | this very file | |

**Frontmatter conventions** (full inventory at `coding-standards.md §1-§4`):

- Claude Code / Cursor agents: YAML between `---` lines with `name`, `description`, `tools`, `model`, optional `permissionMode`, `background`. Example at `profiles/claude-code/.claude/agents/architect.md:1-6`. (Cursor uses `Terminal` instead of `Bash` for shell-tool — see `tech-debt.md M6` for the internal-inconsistency cleanup tracked in STATE.md Q52.)
- Claude Code / Cursor skills: YAML with `name`, `description`, `allowed-tools`, optional `argument-hint`, `context`, `agent` (the `context: fork` and `agent:` fields are Claude-Code-specific harness hints; Codex omits them by design per Q51).
- Codex agents: TOML with `name`, `description`, `model`, `model_reasoning_effort`, multi-line `developer_instructions = """..."""`. Example at `profiles/codex/.codex/agents/architect.toml:1-39`.
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
| `setup.sh` | 162 | Top-level installer. **Single copy** — not triplicated. |
| `canonical/templates/scripts/build-project-index.sh` | 368 | `aid-discover` Step 0c pre-pass: emits `.aid/knowledge/project-index.md` with file inventory, sizes, language detection, mtimes. Largest single file in the repo. Run before the 5 sub-agents to eliminate duplicated `find` / `wc` work. |
| `canonical/templates/scripts/grade.sh` | 141 | Deterministic grading: reads `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` / `[MINOR]` severity tags from a reviewer's issue list recorded in `work STATE.md ## Tasks Status` (per FR2; pre-FR2 was `task-NNN-STATE.md`), computes a letter grade per the rubric in `canonical/templates/grading-rubric.md`. Same input → same grade. |
| `canonical/templates/knowledge-summary/scripts/grade.sh` | 194 | Variant for `aid-summarize` HTML quality gating. Slightly more elaborate rubric (a11y, contrast, mermaid validity). |
| `canonical/templates/knowledge-summary/scripts/check-preflight.sh` | 100 | `aid-summarize` PREFLIGHT mode entry. |
| `canonical/templates/knowledge-summary/scripts/stale-check.sh` | 93 | `aid-summarize` STALE-CHECK mode: compare KB mtime vs last summary mtime. |
| `canonical/templates/knowledge-summary/scripts/validate-html.sh` | 94 | HTML structure validation for generated `knowledge-summary.html`. |
| `canonical/templates/knowledge-summary/scripts/validate-links.sh` | 78 | Link integrity check. |
| `canonical/templates/knowledge-summary/scripts/fetch-mermaid.sh` | 77 | Downloads latest Mermaid library for inlining. |
| `canonical/templates/knowledge-summary/scripts/concatenate.sh` | 23 | Inlines CSS + JS + Mermaid into the single HTML output. |
| `canonical/templates/knowledge-summary/scripts/writeback-state.sh` | 139 (canonical) / 173 (per-profile post-render) | Updates the Discovery-area `STATE.md ## Summarization History` after a successful generate. Renamed from `writeback-discovery-state.sh` post-FR2 (work-003 feature-002 area-STATE consolidation). |
| `profiles/claude-code/.claude/skills/aid-discover/scripts/check-preflight.sh` | 45 | `aid-discover` PREFLIGHT (all 3 profile trees ship identical scripts via canonical-generator). |
| `profiles/claude-code/.claude/skills/aid-discover/scripts/verify-kb.sh` | 60 | Verifies all 16 KB files exist after agent dispatch. |

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
| `setup.ps1` | 157 | Windows port of `setup.sh`. Identical menu, identical copy semantics, identical "Next steps" message. Single copy at repo root. |
| `canonical/templates/knowledge-summary/scripts/concatenate.ps1` | 36 (× 4 copies = 144 lines) | Windows port of `concatenate.sh` for the `aid-summarize` HTML output. Triplicated like all knowledge-summary assets. |

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
| `canonical/templates/knowledge-summary/lightbox.js` | 359 | Theme toggle, Mermaid init, click-to-expand lightbox, breadcrumb scrollspy, focus trap, skip-link a11y. Self-contained — no external deps. Inlined into the generated HTML. |
| `canonical/templates/knowledge-summary/mermaid-init.js` | 53 | Reference-only standalone copy of the Mermaid theming config. The actual runtime init lives inside `lightbox.js` (see `mermaid-init.js:1-7`). |
| `canonical/templates/knowledge-summary/scripts/validate-diagrams.mjs` | 294 | Node-based validator: parses every Mermaid block in `knowledge-summary.html`, attempts to render via Mermaid CLI (`mmdc`), fails the build if any diagram does not parse. Run during `aid-summarize` VALIDATE mode. |
| `canonical/templates/knowledge-summary/scripts/contrast-check.mjs` | 151 | Node-based WCAG-AA contrast checker. Verifies the token pairs declared in `accessibility-checklist.md ## Color contrast` for both light and dark themes. |

Total distinct JS source: 359 + 53 + 294 + 151 = **857 lines** × 4 trees = 3,428 lines (matches the language total).

**Module format:** Two `.js` (browser, inlined into HTML at generation time) + two `.mjs` (Node ESM, executed via `node --experimental-vm-modules` or directly on Node >= 18).

---

## 5. CSS (offline HTML KB summary viewer styling)

| Files | Lines |
|---|---|
| **4** | **2,568** |

Per `project-index.md` Language Breakdown (line 22). Single file `canonical/templates/knowledge-summary/component-css.css` (642 lines) × 4 copies.

**Architecture:**
- CSS custom properties (variables) for theming, scoped via `html[data-theme="light"]` and `html[data-theme="dark"]` (see `component-css.css:6-63`).
- No preprocessor. No PostCSS pipeline. No autoprefixer. Hand-authored.
- Tokens documented in `canonical/templates/knowledge-summary/design-tokens.md` (124 lines) — this is **documentation**, not a build input. ⚠️ The drift question of "is the CSS or the tokens doc the source of truth" is recorded by scout as Q14 in `DISCOVERY-STATE.md`.

---

## 6. HTML (single skeleton, inlined assets)

| Files | Lines |
|---|---|
| **4** | **404** |

Per `project-index.md` Language Breakdown (line 25). Single file `canonical/templates/knowledge-summary/html-skeleton.html` (101 lines) × 4 copies.

The skeleton uses Mustache-style `{{PLACEHOLDER}}` substitution (`{{LANG}}`, `{{PROJECT_NAME}}`, `{{INLINE_CSS}}`, `{{BODY_CONTENT}}`, `{{GENERATION_DATE}}`, `{{MERMAID_VERSION}}`, `{{INLINE_LIGHTBOX_JS}}`, `{{MERMAID_VERSION_COMMENT}}`) — replacement is performed by `aid-summarize` at generation time, not by a templating engine. See `aid-summarize/SKILL.md:198-200` (Step 4 "Build the HTML").

---

## 7. TOML (OpenAI Codex agent definitions)

| Files | Lines |
|---|---|
| **22** | **1,522** |

Per `project-index.md` Language Breakdown (line 24). All 22 files live under `profiles/codex/.codex/agents/` — one per agent. Schema per `profiles/codex/.codex/agents/architect.toml`:

```toml
name = "architect"
description = "..."
model = "gpt-5.5"
model_reasoning_effort = "high"
developer_instructions = """
... (body identical to the Claude Code agent .md body, minus YAML headers) ...
"""
```

Models per Codex tier (per `architecture.md:354-380` Pattern 8 Three-tier agent model and `profiles/codex/README.md:35`):

| Tier | Codex model | reasoning_effort |
|---|---|---|
| Opus | `gpt-5.5` | `high` |
| Sonnet | `gpt-5.4` | `medium` |
| Haiku | `gpt-5.4-mini` | `low` |

**Sonnet tier mapping VERIFIED** per STATE.md Q36 + reviewer spot-check #17: `grep model profiles/codex/.codex/agents/{orchestrator,operator,researcher,developer,interviewer,architect,reviewer}.toml` all return `model = "gpt-5.4"` and `model_reasoning_effort = "medium"`. Quality agent also verified tier-consistency across all 22 agents × 3 trees (`tech-debt.md L6`). No exceptions found. The `model_reasoning_effort` field is honored by current Codex CLI versions per the AID install design; vendor-doc cross-reference still pending (see `external-sources.md` §3-4 "Still requires vendor docs").

---

## 8. JSON (this repo's own Claude Code settings)

| Files | Lines |
|---|---|
| **2** | **23** |

Per `project-index.md` Language Breakdown (line 27).

| File | Lines | Notes |
|---|---|---|
| `.claude/settings.json` | 11 | Narrow Bash permission allow-list scoped to this dogfood worktree. Not shipped in the install payload. |
| `.claude/settings.json` (the historical double-dot typo file `.claude/settings..json` was removed; see `project-structure.md` Anomaly #2) | 12 | ⚠️ **Typo file (double dot in name).** Sits alongside `settings.json` with similar contents. See `project-structure.md` Anomaly #2 (line 255) and `STATE.md` Q7 — recommended action is to delete it. |

---

## 9. Other / Images / Licenses (8 files, 2,469 lines)

Per `project-index.md` Language Breakdown (line 23):

| Item | Files | Notes |
|---|---|---|
| `methodology/images/*.png` | 4 | The four canonical pipeline diagrams. Binary; line counts in `project-index.md` are byte-derived placeholders, not real lines. |
| `LICENSE` | 1 | MIT, 21 lines. |
| `.gitignore` | 1 | 47 lines (Python/Node/IDE patterns + selective `.aid/knowledge/.cache/` L40 + `.aid/.heartbeat/` L47; does NOT exclude the full `.aid/` tree — KB and work artifacts are version-tracked). |
| `profiles/cursor/.cursor/rules/aid-methodology.mdc` | 1 | 29 lines. Always-on Cursor rule. |
| `profiles/cursor/.cursor/rules/aid-review.mdc` | 1 | 11 lines. Glob-scoped rule (`globs: "**/*.{java,py,ts,js,cs,go,rs}"`). |

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
| **Bash** (Linux / macOS / WSL / Git Bash on Windows) | `aid-discover` (`build-project-index.sh`, `verify-kb.sh`), `aid-summarize` (`validate-html.sh`, `validate-links.sh`, `check-preflight.sh`, `stale-check.sh`, `fetch-mermaid.sh`, `concatenate.sh`, `writeback-state.sh`, `grade.sh`) | Hard for those skills. Windows-only users without Bash can use `setup.ps1` + Cursor / Codex's own runners, but `aid-discover` Step 0c will not run on pure-PowerShell. |
| **PowerShell 5+** | `setup.ps1`, `concatenate.ps1` | Soft. Bash equivalents exist. Required only for Windows-without-Bash users. |
| **Node.js >= 18** (verified at `canonical/templates/knowledge-summary/scripts/check-preflight.sh:87-96` which enforces the version per STATE.md Q54) | `aid-summarize` (`validate-diagrams.mjs`, `contrast-check.mjs` — both use ES module syntax + top-level `await` stable from Node 18 LTS) | Soft. Only `aid-summarize` needs it; skipping these validators means skipping the HTML quality gate. |
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

This repo has **no traditional build step** (no compile, no transpile, no bundling). It does, however, have a **canonical generator** (shipped via work-002) that propagates a single source tree to the per-tool install payloads. The "transforms" performed in the codebase are:

1. **`run_generator.py`** (top-level, 84 lines) — the canonical generator. Reads `profiles/{claude-code,codex,cursor}.toml` (3 profile descriptors), then for each profile invokes the three worker renderers (`render_agents.py`, `render_skills.py`, `render_templates.py`) under `.claude/skills/aid-generate/scripts/` to emit `profiles/{claude-code,codex,cursor}/...` from `canonical/{agents,skills,templates,rules}/`. Each render emits an `emission-manifest.jsonl` with `sha256` per file; subsequent runs diff against the previous manifest and delete obsolete files (`run_generator.py:43-60`). Followed by `VERIFY-4a` (deterministic re-render check, `verify_deterministic.py`, 513 lines) and `VERIFY-4b` (advisory drift check, `verify_advisory.py`, 343 lines) — see §12.0 below.
2. The host AI tool's own loader reads `*.md` / `*.toml` / `*.mdc` files at startup.
3. `aid-summarize` concatenates CSS + JS + Mermaid into the single `knowledge-summary.html` at user runtime, **not** at repo build time.
4. `setup.sh` / `setup.ps1` performs a literal `cp -r` of the chosen pre-rendered profile tree into the target project. The installer is a downstream consumer of `run_generator.py`'s output — it does not re-render.

### 12.0 Canonical Generator (the closest thing to a build)

The canonical-generator pipeline (work-002) is the only Python code in this repo and the only thing that runs at "contributor build" time (as opposed to user-runtime). Entry point: `run_generator.py` (top-level). Workers and supporting modules live under `.claude/skills/aid-generate/scripts/`:

| File | Lines | Purpose |
|---|---|---|
| `run_generator.py` | 84 | Top-level driver. Iterates `profiles/*.toml`, loads each profile, dispatches the three render workers, runs VERIFY-4a + VERIFY-4b. |
| `.claude/skills/aid-generate/scripts/profile.py` | 516 | Profile loader + validator. `load_profile(path) -> Profile`, `validate(profile) -> errors`. Reads the `[layout]`, `[agent]`, `[skill]`, `[model_tiers]`, `[tool_names]`, `[filename_map]`, `[extras]`, `[capabilities]` TOML sections. |
| `.claude/skills/aid-generate/scripts/harness.py` | 615 | Shared utilities: `EmissionManifest` (records emitted-file `sha256` + relative dst path; supports `load`, `diff(prev)`, `write`), `read_canonical_file`, `substitute_filenames` (canonical placeholder -> per-profile filename, e.g., `{project_context_file}` -> `CLAUDE.md` for Claude Code, `AGENTS.md` for Codex / Cursor), `sha256_hex`. |
| `.claude/skills/aid-generate/scripts/render_agents.py` | 503 | Worker: emits per-profile agent files from `canonical/agents/{name}/AGENT.md`. Markdown -> markdown (Claude Code, Cursor) or markdown -> TOML (Codex). |
| `.claude/skills/aid-generate/scripts/render_skills.py` | 450 | Worker: emits per-profile skill files from `canonical/skills/aid-{name}/`. Copies SKILL.md + the entire `references/` + `scripts/` subtree, applying filename substitutions to `.md` files. |
| `.claude/skills/aid-generate/scripts/render_templates.py` | 245 | Worker: copies `canonical/templates/` subtree to each profile's `{templates_dir}` location with the same substitution discipline. |
| `.claude/skills/aid-generate/scripts/verify_deterministic.py` | 513 | VERIFY-4a: re-runs the renderers in a temp dir and compares against the on-disk profile trees; any byte difference fails the build. Used as a determinism guard. |
| `.claude/skills/aid-generate/scripts/verify_advisory.py` | 343 | VERIFY-4b: non-blocking drift detector that flags advisory concerns (e.g., orphan files, manifest gaps). Reports skip/check counts. |
| `.claude/skills/aid-generate/scripts/test_manifest_safety.py` | 254 | Manifest-safety regression test (run via `python test_manifest_safety.py`). |
| `.claude/skills/aid-generate/SKILL.md` | 261 | The skill front-end that drives the same pipeline from inside a host (the methodology dogfoods its own generator). |

The canonical source tree (`canonical/`, top-level since work-002) holds:

- `canonical/agents/{name}/AGENT.md` + `README.md` (22 agents).
- `canonical/skills/aid-{name}/SKILL.md` + `references/*.md` + `scripts/*.sh` + `README.md` (10 skills).
- `canonical/templates/` (everything under templates — `knowledge-base/`, `knowledge-summary/`, `requirements/`, `specs/`, `delivery-plans/`, `feedback-artifacts/`, `scripts/`, plus root-level `work-state-template.md`, `discovery-state-template.md`, `feature.md`, `feature-inventory.md`, `known-issues.md`, `package.md`, `requirements.md`, `ui-architecture.md`).
- `canonical/rules/{aid-methodology,aid-review}.mdc` (Cursor-only outputs).
- `canonical/EMISSION-MANIFEST.md` (manifest documentation).

`canonical/` is the **edit surface** — contributors change a skill / agent / template here, then re-run `python run_generator.py` to refresh the three profile trees. The pre-canonical-generator "quadruplicate rule" (`CONTRIBUTING.md:21-26`) is now superseded by this generator.

Six orphan templates currently exist in install trees but not in `canonical/templates/` (`feature.md`, `feature-inventory.md` at root, `known-issues.md`, `package.md`, `requirements.md` at root, `ui-architecture.md` at root) — escalated as Q190 cycle 11, pending promotion + orphan-detection check in `run_generator.py`.

### 12.1 Build Commands

There is no compile / transpile / package step. The canonical "build" is the **generator pass** that renders `canonical/` into the three `profiles/{claude-code,codex,cursor}/` install trees, followed by the **install step** that copies the chosen tree into a target project:

```bash
# Regenerate all 3 profile trees from canonical/ (contributor workflow)
python run_generator.py                              # writes emission-manifest.jsonl + runs VERIFY-4a + VERIFY-4b

# Then install the chosen tree into a user project:

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

**Note (cycle 11):** The "Future build" placeholder above (STATE.md Q3 / Q73) was **shipped by work-002 as `run_generator.py` + the three renderers** described in §12.0. The propagation no longer goes from a Claude-Code-anchored source to Codex / Cursor variants — instead, all three trees are derived from `canonical/` via per-profile TOMLs. Q73 (453/1078/1090-line SKILL.md divergence) is resolved — all three trees ship 307 lines for `aid-discover/SKILL.md` (post-thin-router refactor + cycle-19 additions; was 548 pre-refactor).

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

**Future lint** (per STATE.md Q4 + Q35 resolution): a minimal `.github/workflows/ci.yml` adding `shellcheck` on `*.sh`, `markdownlint` on docs, link-check on README + methodology, a structural cross-tree-parity test, and JSON-Schema validation for SKILL.md + agent frontmatter. Not yet authored — tracked in `tech-debt.md`.

---

## 13. Development Tools

| Tool | Required? | Config file |
|---|---|---|
| `git` | Yes (the whole repo is git-distributed) | `.gitignore` (47 lines — Python/Node/IDE + selective `.aid/knowledge/.cache/` + `.aid/.heartbeat/`) |
| Bash | Yes (for any contributor who wants to test discovery against the repo itself) | — |
| PowerShell 5+ | Optional (Windows contributors who want to verify `setup.ps1`) | — |
| Node.js | Optional (only for `aid-summarize` validation) | — |
| Claude Code | Optional but recommended (to test the `claude-code/` install tree end-to-end and to dogfood discovery) | This repo's own `.claude/settings.json` |
| OpenAI Codex CLI | Optional (to test the `codex/` install tree) | — |
| Cursor | Optional (to test the `cursor/` install tree) | — |
| **Python 3.11+** | **Required for contributors who edit `canonical/` and need to re-render the profile trees** (entry point `python run_generator.py`) | Profile TOMLs at `profiles/{claude-code,codex,cursor}.toml`; worker scripts under `.claude/skills/aid-generate/scripts/` |

A "complete" contributor environment for this repo includes all three host AI tools plus Bash + Node + git + PowerShell. None of this is documented in `CONTRIBUTING.md:1-116`; that file covers PR mechanics and the triplication rule, not toolchain.

---

## 14. Gap: this repo has no traditional build/test pipeline

To call out the omission explicitly (as required by this discovery's brief):

- **No CI configuration** anywhere in the tree. No `.github/workflows/`, no GitLab, Jenkins, CircleCI, Azure Pipelines configs.
- **No test runner config**. No `jest.config.*`, `pytest.ini`, `vitest`, `mocha`, `tap`, `karma`, `playwright.config`, `cypress.json`. No `__tests__/` directory. No `tests/` directory.
- **No lint config**. No `.shellcheckrc`, `.markdownlint.*`, `.eslintrc.*`, `.stylelintrc.*`, `.editorconfig`, `.prettierrc.*`.
- **No pre-commit / pre-push hooks** (no `.husky/`, no `.pre-commit-config.yaml`, no `lefthook.yml`).
- **No structural parity test** verifying the cross-tree duplication is complete (every skill / agent / template exists in all three install trees with no drift).

The only quality-gating mechanism that exists in this repo is the suite of **runtime validation scripts under `canonical/templates/knowledge-summary/scripts/`** (`validate-diagrams.mjs`, `validate-html.sh`, `validate-links.sh`, `contrast-check.mjs`, `check-preflight.sh`, `stale-check.sh`). These are invoked from inside the `aid-summarize` skill at runtime against a *user's* KB — not against this repository's own correctness.

The closest thing to a "test of this repo" is the current dogfood discovery: if `/aid-discover` cannot complete a clean pass on the methodology repo itself, that is a structural regression. **Resolution per STATE.md Q12:** adopt the dogfood discovery as a CI smoke test alongside unit tests on `grade.sh` and `build-project-index.sh` (pure Bash, easy to fixture). Tracked in `tech-debt.md`.

---

## 15. Cross-references

- File counts and language breakdown: `project-index.md ## Language Breakdown` (line 17-27).
- Triplication math (why every script appears four times): `project-structure.md ## Per-Tool Installation Trees` (line 58-72).
- Anomalies (double-dot settings file, missing templates, `aid-correct` stub): `project-structure.md ## Anomalies and Things to Flag` (line 252-263).
- Vendor docs not yet fetched (Claude Code, Codex, Cursor, Copilot, Antigravity): `external-sources.md` (full document).
- Distribution / versioning / CI / cross-tree-sync open questions: `STATE.md` Q1 (SemVer + VERSION file — user-confirmed), Q2 (git-clone + tagged releases — user-confirmed), Q3 (propagation script + CI drift-check — auto-resolved), Q4 (minimal CI workflow — auto-resolved).
- HTML viewer specifics: `ui-architecture.md`.
