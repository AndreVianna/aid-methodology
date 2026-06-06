# task-003: `astro.config.mjs` — Starlight config, sidebar contract, integrations, components-map owner

**Type:** CONFIGURE

**Source:** feature-001-site-foundation → delivery-001

**Depends on:** task-002

**Scope:**
- Author `site/astro.config.mjs`: Starlight integration with `title` ("AID — Agentic Iterative Development"), `social` (GitHub + casuloailabs.com), `customCss` (`@fontsource/inter` + `./src/styles/casulo.css`), `favicon`, `tableOfContents` (`minHeadingLevel: 2`, `maxHeadingLevel: 3`).
- Configure the reconciled sidebar contract (D8): `autogenerate` for Get Started / Concepts / Reference; explicit `slug:` items for Guides (`guides/installation`, `guides/pipeline`, `guides/maintainer`); Releases as `{ label: 'Changelog', link: '/releases/changelog' }`.
- Add the `astro-mermaid` integration BEFORE Starlight in the integrations array; configure Mermaid `theme: 'dark'` / themeVariables to casulo tokens (legible on dark base).
- Own and ship the `components:` map: leave it EMPTY but documented, with reserved slots for `Banner` (feature-009), `Footer` (feature-010), and the version-badge slot (feature-008) so siblings only add a key.
- Leave `site`/`base` and the sitemap integration as TODO markers (owned by feature-002 / task-005).
- Add a footer back-link override to casuloailabs.com if `social:` placement is insufficient (persistent GitHub + casuloailabs.com chrome on every page).

**Acceptance Criteria:**
- [ ] Sidebar renders the five sections exactly per D8 (autogenerate for 3 groups, explicit Guides slugs, Releases `link:`).
- [ ] `astro-mermaid` precedes `starlight()` in the integrations array; Mermaid uses a dark themed palette.
- [ ] `customCss` registers Inter + `casulo.css`; `tableOfContents` is `{2,3}`; `social` exposes GitHub + casuloailabs.com.
- [ ] The `components:` map exists and is empty with documented reserved `Banner`/`Footer`/version slots.
- [ ] `site`/`base` and sitemap are present only as TODO markers (not set here).
- [ ] Configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
