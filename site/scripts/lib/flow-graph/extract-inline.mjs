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
 *   5. Additional `loop-back` edges from body back-references (rule 7): a body
 *      mention of a declared state with lower order than the current one emits one
 *      `loop-back` edge, deduplicated against advance edges — but ONLY when that
 *      state is the target of a loop/return phrase, tested over the joined logical
 *      block rather than the physical line, and only when the occurrence is not part
 *      of a filename. A bare mention is not a return (task-058, closes W1-16).
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
/**
 * Rule 7 helper — is the state name at `idx` actually part of a filename?
 *
 * `TOKEN_RE` stops at `.`, so a state called `DESIGN` matches inside `DESIGN.md`. A file
 * reference is not a control-flow reference. Checks only for a following extension: a
 * leading path (`docs/DESIGN.md`) still ends in the extension, and a state legitimately
 * named at a sentence end (`… loop back to DESIGN.`) is followed by a period plus space
 * or EOL, not by 1-5 word characters.
 *
 * @param {string} line     The physical line.
 * @param {number} idx      Index where the state token starts.
 * @param {string} stateName The matched state name.
 * @returns {boolean} true when the occurrence is a filename and must be ignored.
 */
function _isFilenameAt(line, idx, stateName) {
  return /^\.[A-Za-z0-9]{1,5}\b/.test(line.slice(idx + stateName.length));
}

/**
 * Rule 7 helper — does this text return control TO `stateName`?
 *
 * Requires a loop/return cue whose object is the state: `loop back to REVIEW`,
 * `loop` + `to AUTHOR`, `return to BUILD`, `Loop back` + `to Step 1 (REVIEW)`.
 *
 * Bounded filler is allowed on both sides of `to` — up to 40 characters before it, and up
 * to 28 after — which is what lets the two real wrap directions and a parenthetical step
 * number through while still rejecting a cue aimed elsewhere. The 28 is the load-bearing
 * bound: "Write the revision **back to** the existing document (the diff was already
 * reviewed at PRESENT)" carries a genuine `back to`, but ~56 characters separate `to` from
 * `PRESENT`, so it correctly yields nothing. Widening that number past ~50 reintroduces
 * that exact fabricated edge.
 *
 * Validated against every loop-back provenance line in the corpus — 6 genuine, 7
 * fabricated, 13/13 classified correctly — before this rule was written.
 *
 * @param {string} stateName Declared state name (may contain hyphens).
 * @returns {RegExp} Case-insensitive matcher to test against a logical block.
 */
function _loopTargetRe(stateName) {
  const name = stateName.replace(/-/g, '\\-');
  return new RegExp(
    '(?:loops?|loop\\s+back|back|returns?|re-?enter(?:s|ing)?|re-?run|retry|goes?|go)' +
    '[\\s\\S]{0,40}?\\bto\\s+[^.\\n]{0,28}?\\*{0,2}`?' +
    name +
    '`?\\*{0,2}\\b',
    'i',
  );
}

/**
 * Rule 7 helper — join the wrapped lines around `idx` into one logical block.
 *
 * Markdown hard-wraps prose, so a sentence's verb and its object routinely sit on
 * different physical lines. The block runs between blank lines, headings and fences, and
 * is clamped to the section being scanned so a block never leaks into a sibling state.
 *
 * @param {string[]} allLines       Full file lines, 0-indexed.
 * @param {number}   idx            0-indexed line to expand around.
 * @param {number}   bodyStart      0-indexed first body line of this section.
 * @param {number}   sectionEndLine 1-based last line of the section (exclusive bound).
 * @returns {string} The joined block.
 */
function _logicalBlock(allLines, idx, bodyStart, sectionEndLine) {
  const isBreak = (l) => l === undefined || l.trim() === '' || /^#{1,6}\s/.test(l) || /^```/.test(l);
  let a = idx;
  let b = idx;
  while (a - 1 >= bodyStart && !isBreak(allLines[a - 1])) a--;
  while (b + 1 < sectionEndLine && !isBreak(allLines[b + 1])) b++;
  return allLines.slice(a, b + 1).join(' ');
}

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
    //
    // Exact case alone was NOT enough, and shipped 7 fabricated arrows on 4 published
    // charts before an unfamiliar reader caught it at an AC-7 comprehension spot-check
    // (work-001 W1-16, task-058). Mentioning an earlier state is not the same as
    // returning to it: `(model+effort from INTAKE Step 4)` drew REVIEW→INTAKE, and
    // `checks \`DESIGN.md\`` drew VERIFY→DESIGN. So the state must be the TARGET of a
    // loop/return phrase, and a filename occurrence is not a state reference at all.
    const block = _logicalBlock(allLines, j, headingLine, sectionEndLine);
    TOKEN_RE.lastIndex = 0;
    let m;
    while ((m = TOKEN_RE.exec(line)) !== null) {
      const state = stateByName.get(m[0].toLowerCase());
      if (!state) continue;
      if (state.name !== m[0]) continue;          // exact-case match required
      if (state.order >= currentOrder) continue; // forward or self reference
      if (seen.has(state.id)) continue;           // already emitted

      // Trigger 2 — filename collision. `TOKEN_RE` is /[A-Za-z][A-Za-z0-9-]*/g, so a
      // state named DESIGN matches inside `DESIGN.md`. aid-design drew 3 loop-backs of
      // which 0 were real, purely from prose mentioning its own output artifact.
      if (_isFilenameAt(line, m.index, state.name)) continue;

      // Trigger 1 — mention vs return. Tested over the joined LOGICAL BLOCK, never the
      // physical line: three of the six genuine loop-backs in the corpus wrap the verb
      // onto the previous line (`... -> loop` / `   to AUTHOR`), and the shared engine
      // wraps the other way (`Loop back` / `to Step 1 (REVIEW)`). A line-scoped test
      // deletes 15 real edges — measured, not assumed.
      if (!_loopTargetRe(state.name).test(block)) continue;

      seen.add(state.id);
      result.push({
        to: state.id,
        kind: 'loop-back',
        condition: null,
        advanceType: 'UNSPECIFIED',
        // Provenance stays on the PHYSICAL line the token matched, not the block, so
        // deep links keep pointing at the sentence the reader is shown.
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
