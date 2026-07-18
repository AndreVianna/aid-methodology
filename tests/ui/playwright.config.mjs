// Playwright config for the AID dashboard's ON-DEMAND UI tests.
//
// This is NOT wired into the required test suite: it lives under tests/ui/ (outside
// tests/run-all.sh's `tests/canonical/test-*.sh` glob) and is absent from
// .github/workflows/test.yml, so CI never runs it and no PR is gated by it. Playwright
// is an OPTIONAL dev dependency, installed on demand (see README.md).
//
// `npx playwright test` will auto-start an isolated dashboard server via serve.mjs.

import { defineConfig, devices } from '@playwright/test';

const PORT = process.env.AID_UI_TEST_PORT || '8799';
const BASE_URL = `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: '.',
  testMatch: '**/*.spec.mjs',
  fullyParallel: false,        // single dashboard server; keep edits from racing
  workers: 1,
  timeout: 30_000,
  reporter: [['list']],
  use: {
    baseURL: BASE_URL,
    headless: true,
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: 'node serve.mjs',
    url: `${BASE_URL}/`,
    reuseExistingServer: true,   // reuse a server you already started with `node serve.mjs`
    timeout: 60_000,
  },
});
