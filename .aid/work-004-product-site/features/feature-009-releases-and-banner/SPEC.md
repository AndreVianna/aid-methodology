# Releases Page & Announcement Banner

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature, split from the combined feature-008-release-integration per user request: owns the Releases page (FR10) and the dismissible release-announcement banner (FR16). The always-current version binding (FR15) moved to feature-008-version-injection. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR10, FR16 · §4 Scope · §6 NFRs · §7 Constraints (live-project bindings) · §8 Assumptions

## Description

The release-visible surface of the live-project binding. At build time this feature consumes the
release data fetched by feature-002 (the GitHub Releases API) and produces
two outputs: (1) a **Releases page** auto-populated from the GitHub Releases API with each
release's notes, date, and per-release **offline bundle asset link(s)**, rebuilt automatically on
the `release: published` event so it stays current hands-free; and (2) a **dismissible
release-announcement banner** surfacing the latest release (e.g. "AID vX.Y.Z is out") and linking
to the Releases page, with the dismissal persisted for the visitor. Both are read at build time —
no runtime backend — and are decoupled from `release.yml`, which is never modified. Per §10 the
Releases page is **Should** and the announcement banner is **Could**, so this feature is a
coherent post-MVP slice that can follow the first deploy.

## User Stories

- As a returning user, I want the Releases page to reflect the latest GitHub Releases with offline-tarball links so that I can see what changed and download an air-gapped build.
- As a new adopter in an air-gapped environment, I want each release's offline-tarball download link so that I can fetch the exact version I need.
- As an evaluator, I want a clear "latest release" banner so that I can immediately see the project is active and current.
- As an adopter, I want the announcement banner to be dismissible and stay dismissed so that it doesn't nag me on every visit.
- As a maintainer, I want publishing a GitHub Release to refresh the Releases page and banner automatically so that I never hand-edit the site and never modify `release.yml`.

## Priority

Should

> Slice priorities (mirroring §10): FR10 Releases page = **Should**; FR16 announcement banner = **Could**.

## Acceptance Criteria

- [ ] Given a build, when the Releases page renders, then it reflects the GitHub Releases API with per-release offline bundle asset link(s). (AC9)
- [ ] Given the latest release data, when any page renders, then a dismissible banner shows the latest release and links to the Releases page, and dismissal persists for the visitor. (AC14)
- [ ] Given a published GitHub Release, when the `release: published` rebuild runs, then the Releases page and the banner update with no manual steps and no change to `release.yml`. (AC15 — releases-page/banner portion)
- [ ] Given the binding, when release data is read, then it is read at build time with no runtime backend call. (§4, §7)

---

## Technical Specification

### Overview & Approach

This feature owns the two **release-visible surfaces** of the live-project binding: the
**Releases page** (`releases/changelog`, FR10 / AC9) and the **dismissible announcement
banner** (FR16 / AC14). Both are pure consumers of feature-002's build-time data-fetch
contract — they read the **typed accessor `site/src/lib/release-data.ts`** and never re-fetch
the GitHub Releases API, never read `process.env`, and never touch `release.yml`. Refresh on a
new release is hands-free: feature-002's `docs.yml` rebuilds on `release: published`, the
fetcher repopulates `AID_RELEASES_JSON` / `AID_LATEST_RELEASE_JSON`, and both surfaces
re-render with the new data baked into static HTML (AC15 — releases/banner portion).

This feature **extends** the `site/` Astro + Starlight project (feature-001) and does not
contradict its anchors: it owns the `releases/changelog` route (replacing feature-001's
stub `src/pages/releases/changelog.astro`) and registers the **`Banner`** Starlight
component-override slot that feature-001 reserved for FR16. It adds no theme tokens, no
navigation, and no build/deploy config.

