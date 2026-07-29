---
title: 'aid-test-security'
description: 'Run a security verification NOW -- SAST, DAST, fuzzing, or dependency audit -- and consolidate findings.'
generatedFrom: 'canonical/skills/aid-test-security/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-test-security/SKILL.md -->

## Frontmatter

- **`name`** — aid-test-security
- **`description`** — Run a security verification NOW -- SAST, DAST, fuzzing, or dependency audit -- and consolidate findings. A thin kind-sibling of /aid-test with the verification kind bound to security. Read-only; resolves nothing; findings hand off to /aid-fix. This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-test/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;target> -- the endpoint/module/dependency set to verify

[Definition: `canonical/skills/aid-test-security/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test-security/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-test-security<br/>{verb: test, artifact: security}"])
  n2(["INTAKE"])
  n3["RUN"]
  n4["VERIFY"]
  n5{"PRESENT"}
  n6["HANDOFF<br/>optional; printed suggestions only"]
  n7(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 -.-> n3
  n4 --> n5
  n5 -->|"optional"| n6
  n5 --> n7
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
