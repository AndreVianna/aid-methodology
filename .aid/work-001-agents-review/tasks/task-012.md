# task-012: Regenerate all five install trees (FR7)

**Type:** CONFIGURE

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-011

**Scope:**
- Run `/aid-generate` for all five profiles to render the rewired canonical SOURCE into the five `profiles/<tool>/` trees — the only surfaces the generator emits to (feature-002 SPEC → Rollout Process Flow step 3; Regeneration & Build Validation).
- Per profile, run `render_agents.py`, `render_skills.py`, `render_templates.py`, `render_recipes.py`, `render_canonical_scripts.py` with `--canonical-root .` `--profile profiles/<tool>.toml` `--output-root profiles/<tool>/<install_root>`; confirm each of the four format branches (`markdown`/`toml`/`copilot-agent`/`antigravity-rule`) renders a valid file for the new agent shape (no new per-tool special-casing).
- The repo-root `.claude/` dogfood tree is NOT a generator target and is NOT regenerated here (B2). Do NOT hand-edit any generated output — this task only runs the renderer (output is a build artifact, not a hand edit).
- This is the regeneration run only; the determinism/build gates and the consistency sweep are task-014.

**Acceptance Criteria:**
- [ ] `/aid-generate` completes without error for all five profiles (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`); each emits only into its own `profiles/<tool>/` output root.
- [ ] All four format branches produce valid files for every new agent; no per-tool special-casing was added.
- [ ] The repo-root `.claude/` dogfood tree is untouched by the run.
- [ ] CONFIGURE baseline: the generated trees are produced solely by the renderer (no hand edits), reproducibly from the current SOURCE.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
