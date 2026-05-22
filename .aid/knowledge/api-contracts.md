# API Contracts

> **Source:** aid-discover (discovery-integrator)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21

> **Note:** This repository ships **no HTTP/RPC/GraphQL/gRPC API**. It is a methodology + install-payload distribution. The "contracts" documented here are the **file-format contracts** AID has with each host AI coding tool (Claude Code, Codex CLI, Cursor) and the **inter-phase artifact contracts** AID uses internally between its own pipeline stages.

## Exposed APIs

**None.** No HTTP listener, RPC server, GraphQL endpoint, WebSocket, gRPC service, message-queue producer, or webhook receiver exists in this repository. Verified by negative search: no `app.js`, `server.py`, `*Controller.cs`, `package.json` with an `express`/`fastify`/`koa` dependency, no `*.proto`, no `openapi.yaml`, no `Dockerfile`, no Kubernetes manifest (see `project-structure.md` "Build / Test / CI" and "Detected Languages and Frameworks").

The closest thing to an "API" is the installer's interactive menu (`setup.sh` lines 1-161, `setup.ps1` lines 1-156) — a stdin/stdout dialog, not a network surface.

## Consumed APIs

**None at runtime.** The only network-style consumption is the **optional, deferred web-fetch** of the 8 vendor documentation URLs registered in `.aid/knowledge/external-sources.md:15-24`. Those are inputs to discovery, not runtime calls.

Optional runtime tool invocations (process-level, not HTTP):
- `mmdc` (Mermaid CLI) — invoked via `spawnSync` in `templates/knowledge-summary/scripts/validate-diagrams.mjs:164` for diagram parse/render validation when generating `knowledge-summary.html`. Falls back to a regex sanity check if `mmdc` is absent.
- `npx @mermaid-js/mermaid-cli` — npm fallback when `mmdc` is not on `$PATH` (`validate-diagrams.mjs:195`).

Both are local subprocess invocations, not external HTTP APIs.

---

## Host-Tool File-Format Contracts

These are the schemas AID writes to disk so each host AI tool will load AID's agents, skills, and project context. Breaking changes in any of these schemas (introduced upstream by Anthropic / OpenAI / Cursor) would silently break AID for adopters using that tool.

### 1. Claude Code Contract — `claude-code/.claude/`

#### 1a. Agent Definition Contract — `claude-code/.claude/agents/*.md`

Markdown with YAML frontmatter, then a free-form system-prompt body. Sampled across `architect.md`, `discovery-reviewer.md`, `researcher.md`, `simple-extractor.md`, `developer.md`, plus the 22-agent inventory from `Grep` over `claude-code/.claude/agents/*.md`.

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `name` | string | yes | kebab-case agent ID, must match filename stem | matches filename | `claude-code/.claude/agents/architect.md:2` |
| `description` | string or YAML folded `>` block | yes | one-line or multi-line summary; serves as the trigger phrase for skill `agents:` selection | — | `claude-code/.claude/agents/discovery-reviewer.md:3-6` (folded block); `claude-code/.claude/agents/architect.md:3` (one-line) |
| `tools` | comma-separated string | yes | Subset of `Read`, `Glob`, `Grep`, `Bash`, `Write`, `Edit`, `Agent` | varies | `claude-code/.claude/agents/architect.md:4` (`Read, Glob, Grep, Write, Edit, Bash`); `claude-code/.claude/agents/interviewer.md:4` (`Read, Glob, Grep` — no write) |
| `model` | string | yes | `opus` (Opus tier), `sonnet` (Sonnet tier), `haiku` (Haiku tier) | per agent — see tier mapping | `architect.md:5` = `opus`; `developer.md:5` = `sonnet`; `simple-extractor.md:5` = `haiku` |
| `permissionMode` | string | optional | `bypassPermissions` observed | absent on most | `discovery-reviewer.md:9`; all 6 `discovery-*.md` agents set this |
| `background` | boolean | optional | `true` observed | absent on most | `discovery-reviewer.md:10`; same 6 `discovery-*.md` agents |

**Observed model-value space across all 22 agents:** `opus` (10x), `sonnet` (9x), `haiku` (3x). The `permissionMode: bypassPermissions` + `background: true` pair appears only on the six `discovery-*.md` agents — these are the parallel-dispatched discovery sub-agents that must run without per-call permission prompts.

**Body conventions** (not enforced but consistent across all 22 agents): `## What You Do`, `## What You Don't Do`, `## Key Constraints`, `## Output Format`, `## When to Escalate`. See `architect.md:8-41` for the canonical shape; `discovery-reviewer.md` (381 lines) is the expanded shape with `## Document Expectations`, `## Cross-Cutting Checks`, `## Output` sections plus a full `DISCOVERY-STATE.md` template embedded in the prompt.

#### 1b. Skill Package Contract — `claude-code/.claude/skills/aid-*/SKILL.md`

