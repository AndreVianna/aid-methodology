# AID Agents

Agents in AID are **specialties**, not phases. Each agent has a focused area of expertise and is invoked when that expertise is needed — regardless of which phase the pipeline is in.

## Core, Specialist, and Utility

AID agents are divided into three categories:

- **Core Agents** (7) — always present in the pipeline. Every project uses them.
- **Specialist Agents** (6) — invoked ad-hoc when their expertise is needed. Not every project uses every specialist.
- **Utility Agents** (3) — Haiku-tier sub-agents called *by* Core/Specialist agents for mechanical sub-tasks (extraction, formatting, file enumeration). Never invoked at the skill layer.

Models map per tier across editor variants:

| Tier | Anthropic | OpenAI Codex |
|------|-----------|---------------|
| Opus | `opus` | `gpt-5.5` (high reasoning) |
| Sonnet | `sonnet` | `gpt-5.4` (medium reasoning) |
| Haiku | `haiku` | `gpt-5.4-mini` (low reasoning) |

The Reviewer ≥ Executor invariant is enforced: the agent that writes is never the agent that grades, and the grader's tier is never below the writer's.

---

## Core Agents

These agents form the backbone of every AID pipeline:

| Agent | Specialty | Typical Phases | Tier |
|-------|-----------|----------------|------|
| [**Orchestrator**](orchestrator/) | Pipeline coordination, routing, human gates | All | Sonnet |
| [**Researcher**](researcher/) | Investigation, KB generation, analysis | Discover, Track, any | Sonnet |
| [**Interviewer**](interviewer/) | Adaptive dialogue, requirements gathering | Interview | Opus |
| [**Architect**](architect/) | Design: specs, plans, task decomposition | Specify, Plan, Detail | Opus |
| [**Developer**](developer/) | Code implementation (only agent that writes code) | Implement | Sonnet |
| [**Reviewer**](reviewer/) | Adversarial issue-finding; grade computed by script | Review, Test | Opus |
| [**Operator**](operator/) | Deployment, PR creation, release management | Deploy | Sonnet |

### How Core Agents Map to Phases

```
Discover    → Researcher (with discovery-* sub-agents at Opus)
Interview   → Interviewer
Specify     → Architect
Plan        → Architect
Detail      → Architect
Implement   → Developer
Review      → Reviewer
Test        → Reviewer
Deploy      → Operator
Track       → Researcher
Triage      → Orchestrator (root cause analysis, routes to Developer or Discover)
```

The Orchestrator coordinates all of the above, managing transitions and routing feedback artifacts.

---

## Specialist Agents

These agents are invoked on demand when specific expertise is needed:

| Agent | Specialty | Called By | Tier |
|-------|-----------|-----------|------|
| [**UX Designer**](ux-designer/) | UI/UX, accessibility (WCAG), user flows | Architect, Reviewer | Sonnet |
| [**DevOps**](devops/) | CI/CD, IaC, containerization, monitoring | Operator, Researcher | Sonnet |
| [**Tech Writer**](tech-writer/) | Documentation, API docs, changelogs | Operator, Architect | Sonnet |
| [**Security**](security/) | Threat modeling, OWASP, auth, dependency audit | Reviewer, Researcher | Opus |
| [**Data Engineer**](data-engineer/) | Schema, migrations, queries, ETL | Architect, Developer | Sonnet |
| [**Performance**](performance/) | Profiling, load testing, caching, optimization | Reviewer, Researcher | Sonnet |

### When to Call a Specialist

The Orchestrator (or any Core agent) invokes a specialist when:

- **UX Designer** — the feature has a user interface, or accessibility review is needed
- **DevOps** — CI/CD pipeline needs setup/modification, or infrastructure changes are required
- **Tech Writer** — a release needs documentation, or specs need clarity review
- **Security** — code touches auth, handles user data, or a security audit is due
- **Data Engineer** — schema changes, new migrations, or query performance issues
- **Performance** — load testing needed, performance regression detected, or scaling decisions required

---

## Utility Agents

These Haiku-tier sub-agents are dispatched *by* Core/Specialist agents for mechanical sub-tasks. They are never exposed at the skill layer — they exist to keep mechanical work cheap.

| Agent | Purpose | Used By | Tier |
|-------|---------|---------|------|
| [**simple-extractor**](simple-extractor/) | Extract structured items from files (annotations, imports, endpoints) per a fixed schema | Researcher, discovery-*, others | Haiku |
| [**simple-formatter**](simple-formatter/) | Fill markdown templates with structured input | discovery-*, Operator, Tech Writer | Haiku |
| [**simple-glob**](simple-glob/) | Enumerate files matching glob patterns with metadata (path, size, mtime) | Researcher, Operator, others | Haiku |

Caller contract: full agents validate the simple-* output (sample-check, count sanity, schema match) before consuming it.

