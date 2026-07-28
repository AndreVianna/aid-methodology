// extract-dispatch.mjs — FlowChart extractor for the D1 dispatch-table shape.
//
// Entry: extractDispatch(skill, dir, repoRoot) → FlowChart
//
// D1 skills carry a `## Dispatch` or `## State Machine` heading followed by
// a GFM table whose header row has both a `State` and an `Advance` column.
// Each data row is one FlowNode; edges come from the Advance cell and from
// the state's worker file (references/state-*.md) or inline ## State: section.
//
// Rule 8 (Re-entry heading) is implemented here as the user routing confirmed.
// `advance.mjs` carries a defensive guard but never assigns kind:'re-entry'
// itself — that assignment lives only in this extractor.
//
// Keyword-named states (states whose name equals an advance-type keyword such
// as HALT) require special handling: they are filtered from declaredStates
// passed to parseAdvanceBlock (preventing V9 false-positives caused by
// _resolveTarget stripping the keyword before state matching), and their
// edges are recovered via _extractKeywordStateEdges which scans for explicit
// [State: KEYWORD] and "-> KEYWORD" arrow patterns.
//
// [gen-skills] error prefix convention: every guard error cites file:line
// and the offending text.
//
// Pure side-effect-free beyond filesystem reads; no import-time side effects.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  splitFrontmatter,
  buildProvenance,
  findStateSections,
} from './source.mjs';
import { extractAdvanceBlock, parseAdvanceBlock } from './advance.mjs';
import { truncate, makeNode, makeEdge, buildChart } from './model.mjs';

// ── Constants ──────────────────────────────────────────────────────────────────

/** D1 heading text pattern (matched against body lines). */
const D1_HEADING_RE = /^#{2,}\s+(Dispatch|State Machine)\s*$/;

/** Heading that starts a new section (used to bound re-entry body scan). */
const SECTION_END_RE = /^#{1,6}\s/;

/**
 * Matches headings whose text contains "Loopback" or "Re-entry" (rule 8).
 * Level-agnostic: any heading depth qualifies.
 */
const REENTRY_HEADING_RE = /^#+\s+.*(?:Loopback|Re-entry)/i;

/**
 * Matches arrow-form state references in advance text ("→ STATE" or "-> STATE").
 * Used by the absent-state detector.  Not global — exec in loop with .exec().
 */
const ARROW_TARGET_RE = /(?:→|--?>+)\s*([A-Z][A-Z0-9-]*)/g;

/** Advance-type keywords (upper-case only) — excluded from absent-state warnings. */
const ADVANCE_TYPE_KEYWORDS = new Set([
  'CHAIN', 'HALT', 'PAUSE-FOR-USER-ACTION', 'PAUSE-FOR-USER-DECISION',
]);

/** Token scanner: letter then letters/digits/hyphens (same as advance.mjs). */
const TOKEN_RE = /[A-Za-z][A-Za-z0-9-]*/g;

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Extract a FlowChart from a D1 dispatch-table skill.
 *
 * Reads `canonical/skills/<skill>/SKILL.md`, locates the `## Dispatch` /
 * `## State Machine` table, and derives nodes + edges from its rows.  For
 * each row, the `Detail` cell supplies either a worker file path
 * (`references/state-*.md`) or the token `inline`, which binds the matching
 * `## State: NAME` section in the same file through `findStateSections`.
 *
 * Rule 8 (re-entry heading) is applied after the table: any heading whose
 * text contains `Loopback` or `Re-entry` and whose body names a declared
 * state emits a single `re-entry` edge into that state.
 *
 * @param {string} skill     Directory name under `canonical/skills/`.
 * @param {string} _dir      Unused; kept for API parity with other extractors.
 * @param {string} repoRoot  Absolute path to the repository root.
 * @returns {import('./model.mjs').FlowChart}
 * @throws {Error}  If no D1 table is found (callers should classifySkill first).
 */
