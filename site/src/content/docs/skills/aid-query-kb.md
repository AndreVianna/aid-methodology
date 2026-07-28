---
title: 'aid-query-kb'
description: 'Optional on-demand Q&A skill.'
generatedFrom: 'canonical/skills/aid-query-kb/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-query-kb/SKILL.md -->

## Frontmatter

- **`name`** — aid-query-kb
- **`description`** — Optional on-demand Q&amp;A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an answer with source citations (KB doc names, file paths, or work-NNN STATE references). When the available context cannot answer the question, states the gap explicitly rather than fabricating an answer AND captures the gap as a Query-Gap entry in the STATE.md Q&amp;A (Pending) backlog so it feeds the KB-improvement loop. Trivial questions are answered inline (Read/Glob/Grep only); broad or expensive investigations dispatch aid-researcher in strictly read-only mode. Writes are restricted to appending a Query-Gap entry to a STATE.md Q&amp;A (Pending) section; no KB doc, settings, or code file is ever written.
- **`allowed-tools`** — Read, Glob, Grep, Agent, Write, Edit
- **`argument-hint`** — &lt;question>  — a free-form question about the project

[Definition: `canonical/skills/aid-query-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-query-kb/SKILL.md)

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
  n1(["STEP-1<br/>Classify the question"])
  n2["STEP-2A<br/>Trivial question: answer inline"]
  n3["STEP-2B<br/>Broad/expensive question: dispatch aid-researcher"]
  n4["STEP-2C<br/>Connector enrichment (optional)"]
  n5["STEP-3<br/>Compose and emit the reply"]
  n6(["STEP-4<br/>Gap capture"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidStep
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
