---
kb-category: primary
source: hand-authored
intent: |
  Maps the major code/content modules in AID — the 10 user-facing aid-* skills,
  the 11th maintainer-only aid-generate skill, the 22 agents, the 11 renderer
  Python files (10 under .claude/skills/aid-generate/scripts/ + run_generator.py),
  and the canonical helper scripts under canonical/scripts/{config,kb,execute,summarize,interview}.
  Each entry lists purpose, directory path, dependencies, and associated tests.
  Read this when you need to know what a directory holds and who consumes it.
  NOT a tech-stack overview (see architecture.md) and NOT a per-script API
  reference (see the script's own header comment block).
contracts:
  - "10 user-facing aid-* skills + 1 maintainer-only aid-generate skill = 11 total"
  - "22 agents under canonical/agents/ (10 large / 9 medium / 3 small)"
  - "5 renderer Python files under .claude/skills/aid-generate/scripts/ (render_agents, render_skills, render_templates, render_scripts, render_recipes) + harness + profile + verify_deterministic + verify_advisory + test_manifest_safety = 10 files under scripts/, plus run_generator.py at the repo root"
  - "5 script categories under canonical/scripts/ (config, kb, execute, summarize, interview) + grade.sh at the category root"
  - "Every canonical helper script has 4 byte-identical copies on disk (canonical + .claude + 3 profile trees)"
changelog:
  - 2026-05-27: Initial generation by discovery-analyst (cycle-1)
---

# Module Map

> Coverage of every "module" in the AID repo. Modules here are NOT application
> components (there is no application — see CLAUDE.md:23-25 and
> project-structure.md:18-19); they are the artifact families the renderer ships
> and the helper code that supports them. All paths are repo-relative.

## Module classes

The repo contains five module classes, each with its own conventions:

1. **Skills** — 10 user-facing + 1 maintainer-only — under `canonical/skills/aid-*/`
2. **Agents** — 22 specialist agents — under `canonical/agents/<name>/`
3. **Renderer (Python)** — 10 files under `.claude/skills/aid-generate/scripts/` + `run_generator.py` at the repo root
4. **Helper scripts (Bash + JS + PS1)** — under `canonical/scripts/{config,kb,execute,summarize,interview}/` + `canonical/scripts/grade.sh`
5. **Templates + Recipes** — content fixtures consumed by skills — under `canonical/templates/` + `canonical/recipes/`

The render pipeline (Module 3) emits Modules 1, 2, 4, 5 into 3 install trees
(`profiles/{claude-code,codex,cursor}/`) and the dogfood `.claude/` tree.
Source-of-truth is `canonical/`; every other copy is byte-identical output
verified by `.claude/skills/aid-generate/scripts/verify_deterministic.py`.

---

## 1. Skills — `canonical/skills/aid-*/`

Eleven `aid-*` skills. Each has a `SKILL.md` Thin-Router (per CLAUDE.md:51-56)
plus a `references/state-*.md` per state plus topic-specific reference docs.

| Skill | Purpose | SKILL.md (canonical) | Reference files | Notable references |
|-------|---------|---------------------|-----------------|--------------------|
| `aid-config` | View/update `.aid/settings.yml` — first-run scaffold + per-key edit | `canonical/skills/aid-config/SKILL.md` | 0 | (single-state; no references/ subdir) |
| `aid-discover` | Brownfield KB scan — dispatches 5 discovery sub-agents in parallel; state machine GENERATE→REVIEW→Q-AND-A→FIX→APPROVAL→DONE | `canonical/skills/aid-discover/SKILL.md` | 8 | `agent-prompts.md`, `document-expectations.md`, `reviewer-{brief,prompt}.md`, `state-{approval,done,fix,generate,q-and-a,review}.md` |
| `aid-interview` | Requirements gathering + lite-path triage (LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths) — largest reference set per CLAUDE.md:60-64 | `canonical/skills/aid-interview/SKILL.md` | 19 | `state-triage.md` (largest single state file), `state-condensed-intake.md`, `lite-to-full-escalation.md`, `recipe-to-lite-escalation.md`, `feature-decomposition.md` |
| `aid-specify` | Per-feature technical spec — state machine INITIALIZE→CONTINUE→REVIEW→DONE plus BLOCKED + SPIKE side states | `canonical/skills/aid-specify/SKILL.md` | 9 | `state-{initialize,continue,review,done,spike,blocked}.md`, `handling-outcomes.md`, `known-issues-scope.md`, `reviewer-brief.md` |
| `aid-plan` | Sequence features into shippable deliveries | `canonical/skills/aid-plan/SKILL.md` | 3 | `first-run-loop.md`, `review-deliverables.md`, `reviewer-brief.md` |
| `aid-detail` | Decompose deliveries into PR-sized typed tasks (8-type catalog: RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE per `canonical/skills/aid-execute/references/state-execute.md:6-16`) | `canonical/skills/aid-detail/SKILL.md` | 5 | `task-decomposition.md`, `execution-graph-generation.md`, `first-run.md`, `review.md`, `reviewer-brief.md` |
| `aid-execute` | Implement + two-tier review (per-task quick-check + per-delivery gate per CLAUDE.md:65-67); parallel pool dispatch with `MaxConcurrent` | `canonical/skills/aid-execute/SKILL.md` | 8 | `state-execute.md` (largest single state file — pool dispatch PD-0..PD-6), `state-delivery-gate.md`, `state-review.md`, `state-{fix,re-run}.md`, `reviewer-{brief,guide}.md`, `task-type-rules.md` |
| `aid-deploy` | Ship a delivery + create PR | `canonical/skills/aid-deploy/SKILL.md` | 5 | `state-{idle,selecting,packaging,verifying,re-run}.md` |
| `aid-monitor` | Production-finding classification + routing | `canonical/skills/aid-monitor/SKILL.md` | 3 | `state-{observe,classify,route}.md` |
| `aid-summarize` | Optional offline HTML KB viewer (Mermaid + sectioned per profile) | `canonical/skills/aid-summarize/SKILL.md` | 10 | `state-{preflight,profile,generate,validate,manual-checklist,stale-check,writeback,fix,approval,done}.md` |
| `aid-generate` (maintainer-only) | Render canonical/ → 3 install trees; LOAD → VALIDATE → RENDER → VERIFY → REPORT | `.claude/skills/aid-generate/SKILL.md` (NOT in `canonical/skills/` — see `.claude/skills/aid-generate/SKILL.md:13` for the chicken-and-egg justification) | n/a — uses `scripts/*.py` instead | (renderer Python files — see §3) |

**Test coverage:**

- Skill end-to-end behavior: `tests/skills/lite-subpaths.sh`, `tests/skills/lite-to-full-escalation.sh`.
- Helper scripts that skills invoke are covered by the per-script test suites in `tests/canonical/` (see §4).
- No direct unit tests for SKILL.md bodies themselves — they are state-router markdown read by Claude Code / Codex / Cursor at slash-command invocation; behavior is exercised indirectly through skill-level e2e runs.

**Key convention** (per CLAUDE.md:51-56): every `aid-*` SKILL.md is a state
router (≤~360 lines) that delegates per-state logic to `references/state-*.md`
files. The Dispatch table is the canonical state machine; advance follows one
of three forms (Unconditional / Halt / Conditional on a computed criterion).

---

## 2. Agents — `canonical/agents/<name>/`

22 specialist agent definitions. Each lives in its own subdirectory containing
`AGENT.md` (the agent contract) and `README.md` (the human-facing description).
Three tiers, per the `tier:` frontmatter field:

### 2a. Large tier (10) — heavy-lifting analysts, designers, reviewers, dispatchers

| Agent | Description (from AGENT.md frontmatter) | Path |
|-------|-----------------------------------------|------|
| `architect` | Design-thinking specialist — produces SPEC.md, PLAN.md, task-NNN.md decomposition + execution graph | `canonical/agents/architect/AGENT.md` |
| `reviewer` | Adversarial quality evaluator. Produces a structured issue list; grade is computed by `canonical/scripts/grade.sh`, NOT by the agent | `canonical/agents/reviewer/AGENT.md` |
| `interviewer` | One-question-at-a-time adaptive dialogue with stakeholders → REQUIREMENTS.md | `canonical/agents/interviewer/AGENT.md` |
| `security` | Threat modeling, OWASP, auth patterns, secrets, SSRF/injection/XSS | `canonical/agents/security/AGENT.md` |
| `discovery-scout` | Maps deployment infrastructure + project structure → `infrastructure.md`, `project-structure.md` | `canonical/agents/discovery-scout/AGENT.md` |
| `discovery-architect` | Codebase structure, patterns, tech stack, UI architecture → `architecture.md`, `technology-stack.md`, `ui-architecture.md` | `canonical/agents/discovery-architect/AGENT.md` |
| `discovery-analyst` | Modules, coding conventions, data models → `module-map.md`, `coding-standards.md`, `data-model.md` (this agent) | `canonical/agents/discovery-analyst/AGENT.md` |
| `discovery-integrator` | APIs, integrations, domain glossary → `api-contracts.md`, `integration-map.md`, `domain-glossary.md` | `canonical/agents/discovery-integrator/AGENT.md` |
| `discovery-quality` | Tests, security, tech debt, infrastructure assessment → `test-landscape.md`, `security-model.md`, `tech-debt.md` | `canonical/agents/discovery-quality/AGENT.md` |
| `discovery-reviewer` | Reviews + grades KB docs; cross-references claims against source. Densest agent contract per project-structure.md:256 | `canonical/agents/discovery-reviewer/AGENT.md` |

### 2b. Medium tier (9) — specialists + orchestrator + executors

| Agent | Description | Path |
|-------|-------------|------|
| `orchestrator` | Routes work to agents, manages phase transitions with human gates | `canonical/agents/orchestrator/AGENT.md` |
| `researcher` | Investigates + synthesizes from code/docs/APIs into KB docs | `canonical/agents/researcher/AGENT.md` |
| `developer` | The ONLY agent authorized to modify production code (per `canonical/agents/developer/AGENT.md:8`) | `canonical/agents/developer/AGENT.md` |
| `operator` | Deploy, PR creation, release management, KB updates | `canonical/agents/operator/AGENT.md` |
| `data-engineer` | Schema, migrations, query optimization, ETL | `canonical/agents/data-engineer/AGENT.md` |
| `performance` | Profiling, load testing, bottleneck analysis | `canonical/agents/performance/AGENT.md` |
| `devops` | CI/CD, IaC, containerization, deployment | `canonical/agents/devops/AGENT.md` |
| `tech-writer` | End-user docs, API docs, changelogs, README quality | `canonical/agents/tech-writer/AGENT.md` |
| `ux-designer` | UI/UX patterns, accessibility (WCAG), user flows | `canonical/agents/ux-designer/AGENT.md` |

### 2c. Small tier (3) — mechanical utility sub-agents (sub-agent-only)

Each is labelled `INTERNAL UTILITY (sub-agent only — do NOT invoke from a skill)`
in its `description:` frontmatter (per `canonical/agents/simple-extractor/AGENT.md:3`,
`simple-formatter/AGENT.md:3`, `simple-glob/AGENT.md:3`).

| Agent | Purpose | Path |
|-------|---------|------|
| `simple-extractor` | Mechanical extraction with schema-bound output (path + line for every row) | `canonical/agents/simple-extractor/AGENT.md` |
| `simple-formatter` | Fills templates from structured input → markdown | `canonical/agents/simple-formatter/AGENT.md` |
| `simple-glob` | Enumerates files matching glob patterns → sorted markdown table (path, size, mtime) | `canonical/agents/simple-glob/AGENT.md` |

**Dependencies (cross-agent):**

- Skills dispatch agents via the host's Agent/Task tool with `subagent_type` matching the `name:` field of `AGENT.md` (per `canonical/skills/aid-discover/SKILL.md:213-219` Dispatch table).
- Agents call other agents only indirectly — through a wrapping skill or `orchestrator`. There are no direct agent-to-agent Task tool calls in the canonical bodies.
- All 5 `discovery-*` sub-agents receive `permissionMode: bypassPermissions` + `background: true` in frontmatter (per `canonical/agents/discovery-analyst/AGENT.md:6-7`, `discovery-architect/AGENT.md:6-7`, etc.). The non-discovery large + medium agents do NOT set those keys.
- Every agent (except `interviewer` which has read-only tools, and the three small-tier utilities which have a narrower scope) carries `## Heartbeat protocol` + `## Self-review discipline` blocks (per `canonical/agents/architect/AGENT.md:11-60`, `developer/AGENT.md:11-60`, `discovery-analyst/AGENT.md:11-61`). The blocks are byte-identical across agents — they are macro-copied from `canonical/templates/subagent-heartbeat-protocol.md` and `canonical/templates/self-review-protocol.md` at authoring time, NOT inserted by the renderer.

**Test coverage:** none direct. Agent contracts are exercised through skill-level e2e tests and via the canonical helper test suites (§4).

---

## 3. Renderer (Python) — `.claude/skills/aid-generate/scripts/` + repo root

The generator lives in `.claude/skills/aid-generate/scripts/`, NOT in
`canonical/skills/`, because it CANNOT be regenerated from itself
(chicken-and-egg per `.claude/skills/aid-generate/SKILL.md:13`). It is the only
Python in the repo.

**Path:** `.claude/skills/aid-generate/scripts/*.py` (10 files) + `run_generator.py` (repo root wrapper).

| File | Purpose | Key entry points |
|------|---------|------------------|
| `harness.py` | Shared utilities — `read_canonical_file`, `write_output_file`, `substitute_filenames`, `rewrite_install_paths`, `sha256_hex`, `EmissionManifest` (JSONL writer per `canonical/EMISSION-MANIFEST.md`) | `EmissionManifest.{add,diff,load,write}`, `sha256_hex`, regex constants `_PLACEHOLDER_RE`, `_CANONICAL_PATH_RE` |
| `profile.py` | Loads + validates a per-tool profile TOML; dataclasses `Profile`, `LayoutConfig`, `FrontmatterConfig`, `AgentConfig`, `SkillConfig`, `ModelTierSimple`, `ModelTierDetailed` | `load_profile(path)`, `validate(profile)` |
| `render_agents.py` | Renders `canonical/agents/<name>/AGENT.md` per profile (markdown OR TOML output depending on `agent.format` per `canonical/EMISSION-MANIFEST.md:113`) | `render_agents(repo, profile, manifest, repo_root)`, `_parse_frontmatter` |
| `render_skills.py` | Renders `canonical/skills/aid-*/SKILL.md` + `references/*.md` per profile; preserves frontmatter formatting verbatim (folded `description:` blocks) | `render_skills(...)`, `_split_frontmatter_raw`, `_rewrite_skill_frontmatter` |
| `render_templates.py` | Renders `canonical/templates/` per profile (passthrough with path rewriting) | `render_templates(...)` |
| `render_scripts.py` | Renders `canonical/scripts/` (Bash + JS + PS1) per profile; preserves shebang + line endings | `render_scripts(...)` |
| `render_recipes.py` | Renders `canonical/recipes/` (passthrough, no frontmatter injection, no slot resolution at render time per `canonical/EMISSION-MANIFEST.md:117-125`) | `render_recipes(...)` |
| `verify_deterministic.py` | VERIFY-4a (strict) — re-renders to a scratch dir, compares byte-by-byte against committed install trees; non-zero exit if any drift | `run_verify(repo_root, report_path)` |
| `verify_advisory.py` | VERIFY-4b (advisory) — additional checks (frontmatter shape, install-path rewrites, etc.) | `run_advisory(repo_root, report_path)` |
| `test_manifest_safety.py` | Self-tests for the EmissionManifest deletion logic | (pytest-style; run standalone) |
| `run_generator.py` (repo root) | Live generator entrypoint — loads every `profiles/*.toml`, calls renderers in sequence, performs deletion pass via `EmissionManifest.diff`, writes manifest, runs VERIFY-4a + VERIFY-4b | `for profile_path in sorted(profiles_dir.glob('*.toml'))` (line 24) |

**Dependencies:**

- Python 3.11+ (stdlib `tomllib` per `.claude/skills/aid-generate/scripts/profile.py:12`).
- No third-party packages (no `requirements.txt`, no `pyproject.toml`; confirmed via project-structure.md:96).
- `harness.py` is imported by every `render_*.py` via `sys.path.insert(0, str(_SCRIPT_DIR))` (per `render_agents.py:24`, `render_skills.py:21-24`).
- `run_generator.py:7` inserts `.claude/skills/aid-generate/scripts` on the Python path and imports the renderers directly.

**Test coverage:**

- `test_manifest_safety.py` covers `EmissionManifest` round-trip + diff edge cases.
- `verify_deterministic.py` is itself a test — invoked after every render and exits non-zero on drift (per `run_generator.py:75-79`). It exercises the entire renderer chain end-to-end against the committed trees.
- No standalone Python test runner configured (no `pytest.ini`, per project-structure.md:96). Tests are invoked manually via the commands listed in CLAUDE.md:27-42.

---

## 4. Helper scripts — `canonical/scripts/{config,kb,execute,summarize,interview}/` + `grade.sh`

Bash (Shell) + Node (JavaScript) + PowerShell helpers consumed by skills at
slash-command invocation. Every script has 4 byte-identical copies on disk
(canonical + `.claude/scripts/` + `profiles/{claude-code,codex,cursor}/.{claude,agents,cursor}/scripts/`)
— verified by `verify_deterministic.py`. Repo totals are recorded in `.aid/generated/project-index.md`.

### 4a. `canonical/scripts/config/` — settings access

| Script | Purpose | Key flags |
|--------|---------|-----------|
| `read-setting.sh` | Reads a key from `.aid/settings.yml` with per-skill override resolution (skill.key → review.key → default) | `--skill X --key Y` (override-aware), `--path A.B` (direct), `--default V` |

### 4b. `canonical/scripts/kb/` — KB build + verification

| Script | Purpose |
|--------|---------|
| `verify-claims.sh` (largest shell file per `.aid/generated/project-index.md:50`) | Validates KB citations against disk: file:line existence, KB-file presence (16 standard primary files per `verify-claims.sh:102-119`), frontmatter compliance, generated-files freshness, count-drift detection |
| `build-project-index.sh` | Builds `.aid/generated/project-index.md` — used as the pre-pass shared input by the 5 discovery sub-agents |
| `build-index.sh` | Builds `.aid/generated/INDEX.md` — agent-facing 2-3-line summary per KB doc, composed from each doc's `intent:` frontmatter |
| `build-metrics.sh` | Builds `.aid/generated/metrics.md` — T3 numeric facts (line counts, file counts, term counts, severity tallies per `canonical/templates/kb-authoring/tier-model.md:42-54`) |
| `preflight.sh` | Pre-flight checks for `aid-discover` (verifies `.aid/knowledge/STATE.md` exists + not in Plan Mode) |

### 4c. `canonical/scripts/execute/` — task execution + parallel pool

| Script | Purpose |
|--------|---------|
| `writeback-task-status.sh` | Row-level write coordination for parallel pool dispatch (FR6) × per-area STATE writes; 4 modes (`--field`, `--findings`, `--block`, `--append-issue`); sentinel-file lock with retry; per CLAUDE.md:30 — 69 tests |
| `compute-block-radius.sh` | BFS over task dependency graph — computes the failure block radius when a task fails (per CLAUDE.md:32 — 17 tests) |
| `complexity-score.sh` | Task complexity scoring (drives executor model tier selection) |

### 4d. `canonical/scripts/summarize/` — offline HTML KB viewer

| Script | Purpose |
|--------|---------|
| `validate-diagrams.mjs` | Mermaid diagram validation (largest JS file per `.aid/generated/project-index.md:57`) |
| `run-validators.sh` | Aggregates summarize-phase validators |
| `validate-html-output.sh` | HTML output validation |
| `manual-checklist.sh` | Manual verification prompts |
| `spot-check-facts.sh` | Spot-checks KB facts against source files |
| `writeback-state.sh` | Writes summarize-phase state back to `.aid/knowledge/STATE.md` |
| `contrast-check.mjs` | WCAG AA contrast ratio checker (Node) |
| `stale-check.sh` | Detects stale KB sections |
| `preflight.sh` | Summarize preflight |
| `fetch-mermaid.sh` | Fetches Mermaid CLI assets |
| `concatenate.ps1` / `concatenate.sh` | Per-host concatenation helpers (PowerShell for Windows, Bash elsewhere) |

### 4e. `canonical/scripts/interview/` — lite-path recipes

| Script | Purpose |
|--------|---------|
| `parse-recipe.sh` | Parses `canonical/recipes/*.md` recipe files (YAML front-matter + `## spec` / `## tasks` body blocks); 5 modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`); per CLAUDE.md:34 — 113 tests (largest test file at `tests/canonical/parse-recipe.sh`) |

### 4f. `canonical/scripts/` (root)

| Script | Purpose |
|--------|---------|
| `grade.sh` | Deterministic grading: reads issue list with severity tags ([CRITICAL]/[HIGH]/[MEDIUM]/[LOW]/[MINOR]), applies the universal AID rubric (worst severity dominates, count modifies), prints letter grade. Used by reviewers + delivery gates. `--non-functional` flag forces F. |

**Test coverage:** 6 dedicated test suites under `tests/canonical/`, each invoked manually:

| Test file | Asserts (per CLAUDE.md:30-34) |
|-----------|------|
| `tests/canonical/parse-recipe.sh` | 113 tests for `parse-recipe.sh` |
| `tests/canonical/writeback-task-status.sh` | 69 tests for `writeback-task-status.sh` |
| `tests/canonical/delivery-gate-aggregate.sh` | 18 tests for delivery-gate aggregator |
| `tests/canonical/compute-block-radius.sh` | 17 tests for BFS block-radius |
| `tests/canonical/read-setting.sh` | (count not stated in CLAUDE.md; suite exists) |
| `tests/canonical/pool-dispatch.sh` | 7 tests for parallel pool dispatch |

> ⚠️ Inferred from disk — needs confirmation: CLAUDE.md:35-36 references two test
> runners at `.aid/work-001-aid-lite/test-reports/e2e-{two-tier,lite-path}-runner.sh`
> (35 + 38 tests). These files are NOT present in the `.aid/generated/project-index.md`
> snapshot — same caveat raised in project-structure.md:178.

---

## 5. Templates + Recipes — `canonical/templates/` + `canonical/recipes/`

Content fixtures consumed by skills + agents at runtime. The renderer copies them passthrough (no transform) into all 3 install trees.

### 5a. Templates — `canonical/templates/`

Organized into categories (per project-structure.md:273-282):

| Subdirectory | Files | Notable contents |
|--------------|-------|------------------|
| `delivery-plans/` | 1 | `task-template.md` — the 6-section task contract (Type / Source / Depends on / Scope / Acceptance Criteria) |
| `feedback-artifacts/` | 1 | `IMPEDIMENT.md` — formal escalation contract for developer↔orchestrator |
| `kb-authoring/` | 5 | `README.md`, `frontmatter-schema.md`, `principles.md` (P1-P7), `review-rubric.md`, `tier-model.md` (T1-T4) |
| `knowledge-base/` | 17 | Templates for all 16 standard KB documents + README (one per `verify-claims.sh:102-119` `STANDARD_KB_FILES` array) |
| `knowledge-summary/` | 19+ | HTML/CSS/JS for the offline `knowledge-summary.html` viewer; `component-css.css` is the largest CSS file in the repo |
| `requirements/` | 1 | `requirements-template.md` |
| `specs/` | 2 | `lite-spec-template.md`, `spec-template.md` |
| `(top-level)` | 17 | `settings.yml`, `discovery-state-template.md`, `work-state-template.md`, `feature.md`, `recipe-template.md`, `subagent-heartbeat-protocol.md`, `long-wait-protocol.md`, `rough-time-hints.md`, `self-review-protocol.md`, `grading-rubric.md`, `reviewer-dispatch.md`, `delivery-issues.md`, `feature-inventory.md`, `generated-files.txt`, `known-issues.md`, `package.md`, `ui-architecture.md`, `dispatch-protocol-checklist.md` |

### 5b. Recipes — `canonical/recipes/`

5 pre-filled lite-path templates with YAML front-matter + `{{slot}}`
placeholders (per `canonical/templates/recipe-template.md:97-100`).

| Recipe | Path |
|--------|------|
| `add-crud-endpoint.md` | `canonical/recipes/add-crud-endpoint.md` |
| `add-unit-test.md` | `canonical/recipes/add-unit-test.md` |
| `bug-fix.md` | `canonical/recipes/bug-fix.md` |
| `method-refactor.md` | `canonical/recipes/method-refactor.md` |
| `write-release-note.md` | `canonical/recipes/write-release-note.md` |
| `README.md` | `canonical/recipes/README.md` — catalog documentation |

Consumed by `canonical/scripts/interview/parse-recipe.sh` during `/aid-interview` TRIAGE → recipe-offer.

**Test coverage:** indirect — recipe behavior is exercised by `tests/canonical/parse-recipe.sh` and `tests/skills/lite-subpaths.sh`.

---

## Cross-cutting dependencies

- **Skills → agents:** every multi-state skill dispatches one or more agents via the host's Agent/Task tool (per `canonical/skills/aid-discover/SKILL.md:213-219` Dispatch table; per `canonical/skills/aid-execute/references/state-execute.md:22-31` Agent Selection table mapping the 8 task types to executors).
- **Skills → scripts:** skills invoke helper scripts via Bash. Examples: `canonical/skills/aid-discover/SKILL.md:22` (`preflight.sh`), `aid-discover/SKILL.md:83` (`read-setting.sh`), `aid-execute/references/state-delivery-gate.md` (`grade.sh`, `writeback-task-status.sh`).
- **Agents → scripts:** agents invoke scripts indirectly (a skill dispatches the agent with a prompt containing the script call). No agent invokes a script except via its own Bash tool when authorized in its `tools:` frontmatter.
- **Renderer → everything:** the renderer reads `canonical/{agents,skills,templates,recipes,scripts}/`, applies the profile's transforms, writes into `profiles/{name}/<install_root>/`, and records every emission in `<install_root>/emission-manifest.jsonl`. The manifest is the SAFETY boundary for the next run's deletion pass (per `canonical/EMISSION-MANIFEST.md:70-83`).
- **Verify → renderer:** `run_generator.py:75-83` calls `verify_deterministic.py` (strict) then `verify_advisory.py` (advisory) after every render. VERIFY-4a re-runs the renderer to a scratch directory and compares byte-by-byte; any drift exits non-zero.
