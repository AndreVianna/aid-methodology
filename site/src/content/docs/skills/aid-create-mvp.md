---
title: 'aid-create-mvp'
description: 'Realize a ready MVP seed into roadmap.md''s ## MVP section only -- the first shippable slice: what it includes, why the line falls there, what was cut, and…'
generatedFrom: 'canonical/skills/aid-create-mvp/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-mvp/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-mvp
- **`description`** — Realize a ready MVP seed into roadmap.md's ## MVP section only -- the first shippable slice: what it includes, why the line falls there, what was cut, and its current status. Use this skill when an MVP seed is ready and the roadmap's MVP section has not been written yet. The roadmap document itself is `/aid-create-roadmap`'s to create; when roadmap.md is absent this skill routes to `/aid-create-roadmap` without writing anything and leaves the seed in place. Routes to `/aid-update-mvp` when ## MVP already carries committed content. Writes no document and no registration entry -- it owns a section, not a file.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;slice>] -- what to realize into the ## MVP section (fills the section from the seed)

[Definition: `canonical/skills/aid-create-mvp/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md)

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
  n4["VERIFY"]
  n5["PRESENT<br/>hard stop -- the user decides"]
  n6(["DONE"])
  n1 --> n2
  n2 -->|"when no question is unresolved"| n3
  n3 -->|"creation path"| n4
  n4 -.-> n3
  n4 --> n5
  n5 --> n6
  class n1 aidEntry
  class n2 aidExit
  class n3 aidExit
  class n4 aidLoopBack
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L55-L67" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   belongs in the first shippable slice, and where does the line fall -- or run
   `/aid-design-mvp` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-create-mvp`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Read the seed** at `.aid/design/mvp.md`. If no seed exists, inform the user and
   ask whether to proceed without one (slice entered interactively) or to run
   `/aid-design-mvp` first; do not proceed silently. The question blocks the work: pause INTAKE on it, with its detail saying the work is allocated and the question is open, record it with `--ask`, set the lifecycle to `Paused-Awaiting-Input`, and then ask it. Once it is answered, INTAKE continues at step 4.
4. **Read the destination** at `.aid/knowledge/roadmap.md` if it exists. Classify its
   state: absent | present-MVP-absent | present-MVP-populated.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L55-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L55-L67) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L55-L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L55-L69)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L73-L76" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a
non-empty `## Open questions` section per `design-lifecycle.md`'s detection rule.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L73-L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L73-L76) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L73-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L73-L83)

<a id="fragment-n3"></a>**3 · `REALIZE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L87-L90" wrap
## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the
case determined in INTAKE:
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L87-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L87-L90) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L87-L126`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L87-L126)

<a id="fragment-n4"></a>**4 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L130-L134" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L130-L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L130-L134) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L130-L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L130-L136)

<a id="fragment-n5"></a>**5 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L140-L143" wrap
## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the realized `## MVP` section clearly.
Assert:
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L140-L143`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L140-L143) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L140-L153`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L140-L153)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L157-L159" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer, `updated` now, append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L157-L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L157-L159) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L157-L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L157-L159)
