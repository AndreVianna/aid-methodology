# task-015: Human-facing prose lockstep across docs, site, CONTRIBUTING, and READMEs

**Type:** DOCUMENT

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Retire **EVERY** retired-layout reference (enumerate the whole class — do NOT pin only to the lines cited in the feature SPEC) in the shipped human-facing docs, per feature-004 SPEC §B.2:
  - `docs/install.md` — collapse the `.codex/` + `.agents/` install description to a single `.codex/{agents,skills,aid}`; drop the "`.agents/` alternate path" bullets (including `:785` and the `:418-423` sub-bullets).
  - `docs/repository-structure.md` — codex row/tree `.codex/ + .agents/` → `.codex/`.
  - `docs/faq.md` — "installs to `.codex/agents/` + `.agents/`" → `.codex/`.
  - `docs/aid-methodology.md` — retire the **copilot-agent** + **antigravity-rule** format bullets; collapse the per-tool format table (codex split, the 4-format column) to uniform markdown; fix the `{.claude/ | .codex/+.agents/ | …}` layout line.
  - `docs/glossary.md` — codex `.codex/agents/` + `.agents/` → `.codex/`.
  - `CONTRIBUTING.md` — codex-split lines + generated-tree references.
  - `profiles/cursor/README.md` and `profiles/codex/README.md` — rewrite to the unified layout; **verify** `profiles/claude-code/README.md` is already clean. (READMEs are hand-maintained and tarball-excluded — a residual doc edit, not a render output.)
- Run `node site/scripts/sync-docs.mjs` and **commit** the regenerated synced site copies `site/src/content/docs/{concepts,reference}/*` (sources `aid-methodology`, `faq`, `repository-structure`, `glossary` per the MANIFEST at `sync-docs.mjs:31-72`).
- Hand-edit the NON-synced site pages: `site/src/content/docs/guides/installation.mdx` (`:19,205-206`) and `site/src/content/docs/reference/cli.mdx` — neither is in the sync manifest.
- **Out of scope (do NOT touch):** `.aid/knowledge/*` (tasks 016–019), `release.sh` (task-014), generator scripts / `profiles/*` rendered trees / `canonical/*` (feature-002), `lib/*`/`bin/*` (feature-003), and the `gen-reference.mjs`-generated site pages (skills/agents/kb/settings — they carry no layout references and skill/agent counts are unchanged, OQ3).

**Acceptance Criteria:**
- [ ] NO retired-layout string survives in ANY shipped human-facing doc — the criterion is "every reference of the class," not the cited line-list (verified by a class-wide grep for `.agents/`, codex-split, copilot-agent, antigravity-rule across `docs/`, `CONTRIBUTING.md`, `profiles/*/README.md`, `site/`).
- [ ] The synced site copies match their `docs/*` sources: `sync-docs.mjs` re-run produces no diff (idempotent), and the regenerated `site/src/content/docs/{concepts,reference}/*` are committed.
- [ ] The hand-edited `installation.mdx` and `cli.mdx` carry no `.agents`/codex-split mention.
- [ ] `profiles/cursor/README.md` and `profiles/codex/README.md` describe the unified layout; `profiles/claude-code/README.md` verified clean; all profile READMEs remain tarball-excluded.
- [ ] DOCUMENT default: accuracy verified against the current (settled, post-001/002/003) layout.
- [ ] All §6 quality gates pass.
