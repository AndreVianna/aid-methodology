// advance.mjs — Advance-clause parser (rules 1–4 only; rules 5–10 added by task-023).
//
// Shared by extract-dispatch.mjs (Dispatch Advance cells) and extract-inline.mjs
// (## State: section **Advance:** blocks). Applied identically to both call sites.
//
// Rules 1–4 implemented here:
//   1. Block scoping — input is a multi-line block, not a single line.
//   2. Phase 1 / Phase 2 separator proposal and validation.
//   3. Per-clause target resolution (rule 2).
//   4. Condition capture (rule 3) and terminal handling (rule 4).
//
// Seam for task-023 / rules 5–10 / V9:
//   After phase-2 clause extraction, the normalized `content` string and the
//   accepted clause texts are both in scope. task-023 inserts rules 5–9
//   (self-loop, `then`, back-reference, re-entry, pause-resume) and the
//   rule-10 / V9 guard at the clearly-marked seam inside parseAdvanceBlock().
//
//   For rule-10 / V9 specifically: residue = content text not covered by any
//   accepted clause span. task-023 enforces V9 (error throw) against residue
//   that references a declared chart state not already reachable as an edge
//   target from this node or recorded in terminal.handoff.
//
// [gen-skills] error prefix convention: every guard error cites file:line and
// the offending text. Warnings follow the same pattern.
//
// Pure exports — no import-time side effect, no filesystem access.

import { truncate, makeProvenance } from './model.mjs';

// ── Constants ─────────────────────────────────────────────────────────────────

/**
 * The four advance-type keywords that appear in advance clause text.
 * UNSPECIFIED is a computed value (no keyword present), never written in text.
 */
const ADVANCE_TYPES_IN_TEXT = ['CHAIN', 'HALT', 'PAUSE-FOR-USER-ACTION', 'PAUSE-FOR-USER-DECISION'];

/**
 * Matches advance-type keywords that are NOT part of a hyphenated state name.
 * Uses lookbehind/lookahead to require that the keyword is not immediately
 * preceded or followed by a letter, digit, or hyphen — so HALT matches the
 * standalone keyword but NOT the "HALT" inside "APPROVAL-HALT".
 * Used for keyword stripping during target resolution.
 */
const ADVANCE_KW_RE = new RegExp(
  `(?<![A-Za-z0-9-])(${ADVANCE_TYPES_IN_TEXT.join('|')})(?![A-Za-z0-9-])`, 'g'
);

/** Strip arrow forms: → and variants of ->. */
const ARROW_RE = /→|--?>+/g;

/** Strip [State: X] wrapper to just X. */
const STATE_WRAPPER_RE = /\[State:\s+([^\]]+)\]/g;

/**
 * Token scanner: a letter followed by letters, digits, or hyphens.
 * Hyphenated names (PRESENT-FINDINGS, Q-AND-A) are matched as one token.
 * Must be reset via lastIndex = 0 before each exec loop.
 */
const TOKEN_RE = /[A-Za-z][A-Za-z0-9-]*/g;

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Extract the **Advance:** block starting at the given 0-based marker line index.
 *
 * The block runs from the marker line through the last line before the first
 * blank line, `---` horizontal rule, or any heading (`# …`) that follows.
 * Continuation lines immediately after the marker (no blank between) are part
 * of the block — this is what captures the third clause of
 * `aid-create-ticket/SKILL.md` 200–201.
 *
 * @param {string[]} lines           0-indexed line array (CRLF already stripped).
 * @param {number}   markerLineIndex 0-based index of the '**Advance:**' line.
 * @returns {{ blockText: string, endLineIndex: number }}
 *   blockText:    All lines joined with '\n', including the marker line.
 *   endLineIndex: 0-based index of the last included line (≥ markerLineIndex).
 */
export function extractAdvanceBlock(lines, markerLineIndex) {
  let i = markerLineIndex + 1;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === '') break;
    if (line === '---') break;
    if (/^#{1,6}\s/.test(line)) break;
    i++;
  }
  const endLineIndex = i - 1; // last included line index
  return {
    blockText: lines.slice(markerLineIndex, endLineIndex + 1).join('\n'),
    endLineIndex,
  };
}

