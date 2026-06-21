# task-007: Delete dead emitter tests + CI de-wire

**Type:** REFACTOR

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-005, task-006

**Scope:**
- **Delete the 5 superseded renderer scripts** orphaned by task-005's `render.py` copy-collapse — `render_agents.py`, `render_skills.py`, `render_templates.py`, `render_recipes.py`, `render_canonical_scripts.py` (all under `.claude/skills/generate-profile/scripts/`). Task-005's quick-check confirmed NO live importer references them (only the 2 dead emitter tests + cross-references among themselves). **KEEP** `render_lib.py` + `aid_profile.py` (still consumed by `render.py`/`run_generator.py`/`verify_*`).
- Delete the two now-dead format-branch conformance tests: `test_copilot_emitter.py` (deleted `copilot-agent` branch) and `test_antigravity_emitter.py` (deleted `antigravity-rule` branch) (feature-002 Layers — DELETE rows 12/13).
- **De-wire / re-point the 3 stale CI self-test invocations** (verify exact line refs at implementation time — they drift): (a) `render_canonical_scripts.py --self-test` (today `test.yml:94` / `release.yml:163`) -> **re-point to `render.py --self-test`** (its script is being deleted); (b) `test_copilot_emitter.py --self-test` + (c) `test_antigravity_emitter.py --self-test` (today `test.yml:97-98` / `release.yml:166-167`) -> **removed**. **KEEP** `render_lib.py --self-test` wired (render_lib.py is retained; its self-test stays valid).
- Confirm/drop any **rules-specific advisory CI invocation** (assumption A5) — task-005 found `verify_advisory.py` has no rules/extras check (nothing to drop in code); de-wire a rules-specific advisory CI invocation only if one is present.
- **Boundary:** the `render-drift` job (test.yml / release.yml) stays unchanged in shape (it still runs `run_generator.py` + `git diff --exit-code -- profiles/`). This task touches dead generator code + workflow wiring only — it does not author the new dogfood byte-identity guard (task-008).

**Acceptance Criteria:**
- [ ] The 5 superseded renderer scripts (`render_agents/skills/templates/recipes/canonical_scripts.py`) are deleted; `render_lib.py` + `aid_profile.py` retained.
- [ ] `test_copilot_emitter.py` and `test_antigravity_emitter.py` are deleted.
- [ ] No workflow file (`test.yml`, `release.yml`) references any deleted script: `render_canonical_scripts.py --self-test` is re-pointed to `render.py --self-test`; the 2 emitter-test self-test invocations are removed. (Verified against the actual current line refs.)
- [ ] `render_lib.py --self-test` (retained) is still wired and green.
- [ ] Any rules/extras-specific advisory **CI invocation** (A5) is confirmed present-or-absent and de-wired if present (the `verify_advisory.py` code edit is task-005's).
- [ ] CI is green after de-wiring (the canonical / generator-selftest / render-drift jobs pass).
- [ ] REFACTOR defaults: all tests pass before AND after (the surviving suite stays green); no behavior change to surviving generator output.
- [ ] All §6 quality gates pass.
