# Build & Deploy

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR12), §6, §7, §8 | /aid-interview |
| 2026-06-06 | Revised: add `release: published` trigger and a generic build-time data-fetch capability (latest VERSION + GitHub Releases API) consumed by feature-008-version-injection and feature-009-releases-and-banner; release.yml remains unmodified (decoupled). | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR12 (enabling FR10, FR15, FR16) · §4 Scope · §6 NFRs · §7 Constraints · §8 Assumptions

## Description

A GitHub Actions workflow builds the Astro Starlight site and deploys it to GitHub Pages at
the custom domain `aid.casuloailabs.com` over enforced HTTPS, shipping a `CNAME` in the build
output and generating `sitemap.xml` and `robots.txt`, with pinned build dependencies for
reproducible builds. Beyond push-to-default-branch deploys, the workflow also triggers on the
GitHub `release: published` event so the site can refresh release-bound content hands-free.
To support that, the workflow provides a generic build-time data-fetch capability — reading the
repository `VERSION` file and the GitHub Releases API using the workflow's `GITHUB_TOKEN` — and
exposes that data to the build for the version-injection (feature-008) and releases-and-banner
(feature-009) features to consume. This binding is fully decoupled from `release.yml`, which is
not modified.

## User Stories

- As an adopter, I want the site live at a stable HTTPS custom domain so that I can trust and bookmark it.
- As a maintainer, I want the site to build and deploy automatically on every change to the default branch so that publishing requires no manual steps.
- As a maintainer, I want the docs to rebuild automatically when I publish a GitHub Release so that release-bound content refreshes without touching the release process.
- As a maintainer, I want build dependencies pinned so that builds are reproducible and don't break on upstream churn.
- As an evaluator, I want the site discoverable (sitemap, robots, valid HTTPS) so that it presents as a credible product.

## Priority

Must

## Acceptance Criteria

- [ ] Given a push to the default branch, when the workflow runs, then the Starlight site builds with no errors and deploys to GitHub Pages automatically. (AC1)
- [ ] Given the deployed site, when a visitor loads `https://aid.casuloailabs.com`, then it is reachable over enforced HTTPS with the `CNAME` and Pages custom-domain configured. (AC2)
- [ ] Given the build output, when it is published, then a sitemap index (`sitemap-index.xml`, emitted by `@astrojs/sitemap` alongside `sitemap-0.xml`) and `robots.txt` are present and valid.
- [ ] Given the build pipeline, when it runs in CI, then build dependencies are pinned so the build is reproducible.
- [ ] Given a published GitHub Release, when the `release: published` event fires, then the docs workflow triggers a rebuild with no manual steps and with no change to `release.yml`. (AC15, enabling)
- [ ] Given the workflow, when it builds, then a build-time data-fetch step reads the `VERSION` file and the GitHub Releases API (via `GITHUB_TOKEN`) and exposes that data to the build for features 008 and 009 to consume.

---

## Technical Specification

### Overview & Approach

This feature adds the **CI/CD and deploy layer** on top of the `site/` Astro + Starlight
project stood up by feature-001. It owns three things feature-001 deliberately left as TODO
markers: (1) the Pages-facing `site`/`base` config in `astro.config.mjs`; (2) a GitHub Actions
workflow that builds `site/` and deploys it to GitHub Pages at `aid.casuloailabs.com` over
enforced HTTPS; (3) the SEO/discoverability outputs (a `@astrojs/sitemap` index — `sitemap-index.xml` + `sitemap-0.xml`, `robots.txt`, `CNAME`).

It also owns a fourth, cross-feature capability: a **build-time data-fetch contract** that reads
the repo `VERSION` file and the GitHub Releases API and exposes that data to the Astro build via
**well-defined environment variables**. This feature *builds and ships* the fetch + the contract
(and proves it with a no-op default), but does **not** render any version badge, install-command
injection, or release/banner UI — those are owned by feature-008 (version injection) and
feature-009 (releases + banner), which consume the contract defined here. The binding is fully
**decoupled from `release.yml`** (it triggers on the `release: published` event from the outside;
it does not modify `release.yml` — see *Decoupling* below).

