# task-026: Bootstrap verification — run the generator, diff against current trees

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-025

**Scope:**
- With `canonical/` + `profiles/` + the generator skill now in place (via the upstream chain), run `/aid-generate` in **dry-run mode** (`--dry-run`) from the repo root.
- The generator renders into a scratch directory; the orchestrator computes `diff -r <scratch> <current install trees>` for each profile and reports the diff.
- The **expected diff signature** is:
  - The bloated Codex / Cursor `SKILL.md` files lose their inlined content and shrink to ~Claude Code line counts. The diff shows large removals from those files.
  - The corresponding `references/*.md` files appear in Codex / Cursor trees (per Decision F — all three profiles externalize).
  - Cursor agent `tools:` declarations now consistently say `Terminal` (per M6 fix encoded in the Cursor profile).
  - Codex agent / skill content uses the canonical filenames (`DISCOVERY-STATE.md`, `additional-info.md`) instead of the divergent `DISCOVERY-GRADE.md` / `open-questions.md` (per R12).
  - Templates lose their per-tool divergence; per-tool `filename_map` substitutions are visible.
  - The 4-way duplicated knowledge-summary assets are now byte-identical across the three install trees (they were already very close, but any sub-character drift is now eliminated).
- **The maintainer reviews the diff manually.** Acceptance is gated on the maintainer confirming the diff is exclusively drift-elimination + the intended fixes (M6, R12) — no functional content is lost.
- Any unexpected diff (e.g. a canonical/skills/aid-X/SKILL.md body section that the maintainer realizes was actually a Codex-specific improvement that should have been carried into canonical) goes back to the relevant bootstrap task (006–014) as a corrective revision before this verification re-runs.
- Output: a `.aid/work-002-canonical-generator/bootstrap-diff.md` artifact summarizing per-profile diff stats + the maintainer's confirmation note.

**Acceptance Criteria:**
- [ ] `/aid-generate --dry-run` runs to completion; VERIFY-4a passes; VERIFY-4b reports `skipped_count = 8`.
- [ ] Per-profile diff is documented in `bootstrap-diff.md` (file-count delta, lines-added, lines-removed, plus a sample of the most significant changes).
- [ ] The diff shape matches the expected signature above; any deviation is documented and either accepted (with rationale) or routed back to the upstream bootstrap task.
- [ ] The maintainer has explicitly confirmed in `bootstrap-diff.md` that the diff is drift-elimination + intended fixes only — no functional content lost.
- [ ] No commit is made in this task — task-027 commits the trees after this verification passes.
