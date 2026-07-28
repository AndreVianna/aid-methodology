// render-mermaid.mjs — Mermaid fence body renderer for FlowChart objects.
//
// renderMermaid(chart) -> string
//   Returns the Mermaid flowchart TB fence body only — no fence markers
//   (```mermaid / ```), no H2, and no approximate-notice line.  The enclosing
//   fence and the provider heading (## Flow) are the body provider's concern;
//   renderMermaid is called by that provider (task-029), not by itself.
//
// Node shapes by kind:
//   entry, exit    → stadium      n1(["NAME<br/>label"])
//   decision       → rhombus      n1{"NAME<br/>label"}
//   step, loop-back → rectangle   n1["NAME<br/>label"]
//
// Edge arrows by kind:
//   sequence                           →   n1 --> n2
//   branch, non-null condition         →   n1 -->|"condition"| n2
//   branch, null condition             →   n1 --> n2
//   loop-back, non-null condition      →   n1 -. "condition" .-> n2
//   loop-back, null condition          →   n1 -.-> n2
//   re-entry, non-null condition       →   n1 -. "condition" .-> n2
//   re-entry, null condition           →   n1 -.-> n2
//
// Escaping (applied to label text and condition text before embedding):
//   &  → &amp;    (first, to prevent double-escaping of later entities)
//   <  → &lt;
//   >  → &gt;
//   "  → &quot;
//   `  → space    (residual; backtick triggers Mermaid monospace formatting)
//   |  → space    (residual; pipe is special inside arrow syntax)
//
// classDef block (casulo palette, self-contained per KI-001):
//   aidNode      — hook H3; feature-006 queries by this class (no fill/stroke change)
//   aidEntry     — entry nodes (green)
//   aidExit      — exit nodes (red)
//   aidDecision  — decision nodes (amber)
//   aidLoopBack  — loop-back nodes (blue)
//   aidStep      — regular step nodes (dark card + gold border)
//
// AC-6 (byte-stability): output is deterministic — nodes ordered by node.order,
// edges in the pre-sorted order the chart already carries (from.order, to.order,
// condition).  No clock, environment variable, or random source is read.
//
// truncate is the single shared code-point truncator (≤60 label / ≤80 condition).
// Imported here as the canonical function so that if any future callsite within
// this module needs truncation it uses the same implementation.  The renderer
// itself does not truncate because labels and conditions arrive pre-truncated
// from the extractors; writing a second truncator is the HIGH-finding shape
// delivery-002 paid for.
//
// Pure export — no import-time side effect.

// eslint-disable-next-line no-unused-vars
import { truncate } from './model.mjs';

// ── casulo palette ──────────────────────────────────────────────────────────

/**
 * Self-contained classDef block emitted at the top of every fence.
 * Order matters: aidNode comes first so kind classDefs (declared later)
 * override aidNode's color property in the CSS cascade.
 */
const CLASS_DEFS = [
  // `color:#fff`, NOT `color:inherit`. Every node carries two classes — its kind
  // class and this hook — and Mermaid emits both, so the cascade decides. `inherit`
  // picked up the PAGE's text colour, which is dark in light mode: measured
  // rgb(53,56,65) on fills of dark green, dark red and near-black. Unreadable in
  // light mode, fine in dark, because there `inherit` happened to be near-white.
  //
  // The earlier reasoning that declaration order protected the kind colours was
  // wrong, and it took a rendered page to show it — the source and the unit tests
  // both looked correct. Every kind class sets the same `#fff`, so matching it here
  // makes the hook inert with respect to colour while keeping the H3 selector
  // feature-006 binds to.
  'classDef aidNode color:#fff',
  'classDef aidEntry fill:#166534,stroke:#14532d,color:#fff',
  'classDef aidExit fill:#991b1b,stroke:#7f1d1d,color:#fff',
  'classDef aidDecision fill:#92400e,stroke:#78350f,color:#fff',
  'classDef aidLoopBack fill:#1e3a8a,stroke:#1e3a8a,color:#fff',
  'classDef aidStep fill:#1a2035,stroke:#d4a853,color:#f1f5f9',
].join('\n  ');

/** Map node.kind → classDef name (for per-node kind assignment). */
const KIND_CLASS = {
  entry: 'aidEntry',
  exit: 'aidExit',
  decision: 'aidDecision',
  'loop-back': 'aidLoopBack',
  step: 'aidStep',
};

