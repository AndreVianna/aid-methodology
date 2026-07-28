---
title: 'aid-create-ticket'
description: 'On-demand utility skill that files one new ticket via whatever issue-tracker connector the project has registered, or the host tool''s own tracker MCP when…'
generatedFrom: 'canonical/skills/aid-create-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-ticket
- **`description`** — On-demand utility skill that files one new ticket via whatever issue-tracker connector the project has registered, or the host tool's own tracker MCP when none is catalogued. Parses `--connector <stem>`, `--level epic|story|task`, and `--parent <ref>` flags in any order ahead of a free-text `<description>` (create has no leading-token connector heuristic), resolves the connector via the shared ladder, composes the new-ticket payload (fixing level and parent by precedence, defaulting neither silently), resolves the canonical tier to the tracker's concrete issue-type at runtime via a non-destructive read (graceful degradation when the tracker has no matching type), previews the exact payload, and gates on one in-run AskUserQuestion confirm -- which also carries the epic|story|task pick when the level is neither explicit nor inferable -- before filing. Returns the new `<connector-stem>:<external-id>` only after the user confirms; nothing is filed, and no local file is ever written, before that.
- **`allowed-tools`** — Read, Glob, Grep, AskUserQuestion
- **`argument-hint`** — [--connector &lt;stem>] [--level epic|story|task] [--parent &lt;ref>] &lt;description>

[Definition: `canonical/skills/aid-create-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md)

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
  n3["COMPOSE"]
  n4["LEVEL-RESOLVE"]
  n5["CONFIRM"]
  n6["FILE"]
  n7(["RETURN-REF"])
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
