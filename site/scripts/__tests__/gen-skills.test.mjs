// gen-skills.test.mjs — Unit and integration tests for feature-001-skill-detail-pages
//                        and feature-002-grouped-skill-index (task-012 / task-015 / task-017).
//
// Covers every acceptance criterion:
//   AC-1  Drift guard — missing page and orphan page scenarios; corpus coverage.
//   AC-2  Header completeness — every frontmatter key appears on the page,
//         tested both at fixture granularity (driven off the parser) and
//         against the real generated corpus.
//   AC-6  Idempotence — byte comparison of two consecutive runs, no `git` dependency.
//   Parser — every row of feature-001's parser table as an inline fixture, and
//            every parser guard (duplicate key, unclassifiable line, missing/
//            unterminated fence, `name` mismatch) asserted to throw with the
//            file and line in its message.
//   Value rendering — `<`/`&` escaping outside code spans, byte-identical
//            passthrough inside an authored code span.
//   Manifest shape, marker, isolation, stdout discipline.
//   feature-002: catalog load (3a), group assignment (4a), index write (5a),
//                dead card guard (7a), assertNoDeadCards all branches.

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import {
  readFileSync,
  existsSync,
  readdirSync,
  writeFileSync,
  rmSync,
  mkdtempSync,
  mkdirSync,
} from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { execSync, spawnSync } from 'node:child_process';
import { discoverSkills, buildRecord } from '../skills/discover.mjs';
import { loadShortcutCatalog } from '../skills/catalog.mjs';
import { assignGroups } from '../skills/groups.mjs';
import { parseSkillFrontmatter } from '../skills/frontmatter.mjs';
import { renderFrontmatterValue } from '../skills/render-value.mjs';
import { renderSkillPage } from '../skills/render-page.mjs';
// Importing the generator is safe — and is itself a check on the `main()` guard.
// gen-reference.mjs calls main() at module scope, so importing it would
// regenerate four pages as a side effect; gen-skills.mjs must not, and this
// import would run the whole generator on every test file load if it did.
import { assertNoSkillsDrift, assertNoDeadCards, reportFlowWarnings, main } from '../gen-skills.mjs';
import {
  buildFlowChart,
  resetFlowWarnings,
  summarizeFlowWarnings,
} from '../lib/flow-graph/index.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const REPO_ROOT = resolve(__dirname, '../../../');
const SKILLS_OUTPUT_DIR = join(SITE_ROOT, 'src', 'content', 'docs', 'skills');
const MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.skills-manifest.json');
const REFERENCE_MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.reference-manifest.json');
const CANONICAL_SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const GEN_SKILLS_SCRIPT = join(SITE_ROOT, 'scripts', 'gen-skills.mjs');
const GEN_REFERENCE_SCRIPT = join(SITE_ROOT, 'scripts', 'gen-reference.mjs');

// ── Setup: ensure gen-skills has run at least once ────────────────────────────

