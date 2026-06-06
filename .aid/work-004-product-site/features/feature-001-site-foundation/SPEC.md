# Site Foundation: Shell, Navigation, Search & Theming

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR1, FR2, FR13), §6, §7, §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR1 Site shell & navigation, FR2 Search, FR13 Brand theming)
- REQUIREMENTS.md §6 (Non-Functional Requirements), §7 (Constraints), §10 (Priority — Must)

## Description

Stand up the Astro Starlight documentation project that every other feature builds on. It
provides the site's chrome and look-and-feel: the three-pane developer-docs layout (top nav
with the five section tabs — Get Started, Guides, Concepts, Reference, Releases; a grouped,
collapsible left sidebar; an on-this-page TOC; breadcrumbs), persistent header/footer links to
GitHub and casuloailabs.com, and site-wide client-side search (Pagefind, which ships with
Starlight — offline-capable, no external SaaS). The site is themed to the casuloailabs.com brand
so AID reads as product documentation within the Casulo AI Labs family: dark base `#0a0e1a`,
gold accent `#d4a853`, Inter typography, dark by default with a working light-mode toggle, both
modes WCAG-AA contrast-verified. The layout is optimized for desktop and landscape tablet and
remains usable (readable, navigable, with scrollable diagrams and code) on portrait tablet and
mobile. Mermaid diagram rendering is enabled here so content features can use it. This feature
delivers the shell with placeholder/empty section pages; real content arrives in later features.

## User Stories

- As an evaluator, I want a polished, branded, professionally laid-out site so that I get a
  credible first impression of AID's maturity within seconds.
- As an evaluator, I want a site-wide search box so that I can jump straight to what I need
  without reading linearly.
- As a returning user, I want consistent navigation (top tabs, left sidebar, TOC, breadcrumbs)
  so that I can reliably relocate reference material.
- As a returning user, I want a light-mode toggle so that I can read comfortably in any
  environment, with the casulo brand preserved in both modes.
- As a maintainer, I want a single CSS-variable theme mapped to the casulo tokens so that
  brand changes are made in one place without per-page overrides.

## Priority

Must

## Acceptance Criteria

- [ ] Given the project repo, when the site is built and served, then it renders the three-pane
  layout with top nav, grouped collapsible left sidebar, on-this-page TOC, and breadcrumbs (AC3).
- [ ] Given any page, when it is viewed, then the header/footer expose persistent links to
  GitHub and casuloailabs.com (AC3).
- [ ] Given the rendered site, when inspected against the brand reference, then it uses the
  casulo palette (dark `#0a0e1a`, gold `#d4a853`, Inter) and loads dark by default with a working
  light toggle, both modes themed (AC4).
- [ ] Given gold `#d4a853` and the theme tokens, when contrast is measured in both modes, then
  they meet WCAG 2.1 AA (AC4, AC10).
- [ ] Given a search query, when entered in the search box, then relevant client-side results
  are returned with no external SaaS request (AC8).
- [ ] Given a page containing a Mermaid code block, when the page is built and viewed, then the
  diagram renders correctly (AC5 enabler).
- [ ] Given a desktop or landscape-tablet viewport, when the site is viewed, then the full
  three-pane layout is shown; given a portrait-tablet or mobile viewport, then the site remains
  usable (text readable, sidebars collapse to a drawer, diagrams/code scroll) (AC10).

---

## Technical Specification

### Overview & Approach

This feature stands up the **Astro + Starlight** documentation project that every other
feature in `work-004-product-site` extends. It is the project skeleton: the Node/Astro
toolchain, the Starlight configuration, the casulo theme layer, the navigation contract
(top-nav tabs + grouped sidebar), build-time search (Pagefind) and Mermaid rendering, and a
concrete `site/` directory tree with **placeholder pages** for the five top sections plus the
home page. No real content, deploy workflow, version injection, or releases binding is built
here — those are owned by sibling features (see *Feature Boundaries* below) and only stubbed.