export function extractDispatch(skill, _dir, repoRoot) {
  const skillRelPath = 'canonical/skills/' + skill + '/SKILL.md';
  const text = readFileSync(join(repoRoot, skillRelPath), 'utf8');
  const { allLines, bodyLines, bodyStartLine } = splitFrontmatter(text, skillRelPath);

  // ── 1. Locate the dispatch table ────────────────────────────────────────────
  const tableInfo = _findDispatchTable(bodyLines, bodyStartLine, skillRelPath);
  if (!tableInfo) {
    throw new Error(
      `[gen-skills] extract-dispatch: no dispatch table found (${skillRelPath}:1)`
    );
  }

  const { colState, colDetail, colAdvance, headerBodyIdx, dataRows } = tableInfo;

  // ── 2. Pre-assign IDs for parseAdvanceBlock (n1…nN by row order) ────────────
  const declaredStates = dataRows.map((r, i) => ({
    name: r.state,
    order: i + 1,
    id: 'n' + (i + 1),
  }));

  // States whose name collides with an advance-type keyword (e.g., HALT).
  // parseAdvanceBlock._resolveTarget strips these as keywords before state
  // matching, so they can never be edge targets — filter them from
  // declaredStates on every parseAdvanceBlock call and recover edges manually.
  const kwNamedStates = declaredStates.filter(
    (s) => ADVANCE_TYPE_KEYWORDS.has(s.name.toUpperCase())
  );

  const rawNodes = [];
  const rawEdges = [];
  const allWarnings = [];
  const sources = [skillRelPath];

  // ── 3. Process each dispatch row ─────────────────────────────────────────────
  for (let i = 0; i < dataRows.length; i++) {
    const row = dataRows[i];
    const nodeId = 'n' + (i + 1);
    const nodeOrder = i + 1;

    // 1-based line in the full file for this data row.
    // headerBodyIdx = 0-based index of header row in bodyLines.
    // +2 = skip header (0-based 0) and separator (0-based 1); +i = row index.
    const rowBodyIdx = headerBodyIdx + 2 + i;
    const rowFileLine = bodyStartLine + rowBodyIdx;

    // Safe declaredStates for parseAdvanceBlock: exclude the current node
    // (prevents prose mentions of a state's own name from triggering V9) and
    // exclude keyword-named states (prevents V9 false-positives caused by
    // _resolveTarget stripping keyword names before state matching).
    const safeDecl = declaredStates.filter(
      (s) => s.id !== nodeId && !kwNamedStates.some((k) => k.id === s.id)
    );

    // ── Row Advance parse ────────────────────────────────────────────────────
    const rowBlock = '**Advance:** ' + row.advance;
    const rowResult = parseAdvanceBlock({
      block: rowBlock,
      fromNodeId: nodeId,
      fromNodeName: row.state,
      declaredStates: safeDecl,
      file: skillRelPath,
      blockStartLine: rowFileLine,
      sourceKind: 'skill',
    });
    allWarnings.push(...rowResult.warnings);

    // ── Detail: worker file or inline section ────────────────────────────────
    let labelCandidate = null;
    let workerResult = null;
    let detailProvenance = null;

    // Strip backtick/bold formatting and, for file paths, discard any trailing
    // explanatory prose (e.g. `references/state-review.md (REUSES f005's panel…)`
    // → `references/state-review.md`).
    const detailRaw = _extractDetailPath(_stripMarkdownFormatting(row.detail));

    if (/\binline\b/i.test(detailRaw) && !detailRaw.startsWith('references/')) {
      // Inline: find the matching ## State: NAME section in the same SKILL.md.
      const { label, result, detail, warns } = _processInlineDetail(
        allLines, row.state, nodeId, safeDecl, skillRelPath
      );
      labelCandidate = label;
      workerResult = result;
      detailProvenance = detail;
      allWarnings.push(...warns);
    } else {
      // Worker file: path is repo-relative under canonical/skills/<skill>/.
      const detailPath = detailRaw.startsWith('references/')
        ? detailRaw
        : null;
      if (detailPath) {
        const workerRelPath = 'canonical/skills/' + skill + '/' + detailPath;
        if (!sources.includes(workerRelPath)) sources.push(workerRelPath);

        const { label, result, detail, warns } = _processWorkerDetail(
          workerRelPath, nodeId, row.state, safeDecl, repoRoot
        );
        labelCandidate = label;
        workerResult = result;
        detailProvenance = detail;
        allWarnings.push(...warns);

        // Absent-state check: warn if the worker advance text references a state
        // not in the dispatch table (no edge is produced for it, but no silent drop).
        if (workerResult) {
          _checkAbsentStates(
            workerResult._rawAdvanceText, workerRelPath,
            workerResult._advanceStartLine, declaredStates, allWarnings
          );
        }
      } else {
        // Unknown detail format — emit a warning, fall through to row-only.
        allWarnings.push(
          `[gen-skills] extract-dispatch: unrecognised detail cell '${row.detail}' ` +
          `for state '${row.state}' (${skillRelPath}:${rowFileLine})`
        );
      }
    }

    // ── Merge edges: worker wins by `to` (DETAIL: "worker conditions winning") ─
    // Artifact conditions (bold markers, inline commentary) in worker edges are
    // neutralised so the row's unconditional edge is preferred; Rule 5 self-loops
    // generated for artifact-conditional edges are also dropped.
    const mergedEdges = _mergeEdges(
      rowResult.edges, workerResult ? workerResult.edges : [], nodeId
    );

    // ── Keyword-state edges: recover edges to keyword-named states ───────────
    // parseAdvanceBlock cannot produce edges to keyword-named states because
    // _resolveTarget strips keyword names before state matching. Scan both the
    // row advance text and the worker raw advance text for explicit references.
    const nodeProv = buildProvenance(
      skillRelPath, allLines, rowFileLine, rowFileLine, 'skill'
    );
    const kwEdges = _extractKeywordStateEdges(
      [row.advance, workerResult ? workerResult._rawAdvanceText : null],
      nodeId, kwNamedStates, nodeProv
    );
    // Exclude duplicate targets already in mergedEdges
    const mergedTargets = new Set(mergedEdges.map((e) => e.to));
    for (const ke of kwEdges) {
      if (!mergedTargets.has(ke.to)) {
        mergedEdges.push(ke);
        mergedTargets.add(ke.to);
      }
    }

    // Worker terminal wins if present; else row terminal.
    // A terminal produced when the only advance was to a keyword-named state is
    // spurious: Rule 4 fired on the keyword (CHAIN / HALT / PAUSE-*) embedded
    // in text like `**CHAIN** -> [State: HALT]`, but the real advance was to a
    // state — the keyword-state edge recovery above handles that. Clear the
    // terminal when keyword edges were emitted and all worker non-self edges
    // (if any) were for the keyword-named state.
    const hasKwEdges = kwEdges.length > 0;
    /**
     * @param {{advanceType:string}|null} term
     * @param {Array} workerEdges
     */
    const isSpuriousTerminal = (term, workerEdges) =>
      hasKwEdges &&
      term !== null &&
      kwNamedStates.some((k) => k.name.toUpperCase() === term.advanceType) &&
      workerEdges.filter((e) => e.to !== nodeId).length === 0;

    let terminal;
    if (workerResult && workerResult.terminal !== null) {
      terminal = isSpuriousTerminal(workerResult.terminal, workerResult.edges)
        ? null
        : workerResult.terminal;
    } else {
      terminal = rowResult.terminal;
    }
    // Also clear a row-level spurious terminal when keyword edges are emitted.
    if (isSpuriousTerminal(terminal, rowResult.edges)) {
      terminal = null;
    }

    // ── Label ladder ──────────────────────────────────────────────────────────
    // 1. labelCandidate from worker/inline (includes Purpose: check)
    // 2. title-cased name
    const label = labelCandidate
      ? truncate(_normaliseLabel(labelCandidate), 60)
      : _titleCase(row.state);

    rawNodes.push(makeNode({
      order: nodeOrder,
      name: row.state,
      label,
      provenance: nodeProv,
      terminal,
      detail: detailProvenance,
    }));

    // Emit merged edges from this node.
    for (const e of mergedEdges) {
      rawEdges.push(makeEdge({
        from: nodeId,
        to: e.to,
        kind: e.kind,
        condition: e.condition,
        advanceType: e.advanceType,
        provenance: e.provenance,
      }));
    }
  }

  // ── 4. Rule 8: Re-entry headings in the skill body ──────────────────────────
  const reentryEdges = _findReentryEdges(
    bodyLines, bodyStartLine, declaredStates, skillRelPath, allLines
  );
  rawEdges.push(...reentryEdges);

  // ── 5. Build and return the chart ────────────────────────────────────────────
  return buildChart({
    skill,
    shape: 'dispatch-table',
    extractor: 'extract-dispatch',
    confidence: 'derived',
    nodes: rawNodes,
    edges: rawEdges,
    sources,
    warnings: allWarnings,
  });
}

