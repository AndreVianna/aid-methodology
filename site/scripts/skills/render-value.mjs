// render-value.mjs — Code-span-aware frontmatter value renderer.
//
// Pure exported function; no import-time side effect.

/**
 * Tokenizes a scalar string into alternating text and code-span runs.
 *
 * CommonMark backtick-run rule: a code span is opened by a run of N backticks
 * and closed by the next run of exactly N backticks. A run that finds no
 * matching close is treated as literal text; scanning resumes immediately
 * after the unmatched opening run.
 *
 * @param {string} text
 * @returns {Array<{type: 'code'|'text', content: string}>}
 */
function tokenize(text) {
  const tokens = [];
  let i = 0;
  while (i < text.length) {
    if (text[i] === '`') {
      // Measure the opening backtick run
      let j = i + 1;
      while (j < text.length && text[j] === '`') j++;
      const runLen = j - i;
      // Search for a closing run of exactly the same length
      let k = j;
      let found = false;
      while (k < text.length) {
        if (text[k] === '`') {
          let l = k + 1;
          while (l < text.length && text[l] === '`') l++;
          if (l - k === runLen) {
            tokens.push({ type: 'code', content: text.slice(i, l) });
            i = l;
            found = true;
            break;
          }
          k = l;
        } else {
          k++;
        }
      }
      if (!found) {
        // No matching close — the opening run is literal text
        tokens.push({ type: 'text', content: text.slice(i, j) });
        i = j;
      }
    } else {
      // Accumulate text up to the next backtick
      let j = i + 1;
      while (j < text.length && text[j] !== '`') j++;
      tokens.push({ type: 'text', content: text.slice(i, j) });
      i = j;
    }
  }
  return tokens;
}

/**
 * Renders a parsed frontmatter field to a markdown string.
 * Keyed on field.kind only — never on the key's name.
 *
 * - kind: 'list'   → each item wrapped in a code span, joined with `, `
 *                    e.g. [`a`, `b`, `c`]  →  "`a`, `b`, `c`"
 * - kind: 'scalar' → value with `&` → `&amp;` and `<` → `&lt;` applied only
 *                    outside the author's own inline code spans; code-span runs
 *                    pass through byte-identical; `|` is never escaped in either
 *                    run type.
 *
 * The result is a SINGLE-LINE inline rendering, suitable for a bullet-list item
 * or a card. Trailing newlines are stripped: a YAML folded or literal block with
 * clip chomping (`>` / `|`) legitimately ends in one newline, which the parser is
 * right to preserve — but emitted raw into a bullet it inserts a blank line and
 * breaks the list. Every one of the 111 skill descriptions is a folded block, so
 * this affected every page before it was stripped here rather than at one call
 * site: the trim belongs with the inline-rendering contract, not with a consumer.
 *
 * A value with an INTERNAL newline — a `>` block containing a paragraph break,
 * or any `|` literal block — cannot be rendered on one line at all, and emitting
 * it raw reproduces exactly the defect above: a blank line inside the bullet
 * list, on every page carrying that key. There are none in the corpus today
 * (measured, not assumed), so this THROWS rather than guessing. Collapsing would
 * silently misrepresent a literal block; truncating would silently lose text.
 * Whoever first writes a multi-paragraph frontmatter value should decide how it
 * should look, and will get a message telling them so rather than a quietly
 * malformed page.
 *
 * @param {{ key: string, kind: 'scalar'|'list', value: string|string[], line: number }} field
 * @returns {string}
 */
export function renderFrontmatterValue(field) {
  if (field.kind === 'list') {
    return /** @type {string[]} */ (field.value).map(item => `\`${item}\``).join(', ');
  }
  // kind === 'scalar'
  const scalar = String(field.value).replace(/\s+$/, '');
  if (scalar.includes('\n')) {
    throw new Error(
      `[gen-skills] multi-line value: \`${field.key}\`` +
        (field.line ? ` (line ${field.line})` : '') +
        ' contains an internal newline, which cannot render inside a single ' +
        'bullet-list item — it would insert a blank line and break the list. ' +
        'Decide how a multi-paragraph frontmatter value should be presented, ' +
        'then teach renderFrontmatterValue about it.'
    );
  }
  return tokenize(scalar)
    .map(tok =>
      tok.type === 'code'
        ? tok.content
        : tok.content.replace(/&/g, '&amp;').replace(/</g, '&lt;')
    )
    .join('');
}
