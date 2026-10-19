---
title: 'aid-create-roadmap'
description: 'Realize a ready roadmap seed into `.aid/knowledge/roadmap.md` -- frontmatter, preamble, ## Contents index (including the forward ## MVP entry), and the three…'
generatedFrom: 'canonical/skills/aid-create-roadmap/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-roadmap/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-roadmap
- **`description`** — Realize a ready roadmap seed into `.aid/knowledge/roadmap.md` -- frontmatter, preamble, ## Contents index (including the forward ## MVP entry), and the three horizon sections ## Now, ## Next, ## Later. Use this skill when a roadmap seed is ready and the project needs its roadmap document written for the first time. Registers the document in `.aid/settings.yml` and `.aid/knowledge/README.md` on first creation. Routes to `/aid-update-roadmap` when the horizon sections already carry committed content. The ## MVP section belongs entirely to `/aid-create-mvp` -- this skill writes only its ## Contents index entry.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- what to realize (fills horizon sections from the seed)

[Definition: `canonical/skills/aid-create-roadmap/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md)

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
  n2(["GUARD"])
  n3(["REALIZE"])
  n4["REGISTER"]
  n5["VERIFY"]
  n6["PRESENT<br/>hard stop -- the user decides"]
  n7(["DONE"])
  n1 --> n2
  n2 -->|"when no question is unresolved"| n3
  n3 -->|"creation or fill path"| n4
  n4 --> n5
  n5 -.-> n3
  n5 --> n6
  n6 --> n7
  class n1 aidEntry
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidLoopBack
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L50-L61" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What direction
   do you want to realize into roadmap.md -- or run `/aid-design-roadmap` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-create-roadmap`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Read the seed** at `.aid/design/roadmap.md`. If no seed exists, inform the user and
   ask whether to proceed without one (direction entered interactively) or to run
   `/aid-design-roadmap` first; do not proceed silently. The question blocks the work: pause INTAKE on it, with its detail saying the work is allocated and the question is open, record it with `--ask`, set the lifecycle to `Paused-Awaiting-Input`, and then ask it. Once it is answered, INTAKE continues at step 4.
4. **Read the destination** at `.aid/knowledge/roadmap.md` if it exists. Classify its state:
   absent | present-horizon-empty | present-horizon-populated.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L50-L61`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L50-L61) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L50-L63`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L50-L63)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L67-L70" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a non-empty
`## Open questions` section per `design-lifecycle.md`'s detection rule.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L67-L70`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L67-L70) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L67-L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L67-L77)

<a id="fragment-n3"></a>**3 · `REALIZE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L81-L84" wrap
## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the case
determined in INTAKE:
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L81-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L81-L84) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L81-L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L81-L136)

<a id="fragment-n4"></a>**4 · `REGISTER`** · _step_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L140-L143" wrap
## State: REGISTER

**On creation only** (destination was absent in INTAKE). Write two surfaces atomically
in the same run, per `feature-003 §6b` (REQUIREMENTS CC-1, CC-2):
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L140-L143`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L140-L143) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L140-L155`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L140-L155)

<a id="fragment-n5"></a>**5 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L159-L163" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L159-L163`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L159-L163) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L159-L165`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L159-L165)

<a id="fragment-n6"></a>**6 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L169-L171" wrap
## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the realized document clearly. Assert:
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L169-L171`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L169-L171) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L169-L178`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L169-L178)

<a id="fragment-n7"></a>**7 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L182-L184" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer, `updated` now, append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L182-L184`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L182-L184) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L182-L184`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L182-L184)
