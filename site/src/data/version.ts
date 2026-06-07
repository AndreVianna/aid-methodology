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

export type InstallChannel = 'curl' | 'irm' | 'npm' | 'pypi' | 'offline';

/**
 * Version-pinned, copy-pasteable install commands, one per channel.
 * Command shapes are sourced from docs/install.md (single content source, D6).
 * Each is the *pinned* form so the rendered command always shows the current version.
 */
export const installCommands: Record<InstallChannel, string> = {
  curl:
    `curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- --version ${VERSION}`,
  // Windows PowerShell bootstrap. irm … | iex cannot forward args, so the pinned
  // version is supplied via $env:AID_VERSION (docs/install.md "Pinned-version
  // bootstrap", lines 202-204). Two PowerShell statements, one per line.
  irm:
    `$env:AID_VERSION = '${VERSION}'\nirm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex`,
  npm:
    `npm i -g aid-installer@${VERSION}`,
  pypi:
    `pipx install aid-installer==${VERSION}`,
  offline:
    `curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/${VERSION_TAG}/aid-claude-code-${VERSION_TAG}.tar.gz`,
};

/** Human label per channel, for tab/heading reuse by 004. */
export const channelLabels: Record<InstallChannel, string> = {
  curl: 'curl (Linux / macOS)',
  irm: 'irm (Windows PowerShell)',
  npm: 'npm',
  pypi: 'PyPI (pipx)',
  offline: 'Offline bundle',
};
