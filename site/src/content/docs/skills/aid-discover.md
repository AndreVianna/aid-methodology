---
title: 'aid-discover'
description: 'Brownfield project discovery with built-in quality gate.'
generatedFrom: 'canonical/skills/aid-discover/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-discover/SKILL.md -->

## Frontmatter

- **`name`** — aid-discover
- **`description`** — Brownfield project discovery with built-in quality gate. Run `/aid-config` first to scaffold the KB. Analyzes all repository content (code, configuration, and documentation) to populate KB documents. Reviews, collects user input, fixes issues, and gets user approval — one step per run. State-machine: ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart

[Definition: `canonical/skills/aid-discover/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md)

## Flow

```mermaid
---
config:
  layout: elk
  flowchart:
    nodeSpacing: 55
    rankSpacing: 65
    padding: 12
    useMaxWidth: true
---
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ELICIT<br/>ELICIT captures the project's external sources and tool…"])
  n2(["GENERATE<br/>GENERATE generates KB documents that are missing or still…"])
  n3{"REVIEW"}
  n4{"Q-AND-A"}
  n5{"FIX"}
  n6(["APPROVAL<br/>APPROVAL presents the KB summary and asks the user to…"])
  n7(["DONE<br/>DONE confirms discovery is complete and user-approved; it…"])
  n1 --> n2
  n2 --> n3
  n3 -->|"if Pending Q&amp;A entries with Impact: Required exist"| n4
  n3 -->|"otherwise"| n5
  n4 -->|"when any answer implies a doc change"| n5
  n4 -->|"otherwise chain once zero Pending and grade &gt;= minimum"| n6
  n5 -->|"if grade &lt; minimum"| n3
  n5 -->|"if grade ≥ minimum"| n6
  n6 -. "otherwise" .- n6
  n6 -->|"user approval is the natural pause — once user approves"| n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidDecision
  class n4 aidDecision
  class n5 aidDecision
  class n6 aidExit
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