beforeAll(() => {
  // Run the generator if no pages exist yet.
  const anyPage = existsSync(SKILLS_OUTPUT_DIR) &&
    readdirSync(SKILLS_OUTPUT_DIR).some((f) => f.endsWith('.md') && f !== 'index.md');
  if (!anyPage) {
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Returns sorted array of skill directory names from canonical/skills/. */
function getCanonicalDirNames() {
  return readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();
}

/** Returns sorted array of on-disk page basenames (without .md), excluding index.md. */
function getOnDiskPageNames() {
  if (!existsSync(SKILLS_OUTPUT_DIR)) return [];
  return readdirSync(SKILLS_OUTPUT_DIR)
    .filter((f) => f.endsWith('.md') && f !== 'index.md')
    .map((f) => f.slice(0, -3))
    .sort();
}

// ── Parser — fixtures ─────────────────────────────────────────────────────────
// Every row of feature-001's parser table, each as a small inline fixture
// string, asserted against the exact Field[] the row demands. This is AC-2's
// real test: these are precisely the constructs the old gen-reference.mjs
// parser mishandled (block sequences dropped, folded blocks truncated at a
// blank line, only `>` handled, CRLF fences rejected, digit/dotted keys
// dropped) — none of them present in today's corpus, so a corpus grep alone
// cannot exercise them.

describe('gen-skills: parser — fixtures', () => {
  // The parser table's "Plain scalar" row states that a `#` inside a value is
  // CONTENT, not a comment — only a `#` starting its own line is skipped. That
  // clause had no fixture, which made it the one row of the table a regression
  // could cross silently: adding naive comment-stripping would truncate a real
  // description at the first `#` and nothing would object.
  it('plain scalar: a `#` inside a value is content, not a comment', () => {
    const text = [
      '---',
      'name: test-skill',
      'description: Pass a key (e.g. #tag) to filter. See #notes for detail.',
      '# a comment line of its own IS skipped',
      'argument-hint: --flag=#value',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/hash-in-scalar.md');

    // The `#` and everything after it survives, in both fields.
    expect(fields.find((f) => f.key === 'description').value).toBe(
      'Pass a key (e.g. #tag) to filter. See #notes for detail.'
    );
    expect(fields.find((f) => f.key === 'argument-hint').value).toBe('--flag=#value');
    // …and the standalone comment line contributed no field.
    expect(fields.map((f) => f.key)).toEqual(['name', 'description', 'argument-hint']);
  });

  it('block sequence: `key:` followed by indented `- item` lines yields kind "list"', () => {
    const text = [
      '---',
      'name: test-skill',
      'allowed-tools:',
      '  - Read',
      '  - Glob',
      '  - Grep',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/block-seq.md');
    const field = fields.find((f) => f.key === 'allowed-tools');
    expect(field.kind).toBe('list');
    expect(field.value).toEqual(['Read', 'Glob', 'Grep']);
  });

  it('flow sequence: `key: [a, b, c]` yields kind "list", split on commas', () => {
    const text = ['---', 'name: test-skill', 'tags: [alpha, beta, gamma]', '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/flow-seq.md');
    const field = fields.find((f) => f.key === 'tags');
    expect(field.kind).toBe('list');
    expect(field.value).toEqual(['alpha', 'beta', 'gamma']);
  });

  it('`|` literal block preserves internal newlines verbatim (clip chomping)', () => {
    const text = ['---', 'name: test-skill', 'notes: |', '  line one', '  line two', '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/literal.md');
    const field = fields.find((f) => f.key === 'notes');
    expect(field.kind).toBe('scalar');
    expect(field.value).toBe('line one\nline two\n');
  });

  it('`>-` strip chomping folds lines with a space and adds no trailing newline', () => {
    const text = ['---', 'name: test-skill', 'desc: >-', '  hello', '  world', '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/strip-chomp.md');
    const field = fields.find((f) => f.key === 'desc');
    expect(field.value).toBe('hello world');
  });

  it('`|+` keep chomping preserves every trailing blank line inside the block', () => {
    const text = [
      '---',
      'name: test-skill',
      'raw: |+',
      '  keep me',
      '',
      '',
      'next: after',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/keep-chomp.md');
    const raw = fields.find((f) => f.key === 'raw');
    const next = fields.find((f) => f.key === 'next');
    expect(raw.value).toBe('keep me\n\n\n');
    expect(next.value).toBe('after');
  });

  it('a blank line inside a folded (`>`) block becomes a paragraph break, not a truncation', () => {
    // This is the exact failure mode of the existing gen-reference.mjs parser:
    // `/^\s/.test('')` is false, so it stops collecting continuation lines at
    // the first blank line and silently drops "para two".
    const text = [
      '---',
      'name: test-skill',
      'desc: >',
      '  para one line a',
      '  para one line b',
      '',
      '  para two',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/folded-blank.md');
    const field = fields.find((f) => f.key === 'desc');
    expect(field.value).toBe('para one line a para one line b\n\npara two\n');
  });

  it('CRLF fence and CRLF body lines parse identically to LF (fence tolerates \\r\\n)', () => {
    const text = '---\r\nname: test-skill\r\ndesc: hello world\r\n---\r\nbody text\r\n';
    const fields = parseSkillFrontmatter(text, 'fixtures/crlf.md');
    expect(fields.find((f) => f.key === 'name').value).toBe('test-skill');
    expect(fields.find((f) => f.key === 'desc').value).toBe('hello world');
  });

  it('dotted and digit keys are captured, not dropped by the key regex', () => {
    const text = ['---', 'name: test-skill', 'schema.v2: enabled', 'field3: third', '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/dotted-digit.md');
    expect(fields.find((f) => f.key === 'schema.v2').value).toBe('enabled');
    expect(fields.find((f) => f.key === 'field3').value).toBe('third');
  });

  it('an empty value (`key:` with nothing following) is kept as a field with value ""', () => {
    const text = ['---', 'name: test-skill', 'extra:', '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/empty-value.md');
    const field = fields.find((f) => f.key === 'extra');
    expect(field).toBeDefined();
    expect(field.kind).toBe('scalar');
    expect(field.value).toBe('');
  });

  it('single-quoted scalar: outer quotes removed, \'\'  -> \'', () => {
    const text = ['---', 'name: test-skill', "single: 'it''s fine'", '---', ''].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/single-quoted.md');
    expect(fields.find((f) => f.key === 'single').value).toBe("it's fine");
  });

  it('double-quoted scalar: outer quotes removed, \\n \\t \\" unescaped', () => {
    const text = [
      '---',
      'name: test-skill',
      'double: "line1\\nline2\\ttab \\"quoted\\""',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/double-quoted.md');
    expect(fields.find((f) => f.key === 'double').value).toBe('line1\nline2\ttab "quoted"');
  });

  it('a blank line and a `#` comment between fields are skipped, not treated as fields', () => {
    const text = [
      '---',
      'name: test-skill',
      '',
      '# a comment line',
      'description: after comment',
      '---',
      '',
    ].join('\n');
    const fields = parseSkillFrontmatter(text, 'fixtures/blank-comment.md');
    expect(fields.map((f) => f.key)).toEqual(['name', 'description']);
  });
});

// ── Parser — guards ───────────────────────────────────────────────────────────
// Each guard throws, naming the file and the 1-based line (except name
// mismatch — see the note on that test below, which documents a decision).

describe('gen-skills: parser — guards', () => {
  it('duplicate key throws, naming the file and the 1-based line', () => {
    const text = ['---', 'name: dup-test', 'name: dup-test-again', '---', ''].join('\n');
    expect(() => parseSkillFrontmatter(text, 'fixtures/dup-key.md')).toThrow(
      /duplicate key 'name'.*fixtures\/dup-key\.md:3/
    );
  });

  it('an unclassifiable line at indent 0 throws, naming the file and the 1-based line', () => {
    const text = ['---', 'name: test', 'this has no colon at all', '---', ''].join('\n');
    expect(() => parseSkillFrontmatter(text, 'fixtures/unclassifiable.md')).toThrow(
      /unclassifiable line.*fixtures\/unclassifiable\.md:3/
    );
  });

  it('a missing opening fence throws, naming the file and line 1', () => {
    const text = 'name: test\ndescription: test\n';
    expect(() => parseSkillFrontmatter(text, 'fixtures/no-fence.md')).toThrow(
      /missing opening fence.*fixtures\/no-fence\.md:1/
    );
  });

  it('an unterminated fence throws, naming the file and line 1', () => {
    const text = '---\nname: test\n';
    expect(() => parseSkillFrontmatter(text, 'fixtures/unterminated.md')).toThrow(
      /unterminated frontmatter fence.*fixtures\/unterminated\.md:1/
    );
  });

  describe('name mismatch', () => {
    // buildRecord() accepts an optional skillsDir precisely so this guard is
    // testable against a disposable fixture rather than the real corpus
    // (discover.mjs's own doc comment on the parameter).
    let tmpRoot;

    beforeAll(() => {
      tmpRoot = mkdtempSync(join(tmpdir(), 'gen-skills-name-mismatch-'));
      mkdirSync(join(tmpRoot, 'some-dir-name'));
      writeFileSync(
        join(tmpRoot, 'some-dir-name', 'SKILL.md'),
        '---\nname: wrong-name\ndescription: test\n---\n\nbody\n',
        'utf8'
      );
    });

    afterAll(() => {
      rmSync(tmpRoot, { recursive: true, force: true });
    });

    // task-017 originally asserted only the directory here, because the guard
    // emitted no line number while the other three did — and recorded that gap
    // rather than reaching into `discover.mjs`, which was the right call with a
    // second agent live in the worktree. The guard has since been brought into
    // line, so this now asserts what the acceptance criterion actually asks for:
    // the file AND the 1-based line, like every other guard.
    it('throws when frontmatter name does not match the directory, citing file and line', () => {
      let err;
      try {
        buildRecord('some-dir-name', tmpRoot);
      } catch (e) {
        err = e;
      }
      expect(err).toBeDefined();
      expect(err.message).toMatch(/name mismatch.*some-dir-name.*wrong-name/);
      // `---` is line 1, so `name:` is line 2.
      expect(err.message).toContain('canonical/skills/some-dir-name/SKILL.md:2');
    });
  });
});

// ── Value rendering ───────────────────────────────────────────────────────────
// `<`/`&` escaped outside the author's own code spans; code-span content
// passes through byte-identical; `|` needs no escaping in either run type.

// This is the OVER-escaping half of the escaping contract, and it lives here
// rather than in the index suite for a measured reason: a card's intent is only
// the description's first sentence, and 0 of 111 card intents contain a code span,
// so the construct cannot occur there. The detail pages render the FULL
// description — 70 of 111 carry a code span, 579 in total — so this is where the
// defect could actually appear.
//
// The property asserted is absolute, not derived. Comparing against a
// re-rendered expectation would be tautological: a broken escaper on both sides
// agrees with itself. And the premise is measured rather than assumed — no
// `SKILL.md` frontmatter in the corpus contains an authored HTML entity, so an
// entity inside a rendered code span can only have been put there by the escaper.
describe('gen-skills: escaping — code spans pass through byte-identical', () => {
  it('no rendered code span contains an HTML entity', () => {
    // Renders IN MEMORY from the live corpus rather than reading the generated
    // pages from disk. That is deliberate and it is the second version of this
    // test: the first read `src/content/docs/skills/*.md`, and its freshness
    // turned out to depend on an accidental cross-file ordering coincidence —
    // this file's top-level `beforeAll` only regenerates when no pages exist, so
    // it otherwise reads whatever is committed, and the check only failed under
    // `npm test` because a sibling suite sorts earlier and regenerates
    // unconditionally. Run this file alone and it passed with the defect live.
    //
    // Driving the escaper directly removes the dependency altogether: no disk
    // read, no ordering assumption, no staleness, and it tests the code path
    // rather than a snapshot of its past output.
    const dirs = readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name);
    let spansChecked = 0;

    for (const dir of dirs) {
      const source = join(CANONICAL_SKILLS_DIR, dir, 'SKILL.md');
      if (!existsSync(source)) continue;
      for (const field of parseSkillFrontmatter(readFileSync(source, 'utf8'), dir)) {
        for (const [, inner] of renderFrontmatterValue(field).matchAll(/`+([^`]*)`+/g)) {
          spansChecked++;
          expect(
            inner,
            `${dir}: the escaper altered an authored code span in \`${field.key}\` — ` +
              `entities are not decoded inside code spans, so a reader would see ` +
              `this literally: \`${inner}\``
          ).not.toMatch(/&(?:amp|lt|gt|quot|#\d+);/);
        }
      }
    }

    // Not vacuous, and compared against a derived quantity rather than a literal:
    // the corpus carries authored code spans on more keys than it has skills.
    expect(spansChecked).toBeGreaterThan(dirs.length);
  });
});

describe('gen-skills: value rendering', () => {
  it('escapes < and & outside code spans', () => {
    const field = { key: 'test', kind: 'scalar', value: 'A < B & C', line: 1 };
    expect(renderFrontmatterValue(field)).toBe('A &lt; B &amp; C');
  });

  it('passes < through unescaped inside an authored code span', () => {
    const field = { key: 'test', kind: 'scalar', value: 'before `<inner>` after', line: 1 };
    expect(renderFrontmatterValue(field)).toBe('before `<inner>` after');
  });

  it('escapes the text runs around a code span while leaving the span itself untouched', () => {
    const field = { key: 'test', kind: 'scalar', value: 'A<b> `<code>` C&D', line: 1 };
    expect(renderFrontmatterValue(field)).toBe('A&lt;b> `<code>` C&amp;D');
  });

  it('does not escape | in either a text run or a code span', () => {
    const field = { key: 'test', kind: 'scalar', value: 'a | b `c|d`', line: 1 };
    expect(renderFrontmatterValue(field)).toBe('a | b `c|d`');
  });

  it('renders a list field as comma-joined code spans', () => {
    const field = { key: 'test', kind: 'list', value: ['Read', 'Glob', 'Grep'], line: 1 };
    expect(renderFrontmatterValue(field)).toBe('`Read`, `Glob`, `Grep`');
  });

  it("real fixture: aid-read-ticket's description keeps its <connector>/<ticket-id> placeholders unescaped inside the authored code span", () => {
    const raw = readFileSync(
      join(resolve(dirname(fileURLToPath(import.meta.url)), '../../../'), 'canonical', 'skills', 'aid-read-ticket', 'SKILL.md'),
      'utf8'
    );
    const fields = parseSkillFrontmatter(raw, 'canonical/skills/aid-read-ticket/SKILL.md');
    const descField = fields.find((f) => f.key === 'description');
    expect(descField).toBeDefined();

    const rendered = renderFrontmatterValue(descField);

    // Authored inside backticks in the real file — must survive rendering
    // byte-identical, not become &lt;connector&gt;.
    expect(rendered).toContain('`aid-read-ticket [<connector>:]<ticket-id>`');
    expect(rendered).not.toContain('&lt;connector&gt;');
    expect(rendered).not.toContain('&lt;ticket-id&gt;');
  });
});

// ── AC-2 header completeness — fixture-driven (the real test) ────────────────
// Driven off the parser, not by grepping the rendered corpus, so it stays true
// as the corpus changes — today's corpus has no list-valued frontmatter key,
// so a corpus grep alone cannot prove a list-valued key is rendered rather
// than silently dropped.

describe('gen-skills: AC-2 header completeness — fixture-driven', () => {
  it('every key from a list-valued + multi-line-folded fixture appears on the rendered page', () => {
    const fixtureText = [
      '---',
      'name: fixture-ac2-skill',
      'description: >',
      '  first line of the summary',
      '  continued on a second physical line',
      'allowed-tools:',
      '  - Read',
      '  - Glob',
      '  - Grep',
      'argument-hint: [description]',
      '---',
      '',
      'body text',
    ].join('\n');

    const fields = parseSkillFrontmatter(fixtureText, 'fixtures/ac2.md');
    const skill = {
      dirName: 'fixture-ac2-skill',
      fields,
      field(k) {
        return fields.find((f) => f.key === k);
      },
      body: 'body text\n',
      bodyStartLine: 13,
      lineCount: 13,
      referencesDir: null,
    };

    const page = renderSkillPage(skill);

    // AC-2: no key is silently dropped.
    for (const field of fields) {
      expect(page).toContain(`**\`${field.key}\`**`);
    }

    // The specific case the old parser mishandled: a list-valued key must
    // render its items, not an empty string.
    expect(page).toContain('`Read`, `Glob`, `Grep`');
  });
});

// ── AC-1 / Corpus coverage: one page per skill directory ─────────────────────

describe('gen-skills: AC-1 corpus coverage', () => {
  it('every canonical/skills/ directory has a generated page', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    const missing = dirNames.filter((d) => !pageNames.includes(d));
    expect(missing).toEqual([]);
  });

  it('no generated page exists without a canonical/skills/ directory', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    const orphans = pageNames.filter((p) => !dirNames.includes(p));
    expect(orphans).toEqual([]);
  });

  it('index.md is excluded from the on-disk comparison', () => {
    const pageNames = getOnDiskPageNames();
    expect(pageNames).not.toContain('index');
  });

  it('page count matches directory count — derived, no literal', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    expect(pageNames).toHaveLength(dirNames.length);
  });
});

// Note on "missing page" guard direction:
// The generator's drift guard runs AFTER the write pass. Since the write pass
// writes all expected pages unconditionally, the "missing pages" branch of the
// on-disk guard is architecturally unreachable in a successfully-executing
// generator (a deleted file is always regenerated before the guard checks).
// The write pass self-healing behaviour is implicitly covered by the corpus
// coverage tests above (which verify all pages exist after a run) and by the
// AC-6 idempotence test (which runs twice and compares bytes).
// The orphan page test below covers the reachable "orphan pages:" guard branch.

// ── AC-1 / Drift guard: orphan page scenario ─────────────────────────────────

describe('gen-skills: drift guard — orphan page', () => {
  const ORPHAN_NAME = '__test-orphan-skill__';
  const ORPHAN_PATH = join(SKILLS_OUTPUT_DIR, ORPHAN_NAME + '.md');

  it('throws when a synthetic orphan page is on disk, names it, gives git rm remedy, does not delete it', () => {
    // Create a synthetic orphan page (no corresponding canonical/skills/ directory).
    writeFileSync(ORPHAN_PATH, '---\ntitle: orphan\n---\n', 'utf8');
    expect(existsSync(ORPHAN_PATH)).toBe(true);

    // Run the generator — it writes all real pages, then the drift guard runs.
    const result = spawnSync('node', ['scripts/gen-skills.mjs'], {
      cwd: SITE_ROOT,
      encoding: 'utf8',
    });

    // Generator should exit 1.
    expect(result.status).toBe(1);

    // The error message should name the orphan.
    const errMsg = result.stderr || '';
    expect(errMsg).toContain(ORPHAN_NAME);

    // The error message should include "orphan pages:".
    expect(errMsg).toContain('orphan pages:');

    // The error message should include the git rm remedy.
    expect(errMsg).toContain('git rm');

    // The orphan page must NOT have been deleted — auto-pruning is forbidden.
    expect(existsSync(ORPHAN_PATH)).toBe(true);
  });

  afterAll(() => {
    // Clean up the synthetic orphan page.
    if (existsSync(ORPHAN_PATH)) {
      rmSync(ORPHAN_PATH);
    }
  });
});

// ── AC-2 / Header completeness: every frontmatter key appears on each page ───

describe('gen-skills: AC-2 header completeness', () => {
  it('every SKILL.md frontmatter key appears in the rendered Frontmatter section', () => {
    const skills = discoverSkills();
    for (const skill of skills) {
      const pagePath = join(SKILLS_OUTPUT_DIR, skill.dirName + '.md');
      const pageContent = readFileSync(pagePath, 'utf8');
      for (const field of skill.fields) {
        expect(pageContent).toContain(`**\`${field.key}\`**`);
      }
    }
  });
});

// ── Marker: "generated — do not edit" on every page ─────────────────────────

describe('gen-skills: generated marker', () => {
  it('every page contains "generated \u2014 do not edit" (em-dash)', () => {
    const dirNames = getCanonicalDirNames();
    for (const dir of dirNames) {
      const content = readFileSync(join(SKILLS_OUTPUT_DIR, dir + '.md'), 'utf8');
      expect(content).toContain('generated \u2014 do not edit');
    }
  });
});

// ── Manifest shape ────────────────────────────────────────────────────────────

describe('gen-skills: .skills-manifest.json shape', () => {
  let manifest;

  beforeAll(() => {
    manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
  });

  it('manifest has generator, entries, generatedPaths fields', () => {
    expect(manifest).toHaveProperty('generator');
    expect(manifest).toHaveProperty('entries');
    expect(manifest).toHaveProperty('generatedPaths');
  });

  it('manifest.generator identifies gen-skills.mjs', () => {
    expect(manifest.generator).toContain('gen-skills.mjs');
  });

  it('manifest has no generatedAt field (determinism: no wall-clock timestamps)', () => {
    expect(manifest).not.toHaveProperty('generatedAt');
    // Also check the raw JSON string has no timestamp-like field.
    const raw = readFileSync(MANIFEST_PATH, 'utf8');
    expect(raw).not.toContain('generatedAt');
  });

  it('manifest.entries count is directory count + 1 (skill pages + index row) — derived, no literal', () => {
    const dirNames = getCanonicalDirNames();
    // +1 for the index entry (src: canonical/skills/*/SKILL.md, ...)
    expect(manifest.entries).toHaveLength(dirNames.length + 1);
  });

  it('manifest.entries are ordered by src ascending (literal string comparison, no localeCompare)', () => {
    // Task-015: entries are sorted by full src string (pure string comparison).
    // '*' (code point 42) < 'a' (97), so the index row lands first.
    // This differs from directory-name sort for pairs where one name is a prefix
    // of another (e.g. 'aid-add-api/SKILL.md' < 'aid-add/SKILL.md' because
    // '-' (45) < '/' (47) at the divergence point).
    const entries = manifest.entries;
    expect(entries.length).toBeGreaterThan(1);

    // The index row must be first.
    expect(entries[0].src).toBe(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
    expect(entries[0].dest).toBe('site/src/content/docs/skills/index.md');

    // All consecutive pairs must satisfy strict ascending literal order.
    for (let i = 1; i < entries.length; i++) {
      expect(entries[i - 1].src < entries[i].src).toBe(true);
    }

    // Skill entries (all but the first) must cover exactly the canonical dirs.
    const dirNames = getCanonicalDirNames(); // directory-name sort order
    const skillSrcs = entries.slice(1).map((e) => e.src);
    // Same set, regardless of which sort order they arrived in.
    const expectedSkillSrcs = dirNames.map((d) => 'canonical/skills/' + d + '/SKILL.md').sort();
    expect(skillSrcs.slice().sort()).toEqual(expectedSkillSrcs);
  });

  it('manifest.entries each have src and dest as POSIX repo-relative strings', () => {
    for (const entry of manifest.entries) {
      // No Windows backslashes anywhere.
      expect(entry.src).not.toContain('\\');
      expect(entry.dest).not.toContain('\\');
      // dest always points at site/src/content/docs/skills/*.md
      expect(entry.dest).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }

    // Skill entries (all but index row) must match the single-source pattern.
    for (const entry of manifest.entries.slice(1)) {
      expect(entry.src).toMatch(/^canonical\/skills\/[^/]+\/SKILL\.md$/);
    }

    // The index entry (first) has the two-source src.
    const indexEntry = manifest.entries[0];
    expect(indexEntry.src).toBe(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
    expect(indexEntry.dest).toBe('site/src/content/docs/skills/index.md');
  });

  it('manifest.generatedPaths has directory count + 1 entries, all POSIX, includes index.md', () => {
    const dirNames = getCanonicalDirNames();
    // +1 for index.md
    expect(manifest.generatedPaths).toHaveLength(dirNames.length + 1);
    for (const p of manifest.generatedPaths) {
      expect(p).not.toContain('\\');
      expect(p).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }
    expect(manifest.generatedPaths).toContain('site/src/content/docs/skills/index.md');
  });

  it('manifest JSON ends with exactly one trailing newline and is two-space indented', () => {
    const raw = readFileSync(MANIFEST_PATH, 'utf8');
    expect(raw.endsWith('\n')).toBe(true);
    expect(raw.endsWith('\n\n')).toBe(false);
    // Two-space indented: second line starts with two spaces.
    const lines = raw.split('\n');
    const firstIndented = lines.find((l) => l.startsWith('  ') && !l.startsWith('   '));
    expect(firstIndented).toBeDefined();
  });
});

// ── AC-6 / Idempotence: byte comparison of two consecutive runs ───────────────

describe('gen-skills: AC-6 idempotence by byte comparison', () => {
  it('two consecutive runs produce byte-identical skill pages, index.md, and manifest', () => {
    // Run 1.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Capture byte content after run 1.
    const dirNames = getCanonicalDirNames();
    const run1Pages = new Map();
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      run1Pages.set(dir, readFileSync(p));
    }
    const run1Index = readFileSync(join(SKILLS_OUTPUT_DIR, 'index.md'));
    const run1Manifest = readFileSync(MANIFEST_PATH);

    // Run 2.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Compare skill page bytes.
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      const run2Content = readFileSync(p);
      const run1Content = run1Pages.get(dir);
      expect(run2Content.equals(run1Content)).toBe(true);
    }

    // Compare index.md bytes (AC-6 for the index page).
    const run2Index = readFileSync(join(SKILLS_OUTPUT_DIR, 'index.md'));
    expect(run2Index.equals(run1Index)).toBe(true);

    // Compare manifest bytes.
    const run2Manifest = readFileSync(MANIFEST_PATH);
    expect(run2Manifest.equals(run1Manifest)).toBe(true);
  });
});

// ── Stdout discipline: four phase lines, then the flow report ────────────────

describe('gen-skills: stdout discipline', () => {
  it('successful run emits the four phase lines in order and nothing on stderr', () => {
    const result = spawnSync('node', ['scripts/gen-skills.mjs'], {
      cwd: SITE_ROOT,
      encoding: 'utf8',
    });

    expect(result.status).toBe(0);

    // stderr must be empty on success.
    expect(result.stderr || '').toBe('');

    const lines = (result.stdout || '').split('\n').filter((l) => l.trim() !== '');

    // The four phase lines are the first four, in order. The count is no longer
    // pinned at four: step 8 appends a flow-warning report whose length tracks the
    // corpus. Pinning a total here would either forbid the report or turn a corpus
    // change into an unrelated failure, so the shape below is asserted instead —
    // four phase lines, then only report lines.
    const phase = lines.slice(0, 4);

    // Line 1: start message.
    expect(phase[0]).toContain('[gen-skills] generating');

    // Line 2: parsed N skills — count derived, not literal.
    expect(phase[1]).toMatch(/^\[gen-skills\] parsed \d+ skills$/);

    // Line 3: wrote N pages.
    expect(phase[2]).toMatch(/^\[gen-skills\] wrote \d+ pages -> src\/content\/docs\/skills\/$/);

    // Line 4: manifest.
    expect(phase[3]).toBe('[gen-skills] wrote scripts/.skills-manifest.json');

    // The counts in lines 2 and 3 must match the actual directory count.
    const dirCount = getCanonicalDirNames().length;
    expect(phase[1]).toBe(`[gen-skills] parsed ${dirCount} skills`);
    expect(phase[2]).toBe(`[gen-skills] wrote ${dirCount} pages -> src/content/docs/skills/`);

    // Anything after the four phase lines belongs to the flow report: one header
    // followed by one indented line per warning. Nothing else may print.
    const rest = lines.slice(4);
    if (rest.length > 0) {
      expect(rest[0]).toMatch(/^\[gen-skills\] flow: \d+ warnings? across \d+ charts?/);
      for (const line of rest.slice(1)) {
        expect(line).toMatch(/^ {2}\[gen-skills\] /);
      }
      // The header's chart count must equal the number of distinct skills it names.
      const named = rest[0].replace(/^.*\(/, '').replace(/\)\s*$/, '').split(', ');
      expect(rest[0]).toContain(`across ${named.length} chart`);
    }
  });
});

// ── Isolation: gen-reference.mjs is byte-unmodified and not imported ──────────

describe('gen-skills: isolation from gen-reference', () => {
  it('gen-reference.mjs is byte-unmodified after gen-skills run', () => {
    // Read gen-reference.mjs bytes before a gen-skills run.
    const before = readFileSync(GEN_REFERENCE_SCRIPT);

    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Read after.
    const after = readFileSync(GEN_REFERENCE_SCRIPT);
    expect(after.equals(before)).toBe(true);
  });

  it('.reference-manifest.json is unchanged after gen-skills run', () => {
    const before = readFileSync(REFERENCE_MANIFEST_PATH);
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
    const after = readFileSync(REFERENCE_MANIFEST_PATH);
    expect(after.equals(before)).toBe(true);
  });

  it('the four reference pages are unchanged after gen-skills run', () => {
    const refPages = [
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'skills.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'agents.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'kb.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'settings.md'),
    ];

    const before = refPages.map((p) => readFileSync(p));
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
    const after = refPages.map((p) => readFileSync(p));

    for (let i = 0; i < refPages.length; i++) {
      expect(after[i].equals(before[i])).toBe(true);
    }
  });
});

// ── AC-1 drift guard, every branch ───────────────────────────────────────────
//
// Called from main() the guard runs after the write pass, so two of its four
// branches cannot fire there — a page has just been written for every discovered
// skill. Driving the exported function directly is what makes them reachable;
// left untested they would be indistinguishable from branches that do not work.
// The orphan-on-disk path is additionally proven end-to-end, against the real
// generator in a subprocess, in the suite above.

describe('assertNoSkillsDrift — all four branches', () => {
  const ok = { expected: ['a', 'b'], written: ['a', 'b'], onDisk: ['a', 'b'] };

  it('passes when all three sets agree', () => {
    expect(() => assertNoSkillsDrift(ok)).not.toThrow();
  });

  it('throws when the write pass missed a discovered skill', () => {
    expect(() => assertNoSkillsDrift({ ...ok, written: ['a'] })).toThrow(
      /skills drift: write pass diverged from discovery\. missing pages: b/
    );
  });

  it('throws when the write pass produced a page for an undiscovered skill', () => {
    expect(() => assertNoSkillsDrift({ ...ok, written: ['a', 'b', 'zz'] })).toThrow(
      /write pass diverged from discovery\. orphan pages: zz/
    );
  });

  it('throws when a discovered skill has no page on disk', () => {
    expect(() => assertNoSkillsDrift({ ...ok, onDisk: ['a'] })).toThrow(
      /\[gen-skills\] skills drift: missing pages: b/
    );
  });

  it('throws when a page on disk has no skill, naming it with the git rm remedy', () => {
    let err;
    try {
      assertNoSkillsDrift({ ...ok, onDisk: ['a', 'b', 'aid-deleted'] });
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('orphan pages: aid-deleted');
    expect(err.message).toContain('git rm site/src/content/docs/skills/aid-deleted.md');
  });

  it('reports both deltas at once, each under its own label', () => {
    let err;
    try {
      assertNoSkillsDrift({ expected: ['a', 'b'], written: ['a', 'b'], onDisk: ['a', 'zz'] });
    } catch (e) {
      err = e;
    }
    expect(err.message).toContain('missing pages: b');
    expect(err.message).toContain('orphan pages: zz');
  });

  it('reports each delta sorted', () => {
    let err;
    try {
      assertNoSkillsDrift({
        expected: ['a'],
        written: ['a'],
        onDisk: ['a', 'zz', 'mm', 'bb'].sort(),
      });
    } catch (e) {
      err = e;
    }
    expect(err.message).toContain('orphan pages: bb, mm, zz');
  });
});

// ── feature-002: step 3a CATALOG load ─────────────────────────────────────────

describe('gen-skills: step 3a catalog load', () => {
  it('loadShortcutCatalog returns rows in file order and a byName Map', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    // rows is a non-empty array in file order.
    expect(Array.isArray(catalog.rows)).toBe(true);
    expect(catalog.rows.length).toBeGreaterThan(0);
    // byName is a Map covering the same names.
    expect(catalog.byName).toBeInstanceOf(Map);
    expect(catalog.byName.size).toBe(catalog.rows.length);
    // Every row has a name and a verb.
    for (const row of catalog.rows) {
      expect(typeof row.name).toBe('string');
      expect(typeof row.verb).toBe('string');
    }
  });

  it('the real catalog loads, and every row it yields is well-formed', () => {
    // Deliberately NOT "catalog row count matches manifest skill count" — it never
    // checked that and the counts are not equal by design: catalog rows cover
    // classic and shortcut skills, curated and not, while the manifest has one
    // row per skill directory plus the index. What matters here is that the real
    // file was loaded rather than a stub, so downstream assertions are not
    // vacuously true over an empty array.
    const catalog = loadShortcutCatalog(REPO_ROOT);

    // Row count derived from the file itself, never a literal (§8; the defect
    // class that produced KI-005).
    const raw = readFileSync(join(REPO_ROOT, 'canonical/aid/templates/shortcut-catalog.yml'), 'utf8');
    const declared = (raw.match(/^ {2}- name:/gm) || []).length;
    expect(declared).toBeGreaterThan(0);
    expect(catalog.rows).toHaveLength(declared);

    for (const row of catalog.rows) {
      expect(row.name, 'every catalog row has a name').toBeTruthy();
      expect(row.verb, `${row.name} has a verb`).toBeTruthy();
      expect(catalog.byName.get(row.name)).toBe(row);
    }
  });
});

// ── feature-002: step 4a ASSIGN ────────────────────────────────────────────────

describe('gen-skills: step 4a group assignment', () => {
  it('assignGroups returns four sections: Support, Knowledge Base Maintenance, Definition, Execution', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    expect(sections).toHaveLength(4);
    expect(sections.map((s) => s.group)).toEqual([
      'Support',
      'Knowledge Base Maintenance',
      'Definition',
      'Execution',
    ]);
  });

  it('every skill has exactly one card across all sections — derived count, no literal', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);

    // Collect all card names from all sections and families.
    const cardNames = [];
    for (const section of sections) {
      for (const card of section.cards) cardNames.push(card.name);
      for (const family of section.families) {
        for (const card of family.cards) cardNames.push(card.name);
      }
    }

    // Each skill must appear exactly once.
    const skillDirNames = skills.map((s) => s.dirName);
    expect(cardNames.sort()).toEqual(skillDirNames.sort());
  });

  it('Definition section has families (verb subdivisions)', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    const definition = sections.find((s) => s.group === 'Definition');
    expect(definition).toBeDefined();
    expect(definition.families.length).toBeGreaterThan(0);
  });

  it('non-Definition sections have no families', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    for (const section of sections) {
      if (section.group !== 'Definition') {
        expect(section.families).toHaveLength(0);
      }
    }
  });
});

