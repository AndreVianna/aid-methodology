---
title: 'aid-research'
description: 'Investigate an open technical question and weigh its options.'
generatedFrom: 'canonical/skills/aid-research/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-research/SKILL.md -->

## Frontmatter

- **`name`** — aid-research
- **`description`** — Investigate an open technical question and weigh its options. Use when options must be weighed before a choice is made.
- **`allowed-tools`** — Read Glob Grep Bash Shell Terminal Write Edit Agent
- **`argument-hint`** — &lt;question> -- an open technical question to investigate

[Definition: `canonical/skills/aid-research/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md)

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
  n4["INVESTIGATE"]
  n5["PROPOSE-SPIKE<br/>only when a spike is proposed; the user decides"]
  n6["VERIFY<br/>who reviews the researcher"]
  n7["PRESENT<br/>always a hard stop -- the user resolves"]
  n8(["HANDOFF<br/>optional; printed suggestions only"])
  n9(["DONE"])
  n1 -->|"when the argument is empty, the path is Guided"| n2
  n1 -->|"works exist; otherwise"| n3
  n2 --> n3
  n3 -. "otherwise" .- n3
  n3 -->|"on a new work; a continuation follows the gate's § 3b instead"| n4
  n4 -->|"when the researcher returned a spike proposal, instead"| n5
  n4 --> n6
  n5 --> n6
  n6 -.-> n4
  n6 --> n7
  n7 --> n8
  n8 --> n9
  class n1 aidEntry
  class n2 aidStep
  class n3 aidLoopBack
  class n4 aidStep
  class n5 aidStep
  class n6 aidLoopBack
  class n7 aidStep
  class n8 aidExit
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

<a id="fragment-n1"></a>**1 · `INTAKE`** · _entry_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L36-L50" wrap
## State: INTAKE

1. **Check the question.** Note whether the argument is empty. Do not ask here.
2. **Pick the path (question scope):**
   - **Fast path** -- a concrete, well-scoped question with clear evaluation criteria
     ("Is lib X compatible with our Node 24 build?", "Postgres vs SQLite for use-case Y
     against criteria A/B/C") -> investigate immediately.
   - **Guided path** -- vague / broad / underspecified ("research our DB options") -> narrow
     it first in INTAKE-ASK (2-3 scoping questions), then investigate.
3. **Classify complexity (sets model + effort):** simple (bounded question, a few docs,
   <=1 web source) -> `aid-researcher` at **sonnet / medium**; standard/complex (broad
   options analysis, deep traversal, many web sources, a spike) -> **opus / high**.
   Verifier tier is always >= producer tier.
4. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L36-L50`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L36-L50) · [full step: `canonical/skills/aid-research/SKILL.md#L36-L53`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L36-L53)

<a id="fragment-n2"></a>**2 · `INTAKE-ASK`** — only when a question must be put · _step_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L57-L59" wrap
## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L57-L59`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L57-L59) · [full step: `canonical/skills/aid-research/SKILL.md#L57-L66`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L57-L66)

<a id="fragment-n3"></a>**3 · `ALLOCATE`** · _loop-back_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L70-L73" wrap
## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L70-L73`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L70-L73) · [full step: `canonical/skills/aid-research/SKILL.md#L70-L86`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L70-L86)

<a id="fragment-n4"></a>**4 · `INVESTIGATE`** · _step_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L90-L93" wrap
## State: INVESTIGATE

Dispatch **`aid-researcher`** (clean context, model+effort from INTAKE Step 3) to gather
and curate the evidence:
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L90-L93`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L90-L93) · [full step: `canonical/skills/aid-research/SKILL.md#L90-L107`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L90-L107)

<a id="fragment-n5"></a>**5 · `PROPOSE-SPIKE`** — only when a spike is proposed; the user decides · _step_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L111-L117" wrap
## State: PROPOSE-SPIKE  (only when a spike is proposed; the user decides)

Present *what* the spike would build, *where* (isolated in the work folder / opt-in worktree,
never touching production), and *what it would learn*. Ask the user to authorize or decline it.
Once the user answers: on **authorization** -> re-dispatch `aid-researcher` to write the
throwaway spike (isolated) and fold the finding into `RESEARCH.md`; on **decline** -> proceed
analytically and state the resulting limit in the Gaps section.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L111-L117`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L111-L117) · [full step: `canonical/skills/aid-research/SKILL.md#L111-L119`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L111-L119)

<a id="fragment-n6"></a>**6 · `VERIFY`** — who reviews the researcher · _loop-back_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L123-L137" wrap
## State: VERIFY  (who reviews the researcher)

1. **Mechanical grounding check** (no dispatch): every project claim carries a KB/source
   cite; every external claim a URL+date; the **Conflicts** and **Gaps** sections exist
   (empty-but-present is allowed; silently-omitted is not).
2. **Adversarial verification** -- dispatch a clean-context **`aid-reviewer`** to check
   `RESEARCH.md`: claims grounded and correctly attributed; conclusions evidence-backed
   and **not overstated into resolutions**; every KB<->web conflict surfaced with its
   reason; no material angle of the question left silently unaddressed. It writes a
   review-quality 7-column ledger (`reviewer-ledger-schema.md`) to
   `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade the response:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not
   clean -> loop back to INVESTIGATE for the researcher to revise. **Circuit-breaker: 3
   cycles** -> write `.aid/works/{work}/IMPEDIMENT-research.md`, and set the lifecycle to `Blocked` through the writer,
   surface it.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L123-L137`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L123-L137) · [full step: `canonical/skills/aid-research/SKILL.md#L123-L141`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L123-L141)

<a id="fragment-n7"></a>**7 · `PRESENT`** — always a hard stop -- the user resolves · _step_

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L145-L150" wrap
## State: PRESENT  (always a hard stop -- the user resolves)

The hard stop follows the ASK step of `skill-steps.md`. Present `RESEARCH.md` **clearly and simply**:
the in-depth answer, conclusions (positive **and** negative), conflicts/contradictions
**with their reasons**, and gaps. Assert no resolution -- the user decides. Negatives and
gaps are first-class, never buried under positives.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L145-L150`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L145-L150) · [full step: `canonical/skills/aid-research/SKILL.md#L145-L152`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L145-L152)

<a id="fragment-n8"></a>**8 · `HANDOFF`** — optional; printed suggestions only · _exit_ · ASK

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L156-L163" wrap
## State: HANDOFF  (optional; printed suggestions only)

Offer the natural next steps as **printed suggestions**, each requiring the user to act:
record an ADR (`/aid-document-decision` -> once landed, `/aid-create-document`), update the
KB (`/aid-update-kb`), act on a conclusion (`/aid-create*` / `/aid-update*`), or comment on
a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`). Never
auto-invoked; never a resolution. Ask which one, if any, the user takes; a picked one is named
in one plain line.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L156-L163`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L156-L163) · [full step: `canonical/skills/aid-research/SKILL.md#L156-L165`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L156-L165)

<a id="fragment-n9"></a>**9 · `DONE`** · _exit_ · HALT

~~~~plaintext title="canonical/skills/aid-research/SKILL.md#L169-L171" wrap
## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the work folder (`RESEARCH.md`, any spike scratch, the verify ledger) as the audit record.
~~~~

[Source: `canonical/skills/aid-research/SKILL.md#L169-L171`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L169-L171) · [full step: `canonical/skills/aid-research/SKILL.md#L169-L173`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-research/SKILL.md#L169-L173)
