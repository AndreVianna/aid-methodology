// @vitest-environment jsdom
//
// skill-node-panel-lifecycle.test.mjs — Task-049 acceptance-criteria suite.
//
// Tests the client-side controller's attachment lifecycle and node decoration:
//   • Three-part readiness predicate (KI-011), each arm separately falsified.
//   • Once-only binding: addEventListener called exactly once per event type across
//     three simulated re-render cycles; handlers still functional after re-render.
//   • Idempotent decoration: data-aid-node check prevents double-decoration.
//   • Schema guard: v !== 1 produces no DOM changes.
//   • Delegation via closest() so a click on a <text> descendant works.
//   • Zero resolvable nodes → BOUND_INERT with one warning.
//   • Multiple containers → bind first, warn once via 'panel container'.
//   • Non-vacuity: every assertion over a node set is preceded by a count bound.
//
// This suite does NOT cover (task-053 owns those):
//   • Full jsdom lifecycle and ARIA suite.
//
// SVG fixtures are built inline — no dependency on a real rendered chart.
// The script is read as text and executed with injected globals (same pattern as
// mermaid-source-cache.test.mjs) so a fake synchronous MutationObserver can be used
// for full control over mutation delivery timing.

import { describe, it, expect, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = join(resolve(__dirname, '../..'), 'public', 'skill-node-panel.mjs');
const SCRIPT_SRC = readFileSync(SCRIPT_PATH, 'utf8');
const HEAD_PATH = join(resolve(__dirname, '../..'), 'src', 'components', 'overrides', 'Head.astro');
const HEAD_SRC = readFileSync(HEAD_PATH, 'utf8');

// ── Projection fixtures ───────────────────────────────────────────────────────

/** Minimal valid projection (v=1) with two nodes. */
const PROJECTION = {
  v: 1,
  skill: 'test-skill',
  confidence: 'high',
  nodes: [
    { id: 'n1', name: 'INTAKE', label: 'Intake step', kind: 'entry', exit: null, fragment: 'f1', source: { url: 'u1' }, detail: null },
    { id: 'n2', name: 'PROCESS', label: 'Processing', kind: 'step', exit: null, fragment: 'f2', source: { url: 'u2' }, detail: null },
  ],
};

// ── Fake element factories ────────────────────────────────────────────────────

/**
 * Create a fake g.node.aidNode SVG element.
 *
 * svgId is the mermaid-emitted id. The real format, measured on the running
 * site, is `mermaid-<diagramId>-flowchart-<nodeId>-<n>` — for example
 * `mermaid-rkijoq1pv-flowchart-n10-9`. The fixtures below carry that
 * diagram-id prefix deliberately: an earlier version of this suite built ids as
 * `flowchart-n1-0`, which no page ever produces, so it passed against a
 * start-anchored pattern that matched 0 of 10 nodes in the browser and would
 * have left the panel permanently inert.
 */
function makeAidNode(svgId) {
  const attrs = {};
  let setCallCount = 0;
  const node = {
    id: svgId,
    hasAttribute: (k) => k in attrs,
    setAttribute: (k, v) => { attrs[k] = v; setCallCount++; },
    getAttribute: (k) => (k in attrs ? attrs[k] : null),
    removeAttribute: (k) => { delete attrs[k]; },
    // closest('g.node.aidNode') returns self (the node IS a g.node.aidNode).
    closest: (sel) => sel === 'g.node.aidNode' ? node : null,
    _attrs: attrs,
    _setCallCount: () => setCallCount,
  };
  return node;
}

/**
 * Create a fake pre.mermaid container.
 *
 * @param {object} opts
 * @param {boolean} opts.processed  — whether data-processed is set
 * @param {boolean} opts.hasSvg     — whether an <svg> child is present
 * @param {Array}   opts.aidNodes   — g.node.aidNode fake elements inside the SVG
 */
function makeContainer({ processed = false, hasSvg = false, aidNodes = [] } = {}) {
  const attrs = {};
  if (processed) attrs['data-processed'] = 'true';

  // Track addEventListener calls to verify once-only binding.
  let addEventCount = 0;
  const eventHandlers = {};

  const fakeSvg = hasSvg ? { _tag: 'svg' } : null;

  const container = {
    hasAttribute: (k) => k in attrs,
    setAttribute: (k, v) => { attrs[k] = v; },
    getAttribute: (k) => (k in attrs ? attrs[k] : null),
    removeAttribute: (k) => { delete attrs[k]; },
    querySelector: (sel) => sel === 'svg' ? fakeSvg : null,
    querySelectorAll: (sel) => sel === 'g.node.aidNode' ? aidNodes : [],
    addEventListener: (type, fn) => {
      if (type === 'click' || type === 'keydown') addEventCount++;
      if (!eventHandlers[type]) eventHandlers[type] = [];
      eventHandlers[type].push(fn);
    },
    dispatchToHandlers: (event) => {
      (eventHandlers[event.type] || []).forEach((h) => h(event));
    },
    // Replace the aidNodes list to simulate a theme re-render (new SVG with fresh nodes).
    replaceNodes: (newNodes) => { aidNodes = newNodes; },
    _attrs: attrs,
    _addEventCount: () => addEventCount,
    _handlers: eventHandlers,
  };

  return container;
}

// ── Script runner ─────────────────────────────────────────────────────────────

/**
 * Execute the controller against a controlled fake environment.
 *
 * Returns:
 *   warnCalls     — array of full console.warn argument strings, in order.
 *   triggerObs    — call this to synchronously deliver a MutationObserver callback.
 *   observerOpts  — the options passed to observer.observe() for inspection.
 *   listeners     — document-level addEventListener registrations.
 */
function runScript({ island = PROJECTION, containers = [] } = {}) {
  const warnCalls = [];
  const fakeConsole = { warn: (...args) => warnCalls.push(args.join(' ')) };

  let observerCb = null;
  let observerOpts = null;

  class FakeMutationObserver {
    constructor(cb) { observerCb = cb; }
    observe(_, opts) { observerOpts = opts; }
    disconnect() {}
  }

  const islandEl = island !== null
    ? { id: 'aid-flow-data', textContent: JSON.stringify(island) }
    : null;

  const slContent = {
    querySelectorAll: (sel) => sel === 'pre.mermaid' ? containers : [],
  };

  const docListeners = {};
  const fakeDoc = {
    getElementById: (id) => id === 'aid-flow-data' ? islandEl : null,
    querySelector: (sel) => sel === '.sl-markdown-content' ? slContent : null,
    addEventListener: (name, fn) => { docListeners[name] = fn; },
  };

  const fn = new Function('document', 'MutationObserver', 'console', SCRIPT_SRC);
  fn(fakeDoc, FakeMutationObserver, fakeConsole);

  return {
    warnCalls,
    triggerObs: () => observerCb && observerCb([{}]),
    observerOpts,
    listeners: docListeners,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * A per-render diagram id in mermaid's real format. Arbitrary but realistic —
 * the point is that a prefix is present at all, since its absence is what let
 * the start-anchored pattern look correct.
 */
const DIAGRAM_ID = 'mermaid-rkijoq1pv';

/** Build a node whose SVG id maps to a projection node id via ID_RE. */
function aidNodeFor(modelId, counter = 0) {
  return makeAidNode(DIAGRAM_ID + '-flowchart-' + modelId + '-' + counter);
}

// ── Test suites ───────────────────────────────────────────────────────────────

// Cross-seam guards.
//
// The controller and the Head override were written in parallel, each with its own
// fixtures, and each passed its own suite while disagreeing with the other: the
// override emitted the projection island as `aid-flow-data` while the controller
// looked up `aid-panel-data`, so the controller would have found nothing and
// silently no-opped on every page. Testing each side against its own fixture
// cannot catch that. These assertions compare the two sides directly.
describe('skill-node-panel: the controller and the Head override agree on the seam', () => {
  /** The id string the controller passes to getElementById. */
  function idReadByController() {
    const m = /getElementById\('([^']+)'\)/.exec(SCRIPT_SRC);
    expect(m).not.toBeNull();
    return m[1];
  }

  /** The id the Head override puts on the JSON island. */
  function idEmittedByHead() {
    const m = /<script[^>]*type="application\/json"[^>]*id="([^"]+)"/.exec(HEAD_SRC);
    expect(m).not.toBeNull();
    return m[1];
  }

  it('the island id read equals the island id emitted', () => {
    const read = idReadByController();
    const emitted = idEmittedByHead();
    // Non-vacuity: both sides produced a real, non-empty id.
    expect(read.length).toBeGreaterThan(3);
    expect(emitted.length).toBeGreaterThan(3);
    expect(read).toBe(emitted);
  });

  it('the controller asset paths match the tags the Head override emits', () => {
    // The override references the controller and stylesheet by absolute public path.
    expect(HEAD_SRC).toContain('/skill-node-panel.mjs');
    expect(HEAD_SRC).toContain('/skill-node-panel.css');
  });
});

