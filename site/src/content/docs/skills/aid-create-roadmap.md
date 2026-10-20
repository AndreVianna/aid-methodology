---
title: 'aid-create-roadmap'
description: 'Realize a ready roadmap seed into `.aid/knowledge/roadmap.md` -- frontmatter, preamble, ## Contents index (including the forward ## MVP entry), and the three…'
generatedFrom: 'canonical/skills/aid-create-roadmap/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-roadmap/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-roadmap
- **`description`** — Realize a ready roadmap seed into `.aid/knowledge/roadmap.md` -- frontmatter, preamble, ## Contents index (including the forward ## MVP entry), and the three horizon sections ## Now, ## Next, ## Later. Use this skill when a roadmap seed is ready and the project needs its roadmap document written for the first time. Registers the document in `.aid/settings.yml` and `.aid/knowledge/README.md` on first creation. Routes to `/aid-update-roadmap` when the horizon sections already carry committed content. The ## MVP section belongs entirely to `/aid-create-mvp` -- this skill writes only its ## Contents index entry.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- what to realize (fills horizon sections from the seed)

[Definition: `canonical/skills/aid-create-roadmap/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md)

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
  n2(["GUARD"])
  n3(["REALIZE"])
  n4["REGISTER"]
  n5(["VERIFY"])
  n6["PRESENT<br/>hard stop -- the user decides"]
  n7(["DONE"])
  n1 -->|"once the seed question is settled"| n2
  n2 -->|"when the gate passes"| n3
  n3 -->|"when the document is written"| n4
  n4 --> n5
  n5 -. "when it is not clean and fewer than 3 cycles have run" .-> n3
  n5 -->|"when the verify is clean"| n6
  n6 -. "when the user declines or asks for changes" .-> n3
  n6 -->|"when the user approves"| n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidExit
  class n6 aidLoopBack
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L51-L53" wrap
## State: INTAKE

Every question this step asks (the opening bootstrapping question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-create-roadmap` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/roadmap.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L51-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L51-L53) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L51-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L51-L66)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L70-L73" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a non-empty
`## Open questions` section per `design-lifecycle.md`'s detection rule.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L70-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L70-L73) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L70-L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L70-L80)

<a id="fragment-n3"></a>**3 · `REALIZE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L84-L88" wrap
## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the case
determined in INTAKE. The worker never asks the user: the route question below is
asked by the main conversation.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L84-L88`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L84-L88) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L84-L142`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L84-L142)

<a id="fragment-n4"></a>**4 · `REGISTER`** · _step_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L146-L149" wrap
## State: REGISTER

**On creation only** (destination was absent in INTAKE). Write two surfaces atomically
in the same run, per `feature-003 §6b` (REQUIREMENTS CC-1, CC-2):
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L146-L149`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L146-L149) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L146-L161`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L146-L161)

<a id="fragment-n5"></a>**5 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L165-L169" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L165-L169`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L165-L169) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L165-L171`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L165-L171)

<a id="fragment-n6"></a>**6 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L175-L177" wrap
## State: PRESENT (hard stop -- the user decides)

Present the realized document clearly. Assert:
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L175-L177`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L175-L177) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L175-L187`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L175-L187)

<a id="fragment-n7"></a>**7 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-roadmap/SKILL.md#L191-L193" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-roadmap/SKILL.md#L191-L193`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L191-L193) · [full step: `canonical/skills/aid-create-roadmap/SKILL.md#L191-L193`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-roadmap/SKILL.md#L191-L193)
