// skills-frontmatter.test.mjs — unit tests for site/scripts/skills/frontmatter.mjs
//
// Covers every row of feature-001's parser table, all three throw conditions,
// and proves the parser against the real canonical/skills/ corpus.

import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseSkillFrontmatter } from '../skills/frontmatter.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const SKILLS_DIR = resolve(REPO_ROOT, 'canonical', 'skills');

// ── Helper: build a complete minimal frontmatter document ──────────────────

function fm(body) {
  return `---\n${body}\n---\nBody text here.\n`;
}

// ── Parser fixtures: every row of the parser table ─────────────────────────

describe('parseSkillFrontmatter — fence handling', () => {
  it('parses a minimal LF fence', () => {
    const fields = parseSkillFrontmatter(fm('name: foo'), 'test.md');
    expect(fields).toHaveLength(1);
    expect(fields[0]).toMatchObject({ key: 'name', kind: 'scalar', value: 'foo', line: 2 });
  });

  it('parses a CRLF fence (\\r\\n line endings)', () => {
    // Full CRLF doc
    const doc = '---\r\nname: foo\r\n---\r\n';
    const fields = parseSkillFrontmatter(doc, 'test.md');
    expect(fields).toHaveLength(1);
    expect(fields[0].key).toBe('name');
    expect(fields[0].value).toBe('foo');
  });

  it('throws on missing opening fence', () => {
    expect(() => parseSkillFrontmatter('name: foo\n---\n', 'f.md'))
      .toThrow(/missing opening fence/);
  });

  it('throws on unterminated fence (no closing ---)', () => {
    expect(() => parseSkillFrontmatter('---\nname: foo\n', 'f.md'))
      .toThrow(/unterminated/);
  });

  it('error message includes sourcePath and line number for missing fence', () => {
    expect(() => parseSkillFrontmatter('hello\n', 'canonical/skills/foo/SKILL.md'))
      .toThrow(/canonical\/skills\/foo\/SKILL\.md:1/);
  });

  it('returns empty array for a completely empty fence', () => {
    const fields = parseSkillFrontmatter('---\n---\n', 'test.md');
    expect(fields).toHaveLength(0);
  });
});

describe('parseSkillFrontmatter — key lines', () => {
  it('accepts a lowercase kebab-case key', () => {
    const [f] = parseSkillFrontmatter(fm('my-key: val'), 'test.md');
    expect(f.key).toBe('my-key');
  });

  it('accepts a key with digits', () => {
    const [f] = parseSkillFrontmatter(fm('key123: val'), 'test.md');
    expect(f.key).toBe('key123');
  });

  it('accepts a key with dots', () => {
    const [f] = parseSkillFrontmatter(fm('key.name: val'), 'test.md');
    expect(f.key).toBe('key.name');
  });

  it('accepts a key with uppercase letters', () => {
    const [f] = parseSkillFrontmatter(fm('MyKey: val'), 'test.md');
    expect(f.key).toBe('MyKey');
  });

  it('preserves field source-order (line numbers are correct)', () => {
    const doc = fm('a: 1\nb: 2\nc: 3');
    const fields = parseSkillFrontmatter(doc, 'test.md');
    expect(fields.map((f) => f.key)).toEqual(['a', 'b', 'c']);
    expect(fields[0].line).toBe(2); // line 1 = ---, line 2 = a: 1
    expect(fields[1].line).toBe(3);
    expect(fields[2].line).toBe(4);
  });
});