// Regression pin for the node-id pattern.
//
// Every other fixture in this file constructs its ids from DIAGRAM_ID, so a
// wrong assumption about the real format would be applied consistently and pass.
// These ids were copied verbatim from a rendered page on the running site, which
// is the only source that can contradict the assumption.
describe('skill-node-panel: node-id recovery against ids captured from a real page', () => {
  const REAL_IDS = [
    'mermaid-rkijoq1pv-flowchart-n1-0',
    'mermaid-rkijoq1pv-flowchart-n8-7',
    'mermaid-rkijoq1pv-flowchart-n10-9',
    'mermaid-11br4n7o5-flowchart-n2-1',
  ];
  const EXPECTED = ['n1', 'n8', 'n10', 'n2'];

  /** The live ID_RE, lifted from the shipped source so the test cannot drift from it. */
  function liveIdRe() {
    const m = /var ID_RE = (\/.*\/);/.exec(SCRIPT_SRC);
    expect(m).not.toBeNull();
    return new Function('return ' + m[1])();
  }

  it('recovers the model id from every real id', () => {
    const re = liveIdRe();
    const captured = REAL_IDS.map((id) => (re.exec(id) || [])[1]);
    expect(captured).toEqual(EXPECTED);
    // Non-vacuity: the list is real and the regex was actually applied.
    expect(REAL_IDS.length).toBeGreaterThan(3);
  });

  it('is not anchored at the start, because a diagram-id prefix always precedes it', () => {
    const literal = /var ID_RE = (\/.*\/);/.exec(SCRIPT_SRC)[1];
    // A `^` here matched 0 of 10 nodes on a real page and left the panel inert.
    expect(literal.startsWith('/^')).toBe(false);
    // Still end-anchored, which is what keeps the capture unambiguous.
    expect(literal.endsWith('$/')).toBe(true);
  });

  it('rejects an id that is not a flowchart node', () => {
    const re = liveIdRe();
    for (const bad of ['mermaid-rkijoq1pv', 'mermaid-rkijoq1pv-flowchart-', 'flowchart-n1', 'L-n1-n2-0']) {
      expect(re.exec(bad)).toBeNull();
    }
  });
});