// ── Table Finder ───────────────────────────────────────────────────────────────

/**
 * Locate the first D1 dispatch table in `bodyLines` and parse its header and
 * data rows.
 *
 * @param {string[]} bodyLines      Lines after the frontmatter (0-indexed).
 * @param {number}   bodyStartLine  1-based line of bodyLines[0] in the full file.
 * @param {string}   skillRelPath   Used in error messages only.
 * @returns {{
 *   colState:      number,
 *   colDetail:     number,
 *   colAdvance:    number,
 *   headerBodyIdx: number,
 *   dataRows:      Array<{state:string, detail:string, advance:string}>
 * } | null}
 */
function _findDispatchTable(bodyLines, bodyStartLine, skillRelPath) {
  for (let i = 0; i < bodyLines.length; i++) {
    if (!D1_HEADING_RE.test(bodyLines[i])) continue;

    // Scan forward for the first pipe-row (the header).
    for (let j = i + 1; j < bodyLines.length; j++) {
      if (SECTION_END_RE.test(bodyLines[j])) break; // next heading, no table found
      if (!bodyLines[j].trimStart().startsWith('|')) continue;

      // Found header row — parse column indices.
      const cols = bodyLines[j].split('|').map((c) => c.trim()).filter(Boolean);
      const colState = cols.findIndex((c) => c === 'State');
      const colDetail = cols.findIndex((c) => c === 'Detail');
      const colAdvance = cols.findIndex((c) => c === 'Advance');

      if (colState === -1 || colAdvance === -1) break; // wrong table
      // colDetail may be -1 for a table that has no Detail column; we accept that.

      // j is the header row (0-based in bodyLines).
      const headerBodyIdx = j;

      // j+1 is the separator row; data rows start at j+2.
      const dataRows = [];
      for (let k = j + 2; k < bodyLines.length; k++) {
        const line = bodyLines[k];
        if (!line.trimStart().startsWith('|')) break;
        const cells = line.split('|').map((c) => c.trim()).filter(Boolean);
        if (cells.length === 0) break;

        const state = cells[colState] ?? '';
        const detail = colDetail !== -1 ? (cells[colDetail] ?? '') : '';
        const advance = cells[colAdvance] ?? '';

        if (!state) continue; // skip empty state cells
        dataRows.push({ state, detail, advance });
      }

      return { colState, colDetail, colAdvance, headerBodyIdx, dataRows };
    }
  }
  return null;
}

