---
title: 'aid-design-mvp'
description: 'Draw the MVP line as a DESIGN SEED in `.aid/design/mvp.md` -- what is in the first shippable slice, what defers, and the reason for each cut.'
generatedFrom: 'canonical/skills/aid-design-mvp/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-mvp/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-mvp
- **`description`** — Draw the MVP line as a DESIGN SEED in `.aid/design/mvp.md` -- what is in the first shippable slice, what defers, and the reason for each cut. Use this skill when what the first shippable slice should contain is still an open question. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB DOCUMENT and NO production code -- realize the seed into roadmap.md's ## MVP section with `/aid-create-mvp` once it is ready. For direction beyond the first slice, use `/aid-design-roadmap` instead. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;slice> -- what belongs in the first shippable slice, and what to cut

[Definition: `canonical/skills/aid-design-mvp/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-design-mvp/SKILL.md#L41-L51" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   belongs in the first shippable slice, and what should defer?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-design-mvp`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/mvp.md` -- re-invocation
   iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
~~~~

[Source: `canonical/skills/aid-design-mvp/SKILL.md#L41-L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L41-L51) · [full step: `canonical/skills/aid-design-mvp/SKILL.md#L41-L57`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L41-L57)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-mvp/SKILL.md#L61-L66" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to develop or iterate the seed,
grounded in `.aid/knowledge/` and the project source, plus the seed read in INTAKE if one
exists. Draws out: **the line -- what is in the first shippable slice, what defers, and
the reason for each cut.**
~~~~

[Source: `canonical/skills/aid-design-mvp/SKILL.md#L61-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L61-L66) · [full step: `canonical/skills/aid-design-mvp/SKILL.md#L61-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L61-L73)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-mvp/SKILL.md#L77-L81" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-mvp/SKILL.md#L77-L81`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L77-L81) · [full step: `canonical/skills/aid-design-mvp/SKILL.md#L77-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L77-L83)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-mvp/SKILL.md#L87-L91" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (re-invoke this skill) or realize it now
(`/aid-create-mvp`).
~~~~

[Source: `canonical/skills/aid-design-mvp/SKILL.md#L87-L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L87-L91) · [full step: `canonical/skills/aid-design-mvp/SKILL.md#L87-L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L87-L96)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-mvp/SKILL.md#L100-L103" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
stays at `.aid/design/mvp.md` -- consumption happens at `/aid-create-mvp`, not here.
~~~~

[Source: `canonical/skills/aid-design-mvp/SKILL.md#L100-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L100-L103) · [full step: `canonical/skills/aid-design-mvp/SKILL.md#L100-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-mvp/SKILL.md#L100-L103)
