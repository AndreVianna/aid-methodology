# Lite Path via Triage Fork in aid-interview

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR1) | /aid-interview |
| 2026-05-22 | Lite-path eligibility criteria added (size/complexity) per cross-reference discussion | /aid-interview |
| 2026-05-22 | Technical Specification — Data Model section written (reduced artifact set; new `DELIVERY.md` minimal delivery descriptor; FR1 deferral resolved — descriptor over PLAN-less aid-execute) | /aid-specify |
| 2026-05-22 | Technical Specification — Feature Flow section written (State 1.5 TRIAGE fork; lite-path States L1–L4; deterministic routing rule; lite→full escalation; aid-execute hand-off contract) | /aid-specify |
| 2026-05-22 | Technical Specification — Layers & Components section written (no new skill/agent; states inside aid-interview; reused agent roster; cross-tree propagation) | /aid-specify |
| 2026-05-22 | Technical Specification — State Machines section written (aid-interview extended with State 1.5 + L1–L4; transition table; resume detection) | /aid-specify |
| 2026-05-22 | Technical Specification — Migration Plan section written (additive; absent `**Path:**` reads as full; aid-execute back-compat superset) | /aid-specify |
| 2026-05-22 | Technical Specification — revised against locked decisions: (B) `DELIVERY.md` removed entirely, replaced by ONE consolidated work-root `SPEC.md` (`.aid/work-NNN/SPEC.md`) merging the condensed spec + PLAN.md info; lite work has no feature folder, no per-feature `SPEC.md`, no `PLAN.md`; (A) `task-NNN-STATE.md` merged into `task-NNN.md` (two-zone shape); `aid-execute` delivery-descriptor resolution rule updated (full → `PLAN.md`, lite → work-root `SPEC.md`); Data Model, Feature Flow, Layers & Components, State Machines, Migration Plan all updated | /aid-specify |
| 2026-05-22 | Reviewer-identified fixes applied (1 LOW + 3 MINOR): Resume detection special-cases the 1b–1.5 interrupt window (re-enters State 1.5, not State 3); `## Source` now lists §8; State L4 hand-off prints `/aid-execute task-001 {work-NNN}`; the two `references/` files marked conditional on FR3/feature-002 | /aid-specify |
| 2026-05-22 | Reviewer-identified fixes applied (1 MEDIUM + 1 LOW + 3 MINOR). **MEDIUM (cross-reference).** Every bare `FR5` reference qualified as `work-002's feature-001-profile-driven-generator` per the post-reshape `REQUIREMENTS.md §10` (`FR5 (Moved)` to work-002): Cross-tree propagation paragraph, Layers row for `references/triage.md`, Sequencing note, and Migration Plan §5 all rewritten; no bare `FR5` remains in the SPEC. **LOW (dead text).** Cross-tree propagation paragraph's pre-FR5 manual-quadruplicate fallback removed — `REQUIREMENTS.md §10` sequences work-002 **first**, so by the time feature-005 lands the generator is in place; the fallback is dead text. **MINOR (CR6).** Lite-path state ids converted from embedded-space to hyphenated UPPERCASE per feature-002's locked CR6: `CONDENSED INTAKE` → `CONDENSED-INTAKE`, `TASK BREAKDOWN` → `TASK-BREAKDOWN`, `LITE REVIEW` → `LITE-REVIEW`, `LITE DONE` → `LITE-DONE` (L1–L4 dispatch table, transition table, ASCII state diagram, all in-prose `State Lx ...` references). **MINOR (state-id).** `State 1.5 TRIAGE` pinned as canonical `State TRIAGE` (drops the numeric-fractional `1.5` from the id); positional framing kept in prose ("positioned between State 1 and State 2") where useful. **MINOR (data-model registration).** Migration Plan §5's data-model.md write-action now states concrete targets: extend `§2.4 SPEC.md (per-feature)` with a lite-path sub-note (work-root placement, merged spec + PLAN-level content) and update `§3.2 Cardinality` for one-per-lite-work cardinality; renaming §2.4 to cover both placements is at implementer's discretion. | /aid-specify |
| 2026-05-24 | **Alignment Update** added (between Acceptance Criteria and Technical Specification) **+** new "Type-Aware Lite Sub-paths (FR1 extension)" section added between Alignment Update and Technical Specification **+** 4 new ACs for the FR1 type-aware extension. Per the 2026-05-24 REQUIREMENTS refresh: (1) `INTERVIEW-STATE.md` is retired as a separate file — triage result + lite-path status live in the consolidated per-work `STATE.md` per work-003 FR2 area-STATE rule; `task-NNN.md` stays 6-section flat; per-task state in work `STATE.md ## Tasks Status` row. Body references to INTERVIEW-STATE.md / two-zone task-NNN.md / Execution Record become historical reference. (2) New FR1 type-aware extension: triage's (c) type-of-work answer routes within the lite path to one of LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths; user can override on the same triage turn. The Type-Aware Lite Sub-paths section documents the sub-path table, the triage emission shape, the user override flow, the per-sub-path mechanics, and the integration point with feature-011 (recipes). | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR1, §1, §6 NFR1, §8, §9, §10

## Description

The full AID pipeline — Interview → Specify → Plan → Detail before execution — earns
its overhead on large efforts but is too bureaucratic for small work like debugging
a bug, a small refactor, or writing a single document. This feature adds an early
fork inside `aid-interview` that routes a work item to either the full path or a
condensed lite path. The fork is decided by 2–3 quick deterministic triage
questions asked at the start — probing breadth, size, and type of work — and a
deterministic rule maps the answers to a path; it is not a new skill, because the
user often cannot tell upfront whether the full pipeline is needed. The lite path
collapses pre-execution planning into a fast, condensed flow and ends at
execution-ready output, leaving `aid-execute` to perform the actual execution. If
the lite path later discovers the work is actually large, it escalates to the full
path rather than forcing a poor fit, without losing information already captured.
Lite-path eligibility is judged on size and complexity: a work qualifies when it is
a single small delivery of a few simple tasks — a small single feature, or no
feature at all (a bug fix, a small refactor, or a simple artifact such as a short
report); typical scale is adding one small class, or changing an existing method
with its unit tests. The criterion is acknowledged as somewhat subjective and will
be tuned with experience.