/**
 * Parse an **Advance:** block into edges and/or a terminal (rules 1–4 only).
 *
 * The public signature is final. Rules 5–10 (added by task-023) enrich the
 * returned arrays without changing the parameters or return type.
 *
 * @param {object}   params
 * @param {string}   params.block            Multi-line block text (includes the
 *                                           '**Advance:**' marker line and any
 *                                           continuation lines, '\n'-joined).
 * @param {string}   params.fromNodeId       Source node id (n1…nN).
 * @param {string}   params.fromNodeName     State name (for warning messages).
 * @param {Array<{name:string, order:number, id:string}>} params.declaredStates
 *                                           All declared states for this chart.
 * @param {string}   params.file             Repo-root-relative source path.
 * @param {number}   params.blockStartLine   1-based line of the block's first line.
 * @param {string}   [params.sourceKind]     'skill' | 'worker' (default 'skill').
 * @returns {{
 *   edges:    Array<{to:string, kind:string, condition:string|null,
 *                    advanceType:string,
 *                    provenance: import('./model.mjs').Provenance}>,
 *   terminal: {advanceType:string, handoff:string|null} | null,
 *   warnings: string[],
 * }}
 */
export function parseAdvanceBlock({
  block,
  fromNodeId,
  fromNodeName,
  declaredStates,
  file,
  blockStartLine,
  sourceKind = 'skill',
}) {
  const warnings = [];

  // ── Build case-insensitive state index; lowest order wins on collision ────
  const stateByName = _buildStateIndex(
    declaredStates, fromNodeName, file, blockStartLine, warnings
  );

  // ── Normalize block to a single content string ───────────────────────────
  const content = _normalizeBlock(block);
  if (!content) return { edges: [], terminal: null, warnings };

  // ── Build block-level provenance (shared by all edges from this block) ───
  const blockLineCount = block.split('\n').length;
  const blockProvenance = makeProvenance({
    file,
    startLine: blockStartLine,
    endLine: blockStartLine + blockLineCount - 1,
    sourceKind,
    excerpt: block,
  });

  // ── Phase 1: propose separator cut positions ──────────────────────────────
  const proposedCuts = _proposeSeparatorPositions(content);

  // ── Phase 2: validate and build final clause list ─────────────────────────
  const clauses = _buildClauses(content, proposedCuts, stateByName);

  // ── Rules 2–4: per-clause target resolution, condition capture, terminal ──
  const edges = [];
  let terminal = null;

  for (const clauseText of clauses) {
    const advanceType = _detectAdvanceType(clauseText);
    const targetState = _resolveTarget(clauseText, stateByName);

    if (targetState) {
      // Rule 2: resolved to a declared state — emit an edge (rule 3: condition).
      const condition = _extractCondition(clauseText, targetState.name);
      edges.push({
        to: targetState.id,
        kind: condition !== null ? 'branch' : 'sequence',
        condition,
        advanceType,
        provenance: blockProvenance,
      });
    } else if (
      advanceType !== 'UNSPECIFIED' ||
      /(?<![A-Za-z0-9-])halt(?![A-Za-z0-9-])/i.test(clauseText) ||
      /\bStop here\b/.test(clauseText)
    ) {
      // Rule 4: recognized terminal keyword with no declared state target —
      // no edge; populate terminal and the node joins exits.
      if (terminal !== null) {
        warnings.push(
          `[gen-skills] advance: multiple terminal clauses in '${fromNodeName}'; ` +
          `keeping last (${file}:${blockStartLine}: ${clauseText.slice(0, 60)})`
        );
      }
      terminal = {
        advanceType,
        handoff: _extractHandoff(clauseText),
      };
    }
    // Clauses that pass phase-2 but resolve to neither a declared state nor a
    // recognized terminal are silently skipped here; task-023's rule-10 / W-1
    // guard will surface them as warnings via residue analysis.
  }

  // ── SEAM FOR TASK-023 ─────────────────────────────────────────────────────
  // Rules 5–9 (self-loop, `then` optionality, back-reference, re-entry,
  // pause-resume) and rule-10 / V9 (residual-text guard) are added by
  // task-023 immediately here, with access to:
  //   content       — normalized advance block text (single string)
  //   clauses       — accepted clause strings (phase-2 output)
  //   edges         — edge array produced above (may be mutated/extended)
  //   terminal      — terminal record produced above (may be replaced)
  //   stateByName   — state index (for V9 / W-1 declared-state lookups)
  //   fromNodeId, fromNodeName, file, blockStartLine — error-message context
  //   blockProvenance — provenance for new edges

  return { edges, terminal, warnings };
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/**
 * Build a case-insensitive Map from state name to the lowest-order node record.
 * When the same name (lowercased) appears more than once, the lowest-order node
 * wins and a collision warning is recorded.
 *
 * @param {Array<{name:string, order:number, id:string}>} declaredStates
 * @param {string}   fromNodeName
 * @param {string}   file
 * @param {number}   blockStartLine
 * @param {string[]} warnings  Mutated in place.
 * @returns {Map<string, {name:string, order:number, id:string}>}
 */
function _buildStateIndex(declaredStates, fromNodeName, file, blockStartLine, warnings) {
  const byName = new Map();
  const counts = new Map();

  for (const s of declaredStates) {
    const key = s.name.toLowerCase();
    counts.set(key, (counts.get(key) ?? 0) + 1);
    const existing = byName.get(key);
    if (!existing || s.order < existing.order) byName.set(key, s);
  }

  for (const [key, count] of counts) {
    if (count > 1) {
      const winner = byName.get(key);
      warnings.push(
        `[gen-skills] advance: duplicate state name '${winner.name}' in ` +
        `'${fromNodeName}'; resolves to lowest-order node '${winner.id}' ` +
        `(${file}:${blockStartLine}: collision)`
      );
    }
  }

  return byName;
}

/**
 * Strip the `**Advance:**` marker from the first line of the block, join any
 * continuation lines with a space, and return a single normalized string.
 *
 * @param {string} block  Raw block text ('\n'-joined, includes the marker line).
 * @returns {string}
 */
function _normalizeBlock(block) {
  const lines = block.split('\n');
  const first = lines[0].replace(/^\s*\*{0,2}Advance:\*{0,2}\s*/i, '').trim();
  const rest = lines.slice(1).map((l) => l.trim()).filter(Boolean);
  return [first, ...rest].filter(Boolean).join(' ').trim();
}

/**
 * Build a Uint8Array of the same length as `text`, with 1 at every position
 * inside a backtick span and 0 outside.  A backtick character toggles the
 * inside/outside state (simple toggle — no nested or escaped backticks).
 *
 * @param {string} text
 * @returns {Uint8Array}
 */
function _buildBacktickMask(text) {
  const mask = new Uint8Array(text.length);
  let inside = false;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '`') inside = !inside;
    if (inside) mask[i] = 1;
  }
  return mask;
}

