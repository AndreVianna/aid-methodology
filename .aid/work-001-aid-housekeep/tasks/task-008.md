# task-008: Integration TEST — cross-stage state machine + distribution/render + run-all discovery

**Type:** TEST

**Source:** feature-001-skill-and-state-machine + feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006, task-007

**Scope:**

### (a) Cross-stage integration — KB-DELTA → stub-no-ops → DONE
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
  gate-field write by `test-housekeep-state.sh`). When task-009 replaces the stub, this suite's
  state-transition coverage must still hold: a fully-`passed`/`skipped` machine still terminates at
  `**State:** DONE`, and the C1 hard-gate ledger (SUMMARY-DELTA gated on `**KB Stage:**`,
  CLEANUP gated on `**Summary Stage:**`) is unchanged — assert these against the deterministic
  `housekeep-state.sh` gate-ledger transitions, not the `/aid-summarize` delegation prose.

### (b) Distribution / render to 5 profiles + run-all discovery (AC11, NFR4)
- Verify the distribution contract (AC11; feature-001 SPEC § Distribution) with **no renderer
  edit**: running `.claude/skills/aid-generate/scripts/render_skills.py` discovers the new
  `canonical/skills/aid-housekeep/` folder via its `skill_dirs = sorted(...)` glob and emits
  `SKILL.md` + `references/*.md` + `scripts/*.sh` into all 5 install profiles (claude-code,
  codex, cursor, copilot-cli, antigravity under `profiles/*.toml`).
- Run the renderer determinism self-test (`render_skills.py --self-test`) and confirm it
  exercises the new folder and passes (byte-identical render across profiles).
- Confirm the D1-edited `aid-discover/references/state-approval.md` (task-006) re-renders cleanly
  to all 5 profiles (CI render-drift gate; cross-cutting Risk #1).
- Confirm `/aid-housekeep` is **absent from the mandatory pipeline flow** — it is NOT inserted
  into the phase-to-skill mapping in `.aid/knowledge/architecture.md` and no phase-gate
  references it (optional/on-demand like `/aid-summarize`).
- Confirm the delivery-001 housekeep suites are picked up by the `tests/canonical/test-*.sh`
  glob and run green under `tests/run-all.sh` (no edit to `run-all.sh`; NFR4 "wired into
  run-all.sh"). After the `parse-args.sh` drop (args handled in `SKILL.md` prose, no dedicated
  arg-parse suite), the suite list is the **5** suites: `test-housekeep-state.sh`,
  `test-housekeep-branch-commit.sh`, `test-housekeep-detect-delta.sh`,
  `test-housekeep-scope-delta.sh`, and this integration suite (5 suites, NOT 6 — the
  `test-housekeep-parse-args.sh` suite is removed).

**Acceptance Criteria:**
- [ ] Deterministic, with clean setup/teardown (throwaway repo + STATE fixture), CI-wired via
  the existing `test-*.sh` glob (no edit to `run-all.sh`).
- [ ] Asserts a no-delta KB-DELTA → `skipped` → SUMMARY-DELTA stub `skipped` → CLEANUP stub
  `skipped` → `**State:** DONE` (clean termination of the delivery-001 KB-refresh run).
- [ ] Asserts a stalled KB-DELTA halts and a re-run resumes at KB-DELTA (not job 1) — AC9.
- [ ] Asserts the hard-gate ledger ordering (C1): no downstream stub advances before its
  upstream `**X Stage:**` reads `passed`/`skipped`.
- [ ] Asserts a fully-resolved run reports "nothing to resume" (re-entry row 6 — NFR2).
- [ ] `render_skills.py` (and `--self-test`) emit `aid-housekeep` SKILL.md + references + scripts
  to all 5 profiles with no renderer source edit, byte-identical across profiles.
- [ ] The D1-edited `aid-discover` approval body (task-006) renders to all 5 profiles with no
  render drift.
- [ ] `/aid-housekeep` does not appear in the mandatory phase-to-skill pipeline mapping
  (architecture.md) and no phase-gate references it (AC11).
- [ ] `tests/run-all.sh` discovers and passes the 5 delivery-001 housekeep canonical suites
  (`test-housekeep-state`, `test-housekeep-branch-commit`, `test-housekeep-detect-delta`,
  `test-housekeep-scope-delta`, + this integration suite — NOT a parse-args suite) via the
  existing glob (NFR4/NFR5) with no `run-all.sh` edit.
- [ ] All §6 quality gates pass; covers the source ACs (AC9, C1, NFR2, stub-no-op contract,
  AC11, NFR4).
