---
title: 'aid-design-ui'
description: 'Develop a UI design as a DESIGN SEED in `.aid/design/ui.md` -- the screen/flow structure, the interaction model, and accessibility notes.'
generatedFrom: 'canonical/skills/aid-design-ui/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-ui/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-ui
- **`description`** — Develop a UI design as a DESIGN SEED in `.aid/design/ui.md` -- the screen/flow structure, the interaction model, and accessibility notes. Use this skill when a screen's layout and behaviour are still being worked out and you want a design you intend to keep. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO production code and NO KB document -- realize the seed into the built component/page with `/aid-create-ui` once it is ready. For a THROWAWAY low-fidelity mock that merely validates a UX direction rather than a kept design, use `/aid-prototype-ui` instead. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify).
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the UI screen(s)/flow to design (structure, interaction, accessibility)

[Definition: `canonical/skills/aid-design-ui/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md)

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
  n3(["VERIFY"])
  n4["PRESENT<br/>hard stop -- the user decides"]
  n5(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 -. "when the user declines or asks for changes" .-> n2
  n4 -->|"when the user approves"| n5
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n4 aidLoopBack
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-design-ui/SKILL.md#L41-L48" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What UI
   screen(s) or flow do you want to design, and what must it support?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/ui.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-ui`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/ui.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/ui.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/ui.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/ui.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/ui.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-ui/SKILL.md#L41-L48`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L41-L48) · [full step: `canonical/skills/aid-design-ui/SKILL.md#L41-L54`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L41-L54)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-ui/SKILL.md#L58-L66" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/ui.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the screen and flow structure, the
interaction model, and accessibility notes**; its `## Destination` names where the built
component/page lands. **Never writes `.aid/knowledge/` and never writes production code**
-- the `design` invariant (`design-lifecycle.md`).
~~~~

[Source: `canonical/skills/aid-design-ui/SKILL.md#L58-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L58-L66) · [full step: `canonical/skills/aid-design-ui/SKILL.md#L58-L68`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L58-L68)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-ui/SKILL.md#L72-L75" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/ui.md --detail 'impediment: <reason>'`.
~~~~

[Source: `canonical/skills/aid-design-ui/SKILL.md#L72-L75`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L72-L75) · [full step: `canonical/skills/aid-design-ui/SKILL.md#L72-L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L72-L77)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-ui/SKILL.md#L81-L84" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-ui`).
~~~~

[Source: `canonical/skills/aid-design-ui/SKILL.md#L81-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L81-L84) · [full step: `canonical/skills/aid-design-ui/SKILL.md#L81-L89`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L81-L89)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-ui/SKILL.md#L93-L96" wrap
## State: DONE

Record the step with `--step DONE --design .aid/design/ui.md --detail 'approved'`. The seed
persists at `.aid/design/ui.md`; consumption happens at `/aid-create-ui`.
~~~~

[Source: `canonical/skills/aid-design-ui/SKILL.md#L93-L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L93-L96) · [full step: `canonical/skills/aid-design-ui/SKILL.md#L93-L96`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-ui/SKILL.md#L93-L96)
