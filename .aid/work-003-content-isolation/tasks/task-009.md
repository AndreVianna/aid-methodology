# task-009: Record content-isolation cornerstone in project KB + regenerate INDEX

**Type:** DOCUMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** — (none)

**Scope:**
- Document the content-isolation cornerstone in the project KB (`.aid/knowledge/`, NOT canonical) as a standing convention: the two content classes (AID-own vs. tool-native), the `aid/`-nest rule, the `aid-` prefix rule, the prune basis (`aid-` prefix + new-manifest membership), and the root-agent `<!-- AID:BEGIN -->`/`<!-- AID:END -->` marker boundary (SD-2 — choose a short dedicated section or an addition to an existing doc such as `coding-standards.md`).
- Update the existing project-KB layout docs that now describe a stale (un-nested) install-tree layout, to the nested `aid/` paths — factual path updates only (no re-architecting the doc):
  - `project-structure.md`:
    - the dogfood `.claude/` tree-view description (~:58-64 — the `├── .claude/` block whose child lines name `recipes/`, `scripts/`, `templates/` directly under `.claude/`): reflect the nested `.claude/aid/{scripts,templates,recipes}` layout (F8 — the dogfood tree is hand-migrated to match the profile);
    - the `## Helper scripts` mirror description (~:209, "the dogfood `.claude/scripts/` copy" / profile-tree scripts paths) and the recipes profile-tree list (~:365, `profiles/codex/.agents/recipes/` etc.); reflect the nested `…/aid/{scripts,recipes,templates}` install-tree locations;
    - the `## Unusual Structure Notes` mirror/dogfood references (~:403 — the "7 byte-identical copies … dogfood `.claude/`" and the "Dogfood `.claude/` tree" note that cites `.claude/scripts/`): reflect the nested form.
    - (The `canonical/` tree-view line ~:70 describes the canonical source layout, which does NOT nest — leave it, except where it points at the install-tree `.claude/scripts/` mirror.)
  - `module-map.md` (~:185-187) — the 5 profile-tree scripts-dir paths (`profiles/claude-code/.claude/scripts/` … `profiles/antigravity/.agent/scripts/`) → nested `…/aid/scripts/`.
  - `pipeline-contracts.md` (~:709-711) — the render-pass output table rows for `canonical/templates/`, `canonical/recipes/`, `canonical/scripts/`: the per-profile output columns (`.claude/templates/`, `.agents/recipes/`, `.github/scripts/`, etc.) → nested `…/aid/{templates,recipes,scripts}`. The `agents/`/`skills/`/`rules/` rows stay un-nested (tool-native).
- If a new KB doc is created, regenerate `.aid/knowledge/INDEX.md` via `canonical/scripts/kb/build-kb-index.sh` (not the `.claude/` copy).

**Acceptance Criteria:**
- [ ] `project-structure.md`, `module-map.md`, and `pipeline-contracts.md` describe the nested install-tree layout (`<assets-root>/aid/{scripts,templates,recipes}`) wherever they previously named un-nested install-tree paths; this includes the dogfood `.claude/` tree-view block (~:58-64) and the helper-scripts-mirror / Unusual-Structure dogfood references in `project-structure.md`, which now show `.claude/aid/{scripts,templates,recipes}` (F8). The AID-own render-pass output columns in `pipeline-contracts.md` show the nested `aid/` form while tool-native rows (agents/skills/rules) stay un-nested. No project-KB doc still names an un-nested AID-own install-tree path. `INDEX.md` is regenerated.
- [ ] The project KB documents all five cornerstone elements (two classes, `aid/`-nest, `aid-` prefix, prune basis, marker boundary) in a citable location.
- [ ] The doc states the invariant: every AID-delivered file is either nested under an `aid/` subtree or `aid-`-prefixed; nothing AID-owned is un-prefixed outside an `aid/` subtree.
- [ ] If a new doc was added, `.aid/knowledge/INDEX.md` is regenerated via the canonical build script and lists it; KB-hygiene checks pass.
- [ ] All §6 quality gates pass.
