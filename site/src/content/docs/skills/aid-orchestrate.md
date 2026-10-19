---
title: 'aid-orchestrate'
description: 'Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases.'
generatedFrom: 'canonical/skills/aid-orchestrate/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-orchestrate/SKILL.md -->

## Frontmatter

- **`name`** — aid-orchestrate
- **`description`** — Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts, continues, closes or cancels a work.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit AskUserQuestion
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
  n1(["STEP-1<br/>**Project question** (PROJECT-QUESTION).…"])
  n2["STEP-2<br/>**Check the reading** (CHECK-READING).…"]
  n3["STEP-3<br/>**Size the reading** (SIZE-READING).…"]
  n4["STEP-4<br/>**Show the reading** (SHOW-READING). One line with its…"]
  n5(["STEP-5<br/>**Hand over an action-skill reading** (ACTION-HANDOVER).…"])
  n6["STEP-6<br/>**Find or create the work** (FIND-OR-CREATE).…"]
  n7["STEP-7<br/>**Ask before going on** (ASK-FIRST). Ask one question when…"]
  n8["STEP-8<br/>**Record the intent** (RECORD-INTENT).…"]
  n9(["STEP-9<br/>**Cancel a named work** (CANCEL).…"])
  n10(["STEP-10<br/>**Close a work** (CLOSE). references/size-and-route.md…"])
  n11(["STEP-11<br/>**Hand over** (HAND-OVER). Ask the user to go ahead, then…"])
  n12(["STEP-12<br/>**During the work** (DURING-WORK). Load…"])
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 -->|"when the reading matches no action skill"| n6
  n6 -->|"when several works plausibly match"| n7
  n6 --> n8
  n7 --> n8
  n8 --> n11
  n12 -. "on a new fact" .-> n2
  n12 -. "otherwise" .- n12
  class n1 aidExit
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidExit
  class n6 aidStep
  class n7 aidStep
  class n8 aidStep
  class n9 aidExit
  class n10 aidExit
  class n11 aidExit
  class n12 aidEntry
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
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `STEP-1`** — \*\*Project question\*\* (PROJECT-QUESTION).… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L20" wrap
1. **Project question** (`PROJECT-QUESTION`). `references/check-intent.md` step 0 spots a question about the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L20`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L20)

<a id="fragment-n2"></a>**2 · `STEP-2`** — \*\*Check the reading\*\* (CHECK-READING).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L23" wrap
2. **Check the reading** (`CHECK-READING`). `references/check-intent.md` steps 1 to 5 compare the request with
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L23`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L23)

<a id="fragment-n3"></a>**3 · `STEP-3`** — \*\*Size the reading\*\* (SIZE-READING).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L26" wrap
3. **Size the reading** (`SIZE-READING`). `references/size-and-route.md` sections 1 and 2 pick the phases and the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L26`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L26)

<a id="fragment-n4"></a>**4 · `STEP-4`** — \*\*Show the reading\*\* (SHOW-READING). One line with its… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L29" wrap
4. **Show the reading** (`SHOW-READING`). One line with its reason, the phases and the depth, in the same
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L29`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L29)

<a id="fragment-n5"></a>**5 · `STEP-5`** — \*\*Hand over an action-skill reading\*\* (ACTION-HANDOVER).… · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L32" wrap
5. **Hand over an action-skill reading** (`ACTION-HANDOVER`). Once the user approves, a reading that matches an
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L32`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L32)

<a id="fragment-n6"></a>**6 · `STEP-6`** — \*\*Find or create the work\*\* (FIND-OR-CREATE).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L38" wrap
6. **Find or create the work** (`FIND-OR-CREATE`). `references/start-or-resume.md` section 3. A matching work is
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L38`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L38)

<a id="fragment-n7"></a>**7 · `STEP-7`** — \*\*Ask before going on\*\* (ASK-FIRST). Ask one question when… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L41" wrap
6a. **Ask before going on** (`ASK-FIRST`). Ask one question when several works plausibly match
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L41`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L41)

<a id="fragment-n8"></a>**8 · `STEP-8`** — \*\*Record the intent\*\* (RECORD-INTENT).… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L44" wrap
7. **Record the intent** (`RECORD-INTENT`). `references/start-or-resume.md` section 6. The record's keys are set
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L44`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L44)

<a id="fragment-n9"></a>**9 · `STEP-9`** — \*\*Cancel a named work\*\* (CANCEL).… · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L47" wrap
8. **Cancel a named work** (`CANCEL`). `references/start-or-resume.md` section 5: one confirmation question,
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L47`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L47)

<a id="fragment-n10"></a>**10 · `STEP-10`** — \*\*Close a work\*\* (CLOSE). references/size-and-route.md… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L49" wrap
9. **Close a work** (`CLOSE`). `references/size-and-route.md` section 3: when every task is `Done` (or, for an
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L49`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L49)

<a id="fragment-n11"></a>**11 · `STEP-11`** — \*\*Hand over\*\* (HAND-OVER). Ask the user to go ahead, then… · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L52" wrap
10. **Hand over** (`HAND-OVER`). Ask the user to go ahead, then start the first phase skill of a new work
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L52`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L52)

<a id="fragment-n12"></a>**12 · `STEP-12`** — \*\*During the work\*\* (DURING-WORK). Load… · _entry_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L56" wrap
11. **During the work** (`DURING-WORK`). Load `references/external-sources.md` when a source is pulled in, applied
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L56)
