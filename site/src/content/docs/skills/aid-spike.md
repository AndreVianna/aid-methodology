---
title: 'aid-spike'
description: 'Alias of /aid-research -- investigate an open technical question NOW and return a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-,…'
generatedFrom: 'canonical/skills/aid-spike/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-spike/SKILL.md -->

## Frontmatter

- **`name`** — aid-spike
- **`description`** — Alias of /aid-research -- investigate an open technical question NOW and return a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-, conflicts with their reasons, and gaps for you to resolve). "Spike" emphasizes the feasibility-question flavor; aid-research handles that via its human-authorized, isolated, throwaway spike escalation (it never spikes code without your approval). This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-research/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;question> -- a feasibility question to investigate

[Definition: `canonical/skills/aid-spike/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-spike/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
%%{init: {'flowchart': {'nodeSpacing': 55, 'rankSpacing': 65, 'curve': 'linear', 'padding': 12, 'useMaxWidth': true}}}%%
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ENTRY<br/>Entry"])
  n2["RUN<br/>Run Alias of /aid-research -- investigate an open technical…"]
  n3(["EXIT<br/>Exit"])
  n1 --> n2
  n2 --> n3
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
