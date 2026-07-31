#!/usr/bin/env node
// check-skill-counts.mjs — REPO-WIDE guard for every stated skill count.
//
// WHY THIS EXISTS, AND WHY IT IS AT REPO LEVEL RATHER THAN UNDER site/.
//
// delivery-006 built a derivation (site/scripts/skills/skill-counts.mjs) and a guard
// (site/scripts/__tests__/skill-counts.test.mjs) to end the KI-005 class: the same skill
// counts hand-written into many places and drifting independently. Two gate cycles then
// found the class alive and well, in file after file, and the reason was structural rather
// than careless:
//
//   THE GUARD WAS ROOTED AT site/. Its CLAIM_PAGES could only name pages under
//   site/src/content/docs/. Every other hand-maintained statement of a skill count in the
//   repository -- README.md, docs/, .aid/knowledge/, canonical/, the repo-local maintainer
//   skills -- was outside anything it could see. So the guard was not weak; it was
//   pointed at a fraction of the surface.
//
// That is why a gate-fix commit could write "17 curated + aid-triage + aid-ask + 64 + 30"
// (= 113 for a 111-skill corpus) into .claude/skills/generate-profile/SKILL.md and pass
// every check: the file is not under site/. It is why architecture.md could be corrected
// in one sentence while its own table 18 lines below kept saying 76. It is why
// module-map.md, test-landscape.md and decisions.md drifted freely.
//
// So the fix is not another assertion. It is moving the guard's ROOT to the repository and
// deriving from the one derivation, everywhere. Adding a phrasing or a path here extends
// coverage across the whole repo at once.
//
// SCOPE. Permanent artifacts only:
//   included  README.md, docs/, .aid/knowledge/, canonical/, .claude/skills/<repo-local>/,
//             site/src/content/docs/
//   excluded  .aid/works/**        transient by project rule, and legitimately quotes
//                                  historical values in KI entries and STATE history
//             profiles/**          rendered from canonical/; byte-identity covers them
//             .claude/aid/, .cursor/  dogfood renders of canonical/; ditto
//             site/dist/, node_modules/
//   NOT YET SCANNED (stated so the SCOPE above is not read as exhaustive):
//             site/scripts/, tests/, dashboard/, lib/, bin/, packages/ — code trees whose
//             counts live in comments. site/scripts/ is covered separately by
//             site/scripts/__tests__/skill-counts.test.mjs; the rest are uncovered.
//
// HISTORICAL QUOTES. A line that deliberately quotes a superseded number must carry the
// marker `count-history` (in a comment or inline). It is BOUNDED, because an unbounded
// per-line opt-out is not a guard: every marked line is listed on stdout whether the run
// passes or fails, and the total is capped (MARKER_CAP) so the exemption cannot creep
// file-by-file. Raising the cap should take a reason in the commit message.
//
// Usage: node tests/canonical/check-skill-counts.mjs [--list]
// Exit 0 clean, 1 on any wrong or unmarked-stale count.

import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join, resolve, dirname, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const MARKER = 'count-history';

const { deriveSkillCounts } = await import(
  new URL('../../site/scripts/skills/skill-counts.mjs', import.meta.url).href
);
const c = deriveSkillCounts(REPO_ROOT);

