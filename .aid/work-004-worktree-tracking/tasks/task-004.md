# task-004: Propagate the EXECUTE writeback-state.sh to its profile + dogfood copies

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-003

**Scope:**
- Propagate the task-003 changes to every copy of the EXECUTE `writeback-state.sh` so render-drift stays clean. The task-003 edits live in `canonical/scripts/execute/writeback-state.sh`; the propagation targets are ONLY the execute copies (confirmed):
  - the 5 generated profile copies under `profiles/*/.../aid/scripts/execute/writeback-state.sh` (antigravity `.agent`, claude-code `.claude`, codex `.agents`, copilot-cli `.github`, cursor `.cursor`) — NOTE: nested under `aid/` since work-003 (#93);
  - the `.claude/aid/scripts/execute/writeback-state.sh` dogfood working copy.
- **EXCLUDE the summarize `writeback-state.sh`.** `canonical/scripts/summarize/writeback-state.sh` (and its profile/dogfood copies under `*/aid/scripts/summarize/`) is a DIFFERENT, ~5 KB script that only appends `## Summarization History` to `.aid/knowledge/STATE.md`; it has none of the `--field`/`--findings`/`--block`/`--task-id`/`--pipeline` modes and touches no renamed section. It receives NO part of the task-003 retarget or state-naming change. The two are not twins (`diff` => DIFFER, 5160 vs 33675 bytes); making them byte-identical would corrupt the summarize path. Leave summarize untouched.
- Use the FULL generator at `.claude/skills/generate-profile/scripts/run_generator.py` to regenerate emitted copies (NOT per-script renderers), per the render-drift discipline.
- Verify byte-identical logic across canonical execute ↔ all execute profile/dogfood copies; ASCII-only preserved.

**Acceptance Criteria:**
- [ ] The 5 profile execute copies + the `.claude/aid/scripts/execute/` copy carry the task-003 retarget + state naming, byte-consistent with `canonical/scripts/execute/writeback-state.sh`.
- [ ] The summarize `writeback-state.sh` (canonical + all profile/dogfood copies) is UNCHANGED by this task (verify `diff` against pre-task baseline is empty).
- [ ] Regenerated via `run_generator.py`; render-drift CI check is clean.
- [ ] All touched copies are ASCII-only; `bash -n` clean.
- [ ] All §6 quality gates pass.
