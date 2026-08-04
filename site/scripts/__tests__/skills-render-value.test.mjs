// skills-render-value.test.mjs — Unit tests for renderFrontmatterValue.
//
// Covers every acceptance criterion for task-006:
//   AC-1  < outside code spans escaped; < inside code spans byte-identical
//         (fixture drawn from aid-read-ticket's real description)
//   AC-2  & escaped outside code spans; passed through inside
//   AC-3  | unescaped in both run types
//   AC-4  rule never branches on key name (synthetic key test)
//   AC-5  backtick runs of length 1, 2, 3, 4 each tokenized correctly
//   AC-6  kind: 'list' wraps every item in its own code span, joins with ", "
//   Corpus sweep: all canonical description values with < or & render correctly

import { describe, it, expect } from 'vitest';
// (trailing-whitespace cases live in the "single-line contract" describe below)
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { renderFrontmatterValue } from '../skills/render-value.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../..');
const SKILLS_DIR = resolve(REPO_ROOT, 'canonical/skills');

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Construct a minimal Field object. */
function field(key, kind, value) {
  return { key, kind, value, line: 1 };
}

/**
 * Extracts code spans from a string using CommonMark's backtick-run rule
 * (same rule as renderFrontmatterValue's internal tokenizer).
 * Returns them in source order.
 *
 * @param {string} text
 * @returns {string[]}
 */
function extractCodeSpans(text) {
  const spans = [];
  let i = 0;
  while (i < text.length) {
    if (text[i] === '`') {
      let j = i + 1;
      while (j < text.length && text[j] === '`') j++;
      const runLen = j - i;
      let k = j;
      let found = false;
      while (k < text.length) {
        if (text[k] === '`') {
          let l = k + 1;
          while (l < text.length && text[l] === '`') l++;
          if (l - k === runLen) {
            spans.push(text.slice(i, l));
            i = l;
            found = true;
            break;
          }
          k = l;
        } else {
          k++;
        }
      }
      if (!found) i = j;
    } else {
      i++;
    }
  }
  return spans;
}

/**
 * Returns true if text contains `<` followed by a letter or `/` outside
 * code spans (i.e. an unescaped HTML-tag-like pattern in a text run).
 *
 * @param {string} text
 * @returns {boolean}
 */
function hasUnescapedAngleBracket(text) {
  let i = 0;
  while (i < text.length) {
    if (text[i] === '`') {
      // Skip over the code span
      let j = i + 1;
      while (j < text.length && text[j] === '`') j++;
      const runLen = j - i;
      let k = j;
      let found = false;
      while (k < text.length) {
        if (text[k] === '`') {
          let l = k + 1;
          while (l < text.length && text[l] === '`') l++;
          if (l - k === runLen) {
            i = l;
            found = true;
            break;
          }
          k = l;
        } else {
          k++;
        }
      }
      if (!found) i = j;
    } else {
      if (text[i] === '<' && i + 1 < text.length && /[a-zA-Z/]/.test(text[i + 1])) {
        return true;
      }
      i++;
    }
  }
  return false;
}

// ── AC-6: kind: 'list' ────────────────────────────────────────────────────────

describe('kind: list', () => {
  it('wraps every item in its own code span and joins with ", "', () => {
    expect(renderFrontmatterValue(field('allowed-tools', 'list', ['Read', 'Glob', 'Grep'])))
      .toBe('`Read`, `Glob`, `Grep`');
  });

  it('handles a single item', () => {
    expect(renderFrontmatterValue(field('x', 'list', ['only'])))
      .toBe('`only`');
  });

  it('does not escape | in list items (AC-3)', () => {
    expect(renderFrontmatterValue(field('x', 'list', ['a|b', 'c'])))
      .toBe('`a|b`, `c`');
  });

  it('renders correctly for synthetic key absent from corpus (AC-4)', () => {
    expect(renderFrontmatterValue(field('synthetic-nonexistent-key-xyzzy', 'list', ['foo', 'bar'])))
      .toBe('`foo`, `bar`');
  });
});

// ── AC-1 + AC-2 + AC-3: kind: 'scalar' basic escaping ────────────────────────

