# Version Injection: Always-Current Version & Install Commands

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature, split from the combined feature-008-release-integration per user request: owns the always-current version binding (FR15) only. Releases page + announcement banner moved to feature-009-releases-and-banner. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR15 · §4 Scope · §6 NFRs (Maintainability) · §7 Constraints (live-project bindings) · §8 Assumptions

## Description

The single build-time binding that keeps every documented version current with the live AID
project. At build time this feature consumes the version data fetched by feature-002 (the
repository `VERSION` file and the latest GitHub Release) and injects it into the site's version
badge and into **all** install one-liners across the site — curl/irm, npm, PyPI, and the offline
tarball. It is the one owner of "what is the current version" so there is a single source of
truth: the Home install one-liner (feature-003) and the Installation guide commands (feature-004)
are pure consumers of this injected value rather than hard-coding a version. The injection is
read at build time only — no runtime backend — and is refreshed automatically when the docs
rebuild on the `release: published` event (trigger provided by feature-002), so a new release
makes every command and badge current with no hand-editing and no change to `release.yml`. This
is the FR15 slice the project marks **Must** for the first deploy, isolated from the Should/Could
releases-page and banner work so it cannot be delayed by them.

## User Stories

- As a returning user, I want the version badge and every install command to show the current release so that I never copy a stale version.
- As a new adopter, I want the install one-liner I copy to "just work" with the current version so that my first install doesn't fail on a wrong version.
- As a maintainer, I want a single owner of the current-version value so that there is no risk of three different hard-coded versions drifting across the site.
- As a maintainer, I want the version to refresh automatically when I publish a release so that I never hand-edit version numbers in the docs.

## Priority

Must

## Acceptance Criteria

- [ ] Given a build, when the version badge and the install one-liners (curl/irm, npm, PyPI, offline) render, then each shows the latest released version, matching the `VERSION` file / latest GitHub Release. (AC13)
- [ ] Given features 003 and 004, when they render version-bearing commands, then they consume the value injected by this feature rather than hard-coding a version. (AC13)
- [ ] Given a published GitHub Release, when the docs rebuild on the `release: published` event, then the badge and all install commands update with no manual steps and no change to `release.yml`. (AC15 — version/install portion)
- [ ] Given the binding, when the version is read, then it is read at build time with no runtime backend call. (§4, §7)

---

## Technical Specification

### Overview & Approach

This feature provides the **single build-time version binding** for the whole site. It owns
one typed data module and a small set of components; every version number and every install
one-liner rendered anywhere on the site derives from this binding, so there is exactly one
place that answers "what is the current AID version." Features 003 (home install one-liner)
and 004 (install guide, all four channels) are **pure consumers** — they import the components
defined here and never hard-code a version string.

