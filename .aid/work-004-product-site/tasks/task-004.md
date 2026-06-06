# task-004: Content schema + stub pages behind every sidebar entry

**Type:** IMPLEMENT

**Source:** feature-001-site-foundation → delivery-001

**Depends on:** task-003

**Scope:**
- Author `site/src/content/config.ts`: declare the `docs` collection with `docsLoader()` + `docsSchema()`, extended with `sourceDoc?: z.string()` and `reportIssue: z.boolean().default(true)`.
- Ship a stub page behind every sidebar entry so the foundation builds standalone with no broken nav/links:
  - `src/content/docs/index.mdx` — Home (`template: splash`, minimal hero stub).
  - `src/content/docs/get-started/index.md`, `concepts/index.md`, `reference/index.md` — autogenerate stubs (one per growing group).
  - `src/content/docs/guides/installation.mdx`, `guides/pipeline.md`, `guides/maintainer.md` — explicit Guides slug stubs.
  - `src/pages/releases/changelog.astro` — Releases route stub for the sidebar `link: '/releases/changelog'`.
- Ship `src/content/docs/mermaid-smoke.md` with one small `mermaid` fence (AC5 pipeline proof).
- Stub pages set `title` + `description` only.

**Acceptance Criteria:**
- [ ] `config.ts` extends `docsSchema()` with `sourceDoc` (optional) and `reportIssue` (default `true`); build validation passes.
- [ ] Every sidebar entry (3 autogenerate dirs, 3 Guides slugs, Releases `link:`) resolves to a shipped stub page — no broken nav/links in a standalone build.
- [ ] `src/pages/releases/changelog.astro` serves `/releases/changelog`.
- [ ] `mermaid-smoke.md` exists with a valid `mermaid` fence.
- [ ] Unit/schema validation for the content collection passes; build passes; all existing checks still pass.
- [ ] All §6 quality gates pass.
