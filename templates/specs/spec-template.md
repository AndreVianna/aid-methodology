# {Project Name} — Specification

> **Version:** 1.0
> **Date:** {date}
> **Source:** aid-specify (Phase 3)
> **Input:** REQUIREMENTS.md v{n} + aid-workspace/knowledge/ (KB)

> **Note:** This spec is grounded in the Knowledge Base. Every architectural decision references existing code patterns — it doesn't invent new ones. Agents implementing from this spec should read the referenced KB documents before writing a single line of code.

---

## Vision

{One paragraph. What this is, why it exists, and what problem it solves. Written for a developer who knows nothing about this project — they should understand the purpose after reading this paragraph.}

---

## Constraints

> Hard constraints that every implementation decision must respect.

**Stack:**
- Language/Runtime: {from KB technology-stack.md — don't change unless REQUIREMENTS.md explicitly demands it}
- Framework: {existing framework — extend it, don't add a new one without justification}
- Database: {existing DB — use existing ORM and migration pattern}

**Platform:**
- Target environments: {Development / Staging / Production}
- OS compatibility: {if relevant}
- Browser support: {if web — from REQUIREMENTS.md}

**Performance:**
- Response time: {P95 target in ms for user-facing operations}
- Throughput: {requests/sec or events/sec if relevant}
- Data volume: {expected storage growth}

**Security:**
- Authentication: {required or not — from KB security-model.md}
- Authorization: {roles required — reference KB security-model.md for existing role model}
- Data classification: {PII involved? compliance requirements?}

**Non-negotiable:**
- {Any constraint from REQUIREMENTS.md that must be respected regardless of implementation preference}

---

## Architecture

> How this fits into the existing system. Not what architecture should be used in general — what architecture IS used here, and how this feature extends it.

**Pattern:**
{Reference KB architecture.md — "Following the {pattern} established in `aid-workspace/knowledge/architecture.md`, this feature..."}

**New components:**
{What new modules, services, or classes this feature adds. Be specific about where they live in the existing layer structure.}

**Modified components:**
{Existing code that changes. Reference module names from KB module-map.md.}

**Data:**
{New tables or schema changes. Reference KB data-model.md for conventions — migration naming, column conventions, relationship patterns.}

**External integrations:**
{New external APIs or services. Reference KB integration-map.md if extending existing integration patterns.}

---

## Domain Model

> Key entities and their relationships. Use the vocabulary from KB domain-glossary.md — not generic terms.

### {Entity Name}

| Property | Type | Description |
|----------|------|-------------|
| `{field}` | `{type}` | {description using domain language} |

**Relationships:**
- {Entity A} 1:N {Entity B} — {description using domain terms}

**Business rules:**
- {rule that applies to this entity — in domain language, not implementation language}

---

## Feature Specifications

> Each feature from REQUIREMENTS.md gets a specification here. Include behavior, interfaces, and edge cases.

### Feature {n}: {Name}

**Priority:** {Must / Should / Could}

**Behavior:**
{Describe what happens from the user's perspective. Start with the happy path, then edge cases.}

**Interface:**
```csharp
// Language-specific interface definition
// Reference existing patterns from KB coding-standards.md
// Example (C#):
public interface I{Feature}Service
{
    Task<Result<{Output}>> {Method}({Input} input, CancellationToken ct = default);
}
```

**Acceptance criteria:**
- [ ] {Concrete, testable criterion}
- [ ] {Criterion for edge case}
- [ ] {Criterion for error case}

**Error handling:**
| Condition | Response | Notes |
|-----------|----------|-------|
| {input is null} | {throw ArgumentNullException / return Result.Failure} | |
| {external service unavailable} | {return cached / fail fast / retry} | |

---

## Non-Functional Requirements

> Derived from REQUIREMENTS.md constraints + KB infrastructure.md capabilities.

**Observability:**
- Logging: {what events to log, at what level — follow pattern in KB coding-standards.md}
- Metrics: {what to measure, if applicable}
- Error tracking: {Sentry / Application Insights / whatever KB infrastructure.md documents}

**Testing:**
- Unit test coverage target: {%}
- Integration tests: {which components need integration testing}
- E2E tests: {which user flows need E2E coverage}

**Accessibility:** {if web — WCAG level, screen reader requirements}

**i18n:** {if applicable — localization requirements}

---

## Out of Scope

> From REQUIREMENTS.md. Be explicit — prevents scope creep during implementation.

- {feature explicitly excluded}
- {future version item}
- {won't-fix item}

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-specify | Initial specification |
