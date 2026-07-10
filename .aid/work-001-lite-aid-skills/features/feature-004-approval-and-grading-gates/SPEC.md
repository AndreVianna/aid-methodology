# Approval & Grading Gates

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.5 (FR-10, FR-11), C-2, C-5, NFR-10 | /aid-define |
| 2026-07-08 | STRUCTURE/NAMING amendment cascade: `BLUEPRINT.md` joins the graded definition-doc set (Pass 1) per FR-11; task defs renamed `SPEC.md` → `DETAIL.md` (Pass 2); the (post-execution) delivery gate reads its criteria from `BLUEPRINT.md § GATE CRITERIA` (feature-001 short / feature-015 full — the shipped `PLAN.md` mis-wire fix) | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.5 (FR-10, FR-11)
- REQUIREMENTS.md C-2, C-5, NFR-10

## Description

Preserve AID's quality and human-gating guarantees on the shortcut path. Every shortcut stops
after Detail and never executes: the produced documents (`REQUIREMENTS.md`, `SPEC.md`,
`PLAN.md`, `BLUEPRINT.md`, and the `tasks/` set of `DETAIL.md` files) must be validated and
approved by the user before any execution, which is a separate, user-initiated `/aid-execute` run. Before that approval gate is
reached, each generated document must pass its phase's Grading Gate — a dispatched `aid-reviewer`
writes the 7-column ledger, `grade.sh` computes the grade, and the document must clear the
resolved `minimum_grade` (the live gate, A+) through a REVIEW to FIX loop. The shortcut removes
information-capture red tape, not the quality gates: every document is reviewed and graded
exactly as on the full path, reusing the existing `aid-reviewer` and `grade.sh` machinery.

## User Stories

- As an AID adopter, I want the shortcut to stop after Detail and wait for my approval so nothing
  executes until I have validated the generated documents.
- As an AID maintainer, I want every generated document graded to at least the minimum grade
  before approval so the shortcut's speed never sacrifices AID's quality gates.

## Priority

Must

## Acceptance Criteria

- [ ] Given a shortcut run, when it reaches the end of Detail, then it halts at the approval gate
  and no execution happens until the user approves and separately runs `/aid-execute`. (AC-3;
  FR-10)
- [ ] Given each generated document (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, and
  each task `DETAIL.md`), when the Grading Gate runs, then the document has passed at >=
  `minimum_grade` via the REVIEW to FIX loop before the FR-10 approval gate is reached. (AC-11;
  FR-11)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-A7` (batched review is already how the delivery
> gate works) and `quality-gates.md`. This feature adds **no new grading machinery** — it
> reuses `grade.sh`, the `aid-reviewer` agent, the 7-column ledger, and `read-setting.sh`, and
> is hosted as the GATE + APPROVAL-HALT states of the **shortcut engine (feature-003)**, run
> over the **flattened work (feature-001)**.

### Data Model / Schemas

**1. The reviewer ledger (reused verbatim).** Every gate writes the canonical 7-column table
(`reviewer-ledger-schema.md`; `CLAUDE.md § Review output format`), and nothing else, to
`.aid/.temp/review-pending/<scope>.md`:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
```

Severity (closed, bracketed): `[CRITICAL] | [HIGH] | [MEDIUM] | [LOW] | [MINOR]`. Status (closed,
plain): `Pending | Fixed | Recurred | Accepted | OOS | Invalid`. `grade.sh` counts only rows
whose Status is `Pending`/`Recurred`, by the Severity column position (`grade.sh` header
"cols[3] = Severity … cols[4] = Status"). Separation of concerns holds: the reviewer sets
Status, the fixer addresses Pending/Recurred but never marks `Fixed`, the orchestrator runs
`grade.sh` and deletes the ledger at DONE (`quality-gates.md § The Reviewer Ledger`).

