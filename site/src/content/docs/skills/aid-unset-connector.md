---
title: 'aid-unset-connector'
description: 'Remove a connector to a tracker or tool.'
generatedFrom: 'canonical/skills/aid-unset-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-unset-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-unset-connector
- **`description`** — Remove a connector to a tracker or tool. Use when a connection is no longer wanted.
- **`allowed-tools`** — Read Bash Shell Terminal
- **`argument-hint`** — &lt;tool>  -- e.g. aid-unset-connector Jira

[Definition: `canonical/skills/aid-unset-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md)

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
  n1(["STEP-0<br/>Validate arguments"])
  n2["STEP-1<br/>Resolve &lt;tool&gt; → descriptor stem"]
  n3["STEP-2<br/>Single-stem REMOVE (reconcile.md)"]
  n4(["STEP-3<br/>Rebuild INDEX.md"])
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

<a id="fragment-n1"></a>**1 · `STEP-0`** — Validate arguments · _entry_

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L34" wrap
### Step 0: Validate arguments
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L34`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L34)

<a id="fragment-n2"></a>**2 · `STEP-1`** — Resolve &lt;tool> → descriptor stem · _step_

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L53" wrap
## Step 1: Resolve `<tool>` → descriptor stem
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L53)

<a id="fragment-n3"></a>**3 · `STEP-2`** — Single-stem REMOVE (reconcile.md) · _step_

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L67" wrap
## Step 2: Single-stem REMOVE (`reconcile.md`)
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L67)

<a id="fragment-n4"></a>**4 · `STEP-3`** — Rebuild INDEX.md · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L97" wrap
## Step 3: Rebuild `INDEX.md`
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L97)
