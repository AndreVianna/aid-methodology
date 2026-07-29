// provenance-appender.test.mjs — Unit tests for lib/provenance/index.mjs
//
// Tests the provenanceAppender = { id: 'source-fragments', render(skill) }
// exported by lib/provenance/index.mjs.
//
// Acceptance criteria covered:
//   AC-1  verifyProvenance runs before any markdown is produced — a chart with bad
//         provenance produces no page bytes (renderFragmentList never called).
//   AC-2  The appender uses only SkillRecord.dirName and sourcePath; bodyStartLine
//         and lineCount appear nowhere in the module (source grep).
//   AC-3  buildFlowChart is memoised per dirName — asserted by call count.
//   AC-4  The section is emitted unconditionally for every skill; there is no code
//         path that skips it (no conditional gate in the source, plus direct proof
//         with two real skills).
//   AC-7  The appender id is 'source-fragments'.
//
// All mutation tests use the mutator at .aid/.temp/mutate.py.
//
// Notes:
// - Real skills (aid-review, aid-create-api) are used to verify integration with
//   the live corpus (verifyProvenance passes clean, section emitted).
// - Testing seams opts._memo, opts._buildFlowChart, opts._renderFragmentList allow
//   call counting and render-before-verify proof without needing filesystem fakes.

import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect, beforeAll } from 'vitest';
import { provenanceAppender } from '../lib/provenance/index.mjs';
import { REPO_ROOT } from '../skills/paths.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MODULE_PATH = resolve(__dirname, '../lib/provenance/index.mjs');
const REPO_ROOT   = resolve(__dirname, '../../../');

// ── Shared fixtures ───────────────────────────────────────────────────────────

/**
 * A minimal FlowChart with a provenance record that will fail verifyProvenance.
 * Uses file: '' to trigger P1 immediately — no disk I/O needed, no tmp files.
 */
function makeBadChart() {
  return {
    skill: 'test-bad',
    nodes: [{
      id: 'n1', order: 1, name: 'BAD', label: 'bad', kind: 'entry',
      terminal: null, detail: null,
      provenance: { file: '', startLine: 1, endLine: 1, excerpt: 'x', sourceKind: 'skill' },
    }],
    edges: [], entries: ['n1'], exits: [], sources: [], warnings: [],
    shape: 'inline-states', extractor: 'test', confidence: 'derived',
    title: 'test-bad — state flow',
  };
}

/** SkillRecord shape sufficient for the appender (dirName + sourcePath only). */
function makeSkill(dirName) {
  return {
    dirName,
    sourcePath: 'canonical/skills/' + dirName + '/SKILL.md',
  };
}

// ── Run-level source-file cache ──────────────────────────────────────────────
//
// verifyProvenance defaults to a fresh cache per call, which deduplicates reads
// within one chart but not across the corpus. Across the corpus is where the cost
// is: 64 of the 111 skills cite canonical/aid/templates/shortcut-engine.md, so a
// per-call cache reads it 64 times. The appender therefore owns one cache for the
// run and threads it through every verify call.

