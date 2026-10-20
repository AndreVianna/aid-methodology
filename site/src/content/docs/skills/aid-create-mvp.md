---
title: 'aid-create-mvp'
description: 'Realize a ready MVP seed into roadmap.md''s ## MVP section only -- the first shippable slice: what it includes, why the line falls there, what was cut, and…'
generatedFrom: 'canonical/skills/aid-create-mvp/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-mvp/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-mvp
- **`description`** — Realize a ready MVP seed into roadmap.md's ## MVP section only -- the first shippable slice: what it includes, why the line falls there, what was cut, and its current status. Use this skill when an MVP seed is ready and the roadmap's MVP section has not been written yet. The roadmap document itself is `/aid-create-roadmap`'s to create; when roadmap.md is absent this skill routes to `/aid-create-roadmap` without writing anything and leaves the seed in place. Routes to `/aid-update-mvp` when ## MVP already carries committed content. Writes no document and no registration entry -- it owns a section, not a file.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;slice>] -- what to realize into the ## MVP section (fills the section from the seed)

[Definition: `canonical/skills/aid-create-mvp/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md)

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
  n4(["VERIFY"])
  n5["PRESENT<br/>hard stop -- the user decides"]
  n6(["DONE"])
  n1 -->|"once the seed question is settled"| n2
  n2 -->|"when the gate passes"| n3
  n3 -->|"when the section is written"| n4
  n4 -. "when it is not clean and fewer than 3 cycles have run" .-> n3
  n4 -->|"when the verify is clean"| n5
  n5 -. "when the user declines or asks for changes" .-> n3
  n5 -->|"when the user approves"| n6
  class n1 aidExit
  class n2 aidExit
  class n3 aidExit
  class n4 aidExit
  class n5 aidLoopBack
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L56-L58" wrap
## State: INTAKE

Every question this step asks (the opening bootstrapping question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-create-mvp` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/mvp.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L56-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L56-L58) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L56-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L56-L72)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L76-L79" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a
non-empty `## Open questions` section per `design-lifecycle.md`'s detection rule.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L76-L79`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L76-L79) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L76-L86`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L76-L86)

<a id="fragment-n3"></a>**3 · `REALIZE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L90-L94" wrap
## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the
case determined in INTAKE. The worker never asks the user: the route question below is
asked by the main conversation.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L90-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L90-L94) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L90-L132`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L90-L132)

<a id="fragment-n4"></a>**4 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L136-L140" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L136-L140`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L136-L140) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L136-L142`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L136-L142)

<a id="fragment-n5"></a>**5 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L146-L149" wrap
## State: PRESENT (hard stop -- the user decides)

Present the realized `## MVP` section clearly.
Assert:
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L146-L149`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L146-L149) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L146-L162`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L146-L162)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-mvp/SKILL.md#L166-L168" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-mvp/SKILL.md#L166-L168`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L166-L168) · [full step: `canonical/skills/aid-create-mvp/SKILL.md#L166-L168`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-mvp/SKILL.md#L166-L168)
