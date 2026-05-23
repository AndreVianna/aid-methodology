# task-021: Write the template renderer

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-005, task-018, task-022

**Scope:**
- Author `.claude/skills/aid-generate/scripts/render_templates.py`.
- Input: `canonical/templates/` (the whole subtree from task-005) + one `Profile` + the `EmissionManifest`.
- Output: copy the entire `canonical/templates/` subtree into the profile's templates location:
  - Claude Code: `claude-code/.claude/templates/...`
  - Codex: `codex/.agents/templates/...` (per the split layout)
  - Cursor: `cursor/.cursor/templates/...`
- Transformations per profile:
  - **`substitute_filenames()`** on every `.md` template body using the profile's `filename_map` (every literal `{project_context_file}` etc. in a template gets the per-tool substitution).
  - **`scripts/*.sh` and asset-bundle binaries (CSS, JS, HTML)** carried over byte-identical (no substitution). The `knowledge-summary/` asset bundle includes `lightbox.js`, `mermaid-init.js`, `component-css.css`, `html-skeleton.html`, `validate-*.{sh,mjs}`, `grade.sh`, etc. — none of these mention per-tool filenames, so no body rewriting is needed.
  - **Cursor `rules/`** — the existing per-tool template tree does not include `.mdc` rules under `templates/` (those live under `cursor/.cursor/rules/` directly). If `canonical/templates/` has any Cursor-only rule template, the renderer routes it to `cursor/.cursor/rules/`; otherwise the rules are sourced from `canonical/rules/` (a new top-level — flag this as a follow-up if rules need separate canonical handling).
- Determinism — sorted directory walk, no timestamps, no host-machine paths in output.
- This task **eliminates the largest single duplication category** per `tech-debt.md` H4 (the ~17,600 lines of 4-way duplicated knowledge-summary + scripts). After this renderer lands and task-026 verifies the output equals the current install-tree state, the duplicated copies become generated artifacts.

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/render_templates.py` exists; compiles; runs end-to-end.
- [ ] For each profile, the renderer emits a `templates/` subtree under the profile's templates location with the same file count and total LOC as the current install tree's `templates/` (±0 expected; any delta is investigated and resolved in the execution log).
- [ ] Binary / asset files (CSS, JS, HTML, .mjs scripts) are byte-identical to canonical (no substitution attempted).
- [ ] Spot-check: the rendered `templates/knowledge-base/INDEX.md` for Codex has `AGENTS.md` (not `CLAUDE.md`) wherever the template body refers to the per-tool project-context file; the same rendered file for Claude Code has `CLAUDE.md`.
- [ ] Two consecutive renders produce byte-identical output.
- [ ] Every emitted file is in the `EmissionManifest`.
