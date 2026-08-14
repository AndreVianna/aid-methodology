**Type:** CONFIGURE

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-014

**Scope:**
- The render fan-out for every canonical edit this delivery made -- the three state templates
  (task-002), the shell readers (task-006), the writer (task-007), the review-exclusion surfaces
  (task-012) and the skill/prose retargeting (task-014).
- Run the FULL generator, not a per-script renderer:
  `python .claude/skills/generate-profile/scripts/run_generator.py` -- a per-script render leaves
  stale emission manifests and the drift check fails (`test-landscape.md § Test Commands` note).
- Resync this repo's dogfood trees from `profiles/claude-code/` (and the cursor profile for
  `.cursor/`) after the generator runs -- skipping this resync is the classic red-CI mistake the
  byte-identity gate exists to catch.
- Verify, not assume: `python .claude/skills/generate-profile/scripts/run_generator.py && git diff
  --exit-code -- profiles/` for drift, then `tests/canonical/test-dogfood-byte-identity.sh` and
  `tests/canonical/test-multitool-isolation.sh` (T21-T26 -- no foreign-tool root path in an
  operational script, comments included).
- No canonical file is edited here and no render is hand-edited (C-1 -- "editing a render is a
  defect"). If a render comes out wrong, the fix goes into `canonical/` and the generator is re-run.
- `dashboard/scripts/writeback-state.sh` is NOT a render and must NOT be resynced (C-2, FR-4d): its
  hand-applied change from task-007 stays, and its acceptance of `Deploy` as a `Phase` value is the
  only available proof it was not overwritten.
- Idempotent (`task-type-rules.md § CONFIGURE`): re-running the generator and the resync produces no
  further diff.
- OUT of this task: any canonical edit; the KB refresh (task-018); the final suite comparison
  (task-019).

**Acceptance Criteria:**
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code --
      profiles/` is clean -- the full generator was run and no drift remains (SP-14).
- [ ] All five profile renders (`profiles/claude-code`, `profiles/cursor`, `profiles/codex`,
      `profiles/copilot-cli`, `profiles/antigravity`) carry the state-format change: each has the
      three `.yml` state templates, the converted `writeback-state.sh`, the retargeted shell
      readers and the retargeted skill/prose surfaces, and none has a leftover `*-state-template.md`
      (SP-14).
- [ ] `tests/canonical/test-dogfood-byte-identity.sh` passes per its own summary line, proving
      `.claude/` was resynced from `profiles/claude-code/` (SP-14, NFR-7).
- [ ] `tests/canonical/test-multitool-isolation.sh` T21-T26 pass -- no foreign-tool root path
      appears in an operational script, comments included (SP-14, NFR-7).
- [ ] No render was hand-edited: every file under `profiles/`, `.claude/` and `.cursor/` in this
      task's diff is byte-identical to generator output, and re-running the generator produces no
      further diff (C-1, idempotence).