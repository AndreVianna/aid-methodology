---
title: 'aid-monitor'
description: 'Watch production and route what it finds back into the pipeline.'
generatedFrom: 'canonical/skills/aid-monitor/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-monitor/SKILL.md -->

## Frontmatter

- **`name`** — aid-monitor
- **`description`** — Watch production and route what it finds back into the pipeline. Use when a release has shipped or production misbehaves.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write

[Definition: `canonical/skills/aid-monitor/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["OBSERVE<br/>No prior run context; pull telemetry signals and correlate…"])
  n2["CLASSIFY<br/>Active findings are present; classify each anomaly and…"]
  n3(["ROUTE<br/>All findings are classified; propose and execute routing…"])
  n4(["DONE"])
  n1 --> n2
  n2 --> n3
  n4 -->|"when the user asks for a new observation"| n1
  class n1 aidEntry
  class n2 aidStep
  class n3 aidExit
  class n4 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `OBSERVE`** — No prior run context; pull telemetry signals and correlate… · _entry_

~~~~plaintext title="canonical/skills/aid-monitor/SKILL.md#L190" wrap
| OBSERVE | `references/state-observe.md` | `aid-researcher` | CHAIN → CLASSIFY |
~~~~

[Source: `canonical/skills/aid-monitor/SKILL.md#L190`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md#L190) · [full step: `canonical/skills/aid-monitor/references/state-observe.md#L1-L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/references/state-observe.md#L1-L51)

<a id="fragment-n2"></a>**2 · `CLASSIFY`** — Active findings are present; classify each anomaly and… · _step_

~~~~plaintext title="canonical/skills/aid-monitor/SKILL.md#L191" wrap
| CLASSIFY | `references/state-classify.md` | `aid-researcher` | CHAIN → ROUTE |
~~~~

[Source: `canonical/skills/aid-monitor/SKILL.md#L191`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md#L191) · [full step: `canonical/skills/aid-monitor/references/state-classify.md#L1-L46`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/references/state-classify.md#L1-L46)

<a id="fragment-n3"></a>**3 · `ROUTE`** — All findings are classified; propose and execute routing… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-monitor/SKILL.md#L192" wrap
| ROUTE | `references/state-route.md` | `inline` (main conversation) | HALT |
~~~~

[Source: `canonical/skills/aid-monitor/SKILL.md#L192`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md#L192) · [full step: `canonical/skills/aid-monitor/references/state-route.md#L1-L74`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/references/state-route.md#L1-L74)

<a id="fragment-n4"></a>**4 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-monitor/SKILL.md#L193" wrap
| DONE | _(inline — see Re-run below)_ | `inline` | CHAIN → OBSERVE when the user asks for a new observation; HALT otherwise |
~~~~

[Source: `canonical/skills/aid-monitor/SKILL.md#L193`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md#L193)
