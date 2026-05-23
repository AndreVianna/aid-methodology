# Test Landscape

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Test Framework Inventory

| Framework | Version | Type | Location |
|-----------|---------|------|----------|
| {e.g., xUnit} | {2.x} | {Unit} | {path/to/tests/} |
| {e.g., Playwright} | {1.x} | {E2E} | {path/to/e2e/} |
| {e.g., Testcontainers} | {3.x} | {Integration (DB)} | {path/to/integration/} |

**Test runner command:**
```bash
# Run all tests
{command}

# Run unit tests only
{command}

# Run E2E tests
{command}

# With coverage
{command}
```

---

## Coverage Summary

| Module | Unit Tests | Integration Tests | E2E | Overall |
|--------|-----------|------------------|-----|---------|
| {module} | {%} | {%} | {covered / not} | {%} |

**Total coverage:** {overall %}
**Coverage target:** {target % or "not defined"}
**Coverage enforcement:** {CI fails below X% / advisory only / not enforced}

---

## Test Types Present

| Type | Present | Volume | Notes |
|------|---------|--------|-------|
| Unit | {✅ / ❌} | {~n tests} | {fast / slow, any issues?} |
| Integration | {✅ / ❌} | {~n tests} | {requires Docker / requires DB / other} |
| E2E | {✅ / ❌} | {~n tests} | {Playwright / Cypress / manual / other} |
| Performance | {✅ / ❌} | {~n tests} | {k6 / JMeter / other} |
| Contract | {✅ / ❌} | {~n tests} | {Pact / other} |
| Snapshot | {✅ / ❌} | {~n tests} | {for UI / serialization} |

---

## CI/CD Pipeline

| Stage | Tool | Trigger | Duration (approx.) |
|-------|------|---------|---------------------|
| {Build} | {GitHub Actions / Azure DevOps / Jenkins} | {PR / push to main} | {~Xs} |
| {Unit Tests} | {same} | {PR / push} | {~Xs} |
| {Integration Tests} | {same} | {PR / merge} | {~Xs} |
| {E2E Tests} | {same} | {merge to main / deploy} | {~Xs} |
| {Deploy Staging} | {same} | {merge to main} | {~Xs} |
| {Deploy Production} | {same} | {manual approval} | {~Xs} |

**Pipeline config location:** {path/to/.github/workflows/ or azure-pipelines.yml}

---

## Test Data Strategy

| Approach | Used? | Notes |
|----------|-------|-------|
| Factories / builders | {Yes / No} | {e.g., `AutoFixture`, `factory_boy`, manual builders} |
| Fixtures / seeds | {Yes / No} | {location} |
| Testcontainers | {Yes / No} | {spins up real DB for integration tests} |
| Mocks | {Yes / No} | {framework: Moq, NSubstitute, Jest, etc.} |
| Shared test DB | {Yes / No} | {⚠️ can cause test pollution — isolation issues?} |

---

## Known Test Gaps

> Areas with insufficient test coverage — important for aid-execute to know what to add.

| Area | Gap | Risk | Recommendation |
|------|-----|------|----------------|
| {module/feature} | {e.g., No tests for error paths} | {High / Medium} | {add X tests} |
| {module/feature} | {e.g., E2E only covers happy path} | {Medium} | {add failure scenarios} |

---

## Test Anti-Patterns Observed

> Bad patterns to avoid when writing new tests.

- {e.g., "Tests that depend on execution order — some test methods rely on state set by previous tests"}
- {e.g., "Magic sleep() calls — tests using Thread.Sleep(2000) instead of proper waiting"}
- {e.g., "Shared mutable state — static fields used for test data causing race conditions in parallel runs"}

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial test landscape analysis |
