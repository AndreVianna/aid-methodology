# task-005: render.py copy core + slims + FR5 reduction + verify re-point

**Type:** IMPLEMENT

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-002, task-003, task-004

**Scope:**
- Build **`render.py`** — the copy generator: tiny config load + `copy_tree(translate)` for `canonical/agents/ → {root}/agents/` and `canonical/skills/ → {root}/skills/` + a **verbatim** `canonical/aid/ → {root}/aid/` copy (translate=none) + the `EmissionManifest` add/diff/prune lifecycle **lifted verbatim** from today's `run_generator.py` (feature-002 Target Architecture + Feature Flow).
- Collapse `render_agents.py`'s **4 format branches → 1 markdown** branch (keep `_remap_tools` / `_remap_tools_list` — the surviving `tool_names` translation); delete the cursor-extras / antigravity / copilot emitter code (`_build_frontmatter_md_copilot`, `_build_frontmatter_md_antigravity`, and from `render_skills.py`: `_render_cursor_extras`, `_build_trigger_frontmatter`, `_split_rule_body`).
- **FR5 Option (c) MINIMAL:** reduce `rewrite_install_paths` to the **one-line `{root}`-prefix substitution** — remove the **multi-dir branching only**; do **NOT** delete the rewriter, do **NOT** introduce a `{AID_ROOT}` placeholder, and do **NOT** rewrite any canonical content (feature-002 FR5 section). Keep `substitute_filenames` (the `{project_context_file}` / `{reviewer_output_file}` / `{open_questions_file}` placeholders).
- Shrink `aid_profile.py` to `{root_dir, root_file, agent_format, tool_names, model_tiers, capabilities}` — drop `*_dir` / `rules_dir` / `[extras]` / split-root (`LayoutConfig.common_parent()` / `install_root()` / `agents_root` split) logic; prune the validator's known agent formats to `{markdown, toml}`.
- Slim `run_generator.py` (drop the 5-renderer import block; keep the load / diff / prune / manifest / verify spine).
- Re-point `verify_deterministic.py` (rewire `_render_all` to the single copy pass; `_profile_output_dirs` loses the Codex split branch) and `verify_advisory.py` (re-point to the new layout; drop any rules/extras-specific advisory check — A5).
- **Codex `agent_format` follows task-002:** retain the dormant TOML branch (minimized `_render_codex_toml` + the `toml` validator value) **iff** E-CODEX-1 is **not** `high`; otherwise delete `_render_codex_toml` and remove `toml` from the validator. All other format branches (`copilot-agent`, `antigravity-rule`) are deleted regardless.
- **Boundary:** this task produces the generator code only. It does NOT run the generator / commit reshaped `profiles/*` output (task-006), nor delete the dead emitter test files / de-wire CI (task-007), nor author the dogfood byte-identity guard (task-008).

**Acceptance Criteria:**
- [ ] The 4-script set is produced: `render.py` (copy core) + slimmed `run_generator.py` + re-pointed `verify_deterministic.py` + `verify_advisory.py` (surviving `test_manifest_safety.py` logic unchanged).
- [ ] The emission-manifest schema is **byte-for-byte unchanged** (`{_manifest_version:1}` sentinel + `{profile, src, dst, sha256}` records sorted by `dst`, LF-only, binary write) — C5 / NFR2 preserved.
- [ ] The FR5 reducer keeps the single `{root}`-prefix regex and removes the multi-dir branching only (no `{AID_ROOT}` placeholder; no canonical content rewritten).
- [ ] The Codex `agent_format` branch matches task-002's E-CODEX-1 verdict (dormant TOML retained iff not `high`; else deleted with `_render_codex_toml` + the `toml` validator value).
- [ ] IMPLEMENT defaults: unit tests for all new public methods in `render.py`; all existing tests still pass; build / generator self-test passes.
- [ ] Shipped generator scripts are ASCII-only (C3).
- [ ] All §6 quality gates pass.
