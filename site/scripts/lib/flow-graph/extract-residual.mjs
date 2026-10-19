// extract-residual.mjs — Residual heuristic extractor (feature-003, named sub-scope).
//
// FR-2 forbids a "no flow derivable" fallback state, so this extractor always emits a
// chart. A ladder of five rungs is tried in order; the first rung yielding ≥ 2 nodes
// wins. R5 is unconditional and produces a valid three-node spine, so no skill is left
// chart-less. Every chart is stamped confidence: 'approximate'.
//
// Exported API:
//   parseAsciiStateMap(text) — R1 token parser. Also imported by the two authored
//     extractors as a corroborating spine (evidence precedence 1). There is exactly
//     one implementation; callers import from this module.
//   extractResidual(params)  — main extractor; returns FlowChart.
//
// Heuristic ladder (first rung yielding ≥ 2 nodes wins):
//   R1  ASCII state map — fenced/indented block with `->` / `→` tokens, or a
//       `State machine:` line.
//   R2  `^###\s+State\s+\d+[a-z]?\s*[—-]\s*(NAME)` headings (ticket skills).
//   R3  `^###\s+Step\s+\d+` headings; `## Mode N` ancestor starts a separate lane.
//   R4  Top-level ordered list whose items begin with a verb.
//   R5  Three-node spine `Entry → "Run <skill>" → Exit`, labelled from frontmatter.
//
// R2–R4 read each step's `**Advance:**` line through advance.mjs, the parser the authored
// extractors use, so edges, conditions, exits and advance types follow the skill's own
// words. A step with no advance line keeps the sequence to the next step.
//
// Pure exports — no import-time side effect.

import { truncate, makeNode, makeEdge, makeProvenance, buildChart } from './model.mjs';
import { buildProvenance } from './source.mjs';
import { extractAdvanceBlock, parseAdvanceBlock } from './advance.mjs';

// ── Constants ─────────────────────────────────────────────────────────────────

const EXTRACTOR = 'residual';
const CONFIDENCE = 'approximate';
const SHAPE = 'residual';

// R2: ### State N — NAME  (em-dash U+2014 or plain hyphen)
const R2_STATE_RE = /^###\s+State\s+(\d+[a-z]?)\s*[\u2014\-]+\s*(.+)/;

// R3: ## Mode N heading
const R3_MODE_RE = /^##\s+Mode\s+(\d+)\s*[\u2014\-:]*\s*(.*)/;

// R3: ### Step N heading (matches Step N, Step Na, Step 2a, etc.)
// `##` OR `###`. Two real skills mix the two levels — `aid-set-connector` has
// `### Step 0` followed by `## Step 1`..`## Step 6`, and `aid-unset-connector`
// `### Step 0` plus `## Step 1`..`## Step 3`. Matching only `###` found exactly one
// heading in each, failed R3's two-heading minimum, and dropped both to the R5
// three-node spine — discarding 7 and 4 authored steps. Meanwhile `aid-config`
// charted 12 nodes purely because it happens to use `###`, so two structurally
// comparable skills rendered very differently for a typographic reason a reader
// cannot see. No conflict with multi-lane detection: `Mode` and `Step` are distinct
// labels, so a `## Mode N` heading cannot be read as a step.
const R3_STEP_RE = /^#{2,3}\s+Step\s+([\w.]+)\s*(.*)/;

// R4: top-level ordered list item (column 0, not in a code block). A letter suffix is a
// step too: `6a.` in aid-orchestrate is its own step, and its advance line names it.
const R4_ITEM_RE = /^(\d+[a-z]?)\.\s+(.+)/;

// Non-verb starters — determiners, articles, prepositions, conjunctions, pronouns,
// modal verbs, and common non-verb first words found in SKILL.md prose.
const NON_VERB_STARTERS = new Set([
  'the', 'a', 'an', 'this', 'that', 'these', 'those',
  'it', 'if', 'when', 'for', 'on', 'at', 'in', 'by', 'of', 'and', 'or', 'not',
  'no', 'all', 'any', 'each', 'every', 'most', 'more', 'many', 'few', 'some',
  'with', 'from', 'to', 'into', 'than', 'then', 'but', 'so', 'also', 'both',
  'which', 'what', 'how', 'where', 'who', 'whose',
  'must', 'will', 'can', 'may', 'should', 'would', 'could',
  'now', 'after', 'before', 'its', 'your', 'our', 'their', 'my', 'his', 'her',
  'we', 'you', 'i', 'he', 'she', 'they',
  'here', 'there', 'note', 'new', 'as', 'use', 'see',
  'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
  'fewer', 'more', 'less', 'not', 'neither', 'either',
]);

// ── Shared R1 token parser ─────────────────────────────────────────────────────

