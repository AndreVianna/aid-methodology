# Plan — work-001-aid-housekeep

> Delivery roadmap for the new optional `/aid-housekeep` skill. Each delivery is a
> standalone-functional MVP that incrementally wires one more stage into the
> `KB-DELTA → SUMMARY-DELTA → CLEANUP` state machine. Sequence approved by user 2026-06-02.

## Deliverables

### delivery-001: KB Delta Refresh (MVP)
- **What it delivers:** A runnable `/aid-housekeep` that, on an `aid/housekeep-*` branch,
  detects KB drift since the last approval (SHA-anchored, online-first with permissioned
  offline fallback) and refreshes only the affected KB docs by delegating to `/aid-discover`'s
  targeted re-entry + approval gate, recording `Approved-At-Commit:`. The skeleton ships the
  **full** state machine, but **KB-DELTA is the only functional stage**: the SUMMARY-DELTA and
  CLEANUP stages ship as **inert stub no-ops** (each records `**<X> Stage:** skipped` and CHAINs
  onward to DONE — the skeleton's incremental-delivery stub-no-op contract, feature-001 SPEC
  § "Incremental-delivery stub no-op"). So a KB-refresh run terminates cleanly through to DONE,
  making this delivery a complete, usable KB-refresh tool on its own. (`--cleanup-only` is not
  yet offered — it arrives with delivery-003.)
- **Features:** feature-001-skill-and-state-machine (skeleton: thin-router SKILL.md, state
  machine, run-state, gate/commit/resume, distribution), feature-002-kb-delta-refresh (KB
  detection + path→doc scoping + `/aid-discover` delegation + the D1 approval-writeback edit)
- **Depends on:** — (foundation)
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | — |
| task-003 | task-001, task-002 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | — |
| task-007 | task-003, task-004, task-005, task-006 |
| task-008 | task-001, task-002, task-003, task-004, task-005, task-006, task-007 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-002, task-006 |
| task-003, task-004, task-005 |

### delivery-002: Summary Reconciliation
- **What it delivers:** Inserts the `SUMMARY-DELTA` stage between the KB gate and `DONE`. After
  a KB refresh, reconciles `knowledge-summary.html` by delegating to `/aid-summarize`'s
  STALE-CHECK + two-grade gate (coarse/date-based; no-op when current). The full sequence
  becomes `KB-DELTA → SUMMARY-DELTA → DONE`.
- **Features:** feature-003-summary-delta-refresh
- **Depends on:** delivery-001
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-009 | task-001, task-002, task-003, task-007 |

| Can Be Done In Parallel |
|------------------------|
| — (single task) |

### delivery-003: .aid/ Cleanup
- **What it delivers:** Adds the terminal `CLEANUP` stage — a tiered, user-confirmed checklist
  that sweeps stale `.aid/` artifacts (`git rm` tracked / `rm` untracked, one commit, never
  push) with the work-folder safety matrix (merged-to-`master` + concluded + active-folder
  guard). Also enables the `--cleanup-only` invocation. The full sequence becomes
  `KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE`.
- **Features:** feature-004-aid-cleanup
- **Depends on:** delivery-001 (skeleton). Runtime-independent of delivery-002 via
  `--cleanup-only`; in the **full** sequence, CLEANUP is reached only when `**Summary Stage:**`
  reads passed/skipped — which the delivery-001 SUMMARY-DELTA stub no-op already satisfies
  (records `skipped`) until delivery-002 ships the real summary stage. Sequenced last per the
  C1 ordering rule.
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-010 | — |
| task-011 | task-003 |
| task-012 | task-001, task-002, task-003, task-010, task-011 |
| task-013 | task-001, task-002, task-008, task-010, task-011, task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-010, task-011 |

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | delivery-001 modifies an **existing** skill (`/aid-discover`'s `state-approval.md` — the D1 `Approved-At-Commit:` writeback). A regression could break the discover approval flow that the rest of the pipeline depends on. | H | The edit is specified as idempotent + back-compatible (older KBs lack the field until next approval → AC2 bootstrap). Guarded by CI render-drift + the `/aid-discover` self-tests; verify the discover flow after the edit. |
| 2 | **Incremental state-machine wiring** across deliveries: delivery-001 ships the full machine with KB-DELTA functional and SUMMARY-DELTA/CLEANUP as **stub no-ops**; deliveries 002/003 each replace a stub with real logic. Each replacement must preserve the halt/resume + hard-gate contract (feature-001's `## Housekeep Status` resume table), and the stub no-ops themselves must record `skipped` + CHAIN cleanly so delivery-001 terminates at DONE. | M | feature-001's state-detection/resume table + the explicit **incremental-delivery stub-no-op contract** (feature-001 SPEC § "Incremental-delivery stub no-op") are the single source of truth; each delivery adds/replaces a stage body + its gate predecessor check and re-runs feature-001's skeleton suites (state/resume, branch-commit) plus its own stage suite. (Args are handled in `SKILL.md` `## Arguments` + State Detection prose — no dedicated arg-parse script or suite.) |
| 3 | All three stages share feature-001's `branch-commit.sh` + `housekeep-state.sh` helpers (shipped in delivery-001). A bug there affects every stage. | M | These helpers are delivery-001's tested deterministic core (skeleton suites: state/resume, branch-commit) — landed and green before any stage logic builds on them. |
