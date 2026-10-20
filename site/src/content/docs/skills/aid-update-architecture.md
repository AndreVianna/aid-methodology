---
title: 'aid-update-architecture'
description: 'Revise the project''s build-and-shape (C1) Knowledge Base document -- components and their responsibilities, boundaries, interactions, and the invariants a…'
generatedFrom: 'canonical/skills/aid-update-architecture/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-architecture/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-architecture
- **`description`** — Revise the project's build-and-shape (C1) Knowledge Base document -- components and their responsibilities, boundaries, interactions, and the invariants a change must not break -- plus any previously created outputs you name. Use this skill when the architecture document already exists and part of it needs revising. Requires no design seed: the change you state in the run is a sufficient input. Reads and consumes an architecture seed when one is present in `.aid/design/`. When the C1 document does not yet exist, routes to `/aid-create-architecture`. To write documentation ABOUT an architecture rather than revise the KB record, use `/aid-document-architecture`. Produced by the aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;change> -- what to revise in the architecture record

[Definition: `canonical/skills/aid-update-architecture/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md)

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
  n2["UPDATE"]
  n3(["VERIFY"])
  n4{"PRESENT"}
  n5(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -. "when it is not clean and fewer than 3 cycles have run" .-> n2
  n3 -->|"when the verify is clean"| n4
  n4 -. "when the user asks for changes" .-> n2
  n4 -->|"when the user approves"| n5
  n4 -->|"when the user declines (the revision is rolled back first)"| n5
  class n1 aidExit
  class n2 aidStep
  class n3 aidExit
  class n4 aidDecision
  class n5 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-architecture/SKILL.md#L51-L53" wrap
## State: INTAKE

Every question this step asks (the opening, the destination confirmation and the derived-outputs question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-update-architecture` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/architecture.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.
~~~~

[Source: `canonical/skills/aid-update-architecture/SKILL.md#L51-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L51-L53) · [full step: `canonical/skills/aid-update-architecture/SKILL.md#L51-L83`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L51-L83)

<a id="fragment-n2"></a>**2 · `UPDATE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-architecture/SKILL.md#L87-L93" wrap
## State: UPDATE

**Before the first edit,** copy every file this step will edit or delete (the destination, each output the user
named in INTAKE, a consumed seed and, for a promotion, `tech-debt.md`) into `rollback/` in the work folder, under the same
relative path, so PRESENT can restore them if the user declines. Copy only once: when UPDATE runs
again (after VERIFY or a requested change), a file already under `rollback/` is kept, so a decline restores
the original, not an earlier revision.
~~~~

[Source: `canonical/skills/aid-update-architecture/SKILL.md#L87-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L87-L93) · [full step: `canonical/skills/aid-update-architecture/SKILL.md#L87-L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L87-L102)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-architecture/SKILL.md#L106-L109" wrap
## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-update-architecture/SKILL.md#L106-L109`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L106-L109) · [full step: `canonical/skills/aid-update-architecture/SKILL.md#L106-L111`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L106-L111)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user decides · _decision_

~~~~plaintext title="canonical/skills/aid-update-architecture/SKILL.md#L115-L117" wrap
## State: PRESENT (hard stop -- the user decides)

Present the revision, name every output touched, and assert that a consumed seed is gone.
~~~~

[Source: `canonical/skills/aid-update-architecture/SKILL.md#L115-L117`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L115-L117) · [full step: `canonical/skills/aid-update-architecture/SKILL.md#L115-L130`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L115-L130)

<a id="fragment-n5"></a>**5 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-architecture/SKILL.md#L134-L136" wrap
## State: DONE

Set `lifecycle` to `Completed` through the writer (`--pipeline --field Lifecycle --value Completed`), which also clears the saved skill and step.
~~~~

[Source: `canonical/skills/aid-update-architecture/SKILL.md#L134-L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L134-L136) · [full step: `canonical/skills/aid-update-architecture/SKILL.md#L134-L138`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-architecture/SKILL.md#L134-L138)
