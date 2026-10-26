---
title: 'aid-create-stack'
description: 'Write the technology-stack KB document from a ready seed.'
generatedFrom: 'canonical/skills/aid-create-stack/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-stack/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-stack
- **`description`** — Write the technology-stack KB document from a ready seed. Use when none exists yet.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- which parts of the stack seed to realize

[Definition: `canonical/skills/aid-create-stack/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-create-stack/SKILL.md#L29-L43" wrap
## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-stack`. `phase` is not driven.
2. **Read the seed** at `.aid/design/stack.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C0**
   (technology, `.aid/runtime/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C0 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C0 row of
   `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user.
   An ambiguous realization is **asked**, never picked silently. The seed also names a
   **second** destination -- the project's D document, for the rejected alternatives.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-create-stack/SKILL.md#L29-L43`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L29-L43) · [full step: `canonical/skills/aid-create-stack/SKILL.md#L29-L45`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L29-L45)

<a id="fragment-n2"></a>**2 · `CREATE`** · _step_

~~~~plaintext title="canonical/skills/aid-create-stack/SKILL.md#L49-L51" wrap
## State: CREATE

**Exactly three conditions refuse. There is no fourth.**
~~~~

[Source: `canonical/skills/aid-create-stack/SKILL.md#L49-L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L49-L51) · [full step: `canonical/skills/aid-create-stack/SKILL.md#L49-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L49-L83)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-stack/SKILL.md#L87-L90" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-create-stack/SKILL.md#L87-L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L87-L90) · [full step: `canonical/skills/aid-create-stack/SKILL.md#L87-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L87-L92)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-create-stack/SKILL.md#L96-L101" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the realized document and assert: the seed
was consumed only for what was written; on the creation path both registration surfaces were
written; the rejected alternatives went to the D document; and anything routed to
`/aid-update-stack` is named.
~~~~

[Source: `canonical/skills/aid-create-stack/SKILL.md#L96-L101`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L96-L101) · [full step: `canonical/skills/aid-create-stack/SKILL.md#L96-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L96-L103)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-stack/SKILL.md#L107-L109" wrap
## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-create-stack/SKILL.md#L107-L109`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L107-L109) · [full step: `canonical/skills/aid-create-stack/SKILL.md#L107-L109`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-stack/SKILL.md#L107-L109)
