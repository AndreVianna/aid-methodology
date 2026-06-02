# task-010: Cross-stage integration TEST — KB-DELTA → stub-no-ops → DONE

**Type:** TEST

**Source:** feature-001-skill-and-state-machine + feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-001, task-002, task-005, task-006, task-007, task-009

**Scope:**
- Author a canonical integration suite (e.g. `tests/canonical/test-housekeep-flow.sh`,
  auto-discovered by the `tests/canonical/test-*.sh` glob in `tests/run-all.sh`, sourcing
  `tests/lib/assert.sh`, runs under `timeout 300`) that exercises the **deterministic state
  transitions** of the delivery-001 state machine over a throwaway fixtured repo + `STATE.md`,
  driving the housekeep scripts (`housekeep-state.sh`, `branch-commit.sh`, `detect-delta.sh`,
  `scope-delta.sh`) — not the LLM prose bodies.
- Cover the delivery-001 end-to-end wiring contract from PLAN.md (Risk #2) and feature-001 SPEC
  § "Incremental-delivery stub no-op": with KB-DELTA functional, after KB-DELTA reaches
  `passed`/`skipped`, the **SUMMARY-DELTA and CLEANUP stub no-ops each record `skipped` and
  CHAIN through to DONE**, so a KB-refresh run terminates cleanly at `**State:** DONE`.
- Cover the gate/resume contract (AC9): a `stalled` KB-DELTA halts and a re-run resumes at
  KB-DELTA (re-entry row 3); a fully-`passed`/`skipped` machine reports "nothing to resume"
  (re-entry row 6, NFR2 idempotent no-op).
- Assert the hard-gate ledger (C1): SUMMARY-DELTA's stub does not "run" until `**KB Stage:**`
  reads `passed`/`skipped`; CLEANUP's stub does not "run" until `**Summary Stage:**` reads
  `passed`/`skipped`.
- **Forward-compat note (delivery-002):** this suite is the home for the SUMMARY-DELTA
  stub→real-body swap assertion. Per feature-003 SPEC § Testing, feature-003 ships **no new
  dedicated suite** (its staleness/grade logic is covered by `/aid-summarize`'s own suites and its
  gate-field write by `test-housekeep-state.sh`). When task-012 replaces the stub, this suite's
  state-transition coverage must still hold: a fully-`passed`/`skipped` machine still terminates at
  `**State:** DONE`, and the C1 hard-gate ledger (SUMMARY-DELTA gated on `**KB Stage:**`,
  CLEANUP gated on `**Summary Stage:**`) is unchanged — assert these against the deterministic
  `housekeep-state.sh` gate-ledger transitions, not the `/aid-summarize` delegation prose.

**Acceptance Criteria:**
- [ ] Deterministic, with clean setup/teardown (throwaway repo + STATE fixture), CI-wired via
  the existing `test-*.sh` glob (no edit to `run-all.sh`).
- [ ] Asserts a no-delta KB-DELTA → `skipped` → SUMMARY-DELTA stub `skipped` → CLEANUP stub
  `skipped` → `**State:** DONE` (clean termination of the delivery-001 KB-refresh run).
- [ ] Asserts a stalled KB-DELTA halts and a re-run resumes at KB-DELTA (not job 1) — AC9.
- [ ] Asserts the hard-gate ledger ordering (C1): no downstream stub advances before its
  upstream `**X Stage:**` reads `passed`/`skipped`.
- [ ] Asserts a fully-resolved run reports "nothing to resume" (re-entry row 6 — NFR2).
- [ ] All §6 quality gates pass; covers the source ACs (AC9, C1, NFR2, stub-no-op contract).
