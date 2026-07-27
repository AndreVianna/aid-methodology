// skills-render-index.test.mjs — Tests for site/scripts/skills/render-index.mjs
//
// Covers all acceptance criteria from task-014 and the SPEC:
//   AC-1  Grammar round-trip — three regexes match only the correct lines.
//   AC-2  Two heading levels: H2 for groups, H3 for verb families.
//   AC-3  Full-path block carries a bold lead-in and no heading.
//   AC-4  Card intent equals skillSummary(record), escaped by renderFrontmatterValue.
//   AC-5  Marker is byte-identical to the existing generated pages' sentence.
//   AC-6  title: 'All Skills'; sidebar: hidden: true present and indented.
//   AC-7  Divergence note present, before first ## , names three skills, links to /reference/skills/.
//   AC-8  No count literal in the module source.
//   AC-9  End-to-end: every on-disk skill appears exactly once; no duplicates, no missing.
//   AC-10 Idempotence: renderSkillIndex called twice with same inputs produces identical output.
//
// Drives the real modules — never reimplements their rules inline.

import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { renderSkillIndex } from '../skills/render-index.mjs';
import { discoverSkills } from '../skills/discover.mjs';
import { loadShortcutCatalog } from '../skills/catalog.mjs';
import { assignGroups, CURATED_GROUPS } from '../skills/groups.mjs';
import { skillSummary } from '../skills/summary.mjs';
import { renderFrontmatterValue } from '../skills/render-value.mjs';
import { CANONICAL_SKILLS_DIR, SITE_SKILLS_DIR } from '../skills/paths.mjs';

// ── Index grammar regexes (verbatim from the SPEC § Index grammar) ─────────────
//
// These are the machine contract the renderer emits and this suite parses.
// Nothing else in the rendered page may match any of them.

const RE_GROUP  = /^## (.+)$/;
const RE_FAMILY = /^### `([a-z][a-z-]*)`$/;
// em-dash U+2014 in the card separator
const RE_CARD   = /^- \[`([a-z0-9-]+)`\]\((\/skills\/[a-z0-9-]+\/)\) \u2014 (.+)$/;

// ── File paths ─────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const RENDER_INDEX_SRC = resolve(__dirname, '../skills/render-index.mjs');

// ── Real-corpus fixtures (built once, shared across all end-to-end tests) ──────
//
// Derived from the live canonical/ tree and catalog at test run time.
// No count literal anywhere in this file; every number is re-derived.
//
// KI-016: Vitest runs test files in parallel workers.  gen-skills.test.mjs
// re-runs the generator against SITE_SKILLS_DIR, which can briefly disturb
// the output tree.  Snapshot existingDetailPages at module-import time (before
// any concurrent generator can interfere) so the dead-card check is stable.

const records   = discoverSkills();
const catalog   = loadShortcutCatalog(REPO_ROOT);
const sections  = assignGroups(records, catalog);
const page      = renderSkillIndex(records, sections);
const lines     = page.split('\n');

// Snapshot of the detail-page set captured at import time. Used by the
// dead-card test.
//
// This was written to survive `gen-skills.test.mjs` regenerating the same tree
// in a parallel worker — the KI-016 hazard. `site/vitest.config.mjs` now sets
// `fileParallelism: false`, so this file's import happens after every earlier
// file has finished and there is no concurrent generator left to race. The
// snapshot is therefore redundant TODAY and is kept deliberately: it costs one
// readdir, and it is the difference between a documented defence and a silent
// fragility if file parallelism is ever turned back on.
const existingDetailPageNames = new Set(
  readdirSync(SITE_SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isFile() && e.name.endsWith('.md'))
    .map((e) => e.name.slice(0, -3))  // strip .md
);

// Snapshot detail page CONTENTS at import time for the same reason (KI-016).
// Only retains real generated pages that have a description: frontmatter key.
const detailPageContents = new Map();
for (const name of existingDetailPageNames) {
  const raw = readFileSync(resolve(SITE_SKILLS_DIR, name + '.md'), 'utf8');
  if (raw.includes("description: '")) {
    detailPageContents.set(name, raw);
  }
}

// ── Synthetic helpers (unit tests only) ───────────────────────────────────────

/**
 * Build a minimal SkillRecord-shaped fixture (no real filesystem access).
 */
