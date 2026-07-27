import { defineConfig } from 'vitest/config';

// Serialise test FILES. See KI-016 and delivery-002 Q2 for the full reasoning.
//
// Vitest runs test files in parallel workers by default, and several suites in
// this repo prove idempotence by re-running a generator and comparing bytes —
// gen-reference, sync-docs, and now gen-skills, with more arriving in
// delivery-003 (sidecar and cross-page byte-identity) and delivery-004 (a
// whole-corpus provenance sweep). Two workers regenerating the same tree at once
// is a real flake source: one worker's write lands between another's read and
// compare, and the failure is intermittent and blames the wrong suite.
//
// This is the whole fix. Per-suite workarounds were tried first and are worse:
// task-014's index suite had to snapshot the output directory at module-import
// time to stay stable while gen-skills.test.mjs wrote to it, which only works
// while import order happens to cooperate.
//
// Cost is negligible — the suite is ~800 tests in a few seconds, against an
// `npm ci` that takes 26s in CI.
//
// Deliberately does NOT set `environment`. feature-006 opts a single file into
// jsdom with a `// @vitest-environment jsdom` docblock and relies on the default
// staying `node`; setting it here would silently break that.
export default defineConfig({
  test: {
    fileParallelism: false,
  },
});
