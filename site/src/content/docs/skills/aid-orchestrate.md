---
title: 'aid-orchestrate'
description: 'Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases.'
generatedFrom: 'canonical/skills/aid-orchestrate/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-orchestrate/SKILL.md -->

## Frontmatter

- **`name`** — aid-orchestrate
- **`description`** — Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts, continues, closes or cancels a work.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit
- **`argument-hint`** — [request]  -- what you want to do, in your own words

[Definition: `canonical/skills/aid-orchestrate/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["PROJECT-QUESTION<br/>**Project question** (PROJECT-QUESTION).…"])
  n2{"CHECK-READING"}
  n3["SIZE-READING<br/>**Size the reading** (SIZE-READING).…"]
  n4{"SHOW-READING"}
  n5(["ACTION-HANDOVER<br/>**Read the answer** (ACTION-HANDOVER). Only a yes to the…"])
  n6(["START-ACTION<br/>**Start an action skill** (START-ACTION). Start that skill…"])
  n7{"FIND-OR-CREATE"}
  n8["ASK-FIRST<br/>**Ask before going on** (ASK-FIRST).…"]
  n9["RECORD-INTENT<br/>**Record the intent** (RECORD-INTENT).…"]
  n10(["CANCEL<br/>**Cancel a named work** (CANCEL).…"])
  n11(["CLOSE<br/>**Close a work** (CLOSE). references/size-and-route.md…"])
  n12(["HAND-OVER<br/>**Hand over** (HAND-OVER). Nothing more is asked. Start the…"])
  n13(["DURING-WORK<br/>**During the work** (DURING-WORK). Load…"])
  n1 -->|"when the request is not a project question"| n2
  n2 -->|"otherwise"| n3
  n2 -->|"when it names a work to cancel"| n10
  n2 -->|"when it names a work to close"| n11
  n3 --> n4
  n4 -->|"otherwise"| n5
  n4 -->|"when section 6 applies"| n7
  n5 -. "when the user corrects it" .-> n2
  n5 -->|"when the approved reading matches an action skill"| n6
  n5 -->|"when it matches none"| n7
  n7 -->|"when several works plausibly match"| n8
  n7 -->|"otherwise"| n9
  n8 --> n9
  n9 --> n12
  n13 -. "when a new fact arrives" .-> n2
  class n1 aidExit
  class n2 aidDecision
  class n3 aidStep
  class n4 aidDecision
  class n5 aidExit
  class n6 aidExit
  class n7 aidDecision
  class n8 aidStep
  class n9 aidStep
  class n10 aidExit
  class n11 aidExit
  class n12 aidExit
  class n13 aidExit
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
  class n12 aidNode
  class n13 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `PROJECT-QUESTION`** — \*\*Project question\*\* (PROJECT-QUESTION).… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L25" wrap
1. **Project question** (`PROJECT-QUESTION`). `references/check-intent.md` step 0 spots a question about the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L25`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L25)

<a id="fragment-n2"></a>**2 · `CHECK-READING`** — \*\*Check the reading\*\* (CHECK-READING).… · _decision_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L28" wrap
2. **Check the reading** (`CHECK-READING`). `references/check-intent.md` steps 1 to 5 classify the request by its
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L28`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L28)

<a id="fragment-n3"></a>**3 · `SIZE-READING`** — \*\*Size the reading\*\* (SIZE-READING).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L31" wrap
3. **Size the reading** (`SIZE-READING`). `references/size-and-route.md` sections 1 and 2 pick the phases and the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L31`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L31)

<a id="fragment-n4"></a>**4 · `SHOW-READING`** — \*\*Show the reading\*\* (SHOW-READING). One line with its… · _decision_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L33" wrap
4. **Show the reading** (`SHOW-READING`). One line with its reason, the phases and the depth, inside the go-ahead: one approval question
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L33`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L33)

<a id="fragment-n5"></a>**5 · `ACTION-HANDOVER`** — \*\*Read the answer\*\* (ACTION-HANDOVER). Only a yes to the… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L41" wrap
5. **Read the answer** (`ACTION-HANDOVER`). Only a yes to the SHOW-READING go-ahead decides; an answer to a clarifying question never
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L41`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L41)

<a id="fragment-n6"></a>**6 · `START-ACTION`** — \*\*Start an action skill\*\* (START-ACTION). Start that skill… · _exit_ · PASS

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L46" wrap
5a. **Start an action skill** (`START-ACTION`). Start that skill in this turn, with the reading as an `intent:` block
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L46`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L46)

<a id="fragment-n7"></a>**7 · `FIND-OR-CREATE`** — \*\*Find or create the work\*\* (FIND-OR-CREATE).… · _decision_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L48" wrap
6. **Find or create the work** (`FIND-OR-CREATE`). `references/start-or-resume.md` section 3: a matching work is
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L48`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L48)

<a id="fragment-n8"></a>**8 · `ASK-FIRST`** — \*\*Ask before going on\*\* (ASK-FIRST).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L51" wrap
6a. **Ask before going on** (`ASK-FIRST`). `references/start-or-resume.md` sections 3a and 4: which work, when several
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L51)

<a id="fragment-n9"></a>**9 · `RECORD-INTENT`** — \*\*Record the intent\*\* (RECORD-INTENT).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L54" wrap
7. **Record the intent** (`RECORD-INTENT`). `references/start-or-resume.md` section 6, through the writer only; a
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L54`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L54)

<a id="fragment-n10"></a>**10 · `CANCEL`** — \*\*Cancel a named work\*\* (CANCEL).… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L56" wrap
8. **Cancel a named work** (`CANCEL`). `references/start-or-resume.md` section 5: one confirmation question, then
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L56)

<a id="fragment-n11"></a>**11 · `CLOSE`** — \*\*Close a work\*\* (CLOSE). references/size-and-route.md… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L58" wrap
9. **Close a work** (`CLOSE`). `references/size-and-route.md` section 3. **Advance:** **HALT**.
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L58)

<a id="fragment-n12"></a>**12 · `HAND-OVER`** — \*\*Hand over\*\* (HAND-OVER). Nothing more is asked. Start the… · _exit_ · PASS

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L59" wrap
10. **Hand over** (`HAND-OVER`). Nothing more is asked. Start the first phase skill of a new work (`intent.phases`),
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L59`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L59)

<a id="fragment-n13"></a>**13 · `DURING-WORK`** — \*\*During the work\*\* (DURING-WORK). Load… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L62" wrap
11. **During the work** (`DURING-WORK`). Load `references/external-sources.md` when a source is pulled in, applied
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L62`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L62)
