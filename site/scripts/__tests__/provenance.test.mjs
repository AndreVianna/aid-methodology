// provenance.test.mjs — AC-5 acceptance suite for feature-005-verbatim-source-provenance.
//
// Six groups, each owning a distinct acceptance aspect:
//   1. Corpus sweep   — AC-5 whole-corpus: every node's file, range, and excerpt.
//   2. Link half      — Offline deep-link format and href correctness.
//   3. Containment    — Fragment round-trip byte-exact through the tilde fence.
//   4. Verifier       — Synthetic failing cases for every check P0–P6.
//   5. Determinism    — renderFragmentList is deterministic in isolation.
//   6. No-JS          — Rendered markdown carries no script/import/directive.
//
// Quality gates:
//   - No literal count for skill directories or node count (non-vacuity floor instead).
//   - Verifier fixtures are input-separable (see separability table in that group).
//   - P5 uses a real all-whitespace slice so P4 passes first.
//   - Every throw asserts the guard name, skill, node id, and file#L... location.
//   - P4 throw additionally asserts the first-differing-line.
//   - No-JS count assertion is an equality, not a lower bound.
//   - Fence round-trip asserts byte-exact equality, not containment.
//   - Fixtures are built in the test file; nothing under .aid/works/ is read.
//
// Run: cd site && npx vitest run scripts/__tests__/provenance.test.mjs

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import {
  readFileSync,
  existsSync,
  readdirSync,
  writeFileSync,
  mkdtempSync,
  mkdirSync,
  rmSync,
} from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { buildFlowChart } from '../lib/flow-graph/index.mjs';
import { makeProvenance, makeNode, buildChart } from '../lib/flow-graph/model.mjs';
import { verifyProvenance } from '../lib/provenance/verify.mjs';
import { buildEntries, renderFragmentList } from '../lib/provenance/render-list.mjs';
import { GITHUB_BLOB_BASE, REPO_ROOT, SITE_SKILLS_DIR } from '../skills/paths.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CANONICAL_SKILLS_DIR = resolve(REPO_ROOT, 'canonical', 'skills');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Enumerate all skill directory names from canonical/skills/.
 * Returns a sorted array — no hard-coded count anywhere in this file.
 */
function getSkillDirNames() {
  return readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();
}

/**
 * Extract all tilde-fence bodies from a rendered fragment list.
 *
 * Each fence opens with a line matching /^(~{4,})plaintext title="/.
 * Everything between the opener and its matching closer (same tilde run)
 * is the body. Returns an array of body strings in source order.
 *
 * @param {string} rendered
 * @returns {string[]}
 */
function extractFenceBodies(rendered) {
  const lines = rendered.split('\n');
  const bodies = [];
  let inFence = false;
  let fenceDelim = '';
  let bodyLines = [];

  for (const line of lines) {
    if (!inFence) {
      // Match any plaintext tilde fence regardless of its attributes so the
      // extractor works even when an attribute is mutated during M3 testing.
      const m = line.match(/^(~{4,})plaintext/);
      if (m) {
        inFence = true;
        fenceDelim = m[1];
        bodyLines = [];
      }
    } else {
      if (line === fenceDelim) {
        bodies.push(bodyLines.join('\n'));
        inFence = false;
        fenceDelim = '';
        bodyLines = [];
      } else {
        bodyLines.push(line);
      }
    }
  }
  return bodies;
}

/**
 * Extract all tilde fence opener lines from rendered output.
 *
 * @param {string} rendered
 * @returns {string[]}
 */
function extractFenceOpeners(rendered) {
  return rendered.split('\n').filter((line) => line.match(/^~{4,}plaintext/));
}

/**
 * Count occurrences of a substring in a string.
 *
 * @param {string} haystack
 * @param {string} needle
 * @returns {number}
 */
function countOccurrences(haystack, needle) {
  let count = 0;
  let pos = 0;
  while ((pos = haystack.indexOf(needle, pos)) !== -1) {
    count++;
    pos += needle.length;
  }
  return count;
}

