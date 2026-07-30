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
// A generous per-test timeout, for the same reason `fileParallelism` is off.
//
// Eleven tests in gen-skills.test.mjs, plus others in gen-skills-index.test.mjs,
// gen-reference.test.mjs and sync-docs.test.mjs, shell out to a REAL generator run
// with spawnSync/execSync — several of them twice, to prove byte-identical
// regeneration. That is a whole build step, and its wall clock is a property of the
// machine, not of the assertion: measured here at ~2.4s idle and ~70s under load.
// Against vitest's 5000ms default those tests are a coin flip, and they fail as
// `Test timed out in 5000ms`, which reads like the behaviour under test being wrong
// rather than the budget being too small. That misreading is exactly what KI-020
// cost: an "intermittently flaky byte-identity test" that was never flaky and never
// a byte difference.
//
// Only one of those eleven call sites carried an explicit timeout. Setting it here
// covers the class, including tests not yet written, instead of relying on each
// author to remember. The cost is that a genuinely hung test takes 90s to report
// instead of 5s — acceptable, since nothing here is a tight unit test where 5s
// would be a meaningful signal.
export default defineConfig({
  test: {
    fileParallelism: false,
    testTimeout: 90000,
    hookTimeout: 90000,
  },
});
