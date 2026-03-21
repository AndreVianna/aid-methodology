# AID Agents

Agents in AID are **specialties**, not phases. Each agent has a focused area of expertise and is invoked when that expertise is needed — regardless of which phase the pipeline is in.

## Core vs. Specialist

AID agents are divided into two categories:

- **Core Agents** (7) — always present in the pipeline. Every project uses them.
- **Specialist Agents** (6) — invoked ad-hoc when their expertise is needed. Not every project uses every specialist.

---

## Core Agents

These agents form the backbone of every AID pipeline:

| Agent | Specialty | Typical Phases | Model |
|-------|-----------|----------------|-------|
| [**Orchestrator**](orchestrator/) | Pipeline coordination, routing, human gates | All | opus |
| [**Researcher**](researcher/) | Investigation, KB generation, analysis | Discover, Track, any | sonnet |
| [**Interviewer**](interviewer/) | Adaptive dialogue, requirements gathering | Interview | opus |
| [**Architect**](architect/) | Design: specs, plans, task decomposition | Specify, Plan, Detail | opus |
| [**Developer**](developer/) | Code implementation (only agent that writes code) | Implement | sonnet/opus |
| [**Critic**](critic/) | Quality evaluation, grading (A+ to F) | Review, Test | opus |
| [**Operator**](operator/) | Deployment, PR creation, release management | Deploy | sonnet |

### How Core Agents Map to Phases

```
Discover    → Researcher
Interview   → Interviewer
Specify     → Architect
Plan        → Architect
Detail      → Architect
Implement   → Developer
Review      → Critic
Test        → Critic
Deploy      → Operator
Track       → Researcher
Triage      → Orchestrator (performs root cause analysis for bugs, routes to Developer or Discover)
```

The Orchestrator coordinates all of the above, managing transitions and routing feedback artifacts.

---

## Specialist Agents

These agents are invoked on demand when specific expertise is needed:

| Agent | Specialty | Called By | Model |
|-------|-----------|-----------|-------|
| [**UX Designer**](ux-designer/) | UI/UX, accessibility (WCAG), user flows | Architect, Critic | sonnet |
| [**DevOps**](devops/) | CI/CD, IaC, containerization, monitoring | Operator, Researcher | sonnet |
| [**Tech Writer**](tech-writer/) | Documentation, API docs, changelogs | Operator, Architect | sonnet |
| [**Security**](security/) | Threat modeling, OWASP, auth, dependency audit | Critic, Researcher | opus |
| [**Data Engineer**](data-engineer/) | Schema, migrations, queries, ETL | Architect, Developer | sonnet |
| [**Performance**](performance/) | Profiling, load testing, caching, optimization | Critic, Researcher | sonnet |

### When to Call a Specialist

The Orchestrator (or any core agent) invokes a specialist when:

- **UX Designer** — the feature has a user interface, or accessibility review is needed
- **DevOps** — CI/CD pipeline needs setup/modification, or infrastructure changes are required
- **Tech Writer** — a release needs documentation, or specs need clarity review
- **Security** — code touches auth, handles user data, or a security audit is due
- **Data Engineer** — schema changes, new migrations, or query performance issues
- **Performance** — load testing needed, performance regression detected, or scaling decisions required

---

## Design Principles

### Specialty over Phase

The old approach assigned one agent per phase (discoverer, interviewer, tester, etc.). The new approach assigns agents by *expertise*. This means:

- The **Researcher** handles both Discovery and Track — same skill (investigation), different phases
- The **Architect** handles Specify, Plan, and Detail — same skill (design), different granularities
- The **Critic** handles both Review and Test — same skill (evaluation), different artifacts

### Separation of Concerns

- Only the **Developer** modifies production code
- Only the **Critic** grades quality
- Only the **Operator** executes external actions
- The **Orchestrator** never implements — it coordinates

### Adversarial by Design

The **Critic** is adversarial to the **Developer**. This is intentional. The agent that writes code should never be the agent that evaluates it.

---

## File Formats

Each agent has documentation in three formats:

| Format | Location | Purpose |
|--------|----------|---------|
| `agents/{name}/README.md` | This directory | Human-readable, rich documentation |
| `claude-code/agents/{name}.md` | Claude Code format | LLM-optimized with YAML frontmatter |
| `codex/agents/{name}.toml` | Codex TOML format | LLM-optimized for OpenAI Codex CLI |