> **Ownership correction (per feature-001 D8 sidebar comment):** feature-001's
> `astro.config.mjs` sidebar attributes `releases/changelog` to feature-008. That is a
> scaffold-era label from before the FR10/FR15/FR16 split — **feature-009 (this feature) owns
> the releases page**; feature-008 owns only the version binding.
>
> **Sidebar = `link:`, not `slug:` (settled):** because the Releases page is an Astro route
> (`src/pages/releases/changelog.astro`) and **not** a content-collection doc, feature-001's
> sidebar references it as a route link, not a content `slug:`. feature-001 is amended to use
> `{ label: 'Changelog', link: '/releases/changelog' }` and ships a stub
> `src/pages/releases/changelog.astro`. **feature-009 supplies the real page replacing
> feature-001's stub**; no sidebar edit is owned by this feature (the `link:` target is
> unchanged).

The only client-side JavaScript this feature ships is the **banner dismissal** (a small inline
script with `localStorage`); the Releases page is fully static / prerendered with no client JS
(honoring the NFR minimal-JS / Lighthouse ≥ 90 bar).

### Dependency on feature-002 (CONSUMED contract — not redefined)

This feature consumes feature-002's accessor exactly as published; it adds no new env vars and
no new fetch logic. The two accessors used:

> **`getAllReleases(): Release[]`** — all releases, newest-first, each projected to
> `{ tag, name, url, publishedAt, body, assets: [{ name, url }] }`; `[]` when no release data
> (local dev / API failure / empty fetch). → drives the **Releases page**.
>
> **`getLatestRelease(): Release | null`** — the latest release projected to
> `{ tag, name, url, publishedAt, assets: [{ name, url }] }`; `null` when unavailable.
> → drives the **banner**.

`Release` / `ReleaseAsset` are feature-002's exported interfaces. Both accessors run at
**build time in Node** (SSG) and degrade gracefully to empty — this feature renders an
empty-state for the page and renders **no banner** when the latest release is `null`, so the
build never fails for lack of release data. This is the only coupling; the sole shared file is
the imported accessor and there is **no runtime call**.