describe('kind: scalar — HTML escaping', () => {
  it('escapes < outside code spans to &lt; (AC-1)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '<tag> text')))
      .toBe('&lt;tag> text');
  });

  it('escapes & outside code spans to &amp; (AC-2)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', 'foo & bar')))
      .toBe('foo &amp; bar');
  });

  it('escapes both < and & in plain text', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', 'a < b & c')))
      .toBe('a &lt; b &amp; c');
  });

  it('does not escape | in text runs (AC-3)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', 'foo | bar')))
      .toBe('foo | bar');
  });

  it('passes < inside a code span through byte-identical (AC-1)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '`<tag>`')))
      .toBe('`<tag>`');
  });

  it('passes & inside a code span through byte-identical (AC-2)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '`a & b`')))
      .toBe('`a & b`');
  });

  it('does not escape | inside a code span (AC-3)', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '`a | b`')))
      .toBe('`a | b`');
  });

  it('escapes text runs but preserves code spans in mixed content', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', 'foo <a> `<b>` bar &')))
      .toBe('foo &lt;a> `<b>` bar &amp;');
  });

  it('renders correctly for synthetic key absent from corpus (AC-4)', () => {
    expect(renderFrontmatterValue(field('synthetic-nonexistent-key-xyzzy', 'scalar', '<foo> & `<bar>`')))
      .toBe('&lt;foo> &amp; `<bar>`');
  });
});

// ── AC-1: aid-read-ticket real description fixture ────────────────────────────

describe('aid-read-ticket description fixture (AC-1)', () => {
  // Verbatim folded-block value from canonical/skills/aid-read-ticket/SKILL.md,
  // continuation lines joined with spaces (YAML > folded-block semantics).
  const AID_READ_TICKET_DESCRIPTION =
    'On-demand, non-destructive ticket read. `aid-read-ticket [<connector>:]<ticket-id>` parses the' +
    ' ref (an optional `<stem>:` prefix plus the tracker\'s own id), resolves which issue-tracker' +
    ' connector answers it via the shared connector-resolution ladder (explicit override; a single' +
    ' catalogued issue-tracker connector used silently; a choice asked when two or more are' +
    ' catalogued; the host tool\'s own tracker MCP as fallback; a "no issue-tracker connector found."' +
    ' notice otherwise), fetches the ticket through the host tool\'s own MCP -- AID resolves no' +
    ' credential and stores none -- and displays its fields. Never writes, locally or to the' +
    ' tracker, and never shows a confirmation prompt; a failed, not-found, unauthorized, or' +
    ' unavailable fetch surfaces the tracker\'s error verbatim and exits without side effects.';

  it('passes the first code span byte-identical (contains [<connector>:]<ticket-id>)', () => {
    const rendered = renderFrontmatterValue(field('description', 'scalar', AID_READ_TICKET_DESCRIPTION));
    expect(rendered).toContain('`aid-read-ticket [<connector>:]<ticket-id>`');
  });

  it('passes the second code span byte-identical (contains <stem>:)', () => {
    const rendered = renderFrontmatterValue(field('description', 'scalar', AID_READ_TICKET_DESCRIPTION));
    expect(rendered).toContain('`<stem>:`');
  });

  it('all code spans in rendered output match originals exactly', () => {
    const rendered = renderFrontmatterValue(field('description', 'scalar', AID_READ_TICKET_DESCRIPTION));
    const originalSpans = extractCodeSpans(AID_READ_TICKET_DESCRIPTION);
    const renderedSpans = extractCodeSpans(rendered);
    expect(renderedSpans).toEqual(originalSpans);
  });

  it('no unescaped < appears in text runs (all < in this description are inside code spans)', () => {
    const rendered = renderFrontmatterValue(field('description', 'scalar', AID_READ_TICKET_DESCRIPTION));
    expect(hasUnescapedAngleBracket(rendered)).toBe(false);
  });
});

// ── AC-5: backtick-run tokenization lengths 1–4 ───────────────────────────────

