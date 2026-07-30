// Guards for the skill-count triple (delivery-006 / task-054).
//
// Every reader-facing claim about how many skills AID ships is checked here against
// ONE derivation, `deriveSkillCounts`. Nothing may hand-count.
//
// This exists because the same three numbers were written by hand into five places —
// gen-reference.mjs's header comments, two content pages, and a test's fixtures — and
// drifted independently until the home page promised "92 skills" while the site
// shipped 111 cards. That is the KI-005 class, and delivery-001 closed one instance
// of it by re-deriving a test's roster assertions. This closes the reader-facing half.
//
// A wrong number is now a red build rather than something a reader discovers.

import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { REPO_ROOT, CANONICAL_SKILLS_DIR } from '../skills/paths.mjs';
import { deriveSkillCounts } from '../skills/skill-counts.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../..');
const DOCS = join(SITE_ROOT, 'src', 'content', 'docs');

const counts = deriveSkillCounts(REPO_ROOT);

/**
 * Hand-authored pages that state a roster claim, and must track the derivation.
 *
 * This list started as just `index.mdx` and `reference/overview.md` — the two pages
 * work-level Q4 named. Review found two more the guard was blind to: `guides/
 * maintainer.mdx` still claimed "92 skills, 9 agents", and `concepts/faq.md` still
 * claimed "76 shortcut skills". A guard that covers only the pages someone already
 * thought of is not a guard against drift, so every hand-authored page that states a
 * roster claim is listed here, and `discovers no unguarded claim` below fails if a new
 * one appears anywhere under `docs/`.
 */
const CLAIM_PAGES = [
  join(DOCS, 'index.mdx'),
  join(DOCS, 'reference', 'overview.md'),
  join(DOCS, 'reference', 'glossary.md'),
  join(DOCS, 'reference', 'repository-structure.md'),
  join(DOCS, 'concepts', 'methodology.md'),
  join(DOCS, 'concepts', 'faq.md'),
  join(DOCS, 'guides', 'maintainer.mdx'),
];

/** Generated pages — derived at build time, so not hand-authored claims. */
const GENERATED_PAGES = ['reference/skills.md', 'skills/'];

describe('deriveSkillCounts — internal consistency', () => {
  it('finds a plausible corpus, with no literal count asserted', () => {
    // Floors rather than numbers: these move when the roster does, but an empty or
    // nearly-empty read means a broken path, not a smaller corpus.
    expect(counts.directories).toBeGreaterThan(50);
    expect(counts.curated).toBeGreaterThan(5);
    expect(counts.shortcuts).toBeGreaterThan(20);
    expect(counts.catalogRows).toBeGreaterThan(counts.shortcuts);
  });

  it('classic is curated minus exactly the router and the Q&A alias', () => {
    expect(counts.curated - counts.classic).toBe(2);
    expect(counts.curatedNames).toContain('aid-triage');
    expect(counts.curatedNames).toContain('aid-ask');
  });

  it('every catalog row either emits a shortcut or is a repurpose re-registration', () => {
    expect(counts.shortcuts + counts.repurposed).toBe(counts.catalogRows);
    expect(counts.repurposed).toBeGreaterThan(0);
  });

  it('every curated and shortcut name has a directory on disk', () => {
    const onDisk = new Set(
      readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory()).map((e) => e.name),
    );
    expect(counts.curatedNames.filter((n) => !onDisk.has(n))).toEqual([]);
    expect(counts.shortcutNames.filter((n) => !onDisk.has(n))).toEqual([]);
    // Non-vacuity: the sets are real, so the filters above had something to check.
    expect(counts.curatedNames.length + counts.shortcutNames.length).toBeGreaterThan(50);
  });

  it('decomposes the corpus without double-counting: curatedOnly + catalogRows = directories', () => {
    // THE identity every reader-facing decomposition depends on. `curated` counts four
    // skills that are also catalog rows, so a sentence built from it does not sum — which
    // is exactly the defect this guard now prevents: the home page briefly read
    // "111 skills — 19 classic … and 64 verb-first", i.e. 85, for a 111-skill corpus.
    expect(counts.curatedOnly + counts.catalogRows).toBe(counts.directories);
    // And the overlap is real, so the distinction is not academic.
    expect(counts.curated - counts.curatedOnly).toBe(counts.classicRepurposed);
    expect(counts.classicRepurposed).toBeGreaterThan(0);
  });

  it('counts the repurpose rows that re-register a curated skill', () => {
    // The reference page states this in prose. It was hard-coded as "the 4 classic
    // re-registered skills" — correct, but hand-counted in reader-facing output.
    expect(counts.classicRepurposed).toBeGreaterThan(0);
    expect(counts.classicRepurposed).toBeLessThanOrEqual(counts.repurposed);
    expect(counts.classicRepurposed).toBeLessThanOrEqual(counts.curated);
  });

  it('agrees with every count the reference page renders', () => {
    // The generated page derives its own numbers at build time. If this module and
    // that generator ever disagree, one of them is lying to a reader. Each claim is
    // checked only when present, so task-057's hollowing-out does not force a
    // rewrite here — but `checked` proves at least one claim was really compared,
    // so a page that renders nothing cannot pass this by being empty.
    const page = readFileSync(join(DOCS, 'reference', 'skills.md'), 'utf8');
    const claims = [
      [/\*\*(\d+) skill directories\*\*/, counts.directories],
      [/\*\*(\d+) classic\b/, counts.classic],
      [/\*\*(\d+) engine-driven direct-entry shortcut/, counts.shortcuts],
      [/(\d+) of the rows \(/, counts.repurposed],
      [/— the (\d+) classic\s+re-registered/, counts.classicRepurposed],
    ];
    let checked = 0;
    for (const [re, expected] of claims) {
      const m = re.exec(page);
      if (m) {
        expect(Number(m[1]), `page claim ${re}`).toBe(expected);
        checked++;
      }
    }
    if (checked === 0) {
      // Page hollowed out (task-057) — then it must still carry the narrative that
      // replaced the roster, rather than being empty or missing.
      expect(page).toMatch(/APPROVAL-HALT/);
    }
  });
});