> **Assets-field note (spot-check A1):** feature-002's contract table lists the projected
> asset shape as `{ name, url }`. The provider intent (D7 / contract notes) is that
> `assets[].url` is the release asset `browser_download_url`. A `size` field is *not* in
> feature-002's guaranteed projection, so this feature renders **name + download link only**
> and does not display byte sizes (see Assumptions A1).

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | The Releases page is a **single dynamic `.astro` page** at `site/src/pages/releases/changelog.astro` that calls `getAllReleases()` and maps over the array, rendering one section per release. **Not** a content-collection file (no per-release MD), and **not** a `getStaticPaths` multi-route split. | One auto-populated page from one build-time array is the simplest shape that satisfies "auto-pulled from the GitHub Releases API." A custom Astro page can call the Node accessor directly in its frontmatter; a Markdown content file cannot. A single page (vs one route per release) matches "a changelog" and keeps the route stable. This **replaces** feature-001's stub `src/pages/releases/changelog.astro`. |
| D2 | The page lives under `site/src/pages/` (Astro file-based routing), **not** `src/content/docs/`, and wraps its content in Starlight's **`<StarlightPage>`** route-middleware component so it keeps the three-pane shell (nav, sidebar, TOC, breadcrumbs, theme). | Custom logic (mapping the accessor array) requires an `.astro` page, which `src/content/docs/` does not allow. `<StarlightPage>` (`@astrojs/starlight/components`) lets a standalone Astro page render *inside* the Starlight frame so the page is not an unstyled orphan (feature-001 anchor: "Custom Astro pages allowed under `site/src/pages/`"). |
| D3 | Each release's markdown **`body`** is rendered to HTML at build time via a **markdown renderer** — Astro's built-in `markdown.render` is not exposed to pages, so use a small dependency-light renderer (`marked`) piped through a sanitizer (`sanitize-html`) before `set:html`. | GitHub release `body` is GitHub-Flavored Markdown; it must render as formatted notes, not raw text. Because the source is the project's own releases (semi-trusted) but is injected as HTML, it is **sanitized** before `set:html` to avoid shipping unsanitized HTML (defense-in-depth; safe-by-default). `sanitize-html`'s **bare defaults drop `h1`/`h2`/`img` and GFM task-list `<input>` checkboxes**, so an explicit **`allowedTags`/`allowedAttributes` allowlist** is supplied that re-admits headings (`h1`–`h6`), `img` (`src`/`alt`/`title`), links, lists, code/pre, tables, and task-list checkboxes — so notes render fully. `marked.parse` is called with `{ async: false }` so it returns a `string` synchronously (no `as string` cast). Both deps are pinned and small. (Fallback in A2 if adding deps is undesired.) |
| D4 | **Offline-bundle asset links** are produced by filtering `release.assets` to names matching the offline-tarball pattern **`/^aid-.*\.tar\.gz$/`** (e.g. `aid-claude-code-v1.0.0.tar.gz`), rendering each as a download link to `asset.url`. Releases with no matching asset render the notes but **omit** the download block. | FR10 / AC9 require **per-release offline bundle asset link(s)**; the `aid-*.tar.gz` pattern is the offline bundle naming used across `docs/install.md` and feature-008 A4 (`aid-<tool>-v<version>.tar.gz`). Filtering keeps source tarballs / checksums out of the download list. |
| D5 | **Empty-state:** when `getAllReleases()` returns `[]`, the page renders a friendly empty-state ("Releases will appear here once the first GitHub Release is published") plus a link to the GitHub releases page, instead of an empty list. | Graceful degradation (feature-002 ships `[]` in local dev / on API failure); the page must still build and read sensibly (AC9 + §4/§7 build-time, no runtime backend). |
| D6 | The **banner** is a Starlight component override `site/src/components/Banner.astro` registered via `components: { Banner: './src/components/Banner.astro' }` in `astro.config.mjs`. It calls `getLatestRelease()`; if `null` it renders nothing. It also **suppresses itself on `/releases/changelog`** (`Astro.url.pathname`) since the "see what's new" link would target the current page. | feature-001 reserved the `Banner` slot for FR16; an override renders on **every page** (the announcement requirement) via Starlight's layout, with no per-page wiring. Self-suppression on the Releases page avoids a link-to-self. |
| D7 | Banner **dismissal** persists via `localStorage` **keyed by the release tag** (`aid-banner-dismissed=<tag>`). The banner is server-rendered visible with the current tag embedded as a `data-tag` attribute; a tiny inline `<script>` hides it on load **iff** the stored value equals the current tag. A new release (new tag) → stored value no longer matches → banner re-shows. | AC14 "dismissible … dismissal persists" **and** "a new release re-shows." Keying by tag (not a boolean) is what makes a new release re-surface automatically. Inline script (no framework, no hydration) keeps it to the minimal client-JS this feature is allowed (AC14 note: "the small bit of client JS"). |
| D8 | The banner is **prerendered visible** (not hidden-by-default-then-shown); the dismissal script only *hides*. No flash of a banner the user already dismissed is avoided by running the hide-check in a **blocking inline `<script>` in the banner markup** (executes before paint of the banner region). | Avoids FOUC of a re-appearing banner; keeps the page SSR-correct with JS disabled (banner simply stays visible, still dismissable-less but functional — links work). Progressive enhancement: with JS off the banner shows and links to the page (acceptable degraded state). |
| D9 | The banner copy is **"AID v{tag} is out"** linking to the releases page (`/releases/changelog`), built from `getLatestRelease().tag`/`.name`. The tag is normalized for display (ensure a single leading `v`). | FR16 / AC14 example copy; the link target is this feature's own page (D1). |

### The Releases Page — `site/src/pages/releases/changelog.astro`

A single Astro page; frontmatter (build-time Node) calls the accessor and renders the markdown
`body` safely, then the template maps over releases. Shape:

