---
title: 'aid-create-architecture'
description: 'Write the architecture document from a ready seed.'
generatedFrom: 'canonical/skills/aid-create-architecture/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-architecture/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-architecture
- **`description`** — Write the architecture document from a ready seed. Use when a seed exists and the document does not.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- which parts of the architecture seed to realize

[Definition: `canonical/skills/aid-create-architecture/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md)

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
  n2["CREATE"]
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

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L30-L45" wrap
## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-architecture`. `phase` is not driven.
2. **Read the seed** at `.aid/design/architecture.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C1**
   (build & shape, `.aid/runtime/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C1 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C1 row of
   `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user.
   C1's default set holds both `project-structure.md` and `architecture.md`; this skill
   targets the document describing the system's shape and **never**
   `project-structure.md`. An ambiguous realization is **asked**, never picked silently.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L30-L45`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L30-L45) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L30-L47`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L30-L47)

<a id="fragment-n2"></a>**2 · `CREATE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L51-L53" wrap
## State: CREATE

**Exactly three conditions refuse. There is no fourth.**
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L51-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L51-L53) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L51-L85`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L51-L85)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L89-L92" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L89-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L89-L92) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L89-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L89-L94)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L98-L102" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the realized document and assert: the seed
was consumed only for what was written; on the creation path both registration surfaces were
written; and anything routed to `/aid-update-architecture` is named.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L98-L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L98-L102) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L98-L104`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L98-L104)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L108-L110" wrap
## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L108-L110`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L108-L110) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L108-L110`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L108-L110)