describe('hand-authored pages quote the derived triple, not a hand-counted one', () => {
  it('the pages under test exist', () => {
    for (const p of CLAIM_PAGES) expect(existsSync(p), p).toBe(true);
    expect(CLAIM_PAGES.length).toBeGreaterThan(1);
  });

  // The specific stale values that shipped, named so a regression to them is obvious
  // rather than merely "a number changed". 92/14/76 were the claims; 111/19/64 are real.
  it('no page still claims the superseded 92 / 14 classic / 76 triple', () => {
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      expect(text, `${p}: stale total`).not.toMatch(/\b92 (?:AID )?skills\b/);
      expect(text, `${p}: stale classic`).not.toMatch(/\b14 classic\b/);
      expect(text, `${p}: stale shortcut count`).not.toMatch(/\b76 verb-first\b/);
    }
  });

  it('every page stating a total states the derived total', () => {
    let checked = 0;
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      for (const m of text.matchAll(/\b(\d+) (?:AID )?skills\b/g)) {
        expect(Number(m[1]), `${p}: "${m[0]}"`).toBe(counts.directories);
        checked++;
      }
    }
    // Non-vacuity: these pages really do state a total, so the loop ran.
    expect(checked).toBeGreaterThan(0);
  });

  it('every page stating a curated count states the SUMMING one (17, not 21 or 19)', () => {
    // "N curated" must be curatedOnly. Stating `curated` (21) or `classic` (19) here is
    // the double-count that stopped the home page's own sentence from adding up.
    let checked = 0;
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      for (const m of text.matchAll(/\b(\d+) curated\b/g)) {
        expect(Number(m[1]), `${p}: "${m[0]}"`).toBe(counts.curatedOnly);
        checked++;
      }
    }
    expect(checked).toBeGreaterThan(0);
  });

  it('no hand-authored page decomposes the corpus with a classic count', () => {
    // "N classic" is a valid internal figure but not a valid reader-facing SUMMAND, for
    // the reason above. The pages now say "17 curated + 94 catalog" instead.
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      expect(text, `${p}: states a classic count`).not.toMatch(/\b\d+ classic pipeline\b/);
    }
  });

  it('every page stating a shortcut count states the derived shortcut count', () => {
    let checked = 0;
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      for (const re of [/\b(\d+) verb-first\b/g, /\b(\d+) shortcut skills\b/g]) {
        for (const m of text.matchAll(re)) {
          expect(Number(m[1]), `${p}: "${m[0]}"`).toBe(counts.shortcuts);
          checked++;
        }
      }
    }
    expect(checked).toBeGreaterThan(0);
  });

  it('every page stating a catalog-row count states the derived one', () => {
    let checked = 0;
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      for (const m of text.matchAll(/\b(\d+)-row (?:shortcut )?catalog\b/g)) {
        expect(Number(m[1]), `${p}: "${m[0]}"`).toBe(counts.catalogRows);
        checked++;
      }
      for (const m of text.matchAll(/\b(\d+) hand-authored `repurpose`/g)) {
        expect(Number(m[1]), `${p}: "${m[0]}"`).toBe(counts.repurposed);
        checked++;
      }
    }
    expect(checked).toBeGreaterThan(0);
  });

  it('discovers no unguarded roster claim anywhere under docs/', () => {
    // The guard above only sees pages someone listed. This walks the whole tree, so a
    // NEW page stating a roster claim fails here instead of shipping unchecked — which is
    // how guides/maintainer.mdx kept "92 skills" and concepts/faq.md kept "76 shortcut
    // skills" through a delivery whose whole purpose was correcting exactly those numbers.
    const guarded = new Set(CLAIM_PAGES);
    const CLAIM = /\b\d+ (?:AID )?skills\b|\b\d+ curated\b|\b\d+ classic\b|\b\d+ verb-first\b|\b\d+ shortcut skills\b/;
    const unguarded = [];
    const walk = (dir) => {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        const full = join(dir, e.name);
        if (e.isDirectory()) {
          walk(full);
        } else if (/\.mdx?$/.test(e.name)) {
          const rel = full.slice(DOCS.length + 1).replace(/\\/g, '/');
          if (GENERATED_PAGES.some((g) => rel.startsWith(g))) continue;
          if (guarded.has(full)) continue;
          const text = readFileSync(full, 'utf8');
          const hit = CLAIM.exec(text);
          if (hit) unguarded.push(`${rel}: "${hit[0]}"`);
        }
      }
    };
    walk(DOCS);
    expect(
      unguarded,
      'these pages state a roster claim but are not in CLAIM_PAGES — add them',
    ).toEqual([]);
    // Non-vacuity: the walk really visited files and really skipped the guarded ones.
    expect(guarded.size).toBeGreaterThan(5);
  });
});

