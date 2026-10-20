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
  n4["SHOW-READING<br/>**Show the reading** (SHOW-READING). One line with its…"]
  n5(["ACTION-HANDOVER<br/>**Read the answer** (ACTION-HANDOVER). The user's answer to…"])
  n6(["START-ACTION<br/>**Start an action skill** (START-ACTION). Start that skill…"])
  n7{"FIND-OR-CREATE"}
  n8["ASK-FIRST<br/>**Ask before going on** (ASK-FIRST). Ask one question when…"]
  n9["RECORD-INTENT<br/>**Record the intent** (RECORD-INTENT).…"]
  n10(["CANCEL<br/>**Cancel a named work** (CANCEL).…"])
  n11(["CLOSE<br/>**Close a work** (CLOSE). references/size-and-route.md…"])
  n12(["HAND-OVER<br/>**Hand over** (HAND-OVER). The user approved the reading at…"])
  n13(["DURING-WORK<br/>**During the work** (DURING-WORK). Load…"])
  n1 -->|"when the request is not a project question"| n2
  n2 -->|"otherwise"| n3
  n2 -->|"when the request names a work to cancel"| n10
  n2 -->|"when it names a work to close"| n11
  n3 --> n4
  n4 --> n5
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
  class n4 aidStep
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

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L37" wrap
1. **Project question** (`PROJECT-QUESTION`). `references/check-intent.md` step 0 spots a question about the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L37`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L37)

<a id="fragment-n2"></a>**2 · `CHECK-READING`** — \*\*Check the reading\*\* (CHECK-READING).… · _decision_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L41" wrap
2. **Check the reading** (`CHECK-READING`). `references/check-intent.md` steps 1 to 5 compare the request with
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L41`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L41)

<a id="fragment-n3"></a>**3 · `SIZE-READING`** — \*\*Size the reading\*\* (SIZE-READING).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L44" wrap
3. **Size the reading** (`SIZE-READING`). `references/size-and-route.md` sections 1 and 2 pick the phases and the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L44`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L44)

<a id="fragment-n4"></a>**4 · `SHOW-READING`** — \*\*Show the reading\*\* (SHOW-READING). One line with its… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L47" wrap
4. **Show the reading** (`SHOW-READING`). One line with its reason, the phases and the depth, in the same
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L47`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L47)

<a id="fragment-n5"></a>**5 · `ACTION-HANDOVER`** — \*\*Read the answer\*\* (ACTION-HANDOVER). The user's answer to… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L50" wrap
5. **Read the answer** (`ACTION-HANDOVER`). The user's answer to SHOW-READING decides. A reading that matches an
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L50`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L50)

<a id="fragment-n6"></a>**6 · `START-ACTION`** — \*\*Start an action skill\*\* (START-ACTION). Start that skill… · _exit_ · PASS

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L56" wrap
5a. **Start an action skill** (`START-ACTION`). Start that skill in this turn, with the reading as an `intent:`
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L56)

<a id="fragment-n7"></a>**7 · `FIND-OR-CREATE`** — \*\*Find or create the work\*\* (FIND-OR-CREATE).… · _decision_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L60" wrap
6. **Find or create the work** (`FIND-OR-CREATE`). `references/start-or-resume.md` section 3. A matching work is
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L60`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L60)

<a id="fragment-n8"></a>**8 · `ASK-FIRST`** — \*\*Ask before going on\*\* (ASK-FIRST). Ask one question when… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L64" wrap
6a. **Ask before going on** (`ASK-FIRST`). Ask one question when several works plausibly match
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L64`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L64)

<a id="fragment-n9"></a>**9 · `RECORD-INTENT`** — \*\*Record the intent\*\* (RECORD-INTENT).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L71" wrap
7. **Record the intent** (`RECORD-INTENT`). `references/start-or-resume.md` section 6. The record's keys are set
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L71`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L71)

<a id="fragment-n10"></a>**10 · `CANCEL`** — \*\*Cancel a named work\*\* (CANCEL).… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L74" wrap
8. **Cancel a named work** (`CANCEL`). `references/start-or-resume.md` section 5: one confirmation question,
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L74)

<a id="fragment-n11"></a>**11 · `CLOSE`** — \*\*Close a work\*\* (CLOSE). references/size-and-route.md… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L77" wrap
9. **Close a work** (`CLOSE`). `references/size-and-route.md` section 3: when every task is `Done` (or, for an
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L77)

<a id="fragment-n12"></a>**12 · `HAND-OVER`** — \*\*Hand over\*\* (HAND-OVER). The user approved the reading at… · _exit_ · PASS

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L80" wrap
10. **Hand over** (`HAND-OVER`). The user approved the reading at SHOW-READING, so nothing more is asked. Start the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L80)

<a id="fragment-n13"></a>**13 · `DURING-WORK`** — \*\*During the work\*\* (DURING-WORK). Load… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L85" wrap
11. **During the work** (`DURING-WORK`). Load `references/external-sources.md` when a source is pulled in, applied
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L85`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L85)
