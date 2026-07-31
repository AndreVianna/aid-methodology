// body.mjs — Body provider and appender registries.
//
// BODY_PROVIDERS and BODY_APPENDERS are static array literals.
// No directory globbing, no dynamic-import, no registration side effect.
// Filesystem enumeration order is not guaranteed and would put AC-6 at the
// mercy of the OS, so arrays are populated only by direct declaration here.
//
// Seam: features 003-005 extend this file only.
//   feature-003 and feature-004 each add one BODY_PROVIDERS entry.
//   feature-005 adds one BODY_APPENDERS entry.
//   feature-006 has no entry here (it ships browser JavaScript, not page markdown).
//
// Pure exports — no import-time side effect.

import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { REPO_ROOT } from './paths.mjs';
import { classifySkill, buildFlowChart, renderMermaid } from '../lib/flow-graph/index.mjs';
import { provenanceAppender } from '../lib/provenance/index.mjs';

// ── Authored-shape set (mirrors index.mjs; declared locally to avoid a cycle) ─

const AUTHORED_SHAPES = new Set(['dispatch-table', 'inline-states', 'residual']);

/**
 * The two doorway shapes, claimed by the `flow-chart-doorway` provider.
 *
 * Declared as the complement of AUTHORED_SHAPES over the classifier's five-member enum.
 * Together the two sets partition it — see that provider's `applies()` for why the
 * partition, rather than array order, is what keeps the providers from shadowing.
 */
const DOORWAY_SHAPES = new Set(['engine-doorway', 'sibling-doorway']);

/**
 * First matching provider wins — the chart.
 * Each entry: { id: string, applies(skill): boolean, render(skill): string }
 * Feature-003 and feature-004 each add one entry.
 *
 * @type {Array<{ id: string, applies(skill: object): boolean, render(skill: object): string }>}
 */
export const BODY_PROVIDERS = [
  {
    id: 'flow-chart-authored',

    /**
     * Returns true when the skill body classifies as one of the three authored
     * shapes (dispatch-table, inline-states, residual). Returns false for the
     * two doorway shapes — task-037 provides those.
     *
     * @param {object} skill  SkillRecord (body may be '' or undefined for stubs).
     * @returns {boolean}
     */
    applies(skill) {
      if (!skill.body) return false;
      // Guard against test fixtures whose dirName has no real SKILL.md on disk.
      const skillFile = join(REPO_ROOT, 'canonical/skills', skill.dirName, 'SKILL.md');
      if (!existsSync(skillFile)) return false;
      const { shape } = classifySkill({
        name: skill.dirName,
        dir: REPO_ROOT,
        frontmatter: {},
        body: skill.body,
      });
      return AUTHORED_SHAPES.has(shape);
    },

    /**
     * Render the ## Flow section for the skill page.
     *
     * Emits:
     *   ## Flow\n\n
     *   [approximate notice line + blank line — only when confidence === 'approximate']\n
     *   ```mermaid\n<mermaid body>\n```\n
     *
     * @param {object} skill  SkillRecord (dirName must identify a real skill).
     * @returns {string}  LF-terminated markdown.
     */
    render(skill) {
      const chart = buildFlowChart({ name: skill.dirName, dir: REPO_ROOT });
      const mermaid = renderMermaid(chart);

      const notice =
        chart.confidence === 'approximate'
          ? '> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.\n\n'
          : '';

      return `## Flow\n\n${notice}\`\`\`mermaid\n${mermaid}\`\`\`\n`;
    },
  },

  {
    id: 'flow-chart-doorway',

    /**
     * Returns true for the two doorway shapes, and only those.
     *
     * **Array order is not load-bearing, and that is designed rather than lucky.**
     * `classifySkill` returns exactly one value from a five-member enum; the entry
     * above claims `{dispatch-table, inline-states, residual}` and this one claims
     * `{engine-doorway, sibling-doorway}`. The two sets **partition** the enum, so at
     * most one predicate can fire and neither entry can shadow the other.
     *
     * Depending on order instead would fail in the one way that matters: the day a
     * sixth shape is added, an order-dependent design silently routes it to whichever
     * provider is listed first, while a partition leaves it unclaimed — and the
     * exactly-one-provider test then fails loudly. That test, not this comment, is the
     * guard (task-037 AC).
     *
     * @param {object} skill  SkillRecord (body may be '' or undefined for stubs).
     * @returns {boolean}
     */
    applies(skill) {
      if (!skill.body) return false;
      // Same fixture guard as the entry above: a dirName with no SKILL.md on disk.
      const skillFile = join(REPO_ROOT, 'canonical/skills', skill.dirName, 'SKILL.md');
      if (!existsSync(skillFile)) return false;
      const { shape } = classifySkill({
        name: skill.dirName,
        dir: REPO_ROOT,
        frontmatter: Object.fromEntries((skill.fields ?? []).map((f) => [f.key, f.value])),
        body: skill.body,
      });
      return DOORWAY_SHAPES.has(shape);
    },

    /**
     * Render the ## Flow section for a doorway page.
     *
     * Emits the **identical `## Flow` H2** the authored provider emits (task-019 seam 3),
     * so the page table of contents, feature-005's appended fragment list and
     * feature-006's DOM lookup anchor the same way whatever a skill's shape is. An AC
     * asserts that by comparing the two rendered outputs, not by inspection.
     *
     * @param {object} skill  SkillRecord (dirName must identify a real skill).
     * @returns {string}  LF-terminated markdown.
     */
    render(skill) {
      const chart = buildFlowChart({ name: skill.dirName, dir: REPO_ROOT });
      const mermaid = renderMermaid(chart);

      const notice =
        chart.confidence === 'approximate'
          ? '> **Approximate:** This chart is derived by heuristic; exact transitions may differ from runtime behaviour.\n\n'
          : '';

      return `## Flow\n\n${notice}\`\`\`mermaid\n${mermaid}\`\`\`\n`;
    },
  },
];

/**
 * All run, in array order, each appended below the provider's output.
 * Each entry: { id: string, render(skill): string }
 * Feature-005 adds one.
 *
 * @type {Array<{ id: string, render(skill: object): string }>}
 */
export const BODY_APPENDERS = [provenanceAppender];

/**
 * Render the body content for a skill page.
 *
 * Returns the first matching provider's output followed by every appender's
 * output (all appended in declaration order), or '' when no provider matches
 * and no appenders are registered.
 *
 * When this returns '' the caller (render-page.mjs) emits the
 * <!-- body slot: … --> comment instead of an empty heading.
 *
 * Providers own their own headings (## Flow, ## Steps, …); render-page.mjs
 * imposes none, so features 003 and 004 are not boxed into a structure chosen
 * before their charts existed.
 *
 * @param {object} skill  SkillRecord as built by skills/discover.mjs.
 * @returns {string}  Markdown body, LF-terminated, or '' for no body.
 */
export function renderSkillBody(skill) {
  const provider = BODY_PROVIDERS.find((p) => p.applies(skill));
  const providerOutput = provider ? provider.render(skill) : '';
  const appendersOutput = BODY_APPENDERS.map((a) => a.render(skill)).join('');
  return providerOutput + appendersOutput;
}
