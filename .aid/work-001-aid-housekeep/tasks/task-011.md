# task-011: Distribution TEST — render to 5 profiles + run-all.sh suite discovery

**Type:** TEST

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010

**Scope:**
- Verify the distribution contract (AC11; feature-001 SPEC § Distribution) with **no renderer
  edit**: running `.claude/skills/aid-generate/scripts/render_skills.py` discovers the new
  `canonical/skills/aid-housekeep/` folder via its `skill_dirs = sorted(...)` glob and emits
  `SKILL.md` + `references/*.md` + `scripts/*.sh` into all 5 install profiles (claude-code,
  codex, cursor, copilot-cli, antigravity under `profiles/*.toml`).
- Run the renderer determinism self-test (`render_skills.py --self-test`) and confirm it
  exercises the new folder and passes (byte-identical render across profiles).
- Confirm the D1-edited `aid-discover/references/state-approval.md` re-renders cleanly to all 5
  profiles (CI render-drift gate; cross-cutting Risk #1).
- Confirm `/aid-housekeep` is **absent from the mandatory pipeline flow** — it is NOT inserted
  into the phase-to-skill mapping in `.aid/knowledge/architecture.md` and no phase-gate
  references it (optional/on-demand like `/aid-summarize`).
- Confirm all six new housekeep suites (`test-housekeep-state.sh`,
  `test-housekeep-branch-commit.sh`, `test-housekeep-parse-args.sh`,
  `test-housekeep-detect-delta.sh`, `test-housekeep-scope-delta.sh`, the task-010 integration
  suite) are picked up by the `tests/canonical/test-*.sh` glob and run green under
  `tests/run-all.sh` (no edit to `run-all.sh`; NFR4 "wired into run-all.sh").

**Acceptance Criteria:**
- [ ] `render_skills.py` (and `--self-test`) emit `aid-housekeep` SKILL.md + references + scripts
  to all 5 profiles with no renderer source edit, byte-identical across profiles.
- [ ] The D1-edited `aid-discover` approval body renders to all 5 profiles with no render drift.
- [ ] `/aid-housekeep` does not appear in the mandatory phase-to-skill pipeline mapping
  (architecture.md) and no phase-gate references it (AC11).
- [ ] `tests/run-all.sh` discovers and passes all six new housekeep canonical suites via the
  existing glob (NFR4/NFR5) with no `run-all.sh` edit.
- [ ] Deterministic with clean setup/teardown; all §6 quality gates pass.
