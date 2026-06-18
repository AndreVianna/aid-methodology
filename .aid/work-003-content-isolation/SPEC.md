# AID / User Content Isolation

- **Name:** AID/user content isolation
- **Description:** Isolate all AID-delivered content from user content so install/update can prune stale AID files and update in place without touching user content.
- **Work:** work-003-content-isolation
- **Created:** 2026-06-18
- **Source:** /aid-interview lite path — LITE-REFACTOR
- **Status:** Ready

## Goal

Today AID-delivered files share directories (and a root-agent file) with user
content, and there is no install-time prune. When AID renames, moves, or drops
a file, the stale copy lingers in the adopter project forever (`copy_dir`
overlays the new tree, `manifest_write` only merges). The root-agent update path
also writes a lossy `.aid-new` sidecar on any divergence. The cornerstone of
this work: **all AID-delivered content must be isolated from user content so
install/update can prune stale AID files and update in place WITHOUT touching
user content.** Success = every AID-owned file is either nested under an `aid/`
subtree or carries the `aid-` prefix; install/update prunes orphaned AID files
by prefix + new-manifest membership; the root-agent file is updated only between
`<!-- AID:BEGIN -->`/`<!-- AID:END -->` markers, losslessly, with no `.aid-new`;
and the cornerstone is recorded in the project KB and enforced by the reviewer.

## Context

This is the AID dogfood repo (AID building AID). The grounded codebase map is in
`.aid/work-003-content-isolation/ANALYSIS.md` (read it first); this SPEC
consolidates the four locked design pillars and turns them into acceptance
criteria. The design decisions below are LOCKED — do not re-litigate.

**Content model.** Two classes of AID-delivered content:
- **AID-own folders** — generic names AID invented; the host tool does NOT
  require the path: `scripts/`, `templates/`, `recipes/`. These NEST under an
  `aid/` subtree.
- **Tool-native folders** — the host tool requires the exact path: `agents/`,
  `skills/`, `rules/`. These KEEP their path; the AID files inside are isolated
  by the `aid-` prefix and pruned by prefix + manifest membership.
- **Root-agent files** — `CLAUDE.md` / `AGENTS.md` — share the file with
  user-owned sections; AID content is fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`.

**Per-profile classification** (assets root in brackets; from ANALYSIS.md):

| Profile [root] | tool-native (keep; prune `aid-*`) | AID-own (→ `aid/`) |
|---|---|---|
| claude-code [.claude] | agents/ (`aid-*.md`), skills/ (`aid-*/`, `aid-README.md`) | scripts, templates, recipes → `.claude/aid/{scripts,templates,recipes}` |
| codex [.codex + .agents] | .codex/agents/ (`aid-*.toml`), .agents/skills/ (`aid-*/`, `aid-README.md`) | `.agents/aid/{scripts,templates,recipes}` (NOT under `.codex/`) |
| cursor [.cursor] | agents/, skills/ (`aid-README.md`), rules/ (`aid-*.mdc`) | scripts, templates, recipes → `.cursor/aid/{scripts,templates,recipes}` |
| copilot-cli [.github] | .github/agents/ (`aid-*.agent.md`), .github/skills/ | `.github/aid/{scripts,templates,recipes}` |
| antigravity [.agent] | rules/ (`aid-*.md`), skills/ | scripts, templates, recipes → `.agent/aid/{scripts,templates,recipes}` |

**Key risks (from ANALYSIS.md), baked into the design below:**
- **R1:** `.github/` is shared GitHub user content — isolation must scope to
  `.github/{agents,skills,aid/}` ONLY; never treat `.github` root as AID-own.
- **R2:** the committed `profiles/{claude-code,codex,cursor}/.../skills/README.md`
  is AID content WITHOUT the `aid-` prefix — it is profile-local committed data
  (not generated, absent from every `emission-manifest.jsonl`). Rename to
  `aid-README.md` so a prefix-only prune can manage it.
- **R3:** the toml `[layout]` `*_dir` keys (`scripts_dir`/`templates_dir`/`recipes_dir`)
  and `render_lib._CANONICAL_PATH_DIRS` + `rewrite_install_paths` MUST stay
  lockstep — the nest splits AID-own (rewrite → `<root>/aid/<x>/`) from
  tool-native (unchanged).
- **R4:** `canonical/templates/generated-files.txt` references the kb build
  scripts as `canonical/scripts/kb/...` DATA lines (non-comment) — the
  chokepoint `rewrite_install_paths` AUTO-rewrites these (only `#`-leading
  comment lines are skipped; see `render_lib.py:172-178`). There is NO
  `.claude/scripts/kb/...` literal to hand-edit; after Pillar 1 these refs
  auto-nest to `…/aid/scripts/kb/…`. VERIFY the rendered output, do not
  hand-edit the source data lines.
