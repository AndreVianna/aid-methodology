---
title: 'aid-design-test'
description: 'Develop a test design as a DESIGN SEED in `.aid/design/test.md` -- the units under test, the cases, and the framework and fixtures.'
generatedFrom: 'canonical/skills/aid-design-test/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-test/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-test
- **`description`** — Develop a test design as a DESIGN SEED in `.aid/design/test.md` -- the units under test, the cases, and the framework and fixtures. Use this skill when what a test should actually assert is still being worked out. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO production code and NO KB document -- realize the seed into authored tests with `/aid-create-test` once it is ready. To design the testing policy rather than specific tests, use `/aid-design-testing-strategy`; to RUN existing suites rather than design them, use `/aid-test`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the tests to design (units under test, cases, framework/fixtures)

[Definition: `canonical/skills/aid-design-test/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-design-test/SKILL.md#L40-L49" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What tests do
   you want to design -- the units under test, the cases, and the framework?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-test` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/test.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-test/SKILL.md#L40-L49`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L40-L49) · [full step: `canonical/skills/aid-design-test/SKILL.md#L40-L55`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L40-L55)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-test/SKILL.md#L59-L67" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/test.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the units under test, the cases, and
the framework and fixtures**; its `## Destination` names where the authored tests land.
**Never writes `.aid/knowledge/` and never writes production code** -- the `design`
invariant (`design-lifecycle.md`).
~~~~

[Source: `canonical/skills/aid-design-test/SKILL.md#L59-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L59-L67) · [full step: `canonical/skills/aid-design-test/SKILL.md#L59-L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L59-L69)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-test/SKILL.md#L73-L76" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-test/SKILL.md#L73-L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L73-L76) · [full step: `canonical/skills/aid-design-test/SKILL.md#L73-L78`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L73-L78)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-test/SKILL.md#L82-L85" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-test`).
~~~~

[Source: `canonical/skills/aid-design-test/SKILL.md#L82-L85`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L82-L85) · [full step: `canonical/skills/aid-design-test/SKILL.md#L82-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L82-L90)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-test/SKILL.md#L94-L97" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/test.md`; consumption happens at `/aid-create-test`.
~~~~

[Source: `canonical/skills/aid-design-test/SKILL.md#L94-L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L94-L97) · [full step: `canonical/skills/aid-design-test/SKILL.md#L94-L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-test/SKILL.md#L94-L97)
