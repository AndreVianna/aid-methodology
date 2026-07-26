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
