---
title: 'aid-design-testing-strategy'
description: 'Develop the testing policy as a DESIGN SEED in `.aid/design/testing-strategy.md` -- test levels, coverage expectations, which gates block a merge, and who…'
generatedFrom: 'canonical/skills/aid-design-testing-strategy/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-testing-strategy/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-testing-strategy
- **`description`** — Develop the testing policy as a DESIGN SEED in `.aid/design/testing-strategy.md` -- test levels, coverage expectations, which gates block a merge, and who may waive one. Use this skill when how the project should be tested is still being decided, rather than which tests to write. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document and NO test code -- realize the seed into the project's C6 document(s) with `/aid-create-testing-strategy` once it is ready. To design a specific set of tests rather than the policy, use `/aid-design-test`; to RUN existing suites, use `/aid-test`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the testing policy to design (levels, coverage, merge-blocking gates, waivers)

[Definition: `canonical/skills/aid-design-testing-strategy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md)

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
  n1 --> n2
  n2 --> n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 --> n5
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
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

~~~~plaintext title="canonical/skills/aid-design-testing-strategy/SKILL.md#L40-L50" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What testing
   policy do you want to design -- its levels, coverage expectations, and merge-blocking
   gates?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-testing-strategy` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/testing-strategy.md`
   if a prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-testing-strategy/SKILL.md#L40-L50`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L40-L50) · [full step: `canonical/skills/aid-design-testing-strategy/SKILL.md#L40-L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L40-L56)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-testing-strategy/SKILL.md#L60-L66" wrap
## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/testing-strategy.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the test levels, coverage expectations,
which gates block a merge, and who may waive one**.
~~~~

[Source: `canonical/skills/aid-design-testing-strategy/SKILL.md#L60-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L60-L66) · [full step: `canonical/skills/aid-design-testing-strategy/SKILL.md#L60-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L60-L84)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-testing-strategy/SKILL.md#L88-L91" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-testing-strategy/SKILL.md#L88-L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L88-L91) · [full step: `canonical/skills/aid-design-testing-strategy/SKILL.md#L88-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L88-L93)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-design-testing-strategy/SKILL.md#L97-L101" wrap
## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now
(`/aid-create-testing-strategy`).
~~~~

[Source: `canonical/skills/aid-design-testing-strategy/SKILL.md#L97-L101`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L97-L101) · [full step: `canonical/skills/aid-design-testing-strategy/SKILL.md#L97-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L97-L103)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-testing-strategy/SKILL.md#L107-L111" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/testing-strategy.md`; consumption happens at
`/aid-create-testing-strategy`.
~~~~

[Source: `canonical/skills/aid-design-testing-strategy/SKILL.md#L107-L111`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L107-L111) · [full step: `canonical/skills/aid-design-testing-strategy/SKILL.md#L107-L111`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-testing-strategy/SKILL.md#L107-L111)
