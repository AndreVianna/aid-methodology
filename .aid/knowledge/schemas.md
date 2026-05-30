---
kb-category: primary
source: hand-authored
intent: |
  Documents the document-and-config schemas that AID treats as its "data model":
  .aid/settings.yml, the per-area STATE.md (discovery + work) markdown shapes,
  the frontmatter contracts for SKILL.md / AGENT.md / KB docs, the emission-
  manifest JSONL schema, the recipe + task templates, and the work-area
  filesystem layout. There is NO relational database in AID — the project ships
  methodology + tooling, no application. Read this when authoring or modifying
  any of the above structured documents. NOT a module map (see module-map.md)
  and NOT a coding-conventions reference (see coding-standards.md).
contracts:
  - "Settings file = .aid/settings.yml, YAML 1.2, with 5 mandatory top-level sections (project, tools, review, execution, traceability)"
  - "Discovery KB has 15 active primary documents post-cycle-1 Q3 carve-out (14 from the standard 16-doc set minus security-model and ui-architecture, plus repo-presentation custom doc)"
  - "Emission manifest is JSON-Lines (.jsonl) with 4-key record schema (profile, src, dst, sha256) + 1-key sentinel object {_manifest_version: 1}"
  - "Frontmatter schema for KB docs requires kb-category + source + intent; generator required iff source=generated"
  - "Recipe slot syntax: {{slot-name}} where slot-name matches POSIX ERE [a-z][a-z0-9-]*"
  - "Task templates have 6 sections: title heading, Type, Source, Depends on, Scope, Acceptance Criteria"
changelog:
  - 2026-05-27: Initial generation by discovery-analyst (cycle-1)
---

# Schemas

> **There is no database.** AID is a methodology + multi-tool distribution; it
> ships skills, agents, templates, recipes, and helper scripts. Every "schema"
> below is a document or config contract — YAML, JSONL, or structured Markdown —
> that the pipeline reads + writes.

## 1. Database

| Property | Value |
|----------|-------|
| **Type** | None — no DB. AID ships no application; state lives in filesystem documents. |
| **Persistent state** | `.aid/` directory tree (settings, knowledge base, per-work state, generated artifacts) |
| **Ephemeral state** | `.aid/.heartbeat/` (subagent heartbeat files, gitignored per `.gitignore:47`), `.aid/.temp/` (skill scratch / review-pending ledgers) |
| **Cache** | `.aid/knowledge/.cache/` (Mermaid library cache for `aid-summarize`; gitignored per `.gitignore:40`) |
| **Configs (non-runtime)** | `profiles/*.toml` (generator profiles), `.claude/settings.json` (Claude Code permissions) |

---

## 2. Settings — `.aid/settings.yml`

**Source of truth:** `canonical/templates/settings.yml` → rendered identically into all 3 install trees and copied to `.aid/settings.yml` by `/aid-config` on first run.

**Schema (YAML 1.2, per `canonical/templates/settings.yml:1-82`):**

| Path | Type | Default | Purpose |
|------|------|---------|---------|
| `project.name` | string | `<project-name>` | Set during `/aid-config` INIT |
| `project.description` | string | `<project-description>` | Sole source of truth (not duplicated in CLAUDE.md/AGENTS.md per settings.yml:16) |
| `project.type` | enum `brownfield`|`greenfield` | `brownfield` | Project class |
| `tools.installed` | list of strings | `[claude-code]` | Which install trees are active; valid values: `claude-code`, `codex`, `cursor` |
| `review.minimum_grade` | grade string | `A` | Quality bar for every skill's REVIEW state |
| `execution.max_parallel_tasks` | int | `5` | Parallel pool dispatch capacity (FR6 / work-001 feature-009) |
| `traceability.heartbeat_interval` | int (minutes) | `1` | L3 heartbeat interval; `0` disables heartbeat entirely |
| `<skill>.minimum_grade` | grade string | — | Optional per-skill override; falls back to `review.minimum_grade` |

**Grade enum** (per `canonical/templates/settings.yml:58`):
```
A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F
```

**Per-skill override skills** (per `canonical/templates/settings.yml:63-81`):
`discover`, `summary`, `interview`, `specify`, `plan`, `detail`, `execute`,
`deploy`, `monitor` — each may set `minimum_grade:`.

