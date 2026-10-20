---
title: 'aid-create-backlog'
description: 'Realize a ready backlog seed into `.aid/knowledge/backlog.md` -- frontmatter, preamble, ## Contents index, ## Next Release, ## Prioritized, and ## Gotchas.'
generatedFrom: 'canonical/skills/aid-create-backlog/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-backlog/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-backlog
- **`description`** — Realize a ready backlog seed into `.aid/knowledge/backlog.md` -- frontmatter, preamble, ## Contents index, ## Next Release, ## Prioritized, and ## Gotchas. Use this skill when a backlog seed is ready and the project needs its backlog document written for the first time. Moves accepted tech-debt.md items into backlog.md in the same run (id unchanged; row deleted from tech-debt.md). Registers the document in `.aid/settings.yml` and `.aid/knowledge/README.md` on first creation. Routes to `/aid-update-backlog` when the item sections already carry committed content.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;direction>] -- which items to accept and how to prioritize them (fills item sections from the seed)

[Definition: `canonical/skills/aid-create-backlog/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md)

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
  n2(["GUARD"])
  n3(["REALIZE"])
  n4["REGISTER"]
  n5(["VERIFY"])
  n6["PRESENT<br/>hard stop -- the user decides"]
  n7(["DONE"])
  n1 -->|"once the seed question is settled"| n2
  n2 -->|"when the gate passes"| n3
  n3 -->|"when the document is written"| n4
  n4 --> n5
  n5 -. "when it is not clean and fewer than 3 cycles have run" .-> n3
  n5 -->|"when the verify is clean"| n6
  n6 -. "when the user declines or asks for changes" .-> n3
  n6 -->|"when the user approves"| n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidExit
  class n6 aidLoopBack
  class n7 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L46-L59" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What items do
   you want to accept into the backlog -- or run `/aid-design-backlog` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-create-backlog`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Read the seed** at `.aid/design/backlog.md`. If no seed exists, inform the user and
   ask whether to proceed without one (items entered interactively) or to run
   `/aid-design-backlog` first; do not proceed silently. The question blocks the work: pause INTAKE on it, with its detail saying the work is allocated and the question is open, record it with `--ask`, set the lifecycle to `Paused-Awaiting-Input` and the pause reason to the open question, and then ask it. Once it is answered, record the answer with `--answer` and set the lifecycle back to `Running` through the writer. If the user proceeds without a seed, INTAKE continues at step 4. If the user chooses to design the seed first, bring the detail up to date with `--step` (done: work allocated; waiting for the seed from `/aid-design-backlog`), set the lifecycle to `Paused-Awaiting-Input` and the pause reason to 'Waiting for the seed: run /aid-design-backlog, then resume' through the writer, name `/aid-design-backlog` in one plain line, and end the step with the HALT case of the advance line below.
4. **Read the destination** at `.aid/knowledge/backlog.md` if it exists. Classify its
   state: absent | present-sections-empty | present-sections-populated.
5. **Read `tech-debt.md`** at `.aid/knowledge/tech-debt.md` if it exists. The seed may
   name candidate rows to promote; know their current state before the confirm gate runs.
6. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L46-L59`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L46-L59) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L46-L61`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L46-L61)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L65-L68" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a non-empty
`## Open questions` section per `design-lifecycle.md`'s detection rule.
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L65-L68`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L65-L68) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L65-L75`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L65-L75)

<a id="fragment-n3"></a>**3 · `REALIZE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L79-L84" wrap
## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the case
determined in INTAKE. The worker never asks the user: it returns the questions below
(the route question, each per-item confirm gate and any undetermined `Tag`) and the main
conversation asks them, through the question protocol.
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L79-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L79-L84) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L79-L183`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L79-L183)

<a id="fragment-n4"></a>**4 · `REGISTER`** · _step_

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L187-L190" wrap
## State: REGISTER

**On creation only** (destination was absent in INTAKE). Write two surfaces atomically
in the same run, per `feature-003 §6b` (REQUIREMENTS CC-1, CC-2):
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L187-L190`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L187-L190) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L187-L202`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L187-L202)

<a id="fragment-n5"></a>**5 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L206-L210" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L206-L210`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L206-L210) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L206-L212`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L206-L212)

<a id="fragment-n6"></a>**6 · `PRESENT`** — hard stop -- the user decides · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L216-L218" wrap
## State: PRESENT (hard stop -- the user decides)

Present the realized document clearly. Assert:
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L216-L218`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L216-L218) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L216-L228`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L216-L228)

<a id="fragment-n7"></a>**7 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-create-backlog/SKILL.md#L232-L234" wrap
## State: DONE

Set the lifecycle to `Completed` through the writer.
~~~~

[Source: `canonical/skills/aid-create-backlog/SKILL.md#L232-L234`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L232-L234) · [full step: `canonical/skills/aid-create-backlog/SKILL.md#L232-L234`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-backlog/SKILL.md#L232-L234)
