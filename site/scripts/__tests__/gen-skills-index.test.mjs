// gen-skills-index.test.mjs — The AC-8 fifteen-assertion suite for the
//                              grouped /skills/ index (feature-002).
//
// A SEPARATE file from gen-skills.test.mjs, mirroring feature-001's decision
// to keep its suite separate from gen-reference.test.mjs — each suite owns
// one artifact. This file owns the SHIPPED site/src/content/docs/skills/index.md:
// the whole-corpus contract, parsed off disk through the three index-grammar
// regexes (SPEC § Index grammar) so AC-8 is a parse rather than a substring
// hunt. It does not test renderSkillIndex() in isolation — that unit-level
// coverage lives in skills-render-index.test.mjs; this suite drives the real
// generator and reads its real output.
//
// Every expectation is re-derived from canonical/skills/, shortcut-catalog.yml,
// groups.mjs, summary.mjs, the rendered pages, or the manifest. No assertion
// compares anything to a numeric literal — the defect class that produced
// KI-005.

import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';
import { discoverSkills } from '../skills/discover.mjs';
import { loadShortcutCatalog } from '../skills/catalog.mjs';
import { CURATED_GROUPS } from '../skills/groups.mjs';
import { skillSummary } from '../skills/summary.mjs';

// ── Index grammar (verbatim from feature-002's SPEC § Index grammar) ──────────
//
// The machine contract the renderer emits and this suite parses. Nothing else
// in the page may match any of them.

const RE_GROUP  = /^## (.+)$/;
const RE_FAMILY = /^### `([a-z][a-z-]*)`$/;
// em-dash U+2014 in the card separator
const RE_CARD   = /^- \[`([a-z0-9-]+)`\]\((\/skills\/[a-z0-9-]+\/)\) \u2014 (.+)$/;

// The five full-path skills, in pipeline order — a fixed curatorial list
// (REQUIREMENTS.md FR-5 Placement rules), asserted explicitly rather than
// re-derived from CURATED_GROUPS so a corruption of that table's fullPath
// entry cannot silently exempt itself from assertions 5/6.
const FULL_PATH_SKILLS = ['aid-describe', 'aid-define', 'aid-specify', 'aid-plan', 'aid-detail'];

// ── File paths ─────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const REPO_ROOT = resolve(__dirname, '../../../');
const CANONICAL_SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const SITE_SKILLS_DIR = join(SITE_ROOT, 'src', 'content', 'docs', 'skills');
const INDEX_PATH = join(SITE_SKILLS_DIR, 'index.md');
const MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.skills-manifest.json');
const GEN_SKILLS_SCRIPT = 'scripts/gen-skills.mjs';

// ── Fixtures: run the real generator, read the real shipped file ─────────────
//
// beforeAll (not module-scope) so this suite's setup is explicit and isolated
// from import-order effects in sibling files. The generator is a pure function
// of canonical/skills/ + shortcut-catalog.yml (AC-6), so re-running it here is
// side-effect-free with respect to every other suite's expectations.

let indexContent;
let indexLines;
let records;
let catalog;
let curatedNames;
let parsed;

/**
 * Parse the shipped index.md into a structured shape using the three
 * index-grammar regexes: doc-order group headings, doc-order family headings
 * per group, and every card with the group/family it was found under.
 *
 * @param {string[]} lines
 */
function parseIndex(lines) {
  /** @type {string[]} */
  const groupHeadings = [];
  /** @type {Map<string, string[]>} group -> family verbs, doc order */
  const familyHeadingsByGroup = new Map();
  /** @type {Array<{name: string, route: string, intent: string, group: string|null, family: string|null}>} */
  const cards = [];

  let currentGroup = null;
  let currentFamily = null;

  for (const line of lines) {
    const gm = RE_GROUP.exec(line);
    if (gm) {
      currentGroup = gm[1];
      currentFamily = null;
      groupHeadings.push(currentGroup);
      continue;
    }
    const fm = RE_FAMILY.exec(line);
    if (fm) {
      currentFamily = fm[1];
      if (!familyHeadingsByGroup.has(currentGroup)) {
        familyHeadingsByGroup.set(currentGroup, []);
      }
      familyHeadingsByGroup.get(currentGroup).push(currentFamily);
      continue;
    }
    const cm = RE_CARD.exec(line);
    if (cm) {
      cards.push({
        name: cm[1],
        route: cm[2],
        intent: cm[3],
        group: currentGroup,
        family: currentFamily,
      });
    }
  }

  return { groupHeadings, familyHeadingsByGroup, cards };
}

