// skill-node-panel.test.ts — unit tests for site/src/lib/skill-node-panel.ts
//
// Covers: shouldMount, buildProjection, embedJson.
// Minimal scope — task-052 owns the comprehensive node-environment suite.
//
// Placement: same directory as sibling src/lib tests (feature-009, release-data).

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import { shouldMount, buildProjection, embedJson } from '../skill-node-panel.js';
import type { PanelProjection } from '../skill-node-panel.js';

// ── Fixture helpers ───────────────────────────────────────────────────────────

function makeProvenance(overrides: Partial<{
  file: string; startLine: number; endLine: number; sourceKind: string; excerpt: string;
}> = {}) {
  return {
    file: 'canonical/skills/aid-ask/SKILL.md',
    startLine: 1,
    endLine: 3,
    sourceKind: 'skill' as const,
    excerpt: 'some text',
    ...overrides,
  };
}

function makeNode(overrides: Partial<{
  id: string; order: number; name: string; label: string; kind: string;
  terminal: { advanceType: string; handoff: string | null } | null;
  provenance: ReturnType<typeof makeProvenance>;
  detail: ReturnType<typeof makeProvenance> | null;
}> = {}) {
  return {
    id: 'n1',
    order: 1,
    name: 'ENTRY',
    label: 'Entry',
    kind: 'entry',
    terminal: null,
    provenance: makeProvenance(),
    detail: null,
    ...overrides,
  };
}

function makeChart(nodes: ReturnType<typeof makeNode>[] = [makeNode()]) {
  return {
    skill: 'aid-ask',
    shape: 'residual',
    extractor: 'residual',
    confidence: 'approximate' as const,
    title: 'aid-ask — state flow',
    nodes,
    edges: [],
    entries: ['n1'],
    exits: [],
    sources: ['canonical/skills/aid-ask/SKILL.md'],
    warnings: [],
  };
}

// ── shouldMount ───────────────────────────────────────────────────────────────