Markdown with YAML frontmatter plus an optional `references/` and `scripts/` subdirectory. Sampled `aid-discover/SKILL.md:1-10`, `aid-init/SKILL.md:1-10`, and `Grep` across all 10 skills.

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `name` | string | yes | kebab-case, must match enclosing folder name (`aid-discover`, `aid-init`, etc.) | matches folder | `claude-code/.claude/skills/aid-discover/SKILL.md:2` |
| `description` | string or folded `>` block | yes | summary used by the host to decide when to load this skill into context | — | `claude-code/.claude/skills/aid-discover/SKILL.md:3-7` (folded); `aid-init/SKILL.md:3-7` (folded) |
| `allowed-tools` | comma-separated string | yes | subset of `Read`, `Glob`, `Grep`, `Bash`, `Write`, `Edit`, `Agent` | varies; `Agent` only present on `aid-discover` (1 of 10 skills) | `aid-discover/SKILL.md:8`; `aid-init/SKILL.md:8` |
| `argument-hint` | string | optional | short usage hint shown by the host CLI for slash-command invocation | varies | `aid-discover/SKILL.md:9`; `aid-execute/SKILL.md:11` |
| `context` | string | optional | `fork` observed — instructs Claude Code to run the skill in a forked context | absent on `aid-init`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-summarize` | `aid-detail/SKILL.md:9`; `aid-deploy/SKILL.md:9`; `aid-execute/SKILL.md:9`; `aid-monitor/SKILL.md:9`; `aid-plan/SKILL.md:8` |
| `agent` | string | optional | name of the default executor agent (`architect`, `developer`, `operator`, `orchestrator`, `interviewer`) — host harness will pre-load that agent | absent on `aid-init`, `aid-discover`, `aid-summarize` | `aid-detail/SKILL.md:10` (architect); `aid-execute/SKILL.md:10` (developer); `aid-deploy/SKILL.md:10` (operator); `aid-monitor/SKILL.md:10` (orchestrator); `aid-interview/SKILL.md:9` (interviewer); `aid-plan/SKILL.md:9` (architect); `aid-specify/SKILL.md:9` (architect) |

**`agents:` block:** Scout's earlier mention of `agents:` selector tables was investigated — `Grep "^agents:"` across `claude-code/.claude/skills/**` returned **zero matches**. The `agents:` selector pattern referenced in `codex/README.md:102` and `agents/README.md:140-149` is **implemented inside the SKILL.md body** (as a per-task-type selector table) rather than as a frontmatter field. See `aid-execute/SKILL.md:45-54` for the table shape (`Task Type | Executor | Reviewer | Specialist consult`).

**`references/` and `scripts/` decomposition convention:**
- `claude-code/.claude/skills/aid-discover/references/agent-prompts.md` (142 lines), `document-expectations.md` (121 lines), `reviewer-prompt.md` (75 lines) — externalized prose the body of SKILL.md references with phrases like *"Read `references/agent-prompts.md` section `## Scout`"* (`aid-discover/SKILL.md:126-127`).
- `claude-code/.claude/skills/aid-discover/scripts/check-preflight.sh` (45 lines), `verify-kb.sh` (60 lines) — bash helpers invoked from the SKILL body.
- Same pattern in `aid-execute/references/` (`reviewer-guide.md`, `task-type-rules.md`), `aid-interview/references/` (4 files), `aid-specify/references/` (2 files).

The Claude Code tree consistently externalizes; the Codex and Cursor trees inline the same content (see Codex `aid-discover/SKILL.md` = 1,078 lines; Cursor = 1,090 lines vs. Claude Code = 453 lines — see `project-structure.md` Anomaly #7).

**No sentinel files observed** (no `.skill`, `.meta.json`, or version file inside skill folders).

#### 1c. `CLAUDE.md` Project-Context Contract

Top-level project context file that Claude Code auto-loads. The AID install ships a placeholder at `claude-code/CLAUDE.md` (30 lines). This repo's own `CLAUDE.md` (30 lines) shows the populated shape with the `<!-- AID-DISCOVER ... -->` placeholder convention.

| Section | Required | AID-DISCOVER placeholder ID | Filled by | Evidence |
|---------|----------|------------------------------|-----------|----------|
| `# {ProjectName}` (H1 title) | yes | — | aid-init | `CLAUDE.md:1` |
| `<!-- AID-DISCOVER project-description -->` block | yes | `project-description` | aid-discover | `CLAUDE.md:3-5` |
| `## Project Overview` | yes | `project-overview` | aid-discover | `CLAUDE.md:7-10` |
| `## Build & Test` | yes | `build-test` | aid-discover | `CLAUDE.md:12-15` |
| `## Code Conventions` | yes | `code-conventions` | aid-discover | `CLAUDE.md:17-20` |
| `## Architecture` | yes | `architecture` | aid-discover | `CLAUDE.md:22-25` |
| `## AID Workspace` (or `## Knowledge Base`) | yes | — | aid-init (static) | `CLAUDE.md:27-30`; `claude-code/CLAUDE.md:7-12` |
| `## Skills`, `## Agents`, `## Permissions`, `## Conventions` | optional | — | aid-init (static, install variant only) | `claude-code/CLAUDE.md:14-30` |

The placeholders are wrapped in matched `<!-- AID-DISCOVER {id} -->` / `<!-- /AID-DISCOVER -->` comments. `aid-discover` looks for any `<!-- AID-DISCOVER ... -->` block and replaces the content between the open and close markers, preserving the comments so future re-discoveries can update the same regions (`codex/.agents/skills/aid-discover/SKILL.md:533-542`).

The install payload (`claude-code/CLAUDE.md`) uses a simpler single-line comment style (`<!-- AID-DISCOVER — Replace with... -->`) without the matched-pair structure — see `claude-code/CLAUDE.md:4`. ⚠️ **Drift between the install payload's placeholder style and the matched-pair style this repo's own CLAUDE.md uses.** [Q50 — see `DISCOVERY-STATE.md`]

#### 1d. `.claude/settings.json` Permission Contract

JSON. Schema (observed):

```json
{
  "permissions": {
    "allow": ["<Tool>(...exact-command-pattern...)"],
    "deny": ["..."]
  }
}
```

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `permissions` | object | yes | top-level wrapper | — | `.claude/settings.json:1-12` |
| `permissions.allow` | string array | yes | each entry is `<ToolName>(<pattern>)` — e.g., `Bash(mkdir -p ...)`, `Bash(cp ...)`, `Bash(chmod +x ...)` | empty array allowed | `.claude/settings.json:3-10` |
| `permissions.deny` | string array | optional | same shape as `allow`, for explicit blocklist | absent in this repo | not observed |

This repo's own `.claude/settings.json` (11 lines) declares 6 narrow `Bash(...)` allow patterns, all for the triplication-propagation scripts. The install payload does **not** ship its own `settings.json` at `claude-code/.claude/settings.json` (only `claude-code/CLAUDE.md` exists at the install root) — so each adopter inherits Claude Code's default permission prompt model.

⚠️ The sibling file `.claude/settings..json` (note **double-dot** in the filename) is a typo/leftover with identical content (`project-structure.md` Anomaly #2). Listed for completeness — both contain identical 6 Bash allow-list entries.

---

### 2. Codex CLI Contract — `codex/.codex/` + `codex/.agents/` + `codex/AGENTS.md`

#### 2a. Agent TOML Contract — `codex/.codex/agents/*.toml`

Plain TOML (no `[section]` headers; top-level keys only). Sampled `architect.toml`, `discovery-reviewer.toml:1-40`, `simple-extractor.toml`, `developer.toml`, plus `Grep` over all 22 `*.toml`.

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `name` | string | yes | kebab-case agent ID matching filename stem | matches filename | `codex/.codex/agents/architect.toml:1` |
| `description` | string | yes | one-line summary | — | `architect.toml:2` |
| `model` | string | yes | `gpt-5.5` (Opus tier) ∨ `gpt-5.4` (Sonnet tier) ∨ `gpt-5.4-mini` (Haiku tier) | per agent | 22-file `Grep`: 10x `gpt-5.5`, 9x `gpt-5.4`, 3x `gpt-5.4-mini` |
| `model_reasoning_effort` | string | yes | `high` (paired with `gpt-5.5`) ∨ `medium` (paired with `gpt-5.4`) ∨ `low` (paired with `gpt-5.4-mini`) | matches the tier of `model` | `architect.toml:4`; `developer.toml:4`; `simple-extractor.toml:4` |
| `developer_instructions` | TOML multi-line string (`"""..."""`) | yes | full system-prompt body | — | `architect.toml:5-39` |

**Tier-mapping pattern (per `codex/README.md:23-35`):**

| AID tier | Codex `model` | `model_reasoning_effort` | Used for |
|----------|---------------|--------------------------|----------|
| Opus | `gpt-5.5` | `high` | Architect, Interviewer, Reviewer, Security, all 6 `discovery-*` agents |
| Sonnet | `gpt-5.4` | `medium` | Orchestrator, Researcher, Developer, Operator, UX Designer, DevOps, Tech Writer, Data Engineer, Performance |
| Haiku | `gpt-5.4-mini` | `low` | simple-extractor, simple-formatter, simple-glob |

The May 2026 migration note at `codex/README.md:35` records a prior bug where 7 Sonnet-tier agents were incorrectly set to `gpt-5.4-mini`/`medium` (a non-tier combination) and have been corrected to `gpt-5.4`/`medium`.

**No `tools:` field** in the TOML — Codex CLI does not surface per-agent tool restrictions; tool access is governed by the broader CLI invocation. The Claude Code `tools:` whitelist concept has no direct Codex equivalent in the observed files.

#### 2b. Skill SKILL.md Contract — `codex/.agents/skills/aid-*/SKILL.md`

Same shape as the Claude Code SKILL.md (YAML frontmatter + body) but **inlined** — Codex does not consume `references/` or `scripts/` subfolders. Sampled `codex/.agents/skills/aid-discover/SKILL.md:1-15`.

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `name` | string | yes | matches enclosing folder | matches | `codex/.agents/skills/aid-discover/SKILL.md:2` |
| `description` | string/folded | yes | as Claude Code | identical text to Claude Code variant | `codex/.agents/skills/aid-discover/SKILL.md:3-7` |
| `allowed-tools` | comma-separated string | yes | as Claude Code | identical lists | `codex/.agents/skills/aid-discover/SKILL.md:8` |
| `argument-hint` | string | optional | as Claude Code | identical text | `codex/.agents/skills/aid-discover/SKILL.md:9` |

**Notable absence:** the Codex tree's SKILL.md files **do not** carry the `context: fork` or `agent: <name>` fields seen in the Claude Code tree on `aid-detail`, `aid-execute`, `aid-deploy`, `aid-interview`, `aid-monitor`, `aid-plan`, `aid-specify`. ⚠️ **Worth confirming this is intentional (Codex doesn't support those harness hints) or a drift gap.** [Q51]

The one supplementary `references/` file in the Codex tree is `codex/.agents/skills/aid-interview/references/kb-hydration.md` (106 lines) — identical to the Claude Code equivalent. The split is asymmetric (Codex inlines most but not all).

#### 2c. `AGENTS.md` Project-Context Contract

Markdown. The install payload at `codex/AGENTS.md` (28 lines) shows the placeholder shape:

| Section | Required | AID-DISCOVER placeholder | Filled by | Evidence |
|---------|----------|--------------------------|-----------|----------|
| `# AGENTS.md` (title) | yes | — | aid-init | `codex/AGENTS.md:1` |
| `## Project Overview` | yes | inline `<!-- AID-DISCOVER — Replace with project name, purpose, tech stack, and target platform -->` | aid-discover | `codex/AGENTS.md:3-5` |
| `## Build & Test` | yes | inline `<!-- AID-DISCOVER ... -->` | aid-discover | `codex/AGENTS.md:7-11` |
| `## Code Conventions` | yes | inline placeholder | aid-discover | `codex/AGENTS.md:13-15` |
| `## Architecture` | yes | inline placeholder | aid-discover | `codex/AGENTS.md:17-20` |
| `## AI-Integrated Development` | yes | static footer pointing to KB | aid-init | `codex/AGENTS.md:22-28` |