```astro
---
// site/src/pages/releases/changelog.astro — Releases/changelog (FR10, AC9).
// Build-time only: reads feature-002's accessor (no fetch, no runtime backend).
import { StarlightPage } from '@astrojs/starlight/components';
import { getAllReleases, type Release, type ReleaseAsset } from '../../lib/release-data';
import { marked } from 'marked';
import sanitizeHtml from 'sanitize-html';

const releases: Release[] = getAllReleases();

// D4 — offline bundle assets only (aid-*.tar.gz), e.g. aid-claude-code-v1.0.0.tar.gz
const OFFLINE_RE = /^aid-.*\.tar\.gz$/;
const offlineAssets = (r: Release): ReleaseAsset[] =>
  (r.assets ?? []).filter((a) => OFFLINE_RE.test(a.name));

// D3 — render GitHub-Flavored Markdown body → sanitized HTML at build time.
// Allowlist re-admits headings, images, links, lists, code/pre and GFM task-list
// checkboxes — sanitize-html's bare defaults drop h1/h2/img and the <input> checkboxes.
const ALLOWED_TAGS = [
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'p', 'a', 'ul', 'ol', 'li', 'blockquote', 'hr', 'br',
  'strong', 'em', 'del', 'code', 'pre',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'img', 'input',
];
const ALLOWED_ATTRS = {
  a: ['href', 'name', 'target', 'rel'],
  img: ['src', 'alt', 'title'],
  // GFM task-list checkboxes render as <input type="checkbox" disabled checked>
  input: ['type', 'checked', 'disabled'],
};
const renderBody = (body?: string): string =>
  body
    ? sanitizeHtml(marked.parse(body, { async: false }), {
        allowedTags: ALLOWED_TAGS,
        allowedAttributes: ALLOWED_ATTRS,
      })
    : '';

// D-fix — guard against empty/null publishedAt (draft releases) → omit date, no "Invalid Date".
const fmtDate = (iso?: string): string =>
  iso
    ? new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    : '';
---
<StarlightPage frontmatter={{ title: 'Releases', description: 'AID release notes and offline bundle downloads.' }}>
  {releases.length === 0 ? (
    <p>
      Releases will appear here once the first GitHub Release is published.
      See <a href="https://github.com/AndreVianna/aid-methodology/releases">all releases on GitHub</a>.
    </p>
  ) : (
    releases.map((r) => (
      <section class="release">
        <h2 id={r.tag}><a href={r.url}>{r.name || r.tag}</a></h2>
        <p class="release-meta">
          <code>{r.tag}</code>
          {r.publishedAt && (
            <Fragment> · <time datetime={r.publishedAt}>{fmtDate(r.publishedAt)}</time></Fragment>
          )}
        </p>
        <div class="release-notes" set:html={renderBody(r.body)} />
        {offlineAssets(r).length > 0 && (
          <div class="release-downloads">
            <h3>Offline bundles</h3>
            <ul>
              {offlineAssets(r).map((a) => (
                {/* No `download` attr: it is a no-op on cross-origin GitHub asset
                    links (the asset still downloads via GitHub's Content-Disposition). */}
                <li><a href={a.url}>{a.name}</a></li>
              ))}
            </ul>
          </div>
        )}
      </section>
    ))
  )}
</StarlightPage>
```

Notes:
- The page **replaces** feature-001's stub `src/pages/releases/changelog.astro` (this feature
  overwrites that file at the same route). feature-001's sidebar entry
  `{ label: 'Changelog', link: '/releases/changelog' }` (a route `link:`, **not** a content
  `slug:`) resolves to this route unchanged — no sidebar edit is owned by this feature.
- `set:html` content is **sanitized** with an explicit allowlist (D3) that admits headings/`img`
  /task-list checkboxes before injection.
- Styling reuses casulo tokens (`.release`, `.release-meta`, `.release-downloads`) appended to
  feature-001's `site/src/styles/casulo.css` — no new color tokens; download links use the
  `--sl-color-accent` affordance.

### The Banner — `site/src/components/Banner.astro`

Registered as the `Banner` Starlight override (D6). Build-time `getLatestRelease()`; renders
nothing when `null`; dismissal keyed by tag (D7).

