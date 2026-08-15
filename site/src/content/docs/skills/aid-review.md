---
title: 'aid-review'
description: 'Review an existing artifact against criteria and return findings and recommendations in one pass -- code, a diff, a design, a pull request, a ticket, a…'
generatedFrom: 'canonical/skills/aid-review/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-review/SKILL.md -->

## Frontmatter

- **`name`** — aid-review
- **`description`** — Review an existing artifact against criteria and return findings and recommendations in one pass -- code, a diff, a design, a pull request, a ticket, a document, a UI, whatever you name. Use this skill when you want a second opinion before something lands. It is read-only apart from its findings ledger: it never plans and halts. Every finding cites a Knowledge Base document or a file and line. The review is produced in a clean context and independently verified before you see it, and nothing is published to a pull request, ticket or document until you approve. It does not fix anything -- findings hand off to `/aid-fix`.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
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
  n2["REVIEW"]
  n3["VERIFY<br/>who reviews the reviewer"]
  n4{"PRESENT-FINDINGS"}
  n5["PUBLISH<br/>only on approval"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"on approval"| n5
  n4 -->|"otherwise"| n6
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidLoopBack
  class n4 aidDecision
  class n5 aidStep
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L36-L38" wrap
## State: INTAKE

Purpose: resolve the target + criteria, pick the path, allocate the work folder.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L36-L38`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L36-L38) · [full step: `canonical/skills/aid-review/SKILL.md#L36-L116`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L36-L116)

<a id="fragment-n2"></a>**2 · `REVIEW`** · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L120-L122" wrap
## State: REVIEW

Purpose: gather evidence and produce the grounded findings ledger.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L120-L122`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L120-L122) · [full step: `canonical/skills/aid-review/SKILL.md#L120-L141`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L120-L141)

<a id="fragment-n3"></a>**3 · `VERIFY`** — who reviews the reviewer · _loop-back_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L145-L147" wrap
## State: VERIFY  (who reviews the reviewer)

Purpose: ensure the review is grounded, correct, and complete before the human sees it.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L145-L147`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L145-L147) · [full step: `canonical/skills/aid-review/SKILL.md#L145-L165`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L145-L165)

<a id="fragment-n4"></a>**4 · `PRESENT-FINDINGS`** — always a hard stop -- human final say · _decision_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L169-L171" wrap
## State: PRESENT-FINDINGS  (always a hard stop -- human final say)

Set STATE `lifecycle: Paused-Awaiting-Input`. Present:
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L169-L171`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L169-L171) · [full step: `canonical/skills/aid-review/SKILL.md#L169-L182`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L169-L182)

<a id="fragment-n5"></a>**5 · `PUBLISH`** — only on approval · _step_

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L186-L195" wrap
## State: PUBLISH  (only on approval)

Deliver by the method appropriate to the target, chosen by judgment (not a hardcoded
enum): a PR comment via `gh`; a ticket comment via `/aid-update-ticket comment
[<connector>:]<ticket-id> <text>` (still user-authorized -- the approval just given at
PRESENT-FINDINGS is what authorizes this call, and the skill previews the exact payload again
at its own CONFIRM before posting); a findings report in the work folder (+ optional
inline-comment suggestions) for code; inline notes for a document. **Graceful fallback:** no PR /
no catalogued connector / unknown target -> present the exact text for the human to paste.
Publishing is optional and never blocks DONE.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L186-L195`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L186-L195) · [full step: `canonical/skills/aid-review/SKILL.md#L186-L197`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L186-L197)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-review/SKILL.md#L201-L205" wrap
## State: DONE

Set STATE `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.
Leave the findings ledger on disk (`.aid/.temp/review-pending/<work>-review.md`) so a
follow-up `/aid-fix` can consume it. Keep the work folder as the audit record.
~~~~

[Source: `canonical/skills/aid-review/SKILL.md#L201-L205`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L201-L205) · [full step: `canonical/skills/aid-review/SKILL.md#L201-L205`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-review/SKILL.md#L201-L205)
