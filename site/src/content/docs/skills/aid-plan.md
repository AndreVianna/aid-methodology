---
title: 'aid-plan'
description: 'Group the specified features into deliveries.'
generatedFrom: 'canonical/skills/aid-plan/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-plan/SKILL.md -->

## Frontmatter

- **`name`** — aid-plan
- **`description`** — Group the specified features into deliveries. Use when the feature specifications are approved and ready to group.
- **`allowed-tools`** — Read Glob Grep Write Edit Bash Shell Terminal
- **`argument-hint`** — work-001 (required if multiple works)  [--reset] clear PLAN.md and restart

[Definition: `canonical/skills/aid-plan/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["FIRST-RUN<br/>No PLAN.md found; begin dependency mapping and deliverable…"])
  n2(["CONFIRM"])
  n3(["REVIEW<br/>PLAN.md exists and was previously completed; re-review…"])
  n4(["DONE"])
  n1 --> n3
  n2 --> n3
  n3 -->|"when the grade is below minimum and the deliverables are fixable"| n1
  n3 -->|"when the grade meets minimum and all delivery folders are created"| n4
  class n1 aidEntry
  class n2 aidEntry
  class n3 aidExit
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `FIRST-RUN`** — No PLAN.md found; begin dependency mapping and deliverable… · _entry_

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L164" wrap
| FIRST-RUN | `references/first-run-loop.md` | `aid-architect` | CHAIN → REVIEW |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L164`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L164) · [full step: `canonical/skills/aid-plan/references/first-run-loop.md#L1-L234`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/first-run-loop.md#L1-L234)

<a id="fragment-n2"></a>**2 · `CONFIRM`** · _entry_

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L165" wrap
| CONFIRM | `references/confirm-reopen.md` | `inline` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L165`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L165) · [full step: `canonical/skills/aid-plan/references/confirm-reopen.md#L1-L13`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/confirm-reopen.md#L1-L13)

<a id="fragment-n3"></a>**3 · `REVIEW`** — PLAN.md exists and was previously completed; re-review… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L166" wrap
| REVIEW | `references/review-deliverables.md` | `aid-reviewer` | CHAIN → DONE when the grade meets minimum and all delivery folders are created; CHAIN → FIRST-RUN when the grade is below minimum and the deliverables are fixable; HALT when the sequence is invalidated |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L166`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L166) · [full step: `canonical/skills/aid-plan/references/review-deliverables.md#L1-L76`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/review-deliverables.md#L1-L76)

<a id="fragment-n4"></a>**4 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L167" wrap
| DONE | _(inline — plan complete; print summary and exit)_ | `inline` | HALT |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L167`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L167)
