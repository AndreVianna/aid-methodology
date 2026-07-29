// @vitest-environment jsdom
//
// Panel behaviour: disclosure, focus and key handling (task-050).
//
// The controller ships from public/ as an IIFE, so it is loaded by evaluating the
// file text into a real jsdom document rather than imported. That is deliberate: it
// exercises the same bytes the browser gets, including the IIFE wrapper and the
// top-level try/catch.
//
// Fixture ids carry mermaid's diagram-id prefix — `mermaid-<diagramId>-flowchart-<id>-<n>`
// — because that is what a rendered page actually emits, measured in a browser on
// this site (`mermaid-rkijoq1pv-flowchart-n10-9`). task-050's and task-053's DETAILs
// both describe the shape as `flowchart-<id>-<n>`, which is mermaid's internal domId
// and not what reaches the DOM; building fixtures that way is how the shipped
// start-anchored pattern came to match 0 of 10 real nodes while its suite passed.
// See delivery-005 STATE, Q4.
//
// Focus PLACEMENT inside the panel is asserted here only where jsdom is reliable:
// jsdom does honour focus() on an HTML element with tabindex, which the panel is, so
// panel-takes-focus and Escape-returns-focus-to-the-node are both meaningful. What
// jsdom cannot settle is focus ORDER through an SVG <g> carrying tabindex, and
// screen-reader announcement — those are two of the four manual gate checks.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = join(resolve(__dirname, '../..'), 'public', 'skill-node-panel.mjs');
const SCRIPT_SRC = readFileSync(SCRIPT_PATH, 'utf8');

const DIAGRAM_ID = 'mermaid-rkijoq1pv';

/** A two-node projection: n1 plain, n2 terminal with a detail pointer. */
function projection() {
  return {
    v: 1,
    skill: 'aid-fixture',
    confidence: 'derived',
    nodes: [
      {
        id: 'n1', order: 1, name: 'INTAKE', label: 'Read the request', kind: 'entry',
        exit: null,
        fragment: '| INTAKE | `references/state-intake.md` | a <b>pipe</b> & ````four```` |',
        source: { url: 'https://github.com/x/blob/master/canonical/skills/a/SKILL.md#L5' },
        detail: null,
      },
      {
        id: 'n2', order: 2, name: 'DONE', label: 'Hand back to the caller', kind: 'exit',
        exit: { advanceType: 'HALT', handoff: null },
        fragment: '## State: DONE\n\n  indented line\n',
        source: { url: 'https://github.com/x/blob/master/canonical/skills/a/SKILL.md#L9-L12' },
        detail: { url: 'https://github.com/x/blob/master/canonical/skills/a/references/w.md#L1-L43' },
      },
    ],
  };
}

/**
 * Build the page shape the controller expects: a `.sl-markdown-content` scope
 * containing a `pre.mermaid` container with a rendered SVG.
 *
 * Deliberately contains NO `## Source fragments` list. Omitting it is the point:
 * it proves the panel's data path runs through the projection and never reads
 * delivery-004's DOM, which that feature forbids.
 */
function buildPage({ processed = true, withSvg = true, nodeIds = ['n1', 'n2'], island = projection() } = {}) {
  document.body.innerHTML = '';

  if (island !== null) {
    const script = document.createElement('script');
    script.type = 'application/json';
    script.id = 'aid-flow-data';
    script.textContent = JSON.stringify(island);
    document.body.appendChild(script);
  }

  const scope = document.createElement('div');
  scope.className = 'sl-markdown-content';

  const pre = document.createElement('pre');
  pre.className = 'mermaid';

  if (withSvg) pre.appendChild(buildSvg(nodeIds));
  if (processed) pre.setAttribute('data-processed', 'true');

  scope.appendChild(pre);
  document.body.appendChild(scope);
  return pre;
}

/**
 * A minimal rendered-chart SVG. Layer order matches mermaid: clusters, edgePaths,
 * edgeLabels, then nodes last. Node groups carry `node default <kind> aidNode`,
 * which is the real class attribute — the per-kind class sits between `default`
 * and `aidNode`.
 */
function buildSvg(nodeIds) {
  const svgNs = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(svgNs, 'svg');
  svg.setAttribute('id', DIAGRAM_ID);

  for (const layer of ['clusters', 'edgePaths', 'edgeLabels']) {
    const g = document.createElementNS(svgNs, 'g');
    g.setAttribute('class', layer);
    svg.appendChild(g);
  }

  const nodes = document.createElementNS(svgNs, 'g');
  nodes.setAttribute('class', 'nodes');
  nodeIds.forEach((id, i) => {
    const g = document.createElementNS(svgNs, 'g');
    g.setAttribute('class', 'node default aidStep aidNode');
    g.setAttribute('id', `${DIAGRAM_ID}-flowchart-${id}-${i}`);
    // A text child, so a click on descendant text still resolves via closest().
    const text = document.createElementNS(svgNs, 'text');
    text.textContent = id;
    g.appendChild(text);
    nodes.appendChild(g);
  });
  svg.appendChild(nodes);
  return svg;
}

