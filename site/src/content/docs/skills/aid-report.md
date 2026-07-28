---
title: 'aid-report'
description: 'Analyze data or usage NOW -- EDA, metrics, or an A/B result -- and return a curated, verified insight report in one pass.'
generatedFrom: 'canonical/skills/aid-report/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-report/SKILL.md -->

## Frontmatter

- **`name`** — aid-report
- **`description`** — Analyze data or usage NOW -- EDA, metrics, or an A/B result -- and return a curated, verified insight report in one pass. It RESOLVES NOTHING: it presents findings, conclusions (positive AND negative), data-quality caveats, conflicts (each with its reason), and gaps, clearly and simply; you resolve. Grounded two ways: the data being analyzed plus the KB/project source (for what the data means) are the authoritative grounding truth; external baselines/benchmarks are supplementary, cited with URL + access date. Produced by aid-researcher and verified by aid-reviewer. Reads data read-only (files/logs directly; live sources via an MCP connector); never a durable dashboard -- that is /aid-create-dashboard. Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- the data/usage to analyze (a dataset, logs, metrics, an A/B result)

[Definition: `canonical/skills/aid-report/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md)

## Flow

```mermaid
%%{init: {'flowchart': {'nodeSpacing': 55, 'rankSpacing': 65, 'curve': 'linear', 'padding': 12, 'useMaxWidth': true}}}%%
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE"])
  n2["ANALYZE"]
  n3["VERIFY"]
  n4{"PRESENT<br/>hard stop -- the user resolves"}
  n5["HANDOFF<br/>optional; printed suggestions only"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"optional"| n5
  n4 --> n6
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
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
