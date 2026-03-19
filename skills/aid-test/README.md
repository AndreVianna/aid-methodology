
# Staging Validation & Testing

Deploy to staging, run E2E and integration tests, support manual testing, produce TEST-REPORT.md. The gate between review (static analysis) and deploy (production ship).

## Core Principle

**Review catches what code looks like. Test catches what code does.** Review is static — it reads the diff against the spec. Test is dynamic — it runs the code in a staging environment and verifies it behaves correctly. A passing review with failing E2E tests means the code is well-structured but wrong. A passing test suite with a failing review means the code works but is unmaintainable. Both gates are necessary.

## Inputs

- Feature branch with reviewed code (grade A- or above from aid-review).
- `DELIVERY-{id}.md` — delivery scope and success criteria.
- `DETAIL.md` — user stories and acceptance criteria.
- `SPEC.md` — expected behavior and non-functional requirements.
- `knowledge/test-landscape.md` — test infrastructure and conventions.
- `knowledge/infrastructure.md` — staging environment details.

## Prerequisites

Before starting testing:

- [ ] All tasks in the delivery passed review with grade A- or above.
- [ ] Staging environment is available and configured.
- [ ] Test data/fixtures are prepared.
- [ ] No open IMPEDIMENT.md files blocking this delivery.

If any prerequisite fails, do not proceed. Resolve the blocking issue first.

## Process

### Step 1: Deploy to Staging

Deploy the feature branch to the staging environment:

```bash
# Example: deploy to staging
git checkout feature/DELIVERY-{id}
# Run staging deploy script (project-specific)
./deploy-staging.sh  # or docker-compose up, k8s apply, etc.
```

Verify the staging deployment:
- Application starts without errors.
- Health checks pass.
- Database migrations applied (if applicable).
- External service connections verified (or mocked).

### Step 2: Run Automated Test Suite

Run the full automated test battery in staging:

```bash
# Unit tests (regression check)
dotnet test --filter "Category!=E2E"  # or npm run test:unit

# Integration tests
dotnet test --filter "Category=Integration"  # or npm run test:integration

# E2E tests
dotnet test --filter "Category=E2E"  # or npm run test:e2e, npx playwright test
```

For each test category, record:
- Total tests run.
- Passed / Failed / Skipped.
- Execution time.
- Failure details (stack traces, screenshots for E2E).

### Step 3: Validate User Stories

For each user story in the delivery, verify acceptance criteria in the staging environment:

```markdown
### US-01: Record audio from microphone
- [x] AC1: Click "Record" starts recording with visual indicator
- [x] AC2: Click "Stop" saves recording to library
- [ ] AC3: Recording >60min auto-saves and continues ← FAILS (truncates at 58min)
```

This can be automated (E2E tests mapped to user stories) or manual (human walkthrough in staging). Document which method was used for each criterion.

### Step 4: Non-Functional Validation

Test non-functional requirements from SPEC.md:

- **Performance:** Response times under load. Does it meet the spec's latency targets?
- **Concurrency:** Multiple simultaneous users/operations.
- **Data integrity:** Create, update, delete cycles preserve data correctness.
- **Error handling:** Invalid inputs produce correct error responses, not crashes.
- **Edge cases:** Boundary conditions, empty states, maximum values.

### Step 5: Manual Testing (if applicable)

Some things can't be automated:
- Visual/UI review — does it look right?
- Workflow coherence — does the user flow make sense?
- Accessibility — screen reader behavior, keyboard navigation.
- Cross-browser/platform — if the spec requires multiple platforms.

Document manual test results with the tester's observations.

### Step 6: Produce TEST-REPORT.md

Generate the test report using the [template](references/test-report-template.md).

**Verdict determination:**
- **PASS** — All automated tests pass. All user story acceptance criteria verified. No critical or high-severity issues.
- **PASS WITH NOTES** — All critical tests pass. Minor issues documented but not blocking. Deploy can proceed.
- **FAIL** — Critical or high-severity issues found. Deploy blocked until resolved.

## Output: TEST-REPORT.md

See [Test Report Template](references/test-report-template.md) for the full template.

## Feedback Loops

### → Implement (test failure → fix)

**Trigger:** Tests fail due to implementation bugs.

**Protocol:**
1. Document failures in TEST-REPORT.md with reproduction steps.
2. Route back to aid-implement for targeted fix.
3. Fix → aid-review (quick review of the fix) → aid-test (re-run failed tests + regression).

### → Review (test reveals review miss)

**Trigger:** Tests pass but expose a pattern that review should have caught (e.g., hardcoded config values that break in staging but not local).

**Protocol:**
1. Document in TEST-REPORT.md.
2. Update aid-review checklist with the new pattern to check for.
3. Fix → re-review → re-test.

### → Specify (spec gap in staging)

**Trigger:** Staging reveals behavior not covered by the spec.

**Protocol:**
1. Generate GAP.md with `ambiguity`.
2. Trigger aid-specify revision.
3. Updated spec → update tasks → implement → review → test again.

## Quality Checklist

- [ ] Staging deployment successful and verified.
- [ ] Full automated test suite ran (unit + integration + E2E).
- [ ] Every user story acceptance criterion validated.
- [ ] Non-functional requirements tested.
- [ ] Manual testing completed (if applicable).
- [ ] All failures documented with reproduction steps.
- [ ] TEST-REPORT.md produced with clear verdict.
- [ ] Verdict is PASS before proceeding to aid-deploy.

## See Also

- [Test Report Template](references/test-report-template.md) — Full TEST-REPORT.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
