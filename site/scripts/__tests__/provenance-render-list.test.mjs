// provenance-render-list.test.mjs — Unit tests for lib/provenance/render-list.mjs
//
// Format is specified by feature-005/SPEC.md § Entry anatomy (the fenced example
// and element table are authoritative).
//
// Coverage (per DETAIL.md acceptance criteria):
//   AC-1  buildEntries returns exactly one entry per node in chart.nodes array
//         order, with no re-sort and no de-duplication (two nodes same range).
//   AC-2  Fence width is max(4, 1+longest leading-tilde run): both arms tested
//         with inputs that only each arm explains, including boundary at ~~~.
//   AC-3  Every emitted fence carries title="<file><anchor>" (before wrap) and
//         bare `wrap` flag, language `plaintext` — asserted on every fence in
//         multi-node output.
//   AC-4  Fragment round-trips byte-for-byte: fence body extracted and asserted
//         equal to input.  Hostile chars covered: backticks (4-run), pipes,
//         <div>, {braces}, complete fenced code block, leading-tab line, line
//         starting with #.
//   AC-5  Every entry's three blocks start at column 0; output contains no
//         markdown ordered-list markers wrapping a fence.
//   AC-6  Anchor <a id="fragment-<nodeId>"></a> is on the same line as the
//         lead-in text, not standing alone.
//   AC-7  ## Source fragments heading is H2; intro sentence matches SPEC wording
//         exactly (contains no count); no count literal in the module source.
//   AC-8  Exit marker renders only when terminal is set, reading advanceType;
//         handoff, edges, and edge conditions are not rendered (if-and-only-if,
//         dedicated tests — M6 proof).
//   AC-9  [Source: `…`] and optional [full step: `…`] on one line (if-and-only-if,
//         dedicated tests — M8 proof).
//   AC-10 Label escaper applies its full character set; kind and advanceType pass
//         through unescaped; name fallback covers backtick-containing names.
//   AC-11 renderFragmentList called twice on the same entries returns identical
//         strings; output is LF-terminated with no os.EOL.
//   AC-12 All unit tests pass; existing tests unaffected; build passes.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, it, expect } from 'vitest';
import {
  makeProvenance,
  makeNode,
  makeEdge,
  buildChart,
} from '../lib/flow-graph/model.mjs';
import { buildEntries, renderFragmentList } from '../lib/provenance/render-list.mjs';

// ── Shared fixture helpers ────────────────────────────────────────────────────

function prov(file, startLine, endLine, excerpt = `line ${startLine}\nline ${startLine + 1}`) {
  return makeProvenance({ file, startLine, endLine, sourceKind: 'skill', excerpt });
}

const DEFAULT_FILE = 'canonical/skills/aid-test/SKILL.md';
const DEFAULT_PROV = prov(DEFAULT_FILE, 1, 2);

function rawNode(order, name, { label = name, terminal = null, detail = null, excerpt } = {}) {
  const p = excerpt !== undefined
    ? prov(DEFAULT_FILE, order, order + 1, excerpt)
    : DEFAULT_PROV;
  return makeNode({ order, name, label, provenance: p, terminal, detail });
}

function halt() { return { advanceType: 'HALT', handoff: null }; }
function pause() { return { advanceType: 'PAUSE-FOR-USER-ACTION', handoff: 'Some instruction' }; }

function rawEdge(from, to, condition = null) {
  return makeEdge({ from, to, kind: 'sequence', condition, advanceType: 'CHAIN', provenance: DEFAULT_PROV });
}

function makeChart(rawNodes, rawEdges = []) {
  return buildChart({
    skill: 'aid-fixture',
    shape: 'inline-states',
    extractor: 'extract-inline',
    confidence: 'derived',
    nodes: rawNodes,
    edges: rawEdges,
    sources: [DEFAULT_FILE],
  });
}

// ── Fence-body extractor ──────────────────────────────────────────────────────

/**
 * Extract the verbatim body of the tilde-fenced block whose info string
 * contains `markerSubstring` from `rendered`.
 *
 * Finds the opening fence line (contains markerSubstring), counts its leading
 * tildes, then finds the closing line of exactly those tildes.
 * Returns the lines between them joined with '\n'.
 */