describe('backtick run tokenization (AC-5)', () => {
  it('length-1 run: closed by the next length-1 run', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', 'a `<foo>` b')))
      .toBe('a `<foo>` b');
  });

  it('length-2 run: closed by the next length-2 run, not by length-1', () => {
    // The lone ` in the middle does not close the `` span
    expect(renderFrontmatterValue(field('x', 'scalar', '``<foo>`<bar>``')))
      .toBe('``<foo>`<bar>``');
  });

  it('length-3 run: closed by the next length-3 run, not by shorter runs', () => {
    // The `` in the middle does not close the ``` span
    expect(renderFrontmatterValue(field('x', 'scalar', '```<foo>``<bar>```')))
      .toBe('```<foo>``<bar>```');
  });

  it('length-4 run: closed by the next length-4 run', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '````<foo>````')))
      .toBe('````<foo>````');
  });

  it('length-1 run does not close a length-2 span (reverse check)', () => {
    // Inside `` span, a single ` is content, not a close
    expect(renderFrontmatterValue(field('x', 'scalar', '``<a>`<b>``')))
      .toBe('``<a>`<b>``');
  });

  it('unmatched opening run is literal text; < after it is escaped', () => {
    // Lone ` with no closing ` → treated as text; the following < is in a text run
    expect(renderFrontmatterValue(field('x', 'scalar', '`<foo>')))
      .toBe('`&lt;foo>');
  });

  it('unmatched length-2 run is literal text; < is escaped', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '``<foo>')))
      .toBe('``&lt;foo>');
  });

  it('text before and after code spans is independently escaped', () => {
    expect(renderFrontmatterValue(field('x', 'scalar', '<a> `<b>` <c>')))
      .toBe('&lt;a> `<b>` &lt;c>');
  });
});

// ── Corpus sweep ──────────────────────────────────────────────────────────────

describe('corpus sweep', () => {
  it('no text-run < survives unescaped; no code-span content mutated (all skills)', () => {
    const dirs = readdirSync(SKILLS_DIR)
      .filter(d => {
        try { return statSync(resolve(SKILLS_DIR, d)).isDirectory(); } catch { return false; }
      })
      .sort();

    for (const dir of dirs) {
      let text;
      try {
        text = readFileSync(resolve(SKILLS_DIR, dir, 'SKILL.md'), 'utf8');
      } catch {
        continue;
      }

      // Extract folded description (>, >-, >+) — simple regex extraction
      const match = text.match(/^description:[ \t]*>[- +]?\r?\n((?:[ \t]+[^\r\n]*(?:\r?\n)?)*)/m);
      if (!match) continue;

      const description = match[1]
        .split(/\r?\n/)
        .filter(l => l.trim() !== '')
        .map(l => l.trim())
        .join(' ');

      if (!description.includes('<') && !description.includes('&')) continue;

      const rendered = renderFrontmatterValue({
        key: 'description',
        kind: 'scalar',
        value: description,
        line: 1,
      });

      // Invariant 1: no code-span content was mutated
      const originalSpans = extractCodeSpans(description);
      const renderedSpans = extractCodeSpans(rendered);
      expect(renderedSpans, `${dir}: code-span content mutated`).toEqual(originalSpans);

      // Invariant 2: no text-run < survived unescaped
      expect(
        hasUnescapedAngleBracket(rendered),
        `${dir}: unescaped < in text run after rendering`,
      ).toBe(false);
    }
  });
});

// ── Single-line contract ──────────────────────────────────────────────────────
//
// The output goes into a bullet-list item. A YAML folded/literal block with clip
// chomping (`>` / `|`) legitimately ends in one newline, and the parser is right
// to keep it — but emitted raw into a bullet it inserts a blank line and breaks
// the list. Skill `description` values are authored as folded blocks, so this broke
// every generated page until the trim landed here. The authoring convention is
// stated rather than a count of affected skills, which would go stale unguarded;
// the corpus-wide case is exercised by the real-corpus test below, not asserted here.

