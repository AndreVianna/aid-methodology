// FR-8 group (d): structure, accessibility, diagram markup, script and weight checks on every built page.
// Pages are parsed with jsdom (page scripts never run). Reads dist/, writes nothing. Run `npm run build` first.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { gzipSync } from 'node:zlib';
import axe from 'axe-core';
import { JSDOM, VirtualConsole } from 'jsdom';
import { describe, expect, it } from 'vitest';
import { builtPages, DIST, SITE } from './dist.mjs';

/** Script purposes for AC-15 and NFR-2. A script is classified by the markers its text contains. */
const PURPOSES = {
  search: ['site-search', 'data-open-modal', 'pagefind'],
  theme: ['starlight-theme-select', 'StarlightThemeProvider', 'starlight-theme'],
  navigation: ['starlight-menu-button', 'starlight-toc', 'mobile-starlight-toc',
    'sl-sidebar-state', 'sl-sidebar-restore', '_starlightScrollRestore'],
};
/** Markers that fail a script even when it also carries an allowed marker. */
const FORBIDDEN = ['starlight-tabs', 'mermaid', '.expressive-code .copy', 'aid-banner',
  'aid-flow-data', 'rf-submit'];
const BANNED_LINK_TEXT = ['here', 'click here', 'read more', 'more', 'link', 'this', 'this page'];
const LIMIT = 150 * 1024; // bytes; AC-15 and NFR-2
const SVG_OK = ['g', 'rect', 'circle', 'ellipse', 'path', 'line', 'polyline', 'polygon', 'text', 'tspan',
  'defs', 'marker', 'title', 'desc'];
const OFF_SITE = /^(https?:)?\/\//;

const all = (root, sel) => [...root.querySelectorAll(sel)];
const kids = (el, name) => [...el.children].filter((c) => c.localName === name);
const words = (el) => (el?.textContent ?? '').replace(/\s+/g, ' ').trim();

/** The file under dist/ that a local reference names, or null for an off-site one. */
function localFile(ref, url) {
  if (OFF_SITE.test(ref)) return null;
  return join(DIST, decodeURIComponent(new URL(ref, 'https://site.invalid' + url).pathname));
}
const readText = (file) => { try { return readFileSync(file, 'utf8'); } catch { return null; } };
const purposesOf = (text) => Object.keys(PURPOSES).filter((k) => PURPOSES[k].some((m) => text.includes(m)));

function open(page) {
  return new JSDOM(page.html, { url: 'https://aid.casuloailabs.com' + page.url,
    runScripts: 'outside-only', virtualConsole: new VirtualConsole() });
}

/** S1-S9. */
function structure(doc) {
  const out = [];
  const main = doc.querySelector('main');
  if (doc.documentElement.getAttribute('lang') !== 'en') out.push('S1 html has no lang="en"');
  const h1s = all(doc, 'h1');
  if (h1s.length !== 1 || !main?.contains(h1s[0])) out.push(`S2 found ${h1s.length} h1, expected one inside main`);
  const mains = all(doc, 'main').length;
  const roleMain = all(doc, '[role="main"]').filter((e) => e.localName !== 'main').length;
  if (mains !== 1 || roleMain) out.push(`S3 found ${mains} main and ${roleMain} other role=main`);
  let prev = 0;
  all(main ?? doc.body, 'h1,h2,h3,h4,h5,h6').forEach((h, i) => {
    const level = Number(h.localName[1]);
    if (i === 0 ? level !== 1 : level > prev + 1) out.push(`S4 ${h.localName} follows ${i ? 'h' + prev : 'nothing'} in main`);
    prev = level;
  });
  const first = doc.body.querySelector('a[href]');
  if (first?.getAttribute('href') !== '#_top' || doc.getElementById('_top')?.localName !== 'h1') out.push('S5 skip link missing or its target is not the h1');
  const banners = all(doc, 'header').filter((h) => !h.closest('main, aside, nav, article, section'));
  if (banners.length !== 1) out.push(`S6 found ${banners.length} banner header, expected one`);
  for (const nav of all(doc, 'nav')) {
    const by = (nav.getAttribute('aria-labelledby') ?? '').split(/\s+/).map((id) => words(doc.getElementById(id))).join('');
    if (!(nav.getAttribute('aria-label') ?? '').trim() && !by) out.push('S6 nav without an accessible name');
  }
  for (const a of all(doc, 'a[href]')) {
    const text = (a.getAttribute('aria-label') ?? words(a)).replace(/[\s\p{P}\p{S}]+$/u, '').toLowerCase();
    if (BANNED_LINK_TEXT.includes(text)) out.push(`S7 link text "${text}" -> ${a.getAttribute('href')}`);
  }
  if (doc.querySelector('starlight-tabs, [role="tablist"]')) out.push('S8 page has a tab list');
  const seen = new Set();
  for (const { id } of all(doc, '[id]')) {
    if (seen.has(id)) out.push(`S9 duplicate id "${id}"`);
    seen.add(id);
  }
  return out;
}

