# task-029: Final round-trip verification via the generator

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-027, task-028

**Scope:**
- End-to-end exercise of the generator post-cutover (the "AC1 + AC2 + AC5 live" check).
- Steps:
  1. Make a deliberate, trivial change to one canonical file — e.g. add a single comment line to `canonical/skills/aid-deploy/SKILL.md` like `<!-- round-trip test 2026-05-22 -->`.
  2. Run `/aid-generate` (live mode).
  3. Confirm the change lands in all three install trees:
     - `claude-code/.claude/skills/aid-deploy/SKILL.md` has the new line.
     - `codex/.agents/skills/aid-deploy/SKILL.md` has the new line.
     - `cursor/.cursor/skills/aid-deploy/SKILL.md` has the new line.
  4. Re-run `/aid-generate --dry-run` immediately; confirm zero diff (the generator is now idempotent at the new state — AC2 byte-identical re-run).
  5. Revert the canonical change (`git checkout canonical/skills/aid-deploy/SKILL.md`).
  6. Run `/aid-generate` again; confirm the install trees revert to their post-cutover state (a clean delete of the test comment).
- The three install-tree files getting the change in step 3 is **AC1 live evidence** ("a single `canonical/` source renders every install tree"). The idempotent re-run in step 4 is **AC2 live evidence** ("byte-identical output"). The fact that no manual cross-tree edit was needed is **AC5 live evidence** ("edit `canonical/`, run the generator" is what actually happened).
- **AC3 live smoke test** (new — was previously a structural-claim trace only; promoted to executable per Reviewer Finding E):
  7. Author a stub `profiles/test-tool.toml` whose `[layout]`, `[agent]`, `[skill]`, `[model_tiers]`, `[tool_names]`, `[filename_map]`, `[extras]`, `[capabilities]` tables all alias the Claude Code profile values (the simplest valid "new tool" — same layout, same conventions, different `output_root`, e.g. `test-tool/.test-tool`). Critically: **`canonical/` is not modified** and the three existing `profiles/*.toml` are not modified — only the new profile is added.
  8. Run `/aid-generate` and observe a fourth output root (`test-tool/.test-tool/`) materialize, populated with the same agents + skills + templates the other three profiles emit.
  9. Delete `profiles/test-tool.toml` and re-run `/aid-generate`. Confirm pure-mirror deletion (per task-022's safety boundary) removes the `test-tool/` tree entirely — the previous run's manifest at `test-tool/emission-manifest.jsonl` enumerates every emitted path, and the absence of `profiles/test-tool.toml` on the second run means none of those paths are re-emitted, triggering the `removed_dst` deletion cascade.
  10. Confirm zero residue: `git status` shows no untracked / modified files under `test-tool/` after the deletion run.
- The materialization in step 8 is **AC3 live evidence** ("onboarding a new host tool requires only a new profile — `canonical/` and existing profiles untouched"). The clean teardown in step 9 is also a **task-022 safety-boundary live exercise** (the pure-mirror deletion works as designed when a profile is removed).
- **AC4 is structural** (the profile is the per-tool capability registry) — verified passively by inspecting the three `profiles/*.toml` files' `[capabilities]` tables produced in tasks 015–017.
- Output: an entry in `.aid/work-002-canonical-generator/PLAN.md` Change Log noting AC1, AC2, AC3, AC5 verified live; AC4 verified by inspection.
- Final cleanup: revert the test comment (from step 1), confirm `profiles/test-tool.toml` is deleted (from step 9), run the generator one last time, commit if anything moves.

**Acceptance Criteria:**
- [ ] The deliberate canonical change lands in all three install trees (AC1 live).
- [ ] `/aid-generate --dry-run` immediately after step 3 reports zero diff (AC2 live).
- [ ] Reverting the canonical change cleanly reverts all three install trees (round-trip clean).
- [ ] **AC3 live**: adding `profiles/test-tool.toml` (without touching `canonical/` or the existing profiles) materializes a fourth output root; deleting the test profile and re-running the generator removes the fourth tree cleanly via the pure-mirror deletion safety boundary.
- [ ] The PLAN.md Change Log entry documents the live verification of AC1, AC2, AC3, AC5 and the inspection-based verification of AC4.
- [ ] No residual test artifact is left in the working tree post-task (test comment reverted; `profiles/test-tool.toml` deleted; no orphan `test-tool/` directory).