The project is **self-contained under `site/`** at the repo root, a sibling to `docs/`,
`.aid/`, `canonical/`, `profiles/`. It does not touch the existing AID toolchain (Python
renderer, `bin/aid`, `canonical/`); per the KB (`infrastructure.md`) this repo has no
application runtime, so the site is the first Node/Astro artifact in the tree and lives in its
own subtree to avoid collision. The repo's ASCII-only guard (user memory, CI-enforced for
shipped installer/CLI scripts) does **not** apply to `site/` content (REQUIREMENTS §7).

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Astro + Starlight (latest stable), pinned via `package.json` + `package-lock.json` | Per agreed baseline & REQUIREMENTS §7 (constraint: Astro Starlight); reproducible builds (NFR maintainability). |
| D2 | Project root at `site/`, self-contained | Keeps Node deps + build out of the methodology toolchain; one tree to deploy; matches baseline. |
| D3 | Theme via custom CSS overriding Starlight CSS custom properties (`site/src/styles/casulo.css`), not a forked theme | Single-source brand tokens (User Story: "single CSS-variable theme … one place"); Starlight is built on CSS custom properties so casulo tokens map 1:1 (`casulo-brand.md`). |
| D4 | Dark default + Starlight's built-in light/dark toggle, both themed | NFR theme; AC4. Starlight ships the toggle; we supply tokens for both `[data-theme]` scopes. |
| D5 | Pagefind (Starlight built-in) for search | NFR/AC8: offline, client-side, no SaaS; zero extra integration. |
| D6 | Mermaid rendered via the `astro-mermaid` integration (client-side runtime rendering, no Playwright/build-time browser) | Baseline: a concrete, maintained plugin avoiding a headless browser. `astro-mermaid` emits `<pre class="mermaid">` at build and ships Mermaid's JS, which renders the SVG **client-side in the browser at runtime** — so no Playwright/build-time browser is needed (unlike `rehype-mermaid`'s SVG strategies, which require Playwright). **Note:** because rendering is client-side, Mermaid diagrams require JavaScript on the pages that contain them. This is the one place JS is shipped to the browser; it interacts with the minimal-JS / Lighthouse-≥90 NFR, so diagram JS loads **only on pages that use a Mermaid block** (non-diagram pages stay JS-free). See *Mermaid* below for the contract this must satisfy. |
| D7 | Content as a Starlight `docs` content collection under `site/src/content/docs/`, MD/MDX + YAML frontmatter | Baseline & REQUIREMENTS §8: Starlight requires `title` frontmatter and a content dir. |
| D8 | Explicit hand-authored sidebar config (not `autogenerate` initially) | Deterministic group order/labels for the five sections; placeholder pages exist before content migration (feature-005). Groups may switch to `autogenerate` per-section later. |
| D9 | Inter via `@fontsource/inter` (self-hosted), not a Google Fonts `<link>` | Performance (Lighthouse ≥ 90), privacy (no third-party request, aligns with "no analytics/SaaS"), offline-capable. |

### Layers & Components

The `site/` project has four layers:

1. **Toolchain / config layer** — `site/package.json`, `site/package-lock.json`,
   `site/astro.config.mjs`, `site/tsconfig.json`, `site/.gitignore`. Declares pinned Astro,
   `@astrojs/starlight`, `astro-mermaid`, `@fontsource/inter`, and dev tooling. Defines the
   Starlight integration and its options (title, social, sidebar, customCss, favicon, logo,
   `defaultLocale`, `tableOfContents`). `site` / `base` for Pages live here but are owned by
   feature-002 (left at sensible defaults / TODO marker here).
2. **Content-schema layer** — `site/src/content/config.ts` declares the `docs` collection
   using Starlight's `docsSchema()`, extended with the optional project fields (see *Data
   Model / Content Schema*).
3. **Theme layer** — `site/src/styles/casulo.css` (token overrides + component polish) plus
   font import. This is the brand single-source.
4. **Content / page layer** — `site/src/content/docs/**` MD/MDX pages. This feature ships the
   home page + one placeholder index page per top section. Real pages arrive in features
   003–007.

Optional component override slots (Starlight component overrides via `components:` in config)
are **reserved but not implemented here** — the announcement banner (feature-009 / FR16),
per-page "Report an issue" (feature-006 / FR14), and version badge (feature-008 / FR15) will
register overrides for `Banner`, `PageFrame`/`Footer`, and `Hero`/content respectively. This
feature leaves `components:` empty and documents the slots so siblings plug in without
restructuring.

### Data Model / Content Schema

**No database — static site.** The "data model" is the Starlight content-collection schema.

`site/src/content/config.ts`:

```ts
import { defineCollection } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';
import { z } from 'astro:content';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        // Project-specific optional frontmatter (consumed by later features):
        sourceDoc: z.string().optional(),   // provenance: e.g. "docs/install.md" (feature-005)
        reportIssue: z.boolean().default(true), // toggle per-page "Report an issue" (feature-006)
      }),
    }),
  }),
};
```

