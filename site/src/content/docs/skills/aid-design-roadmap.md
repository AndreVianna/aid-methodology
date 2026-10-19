---
title: 'aid-design-roadmap'
description: 'Develop the project''s committed direction as a DESIGN SEED in `.aid/design/roadmap.md` -- what is committed vs.'
generatedFrom: 'canonical/skills/aid-design-roadmap/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-roadmap/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-roadmap
- **`description`** — Develop the project's committed direction as a DESIGN SEED in `.aid/design/roadmap.md` -- what is committed vs. merely wanted, the sequencing rationale, and the alternatives being rejected and why. Use this skill when the direction for the coming horizons is still being argued out, and you want it settled as a seed before it becomes the roadmap. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB DOCUMENT and NO production code -- realize the seed into roadmap.md with `/aid-create-roadmap` once it is ready. For drawing the MVP line as its own act, use `/aid-design-mvp` instead. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;direction> -- what to develop (committed vs. wanted, sequencing, rejected alternatives)

[Definition: `canonical/skills/aid-design-roadmap/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-design-roadmap/SKILL.md#L41-L52" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   direction do you want to develop -- what's committed, what's merely wanted, and why?")
   and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-design-roadmap`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/roadmap.md` --
   re-invocation iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
~~~~

[Source: `canonical/skills/aid-design-roadmap/SKILL.md#L41-L52`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L41-L52) · [full step: `canonical/skills/aid-design-roadmap/SKILL.md#L41-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L41-L58)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-roadmap/SKILL.md#L62-L67" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to develop or iterate the seed,
grounded in `.aid/knowledge/` and the project source, plus the seed read in INTAKE if one
exists. Draws out: **direction and its *why*; what is committed vs. merely wanted;
sequencing rationale; the alternatives being rejected and why.**
~~~~

[Source: `canonical/skills/aid-design-roadmap/SKILL.md#L62-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L62-L67) · [full step: `canonical/skills/aid-design-roadmap/SKILL.md#L62-L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L62-L74)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-roadmap/SKILL.md#L78-L82" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-design-roadmap/SKILL.md#L78-L82`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L78-L82) · [full step: `canonical/skills/aid-design-roadmap/SKILL.md#L78-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L78-L84)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-roadmap/SKILL.md#L88-L92" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (re-invoke this skill) or realize it now
(`/aid-create-roadmap`).
~~~~

[Source: `canonical/skills/aid-design-roadmap/SKILL.md#L88-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L88-L92) · [full step: `canonical/skills/aid-design-roadmap/SKILL.md#L88-L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L88-L97)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-roadmap/SKILL.md#L101-L105" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
stays at `.aid/design/roadmap.md` -- consumption happens at `/aid-create-roadmap`, not
here.
~~~~

[Source: `canonical/skills/aid-design-roadmap/SKILL.md#L101-L105`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L101-L105) · [full step: `canonical/skills/aid-design-roadmap/SKILL.md#L101-L105`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-roadmap/SKILL.md#L101-L105)
