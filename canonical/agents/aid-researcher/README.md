> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-researcher

**Core Agent — present in every AID pipeline**

The Researcher reads existing systems and produces structured knowledge — KB documents, analysis reports, and investigation findings. It is the pipeline's institutional memory builder.

## What It Does

The Researcher ingests code, documentation, logs, configuration, and APIs — then produces structured output: KB documents for `.aid/knowledge/`, analysis reports for specific questions, and telemetry interpretations for the monitor phase. It does not make decisions; it documents reality so other agents can reason from a shared factual base.

The Researcher consolidates the five former discovery cataloguing agents (one per KB doc-set scope: scout, analyst, architecture, integrator, quality), the security analysis role, and the performance analysis role. All five discovery agents performed "the generalist Researcher scoped to specific KB docs + aid-discover only" — the KB doc-set is a dispatch parameter, not a reason for separate agents. Security and performance *analysis* are read→KB work; the *fix* side routes to the Developer.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Discover** | Populates the full KB doc-set: structure, architecture, tech stack, modules, conventions, schemas, integrations, contracts, glossary, test landscape, tech debt, infrastructure, security posture, performance baseline |
| **Execute** | Executes RESEARCH-typed tasks: investigates a specific subsystem or question |
| **Monitor** | OBSERVE and CLASSIFY states: interprets telemetry, classifies anomalies |

The dispatching skill passes a `doc-set` parameter specifying which KB docs to populate; the Researcher scopes its analysis accordingly.

## What It Produces

- **KB documents** in `.aid/knowledge/` — all doc types per the declared doc-set
- **Analysis reports** — structured markdown with `##` sections, evidence blocks, confidence tags
- **Telemetry interpretations** — OBSERVE/CLASSIFY findings for the monitor pipeline

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-architect** | Architect proposes *new design*. Researcher catalogues *existing state*. |
| **aid-tech-writer** | Tech Writer writes *user-facing docs* (READMEs, API docs). Researcher writes *KB/analysis docs* (internal pipeline knowledge). |
| **aid-reviewer** | Reviewer *judges quality* against criteria. Researcher *documents reality* objectively. |
| **aid-developer** | Developer *fixes* vulnerabilities and performance issues. Researcher *analyzes* and documents them. |

## Tools

- **Read, Glob, Grep** — reading code, docs, configs, logs
- **Bash** — read-only exploration (`find`, `tree`, `wc`, `rg`, `cat`, `head`, `tail`)
- **Write** — writing KB documents and analysis reports to `.aid/knowledge/`
- `permissionMode: bypassPermissions` — required for parallel dispatch in the aid-discover pool
- `background: true` — supports parallel pool dispatch in aid-discover GENERATE phase

## Tier

**Large tier** — deep code + telemetry analysis requires large-context reasoning. The Researcher must read many files, reconcile conflicting evidence, and produce KB documents that downstream agents depend on for months. Shallow analysis compounds into wrong specifications.

## Examples

- *"Populate module-map.md, coding-standards.md, and schemas.md."* → Researcher analyzes the codebase, produces three KB docs
- *"RESEARCH task: investigate the auth middleware's session handling."* → Researcher produces a targeted analysis report
- *"OBSERVE: classify the anomaly in the last monitor cycle."* → Researcher interprets telemetry and classifies the signal
- *"Analyze security posture for the new OAuth integration."* → Researcher documents threat surfaces, auth design patterns, dependency risk

## Key Behaviors

- **Evidence over assumption.** Every claim cites a file path, line number, or log entry.
- **Reality, not ideals.** Documents what the code *does*, not what it *should* do.
- **Dispatch-parameter scoped.** When given a doc-set, analysis covers exactly those docs — no scope creep into unrelated KB areas.
- **Confidence tagging.** Claims are tagged CONFIRMED / LIKELY / UNCERTAIN so downstream agents know how much weight to place on each finding.

## Escalation

- **Cannot access a resource** → reports to Orchestrator
- **Evidence contradicts itself** → documents both sides, flags for human decision
- **Knowledge gap blocks another phase** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section
