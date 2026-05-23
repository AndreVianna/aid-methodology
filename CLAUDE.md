# AID

<!-- AID-DISCOVER project-description -->
AI-Integrated Development methodology — structured AI-assisted software lifecycle from discovery to production monitoring.
<!-- /AID-DISCOVER -->

## Project Overview
<!-- AID-DISCOVER project-overview -->
This repository **is** the AID methodology — not a deployable application. It ships:

1. The canonical methodology document (`methodology/aid-methodology.md`, V3 spec).
2. Three **install payloads** — one per supported AI coding tool — each containing agents, skills, templates, and scripts in that tool's native format:
   - `profiles/claude-code/.claude/` for Anthropic Claude Code.
   - `profiles/codex/.codex/` (agent TOMLs) + `profiles/codex/.agents/` (skills + templates) for OpenAI Codex CLI.
   - `profiles/cursor/.cursor/` for Cursor.
3. Human-readable reference docs (`skills/`, `agents/`) describing each phase and agent role.
4. Source-of-truth templates (`templates/`) consumed by installers and by the skills at runtime.
5. Cross-platform installers: `setup.sh` (Bash, 161 lines) and `setup.ps1` (PowerShell 5.1+, 156 lines).
6. Anonymized real-world examples (`examples/brownfield-enterprise/`, `desktop-app/`, `data-pipeline/`).

GitHub Copilot CLI and Google Antigravity are listed as future targets but have no install tree today.
See `.aid/knowledge/project-structure.md` for the full layout and `.aid/knowledge/feature-inventory.md` once Q-FEATURES is answered.
<!-- /AID-DISCOVER -->

## Build & Test
<!-- AID-DISCOVER build-test -->
**No traditional build, no CI, no test runner.** This is a methodology + assets repo; distribution is `git clone` only.

- **Install into a project:**
  - Bash: `./setup.sh /path/to/your/project` (interactive menu; `--force` skips prompts).
  - PowerShell: `.\setup.ps1 C:\path\to\your\project [-Force]`.
