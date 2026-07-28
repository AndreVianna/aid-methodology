---
title: 'aid-detail'
description: 'Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit.'
generatedFrom: 'canonical/skills/aid-detail/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-detail/SKILL.md -->

## Frontmatter

- **`name`** — aid-detail
- **`description`** — Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit. The ultimate breakdown. Detects task types (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) from SPEC signals. One type per task. Builds execution graph per delivery with explicit dependencies and parallelism. State machine: FIRST-RUN → REVIEW → DONE.
- **`allowed-tools`** — Read, Glob, Grep, Write, Edit, Bash
- **`argument-hint`** — work-001 (required if multiple works)  [--reset] clear deliveries/delivery-NNN/tasks/

[Definition: `canonical/skills/aid-detail/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["FIRST-RUN<br/>No task files exist yet."])
  n2["REVIEW<br/>Existing task files found; re-review against current…"]
  n3(["DONE"])
  n1 --> n2
  n2 --> n3
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