/**
 * Phase 1: scan `content` left-to-right and collect every candidate separator
 * position, skipping positions inside backtick spans.
 *
 * Separators detected (feature-003 SPEC separator table):
 *   semicolon      `;`
 *   spaced-slash   ` / ` (spaces on both sides; splitAt points to the leading space)
 *   unspaced-slash `/` between alphanumeric characters (no surrounding spaces)
 *   then           ` then ` (6 chars; splitAt points to the leading space)
 *   or             ` or `  (4 chars; splitAt points to the leading space)
 *   or-parens      `(or X …)` — altText is the inner text after stripping "or "
 *   sentence       `. ` — splitAt points to the period
 *
 * @param {string} content  Normalized advance block content (no marker).
 * @returns {Array<{type:string, splitAt:number, sepLen:number, altText?:string}>}
 */
function _proposeSeparatorPositions(content) {
  const mask = _buildBacktickMask(content);
  const cuts = [];
  const len = content.length;

  for (let i = 0; i < len; i++) {
    if (mask[i]) continue; // skip positions inside backtick spans

    const ch = content[i];

    // `;` — straight split
    if (ch === ';') {
      cuts.push({ type: 'semicolon', splitAt: i, sepLen: 1 });
      continue;
    }

    // ` / ` — spaced slash; detect at the slash position, record splitAt at
    // the preceding space so the separator span (" / ") is 3 chars.
    if (
      ch === '/' &&
      i > 0 && content[i - 1] === ' ' &&
      i + 1 < len && content[i + 1] === ' '
    ) {
      cuts.push({ type: 'spaced-slash', splitAt: i - 1, sepLen: 3 });
      i++; // skip the trailing space
      continue;
    }

    // Unspaced `/` between alphanumeric characters (no surrounding spaces).
    // Phase 2 validation rejects this when either side is not a declared state.
    if (ch === '/') {
      const prevIsAlpha = i > 0 && /[A-Za-z0-9-]/.test(content[i - 1]);
      const nextIsAlpha = i + 1 < len && /[A-Za-z]/.test(content[i + 1]);
      if (prevIsAlpha && nextIsAlpha) {
        cuts.push({ type: 'unspaced-slash', splitAt: i, sepLen: 1 });
      }
      continue;
    }

    // ` then ` — 6-char separator starting with space
    if (ch === ' ' && content.startsWith(' then ', i)) {
      cuts.push({ type: 'then', splitAt: i, sepLen: 6 });
      i += 5; // advance past ' then' (loop i++ adds 1 more for the trailing space)
      continue;
    }

    // ` or ` — 4-char separator starting with space
    if (ch === ' ' && content.startsWith(' or ', i)) {
      cuts.push({ type: 'or', splitAt: i, sepLen: 4 });
      i += 3; // advance past ' or' (loop i++ adds the trailing space)
      continue;
    }

    // `(or X …)` parenthetical alternative — depth-counted paren matching
    if (ch === '(' && content.startsWith('(or ', i)) {
      let depth = 1;
      let j = i + 1;
      while (j < len && depth > 0) {
        if (content[j] === '(') depth++;
        else if (content[j] === ')') depth--;
        j++;
      }
      if (depth === 0) {
        const inner = content.slice(i + 1, j - 1).trim();
        const altText = inner.startsWith('or ') ? inner.slice(3).trim() : inner;
        cuts.push({ type: 'or-parens', splitAt: i, sepLen: j - i, altText });
        i = j - 1; // resume after the closing paren
      }
      continue;
    }

    // `. ` sentence boundary — period followed by a space
    if (ch === '.' && i + 1 < len && content[i + 1] === ' ') {
      cuts.push({ type: 'sentence', splitAt: i, sepLen: 2 });
      i++; // skip the space (loop i++ skips one more)
      continue;
    }
  }

  return cuts;
}

