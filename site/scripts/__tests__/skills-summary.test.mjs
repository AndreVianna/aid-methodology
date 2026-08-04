// skills-summary.test.mjs — Unit tests for skillSummary (task-007).
//
// Covers: determinism, first-sentence extraction, 157-char cap with word-boundary
// cut, no-'. '-terminator fallback, absent-description fallback, boundary cases at
// 156/157/158 chars, and a full corpus sweep over canonical/skills/.

import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { skillSummary } from '../skills/summary.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');

const SUMMARY_CAP = 157;

// ── Test helpers ──────────────────────────────────────────────────────────────

/**
 * Build a minimal SkillRecord-shaped object for unit tests.
 * Pass `undefined` as descriptionValue to simulate a record with no description.
 */
function makeRecord(dirName, descriptionValue) {
  return {
    dirName,
    field(key) {
      if (key === 'description' && descriptionValue !== undefined) {
        return { key: 'description', kind: 'scalar', value: descriptionValue, line: 2 };
      }
      return undefined;
    },
  };
}

/**
 * Minimal folded-scalar extractor for the corpus sweep.
 * Mirrors the `>` folded-block behaviour of parseSkillFrontmatter: continuation
 * lines (2-space-indented or blank) are joined with spaces. EVERY skill in the
 * corpus states `description: >` and no other block style appears, so this covers
 * the full corpus at whatever size the roster happens to be — deliberately an
 * invariant rather than an "N of M", which would need editing on every roster
 * change and would silently lie in between.
 *
 * Re-implemented here rather than imported from skills/frontmatter.mjs:
 * that module is built by a parallel task and importing it before it is
 * committed would create a cross-task dependency in the test.
 */
function extractDescription(text) {
  const fmEnd = text.indexOf('\n---', 3);
  if (fmEnd === -1) return null;
  const fm = text.slice(0, fmEnd);
  const lines = fm.split('\n');
  const descLines = [];
  let inDesc = false;
  for (const line of lines) {
    if (inDesc) {
      if (line === '' || line.startsWith('  ')) {
        descLines.push(line === '' ? '' : line.trimStart());
      } else {
        break;
      }
    } else if (/^description: >[-+]?$/.test(line)) {
      inDesc = true;
    }
  }
  if (!inDesc) return null;
  // Fold: join non-blank continuation lines with a single space.
  return descLines.filter((l) => l !== '').join(' ').replace(/  +/g, ' ').trim() || null;
}

// ── Unit tests ────────────────────────────────────────────────────────────────

describe('skillSummary', () => {
  it('is deterministic — identical output across repeated calls for the same input', () => {
    const rec = makeRecord('aid-test', 'A short sentence. More text here.');
    expect(skillSummary(rec)).toBe(skillSummary(rec));
  });

  it('returns the first sentence unchanged when shorter than cap, including the terminating period', () => {
    const rec = makeRecord('aid-test', 'A short skill. More text here that is ignored.');
    expect(skillSummary(rec)).toBe('A short skill.');
  });

  it('returns the first sentence unchanged when it has no subsequent text', () => {
    const rec = makeRecord('aid-test', 'A standalone sentence.');
    expect(skillSummary(rec)).toBe('A standalone sentence.');
  });

  it('returns the whole description when no ". " terminator is present (no cap exceeded)', () => {
    const noSentence = 'a '.repeat(40).trimEnd();
    expect(noSentence.length).toBeLessThanOrEqual(SUMMARY_CAP);
    const rec = makeRecord('aid-test', noSentence);
    expect(skillSummary(rec)).toBe(noSentence);
  });

  it('cuts whole description at word boundary when no ". " and length exceeds cap', () => {
    const longNoSentence = 'word '.repeat(40).trimEnd(); // 199 chars, no period-space
    expect(longNoSentence.length).toBeGreaterThan(SUMMARY_CAP);
    const rec = makeRecord('aid-test', longNoSentence);
    const result = skillSummary(rec);
    expect(result.endsWith('\u2026')).toBe(true);
    const body = result.slice(0, -1);
    expect(body.length).toBeLessThanOrEqual(SUMMARY_CAP);
    expect(body[body.length - 1]).not.toBe(' ');
  });

  it('cuts long first sentence at last word boundary at or below 157 chars', () => {
    const longDesc = 'word '.repeat(50).trimEnd() + '. More ignored text.';
    const rec = makeRecord('aid-test', longDesc);
    const result = skillSummary(rec);
    expect(result.endsWith('\u2026')).toBe(true);
    const body = result.slice(0, -1);
    expect(body.length).toBeLessThanOrEqual(SUMMARY_CAP);
    expect(body[body.length - 1]).not.toBe(' ');
  });

  it('returns fallback string byte-for-byte when no description field, with directory interpolated', () => {
    const rec = makeRecord('aid-some-skill', undefined);
    expect(skillSummary(rec)).toBe(
      'AID skill aid-some-skill \u2014 declared frontmatter contract, generated from canonical/.'
    );
  });

  it('interpolates a different directory name in the fallback', () => {
    const rec = makeRecord('aid-custom-dir', undefined);
    expect(skillSummary(rec)).toBe(
      'AID skill aid-custom-dir \u2014 declared frontmatter contract, generated from canonical/.'
    );
  });

  it('fallback contains an em-dash (U+2014), not a hyphen', () => {
    const rec = makeRecord('aid-x', undefined);
    const result = skillSummary(rec);
    expect(result).toContain('\u2014');
    expect(result).not.toMatch(/aid-x -/); // not a hyphen
  });

  it('fallback ends with the exact string "generated from canonical/."', () => {
    const rec = makeRecord('aid-x', undefined);
    expect(skillSummary(rec)).toMatch(/generated from canonical\/\.$/);
  });
});

