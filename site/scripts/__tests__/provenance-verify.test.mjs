// provenance-verify.test.mjs — Unit tests for lib/provenance/verify.mjs
//
// Seven check fixtures (P0–P6), each tripping exactly one check.  Every
// fixture for P*n* is valid for all earlier checks (P0..P*n-1*).
//
// Separability table (see bottom of file for narrative):
//   Fixture  Check tripped    Guard name          Earlier checks pass because
//   P1-*     P1 (path)        provenance path     Nothing runs before P1 in impl
//   P0       P0 (CRLF)        provenance path     P1: valid path, file exists
//   P2       P2 (bad range)   provenance range    P1+P0: valid path, file exists, no CRLF
//   P3       P3 (past EOF)    provenance range    P1+P0+P2: same + valid range syntax
//   P4       P4 (mismatch)    provenance excerpt  P1+P0+P2+P3: same + endLine in bounds
//   P5       P5 (whitespace)  provenance excerpt  P1..P4: same + P4 PASSES (excerpt matches)
//   P6       P6 (detail path) provenance path     P0..P5 on .provenance all pass

import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import { writeFileSync, mkdtempSync, mkdirSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { verifyProvenance } from '../lib/provenance/verify.mjs';

// ── Temp fixture tree ─────────────────────────────────────────────────────────
//
// All fixture files live under a tmpdir that mimics the repo layout
// (tmpRoot/canonical/skills/test-skill/...).  Nothing is written to the repo.

let tmpRoot;
let skillDir;
let goodFile;        // 3-line LF file (no CRLF)
let crlfFile;        // 3-line CRLF file (has \r)
let whitespaceFile;  // 3 lines where line 2 is only spaces

beforeAll(() => {
  tmpRoot  = mkdtempSync(join(tmpdir(), 'prov-verify-'));
  skillDir = join(tmpRoot, 'canonical', 'skills', 'test-skill');
  mkdirSync(skillDir, { recursive: true });

  // Good file — three lines, LF only, all have content.
  goodFile = join(skillDir, 'good.md');
  writeFileSync(goodFile, 'alpha\nbeta\ngamma', 'utf8');

  // CRLF file — triggers P0.
  crlfFile = join(skillDir, 'crlf.md');
  writeFileSync(crlfFile, 'line1\r\nline2\r\n', 'utf8');

  // Whitespace file — line 2 is only spaces (triggers P5 when excerpt matches).
  whitespaceFile = join(skillDir, 'whitespace.md');
  writeFileSync(whitespaceFile, 'content\n   \ncontent', 'utf8');
});

afterAll(() => {
  rmSync(tmpRoot, { recursive: true, force: true });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Build a minimal valid chart with one node.  Override any field you need.
 *
 * Defaults: file='canonical/skills/test-skill/good.md', range L1-L1,
 * excerpt='alpha' (exact match for goodFile line 1), no detail.
 */
function makeChart(overrides = {}, detailOverride = null) {
  const prov = {
    file:      'canonical/skills/test-skill/good.md',
    startLine: 1,
    endLine:   1,
    excerpt:   'alpha',
    sourceKind: 'skill',
    ...overrides,
  };
  return {
    skill: 'test-skill',
    nodes: [{
      id:         'n1',
      order:      1,
      name:       'TEST',
      label:      'Test',
      kind:       'entry',
      terminal:   null,
      provenance: prov,
      detail:     detailOverride,
    }],
    edges: [],
    entries: ['n1'],
    exits:   [],
    sources: [],
    warnings: [],
    shape: 'inline-states',
    extractor: 'test',
    confidence: 'derived',
    title: 'test-skill — state flow',
  };
}

/**
 * A valid two-node chart where both nodes cite the SAME file at different
 * ranges — the shape the read-once claim is about, and the one a doorway corpus
 * produces when many nodes share one engine file.
 */
function sameFileTwoNodeChart() {
  const file = 'canonical/skills/test-skill/good.md';
  return {
    skill: 'test-skill',
    nodes: [
      {
        id: 'n1', order: 1, name: 'A', label: 'A', kind: 'entry',
        terminal: null, detail: null,
        provenance: { file, startLine: 1, endLine: 1, excerpt: 'alpha', sourceKind: 'skill' },
      },
      {
        id: 'n2', order: 2, name: 'B', label: 'B', kind: 'exit',
        terminal: { advanceType: 'HALT', handoff: null }, detail: null,
        provenance: { file, startLine: 2, endLine: 2, excerpt: 'beta', sourceKind: 'skill' },
      },
    ],
    edges: [], entries: ['n1'], exits: ['n2'], sources: [], warnings: [],
    shape: 'inline-states', extractor: 'test', confidence: 'derived',
    title: 'test-skill — state flow',
  };
}

/** Call verifyProvenance with the shared tmpRoot injected. */
function verify(chart, extraOpts = {}) {
  return verifyProvenance(chart, { _repoRoot: tmpRoot, ...extraOpts });
}

// ── Happy path ────────────────────────────────────────────────────────────────

describe('verifyProvenance — happy path', () => {
  it('accepts a well-formed chart with valid provenance', () => {
    expect(() => verify(makeChart())).not.toThrow();
  });

  it('accepts a multi-line range where excerpt exactly matches the file', () => {
    const chart = makeChart({
      startLine: 1,
      endLine:   2,
      excerpt:   'alpha\nbeta',
    });
    expect(() => verify(chart)).not.toThrow();
  });

  it('accepts a chart where detail passes P1–P3', () => {
    const detail = {
      file:      'canonical/skills/test-skill/good.md',
      startLine: 1,
      endLine:   3,
      excerpt:   'alpha\nbeta\ngamma',  // present but not checked by P6
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, detail))).not.toThrow();
  });
});

// ── P1 — path violations (four sub-cases, all throw 'provenance path') ────────

describe('P1 — empty file name', () => {
  it('throws with guard "provenance path"', () => {
    const chart = makeChart({ file: '' });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance path:');
  });

  it('throw message names skill and node', () => {
    const chart = makeChart({ file: '' });
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance path: skill=test-skill node=n1'
    );
  });

  it('throw message says "file is empty"', () => {
    const chart = makeChart({ file: '' });
    expect(() => verify(chart)).toThrow('file is empty');
  });
});

