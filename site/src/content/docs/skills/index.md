---
title: 'All Skills'
description: 'Every AID skill, one card each, grouped by skill group and — inside Definition — by verb family.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
sidebar:
  hidden: true
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml -->

AID ships **112 skill directories** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), with the Definition group subdivided into **18 verb families** derived from the shortcut catalog. Each card below links to that skill’s detail page.

> **Note:** This page is the roster, and it files skills per FR-5’s Placement rules. `aid-triage` is **Support** here and **Definition** in the curated roster that [the methodology's skill inventory](/concepts/methodology/) publishes. Where they disagree about grouping, **this page is authoritative**. How the shortcut skills themselves work — the shared engine and its INTAKE → APPROVAL-HALT sequence — is at [Reference → Shortcut engine](/reference/skills/).

## Support

Skills for configuring AID, managing tickets and connectors, and talking to a peer AI session. Start here if you're not sure which skill to use.

- [`aid-triage`](/skills/aid-triage/) — Suggest which AID entry point fits the work you describe; suggests only and writes nothing.
- [`aid-config`](/skills/aid-config/) — View or change AID settings such as project name, type or minimum grade.
- [`aid-chat`](/skills/aid-chat/) — Talk to another AI coding session.
- [`aid-set-connector`](/skills/aid-set-connector/) — Add or change a connector to a tracker or tool.
- [`aid-unset-connector`](/skills/aid-unset-connector/) — Remove a connector and its stored secret.
- [`aid-read-ticket`](/skills/aid-read-ticket/) — Read one ticket from the issue tracker and show its fields.
- [`aid-create-ticket`](/skills/aid-create-ticket/) — File one new ticket in the issue tracker.
- [`aid-update-ticket`](/skills/aid-update-ticket/) — Change one part of a ticket: description, comment or status.

## Knowledge Base Maintenance

Skills for discovering, querying, summarising, mapping, and maintaining the project Knowledge Base.

- [`aid-discover`](/skills/aid-discover/) — Build the Knowledge Base from an existing codebase: architecture, conventions and patterns.
- [`aid-summarize`](/skills/aid-summarize/) — Build kb.html, a single-file visual tour of the Knowledge Base.
- [`aid-housekeep`](/skills/aid-housekeep/) — Re-sync a drifted Knowledge Base and summary and clear stale work artifacts.
- [`aid-update-kb`](/skills/aid-update-kb/) — Apply one targeted, human-confirmed change to the Knowledge Base, in its own worktree.
- [`aid-ask`](/skills/aid-ask/) — Answer a question about this project, with citations from the Knowledge Base, the code and any work in flight.

## Definition

The full AID pipeline plus every shortcut skill, grouped by verb family.

**The full path** — the five phases, in order:

- [`aid-describe`](/skills/aid-describe/) — Gather requirements through an adaptive interview and write REQUIREMENTS.md.
- [`aid-define`](/skills/aid-define/) — Split approved requirements into features.
- [`aid-specify`](/skills/aid-specify/) — Write one feature's technical specification with you.
- [`aid-plan`](/skills/aid-plan/) — Group specified features into deliveries.
- [`aid-detail`](/skills/aid-detail/) — Break a delivery into small, typed, dependency-ordered tasks.

### `fix`

- [`aid-fix`](/skills/aid-fix/) — Diagnose and correct a defect or regression.

### `create`

- [`aid-create`](/skills/aid-create/) — Create a new internal module, interface or type.
- [`aid-create-api`](/skills/aid-create-api/) — Create an API endpoint or middleware.
- [`aid-create-ui`](/skills/aid-create-ui/) — Create a UI component or page.
- [`aid-create-theme`](/skills/aid-create-theme/) — Create a visual theme or style-token set.
- [`aid-create-cli`](/skills/aid-create-cli/) — Create a CLI command.
- [`aid-create-data-model`](/skills/aid-create-data-model/) — Create a new data model/entity with its schema migration.
- [`aid-create-data-pipeline`](/skills/aid-create-data-pipeline/) — Create a data pipeline (source, transform, sink, schedule).
- [`aid-create-messaging`](/skills/aid-create-messaging/) — Create a message/event schema and its emission.
- [`aid-create-integration`](/skills/aid-create-integration/) — Create an external-service integration (client/adapter).
- [`aid-create-job`](/skills/aid-create-job/) — Create a scheduled or background job.
- [`aid-create-config`](/skills/aid-create-config/) — Create a new configuration option or feature flag.
- [`aid-create-infra`](/skills/aid-create-infra/) — Provision a new infrastructure resource.
- [`aid-create-roadmap`](/skills/aid-create-roadmap/) — Write roadmap.md from a ready seed.
- [`aid-create-backlog`](/skills/aid-create-backlog/) — Write backlog.md from a ready seed.
- [`aid-create-mvp`](/skills/aid-create-mvp/) — Write the MVP section of roadmap.md from a ready seed.
- [`aid-create-architecture`](/skills/aid-create-architecture/) — Write the architecture document from a ready seed.
- [`aid-create-stack`](/skills/aid-create-stack/) — Write the technology-stack document from a ready seed.
- [`aid-create-testing-strategy`](/skills/aid-create-testing-strategy/) — Write the testing-strategy documents (test landscape, merge gates) from a ready seed.
- [`aid-create-cicd`](/skills/aid-create-cicd/) — Write the CI/CD (shipping) document from a ready seed.
- [`aid-create-test`](/skills/aid-create-test/) — Write new tests, each tracing to an acceptance criterion.
- [`aid-create-document`](/skills/aid-create-document/) — Write any document in one pass, choosing its format and structure.
- [`aid-create-diagram`](/skills/aid-create-diagram/) — Draw a diagram (flowchart, sequence, ER, C4) in one pass.
- [`aid-create-dashboard`](/skills/aid-create-dashboard/) — Build a durable dashboard or BI view.

### `update`

- [`aid-update-roadmap`](/skills/aid-update-roadmap/) — Revise roadmap.md outside the MVP section.
- [`aid-update-mvp`](/skills/aid-update-mvp/) — Revise the MVP section of roadmap.md.
- [`aid-update-backlog`](/skills/aid-update-backlog/) — Revise backlog.md: reprioritize, add or retire items.
- [`aid-update`](/skills/aid-update/) — Change an existing code artifact's behavior.
- [`aid-update-api`](/skills/aid-update-api/) — Update an existing API endpoint or middleware.
- [`aid-update-ui`](/skills/aid-update-ui/) — Update an existing UI component or page.
- [`aid-update-theme`](/skills/aid-update-theme/) — Update an existing visual theme or style-token set.
- [`aid-update-cli`](/skills/aid-update-cli/) — Update an existing CLI command.
- [`aid-update-data-model`](/skills/aid-update-data-model/) — Update an existing data model and its schema migration.
- [`aid-update-data-pipeline`](/skills/aid-update-data-pipeline/) — Update an existing data pipeline.
- [`aid-update-messaging`](/skills/aid-update-messaging/) — Update an existing message/event schema or its emission.
- [`aid-update-integration`](/skills/aid-update-integration/) — Update an existing external-service integration.
- [`aid-update-job`](/skills/aid-update-job/) — Update an existing scheduled or background job.
- [`aid-update-config`](/skills/aid-update-config/) — Update an existing configuration option or feature flag.
- [`aid-update-infra`](/skills/aid-update-infra/) — Update an existing infrastructure resource.
- [`aid-update-architecture`](/skills/aid-update-architecture/) — Revise the architecture document.
- [`aid-update-stack`](/skills/aid-update-stack/) — Revise the technology-stack document.
- [`aid-update-testing-strategy`](/skills/aid-update-testing-strategy/) — Revise the testing-strategy documents.
- [`aid-update-cicd`](/skills/aid-update-cicd/) — Revise the CI/CD (shipping) document.
- [`aid-update-test`](/skills/aid-update-test/) — Update or extend existing tests.
- [`aid-update-document`](/skills/aid-update-document/) — Revise or extend an existing document against the current source.
- [`aid-update-dashboard`](/skills/aid-update-dashboard/) — Update an existing dashboard or BI view.

### `refactor`

- [`aid-refactor`](/skills/aid-refactor/) — Restructure code without changing its behavior.

### `remove`

- [`aid-remove`](/skills/aid-remove/) — Remove code, a feature or a dependency and its uses.

### `deprecate`

- [`aid-deprecate`](/skills/aid-deprecate/) — Mark something deprecated, with a migration path.

### `migrate`

- [`aid-migrate`](/skills/aid-migrate/) — Migrate data, a dependency or a platform, with rollback.

### `test`

- [`aid-test`](/skills/aid-test/) — Run tests or checks and report the findings.
- [`aid-test-security`](/skills/aid-test-security/) — Run a security scan (SAST, DAST, fuzzing, dependency audit) and report.
- [`aid-test-performance`](/skills/aid-test-performance/) — Run a benchmark or load test against a threshold and report.
- [`aid-test-data-quality`](/skills/aid-test-data-quality/) — Run data-quality checks (schema, freshness, completeness, uniqueness) and report.

### `experiment`

- [`aid-experiment`](/skills/aid-experiment/) — Design, run, and analyze a controlled experiment or A/B test.

### `prototype`

- [`aid-prototype`](/skills/aid-prototype/) — Build a throwaway low-fidelity model to test a direction.
- [`aid-prototype-ui`](/skills/aid-prototype-ui/) — Build a throwaway UI wireframe to test a UX direction.

### `design`

- [`aid-design`](/skills/aid-design/) — Design anything without its own design skill (UX flow, component, interface).
- [`aid-design-roadmap`](/skills/aid-design-roadmap/) — Design the roadmap direction as a seed in .aid/design (no code).
- [`aid-design-mvp`](/skills/aid-design-mvp/) — Design the MVP line as a seed in .aid/design (no code).
- [`aid-design-backlog`](/skills/aid-design-backlog/) — Design the backlog as a seed in .aid/design (no code).
- [`aid-design-api`](/skills/aid-design-api/) — Design an API endpoint as a seed in .aid/design (no code).
- [`aid-design-ui`](/skills/aid-design-ui/) — Design a UI screen or flow as a seed in .aid/design (no code).
- [`aid-design-theme`](/skills/aid-design-theme/) — Design a visual theme as a seed in .aid/design (no code).
- [`aid-design-cli`](/skills/aid-design-cli/) — Design a CLI command as a seed in .aid/design (no code).
- [`aid-design-data-model`](/skills/aid-design-data-model/) — Design a data model as a seed in .aid/design (no code).
- [`aid-design-data-pipeline`](/skills/aid-design-data-pipeline/) — Design a data pipeline as a seed in .aid/design (no code).
- [`aid-design-messaging`](/skills/aid-design-messaging/) — Design a message or event as a seed in .aid/design (no code).
- [`aid-design-integration`](/skills/aid-design-integration/) — Design an integration as a seed in .aid/design (no code).
- [`aid-design-job`](/skills/aid-design-job/) — Design a background job as a seed in .aid/design (no code).
- [`aid-design-config`](/skills/aid-design-config/) — Design a config option as a seed in .aid/design (no code).
- [`aid-design-infra`](/skills/aid-design-infra/) — Design an infrastructure resource as a seed in .aid/design (no code).
- [`aid-design-test`](/skills/aid-design-test/) — Design a test as a seed in .aid/design (no code).
- [`aid-design-document`](/skills/aid-design-document/) — Design a document as a seed in .aid/design (no code).
- [`aid-design-dashboard`](/skills/aid-design-dashboard/) — Design a dashboard as a seed in .aid/design (no code).
- [`aid-design-architecture`](/skills/aid-design-architecture/) — Design the system architecture as a seed in .aid/design (no code).
- [`aid-design-stack`](/skills/aid-design-stack/) — Design the technology stack as a seed in .aid/design (no code).
- [`aid-design-testing-strategy`](/skills/aid-design-testing-strategy/) — Design the testing policy as a seed in .aid/design (no code).
- [`aid-design-cicd`](/skills/aid-design-cicd/) — Design the delivery pipeline as a seed in .aid/design (no code).

### `brainstorm`

- [`aid-brainstorm`](/skills/aid-brainstorm/) — Explore a fuzzy problem into a design seed in .aid/design.

### `document`

- [`aid-document`](/skills/aid-document/) — Write a how-to, reference, explanation or status report in one pass.
- [`aid-document-decision`](/skills/aid-document-decision/) — Write an ADR (decision record) in one pass.
- [`aid-document-architecture`](/skills/aid-document-architecture/) — Write an architecture write-up (C4 or arc42) in one pass.
- [`aid-document-guideline`](/skills/aid-document-guideline/) — Write a guideline (advisory practice) in one pass.
- [`aid-document-standard`](/skills/aid-document-standard/) — Write a standard (mandatory rule) in one pass.
- [`aid-document-runbook`](/skills/aid-document-runbook/) — Write a runbook (operational procedure) in one pass.
- [`aid-document-tutorial`](/skills/aid-document-tutorial/) — Write a tutorial (learning walkthrough) in one pass.
- [`aid-document-changelog`](/skills/aid-document-changelog/) — Write a changelog (release notes) in one pass.

### `report`

- [`aid-report`](/skills/aid-report/) — Analyse data or usage into a verified insight report.

### `review`

- [`aid-review`](/skills/aid-review/) — Review code, a diff, a design, a document or a ticket against criteria and return findings.

### `research`

- [`aid-research`](/skills/aid-research/) — Investigate an open technical question, weighing options, and return a verified answer.

### `deploy`

- [`aid-deploy`](/skills/aid-deploy/) — Package completed deliveries into a release: verify the build, package, write release notes.

### `monitor`

- [`aid-monitor`](/skills/aid-monitor/) — Watch production, classify what you find and route it: bugs to /aid-fix, change requests to /aid-triage.

## Execution

Skills for executing detailed tasks, each through a graded adversarial review loop.

- [`aid-execute`](/skills/aid-execute/) — Carry out each planned task by its type and review it until it meets the minimum grade.
