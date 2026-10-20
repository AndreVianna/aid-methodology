---
title: 'aid-update-kb'
description: 'Apply one targeted, human-confirmed change to the Knowledge Base.'
generatedFrom: 'canonical/skills/aid-update-kb/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-kb/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-kb
- **`description`** — Apply one targeted, human-confirmed change to the Knowledge Base. Use this skill when you know what changed and which part of the KB should reflect it, and you want that edit and nothing more. It works in its own worktree: it analyses how your instruction lands across the KB, turns that into a minimal scope plan with an explicit list of what it will not change, and pauses for your confirmation before any edit. Only the confirmed scope is applied, it is reviewed against the four-mandate panel, and it commits only after you approve a second time.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;what changed / what to update in the KB>

[Definition: `canonical/skills/aid-update-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ANALYZE<br/>ANALYZE maps the user's instruction onto concrete KB…"])
  n2(["SCOPE<br/>SCOPE turns ANALYZE's Impact Map into the minimal Scope…"])
  n3(["CONFIRM<br/>CONFIRM is the new pre-apply human gate -- the root fix…"])
  n4["APPLY<br/>APPLY makes targeted summary+pointer edits to the KB docs…"]
  n5{"REVIEW"}
  n6{"APPROVAL"}
  n7(["DONE<br/>DONE commits the approved KB changes and closes the run."])
  n1 --> n2
  n2 --> n3
  n3 -->|"when the adjustment corrects the Understanding itself"| n1
  n3 -->|"when the user adjusts"| n2
  n3 -->|"when the user confirms"| n4
  n4 --> n5
  n5 -->|"when an out-of-scope edit is on disk"| n3
  n5 -->|"when an APPLY is incomplete"| n4
  n5 -->|"when the review is READY"| n6
  n6 -->|"when the consideration challenges the Understanding itself"| n1
  n6 -->|"when the user adds a consideration"| n2
  n6 -->|"when the user approves"| n7
  n7 -->|"when it needs an out-of-scope addition (1b)"| n3
  n7 -->|"when the closure gap is fixable within Confirmed Scope (1a)"| n4
  class n1 aidEntry
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidDecision
  class n6 aidDecision
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

<a id="fragment-n1"></a>**1 · `ANALYZE`** — ANALYZE maps the user's instruction onto concrete KB… · _entry_

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L395" wrap
| ANALYZE | `references/state-analyze.md` | `aid-researcher` (clean-context dispatch, HL-8/AC-9) | CHAIN → SCOPE (a concept that cannot be grounded is asked in the step first -- Q&A escalation to `.aid/knowledge/STATE.md`) |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L395`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L395) · [full step: `canonical/skills/aid-update-kb/references/state-analyze.md#L1-L274`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-analyze.md#L1-L274)

<a id="fragment-n2"></a>**2 · `SCOPE`** — SCOPE turns ANALYZE's Impact Map into the minimal Scope… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L396" wrap
| SCOPE | `references/state-scope.md` | `aid-architect` (clean-context dispatch, HL-8/AC-9) | CHAIN → CONFIRM (or HALT if the Scope Plan is empty -- "no update needed") |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L396`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L396) · [full step: `canonical/skills/aid-update-kb/references/state-scope.md#L1-L178`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-scope.md#L1-L178)

<a id="fragment-n3"></a>**3 · `CONFIRM`** — CONFIRM is the new pre-apply human gate -- the root fix… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L397" wrap
| CONFIRM | `references/state-confirm.md` | inline (human gate) | CHAIN → APPLY when the user confirms; CHAIN → SCOPE when the user adjusts; CHAIN → ANALYZE when the adjustment corrects the understanding; HALT when the user cancels |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L397`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L397) · [full step: `canonical/skills/aid-update-kb/references/state-confirm.md#L1-L165`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-confirm.md#L1-L165)

<a id="fragment-n4"></a>**4 · `APPLY`** — APPLY makes targeted summary+pointer edits to the KB docs… · _step_

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L398" wrap
| APPLY | `references/state-apply.md` | inline (Edit) or `aid-architect`/`aid-researcher` for the owning doc-set | CHAIN → REVIEW |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L398`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L398) · [full step: `canonical/skills/aid-update-kb/references/state-apply.md#L1-L310`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-apply.md#L1-L310)

<a id="fragment-n5"></a>**5 · `REVIEW`** — REVIEW first runs two mechanical, aid-update-kb-specific… · _decision_

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L399" wrap
| REVIEW | `references/state-review.md` (REUSES f005's panel scoped to the changed docs; scope-diff guard runs first) | `aid-reviewer` panel (f005) | 3 endings (`state-review.md § Step 4`): incomplete APPLY -> CHAIN → APPLY; out-of-scope disk edit -> CHAIN → CONFIRM; READY -> CHAIN → APPROVAL. Below the gate (scope-diff already PASS), the fix pass runs inside the step and the review runs again |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L399`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L399) · [full step: `canonical/skills/aid-update-kb/references/state-review.md#L1-L413`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-review.md#L1-L413)

<a id="fragment-n6"></a>**6 · `APPROVAL`** — APPROVAL is the explicit human gate before the KB change is… · _decision_

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L400" wrap
| APPROVAL | `references/state-approval.md` | inline | CHAIN → DONE when the user approves; CHAIN → SCOPE when the user adds a consideration; CHAIN → ANALYZE when the consideration challenges the understanding |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L400`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L400) · [full step: `canonical/skills/aid-update-kb/references/state-approval.md#L1-L157`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-approval.md#L1-L157)

<a id="fragment-n7"></a>**7 · `DONE`** — DONE commits the approved KB changes and closes the run. · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L401" wrap
| DONE | `references/state-done.md` | inline | HALT (restamp `approved_at_commit:`, commit on the Pre-flight worktree's `aid/update-kb-<ts>` branch, clean run-state); a closure shortfall goes back instead: CHAIN → APPLY (fixable within Confirmed Scope) or CHAIN → CONFIRM (needs an out-of-scope addition) |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L401`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L401) · [full step: `canonical/skills/aid-update-kb/references/state-done.md#L1-L234`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-done.md#L1-L234)
