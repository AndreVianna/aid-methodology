// check-derived-values.mjs — sweep the repository for stated values that disagree with their source.
//
// The engine for `derived-values.mjs`. Registry says WHAT is derived and how to recognise a claim;
// this file walks the tree, matches, and reports file:line with the stated and derived values.
//
// SCANNING DETAILS ARE COPIED FROM check-skill-counts.mjs ON PURPOSE. Each one is there because it
// found a live falsehood that a naive scan missed, and re-deriving them by trial would repeat the
// same three cycles of misses:
//
//   two-line join      A digit can be separated from its noun by a line break. Three stale counts
//                      in this repo spanned lines and survived a per-line sweep; I hit the same
//                      thing by hand and had to fix them manually afterwards.
//   de-emphasis        `**113** directories` and `` `10` agents `` defeat plain adjacency.
//   history shapes     A dated table row or dated bullet is a record of what WAS true. Flagging
//                      those trains a reader to ignore the guard, which costs it the credibility
//                      its real findings depend on.
//   explicit marker    `derived-value-exempt` on a line says "this value is deliberately not the derived
//                      one" -- a superseded figure quoted as history, or an illustrative example.
//                      An escape hatch that must be written down beats a guard people switch off.
//   non-vacuity floor  A scan that silently stops reaching the corpus reports "all agree". The
//                      floor is what makes that failure loud.
//
// SCOPE
//   included  README.md, docs/, .aid/knowledge/, canonical/, site/src/content/docs/, tests/
//   excluded  .aid/works/**       transient by project rule; legitimately quotes historical values
//             profiles/**         rendered from canonical/; byte-identity already covers them
//             .claude/, .cursor/  dogfood renders of canonical/; ditto
//             node_modules, site/dist, .git
//   NOT SCANNED, stated so the list above is not read as exhaustive: site/scripts/, dashboard/,
//             lib/, bin/, packages/ — code trees whose values live in comments.
//
// Usage:  node tests/canonical/check-derived-values.mjs [--verbose]
// Exit:   0 every stated value agrees · 1 at least one disagrees · 2 the scan did not reach the corpus

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildRegistry } from './derived-values.mjs';

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const VERBOSE = process.argv.includes('--verbose');
const MARKER = 'derived-value-exempt';

const INCLUDE_FILES = ['README.md'];
const INCLUDE_TREES = [
  'docs',
  join('.aid', 'knowledge'),
  'canonical',
  join('site', 'src', 'content', 'docs'),
];
// tests/ is deliberately OUT, matching check-skill-counts.mjs's scope. A test file legitimately
// contains fixture values, planted-wrong values used as controls, and prior values quoted in
// comments explaining what a guard now catches. Sweeping it produced six hits, every one of them
// noise of that kind -- and a guard whose findings are mostly noise is one people stop reading.
const EXCLUDE_DIRS = new Set(['node_modules', '.git', 'dist', '.temp', 'fixtures']);
const EXT = /\.(md|mdx|sh|mjs|js|ts|py|yml|yaml)$/;

// A dated row or dated bullet records what WAS true. Same two shapes check-skill-counts.mjs uses.
const HISTORY_SHAPES = [
  /^\s*\|\s*\d+(?:\.\d+)?\s*\|\s*\d{4}-\d{2}-\d{2}\s*\|/,
  /^\s*-\s*\d{4}-\d{2}-\d{2}\s*:/,
  /^\s*\|\s*\d{4}-\d{2}-\d{2}\s*\|/,
  // A row that declares itself superseded records what WAS decided. Editing its number to match
  // today would rewrite the decision rather than record that it changed -- so the guard reads it
  // as history. The correct response to drift here is a NEW row, which is what D27 is.
  /^\s*\|.*Supersede[sd]/i,
];

function walk(dir, acc) {
  let entries;
  try { entries = readdirSync(dir); } catch { return acc; }
  for (const e of entries) {
    if (EXCLUDE_DIRS.has(e)) continue;
    const p = join(dir, e);
    let st;
    try { st = statSync(p); } catch { continue; }
    if (st.isDirectory()) walk(p, acc);
    else if (EXT.test(e)) acc.push(p);
  }
  return acc;
}

const files = [];
for (const f of INCLUDE_FILES) files.push(join(REPO_ROOT, f));
for (const t of INCLUDE_TREES) walk(join(REPO_ROOT, t), files);

