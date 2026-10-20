---
title: 'aid-create-cicd'
description: 'Realize a ready CI/CD seed from `.aid/design/cicd.md` into the project''s shipping (C8) Knowledge Base document -- the pipeline stages and their order, the…'
generatedFrom: 'canonical/skills/aid-create-cicd/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-cicd/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-cicd
- **`description`** — Realize a ready CI/CD seed from `.aid/design/cicd.md` into the project's shipping (C8) Knowledge Base document -- the pipeline stages and their order, the triggers, the environments and promotion between them, and the release flow. Use this skill when a CI/CD seed is ready and the project has no record of its delivery pipeline yet. It writes the KB record by default, and emits a workflow file only if you ask for one in that run. Creating the document also registers it, in the same run, which opts it into the Conformance Lane permanently -- a choice you make by running this skill. To revise C8 content already committed use `/aid-update-cicd`; for a resource the pipeline ships to, `/aid-create-infra` or `/aid-update-infra`; for a data pipeline rather than a delivery one, `/aid-create-data-pipeline` or `/aid-update-data-pipeline`; to ship a built artifact now, `/aid-deploy`.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- which parts of the CI/CD seed to realize

[Definition: `canonical/skills/aid-create-cicd/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-create-cicd/SKILL.md#L54-L70" wrap
## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-create-cicd` given to the gate's `--create`, plus `--seed .aid/design/cicd.md` when that seed exists (the gate adds it to the work's `sources:` and copies its `## Questions` into the work's record). `phase` is not driven.
2. **Read the seed** at `.aid/design/cicd.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C8**
   (shipping & operation, `.aid/runtime/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C8 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C8 row of
   `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user. An
   ambiguous realization is **asked**, never picked silently.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Ask whether the user also wants production config this run.** Emitting a workflow file
   is **opt-in per run and never the default**; the KB record is what this skill writes
   unless the user asks in this run.
6. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-create-cicd/SKILL.md#L54-L70`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L54-L70) · [full step: `canonical/skills/aid-create-cicd/SKILL.md#L54-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L54-L72)

<a id="fragment-n2"></a>**2 · `CREATE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-cicd/SKILL.md#L76-L78" wrap
## State: CREATE

**Exactly three conditions refuse. There is no fourth.**
~~~~

[Source: `canonical/skills/aid-create-cicd/SKILL.md#L76-L78`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L76-L78) · [full step: `canonical/skills/aid-create-cicd/SKILL.md#L76-L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L76-L112)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-cicd/SKILL.md#L116-L119" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-cicd/SKILL.md#L116-L119`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L116-L119) · [full step: `canonical/skills/aid-create-cicd/SKILL.md#L116-L121`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L116-L121)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-cicd/SKILL.md#L125-L129" wrap
## State: PRESENT (hard stop -- the user decides)

Present the realized document and assert: whether a
workflow file was emitted and that it was asked for; on the creation path both registration
surfaces were written; and anything routed to `/aid-update-cicd` is named.
~~~~

[Source: `canonical/skills/aid-create-cicd/SKILL.md#L125-L129`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L125-L129) · [full step: `canonical/skills/aid-create-cicd/SKILL.md#L125-L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L125-L134)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-cicd/SKILL.md#L138-L140" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-cicd/SKILL.md#L138-L140`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L138-L140) · [full step: `canonical/skills/aid-create-cicd/SKILL.md#L138-L140`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-cicd/SKILL.md#L138-L140)
