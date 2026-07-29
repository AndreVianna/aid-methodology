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
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["FIRST-RUN<br/>This state runs only when STATE.md ## Interview State does…"])
  n2["Q-AND-A<br/>STATE.md ## Cross-phase Q&amp;A has entries with Status…"]
  n3{"CONTINUE"}
  n4["DESCRIBE-SEED<br/>The seed-authoring step of aid-describe (the aid-describe…"]
  n5(["COMPLETION<br/>All sections are Complete or N/A in STATE.md ## Interview…"])
  n1 -->|"after scaffolding is complete"| n3
  n1 -->|"emits the D1 opener and runs the full-path interview"| n3
  n2 --> n3
  n3 -. "otherwise" .- n3
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
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `FIRST-RUN`** — This state runs only when STATE.md ## Interview State does… · _entry_

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L273" wrap
| FIRST-RUN | `references/state-first-run.md` | `aid-interviewer` | → CONTINUE |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L273`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L273) · [full step: `canonical/skills/aid-describe/references/state-first-run.md#L1-L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-first-run.md#L1-L112)

<a id="fragment-n2"></a>**2 · `Q-AND-A`** — STATE.md ## Cross-phase Q&amp;A has entries with Status… · _step_

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L274" wrap
| Q-AND-A | `references/state-q-and-a.md` | `aid-interviewer` | → CONTINUE |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L274`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L274) · [full step: `canonical/skills/aid-describe/references/state-q-and-a.md#L1-L65`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-q-and-a.md#L1-L65)

<a id="fragment-n3"></a>**3 · `CONTINUE`** — Resume the conversational interview; STATE.md shows In… · _decision_

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L275" wrap
| CONTINUE | `references/state-continue.md` | `aid-interviewer` | → DESCRIBE-SEED (greenfield: no brownfield KB on disk and seed not yet complete) / → COMPLETION (brownfield or seed already complete) |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L275`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L275) · [full step: `canonical/skills/aid-describe/references/state-continue.md#L1-L44`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-continue.md#L1-L44)

<a id="fragment-n4"></a>**4 · `DESCRIBE-SEED`** — The seed-authoring step of aid-describe (the aid-describe… · _step_

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L276" wrap
| DESCRIBE-SEED | `references/state-describe-seed.md` | `aid-interviewer` | → COMPLETION |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L276`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L276) · [full step: `canonical/skills/aid-describe/references/state-describe-seed.md#L1-L511`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-describe-seed.md#L1-L511)

<a id="fragment-n5"></a>**5 · `COMPLETION`** — All sections are Complete or N/A in STATE.md ## Interview… · _exit_ · PAUSE-FOR-USER-DECISION

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L277" wrap
| COMPLETION | `references/state-completion.md` | `aid-interviewer` | PAUSE-FOR-USER-DECISION → Run /aid-define {work} |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L277`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L277) · [full step: `canonical/skills/aid-describe/references/state-completion.md#L1-L140`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-completion.md#L1-L140)
