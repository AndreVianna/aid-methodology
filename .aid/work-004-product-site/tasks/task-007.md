# task-007: `docs.yml` GitHub Actions build + deploy workflow

**Type:** CONFIGURE

**Source:** feature-002-build-and-deploy → delivery-001

**Depends on:** task-005, task-006

**Scope:**
- Author `.github/workflows/docs.yml` (sibling to `release.yml`/`test.yml`) with two jobs: `build` (Pages artifact) and `deploy` (publish).
- Triggers: `push` to `master` paths-filtered (`site/**`, `docs/**`, `VERSION`, `.github/workflows/docs.yml`), `release: { types: [published] }` (AC15 enabler), and `workflow_dispatch`.
- `permissions: contents: read / pages: write / id-token: write`; `concurrency: { group: pages-deploy, cancel-in-progress: false }`; `runs-on: ubuntu-24.04`.
- `build` steps: checkout → setup-node (`node-version-file: site/.nvmrc`, npm cache) → `configure-pages` → run `node site/scripts/fetch-release-data.mjs >> "$GITHUB_ENV"` (with `GITHUB_TOKEN`/`GITHUB_REPOSITORY`) → `npm ci` (`working-directory: site`) → `npm run build` (surfacing `AID_VERSION`/`AID_LATEST_RELEASE_JSON`/`AID_RELEASES_JSON`) → `upload-pages-artifact` (`path: site/dist`).
- `deploy` job: `needs: build`, `github-pages` environment, `deploy-pages`.
- Pin every action by commit SHA + `# vX.Y.Z` comment (D9); reuse vetted `checkout`/`setup-node` SHAs from `release.yml`; resolve current-stable SHAs for `configure-pages`/`upload-pages-artifact`/`deploy-pages` at implementation.
- Do NOT modify `release.yml` (decoupling, D8).

**Acceptance Criteria:**
- [ ] `docs.yml` builds on push to `master` (paths-filtered) and deploys to GitHub Pages.
- [ ] `release: published` and `workflow_dispatch` triggers rebuild with no paths constraint; `release.yml` is unmodified and uncross-referenced.
- [ ] The pre-build fetch step exports the three contract env vars into `$GITHUB_ENV` and the build step consumes them.
- [ ] Every action is SHA-pinned with a `# vX.Y.Z` comment; permissions are least-privilege.
- [ ] `concurrency` uses `pages-deploy` with `cancel-in-progress: false`.
- [ ] Configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
