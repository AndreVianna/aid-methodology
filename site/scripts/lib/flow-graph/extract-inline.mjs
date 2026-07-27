// extract-inline.mjs — Inline ## State: extractor (feature-003, D2 shape).
//
// Recognises skills where two or more `^##\s+State:\s+\S` headings declare
// the state machine inline in the SKILL.md body. Each heading becomes one node;
// edges come from the section's **Advance:** block (via advance.mjs) and from
// body back-references to earlier-order states (rule 7) and Loopback/Re-entry
// headings within the body (rule 8).
//
// Exported API:
//   extractInline(params) → FlowChart | null
//     Returns null when fewer than 2 ## State: headings exist (not D2 shape).
//
// Pure exports — no import-time side effect.

import { truncate, makeNode, buildChart } from './model.mjs';
import { buildProvenance, findStateSections } from './source.mjs';
import { extractAdvanceBlock, parseAdvanceBlock } from './advance.mjs';

// ── Constants ──────────────────────────────────────────────────────────────────

const EXTRACTOR = 'inline';
const SHAPE = 'inline-states';
const CONFIDENCE = 'derived';

/** Matches the **Advance:** marker line (with or without bold delimiters). */
const ADVANCE_MARKER_RE = /^\s*\*{0,2}Advance:\*{0,2}\s*/i;

