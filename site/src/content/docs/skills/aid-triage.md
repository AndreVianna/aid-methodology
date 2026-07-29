---
title: 'aid-triage'
description: 'Suggest-only router for "I don''t know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the…'
generatedFrom: 'canonical/skills/aid-triage/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-triage/SKILL.md -->

## Frontmatter

- **`name`** — aid-triage
- **`description`** — Suggest-only router for "I don't know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the single best entry: the matching aid-&lt;verb>[-&lt;artifact>] shortcut for a known single change-type, or the full path via /aid-describe for broad or ambiguous work. Reads canonical/aid/templates/shortcut-catalog.yml to resolve the suggestion to a canonical (non-alias) name. Routes and suggests only -- no interview, no scaffold, no work folder, no STATE.md. State machine: INTAKE -> CLASSIFY -> SUGGEST -> HALT.
- **`allowed-tools`** — Read, Glob, Grep
- **`argument-hint`** — [description]  -- what you want to do; I'll point you at the right entry

[Definition: `canonical/skills/aid-triage/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["INTAKE<br/>Capture one short free-form description in a single turn…"])
  n2["CLASSIFY<br/>From {description} (captured at INTAKE), infer three things…"]
  n3["SUGGEST<br/>Emits the NFR-7 reflect-back straw-man turn proposing the…"]
  n4(["HALT<br/>Print the recommended invocation the user should type next…"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