The binding is **build-time only** (no runtime backend, honoring §4/§7 and AC's "read at build
time with no runtime backend call"). At `astro build` the version is resolved once and frozen
into the static HTML. A new release re-renders everything because feature-002's deploy workflow
rebuilds on the `release: published` event (FR12 → FR15); this feature requires **no change to
`release.yml`** and adds no workflow steps of its own.

This feature extends the `site/` Astro + Starlight project from feature-001 (do not contradict
its anchors): it registers the **version badge** in the reserved `Hero`/content slot and ships
components under `site/src/components/`. It does not touch the theme, navigation, or build/deploy
config.

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | The **raw current version** has one owner: feature-002's `getAidVersion()` in `site/src/lib/release-data.ts`. `site/src/data/version.ts` imports it (`export const VERSION = getAidVersion();`) and is the **version-injection layer** (install commands, labels, components) on top. | FR15 "one owner"; avoids a duplicate accessor — coordinated decision with feature-002. |
| D2 | Version resolution lives entirely in feature-002's `getAidVersion()`: it resolves **(1)** `process.env.AID_VERSION` if set (CI/deploy), else **(2)** an import-time read of the repo-root `VERSION` file. Feature-008 does **not** read env or `fs` itself. | Works in CI (env injected by deploy) and in local `npm run dev`/`build` with no env (reads `VERSION`, currently `1.0.0`). Reproducible, no network at build; single accessor. |
| D3 | `version.ts` runs in Node at build time only (Astro evaluates module imports in the SSG build), never shipped to the browser. The resolved string is inlined into static HTML. | AC: "read at build time, no runtime backend." Keeps NFR minimal-JS (no client fetch). |
| D4 | Install commands are rendered by **one reusable component `<InstallCommand channel=… />`** (`.astro`), not copy-pasted markdown, so the version interpolation lives in one file. | FR15 "reusable injection mechanism"; 003/004 "just use it." |
| D5 | The **version badge** is a separate small component `<VersionBadge />` registered as a Starlight component override (`Hero`/content slot reserved by feature-001), reusable inline in MDX. | AC13 (badge shows latest); feature-001 reserved this slot for FR15. |
| D6 | Channel-specific command shapes are **derived from `docs/install.md`** (the existing single source) and centralized in `version.ts` as a typed `installCommands` map, so command text + version both have one owner. | Constraint §7 content-reuse / minimize drift; matches the real shipped commands. |
| D7 | This feature **does not** fetch the GitHub Releases API itself. The "latest version" string it needs is satisfied by the `VERSION` file (D2); the richer Releases-API data is feature-002/009 territory. | Keeps FR15 isolated and Must-shippable independent of the Should/Could releases work. |

### Dependency on feature-002 (data-fetch CONTRACT)

Feature-002 owns the canonical version accessor — **`getAidVersion()` in
`site/src/lib/release-data.ts`** — and feature-008 consumes it directly:

> **CONTRACT `getAidVersion()` (accessor):** feature-002 exports `getAidVersion()` from
> `site/src/lib/release-data.ts`. It resolves the latest released version string
> (e.g. `1.0.0`, no leading `v`) from **`process.env.AID_VERSION`** (set by feature-002's
> CI/deploy workflow) and falls back to an import-time read of the repo-root `VERSION` file.
> `version.ts` calls `getAidVersion()` — it never reads `process.env` or `fs` itself.

Resilience (env may be unset in local dev) is handled **inside** `getAidVersion()` via its
`VERSION`-file fallback, so feature-008 is not blocked by the parallel spec. Two naming/shape
assumptions to confirm with feature-002 are flagged in *Assumptions* (A1, A2). This is the only
coupling; the sole shared file is the imported accessor, and there is no runtime call.

### Data Model — `site/src/data/version.ts`

The exposed values (the public API other features import):

```ts
// site/src/data/version.ts — the site's version-injection layer.
// The raw version comes from feature-002's canonical accessor (single source):
// getAidVersion() resolves process.env.AID_VERSION → falls back to reading the
// repo-root VERSION file. This module does NOT read env or fs itself; it adds
// the version-pinned install commands + labels + components on top of that value.
import { getAidVersion } from '../lib/release-data';

/** Bare current version, e.g. "1.0.0" (no leading "v"). Sourced from feature-002's accessor. */
export const VERSION: string = getAidVersion();

/** Tag form, e.g. "v1.0.0" — used in release-asset URLs. */
export const VERSION_TAG: string = `v${VERSION}`;

export type InstallChannel = 'curl' | 'npm' | 'pypi' | 'offline';

/**
 * Version-pinned, copy-pasteable install commands, one per channel.
 * Command shapes are sourced from docs/install.md (single content source, D6).
 * Each is the *pinned* form so the rendered command always shows the current version.
 */
export const installCommands: Record<InstallChannel, string> = {
  curl:
    `curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- --version ${VERSION}`,
  npm:
    `npm i -g aid-installer@${VERSION}`,
  pypi:
    `pipx install aid-installer==${VERSION}`,
  offline:
    `curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/${VERSION_TAG}/aid-claude-code-${VERSION_TAG}.tar.gz`,
};

/** Human label per channel, for tab/heading reuse by 004. */
export const channelLabels: Record<InstallChannel, string> = {
  curl: 'curl / irm (bootstrap)',
  npm: 'npm',
  pypi: 'PyPI (pipx)',
  offline: 'Offline bundle',
};
```

Notes:
- The raw version comes entirely from feature-002's `getAidVersion()` (single source); env/cwd/
  `VERSION`-path resolution concerns live in that accessor, not here. The cwd/`VERSION`-path
  caveat is tracked against feature-002 in A3.
- The exported **public API for consumers is: `VERSION`, `VERSION_TAG`, `installCommands`,
  `channelLabels`, the `InstallChannel` type, plus the `<InstallCommand>` and `<VersionBadge>`
  components below.** Consumers should prefer the components; `VERSION`/`installCommands` are the
  escape hatch for bespoke prose.

### Components — `site/src/components/`

**`InstallCommand.astro`** — renders one channel's current, version-pinned command as a
copy-pasteable code block.

```astro
---
// site/src/components/InstallCommand.astro
import { Code } from '@astrojs/starlight/components';
import { installCommands, type InstallChannel } from '../data/version';

interface Props {
  /** Which install channel's command to render. */
  channel: InstallChannel;        // 'curl' | 'npm' | 'pypi' | 'offline'
  /** Override the syntax-highlight language (default per channel). */
  lang?: string;
}
const { channel, lang } = Astro.props;
const code = installCommands[channel];
const language = lang ?? 'bash';
---
<Code code={code} lang={language} />
```

Usage (this is the **consumer contract for 003 and 004**):

```mdx
import InstallCommand from '../../components/InstallCommand.astro';

<InstallCommand channel="curl" />     {/* feature-003 home one-liner */}
<InstallCommand channel="npm" />      {/* feature-004 npm channel  */}
<InstallCommand channel="pypi" />     {/* feature-004 PyPI channel */}
<InstallCommand channel="offline" />  {/* feature-004 offline channel */}
```

- 003 renders **one** `<InstallCommand channel="curl" />` for the home hero one-liner.
- 004 renders **all four** channels (its per-channel tabbed blocks wrap these components).
- The version interpolation happens entirely inside `version.ts`; consumers pass only `channel`.

**`VersionBadge.astro`** — the version badge for the header/hero (AC13).

```astro
---
// site/src/components/VersionBadge.astro
import { VERSION } from '../data/version';
interface Props {
  /** Prefix label, default "v". e.g. renders "v1.0.0". */
  prefix?: string;
  /**
   * Optional link target. Feature-008 does NOT own any route and sets no default:
   * the consumer (e.g. the page/feature using the badge) passes the target. When
   * omitted, the badge renders as plain text with no link.
   */
  href?: string;
}
const { prefix = 'v', href } = Astro.props;
const label = `${prefix}${VERSION}`;
---
{href
  ? <a class="version-badge" href={href}>{label}</a>
  : <span class="version-badge">{label}</span>}
```

Styling uses the casulo accent tokens already defined in `site/src/styles/casulo.css`
(feature-001) — the badge adds a `.version-badge` rule (small pill, `--sl-color-accent`
border/text); no new color tokens. The badge plugs into the **`Hero`/content slot reserved by
feature-001** for FR15. `href` is an optional prop with **no default route** (feature-008 owns no
routes): a consumer that wants the badge linked passes its own target — e.g. feature-003's hero
could embed `<VersionBadge href={releasesHref} />`, or `<VersionBadge />` to render it unlinked.
It may also be used inline in any MDX page.

### Refresh on release (AC15 — version/install slice)

No work is required here at release time beyond the binding existing:

1. Maintainer publishes a GitHub Release (the existing `release.sh`/`release.yml` flow — unchanged).
2. Feature-002's deploy workflow triggers on `release: published`, sets `AID_VERSION` (CONTRACT),
   and runs `astro build`.
3. `version.ts` reads the new version once via `getAidVersion()` (feature-002); `<VersionBadge>`
   and every `<InstallCommand>` on every page re-render with the new version baked into static HTML.
4. The site redeploys. **No hand-edit, no change to `release.yml`.** (AC15 version/install portion.)

Because `VERSION` is also bumped as part of the release, even a non-CI / local rebuild produces
the current value via `getAidVersion()`'s `VERSION`-file fallback (feature-002).

### File / Directory Tree (additions to `site/`, all new)

```
site/
└── src/
    ├── data/
    │   └── version.ts            # version-injection layer: VERSION (= getAidVersion()),
    │                             #   VERSION_TAG, installCommands, channelLabels, InstallChannel  [THIS FEATURE]
    │                             #   (raw version sourced from feature-002's release-data.ts)
    └── components/
        ├── InstallCommand.astro  # <InstallCommand channel=… />  (003 + 004 consume)  [THIS FEATURE]
        └── VersionBadge.astro    # <VersionBadge prefix? href? />  (badge, hero)      [THIS FEATURE]
```

Plus a small `.version-badge` rule appended to feature-001's `site/src/styles/casulo.css`
(no new tokens; uses existing casulo accent variables).

### Feature Boundaries

| Concern | Owner | This feature |
|---------|-------|--------------|
| `release: published` trigger, `AID_VERSION` env / data-fetch, `getAidVersion()` accessor, `release.yml` (unchanged) | feature-002 | imports `getAidVersion()`; consumes the `AID_VERSION` resolution it provides; needs no workflow change |
| Home hero install one-liner (FR3) | feature-003 | provides `<InstallCommand channel="curl" />` + `<VersionBadge>` for it to embed |
| Install guide, all four channels + per-tool tabs (FR5) | feature-004 | provides `<InstallCommand>` for all four channels; 004 owns the surrounding tabs/copy |
| Releases page from GitHub Releases API, per-release assets (FR10) | feature-009 | not in scope (D7); badge may link to the Releases page |
| Announcement banner (FR16) | feature-009 | not in scope |
| Theme tokens, nav, build config | feature-001 / feature-002 | reuses existing tokens; adds no config |

### Acceptance Criteria Coverage

| AC | How this feature satisfies it |
|----|-------------------------------|
| AC13 — badge + all four one-liners show latest, matching `VERSION`/latest release | `version.ts` sets `VERSION = getAidVersion()` (feature-002's accessor) once at build; `<VersionBadge>` + `<InstallCommand channel="curl\|npm\|pypi\|offline" />` interpolate it. Verify at build: once `site/` is built, `<VersionBadge>` and all four `<InstallCommand>` channels render the resolved `VERSION` (currently `1.0.0` per the `VERSION` file). |
| AC13 — 003/004 consume the injected value, not hard-coded | 003/004 import the components and pass only `channel`; no version literal in their files (consumer contract above). |
| AC15 (version/install portion) — rebuild on `release: published` updates badge + commands, no manual steps, no `release.yml` change | Refresh flow above; this feature adds no workflow steps and edits no release file. |
| §4/§7 — read at build time, no runtime backend | D2/D3: `getAidVersion()` (feature-002) resolves env-or-`VERSION`-file at import time during `astro build`; the value is inlined into static HTML; nothing shipped to the browser; no client fetch. |

### Assumptions & Open Questions

- **A1 (env var name — spot-check feature-002):** this spec assumes `getAidVersion()` reads
  **`AID_VERSION`**, matching the existing CLI's own pinned-bootstrap env var (`docs/install.md`
  line 203). Confirm feature-002's accessor uses exactly this name; if it picks another
  (e.g. `SITE_VERSION`), that is fully internal to `getAidVersion()` — feature-008 needs no change.
- **A2 (version string shape — spot-check feature-002):** assumed bare semver `1.0.0` (no leading
  `v`). Confirm feature-002's `getAidVersion()` emits the bare form, stripping any leading `v`
  defensively (the `VERSION` file currently holds `1.0.0`). Normalization is the accessor's job.
- **A3 (build cwd / `VERSION` path):** the `VERSION`-file fallback inside `getAidVersion()`
  resolves the repo-root `VERSION` relative to the build cwd, assuming the build runs from `site/`
  (feature-001 D2 layout). In CI the `AID_VERSION` env path is authoritative and removes this
  dependency; confirm with feature-002 that its build step `cd site` (or sets `AID_VERSION`) so the
  fallback path is never the sole resolver in CI. This caveat now lives entirely in feature-002.
- **A4 (offline command example tool):** the offline one-liner uses `aid-claude-code-vX.Y.Z.tar.gz`
  as the example asset (matching `docs/install.md`), since offline is per-tool. Feature-004 may
  present multiple tools; if so, `<InstallCommand channel="offline" />` shows the representative
  claude-code asset and 004 documents the `aid-<tool>-v<version>.tar.gz` pattern around it. The
  per-release **asset link list** (all tools) is feature-009's GitHub-Releases-API job, not FR15.
- **A5 (Code component import path):** `<InstallCommand>` uses Starlight's `<Code>` from
  `@astrojs/starlight/components` for copy-button + syntax highlight; confirm against the pinned
  Starlight version (feature-001 D1). A fenced-code-block fallback exists if the component path
  differs in the pinned version.