/** U1-U7, inside main (Feature 003 markup contract). */
function diagrams(doc) {
  const out = [];
  const root = doc.querySelector('main') ?? doc.body;
  const figs = all(root, 'figure.diagram');
  const listed = (f) => kids(f, 'div').some((d) => d.classList.contains('diagram-text') && (
    all(d, 'ol').some((ol) => all(ol, 'li').length >= 2) || all(d, 'table').some((t) => all(t, 'tbody tr').length >= 2)));
  const withText = figs.filter(listed).length;
  if (figs.length !== withText) out.push(`U1 ${figs.length} figure.diagram but ${withText} with a text equivalent list`);
  for (const f of figs) {
    const id = f.id || '(no id)';
    const caps = kids(f, 'figcaption');
    const svgs = kids(f, 'svg').filter((s) => s.getAttribute('role') === 'img');
    if (caps.length !== 1 || !words(caps[0])) out.push(`U2 ${id}: needs exactly one non-empty figcaption`);
    if (svgs.length !== 1) out.push(`U2 ${id}: needs exactly one svg[role="img"]`);
    for (const [attr, tag] of [['aria-labelledby', 'title'], ['aria-describedby', 'desc']]) {
      const el = svgs[0] && doc.getElementById(svgs[0].getAttribute(attr) ?? '');
      if (svgs[0] && !(el?.localName === tag && el.parentElement === svgs[0] && words(el))) out.push(`U3 ${id}: ${attr} must name a non-empty ${tag} child`);
    }
    if (f.querySelector('script, [tabindex]')) out.push(`U6 ${id}: script or tabindex inside the figure`);
    for (const el of all(f, 'svg *')) {
      const name = el.localName.toLowerCase();
      if (name === 'a' || name === 'foreignobject') out.push(`U6 ${id}: ${name} inside the svg`);
      if (!SVG_OK.includes(name)) out.push(`U7 ${id}: element ${name} not allowed`);
      for (const a of ['style', 'fill', 'stroke', 'color']) if (el.hasAttribute(a)) out.push(`U7 ${id}: ${name} has a ${a} attribute`);
    }
  }
  for (const svg of all(root, 'svg')) {
    if (!svg.closest('figure.diagram, [aria-hidden="true"]') && !svg.hasAttribute('aria-label')) out.push('U4 svg in main with neither aria-hidden nor aria-label');
  }
  if (doc.querySelector('.mermaid, [data-language="mermaid"]')) out.push('U5 mermaid markup present');
  return out;
}

/** W3 and W4. */
function scripts(page, doc) {
  const out = [];
  for (const s of all(doc, 'script')) {
    const type = s.getAttribute('type');
    if (type === 'application/json' || type === 'application/ld+json') continue;
    const src = s.getAttribute('src');
    if (src && OFF_SITE.test(src)) out.push(`W4 script src is off-site: ${src}`);
    const label = src ?? 'inline script';
    const text = src ? readText(localFile(src, page.url) ?? '') : s.textContent;
    if (text === null) { out.push(`W3 ${label}: file not found`); continue; }
    if (!purposesOf(text).length) out.push(`W3 ${label}: no purpose`);
    for (const m of FORBIDDEN.filter((m) => text.includes(m))) out.push(`W3 ${label}: forbidden marker ${m}`);
  }
  for (const l of all(doc, 'link[rel~="stylesheet"]')) {
    if (OFF_SITE.test(l.getAttribute('href') ?? '')) out.push(`W4 stylesheet href is off-site: ${l.getAttribute('href')}`);
  }
  return out;
}

/** W1 and W2. */
function weight(page, doc) {
  const out = [];
  const size = statSync(page.file).size;
  if (size > LIMIT) out.push(`W1 html is ${size} bytes, limit ${LIMIT}`);
  const refs = [...all(doc, 'link[rel~="stylesheet"]').map((l) => l.getAttribute('href')),
    ...all(doc, 'link[rel~="modulepreload"]').map((l) => l.getAttribute('href')),
    ...all(doc, 'script[src]').map((s) => s.getAttribute('src'))];
  let total = gzipSync(page.html).length;
  for (const ref of new Set(refs.filter(Boolean))) {
    const file = localFile(ref, page.url);
    if (file) { try { total += gzipSync(readFileSync(file)).length; } catch { out.push(`W2 file not found: ${ref}`); } }
  }
  if (total > LIMIT) out.push(`W2 gzip total ${total} bytes, limit ${LIMIT}`);
  return out;
}

/** A1: axe-core on the page, color-contrast off (the contrast test covers it). */
async function axeProblems(dom) {
  dom.window.eval(axe.source);
  const r = await dom.window.axe.run(dom.window.document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] },
    rules: { 'color-contrast': { enabled: false } },
    resultTypes: ['violations'],
  });
  return r.violations.map((v) => `A1 ${v.id}: ${v.nodes.map((n) => n.target.join(' ')).join(', ')}`);
}