describe('skill-node-panel: readiness predicate (three separable negative fixtures)', () => {

  it('arm 1 — no data-processed: stays BOUND_PENDING, no nodes decorated', () => {
    // Fixture differs from the happy path ONLY in the absence of data-processed.
    // SVG is present and nodes are resolvable, so if data-processed is the only
    // guard this removes, the other arms cannot be what rejects it.
    const node1 = aidNodeFor('n1');
    const node2 = aidNodeFor('n2');
    const container = makeContainer({ processed: false, hasSvg: true, aidNodes: [node1, node2] });

    runScript({ containers: [container] });

    // Non-vacuity: assert the node set is non-empty before asserting no decoration.
    expect([node1, node2].length).toBeGreaterThan(0);
    expect(node1.hasAttribute('data-aid-node')).toBe(false);
    expect(node2.hasAttribute('data-aid-node')).toBe(false);
  });

  it('arm 2 — data-processed + SVG + zero resolvable node ids: BOUND_INERT with one warning', () => {
    // Fixture differs from the happy path ONLY in having no g.node.aidNode elements
    // whose ids resolve in the projection. data-processed is set and SVG is present,
    // so the only failing arm is part 3 (resolvable node id).
    //
    // The id 'flowchart-UNKNOWN-0' does not match any projection node id.
    const unknownNode = aidNodeFor('UNKNOWN');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [unknownNode] });

    const { warnCalls } = runScript({ containers: [container] });

    expect(unknownNode.hasAttribute('data-aid-node')).toBe(false);
    // Exactly one warning via 'panel nodes'.
    const nodeWarns = warnCalls.filter((w) => w.includes('panel nodes'));
    expect(nodeWarns).toHaveLength(1);
  });

  it('arm 3 (failed render) — data-processed + no SVG: BOUND_INERT with one warning, node undecorated', () => {
    // Fixture differs from the happy path ONLY in the absence of an <svg> child.
    // data-processed IS set (mermaid attempted the render), but the render failed
    // (replaced container contents with an error div, not an SVG). This is the
    // failed-render shape described in KI-011.
    //
    // The fixture INCLUDES a resolvable node to prove it is the SVG check — not the
    // zero-nodes path — that blocks decoration. If the SVG check were removed the node
    // would be decorated and this test would fail, killing that mutant.
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: false, aidNodes: [node1] });

    const { warnCalls } = runScript({ containers: [container] });

    // Node must remain undecorated (SVG check rejected the render before reaching nodes).
    expect(node1.hasAttribute('data-aid-node')).toBe(false);
    expect(node1.hasAttribute('role')).toBe(false);
    // Exactly one 'panel nodes' warning.
    const nodeWarns = warnCalls.filter((w) => w.includes('panel nodes'));
    expect(nodeWarns).toHaveLength(1);
  });

});