/**
 * Parse an ASCII state map into an ordered token sequence.
 *
 * Recognises `->`- or `→`-separated `[TOKEN]` tokens. A parenthesised suffix
 * inside the brackets (`[NAME(cond)]`) becomes the condition on the edge leading
 * INTO that token; the first token's condition is always `null`. Tokens without
 * brackets are ignored (the parser only extracts `[...]` forms).
 *
 * This is the single shared implementation. The two authored extractors import it
 * as a corroborating spine (evidence precedence 1); there is no second copy.
 *
 * @param {string} text  One or more lines of text containing the state map.
 * @returns {{ names: string[], conditions: (string|null)[] }}
 *   `names[i]` — state name (uppercase, trimmed).
 *   `conditions[i]` — condition on the edge TO token i, or null.
 */
export function parseAsciiStateMap(text) {
  const names = /** @type {string[]} */ ([]);
  const conditions = /** @type {(string|null)[]} */ ([]);

  // Split on arrow separators to get per-token segments.
  const segments = text.split(/->|→/);
  for (const seg of segments) {
    // Extract the first `[...]` bracketed token in this segment.
    const m = seg.match(/\[([^\]]+)\]/);
    if (!m) continue;

    const inner = m[1].trim();
    // A parenthesised suffix inside the brackets becomes the incoming condition.
    const condMatch = inner.match(/^(.*?)\s*\((.+)\)\s*$/);
    const name = (condMatch ? condMatch[1] : inner).trim().toUpperCase();

    // A token with no NAME is not a state, and must not become a node. `[ ]` and
    // `[(when ready)]` both reach here with an empty name, and both used to produce
    // a node with an empty label — which fails V8, which makes the throwing façade
    // lose the ENTIRE page.
    //
    // That is the worst place for this defect to live: R1 is the first rung of the
    // safety-net extractor, the one whose whole purpose is that every skill gets
    // *some* chart. FR-2 draws the line at "approximate, never malformed", and an
    // empty node is malformed. Skipping the token lets the ladder fall through to a
    // rung that can describe the skill, which is the honest outcome.
    if (name === '') continue;

    names.push(name);
    conditions.push(condMatch ? condMatch[2].trim() : null);
  }

  // The first token never has an incoming condition (nothing precedes it).
  if (conditions.length > 0) conditions[0] = null;

  return { names, conditions };
}

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Extract an approximate residual flow chart for a skill.
 *
 * Applies the five-rung heuristic ladder in order; the first rung producing
 * ≥ 2 nodes wins. R5 always succeeds, so the function never returns null or
 * throws due to "no chart derivable". Every chart is stamped
 * `confidence: 'approximate'` and passes the V1–V8 well-formedness rules.
 *
 * @param {object}   params
 * @param {string}   params.skill          Skill directory name (under canonical/skills/).
 * @param {string}   params.file           Repo-root-relative POSIX path to the SKILL.md.
 * @param {string[]} params.allLines       All file lines, 0-indexed, CRLF stripped.
 * @param {string[]} params.bodyLines      Body-only lines (after frontmatter), 0-indexed.
 * @param {number}   params.bodyStartLine  1-based file line number of bodyLines[0].
 * @param {object}   params.frontmatter    Parsed frontmatter object.
 * @returns {import('./model.mjs').FlowChart}
 */
export function extractResidual({ skill, file, allLines, bodyLines, bodyStartLine, frontmatter }) {
  const sources = [file];
  const warnings = [];

  // Try each rung in order; stop at the first that yields ≥ 2 nodes.
  const r1 = _tryR1(bodyLines, allLines, bodyStartLine, file);
  if (r1 && r1.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r1.rawNodes, edges: r1.rawEdges, sources,
      warnings: [...warnings, ...r1.warnings] });
  }

  const r2 = _tryR2(bodyLines, allLines, bodyStartLine, file);
  if (r2 && r2.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r2.rawNodes, edges: r2.rawEdges, sources,
      warnings: [...warnings, ...r2.warnings] });
  }

  const r3 = _tryR3(bodyLines, allLines, bodyStartLine, file);
  if (r3 && r3.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r3.rawNodes, edges: r3.rawEdges, sources,
      warnings: [...warnings, ...r3.warnings] });
  }

  const r4 = _tryR4(bodyLines, allLines, bodyStartLine, file);
  if (r4 && r4.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r4.rawNodes, edges: r4.rawEdges, sources,
      warnings: [...warnings, ...r4.warnings] });
  }

  // R5 always succeeds.
  const r5 = _buildR5(skill, file, allLines, bodyStartLine, frontmatter);
  return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
    nodes: r5.rawNodes, edges: r5.rawEdges, sources,
    warnings: [...warnings, ...r5.warnings] });
}

// ── R1 — ASCII state map ───────────────────────────────────────────────────────

