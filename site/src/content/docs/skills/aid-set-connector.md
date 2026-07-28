---
title: 'aid-set-connector'
description: 'On-demand, off-pipeline upsert into the connector catalog.'
generatedFrom: 'canonical/skills/aid-set-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-set-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-set-connector
- **`description`** — On-demand, off-pipeline upsert into the connector catalog. `aid-set-connector <tool> <type>` creates `.aid/connectors/<stem>.md` when the stem is absent, or updates that SAME descriptor in place when present (including an in-place connection_type transition) -- never invokes /aid-discover. Branches on &lt;type> (mcp|api|ssh|cli) to ask the matching config question-set, prefilled from canonical/aid/templates/connectors/preset-catalog.md when &lt;tool> matches a preset; the user confirms or edits. Reconciles the secret (connector-secret write/purge) per set-skill logic and runs reconcile.md's single-stem mode, so every OTHER catalogued connector is left byte-for-byte untouched.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
- **`argument-hint`** — &lt;tool> &lt;type> [--rotate-secret]  -- e.g. aid-set-connector Jira mcp   (type: mcp|api|ssh|cli)

[Definition: `canonical/skills/aid-set-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md)

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
  n1(["STEP-0<br/>Validate arguments"])
  n2["STEP-1<br/>Resolve  &lt;tool&gt;  → descriptor stem; read the preset catalog"]
  n3["STEP-2<br/>Branch on  &lt;type&gt;  — ask the config question-set"]
  n4["STEP-3<br/>Classify — ADD vs UPDATE (single stem only)"]
  n5["STEP-4<br/>Ensure the  .secrets/  gitignore precondition — BEFORE any…"]
  n6["STEP-5<br/>Author the descriptor + reconcile the secret (set-skill…"]
  n7(["STEP-6<br/>Single-stem reconcile → rebuild  INDEX.md "])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 --> n6
  n6 --> n7
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidStep
  class n6 aidStep
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
