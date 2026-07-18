#!/usr/bin/env node
// serve.mjs -- launch an ISOLATED AID dashboard server for the on-demand Playwright UI
// tests. Started automatically by playwright.config.mjs's `webServer`; can also be run
// standalone (`node serve.mjs`) if you prefer to drive the tests against a long-lived server.
//
// Isolation (critical): HOME / USERPROFILE / AID_HOME are all pinned to a throwaway scratch
// dir whose registry.yml lists ONLY this repo, so the two-tier registry union CANNOT pull in
// your real ~/.aid projects. With --allow-writes on, an errant edit can therefore only touch
// this repo's own .aid/ (git-revertible) -- never an external project.
//
// NOT part of the required test suite / CI. Manual, on-demand only.

import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '..', '..');            // tests/ui -> repo root
const PORT = process.env.AID_UI_TEST_PORT || '8799';
const RUNTIME = process.env.AID_UI_TEST_RUNTIME || 'python';   // 'python' | 'node'
const PY = process.env.AID_UI_TEST_PYTHON || 'python';

// Scratch AID_HOME with a registry that points ONLY at this repo.
const scratch = mkdtempSync(join(tmpdir(), 'aid-ui-test-'));
writeFileSync(join(scratch, 'registry.yml'), `schema: 1\nprojects:\n  - ${REPO_ROOT}\n`, 'utf8');

const entry = RUNTIME === 'node'
  ? { cmd: process.env.AID_UI_TEST_NODE || 'node', arg: join(REPO_ROOT, 'dashboard', 'server', 'server.mjs') }
  : { cmd: PY, arg: join(REPO_ROOT, 'dashboard', 'server', 'server.py') };

const env = {
  ...process.env,
  HOME: scratch,
  USERPROFILE: scratch,
  AID_HOME: scratch,
};

const child = spawn(entry.cmd, [entry.arg, '--host', '127.0.0.1', '--port', PORT, '--allow-writes'], {
  cwd: REPO_ROOT,
  env,
  stdio: 'inherit',
});

function cleanup() {
  try { child.kill(); } catch { /* already gone */ }
  try { rmSync(scratch, { recursive: true, force: true }); } catch { /* best effort */ }
}
process.on('SIGINT', () => { cleanup(); process.exit(0); });
process.on('SIGTERM', () => { cleanup(); process.exit(0); });
child.on('exit', (code) => { cleanup(); process.exit(code ?? 0); });
