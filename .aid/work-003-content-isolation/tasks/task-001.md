# task-001: Nest AID-own dirs at the generator chokepoint + dst builders + toml keys

**Type:** IMPLEMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** — (none)

**Scope:**
- Split the canonical-path rewrite chokepoint in `.claude/skills/generate-profile/scripts/render_lib.py` (`_CANONICAL_PATH_DIRS` + `rewrite_install_paths`) so AID-own dirs (`scripts`, `templates`, `recipes`) rewrite `canonical/<x>/` → `<install_root>/aid/<x>/`, while tool-native dirs (`skills`, `agents`, `rules`) rewrite `canonical/<x>/` → `<install_root>/<x>/` unchanged.
- Update the three dst builders to emit AID-own subtrees under the nested `aid/` parent: `render_canonical_scripts._scripts_output_root`, `render_templates._templates_output_root`, `render_recipes._recipes_output_root` (single-root: `output_root/aid/<dir>`; codex split: `assets_root/aid/<dir>`, never `agents_root`).
- Keep the toml `[layout]` `scripts_dir`/`templates_dir`/`recipes_dir` keys lockstep with the chosen encoding across all five `profiles/*.toml` (SD-1: pick one uniform convention for where the `aid/` segment lives — recommended: bare leaf in `*_dir`, `aid/` parent in builder + chokepoint).
- Do NOT regenerate `profiles/` here (that is task-003); this task changes generator code + toml only.

**Acceptance Criteria:**
- [ ] In `render_lib.py`, AID-own dir refs rewrite to `<install_root>/aid/<x>/` and tool-native dir refs to `<install_root>/<x>/`; the comment-skip and word-boundary behavior of `rewrite_install_paths` is preserved and rewriting already-nested text is a no-op (idempotent).
- [ ] The three `_*_output_root` builders return a path under `<root>/aid/<dir>` for single-root profiles and under `assets_root/aid/<dir>` (not `agents_root`) for the codex split.
- [ ] The `*_dir` toml encoding is identical in convention across all five profiles and agrees with the chokepoint + builders (R3 lockstep); no per-profile drift.
- [ ] `python render_lib.py` self-test and each renderer's `--self-test` pass (determinism preserved).
- [ ] All §6 quality gates pass.