/**
 * Build a minimal valid synthetic FlowChart for test use.
 *
 * All fields default to a known-good state; callers pass the nodes array they
 * actually care about testing.
 *
 * @param {object[]} rawNodes  makeNode() results (without id/kind)
 * @param {string}   [skill]   Skill directory name (default 'aid-test')
 * @returns {import('../lib/flow-graph/model.mjs').FlowChart}
 */
function makeTestChart(rawNodes, skill = 'aid-test') {
  return buildChart({
    skill,
    shape:       'dispatch-table',
    extractor:   'test',
    confidence:  'derived',
    nodes:       rawNodes,
    edges:       [],
    sources:     [],
    warnings:    [],
  });
}

// ── Group 1: AC-5 Corpus Sweep ────────────────────────────────────────────────
//
// Enumerates every skill directory from disk and builds its FlowChart.  Checks
// that every node's provenance satisfies the five AC-5 properties:
//   (a) file starts with 'canonical/'
//   (b) file exists on disk
//   (c) 1 <= startLine <= endLine <= lineCount(file)
//   (d) excerpt equals the verbatim file slice
//   (e) detail, when present, satisfies (a)–(c) but is NOT excerpt-checked

describe('AC-5 corpus sweep', () => {
  let skillDirNames;
  let allCharts;

  beforeAll(() => {
    skillDirNames = getSkillDirNames();
    allCharts = skillDirNames.map((name) =>
      buildFlowChart({ name, dir: REPO_ROOT })
    );
  });

  it('enumerates more than 50 skill directories (non-vacuity floor)', () => {
    expect(skillDirNames.length).toBeGreaterThan(50);
  });

  it('every node provenance.file starts with "canonical/"', () => {
    for (const chart of allCharts) {
      for (const node of chart.nodes) {
        expect(
          node.provenance.file.startsWith('canonical/'),
          `${chart.skill}/${node.id} provenance.file="${node.provenance.file}"`
        ).toBe(true);
      }
    }
  });

  it('every node provenance.file exists on disk', () => {
    for (const chart of allCharts) {
      for (const node of chart.nodes) {
        const absPath = resolve(REPO_ROOT, ...node.provenance.file.split('/'));
        expect(
          existsSync(absPath),
          `${chart.skill}/${node.id} file not found: ${node.provenance.file}`
        ).toBe(true);
      }
    }
  });

  it('every node provenance satisfies 1 <= startLine <= endLine <= lineCount(file)', () => {
    for (const chart of allCharts) {
      for (const node of chart.nodes) {
        const { file, startLine, endLine } = node.provenance;
        const absPath = resolve(REPO_ROOT, ...file.split('/'));
        const lineCount = readFileSync(absPath, 'utf8').split('\n').length;
        expect(startLine, `${chart.skill}/${node.id} startLine`).toBeGreaterThanOrEqual(1);
        expect(endLine, `${chart.skill}/${node.id} endLine >= startLine`).toBeGreaterThanOrEqual(startLine);
        expect(endLine, `${chart.skill}/${node.id} endLine <= lineCount=${lineCount}`).toBeLessThanOrEqual(lineCount);
      }
    }
  });

  it('every node excerpt equals the verbatim file slice (byte-exact)', () => {
    for (const chart of allCharts) {
      for (const node of chart.nodes) {
        const { file, startLine, endLine, excerpt } = node.provenance;
        const absPath = resolve(REPO_ROOT, ...file.split('/'));
        const lines = readFileSync(absPath, 'utf8').split('\n');
        const expected = lines.slice(startLine - 1, endLine).join('\n');
        expect(
          excerpt,
          `${chart.skill}/${node.id} excerpt mismatch at ${file}#L${startLine}-L${endLine}`
        ).toBe(expected);
      }
    }
  });

  it('every node detail (when present) has file under "canonical/" and a valid range', () => {
    for (const chart of allCharts) {
      for (const node of chart.nodes) {
        if (node.detail == null) continue;
        const { file, startLine, endLine } = node.detail;
        expect(
          file.startsWith('canonical/'),
          `${chart.skill}/${node.id} detail.file="${file}"`
        ).toBe(true);
        const absPath = resolve(REPO_ROOT, ...file.split('/'));
        expect(
          existsSync(absPath),
          `${chart.skill}/${node.id} detail file not found: ${file}`
        ).toBe(true);
        const lineCount = readFileSync(absPath, 'utf8').split('\n').length;
        expect(startLine, `${chart.skill}/${node.id} detail startLine`).toBeGreaterThanOrEqual(1);
        expect(endLine, `${chart.skill}/${node.id} detail endLine >= startLine`).toBeGreaterThanOrEqual(startLine);
        expect(endLine, `${chart.skill}/${node.id} detail endLine <= lineCount=${lineCount}`).toBeLessThanOrEqual(lineCount);
      }
    }
  });
});