- **R6:** codex split — the nest applies to `.agents/`; `.codex/` ships only `agents/`.
- **R7:** NO install-time prune exists today in bash (`install_tool`) OR PS
  (`Install-Tool`) — net-new in BOTH, in lockstep.
- **R8:** root-agent files are NOT generated — markers go in committed
  `profiles/*/CLAUDE.md` + `AGENTS.md`; consumer is `_copy_root_agent_file`
  (bash) + `Copy-RootAgentFile` (PS).

KB references (by INDEX.md doc name): `architecture.md`, `pipeline-contracts.md`,
`module-map.md`, `project-structure.md`, `coding-standards.md`,
`test-landscape.md`, `schemas.md`.

---

## Design

### Pillar 1 — Nest AID-own folders under `aid/`

`scripts/`, `templates/`, `recipes/` move to `<assets-root>/aid/{scripts,templates,recipes}`
in every profile. The nest is implemented at the single generator chokepoint plus
the three dst builders, kept lockstep with the toml `*_dir` keys, then `profiles/`
is regenerated.

- **Chokepoint (`render_lib.py`).** Split the rewrite so AID-own dirs rewrite to
  the nested path and tool-native dirs stay unchanged:
  - AID-own set = `{scripts, templates, recipes}` → `canonical/<x>/` rewrites to
    `<install_root>/aid/<x>/`.
  - Tool-native set = `{skills, agents, rules}` → `canonical/<x>/` rewrites to
    `<install_root>/<x>/` (current behavior, unchanged).
  - The existing comment-skip and word-boundary rules in `rewrite_install_paths`
    are preserved; idempotence is preserved (re-running on already-nested text is
    a no-op).
- **Dst builders.** `render_canonical_scripts._scripts_output_root`,
  `render_templates._templates_output_root`, `render_recipes._recipes_output_root`
  emit under `<root>/aid/<dir>` (single-root: `output_root/aid/<dir>`; codex split:
  `assets_root/aid/<dir>`, never `agents_root`). The `<dir>` segment continues to
  come from the toml `*_dir` key.
- **Toml `*_dir` keys (R3).** The `scripts_dir`/`templates_dir`/`recipes_dir`
  values express the nested location so the chokepoint and the builders stay
  lockstep. Whichever lockstep convention is chosen (the `aid/` segment lives in
  the builder vs. baked into the `*_dir` value) MUST be consistent across all five
  profiles and across the chokepoint constant — see Spec Decision SD-1.
- **`.github` scope (R1).** For copilot-cli the nest produces
  `.github/aid/{scripts,templates,recipes}`; tool-native stays at
  `.github/{agents,skills}`. The `.github` root itself is never AID-own and is
  never pruned.
- **`generated-files.txt` (R4).** The kb-build DATA lines reference
  `canonical/scripts/kb/...` (non-comment lines), so the chokepoint
  `rewrite_install_paths` AUTO-nests them post-Pillar-1 (the comment-skip in
  `render_lib.py:172-178` only spares `#`-leading lines). No hand-edit of the
  source is needed; VERIFY that the rendered `generated-files.txt` in each
  profile shows the nested `…/aid/scripts/kb/…` form.
- **Regenerate.** Run the FULL `run_generator.py` so every profile tree and every
  `emission-manifest.jsonl` reflects the nested dst paths. The generator's
  deletion pass removes the old (un-nested) emitted paths on first regen.
- **Dogfood tree (hand-migrated — §7a).** The repo-root `.claude/` (the tree this
  AID repo itself uses) is hand-maintained and is NOT written by `run_generator.py`
  (which iterates only `profiles/*.toml`). Per `coding-standards.md §7a` the
  byte-identity invariant spans the 6 generated trees PLUS this hand-maintained
  dogfood `.claude/` (7 on-disk copies). After the nest the dogfood tree must be
  migrated BY HAND to match `profiles/claude-code/.claude/`: move its AID-own dirs
  to `.claude/aid/{scripts,templates,recipes}`, apply the `skills/README.md` →
  `aid-README.md` rename, and rewrite the AID-own body path-refs inside its
  skills/agents (`.claude/scripts|templates|recipes/…` → `.claude/aid/…`).
  Otherwise the dogfood tree diverges from the generated profile (breaking §7a),
  the repo's own skill path-resolution breaks, and render-drift CI — which diffs
  only `profiles/` — will not catch it. task-003 owns this hand-migration.