// ── Detail Processors ──────────────────────────────────────────────────────────

/**
 * Process an inline detail cell: find the matching `## State: NAME` section
 * in the same SKILL.md, derive a label candidate, and parse its advance block.
 *
 * Uses `findStateSections` from source.mjs — no private section reader.
 *
 * @param {string[]} allLines       Full file lines (0-indexed, CRLF stripped).
 * @param {string}   stateName      State name to match.
 * @param {string}   nodeId         Pre-assigned node id for parseAdvanceBlock.
 * @param {Array}    safeDecl       Filtered declared states (excl. self + keywords).
 * @param {string}   skillRelPath   Repo-relative path for provenance and errors.
 * @returns {{ label: string|null, result: object|null, detail: object|null, warns: string[] }}
 */
function _processInlineDetail(allLines, stateName, nodeId, safeDecl, skillRelPath) {
  const warns = [];
  const sections = findStateSections(allLines, skillRelPath);
  const section = sections.find(
    (s) => s.name.toLowerCase() === stateName.toLowerCase()
  );

  if (!section) {
    warns.push(
      `[gen-skills] extract-dispatch: inline detail for state '${stateName}' ` +
      `has no matching ## State: section (${skillRelPath})`
    );
    return { label: null, result: null, detail: null, warns };
  }

  // Label candidate: Purpose: line or first prose sentence from lead paragraph.
  const label = _extractLabelFromSection(
    allLines, section.headingLine, section.leadEndLine
  );

  // Detail provenance: full section range, sourceKind 'skill'.
  const detail = buildProvenance(
    skillRelPath, allLines, section.headingLine, section.sectionEndLine, 'skill'
  );

  // Advance block: scan the section lines for **Advance:** marker anchored to
  // the start of the line (not inside list items or other inline contexts).
  const sectionLines = allLines.slice(section.headingLine - 1, section.sectionEndLine);
  const advanceMarkerIdx = sectionLines.findIndex(
    (l) => /^\s*\*{1,2}Advance:/.test(l)
  );

  if (advanceMarkerIdx === -1) {
    // No advance block in this section — use row advance only.
    return { label, result: null, detail, warns };
  }

  const { blockText } = extractAdvanceBlock(sectionLines, advanceMarkerIdx);
  const advanceStartLine = section.headingLine + advanceMarkerIdx; // 1-based in file

  let result;
  try {
    result = parseAdvanceBlock({
      block: blockText,
      fromNodeId: nodeId,
      fromNodeName: stateName,
      declaredStates: safeDecl,
      file: skillRelPath,
      blockStartLine: advanceStartLine,
      sourceKind: 'skill',
    });
  } catch (err) {
    // V9 false-positives: convert to warning; row advance used as fallback.
    if (typeof err.message === 'string' && err.message.startsWith('[gen-skills] V9:')) {
      warns.push(
        `[gen-skills] extract-dispatch: W-V9 in inline section for state ` +
        `'${stateName}' in '${skillRelPath}': ${err.message}`
      );
      result = { edges: [], terminal: null, warnings: [] };
    } else {
      throw err;
    }
  }
  // Attach raw text for absent-state check (sourceKind='skill' so skip that check here).
  result._rawAdvanceText = blockText;
  result._advanceStartLine = advanceStartLine;

  warns.push(...result.warnings);
  return { label, result, detail, warns };
}

/**
 * Process a worker-file detail cell: read `references/state-*.md`, extract the
 * first prose sentence as a label candidate, and parse its advance block.
 *
 * @param {string}   workerRelPath   Repo-relative path to the worker file.
 * @param {string}   nodeId          Pre-assigned node id for parseAdvanceBlock.
 * @param {string}   stateName       State name (for error messages).
 * @param {Array}    safeDecl        Filtered declared states (excl. self + keywords).
 * @param {string}   repoRoot        Absolute path to the repo root.
 * @returns {{ label: string|null, result: object|null, detail: object|null, warns: string[] }}
 */
