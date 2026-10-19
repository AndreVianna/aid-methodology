---
title: 'aid-specify'
description: 'Write a feature''s technical specification.'
generatedFrom: 'canonical/skills/aid-specify/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-specify/SKILL.md -->

## Frontmatter

- **`name`** — aid-specify
- **`description`** — Write a feature's technical specification. Use when the features are defined and each one needs a specification.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit
- **`argument-hint`** — work-001/feature-001 (required)  [--reset] clear technical spec for this feature

[Definition: `canonical/skills/aid-specify/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INITIALIZE<br/>First run for this feature; load context, determine…"])
  n2["CONTINUE<br/>The work STATE.yml's features: entry for this feature shows…"]
  n3(["SPIKE<br/>&gt; Source: references/handling-outcomes.md §&quot;Spike Needed…"])
  n4(["BLOCKED<br/>&gt; Source: references/handling-outcomes.md §&quot;Blocked (State…"])
  n5["REVIEW<br/>All sections complete; re-review entire spec against…"]
  n6(["DONE<br/>Spec is Ready and has met the minimum grade; this feature's…"])
  n1 --> n2
  n2 --> n5
  n3 --> n2
  n4 --> n2
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidEntry
  class n4 aidEntry
  class n5 aidStep
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

<a id="fragment-n1"></a>**1 · `INITIALIZE`** — First run for this feature; load context, determine… · _entry_

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L231" wrap
| INITIALIZE | `references/state-initialize.md` | `aid-architect` | ASK → CONTINUE |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L231`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L231) · [full step: `canonical/skills/aid-specify/references/state-initialize.md#L1-L145`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-initialize.md#L1-L145)

<a id="fragment-n2"></a>**2 · `CONTINUE`** — The work STATE.yml's features: entry for this feature shows… · _step_

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L232" wrap
| CONTINUE | `references/state-continue.md` | `aid-architect` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L232`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L232) · [full step: `canonical/skills/aid-specify/references/state-continue.md#L1-L116`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-continue.md#L1-L116)

<a id="fragment-n3"></a>**3 · `SPIKE`** — > Source: references/handling-outcomes.md §"Spike Needed… · _entry_

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L233" wrap
| SPIKE | `references/state-spike.md` | `inline` | WAIT → CONTINUE |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L233`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L233) · [full step: `canonical/skills/aid-specify/references/state-spike.md#L1-L22`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-spike.md#L1-L22)

<a id="fragment-n4"></a>**4 · `BLOCKED`** — > Source: references/handling-outcomes.md §"Blocked (State… · _entry_

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L234" wrap
| BLOCKED | `references/state-blocked.md` | `inline` | WAIT → CONTINUE |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L234`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L234) · [full step: `canonical/skills/aid-specify/references/state-blocked.md#L1-L19`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-blocked.md#L1-L19)

<a id="fragment-n5"></a>**5 · `REVIEW`** — All sections complete; re-review entire spec against… · _step_

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L235" wrap
| REVIEW | `references/state-review.md` | `aid-reviewer` | ASK → DONE |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L235`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L235) · [full step: `canonical/skills/aid-specify/references/state-review.md#L1-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-review.md#L1-L93)

<a id="fragment-n6"></a>**6 · `DONE`** — Spec is Ready and has met the minimum grade; this feature's… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-specify/SKILL.md#L236" wrap
| DONE | `references/state-done.md` | `inline` | HALT |
~~~~

[Source: `canonical/skills/aid-specify/SKILL.md#L236`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md#L236) · [full step: `canonical/skills/aid-specify/references/state-done.md#L1-L20`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/references/state-done.md#L1-L20)
