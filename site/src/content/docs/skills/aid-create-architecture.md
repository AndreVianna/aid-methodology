---
title: 'aid-create-architecture'
description: 'Realize a ready architecture seed from `.aid/design/architecture.md` into the project''s build-and-shape (C1) Knowledge Base document -- components and their…'
generatedFrom: 'canonical/skills/aid-create-architecture/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-architecture/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-architecture
- **`description`** — Realize a ready architecture seed from `.aid/design/architecture.md` into the project's build-and-shape (C1) Knowledge Base document -- components and their responsibilities, boundaries, interactions, and the invariants a change must not break. Use this skill when an architecture seed is ready and the project has no architecture document yet. When it creates the document it also registers it in `.aid/settings.yml` and `.aid/knowledge/README.md` in the same run, which opts that document into the Conformance Lane permanently -- a choice you are making by running this skill. To revise C1 content this lifecycle already committed, use `/aid-update-architecture`; to write documentation ABOUT an architecture rather than realize a design seed, use `/aid-document-architecture`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
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
  n2(["CREATE"])
  n3(["VERIFY"])
  n4["PRESENT<br/>hard stop -- the user decides"]
  n5(["DONE"])
  n1 -->|"when the gate allocated a new work"| n2
  n2 -->|"when every refusal check passes"| n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 -. "when the user declines or asks for changes" .-> n2
  n4 -->|"when the user approves"| n5
  class n1 aidExit
  class n2 aidExit
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

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L52-L67" wrap
## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-create-architecture` given to the gate's `--create`, plus `--seed .aid/design/architecture.md` when that seed exists (the gate adds it to the work's `sources:` and copies its `## Questions` into the work's record). `phase` is not driven.
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

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L52-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L52-L67) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L52-L69`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L52-L69)

<a id="fragment-n2"></a>**2 · `CREATE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L73-L75" wrap
## State: CREATE

**Exactly three conditions refuse. There is no fourth.**
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L73-L75`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L73-L75) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L73-L109`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L73-L109)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L113-L116" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L113-L116`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L113-L116) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L113-L118`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L113-L118)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L122-L126" wrap
## State: PRESENT (hard stop -- the user decides)

Present the realized document and assert: the seed
was consumed only for what was written; on the creation path both registration surfaces were
written; and anything routed to `/aid-update-architecture` is named.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L122-L126`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L122-L126) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L122-L131`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L122-L131)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-architecture/SKILL.md#L135-L137" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-architecture/SKILL.md#L135-L137`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L135-L137) · [full step: `canonical/skills/aid-create-architecture/SKILL.md#L135-L137`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-architecture/SKILL.md#L135-L137)