**Resolution helper:** `canonical/scripts/config/read-setting.sh` implements
the per-skill override → global default → hardcoded `--default` fallback
(per its header comment `read-setting.sh:4-17`).

---

## 3. Discovery State — `.aid/knowledge/STATE.md`

**Source of truth:** `canonical/templates/discovery-state-template.md`.

**Purpose:** the per-area state hub for the Discovery area (per FR2 area-state
consolidation — see `coding-standards.md §7e`). Absorbs former `DISCOVERY-STATE.md` +
`SUMMARY-STATE.md`.

**Schema (Markdown, per `canonical/templates/discovery-state-template.md:1-89`):**

| Section | Shape | Cardinality |
|---------|-------|-------------|
| Top-level metadata (blockquote) | `Source:`, `Status:` (Initial / In Progress / Approved), `Current Grade:`, `User Approved:`, `Last KB Review:`, `Last Summary:` | 1 |
| `## External Documentation` | Table: `Path | Type | Accessible | Notes` | 1 table |
| `## KB Documents Status` | Table: `# | Document | Status | Grade | Last Reviewed | Notes` | One row per active primary KB doc (currently 15 primary docs per `canonical/skills/aid-discover/SKILL.md:145-149`) |
| `## Knowledge Summary Status` | Table: `Field | Value` with 10 fields (Profile, Profile Source, Profile Confidence, Theme, Machine Grade, Human Grade, User Approved, Last Run, Output, Mermaid Version, Mermaid Cached) | 1 table |
| `## Q&A (Pending)` | One `### Q{N}` block per entry with sub-bullets: `Category`, `Impact`, `Status`, `Context`, `Suggested`, `Answer` (Style A per `coding-standards.md §12`) | 0..N |
| `## Review History` | Append-only table: `# | Date | Grade | Source | Notes` | 1..N |
| `## Summarization History` | Append-only table: `# | Date | Grade | Profile | Mermaid | Output | Notes` | 1..N |

**15 active KB documents** (post-Q3 FIX):
project-structure, external-sources, architecture, technology-stack, module-map,
coding-standards, schemas (was data-model), pipeline-contracts (was api-contracts), integration-map, domain-glossary,
test-landscape, tech-debt, infrastructure, repo-presentation,
feature-inventory.

---

## 4. Work State — `.aid/work-NNN-{name}/STATE.md`

**Source of truth:** `canonical/templates/work-state-template.md`.

**Purpose:** the single per-area state hub for one work item; absorbs former
`INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md`
× N + (future) `DEPLOYMENT-STATE.md` per `work-state-template.md:9-12`.

**Schema (Markdown):**

| Section | Shape | Cardinality |
|---------|-------|-------------|
| Top-level metadata (blockquote) | `Status:`, `Phase:`, `Minimum Grade:`, `Started:`, `User Approved:` | 1 |
| `## Triage` | Bullets: `Path:` (lite/full), `Work Type:` enum, `Sub-path:` enum, `Sub-path (auto):`, `Decision rationale:`, `Override:`, `Recipe:` | 1 |
| `## Escalation Carry` | Conditional — only when work was escalated from lite to full | 0 or 1 |
| `## Interview Status` | Table: 10 standard sections (Objective / Problem Statement / Users & Stakeholders / Scope / Functional Requirements / Non-Functional Requirements / Constraints / Assumptions & Dependencies / Acceptance Criteria / Priority) with Status + Last Updated | Fixed 10 rows |
| `## Features Status` | Table: `# | Feature | Spec Status | Spec Grade | Q&A Count | Notes` | 0..N |
| `## Plan / Deliveries` | Table: `Delivery | Status | Tasks | Notes` | 0..N |
| `## Tasks Status` | Table: `# | Task | Type | Wave | Status | Review | Elapsed | Notes` | 0..N |
| `## Deploy Status` | Table: `Delivery | State | PR | KB Updated | Tag | Notes` | 0..N |
| `## Cross-phase Q&A (Pending)` | Free-form Q-blocks (same shape as discovery-state Q&A) | 0..N |
| `## Delivery Gates` | Free-form per-delivery blocks: `Reviewer Tier`, `Grade`, `Issue List`, `Timestamp` | 0..N |
| `## Quick Check Findings` | Free-form per-task blocks: `Reviewer Tier`, `Findings` list with severity tags | 0..N |
| `## Lifecycle History` | Append-only table: `Date | Phase Transition / Gate | Grade | Notes` | 1..N |

