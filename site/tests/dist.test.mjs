// Checks the built site (run `npm run build` first). Covers what a documentation site
// can get wrong without anyone noticing: broken links, missing page structure and the
// basics of accessibility. Pure Node plus one small HTML parser.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'node-html-parser';

const SITE = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const DIST = join(SITE, 'dist');
const hasDist = existsSync(DIST);
const skip = hasDist ? false : 'dist/ missing: run `npm run build` first';

function walk(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
}

const pages = new Map(); // url path -> parsed document
if (hasDist) {
  for (const f of walk(DIST).filter((p) => p.endsWith('.html'))) {
    const rel = f.slice(DIST.length).replace(/\\/g, '/').replace(/index\.html$/, '');
    if (rel === '/404.html') continue;
    pages.set(rel, parse(readFileSync(f, 'utf8')));
  }
}

const accessibleName = (el) =>
  (el.getAttribute('aria-label') || el.textContent || '').trim() ||
  el.querySelectorAll('img').map((i) => i.getAttribute('alt') || '').join('').trim();

// Each test collects every problem it finds, so one run shows the whole list.
let problems = [];
const ok = (cond, msg) => { if (!cond) problems.push(msg); };
const each = (fn) => { for (const [url, doc] of pages) fn(url, doc); };
const done = () => { const p = [...new Set(problems)]; problems = []; assert.deepEqual(p, []); };

test('there are pages, and a page for every skill', { skip }, () => {
  ok(pages.size > 50, `only ${pages.size} pages built`);
  const skills = readdirSync(join(SITE, '../canonical/skills'));
  for (const s of skills) ok(pages.has(`/reference/skills/${s}/`), `no page for ${s}`);
  done();
});

test('every page has a language, a unique title, one h1 and a main landmark', { skip }, () => {
  const titles = new Map();
  each((url, doc) => {
    ok(doc.querySelector('html')?.getAttribute('lang'), `${url}: <html lang> missing`);
    const title = doc.querySelector('title')?.textContent.trim();
    ok(title, `${url}: empty <title>`);
    ok(!titles.has(title), `${url}: title "${title}" is also used by ${titles.get(title)}`);
    titles.set(title, url);
    ok(doc.querySelectorAll('h1').length === 1, `${url}: needs exactly one h1`);
    ok(doc.querySelector('main'), `${url}: no <main>`);
  });
  done();
});

test('headings never skip a level', { skip }, () => {
  each((url, doc) => {
    let prev = 1;
    for (const h of doc.querySelectorAll('.sl-markdown-content h2, .sl-markdown-content h3, .sl-markdown-content h4, .sl-markdown-content h5')) {
      const level = Number(h.tagName[1]);
      ok(level <= prev + 1, `${url}: h${level} "${h.textContent.trim()}" follows h${prev}`);
      prev = level;
    }
  });
  done();
});

test('images have alt text, svgs are labelled or hidden, tables have headers', { skip }, () => {
  each((url, doc) => {
    for (const img of doc.querySelectorAll('main img')) ok(img.hasAttribute('alt'), `${url}: <img ${img.getAttribute('src')}> has no alt`);
    for (const svg of doc.querySelectorAll('main svg')) {
      const named = svg.closest('[aria-hidden="true"]') || svg.querySelector('title') || svg.getAttribute('aria-label');
      ok(named, `${url}: an <svg> is neither hidden nor labelled`);
    }
    for (const t of doc.querySelectorAll('.sl-markdown-content table')) ok(t.querySelector('th'), `${url}: a table has no header cells`);
  });
  done();
});

test('links have a name, descriptive text and no duplicate ids', { skip }, () => {
  const vague = /^(here|click here|this|link|more|read more)$/i;
  each((url, doc) => {
    for (const a of doc.querySelectorAll('main a[href]')) {
      const name = accessibleName(a);
      ok(name, `${url}: link to ${a.getAttribute('href')} has no accessible name`);
      ok(!vague.test(name), `${url}: vague link text "${name}"`);
    }
    const seen = new Set();
    for (const el of doc.querySelectorAll('[id]')) {
      const id = el.getAttribute('id');
      ok(!seen.has(id), `${url}: duplicate id "${id}"`);
      seen.add(id);
    }
  });
  done();
});

test('internal links and #fragments resolve', { skip }, () => {
  each((url, doc) => {
    for (const a of doc.querySelectorAll('a[href]')) {
      const href = a.getAttribute('href');
      if (/^([a-z][a-z0-9+.-]*:|\/\/)/i.test(href) || href.startsWith('mailto:')) continue;
      const target = new URL(href, `https://x.test${url}`);
      const path = target.pathname.endsWith('/') ? target.pathname : target.pathname + '/';
      const isFile = /\.[a-z0-9]+$/i.test(target.pathname);
      if (isFile) { ok(existsSync(join(DIST, target.pathname)), `${url}: ${href} is missing`); continue; }
      const doc2 = pages.get(path);
      ok(doc2, `${url}: link to ${href} has no page`);
      if (doc2 && target.hash.length > 1) {
        const id = decodeURIComponent(target.hash.slice(1));
        ok(doc2.querySelector(`[id="${id}"]`), `${url}: ${href} points at a missing anchor`);
      }
    }
  });
  done();
});

test('search index and sitemap are built', { skip }, () => {
  ok(existsSync(join(DIST, 'pagefind/pagefind.js')), 'pagefind index missing');
  ok(existsSync(join(DIST, 'sitemap-index.xml')), 'sitemap missing');
  done();
});