function _processWorkerDetail(workerRelPath, nodeId, stateName, safeDecl, repoRoot) {
  const warns = [];

  let workerText;
  try {
    workerText = readFileSync(join(repoRoot, workerRelPath), 'utf8');
  } catch (err) {
    warns.push(
      `[gen-skills] extract-dispatch: worker file not found: '${workerRelPath}' ` +
      `(state '${stateName}'): ${err.message}`
    );
    return { label: null, result: null, detail: null, warns };
  }

  const workerLines = workerText.split('\n').map((l) => l.replace(/\r$/, ''));

  // Label candidate: Purpose: line or first prose sentence.
  const label = _extractLabelFromWorker(workerLines);

  // Detail provenance: whole file, sourceKind 'worker'.
  const workerFileEndLine = workerLines.length;
  const detail = buildProvenance(
    workerRelPath, workerLines, 1, workerFileEndLine, 'worker'
  );

  // Find **Advance:** marker anchored to the start of the line.
  // This guards against false matches inside numbered list items such as
  // "4. Do NOT commit. **Advance:** PAUSE-FOR-USER-ACTION …" which starts
  // with non-whitespace before the marker.
  const advanceMarkerIdx = workerLines.findIndex(
    (l) => /^\s*\*{1,2}Advance:/.test(l)
  );

  if (advanceMarkerIdx === -1) {
    return { label, result: null, detail, warns };
  }

  const { blockText } = extractAdvanceBlock(workerLines, advanceMarkerIdx);
  const advanceStartLine1Based = advanceMarkerIdx + 1; // 1-based in worker file

  let result;
  try {
    result = parseAdvanceBlock({
      block: blockText,
      fromNodeId: nodeId,
      fromNodeName: stateName,
      declaredStates: safeDecl,
      file: workerRelPath,
      blockStartLine: advanceStartLine1Based,
      sourceKind: 'worker',
    });
  } catch (err) {
    // V9 false-positives can occur when a state name coincides with a common
    // English word in prose (e.g. "continue" matching state CONTINUE inside
    // the phrase "(continue inline)").  Convert to a warning so the build
    // never fails; the row advance is used as the fallback.
    if (typeof err.message === 'string' && err.message.startsWith('[gen-skills] V9:')) {
      warns.push(
        `[gen-skills] extract-dispatch: W-V9 in worker '${workerRelPath}' for ` +
        `state '${stateName}': ${err.message}`
      );
      result = { edges: [], terminal: null, warnings: [] };
    } else {
      throw err;
    }
  }
  result._rawAdvanceText = blockText;
  result._advanceStartLine = advanceStartLine1Based;

  warns.push(...result.warnings);
  return { label, result, detail, warns };
}

// ── Edge Merger ────────────────────────────────────────────────────────────────

/**
 * Return true when `condition` is a markdown artifact with no real content —
 * e.g. `** **` (bold delimiters around whitespace after keyword stripping) or
 * `(continue inline` / `(continue inline)` (parenthetical navigation prose,
 * with or without the closing paren which may be stripped by _extractCondition's
 * trailing-punctuation trimmer).
 *
 * These conditions are created by `_extractCondition` in advance.mjs when the
 * clause text contains `**KEYWORD**` followed by parenthetical navigation prose.
 *
 * @param {string|null} condition
 * @returns {boolean}
 */
function _isArtifactCondition(condition) {
  if (condition === null) return false;
  // Strip bold-artifact pattern: ** ** (bold markers around whitespace only)
  let cleaned = condition.replace(/\*\*\s*\*\*/g, ' ').trim();
  // Standalone asterisk-only strings (e.g. `**` from `**Advance: CHAIN -> X **`)
  if (/^\*+$/.test(cleaned)) return true;
  // Strip parenthetical navigation prose: (continue inline), (continue inline
  // The closing ) may have been stripped by _extractCondition's punctuation trimmer.
  cleaned = cleaned.replace(/\(\s*continue\b[^)]*\)?/gi, '').trim();
  cleaned = cleaned.replace(/\(\s*chain\s+continues?\b[^)]*\)?/gi, '').trim();
  // Strip single-word navigation parentheticals — fragments left when `continue`
  // is stripped from `(continue inline)` by _extractCondition's state-name removal.
  // e.g. `( inline)` / `( inline` / `( below)` / `(continued)`.
  cleaned = cleaned.replace(/\(\s*(?:inline|below|above|continued?)\s*\)?/gi, '').trim();
  // …and the same words with no parenthesis at all. `_extractCondition` now drops an
  // orphaned trailing parenthetical outright, so what used to arrive as `( inline`
  // arrives as a bare `inline`. Both are routing notation rather than a condition,
  // and a chart edge labelled "inline" tells a reader nothing.
  cleaned = cleaned.replace(/^\s*(?:inline|below|above|continued?)\s*$/gi, '').trim();
  // Strip bare navigation phrases (no parens) produced when _extractCondition's
  // leading/trailing punctuation stripper removes the surrounding `(` and `)`.
  // e.g. `continue inline` (from `(continue inline)` minus parens).
  cleaned = cleaned.replace(/\bcontinue\s+inline\b/gi, '').trim();
  // Strip residual routing punctuation
  cleaned = cleaned.replace(/^[[\]().,;:!?→>-]+|[[\]().,;:!?→>-]+$/g, '').trim();
  return !cleaned;
}