**Triage enum values** (per `work-state-template.md:18-22`):

- `Path:` ∈ {`lite`, `full`}
- `Work Type:` ∈ {`bug-fix`, `single-doc`, `small-refactor`, `small-new-feature`} (omitted for full path)
- `Sub-path:` ∈ {`LITE-BUG-FIX`, `LITE-DOC`, `LITE-REFACTOR`, `LITE-FEATURE`, `—`}
- `Override:` ∈ {`yes`, `no`}

**Task `Type` enum** (per `work-state-template.md:80-85` + `canonical/templates/delivery-plans/task-template.md:3`):
8 values — `RESEARCH`, `DESIGN`, `IMPLEMENT`, `TEST`, `DOCUMENT`, `MIGRATE`, `REFACTOR`, `CONFIGURE`.

**Quick-Check finding severity enum** (per `work-state-template.md:128-129`):
`[CRITICAL]` (Fixed-on-spot), `[HIGH]` (Deferred-to-gate); no `[MEDIUM]` /
`[LOW]` / `[MINOR]` appear in quick-check (they remain inline in the broader
delivery gate per `canonical/scripts/grade.sh:5-7`).

---

## 5. KB Document Frontmatter

**Source of truth:** `canonical/templates/kb-authoring/frontmatter-schema.md`.

**Schema (YAML, delimited by `---` markers as the FIRST content in the file):**

| Field | Type | Required? | Allowed values |
|-------|------|-----------|----------------|
| `kb-category` | enum | YES | `primary` / `meta` / `extension` (per frontmatter-schema.md:50-54) |
| `source` | enum | YES | `hand-authored` / `generated` (per frontmatter-schema.md:62-65) |
| `generator` | string | YES iff `source: generated` | Build-script name relative to `canonical/scripts/` (per frontmatter-schema.md:70-74) |
| `intent` | folded string (YAML `|`) | YES | 1-4 sentences describing what the doc is FOR (per frontmatter-schema.md:76-89) |
| `contracts` | list of strings | NO (defaults to `[]`) | Each entry is a structural cardinality assertion validated by the `discovery-reviewer` in REVIEW state (per `canonical/agents/discovery-reviewer/AGENT.md`; spec at frontmatter-schema.md:104-127) |
| `changelog` | list of dated entries | NO (defaults to `[]`) | Free-form ISO-dated notes; exempt from review (per frontmatter-schema.md:129-147) |

**Parsing rules** (per frontmatter-schema.md:161-169):

- Block MUST be the first content (no whitespace, no BOM, no comments before).
- Opening + closing `---` on their own lines.
- Body MUST be valid YAML 1.2.
- Missing fields default-empty.
- Unknown fields tolerated (forward-compatible).
- Parse failure → doc treated as `kb-category: primary, source: hand-authored` with empty intent/contracts/changelog + lint emits HIGH-severity warning.

**Per-doc review treatment** (per `canonical/templates/kb-authoring/review-rubric.md:8-21`): the combination of `kb-category` and `source` selects one of six rubrics — Full Primary (hand-authored), Full Primary + Build-Verify (generated INDEX.md), Spot-Check Snapshot (meta hand-authored), Build-Verify Only (meta generated, e.g., metrics.md / project-index.md), Extension-Scope, Extension Build-Verify.

---

## 6. Skill Frontmatter

**Source of truth:** `canonical/skills/*/SKILL.md` (10 user-facing + 1 maintainer-only) + `profiles/claude-code.toml:30-36` (skill frontmatter schema declaration).

**Schema (YAML, per `profiles/claude-code.toml:30-36`):**

| Field | Type | Required? | Notes |
|-------|------|-----------|-------|
| `name` | string | YES | Matches the skill directory name (e.g., `aid-discover`) |
| `description` | folded string (YAML `>`) | YES | One paragraph describing the skill's purpose + state-machine summary |
| `allowed-tools` | comma-separated string | YES | Subset of `Read, Glob, Grep, Bash, Write, Edit, Agent, AskUserQuestion` |
| `argument-hint` | string | NO | Brief flag description shown by the host's slash-command help |
| `context` | string | NO (claude-code-only) | Injected by renderer for Claude Code (per `profiles/claude-code.toml:36`) |
| `agent` | string | NO (claude-code-only) | Injected by renderer for Claude Code |

