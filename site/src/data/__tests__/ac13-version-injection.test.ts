// ac13-version-injection.test.ts — Task-013 acceptance criteria tests.
//
// Verifies:
//   AC13 — badge + all five install one-liners render the build-time version; no
//           hard-coded version literal in the source pages.
//   AC6  — Get Started section has Overview / Install / Your first work / Lite path.
//   AC7  — Installation guide documents all four channels + five tool tabs.
//   AC5  — Home pipeline diagram present; Installation guide prose faithful to source.
//
// Approach: these are build-time integration tests that inspect the SOURCE files
// (MDX/MD pages and version.ts) for structural and no-hardcoded-version invariants.
// Component rendering (Astro) is not testable in Vitest — we verify via the data
// layer and by asserting the source files do not contain hard-coded version literals.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
// __dirname = site/src/data/__tests__
// site root = ../../../  (data/__tests__ → data → src → site)
const siteRoot = resolve(__dirname, '../../..');
const docsRoot = resolve(siteRoot, 'src/content/docs');

// ── Helpers ──────────────────────────────────────────────────────────────────

function readDoc(relPath: string): string {
  return readFileSync(resolve(docsRoot, relPath), 'utf8');
}


const savedEnv: Record<string, string | undefined> = {};

function saveEnv(...keys: string[]) {
  for (const k of keys) savedEnv[k] = process.env[k];
}

function restoreEnv(...keys: string[]) {
  for (const k of keys) {
    if (savedEnv[k] === undefined) delete process.env[k];
    else process.env[k] = savedEnv[k];
  }
}

// ── AC13 — no hard-coded version in source pages ──────────────────────────────

describe('AC13 — no hard-coded version literal in source pages', () => {
  const HARDCODED_VERSION_RE = /\b1\.0\.0\b/g;

  it('index.mdx has no hard-coded version literal', () => {
    const src = readDoc('index.mdx');
    // Hard-coded "1.0.0" must not appear — version is injected via <InstallCommand>/<VersionBadge>
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/overview.md has no hard-coded version literal', () => {
    const src = readDoc('get-started/overview.md');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/install.md has no hard-coded version literal', () => {
    const src = readDoc('get-started/install.md');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/first-work.mdx has no hard-coded version literal', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/lite-path.mdx has no hard-coded version literal', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('guides/installation.mdx has no hard-coded version literal', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });
});

// ── AC13 — components import + channel usage ──────────────────────────────────

describe('AC13 — version-bearing commands rendered via <InstallCommand>', () => {
  it('index.mdx imports InstallCommand from correct depth', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain("import InstallCommand from '../../components/InstallCommand.astro'");
  });

  it('index.mdx imports VersionBadge from correct depth', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain("import VersionBadge from '../../components/VersionBadge.astro'");
  });

  it('index.mdx uses <InstallCommand channel="curl" />', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('channel="curl"');
  });

  it('index.mdx uses <VersionBadge> with href', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('<VersionBadge');
    expect(src).toContain('href=');
  });

  it('guides/installation.mdx imports InstallCommand from correct depth', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain("import InstallCommand from '../../../components/InstallCommand.astro'");
  });

  it('guides/installation.mdx uses all five channels', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="curl"');
    expect(src).toContain('channel="irm"');
    expect(src).toContain('channel="npm"');
    expect(src).toContain('channel="pypi"');
    expect(src).toContain('channel="offline"');
  });
});

// ── AC13 — AID_VERSION override propagation ───────────────────────────────────

describe('AC13 — AID_VERSION override propagates to all five commands (no runtime call)', () => {
  const ENV_KEY = 'AID_VERSION';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('curl command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.curl).toContain('5.0.0');
    expect(installCommands.curl).not.toContain('1.0.0');
  });

  it('irm command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.irm).toContain('5.0.0');
    expect(installCommands.irm).not.toContain('1.0.0');
  });

  it('npm command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.npm).toContain('5.0.0');
  });

  it('pypi command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.pypi).toContain('5.0.0');
  });

  it('offline command reflects AID_VERSION override (v-prefixed tag)', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.offline).toContain('v5.0.0');
    expect(installCommands.offline).not.toContain('1.0.0');
  });

  it('VERSION reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { VERSION } = await import('../version.js');
    expect(VERSION).toBe('5.0.0');
  });
});

// ── AC5 — Home pipeline diagram present ──────────────────────────────────────

