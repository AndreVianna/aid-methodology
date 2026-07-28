// mermaid-source-cache.test.mjs — the KI-018 workaround's logic and its wiring.
//
// The workaround is an inline <head> script, so there is no module to import. Rather
// than settle for asserting the file exists, the script is executed here against a
// minimal fake DOM: enough of `document`, `MutationObserver` and element to drive the
// real code and observe what it writes. That makes the three guards inside
// `cacheSource` genuinely testable, which matters because each one exists to stop a
// specific way of caching the WRONG value — and a workaround whose guards are untested
// is the defect this delivery has spent two checkpoints learning to avoid.
//
// What is NOT covered here, and is verified in a browser instead: that the script runs
// before astro-mermaid's deferred module. That is a property of script types and
// document order, not of this code.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const SCRIPT_PATH = join(SITE_ROOT, 'src', 'scripts', 'mermaid-source-cache.js');
const CONFIG_PATH = join(SITE_ROOT, 'astro.config.mjs');

const SCRIPT_SRC = readFileSync(SCRIPT_PATH, 'utf8');

/** A fake <pre class="mermaid"> good enough for the script's queries. */
function fakePre({ text, hasSvg = false, attrs = {} } = {}) {
  const store = { ...attrs };
  return {
    _tag: 'pre.mermaid',
    // Element node. Load-bearing: the script skips anything whose nodeType is not 1,
    // and without this every fixture was skipped — which made the two "refuses …"
    // guard tests pass for the wrong reason. The happy-path test above is what exposed
    // that, which is the argument for always pairing a negative case with a positive one.
    nodeType: 1,
    textContent: text,
    hasAttribute: (k) => k in store,
    getAttribute: (k) => (k in store ? store[k] : null),
    setAttribute: (k, v) => { store[k] = v; },
    matches: (sel) => sel === 'pre.mermaid',
    querySelector: (sel) => (sel === 'svg' && hasSvg ? { tag: 'svg' } : null),
    querySelectorAll: () => [],
    _store: store,
  };
}

/**
 * Execute the workaround against a fake DOM and return handles to poke at it.
 *
 * Returns the captured MutationObserver callback and the registered event listeners,
 * so a test can simulate the parser appending a node or a view transition swapping one.
 */
function runScript(initialPres = []) {
  const listeners = {};
  let observerCallback = null;
  let observed = null;

  const document = {
    documentElement: { _tag: 'html' },
    querySelectorAll: (sel) => (sel === 'pre.mermaid' ? initialPres : []),
    addEventListener: (name, fn) => { listeners[name] = fn; },
  };

  class MutationObserver {
    constructor(cb) { observerCallback = cb; }
    observe(target, opts) { observed = { target, opts }; }
  }

  // Indirect eval with injected globals — the script is a bare IIFE with no imports,
  // which is exactly why it can be driven this way.
  const fn = new Function('document', 'MutationObserver', SCRIPT_SRC);
  fn(document, MutationObserver);

  return {
    listeners,
    observed,
    append: (nodes) => observerCallback([{ addedNodes: nodes }]),
  };
}

describe('KI-018 workaround: caches the diagram source before astro-mermaid can', () => {
  it('caches the source of a freshly parsed pre.mermaid', () => {
    const pre = fakePre({ text: 'flowchart TB\n  a --> b\n' });
    const { append } = runScript();
    append([pre]);
    expect(pre.getAttribute('data-diagram')).toBe('flowchart TB\n  a --> b\n');
  });

  it('observes from documentElement with subtree, so it sees nodes as they are parsed', () => {
    const { observed } = runScript();
    expect(observed.target).toEqual({ _tag: 'html' });
    expect(observed.opts).toEqual({ childList: true, subtree: true });
  });

  // ── The three guards, one test each. Each fixture differs from the happy path in
  //    exactly the property under test, so only that guard can be what rejects it.

  it('guard 1 — never overwrites an existing data-diagram', () => {
    // astro-mermaid may have cached a correct value already; clobbering it would make
    // this workaround the source of the very problem it fixes.
    const pre = fakePre({
      text: 'flowchart TB\n  new --> value\n',
      attrs: { 'data-diagram': 'flowchart TB\n  original\n' },
    });
    const { append } = runScript();
    append([pre]);
    expect(pre.getAttribute('data-diagram')).toBe('flowchart TB\n  original\n');
  });

  it('guard 2 — refuses an element that already contains rendered SVG', () => {
    const pre = fakePre({ text: 'whatever the svg serialises to', hasSvg: true });
    const { append } = runScript();
    append([pre]);
    expect(pre.hasAttribute('data-diagram')).toBe(false);
  });

  it('guard 3 — refuses content that looks like mermaid\'s own stylesheet', () => {
    // The exact shape observed on a broken page: the SVG's <style> text, which contains
    // the keyframes mermaid emits. Reaching this guard requires getting past guard 2,
    // which is why the fixture has no <svg> child — the two are separately reachable.
    const pre = fakePre({
      text: '#mermaid-1785268632684{font-family:"trebuchet ms";}@keyframes dash{to{stroke-dashoffset:0;}}',
      hasSvg: false,
    });
    const { append } = runScript();
    append([pre]);
    expect(pre.hasAttribute('data-diagram')).toBe(false);
  });

  it('sweeps nodes nested inside an added subtree, not just the node itself', () => {
    const nested = fakePre({ text: 'flowchart TB\n  x --> y\n' });
    const wrapper = {
      nodeType: 1,
      matches: () => false,
      querySelectorAll: (sel) => (sel === 'pre.mermaid' ? [nested] : []),
    };
    const { append } = runScript();
    append([wrapper]);
    expect(nested.getAttribute('data-diagram')).toBe('flowchart TB\n  x --> y\n');
  });

  it('re-sweeps after a view transition, which delivers a whole new DOM', () => {
    const pre = fakePre({ text: 'flowchart TB\n  p --> q\n' });
    const { listeners } = runScript([pre]);
    expect(typeof listeners['astro:after-swap']).toBe('function');
    listeners['astro:after-swap']();
    expect(pre.getAttribute('data-diagram')).toBe('flowchart TB\n  p --> q\n');
  });

  it('ignores non-element nodes, which the parser also reports', () => {
    const textNode = { nodeType: 3, textContent: 'stray text' };
    const { append } = runScript();
    // Text nodes have no matches/querySelectorAll; touching them would throw.
    expect(() => append([textNode, null])).not.toThrow();
  });
});

describe('KI-018 workaround: wiring', () => {
  it('astro.config.mjs inlines THIS file as a head script', () => {
    const config = readFileSync(CONFIG_PATH, 'utf8');
    // The path, so a rename cannot leave the config reading a file that no longer exists.
    expect(config).toContain('./src/scripts/mermaid-source-cache.js');
    // Read at config time rather than duplicated as a template literal.
    expect(config).toMatch(/head:\s*\[/);
    expect(config).toContain("tag: 'script'");
    expect(config).toContain('readFileSync(');
  });

  it('the script is a bare IIFE — no imports, so it can be inlined and eval-tested', () => {
    expect(SCRIPT_SRC).not.toMatch(/^\s*import\s/m);
    expect(SCRIPT_SRC).not.toMatch(/^\s*export\s/m);
    expect(SCRIPT_SRC.trimStart()).toMatch(/^(\/\/|\(function)/);
  });
});
