---
title: 'aid-graph'
description: 'Build .aid/knowledge/relationships.md and .aid/knowledge/graph.html from an approved Knowledge Base and the project source.'
generatedFrom: 'canonical/skills/aid-graph/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-graph/SKILL.md -->

## Frontmatter

- **`name`** — aid-graph
- **`description`** — Build .aid/knowledge/relationships.md and .aid/knowledge/graph.html from an approved Knowledge Base and the project source. On demand, never fired by discovery, and a sibling of aid-summarize rather than a phase of it. Reads widely and writes narrowly: the Knowledge Base is read-only for the whole run, and that guarantee is a fence raised before the first write and verified before the run ends. Idempotent and content-addressed: a re-run on an unchanged project is a true no-op, and when it does regenerate it names which input changed. Two-grade quality gate (Machine + Human) over THIS SKILL'S OWN artifacts only -- never over the Knowledge Base's completeness. Knowledge Base gaps are REPORTED and routed onward, never gated on and never fixed here. State machine: PREFLIGHT -> ENUMERATE -> STALE-CHECK -> EXTRACT -> EMIT -> GAP-REPORT -> RENDER -> VALIDATE -> VISUAL-GATE -> FIX -> DONE.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [--reset] force regeneration  [--grade X] override the minimum for this run only

