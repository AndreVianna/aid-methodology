# Project Structure

> **Source:** aid-discover (discovery-scout)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21

> Source of truth for file inventory: `.aid/knowledge/project-index.md` (353 files, 49,226 lines).

## What This Repository Is

This repository IS the AID methodology — it is not a deployable application. It ships:

1. A canonical methodology document (`methodology/aid-methodology.md`, 1,158 lines, V3 spec).
2. Three **install payloads** — one per supported AI coding tool (Claude Code, OpenAI Codex CLI, Cursor) — each containing agents, skills, templates, and scripts in that tool's native format.
3. Human-readable reference docs (`skills/`, `agents/`) describing each phase and agent role without LLM-format optimization.
4. Source-of-truth templates (`templates/`) consumed by the installers and by the AID skills themselves at runtime.
5. Cross-platform installer scripts (`setup.sh`, `setup.ps1`) that copy the relevant tool tree into a target project.
6. Anonymized real-world examples (`examples/`).

The dogfood pattern: this repo's own `.aid/knowledge/` is being populated by running AID's own discovery pipeline against itself. The KB taxonomy on disk (per DISCOVERY-STATE Q102): **16 standard KB documents** (architecture, module-map, technology-stack, coding-standards, data-model, api-contracts, integration-map, domain-glossary, test-landscape, security-model, tech-debt, infrastructure, ui-architecture, feature-inventory, project-structure, external-sources) + **3 meta-documents** (INDEX.md, README.md, DISCOVERY-STATE.md) + **1 generated pre-pass** (`project-index.md`, emitted by `templates/scripts/build-project-index.sh`) + **1 KB extension** (`host-tools-matrix.md`, project-type-specific, outside the standard 16). Total: 21 files in `.aid/knowledge/`.

## Top-Level Layout