**2. Two batched passes (A-7), not one-per-document.** The grading machinery is generic and
already supports one reviewer over many artifacts — the delivery gate dispatches ONE reviewer
over a whole delivery's artifacts (`state-delivery-gate.md § Gate Reviewer Inputs`: `{{ARTIFACTS}}`
= the delivery branch diff + every task's STATE.md row + the PLAN.md delivery section as context —
unchanged). Its **separate** acceptance-**criteria** input (the shipped mis-wire that reads
`PLAN.md`, `state-delivery-gate.md` ~line 182) is repointed by **feature-015** to
`BLUEPRINT.md § GATE CRITERIA`.
So the definition documents batch into **two** dispatches, each one ledger, cutting sub-agent
round-trips (NFR-5) without weakening FR-11:

| Pass | Artifacts under review | Ledger scope |
|---|---|---|
| 1 (definition docs) | `REQUIREMENTS.md` + `SPEC.md` + `PLAN.md` + `BLUEPRINT.md` | `.aid/.temp/review-pending/shortcut-<work>-defn.md` |
| 2 (task set) | every `tasks/task-NNN/DETAIL.md` | `.aid/.temp/review-pending/shortcut-<work>-tasks.md` |

Each document still clears `minimum_grade` via its own REVIEW->FIX loop within the pass; the
lever A-7 pulls is dispatch **granularity** only, a pure `/aid-specify` policy choice with no
contract impact.

**3. minimum_grade resolution.** Resolved per skill through the standard 3-tier order
(`quality-gates.md § Minimum-Grade Thresholds`): per-skill override -> `review.minimum_grade`
-> hardcoded `A`, via
`bash canonical/aid/scripts/config/read-setting.sh --skill <shortcut-skill> --key minimum_grade
--default A`. The **operative live gate for this work is A+** (the settled decision); the gate
loops until each document's computed grade is `>= A+`. (A+ = zero findings per the rubric;
`grading-rubric.md` Grade Calculation.) The shortcut engine's GATE resolves the floor via
`read-setting.sh --skill <shortcut> --key minimum_grade --default A+` — i.e. **the shortcut path's
built-in default is A+, not the global `A`**. This keeps the A+ gate load-bearing for adopters
(whose `.aid/settings.yml` global `review.minimum_grade` defaults to `A`) without shipping 69
per-skill settings entries; in this repo the global is already `A+` (owner directive), so it is
belt-and-suspenders here. A project may still lower it with an explicit per-skill override.

### Feature Flow — REVIEW -> FIX -> APPROVAL

The engine reaches GATE after DETAIL (feature-003). For each of the two passes, run the
universal grading loop (`quality-gates.md § The Per-Phase REVIEW to FIX Loop`):

1. **REVIEW.** Dispatch `aid-reviewer` in a **clean context** (never inherits the author's
   reasoning; `architecture.md § Agent Dispatch`), using a 5-section brief the engine
   **hand-crafts inline** per `reviewer-dispatch.md` § One-off reviews (there is **no** shared
   `reviewer-brief.md` — that file exists only per-skill under `canonical/skills/<skill>/references/`):
   `ARTIFACTS UNDER REVIEW`, `CONTEXT`, `RUBRIC`, `OUT OF SCOPE`, `OUT-OF-SCOPE FINDINGS POLICY` —
   to prevent scope leak. It upserts findings as `Pending` into the pass's ledger.
2. **GRADE.** Run `grade.sh <ledger>` (or `--explain`). If grade `>= minimum_grade` -> pass
   clears, advance to the next pass (or to APPROVAL after pass 2).
3. **FIX.** If grade `< minimum_grade`, address every `Pending`/`Recurred` row (the fixer does
   not set `Fixed`), then re-REVIEW (reviewer re-verifies on disk, updates Status, appends new
   findings). Repeat until `>= minimum_grade`. The loop is bounded by the same safeguards as
   elsewhere: same grade across 3 cycles escalates to human judgment (`quality-gates.md § The
   Per-Phase REVIEW to FIX Loop`).

