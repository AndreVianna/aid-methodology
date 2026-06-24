---
kb-category: primary
source: hand-authored
objective: AID major module map: aid-* skills, agents, generator Python files, and canonical helper scripts with purpose, path, dependencies, and tests.
summary: Maps all major code and content modules in AID, including the 13 user-facing aid-* skills, 9 agents, 7 generator Python files, and canonical helper scripts, with each entry's directory path, dependencies, and associated tests.
tags: [module-map, aid-skills, agents, generator, helper-scripts, installer-cli, module-wiring]
audience: [architect, developer, maintainer]
see_also: [architecture.md, project-structure.md, pipeline-contracts.md, coding-standards.md]
sources:
  - canonical/skills/
  - canonical/agents/
  - canonical/aid/scripts/
  - .claude/skills/generate-profile/scripts/
  - tests/canonical/
approved_at_commit: ccb4e823
contracts:
  - "13 user-facing aid-* skills + 1 maintainer-only generate-profile skill = 14 total"
  - "9 agents under canonical/agents/ (4 large / 4 medium / 1 small)"
  - "7 generator Python files under .claude/skills/generate-profile/scripts/: render.py (single copy core + dormant Codex-TOML branch) + render_lib + aid_profile + verify_deterministic + verify_advisory + test_manifest_safety + run_generator.py (the entrypoint, moved here from repo root by work-001)"
  - "6 script categories under canonical/scripts/ (config, kb, execute, summarize, interview, housekeep) + grade.sh at the category root"
  - "Every canonical helper script has 7 byte-identical copies on disk (canonical + .claude dogfood + 5 profile trees)"
