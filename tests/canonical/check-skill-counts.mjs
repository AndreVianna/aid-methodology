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
//
// HISTORICAL QUOTES. A line that deliberately quotes a superseded number must carry the
// marker `count-history` (in a comment or inline). The marker is per line and is reported,
// so it cannot spread silently.
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
  [/\b(\d+) shipped (?:user-facing )?skills\b/g, () => c.directories, 'corpus total'],
  // `curated` must be followed by a skill-ish noun. Bare `\d+ curated` matched
  // "8 curated domains" (KB domains) and "feature-014 curated them" -- neither is a
  // skill count. A guard that cries wolf gets its real findings ignored.
  [/\b(\d+) curated (?:pipeline|skills?|non-catalog|and|\/)/g, () => c.curatedOnly, 'curated (non-catalog)'],
  [/\b(\d+) curated\b(?= *[-—,.)]| skills)/g, () => c.curatedOnly, 'curated (non-catalog)'],
  [/\b(\d+) verb-first\b/g, () => c.shortcuts, 'emitting shortcuts'],
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
 */
const HISTORY_SHAPES = [
  /^\s*\|\s*\d+(?:\.\d+)?\s*\|\s*\d{4}-\d{2}-\d{2}\s*\|/, // versioned/dated table row
  /^\s*-\s*\d{4}-\d{2}-\d{2}\s*:/,                        // dated history bullet
];

const wrong = [];
const marked = [];
let history = 0;
let checked = 0;

for (const file of files) {
  const rel = relative(REPO_ROOT, file).split(sep).join('/');
  const lines = readFileSync(file, 'utf8').split('\n');
  lines.forEach((line, i) => {
    if (HISTORY_SHAPES.some((re) => re.test(line))) {
      history++;
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
          marked.push(`${rel}:${i + 1}  "${m[0]}"  (${what}, historical)`);
        } else {
          wrong.push(`${rel}:${i + 1}  "${m[0]}"  ${what} should be ${want}`);
        }
      }
    }
  });
}

if (process.argv.includes('--list')) {
  console.log(JSON.stringify(c, null, 2));
}

console.log(`=== repo-wide skill-count guard ===`);
console.log(`Files scanned : ${files.length}`);
console.log(`Claims checked: ${checked}`);
console.log(`History lines : ${history} (dated rows/bullets, skipped by shape)`);
console.log(`Marked history: ${marked.length}`);
if (marked.length) for (const m of marked) console.log(`  [history] ${m}`);

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

// Non-vacuity: a guard that scans nothing passes trivially.
if (checked < 20) {
  console.log(`\nFAIL: only ${checked} claims checked — the scan is not reaching the corpus.`);
  process.exit(1);
}
console.log(`\nAll ${checked} stated skill counts agree with the derivation.`);
