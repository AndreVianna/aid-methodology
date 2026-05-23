# task-012: Bootstrap `canonical/skills/aid-interview/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-interview/` from `claude-code/.claude/skills/aid-interview/`.
- Heavyweight: Claude Code 477 lines, Codex 694, Cursor 698 (per `tech-debt.md` H1). 4 `references/*.md` files on Claude Code per module-map.md table:
  - `cross-reference.md` (97 lines)
  - `feature-decomposition.md` (82 lines)
  - `interview-strategies.md` (81 lines)
  - `kb-hydration.md` (106 lines)
- The Codex / Cursor SKILL.md retain one `references/` survivor — `aid-interview/references/kb-hydration.md` 106 lines — per `coding-standards.md §1.3` ("One exception in both Codex and Cursor: `aid-interview/references/kb-hydration.md` 106 lines"). So three of the four references are inlined in Codex / Cursor; one is already externalized. The drift-resolution check must account for this asymmetry.
- Files to author: `SKILL.md` + the four `references/*.md` listed above + any `scripts/` (Claude Code has none per module-map.md, but verify).
- Drift resolution per the methodology in task-011: per `references/*.md` file, find the corresponding inlined block (or already-externalized file) in Codex / Cursor and diff. Resolve any non-cosmetic divergence explicitly.
- Apply abstract-frontmatter + `{filename_map}` discipline.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-interview/SKILL.md` (~477 lines) + four `references/*.md` files exist with abstract frontmatter.
- [ ] Drift-resolution log enumerates each non-cosmetic divergence (or asserts there were none).
- [ ] The already-externalized `kb-hydration.md` is byte-compared across all three trees first — if drift exists even in this externalized file, the resolution is documented.
- [ ] Placeholder substitution applied.
- [ ] FR2-style per-task quick check: maintainer reviews the drift-resolution log before downstream tasks depend on this bootstrap.
