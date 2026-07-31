// skill-node-panel.ts — Build-time half of feature-006's interactive node panel.
//
// Exports:
//   shouldMount(generatedFrom, known)  — route gate: identifies skill pages by data
//   buildProjection(chart)             — sidecar → PanelProjection for the browser
//   embedJson(projection)              — safe inline-script encoding
//
// Pure exported functions; no import-time side effect.

import { blobUrl } from '../../scripts/lib/provenance/deep-link.mjs';

// ── Internal type aliases (mirrors the JSDoc shapes in model.mjs) ─────────────

interface Terminal {
  advanceType: string;
  handoff: string | null;
}

interface Provenance {
  file: string;
  startLine: number;
  endLine: number;
  sourceKind: string;
  excerpt: string;
}

interface FlowNode {
  id: string;
  order: number;
  name: string;
  label: string;
  kind: string;
  terminal: Terminal | null;
  provenance: Provenance;
  detail: Provenance | null;
}

interface FlowChart {
  skill: string;
  confidence: string;
  nodes: FlowNode[];
}

// ── Exported types ────────────────────────────────────────────────────────────

export interface PanelNode {
  id: string;
  order: number;
  name: string;
  label: string;
  kind: string;
  exit: Terminal | null;
  fragment: string;
  source: { url: string };
  detail: { url: string } | null;
}

export interface PanelProjection {
  v: 1;
  skill: string;
  confidence: string;
  nodes: PanelNode[];
}

// ── Route gate ────────────────────────────────────────────────────────────────

const SKILL_PATH_RE =
  /^canonical\/skills\/([a-z0-9]+(?:-[a-z0-9]+)*)\/SKILL\.md$/;

/**
 * Return the captured skill directory name when `generatedFrom` matches the
 * canonical skill path pattern AND the sidecar exists in `known`, else null.
 *
 * Data test, not a path test — independent of the site `base` setting, and
 * fails closed when the sidecar set is empty (sidecars not yet generated).
 *
 * @param generatedFrom  Value of `entry.data.generatedFrom`; may be undefined.
 * @param known          Set of skill directory names that have a sidecar.
 * @returns              Skill directory name, or null.
 */
export function shouldMount(
  generatedFrom: string | undefined,
  known: Set<string>
): string | null {
  if (!generatedFrom) return null;
  const m = SKILL_PATH_RE.exec(generatedFrom);
  if (!m) return null;
  const name = m[1];
  return known.has(name) ? name : null;
}

// ── Sidecar projection ────────────────────────────────────────────────────────

/**
 * Build a PanelProjection from a FlowChart sidecar.
 *
 * Emits exactly PanelNode's field set for each node, in chart.nodes array
 * order (no re-sort). source.url is derived from blobUrl (delivery-004 import)
 * so the panel link and the source-fragment list share one URL authority.
 * detail carries only the URL, never the excerpt.
 *
 * Deliberately excluded to keep page weight down: edges, sources, warnings,
 * entries, exits, title, shape, extractor.
 *
 * @param chart  FlowChart read from the sidecar.
 * @returns      PanelProjection ready for embedJson.
 */
export function buildProjection(chart: FlowChart): PanelProjection {
  return {
    v: 1,
    skill: chart.skill,
    confidence: chart.confidence,
    nodes: chart.nodes.map((n): PanelNode => {
      const { file, startLine, endLine, excerpt } = n.provenance;
      return {
        id: n.id,
        order: n.order,
        name: n.name,
        label: n.label,
        kind: n.kind,
        exit: n.terminal,
        fragment: excerpt,
        source: { url: blobUrl(file, startLine, endLine) },
        detail:
          n.detail === null
            ? null
            : { url: blobUrl(n.detail.file, n.detail.startLine, n.detail.endLine) },
      };
    }),
  };
}

// ── Safe inline-script encoding ───────────────────────────────────────────────

/**
 * Serialize a PanelProjection to a string safe for embedding inside a
 * <script> tag as a JSON literal.
 *
 * JSON.stringify output + replace every `<` with `\u003c`.  In stringify
 * output a `<` can only appear inside a JSON string value, where `\u003c` is
 * a valid JSON escape and JSON.parse round-trips it to the original character.
 * One replacement rule closes both `</script>` injection and `<!--` sequences.
 *
 * @param projection  Any JSON-serialisable value.
 * @returns           String with no literal `<` characters.
 */
export function embedJson(projection: PanelProjection): string {
  return JSON.stringify(projection).replace(/</g, '\\u003c');
}
