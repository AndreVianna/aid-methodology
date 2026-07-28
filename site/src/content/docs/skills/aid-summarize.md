---
title: 'aid-summarize'
description: 'Generate a single-file kb.html from .aid/knowledge/.'
generatedFrom: 'canonical/skills/aid-summarize/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-summarize/SKILL.md -->

## Frontmatter

- **`name`** — aid-summarize
- **`description`** — Generate a single-file kb.html from .aid/knowledge/. Domain-driven, doc-set-based: one section per resolved doc derived from frontmatter (kb-category, objective, summary, tags, see_also). Audience: non-technical newcomer (visually rich; no KB authoring-rules leakage). Light/dark theme, click-to-expand lightbox, accessibility-first (WCAG AA). Two-grade quality gate (Machine + Human): script-verifiable checks score the Machine Grade; an interactive checklist scores the Human Grade (K1 KB-completeness, K2 fact-grounding, V1 mandatory human visual gate). APPROVAL requires BOTH grades >= minimum. Idempotent: re-running on an unchanged KB does nothing. State-machine: PREFLIGHT -> STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> MANUAL-CHECKLIST -> FIX -> APPROVAL -> WRITEBACK -> DONE.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit
- **`argument-hint`** — [--grade X] override minimum  [--theme default|brand-X]  [--reset]

[Definition: `canonical/skills/aid-summarize/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-summarize/SKILL.md)

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
  n2(["STALE-CHECK<br/>STALE-CHECK compares the KB review date against the last…"])
  n3["PROFILE<br/>PROFILE reads the doc-set and domain from feature-014…"]
  n4["GENERATE<br/>GENERATE builds kb.html from KB content using the resolved…"]
  n5{"VALIDATE<br/>VALIDATE runs the machine-verifiable quality checks…"}
  n6{"MANUAL-CHECKLIST<br/>MANUAL-CHECKLIST elicits human-judgment answers for the…"}
  n7["FIX<br/>FIX handles objective machine-pool failures autonomously…"]
  n8(["APPROVAL<br/>APPROVAL presents the graded summary to the user for final…"])
  n9["WRITEBACK<br/>WRITEBACK atomically records the approved summarization…"]
  n10(["DONE<br/>DONE confirms the summarization is complete and the…"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 -->|"if Machine Grade &gt;= minimum"| n6
  n5 -->|"otherwise. Both continue inline"| n7
  n6 -->|"otherwise. Both continue inline"| n7
  n6 -->|"if Overall Grade ≥ minimum"| n8
  n7 --> n5
  n8 -->|"no writeback). If user said &quot;changes needed&quot;: (continue inline"| n7
  n8 -->|"If user approved"| n9
  n9 --> n10
  class n1 aidEntry
  class n2 aidExit
  class n3 aidStep
  class n4 aidStep
  class n5 aidDecision
  class n6 aidDecision
  class n7 aidStep
  class n8 aidExit
  class n9 aidStep
  class n10 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
  class n10 aidNode
```