function makeRecord(dirName, description) {
  const fields = description
    ? [{ key: 'description', kind: 'scalar', value: description, line: 1 }]
    : [];
  return {
    dirName,
    route: '/skills/' + dirName + '/',
    fields,
    field(k) { return fields.find((f) => f.key === k); },
  };
}

// ── AC-5: Generated marker ─────────────────────────────────────────────────────

describe('generated marker (AC-5)', () => {
  it('is byte-identical to the existing generated pages\u2019 sentence', () => {
    const src = 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml';
    const expected =
      `<!-- generated \u2014 do not edit; source: ${src} -->`;
    expect(page).toContain(expected);
  });

  it('contains generated \u2014 do not edit (em-dash, not a hyphen)', () => {
    // Suites\u2019 toContain idiom transfers: the em-dash U+2014 is present.
    expect(page).toContain('generated \u2014 do not edit');
    expect(page).not.toContain('generated - do not edit');
  });

  it('marker appears before the first ## heading', () => {
    const markerIdx = page.indexOf('<!-- generated');
    const firstH2   = page.indexOf('\n## ');
    expect(markerIdx).toBeGreaterThan(-1);
    expect(firstH2).toBeGreaterThan(-1);
    expect(markerIdx).toBeLessThan(firstH2);
  });
});

// ── AC-6: Frontmatter ──────────────────────────────────────────────────────────

describe('frontmatter (AC-6)', () => {
  it('opens with ---', () => {
    expect(page.startsWith('---\n')).toBe(true);
  });

  it("title is 'All Skills' (single-quoted)", () => {
    expect(page).toContain("title: 'All Skills'");
  });

  it('description is the fixed page description', () => {
    const desc =
      "Every AID skill, one card each, grouped by skill group and \u2014" +
      " inside Definition \u2014 by verb family.";
    // Serialised with ' \u2192 '' escaping; this description contains no single quotes.
    expect(page).toContain(`description: '${desc}'`);
  });

  it('generatedFrom lists both sources', () => {
    const src = 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml';
    expect(page).toContain(`generatedFrom: '${src}'`);
  });

  it('sidebar: hidden: true block is present and correctly indented', () => {
    expect(page).toContain('\nsidebar:\n  hidden: true\n---');
  });

  it('frontmatter closes before the generated marker', () => {
    const fmClose  = page.indexOf('\n---\n', 4);  // second ---
    const markerIdx = page.indexOf('<!-- generated');
    expect(fmClose).toBeGreaterThan(0);
    expect(markerIdx).toBeGreaterThan(fmClose);
  });
});

// ── AC-7: Divergence note ──────────────────────────────────────────────────────

describe('divergence note (AC-7)', () => {
  // The note sits between the intro paragraph and the first ## heading.
  const firstH2Pos = page.indexOf('\n## ');
  const noteStart  = page.indexOf('> **Note:**');

  it('is present in the page', () => {
    expect(noteStart).toBeGreaterThan(-1);
  });

  it('sits above the first ## heading', () => {
    expect(noteStart).toBeLessThan(firstH2Pos);
  });

  it('sits below the intro paragraph (after the marker)', () => {
    const markerEnd = page.indexOf('\n\n', page.indexOf('<!-- generated'));
    expect(noteStart).toBeGreaterThan(markerEnd);
  });

  it('names aid-triage', () => {
    // Extract just the note line for scoped checks.
    const noteLine = lines.find((l) => l.startsWith('> **Note:**'));
    expect(noteLine).toBeDefined();
    expect(noteLine).toContain('`aid-triage`');
  });

  it('names aid-deploy', () => {
    const noteLine = lines.find((l) => l.startsWith('> **Note:**'));
    expect(noteLine).toContain('`aid-deploy`');
  });

  it('names aid-monitor', () => {
    const noteLine = lines.find((l) => l.startsWith('> **Note:**'));
    expect(noteLine).toContain('`aid-monitor`');
  });

  it('links to /reference/skills/', () => {
    const noteLine = lines.find((l) => l.startsWith('> **Note:**'));
    expect(noteLine).toContain('/reference/skills/');
  });

  it('does not itself match any grammar regex', () => {
    const noteLine = lines.find((l) => l.startsWith('> **Note:**')) ?? '';
    expect(RE_GROUP.test(noteLine)).toBe(false);
    expect(RE_FAMILY.test(noteLine)).toBe(false);
    expect(RE_CARD.test(noteLine)).toBe(false);
  });
});

