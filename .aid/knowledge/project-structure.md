# Project Structure

> **Source:** aid-discover (discovery-scout) — cycle-11 FIX
> **Status:** Refreshed post-work-002 (canonical-generator) + work-003 (heartbeats + area-STATE)
> **Last Updated:** 2026-05-23

> Source of truth for file inventory: `.aid/knowledge/project-index.md` (regenerated 2026-05-23: 631 files, 90,011 lines).

## What This Repository Is

This repository IS the AID methodology — it is not a deployable application. It ships:

1. A canonical methodology document (`methodology/aid-methodology.md`, 1,071 lines, V3 spec).
2. A **canonical source tree** (`canonical/`) — the single authority for skills, agents, rules, and templates. All three install payloads are **generated** from it.
3. A **canonical-to-profile generator** (`run_generator.py` at the repo root, 82 lines) — runs the per-profile renderers and propagates `canonical/` into each install tree per its profile spec.
4. Three **install payloads** (`profiles/claude-code/`, `profiles/codex/`, `profiles/cursor/`) — one per supported AI coding tool — **generated, not hand-maintained**. Each contains agents, skills, templates, and (for Cursor) rules in that tool native format, plus an `emission-manifest.jsonl` recording what the generator emitted.
5. Three **profile spec TOMLs** (`profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml`) — declarative descriptions of each host tool filename conventions, frontmatter rules, model tier mapping, and capability matrix. These are the generator per-tool input.
6. Cross-platform installer scripts (`setup.sh`, `setup.ps1`) that copy the relevant generated tree into a target project. (Generator and installer are separate concerns: the generator builds the install payloads inside this repo; the installer copies a payload into a downstream project.)
7. Anonymized real-world examples (`examples/`).

The dogfood pattern: this repo own `.aid/knowledge/` is being populated by running AID own discovery pipeline against itself. The KB taxonomy on disk (per DISCOVERY-STATE Q102): **16 standard KB documents** (architecture, module-map, technology-stack, coding-standards, data-model, api-contracts, integration-map, domain-glossary, test-landscape, security-model, tech-debt, infrastructure, ui-architecture, feature-inventory, project-structure, external-sources) + **2 meta-documents** (INDEX.md, README.md) + **1 consolidated area-STATE file** (`STATE.md`, replacing the pre-FR2 `DISCOVERY-STATE.md`/`SUMMARY-STATE.md` split per work-003 feature-002) + **1 generated pre-pass** (`project-index.md`, emitted by `canonical/templates/scripts/build-project-index.sh`) + **1 KB extension** (`host-tools-matrix.md`, project-type-specific, outside the standard 16). Total: 21 files in `.aid/knowledge/`.

## Top-Level Layout