// ── Boundary cases at 156, 157, 158 characters ───────────────────────────────
//
// These are the off-by-one territory: 156 and 157 must return as-is (no
// ellipsis), 158 must truncate and append an ellipsis.
//
// Construction:
//   'x'.repeat(152) + ' ab.'   = 152 + 4 = 156 chars   (space at idx 152)
//   'x'.repeat(152) + ' abc.'  = 152 + 5 = 157 chars
//   'x'.repeat(152) + ' abcd.' = 152 + 6 = 158 chars
//
// The description passed to makeRecord appends ' Extra.' so that there IS a
// '. ' boundary and the first-sentence extractor returns exactly the constructed
// sentence length.

describe('skillSummary — boundary cases (156, 157, 158 chars)', () => {
  const s156 = 'x'.repeat(152) + ' ab.';   // 156 chars
  const s157 = 'x'.repeat(152) + ' abc.';  // 157 chars
  const s158 = 'x'.repeat(152) + ' abcd.'; // 158 chars

  it('constructs correct sentence lengths (self-check)', () => {
    expect(s156.length).toBe(156);
    expect(s157.length).toBe(157);
    expect(s158.length).toBe(158);
  });

  it('156-char sentence: returned unchanged, no ellipsis', () => {
    const rec = makeRecord('aid-test', s156 + ' Extra.');
    const result = skillSummary(rec);
    expect(result).toBe(s156);
    expect(result.length).toBe(156);
    expect(result.endsWith('\u2026')).toBe(false);
    expect(result.endsWith('.')).toBe(true);
  });

  it('157-char sentence: returned unchanged, no ellipsis (at the cap)', () => {
    const rec = makeRecord('aid-test', s157 + ' Extra.');
    const result = skillSummary(rec);
    expect(result).toBe(s157);
    expect(result.length).toBe(157);
    expect(result.endsWith('\u2026')).toBe(false);
    expect(result.endsWith('.')).toBe(true);
  });

  it('158-char sentence: truncated at word boundary with ellipsis (one over cap)', () => {
    const rec = makeRecord('aid-test', s158 + ' Extra.');
    const result = skillSummary(rec);
    expect(result.endsWith('\u2026')).toBe(true);
    const body = result.slice(0, -1); // remove the '…'
    expect(body.length).toBeLessThanOrEqual(SUMMARY_CAP);
    // The last space in s158 is at index 152; cut is at 152 → body = 'x'.repeat(152)
    expect(body).toBe('x'.repeat(152));
    expect(result).toBe('x'.repeat(152) + '\u2026');
  });

  it('158-char sentence: cut body never ends with a space (not mid-word)', () => {
    const rec = makeRecord('aid-test', s158 + ' Extra.');
    const body = skillSummary(rec).slice(0, -1);
    expect(body[body.length - 1]).not.toBe(' ');
  });
});

// ── Corpus sweep ──────────────────────────────────────────────────────────────

describe('skillSummary — corpus sweep (all canonical/skills/)', () => {
  const skillDirs = readdirSync(SKILLS_DIR).sort();

  it('no output exceeds SUMMARY_CAP + 1 chars (cap plus the single ellipsis character)', () => {
    for (const dir of skillDirs) {
      const text = readFileSync(join(SKILLS_DIR, dir, 'SKILL.md'), 'utf8');
      const desc = extractDescription(text);
      const rec = makeRecord(dir, desc !== null ? desc : undefined);
      const summary = skillSummary(rec);
      expect(
        summary.length,
        `${dir}: summary length ${summary.length} exceeds ${SUMMARY_CAP + 1}`
      ).toBeLessThanOrEqual(SUMMARY_CAP + 1);
    }
  });

  it('no output is empty', () => {
    for (const dir of skillDirs) {
      const text = readFileSync(join(SKILLS_DIR, dir, 'SKILL.md'), 'utf8');
      const desc = extractDescription(text);
      const rec = makeRecord(dir, desc !== null ? desc : undefined);
      const summary = skillSummary(rec);
      expect(summary.length, `${dir}: empty summary`).toBeGreaterThan(0);
    }
  });

  it('no output ends mid-word (no space immediately before the ellipsis)', () => {
    for (const dir of skillDirs) {
      const text = readFileSync(join(SKILLS_DIR, dir, 'SKILL.md'), 'utf8');
      const desc = extractDescription(text);
      const rec = makeRecord(dir, desc !== null ? desc : undefined);
      const summary = skillSummary(rec);
      if (summary.endsWith('\u2026')) {
        const body = summary.slice(0, -1);
        expect(
          body[body.length - 1],
          `${dir}: last char before ellipsis is a space (mid-word cut)`
        ).not.toBe(' ');
      }
    }
  });
});
