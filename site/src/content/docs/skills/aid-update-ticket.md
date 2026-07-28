---
title: 'aid-update-ticket'
description: 'On-demand write skill that mutates exactly ONE named part of an existing ticket in whatever issue-tracker connector resolves for it: `aid-update-ticket…'
generatedFrom: 'canonical/skills/aid-update-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-ticket
- **`description`** — On-demand write skill that mutates exactly ONE named part of an existing ticket in whatever issue-tracker connector resolves for it: `aid-update-ticket <part> [<connector>:]<ticket-id> <content>` where `part` is the closed enum `description | comment | status`. `description` REPLACES the field, `comment` APPENDS a new comment, `status` SETS the ticket's state. Resolves the connector via the shared ticket-resolution ladder, loads whatever context the named part needs (status: the ticket's available transitions; description: its current value for a before/after preview; comment: nothing), composes the exact mutation, and shows it in an in-invocation `AskUserQuestion` confirm before the single host-MCP write. A `status` target is validated against the tracker's available transitions when the MCP can enumerate them (a mismatch lists the valid options and stops before the confirm gate); when transitions cannot be enumerated, the transition is attempted and the tracker's own error is surfaced verbatim on rejection. Never writes silently, and an MCP failure never leaves a partial write.
- **`allowed-tools`** — Read, Glob, Grep, AskUserQuestion
- **`argument-hint`** — &lt;part> [&lt;connector>:]&lt;ticket-id> &lt;content>

[Definition: `canonical/skills/aid-update-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md)

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
  n1(["PARSE-ARGS"])
  n2["RESOLVE-CONNECTOR"]
  n3["LOAD-CONTEXT"]
  n4["COMPOSE"]
  n5["CONFIRM"]
  n6(["WRITE"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidStep
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
