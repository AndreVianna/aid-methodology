---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-08-14"
minimum_grade: "A"
user_approved: no
lifecycle: Paused-Awaiting-Input
phase: Describe
active_skill: aid-describe
updated: "2026-08-14T19:22:00Z"
pause_reason: "Requirements drafted and complete -- awaiting owner approval and the four Q&A answers below"
block_reason: --
block_artifact: --
ticket_ref: --
---

# Work State -- work-012-review-loop-cost

[!NOTE]
Full multi-delivery work. The flattened single-delivery sections (`## Delivery
Lifecycle`, `### Tasks lifecycle`, `## Delivery Gate`) and their four frontmatter
scalars are deliberately absent per the work-state template: each delivery's own
lifecycle and gate will live in its `delivery-NNN/STATE.md`.

Base branch is `work-004` (pending merge), not `master` -- this work extends the
declared-review-criteria mechanism that work introduced, and that mechanism does not
exist on `master`.

**`work-004` is the only dependency** (owner decision, REQUIREMENTS.md C-1). Every other
live work, `work-011` included, is a read-only reference. Adding a second dependency
requires an owner decision that amends C-1 -- it is not something a later phase may assume.

## Pipeline State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`,
     `block_artifact`), written ONLY by `writeback-state.sh --pipeline ...` at every
     phase/state transition the pipeline performs (surgical frontmatter rewrite; never
     hand-edited). All values are closed enums so a deterministic reader needs no
     inference. This section retains the enum reference below for human readability. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**State:** In Progress  **Grade:** Pending

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-08-14 |
| 2 | Problem Statement | Complete | 2026-08-14 |
| 3 | Users & Stakeholders | Complete | 2026-08-14 |
| 4 | Scope | Complete | 2026-08-14 |
| 5 | Functional Requirements | Complete | 2026-08-14 |
| 6 | Non-Functional Requirements | Complete | 2026-08-14 |
| 7 | Constraints | Complete | 2026-08-14 |
| 8 | Assumptions & Dependencies | Complete | 2026-08-14 |
| 9 | Acceptance Criteria | Complete | 2026-08-14 |
| 10 | Priority | Complete | 2026-08-14 |

**Elicitation provenance.** This interview was conducted against a written brief rather
than a live turn-by-turn dialogue: the requester supplied the full proposal
(`.aid/knowledge/tech-debt.md` § L5) as the requirements input, together with the
sequencing, the three mandatory guards, the already-decided compatibility properties, the
one tension to confront early, and the out-of-scope list. Every section above was filled
from that brief and re-derived against this branch's disk. Where the brief did not decide
something, the gap is recorded as a Pending Q&A below rather than guessed.

**State is `In Progress`, not `Approved`.** COMPLETION's step 5 requires an explicit human
approval that has not been given. The four Pending Q&A entries below must also be answered
-- `Q-01` in particular changes NFR-1, which is the exit criterion of the whole work.

### Quality check (COMPLETION step 1)

| Check | Result |
|-------|--------|
| Every Must requirement in §5 has an acceptance criterion in §9 | Pass -- FR-1..FR-7 to AC-2/AC-3/AC-4; FR-8..FR-13 to AC-5/AC-6/AC-7/AC-8; FR-14 to AC-9; FR-15 to AC-1 |
| No contradictions between sections | Pass -- NFR-1 permits the executable surface §4 requires, and states the exit criterion that bounds it |
| §4 Scope consistent with §5 | Pass -- each in-scope bullet maps to at least one FR; each out-of-scope item maps to a constraint (C-2, C-3, C-4) |
| §7 Constraints do not conflict with §5 | Pass -- C-3 and C-4 constrain HOW the remedies land, not whether; FR-11 was written to satisfy C-3 |

### KB hydration assessment (COMPLETION step 2)

Performed, and the conclusion is **no KB write at this point.** Three reasons, each
sufficient:

1. The interview surfaced no new project fact. Its entire factual content already lives in
   `.aid/knowledge/tech-debt.md` § L5, which is where the proposal was authored.
