// feature-006-head-gate.test.ts — task-047 gate-decision tests for Head.astro
//
// Tests the pure decision layer (shouldMount from skill-node-panel.ts) for the five
// pages that must emit zero additional tags, and the construction path for the three
// tags emitted on a skill detail page.
//
// Astro component rendering is not unit-testable here; build-time distribution
// verification is task-048's gate check (AC-6.5). The parts tested here are:
//   - shouldMount exclusions for all five documented zero-tag pages (non-vacuous)
//   - shouldMount inclusion for a valid skill detail page
//   - embedJson output parses cleanly and contains v:1
//   - Head.astro source contains no readFileSync, no fetch(, no process.env
//
// task-052 owns the comprehensive node-environment suite for feature-006's
// build-time half.

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect, beforeAll } from 'vitest';
import { shouldMount, buildProjection, embedJson } from '../skill-node-panel.js';
import type { PanelProjection } from '../skill-node-panel.js';

const moduleDir = dirname(fileURLToPath(import.meta.url));

// ── Five excluded pages — generatedFrom values sourced from the actual content files ─────

// pages 1-3: paths outside canonical/skills/ → pattern fails the regex
// pages 4-5: comma-joined two-source string → fails the anchored $ in the regex

const EXCLUDED_PAGES = [
  {
    page: 'reference/agents.md',
    generatedFrom: 'canonical/agents/*/AGENT.md',
    reason: 'path outside canonical/skills/',
  },
  {
    page: 'reference/kb.md',
    generatedFrom: 'canonical/aid/templates/knowledge-base/*.md',
    reason: 'path outside canonical/skills/',
  },
  {
    page: 'reference/settings.md',
    generatedFrom: '.aid/settings.yml',
    reason: 'path outside canonical/skills/',
  },
  {
    page: 'reference/skills.md',
    generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml',
    reason: 'comma-joined two-source string — fails anchored $ in pattern',
  },
  {
    page: 'skills/index.md',
    generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml',
    reason: 'comma-joined two-source string — fails anchored $ in pattern',
  },
];

// Maximally permissive known set: includes names that WOULD match if only the pattern
// succeeded. Proves the pattern rejects, not the known-set membership.
const PERMISSIVE_KNOWN = new Set(['*', 'index', 'agents', 'knowledge-base', 'settings', 'skills']);

// ── Zero-tag case: all five excluded pages (non-vacuous) ─────────────────────────────────

describe('shouldMount — five excluded pages return null (zero-tag gate)', () => {
  for (const { page, generatedFrom, reason } of EXCLUDED_PAGES) {
    it(`returns null for ${page} — ${reason}`, () => {
      expect(shouldMount(generatedFrom, PERMISSIVE_KNOWN)).toBeNull();
    });
  }

  // Non-vacuity: a valid skill generatedFrom with PERMISSIVE_KNOWN must return non-null.
  // This proves the exclusions above are due to the pattern, not an always-null gate.
  it('returns skill name for a valid skill page (proves zero-tag cases are not vacuous)', () => {
    const validFrom = 'canonical/skills/aid-ask/SKILL.md';
    const knownWithAidAsk = new Set([...PERMISSIVE_KNOWN, 'aid-ask']);
    expect(shouldMount(validFrom, knownWithAidAsk)).toBe('aid-ask');
  });
});

// ── Comma-joined rejection is structural, not a special case naming "index" ─────────────

