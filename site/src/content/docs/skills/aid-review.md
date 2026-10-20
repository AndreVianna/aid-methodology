---
title: 'aid-review'
description: 'Review code, a change or a design against criteria.'
generatedFrom: 'canonical/skills/aid-review/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-review/SKILL.md -->

## Frontmatter

- **`name`** — aid-review
- **`description`** — Review code, a change or a design against criteria. Use when a review is asked for.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)

[Definition: `canonical/skills/aid-review/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md)

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
  n2["INTAKE-ASK<br/>only when a question must be put"]
  n3["ALLOCATE"]
  n4["REVIEW"]
  n5(["VERIFY<br/>who reviews the reviewer"])
  n6["PRESENT-FINDINGS<br/>always a hard stop -- human final say"]
  n7["PUBLISH<br/>only on approval"]
  n8(["DONE"])
  n1 -->|"when any of these holds: the argument is empty, the path is guided, works exist"| n2
  n1 -->|"otherwise"| n3
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 -. "when it is not clean and fewer than 3 cycles have run" .-> n4
  n5 -->|"when the grade is clean"| n6
  n6 --> n7
  n7 --> n8
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidExit
  class n6 aidStep
  class n7 aidStep
  class n8 aidExit
  class n1 aidNode
  class n2 aidNode
  class n3 aidNode
  class n4 aidNode
  class n5 aidNode
  class n6 aidNode
  class n7 aidNode
  class n8 aidNode
```
## Source fragments

Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L37-L39" wrap
## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists). Their questions are recorded in a design document under `.aid/design/`, not in a work record.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L37-L39`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L37-L39) · [full step: `canonical/skills/aid-review/SKILL.md#L37-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L37-L94)

<a id="fragment-n2"></a>**2 · `INTAKE-ASK`** — only when a question must be put · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L98-L100" wrap
## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L98-L100`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L98-L100) · [full step: `canonical/skills/aid-review/SKILL.md#L98-L109`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L98-L109)

<a id="fragment-n3"></a>**3 · `ALLOCATE`** · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L113-L115" wrap
## State: ALLOCATE

Allocate through the Work Initiation Gate (`.aid/runtime/templates/work-initiation-gate.md`).
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L113-L115`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L113-L115) · [full step: `canonical/skills/aid-review/SKILL.md#L113-L130`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L113-L130)

<a id="fragment-n4"></a>**4 · `REVIEW`** · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L134-L136" wrap
## State: REVIEW

Purpose: gather evidence and produce the grounded findings ledger.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L134-L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L134-L136) · [full step: `canonical/skills/aid-review/SKILL.md#L134-L155`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L134-L155)

<a id="fragment-n5"></a>**5 · `VERIFY`** — who reviews the reviewer · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L159-L161" wrap
## State: VERIFY  (who reviews the reviewer)

Purpose: ensure the review is grounded, correct, and complete before the human sees it.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L159-L161`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L159-L161) · [full step: `canonical/skills/aid-review/SKILL.md#L159-L179`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L159-L179)

<a id="fragment-n6"></a>**6 · `PRESENT-FINDINGS`** — always a hard stop -- human final say · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L183-L185" wrap
## State: PRESENT-FINDINGS  (always a hard stop -- human final say)

The hard stop follows the ASK step of `skill-steps.md`. Present:
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L183-L185`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L183-L185) · [full step: `canonical/skills/aid-review/SKILL.md#L183-L201`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L183-L201)

<a id="fragment-n7"></a>**7 · `PUBLISH`** — only on approval · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L205-L217" wrap
## State: PUBLISH  (only on approval)

If the user did not approve publishing, nothing is posted: the step goes on to DONE. Otherwise
deliver by the method appropriate to the target, chosen by judgment (not a hardcoded
enum): a PR comment via `gh`; a ticket comment via `/aid-update-ticket comment
[<connector>:]<ticket-id> <text>` (still user-authorized -- the approval just given at
PRESENT-FINDINGS is what authorizes this call, and the skill previews the exact payload again
at its own CONFIRM before posting); a findings report in the work folder (+ optional
inline-comment suggestions) for code; inline notes for a document. **Graceful fallback:** no PR /
no catalogued connector / unknown target -> present the exact text for the human to paste; when the
user must choose where it goes, ask that as one question in the same form, recorded with `--ask` before
it is shown and `--answer` after, recommending the paste.
Publishing is optional and never blocks DONE.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L205-L217`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L205-L217) · [full step: `canonical/skills/aid-review/SKILL.md#L205-L219`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L205-L219)

<a id="fragment-n8"></a>**8 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L223-L225" wrap
## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Leave the findings ledger on disk (`.aid/.temp/review-pending/<work>-review.md`) so a follow-up `/aid-fix` can consume it. Keep the work folder as the audit record.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L223-L225`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L223-L225) · [full step: `canonical/skills/aid-review/SKILL.md#L223-L227`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L223-L227)