/**
 * Return true if `text` "resolves" for phase-2 validation purposes — i.e.,
 * contains a declared state name (whole-token, case-insensitive) OR a
 * recognized terminal keyword.
 *
 * @param {string}  text
 * @param {Map}     stateByName
 * @returns {boolean}
 */
function _clauseResolves(text, stateByName) {
  // Terminal keywords — use lookbehind/lookahead to exclude hyphenated names
  // (e.g. "HALT" in "APPROVAL-HALT" should not trigger the terminal check).
  if (/(?<![A-Za-z0-9-])halt(?![A-Za-z0-9-])/i.test(text)) return true;
  if (/\bStop here\b/.test(text)) return true;
  if (/(?<![A-Za-z0-9-])PAUSE-FOR-USER-ACTION(?![A-Za-z0-9-])/.test(text)) return true;
  if (/(?<![A-Za-z0-9-])PAUSE-FOR-USER-DECISION(?![A-Za-z0-9-])/.test(text)) return true;
  return _resolveTarget(text, stateByName) !== null;
}

/**
 * Phase 2: process proposed cuts left-to-right, greedily accepting each one
 * when both resulting sub-clauses individually resolve.  Returns the ordered
 * list of clause strings.
 *
 * Pieces are tracked by their {start, end} positions in the original `content`
 * string.  Accepted cuts produce new pieces without disturbing the positions
 * of previously recorded cuts (they reference the original content).
 *
 * `or-parens` produces a synthetic piece (start = -1) for the alternative text,
 * which cannot be split further by subsequent cuts.
 *
 * @param {string} content
 * @param {Array}  proposedCuts   From _proposeSeparatorPositions.
 * @param {Map}    stateByName
 * @returns {string[]}
 */
