---
title: 'aid-update-data-model'
description: 'Direct-entry Lite-path shortcut (Alias of aid-change-data-model.) -- skips the aid-describe interview/triage.'
generatedFrom: 'canonical/skills/aid-update-data-model/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-data-model/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-data-model
- **`description`** — Direct-entry Lite-path shortcut (Alias of aid-change-data-model.) -- skips the aid-describe interview/triage. Binds VERB=`change` ARTIFACT=`data-model` and runs the shared shortcut engine, producing a fully-graded flattened Lite work that halts for approval. State machine: delegated to canonical/aid/templates/shortcut-engine.md (INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT).
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [description]  -- what to change; runs straight to a graded flattened Lite work

[Definition: `canonical/skills/aid-update-data-model/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-data-model/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-update-data-model<br/>Bind VERB=change, ARTIFACT=data-model"])
  n2{"INTAKE"}
  n3(["CONTINUATION"])
  n4["CAPTURE<br/>Collapses Describe."]
  n5["SPEC<br/>Collapses Define + Specify."]
  n6["PLAN<br/>Collapses Plan."]
  n7["DETAIL<br/>Collapses Detail."]
  n8{"GATE"}
  n9(["Circuit breaker"])
  n10(["APPROVAL-HALT<br/>Terminal state (FR-10 / NFR-10)."])
  n1 --> n2
  n2 -->|"On continuation"| n3
  n2 -->|"On new work"| n4
  n4 --> n5
  n5 --> n6
  n6 --> n7
  n7 --> n8
  n8 --- n8
  n8 -->|"If the pass's grade has not improved across 3 consecutive cycles"| n9
  n8 --> n10
  class n1 aidEntry
  class n2 aidDecision
  class n3 aidExit
  class n4 aidStep
  class n5 aidStep
  class n6 aidStep
  class n7 aidStep
  class n8 aidDecision
  class n9 aidExit
  class n10 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
  class n10 aidNode
```
