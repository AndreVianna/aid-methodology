---
name: aid-correct
description: >
  Bug mapping and patch planning. Root cause analysis, impact mapping, patch scope
  definition. Produces CORRECTION.md and hands off to aid-implement. Use when
  aid-triage classifies a finding as BUG.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: developer
---

# Bug Mapping & Patch Planning

Map the fix. Root cause → impact → patch scope → hand off to Implement.

## Core Principle

Fix the root cause, not the symptom. A 500 on valid input isn't fixed by catching the exception — it's fixed by handling the null field that should have been validated.

## Inputs

- `TRIAGE.md` — classified as BUG, with evidence
- `knowledge/`: architecture.md, module-map.md, coding-standards.md, test-landscape.md
- `SPEC.md` — expected behavior
- `TASK-{id}.md` — acceptance criteria for affected feature (if traceable)
- Source code access

## Process

### 1. Root Cause Analysis
1. Reproduce the path from TRIAGE evidence (endpoint → module → function)
2. Identify the fault (missing validation? wrong assumption? race condition?)
3. Understand why (spec ambiguous? edge case missed? KB assumption wrong?)

Root cause = one sentence: "The `PaymentService.Process()` method doesn't validate null `currency` field, which spec says must default to USD."

### 2. Impact Mapping
1. Direct impact: broken functionality, affected users
2. Module consumers: check module-map.md — who else calls this code?
3. Data integrity: corrupted data? need migration?
4. Related code: same pattern elsewhere? same bug might exist in other modules

### 3. Patch Scope
Table: File | Change | Reason. Rules:
- Fix the bug, don't refactor the neighborhood
- If fix touches shared code, check all consumers
- If same pattern exists elsewhere, document — but fix one at a time

### 4. Test Requirements
1. **Fix verification:** Test that fails now, passes after fix
2. **Regression:** Tests proving existing functionality still works
3. **Coverage gap:** Tests that should have existed to catch this

### 5. Generate CORRECTION.md
Contains everything aid-implement needs: root cause, files to touch, test requirements, acceptance criteria.

### 6. Hand Off
CORRECTION.md → aid-implement → aid-review → aid-test → aid-deploy (5 phases, skips discover/interview/specify/plan/detail)

## What Correct Is NOT

- Not re-specification (spec was right, code was wrong)
- Not re-planning (bug fix = single task, not delivery)
- Not a workaround (catching exception + logging ≠ fix)
- Not scope creep ("while we're here, let's refactor..." — no)

## Output

`CORRECTION.md` with: root cause, impact assessment, patch scope (files + changes), test requirements, acceptance criteria.

## Quality Checklist

- [ ] Root cause identified (one sentence, specific)
- [ ] Impact mapped — consumers checked, data integrity assessed
- [ ] Patch scope minimal
- [ ] Fix verification test defined
- [ ] Regression tests defined
- [ ] Coverage gap identified
- [ ] No scope creep
