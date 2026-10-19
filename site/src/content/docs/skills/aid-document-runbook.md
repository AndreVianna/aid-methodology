---
title: 'aid-document-runbook'
description: 'Write a runbook in one pass -- an operational procedure, from trigger through diagnostic and remediation to escalation.'
generatedFrom: 'canonical/skills/aid-document-runbook/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-document-runbook/SKILL.md -->

## Frontmatter

- **`name`** — aid-document-runbook
- **`description`** — Write a runbook in one pass -- an operational procedure, from trigger through diagnostic and remediation to escalation. Use this skill when you already know the document you need is runbook, and want it drafted now rather than planned. It is grounded in, and accuracy- checked against, the Knowledge Base (`.aid/knowledge/`) and the project source; aid-tech- writer produces it and aid-reviewer verifies it. It resolves nothing: it drafts, you approve, and only then is the document placed. It never writes into `.aid/knowledge/`. A thin kind-sibling of `/aid-create-document`, which defines its full behavior.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;operation/alert> -- the runbook

[Definition: `canonical/skills/aid-document-runbook/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-document-runbook/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-document-runbook<br/>{verb: document, artifact: runbook}"])
  n2(["INTAKE"])
  n3["INTAKE-ASK<br/>only when a question must be put"]
  n4["ALLOCATE"]
  n5["AUTHOR"]
  n6["VERIFY"]
  n7["PRESENT<br/>hard stop -- human final say before placing"]
  n8["PLACE<br/>only on approval"]
  n9(["DONE"])
  n1 --> n2
  n2 -->|"when the argument is empty, the path is Guided"| n3
  n2 -->|"works exist; otherwise"| n4
  n3 --> n4
  n4 -. "otherwise" .- n4
  n4 -->|"on a new work; a continuation follows the gate's § 3b instead"| n5
  n5 --> n6
  n6 -.-> n5
  n6 --> n7
  n7 --> n8
  n8 --> n9
  class n1 aidEntry
  class n2 aidEntry
  class n3 aidStep
  class n4 aidLoopBack
  class n5 aidStep
  class n6 aidLoopBack
  class n7 aidStep
  class n8 aidStep
  class n9 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
  class n9 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `aid-document-runbook`** — {verb: document, artifact: runbook} · _entry_

~~~~plaintext title="canonical/skills/aid-document-runbook/SKILL.md#L19" wrap
row (`alias_of: null`, its own `{verb: document, artifact: runbook}`), `repurpose: true`
~~~~

[Source: `canonical/skills/aid-document-runbook/SKILL.md#L19`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-document-runbook/SKILL.md#L19)

<a id="fragment-n2"></a>**2 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L48-L50" wrap
## State: INTAKE

INTAKE and INTAKE-ASK run before any work exists, so they save no steps (`skill-steps.md`, "Before a work exists"). Their questions are asked through the question protocol, and their answers go into the record when ALLOCATE creates it.
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L48-L50`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L48-L50) · [full step: `canonical/skills/aid-create-document/SKILL.md#L48-L67`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L48-L67)

<a id="fragment-n3"></a>**3 · `INTAKE-ASK`** — only when a question must be put · _step_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L71-L73" wrap
## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L71-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L71-L73) · [full step: `canonical/skills/aid-create-document/SKILL.md#L71-L80`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L71-L80)

<a id="fragment-n4"></a>**4 · `ALLOCATE`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L84-L87" wrap
## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L84-L87`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L84-L87) · [full step: `canonical/skills/aid-create-document/SKILL.md#L84-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L84-L103)

<a id="fragment-n5"></a>**5 · `AUTHOR`** · _step_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L107-L114" wrap
## State: AUTHOR

Dispatch **`aid-tech-writer`** (clean context, tiered) to write the document in the resolved
format + genre structure, **grounded in and accurate to** the KB + project source
(`task-type-rules.md ## DOCUMENT` -- verify accuracy against the current codebase and KB).
It drafts into the work folder (not yet placed). Text formats are produced natively
(markdown, mermaid, HTML, CSV/tables); for a format it cannot cleanly emit (native
`.pptx`/`.xlsx`), it produces the best text form and notes the conversion handoff.
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L107-L114`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L107-L114) · [full step: `canonical/skills/aid-create-document/SKILL.md#L107-L116`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L107-L116)

<a id="fragment-n6"></a>**6 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L120-L128" wrap
## State: VERIFY

1. **Mechanical grounding check** (no dispatch): claims about the project cite a KB doc or
   `file:line`; the genre's required structure is present.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks the draft:
   accurate against KB + codebase, complete for its genre, no fabricated content. Writes a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to AUTHOR. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L120-L128`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L120-L128) · [full step: `canonical/skills/aid-create-document/SKILL.md#L120-L130`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L120-L130)

<a id="fragment-n7"></a>**7 · `PRESENT`** — hard stop -- human final say before placing · _step_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L134-L138" wrap
## State: PRESENT  (hard stop -- human final say before placing)

The hard stop follows the ASK step of `skill-steps.md`. Present the drafted document **and the proposed
target location** (KB-informed: `docs/`, an ADR dir, `CHANGELOG.md`, a runbook path, ...).
Await approval. **Never writes `.aid/knowledge/`.**
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L134-L138`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L134-L138) · [full step: `canonical/skills/aid-create-document/SKILL.md#L134-L140`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L134-L140)

<a id="fragment-n8"></a>**8 · `PLACE`** — only on approval · _step_

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L144-L151" wrap
## State: PLACE  (only on approval)

If the user declined, place nothing: the draft stays in the work folder, and the step goes on to
DONE. Otherwise write the document to its approved target location. **Extra care on overwrite or on the
published `docs/` tree:** inspect the target first and show the diff -- never silently
overwrite an existing doc. Then optionally print handoffs the user may act on: `/aid-update-kb`
(if it belongs in the KB), `/aid-create*` (if it describes something not yet built),
`/aid-refactor` (an ADR mandating a refactor).
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L144-L151`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L144-L151) · [full step: `canonical/skills/aid-create-document/SKILL.md#L144-L153`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L144-L153)

<a id="fragment-n9"></a>**9 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-create-document/SKILL.md#L157-L159" wrap
## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the work folder (draft + verify ledger) as the audit record.
~~~~

[Source: `canonical/skills/aid-create-document/SKILL.md#L157-L159`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L157-L159) · [full step: `canonical/skills/aid-create-document/SKILL.md#L157-L161`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-document/SKILL.md#L157-L161)
