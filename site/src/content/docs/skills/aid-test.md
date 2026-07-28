---
title: 'aid-test'
description: 'Run a test suite / verification NOW and consolidate the results into findings, in one pass.'
generatedFrom: 'canonical/skills/aid-test/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-test/SKILL.md -->

## Frontmatter

- **`name`** — aid-test
- **`description`** — Run a test suite / verification NOW and consolidate the results into findings, in one pass. Generic: it runs whatever the request implies -- unit/integration/ e2e, a security scan (SAST/DAST/fuzz/dependency-audit), a performance benchmark/load/stress test, a data-quality check (schema/freshness/completeness/ uniqueness), or a model evaluation -- and reports. It RESOLVES NOTHING and is read-only on the source: findings hand off to /aid-fix; it never fixes. The skill runs the tool itself (read-only); consolidation + verification are done by the aid-reviewer agent (review-shaped). Allocates a work-NNN folder. To AUTHOR test code, use /aid-create-test (a keep-cycle create-family skill), not this.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;target> -- what to test/verify (a suite/module, or a kind: security, performance, data-quality, model-eval)

[Definition: `canonical/skills/aid-test/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md)

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
  n2["RUN"]
  n3["VERIFY"]
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