describe('renderFrontmatterValue — single-line contract', () => {
  it('strips the trailing newline a clip-chomped folded block carries', () => {
    expect(
      renderFrontmatterValue({ key: 'description', kind: 'scalar', value: 'One sentence.\n', line: 2 })
    ).toBe('One sentence.');
  });

  it('strips multiple trailing newlines and trailing spaces', () => {
    expect(
      renderFrontmatterValue({ key: 'k', kind: 'scalar', value: 'text  \n\n', line: 2 })
    ).toBe('text');
  });

  it('output never contains a newline, for every field of every real skill', async () => {
    // Driven through the real parser rather than a regex, so this exercises the
    // actual pipeline: parseSkillFrontmatter -> renderFrontmatterValue.
    const { parseSkillFrontmatter } = await import('../skills/frontmatter.mjs');
    const dirs = readdirSync(SKILLS_DIR)
      .filter((d) => {
        try { return statSync(resolve(SKILLS_DIR, d)).isDirectory(); } catch { return false; }
      })
      .sort();

    let checked = 0;
    for (const dir of dirs) {
      const file = resolve(SKILLS_DIR, dir, 'SKILL.md');
      let text;
      try { text = readFileSync(file, 'utf8'); } catch { continue; }
      for (const field of parseSkillFrontmatter(text, `canonical/skills/${dir}/SKILL.md`)) {
        const rendered = renderFrontmatterValue(field);
        expect(
          rendered.includes('\n'),
          `${dir}: rendered \`${field.key}\` contains a newline, which breaks the bullet list`
        ).toBe(false);
        checked++;
      }
    }
    // Guard against a vacuous pass if discovery or parsing silently yields nothing.
    expect(checked).toBeGreaterThan(dirs.length);
  });

  it('preserves interior whitespace — only the trailing edge is trimmed', () => {
    expect(
      renderFrontmatterValue({ key: 'k', kind: 'scalar', value: 'a  b\tc.\n', line: 2 })
    ).toBe('a  b\tc.');
  });

  // ── The internal-newline guard ─────────────────────────────────────────────
  //
  // A trailing newline is trimmed; an INTERNAL one cannot be, because there is no
  // correct single-line rendering of a paragraph break — collapsing would
  // misrepresent a `|` literal block and truncating would lose text. So it
  // throws. These cases exist because the guard is otherwise unreachable from any
  // test: no value in the corpus has an internal newline, and CI runs only
  // `npm ci && npm run build` (KI-006 is still open), which makes this throw the
  // ONLY thing standing between a multi-paragraph frontmatter value and a broken
  // page. An untested guard is indistinguishable from an absent one.

  it('throws on a value with an internal newline, naming the key', () => {
    let err;
    try {
      renderFrontmatterValue({ key: 'description', kind: 'scalar', value: 'para one.\n\npara two.', line: 4 });
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toMatch(/multi-line value/);
    expect(err.message).toContain('`description`');
  });

  it.each([
    ['a folded block with a paragraph break', 'one.\n\ntwo.'],
    ['a two-line literal block', 'one.\ntwo.'],
    ['a keep-chomped multi-line block', 'one.\ntwo.\n\n'],
  ])('throws on %s', (_case, value) => {
    expect(() => renderFrontmatterValue({ key: 'k', kind: 'scalar', value, line: 2 })).toThrow(
      /multi-line value/
    );
  });

  it('names the source line when known, and omits the clause when it is not', () => {
    const raise = (line) => {
      try {
        renderFrontmatterValue({ key: 'k', kind: 'scalar', value: 'a\nb', line });
        return '';
      } catch (e) {
        return e.message;
      }
    };
    expect(raise(7)).toContain('(line 7)');
    // A synthetic field carries no source line; the clause must be suppressed
    // rather than emitting a misleading "line 0".
    expect(raise(0)).not.toContain('line 0');
  });

  it('does NOT throw on a single-line value, however much trailing whitespace it has', () => {
    // The negative case: it stops anyone "fixing" the guard into over-firing on
    // the clip-chomped trailing newline that all 111 real descriptions carry.
    expect(() =>
      renderFrontmatterValue({ key: 'k', kind: 'scalar', value: 'just one line.   \n\n\n', line: 1 })
    ).not.toThrow();
    expect(
      renderFrontmatterValue({ key: 'k', kind: 'scalar', value: 'just one line.   \n\n\n', line: 1 })
    ).toBe('just one line.');
  });
});
