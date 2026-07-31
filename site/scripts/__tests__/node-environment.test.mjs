// Companion to jsdom-environment.test.mjs, carrying NO environment docblock.
//
// The opt-in claim has two halves: one file gets a DOM, and every other file does
// not. Asserting only the first would pass just as well if the config had set
// `environment: 'jsdom'` globally — which is exactly the change that would
// silently alter 40 other suites. This half fails if that ever happens.

import { describe, it, expect } from 'vitest';

describe('default test environment stays node', () => {
  it('has no document', () => {
    expect(typeof document).toBe('undefined');
  });

  it('has no window', () => {
    expect(typeof window).toBe('undefined');
  });

  it('still has the node globals the generator suites use', () => {
    expect(typeof process).toBe('object');
    expect(typeof process.cwd).toBe('function');
  });
});
