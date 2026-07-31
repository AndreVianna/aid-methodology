// extract-sibling.mjs — Sibling-doorway extractor (feature-004, shape 4).
//
// Entry: extractSiblingDoorway(skillRecord) → FlowChart
//        resolveSiblingParent({ body }) → string|null
//        parentChartCache — Map<parentName, FlowChart>, exported for memo tests.
//
// Splices the parent's chart whole and verbatim (no feature-004 rule — L1, B1,
// or otherwise — is applied to the spliced segment).  This is an invariant:
// /skills/aid-test/ and /skills/aid-test-security/ must show the same aid-test
// flow.  composeDoorwayChart (compose.mjs) performs the offset splice.
//
// parentChartCache is a contract, not an optimisation: aid-create-document has
// ten siblings and re-deriving its chart ten times would be visible in build time.
//
// Sub-forms (read by readDoorwayBinding from compose.mjs):
//   kind-sibling  — body carries {verb, artifact}: label = braced group verbatim;
//                   hop condition = bolded facet binding, e.g. 'kind bound to security'.
//   pure-alias    — body carries alias_of: label = 'alias of <parent>';
//                   hop condition = null.
//   neither       — no binding match: label = 'Delegates to <parent>';
//                   condition = null; W1 already emitted by readDoorwayBinding.
//
// confidence is the weaker of the two: 'approximate' when the parent is
// approximate (W4), 'derived' otherwise.
//
// Resolution is capped at MAX_HOPS sibling-chain hops with a visited-set cycle
// guard.  On exceeding either, W3 is emitted and a single-node exit chart is
// returned — never a throw.
//
// Warnings:
//   W1 — no binding form matched in body (emitted by readDoorwayBinding)
//   W2 — sibling body carries H2 sections beyond the hop prose (not drawn)
//   W3 — chain cap exceeded, cycle detected, or unresolvable parent
//   W4 — confidence weakened to 'approximate' due to approximate parent
//
// This module defines no model, no validator, no renderer, and no substrate.
// It consumes feature-003's as published: truncate, makeNode, makeEdge,
// buildChart.  GITHUB_BLOB_BASE is exported from site/scripts/skills/paths.mjs.
//
// Pure exports — no import-time side effect.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { truncate, makeNode, makeEdge, buildChart } from './model.mjs';
import { readDoorwayBinding, composeDoorwayChart } from './compose.mjs';
import { buildFlowChart } from './index.mjs';
import { classifySkill } from './classify.mjs';
import { splitFrontmatter } from './source.mjs';
import { GITHUB_BLOB_BASE, REPO_ROOT } from '../../skills/paths.mjs';

// ── Constants ─────────────────────────────────────────────────────────────────

/** Maximum sibling-chain hops before W3 fires. */
const MAX_HOPS = 4;

/** D3's canonical SKILL.md reference pattern (same regex source as classify.mjs). */
const _SKILL_REF_SRC = 'canonical\\/skills\\/([^/\\s]+)\\/SKILL\\.md';

// ── Parent chart cache ────────────────────────────────────────────────────────

/**
 * Memoizes FlowChart for authored-shape parent skills by directory name.
 *
 * A contract: aid-create-document has ten siblings; re-deriving its chart ten
 * times would be visible in build time.  Tests must assert object identity
 * (toBe) or call count — not deep equality, which would pass for a re-derivation.
 *
 * @type {Map<string, import('./model.mjs').FlowChart>}
 */
export const parentChartCache = new Map();

// ── resolveSiblingParent ──────────────────────────────────────────────────────

/**
 * Resolve the parent skill name from a sibling body.
 *
 * Implements D3's rule: the single distinct
 * canonical/skills/<name>/SKILL.md reference in the body.
 *
 * Call site should prefer `skillRecord.delegatesTo` (set by the classifier)
 * and use this function only as the fallback — as the DETAIL specifies.
 *
 * @param {{ body: string }} params
 * @returns {string|null}  Parent directory name, or null when zero or 2+ distinct
 *                         references are found (contradicts D3; should not occur
 *                         for skills the classifier routed here).
 */
