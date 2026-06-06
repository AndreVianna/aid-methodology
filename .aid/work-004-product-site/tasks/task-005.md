# task-005: Pages/SEO config — `site`/`base`, sitemap, robots, CNAME, `.nvmrc`

**Type:** CONFIGURE

**Source:** feature-002-build-and-deploy → delivery-001

**Depends on:** task-003

**Scope:**
- Edit `site/astro.config.mjs` to set `site: 'https://aid.casuloailabs.com'` and `base: '/'` (D2), resolving feature-001's TODO markers; add the `@astrojs/sitemap` integration (D3) (order-independent; preserve the astro-mermaid/starlight ordering).
- Add `site/public/CNAME` (single line `aid.casuloailabs.com`, no scheme/trailing slash) (D4).
- Add `site/public/robots.txt` (Allow all + `Sitemap: https://aid.casuloailabs.com/sitemap-index.xml`).
- Add `site/.nvmrc` pinned to the Node major matching `release.yml`/`test.yml` (`20`); confirm it agrees with feature-001's `engines.node` (A2) — feature-001's value wins if they differ.
- Confirm `@astrojs/sitemap` is a pinned dep in `package.json` (add + relock if absent, A6).

**Acceptance Criteria:**
- [ ] `astro.config.mjs` sets `site` to the absolute origin and `base: '/'`; `@astrojs/sitemap` is in the integrations.
- [ ] Build emits `sitemap-index.xml` + `sitemap-0.xml` into `dist/`.
- [ ] `public/CNAME` contains exactly `aid.casuloailabs.com`; `public/robots.txt` references the sitemap index.
- [ ] `.nvmrc` Node major matches `engines.node` and `release.yml`/`test.yml`.
- [ ] Configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
