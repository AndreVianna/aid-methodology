---
title: 'aid-design-integration'
description: 'Develop an external-service integration design as a DESIGN SEED in `.aid/design/integration.md` -- the external service, the client/adapter surface, and the…'
generatedFrom: 'canonical/skills/aid-design-integration/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-design-integration/SKILL.md -->

## Frontmatter

- **`name`** — aid-design-integration
- **`description`** — Develop an external-service integration design as a DESIGN SEED in `.aid/design/integration.md` -- the external service, the client/adapter surface, and the auth and failure modes. Use this skill when how to talk to an external service is still being worked out, including how failures should behave. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO production code and NO KB document -- realize the seed into the built client/adapter with `/aid-create-integration` once it is ready. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify).
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;subject> -- the integration to design (service, client surface, auth/failure)

[Definition: `canonical/skills/aid-design-integration/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md)

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

~~~~plaintext title="canonical/skills/aid-design-integration/SKILL.md#L38-L46" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   integration do you want to design -- the service, its client surface, and its auth and
   failure modes?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/integration.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-integration`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/integration.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/integration.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/integration.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/integration.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/integration.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
~~~~

[Source: `canonical/skills/aid-design-integration/SKILL.md#L38-L46`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L38-L46) · [full step: `canonical/skills/aid-design-integration/SKILL.md#L38-L52`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L38-L52)

<a id="fragment-n2"></a>**2 · `DESIGN`** · _step_

~~~~plaintext title="canonical/skills/aid-design-integration/SKILL.md#L56-L64" wrap
## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/integration.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the external service, the
client/adapter surface, and the auth and failure modes**; its `## Destination` names where
the built client/adapter lands. **Never writes `.aid/knowledge/` and never writes
production code** -- the `design` invariant (`design-lifecycle.md`).
~~~~

[Source: `canonical/skills/aid-design-integration/SKILL.md#L56-L64`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L56-L64) · [full step: `canonical/skills/aid-design-integration/SKILL.md#L56-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L56-L66)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-design-integration/SKILL.md#L70-L73" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/integration.md --detail 'impediment: <reason>'`.
~~~~

[Source: `canonical/skills/aid-design-integration/SKILL.md#L70-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L70-L73) · [full step: `canonical/skills/aid-design-integration/SKILL.md#L70-L75`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L70-L75)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-design-integration/SKILL.md#L79-L82" wrap
## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-integration`).
~~~~

[Source: `canonical/skills/aid-design-integration/SKILL.md#L79-L82`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L79-L82) · [full step: `canonical/skills/aid-design-integration/SKILL.md#L79-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L79-L87)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-design-integration/SKILL.md#L91-L94" wrap
## State: DONE

Record the step with `--step DONE --design .aid/design/integration.md --detail 'approved'`. The seed
persists at `.aid/design/integration.md`; consumption happens at `/aid-create-integration`.
~~~~

[Source: `canonical/skills/aid-design-integration/SKILL.md#L91-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L91-L94) · [full step: `canonical/skills/aid-design-integration/SKILL.md#L91-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-design-integration/SKILL.md#L91-L94)
