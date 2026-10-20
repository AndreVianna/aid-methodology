---
title: 'aid-update-mvp'
description: 'Revise roadmap.md''s ## MVP section only -- the first shippable slice: its contents, the line reasoning, what was cut, and its Status field (including the…'
generatedFrom: 'canonical/skills/aid-update-mvp/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-mvp/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-mvp
- **`description`** — Revise roadmap.md's ## MVP section only -- the first shippable slice: its contents, the line reasoning, what was cut, and its Status field (including the transition to Shipped &lt;version>). Use this skill when the MVP section already carries committed content and its scope has changed. May create the ## MVP section if roadmap.md exists without one. Reads and consumes an MVP seed when one is present in `.aid/design/`; never requires one. Asks every run which previously created outputs to update alongside it -- no stored list, no tracking metadata written. Everything outside ## MVP belongs to `/aid-update-roadmap`. When roadmap.md is absent, routes to `/aid-create-roadmap` without writing anything.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;slice>] -- what to revise in the MVP section (contents, line, cuts, status)

[Definition: `canonical/skills/aid-update-mvp/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md)

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
  n3["UPDATE"]
  n4(["VERIFY"])
  n5{"PRESENT"}
  n6(["DONE"])
  n1 --> n2
  n2 -->|"when no seed was found, it has no unresolved question"| n3
  n3 --> n4
  n4 -. "when it is not clean and fewer than 3 cycles have run" .-> n3
  n4 -->|"when the verify is clean"| n5
  n5 -. "when the user asks for changes" .-> n3
  n5 -->|"when the user approves"| n6
  n5 -->|"when the user declines (the revision is rolled back first)"| n6
  class n1 aidExit
  class n2 aidExit
  class n3 aidStep
  class n4 aidExit
  class n5 aidDecision
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L56-L58" wrap
## State: INTAKE

Every question this step asks (the opening and the derived-outputs question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-update-mvp` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/mvp.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L56-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L56-L58) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L56-L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L56-L80)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L84-L87" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Only applies when a seed was
found in INTAKE.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L84-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L84-L87) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L84-L97`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L84-L97)

<a id="fragment-n3"></a>**3 · `UPDATE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L101-L107" wrap
## State: UPDATE

**Before the first edit,** copy every file this step will edit or delete (the destination, each output the user
named in INTAKE, a consumed seed and, for a promotion, `tech-debt.md`) into `rollback/` in the work folder, under the same
relative path, so PRESENT can restore them if the user declines. Copy only once: when UPDATE runs
again (after VERIFY or a requested change), a file already under `rollback/` is kept, so a decline restores
the original, not an earlier revision.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L101-L107`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L101-L107) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L101-L146`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L101-L146)

<a id="fragment-n4"></a>**4 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L150-L154" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to UPDATE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L150-L154`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L150-L154) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L150-L156`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L150-L156)

<a id="fragment-n5"></a>**5 · `PRESENT`** — hard stop -- the user decides · _decision_

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L160-L163" wrap
## State: PRESENT (hard stop -- the user decides)

Present the revised `## MVP` section clearly.
Assert:
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L160-L163`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L160-L163) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L160-L187`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L160-L187)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L191-L193" wrap
## State: DONE

Set `lifecycle` to `Completed` through the writer (`--pipeline --field Lifecycle --value Completed`), which also clears the saved skill and step.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L191-L193`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L191-L193) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L191-L195`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L191-L195)
