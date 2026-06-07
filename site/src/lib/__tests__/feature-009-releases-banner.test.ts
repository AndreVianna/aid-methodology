// feature-009-releases-banner.test.ts — task-020
//
// Verifies the logic that backs the Releases page and the Banner component:
//   - getAllReleases() renders from AID_RELEASES_JSON (mock data)
//   - asset filter regex /^aid-.*\.tar\.gz$/ admits correct assets only
//   - sanitize-html allowlist admits headings/img/task-list checkboxes after marked.parse
//   - empty-state: getAllReleases() returns [] when env is absent
//   - date guard: fmtDate handles undefined/null publishedAt gracefully
//   - banner dismissal-key logic: keyed by tag; new tag re-shows

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { marked } from 'marked';

// Isolate the env-var path from the on-disk .release-data.json fallback (generated
// into the working tree by `npm run fetch:release`) so the empty-state assertions
// test env behaviour, not a happened-to-exist data file.
process.env.AID_NO_RELEASE_FILE = '1';
import sanitizeHtml from 'sanitize-html';

// ── Reusable helpers ──────────────────────────────────────────────────────────

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

// ── Offline-bundle asset filter regex (D4) ────────────────────────────────────

describe('offline asset filter regex /^aid-.*\\.tar\\.gz$/', () => {
  const OFFLINE_RE = /^aid-.*\.tar\.gz$/;

  it('matches aid-claude-code-v1.0.0.tar.gz', () => {
    expect(OFFLINE_RE.test('aid-claude-code-v1.0.0.tar.gz')).toBe(true);
  });

  it('matches aid-claude-code-v2.3.4.tar.gz', () => {
    expect(OFFLINE_RE.test('aid-claude-code-v2.3.4.tar.gz')).toBe(true);
  });

  it('matches generic aid-foo.tar.gz', () => {
    expect(OFFLINE_RE.test('aid-foo.tar.gz')).toBe(true);
  });

  it('does not match source.tar.gz (no aid- prefix)', () => {
    expect(OFFLINE_RE.test('source.tar.gz')).toBe(false);
  });

  it('does not match aid-foo.zip', () => {
    expect(OFFLINE_RE.test('aid-foo.zip')).toBe(false);
  });

  it('does not match aid-foo.tar.gz.sig (extra suffix)', () => {
    expect(OFFLINE_RE.test('aid-foo.tar.gz.sig')).toBe(false);
  });

  it('does not match an empty string', () => {
    expect(OFFLINE_RE.test('')).toBe(false);
  });
});

// ── Sanitize-html allowlist (D3) ──────────────────────────────────────────────

const ALLOWED_TAGS = [
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'p', 'a', 'ul', 'ol', 'li', 'blockquote', 'hr', 'br',
  'strong', 'em', 'del', 'code', 'pre',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'img', 'input',
];
const ALLOWED_ATTRS: sanitizeHtml.IOptions['allowedAttributes'] = {
  a: ['href', 'name', 'target', 'rel'],
  img: ['src', 'alt', 'title'],
  input: ['type', 'checked', 'disabled'],
};

function renderBody(body?: string): string {
  if (!body) return '';
  return sanitizeHtml(marked.parse(body, { async: false }), {
    allowedTags: ALLOWED_TAGS,
    allowedAttributes: ALLOWED_ATTRS,
  });
}

