// @vitest-environment jsdom
//
// Guard for the per-file DOM environment opt-in that feature-006 depends on.
//
// The docblock directive above is the whole mechanism: `site/vitest.config.mjs`
// sets only `fileParallelism` and deliberately leaves `environment` unset, so the
// runner default stays `node` and a single file can opt itself into jsdom. That
// arrangement is easy to break from a distance — adding `environment: 'jsdom'`
// to the config would flip every suite, and removing jsdom from
// devDependencies would make the directive fail at collection time rather than
// somewhere legible.
//
// This file exists so that breakage is a named failure here rather than an
// unexplained one in the DOM lifecycle suite, and so the mechanism is proven
// available before that suite is written against it.

import { describe, it, expect } from 'vitest';

describe('jsdom environment opt-in', () => {
  it('provides a document', () => {
    expect(typeof document).toBe('object');
    expect(document).not.toBeNull();
  });

  it('provides a window with the globals the panel controller needs', () => {
    expect(typeof window).toBe('object');
    // The controller waits on mermaid's render, decorates nodes, and moves focus.
    expect(typeof MutationObserver).toBe('function');
    expect(typeof window.getComputedStyle).toBe('function');
    expect(typeof HTMLElement).toBe('function');
  });

  it('supports element creation, attributes and event dispatch', () => {
    const el = document.createElement('div');
    el.setAttribute('role', 'button');
    el.setAttribute('tabindex', '0');
    document.body.appendChild(el);

    let seen = 0;
    el.addEventListener('click', () => { seen++; });
    el.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    expect(el.getAttribute('role')).toBe('button');
    expect(seen).toBe(1);
    document.body.removeChild(el);
  });

  it('supports the focus model Escape handling relies on', () => {
    const el = document.createElement('button');
    document.body.appendChild(el);
    el.focus();
    expect(document.activeElement).toBe(el);
    document.body.removeChild(el);
  });
});
