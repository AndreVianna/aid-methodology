// skills-render-page.test.mjs — Unit tests for renderSkillPage (task-010).
//
// Covers every acceptance criterion:
//   AC-1  Page is in fixed order: frontmatter → marker → ## Frontmatter → [Definition:] → body slot.
//   AC-2  Generated marker is byte-for-byte the sentence the four existing pages carry
//         (em-dash U+2014, not a hyphen).
//   AC-3  Header is a bullet list, not a markdown table.
//   AC-4  Every frontmatter field present on the record appears in the Frontmatter section.
//         Specifically: list-valued key, folded-scalar key, key with |, key with < inside
//         a code span, synthetic key absent from the corpus — all appear in the header.
//   AC-5  No sidebar: key is emitted on any detail page.
//   AC-6  render-page.mjs imports skillSummary from summary.mjs; 157 cap appears in exactly
//         one module (verified by grep in the post-implementation gate, not duplicated here).
//   AC-7  With both registries empty, the <!-- body slot: … --> comment is emitted; no
//         empty heading is added.
//   AC-8  Body follows the [Definition:] link, separated by a blank line, when non-empty.
//
// Fixtures are SkillRecord-shaped objects built by makeSkill()/makeField().
// The real modules (render-page.mjs, body.mjs, summary.mjs) are imported and
// driven directly — not re-implemented — so assertions verify the shipped code.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { renderSkillPage } from '../skills/render-page.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RENDER_PAGE_SRC = resolve(__dirname, '../skills/render-page.mjs');

// ── Fixtures ─────────────────────────────────────────────────────────────────

/**
 * Build a minimal Field object per the frontmatter.mjs typedef.
 * @param {string} key
 * @param {'scalar'|'list'} kind
 * @param {string|string[]} value
 * @returns {{ key: string, kind: string, value: string|string[], line: number }}
 */
function makeField(key, kind, value) {
  return { key, kind, value, line: 1 };
}

/**
 * Build a SkillRecord-shaped fixture per the SPEC typedef.
 * @param {string} dirName
 * @param {Array<{key: string, kind: string, value: string|string[], line: number}>} fields
 * @returns {object}  SkillRecord-shaped fixture.
 */
function makeSkill(dirName, fields) {
  return {
    dirName,
    sourcePath: `canonical/skills/${dirName}/SKILL.md`,
    route: `/skills/${dirName}/`,
    destPath: `site/src/content/docs/skills/${dirName}.md`,
    fields,
    field(k) { return fields.find((f) => f.key === k); },
    body: '',
    bodyStartLine: 1,
    lineCount: 10,
    referencesDir: null,
  };
}

// Baseline fixture: a minimal skill with the four standard corpus fields.
const BASELINE_FIELDS = [
  makeField('name', 'scalar', 'aid-test-skill'),
  makeField('description', 'scalar', 'A test skill. Used for unit testing purposes.'),
  makeField('allowed-tools', 'scalar', 'Read, Grep, Write'),
  makeField('argument-hint', 'scalar', '[description]'),
];

const BASELINE = makeSkill('aid-test-skill', BASELINE_FIELDS);

// ── AC-1: Page order ──────────────────────────────────────────────────────────

describe('page order (AC-1)', () => {
  it('frontmatter block comes first (before the generated marker)', () => {
    const page = renderSkillPage(BASELINE);
    const fmEnd = page.indexOf('\n---\n', 1); // closing ---
    const markerIdx = page.indexOf('<!-- generated');
    expect(fmEnd).toBeGreaterThan(0);
    expect(markerIdx).toBeGreaterThan(fmEnd);
  });

  it('generated marker comes before ## Frontmatter section', () => {
    const page = renderSkillPage(BASELINE);
    const markerIdx = page.indexOf('<!-- generated');
    const sectionIdx = page.indexOf('## Frontmatter');
    expect(markerIdx).toBeGreaterThan(-1);
    expect(sectionIdx).toBeGreaterThan(markerIdx);
  });

  it('## Frontmatter section comes before the [Definition:] link', () => {
    const page = renderSkillPage(BASELINE);
    const sectionIdx = page.indexOf('## Frontmatter');
    const definitionIdx = page.indexOf('[Definition:');
    expect(sectionIdx).toBeGreaterThan(-1);
    expect(definitionIdx).toBeGreaterThan(sectionIdx);
  });

  it('[Definition:] link comes before the body slot comment', () => {
    const page = renderSkillPage(BASELINE);
    const definitionIdx = page.indexOf('[Definition:');
    const bodySlotIdx = page.indexOf('<!-- body slot:');
    expect(definitionIdx).toBeGreaterThan(-1);
    expect(bodySlotIdx).toBeGreaterThan(definitionIdx);
  });

  it('body slot comment is the last substantive line in the page', () => {
    const page = renderSkillPage(BASELINE);
    const bodySlotIdx = page.indexOf('<!-- body slot:');
    const afterSlot = page.slice(bodySlotIdx).trimEnd();
    expect(afterSlot).toBe('<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->');
  });
});

