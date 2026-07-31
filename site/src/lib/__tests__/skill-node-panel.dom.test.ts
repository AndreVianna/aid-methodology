// @vitest-environment jsdom
//
// feature-006 acceptance suite (task-053): the controller's lifecycle and ARIA
// behaviour against a real DOM. The rest of the repo's suites run in vitest's
// default `node` environment; this file opts itself in with the docblock above,
// which is the mechanism task-045 established and guards.
//
// Six groups: Activation, Keyboard + ARIA, Re-render survival, Degradation,
// Resolve-or-skip, Schema guard.
//
// ── Fixture shape, and a correction to this task's own DETAIL ─────────────────
//
// The DETAIL specifies node ids as `flowchart-<id>-<n>` and states that shape was
// "verified against the locked mermaid install". It was not: that is mermaid's
// internal `domId`, and what reaches the DOM is
//
//     mermaid-<diagramId>-flowchart-<id>-<n>
//
// measured in a browser on this site as `mermaid-11br4n7o5-flowchart-n2-1`,
// `mermaid-rkijoq1pv-flowchart-n10-9` and `mermaid-23qhs6d31-flowchart-n1-0` —
// the diagram id differing on every render. Building fixtures the DETAIL's way is
// exactly how task-049 shipped a start-anchored pattern that matched 0 of 10 real
// nodes while its own suite stayed green, so the measurement wins here. Recorded
// as delivery-005 STATE Q4. The real class attribute is likewise
// `node default <kind> aidNode`, with the per-kind class the DETAIL omits.
//
// ── Why focus placement is not asserted here ──────────────────────────────────
//
// jsdom's focusable-area model does not reliably treat an SVG <g> carrying
// tabindex as focusable, so `document.activeElement` on a node would prove nothing
// about a real browser. This suite therefore asserts the attributes and state that
// make focus possible — role, tabindex, aria-label, aria-controls, aria-expanded.
// Focus order, focus return, screen-reader announcement and the 360 px layout are
// the four checks performed once by hand at the delivery gate. (Focus landing on
// the panel, which is an HTML element with tabindex and which jsdom does honour, is
// asserted in scripts/__tests__/skill-node-panel-panel.test.mjs.)

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const moduleDir = dirname(fileURLToPath(import.meta.url));
const CONTROLLER_SRC = readFileSync(
  resolve(moduleDir, '../../../public/skill-node-panel.mjs'),
  'utf8',
);

const SVG_NS = 'http://www.w3.org/2000/svg';

/** A per-render diagram id, in mermaid's real format. */
let diagramId = 'mermaid-rkijoq1pv';

interface FixtureNode {
  id: string;
  order: number;
  name: string;
  label: string;
  kind: string;
  exit: { advanceType: string; handoff: string | null } | null;
  fragment: string;
  source: { url: string };
  detail: { url: string } | null;
}

function projection(): { v: number; skill: string; confidence: string; nodes: FixtureNode[] } {
  return {
    v: 1,
    skill: 'aid-fixture',
    confidence: 'derived',
    nodes: [
      {
        id: 'n1', order: 1, name: 'INTAKE', label: 'Read the request', kind: 'entry',
        exit: null,
        fragment: '## State: INTAKE\n\n  a <b>tagged</b> & piped | line\n',
        source: { url: 'https://github.com/o/r/blob/master/canonical/skills/a/SKILL.md#L5' },
        detail: null,
      },
      {
        id: 'n2', order: 2, name: 'DONE', label: 'Hand back', kind: 'exit',
        exit: { advanceType: 'HALT', handoff: null },
        fragment: '| DONE | `references/w.md` | HALT |',
        source: { url: 'https://github.com/o/r/blob/master/canonical/skills/a/SKILL.md#L9-L12' },
        detail: { url: 'https://github.com/o/r/blob/master/canonical/skills/a/references/w.md#L1-L43' },
      },
    ],
  };
}

/**
 * Build a rendered-chart SVG in mermaid's layer order: clusters, edgePaths,
 * edgeLabels, then nodes last.
 */
function buildSvg(nodeIds: string[], kinds: string[] = []): SVGElement {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('id', diagramId);

  for (const layer of ['clusters', 'edgePaths', 'edgeLabels']) {
    const g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('class', layer);
    svg.appendChild(g);
  }

  const nodes = document.createElementNS(SVG_NS, 'g');
  nodes.setAttribute('class', 'nodes');
  nodeIds.forEach((id, i) => {
    const g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('class', `node default ${kinds[i] || 'aidStep'} aidNode`);
    g.setAttribute('id', `${diagramId}-flowchart-${id}-${i}`);
    const text = document.createElementNS(SVG_NS, 'text');
    text.textContent = id;
    g.appendChild(text);
    nodes.appendChild(g);
  });
  svg.appendChild(nodes);
  return svg;
}

