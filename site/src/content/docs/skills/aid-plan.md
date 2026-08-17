---
title: 'aid-plan'
description: 'Sequence feature SPECs into deliverables -- each one a functional MVP that builds on the previous.'
generatedFrom: 'canonical/skills/aid-plan/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-plan/SKILL.md -->

## Frontmatter

- **`name`** — aid-plan
- **`description`** — Sequence feature SPECs into deliverables -- each one a functional MVP that builds on the previous. Strategy, not tactics. Use when feature SPECs are complete and you need a delivery roadmap.
- **`allowed-tools`** — Read, Glob, Grep, Write, Edit, Bash
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
  n2["REVIEW<br/>PLAN.md exists and was previously completed; re-review…"]
  n3(["DONE"])
  n1 -. "otherwise" .- n1
  n1 -->|"when PLAN.md is written, delivery folders are created, and the final summary is…"| n2
  n2 -. "otherwise" .- n2
  n2 -->|"when the grade meets minimum and all delivery folders are created"| n3
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `FIRST-RUN`** — No PLAN.md found; begin dependency mapping and deliverable… · _entry_

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L149" wrap
| FIRST-RUN | `references/first-run-loop.md` | `aid-architect` | → REVIEW |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L149`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L149) · [full step: `canonical/skills/aid-plan/references/first-run-loop.md#L1-L231`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/first-run-loop.md#L1-L231)

<a id="fragment-n2"></a>**2 · `REVIEW`** — PLAN.md exists and was previously completed; re-review… · _loop-back_

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L150" wrap
| REVIEW | `references/review-deliverables.md` | `aid-reviewer` | → DONE |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L150`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L150) · [full step: `canonical/skills/aid-plan/references/review-deliverables.md#L1-L79`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/references/review-deliverables.md#L1-L79)

<a id="fragment-n3"></a>**3 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-plan/SKILL.md#L151" wrap
| DONE | _(inline — plan complete; print summary and exit)_ | `inline` | → halt |
~~~~

[Source: `canonical/skills/aid-plan/SKILL.md#L151`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md#L151)
