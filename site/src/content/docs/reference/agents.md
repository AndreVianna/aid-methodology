---
title: 'Agents'
description: 'All 9 AID pipeline agents — grouped by model tier, with role, tools, and source definition.'
generatedFrom: 'canonical/agents/*/AGENT.md'
---

<!-- generated — do not edit; source: canonical/agents/*/AGENT.md -->

AID runs **9 specialized agents** across three model tiers. The separation is structural: the reviewer's tier is always **≥** the executor's, and the agent that writes code never grades its own work. Each profile maps these tiers to concrete models (see [the Agent Model](/concepts/methodology/#5-the-agent-model)). Generated from `canonical/agents/`.

## Large tier

Highest-stakes work — requirements, architecture, brownfield discovery, and adversarial review.

### `aid-architect`

**Tools:** Read, Glob, Grep, Write, Edit, Bash

Transforms requirements, SPEC, and KB into design output — SPEC sections, typed dependency-ordered task breakdowns, feature decomposition, delivery sequencing, and DESIGN-typed task execution including UX and flow advice.

[Definition: `canonical/agents/aid-architect/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-architect/AGENT.md)

### `aid-interviewer`

**Tools:** Read, Glob, Grep, Bash

Conducts adaptive one-question-at-a-time dialogue with human stakeholders to gather requirements, clarify ambiguity, and produce REQUIREMENTS.md or Q&A entries.

[Definition: `canonical/agents/aid-interviewer/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-interviewer/AGENT.md)

### `aid-researcher`

**Tools:** Read, Glob, Grep, Bash, Write, WebSearch, WebFetch

Reads and analyzes code, docs, logs, APIs, and external web sources to produce structured Knowledge Base documents and analysis reports — covering existing-state cataloguing, dependency/integration/convention mapping, telemetry interpretation, security analysis, performance profiling, and web-sourced prior art. Web sources are cited with a URL and access date.

[Definition: `canonical/agents/aid-researcher/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-researcher/AGENT.md)

### `aid-reviewer`

**Tools:** Read, Glob, Grep, Bash

Adversarial quality evaluator. Reviews any artifact (code, tasks, specs, plans, KB docs) against its acceptance criteria, rubric, and KB conventions. Produces the 7-column issue ledger with source and severity tags. Does NOT fix anything; does NOT compute the grade.

[Definition: `canonical/agents/aid-reviewer/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-reviewer/AGENT.md)

## Medium tier

The production workhorses — implementation, delivery, coordination, and documentation.

### `aid-developer`

**Tools:** Read, Glob, Grep, Write, Edit, Bash

The only agent that modifies production code. Implements TASK files following specs and KB conventions across all implementation task types (IMPLEMENT, TEST, REFACTOR, CONFIGURE, MIGRATE, FIX), with mandatory build verification and formal IMPEDIMENT.md escalation.

[Definition: `canonical/agents/aid-developer/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-developer/AGENT.md)

### `aid-operator`

**Tools:** Read, Glob, Grep, Bash, Write

Runs final release verification, packages artifacts, creates PRs and release notes, manages releases, and updates the KB on ship. Safety-first, verification-focused.

[Definition: `canonical/agents/aid-operator/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-operator/AGENT.md)

### `aid-orchestrator`

**Tools:** Read, Glob, Grep, Bash

Routes pipeline findings to the next phase or skill, enforces human gates, dispatches agents with context, and manages parallel execution.

[Definition: `canonical/agents/aid-orchestrator/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-orchestrator/AGENT.md)

### `aid-tech-writer`

**Tools:** Read, Glob, Grep, Write, Edit, Bash

Authors user-facing documentation — API docs, changelogs, READMEs, release notes, user guides — and reviews existing docs for quality and accuracy.

[Definition: `canonical/agents/aid-tech-writer/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-tech-writer/AGENT.md)

## Small tier

Deterministic, mechanical operations — extract, format, enumerate.

### `aid-clerk`

**Tools:** Read, Glob, Grep, Write, Edit, Bash

INTERNAL UTILITY (sub-agent only — do NOT invoke from a skill). Performs one mechanical, schema-bounded operation per dispatch — file extraction, template placeholder-fill, or glob enumeration — returning a markdown table or file with path and line evidence.

[Definition: `canonical/agents/aid-clerk/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-clerk/AGENT.md)
