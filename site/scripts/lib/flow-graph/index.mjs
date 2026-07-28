// index.mjs — Public façade for the flow-graph feature cluster (task-029).
//
// Exports: classifySkill, buildFlowChart, validateChart, renderMermaid, serializeChart.
//
// buildFlowChart({ name, dir }) is the primary entry point:
//   1. Reads canonical/skills/<name>/SKILL.md from `dir`.
//   2. Classifies the skill body with classifySkill.
//   3. Dispatches to the matching authored extractor.
//   4. Validates with validateChart — THROWS on any validation error.
//   5. Logs warnings (FR-2 boundary: a chart may be approximate, never malformed).
//
// The dispatch table covers only the three authored shapes:
//   dispatch-table, inline-states, residual.
// The two doorway shapes (sibling-doorway, engine-doorway) are task-037.
//
// Pure exports — no import-time side effect.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseSkillFrontmatter } from '../../skills/frontmatter.mjs';
import { classifySkill } from './classify.mjs';
import { validateChart } from './validate.mjs';
import { renderMermaid } from './render-mermaid.mjs';
import { serializeChart } from './model.mjs';
import { splitFrontmatter } from './source.mjs';
import { extractDispatch } from './extract-dispatch.mjs';
import { extractInline } from './extract-inline.mjs';
import { extractResidual } from './extract-residual.mjs';

// Re-export supporting primitives as the public façade API.
export { classifySkill, validateChart, renderMermaid, serializeChart };

// ── Authored shapes handled by this façade ─────────────────────────────────

/** Shapes whose extractors are wired here; doorway shapes are handled by task-037. */
const AUTHORED_SHAPES = new Set(['dispatch-table', 'inline-states', 'residual']);

// ── Run-level warning counter ──────────────────────────────────────────────

let _warnCount = 0;

/**
 * Build a validated FlowChart for a skill with one of the three authored shapes.
 *
 * Reads `canonical/skills/<name>/SKILL.md` relative to `dir`, classifies the
 * skill body, dispatches to the appropriate authored extractor, and validates
 * the resulting chart.
 *
 * Throws on any validateChart error: the error message names the failing rule
 * and the offending node or edge. Warnings are logged to stderr with a
 * run-level accumulated count and are never thrown (FR-2 boundary: a chart may
 * be approximate, never malformed).
 *
 * @param {{ name: string, dir: string }} params
 *   name — skill directory name under canonical/skills/
 *   dir  — absolute path to the repository root
 * @returns {import('./model.mjs').FlowChart}
 * @throws {Error}  On validateChart error, unreadable file, or non-authored shape.
 */
export function buildFlowChart({ name, dir }) {
  const skillRelPath = 'canonical/skills/' + name + '/SKILL.md';
  const text = readFileSync(join(dir, skillRelPath), 'utf8');

  const { allLines, bodyLines, bodyStartLine } = splitFrontmatter(text, skillRelPath);

  // Convert Fields array to a plain object for extractor consumption.
  const fmFields = parseSkillFrontmatter(text, skillRelPath);
  const frontmatter = Object.fromEntries(fmFields.map((f) => [f.key, f.value]));

  const bodyText = bodyLines.join('\n');
  const { shape } = classifySkill({ name, dir, frontmatter, body: bodyText });

  if (!AUTHORED_SHAPES.has(shape)) {
    throw new Error(
      `[gen-skills] buildFlowChart: shape '${shape}' is not an authored shape` +
      ` (${skillRelPath}:1)`
    );
  }

  // ── Dispatch ────────────────────────────────────────────────────────────

  let chart;
  switch (shape) {
    case 'dispatch-table':
      chart = extractDispatch(name, null, dir);
      break;
    case 'inline-states':
      chart = extractInline({ skill: name, file: skillRelPath, allLines, frontmatter });
      break;
    case 'residual':
      chart = extractResidual({
        skill: name,
        file: skillRelPath,
        allLines,
        bodyLines,
        bodyStartLine,
        frontmatter,
      });
      break;
    default:
      // Unreachable: AUTHORED_SHAPES guard above ensures shape is one of three values.
      throw new Error(`[gen-skills] buildFlowChart: unhandled shape '${shape}' (${skillRelPath}:1)`);
  }

  // ── Accumulate warnings; never throw on them (FR-2 boundary) ─────────────
  //
  // Warnings are not written to stderr here: the gen-skills run mandates an empty
  // stderr on success. The caller can inspect chart.warnings or chart.confidence
  // ('approximate') to surface them in the run log.

  _warnCount += chart.warnings.length;

  // ── Validate — throw on any error ───────────────────────────────────────

  const { ok, errors } = validateChart(chart);
  if (!ok) {
    throw new Error(errors[0]);
  }

  return chart;
}
