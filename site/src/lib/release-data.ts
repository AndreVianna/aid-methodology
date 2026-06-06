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
  return readVersionFile();
}

/**
 * Returns the latest GitHub Release projected to the contract shape, or null
 * if unavailable (API failure, local dev, or no releases published yet).
 */
export function getLatestRelease(): Release | null {
  return safeParseJson<Release | null>(
    process.env['AID_LATEST_RELEASE_JSON'],
    null
  );
}

/**
 * Returns all GitHub Releases projected to the contract shape, newest-first.
 * Returns an empty array if unavailable.
 */
export function getAllReleases(): Release[] {
  return safeParseJson<Release[]>(
    process.env['AID_RELEASES_JSON'],
    []
  );
}
