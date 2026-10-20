---
title: 'aid-brainstorm'
description: 'Shape an unformed idea into a design seed, a written note of framings and candidate directions.'
generatedFrom: 'canonical/skills/aid-brainstorm/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-brainstorm/SKILL.md -->

## Frontmatter

- **`name`** — aid-brainstorm
- **`description`** — Shape an unformed idea into a design seed, a written note of framings and candidate directions. Use when the problem is still unclear and you need to explore it before committing to one direction.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- a fuzzy problem or theme to explore (not yet a formed question)

[Definition: `canonical/skills/aid-brainstorm/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md)

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
  n2["DESIGN"]
  n3(["VERIFY"])
  n4["PRESENT<br/>hard stop -- the user decides"]
  n5(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 -. "when the user declines or asks for changes" .-> n2
  n4 -->|"when the user approves"| n5
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n4 aidLoopBack
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-brainstorm/SKILL.md#L35-L39" wrap
## State: INTAKE

**State Detection.** Detection shapes the entry step of a fresh start and validates a saved step
on resume; it never routes. The step a design resumes at comes from the seed's `step:` and `step_detail:` frontmatter
(`.aid/runtime/templates/skill-steps.md`, § State Detection).
~~~~

[Source: `canonical/skills/aid-brainstorm/SKILL.md#L35-L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L35-L39) · [full step: `canonical/skills/aid-brainstorm/SKILL.md#L35-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L35-L53)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-brainstorm/SKILL.md#L57-L65" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/<slug>.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any prior seed.
It diverges -- framings, angles, prior art -- then converges to the candidate directions
worth pursuing. The seed's `## Destination` is **optional** here: brainstorm has no fixed
destination until the user promotes the seed. **Never writes `.aid/knowledge/` and never
writes production code** -- the `design` invariant (`design-lifecycle.md`).
~~~~

[Source: `canonical/skills/aid-brainstorm/SKILL.md#L57-L65`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L57-L65) · [full step: `canonical/skills/aid-brainstorm/SKILL.md#L57-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L57-L67)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-brainstorm/SKILL.md#L71-L74" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/<slug>.md --detail 'impediment: <reason>'`.
~~~~

[Source: `canonical/skills/aid-brainstorm/SKILL.md#L71-L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L71-L74) · [full step: `canonical/skills/aid-brainstorm/SKILL.md#L71-L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L71-L76)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-brainstorm/SKILL.md#L80-L84" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place), promotes the seed into a `design` lifecycle
entry, or takes it forward however they choose.
~~~~

[Source: `canonical/skills/aid-brainstorm/SKILL.md#L80-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L80-L84) · [full step: `canonical/skills/aid-brainstorm/SKILL.md#L80-L89`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L80-L89)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-brainstorm/SKILL.md#L93-L96" wrap
## State: DONE

Record the step with `--step DONE --design .aid/design/<slug>.md --detail 'approved'`. The seed
persists at `.aid/design/<slug>.md`; brainstorm has no `create` counterpart to consume it.
~~~~

[Source: `canonical/skills/aid-brainstorm/SKILL.md#L93-L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L93-L96) · [full step: `canonical/skills/aid-brainstorm/SKILL.md#L93-L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-brainstorm/SKILL.md#L93-L96)
