# task-003: Regenerate profiles + emission manifests; hand-migrate the dogfood `.claude/` tree; verify generated-files.txt auto-nests

**Type:** CONFIGURE

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Do NOT hand-edit `canonical/templates/generated-files.txt`: its kb-build DATA lines are `canonical/scripts/kb/...` (non-comment lines), which the chokepoint `rewrite_install_paths` AUTO-nests post-Pillar-1 — only `#`-leading comment lines are skipped (`render_lib.py:172-178`). There is no `.claude/scripts/kb/...` literal in the source. VERIFY the rendered output instead (AC below).
- Run the FULL `run_generator.py` (`.claude/skills/generate-profile/scripts/run_generator.py`) to regenerate every `profiles/` tree and every `emission-manifest.jsonl` under the nested layout; let the deletion pass remove the old un-nested emitted paths.
- Do not hand-edit generated profile files; only the canonical source + generator-driven regen.
- HAND-MIGRATE the repo-root dogfood `.claude/` tree (F8). The generator iterates only `profiles/*.toml` (`run_generator.py:21-26`) and NEVER writes the repo-root `.claude/`, which is hand-maintained per `coding-standards.md §7a` (the byte-identity invariant spans the 6 generated trees PLUS the hand-maintained dogfood `.claude/` = 7 on-disk copies). After the Pillar-1 nest, the dogfood tree must be migrated BY HAND to match `profiles/claude-code/.claude/` or it diverges (§7a breaks), the AID repo's own skill path-resolution breaks, and render-drift CI (which diffs only `profiles/`) will NOT catch it. Specifically, in the repo-root `.claude/`:
  - Move the AID-own dirs to the nested form: `.claude/{scripts,templates,recipes}` → `.claude/aid/{scripts,templates,recipes}` (matching `profiles/claude-code/.claude/aid/…`). Tool-native dirs (`agents/`, `skills/`) keep their path.
  - Apply the `skills/README.md` → `aid-README.md` rename here too (`.claude/skills/README.md` → `.claude/skills/aid-README.md`), matching the Pillar-2 rename in `profiles/claude-code/`.
  - Rewrite the AID-own body path-refs inside the repo-root `.claude/` skills/agents from the un-nested form to the nested form: `.claude/scripts/…` → `.claude/aid/scripts/…`, `.claude/templates/…` → `.claude/aid/templates/…`, `.claude/recipes/…` → `.claude/aid/recipes/…` (≈70 files carry such refs). Match each rewritten body byte-for-byte against its counterpart in `profiles/claude-code/.claude/` after the regen.
  - Do NOT rewrite `canonical/…` source refs and do NOT touch tool-native (`agents`/`skills`/`rules`) path segments.

**Acceptance Criteria:**
- [ ] In the RENDERED `generated-files.txt` of a profile tree, the kb-build DATA lines show the nested `…/aid/scripts/kb/...` form (e.g. claude-code `.claude/aid/scripts/kb/...`); the canonical source line is unchanged (`canonical/scripts/kb/...`) and was auto-rewritten by the chokepoint — confirm it was NOT hand-edited.
- [ ] After regen, `scripts/`, `templates/`, `recipes/` exist ONLY under each profile's `<assets-root>/aid/` and nowhere at the un-nested location; `.codex/` contains only `agents/` (R6); copilot-cli AID-own is under `.github/aid/` and `.github` root is untouched as user content (R1).
- [ ] Every `emission-manifest.jsonl` dst path reflects the nested layout; no stale un-nested emitted files remain.
- [ ] A second consecutive FULL `run_generator.py` run produces byte-identical output (render-drift clean); generator VERIFY (deterministic) passes.
- [ ] The §7a byte-identity invariant holds AFTER the dogfood nest: the hand-migrated repo-root `.claude/` and the generated `profiles/claude-code/.claude/` agree on the nested layout — `.claude/aid/{scripts,templates,recipes}` exists (with no un-nested `.claude/{scripts,templates,recipes}` left), `.claude/skills/aid-README.md` is present (and `README.md` is gone), and every counterpart body file is byte-identical between the two trees (e.g. `diff -r` of `.claude/` vs `profiles/claude-code/.claude/` shows no differences in the AID-own/tool-native bodies). No repo-root `.claude/` skill/agent body still references an un-nested `.claude/{scripts,templates,recipes}/` install-tree path.
- [ ] The AID repo's own skills resolve after the nest: a repo-root `.claude/` skill that invokes an AID-own script (e.g. a `.claude/aid/scripts/kb/…` ref) finds it at the nested path (the dogfood path-resolution is not broken by the move).
- [ ] All §6 quality gates pass.
