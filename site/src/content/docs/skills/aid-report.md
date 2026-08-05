---
title: 'aid-report'
description: 'Analyze data or usage NOW -- EDA, metrics, or an A/B result -- and return a curated, verified insight report in one pass.'
generatedFrom: 'canonical/skills/aid-report/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-report/SKILL.md -->

## Frontmatter

- **`name`** — aid-report
- **`description`** — Analyze data or usage NOW -- EDA, metrics, or an A/B result -- and return a curated, verified insight report in one pass. It RESOLVES NOTHING: it presents findings, conclusions (positive AND negative), data-quality caveats, conflicts (each with its reason), and gaps, clearly and simply; you resolve. Grounded two ways: the data being analyzed plus the KB/project source (for what the data means) are the authoritative grounding truth; external baselines/benchmarks are supplementary, cited with URL + access date. Produced by aid-researcher and verified by aid-reviewer. Reads data read-only (files/logs directly; live sources via an MCP connector); never a durable dashboard -- that is /aid-create-dashboard. Allocates a work-NNN folder.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;subject> -- the data/usage to analyze (a dataset, logs, metrics, an A/B result)

[Definition: `canonical/skills/aid-report/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md)

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
  n2["ANALYZE"]
  n3["VERIFY"]
  n4{"PRESENT"}
  n5["HANDOFF<br/>optional; printed suggestions only"]
  n6(["DONE"])
  n1 --> n2
  n2 --> n3
  n3 -.-> n2
  n3 --> n4
  n4 -->|"optional"| n5
  n4 --> n6
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

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L36-L56" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What data
   should I analyze, and what question about it?") and wait.
2. **Pick the path:** **Fast** -- a clear data source + a clear analytical ask ("analyze
   the A/B results in `results.csv`", "error-rate breakdown from these logs") -> analyze
   now. **Guided** -- vague ("analyze our usage") -> scope *which data, which metrics, what
   question* first, then analyze.
3. **Classify complexity (model + effort):** simple (small dataset, one metric) ->
   `aid-researcher` at **sonnet / medium**; standard/complex (large data, A/B significance,
   deep telemetry) -> **opus / high**. Verifier tier >= producer tier.
4. **Consult the Work Initiation Gate, then allocate the work folder + STATE.** First run
   the gate (`canonical/aid/templates/work-initiation-gate.md`):
   `bash canonical/aid/scripts/works/enumerate-works.sh` (main tree + every git worktree).
   Empty -> allocate, no prompt. Works exist -> ask new-vs-continuation; on **continuation**
   route to the chosen work's resume door and STOP (allocate nothing); on **new work**:
   create and enter the worktree per the gate's `§ 3a` step 2
   (`worktree-lifecycle.sh create <work-id> <name>`, STOP on a non-zero exit or empty path,
   else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:
   aid-report`, `lifecycle: Running`, `active_skill: aid-report`; `phase` not driven), same
   as the other collapse skills.
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L36-L56`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L36-L56) · [full step: `canonical/skills/aid-report/SKILL.md#L36-L58`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L36-L58)

<a id="fragment-n2"></a>**2 · `ANALYZE`** · _step_

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L62-L65" wrap
## State: ANALYZE

Access the data **read-only** and dispatch **`aid-researcher`** (clean context, tiered) to
analyze + consolidate:
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L62-L65`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L62-L65) · [full step: `canonical/skills/aid-report/SKILL.md#L62-L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L62-L77)

<a id="fragment-n3"></a>**3 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L81-L91" wrap
## State: VERIFY

1. **Mechanical grounding check** (no dispatch): findings cite the data; external claims a
   URL+date; the **Caveats** and **Conflicts** sections exist.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks `REPORT.md`:
   findings supported by the data; **no metric or A/B conclusion stated without its caveat**
   (sampling, significance, denominator, confounders); conflicts surfaced with reasons;
   conclusions not overstated into resolutions. Writes a review-quality ledger to
   `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash canonical/aid/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to ANALYZE. Circuit-breaker: 3 cycles -> IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L81-L91`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L81-L91) · [full step: `canonical/skills/aid-report/SKILL.md#L81-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L81-L93)

<a id="fragment-n4"></a>**4 · `PRESENT`** — hard stop -- the user resolves · _decision_

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L97-L101" wrap
## State: PRESENT  (hard stop -- the user resolves)

Set `lifecycle: Paused-Awaiting-Input`. Present `REPORT.md` clearly: findings
(metrics/tables), conclusions (+/-), **caveats & data-quality gaps** (first-class),
conflicts with reasons, and gaps. Assert no resolution.
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L97-L101`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L97-L101) · [full step: `canonical/skills/aid-report/SKILL.md#L97-L103`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L97-L103)

<a id="fragment-n5"></a>**5 · `HANDOFF`** — optional; printed suggestions only · _step_

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L107-L112" wrap
## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions the user may act on: make it recurring (`/aid-create-dashboard`), record
a decision (`/aid-document-decision`), act on a conclusion (`/aid-create*` / `/aid-update*`),
or comment on a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`).
Never auto-invoked; never a resolution.
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L107-L112`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L107-L112) · [full step: `canonical/skills/aid-report/SKILL.md#L107-L114`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L107-L114)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · UNSPECIFIED

~~~~plaintext title="canonical/skills/aid-report/SKILL.md#L118-L121" wrap
## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the
work folder (`REPORT.md`, the verify ledger) as the audit record.
~~~~

[Source: `canonical/skills/aid-report/SKILL.md#L118-L121`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L118-L121) · [full step: `canonical/skills/aid-report/SKILL.md#L118-L121`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-report/SKILL.md#L118-L121)
