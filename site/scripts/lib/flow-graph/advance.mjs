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

/**
 * Non-global variant of ADVANCE_KW_RE for `.test()` calls that must not
 * advance lastIndex (rule-10 W-1 pure-commentary check).
 */
const ADVANCE_KW_PLAIN_RE = new RegExp(
  `(?<![A-Za-z0-9-])(${ADVANCE_TYPES_IN_TEXT.join('|')})(?![A-Za-z0-9-])`
);

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
  // pause-resume) and rule-10 / V9 (residual-text guard) added below.
  //
  // validate.mjs implements V1–V8 (pure FlowChart checks). V9 lives here
  // because residue is leftover source text that exists only during parsing:
  // a validator handed the finished FlowChart cannot distinguish "this state
  // was never mentioned" from "this state was mentioned and its edge was
  // silently dropped" — the KI-008 failure V9 exists to catch. Owner
  // decision recorded as work STATE.md Q3 and delivery-003 seam S5.
  //
  //   content       — normalized advance block text (single string)
  //   clauses       — accepted clause strings (phase-2 output)
  //   edges         — edge array produced above (may be mutated/extended)
  //   terminal      — terminal record produced above (may be replaced)
  //   stateByName   — state index (for V9 / W-1 declared-state lookups)
  //   fromNodeId, fromNodeName, file, blockStartLine — error-message context
  //   blockProvenance — provenance for new edges

  // States that are legitimately named in the advance text but deliberately not
  // edge targets from this node. V9 must skip them, or a rule that intentionally
  // declines to emit an edge becomes indistinguishable from a dropped one.
  const v9Exempt = new Set();

  // ── Rule 6: X then Y — optional side-trip ─────────────────────────────────
  // Runs before rules 5 and 9 (it changes edge count and kind).
  // For each consecutive clause pair separated by ` then ` in the content:
  //   - optionality marker on X → emit two branch edges (X with marker, Y null)
  //   - no marker → keep → X as sequence, remove → Y, warn
  for (let ci = 0; ci < clauses.length - 1; ci++) {
    const xClause = clauses[ci];
    const yClause = clauses[ci + 1];

    // Detect ` then ` between this adjacent pair in the normalized content.
    if (!content.includes(xClause + ' then ' + yClause)) continue;

    const xTarget = _resolveTarget(xClause, stateByName);
    const yTarget = _resolveTarget(yClause, stateByName);
    // Skip if either resolves to a terminal rather than a declared state.
    if (!xTarget || !yTarget) continue;

    // Find the edges produced by rules 2–4 for X and Y.
    const xEdgeIdx = edges.findIndex((e) => e.to === xTarget.id);
    const yEdgeIdx = edges.findIndex((e) => e.to === yTarget.id);

    const marker = _extractOptionalityMarker(xClause, xTarget.name);

    if (marker !== null) {
      // X is optional: both X and Y reachable from this node.
      // → X: branch with marker text as condition (verbatim).
      if (xEdgeIdx !== -1) {
        edges[xEdgeIdx] = { ...edges[xEdgeIdx], kind: 'branch', condition: marker };
      }
      // → Y: branch with condition null (the skip path).
      if (yEdgeIdx !== -1) {
        edges[yEdgeIdx] = { ...edges[yEdgeIdx], kind: 'branch', condition: null };
      }
    } else {
      // X is not optional: "X then Y" means "go to X, X advances to Y."
      // Keep → X as a sequence edge; remove → Y; warn.
      if (yEdgeIdx !== -1) {
        edges.splice(yEdgeIdx, 1);
      }
      // Y is deliberately NOT an edge target from this node — its edge belongs to
      // X's own advance. Exempt it from V9, or this warn-path is unreachable: V9
      // would find Y named in the text, absent from `edgeTargetIds`, and throw
      // before the caller ever sees the warning. The DETAIL and its acceptance
      // criterion both require "one sequence edge plus a warning" here, and FR-2
      // requires a chart be approximate rather than malformed — a throw makes the
      // page fail to build instead. Same shape as the pause-resume exemption below.
      v9Exempt.add(yTarget.id);
      warnings.push(
        `[gen-skills] advance: W-1: '${fromNodeName}' in '${file}:${blockStartLine}': ` +
        `' then ${yClause.slice(0, 40)}' was read as '${xTarget.name}'\`s onward flow ` +
        `via the ' then ' connector — if a branch edge to '${yTarget.name}' was intended, ` +
        `add an optionality marker (e.g. '(optional)') to the first clause`
      );
    }
  }

  // ── Rule 9: Pause-resume targets are metadata, not edges ──────────────────
  // Runs before rule 5 (cleans up PAUSE edges so rule 5 sees the final count).
  // A PAUSE-FOR-USER-* edge to a declared state records that state in
  // terminal.handoff and emits no edge — the transition is out-of-run.
  {
    const pauseIndices = [];
    for (let i = 0; i < edges.length; i++) {
      const e = edges[i];
      if (
        e.advanceType === 'PAUSE-FOR-USER-ACTION' ||
        e.advanceType === 'PAUSE-FOR-USER-DECISION'
      ) {
        pauseIndices.push(i);
      }
    }
    for (let j = pauseIndices.length - 1; j >= 0; j--) {
      const i = pauseIndices[j];
      const e = edges[i];
      const targetState = [...stateByName.values()].find((s) => s.id === e.to);
      edges.splice(i, 1);
      if (terminal !== null) {
        warnings.push(
          `[gen-skills] advance: multiple terminal clauses in '${fromNodeName}'; ` +
          `keeping last pause-resume (${file}:${blockStartLine})`
        );
      }
      terminal = {
        advanceType: e.advanceType,
        handoff: targetState ? targetState.name : null,
      };
    }
  }

  // ── Rule 5: Single-target conditional ⇒ self-loop ─────────────────────────
  // When the advance block produces exactly ONE conditional edge and the target
  // is not the source node itself, the state stays put while the guard is
  // unmet: emit a loop-back self-edge with condition 'otherwise'.
  // Not suppressed by dispatch-row branches (merged later by the extractor).
  if (
    edges.length === 1 &&
    edges[0].condition !== null &&
    edges[0].to !== fromNodeId
  ) {
    edges.push({
      to: fromNodeId,
      kind: 'loop-back',
      condition: 'otherwise',
      advanceType: 'UNSPECIFIED',
      provenance: blockProvenance,
    });
  }

  // ── Rule 7: Position-based kind assignment (back-reference ⇒ loop-back) ────
  // Any edge whose target sits earlier in the declared spine (lower order)
  // than its source is kind 'loop-back', whichever rule produced it.
  // Rule 8 (re-entry heading, applied by the extractor) takes precedence:
  // re-entry-typed edges are not downgraded here (defensive guard).
  {
    const fromOrder =
      [...stateByName.values()].find((s) => s.id === fromNodeId)?.order ?? 0;
    for (const edge of edges) {
      if (edge.kind === 're-entry') continue; // Rule 8: extractor owns re-entry
      const targetState = [...stateByName.values()].find((s) => s.id === edge.to);
      if (targetState && targetState.order < fromOrder) {
        edge.kind = 'loop-back';
      }
    }
  }

  // ── Rule 10 / V9: Residual-text guard ─────────────────────────────────────
  // W-1 (warning, never throw): non-commentary residue after clause extraction.
  // V9 (error, always throw): declared state in advance text that is not an
  // edge target or pause-resume handoff — the fingerprint of a dropped edge.
  {
    // Compute strict residue: the advance text not covered by accepted clause spans.
    const residue = _computeResidue(content, clauses);

    if (residue) {
      // "Pure commentary" test is mechanical: no declared-state token,
      // no advance-type keyword, no [State:…] reference.
      const isPureCommentary =
        !/\[State:\s+[^\]]+\]/.test(residue) &&
        !ADVANCE_KW_PLAIN_RE.test(residue) &&
        !_residueHasDeclaredState(residue, stateByName);

      if (!isPureCommentary) {
        warnings.push(
          `[gen-skills] advance: W-1: '${fromNodeName}' in '${file}:${blockStartLine}': ` +
          `non-commentary residue after clause extraction: '${truncate(residue, 60)}'`
        );
      }
    }

    // V9: scan the full advance text for declared state references that are
    // neither edge targets nor pause-resume handoffs. The full-text scan (not
    // just strict residue) catches states inside a clause's condition text —
    // the KI-008 scenario: DONE named in "HANDOFF … THEN DONE." where THEN is
    // not in the separator set, leaving DONE consumed by the condition but
    // unreachable as an edge.
    const edgeTargetIds = new Set(edges.map((e) => e.to));
    const handoffName = terminal?.handoff?.toLowerCase() ?? null;

    const contentForV9 = content
      .replace(STATE_WRAPPER_RE, '$1') // unwrap [State: X] → X
      .replace(ARROW_RE, ' ');          // strip arrows

    TOKEN_RE.lastIndex = 0;
    let vm;
    while ((vm = TOKEN_RE.exec(contentForV9)) !== null) {
      const state = stateByName.get(vm[0].toLowerCase());
      if (!state) continue;                           // not a declared state
      // Case-SENSITIVE, for the same reason target resolution is: a lowercase
      // token is English prose, not a reference to a state. Without this, making
      // resolution exact-case merely moves the defect — the false edge disappears
      // and V9 THROWS on the same prose instead, which is worse, since a throw
      // fails the page. It also serves V9's own stated design goal of staying
      // narrow, because a noisy guard is an ignored guard.
      if (state.name !== vm[0]) continue;
      if (edgeTargetIds.has(state.id)) continue;     // already an edge target
      if (handoffName && state.name.toLowerCase() === handoffName) continue; // pause handoff
      if (v9Exempt.has(state.id)) continue;          // rule 6 unmarked `then` tail

      // Unconsumed declared state — precise KI-008 fingerprint.
      throw new Error(
        `[gen-skills] V9: '${fromNodeName}' (${file}:${blockStartLine}): declared state ` +
        `'${state.name}' is referenced in the advance text but is not an edge target or ` +
        `pause-resume handoff — possible dropped edge. ` +
        `Advance: '${truncate(content, 60)}'`
      );
    }
  }

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
 * Return true if `text` reads as a complete routing outcome whose target is not a
 * declared state — an arrow form followed, eventually, by a state-shaped ALL-CAPS
 * token.  Used by `_buildClauses` to tell "an outcome pointing at an undeclared
 * state" (drop it) apart from "a sentence fragment" (keep it joined).
 *
 * Deliberately narrow: without an arrow this returns false, so ordinary prose that
 * happens to contain a `;` or `. ` still keeps its halves joined.
 *
 * @param {string} text  A clause half that failed `_clauseResolves`.
 * @returns {boolean}
 */
