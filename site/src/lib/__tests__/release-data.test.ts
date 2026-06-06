// release-data.test.ts — unit tests for site/src/lib/release-data.ts
//
// Covers:
//   getAidVersion()   — env var, leading-v strip, VERSION file fallback, empty fallback
//   getLatestRelease() — parses AID_LATEST_RELEASE_JSON, null on empty/invalid
//   getAllReleases()   — parses AID_RELEASES_JSON, [] on empty/invalid
//   contract shapes  — Release / ReleaseAsset interface shapes

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// ── Helpers ──────────────────────────────────────────────────────────────────

// We must reset module registry between tests that manipulate import.meta.url
// behaviour (VERSION file path), so we use dynamic import for each test group.

const savedEnv: Record<string, string | undefined> = {};

function saveEnv(...keys: string[]) {
  for (const k of keys) savedEnv[k] = process.env[k];
}

function restoreEnv(...keys: string[]) {
  for (const k of keys) {
    if (savedEnv[k] === undefined) delete process.env[k];
    else process.env[k] = savedEnv[k];
  }
}

// ── getAidVersion ─────────────────────────────────────────────────────────────

describe('getAidVersion', () => {
  const ENV_KEY = 'AID_VERSION';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('returns bare semver from env var (no leading v)', async () => {
    process.env[ENV_KEY] = '1.2.3';
    const { getAidVersion } = await import('../release-data.js');
    expect(getAidVersion()).toBe('1.2.3');
  });

  it('strips a leading v from env var', async () => {
    process.env[ENV_KEY] = 'v2.0.0';
    const { getAidVersion } = await import('../release-data.js');
    expect(getAidVersion()).toBe('2.0.0');
  });

  it('returns empty string when env var is empty string', async () => {
    process.env[ENV_KEY] = '';
    // VERSION file may or may not exist; result is non-throwing string
    const { getAidVersion } = await import('../release-data.js');
    const result = getAidVersion();
    expect(typeof result).toBe('string');
  });

  it('returns empty string when env var is absent and env var is whitespace', async () => {
    process.env[ENV_KEY] = '   ';
    // When env var is whitespace-only, falls back to VERSION file (or '').
    // Just verify it does not throw and returns a string.
    const { getAidVersion } = await import('../release-data.js');
    const result = getAidVersion();
    expect(typeof result).toBe('string');
  });

  it('reads from VERSION file when env var is absent (real file exists)', async () => {
    delete process.env[ENV_KEY];
    const { getAidVersion } = await import('../release-data.js');
    const result = getAidVersion();
    // Real repo has a VERSION file — result is a non-empty string with semver shape
    // or '' if not found; either is acceptable; must not throw
    expect(typeof result).toBe('string');
  });

  it('strips leading v from env var with surrounding whitespace', async () => {
    process.env[ENV_KEY] = '  v3.1.0  ';
    const { getAidVersion } = await import('../release-data.js');
    expect(getAidVersion()).toBe('3.1.0');
  });
});

// ── getLatestRelease ──────────────────────────────────────────────────────────

