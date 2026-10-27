// Token contrast and colour-literal checks (K1-K5). Node built-ins and vitest only; no build needed.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { SITE } from './dist.mjs';

const read = (...p) => readFileSync(join(SITE, ...p), 'utf8');
const channel = (c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
/** WCAG 2.x relative luminance of '#rrggbb'. */
function luminance(hex) {
  const [r, g, b] = [1, 3, 5].map((i) => channel(parseInt(hex.slice(i, i + 2), 16) / 255));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
/** WCAG 2.x contrast ratio: (Lmax + 0.05) / (Lmin + 0.05). */
const ratio = (fg, bg) => (Math.max(luminance(fg), luminance(bg)) + 0.05) / (Math.min(luminance(fg), luminance(bg)) + 0.05);
/** { dark, light, mapping } (Maps of name -> value) from the two rule blocks of tokens.css. */
function readTokens(cssText) {
  const css = cssText.replace(/\/\*[\s\S]*?\*\//g, '');
  const decls = (re) => new Map([...(re.exec(css)?.[1] ?? '').matchAll(/^\s*(--[\w-]+):\s*([^;]+);/gm)].map((m) => [m[1], m[2].trim()]));
  const dark = decls(/:root\s*\{([^}]*)\}/);
  return { dark, light: decls(/:root\[data-theme='light'\]\s*\{([^}]*)\}/), mapping: new Map([...dark].filter(([k]) => k.startsWith('--sl-'))) };
}

const T = readTokens(read('src', 'styles', 'tokens.css'));
const colours = (m) => new Map([...m].filter(([k]) => k.startsWith('--aid-color-')));
const ASIDE_BGS = ['note-bg', 'tip-bg', 'caution-bg', 'danger-bg'], SL = (n) => `--sl-color-${n}`;
const DIAGRAM_BGS = ['--sl-color-bg', '--sl-color-gray-6', '--sl-color-accent-low'];
/** [foreground, backgrounds, minimum, used for]; a side is a token name or a Starlight variable. */
const PAIRS = [
  ['text', ['bg', 'nav', 'surface'], 4.5, 'body text'],
  ['text-strong', ['bg', 'surface', 'accent-soft'], 4.5, 'headings, diagram labels'],
  ['text-muted', ['bg', 'nav', 'surface'], 4.5, 'group labels, captions, footer'],
  ['accent', ['bg', 'nav', 'surface', 'accent-soft'], 4.5, 'links'],
  ['accent-strong', ['bg'], 4.5, 'link hover'],
  ['on-accent', ['accent'], 4.5, 'skip link, current sidebar item'],
  ['border-strong', ['bg', 'nav', 'surface'], 3, 'control borders'],
  ['focus', ['bg', 'nav', 'surface'], 3, 'focus ring'],
  ...ASIDE_BGS.map((bg) => [bg.slice(0, -3), [bg], 4.5, 'aside title and links']),
  ['text-strong', ASIDE_BGS, 4.5, 'aside body text'],
  ['--sl-color-white', DIAGRAM_BGS, 4.5, 'diagram labels'],
  ['--sl-color-gray-2', DIAGRAM_BGS, 4.5, 'diagram notes and sub-lines'],
  ['--sl-color-gray-3', ['--sl-color-bg'], 3, 'diagram edges'],
  ['--sl-color-accent', ['--sl-color-bg'], 3, 'diagram accent outline'],
];
const token = (side) => (side.startsWith('--sl-') ? /^var\(--aid-color-([\w-]+)\)$/.exec(T.mapping.get(side) ?? '')?.[1] : side);
const SL_NAMES = [...['bg', 'black', 'bg-nav', 'bg-sidebar', 'gray-7', 'bg-inline-code', 'gray-6', 'text', 'gray-2', 'white', 'gray-1', 'gray-3', 'gray-4', 'gray-5',
  'hairline', 'hairline-light', 'hairline-shade', 'accent', 'text-accent', 'bg-accent', 'accent-high', 'accent-low', 'text-invert',
  ...['blue', 'purple', 'orange', 'red'].flatMap((c) => [c, `${c}-high`, `${c}-low`])].map(SL),
  ...['h1', 'h2', 'h3', 'h4', 'h5', 'xs', '2xs'].map((h) => `--sl-text-${h}`), '--sl-line-height', '--sl-line-height-headings', '--sl-content-width'];

describe('token contrast', () => {
  it('K1 both blocks define the same --aid-color-* names, all #rrggbb', () => {
    const [d, l] = [colours(T.dark), colours(T.light)];
    expect(Math.min(d.size, l.size)).toBeGreaterThan(0); expect([...l.keys()].sort()).toEqual([...d.keys()].sort());
    expect([...d, ...l].filter(([, v]) => !/^#[0-9a-f]{6}$/.test(v)).map(([k, v]) => `${k}: ${v}`)).toEqual([]);
  });
  it('K2 every --sl-* value is var(--aid-...) of a defined token, and the mapping is complete', () => {
    const bad = [...T.mapping].filter(([, v]) => !/^var\(--aid-[\w-]+\)$/.test(v) || !T.dark.has(v.slice(4, -1)));
    expect(bad.map(([k, v]) => `${k}: ${v}`)).toEqual([]);
    expect(SL_NAMES.filter((k) => !T.mapping.has(k))).toEqual([]);
  });
  it('K3 every pair meets its minimum in both themes', () => {
    const fails = [];
    for (const theme of ['dark', 'light']) {
      const value = (side) => T[theme].get(`--aid-color-${token(side)}`);
      for (const [fg, bgs, min, use] of PAIRS) {
        for (const bg of bgs) {
          const r = ratio(value(fg), value(bg));
          if (!(r >= min)) fails.push(`${theme} ${fg} on ${bg}: ${r.toFixed(2)} < ${min} (${use})`);
        }
      }
    }
    expect(fails).toEqual([]);
  });
  it('K4 no colour literal in site.css or the component styles and diagrams', () => {
    const files = new Map([['src/styles/site.css', read('src', 'styles', 'site.css')]]);
    for (const f of readdirSync(join(SITE, 'src', 'components'), { recursive: true }).filter((n) => n.endsWith('.astro')).sort()) {
      const src = read('src', 'components', f);
      const whole = /^(Diagram\.astro|diagrams[\\/][^\\/]+\.astro)$/.test(f);
      files.set(`src/components/${f}`, whole ? src : [...src.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/g)].map((m) => m[1]).join('\n'));
    }
    const hits = [...files].flatMap(([f, text]) => text.split('\n').filter((line) => /#[0-9a-f]{3,8}\b|rgba?\(|hsla?\(/i.test(line)).map((line) => `${f}: ${line.trim()}`));
    expect(hits).toEqual([]);
  });
  it('K5 ratio() is the WCAG formula and can fail', () => {
    expect(ratio('#000000', '#ffffff')).toBeCloseTo(21, 5);
    expect(ratio('#767676', '#ffffff')).toBeGreaterThanOrEqual(4.5);
    expect(ratio('#777777', '#ffffff')).toBeLessThan(4.5);
  });
});