function _buildClauses(content, proposedCuts, stateByName) {
  // Each piece: { start, end } for content ranges; start === -1 for synthetic
  // alt-text pieces from (or-parens) extractions.
  // `_text` caches overridden text (for or-parens whose piece1 merges before+after).
  let pieces = [{ start: 0, end: content.length, _text: undefined }];

  for (const cut of proposedCuts) {
    if (cut.type === 'or-parens') {
      // Find the piece that contains cut.splitAt (strictly inside: start <= pos < end)
      const pIdx = pieces.findIndex(
        (p) => p.start !== -1 && p.start <= cut.splitAt && cut.splitAt < p.end
      );
      if (pIdx === -1) continue;

      const piece = pieces[pIdx];
      const beforeText = (piece._text !== undefined
        ? piece._text
        : content.slice(piece.start, piece.end)
      ).slice(0, cut.splitAt - piece.start).trim();

      const afterStart = cut.splitAt + cut.sepLen;
      const afterText =
        afterStart < piece.end
          ? content.slice(afterStart, piece.end).trim()
          : '';

      // piece1 = text before (or…) plus any text after the closing paren
      const piece1Text = [beforeText, afterText].filter(Boolean).join(' ').trim();
      const piece2Text = cut.altText;

      if (!piece1Text) continue;
      if (!_clauseResolves(piece1Text, stateByName)) continue;
      if (!_clauseResolves(piece2Text, stateByName)) continue;

      // Accept: replace the piece with piece1 (same range but with override text)
      // and a synthetic alt piece.
      pieces.splice(
        pIdx, 1,
        { start: piece.start, end: cut.splitAt, _text: piece1Text },
        { start: -1, end: -1, _text: piece2Text }
      );
    } else {
      // Linear split: find the piece that strictly contains cut.splitAt
      const pIdx = pieces.findIndex(
        (p) => p.start !== -1 && p.start < cut.splitAt && cut.splitAt < p.end
      );
      if (pIdx === -1) continue;

      const piece = pieces[pIdx];
      const text1 = content.slice(piece.start, cut.splitAt).trim();
      const text2 = content.slice(cut.splitAt + cut.sepLen, piece.end).trim();

      if (!text1 || !text2) continue;
      if (!_clauseResolves(text1, stateByName) || !_clauseResolves(text2, stateByName)) continue;

      // Accept: replace piece with two sub-pieces.
      pieces.splice(
        pIdx, 1,
        { start: piece.start, end: cut.splitAt, _text: undefined },
        { start: cut.splitAt + cut.sepLen, end: piece.end, _text: undefined }
      );
    }
  }

  return pieces
    .map((p) => {
      if (p._text !== undefined) return p._text;
      if (p.start === -1) return '';
      return content.slice(p.start, p.end).trim();
    })
    .filter(Boolean);
}

/**
 * Resolve the first declared-state token in `text` (rule 2).
 *
 * Pre-processes `text` by stripping `[State: X]` wrappers (replacing with X),
 * arrow forms, and advance-type keywords — so that intermediate routing syntax
 * like `-> CHAIN ->` does not shadow the real target.  Matching is whole-token
 * and case-insensitive; a hyphenated name is one token, so DONE-IDEMPOTENT
 * never matches DONE.
 *
 * @param {string}  text
 * @param {Map<string, {name:string, order:number, id:string}>} stateByName
 * @returns {{name:string, order:number, id:string} | null}
 */
function _resolveTarget(text, stateByName) {
  let cleaned = text.replace(STATE_WRAPPER_RE, '$1');
  cleaned = cleaned.replace(ARROW_RE, ' ');
  cleaned = cleaned.replace(ADVANCE_KW_RE, ' ');

  TOKEN_RE.lastIndex = 0;
  let m;
  while ((m = TOKEN_RE.exec(cleaned)) !== null) {
    const state = stateByName.get(m[0].toLowerCase());
    if (state) return state;
  }
  return null;
}