**Renderer behavior** (per `.claude/skills/aid-generate/scripts/render_skills.py:64-79`):

- Tool name remapping applied to `allowed-tools:` line via the profile's `[tool_names]` table (identity map for Claude Code per `profiles/claude-code.toml:43-46`).
- `claude_code_optional` fields are dropped from non-Claude-Code renders.

---

## 7. Agent Frontmatter

**Source of truth:** `canonical/agents/*/AGENT.md` (22 agents) + `profiles/claude-code.toml:17-24`.

**Schema (YAML, per `profiles/claude-code.toml:17-24`):**

| Field | Type | Required? | Notes |
|-------|------|-----------|-------|
| `name` | string | YES | Kebab-case, matches the directory name; used as `subagent_type` in the host's Task tool call |
| `description` | string OR folded YAML `>` | YES | One paragraph; for sub-agent-only utilities, must begin with `INTERNAL UTILITY (sub-agent only — do NOT invoke from a skill)` per `canonical/agents/simple-extractor/AGENT.md:3` |
| `tier` | enum | YES (canonical) | `large` / `medium` / `small` — maps to `model:` via the profile's `[model_tiers]` table |
| `tools` | comma-separated string | YES | Subset of `Read, Glob, Grep, Bash, Write, Edit` |
| `model` | string | YES (rendered output, NOT canonical input) | Derived by the renderer from `tier:` via `[model_tiers]` (per `.claude/skills/aid-generate/scripts/render_agents.py`) |
| `permissionMode` | enum | NO | `bypassPermissions` — set on all 5 `discovery-*` sub-agents (per `canonical/agents/discovery-analyst/AGENT.md:6`) |
| `background` | bool | NO | `true` — set on all 5 `discovery-*` sub-agents (per `canonical/agents/discovery-analyst/AGENT.md:7`) |

**Tier → model mapping** (per `profiles/claude-code.toml:38-41`):
- `large` → `opus`
- `medium` → `sonnet`
- `small` → `haiku`

Codex uses a `[model_tiers.<tier>]` sub-table with `model` + `reasoning_effort` fields (per `.claude/skills/aid-generate/scripts/profile.py:137-141` `ModelTierDetailed`).

---

## 8. Emission Manifest — `<install-tree>/emission-manifest.jsonl`

**Source of truth:** `canonical/EMISSION-MANIFEST.md`.

**Purpose:** authoritative safety boundary for the generator's pure-mirror deletion logic (per `canonical/EMISSION-MANIFEST.md:5-13`). Every file the generator emits is recorded; only manifest-tracked paths are eligible for deletion.

**Format:** JSON-Lines (`.jsonl`); one record per line, LF-only line endings even on Windows (per `EMISSION-MANIFEST.md:51-56`).

**Record schemas:**

**Sentinel object** (first line of every manifest):
```json
{"_manifest_version": 1}
```

**Data record** (lines 2..N):

| Key | Type | Description |
|-----|------|-------------|
| `profile` | string | Profile name — one of `claude-code`, `codex`, `cursor` (per `EMISSION-MANIFEST.md:38`) |
| `src` | string | Repo-relative path inside `canonical/` |
| `dst` | string | Path inside the install tree, relative to the manifest's directory |
| `sha256` | string | Lowercase hex SHA-256 of the rendered file's bytes |

**Ordering** (per `EMISSION-MANIFEST.md:46-49`): records sorted lexicographically by `dst` before writing.

**One manifest per profile** at the deepest common parent (per `EMISSION-MANIFEST.md:16-27`):

| Profile | Manifest path |
|---------|---------------|
| `claude-code` | `profiles/claude-code/emission-manifest.jsonl` |
| `codex` | `profiles/codex/emission-manifest.jsonl` (covers BOTH `.codex/` and `.agents/` split roots) |
| `cursor` | `profiles/cursor/emission-manifest.jsonl` |

**Safety-boundary algorithm** (per `EMISSION-MANIFEST.md:70-83`):

