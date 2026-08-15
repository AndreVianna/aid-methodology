---
title: 'aid-create-infra'
description: 'Provision a new infrastructure resource.'
generatedFrom: 'canonical/skills/aid-create-infra/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-infra/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-infra
- **`description`** — Provision a new infrastructure resource. Use this skill when you already know what to create and want it scoped, specified, and broken into reviewable tasks in a single pass, with no requirements interview. You approve the resulting plan before anything is built: this skill plans and stops, so run `/aid-execute` to carry the plan out.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [description]  -- what to create; runs straight to a graded flattened Lite work

[Definition: `canonical/skills/aid-create-infra/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-infra/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-create-infra<br/>Bind VERB=create, ARTIFACT=infra"])
  n2{"INTAKE"}
  n3(["CONTINUATION"])
  n4["CAPTURE<br/>Collapses Describe."]
  n5["SPEC<br/>Collapses Define + Specify."]
  n6["PLAN<br/>Collapses Plan."]
  n7["DETAIL<br/>Collapses Detail."]
  n8{"GATE"}
  n9(["Circuit breaker"])
  n10(["APPROVAL-HALT<br/>Terminal state (FR-10 / NFR-10)."])
  n1 --> n2
  n2 -->|"On continuation"| n3
  n2 -->|"On new work"| n4
  n4 --> n5
  n5 --> n6
  n6 --> n7
  n7 --> n8
  n8 --- n8
  n8 -->|"If the pass's grade has not improved across 3 consecutive cycles"| n9
  n8 --> n10
  class n1 aidEntry
  class n2 aidDecision
  class n3 aidExit
  class n4 aidStep
  class n5 aidStep
  class n6 aidStep
  class n7 aidStep
  class n8 aidDecision
  class n9 aidExit
  class n10 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
  class n10 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `aid-create-infra`** — Bind VERB=create, ARTIFACT=infra · _entry_

~~~~plaintext title="canonical/skills/aid-create-infra/SKILL.md#L16" wrap
Bind **VERB=`create`**, **ARTIFACT=`infra`**, then run the shared engine at `canonical/aid/templates/shortcut-engine.md`. The engine scaffolds the flattened Lite work (feature-001 structure), authors `REQUIREMENTS.md` -- whose `§ 11` feature section carries the technical specification -- then the task `DETAIL.md` files, with reduced capture. It writes no SPEC.md and no PLAN.md: one feature and one delivery means nothing to sequence, and the execution graph is derived from each task's `**Depends on:**` field. It runs the per-document Grading Gates (feature-004) and halts at the FR-10 approval gate. It never executes. This shortcut's `default_type`/`group` are its row in `canonical/aid/templates/shortcut-catalog.yml`.
~~~~

[Source: `canonical/skills/aid-create-infra/SKILL.md#L16`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-infra/SKILL.md#L16)

<a id="fragment-n2"></a>**2 · `INTAKE`** — parse the bound invocation values; resolve the catalog row… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L91" wrap
| INTAKE | below | inline | CHAIN -> CAPTURE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L91) · [full step: `canonical/aid/templates/shortcut-engine.md#L219-L359`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L219-L359)

<a id="fragment-n3"></a>**3 · `CONTINUATION`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/work-initiation-gate.md#L129" wrap
### 3b. CONTINUATION -> route to the chosen work's resume entry point, then STOP
~~~~

[Source: `canonical/aid/templates/work-initiation-gate.md#L129`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/work-initiation-gate.md#L129)

<a id="fragment-n4"></a>**4 · `CAPTURE`** — Collapses Describe. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L92" wrap
| CAPTURE | below | `aid-architect` (Large) | CHAIN -> SPEC |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L92) · [full step: `canonical/aid/templates/shortcut-engine.md#L363-L461`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L363-L461)

<a id="fragment-n5"></a>**5 · `SPEC`** — Collapses Define + Specify. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L93" wrap
| SPEC | below | `aid-architect` (Large) | CHAIN -> PLAN |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L93) · [full step: `canonical/aid/templates/shortcut-engine.md#L465-L524`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L465-L524)

<a id="fragment-n6"></a>**6 · `PLAN`** — Collapses Plan. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L94" wrap
| PLAN | below | `aid-architect` (Large) | CHAIN -> DETAIL |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L94) · [full step: `canonical/aid/templates/shortcut-engine.md#L528-L597`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L528-L597)

<a id="fragment-n7"></a>**7 · `DETAIL`** — Collapses Detail. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L95" wrap
| DETAIL | below | `aid-architect` (Large) | CHAIN -> GATE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L95`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L95) · [full step: `canonical/aid/templates/shortcut-engine.md#L601-L702`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L601-L702)

<a id="fragment-n8"></a>**8 · `GATE`** — Runs feature-004's two batched Grading-Gate passes over the… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L96" wrap
| GATE | below | `aid-reviewer` (Large) | CHAIN -> APPROVAL-HALT |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L96) · [full step: `canonical/aid/templates/shortcut-engine.md#L704-L883`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L704-L883)

<a id="fragment-n9"></a>**9 · `Circuit breaker`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L839" wrap
   **Circuit breaker.** If the pass's grade has not improved across 3
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L839`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L839)

<a id="fragment-n10"></a>**10 · `APPROVAL-HALT`** — Terminal state (FR-10 / NFR-10). · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L97" wrap
| APPROVAL-HALT | below | inline | HALT |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L97) · [full step: `canonical/aid/templates/shortcut-engine.md#L887-L935`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L887-L935)
