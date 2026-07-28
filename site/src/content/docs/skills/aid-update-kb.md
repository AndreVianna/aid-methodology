---
title: 'aid-update-kb'
description: 'Optional on-demand targeted KB update skill.'
generatedFrom: 'canonical/skills/aid-update-kb/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-kb/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-kb
- **`description`** — Optional on-demand targeted KB update skill. Isolates itself in its own worktree, analyzes how a free-form instruction lands in the Knowledge Base (an aid-researcher Impact Map), turns that into a minimal aid-architect Scope Plan traced to the instruction (+ an explicit Not-Changing list), and pauses for an explicit human CONFIRM before any edit. Applies only the confirmed scope, reviews it through f005's four-mandate panel (scoped to the changed docs), and commits only after a second explicit human approval. State-machine: ANALYZE -> SCOPE -> CONFIRM -> APPLY -> REVIEW -> APPROVAL -> DONE (FIX loop inside REVIEW).
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;what changed / what to update in the KB>

[Definition: `canonical/skills/aid-update-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md)

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
  n1(["ANALYZE<br/>ANALYZE maps the user's instruction onto concrete KB…"])
  n2(["SCOPE<br/>SCOPE turns ANALYZE's Impact Map into the minimal Scope…"])
  n3(["CONFIRM<br/>CONFIRM is the new pre-apply human gate -- the root fix…"])
  n4["APPLY<br/>APPLY makes targeted summary+pointer edits to the KB docs…"]
  n5(["REVIEW<br/>REVIEW first runs two mechanical, -specific checks -- a"])
  n6(["APPROVAL<br/>APPROVAL is the explicit human gate before the KB change is…"])
  n7(["DONE<br/>DONE commits the approved KB changes and closes the run."])
  n1 --> n2
  n2 --> n3
  n3 --> n1
  n3 --> n4
  n4 --> n5
  n5 --> n4
  n5 -->|"grade/teach-back/act-back/TRACE-1 below gate (scope-diff already PASS) FIX…"| n6
  n6 --> n2
  n6 --> n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidExit
  class n6 aidExit
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
