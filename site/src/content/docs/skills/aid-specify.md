---
title: 'aid-specify'
description: 'Technical specification through conversational refinement, one feature at a time.'
generatedFrom: 'canonical/skills/aid-specify/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-specify/SKILL.md -->

## Frontmatter

- **`name`** — aid-specify
- **`description`** — Technical specification through conversational refinement, one feature at a time. The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes technical solutions, and builds the spec collaboratively with the user. Writes to SPEC.md in the feature folder. State machine: INITIALIZE → CONTINUE → REVIEW → DONE (SPIKE / BLOCKED are loopback states that return to CONTINUE).
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit
- **`argument-hint`** — work-001/feature-001 (required)  [--reset] clear technical spec for this feature

[Definition: `canonical/skills/aid-specify/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INITIALIZE<br/>First run for this feature; load context, determine…"])
  n2["CONTINUE<br/>Work STATE.md shows this feature ; find first or section in…"]
  n3(["SPIKE<br/>&gt; Source: §&quot;Spike Needed (State 3)&quot; (the body below is…"])
  n4(["BLOCKED<br/>&gt; Source: §&quot;Blocked (State 4)&quot; (the body below is preserved…"])
  n5["REVIEW<br/>All sections complete; re-review entire spec against…"]
  n6(["DONE<br/>Spec is Ready and has met the minimum grade; this feature's…"])
  n1 --> n2
  n2 -. "otherwise" .- n2
  n2 -->|"when all sections are Complete"| n5
  n3 --> n2
  n4 --> n2
  n5 -. "otherwise" .- n5
  n5 -->|"when spec is Ready and meets minimum grade"| n6
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidExit
  class n4 aidExit
  class n5 aidLoopBack
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
