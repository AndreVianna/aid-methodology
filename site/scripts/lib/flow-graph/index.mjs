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

/**
 * Build a validated FlowChart for a skill with one of the three authored shapes.
 *
 * Reads `canonical/skills/<name>/SKILL.md` relative to `dir`, classifies the
 * skill body, dispatches to the appropriate authored extractor, and validates
 * the resulting chart.
 *
 * Throws on any validateChart error: the error message names the failing rule
 * and the offending node or edge.
 *
 * Warnings are never thrown — that is FR-2's boundary, a chart may be
 * *approximate* but never *malformed*. They are also **not written to stderr**,
 * because `gen-skills` requires an empty stderr on a successful run. They are
 * carried on the chart itself, as `chart.warnings`.
 *
 * **`confidence` does not track warnings, and no current caller reads
 * `chart.warnings`.** `extract-dispatch` stamps `'derived'` unconditionally and
 * `extract-residual` stamps `'approximate'` unconditionally, so the body provider's
 * interpretation notice reflects the *extractor* that built the chart, not whether
 * that chart lost anything. A dispatch-table chart can therefore drop an outcome —
 * see `_buildClauses` in advance.mjs — and publish with no notice and no console
 * output. The warning exists and is unit-tested; nothing shows it to a human.
 *
 * The task DETAIL asks for "a run-level accumulated count", which cannot be
 * reconciled with the empty-stderr requirement without a caller to report it to.
 * A module-level counter was tried and removed: nothing read it, so it recorded a
 * number no one could see. Closing the gap properly means summing
 * `chart.warnings.length` at the `gen-skills` call site and printing to stdout —
 * but the chart is built inside `BODY_PROVIDERS[].render()`, a pure
 * string-returning function with nowhere to accumulate, so it needs a seam that
 * does not exist yet. Recorded as a finding rather than bolted on here.
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

  // ── Validate — throw on any error ───────────────────────────────────────

  const { ok, errors } = validateChart(chart);
  if (!ok) {
    throw new Error(errors[0]);
  }

  return chart;
}