/**
 * R1: look for a fenced/indented block with `->`/`→`-separated `[TOKEN]`s, or
 * a `State machine:` line.
 *
 * Returns null when no block with ≥ 1 token is found; the caller checks node count.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] } | null}
 */

/**
 * Normalise a node label: collapse whitespace, trim, then apply the shared 60-code-point
 * cap. Every label this module emits goes through here.
 *
 * Whitespace collapsing is not cosmetic. Unwrapping a code span leaves the spaces that
 * surrounded it, and rungs that strip markdown leave their own gaps, so seven labels
 * reached the page with doubled spaces — "Ensure  .aid/settings.yml  exists". Each rung
 * previously built its own label and only one of them collapsed, which is exactly the
 * shape of defect that comes back the next time a rung is added.
 *
 * @param {string} text
 * @returns {string}
 */
function _label(text) {
  return truncate(
    String(text)
      // Unwrap code spans before collapsing. R3 step headings carry them — e.g.
      // `### Step 1: Ensure \`.aid/settings.yml\` exists` — and the Mermaid escaper
      // replaces each backtick with a space individually, so leaving them here produced
      // "Ensure  .aid/settings.yml  exists" with doubled spaces on the rendered page.
      // Unwrapping first means the collapse below sees the final text.
      .replace(/`([^`]*)`/g, '$1')
      .replace(/\s+/g, ' ')
      .trim(),
    60
  );
}

function _tryR1(bodyLines, allLines, bodyStartLine, file) {
  // Try `State machine:` line first.
  for (let i = 0; i < bodyLines.length; i++) {
    if (/^State machine:/i.test(bodyLines[i])) {
      const { names, conditions } = parseAsciiStateMap(bodyLines[i]);
      if (names.length >= 1) {
        const lineNum = bodyStartLine + i;
        return _r1Build(names, conditions, lineNum, lineNum, allLines, file);
      }
    }
  }

  // Try fenced code blocks (``` ... ```).
  for (let i = 0; i < bodyLines.length; i++) {
    if (!/^```/.test(bodyLines[i])) continue;
    const fenceStart = i;
    let j = i + 1;
    while (j < bodyLines.length && !/^```/.test(bodyLines[j])) j++;
    const blockText = bodyLines.slice(fenceStart + 1, j).join('\n');
    if (blockText.includes('->') || blockText.includes('\u2192')) {
      const { names, conditions } = parseAsciiStateMap(blockText);
      if (names.length >= 1) {
        const startLineNum = bodyStartLine + fenceStart;
        const endLineNum = bodyStartLine + Math.min(j, bodyLines.length - 1);
        return _r1Build(names, conditions, startLineNum, endLineNum, allLines, file);
      }
    }
    i = j; // advance past the fence
  }

  // Try indented blocks (4+ spaces or tab).
  let blockStart = -1;
  let blockLines = /** @type {string[]} */ ([]);

  const flush = (/** @type {number} */ bStart) => {
    if (blockLines.length === 0) return null;
    const text = blockLines.join('\n');
    if (!text.includes('->') && !text.includes('\u2192')) return null;
    const { names, conditions } = parseAsciiStateMap(text);
    if (names.length < 1) return null;
    const startLineNum = bodyStartLine + bStart;
    const endLineNum = bodyStartLine + bStart + blockLines.length - 1;
    return _r1Build(names, conditions, startLineNum, endLineNum, allLines, file);
  };

  for (let i = 0; i < bodyLines.length; i++) {
    const isIndented = /^(?:    |\t)/.test(bodyLines[i]);
    if (isIndented) {
      if (blockStart === -1) blockStart = i;
      blockLines.push(bodyLines[i]);
    } else {
      if (blockLines.length > 0) {
        const result = flush(blockStart);
        if (result) return result;
      }
      blockStart = -1;
      blockLines = [];
    }
  }
  // Flush any trailing block.
  if (blockLines.length > 0) {
    const result = flush(blockStart);
    if (result) return result;
  }

  return null;
}

/**
 * Build raw nodes/edges from `parseAsciiStateMap` output.
 *
 * All nodes share provenance pointing to the block's line range. The first token
 * has no incoming condition; subsequent tokens inherit their condition from the
 * `conditions` array. The last node is the exit (terminal UNSPECIFIED).
 *
 * @param {string[]}        names
 * @param {(string|null)[]} conditions
 * @param {number}          startLineNum  1-based, inclusive — provenance start
 * @param {number}          endLineNum    1-based, inclusive — provenance end
 * @param {string[]}        allLines
 * @param {string}          file
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] }}
 */
function _r1Build(names, conditions, startLineNum, endLineNum, allLines, file) {
  const prov = buildProvenance(file, allLines, startLineNum, endLineNum, 'skill');
  const rawNodes = [];
  const rawEdges = [];
  const warnings = [];

  // Deduplicate names: append occurrence index when a name repeats.
  const seen = new Map();
  const uniqueNames = names.map((n) => {
    const cnt = (seen.get(n) ?? 0) + 1;
    seen.set(n, cnt);
    return cnt === 1 ? n : `${n}-${cnt}`;
  });

  for (let i = 0; i < uniqueNames.length; i++) {
    const isLast = i === uniqueNames.length - 1;
    rawNodes.push(makeNode({
      order: i + 1,
      name: uniqueNames[i],
      label: _label(uniqueNames[i]),
      provenance: prov,
      terminal: isLast ? { advanceType: 'UNSPECIFIED', handoff: null } : null,
    }));
  }

  for (let i = 0; i < uniqueNames.length - 1; i++) {
    const from = 'n' + (i + 1);
    const to = 'n' + (i + 2);
    const cond = conditions[i + 1] ?? null;
    rawEdges.push(makeEdge({
      from, to,
      kind: 'sequence',
      condition: cond !== null ? truncate(cond, 80) : null,
      advanceType: 'CHAIN',
      provenance: prov,
    }));
  }

  return { rawNodes, rawEdges, warnings };
}

// ── Advance lines (shared by R2, R3 and R4) ─────────────────────────────────────

/**
 * The **Advance:** marker. It is bold and may follow prose on its line (aid-orchestrate
 * writes "... first write. **Advance:** **CHAIN** ..."), or be the whole line when plain.
 * The block is read by advance.mjs, the same parser the authored extractors use, so a
 * residual chart and an authored chart cannot disagree about what a step says next.
 */
const ADVANCE_MARKER_RE = /\*\*Advance:\*\*|^\s*Advance:/i;

/**
 * A state named as `State 2 (RESOLVE-CONNECTOR)`, the form ticket skills use. The name in
 * parentheses is the state; it is rewritten to the parser's own `[State: NAME]` wrapper,
 * which advance.mjs reads as a plain target. Left as written, the number and the bracket
 * are read as a condition on the edge.
 */
const STATE_REF_RE = /\bState\s+\d+[a-z]?\s*\(\s*([A-Z][A-Z0-9-]*)\s*\)/g;

/** An advance-type keyword. A backticked word of this kind is never a state name. */
const ADVANCE_KEYWORD_RE = /^(?:CHAIN|HALT|ASK|WAIT|PASS|CALL|PAUSE-FOR-USER-ACTION|PAUSE-FOR-USER-DECISION)$/;

/**
 * Locate the first **Advance:** marker in [start, end). Returns its 0-based line and the
 * column where the marker starts, or null. Fenced code is skipped: a marker inside an
 * example is not the step's own advance.
 *
 * @returns {{ line: number, col: number } | null}
 */
function _findAdvanceLine(bodyLines, start, end) {
  let inFence = false;
  for (let i = start; i < end; i++) {
    if (/^```/.test(bodyLines[i])) { inFence = !inFence; continue; }
    if (inFence) continue;
    const m = bodyLines[i].match(ADVANCE_MARKER_RE);
    if (m) return { line: i, col: m.index };
  }
  return null;
}