```astro
---
// site/src/components/Banner.astro — Starlight `Banner` override (FR16, AC14).
// Build-time: latest release from feature-002's accessor; no fetch, no runtime backend.
import { getLatestRelease } from '../lib/release-data';
const latest = getLatestRelease();
const tag = latest ? (latest.tag.startsWith('v') ? latest.tag : `v${latest.tag}`) : '';
// Suppress the banner on the Releases page itself — its "See what's new" link would
// point at the current page. (Trailing slash tolerated.)
const onReleasesPage = Astro.url.pathname.replace(/\/$/, '') === '/releases/changelog';
---
{latest && !onReleasesPage && (
  <div class="aid-banner" data-tag={tag} id="aid-release-banner">
    <span>AID <strong>{tag}</strong> is out.</span>
    <a href="/releases/changelog">See what's new →</a>
    <button type="button" class="aid-banner-dismiss" aria-label="Dismiss announcement">×</button>
    {/* D7/D8 — blocking inline script: hide iff this tag was already dismissed. */}
    <script is:inline>
      (() => {
        const el = document.getElementById('aid-release-banner');
        if (!el) return;
        const key = 'aid-banner-dismissed';
        const tag = el.getAttribute('data-tag');
        if (localStorage.getItem(key) === tag) { el.hidden = true; return; }
        el.querySelector('.aid-banner-dismiss')?.addEventListener('click', () => {
          localStorage.setItem(key, tag);
          el.hidden = true;
        });
      })();
    </script>
  </div>
)}
```

Notes:
- `is:inline` keeps the script verbatim (per-tag value embedded server-side via `data-tag`), no
  bundling/hydration — the minimal allowed client JS.
- A **new release** publishes a new `tag` → `localStorage` value (old tag) ≠ current `data-tag`
  → the banner re-shows automatically (AC14 "a new release re-shows").
- The banner **does not render on `/releases/changelog`** (it would otherwise link to the
  current page); it shows on every other page.
- With JS disabled the banner stays visible and its link still works (D8 degraded state).
- Banner styling (`.aid-banner`, `.aid-banner-dismiss`) appended to `casulo.css`, using existing
  accent/border tokens; sits in Starlight's `Banner` slot above page content on every page.

### Refresh on release (AC15 — releases/banner slice)

No work is required here at release time beyond the surfaces existing:
1. Maintainer publishes a GitHub Release (existing `release.sh` / `release.yml` flow — unchanged).
2. feature-002's `docs.yml` triggers on `release: published`, the fetcher repopulates
   `AID_RELEASES_JSON` / `AID_LATEST_RELEASE_JSON`, and runs `astro build`.
3. `getAllReleases()` / `getLatestRelease()` return the new data; the Releases page re-renders
   with the new release section + offline links, and `<Banner>` re-renders with the new tag.
4. The site redeploys. **No hand-edit, no change to `release.yml`** (AC15 releases/banner portion).

### File / Directory Tree (additions to `site/`)

```
site/
├── astro.config.mjs                         # EDIT — register components: { Banner: './src/components/Banner.astro' }  [THIS FEATURE]
├── package.json                             # EDIT — add pinned deps: marked, sanitize-html (D3)  [THIS FEATURE]
└── src/
    ├── pages/
    │   └── releases/
    │       └── changelog.astro              # REPLACE — overwrites feature-001's stub; real Releases page from getAllReleases() (FR10/AC9)  [THIS FEATURE]
    └── components/
        └── Banner.astro                     # NEW — Starlight Banner override from getLatestRelease() (FR16/AC14)  [THIS FEATURE]
```

Plus `.release*` and `.aid-banner*` rules appended to feature-001's
`site/src/styles/casulo.css` (no new color tokens; reuse existing casulo accent/border vars).

### Feature Boundaries