### Pillar 2 — Prefix-isolate + prune tool-native AID files

Tool-native dirs (`agents/`, `skills/`, `rules/`) keep their path; AID files
inside them carry the `aid-` prefix. A net-new install/update prune removes stale
AID files.

- **`skills/README.md` → `aid-README.md` (R2).** Rename the committed
  profile-local file in `profiles/{claude-code,codex,cursor}/.../skills/` so
  nothing AID is un-prefixed. This file is NOT generated and appears in no
  manifest; the rename is a straight file move in each profile. Update any body
  references to it. After the rename it falls under the prefix rule.
- **Prune (net-new — R7).** After the per-tool copy + manifest write in
  `install_tool` (bash) and `Install-Tool` (PS), prune within each tool's
  scoped AID directories:
  - **Prune basis = `aid-` prefix + new-manifest membership** (the user
    explicitly rejected reading the old manifest; NOT an old-manifest diff).
  - **Remove** (the manifest stores FILE paths only, never directory entries —
    so the keep/remove test for a directory is about its CONTENTS, not its own
    membership):
    - (a) an `aid-`-prefixed FILE inside a tool-native dir (e.g.
      `agents/aid-foo.md`, `skills/aid-README.md`) when that file path is NOT in
      the new manifest's path set;
    - (b) an `aid-`-prefixed DIRECTORY inside a tool-native dir (e.g.
      `skills/aid-skill/`) when NONE of its files appear in the new manifest's
      path set — a current skill dir whose files ARE in the set is KEPT (do not
      delete it just because the dir path itself is never a set member);
    - (c) any FILE anywhere under the nested `aid/` subtree when its path is NOT
      in the new manifest's path set (and prune now-empty `aid/` subdirs).
  - **Never remove** non-`aid-`-prefixed entries (user content) and never touch
    anything outside the tool's scoped AID directories.
  - **Scope (R1):** for copilot-cli the prune walks only
    `.github/{agents,skills,aid}`, never the `.github` root.
  - The prune walks the tool's installed-and-scoped directories, comparing each
    candidate path against the new manifest's path set (the same set just written
    by `manifest_write`).
- **Parity.** bash (`install_tool` / `lib/aid-install-core.sh`) and PowerShell
  (`Install-Tool` / `lib/AidInstallCore.psm1`) implement byte-for-byte equivalent
  prune semantics (same candidate selection, same keep/remove decision, same
  scoping). `bin/aid` and `bin/aid.ps1` stay ASCII-only.

### Pillar 3 — Boundary in CLAUDE.md / AGENTS.md

The AID-managed sections of the committed root-agent files are fenced by
`<!-- AID:BEGIN -->` / `<!-- AID:END -->`; the installer updates ONLY that region
in place, losslessly, and the `.aid-new` fallback is eliminated.

- **Committed markers (R8).** In `profiles/claude-code/CLAUDE.md` and
  `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md`, wrap the AID-managed
  sections (`## Tracking discipline (IMPERATIVE)`, `## Knowledge Base`,
  `## Review output format`, `## Permissions` — i.e. everything after the
  user-owned header section) in `<!-- AID:BEGIN -->` … `<!-- AID:END -->`. The
  user-owned `## Project` / `## Project Overview` section stays OUTSIDE the
  markers. These files are committed, not generated.
- **Orphaned AID-own refs in committed files (R8).** Because these files are NOT
  generated, the chokepoint never rewrites their bodies — so any AID-own path
  reference inside them is stale after the Pillar-1 nest and must be hand-updated
  here. The `## Review output format (global)` section cites
  `reviewer-ledger-schema.md`: claude-code → `.claude/aid/templates/…`, the four
  AGENTS.md → `aid/templates/…`. Update these (and any other `scripts`/`templates`/
  `recipes` install-root ref in the five files) to the nested `aid/` form.
