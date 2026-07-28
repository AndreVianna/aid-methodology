---
title: 'aid-define'
description: 'Feature decomposition and cross-reference validation from approved requirements.'
generatedFrom: 'canonical/skills/aid-define/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-define/SKILL.md -->

## Frontmatter

- **`name`** — aid-define
- **`description`** — Feature decomposition and cross-reference validation from approved requirements. Begins from an approved REQUIREMENTS.md (produced by /aid-describe) and decomposes functional requirements into discrete feature folders with SPEC.md stubs (FEATURE-DECOMPOSITION), then validates the requirements and feature boundaries against the KB and codebase (CROSS-REFERENCE), then halts at DONE ready for /aid-specify. State machine: (Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT -> /aid-specify].
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit
- **`argument-hint`** — [work-001] decompose approved requirements  [--features work-001] re-run feature decomposition

[Definition: `canonical/skills/aid-define/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-define/SKILL.md)

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
  n1(["FEATURE-DECOMPOSITION<br/>Requirements are approved and no feature folders exist yet…"])
  n2["CROSS-REFERENCE<br/>Requirements are approved and features exist but…"]
  n3(["DONE<br/>Interview is complete, approved, features decomposed, and…"])
  n1 -. "otherwise" .- n1
  n1 -->|"when decomposition completes"| n2
  n2 -. "otherwise" .- n2
  n2 -->|"when cross-reference completes"| n3
  class n1 aidEntry
  class n2 aidLoopBack
  class n3 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
```