/** Strip markdown emphasis and backticks so `**113**` and `` `10` `` match plain patterns. */
const deEmphasise = (s) => s.replace(/\*\*/g, '').replace(/`/g, '');

const registry = buildRegistry(REPO_ROOT);
const wrong = [];
const marked = [];
const historyLines = [];
let checked = 0;

for (const file of files) {
  const rel = relative(REPO_ROOT, file).split(sep).join('/');
  let raw;
  try { raw = readFileSync(file, 'utf8').split('\n'); } catch { continue; }

  for (let i = 0; i < raw.length; i++) {
    // The physical line, and that line joined with the next: a value can be split from its noun by
    // a line break, and the joined form is the only way to see it.
    const first = deEmphasise(raw[i]);
    const candidates = [
      { text: first, lineNo: i + 1 },
      // firstLen is the length of the DE-EMPHASISED first line, not the raw one: the span test
      // below indexes into de-emphasised text, and comparing it against the raw length suppressed
      // nothing, so every finding was reported twice.
      { text: first + ' ' + deEmphasise(raw[i + 1] ?? ''), lineNo: i + 1, joined: true, firstLen: first.length },
    ];

    for (const entry of registry) {
      for (const cand of candidates) {
        const { text, lineNo } = cand;
        const isHistory = HISTORY_SHAPES.some((re) => re.test(raw[i]));
        const isMarked = raw[i].includes(MARKER)
          || (raw[i - 1] ?? '').includes(MARKER)   // a comment directly above the claim
          || (raw[i + 1] ?? '').includes(MARKER);  // or the second half of a joined pair

        if (entry.kind === 'scalar') {
          const want = entry.derive();
          if (want == null) continue;
          for (const re of entry.claims) {
            re.lastIndex = 0;
            let m;
            while ((m = re.exec(text)) !== null) {
              // Only keep a joined match that genuinely STRADDLES the line boundary: it must start
              // before the join point and end after it. Testing only the end still admitted every
              // match that lies wholly in the SECOND line, so each finding was reported twice --
              // once by line N's joined pass and again by line N+1's own pass.
              if (cand.joined && !(m.index < cand.firstLen && m.index + m[0].length > cand.firstLen)) continue;
              const got = m[1];
              if (isHistory) { historyLines.push(`${rel}:${lineNo}  "${m[0].trim()}"  (${entry.label})`); continue; }
              checked++;
              if (got === want) continue;
              if (isMarked) { marked.push(`${rel}:${lineNo}  "${m[0].trim()}"`); continue; }
              wrong.push(`${rel}:${lineNo}  "${m[0].trim()}"  ${entry.label} is ${want}`);
            }
          }
        } else {
          // relation: the line must carry a key AND a token; the token must be the table's.
          if (cand.joined) continue;               // relations are stated on one line
          if (entry.exempt && entry.exempt.test(text)) continue;
          entry.keyPattern.lastIndex = 0;
          const keys = [...text.matchAll(entry.keyPattern)].map((k) => k[1]).filter((k) => entry.table.has(k));
          if (keys.length !== 1) continue;         // ambiguous or unmapped: not this guard's claim
          entry.tokenPattern.lastIndex = 0;
          const tokens = [...text.matchAll(entry.tokenPattern)].map((t) => entry.format(t[1]));
          if (tokens.length !== 1) continue;       // a scale line lists many; not a claim about one rule
          if (isHistory) { historyLines.push(`${rel}:${lineNo}  ${keys[0]} ${tokens[0]}  (${entry.label})`); continue; }
          checked++;
          const want = entry.table.get(keys[0]);
          if (tokens[0] === want) continue;
          if (isMarked) { marked.push(`${rel}:${lineNo}  ${keys[0]} ${tokens[0]}`); continue; }
          wrong.push(`${rel}:${lineNo}  ${keys[0]} stated ${tokens[0]}, catalog declares ${want}`);
        }
      }
    }
  }
}

console.log('=== repo-wide derived-value guard ===');
console.log(`Files scanned : ${files.length}`);
console.log(`Claims checked: ${checked}`);
console.log(`History lines : ${historyLines.length} (dated rows/bullets, skipped by shape)`);
console.log(`Exempt lines  : ${marked.length}`);
if (VERBOSE) {
  for (const h of historyLines) console.log(`  [shape-skip] ${h}`);
  for (const m of marked) console.log(`  [history] ${m}`);
}

// Non-vacuity floor. A scan that stops reaching the corpus — a moved tree, a broken walk, a regex
// refactor that neuters every pattern — otherwise reports "all agree" and is indistinguishable from
// a clean repo. Set below the live figure but far above zero; if a change legitimately removes most
// claims, lower it deliberately and say so in the commit.
const CLAIM_FLOOR = 40;
if (checked < CLAIM_FLOOR) {
  console.log(`\nFAIL: only ${checked} claims checked (floor ${CLAIM_FLOOR}) — the scan is not reaching the corpus.`);
  process.exit(2);
}

if (wrong.length) {
  console.log(`\nWRONG VALUES: ${wrong.length}`);
  for (const w of wrong) console.log(`  ${w}`);
  console.log(`\nEach line above states a value that disagrees with the source it describes.`);
  console.log(`Correct it, or -- if the line quotes a superseded value on purpose -- add the`);
  console.log(`marker \`${MARKER}\` to that line.`);
  process.exit(1);
}

console.log(`\nAll ${checked} stated values agree with their derivation.`);
