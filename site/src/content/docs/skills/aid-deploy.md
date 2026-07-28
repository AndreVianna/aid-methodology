---
title: 'aid-deploy'
description: 'Package completed deliveries into a release.'
generatedFrom: 'canonical/skills/aid-deploy/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-deploy/SKILL.md -->

## Frontmatter

- **`name`** — aid-deploy
- **`description`** — Package completed deliveries into a release. Selects eligible deliveries, verifies the combined build, packages according to project infrastructure, generates release notes, and updates artifact statuses. Use when deliveries are complete and ready to ship. State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write

[Definition: `canonical/skills/aid-deploy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md)

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
  n1(["IDLE<br/>No active release; assess eligible deliveries and…"])
  n2["SELECTING<br/>Eligible deliveries are presented to the user for inclusion…"]
  n3["VERIFYING<br/>Full build, tests, and lint are run against the combined…"]
  n4["PACKAGING<br/>Release artifacts are produced, release notes generated, KB…"]
  n5(["DONE<br/>Release complete."])
  n6(["RE-RUN<br/>When work is Done and the user invokes again:"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 -. "otherwise" .- n4
  n4 -->|"see"| n5
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidLoopBack
  class n5 aidExit
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