// ── AC-2: Generated marker ────────────────────────────────────────────────────

describe('generated marker (AC-2)', () => {
  it('marker contains the em-dash (U+2014), not a hyphen', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain('generated \u2014 do not edit');
    expect(page).not.toContain('generated -- do not edit');
    expect(page).not.toContain('generated - do not edit');
  });

  it('marker matches the exact idiom from the four existing reference pages', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain('generated \u2014 do not edit');
  });

  it('marker includes the per-skill source path', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain('<!-- generated \u2014 do not edit; source: canonical/skills/aid-test-skill/SKILL.md -->');
  });

  it('marker source path is the repo-relative POSIX path (matches dirName)', () => {
    const skill = makeSkill('aid-create-api', [makeField('name', 'scalar', 'aid-create-api')]);
    const page = renderSkillPage(skill);
    expect(page).toContain('source: canonical/skills/aid-create-api/SKILL.md');
  });
});

// ── AC-3: Bullet list, not a table ───────────────────────────────────────────

describe('Frontmatter section is a bullet list (AC-3)', () => {
  it('frontmatter fields are rendered as - **`key`** — value bullets', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain('- **`name`** \u2014 aid-test-skill');
  });

  it('page contains no markdown table row (no | Key | Value | shape)', () => {
    const page = renderSkillPage(BASELINE);
    // A table row would have | at the start of the line (in the Frontmatter section)
    const lines = page.split('\n');
    const tableRows = lines.filter((l) => /^\|[^!]/.test(l));
    expect(tableRows).toHaveLength(0);
  });

  it('bullet lines use em-dash separator (U+2014), not hyphen', () => {
    const page = renderSkillPage(BASELINE);
    const bullets = page.split('\n').filter((l) => l.startsWith('- **`'));
    expect(bullets.length).toBeGreaterThan(0);
    for (const b of bullets) {
      expect(b).toContain('\u2014');
    }
  });
});

// ── AC-4: Header completeness (no key dropped) ────────────────────────────────

describe('header completeness — no key is dropped (AC-4)', () => {
  it('every field key in the record appears as a bullet in the Frontmatter section', () => {
    const page = renderSkillPage(BASELINE);
    for (const f of BASELINE_FIELDS) {
      expect(page).toContain(`**\`${f.key}\`**`);
    }
  });

  it('list-valued key appears and items are rendered as code spans joined with ", "', () => {
    const fields = [
      makeField('name', 'scalar', 'aid-list-test'),
      makeField('allowed-tools', 'list', ['Read', 'Grep', 'Write', 'Edit']),
    ];
    const skill = makeSkill('aid-list-test', fields);
    const page = renderSkillPage(skill);
    expect(page).toContain('**`allowed-tools`**');
    expect(page).toContain('`Read`, `Grep`, `Write`, `Edit`');
  });

  it('key with | in its value appears without pipe escaping (bullet list avoids the need)', () => {
    const fields = [
      makeField('name', 'scalar', 'aid-pipe-test'),
      makeField('description', 'scalar', 'Use `description | comment | status` for the target.'),
    ];
    const skill = makeSkill('aid-pipe-test', fields);
    const page = renderSkillPage(skill);
    expect(page).toContain('**`description`**');
    // The rendered value should contain the pipe literal (not escaped as &#124; or \|)
    expect(page).toContain('`description | comment | status`');
  });

  it('key with < inside a code span passes through byte-identical', () => {
    const fields = [
      makeField('name', 'scalar', 'aid-angle-test'),
      makeField('description', 'scalar', 'Use `aid-read-ticket [<connector>:]<ticket-id>` to fetch.'),
    ];
    const skill = makeSkill('aid-angle-test', fields);
    const page = renderSkillPage(skill);
    expect(page).toContain('**`description`**');
    // < inside code span must be byte-identical
    expect(page).toContain('`aid-read-ticket [<connector>:]<ticket-id>`');
    // < outside code span must be escaped
    expect(page).not.toContain(' <ticket-id>` to fetch'); // outside code spans already escaped
  });

  it('synthetic key that exists nowhere in the corpus still appears in the header', () => {
    const syntheticKey = 'synthetic-nonexistent-key-xyzzy-99999';
    const fields = [
      makeField('name', 'scalar', 'aid-synthetic-test'),
      makeField(syntheticKey, 'scalar', 'some synthetic value'),
    ];
    const skill = makeSkill('aid-synthetic-test', fields);
    const page = renderSkillPage(skill);
    expect(page).toContain(`**\`${syntheticKey}\`**`);
    expect(page).toContain('some synthetic value');
  });

  it('folded-scalar (multiline) value is rendered as a single string on one bullet line', () => {
    const foldedValue = 'This is a folded scalar. Its content spans the description field.';
    const fields = [
      makeField('name', 'scalar', 'aid-folded-test'),
      makeField('description', 'scalar', foldedValue),
    ];
    const skill = makeSkill('aid-folded-test', fields);
    const page = renderSkillPage(skill);
    expect(page).toContain('**`description`**');
    // The bullet must appear on a single line (no mid-bullet newlines)
    const descBullet = page.split('\n').find((l) => l.startsWith('- **`description`**'));
    expect(descBullet).toBeTruthy();
    expect(descBullet).toContain('This is a folded scalar.');
  });

  it('no field is silently dropped — every key in fields[] has a bullet', () => {
    const fields = [
      makeField('name', 'scalar', 'aid-fullfield-test'),
      makeField('description', 'scalar', 'A skill with many fields.'),
      makeField('allowed-tools', 'scalar', 'Read, Write'),
      makeField('argument-hint', 'scalar', '[hint]'),
      makeField('extra-key', 'scalar', 'extra value'),
    ];
    const skill = makeSkill('aid-fullfield-test', fields);
    const page = renderSkillPage(skill);
    const bulletLines = page.split('\n').filter((l) => l.startsWith('- **`'));
    expect(bulletLines).toHaveLength(fields.length);
  });
});

