---
title: 'aid-create-ticket'
description: 'File one new ticket in the project''s issue tracker.'
generatedFrom: 'canonical/skills/aid-create-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-ticket
- **`description`** — File one new ticket in the project's issue tracker. Use this skill when work needs recording where the team tracks it, rather than only inside AID. Describe the ticket in free text; flags let you name the connector, the level (epic, story or task) and a parent. It resolves which tracker to use, composes the payload, maps the level to that tracker's own issue type, and shows you the exact payload before anything is filed. One confirmation gates the write, and carries the level choice when you did not give one. It returns the new ticket's id only after you confirm; nothing is filed, and no local file is written, before that.
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
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PARSE-ARGS`** · _entry_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L70" wrap
### State 1 — PARSE-ARGS
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L70`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L70)

<a id="fragment-n2"></a>**2 · `RESOLVE-CONNECTOR`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L105" wrap
### State 2 — RESOLVE-CONNECTOR
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L105`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L105)

<a id="fragment-n3"></a>**3 · `COMPOSE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L127" wrap
### State 3 — COMPOSE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L127`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L127)

<a id="fragment-n4"></a>**4 · `LEVEL-RESOLVE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L145" wrap
### State 4 — LEVEL-RESOLVE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L145`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L145)

<a id="fragment-n5"></a>**5 · `CONFIRM`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L171" wrap
### State 5 — CONFIRM
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L171`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L171)

<a id="fragment-n6"></a>**6 · `FILE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L201" wrap
### State 6 — FILE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L201`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L201)

<a id="fragment-n7"></a>**7 · `RETURN-REF`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L219" wrap
### State 7 — RETURN-REF
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L219`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L219)