| Concern | Owner | This feature |
|---------|-------|--------------|
| `release: published` trigger, fetcher, env-var contract, `release-data.ts` accessor, `release.yml` (unchanged) | feature-002 | imports `getAllReleases()` / `getLatestRelease()`; needs no workflow change |
| `site/` shell, theme tokens, nav/sidebar (`Changelog` → `link: '/releases/changelog'`), reserved `Banner` slot, `releases/changelog.astro` stub | feature-001 | overwrites the stub with the real page; fills the `Banner` slot; reuses tokens; owns no sidebar edit |
| Version badge + install one-liners (FR15) | feature-008 | separate (`<VersionBadge>`); banner is a distinct announcement surface |
| Theme/config build & deploy | feature-001 / feature-002 | reuses existing config; only adds `components.Banner` + two render deps |

### Acceptance Criteria Coverage

| AC | How this feature satisfies it |
|----|-------------------------------|
| AC9 — Releases page reflects the GitHub Releases API with per-release offline bundle asset link(s) | `changelog.astro` maps `getAllReleases()`; each section renders tag/name/date + sanitized markdown `body` + filtered `aid-*.tar.gz` download links (D1/D3/D4); empty-state when `[]` (D5). |
| AC14 — dismissible banner shows latest release, links to Releases page, dismissal persists, new release re-shows | `Banner.astro` from `getLatestRelease()`; "AID v{tag} is out" → `/releases/changelog`; `localStorage` keyed by tag (D6/D7) so dismissal persists and a new tag re-shows. |
| AC15 (releases/banner portion) — `release: published` rebuild refreshes both, no `release.yml` change | Refresh flow above; this feature adds no workflow steps and edits no release file. |
| §4/§7 — read at build time, no runtime backend | Both surfaces call the build-time Node accessor (feature-002) in SSG; output is static HTML. The only client JS is the banner-dismissal inline script (`localStorage`), which makes no network call. |

### Assumptions & Open Questions

- **A1 (asset projection — spot-check feature-002):** feature-002's contract table projects
  assets as `{ name, url }`; the task brief mentions `{ name, url, size }`. This spec renders
  **name + download link only** (no byte size) to match the *guaranteed* projection. If
  feature-002 confirms `size` is in the projected shape, the page can show a human-readable size
  next to each link — additive, no structural change. `assets[].url` is assumed to be the asset
  `browser_download_url` (feature-002 D7 / contract note).
- **A2 (markdown render deps):** D3 adds `marked` + `sanitize-html` (pinned, small) because
  Astro does not expose its internal markdown renderer to `.astro` pages. **Fallback** if adding
  deps is undesired: render `body` as a fenced code block / `<pre>` (notes shown verbatim,
  unformatted) — degrades the look but ships zero new deps. Spot-check the team's appetite for
  the two deps vs. the plainer fallback.
- **A3 (offline-bundle pattern):** the `/^aid-.*\.tar\.gz$/` filter (D4) assumes offline bundles
  are named `aid-<tool>-v<version>.tar.gz` (per `docs/install.md` / feature-008 A4). If a release
  also attaches non-offline `.tar.gz` source archives that match, tighten the regex (e.g.
  require a known tool segment). Spot-check against an actual published release's asset names.
- **A4 (`<StarlightPage>` availability):** D2 assumes Starlight exposes `<StarlightPage>` (route
  middleware) in the pinned version (feature-001 D1). If absent in that version, the page falls
  back to importing Starlight's layout or a thin Starlight `<doc>` wrapper; the page-logic
  (accessor map + render) is unaffected. Spot-check against the pinned Starlight version.
- **A5 (banner placement / Starlight `Banner` semantics):** D6 assumes Starlight's `Banner`
  override slot renders site-wide above content and accepts a custom component. Confirm the slot
  name is exactly `Banner` in the pinned version (feature-001 reserved it under that name); if
  Starlight expects banner *config* rather than a component override in this version, the banner
  is instead injected via a small `Header`/`PageFrame` override — same accessor + script, different
  registration key.
- **A6 (no-JS / FOUC):** D8 prerenders the banner visible and only hides via the inline script,
  so a returning visitor who dismissed an older-but-still-current tag sees a brief banner only if
  the blocking script is delayed; the script is inline and tiny to minimize this. Acceptable per
  the minimal-JS NFR; verify no measurable Lighthouse regression on pages carrying the banner.
