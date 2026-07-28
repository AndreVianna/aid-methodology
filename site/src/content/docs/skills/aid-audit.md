---
title: 'aid-audit'
description: 'Alias of /aid-review -- review/assess an existing artifact (code, a change/diff, a design, a PR, a ticket, a document, a UI, ...) against criteria and return…'
generatedFrom: 'canonical/skills/aid-audit/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-audit/SKILL.md -->

## Frontmatter

- **`name`** — aid-audit
- **`description`** — Alias of /aid-review -- review/assess an existing artifact (code, a change/diff, a design, a PR, a ticket, a document, a UI, ...) against criteria and return findings + recommendations NOW, in one pass. Single-shot, grounded in the Knowledge Base (.aid/knowledge/) and the project source, produced by the aid-reviewer agent in a clean context and independently verified; you approve before anything is published to an external target. This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-review/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)

[Definition: `canonical/skills/aid-audit/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-audit/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ENTRY"])
  n2["RUN<br/>Run Alias of /aid-review -- review/assess an existing…"]
  n3(["EXIT"])
  n1 --> n2
  n2 --> n3
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