// ── feature-002: step 5a INDEX write ──────────────────────────────────────────

describe('gen-skills: step 5a index page', () => {
  const INDEX_PATH = join(SKILLS_OUTPUT_DIR, 'index.md');

  it('index.md exists after a gen-skills run', () => {
    expect(existsSync(INDEX_PATH)).toBe(true);
  });

  it('index.md has a generatedFrom frontmatter field with the two-source string', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    // The two-source string must appear exactly in the frontmatter.
    expect(content).toContain(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
  });

  it('index.md generatedFrom matches the manifest index entry src — one string, three places', () => {
    // Three places: gen-reference.mjs:447 generatedFrom, manifest index entry src,
    // and index.md frontmatter generatedFrom. All three must be byte-identical.
    const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
    const indexEntry = manifest.entries.find((e) => e.dest === 'site/src/content/docs/skills/index.md');
    expect(indexEntry).toBeDefined();

    const content = readFileSync(INDEX_PATH, 'utf8');
    // The manifest src string must appear verbatim in the page.
    expect(content).toContain(indexEntry.src);
  });

  it('index.md has the "generated — do not edit" marker (em-dash)', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('generated \u2014 do not edit');
  });

  it('index.md has sidebar: hidden: true in frontmatter', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('sidebar:');
    expect(content).toContain('hidden: true');
  });

  it('index.md contains one ## heading per group (Support, Knowledge Base Maintenance, Definition, Execution)', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('## Support');
    expect(content).toContain('## Knowledge Base Maintenance');
    expect(content).toContain('## Definition');
    expect(content).toContain('## Execution');
  });

  it('index.md has LF line endings, no CRLF', () => {
    const raw = readFileSync(INDEX_PATH, 'utf8');
    expect(raw).not.toContain('\r');
  });

  it('index.md ends with a trailing newline', () => {
    const raw = readFileSync(INDEX_PATH, 'utf8');
    expect(raw.endsWith('\n')).toBe(true);
  });
});

