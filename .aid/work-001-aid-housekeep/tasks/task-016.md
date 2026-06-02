# task-016: Cross-stage integration TEST — full `KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE` + `--cleanup-only` entry

**Type:** TEST

**Source:** feature-004-aid-cleanup → delivery-003

**Depends on:** task-001, task-002, task-010, task-013, task-014, task-015

**Scope:**
- **Extend** the delivery-001 integration suite `tests/canonical/test-housekeep-flow.sh`
  (task-010, auto-discovered by the `tests/canonical/test-*.sh` glob, sourcing
  `tests/lib/assert.sh`, runs under `timeout 300`) with the delivery-003 cross-stage wiring —
  the **deterministic state transitions** over a throwaway fixtured repo + `STATE.md`, driving
  the housekeep scripts (`housekeep-state.sh`, `branch-commit.sh`, `cleanup-classify.sh`,
  `parse-args.sh`), NOT the LLM prose bodies.
- **Stub→real-body swap (CLEANUP):** assert the full sequence now terminates
  `KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE` with CLEANUP exercising real logic (the
  delivery-001 stub `**Cleanup Stage:** skipped` is replaced by task-015's `passed`). With the
  upstream gates satisfied (`**KB Stage:**` and `**Summary Stage:**` reading `passed`/`skipped`),
  after a user-resolved cleanup the machine writes `**Cleanup Stage:** passed` and reaches
  `**State:** DONE`. This is the delivery-003 analogue of task-010's delivery-002 forward-compat
  note (the SUMMARY-DELTA swap); the C1 hard-gate ledger (CLEANUP gated on `**Summary Stage:**`)
  must still hold against the deterministic `housekeep-state.sh` gate-ledger transitions.
- **`--cleanup-only` entry (AC10, feature-001 row 2):** assert `parse-args.sh --cleanup-only`
  (task-014) surfaces `**Mode:** cleanup-only` and routes PREFLIGHT → CLEANUP directly —
  KB-DELTA and SUMMARY-DELTA are bypassed, their gate fields neither read nor required, and the
  run still terminates at `**State:** DONE` writing `**Cleanup Stage:** passed`. This exercises a
  brand-new entry mode that did not exist in delivery-001/002.
- **Cancel-all / no-op gate (NFR1/NFR2):** assert a cleanup where the user confirms zero items
  (or the scan finds zero candidates) writes `**Cleanup Stage:** passed` with **no commit**, is
  NOT `stalled`, and a re-run reports "nothing to resume" (resume table row 6 — idempotent no-op).
- **AC8 commit boundary (deterministic half):** assert that a cleanup deleting ≥1 confirmed
  tracked + untracked path produces **exactly one** commit on the `aid/housekeep-*` branch via
  `branch-commit.sh`, with **no `git push` / no remote interaction and no commit to `master`**.
- **Coverage boundary (no double-ownership):** this suite owns only the **cross-stage state
  transitions + entry-mode wiring + commit/no-commit gate**. It does NOT re-own the
  tier-assignment / (i)/(ii) safety-matrix / tracked-untracked unit assertions — those live with
  `cleanup-classify.sh` in task-013 (`test-housekeep-classify.sh`,
  `test-housekeep-workfolder-safety.sh`, `test-housekeep-deletion-split.sh`).

**Acceptance Criteria:**
- [ ] Deterministic, with clean setup/teardown (throwaway repo + STATE fixture), CI-wired via the
  existing `tests/canonical/test-*.sh` glob (no edit to `run-all.sh`).
- [ ] Asserts the full sequence `KB-DELTA → SUMMARY-DELTA → CLEANUP (passed) → **State:** DONE`
  with CLEANUP exercising real logic (stub→real swap), and the C1 hard-gate ledger (CLEANUP does
  not advance until `**Summary Stage:**` reads `passed`/`skipped`) unchanged.
- [ ] Asserts `--cleanup-only` surfaces `**Mode:** cleanup-only`, routes PREFLIGHT → CLEANUP
  directly (KB/Summary fields untouched, no C1 violation), and terminates at `**State:** DONE`
  with `**Cleanup Stage:** passed`.
- [ ] Asserts cancel-all / zero-candidate cleanup → `**Cleanup Stage:** passed` with **no commit**
  (not `stalled`), and a re-run reports "nothing to resume" (resume row 6, NFR2).
- [ ] Asserts a ≥1-item cleanup makes **exactly one** commit on `aid/housekeep-*` (tracked via
  `git rm`, untracked via `rm`), with **no `git push` / no remote write and no `master` commit**
  (AC8).
- [ ] Does NOT duplicate task-013's classification/matrix/split unit assertions (those remain the
  sole property of `cleanup-classify.sh`'s suites).
- [ ] All §6 quality gates pass; covers the source ACs (AC7 UI-transition surface, AC8 commit
  boundary, NFR1/NFR2 cancel-all, AC10 `--cleanup-only`, C1 gate ledger).
