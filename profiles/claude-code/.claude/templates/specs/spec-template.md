# {Feature Title}

## Change Log

| Date | Change | Source |
|------|--------|--------|
| {date} | Feature created from REQUIREMENTS.md | /aid-interview |

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
Reference `.aid/knowledge/data-model.md` for existing schema and conventions.}

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
