---
title: 'aid-update-ticket'
description: 'Change one part of a ticket: description, comment or status.'
generatedFrom: 'canonical/skills/aid-update-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-ticket
- **`description`** — Change one part of a ticket: description, comment or status. Use to update a tracker ticket.
- **`allowed-tools`** — Read Glob Grep AskUserQuestion
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
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PARSE-ARGS`** · _entry_

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L54" wrap
### State 1 — PARSE-ARGS
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L54`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L54)

<a id="fragment-n2"></a>**2 · `RESOLVE-CONNECTOR`** · _step_

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L66" wrap
### State 2 — RESOLVE-CONNECTOR
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L66)

<a id="fragment-n3"></a>**3 · `LOAD-CONTEXT`** · _step_

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L76" wrap
### State 3 — LOAD-CONTEXT
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L76)

<a id="fragment-n4"></a>**4 · `COMPOSE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L95" wrap
### State 4 — COMPOSE
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L95`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L95)

<a id="fragment-n5"></a>**5 · `CONFIRM`** · _step_

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L119" wrap
### State 5 — CONFIRM
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L119`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L119)

<a id="fragment-n6"></a>**6 · `WRITE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-update-ticket/SKILL.md#L145" wrap
### State 6 — WRITE
~~~~

[Source: `canonical/skills/aid-update-ticket/SKILL.md#L145`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md#L145)