describe('shouldMount', () => {
  const KNOWN = new Set(['aid-ask', 'aid-plan', 'aid-execute']);

  // ── Positive case ──────────────────────────────────────────────────────────

  it('returns the captured skill name for a valid generatedFrom + known sidecar', () => {
    expect(shouldMount('canonical/skills/aid-ask/SKILL.md', KNOWN)).toBe('aid-ask');
  });

  it('returns a hyphenated name when valid', () => {
    expect(shouldMount('canonical/skills/aid-plan/SKILL.md', KNOWN)).toBe('aid-plan');
  });

  // ── Null: undefined input ──────────────────────────────────────────────────

  it('returns null for undefined — undefined cause only', () => {
    // undefined → no string to match at all
    expect(shouldMount(undefined, KNOWN)).toBeNull();
  });

  it('returns null for empty string — empty cause only', () => {
    // empty string passes typeof string but is falsy
    expect(shouldMount('', KNOWN)).toBeNull();
  });

  // ── Null: reference path outside canonical/skills/ ────────────────────────

  it('returns null for canonical/agents/*/AGENT.md — reference cause only', () => {
    // Path doesn't start with canonical/skills/…/SKILL.md
    expect(shouldMount('canonical/agents/*/AGENT.md', KNOWN)).toBeNull();
  });

  it('returns null for .aid/settings.yml — outside canonical/skills/ cause only', () => {
    expect(shouldMount('.aid/settings.yml', KNOWN)).toBeNull();
  });

  // ── Null: name failing charset ─────────────────────────────────────────────

  it('returns null when skill name contains uppercase — charset cause only', () => {
    // 'Aid-Ask' has uppercase A which is outside [a-z0-9-]
    const known = new Set(['Aid-Ask', 'aid-ask']);
    expect(shouldMount('canonical/skills/Aid-Ask/SKILL.md', known)).toBeNull();
  });

  it('returns null when skill name contains underscore — charset cause only', () => {
    const known = new Set(['aid_ask']);
    expect(shouldMount('canonical/skills/aid_ask/SKILL.md', known)).toBeNull();
  });

  // ── Null: name absent from sidecar set ────────────────────────────────────

  it('returns null when skill name is not in the sidecar set — absent cause only', () => {
    // Pattern matches, but sidecar not generated yet
    expect(shouldMount('canonical/skills/aid-audit/SKILL.md', KNOWN)).toBeNull();
  });

  // ── Fails closed on empty sidecar set (non-vacuity) ───────────────────────

  it('returns null with an empty sidecar set (fails closed)', () => {
    expect(shouldMount('canonical/skills/aid-ask/SKILL.md', new Set())).toBeNull();
  });

  it('returns the name with a populated sidecar set (same name passes)', () => {
    // Same name as the empty-set test above — proves it was the empty set that caused null
    expect(shouldMount('canonical/skills/aid-ask/SKILL.md', new Set(['aid-ask']))).toBe('aid-ask');
  });

  // ── Index-page exclusion: structural, not special-cased ───────────────────

  it('returns null for the skills-index generatedFrom (rejected by charset * and trailing source)', () => {
    const indexFrom = 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml';
    // Rejected: '*' fails [a-z0-9]+ charset AND trailing ", canonical/..." fails $
    expect(shouldMount(indexFrom, new Set(['*']))).toBeNull();
  });

  it('skill-node-panel.ts contains no special case naming "index"', () => {
    const moduleDir = dirname(fileURLToPath(import.meta.url));
    const source = readFileSync(resolve(moduleDir, '../skill-node-panel.ts'), 'utf8');
    // No hard-coded check like === 'index' or skillName === 'index'
    expect(source).not.toMatch(/['"]\s*index\s*['"]/);
  });
});

// ── buildProjection ───────────────────────────────────────────────────────────

describe('buildProjection', () => {
  it('emits v: 1 on every projection', () => {
    const p = buildProjection(makeChart());
    expect(p.v).toBe(1);
  });

  it('emits skill and confidence from chart', () => {
    const p = buildProjection(makeChart());
    expect(p.skill).toBe('aid-ask');
    expect(p.confidence).toBe('approximate');
  });

  it('preserves chart.nodes array order without re-sorting', () => {
    // Provide nodes out-of-order by id to confirm no sort occurs
    const nodes = [
      makeNode({ id: 'n3', order: 3, name: 'EXIT' }),
      makeNode({ id: 'n1', order: 1, name: 'ENTRY' }),
      makeNode({ id: 'n2', order: 2, name: 'STEP' }),
    ];
    const p = buildProjection(makeChart(nodes));
    expect(p.nodes[0].id).toBe('n3');
    expect(p.nodes[1].id).toBe('n1');
    expect(p.nodes[2].id).toBe('n2');
  });

  it('fragment equals provenance.excerpt byte-for-byte', () => {
    const excerpt = 'exact excerpt bytes\n  with indentation';
    const n = makeNode({ provenance: makeProvenance({ excerpt }) });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].fragment).toBe(excerpt);
  });

  it('source.url equals blobUrl(file, startLine, endLine) for single-line case', () => {
    const n = makeNode({
      provenance: makeProvenance({ file: 'canonical/skills/aid-ask/SKILL.md', startLine: 5, endLine: 5 }),
    });
    const p = buildProjection(makeChart([n]));
    // single-line anchor form: #L5
    expect(p.nodes[0].source.url).toContain('#L5');
    expect(p.nodes[0].source.url).not.toContain('-L');
  });

  it('source.url equals blobUrl(file, startLine, endLine) for multi-line case', () => {
    const n = makeNode({
      provenance: makeProvenance({ file: 'canonical/skills/aid-ask/SKILL.md', startLine: 10, endLine: 20 }),
    });
    const p = buildProjection(makeChart([n]));
    // multi-line anchor form: #L10-L20
    expect(p.nodes[0].source.url).toContain('#L10-L20');
  });

  it('source.url contains the file path', () => {
    const n = makeNode({
      provenance: makeProvenance({ file: 'canonical/skills/aid-plan/SKILL.md', startLine: 1, endLine: 1 }),
    });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].source.url).toContain('canonical/skills/aid-plan/SKILL.md');
  });

  it('exit is null when terminal is null', () => {
    const n = makeNode({ terminal: null });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].exit).toBeNull();
  });

  it('exit equals terminal when terminal is non-null', () => {
    const terminal = { advanceType: 'HALT', handoff: null };
    const n = makeNode({ terminal });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].exit).toEqual(terminal);
  });

  it('detail is null when node.detail is null', () => {
    const n = makeNode({ detail: null });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].detail).toBeNull();
  });

  it('detail carries only url when node.detail is non-null', () => {
    const detail = makeProvenance({
      file: 'canonical/skills/aid-ask/SKILL.md',
      startLine: 10,
      endLine: 30,
      excerpt: 'this excerpt must NOT appear in the panel node detail',
    });
    const n = makeNode({ detail });
    const p = buildProjection(makeChart([n]));
    expect(p.nodes[0].detail).not.toBeNull();
    expect(p.nodes[0].detail!.url).toContain('#L10-L30');
    // detail must not carry excerpt
    expect(JSON.stringify(p.nodes[0].detail)).not.toContain('excerpt');
    expect(JSON.stringify(p.nodes[0].detail)).not.toContain('this excerpt must NOT appear');
  });

  it('no excluded keys survive at any depth in the serialized JSON', () => {
    const chart = {
      ...makeChart(),
      edges: [{ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN',
        provenance: makeProvenance() }],
      sources: ['canonical/skills/aid-ask/SKILL.md'],
      warnings: ['a warning'],
      entries: ['n1'],
      exits: ['n2'],
      title: 'aid-ask — state flow',
      shape: 'residual',
      extractor: 'residual',
    };
    const p = buildProjection(chart);
    const serialized = JSON.stringify(p);
    const parsed = JSON.parse(serialized);

    const EXCLUDED = ['edges', 'warnings', 'sources', 'entries', 'exits', 'title', 'shape', 'extractor'];
    const foundKeys: string[] = [];

    function walk(obj: unknown): void {
      if (obj === null || typeof obj !== 'object') return;
      if (Array.isArray(obj)) {
        for (const item of obj) walk(item);
        return;
      }
      for (const key of Object.keys(obj as object)) {
        if (EXCLUDED.includes(key)) foundKeys.push(key);
        walk((obj as Record<string, unknown>)[key]);
      }
    }
    walk(parsed);

    expect(foundKeys).toEqual([]);
  });
});

