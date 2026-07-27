#!/usr/bin/env node
// gen-skills.mjs — Skill detail page generator (feature-001-skill-detail-pages).
//
// Purpose:
//   Generates one markdown page per canonical/skills/ directory, placing each
//   at site/src/content/docs/skills/<dir>.md, and writes a build manifest at
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
import { pathToFileURL } from 'node:url';
import { discoverSkills } from './skills/discover.mjs';
import { renderSkillPage } from './skills/render-page.mjs';
import {
  SITE_SKILLS_DIR,
  SKILLS_MANIFEST_ABS,
  skillSourcePath,
  skillDestPath,
  skillDestAbs,
} from './skills/paths.mjs';

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  // ── 1. DISCOVER ─────────────────────────────────────────────────────────────
  // discoverSkills() enumerates canonical/skills/, sorts directory names, and
  // builds a SkillRecord[] — throwing on any per-skill guard failure.
  console.log('[gen-skills] generating skill detail pages...');
  const skills = discoverSkills();

  // ── 2. PARSE + 3. RECORD ────────────────────────────────────────────────────
  // Both steps happen inside discoverSkills(). Each SkillRecord carries
  // parsed Field[], body text, line anchors, and path strings.
  console.log(`[gen-skills] parsed ${skills.length} skills`);

  // ── 4. RENDER ───────────────────────────────────────────────────────────────
  // renderSkillPage() is a pure function: page frontmatter → marker →
  // Frontmatter section → body slot. LF line endings throughout.
  const rendered = skills.map((skill) => ({
    skill,
    content: renderSkillPage(skill),
  }));

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

  // ── 6. MANIFEST ─────────────────────────────────────────────────────────────
  // Write scripts/.skills-manifest.json — sibling of .reference-manifest.json,
  // outside the content-collection root so docsLoader() never sees it.
  // entries ordered by src ascending (same as sorted directory scan).
  // No generatedAt and no wall-clock value anywhere (AC-6 determinism).
  // All paths are POSIX strings built by concatenation (never by the platform-sensitive join helper).
  const manifest = {
    generator: 'site/scripts/gen-skills.mjs',
    entries: skills.map((skill) => ({
      src: skillSourcePath(skill.dirName),
      dest: skillDestPath(skill.dirName),
    })),
    generatedPaths: skills.map((skill) => skillDestPath(skill.dirName)),
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

  assertNoSkillsDrift({ expected, written, onDisk });
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
 * @param {{ expected: string[], written: string[], onDisk: string[] }} sets — each sorted
 */
export function assertNoSkillsDrift({ expected, written, onDisk }) {
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
  if (missingPages.length > 0 || orphanPages.length > 0) {
    const parts = [];
    if (missingPages.length > 0) {
      parts.push('missing pages: ' + missingPages.join(', '));
    }
    if (orphanPages.length > 0) {
      const remedy = orphanPages.map((d) => `git rm site/src/content/docs/skills/${d}.md`).join(', ');
      parts.push('orphan pages: ' + orphanPages.join(', ') + ' (remedy: ' + remedy + ')');
    }
    throw new Error('[gen-skills] skills drift: ' + parts.join('; '));
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