/**
 * End (exclusive, 0-based) of a heading section that starts at `start` with a heading of
 * `level` #s: the next heading at that level or higher. Deeper sub-headings belong to the
 * section, so an advance line written after a `####` sub-heading is still its own.
 */
function _headingSectionEnd(bodyLines, start, level) {
  let inFence = false;
  for (let i = start + 1; i < bodyLines.length; i++) {
    if (/^```/.test(bodyLines[i])) { inFence = !inFence; continue; }
    if (inFence) continue;
    const h = bodyLines[i].match(/^(#{1,6})\s/);
    if (h && h[1].length <= level) return i;
  }
  return bodyLines.length;
}

/**
 * End (exclusive, 0-based) of a top-level list item that starts at `start`: the next
 * top-level item, or any heading. An item has no heading level, so a heading always ends it.
 */
function _listItemEnd(bodyLines, start) {
  let inFence = false;
  for (let i = start + 1; i < bodyLines.length; i++) {
    if (/^```/.test(bodyLines[i])) { inFence = !inFence; continue; }
    if (inFence) continue;
    if (R4_ITEM_RE.test(bodyLines[i]) || /^#{1,6}\s/.test(bodyLines[i])) return i;
  }
  return bodyLines.length;
}

/**
 * Parse the **Advance:** line of the section [start, end) through advance.mjs.
 *
 * Returns the parser's result, or null when the section has no advance line, or when the
 * line names neither a step nor an exit. In the null cases the caller keeps the sequence
 * to the next step, as a step with no advance line always has.
 *
 * @returns {{ edges: object[], terminal: object|null } | null}
 */
function _readAdvance({ bodyLines, bodyStartLine, file, start, end, fromId, fromName, declaredStates, warnings }) {
  const found = _findAdvanceLine(bodyLines, start, end);
  if (!found) return null;

  // The section is sliced to [start, end), so the block is cut at the section's end: an
  // advance line directly above the next step cannot pull that step's text into this block.
  // The first line starts at the marker, not at the start of its line, so prose before
  // the marker on that line is not read as part of the advance.
  const section = bodyLines.slice(start, end);
  const first = found.line - start;
  section[first] = section[first].slice(found.col);
  const { blockText } = extractAdvanceBlock(section, first);
  const block = blockText.replace(STATE_REF_RE, '[State: $1]');
  const where = `${file}:${bodyStartLine + found.line}`;

  // A step that names a state this chart does not declare (the inline `[State: X]` form,
  // used by skills whose states are not headings) cannot be wired: the target is not a
  // node here. The step keeps the sequence rather than drawing a false exit.
  const declaredNames = new Set(declaredStates.map((d) => d.name));
  const unknown = [...block.matchAll(/\[State:\s+([^\]]+)\]/g)]
    .map((m) => m[1].trim())
    .filter((n) => !declaredNames.has(n));
  if (unknown.length > 0) {
    warnings.push(
      `[gen-skills] advance (R2-R4): ${where}: the **Advance:** line of '${fromName}' names ` +
      `state(s) ${unknown.map((n) => `'${n}'`).join(', ')} that this chart does not declare; ` +
      `the sequence to the next step is used`
    );
    return null;
  }

  let result;
  try {
    result = parseAdvanceBlock({
      block,
      fromNodeId: fromId,
      fromNodeName: fromName,
      declaredStates,
      file,
      blockStartLine: bodyStartLine + found.line,
      sourceKind: 'skill',
    });
  } catch (err) {
    // The parser's V9 guard names a declared state that its advance text mentions but no
    // edge reaches. The authored extractors read it as a warning and fall back to the row
    // advance; this rung falls back to the sequence, and never fails the page.
    if (typeof err.message === 'string' && err.message.startsWith('[gen-skills] V9:')) {
      warnings.push(`[gen-skills] advance (R2-R4): W-V9 at ${where}: ${err.message}`);
      return null;
    }
    throw err;
  }
  warnings.push(...result.warnings);

  // CHAIN means "go on to the next step". An unresolved CHAIN therefore cannot be an exit:
  // it is dropped, and the edges the advance did resolve are kept.
  let terminal = result.terminal;
  if (terminal && terminal.advanceType === 'CHAIN') {
    warnings.push(
      `[gen-skills] advance (R2-R4): ${where}: the CHAIN in the **Advance:** line of ` +
      `'${fromName}' resolves to no step; it is not drawn as an exit`
    );
    terminal = null;
  }

  if (result.edges.length === 0 && terminal === null) {
    warnings.push(
      `[gen-skills] advance (R2-R4): ${where}: the **Advance:** line of '${fromName}' ` +
      `names no step and no exit; the sequence to the next step is used`
    );
    return null;
  }
  return { edges: result.edges, terminal };
}