/**
 * Detect the advance-type keyword present in a clause, following the precedence
 * order used by callers: HALT > PAUSE-FOR-USER-DECISION > PAUSE-FOR-USER-ACTION
 * > CHAIN.  `Stop here` prose maps to PAUSE-FOR-USER-ACTION.  Lowercase `halt`
 * maps to HALT.  Returns UNSPECIFIED when no keyword is found.
 *
 * All patterns use lookbehind/lookahead to avoid matching keyword text that is
 * embedded in a hyphenated state name (e.g., "HALT" in "APPROVAL-HALT" or
 * "CHAIN" in a hypothetical "CHAIN-STATE" should not fire here).
 *
 * @param {string} clauseText
 * @returns {'CHAIN'|'HALT'|'PAUSE-FOR-USER-ACTION'|'PAUSE-FOR-USER-DECISION'|'UNSPECIFIED'}
 */
function _detectAdvanceType(clauseText) {
  if (/(?<![A-Za-z0-9-])HALT(?![A-Za-z0-9-])/.test(clauseText)) return 'HALT';
  if (/(?<![A-Za-z0-9-])PAUSE-FOR-USER-DECISION(?![A-Za-z0-9-])/.test(clauseText))
    return 'PAUSE-FOR-USER-DECISION';
  if (/(?<![A-Za-z0-9-])PAUSE-FOR-USER-ACTION(?![A-Za-z0-9-])/.test(clauseText))
    return 'PAUSE-FOR-USER-ACTION';
  if (/(?<![A-Za-z0-9-])CHAIN(?![A-Za-z0-9-])/.test(clauseText)) return 'CHAIN';
  if (/\bStop here\b/.test(clauseText)) return 'PAUSE-FOR-USER-ACTION';
  if (/(?<![A-Za-z0-9-])halt(?![A-Za-z0-9-])/.test(clauseText)) return 'HALT';
  return 'UNSPECIFIED';
}

/**
 * Extract the edge condition from a clause (rule 3): the text that remains
 * after removing `[State: X]` wrappers, arrows, advance-type keywords, the
 * target state name, standalone `State:` prefix, and backtick spans.
 *
 * Returns null when nothing meaningful is left.  Non-null values are capped at
 * 80 code points using the shared truncator imported from model.mjs — this
 * module contains no second truncation implementation (acceptance criterion 8).
 *
 * @param {string} clauseText   Raw clause text.
 * @param {string} targetName   Resolved state name (exact case, for removal).
 * @returns {string|null}
 */
function _extractCondition(clauseText, targetName) {
  let text = clauseText;
  text = text.replace(STATE_WRAPPER_RE, '$1');
  text = text.replace(ARROW_RE, ' ');
  text = text.replace(ADVANCE_KW_RE, ' ');
  // Strip the resolved state name as a whole token (hyphens included in token)
  const escaped = targetName.replace(/[-]/g, '\\-');
  text = text.replace(new RegExp(`\\b${escaped}\\b`, 'gi'), ' ');
  // Strip standalone "State:" prefix (not inside brackets — those were handled above)
  text = text.replace(/\bState:\s*/g, ' ');
  // Strip backtick spans (routing notation such as `[1] File it` is not a condition)
  text = text.replace(/`[^`]*`/g, ' ');
  // Collapse whitespace and trim
  text = text.replace(/\s+/g, ' ').trim();
  // Strip leading/trailing routing punctuation
  text = text.replace(/^[[\]().,;:!?→>-]+|[[\]().,;:!?→>-]+$/g, '').trim();
  if (!text) return null;
  return truncate(text, 80);
}

/**
 * Extract the terminal handoff prose from a clause (rule 4): the text that
 * remains after removing advance-type keywords, arrow forms, stop phrases,
 * and backtick spans.  Returns null when nothing meaningful is left.
 *
 * @param {string} clauseText
 * @returns {string|null}
 */
function _extractHandoff(clauseText) {
  let text = clauseText;
  text = text.replace(ADVANCE_KW_RE, ' ');
  text = text.replace(ARROW_RE, ' ');
  text = text.replace(/\bStop here\b/g, ' ');
  text = text.replace(/\bhalt\b/gi, ' ');
  text = text.replace(/`[^`]*`/g, ' ');
  text = text.replace(/\s+/g, ' ').trim();
  text = text.replace(/^[[\]().,;:!?→>-]+|[[\]().,;:!?→>-]+$/g, '').trim();
  return text || null;
}
