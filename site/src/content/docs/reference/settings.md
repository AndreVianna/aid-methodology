---
title: 'Settings Keys'
description: 'All .aid/settings.yml keys — path, default/current value, and description.'
generatedFrom: '.aid/settings.yml'
---

<!-- generated — do not edit; source: .aid/settings.yml -->

`.aid/settings.yml` is the single source of truth for AID pipeline configuration — quality bar, parallelism, project identity, and more. Manage it with the `/aid-config` skill: a bare `/aid-config` prints every value; `/aid-config <dotted.key>` views and updates one key interactively. The keys below reflect this project's current `settings.yml`. Every skill with a review state reads `review.minimum_grade` and only exits when its grade clears that floor (per-skill overrides are allowed).

| Key Path | Value | Description |
|----------|-------|-------------|
| `format_version` | `3` |  |
| `name` | `AID` |  |
| `description` | `AI Integrated Development` |  |
| `type` | `brownfield` |  |
| `source_control` | `git` |  |
| `minimum_grade` | `A+` |  |
| `heartbeat_interval` | `1` |  |
| `knowledge.source` | `master` |  |
| `knowledge.last_update` | `2026-07-09T00:44:01-04:00` |  |
| `knowledge.doc_set` | `project-structure.md|aid-researcher-scout|required, external-sources.md|aid-researcher-scout|required, architecture.md|aid-researcher-architecture|required, technology-stack.md|aid-researcher-architecture|required, module-map.md|aid-researcher-analyst|required, coding-standards.md|aid-researcher-analyst|required, authoring-conventions.md|aid-researcher-analyst|required, artifact-schemas.md|aid-researcher-analyst|required, pipeline-contracts.md|aid-researcher-integrator|required, integration-map.md|aid-researcher-integrator|required, domain-glossary.md|aid-researcher-integrator|required, test-landscape.md|aid-researcher-quality|required, quality-gates.md|aid-researcher-quality|required, tech-debt.md|aid-researcher-quality|required, infrastructure.md|aid-researcher-quality|required, release-tracking.md|skill-self|required, capability-inventory.md|skill-self|required, decisions.md|aid-researcher-architecture|required, README.md|skill-self|required` | Installed AI host tools |
| `knowledge.term_exclusions` | `In Progress, User Approved, aid-execute, aid-specify, AndreVianna, GitHub, codex, TypeScript, RepoModel, Repo Info, WorkById, Work By Id, TargetDirectory, NoPath, No Profile, AidStatusBody, AidVersion, AidSupportedFormat, Aid Update Self If Stale, CardGrid, Card Grid, LifecycleBadge, Lifecycle Badge, VersionBadge, PipelineDiagram, RuleEntry, ExtrasConfig, Window Style, IsWindows, ProgramData, Script Analyzer, Claude Opus, File Not Found Error, task_id, work_id, PaymentEngine, PaymentHandler, Settlement Batch, ReconciliationCycle, FluxMatrix, SpineAnchor, SingleSource, Crunch Factor, State Detection, Single Source, File Hash, File System, echo, exit, grep, line, must, same, split, strip, none, home, docs, project, branch, target, title, summary, works, knowledge, node_modules, sha256, dry-run, a-z0-9, Change Log, Term, Term Name, Unique Term, Power Shell, Windows Power, Java Script, Program Data, File Sync, Hub Release, Hub Releases` | Installed AI host tools |
