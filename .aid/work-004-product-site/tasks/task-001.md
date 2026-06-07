# task-001: Scaffold the Astro + Starlight project under `site/`

**Type:** CONFIGURE

**Source:** feature-001-site-foundation → delivery-001

**Depends on:** — (none)

**Scope:**
- Create the self-contained `site/` project tree at the repo root (sibling to `docs/`, `canonical/`, `profiles/`).
- Author `site/package.json` with pinned deps (D1): `astro`, `@astrojs/starlight`, `astro-mermaid`, `@fontsource/inter`, `@astrojs/sitemap`, and dev tooling; declare the `build` script (`astro build`) and `engines.node`.
- Generate and commit `site/package-lock.json` via `npm install` (reproducible builds, D1).
- Add `site/tsconfig.json` (extends `astro/tsconfigs/strict`) and `site/.gitignore` (`node_modules/`, `dist/`, `.astro/`).
- Add `site/public/favicon.svg` (casulo favicon).
- Do NOT author `astro.config.mjs`, theme CSS, content schema, or pages here (later tasks) — but the project must `npm install` cleanly.

**Acceptance Criteria:**
- [ ] `site/package.json` pins exact versions for astro, `@astrojs/starlight`, `astro-mermaid`, `@fontsource/inter`, `@astrojs/sitemap`; `engines.node` is set.
- [ ] `site/package-lock.json` is committed and `npm ci` succeeds against it from `site/`.
- [ ] `site/.gitignore` excludes `node_modules/`, `dist/`, `.astro/`.
- [ ] `site/tsconfig.json` extends `astro/tsconfigs/strict`.
- [ ] `astro-mermaid` plugin currency is confirmed against the registry (SPEC A1) and the selected version is a maintained, no-headless-browser option.
- [ ] Configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