/** Evaluate the shipped controller into the current jsdom document. */
function loadController() {
  // eslint-disable-next-line no-new-func
  new Function(SCRIPT_SRC)();
}

/** The decorated node group for a model id. */
function nodeFor(id) {
  return document.querySelector(`[data-aid-node="${id}"]`);
}

function panel() {
  return document.getElementById('aid-node-panel');
}

let warnSpy;

beforeEach(() => {
  warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
});

afterEach(() => {
  warnSpy.mockRestore();
  document.body.innerHTML = '';
});

// ── Activation ────────────────────────────────────────────────────────────────

describe('panel: activation', () => {
  it('clicking a node reveals the panel with that node\'s name, label, order and kind', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const p = panel();
    expect(p).not.toBeNull();
    expect(p.hidden).toBe(false);
    expect(p.querySelector('.aid-node-panel__bar h3 code').textContent).toBe('INTAKE');
    expect(p.querySelector('.aid-node-panel__label').textContent).toBe('Read the request');
    expect(p.querySelector('.aid-node-panel__order').textContent).toBe('1');
    expect(p.querySelector('.aid-node-panel__kind').textContent).toBe('entry');
  });

  it('the fragment survives byte-for-byte, including <, &, backticks and a pipe', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const expected = projection().nodes[0].fragment;
    // Non-vacuity: the fixture really does contain the hostile characters.
    expect(expected).toContain('<b>');
    expect(expected).toContain('&');
    expect(expected).toContain('````');
    expect(expected).toContain('|');
    expect(panel().querySelector('.aid-node-panel__fragment code').textContent).toBe(expected);
  });

  it('preserves a fragment\'s newlines and leading indentation', () => {
    buildPage();
    loadController();
    nodeFor('n2').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().querySelector('.aid-node-panel__fragment code').textContent)
      .toBe(projection().nodes[1].fragment);
  });

  it('renders the Source link at source.url, and the list hook to #fragment-<id>', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const hrefs = [...panel().querySelectorAll('.aid-node-panel__links a')].map((a) => a.getAttribute('href'));
    expect(hrefs).toContain(projection().nodes[0].source.url);
    expect(hrefs).toContain('#fragment-n1');
  });

  it('renders the full-step link only when detail is non-null', () => {
    buildPage();
    loadController();

    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const withoutDetail = [...panel().querySelectorAll('.aid-node-panel__links a')].map((a) => a.textContent);
    expect(withoutDetail).not.toContain('full step');

    nodeFor('n2').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const withDetail = [...panel().querySelectorAll('.aid-node-panel__links a')].map((a) => a.textContent);
    expect(withDetail).toContain('full step');
    expect([...panel().querySelectorAll('.aid-node-panel__links a')]
      .map((a) => a.getAttribute('href'))).toContain(projection().nodes[1].detail.url);
  });

  it('shows the exit marker only for a terminal node', () => {
    buildPage();
    loadController();

    nodeFor('n2').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const exitEl = panel().querySelector('.aid-node-panel__exit');
    expect(exitEl.textContent).toBe('HALT');
    expect(exitEl.hidden).toBe(false);

    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().querySelector('.aid-node-panel__exit').textContent).toBe('');
    expect(panel().querySelector('.aid-node-panel__exit').hidden).toBe(true);
  });

  it('resolves a click on a node\'s text descendant', () => {
    buildPage();
    loadController();
    nodeFor('n1').querySelector('text').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().hidden).toBe(false);
  });

  it('the panel is inserted after the chart container, in normal flow', () => {
    const pre = buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(pre.nextSibling).toBe(panel());
  });

  it('the heading is an h3, under the chart\'s H2', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().querySelector('.aid-node-panel__bar h3')).not.toBeNull();
  });
});

// ── Keyboard and ARIA ─────────────────────────────────────────────────────────