beforeAll(() => {
  execSync(`node ${GEN_SKILLS_SCRIPT}`, { cwd: SITE_ROOT, stdio: 'pipe' });

  indexContent = readFileSync(INDEX_PATH, 'utf8');
  indexLines = indexContent.split('\n');
  records = discoverSkills();
  catalog = loadShortcutCatalog(REPO_ROOT);
  parsed = parseIndex(indexLines);

  // The complete curated name set (fullPath + members), derived from
  // groups.mjs — never hand-duplicated here.
  curatedNames = new Set();
  for (const entry of CURATED_GROUPS) {
    for (const n of entry.fullPath || []) curatedNames.add(n);
    for (const n of entry.members) curatedNames.add(n);
  }
});

// ── Assertion 1 — card set equals on-disk directory set, both directions ─────

describe('assertion 1 — parsed card set equals the on-disk directory set', () => {
  it('every on-disk skill directory has at least one card (uniqueness verified separately below)', () => {
    const onDisk = readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name);
    const cardNames = parsed.cards.map((c) => c.name);

    for (const dir of onDisk) {
      expect(cardNames, `directory ${dir} has no card`).toContain(dir);
    }
  });

  it('every card name has a directory on disk (no phantom card)', () => {
    const onDisk = new Set(
      readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
    );
    for (const card of parsed.cards) {
      expect(onDisk.has(card.name), `card "${card.name}" has no directory on disk`).toBe(true);
    }
  });

  it('no card name appears twice', () => {
    const seen = new Set();
    for (const card of parsed.cards) {
      expect(seen.has(card.name), `card "${card.name}" appears more than once`).toBe(false);
      seen.add(card.name);
    }
  });
});

// ── Assertion 2 — the four ## headings, exact order ──────────────────────────

describe('assertion 2 — ## headings are the four curated groups, in order', () => {
  it('group headings equal CURATED_GROUPS order exactly', () => {
    const expected = CURATED_GROUPS.map((g) => g.group);
    expect(parsed.groupHeadings).toEqual(expected);
  });
});

// ── Assertion 3 — curated group agreement; aid-triage -> Support by name ─────

describe('assertion 3 — curated skill group agrees with CURATED_GROUPS', () => {
  it("every curated skill's parsed group equals CURATED_GROUPS's", () => {
    /** @type {Map<string,string>} */
    const expectedGroup = new Map();
    for (const entry of CURATED_GROUPS) {
      for (const n of entry.fullPath || []) expectedGroup.set(n, entry.group);
      for (const n of entry.members) expectedGroup.set(n, entry.group);
    }

    for (const card of parsed.cards) {
      if (expectedGroup.has(card.name)) {
        expect(card.group, `${card.name} should be under ${expectedGroup.get(card.name)}`)
          .toBe(expectedGroup.get(card.name));
      }
    }
  });

  it('aid-triage is filed under Support', () => {
    const card = parsed.cards.find((c) => c.name === 'aid-triage');
    expect(card, 'aid-triage card not found').toBeDefined();
    expect(card.group).toBe('Support');
  });
});

// ── Assertion 4 — catalog agreement for every non-curated card ───────────────

describe('assertion 4 — catalog agreement for every non-curated card', () => {
  it('every non-curated card sits under Definition, under its catalog verb family', () => {
    let checked = 0;
    for (const card of parsed.cards) {
      if (curatedNames.has(card.name)) continue;
      const row = catalog.byName.get(card.name);
      expect(row, `no catalog row for non-curated skill ${card.name}`).toBeDefined();
      expect(card.group, `${card.name} should be under Definition`).toBe('Definition');
      expect(card.family, `${card.name} should be under its catalog verb family`).toBe(row.verb);
      checked += 1;
    }
    expect(checked).toBeGreaterThan(0);
  });
});

// ── Assertion 5 — full-path block: exact array equality ──────────────────────

describe('assertion 5 — full-path block equals the fixed five, in pipeline order', () => {
  it('cards between ## Definition and its first ### heading equal the fixed list exactly', () => {
    const defIdx = indexLines.findIndex((l) => l === '## Definition');
    expect(defIdx).toBeGreaterThan(-1);
    const firstFamilyIdx = indexLines.findIndex((l, i) => i > defIdx && RE_FAMILY.test(l));
    expect(firstFamilyIdx).toBeGreaterThan(defIdx);

    const blockCardNames = indexLines
      .slice(defIdx, firstFamilyIdx)
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean)
      .map((m) => m[1]);

    expect(blockCardNames).toEqual(FULL_PATH_SKILLS);
  });
});

// ── Assertion 6 — the exemption is derived, not assumed ──────────────────────

describe('assertion 6 — none of the five full-path skills has a catalog row', () => {
  it('catalog.byName.has(n) is false for each of the five', () => {
    for (const name of FULL_PATH_SKILLS) {
      expect(catalog.byName.has(name), `${name} unexpectedly has a catalog row`).toBe(false);
    }
  });
});

// ── Assertion 7 — aid-deploy / aid-monitor named explicitly ──────────────────