describe('parseSkillFrontmatter — scalar types', () => {
  it('parses a plain scalar (trimmed)', () => {
    const [f] = parseSkillFrontmatter(fm('name: aid-foo  '), 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('aid-foo');
  });

  it('does not strip # inside a plain scalar value', () => {
    const [f] = parseSkillFrontmatter(fm('desc: value with # hash'), 'test.md');
    expect(f.value).toBe('value with # hash');
  });

  it('parses a single-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm("title: 'hello world'"), 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('hello world');
  });

  it("replaces '' with ' in single-quoted scalars", () => {
    const [f] = parseSkillFrontmatter(fm("title: 'it''s fine'"), 'test.md');
    expect(f.value).toBe("it's fine");
  });

  it('parses a double-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm('title: "hello world"'), 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('hello world');
  });

  it('unescapes \\" in double-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm('msg: "say \\"hi\\""'), 'test.md');
    expect(f.value).toBe('say "hi"');
  });

  it('unescapes \\\\ in double-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm('path: "C:\\\\dir"'), 'test.md');
    expect(f.value).toBe('C:\\dir');
  });

  it('unescapes \\n in double-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm('msg: "line1\\nline2"'), 'test.md');
    expect(f.value).toBe('line1\nline2');
  });

  it('unescapes \\t in double-quoted scalar', () => {
    const [f] = parseSkillFrontmatter(fm('msg: "col1\\tcol2"'), 'test.md');
    expect(f.value).toBe('col1\tcol2');
  });

  it('keeps an empty value as kind:scalar value:""', () => {
    const [f] = parseSkillFrontmatter(fm('empty:'), 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('');
    expect(f.key).toBe('empty');
  });

  it('keeps a whitespace-only post-colon value as empty', () => {
    const [f] = parseSkillFrontmatter(fm('empty:   '), 'test.md');
    // key:   (trailing spaces) — trimmedVal is '' → empty scalar
    // Note: keyMatch[2] is '  ', trimmedVal is '' → empty value path
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('');
  });
});