function extractFenceBody(rendered, markerSubstring) {
  const lines = rendered.split('\n');
  const openIdx = lines.findIndex(l => l.includes(markerSubstring));
  if (openIdx === -1) {
    throw new Error('extractFenceBody: opening fence not found for marker: ' + markerSubstring);
  }
  const tileMatch = lines[openIdx].match(/^(~+)/);
  if (!tileMatch) {
    throw new Error('extractFenceBody: opening line is not a tilde fence: ' + lines[openIdx]);
  }
  const tildes = tileMatch[1];
  const closeIdx = lines.findIndex((l, idx) => idx > openIdx && l === tildes);
  if (closeIdx === -1) {
    throw new Error('extractFenceBody: closing fence not found');
  }
  return lines.slice(openIdx + 1, closeIdx).join('\n');
}

// ── AC-1: buildEntries — order, no sort, no dedup ────────────────────────────

describe('buildEntries — array order preserved', () => {
  it('returns exactly one entry per node', () => {
    const chart = makeChart([
      rawNode(1, 'ALPHA'),
      rawNode(2, 'BETA'),
      rawNode(3, 'GAMMA'),
    ], [rawEdge('n1', 'n2'), rawEdge('n2', 'n3')]);
    const entries = buildEntries(chart);
    expect(entries).toHaveLength(3);
    expect(entries.map(e => e.name)).toEqual(['ALPHA', 'BETA', 'GAMMA']);
  });

  it('entry ids match chart.nodes in array order', () => {
    const chart = makeChart([rawNode(1, 'FIRST'), rawNode(2, 'SECOND')], [rawEdge('n1', 'n2')]);
    const entries = buildEntries(chart);
    expect(entries[0].id).toBe('n1');
    expect(entries[1].id).toBe('n2');
  });

  it('does not re-sort: entries stay in the same object order as chart.nodes', () => {
    const chart = makeChart([rawNode(1, 'A'), rawNode(2, 'B')], [rawEdge('n1', 'n2')]);
    const entries = buildEntries(chart);
    for (let i = 0; i < entries.length; i++) {
      expect(entries[i]).toBe(chart.nodes[i]);
    }
  });

  it('no de-duplication: two nodes citing the same range both appear', () => {
    const sharedProv = prov(DEFAULT_FILE, 10, 15);
    const n1 = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: sharedProv });
    const n2 = makeNode({ order: 2, name: 'BETA',  label: 'BETA',  provenance: sharedProv });
    const chart = makeChart([n1, n2], [rawEdge('n1', 'n2')]);
    const entries = buildEntries(chart);
    expect(entries).toHaveLength(2);
    expect(entries[0].name).toBe('ALPHA');
    expect(entries[1].name).toBe('BETA');
  });

  it('empty chart produces empty entries', () => {
    const entries = buildEntries({ nodes: [] });
    expect(entries).toHaveLength(0);
  });
});

// ── AC-2: fence width — both arms ────────────────────────────────────────────

