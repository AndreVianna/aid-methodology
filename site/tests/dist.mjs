// Shared helper for the tests that read the built site (dist/). Node built-ins only.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

export const SITE = fileURLToPath(new URL('..', import.meta.url));
export const REPO = fileURLToPath(new URL('../..', import.meta.url));
export const DIST = join(SITE, 'dist');

/**
 * @typedef {{ file: string, url: string, html: string, redirectTo: string|null }} BuiltPage
 * url: '/' for dist/index.html, '/a/b/' for dist/a/b/index.html, '/404.html' for dist/404.html.
 * redirectTo: the url of a <meta http-equiv="refresh" content="N;url=..."> (Astro's redirect
 * pages), else null.
 */

/** Sorted recursive list of the .html files under dir. */
function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir).sort()) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walk(full));
    else if (name.endsWith('.html')) out.push(full);
  }
  return out;
}

/** Decode the HTML entities an attribute value may carry. */
function decodeEntities(value) {
  return value.replace(/&amp;/g, '&').replace(/&#38;/g, '&').replace(/&quot;/g, '"');
}

/** The target of a meta refresh in html, entity-decoded, or null. */
function metaRefreshTarget(html) {
  for (const tag of html.match(/<meta\b[^>]*>/gi) ?? []) {
    if (!/http-equiv\s*=\s*["']?refresh["']?/i.test(tag)) continue;
    const content = /content\s*=\s*(?:"([^"]*)"|'([^']*)')/i.exec(tag);
    if (!content) continue;
    const target = /url\s*=\s*(.+)$/i.exec(decodeEntities(content[1] ?? content[2]).trim());
    if (target) return target[1].trim();
  }
  return null;
}

/** @returns {BuiltPage[]} */
export function builtPages(dist = DIST) {
  if (!existsSync(join(dist, 'index.html'))) {
    throw new Error('dist/index.html is missing: run npm run build first');
  }
  return walk(dist).map((file) => {
    const rel = file.slice(dist.length + 1).split(sep).join('/');
    let url;
    if (rel === 'index.html') url = '/';
    else if (rel.endsWith('/index.html')) url = '/' + rel.slice(0, -'index.html'.length);
    else url = '/' + rel;
    const html = readFileSync(file, 'utf8');
    return { file, url, html, redirectTo: metaRefreshTarget(html) };
  });
}

/** @returns {string[]} */
export function findBrokenLinks(dist = DIST) {
  const pages = builtPages(dist);
  const byFile = new Map(pages.map((p) => [p.file, p]));
  const broken = [];

  const isFile = (f) => existsSync(f) && statSync(f).isFile();
  const locate = (path) => {
    const candidates = path.endsWith('/')
      ? [join(dist, path, 'index.html')]
      : [join(dist, path), join(dist, path, 'index.html')];
    return candidates.find(isFile) ?? null;
  };
  const hasAnchor = (html, frag) =>
    [`id="${frag}"`, `name="${frag}"`, `id='${frag}'`, `name='${frag}'`].some((s) => html.includes(s));
  const decode = (s) => {
    try {
      return decodeURIComponent(s);
    } catch {
      return s;
    }
  };

  for (const page of pages) {
    const values = [];
    const attr = /(?<![\w-])(?:href|src)\s*=\s*(?:"([^"]*)"|'([^']*)')/gi;
    for (const m of page.html.matchAll(attr)) values.push(decodeEntities(m[1] ?? m[2]));
    if (page.redirectTo !== null) values.push(page.redirectTo);

    for (const value of values) {
      if (/^[a-z][a-z0-9+.-]*:/i.test(value) || value.startsWith('//')) continue;
      let resolved;
      try {
        resolved = new URL(value, 'http://site.invalid' + page.url);
      } catch {
        continue;
      }
      const file = locate(decode(resolved.pathname));
      if (!file) {
        broken.push(`${page.url} -> ${value} (no such page)`);
        continue;
      }
      const frag = decode(resolved.hash.replace(/^#/, ''));
      if (!frag || !file.endsWith('.html')) continue;
      let target = byFile.get(file);
      let html = target ? target.html : readFileSync(file, 'utf8');
      if (target && target.redirectTo !== null) {
        const next = new URL(target.redirectTo, 'http://site.invalid' + target.url);
        const nextFile = locate(decode(next.pathname));
        if (nextFile) html = byFile.get(nextFile)?.html ?? readFileSync(nextFile, 'utf8');
      }
      if (!hasAnchor(html, frag)) broken.push(`${page.url} -> ${value} (no such anchor)`);
    }
  }
  return broken;
}
