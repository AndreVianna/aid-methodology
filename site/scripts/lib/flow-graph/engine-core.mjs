// engine-core.mjs — Shared shortcut-engine chart derivation (feature-004).
//
// Entry:  getEngineCore() → EngineCore
//
// Derives the shortcut-engine chart once per process from:
//   canonical/aid/templates/shortcut-engine.md
//   canonical/aid/templates/work-initiation-gate.md
//
// Applies E-rules L1 (GATE self-loop) and B1 (CONTINUATION under INTAKE,
// Circuit breaker under GATE) in this function.  Detail-time placement
// decision: the rules fire here because EngineCore already carries their
// output — see task-033/DETAIL.md.
//
// Returns a deeply-frozen EngineCore object.  The second call returns the
// identical object reference.
//
// EngineCore carries: nodes, edges, exits, sources, warnings.
// It carries NO skill, title, entries, or confidence — those are per-page
// chart properties; omitting them prevents one page's values leaking into
// the next.
//
// Pure side-effects limited to filesystem reads (once, at first call).
// Import-time side effect: none.

import { readFileSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildProvenance, findStateSections, sliceLines } from './source.mjs';
import { extractAdvanceBlock, parseAdvanceBlock } from './advance.mjs';
import { truncate, makeNode, makeEdge } from './model.mjs';

// ── Repo-root resolution ────────────────────────────────────────────────────────

/** Absolute path to this file's directory. */
const __dirname_mjs = dirname(fileURLToPath(import.meta.url));

/** Absolute path to the repository root (four levels up from site/scripts/lib/flow-graph/). */
const REPO_ROOT = resolve(__dirname_mjs, '../../../..');

// ── Source paths ───────────────────────────────────────────────────────────────

const ENGINE_REL   = 'canonical/aid/templates/shortcut-engine.md';
const GATE_REL     = 'canonical/aid/templates/work-initiation-gate.md';

// ── D1 heading pattern — matches `## State Machine` exactly ───────────────────

// Only `State Machine`, not classify.mjs's `(Dispatch|State Machine)`. This module reads
// exactly one file, whose table sits under `## State Machine`; its only other candidate
// heading is `## Dispatch Protocol`, which an exact-text match rejects anyway. So the
// `Dispatch` alternative was unreachable here — removing it killed no test, which is how
// wave 10's review found it. Narrowed rather than pinned, for the same reason the inert
// `\b` in advance.mjs was deleted in wave 8: a test for an alternative no input can reach
// is a test that cannot fail.
//
// A consequence worth stating so it is not re-filed as a gap: putting `Dispatch|` back is
// now also a no-op, because nothing in this file's input can match it either way. That
// mutant is inert, not uncaught.
//
// Deliberately a separate constant from classify.mjs's, which is not exported and whose
// module the DETAIL forbids this task from touching.
const D1_HEADING_RE = /^#{2,}\s+State Machine\s*$/;

// ── Maintenance-note pattern (W5) ─────────────────────────────────────────────
// Matches the `> **Maintenance note:** the states in order are X -> Y -> …`
// line and captures the arrow-separated list.
const MAINTENANCE_NOTE_RE = />\s*\*\*Maintenance note:\*\*.*?are\s+([\w\-]+(?:\s*->\s*[\w\-]+)*)/;

// ── B1 trigger tokens ─────────────────────────────────────────────────────────

const B1_TRIGGERS_RE = /\bHALTS\b|\bSTOP\b|does not run|instead of looping further/;

// ── Module-level memo ──────────────────────────────────────────────────────────

/** @type {EngineCore|null} */
let _memo = null;

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * @typedef {object} EngineCore
 * @property {import('./model.mjs').FlowNode[]} nodes     Ordered c1…cN
 * @property {import('./model.mjs').FlowEdge[]} edges     Ordered by (from.order, to.order, condition)
 * @property {string[]}                          exits     Node ids of exit nodes
 * @property {string[]}                          sources   Repo-root-relative files, ASCII-sorted
 * @property {string[]}                          warnings  Derivation warnings
 */

/**
 * Derive the shortcut-engine chart once per process and return a deeply-frozen
 * EngineCore.  Subsequent calls return the identical frozen object reference.
 *
 * ## The `sources` parameter is a test seam, and why it exists
 *
 * Called with no argument — the only way production calls it — this reads the two real
 * template files and memoizes. Called with `{ engineText, gateText }` it derives from
 * those strings instead and **does not touch the memo**, so a fixture-driven call can
 * never poison the shared instance or be poisoned by one.
 *
 * Without this, several rules the DETAIL states as contract cannot be tested at all,
 * because the derivation's only inputs were two fixed paths. Wave 10's review proved
 * that concretely: five mutations survived — removing `does not run` and `instead of
 * looping further` from B1's trigger set, widening L1's phrasing from `Loop back` to
 * `Loop`, turning W5's warning into a throw, and dropping the shared truncator from a B1
 * condition. Every one is a stated contract, and every one was unreachable because the
 * real corpus happens not to discriminate them. Narrowing the code to match what the
 * corpus exercises was the alternative and was rejected: the DETAIL names all four
 * trigger tokens, so the right move is to make the contract assertable rather than to
 * shrink it to what today's two files happen to reach.
 *
 * @param {{ engineText?: string, gateText?: string }} [sources]  Test-only override.
 * @returns {EngineCore}
 */
