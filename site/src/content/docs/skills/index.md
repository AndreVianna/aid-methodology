---
title: 'All Skills'
description: 'Every AID skill, one card each, grouped by skill group and — inside Definition — by verb family.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
sidebar:
  hidden: true
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml -->

AID ships **111 skill directories** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), with the Definition group subdivided into **17 verb families** derived from the shortcut catalog. Each card below links to that skill’s detail page.

> **Note:** [Reference → Skills](/reference/skills/) is a terse family **summary**, generated separately. It groups `aid-triage`, `aid-deploy`, and `aid-monitor` under *Definition*, while this page files them per FR-5’s Placement rules. Where the two pages disagree about grouping, **this page is authoritative**. The difference exists because the older generator is frozen, not because either page is stale-by-accident.

## Support

Skills for configuring AID and managing tickets and connectors. Start here if you're not sure which skill to use.

- [`aid-triage`](/skills/aid-triage/) — Suggest-only router for "I don't know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the…
- [`aid-config`](/skills/aid-config/) — View or update AID pipeline settings.
- [`aid-set-connector`](/skills/aid-set-connector/) — On-demand, off-pipeline upsert into the connector catalog.
- [`aid-unset-connector`](/skills/aid-unset-connector/) — On-demand, off-pipeline removal from the connector catalog.
- [`aid-read-ticket`](/skills/aid-read-ticket/) — On-demand, non-destructive ticket read.
- [`aid-create-ticket`](/skills/aid-create-ticket/) — On-demand utility skill that files one new ticket via whatever issue-tracker connector the project has registered, or the host tool's own tracker MCP when…
- [`aid-update-ticket`](/skills/aid-update-ticket/) — On-demand write skill that mutates exactly ONE named part of an existing ticket in whatever issue-tracker connector resolves for it: `aid-update-ticket…

## Knowledge Base Maintenance

Skills for discovering, querying, summarising, and maintaining the project Knowledge Base.

- [`aid-discover`](/skills/aid-discover/) — Brownfield project discovery with built-in quality gate.
- [`aid-summarize`](/skills/aid-summarize/) — Generate a single-file kb.html from .aid/knowledge/.
- [`aid-housekeep`](/skills/aid-housekeep/) — Optional on-demand housekeeping skill.
- [`aid-update-kb`](/skills/aid-update-kb/) — Optional on-demand targeted KB update skill.
- [`aid-query-kb`](/skills/aid-query-kb/) — Optional on-demand Q&amp;A skill.
- [`aid-ask`](/skills/aid-ask/) — Friendly-named alias of /aid-query-kb -- the optional on-demand Q&amp;A skill.

## Definition

The full AID pipeline plus every shortcut skill, grouped by verb family.

**The full path** — the five phases, in order:

- [`aid-describe`](/skills/aid-describe/) — Conversational requirements gathering through adaptive interview, driven by the seasoned-analyst elicitation engine (references/elicitation-engine.md): one…
- [`aid-define`](/skills/aid-define/) — Feature decomposition and cross-reference validation from approved requirements.
- [`aid-specify`](/skills/aid-specify/) — Technical specification through conversational refinement, one feature at a time.
- [`aid-plan`](/skills/aid-plan/) — Sequence feature SPECs into deliverables — each one a functional MVP that builds on the previous.
- [`aid-detail`](/skills/aid-detail/) — Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit.

### `fix`

- [`aid-fix`](/skills/aid-fix/) — Direct-entry Lite-path shortcut (Diagnose and correct a defect, regression, incident, or vulnerability.) -- skips the aid-describe interview/triage.

### `create`

- [`aid-create`](/skills/aid-create/) — Direct-entry Lite-path shortcut (Create a new internal code artifact (module, interface, type) from scratch.) -- skips the aid-describe interview/triage.
- [`aid-create-api`](/skills/aid-create-api/) — Direct-entry Lite-path shortcut (Create an API endpoint / middleware (contract, handler, validation).) -- skips the aid-describe interview/triage.
- [`aid-create-ui`](/skills/aid-create-ui/) — Direct-entry Lite-path shortcut (Create a UI component or page.) -- skips the aid-describe interview/triage.
- [`aid-create-theme`](/skills/aid-create-theme/) — Direct-entry Lite-path shortcut (Create a visual theme or style-token set.) -- skips the aid-describe interview/triage.
- [`aid-create-cli`](/skills/aid-create-cli/) — Direct-entry Lite-path shortcut (Create a CLI command.) -- skips the aid-describe interview/triage.
- [`aid-create-data-model`](/skills/aid-create-data-model/) — Direct-entry Lite-path shortcut (Create a new data model/entity with its schema migration.) -- skips the aid-describe interview/triage.
- [`aid-create-data-pipeline`](/skills/aid-create-data-pipeline/) — Direct-entry Lite-path shortcut (Create a data pipeline (source, transform, sink, schedule).) -- skips the aid-describe interview/triage.
- [`aid-create-messaging`](/skills/aid-create-messaging/) — Direct-entry Lite-path shortcut (Create a message/event schema and its emission.) -- skips the aid-describe interview/triage.
- [`aid-create-integration`](/skills/aid-create-integration/) — Direct-entry Lite-path shortcut (Create an external-service integration (client/adapter).) -- skips the aid-describe interview/triage.
- [`aid-create-job`](/skills/aid-create-job/) — Direct-entry Lite-path shortcut (Create a scheduled or background job.) -- skips the aid-describe interview/triage.
- [`aid-create-config`](/skills/aid-create-config/) — Direct-entry Lite-path shortcut (Create a new configuration option or feature flag.) -- skips the aid-describe interview/triage.
- [`aid-create-infra`](/skills/aid-create-infra/) — Direct-entry Lite-path shortcut (Provision a new infrastructure resource.) -- skips the aid-describe interview/triage.
- [`aid-add`](/skills/aid-add/) — Direct-entry Lite-path shortcut (Alias of aid-create.) -- skips the aid-describe interview/triage.
- [`aid-add-api`](/skills/aid-add-api/) — Direct-entry Lite-path shortcut (Alias of aid-create-api.) -- skips the aid-describe interview/triage.
- [`aid-add-ui`](/skills/aid-add-ui/) — Direct-entry Lite-path shortcut (Alias of aid-create-ui.) -- skips the aid-describe interview/triage.
- [`aid-add-theme`](/skills/aid-add-theme/) — Direct-entry Lite-path shortcut (Alias of aid-create-theme.) -- skips the aid-describe interview/triage.
- [`aid-add-cli`](/skills/aid-add-cli/) — Direct-entry Lite-path shortcut (Alias of aid-create-cli.) -- skips the aid-describe interview/triage.
- [`aid-add-data-model`](/skills/aid-add-data-model/) — Direct-entry Lite-path shortcut (Alias of aid-create-data-model.) -- skips the aid-describe interview/triage.
- [`aid-add-data-pipeline`](/skills/aid-add-data-pipeline/) — Direct-entry Lite-path shortcut (Alias of aid-create-data-pipeline.) -- skips the aid-describe interview/triage.
- [`aid-add-messaging`](/skills/aid-add-messaging/) — Direct-entry Lite-path shortcut (Alias of aid-create-messaging.) -- skips the aid-describe interview/triage.
- [`aid-add-integration`](/skills/aid-add-integration/) — Direct-entry Lite-path shortcut (Alias of aid-create-integration.) -- skips the aid-describe interview/triage.
- [`aid-add-job`](/skills/aid-add-job/) — Direct-entry Lite-path shortcut (Alias of aid-create-job.) -- skips the aid-describe interview/triage.
- [`aid-add-config`](/skills/aid-add-config/) — Direct-entry Lite-path shortcut (Alias of aid-create-config.) -- skips the aid-describe interview/triage.
- [`aid-add-infra`](/skills/aid-add-infra/) — Direct-entry Lite-path shortcut (Alias of aid-create-infra.) -- skips the aid-describe interview/triage.
- [`aid-create-test`](/skills/aid-create-test/) — Direct-entry Lite-path shortcut (Author new tests (unit/integration/e2e); each test traces to an acceptance criterion; framework inferred from the KB.) --…
- [`aid-add-test`](/skills/aid-add-test/) — Direct-entry Lite-path shortcut (Alias of aid-create-test.) -- skips the aid-describe interview/triage.
- [`aid-create-document`](/skills/aid-create-document/) — Create a document NOW -- markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a mermaid diagram, a table --…
- [`aid-add-document`](/skills/aid-add-document/) — Alias of /aid-create-document -- create a document NOW (markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a…
- [`aid-create-diagram`](/skills/aid-create-diagram/) — Create a diagram NOW -- a mermaid or graphviz diagram (flowchart, sequence, ER, C4, state, ...) chosen for the subject, in one pass.
- [`aid-create-dashboard`](/skills/aid-create-dashboard/) — Direct-entry Lite-path shortcut (Build a durable dashboard / BI view (source -> visualization -> publish/refresh).) -- skips the aid-describe…
- [`aid-add-dashboard`](/skills/aid-add-dashboard/) — Direct-entry Lite-path shortcut (Alias of aid-create-dashboard.) -- skips the aid-describe interview/triage.
- [`aid-show-dashboard`](/skills/aid-show-dashboard/) — Direct-entry Lite-path shortcut (Alias of aid-create-dashboard (backward-compatible name).) -- skips the aid-describe interview/triage.

### `change`

- [`aid-change`](/skills/aid-change/) — Direct-entry Lite-path shortcut (Change an existing internal code artifact's behavior under new acceptance criteria.) -- skips the aid-describe…
- [`aid-change-api`](/skills/aid-change-api/) — Direct-entry Lite-path shortcut (Change an existing API endpoint / middleware's contract or behavior.) -- skips the aid-describe interview/triage.
- [`aid-change-ui`](/skills/aid-change-ui/) — Direct-entry Lite-path shortcut (Change an existing UI component or page.) -- skips the aid-describe interview/triage.
- [`aid-change-theme`](/skills/aid-change-theme/) — Direct-entry Lite-path shortcut (Change an existing visual theme or style-token set.) -- skips the aid-describe interview/triage.
- [`aid-change-cli`](/skills/aid-change-cli/) — Direct-entry Lite-path shortcut (Change an existing CLI command.) -- skips the aid-describe interview/triage.
- [`aid-change-data-model`](/skills/aid-change-data-model/) — Direct-entry Lite-path shortcut (Change an existing data model/entity's schema, with forward+rollback migration.) -- skips the aid-describe interview/triage.
- [`aid-change-data-pipeline`](/skills/aid-change-data-pipeline/) — Direct-entry Lite-path shortcut (Change an existing data pipeline's source, transform, sink, or schedule.) -- skips the aid-describe interview/triage.
- [`aid-change-messaging`](/skills/aid-change-messaging/) — Direct-entry Lite-path shortcut (Change an existing message/event schema or its emission.) -- skips the aid-describe interview/triage.
- [`aid-change-integration`](/skills/aid-change-integration/) — Direct-entry Lite-path shortcut (Change an existing external-service integration.) -- skips the aid-describe interview/triage.
- [`aid-change-job`](/skills/aid-change-job/) — Direct-entry Lite-path shortcut (Change an existing scheduled or background job.) -- skips the aid-describe interview/triage.
- [`aid-change-config`](/skills/aid-change-config/) — Direct-entry Lite-path shortcut (Change an existing configuration option or feature flag.) -- skips the aid-describe interview/triage.
- [`aid-change-infra`](/skills/aid-change-infra/) — Direct-entry Lite-path shortcut (Change an existing infrastructure resource.) -- skips the aid-describe interview/triage.
- [`aid-update`](/skills/aid-update/) — Direct-entry Lite-path shortcut (Alias of aid-change.) -- skips the aid-describe interview/triage.
- [`aid-update-api`](/skills/aid-update-api/) — Direct-entry Lite-path shortcut (Alias of aid-change-api.) -- skips the aid-describe interview/triage.
- [`aid-update-ui`](/skills/aid-update-ui/) — Direct-entry Lite-path shortcut (Alias of aid-change-ui.) -- skips the aid-describe interview/triage.
- [`aid-update-theme`](/skills/aid-update-theme/) — Direct-entry Lite-path shortcut (Alias of aid-change-theme.) -- skips the aid-describe interview/triage.
- [`aid-update-cli`](/skills/aid-update-cli/) — Direct-entry Lite-path shortcut (Alias of aid-change-cli.) -- skips the aid-describe interview/triage.
- [`aid-update-data-model`](/skills/aid-update-data-model/) — Direct-entry Lite-path shortcut (Alias of aid-change-data-model.) -- skips the aid-describe interview/triage.
- [`aid-update-data-pipeline`](/skills/aid-update-data-pipeline/) — Direct-entry Lite-path shortcut (Alias of aid-change-data-pipeline.) -- skips the aid-describe interview/triage.
- [`aid-update-messaging`](/skills/aid-update-messaging/) — Direct-entry Lite-path shortcut (Alias of aid-change-messaging.) -- skips the aid-describe interview/triage.
- [`aid-update-integration`](/skills/aid-update-integration/) — Direct-entry Lite-path shortcut (Alias of aid-change-integration.) -- skips the aid-describe interview/triage.
- [`aid-update-job`](/skills/aid-update-job/) — Direct-entry Lite-path shortcut (Alias of aid-change-job.) -- skips the aid-describe interview/triage.
- [`aid-update-config`](/skills/aid-update-config/) — Direct-entry Lite-path shortcut (Alias of aid-change-config.) -- skips the aid-describe interview/triage.
- [`aid-update-infra`](/skills/aid-update-infra/) — Direct-entry Lite-path shortcut (Alias of aid-change-infra.) -- skips the aid-describe interview/triage.
- [`aid-change-test`](/skills/aid-change-test/) — Direct-entry Lite-path shortcut (Change or extend existing tests.) -- skips the aid-describe interview/triage.
- [`aid-update-test`](/skills/aid-update-test/) — Direct-entry Lite-path shortcut (Alias of aid-change-test.) -- skips the aid-describe interview/triage.
- [`aid-change-document`](/skills/aid-change-document/) — Update an EXISTING document NOW -- revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, etc.
- [`aid-update-document`](/skills/aid-update-document/) — Alias of /aid-change-document -- update an EXISTING document NOW (revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, ...) in one pass.
- [`aid-change-dashboard`](/skills/aid-change-dashboard/) — Direct-entry Lite-path shortcut (Change an existing dashboard / BI view (source, visualization, or refresh cadence).) -- skips the aid-describe…
- [`aid-update-dashboard`](/skills/aid-update-dashboard/) — Direct-entry Lite-path shortcut (Alias of aid-change-dashboard.) -- skips the aid-describe interview/triage.

### `refactor`

- [`aid-refactor`](/skills/aid-refactor/) — Direct-entry Lite-path shortcut (Restructure or optimize code without changing behavior (rename, restructure, or improve performance).) -- skips the…

### `remove`

- [`aid-remove`](/skills/aid-remove/) — Direct-entry Lite-path shortcut (Remove or delete a code artifact, endpoint, dependency, feature, or dead code; update dependents, tests, and docs.) -- skips…
- [`aid-delete`](/skills/aid-delete/) — Direct-entry Lite-path shortcut (Alias of aid-remove.) -- skips the aid-describe interview/triage.

### `deprecate`

- [`aid-deprecate`](/skills/aid-deprecate/) — Direct-entry Lite-path shortcut (Deprecate an existing artifact/API: mark deprecated, add warnings and a migration path, without deleting yet.) -- skips the…

### `migrate`

- [`aid-migrate`](/skills/aid-migrate/) — Direct-entry Lite-path shortcut (Migrate data, a dependency, framework, or platform, with a rollback plan (non-schema; schema migrations use…

### `test`

- [`aid-test`](/skills/aid-test/) — Run a test suite / verification NOW and consolidate the results into findings, in one pass.
- [`aid-test-security`](/skills/aid-test-security/) — Run a security verification NOW -- SAST, DAST, fuzzing, or dependency audit -- and consolidate findings.
- [`aid-test-performance`](/skills/aid-test-performance/) — Run a performance verification NOW -- benchmark, load test, or stress test against a threshold/SLO -- and report measured-vs-threshold.
- [`aid-test-data-quality`](/skills/aid-test-data-quality/) — Run data-quality checks NOW -- schema, freshness, completeness, uniqueness -- on a dataset or pipeline, against thresholds, and report.

### `experiment`

- [`aid-experiment`](/skills/aid-experiment/) — Direct-entry Lite-path shortcut (Design, run, and analyze a controlled experiment or A/B test.) -- skips the aid-describe interview/triage.

### `prototype`

- [`aid-prototype`](/skills/aid-prototype/) — Build a THROWAWAY low-fidelity model NOW to validate a direction before committing to a full build -- then present what it shows and hand the real build off…
- [`aid-prototype-ui`](/skills/aid-prototype-ui/) — A ui kind-sibling of /aid-prototype -- build a THROWAWAY low-fidelity UI wireframe/mock + interaction flow NOW to validate a UX direction, then present what…

### `design`

- [`aid-design`](/skills/aid-design/) — Produce a KEPT design artifact NOW -- a UX/interaction flow, a component or interface design, an architecture sketch, with accessibility notes -- meant to…

### `document`

- [`aid-document`](/skills/aid-document/) — Write a general document NOW -- a Diataxis how-to / reference / explanation, or a status/progress report -- in one pass.
- [`aid-document-decision`](/skills/aid-document-decision/) — Write an ADR NOW -- an architecture decision record (Context -> Decision -> Alternatives -> Consequences) -- in one pass.
- [`aid-document-architecture`](/skills/aid-document-architecture/) — Document an architecture NOW -- a system's components, boundaries, and interactions (C4/arc42 views + Mermaid diagrams) -- in one pass.
- [`aid-document-guideline`](/skills/aid-document-guideline/) — Write a guideline NOW -- an advisory recommended practice (principle -> rationale -> do/don't examples) -- in one pass.
- [`aid-document-standard`](/skills/aid-document-standard/) — Write a standard NOW -- a mandatory rule (rule -> scope -> compliance/enforcement -> exceptions) -- in one pass.
- [`aid-document-runbook`](/skills/aid-document-runbook/) — Write a runbook NOW -- an operational procedure (trigger -> diagnostic -> remediation -> escalation) -- in one pass.
- [`aid-document-tutorial`](/skills/aid-document-tutorial/) — Write a tutorial NOW -- a learning-oriented walkthrough (prerequisites -> worked steps -> outcome) -- in one pass.
- [`aid-document-changelog`](/skills/aid-document-changelog/) — Write a changelog NOW -- release notes grouped Added / Changed / Fixed / Removed / Security -- in one pass.

### `report`

- [`aid-report`](/skills/aid-report/) — Analyze data or usage NOW -- EDA, metrics, or an A/B result -- and return a curated, verified insight report in one pass.

### `review`

- [`aid-review`](/skills/aid-review/) — Review/assess an existing artifact -- code, a change/diff, a design, a PR, a ticket, a document, a UI, whatever the request names -- against criteria, and…
- [`aid-audit`](/skills/aid-audit/) — Alias of /aid-review -- review/assess an existing artifact (code, a change/diff, a design, a PR, a ticket, a document, a UI, ...) against criteria and return…

### `research`

- [`aid-research`](/skills/aid-research/) — Investigate an open technical question NOW -- evaluate options, or (only with your explicit authorization) run an isolated feasibility spike -- and return a…
- [`aid-investigate`](/skills/aid-investigate/) — Alias of /aid-research -- investigate an open technical question NOW and return a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-,…
- [`aid-spike`](/skills/aid-spike/) — Alias of /aid-research -- investigate an open technical question NOW and return a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-,…

### `deploy`

- [`aid-deploy`](/skills/aid-deploy/) — Package completed deliveries into a release.

### `monitor`

- [`aid-monitor`](/skills/aid-monitor/) — Observe production, classify findings, and route actions.

## Execution

Skills for executing tasks and monitoring or deploying the results.

- [`aid-execute`](/skills/aid-execute/) — Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE.