## User Stories

- As an AID end user with a small task, I want `aid-interview` to detect that the
  work is small and route me through a fast condensed flow so that AID is competitive
  on speed with ad-hoc prompting for small work.
- As an AID end user, I want a few quick triage questions to decide the path
  deterministically so that I do not have to know upfront whether my work needs the
  full pipeline.
- As an AID end user on the lite path, I want the work to escalate to the full path
  if it turns out to be large so that I am never stuck in a poor-fit flow and no
  captured information is lost.

## Priority

Must

## Acceptance Criteria

- [ ] Given `/aid-interview` is started, when the triage step runs, then it asks 2–3
  triage questions and deterministically routes the work to the lite or full path.
- [ ] Given a small work item routed to the lite path, when the lite path completes,
  then it produces execution-ready tasks plus one consolidated work-root `SPEC.md`
  (`.aid/work-NNN/SPEC.md`), without creating REQUIREMENTS.md, a per-feature SPEC.md
  inside a feature folder, a separate PLAN.md, or feature folders — and the lite path
  itself does not execute the tasks (execution remains `aid-execute`'s responsibility,
  a deliberate non-goal of the lite path).
- [ ] Given the lite path has produced its output, when `/aid-execute` is run, then
  it can run that output — the exact input contract is finalized in `aid-specify`
  (see FR1).
- [ ] Given a lite work item that proves to be large, when escalation is triggered,
  then it moves to the full path without losing any captured information.

## Acceptance Criteria — Type-aware extension (added 2026-05-24)

- [ ] Given the triage's (c) type-of-work answer is one of `bug-fix`,
  `single-doc`, `small-refactor`, or `small-new-feature`, when the work
  routes to the lite path, then the lite path selects a sub-path matched to
  that type.
- [ ] Given the work type is `bug-fix`, when the lite-path sub-path runs,
  then the work-root `SPEC.md` carries reproduction + intended-behavior +
  task list only (no Specify-equivalent block; the fix is the spec).
- [ ] Given the work type is `single-doc`, when the lite-path sub-path runs,
  then it produces a single-task delivery whose work-root `SPEC.md` is the
  document outline.
- [ ] Given the auto-selected sub-path is wrong for the user's intent, when
  the triage step exposes the sub-path choice, then the user can override
  the selection on the same turn.

---

## Alignment Update — 2026-05-24

> **REQUIREMENTS.md was refreshed on 2026-05-24** with two changes that touch
> this feature:
>
> **(1) Per-area STATE rule (work-003 FR2 deployment).** Per the updated §5
> scope-addition:
>
> - **`task-NNN.md` stays 6-section flat** (Definition only). The two-zone
>   shape (Definition + Execution Record) this SPEC's body uses is retired.
> - **`INTERVIEW-STATE.md` is retired as a separate file** — the triage
>   result + lite-path status live in the consolidated per-work
>   `.aid/work-NNN/STATE.md` (the work-area STATE.md per work-003 FR2
>   area-STATE rule). work-001's own STATE.md is already in this shape.
> - **Per-task status lives in the per-work `.aid/work-NNN/STATE.md
>   ## Tasks Status` row** (not in a task-NNN.md Execution Record zone).
>
> **(2) Type-aware lite-path routing (FR1 extension).** REQUIREMENTS.md §5
> FR1 was extended on 2026-05-24 to make the lite-path triage's (c)
> type-of-work answer route within the lite path — see the new "Type-Aware
> Lite Sub-paths" section below for the substantive new content this feature
> now owns.
>
> **What changes for this feature's body:**
>
> - Every "INTERVIEW-STATE.md" reference in the body is superseded — reads as
>   "the work-area `.aid/work-NNN/STATE.md`" (the consolidated work STATE per
>   work-003 FR2 area-STATE rule). The `§ Triage` block lives in that STATE.md
>   instead of in a separate `INTERVIEW-STATE.md`.
> - Every "two-zone task-NNN.md" / "Execution Record zone" reference is
>   superseded — task-NNN.md remains 6-section flat; per-task status lives in
>   the per-work `STATE.md ## Tasks Status` row.
> - The lite-path workspace diagram showing `INTERVIEW-STATE.md` and
>   `tasks/task-001.md ← execution-ready, two-zone task shape` is superseded
>   — the workspace shape is:
>   ```
>   .aid/work-NNN-{name}/
>     STATE.md             ← work-area STATE (triage + tasks status + lifecycle)
>     SPEC.md              ← the ONE consolidated work-root spec (lite path only)
>     tasks/
>       task-001.md        ← 6-section flat
>       task-002.md
>       ...
>   ```
> - The Migration Plan's "two-zone shape coordinated repo-wide" notes are
>   superseded (no two-zone shape exists; per-area STATE consolidation
>   replaces it).
>
> **What stays the same:**
>
> - The lite-path fork inside aid-interview, decided by 2-3 deterministic
>   triage questions.
> - The lite-path output shape: one consolidated work-root `SPEC.md` + a
>   `tasks/` folder, no per-feature SPEC, no PLAN.md, no feature folders.
> - aid-execute's delivery-descriptor resolution rule: PLAN.md on full path,
>   work-root SPEC.md on lite path.
> - The FR2 per-delivery gate treating the lite work's single delivery as one
>   delivery.
> - Lite → full escalation (FR1) without losing captured info.
> - Cross-tree propagation via work-002's generator (single-source canonical).
>
> Body sections below describe the original INTERVIEW-STATE.md + two-zone
> design as historical reference; the alignment update above is the operative
> contract for /aid-plan and implementation. A focused body-text rewrite is
> a candidate /aid-detail task and is not scoped into this feature.

