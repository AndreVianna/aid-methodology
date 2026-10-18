---
title: 'aid-set-connector'
description: 'Add or change a connector to a tracker or tool.'
generatedFrom: 'canonical/skills/aid-set-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-set-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-set-connector
- **`description`** — Add or change a connector to a tracker or tool. Use when you are connecting a tracker or tool to the project.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit AskUserQuestion
- **`argument-hint`** — &lt;tool> &lt;type> [--rotate-secret]  -- e.g. aid-set-connector Jira mcp   (type: mcp|api|ssh|cli)

[Definition: `canonical/skills/aid-set-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md)

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
  n2["STEP-1<br/>Resolve &lt;tool&gt; → descriptor stem; read the preset catalog"]
  n3["STEP-2<br/>Branch on &lt;type&gt; — ask the config question-set"]
  n4["STEP-3<br/>Classify — ADD vs UPDATE (single stem only)"]
  n5["STEP-4<br/>Ensure the .secrets/ gitignore precondition — BEFORE any…"]
  n6["STEP-5<br/>Author the descriptor + reconcile the secret (set-skill…"]
  n7(["STEP-6<br/>Single-stem reconcile → rebuild INDEX.md"])
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

<a id="fragment-n1"></a>**1 · `STEP-0`** — Validate arguments · _entry_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L36" wrap
### Step 0: Validate arguments
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L36`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L36)

<a id="fragment-n2"></a>**2 · `STEP-1`** — Resolve &lt;tool> → descriptor stem; read the preset catalog · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L62" wrap
## Step 1: Resolve `<tool>` → descriptor stem; read the preset catalog
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L62`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L62)

<a id="fragment-n3"></a>**3 · `STEP-2`** — Branch on &lt;type> — ask the config question-set · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L87" wrap
## Step 2: Branch on `<type>` — ask the config question-set
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L87)

<a id="fragment-n4"></a>**4 · `STEP-3`** — Classify — ADD vs UPDATE (single stem only) · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L108" wrap
## Step 3: Classify — ADD vs UPDATE (single stem only)
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L108`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L108)

<a id="fragment-n5"></a>**5 · `STEP-4`** — Ensure the .secrets/ gitignore precondition — BEFORE any… · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L130" wrap
## Step 4: Ensure the `.secrets/` gitignore precondition — BEFORE any write under `.aid/connectors/`
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L130`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L130)

<a id="fragment-n6"></a>**6 · `STEP-5`** — Author the descriptor + reconcile the secret (set-skill… · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L152" wrap
## Step 5: Author the descriptor + reconcile the secret (set-skill logic)
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L152`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L152)

<a id="fragment-n7"></a>**7 · `STEP-6`** — Single-stem reconcile → rebuild INDEX.md · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L196" wrap
## Step 6: Single-stem reconcile → rebuild `INDEX.md`
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L196`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L196)