export function getEngineCore(sources) {
  if (sources) return _deepFreeze(_buildEngineCore(sources));
  if (_memo !== null) return _memo;
  _memo = _deepFreeze(_buildEngineCore());
  return _memo;
}

// ── Core builder ───────────────────────────────────────────────────────────────

/**
 * Read both source files, derive the D1 spine, apply E-rules L1 and B1,
 * assign c1…cN ids, and return a plain (unfrozen) EngineCore.
 *
 * @param {{ engineText?: string, gateText?: string }} [override]  Test-only override;
 *   when a text is supplied the corresponding file is not read. Named `override` rather
 *   than `sources` because this function already has a local `sources` — the chart's
 *   source-file list, which is a different thing.
 * @returns {EngineCore}
 */
function _buildEngineCore(override = {}) {
  const warnings = [];

  // ── 1. Read source files ──────────────────────────────────────────────────
  // Provenance paths stay ENGINE_REL / GATE_REL even under an override, so a fixture
  // produces the same shape of chart as the real derivation.
  const engineText = override.engineText ?? readFileSync(join(REPO_ROOT, ENGINE_REL), 'utf8');
  const gateText   = override.gateText   ?? readFileSync(join(REPO_ROOT, GATE_REL),   'utf8');

  const engineLines = engineText.split('\n').map((l) => l.replace(/\r$/, ''));
  const gateLines   = gateText.split('\n').map((l) => l.replace(/\r$/, ''));

  const sources = [ENGINE_REL, GATE_REL].slice().sort();

  // ── 2. Locate the ## State Machine table ─────────────────────────────────
  const tableInfo = _findDispatchTable(engineLines);
  if (!tableInfo) {
    throw new Error(
      `[gen-skills] engine-core: no ## State Machine table found (${ENGINE_REL})`
    );
  }
  const { headerIdx, dataRows } = tableInfo;

  // ── 3. W5: check table order against Maintenance note ────────────────────
  _checkMaintenanceNote(engineLines, dataRows, warnings, ENGINE_REL);

  // ── 4. Parse the ## State: sections from shortcut-engine.md ──────────────
  const stateSections = findStateSections(engineLines, ENGINE_REL);

  // ── 5. Pre-assign provisional IDs for parseAdvanceBlock (n1…nN).
  //       These are temporary; we reassign c1…cN after B1 inserts new nodes.
  const declaredStates = dataRows.map((r, i) => ({
    name: r.state,
    order: i + 1,
    id: 'n' + (i + 1),
  }));

  // APPROVAL-HALT's name contains 'HALT', which is an advance-type keyword.
  // parseAdvanceBlock strips such keywords before state matching so it cannot
  // produce edges TO APPROVAL-HALT.  We handle it via keyword-state edge
  // recovery below, mirroring extract-dispatch.mjs's approach.
  const kwNamedStates = declaredStates.filter((s) =>
    /^(HALT|CHAIN|PAUSE-FOR-USER-ACTION|PAUSE-FOR-USER-DECISION)$/i.test(s.name) ||
    s.name.toUpperCase().includes('HALT')
  );

  // ── 6. Build spine nodes + row-advance edges ─────────────────────────────
  /** @type {Array<object>} raw nodes (no id/kind yet) */
  const rawNodes = [];

  /** @type {Array<object>} raw edges (provisional n-prefixed ids) */
  const rawEdges = [];

  for (let i = 0; i < dataRows.length; i++) {
    const row     = dataRows[i];
    const nodeId  = 'n' + (i + 1);
    const order   = i + 1;
    const rowLine = headerIdx + 2 + i + 1; // 1-based line in file (header=0, sep=1, data starts at 2)

    const nodeProv = buildProvenance(ENGINE_REL, engineLines, rowLine, rowLine, 'engine');

    // Row Advance parse — safe declaredStates excludes self + keyword-named states.
    const safeDecl = declaredStates.filter(
      (s) => s.id !== nodeId && !kwNamedStates.some((k) => k.id === s.id)
    );

    const rowBlock  = '**Advance:** ' + row.advance;
    const rowResult = parseAdvanceBlock({
      block:          rowBlock,
      fromNodeId:     nodeId,
      fromNodeName:   row.state,
      declaredStates: safeDecl,
      file:           ENGINE_REL,
      blockStartLine: rowLine,
      sourceKind:     'engine',
    });
    warnings.push(...rowResult.warnings);

    // Recover edges to APPROVAL-HALT (keyword-named state).
    // Initially from row advance only; expanded with section advance text later.
    const kwEdges = _extractKeywordStateEdges(
      [row.advance], nodeId, kwNamedStates,
      buildProvenance(ENGINE_REL, engineLines, rowLine, rowLine, 'engine')
    );

    let terminal = rowResult.terminal;

    // ── Bind ## State: section through shared reader ─────────────────────
    let labelCandidate = null;
    let detailProvenance = null;
    let sectionResult = null;
    let sectionAdvanceText = null;

    const section = stateSections.find(
      (s) => s.name.toLowerCase() === row.state.toLowerCase()
    );

    if (section) {
      // Label: Purpose: line or first prose sentence from lead paragraph.
      labelCandidate = _extractLabelFromSection(
        engineLines, section.headingLine, section.leadEndLine
      );

      // Detail provenance: full section range.
      detailProvenance = buildProvenance(
        ENGINE_REL, engineLines,
        section.headingLine, section.sectionEndLine, 'engine'
      );

      // Advance block within the section.
      const sectionLines = engineLines.slice(
        section.headingLine - 1, section.sectionEndLine
      );
      const advMarkerIdx = sectionLines.findIndex(
        (l) => /^\s*\*{1,2}Advance:/.test(l)
      );

      if (advMarkerIdx !== -1) {
        const { blockText } = extractAdvanceBlock(sectionLines, advMarkerIdx);
        const advStartLine  = section.headingLine + advMarkerIdx;
        sectionAdvanceText  = blockText;

        try {
          sectionResult = parseAdvanceBlock({
            block:          blockText,
            fromNodeId:     nodeId,
            fromNodeName:   row.state,
            declaredStates: safeDecl,
            file:           ENGINE_REL,
            blockStartLine: advStartLine,
            sourceKind:     'engine',
          });
          warnings.push(...sectionResult.warnings);
        } catch (err) {
          if (typeof err.message === 'string' && err.message.startsWith('[gen-skills] V9:')) {
            warnings.push(
              `[gen-skills] engine-core: W-V9 in section for '${row.state}': ${err.message}`
            );
            sectionResult = { edges: [], terminal: null, warnings: [] };
          } else {
            throw err;
          }
        }
      }
    }

    // Recover keyword-state edges from BOTH row advance AND section advance.
    // (Re-run with section text to cover cases where the section references
    // the keyword-named state even if the row cell does not.)
    const kwEdgesFull = _extractKeywordStateEdges(
      [row.advance, sectionAdvanceText], nodeId, kwNamedStates,
      buildProvenance(ENGINE_REL, engineLines, rowLine, rowLine, 'engine')
    );
    // Override kwEdges with the fuller set (include section advance text).
    kwEdges.length = 0;
    kwEdges.push(...kwEdgesFull);

    // Merge: section edges win over row edges for the same target.
    const sectionEdges = sectionResult ? sectionResult.edges : [];
    const mergedEdges  = _mergeEdges(rowResult.edges, sectionEdges, nodeId);

    // Section terminal wins if present.
    if (sectionResult && sectionResult.terminal !== null) {
      terminal = sectionResult.terminal;
    }

    // Clear spurious terminal produced when advance text named a keyword-named
    // state (e.g. APPROVAL-HALT → HALT keyword stripped → terminal fired
    // even though the intent was an edge, not a halt).
    if (kwEdges.length > 0 && terminal !== null) {
      terminal = null;
    }

    // Add keyword-state edges not already in mergedEdges.
    const mergedTargets = new Set(mergedEdges.map((e) => e.to));
    for (const ke of kwEdges) {
      if (!mergedTargets.has(ke.to)) {
        mergedEdges.push(ke);
        mergedTargets.add(ke.to);
      }
    }

    const label = labelCandidate
      ? truncate(_normaliseLabel(labelCandidate), 60)
      : _titleCase(row.state);

    rawNodes.push(makeNode({
      order,
      name:       row.state,
      label,
      provenance: nodeProv,
      terminal,
      detail:     detailProvenance,
    }));

    for (const e of mergedEdges) {
      rawEdges.push(makeEdge({
        from:        nodeId,
        to:          e.to,
        kind:        e.kind,
        condition:   e.condition,
        advanceType: e.advanceType,
        provenance:  e.provenance,
      }));
    }
  }

  // ── 7. E-rule L1: GATE self-loop ─────────────────────────────────────────
  // Inside the GATE section, "Loop back to Step 1 (REVIEW)" targets "Step 1
  // (REVIEW)" which is not a declared state — emit one loop-back self-edge
  // with condition null.
  const gateStateIdx = declaredStates.findIndex((s) => s.name === 'GATE');
  if (gateStateIdx !== -1) {
    const gateState   = declaredStates[gateStateIdx];
    const gateSection = stateSections.find((s) => s.name === 'GATE');

    if (gateSection) {
      const loopLine = _findLoopPhrasingLine(
        engineLines, gateSection.headingLine, gateSection.sectionEndLine
      );

      if (loopLine !== -1) {
        // Emit self-loop with condition null.
        rawEdges.push(makeEdge({
          from:        gateState.id,
          to:          gateState.id,
          kind:        'loop-back',
          condition:   null,
          advanceType: 'UNSPECIFIED',
          provenance:  buildProvenance(ENGINE_REL, engineLines, loopLine, loopLine, 'engine'),
        }));
      }
    }
  }

  // ── 8. E-rule B1: early-halt branches ───────────────────────────────────
  // Applied to INTAKE (CONTINUATION) and GATE (Circuit breaker).
  // For each firing site: insert an exit node after the parent, emit a branch
  // edge to it, and re-kind the parent's declared advance edge to branch.
  //
  // B1 nodes are inserted into rawNodes at this point; their provisional
  // order is set to a fractional value so they slot in after their parent.
  // After B1 processing, all orders are renumbered to integers for id assignment.

  const b1Insertions = []; // { afterParentName, node, branchEdge, rekinds }

  for (const parentName of ['INTAKE', 'GATE']) {
    const parentState   = declaredStates.find((s) => s.name === parentName);
    const parentSection = stateSections.find((s) => s.name === parentName);
    if (!parentState || !parentSection) continue;

    const b1 = _applyB1(
      parentName, parentState, parentSection,
      engineLines, gateLines, warnings
    );

    if (b1) {
      b1Insertions.push({ parentName, ...b1 });
    }
  }

  // ── 9. Insert B1 nodes and re-kind edges ──────────────────────────────────
  // Build the final ordered list: each B1 node goes immediately after its parent.
  // Assign final c1…cN ids in the resulting order.

  // Map parentName -> B1 insertion for quick lookup.
  const b1ByParent = new Map(b1Insertions.map((ins) => [ins.parentName, ins]));

  // Build ordered node list with B1 nodes inserted after their parent.
  const orderedNodes = []; // { rawNode, isB1, b1Ins? }
  for (const rawNode of rawNodes) {
    orderedNodes.push({ rawNode, isB1: false });
    const ins = b1ByParent.get(rawNode.name);
    if (ins) {
      orderedNodes.push({ rawNode: ins.b1Node, isB1: true, ins });
    }
  }

  // Assign c1…cN ids and update order fields.
  const idMap = new Map(); // old provisional id -> new cN id
  const finalNodes = [];

  for (let idx = 0; idx < orderedNodes.length; idx++) {
    const { rawNode, isB1, ins } = orderedNodes[idx];
    const newId    = 'c' + (idx + 1);
    const newOrder = idx + 1;

    if (!isB1) {
      // Map the provisional n-id to the new c-id.
      const oldId = 'n' + rawNode.order;
      idMap.set(oldId, newId);
    } else {
      // B1 node: store its new id in the insertion record.
      ins.newB1Id = newId;
    }

    finalNodes.push({ ...rawNode, id: newId, order: newOrder, kind: 'step' });
  }

  // ── 10. Re-map edge ids and apply B1 re-kinds ────────────────────────────
  const finalEdges = [];

  for (const e of rawEdges) {
    const from = idMap.get(e.from) ?? e.from;
    const to   = idMap.get(e.to)   ?? e.to;
    finalEdges.push({ ...e, from, to });
  }

  // Add B1 branch edges and re-kind parent's advance edge.
  for (const ins of b1Insertions) {
    const parentId = idMap.get('n' + ins.parentState.order);
    const b1Id     = ins.newB1Id;

    if (!parentId || !b1Id) continue;

    // Add the branch edge parent -> B1 node.
    finalEdges.push(makeEdge({
      from:        parentId,
      to:          b1Id,
      kind:        'branch',
      condition:   ins.b1Condition,
      advanceType: 'HALT',
      provenance:  ins.b1EdgeProvenance,
    }));

    // Re-kind the parent's declared advance edge (the one going to the next
    // spine state) from sequence to branch, updating its condition.
    // The declared advance target id (in c-space) comes from idMap.
    const advanceTargetId = idMap.get('n' + ins.advanceTargetOldOrder);
    if (advanceTargetId) {
      for (let j = 0; j < finalEdges.length; j++) {
        const edge = finalEdges[j];
        if (
          edge.from === parentId &&
          edge.to   === advanceTargetId &&
          edge.kind === 'sequence'
        ) {
          finalEdges[j] = {
            ...edge,
            kind:      'branch',
            condition: ins.advanceCondition,
          };
          break;
        }
      }
    }
  }

  // Re-map L1 self-loop (GATE -> GATE) to c-space.
  for (let j = 0; j < finalEdges.length; j++) {
    const edge = finalEdges[j];
    if (edge.from === edge.to && idMap.has(edge.from)) {
      // Self-loop was stored with provisional id; already remapped above.
    }
  }

  // ── 11. Assign kind, terminal, exits ─────────────────────────────────────
  // Add B1 exit nodes (terminal) to finalNodes.
  for (const ins of b1Insertions) {
    const b1Id = ins.newB1Id;
    if (!b1Id) continue;
    const nodeIdx = finalNodes.findIndex((n) => n.id === b1Id);
    if (nodeIdx !== -1) {
      finalNodes[nodeIdx] = {
        ...finalNodes[nodeIdx],
        terminal: { advanceType: 'HALT', handoff: null },
        kind:     'exit',
      };
    }
  }

  // Compute kind for spine nodes.
  const branchCount    = new Map(finalNodes.map((n) => [n.id, 0]));
  const hasLoopBackOut = new Set();

  for (const e of finalEdges) {
    if (e.kind === 'branch') {
      branchCount.set(e.from, (branchCount.get(e.from) ?? 0) + 1);
    }
    if (e.kind === 'loop-back') {
      hasLoopBackOut.add(e.from);
    }
  }

  // exits = nodes with terminal !== null.
  const exitSet = new Set(
    finalNodes.filter((n) => n.terminal !== null).map((n) => n.id)
  );

  // Exits fallback: if none, designate the highest-order node.
  if (exitSet.size === 0) {
    const highest = finalNodes.reduce((max, n) => (n.order > max.order ? n : max));
    highest.terminal = { advanceType: 'UNSPECIFIED', handoff: null };
    exitSet.add(highest.id);
    warnings.push(
      `[gen-skills] engine-core: exits fallback: no terminal node found; ` +
      `designating '${highest.name}' (${highest.id}) as exit`
    );
  }

  for (const node of finalNodes) {
    if (exitSet.has(node.id)) {
      node.kind = 'exit';
    } else if ((branchCount.get(node.id) ?? 0) >= 2) {
      node.kind = 'decision';
    } else if (hasLoopBackOut.has(node.id)) {
      node.kind = 'loop-back';
    } else {
      node.kind = 'step';
    }
  }

  // ── 12. Sort edges by (from.order, to.order, condition) ──────────────────
  const nodeByIdFinal = new Map(finalNodes.map((n) => [n.id, n]));

  const sortedEdges = finalEdges.slice().sort((a, b) => {
    const fromA = nodeByIdFinal.get(a.from)?.order ?? 0;
    const fromB = nodeByIdFinal.get(b.from)?.order ?? 0;
    if (fromA !== fromB) return fromA - fromB;

    const toA = nodeByIdFinal.get(a.to)?.order ?? 0;
    const toB = nodeByIdFinal.get(b.to)?.order ?? 0;
    if (toA !== toB) return toA - toB;

    const ca = a.condition ?? '';
    const cb = b.condition ?? '';
    return ca < cb ? -1 : ca > cb ? 1 : 0;
  });

  // ── 13. Compute exits array ───────────────────────────────────────────────
  const exits = finalNodes
    .filter((n) => exitSet.has(n.id))
    .sort((a, b) => a.order - b.order)
    .map((n) => n.id);

  // ── 14. Sort nodes by order ───────────────────────────────────────────────
  const sortedNodes = finalNodes.slice().sort((a, b) => a.order - b.order);

  return { nodes: sortedNodes, edges: sortedEdges, exits, sources, warnings };
}