/** The declared-state list parseAdvanceBlock resolves targets against: one per node. */
function _declaredStates(rawNodes, names) {
  return rawNodes.map((n, i) => ({ name: names[i], order: n.order, id: 'n' + n.order }));
}

/**
 * Wire one rung's steps into edges and exits.
 *
 * `steps` is in source order. Each entry carries its node, its state name, its section
 * range in bodyLines (0-based, end exclusive), `seqNext`, the order of the next step or
 * null for the last one, and `seqLineNum`, the 1-based line the sequence edge to that
 * next step is sourced from (each rung keeps the convention it always had). A step's own
 * **Advance:** line decides its outgoing edges, conditions, exit and advance type. A step
 * with no advance line keeps the sequence to `seqNext`; the last such step is the exit.
 *
 * @returns {object[]} the rung's edges (sequence fallbacks and advance-derived edges).
 */
function _wireSteps({ steps, declaredStates, bodyLines, bodyStartLine, allLines, file, warnings }) {
  const rawEdges = [];
  for (const s of steps) {
    const fromId = 'n' + s.node.order;
    const adv = _readAdvance({
      bodyLines, bodyStartLine, file,
      start: s.start, end: s.end,
      fromId, fromName: s.name, declaredStates, warnings,
    });
    if (adv) {
      rawEdges.push(...adv.edges.map((e) => ({ from: fromId, ...e })));
      s.node.terminal = adv.terminal;
      continue;
    }
    if (s.seqNext !== null) {
      rawEdges.push(makeEdge({
        from: fromId,
        to: 'n' + s.seqNext,
        kind: 'sequence',
        condition: null,
        advanceType: 'CHAIN',
        provenance: buildProvenance(file, allLines, s.seqLineNum, s.seqLineNum, 'skill'),
      }));
    } else {
      s.node.terminal = { advanceType: 'UNSPECIFIED', handoff: null };
    }
  }
  return rawEdges;
}

