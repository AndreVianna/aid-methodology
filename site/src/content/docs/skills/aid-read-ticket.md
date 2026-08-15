---
title: 'aid-read-ticket'
description: 'Read one ticket from the project''s issue tracker and show its fields.'
generatedFrom: 'canonical/skills/aid-read-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-read-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-read-ticket
- **`description`** — Read one ticket from the project's issue tracker and show its fields. Use this skill when you need a ticket's current contents -- during triage, before starting work, or while writing a change that references it. Give it a ticket id, optionally prefixed with a connector name when more than one tracker is catalogued. It resolves which tracker answers, fetches through your host tool's own MCP so AID never handles a credential, and displays the result. It never writes, locally or to the tracker, and never asks for confirmation; a failed, not-found, unauthorized or unavailable fetch surfaces the tracker's own error and exits without side effects.
- **`allowed-tools`** — Read, Glob, Grep, AskUserQuestion
- **`argument-hint`** — [&lt;connector>:]&lt;ticket-id>

[Definition: `canonical/skills/aid-read-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md)

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
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PARSE-ARGS`** · _entry_

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L67" wrap
### State 1 — PARSE-ARGS
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L67)

<a id="fragment-n2"></a>**2 · `RESOLVE-CONNECTOR`** · _step_

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L76" wrap
### State 2 — RESOLVE-CONNECTOR
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L76)

<a id="fragment-n3"></a>**3 · `FETCH`** · _step_

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L102" wrap
### State 3 — FETCH
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L102)

<a id="fragment-n4"></a>**4 · `DISPLAY`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L116" wrap
### State 4 — DISPLAY
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L116`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L116)