// ── embedJson ─────────────────────────────────────────────────────────────────

describe('embedJson', () => {
  function makeSimpleProjection(extra: Record<string, unknown> = {}): PanelProjection {
    return {
      v: 1,
      skill: 'test-skill',
      confidence: 'derived',
      nodes: [],
      ...extra,
    } as unknown as PanelProjection;
  }

  it('output contains no literal < characters', () => {
    const p = makeSimpleProjection();
    const out = embedJson(p);
    expect(out).not.toContain('<');
  });

  it('JSON.parse round-trips to deep-equal object', () => {
    const p: PanelProjection = {
      v: 1,
      skill: 'aid-ask',
      confidence: 'approximate',
      nodes: [
        {
          id: 'n1',
          order: 1,
          name: 'ENTRY',
          label: 'Entry',
          kind: 'entry',
          exit: null,
          fragment: 'some text',
          source: { url: 'https://github.com/example#L1' },
          detail: null,
        },
      ],
    };
    const out = embedJson(p);
    const parsed = JSON.parse(out);
    expect(parsed).toEqual(p);
  });

  it('encodes </script> so no literal < remains', () => {
    // Embed </script> in a node fragment
    const withScript: PanelProjection = {
      v: 1,
      skill: 'test',
      confidence: 'derived',
      nodes: [
        {
          id: 'n1', order: 1, name: 'N', label: 'N', kind: 'step',
          exit: null,
          fragment: '</script>',
          source: { url: 'https://github.com/x#L1' },
          detail: null,
        },
      ],
    };
    const out = embedJson(withScript);
    expect(out).not.toContain('<');
    const parsed: PanelProjection = JSON.parse(out);
    expect(parsed.nodes[0].fragment).toBe('</script>');
  });

  it('encodes <!-- so no literal < remains, and round-trips', () => {
    const withComment: PanelProjection = {
      v: 1,
      skill: 'test',
      confidence: 'derived',
      nodes: [
        {
          id: 'n1', order: 1, name: 'N', label: '<!--', kind: 'step',
          exit: null,
          fragment: '<!-- comment -->',
          source: { url: 'https://github.com/x#L1' },
          detail: null,
        },
      ],
    };
    const out = embedJson(withComment);
    expect(out).not.toContain('<');
    expect(JSON.parse(out)).toEqual(withComment);
  });

  it('handles <div>, 4-backtick run, pipe and {braces} — round-trips all', () => {
    const withAll: PanelProjection = {
      v: 1,
      skill: 'test',
      confidence: 'derived',
      nodes: [
        {
          id: 'n1', order: 1, name: 'N', label: '<div>', kind: 'step',
          exit: null,
          fragment: '````\n| pipe |\n{braces}',
          source: { url: 'https://github.com/x#L1' },
          detail: null,
        },
      ],
    };
    const out = embedJson(withAll);
    expect(out).not.toContain('<');
    expect(JSON.parse(out)).toEqual(withAll);
  });

  it('leaves non-< characters unchanged', () => {
    const p = makeSimpleProjection();
    const out = embedJson(p);
    expect(out).toContain('"test-skill"');
  });
});

// ── blobUrl import AC: no #L reconstruction in skill-node-panel.ts ────────────

describe('source code constraints', () => {
  it('skill-node-panel.ts imports blobUrl and does not reconstruct #L anchors', () => {
    const moduleDir = dirname(fileURLToPath(import.meta.url));
    const source = readFileSync(resolve(moduleDir, '../skill-node-panel.ts'), 'utf8');
    // Must import blobUrl from deep-link.mjs
    expect(source).toContain("from '../../scripts/lib/provenance/deep-link.mjs'");
    // Must not contain #L — any URL construction is delegated to blobUrl
    expect(source).not.toContain('#L');
  });
});
