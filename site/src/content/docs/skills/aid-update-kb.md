---
title: 'aid-update-kb'
description: 'Apply one targeted, human-confirmed change to the Knowledge Base.'
generatedFrom: 'canonical/skills/aid-update-kb/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-kb/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-kb
- **`description`** — Apply one targeted, human-confirmed change to the Knowledge Base. Use this skill when you know what changed and which part of the KB should reflect it, and you want that edit and nothing more. It works in its own worktree: it analyses how your instruction lands across the KB, turns that into a minimal scope plan with an explicit list of what it will not change, and pauses for your confirmation before any edit. Only the confirmed scope is applied, it is reviewed against the four-mandate panel, and it commits only after you approve a second time.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
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
  n5(["REVIEW<br/>REVIEW first runs two mechanical, aid-update-kb-specific…"])
  n6(["APPROVAL<br/>APPROVAL is the explicit human gate before the KB change is…"])
  n7(["DONE<br/>DONE commits the approved KB changes and closes the run."])
  n1 --> n2
  n2 --> n3
  n3 --> n1
  n3 --> n4
  n4 --> n5
  n5 --> n4
  n5 -->|"READY"| n6
  n6 --> n2
  n6 --> n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidExit
  class n4 aidStep
  class n5 aidExit
  class n6 aidExit
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

<a id="fragment-n1"></a>**1 · `ANALYZE`** — ANALYZE maps the user's instruction onto concrete KB… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L442" wrap
| ANALYZE | `references/state-analyze.md` | `aid-researcher` (clean-context dispatch, HL-8/AC-9) | CHAIN -> SCOPE (or PAUSE-FOR-USER-ACTION if a concept is un-groundable -- Q&A escalation to `.aid/knowledge/STATE.md`) |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L442`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L442) · [full step: `canonical/skills/aid-update-kb/references/state-analyze.md#L1-L276`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-analyze.md#L1-L276)

<a id="fragment-n2"></a>**2 · `SCOPE`** — SCOPE turns ANALYZE's Impact Map into the minimal Scope… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L443" wrap
| SCOPE | `references/state-scope.md` | `aid-architect` (clean-context dispatch, HL-8/AC-9) | CHAIN -> CONFIRM (or HALT if the Scope Plan is empty -- "no update needed") |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L443`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L443) · [full step: `canonical/skills/aid-update-kb/references/state-scope.md#L1-L178`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-scope.md#L1-L178)

<a id="fragment-n3"></a>**3 · `CONFIRM`** — CONFIRM is the new pre-apply human gate -- the root fix… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L444" wrap
| CONFIRM | `references/state-confirm.md` | inline (human gate) | `[1]` CHAIN -> APPLY; `[2]` PAUSE-FOR-USER-ACTION -> SCOPE/ANALYZE; `[3]` HALT |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L444`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L444) · [full step: `canonical/skills/aid-update-kb/references/state-confirm.md#L1-L156`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-confirm.md#L1-L156)

<a id="fragment-n4"></a>**4 · `APPLY`** — APPLY makes targeted summary+pointer edits to the KB docs… · _step_

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L445" wrap
| APPLY | `references/state-apply.md` | inline (Edit) or `aid-architect`/`aid-researcher` for the owning doc-set | CHAIN -> REVIEW |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L445`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L445) · [full step: `canonical/skills/aid-update-kb/references/state-apply.md#L1-L312`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-apply.md#L1-L312)

<a id="fragment-n5"></a>**5 · `REVIEW`** — REVIEW first runs two mechanical, aid-update-kb-specific… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L446" wrap
| REVIEW | `references/state-review.md` (REUSES f005's panel scoped to the changed docs; scope-diff guard runs first) | `aid-reviewer` panel (f005) | 4 outcomes (`state-review.md § Step 4`): incomplete APPLY -> CHAIN -> APPLY; out-of-scope disk edit -> PAUSE-FOR-USER-ACTION -> CONFIRM; grade/teach-back/act-back/TRACE-1 below gate (scope-diff already PASS) -> CHAIN -> FIX; READY -> CHAIN -> APPROVAL |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L446`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L446) · [full step: `canonical/skills/aid-update-kb/references/state-review.md#L1-L414`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-review.md#L1-L414)

<a id="fragment-n6"></a>**6 · `APPROVAL`** — APPROVAL is the explicit human gate before the KB change is… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L447" wrap
| APPROVAL | `references/state-approval.md` | inline | `[1] Approved` -> CHAIN -> DONE; `[2] Additional consideration` -> PAUSE-FOR-USER-ACTION -> re-scope (CONFIRM/SCOPE) |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L447`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L447) · [full step: `canonical/skills/aid-update-kb/references/state-approval.md#L1-L155`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-approval.md#L1-L155)

<a id="fragment-n7"></a>**7 · `DONE`** — DONE commits the approved KB changes and closes the run. · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-kb/SKILL.md#L448" wrap
| DONE | `references/state-done.md` | inline | HALT (restamp `approved_at_commit:`, commit on the Pre-flight worktree's `aid/update-kb-<ts>` branch, clean run-state) |
~~~~

[Source: `canonical/skills/aid-update-kb/SKILL.md#L448`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md#L448) · [full step: `canonical/skills/aid-update-kb/references/state-done.md#L1-L239`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/references/state-done.md#L1-L239)