interface PageOptions {
  processed?: boolean;
  withSvg?: boolean;
  errorDiv?: boolean;
  nodeIds?: string[];
  island?: unknown;
}

/**
 * Build the page the controller expects.
 *
 * The Activation fixture deliberately contains **no `## Source fragments` list**.
 * Omitting it is the point: it proves the panel's data path runs through the
 * projection and never reads delivery-004's DOM, which that feature forbids.
 */
function buildPage(opts: PageOptions = {}): HTMLElement {
  const {
    processed = true, withSvg = true, errorDiv = false,
    nodeIds = ['n1', 'n2'], island = projection(),
  } = opts;

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

  if (withSvg) pre.appendChild(buildSvg(nodeIds, ['aidEntry', 'aidExit']));
  if (errorDiv) {
    const err = document.createElement('div');
    err.textContent = 'Syntax error in text';
    pre.appendChild(err);
  }
  if (processed) pre.setAttribute('data-processed', 'true');

  scope.appendChild(pre);
  document.body.appendChild(scope);
  return pre;
}

/** Evaluate the shipped controller into the current document. */
function loadController(): void {
  new Function(CONTROLLER_SRC)();
}

function nodeFor(id: string): Element | null {
  return document.querySelector(`[data-aid-node="${id}"]`);
}

function panel(): HTMLElement | null {
  return document.getElementById('aid-node-panel');
}

function click(el: Element): void {
  el.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
}

function keydown(el: Element, key: string): KeyboardEvent {
  const e = new window.KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
  el.dispatchEvent(e);
  return e;
}

/**
 * Let the MutationObserver callback run.
 *
 * MutationObserver delivers records asynchronously — on the microtask queue — so
 * decoration triggered by swapping the SVG or setting `data-processed` has not
 * happened yet when the mutating statement returns. Anything asserting the
 * observer's effect must await this first; without it the assertion reads as
 * "decoration never happened" when in fact it had not happened *yet*.
 */
function flushObserver(): Promise<void> {
  return new Promise((r) => setTimeout(r, 0));
}

let warnSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  diagramId = 'mermaid-rkijoq1pv';
  warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
});

afterEach(() => {
  warnSpy.mockRestore();
  // Each case tears down its own document so no state leaks between tests.
  document.body.innerHTML = '';
});

// ── 1. Activation (AC-6.1) ────────────────────────────────────────────────────

describe('AC-6.1 activation', () => {
  it('reveals the panel with the node\'s name, label, order and kind', () => {
    buildPage();
    loadController();
    click(nodeFor('n1')!);

    const p = panel()!;
    expect(p.hidden).toBe(false);
    expect(p.querySelector('.aid-node-panel__bar h3 code')!.textContent).toBe('INTAKE');
    expect(p.querySelector('.aid-node-panel__label')!.textContent).toBe('Read the request');
    expect(p.querySelector('.aid-node-panel__order')!.textContent).toBe('1');
    expect(p.querySelector('.aid-node-panel__kind')!.textContent).toBe('entry');
  });

  it('puts the fragment in a <pre> whose textContent equals the projection exactly', () => {
    buildPage();
    loadController();
    click(nodeFor('n1')!);

    const expected = projection().nodes[0].fragment;
    // Non-vacuity: the fragment really carries characters that HTML would reinterpret.
    expect(expected).toContain('<b>');
    expect(expected).toContain('&');
    expect(expected).toContain('|');
    expect(expected).toContain('\n');

    const pre = panel()!.querySelector('pre.aid-node-panel__fragment')!;
    expect(pre.querySelector('code')!.textContent).toBe(expected);
  });

  it('links Source at source.url, full step iff detail is non-null, and #fragment-<id>', () => {
    buildPage();
    loadController();

    click(nodeFor('n1')!);
    let hrefs = [...panel()!.querySelectorAll('.aid-node-panel__links a')]
      .map((a) => a.getAttribute('href'));
    expect(hrefs).toContain(projection().nodes[0].source.url);
    expect(hrefs).toContain('#fragment-n1');
    expect(hrefs).not.toContain(projection().nodes[1].detail!.url);

    click(nodeFor('n2')!);
    hrefs = [...panel()!.querySelectorAll('.aid-node-panel__links a')]
      .map((a) => a.getAttribute('href'));
    expect(hrefs).toContain(projection().nodes[1].detail!.url);
    expect(hrefs).toContain('#fragment-n2');
  });

  it('reads nothing from a fragment list, because the fixture has none', () => {
    buildPage();
    loadController();
    // Precondition: the page genuinely contains no fragment list to read.
    expect(document.querySelector('#fragment-n1')).toBeNull();
    expect(document.body.textContent).not.toContain('Source fragments');

    click(nodeFor('n1')!);
    // The panel still has the full fragment, so it came from the projection.
    expect(panel()!.querySelector('.aid-node-panel__fragment code')!.textContent)
      .toBe(projection().nodes[0].fragment);
  });
});

