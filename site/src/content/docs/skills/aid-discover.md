---
title: 'aid-discover'
description: 'Populate the Knowledge Base from a codebase that already exists.'
generatedFrom: 'canonical/skills/aid-discover/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-discover/SKILL.md -->

## Frontmatter

- **`name`** — aid-discover
- **`description`** — Populate the Knowledge Base from a codebase that already exists. Use this skill when you are starting AID on a project with existing code, and its architecture, conventions, and patterns need to be written down before any later phase can rely on them. It reads all repository content -- code, configuration, and documentation -- drafts the KB documents, reviews them, asks you what it could not infer, fixes what it finds, and takes your approval. It advances one step per run, so you can stop and resume. Run /aid-config first to scaffold the KB.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart

[Definition: `canonical/skills/aid-discover/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["ELICIT<br/>ELICIT captures the project's external sources and tool…"])
  n2(["GENERATE<br/>GENERATE generates KB documents that are missing or still…"])
  n3{"REVIEW"}
  n4{"Q-AND-A"}
  n5{"FIX"}
  n6(["APPROVAL<br/>APPROVAL presents the KB summary and asks the user to…"])
  n7(["DONE<br/>DONE confirms discovery is complete and user-approved; it…"])
  n1 --> n2
  n2 --> n3
  n3 -->|"if Pending Q&amp;A entries with Impact: Required exist"| n4
  n3 -->|"otherwise"| n5
  n4 -->|"when any answer implies a doc change"| n5
  n4 -->|"otherwise chain once zero Pending and grade &gt;= minimum"| n6
  n5 -->|"if grade &lt; minimum"| n3
  n5 -->|"if grade ≥ minimum"| n6
  n6 -. "otherwise" .- n6
  n6 -->|"user approval is the natural pause — once user approves"| n7
  class n1 aidExit
  class n2 aidExit
  class n3 aidDecision
  class n4 aidDecision
  class n5 aidDecision
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

<a id="fragment-n1"></a>**1 · `ELICIT`** — ELICIT captures the project's external sources and tool… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L265" wrap
| ELICIT | `references/state-elicit.md` | inline | → GENERATE |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L265`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L265) · [full step: `canonical/skills/aid-discover/references/state-elicit.md#L1-L329`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-elicit.md#L1-L329)

<a id="fragment-n2"></a>**2 · `GENERATE`** — GENERATE generates KB documents that are missing or still… · _exit_ · PAUSE-FOR-USER-ACTION

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L266" wrap
| GENERATE | `references/state-generate.md` | `aid-architect` | → REVIEW |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L266`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L266) · [full step: `canonical/skills/aid-discover/references/state-generate.md#L1-L1072`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-generate.md#L1-L1072)

<a id="fragment-n3"></a>**3 · `REVIEW`** — REVIEW grades all declared KB documents for accuracy… · _decision_

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L267" wrap
| REVIEW | `references/state-review.md` | `aid-architect` | → Q-AND-A |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L267`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L267) · [full step: `canonical/skills/aid-discover/references/state-review.md#L1-L648`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-review.md#L1-L648)

<a id="fragment-n4"></a>**4 · `Q-AND-A`** — Q-AND-A drives EVERY pending question to a terminal answer. · _decision_

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L268" wrap
| Q-AND-A | `references/state-q-and-a.md` | inline | → FIX |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L268`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L268) · [full step: `canonical/skills/aid-discover/references/state-q-and-a.md#L1-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-q-and-a.md#L1-L66)

<a id="fragment-n5"></a>**5 · `FIX`** — FIX applies Q&amp;A answers and reviewer feedback to bring KB… · _decision_

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L269" wrap
| FIX | `references/state-fix.md` | `aid-architect` | → APPROVAL |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L269`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L269) · [full step: `canonical/skills/aid-discover/references/state-fix.md#L1-L126`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-fix.md#L1-L126)

<a id="fragment-n6"></a>**6 · `APPROVAL`** — APPROVAL presents the KB summary and asks the user to… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L270" wrap
| APPROVAL | `references/state-approval.md` | inline | → halt |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L270`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L270) · [full step: `canonical/skills/aid-discover/references/state-approval.md#L1-L40`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-approval.md#L1-L40)

<a id="fragment-n7"></a>**7 · `DONE`** — DONE confirms discovery is complete and user-approved; it… · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-discover/SKILL.md#L271" wrap
| DONE | `references/state-done.md` | inline | → halt |
~~~~

[Source: `canonical/skills/aid-discover/SKILL.md#L271`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md#L271) · [full step: `canonical/skills/aid-discover/references/state-done.md#L1-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/references/state-done.md#L1-L73)
