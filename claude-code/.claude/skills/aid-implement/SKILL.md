---
name: aid-implement
description: >
  Execute a planned task by spawning a coding agent with full KB context.
  Mandatory build verification. Use when a TASK-{id}.md is ready for
  implementation or a CORRECTION.md needs coding.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: developer
# Note: For complex implementations, consider using opus instead of sonnet.
---

# Execute Task with Agent

Read TASK spec, load context, spawn coding agent, verify output.

## Core Principle

Agents don't improvise. They receive task spec + project spec + KB context. When reality contradicts instructions, they report an impediment — never silently work around it.

## Inputs

- `TASK-{id}.md` — primary prompt
- `SPEC.md` — architectural constraints
- `knowledge/INDEX.md` — always included. The agent's map of the full KB for on-demand self-service.
- `knowledge/`: Always coding-standards.md + architecture.md. Add data-model.md (DB work), api-contracts.md (API work), integration-map.md (integrations), test-landscape.md (test-heavy).

## Process

### 1. Prepare Context
Assemble: TASK content + relevant SPEC sections + KB INDEX.md + 2-4 most relevant KB docs. The INDEX lets the agent read additional KB documents on demand.

### 2. Spawn Agent
Agent prompt includes: task spec, project spec sections, coding standards, architecture context, and rules:
- Follow coding standards exactly
- Match interface contracts
- Write tests as specified
- If contradiction found → STOP and report, don't work around it
- Run build and tests before reporting done

### 3. Verify Output
1. **Build:** Zero errors, zero warnings
2. **Tests:** All pass (new + existing)
3. **Scope:** Files changed match "Files to Touch" guidance

Failures: build errors → agent fixes; test failures → distinguish new vs regression; scope creep → evaluate necessity.

### 4. Handle Impediments
Agent generates `IMPEDIMENT.md` with: type (wrong-assumption | missing-dependency | architecture-conflict | kb-gap), description, options with trade-offs, recommendation.
- kb-gap → trigger targeted aid-discover
- Resolvable locally → resolve, document
- Requires plan/spec change → pause, escalate to human

## Multi-Agent Parallel Execution

Prerequisites: no shared dependencies, different files/modules, separate feature branches.

Protocol: branch per task → spawn agents → yield and wait → verify each independently → merge in dependency order → full test suite after merge.

Do NOT parallelize when: shared DB migrations, same interfaces modified, output/input dependency between tasks.

## Output

- Code changes on feature branch
- Tests added per task spec
- Build: green. Tests: green.
- IMPEDIMENT.md if assumptions violated
- Task status updated

## Quality Checklist

- [ ] Agent received TASK + SPEC + INDEX.md + relevant KB docs
- [ ] Build passes (zero errors, zero warnings)
- [ ] All tests pass (new and existing)
- [ ] Files changed match expected scope
- [ ] No silent workarounds — impediments documented
- [ ] Commit messages reference TASK-{id}
