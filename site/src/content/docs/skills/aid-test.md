---
title: 'aid-test'
description: 'Run tests or checks and report the findings.'
generatedFrom: 'canonical/skills/aid-test/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-test/SKILL.md -->

## Frontmatter

- **`name`** — aid-test
- **`description`** — Run tests or checks and report the findings. Use when something must be verified.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;target> -- what to test/verify (a suite/module, or a kind: security, performance, data-quality, model-eval)

[Definition: `canonical/skills/aid-test/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md)

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
  n4["RUN"]
  n5["VERIFY"]
  n6["PRESENT<br/>hard stop -- human"]
  n7["HANDOFF<br/>optional; printed suggestions only"]
  n8(["DONE"])
  n1 -->|"when any of these holds: the argument is empty, the path is Guided, works exist"| n2
  n1 -->|"otherwise"| n3
  n2 --> n3
  n3 --> n4
  n4 --> n5
  n5 -.-> n4
  n5 --> n6
  n6 --> n7
  n7 --> n8
  class n1 aidEntry
  class n2 aidStep
  class n3 aidStep
  class n4 aidStep
  class n5 aidLoopBack
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

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L35-L37" wrap
## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L35-L37`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L35-L37) · [full step: `canonical/skills/aid-test/SKILL.md#L35-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L35-L53)

<a id="fragment-n2"></a>**2 · `INTAKE-ASK`** — only when a question must be put · _step_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L57-L59" wrap
## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L57-L59`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L57-L59) · [full step: `canonical/skills/aid-test/SKILL.md#L57-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L57-L66)

<a id="fragment-n3"></a>**3 · `ALLOCATE`** · _step_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L70-L73" wrap
## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L70-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L70-L73) · [full step: `canonical/skills/aid-test/SKILL.md#L70-L86`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L70-L86)

<a id="fragment-n4"></a>**4 · `RUN`** · _step_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L90-L100" wrap
## State: RUN

Execute the verification **read-only** (Bash: the test runner, scanner, benchmark, or
data-quality check per the kind; never mutate the source), capturing raw output. Then
dispatch **`aid-reviewer`** (clean context, tiered) to **consolidate** the raw results into
the global 7-column findings ledger (`reviewer-ledger-schema.md`) at
`.aid/.temp/review-pending/<work>-test.md`, applying the kind's guidance -- security:
SAST/DAST/fuzz/audit findings + severity; performance: measured-vs-threshold with the
workload/environment noted; data-quality: per-check pass/fail with thresholds; functional:
pass/fail + failures; model-eval: metric vs threshold. Every finding cites its evidence
(the run output + a `file:line` where applicable).
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L90-L100`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L90-L100) · [full step: `canonical/skills/aid-test/SKILL.md#L90-L102`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L90-L102)

<a id="fragment-n5"></a>**5 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L106-L115" wrap
## State: VERIFY

1. **Mechanical grounding check** (no dispatch): every finding cites run output / a
   `file:line`; a metric/threshold finding states its threshold + measured value.
2. **Adversarial verification** -- a clean-context **`aid-reviewer`** checks the ledger:
   findings real and grounded in the run output, correctly severity-tagged, no
   over/under-statement, and the run actually exercised the stated scope. Writes a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to RUN/consolidate. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer.
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L106-L115`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L106-L115) · [full step: `canonical/skills/aid-test/SKILL.md#L106-L117`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L106-L117)

<a id="fragment-n6"></a>**6 · `PRESENT`** — hard stop -- human · _step_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L121-L125" wrap
## State: PRESENT  (hard stop -- human)

The hard stop follows the ASK step of `skill-steps.md`. Present the consolidated findings, severity-ranked,
each with its evidence; state pass/fail against any threshold; and a printed suggestion:
"N issues found -- run `/aid-fix` to address them." Assert no resolution.
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L121-L125`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L121-L125) · [full step: `canonical/skills/aid-test/SKILL.md#L121-L127`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L121-L127)

<a id="fragment-n7"></a>**7 · `HANDOFF`** — optional; printed suggestions only · _step_

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L131-L135" wrap
## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: `/aid-fix` (address findings), `/aid-create-test` (add regression tests
for a bug found), `/aid-update*` (if a fix is a real change). Never auto-invoked. Ask which one,
if any, the user takes; a picked one is named in one plain line.
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L131-L135`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L131-L135) · [full step: `canonical/skills/aid-test/SKILL.md#L131-L137`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L131-L137)

<a id="fragment-n8"></a>**8 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-test/SKILL.md#L141-L143" wrap
## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Leave the findings ledger on disk for `/aid-fix`. Keep the work folder as the audit record.
~~~~

[Source: `canonical/skills/aid-test/SKILL.md#L141-L143`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L141-L143) · [full step: `canonical/skills/aid-test/SKILL.md#L141-L145`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test/SKILL.md#L141-L145)
