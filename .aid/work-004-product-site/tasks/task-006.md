# task-006: Build-time data-fetch contract — fetcher + typed accessor

**Type:** IMPLEMENT

**Source:** feature-002-build-and-deploy → delivery-001

**Depends on:** task-004

**Scope:**
- Author `site/scripts/fetch-release-data.mjs` (Node, stdlib `fetch` + `node:fs`): read repo-root `VERSION` (trim → bare semver); call the GitHub Releases API (`?per_page=100` + `/releases/latest`) with `Authorization: Bearer $GITHUB_TOKEN`; derive `{owner}/{repo}` from `GITHUB_REPOSITORY` (fallback `AndreVianna/aid-methodology`); emit three single-line `KEY=value` lines (`AID_VERSION`, `AID_LATEST_RELEASE_JSON`, `AID_RELEASES_JSON`) for `$GITHUB_ENV`.
- Project release JSON to the contract shape (`{ tag, name, url, publishedAt, body, assets:[{name,url}] }`, newest-first); latest projected likewise.
- Degrade gracefully: any API failure → emit VERSION-derived fields + empty release fields and exit 0 (log a warning); the build must never fail for lack of release data.
- Author `site/src/lib/release-data.ts` — the ONE canonical accessor (D7): export `ReleaseAsset`/`Release` interfaces and `getAidVersion()`, `getLatestRelease()`, `getAllReleases()`; read from `process.env.*` (NOT `import.meta.env`); `getAidVersion()` resolution = env → repo-root `VERSION` file fallback → `''`.

**Acceptance Criteria:**
- [ ] `fetch-release-data.mjs` emits three valid single-line `$GITHUB_ENV` entries; JSON values contain no newlines.
- [ ] On simulated API failure the fetcher emits the VERSION-derived field + empty release fields and exits 0.
- [ ] `release-data.ts` exposes `getAidVersion()` / `getLatestRelease()` / `getAllReleases()` with safe defaults (`''` / `null` / `[]`).
- [ ] `getAidVersion()` resolves the bare semver (strips leading `v`) from env, then the `VERSION` file fallback (works in local dev with no env var).
- [ ] Unit tests cover the fetcher's projection + degradation path and the accessor's resolution order and empty/invalid parsing.
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
