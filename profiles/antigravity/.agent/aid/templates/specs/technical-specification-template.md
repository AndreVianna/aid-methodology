# Technical Specification body

> **What this is.** The contents of the `#### Technical Specification` subsection that
> `/aid-specify` appends to a feature section in `REQUIREMENTS.md § 11`. It is a body,
> not a document: there is no separate specification file, and the heading levels below
> assume the section is already nested under `## 11. Features` -> `### Feature NNN`.
>
> The feature section's own skeleton -- title, Priority, Requirements, Criteria,
> Description, User Stories -- is defined by
> `.agent/aid/templates/requirements/requirements-template.md § 11`, which is where
> `/aid-define` creates it. This template covers only what `/aid-specify` adds, which is
> the part `/aid-define` leaves as a placeholder.

---

#### Technical Specification

> Added by `/aid-specify`. Do not fill during the interview.
> The sections below are determined by Specify from the KB, the codebase, and
> discussion with the developer.

##### Data Model

{Tables, columns, types, constraints, FKs, indices -- or "no schema changes".
Reference `.aid/knowledge/schemas.md` for the existing schema and its conventions.}

##### Feature Flow

{Technical flowchart: request -> service -> repo -> response.
Reference `.aid/knowledge/architecture.md` for existing patterns.}

##### Layers & Components

{What goes in each layer, dependencies, DI registrations.
Reference `.aid/knowledge/module-map.md` and `coding-standards.md`.}

<!-- Conditional sections below -- include one only when Specify activates it. An empty
     heading is worse than an absent one: it reads as an unanswered question rather than
     an inapplicable one. -->

<!--
##### API Contracts
##### UI Specs
##### Events & Messaging
##### DDD Analysis
##### BDD Scenarios
##### CQRS Specs
##### State Machines
##### Security Specs
##### Migration Plan
##### Cache Strategy
##### External Integrations
##### Batch/Jobs
##### Mobile Specs
##### Search/Indexing
##### AI Enhancements
##### Telemetry & Tracking
##### Recovery Management
##### Cloud Support
##### Hardware Requirements
-->
