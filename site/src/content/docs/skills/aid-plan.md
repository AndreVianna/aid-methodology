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
  n2(["CONFIRM<br/>PLAN.md exists and was previously completed; re-review…"])
  n3(["REVIEW<br/>PLAN.md exists and was previously completed; re-review…"])
  n4(["DONE"])
  n1 -. "otherwise" .- n1
  n1 -->|"once the user has approved the sequence, PLAN.md is written, delivery folders…"| n3
  n2 -. "otherwise" .- n2
  n2 -->|"A confirmation continues to the review; a specific concern the user gives is…"| n3
  n3 --> n4
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

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L157" wrap
| FIRST-RUN | `references/first-run-loop.md` | `aid-architect` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L157`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L157) · [full step: `canonical/skills/aid-plan/references/first-run-loop.md#L1-L233`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/first-run-loop.md#L1-L233)

<a id="fragment-n2"></a>**2 · `CONFIRM`** — PLAN.md exists and was previously completed; re-review… · _entry_

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L158" wrap
| CONFIRM | `references/review-deliverables.md` | `inline` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L158`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L158) · [full step: `canonical/skills/aid-plan/references/review-deliverables.md#L1-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/review-deliverables.md#L1-L84)

<a id="fragment-n3"></a>**3 · `REVIEW`** — PLAN.md exists and was previously completed; re-review… · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L159" wrap
| REVIEW | `references/review-deliverables.md` | `aid-reviewer` | CHAIN → DONE |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L159) · [full step: `canonical/skills/aid-plan/references/review-deliverables.md#L1-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/review-deliverables.md#L1-L84)

<a id="fragment-n4"></a>**4 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L160" wrap
| DONE | _(inline — plan complete; print summary and exit)_ | `inline` | HALT |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L160`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L160)