1. Load previous run's committed manifest.
2. Render — add each emitted path to current in-memory manifest.
3. Diff: compute `added_dst` (no action), `removed_dst` (delete from disk), `changed_dst` (overwrite via renderer).
4. Delete each path in `removed_dst`; prune empty parents within the generator-owned subtree.
5. Write current manifest to disk.

Files **outside** any manifest are NEVER touched.

---

## 9. Profile TOML — `profiles/*.toml`

**Source of truth:** `profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml`.

**Schema (TOML 1.0, parsed by `.claude/skills/aid-generate/scripts/profile.py:_parse_layout` etc.):**

| Section | Keys | Purpose |
|---------|------|---------|
| `[layout]` | `output_root` (single-root tools), `agents_root` + `assets_root` (split-root Codex), `agents_dir`, `skills_dir`, `templates_dir`, `recipes_dir`, `scripts_dir`, `rules_dir` (Cursor only), `project_context_file` | Where rendered files go |
| `[agent]` | `format` ∈ {`markdown`, `toml`} | Per-tool agent output format |
| `[agent.frontmatter]` | `required` list, `optional` list, `claude_code_optional` list | Which frontmatter keys are required/optional in agent output |
| `[skill]` | `decomposition` (always `"references"` per Decision F per `profile.py:127`) | Skill body decomposition strategy |
| `[skill.frontmatter]` | `required` list, `optional` list, `claude_code_optional` list | Same as agent frontmatter |
| `[model_tiers]` | `large`, `medium`, `small` — string OR sub-table | Tier-to-model mapping |
| `[tool_names]` | flat map, e.g., `Read = "read_file"` | Per-tool tool-name remapping (identity for Claude Code per `claude-code.toml:43-46`) |
| `[filename_map]` | `project_context_file`, `reviewer_output_file`, `open_questions_file` | Per-tool placeholder substitutions for `{project_context_file}` etc. |
| `[extras]` | varies; for Cursor includes `[[extras.rules]]` array of `{filename, always_apply, description, globs}` | Tool-specific extras |
| `[capabilities]` | `hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue` (booleans) | Tool capabilities (verified against host docs) |

The dataclasses mirror this schema 1:1 in `.claude/skills/aid-generate/scripts/profile.py:28-192`.

---

## 10. Recipe Front-Matter + Body — `canonical/recipes/*.md`

**Source of truth:** `canonical/templates/recipe-template.md` +
`canonical/scripts/interview/parse-recipe.sh`.

**Front-matter schema (YAML, all fields required per `recipe-template.md:81-86`):**

| Field | Type | Validation |
|-------|------|------------|
| `name` | string (kebab-case) | Must match the file basename without `.md` |
| `applies-to` | enum | One of `bug-fix`, `small-refactor`, `single-doc`, `small-new-feature`, or `*` (matches any workType — use sparingly per `recipe-template.md:170-172`) |
| `slot-count` | integer | Count of unique `{{slot-name}}` tokens in body; parser warns on mismatch |
| `task-count` | integer | Count of `### task-NNN` headings in `## tasks` block; parser warns on mismatch |

**Body schema** (per `recipe-template.md:129-167`):

- `## spec` block (lowercase intentional per `recipe-template.md:136-138`) — becomes the rendered `.aid/work-NNN/SPEC.md`. Must include sections: `# {title}`, metadata block (4 bold key/value lines: Work / Created / Source / Status), `## Goal`, `## Context`, `## Acceptance Criteria`, `## Tasks` (table), `## Execution Graph` (two tables), `## Revision History`.
- `## tasks` block — one `### task-NNN — Title` heading per task; renders one `task-NNN.md` per heading.

**Slot syntax** (per `recipe-template.md:96-100`):

- Slots written as `{{slot-name}}` anywhere in body.
- Slot names match POSIX ERE `[a-z][a-z0-9-]*` — lowercase ASCII letter first, then lowercase letters / digits / hyphens.
- No underscores, no uppercase, no dots, no spaces.

**Escape** (per `recipe-template.md:108-114`): `{!{` renders as literal `{{` at emit time without being treated as a slot token. Use when a recipe body discusses AID slot syntax as content.

