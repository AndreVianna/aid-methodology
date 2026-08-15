---
title: 'aid-ask'
description: 'Answer a question about this project, with citations.'
generatedFrom: 'canonical/skills/aid-ask/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-ask/SKILL.md -->

## Frontmatter

- **`name`** — aid-ask
- **`description`** — Answer a question about this project, with citations. Use this skill when you want to know something -- how a part of the system works, what a document says, where a piece of work stands -- and you want a grounded answer rather than a guess. It reads three sources: the Knowledge Base, the live codebase, and any AID work currently in flight, and cites whichever it used, by document name, file path, or work reference. When those sources genuinely cannot answer, it says so instead of inventing an answer, and records the gap so it feeds back into improving the Knowledge Base. Trivial questions are answered inline; broad investigations are dispatched read-only. The only thing it ever writes is that recorded gap.
- **`allowed-tools`** — Read, Glob, Grep, Agent, Write, Edit
- **`argument-hint`** — &lt;question>  — a free-form question about the project

[Definition: `canonical/skills/aid-ask/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md)

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
  n1(["STEP-1<br/>Classify the question"])
  n2["STEP-2A<br/>Trivial question: answer inline"]
  n3["STEP-2B<br/>Broad/expensive question: dispatch aid-researcher"]
  n4["STEP-2C<br/>Connector enrichment (optional)"]
  n5["STEP-3<br/>Compose and emit the reply"]
  n6(["STEP-4<br/>Gap capture"])
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

<a id="fragment-n1"></a>**1 · `STEP-1`** — Classify the question · _entry_

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L51" wrap
### Step 1 — Classify the question
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L51)

<a id="fragment-n2"></a>**2 · `STEP-2A`** — Trivial question: answer inline · _step_

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L63" wrap
### Step 2a — Trivial question: answer inline
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L63`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L63)

<a id="fragment-n3"></a>**3 · `STEP-2B`** — Broad/expensive question: dispatch aid-researcher · _step_

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L77" wrap
### Step 2b — Broad/expensive question: dispatch aid-researcher
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L77)

<a id="fragment-n4"></a>**4 · `STEP-2C`** — Connector enrichment (optional) · _step_

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L102" wrap
### Step 2c — Connector enrichment (optional)
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L102)

<a id="fragment-n5"></a>**5 · `STEP-3`** — Compose and emit the reply · _step_

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L112" wrap
### Step 3 — Compose and emit the reply
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L112)

<a id="fragment-n6"></a>**6 · `STEP-4`** — Gap capture · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-ask/SKILL.md#L159" wrap
### Step 4 -- Gap capture
~~~~

[Source: `canonical/skills/aid-ask/SKILL.md#L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md#L159)
