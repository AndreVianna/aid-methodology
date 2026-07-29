---
title: 'aid-document'
description: 'Write a general document NOW -- a Diataxis how-to / reference / explanation, or a status/progress report -- in one pass.'
generatedFrom: 'canonical/skills/aid-document/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-document/SKILL.md -->

## Frontmatter

- **`name`** — aid-document
- **`description`** — Write a general document NOW -- a Diataxis how-to / reference / explanation, or a status/progress report -- in one pass. A thin kind-sibling of /aid-create-document with the document genre bound to general. Grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer, verified by aid-reviewer. It RESOLVES NOTHING -- drafts, you approve, then it is placed. NEVER writes into .aid/knowledge/. This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-create-document/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- what to document

[Definition: `canonical/skills/aid-document/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-document/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-document<br/>{verb: document, artifact: &quot;&quot;}"])
  n2(["INTAKE"])
  n3["AUTHOR"]
  n4["VERIFY"]
  n5{"PRESENT"}
  n6["PLACE<br/>only on approval"]
  n7(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 -.-> n3
  n4 --> n5
  n5 -->|"on approval"| n6
  n5 -->|"else"| n7
  n6 --> n7
  class n1 aidEntry
  class n2 aidEntry
  class n3 aidStep
  class n4 aidLoopBack
  class n5 aidDecision
  class n6 aidStep
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