// ── 2. Keyboard + ARIA (AC-6.2) ───────────────────────────────────────────────

describe('AC-6.2 keyboard and ARIA', () => {
  it('every decorated node carries role, tabindex, a non-empty aria-label and aria-controls', () => {
    buildPage();
    loadController();

    const nodes = [...document.querySelectorAll('[data-aid-node]')];
    expect(nodes).toHaveLength(2);
    for (const n of nodes) {
      expect(n.getAttribute('role')).toBe('button');
      expect(n.getAttribute('tabindex')).toBe('0');
      expect(n.getAttribute('aria-label')!.length).toBeGreaterThan(0);
      expect(n.getAttribute('aria-expanded')).toBe('false');
    }
  });

  it('aria-controls names the panel element that is actually created', () => {
    buildPage();
    loadController();
    click(nodeFor('n1')!);
    const createdId = panel()!.id;
    expect(createdId.length).toBeGreaterThan(3);
    for (const n of document.querySelectorAll('[data-aid-node]')) {
      expect(n.getAttribute('aria-controls')).toBe(createdId);
    }
  });

  it('Enter opens', () => {
    buildPage();
    loadController();
    keydown(nodeFor('n1')!, 'Enter');
    expect(panel()!.hidden).toBe(false);
  });

  it('Space opens and prevents default', () => {
    buildPage();
    loadController();
    const e = keydown(nodeFor('n1')!, ' ');
    expect(panel()!.hidden).toBe(false);
    expect(e.defaultPrevented).toBe(true);
  });

  it('Escape closes and resets aria-expanded', () => {
    buildPage();
    loadController();
    const n1 = nodeFor('n1')!;
    click(n1);
    expect(n1.getAttribute('aria-expanded')).toBe('true');

    keydown(panel()!, 'Escape');
    expect(panel()!.hidden).toBe(true);
    expect(n1.getAttribute('aria-expanded')).toBe('false');
  });

  it('re-activating the open node toggles it closed', () => {
    buildPage();
    loadController();
    const n1 = nodeFor('n1')!;
    click(n1);
    click(n1);
    expect(panel()!.hidden).toBe(true);
    expect(n1.getAttribute('aria-expanded')).toBe('false');
  });

  it('is a disclosure, not a dialog: no focus trap, no modal semantics', () => {
    buildPage();
    loadController();
    click(nodeFor('n1')!);
    const p = panel()!;
    expect(p.getAttribute('role')).not.toBe('dialog');
    expect(p.hasAttribute('aria-modal')).toBe(false);
    // tabindex -1 keeps the panel out of the tab sequence, so Tab continues into
    // the page and delivery-004's list stays reachable while the panel is open.
    expect(p.getAttribute('tabindex')).toBe('-1');
  });
});

// ── 3. Re-render survival (AC-6.3) ────────────────────────────────────────────

describe('AC-6.3 re-render survival', () => {
  it('decorates the new nodes and opens exactly one panel per activation, over three cycles', async () => {
    const pre = buildPage();
    loadController();

    let opens = 0;
    for (let cycle = 0; cycle < 3; cycle++) {
      // The integration's exact order: drop data-processed, swap the SVG, set it again.
      pre.removeAttribute('data-processed');
      pre.innerHTML = '';
      diagramId = `mermaid-cycle${cycle}`;
      pre.appendChild(buildSvg(['n1', 'n2'], ['aidEntry', 'aidExit']));
      pre.setAttribute('data-processed', 'true');
      await flushObserver();

      const decorated = [...document.querySelectorAll('[data-aid-node]')];
      expect(decorated, `cycle ${cycle}`).toHaveLength(2);
      // The ids changed with the diagram id, so these are genuinely new elements.
      expect(decorated[0].id, `cycle ${cycle}`).toContain(`mermaid-cycle${cycle}`);

      const before = panel();
      click(nodeFor('n1')!);
      const after = panel()!;
      expect(after.hidden, `cycle ${cycle}`).toBe(false);
      // One panel element for the page, reused rather than duplicated.
      if (before) expect(after, `cycle ${cycle}`).toBe(before);
      expect(document.querySelectorAll('.aid-node-panel'), `cycle ${cycle}`).toHaveLength(1);
      opens++;

      click(nodeFor('n1')!); // close again, so each cycle starts from the same state
    }

    expect(opens).toBe(3);
  });

  it('binds handlers once: the container gains no duplicate listeners across cycles', async () => {
    const pre = buildPage();
    const added: string[] = [];
    const realAdd = pre.addEventListener.bind(pre);
    pre.addEventListener = ((type: string, fn: EventListener) => {
      added.push(type);
      return realAdd(type, fn);
    }) as typeof pre.addEventListener;

    loadController();
    const afterLoad = added.length;
    expect(afterLoad).toBeGreaterThan(0);

    for (let cycle = 0; cycle < 3; cycle++) {
      pre.removeAttribute('data-processed');
      pre.innerHTML = '';
      pre.appendChild(buildSvg(['n1', 'n2']));
      pre.setAttribute('data-processed', 'true');
      await flushObserver();
    }

    expect(added.length).toBe(afterLoad);
  });
});

