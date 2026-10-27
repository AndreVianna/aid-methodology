// Build-output checks (B1-B5). Each case reads the existing dist/; run `npm run build` first.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { DIST, REPO, SITE, builtPages } from './dist.mjs';

const read = (...p) => readFileSync(join(DIST, ...p), 'utf8');
const dirs = (dir) => readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).length;

/** URLs of the pages under src/content/docs/: extension dropped, trailing index dropped. */
function expectedUrls() {
  const root = join(SITE, 'src', 'content', 'docs');
  const out = [];
  const walk = (dir, rel) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory()) walk(join(dir, e.name), [...rel, e.name]);
      else if (/\.mdx?$/.test(e.name)) {
        const parts = [...rel, e.name.replace(/\.mdx?$/, '')];
        if (parts[parts.length - 1] === 'index') parts.pop();
        out.push(parts.length ? '/' + parts.join('/') + '/' : '/');
      }
    }
  };
  walk(root, []);
  return out;
}

describe('build output', () => {
  it('B1 the built pages are exactly the pages of src/content/docs', () => {
    expect(existsSync(join(DIST, 'index.html'))).toBe(true);
    expect(existsSync(join(DIST, '404.html'))).toBe(true);
    const built = new Set(builtPages().filter((p) => p.redirectTo === null && p.url !== '/404.html').map((p) => p.url));
    const expected = new Set(expectedUrls());
    const missing = [...expected].filter((u) => !built.has(u)).sort();
    const extra = [...built].filter((u) => !expected.has(u)).sort();
    expect({ missing, extra }).toEqual({ missing: [], extra: [] });
  });

  it('B2 the kept site functions are present', () => {
    for (const f of ['pagefind/pagefind.js', 'sitemap-index.xml', 'favicon.svg']) {
      expect(existsSync(join(DIST, f)), f).toBe(true);
    }
    expect(read('robots.txt')).toContain('Sitemap: https://aid.casuloailabs.com/sitemap-index.xml');
    expect(read('CNAME').trim()).toBe('aid.casuloailabs.com');
  });

  it('B3 the version from VERSION is displayed', () => {
    const v = readFileSync(join(REPO, 'VERSION'), 'utf8').trim().replace(/^v/, '');
    expect(read('index.html')).toContain(`v${v}`);
    const changelog = read('releases', 'changelog', 'index.html');
    expect(changelog).toContain(`v${v}`);
    expect(changelog).toContain('href="https://github.com/AndreVianna/aid-methodology/releases"');
  });

  it('B4 the contact pages hold a GET form or a mailto link', () => {
    for (const name of ['site-issue', 'methodology-bug', 'feedback']) {
      const html = read('contact', name, 'index.html');
      expect(html.match(/<form\b/g) ?? [], `${name}: form count`).toHaveLength(1);
      const tag = /<form\b[^>]*>/.exec(html)[0];
      expect(tag, `${name}: method`).toMatch(/method="get"/);
      expect(tag, `${name}: enctype`).not.toMatch(/enctype/);
      expect(tag, `${name}: action`).toContain('action="https://github.com/AndreVianna/aid-methodology/issues/new"');
    }
    const request = read('contact', 'contact-request', 'index.html');
    expect(request).not.toMatch(/<form\b/);
    const mailto = (request.match(/<a\b[^>]*>/g) ?? []).map((t) => /href="(mailto:[^"]*)"/.exec(t)?.[1]).filter(Boolean);
    expect(mailto.length, 'mailto link count').toBeGreaterThan(0);
    for (const href of mailto) {
      expect(href).toContain('subject=AID%3A%20request');
      expect(href).not.toContain('+');
    }
  });

  it('B5 one skill page folder per canonical skill', () => {
    expect(dirs(join(DIST, 'skills'))).toBe(dirs(join(REPO, 'canonical', 'skills')));
  });
});