[Definition: `canonical/skills/aid-graph/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["PREFLIGHT<br/>PREFLIGHT is the synchronous gate that verifies every…"])
  n2["ENUMERATE<br/>ENUMERATE walks the project source once and writes the…"]
  n3{"STALE-CHECK"}
  n4["EXTRACT<br/>EXTRACT harvests the Knowledge Base side of the graph…"]
  n5["EMIT<br/>EMIT assembles the coverage-notes section and then writes…"]
  n6["GAP-REPORT<br/>GAP-REPORT reports which structurally significant source…"]
  n7["RENDER<br/>RENDER builds .aid/knowledge/graph.html and…"]
  n8{"VALIDATE"}
  n9{"VISUAL-GATE"}
  n10["FIX<br/>FIX repairs what the gate found and re-enters the pipeline…"]
  n11(["DONE<br/>DONE lowers the write fence, reports what the run produced…"])
  n1 -. "otherwise" .- n1
  n1 --> n2
  n2 --> n3
  n3 -->|"on"| n4
  n3 -->|"(idempotent variant) on"| n11
  n4 --> n5
  n5 --> n6
  n6 --> n7
  n7 -. "otherwise" .- n7
  n7 --> n8
  n8 -->|"if the Machine Grade ≥ the floor and the view is in scope"| n9
  n8 -->|"otherwise. All continue inline"| n10
  n8 -->|"if it is ≥ the floor and the view is not in scope"| n11
  n9 -->|"otherwise"| n10
  n9 -->|"if the Overall Grade ≥ the floor"| n11
  n10 --> n4
  n10 --> n7
  n10 -->|"per the table above"| n8
  class n1 aidEntry
  class n2 aidStep
  class n3 aidDecision
  class n4 aidStep
  class n5 aidStep
  class n6 aidStep
  class n7 aidLoopBack
  class n8 aidDecision
  class n9 aidDecision
  class n10 aidStep
  class n11 aidExit
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
  class n11 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PREFLIGHT`** — PREFLIGHT is the synchronous gate that verifies every… · _entry_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L126" wrap
| PREFLIGHT | `references/state-preflight.md` | inline | → ENUMERATE (exit `0`) / abort the run, naming the failing check (exit `1`) |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L126`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L126) · [full step: `canonical/skills/aid-graph/references/state-preflight.md#L1-L48`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-preflight.md#L1-L48)

<a id="fragment-n2"></a>**2 · `ENUMERATE`** — ENUMERATE walks the project source once and writes the… · _step_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L127" wrap
| ENUMERATE | `references/state-enumerate.md` | inline | → STALE-CHECK |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L127`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L127) · [full step: `canonical/skills/aid-graph/references/state-enumerate.md#L1-L36`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-enumerate.md#L1-L36)

<a id="fragment-n3"></a>**3 · `STALE-CHECK`** — STALE-CHECK decides whether this run must regenerate, and… · _decision_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L128" wrap
| STALE-CHECK | `references/state-stale-check.md` | inline | → EXTRACT (`STALE` / `FIRST_RUN`) / → DONE, idempotent variant (`CURRENT`) |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L128`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L128) · [full step: `canonical/skills/aid-graph/references/state-stale-check.md#L1-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-stale-check.md#L1-L53)

<a id="fragment-n4"></a>**4 · `EXTRACT`** — EXTRACT harvests the Knowledge Base side of the graph… · _step_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L129" wrap
| EXTRACT | `references/state-extract.md` | inline + `Agent` dispatches per `references/agent-pass.md` | → EMIT |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L129`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L129) · [full step: `canonical/skills/aid-graph/references/state-extract.md#L1-L125`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-extract.md#L1-L125)

<a id="fragment-n5"></a>**5 · `EMIT`** — EMIT assembles the coverage-notes section and then writes… · _step_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L130" wrap
| EMIT | `references/state-emit.md` | inline | → GAP-REPORT |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L130`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L130) · [full step: `canonical/skills/aid-graph/references/state-emit.md#L1-L62`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-emit.md#L1-L62)

<a id="fragment-n6"></a>**6 · `GAP-REPORT`** — GAP-REPORT reports which structurally significant source… · _step_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L131" wrap
| GAP-REPORT | `references/state-gap-report.md` | inline | → RENDER |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L131`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L131) · [full step: `canonical/skills/aid-graph/references/state-gap-report.md#L1-L92`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-gap-report.md#L1-L92)

<a id="fragment-n7"></a>**7 · `RENDER`** — RENDER builds .aid/knowledge/graph.html and… · _loop-back_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L132" wrap
| RENDER | `references/state-render.md` | inline | → VALIDATE. **Skipped when `view_expected` is false** |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L132`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L132) · [full step: `canonical/skills/aid-graph/references/state-render.md#L1-L54`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-render.md#L1-L54)

<a id="fragment-n8"></a>**8 · `VALIDATE`** — VALIDATE runs this skill's own quality rubric over its own… · _decision_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L133" wrap
| VALIDATE | `references/state-validate.md` | inline | → VISUAL-GATE (Machine Grade ≥ the resolved floor) / → FIX (below it) / → DONE (Machine Grade ≥ the floor and `view_expected` is false, VISUAL-GATE being N/A) |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L133`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L133) · [full step: `canonical/skills/aid-graph/references/state-validate.md#L1-L60`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-validate.md#L1-L60)

<a id="fragment-n9"></a>**9 · `VISUAL-GATE`** — VISUAL-GATE asks the one question about this artifact that… · _decision_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L134" wrap
| VISUAL-GATE | `references/state-visual-gate.md` | inline | → DONE (Overall Grade ≥ the floor) / → FIX (below it). **N/A when `view_expected` is false** |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L134) · [full step: `canonical/skills/aid-graph/references/state-visual-gate.md#L1-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-visual-gate.md#L1-L73)

<a id="fragment-n10"></a>**10 · `FIX`** — FIX repairs what the gate found and re-enters the pipeline… · _step_

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L135" wrap
| FIX | `references/state-fix.md` | inline | → RENDER / → EXTRACT / → VALIDATE, by where the repaired input lives |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L135`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L135) · [full step: `canonical/skills/aid-graph/references/state-fix.md#L1-L57`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-fix.md#L1-L57)

<a id="fragment-n11"></a>**11 · `DONE`** — DONE lowers the write fence, reports what the run produced… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-graph/SKILL.md#L136" wrap
| DONE | `references/state-done.md` | inline | → halt, in one of two variants |
~~~~

[Source: `canonical/skills/aid-graph/SKILL.md#L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/SKILL.md#L136) · [full step: `canonical/skills/aid-graph/references/state-done.md#L1-L98`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-graph/references/state-done.md#L1-L98)