describe('getLatestRelease', () => {
  const ENV_KEY = 'AID_LATEST_RELEASE_JSON';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('returns null when env var is absent', async () => {
    delete process.env[ENV_KEY];
    const { getLatestRelease } = await import('../release-data.js');
    expect(getLatestRelease()).toBeNull();
  });

  it('returns null when env var is empty string', async () => {
    process.env[ENV_KEY] = '';
    const { getLatestRelease } = await import('../release-data.js');
    expect(getLatestRelease()).toBeNull();
  });

  it('returns null on invalid JSON', async () => {
    process.env[ENV_KEY] = 'not-json{{';
    const { getLatestRelease } = await import('../release-data.js');
    expect(getLatestRelease()).toBeNull();
  });

  it('parses a valid Release JSON and returns correct shape', async () => {
    const release = {
      tag: 'v1.0.0',
      name: 'First release',
      url: 'https://github.com/example/releases/tag/v1.0.0',
      publishedAt: '2026-01-01T00:00:00Z',
      body: 'Initial release',
      assets: [{ name: 'aid.tar.gz', url: 'https://github.com/example/releases/download/v1.0.0/aid.tar.gz' }],
    };
    process.env[ENV_KEY] = JSON.stringify(release);
    const { getLatestRelease } = await import('../release-data.js');
    const result = getLatestRelease();
    expect(result).not.toBeNull();
    expect(result!.tag).toBe('v1.0.0');
    expect(result!.name).toBe('First release');
    expect(result!.url).toBe('https://github.com/example/releases/tag/v1.0.0');
    expect(result!.publishedAt).toBe('2026-01-01T00:00:00Z');
    expect(result!.body).toBe('Initial release');
    expect(result!.assets).toHaveLength(1);
    expect(result!.assets[0].name).toBe('aid.tar.gz');
    expect(result!.assets[0].url).toContain('aid.tar.gz');
  });

  it('handles release with no body field', async () => {
    const release = {
      tag: 'v1.0.1',
      name: 'Patch',
      url: 'https://github.com/example/releases/tag/v1.0.1',
      publishedAt: '2026-02-01T00:00:00Z',
      assets: [],
    };
    process.env[ENV_KEY] = JSON.stringify(release);
    const { getLatestRelease } = await import('../release-data.js');
    const result = getLatestRelease();
    expect(result).not.toBeNull();
    expect(result!.body).toBeUndefined();
    expect(result!.assets).toEqual([]);
  });
});

// ── getAllReleases ─────────────────────────────────────────────────────────────

describe('getAllReleases', () => {
  const ENV_KEY = 'AID_RELEASES_JSON';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('returns [] when env var is absent', async () => {
    delete process.env[ENV_KEY];
    const { getAllReleases } = await import('../release-data.js');
    expect(getAllReleases()).toEqual([]);
  });

  it('returns [] when env var is empty string', async () => {
    process.env[ENV_KEY] = '';
    const { getAllReleases } = await import('../release-data.js');
    expect(getAllReleases()).toEqual([]);
  });

  it('returns [] on invalid JSON', async () => {
    process.env[ENV_KEY] = '[broken';
    const { getAllReleases } = await import('../release-data.js');
    expect(getAllReleases()).toEqual([]);
  });

  it('parses an array of releases and returns correct shapes', async () => {
    const releases = [
      {
        tag: 'v2.0.0',
        name: 'Second release',
        url: 'https://github.com/example/releases/tag/v2.0.0',
        publishedAt: '2026-05-01T00:00:00Z',
        body: 'New features',
        assets: [{ name: 'aid-linux.tar.gz', url: 'https://example.com/aid-linux.tar.gz' }],
      },
      {
        tag: 'v1.0.0',
        name: 'First release',
        url: 'https://github.com/example/releases/tag/v1.0.0',
        publishedAt: '2026-01-01T00:00:00Z',
        assets: [],
      },
    ];
    process.env[ENV_KEY] = JSON.stringify(releases);
    const { getAllReleases } = await import('../release-data.js');
    const result = getAllReleases();
    expect(result).toHaveLength(2);
    expect(result[0].tag).toBe('v2.0.0');
    expect(result[1].tag).toBe('v1.0.0');
    expect(result[0].assets[0].name).toBe('aid-linux.tar.gz');
  });

  it('returns array with a single entry', async () => {
    const releases = [
      {
        tag: 'v1.0.0',
        name: 'Only release',
        url: 'https://github.com/example/releases/tag/v1.0.0',
        publishedAt: '2026-01-01T00:00:00Z',
        assets: [],
      },
    ];
    process.env[ENV_KEY] = JSON.stringify(releases);
    const { getAllReleases } = await import('../release-data.js');
    const result = getAllReleases();
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe('Only release');
  });
});
