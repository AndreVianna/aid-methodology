---
title: 'aid-read-ticket'
description: 'On-demand, non-destructive ticket read.'
generatedFrom: 'canonical/skills/aid-read-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-read-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-read-ticket
- **`description`** — On-demand, non-destructive ticket read. `aid-read-ticket [<connector>:]<ticket-id>` parses the ref (an optional `<stem>:` prefix plus the tracker's own id), resolves which issue-tracker connector answers it via the shared connector-resolution ladder (explicit override; a single catalogued issue-tracker connector used silently; a choice asked when two or more are catalogued; the host tool's own tracker MCP as fallback; a "no issue-tracker connector found." notice otherwise), fetches the ticket through the host tool's own MCP -- AID resolves no credential and stores none -- and displays its fields. Never writes, locally or to the tracker, and never shows a confirmation prompt; a failed, not-found, unauthorized, or unavailable fetch surfaces the tracker's error verbatim and exits without side effects.
- **`allowed-tools`** — Read, Glob, Grep, AskUserQuestion
- **`argument-hint`** — [&lt;connector>:]&lt;ticket-id>

[Definition: `canonical/skills/aid-read-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

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
  n1(["PARSE-ARGS"])
  n2["RESOLVE-CONNECTOR"]
  n3["FETCH"]
  n4(["DISPLAY"])
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
