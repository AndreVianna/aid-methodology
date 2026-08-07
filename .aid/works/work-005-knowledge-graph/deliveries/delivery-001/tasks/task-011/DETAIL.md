# task-011: Re-issue feature-002's D10 decision record against the current SPEC

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-011/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** feature-002-graph-rendering-research -> delivery-001 (Wave 1)

**Depends on:** task-002, task-010

**Scope:**
- `deliveries/delivery-001/research/rendering-decision-record.md` exists but is **stale, not merely
  incomplete**: it is dated 2026-07-28 and its Part 1 resolves Q2 against the baseline the
  2026-07-29 amendments voided — six renderer classes, five hard screens, accessibility cost as a
  per-candidate dimension, A-5's node bounds. feature-002's own SPEC carries the audit table naming
  each voided premise.
- Re-issue the record so every D10 required part is discharged by a live stage: Stage 1
  (`research/rendering-stage1-webgl-probe.md`, done), Stage 2a (task-003), Stage 2b (task-010),
  Stage 3 (task-002).
- The re-issued record is the single document three downstream tasks read their firing conditions
  off: task-017 (canvas sizing and runtime prerequisites), task-019 (feature-011's `S2` carve-out)
  and task-023 (feature-012's dependency-packaging gate). **This is BLUEPRINT edge 2** — feature-002
  before features 008, 011 and 012 — and those three tasks depend on this one.

**Acceptance Criteria:**
- [ ] Every D10 required part is present and attributed to the stage that discharged it; nothing is
      carried over from the superseded revision without being re-derived
- [ ] The superseded-baseline audit table is carried forward rather than silently dropped — a reader
      who has seen the 2026-07-28 record must be able to tell that its absence is deliberate
- [ ] The runtime-prerequisite sentence is stated as prose AC-6 can be checked against, and is
      quotable verbatim by feature-007 and feature-010 without paraphrase
- [ ] feature-011's `S2` firing condition and feature-012 D6's gate firing condition are each
      readable off this document as a yes/no, not inferred
- [ ] No renderer comparison is reopened — Q9 decided, and reporting a failure with evidence is a
      different act from re-scoring candidates
- [ ] AC-S3 still holds across the re-issued record: no bench size is asserted by this feature
- [ ] No permanent artifact cites this document (work folders are transient); the ship-time KB
      content it feeds is task-026's to write
- [ ] **Accuracy verified against the current codebase** (DOCUMENT type-default,
      `task-decomposition.md`:182). Load-bearing here rather than a formality: the record being replaced
      was wrong *because* it was verified against a baseline that later moved, so verify every re-issued
      part against the SPEC as it stands at execution time, not against this task's description of it
- [ ] All section-6 quality gates pass
