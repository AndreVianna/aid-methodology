---
title: 'aid-config'
description: 'View or update AID pipeline settings.'
generatedFrom: 'canonical/skills/aid-config/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-config/SKILL.md -->

## Frontmatter

- **`name`** — aid-config
- **`description`** — View or update AID pipeline settings. Bare invocation shows all values in a table; first run auto-creates .aid/settings.yml from the template. Pass a key (e.g., /aid-config name) to view + update one setting interactively.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
- **`argument-hint`** — (none) view all  |  &lt;key> view+update one (e.g., name, minimum_grade)

[Definition: `canonical/skills/aid-config/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md)

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
  n1(["MODE-1<br/>Mode 1 — Show all settings (…)"])
  n2["STEP-1<br/>Ensure  .aid/settings.yml  exists"]
  n3["STEP-2<br/>Render the table"]
  n4(["STEP-3<br/>Suggest commands for unset values + the general update form"])
  n5(["MODE-2<br/>Mode 2 — View/update one key (…)"])
  n6["STEP-1<br/>Validate the key argument"]
  n7["STEP-2<br/>Ensure  .aid/settings.yml  exists"]
  n8["STEP-3<br/>Read current value"]
  n9["STEP-4<br/>Prompt for new value"]
  n10["STEP-5<br/>Validate"]
  n11["STEP-6<br/>Save in place"]
  n12(["STEP-7<br/>Confirm"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n5 --> n6
  n6 --> n7
  n7 --> n8
  n8 --> n9
  n9 --> n10
  n10 --> n11
  n11 --> n12
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidExit
  class n5 aidEntry
  class n6 aidStep
  class n7 aidStep
  class n8 aidStep
  class n9 aidStep
  class n10 aidStep
  class n11 aidStep
  class n12 aidExit
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
  class n11 aidNode
  class n12 aidNode
```
