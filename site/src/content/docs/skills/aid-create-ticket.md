---
title: 'aid-create-ticket'
description: 'File one new ticket in the project''s issue tracker.'
generatedFrom: 'canonical/skills/aid-create-ticket/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-ticket/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-ticket
- **`description`** — File one new ticket in the project's issue tracker. Use this skill when work needs recording where the team tracks it, rather than only inside AID. Describe the ticket in free text; flags let you name the connector, the level (epic, story or task) and a parent. It resolves which tracker to use, composes the payload, maps the level to that tracker's own issue type, and shows you the exact payload before anything is filed. One confirmation gates the write, and carries the level choice when you did not give one. It returns the new ticket's id only after you confirm; nothing is filed, and no local file is written, before that.
- **`allowed-tools`** — Read Glob Grep AskUserQuestion
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
  n2(["RESOLVE-CONNECTOR"])
  n3["PICK-CONNECTOR"]
  n4(["COMPOSE"])
  n5["LEVEL-RESOLVE"]
  n6(["CONFIRM"])
  n7["FILE"]
  n8(["RETURN-REF"])
  n1 -->|"when the arguments parse"| n2
  n2 -->|"when several connectors match"| n3
  n2 -->|"when the connector resolves silently"| n4
  n3 -. "otherwise" .- n3
  n3 -->|"once the user has picked the connector"| n4
  n4 --> n5
  n5 --> n6
  n6 -. "on [2] Edit , with the user's requested change folded into the payload" .-> n4
  n6 -->|"once the user has chosen [1] File it"| n7
  n7 --> n8
  class n1 aidExit
  class n2 aidExit
  class n3 aidLoopBack
  class n4 aidExit
  class n5 aidStep
  class n6 aidExit
  class n7 aidStep
  class n8 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PARSE-ARGS`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L69" wrap
### State 1 — PARSE-ARGS
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L69)

<a id="fragment-n2"></a>**2 · `RESOLVE-CONNECTOR`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L104" wrap
### State 2 — RESOLVE-CONNECTOR
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L104`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L104)

<a id="fragment-n3"></a>**3 · `PICK-CONNECTOR`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L120" wrap
### State 2a — PICK-CONNECTOR
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L120`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L120)

<a id="fragment-n4"></a>**4 · `COMPOSE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L131" wrap
### State 3 — COMPOSE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L131`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L131)

<a id="fragment-n5"></a>**5 · `LEVEL-RESOLVE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L159" wrap
### State 4 — LEVEL-RESOLVE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L159)

<a id="fragment-n6"></a>**6 · `CONFIRM`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L185" wrap
### State 5 — CONFIRM
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L185`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L185)

<a id="fragment-n7"></a>**7 · `FILE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L215" wrap
### State 6 — FILE
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L215`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L215)

<a id="fragment-n8"></a>**8 · `RETURN-REF`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-ticket/SKILL.md#L232" wrap
### State 7 — RETURN-REF
~~~~

[Source: `canonical/skills/aid-create-ticket/SKILL.md#L232`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md#L232)