Codex uses the **single-line `<!-- AID-DISCOVER — Replace with ... -->` comment** style rather than the matched-pair convention seen in the dogfooded `CLAUDE.md` at the repo root. ⚠️ **Same drift as 1c.** [Q50]

---

### 3. Cursor Contract — `cursor/.cursor/` + `cursor/AGENTS.md`

#### 3a. `.mdc` Rule Contract — `cursor/.cursor/rules/*.mdc`

YAML frontmatter + markdown body. Sampled both files in the repo.

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `description` | string | yes | one-line summary | — | `cursor/.cursor/rules/aid-methodology.mdc:2`; `aid-review.mdc:2` |
| `globs` | string (comma-separated globs, optionally quoted) | optional | only present when `alwaysApply: false` | absent on always-on rules | `aid-review.mdc:3` (`"**/*.{java,py,ts,js,cs,go,rs}"`) |
| `alwaysApply` | boolean | yes | `true` (load into every conversation) ∨ `false` (load only when `globs` match) | — | `aid-methodology.mdc:3` (`true`); `aid-review.mdc:4` (`false`) |

Two rules ship: `aid-methodology.mdc` (29 lines, always on — KB lookup + phase discipline) and `aid-review.mdc` (11 lines, code-file-glob — issue-tagging + grading convention).

