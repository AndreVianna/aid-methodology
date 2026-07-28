---
title: 'aid-design'
description: 'Produce a KEPT design artifact NOW -- a UX/interaction flow, a component or interface design, an architecture sketch, with accessibility notes -- meant to…'
generatedFrom: 'canonical/skills/aid-design/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design/SKILL.md -->

## Frontmatter

- **`name`** — aid-design
- **`description`** — Produce a KEPT design artifact NOW -- a UX/interaction flow, a component or interface design, an architecture sketch, with accessibility notes -- meant to inform the real build. Single-shot; grounded in the Knowledge Base (.aid/knowledge/) and the project source (patterns, conventions, architecture). It RESOLVES NOTHING: it presents the design; you decide, and the build is a separate /aid-create* step. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify -- a kept design drives a build, so its correctness matters). For a THROWAWAY model to merely validate a direction, use /aid-prototype instead. Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- what to design (a flow, a component/interface, a UI, an architecture sketch)

[Definition: `canonical/skills/aid-design/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design/SKILL.md)

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
  n2["DESIGN"]
  n3["VERIFY<br/>full -- a kept design drives a build"]
  n4{"PRESENT"}
  n5["HANDOFF<br/>optional; printed suggestions only"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -.-> n2
  n4 -->|"optional"| n5
  n4 --> n6
  n5 --> n6
  n6 -.-> n2
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
