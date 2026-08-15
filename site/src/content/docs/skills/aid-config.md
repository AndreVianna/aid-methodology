---
title: 'aid-config'
description: 'View or update AID pipeline settings.'
generatedFrom: 'canonical/skills/aid-config/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-config/SKILL.md -->

## Frontmatter

- **`name`** — aid-config
- **`description`** — View or update AID pipeline settings. Use this skill when you need to see how the pipeline is configured, or change one setting such as the project name, its type, or the minimum grade. A bare invocation prints every value in a table and, on the first run, creates `.aid/settings.yml` from the template. Passing a key -- `/aid-config` name -- views and updates that one setting interactively.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
- **`argument-hint`** — (none) view all  |  &lt;key> view+update one (e.g., name, minimum_grade)

[Definition: `canonical/skills/aid-config/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md)

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
  n1(["MODE-1<br/>Mode 1 — Show all settings (/aid-config)"])
  n2["STEP-1<br/>Ensure .aid/settings.yml exists"]
  n3["STEP-2<br/>Render the table"]
  n4(["STEP-3<br/>Suggest commands for unset values + the general update form"])
  n5(["MODE-2<br/>Mode 2 — View/update one key (/aid-config &lt;key&gt;)"])
  n6["STEP-1<br/>Validate the key argument"]
  n7["STEP-2<br/>Ensure .aid/settings.yml exists"]
  n8["STEP-3<br/>Read current value"]
  n9["STEP-4<br/>Prompt for new value"]
  n10["STEP-5<br/>Validate"]
  n11["STEP-6<br/>Save in place"]
  n12(["STEP-7<br/>Confirm"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n5 --> n6
  n6 --> n7
  n7 --> n8
  n8 --> n9
  n9 --> n10
  n10 --> n11
  n11 --> n12
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidExit
  class n5 aidEntry
  class n6 aidStep
  class n7 aidStep
  class n8 aidStep
  class n9 aidStep
  class n10 aidStep
  class n11 aidStep
  class n12 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
  class n10 aidNode
  class n11 aidNode
  class n12 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `MODE-1`** — Mode 1 — Show all settings (/aid-config) · _entry_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L37" wrap
## Mode 1 — Show all settings (`/aid-config`)
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L37`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L37)

<a id="fragment-n2"></a>**2 · `STEP-1`** — Ensure .aid/settings.yml exists · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L39" wrap
### Step 1: Ensure `.aid/settings.yml` exists
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L39)

<a id="fragment-n3"></a>**3 · `STEP-2`** — Render the table · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L46" wrap
### Step 2: Render the table
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L46`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L46)

<a id="fragment-n4"></a>**4 · `STEP-3`** — Suggest commands for unset values + the general update form · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L55" wrap
### Step 3: Suggest commands for unset values + the general update form
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L55`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L55)

<a id="fragment-n5"></a>**5 · `MODE-2`** — Mode 2 — View/update one key (/aid-config &lt;key>) · _entry_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L74" wrap
## Mode 2 — View/update one key (`/aid-config <key>`)
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L74)

<a id="fragment-n6"></a>**6 · `STEP-1`** — Validate the key argument · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L76" wrap
### Step 1: Validate the key argument
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L76)

<a id="fragment-n7"></a>**7 · `STEP-2`** — Ensure .aid/settings.yml exists · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L88" wrap
### Step 2: Ensure `.aid/settings.yml` exists
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L88`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L88)

<a id="fragment-n8"></a>**8 · `STEP-3`** — Read current value · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L92" wrap
### Step 3: Read current value
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L92)

<a id="fragment-n9"></a>**9 · `STEP-4`** — Prompt for new value · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L101" wrap
### Step 4: Prompt for new value
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L101`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L101)

<a id="fragment-n10"></a>**10 · `STEP-5`** — Validate · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L119" wrap
### Step 5: Validate
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L119`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L119)

<a id="fragment-n11"></a>**11 · `STEP-6`** — Save in place · _step_

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L123" wrap
### Step 6: Save in place
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L123`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L123)

<a id="fragment-n12"></a>**12 · `STEP-7`** — Confirm · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-config/SKILL.md#L132" wrap
### Step 7: Confirm
~~~~

[Source: `canonical/skills/aid-config/SKILL.md#L132`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md#L132)
