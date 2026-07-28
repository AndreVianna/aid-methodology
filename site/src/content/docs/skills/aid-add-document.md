---
title: 'aid-add-document'
description: 'Alias of /aid-create-document -- create a document NOW (markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a…'
generatedFrom: 'canonical/skills/aid-add-document/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-add-document/SKILL.md -->

## Frontmatter

- **`name`** — aid-add-document
- **`description`** — Alias of /aid-create-document -- create a document NOW (markdown/reference/how-to, an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a mermaid diagram, a table), determining the format AND structure from the request, in one pass. Grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer, verified by aid-reviewer. It RESOLVES NOTHING -- drafts, you approve, then it is placed. NEVER writes into .aid/knowledge/. This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-create-document/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- what to document

[Definition: `canonical/skills/aid-add-document/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-add-document/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
flowchart TB
  classDef aidNode color:inherit
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ENTRY<br/>Entry"])
  n2["RUN<br/>Run Alias of /aid-create-document -- create a document NOW…"]
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