Per-page frontmatter fields available (Starlight built-ins used by this feature):
`title` (required), `description` (SEO/OG), `template` (`doc` | `splash` — splash for Home),
`hero` (Home landing), `sidebar` (order/label/badge), `tableOfContents`, `lastUpdated`,
`prev`/`next`, `head` (per-page OG/meta). Placeholder pages set `title` + `description` only.

### Navigation Structure (top-nav tabs + sidebar)

Starlight renders **top-level sidebar groups as the section structure**; the five tabs
(REQUIREMENTS FR1, AC3) are modeled as the five top-level sidebar groups, with Home as the
splash landing at `/`. Sidebar configured explicitly in `astro.config.mjs`:

```js
sidebar: [
  { label: 'Get Started', items: [
      { label: 'Overview', slug: 'get-started/overview' } ] },     // feature-003
  { label: 'Guides', items: [
      { label: 'Installation', slug: 'guides/installation' } ] },   // feature-004/003
  { label: 'Concepts', items: [
      { label: 'The methodology', slug: 'concepts/methodology' } ] }, // feature-005
  { label: 'Reference', items: [
      { label: 'Overview', slug: 'reference/overview' } ] },        // feature-007
  { label: 'Releases', items: [
      { label: 'Changelog', slug: 'releases/changelog' } ] },       // feature-008
],
```

Each group points at a placeholder page shipped by this feature; later features deepen the
items. Breadcrumbs, the on-this-page TOC (`tableOfContents: { minHeadingLevel: 2,
maxHeadingLevel: 3 }`), grouped collapsible sidebar (drawer on mobile), and the global
search box are all **provided by Starlight's default layout** once the project is configured —
this satisfies AC3 / FR1 without custom layout code.

Header/footer links (AC3, FR1): GitHub + casuloailabs.com.

```js
social: [
  { icon: 'github', label: 'GitHub', href: 'https://github.com/AndreVianna/aid-methodology' },
  { icon: 'external', label: 'Casulo AI Labs', href: 'https://casuloailabs.com' },
],
```

A footer back-link to `casuloailabs.com` is added via a small footer override or the
`Footer` component slot if `social:` placement is insufficient; the GitHub + casuloailabs.com
links must be present in persistent chrome on every page.

### Theme Layer (casulo tokens → Starlight CSS variables)

`site/src/styles/casulo.css` is registered via `customCss: ['@fontsource/inter',
'./src/styles/casulo.css']` (or font imported inside the CSS). It overrides Starlight's
documented CSS custom properties. Token mapping (from `casulo-brand.md`):

```css
:root {
  /* casulo brand tokens (single source) */
  --casulo-bg-primary: #0a0e1a;
  --casulo-bg-secondary: #111827;
  --casulo-bg-card: #1a2035;
  --casulo-bg-card-hover: #212b45;
  --casulo-text-primary: #f1f5f9;
  --casulo-text-secondary: #94a3b8;
  --casulo-text-muted: #64748b;
  --casulo-accent: #d4a853;
  --casulo-accent-hover: #e6bc6a;
  --casulo-accent-glow: rgba(212,168,83,0.15);
  --casulo-border: rgba(148,163,184,0.1);
  --casulo-border-accent: rgba(212,168,83,0.3);
  --casulo-radius: 12px;
  --casulo-radius-sm: 8px;
}

/* DARK (default) — Starlight applies dark on bare `:root`, so the dark
   tokens are the default scope (Starlight does NOT emit `[data-theme='dark']`). */
:root {
  --sl-color-accent: var(--casulo-accent);
  --sl-color-accent-high: var(--casulo-accent-hover);
  --sl-color-accent-low: var(--casulo-accent-glow);
  --sl-color-text: var(--casulo-text-primary);
  --sl-color-text-accent: var(--casulo-accent);
  --sl-color-gray-1: var(--casulo-text-primary);
  --sl-color-gray-2: var(--casulo-text-secondary);
  --sl-color-gray-3: var(--casulo-text-muted);
  --sl-color-bg: var(--casulo-bg-primary);
  --sl-color-bg-nav: var(--casulo-bg-secondary);
  --sl-color-bg-sidebar: var(--casulo-bg-secondary);
  --sl-color-bg-inline-code: var(--casulo-bg-card);
  --sl-color-hairline: var(--casulo-border);
  --sl-color-hairline-shade: var(--casulo-border-accent);
}

/* LIGHT — casulo-branded light variant (gold accent retained, AA-verified).
   Starlight sets `[data-theme='light']` only for the light scope. */
:root[data-theme='light'] {
  --sl-color-accent: #8a6418;        /* darkened gold, 5.36:1 on white — passes AA */
  --sl-color-accent-high: #6f5013;   /* darker still for hover/high-emphasis */
  --sl-color-text-accent: #8a6418;
  /* light surfaces kept warm-neutral; tokens chosen to meet AA */
}

/* corner radius + font */
:root { --sl-text-h1: 2.25rem; }
:root, body { font-family: 'Inter', var(--sl-font-system); }
```

