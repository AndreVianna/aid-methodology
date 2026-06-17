> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-developer

**Core Agent — present in every AID pipeline**

The Developer is the only agent that modifies production source code. It implements tasks, fixes bugs, and verifies builds — across all implementation task types including data migrations, infrastructure configuration, and code fixes.

## What It Does

The Developer reads a TASK file, understands its acceptance criteria, writes code (or configuration, migrations, or infrastructure), and verifies the build passes. It is the sole authority on production source mutation; every other agent that produces "implementation" output goes through the Developer.

The Developer absorbed the Data Engineer (MIGRATE-typed tasks) and DevOps-as-executor (CONFIGURE-typed tasks). Both were strict subsets of the same implement-and-verify responsibility; the task type is a dispatch parameter, not a separate agent. The security and performance *fix* sides also route here: security-pattern analysis goes to the Researcher, but writing the fix is implementation work.

## When It's Invoked

| Task Type | Purpose |
|-----------|---------|
| **IMPLEMENT** | Core feature implementation |
| **TEST** | Writing and running automated tests |
| **REFACTOR** | Code restructuring without behavior change |
| **FIX** | Bug fixes guided by root cause analysis |
| **MIGRATE** | Database schema changes, data migrations, ETL pipelines |
| **CONFIGURE** | CI/CD pipelines, Dockerfiles, IaC, deployment strategies |

Invoked by **aid-execute** and **aid-discover** (for KB FIX cycles that require regenerating generated files).

## What It Produces

- **Code changes** satisfying TASK acceptance criteria
- **Build verification output** (pass/fail with evidence)
- **IMPEDIMENT.md** when spec contradicts reality: `type`, `evidence`, `blocked-task`, `proposed-resolution`

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-architect** | Architect designs the solution. Developer implements it. |
| **aid-reviewer** | Reviewer evaluates correctness. Developer produces the code to evaluate. |
| **aid-operator** | Developer verifies per-task builds. Operator runs release-gated final verification before shipping. |
| **aid-researcher** | Researcher reads and analyzes. Developer writes and mutates. |

## Tools

- **Read, Glob, Grep** — reading task files, specs, KB, existing code
- **Write, Edit** — the only agent with production-code write access
- **Bash** — running builds, tests, linters, generators

## Tier

**Medium tier** — implementation follows a specification; deep reasoning is the Architect's job. The Developer's skill is in faithful, complete, convention-respecting execution of a defined task.

## Examples

- *"Implement task-003."* → Developer reads task, writes code, verifies build passes
- *"FIX: task-007 reports broken auth middleware."* → Developer reads root cause analysis, writes the fix, verifies
- *"MIGRATE: add `user_preferences` table."* → Developer writes migration, verifies against test DB
- *"CONFIGURE: add GitHub Actions workflow for CI."* → Developer writes the workflow file, verifies syntax and expected triggers

## Key Behaviors

- **Spec-first.** Every implementation decision traces back to the TASK, SPEC, or KB convention — no guessing.
- **Build verification non-negotiable.** Every task ends with a passing build. No "it should work."
- **Impediment over workaround.** When spec contradicts reality, IMPEDIMENT.md — never a silent workaround.
- **One task per instance.** Parallelism is the Orchestrator's job; the Developer focuses on one task.

## Escalation

- **Spec contradicts reality** → creates IMPEDIMENT.md with evidence and proposed resolution
- **Missing dependency or access** → reports to Orchestrator
- **Task acceptance criteria untestable** → IMPEDIMENT.md, asks Architect to clarify
- **Build fails outside task scope** → reports to Orchestrator
