---
title: 'aid-research'
description: 'Investigate an open technical question NOW -- evaluate options, or (only with your explicit authorization) run an isolated feasibility spike -- and return a…'
generatedFrom: 'canonical/skills/aid-research/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-research/SKILL.md -->

## Frontmatter

- **`name`** — aid-research
- **`description`** — Investigate an open technical question NOW -- evaluate options, or (only with your explicit authorization) run an isolated feasibility spike -- and return a curated, verified answer in one pass. It RESOLVES NOTHING: it presents the in-depth answer plus conclusions (positive AND negative), conflicts / contradictions (each with its reason), and gaps, clearly and simply; you resolve. Grounded two ways: the Knowledge Base (.aid/knowledge/) and the project source/codebase are the authoritative grounding truth; external / web sources are allowed and encouraged but supplementary, cited with URL + access date. A KB&lt;->web contradiction is surfaced to you with its reason, never silently resolved. Produced by the aid-researcher agent and independently verified by aid-reviewer before you see it. Allocates a work-NNN folder. /aid-investigate and /aid-spike are aliases.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;question> -- an open technical question to investigate

[Definition: `canonical/skills/aid-research/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md)

## Flow

```mermaid
---
config:
  layout: elk
  flowchart:
    nodeSpacing: 55
    rankSpacing: 65
    padding: 12
    useMaxWidth: true
---
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE"])
  n2["INVESTIGATE"]
  n3["VERIFY<br/>who reviews the researcher"]
  n4{"PRESENT<br/>always a hard stop -- the user resolves"}
  n5["HANDOFF<br/>optional; printed suggestions only"]
  n6(["DONE"])
  n1 --> n2
  n2 -.-> n1
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"optional"| n5
  n4 --> n6
  n5 --> n6
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidLoopBack
  class n4 aidDecision
  class n5 aidStep
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
