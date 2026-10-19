---
title: 'aid-design-cicd'
description: 'Develop the delivery pipeline as a DESIGN SEED in `.aid/design/cicd.md` -- stages, triggers, environments, promotion, and release flow.'
generatedFrom: 'canonical/skills/aid-design-cicd/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-cicd/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-cicd
- **`description`** — Develop the delivery pipeline as a DESIGN SEED in `.aid/design/cicd.md` -- stages, triggers, environments, promotion, and release flow. Use this skill when how the project should be built, gated and shipped is still being worked out. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document, NO production code, and NO workflow file -- realize the seed into the project's C8 document with `/aid-create-cicd` once it is ready. To design a resource the pipeline ships to, use `/aid-design-infra`; to design a data pipeline rather than a delivery one, use `/aid-design-data-pipeline`; to ship a built artifact now, use `/aid-deploy`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the delivery pipeline to design (stages, triggers, environments, promotion)

[Definition: `canonical/skills/aid-design-cicd/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-design-cicd/SKILL.md#L41-L51" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What delivery
   pipeline do you want to design -- its stages, triggers, environments, and promotion
   flow?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-cicd` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/cicd.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-cicd/SKILL.md#L41-L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L41-L51) · [full step: `canonical/skills/aid-design-cicd/SKILL.md#L41-L57`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L41-L57)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-cicd/SKILL.md#L61-L67" wrap
## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/cicd.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the pipeline stages, triggers,
environments, and promotion and release flow**.
~~~~

[Source: `canonical/skills/aid-design-cicd/SKILL.md#L61-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L61-L67) · [full step: `canonical/skills/aid-design-cicd/SKILL.md#L61-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L61-L83)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-cicd/SKILL.md#L87-L90" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-cicd/SKILL.md#L87-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L87-L90) · [full step: `canonical/skills/aid-design-cicd/SKILL.md#L87-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L87-L92)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-design-cicd/SKILL.md#L96-L99" wrap
## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-cicd`).
~~~~

[Source: `canonical/skills/aid-design-cicd/SKILL.md#L96-L99`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L96-L99) · [full step: `canonical/skills/aid-design-cicd/SKILL.md#L96-L101`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L96-L101)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-cicd/SKILL.md#L105-L108" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/cicd.md`; consumption happens at `/aid-create-cicd`.
~~~~

[Source: `canonical/skills/aid-design-cicd/SKILL.md#L105-L108`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L105-L108) · [full step: `canonical/skills/aid-design-cicd/SKILL.md#L105-L108`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-cicd/SKILL.md#L105-L108)
