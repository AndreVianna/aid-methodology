---
title: 'aid-remove'
description: 'Remove or delete a code artifact, endpoint, dependency, feature, or dead code; update dependents, tests, and docs.'
generatedFrom: 'canonical/skills/aid-remove/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-remove/SKILL.md -->

## Frontmatter

- **`name`** — aid-remove
- **`description`** — Remove or delete a code artifact, endpoint, dependency, feature, or dead code; update dependents, tests, and docs. Use when the request is already clear and you want it scoped, specified and broken into reviewable tasks in one pass, before anything is built.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [description]  -- a request to remove; runs straight to a graded flattened Lite work

[Definition: `canonical/skills/aid-remove/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-remove/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-remove<br/>Bind VERB=remove, ARTIFACT=&quot;&quot; (bare verb)"])
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
  n8 -. "when a pass is below the floor and the circuit breaker has not tripped" .- n8
  n8 -->|"If the pass's grade has not improved across 3 consecutive cycles"| n9
  n8 -->|"when both passes clear"| n10
  n10 -. "when the requirements must change" .-> n4
  n10 -. "when only the task set must change" .-> n7
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

<a id="fragment-n1"></a>**1 · `aid-remove`** — Bind VERB=remove, ARTIFACT="" (bare verb) · _entry_

~~~~plaintext title="canonical/skills/aid-remove/SKILL.md#L16" wrap
Bind **VERB=`remove`**, **ARTIFACT="" (bare verb)**, then run the shared engine at `.aid/runtime/templates/shortcut-engine.md`. The engine scaffolds the flattened Lite work (feature-001 structure) and authors exactly two documents: `REQUIREMENTS.md`, whose `§ 11` feature section carries the technical specification and whose `§ 9` carries the gate criteria, and the task `DETAIL.md` files -- with reduced capture. One feature and one delivery means there is nothing to sequence, so no plan is written and the execution graph is derived from each task's `**Depends on:**` field. It runs the per-document Grading Gates (feature-004) and halts at the FR-10 approval gate. It never executes. This shortcut's `default_type`/`group` are its row in `.aid/runtime/templates/shortcut-catalog.yml`.
~~~~

[Source: `canonical/skills/aid-remove/SKILL.md#L16`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-remove/SKILL.md#L16)

<a id="fragment-n2"></a>**2 · `INTAKE`** — parse the bound invocation values; resolve the catalog row… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L88" wrap
| INTAKE | below | inline | CHAIN → CAPTURE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L88`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L88) · [full step: `canonical/aid/templates/shortcut-engine.md#L222-L384`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L222-L384)

<a id="fragment-n3"></a>**3 · `CONTINUATION`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/work-initiation-gate.md#L175" wrap
### 3b. CONTINUATION -> the work's record decides where it resumes
~~~~

[Source: `canonical/aid/templates/work-initiation-gate.md#L175`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/work-initiation-gate.md#L175)

<a id="fragment-n4"></a>**4 · `CAPTURE`** — Collapses the Describe work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L89" wrap
| CAPTURE | below | `aid-architect` (Large) | CHAIN → SPEC |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L89`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L89) · [full step: `canonical/aid/templates/shortcut-engine.md#L388-L480`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L388-L480)

<a id="fragment-n5"></a>**5 · `SPEC`** — Collapses the Define and Specify work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L90" wrap
| SPEC | below | `aid-architect` (Large) | CHAIN → PLAN |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L90`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L90) · [full step: `canonical/aid/templates/shortcut-engine.md#L484-L544`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L484-L544)

<a id="fragment-n6"></a>**6 · `PLAN`** — Collapses the Plan work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L91" wrap
| PLAN | below | `aid-architect` (Large) | CHAIN → DETAIL |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L91) · [full step: `canonical/aid/templates/shortcut-engine.md#L548-L617`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L548-L617)

<a id="fragment-n7"></a>**7 · `DETAIL`** — Collapses the Detail work. · _step_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L92" wrap
| DETAIL | below | `aid-architect` (Large) | CHAIN → GATE |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L92) · [full step: `canonical/aid/templates/shortcut-engine.md#L621-L722`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L621-L722)

<a id="fragment-n8"></a>**8 · `GATE`** — Runs feature-004's two batched Grading-Gate passes over the… · _decision_

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L93" wrap
| GATE | below | `aid-reviewer` (Large) | CHAIN → APPROVAL-HALT when both passes clear; CHAIN → GATE when a pass is below the floor and the circuit breaker has not tripped; HALT when the circuit breaker has blocked the work |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L93) · [full step: `canonical/aid/templates/shortcut-engine.md#L724-L906`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L724-L906)

<a id="fragment-n9"></a>**9 · `Circuit breaker`** · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L861" wrap
   **Circuit breaker.** If the pass's grade has not improved across 3
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L861`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L861)

<a id="fragment-n10"></a>**10 · `APPROVAL-HALT`** — Terminal state (FR-10 / NFR-10). · _exit_ · HALT

~~~~plaintext title="canonical/aid/templates/shortcut-engine.md#L94" wrap
| APPROVAL-HALT | below | inline | CHAIN → CAPTURE when the requirements must change; CHAIN → DETAIL when only the task set must change; HALT when approved or dropped |
~~~~

[Source: `canonical/aid/templates/shortcut-engine.md#L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L94) · [full step: `canonical/aid/templates/shortcut-engine.md#L910-L994`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md#L910-L994)
