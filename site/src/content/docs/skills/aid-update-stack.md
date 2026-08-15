---
title: 'aid-update-stack'
description: 'Revise the project''s technology (C0) Knowledge Base document -- languages, runtimes, frameworks, package managers, and build and test tooling with their…'
generatedFrom: 'canonical/skills/aid-update-stack/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-stack/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-stack
- **`description`** — Revise the project's technology (C0) Knowledge Base document -- languages, runtimes, frameworks, package managers, and build and test tooling with their versions, dependencies and constraints -- plus any previously created outputs you name. Use this skill when the technology-stack document already exists and a choice in it has changed. Requires no design seed: the change you state in the run is a sufficient input. Reads and consumes a stack seed when one is present in `.aid/design/`. When the C0 document does not yet exist, routes to `/aid-create-stack`. To change a configuration option within a chosen stack rather than the stack record, use `/aid-create-config` or `/aid-update-config`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;change> -- what to revise in the technology-stack record

[Definition: `canonical/skills/aid-update-stack/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-update-stack/SKILL.md#L38-L56" wrap
## State: INTAKE

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What
   should change in the technology-stack record?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`canonical/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-update-stack`. `phase` is not driven.
3. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/stack.md`, carrying its `## Current direction` into the destination and
   deleting it once realized.
4. **Resolve the destination by concern.** This skill binds concern **C0** (technology). Where
   a seed supplied a `## Destination`, use it; otherwise apply the concern rule here --
   resolve C0 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the C0 row of
   `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the resolution
   with the user before writing**. Never resolve silently.
5. **Read the whole destination**, and note its `source:` field. Absent destination -> route
   to `/aid-create-stack` and write nothing.
6. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-update-stack/SKILL.md#L38-L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L38-L56) · [full step: `canonical/skills/aid-update-stack/SKILL.md#L38-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L38-L58)

<a id="fragment-n2"></a>**2 · `UPDATE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-stack/SKILL.md#L62-L72" wrap
## State: UPDATE

1. **Apply only the change the user named in this run**, to the owned C0 content, per the
   content rules below.
2. **Ask, every run, which derived outputs to update alongside this one.** This step is
   unconditional -- it runs on every invocation, and the answer is **stored nowhere**: no
   frontmatter backlink, no manifest, no registry, and no state carried between runs. The
   question is asked afresh each time.
3. **Write no tracking metadata** into any output this run touches -- no `derived-from`, no
   `source-doc`, no `generated-by`, no `aid-tracked` field, and no skill-attribution line.
4. **`source: generated` refuses.** A registered build script owns that content.
~~~~

[Source: `canonical/skills/aid-update-stack/SKILL.md#L62-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L62-L72) · [full step: `canonical/skills/aid-update-stack/SKILL.md#L62-L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L62-L74)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-update-stack/SKILL.md#L78-L81" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-update-stack/SKILL.md#L78-L81`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L78-L81) · [full step: `canonical/skills/aid-update-stack/SKILL.md#L78-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L78-L83)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-update-stack/SKILL.md#L87-L90" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revision, name every output touched, state
where any rejected alternative went, and assert that a consumed seed is gone.
~~~~

[Source: `canonical/skills/aid-update-stack/SKILL.md#L87-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L87-L90) · [full step: `canonical/skills/aid-update-stack/SKILL.md#L87-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L87-L92)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-update-stack/SKILL.md#L96-L98" wrap
## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-update-stack/SKILL.md#L96-L98`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L96-L98) · [full step: `canonical/skills/aid-update-stack/SKILL.md#L96-L98`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-stack/SKILL.md#L96-L98)