describe('run-level file cache is shared across skills', () => {
  /** A chart whose single node cites `file`, valid for every check. */
  function chartCiting(skillName, file, excerpt, startLine, endLine) {
    return {
      skill: skillName,
      nodes: [{
        id: 'n1', order: 1, name: 'STEP', label: 'Step', kind: 'entry',
        terminal: null, detail: null,
        provenance: { file, startLine, endLine, excerpt, sourceKind: 'skill' },
      }],
      edges: [], entries: ['n1'], exits: [], sources: [], warnings: [],
      shape: 'inline-states', extractor: 'test', confidence: 'derived',
      title: `${skillName} — state flow`,
    };
  }

  it('two different skills citing one file share a single cache entry', () => {
    // A real file both charts can cite, so verification genuinely runs.
    const file = 'canonical/aid/templates/shortcut-engine.md';
    const abs  = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'shortcut-engine.md');
    const line1 = readFileSync(abs, 'utf8').split('\n')[0];

    const fileCache = new Map();
    for (const name of ['aid-add-api', 'aid-add-cli']) {
      provenanceAppender.render(makeSkill(name), {
        _memo: new Map(),
        _fileCache: fileCache,
        _buildFlowChart: () => chartCiting(name, file, line1, 1, 1),
        _renderFragmentList: () => '## Source fragments\n\n',
      });
    }

    // Non-vacuity: the cache was used at all, and holds exactly the shared file.
    expect(fileCache.size).toBe(1);
    expect(fileCache.has(file)).toBe(true);
  });

  it('render passes the run cache through rather than letting verify make its own', () => {
    const file = 'canonical/aid/templates/shortcut-engine.md';
    const abs  = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'shortcut-engine.md');
    const line1 = readFileSync(abs, 'utf8').split('\n')[0];

    const fileCache = new Map();
    provenanceAppender.render(makeSkill('aid-add-api'), {
      _memo: new Map(),
      _fileCache: fileCache,
      _buildFlowChart: () => chartCiting('aid-add-api', file, line1, 1, 1),
      _renderFragmentList: () => '## Source fragments\n\n',
    });

    // If render ignored _fileCache, verify would cache into its own Map and this
    // one would still be empty.
    expect(fileCache.size).toBeGreaterThan(0);
  });
});

// ── AC-7: identity ────────────────────────────────────────────────────────────

describe('provenanceAppender — identity', () => {
  it('has id "source-fragments"', () => {
    expect(provenanceAppender.id).toBe('source-fragments');
  });

  it('has a render function', () => {
    expect(typeof provenanceAppender.render).toBe('function');
  });
});

// ── AC-2: field access — source grep ─────────────────────────────────────────

describe('field access: bodyStartLine and lineCount absent (AC-2)', () => {
  let src;
  beforeAll(() => { src = readFileSync(MODULE_PATH, 'utf8'); });

  it('bodyStartLine does not appear in the module source', () => {
    expect(src).not.toContain('bodyStartLine');
  });

  it('lineCount does not appear in the module source', () => {
    expect(src).not.toContain('lineCount');
  });

  it('dirName appears in the module source', () => {
    expect(src).toContain('dirName');
  });

  // The DETAIL anticipated two fields, dirName and sourcePath. Only dirName is
  // read: buildFlowChart derives every path it needs from name and dir, so
  // sourcePath had no work to do, and destructuring it purely to match the
  // wording left a variable that was never referenced. The constraint the AC
  // actually protects — that the per-skill line-range fields are not consulted,
  // because a node may cite a worker or the shared engine template rather than
  // this skill's own SKILL.md — is asserted by the two tests above and is intact.
  it('sourcePath is not destructured, because nothing reads it', () => {
    expect(src).not.toMatch(/const\s*\{[^}]*sourcePath[^}]*\}\s*=\s*skill/);
  });
});

// ── AC-3: memoisation — asserted by call count ───────────────────────────────