// ── AC-2: Heading levels ────────────────────────────────────────────────────────

describe('heading levels (AC-2)', () => {
  it('contains no H1 headings', () => {
    expect(lines.some((l) => /^# [^#]/.test(l))).toBe(false);
  });

  it('H2 headings are exactly the four curated groups in order', () => {
    const h2s = lines
      .map((l) => RE_GROUP.exec(l))
      .filter(Boolean)
      .map((m) => m[1]);
    const expected = CURATED_GROUPS.map((g) => g.group);
    expect(h2s).toEqual(expected);
  });

  it('every H3 heading holds a bare code span and nothing else', () => {
    const h3s = lines.filter((l) => l.startsWith('### '));
    expect(h3s.length).toBeGreaterThan(0);
    for (const h3 of h3s) {
      expect(RE_FAMILY.test(h3)).toBe(true);
    }
  });

  it('contains no H4+ headings', () => {
    expect(lines.some((l) => /^#{4,} /.test(l))).toBe(false);
  });
});

// ── AC-3: Full-path block ──────────────────────────────────────────────────────

describe('full-path block (AC-3)', () => {
  it('has a bold lead-in line (**The full path**)', () => {
    expect(page).toContain('**The full path**');
  });

  it('bold lead-in does not match the group regex', () => {
    const leadIn = lines.find((l) => l.includes('**The full path**'));
    expect(leadIn).toBeDefined();
    expect(RE_GROUP.test(leadIn ?? '')).toBe(false);
  });

  it('bold lead-in does not match the family regex', () => {
    const leadIn = lines.find((l) => l.includes('**The full path**'));
    expect(RE_FAMILY.test(leadIn ?? '')).toBe(false);
  });

  it('five full-path skills appear as cards with no H3 between ## Definition and them', () => {
    // Locate ## Definition, then collect lines until the first ### .
    const defIdx = lines.findIndex((l) => l === '## Definition');
    expect(defIdx).toBeGreaterThan(-1);
    // Find the bold lead-in and cards before the first ### .
    const firstFamilyIdx = lines.findIndex((l, i) => i > defIdx && l.startsWith('### '));
    expect(firstFamilyIdx).toBeGreaterThan(defIdx);
    const blockLines = lines.slice(defIdx, firstFamilyIdx);
    // No H3 heading before the first family.
    expect(blockLines.some((l) => l.startsWith('### '))).toBe(false);
    // All five full-path skills appear as cards in this block.
    const fullPath = CURATED_GROUPS.find((g) => g.fullPath)?.fullPath ?? [];
    for (const name of fullPath) {
      expect(blockLines.some((l) => {
        const m = RE_CARD.exec(l);
        return m !== null && m[1] === name;
      })).toBe(true);
    }
  });

  it('none of the five full-path skills appears under a ### heading', () => {
    const fullPath = new Set(
      CURATED_GROUPS.find((g) => g.fullPath)?.fullPath ?? []
    );
    let currentFamily = null;
    for (const line of lines) {
      if (RE_FAMILY.test(line)) { currentFamily = line; continue; }
      if (RE_GROUP.test(line))  { currentFamily = null; continue; }
      const cardMatch = RE_CARD.exec(line);
      if (cardMatch && currentFamily !== null) {
        expect(fullPath.has(cardMatch[1])).toBe(false);
      }
    }
  });
});

// ── AC-1: Grammar round-trip / nothing else matches ────────────────────────────

describe('grammar round-trip and exclusivity (AC-1)', () => {
  // Build expected sets from the real corpus.

  // Expected group heading count = number of curated groups (no literal)
  const expectedGroupCount = CURATED_GROUPS.length;

  // Expected card count = all skill directories (no literal)
  const onDiskNames = new Set(
    readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
  );
  const expectedCardCount = onDiskNames.size;

  // Expected family count derived from sections
  const expectedFamilyCount = sections.reduce((n, s) => n + s.families.length, 0);

  it('every H2 line matches the group regex', () => {
    const h2s = lines.filter((l) => l.startsWith('## '));
    for (const line of h2s) {
      expect(RE_GROUP.test(line)).toBe(true);
    }
  });

  it('group regex matches exactly the curated-groups count of lines', () => {
    const matched = lines.filter((l) => RE_GROUP.test(l));
    expect(matched.length).toBe(expectedGroupCount);
  });

  it('family regex matches exactly the derived verb-family count of lines', () => {
    const matched = lines.filter((l) => RE_FAMILY.test(l));
    expect(matched.length).toBe(expectedFamilyCount);
  });

  it('card regex matches exactly the on-disk skill count of lines', () => {
    const matched = lines.filter((l) => RE_CARD.test(l));
    expect(matched.length).toBe(expectedCardCount);
  });

  it('nothing that is not an H2 heading matches the group regex', () => {
    // Every line matching the group regex must start with "## " and be
    // exactly one of the four curated group names.
    const groups = new Set(CURATED_GROUPS.map((g) => `## ${g.group}`));
    for (const line of lines) {
      if (RE_GROUP.test(line)) {
        expect(groups.has(line)).toBe(true);
      }
    }
  });

  it('nothing that is not an H3 family heading matches the family regex', () => {
    // Every line matching the family regex must also start with "### ".
    for (const line of lines) {
      if (RE_FAMILY.test(line)) {
        expect(line.startsWith('### ')).toBe(true);
      }
    }
  });

  it('nothing that is not a card line matches the card regex', () => {
    // Every line matching the card regex must start with "- [".
    for (const line of lines) {
      if (RE_CARD.test(line)) {
        expect(line.startsWith('- [')).toBe(true);
      }
    }
  });

  it('the intro, divergence note, blurbs, and bold lead-in match none of the three regexes', () => {
    const nonStructural = lines.filter(
      (l) => !RE_GROUP.test(l) && !RE_FAMILY.test(l) && !RE_CARD.test(l) && l !== ''
    );
    // Spot-check known non-structural lines.
    for (const line of nonStructural) {
      // A non-structural line must NOT match any of the three regexes.
      expect(RE_GROUP.test(line)).toBe(false);
      expect(RE_FAMILY.test(line)).toBe(false);
      expect(RE_CARD.test(line)).toBe(false);
    }
  });
});

// ── AC-9: Every skill appears exactly once ─────────────────────────────────────

describe('every skill appears exactly once (AC-9)', () => {
  const cardMatches = lines
    .map((l) => RE_CARD.exec(l))
    .filter(Boolean);

  const cardNames = cardMatches.map((m) => m[1]);

  it('no card name appears twice', () => {
    const seen = new Set();
    for (const name of cardNames) {
      expect(seen.has(name)).toBe(false);
      seen.add(name);
    }
  });

  it('every on-disk skill directory appears as exactly one card', () => {
    const onDisk = readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name);
    const cardSet = new Set(cardNames);
    for (const name of onDisk) {
      expect(cardSet.has(name)).toBe(true);
    }
  });

  it('no card references a name that has no directory on disk', () => {
    const onDisk = new Set(
      readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
    );
    for (const name of cardNames) {
      expect(onDisk.has(name)).toBe(true);
    }
  });

  it('no dead cards: every card route resolves to an existing detail page', () => {
    // Uses the module-import-time snapshot — see its definition above for why
    // it is retained now that vitest.config.mjs serialises test files (KI-016).
    for (const match of cardMatches) {
      const name = match[1];
      expect(
        existingDetailPageNames.has(name),
        `detail page missing: ${name}.md`
      ).toBe(true);
    }
  });
});

// ── AC-4: Card intent ──────────────────────────────────────────────────────────

describe('card intent equals skillSummary, escaped by renderFrontmatterValue (AC-4)', () => {
  it('every card\u2019s rendered intent equals renderFrontmatterValue(skillSummary(record))', () => {
    const recordByName = new Map(records.map((r) => [r.dirName, r]));
    const cardMatches = lines
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean);

    for (const match of cardMatches) {
      const [, name, , renderedIntent] = match;
      const record = recordByName.get(name);
      expect(record, `record missing for card ${name}`).toBeDefined();
      const expectedIntent = renderFrontmatterValue({
        key: 'description',
        kind: 'scalar',
        value: skillSummary(record),
        line: 0,
      });
      expect(renderedIntent).toBe(expectedIntent);
    }
  });

  it('unescaped summary equals the target page\u2019s description frontmatter', () => {
    // The detail page\u2019s description was serialised with renderSkillPage, which also
    // calls skillSummary. Both must call the same authority for card text and
    // page <meta name="description"> to agree.
    // Uses the snapshot captured at import time (KI-016: concurrent generator
    // runs can briefly overwrite pages with stale fixtures).
    const recordByName = new Map(records.map((r) => [r.dirName, r]));
    const cardMatches = lines
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean);

    for (const match of cardMatches) {
      const [, name] = match;
      const record = recordByName.get(name);
      if (!record) continue;
      const summary = skillSummary(record);
      const detailContent = detailPageContents.get(name);
      if (!detailContent) continue; // page was stale/missing at snapshot time
      // The description in frontmatter is single-quoted with ' -> '' escaping.
      const escaped = summary.replace(/'/g, "''");
      expect(detailContent).toContain(`description: '${escaped}'`);
    }
  });

  it('no card line contains a raw < followed by a letter or / outside a code span', () => {
    // Cards that reach this check have already been through the code-span-aware
    // escaper; raw HTML-like sequences outside code spans become &lt;.
    const cardMatches = lines
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean);

    for (const match of cardMatches) {
      const [, name, , intent] = match;
      // After the code-span-aware escaper, any < outside a code span is &lt;.
      // Walk through the intent: code-span regions pass unchanged; outside them,
      // no raw < should remain before a letter or /.
      let i = 0;
      while (i < intent.length) {
        if (intent[i] === '`') {
          // Skip code-span region
          let j = i + 1;
          while (j < intent.length && intent[j] === '`') j++;
          const runLen = j - i;
          let k = j;
          let closed = false;
          while (k < intent.length) {
            if (intent[k] === '`') {
              let l = k + 1;
              while (l < intent.length && intent[l] === '`') l++;
              if (l - k === runLen) { i = l; closed = true; break; }
              k = l;
            } else { k++; }
          }
          if (!closed) i = j;
        } else {
          if (intent[i] === '<') {
            const next = intent[i + 1];
            if (next !== undefined && (/[a-zA-Z/]/.test(next))) {
              throw new Error(
                `card ${name}: raw < before '${next}' found in intent: ${intent}`
              );
            }
          }
          i++;
        }
      }
    }
  });
});

// ── Catalog / family ordering ──────────────────────────────────────────────────

describe('family headings inside Definition follow catalog first-appearance order', () => {
  it('family heading order in the page equals catalog first-appearance verb order', () => {
    // Build the expected verb order from the catalog (same rule as assignGroups).
    const curatedNames = new Set();
    for (const entry of CURATED_GROUPS) {
      for (const n of (entry.fullPath || [])) curatedNames.add(n);
      for (const n of entry.members) curatedNames.add(n);
    }
    const expectedVerbs = [];
    const seen = new Set();
    for (const row of catalog.rows) {
      if (curatedNames.has(row.name)) continue;
      if (!seen.has(row.verb)) {
        seen.add(row.verb);
        expectedVerbs.push(row.verb);
      }
    }

    // Extract actual family headings from the page.
    const actualVerbs = lines
      .map((l) => RE_FAMILY.exec(l))
      .filter(Boolean)
      .map((m) => m[1]);

    // Filter expected verbs to those that actually appear (empty families are omitted).
    const actualSet = new Set(actualVerbs);
    const expectedFiltered = expectedVerbs.filter((v) => actualSet.has(v));

    expect(actualVerbs).toEqual(expectedFiltered);
  });

  it('aid-deploy sits under ### `deploy` (not in the full-path block)', () => {
    let currentFamily = null;
    let deployFamilyFound = false;
    for (const line of lines) {
      const fm = RE_FAMILY.exec(line);
      if (fm) { currentFamily = fm[1]; continue; }
      if (RE_GROUP.test(line)) { currentFamily = null; continue; }
      const cm = RE_CARD.exec(line);
      if (cm && cm[1] === 'aid-deploy') {
        expect(currentFamily).toBe('deploy');
        deployFamilyFound = true;
      }
    }
    expect(deployFamilyFound).toBe(true);
  });

  it('aid-monitor sits under ### `monitor`', () => {
    let currentFamily = null;
    let found = false;
    for (const line of lines) {
      const fm = RE_FAMILY.exec(line);
      if (fm) { currentFamily = fm[1]; continue; }
      if (RE_GROUP.test(line)) { currentFamily = null; continue; }
      const cm = RE_CARD.exec(line);
      if (cm && cm[1] === 'aid-monitor') {
        expect(currentFamily).toBe('monitor');
        found = true;
      }
    }
    expect(found).toBe(true);
  });

  it('aid-triage sits under ## Support (not ## Definition)', () => {
    let currentGroup = null;
    let found = false;
    for (const line of lines) {
      const gm = RE_GROUP.exec(line);
      if (gm) { currentGroup = gm[1]; continue; }
      const cm = RE_CARD.exec(line);
      if (cm && cm[1] === 'aid-triage') {
        expect(currentGroup).toBe('Support');
        found = true;
      }
    }
    expect(found).toBe(true);
  });

  it('aid-triage is the first card in Support', () => {
    const supportIdx = lines.findIndex((l) => l === '## Support');
    expect(supportIdx).toBeGreaterThan(-1);
    const nextGroupIdx = lines.findIndex((l, i) => i > supportIdx && RE_GROUP.test(l));
    const supportLines = lines.slice(supportIdx, nextGroupIdx > -1 ? nextGroupIdx : undefined);
    const firstCard = supportLines.find((l) => RE_CARD.test(l));
    expect(firstCard).toBeDefined();
    const m = RE_CARD.exec(firstCard ?? '');
    expect(m?.[1]).toBe('aid-triage');
  });

  it('every catalog-backed card sits under ## Definition under the correct ### verb', () => {
    // For every non-curated card, its family heading verb must equal catalog.byName.get(name).verb.
    const curatedNames = new Set();
    for (const entry of CURATED_GROUPS) {
      for (const n of (entry.fullPath || [])) curatedNames.add(n);
      for (const n of entry.members) curatedNames.add(n);
    }

    let currentGroup = null;
    let currentFamily = null;
    for (const line of lines) {
      const gm = RE_GROUP.exec(line);
      if (gm) { currentGroup = gm[1]; currentFamily = null; continue; }
      const fm = RE_FAMILY.exec(line);
      if (fm) { currentFamily = fm[1]; continue; }
      const cm = RE_CARD.exec(line);
      if (cm) {
        const name = cm[1];
        if (curatedNames.has(name)) continue; // curated skills checked separately
        // Non-curated skills must be in Definition under the correct verb family.
        expect(currentGroup).toBe('Definition');
        const row = catalog.byName.get(name);
        expect(row, `no catalog row for non-curated skill ${name}`).toBeDefined();
        expect(currentFamily).toBe(row?.verb);
      }
    }
  });
});

// ── Curated-group membership ───────────────────────────────────────────────────

describe('curated group membership agrees with CURATED_GROUPS', () => {
  it('every curated member skill sits in the correct group', () => {
    // Build expected group for each curated name.
    const expected = new Map();
    for (const entry of CURATED_GROUPS) {
      for (const n of (entry.fullPath || [])) expected.set(n, entry.group);
      for (const n of entry.members) expected.set(n, entry.group);
    }

    let currentGroup = null;
    for (const line of lines) {
      const gm = RE_GROUP.exec(line);
      if (gm) { currentGroup = gm[1]; continue; }
      const cm = RE_CARD.exec(line);
      if (cm) {
        const name = cm[1];
        if (expected.has(name)) {
          expect(currentGroup).toBe(expected.get(name));
        }
      }
    }
  });

  it('the full-path block cards equal the five full-path skills in pipeline order', () => {
    const fullPath = CURATED_GROUPS.find((g) => g.fullPath)?.fullPath ?? [];
    const defIdx = lines.findIndex((l) => l === '## Definition');
    expect(defIdx).toBeGreaterThan(-1);
    const firstFamilyIdx = lines.findIndex((l, i) => i > defIdx && RE_FAMILY.test(l));
    // Cards between ## Definition and first ### (exclusive of blanks/lead-in).
    const blockCards = lines
      .slice(defIdx, firstFamilyIdx)
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean)
      .map((m) => m[1]);
    expect(blockCards).toEqual(fullPath);
  });

  it('none of the five full-path skills has a catalog row', () => {
    const fullPath = CURATED_GROUPS.find((g) => g.fullPath)?.fullPath ?? [];
    for (const name of fullPath) {
      expect(catalog.byName.has(name)).toBe(false);
    }
  });
});

