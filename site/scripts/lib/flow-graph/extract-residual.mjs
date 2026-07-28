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
//   R2  `^###\s+State\s+\d+\s*[—-]\s*(NAME)` headings (ticket skills).
//   R3  `^###\s+Step\s+\d+` headings; `## Mode N` ancestor starts a separate lane.
//   R4  Top-level ordered list whose items begin with a verb.
//   R5  Three-node spine `Entry → "Run <skill>" → Exit`, labelled from frontmatter.
//
// Pure exports — no import-time side effect.

import { truncate, makeNode, makeEdge, makeProvenance, buildChart } from './model.mjs';
import { buildProvenance } from './source.mjs';

// ── Constants ─────────────────────────────────────────────────────────────────

const EXTRACTOR = 'residual';
const CONFIDENCE = 'approximate';
const SHAPE = 'residual';

// R2: ### State N — NAME  (em-dash U+2014 or plain hyphen)
const R2_STATE_RE = /^###\s+State\s+(\d+)\s*[\u2014\-]+\s*(.+)/;

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

// R4: top-level ordered list item (column 0, not in a code block)
const R4_ITEM_RE = /^(\d+)\.\s+(.+)/;

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
      nodes: r2.rawNodes, edges: r2.rawEdges, sources, warnings });
  }

  const r3 = _tryR3(bodyLines, allLines, bodyStartLine, file);
  if (r3 && r3.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r3.rawNodes, edges: r3.rawEdges, sources, warnings });
  }

  const r4 = _tryR4(bodyLines, allLines, bodyStartLine, file);
  if (r4 && r4.rawNodes.length >= 2) {
    return buildChart({ skill, shape: SHAPE, extractor: EXTRACTOR, confidence: CONFIDENCE,
      nodes: r4.rawNodes, edges: r4.rawEdges, sources, warnings });
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
      label: truncate(uniqueNames[i], 60),
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

// ── R2 — ### State N — NAME headings ─────────────────────────────────────────

/**
 * R2: find `^###\s+State\s+\d+\s*[—-]\s*(NAME)` headings and build a sequential
 * chain. Returns null when fewer than 1 heading is found.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[] } | null}
 */
function _tryR2(bodyLines, allLines, bodyStartLine, file) {
  /** @type {{ name: string, label: string, lineNum: number }[]} */
  const hits = [];

  for (let i = 0; i < bodyLines.length; i++) {
    const m = bodyLines[i].match(R2_STATE_RE);
    if (!m) continue;
    const name = m[2].trim();
    hits.push({
      name,
      label: truncate(name, 60),
      lineNum: bodyStartLine + i,
    });
  }

  if (hits.length === 0) return null;

  const rawNodes = [];
  const rawEdges = [];

  for (let i = 0; i < hits.length; i++) {
    const { name, label, lineNum } = hits[i];
    const isLast = i === hits.length - 1;
    rawNodes.push(makeNode({
      order: i + 1,
      name,
      label,
      provenance: buildProvenance(file, allLines, lineNum, lineNum, 'skill'),
      terminal: isLast ? { advanceType: 'UNSPECIFIED', handoff: null } : null,
    }));
  }

  for (let i = 0; i < hits.length - 1; i++) {
    const prov = buildProvenance(file, allLines, hits[i].lineNum, hits[i].lineNum, 'skill');
    rawEdges.push(makeEdge({
      from: 'n' + (i + 1),
      to: 'n' + (i + 2),
      kind: 'sequence',
      condition: null,
      advanceType: 'CHAIN',
      provenance: prov,
    }));
  }

  return { rawNodes, rawEdges };
}

// ── R3 — ### Step N headings (with optional ## Mode N lanes) ─────────────────

/**
 * R3: find `^###\s+Step\s+\d+` headings. When `## Mode N` headings are also
 * present, each mode starts a separate lane with its own entry node. Returns
 * null when no step headings are found.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[] } | null}
 */
function _tryR3(bodyLines, allLines, bodyStartLine, file) {
  // Collect mode headings and step headings together, preserving order.
  /** @type {Array<{ kind: 'mode'|'step', label: string, name: string, lineNum: number, lineIndex: number }>} */
  const events = [];

  for (let i = 0; i < bodyLines.length; i++) {
    const modeM = bodyLines[i].match(R3_MODE_RE);
    if (modeM) {
      const num = modeM[1];
      const rest = modeM[2].trim();
      // Label: e.g. "Mode 1 — Show all settings (/aid-config)" stripped of backtick content.
      const rawLabel = rest
        ? `Mode ${num} \u2014 ${rest}`.replace(/`[^`]*`/g, '…')
        : `Mode ${num}`;
      events.push({
        kind: 'mode',
        label: truncate(rawLabel, 60),
        name: `MODE-${num}`,
        lineNum: bodyStartLine + i,
        lineIndex: i,
      });
      continue;
    }
    const stepM = bodyLines[i].match(R3_STEP_RE);
    if (stepM) {
      const id = stepM[1]; // e.g. "1", "2a", "0"
      const rest = stepM[2].trim();
      // Strip leading separator characters from the description text.
      const desc = rest.replace(/^[\u2014\u2013:\-\s]+/, '').trim();
      const rawLabel = desc || `Step ${id}`;
      events.push({
        kind: 'step',
        label: truncate(rawLabel, 60),
        name: `STEP-${id.toUpperCase()}`,
        lineNum: bodyStartLine + i,
        lineIndex: i,
      });
    }
  }

  // Require at least one step event.
  const stepCount = events.filter((e) => e.kind === 'step').length;
  if (stepCount === 0) return null;

  // Check whether any mode headings exist.
  const hasModes = events.some((e) => e.kind === 'mode');

  const rawNodes = [];
  const rawEdges = [];
  let order = 0;

  if (hasModes) {
    // Multi-lane: each mode gets an entry node; steps under it form a lane.
    let laneEntry = /** @type {number|null} */ (null); // order of current mode's entry node
    let prevStepOrder = /** @type {number|null} */ (null);

    for (const evt of events) {
      if (evt.kind === 'mode') {
        // Terminate the previous lane's last step as exit.
        if (prevStepOrder !== null) {
          const prev = rawNodes.find((n) => n.order === prevStepOrder);
          if (prev) prev.terminal = { advanceType: 'UNSPECIFIED', handoff: null };
        }

        order++;
        const nodeOrder = order;
        rawNodes.push(makeNode({
          order: nodeOrder,
          name: evt.name,
          label: evt.label,
          provenance: buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill'),
          terminal: null,
        }));
        laneEntry = nodeOrder;
        prevStepOrder = null;
      } else {
        // Step under the current mode (or without a mode — shouldn't happen in hasModes path).
        order++;
        const nodeOrder = order;
        rawNodes.push(makeNode({
          order: nodeOrder,
          name: evt.name,
          label: evt.label,
          provenance: buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill'),
          terminal: null,
        }));

        // Edge: from laneEntry or prevStep → this step.
        const fromOrder = prevStepOrder ?? laneEntry;
        if (fromOrder !== null) {
          const prov = buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill');
          rawEdges.push(makeEdge({
            from: 'n' + fromOrder,
            to: 'n' + nodeOrder,
            kind: 'sequence',
            condition: null,
            advanceType: 'CHAIN',
            provenance: prov,
          }));
        }
        prevStepOrder = nodeOrder;
      }
    }

    // Terminate the final lane's last step as exit.
    if (prevStepOrder !== null) {
      const last = rawNodes.find((n) => n.order === prevStepOrder);
      if (last) last.terminal = { advanceType: 'UNSPECIFIED', handoff: null };
    }
  } else {
    // Single lane: steps only, no mode entries.
    for (const evt of events) {
      if (evt.kind !== 'step') continue;
      order++;
      const nodeOrder = order;
      rawNodes.push(makeNode({
        order: nodeOrder,
        name: evt.name,
        label: evt.label,
        provenance: buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill'),
        terminal: null,
      }));
      if (order > 1) {
        const prov = buildProvenance(file, allLines, evt.lineNum, evt.lineNum, 'skill');
        rawEdges.push(makeEdge({
          from: 'n' + (order - 1),
          to: 'n' + order,
          kind: 'sequence',
          condition: null,
          advanceType: 'CHAIN',
          provenance: prov,
        }));
      }
    }
    // Last node is exit.
    if (rawNodes.length > 0) {
      rawNodes[rawNodes.length - 1].terminal = { advanceType: 'UNSPECIFIED', handoff: null };
    }
  }

  return rawNodes.length >= 1 ? { rawNodes, rawEdges } : null;
}

// ── R4 — top-level ordered list with verb-starting items ─────────────────────

/**
 * R4: find a top-level ordered list (`^\d+\.\s+...`) whose items begin with a
 * word that is not a known non-verb starter. Returns null when fewer than 2
 * qualifying items are found, or when no items begin with a verb.
 *
 * This rung does not fire for any of the 13 currently-known residual skills but
 * is implemented to satisfy the ladder's completeness requirement.
 *
 * @param {string[]} bodyLines
 * @param {string[]} allLines
 * @param {number}   bodyStartLine
 * @param {string}   file
 * @returns {{ rawNodes: object[], rawEdges: object[] } | null}
 */
function _tryR4(bodyLines, allLines, bodyStartLine, file) {
  let inFence = false;
  /** @type {{ text: string, lineNum: number }[]} */
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
      items.push({ text, lineNum: bodyStartLine + i });
    }
  }

  if (items.length < 2) return null;

  const rawNodes = [];
  const rawEdges = [];

  for (let i = 0; i < items.length; i++) {
    const { text, lineNum } = items[i];
    const isLast = i === items.length - 1;
    rawNodes.push(makeNode({
      order: i + 1,
      name: `STEP-${i + 1}`,
      label: truncate(text, 60),
      provenance: buildProvenance(file, allLines, lineNum, lineNum, 'skill'),
      terminal: isLast ? { advanceType: 'UNSPECIFIED', handoff: null } : null,
    }));
  }

  for (let i = 0; i < items.length - 1; i++) {
    const prov = buildProvenance(file, allLines, items[i].lineNum, items[i].lineNum, 'skill');
    rawEdges.push(makeEdge({
      from: 'n' + (i + 1),
      to: 'n' + (i + 2),
      kind: 'sequence',
      condition: null,
      advanceType: 'CHAIN',
      provenance: prov,
    }));
  }

  return { rawNodes, rawEdges };
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
