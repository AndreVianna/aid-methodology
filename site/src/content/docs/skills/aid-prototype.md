---
title: 'aid-prototype'
description: 'Build a THROWAWAY low-fidelity model NOW to validate a direction before committing to a full build -- then present what it shows and hand the real build off…'
generatedFrom: 'canonical/skills/aid-prototype/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-prototype/SKILL.md -->

## Frontmatter

- **`name`** — aid-prototype
- **`description`** — Build a THROWAWAY low-fidelity model NOW to validate a direction before committing to a full build -- then present what it shows and hand the real build off to /aid-create*. It RESOLVES NOTHING (states whether the direction holds + what was learned; you decide). Isolated and throwaway: artifacts live in the work folder / an opt-in worktree and never touch production. Produced by the aid-architect agent; the validation assessment gets a LIGHT verify (the model is deliberately rough -- it is not polish-graded). For a KEPT design meant to inform the build, use /aid-design instead. Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;direction> -- the direction/hypothesis to validate (optionally: fidelity paper|low-fi|runnable-spike)

[Definition: `canonical/skills/aid-prototype/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md)

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
  n2["BUILD"]
  n3["VERIFY<br/>LIGHT -- do not polish-grade a rough model"]
  n4{"PRESENT"}
  n5["HANDOFF<br/>optional; printed suggestions only"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"optional"| n5
  n4 --> n6
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
