# task-019: Releases page + announcement banner

**Type:** IMPLEMENT

**Source:** feature-009-releases-and-banner → delivery-003

**Depends on:** task-009

**Scope:**
- Replace feature-001's stub `site/src/pages/releases/changelog.astro` with the real Releases page (D1): call `getAllReleases()`, map one section per release (tag/name/date), render each markdown `body` → sanitized HTML at build time (D3, `marked` + `sanitize-html` with the explicit allowlist re-admitting headings/img/task-list checkboxes), and render per-release offline-bundle download links filtered by `/^aid-.*\.tar\.gz$/` (D4). Wrap in `<StarlightPage>` (D2); render the empty-state when `getAllReleases()` is `[]` (D5).
- Author `site/src/components/Banner.astro` (D6/D7/D8/D9): call `getLatestRelease()`; render nothing when `null`; self-suppress on `/releases/changelog`; copy "AID v{tag} is out" → `/releases/changelog`; dismissal persisted in `localStorage` keyed by tag via a blocking `is:inline` script (new tag re-shows).
- Add pinned `marked` + `sanitize-html` deps to `package.json` and relock.
- Register `components: { Banner: './src/components/Banner.astro' }` by ADDING the key to feature-001's shared `components:` map (do not rewrite the map).
- Append `.release*` and `.aid-banner*` rules to `casulo.css` (existing tokens only).

**Acceptance Criteria:**
- [ ] Releases page maps `getAllReleases()`; each release renders tag/name/date + sanitized `body` HTML + `aid-*.tar.gz` download links; empty-state renders when `[]` (AC9).
- [ ] Markdown `body` is sanitized via the explicit allowlist before `set:html`; `marked.parse` called with `{ async: false }`.
- [ ] Banner shows the latest release, links to `/releases/changelog`, self-suppresses on that page, and dismissal persists keyed by tag with a new tag re-showing (AC14).
- [ ] The only client JS is the inline dismissal script (no network call); the Releases page ships no client JS.
- [ ] `Banner` key is added to feature-001's shared `components:` map (Cross-Cutting Risk #1); `marked`/`sanitize-html` pinned + relocked.
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