- **Re-run is safe:** identical files are skipped, changed files prompt before overwriting.
- **Dogfood:** `/aid-init` then `/aid-discover` in this repo regenerates `.aid/knowledge/`. The KB is gitignored (`.gitignore` contains only `.aid/`).
- **Runtime validation scripts** (used by `aid-summarize`, not by this repo's CI):
  - `templates/knowledge-summary/scripts/validate-html.sh`
  - `templates/knowledge-summary/scripts/validate-links.sh`
  - `templates/knowledge-summary/scripts/validate-diagrams.mjs` (needs Node 18+ and optionally `@mermaid-js/mermaid-cli`)
  - `templates/knowledge-summary/scripts/contrast-check.mjs`
  - `templates/scripts/grade.sh` (deterministic A+ … F grade from a Reviewer issue list)
- **Gaps:** no `.github/workflows/`, no `VERSION` file, no tags from this worktree, no linter config. See `.aid/knowledge/tech-debt.md` items H2 and H3, and DISCOVERY-STATE Q1, Q4, Q70.

Runtime deps on the user's machine (per tool selected): Claude Code / Codex CLI / Cursor IDE; Bash (or git-bash on Windows); PowerShell 5.1+ for `setup.ps1`; Node 18+ optional; `@mermaid-js/mermaid-cli` optional.
<!-- /AID-DISCOVER -->

## Code Conventions
<!-- AID-DISCOVER code-conventions -->
Pulled from actual files — not from a style guide (there isn't one). See `.aid/knowledge/coding-standards.md` for the full inventory.

- **Filenames:** kebab-case for skill / agent slugs (`aid-discover`, never `aid_discover`); `SCREAMING-KEBAB-CASE.md` for state files (`DISCOVERY-STATE.md`, `MONITOR-STATE.md`); UPPERCASE.md for top-level methodology artifacts (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `CLAUDE.md`, `AGENTS.md`).
- **Per-tool tree paths:** `profiles/claude-code/.claude/{agents,skills,templates}/`, `profiles/codex/.codex/agents/` + `profiles/codex/.agents/{skills,templates}/`, `profiles/cursor/.cursor/{agents,rules,skills,templates}/`.
- **SKILL.md frontmatter** (all three trees): `name`, `description` (YAML folded `>`), `allowed-tools` (comma-separated string, not YAML list), optional `argument-hint`. Claude Code may add `context: fork` and `agent: <name>`; Codex / Cursor omit them.
- **Agent frontmatter:**
  - Claude Code (markdown): `name`, `description`, `tools` (comma-separated), `model` (`opus` / `sonnet` / `haiku`), optional `permissionMode: bypassPermissions`, optional `background: true`.
  - Codex (TOML): `name`, `description`, `model` (`gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini`), `model_reasoning_effort` (`high` / `medium` / `low`), `developer_instructions = """ ... """`.
  - Cursor (markdown): same shape as Claude Code; note `tools: ... Terminal` instead of `Bash` (Q52).
- **Cursor `.mdc` rules:** `description`, `globs` (required when `alwaysApply: false`), `alwaysApply: true|false`.
- **KB documents** open with a `> **Source:** / > **Status:** / > **Last Updated:**` blockquote metadata header.
- **Templates** use single-curly-brace placeholders (`{Project Name}`, `{date}`) and pipe-separated enums (`{✅ | ⚠️ | ❌}`).
- **Shell scripts:** `#!/usr/bin/env bash`, `set -euo pipefail`, comment-block header, long-flag `case` parsing, `-h|--help` echoes the comment block.
- **Cross-tree updates** (`CONTRIBUTING.md:21-26`): any change to a skill / agent body must be applied to the human README plus **all three install trees** — actually a **quadruplicate** rule (the CONTRIBUTING text omits Cursor — flagged as Q34 / Q72). No automation enforces this.
- **Conventions NOT enforced:** no linter, no schema validation, no triplication-drift checker, no spell-check, no markdown lint. See `.aid/knowledge/coding-standards.md §10` and DISCOVERY-STATE Q35.
<!-- /AID-DISCOVER -->

## Architecture
<!-- AID-DISCOVER architecture -->
Two-level architecture. Full detail in `.aid/knowledge/architecture.md`.

**Level 1 — The AID pipeline** (the methodology itself): **10 SKILL files** = 1 setup phase (Init) + 8 development phases (Discover, Interview, Specify, Plan, Detail, Execute, Deploy, Monitor) + 1 optional phase (Summarize). Canonical taxonomy per user-confirmed DISCOVERY-STATE Q16. `aid-verify` is folded into Execute's review loop and Deploy's final-verification step. `aid-correct` is a tombstone (merged into Triage/Monitor, pending deletion). Phases dispatch specialized **agents** (7 Core + 6 Specialist + 3 Utility + 6 Discovery sub-agents = 22 total per install tree) and produce **artifacts** (REQUIREMENTS, KB, SPEC, DETAIL, TASKs, DELIVERY, *-STATE files). The Knowledge Base is the gravitational center — every phase reads it, every phase may revise it via formal feedback loops.

**Level 2 — The repository that delivers it:** four parallel locations hold the same skills + agents + templates (the human canonical `skills/` / `agents/` / `templates/` plus three per-tool install trees). The `setup.sh` / `setup.ps1` installer copies the chosen tree into the user's project.

**Eight patterns identified in this repo** (`architecture.md §4`):

1. **Skills as state-machine orchestrators** — every skill runs one step per invocation, persists state to disk, and exits. Filesystem is the only source of truth (`aid-discover/SKILL.md:42-43`).
2. **Sub-agent dispatch (orchestrator-worker)** — orchestrator skill dispatches multiple specialized sub-agents in parallel; a separate reviewer runs later with clean context.
3. **Reference-file decomposition (Claude Code only)** — Claude Code skills externalize content into `references/` and `scripts/` subdirs; Codex / Cursor inline. Cause of the 453-vs-1,078-vs-1,090-line drift in `aid-discover/SKILL.md` (Q73).
4. **Knowledge Base as gravitational center** — fixed-shape `.aid/knowledge/` with 16 standard KB documents + 3 meta-docs (INDEX, README, DISCOVERY-STATE) + 1 generated pre-pass (project-index) + extensions outside the standard 16 (currently `host-tools-matrix`) per the Q102 canonical taxonomy; INDEX.md fed to every task as RAG-by-convention.
5. **Spec-as-hypothesis with formal revision** — every artifact template has `## Revision History`; feedback loops produce Q&A entries in STATE files and IMPEDIMENT files; Reviewer tags issues by source `[CODE]/[TASK]/[SPEC]/[KB]/[ARCHITECTURE]`.
6. **Deterministic grading** — Reviewer NEVER assigns letter grades; produces severity-tagged issue list; `templates/scripts/grade.sh` computes the grade from the rubric. Reviewer ≠ Executor invariant.
7. **Triplicated install payloads** — manual cross-tree sync, no propagation tooling; ~36% of repo lines are 4-way duplicated.
8. **Three-tier agent model** — Small / Medium / Large capability tiers, provider-agnostic (Anthropic: Claude Haiku / Sonnet / Opus; OpenAI: `gpt-5.4-mini` / `gpt-5.4` / `gpt-5.5`). All 22 agents are tier-consistent across all 3 trees.

**Entry points:** `setup.sh` / `setup.ps1` for installation, then per-tool slash commands (`/aid-init`, `/aid-discover`, …) once installed.
**External integration surface:** none at runtime; integration is with the host AI coding tool. See `.aid/knowledge/integration-map.md`.
<!-- /AID-DISCOVER -->

## AID Workspace

The `.aid/` directory contains the Knowledge Base and work artifacts.
Read `.aid/knowledge/INDEX.md` to find what you need.
