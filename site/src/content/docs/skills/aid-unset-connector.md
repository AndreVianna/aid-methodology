---
title: 'aid-unset-connector'
description: 'On-demand, off-pipeline removal from the connector catalog.'
generatedFrom: 'canonical/skills/aid-unset-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-unset-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-unset-connector
- **`description`** — On-demand, off-pipeline removal from the connector catalog. `aid-unset-connector <tool>` deletes `.aid/connectors/<stem>.md` and purges its secret via connector-secret purge -- never invokes /aid-discover. Runs reconcile.md's single-stem REMOVE (purge-then-delete) so every OTHER catalogued connector is left byte-for-byte untouched, then rebuilds INDEX.md from whatever descriptors remain on disk. Idempotent: an already-absent stem is a clean no-op.
- **`allowed-tools`** — Read, Bash
- **`argument-hint`** — &lt;tool>  -- e.g. aid-unset-connector Jira

[Definition: `canonical/skills/aid-unset-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
flowchart TB
  classDef aidNode color:inherit
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["STEP-0<br/>Validate arguments"])
  n2["STEP-1<br/>Resolve  &lt;tool&gt;  → descriptor stem"]
  n3["STEP-2<br/>Single-stem REMOVE ( reconcile.md )"]
  n4(["STEP-3<br/>Rebuild  INDEX.md "])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