// ── feature-002: step 7a assertNoDeadCards — all branches ────────────────────
//
// Called from main() after both writes, the guard is architecturally unreachable
// in a correctly-executing generator — assignGroups() only produces cards from
// SkillRecords that were just written. Driving the exported function directly is
// what makes every branch testable; left untested they would be indistinguishable
// from absent code.

describe('assertNoDeadCards — all branches', () => {
  // Minimal section shape: two sections, one with families.
  const makeSection = (groupCards, familyCards = []) => ({
    group: 'Test',
    blurb: '',
    cards: groupCards,
    families: familyCards.length
      ? [{ verb: 'test-verb', cards: familyCards }]
      : [],
  });

  it('passes when all cards are in the written set', () => {
    const sections = [
      makeSection([{ name: 'a', route: '/skills/a/' }]),
      makeSection([], [{ name: 'b', route: '/skills/b/' }]),
    ];
    expect(() => assertNoDeadCards(sections, ['a', 'b'])).not.toThrow();
  });

  it('passes when written set has more entries than cards (extra pages are fine)', () => {
    const sections = [makeSection([{ name: 'a', route: '/skills/a/' }])];
    expect(() => assertNoDeadCards(sections, ['a', 'b', 'c'])).not.toThrow();
  });

  it('throws [gen-skills] dead card when a section card is missing from written', () => {
    const sections = [
      makeSection([
        { name: 'a', route: '/skills/a/' },
        { name: 'missing-skill', route: '/skills/missing-skill/' },
      ]),
    ];
    expect(() => assertNoDeadCards(sections, ['a'])).toThrow(
      /\[gen-skills\] dead card:.*missing-skill/
    );
  });

  it('throws [gen-skills] dead card when a family card is missing from written', () => {
    const sections = [
      makeSection(
        [{ name: 'a', route: '/skills/a/' }],
        [{ name: 'ghost-skill', route: '/skills/ghost-skill/' }]
      ),
    ];
    expect(() => assertNoDeadCards(sections, ['a'])).toThrow(
      /\[gen-skills\] dead card:.*ghost-skill/
    );
  });

  it('names the specific offending card in the error message', () => {
    const sections = [
      makeSection([{ name: 'xyz-offender', route: '/skills/xyz-offender/' }]),
    ];
    let err;
    try {
      assertNoDeadCards(sections, []);
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('[gen-skills] dead card:');
    expect(err.message).toContain('xyz-offender');
  });

  it('passes with empty sections', () => {
    expect(() => assertNoDeadCards([], [])).not.toThrow();
    expect(() => assertNoDeadCards([], ['a', 'b'])).not.toThrow();
  });

  it('passes with sections that have no cards or families', () => {
    const sections = [makeSection([]), makeSection([], [])];
    expect(() => assertNoDeadCards(sections, [])).not.toThrow();
  });
});

// ── Run-level flow-warning report (task-029 AC: "logged with a run-level count") ──

describe('flow warnings reach a human', () => {
  // task-029 shipped a module-level counter and removed it because nothing read it.
  // The reader is the part that was missing; these tests assert the reader, not the
  // counter — a count no one prints is the defect that got the counter deleted.

  it('a clean run reports nothing, so any output is signal', () => {
    resetFlowWarnings();
    const lines = [];
    const result = reportFlowWarnings((m) => lines.push(m));
    expect(result).toEqual({ total: 0, charts: 0 });
    expect(lines).toEqual([]);
  });

  it('counts charts and warnings separately — one chart can carry several', () => {
    resetFlowWarnings();
    // aid-update-kb carries two: a multiple-terminal-clauses warning from the
    // CONFIRM row and the W-1 residue from REVIEW's dropped fourth outcome.
    buildFlowChart({ name: 'aid-update-kb', dir: REPO_ROOT });
    const s = summarizeFlowWarnings();
    expect(s.charts).toBe(1);
    expect(s.total).toBeGreaterThan(1);
    expect(s.skills).toEqual(['aid-update-kb']);
    expect(s.messages).toHaveLength(s.total);
  });

  it('prints the count, the skill names, and every message', () => {
    resetFlowWarnings();
    buildFlowChart({ name: 'aid-update-kb', dir: REPO_ROOT });
    const lines = [];
    const { total, charts } = reportFlowWarnings((m) => lines.push(m));

    expect(charts).toBe(1);
    expect(lines[0]).toContain(`${total} warnings across 1 chart`);
    expect(lines[0]).toContain('aid-update-kb');
    // One line per message, after the header.
    expect(lines).toHaveLength(total + 1);
    // The dropped outcome from row 19 is among them — the specific thing whose
    // invisibility made row 19's justification hollow before this existed.
    expect(lines.join('\n')).toContain('grade/teach-back/act-back/TRACE-1');
  });

  it('resetFlowWarnings makes a second run report its own total, not a running one', () => {
    resetFlowWarnings();
    buildFlowChart({ name: 'aid-update-kb', dir: REPO_ROOT });
    const first = summarizeFlowWarnings().total;
    expect(first).toBeGreaterThan(0);

    // Without the reset, building the same chart again would double the count.
    buildFlowChart({ name: 'aid-update-kb', dir: REPO_ROOT });
    expect(summarizeFlowWarnings().total).toBe(first * 2);

    resetFlowWarnings();
    buildFlowChart({ name: 'aid-update-kb', dir: REPO_ROOT });
    expect(summarizeFlowWarnings().total).toBe(first);
  });

  it('a chart with no warnings does not enter the accumulator', () => {
    resetFlowWarnings();
    // aid-discover charts clean — it is the skill whose label row 17 repaired.
    buildFlowChart({ name: 'aid-discover', dir: REPO_ROOT });
    expect(summarizeFlowWarnings()).toEqual({
      total: 0, charts: 0, skills: [], messages: [],
    });
  });

  it('main() resets, so a second run in one process reports its own total', async () => {
    // The reset is invisible to any subprocess test: a fresh process starts empty
    // either way. Only a second in-process run can observe it, which is why main()
    // is exported. Without the reset, run 2 reports run 1's total plus its own.
    await main();
    const first = summarizeFlowWarnings().total;
    expect(first).toBeGreaterThan(0); // non-vacuity — silence would prove nothing

    await main();
    expect(summarizeFlowWarnings().total).toBe(first);
  }, 60_000);

  it('gen-skills wires the reader in — the summary appears on stdout, not stderr', () => {
    const run = spawnSync(process.execPath, [join(SITE_ROOT, 'scripts', 'gen-skills.mjs')], {
      cwd: SITE_ROOT, encoding: 'utf8',
    });
    expect(run.status).toBe(0);
    expect(run.stderr).toBe('');
    expect(run.stdout).toMatch(/\[gen-skills\] flow: \d+ warnings? across \d+ charts?/);
  });
});