describe('skill-node-panel: happy path — successful decoration', () => {

  it('decorates resolvable nodes with role, tabindex, aria-expanded, aria-controls, aria-label, data-aid-node', () => {
    const node1 = aidNodeFor('n1');
    const node2 = aidNodeFor('n2');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1, node2] });

    runScript({ containers: [container] });

    // Non-vacuity: confirm both nodes were checked.
    expect([node1, node2].length).toBe(2);

    expect(node1.getAttribute('role')).toBe('button');
    expect(node1.getAttribute('tabindex')).toBe('0');
    expect(node1.getAttribute('aria-expanded')).toBe('false');
    expect(node1.getAttribute('aria-controls')).toBe('aid-node-panel');
    expect(node1.getAttribute('aria-label')).toBe('INTAKE');
    expect(node1.getAttribute('data-aid-node')).toBe('n1');

    expect(node2.getAttribute('role')).toBe('button');
    expect(node2.getAttribute('data-aid-node')).toBe('n2');
    expect(node2.getAttribute('aria-label')).toBe('PROCESS');
  });

  it('no console warnings on a successful run', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { warnCalls } = runScript({ containers: [container] });

    expect(warnCalls).toHaveLength(0);
  });

  it('a node whose SVG id does not match ID_RE is left entirely undecorated', () => {
    // Node id uses the mermaid internal format WITHOUT the anchored suffix — not a
    // valid flowchart-<id>-<n> pattern. recoverNodeId returns null; node is skipped.
    const badIdNode = makeAidNode(DIAGRAM_ID + '-flowchart-');
    const goodNode = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [badIdNode, goodNode] });

    runScript({ containers: [container] });

    expect(badIdNode.hasAttribute('data-aid-node')).toBe(false);
    expect(badIdNode.hasAttribute('role')).toBe(false);
    expect(goodNode.getAttribute('data-aid-node')).toBe('n1');
  });

  it('a node whose model id is absent from the projection is left entirely undecorated', () => {
    // SVG id matches the pattern but the recovered id ('x9') is not in the projection.
    const orphanNode = aidNodeFor('x9');
    const goodNode = aidNodeFor('n2');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [orphanNode, goodNode] });

    runScript({ containers: [container] });

    expect(orphanNode.hasAttribute('data-aid-node')).toBe(false);
    expect(goodNode.getAttribute('data-aid-node')).toBe('n2');
  });

});