- **In-place region update (`_copy_root_agent_file` bash + `Copy-RootAgentFile` PS).**
  Replace the lossy whole-file-copy / `.aid-new` algorithm with a region update:
  1. If the destination is absent → write the full source file (markers included).
  2. If the destination has `<!-- AID:BEGIN -->` … `<!-- AID:END -->` → replace
     ONLY the bytes between (and including) the markers with the source's marked
     region; preserve everything outside verbatim.
  3. **Eliminate `.aid-new` entirely** — updates are in-place and lossless; never
     write a backup/sidecar file under any branch (including non-`--force` divergence).
- **Migration when no markers exist.** When the destination has no markers:
  - If the file still matches the AID-recorded sha (from the manifest's
    `root_agent_files`) → clean rewrite to the full marked source.
  - Else → excise the known AID-managed sections (`## Knowledge Base`,
    `## Review output format`, `## Permissions`) wherever they appear and
    re-insert them, wrapped in the markers, in place — preserving
    `## Project` / `## Project Overview` and all other user content. Never write a
    backup file. **Heading match is by normalized stem, not exact string:** the
    committed source heading is `## Review output format (global)` (not
    `## Review output format`), so the excise must match the heading stem and
    tolerate a trailing parenthetical suffix (e.g. ` (global)`) — applied
    identically in bash and PS so the marker-less migration is deterministic.
- **Cleanup.** Remove the stray `AGENTS.md.aid-new` at the repo root.
- **Parity.** bash and PowerShell implement identical region-update + migration
  semantics. `bin/aid` / `bin/aid.ps1` stay ASCII-only.

### Pillar 4 — Make it enforced

- **Project KB.** Record the content-isolation cornerstone in the project KB
  (`.aid/knowledge/`, NOT canonical) as a standing convention: the two content
  classes, the `aid/`-nest rule, the `aid-` prefix rule, the prune basis, and the
  root-agent marker boundary. Regenerate `.aid/knowledge/INDEX.md` via
  `canonical/scripts/kb/build-kb-index.sh` if a new doc is added.
- **Fix stale layout docs.** The nest makes existing project-KB layout
  descriptions stale; correct them to the nested install-tree paths (factual
  path updates only): `project-structure.md` (helper-scripts mirror + recipes
  profile-tree list), `module-map.md` (profile scripts-dir paths),
  `pipeline-contracts.md` (render-pass output table — AID-own rows nest,
  tool-native rows stay). Tool-native (`agents`/`skills`/`rules`) descriptions
  are unchanged.
- **Reviewer wiring.** Wire the cornerstone into the reviewer's standing criteria
  so future changes are checked for AID/user isolation (the reviewer evaluates
  against "KB conventions"; the cornerstone must be discoverable as one). Add a
  concrete check item: any new AID-delivered file is either nested under `aid/` or
  `aid-`-prefixed, and nothing AID-owned is un-prefixed outside an `aid/` subtree.

---

## Acceptance Criteria

**Pillar 1 — nest**
- [ ] Given a regenerated `profiles/` tree, when listing each profile's assets
      root, then `scripts/`, `templates/`, `recipes/` appear ONLY under
      `<assets-root>/aid/` (claude-code `.claude/aid/…`, codex `.agents/aid/…`,
      cursor `.cursor/aid/…`, copilot-cli `.github/aid/…`, antigravity `.agent/aid/…`)
      and nowhere at the un-nested location.
- [ ] Given codex's split layout, when checking `.codex/`, then it contains only
      `agents/` (no `scripts/`/`templates/`/`recipes/` and no `aid/` subtree) (R6).
- [ ] Given a skill body that referenced `canonical/scripts/...`, when rendered,
      then it resolves to `<install_root>/aid/scripts/...`; a body that referenced
      `canonical/skills/...` or `canonical/agents/...` or `canonical/rules/...`
      still resolves to the un-nested tool-native path (R3 split).
- [ ] Given copilot-cli, when nesting, then AID-own lands under `.github/aid/…`
      and the `.github` root holds only `{agents,skills,aid}` AID-relevant entries —
      `.github` itself is never treated as AID-own (R1).
- [ ] Given the RENDERED `generated-files.txt` in a profile tree (after the FULL
      regen), when inspected, then its kb-build DATA lines reference the nested
      `…/aid/scripts/kb/...` form (e.g. claude-code `.claude/aid/scripts/kb/...`);
      the canonical source data line stays `canonical/scripts/kb/...` and is
      auto-rewritten by the chokepoint — not hand-edited (R4).
- [ ] Given a second consecutive FULL `run_generator.py` run, when compared, then
      the emitted trees are byte-identical (render-drift clean) and every
      `emission-manifest.jsonl` dst path reflects the nested layout.