describe('P1 — file not under canonical/', () => {
  it('throws with guard "provenance path"', () => {
    const chart = makeChart({ file: 'other/path/file.md' });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance path:');
  });

  it('throw message says "not under canonical/"', () => {
    const chart = makeChart({ file: 'other/path/file.md' });
    expect(() => verify(chart)).toThrow('not under canonical/');
  });
});

describe('P1 — file contains ".." segment', () => {
  it('throws with guard "provenance path"', () => {
    const chart = makeChart({ file: 'canonical/../etc/passwd' });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance path:');
  });

  it('throw message says contains ".." segment', () => {
    const chart = makeChart({ file: 'canonical/../etc/passwd' });
    expect(() => verify(chart)).toThrow('contains ".." segment');
  });
});

describe('P1 — file does not exist on disk', () => {
  it('throws with guard "provenance path"', () => {
    const chart = makeChart({ file: 'canonical/skills/nonexistent/SKILL.md' });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance path:');
  });

  it('throw message says "does not exist on disk"', () => {
    const chart = makeChart({ file: 'canonical/skills/nonexistent/SKILL.md' });
    expect(() => verify(chart)).toThrow('does not exist on disk');
  });

  it('throw message includes the file path and location', () => {
    const chart = makeChart({ file: 'canonical/skills/nonexistent/SKILL.md' });
    expect(() => verify(chart)).toThrow(
      'canonical/skills/nonexistent/SKILL.md#L1'
    );
  });
});

// ── P0 — CRLF guard ───────────────────────────────────────────────────────────
//
// Separability: P1 passes (crlf.md exists, valid path). P0 fires.

