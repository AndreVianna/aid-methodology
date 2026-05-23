# task-009: Bootstrap `canonical/skills/aid-summarize/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-summarize/` from `claude-code/.claude/skills/aid-summarize/`.
- `aid-summarize` is mid-complexity (Claude Code SKILL.md = 430 lines per module-map.md Module 3). Optional phase, well-tested (the H8 grading-rubric overhaul of 2026-05-21 touched its body across all three trees — they were re-aligned then, so drift should be low).
- Files to author:
  - `canonical/skills/aid-summarize/SKILL.md` (~430 lines).
  - `canonical/skills/aid-summarize/references/*.md` (Claude Code has none in module-map.md table, but verify).
  - `canonical/skills/aid-summarize/scripts/*.sh` if any.
- Apply abstract-frontmatter + placeholder discipline as in tasks 006–008.
- **Special attention:** `aid-summarize` invokes a large set of runtime validation scripts inside `templates/knowledge-summary/scripts/` (`validate-html.sh`, `validate-links.sh`, `validate-diagrams.mjs`, `contrast-check.mjs`, `manual-checklist.sh`, `spot-check-facts.sh`, `grade.sh`). Those scripts live under `canonical/templates/knowledge-summary/scripts/` after task-005; the SKILL.md should reference them through their canonical-relative path so the renderer can per-profile-rewrite the path when emitting into each install tree.
- Verify against Codex and Cursor: post-H8 the three SKILL.md bodies should be very close; flag any residual divergence.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-summarize/SKILL.md` exists with abstract frontmatter.
- [ ] `references/` and `scripts/` siblings (if any) carried over.
- [ ] Cross-tree body reconciliation documented in the execution record (Codex and Cursor compared to Claude Code; non-cosmetic divergences resolved).
- [ ] Script-path references inside SKILL.md use the canonical-tree-relative form so the renderer can rewrite them per-profile.
- [ ] Placeholder substitution applied.
