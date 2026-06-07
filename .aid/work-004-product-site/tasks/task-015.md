# task-015: Verify migration — no-loss, links, Mermaid, drift-check

**Type:** TEST

**Source:** feature-005-content-migration → delivery-003

**Depends on:** task-014

**Scope:**
- Verify each of the four migrated pages appears with no content loss vs its `docs/*.md` source (AC5) and carries required frontmatter incl. `title` (§8).
- Verify all 7 Mermaid diagrams on `concepts/methodology` render as SVG and are horizontally scrollable (AC5).
- Run a post-build internal link/anchor checker over `dist/` HTML and confirm no unresolved internal `href`/anchor (AC5; external links reported, not failed).
- Verify the relocated image renders (optimized via the content image pipeline).
- Verify the sync drift-check: run `npm run sync:docs` then `git diff --exit-code` scoped to **only sync-docs' own outputs** — the four migrated pages (`site/src/content/docs/concepts/methodology.md`, `concepts/faq.md`, `reference/repository-structure.md`, `reference/glossary.md`), `site/src/assets/`, and `site/scripts/.synced-manifest.json` — produces no diff (idempotency + drift guard, D2). Scope the diff to these paths (NOT the whole `site/src/content/docs/` tree) so it does not collide with feature-006's separately-generated reference pages (task-016).

**Acceptance Criteria:**
- [ ] All four pages: no content loss, valid frontmatter, build passes.
- [ ] 7 methodology Mermaid diagrams render as SVG and scroll horizontally on narrow viewports.
- [ ] Internal link/anchor check over built HTML passes with zero unresolved internal targets.
- [ ] The relocated image renders.
- [ ] Fresh `sync:docs` + `git diff --exit-code` scoped to sync-docs' four migrated pages + `site/src/assets/` + the sync manifest yields no diff (scope excludes feature-006's generated reference pages).
- [ ] Tests are deterministic with clean setup/teardown; all feature-005 acceptance criteria covered.
- [ ] All §6 quality gates pass.
