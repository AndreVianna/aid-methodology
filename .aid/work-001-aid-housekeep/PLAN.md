# Plan — work-001-aid-housekeep

> Delivery roadmap for the new optional `/aid-housekeep` skill. Each delivery is a
> standalone-functional MVP that incrementally wires one more stage into the
> `KB-DELTA → SUMMARY-DELTA → CLEANUP` state machine. Sequence approved by user 2026-06-02.

## Deliverables

### delivery-001: KB Delta Refresh (MVP)
- **What it delivers:** A runnable `/aid-housekeep` that, on an `aid/housekeep-*` branch,
  reconciles KB drift since the last approval **agent-driven**: the agent inspects the actual
  repo content against the KB's claims (git history is an optional hint, not a boundary), then
  refreshes only the affected KB docs by delegating to `/aid-discover`'s targeted re-entry +
  approval gate (via a synthesized `Impact: Required` Q&A entry). The skeleton ships the
  **full** state machine, but **KB-DELTA is the only functional stage**: the SUMMARY-DELTA and
  CLEANUP stages ship as **inert stub no-ops** (each records `**<X> Stage:** skipped` and CHAINs
  onward to DONE — the skeleton's incremental-delivery stub-no-op contract, feature-001 SPEC
  § "Incremental-delivery stub no-op"). So a KB-refresh run terminates cleanly through to DONE,
  making this delivery a complete, usable KB-refresh tool on its own. (`--cleanup-only` is not
  yet offered — it arrives with delivery-003.)
- **Features:** feature-001-skill-and-state-machine (skeleton: thin-router SKILL.md, state
  machine, run-state, gate/commit/resume, distribution), feature-002-kb-delta-refresh
  (agent-driven KB reconciliation: inspect repo content vs KB claims + scope/confirm +
  `/aid-discover` delegation via a synthesized Q&A entry — **no detection/scoping scripts, no
  `Approved-At-Commit:` field, no edit to `/aid-discover`**)
- **Depends on:** — (foundation)
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | — |
| task-003 | task-001, task-002 |
| task-004 | task-001, task-002, task-003 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-002 |

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
| task-005 | task-001, task-002, task-003, task-004 |

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
| task-006 | — |
| task-007 | task-003 |
| task-008 | task-001, task-002, task-003, task-006, task-007 |

| Can Be Done In Parallel |
|------------------------|
| task-006, task-007 |

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The KB-DELTA stage is **agent-driven** (LLM judgment, not a deterministic script): the agent decides what has drifted, which docs are affected, and what the correction is. There is no detection/scoping script to unit-test, so a mis-scoped or missed-drift run is a judgment risk, not a code-path bug. (The 2026-06-02 pivot also removed the former `/aid-discover` `Approved-At-Commit:` edit, so delivery-001 no longer modifies any existing skill — that earlier regression risk is gone.) | M | The agent reuses `/aid-discover`'s proven REVIEW→APPROVAL gate (the human approval is the backstop against bad scope), and confirm-and-adjust (NFR3) puts the proposed scope in front of the user before any change. The deterministic transitions the body wires (`**KB Stage:**` gate ledger, resume) are covered by `test-housekeep-state.sh`; the agent-driven prose body is verified by dogfooding + render-drift CI / generator self-tests (no bespoke integration test — AID has no E2E tier). No existing skill is edited, so there is no cross-skill regression surface. |
| 2 | **Incremental state-machine wiring** across deliveries: delivery-001 ships the full machine with KB-DELTA functional and SUMMARY-DELTA/CLEANUP as **stub no-ops**; deliveries 002/003 each replace a stub with real logic. Each replacement must preserve the halt/resume + hard-gate contract (feature-001's `## Housekeep Status` resume table), and the stub no-ops themselves must record `skipped` + CHAIN cleanly so delivery-001 terminates at DONE. | M | feature-001's state-detection/resume table + the explicit **incremental-delivery stub-no-op contract** (feature-001 SPEC § "Incremental-delivery stub no-op") are the single source of truth; each delivery adds/replaces a stage body + its gate predecessor check, re-runs feature-001's skeleton suites (state/resume, branch-commit) plus any deterministic-helper suite it owns (delivery-003's cleanup-classify), and is otherwise verified by dogfooding + render-drift CI — there is no bespoke integration test (AID has no E2E tier). (Args are handled in `SKILL.md` `## Arguments` + State Detection prose — no dedicated arg-parse script or suite.) |
| 3 | All three stages share feature-001's `branch-commit.sh` + `housekeep-state.sh` helpers (shipped in delivery-001). A bug there affects every stage. | M | These helpers are delivery-001's tested deterministic core (skeleton suites: state/resume, branch-commit) — landed and green before any stage logic builds on them. |
