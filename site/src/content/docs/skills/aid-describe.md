---
title: 'aid-describe'
description: 'Conversational requirements gathering through adaptive interview, driven by the seasoned-analyst elicitation engine (references/elicitation-engine.md): one…'
generatedFrom: 'canonical/skills/aid-describe/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-describe/SKILL.md -->

## Frontmatter

- **`name`** — aid-describe
- **`description`** — Conversational requirements gathering through adaptive interview, driven by the seasoned-analyst elicitation engine (references/elicitation-engine.md): one fixed D1 opener plus a deterministic five-step next-move selector (stop check, gap selection, move selection, calibration shaping, NFR-7 envelope + emit). First run builds REQUIREMENTS.md incrementally. Subsequent runs resume the interview for incomplete sections. Final step presents approved requirements for handoff to /aid-define. State machine: FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> /aid-define].
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit
- **`argument-hint`** — [work-001] resume work  [--reset work-001] clear and restart

[Definition: `canonical/skills/aid-describe/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md)

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
  n1(["FIRST-RUN<br/>This state runs only when STATE.md does not exist in the…"])
  n2["Q-AND-A<br/>STATE.md has entries with ; resolve them one at a time…"]
  n3{"CONTINUE<br/>Resume the conversational interview; STATE.md shows In…"}
  n4["DESCRIBE-SEED<br/>The seed-authoring step of (the step per D3, executed today…"]
  n5(["COMPLETION<br/>All sections are Complete or N/A in STATE.md ; run quality…"])
  n1 -->|"after scaffolding is complete"| n3
  n1 -->|"emits the D1 opener and runs the full-path interview"| n3
  n2 --> n3
  n3 -. "otherwise" .-> n3
  n3 -->|"greenfield: no brownfield KB on disk and seed not yet complete"| n4
  n3 -->|"when all sections are Complete or N/A"| n5
  n4 --> n5
  n5 -.-> n2
  class n1 aidEntry
  class n2 aidStep
  class n3 aidDecision
  class n4 aidStep
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