Globals: favicon `site/public/favicon.svg`, site title **"AID — Agentic Iterative
Development"** (`title:` in config), `logo:` optional. Inter weights 400/500/600/700/800
(`@fontsource/inter`).

**Accessibility / contrast (AC4, AC10, NFR a11y):** gold `#d4a853` on dark `#0a0e1a` is used
for accents/links and measures **8.73:1 (>7:1, exceeds AA — meets AAA for normal text)** on the
dark base; in **light** mode the raw `#d4a853` is only 2.2:1 on white (well below AA), so light mode
uses a darkened gold `#8a6418` (**5.36:1 on white — passes AA**) for text-weight accents while
keeping the brand hue. The brighter brand gold `#d4a853` is therefore restricted to dark mode and
to large-text / non-text UI affordances; any light-mode text-weight accent uses `#8a6418`. Both
modes must be contrast-checked as an acceptance step (semantic headings + keyboard nav come from
Starlight defaults).

### UI Specs

- **Layout:** Starlight's three-pane developer-docs layout (top nav bar with section tabs +
  search + theme toggle + social links; grouped collapsible left sidebar; center content with
  breadcrumbs + body; right "On this page" TOC). Provided by the default `doc` template; no
  custom layout component required for the shell (AC3).
- **Home (`/`):** `template: splash` with a `hero` (title, tagline, install one-liner
  placeholder, CTA buttons to Get Started + GitHub). This feature ships a minimal hero; FR3 /
  feature-003 enriches it. The pipeline diagram (Mermaid) is wired but the diagram content is
  added by content features.
- **Responsive (NFR, AC10):** desktop + landscape-tablet show the full three-pane layout;
  Starlight collapses the sidebar to a drawer and hides/relocates the TOC on narrow viewports
  by default. Wide Mermaid diagrams and code blocks must be **horizontally scrollable** (not
  reflowed) — ensure `overflow-x: auto` on `.mermaid`/diagram wrappers and `pre` (Starlight
  defaults handle `pre`; verify the Mermaid wrapper).
- **Theme toggle (AC4):** Starlight's built-in switch; dark is the default (`<html>` boots in
  dark). Verified that both `[data-theme]` scopes are themed.

### Build-time Concerns

- **Search — Pagefind (AC8, FR2):** Starlight runs Pagefind automatically on `astro build`,
  emitting the static index into the output; the search box is in the default header. No
  config beyond Starlight defaults; **must be verified to issue no external network request**.
