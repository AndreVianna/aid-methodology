// AC-9 keyboard check and AC-11 screenshots against a local preview (http://localhost:4321/).
// Run: PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers node ac9-ac11.mjs   (playwright already on the machine; nothing is downloaded)
import { createRequire } from 'node:module';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node-tools/node_modules/playwright';
const { chromium } = require(PW);

const BASE = 'http://localhost:4321';
const here = dirname(fileURLToPath(import.meta.url));
const shots = resolve(here, '../screenshots');
mkdirSync(shots, { recursive: true });
const END = 'Report a problem with this page on GitHub';
const pages = [['home', '/'], ['aid-define', '/skills/aid-define/']];

const browser = await chromium.launch();

async function focusInfo(page) {
  return page.evaluate(() => {
    const e = document.activeElement;
    if (!e || e === document.body) return null;
    const cs = getComputedStyle(e);
    const clean = (t) => (t || '').replace(/\s+/g, ' ').trim();
    const lab = e.labels && e.labels.length ? clean((e.labels[0].querySelector('.sr-only') || e.labels[0]).textContent) : '';
    const name = clean(e.getAttribute('aria-label')) || lab || clean(e.innerText) || clean(e.textContent)
      || clean(e.getAttribute('title')) || clean(e.getAttribute('alt')) || (e.querySelector('img') ? clean(e.querySelector('img').alt) : '');
    const area = e.closest('nav.sidebar, #starlight__sidebar') ? 'sidebar'
      : e.closest('starlight-toc, .right-sidebar, mobile-starlight-toc') ? 'toc'
      : e.closest('main') ? 'content' : 'other';
    return { name, area, tag: e.tagName, outlineStyle: cs.outlineStyle, outlineWidth: parseFloat(cs.outlineWidth) };
  });
}

// (1)+(2) keyboard
for (const [, path] of pages) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  await page.goto(BASE + path);
  const stops = [];
  for (let i = 0; i < 400; i++) {
    await page.keyboard.press('Tab');
    const f = await focusInfo(page);
    if (!f) continue;
    stops.push(f);
    if (f.name === END) break;
  }
  const ringOk = stops.filter((s) => s.outlineStyle !== 'none' && s.outlineWidth >= 3).length;
  const out = [];
  let prev = null;
  for (const s of stops) {
    if (/^(Previous|Next) /.test(s.name)) s.area = 'pager', s.name = s.name.split(' ')[0];
    if (s.name === END) s.area = 'end';
    const key = s.area === 'sidebar' || s.area === 'toc' || s.area === 'content' ? s.area : s.name;
    if (prev && prev.key === key && prev.group) prev.n++;
    else { prev = { key, group: key === s.area, n: 1, name: s.name }; out.push(prev); }
  }
  const text = out.map((g) => (g.group ? `${g.key === 'toc' ? 'On this page' : g.key} (${g.n} stops)` : g.name)).join(', ');
  console.log(`KEY ${path}`);
  console.log(`  stops: ${text}`);
  console.log(`  last stops: ${stops.slice(-5).map((x) => x.name + ' [' + x.area + ']').join(' | ')}`);
  console.log(`  total stops: ${stops.length}`);
  console.log(`  focus ring (outline-style not none, width >= 3px): ${ringOk}/${stops.length}`);
  stops.filter((s) => !(s.outlineStyle !== 'none' && s.outlineWidth >= 3)).forEach((s) => console.log(`  NO RING: ${s.name} [${s.area}] ${s.outlineStyle} ${s.outlineWidth}`));
  console.log(`  reached end: ${stops.length > 0 && stops[stops.length - 1].name === END}`);

  // Skip link: Enter moves focus to h1
  await page.goto(BASE + path);
  await page.keyboard.press('Tab');
  const first = await focusInfo(page);
  await page.keyboard.press('Enter');
  const hash = await page.evaluate(() => location.hash);
  const h1Top = await page.evaluate(() => { const h = document.querySelector('h1'); return h ? Math.round(h.getBoundingClientRect().top) : null; });
  await page.keyboard.press('Tab');
  const next = await focusInfo(page);
  console.log(`  skip link first stop: ${first && first.name}; after Enter: hash=${hash}, h1 top=${h1Top}px, next Tab -> ${next && next.name} [${next && next.area}]`);
  // Search: Enter opens, Escape closes
  await page.goto(BASE + path);
  const btn = page.locator('site-search button[data-open-modal]').first();
  await btn.focus();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  const opened = await page.evaluate(() => !!document.querySelector('dialog[open]'));
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
  const closed = await page.evaluate(() => !document.querySelector('dialog[open]'));
  console.log(`  search: Enter opens dialog=${opened}; Escape closes dialog=${closed}`);
  await ctx.close();
}

// (3) screenshots
for (const [label, path] of pages) {
  for (const w of [320, 1280]) {
    for (const theme of ['light', 'dark']) {
      const ctx = await browser.newContext({ viewport: { width: w, height: 800 } });
      const page = await ctx.newPage();
      await page.goto(BASE + path);
      await page.evaluate((t) => localStorage.setItem('starlight-theme', t), theme);
      await page.reload();
      await page.waitForLoadState('networkidle');
      const actual = await page.evaluate(() => document.documentElement.dataset.theme);
      const file = `${label}-${w}-${theme}.png`;
      await page.screenshot({ path: resolve(shots, file) });
      const fits = await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth);
      console.log(`SHOT ${file}, data-theme=${actual}, scrollWidth <= innerWidth: ${fits}`);
      await ctx.close();
    }
  }
}

// (4) contact request: a plain mailto link, no form (a GET form encoded spaces as +)
{
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  await page.goto(BASE + '/contact/contact-request/');
  const href = await page.getAttribute('a.rf-button', 'href');
  const ok = href && href.startsWith('mailto:') && href.includes('subject=AID%3A%20request') && !href.includes('+');
  console.log(`MAILTO ${ok ? 'ok' : 'BAD'} ${href}`);
  await ctx.close();
}
await browser.close();