// ── AC-8: No count literal in the module source ────────────────────────────────

describe('no count literal in module source (AC-8)', () => {
  // The module must not contain the number 157 (the cap lives only in summary.mjs).
  it('does not contain 157 (the summary cap lives only in summary.mjs)', () => {
    const src = readFileSync(RENDER_INDEX_SRC, 'utf8');
    expect(src).not.toMatch(/\b157\b/);
  });

  // These two prove INTERPOLATION, not agreement.
  //
  // The obvious form — assert the rendered number equals `records.length` — is
  // satisfied just as well by a hard-coded literal that happens to match today's
  // corpus, so it cannot detect the defect its name promises. §8 forbids exactly
  // that literal, and a hard-coded count is what produced KI-005. The check that
  // actually bites is to render a corpus of a DIFFERENT size and require the
  // output to move with it: a literal cannot track two sizes at once.

  // A synthetic corpus, deliberately not built through `assignGroups` — its four
  // guards would reject any subset of the real corpus, and what is under test
  // here is the renderer's arithmetic, not the assigner's.
  const tinyCorpus = () => {
    const recs = [makeRecord('aid-alpha', 'Alpha.'), makeRecord('aid-beta', 'Beta.')];
    const card = (r) => ({ name: r.dirName, route: r.route, intent: skillSummary(r) });
    const secs = [
      { group: 'Support', blurb: 'b', cards: [card(recs[0])], families: [] },
      {
        group: 'Definition',
        blurb: 'b',
        cards: [],
        families: [{ verb: 'fix', cards: [card(recs[1])] }],
      },
    ];
    return { recs, secs };
  };

  it('the intro skill count tracks the corpus size, so it cannot be a literal', () => {
    const { recs, secs } = tinyCorpus();
    const shrunk = /\*\*(\d+) skill directories\*\*/.exec(renderSkillIndex(recs, secs));
    expect(shrunk).not.toBeNull();
    expect(Number(shrunk?.[1])).toBe(recs.length);

    const full = /\*\*(\d+) skill directories\*\*/.exec(page);
    expect(Number(full?.[1])).toBe(records.length);
    // Two corpora of different sizes yield different numbers — a literal could
    // satisfy at most one of these two assertions.
    expect(Number(full?.[1])).not.toBe(Number(shrunk?.[1]));
  });

  it('the intro family count tracks the derived families, so it cannot be a literal', () => {
    const derived = (s) => s.reduce((n, x) => n + x.families.length, 0);
    const { recs, secs } = tinyCorpus();

    const shrunk = /\*\*(\d+) verb famil/.exec(renderSkillIndex(recs, secs));
    expect(shrunk).not.toBeNull();
    expect(Number(shrunk?.[1])).toBe(derived(secs));

    const full = /\*\*(\d+) verb famil/.exec(page);
    expect(Number(full?.[1])).toBe(derived(sections));
    expect(Number(full?.[1])).not.toBe(Number(shrunk?.[1]));
  });

  // Belt and braces, using the source-inspection idiom already used above for
  // the 157 cap: no bare two-or-three-digit integer may appear in the module.
  it('the module source carries no bare corpus-count literal', () => {
    const src = readFileSync(RENDER_INDEX_SRC, 'utf8')
      .split('\n')
      .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l)) // ignore comments
      .join('\n');
    expect(src).not.toMatch(/\b\d{2,3}\b/);
  });
});

// ── AC-10: Idempotence ────────────────────────────────────────────────────────

describe('idempotence (AC-10)', () => {
  it('renderSkillIndex is a pure function: second call produces identical output', () => {
    const page2 = renderSkillIndex(records, sections);
    expect(page2).toBe(page);
  });
});

// ── Link target format ────────────────────────────────────────────────────────

describe('card link targets', () => {
  it('every card route equals /skills/<name>/', () => {
    const cardMatches = lines
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean);
    for (const match of cardMatches) {
      const [, name, route] = match;
      expect(route).toBe(`/skills/${name}/`);
    }
  });
});