#### 3b. Agent File Contract — `cursor/.cursor/agents/*.md`

**Identical shape to Claude Code 1a** (markdown + YAML frontmatter with `name`, `description`, `tools`, `model`). Sampled `cursor/.cursor/agents/architect.md`:

| Field | Type | Required | Allowed values / pattern | Observed default | Evidence |
|-------|------|----------|--------------------------|------------------|----------|
| `name` | string | yes | kebab-case | matches filename | `cursor/.cursor/agents/architect.md:2` |
| `description` | string/folded | yes | as Claude Code | — | `cursor/.cursor/agents/architect.md:3` |
| `tools` | comma-separated | yes | subset of `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Terminal`, `Bash`, `Agent` — note **`Terminal`** appears on Cursor where Claude Code uses **`Bash`** | varies | `cursor/.cursor/agents/architect.md:4` (`Read, Glob, Grep, Write, Edit, Terminal`) vs. Claude Code `architect.md:4` (`Read, Glob, Grep, Write, Edit, Bash`) |
| `model` | string | yes | `opus` / `sonnet` / `haiku` | per agent | `cursor/.cursor/agents/architect.md:5` |

⚠️ **`Terminal` vs `Bash` divergence**: the Cursor architect declares `Terminal` instead of `Bash`. Spot-check needed across all 22 Cursor agents to confirm whether this is consistent or a drift artifact. [Q52]

`permissionMode` and `background` fields (used by 6 `discovery-*.md` agents in the Claude Code tree) appear in the Cursor tree as well — confirmed by the 172/147/153 line counts in `project-index.md` matching the Claude Code line counts for those same files (suggesting the same content). The Cursor README at `cursor/README.md:128` notes that **Task tool dispatch is experimental as of March 2026** — so even with `background: true`, the actual parallel-dispatch behavior may not be available.

#### 3c. Skill SKILL.md Contract — `cursor/.cursor/skills/aid-*/SKILL.md`

Same shape as Claude Code 1b. Inlined like the Codex variant (Cursor `aid-discover/SKILL.md` = 1,090 lines; Claude Code = 453 lines). Sampled `cursor/.cursor/skills/aid-discover/SKILL.md:1-15` — identical frontmatter to the Claude Code version (`name`, `description`, `allowed-tools`, `argument-hint`).

Per `cursor/README.md:136-142`, Cursor reads skills from `.cursor/skills/`, **and** is cross-tool compatible — it will also read `.claude/skills/` and `.codex/skills/`. This is the only documented "skill loader fallback chain" in the AID install set.

#### 3d. `AGENTS.md` Project-Context Contract

Markdown. `cursor/AGENTS.md` (45 lines). Same section list as Codex `AGENTS.md` (4 of 8 sections share placeholder IDs), plus Cursor-specific additions:

| Section | Required | AID-DISCOVER placeholder | Filled by | Evidence |
|---------|----------|--------------------------|-----------|----------|
| `## Project Overview` | yes | inline `<!-- AID-DISCOVER — Replace with ... -->` | aid-discover | `cursor/AGENTS.md:3-5` |
| `## Build & Test` | yes | inline placeholder | aid-discover | `cursor/AGENTS.md:7-11` |
| `## Code Conventions` | yes | inline placeholder | aid-discover | `cursor/AGENTS.md:13-15` |
| `## Architecture` | yes | inline placeholder | aid-discover | `cursor/AGENTS.md:17-20` |
| `## Knowledge Base` | yes | static | aid-init | `cursor/AGENTS.md:22-25` |
| `## Skills & Agents` | yes | static | aid-init | `cursor/AGENTS.md:27-30` (mentions Task tool experimental) |
| `## Permissions` | yes | static | aid-init | `cursor/AGENTS.md:32-37` |
| `## AI-Integrated Development` | yes | static | aid-init | `cursor/AGENTS.md:39-45` |

Cursor **does not** use `CLAUDE.md` — `cursor/README.md:143` is explicit: *"Cursor does not use CLAUDE.md — all project context goes into AGENTS.md."*

---

## AID Internal Artifact Contracts

These are the schemas AID phases use to communicate with each other. Every artifact below is the contract between two AID phases — broken contracts mean broken hand-offs. Templates listed are the source-of-truth shape; install variants duplicate them under each tool tree.

### `REQUIREMENTS.md` Schema

Source-of-truth template: `templates/requirements/requirements-template.md` (95 lines). Per-instance file lives at `.aid/{work}/REQUIREMENTS.md`. Produced by aid-interview; consumed by aid-specify.

