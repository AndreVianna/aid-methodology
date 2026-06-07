# task-012: Installation guide — `guides/installation.mdx`

**Type:** IMPLEMENT

**Source:** feature-004-installation-guide → delivery-002

**Depends on:** task-010

**Scope:**
- Author `site/src/content/docs/guides/installation.mdx` (hand-authored `.mdx`, D1/D2) at the `guides/installation` slug, sourced faithfully from `docs/install.md` (AC5).
- Import Starlight `<Tabs>/<TabItem>/<Steps>/<Aside>/<LinkButton>` and feature-008's `<InstallCommand>` (correct depth `../../../components/`).
- Sections per the SPEC outline: (1) How it works (two layers); (2) Choose your channel (comparison table, D4); (3) Step 1 bootstrap per-channel with `<Tabs syncKey="os">` and `<InstallCommand>` for curl/irm/npm/pypi/offline (D5); (4) Step 2 add-to-project `<Tabs syncKey="tool">` for the five profiles; (5) one-line first install; (6) Update; (7) Remove; (8) Next steps / see also.
- Every version-bearing command renders via `<InstallCommand channel=… />` (D5); non-versioned subcommands are plain fenced blocks. Per-OS and per-tool tabs use distinct `syncKey`s (D3).
- Cross-links target live routes (Reference / Get Started / Releases), not migrated-`install.md` anchors (D8).

**Acceptance Criteria:**
- [ ] All four channels (curl/irm, npm, PyPI, offline) documented with copyable commands (AC7).
- [ ] Per-tool "add to project" instructions in `<Tabs syncKey="tool">` for Claude Code / Codex / Cursor / Copilot CLI / Antigravity (AC7).
- [ ] Update and remove procedures present.
- [ ] Every version-bearing command (incl. the Windows `irm` bootstrap) renders via `<InstallCommand>` with no version literal in the file (AC13).
- [ ] Content is faithful to `docs/install.md` per the section mapping; internal cross-links resolve (AC5).
- [ ] `syncKey="os"` and `syncKey="tool"` are independent.
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
