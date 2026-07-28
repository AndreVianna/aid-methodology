---
title: 'aid-create-document'
description: 'Create a document NOW -- markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a mermaid diagram, a table --…'
generatedFrom: 'canonical/skills/aid-create-document/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-document/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-document
- **`description`** — Create a document NOW -- markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a mermaid diagram, a table -- determining the format AND structure from the request, in one pass. Grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source. It RESOLVES NOTHING: it drafts the document, you approve, then it is placed. Produced by the aid-tech-writer agent and verified by aid-reviewer. NEVER writes into .aid/knowledge/ (that is /aid-update-kb's territory). Allocates a work-NNN folder. /aid-add-document is its alias; the genre skills (/aid-document-decision, ...) and /aid-create-diagram delegate here.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- what to document (optionally a kind: adr, runbook, tutorial, changelog, diagram, ...)

[Definition: `canonical/skills/aid-create-document/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md)

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
  n2["AUTHOR"]
  n3["VERIFY"]
  n4{"PRESENT<br/>hard stop -- human final say before placing"}
  n5["PLACE<br/>only on approval"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"on approval"| n5
  n4 -->|"else"| n6
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
