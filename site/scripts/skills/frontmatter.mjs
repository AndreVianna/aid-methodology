// frontmatter.mjs — Strict SKILL.md frontmatter parser.
//
// Sole YAML reader in the skills/ cluster.
// Implements every row of feature-001's parser table.
//
// Pure export — no import-time side effect.

/**
 * @typedef {{ key: string, kind: 'scalar'|'list', value: string|string[], line: number }} Field
 */

// ── Public API ────────────────────────────────────────────────────────────

/**
 * Parse the YAML frontmatter of a SKILL.md file.
 *
 * @param {string} text        Full file content (LF or CRLF).
 * @param {string} sourcePath  Repo-relative path, used in error messages.
 * @returns {Field[]}          Ordered array, preserving source order.
 * @throws {Error}             On missing/unterminated fence, duplicate key,
 *                             or unclassifiable line at indent 0.
 */
export function parseSkillFrontmatter(text, sourcePath) {
  // Normalise line endings; keep 1-based line numbers aligned to original file.
  const lines = text.split('\n').map((l) => l.replace(/\r$/, ''));

  // ── 1. Locate frontmatter fence ────────────────────────────────────────

  if (lines.length === 0 || lines[0] !== '---') {
    const first = lines.length > 0 ? lines[0] : '';
    throw new Error(
      `[gen-skills] frontmatter parse: missing opening fence` +
      ` (${sourcePath}:1: ${first})`
    );
  }

  let fenceEnd = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') {
      fenceEnd = i;
      break;
    }
  }

  if (fenceEnd === -1) {
    throw new Error(
      `[gen-skills] frontmatter parse: unterminated frontmatter fence` +
      ` (${sourcePath}:1: ---)`
    );
  }

  // ── 2. Parse key-value fields ──────────────────────────────────────────

  const fields = [];
  const seenKeys = new Set();

  let i = 1; // index into lines[]; 1-based line = i + 1; starts after opening fence

  while (i < fenceEnd) {
    const lineNo = i + 1; // 1-based
    const line = lines[i];

    // Skip blank lines between fields.
    if (line.trim() === '') {
      i++;
      continue;
    }

    // Skip comment lines between fields.
    if (line.startsWith('#')) {
      i++;
      continue;
    }

    // Match key line at indent 0.
    // Key: non-whitespace, non-colon, non-# first char; then any non-colon chars.
    const keyMatch = line.match(/^([^\s:#][^:]*):(?:[ \t]+(.*))?$/);
    if (!keyMatch) {
      throw new Error(
        `[gen-skills] frontmatter parse: unclassifiable line` +
        ` (${sourcePath}:${lineNo}: ${line})`
      );
    }

    const key = keyMatch[1];
    const rawVal = keyMatch[2]; // undefined when nothing follows the colon

    if (seenKeys.has(key)) {
      throw new Error(
        `[gen-skills] duplicate key '${key}'` +
        ` (${sourcePath}:${lineNo}: ${line})`
      );
    }
    seenKeys.add(key);
    i++;

    const trimmedVal = rawVal !== undefined ? rawVal.trim() : '';

    // ── Block scalar: > >- >+ | |- |+ ──────────────────────────────────
    const blockMatch = trimmedVal.match(/^([>|])([+-]?)$/);
    if (blockMatch) {
      const isFolded = blockMatch[1] === '>';
      const chomp = blockMatch[2]; // '' | '-' | '+'

      // Collect continuation lines: indented or blank.
      const contLines = [];
      while (i < fenceEnd && (lines[i].trim() === '' || /^\s/.test(lines[i]))) {
        contLines.push(lines[i]);
        i++;
      }

      fields.push({
        key,
        kind: 'scalar',
        value: _processBlock(contLines, isFolded, chomp),
        line: lineNo,
      });
      continue;
    }

    // ── Empty value (no rawVal) — may be block sequence ────────────────
    if (rawVal === undefined || trimmedVal === '') {
      const seqItems = [];
      while (i < fenceEnd && /^\s+-[ \t]/.test(lines[i])) {
        const itemMatch = lines[i].match(/^\s+-[ \t]+(.*)$/);
        if (itemMatch) {
          seqItems.push(_decodeScalar(itemMatch[1].trim()));
          i++;
        } else {
          break;
        }
      }

      if (seqItems.length > 0) {
        fields.push({ key, kind: 'list', value: seqItems, line: lineNo });
      } else {
        fields.push({ key, kind: 'scalar', value: '', line: lineNo });
      }
      continue;
    }

    // ── Flow sequence: [ a, b, c ] ─────────────────────────────────────
    if (trimmedVal.startsWith('[')) {
      fields.push({
        key,
        kind: 'list',
        value: _parseFlowSequence(trimmedVal),
        line: lineNo,
      });
      continue;
    }

    // ── Plain / quoted scalar ──────────────────────────────────────────
    fields.push({
      key,
      kind: 'scalar',
      value: _decodeScalar(trimmedVal),
      line: lineNo,
    });
  }

  return fields;
}

// ── Internal helpers ──────────────────────────────────────────────────────

/**
 * Process a block scalar's collected continuation lines into a final string.
 *
 * @param {string[]} contLines  Raw lines (may have leading whitespace or be blank).
 * @param {boolean}  isFolded   true = folded (>), false = literal (|).
 * @param {string}   chomp      '' (clip) | '-' (strip) | '+' (keep).
 * @returns {string}
 */
function _processBlock(contLines, isFolded, chomp) {
  if (contLines.length === 0) {
    return chomp === '-' ? '' : '\n';
  }

  // Determine base indentation from the first non-blank line.
  let baseIndent = 0;
  for (const cl of contLines) {
    if (cl.trim() !== '') {
      const m = cl.match(/^(\s+)/);
      baseIndent = m ? m[1].length : 0;
      break;
    }
  }

  // Strip base indentation; blank lines become ''.
  const stripped = contLines.map((cl) => {
    if (cl.trim() === '') return '';
    return cl.slice(baseIndent);
  });

  // Find last non-blank index to separate content from trailing blanks.
  let lastNonBlank = stripped.length - 1;
  while (lastNonBlank >= 0 && stripped[lastNonBlank] === '') lastNonBlank--;

  const contentLines = stripped.slice(0, lastNonBlank + 1);
  const trailingBlanks = stripped.length - 1 - lastNonBlank;

  let mainContent;

  if (isFolded) {
    // Lines joined with a space; blank line = paragraph break (\n\n).
    const segments = [];
    let buf = '';
    for (const s of contentLines) {
      if (s === '') {
        if (buf) { segments.push(buf); buf = ''; }
        segments.push(null); // paragraph-break marker
      } else {
        buf = buf ? buf + ' ' + s : s;
      }
    }
    if (buf) segments.push(buf);

    // Join text segments with '\n\n' (paragraph break); null markers are just
    // separators and are discarded after they have caused a segment push.
    mainContent = segments.filter((s) => s !== null).join('\n\n');
  } else {
    // Literal: newlines preserved verbatim.
    mainContent = contentLines.join('\n');
  }

  if (chomp === '-') {
    return mainContent;
  }
  if (chomp === '+') {
    // Keep all trailing newlines: one for the block-end newline + one per trailing blank.
    return mainContent + '\n' + '\n'.repeat(trailingBlanks);
  }
  // Clip (default): exactly one trailing newline.
  return mainContent + '\n';
}

/**
 * Decode a scalar value according to its quoting style.
 *
 * @param {string} s  Already-trimmed token.
 * @returns {string}
 */
function _decodeScalar(s) {
  if (s.startsWith("'") && s.endsWith("'") && s.length >= 2) {
    // Single-quoted: remove outer quotes, '' → '
    return s.slice(1, -1).replace(/''/g, "'");
  }
  if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
    // Double-quoted: remove outer quotes, handle \", \\, \n, \t
    return _decodeDoubleQuoted(s.slice(1, -1));
  }
  // Plain scalar — returned as-is (caller already trimmed).
  return s;
}

/**
 * Unescape the interior of a double-quoted YAML scalar.
 * Handles exactly: \" \\ \n \t
 *
 * @param {string} inner  Content between the outer double-quotes.
 * @returns {string}
 */
function _decodeDoubleQuoted(inner) {
  let result = '';
  let i = 0;
  while (i < inner.length) {
    if (inner[i] === '\\' && i + 1 < inner.length) {
      const next = inner[i + 1];
      if (next === '"')  { result += '"';  i += 2; continue; }
      if (next === '\\') { result += '\\'; i += 2; continue; }
      if (next === 'n')  { result += '\n'; i += 2; continue; }
      if (next === 't')  { result += '\t'; i += 2; continue; }
    }
    result += inner[i];
    i++;
  }
  return result;
}

/**
 * Split a YAML flow sequence string into decoded scalar items.
 * Handles single- and double-quoted items; splits on commas outside quotes.
 *
 * @param {string} raw  Entire trimmed value, e.g. '[a, b, "c d"]'.
 * @returns {string[]}
 */
function _parseFlowSequence(raw) {
  // Strip outer [ and ].
  const inner = raw.startsWith('[') && raw.endsWith(']')
    ? raw.slice(1, -1)
    : raw;

  const items = [];
  let current = '';
  let inSingle = false;
  let inDouble = false;

  for (let ci = 0; ci < inner.length; ci++) {
    const ch = inner[ci];
    if (ch === "'" && !inDouble) {
      inSingle = !inSingle;
      current += ch;
    } else if (ch === '"' && !inSingle) {
      inDouble = !inDouble;
      current += ch;
    } else if (ch === ',' && !inSingle && !inDouble) {
      const trimmed = current.trim();
      if (trimmed !== '') items.push(_decodeScalar(trimmed));
      current = '';
    } else {
      current += ch;
    }
  }
  const last = current.trim();
  if (last !== '') items.push(_decodeScalar(last));

  return items;
}
