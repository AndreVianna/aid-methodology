---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-08-13"
minimum_grade: "A"
user_approved: yes
lifecycle: Running
phase: Execute
active_skill: none
updated: "2026-08-14T15:45:00Z"
pause_reason: --
block_reason: --
block_artifact: --
ticket_ref: --
---

# Work State -- work-011-methodology-cost

[!NOTE]
Created retroactively, mid-work. The tracking-discipline rule requires this file
before anything else happens, and it did not exist for phases 1 through 5a — the
agreements on the target artifact shape lived only in the conversation, with no
artifact on the branch to contradict a misremembering. One did occur: a shape
table was restated with `BLUEPRINT.md` surviving on the full path, contradicting
the settled decision that PLAN absorbs it. That is the failure this file exists
to prevent, so it is recorded here rather than quietly corrected.

## Pipeline State

| Field | Value |
|-------|-------|
| Path | full |
| Phase | Execute |
| Lifecycle | Running |
| Minimum grade | A |
| Branch | work-011 |

## Features State

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 001 | Cost measurement | Done | meter + gate model; 33 assertions |
| 002 | Artifact discipline | Done | Change Log removed repo-wide; AC verifiability rule |
| 003 | Traceability | Done | `AC-N` ids; task `Source` cites them |
| 004 | Artifact folding | In Progress | features->§11 landed; BLUEPRINT->PLAN and the Lite reduction outstanding |
| 005 | Derivation over authoring | In Progress | wave-map derived; Lite graph-from-DETAILs outstanding |
| 006 | Render and close-out | In Progress | rendered once mid-work to clear CI; owed again after feature 004 |

## Acceptance Criteria State

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Met | `test-cost-meter.sh` CM08 |
| AC-2 | Met | CM11-CM15 |
| AC-3 | Met | CM19-CM24, CM28+ |
| AC-4 | Met | 0 matches repo-wide |
| AC-5 | Met | `requirements-template.md § Verifiable Acceptance Criteria`, 5 citing sites |
| AC-6 | Met | `task-detail-template.md` `**Source:**` |
| AC-7 | Met | `test-derive-waves.sh` DW14-DW17 |
| AC-8 | Met | DW24-DW27 |
| AC-9 | Met | 10 broken citations fixed; sweep reports 0 |
| AC-10 | Met | 19 dangling anchors fixed; sweep reports 0 |
| AC-11 | Met | phase 5a |
| AC-12 | Not met | `delivery-blueprint-template.md` still exists; 46 files mention BLUEPRINT |
| AC-13 | Not met | shortcut engine still writes SPEC.md, PLAN.md, BLUEPRINT.md |
| AC-14 | Partially met | rendered once; goes stale again with the remaining work |

## Lifecycle History

Per FR-2 this file carries no revision table. Phase-by-phase history is in
`git log --follow` on this branch; each commit message states what it changed and
why.

## Cross-phase Q&A

### Q1 — Does the Lite path keep a PLAN?

**Resolved (owner, 2026-08-14):** No. One feature and one delivery means no
sequencing decision to record, so PLAN would exist only to hold a derived table.
The Lite path is `REQUIREMENTS.md` + `tasks/task-NNN/DETAIL.md` + `STATE.md`.

### Q2 — Store the Lite execution graph in REQUIREMENTS, or derive it?

**Resolved (owner, 2026-08-14):** Derive it. Each task DETAIL already carries
`Depends on`, so the graph is fully specified by the task set; a stored table is a
denormalised view that can disagree with what it came from. Establishes the
general rule: **store what was decided, derive what follows from it.**

### Q3 — Do judgment-based acceptance criteria get an escape hatch?

**Resolved (agent judgment, flagged for override):** Yes, narrowly. A judgment
criterion must name what is judged and against what standard, so it remains
checkable that the judgment happened against the stated bar. A strict rule would
either reject legitimate criteria or push authors into dishonest proxies. One
paragraph to delete if the owner prefers strict.

### Q4 — Contended files (`work-004`)

**Open.** 14 canonical files and 4 KB docs are modified on `origin/work-004`,
including `agents/aid-reviewer/AGENT.md`, five READMEs and four reviewer-briefs.
Per C-2 they are not contended; the prose sweep for those waits until work-004
lands. Note the four KB docs already carry edits from this branch's Change Log
work, so that conflict exists regardless.

## Dispatches

None. Every phase was executed directly rather than via dispatched sub-agents,
which is itself a finding: two real bugs shipped under 48 passing tests in phase 1
and were only found when the owner asked for an audit. Independent review is owed
before this work is considered done — the branch has had none.