describe('fenceWidth arm 1: floor (no tildes → width 4)', () => {
  it('fragment with no tildes at line start uses the floor of 4', () => {
    const chart = makeChart([rawNode(1, 'ALPHA', { excerpt: 'no tildes here\nline two' })]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toMatch(/^~~~~plaintext/m);
    expect(rendered).not.toMatch(/^~~~~~plaintext/m);
  });

  it('fragment with leading ~~~ (3 tildes) stays at floor 4', () => {
    const chart = makeChart([rawNode(1, 'ALPHA', { excerpt: '~~~\nsome content' })]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toMatch(/^~~~~plaintext/m);
    expect(rendered).not.toMatch(/^~~~~~plaintext/m);
  });
});

describe('fenceWidth arm 2: 1 + longest run (~~~~ → width 5)', () => {
  it('fragment with ~~~~ at column 0 forces a 5-tilde fence', () => {
    const chart = makeChart([rawNode(1, 'ALPHA', { excerpt: '~~~~\nsome content' })]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toMatch(/^~~~~~plaintext/m);
    expect(rendered).not.toMatch(/^~~~~~~plaintext/m);
  });

  it('non-vacuity: 5-tilde fence closes with exactly 5 tildes', () => {
    const chart = makeChart([rawNode(1, 'ALPHA', { excerpt: '~~~~\nsome content' })]);
    const rendered = renderFragmentList(buildEntries(chart));
    const closingFenceLines = rendered.split('\n').filter(l => /^~{5}$/.test(l));
    expect(closingFenceLines).toHaveLength(1);
  });

  it('fragment with ~~~~~ (5 tildes) forces a 6-tilde fence', () => {
    const chart = makeChart([rawNode(1, 'ALPHA', { excerpt: '~~~~~\nsome content' })]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toMatch(/^~~~~~~plaintext/m);
  });
});

// ── AC-3: fence carries title= (before wrap) and plaintext on every fence ────

describe('fence attributes: title= before wrap, plaintext on every fence', () => {
  it('single node: fence info string is plaintext title="..." wrap', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const rendered = renderFragmentList(buildEntries(chart));
    // title= appears before wrap
    expect(rendered).toContain('~~~~plaintext title="');
    expect(rendered).not.toContain('~~~~plaintext wrap title=');
  });

  it('title= appears before wrap in the fence info string', () => {
    const file = DEFAULT_FILE;
    const n = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: prov(file, 5, 10) });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    const fenceLine = rendered.split('\n').find(l => /^~~~~plaintext/.test(l));
    expect(fenceLine).toBeDefined();
    const titleIdx = fenceLine.indexOf('title=');
    const wrapIdx = fenceLine.indexOf(' wrap');
    expect(titleIdx).toBeLessThan(wrapIdx);
  });

  it('multi-node: ALL fences carry title= (asserted on each)', () => {
    const chart = makeChart(
      [rawNode(1, 'A'), rawNode(2, 'B'), rawNode(3, 'C')],
      [rawEdge('n1', 'n2'), rawEdge('n2', 'n3')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    const fenceLines = rendered.split('\n').filter(l => /^~~~~/.test(l) && l.includes('plaintext'));
    expect(fenceLines).toHaveLength(3);
    for (const fenceLine of fenceLines) {
      expect(fenceLine).toContain('title="');
      expect(fenceLine).toContain(' wrap');
      // title= must come before wrap in every fence
      expect(fenceLine.indexOf('title=')).toBeLessThan(fenceLine.indexOf(' wrap'));
    }
  });

  it('title value is file + anchor: file#L<start>-L<end>', () => {
    const file = 'canonical/skills/aid-test/SKILL.md';
    const n = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: prov(file, 5, 10) });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain(`title="${file}#L5-L10"`);
  });

  it('single-line provenance produces #L<n> anchor in title', () => {
    const file = 'canonical/skills/aid-test/SKILL.md';
    const n = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: prov(file, 7, 7) });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain(`title="${file}#L7"`);
  });
});

// ── AC-4: byte-exact round-trip ───────────────────────────────────────────────