describe('shouldMount — comma-joined rejection is anchored-pattern, not special-cased', () => {
  it('Head.astro source contains no special case naming "index"', () => {
    const headSource = readFileSync(
      resolve(moduleDir, '../../components/overrides/Head.astro'),
      'utf8',
    );
    expect(headSource).not.toMatch(/['"]\s*index\s*['"]/);
  });

  it('the same comma-joined string with a single valid path before the comma is still null', () => {
    // Confirm it is the comma (and therefore the $ anchor) that causes rejection,
    // not any other characteristic of the string.
    const commaJoined = 'canonical/skills/aid-ask/SKILL.md, extra-source.yml';
    // known DOES contain 'aid-ask' — only the pattern fails
    expect(shouldMount(commaJoined, new Set(['aid-ask']))).toBeNull();
  });
});

// ── Three-tag construction path ───────────────────────────────────────────────────────────

describe('three-tag construction (shouldMount + buildProjection + embedJson pipeline)', () => {
  function makeMinimalChart() {
    return {
      skill: 'aid-ask',
      shape: 'residual',
      extractor: 'residual',
      confidence: 'approximate' as const,
      title: 'aid-ask',
      nodes: [
        {
          id: 'n1',
          order: 1,
          name: 'ENTRY',
          label: 'Entry',
          kind: 'entry',
          terminal: null,
          provenance: {
            file: 'canonical/skills/aid-ask/SKILL.md',
            startLine: 1,
            endLine: 3,
            sourceKind: 'skill',
            excerpt: 'entry text',
          },
          detail: null,
        },
      ],
      edges: [],
      entries: ['n1'],
      exits: [],
      sources: ['canonical/skills/aid-ask/SKILL.md'],
      warnings: [],
    };
  }

  it('pipeline produces a JSON string that parses to an object with v:1', () => {
    const chart = makeMinimalChart();
    const projection = buildProjection(chart);
    const json = embedJson(projection);
    const parsed = JSON.parse(json) as PanelProjection;
    expect(parsed.v).toBe(1);
  });

  it('embedded JSON string contains no literal < characters (non-vacuous: input contains <)', () => {
    // Use a chart where the excerpt contains '<script>' so the test would fail if embedJson
    // did not escape — a chart with no '<' would pass vacuously.
    const chartWithLt = {
      skill: 'aid-ask',
      shape: 'residual',
      extractor: 'residual',
      confidence: 'approximate' as const,
      title: 'aid-ask',
      nodes: [
        {
          id: 'n1',
          order: 1,
          name: 'ENTRY',
          label: 'Entry',
          kind: 'entry',
          terminal: null,
          provenance: {
            file: 'canonical/skills/aid-ask/SKILL.md',
            startLine: 1,
            endLine: 3,
            sourceKind: 'skill',
            excerpt: '</script><!--injection-->',
          },
          detail: null,
        },
      ],
      edges: [],
      entries: ['n1'],
      exits: [],
      sources: ['canonical/skills/aid-ask/SKILL.md'],
      warnings: [],
    };
    const json = embedJson(buildProjection(chartWithLt));
    expect(json).not.toContain('<');
    // And the input DID have < characters (non-vacuity bound)
    expect(chartWithLt.nodes[0].provenance.excerpt).toContain('<');
  });

  it('embedded JSON string is non-empty (not from a vacuous input)', () => {
    const chart = makeMinimalChart();
    const json = embedJson(buildProjection(chart));
    expect(json.length).toBeGreaterThan(0);
    const parsed = JSON.parse(json) as PanelProjection;
    expect(parsed.nodes.length).toBeGreaterThan(0);
  });

  it('parsed output contains skill name from chart', () => {
    const chart = makeMinimalChart();
    const json = embedJson(buildProjection(chart));
    const parsed = JSON.parse(json) as PanelProjection;
    expect(parsed.skill).toBe('aid-ask');
  });
});

// ── Source constraints on Head.astro ─────────────────────────────────────────────────────

describe('Head.astro source constraints', () => {
  let headSource: string;
  let headTemplate: string;

  beforeAll(() => {
    headSource = readFileSync(
      resolve(moduleDir, '../../components/overrides/Head.astro'),
      'utf8',
    );
    // The template section starts after the closing `---` of the frontmatter.
    // Split on `\n---\n` to get everything after the second delimiter.
    const parts = headSource.split(/\n---\n/);
    headTemplate = parts.length >= 2 ? parts.slice(1).join('\n---\n') : '';
  });

  it('contains no readFileSync — no synchronous file I/O on the mounting path', () => {
    expect(headSource).not.toContain('readFileSync');
  });

  it('contains no fetch( — no network calls', () => {
    expect(headSource).not.toContain('fetch(');
  });

  it('contains no process.env — no environment variable reads', () => {
    expect(headSource).not.toContain('process.env');
  });

  it('imports shouldMount from skill-node-panel (not reimplementing the gate)', () => {
    expect(headSource).toContain('shouldMount');
    expect(headSource).toContain('skill-node-panel');
  });

  it('imports buildProjection and embedJson from skill-node-panel', () => {
    expect(headSource).toContain('buildProjection');
    expect(headSource).toContain('embedJson');
  });

  it('uses set:html for the JSON island (not an interpolated child)', () => {
    // Check template section to avoid matching comment that documents the tag
    expect(headTemplate).toContain('set:html={embedded}');
  });

  it('JSON island script tag carries is:inline (template section, not comment)', () => {
    // is:inline added explicitly to suppress astro(4000) hint
    expect(headTemplate).toMatch(/type="application\/json"[^>]*is:inline|is:inline[^>]*type="application\/json"/);
  });

  it('controller script tag carries is:inline (template section, not comment)', () => {
    // is:inline keeps the runtime conditional effective; Astro module-graph deduplication
    // would otherwise pull a processed script onto every page regardless of the condition.
    expect(headTemplate).toMatch(/skill-node-panel\.mjs[^>]*is:inline|is:inline[^>]*skill-node-panel\.mjs/);
  });

  it('composes with Default (<Default />) rather than reimplementing Head', () => {
    expect(headTemplate).toContain('<Default />');
    expect(headSource).toContain("from '@astrojs/starlight/components/Head.astro'");
  });
});
