// Guards for public/skill-node-panel.css (feature-006 / task-051).
//
// The stylesheet's acceptance criteria are mostly negative — no hard-coded
// colour, no animation on focus or open state, no `position: fixed`, no scroll
// lock, no second breakpoint — and negatives rot silently. A later edit that adds
// a hex colour or a transition breaks a stated property of the feature (theme
// tracking, and `prefers-reduced-motion` needing no branch) without breaking
// anything a rendering test would notice.
//
// Comment text is stripped before every check, so a criterion cannot be
// satisfied by prose that merely mentions the thing.

import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CSS_PATH = resolve(__dirname, '../../public/skill-node-panel.css');

const raw = readFileSync(CSS_PATH, 'utf8');
const css = raw.replace(/\/\*[\s\S]*?\*\//g, '');

/**
 * The element list from feature-006's Anatomy block. Kept here as the expected
 * set so a rule for an element the controller never creates, or a missing rule
 * for one it does, both fail.
 */
const ANATOMY_ELEMENTS = ['bar', 'order', 'kind', 'exit', 'close', 'label', 'fragment', 'links'];

/** Shape elements mermaid can put inside `g.node`, depending on node kind. */
const NODE_SHAPES = ['rect', 'polygon', 'circle', 'ellipse', 'path'];

describe('skill-node-panel.css — the file itself', () => {
  it('is a static file under public/, so it is served same-origin', () => {
    expect(existsSync(CSS_PATH)).toBe(true);
    // Non-vacuity: a stripped-to-nothing file would satisfy most checks below.
    expect(css.length).toBeGreaterThan(500);
  });
});

describe('skill-node-panel.css — Anatomy coverage', () => {
  it('has a rule for the block', () => {
    expect(css).toMatch(/\.aid-node-panel\s*\{/);
  });

  it('has a rule for every Anatomy element', () => {
    const missing = ANATOMY_ELEMENTS.filter((e) => !css.includes(`.aid-node-panel__${e}`));
    expect(missing).toEqual([]);
    expect(ANATOMY_ELEMENTS.length).toBeGreaterThan(0);
  });

  it('styles no element outside the Anatomy block', () => {
    const declared = [...new Set([...css.matchAll(/\.aid-node-panel__([a-z-]+)/g)].map((m) => m[1]))];
    expect(declared.filter((e) => !ANATOMY_ELEMENTS.includes(e))).toEqual([]);
    // Non-vacuity: the selector scan found something to check.
    expect(declared.length).toBe(ANATOMY_ELEMENTS.length);
  });
});

describe('skill-node-panel.css — focus visibility', () => {
  it('rings the node group on :focus-visible', () => {
    expect(css).toMatch(/g\.node\[role='button'\]:focus-visible\s*\{/);
  });

  // Belt and braces: several engines apply `outline` unreliably to SVG groups,
  // and a focus indicator resting on one mechanism is one bug from invisible —
  // which makes the chart unusable by keyboard, not merely plain.
  it('also changes the child shape stroke, for every shape mermaid can emit', () => {
    for (const shape of NODE_SHAPES) {
      expect(css).toContain(`:focus-visible > ${shape}`);
    }
    expect(css).toMatch(/stroke-width/);
  });

  it('marks the open node so the panel can be traced back to it', () => {
    expect(css).toMatch(/\[aria-expanded='true'\]/);
  });
});

describe('skill-node-panel.css — no motion, so reduced-motion needs no branch', () => {
  it('declares no animation', () => {
    expect(css).not.toMatch(/\banimation\s*:/);
  });

  it('declares no transition', () => {
    expect(css).not.toMatch(/\btransition\s*:/);
  });
});

describe('skill-node-panel.css — colours come only from tokens', () => {
  it('hard-codes no hex colour', () => {
    expect(css.match(/#[0-9a-fA-F]{3,8}\b/g)).toBeNull();
  });

  it('hard-codes no rgb()/rgba() colour', () => {
    expect(css.match(/\brgba?\(/g)).toBeNull();
  });

  it('resolves every colour-bearing declaration from a --sl-color-* or --casulo-* token', () => {
    const decls = [...css.matchAll(
      /(?:^|[;{])\s*(?:color|background|background-color|border[a-z-]*|outline|stroke|fill)\s*:\s*([^;}]+)/g,
    )].map((m) => m[1].trim());

    // Non-vacuity: this file certainly sets colours, so an empty scan is a broken regex.
    expect(decls.length).toBeGreaterThan(5);

    const untokenised = decls.filter((v) =>
      !/var\(--sl-color-|var\(--casulo-/.test(v) &&
      !/^(transparent|inherit|none|currentColor|initial|unset)/.test(v) &&
      !/^\d/.test(v) &&
      !/^(solid|dashed)/.test(v));
    expect(untokenised).toEqual([]);
  });
});

describe('skill-node-panel.css — in flow, not modal', () => {
  it('never takes the panel out of flow', () => {
    expect(css).not.toMatch(/position\s*:\s*fixed/);
    expect(css).not.toMatch(/position\s*:\s*sticky/);
  });

  it('locks no scroll and defines no overlay', () => {
    expect(css).not.toMatch(/overflow\s*:\s*hidden/);
    expect(css).not.toMatch(/backdrop|overlay/i);
  });
});

describe('skill-node-panel.css — the fragment cannot crowd out the list below', () => {
  const fragmentRule = /\.aid-node-panel__fragment\s*\{([^}]*)\}/.exec(css)?.[1] ?? '';

  it('caps its height and scrolls vertically', () => {
    expect(fragmentRule).toMatch(/max-height/);
    expect(fragmentRule).toMatch(/overflow\s*:\s*auto/);
  });

  // The same readability choice delivery-004 makes with its `wrap` meta option:
  // a long dispatch row wraps rather than scrolling sideways.
  it('wraps rather than scrolling horizontally', () => {
    expect(fragmentRule).toMatch(/white-space\s*:\s*pre-wrap/);
    expect(fragmentRule).toMatch(/overflow-wrap\s*:\s*anywhere/);
  });
});

describe('skill-node-panel.css — narrow screens', () => {
  it('uses the breakpoint the site already has, and introduces no other', () => {
    const media = [...new Set((css.match(/@media[^{]*/g) || []).map((s) => s.trim()))];
    expect(media).toEqual(['@media (max-width: 50rem)']);
  });
});
