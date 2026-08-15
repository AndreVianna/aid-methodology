---
title: 'aid-design-data-model'
description: 'Develop a data-model design as a DESIGN SEED in .aid/design/data-model.md -- its entities, their relationships, and the migration impact of introducing them.'
generatedFrom: 'canonical/skills/aid-design-data-model/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-data-model/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-data-model
- **`description`** — Develop a data-model design as a DESIGN SEED in .aid/design/data-model.md -- its entities, their relationships, and the migration impact of introducing them. Use this skill when an entity's shape and its relationships are still being worked out, before any migration is written. Grounded in the Knowledge Base (.aid/knowledge/) and the project source. It WRITES NO production code and NO KB document -- realize the seed into the built model and its migration with /aid-create-data-model once it is ready. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- the data model to design (entities, relationships, migration impact)

[Definition: `canonical/skills/aid-design-data-model/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE"])
  n2["DESIGN"]
  n3["VERIFY"]
  n4["PRESENT<br/>hard stop -- the user decides"]
  n5(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 --> n5
  class n1 aidEntry
  class n2 aidStep
  class n3 aidLoopBack
  class n4 aidStep
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-design-data-model/SKILL.md#L36-L46" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What data
   model do you want to design -- its entities, relationships, and migration impact?") and
   wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`canonical/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-data-model`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/data-model.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-data-model/SKILL.md#L36-L46`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L36-L46) · [full step: `canonical/skills/aid-design-data-model/SKILL.md#L36-L48`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L36-L48)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-data-model/SKILL.md#L52-L60" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/data-model.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **its entities, their relationships, and
the migration impact of introducing them**; its `## Destination` names where the built
model and its migration land. **Never writes `.aid/knowledge/` and never writes production
code** -- the `design` invariant (`design-lifecycle.md`).
~~~~

[Source: `canonical/skills/aid-design-data-model/SKILL.md#L52-L60`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L52-L60) · [full step: `canonical/skills/aid-design-data-model/SKILL.md#L52-L62`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L52-L62)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-data-model/SKILL.md#L66-L69" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-design-data-model/SKILL.md#L66-L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L66-L69) · [full step: `canonical/skills/aid-design-data-model/SKILL.md#L66-L71`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L66-L71)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-design-data-model/SKILL.md#L75-L78" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-data-model`).
~~~~

[Source: `canonical/skills/aid-design-data-model/SKILL.md#L75-L78`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L75-L78) · [full step: `canonical/skills/aid-design-data-model/SKILL.md#L75-L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L75-L80)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-data-model/SKILL.md#L84-L87" wrap
## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/data-model.md`; consumption happens at `/aid-create-data-model`.
~~~~

[Source: `canonical/skills/aid-design-data-model/SKILL.md#L84-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L84-L87) · [full step: `canonical/skills/aid-design-data-model/SKILL.md#L84-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-data-model/SKILL.md#L84-L87)