/** Every phrasing in which a skill count is stated, and what it must equal. */
const CLAIMS = [
  [/\b(\d+) (?:AID )?skills\b/g, () => c.directories, 'corpus total'],
  [/\b(\d+) skill directories\b/g, () => c.directories, 'corpus total'],
  [/\b(\d+) skill definitions\b/g, () => c.directories, 'corpus total'],
  // `skill directories` as the noun, optionally with a backticked token between it and the
  // digit: "The 76 `aid-<verb>[-<artifact>]` skill directories". Cycle 4 found this live in a
  // KB primary doc while this guard printed "All 169 agree" over it.
  // WITH a backticked name-template between digit and noun, the sentence counts the GENERATED
  // DOORWAY directories ("The N `aid-<verb>[-<artifact>]` skill directories … are emitted by"),
  // not the corpus. Same noun, different quantity — so it maps to shortcuts. The bare form
  // above stays the corpus total. Reading the sentence, not just the noun, is the F3 rule.
  [/\b(\d+)\s+`[^`]+`\s+skill directories\b/g, () => c.shortcuts, 'emitting shortcuts'],
  // An adjective between the digit and `skills`, with an optional `~`: "~92 prompt-driven
  // skills". Bounded to a NAMED set of adjectives on purpose — an open `\w+` run starts
  // swallowing "30 hand-authored repurpose skills", which counts something else entirely.
  [/\b~?(\d+) (?:prompt-driven|shipped|generated|classic pipeline) skills\b/g, () => c.directories, 'corpus total'],
  // These three phrasings were MISSING, and they are precisely the three live falsehoods
  // that survived in architecture.md -- the file this guard's own commit message used as
  // its motivating example. A digit can be separated from its noun by markdown emphasis or
  // a backticked token, which defeats every plain-adjacency pattern.
  [/\b(\d+) dirs\b/g, () => c.directories, 'corpus total'],
  // Negative lookbehind on `/`: "site/scripts/skills/* (12)" is a MODULE count, not a skill
  // count. Only a bare `skills/` — i.e. canonical/skills/ referred to as itself — qualifies.
  [/(?<![\w/*])`?skills\/`?\s*\((\d+)\)/g, () => c.directories, 'corpus total'],
  // Negative lookahead on `repurpose`: "30 `repurpose` skills" is the repurpose count and has
  // its own pattern above. Without this, the shortcut pattern claims it and reports a CORRECT
  // number as wrong — and a guard's false positives cost it the credibility its real findings
  // depend on. Three of the original 55 were exactly this kind of noise.
  [/\b(\d+) `(?!repurpose`)[^`]+` skills\b/g, () => c.shortcuts, 'emitting shortcuts'],
  [/\b(\d+) shipped (?:user-facing )?skills\b/g, () => c.directories, 'corpus total'],
  // `curated` must be followed by a skill-ish noun. Bare `\d+ curated` matched
  // "8 curated domains" (KB domains) and "feature-014 curated them" -- neither is a
  // skill count. A guard that cries wolf gets its real findings ignored.
  [/\b(\d+) curated (?:pipeline|skills?|non-catalog|and|\/)/g, () => c.curatedOnly, 'curated (non-catalog)'],
  [/\b(\d+) curated\b(?= *[-—,.)]| skills)/g, () => c.curatedOnly, 'curated (non-catalog)'],
  [/\b(\d+) verb-first\b/g, () => c.shortcuts, 'emitting shortcuts'],
  // Bare `N shortcuts`, and the README's own "N pipeline / on-demand / router skills" phrasing.
  // Both were live in README.md and docs/ with CORRECT values, checked by nothing — a coverage
  // gap rather than a defect, which is the more dangerous of the two because it looks clean.
  // Negative lookbehind on `: ` — a YAML scalar. The wrapped-line pass joins `version: 1` in
  // shortcut-catalog.yml with the next line and manufactures "1 shortcuts" out of nothing.
  [/(?<!:\s)\b(\d+) shortcuts\b/g, () => c.shortcuts, 'emitting shortcuts'],
  [/\b(\d+) pipeline \/ on-demand \/ router skills\b/g, () => c.curatedOnly, 'curated (non-catalog)'],
  [/\b(\d+) shortcut skills\b/g, () => c.shortcuts, 'emitting shortcuts'],
  [/\b(\d+) (?:verb-first )?(?:shortcut )?doorways\b/g, () => c.shortcuts, 'emitting shortcuts'],
  [/\b(\d+)-row (?:shortcut )?catalog\b/g, () => c.catalogRows, 'catalog rows'],
  [/\b(\d+) catalog skills\b/g, () => c.catalogRows, 'catalog rows'],
  [/\b(\d+) shortcut-catalog skills\b/g, () => c.catalogRows, 'catalog rows'],
  [/\((\d+) rows total/g, () => c.catalogRows, 'catalog rows'],
  [/\b(\d+) hand-authored `?repurpose/g, () => c.repurposed, 'repurpose rows'],
  [/the other (\d+) are `repurpose/g, () => c.repurposed, 'repurpose rows'],
  [/\b(\d+) `repurpose` (?:rows|skills)\b/g, () => c.repurposed, 'repurpose rows'],
  [/the (\d+) classic\s+re-registered/g, () => c.classicRepurposed, 'classic re-registered'],
  [/\b(\d+) canonical names\b/g, () => c.catalogCanonical, 'catalog canonical names'],
  [/\b(\d+) aliases\b/g, () => c.catalogAliases, 'catalog aliases'],
];

/**
 * What a marked line is allowed to say, PER QUANTITY.
 *
 * The marker alone was not a bound: mutation-proved, a line reading "ships 999 skills
 * <!-- count-history -->" was accepted and labelled `[history]`. So the marker exempts a
 * number only if it is a value this quantity ACTUALLY held — the figures below are the ones
 * this repository's own history records. Anything else is a wrong number wearing a marker,
 * and is reported as wrong.
 *
 * Keyed on the quantity (the CLAIMS label), not on the file or the line, for the same reason
 * the history rule keys on line shape: 94 is superseded for the corpus and meaningless for
 * the classic count, so a flat set of numbers cannot express the constraint.
 */
const SUPERSEDED = {
  'corpus total': [10, 12, 13, 14, 67, 82, 92, 94],
  'emitting shortcuts': [51, 67, 76],
  'catalog rows': [69, 80],
  'catalog canonical names': [45, 51],
  'catalog aliases': [24, 29],
  'curated (non-catalog)': [14, 15, 16, 19, 21],
  'repurpose rows': [2, 4],
  'classic re-registered': [4],
};

/** Files and trees the guard reads. */
const INCLUDE_FILES = ['README.md'];
/**
 * Files excluded because they are LOGS END TO END, not documents that describe today.
 *
 * `.aid/knowledge/STATE.md` is the KB's Q&A + Review History record: every count in it sits
 * inside a dated round's `**Context:**` / `**Answer:**` / spot-check line and was true when
 * written. `release-tracking.md` is per-release notes: "51 verb-first shortcut skills" is a
 * correct statement about v2.1.0. Marking ~15 lines in each would be noise, and forcing them
 * to today's numbers would make them lie about the past.
 */
const EXCLUDE_FILES = [
  join('.aid', 'knowledge', 'STATE.md'),
  join('.aid', 'knowledge', 'release-tracking.md'),
];

const INCLUDE_TREES = [
  'docs',
  join('.aid', 'knowledge'),
  'canonical',
  join('site', 'src', 'content', 'docs'),
];
/** Repo-local maintainer skills — absent from canonical/, so not covered by any render. */
const INCLUDE_GLOB_SKILLS = join('.claude', 'skills');
const REPO_LOCAL_SKILLS = ['generate-profile', 'release-aid'];

const EXT = /\.(md|mdx|sh|mjs|js|ts|py|yml|yaml)$/;

function walk(dir, acc) {
  if (!existsSync(dir)) return acc;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === 'node_modules' || e.name === 'dist' || e.name === '.git') continue;
      walk(full, acc);
    } else if (EXT.test(e.name)) {
      if (EXCLUDE_FILES.some((x) => full.endsWith(x))) continue;
      acc.push(full);
    }
  }
  return acc;
}

const files = [];
for (const f of INCLUDE_FILES) {
  const p = join(REPO_ROOT, f);
  if (existsSync(p) && statSync(p).isFile()) files.push(p);
}
for (const t of INCLUDE_TREES) walk(join(REPO_ROOT, t), files);
for (const s of REPO_LOCAL_SKILLS) {
  const p = join(REPO_ROOT, INCLUDE_GLOB_SKILLS, s);
  if (existsSync(p)) walk(p, files);
}

/**
 * Line shapes that are RECORDS OF A MOMENT rather than claims about now.
 *
 * A KB Change Log row (`| 1.5 | 2026-07-09 | … skill count 14 -> 82 …`), a dated history
 * bullet (`- 2026-07-09: … 67 verb-first shortcuts`), and a dated review-history row are all
 * *true statements about a past state*. Demanding they equal today's derivation would be
 * demanding they lie, and hand-marking dozens of them would be noise.
 *
 * The distinction is exactly the one the two gate cycles kept tripping over:
 * `architecture.md:531` is a changelog row and correct; `architecture.md:515` is body prose
 * reading "(the 92 shipped skills)" and is a live falsehood. Same file, same number, opposite
 * verdicts — so the guard keys on the LINE'S SHAPE, not on the file.
 *
 * LIMIT, stated rather than implied: the rule is evadable. A live false claim formatted as
 * a dated bullet is skipped. That is accepted — the shapes are conventions this repo's KB
 * actually uses for history, and a reviewer reading a dated line reads it as history too.
 * The guard narrows where drift can hide; it does not make hiding impossible.
 */
const HISTORY_SHAPES = [
  /^\s*\|\s*\d+(?:\.\d+)?\s*\|\s*\d{4}-\d{2}-\d{2}\s*\|/, // versioned/dated table row
  /^\s*-\s*\d{4}-\d{2}-\d{2}\s*:/,                        // dated history bullet
];

const wrong = [];
const marked = [];
let history = 0;
const historyLines = [];
let checked = 0;

for (const file of files) {
  const rel = relative(REPO_ROOT, file).split(sep).join('/');
  const raw = readFileSync(file, 'utf8').split('\n');
  // Each physical line, PLUS that line joined with the next, both de-emphasised.
  //
  // Two mechanisms defeated plain per-line matching, and cycle 4 found live wrong counts
  // hiding behind each. Markdown emphasis breaks digit-noun adjacency, so "**94-row**
  // catalog" matches nothing that "94-row catalog" would. And prose WRAPS: "The 76
  // `aid-<verb>`\n  skill directories" is one claim on two lines. The joined form is
  // reported against the FIRST line, which is where a reader looks.
  //
  // Backticks are deliberately NOT stripped — the repurpose/shortcut lookaheads key on them.
  const deEmphasise = (t) => t.replace(/[*_]{1,3}/g, '');

  // Per-line matches carry accurate line numbers. The joined form exists only to catch a
  // claim that STRADDLES the break, so a joined match is reported only when it appears in
  // NEITHER constituent line alone — otherwise every claim would be counted twice (once on
  // its own line, once in the previous line's join), which inflated the claim total to 401
  // and pushed the marker count past its own cap.
  const single = raw.map(deEmphasise);
  const straddling = raw.map((l, i) => {
    if (i + 1 >= raw.length) return '';
    const joined = deEmphasise(`${l} ${raw[i + 1].trim()}`);
    const alone = new Set();
    for (const [re] of CLAIMS) {
      for (const src of [single[i], single[i + 1]]) {
        for (const m of src.matchAll(new RegExp(re.source, re.flags))) alone.add(m[0]);
      }
    }
    // Keep the joined text only if it yields a claim neither line yields by itself.
    for (const [re] of CLAIMS) {
      for (const m of joined.matchAll(new RegExp(re.source, re.flags))) {
        if (!alone.has(m[0])) return joined;
      }
    }
    return '';
  });

  const lines = single.map((l, i) => (straddling[i] ? straddling[i] : l));
  lines.forEach((line, i) => {
    if (HISTORY_SHAPES.some((re) => re.test(line))) {
      history++;
      // Report the ones that actually CARRY a count, not just the count of skipped lines.
      // The rule is evadable by construction (a live false claim formatted as a dated bullet
      // is skipped), so the only defence is that every skip carrying a number is visible and
      // auditable rather than folded into an aggregate.
      for (const [re, , what] of CLAIMS) {
        for (const m of line.matchAll(new RegExp(re.source, re.flags))) {
          historyLines.push(`${rel}:${i + 1}  "${m[0]}"  (${what}, history-shaped line)`);
        }
      }
      return;
    }
    const isMarked = line.includes(MARKER);
    for (const [re, expected, what] of CLAIMS) {
      for (const m of line.matchAll(new RegExp(re.source, re.flags))) {
        const stated = Number(m[1]);
        const want = expected();
        checked++;
        if (stated === want) continue;
        if (isMarked) {
          // A marker exempts a HISTORICAL value, never an arbitrary one.
          if (!(SUPERSEDED[what] || []).includes(stated)) {
            wrong.push(
              `${rel}:${i + 1}  "${m[0]}"  marked \`${MARKER}\` but ${stated} is not a value ` +
                `${what} ever held (${(SUPERSEDED[what] || []).join(', ') || 'none recorded'})`,
            );
            continue;
          }
          marked.push(`${rel}:${i + 1}  "${m[0]}"  (${what}, historical)`);
        } else {
          wrong.push(`${rel}:${i + 1}  "${m[0]}"  ${what} should be ${want}`);
        }
      }
    }
  });
}