Per the KB (`infrastructure.md`): this repo has **no conventional runtime infrastructure**; the
existing release pipeline (`release.yml`) is tag-triggered and least-privilege, and all actions
are **SHA-pinned with a trailing `# vX.Y.Z` comment** on `ubuntu-24.04`. This workflow matches
those repo conventions exactly so it reads as a sibling of `release.yml` / `test.yml`.

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Hand-rolled build job + official Pages actions** (`actions/upload-pages-artifact` + `actions/deploy-pages`), **not** `withastro/action` | We need a custom build-time data-fetch step (VERSION + Releases API → env vars) *before* `astro build`, plus an explicit `working-directory: site`. `withastro/action` is a convenience wrapper that hides the build step and complicates injecting our env-var contract and a monorepo subdir; explicit steps are more transparent, match the `release.yml` house style (explicit `npm ci` / `npm run build`), and keep the data-fetch contract first-class. Research §3 notes `withastro/action` exists but is optional. |
| D2 | **`site: 'https://aid.casuloailabs.com'`, `base: '/'`** in `astro.config.mjs` | Apex-of-its-own subdomain on a custom domain serves from the domain root, so `base` is `/` (no repo-path prefix). `site` is the absolute origin Astro/Starlight/sitemap use to emit canonical + sitemap URLs. |
| D3 | **`@astrojs/sitemap`** integration for `sitemap.xml`; **static `site/public/robots.txt`** | Standard Astro SEO path (research §3, NFR SEO). `@astrojs/sitemap` reads `site` (D2) to emit absolute URLs; robots.txt points crawlers at the sitemap. (The `@astrojs/sitemap` dep was already listed in feature-001's `package.json` plan — this feature wires the integration.) |
| D4 | **`site/public/CNAME`** committed (single line `aid.casuloailabs.com`) | Actions-based Pages publishing requires the `CNAME` in the build output; `public/` is copied verbatim to `dist/`. Research §4 confirms this is the Astro pattern. |
| D5 | **Pinned Node via `site/.nvmrc` + `engines.node` in `site/package.json`**, `npm ci` from the committed lockfile | Reproducible builds (AC: pinned deps). `setup-node` reads `.nvmrc`; `npm ci` fails on lockfile drift. |
| D6 | **Build-time data exposed as `process.env` vars** (`AID_VERSION`, `AID_LATEST_RELEASE_JSON`, `AID_RELEASES_JSON`), populated by a pre-build fetch step writing to `$GITHUB_ENV` | These are non-`PUBLIC_`-prefixed, build-time-only vars. Vite/Astro only place `PUBLIC_`-prefixed vars on `import.meta.env`, so the build-time Node accessor module reads `process.env.*` directly (the accessor runs in Node during SSG/build, where `process.env` carries the values exported into `$GITHUB_ENV`). Env vars are the simplest decoupled contract that 008/009 can read without this feature importing their code. A typed accessor module wraps them (D7). |
| D7 | **A typed accessor module `site/src/lib/release-data.ts`** wraps the raw env vars and provides safe defaults | Gives 008/009 a stable import surface (`getAidVersion()`, `getLatestRelease()`, `getAllReleases()`) instead of reaching into `process.env` directly; centralizes parsing/fallbacks so a missing/empty fetch degrades gracefully (build never fails for lack of release data). This module is the **ONE canonical accessor** — feature-008 imports `getAidVersion()` from it and does NOT re-read the env itself. |
| D8 | **Decoupled `release: published` trigger** in *this* workflow; `release.yml` is **NOT** modified | NFR maintainability + constraint §7: release process needs no changes. The docs workflow listens for the event from the outside; the two workflows never reference each other. |
| D9 | **Pin all actions by commit SHA + `# vX.Y.Z` comment**, reuse the exact SHAs already vetted in `release.yml` where the action is shared (`actions/checkout`, `actions/setup-node`) | Repo convention (every existing workflow pins by SHA); supply-chain hardening; reusing vetted SHAs reduces review surface. New actions (`configure-pages`, `upload-pages-artifact`, `deploy-pages`) are pinned at their current-stable SHA — **mark "pin at implementation"** (resolve the SHA for the latest stable tag when the file is written). |

### The Workflow — `.github/workflows/docs.yml`

A new workflow file, sibling to `release.yml` / `test.yml`. **Two jobs**: `build` (produces the
Pages artifact) and `deploy` (publishes it). Shape (action SHAs marked *pin at implementation*
must be resolved to the current-stable tag's commit SHA when written):

```yaml
name: Docs

# Builds the Astro Starlight site under site/ and deploys it to GitHub Pages
# at https://aid.casuloailabs.com.  Decoupled from release.yml: it merely
# *listens* for release:published to refresh release-bound content; it does
# not modify or depend on the release pipeline.

on:
  push:
    branches: [master]
    paths:                      # only rebuild when site inputs change
      - 'site/**'
      - 'docs/**'               # migrated content source (feature-005)
      - 'VERSION'               # version injection input (feature-008)
      - '.github/workflows/docs.yml'
  release:
    types: [published]          # AC15 enabler — refresh release-bound content hands-free
  workflow_dispatch:            # manual re-deploy

# Least-privilege: read the repo, write the Pages deployment, mint the OIDC
# token deploy-pages exchanges.  No contents:write, no issues/pull-requests.
permissions:
  contents: read
  pages: write
  id-token: write

# One in-flight Pages deploy at a time; a newer push supersedes an older
# queued run, but never cancel a deploy mid-publish.
concurrency:
  group: pages-deploy
  cancel-in-progress: false

jobs:
  build:
    name: build (astro build → Pages artifact)
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
        with:
          node-version-file: 'site/.nvmrc'
          cache: 'npm'
          cache-dependency-path: 'site/package-lock.json'

      - uses: actions/configure-pages@<SHA> # vX  (pin at implementation)

      # Build-time data-fetch (this feature OWNS this; 008/009 consume it).
      # Reads VERSION + the GitHub Releases API via the workflow GITHUB_TOKEN
      # and exports the contract env vars into $GITHUB_ENV for the build step.
      - name: Fetch build-time release data (VERSION + Releases API)
        env:
          GITHUB_TOKEN: ${{ github.token }}   # built-in, read-only here
          GITHUB_REPOSITORY: ${{ github.repository }}
        run: node site/scripts/fetch-release-data.mjs >> "$GITHUB_ENV"

      - name: Install deps (reproducible)
        working-directory: site
        run: npm ci

      - name: Build Astro Starlight site
        working-directory: site
        env:                                  # surface the contract to the build
          AID_VERSION: ${{ env.AID_VERSION }}
          AID_LATEST_RELEASE_JSON: ${{ env.AID_LATEST_RELEASE_JSON }}
          AID_RELEASES_JSON: ${{ env.AID_RELEASES_JSON }}
        run: npm run build            # = astro build (emits site/dist + CNAME + sitemap)

      - uses: actions/upload-pages-artifact@<SHA> # vX  (pin at implementation)
        with:
          path: site/dist

  deploy:
    name: deploy (Pages)
    needs: build
    runs-on: ubuntu-24.04
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@<SHA> # vX  (pin at implementation)
```

Notes:
- **Paths filter** keeps the workflow from running on unrelated repo changes (canonical/,
  profiles/, tests/), satisfying "deploys on push to default branch" without churn.
- The `release: published` and `workflow_dispatch` events have no `paths` constraint (paths
  filters only apply to `push`), so a published release or manual dispatch always rebuilds —
  which is exactly the AC15-enabler behavior (release-bound content refreshes).
- `concurrency.group: pages-deploy` with `cancel-in-progress: false` is the GitHub-recommended
  Pages pattern (don't kill an in-flight publish).
- `npm run build` is the `site/package.json` script feature-001 defines (`astro build`); this
  feature does not introduce a new build entrypoint.

### Build-time Data-Fetch Contract (OWNED here; consumed by feature-008 & feature-009)

This is the load-bearing cross-feature deliverable. It has two halves — the **fetcher** (CI) and
the **accessor** (build) — joined by **three environment variables**.

**1. Fetcher — `site/scripts/fetch-release-data.mjs`** (Node, no extra deps; uses global
`fetch` + `node:fs`). Run as the pre-build CI step above. Responsibilities:
- Read the repo `VERSION` file (repo root), trim whitespace → the bare semver (e.g. `1.0.0`).
- Call the GitHub Releases API (`GET /repos/{owner}/{repo}/releases?per_page=100` and
  `GET /repos/{owner}/{repo}/releases/latest`) with `Authorization: Bearer $GITHUB_TOKEN`
  and `Accept: application/vnd.github+json`; `{owner}/{repo}` derived from `GITHUB_REPOSITORY`
  (falls back to `AndreVianna/aid-methodology`).
- Emit **three `KEY=value` lines** suitable for appending to `$GITHUB_ENV` (the step does
  `>> "$GITHUB_ENV"`). JSON values are emitted single-line (no newlines) so they are valid
  `$GITHUB_ENV` entries.
- **Degrade gracefully:** on any API failure / rate-limit / non-2xx, emit the VERSION-derived
  fields and **empty** release fields (`AID_LATEST_RELEASE_JSON=` / `AID_RELEASES_JSON=`) and
  exit 0 — the docs build must never fail because release data was unavailable. Log a warning.

**2. The three contract environment variables** (the stable interface 008/009 rely on):

| Env var | Type (string) | Meaning | Primary consumer |
|---------|---------------|---------|------------------|
| `AID_VERSION` | bare semver, e.g. `1.0.0` | latest released version; from `VERSION`, falling back to `latest` release `tag_name` (stripped of leading `v`) if VERSION is absent | feature-008 (version badge + install one-liners) |
| `AID_LATEST_RELEASE_JSON` | single-line JSON object \| empty | the latest release projected to `{ tag, name, url, publishedAt, assets: [{ name, url }] }` (empty string if unavailable) | feature-009 (banner) + feature-008 (cross-check) |
| `AID_RELEASES_JSON` | single-line JSON array \| empty | all releases, each projected to `{ tag, name, url, publishedAt, body, assets: [{ name, url }] }`, newest-first (empty array/string if unavailable) | feature-009 (Releases/changelog page, incl. per-release offline-bundle asset links) |

The **projected shape** (not the raw GitHub payload) is part of the contract: only the listed
fields are guaranteed. `assets[].name` / `assets[].url` (the release asset `browser_download_url`)
are included specifically so feature-009 can render per-release offline-bundle download links
(FR10 / AC9). If 008/009 need an additional field later, they request it here (one fetcher, one
contract).

**3. Accessor — `site/src/lib/release-data.ts`** (this feature ships it). This is the **ONE
canonical accessor** for the contract. It is a build-time **Node** module: it reads the raw vars
from `process.env` (NOT `import.meta.env` — these are non-`PUBLIC_` build-time vars, which
Vite/Astro do not place on `import.meta.env`) and exposes a typed API with safe fallbacks so
consuming features import a stable surface, never `process.env` directly:

```ts
export interface ReleaseAsset { name: string; url: string }
export interface Release {
  tag: string; name: string; url: string;
  publishedAt: string; body?: string; assets: ReleaseAsset[];
}
// Resolution: process.env.AID_VERSION (strip leading 'v') → fallback to reading
// the repo-root VERSION file (so it works in local dev with no env var) → '' if neither.
export function getAidVersion(): string;
export function getLatestRelease(): Release | null; // parse process.env.AID_LATEST_RELEASE_JSON, null if empty/invalid
export function getAllReleases(): Release[];        // parse process.env.AID_RELEASES_JSON, [] if empty/invalid
```

`getAidVersion()` resolution order (full single-source logic, owned here):
1. `process.env.AID_VERSION` — if set, trim and strip a leading `v` → return the bare semver.
2. **Fallback:** read the repo-root `VERSION` file directly (`node:fs`), trim, strip leading `v`
   — so the accessor resolves a version in **local dev** (`astro build`/`dev` with no env var set,
   no CI fetch step run).
3. If neither is available, return `''` (consumers handle empty).

**feature-008 imports `getAidVersion()` from this module** (the version badge + install
one-liners) and does **NOT** re-read the env or the `VERSION` file itself — 008 will be updated to
match this single-source contract. `getLatestRelease()` / `getAllReleases()` remain for feature-009.

**Default behavior shipped by this feature:** with no release data present (local dev, or API
failure) `getAidVersion()` still resolves via the `VERSION`-file fallback while
`getLatestRelease()` / `getAllReleases()` return `null` / `[]`, the build succeeds, and 008/009
render their no-data fallbacks. This feature ships the module + a trivial proof (e.g. logs the
resolved version at build) but **no user-visible UI**.

### `astro.config.mjs` changes (owned here)

Feature-001 left `site`/`base` and the sitemap integration as TODO markers. This feature sets:

```js
export default defineConfig({
  site: 'https://aid.casuloailabs.com',   // D2 — absolute origin for canonical + sitemap URLs
  base: '/',                              // D2 — custom subdomain serves from root
  integrations: [
    sitemap(),                            // D3 — @astrojs/sitemap → sitemap-index.xml
    // astro-mermaid + starlight(...) already configured by feature-001
  ],
});
```

`@astrojs/sitemap` emits `sitemap-index.xml` + `sitemap-0.xml` into `dist/`; `robots.txt`
references the index. (Exact integration-array ordering relative to feature-001's
`astro-mermaid`/`starlight` entries is preserved; sitemap is order-independent.)

### Static SEO / domain files (owned here)

- `site/public/CNAME` — single line: `aid.casuloailabs.com` (no scheme, no trailing slash).
- `site/public/robots.txt`:
  ```
  User-agent: *
  Allow: /
  Sitemap: https://aid.casuloailabs.com/sitemap-index.xml
  ```
- `site/.nvmrc` — pinned Node major (e.g. `20`, matching `release.yml`/`test.yml`'s `node-version: '20'`; **confirm against feature-001's `engines`** and pin at implementation).
- `site/package.json` `engines.node` — `">=20"` (or the exact line feature-001 chose; keep consistent — spot-check).

### Decoupling from `release.yml` (explicit)

`release.yml` is **not edited** by this feature. The only relationship is that *this* workflow
subscribes to the `release: published` GitHub event, which `release.yml` produces as a side effect
of `gh release create` during a tag release. The two workflows have no `needs`, no shared
artifacts, and no file references. This satisfies the constraint "live-project bindings must be
decoupled from `release.yml`, which is not modified" (REQUIREMENTS §7, NFR maintainability).

### One-time manual GitHub settings (out-of-band; documented, not automated)

These cannot be set by the workflow and are recorded for the operator (AC2):
1. Repo **Settings → Pages → Source = GitHub Actions** (required for `deploy-pages`).
2. Repo **Settings → Pages → Custom domain = `aid.casuloailabs.com`** (then GitHub verifies DNS).
3. **DNS at GoDaddy:** add the `aid` `CNAME` record → `AndreVianna.github.io` (per research §4 —
   add the domain in GitHub *before* creating the DNS record to avoid takeover risk).
4. Wait for Let's Encrypt provisioning, then enable **Enforce HTTPS** (can take up to ~24h).

The committed `public/CNAME` keeps the custom-domain setting from being wiped on each Actions
deploy.

### File / Directory additions

```
.github/workflows/docs.yml                 # NEW — build + deploy workflow (this feature)
site/
├── .nvmrc                                  # NEW — pinned Node (reproducible builds)
├── astro.config.mjs                        # EDIT — set site/base + add sitemap() integration
├── package.json                            # EDIT — confirm engines.node + @astrojs/sitemap dep
├── public/
│   ├── CNAME                               # NEW — aid.casuloailabs.com
│   └── robots.txt                          # NEW — Allow all + Sitemap pointer
├── scripts/
│   └── fetch-release-data.mjs              # NEW — CI build-time fetcher (VERSION + Releases API)
└── src/lib/
    └── release-data.ts                     # NEW — typed accessor for the contract (008/009 import)
```

### Acceptance Criteria Coverage

| AC | How this feature satisfies it |
|----|-------------------------------|
| AC1 — builds & deploys on push to default branch | `docs.yml` `push: branches: [master]` (paths-filtered) → `build` (`npm ci` + `astro build`) → `deploy` (`actions/deploy-pages`). |
| AC2 — live on custom domain over HTTPS | `public/CNAME` + Pages custom-domain + Enforce-HTTPS (manual one-time steps documented); `site: https://aid.casuloailabs.com` / `base: '/'`. |
| sitemap index + robots.txt present & valid | `@astrojs/sitemap` integration (reads `site`) emits `sitemap-index.xml` (+ `sitemap-0.xml`) + static `public/robots.txt` referencing the sitemap index. |
| reproducible / pinned build | committed `package-lock.json` (feature-001) + `npm ci` + `.nvmrc`/`engines.node` pinned Node. |
| AC15 enabler — `release: published` rebuild, no `release.yml` change | `docs.yml` `release: { types: [published] }` trigger; `release.yml` untouched; no cross-references (*Decoupling*). |
| build-time data-fetch exposed to build for 008/009 | `fetch-release-data.mjs` (reads VERSION + Releases API via `GITHUB_TOKEN`) → `AID_VERSION` / `AID_LATEST_RELEASE_JSON` / `AID_RELEASES_JSON` → `release-data.ts` typed accessor. |

> **Lighthouse / perf (AC10) and a11y/contrast (AC4/AC10)** are verified by the *built site*
> (feature-001 + content features), not by this deploy layer. This feature only ensures the
> static, prerendered output ships unmodified to Pages (minimal JS, static assets) so those
> bars remain achievable; it adds no client-side runtime.

### Assumptions & Open Questions

- **A1 (Pages action SHAs):** `actions/configure-pages`, `actions/upload-pages-artifact`, and
  `actions/deploy-pages` are pinned by SHA *at implementation* (resolve the current-stable tag's
  commit SHA, mirroring how `release.yml` pins every action). `actions/checkout` + `setup-node`
  reuse the SHAs already vetted in `release.yml`/`test.yml`.
- **A2 (Node version):** `.nvmrc`/`engines.node` is assumed `20` to match `release.yml`/`test.yml`
  (`node-version: '20'`). **Spot-check** against the `engines` value feature-001 committed in
  `site/package.json`; if they differ, feature-001's value wins and `.nvmrc` follows it.
- **A3 (`base: '/'`):** correct for an apex-of-subdomain custom domain. Only changes if the site
  were ever served from a repo sub-path (`AndreVianna.github.io/aid-methodology/`), which the
  custom-domain decision rules out.
- **A4 (Node build-env exposure):** the accessor is a build-time Node module and reads the
  non-`PUBLIC_` contract vars from `process.env` (NOT `import.meta.env`, which Vite/Astro reserve
  for `PUBLIC_`-prefixed vars). The contract (the three var names + the accessor API) is fixed; the
  accessor is the single read-point so any future exposure tuning stays internal to this module.
- **A5 (Releases API rate limit):** authenticated `GITHUB_TOKEN` gives 5000 req/h — ample for two
  calls per build. The graceful-degradation path (empty release fields, exit 0) covers transient
  failures so a deploy is never blocked by the API.
- **A6 (`@astrojs/sitemap` dependency):** assumed present in `site/package.json` per feature-001's
  declared deps; if absent, this feature adds it (pinned) and re-runs `npm install` to update the
  lockfile. Spot-check.
