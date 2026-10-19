---
title: 'aid-create-ui'
description: 'Create a UI component or page.'
generatedFrom: 'canonical/skills/aid-create-ui/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-ui/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-ui
- **`description`** — Create a UI component or page. Use when the request is already clear and you want it scoped, specified and broken into reviewable tasks in one pass, before anything is built.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [description]  -- a request to create; runs straight to a graded flattened Lite work

[Definition: `canonical/skills/aid-create-ui/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ui/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-create-ui<br/>Bind VERB=create, ARTIFACT=ui"])
  n2{"INTAKE"}
  n3(["CONTINUATION"])
  n4["CAPTURE<br/>Collapses the Describe work."]
  n5["SPEC<br/>Collapses the Define and Specify work."]
  n6["PLAN<br/>Collapses the Plan work."]
  n7["DETAIL<br/>Collapses the Detail work."]
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

<a id="fragment-n1"></a>**1 · `aid-create-ui`** — Bind VERB=create, ARTIFACT=ui · _entry_

~~~~plaintext title="canonical/skills/aid-create-ui/SKILL.md#L15" wrap
Bind **VERB=`create`**, **ARTIFACT=`ui`**, then run the shared engine at `.aid/runtime/templates/shortcut-engine.md`. The engine scaffolds the flattened Lite work (feature-001 structure) and authors exactly two documents: `REQUIREMENTS.md`, whose `§ 11` feature section carries the technical specification and whose `§ 9` carries the gate criteria, and the task `DETAIL.md` files -- with reduced capture. One feature and one delivery means there is nothing to sequence, so no plan is written and the execution graph is derived from each task's `**Depends on:**` field. It runs the per-document Grading Gates (feature-004) and halts at the FR-10 approval gate. It never executes. This shortcut's `default_type`/`group` are its row in `.aid/runtime/templates/shortcut-catalog.yml`.
~~~~

[Source: `canonical/skills/aid-create-ui/SKILL.md#L15`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ui/SKILL.md#L15)

<a id="fragment-n2"></a>**2 · `INTAKE`** — parse the bound invocation values; resolve the catalog row… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L88" wrap
| INTAKE | below | inline | CHAIN -> CAPTURE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L88`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L88) · [full step: `canonical/aid/templates/shortcut-engine.md#L221-L366`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L221-L366)

<a id="fragment-n3"></a>**3 · `CONTINUATION`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/work-initiation-gate.md#L146" wrap
### 3b. CONTINUATION -> the work's record decides where it resumes
~~~~

[Source: `canonical/aid/templates/work-initiation-gate.md#L146`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/work-initiation-gate.md#L146)

<a id="fragment-n4"></a>**4 · `CAPTURE`** — Collapses the Describe work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L89" wrap
| CAPTURE | below | `aid-architect` (Large) | CHAIN -> SPEC |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L89`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L89) · [full step: `canonical/aid/templates/shortcut-engine.md#L370-L461`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L370-L461)

<a id="fragment-n5"></a>**5 · `SPEC`** — Collapses the Define and Specify work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L90" wrap
| SPEC | below | `aid-architect` (Large) | CHAIN -> PLAN |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L90) · [full step: `canonical/aid/templates/shortcut-engine.md#L465-L525`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L465-L525)

<a id="fragment-n6"></a>**6 · `PLAN`** — Collapses the Plan work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L91" wrap
| PLAN | below | `aid-architect` (Large) | CHAIN -> DETAIL |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L91) · [full step: `canonical/aid/templates/shortcut-engine.md#L529-L598`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L529-L598)

<a id="fragment-n7"></a>**7 · `DETAIL`** — Collapses the Detail work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L92" wrap
| DETAIL | below | `aid-architect` (Large) | CHAIN -> GATE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L92) · [full step: `canonical/aid/templates/shortcut-engine.md#L602-L703`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L602-L703)

<a id="fragment-n8"></a>**8 · `GATE`** — Runs feature-004's two batched Grading-Gate passes over the… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L93" wrap
| GATE | below | `aid-reviewer` (Large) | CHAIN -> APPROVAL-HALT |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L93) · [full step: `canonical/aid/templates/shortcut-engine.md#L705-L884`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L705-L884)

<a id="fragment-n9"></a>**9 · `Circuit breaker`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L840" wrap
   **Circuit breaker.** If the pass's grade has not improved across 3
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L840`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L840)

<a id="fragment-n10"></a>**10 · `APPROVAL-HALT`** — Terminal state (FR-10 / NFR-10). · _exit_ · ASK

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L94" wrap
| APPROVAL-HALT | below | inline | ASK then HALT |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L94) · [full step: `canonical/aid/templates/shortcut-engine.md#L888-L948`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L888-L948)
