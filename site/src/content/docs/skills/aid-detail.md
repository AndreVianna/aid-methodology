---
title: 'aid-detail'
description: 'Break deliverables into small, dependency-driven, typed tasks -- each one a reviewable unit.'
generatedFrom: 'canonical/skills/aid-detail/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-detail/SKILL.md -->

## Frontmatter

- **`name`** — aid-detail
- **`description`** — Break deliverables into small, dependency-driven, typed tasks -- each one a reviewable unit. The ultimate breakdown. Use this skill when a delivery has been planned and the actual work items are needed before execution starts. It detects each task's type from the SPEC's own signals -- RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE -- gives every task exactly one type, and builds the delivery's execution graph with explicit dependencies and the parallelism they allow.
- **`allowed-tools`** — Read Glob Grep Write Edit Bash Shell Terminal
- **`argument-hint`** — work-001 (required if multiple works)  [--reset] clear deliveries/delivery-NNN/tasks/

[Definition: `canonical/skills/aid-detail/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["FIRST-RUN<br/>No task files exist yet."])
  n2(["CONFIRM<br/>Existing task files found; re-review against current…"])
  n3(["REVIEW<br/>Existing task files found; re-review against current…"])
  n4(["DONE"])
  n1 -. "otherwise" .- n1
  n1 -->|"once the user has approved the task breakdown"| n3
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

<a id="fragment-n1"></a>**1 · `FIRST-RUN`** — No task files exist yet. · _entry_

~~~~plaintext title="canonical/skills/aid-detail/SKILL.md#L94" wrap
| FIRST-RUN | `references/first-run.md` | `aid-architect` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-detail/SKILL.md#L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md#L94) · [full step: `canonical/skills/aid-detail/references/first-run.md#L1-L129`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/references/first-run.md#L1-L129)

<a id="fragment-n2"></a>**2 · `CONFIRM`** — Existing task files found; re-review against current… · _entry_

~~~~plaintext title="canonical/skills/aid-detail/SKILL.md#L95" wrap
| CONFIRM | `references/review.md` | `inline` | ASK → REVIEW |
~~~~

[Source: `canonical/skills/aid-detail/SKILL.md#L95`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md#L95) · [full step: `canonical/skills/aid-detail/references/review.md#L1-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/references/review.md#L1-L87)

<a id="fragment-n3"></a>**3 · `REVIEW`** — Existing task files found; re-review against current… · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-detail/SKILL.md#L96" wrap
| REVIEW | `references/review.md` | `aid-reviewer` | CHAIN → DONE |
~~~~

[Source: `canonical/skills/aid-detail/SKILL.md#L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md#L96) · [full step: `canonical/skills/aid-detail/references/review.md#L1-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/references/review.md#L1-L87)

<a id="fragment-n4"></a>**4 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-detail/SKILL.md#L97" wrap
| DONE | — | `inline` | HALT |
~~~~

[Source: `canonical/skills/aid-detail/SKILL.md#L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md#L97)
