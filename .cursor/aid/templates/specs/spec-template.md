# {Feature Title}

> **Ticket:** {connector-stem}:{external-id}
<!-- OPTIONAL `ticket_ref` -- e.g. `jira:PROJ-123`; links this feature to an external tracker
     item. Omit the line above entirely when this feature has no linked tracker item
     (readers/dashboard ignore its absence). Nearest-ancestor resolution + MCP-first consumption
     contract: `.cursor/aid/templates/connectors/consumption-protocol.md`. This is a SPEC body
     line, not frontmatter -- SPEC.md carries no frontmatter block. `ticket_ref` is a
     lifecycle-unit field only -- the connector descriptor schema is unchanged. Coordinate with
     the in-flight `work-003-state-schema` frontmatter conventions. -->

## Change Log

| Date | Change | Source |
|------|--------|--------|
| {date} | Feature created from REQUIREMENTS.md | /aid-describe |

## Source

- REQUIREMENTS.md §5.{n} — {requirement reference}
- REQUIREMENTS.md §9 — {acceptance criteria reference}

## Description

{Description from stakeholder perspective — extracted and synthesized from REQUIREMENTS.md.
Write in plain language. This is what the feature does, not how.}

## User Stories

- As a {user}, I want to {action} so that {benefit}

## Priority

{Must / Should / Could}

## Acceptance Criteria

- [ ] Given {precondition}, when {action}, then {expected result}

---

## Technical Specification

> Added by `/aid-specify`. Do not fill during interview.
> The sections below are determined by Specify based on KB, codebase, and developer discussion.

### Data Model

{Tables, columns, types, constraints, FKs, indices — or "no schema changes".
Reference `.aid/knowledge/schemas.md` for existing schema and conventions.}

### Feature Flow

{Technical flowchart: request → service → repo → response.
Reference `.aid/knowledge/architecture.md` for existing patterns.}

### Layers & Components

{What goes in each layer, dependencies, DI registrations.
Reference `.aid/knowledge/module-map.md` and `coding-standards.md`.}

<!-- Conditional sections below — only include if activated by Specify -->

<!--
### API Contracts
### UI Specs
### Events & Messaging
### DDD Analysis
### BDD Scenarios
### CQRS Specs
### State Machines
### Security Specs
### Migration Plan
### Cache Strategy
### External Integrations
### Batch/Jobs
### Mobile Specs
### Search/Indexing
### AI Enhancements
### Telemetry & Tracking
### Recovery Management
### Cloud Support
### Hardware Requirements
-->
