---
title: 'aid-unset-connector'
description: 'Remove one entry from the connector catalog.'
generatedFrom: 'canonical/skills/aid-unset-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-unset-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-unset-connector
- **`description`** — Remove one entry from the connector catalog. Use this skill when a project stops using an external tool and its descriptor and stored secret should go with it. Naming the tool deletes its descriptor, purges its secret, and rebuilds the catalog index from whatever remains on disk -- touching only that one stem, so every other catalogued connector is left byte-for-byte untouched. Idempotent: removing an already-absent tool is a clean no- op. It never invokes `/aid-discover`.
- **`allowed-tools`** — Read, Bash
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

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L39" wrap
### Step 0: Validate arguments
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L39)

<a id="fragment-n2"></a>**2 · `STEP-1`** — Resolve &lt;tool> → descriptor stem · _step_

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L58" wrap
## Step 1: Resolve `<tool>` → descriptor stem
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L58)

<a id="fragment-n3"></a>**3 · `STEP-2`** — Single-stem REMOVE (reconcile.md) · _step_

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L72" wrap
## Step 2: Single-stem REMOVE (`reconcile.md`)
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L72)

<a id="fragment-n4"></a>**4 · `STEP-3`** — Rebuild INDEX.md · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-unset-connector/SKILL.md#L102" wrap
## Step 3: Rebuild `INDEX.md`
~~~~

[Source: `canonical/skills/aid-unset-connector/SKILL.md#L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md#L102)