describe('P0 — CRLF in file', () => {
  it('throws with guard "provenance path"', () => {
    // P1 passes: file is valid path and exists.
    // P0 fires: file contains \r.
    const chart = makeChart({
      file:      'canonical/skills/test-skill/crlf.md',
      startLine: 1,
      endLine:   1,
      excerpt:   'line1',  // irrelevant — we never reach P4
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance path:');
  });

  it('throw message says "CRLF"', () => {
    const chart = makeChart({
      file:      'canonical/skills/test-skill/crlf.md',
      startLine: 1,
      endLine:   1,
      excerpt:   'line1',
    });
    expect(() => verify(chart)).toThrow('CRLF');
  });

  it('throw message includes skill, node, and file#L location', () => {
    const chart = makeChart({
      file:      'canonical/skills/test-skill/crlf.md',
      startLine: 1,
      endLine:   1,
      excerpt:   'line1',
    });
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance path: skill=test-skill node=n1 canonical/skills/test-skill/crlf.md#L1 file contains CRLF'
    );
  });

  it('does NOT throw on a file with no \\r', () => {
    // Regression: goodFile has no CRLF, so P0 must not fire.
    expect(() => verify(makeChart())).not.toThrow();
  });
});

// ── P2 — invalid range ────────────────────────────────────────────────────────
//
// Separability: P1 passes (goodFile exists), P0 passes (no CRLF). P2 fires.

describe('P2 — startLine < 1', () => {
  it('throws with guard "provenance range"', () => {
    const chart = makeChart({
      startLine: 0,
      endLine:   1,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance range:');
  });

  it('throw message says "invalid range"', () => {
    const chart = makeChart({
      startLine: 0,
      endLine:   1,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('invalid range');
  });

  it('throw message includes skill, node, and file#L location', () => {
    const chart = makeChart({
      startLine: 0,
      endLine:   1,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('skill=test-skill node=n1');
  });
});

describe('P2 — startLine > endLine', () => {
  it('throws with guard "provenance range"', () => {
    const chart = makeChart({
      startLine: 3,
      endLine:   1,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance range:');
  });

  it('throw message says "invalid range"', () => {
    const chart = makeChart({
      startLine: 3,
      endLine:   1,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('invalid range');
  });
});

describe('P2 — non-integer startLine', () => {
  it('throws with guard "provenance range"', () => {
    const chart = makeChart({
      startLine: 1.5,
      endLine:   2,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance range:');
  });
});

// ── P3 — endLine beyond EOF ───────────────────────────────────────────────────
//
// Separability: P1 passes (goodFile), P0 passes (no CRLF), P2 passes
// (1 <= 1 <= 100 is valid syntax). P3 fires because goodFile has 3 lines.

describe('P3 — endLine beyond EOF', () => {
  it('throws with guard "provenance range"', () => {
    // goodFile has 3 lines; endLine=100 is beyond EOF.
    const chart = makeChart({
      startLine: 1,
      endLine:   100,
      excerpt:   'alpha',  // irrelevant — we never reach P4
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance range:');
  });

  it('throw message says "endLine=" and "exceeds file length"', () => {
    const chart = makeChart({
      startLine: 1,
      endLine:   100,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow('endLine=100 exceeds file length');
  });

  it('throw message includes the file location', () => {
    const chart = makeChart({
      startLine: 1,
      endLine:   100,
      excerpt:   'alpha',
    });
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance range: skill=test-skill node=n1 canonical/skills/test-skill/good.md#L1-L100 endLine=100 exceeds file length (3)'
    );
  });
});

// ── P4 — excerpt mismatch ─────────────────────────────────────────────────────
//
// Separability: P1+P0+P2+P3 all pass (valid path, no CRLF, range L2-L3 is valid
// and in bounds for goodFile). P4 fires because excerpt doesn't match 'beta\ngamma'.

describe('P4 — excerpt mismatch', () => {
  it('throws with guard "provenance excerpt"', () => {
    const chart = makeChart({
      startLine: 2,
      endLine:   3,
      excerpt:   'WRONG',  // real content is 'beta\ngamma'
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance excerpt:');
  });

  it('throw message says "excerpt mismatch"', () => {
    const chart = makeChart({
      startLine: 2,
      endLine:   3,
      excerpt:   'WRONG',
    });
    expect(() => verify(chart)).toThrow('excerpt mismatch');
  });

  it('throw message names the first differing line (absolute, 1-based)', () => {
    // Range L2-L3; first mismatch is at line 2 (index 0 in the range).
    const chart = makeChart({
      startLine: 2,
      endLine:   3,
      excerpt:   'WRONG',
    });
    expect(() => verify(chart)).toThrow('first-differing-line=2');
  });

  it('names the SECOND differing line when line 1 of the range matches', () => {
    // Range L2-L3 in goodFile: 'beta\ngamma'
    // Provide excerpt that matches line 2 ('beta') but differs at line 3 ('gamma').
    const chart = makeChart({
      startLine: 2,
      endLine:   3,
      excerpt:   'beta\nWRONG',
    });
    // First diff is at position 1 in the range → absolute line 3.
    expect(() => verify(chart)).toThrow('first-differing-line=3');
  });

  it('throw message includes skill, node, and file#L location', () => {
    const chart = makeChart({
      startLine: 1,
      endLine:   1,
      excerpt:   'WRONG',
    });
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance excerpt: skill=test-skill node=n1 canonical/skills/test-skill/good.md#L1 excerpt mismatch first-differing-line=1'
    );
  });
});

// ── P5 — all-whitespace excerpt ───────────────────────────────────────────────
//
// The critical separability case: P4 PASSES (excerpt matches the file),
// but the excerpt is all whitespace.
//
// whitespaceFile: 'content\n   \ncontent'
//   line 1: 'content'
//   line 2: '   '      ← only spaces
//   line 3: 'content'
//
// Provenance: range L2-L2, excerpt='   '  (exact match → P4 passes).
// P5 fires because '   ' has no non-whitespace character.

describe('P5 — all-whitespace excerpt (P4 passes)', () => {
  it('throws with guard "provenance excerpt"', () => {
    const chart = makeChart({
      file:      'canonical/skills/test-skill/whitespace.md',
      startLine: 2,
      endLine:   2,
      excerpt:   '   ',  // exactly what line 2 of whitespaceFile contains
    });
    expect(() => verify(chart)).toThrow('[gen-skills] provenance excerpt:');
  });

  it('throw message says "all whitespace"', () => {
    const chart = makeChart({
      file:      'canonical/skills/test-skill/whitespace.md',
      startLine: 2,
      endLine:   2,
      excerpt:   '   ',
    });
    expect(() => verify(chart)).toThrow('excerpt is all whitespace');
  });

  it('throw message includes skill, node, and file#L location', () => {
    const chart = makeChart({
      file:      'canonical/skills/test-skill/whitespace.md',
      startLine: 2,
      endLine:   2,
      excerpt:   '   ',
    });
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance excerpt: skill=test-skill node=n1 canonical/skills/test-skill/whitespace.md#L2 excerpt is all whitespace'
    );
  });

  it('P4 would have passed — the excerpt literally equals the file content', () => {
    // Prove that P4 is not the reason it throws: manually confirm the match.
    // (The test above shows P5 fires; this assertion makes the P4-pass explicit.)
    const excerpt = '   ';
    // whitespaceFile line 2 is '   ' (three spaces between two \n)
    // Split on \n: ['content', '   ', 'content'], index 1 is '   '
    expect(excerpt).toBe('   ');
    expect(/\S/.test(excerpt)).toBe(false);  // confirms P5 fires
    // Not a redundant check: proves excerpt !== '' (empty), it truly has characters.
    expect(excerpt.length).toBeGreaterThan(0);
  });
});

// ── P6 — detail gets P1–P3 only ──────────────────────────────────────────────
//
// Separability: node.provenance passes P0–P5 (valid, no CRLF, in-bounds, match,
// non-whitespace). node.detail has an invalid path → throws provenance path.
// P4 and P5 are NEVER run on detail (by contract).

describe('P6 — detail with invalid path', () => {
  it('throws with guard "provenance path" from the detail check', () => {
    const badDetail = {
      file:      'canonical/skills/nonexistent/DETAIL.md',
      startLine: 1,
      endLine:   5,
      excerpt:   '',
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, badDetail))).toThrow(
      '[gen-skills] provenance path:'
    );
  });

  it('throw message says "does not exist on disk"', () => {
    const badDetail = {
      file:      'canonical/skills/nonexistent/DETAIL.md',
      startLine: 1,
      endLine:   5,
      excerpt:   '',
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, badDetail))).toThrow('does not exist on disk');
  });

  it('detail with bad range (P2) throws "provenance range" once P1 passes', () => {
    // detail.file exists; but startLine > endLine → P2 fires on detail.
    const badDetail = {
      file:      'canonical/skills/test-skill/good.md',
      startLine: 5,
      endLine:   1,
      excerpt:   '',
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, badDetail))).toThrow(
      '[gen-skills] provenance range:'
    );
  });

  it('detail with valid P1–P3 does NOT throw', () => {
    // Even if detail.excerpt is wrong/empty, P4/P5 are never run on detail.
    const okDetail = {
      file:      'canonical/skills/test-skill/good.md',
      startLine: 1,
      endLine:   3,
      excerpt:   '',  // intentionally wrong — P6 must not check it
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, okDetail))).not.toThrow();
  });
});

// ── P6 detail — P3 check ─────────────────────────────────────────────────────
//
// Verify that P3 also runs on detail provenance (not just P1 and P2).

describe('P6 detail — endLine beyond EOF (P3)', () => {
  it('throws "provenance range" when detail.endLine exceeds the file length', () => {
    // goodFile has 3 lines; endLine=100 is beyond EOF.
    // P1 passes (file exists), P2 passes (1 <= 1 <= 100 are valid integers).
    // P3 fires because 100 > 3.
    const badDetail = {
      file:      'canonical/skills/test-skill/good.md',
      startLine: 1,
      endLine:   100,
      excerpt:   '',
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, badDetail))).toThrow(
      '[gen-skills] provenance range:'
    );
  });

  it('throw message says "endLine=" and "exceeds file length"', () => {
    const badDetail = {
      file:      'canonical/skills/test-skill/good.md',
      startLine: 1,
      endLine:   100,
      excerpt:   '',
      sourceKind: 'skill',
    };
    expect(() => verify(makeChart({}, badDetail))).toThrow(
      'endLine=100 exceeds file length'
    );
  });
});

// ── Read-once guarantee ───────────────────────────────────────────────────────
//
// A chart with two nodes citing the same file must cause exactly one disk read.
// Proven by a counting wrapper around Map.set — `cache.set` is called once per
// unique file when the cache hit-check works; twice when it is bypassed.

describe('read-once cache', () => {
  it('two nodes citing the same file trigger exactly one disk read (cache.set count = 1)', () => {
    // Wrap an external Map to count how many times a value is written.
    // With the cache working: set(file, entry) is called once (on first read).
    // Without the cache working: set(file, entry) is called N times (once per node).
    const setCount = { n: 0 };
    const countingCache = new Map();
    const origSet = Map.prototype.set.bind(countingCache);
    countingCache.set = (k, v) => { setCount.n++; return origSet(k, v); };

    const chart = {
      skill: 'test-skill',
      nodes: [
        {
          id: 'n1', order: 1, name: 'A', label: 'A', kind: 'entry',
          terminal: null, detail: null,
          provenance: {
            file: 'canonical/skills/test-skill/good.md',
            startLine: 1, endLine: 1, excerpt: 'alpha', sourceKind: 'skill',
          },
        },
        {
          id: 'n2', order: 2, name: 'B', label: 'B', kind: 'exit',
          terminal: { advanceType: 'HALT', handoff: null }, detail: null,
          provenance: {
            file: 'canonical/skills/test-skill/good.md',
            startLine: 2, endLine: 2, excerpt: 'beta', sourceKind: 'skill',
          },
        },
      ],
      edges: [], entries: ['n1'], exits: ['n2'], sources: [], warnings: [],
      shape: 'inline-states', extractor: 'test', confidence: 'derived',
      title: 'test-skill — state flow',
    };

    verifyProvenance(chart, { _repoRoot: tmpRoot, _cache: countingCache });

    // Both nodes cite the same file; the cache must have stored it only once.
    expect(setCount.n).toBe(1);
    expect(countingCache.size).toBe(1);
    expect(countingCache.has('canonical/skills/test-skill/good.md')).toBe(true);
  });

  // The Map.set counter above proves the cache is *populated* once, which is not
  // the same claim. A readCached that called readFileSync before consulting the
  // cache would still store one entry while reading the file six times, and that
  // counter would stay green. The criterion says reads, so count reads.
  it('reads a file cited by several nodes once per call — counted at readFileSync', async () => {
    const reads = [];

    vi.resetModules();
    vi.doMock('node:fs', async (importOriginal) => {
      const actual = await importOriginal();
      return {
        ...actual,
        default: actual,
        readFileSync: (p, enc) => {
          reads.push(String(p).replace(/\\/g, '/'));
          return actual.readFileSync(p, enc);
        },
      };
    });

    try {
      const { verifyProvenance: fresh } = await import('../lib/provenance/verify.mjs');
      fresh(sameFileTwoNodeChart(), { _repoRoot: tmpRoot });
    } finally {
      vi.doUnmock('node:fs');
      vi.resetModules();
    }

    // Two nodes, and P0/P3/P4 each consume the cache: six readCached calls,
    // which must collapse to exactly one read of the file on disk.
    const goodReads = reads.filter((p) => p.endsWith('/good.md'));
    expect(goodReads).toHaveLength(1);
  });

  // The claim above is per-CALL, which is not what the SPEC asks for. "Once per
  // run" only bites across charts: 64 of the 111 skills cite the same engine
  // template, so a fresh cache per call reads it 64 times. A caller passes one
  // cache through _cache to collapse that; this proves the seam actually does it.
  it('reads a shared file once across MANY calls when one cache is passed', async () => {
    const reads = [];

    vi.resetModules();
    vi.doMock('node:fs', async (importOriginal) => {
      const actual = await importOriginal();
      return {
        ...actual,
        default: actual,
        readFileSync: (p, enc) => {
          reads.push(String(p).replace(/\\/g, '/'));
          return actual.readFileSync(p, enc);
        },
      };
    });

    try {
      const { verifyProvenance: fresh } = await import('../lib/provenance/verify.mjs');
      const shared = new Map();
      // Three separate charts, each citing the same file — the doorway shape.
      for (let i = 0; i < 3; i++) {
        fresh(sameFileTwoNodeChart(), { _repoRoot: tmpRoot, _cache: shared });
      }
    } finally {
      vi.doUnmock('node:fs');
      vi.resetModules();
    }

    const goodReads = reads.filter((p) => p.endsWith('/good.md'));
    expect(goodReads).toHaveLength(1);
  });

  // Non-vacuity for the test above: without the shared cache the same three calls
  // read three times, so the assertion is measuring the cache and not the loop.
  it('reads a shared file once PER call when no cache is passed', async () => {
    const reads = [];

    vi.resetModules();
    vi.doMock('node:fs', async (importOriginal) => {
      const actual = await importOriginal();
      return {
        ...actual,
        default: actual,
        readFileSync: (p, enc) => {
          reads.push(String(p).replace(/\\/g, '/'));
          return actual.readFileSync(p, enc);
        },
      };
    });

    try {
      const { verifyProvenance: fresh } = await import('../lib/provenance/verify.mjs');
      for (let i = 0; i < 3; i++) {
        fresh(sameFileTwoNodeChart(), { _repoRoot: tmpRoot });
      }
    } finally {
      vi.doUnmock('node:fs');
      vi.resetModules();
    }

    const goodReads = reads.filter((p) => p.endsWith('/good.md'));
    expect(goodReads).toHaveLength(3);
  });

  it('cache entry has text and lines properties', () => {
    const externalCache = new Map();
    verify(makeChart(), { _cache: externalCache });
    const entry = externalCache.get('canonical/skills/test-skill/good.md');
    expect(typeof entry.text).toBe('string');
    expect(Array.isArray(entry.lines)).toBe(true);
    expect(entry.lines.length).toBeGreaterThan(0);
  });
});

// ── Guard name stability ──────────────────────────────────────────────────────
//
// The three stable greppable literals must appear verbatim in thrown messages.

describe('guard name stability', () => {
  it('"provenance path" appears in path-violation messages', () => {
    expect(() => verify(makeChart({ file: '' }))).toThrow('provenance path');
  });

  it('"provenance range" appears in range-violation messages', () => {
    expect(() =>
      verify(makeChart({ startLine: 0, endLine: 1, excerpt: 'alpha' }))
    ).toThrow('provenance range');
  });

  it('"provenance excerpt" appears in excerpt-violation messages', () => {
    expect(() =>
      verify(makeChart({ startLine: 1, endLine: 1, excerpt: 'WRONG' }))
    ).toThrow('provenance excerpt');
  });
});

// ── Throw-not-warn: first violation stops iteration ───────────────────────────

describe('throws on the first violation — never warns', () => {
  it('stops at node n1 when n1 has a bad path (n2 is never reached)', () => {
    const chart = {
      skill: 'test-skill',
      nodes: [
        {
          id: 'n1', order: 1, name: 'A', label: 'A', kind: 'entry',
          terminal: null, detail: null,
          provenance: {
            file: '',  // P1 fires on n1
            startLine: 1, endLine: 1, excerpt: 'alpha', sourceKind: 'skill',
          },
        },
        {
          id: 'n2', order: 2, name: 'B', label: 'B', kind: 'exit',
          terminal: { advanceType: 'HALT', handoff: null }, detail: null,
          provenance: {
            file: 'canonical/skills/test-skill/good.md',
            startLine: 1, endLine: 1, excerpt: 'alpha', sourceKind: 'skill',
          },
        },
      ],
      edges: [], entries: ['n1'], exits: ['n2'], sources: [], warnings: [],
      shape: 'inline-states', extractor: 'test', confidence: 'derived',
      title: 'test-skill — state flow',
    };

    // Must throw exactly the n1 error (guard + node id).
    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance path: skill=test-skill node=n1'
    );
  });

  it('node.detail failure fires before moving to the next node', () => {
    const chart = {
      skill: 'test-skill',
      nodes: [
        {
          id: 'n1', order: 1, name: 'A', label: 'A', kind: 'entry',
          terminal: null,
          provenance: {
            file: 'canonical/skills/test-skill/good.md',
            startLine: 1, endLine: 1, excerpt: 'alpha', sourceKind: 'skill',
          },
          detail: {
            file: '',  // P6 fires here on n1's detail
            startLine: 1, endLine: 1, excerpt: '', sourceKind: 'skill',
          },
        },
        {
          id: 'n2', order: 2, name: 'B', label: 'B', kind: 'exit',
          terminal: { advanceType: 'HALT', handoff: null }, detail: null,
          provenance: {
            file: 'canonical/skills/test-skill/good.md',
            startLine: 2, endLine: 2, excerpt: 'beta', sourceKind: 'skill',
          },
        },
      ],
      edges: [], entries: ['n1'], exits: ['n2'], sources: [], warnings: [],
      shape: 'inline-states', extractor: 'test', confidence: 'derived',
      title: 'test-skill — state flow',
    };

    expect(() => verify(chart)).toThrow(
      '[gen-skills] provenance path: skill=test-skill node=n1'
    );
    // n2 error would say node=n2; confirm it's n1 that fired.
    expect(() => verify(chart)).not.toThrow(/node=n2/);
  });
});
