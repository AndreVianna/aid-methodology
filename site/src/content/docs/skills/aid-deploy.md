---
title: 'aid-deploy'
description: 'Package completed deliveries into a release.'
generatedFrom: 'canonical/skills/aid-deploy/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-deploy/SKILL.md -->

## Frontmatter

- **`name`** — aid-deploy
- **`description`** — Package completed deliveries into a release. Use when completed deliveries are ready to ship.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write

[Definition: `canonical/skills/aid-deploy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1{"IDLE"}
  n2(["SELECTING<br/>Eligible deliveries are presented to the user for inclusion…"])
  n3(["VERIFYING<br/>Full build, tests, and lint are run against the combined…"])
  n4{"PACKAGING"}
  n5(["DONE<br/>Release complete."])
  n6(["RE-RUN<br/>When work STATE.md ## Deploy State is Done and the user…"])
  n1 -->|"otherwise"| n2
  n1 -->|"when infrastructure.md has no Deployment section, once the user answers"| n2
  n2 -. "otherwise" .- n2
  n2 -->|"once the user has chosen the deliveries and given the version and package name"| n3
  n3 -->|"after a failure, once the user chooses to fix here and the re-verification…"| n4
  n3 -->|"when every check passes"| n4
  n4 -->|"otherwise"| n5
  n4 -->|"when the project type is unclear, once the user answers"| n5
  n6 -->|"on [1] New release"| n1
  n6 -. "otherwise" .- n6
  class n1 aidDecision
  class n2 aidExit
  class n3 aidExit
  class n4 aidDecision
  class n5 aidExit
  class n6 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `IDLE`** — No active release; assess eligible deliveries and… · _decision_

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L180" wrap
| IDLE | `references/state-idle.md` | `aid-operator` | → SELECTING |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L180`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L180) · [full step: `canonical/skills/aid-deploy/references/state-idle.md#L1-L35`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-idle.md#L1-L35)

<a id="fragment-n2"></a>**2 · `SELECTING`** — Eligible deliveries are presented to the user for inclusion… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L181" wrap
| SELECTING | `references/state-selecting.md` | `aid-operator` | → VERIFYING |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L181`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L181) · [full step: `canonical/skills/aid-deploy/references/state-selecting.md#L1-L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-selecting.md#L1-L39)

<a id="fragment-n3"></a>**3 · `VERIFYING`** — Full build, tests, and lint are run against the combined… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L182" wrap
| VERIFYING | `references/state-verifying.md` | `aid-operator` | → PACKAGING |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L182`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L182) · [full step: `canonical/skills/aid-deploy/references/state-verifying.md#L1-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-verifying.md#L1-L53)

<a id="fragment-n4"></a>**4 · `PACKAGING`** — Release artifacts are produced, release notes generated, KB… · _decision_

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L183" wrap
| PACKAGING | `references/state-packaging.md` | `aid-operator` | → DONE |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L183`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L183) · [full step: `canonical/skills/aid-deploy/references/state-packaging.md#L1-L99`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-packaging.md#L1-L99)

<a id="fragment-n5"></a>**5 · `DONE`** — Release complete. · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L184" wrap
| DONE | `references/state-done.md` | `inline` | → halt |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L184`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L184) · [full step: `canonical/skills/aid-deploy/references/state-done.md#L1-L33`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-done.md#L1-L33)

<a id="fragment-n6"></a>**6 · `RE-RUN`** — When work STATE.md ## Deploy State is Done and the user… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-deploy/SKILL.md#L185" wrap
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |
~~~~

[Source: `canonical/skills/aid-deploy/SKILL.md#L185`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md#L185) · [full step: `canonical/skills/aid-deploy/references/state-re-run.md#L1-L19`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/references/state-re-run.md#L1-L19)
