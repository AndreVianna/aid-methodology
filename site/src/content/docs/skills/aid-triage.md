---
title: 'aid-triage'
description: 'Suggest which AID entry point fits the work you describe; suggests only and writes nothing.'
generatedFrom: 'canonical/skills/aid-triage/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-triage/SKILL.md -->

## Frontmatter

- **`name`** — aid-triage
- **`description`** — Suggest which AID entry point fits the work you describe; suggests only and writes nothing. Use when you know what you want to change but not which skill to run.
- **`allowed-tools`** — Read Glob Grep
- **`argument-hint`** — [description]  -- what you want to do; I'll point you at the right entry

[Definition: `canonical/skills/aid-triage/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE<br/>Capture one short free-form description in a single turn…"])
  n2["CLASSIFY<br/>From {description} (captured at INTAKE), infer three things…"]
  n3["SUGGEST<br/>Emits the NFR-7 reflect-back straw-man turn proposing the…"]
  n4(["HALT<br/>Print the recommended invocation the user should type next…"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** — Capture one short free-form description in a single turn… · _entry_

~~~~plaintext title="canonical/skills/aid-triage/SKILL.md#L71" wrap
| INTAKE | inline (below) | inline | CHAIN -> CLASSIFY |
~~~~

[Source: `canonical/skills/aid-triage/SKILL.md#L71`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L71) · [full step: `canonical/skills/aid-triage/SKILL.md#L78-L99`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L78-L99)

<a id="fragment-n2"></a>**2 · `CLASSIFY`** — From {description} (captured at INTAKE), infer three things… · _step_

~~~~plaintext title="canonical/skills/aid-triage/SKILL.md#L72" wrap
| CLASSIFY | `references/state-classify.md` | inline | CHAIN -> SUGGEST |
~~~~

[Source: `canonical/skills/aid-triage/SKILL.md#L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L72) · [full step: `canonical/skills/aid-triage/references/state-classify.md#L1-L143`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/references/state-classify.md#L1-L143)

<a id="fragment-n3"></a>**3 · `SUGGEST`** — Emits the NFR-7 reflect-back straw-man turn proposing the… · _step_

~~~~plaintext title="canonical/skills/aid-triage/SKILL.md#L73" wrap
| SUGGEST | `references/state-suggest.md` | inline | CHAIN -> HALT |
~~~~

[Source: `canonical/skills/aid-triage/SKILL.md#L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L73) · [full step: `canonical/skills/aid-triage/references/state-suggest.md#L1-L98`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/references/state-suggest.md#L1-L98)

<a id="fragment-n4"></a>**4 · `HALT`** — Print the recommended invocation the user should type next… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-triage/SKILL.md#L74" wrap
| HALT | inline (below) | inline | -> halt |
~~~~

[Source: `canonical/skills/aid-triage/SKILL.md#L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L74) · [full step: `canonical/skills/aid-triage/SKILL.md#L103-L127`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md#L103-L127)
