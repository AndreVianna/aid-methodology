# Work State — work-NNN-{name}

> **Status:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
> **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
> **Minimum Grade:** {resolved at runtime by `bash .claude/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** {YYYY-MM-DD}
> **User Approved:** yes | no

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. Absorbs what used to be `INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N + (future) `DEPLOYMENT-STATE.md`.

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, task-NNN.md) keep their inline `## Change Log` sections — that's *content history* (what changed in the document), distinct from *process state* (where are we in the workflow). Both are useful; they live in different places.

## Triage

> Populated by `aid-interview` TRIAGE state for lite-path works. Left empty for full-path works (aid-interview runs the full interview flow instead).

- **Path:** lite | full
- **Work Type:** bug-fix | single-doc | small-refactor | small-new-feature | {omitted for full path}
- **Sub-path:** LITE-BUG-FIX | LITE-DOC | LITE-REFACTOR | LITE-FEATURE | — (absent for full path)
- **Sub-path (auto):** {auto-detected sub-path label, or — if overridden or full path}
- **Decision rationale:** {one sentence: why this path/sub-path was selected}
- **Override:** yes | no (yes = human changed auto-detected sub-path)
- **Recipe:** {recipe-name} | none

## Escalation Carry

> Written by `aid-interview` lite→full escalation (Steps 3–9 of `lite-to-full-escalation.md`).
> Present only when a work started on the lite path and was escalated to full.
> The CONTINUE state reads this section to avoid re-asking questions already answered
> during the lite-path session. See `references/state-continue.md § Escalation Carry`.

- **Escalated from:** {state name} (Sub-path: {sub-path value})
- **Escalated at:** {YYYY-MM-DDTHH:MM:SSZ}
- **Escalation rationale:** {one sentence}

### Captured Slot Values

- **{slot-name}:** {slot-value}
- (no slots captured — escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

- **SPEC.md:** present | absent — {notes on content available for seeding}
- **tasks/:** {N} task files present | absent

## Interview Status

**Status:** In Progress | Complete | Approved · **Grade:** {grade or Pending}

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Pending | — |
| 2 | Problem Statement | Pending | — |
| 3 | Users & Stakeholders | Pending | — |
| 4 | Scope | Pending | — |
| 5 | Functional Requirements | Pending | — |
| 6 | Non-Functional Requirements | Pending | — |
| 7 | Constraints | Pending | — |
| 8 | Assumptions & Dependencies | Pending | — |
| 9 | Acceptance Criteria | Pending | — |
| 10 | Priority | Pending | — |

## Features Status

> One row per feature. Tracks /aid-specify progress per feature.

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

> One row per delivery from PLAN.md. Tracks /aid-plan + /aid-detail completion.

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| _none yet_ | | | |

## Tasks Status

> One row per task from PLAN.md execution graph. Tracks /aid-execute progress per task. This is the iteration source for FR1's AC4 sub-unit drill-down on aid-execute/EXECUTE-WAVE.

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Deploy Status

> One row per delivery from /aid-deploy. Tracks deploy lifecycle.

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Cross-phase Q&A (Pending)

> Consolidated open questions across all phases of this work. Each entry: ID, source phase, category, impact, suggested answer, status. Cross-phase because the same question may originate in /aid-specify and apply to /aid-plan, etc.

### Q{N}: [{Phase}: {Category}: {Impact}]

- **Question:** {the actual question}
- **Context:** {why this matters}
- **Source:** {phase/skill that raised it}
- **Suggested:** {answer if inferrable, or —}
- **Status:** Pending | Answered | Skipped
- **Answer:** {filled when status is Answered}
- **Applied to:** {artifact(s) the answer was applied to}

## Delivery Gates

> One block per delivery from PLAN.md (or the single work-root SPEC.md delivery on the lite path), written by the delivery-gate closing step of `aid-execute`. Distinct from per-task quick-check findings — the gate aggregates those deferred [HIGH] rows (via `delivery-NNN-issues.md`) and runs a full grade.sh pass. Instances of the deferred-[HIGH] log live at `.aid/work-NNN/delivery-NNN-issues.md`; see `.claude/templates/delivery-issues.md` for the template.

### delivery-NNN

- **Reviewer Tier:** Small | Medium | Large
- **Grade:** {grade or Pending}
- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}

## Quick Check Findings

> One block per task, keyed by task-id. Written by `writeback-task-status.sh --findings` during the per-task quick-check step of `aid-execute`. Records the reviewer tier used and all [HIGH] / [CRITICAL] findings for that task. [CRITICAL] findings trigger an immediate fix-on-spot; [HIGH] findings are deferred to the delivery gate via `delivery-NNN-issues.md`. No grade is recorded here — grading is per-delivery, not per-task.

### task-NNN

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**
  - [CRITICAL] {description} — {source-file:line} — Fixed-on-spot
  - [HIGH] {description} — {source-file:line} — Deferred-to-gate

## Lifecycle History

> One row per phase transition or gate approval. Append-only audit trail.

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| {YYYY-MM-DD} | Work created | — | Initial scaffold by aid-config |
