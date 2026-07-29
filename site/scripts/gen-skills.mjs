#!/usr/bin/env node
// gen-skills.mjs — Skill detail page generator (feature-001-skill-detail-pages).
//
// Purpose:
//   Generates one markdown page per canonical/skills/ directory, placing each
//   at site/src/content/docs/skills/<dir>.md, writes the grouped index page
//   at site/src/content/docs/skills/index.md, and writes a build manifest at
//   site/scripts/.skills-manifest.json.
//
// Usage:
//   node scripts/gen-skills.mjs
//
// Wired as:
//   gen:skills in package.json (chained in prebuild / predev, after gen:reference)
//
// Exit codes:
//   0 — success; all pages written, manifest written, drift guard passed.
//   1 — any guard failure (uncaught throw). No exit code 2: this script takes
//       no arguments, so there is no usage-error path.

import { mkdirSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { discoverSkills } from './skills/discover.mjs';
import { renderSkillPage } from './skills/render-page.mjs';
import { loadShortcutCatalog } from './skills/catalog.mjs';
import { assignGroups } from './skills/groups.mjs';
import { renderSkillIndex } from './skills/render-index.mjs';
import {
  resetFlowWarnings,
  summarizeFlowWarnings,
  classifySkill,
  buildFlowChart,
  serializeChart,
} from './lib/flow-graph/index.mjs';
import {
  REPO_ROOT,
  SITE_SKILLS_DIR,
  SITE_SKILL_FLOWS_DIR,
  SKILLS_MANIFEST_ABS,
  skillSourcePath,
  skillDestPath,
  skillDestAbs,
  skillFlowPath,
  skillFlowAbs,
} from './skills/paths.mjs';

// ── Index-row constants ────────────────────────────────────────────────────────
// Two-source src string — byte-identical to gen-reference.mjs:447's generatedFrom
// and to the index page's own generatedFrom value (render-index.mjs's GENERATED_FROM
// constant). One string, three places; an AC check confirms all three agree.
//
// '*' (code point 42) sorts before 'a' (code point 97), so this entry lands
// first when entries are sorted by src ascending — confirmed by pure string
// comparison, no localeCompare.
const INDEX_SRC = 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml';
const INDEX_DEST = 'site/src/content/docs/skills/index.md';

// ── Shape constants ────────────────────────────────────────────────────────────

/**
 * The five classifier shapes, in the enum's declared order (task-019 seam S2).
 *
 * `shapeCounts` carries all five as literal keys with an integer each, `0` included
 * where a shape is unpopulated. Emitting only the shapes the scan encountered would
 * make the key set a function of the corpus, so a shape falling to zero would change
 * the manifest's *shape* rather than its numbers, and an absent key would be
 * indistinguishable from a classifier that never ran. An explicit `0` states the fact.
 *
 * These are shape names, not counts. No per-shape number appears anywhere in this
 * file — `shapeCounts` is the repo's only authority for those, and it is computed.
 */
const SHAPE_ORDER = [
  'dispatch-table',
  'inline-states',
  'sibling-doorway',
  'engine-doorway',
  'residual',
];

/**
 * Shapes that produce a chart, and therefore a sidecar.
 *
 * Derived from SHAPE_ORDER rather than listed again, because every shape the
 * classifier can return now charts: feature-003's three authored shapes plus
 * feature-004's two doorway shapes, which landed in tasks 035–037.
 *
 * It was previously the three authored shapes with a comment predicting this very
 * change, and widening it was missed when the doorway extractors shipped — so 77
 * of the 111 skills charted on the page but got no sidecar. Nothing caught it
 * because the drift guard derives both its expected and its on-disk set from this
 * constant, making the omission self-consistent and therefore invisible.
 * Deriving it removes the second list that could go stale.
 */
const CHARTABLE_SHAPES = new Set(SHAPE_ORDER);

// ── Main ──────────────────────────────────────────────────────────────────────

/**
 * Run the full generation pipeline.
 *
 * Exported so a test can invoke it twice in one process. That is the only way to
 * observe the `resetFlowWarnings()` call below: deleting it changes nothing in a
 * fresh process, so a subprocess test can never catch its removal, and the reset
 * shipped un-undoable until this export existed.
 *
 * @returns {Promise<void>}
 */
export async function main() {
  // ── 1. DISCOVER ─────────────────────────────────────────────────────────────
  // discoverSkills() enumerates canonical/skills/, sorts directory names, and
  // builds a SkillRecord[] — throwing on any per-skill guard failure.
  console.log('[gen-skills] generating skill detail pages...');
  // Start the run's warning count at zero, so a second run in the same process
  // (a test, or a watch rebuild) reports its own total rather than a cumulative one.
  resetFlowWarnings();
  const skills = discoverSkills();

  // ── 2. PARSE + 3. RECORD ────────────────────────────────────────────────────
  // Both steps happen inside discoverSkills(). Each SkillRecord carries
  // parsed Field[], body text, line anchors, and path strings.
  console.log(`[gen-skills] parsed ${skills.length} skills`);

  // ── 3a. CATALOG ─────────────────────────────────────────────────────────────
  // Read canonical/aid/templates/shortcut-catalog.yml through catalog.mjs.
  // Placed after RECORD only because nothing earlier needs it; it depends on no
  // step and is a pure file read.
  const catalog = loadShortcutCatalog(REPO_ROOT);

  // ── 4. RENDER ───────────────────────────────────────────────────────────────
  // renderSkillPage() is a pure function: page frontmatter → marker →
  // Frontmatter section → body slot. LF line endings throughout.
  const rendered = skills.map((skill) => ({
    skill,
    content: renderSkillPage(skill),
  }));

  // ── 4a. ASSIGN ──────────────────────────────────────────────────────────────
  // assignGroups() must follow RECORD (it needs every record's route and
  // description) and must precede 5a. Four assignment guards — unassignable
  // skill, curated skill missing, duplicate assignment, full-path catalog row —
  // all throw before any assignment if violated.
  const sections = assignGroups(skills, catalog);

  // ── 5. WRITE ────────────────────────────────────────────────────────────────
  // mkdir -p the output directory, then write each page as utf8, LF endings.
  mkdirSync(SITE_SKILLS_DIR, { recursive: true });

  const writtenDirNames = [];
  for (const { skill, content } of rendered) {
    const destAbs = skillDestAbs(skill.dirName);
    // Normalize to LF: content from renderSkillPage() is already LF, but be
    // defensive in case the platform's string operations introduce CRLF.
    const normalized = content.replace(/\r\n?/g, '\n');
    writeFileSync(destAbs, normalized, 'utf8');
    writtenDirNames.push(skill.dirName);
  }

  console.log(`[gen-skills] wrote ${writtenDirNames.length} pages -> src/content/docs/skills/`);

  // ── 5a. INDEX ───────────────────────────────────────────────────────────────
  // Render and write src/content/docs/skills/index.md.
  const indexContent = renderSkillIndex(skills, sections).replace(/\r\n?/g, '\n');
  const indexDestAbs = resolve(SITE_SKILLS_DIR, 'index.md');
  writeFileSync(indexDestAbs, indexContent, 'utf8');

  // ── 5b. SIDECARS ────────────────────────────────────────────────────────────
  // One <skill>.flow.json per charted skill, bytes exactly serializeChart(chart).
  // No line is printed for this step: feature-001's stdout contract is four phase
  // lines, and task-030 must not widen it.
  //
  // Classification drives both the sidecar set and shapeCounts, so the two cannot
  // disagree — shapeCounts is the repo's only authority for per-shape numbers, and
  // an authority computed from a second scan would be a second authority.
  mkdirSync(SITE_SKILL_FLOWS_DIR, { recursive: true });

  const shapeCounts = Object.fromEntries(SHAPE_ORDER.map((s) => [s, 0]));
  const chartedDirNames = [];

  for (const skill of skills) {
    const { shape } = classifySkill({
      name: skill.dirName,
      dir: REPO_ROOT,
      frontmatter: Object.fromEntries((skill.fields ?? []).map((f) => [f.key, f.value])),
      body: skill.body ?? '',
    });

    if (!(shape in shapeCounts)) {
      throw new Error(
        `[gen-skills] shapeCounts: classifier returned unknown shape '${shape}' for ` +
        `'${skill.dirName}' — SHAPE_ORDER must list every classifier value.`
      );
    }
    shapeCounts[shape] += 1;

    // A sidecar exists only where a chart does. That is 34 of 111 until feature-004's
    // doorway extractors land and every shape charts.
    if (!CHARTABLE_SHAPES.has(shape)) continue;

    const chart = buildFlowChart({ name: skill.dirName, dir: REPO_ROOT });
    writeFileSync(skillFlowAbs(skill.dirName), serializeChart(chart), 'utf8');
    chartedDirNames.push(skill.dirName);
  }

  // ── 6. MANIFEST ─────────────────────────────────────────────────────────────
  // Write scripts/.skills-manifest.json — sibling of .reference-manifest.json,
  // outside the content-collection root so docsLoader() never sees it.
  // Insert the index row then sort all entries by src ascending — pure string
  // comparison, no localeCompare, so the sort is platform-identical.
  // '*' (42) < 'a' (97), so the index row lands first among canonical/skills/…
  // entries. Rebuild generatedPaths from entries in the same order.
  // No generatedAt and no wall-clock value anywhere (AC-6 determinism).
  // All paths are POSIX strings built by concatenation (never platform join).
  const skillEntries = skills.map((skill) => ({
    src: skillSourcePath(skill.dirName),
    dest: skillDestPath(skill.dirName),
  }));
  const indexEntry = { src: INDEX_SRC, dest: INDEX_DEST };
  const entries = [...skillEntries, indexEntry].sort(
    (a, b) => (a.src < b.src ? -1 : a.src > b.src ? 1 : 0)
  );

  // Sidecars ride in their own key, never as `entries` rows and never in
  // `generatedPaths` (task-019 seam S1). Six green assertions pin `entries` to exactly
  // one row per page — including one on *strictly* ascending `src`, which a page and
  // sidecar sharing a `src` would violate. Same pure string comparator as `entries`.
  const sidecars = chartedDirNames
    .map((dirName) => ({
      src: skillSourcePath(dirName),
      dest: skillFlowPath(dirName),
    }))
    .sort((a, b) => (a.src < b.src ? -1 : a.src > b.src ? 1 : 0));

  // Five keys in fixed insertion order (seam S2). This diverges deliberately from
  // .reference-manifest.json, which stays three-key and byte-untouched: from
  // delivery-003 this manifest is a superset of that shape rather than a mirror of it.
  const manifest = {
    generator: 'site/scripts/gen-skills.mjs',
    entries,
    generatedPaths: entries.map((e) => e.dest),
    sidecars,
    shapeCounts,
  };

  writeFileSync(SKILLS_MANIFEST_ABS, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log('[gen-skills] wrote scripts/.skills-manifest.json');

  // ── 7. GUARD ────────────────────────────────────────────────────────────────
  // Run AFTER the write pass so it also catches pages left over from a deleted
  // skill. Compare the three sorted sets:
  //   expected = directories under canonical/skills/  (from the records)
  //   written  = dir names of pages this run wrote    (writtenDirNames, already sorted)
  //   onDisk   = *.md under src/content/docs/skills/, minus index.md, basename w/o .md
  //
  // Throw on either mismatch. Report only the two set differences:
  //   missing pages: (in expected but not on disk)
  //   orphan pages:  (on disk but not in expected)
  // The generator never deletes — an orphan is thrown on and named with a git rm remedy.
  const expected = skills.map((s) => s.dirName).sort();
  const written = writtenDirNames.slice().sort();

  // onDisk: read the output directory and find *.md files, excluding index.md
  const onDiskFiles = existsSync(SITE_SKILLS_DIR)
    ? readdirSync(SITE_SKILLS_DIR).filter((f) => f.endsWith('.md') && f !== 'index.md')
    : [];
  const onDisk = onDiskFiles.map((f) => f.slice(0, -3)).sort();

  // onDiskSidecars: *.flow.json under src/data/skill-flows/, basename without the
  // .flow.json suffix. Read from disk rather than from chartedDirNames, so a sidecar
  // left behind by a deleted skill is caught — the one branch that actually fires.
  const onDiskSidecarFiles = existsSync(SITE_SKILL_FLOWS_DIR)
    ? readdirSync(SITE_SKILL_FLOWS_DIR).filter((f) => f.endsWith('.flow.json'))
    : [];
  const onDiskSidecars = onDiskSidecarFiles.map((f) => f.slice(0, -'.flow.json'.length)).sort();

  assertNoSkillsDrift({
    expected,
    written,
    onDisk,
    expectedSidecars: chartedDirNames.slice().sort(),
    onDiskSidecars,
  });

  // ── 7a. CARDS ───────────────────────────────────────────────────────────────
  // Dead card guard: every card target must be among the pages just written.
  // Runs inside the same guard phase as step 7, after both writes (detail pages
  // + index.md), so it also catches an index referencing a page a later step
  // failed to produce.
  assertNoDeadCards(sections, writtenDirNames);

  // ── 8. REPORT ───────────────────────────────────────────────────────────────
  // Flow-chart warnings, drained from the accumulator in flow-graph/index.mjs.
  // Printed to stdout, never stderr — a successful run must leave stderr empty.
  //
  // This is the reader that task-029's counter lacked. A warning means an authored
  // chart is approximate in some specific way (a clause dropped, a heuristic ladder
  // rung declined); without this line, `chart.warnings` reached nobody, because
  // `confidence` reflects which extractor ran rather than whether anything was lost.
  reportFlowWarnings();
}

/**
 * Print the run-level flow-warning summary. Silent when the run produced none, so
 * a clean run stays quiet and any output is signal.
 *
 * Exported for test: the assertion that a warning actually reaches a human should
 * not have to scrape a subprocess's stdout.
 *
 * @param {(msg: string) => void} [log]  Sink (default console.log).
 * @returns {{total: number, charts: number}}  What was reported.
 */
export function reportFlowWarnings(log = console.log) {
  const { total, charts, skills, messages } = summarizeFlowWarnings();
  if (total === 0) return { total: 0, charts: 0 };

  log(
    `[gen-skills] flow: ${total} warning${total === 1 ? '' : 's'} across ` +
    `${charts} chart${charts === 1 ? '' : 's'} (${skills.join(', ')})`
  );
  for (const m of messages) log(`  ${m}`);
  return { total, charts };
}

/**
 * The AC-1 drift guard. Throws `[gen-skills] skills drift: …` when the page set
 * diverges from the skill set in either direction, reporting only the two set
 * differences under `missing pages:` / `orphan pages:` labels — `gen-reference.mjs`
 * dumps both full lists, which is unreadable at this corpus's scale.
 *
 * Exported and taking its three sets as parameters so every branch is reachable
 * from a test. Called from `main()` after the write pass, **three of the four
 * branches are unreachable in situ** — write-pass-missing, write-pass-orphan and
 * onDisk-missing all require a page to be absent moments after it was written,
 * so only onDisk-orphan (a page left behind by a deleted skill) can actually
 * fire there. Left inline they would be code no test could exercise, which is
 * indistinguishable from code that does not work; the same reasoning applies
 * here as to `buildCuratedIndex` in `skills/groups.mjs`.
 *
 * The generator NEVER deletes. An orphan is named with its `git rm` remedy —
 * auto-pruning would keep the build green and turn AC-1's loud coverage failure
 * into exactly the silent rot the criterion exists to prevent.
 *
 * **Sidecars join block (b), not block (a)** (task-019 seam S1). An orphan sidecar is
 * the same reachable failure as an orphan page — the generator never deletes, and
 * deliveries 004 and 005 read the sidecar — so it belongs in the same guard and the
 * same single throw. Two separate guards would report the page on one run and the
 * sidecar only on the next, costing a build cycle on the one failure that actually
 * occurs. The realistic case, a skill deleted from `canonical/`, orphans a page and
 * its sidecar at once and must produce one throw naming both remedies.
 *
 * `expectedSidecars` is **required and separate from `expected`**, which is a delta
 * against S1's letter ("the same `expected` set"). A sidecar can only exist for a
 * skill that produces a chart: 34 of 111 until feature-004's doorway extractors land,
 * all 111 afterwards, at which point this set equals `expected` and S1 holds exactly.
 * Passing `expected` today would make the guard throw on 77 skills that are correctly
 * chart-less. The set is required rather than defaulted for the same reason S1 gave
 * for `onDiskSidecars`: a defaulted set is a guard that silently passes when a caller
 * forgets it, which is the silent-skip class KI-008 has already cost this work once.
 *
 * @param {{ expected: string[], written: string[], onDisk: string[],
 *           expectedSidecars: string[], onDiskSidecars: string[] }} sets — each sorted
 */
export function assertNoSkillsDrift({ expected, written, onDisk, expectedSidecars, onDiskSidecars }) {
  // Required-not-defaulted: name the omission rather than skipping the comparison.
  for (const [key, value] of [
    ['expectedSidecars', expectedSidecars],
    ['onDiskSidecars', onDiskSidecars],
  ]) {
    if (!Array.isArray(value)) {
      throw new Error(
        `[gen-skills] skills drift: ${key} is required (task-019 seam S1) — ` +
        'a defaulted sidecar set is a guard that silently passes.'
      );
    }
  }

  // (a) the write pass must match discovery
  const missingFromWritten = expected.filter((d) => !written.includes(d));
  const extraInWritten = written.filter((d) => !expected.includes(d));
  if (missingFromWritten.length > 0 || extraInWritten.length > 0) {
    const parts = [];
    if (missingFromWritten.length > 0) {
      parts.push('missing pages: ' + missingFromWritten.join(', '));
    }
    if (extraInWritten.length > 0) {
      parts.push('orphan pages: ' + extraInWritten.join(', '));
    }
    throw new Error('[gen-skills] skills drift: write pass diverged from discovery. ' + parts.join('; '));
  }

  // (b) what is on disk must match discovery — this is the branch that catches a
  // page left behind by a deleted skill, which the write pass cannot see.
  const missingPages = expected.filter((d) => !onDisk.includes(d));
  const orphanPages = onDisk.filter((d) => !expected.includes(d));
  const missingSidecars = expectedSidecars.filter((d) => !onDiskSidecars.includes(d));
  const orphanSidecars = onDiskSidecars.filter((d) => !expectedSidecars.includes(d));

  if (
    missingPages.length > 0 || orphanPages.length > 0 ||
    missingSidecars.length > 0 || orphanSidecars.length > 0
  ) {
    // Fixed part order (S1): missing pages, orphan pages, missing sidecars, orphan
    // sidecars. The page parts keep their exact wording and position, which is what
    // keeps feature-001's seven message assertions green.
    const parts = [];
    if (missingPages.length > 0) {
      parts.push('missing pages: ' + missingPages.join(', '));
    }
    if (orphanPages.length > 0) {
      const remedy = orphanPages.map((d) => `git rm site/src/content/docs/skills/${d}.md`).join(', ');
      parts.push('orphan pages: ' + orphanPages.join(', ') + ' (remedy: ' + remedy + ')');
    }
    if (missingSidecars.length > 0) {
      parts.push('missing sidecars: ' + missingSidecars.join(', '));
    }
    if (orphanSidecars.length > 0) {
      const remedy = orphanSidecars
        .map((d) => `git rm site/src/data/skill-flows/${d}.flow.json`)
        .join(', ');
      parts.push('orphan sidecars: ' + orphanSidecars.join(', ') + ' (remedy: ' + remedy + ')');
    }
    // The guard NAME is unchanged: feature-001 § Telemetry pins `skills drift` in a
    // closed list of grep-able names, so no `sidecar drift` name is minted.
    throw new Error('[gen-skills] skills drift: ' + parts.join('; '));
  }
}

/**
 * The 7a dead card guard. Throws `[gen-skills] dead card: <name>` when a card
 * in the index references a skill page that was not written.
 *
 * Exported and taking its inputs as parameters so every branch is reachable
 * from a test. Called from `main()` after both writes (detail pages + index.md),
 * so it also catches an index that references a page a later step failed to
 * produce. In practice all branches are unreachable in situ — assignGroups()
 * only builds cards from SkillRecords that discoverSkills() produced, and every
 * discovered skill is written unconditionally in step 5. Left inline, the guard
 * would be indistinguishable from absent code.
 *
 * @param {Array<{ cards: Array<{ name: string, route: string }>, families: Array<{ cards: Array<{ name: string, route: string }> }> }>} sections
 * @param {string[]} writtenDirNames  Dir names of skill detail pages written in step 5.
 */
export function assertNoDeadCards(sections, writtenDirNames) {
  const writtenSet = new Set(writtenDirNames);
  for (const section of sections) {
    for (const card of section.cards) {
      if (!writtenSet.has(card.name)) {
        throw new Error('[gen-skills] dead card: "' + card.name + '" (route: ' + card.route + ')');
      }
    }
    for (const family of section.families) {
      for (const card of family.cards) {
        if (!writtenSet.has(card.name)) {
          throw new Error('[gen-skills] dead card: "' + card.name + '" (route: ' + card.route + ')');
        }
      }
    }
  }
}

// Only run main() when this file is executed directly (not imported by tests).
// Use pathToFileURL for a cross-platform comparison — string-concatenating
// `file://` + process.argv[1] does not match import.meta.url on Windows
// (drive letters + backslashes), which would silently skip execution there.
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((err) => {
    process.stderr.write(err.message + '\n');
    process.exit(1);
  });
}
