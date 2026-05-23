# task-020-STATE

**Status:** Done
**Grade:** A
**Cycle:** 1

## Review History

| Cycle | Grade | Notes |
|-------|-------|-------|
| 1 | A | render_skills.py exists, compiles, runs end-to-end. All 10 skill folders rendered for all 3 profiles. Determinism OK. claude-code aid-discover/SKILL.md BYTE IDENTICAL (453 lines). cursor aid-discover/SKILL.md has Terminal. codex aid-discover/SKILL.md is thin form (453 lines, not 1078). Cursor extras (.mdc rules) rendered from canonical/rules/ into cursor/.cursor/rules/. |

## Citations

- Strategy: preserve frontmatter verbatim (_split_frontmatter_raw + _rewrite_skill_frontmatter) — only modifies the allowed-tools line and drops claude_code_optional fields. Avoids YAML reformatting bugs with folded description blocks.
- Output paths: claude-code/cursor → output_root/skills_dir/aid-{name}/; codex → assets_root/skills_dir/aid-{name}/ (split layout).
- references/*.md: substitute_filenames() applied; all three filename_map placeholders resolved.
- scripts/*.sh: verbatim copy (no substitution — abstract names already).
- Cursor extras: _render_cursor_extras() copies canonical/rules/*.mdc into cursor/.cursor/rules/. Decision: keep in render_skills.py (not a separate render_extras.py) since the extras are simple verbatim copies triggered by profile.extras.rules.
- File counts: claude-code: 23 files (10 SKILL.md + 11 references + 2 scripts); codex: 23 files (same); cursor: 25 files (23 + 2 .mdc rules).
- canonical/rules/ created as part of this task to house aid-methodology.mdc and aid-review.mdc (byte-identical copies from cursor/.cursor/rules/).

## Spot-check

- claude-code aid-discover/SKILL.md: BYTE IDENTICAL to install tree (453 lines) ✓
- cursor aid-discover/SKILL.md: "Terminal" in allowed-tools ✓
- codex aid-discover/SKILL.md: 453 lines (thin form, not 1078-line inlined) ✓
- cursor extras: aid-methodology.mdc and aid-review.mdc emitted into cursor/.cursor/rules/ ✓
- Two consecutive renders: byte-identical ✓