export function resolveSiblingParent({ body }) {
  const re = new RegExp(_SKILL_REF_SRC, 'g');
  const names = new Set();
  let m;
  while ((m = re.exec(body)) !== null) names.add(m[1]);
  return names.size === 1 ? [...names][0] : null;
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/**
 * Return the titles of all level-2 headings (`## …`) in a body text.
 * Used to detect W2: sibling carries H2 sections it does not draw.
 *
 * @param {string} body
 * @returns {string[]}
 */
function _h2Titles(body) {
  const titles = [];
  for (const raw of body.split('\n')) {
    const line = raw.replace(/\r$/, '');
    const m = line.match(/^##\s+(.+)/);
    if (m) titles.push(m[1].trim());
  }
  return titles;
}

/**
 * Build the one-line prose sibling resolution notice.
 *
 * Emitted **above** the Mermaid fence by the body provider (task-037); never
 * a chart node.  Carries a GITHUB_BLOB_BASE link and names the resolved parent
 * and any facet binding.
 *
 * @param {string}      parent  Resolved parent directory name
 * @param {string|null} bound   Facet binding string, e.g. 'kind bound to security'
 * @returns {string}
 */
function _buildNotice(parent, bound) {
  const url = `${GITHUB_BLOB_BASE}/canonical/skills/${parent}/SKILL.md`;
  const boundPart = bound != null ? `, ${bound}` : '';
  return `> Sibling resolution: delegates to [${parent}](${url})${boundPart}.`;
}

/**
 * Follow the sibling chain from `initialParent` to an authored-shape parent.
 *
 * At each step: check the cache, then read + classify the parent.  On authored
 * shape, build with buildFlowChart and cache by parent name.  On sibling, follow.
 * On engine-doorway or unreadable, emit W3.
 *
 * @param {string|null} initialParent  First parent name; null means no parent found.
 * @param {string}      skill          Skill being extracted (for W3 messages).
 * @returns {{ parentName: string|null, chart: import('./model.mjs').FlowChart|null, w3: string|null }}
 */
function _resolveChain(initialParent, skill) {
  if (initialParent === null) {
    return {
      parentName: null,
      chart: null,
      w3: `[gen-skills] W3: ${skill}: cannot resolve parent (no single canonical/skills reference in body)`,
    };
  }

  const visited = new Set([skill]);
  let parent = initialParent;

  for (let hop = 0; hop < MAX_HOPS; hop++) {
    // Cycle guard
    if (visited.has(parent)) {
      return {
        parentName: parent,
        chart: null,
        w3: `[gen-skills] W3: ${skill}: resolution cycle detected at ${parent}`,
      };
    }
    visited.add(parent);

    // Cache hit — return the memoized chart immediately.
    if (parentChartCache.has(parent)) {
      return { parentName: parent, chart: parentChartCache.get(parent), w3: null };
    }

    // Read the parent's SKILL.md.
    let parentBody;
    try {
      const skillRelPath = 'canonical/skills/' + parent + '/SKILL.md';
      const text = readFileSync(join(REPO_ROOT, skillRelPath), 'utf8');
      const { bodyLines } = splitFrontmatter(text, skillRelPath);
      parentBody = bodyLines.join('\n');
    } catch (err) {
      return {
        parentName: parent,
        chart: null,
        w3: `[gen-skills] W3: ${skill}: cannot read parent ${parent}: ${err.message}`,
      };
    }

    // Classify the parent's body.
    const classification = classifySkill({
      name: parent, dir: REPO_ROOT, frontmatter: {}, body: parentBody,
    });

    if (classification.shape === 'sibling-doorway') {
      // Follow one more hop.
      const nextParent =
        classification.delegatesTo ?? resolveSiblingParent({ body: parentBody });
      if (nextParent === null) {
        return {
          parentName: parent,
          chart: null,
          w3: `[gen-skills] W3: ${skill}: chain broken at ${parent} (no next parent found)`,
        };
      }
      parent = nextParent;
      continue;
    }

    // Authored shape (dispatch-table, inline-states, residual) or engine-doorway.
    // buildFlowChart handles authored shapes and throws for engine-doorway.
    try {
      const chart = buildFlowChart({ name: parent, dir: REPO_ROOT });
      parentChartCache.set(parent, chart);
      return { parentName: parent, chart, w3: null };
    } catch (err) {
      return {
        parentName: parent,
        chart: null,
        w3: `[gen-skills] W3: ${skill}: cannot build parent chart for ${parent}: ${err.message}`,
      };
    }
  }

  // Exceeded hop cap.
  return {
    parentName: parent,
    chart: null,
    w3: `[gen-skills] W3: ${skill}: exceeded ${MAX_HOPS}-hop resolution cap (last attempted: ${parent})`,
  };
}

// ── extractSiblingDoorway ─────────────────────────────────────────────────────

/**
 * Extract a FlowChart for a sibling-doorway skill (shape: 'sibling-doorway').
 *
 * Reads the doorway binding from the body (compose.mjs), resolves the parent
 * chart (with memoization and chain-following), builds a one-node prefix, and
 * splices the parent chart whole through composeDoorwayChart (compose.mjs).
 *
 * Adds a `notice` field (prose string) on the returned chart for the body
 * provider (task-037) to emit above the Mermaid fence.
 *
 * @param {object} skillRecord  SkillRecord as produced by discover.mjs
 * @param {string} skillRecord.dirName        Skill directory name (e.g. 'aid-test-security')
 * @param {string} skillRecord.sourcePath     Repo-root-relative POSIX path to SKILL.md
 * @param {string} skillRecord.body           Body text (after frontmatter closing fence)
 * @param {number} skillRecord.bodyStartLine  1-based file line of body[0]
 * @param {string} [skillRecord.delegatesTo]  Pre-resolved parent (from classifier, task-019)
 * @returns {import('./model.mjs').FlowChart & { notice: string }}
 */
export function extractSiblingDoorway(skillRecord) {
  const { dirName: skill, sourcePath: file, body, bodyStartLine } = skillRecord;
  const warnings = [];

  // ── 1. Read the doorway binding ────────────────────────────────────────────
  // W1 is emitted by readDoorwayBinding and propagated here.
  const binding = readDoorwayBinding({ body, bodyStartLine, sourcePath: file });
  warnings.push(...binding.warnings);

  // ── 2. Determine the initial parent name ──────────────────────────────────
  // Prefer the caller-supplied delegatesTo (from the classifier), else parse body.
  const initialParent = skillRecord.delegatesTo ?? resolveSiblingParent({ body });

  // ── 3. Follow the parent chain ────────────────────────────────────────────
  const { parentName, chart: parentChart, w3 } = _resolveChain(initialParent, skill);
  if (w3 !== null) warnings.push(w3);

  // ── 4. Detect W2: H2 sections in the sibling body ─────────────────────────
  const h2titles = _h2Titles(body);
  if (h2titles.length > 0) {
    warnings.push(
      `[gen-skills] W2: sibling ${file} carries H2 sections not drawn: ${h2titles.join(', ')}`
    );
  }

  // ── 5. Build the resolution notice ────────────────────────────────────────
  const notice = _buildNotice(parentName ?? 'unknown', binding.bound);

  // ── 6. Fallback chart when parent chart is unavailable (W3 fired) ──────────
  // Returns a single-node approximate chart that passes validateChart.
  if (parentChart === null) {
    const unresolved = parentName ?? 'unknown';
    const rawNode = makeNode({
      order: 1,
      name: skill,
      label: truncate(`Unresolved: ${unresolved}`, 60),
      provenance: {
        file,
        startLine: bodyStartLine,
        endLine: bodyStartLine,
        sourceKind: 'skill',
        excerpt: body.split('\n')[0]?.replace(/\r$/, '') ?? '',
      },
      terminal: { advanceType: 'UNSPECIFIED', handoff: null },
      detail: null,
    });
    const fallbackChart = buildChart({
      skill,
      shape: 'sibling-doorway',
      extractor: 'extract-sibling',
      confidence: 'approximate',
      nodes: [rawNode],
      edges: [],
      sources: [file],
      warnings,
    });
    return Object.assign(fallbackChart, { notice });
  }

  // ── 7. Build the prefix entry node label (sub-form dependent) ─────────────
  let label;
  let hopCondition;

  if (binding.aliasOf !== null) {
    // Pure-alias sub-form: alias_of matched; no facet binding.
    label = truncate(`alias of ${parentName ?? binding.aliasOf}`, 60);
    hopCondition = null;
  } else if (binding.verb !== null) {
    // Kind-sibling sub-form: braced group matched; label = group verbatim.
    // artifact '' is rendered as "" per the source-text convention.
    const artToken = binding.artifact === '' ? '""' : binding.artifact;
    label = truncate(`{verb: ${binding.verb}, artifact: ${artToken}}`, 60);
    hopCondition = binding.bound; // e.g. 'kind bound to security' (null if none)
  } else {
    // Neither sub-form (W1 already emitted).  Delegates with no binding.
    label = truncate(`Delegates to ${parentName ?? 'unknown'}`, 60);
    hopCondition = null;
  }

  // ── 8. Build the prefix node ───────────────────────────────────────────────
  // id = 'n1' and kind = 'entry' are set explicitly here because makeNode
  // (per model.mjs) returns a raw node without those fields, yet
  // composeDoorwayChart reads prefixNodes[0].id directly when deriving entries.
  const prefixNode = {
    ...makeNode({
      order: 1,
      name: skill,
      label,
      provenance: binding.provenance,
      terminal: null,
      detail: null,
    }),
    id:   'n1',
    kind: 'entry',
  };

  // ── 9. Build the hop edge ──────────────────────────────────────────────────
  // The hop targets the parent chart's first node (order = 1, id = 'n1').
  // After composeDoorwayChart applies the offset of 1, that node becomes 'n2'.
  // prefixEdges are NOT remapped by compose; we pre-compute the composed id.
  //
  // sourceKind is 'sibling': this edge is the sibling delegation, not a
  // sequence edge within the skill's own state machine.
  const hopProvenance = { ...binding.provenance, sourceKind: 'sibling' };
  const hopEdge = makeEdge({
    from:        'n1',
    to:          'n2',
    kind:        'sequence',
    condition:   hopCondition,
    advanceType: 'CHAIN',
    provenance:  hopProvenance,
  });

  // ── 10. Confidence: weaker of the two; W4 when it weakens ─────────────────
  let confidence = 'derived';
  if (parentChart.confidence === 'approximate') {
    confidence = 'approximate';
    warnings.push(
      `[gen-skills] W4: ${skill}: confidence weakened to 'approximate' ` +
      `because parent ${parentName} chart is approximate`
    );
  }

  // ── 11. Compose and return ─────────────────────────────────────────────────
  // Passes the parent chart as the core.  composeDoorwayChart splices it whole
  // and verbatim: no L1, no B1, no other feature-004 rule touches the segment.
  const chart = composeDoorwayChart({
    skill,
    prefixNodes: [prefixNode],
    prefixEdges: [hopEdge],
    core:        parentChart,
    confidence,
    shape:       'sibling-doorway',
    extractor:   'extract-sibling',
  });

  // composeDoorwayChart carries only core.warnings; prefix-level warnings
  // (W1, W2, W4 accumulated above) must be pushed in by the caller.
  chart.warnings.push(...warnings);

  return Object.assign(chart, { notice });
}
