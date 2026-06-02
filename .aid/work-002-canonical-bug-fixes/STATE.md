# Work State — work-002-canonical-bug-fixes

> **Status:** Detailing — complete (lite path; 14 tasks; next: /aid-execute)
> **Phase:** Detail — complete
> **Minimum Grade:** {resolved at runtime by `bash .claude/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-06-02
> **User Approved:** no

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy. One STATE.md per `.aid/work-NNN-{name}/` directory.

## Triage

> Populated by `aid-interview` TRIAGE state for lite-path works.

- **Path:** lite
- **Decision rationale:** T1=single concern (correct a fixed set of known defects) + T2=bounded
  (13 confirmed-real findings in 2 scripts + 7 agent files) + T3=bug-fix, not new feature → lite path
  (LITE-BUG-FIX). Scaffolded directly from the Copilot-findings analysis rather than via an
  interactive interview.

## Escalation Carry

> Written by `aid-interview` lite→full escalation. Present only when a work started on the lite path and was escalated to full.

_none_

## Interview Status

**Status:** N/A (lite path — condensed intake captured directly in SPEC.md)

## Features Status

> Lite path has no per-feature decomposition; the single SPEC.md is the source.

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| — | (lite — single SPEC.md) | Ready | — | 0 | LITE-BUG-FIX; 13 real findings + 1 regenerate/verify task |

## Plan / Deliveries

> Lite path uses a single delivery-001.

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Detailed | 7 | Canonical script + agent bug fixes (one task per document); final task regenerates the 3 install trees |

## Tasks Status

> One row per task from SPEC.md execution graph. Tracks /aid-execute progress per task.

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 1 | task-001 | IMPLEMENT | 1 | Pending | — | — | complexity-score.sh — A1 Type match, A2 portable awk, A3 lite/recipe graph, A4 cycle guard |
| 2 | task-002 | IMPLEMENT | 1 | Pending | — | — | compute-block-radius.sh — B1 graph heading, B2 exit-2 contract, B3 leaf radius (+B5), B4 `--delivery-id` |
| 3 | task-003 | CONFIGURE | 1 | Pending | — | — | D1 heartbeat/Bash (interviewer, tech-writer; exempt simple-formatter) |
| 4 | task-004 | DOCUMENT | 1 | Pending | — | — | D2 discovery-quality infrastructure.md skeleton |
| 5 | task-005 | DOCUMENT | 1 | Pending | — | — | D3+D4 discovery-reviewer doc count + ledger complete-table contract |
| 6 | task-006 | DOCUMENT | 2 | Pending | — | — | D6 reviewer.md File Writing section (mirrors task-005) |
| 7 | task-007 | CONFIGURE | 3 | Pending | — | — | Regenerate 3 trees + full test suite |

## Deploy Status

> One row per delivery from /aid-deploy. Tracks deploy lifecycle.

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Cross-phase Q&A (Pending)

> Consolidated open questions across all phases of this work.

_none_

## Delivery Gates

> One block per delivery from PLAN.md, written by the delivery-gate closing step of `aid-execute`.

_none yet_

## Quick Check Findings

> One block per task, keyed by task-id. Written by `writeback-state.sh --findings` during the per-task quick-check step of `aid-execute`.

_none yet_

## Lifecycle History

> One row per phase transition or gate approval. Append-only audit trail.

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-02 | Work created (lite, LITE-BUG-FIX) | — | Scaffolded from Copilot-findings analysis; isolated from work-001-aid-housekeep (disjoint canonical files) |
| 2026-06-02 | Specify (lite SPEC.md) | — | 13 confirmed-real findings (A1–A4, B1–B4, D1–D4, D6) in scope; A5/C1 false positives + D5 already-handled excluded |
| 2026-06-02 | Detail | — | 14 tasks (13 fixes + 1 regenerate/verify); same-file edits serialized; 5 waves. |
| 2026-06-02 | Detail (revised) | — | Merged same-document tasks → 7 (one fix task per document + regenerate); 6 fix tasks parallel, 3 waves. Next: /aid-execute |
