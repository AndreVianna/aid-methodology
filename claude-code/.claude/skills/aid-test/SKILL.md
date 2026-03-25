---
name: aid-test
description: >
  Staging validation — E2E, integration, and manual testing. The gate between
  review and deploy. Use when code has passed review (grade A- or above) and
  needs staging validation.
allowed-tools: Read, Glob, Grep, Bash
context: fork
agent: critic
---

# Staging Validation & Testing

Deploy to staging, run tests, validate user stories, produce TEST-REPORT.md.

## Core Principle

Review catches what code looks like. Test catches what code does. Both gates are necessary.

## Inputs

- Feature branch (reviewed, grade A- or above)
- `.aid/{work}/DETAIL.md` — user stories, delivery breakdown, and acceptance criteria
- `.aid/{work}/PLAN.md` — deliverables and test scenarios
- Feature SPECs: `.aid/{work}/features/*/SPEC.md` — expected behavior and NFRs
- `.aid/knowledge/`: test-landscape.md, infrastructure.md

## Prerequisites

- [ ] All tasks passed review (A- or above)
- [ ] Staging environment available
- [ ] Test data prepared
- [ ] No open IMPEDIMENTs blocking this delivery

If any fail → do not proceed.

## Process

### 1. Deploy to Staging
Deploy feature branch. Verify: app starts, health checks pass, migrations applied, external services connected/mocked.

### 2. Run Automated Tests
Full battery in staging: unit (regression), integration, E2E. Record per category: total, passed, failed, skipped, execution time, failure details.

### 3. Validate User Stories
Per acceptance criterion from delivery's user stories: verify in staging. Mark passed/failed. Document method (automated or manual).

### 4. Non-Functional Validation
Performance (latency under load), concurrency, data integrity, error handling, edge cases — against feature SPEC targets.

### 5. Manual Testing (if applicable)
Visual/UI review, workflow coherence, accessibility, cross-platform. Document observations.

### 6. Produce TEST-REPORT.md
Verdict: **PASS** (all green, no critical issues) | **PASS WITH NOTES** (critical pass, minor issues noted) | **FAIL** (critical/high issues, deploy blocked).

## Feedback Loops

- **→ Implement:** Test failure from implementation bug → Developer fixes → quick review → re-test
- **→ Review:** Test reveals review miss → update review checklist → fix → re-review → re-test
- **→ Specify:** Spec gap in staging → GAP.md → Architect revises → implement → review → test

## Output

`TEST-REPORT.md` with: staging deployment status, automated test results per category, user story validation per criterion, NFR results, manual test observations, verdict.

## Quality Checklist

- [ ] Staging deployment successful
- [ ] Full automated suite ran (unit + integration + E2E)
- [ ] Every acceptance criterion validated
- [ ] NFRs tested
- [ ] Manual testing completed (if applicable)
- [ ] All failures documented with reproduction steps
- [ ] TEST-REPORT.md produced with clear verdict