/** Cap on `count-history` exemptions. An opt-out that can grow without limit is not bounded. */
const MARKER_CAP = 12;


if (process.argv.includes('--list')) {
  console.log(JSON.stringify(c, null, 2));
}

console.log(`=== repo-wide skill-count guard ===`);
console.log(`Files scanned : ${files.length}`);
console.log(`Claims checked: ${checked}`);
console.log(`History lines : ${history} (dated rows/bullets, skipped by shape)`);
console.log(`  ...of which carry a count: ${historyLines.length}`);
for (const h of historyLines) console.log(`  [shape-skip] ${h}`);
console.log(`Marked history: ${marked.length}`);
if (marked.length) for (const m of marked) console.log(`  [history] ${m}`);

if (marked.length > MARKER_CAP) {
  console.log(`
FAIL: ${marked.length} \`${MARKER}\` exemptions exceeds the cap of ${MARKER_CAP}.`);
  console.log('The marker is for the occasional historical clause, not a way to opt whole');
  console.log('files out. Either the numbers are stale, or the cap needs a deliberate raise.');
  process.exit(1);
}

if (wrong.length) {
  console.log(`\nWRONG COUNTS: ${wrong.length}`);
  for (const w of wrong) console.log(`  ${w}`);
  console.log(
    `\nEach line above states a skill count that disagrees with the single derivation in` +
      `\nsite/scripts/skills/skill-counts.mjs. Correct the number, or -- if the line quotes a` +
      `\nsuperseded value on purpose -- add the marker \`${MARKER}\` to that line.`
  );
  process.exit(1);
}

// Non-vacuity floor. Set near the live figure rather than at a token 20: the point is to
// catch a scan that has silently stopped reaching the corpus (a moved tree, a broken walk,
// a regex refactor that neuters every pattern), and a floor an order of magnitude below the
// real count cannot do that. If a future work legitimately shrinks the corpus -- work-004
// takes it from 111 to 74 -- lower this deliberately and say so in the commit.
const CLAIM_FLOOR = 120;
if (checked < CLAIM_FLOOR) {
  console.log(`\nFAIL: only ${checked} claims checked — the scan is not reaching the corpus.`);
  process.exit(1);
}
console.log(`\nAll ${checked} stated skill counts agree with the derivation.`);
