# task-017: Concepts & Reference IA — overview/CLI/artifacts pages + sidebar groups

**Type:** IMPLEMENT

**Source:** feature-006-concepts-and-reference → delivery-003

**Depends on:** task-016

**Scope:**
- Hand-author the net-new pages (provenance A): `concepts/overview.md` (Explanation entry), `reference/overview.md` (Information entry, replaces feature-001 stub), `reference/cli.mdx` (CLI command reference from `docs/install.md`, restructured, with `<Tabs>` for flag forms; links to `guides/installation` for prose, D3), and `reference/artifacts.md` (AID artifact set, cross-links repository-structure).
- Edit `site/astro.config.mjs` to replace ONLY the Concepts and Reference sidebar groups with explicit `items:` lists per the SPEC (turn `autogenerate` OFF for these two groups, D1); leave the other three groups untouched. Concepts: Overview → The methodology (M) → FAQ (M). Reference: Overview → CLI & subcommands → Skills → Agents → Knowledge Base → Settings keys → Artifacts → Repository structure → Glossary.
- These authored pages carry no `sourceDoc`/`generatedFrom` and are never touched by either generator.

**Acceptance Criteria:**
- [ ] `concepts/overview.md`, `reference/overview.md`, `reference/cli.mdx`, `reference/artifacts.md` exist with valid frontmatter.
- [ ] `astro.config.mjs` Concepts + Reference groups are explicit `items:` lists in the SPEC order; the other three sidebar groups are unchanged.
- [ ] Concepts shows Overview + methodology + FAQ; Reference shows CLI, settings, artifacts, repo-structure, glossary, and the generated Skills/Agents/KB pages (AC3).
- [ ] `reference/cli.mdx` links to `guides/installation` for long-form prose (no duplication, D3).
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