**Parser modes** (per `canonical/scripts/interview/parse-recipe.sh:14-58`): `--list`, `--validate`, `--spec`, `--tasks`, `--render --recipe X --slots-json Y --work-dir Z`.

---

## 11. Task Template — `canonical/templates/delivery-plans/task-template.md`

**Source of truth:** `canonical/templates/delivery-plans/task-template.md`.

**Schema (Markdown, 6 sections — flat, no nesting):**

1. `# task-NNN: {Title}` — heading
2. `**Type:**` — one of 8 enum values (RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE)
3. `**Source:**` — `feature-NNN-{name} → delivery-NNN`
4. `**Depends on:**` — `task-NNN[, task-NNN]` or `— (none)`
5. `**Scope:**` — bullet list, type-dependent
6. `**Acceptance Criteria:**` — checklist bullets

**Invariants** (per `task-template.md:19`):
- Six sections, nothing else.
- One Type per task; never mix.
- Every task except the first declares at least one `Depends on` entry.

---

## 12. Delivery Issues Log — `.aid/work-NNN/delivery-NNN-issues.md`

**Source of truth:** `canonical/templates/delivery-issues.md`.

**Purpose:** aggregates all `[HIGH]` findings deferred from per-task quick-checks. Input to the delivery-gate reviewer (per `delivery-issues.md:11-13`).

**Schema (Markdown, single table):**

```
| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-NNN    | [HIGH]   | ...         | Open   |
```

**Column constraints** (per `delivery-issues.md:25-34`):

- `Source task` — the `task-NNN` that generated the finding.
- `Severity` — always `[HIGH]` (`[CRITICAL]` findings are fixed on-the-spot; never deferred).
- `Description` — one-line summary matching the original quick-check finding.
- `Status` ∈ {`Open`, `Resolved`, `Accepted`}.

**Writer:** `canonical/scripts/execute/writeback-task-status.sh --append-issue` (sentinel-lock concurrent-safe per `writeback-task-status.sh:42-50`).

---

## 13. IMPEDIMENT Schema — `.aid/{work}/task-NNN/IMPEDIMENT.md`

**Source of truth:** `canonical/templates/feedback-artifacts/IMPEDIMENT.md`.

**Schema (Markdown):**

| Section | Shape | Required |
|---------|-------|----------|
| Header blockquote | `Generated by`, `Task`, `Date`, `Status` (Open / Escalated / Resolved / No Action) | YES |
| `## Summary` | One sentence | YES |
| `## Type` | Checkbox — exactly one of: `wrong-assumption`, `missing-dependency`, `architecture-conflict`, `kb-gap` (per IMPEDIMENT.md:20-23) | YES |
| `## Source` | `Task:`, `Phase:`, `File encountered:` | YES |
| `## What Was Found` | Expected vs. Actual code blocks + Evidence block | YES |
| `## KB Impact` | `Document:`, `Section:`, `Current content:`, `Correct content:` | Conditional (when `kb-gap`) |
| `## Options` | One `### Option A: {Name}` per option with `Approach`, `Effort` (S/M/L/XL), `Risk`, `Scope impact`, `Spec impact` | YES, ≥ 2 options |

---

## 14. Generated-Files Registry — `canonical/templates/generated-files.txt`

**Source of truth:** `canonical/templates/generated-files.txt`.

**Purpose:** registry of every file in `.aid/generated/` with its build command. Consumed by `/aid-discover` FIX state (refresh-all at end of cycle per P3) and by the `discovery-reviewer` in REVIEW state (freshness check).

**Format** (per `generated-files.txt:3-13`):

```
<output-path>|<build-command>
```

- `output-path` — relative to the target project root (where `.aid/` lives).
- `build-command` — shell command to regenerate, run from the target project root.
- Comments (lines starting with `#`) and blank lines are ignored.
- Order matters: scripts are executed top-to-bottom; list dependencies first.

**Path-rewriting convention** (per `generated-files.txt:16-26`): build commands cite repo-root paths under `canonical/`. The renderer (`run_generator.py` + `rewrite_install_paths` in `harness.py`) rewrites those at render time to each profile's install-tree root (`.claude` for Claude Code, `.agents` for Codex assets, `.cursor` for Cursor). Comment blocks at the top of the file are skipped by the rewriter so the prose survives intact in profile renders.

