---
title: 'aid-design-stack'
description: 'Develop the technology choice as a DESIGN SEED in `.aid/design/stack.md` -- languages, runtimes, frameworks, and build and test tooling with versions, plus…'
generatedFrom: 'canonical/skills/aid-design-stack/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-stack/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-stack
- **`description`** — Develop the technology choice as a DESIGN SEED in `.aid/design/stack.md` -- languages, runtimes, frameworks, and build and test tooling with versions, plus the alternatives rejected and why. Use this skill when which technologies to build on is still an open choice. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document and NO production code -- realize the seed into the project's C0 document with `/aid-create-stack` once it is ready. To design a configuration option within a stack rather than choose the stack, use `/aid-design-config`; for an open question with a researchable answer, use `/aid-research`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the technology stack to design (languages, runtimes, frameworks, tooling with versions)

[Definition: `canonical/skills/aid-design-stack/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md)

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
  n3(["VERIFY"])
  n4["PRESENT<br/>hard stop -- the user decides"]
  n5(["DONE"])
  n1 -->|"when the gate allocated a new work"| n2
  n2 --> n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 -. "when the user declines or asks for changes" .-> n2
  n4 -->|"when the user approves"| n5
  class n1 aidExit
  class n2 aidStep
  class n3 aidExit
  class n4 aidLoopBack
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-stack/SKILL.md#L42-L52" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What technology
   stack do you want to design -- its languages, runtimes, frameworks, and tooling?") and
   wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-stack` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/stack.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-stack/SKILL.md#L42-L52`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L42-L52) · [full step: `canonical/skills/aid-design-stack/SKILL.md#L42-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L42-L58)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-stack/SKILL.md#L62-L68" wrap
## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/stack.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the languages, runtimes, frameworks and
build/test tooling WITH VERSIONS, plus the alternatives rejected and why**.
~~~~

[Source: `canonical/skills/aid-design-stack/SKILL.md#L62-L68`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L62-L68) · [full step: `canonical/skills/aid-design-stack/SKILL.md#L62-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L62-L84)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-stack/SKILL.md#L88-L91" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-stack/SKILL.md#L88-L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L88-L91) · [full step: `canonical/skills/aid-design-stack/SKILL.md#L88-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L88-L93)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-stack/SKILL.md#L97-L100" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-stack`).
~~~~

[Source: `canonical/skills/aid-design-stack/SKILL.md#L97-L100`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L97-L100) · [full step: `canonical/skills/aid-design-stack/SKILL.md#L97-L105`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L97-L105)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-stack/SKILL.md#L109-L112" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/stack.md`; consumption happens at `/aid-create-stack`.
~~~~

[Source: `canonical/skills/aid-design-stack/SKILL.md#L109-L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L109-L112) · [full step: `canonical/skills/aid-design-stack/SKILL.md#L109-L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-stack/SKILL.md#L109-L112)
