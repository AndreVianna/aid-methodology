---
name: aid-deploy
description: >
  Final verification, PR creation, delivery summary, and KB updates. The last
  development phase before production. Use when all tasks are complete, reviewed
  (A-+), and tested (PASS).
allowed-tools: Read, Glob, Grep, Bash, Write
context: fork
agent: operator
---

# Package & Ship

Final verification, PR, delivery summary, documentation updates.

## Inputs

- Feature branch with completed, reviewed, tested tasks
- `aid-workspace/{task}/DETAIL.md` — scope, user stories, delivery breakdown
- `aid-workspace/{task}/PLAN.md` — deliverables and success criteria
- REVIEW.md files, TEST-REPORT.md
- Feature SPECs: `aid-workspace/{task}/features/*/SPEC.md`
- `aid-workspace/knowledge/`

## Prerequisites

- [ ] All tasks status "Complete"
- [ ] All reviews grade A- or above
- [ ] TEST-REPORT.md verdict PASS
- [ ] No open IMPEDIMENTs or GAPs

## Process

### 1. Final Verification
Full build (not incremental), full test suite, lint/format. Zero failures, zero errors, zero warnings. If fails → fix → re-verify (loop to review if non-trivial).

### 2. Delivery Summary
Generate: scope paragraph, tasks table (description, complexity, review grade), change metrics (files/lines changed, tests added), spec revisions during delivery, KB updates during delivery, known deferred issues.

### 3. PR Creation
Structured description: what (scope), tasks (with grades), verification results (build/tests/lint/staging), review notes, references (DELIVERY, SPEC, TEST-REPORT).

### 4. Documentation Updates
Check if implementation revealed KB updates needed:
- New conventions → coding-standards.md
- Architecture changes → architecture.md
- New integrations → integration-map.md
- Tech debt created/resolved → tech-debt.md
- Data model changes → data-model.md
Add revision entries to aid-workspace/knowledge/README.md.

### 5. Artifact Status Updates
- DETAIL.md delivery entries → Status: Complete, completion date, final test count
- `aid-workspace/{task}/tasks/TASK-{id}.md` files → Status: Complete
- Feature SPEC change logs (if revisions occurred)
- aid-workspace/knowledge/README.md (if KB docs updated)

## Post-Deploy

1. Verify CI/CD on main branch
2. Tag/release if milestone
3. Notify stakeholders
4. Plan next delivery (if more remain)
5. Trigger aid-track for production monitoring

## Output

- PR ready for merge
- Delivery summary document
- Updated DELIVERY and TASK statuses
- Updated KB documents (if applicable)

## Quality Checklist

- [ ] All tasks complete and reviewed (A-+)
- [ ] Testing passed
- [ ] Full build passes (not incremental)
- [ ] Full test suite passes
- [ ] Lint/format clean
- [ ] PR created with structured description
- [ ] Delivery summary generated
- [ ] Statuses updated
- [ ] KB updated with discoveries
- [ ] No open GAPs or IMPEDIMENTs
