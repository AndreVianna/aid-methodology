---
title: 'aid-create-testing-strategy'
description: 'Realize a ready testing-strategy seed from `.aid/design/testing-strategy.md` into the project''s quality (C6) documents -- the test landscape (levels,…'
generatedFrom: 'canonical/skills/aid-create-testing-strategy/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-testing-strategy/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-testing-strategy
- **`description`** — Realize a ready testing-strategy seed from `.aid/design/testing-strategy.md` into the project's quality (C6) documents -- the test landscape (levels, coverage expectations, CI lane mapping, known gaps) and the gate policy (what blocks a merge, the thresholds, who may waive one). Use this skill when a testing-strategy seed is ready and the project has no record of its test lanes or merge gates yet. Creates the gate document on first use and registers it in `.aid/settings.yml` and `.aid/knowledge/README.md` in the same run, which opts that document into the Conformance Lane permanently -- a choice you are making by running this skill. To revise C6 content this lifecycle already committed, use `/aid-update-testing-strategy`; to author or revise test CODE rather than the strategy, use `/aid-create-test` or `/aid-update-test`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- which parts of the testing-strategy seed to realize

[Definition: `canonical/skills/aid-create-testing-strategy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-create-testing-strategy/SKILL.md#L51-L64" wrap
## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-create-testing-strategy` given to the gate's `--create`. `phase` is not driven.
2. **Read the seed** at `.aid/design/testing-strategy.md`.
3. **Resolve the destinations by concern, not filename.** This skill binds concern **C6**
   (quality & testing, `.aid/runtime/templates/kb-authoring/concern-model.md`) and owns
   **two** documents. The seed's `## Destination` names both halves; where it does not,
   resolve C6 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the C6 row of
   `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user. An
   ambiguous realization is **asked**, never picked silently.
4. **Read both destinations** whole where they exist, and note each one's `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-create-testing-strategy/SKILL.md#L51-L64`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L51-L64) · [full step: `canonical/skills/aid-create-testing-strategy/SKILL.md#L51-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L51-L66)

<a id="fragment-n2"></a>**2 · `CREATE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-testing-strategy/SKILL.md#L70-L72" wrap
## State: CREATE

**Exactly three conditions refuse. There is no fourth.**
~~~~

[Source: `canonical/skills/aid-create-testing-strategy/SKILL.md#L70-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L70-L72) · [full step: `canonical/skills/aid-create-testing-strategy/SKILL.md#L70-L106`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L70-L106)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-testing-strategy/SKILL.md#L110-L113" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-testing-strategy/SKILL.md#L110-L113`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L110-L113) · [full step: `canonical/skills/aid-create-testing-strategy/SKILL.md#L110-L115`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L110-L115)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-testing-strategy/SKILL.md#L119-L123" wrap
## State: PRESENT (hard stop -- the user decides)

Present both realized documents and assert: which
half went where; on a creation path both registration surfaces were written; and anything
routed to `/aid-update-testing-strategy` is named.
~~~~

[Source: `canonical/skills/aid-create-testing-strategy/SKILL.md#L119-L123`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L119-L123) · [full step: `canonical/skills/aid-create-testing-strategy/SKILL.md#L119-L128`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L119-L128)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-testing-strategy/SKILL.md#L132-L134" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-testing-strategy/SKILL.md#L132-L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L132-L134) · [full step: `canonical/skills/aid-create-testing-strategy/SKILL.md#L132-L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-testing-strategy/SKILL.md#L132-L134)
