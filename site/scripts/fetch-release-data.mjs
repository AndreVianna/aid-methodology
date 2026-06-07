#!/usr/bin/env node
// fetch-release-data.mjs — Build-time release data fetcher (CI pre-build step).
//
// Usage (in CI, step output appended to $GITHUB_ENV):
//   node site/scripts/fetch-release-data.mjs >> "$GITHUB_ENV"
//
// Emits three single-line KEY=value lines for $GITHUB_ENV:
//   AID_VERSION            — bare semver from VERSION file (e.g. "1.0.0")
//   AID_LATEST_RELEASE_JSON — single-line JSON | empty string on failure
//   AID_RELEASES_JSON      — single-line JSON array | empty string on failure
//
// Degrades gracefully: any API failure emits VERSION-derived fields +
// empty release fields and exits 0 (build never fails for lack of release data).
//
// Contract shape (owned here; feature-008 and feature-009 are consumers):
//   Release: { tag, name, url, publishedAt, body?, assets: [{ name, url }] }

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
// VERSION file is at the repo root (two levels up from site/scripts/)
const VERSION_PATH = resolve(__dirname, '../../VERSION');
// Build-time data file consumed by src/lib/release-data.ts as a fallback when the
// AID_* env vars are not set (i.e. a plain local `npm run build`). Script-relative
// so the path is stable regardless of the process cwd. Resolves to site/.release-data.json.
const DATA_FILE = resolve(__dirname, '..', '.release-data.json');

// ── Read VERSION ─────────────────────────────────────────────────────────────

export function readVersion() {
  try {
    const raw = readFileSync(VERSION_PATH, 'utf8').trim();
    // Strip a leading 'v' if present
    return raw.replace(/^v/, '');
  } catch (err) {
    console.warn(`[fetch-release-data] WARNING: Could not read VERSION file: ${err.message}`);
    return '';
  }
}

// ── Project GitHub release to contract shape ─────────────────────────────────

export function projectRelease(r) {
  return {
    tag: r.tag_name,
    name: r.name ?? r.tag_name,
    url: r.html_url,
    publishedAt: r.published_at,
    body: r.body ?? '',
    assets: (r.assets ?? []).map((a) => ({
      name: a.name,
      url: a.browser_download_url,
    })),
  };
}

// ── Fetch from GitHub Releases API ──────────────────────────────────────────

async function fetchReleases(owner, repo, token) {
  const headers = {
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const baseUrl = `https://api.github.com/repos/${owner}/${repo}`;

  // Fetch all releases (newest-first from API)
  const allRes = await fetch(`${baseUrl}/releases?per_page=100`, { headers });
  if (!allRes.ok) {
    throw new Error(`GitHub Releases API returned ${allRes.status} ${allRes.statusText}`);
  }
  const allRaw = await allRes.json();

  // Fetch latest release
  const latestRes = await fetch(`${baseUrl}/releases/latest`, { headers });
  if (!latestRes.ok) {
    // Not a fatal error — might have no releases yet
    const latest = allRaw.length > 0 ? allRaw[0] : null;
    const all = allRaw.map(projectRelease);
    return { latest: latest ? projectRelease(latest) : null, all };
  }
  const latestRaw = await latestRes.json();

  return {
    latest: projectRelease(latestRaw),
    // Changelog shows stable releases only — exclude drafts and pre-releases
    // (e.g. the v0.7.x dev pre-releases) so the public history starts at v1.0.0.
    all: allRaw.filter((r) => !r.prerelease && !r.draft).map(projectRelease),
  };
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const version = readVersion();
  const token = process.env.GITHUB_TOKEN ?? '';
  const repoSlug = process.env.GITHUB_REPOSITORY ?? 'AndreVianna/aid-methodology';
  const [owner, repo] = repoSlug.split('/');

  let latestJson = '';
  let allJson = '';

  try {
    const { latest, all } = await fetchReleases(owner, repo, token);
    if (latest) {
      latestJson = JSON.stringify(latest);
    }
    if (all.length > 0) {
      allJson = JSON.stringify(all);
    }
  } catch (err) {
    console.warn(`[fetch-release-data] WARNING: GitHub API call failed — ${err.message}`);
    console.warn('[fetch-release-data] Degrading to empty release fields (build will succeed).');
  }

  // Persist a JSON data file (local fallback path for src/lib/release-data.ts).
  try {
    const fileData = {
      version,
      latest: latestJson ? JSON.parse(latestJson) : null,
      all: allJson ? JSON.parse(allJson) : [],
    };
    writeFileSync(DATA_FILE, JSON.stringify(fileData) + '\n', 'utf8');
    console.warn(`[fetch-release-data] wrote ${DATA_FILE} (version=${version}, releases=${fileData.all.length})`);
  } catch (err) {
    console.warn(`[fetch-release-data] WARNING: could not write data file — ${err.message}`);
  }

  // Emit three KEY=value lines for $GITHUB_ENV (CI consumes stdout via `>> $GITHUB_ENV`).
  // Values must be single-line (no embedded newlines) to be valid GITHUB_ENV entries.
  // Skipped for local runs (no $GITHUB_ENV) to avoid dumping a 20KB JSON line into the
  // build log — the data file written above is the local source instead.
  if (process.env.GITHUB_ENV) {
    console.log(`AID_VERSION=${version}`);
    console.log(`AID_LATEST_RELEASE_JSON=${latestJson}`);
    console.log(`AID_RELEASES_JSON=${allJson}`);
  }
}

// Only run main() when this file is executed directly (not imported by tests).
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.warn(`[fetch-release-data] FATAL: Unexpected error — ${err.message}`);
    console.warn('[fetch-release-data] Emitting empty release data and exiting 0.');
    // Best-effort: emit whatever we can
    const version = readVersion();
    try {
      writeFileSync(DATA_FILE, JSON.stringify({ version, latest: null, all: [] }) + '\n', 'utf8');
    } catch {
      /* ignore */
    }
    if (process.env.GITHUB_ENV) {
      console.log(`AID_VERSION=${version}`);
      console.log('AID_LATEST_RELEASE_JSON=');
      console.log('AID_RELEASES_JSON=');
    }
    process.exit(0);
  });
}