describe('assertion 7 — aid-deploy and aid-monitor sit under their own families', () => {
  it('aid-deploy sits under ### `deploy`', () => {
    const card = parsed.cards.find((c) => c.name === 'aid-deploy');
    expect(card, 'aid-deploy card not found').toBeDefined();
    expect(card.family).toBe('deploy');
  });

  it('aid-monitor sits under ### `monitor`', () => {
    const card = parsed.cards.find((c) => c.name === 'aid-monitor');
    expect(card, 'aid-monitor card not found').toBeDefined();
    expect(card.family).toBe('monitor');
  });

  it('neither aid-deploy nor aid-monitor appears in the full-path block', () => {
    expect(FULL_PATH_SKILLS).not.toContain('aid-deploy');
    expect(FULL_PATH_SKILLS).not.toContain('aid-monitor');

    const defIdx = indexLines.findIndex((l) => l === '## Definition');
    const firstFamilyIdx = indexLines.findIndex((l, i) => i > defIdx && RE_FAMILY.test(l));
    const blockCardNames = indexLines
      .slice(defIdx, firstFamilyIdx)
      .map((l) => RE_CARD.exec(l))
      .filter(Boolean)
      .map((m) => m[1]);

    expect(blockCardNames).not.toContain('aid-deploy');
    expect(blockCardNames).not.toContain('aid-monitor');
  });
});

// ── Assertion 8 — the clamp, both directions ──────────────────────────────────

describe('assertion 8 — the clamp: curated-or-catalog-backed, both directions', () => {
  it('every on-disk directory is curated or catalog-backed', () => {
    const onDisk = readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name);
    for (const dir of onDisk) {
      const ok = curatedNames.has(dir) || catalog.byName.has(dir);
      expect(ok, `${dir} is neither curated nor catalog-backed`).toBe(true);
    }
  });

  it('every curated name has a directory on disk', () => {
    const onDisk = new Set(
      readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
    );
    for (const name of curatedNames) {
      expect(onDisk.has(name), `curated name ${name} has no directory on disk`).toBe(true);
    }
  });
});

// ── Assertion 9 — family heading order = catalog first-appearance order ─────

describe('assertion 9 — family heading order equals catalog first-appearance order', () => {
  it('Definition family headings, in document order, equal catalog first-appearance verb order (non-curated rows only)', () => {
    const expectedVerbs = [];
    const seen = new Set();
    for (const row of catalog.rows) {
      if (curatedNames.has(row.name)) continue;
      if (!seen.has(row.verb)) {
        seen.add(row.verb);
        expectedVerbs.push(row.verb);
      }
    }

    const actualVerbs = parsed.familyHeadingsByGroup.get('Definition') || [];
    // Restrict expected to verbs that actually produced a section (a verb
    // whose every member is curated derives no section — SPEC § Family derivation).
    const actualSet = new Set(actualVerbs);
    const expectedFiltered = expectedVerbs.filter((v) => actualSet.has(v));

    expect(actualVerbs).toEqual(expectedFiltered);
  });
});

// ── Assertion 10 — no dead cards ─────────────────────────────────────────────

describe('assertion 10 — no dead cards: every card route resolves to an existing page', () => {
  it('every card name has a corresponding site/src/content/docs/skills/<name>.md', () => {
    for (const card of parsed.cards) {
      const pagePath = join(SITE_SKILLS_DIR, card.name + '.md');
      expect(existsSync(pagePath), `no detail page for card ${card.name}`).toBe(true);
    }
  });
});

// ── Assertion 11 — card intent pins summary.mjs and the target page together ─