// ── Escaping ─────────────────────────────────────────────────────────────────

/**
 * Escape text for safe embedding inside a Mermaid label or edge condition.
 *
 * Order is significant: `&` must be replaced first so that later entity
 * substitutions (`&lt;` etc.) are not themselves double-escaped.
 *
 * After HTML entity substitution, any residual backtick (Mermaid monospace
 * trigger) and pipe (special inside arrow label syntax) are replaced with a
 * space — the visual impact is minimal and parsing is guaranteed safe.
 *
 * @param {string} text  Raw text from node.name, node.label or edge.condition.
 * @returns {string}
 */
function escapeMermaid(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/`/g, ' ')
    .replace(/\|/g, ' ');
}

// ── Node rendering ────────────────────────────────────────────────────────────

/**
 * Render the two-line Mermaid label for a node: `"NAME<br/>derived label"`.
 * Both segments are escaped; the `<br/>` separator is Mermaid HTML markup and
 * is therefore never escaped.
 *
 * @param {import('./model.mjs').FlowNode} node
 * @returns {string}
 */
function nodeLabel(node) {
  const name = escapeMermaid(node.name);
  // A DECISION renders as a rhombus, and Mermaid sizes a rhombus around its text —
  // so a two-line label inflated one to 320x320px, a quarter of the whole chart's
  // height and two thirds of its width. No layout engine fixes that; it is node
  // sizing, not arrangement.
  //
  // The second line is also least useful here: a decision's meaning is carried by
  // its outgoing BRANCH CONDITIONS, which are already drawn on the edges, so the
  // prose beneath the name mostly repeats what the branches say. Name only.
  if (node.kind === 'decision') return `"${name}"`;
  // When the derived label adds nothing over the state name, render one line.
  // Otherwise a node reads `INTAKE<br/>INTAKE` — measured at 45 of 181 nodes
  // across the 34 charts, and 100% of the nodes in three ticket skills, where
  // every state's lead prose was just its own name. The second line is there to
  // carry meaning; repeating the name is visual noise a reader has to look past.
  const label = escapeMermaid(node.label);
  if (label.trim() === name.trim()) return `"${name}"`;
  return `"${name}<br/>${label}"`;
}

/**
 * Render a single FlowNode as a Mermaid node declaration.
 *
 * Shape delimiters by kind:
 *   entry, exit    → stadium  id(["label"])
 *   decision       → rhombus  id{"label"}
 *   step, loop-back → rect    id["label"]
 *
 * @param {import('./model.mjs').FlowNode} node
 * @returns {string}
 */
function nodeDecl(node) {
  const lbl = nodeLabel(node);
  switch (node.kind) {
    case 'entry':
    case 'exit':
      return `${node.id}([${lbl}])`;
    case 'decision':
      return `${node.id}{${lbl}}`;
    case 'step':
    case 'loop-back':
      return `${node.id}[${lbl}]`;
    default:
      throw new Error(
        `[gen-skills] render-mermaid.mjs:nodeDecl: unknown node kind ${JSON.stringify(node.kind)}`
      );
  }
}

// ── Edge rendering ────────────────────────────────────────────────────────────

/**
 * Render a single FlowEdge as a Mermaid edge declaration.
 *
 * Solid arrows (sequence, branch):
 *   sequence or branch with null condition   →   from --> to
 *   branch with non-null condition           →   from -->|"escaped-condition"| to
 *
 * Dotted arrows (loop-back, re-entry):
 *   null condition     →   from -.-> to
 *   non-null condition →   from -. "escaped-condition" .-> to
 *
 * @param {import('./model.mjs').FlowEdge} edge
 * @returns {string}
 */
function edgeDecl(edge) {
  const { from, to, kind, condition } = edge;
  const cond = condition !== null ? escapeMermaid(condition) : null;

  // A SELF-EDGE is drawn without an arrowhead, and this is a workaround for a
  // renderer artifact rather than a stylistic choice.
  //
  // Under the ELK layout, a self-loop is emitted as an ordinary edge path whose
  // final segment doubles back on itself — its last two coordinates run
  // right-to-left by a fraction of a pixel. SVG `marker-end` orients on that final
  // segment, so the arrowhead renders pointing AWAY from the node. Measuring the
  // tangent over a few pixels shows the loop genuinely arriving rightward, which
  // makes the defect easy to argue away; at 3x zoom the arrow is plainly backwards.
  // dagre avoids it by rendering self-loops through a dedicated `cyclic-special`
  // path set, but dagre loses on every other count.
  //
  // A loop with no arrowhead cannot point the wrong way. Direction is not lost:
  // both endpoints are the same node, so there is nothing for an arrow to
  // disambiguate — and the "otherwise" caption still says what the loop means.
  if (from === to) {
    return cond !== null ? `${from} -. "${cond}" .- ${to}` : `${from} --- ${to}`;
  }

  switch (kind) {
    case 'sequence':
      return `${from} --> ${to}`;
    case 'branch':
      return cond !== null
        ? `${from} -->|"${cond}"| ${to}`
        : `${from} --> ${to}`;
    case 'loop-back':
    case 're-entry':
      return cond !== null
        ? `${from} -. "${cond}" .-> ${to}`
        : `${from} -.-> ${to}`;
    default:
      throw new Error(
        `[gen-skills] render-mermaid.mjs:edgeDecl: unknown edge kind ${JSON.stringify(kind)}`
      );
  }
}

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Render a FlowChart as a Mermaid `flowchart TB` fence body.
 *
 * Returns the fence body only — no opening/closing fence markers
 * (```mermaid … ```) and no H2 or approximate-notice line.  Those are
 * the body provider's responsibility.
 *
 * The output is byte-stable: given the same FlowChart, two calls return the
 * identical string (AC-6).  No clock, environment variable or random source
 * is read.  Node order follows `node.order` ascending; edge order is the
 * pre-sorted order the FlowChart already carries — (from.order, to.order,
 * condition).
 *
 * Every chart emits its own `classDef` block (casulo palette) so that
 * rendering is correct regardless of whether KI-001 (astro-mermaid silently
 * dropping `themeVariables`) is ever fixed.
 *
 * Every node carries a `class <id> aidNode` statement (hook H3) that
 * feature-006 binds its interactive panel to.  The `classDef aidNode` that
 * backs the hook is included in every chart's classDef block.
 *
 * @param {import('./model.mjs').FlowChart} chart
 * @returns {string}  Mermaid fence body, ending with a single `\n`.
 */
export function renderMermaid(chart) {
  const lines = [];

  // ── 1. Dialect and classDef block ──────────────────────────────────────────
  // Layout directive. Mermaid's defaults are tuned for small hand-drawn diagrams;
  // these charts are derived, so nodes carry two lines of real text and grow well
  // past the spacing dagre assumes. The result was shapes nearly touching and edges
  // taking long curved detours around them.
  //
  //   nodeSpacing / rankSpacing — room between siblings and between ranks, so a
  //     wide rhombus stops crowding whatever sits beside and below it.
  //   curve: linear — dagre's default basis spline bows edges outward around large
  //     nodes, which is what reads as "bending strangely"; straight segments make
  //     a loop-back's destination obvious.
  //   padding — breathing room inside each shape.
  lines.push('---');
  lines.push('config:');
  lines.push('  layout: elk');
  lines.push('  flowchart:');
  lines.push('    nodeSpacing: 55');
  lines.push('    rankSpacing: 65');
  lines.push('    padding: 12');
  lines.push('    useMaxWidth: true');
  lines.push('---');
  lines.push('flowchart TB');
  lines.push(`  ${CLASS_DEFS}`);

  // ── 2. Node declarations (in order ascending) ──────────────────────────────
  for (const node of chart.nodes) {
    lines.push(`  ${nodeDecl(node)}`);
  }

  // ── 3. Edge declarations (pre-sorted: from.order, to.order, condition) ──────
  for (const edge of chart.edges) {
    lines.push(`  ${edgeDecl(edge)}`);
  }

  // ── 4. Kind-class assignments (one per node, in order ascending) ────────────
  for (const node of chart.nodes) {
    lines.push(`  class ${node.id} ${KIND_CLASS[node.kind]}`);
  }

  // ── 5. aidNode hook H3 (one per node, in order ascending) ───────────────────
  for (const node of chart.nodes) {
    lines.push(`  class ${node.id} aidNode`);
  }

  return lines.join('\n') + '\n';
}