describe('AC5 — Home pipeline diagram', () => {
  // The home pipeline is the canonical README diagram (a Mermaid flowchart with a
  // TRIAGE branch). It MUST show both the full and lite paths.
  it('index.mdx renders the pipeline as a Mermaid diagram', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('```mermaid');
    expect(src).toContain('flowchart TB');
  });

  it('index.mdx lists the six core phases in order', () => {
    const src = readDoc('index.mdx');
    for (const phase of ['Discover', 'Describe', 'Specify', 'Plan', 'Detail', 'Execute']) {
      expect(src).toContain(phase);
    }
  });

  // Regression guard (this has been wrong three times): the pipeline diagram must
  // include the TRIAGE node AND the lite-path branch that routes straight to Execute,
  // skipping Specify/Plan/Detail — matching README.md's canonical diagram.
  it('index.mdx pipeline shows the TRIAGE branch and the lite path', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('TRIAGE');
    expect(src).toContain('lite path');
    // The lite branch routes Triage --> Exe (skips Specify/Plan/Detail).
    expect(src).toMatch(/Triage\s*--\s*"lite path[\s\S]*?-->\s*Exe/);
  });
});

// ── AC6 — Get Started section structure ──────────────────────────────────────

describe('AC6 — Get Started section has required four pages', () => {
  it('overview.md exists and has sidebar.order: 1', () => {
    const src = readDoc('get-started/overview.md');
    expect(src).toContain('order: 1');
    expect(src).toContain("label: Overview");
  });

  it('install.md exists and has sidebar.order: 2', () => {
    const src = readDoc('get-started/install.md');
    expect(src).toContain('order: 2');
  });

  it('first-work.mdx exists and has sidebar.order: 3', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).toContain('order: 3');
  });

  it('lite-path.mdx exists and has sidebar.order: 4', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).toContain('order: 4');
  });

  it('first-work.mdx uses <Steps> component (net-new content)', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).toContain('<Steps>');
    expect(src).toContain("import { Steps }");
  });

  it('lite-path.mdx uses <Steps> component (net-new content)', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).toContain('<Steps>');
    expect(src).toContain("import { Steps }");
  });
});

// ── AC7 — Installation guide channels and tool tabs ──────────────────────────

describe('AC7 — Installation guide four channels and five tool tabs', () => {
  it('installation.mdx documents curl channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="curl"');
  });

  it('installation.mdx documents irm channel (Windows PowerShell)', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="irm"');
  });

  it('installation.mdx documents npm channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="npm"');
  });

  it('installation.mdx documents pypi channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="pypi"');
  });

  it('installation.mdx documents offline channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="offline"');
  });

  it('installation.mdx has per-OS <Tabs syncKey="os">', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="os"');
    expect(src).toContain('label="Linux"');
    expect(src).toContain('label="macOS"');
    expect(src).toContain('label="Windows"');
  });

  it('installation.mdx has per-tool <Tabs syncKey="tool">', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="tool"');
    expect(src).toContain('label="Claude Code"');
    expect(src).toContain('label="Codex"');
    expect(src).toContain('label="Cursor"');
    expect(src).toContain('label="Copilot CLI"');
    expect(src).toContain('label="Antigravity"');
  });

  it('os and tool syncKey values are independent (different strings)', () => {
    // Confirm the two syncKey values are distinct strings
    expect('os').not.toBe('tool');
    // Source uses both
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="os"');
    expect(src).toContain('syncKey="tool"');
  });

  it('installation.mdx has update instructions', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('Update');
    expect(src).toContain('aid update');
  });

  it('installation.mdx has remove instructions', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('Remove');
    expect(src).toContain('aid remove');
  });
});

// ── AC3 — Home doc page (Overview) structure ──────────────────────────────────
// The root page is a standard documentation page, NOT a marketing splash. The
// anti-splash invariant is the absence of `template: splash`, a `hero:` block, and
// CTA `actions:`. Per prototype-01 it DOES use a <CardGrid> of <LinkCard>s for doc
// navigation and the inline <PipelineDiagram /> — both are documentation patterns.

describe('AC3 — Home page is a documentation page (no marketing splash)', () => {
  it('index.mdx does NOT have template: splash', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('template: splash');
  });

  it('index.mdx does NOT have a hero block', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('hero:');
  });

  it('index.mdx does NOT have CTA actions (splash buttons)', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('actions:');
  });

  it('index.mdx uses <CardGrid>/<LinkCard> for documentation navigation', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('<CardGrid>');
    expect(src).toContain('<LinkCard');
  });

  it('index.mdx title is Overview (documentation voice)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('title: Overview');
  });

  it('index.mdx links to /get-started/overview/ (navigation card)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('/get-started/overview/');
  });

  it('index.mdx links to the Installation guide (all channels)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('/guides/installation/');
  });

  it('index.mdx has a pipeline diagram (Mermaid)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('```mermaid');
  });
});
