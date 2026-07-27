---
title: 'aid-triage'
description: 'Suggest-only router for "I don''t know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the…'
generatedFrom: 'canonical/skills/aid-triage/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-triage/SKILL.md -->

## Frontmatter

- **`name`** — aid-triage
- **`description`** — Suggest-only router for "I don't know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the single best entry: the matching aid-&lt;verb>[-&lt;artifact>] shortcut for a known single change-type, or the full path via /aid-describe for broad or ambiguous work. Reads canonical/aid/templates/shortcut-catalog.yml to resolve the suggestion to a canonical (non-alias) name. Routes and suggests only -- no interview, no scaffold, no work folder, no STATE.md. State machine: INTAKE -> CLASSIFY -> SUGGEST -> HALT.
- **`allowed-tools`** — Read, Glob, Grep
- **`argument-hint`** — [description]  -- what you want to do; I'll point you at the right entry

[Definition: `canonical/skills/aid-triage/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md)

<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->