2. C-5 makes a `.aid/knowledge/` edit an owner-authorized act, and no such authorization
   has been given for this work.
3. The KB edit this work will eventually owe -- documenting `oracle:` in
   `authoring-conventions.md` -- is a deliverable of the work itself, not hydration of the
   interview, and it lands with the change rather than ahead of it.

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-08-14 | Work created | -- | Scaffolded by /aid-describe FIRST-RUN on branch `cursor/work-012-review-loop-cost-8a59`, based on `work-004` |
| 2026-08-14 | Describe: FIRST-RUN -> CONTINUE -> COMPLETION | -- | All ten sections filled from the L5 brief and re-derived against disk |
| 2026-08-14 | Describe: COMPLETION -- paused | -- | PAUSE-FOR-USER-DECISION. Awaiting approval + Q-01..Q-04 |
| 2026-08-14 | Describe: constraint amendment (owner) | -- | Dependency set closed at one: `work-004` only. C-1 rewritten, C-2 generalised, the conditional meter reuse in §8 withdrawn. Still paused |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress.
     Never written here; feature progress is tracked via /aid-specify per-feature. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here). -->

### Q-01

- **Category:** Requirements / exit criterion
- **Impact:** Required
- **Status:** Pending
- **Context:** `work-004`'s owner revision (2026-08-14) redefined the "added mechanism"
  side of its NFR-2 as EXECUTABLE surface only, explicitly excluding authored instruction.
  Remedy 2 adds executable surface by design -- every oracle is a script -- so this is the
  first work where that definition bites. NFR-1 currently states the exit criterion as
  "an oracle is justified only where it REPLACES recurring human re-derivation, and the
  work measures the trade rather than asserting it", which is the requester's suggested
  framing. It needs owner ratification before Specify, because AC-11 is derived from it and
  it decides whether an oracle can ship at all.
- **Suggested:** Ratify as written. The four grounds the owner used in the `work-004`
  revision point the same way: an oracle is not a guard bolted onto prose, it is the
  removal of a recurring re-derivation, so the cost it adds is paid back per cycle rather
  than owed.

### Q-02

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Where does an oracle live on disk? L5's worked example writes
  `oracle: scripts/checks/g07-selector-partition.sh`, a project-relative path. But a
  criterion declared in a project's own `.aid/knowledge/authoring-conventions.md` is
  project-specific, while `G-07` is AID's own criterion about AID's own corpus -- and
  anything under `canonical/` renders into five `profiles/` trees and two dogfood trees.
  The choice decides whether an adopter's oracle and AID's own oracle share a resolution
  rule, and whether `NFR-5`'s single render covers them.
- **Suggested:** A project-relative path resolved from the repo root, so an adopter's
  oracle and AID's own resolve identically; AID's own oracles then live outside
  `canonical/` and stay out of the render chain. Confirm before Specify.

### Q-03

- **Category:** Requirements / measurement
- **Impact:** High
- **Status:** Pending
- **Context:** AC-1 requires a before-and-after measurement on a real artifact, and FR-15
  requires the before figure to be captured first. Which artifact and which gate are the
  measurement subject? It must be one that will actually run enough cycles after the change
  to produce a comparable after-figure.
- **Suggested:** Name the subject at Define, once the feature decomposition shows which
  gate this work itself will run most often -- this work's own specify gate is the obvious
  candidate, since it makes the work its own experiment.

### Q-04

- **Category:** Process
- **Impact:** Medium
- **Status:** Pending
- **Context:** Who generates an oracle, and when? FR-10 says "generated once", but not
  whether that happens when the criterion is authored, or lazily the first time a reviewer
  meets a criterion that ought to have one. This affects whether a criterion can be
  declared without its oracle existing yet -- which FR-8 permits, since absence is never a
  defect.
- **Suggested:** At criterion-authoring time when the author knows the check is mechanical;
  otherwise lazily, on the first cycle where a reviewer re-derives the same criterion twice.
  Confirm at Specify.

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