changelog:
  - 2026-06-23: work-001-kb-skills-improvement delivery-008 (task-050) — aid-ask renamed to aid-query-kb; aid-update-kb added (12->13 user-facing skills, 13->14 total, 5->6 optional). Reconciled all counts and enumerations.
  - 2026-06-23: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-06-22: work-005-profile-generator-simplify (merged) — §3 rewritten to the single copy-core model: render.py is now the sole copy generator (copy_tree over 3 trees: agents/skills translated, canonical/aid/ verbatim) + dormant Codex-TOML branch; the 5 per-type renderers (render_agents/render_skills/render_templates/render_recipes/render_canonical_scripts) + 2 emitter self-tests (test_copilot_emitter/test_antigravity_emitter) DELETED. Renderer .py count 13->7; §3 table, intent, contract, and Module-classes entry updated. Via /aid-housekeep KB-DELTA (Q30).
  - 2026-06-09: aid-ask added (11->12 user-facing skills, 12->13 total) via /aid-housekeep KB-DELTA.
  - 2026-06-05: work-002-auto-installer — added Module class 6 (Installer / CLI): the `aid` CLI dispatcher (bin/aid + bin/aid.ps1 + bin/aid.cmd), the shared install-core libs (lib/aid-install-core.sh + lib/AidInstallCore.psm1), the curl/irm bootstrap (install.sh + install.ps1), and the npm/PyPI shim packages (packages/npm + packages/pypi). Fixed the §4g test-coverage table: the removed test-setup.sh/test-setup-ps1.sh rows replaced with the installer/CLI suites.
  - 2026-06-04: work-001-agents-review (task-013) — roster reduced 22→9 agents with aid-* prefix (feature-002); §2 per-tier rosters replaced with new 4/4/1 tier split; boilerplate-presence claim updated to shared-include via canonical/templates/agent-boilerplate.md; all old bare agent names removed.
  - 2026-06-03: housekeep run-state relocation (PR #51) — corrected housekeep-state.sh (run-state now in the project-level `.aid/.temp/HOUSEKEEP_STATE_<ts>.md`, not a work-area STATE.md) and cleanup-classify.sh (every work folder offered, user-confirmed; signals informational; only the current-branch folder hard-skipped).
  - 2026-06-03: aid/housekeep-2026-06-03 (PR #49) — added the optional aid-housekeep skill (11→12 total skills; 11 user-facing canonical + generate-profile maintainer-only) and the canonical/scripts/housekeep/ category (5→6 script categories): housekeep-state.sh, branch-commit.sh, cleanup-classify.sh.
  - 2026-06-01: work-001-add-providers (PRs #42/#43/#44) — render profiles grew 3→5 (added copilot-cli + antigravity); scripts/ grew 10→12 .py (added test_copilot_emitter.py + test_antigravity_emitter.py); render_agents gained copilot-agent + antigravity-rule format branches; helper-script copy set is now canonical + .claude + 5 profile trees.
  - 2026-05-31: delivery-001 — reconciled discovery-agent ownership in old roster (now absorbed into aid-researcher per migration-map). Added note that document-expectations.md is the single per-doc expectations source loaded by aid-reviewer at REVIEW and FIX dispatch.
  - 2026-05-27: Initial generation (cycle-1)
---

# Module Map

> Coverage of every "module" in the AID repo. Modules here are NOT application
> components (there is no application — see project-structure.md §Primary Purpose);
> they are the artifact families the renderer ships and the helper code that supports
> them. All paths are repo-relative.

## Module classes

The repo contains six module classes, each with its own conventions:

1. **Skills** — 13 user-facing + 1 maintainer-only — under `canonical/skills/aid-*/`
2. **Agents** — 9 specialist agents — under `canonical/agents/<name>/`
3. **Generator (Python)** — 7 files under `.claude/skills/generate-profile/scripts/` (the `render.py` copy core + `run_generator.py` entrypoint)
4. **Helper scripts (Bash + JS + PS1)** — under `canonical/scripts/{config,kb,execute,summarize,interview,housekeep}/` + `canonical/scripts/grade.sh`
5. **Templates + Recipes** — content fixtures consumed by skills — under `canonical/templates/` + `canonical/recipes/`
6. **Installer / CLI** — the persistent global `aid` CLI + its install-core libs + bootstrap + the npm/PyPI shim packages — under `bin/`, `lib/`, repo-root `install.sh`/`install.ps1`, and `packages/`

The generator (Module 3) emits Modules 1, 2, 4, 5 into 5 install trees
(`profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`) and the dogfood
`.claude/` tree. Source-of-truth is `canonical/`; every other copy is
byte-identical output verified by
`.claude/skills/generate-profile/scripts/verify_deterministic.py`.

---

## 1. Skills — `canonical/skills/aid-*/`

Thirteen user-facing `aid-*` skills (`ls -d canonical/skills/*/` = 13) plus the
maintainer-only `generate-profile` (`.claude/`-only, NOT in `canonical/skills/`) = 14
total. Each has a `SKILL.md` Thin-Router (per `coding-standards.md §7b`)
plus a `references/state-*.md` per state plus topic-specific reference docs.

| Skill | Purpose | SKILL.md (canonical) | Reference files | Notable references |
|-------|---------|---------------------|-----------------|--------------------|
| `aid-config` | View/update `.aid/settings.yml` — first-run scaffold + per-key edit | `canonical/skills/aid-config/SKILL.md` | 0 | (single-state; no references/ subdir) |
| `aid-discover` | Brownfield KB scan — dispatches 5 discovery sub-agents in parallel; state machine GENERATE→REVIEW→Q-AND-A→FIX→APPROVAL→DONE | `canonical/skills/aid-discover/SKILL.md` | 8 | `agent-prompts.md`, `document-expectations.md`, `reviewer-{brief,prompt}.md`, `state-{approval,done,fix,generate,q-and-a,review}.md` |
| `aid-interview` | Requirements gathering + description-first lite-path triage (work-type inferred from the request description, never shown as a menu; sub-paths LITE-BUG-FIX / LITE-REFACTOR / LITE-FEATURE) — largest reference set | `canonical/skills/aid-interview/SKILL.md` | 19 | `state-triage.md` (largest single state file), `state-condensed-intake.md`, `lite-to-full-escalation.md`, `recipe-to-lite-escalation.md`, `feature-decomposition.md` |
| `aid-specify` | Per-feature technical spec — state machine INITIALIZE→CONTINUE→REVIEW→DONE plus BLOCKED + SPIKE side states | `canonical/skills/aid-specify/SKILL.md` | 9 | `state-{initialize,continue,review,done,spike,blocked}.md`, `handling-outcomes.md`, `known-issues-scope.md`, `reviewer-brief.md` |
| `aid-plan` | Sequence features into shippable deliveries | `canonical/skills/aid-plan/SKILL.md` | 3 | `first-run-loop.md`, `review-deliverables.md`, `reviewer-brief.md` |
| `aid-detail` | Decompose deliveries into PR-sized typed tasks (8-type catalog: RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE per `canonical/skills/aid-execute/references/state-execute.md` `## Task Types`) | `canonical/skills/aid-detail/SKILL.md` | 5 | `task-decomposition.md`, `execution-graph-generation.md`, `first-run.md`, `review.md`, `reviewer-brief.md` |
| `aid-execute` | Implement + two-tier review (per-task quick-check + per-delivery gate); parallel pool dispatch with `MaxConcurrent` | `canonical/skills/aid-execute/SKILL.md` | 8 | `state-execute.md` (largest single state file — pool dispatch PD-0..PD-6), `state-delivery-gate.md`, `state-review.md`, `state-{fix,re-run}.md`, `reviewer-{brief,guide}.md`, `task-type-rules.md` |
| `aid-deploy` | Ship a delivery + create PR | `canonical/skills/aid-deploy/SKILL.md` | 5 | `state-{idle,selecting,packaging,verifying,re-run}.md` |
| `aid-monitor` | Production-finding classification + routing | `canonical/skills/aid-monitor/SKILL.md` | 3 | `state-{observe,classify,route}.md` |
| `aid-housekeep` | Optional on-demand housekeeping skill — runs three gated jobs in strict order on an `aid/housekeep-*` branch, one commit per stage, never pushes; re-entrant (a stalled run resumes at the stalled stage). State machine PREFLIGHT→KB-DELTA→SUMMARY-DELTA→CLEANUP→DONE (per `canonical/skills/aid-housekeep/SKILL.md` `description:`). NOT inserted into the mandatory phase-to-skill pipeline. | `canonical/skills/aid-housekeep/SKILL.md` | 5 | `state-{preflight,kb-delta,summary-delta,cleanup,done}.md` |
| `aid-summarize` | Optional offline HTML KB viewer (Mermaid + sectioned per profile) | `canonical/skills/aid-summarize/SKILL.md` | 10 | `state-{preflight,profile,generate,validate,manual-checklist,stale-check,writeback,fix,approval,done}.md` |
| `aid-query-kb` | Optional on-demand Q&A skill OUTSIDE the numbered pipeline — answers free-form project questions from the KB + codebase + in-flight works with source citations; single-shot; captures knowledge gaps as Query-Gap entries in STATE.md Q&A (Pending) backlog (gap-capture write only — no KB doc or code file written) | `canonical/skills/aid-query-kb/SKILL.md` | 0 | (single-shot router; `allowed-tools: Read, Glob, Grep, Agent, Write, Edit`) |
| `aid-update-kb` | Optional on-demand targeted KB update skill OUTSIDE the numbered pipeline — applies a prompt-driven delta to KB docs through the review gate (ANALYZE→APPLY→REVIEW→APPROVAL→DONE, FIX loop inside REVIEW); commits only after explicit human approval; human-gated (no auto-apply path) | `canonical/skills/aid-update-kb/SKILL.md` | TBD | (`allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent`) |
| `generate-profile` (maintainer-only) | Render canonical/ → 5 install trees; LOAD → VALIDATE → RENDER → VERIFY → REPORT | `.claude/skills/generate-profile/SKILL.md` (NOT in `canonical/skills/` — see `.claude/skills/generate-profile/SKILL.md` `chicken-and-egg deployment problem` for the justification) | n/a — uses `scripts/*.py` instead | (renderer Python files — see §3) |

**Test coverage:**

- Helper scripts that skills invoke are covered by the per-script test suites in `tests/canonical/` (see §4).
- No direct unit tests for SKILL.md bodies themselves — they are state-router markdown read by Claude Code / Codex / Cursor at slash-command invocation; behavior is exercised indirectly through skill-level e2e runs.

**Key convention** (per `coding-standards.md §7b`): every `aid-*` SKILL.md is a state
router (≤~360 lines) that delegates per-state logic to `references/state-*.md`
files. The Dispatch table is the canonical state machine; advance follows one
of three forms (Unconditional / Halt / Conditional on a computed criterion).

**`document-expectations.md` — single per-doc expectations source:** The file
`canonical/skills/aid-discover/references/document-expectations.md` is the sole
authoritative specification of what `aid-reviewer` must look for in each KB doc
when dispatched from `aid-discover`. The reviewer loads it at dispatch time in both
REVIEW state (`state-review.md`) and FIX state (`state-fix.md`) via the
`{{DOCUMENT_EXPECTATIONS}}` placeholder in `reviewer-prompt.md`. No per-doc expectation
blocks live in `aid-reviewer/AGENT.md` or in any other file — all are consolidated in
this single reference.

---

## 2. Agents — `canonical/agents/<name>/`

9 specialist agent definitions. Each lives in its own subdirectory containing
`AGENT.md` (the agent contract) and `README.md` (the human-facing description).
Three tiers, per the `tier:` frontmatter field:

### 2a. Large tier (4) — heavy-lifting analysts, designers, reviewers

| Agent | Description (from AGENT.md frontmatter) | Path |
|-------|-----------------------------------------|------|
| `aid-interviewer` | One-question-at-a-time adaptive dialogue with stakeholders → REQUIREMENTS.md | `canonical/agents/aid-interviewer/AGENT.md` |
| `aid-architect` | Design-thinking specialist — produces SPEC.md, PLAN.md, task-NNN.md decomposition + execution graph; absorbs DESIGN-typed UX advisory | `canonical/agents/aid-architect/AGENT.md` |
| `aid-researcher` | Reads and analyzes code/docs/logs/APIs → structured KB / analysis documents (existing-state cataloguing, discovery, dependency mapping, telemetry interpretation) | `canonical/agents/aid-researcher/AGENT.md` |
| `aid-reviewer` | Adversarial quality evaluator — reviews any artifact (code, tasks, specs, plans, KB docs) against acceptance criteria / rubric; emits the 7-column issue ledger | `canonical/agents/aid-reviewer/AGENT.md` |

### 2b. Medium tier (4) — executors + release + routing

| Agent | Description | Path |
|-------|-------------|------|
| `aid-developer` | Implements, modifies, refactors, and build-verifies code from task files; raises IMPEDIMENT.md when spec contradicts reality | `canonical/agents/aid-developer/AGENT.md` |
| `aid-operator` | Runs final release verification, packages artifacts, creates PRs/release notes, manages releases, updates KB on ship | `canonical/agents/aid-operator/AGENT.md` |
| `aid-orchestrator` | Routes pipeline findings to the next phase/skill, enforces human gates, dispatches with context, manages parallel execution | `canonical/agents/aid-orchestrator/AGENT.md` |
| `aid-tech-writer` | Authors user-facing documentation — API docs, changelogs, READMEs, release notes, user guides — and reviews docs for quality/accuracy | `canonical/agents/aid-tech-writer/AGENT.md` |

### 2c. Small tier (1) — mechanical utility sub-agent (sub-agent-only)

| Agent | Purpose | Path |
|-------|---------|------|
| `aid-clerk` | Performs one mechanical, schema-bounded operation per dispatch — file extraction, template placeholder-fill, or glob enumeration — returning a markdown table/file with path+line evidence | `canonical/agents/aid-clerk/AGENT.md` |

**Dependencies (cross-agent):**

- Skills dispatch agents via the host's Agent/Task tool with `subagent_type` matching the `name:` field of `AGENT.md` (per `canonical/skills/aid-discover/SKILL.md` `## Dispatch` table).
- Agents call other agents only indirectly — through a wrapping skill or `aid-orchestrator`. There are no direct agent-to-agent Task tool calls in the canonical bodies.
- Every agent carries `## Heartbeat protocol` + `## Self-review discipline` blocks via `{{include:agent-boilerplate}}`, which is resolved at render time from `canonical/templates/agent-boilerplate.md`. The two protocol blocks are no longer macro-copied per-agent; they are factored into the shared include and injected by the renderer before the format-branch dispatch. `aid-clerk` (small-tier, mechanical) may omit the blocks per its narrow scope.

**Test coverage:** none direct. Agent contracts are exercised through skill-level e2e tests and via the canonical helper test suites (§4).

---

## 3. Generator (Python) — `.claude/skills/generate-profile/scripts/`

The generator lives in `.claude/skills/generate-profile/scripts/`, NOT in
`canonical/skills/`, because it CANNOT be regenerated from itself
(chicken-and-egg per `.claude/skills/generate-profile/SKILL.md` `chicken-and-egg deployment problem`). It is the only
Python in the repo.

**Path:** `.claude/skills/generate-profile/scripts/*.py` (7 files, incl. the `run_generator.py` entrypoint).

**Architecture (post work-005-profile-generator-simplify):** the generator is a
**single copy core** — `render.py` walks each canonical source tree and copies it
verbatim, applying a per-file *translate* only where a tool needs one. The old
per-type renderer scripts (`render_agents` / `render_skills` / `render_templates` /
`render_recipes` / `render_canonical_scripts`) and the two emitter self-tests
(`test_copilot_emitter` / `test_antigravity_emitter`) were **deleted** and folded
into `render.py`'s `copy_tree` pass. `render_profile()` copies exactly three trees:
`canonical/agents/` (translate=agents — frontmatter `tools:`/`model:` remap),
`canonical/skills/` (translate=skills — `allowed-tools:` remap + CC-optional strip),
and `canonical/aid/` (translate=none — verbatim; this subtree contains the former
templates / recipes / helper-scripts content, now copied byte-for-byte rather than
re-rendered). Codex's TOML agent format is a **dormant branch** in `render.py`
(`agent_format="toml"` -> `_render_codex_toml`), retained until E-CODEX-1 reaches
high confidence.

| File | Purpose | Key entry points |
|------|---------|------------------|
| `render.py` | The single copy core. `copy_tree(src, dst, profile, manifest, translate)` walks one canonical tree and copies every file, applying the per-file translate. translate=agents rewrites agent frontmatter (`tools:` remap via `_remap_tools`, `model:`/`reasoning_effort` resolution, `{{include:...}}` resolution); translate=skills rewrites `allowed-tools:` and strips Claude-Code-only fields; translate=none copies verbatim. Includes the **dormant** Codex-TOML branch (`_render_codex_toml`, gated on `agent_format="toml"`) and the YAML-lite frontmatter parser/serializer. | `render_profile(canonical_root, profile, manifest, output_base)`, `copy_tree(...)`, `_translate_agent`, `_rewrite_skill_frontmatter`, `_parse_frontmatter`, `_build_frontmatter_md`, `_render_codex_toml`, `_resolve_model`, `_resolve_includes` |
| `render_lib.py` | Shared utilities — `read_canonical_file`, `write_output_file`, `substitute_filenames`, `rewrite_install_paths` (FR5 Option (c) MINIMAL: single `{root}`-prefix substitution), `sha256_hex`, `EmissionManifest` (JSONL writer per `canonical/EMISSION-MANIFEST.md`) | `EmissionManifest.{add,diff,load,write}`, `sha256_hex`, `rewrite_install_paths`, `substitute_filenames` |
| `aid_profile.py` | Loads + validates a per-tool profile TOML (shrunk schema, work-005); surviving dataclasses `Profile` (`name`/`root_dir`/`root_file`/`agent_format`/`tool_names`/`model_tiers`/`capabilities`), `ModelTierSimple`, `ModelTierDetailed`, `CapabilitiesConfig` (`LayoutConfig`/`FrontmatterConfig`/`AgentConfig`/`SkillConfig`/`RuleEntry`/`ExtrasConfig` were dropped); `_KNOWN_AGENT_FORMATS = {markdown, toml}` (the `toml` value dormant for Codex; `copilot-agent`/`antigravity-rule` retired) | `load_profile(path)`, `validate(profile)`, `_KNOWN_AGENT_FORMATS` |
| `verify_deterministic.py` | VERIFY (deterministic) — strict; re-renders to a scratch dir via `render_profile` (single copy pass), compares byte-by-byte against committed install trees; non-zero exit if any drift | `run_verify(repo_root, report_path)`, `_render_all` |
| `verify_advisory.py` | VERIFY (advisory) — additional checks (frontmatter shape, install-path rewrites, etc.) | `run_advisory(repo_root, report_path)` |
| `test_manifest_safety.py` | Self-tests for the EmissionManifest deletion logic | (pytest-style; run standalone) |
| `run_generator.py` | Generator entrypoint — loads every `profiles/*.toml`, calls `render_profile` (single copy pass per profile), performs deletion pass via `EmissionManifest.diff`, writes manifest, runs VERIFY (deterministic) + VERIFY (advisory) | `for profile_path in sorted(profiles_dir.glob('*.toml'))`, `render_profile`, `manifest.diff`, `run_verify`, `run_advisory` |

**Dependencies:**

- Python 3.11+ (stdlib `tomllib` per `.claude/skills/generate-profile/scripts/aid_profile.py` `Requirements: Python 3.11+`).
- No third-party packages (no `requirements.txt`, no `pyproject.toml`; confirmed by repo-wide search).
- Every module inserts its own dir on `sys.path` (`_SCRIPT_DIR = Path(__file__).parent`) so `render.py`, `verify_deterministic.py`, and `run_generator.py` can `from render_lib import ...` / `from aid_profile import ...` / `from render import render_profile` regardless of CWD.
- `render.py` is imported by `run_generator.py` and `verify_deterministic.py` (both call `render_profile`); `render.py` in turn imports `aid_profile` + `render_lib`.

**Test coverage:**

- `render.py --self-test` runs 8 in-process tests (verbatim-copy byte-identity, two-run determinism per translate mode, tool_names remap), wired in CI (`.github/workflows/test.yml`).
- `test_manifest_safety.py` covers `EmissionManifest` round-trip + diff edge cases.
- `verify_deterministic.py` is itself a test — invoked after every render and exits non-zero on drift (per `run_generator.py` `run_verify`). It re-renders via `render_profile` and compares end-to-end against the committed trees; it also has a `--self-test` mode wired in CI.
- No standalone Python test runner configured (no `pytest.ini`, per project-structure.md §6). Tests are invoked manually per `tests/README.md`.

---

## 4. Helper scripts — `canonical/scripts/{config,kb,execute,summarize,interview,housekeep}/` + `grade.sh`

Bash (Shell) + Node (JavaScript) + PowerShell helpers consumed by skills at
slash-command invocation. Every script has 7 byte-identical copies on disk
(canonical + `.claude/aid/scripts/` dogfood + the 5 profile-tree scripts dirs:
`profiles/claude-code/.claude/aid/scripts/`, `profiles/codex/.codex/aid/scripts/`,
`profiles/cursor/.cursor/aid/scripts/`, `profiles/copilot-cli/.github/aid/scripts/`,
`profiles/antigravity/.agent/aid/scripts/`)
— verified by `verify_deterministic.py`. Repo totals are recorded in `.aid/generated/project-index.md`.

### 4a. `canonical/scripts/config/` — settings access

| Script | Purpose | Key flags |
|--------|---------|-----------|
| `read-setting.sh` | Reads a key from `.aid/settings.yml` with per-skill override resolution (skill.key → review.key → default) | `--skill X --key Y` (override-aware), `--path A.B` (direct), `--default V` |

### 4b. `canonical/scripts/kb/` — KB build + verification

| Script | Purpose |
|--------|---------|
| `build-project-index.sh` | Builds `.aid/generated/project-index.md` — used as the pre-pass shared input by the 5 discovery sub-agents |
| `build-kb-index.sh` | Builds `.aid/knowledge/INDEX.md` — agent-facing 2-3-line summary per KB doc, composed from each doc's `intent:` frontmatter (per Q12 resolution cycle-1: moved from `.aid/generated/` to `.aid/knowledge/`) |
| `build-metrics.sh` | Builds `.aid/generated/metrics.md` — T3 numeric facts (line counts, file counts, term counts, severity tallies per `canonical/templates/kb-authoring/tier-model.md` `### T3 — Metric`) |
| `discover-preflight.sh` | Pre-flight checks for `aid-discover` (verifies `.aid/knowledge/STATE.md` exists + not in Plan Mode) |

### 4c. `canonical/scripts/execute/` — task execution + parallel pool

| Script | Purpose |
|--------|---------|
| `writeback-state.sh` | Row-level write coordination for parallel pool dispatch (FR6) × per-area STATE writes; 4 modes (`--field`, `--findings`, `--block`, `--append-issue`); sentinel-file lock with retry — covered by `tests/canonical/test-writeback-state.sh` |
| `compute-block-radius.sh` | BFS over task dependency graph — computes the failure block radius when a task fails — covered by `tests/canonical/test-compute-block-radius.sh` |
| `complexity-score.sh` | Task complexity scoring (drives executor model tier selection) |

### 4d. `canonical/scripts/summarize/` — offline HTML KB viewer

| Script | Purpose |
|--------|---------|
| `validate-diagrams.mjs` | Mermaid diagram validation (largest JS file per `.aid/generated/project-index.md` `## Top 20 Largest Source Files`) |
| `grade-summary.sh` | Aggregates summarize-phase validators |
| `validate-html-output.sh` | HTML output validation |
| `manual-checklist.sh` | Manual verification prompts |
| `spot-check-facts.sh` | Spot-checks KB facts against source files |
| `writeback-state.sh` | Writes summarize-phase state back to `.aid/knowledge/STATE.md` |
| `contrast-check.mjs` | WCAG AA contrast ratio checker (Node) |
| `stale-check.sh` | Detects stale KB sections |
| `summarize-preflight.sh` | Summarize preflight |
| `fetch-mermaid.sh` | Fetches Mermaid CLI assets |
| `assemble-3part.ps1` / `assemble-3part.sh` | Per-host concatenation helpers (PowerShell for Windows, Bash elsewhere) |

### 4e. `canonical/scripts/interview/` — lite-path recipes

| Script | Purpose |
|--------|---------|
| `parse-recipe.sh` | Parses `canonical/recipes/*.md` recipe files (YAML front-matter + `## spec` / `## tasks` body blocks); 5 modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`) — covered by `tests/canonical/test-parse-recipe.sh` (largest test file) |

### 4f. `canonical/scripts/housekeep/` — `/aid-housekeep` stage helpers

Three deterministic, dependency-free (bash + grep/sed/awk only) helpers backing
the optional `aid-housekeep` skill (see §1). All are read-only or git-safe:
`branch-commit.sh` and `cleanup-classify.sh` each carry a self-check that aborts
if their own source ever contained a `git push` (and, for `cleanup-classify.sh`,
any `rm`/`git rm`/`git commit`) call.

| Script | Purpose | Key flags |
|--------|---------|-----------|
| `housekeep-state.sh` | Deterministic field I/O for the `## Housekeep Status` block of the project-level run-state file `.aid/.temp/HOUSEKEEP_STATE_<YYYYMMDDHHMM>.md` (transient/gitignored, created on first write — NOT a work-area STATE.md; 9 valid fields: State, Stage Status, Branch, Mode, Stall Reason, Last Run, KB Stage, Summary Stage, Cleanup Stage), plus `--resume` resolution implementing the 6-row resume-detection table (per `canonical/scripts/housekeep/housekeep-state.sh` `six-row re-entry table`): no section→PREFLIGHT (or CLEANUP with `--cleanup-only`); KB not passed/skipped→KB-DELTA; KB done + Summary not done→SUMMARY-DELTA; KB+Summary done + Cleanup not passed→CLEANUP; all done + State=DONE→DONE | `--state FILE --write --field F --value V`, `--read --field F`, `--resume [--cleanup-only]` |
| `branch-commit.sh` | Deterministic git branch/commit safety guard — `--ensure-branch` creates/switches `aid/housekeep-<slug>` off master (or reuses an existing `aid/housekeep-*` branch on resume; refuses any other non-master branch, exit 3); `--commit` stages + makes exactly ONE commit. Refuses to commit while on `master` (exit 3). NEVER runs `git push` (self-check exit 4 if its source ever contains one). | `--ensure-branch --slug S`, `--commit --message M [--add PATH ...] [--add-all]` |
| `cleanup-classify.sh` | Read-only scan + classify of stale `.aid/` artifacts across roots S1–S6 (.temp, .heartbeat, KB cache/scratch, stray verify reports, unregistered generated outputs, work-* folders) + Tier-2 loose `.aid/` files. Emits pipe-delimited `PATH\|TIER\|TRACKED\|DEFAULT_CHECKED\|REASON[\|GATE]` candidates; performs NO deletion/commit/push. Work folders: **every** `work-*/` folder is offered (merged+concluded → main checklist; otherwise → explicit per-folder confirm) — the user has the last word, nothing is silently hidden. The signal(i) merged / signal(ii) concluded checks are **informational context only** (shown in the prompt), not a gate. The single hard skip is the work folder whose `aid/work-NNN-*` branch is currently checked out; `HOUSEKEEP_STATE_*.md` is excluded from the .temp sweep; `settings.yml` is never touched. | `--root REPO_ROOT [--active-work FOLDER ...]` |

### 4g. `canonical/scripts/` (root)

| Script | Purpose |
|--------|---------|
| `grade.sh` | Deterministic grading: reads issue list with severity tags ([CRITICAL]/[HIGH]/[MEDIUM]/[LOW]/[MINOR]), applies the universal AID rubric (worst severity dominates, count modifies), prints letter grade. Used by reviewers + delivery gates. `--non-functional` flag forces F. |

**Test coverage:** currently 35 dedicated test suites under `tests/canonical/`, each invoked
manually or as a batch via `tests/run-all.sh` (recount with `ls tests/canonical/test-*.sh | wc -l`). Suites share helpers from
`tests/lib/assert.sh`. The installer/CLI/release suites are covered in Module 6e; a subset of helper-script suites:

| Test file | Covers |
|-----------|------|
| `tests/canonical/test-parse-recipe.sh` | `parse-recipe.sh` (largest suite) |
| `tests/canonical/test-writeback-state.sh` | `writeback-state.sh` 4 arg modes + lock-contention safety |
| `tests/canonical/test-delivery-gate-aggregate.sh` | delivery-gate aggregation |
| `tests/canonical/test-compute-block-radius.sh` | BFS block-radius |
| `tests/canonical/test-read-setting.sh` | settings 3-tier resolution |
| `tests/canonical/test-grade.sh` | `grade.sh` severity-tag → letter-grade scorer |
| `tests/canonical/test-fetch-mermaid.sh` | `fetch-mermaid.sh` pin + SHA verify |
| `tests/canonical/test-validate-diagrams.sh` | `validate-diagrams.mjs` (Node) |
| `tests/canonical/test-contrast-check.sh` | `contrast-check.mjs` WCAG AA contrast (Node) |
| `tests/canonical/test-assemble-3part.sh` | `assemble-3part.sh` byte-concat |
| `tests/canonical/test-assemble-3part-ps1.sh` | `assemble-3part.ps1` mirror (PowerShell) |
| `tests/canonical/test-install.sh` / `test-install-ps1.sh` / `test-install-parity.sh` | `install.sh` / `install.ps1` bootstrap + cross-platform parity |
| `tests/canonical/test-aid-cli.sh` / `test-aid-cli-ps1.sh` / `test-aid-cli-parity.sh` | `bin/aid` / `bin/aid.ps1` subcommand behavior + parity |
| `tests/canonical/test-release.sh` / `test-release-install-e2e.sh` | `release.sh` packaging + end-to-end release→install |
| `tests/canonical/test-discovery-doc-ownership.sh` | discovery agent doc-ownership consistency (scout vs quality) |
| `tests/canonical/test-expectations-single-source.sh` | `document-expectations.md` single-source + reviewer-has-access invariants |

See `tests/README.md` for the full suite list and run instructions.

---

## 5. Templates + Recipes — `canonical/templates/` + `canonical/recipes/`

Content fixtures consumed by skills + agents at runtime. The renderer copies them passthrough (no transform) into all 5 install trees.

### 5a. Templates — `canonical/templates/`

Organized into categories (per `project-structure.md` `## Templates (categories under \`canonical/templates/\`)`):

| Subdirectory | Files | Notable contents |
|--------------|-------|------------------|
| `delivery-plans/` | 1 | `task-template.md` — the 6-section task contract (Type / Source / Depends on / Scope / Acceptance Criteria) |
| `feedback-artifacts/` | 1 | `IMPEDIMENT.md` — formal escalation contract for developer↔orchestrator |
| `kb-authoring/` | 5 | `README.md`, `frontmatter-schema.md`, `principles.md` (P1-P7), `review-rubric.md`, `tier-model.md` (T1-T4) |
| `knowledge-base/` | 15 | Templates for the 14 standard-set KB docs (kept post-Q3 carve-out) + README. These templates form the default seed for `synth_default_seed` (delivery-002: doc-set-resolve.md §2.2 ownership map). This repo also uses the custom `repo-presentation.md` — no template exists for it in `canonical/templates/knowledge-base/` since it's a per-project customization declared via `discovery.doc_set` (per delivery-002, which resolved H5). |
| `knowledge-summary/` | 19+ | HTML/CSS/JS for the offline `knowledge-summary.html` viewer; `component-css.css` is the largest CSS file in the repo |
| `requirements/` | 1 | `requirements-template.md` |
| `specs/` | 2 | `lite-spec-template.md`, `spec-template.md` |
| `(top-level)` | 17 | `settings.yml`, `discovery-state-template.md`, `work-state-template.md`, `feature.md`, `recipe-template.md`, `subagent-heartbeat-protocol.md`, `long-wait-protocol.md`, `rough-time-hints.md`, `self-review-protocol.md`, `grading-rubric.md`, `reviewer-dispatch.md`, `delivery-issues.md`, `feature-inventory.md`, `generated-files.txt`, `known-issues.md`, `package.md`, `dispatch-protocol-checklist.md` |

### 5b. Recipes — `canonical/recipes/`

**51 recipes** under `canonical/recipes/` — pre-filled lite-path templates with
YAML front-matter + `{{slot}}` placeholders (per
`canonical/templates/recipe-template.md` `## Slot syntax`). Named `add-X` /
`change-X` / `fix-X`: 40 `add`/`change` pairs across 11 target-kind families
(`applies-to: new-feature` for `add-`, `refactor` for `change-`), 7 `fix-*`
bug-fix recipes (`applies-to: bug-fix`), 3 refactor-only verbs
(`improve-performance`, `bump-dependency`, `rename-symbol`), and 1 cross-type
recipe `add-test-coverage` (`applies-to: *`). See `canonical/recipes/README.md
## Seed Catalog` for the per-recipe table; `README.md` itself documents the
catalog and is not a recipe.

Consumed by `canonical/scripts/interview/parse-recipe.sh` during `/aid-interview` TRIAGE → recipe-offer (description→recipe matching uses each recipe's `summary:` field).

**Test coverage:** indirect — recipe behavior is exercised by `tests/canonical/test-parse-recipe.sh`. (`tests/skills/lite-subpaths.sh` was deleted in cycle-1 per Q6.)

---

## 6. Installer / CLI — `bin/` + `lib/` + `install.sh`/`install.ps1` + `packages/`

The end-user delivery surface (added by work-002-auto-installer). A persistent global `aid` CLI is bootstrapped once per machine into `$AID_HOME` (default `~/.aid` / `%LOCALAPPDATA%\aid`), then run per project. The CLI dispatches into a shared install-core engine; four install channels all deliver the same CLI.

### 6a. CLI dispatcher — `bin/`

| Component | Purpose | Depends on |
|-----------|---------|------------|
| `bin/aid` | Bash dispatcher. Parses subcommands (`add`/`status`/`update`/`remove`/`version`, bare → dashboard) + shared flags (`--from-bundle`, `--version`, `--force`, `--target`, `--verbose`), then sources + dispatches into `lib/aid-install-core.sh` (`bin/aid` `_aid_usage`, `source "$_AID_CORE"`). | `lib/aid-install-core.sh` |
| `bin/aid.ps1` | PowerShell dispatcher (Windows) — same subcommand surface. | `lib/AidInstallCore.psm1` |
| `bin/aid.cmd` | cmd.exe shim so `aid` resolves in cmd.exe and pwsh; tries `pwsh` then `powershell`, calling `bin/aid.ps1`. | `bin/aid.ps1` |

### 6b. Install-core libraries — `lib/`

| Component | Purpose | Consumers |
|-----------|---------|-----------|
| `lib/aid-install-core.sh` | The Bash install engine: status/add/update/remove bodies, release-asset download + SHA-256 verification against `SHA256SUMS`, manifest-driven remove, FR11 protect-on-diff (`*.aid-new`), the `AID_INSTALL_CHANNEL` per-channel `update self` hint. | `bin/aid`, `install.sh` (sourced in piped mode) |
| `lib/AidInstallCore.psm1` | The PowerShell parity module — same engine for Windows. | `bin/aid.ps1`, `install.ps1` |

### 6c. Bootstrap — `install.sh` / `install.ps1`

Repo-root curl/irm-piped bootstrap. In piped mode they fetch the `aid-cli-v<VERSION>.tar.gz` bundle from the matching GitHub Release, verify it against the release `SHA256SUMS`, extract into `$AID_HOME`, and wire PATH (`install.sh` `_source_install_core` + bundle-verify block; `AID_NO_PATH` skips PATH wiring). They also accept legacy project-install flags (`--from-bundle`, `--target`) as a fallback when `aid` is not yet on PATH.

### 6d. Channel shims — `packages/npm` + `packages/pypi`

Thin published wrappers that put the same `aid` CLI on PATH via a package manager. Each vendors the `bin/` + `lib/` payload and spawns `bin/aid` (Unix) or `bin/aid.ps1` (Windows), injecting `AID_INSTALL_CHANNEL`.

| Module | Purpose | Manifest |
|--------|---------|----------|
| `packages/npm/bin/aid.js` | npm `aid-installer` shim — spawns the vendored CLI with `AID_INSTALL_CHANNEL=npm`; runs on Node built-ins only (zero deps). Payload vendored at pack time by `packages/npm/scripts/vendor.js` (`prepack`). | `packages/npm/package.json` (`engines.node >=18`) |
| `packages/pypi/aid_installer/__main__.py` | PyPI `aid-installer` shim — spawns the vendored CLI with `AID_INSTALL_CHANNEL=pypi`. Payload vendored by `packages/pypi/scripts/vendor.py` (hatchling build hook). | `packages/pypi/pyproject.toml` (`requires-python >=3.8`, hatchling) |

### 6e. Release packager — `release.sh`

Maintainer-only. Verifies `profiles/` matches `canonical/` (reusing the render-drift gate), builds the five per-profile tarballs + the `aid-cli-v<VERSION>.tar.gz` CLI bundle + the two libs + `SHA256SUMS` under `.aid/.temp/release-<VERSION>/`, then `gh release create` (`release.sh` `build_tarball()`, `# Step 5: Build the CLI bundle tarball`). Driven in CI by `.github/workflows/release.yml` on a `v*` tag push.

**Test coverage:** `tests/canonical/test-install.sh` + `test-install-ps1.sh` + `test-install-parity.sh` (bootstrap), `test-aid-cli.sh` + `test-aid-cli-ps1.sh` + `test-aid-cli-parity.sh` (CLI subcommands), `test-release.sh` + `test-release-install-e2e.sh` (release packaging + end-to-end), `test-npm-installer.sh` + `test-pypi-installer.sh` (channel shims), `test-version-sync.sh` (FR10), `test-ascii-only.sh` (ASCII guard for shipped scripts), `test-agents-md-invariant.sh` (FR12), and the native-Windows `tests/windows/Test-AidInstaller.ps1`. All run by `.github/workflows/installer-tests.yml`.

---

## Cross-cutting dependencies

- **Skills → agents:** every multi-state skill dispatches one or more agents via the host's Agent/Task tool (per `canonical/skills/aid-discover/SKILL.md` `## Dispatch` table; per `canonical/skills/aid-execute/references/state-execute.md` `## Agent Selection` table mapping the 8 task types to executors).
- **Skills → scripts:** skills invoke helper scripts via Bash. Examples: `canonical/skills/aid-discover/SKILL.md` `discover-preflight.sh`, `aid-discover/SKILL.md` `read-setting.sh`, `aid-execute/references/state-delivery-gate.md` (`grade.sh`, `writeback-state.sh`); `aid-housekeep/SKILL.md` (`housekeep-state.sh`, `branch-commit.sh`, `cleanup-classify.sh`).
- **Agents → scripts:** agents invoke scripts indirectly (a skill dispatches the agent with a prompt containing the script call). No agent invokes a script except via its own Bash tool when authorized in its `tools:` frontmatter.
- **Renderer → everything:** the renderer reads `canonical/{agents,skills,templates,recipes,scripts}/`, applies the profile's transforms, writes into `profiles/{name}/<install_root>/`, and records every emission in `<install_root>/emission-manifest.jsonl`. The manifest is the SAFETY boundary for the next run's deletion pass (per `canonical/EMISSION-MANIFEST.md` `## Safety-Boundary Semantics`).
- **Verify → renderer:** `run_generator.py` (`run_verify` / `run_advisory`) calls `verify_deterministic.py` (strict) then `verify_advisory.py` (advisory) after every render. VERIFY (deterministic) re-runs the renderer to a scratch directory and compares byte-by-byte; any drift exits non-zero.

---

## Conventions

> How a new module of each class is added and wired into AID -- the registration steps an
> agent would otherwise get wrong. Each rule names its module class; the per-class detail
> lives in §1-§6 above.

- **Wiring a new skill (class 1):** create `canonical/skills/aid-<name>/SKILL.md` as a
  Thin-Router (`<=~360` lines) plus one `references/state-<state>.md` per state; the
  Dispatch table IS the canonical state machine. Add the skill to the user-facing count
  and reconcile the "N user-facing skills" tallies KB-wide via `/aid-housekeep` (never
  inline) -- a new skill drifts ~10 docs. Never hand-edit the rendered profile copies.
- **Wiring a new agent (class 2):** create `canonical/agents/aid-<name>/AGENT.md` with the
  `tier`/`tools` frontmatter and the `{{include:agent-boilerplate}}` body; register it in
  the relevant skill's `## Dispatch` / `## Agent Selection` table so a skill can dispatch it.
- **Wiring a new helper script (class 4):** place it under the matching
  `canonical/scripts/{config,kb,execute,summarize,interview,housekeep}/` subdir, kebab-case
  `verb-noun.sh`; invoke it from the skill via Bash (skills -> scripts is the only call
  edge -- agents reach scripts only through a dispatching skill's prompt). A generated
  script is registered in `canonical/templates/generated-files.txt`.
- **Adding a template/recipe (class 5):** kebab-case `.md` under `canonical/templates/` or
  `canonical/recipes/`; recipes are listed in the README Seed Catalog.
- **Touching the installer/CLI (class 6):** shipped `bin/`, `lib/`, `install.*` scripts stay
  ASCII-only and Windows-PowerShell-5.1-compatible (CI-guarded).

---

## Invariants

> What MUST always hold about the module structure. Violating one of these silently breaks
> the render pipeline or the isolation guarantee.

- **Canonical is the single source of truth:** every module under
  `profiles/{...}/` and the dogfood `.claude/` tree is byte-identical *output* of the
  generator from `canonical/`. A profile copy MUST NEVER be hand-edited; the fix goes in
  `canonical/` and is re-rendered. `verify_deterministic.py` enforces this byte-for-byte.
- **The emission manifest is the deletion safety boundary:** the generator may only prune
  files it previously emitted (recorded in `<install_root>/emission-manifest.jsonl`); it
  MUST NOT delete user content. Orphan-pruning is by the `aid-` prefix only.
- **Dependency direction is one-way:** skills dispatch agents and invoke scripts; agents
  do not invoke scripts except via a dispatching skill's prompt; scripts never dispatch
  agents. No cycle in the skill -> agent / skill -> script edges.
- **`generate-profile` lives only in `.claude/`, never in `canonical/skills/`:** rendering
  the renderer into the profiles it renders is the chicken-and-egg case it is exempt from.
- **All AID-delivered modules are `aid-`-namespaced / isolated from user content:** skill and
  agent directories carry the `aid-` prefix so orphan-prune and collision-avoidance work
  (content-isolation cornerstone).