describe('assertion 11 — card intent equals skillSummary(record); unescaped summary equals the page description', () => {
  it("every card's rendered intent equals the escaped rendering of skillSummary(record)", () => {
    const recordByName = new Map(records.map((r) => [r.dirName, r]));
    let checked = 0;
    for (const card of parsed.cards) {
      const record = recordByName.get(card.name);
      expect(record, `record missing for card ${card.name}`).toBeDefined();
      const summary = skillSummary(record);
      // Escaped the same way render-index.mjs escapes every card: code-span-aware
      // & -> &amp;, < -> &lt;. Reimplemented minimally here only for entries with
      // no special characters would be circular; instead compare against the
      // shipped detail page's OWN escaped description (assertion's second half)
      // and, independently, that the raw card text matches the raw summary once
      // the page's own escaping artifacts (&amp; / &lt;) are unescaped back.
      const unescaped = card.intent.replace(/&lt;/g, '<').replace(/&amp;/g, '&');
      expect(unescaped, `card ${card.name} intent does not match skillSummary`).toBe(summary);
      checked += 1;
    }
    expect(checked).toBeGreaterThan(0);
  });

  it("the unescaped summary equals the target page's description frontmatter", () => {
    const recordByName = new Map(records.map((r) => [r.dirName, r]));
    let checked = 0;
    for (const card of parsed.cards) {
      const record = recordByName.get(card.name);
      const summary = skillSummary(record);
      const pagePath = join(SITE_SKILLS_DIR, card.name + '.md');
      const pageContent = readFileSync(pagePath, 'utf8');
      const escaped = summary.replace(/'/g, "''");
      expect(pageContent, `description frontmatter mismatch for ${card.name}`)
        .toContain(`description: '${escaped}'`);
      checked += 1;
    }
    expect(checked).toBeGreaterThan(0);
  });
});

// ── Assertion 12 — no unescaped < outside a code span ────────────────────────

describe('assertion 12 — no card line contains a raw < before a letter or / outside a code span', () => {
  it('every card intent is free of unescaped HTML-like sequences', () => {
    for (const card of parsed.cards) {
      const intent = card.intent;
      let i = 0;
      while (i < intent.length) {
        if (intent[i] === '`') {
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
            if (next !== undefined && /[a-zA-Z/]/.test(next)) {
              throw new Error(`card ${card.name}: raw < before '${next}' found in intent: ${intent}`);
            }
          }
          i++;
        }
      }
    }
  });

  // The loop above deliberately SKIPS code-span content, so on its own it catches
  // only UNDER-escaping. The mirror defect — OVER-escaping inside an authored code
  // span, turning `` `<connector>` `` into `` `&lt;connector>` `` so the reader
  // sees a literal entity (entities are not decoded inside code spans) — is NOT
  // checked here, deliberately, and this comment exists so nobody assumes it is.
  //
  // It cannot manifest on this page. A card's intent is `skillSummary`'s FIRST
  // SENTENCE, capped, and measurement says **0 of 111** card intents contain a
  // code span at all — every authored span in the corpus falls after the first
  // sentence. A test here would be vacuous, and a `spansChecked > 0` guard on it
  // fails outright.
  //
  // The risk is real on the DETAIL pages, which render the full description:
  // **70 of 111** carry a code span, producing 579 spans in total. It is asserted
  // there instead — see `gen-skills.test.mjs`, "no rendered code span contains an
  // HTML entity". Keeping the check where the construct actually occurs is what
  // makes it able to fail.
});

// ── Assertion 13 — marker, manifest row, generatedPaths, no generatedAt ──────

describe('assertion 13 — marker present; manifest carries the index row; no generatedAt', () => {
  it('the generated marker is present in index.md', () => {
    expect(indexContent).toContain('generated \u2014 do not edit');
  });

  it('the manifest carries an entry whose dest is the index page', () => {
    const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
    const indexEntry = manifest.entries.find(
      (e) => e.dest === 'site/src/content/docs/skills/index.md'
    );
    expect(indexEntry, 'no manifest entry for the index page').toBeDefined();
  });

  it('generatedPaths lists the index page', () => {
    const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
    expect(manifest.generatedPaths).toContain('site/src/content/docs/skills/index.md');
  });

  it('the manifest still has no generatedAt field', () => {
    const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
    expect(manifest).not.toHaveProperty('generatedAt');
    const raw = readFileSync(MANIFEST_PATH, 'utf8');
    expect(raw).not.toContain('generatedAt');
  });
});

// ── Assertion 14 — byte comparison of index.md across two generator runs ────

describe('assertion 14 — index.md is byte-identical across two generator runs', () => {
  it('re-running the generator leaves index.md byte-identical (buffer comparison, not git diff)', () => {
    execSync(`node ${GEN_SKILLS_SCRIPT}`, { cwd: SITE_ROOT, stdio: 'pipe' });
    const run1 = readFileSync(INDEX_PATH);

    execSync(`node ${GEN_SKILLS_SCRIPT}`, { cwd: SITE_ROOT, stdio: 'pipe' });
    const run2 = readFileSync(INDEX_PATH);

    expect(run2.equals(run1)).toBe(true);
  });
});

// ── Assertion 15 — divergence note ────────────────────────────────────────────

describe('assertion 15 — divergence note present, before the first ## , links to /reference/skills/', () => {
  it('is present in the page', () => {
    expect(indexContent).toContain('> **Note:**');
  });

  it('sits before the first ## heading', () => {
    const noteIdx = indexContent.indexOf('> **Note:**');
    const firstH2Idx = indexContent.indexOf('\n## ');
    expect(noteIdx).toBeGreaterThan(-1);
    expect(firstH2Idx).toBeGreaterThan(-1);
    expect(noteIdx).toBeLessThan(firstH2Idx);
  });

  it('links to /reference/skills/', () => {
    const noteLine = indexLines.find((l) => l.startsWith('> **Note:**'));
    expect(noteLine).toBeDefined();
    expect(noteLine).toContain('/reference/skills/');
  });
});
