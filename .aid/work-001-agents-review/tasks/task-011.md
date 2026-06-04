# task-011: Fix the aid-generate skill's own stale references (FR7)

**Type:** IMPLEMENT

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-010

**Scope:**
- Hand-edit the maintainer-only `aid-generate` SOURCE-exception (`.claude/skills/aid-generate/`) to correct its stale references so it matches five-profile reality before regeneration (feature-002 SPEC → Regeneration & Build Validation):
  - `SKILL.md` line 4 + 15: "three install trees (claude-code, codex, cursor)" → five (claude-code, codex, cursor, copilot-cli, antigravity).
  - `SKILL.md` line 8: `--tool` enum → five-value (or derive from `ls profiles/*.toml`).
  - `SKILL.md` line 61: State-Detection `--tool` default `[claude-code, codex, cursor]` → all five.
  - RENDER/REPORT body (output-root anchors ~130–134; three-profile summary ~222–239, incl. `git diff --stat -- claude-code/ codex/ cursor/`) → the actual `profiles/<tool>/...` output roots + five-profile summary.
  - VERIFY report path pointing at `.aid/work-002-canonical-generator/` → a valid path for this run.
  - `render_agents.py` header comment (lines 6–7) → the four current format branches (`markdown`/`toml`/`copilot-agent`/`antigravity-rule`), and apply any renderer/`profiles/*.toml` change the *Generation decision* requires (B3).
- This is the FR7 generator-code fix only — agent-name rewrites in aid-generate were done in task-010 (FR6), and the regeneration *run* is task-012. Do NOT run the generator or edit any `profiles/<tool>/` generated tree here.

**Acceptance Criteria:**
- [ ] No "three install trees"/three-profile/`--tool` enum or list in `aid-generate` lags the five profiles; the VERIFY report path is valid for this run.
- [ ] `render_agents.py` header + any branch touched by the *Generation decision* (B3) reflects the four current format branches; if the decision keeps the per-agent shape, the renderer is otherwise unchanged.
- [ ] Edits land only in `.claude/skills/aid-generate/` (the SOURCE-exception); no generated `profiles/<tool>/` tree is touched.
- [ ] IMPLEMENT baseline: the change is internally consistent with `profiles/*.toml` and ready for a clean generator run.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