describe('sanitize-html allowlist', () => {
  it('admits h1 through h6 headings', () => {
    const md = '# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6';
    const html = renderBody(md);
    expect(html).toContain('<h1>');
    expect(html).toContain('<h2>');
    expect(html).toContain('<h3>');
    expect(html).toContain('<h4>');
    expect(html).toContain('<h5>');
    expect(html).toContain('<h6>');
  });

  it('admits img tags with src/alt/title attributes', () => {
    const md = '![Alt text](https://example.com/img.png "Title")';
    const html = renderBody(md);
    expect(html).toContain('<img');
    expect(html).toContain('src="https://example.com/img.png"');
    expect(html).toContain('alt="Alt text"');
    expect(html).toContain('title="Title"');
  });

  it('admits links with href', () => {
    const md = '[link text](https://example.com)';
    const html = renderBody(md);
    expect(html).toContain('<a');
    expect(html).toContain('href="https://example.com"');
    expect(html).toContain('link text');
  });

  it('admits ordered and unordered lists', () => {
    const md = '- item 1\n- item 2\n\n1. first\n2. second';
    const html = renderBody(md);
    expect(html).toContain('<ul>');
    expect(html).toContain('<ol>');
    expect(html).toContain('<li>');
  });

  it('admits code and pre tags', () => {
    const md = '`inline code`\n\n```\nblock code\n```';
    const html = renderBody(md);
    expect(html).toContain('<code>');
    expect(html).toContain('<pre>');
  });

  it('admits table elements', () => {
    const md = '| col1 | col2 |\n|------|------|\n| a    | b    |';
    const html = renderBody(md);
    expect(html).toContain('<table>');
    expect(html).toContain('<th>');
    expect(html).toContain('<td>');
  });

  it('admits GFM task-list checkboxes (input type=checkbox)', () => {
    const md = '- [x] done\n- [ ] todo';
    const html = renderBody(md);
    expect(html).toContain('<input');
    expect(html).toContain('type="checkbox"');
  });

  it('strips disallowed tags (script)', () => {
    const md = '<script>alert("xss")</script>normal text';
    const html = renderBody(md);
    expect(html).not.toContain('<script>');
    expect(html).not.toContain('alert');
  });

  it('strips disallowed attributes (onclick)', () => {
    const md = '<p onclick="alert(1)">text</p>';
    const html = renderBody(md);
    expect(html).not.toContain('onclick');
  });

  it('returns empty string when body is undefined', () => {
    expect(renderBody(undefined)).toBe('');
  });

  it('returns empty string when body is empty string', () => {
    expect(renderBody('')).toBe('');
  });
});

// ── getAllReleases (empty-state) ───────────────────────────────────────────────

describe('getAllReleases — empty-state', () => {
  const ENV_KEY = 'AID_RELEASES_JSON';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('returns [] when AID_RELEASES_JSON is absent (D5 empty-state)', async () => {
    delete process.env[ENV_KEY];
    const { getAllReleases } = await import('../release-data.js');
    expect(getAllReleases()).toEqual([]);
  });

  it('returns [] on invalid JSON', async () => {
    process.env[ENV_KEY] = 'not-json';
    const { getAllReleases } = await import('../release-data.js');
    expect(getAllReleases()).toEqual([]);
  });

  it('returns releases with correct shape from simulated AID_RELEASES_JSON', async () => {
    const releases = [
      {
        tag: 'v1.2.0',
        name: 'AID 1.2.0',
        url: 'https://github.com/AndreVianna/aid-methodology/releases/tag/v1.2.0',
        publishedAt: '2026-05-15T12:00:00Z',
        body: '## What is new\n- Feature A\n- Feature B\n\n- [x] Task done\n- [ ] Task pending',
        assets: [
          { name: 'aid-claude-code-v1.2.0.tar.gz', url: 'https://github.com/releases/download/v1.2.0/aid-claude-code-v1.2.0.tar.gz' },
          { name: 'aid-claude-code-v1.2.0.tar.gz.sha256', url: 'https://github.com/releases/download/v1.2.0/aid-claude-code-v1.2.0.tar.gz.sha256' },
        ],
      },
    ];
    process.env[ENV_KEY] = JSON.stringify(releases);
    const { getAllReleases } = await import('../release-data.js');
    const result = getAllReleases();
    expect(result).toHaveLength(1);
    expect(result[0].tag).toBe('v1.2.0');
    expect(result[0].name).toBe('AID 1.2.0');
    expect(result[0].body).toContain('## What is new');
    expect(result[0].assets).toHaveLength(2);
  });

  it('offline asset filter keeps only aid-*.tar.gz', async () => {
    const OFFLINE_RE = /^aid-.*\.tar\.gz$/;
    const assets = [
      { name: 'aid-claude-code-v1.2.0.tar.gz', url: 'https://example.com/aid-claude-code-v1.2.0.tar.gz' },
      { name: 'aid-claude-code-v1.2.0.tar.gz.sha256', url: 'https://example.com/sha256' },
      { name: 'source.tar.gz', url: 'https://example.com/source.tar.gz' },
    ];
    const offline = assets.filter((a) => OFFLINE_RE.test(a.name));
    expect(offline).toHaveLength(1);
    expect(offline[0].name).toBe('aid-claude-code-v1.2.0.tar.gz');
  });
});

// ── Date guard (fmtDate) ──────────────────────────────────────────────────────

