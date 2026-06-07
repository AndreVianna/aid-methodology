// release-data.ts — ONE canonical accessor for build-time release data.
//
// Consuming features import from here; they do NOT read process.env directly.
//   feature-008: getAidVersion() for the version badge + install one-liners
//   feature-009: getLatestRelease() (banner) + getAllReleases() (changelog page)
//
// These vars are non-PUBLIC_ build-time vars; Vite/Astro only expose PUBLIC_-
// prefixed vars on import.meta.env.  This module reads process.env directly
// (runs in Node during Astro SSG build where $GITHUB_ENV values are present).
//
// Contract shape (defined by fetch-release-data.mjs):
//   Release: { tag, name, url, publishedAt, body?, assets: [{ name, url }] }

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// ── Interfaces ────────────────────────────────────────────────────────────────

export interface ReleaseAsset {
  name: string;
  url: string;
}

export interface Release {
  tag: string;
  name: string;
  url: string;
  publishedAt: string;
  body?: string;
  assets: ReleaseAsset[];
}

// ── Internal helpers ──────────────────────────────────────────────────────────

function stripLeadingV(s: string): string {
  return s.replace(/^v/, '');
}

function readVersionFile(): string {
  // During Astro SSG, import.meta.url may resolve to a Vite-bundled location
  // rather than the original source path. We probe multiple candidate paths:
  //   1. Three levels up from import.meta.url (dev / Vitest: site/src/lib/ → repo root)
  //   2. One level up from process.cwd() (Astro build runs from site/; repo root is ../VERSION)
  //   3. process.cwd() itself (in case the build runs from the repo root)
  const candidates: string[] = [];

  // Candidate 1: import.meta.url-based (works in dev and Vitest)
  try {
    const moduleDir = dirname(fileURLToPath(import.meta.url));
    candidates.push(resolve(moduleDir, '../../../VERSION'));
  } catch {
    // fileURLToPath may fail for virtual/data URLs; skip
  }

  // Candidate 2: cwd-based (works when Astro SSG build runs from site/ directory)
  candidates.push(resolve(process.cwd(), '../VERSION'));

  // Candidate 3: cwd itself as repo root
  candidates.push(resolve(process.cwd(), 'VERSION'));

  for (const candidate of candidates) {
    try {
      const raw = readFileSync(candidate, 'utf8').trim();
      if (raw) return stripLeadingV(raw);
    } catch {
      // Try next candidate
    }
  }

  return '';
}

function safeParseJson<T>(raw: string | undefined, fallback: T): T {
  if (!raw || raw.trim() === '') return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

// ── Local data-file fallback ───────────────────────────────────────────────────
// CI sets the AID_* env vars (via fetch-release-data.mjs → $GITHUB_ENV). A plain
// local `npm run build` does not, so we also read site/.release-data.json, which the
// prebuild step (npm run fetch:release) writes. Env vars take priority; this is the
// fallback. Cached after first read.

interface ReleaseDataFile {
  version?: string;
  latest?: Release | null;
  all?: Release[];
}

let _fileCache: ReleaseDataFile | null | undefined;

function readReleaseDataFile(): ReleaseDataFile | null {
  // Opt-out hook (used by unit tests to isolate the env-var path from the
  // on-disk fallback, which is otherwise present in the working tree).
  if (process.env['AID_NO_RELEASE_FILE'] === '1') return null;
  if (_fileCache !== undefined) return _fileCache;
  const candidates: string[] = [];
  try {
    const moduleDir = dirname(fileURLToPath(import.meta.url));
    candidates.push(resolve(moduleDir, '../../.release-data.json')); // src/lib → site/
  } catch {
    /* virtual URL; skip */
  }
  candidates.push(resolve(process.cwd(), '.release-data.json')); // cwd = site/
  candidates.push(resolve(process.cwd(), 'site/.release-data.json')); // cwd = repo root
  for (const c of candidates) {
    try {
      const raw = readFileSync(c, 'utf8');
      if (raw.trim()) {
        _fileCache = JSON.parse(raw) as ReleaseDataFile;
        return _fileCache;
      }
    } catch {
      /* try next candidate */
    }
  }
  _fileCache = null;
  return _fileCache;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Returns the current AID version as a bare semver string (no leading 'v').
 *
 * Resolution order:
 *   1. process.env.AID_VERSION (set by fetch-release-data.mjs in CI)
 *   2. Repo-root VERSION file (fallback for local dev with no env var)
 *   3. '' if neither is available
 */
export function getAidVersion(): string {
  const fromEnv = process.env['AID_VERSION'];
  if (fromEnv && fromEnv.trim() !== '') {
    return stripLeadingV(fromEnv.trim());
  }
  const file = readReleaseDataFile();
  if (file && file.version && file.version.trim() !== '') {
    return stripLeadingV(file.version.trim());
  }
  return readVersionFile();
}

/**
 * Returns the latest GitHub Release projected to the contract shape, or null
 * if unavailable (API failure, local dev, or no releases published yet).
 */
export function getLatestRelease(): Release | null {
  const fromEnv = safeParseJson<Release | null>(process.env['AID_LATEST_RELEASE_JSON'], null);
  if (fromEnv) return fromEnv;
  const file = readReleaseDataFile();
  return file && file.latest ? file.latest : null;
}

/**
 * Returns all GitHub Releases projected to the contract shape, newest-first.
 * Returns an empty array if unavailable.
 */
export function getAllReleases(): Release[] {
  const fromEnv = safeParseJson<Release[] | null>(process.env['AID_RELEASES_JSON'], null);
  if (fromEnv && fromEnv.length > 0) return fromEnv;
  const file = readReleaseDataFile();
  return file && Array.isArray(file.all) ? file.all : [];
}
