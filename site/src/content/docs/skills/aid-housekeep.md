---
title: 'aid-housekeep'
description: 'Optional on-demand housekeeping skill.'
generatedFrom: 'canonical/skills/aid-housekeep/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-housekeep/SKILL.md -->

## Frontmatter

- **`name`** — aid-housekeep
- **`description`** — Optional on-demand housekeeping skill. Runs three gated jobs in strict order: KB-DELTA (re-discover changed docs since last KB approval; brownfield docs take the doc&lt;-code drift path, while source: forward-authored greenfield docs take the Conformance Lane -- a code->design shadow-extract that FLAGS design vs as-built divergence for human reconciliation and never auto-overwrites the design) → SUMMARY-DELTA (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale work-area artifacts). Each stage commits its own changes on an aid/housekeep-* branch; the skill never pushes. Re-entrant: a stalled run resumes at the stalled stage on re-invocation. State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE. Source-driven global reconcile; for a targeted prompt-named delta use /aid-update-kb.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [--cleanup-only] [--grade X] jump to cleanup stage, or set minimum summary grade

[Definition: `canonical/skills/aid-housekeep/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-housekeep/SKILL.md)

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
  n1(["PREFLIGHT<br/>PREFLIGHT is the synchronous gate that verifies all…"])
  n2(["KB-DELTA<br/>KB-DELTA is a lightweight, drift-focused re-discovery: you…"])
  n3(["SUMMARY-DELTA<br/>SUMMARY-DELTA checks whether needs to be regenerated after…"])
  n4["CLEANUP<br/>CLEANUP is the terminal gated stage of ."]
  n5(["DONE<br/>DONE is the terminal state."])
  n1 --> n2
  n1 --> n4
  n2 --> n3
  n3 --> n4
  n4 --> n5
  class n1 aidEntry
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