**Where grades are recorded.** These are **definition-phase** gates (the shortcut's analog of
the `/aid-specify` / `/aid-plan` / `/aid-detail` per-phase gates), so each pass's cleared grade
is recorded in the work-root `STATE.md` `## Lifecycle History` (append-only). (In the flattened
layout there is no `features/{feature}/SPEC.md`, so the DERIVED `## Features State` Spec-Grade
column does not apply — Lifecycle History is the authoritative record.) They are **distinct** from
the post-execution `## Delivery Gate` block (feature-001's
A-8 promotion), which `/aid-execute` fills later after the tasks run — reading its criteria from
`BLUEPRINT.md § GATE CRITERIA` (feature-001 short / feature-015 full). This avoids conflating the
pre-Execute definition gates with the post-Execute delivery gate.

**APPROVAL-HALT (FR-10 / NFR-10).** Once both passes clear, the engine presents the flattened
work and **STOPS** — no branch is created, no task executes. Execution is a separate,
user-initiated `/aid-execute` run. The pipeline never auto-advances (`architecture.md §
Invariants` "Human-gated advancement"); a grade `>= minimum` is necessary but not sufficient —
the human gate must also pass (`pipeline-contracts.md § Invariants`). At halt the work-root
`STATE.md` Pipeline State is `Paused-Awaiting-Input` and the promoted `## Delivery Lifecycle`
State is `Specified` (tasks defined, not yet `Executing`).

**Reviewer-tier invariant (C-2).** The engine authors via `aid-architect` (Large); the gate
reviewer is `aid-reviewer` (Large). Reviewer tier `>=` executor tier and the writer never grades
its own work (`quality-gates.md § Minimum-Grade`; `architecture.md § Agent Dispatch`).

### Layers & Components (canonical files + reuse)

| Component | Change |
|---|---|
| `canonical/aid/templates/shortcut-engine.md` | host the GATE (2 batched passes) + APPROVAL-HALT states + the minimum_grade resolution call — the seam co-authored with feature-003 |
| `canonical/aid/scripts/grade.sh` | **reused as-is** (no change) |
| `canonical/agents/aid-reviewer/AGENT.md` | **reused as-is** |
| `canonical/aid/templates/reviewer-ledger-schema.md`, `reviewer-dispatch.md` | **reused as-is** (ledger schema + dispatch-brief structure); the engine hand-crafts its one-off brief inline per `reviewer-dispatch.md` § One-off reviews — **no shared `reviewer-brief.md` exists** |
| `canonical/aid/scripts/config/read-setting.sh` | **reused as-is** (minimum_grade resolution) |

Feature-004 introduces **no new files** — its surface is the gate/approval prose authored into
the engine (feature-003) plus reuse of the existing quality-gate machinery. This directly
satisfies NFR-8 (shared machinery over bespoke) and the "removes red tape, not the quality
gates" objective (FR-11).

### Testing strategy

- **Gate integration** (canonical test): assert the engine's GATE prose resolves minimum_grade
  via `read-setting.sh --skill <shortcut> --key minimum_grade --default A+` (the shortcut floor is A+), drives `grade.sh`
  over the two named ledger scopes, and loops REVIEW->FIX until `>= A+` — reusing the existing
  `grade.sh` unit tests for the computation itself.
- **Halt proof** (fixture): after both passes clear, the engine terminates at APPROVAL-HALT with
  no branch created and no task in any state past `Pending` — proving FR-10/AC-3 (no execution
  before user approval).
- **Batching** (assertion): exactly two reviewer dispatches / two ledgers for a representative
  work (not one-per-document) — the A-7 NFR-5 win — while every document (`REQUIREMENTS.md`,
  `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, and each task `DETAIL.md`) individually clears the floor
  (AC-11).

Seams: this gate runs inside the **shortcut engine (feature-003)** over the **flattened work
(feature-001)**; the `## Delivery Gate` block those features define is written later by
`/aid-execute`, not by these definition-phase gates.
