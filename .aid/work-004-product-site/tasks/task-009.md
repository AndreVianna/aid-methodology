# task-009: Foundation verification — standalone build, Lighthouse, WCAG-AA, Mermaid

**Type:** TEST

**Source:** feature-001-site-foundation, feature-002-build-and-deploy → delivery-001

**Depends on:** task-007

**Scope:**
- Verify a standalone `npm ci && npm run build` of `site/` succeeds with no errors and emits `dist/` with `CNAME`, `robots.txt`, and `sitemap-index.xml` + `sitemap-0.xml`.
- Verify every sidebar entry resolves to a shipped page (no broken nav/links) in the built output (AC3).
- Verify the three-pane layout, top nav, grouped collapsible sidebar, on-this-page TOC, breadcrumbs, and persistent GitHub + casuloailabs.com chrome render (AC3).
- Verify Pagefind search returns client-side results with no external SaaS request (AC8).
- Verify the `mermaid-smoke.md` diagram renders as SVG (not raw code) and is horizontally scrollable on narrow viewports (AC5 enabler).
- Run Lighthouse against the built site and confirm Performance / Accessibility / Best-Practices / SEO ≥ 90 (NFR).
- Verify color contrast in both dark and light modes meets WCAG 2.1 AA for gold accents and theme tokens (AC4/AC10).
- Verify responsive behavior: full three-pane on desktop/landscape-tablet; usable (drawer sidebar, readable text, scrollable diagrams/code) on portrait-tablet/mobile (AC10).

**Acceptance Criteria:**
- [ ] Standalone build passes with no errors; `dist/` contains `CNAME`, `robots.txt`, sitemap index + `sitemap-0.xml`.
- [ ] No broken internal nav/links in built output; all five sections + stubs resolve.
- [ ] Pagefind search works with zero external network requests.
- [ ] `mermaid-smoke` renders as SVG and is horizontally scrollable on narrow viewports.
- [ ] Lighthouse ≥ 90 on all four categories.
- [ ] Contrast verified AA in both `[data-theme]` scopes.
- [ ] Tests are deterministic with clean setup/teardown; all AC3/AC4/AC5/AC8/AC10 from features 001/002 are covered.
- [ ] All §6 quality gates pass.
