---
title: 'aid-deep-review'
description: 'The graded adversarial review, callable by any skill.'
generatedFrom: 'canonical/skills/aid-deep-review/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-deep-review/SKILL.md -->

## Frontmatter

- **`name`** — aid-deep-review
- **`description`** — The graded adversarial review, callable by any skill. Dispatches aid-reviewer against a resolved rule set, reconciles findings into the durable ledger, gates on open criteria gaps, grades, and runs the FIX loop to the caller's minimum grade. This is the pass a quality gate reads.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Task

[Definition: `canonical/skills/aid-deep-review/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md)

## Flow

> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.

```mermaid
flowchart TB
  classDef aidNode color:#fff
  classDef aidEntry fill:#166534,stroke:#14532d,color:#fff
  classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff
  classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff
  classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff
  classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9
  n1(["STEP-1<br/>**Resolve the rule set** through review-rubrics/INDEX.md…"])
  n2["STEP-2<br/>**Pick the scratch ledger path.** &lt;scope&gt;-cycle&lt;N&gt;.md. Its…"]
  n3["STEP-3<br/>**Subtract settled gaps.** gap-register.sh --resolved-keys…"]
  n4["STEP-4<br/>**Plan the resume**, if resuming: plan-resume.sh --ledger…"]
  n5["STEP-5<br/>**Validate the settings file, then resolve the minimum…"]
  n6(["STEP-6<br/>**Print the resolved bar** in the gate's output: bar =…"])
  n1 --> n2
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 --> n6
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
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

<a id="fragment-n1"></a>**1 · `STEP-1`** — \*\*Resolve the rule set\*\* through review-rubrics/INDEX.md… · _entry_

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L22" wrap
1. **Resolve the rule set** through `review-rubrics/INDEX.md`, in its stated order: exact route →
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L22`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L22)

<a id="fragment-n2"></a>**2 · `STEP-2`** — \*\*Pick the scratch ledger path.\*\* &lt;scope>-cycle&lt;N>.md. Its… · _step_

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L26" wrap
2. **Pick the scratch ledger path.** `<scope>-cycle<N>.md`. Its presence decides the mode: present →
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L26`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L26)

<a id="fragment-n3"></a>**3 · `STEP-3`** — \*\*Subtract settled gaps.\*\* gap-register.sh --resolved-keys… · _step_

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L28" wrap
3. **Subtract settled gaps.** `gap-register.sh --resolved-keys` — anything `Answered`, `Declined` or
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L28`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L28)

<a id="fragment-n4"></a>**4 · `STEP-4`** — \*\*Plan the resume\*\*, if resuming: plan-resume.sh --ledger… · _step_

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L31" wrap
4. **Plan the resume**, if resuming: `plan-resume.sh --ledger <scratch>` and apply its verdicts with
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L31`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L31)

<a id="fragment-n5"></a>**5 · `STEP-5`** — \*\*Validate the settings file, then resolve the minimum… · _step_

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L33" wrap
5. **Validate the settings file, then resolve the minimum grade.**
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L33`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L33)

<a id="fragment-n6"></a>**6 · `STEP-6`** — \*\*Print the resolved bar\*\* in the gate's output: bar =… · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-deep-review/SKILL.md#L51" wrap
6. **Print the resolved bar** in the gate's output: `bar = <grade> (from .aid/settings.yml)`. A gate that
~~~~

[Source: `canonical/skills/aid-deep-review/SKILL.md#L51`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deep-review/SKILL.md#L51)
