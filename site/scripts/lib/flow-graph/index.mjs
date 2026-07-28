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
 * carried on the chart itself, as `chart.warnings`, and accumulated for the run —
 * see `resetFlowWarnings` / `summarizeFlowWarnings` below, which `gen-skills` drains
 * and prints to **stdout**, keeping stderr empty on a successful run.
 *
 * **`confidence` does not track warnings.** `extract-dispatch` stamps `'derived'`
 * unconditionally and `extract-residual` stamps `'approximate'` unconditionally, so
 * the body provider's interpretation notice reflects the *extractor* that built the
 * chart, not whether that chart lost anything. A dispatch-table chart can drop an
 * outcome — see `_buildClauses` in advance.mjs — and still publish with no on-page
 * notice. The run summary is what makes that visible; the page notice is not, and
 * making `confidence` warning-sensitive would change which pages carry the notice,
 * which is a rendering decision this module should not take on its own.
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

  if (chart.warnings && chart.warnings.length > 0) {
    _runWarnings.set(name, chart.warnings.slice());
  }

  return chart;
}

// ── Run-level warning accumulation ───────────────────────────────────────────
//
// task-029's DETAIL requires that `chart.warnings` be "logged with a run-level
// count". A bare counter was tried in task-029 and removed because nothing read it
// — a number no one could see. The missing half was never the counter; it was a
// reader. These two functions are that seam: `buildFlowChart` accumulates, and the
// generator drains and reports at the end of its run.
//
// Accumulating here rather than in the body provider is what makes this work at
// all: `BODY_PROVIDERS[].render()` is a pure string-returning function with nowhere
// to put a total, but it calls `buildFlowChart`, which can hold one.
//
// This is module-level mutable state, deliberately. It is not an import-time side
// effect (the array starts empty and is written only when a chart is built), and it
// cannot affect generated output — `summarizeFlowWarnings` is read-only and
// `resetFlowWarnings` exists so a test or a second run starts clean.

/**
 * Keyed by skill name, **not** an append-only list. A single run builds the same
 * chart more than once — the body provider builds it during RENDER and `gen-skills`
 * builds it again to write the sidecar — and an append-only list reported that as
 * doubled warnings across doubled charts, naming every skill twice. Keying by skill
 * makes the count a property of the corpus rather than of how many times the
 * generator happened to ask.
 *
 * @type {Map<string, string[]>}
 */
const _runWarnings = new Map();

/**
 * Drop every accumulated warning. Call before a run whose count must be its own —
 * `gen-skills` does this at the start, and tests do it between cases.
 *
 * @returns {void}
 */
export function resetFlowWarnings() {
  _runWarnings.clear();
}

/**
 * Summarize warnings accumulated since the last reset.
 *
 * `charts` is the number of charts that carried at least one warning, not the
 * number of warnings — a single chart can carry several, and the two numbers being
 * different is the interesting case.
 *
 * @returns {{total: number, charts: number, skills: string[], messages: string[]}}
 */
export function summarizeFlowWarnings() {
  const entries = [..._runWarnings.entries()];
  return {
    total: entries.reduce((n, [, w]) => n + w.length, 0),
    charts: entries.length,
    skills: entries.map(([skill]) => skill),
    messages: entries.flatMap(([, w]) => w),
  };
}