// ── AC-5: No sidebar: key ─────────────────────────────────────────────────────

describe('no sidebar: key (AC-5)', () => {
  it('does not emit a sidebar: key in the frontmatter', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).not.toContain('sidebar:');
  });

  it('does not emit sidebar: key for a skill with many fields', () => {
    const fields = Array.from({ length: 5 }, (_, i) =>
      makeField(`key-${i}`, 'scalar', `value-${i}`)
    );
    const skill = makeSkill('aid-nosidebar-test', fields);
    const page = renderSkillPage(skill);
    expect(page).not.toContain('sidebar:');
  });
});

// ── AC-6: Description uses skillSummary from summary.mjs ─────────────────────

describe('description comes from skillSummary (AC-6)', () => {
  it('page description is the first sentence of the description field', () => {
    const fields = [
      makeField('name', 'scalar', 'aid-desc-test'),
      makeField('description', 'scalar', 'A short skill. More text after the sentence.'),
    ];
    const skill = makeSkill('aid-desc-test', fields);
    const page = renderSkillPage(skill);
    // First sentence: 'A short skill.'
    expect(page).toContain(`description: 'A short skill.'`);
    // The remainder is not in the frontmatter description
    expect(page).not.toContain(`description: 'A short skill. More text`);
  });

  it('page description uses the fallback sentinel when no description field exists', () => {
    const skill = makeSkill('aid-nodesc', [makeField('name', 'scalar', 'aid-nodesc')]);
    const page = renderSkillPage(skill);
    // Fallback: 'AID skill aid-nodesc — declared frontmatter contract, generated from canonical/.'
    expect(page).toContain(`AID skill aid-nodesc \u2014 declared frontmatter contract`);
  });

  it('render-page.mjs source imports skillSummary from summary.mjs (not a private copy)', () => {
    const src = readFileSync(RENDER_PAGE_SRC, 'utf8');
    expect(src).toMatch(/import.*skillSummary.*from.*summary\.mjs/);
  });

  it('render-page.mjs source does not contain the 157 cap literal (avoids duplicating the rule)', () => {
    const src = readFileSync(RENDER_PAGE_SRC, 'utf8');
    // The 157 cap lives only in summary.mjs; render-page.mjs must not reimplement it.
    expect(src).not.toContain('157');
  });
});

// ── AC-7: Body slot comment (never an empty heading) ─────────────────────────