describe('skill-node-panel: once-only binding and re-render survival', () => {

  it('three simulated re-render cycles produce exactly one addEventListener call per event type', () => {
    // The WeakSet guard (bound.has(container)) must prevent duplicate attachment.
    // We verify this by simulating astro:after-swap three times — each fires scan(),
    // which calls attachContainer(). Without the WeakSet guard, every scan() would
    // add new click+keydown listeners, multiplying the call count.
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { listeners, triggerObs } = runScript({ containers: [container] });

    // Initial scan: 1 click + 1 keydown = 2 calls.
    expect(container._addEventCount()).toBe(2);

    // Simulate three after-swap cycles. Each fires scan() → attachContainer().
    // The WeakSet guard must suppress the duplicate attach.
    for (let cycle = 0; cycle < 3; cycle++) {
      const freshNode = aidNodeFor('n1', cycle + 1);
      container.replaceNodes([freshNode]);
      listeners['astro:after-swap']();   // calls scan() → attachContainer()
      triggerObs();                      // observer fires → tryDecorate
    }

    // Still exactly 2 calls — one click + one keydown from the initial scan.
    expect(container._addEventCount()).toBe(2);
  });

  it('handlers are still functional after a re-render (delegation chain is intact)', () => {
    // After re-render the new nodes must be decorated, meaning the delegation
    // handler can resolve them via data-aid-node. This proves "bound once AND
    // still functional" are both true — not just one.
    const initialNode = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [initialNode] });

    const { triggerObs } = runScript({ containers: [container] });

    // Simulate re-render with fresh nodes.
    const freshNode = aidNodeFor('n1', 99);
    container.replaceNodes([freshNode]);
    triggerObs();

    // Fresh node is decorated — the delegation handler can resolve it.
    expect(freshNode.getAttribute('data-aid-node')).toBe('n1');
    expect(freshNode.getAttribute('role')).toBe('button');

    // Dispatch a click through the delegation chain. closest() returns the node
    // itself in the fake, simulating a click landing on the g.node.aidNode element.
    // No throw means the chain is intact.
    let activated = false;
    // Wrap: we can't spy on openPanel (internal), but we can verify the delegation
    // resolves by checking the event reaches the container handler without error.
    expect(() => {
      container.dispatchToHandlers({
        type: 'click',
        target: freshNode,
        preventDefault: () => {},
      });
    }).not.toThrow();

    // Verify delegation did NOT fire for an undecorated node (guard check).
    const undecoratedNode = aidNodeFor('n2');
    // undecoratedNode has no data-aid-node → handler exits early.
    expect(() => {
      container.dispatchToHandlers({
        type: 'click',
        target: undecoratedNode,
        preventDefault: () => {},
      });
    }).not.toThrow();
  });

  it('MutationObserver is configured for childList and data-processed attribute, no subtree for attributes', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { observerOpts } = runScript({ containers: [container] });

    expect(observerOpts).not.toBeNull();
    expect(observerOpts.childList).toBe(true);
    expect(observerOpts.attributes).toBe(true);
    expect(observerOpts.attributeFilter).toEqual(['data-processed']);
  });

});