describe('the roster has one home', () => {
  it('gen-reference.mjs imports the roster instead of declaring it', () => {
    const src = readFileSync(join(SITE_ROOT, 'scripts', 'gen-reference.mjs'), 'utf8');
    expect(src).toMatch(/import \{ SKILL_GROUPS \} from '\.\/skills\/curated-roster\.mjs'/);
    // The inline declaration is gone, so there is no second roster to drift.
    expect(src).not.toMatch(/^const SKILL_GROUPS = \[/m);
  });

  // Skill-count SHAPES, not specific stale values. An earlier version of this guard
  // grepped for the two literal strings `16 classic` and `94 skill directories`, which
  // is only a guard against the exact drift that already happened: it sailed past
  // `67 near-identical H3 blocks` (real: 64) sitting unmarked in the same file, and
  // would have sailed past the next wrong number too. These patterns catch any count
  // adjacent to a skill-ish noun, so a NEW hand-count is caught as readily as the old.
  const COUNT_SHAPES = [
    /\b\d+\s+classic\b/,
    /\b\d+\s+skill directories\b/,
    /\b\d+\s+(?:AID\s+)?skills\b/,
    /\b\d+\s+(?:[\w-]+\s+)?shortcuts?\b/,
    /\b\d+\s+near-identical\b/,
  ];

  /** Files that must state no skill count outside a `KI-003`-marked line. */
  const NO_COUNT_FILES = [
    join(SITE_ROOT, 'scripts', 'gen-reference.mjs'),
    join(SITE_ROOT, 'scripts', 'skills', 'curated-roster.mjs'),
    join(SITE_ROOT, 'scripts', 'skills', 'skill-counts.mjs'),
  ];

  it('states no skill count outside a KI-003-marked line (KI-003)', () => {
    // Some lines quote a superseded number on purpose, to explain what went wrong.
    // Those are marked `KI-003`; every other line must be free of a stated count.
    // Keying the exemption on the marker rather than on a line range means it cannot
    // silently widen as the file is edited.
    let exempted = 0;
    for (const file of NO_COUNT_FILES) {
      const lines = readFileSync(file, 'utf8').split('\n');
      const kept = lines.filter((l) => !l.includes('KI-003'));
      exempted += lines.length - kept.length;
      for (const [i, line] of kept.entries()) {
        for (const shape of COUNT_SHAPES) {
          expect(line, `${file}: unmarked count near line ${i + 1}: "${line.trim()}"`)
            .not.toMatch(shape);
        }
      }
    }
    // Non-vacuity: the exemption removed something, so the marker really is in use —
    // and each file was actually read.
    expect(exempted).toBeGreaterThan(0);
    expect(NO_COUNT_FILES.length).toBeGreaterThan(2);
  });

  it('the count shapes actually match the drift they are meant to catch', () => {
    // Guards the guard. Each shape is proved against the literal text that shipped, so
    // a future refactor cannot quietly neuter a pattern into matching nothing.
    const regressions = [
      '// reference/skills.md — 94 skill directories (16 classic + aid-triage',
      "// page — individually they'd be 67 near-identical H3 blocks of pure noise.",
      '  // The 64 direct-entry shortcuts are rendered as an H3 family-summary table',
      'the home page promised 92 skills while the site shipped 111 cards.',
    ];
    for (const text of regressions) {
      expect(
        COUNT_SHAPES.some((s) => s.test(text)),
        `no shape catches: ${text}`,
      ).toBe(true);
    }
  });
});