// ── Group 2: Link Half (offline) ──────────────────────────────────────────────
//
// Proves that the [Source: ...] link in each entry is correctly formed without
// any network request.  The href is the mechanical encoding
//   GITHUB_BLOB_BASE + '/' + provenance.file + anchor
// where anchor = '#L<n>' for a single-line range and '#L<a>-L<b>' otherwise.
//
// Two fixture nodes cover both anchor shapes; one with detail exercises the
// optional [full step: ...] link.  The links are extracted from the rendered
// markdown and compared to the expected URL strings.

describe('link half (offline, no network)', () => {
  const FILE   = 'canonical/skills/aid-review/SKILL.md';
  const SINGLE_START = 1;
  const SINGLE_END   = 1;
  const MULTI_START  = 1;
  const MULTI_END    = 3;
  const DETAIL_FILE  = 'canonical/skills/aid-review/SKILL.md';
  const DETAIL_START = 5;
  const DETAIL_END   = 10;

  // Minimal known-good excerpt text (value does not affect link assertions)
  const EXCERPT_SINGLE = '## aid-review';
  const EXCERPT_MULTI  = '## aid-review\n\na short excerpt';

  let rendered;
  let nodeCount;

  beforeAll(() => {
    const provSingle = makeProvenance({
      file: FILE, startLine: SINGLE_START, endLine: SINGLE_END,
      sourceKind: 'skill', excerpt: EXCERPT_SINGLE,
    });
    const provMulti = makeProvenance({
      file: FILE, startLine: MULTI_START, endLine: MULTI_END,
      sourceKind: 'skill', excerpt: EXCERPT_MULTI,
    });
    const detailProv = makeProvenance({
      file: DETAIL_FILE, startLine: DETAIL_START, endLine: DETAIL_END,
      sourceKind: 'skill', excerpt: 'x',
    });
    const chart = makeTestChart([
      makeNode({ order: 1, name: 'SINGLE', label: 'Single', provenance: provSingle }),
      makeNode({ order: 2, name: 'MULTI',  label: 'Multi',  provenance: provMulti }),
      makeNode({
        order:      3,
        name:       'WITH_DETAIL',
        label:      'WithDetail',
        provenance: provMulti,
        detail:     detailProv,
        terminal:   { advanceType: 'HALT', handoff: null },
      }),
    ]);
    const entries = buildEntries(chart);
    nodeCount = chart.nodes.length;
    rendered = renderFragmentList(entries);
  });

  it('single-line range uses #L<n> anchor in the [Source:] href', () => {
    const expectedUrl =
      GITHUB_BLOB_BASE + '/' + FILE + '#L' + SINGLE_START;
    expect(rendered).toContain(`[Source: \`${FILE}#L${SINGLE_START}\`](${expectedUrl})`);
  });

  it('multi-line range uses #L<a>-L<b> anchor in the [Source:] href', () => {
    const expectedUrl =
      GITHUB_BLOB_BASE + '/' + FILE + '#L' + MULTI_START + '-L' + MULTI_END;
    expect(rendered).toContain(
      `[Source: \`${FILE}#L${MULTI_START}-L${MULTI_END}\`](${expectedUrl})`
    );
  });

  it('each entry has exactly one [Source: ] link', () => {
    const count = countOccurrences(rendered, '[Source: ');
    expect(count).toBe(nodeCount);
  });

  it('detail link appears on same line as Source link and uses correct href', () => {
    const expectedDetailUrl =
      GITHUB_BLOB_BASE + '/' + DETAIL_FILE + '#L' + DETAIL_START + '-L' + DETAIL_END;
    expect(rendered).toContain(
      ` · [full step: \`${DETAIL_FILE}#L${DETAIL_START}-L${DETAIL_END}\`](${expectedDetailUrl})`
    );
    // The two links must be on the same line (no newline between Source and full step).
    const lines = rendered.split('\n');
    const sourceAndDetail = lines.filter(
      (l) => l.includes('[Source: ') && l.includes('[full step: ')
    );
    expect(sourceAndDetail.length).toBe(1);
  });
});

