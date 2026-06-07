# task-010: Version-injection layer — `version.ts` + `<InstallCommand>` + `<VersionBadge>`

**Type:** IMPLEMENT

**Source:** feature-008-version-injection → delivery-002

**Depends on:** task-009

**Scope:**
- Author `site/src/data/version.ts`: `import { getAidVersion } from '../lib/release-data'` (feature-002 accessor, single source); export `VERSION = getAidVersion()`, `VERSION_TAG = \`v${VERSION}\``, the `InstallChannel` type (`curl|irm|npm|pypi|offline`), the `installCommands` map (version-pinned shapes sourced from `docs/install.md`, D6), and `channelLabels`. Do NOT read `process.env`/`fs` here (D1/D2).
- Author `site/src/components/InstallCommand.astro`: `Props { channel; lang? }`; render `installCommands[channel]` via Starlight `<Code>` with per-channel language (`irm` → `powershell`, others → `bash`).
- Author `site/src/components/VersionBadge.astro`: `Props { prefix='v'; href? }`; render a pill (linked if `href`, else plain text); no default route.
- Append a `.version-badge` rule to `site/src/styles/casulo.css` using existing casulo accent tokens (no new tokens).
- Register the version badge in the `Hero`/content slot reserved by feature-001 (add the key to feature-001's `components:` map; do not rewrite the map).

**Acceptance Criteria:**
- [ ] `version.ts` derives `VERSION` solely from `getAidVersion()`; exports `VERSION`, `VERSION_TAG`, `installCommands`, `channelLabels`, `InstallChannel`.
- [ ] `installCommands` covers all five channels with version-pinned shapes matching `docs/install.md` (incl. the `irm` `$env:AID_VERSION` PowerShell bootstrap).
- [ ] `<InstallCommand channel=… />` renders the current version with correct per-channel highlighting; `<VersionBadge>` renders `v{VERSION}`, linked only when `href` is passed.
- [ ] `.version-badge` CSS uses existing casulo accent tokens only.
- [ ] Unit tests cover `installCommands` shape per channel and badge linked/unlinked rendering.
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
