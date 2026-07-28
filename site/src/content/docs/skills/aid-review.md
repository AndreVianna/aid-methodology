---
title: 'aid-review'
description: 'Review/assess an existing artifact -- code, a change/diff, a design, a PR, a ticket, a document, a UI, whatever the request names -- against criteria, and…'
generatedFrom: 'canonical/skills/aid-review/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-review/SKILL.md -->

## Frontmatter

- **`name`** — aid-review
- **`description`** — Review/assess an existing artifact -- code, a change/diff, a design, a PR, a ticket, a document, a UI, whatever the request names -- against criteria, and return findings + recommendations NOW, in one pass. Single-shot and (except the findings ledger + optional approved publish) read-only: it never plans-and-halts. Grounded in the Knowledge Base (.aid/knowledge/) and the project source -- every finding cites a KB doc or a file:line. The review is produced by the aid-reviewer agent in a clean context and independently verified before you see it; you approve before anything is published to an external target (PR/ticket/doc). Allocates a work-NNN folder for isolation; does not fix anything (findings hand off to /aid-fix).
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)

[Definition: `canonical/skills/aid-review/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:inherit
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE"])
  n2["REVIEW"]
  n3["VERIFY<br/>who reviews the reviewer"]
  n4{"PRESENT-FINDINGS<br/>always a hard stop -- human final say"}
  n5["PUBLISH<br/>only on approval"]
  n6(["DONE"])
  n1 --> n2
  n2 -.-> n1
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"on approval"| n5
  n4 -->|"otherwise"| n6
  n5 -.-> n4
  n5 --> n6
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidLoopBack
  class n4 aidDecision
  class n5 aidLoopBack
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
