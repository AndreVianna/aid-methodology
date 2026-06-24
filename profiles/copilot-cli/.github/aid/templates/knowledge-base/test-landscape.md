---
kb-category: primary
source: hand-authored
objective: Test frameworks, coverage areas, and gaps for {project}.
summary: Read this before writing or modifying tests to follow established patterns and avoid duplicating or breaking existing suites.
sources:
  - tests/                      # test suite directories
  - {path/to/test/config}       # e.g., jest.config.js, pytest.ini, .rspec
tags: [C6, testing, coverage, frameworks, gaps]
see_also: [technology-stack.md, coding-standards.md]
owner: developer
audience: [developer, architect]
intent: |
  Test frameworks in use, coverage areas, and gaps. Read this before writing or modifying tests to follow established patterns.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# Test Landscape

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

## Contents

- [Test Framework Inventory](#test-framework-inventory)
- [Coverage Summary](#coverage-summary)
- [Test Types Present](#test-types-present)
- [CI/CD Pipeline](#cicd-pipeline)
- [Test Data Strategy](#test-data-strategy)
- [Known Test Gaps](#known-test-gaps)
- [Test Anti-Patterns Observed](#test-anti-patterns-observed)
- [Change Log](#change-log)

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
| {module} | {✅ / ⚠️ / ❌} | {✅ / ⚠️ / ❌} | {covered / not} | {✅ / ⚠️ / ❌} |

**Coverage target:** {target % or "not defined"}
**Coverage enforcement:** {CI fails below X% / advisory only / not enforced}

---

## Test Types Present

| Type | Present | Notes |
|------|---------|-------|
| Unit | {✅ / ❌} | {fast / slow, any issues?} |
| Integration | {✅ / ❌} | {requires Docker / requires DB / other} |
| E2E | {✅ / ❌} | {Playwright / Cypress / manual / other} |
| Performance | {✅ / ❌} | {k6 / JMeter / other} |
| Contract | {✅ / ❌} | {Pact / other} |
| Snapshot | {✅ / ❌} | {for UI / serialization} |

---

## CI/CD Pipeline

| Stage | Tool | Trigger |
|-------|------|---------|
| {Build} | {GitHub Actions / Azure DevOps / Jenkins} | {PR / push to main} |
| {Unit Tests} | {same} | {PR / push} |
| {Integration Tests} | {same} | {PR / merge} |
| {E2E Tests} | {same} | {merge to main / deploy} |
| {Deploy Staging} | {same} | {merge to main} |
| {Deploy Production} | {same} | {manual approval} |

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

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial test landscape analysis |