// ── R2 — ### State N — NAME headings ─────────────────────────────────────────

/**
 * R2: find `^###\s+State\s+\d+\s*[—-]\s*(NAME)` headings and build one node per state.
 * Each state's edges come from its own **Advance:** line (see `_wireSteps`); a state
 * without one is sequenced to the next state. Returns null when no heading is found.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] } | null}
 */
function _tryR2(bodyLines, allLines, bodyStartLine, file) {
  /** @type {{ name: string, label: string, lineNum: number, index: number }[]} */
  const hits = [];

  for (let i = 0; i < bodyLines.length; i++) {
    const m = bodyLines[i].match(R2_STATE_RE);
    if (!m) continue;
    const name = m[2].trim();
    // Same guard as R1, and it belongs here for the same reason: `R2_STATE_RE`'s
    // `(.+)` matches a lone space, so `### State 1 — ` with a trailing space yields
    // an empty name, an empty label, a V8 failure and a lost page.
    //
    // This half was missed the first time round. The finding named R1 *and* R2, and
    // the fix went to R1 because that is where the reproduction was easiest to see —
    // my own R2 probe passed only because its fixture had no trailing space. Fixing
    // the instance rather than the class.
    if (name === '') continue;
    hits.push({
      name,
      label: _label(name),
      lineNum: bodyStartLine + i,
      index: i,
    });
  }

  if (hits.length === 0) return null;

  const warnings = [];
  const rawNodes = hits.map((h, i) => makeNode({
    order: i + 1,
    name: h.name,
    label: h.label,
    provenance: buildProvenance(file, allLines, h.lineNum, h.lineNum, 'skill'),
    terminal: null,
  }));

  const steps = hits.map((h, i) => ({
    node: rawNodes[i],
    name: h.name,
    start: h.index,
    end: _headingSectionEnd(bodyLines, h.index, 3),
    seqNext: i + 1 < hits.length ? i + 2 : null,
    seqLineNum: h.lineNum,
  }));

  const rawEdges = _wireSteps({
    steps,
    declaredStates: _declaredStates(rawNodes, hits.map((h) => h.name)),
    bodyLines, bodyStartLine, allLines, file, warnings,
  });

  return { rawNodes, rawEdges, warnings };
}

// ── R3 — ### Step N headings (with optional ## Mode N lanes) ─────────────────

/**
 * R3: find `^###\s+Step\s+\d+` headings. When `## Mode N` headings are also
 * present, each mode starts a separate lane with its own entry node. Each step's edges
 * come from its own **Advance:** line (see `_wireSteps`). Returns null when no step
 * headings are found.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] } | null}
 */
