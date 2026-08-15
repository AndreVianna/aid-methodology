---
title: 'All Skills'
description: 'Every AID skill, one card each, grouped by skill group and — inside Definition — by verb family.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
sidebar:
  hidden: true
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml -->

AID ships **111 skill directories** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), with the Definition group subdivided into **18 verb families** derived from the shortcut catalog. Each card below links to that skill’s detail page.

> **Note:** This page is the roster, and it files skills per FR-5’s Placement rules. `aid-triage` is **Support** here and **Definition** in the curated roster that [the methodology's skill inventory](/concepts/methodology/) publishes. Where they disagree about grouping, **this page is authoritative**. How the shortcut skills themselves work — the shared engine and its INTAKE → APPROVAL-HALT sequence — is at [Reference → Shortcut engine](/reference/skills/).

## Support

Skills for configuring AID and managing tickets and connectors. Start here if you're not sure which skill to use.

- [`aid-triage`](/skills/aid-triage/) — Suggest which AID entry point fits the work you are describing.
- [`aid-config`](/skills/aid-config/) — View or update AID pipeline settings.
- [`aid-set-connector`](/skills/aid-set-connector/) — Add or update one entry in the connector catalog.
- [`aid-unset-connector`](/skills/aid-unset-connector/) — Remove one entry from the connector catalog.
- [`aid-read-ticket`](/skills/aid-read-ticket/) — Read one ticket from the project's issue tracker and show its fields.
- [`aid-create-ticket`](/skills/aid-create-ticket/) — File one new ticket in the project's issue tracker.
- [`aid-update-ticket`](/skills/aid-update-ticket/) — Change exactly one part of an existing ticket in the project's issue tracker.

## Knowledge Base Maintenance

Skills for discovering, querying, summarising, mapping, and maintaining the project Knowledge Base.

- [`aid-discover`](/skills/aid-discover/) — Populate the Knowledge Base from a codebase that already exists.
- [`aid-summarize`](/skills/aid-summarize/) — Generate kb.html, a single-file visual tour of the Knowledge Base.
- [`aid-housekeep`](/skills/aid-housekeep/) — Sweep the project back into a consistent state after work has landed.
- [`aid-update-kb`](/skills/aid-update-kb/) — Apply one targeted, human-confirmed change to the Knowledge Base.
- [`aid-ask`](/skills/aid-ask/) — Answer a question about this project, with citations.

## Definition

The full AID pipeline plus every shortcut skill, grouped by verb family.

**The full path** — the five phases, in order:

- [`aid-describe`](/skills/aid-describe/) — Gather requirements through an adaptive interview and write them to REQUIREMENTS.md.
- [`aid-define`](/skills/aid-define/) — Decompose approved requirements into discrete feature folders, each with its own SPEC.md stub.
- [`aid-specify`](/skills/aid-specify/) — Turn one feature into a technical specification, collaboratively.
- [`aid-plan`](/skills/aid-plan/) — Sequence feature SPECs into deliverables -- each one a functional MVP that builds on the previous.
- [`aid-detail`](/skills/aid-detail/) — Break deliverables into small, dependency-driven, typed tasks -- each one a reviewable unit.

### `fix`

- [`aid-fix`](/skills/aid-fix/) — Diagnose and correct a defect, regression, incident, or vulnerability.

### `create`

- [`aid-create`](/skills/aid-create/) — Create a new internal code artifact (module, interface, type) from scratch.
- [`aid-create-api`](/skills/aid-create-api/) — Create an API endpoint / middleware (contract, handler, validation).
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
- [`aid-create-roadmap`](/skills/aid-create-roadmap/) — Realize a ready roadmap seed into .aid/knowledge/roadmap.md -- frontmatter, preamble, ## Contents index (including the forward ## MVP entry), and the three…
- [`aid-create-backlog`](/skills/aid-create-backlog/) — Realize a ready backlog seed into .aid/knowledge/backlog.md -- frontmatter, preamble, ## Contents index, ## Next Release, ## Prioritized, and ## Gotchas.
- [`aid-create-mvp`](/skills/aid-create-mvp/) — Realize a ready MVP seed into roadmap.md's ## MVP section only -- the first shippable slice: what it includes, why the line falls there, what was cut, and…
- [`aid-create-architecture`](/skills/aid-create-architecture/) — Realize a ready architecture seed from .aid/design/architecture.md into the project's build-and-shape (C1) Knowledge Base document -- components and their…
- [`aid-create-stack`](/skills/aid-create-stack/) — Realize a ready stack seed from .aid/design/stack.md into the project's technology (C0) Knowledge Base document -- languages, runtimes, frameworks, package…
- [`aid-create-testing-strategy`](/skills/aid-create-testing-strategy/) — Realize a ready testing-strategy seed from .aid/design/testing-strategy.md into the project's quality (C6) documents -- the test landscape (levels, coverage…
- [`aid-create-cicd`](/skills/aid-create-cicd/) — Realize a ready CI/CD seed from .aid/design/cicd.md into the project's shipping (C8) Knowledge Base document -- the pipeline stages and their order, the…
- [`aid-create-test`](/skills/aid-create-test/) — Author new tests (unit/integration/e2e); each test traces to an acceptance criterion; framework inferred from the KB.
- [`aid-create-document`](/skills/aid-create-document/) — Create a document in one pass, working out both its format and its structure from what you ask for -- a how-to, a reference page, an ADR, an architecture…
- [`aid-create-diagram`](/skills/aid-create-diagram/) — Create a diagram in one pass, choosing the diagram type that fits the subject -- flowchart, sequence, entity-relationship, C4, state, and so on, in Mermaid…
- [`aid-create-dashboard`](/skills/aid-create-dashboard/) — Build a durable dashboard / BI view (source -> visualization -> publish/refresh).

### `update`

- [`aid-update-roadmap`](/skills/aid-update-roadmap/) — Revise roadmap.md's direction entries outside the ## MVP section -- add, revise or supersede direction entries, and move an entry between horizon sections…
- [`aid-update-mvp`](/skills/aid-update-mvp/) — Revise roadmap.md's ## MVP section only -- the first shippable slice: its contents, the line reasoning, what was cut, and its Status field (including the…
- [`aid-update-backlog`](/skills/aid-update-backlog/) — Revise backlog.md -- re-prioritize items, add new items, and promote accepted tech-debt.md rows into backlog.md (deleted from tech-debt.md in the same run).
- [`aid-update`](/skills/aid-update/) — Update an existing internal code artifact's behavior under new acceptance criteria.
- [`aid-update-api`](/skills/aid-update-api/) — Update an existing API endpoint / middleware's contract or behavior.
- [`aid-update-ui`](/skills/aid-update-ui/) — Update an existing UI component or page.
- [`aid-update-theme`](/skills/aid-update-theme/) — Update an existing visual theme or style-token set.
- [`aid-update-cli`](/skills/aid-update-cli/) — Update an existing CLI command.
- [`aid-update-data-model`](/skills/aid-update-data-model/) — Update an existing data model/entity's schema, with forward+rollback migration.
- [`aid-update-data-pipeline`](/skills/aid-update-data-pipeline/) — Update an existing data pipeline's source, transform, sink, or schedule.
- [`aid-update-messaging`](/skills/aid-update-messaging/) — Update an existing message/event schema or its emission.
- [`aid-update-integration`](/skills/aid-update-integration/) — Update an existing external-service integration.
- [`aid-update-job`](/skills/aid-update-job/) — Update an existing scheduled or background job.
- [`aid-update-config`](/skills/aid-update-config/) — Update an existing configuration option or feature flag.
- [`aid-update-infra`](/skills/aid-update-infra/) — Update an existing infrastructure resource.
- [`aid-update-architecture`](/skills/aid-update-architecture/) — Revise the project's build-and-shape (C1) Knowledge Base document -- components and their responsibilities, boundaries, interactions, and the invariants a…
- [`aid-update-stack`](/skills/aid-update-stack/) — Revise the project's technology (C0) Knowledge Base document -- languages, runtimes, frameworks, package managers, and build and test tooling with their…
- [`aid-update-testing-strategy`](/skills/aid-update-testing-strategy/) — Revise the project's quality (C6) documents -- the test landscape (levels, coverage expectations, CI lane mapping, known gaps) and the gate policy (what…
- [`aid-update-cicd`](/skills/aid-update-cicd/) — Revise the project's shipping (C8) Knowledge Base document -- pipeline stages and their order, triggers, environments and promotion, and the release flow --…
- [`aid-update-test`](/skills/aid-update-test/) — Update or extend existing tests.
- [`aid-update-document`](/skills/aid-update-document/) — Revise or extend a document that already exists, in one pass.
- [`aid-update-dashboard`](/skills/aid-update-dashboard/) — Update an existing dashboard / BI view (source, visualization, or refresh cadence).

### `refactor`

- [`aid-refactor`](/skills/aid-refactor/) — Restructure or optimize code without changing behavior (rename, restructure, or improve performance).

### `remove`

- [`aid-remove`](/skills/aid-remove/) — Remove or delete a code artifact, endpoint, dependency, feature, or dead code; update dependents, tests, and docs.

### `deprecate`

- [`aid-deprecate`](/skills/aid-deprecate/) — Deprecate an existing artifact/API: mark deprecated, add warnings and a migration path, without deleting yet.

### `migrate`

- [`aid-migrate`](/skills/aid-migrate/) — Migrate data, a dependency, framework, or platform, with a rollback plan (non-schema; schema migrations use create/update-data-model).

### `test`

- [`aid-test`](/skills/aid-test/) — Run a test suite or verification and consolidate the results into findings, in one pass.
- [`aid-test-security`](/skills/aid-test-security/) — Run a security verification and consolidate the findings -- SAST, DAST, fuzzing, or a dependency audit.
- [`aid-test-performance`](/skills/aid-test-performance/) — Run a performance verification against a threshold or SLO -- a benchmark, a load test, or a stress test -- and report measured against target.
- [`aid-test-data-quality`](/skills/aid-test-data-quality/) — Run data-quality checks against thresholds and report -- schema, freshness, completeness, uniqueness.

### `experiment`

- [`aid-experiment`](/skills/aid-experiment/) — Design, run, and analyze a controlled experiment or A/B test.

### `prototype`

- [`aid-prototype`](/skills/aid-prototype/) — Build a throwaway, low-fidelity model to test whether a direction actually works, before anyone commits to building it properly.
- [`aid-prototype-ui`](/skills/aid-prototype-ui/) — Build a throwaway, low-fidelity UI wireframe and interaction flow to test whether a UX direction actually works.

### `design`

- [`aid-design`](/skills/aid-design/) — Produce a design artifact you intend to keep -- a UX or interaction flow, a component or interface design, with accessibility notes -- meant to inform the…
- [`aid-design-roadmap`](/skills/aid-design-roadmap/) — Develop the project's committed direction as a DESIGN SEED in .aid/design/roadmap.md -- what is committed vs.
- [`aid-design-mvp`](/skills/aid-design-mvp/) — Draw the MVP line as a DESIGN SEED in .aid/design/mvp.md -- what is in the first shippable slice, what defers, and the reason for each cut.
- [`aid-design-backlog`](/skills/aid-design-backlog/) — Develop the defined-and-prioritized item set as a DESIGN SEED in .aid/design/backlog.md -- item definitions, done-conditions, priorities, and which…
- [`aid-design-api`](/skills/aid-design-api/) — Develop an API design as a DESIGN SEED in .aid/design/api.md -- the resource shape, the request/response contract, and the error model.
- [`aid-design-ui`](/skills/aid-design-ui/) — Develop a UI design as a DESIGN SEED in .aid/design/ui.md -- the screen/flow structure, the interaction model, and accessibility notes.
- [`aid-design-theme`](/skills/aid-design-theme/) — Develop a visual theme design as a DESIGN SEED in .aid/design/theme.md -- the style-token set (color, type, spacing), its light/dark variants, and how…
- [`aid-design-cli`](/skills/aid-design-cli/) — Develop a CLI design as a DESIGN SEED in .aid/design/cli.md -- the command and subcommand shape, its arguments and flags, and its output and error…
- [`aid-design-data-model`](/skills/aid-design-data-model/) — Develop a data-model design as a DESIGN SEED in .aid/design/data-model.md -- its entities, their relationships, and the migration impact of introducing them.
- [`aid-design-data-pipeline`](/skills/aid-design-data-pipeline/) — Develop a data-pipeline design as a DESIGN SEED in .aid/design/data-pipeline.md -- the source, the transform, the sink, and the schedule.
- [`aid-design-messaging`](/skills/aid-design-messaging/) — Develop a messaging design as a DESIGN SEED in .aid/design/messaging.md -- the message/event schema, its channel, and its emission points.
- [`aid-design-integration`](/skills/aid-design-integration/) — Develop an external-service integration design as a DESIGN SEED in .aid/design/integration.md -- the external service, the client/adapter surface, and the…
- [`aid-design-job`](/skills/aid-design-job/) — Develop a scheduled or background job design as a DESIGN SEED in .aid/design/job.md -- the trigger, the work it performs, and its idempotency and failure…
- [`aid-design-config`](/skills/aid-design-config/) — Develop a configuration-option or feature-flag design as a DESIGN SEED in .aid/design/config.md -- the option or flag, its default and scope, and how it is…
- [`aid-design-infra`](/skills/aid-design-infra/) — Develop an infrastructure-resource design as a DESIGN SEED in .aid/design/infra.md -- the resource, its configuration, and its provisioning and teardown.
- [`aid-design-test`](/skills/aid-design-test/) — Develop a test design as a DESIGN SEED in .aid/design/test.md -- the units under test, the cases, and the framework and fixtures.
- [`aid-design-document`](/skills/aid-design-document/) — Develop a document design as a DESIGN SEED in .aid/design/document.md -- the document's kind and structure, its audience, and its placement.
- [`aid-design-dashboard`](/skills/aid-design-dashboard/) — Develop a dashboard / BI-view design as a DESIGN SEED in .aid/design/dashboard.md -- the data source, the visualizations, and the refresh cadence.
- [`aid-design-architecture`](/skills/aid-design-architecture/) — Develop the system's shape as a DESIGN SEED in .aid/design/architecture.md -- components, boundaries, interactions, invariants, and what is deliberately not…
- [`aid-design-stack`](/skills/aid-design-stack/) — Develop the technology choice as a DESIGN SEED in .aid/design/stack.md -- languages, runtimes, frameworks, and build and test tooling with versions, plus the…
- [`aid-design-testing-strategy`](/skills/aid-design-testing-strategy/) — Develop the testing policy as a DESIGN SEED in .aid/design/testing-strategy.md -- test levels, coverage expectations, which gates block a merge, and who may…
- [`aid-design-cicd`](/skills/aid-design-cicd/) — Develop the delivery pipeline as a DESIGN SEED in .aid/design/cicd.md -- stages, triggers, environments, promotion, and release flow.

### `brainstorm`

- [`aid-brainstorm`](/skills/aid-brainstorm/) — Diverge on a problem not yet formed into an answerable question, then converge it to a DESIGN SEED in .aid/design/&lt;slug>.md -- exploration, framings, and the…

### `document`

- [`aid-document`](/skills/aid-document/) — Write a general document in one pass -- a Diataxis how-to, reference page or explanation, or a status or progress report.
- [`aid-document-decision`](/skills/aid-document-decision/) — Write an ADR in one pass -- an architecture decision record: the context, the decision itself, the alternatives considered, and the consequences.
- [`aid-document-architecture`](/skills/aid-document-architecture/) — Write an architecture write-up in one pass -- a system's components, boundaries, and interactions, as C4 or arc42 views with Mermaid diagrams.
- [`aid-document-guideline`](/skills/aid-document-guideline/) — Write a guideline in one pass -- an advisory recommended practice, stating the principle, its rationale, and do/don't examples.
- [`aid-document-standard`](/skills/aid-document-standard/) — Write a standard in one pass -- a mandatory rule, stating the rule, its scope, how compliance is enforced, and the exceptions.
- [`aid-document-runbook`](/skills/aid-document-runbook/) — Write a runbook in one pass -- an operational procedure, from trigger through diagnostic and remediation to escalation.
- [`aid-document-tutorial`](/skills/aid-document-tutorial/) — Write a tutorial in one pass -- a learning-oriented walkthrough, from prerequisites through worked steps to the outcome.
- [`aid-document-changelog`](/skills/aid-document-changelog/) — Write a changelog in one pass -- release notes grouped as Added, Changed, Fixed, Removed and Security.

### `report`

- [`aid-report`](/skills/aid-report/) — Analyse data or usage and return a verified insight report in one pass -- exploratory analysis, metrics, or an A/B result.

### `review`

- [`aid-review`](/skills/aid-review/) — Review an existing artifact against criteria and return findings and recommendations in one pass -- code, a diff, a design, a pull request, a ticket, a…

### `research`

- [`aid-research`](/skills/aid-research/) — Investigate an open technical question and return a verified answer in one pass -- evaluating options, or running an isolated feasibility spike if you…

### `deploy`

- [`aid-deploy`](/skills/aid-deploy/) — Package completed deliveries into a release.

### `monitor`

- [`aid-monitor`](/skills/aid-monitor/) — Watch production, classify what you find, and route it to whoever should act.

## Execution

Skills for executing detailed tasks, each through a graded adversarial review loop.

- [`aid-execute`](/skills/aid-execute/) — Carry out one planned task and review the result.
