---
title: 'All Skills'
description: 'Every AID skill, one card each, grouped by skill group and — inside Definition — by verb family.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
sidebar:
  hidden: true
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml -->

AID ships **37 skill directories** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), with the Definition group subdivided into **18 verb families** derived from the shortcut catalog. Each card below links to that skill’s detail page.

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

- [`aid-create`](/skills/aid-create/) — Create something new: code (API, UI, job, test...), a KB record or a document.

### `update`

- [`aid-update`](/skills/aid-update/) — Change something that exists: code (API, UI, job, test...), a KB record or a document.

### `refactor`

- [`aid-refactor`](/skills/aid-refactor/) — Restructure code without changing its behavior.

### `remove`

- [`aid-remove`](/skills/aid-remove/) — Remove code, a feature or a dependency and its uses.

### `deprecate`

- [`aid-deprecate`](/skills/aid-deprecate/) — Mark something deprecated, with a migration path.

### `migrate`

- [`aid-migrate`](/skills/aid-migrate/) — Migrate data, a dependency or a platform, with rollback.

### `test`

- [`aid-test`](/skills/aid-test/) — Run tests or checks (suites, security, performance, data quality) and report findings.

### `experiment`

- [`aid-experiment`](/skills/aid-experiment/) — Design, run, and analyze a controlled experiment or A/B test.

### `prototype`

- [`aid-prototype`](/skills/aid-prototype/) — Build a throwaway low-fidelity model, such as a UI, to test a direction.

### `design`

- [`aid-design`](/skills/aid-design/) — Design something as a kept seed: API, UI, data model, architecture, roadmap and more.

### `brainstorm`

- [`aid-brainstorm`](/skills/aid-brainstorm/) — Explore a fuzzy problem into a design seed in .aid/design.

### `document`

- [`aid-document`](/skills/aid-document/) — Write a document outside the KB: how-to, runbook, decision, tutorial, changelog and more.

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