| Path | Purpose |
|------|---------|
| `methodology/` | Authoritative AID V3 methodology document plus the four pipeline diagrams. |
| `skills/` | Human-readable per-skill READMEs. Verified count: **9 phase folders** (`aid-correct`, `aid-deploy`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-interview`, `aid-monitor`, `aid-plan`, `aid-specify`) + top-level `README.md` = 10 entries. `aid-correct` is a **confirmed tombstone** (deprecation notice, phase merged into Triage/Monitor per `methodology/aid-methodology.md:889`; pending deletion per DISCOVERY-STATE Q6). `aid-init` and `aid-summarize` are intentionally absent from `skills/` — they live only in the install trees (per `skills/README.md:11-17,48-51`). |
| `agents/` | Human-readable per-agent READMEs. Verified count: **16 agent folders** + top-level `README.md` = 17 entries. Covers Core (7), Specialist (6), Utility (3). The 6 Discovery sub-agents (architect, analyst, integrator, quality, scout, reviewer) currently have NO individual READMEs under `agents/` — only inline rows in `agents/README.md:122-131` and full definitions in the install trees. Pending authoring per DISCOVERY-STATE Q18. |
| `claude-code/` | **Install payload** for Claude Code. Contains `.claude/` (agents, skills, templates) and a `CLAUDE.md` placeholder. |
| `codex/` | **Install payload** for OpenAI Codex CLI. Split into `.codex/agents/` (TOML agent defs) and `.agents/{skills,templates}/` (shared markdown skills/templates) plus an `AGENTS.md` placeholder. |
| `cursor/` | **Install payload** for Cursor. Contains `.cursor/{agents,rules,skills,templates}/` and an `AGENTS.md` placeholder. |
| `templates/` | Source-of-truth templates: KB documents, requirements, specs, delivery plans, feedback artifacts, reports, knowledge-summary assets, and shell scripts (`grade.sh`, `build-project-index.sh`). These are also copied into each tool's install tree. |
| `examples/` | Three anonymized case studies: brownfield-enterprise (Java/OSGi monorepo), desktop-app (.NET/Avalonia/MVVM), data-pipeline (multi-agent e-commerce analytics). |
| `docs/` | `faq.md` and `glossary.md` — short reference docs aimed at adopters. |
| `.claude/` | This repo's own Claude Code settings (`settings.json`, `settings..json`) — narrow permission allow-lists used during dogfooded discovery. Do not confuse with the install payload under `profiles/claude-code/.claude/`. |
| `.aid/` | This repo's own discovery output. Gitignored (`.gitignore` contains only `.aid/`). |
| `setup.sh` | Bash installer. Interactive menu selects one or more of Claude Code / Codex / Cursor; copies the matching tree into a target project; safe re-run (skip identical, prompt different, `--force` to overwrite). |
| `setup.ps1` | PowerShell port of `setup.sh` with identical semantics. |
| `README.md` | Project overview, quick start, phase/agent tables, repository structure diagram. |
| `CONTRIBUTING.md` | "Update all three trees" rule, anonymization rules, what is accepted and rejected. |
| `CLAUDE.md` | This repo's own Claude Code project config (dogfood). The installer ships a separate template at `profiles/claude-code/CLAUDE.md`. |
| `LICENSE` | MIT (21 lines). |
| `.gitignore` | One line: `.aid/` |

## Key Files

| File | Purpose |
|------|---------|
| `methodology/aid-methodology.md` | The complete V3 methodology spec (1,158 lines). The single normative document; everything else is derived from this. |
| `setup.sh` / `setup.ps1` | Tool installers. Identical menu, identical copy semantics, identical "Next steps" message. The `.sh` is 161 lines; `.ps1` is 156 lines. |
| `templates/scripts/build-project-index.sh` | 368-line Bash that emits `.aid/knowledge/project-index.md` — the file inventory consumed by every discovery sub-agent. Run as a Step 0c pre-pass by `aid-discover` so the 5 sub-agents do not each re-glob the tree. |
| `templates/scripts/grade.sh` | 141-line Bash that computes A+/A/B/C/D/F grades deterministically from a Reviewer's structured issue list. Same input, same grade. |
| `templates/knowledge-summary/scripts/grade.sh` | 194-line variant used by `aid-summarize` for HTML quality gating. |
| `templates/knowledge-base/INDEX.md` | The canonical KB index template — drives the layout of `.aid/knowledge/INDEX.md`. |
| `README.md` | Quick start, phase table, agent table, repo structure ASCII tree. |
| `CONTRIBUTING.md` | Explains the per-tool tree triplication rule (lines 21-26): updating a skill or agent means updating human README + Claude Code + Codex versions (Cursor is documented separately in the Cursor README). |

## Per-Tool Installation Trees (the Triplication Pattern)

The repository contains **three near-identical install payloads** — one per supported AI tool. Each payload contains a full copy of the skills, agents, and templates in that tool's native format:

| Tool | Tree | Agents format | Skills location | Project config file |
|------|------|---------------|-----------------|---------------------|
| Claude Code | `profiles/claude-code/.claude/` | `.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) | `profiles/claude-code/.claude/skills/aid-*/SKILL.md` | `profiles/claude-code/CLAUDE.md` |
| OpenAI Codex CLI | `profiles/codex/.codex/agents/` (TOML) + `profiles/codex/.agents/skills/` and `profiles/codex/.agents/templates/` (markdown / scripts) | `.toml` with `name`, `description`, `developer_instructions`, `model`, `model_reasoning_effort` | `profiles/codex/.agents/skills/aid-*/SKILL.md` | `profiles/codex/AGENTS.md` |
| Cursor | `profiles/cursor/.cursor/` | `.md` with YAML frontmatter (same shape as Claude Code) | `profiles/cursor/.cursor/skills/aid-*/SKILL.md` | `profiles/cursor/AGENTS.md` + `profiles/cursor/.cursor/rules/*.mdc` |

The `templates/` directory exists at the repo root AND is copied verbatim under each tool tree (`profiles/claude-code/.claude/templates/`, `profiles/codex/.agents/templates/`, `profiles/cursor/.cursor/templates/`). That is why the top-20-largest-files list in `project-index.md` shows every large script appearing **four times** (root + three trees) — see for example `build-project-index.sh` (368 lines x 4) and `lightbox.js` (359 lines x 4).

