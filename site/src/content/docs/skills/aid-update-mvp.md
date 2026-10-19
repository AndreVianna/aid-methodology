---
title: 'aid-update-mvp'
description: 'Revise roadmap.md''s ## MVP section only -- the first shippable slice: its contents, the line reasoning, what was cut, and its Status field (including the…'
generatedFrom: 'canonical/skills/aid-update-mvp/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-mvp/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-mvp
- **`description`** — Revise roadmap.md's ## MVP section only -- the first shippable slice: its contents, the line reasoning, what was cut, and its Status field (including the transition to Shipped &lt;version>). Use this skill when the MVP section already carries committed content and its scope has changed. May create the ## MVP section if roadmap.md exists without one. Reads and consumes an MVP seed when one is present in `.aid/design/`; never requires one. Asks every run which previously created outputs to update alongside it -- no stored list, no tracking metadata written. Everything outside ## MVP belongs to `/aid-update-roadmap`. When roadmap.md is absent, routes to `/aid-create-roadmap` without writing anything.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — [&lt;slice>] -- what to revise in the MVP section (contents, line, cuts, status)

[Definition: `canonical/skills/aid-update-mvp/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md)

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
  n2(["GUARD"])
  n3["UPDATE"]
  n4["VERIFY"]
  n5["PRESENT<br/>hard stop -- the user decides"]
  n6(["DONE"])
  n1 --> n2
  n2 -->|"when no seed was found, it has no unresolved question"| n3
  n3 --> n4
  n4 -.-> n3
  n4 --> n5
  n5 --> n6
  class n1 aidExit
  class n2 aidExit
  class n3 aidStep
  class n4 aidLoopBack
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L55-L72" wrap
## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What would
   you like to revise in the MVP section -- slice contents, the line reasoning, cuts, or
   status?") and wait.
2. **Read the destination** at `.aid/knowledge/roadmap.md`. If absent, **route**: allocate nothing and
   write nothing, name `/aid-create-roadmap` explicitly in the response, and end the run.
3. **Read the seed** at `.aid/design/mvp.md` if one exists. Note its presence or absence;
   do not require it.
4. **Ask the derived-outputs question** -- every run, unconditionally: "Which previously
   created outputs should be updated alongside the MVP section?" Wait for the user's
   answer before proceeding. Write no stored list and no tracking metadata anywhere.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
6. **Allocate** once the destination is present, so a route leaves no work behind, exactly per
   `design-lifecycle.md § Skill shape -- Allocation`: the Work Initiation Gate, with
   `initiator: aid-update-mvp`, `--path lite` and the saved step `GUARD` (INTAKE runs before the
   record and saves nothing). `phase` is not driven.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L55-L72`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L55-L72) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L55-L77`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L55-L77)

<a id="fragment-n2"></a>**2 · `GUARD`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L81-L84" wrap
## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Only applies when a seed was
found in INTAKE.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L81-L84`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L81-L84) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L81-L94`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L81-L94)

<a id="fragment-n3"></a>**3 · `UPDATE`** · _step_

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L98-L106" wrap
## State: UPDATE

Dispatch **`aid-architect`** (clean context, tiered) to revise the `## MVP` section.
Apply the **byte-range write discipline** (`feature-003 §4`, feature-002 §3c *Mechanics*):
read the whole `roadmap.md` file, identify the `## MVP` byte range (the literal heading
`## MVP`, matched exactly, through to the next heading of level 2 or shallower, or EOF),
replace only that range with the new content, and write the file back with every byte
outside that range **byte-identical** -- no reformatting, no whitespace change, no
re-ordering of any other region.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L98-L106`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L98-L106) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L98-L137`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L98-L137)

<a id="fragment-n4"></a>**4 · `VERIFY`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L141-L145" wrap
## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to UPDATE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L141-L145`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L141-L145) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L141-L147`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L141-L147)

<a id="fragment-n5"></a>**5 · `PRESENT`** — hard stop -- the user decides · _step_

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L151-L154" wrap
## State: PRESENT (hard stop -- the user decides)

Set `lifecycle` to `Paused-Awaiting-Input` through the writer. Present the revised `## MVP` section clearly.
Assert:
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L151-L154`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L151-L154) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L151-L167`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L151-L167)

<a id="fragment-n6"></a>**6 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-update-mvp/SKILL.md#L171-L173" wrap
## State: DONE

Set `lifecycle` to `Completed` through the writer, `updated` now, and append a `## Lifecycle History` row.
~~~~

[Source: `canonical/skills/aid-update-mvp/SKILL.md#L171-L173`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L171-L173) · [full step: `canonical/skills/aid-update-mvp/SKILL.md#L171-L175`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-mvp/SKILL.md#L171-L175)