| Section | Required | Type | Notes | Evidence |
|---------|----------|------|-------|----------|
| `# Requirements` (H1) | yes | title | — | `templates/requirements/requirements-template.md:23` |
| `## Change Log` | yes | table (`Date \| Change \| Source`) | mandatory — every edit gets a row | `requirements-template.md:25-29` |
| `## 1. Objective` | yes | prose | stakeholder's own words preferred | `requirements-template.md:31` |
| `## 2. Problem Statement` | yes | prose | — | `requirements-template.md:35` |
| `## 3. Users & Stakeholders` | yes | table | role / description / needs | `requirements-template.md:39-45` |
| `## 4. Scope` | yes | sub-sections | `### In Scope` + `### Out of Scope` | `requirements-template.md:47-55` |
| `## 5. Functional Requirements` | yes | prose | implementation-precise | `requirements-template.md:57-59` |
| `## 6. Non-Functional Requirements` | yes | prose | measurable where possible | `requirements-template.md:61-63` |
| `## 7. Constraints` | yes | prose | timeline / budget / compliance | `requirements-template.md:65-67` |
| `## 8. Assumptions & Dependencies` | yes | prose | — | `requirements-template.md:69-71` |
| `## 9. Acceptance Criteria` | yes | prose | testable conditions | `requirements-template.md:73-75` |
| `## 10. Priority` | yes | prose | Must / Should / Could | `requirements-template.md:77-79` |

Section markers: `*(pending)*` for not-yet-addressed sections; `N/A` is permitted for inapplicable sections.

### `SPEC.md` Schema (Per-Feature)

Source-of-truth template: `claude-code/.claude/templates/feature.md` (33 lines, requirements-side) extended by `aid-specify` with a `## Technical Specification` block. Per-instance file lives at `.aid/{work}/features/feature-{NNN}-{name}/SPEC.md`. Produced jointly by aid-interview (requirements side) and aid-specify (tech side); consumed by aid-plan, aid-detail, aid-execute.

| Section | Required | Type | Phase that fills it | Evidence |
|---------|----------|------|---------------------|----------|
| `# {Feature Title}` | yes | title | aid-interview | `claude-code/.claude/templates/feature.md:1` |
| `## Change Log` | yes | table | both | `feature.md:3-7` |
| `## Source` | yes | bullet list referencing REQUIREMENTS.md `§n` | aid-interview | `feature.md:9-11` |
| `## Description` | yes | prose | aid-interview | `feature.md:13-15` |
| `## User Stories` | yes | bullet list ("As a {user}, I want to {action} so that {benefit}") | aid-interview | `feature.md:17-19` |
| `## Priority` | yes | enum (Must / Should / Could) | aid-interview | `feature.md:21-23` |
| `## Acceptance Criteria` | yes | checklist (Gherkin-style "Given/When/Then") | aid-interview | `feature.md:25-27` |
| `## Technical Specification` | yes after aid-specify | section header | aid-specify | `feature.md:31-33`; full shape at `templates/specs/spec-template.md:33-75` |
| `### Data Model` | yes (core) | prose / DDL | aid-specify | `templates/specs/spec-template.md:38-41` |
| `### Feature Flow` | yes (core) | flowchart prose | aid-specify | `templates/specs/spec-template.md:43-46` |
| `### Layers & Components` | yes (core) | prose | aid-specify | `templates/specs/spec-template.md:48-51` |
| Conditional sections (commented in template) | optional | up to 20 | aid-specify activates per context | `templates/specs/spec-template.md:53-75` |

**Conditional section enum** (commented-out activatable blocks in the template): `API Contracts`, `UI Specs`, `Events & Messaging`, `DDD Analysis`, `BDD Scenarios`, `CQRS Specs`, `State Machines`, `Security Specs`, `Migration Plan`, `Cache Strategy`, `External Integrations`, `Batch/Jobs`, `Mobile Specs`, `Search/Indexing`, `AI Enhancements`, `Telemetry & Tracking`, `Recovery Management`, `Cloud Support`, `Hardware Requirements`. Source: `templates/specs/spec-template.md:55-74`.

### `DISCOVERY-STATE.md` Schema

Source-of-truth template: `claude-code/.claude/templates/discovery-state.md` (23 lines). Per-instance file lives at `.aid/knowledge/DISCOVERY-STATE.md`. Produced by aid-init (skeleton) and aid-discover (REVIEW mode fills it).

| Field / Section | Required | Type | Allowed values | Evidence |
|-----------------|----------|------|----------------|----------|
| `# Discovery State` (title) | yes | H1 | fixed | `discovery-state.md:1` |
| `**Grade:**` | yes | scalar | `Not Started` ∨ `Pending` ∨ grade letter (A+, A, A-, ..., F) | `discovery-state.md:3`; grade enum at `templates/grading-rubric.md:39-56` |
| `**Minimum Grade:**` | yes | scalar | grade letter (default `A` per `aid-discover/SKILL.md:33`) | `discovery-state.md:4` |
| `**Project Type:**` | yes | enum | `Brownfield` ∨ `Greenfield` | `discovery-state.md:5` |
| `**User Approved:**` | yes | enum | `yes` ∨ `no` | `discovery-state.md:6` |
| `## External Documentation` | yes | bullet list | paths or `"None provided"` | `discovery-state.md:8-10` |
| `## Issues` | yes | bracket-tagged list per `templates/grading-rubric.md` | populated by reviewer | `discovery-state.md:12-14` |
| `## Q&A` | yes | structured Q-entry list | populated by sub-agents and reviewer | `discovery-state.md:16-18` |
| `## Review History` | yes | table (`# \| Date \| Grade \| Source \| Notes`) | one row per review cycle | `discovery-state.md:20-23` |

