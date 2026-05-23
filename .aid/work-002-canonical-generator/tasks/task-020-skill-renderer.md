# task-020: Write the skill renderer

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-006, task-007, task-008, task-009, task-010, task-011, task-011a, task-011b, task-011c, task-012, task-013, task-014, task-018, task-022

**Scope:**
- Author `.claude/skills/aid-generate/scripts/render_skills.py`.
- Input: `canonical/skills/aid-{name}/` (with `SKILL.md` + `references/*.md` + `scripts/*.sh`) + one `Profile` + the `EmissionManifest`.
- Output: per the profile's `[skill]` table — `SKILL.md` + `references/*.md` (Decision F: all three profiles use `references` decomposition, so no inlining) + `scripts/*.sh` carried over verbatim. Output location: `{output_root}/{skills_dir}/aid-{name}/` for Claude Code and Cursor; `{assets_root}/skills/aid-{name}/` for Codex (the split layout per task-016).
- Transformations per profile:
  - **Frontmatter rewriting** — emit `name`, `description`, `allowed-tools` (apply `tool_names` map — Cursor: `Bash → Terminal`), optional `argument-hint`. Claude Code additionally emits `context: fork` and `agent: <name>` if the canonical declares them (verify against `coding-standards.md §1.1`).
  - **Body substitution** — `substitute_filenames()` with the profile's `filename_map`.
  - **Body left intact** — Decision F means the body is **always** the thin-router form; no inlining of `references/*.md` for any profile.
  - **`references/*.md` carried over verbatim** with body substitution applied (their bodies also mention per-tool filenames).
  - **`scripts/*.sh` carried over verbatim** with no transformation (shell scripts use abstract names already).
- Determinism — sorted iteration; manifest-recorded.

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/render_skills.py` exists; compiles; runs end-to-end.
- [ ] For each profile, the renderer emits all 10 skill folders under the profile's skill-output location, each with `SKILL.md` + its `references/` + its `scripts/`.
- [ ] **No skill SKILL.md exceeds the Claude Code source's line count** in any profile's output (the inlining bloat that produced 1,078- and 1,090-line Codex / Cursor SKILL.md files per `tech-debt.md` H1 is eliminated — every profile's `aid-discover/SKILL.md` is now ~453 lines).
- [ ] Spot-check: the rendered `aid-discover/SKILL.md` (Claude Code) is byte-identical to the current `claude-code/.claude/skills/aid-discover/SKILL.md` modulo applied substitutions; the rendered `aid-discover/SKILL.md` (Cursor) has `Terminal` in `allowed-tools`; the rendered `aid-discover/SKILL.md` (Codex) is the **thin** form (NOT the current 1,078-line inlined form).
- [ ] Two consecutive renders produce byte-identical output.
- [ ] Cursor `[extras]` `.mdc` rules are emitted (or, if a separate `render_extras.py` is preferred, the skill renderer cleanly delegates to it — author's choice; record the decision).