// ── Group 3: Containment (fence round-trip) ───────────────────────────────────
//
// Proves that renderFragmentList places the excerpt verbatim between the tilde
// fence delimiters — byte-exact, with no escaping.  Every emitted fence must
// carry the title="<file><anchor>" meta option (per SPEC, it is the visible
// provenance caption that disarms Expressive Code's file-name-comment scan).
//
// Six fragment shapes are exercised:
//   (a) 4-backtick run — passes through, tilde fence width stays at floor 4
//   (b) pipe character — no escape
//   (c) HTML tag (<div>) — no escape
//   (d) curly braces ({braces}) — no escape
//   (e) complete fenced code block — passes through inside tilde fence
//   (f) ~~~~  at column 0 — forces fence width to 5 (max(4, 4+1))

describe('containment — fragment round-trip and title= fence option', () => {
  const PROV_FILE = 'canonical/skills/aid-review/SKILL.md';

  function provAt(startLine, endLine, excerpt) {
    return makeProvenance({ file: PROV_FILE, startLine, endLine, sourceKind: 'skill', excerpt });
  }

  function renderSingle(excerpt) {
    const chart = makeTestChart([
      makeNode({ order: 1, name: 'N', label: 'N', provenance: provAt(1, 1, excerpt) }),
    ]);
    return renderFragmentList(buildEntries(chart));
  }

  it('4-backtick run round-trips byte-exact through a 4-tilde fence', () => {
    const fragment = '````javascript\nconst x = 1;\n````';
    const rendered = renderSingle(fragment);
    const bodies = extractFenceBodies(rendered);
    expect(bodies).toHaveLength(1);
    expect(bodies[0]).toBe(fragment);
  });

  it('pipe character round-trips byte-exact', () => {
    const fragment = '| State | Action |\n|---|---|\n| INIT | start |';
    const rendered = renderSingle(fragment);
    const bodies = extractFenceBodies(rendered);
    expect(bodies[0]).toBe(fragment);
  });

  it('<div> round-trips byte-exact (no HTML escaping)', () => {
    const fragment = '<div class="note">Important</div>';
    const rendered = renderSingle(fragment);
    const bodies = extractFenceBodies(rendered);
    expect(bodies[0]).toBe(fragment);
  });

  it('{braces} round-trips byte-exact (no template escaping)', () => {
    const fragment = '{{ expression }} and {variable}';
    const rendered = renderSingle(fragment);
    const bodies = extractFenceBodies(rendered);
    expect(bodies[0]).toBe(fragment);
  });

  it('complete fenced code block round-trips byte-exact inside tilde fence', () => {
    const fragment = '```javascript\nconst y = 2;\n// comment\n```';
    const rendered = renderSingle(fragment);
    const bodies = extractFenceBodies(rendered);
    expect(bodies[0]).toBe(fragment);
  });

  it('a fragment line starting with ~~~~ forces fence width to 5', () => {
    // Longest leading-tilde run = 4 → fenceWidth = max(4, 4+1) = 5.
    const fragment = '~~~~\nsome content\n~~~~';
    const rendered = renderSingle(fragment);
    // Opener must use 5 tildes (not 4).
    const openers = extractFenceOpeners(rendered);
    expect(openers).toHaveLength(1);
    expect(openers[0].startsWith('~~~~~')).toBe(true);
    expect(openers[0].startsWith('~~~~~~')).toBe(false);
    // Body still round-trips byte-exact.
    const bodies = extractFenceBodies(rendered);
    expect(bodies[0]).toBe(fragment);
  });

  it('every emitted fence carries the title="<file><anchor>" meta option', () => {
    // Multi-node output so we assert on all fences at once.
    const chart = makeTestChart([
      makeNode({ order: 1, name: 'A', label: 'A', provenance: provAt(1,  1,  'line 1') }),
      makeNode({ order: 2, name: 'B', label: 'B', provenance: provAt(2,  4,  'line 2\nline 3\nline 4') }),
      makeNode({ order: 3, name: 'C', label: 'C', provenance: provAt(10, 10, 'line 10') }),
    ]);
    const rendered = renderFragmentList(buildEntries(chart));
    const openers = extractFenceOpeners(rendered);
    expect(openers.length).toBe(3);
    for (const opener of openers) {
      // Per SPEC: the attribute must be exactly title= (not data-title= or
      // similar), appearing right after the language name.
      expect(opener).toMatch(/plaintext title="/);
      expect(opener).toMatch(/wrap/);
    }
  });
});

// ── Group 4: Verifier — P0–P6 synthetic failing cases ─────────────────────────
//
// One failing fixture per check that task-041 implements.  Every fixture is
// input-separable: it is valid for all checks that precede the one it targets,
// so only the intended check fires.
//
// Separability table:
// ┌─────────┬──────────────┬───────────────────┬──────────────────────────────────────────────────────────────────────┐
// │ Fixture │ Check tripped│ Guard name        │ Why all earlier checks pass                                          │
// ├─────────┼──────────────┼───────────────────┼──────────────────────────────────────────────────────────────────────┤
// │ P1a     │ P1           │ provenance path   │ P1 runs first; file is outside canonical/                            │
// │ P1b     │ P1           │ provenance path   │ P1 runs first; file has ".." segment                                 │
// │ P1c     │ P1           │ provenance path   │ P1 runs first; file does not exist on disk                           │
// │ P0      │ P0 (CRLF)    │ provenance path   │ P1: valid canonical/ path, file exists, no "..", no backslash        │
// │ P2a     │ P2           │ provenance range  │ P1+P0: canonical/, exists, no CRLF; startLine is non-integer         │
// │ P2b     │ P2           │ provenance range  │ P1+P0: canonical/, exists, no CRLF; startLine > endLine              │
// │ P3      │ P3           │ provenance range  │ P1+P0+P2: canonical/, exists, no CRLF, valid integers                │
// │ P4      │ P4           │ provenance excerpt│ P1+P0+P2+P3: endLine in bounds; excerpt differs by one char          │
// │ P5      │ P5           │ provenance excerpt│ P1..P4: same + excerpt MATCHES the file (all whitespace passes P4)   │
// │ P6a     │ P1 (detail)  │ provenance path   │ main provenance passes P0–P5; detail.file outside canonical/         │
// │ P6b     │ P3 (detail)  │ provenance range  │ main provenance passes P0–P5; detail.endLine past EOF                │
// └─────────┴──────────────┴───────────────────┴──────────────────────────────────────────────────────────────────────┘
//
// Note: checkDetailProvenance runs only P1, P2, P3 (no P0, P4, P5 on detail).

describe('verifier — P0–P6 synthetic failing cases', () => {
  let tmpRoot;
  // Repo-relative paths under the fake root
  const SKILL      = 'test-skill';
  const GOOD_REL   = 'canonical/skills/test-skill/good.md';
  const CRLF_REL   = 'canonical/skills/test-skill/crlf.md';
  const WS_REL     = 'canonical/skills/test-skill/ws.md';

  beforeAll(() => {
    tmpRoot = mkdtempSync(join(tmpdir(), 'prov-suite-'));
    const skillDir = join(tmpRoot, 'canonical', 'skills', 'test-skill');
    mkdirSync(skillDir, { recursive: true });

    // good.md — 3 LF-only lines, all with non-whitespace content
    writeFileSync(join(skillDir, 'good.md'), 'alpha\nbeta\ngamma', 'utf8');

    // crlf.md — has \r (triggers P0)
    writeFileSync(join(skillDir, 'crlf.md'), 'line1\r\nline2\r\n', 'utf8');

    // ws.md — line 2 and line 3 are entirely whitespace (P5 fixture)
    // P4 PASSES for range L2-L3 because excerpt matches those lines exactly.
    // P5 fires because the matched slice is all whitespace.
    writeFileSync(join(skillDir, 'ws.md'), 'content\n   \n   \ncontent', 'utf8');
  });

  afterAll(() => {
    rmSync(tmpRoot, { recursive: true, force: true });
  });

  /** Call verifyProvenance injecting the fake root. */
  function verify(chart, extraOpts = {}) {
    return verifyProvenance(chart, { _repoRoot: tmpRoot, ...extraOpts });
  }

  /**
   * Build a minimal chart whose single node has the given provenance.
   * `detail` defaults to null; pass a plain object to test P6.
   */
  function makeVerifyChart(provOverrides = {}, detail = null) {
    const prov = {
      file:       GOOD_REL,
      startLine:  1,
      endLine:    1,
      excerpt:    'alpha',
      sourceKind: 'skill',
      ...provOverrides,
    };
    return {
      skill: SKILL,
      nodes: [{
        id:         'n1',
        order:      1,
        name:       'TEST',
        label:      'Test',
        kind:       'entry',
        terminal:   null,
        detail,
        provenance: prov,
      }],
      edges:    [],
      entries:  ['n1'],
      exits:    [],
      sources:  [],
      warnings: [],
      shape:       'inline-states',
      extractor:   'test',
      confidence:  'derived',
      title:       'test-skill — state flow',
    };
  }

  // ── P1 — path violations ───────────────────────────────────────────────────

  it('P1a: file outside canonical/ throws "provenance path"', () => {
    const chart = makeVerifyChart({ file: 'other/skills/test-skill/SKILL.md' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance path:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/other\/skills\/test-skill\/SKILL\.md#L1/);
    expect(() => verify(chart)).toThrow(/file is not under canonical\//);
  });

  it('P1b: file with ".." segment throws "provenance path"', () => {
    const chart = makeVerifyChart({ file: 'canonical/skills/../skills/test-skill/SKILL.md' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance path:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/file contains "\.\."/);
  });

  it('P1c: non-existent file throws "provenance path"', () => {
    const chart = makeVerifyChart({ file: 'canonical/skills/test-skill/nonexistent.md' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance path:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/nonexistent\.md#L1/);
    expect(() => verify(chart)).toThrow(/file does not exist on disk/);
  });

  // ── P0 — CRLF guard ────────────────────────────────────────────────────────

  it('P0: file with \\r throws "provenance path" (CRLF guard)', () => {
    // P1 passes: canonical/, exists, no ".."; P0 fires on the \r.
    const chart = makeVerifyChart({ file: CRLF_REL, startLine: 1, endLine: 1, excerpt: 'line1' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance path:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/crlf\.md#L1/);
    expect(() => verify(chart)).toThrow(/file contains CRLF/);
  });

  // ── P2 — range integer checks ──────────────────────────────────────────────

  it('P2a: non-integer startLine throws "provenance range"', () => {
    // P1+P0: good.md is canonical/, exists, LF-only; non-integer fires P2.
    const chart = makeVerifyChart({ startLine: 1.5, endLine: 2 });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance range:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/good\.md#L1\.5-L2/);
    expect(() => verify(chart)).toThrow(/invalid range/);
  });

  it('P2b: inverted range (startLine > endLine) throws "provenance range"', () => {
    // P1+P0: same file, no CRLF; inverted range fires P2.
    const chart = makeVerifyChart({ startLine: 3, endLine: 1, excerpt: 'alpha' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance range:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/good\.md#L3-L1/);
    expect(() => verify(chart)).toThrow(/invalid range.*startLine=3.*endLine=1/);
  });

  // ── P3 — endLine past EOF ──────────────────────────────────────────────────

  it('P3: endLine beyond file length throws "provenance range"', () => {
    // P1+P0+P2: good.md (3 lines), canonical/, LF-only, valid integers.
    // endLine=100 is past the 3-line file.
    const chart = makeVerifyChart({ startLine: 1, endLine: 100, excerpt: 'alpha' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance range:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/good\.md#L1-L100/);
    expect(() => verify(chart)).toThrow(/endLine=100 exceeds file length \(3\)/);
  });

  // ── P4 — excerpt mismatch ─────────────────────────────────────────────────

  it('P4: excerpt differing by one char throws "provenance excerpt" naming first-differing-line', () => {
    // P1+P0+P2+P3: good.md, canonical/, LF-only, range L1-L2 is in bounds (2 <= 3).
    // good.md line 1 = 'alpha', line 2 = 'beta'.
    // We corrupt line 1 by one character: 'xlpha' instead of 'alpha'.
    const chart = makeVerifyChart({ startLine: 1, endLine: 2, excerpt: 'xlpha\nbeta' });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance excerpt:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/good\.md#L1-L2/);
    expect(() => verify(chart)).toThrow(/excerpt mismatch/);
    // P4 requirement: message names the first differing line (1-based absolute).
    expect(() => verify(chart)).toThrow(/first-differing-line=1/);
  });

  // ── P5 — all-whitespace excerpt ───────────────────────────────────────────

  it('P5: all-whitespace excerpt that passes P4 throws "provenance excerpt"', () => {
    // ws.md content: 'content\n   \n   \ncontent'
    // Range L2-L3 gives ['   ', '   '].join('\n') = '   \n   ' — all whitespace.
    // P4 PASSES because the excerpt exactly matches the file slice.
    // P5 fires because the matched slice is entirely whitespace characters.
    const chart = makeVerifyChart({
      file:      WS_REL,
      startLine: 2,
      endLine:   3,
      excerpt:   '   \n   ',
    });
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance excerpt:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/ws\.md#L2-L3/);
    expect(() => verify(chart)).toThrow(/excerpt is all whitespace/);
  });

  // ── P6 — detail path/range checks ────────────────────────────────────────

  it('P6a: detail.file outside canonical/ throws "provenance path"', () => {
    // Main provenance passes P0–P5 (good.md, L1-L1, 'alpha').
    // detail.file is outside canonical/ — fires P1 inside checkDetailProvenance.
    const detail = {
      file:      'other/skills/test-skill/SKILL.md',
      startLine: 1,
      endLine:   1,
      sourceKind: 'skill',
    };
    const chart = makeVerifyChart({}, detail);
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance path:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/other\/skills\/test-skill\/SKILL\.md/);
    expect(() => verify(chart)).toThrow(/file is not under canonical\//);
  });

  it('P6b: detail.endLine past EOF throws "provenance range"', () => {
    // Main provenance passes P0–P5. detail.file is canonical/ and exists (good.md, 3 lines).
    // detail.startLine=1, detail.endLine=100 fires P3 inside checkDetailProvenance.
    const detail = {
      file:      GOOD_REL,
      startLine: 1,
      endLine:   100,
      sourceKind: 'skill',
    };
    const chart = makeVerifyChart({}, detail);
    expect(() => verify(chart)).toThrow(/\[gen-skills\] provenance range:/);
    expect(() => verify(chart)).toThrow(/skill=test-skill/);
    expect(() => verify(chart)).toThrow(/node=n1/);
    expect(() => verify(chart)).toThrow(/canonical\/skills\/test-skill\/good\.md#L1-L100/);
    expect(() => verify(chart)).toThrow(/endLine=100 exceeds file length \(3\)/);
  });
});

// ── Group 5: Determinism ──────────────────────────────────────────────────────
//
// renderFragmentList on the same entries array returns identical strings on
// each call.  Proved in isolation so a failure localises here rather than
// in the whole-page byte-comparison in feature-001's suite.

describe('determinism — renderFragmentList', () => {
  it('two calls on the same entries return identical strings', () => {
    const prov = makeProvenance({
      file:      'canonical/skills/aid-review/SKILL.md',
      startLine: 1,
      endLine:   3,
      sourceKind: 'skill',
      excerpt:   '## aid-review\n\nShort excerpt.',
    });
    const chart = makeTestChart([
      makeNode({ order: 1, name: 'STEP', label: 'Step', provenance: prov }),
    ]);
    const entries = buildEntries(chart);
    const first  = renderFragmentList(entries);
    const second = renderFragmentList(entries);
    expect(first).toBe(second);
  });

  it('renderFragmentList on two separate buildEntries calls returns identical strings', () => {
    const prov = makeProvenance({
      file:      'canonical/skills/aid-ask/SKILL.md',
      startLine: 1,
      endLine:   1,
      sourceKind: 'skill',
      excerpt:   '# aid-ask',
    });
    const chart = makeTestChart([
      makeNode({ order: 1, name: 'ENTRY', label: 'Entry', provenance: prov }),
    ]);
    const first  = renderFragmentList(buildEntries(chart));
    const second = renderFragmentList(buildEntries(chart));
    expect(first).toBe(second);
  });
});

// The second half of the determinism criterion: "two gen:skills runs leave the
// fragment section byte-identical". Rather than spawn the generator — which would
// rewrite every tracked skill page and flow sidecar as a side effect of running
// the test suite — this compares the section already on disk against a freshly
// rendered one. If a second run could produce different bytes, this is where it
// shows, because the on-disk section IS the previous run's output.
//
// "Every tracked page and sidecar", not a file count: the generator's write set is
// one-per-corpus-skill by construction, so no number here can fall out of date.
describe('determinism — on-disk section equals a fresh render (whole corpus)', () => {
  const SECTION = '## Source fragments';

  /** The `## Source fragments` section of a generated page: that H2 to EOF. */
  function onDiskSection(dirName) {
    const page = join(SITE_SKILLS_DIR, `${dirName}.md`);
    if (!existsSync(page)) return null;
    const text = readFileSync(page, 'utf8');
    const at = text.indexOf(`\n${SECTION}`);
    return at === -1 ? null : text.slice(at + 1);
  }

  it('every generated page carries the section', () => {
    const dirs = getSkillDirNames();
    expect(dirs.length).toBeGreaterThan(50);
    const without = dirs.filter((d) => onDiskSection(d) === null);
    expect(without).toEqual([]);
  });

  it('each on-disk section is byte-identical to a fresh render', () => {
    const dirs = getSkillDirNames();
    expect(dirs.length).toBeGreaterThan(50);

    const differing = [];
    let compared = 0;
    for (const dirName of dirs) {
      const onDisk = onDiskSection(dirName);
      if (onDisk === null) continue;
      const fresh = renderFragmentList(
        buildEntries(buildFlowChart({ name: dirName, dir: REPO_ROOT })),
      );
      compared++;
      // The page is assembled with the section trailing, so compare on the
      // trimmed-trailing-newline form: the page's final newline belongs to the
      // file, not to the section.
      if (onDisk.replace(/\n+$/, '') !== fresh.replace(/\n+$/, '')) {
        differing.push(dirName);
      }
    }

    // Non-vacuity: the loop actually compared the whole corpus, not zero pages.
    expect(compared).toBe(dirs.length);
    expect(differing).toEqual([]);
  });
});

// ── Group 6: No-JS Invariant ──────────────────────────────────────────────────
//
// The rendered markdown must contain no JavaScript artefacts (<script, client:,
// import) and the [Source: ] link count must equal chart.nodes.length exactly
// (an equality, not a lower bound — a missing link is as bad as a spurious one).

describe('no-JS invariant', () => {
  let rendered;
  let chart;

  beforeAll(() => {
    chart = buildFlowChart({ name: 'aid-review', dir: REPO_ROOT });
    const entries = buildEntries(chart);
    rendered = renderFragmentList(entries);
  });

  it('rendered markdown contains no <script tags', () => {
    expect(rendered).not.toContain('<script');
  });

  it('rendered markdown contains no client: directives', () => {
    expect(rendered).not.toContain('client:');
  });

  it('rendered markdown contains no import statements', () => {
    expect(rendered).not.toContain('\nimport ');
    expect(rendered).not.toContain('\nimport{');
  });

  it('[Source: ] link count equals chart.nodes.length (equality)', () => {
    const count = countOccurrences(rendered, '[Source: ');
    expect(count).toBe(chart.nodes.length);
  });
});
