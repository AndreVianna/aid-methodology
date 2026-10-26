---
title: 'aid-update-cicd'
description: 'Revise the CI/CD (shipping) KB document.'
generatedFrom: 'canonical/skills/aid-update-cicd/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-cicd/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-cicd
- **`description`** — Revise the CI/CD (shipping) KB document. Use when stages, triggers or environments changed.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;change> -- what to revise in the delivery-pipeline record

[Definition: `canonical/skills/aid-update-cicd/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md)

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
  n2["UPDATE"]
  n3["VERIFY"]
  n4(["PRESENT<br/>hard stop -- the user decides"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  class n1 aidEntry
  class n2 aidStep
  class n3 aidLoopBack
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-update-cicd/SKILL.md#L32-L53" wrap
## State: INTAKE

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What should
   change in the delivery-pipeline record?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-update-cicd`. `phase` is not driven.
3. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/cicd.md`, carrying its `## Current direction` into the destination and
   deleting it once realized.
4. **Resolve the destination by concern.** This skill binds concern **C8** (shipping &
   operation). Where a seed supplied a `## Destination`, use it; otherwise apply the concern
   rule here -- resolve C8 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the
   C8 row of `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the
   resolution with the user before writing**. Never resolve silently.
5. **Read the whole destination**, and note its `source:` field. Absent destination -> route to
   `/aid-create-cicd` and write nothing.
6. **Ask whether the user also wants production config this run.** Touching a workflow file is
   **opt-in per run and never the default**; the KB record is what this skill revises unless
   the user asks in this run.
7. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-update-cicd/SKILL.md#L32-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L32-L53) · [full step: `canonical/skills/aid-update-cicd/SKILL.md#L32-L55`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L32-L55)

<a id="fragment-n2"></a>**2 · `UPDATE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-cicd/SKILL.md#L59-L69" wrap
## State: UPDATE

1. **Apply only the change the user named in this run**, to the owned C8 content, per the
   content rules below.
2. **Ask, every run, which derived outputs to update alongside this one.** This step is
   unconditional -- it runs on every invocation, and the answer is **stored nowhere**: no
   frontmatter backlink, no manifest, no registry, and no state carried between runs. The
   question is asked afresh each time.
3. **Write no tracking metadata** into any output this run touches -- no `derived-from`, no
   `source-doc`, no `generated-by`, no `aid-tracked` field, and no skill-attribution line.
4. **`source: generated` refuses.** A registered build script owns that content.
~~~~

[Source: `canonical/skills/aid-update-cicd/SKILL.md#L59-L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L59-L69) · [full step: `canonical/skills/aid-update-cicd/SKILL.md#L59-L71`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L59-L71)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-update-cicd/SKILL.md#L75-L78" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-update-cicd/SKILL.md#L75-L78`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L75-L78) · [full step: `canonical/skills/aid-update-cicd/SKILL.md#L75-L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L75-L80)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-update-cicd/SKILL.md#L84-L88" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revision, say whether a workflow file was
touched and that it was asked for, name every output touched, and assert that a consumed seed
is gone.
~~~~

[Source: `canonical/skills/aid-update-cicd/SKILL.md#L84-L88`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L84-L88) · [full step: `canonical/skills/aid-update-cicd/SKILL.md#L84-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-cicd/SKILL.md#L84-L90)
