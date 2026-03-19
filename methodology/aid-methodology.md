# AID — AI-Integrated Development

**A Complete Methodology for AI-Integrated Software Development**

*Version 3.0 — March 2026*

---

## Executive Summary

AID (AI-Integrated Development) is a structured methodology for building and maintaining software with AI agents. It defines twelve sequential phases organized into five groups — from problem mapping through production monitoring and maintenance — with formal feedback loops that allow any phase to revise upstream artifacts when reality contradicts assumptions.

Each phase is **co-executed by human and AI**. The AI is the Iron Man suit — it amplifies the human's capabilities. The human is the pilot — setting direction, making decisions, approving advancement between phases. The human never leaves the cockpit. This is not "AI executes, human validates." It is "human and AI work together, human drives."

The methodology covers the full lifecycle:

- **Problem Mapping** (2 phases): Understand the system and gather requirements.
- **Planning** (3 phases): Specify, plan the roadmap, detail the execution.
- **Implementation** (3 phases): Build, review, and test.
- **Production** (2 phases): Deploy and monitor.
- **Maintenance** (2 phases): Classify issues and fix bugs.

Bugs take a short path back through implementation. Change requests start a new development cycle. Nothing falls on the floor.

The methodology is built on three convictions:

1. **Understanding precedes specification.** You cannot write a useful spec for a system you don't understand. Brownfield projects (90% of enterprise work) require structured discovery before anything else.
2. **Specs are hypotheses, not contracts.** Implementation reveals truths that specification cannot anticipate. A methodology without formal revision protocols is a methodology that produces silent workarounds and hidden debt.
3. **The Knowledge Base is the gravitational center.** Not the spec. Not the code. The accumulated understanding of the project — architecture, conventions, domain language, tech debt — persists across phases, sprints, and team changes.