/**
 * Merge row edges and worker edges with worker winning for every `to` node
 * that appears in the worker's set.  This implements DETAIL §3: "worker
 * conditions winning for (from, to) pairs."
 *
 * Exception: when ALL worker edges to a given `to` carry artifact conditions
 * (bold markers, parenthetical navigation prose with no real content), the
 * row's unconditional edge is preferred.  Concurrently, any Rule 5 "otherwise"
 * self-loop added by parseAdvanceBlock for those artifact-conditional edges is
 * dropped (it was triggered by the artifact condition, not a real guard).
 *
 * @param {Array}  rowEdges     Edges from the row advance parse.
 * @param {Array}  workerEdges  Edges from the worker advance parse.
 * @param {string} fromNodeId   Current node id (to detect self-loops).
 * @returns {Array}
 */
function _mergeEdges(rowEdges, workerEdges, fromNodeId) {
  if (workerEdges.length === 0) return rowEdges;

  // Separate Rule 5 self-loops from forward worker edges.
  const workerSelfLoops = workerEdges.filter((e) => e.to === fromNodeId);
  const workerNonSelf = workerEdges.filter((e) => e.to !== fromNodeId);

  // Group non-self worker edges by target.
  const workerByTarget = new Map();
  for (const e of workerNonSelf) {
    if (!workerByTarget.has(e.to)) workerByTarget.set(e.to, []);
    workerByTarget.get(e.to).push(e);
  }

  const result = [];
  const coveredTargets = new Set();

  for (const [toId, wEdges] of workerByTarget) {
    coveredTargets.add(toId);
    const allArtifact = wEdges.every((e) => _isArtifactCondition(e.condition));
    if (allArtifact) {
      // Prefer row's unconditional edge for this target.
      const rowEdge = rowEdges.find((e) => e.to === toId && e.condition === null);
      if (rowEdge) {
        result.push(rowEdge);
      } else {
        // No row unconditional edge: normalise artifact conditions to null.
        result.push(
          ...wEdges.map((e) => ({
            ...e,
            condition: null,
            kind: e.kind === 'loop-back' ? 'loop-back' : 'sequence',
          }))
        );
      }
    } else {
      result.push(...wEdges);
    }
  }

  // Include Rule 5 self-loops only when at least one worker non-self edge is
  // genuinely conditional (i.e., had a non-artifact condition).
  const hasNonArtifactNonSelf = workerNonSelf.some(
    (e) => !_isArtifactCondition(e.condition)
  );
  if (hasNonArtifactNonSelf) {
    result.push(...workerSelfLoops);
  }

  // Add row edges for targets not covered by worker.
  for (const rowEdge of rowEdges) {
    if (!coveredTargets.has(rowEdge.to)) {
      result.push(rowEdge);
    }
  }

  return result;
}

// ── Keyword-State Edge Recovery ────────────────────────────────────────────────

/**
 * Scan advance text snippets for explicit references to keyword-named declared
 * states and return edges for any that are missing from `existingEdges`.
 *
 * `parseAdvanceBlock._resolveTarget` strips advance-type keywords (CHAIN, HALT,
 * etc.) before matching state names, so states whose names collide with a
 * keyword can never be resolved normally.  This function recovers those edges
 * by matching the two explicit reference patterns:
 *   `[State: KEYWORDNAME]`   — bracket wrapper
 *   `→ KEYWORDNAME` / `-> KEYWORDNAME`  — bare arrow form
 *
 * @param {(string|null)[]} texts         Raw advance text snippets to scan.
 * @param {string}          fromNodeId    Source node id.
 * @param {Array<{name:string,id:string,order:number}>} kwNamedStates
 * @param {import('./model.mjs').Provenance} provenance  Shared provenance for edges.
 * @returns {Array<{to:string, kind:string, condition:string|null,
 *                  advanceType:string, provenance:object}>}
 */
function _extractKeywordStateEdges(texts, fromNodeId, kwNamedStates, provenance) {
  if (kwNamedStates.length === 0) return [];
  const edges = [];
  const added = new Set();

  for (const kwState of kwNamedStates) {
    if (kwState.id === fromNodeId) continue; // never self-loop
    if (added.has(kwState.id)) continue;

    const name = kwState.name.toUpperCase();
    // Match [State: KEYWORDNAME] (case-insensitive for the name part)
    const bracketRe = new RegExp(`\\[State:\\s*${name}\\s*\\]`, 'i');
    // Match -> KEYWORDNAME or → KEYWORDNAME followed by non-identifier char
    const arrowRe = new RegExp(`(?:→|--?>+)\\s*${name}(?![A-Za-z0-9-])`, 'i');

    for (const text of texts) {
      if (!text) continue;
      if (bracketRe.test(text) || arrowRe.test(text)) {
        edges.push({
          to: kwState.id,
          kind: 'sequence',
          condition: null,
          advanceType: 'CHAIN',
          provenance,
        });
        added.add(kwState.id);
        break;
      }
    }
  }
  return edges;
}

// ── Re-entry Rule (Rule 8) ─────────────────────────────────────────────────────