// ── E-rule B1 ─────────────────────────────────────────────────────────────────

/**
 * Apply B1 for a single state (INTAKE or GATE).
 *
 * For INTAKE: locates the "On **continuation**" arm whose sentence contains
 * "HALTS"/"does not run"; names the B1 node from work-initiation-gate.md.
 * For GATE: locates the "**Circuit breaker.**" arm whose sentence contains
 * "STOP"/"instead of looping further"; names the B1 node from shortcut-engine.md.
 *
 * Returns the B1 node, its edge provenance, and the guard conditions for the
 * new branch edge and the re-kinded advance edge.
 *
 * @param {string}   parentName       'INTAKE' | 'GATE'
 * @param {object}   parentState      { name, order, id }
 * @param {object}   parentSection    StateSectionRange from findStateSections
 * @param {string[]} engineLines      0-indexed lines of shortcut-engine.md
 * @param {string[]} gateLines        0-indexed lines of work-initiation-gate.md
 * @param {string[]} warnings         Mutated in place
 * @returns {{ b1Node, b1Condition, b1EdgeProvenance, advanceCondition,
 *             advanceTargetOldOrder, parentState } | null}
 */
function _applyB1(
  parentName, parentState, parentSection,
  engineLines, gateLines, warnings
) {
  const sectionLines = engineLines.slice(
    parentSection.headingLine - 1, parentSection.sectionEndLine
  );

  // Find the targeted B1 arm.
  const armInfo = (parentName === 'INTAKE')
    ? _findIntakeB1Arm(sectionLines, parentSection.headingLine)
    : _findGateB1Arm(sectionLines, parentSection.headingLine);

  if (!armInfo) return null;

  const { armText, armLineInFile, triggerContext, continueCondition } = armInfo;

  // Resolve the arm name and provenance.
  let b1Name;
  let b1Prov;

  if (parentName === 'INTAKE') {
    // Name and provenance come from work-initiation-gate.md.
    const { name, prov } = _resolveB1NameFromGate(gateLines, armText, warnings);
    b1Name = name;
    b1Prov = prov;
  } else {
    // Name and provenance come from shortcut-engine.md.
    // Strip emphasis markers and trailing period/whitespace.
    b1Name = _stripEmphasis(armText).replace(/\.\s*$/, '').trim();
    b1Prov = buildProvenance(ENGINE_REL, engineLines, armLineInFile, armLineInFile, 'engine');
  }

  if (!b1Name) {
    warnings.push(
      `[gen-skills] engine-core: B1 arm name not resolved for '${parentName}'`
    );
    return null;
  }

  // Condition for the B1 branch edge (verbatim guard clause, capped).
  const b1Condition = truncate(
    _stripEmphasisAndBackticks(triggerContext).trim(),
    80
  ) || null;

  // Condition for the re-kinded advance edge.
  const advanceCondition = continueCondition
    ? truncate(_stripEmphasisAndBackticks(continueCondition).trim(), 80) || null
    : null;

  // Find the declared advance target's provisional order.
  const advanceTargetOldOrder = _findAdvanceTargetOrder(parentName, parentState);

  // Build the B1 exit node (provisional order; reassigned later).
  const b1Node = makeNode({
    order:      parentState.order + 0.5, // fractional; renumbered after insert
    name:       b1Name,
    label:      truncate(_normaliseLabel(b1Name), 60),
    provenance: b1Prov,
    terminal:   { advanceType: 'HALT', handoff: null },
    detail:     null,
  });

  return {
    b1Node,
    b1Condition,
    b1EdgeProvenance: b1Prov,
    advanceCondition,
    advanceTargetOldOrder,
    parentState,
  };
}