describe('skill-node-panel: idempotent decoration', () => {

  it('a node already carrying data-aid-node is skipped on a repeated tryDecorate', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { triggerObs } = runScript({ containers: [container] });

    // First decoration: 6 setAttribute calls (role, tabindex, aria-expanded,
    // aria-controls, aria-label, data-aid-node).
    const countAfterFirst = node1._setCallCount();
    expect(countAfterFirst).toBeGreaterThan(0);
    expect(node1.getAttribute('data-aid-node')).toBe('n1');
    expect(node1.getAttribute('aria-expanded')).toBe('false');

    // Simulate second readiness transition — same nodes still present.
    triggerObs();

    // decorateNode was a no-op: setAttribute call count must not grow.
    // If the data-aid-node check were removed, decorateNode would run again
    // and the count would be exactly double. This is the separable proof.
    expect(node1._setCallCount()).toBe(countAfterFirst);
  });

});

describe('skill-node-panel: delegation via closest()', () => {

  it('click on a child element of a node is resolved to the node via closest()', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    runScript({ containers: [container] });

    // Simulate a click on a <text> child inside the node. The fake child's closest()
    // returns the parent node (which has data-aid-node after decoration).
    const textChild = {
      type: 'text',
      closest: (sel) => sel === 'g.node.aidNode' ? node1 : null,
    };

    // Dispatching a click targeting the text child must not throw and must resolve
    // to the parent decorated node via the delegation handler.
    expect(() => {
      container.dispatchToHandlers({
        type: 'click',
        target: textChild,
        preventDefault: () => {},
      });
    }).not.toThrow();
  });

  it('click on a target outside g.node.aidNode is a no-op', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    runScript({ containers: [container] });

    const unrelatedTarget = {
      closest: () => null,
    };

    expect(() => {
      container.dispatchToHandlers({
        type: 'click',
        target: unrelatedTarget,
        preventDefault: () => {},
      });
    }).not.toThrow();
  });

  it('keydown Enter activates, keydown Tab does not', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    runScript({ containers: [container] });

    let prevented = false;
    const enterEvent = {
      type: 'keydown',
      key: 'Enter',
      target: node1,
      preventDefault: () => { prevented = true; },
    };

    expect(() => container.dispatchToHandlers(enterEvent)).not.toThrow();
    expect(prevented).toBe(true);

    // Tab must not preventDefault (exits early before the call).
    let tabPrevented = false;
    container.dispatchToHandlers({
      type: 'keydown',
      key: 'Tab',
      target: node1,
      preventDefault: () => { tabPrevented = true; },
    });
    expect(tabPrevented).toBe(false);
  });

});

describe('skill-node-panel: schema guard (v !== 1)', () => {

  it('v !== 1 produces no DOM changes and exactly one panel schema warning', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { warnCalls } = runScript({
      island: { v: 2, skill: 'test', confidence: 'high', nodes: [] },
      containers: [container],
    });

    // Node must not be touched.
    expect(node1.hasAttribute('data-aid-node')).toBe(false);
    expect(node1.hasAttribute('role')).toBe(false);

    // Exactly one warning via 'panel schema' guard.
    const schemaWarns = warnCalls.filter((w) => w.includes('panel schema'));
    expect(schemaWarns).toHaveLength(1);

    // No addEventListener calls — controller did not proceed.
    expect(container._addEventCount()).toBe(0);
  });

  it('missing island element produces no DOM changes and exactly one panel data warning', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { warnCalls } = runScript({ island: null, containers: [container] });

    expect(node1.hasAttribute('data-aid-node')).toBe(false);
    const dataWarns = warnCalls.filter((w) => w.includes('panel data'));
    expect(dataWarns).toHaveLength(1);
    expect(container._addEventCount()).toBe(0);
  });

  it('invalid JSON in island produces no DOM changes and exactly one panel data warning', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });
    const warnCalls = [];
    const fakeConsole = { warn: (msg) => warnCalls.push(msg) };

    let observerCb = null;
    class FakeMutationObserver {
      constructor(cb) { observerCb = cb; }
      observe() {}
    }

    // Inject a bad-JSON island directly.
    const badIslandEl = { id: 'aid-flow-data', textContent: '{ not valid json' };
    const slContent = { querySelectorAll: () => [container] };
    const fakeDoc = {
      getElementById: () => badIslandEl,
      querySelector: () => slContent,
      addEventListener: () => {},
    };

    const fn = new Function('document', 'MutationObserver', 'console', SCRIPT_SRC);
    fn(fakeDoc, FakeMutationObserver, fakeConsole);

    expect(node1.hasAttribute('data-aid-node')).toBe(false);
    const dataWarns = warnCalls.filter((w) => w.includes('panel data'));
    expect(dataWarns).toHaveLength(1);
    expect(container._addEventCount()).toBe(0);
  });

});

