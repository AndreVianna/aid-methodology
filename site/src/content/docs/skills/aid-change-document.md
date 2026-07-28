---
title: 'aid-change-document'
description: 'Update an EXISTING document NOW -- revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, etc.'
generatedFrom: 'canonical/skills/aid-change-document/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-change-document/SKILL.md -->

## Frontmatter

- **`name`** — aid-change-document
- **`description`** — Update an EXISTING document NOW -- revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, etc. -- in one pass. Reads the existing document first, then edits it, grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source. It RESOLVES NOTHING: it drafts the change, you approve (with a diff shown), then it is written back. Produced by aid-tech-writer, verified by aid-reviewer. NEVER writes into .aid/knowledge/ (that is /aid-update-kb). /aid-update-document is its alias.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;document + change> -- which existing document to update, and how

[Definition: `canonical/skills/aid-change-document/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-change-document/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE"])
  n2["AUTHOR"]
  n3["VERIFY"]
  n4{"PRESENT"}
  n5["WRITE<br/>only on approval"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 -->|"on approval"| n5
  n4 -->|"else"| n6
  n5 -.-> n4
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
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