- [ ] Given the §7a byte-identity invariant (6 generated trees + the
      hand-maintained dogfood `.claude/`), when the dogfood `.claude/` is compared
      to the regenerated `profiles/claude-code/.claude/` after the nest, then they
      agree on the nested layout: `.claude/aid/{scripts,templates,recipes}` exists
      (no un-nested `.claude/{scripts,templates,recipes}` left), `.claude/skills/aid-README.md`
      is present (`README.md` gone), counterpart bodies are byte-identical, no
      repo-root `.claude/` skill/agent body references an un-nested
      `.claude/{scripts,templates,recipes}/` path, and the repo's own skills
      resolve their AID-own scripts at the nested path (F8 — hand-migration, since
      the generator never writes the dogfood tree).

**Pillar 2 — prefix-isolate + prune**
- [ ] Given each of `profiles/{claude-code,codex,cursor}`, when listing
      `…/skills/`, then `README.md` is gone and `aid-README.md` is present; no
      body reference to the old path remains (R2).
- [ ] Given an install over a tree that contains a stale `aid-`-prefixed entry
      (e.g. `agents/aid-old.md`) NOT in the new manifest, when install/update runs,
      then that entry is removed (orphan prune) — bash and PowerShell identical.
- [ ] Given a LIVE `aid-`-prefixed skill directory whose files ARE in the new
      manifest (e.g. `skills/aid-config/SKILL.md`), when install/update runs, then
      the directory is KEPT (it is never pruned merely because the dir path itself
      is not a manifest member); given a stale `aid-`-prefixed dir NONE of whose
      files are in the manifest (e.g. `skills/aid-old/`), then it is removed.
- [ ] Given an install over a tree with a user (non-`aid-`-prefixed) file in a
      tool-native dir, when install/update runs, then the user file is untouched.
- [ ] Given a stale file anywhere under the nested `aid/` subtree NOT in the new
      manifest, when install/update runs, then it is removed; given a current
      `aid/` file in the manifest, then it is kept.
- [ ] Given copilot-cli, when the prune runs, then it walks only
      `.github/{agents,skills,aid}` and never deletes anything at the `.github`
      root or outside those scoped dirs (R1).
- [ ] Given the prune logic, when bash and PowerShell are compared, then candidate
      selection, keep/remove decision, and scoping are equivalent; `bin/aid` and
      `bin/aid.ps1` are ASCII-only.

**Pillar 3 — root-agent boundary**
- [ ] Given each committed `profiles/*/CLAUDE.md` and `AGENTS.md`, when inspected,
      then `<!-- AID:BEGIN -->` precedes `## Tracking discipline (IMPERATIVE)` and `<!-- AID:END -->`
      follows `## Permissions`, with `## Project`/`## Project Overview` OUTSIDE the
      markers.
- [ ] Given each committed root-agent file, when inspected, then its
      `reviewer-ledger-schema.md` reference is nested (claude-code
      `.claude/aid/templates/…`, each AGENTS.md `aid/templates/…`) and no
      un-nested AID-own (`scripts`/`templates`/`recipes`) install-root path
      reference remains (R8 — chokepoint does not touch these files).
- [ ] Given a destination root-agent file with markers and user edits outside the
      markers, when update runs, then ONLY the marker region is replaced and all
      user content outside is preserved byte-for-byte.
- [ ] Given any divergence (including without `--force`), when update runs, then NO
      `.aid-new` (or any backup/sidecar) file is written — verified bash and PS.
- [ ] Given a marker-less destination that still matches the AID-recorded sha, when
      update runs, then the file is cleanly rewritten to the full marked source.
- [ ] Given a marker-less destination that does NOT match the recorded sha, when
      update runs, then the known AID-managed sections are excised and re-wrapped
      in markers in place, `## Project`/`## Project Overview` and other user content
      preserved, and no backup file is written.
- [ ] Given the repo root, when inspected, then `AGENTS.md.aid-new` is gone.
- [ ] Given the root-agent algorithm, when bash and PowerShell are compared, then
      region-update and both migration branches are equivalent.

**Pillar 4 — enforcement**
- [ ] Given `.aid/knowledge/`, when inspected, then the content-isolation
      cornerstone (two classes, `aid/`-nest, `aid-` prefix, prune basis, marker
      boundary) is documented; `INDEX.md` is regenerated if a doc was added.
