---
title: 'aid-orchestrate'
description: 'Start, resume or cancel an AID work: find where it stands, size it and pick its phases.'
generatedFrom: 'canonical/skills/aid-orchestrate/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-orchestrate/SKILL.md -->

## Frontmatter

- **`name`** — aid-orchestrate
- **`description`** — Start, resume or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts a new work, continues an existing one, or cancels one.
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
  n1(["STEP-1<br/>**Project question.** references/check-intent.md step 0…"])
  n2["STEP-2<br/>**Check the reading.** references/check-intent.md steps 1…"]
  n3["STEP-3<br/>**Hand over an action-skill reading.** A reading that…"]
  n4["STEP-4<br/>**Find or create the work.** references/start-or-resume.md…"]
  n5["STEP-5<br/>**Cancel a named work.** references/start-or-resume.md step…"]
  n6["STEP-6<br/>**Size and record.** references/start-or-resume.md step 6…"]
  n7["STEP-7<br/>**Show the reading.** In one line with its reason, inside…"]
  n8["STEP-8<br/>**Hand over.** Start the first phase skill yourself. Where…"]
  n9(["STEP-9<br/>**During the work.** Load references/external-sources.md…"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 --> n6
  n6 --> n7
  n7 --> n8
  n8 --> n9
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidStep
  class n6 aidStep
  class n7 aidStep
  class n8 aidStep
  class n9 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `STEP-1`** — \*\*Project question.\*\* references/check-intent.md step 0… · _entry_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L21" wrap
1. **Project question.** `references/check-intent.md` step 0 spots a question about the
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L21`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L21)

<a id="fragment-n2"></a>**2 · `STEP-2`** — \*\*Check the reading.\*\* references/check-intent.md steps 1… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L24" wrap
2. **Check the reading.** `references/check-intent.md` steps 1 to 5 compare the request with
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L24`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L24)

<a id="fragment-n3"></a>**3 · `STEP-3`** — \*\*Hand over an action-skill reading.\*\* A reading that… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L26" wrap
3. **Hand over an action-skill reading.** A reading that matches an action skill is handed to
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L26`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L26)

<a id="fragment-n4"></a>**4 · `STEP-4`** — \*\*Find or create the work.\*\* references/start-or-resume.md… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L29" wrap
4. **Find or create the work.** `references/start-or-resume.md` steps 3 and 4. A matching work
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L29`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L29)

<a id="fragment-n5"></a>**5 · `STEP-5`** — \*\*Cancel a named work.\*\* references/start-or-resume.md step… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L32" wrap
5. **Cancel a named work.** `references/start-or-resume.md` step 5: resolve the named work,
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L32`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L32)

<a id="fragment-n6"></a>**6 · `STEP-6`** — \*\*Size and record.\*\* references/start-or-resume.md step 6… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L34" wrap
6. **Size and record.** `references/start-or-resume.md` step 6 with
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L34`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L34)

<a id="fragment-n7"></a>**7 · `STEP-7`** — \*\*Show the reading.\*\* In one line with its reason, inside… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L37" wrap
7. **Show the reading.** In one line with its reason, inside the same message as the first
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L37`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L37)

<a id="fragment-n8"></a>**8 · `STEP-8`** — \*\*Hand over.\*\* Start the first phase skill yourself. Where… · _step_

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L39" wrap
8. **Hand over.** Start the first phase skill yourself. Where the tool cannot start a skill,
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L39)

<a id="fragment-n9"></a>**9 · `STEP-9`** — \*\*During the work.\*\* Load references/external-sources.md… · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-orchestrate/SKILL.md#L41" wrap
9. **During the work.** Load `references/external-sources.md` when a source is pulled in,
~~~~

[Source: `canonical/skills/aid-orchestrate/SKILL.md#L41`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-orchestrate/SKILL.md#L41)
