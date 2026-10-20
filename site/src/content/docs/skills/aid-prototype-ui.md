---
title: 'aid-prototype-ui'
description: 'Build a throwaway, low-fidelity UI wireframe and interaction flow to test whether a UX direction actually works.'
generatedFrom: 'canonical/skills/aid-prototype-ui/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-prototype-ui/SKILL.md -->

## Frontmatter

- **`name`** — aid-prototype-ui
- **`description`** — Build a throwaway, low-fidelity UI wireframe and interaction flow to test whether a UX direction actually works. Use this skill when you want to see a screen before committing to building it. Isolated and disposable: it never touches production, and it reports what the mock shows rather than deciding anything for you. For a kept UI design meant to inform the real build rather than a throwaway that validates a direction, use `/aid-design-ui` instead. A thin kind-sibling of `/aid-prototype`, which defines its full behavior.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;screen/flow> -- the UI screen(s)/flow whose direction to validate

[Definition: `canonical/skills/aid-prototype-ui/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype-ui/SKILL.md)

## Flow

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["aid-prototype-ui<br/>{verb: prototype, artifact: ui}"])
  n2(["INTAKE"])
  n3["INTAKE-ASK<br/>only when a question must be put"]
  n4["ALLOCATE"]
  n5["BUILD"]
  n6["VERIFY<br/>LIGHT -- do not polish-grade a rough model"]
  n7["PRESENT<br/>hard stop -- the user decides"]
  n8["HANDOFF<br/>optional; printed suggestions only"]
  n9(["DONE"])
  n1 --> n2
  n2 -->|"when any of these holds: the argument is empty, the path is Guided, works exist"| n3
  n2 -->|"otherwise"| n4
  n3 --> n4
  n4 --> n5
  n5 --> n6
  n6 -. "when the check fails the first time" .-> n5
  n6 -->|"otherwise"| n7
  n7 --> n8
  n8 --> n9
  class n1 aidEntry
  class n2 aidEntry
  class n3 aidStep
  class n4 aidStep
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

<a id="fragment-n1"></a>**1 · `aid-prototype-ui`** — {verb: prototype, artifact: ui} · _entry_

~~~~plaintext title="canonical/skills/aid-prototype-ui/SKILL.md#L18" wrap
(`alias_of: null`, its own `{verb: prototype, artifact: ui}`), `repurpose: true`
~~~~

[Source: `canonical/skills/aid-prototype-ui/SKILL.md#L18`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype-ui/SKILL.md#L18)

<a id="fragment-n2"></a>**2 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L33-L35" wrap
## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists). Their questions are recorded in a design document under `.aid/design/`, not in a work record.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L33-L35`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L33-L35) · [full step: `canonical/skills/aid-prototype/SKILL.md#L33-L49`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L33-L49)

<a id="fragment-n3"></a>**3 · `INTAKE-ASK`** — only when a question must be put · _step_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L53-L55" wrap
## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L53-L55`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L53-L55) · [full step: `canonical/skills/aid-prototype/SKILL.md#L53-L65`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L53-L65)

<a id="fragment-n4"></a>**4 · `ALLOCATE`** · _step_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L69-L72" wrap
## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L69-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L69-L72) · [full step: `canonical/skills/aid-prototype/SKILL.md#L69-L89`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L69-L89)

<a id="fragment-n5"></a>**5 · `BUILD`** · _step_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L93-L100" wrap
## State: BUILD

Dispatch **`aid-architect`** (clean context, tiered) to build the low-fidelity model of
the direction and capture the validation signal. A "runnable spike" is **throwaway code
written by this same `aid-architect` dispatch** -- deliberately NOT `aid-developer` (whose
job is production code), keeping the throwaway/non-production boundary crisp. All artifacts
stay in the work folder / opt-in worktree and **never touch production modules**. It writes
a validation assessment (see [Deliverable](#deliverable)) into the work folder.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L93-L100`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L93-L100) · [full step: `canonical/skills/aid-prototype/SKILL.md#L93-L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L93-L102)

<a id="fragment-n6"></a>**6 · `VERIFY`** — LIGHT -- do not polish-grade a rough model · _loop-back_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L106-L113" wrap
## State: VERIFY  (LIGHT -- do not polish-grade a rough model)

A prototype is *deliberately* low-fidelity, so this is a single light clean-context check
(not the full adversarial loop the other collapses run): dispatch **`aid-reviewer`** once to
confirm (a) the **"success signal observed" claim is honest and grounded** in what was
actually built, and (b) the **throwaway scope was respected** -- no production code snuck in,
nothing was committed to real modules. If the check fails, return to BUILD once to correct;
do not loop on polish.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L106-L113`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L106-L113) · [full step: `canonical/skills/aid-prototype/SKILL.md#L106-L115`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L106-L115)

<a id="fragment-n7"></a>**7 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L119-L123" wrap
## State: PRESENT  (hard stop -- the user decides)

The hard stop follows the ASK step of `skill-steps.md`. Present the throwaway model + the validation
assessment: **Direction · What was built (fidelity) · Success signal — observed or not ·
What we learned · viable? (a conclusion, not a resolution).** Assert no resolution.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L119-L123`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L119-L123) · [full step: `canonical/skills/aid-prototype/SKILL.md#L119-L125`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L119-L125)

<a id="fragment-n8"></a>**8 · `HANDOFF`** — optional; printed suggestions only · _step_

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L129-L134" wrap
## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions the user may act on: build the validated thing for real
(`/aid-create*`, or `/aid-design` first if a kept design is wanted), or test it with users
(`/aid-experiment` / `/aid-test`). Never auto-invoked; never a resolution. Ask which one, if
any, the user takes; a picked one is named in one plain line.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L129-L134`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L129-L134) · [full step: `canonical/skills/aid-prototype/SKILL.md#L129-L136`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L129-L136)

<a id="fragment-n9"></a>**9 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-prototype/SKILL.md#L140-L142" wrap
## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the throwaway artifacts + assessment in the work folder as the audit record; nothing is promoted to production.
~~~~

[Source: `canonical/skills/aid-prototype/SKILL.md#L140-L142`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L140-L142) · [full step: `canonical/skills/aid-prototype/SKILL.md#L140-L144`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-prototype/SKILL.md#L140-L144)