**Discovery-reviewer-extended schema** for the same file adds `## Documents` (18-row grade table), `## Issues Found` (per-document grouped lists with bracketed severity), `## Verification Spot-Checks`, `## Cross-Cutting Concerns` — see `claude-code/.claude/agents/discovery-reviewer.md:309-369`. ⚠️ **Two templates for the same file**: the install-payload template (23 lines) is a skeleton; the reviewer agent's prompt embeds a richer 60-line template. Production behavior writes the richer shape. [Q53]

### `IMPLEMENTATION-STATE.md` Schema

Source-of-truth: `claude-code/.claude/templates/implementation-state.md` (30 lines). Per-instance at `.aid/{work}/tasks/task-{NNN}/IMPLEMENTATION-STATE.md`. Produced/maintained by aid-execute.

| Field / Section | Required | Type | Allowed values | Evidence |
|-----------------|----------|------|----------------|----------|
| `# Implementation State — {task-NNN}` | yes | title | task ID | `implementation-state.md:1` |
| `**Status:**` | yes | enum | `Pending` ∨ `In Progress` ∨ `Complete` (inferred) | `implementation-state.md:3` |
| `**Task:**` | yes | scalar | task-NNN | `implementation-state.md:4` |
| `**Type:**` | yes | enum | `RESEARCH \| DESIGN \| IMPLEMENT \| TEST \| DOCUMENT \| MIGRATE \| REFACTOR \| CONFIGURE` (8 types) | `implementation-state.md:5` |
| `**Feature:**` | yes | scalar | feature-NNN-{name} | `implementation-state.md:6` |
| `**Delivery:**` | yes | scalar | delivery-NNN | `implementation-state.md:7` |
| `**Minimum Grade:**` | yes | scalar (read-through from DISCOVERY-STATE.md) | grade letter | `implementation-state.md:8` |
| `**Branch:**` | yes | scalar | `aid/{delivery-NNN}` pattern | `implementation-state.md:9` |
| `## Current Review` | yes | sub-section with `**Cycle:**` + `**Grade:**` + `### Issues` | per review cycle | `implementation-state.md:11-18` |
| `## Dispatches` | yes | table (`Step \| Agent \| Reason \| Cycle`) | audit trail | `implementation-state.md:20-26` |
| `## Review History` | yes | placeholder for cycle rollup | — | `implementation-state.md:28-30` |

### `INTERVIEW-STATE.md` Schema

Source-of-truth: `claude-code/.claude/templates/interview-state.md` (29 lines). Per-instance at `.aid/{work}/INTERVIEW-STATE.md`. Produced/maintained by aid-interview.

| Field / Section | Required | Type | Allowed values | Evidence |
|-----------------|----------|------|----------------|----------|
| `# INTERVIEW-STATE.md` | yes | title | fixed | `interview-state.md:1` |
| `**Status:**` | yes | enum | `In Progress` ∨ `Complete` (inferred) | `interview-state.md:3` |
| `**Grade:**` | yes | scalar | A/B/C/D per `methodology/aid-methodology.md:272-278` cross-reference rubric, or `—` | `interview-state.md:4` |
| `**Minimum Grade:**` | yes | scalar | grade letter (default `A`) | `interview-state.md:5` |
| `## Section Status` | yes | 10-row table mirroring REQUIREMENTS.md §1-§10 | `Pending` ∨ `In Progress` ∨ `Complete` | `interview-state.md:7-20` |
| `## Pending Q&A` | yes | list (Q-entry format below) | `(none)` allowed | `interview-state.md:22-24` |
| `## Review History` | yes | table | one row per cross-reference run | `interview-state.md:26-29` |

### `FEATURE-STATE.md` Schema

Referenced by phases as the `STATE.md` inside each feature folder. Source-of-truth: `claude-code/.claude/templates/feature-state.md` (22 lines). Per-instance at `.aid/{work}/features/feature-{NNN}-{name}/STATE.md`. Produced/maintained by aid-specify.

| Field / Section | Required | Type | Allowed values | Evidence |
|-----------------|----------|------|----------------|----------|
| `# Specification State` | yes | title | fixed | `feature-state.md:1` |
| `**Status:**` | yes | enum | `In Discussion` ∨ later states (`Ready` per `methodology/aid-methodology.md:333`) | `feature-state.md:3` |
| `**Started:**` | yes | date | ISO | `feature-state.md:4` |
| `## Activated Sections` | yes | table (`Section \| Status \| Activation`) | tracks which conditional spec sections are active | `feature-state.md:6-9` |
| `## Pending Q&A` | yes | list | `(none)` allowed | `feature-state.md:11-13` |
| `## Loopbacks` | yes | list | references back to DISCOVERY-STATE / INTERVIEW-STATE | `feature-state.md:15-17` |
| `## Change Log` | yes | table | — | `feature-state.md:19-22` |

### `DEPLOYMENT-STATE.md` Schema

Source-of-truth: `claude-code/.claude/templates/deployment-state.md` (9 lines). Per-instance at `.aid/{work}/DEPLOYMENT-STATE.md`. Produced by aid-deploy.

| Field / Section | Required | Type | Allowed values | Evidence |
|-----------------|----------|------|----------------|----------|
| `# Deployment State — {work-NNN}` | yes | title | — | `deployment-state.md:1` |
| `**Status:**` | yes | enum | `Idle` ∨ later states (e.g. `Active`, inferred) | `deployment-state.md:3` |
| `**Active Package:**` | yes | scalar | package-NNN or `—` | `deployment-state.md:4` |
| `**Minimum Grade:**` | yes | scalar (read-through) | grade letter | `deployment-state.md:5` |
| `## History` | yes | list | per-package summary; `_No packages created yet._` allowed | `deployment-state.md:7-9` |