---

## Discovery Sub-Agents

The Discovery phase dispatches 5 specialized sub-agents in parallel. They are defined only in the install variants (`.claude/agents/`, `.cursor/agents/`, `.codex/agents/`) — they don't have source-of-truth READMEs in this directory because their roles are tightly bound to the discovery state machine.

| Sub-agent | Outputs | Tier |
|-----------|---------|------|
| `discovery-architect` | architecture.md, technology-stack.md, ui-architecture.md | Opus |
| `discovery-analyst` | module-map.md, coding-standards.md, data-model.md | Opus |
| `discovery-integrator` | api-contracts.md, integration-map.md, domain-glossary.md | Opus |
| `discovery-quality` | test-landscape.md, security-model.md, tech-debt.md | Opus |
| `discovery-scout` | infrastructure.md, additional-info.md | Opus |
| `discovery-reviewer` | DISCOVERY-STATE.md (grades all KB docs) | Opus |

Discovery sub-agents may delegate mechanical work to `simple-*` utilities. They run in parallel after a fast Haiku-tier shell pre-pass (`templates/scripts/build-project-index.sh`) that emits a shared file inventory.

---

## Design Principles

### Specialty over Phase

The old approach assigned one agent per phase (discoverer, interviewer, tester, etc.). The new approach assigns agents by *expertise*. This means:

- The **Researcher** handles both Discovery and Track — same skill (investigation), different phases
- The **Architect** handles Specify, Plan, and Detail — same skill (design), different granularities
- The **Reviewer** handles both Review and Test — same skill (evaluation), different artifacts

### Separation of Concerns

- Only the **Developer** modifies production code
- Only the **Reviewer** *finds and classifies* issues — but never writes the grade itself
- Only the **Operator** executes external actions
- The **Orchestrator** never implements — it coordinates
- Grading is **deterministic** — `templates/scripts/grade.sh` reads the Reviewer's structured issue list and applies the rubric. No agent assigns letter grades.

### Adversarial by Design

The **Reviewer** is adversarial to the **Developer**. This is intentional. The agent that writes code should never be the agent that evaluates it. The Reviewer's tier is enforced ≥ executor's tier so the Reviewer cannot share the writer's blind spots.

### Multi-Agent Skills

Most skills dispatch a single agent throughout. But some skills have phases or task types that require different agents — and the harness can't enforce per-state dispatch automatically. The convention:

- **Frontmatter** (`agent: <default>`) sets the harness-recognized default — the most common executor.
- **Body** has either an "Agents Involved" section (for skills with a single varying point, like a REVIEW step) or an "Agent Selection" table (for skills that vary by task type or state).
- **Dispatch points** in the body explicitly state `subagent_type: <agent>` to override the default. They also print a log line and append to a state file's `## Dispatches` section so the dispatch decision is visible and auditable.

Examples:
- `aid-execute` picks the executor by task Type (RESEARCH→researcher, DESIGN→ux-designer, etc.) — body table + Step 1 instruction to override.
- `aid-interview` runs as `interviewer` for States 1–4, then explicitly switches to `architect` for State 5 (Feature Decomposition) and `reviewer` for State 6 (Cross-Reference).
- `aid-detail`, `aid-plan`, `aid-specify` run their default agent for proposal phases, then explicitly dispatch `reviewer` for the REVIEW step.

The pattern is validated by `templates/scripts/lint-skill-agents.sh` — it walks all SKILL.md files and checks that every backtick-quoted agent reference in Agents Involved / Agent Selection sections corresponds to a real agent file.

### Mechanical Work at the Cheap Tier

Foundation extraction, file enumeration, and template-filling do not require Opus reasoning. The `simple-*` Utility tier exists so Core/Specialist agents can offload these chunks at Haiku price while keeping synthesis at their own tier.

---

## File Formats

Each agent has documentation in up to four formats (only Core/Specialist have all four; Utility and Discovery sub-agents skip the source-of-truth README):

| Format | Location | Purpose |
|--------|----------|---------|
| `agents/{name}/README.md` | This directory | Human-readable, rich documentation |
| `claude-code/.claude/agents/{name}.md` | Claude Code format | LLM-optimized with YAML frontmatter |
| `cursor/.cursor/agents/{name}.md` | Cursor format | Same YAML frontmatter; Task tool experimental |
| `codex/.codex/agents/{name}.toml` | Codex TOML format | OpenAI Codex CLI |

The grading rubric and bash scripts (grade, project-index) live in `templates/`:

| File | Purpose |
|------|---------|
| `templates/grading-rubric.md` | Universal grading scale (severities, grade calculation table) |
| `templates/scripts/grade.sh` | Reads issue list, applies rubric, prints grade. Deterministic. |
| `templates/scripts/build-project-index.sh` | Pre-pass for discovery: file inventory + language breakdown + notable files |