---

## Type-Aware Lite Sub-paths (FR1 extension, added 2026-05-24)

This section is **net-new content** added for the FR1 type-aware lite-path
routing extension introduced in the 2026-05-24 REQUIREMENTS update. The
original lite-path design treated all small work uniformly; this extension
makes the lite path's behavior depend on the triage's (c) type-of-work
answer (which already existed but was used only loosely).

### Sub-path table

The triage emits two signals: `path` (lite/full) and `workType` (one of
`bug-fix`, `single-doc`, `small-refactor`, `small-new-feature`). When
`path = lite`, the lite path selects a sub-path keyed on `workType`:

| `workType` | Sub-path name | Work-root `SPEC.md` shape | Task count | Notes |
|---|---|---|---|---|
| `bug-fix` | LITE-BUG-FIX | reproduction + intended-behavior + task list (no Specify-equivalent block — the fix IS the spec) | typically 1 (apply fix + add test) | Skips the "what are we building" Specify content; the reproduction + intended-behavior pair plays that role. |
| `single-doc` | LITE-DOC | document outline (sections + brief intent per section) + single task list | exactly 1 | The "delivery" is the doc itself; no Specify-equivalent. |
| `small-refactor` | LITE-REFACTOR | standard lite-path SPEC (before/after sketch + scope + AC) + task list | typically 1-3 | Standard lite-path output; no compression beyond what the lite path already does. |
| `small-new-feature` | LITE-FEATURE | standard lite-path SPEC + task list, with **extra AC slots** | typically 2-5 | The only sub-path that cannot lean on existing behavior as the spec; needs AC clarity. |

### Triage emission

The triage step's output is structured as two values written to the work-area
`STATE.md § Triage` block:

```markdown
## Triage

- **Path:** lite | full
- **Work Type:** bug-fix | single-doc | small-refactor | small-new-feature
- **Sub-path:** LITE-BUG-FIX | LITE-DOC | LITE-REFACTOR | LITE-FEATURE | (n/a for full)
- **Decision rationale:** {one-sentence explanation derived from the triage answers}
```

The `Sub-path` value is deterministic from `workType` (1:1 mapping per the
table above). The mapping is hard-coded in the `aid-interview` triage logic;
it is not user-configurable per project (a future extension could allow
per-project overrides, deferred for now).

### User override

After the triage emits its decision, the lite path **exposes the chosen
sub-path** to the user before proceeding:

```
Triage decided:
  Path:     lite
  Type:     bug-fix
  Sub-path: LITE-BUG-FIX (reproduction + intended-behavior + 1 task)

[1] Proceed with LITE-BUG-FIX
[2] Use a different sub-path:
      [a] LITE-DOC
      [b] LITE-REFACTOR
      [c] LITE-FEATURE
[3] Escalate to full path (FR1 escalation)
```

This override is **on the same triage turn** (not after slot-fill or
interview start) — the user sees the decision and can correct misclassification
immediately, before any sub-path-specific work begins. The chosen sub-path is
recorded in the `STATE.md § Triage` block; if overridden, an additional
`**Override:** yes` line records the deviation.

### Sub-path mechanics

Each sub-path is realised as a small branch in the existing lite-path State L1
(CONDENSED-INTAKE) state machine. The State L1 logic reads `Sub-path` from
the `§ Triage` block and dispatches to a sub-path-specific prompt template:

- **LITE-BUG-FIX:** prompts for `bug-title`, `bug-description`, `reproduction-steps`,
  `intended-behavior`; emits a work-root `SPEC.md` matching the same shape as
  the `bug-fix` recipe (see feature-011).
- **LITE-DOC:** prompts for `doc-title`, `doc-purpose`, `outline-bullets`;
  emits a work-root `SPEC.md` that IS the document outline.
- **LITE-REFACTOR:** unchanged from the original lite-path L1 logic; this is
  the "default" sub-path the original spec describes.
- **LITE-FEATURE:** extends the LITE-REFACTOR prompts with **additional AC
  elicitation** — explicit per-AC prompts asking what behavior would prove
  the feature is done.

### Interaction with feature-011 (Recipes)