// ── 4. Degradation (AC-6.4) ───────────────────────────────────────────────────

describe('AC-6.4 degradation', () => {
  it('(a) no data-processed: no decoration, no panel, no throw', () => {
    buildPage({ processed: false });
    expect(() => loadController()).not.toThrow();
    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(0);
    expect(panel()).toBeNull();
  });

  it('(b) data-processed set after load triggers decoration on the mutation', async () => {
    const pre = buildPage({ processed: false });
    loadController();
    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(0);

    pre.setAttribute('data-processed', 'true');
    await flushObserver();
    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(2);
  });

  it('(c) failed render — data-processed with an error div and no svg: no decoration, one warning', () => {
    buildPage({ withSvg: false, errorDiv: true });
    expect(() => loadController()).not.toThrow();
    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(0);
    expect(panel()).toBeNull();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(String(warnSpy.mock.calls[0][0])).toContain('panel nodes');
  });
});

// ── 5. Resolve-or-skip ────────────────────────────────────────────────────────

describe('resolve-or-skip', () => {
  it('leaves an unmatched id and an unknown model id undecorated while siblings work', async () => {
    buildPage();
    loadController();

    // Rebuild the nodes layer with one malformed id and one id absent from the
    // projection, alongside a good node.
    const pre = document.querySelector('pre.mermaid')!;
    pre.removeAttribute('data-processed');
    pre.innerHTML = '';
    const svg = buildSvg(['n1']);
    const nodesLayer = svg.querySelector('g.nodes')!;

    const malformed = document.createElementNS(SVG_NS, 'g');
    malformed.setAttribute('class', 'node default aidStep aidNode');
    malformed.setAttribute('id', `${diagramId}-not-a-node`);
    nodesLayer.appendChild(malformed);

    const unknown = document.createElementNS(SVG_NS, 'g');
    unknown.setAttribute('class', 'node default aidStep aidNode');
    unknown.setAttribute('id', `${diagramId}-flowchart-n99-7`);
    nodesLayer.appendChild(unknown);

    pre.appendChild(svg);
    pre.setAttribute('data-processed', 'true');
    await flushObserver();

    expect(malformed.hasAttribute('data-aid-node')).toBe(false);
    expect(malformed.hasAttribute('role')).toBe(false);
    expect(unknown.hasAttribute('data-aid-node')).toBe(false);
    // The sibling still works, so skipping is per-node and not fatal.
    expect(nodeFor('n1')).not.toBeNull();
    click(nodeFor('n1')!);
    expect(panel()!.hidden).toBe(false);
  });

  it('warns once per page, not once per unresolvable node', () => {
    // A chart where NOTHING resolves: two nodes, both absent from the projection.
    buildPage({ nodeIds: ['n77', 'n88'] });
    loadController();

    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(0);
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });
});

// ── 6. Schema guard ───────────────────────────────────────────────────────────

describe('schema guard', () => {
  it('v: 2 makes the controller no-op entirely and warn once', () => {
    const stale = projection() as unknown as { v: number };
    stale.v = 2;
    buildPage({ island: stale });
    loadController();

    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(0);
    expect(panel()).toBeNull();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(String(warnSpy.mock.calls[0][0])).toContain('panel schema');
  });

  it('a missing island warns once and changes no DOM', () => {
    buildPage({ island: null });
    const before = document.body.innerHTML;
    loadController();
    expect(document.body.innerHTML).toBe(before);
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(String(warnSpy.mock.calls[0][0])).toContain('panel data');
  });

  it('v: 1 is accepted — non-vacuity for the two guards above', () => {
    buildPage();
    loadController();
    expect(document.querySelectorAll('[data-aid-node]')).toHaveLength(2);
    expect(warnSpy).not.toHaveBeenCalled();
  });
});