describe('body slot comment — never an empty heading (AC-7)', () => {
  it('emits the exact body slot comment when both registries are empty', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain(
      '<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->'
    );
  });

  it('does not emit an empty heading instead of the slot comment', () => {
    const page = renderSkillPage(BASELINE);
    // No heading line that has only whitespace after the ## marker
    const headingLines = page.split('\n').filter((l) => /^#+\s*$/.test(l));
    expect(headingLines).toHaveLength(0);
  });

  it('only one ## heading exists in the page (## Frontmatter)', () => {
    const page = renderSkillPage(BASELINE);
    const h2Lines = page.split('\n').filter((l) => /^##\s/.test(l));
    expect(h2Lines).toHaveLength(1);
    expect(h2Lines[0]).toBe('## Frontmatter');
  });
});

// ── AC-8: Body section — blank line separation ───────────────────────────────

describe('page structure — blank lines between sections (AC-8)', () => {
  it('marker is preceded by a blank line (after closing ---)', () => {
    const page = renderSkillPage(BASELINE);
    const lines = page.split('\n');
    const markerLineIdx = lines.findIndex((l) => l.startsWith('<!-- generated'));
    expect(markerLineIdx).toBeGreaterThan(0);
    expect(lines[markerLineIdx - 1]).toBe('');
  });

  it('## Frontmatter is preceded by a blank line', () => {
    const page = renderSkillPage(BASELINE);
    const lines = page.split('\n');
    const sectionIdx = lines.findIndex((l) => l === '## Frontmatter');
    expect(sectionIdx).toBeGreaterThan(0);
    expect(lines[sectionIdx - 1]).toBe('');
  });

  it('[Definition:] link is preceded by a blank line', () => {
    const page = renderSkillPage(BASELINE);
    const lines = page.split('\n');
    const defIdx = lines.findIndex((l) => l.startsWith('[Definition:'));
    expect(defIdx).toBeGreaterThan(0);
    expect(lines[defIdx - 1]).toBe('');
  });

  it('body slot comment is preceded by a blank line', () => {
    const page = renderSkillPage(BASELINE);
    const lines = page.split('\n');
    const slotIdx = lines.findIndex((l) => l.startsWith('<!-- body slot:'));
    expect(slotIdx).toBeGreaterThan(0);
    expect(lines[slotIdx - 1]).toBe('');
  });

  it('page ends with a newline', () => {
    const page = renderSkillPage(BASELINE);
    expect(page.endsWith('\n')).toBe(true);
  });
});

// ── [Definition:] link ────────────────────────────────────────────────────────

describe('[Definition:] source link', () => {
  it('link text includes the repo-relative POSIX source path in a code span', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain('[Definition: `canonical/skills/aid-test-skill/SKILL.md`]');
  });

  it('link href uses the GITHUB_BLOB_BASE from paths.mjs', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain(
      '(https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-test-skill/SKILL.md)'
    );
  });
});

// ── frontmatter field: single-quoted escaping ─────────────────────────────────

describe('page frontmatter single-quoted escaping', () => {
  it("single quotes in the skill description are escaped as '' in the frontmatter block", () => {
    const fields = [
      makeField('name', 'scalar', 'aid-quote-test'),
      makeField('description', 'scalar', "It's a skill. With a quoted word."),
    ];
    const skill = makeSkill('aid-quote-test', fields);
    const page = renderSkillPage(skill);
    // First sentence is "It's a skill." — the ' must be escaped as '' in the YAML frontmatter
    expect(page).toContain("description: 'It''s a skill.'");
  });

  it('generatedFrom uses the repo-relative POSIX path', () => {
    const page = renderSkillPage(BASELINE);
    expect(page).toContain("generatedFrom: 'canonical/skills/aid-test-skill/SKILL.md'");
  });
});

// ── The Frontmatter list must survive a clip-chomped block scalar ─────────────
//
// Every one of the 111 real skill descriptions is a YAML folded block, so the
// parser correctly hands this renderer a value ending in one newline. Emitted
// raw into a bullet that inserts a blank line and breaks the list — on every
// page. The trim lives in renderFrontmatterValue, but the symptom is a PAGE
// defect, so it is pinned here too: these cases fail if that trim is reverted,
// which the earlier fixtures (built without trailing newlines) could not detect.

describe('renderSkillPage — block-scalar values do not break the bullet list', () => {
  const withTrailingNewlines = () =>
    makeSkill('aid-test-skill', [
      makeField('name', 'scalar', 'aid-test-skill'),
      makeField('description', 'scalar', 'A folded description.\n'),
      makeField('argument-hint', 'scalar', 'trailing spaces then newline   \n'),
    ]);

  /** The lines strictly between `## Frontmatter` and the `[Definition:` link. */
  const listLines = (page) => {
    const block = page.slice(page.indexOf('## Frontmatter'), page.indexOf('[Definition:'));
    // Drop the heading, and the blank lines that legitimately bracket the list.
    return block.split('\n').slice(2).filter((l, i, a) => i < a.length - 2);
  };

  it('emits no blank line between bullets', () => {
    const blanks = listLines(renderSkillPage(withTrailingNewlines())).filter((l) => l.trim() === '');
    expect(blanks).toEqual([]);
  });

  it('every line of the header block is a bullet', () => {
    for (const line of listLines(renderSkillPage(withTrailingNewlines()))) {
      expect(line.startsWith('- **`')).toBe(true);
    }
  });

  it('the bullet text itself carries no newline', () => {
    const page = renderSkillPage(withTrailingNewlines());
    const bullet = listLines(page).find((l) => l.includes('`description`'));
    expect(bullet).toContain('A folded description.');
    expect(bullet.endsWith('.')).toBe(true); // no trailing whitespace survived
  });
});
