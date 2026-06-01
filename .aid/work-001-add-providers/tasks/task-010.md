# task-010: Render Copilot tree + self-tests, render-drift, existing-3 byte-identical gate

**Type:** TEST

**Source:** feature-002-copilot-cli → delivery-002

**Depends on:** task-004, task-006, task-009

**Scope:**
- Run the full generator and the SPEC §"Test Plan" checks to prove the Copilot CLI tree is complete and render-drift-clean while the 3 existing profiles stay byte-identical. This is the integration/gate task — no production code; it runs the renderers, commits the emitted `profiles/copilot-cli/.github/` tree + `emission-manifest.jsonl`, and asserts every gate. Test cases (SPEC Test Plan #1–#7):
  - **#1 validator self-test:** the 4 profiles (claude-code, codex, cursor, copilot-cli) validate clean; an unknown `agent.format` is still rejected with a clear message.
  - **#2 render_agents self-test (E1):** `python .claude/skills/aid-generate/scripts/render_agents.py --self-test --canonical-root .` green and exercising copilot-cli — two renders byte-identical; sub-agent outputs end in `.agent.md`; frontmatter is exactly `name, description, tools, model` (Copilot key order); **each emitted frontmatter block round-trips through a real YAML parse**; **`tools` is a valid YAML sequence, not a comma-string scalar and not a Python repr**; **a `description` containing `:` is a quoted scalar that parses back unchanged**; `Bash` is remapped to `shell`. The 3 existing profiles' agent output is byte-identical across the run.
  - **#3 render_skills self-test (skills as `[data]` folders):** `python .claude/skills/aid-generate/scripts/render_skills.py --self-test --canonical-root .` green for all 4 profiles. For copilot-cli the 10 skills emit as **10 `SKILL.md` folders** under `skills/` (the same folder shape cursor emits — `[data]`, like cursor), NOT as agents. Targeted asserts: (a) a multi-reference skill emits `SKILL.md` + its `references/*.md` under `skills/<slug>/`; (b) the zero-reference skill `aid-config` emits `SKILL.md` only, with no `references/` directory (the existing glob matches nothing — no special case); (c) for the 3 existing profiles, skill output is byte-identical to before.
  - **#4 no MCP emitter:** assert no `mcp-config.json` is emitted for copilot-cli (Q-B `[omit]`) and no `render_mcp` pass exists (E3 is not built).
  - **#5 render-drift clean (new profile):** `python run_generator.py` emits copilot-cli with no errors; `verify_deterministic` PASS — byte-identical re-render + presence audit with no MISSING/EXTRA for copilot-cli (incl. confirming the committed `profiles/copilot-cli/AGENTS.md` is NOT in the manifest and not flagged EXTRA; recipes emit at `.github/recipes/` as `[data]` and are present/manifested).
  - **#6 existing-3 byte-identical gate:** after running the generator, `git diff --exit-code -- profiles/claude-code/ profiles/codex/ profiles/cursor/` shows ZERO changes (trees + their `emission-manifest.jsonl` unchanged). This is the continuous backward-compat gate.
  - **#7 canonical suites green:** `render_lib --self-test`, `render_templates`, `render_canonical_scripts`, `render_recipes` self-tests, `verify_deterministic --self-test`, and `verify_advisory` continue to pass unchanged. **No new emitting pass is added** (E3 dropped), so the live-emit list (`run_generator.py`) and `verify_deterministic._render_all` are untouched and the two-pass-list wiring concern does not apply.
- Do NOT modify any renderer/profile code to make a test pass — defects route back to task-005/006/009. This task only runs gates, commits the emitted copilot-cli tree, and records results.

**Acceptance Criteria:**
- [ ] All four profiles validate clean; unknown `agent.format` rejected (Test #1).
- [ ] `render_agents --self-test` green incl. copilot-cli: `.agent.md` suffix, `name/description/tools/model` key order, every frontmatter block YAML-parses, `tools` is a YAML sequence, a `:`-bearing description round-trips, `Bash→shell`; existing-3 agent output byte-identical (Test #2).
- [ ] `render_skills --self-test` green for all 4: copilot-cli emits 10 `SKILL.md` folders under `skills/` (NOT agents, like cursor); existing-3 skill output byte-identical; multi-reference skill emits `SKILL.md`+`references/`; `aid-config` emits `SKILL.md` only with no `references/` (Test #3 a/b/c).
- [ ] No `mcp-config.json` is emitted for copilot-cli and no `render_mcp` pass exists (Test #4, Q-B `[omit]`).
- [ ] `python run_generator.py` succeeds and `verify_deterministic` PASS for copilot-cli (no MISSING/EXTRA; `AGENTS.md` un-manifested and not EXTRA; `.github/recipes/` present as `[data]`) (Test #5).
- [ ] `git diff --exit-code -- profiles/claude-code/ profiles/codex/ profiles/cursor/` reports zero changes (Test #6).
- [ ] All canonical suites + `verify_advisory` green; the live-emit list and `_render_all` are untouched (no new pass added) (Test #7).
- [ ] Tests are deterministic; clean setup/teardown (temp dirs, no leftover state); all acceptance criteria from feature-002 SPEC are covered. All §6 quality gates pass.
