---
title: 'aid-ask'
description: 'Friendly-named alias of /aid-query-kb -- the optional on-demand Q&A skill.'
generatedFrom: 'canonical/skills/aid-ask/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-ask/SKILL.md -->

## Frontmatter

- **`name`** — aid-ask
- **`description`** — Friendly-named alias of /aid-query-kb -- the optional on-demand Q&amp;A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an answer with source citations. When the available context cannot answer the question, states the gap explicitly and captures it as a Query-Gap entry so it feeds the KB-improvement loop. This file carries no logic of its own -- its full behavior is defined entirely by canonical/skills/aid-query-kb/SKILL.md, which this skill delegates to.
- **`allowed-tools`** — Read, Glob, Grep, Agent, Write, Edit
- **`argument-hint`** — &lt;question>  — a free-form question about the project

[Definition: `canonical/skills/aid-ask/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md)

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
  n2["RUN<br/>Run Friendly-named alias of /aid-query-kb -- the optional…"]
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
