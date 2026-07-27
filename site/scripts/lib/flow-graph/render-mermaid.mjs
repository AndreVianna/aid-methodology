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
  'classDef aidNode color:inherit',
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
  return `"${escapeMermaid(node.name)}<br/>${escapeMermaid(node.label)}"`;
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