### TASK File Schema (with 8-type enum)

Source-of-truth: `templates/delivery-plans/task-template.md` (142 lines). Per-instance at `.aid/{work}/tasks/task-{NNN}/task-{NNN}.md`. Produced by aid-detail; consumed by aid-execute.

| Section | Required | Type | Allowed values | Evidence |
|---------|----------|------|----------------|----------|
| `# task-{id}: {Name}` | yes | title | — | `task-template.md:1` |
| `**Delivery:**` | yes | scalar | DELIVERY-{id} | `task-template.md:3` |
| `**User Story:**` | yes | scalar | US-{id} | `task-template.md:4` |
| `**Status:**` | yes | enum | `Not Started` ∨ `In Progress` ∨ `In Review` ∨ `Complete` | `task-template.md:5` |
| `**Complexity:**` | yes | enum | `S \| M \| L \| XL` | `task-template.md:6` |
| `**Assigned to:**` | yes | scalar | agent instance or human | `task-template.md:7` |
| `**Type:**` (in IMPLEMENTATION-STATE.md alongside the task) | yes | enum | `RESEARCH` ∨ `DESIGN` ∨ `IMPLEMENT` ∨ `TEST` ∨ `DOCUMENT` ∨ `MIGRATE` ∨ `REFACTOR` ∨ `CONFIGURE` (8 types) | `aid-execute/SKILL.md:30-39`; `implementation-state.md:5` |
| `## Objective` | yes | prose | — | `task-template.md:11-15` |
| `## Context` | yes | structured (references + KB Index pointer) | — | `task-template.md:19-29` |
| `## Interface Contracts` | yes | code blocks | language-agnostic | `task-template.md:33-55` |
| `## Acceptance Criteria` | yes | checklist | concrete, testable | `task-template.md:59-71` |
| `## Test Requirements` | yes | structured | unit / integration / edge case lists | `task-template.md:75-88` |
| `## Files to Touch` | yes | structured | Create / Modify / Do NOT modify | `task-template.md:92-106` |
| `## Notes & Gotchas` | yes | prose | — | `task-template.md:110-115` |
| `## Impediment Protocol` | yes | static prose | references IMPEDIMENT.md template | `task-template.md:119-129` |
| `## Completion Record` | yes | structured | filled at completion | `task-template.md:133-142` |

### `GAP.md` Feedback Artifact Schema

Source-of-truth: `templates/feedback-artifacts/GAP.md` (88 lines). Per-instance at `.aid/{work}/gaps/GAP-{NNN}.md` (path inferred). Produced by aid-specify, aid-plan, aid-detail, aid-execute when a KB gap is discovered.

| Section | Required | Type | Allowed values | Evidence |
|---------|----------|------|----------------|----------|
| `# GAP: GAP-{id}` | yes | title | — | `GAP.md:1` |
| `**Generated by:**` | yes | enum | `aid-specify \| aid-plan \| aid-detail \| aid-execute` | `GAP.md:3` |
| `**Phase:**` | yes | scalar | Phase {n}: {name} | `GAP.md:4` |
| `**Status:**` | yes | enum | `Open \| In Progress \| Resolved \| No Action` | `GAP.md:6` |
| `## Summary` | yes | prose | one sentence | `GAP.md:10-12` |
| `## Type` | yes | enum (checkbox) | `discovery-needed` ∨ `ambiguity` ∨ `contradiction` ∨ `plan-too-vague` | `GAP.md:16-23` |
| `## Source` | yes | structured (Phase / Artifact / Blocking) | — | `GAP.md:27-31` |
| `## Description` | yes | structured (Expected / Found / Evidence) | — | `GAP.md:35-46` |
| `## Impact` | yes | structured (If unresolved / Blocks) | — | `GAP.md:50-57` |
| `## Resolution Required` | yes | enum (checkbox) | `discovery` ∨ `needs-human` ∨ `needs-spike` ∨ `spec-revision` | `GAP.md:61-69` |
| `## Resolution` | yes | structured | filled when closed | `GAP.md:73-80` |
| `## Revision History` | yes | table | — | `GAP.md:84-88` |

### `IMPEDIMENT.md` Feedback Artifact Schema

Source-of-truth: `templates/feedback-artifacts/IMPEDIMENT.md` (118 lines). Per-instance at `.aid/{work}/tasks/task-{NNN}/IMPEDIMENT-{N}.md` (path inferred). Produced exclusively by aid-execute (Phase 6).

| Section | Required | Type | Allowed values | Evidence |
|---------|----------|------|----------------|----------|
| `# IMPEDIMENT: IMP-{id}` | yes | title | — | `IMPEDIMENT.md:1` |
| `**Generated by:**` | yes | fixed | `aid-execute (Phase 6)` | `IMPEDIMENT.md:3` |
| `**Status:**` | yes | enum | `Open \| Escalated \| Resolved \| No Action` | `IMPEDIMENT.md:5` |
| `## Type` | yes | enum (checkbox) | `wrong-assumption` ∨ `missing-dependency` ∨ `architecture-conflict` ∨ `kb-gap` ∨ `spec-gap` ∨ `scope-creep` | `IMPEDIMENT.md:18-25` |
| `## Source` | yes | structured | Task + Phase + File | `IMPEDIMENT.md:29-33` |
| `## What Was Found` | yes | structured (Expected / Actual / Evidence) | — | `IMPEDIMENT.md:37-54` |
| `## KB Impact` | yes | structured | which document + current / correct content | `IMPEDIMENT.md:58-65` |
| `## Options` | yes | Option A / B / [C] sub-sections with Approach / Effort / Risk / Scope impact / Spec impact | min 2 options | `IMPEDIMENT.md:69-90` |
| `## Recommendation` | yes | prose | agent recommendation only; human decides | `IMPEDIMENT.md:94-96` |
| `## Resolution` | yes | structured | filled when resolved | `IMPEDIMENT.md:100-110` |
| `## Revision History` | yes | table | — | `IMPEDIMENT.md:114-118` |