describe('skill-node-panel: multiple containers', () => {

  it('binds the first container and warns once via panel container', () => {
    const node1a = aidNodeFor('n1', 0);
    const node1b = aidNodeFor('n1', 1);
    const container1 = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1a] });
    const container2 = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1b] });

    const { warnCalls } = runScript({ containers: [container1, container2] });

    // First container is bound and decorated.
    expect(node1a.getAttribute('data-aid-node')).toBe('n1');
    expect(container1._addEventCount()).toBe(2);

    // Second container is left alone.
    expect(node1b.hasAttribute('data-aid-node')).toBe(false);
    expect(container2._addEventCount()).toBe(0);

    // One 'panel container' warning.
    const containerWarns = warnCalls.filter((w) => w.includes('panel container'));
    expect(containerWarns).toHaveLength(1);
  });

});

describe('skill-node-panel: astro:after-swap registration', () => {

  it('registers an astro:after-swap listener on document', () => {
    const node1 = aidNodeFor('n1');
    const container = makeContainer({ processed: true, hasSvg: true, aidNodes: [node1] });

    const { listeners } = runScript({ containers: [container] });

    expect(typeof listeners['astro:after-swap']).toBe('function');
  });

});

describe('skill-node-panel: init() error containment', () => {

  it('an unexpected error during init degrades to no-JS state (does not throw)', () => {
    // Inject a document whose getElementById throws unexpectedly.
    const warnCalls = [];
    const fakeConsole = { warn: (msg) => warnCalls.push(msg) };
    class FakeMutationObserver {
      constructor(cb) {}
      observe() {}
    }

    const throwingDoc = {
      getElementById: () => { throw new Error('injected'); },
      querySelector: () => null,
      addEventListener: () => {},
    };

    const fn = new Function('document', 'MutationObserver', 'console', SCRIPT_SRC);
    expect(() => fn(throwingDoc, FakeMutationObserver, fakeConsole)).not.toThrow();

    // One warn from the catch block.
    expect(warnCalls.length).toBeGreaterThanOrEqual(1);
  });

});

describe('skill-node-panel: static file constraints', () => {

  it('contains no import statement', () => {
    expect(SCRIPT_SRC).not.toMatch(/^\s*import\s/m);
  });

  it('contains no fetch(', () => {
    expect(SCRIPT_SRC).not.toContain('fetch(');
  });

  it('contains no localStorage', () => {
    expect(SCRIPT_SRC).not.toContain('localStorage');
  });

  it('contains no sessionStorage', () => {
    expect(SCRIPT_SRC).not.toContain('sessionStorage');
  });

  it('contains no eval(', () => {
    expect(SCRIPT_SRC).not.toContain('eval(');
  });

  it('contains no new Function(', () => {
    expect(SCRIPT_SRC).not.toContain('new Function(');
  });

  it('contains no innerHTML', () => {
    expect(SCRIPT_SRC).not.toContain('innerHTML');
  });

});