describe('panel: keyboard and ARIA', () => {
  function keydown(el, key) {
    const e = new window.KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
    el.dispatchEvent(e);
    return e;
  }

  it('Enter opens the panel', () => {
    buildPage();
    loadController();
    keydown(nodeFor('n1'), 'Enter');
    expect(panel().hidden).toBe(false);
  });

  it('Space opens the panel and prevents default, so the page does not scroll', () => {
    buildPage();
    loadController();
    const e = keydown(nodeFor('n1'), ' ');
    expect(panel().hidden).toBe(false);
    expect(e.defaultPrevented).toBe(true);
  });

  it('aria-expanded tracks open state on the activated node', () => {
    buildPage();
    loadController();
    const n1 = nodeFor('n1');
    expect(n1.getAttribute('aria-expanded')).toBe('false');
    n1.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(n1.getAttribute('aria-expanded')).toBe('true');
  });

  it('opening a different node clears the previous node\'s aria-expanded', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    nodeFor('n2').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(nodeFor('n1').getAttribute('aria-expanded')).toBe('false');
    expect(nodeFor('n2').getAttribute('aria-expanded')).toBe('true');
  });

  it('re-activating the open node toggles the panel closed', () => {
    buildPage();
    loadController();
    const n1 = nodeFor('n1');
    n1.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().hidden).toBe(false);
    n1.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().hidden).toBe(true);
    expect(n1.getAttribute('aria-expanded')).toBe('false');
  });

  it('every node\'s aria-controls names the panel that is actually created', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const created = panel().id;
    expect(created.length).toBeGreaterThan(3);
    for (const id of ['n1', 'n2']) {
      expect(nodeFor(id).getAttribute('aria-controls')).toBe(created);
    }
  });

  it('carries role, tabindex and a non-empty aria-label on every decorated node', () => {
    buildPage();
    loadController();
    for (const id of ['n1', 'n2']) {
      const n = nodeFor(id);
      expect(n.getAttribute('role')).toBe('button');
      expect(n.getAttribute('tabindex')).toBe('0');
      expect(n.getAttribute('aria-label').length).toBeGreaterThan(0);
    }
  });

  it('the close button closes the panel', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    panel().querySelector('.aid-node-panel__close')
      .dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(panel().hidden).toBe(true);
  });
});

// ── Focus ─────────────────────────────────────────────────────────────────────
//
// jsdom honours focus() on an HTML element carrying tabindex, which the panel is,
// so these two are meaningful here. Focus ORDER through an SVG <g> with tabindex,
// and screen-reader announcement, are not — they are manual gate checks.

describe('panel: focus', () => {
  it('opening moves focus to the panel', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    expect(document.activeElement).toBe(panel());
  });

  it('Escape closes and returns focus to the node that opened it', () => {
    buildPage();
    loadController();
    const n1 = nodeFor('n1');
    let focused = null;
    n1.focus = () => { focused = n1; };

    n1.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    panel().dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }));

    expect(panel().hidden).toBe(true);
    expect(n1.getAttribute('aria-expanded')).toBe('false');
    expect(focused).toBe(n1);
  });

  it('there is no focus trap: the panel is not aria-modal and takes tabindex -1', () => {
    buildPage();
    loadController();
    nodeFor('n1').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const p = panel();
    // -1 keeps the panel out of the tab sequence, so Tab continues into the page
    // and delivery-004's fragment list stays reachable while the panel is open.
    expect(p.getAttribute('tabindex')).toBe('-1');
    expect(p.hasAttribute('aria-modal')).toBe(false);
    expect(p.getAttribute('role')).not.toBe('dialog');
  });
});

// ── Static constraints ────────────────────────────────────────────────────────

describe('panel: the shipped file honours its constraints', () => {
  it('never uses innerHTML, so a fragment cannot be re-parsed as markup', () => {
    // Comments stripped, so the prohibition cannot be "satisfied" by prose.
    const code = SCRIPT_SRC.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    expect(code).not.toMatch(/\.innerHTML/);
  });

  // The panel's id and the value written into every node's aria-controls must come
  // from one declaration. Stating the id twice on two sides of a reference is how
  // both of this delivery's shipped defects happened. The CSS *class* string is a
  // separate concept — fixed by the Anatomy block and by the stylesheet — so it is
  // legitimately its own literal and is not counted here.
  it('sets both the panel id and aria-controls from the single PANEL_ID declaration', () => {
    const code = SCRIPT_SRC.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    expect(code).toMatch(/var PANEL_ID = 'aid-node-panel';/);
    expect(code).toMatch(/\.id = PANEL_ID/);
    expect(code).toMatch(/'aria-controls',\s*PANEL_ID/);
    // Neither site restates the literal.
    expect(code).not.toMatch(/'aria-controls',\s*'aid-node-panel'/);
    expect(code).not.toMatch(/\.id = 'aid-node-panel'/);
  });

  it('adds no forbidden runtime dependency', () => {
    const code = SCRIPT_SRC.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    expect(code).not.toMatch(/\bfetch\s*\(/);
    expect(code).not.toMatch(/localStorage|sessionStorage|document\.cookie/);
    expect(code).not.toMatch(/\beval\s*\(/);
  });
});