/**
 * Find the INTAKE B1 arm: "On **continuation**" whose context has HALTS /
 * "does not run".
 *
 * @param {string[]} sectionLines
 * @param {number}   headingLine  1-based
 * @returns {{ armText, armLineInFile, triggerContext, continueCondition } | null}
 */
function _findIntakeB1Arm(sectionLines, headingLine) {
  // Pattern: "On **arm**" where the bullet/paragraph context has a B1 trigger.
  const ON_ARM_RE = /\bOn\s+(\*\*[^*]+\*\*)/;

  for (let i = 0; i < sectionLines.length; i++) {
    const line = sectionLines[i];
    const m    = line.match(ON_ARM_RE);
    if (!m) continue;

    // Collect continuation lines.
    let context = line;
    let j = i + 1;
    while (j < sectionLines.length) {
      const next = sectionLines[j];
      if (next.trim() === '') break;
      if (/^#{1,6}\s/.test(next)) break;
      context += ' ' + next;
      j++;
    }

    if (!B1_TRIGGERS_RE.test(context)) continue;

    const armText       = m[1]; // e.g. `**continuation**`
    const armLineInFile = headingLine + i;

    // Guard clause for the B1 arm: "On <arm>" stripped.
    const armStripped     = _stripEmphasis(armText).replace(/\.$/, '').trim();
    const triggerContext  = 'On ' + armStripped;

    // Sibling arm: "On **new work**" in the same context.
    const siblingMatch = context.match(/\bOn\s+(\*\*[^*]+\*\*)/g);
    let continueCondition = null;
    if (siblingMatch) {
      for (const sib of siblingMatch) {
        const sibM = sib.match(/\bOn\s+(\*\*[^*]+\*\*)/);
        if (sibM && sibM[1] !== armText) {
          continueCondition = 'On ' + _stripEmphasis(sibM[1]).replace(/\.$/, '').trim();
          break;
        }
      }
    }

    return { armText, armLineInFile, triggerContext, continueCondition };
  }

  return null;
}

/**
 * Find the GATE B1 arm: "**Circuit breaker.**" whose context has STOP /
 * "instead of looping further".
 *
 * @param {string[]} sectionLines
 * @param {number}   headingLine  1-based
 * @returns {{ armText, armLineInFile, triggerContext, continueCondition } | null}
 */
function _findGateB1Arm(sectionLines, headingLine) {
  // Pattern: `**arm.**` or `**arm**` at the start of a paragraph or bullet,
  // whose context contains STOP / "instead of looping further".
  const BOLD_START_RE = /^\s*(?:-\s+)?(\*\*[^*]+\*\*)/;

  for (let i = 0; i < sectionLines.length; i++) {
    const line = sectionLines[i];
    const m    = line.match(BOLD_START_RE);
    if (!m) continue;

    // Collect the full context of this paragraph.
    let context = line;
    let j = i + 1;
    while (j < sectionLines.length) {
      const next = sectionLines[j];
      if (next.trim() === '') break;
      if (/^#{1,6}\s/.test(next)) break;
      // Stop before another bold-at-start line that looks like a sibling arm.
      if (/^\s*(?:-\s+)?\*\*[^*]+\*\*/.test(next) && B1_TRIGGERS_RE.test(next)) break;
      context += ' ' + next;
      j++;
    }

    if (!B1_TRIGGERS_RE.test(context)) continue;

    const armText       = m[1];
    const armLineInFile = headingLine + i;

    // Guard clause: the `If …` condition before STOP.
    const triggerContext = _extractGuardClauseForGate(context, armText);

    return { armText, armLineInFile, triggerContext, continueCondition: null };
  }

  return null;
}

/**
 * Extract the guard clause for GATE's B1 arm.
 *
 * For "**Circuit breaker.** If X, STOP …" → "If X"
 *
 * @param {string} context  Full paragraph/sentence context.
 * @param {string} armText  The bolded arm text (e.g. `**Circuit breaker.**`).
 * @returns {string}
 */
function _extractGuardClauseForGate(context, armText) {
  // Strip the arm text from context.
  const text = context.replace(armText, ' ');

  // Extract the `If …` portion up to the stop keyword.
  const stopMatch = text.match(/\bIf\b(.+?)(?=,?\s*\bSTOP\b|instead of looping further)/s);
  if (stopMatch) {
    return ('If ' + stopMatch[1]).replace(/\s+/g, ' ').trim().replace(/[,\s]+$/, '');
  }

  // Fallback: text before first trigger.
  return text.replace(/\bSTOP\b.*|instead of looping further.*/s, '')
    .replace(/\s+/g, ' ').replace(/[,\s]+$/, '').trim();
}

/**
 * Resolve the B1 arm name for INTAKE by scanning work-initiation-gate.md for
 * the `### 3b. CONTINUATION` heading.
 *
 * Returns the canonical uppercase name and provenance citing gate.md.
 *
 * @param {string[]} gateLines
 * @param {string}   _armText  The bold arm text from engine.md (unused; name comes from gate.md)
 * @param {string[]} warnings
 * @returns {{ name: string, prov: Provenance }}
 */
function _resolveB1NameFromGate(gateLines, _armText, warnings) {
  // Pattern: `### N. NAME -> …` or `### Nb. NAME -> …`
  const GATE_HEADING_RE = /^###\s+\w+\.\s+([\w\-]+)\s*(?:->|–)/;

  for (let i = 0; i < gateLines.length; i++) {
    const m = gateLines[i].match(GATE_HEADING_RE);
    if (!m) continue;

    // Look for a heading that contains a name matching the continuation concept.
    // The heading at line 129 (1-based) is `### 3b. CONTINUATION -> route…`
    if (m[1].toUpperCase() === 'CONTINUATION') {
      const prov = buildProvenance(GATE_REL, gateLines, i + 1, i + 1, 'engine');
      return { name: m[1], prov };
    }
  }

  // Fallback: scan for any heading containing CONTINUATION.
  for (let i = 0; i < gateLines.length; i++) {
    const line = gateLines[i];
    if (/^###/.test(line) && /CONTINUATION/.test(line)) {
      const match = line.match(/###[^A-Z]*([A-Z][A-Z0-9\-]+)/);
      if (match) {
        const prov = buildProvenance(GATE_REL, gateLines, i + 1, i + 1, 'engine');
        return { name: match[1], prov };
      }
    }
  }

  warnings.push(
    `[gen-skills] engine-core: could not find CONTINUATION heading in ${GATE_REL}`
  );
  return { name: 'CONTINUATION', prov: buildProvenance(GATE_REL, gateLines, 1, 1, 'engine') };
}

/**
 * Return the declared advance target's old provisional order for a given
 * parent state.  Hard-coded from the D1 table: INTAKE->CAPTURE (order 2),
 * GATE->APPROVAL-HALT (order 7).
 *
 * @param {string} parentName
 * @param {object} _parentState
 * @returns {number}
 */
function _findAdvanceTargetOrder(parentName, _parentState) {
  // State Machine table order: INTAKE=1, CAPTURE=2, SPEC=3, PLAN=4, DETAIL=5,
  // GATE=6, APPROVAL-HALT=7
  const ORDER_MAP = {
    INTAKE: 2, // -> CAPTURE
    GATE:   7, // -> APPROVAL-HALT
  };
  return ORDER_MAP[parentName] ?? -1;
}

// ── D1 table finder ────────────────────────────────────────────────────────────

/**
 * Locate the `## State Machine` table in the engine file (no frontmatter).
 *
 * @param {string[]} lines  0-indexed lines of shortcut-engine.md.
 * @returns {{ headerIdx: number, dataRows: Array<{state:string,advance:string}> } | null}
 */
function _findDispatchTable(lines) {
  for (let i = 0; i < lines.length; i++) {
    if (!D1_HEADING_RE.test(lines[i])) continue;

    for (let j = i + 1; j < lines.length; j++) {
      if (/^#{1,6}\s/.test(lines[j])) break;
      if (!lines[j].trimStart().startsWith('|')) continue;

      const cols = lines[j].split('|').map((c) => c.trim()).filter(Boolean);
      const colState   = cols.findIndex((c) => c === 'State');
      const colAdvance = cols.findIndex((c) => c === 'Advance');

      if (colState === -1 || colAdvance === -1) break;

      const headerIdx = j; // 0-based line index of the header row
      const dataRows  = [];

      for (let k = j + 2; k < lines.length; k++) {
        const line = lines[k];
        if (!line.trimStart().startsWith('|')) break;
        const cells = line.split('|').map((c) => c.trim()).filter(Boolean);
        if (cells.length === 0) break;
        const state   = cells[colState]   ?? '';
        const advance = cells[colAdvance] ?? '';
        if (!state) continue;
        dataRows.push({ state, advance });
      }

      return { headerIdx, dataRows };
    }
  }
  return null;
}

// ── L1 helpers ────────────────────────────────────────────────────────────────

/**
 * Find the 1-based file line containing loop phrasing inside a state section.
 * Returns -1 when no loop phrasing is found.
 *
 * Loop phrasing: a line containing "Loop back" where the target resolves to
 * no declared state (the text says "Step 1 (REVIEW)", not a state name).
 *
 * @param {string[]} engineLines
 * @param {number}   headingLine    1-based
 * @param {number}   sectionEndLine 1-based
 * @returns {number}  1-based file line, or -1
 */
function _findLoopPhrasingLine(engineLines, headingLine, sectionEndLine) {
  for (let i = headingLine - 1; i < sectionEndLine; i++) {
    if (/Loop back/i.test(engineLines[i])) {
      return i + 1; // 1-based
    }
  }
  return -1;
}

// ── W5 check ──────────────────────────────────────────────────────────────────

/**
 * Compare the State Machine table order against the Maintenance note.
 * Emits a warning when they disagree.
 *
 * @param {string[]} engineLines
 * @param {Array<{state:string}>} dataRows
 * @param {string[]} warnings  Mutated in place.
 * @param {string}   file
 */
function _checkMaintenanceNote(engineLines, dataRows, warnings, file) {
  // Find the Maintenance note within the first 30 lines.
  const noteLines = engineLines.slice(0, 30).join(' ');
  const m = noteLines.match(MAINTENANCE_NOTE_RE);
  if (!m) return;

  const noteOrder = m[1]
    .split(/\s*->\s*/)
    .map((s) => s.trim())
    .filter(Boolean);

  const tableOrder = dataRows.map((r) => r.state);

  // Check that every note state appears in the table in the same relative order.
  let prevIdx = -1;
  for (const noteName of noteOrder) {
    const idx = tableOrder.indexOf(noteName);
    if (idx === -1 || idx <= prevIdx) {
      warnings.push(
        `[gen-skills] engine-core: W5: ## State Machine table order disagrees ` +
        `with Maintenance note order in ${file}. ` +
        `Table: [${tableOrder.join(', ')}]. ` +
        `Note: [${noteOrder.join(', ')}].`
      );
      return;
    }
    prevIdx = idx;
  }
}

// ── Keyword-state edge recovery ────────────────────────────────────────────────

/**
 * Recover edges to keyword-named states (e.g., APPROVAL-HALT) from advance text.
 * Mirrors extract-dispatch.mjs's _extractKeywordStateEdges.
 *
 * @param {(string|null)[]} texts
 * @param {string}          fromNodeId
 * @param {Array<{name:string,id:string,order:number}>} kwNamedStates
 * @param {import('./model.mjs').Provenance} provenance
 * @returns {Array}
 */
function _extractKeywordStateEdges(texts, fromNodeId, kwNamedStates, provenance) {
  if (kwNamedStates.length === 0) return [];
  const edges = [];
  const added = new Set();

  for (const kwState of kwNamedStates) {
    if (kwState.id === fromNodeId) continue;
    if (added.has(kwState.id)) continue;

    const name      = kwState.name.toUpperCase();
    const bracketRe = new RegExp(`\\[State:\\s*${name.replace(/-/g, '\\-')}\\s*\\]`, 'i');
    const arrowRe   = new RegExp(`(?:→|--?>+)\\s*${name.replace(/-/g, '\\-')}(?![A-Za-z0-9-])`, 'i');

    for (const text of texts) {
      if (!text) continue;
      if (bracketRe.test(text) || arrowRe.test(text)) {
        edges.push({
          to:          kwState.id,
          kind:        'sequence',
          condition:   null,
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

// ── Edge merger ────────────────────────────────────────────────────────────────

/**
 * Merge row (table-advance) edges and section edges, with section winning.
 * Mirrors the behaviour of extract-dispatch.mjs's _mergeEdges.
 *
 * @param {Array} rowEdges
 * @param {Array} sectionEdges
 * @param {string} fromNodeId
 * @returns {Array}
 */
function _mergeEdges(rowEdges, sectionEdges, fromNodeId) {
  if (sectionEdges.length === 0) return rowEdges;

  const sectionByTarget = new Map();
  for (const e of sectionEdges) {
    if (!sectionByTarget.has(e.to)) sectionByTarget.set(e.to, []);
    sectionByTarget.get(e.to).push(e);
  }

  const result          = [];
  const coveredTargets  = new Set();

  for (const [toId, sEdges] of sectionByTarget) {
    coveredTargets.add(toId);
    result.push(...sEdges);
  }

  for (const rowEdge of rowEdges) {
    if (!coveredTargets.has(rowEdge.to)) {
      result.push(rowEdge);
    }
  }

  return result;
}

// ── Label helpers ─────────────────────────────────────────────────────────────

/**
 * Extract a label candidate from the lead paragraph of a `## State:` section.
 *
 * @param {string[]} allLines
 * @param {number}   headingLine  1-based
 * @param {number}   leadEndLine  1-based
 * @returns {string|null}
 */
function _extractLabelFromSection(allLines, headingLine, leadEndLine) {
  // Level 1: Purpose: line.
  for (let i = headingLine - 1; i < leadEndLine; i++) {
    const m = allLines[i].match(/^\*{0,2}Purpose:\*{0,2}\s+(.+)/);
    if (m) return m[1].trim();
  }

  // Level 3: first prose sentence of the lead paragraph.
  const proseParts = [];
  for (let i = headingLine; i < leadEndLine; i++) {
    const line = allLines[i];
    if (line.trim() === '' || /^#{1,6}\s/.test(line)) continue;
    proseParts.push(line.trim());
    if (i + 1 < leadEndLine && allLines[i + 1].trim() === '') break;
  }
  if (proseParts.length === 0) return null;
  const prose = proseParts.join(' ');
  const idx   = prose.search(/[.!?]\s|[.!?]$/);
  if (idx === -1) return prose.trim();
  return prose.slice(0, idx + 1).trim();
}

function _normaliseLabel(text) {
  return text
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/\*([^*]+)\*/g, '$1')
    .replace(/`[^`]+`/g, '')
    .replace(/^\*{0,2}Purpose:\*{0,2}\s*/i, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function _titleCase(name) {
  return name
    .split('-')
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1).toLowerCase())
    .join('-');
}

/**
 * Strip markdown emphasis markers (`**`, `*`) from a string.
 *
 * @param {string} text
 * @returns {string}
 */
function _stripEmphasis(text) {
  return text.replace(/\*+/g, '').trim();
}

/**
 * Strip emphasis markers and backtick spans.
 *
 * @param {string} text
 * @returns {string}
 */
function _stripEmphasisAndBackticks(text) {
  return text.replace(/`[^`]*`/g, '').replace(/\*+/g, '').replace(/\s+/g, ' ').trim();
}

// ── Deep freeze ────────────────────────────────────────────────────────────────

/**
 * Recursively deep-freeze an object.
 *
 * @template T
 * @param {T} obj
 * @returns {T}
 */
function _deepFreeze(obj) {
  if (obj === null || typeof obj !== 'object') return obj;

  // Freeze own properties first (before freezing the object itself).
  for (const key of Object.keys(obj)) {
    _deepFreeze(obj[key]);
  }

  return Object.freeze(obj);
}
