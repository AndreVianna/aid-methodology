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
import { resolve, dirname, join, basename } from 'node:path';
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
    // The generated page derives its own numbers independently, at build time. If that
    // generator and this module ever disagree, one of them is lying to a reader.
    //
    // STRICT, deliberately. This test used to skip any claim whose regex found nothing
    // (`if (m)`), which reads as tolerant of the page evolving but is really tolerant of
    // the TEST rotting: task-057 reworded the page and four of the five regexes silently
    // stopped matching, leaving one claim compared out of five and a `checked === 0`
    // fallback that could never fire. Coverage fell by 80% and the suite stayed green.
    //
    // So a missing claim is now a failure, not a skip. If the page's wording changes
    // again, this test says so instead of quietly measuring less.
    const page = readFileSync(join(DOCS, 'reference', 'skills.md'), 'utf8');
    const claims = [
      ['corpus total', /all \*\*(\d+)\*\* skills/, counts.directories],
      ['emitting shortcuts', /\*\*(\d+) engine-driven verb-first shortcut skills\*\*/, counts.shortcuts],
      ['catalog rows', /\((\d+) rows total/, counts.catalogRows],
      ['repurpose rows', /the other (\d+) are `repurpose/, counts.repurposed],
      ['classic re-registered', /the (\d+) classic re-registered/, counts.classicRepurposed],
    ];
    const missing = [];
    for (const [what, re, expected] of claims) {
      const m = re.exec(page);
      if (!m) {
        missing.push(`${what} (${re})`);
        continue;
      }
      expect(Number(m[1]), `reference/skills.md ${what}`).toBe(expected);
    }
    expect(missing, 'reference/skills.md no longer states these — reword the regex or the page').toEqual([]);

    // The narrative the roster was traded for must still be there (task-057).
    expect(page).toMatch(/APPROVAL-HALT/);
  });
});

describe('hand-authored pages state no superseded or unguarded claim', () => {
  it('the pages under test exist', () => {
    for (const p of CLAIM_PAGES) expect(existsSync(p), p).toBe(true);
    expect(CLAIM_PAGES.length).toBeGreaterThan(1);
  });

  it('no page still claims the superseded 92 / 14 classic / 76 triple', () => {
    for (const p of CLAIM_PAGES) {
      const text = readFileSync(p, 'utf8');
      expect(text, `${p}: stale total`).not.toMatch(/\b92 (?:AID )?skills\b/);
      expect(text, `${p}: stale classic`).not.toMatch(/\b14 classic\b/);
      expect(text, `${p}: stale shortcut count`).not.toMatch(/\b76 verb-first\b/);
    }
  });

  it('discovers no unguarded roster claim anywhere under docs/', () => {
    // The guard above only sees pages someone listed. This walks the whole tree, so a
    // NEW page stating a roster claim fails here instead of shipping unchecked — which is
    // how guides/maintainer.mdx kept "92 skills" and concepts/faq.md kept "76 shortcut
    // skills" through a delivery whose whole purpose was correcting exactly those numbers.
    const guarded = new Set(CLAIM_PAGES);
    // Built FROM the claim vocabulary rather than hand-listed beside it. This was a 5-shape
    // regex sitting next to an 18-entry table, so 11 phrasings were invisible to the very
    // check whose comment promised it "fails on any digit-plus-roster-noun shape NOT in this
    // list" — `and N others` among them, the exact shape the table was extended for.
    const CLAIM = new RegExp(CLAIM_PATTERNS.map((c) => c.re.source).join('|'));
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

/**
 * Every phrasing in which a page states a skill-count claim, and what it must equal.
 *
 * This replaces four separate per-phrasing tests that each grepped ONE wording. The
 * gate review showed why that shape fails: the guard checked `N skills`, `N curated`,
 * `N classic` and `N verb-first` and was blind to `N skill directories`,
 * `N skill definitions`, `and N others`, `58 canonical names + 36 aliases` and
 * `N shortcut-catalog skills` — five more phrasings live on three of the pages it
 * already read, including `and 61 others`, a number delivery-006 itself wrote.
 *
 * So the vocabulary is the unit now, not the test. Adding a phrasing here extends coverage
 * to all seven pages at once, and `discovers no unguarded roster claim` (above) builds its
 * regex FROM this table -- so it flags a page stating any phrasing that IS in this list but
 * is not on a guarded page. A phrasing nobody has added here is still invisible to it; the
 * table is the coverage boundary, and that is a limit rather than a guarantee.
 */
const CLAIM_PATTERNS = [
  { re: /\b(\d+) (?:AID )?skills\b/g, of: (c) => c.directories, what: 'corpus total' },
  { re: /\b(\d+) skill directories\b/g, of: (c) => c.directories, what: 'corpus total' },
  { re: /\b(\d+) skill definitions\b/g, of: (c) => c.directories, what: 'corpus total' },
  { re: /\b(\d+) curated\b/g, of: (c) => c.curatedOnly, what: 'curated (non-catalog)' },
  { re: /\b(\d+) verb-first\b/g, of: (c) => c.shortcuts, what: 'emitting shortcuts' },
  { re: /\b(\d+) shortcut skills\b/g, of: (c) => c.shortcuts, what: 'emitting shortcuts' },
  { re: /\b(\d+) engine-driven verb-first shortcut skills\b/g, of: (c) => c.shortcuts, what: 'emitting shortcuts' },
  { re: /\b(\d+)-row (?:shortcut )?catalog\b/g, of: (c) => c.catalogRows, what: 'catalog rows' },
  { re: /\((\d+) rows total\b/g, of: (c) => c.catalogRows, what: 'catalog rows' },
  { re: /\b(\d+) shortcut-catalog skills\b/g, of: (c) => c.catalogRows, what: 'catalog rows' },
  { re: /\b(\d+) catalog skills\b/g, of: (c) => c.catalogRows, what: 'catalog rows' },
  { re: /\b(\d+) hand-authored `repurpose`/g, of: (c) => c.repurposed, what: 'repurpose rows' },
  { re: /the other (\d+) are `repurpose/g, of: (c) => c.repurposed, what: 'repurpose rows' },
  { re: /\b(\d+) `repurpose` skills\b/g, of: (c) => c.repurposed, what: 'repurpose rows' },
  { re: /the (\d+) classic\s+re-registered/g, of: (c) => c.classicRepurposed, what: 'classic re-registered' },
  { re: /\b(\d+) canonical names?\b/g, of: (c) => c.catalogCanonical, what: 'catalog canonical names' },
  { re: /\b(\d+) canonical\b(?! names)/g, of: (c) => c.catalogCanonical, what: 'catalog canonical names' },
  { re: /\b(\d+) aliases\b/g, of: (c) => c.catalogAliases, what: 'catalog aliases' },
];

/** Collect every recognised claim on one page, as {what, stated, expected}. */
function claimsOn(text, c) {
  const found = [];
  for (const { re, of, what } of CLAIM_PATTERNS) {
    for (const m of text.matchAll(new RegExp(re.source, re.flags))) {
      found.push({ what, stated: Number(m[1]), expected: of(c), text: m[0] });
    }
  }
  return found;
}

describe('every roster claim on every page equals the derivation', () => {
  it('states no wrong number, on any page, in any phrasing', () => {
    const wrong = [];
    for (const p of CLAIM_PAGES) {
      for (const cl of claimsOn(readFileSync(p, 'utf8'), counts)) {
        if (cl.stated !== cl.expected) {
          wrong.push(`${basename(p)}: "${cl.text}" — ${cl.what} is ${cl.expected}`);
        }
      }
    }
    expect(wrong).toEqual([]);
  });

  // PER PAGE, not aggregated. The gate review caught the aggregated floor: one page
  // could drop every claim it makes and still pass on its neighbours' claims, which is
  // exactly what task-055's AC-4 says must be impossible.
  it.each(CLAIM_PAGES.map((p) => [basename(p), p]))(
    '%s states at least one checked claim',
    (_name, p) => {
      expect(claimsOn(readFileSync(p, 'utf8'), counts).length).toBeGreaterThan(0);
    },
  );

  it('"and N others" accounts for the skills named beside it', () => {
    // faq.md reads "`/aid-fix`, `/aid-create-api`, `/aid-change-ui`, and 61 others".
    // 3 + 61 must equal the shortcut count -- a claim no single-number check can make,
    // and the phrasing the old guard was completely blind to.
    let checked = 0;
    for (const p of CLAIM_PAGES) {
      for (const line of readFileSync(p, 'utf8').split('\n')) {
        const m = /and (\d+) others\b/.exec(line);
        if (!m) continue;
        const named = (line.slice(0, m.index).match(/`\/aid-[a-z-]+`/g) || []).length;
        expect(named + Number(m[1]), `${basename(p)}: ${named} named + ${m[1]} others`)
          .toBe(counts.shortcuts);
        checked++;
      }
    }
    expect(checked).toBeGreaterThan(0);
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
    // `curated` reached SUPERSEDED_BY_SHAPE (the half that PERMITS a number) but never
    // this list (the half that FINDS one), so unmarked hand-counts sat in a file declared
    // to state none. An allowlist entry with no matching finder guards nothing.
    /\b\d+\s+curated\b/,
    // Negative lookbehind on `-`: "work-005 collapse skills" is a work id, not a count.
    /(?<!-)\b\d+\s+collapse skills\b/,
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
    // The marker is a BOUNDED opt-out, not a free pass. Two bounds, because as first
    // written it was neither: any line could silence any count just by naming KI-003.
    //   (a) an exempted line may only quote SUPERSEDED values — the numbers that actually
    //       drifted — so the marker cannot be used to excuse a wrong CURRENT count;
    //   (b) the total number of exempted lines is capped, so the exemption cannot creep
    //       file-wide one line at a time.
    // The allowlist is PER SHAPE, not a flat set of numbers. A flat set was the first
    // attempt and it did not work: it held 94, 21, 19 and 4 — which are the CURRENT values
    // of catalogRows, curated, classic and classicRepurposed — so a marked line reading
    // "94 classic skills" passed while classic is 19. A number is only "superseded" with
    // respect to the thing it counts, so that is how it is checked.
    const SUPERSEDED_BY_SHAPE = [
      // Negative lookahead: "N classic re-registered skills" counts a DIFFERENT noun
      // (classicRepurposed), so it must not be judged against the classic-skills history.
      [/\b(\d+)\s+classic\b(?!\s+re-registered)/g, [14, 15, 16]],
      [/\b(\d+)\s+classic\s+re-registered/g, [4]],
      [/\b(\d+)\s+skill directories\b/g, [92, 94]],
      [/\b(\d+)\s+(?:AID\s+)?skills\b/g, [92, 94]],
      [/\b(\d+)\s+(?:[\w-]+\s+)?shortcuts?\b/g, [76]],
      [/\b(\d+)\s+near-identical\b/g, [67]],
      [/\b(\d+)\s+curated\b/g, [21]],
    ];
    let exempted = 0;
    for (const file of NO_COUNT_FILES) {
      const lines = readFileSync(file, 'utf8').split('\n');
      const kept = lines.filter((l) => !l.includes('KI-003'));
      for (const l of lines.filter((l) => l.includes('KI-003'))) {
        for (const [shape, allowed] of SUPERSEDED_BY_SHAPE) {
          // matchAll, not exec: exec returns only the FIRST match on the line, so a marked
          // line could smuggle a second, current, wrong number past the check entirely.
          for (const m of l.matchAll(new RegExp(shape.source, shape.flags))) {
            const n = Number(m[1]);
            expect(
              allowed.includes(n),
              `${file}: KI-003-marked line quotes "${m[0]}" — ${n} is not a superseded value `
                + `for that noun (allowed: ${allowed.join(', ')}). The marker exempts historical `
                + 'numbers, not current or invented ones.',
            ).toBe(true);
          }
        }
      }
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
    // Bound (b): the opt-out cannot creep. Raising this ceiling should require a reason.
    expect(exempted, 'too many KI-003 exemptions — the opt-out is creeping').toBeLessThanOrEqual(8);
  });

  it('the count shapes actually match the drift they are meant to catch', () => {
    // Guards the guard. Each shape is proved against the literal text that shipped, so
    // a future refactor cannot quietly neuter a pattern into matching nothing.
    const regressions = [
      '// reference/skills.md — 94 skill directories (16 classic + aid-triage',
      "// page — individually they'd be 67 near-identical H3 blocks of pure noise.",
      '  // The 64 direct-entry shortcuts are rendered as an H3 family-summary table',
      'the home page promised 92 skills while the site shipped 111 cards.',
      '  // 17 curated skills across four groups',            // `N curated`
      'plus 26 collapse skills from work-005',                 // `N collapse skills`
    ];
    for (const text of regressions) {
      expect(
        COUNT_SHAPES.some((s) => s.test(text)),
        `no shape catches: ${text}`,
      ).toBe(true);
    }
  });
});
