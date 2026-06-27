# task-052: Docs-site gen-reference SKILL_GROUPS + skills.md regen + dogfood self-install

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-049

**Scope:**
- f009 Part 4 (S7/S8) + Part 5 (S10, AC12) -- the docs-site generator/page and this repo's own
  dogfood AID install.
- **Docs-site generator (S7, `site/scripts/gen-reference.mjs` -- hand-authored map + count):**
  (a) in `SKILL_GROUPS` (l.83-), rename `{ name: 'aid-ask', phase: 'on demand . read-only Q&A' }`
  (l.126) -> `aid-query-kb`, and **add** `{ name: 'aid-update-kb', phase: 'on demand . targeted KB
  update' }` to the same on-demand group (alongside `aid-housekeep`); (b) bump the hard-coded intro
  string (l.153) `'AID ships **12 user-facing skills** ... plus two off-pipeline on-demand skills'`
  -> **13** and **"plus three off-pipeline on-demand skills"** (`aid-query-kb` read +
  `aid-housekeep` + `aid-update-kb`).
- **Docs-site reference page (S8, `site/src/content/docs/reference/skills.md` -- generated):**
  REGENERATE by running `node site/scripts/gen-reference.mjs` (the per-skill table is built by
  `generateSkillsPage()` reading `canonical/skills/*/SKILL.md`, so `aid-query-kb`/`aid-update-kb`
  appear and the `aid-ask` entry at l.115-121 disappears automatically; the intro count comes from
  the bumped string). **Do NOT hand-edit** (`<!-- generated -- do not edit -->`, l.7).
- **Dogfood self-install (S10, Part 5 -- this repo's own AID install; NOT a render target, NOT
  render-drift-gated):**
  - `.claude/skills/aid-ask/` -> replace with the rendered `aid-query-kb/` + `aid-update-kb/` (copy
    from `profiles/claude-code/.claude/skills/` after task-049, or re-run the AID install/migration
    against this repo -- SPIKE-B mechanism choice; either yields the same end state) and remove the
    orphaned `aid-ask/` dir.
  - `.aid/.aid-manifest.json` -> update the claude-code tool's path list (l.394
    `".claude/skills/aid-ask/SKILL.md"` -> `aid-query-kb`; add the `aid-update-kb` paths incl. its
    `references/state-*.md`).
- **Out of scope:** KB-doc prose counts + INDEX + narrative (task-050); summary-src + kb.html
  (task-051).

**Acceptance Criteria:**
- [ ] `gen-reference.mjs` `SKILL_GROUPS` renames `aid-ask` -> `aid-query-kb` and adds
  `aid-update-kb` in the on-demand group; the intro string is "13 user-facing skills" + "plus three
  off-pipeline on-demand skills".
- [ ] `node site/scripts/gen-reference.mjs` runs clean and regenerates
  `site/src/content/docs/reference/skills.md`; `git diff` on that page shows the rename + the new
  `aid-update-kb` entry + the bumped count; `grep aid-ask site/src/content/docs/reference/skills.md`
  is empty (the page was regenerated, not hand-edited).
- [ ] `find .claude/skills -path '*aid-ask*'` is empty; `aid-query-kb/` and `aid-update-kb/` (incl.
  `references/state-*.md`) are present under `.claude/skills/`.
- [ ] `grep aid-ask .aid/.aid-manifest.json` is empty; the claude-code tool path list carries the
  `aid-query-kb` and `aid-update-kb` paths.
- [ ] All section-6 quality gates pass.
