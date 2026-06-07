---
title: 'Settings Keys'
description: 'All .aid/settings.yml keys — path, default/current value, and description.'
generatedFrom: '.aid/settings.yml'
---

<!-- generated — do not edit; source: .aid/settings.yml -->

`.aid/settings.yml` is the single source of truth for AID pipeline configuration — quality bar, parallelism, project identity, and more. Manage it with the `/aid-config` skill: a bare `/aid-config` prints every value; `/aid-config <dotted.key>` views and updates one key interactively. The keys below reflect this project's current `settings.yml`. Every skill with a review state reads `review.minimum_grade` and only exits when its grade clears that floor (per-skill overrides are allowed).

| Key Path | Value | Description |
|----------|-------|-------------|
| `project.name` | `AID` | set during /aid-config INIT |
| `project.description` | `AI Integrated Development` |  |
| `project.type` | `brownfield` | brownfield | greenfield |
| `tools.installed` | `claude-code` | Installed AI host tools |
| `review.minimum_grade` | `A` |  |
| `execution.max_parallel_tasks` | `5` | parallel pool dispatch capacity (work-001 feature-009) |
| `traceability.heartbeat_interval` | `1` | minutes — interval at which long-running sub-agents update their heartbeat file |