The installer scripts (`setup.sh`, `setup.ps1`) work by copying the matching tree into the target project; they do not generate files from the canonical sources.

**Implication:** any change to a skill or agent body must be applied four times (root `skills/` or `agents/`, then each of the three tool trees). This is called out explicitly in `CONTRIBUTING.md:21-26`. There is no script that propagates changes across trees — drift between trees is possible and must be detected manually.

## Skills Inventory

Source: `profiles/claude-code/.claude/skills/aid-*/SKILL.md` frontmatter `description:` field. The same skills are duplicated under `profiles/codex/.agents/skills/` and `profiles/cursor/.cursor/skills/` (sometimes with longer bodies — e.g., the Codex `aid-discover` SKILL.md is 1,078 lines vs. 453 lines in Claude Code; Cursor's is 1,090 lines).

| Skill | Allowed tools | One-line purpose |
|-------|---------------|-------------------|
| `aid-init` | Read, Glob, Grep, Bash, Write, Edit | Initialize AID project: ask greenfield vs. brownfield, collect metadata + external doc paths, scaffold `.aid/` and KB placeholders. Run once. |
| `aid-discover` | Read, Glob, Grep, Bash, Write, Edit, Agent | Brownfield discovery with built-in quality gate. State machine GENERATE -> REVIEW -> Q&A -> FIX -> APPROVAL -> DONE. Dispatches 5 discovery sub-agents in parallel. |
| `aid-interview` | Read, Glob, Grep, Bash, Write, Edit | Adaptive requirements gathering via one-question-at-a-time dialogue. First run builds `REQUIREMENTS.md`; subsequent runs cross-reference KB and decompose features. |
| `aid-specify` | Read, Glob, Grep, Bash, Write, Edit | Technical refinement per feature — agent acts as tech lead, proposes solutions, writes to per-feature `SPEC.md`. |
| `aid-plan` | Read, Glob, Grep, Write, Edit, Bash | Sequence feature SPECs into deliverables — each a functional MVP that builds on the previous. Strategy. |
| `aid-detail` | Read, Glob, Grep, Write, Edit, Bash | Break deliverables into typed tasks (RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE). One type per task. Tactics. |
| `aid-execute` | Read, Glob, Grep, Write, Edit, Bash | Type-aware task execution with built-in review loop. EXECUTE -> REVIEW -> FIX -> DONE when grade >= minimum. Branch per delivery. |
| `aid-deploy` | Read, Glob, Grep, Bash, Write | Package eligible deliveries into a release; verify combined build; generate release notes; update artifact statuses. |
| `aid-monitor` | Read, Glob, Grep, Bash, Write | Observe production, classify findings, route to `aid-execute` (bugs) or `aid-discover` (CRs). Combines telemetry interpretation + triage. |
| `aid-summarize` | Read, Glob, Grep, Bash, Write, Edit | Optional. Generate single-file `knowledge-summary.html` from `.aid/knowledge/` with Mermaid diagrams, WCAG-AA, idempotent. State machine PREFLIGHT -> STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> FIX -> APPROVAL -> WRITEBACK -> DONE. |

Plus `skills/aid-correct/README.md` (5 lines) — a **confirmed tombstone** ("Correct (Deprecated) — phase merged into Triage" per `methodology/aid-methodology.md:889`); pending deletion per DISCOVERY-STATE Q6 (auto-resolved).

The Claude Code tree carries skill `references/` and `scripts/` subdirectories for several skills (e.g., `aid-discover/references/agent-prompts.md`, `aid-discover/scripts/check-preflight.sh`, `aid-execute/references/task-type-rules.md`); the Codex and Cursor trees only carry SKILL.md for most skills (with `aid-interview/references/kb-hydration.md` as a notable exception in both).

## Agents Inventory

Source: `profiles/claude-code/.claude/agents/*.md` frontmatter `description:` field. The same agents exist under `profiles/cursor/.cursor/agents/*.md` (identical format) and `profiles/codex/.codex/agents/*.toml` (TOML translation). The human-readable versions are under the root `agents/` tree.

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
| `discovery-scout` | Opus | `project-structure.md`, `external-sources.md` enrichment, Q&A seeded directly in `DISCOVERY-STATE.md` (consolidated per Q102 / Q115 — the older `additional-info.md` reference in agent prompts is stale; tracked in R12) |
| `discovery-reviewer` | Opus | `DISCOVERY-STATE.md` (cross-references claims against source code, grades the KB) |

### Utility Sub-Agents (Haiku tier, called by full agents only — never invoked at the skill layer, 3)

| Agent | Tier | Purpose |
|-------|------|---------|
| `simple-extractor` | Haiku | Mechanical extraction of structured items from source files with file path + line number per item. |
| `simple-formatter` | Haiku | Fills markdown templates with structured input. |
| `simple-glob` | Haiku | Enumerates files matching glob patterns with size + mtime metadata. |

Each utility agent is explicitly marked `INTERNAL UTILITY (sub-agent only — do NOT invoke from a skill)` in its description.

## Templates

### `templates/knowledge-base/` (KB document templates, consumed by Discovery)

**17 files** at `templates/knowledge-base/` (verified `ls templates/knowledge-base/`): **15 standard KB-doc templates** (`api-contracts.md`, `architecture.md`, `coding-standards.md`, `data-model.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `project-structure.md`, `security-model.md`, `tech-debt.md`, `technology-stack.md`, `test-landscape.md`) + **2 meta-doc templates** (`INDEX.md`, `README.md`) = 17 files. **The 16th standard KB doc — `ui-architecture.md` — has NO canonical-root template here**, but each install tree ships a 5-line stub at `{profiles/claude-code/.claude,profiles/codex/.agents,profiles/cursor/.cursor}/templates/ui-architecture.md` (per DISCOVERY-STATE Q114 + Q126 — pending lift to canonical root). The KB `README.md` and `INDEX.md` templates here drive the layout `aid-init` writes to `.aid/knowledge/README.md` and `.aid/knowledge/INDEX.md`.

### `templates/requirements/`, `templates/specs/`, `templates/delivery-plans/`

- `requirements/requirements-template.md` (95 lines) — REQUIREMENTS.md template.
- `specs/spec-template.md` (75 lines) — per-feature SPEC.md (requirements + tech spec).
- `delivery-plans/task-template.md` (20 lines) — individual `task-NNN.md` (the only file in `delivery-plans/`). PLAN.md has no template — its format is defined inline by `aid-plan`.

### `templates/feedback-artifacts/`

- `IMPEDIMENT.md` (118 lines) — implementation blocker requiring spec/plan revision. The only file in `feedback-artifacts/`.
- (MONITOR-STATE.md is referenced in `templates/README.md` but is not present as a file under `templates/feedback-artifacts/`.)

### `templates/reports/`

- `discovery-state-template.md` (67 lines) — DISCOVERY-STATE.md skeleton. The only file in `reports/`.

### `templates/knowledge-summary/` (`aid-summarize` assets)

Twenty-five files. The largest are `component-css.css` (642 lines), `lightbox.js` (359 lines), `validate-diagrams.mjs` (294 lines), `prompt.md` (248 lines), `grading-rubric.md` (226 lines). Includes section templates per project profile (`web-app.md`, `library.md`, `cli.md`, `microservices.md`, `data-pipeline.md`, `auto-detect.md`), an HTML skeleton, and a suite of validation scripts (`check-preflight.sh`, `stale-check.sh`, `validate-html.sh`, `validate-links.sh`, `fetch-mermaid.sh`, `contrast-check.mjs`, `writeback-discovery-state.sh`, `concatenate.{sh,ps1}`).

### `templates/scripts/`

- `build-project-index.sh` (368 lines, Bash) — pre-pass for `aid-discover`.
- `grade.sh` (141 lines, Bash) — deterministic grading.

### `templates/` root

- `grading-rubric.md` (74 lines).
- `implementation-state.md` (30 lines).

## Methodology and Docs

| File | Lines | Purpose |
|------|-------|---------|
| `methodology/aid-methodology.md` | 1,158 | The full V3 methodology spec. |
| `methodology/images/1-pipeline.png` | (image) | Pipeline diagram. |
| `methodology/images/2-comparison.png` | (image) | AID vs. SDD comparison diagram. |
| `methodology/images/3-ironman.png` | (image) | Human-as-pilot / AI-as-Iron-Man-suit collaboration diagram. |
| `methodology/images/4-feedback-loops.png` | (image) | The 11 formal feedback loops diagram. |
| `docs/faq.md` | 61 | Adopter FAQ. Mentions tool-agnosticism (Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, Aider). |
| `docs/glossary.md` | 80 | Terminology reference. |

## Examples

| Example | Files | Scenario |
|---------|-------|----------|
| `examples/brownfield-enterprise/` | `README.md` (60), `discovery-report.md` (75), `knowledge-base/architecture.md` (40) | 21 GB Java/OSGi monorepo, no docs, three-day discovery. |
| `examples/desktop-app/` | `README.md` (56), `delivery-plan.md` (51), `task-spec.md` (110) | .NET / Avalonia / MVVM transcription app, 0 to 1,100+ tests across 6 deliveries. |
| `examples/data-pipeline/` | `README.md` (78), `pipeline-architecture.md` (113) | Multi-brand e-commerce analytics, 12 specialist agents, 5 data sources, 1 percent tolerance. |

## Detected Languages and Frameworks

From `project-index.md` Language Breakdown:

| Language | Files | Lines | Purpose in this repo |
|----------|-------|-------|----------------------|
| Markdown | 249 | 33,022 | Methodology, READMEs, SKILL bodies, agent definitions (Claude Code + Cursor), templates. The vast bulk of the repo. |
| Shell | 43 | 5,490 | `setup.sh`, `build-project-index.sh`, `grade.sh`, knowledge-summary validation scripts. |
| JavaScript | 16 | 3,428 | Knowledge-summary viewer assets (`lightbox.js`, `mermaid-init.js`) + `.mjs` validators. |
| CSS | 4 | 2,568 | Knowledge-summary styling (`component-css.css`). |
| Other | 8 | 2,469 | Includes `.png` diagrams (4 in `methodology/images/`), `LICENSE`, `.gitignore`, the two `.mdc` Cursor rules. |
| TOML | 22 | 1,522 | Codex agent definitions under `profiles/codex/.codex/agents/*.toml`. |
| HTML | 4 | 404 | `knowledge-summary/html-skeleton.html` (x4 across trees). |
| PowerShell | 5 | 300 | `setup.ps1` plus `knowledge-summary/scripts/concatenate.ps1` (x4). |
| JSON | 2 | 23 | This repo's own `.claude/settings.json` and a sibling `.claude/settings..json` (note the double-dot — see Anomalies). |

**No framework signals** in the conventional sense. There is no `package.json`, no `requirements.txt`, no `Cargo.toml`, no `pom.xml`, no `go.mod`, no `*.csproj`, no `Dockerfile`, no Kubernetes manifests, no Terraform / CDK / Pulumi files anywhere in the tree. This repo is fundamentally a static set of markdown + shell + a few JS files — not a deployable application.

## Build / Test / CI

- **No top-level package manifest.** No `Makefile`. No `build.sh` or `test.sh` at the root.
- **No CI configuration found.** No `.github/workflows/`, no `.gitlab-ci.yml`, no `.circleci/`, no Jenkinsfile, no `azure-pipelines.yml`.
- **Existing executable scripts** are limited to:
  - `setup.sh` / `setup.ps1` — installer (not tests).
  - `templates/scripts/build-project-index.sh` — runtime pre-pass for `aid-discover` (also runtime, not tests).
  - `templates/scripts/grade.sh` — runtime grading.
  - `templates/knowledge-summary/scripts/*` — runtime validation for `aid-summarize` output (`validate-diagrams.mjs`, `validate-html.sh`, `validate-links.sh`, `contrast-check.mjs`, `check-preflight.sh`, `stale-check.sh`, `fetch-mermaid.sh`).
- **No test runner config** (`jest.config`, `pytest.ini`, `vitest`, `mocha`, etc.).
- The knowledge-summary `validate-*.mjs` and `validate-*.sh` scripts are the closest thing to automated checks — they validate Mermaid diagrams, HTML, links, and color contrast in the generated KB summary, not the source-of-truth methodology files.

## File Counts per Major Directory

| Directory | File count (approx.) |
|-----------|----------------------|
| `profiles/claude-code/.claude/` | 64 (22 agents + 10 skills + 31 templates / scripts) |
| `profiles/codex/.codex/agents/` | 22 (TOML) |
| `profiles/codex/.agents/` | ~58 (10 skills + 47 templates / scripts) |
| `profiles/cursor/.cursor/` | ~80 (22 agents + 2 rules + 10 skills + 45 templates / scripts) |
| `templates/` | ~50 (KB templates + KS assets + scripts + feedback + reports) |
| `agents/` | 17 entries (16 agent README folders + top-level `README.md`) — verified `ls agents/` |
| `skills/` | 10 entries (9 aid-* folders including 1 tombstone `aid-correct/` pending deletion per Q6 + top-level `README.md`) — verified `ls skills/ \| wc -l` = 10 |
| `examples/` | 9 |
| `docs/` | 2 |
| `methodology/` | 5 (1 markdown + 4 images) |
| Root | 7 (`README.md`, `CONTRIBUTING.md`, `LICENSE`, `CLAUDE.md`, `setup.sh`, `setup.ps1`, `.gitignore`) |

Total: 353 files per `project-index.md`.

## Anomalies and Things to Flag

1. **Triplicated install trees with no propagation tooling.** Same content under `profiles/claude-code/.claude/templates/`, `profiles/codex/.agents/templates/`, `profiles/cursor/.cursor/templates/`, AND `templates/`. The CONTRIBUTING guide acknowledges this and tells contributors to update all locations manually. Drift is possible and undetected.
2. **Stray dotfile:** `.claude/settings..json` — note the **double dot** in the filename, sitting alongside `.claude/settings.json`. Both contain similar permission allow-lists. Likely a typo or leftover. Not gitignored.
3. **No CI, no manifest, no version file.** Nothing in the repo declares the AID version number programmatically. README and methodology document refer to "V3" but there is no `VERSION` file, no git tag visible in this worktree, no GitHub release artifact tracked in-repo.
4. **`.aid/` is gitignored** but is being populated by the current dogfood run. The KB outputs will not be committed — they exist only for runtime use of this worktree.
5. **Codex tree uses a split layout** (`.codex/` for agents, `.agents/` for skills + templates) — different from Claude Code (everything under `.claude/`) and Cursor (everything under `.cursor/`). This split is intentional per `profiles/codex/README.md:12-15` but is a source of asymmetry.
6. **`aid-correct` tombstone — CONFIRMED.** `skills/aid-correct/README.md` is 5 lines containing "# Correct (Deprecated)" and "This phase has been merged into Triage." Confirmed by `methodology/aid-methodology.md:889`. Pending deletion per DISCOVERY-STATE Q6 — not a forward-looking placeholder (the earlier characterization was wrong).
7. **Skill body length drift between trees.** `aid-discover/SKILL.md` is 453 lines in Claude Code, 1,078 lines in Codex, 1,090 lines in Cursor. Similar drift on `aid-interview`, `aid-execute`, `aid-specify`. The Claude Code versions appear to externalize content into `references/` and `scripts/` subfolders; the Codex and Cursor versions appear to inline the same content. Worth confirming this is intentional.
8. **Missing report and feedback templates referenced in docs.** No `templates/reports/track-report-template.md` exists, but `templates/README.md` references it. Same for `templates/feedback-artifacts/MONITOR-STATE.md`. Likely documentation drift.
9. **GitHub Copilot and Google Antigravity** are mentioned in `README.md`, `CONTRIBUTING.md`, and `docs/faq.md` as supported / future-supported tools, but there is no install tree for either. Cursor was the most recent addition.
10. **The repository root `CLAUDE.md`** says `## Project (pending discovery)` — this repo is being discovered now, so this field will be filled in by the broader `aid-discover` run, not by this scout.