| Path | Purpose |
|------|---------|
| `canonical/` | **Single source of truth** for skills, agents, rules, and templates. Subdirs: `agents/` (22 agent folders), `skills/` (10 aid-* folders), `rules/` (2 `.mdc` files for Cursor — `aid-methodology.mdc`, `aid-review.mdc`), `templates/` (KB templates, requirements, specs, delivery-plans, feedback-artifacts, knowledge-summary, scripts, root-level templates). Also contains `EMISSION-MANIFEST.md` — design spec for the per-profile manifest format. |
| `profiles/` | **Generated** per-tool install payloads (three trees) plus their profile spec TOMLs. Contents: `claude-code/`, `codex/`, `cursor/` (the generated install trees, each with its own `emission-manifest.jsonl` and a `README.md`) + `claude-code.toml`, `codex.toml`, `cursor.toml` (the profile spec inputs). |
| `run_generator.py` | Top-level orchestrator (82 lines). Iterates every `profiles/*.toml`, loads the profile, runs `render_agents` / `render_skills` / `render_templates` (sourced from `.claude/skills/aid-generate/scripts/`), diffs against the previous emission manifest to compute deletions, writes the new manifest, then runs `verify_deterministic` (VERIFY-4a) and `verify_advisory` (VERIFY-4b). |
| `methodology/` | Authoritative AID V3 methodology document (`aid-methodology.md`, 1,071 lines) plus the four pipeline diagrams under `methodology/images/`. |
| `examples/` | Three anonymized case studies: `brownfield-enterprise/` (Java/OSGi monorepo), `desktop-app/` (.NET/Avalonia/MVVM), `data-pipeline/` (multi-brand e-commerce analytics). |
| `docs/` | `faq.md` and `glossary.md` — short reference docs aimed at adopters. |
| `.claude/` | This repo own Claude Code workspace. Contains the maintainer-only `aid-generate` skill (`skills/aid-generate/` — drives `run_generator.py`), per-conversation worktree state (`worktrees/` — gitignored), the regular `agents/` + `skills/` + `templates/` working copies, plus `settings.json` (committed permission allow-list) and `settings.local.json` (gitignored local overrides). **Do not confuse with the install payload under `profiles/claude-code/.claude/`.** |
| `.aid/` | This repo own dogfooded discovery output and work-tracking. Gitignored only at the cache level (`.aid/knowledge/.cache/`); the rest is committed. |
| `setup.sh` | Bash installer (162 lines). Interactive menu selects one or more of Claude Code / Codex / Cursor; copies the **already-generated** matching `profiles/<tool>/` tree into a target project; safe re-run (skip identical, prompt different, `--force` to overwrite). |
| `setup.ps1` | PowerShell port of `setup.sh` (157 lines) with identical semantics. |
| `README.md` | Project overview, quick start, phase/agent tables, repository structure diagram. |
| `CONTRIBUTING.md` | Contribution rules. **Post-canonical-generator, the "update all three trees" discipline is enforced by `run_generator.py`, not by manual quadruplication.** Contributors edit `canonical/` and re-run the generator; never edit `profiles/*/` directly. |
| `CLAUDE.md` | This repo own Claude Code project config (dogfood). The installer ships a separate template at `profiles/claude-code/CLAUDE.md`. |
| `LICENSE` | MIT (21 lines). |
| `.gitignore` | Python/Node/IDE/editor artifacts, `.aid/knowledge/.cache/`, `.claude/worktrees/`, `.claude/settings.local.json`. (No longer the single-line `.aid/` from the pre-work-003 era.) |