/**
 * Scan `bodyLines` for re-entry headings (containing "Loopback" or "Re-entry")
 * and emit a single `re-entry` edge into the first declared state named in each
 * heading's body.  Rule 8 takes precedence over rule 7 (backwards edge →
 * `re-entry`, never `loop-back`).
 *
 * The `from` node is the highest-order declared state that is not itself the
 * target, representing the prior run's final state.
 *
 * @param {string[]} bodyLines       Lines after frontmatter (0-indexed).
 * @param {number}   bodyStartLine   1-based line of bodyLines[0] in full file.
 * @param {Array<{name:string, order:number, id:string}>} declaredStates
 * @param {string}   skillRelPath    For provenance.
 * @param {string[]} allLines        Full file lines for provenance excerpts.
 * @returns {Array<import('./model.mjs').FlowEdge>}
 */
function _findReentryEdges(
  bodyLines, bodyStartLine, declaredStates, skillRelPath, allLines
) {
  const edges = [];
  if (declaredStates.length < 2) return edges;

  // Build case-insensitive state lookup (same as advance.mjs _buildStateIndex).
  const stateByName = new Map();
  for (const s of declaredStates) {
    stateByName.set(s.name.toLowerCase(), s);
  }

  for (let i = 0; i < bodyLines.length; i++) {
    if (!REENTRY_HEADING_RE.test(bodyLines[i])) continue;

    const headingBodyIdx = i;
    const headingFileLine = bodyStartLine + headingBodyIdx;

    // Collect the section body until the next heading.
    const bodyParts = [];
    let j = i + 1;
    while (j < bodyLines.length && !SECTION_END_RE.test(bodyLines[j])) {
      bodyParts.push(bodyLines[j]);
      j++;
    }
    const sectionText = bodyParts.join(' ');

    // Find the first declared state named in the section body.
    TOKEN_RE.lastIndex = 0;
    let toState = null;
    let m;
    while ((m = TOKEN_RE.exec(sectionText)) !== null) {
      const candidate = stateByName.get(m[0].toLowerCase());
      if (candidate) {
        toState = candidate;
        break;
      }
    }

    if (!toState) continue; // no declared state found — skip this heading

    // FROM = highest-order declared state that is not the target.
    const sorted = [...declaredStates].sort((a, b) => b.order - a.order);
    const fromState = sorted.find((s) => s.id !== toState.id);
    if (!fromState) continue; // only one state and it is the target

    // Provenance: the heading line.
    const prov = buildProvenance(
      skillRelPath, allLines, headingFileLine, headingFileLine, 'skill'
    );

    edges.push(makeEdge({
      from: fromState.id,
      to: toState.id,
      kind: 're-entry',
      condition: null,
      advanceType: 'UNSPECIFIED',
      provenance: prov,
    }));
  }

  return edges;
}

// ── Absent-State Detector ──────────────────────────────────────────────────────

/**
 * Emit warnings for arrow-form state references in a worker advance block that
 * are absent from the dispatch table.  These references resolve to no edge
 * (by construction of parseAdvanceBlock with restricted declaredStates), so no
 * dangling edge is ever produced; the warning surfaces the mismatch.
 *
 * Only arrow-form references (`→ TOKEN` / `-> TOKEN`) are checked to limit
 * false positives.
 *
 * @param {string}   advanceText     Raw advance block text.
 * @param {string}   workerRelPath   For error messages.
 * @param {number}   advanceStartLine 1-based line in the worker file.
 * @param {Array<{name:string}>} declaredStates
 * @param {string[]} warnings        Mutated in place.
 */
function _checkAbsentStates(advanceText, workerRelPath, advanceStartLine, declaredStates, warnings) {
  const tableNames = new Set(declaredStates.map((s) => s.name.toLowerCase()));
  ARROW_TARGET_RE.lastIndex = 0;
  let m;
  while ((m = ARROW_TARGET_RE.exec(advanceText)) !== null) {
    const token = m[1];
    if (ADVANCE_TYPE_KEYWORDS.has(token)) continue;
    if (tableNames.has(token.toLowerCase())) continue;
    warnings.push(
      `[gen-skills] extract-dispatch: worker '${workerRelPath}' references state ` +
      `'${token}' not in dispatch table (${workerRelPath}:${advanceStartLine}: ` +
      `'${token}' from arrow-form reference)`
    );
  }
}

// ── Label Helpers ─────────────────────────────────────────────────────────────

/**
 * Extract a label candidate from the lead paragraph of an inline ## State:
 * section.  Checks for a `Purpose:` line first (level 1 of the label ladder),
 * then falls back to the first prose sentence of the lead paragraph (level 3).
 *
 * @param {string[]} allLines    Full file lines (0-indexed).
 * @param {number}   headingLine 1-based line of the ## State: heading.
 * @param {number}   leadEndLine 1-based last line of heading + lead paragraph.
 * @returns {string|null}
 */
