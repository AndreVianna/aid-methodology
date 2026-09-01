---
title: 'aid-set-connector'
description: 'Add or update one entry in the connector catalog.'
generatedFrom: 'canonical/skills/aid-set-connector/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-set-connector/SKILL.md -->

## Frontmatter

- **`name`** — aid-set-connector
- **`description`** — Add or update one entry in the connector catalog. Use this skill when a project gains a new external tool, or an existing connector's configuration changes, and you do not want to re-run discovery for it. Naming a tool and a type creates its descriptor when absent, or updates that same descriptor in place when present, including a change of connection type. It asks the question set matching the type (mcp, api, ssh or cli), prefilled from the preset catalog when the tool is a known preset, and you confirm or edit. It reconciles that connector's secret and touches only that one stem: every other catalogued connector is left byte-for-byte untouched. It never invokes `/aid-discover`.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
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

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L42" wrap
### Step 0: Validate arguments
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L42`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L42)

<a id="fragment-n2"></a>**2 · `STEP-1`** — Resolve &lt;tool> → descriptor stem; read the preset catalog · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L68" wrap
## Step 1: Resolve `<tool>` → descriptor stem; read the preset catalog
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L68`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L68)

<a id="fragment-n3"></a>**3 · `STEP-2`** — Branch on &lt;type> — ask the config question-set · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L93" wrap
## Step 2: Branch on `<type>` — ask the config question-set
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L93)

<a id="fragment-n4"></a>**4 · `STEP-3`** — Classify — ADD vs UPDATE (single stem only) · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L114" wrap
## Step 3: Classify — ADD vs UPDATE (single stem only)
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L114`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L114)

<a id="fragment-n5"></a>**5 · `STEP-4`** — Ensure the .secrets/ gitignore precondition — BEFORE any… · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L136" wrap
## Step 4: Ensure the `.secrets/` gitignore precondition — BEFORE any write under `.aid/connectors/`
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L136)

<a id="fragment-n6"></a>**6 · `STEP-5`** — Author the descriptor + reconcile the secret (set-skill… · _step_

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L158" wrap
## Step 5: Author the descriptor + reconcile the secret (set-skill logic)
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L158`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L158)

<a id="fragment-n7"></a>**7 · `STEP-6`** — Single-stem reconcile → rebuild INDEX.md · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-set-connector/SKILL.md#L202" wrap
## Step 6: Single-stem reconcile → rebuild `INDEX.md`
~~~~

[Source: `canonical/skills/aid-set-connector/SKILL.md#L202`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md#L202)