function _tryR3(bodyLines, allLines, bodyStartLine, file) {
  // Collect mode headings and step headings together, preserving order.
  /** @type {Array<{ kind: 'mode'|'step', label: string, name: string, lineNum: number, lineIndex: number, level: number }>} */
  const events = [];

  for (let i = 0; i < bodyLines.length; i++) {
    const modeM = bodyLines[i].match(R3_MODE_RE);
    if (modeM) {
      const num = modeM[1];
      const rest = modeM[2].trim();
      // Label: e.g. "Mode 1 — Show all settings (/aid-config)".
      //
      // Code spans are **unwrapped**, not replaced by an ellipsis. Substituting '…'
      // published "Mode 1 — Show all settings (…)" — a parenthetical whose entire
      // contents had been thrown away, and an ellipsis that reads as truncation when
      // nothing was truncated. The command name it removed is the informative part.
      //
      // Fifth site in this delivery of one root cause: a strip correct for one token
      // class applied to text a reader sees. Whitespace is collapsed afterwards because
      // unwrapping can leave the spaces that surrounded the span.
      const rawLabel = (rest
        ? `Mode ${num} — ${rest}`.replace(/`([^`]*)`/g, '$1')
        : `Mode ${num}`
      ).replace(/\s+/g, ' ').trim();
      events.push({
        kind: 'mode',
        label: _label(rawLabel),
        name: `MODE-${num}`,
        lineNum: bodyStartLine + i,
        lineIndex: i,
        level: 2,
      });
      continue;
    }
    const stepM = bodyLines[i].match(R3_STEP_RE);
    if (stepM) {
      const id = stepM[1]; // e.g. "1", "2a", "0"
      const rest = stepM[2].trim();
      // Strip leading separator characters from the description text.
      const desc = rest.replace(/^[—–:\-\s]+/, '').trim();
      const rawLabel = desc || `Step ${id}`;
      events.push({
        kind: 'step',
        label: _label(rawLabel),
        name: `STEP-${id.toUpperCase()}`,
        lineNum: bodyStartLine + i,
        lineIndex: i,
        level: bodyLines[i].match(/^#+/)[0].length,
      });
    }
  }

  // Drop a `## Mode N` heading that has NO steps beneath it before the next mode.
  //
  // Such a mode used to become a node with no inbound and no outbound edge — a box
  // floating beside the chart. It passed validation only incidentally: `buildChart`
  // sees in-degree 0 and lists it in `entries`, so V6 reachability is satisfied
  // trivially and V1–V8 all hold. Valid, and still wrong to show a reader, since it
  // asserts a lane that has no content.
  //
  // A mode heading is a LANE LABEL, not a state. With no steps under it there is no
  // lane, so there is nothing to label.
  {
    const kept = [];
    for (let i = 0; i < events.length; i++) {
      if (events[i].kind !== 'mode') { kept.push(events[i]); continue; }
      const nextMode = events.findIndex((e, j) => j > i && e.kind === 'mode');
      const end = nextMode === -1 ? events.length : nextMode;
      const hasStep = events.slice(i + 1, end).some((e) => e.kind === 'step');
      if (hasStep) kept.push(events[i]);
    }
    events.length = 0;
    events.push(...kept);
  }

  // Require at least one step event.
  const stepCount = events.filter((e) => e.kind === 'step').length;
  if (stepCount === 0) return null;

  const warnings = [];
  const rawNodes = events.map((evt, i) => makeNode({
    order: i + 1,
    name: evt.name,
    label: evt.label,
    provenance: buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill'),
    terminal: null,
  }));

  const rawEdges = [];

  // A lane opens at the step that follows its `## Mode N` entry: a structural edge from
  // the mode into that step. With no modes present, this loop adds nothing.
  events.forEach((evt, i) => {
    const next = events[i + 1];
    if (evt.kind === 'mode' && next && next.kind === 'step') {
      rawEdges.push(makeEdge({
        from: 'n' + (i + 1),
        to: 'n' + (i + 2),
        kind: 'sequence',
        condition: null,
        advanceType: 'CHAIN',
        provenance: buildProvenance(file, allLines, next.lineNum, next.lineNum, 'skill'),
      }));
    }
  });

  // Each step's next step is the event after it, when that event is a step. A mode
  // ends its lane, so the lane's last step has no sequence to follow and is an exit
  // unless its advance line says otherwise.
  const steps = [];
  events.forEach((evt, i) => {
    if (evt.kind !== 'step') return;
    const next = events[i + 1];
    steps.push({
      node: rawNodes[i],
      name: evt.name,
      start: evt.lineIndex,
      end: _headingSectionEnd(bodyLines, evt.lineIndex, evt.level),
      seqNext: next && next.kind === 'step' ? i + 2 : null,
      // The sequence edge into the next step is sourced from that step's heading.
      seqLineNum: next && next.kind === 'step' ? next.lineNum : evt.lineNum,
    });
  });

  rawEdges.push(..._wireSteps({
    steps,
    declaredStates: _declaredStates(rawNodes, events.map((e) => e.name)),
    bodyLines, bodyStartLine, allLines, file, warnings,
  }));

  return { rawNodes, rawEdges, warnings };
}

// ── R4 — top-level ordered list with verb-starting items ─────────────────────

/**
 * The state name a list item declares: the parenthesised code span that follows its bold
 * title, as in `**Find or create the work** (`FIND-OR-CREATE`)`. Null when the item names
 * none, or when the span is an advance-type keyword rather than a state.
 *
 * @param {string} text
 * @returns {string|null}
 */
function _itemStateName(text) {
  const m = text.match(/\(`([A-Z][A-Z0-9-]*)`\)/);
  if (!m || ADVANCE_KEYWORD_RE.test(m[1])) return null;
  return m[1];
}

/**
 * R4: find a top-level ordered list (`^\d+[a-z]?\.\s+...`) whose items begin with a
 * word that is not a known non-verb starter. Each item's edges come from its own
 * **Advance:** line (see `_wireSteps`). Returns null when no qualifying item is found.
 *
 * This rung does not fire for any of the 13 currently-known residual skills but
 * is implemented to satisfy the ladder's completeness requirement.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] } | null}
 */
function _tryR4(bodyLines, allLines, bodyStartLine, file) {
  let inFence = false;
  /** @type {{ text: string, lineNum: number, index: number }[]} */
  const items = [];

  for (let i = 0; i < bodyLines.length; i++) {
    // Skip fenced code blocks.
    if (/^```/.test(bodyLines[i])) { inFence = !inFence; continue; }
    if (inFence) continue;

    const m = bodyLines[i].match(R4_ITEM_RE);
    if (!m) continue;
    const text = m[2].trim();
    const firstWord = text.split(/\s+/)[0].toLowerCase().replace(/[^a-z]/g, '');
    if (!NON_VERB_STARTERS.has(firstWord) && firstWord.length > 0) {
      items.push({ text, lineNum: bodyStartLine + i, index: i });
    }
  }

  // Deliberately NOT a `items.length < 2` gate here. R4 previously carried its own
  // two-item minimum, and mutation testing showed it could be relaxed to `< 1`
  // without changing any outcome — because the ladder re-applies the same `>= 2`
  // check to whatever this returns. An inner guard that cannot alter behaviour reads
  // like a safeguard while guarding nothing, and it invites a future reader to
  // "fix" one of the two copies. The ladder is the single authority for how many
  // nodes a rung must yield to win.
  if (items.length === 0) return null;

  const warnings = [];

  // An item's state name is what its advance line refers to, and it is also the name of
  // the node: a reader of the chart finds the step by the name the skill gave it. It is
  // taken from the item when the item declares one (`(`NAME`)` after its bold title);
  // otherwise the item keeps its STEP-N name. A name already taken by an earlier item also
  // falls back, so declared names stay unique. Numbering the nodes by position instead made
  // `6a` and every item after it a different number from the one the skill prints.
  const used = new Set();
  const stateNames = items.map((it, i) => {
    const declared = _itemStateName(it.text);
    const name = declared && !used.has(declared) ? declared : `STEP-${i + 1}`;
    used.add(name);
    return name;
  });

  const rawNodes = items.map((it, i) => makeNode({
    order: i + 1,
    name: stateNames[i],
    label: _label(it.text),
    provenance: buildProvenance(file, allLines, it.lineNum, it.lineNum, 'skill'),
    terminal: null,
  }));

  const steps = items.map((it, i) => ({
    node: rawNodes[i],
    name: stateNames[i],
    start: it.index,
    end: _listItemEnd(bodyLines, it.index),
    seqNext: i + 1 < items.length ? i + 2 : null,
    seqLineNum: it.lineNum,
  }));

  const rawEdges = _wireSteps({
    steps,
    declaredStates: _declaredStates(rawNodes, stateNames),
    bodyLines, bodyStartLine, allLines, file, warnings,
  });

  return { rawNodes, rawEdges, warnings };
}

// ── R5 — three-node spine (last resort) ───────────────────────────────────────

/**
 * R5: unconditional last resort. Produces a three-node spine:
 *   ENTRY → RUN → EXIT
 *
 * The RUN node's label is derived from the frontmatter `description` field.
 * Provenance for all three nodes is anchored to the frontmatter opening fence.
 *
 * @param {string}   skill
 * @param {string}   file
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {object}   frontmatter
 * @returns {{ rawNodes: object[], rawEdges: object[], warnings: string[] }}
 */
function _buildR5(skill, file, allLines, bodyStartLine, frontmatter) {
  const warnings = [];

  // Find the `description:` line inside the frontmatter for RUN node provenance.
  const fmLineCount = bodyStartLine - 1; // number of frontmatter lines (1-based → count)
  let descLineNum = 1; // default: opening fence
  for (let i = 0; i < fmLineCount && i < allLines.length; i++) {
    if (/^description:/.test(allLines[i])) {
      descLineNum = i + 1;
      break;
    }
  }

  // Derive the RUN label from frontmatter.description, fall back to skill name.
  const rawDesc = typeof frontmatter?.description === 'string'
    ? frontmatter.description.replace(/\s+/g, ' ').trim()
    : skill;
  const runLabel = truncate('Run ' + rawDesc, 60);

  const entryProv = buildProvenance(file, allLines, 1, 1, 'skill');
  const runProv = buildProvenance(file, allLines, descLineNum, descLineNum, 'skill');
  const exitProv = buildProvenance(file, allLines, Math.max(1, bodyStartLine - 1), Math.max(1, bodyStartLine - 1), 'skill');

  if (!rawDesc || rawDesc === skill) {
    warnings.push(
      `[gen-skills] extract-residual R5: no description in frontmatter for '${skill}'; ` +
      `RUN label defaults to skill name`
    );
  }

  const rawNodes = [
    makeNode({
      order: 1,
      name: 'ENTRY',
      label: 'Entry',
      provenance: entryProv,
      terminal: null,
    }),
    makeNode({
      order: 2,
      name: 'RUN',
      label: runLabel,
      provenance: runProv,
      terminal: null,
    }),
    makeNode({
      order: 3,
      name: 'EXIT',
      label: 'Exit',
      provenance: exitProv,
      terminal: { advanceType: 'HALT', handoff: null },
    }),
  ];

  const rawEdges = [
    makeEdge({
      from: 'n1', to: 'n2',
      kind: 'sequence', condition: null, advanceType: 'CHAIN',
      provenance: entryProv,
    }),
    makeEdge({
      from: 'n2', to: 'n3',
      kind: 'sequence', condition: null, advanceType: 'CHAIN',
      provenance: runProv,
    }),
  ];

  return { rawNodes, rawEdges, warnings };
}