- [ ] Given the existing project-KB layout docs (`project-structure.md`,
      `module-map.md`, `pipeline-contracts.md`), when inspected after the nest,
      then no AID-own install-tree path is described un-nested — the helper-scripts
      mirror, profile scripts-dir paths, and AID-own render-pass output columns
      all show the nested `…/aid/{scripts,templates,recipes}` form; tool-native
      rows stay un-nested.
- [ ] Given the reviewer's standing criteria, when a change adds an AID-delivered
      file, then the reviewer checks it is `aid/`-nested or `aid-`-prefixed and
      flags any un-prefixed AID file outside an `aid/` subtree.

**Cross-cutting / quality gates**
- [ ] FULL `tests/run-all.sh` is green (51 suites); the ~80 affected test
      path-refs are triaged (repo-root dev invocations under `canonical/` are
      unaffected; install-root/profile-root refs updated to the nested/prefixed
      paths).
- [ ] New regression tests cover: orphan `aid-*` removed on update; user
      (non-`aid-`) files untouched; `.github` prune scoped (R1); nested-path
      resolution; root-agent in-place region update + user-content preserved + NO
      `.aid-new` + both migration branches.
- [ ] The Windows-only `tests/windows/Test-AidInstaller.ps1` and the workflow
      inline smokes (outside `run-all.sh`) are updated wherever this work changes
      install/CLI behavior (prune, root-agent region update).
- [ ] All §6 quality gates pass.

## Spec Decisions (beyond the locked pillars)

- **SD-1 (lockstep convention for the `aid/` segment).** R3 requires the
  chokepoint constant, the dst builders, and the toml `*_dir` keys to stay
  lockstep. The locked decision fixes the OUTPUT (`<root>/aid/<x>/`) but not
  WHERE the `aid/` segment is encoded. This SPEC requires a single consistent
  convention across all five profiles and the chokepoint; the IMPLEMENT tasks
  must pick one and apply it uniformly (recommended: keep `*_dir` as the bare
  leaf name and encode the `aid/` parent in the builder + chokepoint, so the
  five profiles need no per-profile `aid/` string and the AID-own/tool-native
  split lives in exactly one place). Either encoding is acceptable provided it is
  uniform and render-drift clean.
- **SD-2 (KB doc placement).** The cornerstone is added to the project KB as a
  standing convention. This SPEC does not mandate a new file vs. an addition to
  `coding-standards.md`; the DOCUMENT task chooses, and regenerates `INDEX.md`
  only if a new doc is created. Recommended: a short dedicated section so the
  reviewer can cite it cleanly.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Nest AID-own dirs at the generator chokepoint + dst builders + toml keys |
| task-002 | REFACTOR | Rename committed `skills/README.md` → `aid-README.md` in all profiles |
| task-003 | CONFIGURE | Regenerate `profiles/` + emission manifests; hand-migrate dogfood `.claude/`; verify `generated-files.txt` auto-nests |
| task-004 | IMPLEMENT | Net-new install/update prune (bash, `aid-install-core.sh`) |
| task-005 | IMPLEMENT | Net-new install/update prune (PowerShell, `AidInstallCore.psm1`) — parity |
| task-006 | REFACTOR | Add AID:BEGIN/END markers to committed root-agent profiles + clean up stray `.aid-new` |
| task-007 | IMPLEMENT | Root-agent in-place region update + migration, no `.aid-new` (bash) |
| task-008 | IMPLEMENT | Root-agent in-place region update + migration, no `.aid-new` (PowerShell) — parity |
| task-009 | DOCUMENT | Record content-isolation cornerstone in project KB + regenerate INDEX |
| task-010 | DOCUMENT | Wire the cornerstone into the reviewer's standing criteria |
| task-011 | TEST | Cross-cutting regressions + path-ref triage + run-all + render-drift + Windows/workflow smokes |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | — (none) |
| task-003 | task-001, task-002 |
| task-004 | task-003 |
| task-005 | task-004 |
| task-006 | — (none) |
| task-007 | task-006 |
| task-008 | task-007 |
| task-009 | — (none) |
| task-010 | task-009 |
| task-011 | task-003, task-004, task-005, task-007, task-008, task-010 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001, task-002, task-006, task-009 |
| 2 | task-003, task-007, task-010 |
| 3 | task-004, task-008 |
| 4 | task-005 |
| 5 | task-011 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-18 | Initial lite-path SPEC created | /aid-interview LITE-REFACTOR |