**Important deletions reflected here (cycle-11 verification):**
- The top-level `skills/` and `agents/` directories that earlier KB revisions described as "the canonical human-readable tree" **no longer exist**. They have been collapsed into `canonical/skills/` and `canonical/agents/`, and the per-tool install trees are now generator output rather than parallel hand-maintained copies. Confirmed via `ls C:/Projects/Personal/AID/skills/` returning "No such file or directory" (cycle-11 spot-check #3, #4).
- The top-level `templates/` directory of older KB revisions is now `canonical/templates/`. The previous "four-way duplication" between root `templates/` and three install trees no longer applies — `canonical/templates/` is the single source; the three `profiles/*/templates/` directories are generated mirrors.

## Key Files

| File | Purpose |
|------|---------|
| `methodology/aid-methodology.md` | The complete V3 methodology spec (1,071 lines). The single normative document; everything else is derived from this. |
| `run_generator.py` | 82-line Python orchestrator (top level). The only entry point for propagating canonical edits into all three install trees. Calls per-renderer modules from `.claude/skills/aid-generate/scripts/` and writes `profiles/<tool>/emission-manifest.jsonl` after each render. |
| `canonical/EMISSION-MANIFEST.md` | Design spec for the per-profile emission manifest (JSONL format, sha256 records, pure-mirror deletion semantics). Defines the generator safety boundary — only files the generator emitted can be deleted on subsequent runs. |
| `profiles/claude-code.toml` / `codex.toml` / `cursor.toml` | Per-tool profile specs: layout roots, agent/skill frontmatter rules, model tier mapping, tool-name remap (Cursor: `Bash` to `Terminal`), filename remap (e.g. `reviewer_output_file = "STATE.md"` post-FR2), capability matrix (hooks / skill_chaining / background_execution / stop_hook_autocontinue). |
| `setup.sh` / `setup.ps1` | Tool installers (162 / 157 lines). Identical menu, identical copy semantics, identical "Next steps" message. They copy from `profiles/<tool>/` into a downstream project — they do **not** invoke the generator. |
| `canonical/templates/scripts/build-project-index.sh` | 368-line Bash that emits `.aid/knowledge/project-index.md` — the file inventory consumed by every discovery sub-agent. Run as a Step 0c pre-pass by `aid-discover` so the 5 sub-agents do not each re-glob the tree. |
| `canonical/templates/scripts/grade.sh` | 141-line Bash that computes A+/A/B/C/D/F grades deterministically from a Reviewer structured issue list. Same input, same grade. |
| `canonical/templates/scripts/verify-kb-claims.sh` | Cross-check script: validates that file paths and line counts cited in the KB still match disk reality. Used during /aid-discover REVIEW cycles. |
| `canonical/templates/knowledge-summary/scripts/grade.sh` | Variant used by `aid-summarize` for HTML quality gating. |
| `canonical/templates/knowledge-summary/scripts/writeback-state.sh` | 173-line Bash that appends summarize-cycle entries to `.aid/knowledge/STATE.md` (renamed from `writeback-discovery-state.sh` post-FR2; the older name is still cited by some KB docs — see tech-debt). |
| `canonical/templates/knowledge-base/INDEX.md` | The canonical KB index template — drives the layout of `.aid/knowledge/INDEX.md`. |
| `README.md` | Quick start, phase table, agent table, repo structure ASCII tree. |
| `CONTRIBUTING.md` | Contribution rules. Post-canonical-generator: edit `canonical/`, re-run `python run_generator.py`, commit both canonical and generated changes. The previous manual "update all 3 install trees" rule is obsolete. |

## Generator + Profile Architecture (replaces the pre-2026-05-22 Triplication Pattern)

The repository contains **one canonical tree** plus **three generated install payloads**:

| Tree | Role | Hand-maintained? | Subdirectories |
|------|------|------------------|----------------|
| `canonical/` | Source of truth | **Yes** — edit here | `agents/`, `skills/`, `rules/`, `templates/` |
| `profiles/claude-code/.claude/` | Claude Code install payload | **No** — generated | `agents/`, `skills/`, `templates/` |
| `profiles/codex/.codex/` + `profiles/codex/.agents/` | Codex CLI install payload (split layout: agents under `.codex/`, skills + templates under `.agents/`) | **No** — generated | `.codex/agents/`, `.agents/skills/`, `.agents/templates/` |
| `profiles/cursor/.cursor/` | Cursor install payload | **No** — generated | `agents/`, `skills/`, `rules/`, `templates/` |

The propagation flow:

1. Contributor edits `canonical/` (e.g., updates `canonical/skills/aid-discover/SKILL.md`).
2. Contributor runs `python run_generator.py` at the repo root.
3. The orchestrator loads each `profiles/*.toml`, runs `render_agents` / `render_skills` / `render_templates`, and writes the resulting files under that profile `output_root`.
4. The previous `profiles/<tool>/emission-manifest.jsonl` is diffed against the new render; files no longer emitted are deleted from disk, empty parent dirs are pruned.
5. A fresh manifest is written. Then `VERIFY-4a` (deterministic re-render byte-equality) and `VERIFY-4b` (advisory drift checks) run automatically.
6. All edits — canonical change + regenerated install trees + updated manifests — are committed together.

**Per-tool format translation handled by the generator:**

| Tool | Agent format | Skill format | Project config file | Tool-name remap | Extras |
|------|--------------|--------------|---------------------|-----------------|--------|
| Claude Code | `.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) | `.md` with YAML frontmatter (`name`, `description`, `allowed-tools`); optional `context:` and `agent:` hints injected per skill | `profiles/claude-code/CLAUDE.md` | Identity (Bash stays Bash) | — |
| OpenAI Codex CLI | `.toml` with `name`, `description`, `developer_instructions`, `model`, `model_reasoning_effort` (tool list inlined in `developer_instructions` prose) | `.md` with YAML frontmatter (no `context:`/`agent:`) | `profiles/codex/AGENTS.md` | Identity | Split layout: agents under `.codex/`, skills+templates under `.agents/` |
| Cursor | `.md` with YAML frontmatter (same shape as Claude Code, minus `context:`/`agent:`) | `.md` with YAML frontmatter | `profiles/cursor/AGENTS.md` | **`Bash` to `Terminal`** (the only non-identity mapping across all three profiles) | `.mdc` rule files under `rules/` (always-on methodology rules) |

**File-count parity** (cycle-11 verification): all three trees emit nearly identical file counts because they all derive from `canonical/`:
- `canonical/` — 144 files (source of truth).
- `profiles/claude-code/` — 113 files.
- `profiles/codex/` — 113 files.
- `profiles/cursor/` — 115 files (Cursor extra: 2 `.mdc` rule files).

**SKILL.md unification** (cycle-11 spot-check #1, #2): `aid-discover/SKILL.md` is **548 lines in all three profile trees AND in canonical** (verified `wc -l`). The pre-2026-05-22 drift the KB used to claim (453 / 1,078 / 1,090) no longer exists — the canonical source is the single truth and the generator copies it byte-identically into all profiles.

**Implication for contributors:** never edit anything under `profiles/`. Edit `canonical/`, re-run `python run_generator.py`, commit the canonical edit + the regenerated `profiles/` diff + the updated `emission-manifest.jsonl` files together. Drift between trees is now structurally impossible — the manifest + VERIFY-4a guarantee byte-identical re-rendering.

## Skills Inventory

Source: `canonical/skills/aid-*/SKILL.md` frontmatter `description:` field. The same skills are emitted to all three install trees by `run_generator.py` (byte-identical content; only the path layout differs per profile spec).

| Skill | Allowed tools | One-line purpose |
|-------|---------------|-------------------|
| `aid-init` | Read, Glob, Grep, Bash, Write, Edit | Initialize AID project: ask greenfield vs. brownfield, collect metadata + external doc paths, scaffold `.aid/` and KB placeholders. Run once. |
| `aid-discover` | Read, Glob, Grep, Bash, Write, Edit, Agent | Brownfield discovery with built-in quality gate. State machine GENERATE to REVIEW to Q&A to FIX to APPROVAL to DONE. Dispatches 5 discovery sub-agents in parallel. |
| `aid-interview` | Read, Glob, Grep, Bash, Write, Edit | Adaptive requirements gathering via one-question-at-a-time dialogue. First run builds `REQUIREMENTS.md`; subsequent runs cross-reference KB and decompose features. |
| `aid-specify` | Read, Glob, Grep, Bash, Write, Edit | Technical refinement per feature — agent acts as tech lead, proposes solutions, writes to per-feature `SPEC.md`. |
| `aid-plan` | Read, Glob, Grep, Write, Edit, Bash | Sequence feature SPECs into deliverables — each a functional MVP that builds on the previous. Strategy. |
| `aid-detail` | Read, Glob, Grep, Write, Edit, Bash | Break deliverables into typed tasks (RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE). One type per task. Tactics. |
| `aid-execute` | Read, Glob, Grep, Write, Edit, Bash | Type-aware task execution with built-in review loop. EXECUTE to REVIEW to FIX to DONE when grade is at or above minimum. Branch per delivery. |
| `aid-deploy` | Read, Glob, Grep, Bash, Write | Package eligible deliveries into a release; verify combined build; generate release notes; update artifact statuses. |
| `aid-monitor` | Read, Glob, Grep, Bash, Write | Observe production, classify findings, route to `aid-execute` (bugs) or `aid-discover` (CRs). Combines telemetry interpretation + triage. |
| `aid-summarize` | Read, Glob, Grep, Bash, Write, Edit | Optional. Generate single-file `knowledge-summary.html` from `.aid/knowledge/` with Mermaid diagrams, WCAG-AA, idempotent. State machine PREFLIGHT to STALE-CHECK to PROFILE to GENERATE to VALIDATE to FIX to APPROVAL to WRITEBACK to DONE. |

**`aid-correct` is fully retired.** No `aid-correct/` folder exists under `canonical/skills/` (verified `ls canonical/skills/aid-correct` returning "No such file or directory"). The earlier tombstone README that lived under the deleted top-level ~~`skills/aid-correct/` (DELETED post-work-002 cleanup)~~ is also gone with its parent directory. The phase is merged into Triage/Monitor per `methodology/aid-methodology.md`. The previous KB narrative about a "pending-deletion tombstone at `canonical/skills/aid-correct/README.md`" is obsolete — the deletion has happened.

**Skill decomposition is now uniform across all trees.** Per the profile specs (`[skill] decomposition = "references"` in all three TOMLs), every profile externalizes content into `references/` and `scripts/` subdirectories. The pre-2026-05-22 narrative that "Claude Code uses references/, Codex and Cursor inline" was wholly invalidated by work-002 — all three trees now have identical `references/` subdirs because they are byte-identical copies of `canonical/skills/`.

**Maintainer-only meta-skill** (not shipped to install trees): `.claude/skills/aid-generate/` — the skill that drives `run_generator.py`. Lives only in this repo working `.claude/` tree, not in `canonical/`, not in any profile.

## Agents Inventory

Source: `canonical/agents/*/` — 22 agent folders, each with a per-tool definition file emitted by the renderer (`.md` with YAML frontmatter for Claude Code + Cursor, `.toml` for Codex).

### Core Agents (always present, 7)

| Agent | Tier | One-line purpose |
|-------|------|-------------------|
| `orchestrator` | Sonnet | Coordinates AID pipeline — routes work, manages phase transitions with human gates, handles feedback artifacts, dispatches specialists. |
| `researcher` | Sonnet | Investigates, classifies, and synthesizes information from code, docs, logs, APIs into KB documents and analysis reports. |
| `interviewer` | Opus | Conducts adaptive one-question-at-a-time dialogue to gather requirements and produce `REQUIREMENTS.md`. |
| `architect` | Opus | Transforms requirements + KB into SPEC.md, PLAN.md, and TASK files. |
| `developer` | Sonnet | The only agent that modifies production code. Implements TASK files with mandatory build verification + IMPEDIMENT.md escalation. |
| `reviewer` | Opus | Adversarial quality evaluator. Produces structured issue list with severity + source tags. Does NOT fix; does NOT compute grade (`grade.sh` does that). |
| `operator` | Sonnet | Executes actions with external consequences — deployment, PR creation, release management, KB updates. |

### Specialist Agents (invoked ad-hoc, 6)

| Agent | Tier | Called by |
|-------|------|-----------|
| `ux-designer` | Sonnet | Architect (specify/plan), Reviewer (review). UI/UX, accessibility (WCAG), user flows. |
| `devops` | Sonnet | Operator (deploy), Researcher (infra discovery). CI/CD, IaC, containerization, monitoring. |
| `tech-writer` | Sonnet | Operator (deploy), Architect (specify). Documentation, API docs, changelogs. |
| `security` | Opus | Reviewer (review), Researcher (discover). Threat modeling, OWASP, auth, secrets, SSRF / injection / XSS, dependency audit. |
| `data-engineer` | Sonnet | Architect (plan), Developer (implement). Schema, migrations, query optimization, ETL. |
| `performance` | Sonnet | Reviewer (test), Researcher (track). Profiling, load testing, caching, optimization. |

### Discovery Sub-Agents (dispatched by `aid-discover`, 6)

| Agent | Tier | KB outputs |
|-------|------|------------|
| `discovery-architect` | Opus | `architecture.md`, `technology-stack.md`, `ui-architecture.md` |
| `discovery-analyst` | Opus | `module-map.md`, `coding-standards.md`, `data-model.md` |
| `discovery-integrator` | Opus | `api-contracts.md`, `integration-map.md`, `domain-glossary.md` |
| `discovery-quality` | Opus | `test-landscape.md`, `security-model.md`, `tech-debt.md` |
| `discovery-scout` | Opus | `project-structure.md`, `external-sources.md` enrichment, Q&A seeded directly in `STATE.md` (consolidated per Q102 / Q115 + FR2 area-STATE rule — the older `DISCOVERY-STATE.md` and `additional-info.md` references are obsolete) |
| `discovery-reviewer` | Opus | `STATE.md` (cross-references claims against source code, grades the KB) |

### Utility Sub-Agents (Haiku tier, called by full agents only — never invoked at the skill layer, 3)

| Agent | Tier | Purpose |
|-------|------|---------|
| `simple-extractor` | Haiku | Mechanical extraction of structured items from source files with file path + line number per item. |
| `simple-formatter` | Haiku | Fills markdown templates with structured input. |
| `simple-glob` | Haiku | Enumerates files matching glob patterns with size + mtime metadata. |

Each utility agent is explicitly marked `INTERNAL UTILITY (sub-agent only — do NOT invoke from a skill)` in its description.

## Templates

All templates live under `canonical/templates/` and are propagated to each profile `templates/` subdirectory by the generator.

### `canonical/templates/knowledge-base/` (KB document templates, consumed by Discovery)

**18 files** at `canonical/templates/knowledge-base/` (verified `ls`): **16 standard KB-doc templates** (`api-contracts.md`, `architecture.md`, `coding-standards.md`, `data-model.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `project-structure.md`, `security-model.md`, `tech-debt.md`, `technology-stack.md`, `test-landscape.md`, `ui-architecture.md`) + **2 meta-doc templates** (`INDEX.md`, `README.md`). The 16th standard KB template `ui-architecture.md` is now present at the canonical root (the earlier "only in install trees" anomaly was resolved by work-002). The KB `README.md` and `INDEX.md` templates here drive the layout `aid-init` writes to `.aid/knowledge/README.md` and `.aid/knowledge/INDEX.md`.

### `canonical/templates/requirements/`, `canonical/templates/specs/`, `canonical/templates/delivery-plans/`

- `requirements/requirements-template.md` — REQUIREMENTS.md template.
- `specs/spec-template.md` — per-feature SPEC.md (requirements + tech spec).
- `delivery-plans/task-template.md` — individual `task-NNN.md` (the only file in `delivery-plans/`). PLAN.md has no template — its format is defined inline by `aid-plan`.

### `canonical/templates/feedback-artifacts/`

- `IMPEDIMENT.md` — implementation blocker requiring spec/plan revision. The only file in `feedback-artifacts/`.

### `canonical/templates/knowledge-summary/` (`aid-summarize` assets)

Eleven top-level files (`accessibility-checklist.md`, `component-css.css`, `design-tokens.md`, `grading-rubric.md`, `html-skeleton.html`, `lightbox.js`, `mermaid-examples.md`, `mermaid-init.js`, `prompt.md`) plus `scripts/` (13 scripts including `check-preflight.sh`, `stale-check.sh`, `validate-html.sh`, `validate-links.sh`, `fetch-mermaid.sh`, `contrast-check.mjs`, `validate-diagrams.mjs`, `manual-checklist.sh`, `spot-check-facts.sh`, `grade.sh`, `writeback-state.sh`, `concatenate.sh`, `concatenate.ps1`) and `section-templates/` (6 profile-specific section templates: `auto-detect.md`, `cli.md`, `data-pipeline.md`, `library.md`, `microservices.md`, `web-app.md`).

### `canonical/templates/scripts/`

- `build-project-index.sh` (368 lines, Bash) — pre-pass for `aid-discover`.
- `grade.sh` (141 lines, Bash) — deterministic grading.
- `verify-kb-claims.sh` — KB claim verification (file existence + line counts).

### `canonical/templates/` root

- `discovery-state-template.md` — STATE.md skeleton (template still uses the pre-FR2 name; the resulting file written by `aid-init` is named `STATE.md` per the profile filename remap).
- `feature.md`, `feature-inventory.md`, `known-issues.md`, `package.md`, `requirements.md`, `ui-architecture.md` — root-level templates lifted from install trees by the Q190 cycle-11 fix (previously install-tree-only orphans).
- `grading-rubric.md`, `rough-time-hints.md`, `work-state-template.md`, `README.md` — additional root-level templates and template index.

## Methodology and Docs

| File | Lines | Purpose |
|------|-------|---------|
| `methodology/aid-methodology.md` | 1,071 | The full V3 methodology spec. |
| `methodology/images/1-pipeline.png` | (image) | Pipeline diagram. |
| `methodology/images/2-comparison.png` | (image) | AID vs. SDD comparison diagram. |
| `methodology/images/3-ironman.png` | (image) | Human-as-pilot / AI-as-Iron-Man-suit collaboration diagram. |
| `methodology/images/4-feedback-loops.png` | (image) | The 11 formal feedback loops diagram. |
| `docs/faq.md` | 61 | Adopter FAQ. Mentions tool-agnosticism (Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, Aider). |
| `docs/glossary.md` | 80 | Terminology reference. |

## Examples

| Example | Files | Scenario |
|---------|-------|----------|
| `examples/brownfield-enterprise/` | `README.md`, `discovery-report.md`, `knowledge-base/architecture.md` | 21 GB Java/OSGi monorepo, no docs, three-day discovery. |
| `examples/desktop-app/` | `README.md`, `delivery-plan.md`, `task-spec.md` | .NET / Avalonia / MVVM transcription app, 0 to 1,100+ tests across 6 deliveries. |
| `examples/data-pipeline/` | `README.md`, `pipeline-architecture.md` | Multi-brand e-commerce analytics, 12 specialist agents, 5 data sources, 1 percent tolerance. |

## Detected Languages and Frameworks

From the regenerated `project-index.md` Language Breakdown (2026-05-23):

| Language | Files | Lines | Purpose in this repo |
|----------|-------|-------|----------------------|
| Markdown | 472 | 59,201 | Methodology, READMEs, SKILL bodies, agent definitions (Claude Code + Cursor), templates. The vast bulk of the repo. |
| Shell | 76 | 13,957 | `setup.sh`, generator scripts under `.claude/skills/aid-generate/scripts/`, `canonical/templates/scripts/`, knowledge-summary validation scripts. |
| (Other languages — JavaScript / CSS / TOML / HTML / PowerShell / JSON / Python) follow in the regenerated index. |

**No application framework signals.** There is no `package.json`, no `requirements.txt`, no `Cargo.toml`, no `pom.xml`, no `go.mod`, no `*.csproj`, no `Dockerfile`, no Kubernetes manifests, no Terraform / CDK / Pulumi files anywhere in the tree. The single Python file is the top-level `run_generator.py` (82 lines, stdlib-only — no `requirements.txt` because the generator depends only on Python stdlib + modules sourced from `.claude/skills/aid-generate/scripts/`). This repo is fundamentally a static set of markdown + shell + one Python orchestrator + a few JS files — not a deployable application.

## Build / Test / CI

- **No top-level package manifest.** No `Makefile`. No `build.sh` or `test.sh` at the root.
- **No CI configuration found.** No `.github/workflows/`, no `.gitlab-ci.yml`, no `.circleci/`, no Jenkinsfile, no `azure-pipelines.yml`.
- **The closest thing to "build"** is `python run_generator.py` — regenerates all three install trees from `canonical/`. This runs `VERIFY-4a` (deterministic re-render) and `VERIFY-4b` (advisory) automatically. Manual invocation only — there is no commit hook, no CI trigger.
- **Existing executable scripts** are limited to:
  - `setup.sh` / `setup.ps1` — installer (not tests).
  - `run_generator.py` — canonical-to-profile propagator (runs `verify_deterministic` and `verify_advisory` internally).
  - `canonical/templates/scripts/build-project-index.sh` — runtime pre-pass for `aid-discover`.
  - `canonical/templates/scripts/grade.sh` — runtime grading.
  - `canonical/templates/scripts/verify-kb-claims.sh` — runtime KB-claim verification (used during /aid-discover REVIEW).
  - `canonical/templates/knowledge-summary/scripts/*` — runtime validation for `aid-summarize` output (`validate-diagrams.mjs`, `validate-html.sh`, `validate-links.sh`, `contrast-check.mjs`, `check-preflight.sh`, `stale-check.sh`, `fetch-mermaid.sh`, `writeback-state.sh`, `manual-checklist.sh`, `spot-check-facts.sh`).
- **No test runner config** (`jest.config`, `pytest.ini`, `vitest`, `mocha`, etc.).

## File Counts per Major Directory (cycle-11 verification)

| Directory | File count |
|-----------|------------|
| `canonical/` | 144 (source of truth: 22 agents + 10 skills + 2 rules + ~50 templates + scripts + EMISSION-MANIFEST.md) |
| `profiles/claude-code/` | 113 (generated install tree + manifest + README + CLAUDE.md) |
| `profiles/codex/` | 113 (generated install tree, split layout, + manifest + README + AGENTS.md) |
| `profiles/cursor/` | 115 (generated install tree + 2 .mdc rules + manifest + README + AGENTS.md) |
| `examples/` | 9 |
| `docs/` | 2 |
| `methodology/` | 5 (1 markdown + 4 images) |
| Root | 9 (`README.md`, `CONTRIBUTING.md`, `LICENSE`, `CLAUDE.md`, `setup.sh`, `setup.ps1`, `run_generator.py`, `.gitignore`, plus the 3 `profiles/*.toml` spec files) |

Total per the regenerated `project-index.md`: 631 files, 90,011 lines.

## Anomalies and Things to Flag

1. **One canonical tree, three generated profiles, no manual cross-tree sync needed.** Replaces the pre-2026-05-22 "triplicated install payloads with no propagation tooling" anomaly. The new safety boundary is the per-profile `emission-manifest.jsonl` plus `VERIFY-4a` byte-equality re-render check.
2. **Stray dotfile (still present):** `.claude/settings.local.json` is gitignored; `.claude/settings.json` is the committed permission allow-list. No double-dot typo anymore (the old `settings..json` was cleaned up).
3. **No CI, no manifest, no version file.** Nothing in the repo declares the AID version number programmatically. README and methodology document refer to "V3" but there is no `VERSION` file, no git tag visible in this worktree, no GitHub release artifact tracked in-repo.
4. **`.aid/` is partially committed.** Only `.aid/knowledge/.cache/`, `.claude/worktrees/`, and `.claude/settings.local.json` are gitignored. The rest of `.aid/` (the KB itself + work-tracking) is tracked. This is a change from the pre-work-003 single-line `.aid/` gitignore.
5. **Codex retains its split layout** (`.codex/` for agents, `.agents/` for skills + templates) — different from Claude Code (everything under `.claude/`) and Cursor (everything under `.cursor/`). The generator handles this via `agents_root` + `assets_root` in `profiles/codex.toml`; the single `profiles/codex/emission-manifest.jsonl` covers both roots.
6. **`aid-correct` is fully retired.** No directory exists at `canonical/skills/aid-correct` or in any install tree. The earlier tombstone README pending-deletion narrative is resolved.
7. **Skill body parity** (replaces "skill body length drift" anomaly): `aid-discover/SKILL.md` is 596 lines in **all four locations** — `canonical/skills/aid-discover/`, `profiles/claude-code/.claude/skills/aid-discover/`, `profiles/codex/.agents/skills/aid-discover/`, `profiles/cursor/.cursor/skills/aid-discover/` — verified `wc -l` (cycle-11 spot-checks #1, #2). The pre-2026-05-22 KB claim of 453 / 1,078 / 1,090 divergence is obsolete.
8. **`canonical/templates/README.md` still references retired files.** Reference to `reports/discovery-state-template.md` is stale — the actual location is `canonical/templates/discovery-state-template.md` (root-level); there is no `reports/` subdirectory under `canonical/templates/`. Likely template-README drift that should be fixed in a future pass.
9. **GitHub Copilot and Google Antigravity** are mentioned in `README.md`, `CONTRIBUTING.md`, and `docs/faq.md` as supported / future-supported tools, but there is no profile spec TOML for either, and no install tree. Cursor was the most recent addition.
10. **No `.aid/.cache/` exists yet** — the gitignore line `.aid/knowledge/.cache/` is forward-looking; the cache only materializes when `aid-summarize` runs.