**Currently registered** (per `generated-files.txt:30,34,39`): `.aid/generated/project-index.md` (`build-project-index.sh`), `.aid/generated/metrics.md` (`build-metrics.sh`), `.aid/knowledge/INDEX.md` (`build-index.sh`). Note: INDEX.md lives under `.aid/knowledge/`, not `.aid/generated/` — per Q12 resolution (cycle-1) it was moved to sit alongside the KB docs it indexes.

---

## 15. Filesystem Layout (logical ER)

This is the closest the project has to a "relationship diagram" — each work item, each KB document, each emission tree relates to others via shared identifiers + paths.

```mermaid
erDiagram
    PROJECT ||--|| SETTINGS_YAML : "configures"
    PROJECT ||--|| DISCOVERY_STATE : "tracks"
    DISCOVERY_STATE ||--o{ KB_DOC : "lists active primary docs"
    PROJECT ||--o{ WORK : "contains"
    WORK ||--|| WORK_STATE : "tracks"
    WORK ||--|| REQUIREMENTS : "produces"
    WORK ||--o{ FEATURE : "decomposes into"
    FEATURE ||--|| FEATURE_SPEC : "specified by"
    WORK ||--|| PLAN : "planned by"
    PLAN ||--o{ DELIVERY : "groups"
    DELIVERY ||--o{ TASK : "decomposes into"
    TASK ||--o| IMPEDIMENT : "may raise"
    DELIVERY ||--o| DELIVERY_ISSUES : "aggregates HIGH"
    PROJECT ||--o{ INSTALL_TREE : "renders to"
    INSTALL_TREE ||--|| EMISSION_MANIFEST : "tracks"
    EMISSION_MANIFEST ||--o{ EMITTED_FILE : "records"
```

**Identifier conventions** (per `coding-standards.md` §2d):

- `work-NNN` — zero-padded 3-digit, optional kebab suffix (e.g., `work-001`, `work-002-canonical-generator`)
- `feature-NNN` — zero-padded 3-digit (e.g., `feature-005`)
- `delivery-NNN` — zero-padded 3-digit (e.g., `delivery-001`)
- `task-NNN` — zero-padded 3-digit (e.g., `task-019`)
- `Q{N}` — Q&A entry (NOT zero-padded; per `discovery-state-template.md:65`)

**Foreign keys** are textual: task → delivery via `task.Source = "feature-NNN → delivery-NNN"` (per `task-template.md:5`); feature → work via `feature.Source = "REQUIREMENTS.md §5.{n}"` (per `feature.md:8-12`).

---

## 16. No Migrations, No Indexes, No Soft Deletes

| Aspect | Status |
|--------|--------|
| **Migrations** | N/A — no DB. Document schema changes are tracked via the per-doc `changelog:` frontmatter field (per `frontmatter-schema.md:129-147`) + KB doc cycle history in `STATE.md ## Review History`. |
| **Indexes** | N/A — no DB. The closest analog is `.aid/knowledge/INDEX.md` — an agent-facing RAG navigation index built by `canonical/scripts/kb/build-index.sh` from each KB doc's `intent:` frontmatter. |
| **Soft Deletes** | N/A — no DB. The emission-manifest's `removed_dst` set serves a related purpose: only paths previously emitted by the generator are eligible for deletion (per `EMISSION-MANIFEST.md:70-83`); user-created files are NEVER touched. |
| **Validation** | Three mechanisms: (1) `discovery-reviewer` sub-agent (in `/aid-discover REVIEW`) validates KB frontmatter + cited file:line + doc presence + generated-files freshness; (2) `.claude/skills/aid-generate/scripts/profile.py:validate()` validates profile TOML; (3) `parse-recipe.sh --validate` validates recipe front-matter + body. |

---

## 17. Data Volume

T3 numeric volume facts (file counts + line counts per language and per category) live in `.aid/generated/project-index.md` and `.aid/generated/metrics.md`. They are intentionally not duplicated here — those generated files are regenerated from disk on every discovery cycle so any inline copy would drift.

**Volume shape note (T1):** every canonical asset is multiplied ~4x by the renderer (canonical + 3 install trees + dogfood `.claude/`), so the headline file count overstates unique content by roughly 4x (per project-structure.md:296).