### `KNOWN-ISSUES.md` Schema

Source-of-truth: `claude-code/.claude/templates/known-issues.md` (15 lines, mostly inline-comment specification). Per-instance at `.aid/{work}/KNOWN-ISSUES.md`. Produced by aid-specify during codebase exploration; consumed by aid-plan for deliverable sequencing.

Entry format (from inline-comment specification at `known-issues.md:6-15`):

| Field | Required | Type | Allowed values | Evidence |
|-------|----------|------|----------------|----------|
| `## KI-NNN: {Title}` | yes | title | — | `known-issues.md:8` |
| `**Type:**` | yes | enum | `Bug \| Security \| Deprecated Dependency \| Breaking API Contract` | `known-issues.md:9` |
| `**Severity:**` | yes | enum | `Critical \| High \| Medium` | `known-issues.md:10` |
| `**Affects:**` | yes | list | feature-NNN-{name} references | `known-issues.md:11` |
| `**Source:**` | yes | reference | `{file path}:{line}` ∨ `{dependency}:{version}` | `known-issues.md:12` |
| `**Description:**` | yes | prose | — | `known-issues.md:13` |
| `**See also:**` | optional | cross-reference | tech-debt.md #TD-NNN | `known-issues.md:14` |

### Q&A Entry Schema (used inside DISCOVERY-STATE.md and INTERVIEW-STATE.md `## Q&A` / `## Pending Q&A` sections)

Defined by `claude-code/.claude/agents/discovery-reviewer.md:25-52`. Used by sub-agents and reviewer to flag information that cannot be resolved from code alone.

| Field | Required | Type | Allowed values | Evidence |
|-------|----------|------|----------------|----------|
| `### Q{N}: [{Category}: {Impact}] {question}` | yes | header pattern with embedded category + impact tags | Q{integer}; Category is short tag (e.g., `Security`, `Data`, `Infrastructure`); Impact ∈ `High` ∨ `Medium` ∨ `Low` ∨ `Required` | `discovery-reviewer.md:39` |
| `**Status:**` | yes | enum | `Pending` ∨ `Answered` ∨ `Skipped` | `discovery-reviewer.md:40` |
| `**Context:**` | yes | prose | what the review found lacking | `discovery-reviewer.md:41` |
| `**Suggested:**` | optional | prose | inferred answer; omit if not inferrable | `discovery-reviewer.md:42` |
| `**Question:**` | yes (implicit in header) | prose | — | `aid-discover/SKILL.md:69-71` |
| `**Answer:**` | optional | prose | populated when Status flips to Answered | inferred from state-machine logic in `aid-discover/SKILL.md:69-73` |
| `**Applied to:**` | optional | list | which KB doc was updated as a result | inferred from `aid-discover` FIX-mode behaviour |

Q-IDs are globally unique across a Discovery run; subagents continue from the highest existing ID (`discovery-reviewer.md:33-36`). Pending entries with `**Impact:** Required` force the `aid-discover` state machine into Q&A mode regardless of grade (`aid-discover/SKILL.md:70`).

---

## Breaking-Change Risk

Which host-tool contracts are most exposed to upstream change? Ranked highest to lowest exposure.

1. **Claude Code agent frontmatter (1a).** Anthropic adding required fields, deprecating `permissionMode: bypassPermissions`, or renaming `tools:` would break all 22 Claude Code agents and (because Cursor consumes the same shape) the 22 Cursor agents too. Highest-risk vector. See `external-sources.md:67-68` — Anthropic Hooks, Plugins, and the full frontmatter inventory still need fetch.
2. **Cursor `.mdc` rule schema (3a).** Only 2 files, but `alwaysApply` + `globs` precedence is documented as in flux. A new required field would break both `aid-methodology.mdc` and `aid-review.mdc`. See `external-sources.md:98` — Cursor precedence rules still need fetch.
3. **`AGENTS.md` placeholder convention (2c, 3d).** OpenAI/Cursor have shipped a shared `AGENTS.md` standard, but the `<!-- AID-DISCOVER {id} -->` matched-comment placeholder convention is **AID-specific**. If either vendor introduces a competing placeholder syntax or starts post-processing HTML comments, the aid-discover writeback at `codex/.agents/skills/aid-discover/SKILL.md:533-542` will silently fail to update.
4. **Codex TOML `model` value space (2a).** The pinned `gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini` model IDs will sunset on OpenAI's normal model-deprecation cycle. Every TOML in `codex/.codex/agents/` will need re-pinning. `codex/README.md:35` already documents one corrective migration (May 2026).
5. **Claude Code `model` enum (1a).** Same risk — `opus` / `sonnet` / `haiku` are stable aliases today but the Anthropic docs link in `external-sources.md:17` is the source of truth.
6. **Claude Code SKILL.md `context: fork` and `agent: <name>` fields (1b).** Used by 7 of 10 skills. Not present in the Codex equivalent — ⚠️ if these are deprecated by Anthropic, those 7 skills lose their harness pre-load behavior but still function (degraded). Cursor exposure is the same as Claude Code (shared shape).
7. **`.claude/settings.json` permission schema (1d).** Only this repo's dogfood uses it; the install payload ships no `settings.json`, so adopter exposure is zero. Internal-only risk.

**Lowest risk:** AID internal artifact contracts (REQUIREMENTS, SPEC, DISCOVERY-STATE, etc.) — these are owned end-to-end by AID itself and only break if AID's own templates change.