/** Matches any Markdown heading at levels 2–6 (captured: hashes, text). */
const HEADING_RE = /^(#{2,6})\s+(.*)/;

/**
 * Detects Loopback or Re-entry phrasing in heading text (rule 8, case-insensitive).
 * Matches "Loopback", "Loopbacks", "Re-entry", "Re-Entry", etc.
 */
const RE_ENTRY_HEADING_RE = /Loopback|Re-entry/i;

/**
 * Token scanner: a letter followed by letters, digits, or hyphens.
 * Hyphenated names (PRESENT-FINDINGS, Q-AND-A) are one token.
 * MUST be reset via lastIndex = 0 before each exec loop (global flag).
 */
const TOKEN_RE = /[A-Za-z][A-Za-z0-9-]*/g;

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Extract an `inline-states` flow chart for a skill that declares its state
 * machine as a sequence of `## State: NAME` headings in its SKILL.md body.
 *
 * Returns null when fewer than two `## State:` headings exist; the caller should
 * fall back to the residual extractor in that case.
 *
 * Processing steps:
 *   1. Locate all `## State: NAME` sections via `findStateSections()` (source.mjs).
 *   2. Build one node per section: `name` = heading name (gloss stripped),
 *      `label` = gloss if present else name (both ≤ 60 code points via `truncate`).
 *   3. `provenance` = heading through lead paragraph; `detail` = full section range.
 *      Both ranges come from `buildProvenance()` over the shared section data.
 *   4. Edges from the section's `**Advance:**` block via `extractAdvanceBlock` +
 *      `parseAdvanceBlock` (advance.mjs owns rules 1–10 and V9).
 *   5. Additional `loop-back` edges from body back-references (rule 7): any line
 *      in the section body that names a declared state with lower order than the
 *      current one emits one `loop-back` edge, deduplicated against advance edges.
 *   6. Rule 8: a sub-heading in the section body whose text contains 'Loopback'
 *      or 'Re-entry' and names a declared state emits one `re-entry` edge.
 *   7. A state with no `**Advance:**` line and no outgoing back-reference is an
 *      exit with `advanceType: 'UNSPECIFIED'` — this is how `aid-review`'s `DONE`
 *      terminates.
 *
 * @param {object}   params
 * @param {string}   params.skill         Skill directory name (under canonical/skills/).
 * @param {string}   params.file          Repo-root-relative POSIX path to the SKILL.md.
 * @param {string[]} params.allLines      All file lines, 0-indexed, CRLF stripped.
 * @param {object}   [params.frontmatter] Parsed frontmatter (unused; kept for interface
 *                                        symmetry with other extractor functions).
 * @returns {import('./model.mjs').FlowChart | null}
 */
export function extractInline({ skill, file, allLines, frontmatter: _fm }) {
  const sections = findStateSections(allLines, file);
  if (sections.length < 2) return null;

  // Build the declared-states list (1-based order, n1…nN ids) consumed by
  // parseAdvanceBlock for target resolution, V9, rule 7, and rule 9.
  const declaredStates = sections.map((s, i) => ({
    name: s.name,
    order: i + 1,
    id: `n${i + 1}`,
  }));

  // Case-insensitive index: lowercase name → lowest-order state record.
  // Collision is rare; parseAdvanceBlock's _buildStateIndex also warns on it.
  const stateByName = new Map();
  for (const s of declaredStates) {
    const key = s.name.toLowerCase();
    if (!stateByName.has(key)) stateByName.set(key, s);
  }

  const rawNodes = [];
  const rawEdges = [];
  const warnings = [];

  for (let i = 0; i < sections.length; i++) {
    const section = sections[i];
    const order = i + 1;
    const id = `n${order}`;

    // ── Label: use parenthetical gloss when present ───────────────────────────
    // findStateSections already strips the gloss from section.name; recover the
    // raw heading text to extract the gloss and offer it as a label candidate.
    const headingText = allLines[section.headingLine - 1] ?? '';
    const rawNameMatch = headingText.match(/^##\s+State:\s+(\S.*)/);
    const rawName = rawNameMatch ? rawNameMatch[1].trim() : section.name;
    const glossMatch = rawName.match(/\s*\(([^)]*)\)\s*$/);
    const gloss = glossMatch ? glossMatch[1].trim() : null;
    const label = gloss ? truncate(gloss, 60) : truncate(section.name, 60);

    // ── Provenance: heading through lead paragraph ────────────────────────────
    // The compact range (heading + lead) is the authoritative provenance excerpt
    // for feature-005's line-range equality check.
    const provenance = buildProvenance(
      file, allLines, section.headingLine, section.leadEndLine, 'skill'
    );

    // ── Detail: full section range ────────────────────────────────────────────
    const detail = buildProvenance(
      file, allLines, section.headingLine, section.sectionEndLine, 'skill'
    );

    // ── Advance block ─────────────────────────────────────────────────────────
    // Scan body lines for the first **Advance:** marker, extract the block, and
    // delegate parsing (rules 1–10, V9) to advance.mjs.
    let advanceEdges = [];
    let advanceTerminal = null;
    let hasAdvanceLine = false;

    for (let j = section.headingLine; j < section.sectionEndLine; j++) {
      if (!ADVANCE_MARKER_RE.test(allLines[j])) continue;

      hasAdvanceLine = true;
      const blockStartLine = j + 1; // 1-based
      const { blockText } = extractAdvanceBlock(allLines, j);

      const result = parseAdvanceBlock({
        block: blockText,
        fromNodeId: id,
        fromNodeName: section.name,
        declaredStates,
        file,
        blockStartLine,
        sourceKind: 'skill',
      });

      // Add `from` — parseAdvanceBlock returns edges without it.
      advanceEdges = result.edges.map((e) => ({ from: id, ...e }));
      advanceTerminal = result.terminal;
      warnings.push(...result.warnings);
      break; // at most one **Advance:** block per section
    }

    // ── Body back-reference scan (rule 7) + rule 8 ───────────────────────────
    // Scan body lines for declared states that are not already advance-block
    // targets. Back-references (lower order) become loop-back edges; rule-8
    // headings produce re-entry edges. advance.mjs already applied rule 7 KIND
    // assignment to advance-block edges; here we produce the additional edges.
    const existingTargets = new Set(advanceEdges.map((e) => e.to));
    const bodyEdgeObjs = _scanBodyEdges(
      allLines,
      section.headingLine,
      section.sectionEndLine,
      order,
      stateByName,
      existingTargets,
      file
    );
    const bodyEdges = bodyEdgeObjs.map((e) => ({ from: id, ...e }));

    // ── Terminal ──────────────────────────────────────────────────────────────
    // Rule: a state with no **Advance:** line and no outgoing back-reference is
    // an exit with advanceType: 'UNSPECIFIED'. This covers aid-review's DONE.
    const hasOutgoing = advanceEdges.length > 0 || bodyEdges.length > 0;
    const terminal = hasAdvanceLine
      ? advanceTerminal
      : hasOutgoing
        ? null
        : { advanceType: 'UNSPECIFIED', handoff: null };

    rawNodes.push(
      makeNode({ order, name: section.name, label, provenance, detail, terminal })
    );
    rawEdges.push(...advanceEdges, ...bodyEdges);
  }

  return buildChart({
    skill,
    shape: SHAPE,
    extractor: EXTRACTOR,
    confidence: CONFIDENCE,
    nodes: rawNodes,
    edges: rawEdges,
    sources: [file],
    warnings,
  });
}

// ── Internal helpers ───────────────────────────────────────────────────────────

/**
 * Scan section body lines for back-reference edges (rule 7) and re-entry edges
 * (rule 8), deduplicated against `existingTargets`.
 *
 * Rule 7 back-references: any non-heading, non-fenced line that mentions a
 * declared state whose order < `currentOrder` emits one `loop-back` edge (the
 * first occurrence wins; duplicates are suppressed via `seen`).
 *
 * Rule 8 re-entry: a sub-heading (`##` through `######`) whose text contains
 * 'Loopback' or 'Re-entry' AND names a declared state emits one `re-entry` edge
 * to that state, regardless of order. Takes precedence over rule 7 for the same
 * line; the heading line is not also back-reference-scanned.
 *
 * Fenced code blocks (``` … ```) are skipped — state tokens inside code are
 * implementation examples, not control-flow references.
 *
 * @param {string[]} allLines       Full file line array, 0-indexed, CRLF stripped.
 * @param {number}   headingLine    1-based line number of the `## State:` heading.
 *                                  Body lines start at 0-indexed `headingLine`
 *                                  (= 1-based `headingLine + 1`).
 * @param {number}   sectionEndLine 1-based last line of the full section (inclusive).
 * @param {number}   currentOrder   1-based source-order of the current node.
 * @param {Map<string, {name:string, order:number, id:string}>} stateByName
 *                                  Case-insensitive state index (lowercase key).
 * @param {Set<string>} existingTargets  Target node ids from the advance block.
 * @param {string}   file           Repo-root-relative POSIX path for provenance.
 * @returns {Array<{to:string, kind:string, condition:null, advanceType:'UNSPECIFIED',
 *                  provenance: import('./model.mjs').Provenance}>}
 */
function _scanBodyEdges(
  allLines, headingLine, sectionEndLine, currentOrder, stateByName, existingTargets, file
) {
  const result = [];
  const seen = new Set(existingTargets);
  let inFence = false;

  // Body lines: 0-indexed headingLine … sectionEndLine - 1
  for (let j = headingLine; j < sectionEndLine; j++) {
    const line = allLines[j];
    const lineNum = j + 1; // 1-based

    // Track fenced code blocks.
    if (/^```/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    // Rule 8: heading containing Loopback or Re-entry.
    const headM = line.match(HEADING_RE);
    if (headM && RE_ENTRY_HEADING_RE.test(headM[2])) {
      const target = _firstDeclaredState(headM[2], stateByName);
      if (target && !seen.has(target.id)) {
        seen.add(target.id);
        result.push({
          to: target.id,
          kind: 're-entry',
          condition: null,
          advanceType: 'UNSPECIFIED',
          provenance: buildProvenance(file, allLines, lineNum, lineNum, 'skill'),
        });
      }
      continue; // rule 8 owns this line; skip back-ref scan for it
    }

    // Rule 7 back-reference scan: token-match declared states in line.
    // Exact-case match is required to avoid false positives from common verbs
    // ("run", "done", "review") in prose that coincidentally match an uppercase
    // state name — body text is free-form English, not structured advance syntax.
    TOKEN_RE.lastIndex = 0;
    let m;
    while ((m = TOKEN_RE.exec(line)) !== null) {
      const state = stateByName.get(m[0].toLowerCase());
      if (!state) continue;
      if (state.name !== m[0]) continue;          // exact-case match required
      if (state.order >= currentOrder) continue; // forward or self reference
      if (seen.has(state.id)) continue;           // already emitted

      seen.add(state.id);
      result.push({
        to: state.id,
        kind: 'loop-back',
        condition: null,
        advanceType: 'UNSPECIFIED',
        provenance: buildProvenance(file, allLines, lineNum, lineNum, 'skill'),
      });
    }
  }

  return result;
}

/**
 * Return the first declared state whose name appears as a whole token in `text`,
 * or null when none is found. Used by rule 8 to find the re-entry target.
 *
 * @param {string} text
 * @param {Map<string, {name:string, order:number, id:string}>} stateByName
 * @returns {{name:string, order:number, id:string} | null}
 */
function _firstDeclaredState(text, stateByName) {
  TOKEN_RE.lastIndex = 0;
  let m;
  while ((m = TOKEN_RE.exec(text)) !== null) {
    const state = stateByName.get(m[0].toLowerCase());
    if (state) return state;
  }
  return null;
}
