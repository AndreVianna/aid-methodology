---
profile: agentic-pipeline
target_diagrams: 5
notes: "AI-agent orchestration pipelines — skills, agents, KB, dispatch contracts, review/grade/fix loops. The pipeline shape (sequential phases with feedback loops) is the distinctive structure."
---

# Section Template — `agentic-pipeline` Profile

For projects that orchestrate AI agents through a staged pipeline (sequential phases with phase gates and feedback loops). Examples: AID itself (10-skill development pipeline), AI customer-support escalation pipelines, AI legal-document-review pipelines, AI content-moderation pipelines, any methodology where AI agents do work in defined phases under a controlling harness.

Distinct from `library` (no UI but exports an API; this profile exports *skills + agents*, not symbols) and from `cli` (CLI binaries take flags; this profile invokes *slash commands* that dispatch agents).

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | STATE.md, project-structure.md |
| 2 | The Pipeline | ★ | architecture.md, repo-presentation.md |
| 3 | Phases & Skills | ★ | feature-inventory.md, module-map.md |
| 4 | Agent Model & Tiers | ★ | module-map.md, pipeline-contracts.md |
| 5 | Knowledge Base Shape | | schemas.md, INDEX.md |
| 6 | Pipeline Contracts | | pipeline-contracts.md |
| 7 | Authoring & Quality Gates | | coding-standards.md, test-landscape.md |
| 8 | Distribution / Install | | infrastructure.md, repo-presentation.md |
| 9 | Test Landscape | | test-landscape.md |
| 10 | Tech Debt | | tech-debt.md |
| 11 | Documentation Surface | | repo-presentation.md |
| 12 | Knowledge Base Index | | INDEX.md |

## Diagrams

| Fig | Type | Subject |
|-----|------|---------|
| 1 | flowchart LR | Pipeline phases with phase gates and feedback loops — the canonical sequential flow (e.g., for AID: Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor) |
| 2 | graph TD | Agent dispatch model — how a skill dispatches a sub-agent; agent tier hierarchy (Large / Medium / Small or per-project equivalent) |
| 3 | flowchart TB | Distribution model — canonical source → renderer → install trees (one per supported tool host); shows the multi-tool distribution shape if applicable |
| 4 | erDiagram | Knowledge Base document schema — the cardinality and relationships of the KB docs the agents read and write |
| 5 | flowchart LR | Quality gate loop — the REVIEW → grade → FIX → REVIEW → APPROVAL cycle that runs inside each phase (the "review-fix" loop that converges to A+) |

## Section content guidance

### §2 The Pipeline

The defining diagram: a top-to-bottom or left-to-right pipeline of named phases with explicit phase gates (where the user approves transitions) and feedback loops (where downstream phases can revise upstream artifacts). Cite the methodology spec line range (`methodology/*.md:N-M`) for each phase if available. Explain *why* the pipeline is sequential by default, and *which* feedback loops exist as escape hatches.

### §3 Phases & Skills

For each phase / skill, render a card with: skill name (slash command if applicable), one-sentence purpose, state-machine shape (e.g., `GENERATE → REVIEW → FIX → DONE`), dispatched sub-agents, key inputs / outputs. Featured because adopters scanning the summary mostly want to know *what skills exist* and *what each does*.

### §4 Agent Model & Tiers

Render the agent tier diagram (e.g., AID's Large/Medium/Small tier model). For each tier, list the agents in that tier and their dispatch profiles (which skills dispatch them, in which states). Include the reviewer/executor separation pattern if applicable (the rule that the reviewer is never the same agent that built the artifact). Featured because the agent model is the *active* mechanism that does the work.

### §5 Knowledge Base Shape

Render an erDiagram of the KB documents: which docs are primary vs meta vs generated, which depend on others (e.g., INDEX.md derives from each doc's frontmatter intent), per-doc role. Reference the schema doc that defines the contracts (`schemas.md` or equivalent). If the project has a flexible doc-set (e.g., adopter customization), explain the standard default + how to extend.

### §6 Pipeline Contracts

The interfaces that hold the pipeline together: skill ↔ sub-agent dispatch contracts (what prompt fields are mandatory), script CLI signatures + exit codes, file-format contracts (settings.yml, STATE.md sections, manifest / heartbeat schemas), and the canonical → render → install contract (if multi-tool). One subsection per contract; cite source for each.

### §7 Authoring & Quality Gates

The review-grade-fix discipline that makes the pipeline self-correcting: reviewer dispatch contract, grading rubric, severity scale, the ledger format (if a structured findings ledger is used), and the rule about reviewer ≠ executor. Explain the *philosophy* — the reviewer is the safety net, the orchestrator owns catching all errors before review.

### §8 Distribution / Install

How the project ships to adopters: install script (setup.sh / setup.ps1), supported tool hosts (Claude Code / Codex / Cursor / etc. for AID), what gets copied where, runtime requirements (Node, Python, Git Bash on Windows). If multi-tool, include the canonical → 3-profile distribution model diagram (Fig 3).

### §11 Documentation Surface

How the project presents itself to adopters: README structure, docs/ taxonomy, examples/ catalog, methodology spec link, external references (blog posts, papers). This is the user-facing surface — what a first-time visitor sees before installing.

## Skipped sections (vs web-app)

- ✗ Frontend Architecture (no UI runtime; the *agents* are the runtime)
- ✗ HTTP Request Flow (no server; dispatch happens locally between skills and sub-agents)
- ✗ Integration Hub diagram (no external services in the agentic-pipeline shape; replaced by the agent dispatch model in Fig 2)

## Differences in cards / palette

- "Features" → "Skills" or "Phases" (terminology specific to agentic pipelines)
- "Endpoints" → "Slash commands" (if the project invokes skills via slash commands)
- "Services" → "Agents" (the agents are what does the work)
- "Modules" → "Skills" + "Agents" (split the module-map into the two distinct concerns)
- "Data Model" → "Knowledge Base Shape" (the KB is the persistent state, not a database)
- Palette: prefer cooler / more neutral colors (this is methodology, not a consumer-facing product). Use accent color for phase gates / quality boundaries to emphasize the controlled-handoff philosophy.
