---
title: 'aid-read-ticket'
description: 'Read one ticket from the project''s issue tracker and show its fields.'
generatedFrom: 'canonical/skills/aid-read-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-read-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-read-ticket
- **`description`** — Read one ticket from the project's issue tracker and show its fields. Use when a ticket is named and you need its current contents, as `aid-read-ticket [<connector>:]<ticket-id>`.
- **`allowed-tools`** — Read Glob Grep AskUserQuestion
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

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L62" wrap
### State 1 — PARSE-ARGS
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L62`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L62)

<a id="fragment-n2"></a>**2 · `RESOLVE-CONNECTOR`** · _step_

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L71" wrap
### State 2 — RESOLVE-CONNECTOR
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L71`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L71)

<a id="fragment-n3"></a>**3 · `FETCH`** · _step_

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L97" wrap
### State 3 — FETCH
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L97)

<a id="fragment-n4"></a>**4 · `DISPLAY`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-read-ticket/SKILL.md#L111" wrap
### State 4 — DISPLAY
~~~~

[Source: `canonical/skills/aid-read-ticket/SKILL.md#L111`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md#L111)