function _isUnresolvableOutcome(text) {
  // No `\b` after the token. It was there originally, and the reason for dropping it
  // is NOT that it is inert — an earlier version of this comment claimed that, and it
  // was wrong. `_` is a word character to `\b` but is matched by `[^A-Za-z0-9]`, so
  // the two forms disagree on exactly one input class: an underscored target such as
  // `-> FIX_THING`. With `\b` the token cannot end before `_`, no alternative split
  // succeeds, and the whole match fails; without it, `FIX` and `THING` are read as two
  // tokens and the text is recognised. Recognising it is the better answer — an
  // underscored name is still a name — so the assertion is dropped deliberately, and
  // the case is pinned by test rather than assumed unreachable.
  return /(->|→|=>)[^A-Za-z0-9]*(?:[A-Z][A-Z0-9-]{1,}[^A-Za-z0-9]*)+$/.test(text.trim());
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

      const r1 = _clauseResolves(text1, stateByName);
      const r2 = _clauseResolves(text2, stateByName);

      if (!r1 && !r2) continue;

      // When exactly ONE half fails to resolve, the default is to reject the cut and
      // keep the halves joined — the separator was punctuation inside a single clause,
      // not a boundary between two. That default is wrong for one shape: a half that
      // is itself a complete outcome routing to a state this skill never declares.
      //
      // `aid-update-kb`'s REVIEW row packs four `;`-separated outcomes into one cell,
      // and the third routes to FIX — a loop *mode* described in prose, not a row in
      // the Dispatch table. Rejecting that cut absorbed outcome 3 into outcome 4, so
      // the REVIEW -> APPROVAL edge published outcome 3's condition
      // ("grade/teach-back/… below gate … FIX…") instead of its own ("READY"). The
      // label named a target that was not the edge's target — worse than no label,
      // because it reads as authoritative.
      //
      // So: cut anyway and drop the unresolvable half. An outcome whose target is not
      // a declared state has no node to point at and cannot appear in the chart either
      // way; what it must not do is overwrite its neighbour's condition. Nothing is
      // lost that was previously drawn.
      //
      // The dropped span does fall through to the W-1 residue warning, and that is
      // asserted — but note that a W-1 on a dispatch-table chart currently reaches no
      // human: see the `confidence` note in index.mjs. The drop is defensible because
      // the alternative published a false label, not because the warning is loud.
      if (!r1 || !r2) {
        const orphan = r1 ? text2 : text1;
        if (!_isUnresolvableOutcome(orphan)) continue;
        const kept = r1
          ? { start: piece.start, end: cut.splitAt, _text: undefined }
          : { start: cut.splitAt + cut.sepLen, end: piece.end, _text: undefined };
        pieces.splice(pIdx, 1, kept);
        continue;
      }

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
    // Case-SENSITIVE: the token must match the declared name exactly. State names
    // are uppercase, so a lowercase token is ordinary English prose, not a
    // reference — and resolving it fabricates an edge. `aid-update-kb` gained a
    // false `REVIEW -> SCOPE` transition, conditioned "picks the doc back up -- it
    // is still in", purely because the word "scope" appeared in a parenthetical.
    //
    // Measured before changing: of 48 corpus edges, every one names its target in
    // exact case and ZERO depend on a case-insensitive match, so nothing real is
    // lost. task-026 reached the same conclusion independently in `extract-inline`
    // after a failing test — lowercase "run" was matching state `RUN` — which is
    // why the two extractors disagreed until now.
    if (state && state.name === m[0]) return state;
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
 * Build a whole-token RegExp for `name` using the AID token-boundary convention:
 * not immediately preceded or followed by `[A-Za-z0-9-]`.  This boundary spans
 * hyphenated names as one token (Q-AND-A, PAUSE-FOR-USER-ACTION) and prevents
 * embedded matches (APPROVAL-HALT never matches HALT, CONTINUE never matches
 * the word "continue" inside prose).
 *
 * This is the SINGLE canonical boundary implementation shared by every call
 * site that strips a resolved state name from clause text.  Having three
 * different boundary rules in the same module — `\b…\b`, a lookaround in
 * `_extractOptionalityMarker`, and a lookaround in `extract-dispatch.mjs` —
 * was the root cause of the "to to" doubling defect: `\b…\b` with the `i`
 * flag matched lowercase `continue` (prose) in addition to uppercase `CONTINUE`
 * (state reference), stripping both and leaving a doubled preposition.
 *
 * @param {string} name    Token to match (state name, keyword, etc.).
 * @param {string} [flags] Regex flags (default '').  Pass 'gi' for
 *                         case-insensitive matching (used by
 *                         _extractOptionalityMarker).
 * @returns {RegExp}
 */
function _tokenBoundaryRe(name, flags = '') {
  const escaped = name
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    .replace(/-/g, '\\-');
  return new RegExp(`(?<![A-Za-z0-9-])${escaped}(?![A-Za-z0-9-])`, flags);
}

/**
 * Extract the edge condition from a clause (rule 3): the text that remains
 * after removing `[State: X]` wrappers, arrows, advance-type keywords, the
 * target state name, standalone `State:` prefix, backtick spans, and routing
 * parentheticals.
 *
 * Returns null when nothing meaningful is left — including when the remaining
 * text is a recognised routing artifact (orphaned close-paren fragment,
 * trailing preposition, or subject-stripped conditional).  Non-null values are
 * capped at 80 code points using the shared truncator imported from model.mjs
 * — this module contains no second truncation implementation (AC-8).
 *
 * @param {string} clauseText   Raw clause text.
 * @param {string} targetName   Resolved state name (exact case, for removal).
 * @returns {string|null}
 */
function _extractCondition(clauseText, targetName) {
  let text = clauseText;

  // (1) Strip [State: X] wrappers → X
  text = text.replace(STATE_WRAPPER_RE, '$1');
  // (2) Strip arrow forms
  text = text.replace(ARROW_RE, ' ');
  // (3) Strip advance-type keywords
  text = text.replace(ADVANCE_KW_RE, ' ');

  // (4) Strip the resolved state name — CASE-SENSITIVE, shared boundary helper.
  //
  //     The old `\b${escaped}\b` with the `gi` flag stripped both the uppercase
  //     state reference AND any matching lowercase prose word.  For a CONTINUE
  //     state, this turned the routing clause "Re-run … to continue to
  //     [State: CONTINUE]" into "Re-run … to  to" — two bare prepositions where
  //     the author wrote one.  The shared _tokenBoundaryRe helper without `gi`
  //     strips only the exact-case state reference, leaving prose words intact.
  // Strip the target name only where it reads as a LABEL, not where it is part of a
  // sentence. A name at the start or end of the clause is the routing target being
  // named; a name with prose on both sides is a word in a sentence, and cutting it
  // out leaves a hole the surrounding grammar cannot close.
  //
  // `aid-discover` published the symptom: "otherwise chain toward APPROVAL once zero
  // Pending and grade >= minimum" became "otherwise chain toward once zero Pending
  // …" — "toward" dangling into "once". No amount of trailing cleanup fixes that,
  // because the damage is mid-string. Keeping the name costs only a small redundancy
  // (a condition mentioning its own target) and keeps the sentence true.
  text = text.replace(_tokenBoundaryRe(targetName), ' ');

  // Repair a preposition left dangling by that strip. When the state name sits
  // MID-SENTENCE — `aid-discover` writes "otherwise chain toward APPROVAL once zero
  // Pending" — removing it welds the words either side together and publishes
  // "chain toward once zero Pending". The trailing-preposition guard further down
  // cannot help, because the damage is in the middle of the string.
  //
  // Keeping the name instead was tried and is worse: it resurrects conditions that
  // are correctly null, taking the corpus from 37 labels to 60 and breaking four
  // tests. Dropping the orphaned preposition is the narrow repair — it removes a
  // word that is now pointing at nothing, and leaves every other clause untouched.
  text = text.replace(
    /\s(toward|towards|to|into|onto|through|via|at|on|in)\s+(?=(once|when|if|after|before|unless|until)\b)/gi,
    ' '
  );

  // (5) Strip standalone "State:" prefix artifacts
  text = text.replace(/\bState:\s*/g, ' ');
  // (6) Strip backtick spans (routing notation such as `[1] File it`)
  text = text.replace(/`[^`]*`/g, ' ');
  // (7) Strip markdown emphasis markers.  Removing a BOLDED keyword leaves its
  //     `**` delimiters behind; without this strip they reach the rendered page.
  text = text.replace(/\*+/g, ' ');

  // (8) Strip routing parentheticals — "(continue inline)", "(see …)", "(exit;
  //     no writeback)", etc.  Authors use these to annotate the transition path;
  //     they are never a real edge guard.  The close-paren is optional because
  //     _extractCondition's separator trim sometimes removes it first.
  text = text.replace(
    /\(\s*(?:continue|chain\s+continues?|see|exit|re-?run)\b[^)]*\)?/gi, ' '
  );
  // …and the SAME notation written as a trailing sentence rather than a
  // parenthetical. Four labels published "otherwise. Both continue inline" and
  // "if grade ≥ minimum. Both continue inline", because four reference files write
  // `Both continue inline.` outside brackets, where the rule above cannot see it.
  //
  // It is the same debris either way — a note about how control flows, presented to
  // a reader as the guard on a branch. Anchored to a sentence boundary so it only
  // takes a trailing clause, never text in the middle of a condition.
  text = text.replace(
    /(?:^|[.;])\s*(?:both\s+)?(?:continue|chain)s?\s+inline\b[^.;]*[.;]?\s*$/i, ''
  );

  // (9) Collapse whitespace and trim
  text = text.replace(/\s+/g, ' ').trim();

  // (10) Strip leading/trailing routing punctuation
  text = text.replace(/^[[\]().,;:!?→>-]+|[[\]().,;:!?→>-]+$/g, '').trim();

  // (11) Orphaned open-bracket guard.  Authors write asides like
  //      "(continue inline; state-apply.md § Step 1)", and stripping the state
  //      name or backtick spans out of the middle orphans the opening bracket.
  //      Run AFTER the punctuation strip — balanced parens are still balanced
  //      before it, so this check only fires on debris, not on real parentheticals.
  const opens  = (text.match(/\(/g) || []).length;
  const closes = (text.match(/\)/g) || []).length;
  if (opens > closes) {
    text = text.slice(0, text.lastIndexOf('(')).trim();
    text = text.replace(/[[\]().,;:!?→>-]+$/g, '').trim();
  }

  // (12) Fragment guard — orphaned CLOSE-bracket (more closes than opens).
  //      This signals a bad separator split that began inside a parenthetical,
  //      leaving a fragment like "upstream phase fix). Re-run …" or
  //      "no writeback). If user said …".  No real condition opens with a
  //      dangling close-paren.
  if (closes > opens) return null;

  // (13) Strip trailing routing-reference chains.  After backtick spans are
  //      removed, "— see" / "-- see" / ": see" at the end is a meaningless
  //      footnote, e.g. "… in delivery-001 — see `SKILL.md § Arguments`"
  //      becomes "… in delivery-001 — see" once the backtick span is gone.
  // Kept despite being shadowed on today's corpus. A reviewer found that the only
  // label reaching it is also caught by the subject-stripped-conditional guard
  // below, so removing this line changes nothing measurable — the same shape as the
  // dead R4 guard that was deleted.
  //
  // The difference, and the reason this one stays: that guard was unreachable by
  // CONSTRUCTION, because the caller re-applied the identical test. This one is
  // merely unreached by the CURRENT corpus. A trailing "— see" with no `if was`
  // prefix is ordinary authoring that nobody has written yet, and it would publish
  // a dangling footnote. Its own test below pins it, so it cannot rot unnoticed.
  text = text.replace(/\s*[—–\-:;]\s*see\s*$/i, '').trim();
  text = text.replace(/[[\]().,;:!?→>-]+$/g, '').trim();

  // (14) Trailing-preposition guard.  When the resolved state name was the
  //      object of a routing phrase such as "to continue to [State: CONTINUE]",
  //      stripping the state reference leaves a dangling preposition at the end.
  //      No corpus condition ends with a bare preposition, so returning null is
  //      safe and avoids a label like "Re-run … to continue to".
  if (/\b(?:to|in|at|by|for|from|of)\s*$/i.test(text)) return null;

  // (15) Subject-stripped conditional guard.  When a backtick span held the
  //      grammatical subject of an `if` clause (e.g. "`--cleanup-only` was set"),
  //      stripping backticks leaves "if was set …" — syntactically broken and
  //      never a meaningful condition.
  if (/^if\s+(?:was|were|is|are|has|have|had|does|do|did)\b/i.test(text)) return null;

  if (!text) return null;
  return truncate(text, 80);
}

/**
 * Extract the terminal handoff prose from a clause (rule 4): the text that
 * remains after removing advance-type keywords, arrow forms and stop phrases.
 * Returns null when nothing meaningful is left.
 *
 * Backtick spans are **unwrapped, not removed** — unlike in `_extractCondition`,
 * where a backticked span is routing notation. A handoff's whole job is to tell the
 * reader what to run next, and in this corpus that command is written as code:
 * `aid-describe`'s COMPLETION clause says *Run `/aid-define {work}` to decompose
 * approved requirements into features*. Deleting the span published "Run to decompose
 * approved requirements into features" — the same dangling-verb damage that edge
 * conditions were fixed for, and with the one piece of information the handoff exists
 * to carry removed. `aid-update-kb`'s ANALYZE ended on a bare "escalation to" for the
 * same reason.
 *
 * @param {string} clauseText
 * @returns {string|null}
 */
function _extractHandoff(clauseText) {
  let text = clauseText;
  text = text.replace(ADVANCE_KW_RE, ' ');
  text = text.replace(ARROW_RE, ' ');
  text = text.replace(/\bStop here\b/g, ' ');
  // Hyphen-aware boundary, matching the four other `halt` checks in this module. `\b`
  // treats a hyphen as a boundary, so `\bhalt\b` matched inside `halt-proof` and published
  // the engine's APPROVAL-HALT handoff as "the -proof fixture in feature-004's testing
  // strategy" — a word cut in half in text a reader sees. This was the last `\b` site left
  // when the state-name strip was fixed for exactly this reason.
  text = text.replace(/(?<![A-Za-z0-9-])halt(?![A-Za-z0-9-])/gi, ' ');
  text = text.replace(/`([^`]*)`/g, '$1');
  // Markdown emphasis markers are formatting, never part of a state name. Without
  // this, a bare `**PAUSE-FOR-USER-ACTION**` — which names no resume state — has its
  // keyword stripped and returns the literal `** **` instead of null, because `*` is
  // absent from the trailing-punctuation set below. That string is not internal: it
  // reaches the `.flow.json` sidecar and feature-005's provenance panel, so a reader
  // would see it.
  text = text.replace(/\*+/g, ' ');
  text = text.replace(/\s+/g, ' ').trim();
  text = text.replace(/^[[\]().,;:!?→>-]+|[[\]().,;:!?→>-]+$/g, '').trim();
  return text || null;
}

/**
 * Detect an optionality marker in a clause and return its verbatim text,
 * or null when no marker is present.
 *
 * Markers (feature-003 SPEC rule 6):
 *   `(optional)` / bare `optional`  → `'optional'`
 *   trailing `?` on the clause      → `'?'`
 *   `if <cond>` qualifier           → the full `if …` text
 *
 * @param {string} clauseText   Raw clause text.
 * @param {string} targetName   Resolved state name (stripped before scanning).
 * @returns {string|null}
 */
function _extractOptionalityMarker(clauseText, targetName) {
  let remaining = clauseText;
  // Use the shared boundary helper with 'gi' — optionality markers may
  // reference the state name in mixed case, unlike conditions (exact-case only).
  remaining = remaining.replace(_tokenBoundaryRe(targetName, 'gi'), ' ');
  remaining = remaining.replace(ARROW_RE, ' ');
  remaining = remaining.replace(ADVANCE_KW_RE, ' ');
  remaining = remaining.replace(/\s+/g, ' ').trim();

  // `(optional)` or bare `optional`
  if (/\boptional\b/i.test(remaining)) return 'optional';

  // Trailing `?` on the whole clause (before state-name stripping)
  if (clauseText.trim().endsWith('?')) return '?';

  // `if <cond>` qualifier (any `if …` remaining after other stripping)
  const ifMatch = remaining.match(/\bif\b\s+\S.*/i);
  if (ifMatch) return ifMatch[0].trim();

  return null;
}

/**
 * Compute the residue: the portion of `content` not covered by any accepted
 * clause span.  Each clause is located in the content left-to-right and its
 * character positions are marked; the unmarked characters form the residue.
 *
 * @param {string}   content
 * @param {string[]} clauses  Accepted clause strings (phase-2 output).
 * @returns {string}          Residue text, whitespace-collapsed and trimmed.
 */
function _computeResidue(content, clauses) {
  const covered = new Uint8Array(content.length);
  let searchFrom = 0;
  for (const clause of clauses) {
    const idx = content.indexOf(clause, searchFrom);
    if (idx !== -1) {
      covered.fill(1, idx, idx + clause.length);
      searchFrom = idx + clause.length;
    }
  }
  let residue = '';
  for (let i = 0; i < content.length; i++) {
    if (!covered[i]) residue += content[i];
  }
  return residue.replace(/\s+/g, ' ').trim();
}

/**
 * Return true if `text` contains a whole-token match for any declared state.
 * Used by the rule-10 W-1 pure-commentary check.
 *
 * @param {string} text
 * @param {Map}    stateByName
 * @returns {boolean}
 */
function _residueHasDeclaredState(text, stateByName) {
  TOKEN_RE.lastIndex = 0;
  let m;
  while ((m = TOKEN_RE.exec(text)) !== null) {
    // Case-SENSITIVE, consistently with target resolution and the V9 scan. Rule 10
    // calls residue "pure commentary" when it holds no declared-state token, and a
    // lowercase word IS commentary — treating it as a state name made ordinary
    // prose look like a dropped edge.
    const state = stateByName.get(m[0].toLowerCase());
    if (state && state.name === m[0]) return true;
  }
  return false;
}