describe('parseSkillFrontmatter — folded blocks (>)', () => {
  it('joins continuation lines with a space (clip, >)', () => {
    const doc = fm('desc: >\n  Line one\n  Line two\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('Line one Line two\n');
  });

  it('converts a blank continuation line to a paragraph break', () => {
    const doc = fm('desc: >\n  Para one\n\n  Para two\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('Para one\n\nPara two\n');
  });

  it('>- strips trailing newline', () => {
    const doc = fm('desc: >-\n  Line one\n  Line two\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('Line one Line two');
    expect(f.value.endsWith('\n')).toBe(false);
  });

  it('>+ keeps trailing newlines (one trailing blank line → two trailing newlines)', () => {
    // Use a raw doc (not fm()) so the blank-line count is exact.
    // One blank line before closing fence → trailingBlanks = 1 → 'Line one\n\n'
    const doc = '---\ndesc: >+\n  Line one\n\n---\n';
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('Line one\n\n');
  });

  it('>+ with no trailing blank = single trailing newline', () => {
    // No blank line before closing fence → trailingBlanks = 0 → 'Line one\n'
    const doc = '---\ndesc: >+\n  Line one\n---\n';
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('Line one\n');
  });
});

describe('parseSkillFrontmatter — literal blocks (|)', () => {
  it('preserves newlines verbatim (clip, |)', () => {
    const doc = fm('code: |\n  line one\n  line two\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.kind).toBe('scalar');
    expect(f.value).toBe('line one\nline two\n');
  });

  it('|- strips trailing newline', () => {
    const doc = fm('code: |-\n  line one\n  line two\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('line one\nline two');
    expect(f.value.endsWith('\n')).toBe(false);
  });

  it('|+ keeps trailing blank lines', () => {
    // One blank line before closing fence → trailingBlanks = 1 → 'line one\n\n'
    const doc = '---\ncode: |+\n  line one\n\n---\n';
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('line one\n\n');
  });

  it('| preserves internal blank lines as empty lines', () => {
    const doc = fm('code: |\n  A\n\n  B\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toBe('A\n\nB\n');
  });
});

describe('parseSkillFrontmatter — block sequences', () => {
  it('parses a block sequence as kind:list', () => {
    const doc = fm('tools:\n  - Read\n  - Write\n  - Edit\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.kind).toBe('list');
    expect(f.value).toEqual(['Read', 'Write', 'Edit']);
  });

  it('decodes single-quoted items in a block sequence', () => {
    const doc = fm("items:\n  - 'it''s ok'\n  - plain\n");
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toEqual(["it's ok", 'plain']);
  });

  it('decodes double-quoted items in a block sequence', () => {
    const doc = fm('items:\n  - "say \\"hi\\""\n  - plain\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.value).toEqual(['say "hi"', 'plain']);
  });

  it('records the key line number, not the item line number', () => {
    const doc = fm('tools:\n  - Read\n  - Write\n');
    const [f] = parseSkillFrontmatter(doc, 'test.md');
    expect(f.line).toBe(2); // line 1 = ---, line 2 = tools:
  });
});

describe('parseSkillFrontmatter — flow sequences', () => {
  it('parses [a, b, c] as kind:list', () => {
    const [f] = parseSkillFrontmatter(fm('tools: [Read, Write, Edit]'), 'test.md');
    expect(f.kind).toBe('list');
    expect(f.value).toEqual(['Read', 'Write', 'Edit']);
  });

  it('trims whitespace around flow-sequence items', () => {
    const [f] = parseSkillFrontmatter(fm('tools: [ Read , Write ]'), 'test.md');
    expect(f.value).toEqual(['Read', 'Write']);
  });

  it('handles quoted items in a flow sequence', () => {
    const [f] = parseSkillFrontmatter(fm("tags: ['a b', \"c,d\"]"), 'test.md');
    expect(f.value).toEqual(['a b', 'c,d']);
  });

  it('handles an empty flow sequence', () => {
    const [f] = parseSkillFrontmatter(fm('tools: []'), 'test.md');
    expect(f.kind).toBe('list');
    expect(f.value).toEqual([]);
  });
});

describe('parseSkillFrontmatter — blank lines and comments between fields', () => {
  it('skips blank lines between fields', () => {
    const doc = fm('a: 1\n\nb: 2\n');
    const fields = parseSkillFrontmatter(doc, 'test.md');
    expect(fields).toHaveLength(2);
    expect(fields.map((f) => f.key)).toEqual(['a', 'b']);
  });

  it('skips comment lines between fields', () => {
    const doc = fm('a: 1\n# comment\nb: 2\n');
    const fields = parseSkillFrontmatter(doc, 'test.md');
    expect(fields).toHaveLength(2);
    expect(fields.map((f) => f.key)).toEqual(['a', 'b']);
  });

  it('does NOT strip # in the middle of a scalar value', () => {
    const [f] = parseSkillFrontmatter(fm('desc: see https://example.com/#anchor'), 'test.md');
    expect(f.value).toBe('see https://example.com/#anchor');
  });
});

describe('parseSkillFrontmatter — throws', () => {
  it('throws on duplicate key', () => {
    expect(() =>
      parseSkillFrontmatter(fm('name: a\nname: b\n'), 'canonical/skills/x/SKILL.md')
    ).toThrow(/duplicate key/);
  });

  it('duplicate key error names the file, the 1-based line, and the key', () => {
    let err;
    try {
      parseSkillFrontmatter(fm('name: a\nname: b\n'), 'canonical/skills/x/SKILL.md');
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('canonical/skills/x/SKILL.md');
    expect(err.message).toContain("'name'"); // the offending key
    // The duplicate sits on source line 3 — `---` is line 1, `name: a` line 2.
    // Asserted as `<file>:3` so a shifted or 0-based line number fails here.
    expect(err.message).toContain('canonical/skills/x/SKILL.md:3');
    expect(err.message).toContain('name: b'); // the offending text
  });

  it('throws on an unclassifiable line at indent 0', () => {
    // A bare word with no colon is unclassifiable
    expect(() =>
      parseSkillFrontmatter(fm('name: foo\n!invalid\n'), 'f.md')
    ).toThrow(/unclassifiable line/);
  });

  it('unclassifiable error includes the file, the 1-based line number, and the offending text', () => {
    let err;
    try {
      // `---` is line 1, so the offending line is line 2.
      parseSkillFrontmatter(fm('!bad\n'), 'canonical/skills/z/SKILL.md');
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('canonical/skills/z/SKILL.md:2');
    expect(err.message).toContain('!bad');
  });

  it('the reported line number tracks the offending line, not a fixed position', () => {
    // Same defect pushed further down the block: a 0-based or hard-coded line
    // number would pass the case above and fail here.
    let err;
    try {
      parseSkillFrontmatter(fm('name: foo\nargument-hint: bar\n!bad\n'), 'f.md');
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('f.md:4');
  });

  it('throws on missing opening fence — names line 1', () => {
    let err;
    try {
      parseSkillFrontmatter('no fence here\n---\n', 'f.md');
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toMatch(/f\.md:1/);
  });

  it('throws on unterminated fence — names line 1 and ---', () => {
    let err;
    try {
      parseSkillFrontmatter('---\nname: foo\n', 'f.md');
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toMatch(/unterminated/);
    expect(err.message).toMatch(/f\.md:1/);
  });
});

describe('parseSkillFrontmatter — returns ordered array, not object', () => {
  it('returns an Array instance', () => {
    const result = parseSkillFrontmatter(fm('a: 1\nb: 2\n'), 'test.md');
    expect(Array.isArray(result)).toBe(true);
  });

  it('each element has key, kind, value, line', () => {
    const [f] = parseSkillFrontmatter(fm('name: foo\n'), 'test.md');
    expect(typeof f.key).toBe('string');
    expect(f.kind === 'scalar' || f.kind === 'list').toBe(true);
    expect(f.value !== undefined).toBe(true);
    expect(typeof f.line).toBe('number');
  });
});

// ── Real corpus coverage ────────────────────────────────────────────────────
// Prove the parser against every canonical/skills/*/SKILL.md.
// No literal count is asserted (§8); the test derives its set from the filesystem.

describe('parseSkillFrontmatter — real corpus (canonical/skills/)', () => {
  const skillDirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  it('corpus is non-empty', () => {
    expect(skillDirs.length).toBeGreaterThan(0);
  });

  it.each(skillDirs)('parses %s/SKILL.md without throwing', (dirName) => {
    const skillPath = resolve(SKILLS_DIR, dirName, 'SKILL.md');
    const text = readFileSync(skillPath, 'utf8');
    const sourcePath = 'canonical/skills/' + dirName + '/SKILL.md';

    // Must not throw
    let fields;
    expect(() => { fields = parseSkillFrontmatter(text, sourcePath); }).not.toThrow();

    // Must return an array with at least one field
    expect(Array.isArray(fields)).toBe(true);
    expect(fields.length).toBeGreaterThan(0);

    // Every field must have the required shape
    for (const f of fields) {
      expect(typeof f.key).toBe('string');
      expect(f.key.length).toBeGreaterThan(0);
      expect(f.kind === 'scalar' || f.kind === 'list').toBe(true);
      expect(f.value !== undefined).toBe(true);
      expect(typeof f.line).toBe('number');
      expect(f.line).toBeGreaterThan(0);
    }

    // No duplicate keys
    const keys = fields.map((f) => f.key);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('every skill has a "name" field', () => {
    for (const dirName of skillDirs) {
      const skillPath = resolve(SKILLS_DIR, dirName, 'SKILL.md');
      const text = readFileSync(skillPath, 'utf8');
      const fields = parseSkillFrontmatter(
        text,
        'canonical/skills/' + dirName + '/SKILL.md'
      );
      const nameField = fields.find((f) => f.key === 'name');
      expect(nameField).toBeDefined();
      expect(nameField.kind).toBe('scalar');
    }
  });

  it('name field value equals directory name for every skill', () => {
    for (const dirName of skillDirs) {
      const skillPath = resolve(SKILLS_DIR, dirName, 'SKILL.md');
      const text = readFileSync(skillPath, 'utf8');
      const fields = parseSkillFrontmatter(
        text,
        'canonical/skills/' + dirName + '/SKILL.md'
      );
      const nameField = fields.find((f) => f.key === 'name');
      expect(nameField.value).toBe(dirName);
    }
  });
});
