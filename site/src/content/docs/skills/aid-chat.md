---
title: 'aid-chat'
description: 'Talk to another AI coding session.'
generatedFrom: 'canonical/skills/aid-chat/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-chat/SKILL.md -->

## Frontmatter

- **`name`** — aid-chat
- **`description`** — Talk to another AI coding session. Use this skill when you want to ask a peer agent something, answer one that has asked you, or work alongside one -- whether it runs in this same tool or a different one. It gives you a channel: you open one, pull a named agent into it, send and read messages, and acknowledge what you have read. Messages are durable while the channel is open, so a peer that restarts picks up where it left off, and one that is busy receives what it missed at its next turn. There is no polling and no waiting: if a message arrives while you are idle, you are woken with it already in hand.
- **`allowed-tools`** — Bash
- **`argument-hint`** — &lt;what you want to do>  -- e.g. 'ask the agent named api-work about the schema'

[Definition: `canonical/skills/aid-chat/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-chat/SKILL.md)

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
  n1(["ENTRY"])
  n2["RUN<br/>Run Talk to another AI coding session. Use this skill when…"]
  n3(["EXIT"])
  n1 --> n2
  n2 --> n3
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `ENTRY`** · _entry_

~~~~plaintext title="canonical/skills/aid-chat/SKILL.md#L1" wrap
---
~~~~

[Source: `canonical/skills/aid-chat/SKILL.md#L1`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-chat/SKILL.md#L1)

<a id="fragment-n2"></a>**2 · `RUN`** — Run Talk to another AI coding session. Use this skill when… · _step_

~~~~plaintext title="canonical/skills/aid-chat/SKILL.md#L3" wrap
description: >
~~~~

[Source: `canonical/skills/aid-chat/SKILL.md#L3`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-chat/SKILL.md#L3)

<a id="fragment-n3"></a>**3 · `EXIT`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-chat/SKILL.md#L13" wrap
---
~~~~

[Source: `canonical/skills/aid-chat/SKILL.md#L13`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-chat/SKILL.md#L13)
