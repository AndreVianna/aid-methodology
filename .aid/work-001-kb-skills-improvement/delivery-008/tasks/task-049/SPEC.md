# task-049: Render to 5 host trees + orphan-prune aid-ask + release-tarball verification

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-046, task-048

**Scope:**
- f009 Part 1 + Part 2 (S1/S2/S3, AC12) -- the RED->green core. Consumes f008's FINAL canonical
  state (task-046 renamed+gap-capture `aid-query-kb`; task-048 the complete `aid-update-kb` skill +
  references). f009 edits NO `canonical/skills/` content -- it only runs the generator over f008's
  canonical.
- **Render + prune (one command):**
  `python .claude/skills/generate-profile/scripts/run_generator.py` -- iterates the 5 profiles
  (claude-code/.claude, codex/.codex, cursor/.cursor, copilot-cli/.github, antigravity/.agent),
  renders `canonical/` (skills are dir-globbed at `render.py:538`, so `aid-query-kb/SKILL.md` and
  the new multi-file `aid-update-kb/` SKILL.md + `references/state-*.md` are emitted automatically
  and `aid-ask/SKILL.md` stops being emitted), then the deletion pass (`run_generator.py:43-60`)
  diffs against the previous `emission-manifest.jsonl`, unlinks the removed `aid-ask/SKILL.md`
  record in each tree and rmdir's the emptied `aid-ask/` dir, and rewrites the 5
  `emission-manifest.jsonl`. Commit the regenerated `profiles/` + 5 manifests.
- **Run the FULL `run_generator.py`** (not a per-script renderer) -- the `render-drift-full-generator`
  hazard.
- **Orphan-prune verification (S2, SPIKE-A verify-on-run):** confirm `aid-ask`'s single-file
  rendered dir prunes empty in all 5 trees and `aid-update-kb`'s multi-file new dir emits cleanly.
- **Release-tarball surface (S3, Part 2):** the 5 per-profile tarballs auto-enumerate their file
  list from the rendered `profiles/<host>/` tree (`release.sh:245-258` find), and `release.sh`
  Step-2 itself re-runs `run_generator.py` + fails on `git diff -- profiles/` -- so once `profiles/`
  is regenerated the tarballs ship the new set automatically. **No hand-listed skill set exists in
  the packaging path.** This task VERIFIES the tarball set (no `aid-ask`, both new skills present),
  it does not cut a release tag.
- **Explicit non-surface (record, do not touch):** npm/pypi `vendor.js`/`vendor.py` vendor only the
  CLI installer (bin/lib/dashboard), NOT the skill set (S4) -- not a propagation surface here.
- This task makes `render-drift` CI green; the KB-count / docs-site / dogfood surfaces are
  task-050/046/047. **No release tag is cut between f008 and f009** (PLAN R2) -- the two ship as one
  branch/PR; this task is the green-maker, not a release step.

**Acceptance Criteria:**
- [ ] After `run_generator.py` + commit, `git diff --exit-code -- profiles/` is clean (render-drift
  CI's own generator run is a no-op -> green).
- [ ] `find profiles -path '*/aid-ask/*'` returns nothing (orphan-pruned in all 5 trees);
  `aid-query-kb/` and `aid-update-kb/` (incl. its `references/state-*.md`) are present in all 5
  rendered trees.
- [ ] The 5 `emission-manifest.jsonl` files are rewritten to the new set (no `aid-ask` record; new
  `aid-query-kb` + `aid-update-kb` records present).
- [ ] A built `aid-<tool>-v*.tar.gz` (verification build) contains `aid-query-kb`/`aid-update-kb`
  and no `aid-ask`; `release.sh` Step-2 render-drift guard passes. (Verification only -- no release
  tag cut.)
- [ ] npm/pypi vendor scripts are recorded as a non-surface and left untouched.
- [ ] The FULL `run_generator.py` was run (not a per-script renderer).
- [ ] No `canonical/skills/` content was edited in this task (f009 consumes f008 final).
- [ ] All section-6 quality gates pass.
