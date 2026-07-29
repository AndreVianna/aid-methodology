---
title: 'aid-execute'
description: 'Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE.'
generatedFrom: 'canonical/skills/aid-execute/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-execute/SKILL.md -->

## Frontmatter

- **`name`** — aid-execute
- **`description`** — Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type. State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum. Branch per delivery for isolation.
- **`allowed-tools`** — Read, Glob, Grep, Write, Edit, Bash
- **`argument-hint`** — work-001 (required if multiple works)  task-001 (required)

[Definition: `canonical/skills/aid-execute/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["EXECUTE<br/>Task work is dispatched to the type-appropriate executor…"])
  n2["REVIEW<br/>Task output is graded by a lightweight quick-check pass…"]
  n3["FIX<br/>CODE-source issues from the most recent REVIEW cycle are…"]
  n4(["DONE"])
  n5(["RE-RUN<br/>The task is already Done and the user has re-invoked…"])
  n6(["DELIVERY-GATE<br/>Per-delivery quality gate — runs once per delivery as the…"])
  n1 --> n2
  n2 -. "otherwise" .- n2
  n2 -->|"after triage, findings write, and the terminal State write above"| n4
  n3 --> n2
  n5 --> n2
  n5 -->|"depending on the decision"| n4
  n6 -->|"grade &lt; min"| n3
  n6 -. "otherwise" .- n6
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidStep
  class n4 aidExit
  class n5 aidExit
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `EXECUTE`** — Task work is dispatched to the type-appropriate executor… · _entry_

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L197" wrap
| EXECUTE | `references/state-execute.md` | _(type-specific — see state file; delivery-mode uses pool dispatch PD-0→PD-6)_ | → REVIEW |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L197`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L197) · [full step: `canonical/skills/aid-execute/references/state-execute.md#L1-L772`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/references/state-execute.md#L1-L772)

<a id="fragment-n2"></a>**2 · `REVIEW`** — Task output is graded by a lightweight quick-check pass… · _loop-back_

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L198" wrap
| REVIEW | `references/state-review.md` | `aid-reviewer` (Small tier, quick-check only — no grade loop per FR2) | → DONE |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L198`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L198) · [full step: `canonical/skills/aid-execute/references/state-review.md#L1-L187`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/references/state-review.md#L1-L187)

<a id="fragment-n3"></a>**3 · `FIX`** — CODE-source issues from the most recent REVIEW cycle are… · _step_

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L199" wrap
| FIX | `references/state-fix.md` | _(same type as EXECUTE)_ | → REVIEW |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L199`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L199) · [full step: `canonical/skills/aid-execute/references/state-fix.md#L1-L34`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/references/state-fix.md#L1-L34)

<a id="fragment-n4"></a>**4 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L200" wrap
| DONE | _(inline — task complete)_ | `inline` | → halt |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L200`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L200)

<a id="fragment-n5"></a>**5 · `RE-RUN`** — The task is already Done and the user has re-invoked… · _exit_ · PAUSE-FOR-USER-DECISION

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L201" wrap
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L201`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L201) · [full step: `canonical/skills/aid-execute/references/state-re-run.md#L1-L21`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/references/state-re-run.md#L1-L21)

<a id="fragment-n6"></a>**6 · `DELIVERY-GATE`** — Per-delivery quality gate — runs once per delivery as the… · _exit_ · CHAIN

~~~~plaintext title="canonical/skills/aid-execute/SKILL.md#L202" wrap
| DELIVERY-GATE | `references/state-delivery-gate.md` | `aid-reviewer` (tier = complexity score) | → halt (grade ≥ min) / → FIX (grade < min) |
~~~~

[Source: `canonical/skills/aid-execute/SKILL.md#L202`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md#L202) · [full step: `canonical/skills/aid-execute/references/state-delivery-gate.md#L1-L487`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/references/state-delivery-gate.md#L1-L487)