This document defines the complete methodology: philosophy, phases, artifacts, feedback loops, and practical guidance for adoption.

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [The Knowledge Base](#2-the-knowledge-base)
3. [The Twelve Phases](#3-the-twelve-phases)
4. [Feedback Loops](#4-feedback-loops)
5. [Artifacts Reference](#5-artifacts-reference)
6. [The Pipeline](#6-the-pipeline)
7. [Case Studies](#7-case-studies)
8. [Comparison with SDD](#8-comparison-with-sdd)
9. [Adoption Guide](#9-adoption-guide)

---

## 1. Philosophy

### It's Waterfall. And That's the Point.

Understand → Specify → Plan → Build → Verify → Ship.

This is the Waterfall sequence. We embrace it deliberately.

Waterfall failed not because the sequence was wrong, but because humans couldn't execute it fast enough to afford iteration. When discovery takes weeks and specs take days, going back to fix a wrong assumption costs a sprint. Teams learned to skip forward, hack around problems, and call it "agile."

AI changes the economics:

- **Discovery** that took weeks takes hours. An agent can scan a 21GB codebase, map its architecture, catalog its conventions, and produce a Knowledge Base in a single session.
- **Specification** that took days takes minutes. With a Knowledge Base as context, generating a grounded spec is a single prompt, not a week of meetings.
- **Iteration is cheap.** Feedback loops cost tokens, not sprints. Going back to Discovery to fill a knowledge gap costs pennies, not calendar weeks.
- **Documents don't rot.** The same agents that write code maintain the Knowledge Base and specs. They don't get stale because maintaining them is nearly free.

Agile was the right answer to Waterfall's execution problem. AI is the right answer to Agile's rigor problem. AID is Waterfall with AI execution and formal feedback loops — the methodology that finally works because the bottleneck shifted from "humans are slow" to "humans set direction."

### Human-in-the-Middle

Every phase is co-executed by human + AI. Not "AI executes, human rubber-stamps." Not "human does the thinking, AI does the typing." The human and AI work together within each phase, with the AI amplifying the human's capabilities.

**Between phases, the human gives the OK to advance.** The pipeline never auto-advances. The human reviews the phase output, decides if it's good enough, and greenlights the next phase. This is the checkpoint that keeps the human in control without slowing the work to human speed.

**The roles:**
- **Human:** Pilot. Sets direction, makes judgment calls, holds accountability, approves phase transitions.
- **AI:** Iron Man suit. Amplifies capability — scans codebases in hours, generates specs in minutes, implements tasks, runs reviews, monitors production. Does what the human directs, faster and more thoroughly than the human alone could.

This framing matters. The AI is not autonomous. The AI is not a junior developer that needs supervision. The AI is a power multiplier that makes the human dangerous.

### Three Core Principles

**1. Knowledge Before Specification**

Every methodology tells you to "write good specs." None tells you how to understand a system well enough to write them. AID does. The Discovery phase produces a Knowledge Base — a structured collection of documents covering architecture, conventions, data models, integrations, tech debt, and domain language. The spec is then written *against* this knowledge, not from imagination.

**2. Specs Are Living Documents**

A spec written before implementation is a hypothesis. A spec revised after implementation is knowledge. AID treats specs as living artifacts with formal revision protocols. Every change is tracked, justified, and approved. This isn't chaos — it's controlled evolution.

**3. Feedback Over Forward-Only**

The pipeline is sequential by default, but any phase can trigger upstream revision through structured protocols. Discovery can be re-entered from any phase. Specs can be revised during planning. Tasks can be amended during implementation. The revision trail provides audit transparency while keeping the project moving.

### Roles

AID defines three roles:

| Role | Responsibility |
|------|---------------|
| **Director** | A human. Sets direction, makes decisions, reviews artifacts, approves phase transitions. Spends 2-3 hours/day orchestrating, not coding. |
| **Orchestrator** | An AI agent (or human). Manages the pipeline: spawns agents, routes feedback loops, enforces quality gates, maintains the Knowledge Base. |
| **Specialist** | An AI coding agent (Claude Code, Codex, or similar). Executes tasks within defined scope. Reports impediments rather than working around them. |

The Director never writes code. The Specialist never makes architectural decisions. The Orchestrator bridges both.

---

## 2. The Knowledge Base

The Knowledge Base (`knowledge/`) is the gravitational center of the entire methodology. Every phase reads from it. Any phase can trigger updates to it.

### Structure

```
knowledge/
├── README.md              # Index with completeness status per document
├── architecture.md        # Patterns, layers, module boundaries, data flow
├── module-map.md          # Every module: purpose, dependencies, size, test coverage
├── technology-stack.md    # Languages, frameworks, versions, package managers, runtime
├── coding-standards.md    # Naming conventions, formatting, error handling patterns
├── data-model.md          # Database schema, entities, relationships, migrations
├── api-contracts.md       # External APIs consumed/exposed, auth models, rate limits
├── integration-map.md     # Message queues, caches, third-party services, webhooks
├── domain-glossary.md     # Business terms, domain language, entity definitions
├── test-landscape.md      # Test frameworks, coverage, test types, CI/CD pipeline
├── security-model.md      # Auth/authz, secrets management, compliance requirements
├── tech-debt.md           # Known debt items with file refs, risk ratings, remediation
├── infrastructure.md      # Hosting, networking, environments, deployment model
└── open-questions.md      # Things that need human clarification
```

### Completeness Is Tracked

The `README.md` at the root of the Knowledge Base tracks what exists and what's missing:

```markdown
# Knowledge Base — {Project Name}

| Document | Status | Last Updated | Source |
|----------|--------|-------------|--------|
| architecture.md | ✅ Complete | Mar 16 | aid-discover |
| coding-standards.md | ⚠️ Partial | Mar 16 | aid-discover (inferred) |
| domain-glossary.md | ❌ Missing | — | Needs interview |
| security-model.md | ❌ Missing | — | Needs interview |
```

### Not Every Document Is Required

The Discovery phase assesses the project and generates what's relevant:

- **Simple CLI tool?** Maybe 5 documents.
- **Enterprise monorepo?** All 13.
- **Greenfield?** Only `technology-stack.md`, `coding-standards.md`, and `domain-glossary.md` — populated from the interview, not from code.

### The KB Outlives the Project

The Knowledge Base is institutional memory. It outlives any individual session, sprint, or developer. When a new team member joins — human or AI — they read the KB and have the project's full context. When a feature request arrives six months later, the KB tells you what the system looks like now, not what the spec said it should look like.

---

## 3. The Twelve Phases

AID organizes twelve phases into five groups. The pipeline is linear with feedback loops. Post-production phases monitor and route issues back into development through one of two paths:

- **Bug path (short):** Track → Triage → Correct → Implement → Review → Test → Deploy. Surgical. No re-specification, no re-planning. The correction maps the fix; the existing pipeline executes it.
- **Change Request path (full cycle):** Track → Triage → Discover. The CR enters as a new project, running the complete pipeline from the beginning.

---

### Group 1: Problem Mapping

*Understand the system and gather requirements.*

---

#### Phase 1: Discover (`aid-discover`)

**Purpose:** Understand the existing system. Produce the Knowledge Base.

**Input:** Access to the codebase (git repo, file system, or archive).

**Process:**
1. **Structure scan** — Detect project type, map folder layout, list modules/packages.
2. **Architecture analysis** — Identify patterns, layers, boundaries, data flow.
3. **Stack inventory** — Languages, frameworks, versions, build tools, runtime.
4. **Convention mining** — Naming patterns, error handling, logging, config management (inferred from code).
5. **Module mapping** — Every module: purpose, dependencies, size, test coverage.
6. **Data model extraction** — Schema, entities, relationships, migrations.
7. **Integration surface** — External APIs, message queues, caches, third-party services.
8. **Test landscape** — Frameworks, coverage metrics, test types, CI/CD pipeline.
9. **Tech debt audit** — Large files, circular dependencies, missing tests, outdated packages.
10. **Gap identification** — What we couldn't determine from code alone → feeds into Interview.

**Output:** `knowledge/` directory — the project's Knowledge Base.

**When to skip:** Pure greenfield projects with no existing code. Interview populates a minimal KB instead.

**When to re-enter:** Any downstream phase discovers the KB is wrong or incomplete. Re-entry is always *targeted* — fill the specific gap, not redo full discovery.

#### Phase 2: Interview (`aid-interview`)

**Purpose:** Gather requirements from the human stakeholder. Produce REQUIREMENTS.md.

**Input:** KB (if brownfield) or project description (if greenfield). A human to interview.

**Process:**

The interview is driven by a **knowledge model** — a structured map of what a complete REQUIREMENTS.md needs, with each field tracked as `known`, `unknown`, or `assumed`.

**Question selection:**
1. Scan knowledge model for `unknown` fields.
2. Prioritize by dependency: fields that unblock other fields go first.
3. Batch efficiency: confirm `assumed` fields alongside new questions when natural.
4. Open questions early ("Tell me about your users") → specific later ("Do you need HIPAA compliance?").
5. Never ask what the KB already answered — mark as `known (from discovery)`, but flag critical items for confirmation.

**Key behaviors:**
- One question at a time. Humans think better with focused prompts.
- Each answer shapes the next question. Adaptive, not scripted.
- Brownfield interviews are shorter (KB pre-fills technical fields). Greenfield are longer.

**Output:** `REQUIREMENTS.md` — structured requirements with Problem Statement, Users, Features (priority-ordered), Technical Context, Constraints, Assumptions, and Out of Scope.

**Feedback to Discovery:** If an answer reveals the KB is wrong or incomplete, the interview pauses, triggers targeted discovery, then resumes with corrected understanding.

---

### Group 2: Planning

*From requirements to execution-ready tasks.*

---

#### Phase 3: Specify (`aid-specify`)

**Purpose:** Transform requirements into a formal specification grounded in the Knowledge Base.

**Input:** `REQUIREMENTS.md` + `knowledge/` directory.

**Process:**
1. Read REQUIREMENTS.md for what to build.
2. Read KB for how the system currently works.
3. Generate SPEC.md that specifies new behavior *in the context of existing behavior*.
4. Reference specific KB documents: "Following the repository pattern established in `knowledge/architecture.md`" rather than generic "use repository pattern."
5. Identify conflicts between requirements and existing architecture. Document explicitly.
6. Define non-functional requirements grounded in current system capabilities.

**What makes this different from generic spec generation:** The spec is grounded. It doesn't say "use dependency injection" — it says "register in `ServiceCollectionExtensions.cs` following the pattern in `knowledge/coding-standards.md` §3.2."

**Output:** `SPEC.md` — Vision, Constraints, Architecture, Domain Model, Non-Functional Requirements. Every architectural decision references the KB.

**Feedback to Discovery:** If writing the spec exposes insufficient understanding, generate a `GAP.md` and trigger targeted discovery.

#### Phase 4: Plan (`aid-plan`)

**Purpose:** Define the high-level roadmap — MVP scope, modules, deliverables, test scenarios.

**Input:** `SPEC.md` + `knowledge/` directory.

**Process:**
1. Define the MVP — smallest shippable set of features that delivers value.
2. Identify modules — logical groupings of functionality mapped to the codebase.
3. Scope deliverables — shippable increments with natural boundaries.
4. Define test scenarios — high-level scenarios that prove each deliverable works.
5. Assess risks — what could derail the plan, and mitigations.
6. Identify spikes — unknowns that need research before detailing.

**Plan is strategy, not tactics.** It answers "what do we build and in what order?" — not "how do we build each piece." The Detail phase handles decomposition into tasks.

**Output:** `PLAN.md` — MVP definition, module map, deliverables with ordering and dependencies, test scenarios, risk assessment.

**Feedback loops:**
- If planning reveals KB gaps → `GAP.md` with `discovery-needed`, trigger targeted discovery.
- If the spec is ambiguous → `GAP.md` with `ambiguity`, trigger spec revision or targeted interview.

#### Phase 5: Detail (`aid-detail`)

**Purpose:** Decompose the plan into sprint-ready user stories, executable tasks, and execution order.

**Input:** `PLAN.md` + `SPEC.md` + `knowledge/` directory.

**Process:**
1. **User story decomposition** — For each deliverable, generate user stories with acceptance criteria.
2. **Task decomposition** — For each story, generate executable tasks sized for a single agent session.
3. **Precedence analysis** — Map dependencies between tasks. Identify parallel execution opportunities.
4. **Complexity estimation** — S/M/L/XL based on KB data (files touched, test coverage, tech debt).
5. **Delivery breakdown** — Group tasks into delivery increments with success criteria.
6. **Execution plan** — Organize tasks into waves for parallel execution.

**Detail is tactics, not strategy.** It turns the roadmap into a work breakdown structure that agents can execute.

**Output:**
- `DETAIL.md` — User stories, task list, precedence graph, delivery breakdown, execution waves.
- `TASK-{id}.md` files — One per task with objective, interface contracts, acceptance criteria, test requirements.

**Feedback loops:**
- If the plan is too vague → return to aid-plan for revision.
- If KB gaps are found → trigger targeted discovery.
- If spec is ambiguous → trigger spec revision.

---

### Group 3: Implementation

*Build, review, and test the code.*

---

#### Phase 6: Implement (`aid-implement`)

**Purpose:** Execute a task using an AI coding agent, with full context from the Knowledge Base.

**Input:** `TASK-{id}.md` + `SPEC.md` + relevant KB documents.

**Process:**
1. Load task spec as the primary prompt.
2. Load SPEC.md + KB coding standards + architecture as context.
3. Spawn coding agent with this context.
4. Agent implements the task, creating/modifying files and adding tests.
5. **Build verification is mandatory.** "Done" means green build, not "I wrote some code."

**Multi-agent parallel execution:** When the detail plan identifies independent tasks, multiple agents can execute simultaneously. Each gets its own branch. The orchestrator merges results.

**Impediment protocol:** When the agent discovers assumptions don't hold, it generates an `IMPEDIMENT.md` rather than silently working around the problem. Silent workarounds are how tech debt is born.

**Output:** Code changes + tests on a feature branch. Build green. Test green.

#### Phase 7: Review (`aid-review`)

**Purpose:** Static code review — verify implementation quality against task spec, project spec, and KB standards.

**Input:** Git diff + `TASK-{id}.md` + `SPEC.md` + `knowledge/coding-standards.md`.

**Process:**
1. Check against TASK acceptance criteria.
2. Check against SPEC architectural constraints.
3. Check against KB coding standards.
4. Run automated checks: build, tests, lint.
5. Grade the implementation: A+ through F.
6. Tag each issue by source: CODE, TASK, SPEC, KB, ARCHITECTURE.
7. P1/P2 CODE issues: auto-fix. Everything else: escalate.

**Grading scale:**
- **A+ / A / A-**: Ship-ready. Proceed to testing.
- **B+ / B / B-**: Needs cleanup. One review cycle.
- **C+ / C / C-**: Significant issues. Partial re-implementation.
- **D / F**: Fundamental problems. Re-implement from task spec.

**Output:** `REVIEW.md` — issues found, grade, suggested fixes.

#### Phase 8: Test (`aid-test`)

**Purpose:** Dynamic validation in staging — E2E tests, integration tests, manual testing.

**Input:** Reviewed code (grade A- or above) + `DELIVERY-{id}.md` + `SPEC.md`.

**Process:**
1. Deploy to staging environment.
2. Run full automated test suite (unit, integration, E2E).
3. Validate user story acceptance criteria in staging.
4. Test non-functional requirements (performance, concurrency, error handling).
5. Manual testing where automation isn't feasible.

**The gate between review and deploy.** Review catches what code *looks like*. Test catches what code *does*. Both gates are necessary.

**Verdict:**
- **PASS** — All tests pass, all acceptance criteria verified.
- **PASS WITH NOTES** — All critical tests pass, minor issues documented.
- **FAIL** — Critical issues found. Deploy blocked.

**Output:** `TEST-REPORT.md` — test results, coverage, verdict.

**Feedback loops:**
- Test failure → aid-implement (fix the bug, then re-review, re-test).
- Test reveals spec gap → aid-specify (revise spec, update tasks, re-implement).

---

### Group 4: Production

*Ship and monitor.*

---

#### Phase 9: Deploy (`aid-deploy`)

**Purpose:** Package, verify, and ship the completed delivery to production.

**Input:** Tested code (TEST-REPORT.md passed) + all previous artifacts.

**Process:**
1. **Final verification:** Full build + complete test suite. Zero failures.
2. **Delivery summary:** Files changed, features added, test delta, spec revisions.
3. **PR creation:** Structured description referencing delivery, tasks, test results.
4. **Documentation updates:** Ensure KB reflects any discoveries from implementation.
5. **Artifact status update:** Mark delivery and tasks complete.

**Output:**
- Pull Request ready for merge.
- `DELIVERY-{id}.md` updated with completion status.
- KB updated with any new discoveries.
- Delivery summary for stakeholder communication.

#### Phase 10: Track (`aid-track`)

**Purpose:** Monitor production. Interpret telemetry, error logs, issue trackers, and performance metrics.

**Input:** Telemetry, error logs, issue tracking, performance metrics, user feedback, CI/CD results.

**Process:**
1. **Data collection** — Pull from configured sources.
2. **Anomaly detection** — Identify deviations from baseline.
3. **Trend analysis** — Spot patterns over time.
4. **Correlation** — Connect signals across sources.
5. **Impact assessment** — Evaluate severity.
6. **KB context** — Cross-reference against knowledge/ to distinguish expected behavior from anomalies.

**Key distinction:** Track *interprets*, it doesn't just collect. A dashboard shows you a spike. Track tells you "error rate increased 340% after deploy #47, concentrated in the payment module, affecting ~2,000 users, correlating with the async refactor."

**Output:** `TRACK-REPORT.md` — findings with evidence, severity, recommended action.

**When to trigger:** On deployment, on schedule, on alert threshold, or on-demand.

---

### Group 5: Maintenance

*Classify issues and fix bugs.*

---

#### Phase 11: Triage (`aid-triage`)

**Purpose:** Classify what Track found. Route it to the right path.

**Input:** `TRACK-REPORT.md` + `knowledge/` + `SPEC.md`.

**Classification:**
- **BUG** — Code doesn't match spec. Route to aid-correct (short path).
- **Change Request** — Spec is wrong or incomplete. Route to aid-discover (new cycle).
- **Infrastructure** — Not a code issue. Escalate to ops.
- **No Action** — False positive, expected behavior, or below threshold.

**The hard call:** Bug vs. CR. If the spec said "do X" and the code doesn't do X — bug. If users now need Y instead of X — CR, even if the code "works."

**Output:** `TRIAGE.md` — classification, evidence, severity, routing decision.

#### Phase 12: Correct (`aid-correct`)

**Purpose:** Map the fix for a bug. Root cause analysis, patch scope, handoff to implementation.

**Input:** `TRIAGE.md` (classified as BUG) + `knowledge/` + `SPEC.md`.

**Process:**
1. **Root cause analysis** — Trace from symptom to cause using the KB.
2. **Impact mapping** — What else does this affect? Check module consumers, test coverage.
3. **Patch scope** — Define exactly what changes. Minimal surface area.
4. **Regression check** — What existing tests should catch this?
5. **Generate CORRECTION.md** — A surgical task spec for aid-implement.

**The short path:** Correct → Implement → Review → Test → Deploy. Five phases, not twelve. The correction skips problem mapping, planning, and detail because the spec is already correct — the code just doesn't match it.

**Output:** `CORRECTION.md` — root cause, files to touch, patch scope, test requirements.

---

## 4. Feedback Loops

The pipeline is sequential by default. But real engineering isn't linear. Assumptions break. Gaps appear. Production reveals truths that development couldn't anticipate. AID defines eleven formal feedback loops — eight within development and three connecting production back to development.

### The Eleven Loops

#### Development Loops (1-8)

#### Loop 1: Interview → Discovery

**Trigger:** During the interview, a human's answer reveals the KB is wrong or incomplete.

**Protocol:** Interview pauses → targeted discovery on the specific area → KB updated → interview resumes with corrected understanding.

#### Loop 2: Specify → Discovery

**Trigger:** Writing the spec exposes insufficient understanding of a subsystem.

**Protocol:** Specify pauses → `GAP.md` generated with type `discovery-needed` → targeted discovery → KB updated → specify resumes.

#### Loop 3: Plan → Discovery

**Trigger:** Planning reveals that the codebase is more complex than the KB captured.

**Protocol:** `GAP.md` generated → targeted discovery → KB updated → planning resumes.

#### Loop 4: Plan → Specify

**Trigger:** The KB is complete, but the SPEC is ambiguous or contradictory.

**Protocol:** `GAP.md` with type `ambiguity` or `contradiction` → spec revision (possibly with targeted interview) → planning resumes.

#### Loop 5: Detail → Plan

**Trigger:** The plan is too vague to decompose into tasks. Deliverables are too broad, module boundaries unclear, or test scenarios don't map to features.

**Protocol:** Detail documents the gap → Plan revises the specific section → Detail resumes.

#### Loop 6: Implement → Discovery / Plan / Spec

**Trigger:** The agent discovers that assumptions don't hold in the actual codebase.

**Protocol:** `IMPEDIMENT.md` generated → if KB gap, update KB → if resolvable within scope, resolve and document → if requires plan/spec change, pause and escalate.

#### Loop 7: Review → Any Upstream Phase

**Trigger:** Review finds issues that trace to KB, spec, or plan problems — not just code quality.

**Protocol:** Issues tagged by source (CODE/TASK/SPEC/KB/ARCHITECTURE). CODE issues are fixed in-cycle. Everything else pauses the pipeline and escalates.

#### Loop 8: Test → Implement

**Trigger:** Tests fail due to implementation bugs discovered in staging.

**Protocol:** Failures documented in TEST-REPORT.md → route back to aid-implement for fix → aid-review (quick review) → aid-test (re-run).

#### Post-Production Loops (9-11)

#### Loop 9: Track → Triage

**Trigger:** Track identifies an anomaly above the severity threshold.

**Protocol:** Track produces TRACK-REPORT.md → Triage classifies each finding → routes to Correct (bug) or Discover (CR).

#### Loop 10: Triage → Correct → Implement

**Trigger:** Triage classifies a finding as BUG.

**Protocol:** Triage produces TRIAGE.md → Correct does root cause analysis → CORRECTION.md → Implement → Review → Test → Deploy. The short path.

#### Loop 11: Triage → Discover (New Cycle)

**Trigger:** Triage classifies a finding as Change Request.

**Protocol:** Triage produces TRIAGE.md with CR classification → new project cycle starts at aid-discover (or aid-interview for greenfield) → full pipeline.

### The Revision Trail

Every change to an upstream artifact is tracked at the bottom of the artifact:

```markdown
## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | Mar 1 | aid-specify | Initial spec |
| 1.1 | Mar 5 | GAP-001 (aid-plan) | Added latency requirements |
| 1.2 | Mar 8 | IMP-003 (aid-implement) | Changed sync model |
```

### Feedback Loop Artifacts

**GAP.md** — Generated by Specify, Plan, Detail, or Review when upstream artifacts are deficient.

```markdown
# GAP: GAP-001
**Source:** aid-plan, Deliverable 2
**Type:** discovery-needed | ambiguity | contradiction
**Description:** Module map shows 3 consumers of SearchService, but grep reveals 11.
**KB Gap:** module-map.md (incomplete)
**Blocking:** Deliverable 2 scoping
**Resolution:** discovery | needs-human | needs-spike
```

**IMPEDIMENT.md** — Generated by Implement when reality contradicts assumptions.

```markdown
# IMPEDIMENT: IMP-003
**Source:** aid-implement, TASK-F3a
**Type:** wrong-assumption | missing-dependency | architecture-conflict | kb-gap
**Description:** RecordingService is synchronous, not async as KB states.
**KB Impact:** architecture.md needs revision
**Options:** [A, B, C with effort and risk estimates]
**Recommendation:** [which option and why]
```

---

## 5. Artifacts Reference

### Core Artifacts

| Artifact | Produced By | Consumed By | Lifecycle |
|----------|------------|-------------|-----------|
| `knowledge/` (KB) | Discover | All phases | Living — updated throughout project |
| `REQUIREMENTS.md` | Interview | Specify | Frozen after verification (rev-tracked) |
| `SPEC.md` | Specify | Plan, Detail, Implement, Review, Test, Triage, Correct | Living — rev-tracked |
| `PLAN.md` | Plan | Detail | Living — rev-tracked |
| `DETAIL.md` | Detail | Implement, Review | Updated at completion |
| `TASK-{id}.md` | Detail | Implement, Review | Rev-tracked if amended |
| `REVIEW.md` | Review | Implement (rework), Test | Per review cycle |
| `TEST-REPORT.md` | Test | Deploy, Implement (if failures) | Per test cycle |
| `GAP.md` | Specify, Plan, Detail, Review | Discovery, Specify | Closed when resolved |
| `IMPEDIMENT.md` | Implement | Plan, Specify, Discovery | Closed when resolved |
| `TRACK-REPORT.md` | Track | Triage | Per tracking cycle |
| `TRIAGE.md` | Triage | Correct, Discover (new cycle) | Closed when routed |
| `CORRECTION.md` | Correct | Implement | Closed when fix is deployed |

### REQUIREMENTS.md Template

```markdown
# {Project Name} — Requirements

## Client
- Name: {who}
- Domain: {industry/business type}

## Problem Statement
{In their words, not ours}

## Users
| Role | Description | Primary Needs |
|------|-------------|---------------|
| ... | ... | ... |

## Features (Priority Ordered)
| # | Feature | Priority | Notes |
|---|---------|----------|-------|
| 1 | ... | Must | ... |
| 2 | ... | Should | ... |

## Technical Context
- Existing systems: {what they have}
- Integrations: {what connects}
- Platform: {where this runs}
- Data: {volume, sensitivity}

## Constraints
- Timeline: {deadline or pace}
- Budget: {range or fixed}
- Team: {who's available}
- Compliance: {if any}

## Assumptions
{Stated explicitly — must be verified}

## Out of Scope
{Prevents scope creep}
```

### SPEC.md Template

```markdown
# {Project Name} — Specification

## Vision
One paragraph. What this is and why it exists.

## Constraints
- Stack: {from KB technology-stack.md}
- Platform: {target environments}
- Performance: {measurable targets}
- Security: {auth model, compliance}

## Architecture
- Pattern: {from KB architecture.md — extend, don't reinvent}
- Data: {from KB data-model.md — extend existing schema}
- External: {from KB integration-map.md — new integrations}

## Domain Model
Key entities and relationships. Reference KB domain-glossary.md.

## Feature Specifications
For each feature: behavior, interfaces, edge cases, error handling.

## Non-Functional Requirements
Accessibility, i18n, monitoring, logging. Grounded in KB infrastructure.md.

## Revision History
| Rev | Date | Source | Description |
|-----|------|--------|-------------|
```

### PLAN.md Template

```markdown
# {Project Name} — Roadmap

## MVP Definition
**Core value:** {one sentence}
**Included features:** {list with justification}
**Deferred:** {list with reason}

## Module Map
| Module | Features | Existing Code | New Code | Risk |
|--------|----------|---------------|----------|------|

## Deliverables
### Deliverable 1: {Name}
**Modules:** {list}
**Features:** {list}
**Depends on:** {list or "None"}
**Validates:** {what this proves}

## Test Scenarios
### Deliverable 1
- TS-01: {scenario description}

## Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|

## Spikes
{If any research needed before detailing}

## Revision History
| Rev | Date | Source | Description |
|-----|------|--------|-------------|
```

### DETAIL.md Template

```markdown
# {Project Name} — Execution Detail

## User Stories
### US-{id}: {Title}
**As a** {role} **I want** {capability} **So that** {benefit}
**Acceptance Criteria:** {testable criteria}
**Source:** PLAN.md deliverable {id}, SPEC.md feature {ref}

## Task List
### TASK-{id}: {Name}
**User Story:** US-{id} | **Complexity:** S/M/L/XL
**Objective:** {1-2 sentences}
**Interface Contracts:** {public API}
**Acceptance Criteria:** {testable}
**Test Requirements:** {unit + E2E}
**Files to Touch:** {guidance}
**Depends On / Blocks:** {TASK-ids}

## Precedence Graph
{Text or mermaid diagram}

## Delivery Breakdown
### DELIVERY-{id}: {Name}
**User Stories:** {ids} | **Tasks:** {ids}
**Success Criteria:** {measurable}

## Execution Plan
### Wave 1 (parallel): {tasks}
### Wave 2 (after Wave 1): {tasks}

## Revision History
| Rev | Date | Source | Description |
|-----|------|--------|-------------|
```

### TASK-{id}.md Template

```markdown
# TASK-{id}: {Name}

**Delivery:** {delivery-id}
**Status:** Not Started | In Progress | Complete
**Complexity:** S | M | L | XL

## Objective
What this task accomplishes (1-2 sentences).

## Interface Contracts
Public interfaces this task introduces or modifies (language-specific).

## Architecture
How it fits into the existing system. Reference KB architecture.md.

## Acceptance Criteria
- [ ] Concrete, testable criteria
- [ ] With expected behavior defined
- [ ] Including edge cases

## Test Requirements
- Unit tests: what to test, expected count range
- E2E tests: which user flows to cover
- Edge cases: explicitly listed

## Files to Touch
Expected files to create/modify (guidance, not mandate).

## Notes
Gotchas, decisions, context the agent needs.
```

### TEST-REPORT.md Template

```markdown
# Test Report — {Delivery ID}: {Name}

## Environment
**Staging:** {url} | **Branch:** {branch} | **Date:** {date}

## Automated Tests
| Category | Run | Pass | Fail | Skip | Time |
|----------|-----|------|------|------|------|
| Unit | {n} | {n} | {n} | {n} | {t} |
| Integration | {n} | {n} | {n} | {n} | {t} |
| E2E | {n} | {n} | {n} | {n} | {t} |

## User Story Validation
### US-{id}: {Title}
| AC | Method | Result | Notes |
|----|--------|--------|-------|

## Non-Functional Validation
| Requirement | Target | Actual | Result |
|-------------|--------|--------|--------|

## Issues Found
| # | Severity | Category | Description | Status |
|---|----------|----------|-------------|--------|

## Verdict: {PASS | PASS WITH NOTES | FAIL}
```

### REVIEW.md Template

```markdown
# Review — {Task or Delivery ID}

## Automated Checks
- [ ] Build: zero errors, zero warnings
- [ ] Tests: all pass (unit + E2E)
- [ ] Lint/Format: clean

## Specification Compliance
- [ ] Meets TASK acceptance criteria
- [ ] Follows SPEC architectural decisions
- [ ] Matches KB coding standards

## Issues Found
| # | Severity | Tag | Description | Line | Fix |
|---|----------|-----|-------------|------|-----|

## Grade: {A+ through F}

## Recommendation
Ship to Test | Rework (minor) | Rework (major) | Re-implement
```

### TRACK-REPORT.md Template

```markdown
# Track Report — {Date or Deployment ID}

## Sources Checked
| Source | Type | Period |
|--------|------|--------|

## Findings
### Finding 1: {Title}
**Severity:** Critical | High | Medium | Low
**Source:** {where detected}
**Evidence:** {concrete data}
**Impact:** {users affected, functionality impaired}
**Correlation:** {related events}

## Recommendation
{Trigger triage or no action}
```

### TRIAGE.md Template

```markdown
# Triage — {Finding ID or Title}

## Source
**Track Report:** {ref} | **Finding:** {summary}

## Classification
**Type:** BUG | Change Request | Infrastructure | No Action
**Severity:** Critical | High | Medium | Low

## Evidence
{Concrete data supporting classification}

## Reasoning
{Why this classification. Reference SPEC.md for expected behavior.}

## Routing
- **BUG →** aid-correct (short path: correct → implement → review → test → deploy)
- **CR →** aid-discover (new cycle)
- **Infrastructure →** ops escalation
- **No Action →** closed with justification
```

### CORRECTION.md Template

```markdown
# Correction — {Bug ID or Title}

## Root Cause
{What went wrong and why. Trace from symptom to cause.}

## Impact
**Affected modules:** {from KB} | **Existing coverage:** {what should have caught this}

## Patch Scope
| File | Change | Reason |
|------|--------|--------|

## Test Requirements
- Fix verification: {test that proves the bug is fixed}
- Regression: {tests to prevent recurrence}
- Coverage gap: {tests that should have existed}

## Acceptance Criteria
- [ ] {testable criterion}
- [ ] {regression test added}
```

---

## 6. The Pipeline

### Visual Overview

```
                 ┌─────────────────────────────────────────────────┐
                 │           KNOWLEDGE BASE (knowledge/)           │
                 │    The gravitational center of the project.     │
                 │    Every phase reads from it.                   │
                 │    Any phase can trigger updates to it.         │
                 └──────────┬──────────────────────────────────────┘
                            │
         BROWNFIELD         │         GREENFIELD
             │              │              │
             ▼              │              │
   ┌─ PROBLEM MAPPING ─────┤              │
   │     aid-discover ───────┤              │
   │      → knowledge/*     │              │
   │          │              │              │
   │          ├──────────────┼──────────────┘
   │                        │
   │                        ▼
   │     aid-interview ◄─── GAP (needs-interview)
   │      → REQUIREMENTS.md
   └────────────────────────┤
                            │
   ┌─ PLANNING ─────────────┤
   │                        ▼
   │     aid-specify ◄──── GAP (ambiguity/contradiction)
   │      → SPEC.md
   │          │
   │          ▼
   │     aid-plan ◄─────── GAP (KB gap)
   │      → PLAN.md
   │          │
   │          ▼
   │     aid-detail ◄───── GAP (plan too vague)
   │      → DETAIL.md
   │      → TASK-{id}.md (×N)
   └────────────────────────┤
                            │
   ┌─ IMPLEMENTATION ──────┤
   │            ┌───────────┤
   │            │           ▼
   │            │     aid-implement ◄── IMPEDIMENT
   │            │      → code + tests
   │            │           │
   │            │           ▼
   │            │     aid-review ◄───── issue (KB/SPEC/ARCH)
   │            │      → REVIEW.md
   │            │           │
   │            │           ▼
   │            │     aid-test ◄─────── test failure → fix
   │            │      → TEST-REPORT.md
   └────────────┤──────────┤
                │          │
   ┌─ PRODUCTION ──────────┤
   │            │          ▼
   │            │     aid-deploy
   │            │      → PR + summary
   │            │          │
   │            │          ▼
   │            │     aid-track ◄────── deployment / schedule / alert
   │            │      → TRACK-REPORT.md
   └────────────┤─────────┤
                │         │
   ┌─ MAINTENANCE ────────┤
   │            │         ▼
   │            │     aid-triage
   │            │      → TRIAGE.md
   │            │         │
   │            │    ┌────┴─────┐
   │            │    │          │
   │            │ BUG ↓      CR ↓
   │            │    │          │
   │            │    ▼          └──→ aid-discover (new cycle)
   │            │ aid-correct
   │            │  → CORRECTION.md
   │            │    │
   │            └────┘ (back to aid-implement)
   └────────────────────

 ─── ANY PHASE ──→ aid-discover (targeted) ──→ knowledge/* ──→ resume
```

### The Two Post-Production Paths

**Bug path (short):** Track → Triage → Correct → Implement → Review → Test → Deploy. Five phases to fix, not twelve. Correct maps the fix surgically — root cause, files to touch, tests to add — and hands it to Implement as a task. No re-specification, no re-planning.

**Change Request path (full):** Track → Triage → Discover. The CR enters the development pipeline as a new project. It gets its own requirements, its own spec, its own plan. The full pipeline ensures that changes are understood before they're built.

### Flow Rules

1. **Linear by default.** Discover → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy → Track → Triage.
2. **Human approves each phase transition.** The pipeline never auto-advances.
3. **Feedback to KB.** Any phase can trigger targeted discovery. The KB is always the return target.
4. **Feedback to Spec.** Plan, Detail, Implement, Review, and Test can trigger spec revision.
5. **Greenfield starts at Interview** with minimal KB populated from answers.
6. **Brownfield starts at Discover** with full KB populated from code.
7. **Each phase produces persistent artifacts.** Each artifact has a revision history.
8. **The KB outlives the project.** It's institutional memory for future work.
9. **Bugs take the short path.** Correct → Implement → Review → Test → Deploy. No re-specification.
10. **CRs take the full path.** Triage routes to Discover. New cycle, new spec, new plan.
11. **Track runs continuously.** It monitors production on schedule or on deployment.
12. **Detail feeds Implement.** Plan feeds Detail. Strategy flows down; tactics flow up when strategy is insufficient.

---

## 7. Case Studies

### VivaVoz — Greenfield Desktop Application

**Context:** MVVM desktop app (Avalonia/.NET) for voice recording and transcription. Built from scratch.

**How AID applied:**

- **Discovery:** Skipped (greenfield). Minimal KB populated during interview.
- **Interview:** Full requirements gathering. User personas, feature priority, platform constraints.
- **Specify:** PRD.md as initial spec. Detailed architecture decisions: MVVM pattern, SQLite storage, Whisper integration.
- **Plan:** High-level roadmap: MVP (core recording), v2 (transcription), v3 (export). Module identification, test scenarios.
- **Detail:** Decomposed into deliveries (2a: core recording, 2b: transcription, 2c: file management, 2d: import/export). Each with task specs including C# interface contracts.
- **Implement:** Agent-per-task execution. Parallel implementation of independent features.
- **Review:** 1,184 tests (unit + E2E). Code review with grading system.
- **Test:** Staging validation of each delivery increment.
- **Deploy:** Incremental deliveries. Each delivery merged independently.

**What worked:** The two-level planning (Plan → Detail) meant strategic decisions were separated from tactical decomposition. The plan defined "what goes in MVP" while detail defined "how to build each piece."

### Case Study 1 — Brownfield Enterprise Java

**Context:** 21GB enterprise Java codebase (Maven/Tycho, OSGi bundles). Client needed a developer to understand and extend the search engine.

**How AID applied:**

- **Discovery:** Full codebase analysis. Module listing across hundreds of packages. Architecture report covering 15 sections.
- **Interview:** Targeted — client explained business context, search requirements. Short interview because Discovery pre-filled all technical context.
- **Specify:** Spec grounded in the KB. Referenced actual package names, existing interfaces, OSGi service bindings.

**Key insight:** Without Discovery, an agent dropped into this codebase would have hallucinated. The KB gave agents the context they needed to work within the existing architecture rather than against it.

### Zac Pipeline — Operational Automation

**Context:** E-commerce advertising pipeline. Pull data from Meta/Google/Klaviyo, validate, process with specialist AI agents, grade output quality.

**How AID applied:**

- **Interview:** One question at a time. "What are your brands?" → "What platforms?" → "What does a good report look like?" → "What data don't you agree with?" That last question discovered a timezone bug.
- **Specify:** Pipeline spec with data flow, agent roles, grading criteria.
- **Implement:** Multi-agent orchestration: 4 specialist agents + orchestrator + executive summary generator.
- **Test:** Domain-specific quality gate (Grade A) checking: source match (1% tolerance), traceability, cross-agent consistency.
- **Track:** Monitors quality gate results across brands. When a report fails, Triage determines if it's a data processing bug (short path) or a source format change (full cycle).

---

## 8. Comparison with SDD

### What is SDD?

Spec-Driven Development (SDD) is the practice of using specifications as the primary development artifact, with AI agents implementing code from specs. Key tools: GitHub Spec Kit, AWS Kiro, Tessl Framework.

### Where We Overlap

Both AID and SDD:
- Use specifications as the central development artifact.
- Employ AI agents for code implementation.
- Rely on tests as contracts between spec and code.
- Require human review of agent output.
- Use markdown as the specification format.

### Where We Diverge

| Dimension | SDD | AID |
|-----------|-----|-----|
| **Starting point** | A spec | Understanding (Discovery) |
| **Brownfield support** | Gap acknowledged | First-class Discovery phase with 13-document KB |
| **Spec philosophy** | Spec is source of truth | Spec is hypothesis — revised by formal protocol |
| **Requirements** | Assumed to exist | Gathered through adaptive interview |
| **Planning depth** | Single spec | Two-level: Plan (strategy) → Detail (tactics) |
| **Feedback loops** | Rebuild spec from scratch | Eleven formal loops (8 dev + 3 post-production) |
| **Testing** | Not addressed as separate phase | Dedicated staging/E2E phase between review and deploy |
| **Quality gates** | Generic conformance tests | Domain-specific grading (Grade A system) |
| **Agent model** | One agent per spec | Multi-agent orchestration with specialists |
| **Delivery model** | Spec → code → done | Spec → plan → detail → implement → review → test → deploy |
| **Memory** | Stateless | Knowledge Base persists across sessions |
| **Post-delivery** | Not addressed | Track → Triage → Correct/Discover |
| **Scope** | Code generation | Full lifecycle: discovery through production maintenance |
| **Human role** | Spec writer, reviewer | Co-pilot across all phases |

### The Core Argument

SDD says: "Write better specs, get better code."

We say: "Understand the system first. Then write specs grounded in that understanding. Then plan the roadmap. Then detail the execution. Then build with quality gates. Then review against the spec. Then test in staging. Then ship. And when any of that reveals you were wrong — revise formally, don't hack around it."

SDD is not wrong. It's incomplete. AID is SDD + Discovery + Feedback Loops + Two-Level Planning + Staging Validation + Institutional Memory + Production Lifecycle.

---

## 9. Adoption Guide

### Starting with an Existing Project (Brownfield)

1. Run `aid-discover` on the codebase. This produces your Knowledge Base.
2. Review the KB. Fill gaps with human knowledge.
3. For the next feature request, run `aid-interview` with the stakeholder.
4. Run `aid-specify` with REQUIREMENTS.md + KB as input.
5. Run `aid-plan` to define the roadmap.
6. Run `aid-detail` to decompose into tasks.
7. Run `aid-implement` for each task.
8. Run `aid-review` after each task.
9. Run `aid-test` to validate in staging.
10. Run `aid-deploy` to package and ship.

### Starting a New Project (Greenfield)

1. Run `aid-interview` with the stakeholder. This is your starting point.
2. A minimal KB is populated from interview answers.
3. Run `aid-specify` with REQUIREMENTS.md + minimal KB.
4. Continue with Plan → Detail → Implement → Review → Test → Deploy.
5. The KB grows organically as the codebase develops.

### Adopting Incrementally

You don't need to use all twelve phases from day one:

- **Start with Detail + Implement.** If you already have specs, just formalize your task decomposition and agent execution.
- **Add Review.** Introduce the grading system and spec-anchored review.
- **Add Test.** Add staging validation between review and deploy.
- **Add Plan.** Separate strategy from tactics with two-level planning.
- **Add Discover.** For the next brownfield project, run Discovery first.
- **Add Interview.** For the next client project, use the adaptive interview.
- **Add Track + Triage.** Once you're shipping, add production monitoring and issue classification.
- **Add Correct.** Close the bug loop — root cause analysis feeding back to implementation.
- **Go full pipeline.** Once each phase is familiar, run them sequentially with feedback loops.

### Anti-Patterns

- **Skipping Discovery on brownfield.** Agents will hallucinate about your architecture.
- **Treating the spec as sacred.** It's a hypothesis. Revise it when implementation proves it wrong.
- **Ignoring impediments.** If an agent reports an impediment, stop and decide. Don't let it work around the problem.
- **Skipping Review.** "The tests pass" is not enough. Spec-anchored review catches issues that tests can't.
- **Skipping Test.** Review catches what code looks like. Test catches what code does. Both are necessary.
- **Not maintaining the KB.** A stale KB is worse than no KB. Every phase should update it when new knowledge is acquired.
- **Auto-advancing between phases.** The human approves every transition. That's the checkpoint that keeps the methodology safe.

---

*AID V3 — March 2026*
*Built from practice, not theory. Every phase, every template, every feedback loop was born from real projects.*