- **Mermaid (AC5 enabler, FR11):** the `astro-mermaid` integration is added to
  `astro.config.mjs` *before* Starlight in the integrations array (it transforms fenced
  ` ```mermaid ` blocks). Contract it must satisfy: (1) a page containing a Mermaid code
  block renders a diagram on `astro build` + serve; (2) no headless browser is required at
  build time (D6); (3) the rendered diagram is horizontally scrollable on narrow viewports;
  (4) diagram colors are legible against the casulo dark base (configure Mermaid `theme:
  'dark'` / themeVariables to casulo tokens). This feature ships **one** smoke-test page with
  a small Mermaid block to prove the pipeline; the seven Mermaid diagrams in
  `docs/aid-methodology.md` are migrated by feature-005.
- **SEO (NFR):** Starlight emits per-page `<title>`/meta from frontmatter; add
  `@astrojs/sitemap` (or Starlight's site config) for `sitemap.xml` and a
  `site/public/robots.txt`. OG/social cards may be deferred to a content/polish feature but
  the hooks (`head` frontmatter) exist here.
- **Reproducible builds:** all deps pinned; `package-lock.json` committed; CI uses
  `npm ci` (workflow owned by feature-002).

### File / Directory Tree (`site/`)

```
site/
├── package.json                 # pinned: astro, @astrojs/starlight, astro-mermaid,
│                                #         @fontsource/inter, @astrojs/sitemap
├── package-lock.json            # committed lockfile (reproducible builds)
├── astro.config.mjs             # Astro + Starlight config: title, social, sidebar,
│                                #   customCss, favicon, integrations [astro-mermaid, starlight]
├── tsconfig.json                # extends astro/tsconfigs/strict
├── .gitignore                   # node_modules/, dist/, .astro/
├── public/
│   ├── favicon.svg              # casulo favicon
│   ├── robots.txt               # SEO
│   └── CNAME                    # OWNED BY feature-002 (placeholder/absent here)
└── src/
    ├── content/
    │   ├── config.ts            # docs collection + docsSchema extend
    │   └── docs/
    │       ├── index.mdx                       # Home (template: splash, hero)  [FR3 stub]
    │       ├── get-started/overview.md         # placeholder  [feature-003]
    │       ├── guides/installation.md          # placeholder  [feature-004]
    │       ├── concepts/methodology.md         # placeholder  [feature-005]
    │       ├── reference/overview.md           # placeholder  [feature-007]
    │       ├── releases/changelog.md           # placeholder  [feature-008]
    │       └── mermaid-smoke.md                # Mermaid pipeline smoke test (AC5)
    └── styles/
        └── casulo.css           # brand token → Starlight CSS-var overrides (single source)
```

(`node_modules/`, `dist/`, `.astro/` are generated and git-ignored.)

### Feature Boundaries (where siblings plug in)

| Concern | Owner | This feature ships |
|---------|-------|--------------------|
| GitHub Actions build + deploy, `CNAME`, custom domain, `site`/`base` | feature-002 | config TODO markers only |
| Home value-prop / CTAs depth (FR3) | feature-003 | minimal `index.mdx` hero stub |
| Install guide content + per-tool tabs (FR4/FR5) | feature-003/004 | placeholder pages |
| Migration of `docs/*.md` + Mermaid diagrams (FR11) | feature-005 | empty section pages + Mermaid pipeline proven |
| Concepts / Reference content (FR8/FR9) | feature-005/007 | placeholder pages |
| Feedback / "Report an issue" (FR14) | feature-006 | `reportIssue` schema field + reserved `components:` slot |
| Releases binding (FR10), version injection (FR15), banner (FR16) | feature-008/009 | `releases/changelog.md` stub + reserved `Banner` slot |

### Acceptance Criteria Coverage

| Scaffold AC | How this feature satisfies it |
|-------------|-------------------------------|
| AC3 — three-pane layout, top nav, grouped sidebar, TOC, breadcrumbs | Starlight default `doc` template + explicit `sidebar` config + `tableOfContents`. |
| AC3 — header/footer GitHub + casuloailabs.com | `social:` config + footer back-link override. |
| AC4 — casulo palette, Inter, dark default + light toggle | `casulo.css` token overrides for both `[data-theme]` scopes; `@fontsource/inter`; Starlight toggle. |
| AC4/AC10 — gold + tokens WCAG AA both modes | dark uses `#d4a853`; light uses darkened gold; contrast verified as an acceptance step. |
| AC8 — search, no SaaS | Pagefind (Starlight built-in), build-time static index, no external request. |
| AC5 enabler — Mermaid renders | `astro-mermaid` integration + `mermaid-smoke.md` proof page. |
| AC10 — responsive desktop/tablet/mobile | Starlight responsive defaults (sidebar drawer); scrollable diagrams/code verified. |

### Assumptions & Open Questions

- **A1 (Mermaid plugin):** `astro-mermaid` is selected as a concrete, maintained,
  no-headless-browser option per the baseline. If, during implementation, its Starlight
  compatibility or maintenance status proves inadequate, the fallback is
  `rehype-mermaid` with the `inline-svg` strategy (note: SVG strategies pull Playwright,
  conflicting with D6) or a remark-based pre-render. Flagging for spot-check — the baseline
  asked to "choose and name a concrete, maintained one," and plugin currency should be
  confirmed against latest registry state at build time.
- **A2 (light-mode gold values):** the darkened-gold light-mode value (`#8a6418`, 5.36:1 on
  white) is proposed to meet AA on light surfaces while preserving the brand hue; exact values are
  subject to the contrast-verification acceptance step and may be tuned. `casulo-brand.md`
  defines only the dark palette, so the light variant is a grounded inference, not a given.
- **A3 (Home as splash vs doc):** Home uses `template: splash`; if feature-003 prefers the
  three-pane layout for Home, the template flips with no structural impact.
- **A4 (sidebar tabs vs groups):** Starlight does not render top-level groups as a separate
  horizontal "tab bar" by default the way Mintlify does; the five sections render as
  top-level sidebar groups (satisfying "five section nav" / AC3). If a literal horizontal
  top-tab bar is required for visual parity, a Starlight community plugin (e.g.
  `starlight-sidebar-topics`) would be added — flagged as a visual-parity decision for the
  AC11 human gate, not a functional blocker.
