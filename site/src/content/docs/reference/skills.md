---
title: 'Shortcut engine'
description: 'How the verb-first direct-entry shortcut skills work — the shared shortcut engine they all delegate to, its INTAKE → APPROVAL-HALT sequence, and where to find the full skill roster.'
generatedFrom: 'canonical/aid/templates/shortcut-catalog.yml, canonical/aid/templates/shortcut-engine.md'
---

<!-- generated — do not edit; source: canonical/aid/templates/shortcut-catalog.yml, canonical/aid/templates/shortcut-engine.md -->

:::tip[Looking for the list of skills?]
The full roster — all **37** skills, one card each, grouped by skill group and verb family — lives at [**All skills**](/skills/). This page covers the shortcut engine those skills delegate to.
:::

## Direct-entry shortcuts

**34 engine-driven verb-first shortcuts** — a fast, mostly-autonomous alternative to the full Describe→Detail path for a single, well-scoped change. They enter through the 8 thin doorway skills generated from the non-`repurpose` family rows of [`canonical/aid/templates/shortcut-catalog.yml`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-catalog.yml) (`/aid-fix`, `/aid-create`, `/aid-update`, `/aid-refactor`, `/aid-remove`, `/aid-deprecate`, `/aid-migrate`, `/aid-experiment`); a doorway runs bare, or takes a kind as the first word of its argument (`/aid-create api`). (94 rows total: 19 family rows own a skill directory — the 8 doorways plus 11 hand-authored `repurpose: true` skills, among them the 3 classic re-registered skills (`aid-deploy`/`aid-monitor`/`aid-ask`); the other 75 are kind rows, routed by their family skill.)

Every engine-driven shortcut delegates to the shared **shortcut engine** — [`canonical/aid/templates/shortcut-engine.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md) — which collapses the five definition phases (Describe → Detail) into one mostly-autonomous run:

```
INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT
```

CAPTURE/SPEC/PLAN/DETAIL run without a per-phase human checkpoint (unlike the full path's Propose→Discuss→Write→Review loops); the only interactive moments are a rare CAPTURE gap-question and the terminal APPROVAL-HALT. GATE grades every generated document mechanically against the project's minimum grade before halting. The engine never executes — `/aid-execute` is a separate, user-initiated run after approval. Not sure which shortcut fits your change? `/aid-triage` reads this same catalog and suggests exactly one.