When feature-011 ships, the triage's recipe-offer step (a sub-step
**after** the sub-path is selected but **before** the sub-path's
condensed interview runs) reads the `Sub-path` value to filter the recipe
catalog: recipes whose `applies-to` matches the `workType` are offered first.
If the user accepts a recipe, the sub-path's condensed interview is skipped
entirely (the recipe's slot-fill takes its place). If declined, the
sub-path-specific interview runs as described above.

### Acceptance — covered by the §Acceptance Criteria — Type-aware extension block above

---

## Technical Specification

> The lite path is **not a new skill** — it is an early **fork inside `aid-interview`**.
> The entry point stays `/aid-interview`. The fork is decided by 2–3 deterministic
> triage questions and routes the work to either the **full path** (today's
> Interview → Specify → Plan → Detail) or a **condensed lite path** that ends at
> **execution-ready output**. `aid-execute` is the next step on both paths; the lite
> path does not execute (an explicit non-goal). This spec resolves the FR1 deferral:
> the lite path produces **one consolidated `SPEC.md` at the work root**
> (`.aid/work-NNN/SPEC.md`) plus its `tasks/task-NNN.md` files — and `aid-execute`
> resolves "the delivery descriptor" by a single rule: full path → `PLAN.md`,
> lite path → the work-root `SPEC.md`.

### Data Model

The lite path operates on the same per-work folder as the full path, but produces a
**deliberately reduced artifact set**. AID's "data model" is its structured-artifact
model (`.aid/knowledge/data-model.md`) — the relevant change is *which* artifacts the
lite path writes. The lite path adds **no new artifact type**: it reuses `SPEC.md`
(an existing AID artifact) but writes a single, consolidated instance at the **work
root** instead of the full path's per-feature SPECs.

#### Lite-path workspace

```
.aid/
  knowledge/                      ← shared KB (read-only; unchanged)
  work-NNN-{name}/
    INTERVIEW-STATE.md            ← process — carries the triage result + lite-path status
    SPEC.md                       ← the ONE consolidated work-root spec (lite path only)
    tasks/
      task-001.md                 ← execution-ready, two-zone task shape (Definition + Execution Record)
      task-002.md
      ...
```

A lite work has **no `features/` folder, no per-feature `SPEC.md` inside a feature
folder, no separate `PLAN.md`** — just the one work-root `SPEC.md`, the
`tasks/task-NNN.md` files, and `INTERVIEW-STATE.md`. This is grounded in the locked
rationale: a lite work is **one-or-no feature**, so per-work scope == per-feature
scope — one `SPEC.md` per lite work is the natural unit.

What the lite path **does not** create (vs. the full path):

| Full-path artifact | Lite-path treatment |
|--------------------|---------------------|
| `REQUIREMENTS.md` | Not created. The condensed interview captures only what tasks need; that context lives in the work-root `SPEC.md`. |
| `features/feature-NNN-*/` folders | Not created. Lite work is one-or-no feature; no per-feature structure. |
| per-feature `SPEC.md` (inside a feature folder) | Not created. The lite path writes **one consolidated `SPEC.md` at the work root** instead. |
| full `PLAN.md` | Not created. The work-root `SPEC.md` carries the PLAN-level content the full path would put in `PLAN.md` (single delivery, dependency graph, delivery-level acceptance criteria, task list). |
| `tasks/task-NNN.md` | **Created** — same two-zone shape as the full path (decision A: Definition + Execution Record zones, no separate STATE file). |

#### Decision — ONE consolidated work-root `SPEC.md`, not a separate `DELIVERY.md`

The FR1 deferral asked how the lite path's output reaches `aid-execute`, since
`aid-execute` normally reads delivery context and the Execution Graph from `PLAN.md`.
**Resolution: the lite path produces a single consolidated `SPEC.md` at the work
root** (`.aid/work-NNN/SPEC.md`). It merges, in one file, what the full path splits
across a per-feature `SPEC.md` **and** a `PLAN.md`:

- the condensed spec / context (the full path's per-feature `SPEC.md` role);
- the single delivery, its dependency graph (Execution Graph), the delivery-level
  acceptance criteria, and the task list (the full path's `PLAN.md` role).

Rationale (the locked decision): a lite work is one-or-no feature, so per-work scope
== per-feature scope — one `SPEC.md` per lite work is natural, and merging the
PLAN-level content into it avoids inventing a separate planning artifact. This
supersedes the Wave-1 draft's `DELIVERY.md` proposal — **`DELIVERY.md` is removed
entirely**; no new artifact type is introduced.

Why this still keeps `aid-execute` on one input contract, grounded in the real
`aid-execute/SKILL.md`:

- `aid-execute` consumes `PLAN.md` in three load-bearing places: Check 2b (Verify
  Dependencies — "Read the Execution Graph from PLAN.md"), Check 5 (Branch Isolation
  — extracts `delivery-NNN` from the task `Source` field), and the Delivery
  Lifecycle / "Can Be Done In Parallel" table (FR6 parallelism). `aid-execute` is
  taught **one** rule — *resolve the delivery descriptor*: full path → `PLAN.md`,
  lite path → the work-root `SPEC.md`. Both carry the sections `aid-execute` needs
  (Execution Graph, the delivery id, the parallel-wave info), so every step
  downstream of that resolution is unchanged. No second, descriptor-less code path
  is added — consistent with §7 ("a change to how skills are packaged… not a
  redesign of what the pipeline does").
- FR2's per-delivery quality gate (feature-004) needs a **delivery unit** to gate
  on. The lite work's single delivery — described by the work-root `SPEC.md` — *is*
  that unit, exactly as REQUIREMENTS.md FR1/FR2 state ("the lite path's single small
  delivery is the gate's delivery unit"). Feature-004's only dependency on FR1 is
  the delivery id and the task list; the work-root `SPEC.md` carries both.

#### Work-root `SPEC.md` schema (lite path)

The lite-path work-root `SPEC.md` describes exactly **one delivery** — the lite
work's single small delivery. It is the merge of one per-feature `SPEC.md` plus that
delivery's `PLAN.md` block and Execution Graph, carrying the fields `aid-execute`
and the FR2 gate actually read.

| Section | Required | Purpose | `aid-execute` consumer |
|---------|----------|---------|------------------------|
| `# {work name}` (H1) | yes | Title / provenance. | — |
| Metadata block: `Work` / `Created` / `Source` (`/aid-interview lite path`) / `Status` | yes | Lifecycle (`Ready` → `In Progress` → `Done`). | — |
| `## Goal` | yes | One-paragraph statement of the small delivery. | Context for executor/reviewer. |
| `## Context` | yes | The condensed problem statement + the architectural constraints that would otherwise live in REQUIREMENTS.md / a per-feature SPEC.md — inlined here because the lite path skips both. KB references by `INDEX.md` doc name. | The architectural-constraints input in place of the full path's per-feature `SPEC.md`. |
| `## Acceptance Criteria` | yes | Delivery-level criteria (the work's definition of done). | Per-delivery quality gate (FR2). |
| `## Tasks` | yes | The ordered task list — one row per `task-NNN.md`: `Task` / `Type` / `Title`. | Enumerates the delivery's tasks. |
| `## Execution Graph` | yes | Same two tables `aid-detail` writes into `PLAN.md`: a `Task \| Depends On` table and a `Can Be Done In Parallel` table. | Check 2b (dependency verification) and the FR6 parallel-wave logic — same role as `PLAN.md`'s graph. |
| `## Revision History` | yes | Date / Change / Source — spec-as-hypothesis. | — |

Cardinality: **1 work-root `SPEC.md` per lite work** (a lite work is, by definition,
one delivery). It never coexists with `PLAN.md` or a `features/` folder in the same
work folder — a work folder is either full-path-shaped (`REQUIREMENTS.md` +
`features/feature-NNN/SPEC.md` + `PLAN.md`) or lite-path-shaped (one work-root
`SPEC.md`), never both. `aid-execute` distinguishes the two by the
delivery-descriptor resolution rule (`PLAN.md` present → full; else the work-root
`SPEC.md` → lite).

#### `task-NNN.md` — two-zone shape, lite delivery ID

Lite-path `task-NNN.md` files use the **same** `task-NNN.md` shape as the full path.
Per locked decision A, that shape is now **two zones — Definition + Execution
Record** — with the former `task-NNN-STATE.md` merged in; there is no separate STATE
file repo-wide. The Definition zone carries the existing fields (Type, Source,
Depends on, Scope, Acceptance Criteria); the Execution Record zone carries what
`task-NNN-STATE.md` used to hold (status, dispatches, review history, issues).

The only lite-specific convention is the `Source` field. The full path writes
`feature-NNN-{name} → delivery-NNN`; the lite path has no feature folder, so it
writes:

```
**Source:** {work-NNN-name} → delivery-001
```

The `delivery-001` token is preserved so `aid-execute` Check 5 (Branch Isolation —
`aid/delivery-NNN`) works unchanged. A lite work always has exactly `delivery-001`.

#### `INTERVIEW-STATE.md` — triage fields (extension)

`INTERVIEW-STATE.md` gains a small, additive block recording the triage outcome
(it does not alter the existing Section Status / Pending Q&A / Review History schema):

| Field | Type | Notes |
|-------|------|-------|
| `**Path:**` | enum (`full` / `lite` / `escalated`) | Set by State TRIAGE. `escalated` records a lite→full escalation. |
| `## Triage` | block | The 2–3 triage Q&A pairs verbatim + the deterministic rule's verdict — the audit trail for the routing decision. |

### Feature Flow

#### Where the fork sits in the `aid-interview` state machine

The current `aid-interview` is a 7-state machine (`SKILL.md` State Detection):
State 1 FIRST RUN, 2 Q&A, 3 CONTINUE, 4 COMPLETION & APPROVAL, 5 FEATURE
DECOMPOSITION, 6 CROSS-REFERENCE, 7 DONE. The fork is inserted as a new **State
TRIAGE** (positioned between State 1 and State 2) that runs immediately after State
1's workspace scaffolding (1b/1c) and **before** State 1d's opening question. It
does not disturb States 2–7, which remain the full path.

```
State 1  FIRST RUN
  1a read KB → 1b create INTERVIEW-STATE.md → 1c create REQUIREMENTS.md scaffold
        │
        ▼
State TRIAGE  ◄── NEW FORK (positionally between 1 and 2)
  ask 2–3 deterministic triage questions → apply the deterministic rule
        │
        ├── verdict = FULL ──► 1d opening question → States 2–7 (full path, unchanged)
        │
        └── verdict = LITE ──► State L1 … L4 (lite path, below)
```

State Detection gains one branch: on a resumed run, if `INTERVIEW-STATE.md`
`**Path:** lite`, detection routes to the lite-path states (L1–L4) instead of
States 2–7; if `**Path:** full` or absent, today's detection logic is unchanged.

#### State TRIAGE — the fork (positionally between State 1 and State 2)

Agent: `interviewer` (the frontmatter default — triage is a short structured
dialogue, not design work).

Three deterministic triage questions, asked one at a time (per the skill's "ONE
question per turn" rule), each a closed choice:

| # | Question (probes) | Choices |
|---|-------------------|---------|
| T1 | **Breadth** — how many features does this work touch? | `none` (a bug fix / refactor / single artifact) · `one small` · `multiple` |
| T2 | **Size** — roughly how many distinct tasks? | `a few (≤ ~5)` · `many` |
| T3 | **Type** — what kind of work is it? | `bug fix` · `small refactor` · `single document/artifact` · `new feature or system` |

**Deterministic routing rule** (no LLM judgement — a fixed table):

- Route **LITE** iff **all** of: T1 ∈ {`none`, `one small`} **and** T2 = `a few`
  **and** T3 ∈ {`bug fix`, `small refactor`, `single document/artifact`}.
- Route **FULL** otherwise.

The rule is intentionally conservative: any single "large" signal routes to FULL.
This matches REQUIREMENTS.md FR1 — "any single large signal routes to the full
path" — and the §8 assumption that triage misclassification is caught by escalation
(the safety net runs one direction only: lite→full, never full→lite). The triage
Q&A and the verdict are written to `INTERVIEW-STATE.md § Triage`; `**Path:**` is set.

#### The lite path — States L1–L4

The lite path collapses Interview + Specify + Plan + Detail into four condensed
states. All run within the single `/aid-interview` invocation; the user is never
sent to `/aid-specify`, `/aid-plan`, or `/aid-detail`.

| State | Name | Agent | Produces |
|-------|------|-------|----------|
| L1 | CONDENSED-INTAKE | `interviewer` | work-root `SPEC.md` § Goal, § Context, § Acceptance Criteria |
| L2 | TASK-BREAKDOWN | `architect` | `tasks/task-NNN.md` files + work-root `SPEC.md` § Tasks + § Execution Graph |
| L3 | LITE-REVIEW | `reviewer` | Grade of the task set against the work-root `SPEC.md`; loopback to L1/L2 if below minimum |
| L4 | LITE-DONE | (no dispatch) | Hand-off prompt to `/aid-execute` |

**State L1 — CONDENSED-INTAKE.** A short, focused dialogue (a handful of questions,
not the full 10-section interview) that establishes: what the work is, the relevant
KB context (read via `.aid/knowledge/INDEX.md`), and the delivery-level acceptance
criteria. The agent writes the work-root `SPEC.md` (§ Goal, § Context, § Acceptance
Criteria) incrementally — same write-immediately discipline as the full interview.
No `REQUIREMENTS.md` is created.

**State L2 — TASK-BREAKDOWN.** Dispatch `architect` (override `subagent_type`, as
States 5 and full-path Detail do). The architect proposes a small typed task
breakdown directly from the work-root `SPEC.md` — applying the **same** `aid-detail`
rules (one type per task, dependency-driven, each task one reviewable unit, the
RESEARCH→…→TEST→DOCUMENT natural ordering) but skipping the per-feature SPEC layer.
On approval it writes `tasks/task-NNN.md` (the two-zone `task-NNN.md` shape, `Source:`
= `{work} → delivery-001`) and fills the work-root `SPEC.md` § Tasks and § Execution
Graph (the two tables `aid-detail` Step 5 normally appends to `PLAN.md`).

**State L3 — LITE-REVIEW.** Dispatch `reviewer` (clean context). The reviewer grades
the task set against the work-root `SPEC.md` and the KB using the universal rubric
(`templates/grading-rubric.md`) — coherent breakdown, every task traceable to the
delivery, concrete testable criteria, no gaps in the execution graph. This is the
**lite path's single pre-execution gate** — proportionate to small work, it replaces
the full path's three separate review loops (Specify grade, Plan review, Detail
review). Grade < minimum → loopback to L1 (context wrong) or L2 (breakdown wrong).
Grade ≥ minimum → L4. (This gate is *pre-execution* quality of the plan; it is
distinct from FR2's *post-execution* per-delivery quality gate, which `aid-execute`
runs on the produced code.)

**State L4 — LITE-DONE.** Set the work-root `SPEC.md` Status `Ready`, set
`INTERVIEW-STATE.md` Status `Approved` / `**Path:** lite`. Print the hand-off:

```
Lite path complete for {work}. {N} tasks ready in {work}/tasks/.
Delivery descriptor: {work}/SPEC.md

Next step: /aid-execute task-001 {work-NNN}
```

The `{work-NNN}` work id is required by `aid-execute` whenever multiple works
exist; it is appended to the hand-off command so a multi-work `.aid/` resolves
unambiguously.

#### Escalation — lite → full

Escalation can be triggered in L1, L2, or L3, by the agent (the work reveals
multiple features, many tasks, or genuine architectural complexity) or by the user.
It is **one-directional** — there is no full→lite de-escalation. Escalation steps
are **strictly ordered** so any partial state is recoverable on re-entry: the
work-root `SPEC.md` is deleted **only as the last step**, so the combination "lite
work-root `SPEC.md` still present **and** `**Path:** escalated`" unambiguously
signals "re-seed not yet confirmed" and can be safely resumed (see Resume detection
below). On escalation:

1. Seed `REQUIREMENTS.md` from the captured lite artifacts (AC: "without losing
   any captured information"): the work-root `SPEC.md` § Goal / § Context / §
   Acceptance Criteria seed the corresponding `REQUIREMENTS.md` sections (§1
   Objective, §2 Problem Statement, §9 Acceptance Criteria); any `tasks/task-NNN.md`
   already written are retained for the architect to reconcile during full-path
   Detail.
2. Set `INTERVIEW-STATE.md` `**Path:**` to `escalated`; add a `§ Triage` note
   recording why; add a Change Log entry.
3. Continue on the **full path** — enter State 1d (opening question) / State 3
   (CONTINUE INTERVIEW) so the now-seeded `REQUIREMENTS.md` is completed
   conversationally, then proceed through States 4–7 normally. The lite work-root
   `SPEC.md` is superseded — its content lives on in `REQUIREMENTS.md` (and later in
   the per-feature `SPEC.md` + `PLAN.md` the full path produces).
4. **Last step — delete the lite work-root `SPEC.md`** (`.aid/{work}/SPEC.md`).
   Doing this last is load-bearing: until this step succeeds, a crash leaves the
   recoverable signature "`**Path:** escalated` **and** work-root `SPEC.md`
   present", which Resume detection routes back to step 1 to re-seed safely. The
   escalation rationale is preserved in `INTERVIEW-STATE.md § Triage` and the
   Change Log, so no separate escalation-record file is needed. The full path's
   per-feature SPECs live inside `features/feature-NNN/`, so there is no path
   collision with the deleted work-root file.

#### Hand-off contract to `aid-execute` (the resolved FR1 deferral)

`aid-execute` is taught **one** new rule — *resolve the delivery descriptor* — in
Pre-flight / Inputs:

- Today Inputs lists `.aid/{work}/PLAN.md` as "delivery context and Execution Graph."
- New rule: the delivery descriptor is `.aid/{work}/PLAN.md` if it exists (full path),
  **else** the work-root `.aid/{work}/SPEC.md` (lite path). Exactly one shape is
  present per work. Everything downstream of that resolution is unchanged: Check 2b
  reads `## Execution Graph` from the resolved descriptor; Check 5 extracts
  `delivery-001` from the task `Source` field; the FR6 parallel logic reads `## Can
  Be Done In Parallel`. Because the lite work-root `SPEC.md` carries those sections
  with the same shape, `aid-execute`'s per-state logic does not branch.
- `aid-execute` Inputs currently also "Always load" the per-feature `SPEC.md` from
  `features/{feature}/SPEC.md`. New rule: if there is no `features/` folder, the
  architectural-constraints input is the work-root `SPEC.md` itself (its § Context) —
  which is also the resolved delivery descriptor. On the lite path the delivery
  descriptor and the architectural-constraints input are therefore the **same file**,
  one work-root `SPEC.md`. This is the only other touch point.

This is the minimal, contained change REQUIREMENTS.md §9 calls for: "`/aid-execute`
can run the lite path's output (the exact input contract is finalized in
`aid-specify`)."

### Layers & Components

The lite path adds **no new skill and no new agent**. It is new states inside the
existing `aid-interview` skill, reusing the existing agent roster.

| Layer | Component | Change |
|-------|-----------|--------|
| Orchestration | `aid-interview/SKILL.md` | **Modified** — adds State TRIAGE (positionally between State 1 and State 2) and the State Detection branch on `**Path:**`; adds the lite-path state table (L1–L4). If FR3/feature-002 has landed, the lite-path detail moves to `references/` per the thin-router model; pre-FR3 it lives as plain `SKILL.md` prose (see Sequencing note). |
| Orchestration | `aid-interview/references/triage.md` (NEW) — *conditional on FR3* | The 3 triage questions, the deterministic routing table, and the escalation rule — externalized per the FR3 thin-router pattern, rendered as a `references/` file to all three install trees by `work-002`'s `feature-001-profile-driven-generator` (per decision F — every profile uses `references` decomposition). **Only exists if FR3/feature-002 has landed.** Pre-FR3, this content lives as plain `SKILL.md` prose (see Sequencing note). |
| Orchestration | `aid-interview/references/lite-path.md` (NEW) — *conditional on FR3* | The L1–L4 state detail — condensed intake, task breakdown, lite review, hand-off. **Only exists if FR3/feature-002 has landed.** Pre-FR3, this content lives as plain `SKILL.md` prose (see Sequencing note). |
| Execution input | `aid-execute/SKILL.md` | **Modified** — Pre-flight / Inputs gain the "resolve the delivery descriptor (full → `PLAN.md`; lite → work-root `SPEC.md`)" rule and the "no feature folders → work-root `SPEC.md § Context`" rule. No new states. |
| Data | work-root `SPEC.md` (lite path) | **No new artifact type** — reuses the existing `SPEC.md` artifact, written once at the work root for a lite work. `.aid/knowledge/data-model.md` notes the lite-path placement (work-root `SPEC.md` carrying merged spec + PLAN-level content); no new artifact id. A lite-path `SPEC.md` template variant is added under `templates/` (see Migration Plan). |
| Data | `task-NNN.md` template (`templates/delivery-plans/task-template.md`) | **Modified** — the two-zone shape (Definition + Execution Record) per locked decision A; the former `task-NNN-STATE.md` is merged in. This is a repo-wide change, not lite-specific; the lite path simply uses the same shape. |
| Data | `INTERVIEW-STATE.md` template | **Created** (no `templates/interview-state.md` exists in the repo today — pre-existing defect: live `aid-interview/SKILL.md:174` already references this non-existent path). This feature creates the template carrying today's Section Status / Pending Q&A / Review History schema plus the new `**Path:**` field and the optional `## Triage` block. **Co-dependency:** the dangling `aid-interview/SKILL.md:174` reference resolves automatically once this file exists. |

**Agents — reused, not added.** Triage and L1 use `interviewer`; L2 uses `architect`;
L3 uses `reviewer`. These are the same three agents `aid-interview` already
dispatches across States 1–6 — the lite path introduces no new agent role and stays
inside the three-tier agent model (§7 constraint).

**Cross-tree propagation (work-002's canonical generator).** The `aid-interview/SKILL.md`
changes, the two new `references/` files, the `aid-execute/SKILL.md` change, and the
template changes (`INTERVIEW-STATE.md`, the lite-path `SPEC.md` variant, and the
two-zone `task-NNN.md`) must land in the canonical source and all three install
trees. Per the committed `REQUIREMENTS.md §10` build order, **work-002's
feature-001-profile-driven-generator ships first**, so by the time feature-005 lands,
cross-tree propagation is "edit `canonical/`, run the generator". Per decision F
(every profile uses `references` decomposition), the new `references/` files render
as separate files across **all three** install trees — uniform structure, no
per-tool inlining.

**Sequencing note.** This feature (`feature-005`, FR1) is independent of FR3 and of
work-002's feature-001-profile-driven-generator at the methodology level — the lite
path works as plain `SKILL.md` prose. It is *easier* to land after work-002's
canonical generator (one canonical edit instead of four) and after FR3 (the
`references/` decomposition already exists). `aid-plan` resolves the exact slot;
`REQUIREMENTS.md §10` sequences **work-002 first**, then within `work-001-aid-lite`
FR3 (`feature-002`) before FR1 / FR2 / FR4 — so by the time FR1 lands both
prerequisites are in place.

### State Machines

The `aid-interview` state machine is extended (not redesigned). Two views:

**Full picture — `aid-interview` after FR1:**

```
                ┌─────────────┐
   /aid-interview │ State 1     │
   (first run) →  │ FIRST RUN   │ 1a KB · 1b INTERVIEW-STATE · 1c REQ scaffold
                └──────┬──────┘
                       ▼
                ┌─────────────┐
                │ State       │  ask T1·T2·T3 → deterministic rule
                │ TRIAGE      │
                └──┬───────┬──┘
            FULL  │       │  LITE
                  ▼       ▼
        ┌──────────────┐  ┌──────────────────────────────┐
        │ 1d → States  │  │ L1 CONDENSED-INTAKE          │
        │ 2–7          │  │   ▼                          │
        │ (full path,  │  │ L2 TASK-BREAKDOWN ──┐        │
        │  unchanged)  │  │   ▼                 │ escalate│
        │              │◄─┼─ L3 LITE-REVIEW ────┘ to FULL│
        └──────────────┘  │   │  grade ≥ min            │
                          │   ▼                          │
                          │ L4 LITE-DONE → /aid-execute  │
                          └──────────────────────────────┘
```

**Lite-path sub-machine — transitions:**

| From | Event | To |
|------|-------|----|
| TRIAGE | rule verdict = LITE | L1 CONDENSED-INTAKE |
| L1 | intake complete | L2 TASK-BREAKDOWN |
| L1 / L2 / L3 | escalation triggered | full path (1d / State 3) — `**Path:** escalated` |
| L2 | tasks written | L3 LITE-REVIEW |
| L3 | grade < minimum (context wrong) | L1 |
| L3 | grade < minimum (breakdown wrong) | L2 |
| L3 | grade ≥ minimum | L4 LITE-DONE |
| L4 | — | terminal (hand-off to `/aid-execute`) |

**Resume detection** (filesystem is the only source of truth): on a re-run,
`INTERVIEW-STATE.md` `**Path:** lite` + presence/absence of the work-root `SPEC.md`
sections and `tasks/` files determines re-entry at L1, L2, or L3 — mirroring how the
full path's State Detection inspects section status and feature folders.

**`**Path:** escalated` re-entry.** A re-run finding `**Path:** escalated` routes
to the **full-path State Detection** (today's States 2–7 / Section Status logic) —
escalation has handed the work to the full path, and re-entry must continue there.
One mid-escalation interrupt window exists: if the recoverable signature
"`**Path:** escalated` **and** the lite work-root `.aid/{work}/SPEC.md` still
present" is observed, escalation step 4 (delete the work-root `SPEC.md`) did not
complete. Resume detection treats this as "re-seed not yet confirmed" and replays
escalation steps 1 → 4 idempotently: re-seed `REQUIREMENTS.md` from the still-present
work-root `SPEC.md` (overwriting any partial seeded sections), then delete the
work-root `SPEC.md`. After that delete, the signature collapses to the normal
`**Path:** escalated` + no work-root `SPEC.md` state and detection falls through to
the full-path State Detection.

One pre-triage resume window must be handled explicitly: a first run interrupted
**after sub-step 1b** (which creates `INTERVIEW-STATE.md`) **but before State
TRIAGE** leaves an `INTERVIEW-STATE.md` with **no `**Path:**` field** and **no
`## Triage` block**, alongside only the empty `REQUIREMENTS.md` scaffold from 1c.
Because the spec's default rule reads an absent `**Path:**` as `full`, a naive
resume would silently skip triage and enter State 3. Resume detection therefore
special-cases this signature — `INTERVIEW-STATE.md` present, `**Path:**` absent,
`## Triage` block absent, and REQUIREMENTS.md still an empty scaffold — and
**re-enters at State TRIAGE**, not State 3. The absent-`**Path:**`-reads-as-`full`
rule applies only to works whose Interview is already in progress past triage (a
non-empty REQUIREMENTS.md or any section status), preserving zero-migration
behaviour for pre-feature-005 in-flight works.

### Migration Plan

The lite path is **additive** — no existing artifact schema breaks (NFR2).

1. **No new artifact type.** The lite path reuses the existing `SPEC.md` artifact —
   it only places one at the work root instead of per feature. `INTERVIEW-STATE.md`
   gains two **optional/additive** fields. Existing in-flight `.aid/` workspaces have
   no `**Path:**` field — absent `**Path:**` is read as `full`, so every existing
   work continues on today's behaviour with zero migration.
2. **`aid-execute` back-compat.** The "resolve the delivery descriptor" rule is a
   superset of today's behaviour: if `PLAN.md` exists it is used exactly as now; the
   work-root `SPEC.md` is consulted as the descriptor only when `PLAN.md` is absent.
   Existing works (all of which have `PLAN.md`) are unaffected. Note: a full-path
   work never has a `SPEC.md` *at the work root* — its SPECs are inside
   `features/feature-NNN/` — so there is no ambiguity between the two shapes.
3. **`task-NNN.md` two-zone migration (decision A).** Merging `task-NNN-STATE.md`
   into `task-NNN.md` is a **repo-wide** change, not scoped to this feature; it is
   coordinated with the other Wave-1 features that touch the task artifact. The lite
   path simply consumes the resulting two-zone `task-NNN.md`. In-flight works with
   separate `task-NNN-STATE.md` files migrate per that repo-wide change's plan; the
   lite path introduces no additional migration burden.
4. **No retroactive routing.** Triage runs only in State TRIAGE of a *first* run.
   Works already past Interview are never re-triaged.
5. **Template + data-model updates.** Add the lite-path `SPEC.md` template variant
   under `templates/`. **Create the `INTERVIEW-STATE.md` template** — no
   `templates/interview-state.md` file exists in the repo today (a pre-existing
   defect: the live `aid-interview/SKILL.md:174` already instructs "Copy the
   template from `../../templates/interview-state.md`" against a non-existent
   path). This feature owns creating that template file (carrying today's Section
   Status / Pending Q&A / Review History schema **plus** the new `**Path:**` field
   and the optional `## Triage` block). The dangling
   `aid-interview/SKILL.md:174` reference is a **co-dependency** that lands with
   this template-creation step — once the template exists, the existing skill
   reference resolves correctly with no further change. Also: update the
   `task-NNN.md` template at its real path **`templates/delivery-plans/task-template.md`**
   for the two-zone shape (decision A — coordinated repo-wide, not lite-specific).
   Note the lite-path work-root `SPEC.md` placement in
   `.aid/knowledge/data-model.md` — specifically, extend **§2.4 SPEC.md
   (per-feature)** with a sub-note that the lite path writes ONE consolidated
   instance at the work root (`.aid/work-NNN/SPEC.md`) carrying merged spec +
   PLAN-level content, and update **§3.2 Cardinality** to reflect the
   one-per-lite-work cardinality (no new artifact id — `SPEC.md` already exists).
   If the implementer judges that the existing §2.4 heading should be renamed to
   cover both placements (e.g. `SPEC.md (per-feature or work-root for lite path)`),
   that is at their discretion. These land via the cross-tree rule executed by
   work-002's feature-001-profile-driven-generator (per the §10 build order, the
   generator ships first).
