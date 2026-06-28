---
title: 'Settings Keys'
description: 'All .aid/settings.yml keys — path, default/current value, and description.'
generatedFrom: '.aid/settings.yml'
---

<!-- generated — do not edit; source: .aid/settings.yml -->

`.aid/settings.yml` is the single source of truth for AID pipeline configuration — quality bar, parallelism, project identity, and more. Manage it with the `/aid-config` skill: a bare `/aid-config` prints every value; `/aid-config <dotted.key>` views and updates one key interactively. The keys below reflect this project's current `settings.yml`. Every skill with a review state reads `review.minimum_grade` and only exits when its grade clears that floor (per-skill overrides are allowed).

| Key Path | Value | Description |
|----------|-------|-------------|
| `format_version` | `1` |  |
| `project.name` | `AID` | set during /aid-config INIT |
| `project.description` | `AI Integrated Development` |  |
| `project.type` | `brownfield` | brownfield | greenfield |
| `tools.installed` | `claude-code` | Installed AI host tools |
| `review.minimum_grade` | `A+` | owner directive 2026-06-27: always use an A+ gate across all phases |
| `summary.minimum_grade` | `A+` |  |
| `execution.max_parallel_tasks` | `5` | parallel pool dispatch capacity (work-001 feature-009) |
| `traceability.heartbeat_interval` | `1` | minutes — interval at which long-running sub-agents update their heartbeat file |
| `discovery.closure.max_clean_passes` | `2` | CLOSED after this many consecutive zero-ungrounded DETECT passes (default 2) |
| `discovery.closure.max_rounds` | `4` | hard ceiling on EXPLAIN->DETECT->INVESTIGATE rounds (wall-clock guard) |
| `discovery.closure.token_budget` | `0` | optional alternative cap: 0 = use pass/round caps; >0 = stop when cumulative loop tokens exceed budget |
| `discovery.doc_set` | `project-structure.md|aid-researcher-scout|required, external-sources.md|aid-researcher-scout|required, architecture.md|aid-researcher-architecture|required, technology-stack.md|aid-researcher-architecture|required, module-map.md|aid-researcher-analyst|required, coding-standards.md|aid-researcher-analyst|required, authoring-conventions.md|aid-researcher-analyst|required, artifact-schemas.md|aid-researcher-analyst|required, pipeline-contracts.md|aid-researcher-integrator|required, integration-map.md|aid-researcher-integrator|required, domain-glossary.md|aid-researcher-integrator|required, test-landscape.md|aid-researcher-quality|required, quality-gates.md|aid-researcher-quality|required, tech-debt.md|aid-researcher-quality|required, infrastructure.md|aid-researcher-quality|required, release-tracking.md|skill-self|required, capability-inventory.md|skill-self|required, decisions.md|aid-researcher-architecture|required, README.md|skill-self|required` | Installed AI host tools |
| `triage.greenfield_max_source_files` | `5` | RM1 <= this AND RM2 <= loc => greenfield (little/no source) |
| `triage.greenfield_max_source_loc` | `500` | RM2 ceiling for greenfield |
| `triage.large_min_source_loc` | `20000` | RM2 >= this => brownfield-large (size) |
| `triage.large_min_dirs` | `25` | RM3 >= this => brownfield-large (breadth / fan-out) |
| `triage.large_min_concepts` | `40` | RM4 >= this => brownfield-large (concept density) |
| `kb_baseline.branch` | `master` |  |
| `kb_baseline.tip_date` | `2026-06-21T22:23:47-04:00` |  |