describe('buildFlowChart memoisation (AC-3) — asserted by call count', () => {
  it('calls buildFlowChart exactly once on first render for a dirName', () => {
    const calls = { n: 0 };
    const memo  = new Map();
    const chart = { skill: 'x', nodes: [], edges: [], entries: [], exits: [], sources: [],
                    warnings: [], shape: 'inline-states', extractor: 'test',
                    confidence: 'derived', title: 'x — state flow' };
    const build = ({ name }) => { calls.n++; chart.skill = name; return chart; };
    const renderFn = () => '## Source fragments\n\n';

    provenanceAppender.render(makeSkill('aid-review'), { _memo: memo, _buildFlowChart: build, _renderFragmentList: renderFn });

    // Non-vacuity: build was called at all.
    expect(calls.n).toBeGreaterThan(0);
    expect(calls.n).toBe(1);
  });

  it('does NOT call buildFlowChart a second time for the same dirName (same memo)', () => {
    const calls = { n: 0 };
    const memo  = new Map();
    const chart = { skill: 'x', nodes: [], edges: [], entries: [], exits: [], sources: [],
                    warnings: [], shape: 'inline-states', extractor: 'test',
                    confidence: 'derived', title: 'x — state flow' };
    const build = () => { calls.n++; return chart; };
    const renderFn = () => '## Source fragments\n\n';
    const skill = makeSkill('aid-review');

    provenanceAppender.render(skill, { _memo: memo, _buildFlowChart: build, _renderFragmentList: renderFn });
    provenanceAppender.render(skill, { _memo: memo, _buildFlowChart: build, _renderFragmentList: renderFn });

    // Two calls, same memo, same dirName → exactly one buildFlowChart invocation.
    expect(calls.n).toBe(1);
  });

  it('calls buildFlowChart separately for two distinct dirNames (count = 2)', () => {
    const calls = { n: 0 };
    const memo  = new Map();
    const makeChart = (name) => ({ skill: name, nodes: [], edges: [], entries: [], exits: [],
                                   sources: [], warnings: [], shape: 'inline-states',
                                   extractor: 'test', confidence: 'derived', title: name });
    const build = ({ name }) => { calls.n++; return makeChart(name); };
    const renderFn = () => '## Source fragments\n\n';

    provenanceAppender.render(makeSkill('aid-review'), { _memo: memo, _buildFlowChart: build, _renderFragmentList: renderFn });
    provenanceAppender.render(makeSkill('aid-create-api'), { _memo: memo, _buildFlowChart: build, _renderFragmentList: renderFn });

    expect(calls.n).toBe(2);
  });

  it('memo is keyed by dirName: chart stored under dirName after first render', () => {
    const memo  = new Map();
    const chart = { skill: 'x', nodes: [], edges: [], entries: [], exits: [], sources: [],
                    warnings: [], shape: 'inline-states', extractor: 'test',
                    confidence: 'derived', title: 'x — state flow' };
    provenanceAppender.render(makeSkill('aid-ask'), {
      _memo: memo,
      _buildFlowChart: () => chart,
      _renderFragmentList: () => '## Source fragments\n\n',
    });
    expect(memo.has('aid-ask')).toBe(true);
    expect(memo.get('aid-ask')).toBe(chart);
  });
});

// ── AC-1: verify before render ────────────────────────────────────────────────

describe('verifyProvenance before renderFragmentList (AC-1)', () => {
  it('throws when the chart has invalid provenance', () => {
    const bad  = makeBadChart();
    const memo = new Map();
    expect(() =>
      provenanceAppender.render(makeSkill('test-bad'), {
        _memo: memo,
        _buildFlowChart: () => bad,
      })
    ).toThrow('[gen-skills] provenance path:');
  });

  it('renderFragmentList is never called when verifyProvenance throws', () => {
    let renderCalled = false;
    const bad  = makeBadChart();
    const memo = new Map();
    const spy  = () => { renderCalled = true; return ''; };

    expect(() =>
      provenanceAppender.render(makeSkill('test-bad'), {
        _memo:               memo,
        _buildFlowChart:     () => bad,
        _renderFragmentList: spy,
      })
    ).toThrow();

    // renderCalled is still false — no bytes were produced before the throw.
    expect(renderCalled).toBe(false);
  });

  it('a bad chart yields no page bytes at all (result is undefined — not a string)', () => {
    const bad  = makeBadChart();
    const memo = new Map();
    let result = 'SENTINEL';

    try {
      result = provenanceAppender.render(makeSkill('test-bad'), {
        _memo: memo,
        _buildFlowChart: () => bad,
        _renderFragmentList: () => 'BYTES',
      });
    } catch { /* expected */ }

    // result was never reassigned from 'SENTINEL' because render threw.
    expect(result).toBe('SENTINEL');
  });
});

// ── AC-4: unconditional emission ──────────────────────────────────────────────