describe('byte-exact round-trip: hostile characters survive unaltered', () => {
  // Hostile fragment covers all required characters:
  //   line starting with #, backticks (4-run), pipe, <div>, {braces},
  //   complete fenced code block, leading-tab line.
  const HOSTILE = [
    '# State: ACTIVE',
    '`inline code` and ````four-backtick run````',
    '| pipe | cell |',
    '<div class="outer">content</div>',
    '{key: value, other: 42}',
    '```js',
    'const x = 1;',
    '```',
    '\ttab-indented line',
  ].join('\n');

  it('round-trip: extracted fence body equals input fragment exactly', () => {
    const file = 'canonical/skills/aid-test/SKILL.md';
    const n = makeNode({
      order: 1,
      name: 'HOSTILE',
      label: 'hostile fragment',
      provenance: prov(file, 1, 9, HOSTILE),
    });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    // Extract via title= marker — still present in new fence meta order.
    const body = extractFenceBody(rendered, `title="${file}#L1-L9"`);
    expect(body).toBe(HOSTILE);
  });

  it('round-trip non-vacuity: body is non-empty and contains all hostile lines', () => {
    const file = 'canonical/skills/aid-test/SKILL.md';
    const n = makeNode({
      order: 1,
      name: 'HOSTILE',
      label: 'hostile fragment',
      provenance: prov(file, 1, 9, HOSTILE),
    });
    const rendered = renderFragmentList(buildEntries(makeChart([n])));
    const body = extractFenceBody(rendered, `title="${file}#L1-L9"`);
    expect(body.length).toBeGreaterThan(0);
    expect(body).toContain('# State: ACTIVE');
    expect(body).toContain('````four-backtick run````');
    expect(body).toContain('| pipe | cell |');
    expect(body).toContain('<div class="outer">');
    expect(body).toContain('{key: value');
    expect(body).toContain('```js');
    expect(body).toContain('\ttab-indented line');
  });

  it('backtick 4-run is unescaped inside the fence', () => {
    const excerpt = '````four backticks at start````';
    const n = makeNode({ order: 1, name: 'BACK', label: 'backtick test', provenance: prov(DEFAULT_FILE, 1, 1, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });

  it('pipe inside fragment is unescaped', () => {
    const excerpt = '| col1 | col2 |';
    const n = makeNode({ order: 1, name: 'PIPE', label: 'pipe test', provenance: prov(DEFAULT_FILE, 1, 1, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });

  it('<div> inside fragment is unescaped', () => {
    const excerpt = '<div class="foo">bar</div>';
    const n = makeNode({ order: 1, name: 'HTML', label: 'html test', provenance: prov(DEFAULT_FILE, 1, 1, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });

  it('line starting with # is unescaped inside fence', () => {
    const excerpt = '# Heading inside fragment\nnormal line';
    const n = makeNode({ order: 1, name: 'HASH', label: 'hash test', provenance: prov(DEFAULT_FILE, 1, 2, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });

  it('complete inner fenced code block is unescaped', () => {
    const excerpt = '```js\nconst x = 1;\n```';
    const n = makeNode({ order: 1, name: 'FENCE', label: 'fence-in-fence', provenance: prov(DEFAULT_FILE, 1, 3, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });

  it('leading-tab line is unescaped', () => {
    const excerpt = '\ttab at start\nnormal line';
    const n = makeNode({ order: 1, name: 'TAB', label: 'tab test', provenance: prov(DEFAULT_FILE, 1, 2, excerpt) });
    const body = extractFenceBody(renderFragmentList(buildEntries(makeChart([n]))), 'title="');
    expect(body).toBe(excerpt);
  });
});

// ── AC-5: column 0, no ordered-list markers ───────────────────────────────────

describe('column 0: no ordered-list markers wrapping a fence', () => {
  it('opening fence lines start at column 0', () => {
    const chart = makeChart([rawNode(1, 'A'), rawNode(2, 'B')], [rawEdge('n1', 'n2')]);
    const fenceLines = renderFragmentList(buildEntries(chart))
      .split('\n').filter(l => /^~+plaintext/.test(l));
    expect(fenceLines).toHaveLength(2);
    for (const fl of fenceLines) expect(fl.charAt(0)).toBe('~');
  });

  it('closing fence lines start at column 0', () => {
    const chart = makeChart([rawNode(1, 'A'), rawNode(2, 'B')], [rawEdge('n1', 'n2')]);
    const closingLines = renderFragmentList(buildEntries(chart))
      .split('\n').filter(l => /^~+$/.test(l));
    expect(closingLines).toHaveLength(2);
    for (const cl of closingLines) expect(cl.charAt(0)).toBe('~');
  });

  it('no markdown ordered-list markers appear before a fence', () => {
    const chart = makeChart(
      [rawNode(1, 'A'), rawNode(2, 'B'), rawNode(3, 'C')],
      [rawEdge('n1', 'n2'), rawEdge('n2', 'n3')],
    );
    const lines = renderFragmentList(buildEntries(chart)).split('\n');
    for (let i = 0; i < lines.length; i++) {
      if (/^~+plaintext/.test(lines[i]) && i > 0) {
        expect(lines[i - 1]).not.toMatch(/^\d+\.\s/);
      }
    }
  });
});

// ── AC-6: anchor on same line as lead-in text ────────────────────────────────

describe('anchor <a id="fragment-<nodeId>"></a> is inline with lead-in text', () => {
  it('anchor and lead-in text appear on the same line', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const anchorLine = renderFragmentList(buildEntries(chart))
      .split('\n').find(l => l.includes('<a id="fragment-n1">'));
    expect(anchorLine).toBeDefined();
    expect(anchorLine).toContain('`ALPHA`');
  });

  it('anchor is NOT on a line by itself', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const standaloneAnchorLine = renderFragmentList(buildEntries(chart))
      .split('\n').find(l => /^<a id="fragment-[^"]+"><\/a>\s*$/.test(l));
    expect(standaloneAnchorLine).toBeUndefined();
  });

  it('each node has its own anchor id', () => {
    const chart = makeChart([rawNode(1, 'A'), rawNode(2, 'B')], [rawEdge('n1', 'n2')]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain('<a id="fragment-n1"></a>');
    expect(rendered).toContain('<a id="fragment-n2"></a>');
  });
});

// ── AC-7: H2 heading, exact intro wording, no count ───────────────────────────

describe('## Source fragments heading and intro sentence', () => {
  it('section heading is H2', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toMatch(/^## Source fragments$/m);
    expect(rendered).not.toMatch(/^# Source fragments$/m);
    expect(rendered).not.toMatch(/^### Source fragments$/m);
  });

  it('intro sentence matches SPEC wording exactly', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const rendered = renderFragmentList(buildEntries(chart));
    const introLine = rendered.split('\n')[2];
    expect(introLine).toBe(
      'Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.'
    );
  });

  it('intro sentence contains no count literal', () => {
    const chart = makeChart(
      [rawNode(1, 'A'), rawNode(2, 'B'), rawNode(3, 'C')],
      [rawEdge('n1', 'n2'), rawEdge('n2', 'n3')],
    );
    const introLine = renderFragmentList(buildEntries(chart)).split('\n')[2];
    expect(introLine).not.toMatch(/\d/);
  });

  it('no count literal in the module source (push string literals checked)', () => {
    const dir = dirname(fileURLToPath(import.meta.url));
    const modulePath = resolve(dir, '../lib/provenance/render-list.mjs');
    const src = readFileSync(modulePath, 'utf8');
    const pushArgs = [...src.matchAll(/parts\.push\('([^']*)'\)/g)].map(m => m[1]);
    for (const arg of pushArgs) {
      expect(arg).not.toMatch(/\b\d+\s+(fragment|entry|entries|node|count)\b/i);
    }
  });
});

// ── AC-8: exit marker — if-and-only-if (M6 proof) ───────────────────────────

describe('exit marker: conditional on terminal (M6 proof — if-and-only-if)', () => {
  // M6-proof: uses a chart with ONLY exit nodes so the terminal===null inversion
  // does not cause a null-dereference crash — it causes a behavioral failure
  // (marker absent when it should be present), which is the dedicated evidence.
  it('M6 proof — exit marker IS present when terminal is set', () => {
    // Single-node chart: buildChart fallback makes the one node an exit node.
    const chart = makeChart([rawNode(1, 'ALONE', { terminal: halt() })]);
    const rendered = renderFragmentList(buildEntries(chart));
    const leadIn = rendered.split('\n').find(l => l.includes('`ALONE`'));
    expect(leadIn).toBeDefined();
    expect(leadIn).toContain('HALT');
  });

  it('M6 proof — no exit marker when terminal is null', () => {
    const chart = makeChart(
      [rawNode(1, 'ENTRY'), rawNode(2, 'EXIT', { terminal: halt() })],
      [rawEdge('n1', 'n2')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    const entryLine = rendered.split('\n').find(l => l.includes('`ENTRY`'));
    expect(entryLine).toBeDefined();
    expect(entryLine).not.toContain('HALT');
    expect(entryLine).not.toContain('advanceType');
  });

  it('PAUSE-FOR-USER-ACTION appears when terminal carries that advanceType', () => {
    const chart = makeChart(
      [rawNode(1, 'START'), rawNode(2, 'PAUSE', { terminal: pause() })],
      [rawEdge('n1', 'n2')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    const pauseLine = rendered.split('\n').find(l => l.includes('`PAUSE`'));
    expect(pauseLine).toBeDefined();
    expect(pauseLine).toContain('PAUSE-FOR-USER-ACTION');
  });

  it('handoff text is NOT rendered anywhere in output', () => {
    const handoffText = 'UNIQUE-HANDOFF-MARKER-XYZ';
    const term = { advanceType: 'HALT', handoff: handoffText };
    const chart = makeChart(
      [rawNode(1, 'ENTRY'), rawNode(2, 'EXIT', { terminal: term })],
      [rawEdge('n1', 'n2')],
    );
    expect(renderFragmentList(buildEntries(chart))).not.toContain(handoffText);
  });

  it('outgoing edge conditions are NOT rendered', () => {
    const conditionText = 'UNIQUE-EDGE-CONDITION-ZZZ';
    const n1 = rawNode(1, 'A');
    const n2 = rawNode(2, 'B');
    const n3 = rawNode(3, 'C', { terminal: halt() });
    const e1 = makeEdge({ from: 'n1', to: 'n2', kind: 'branch', condition: conditionText, advanceType: 'CHAIN', provenance: DEFAULT_PROV });
    const chart = makeChart([n1, n2, n3], [e1, rawEdge('n2', 'n3')]);
    expect(renderFragmentList(buildEntries(chart))).not.toContain(conditionText);
  });
});

// ── AC-9: Source link and detail link — if-and-only-if (M8 proof) ────────────

describe('[Source:] and [full step:] links: if-and-only-if (M8 proof)', () => {
  // M8-proof: uses a chart with ONLY a non-null detail so the detail===null
  // inversion does not crash — it causes a behavioral failure (link absent).
  it('M8 proof — [full step:] IS present when detail is set', () => {
    const detailProv = prov(DEFAULT_FILE, 1, 50);
    const n = makeNode({
      order: 1,
      name: 'ALPHA',
      label: 'ALPHA',
      provenance: DEFAULT_PROV,
      detail: detailProv,
    });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain('[full step:');
  });

  it('M8 proof — no [full step:] when detail is null', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    expect(renderFragmentList(buildEntries(chart))).not.toContain('[full step:');
  });

  it('[Source:] link uses code span: [Source: `file#anchor`](url)', () => {
    const file = DEFAULT_FILE;
    const n = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: prov(file, 1, 5) });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain('[Source: `' + file + '#L1-L5`]');
  });

  it('[Source:] and [full step:] are on ONE line joined by ` · `', () => {
    const detailProv = prov('canonical/skills/aid-test/SKILL.md', 1, 50);
    const n = makeNode({
      order: 1,
      name: 'ALPHA',
      label: 'ALPHA',
      provenance: DEFAULT_PROV,
      detail: detailProv,
    });
    const chart = makeChart([n]);
    const rendered = renderFragmentList(buildEntries(chart));
    // Both must appear on the SAME line.
    const linkLine = rendered.split('\n').find(l => l.startsWith('[Source:'));
    expect(linkLine).toBeDefined();
    expect(linkLine).toContain('[Source:');
    expect(linkLine).toContain(' · [full step:');
    // Not two separate lines.
    const lines = rendered.split('\n');
    const sourceIdx = lines.findIndex(l => l.startsWith('[Source:'));
    const fullStepIdx = lines.findIndex(l => l.includes('[full step:'));
    expect(sourceIdx).toBe(fullStepIdx);
  });

  it('detail link uses code span: [full step: `file#anchor`](url)', () => {
    const detailFile = 'canonical/skills/aid-test/SKILL.md';
    const detailProv = prov(detailFile, 1, 50);
    const n = makeNode({
      order: 1,
      name: 'ALPHA',
      label: 'ALPHA',
      provenance: DEFAULT_PROV,
      detail: detailProv,
    });
    const rendered = renderFragmentList(buildEntries(makeChart([n])));
    expect(rendered).toContain('[full step: `' + detailFile + '#L1-L50`]');
  });

  it('detail excerpt is NOT inlined in the output', () => {
    const detailExcerpt = 'UNIQUE-DETAIL-EXCERPT-CONTENT';
    const detailProv = makeProvenance({
      file: DEFAULT_FILE, startLine: 1, endLine: 50,
      sourceKind: 'skill', excerpt: detailExcerpt,
    });
    const n = makeNode({ order: 1, name: 'ALPHA', label: 'ALPHA', provenance: DEFAULT_PROV, detail: detailProv });
    const rendered = renderFragmentList(buildEntries(makeChart([n])));
    expect(rendered).not.toContain(detailExcerpt);
    expect(rendered).toContain('[full step:');
  });
});

// ── AC-10: label escaper, kind/advanceType unescaped, name fallback ───────────

describe('label escaper: full character set applied', () => {
  it('& is replaced with &amp;', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'foo & bar', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('&amp;');
    expect(leadIn).not.toMatch(/foo & bar/);
  });

  it('< is replaced with &lt;', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'a < b', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('&lt;');
    expect(leadIn).not.toMatch(/a < b/);
  });

  it('backtick in label is backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'use `cmd`', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('\\`cmd\\`');
  });

  it('* in label is backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'a * b', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('\\*');
  });

  it('_ in label is backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'under_score', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('under\\_score');
  });

  it('[ and ] in label are backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: '[item]', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('\\[item\\]');
  });

  it('\\ in label is backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'a\\b', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('a\\\\b');
  });

  it('| in label is backslash-escaped', () => {
    const n = makeNode({ order: 1, name: 'X', label: 'a | b', provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('a \\| b');
  });

  it('kind passes through unescaped (in italic markers)', () => {
    // Two-node chain: n1 gets kind='entry', n2 gets kind='exit'.
    const chart = makeChart(
      [rawNode(1, 'ALPHA'), rawNode(2, 'OMEGA', { terminal: halt() })],
      [rawEdge('n1', 'n2')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    const alphaLine = rendered.split('\n').find(l => l.includes('`ALPHA`'));
    expect(alphaLine).toBeDefined();
    // kind 'entry' appears inside _..._
    expect(alphaLine).toContain('· _entry_');
  });

  it('advanceType passes through unescaped', () => {
    const term = { advanceType: 'PAUSE-FOR-USER-ACTION', handoff: null };
    const chart = makeChart(
      [rawNode(1, 'S'), rawNode(2, 'E', { terminal: term })],
      [rawEdge('n1', 'n2')],
    );
    const exitLine = renderFragmentList(buildEntries(chart)).split('\n').find(l => l.includes('`E`'));
    expect(exitLine).toContain('· PAUSE-FOR-USER-ACTION');
    expect(exitLine).not.toContain('\\-');
  });

  it('label with all special chars: &, <, `, *, _, [, ], \\, |', () => {
    const raw = '& < `x` * _y_ [z] \\ | end';
    const n = makeNode({ order: 1, name: 'X', label: raw, provenance: DEFAULT_PROV });
    const leadIn = renderFragmentList(buildEntries(makeChart([n]))).split('\n').find(l => l.includes('`X`'));
    expect(leadIn).toContain('&amp;');
    expect(leadIn).toContain('&lt;');
    expect(leadIn).toContain('\\`x\\`');
    expect(leadIn).toContain('\\*');
    expect(leadIn).toContain('\\_y\\_');
    expect(leadIn).toContain('\\[z\\]');
    expect(leadIn).toContain('\\\\');
    expect(leadIn).toContain('\\|');
  });
});

describe('name span: code span for clean names, escaped plain text fallback', () => {
  it('name without backtick renders as code span in bold', () => {
    const chart = makeChart([rawNode(1, 'CONTINUE')]);
    const rendered = renderFragmentList(buildEntries(chart));
    const leadIn = rendered.split('\n').find(l => l.includes('`CONTINUE`'));
    expect(leadIn).toBeDefined();
    // Bold span contains backtick-delimited name
    expect(leadIn).toContain('**1 · `CONTINUE`**');
  });

  it('name containing a backtick falls back to escaped plain text (no code span)', () => {
    // Node with a backtick in the name — inject directly to bypass buildChart normalisation.
    const backtickName = 'FOO`BAR';
    const entry = {
      id: 'n1',
      order: 1,
      name: backtickName,
      label: 'test',
      kind: 'step',
      terminal: null,
      provenance: DEFAULT_PROV,
      detail: null,
    };
    const rendered = renderFragmentList([entry]);
    const leadIn = rendered.split('\n').find(l => l.includes('FOO'));
    expect(leadIn).toBeDefined();
    // Must NOT wrap in a bare code span that breaks on the embedded backtick.
    expect(leadIn).not.toContain('`FOO`BAR`');
    // Must contain the escaped form.
    expect(leadIn).toContain('FOO\\`BAR');
  });
});

// ── AC-11: idempotency and LF-only ───────────────────────────────────────────

describe('renderFragmentList: determinism and LF-only output', () => {
  it('calling twice on the same entries returns identical strings', () => {
    const chart = makeChart([rawNode(1, 'A'), rawNode(2, 'B')], [rawEdge('n1', 'n2')]);
    const entries = buildEntries(chart);
    expect(renderFragmentList(entries)).toBe(renderFragmentList(entries));
  });

  it('output is LF-terminated', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered.endsWith('\n')).toBe(true);
  });

  it('output contains no CRLF sequences', () => {
    const chart = makeChart([rawNode(1, 'ALPHA')]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).not.toContain('\r\n');
    expect(rendered).not.toContain('\r');
  });

  it('empty entries list renders only the heading and intro, LF-terminated', () => {
    const rendered = renderFragmentList([]);
    expect(rendered).toMatch(/^## Source fragments\n/);
    expect(rendered.endsWith('\n')).toBe(true);
  });
});

// ── Lead-in shape (SPEC: **order · `name`** — label · _kind_) ────────────────

describe('lead-in shape: bold span, italic kind, position from node.order', () => {
  it('lead-in bold span is: **<order> · `<name>`**', () => {
    const chart = makeChart([rawNode(1, 'CONTINUE')]);
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain('**1 · `CONTINUE`**');
  });

  it('kind is wrapped in italic markers: · _<kind>_', () => {
    const chart = makeChart(
      [rawNode(1, 'START'), rawNode(2, 'END', { terminal: halt() })],
      [rawEdge('n1', 'n2')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    // entry node: _entry_
    expect(rendered).toContain('· _entry_');
    // exit node: _exit_
    expect(rendered).toContain('· _exit_');
  });

  it('exit marker appears after italic kind, outside italic', () => {
    const chart = makeChart(
      [rawNode(1, 'START'), rawNode(2, 'END', { terminal: halt() })],
      [rawEdge('n1', 'n2')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    const exitLine = rendered.split('\n').find(l => l.includes('`END`'));
    // _exit_ followed by exit marker outside the italic span
    expect(exitLine).toContain('_exit_ · HALT');
    // Must NOT have HALT inside the italic: _exit · HALT_
    expect(exitLine).not.toContain('_exit · HALT_');
  });

  it('position uses node.order (not loop index): order=5 produces **5 ·', () => {
    // Inject a node with order=5 directly — not via buildChart so loop index ≠ order.
    const entry = {
      id: 'n5',
      order: 5,
      name: 'SOLO',
      label: 'solo',
      kind: 'step',
      terminal: null,
      provenance: DEFAULT_PROV,
      detail: null,
    };
    const rendered = renderFragmentList([entry]);
    // Loop index (0-based) + 1 would give **1 ·
    // node.order gives **5 ·
    expect(rendered).toContain('**5 ·');
    expect(rendered).not.toContain('**1 ·');
  });

  it('position numbering in a normal chart: 1, 2, 3 from node.order', () => {
    const chart = makeChart(
      [rawNode(1, 'FIRST'), rawNode(2, 'SECOND'), rawNode(3, 'THIRD')],
      [rawEdge('n1', 'n2'), rawEdge('n2', 'n3')],
    );
    const rendered = renderFragmentList(buildEntries(chart));
    expect(rendered).toContain('**1 ·');
    expect(rendered).toContain('**2 ·');
    expect(rendered).toContain('**3 ·');
  });

  it('position 1 belongs to the first node in entries array', () => {
    const chart = makeChart([rawNode(1, 'FIRST'), rawNode(2, 'SECOND')], [rawEdge('n1', 'n2')]);
    const rendered = renderFragmentList(buildEntries(chart));
    const firstLine = rendered.split('\n').find(l => l.includes('**1 ·'));
    const secondLine = rendered.split('\n').find(l => l.includes('**2 ·'));
    expect(firstLine).toContain('`FIRST`');
    expect(secondLine).toContain('`SECOND`');
  });
});
