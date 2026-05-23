# Work State — work-NNN-{name}

> **Status:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
> **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
> **Minimum Grade:** {from .aid/knowledge/STATE.md}
> **Started:** {YYYY-MM-DD}
> **User Approved:** yes | no

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. Absorbs what used to be `INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N + (future) `DEPLOYMENT-STATE.md`.

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, task-NNN.md) keep their inline `## Change Log` sections — that's *content history* (what changed in the document), distinct from *process state* (where are we in the workflow). Both are useful; they live in different places.

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

## Lifecycle History

> One row per phase transition or gate approval. Append-only audit trail.

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| {YYYY-MM-DD} | Work created | — | Initial scaffold by aid-init |