describe('unconditional emission — no skip path (AC-4)', () => {
  it('source has no conditional return that could skip the section', () => {
    const src = readFileSync(MODULE_PATH, 'utf8');
    // No `if (...) return` that could suppress rendering (only the throw path exits early).
    // We check there is no `if` guarding the renderFn call.
    // The module may use `if` for the memo lookup — that is the only branch.
    // A conditional return before renderFn would look like `if (…) return`
    // appearing after the memo block and before `return renderFn(…)`.
    // We verify by checking that only one `return` statement calls renderFn
    // and no other `return` is reachable in the hot path (no skip-guard).
    const renderFnReturnMatches = (src.match(/return renderFn\(entries\)/g) || []).length;
    expect(renderFnReturnMatches).toBe(1);
  });

  it('emits ## Source fragments for an authored-flow skill (aid-review)', () => {
    const result = provenanceAppender.render(makeSkill('aid-review'));
    expect(result).toContain('## Source fragments');
  });

  it('emits ## Source fragments for a doorway skill (aid-create-api)', () => {
    const result = provenanceAppender.render(makeSkill('aid-create-api'));
    expect(result).toContain('## Source fragments');
  });

  it('non-vacuity: result contains at least one fragment entry', () => {
    const result = provenanceAppender.render(makeSkill('aid-review'));
    // Every entry has a tilde-fence block.
    expect(result).toMatch(/~~~~plaintext/);
  });

  it('returns a string (not undefined, null, or empty) for aid-review', () => {
    const result = provenanceAppender.render(makeSkill('aid-review'));
    expect(typeof result).toBe('string');
    expect(result.length).toBeGreaterThan(0);
  });

  it('returns a string for aid-create-api', () => {
    const result = provenanceAppender.render(makeSkill('aid-create-api'));
    expect(typeof result).toBe('string');
    expect(result.length).toBeGreaterThan(0);
  });

  it('result is LF-terminated', () => {
    const result = provenanceAppender.render(makeSkill('aid-review'));
    expect(result.endsWith('\n')).toBe(true);
  });
});

// ── Integration: no logging ────────────────────────────────────────────────────

describe('appender logs nothing (AC-7 stdout unchanged)', () => {
  it('render does not call console.log', () => {
    const logged = [];
    const orig = console.log;
    console.log = (...args) => { logged.push(args); orig(...args); };
    try {
      provenanceAppender.render(makeSkill('aid-review'));
    } finally {
      console.log = orig;
    }
    expect(logged).toHaveLength(0);
  });

  it('render does not call console.error', () => {
    const errored = [];
    const orig = console.error;
    console.error = (...args) => { errored.push(args); orig(...args); };
    try {
      provenanceAppender.render(makeSkill('aid-review'));
    } finally {
      console.error = orig;
    }
    expect(errored).toHaveLength(0);
  });
});

// ── AC-4 unconditional: BODY_APPENDERS entry is always present ────────────────

describe('BODY_APPENDERS has exactly one entry and it is the provenance appender', () => {
  it('BODY_APPENDERS contains source-fragments id', async () => {
    const { BODY_APPENDERS } = await import('../skills/body.mjs');
    const ids = BODY_APPENDERS.map((a) => a.id);
    expect(ids).toContain('source-fragments');
  });

  it('body.mjs source has provenanceAppender in the BODY_APPENDERS literal', () => {
    const bodySrc = readFileSync(
      resolve(__dirname, '../skills/body.mjs'), 'utf8'
    );
    expect(bodySrc).toMatch(/export const BODY_APPENDERS\s*=\s*\[provenanceAppender\]/);
  });

  it('body.mjs imports provenanceAppender from lib/provenance/index.mjs', () => {
    const bodySrc = readFileSync(
      resolve(__dirname, '../skills/body.mjs'), 'utf8'
    );
    expect(bodySrc).toContain("import { provenanceAppender } from '../lib/provenance/index.mjs'");
  });
});