function _extractLabelFromSection(allLines, headingLine, leadEndLine) {
  // Level 1: Purpose: line anywhere in the lead range.
  for (let i = headingLine - 1; i < leadEndLine; i++) {
    const m = allLines[i].match(/^\*{0,2}Purpose:\*{0,2}\s+(.+)/);
    if (m) return m[1].trim();
  }

  // Level 3: first prose sentence of the lead paragraph.
  // Collect non-heading, non-blank lines after the heading.
  const proseParts = [];
  for (let i = headingLine; i < leadEndLine; i++) {
    const line = allLines[i];
    if (line.trim() === '' || /^#{1,6}\s/.test(line)) continue;
    proseParts.push(line.trim());
    // Stop after first paragraph (blank line resets).
    if (i + 1 < leadEndLine && allLines[i + 1].trim() === '') break;
  }
  if (proseParts.length === 0) return null;
  const prose = proseParts.join(' ');
  return _firstSentence(prose);
}

/**
 * Extract a label candidate from a worker file's lines.
 * Checks for a `Purpose:` line (level 1) then the first prose sentence (level 2).
 *
 * Worker files are plain markdown (no frontmatter) with a `# State: NAME`
 * heading on line 0.
 *
 * @param {string[]} workerLines  0-indexed lines (CRLF stripped).
 * @returns {string|null}
 */
function _extractLabelFromWorker(workerLines) {
  // Level 1: scan all lines for a Purpose: line.
  for (const line of workerLines) {
    const m = line.match(/^\*{0,2}Purpose:\*{0,2}\s+(.+)/);
    if (m) return m[1].trim();
  }

  // Level 2: first prose sentence — skip the leading # State: heading and blanks,
  // then take the first non-blank, non-heading paragraph.
  let started = false;
  const proseParts = [];
  for (let i = 0; i < workerLines.length; i++) {
    const line = workerLines[i].trim();
    if (!started) {
      // Skip the # State: heading (first heading).
      if (/^#+ /.test(workerLines[i])) { started = true; continue; }
      continue;
    }
    if (line === '') {
      if (proseParts.length > 0) break; // end of first paragraph
      continue; // skip blank lines before first paragraph
    }
    if (/^#+ /.test(workerLines[i]) || workerLines[i] === '---') break;
    // Skip list bullets and fenced code blocks as prose candidates.
    if (/^[-*+]|^\d+\./.test(line)) { if (proseParts.length > 0) break; continue; }
    if (line.startsWith('```')) { if (proseParts.length > 0) break; continue; }
    proseParts.push(line);
  }
  if (proseParts.length === 0) return null;
  return _firstSentence(proseParts.join(' '));
}

/**
 * Extract the first sentence from a prose string (up to the first `. ` or
 * terminal `.`/`!`/`?`).  Returns the full text when no sentence boundary is
 * found.
 *
 * @param {string} prose
 * @returns {string}
 */
function _firstSentence(prose) {
  // Find first `. ` or `. ` that ends a sentence
  const idx = prose.search(/[.!?]\s|[.!?]$/);
  if (idx === -1) return prose.trim();
  return prose.slice(0, idx + 1).trim();
}

/**
 * Strip markdown emphasis, links, and backtick spans and normalise whitespace,
 * ready for use as a label candidate.
 *
 * Does NOT apply the 60-code-point cap — callers truncate after calling this.
 *
 * @param {string} text
 * @returns {string}
 */
function _normaliseLabel(text) {
  return text
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')   // [text](url) → text
    .replace(/\*\*([^*]+)\*\*/g, '$1')           // **bold** → text
    .replace(/\*([^*]+)\*/g, '$1')               // *italic* → text
    .replace(/`[^`]+`/g, '')                     // `code` → ''
    .replace(/^\*{0,2}Purpose:\*{0,2}\s*/i, '')  // strip leading Purpose:
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Given the result of `_stripMarkdownFormatting(detailCell)`, extract just the
 * path or keyword by discarding any trailing explanatory prose.
 *
 * Detail cells sometimes carry prose after the path, e.g.:
 *   `references/state-review.md (REUSES f005's panel…)`
 * After backtick stripping this becomes:
 *   `references/state-review.md (REUSES f005's panel…)`
 * We keep only the first whitespace-delimited token when the value starts
 * with `references/`, leaving the prose behind.
 *
 * @param {string} raw  Result of `_stripMarkdownFormatting`.
 * @returns {string}
 */
function _extractDetailPath(raw) {
  if (raw.startsWith('references/')) {
    return raw.split(/\s/)[0];
  }
  return raw;
}

/**
 * Strip markdown formatting from a Detail cell value (backticks, bold/italic
 * markers, underscores) to get the raw file path or keyword.
 *
 * @param {string} cell
 * @returns {string}
 */
function _stripMarkdownFormatting(cell) {
  return cell
    .replace(/`/g, '')
    .replace(/\*+/g, '')
    .replace(/^_+|_+$/g, '')
    .trim();
}

/**
 * Title-case a state name: split on hyphens, capitalise the first letter of
 * each part, lowercase the rest, rejoin with hyphens.
 *
 * Examples: CONTINUE → Continue, Q-AND-A → Q-And-A, FIRST-RUN → First-Run.
 *
 * @param {string} name
 * @returns {string}
 */
function _titleCase(name) {
  return name
    .split('-')
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1).toLowerCase())
    .join('-');
}