// ---- self-tests: fixtures in this file, nothing written ----
const shell = (body, lang = ' lang="en"') => ({ url: '/',
  html: `<!doctype html><html${lang}><head><title>t</title></head><body><a href="#_top">Skip</a><header><p>h</p></header><main><h1 id="_top">Title</h1>${body}</main></body></html>` });
const fig = (id, inner = '', text = '<div class="diagram-text"><ol><li>a</li><li>b</li></ol></div>') =>
  `<figure class="diagram" id="${id}"><figcaption>Cap</figcaption><svg role="img" aria-labelledby="${id}-t" aria-describedby="${id}-d"><title id="${id}-t">T</title><desc id="${id}-d">D</desc>${inner}</svg>${text}</figure>`;
const check = (page) => { const dom = open(page); const d = dom.window.document; return [...structure(d), ...diagrams(d), ...scripts(page, d)]; };
const starts = (problems, id) => problems.filter((p) => p.startsWith(id + ' '));

describe('self-tests: each check can fail', () => {
  it('T1 two h1 in main gives S2', () => expect(starts(check(shell('<h1>Again</h1>')), 'S2')).toEqual(['S2 found 2 h1, expected one inside main']));
  it('T2 h1, h2, h4 gives S4 naming h4', () => expect(starts(check(shell('<h2>a</h2><h4>b</h4>')), 'S4')).toEqual(['S4 h4 follows h2 in main']));
  it('T3 html without lang gives S1', () => expect(starts(check(shell('', '')), 'S1')).toHaveLength(1));
  it('T4 figure.diagram without .diagram-text gives U1', () => expect(starts(check(shell(fig('dg-a', '', ''))), 'U1')).toHaveLength(1));
  it('T5 svg without aria-hidden or aria-label gives U4', () => expect(starts(check(shell('<svg></svg>')), 'U4')).toHaveLength(1));
  it('T6 inline script without a purpose gives W3 no purpose', () => expect(starts(check(shell('<script>console.log(1)</script>')), 'W3')).toEqual(['W3 inline script: no purpose']));
  it('T7 img without alt gives A1 image-alt', async () => {
    const problems = await axeProblems(open(shell('<img src="a.png">')));
    expect(problems.some((p) => p.startsWith('A1 image-alt:'))).toBe(true);
  });
  it('T8 link text "click here" gives S7', () => expect(starts(check(shell('<a href="/x/">click here →</a>')), 'S7')).toHaveLength(1));
  it('T9 a in the svg gives U6; a in .diagram-text does not', () => {
    const body = fig('dg-one', '<a href="/x/"><text>t</text></a>') +
      fig('dg-two', '', '<div class="diagram-text"><ol><li><a href="/x/">Next page</a></li><li>b</li></ol></div>');
    const u6 = starts(check(shell(body)), 'U6');
    expect(u6).toEqual(['U6 dg-one: a inside the svg']);
  });
  it('T10 fill attribute in the svg gives U7', () => expect(starts(check(shell(fig('dg-a', '<rect fill="#ffffff"/>'))), 'U7')).toEqual(['U7 dg-a: rect has a fill attribute']));
  it('T11 two elements with id x give S9 naming x', () => expect(starts(check(shell('<p id="x">a</p><p id="x">b</p>')), 'S9')).toEqual(['S9 duplicate id "x"']));
});

// ---- one test per built page ----
const pages = builtPages().filter((p) => !p.redirectTo);

describe('built pages', () => {
  it.each(pages)('page $url', async (page) => {
    const dom = open(page);
    const doc = dom.window.document;
    const problems = [...structure(doc), ...diagrams(doc), ...scripts(page, doc), ...weight(page, doc), ...(await axeProblems(dom))];
    dom.window.close();
    if (problems.length) throw new Error(`${problems.length} problem(s)\n` + problems.join('\n'));
  });

  it('every diagram component is used, and the script list is printed', () => {
    let figures = 0;
    const srcs = new Map();
    for (const p of pages) {
      figures += (p.html.match(/<figure[^>]*class="diagram[ "]/g) ?? []).length;
      for (const m of p.html.matchAll(/<script\b[^>]*\ssrc="([^"]*)"/g)) {
        const file = localFile(m[1], p.url);
        srcs.set(m[1], file ? purposesOf(readText(file) ?? '') : ['off-site']);
      }
    }
    const components = readdirSync(join(SITE, 'src/components/diagrams')).length;
    if (!srcs.size) console.info('AC-15: no page has a script src');
    for (const [src, purposes] of [...srcs].sort()) console.info(`AC-15: script src ${src} purposes: ${purposes.join(', ') || 'none'}`);
    expect(figures).toBeGreaterThanOrEqual(components);
  });
});