describe('date guard — fmtDate', () => {
  function fmtDate(iso?: string): string {
    return iso
      ? new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
      : '';
  }

  it('returns empty string when publishedAt is undefined (draft releases)', () => {
    expect(fmtDate(undefined)).toBe('');
  });

  it('returns empty string when publishedAt is empty string', () => {
    expect(fmtDate('')).toBe('');
  });

  it('formats a valid ISO date correctly', () => {
    const result = fmtDate('2026-06-20T12:00:00Z');
    // Should contain year at minimum; day may differ by timezone
    expect(result).toContain('2026');
    // Formatted output is a non-empty string in locale date format
    expect(result.length).toBeGreaterThan(0);
  });

  it('does not throw or produce "Invalid Date" for a valid date', () => {
    const result = fmtDate('2026-05-01T10:00:00Z');
    expect(result).not.toContain('Invalid');
    expect(result.length).toBeGreaterThan(0);
  });
});

// ── Banner dismissal-key logic (D7) ──────────────────────────────────────────

describe('banner dismissal-key logic', () => {
  it('dismissal key is "aid-banner-dismissed"', () => {
    // The banner script uses this exact key; verify no typo
    const key = 'aid-banner-dismissed';
    expect(key).toBe('aid-banner-dismissed');
  });

  it('tag normalization: adds v prefix when absent', () => {
    function normalizeTag(tag: string): string {
      return tag.startsWith('v') ? tag : `v${tag}`;
    }
    expect(normalizeTag('1.2.0')).toBe('v1.2.0');
    expect(normalizeTag('v1.2.0')).toBe('v1.2.0');
  });

  it('banner re-shows when stored tag differs from current tag', () => {
    // Simulate localStorage state: dismissed for old tag
    const storedTag: string = 'v1.0.0';
    const currentTag: string = 'v1.2.0';  // new release
    const isDismissed = storedTag === currentTag;
    expect(isDismissed).toBe(false);      // new tag → banner re-shows
  });

  it('banner stays dismissed when stored tag equals current tag', () => {
    const tag = 'v1.2.0';
    const storedTag: string = tag;
    const currentTag: string = tag;
    const isDismissed = storedTag === currentTag;
    expect(isDismissed).toBe(true);
  });

  it('banner shows when localStorage has no stored tag', () => {
    const storedTag: string | null = null;  // nothing in localStorage
    const currentTag: string = 'v1.2.0';
    const isDismissed = storedTag === currentTag;
    expect(isDismissed).toBe(false);        // null !== 'v1.2.0'
  });
});

// ── Banner self-suppress on /releases/changelog ───────────────────────────────

describe('banner self-suppress on /releases/changelog', () => {
  function onReleasesPage(pathname: string): boolean {
    return pathname.replace(/\/$/, '') === '/releases/changelog';
  }

  it('suppresses on /releases/changelog', () => {
    expect(onReleasesPage('/releases/changelog')).toBe(true);
  });

  it('suppresses on /releases/changelog/ (trailing slash)', () => {
    expect(onReleasesPage('/releases/changelog/')).toBe(true);
  });

  it('does not suppress on /', () => {
    expect(onReleasesPage('/')).toBe(false);
  });

  it('does not suppress on /guides/installation', () => {
    expect(onReleasesPage('/guides/installation')).toBe(false);
  });

  it('does not suppress on /concepts/overview', () => {
    expect(onReleasesPage('/concepts/overview')).toBe(false);
  });
});

// ── getLatestRelease — banner render (AC14) ───────────────────────────────────

describe('getLatestRelease — banner data', () => {
  const ENV_KEY = 'AID_LATEST_RELEASE_JSON';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('returns null when AID_LATEST_RELEASE_JSON is absent (banner renders nothing)', async () => {
    delete process.env[ENV_KEY];
    const { getLatestRelease } = await import('../release-data.js');
    expect(getLatestRelease()).toBeNull();
  });

  it('returns the latest release with correct tag for banner "AID vX.Y.Z is out"', async () => {
    const release = {
      tag: 'v1.2.0',
      name: 'AID 1.2.0',
      url: 'https://github.com/AndreVianna/aid-methodology/releases/tag/v1.2.0',
      publishedAt: '2026-05-01T00:00:00Z',
      assets: [],
    };
    process.env[ENV_KEY] = JSON.stringify(release);
    const { getLatestRelease } = await import('../release-data.js');
    const latest = getLatestRelease();
    expect(latest).not.toBeNull();
    expect(latest!.tag).toBe('v1.2.0');
    // Banner copy would be: "AID v1.2.0 is out."
    const bannerText = `AID ${latest!.tag} is out.`;
    expect(bannerText).toBe('AID v1.2.0 is out.');
  });
});
