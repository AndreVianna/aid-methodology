// render-list.mjs — Source-fragment list renderer for FlowChart objects.
//
// Exports `buildEntries(chart)` and `renderFragmentList(entries)`.
//
// renderFragmentList emits one `## Source fragments` H2, one fixed intro
// sentence (no count), then one entry per node in chart order.  Each entry
// is three blocks at column 0:
//   1. Lead-in paragraph: inline anchor, bold "order · name", escaped label,
//      italic kind, and (when terminal is set) the advanceType exit marker.
//   2. Tilde-fenced verbatim block: plaintext, title= attribute (before wrap),
//      and wrap flag.
//   3. Link line: [Source: `<file><anchor>`](<url>), plus optional
//      ` · [full step: `<detail>` ](<detailUrl>)` on the same line.
//
// Fence width N = max(4, 1 + longest run of '~' at the start of any fragment
// line).  Not one byte of the fragment is escaped inside the fence.
//
// Pure exported functions; no import-time side effect.

import { lineAnchor, blobUrl } from './deep-link.mjs';

// ── Label escaper ─────────────────────────────────────────────────────────────

/**
 * Escape a derived label for safe inline-markdown embedding.
 *
 * HTML-entity substitution first (`&` then `<`), then backslash-escape the
 * seven characters that trigger inline markdown constructs: backtick, `*`,
 * `_`, `[`, `]`, `\`, and `|`.
 *
 * `kind` and `advanceType` are closed enums and pass through unescaped.
 *
 * @param {string} label
 * @returns {string}
 */
function escapeLabel(label) {
  return label
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/[`*_[\]\\|]/g, '\\$&');
}

// ── Name span ─────────────────────────────────────────────────────────────────

/**
 * Render the node name for the lead-in's bold span.
 *
 * Returns a code span (`` `name` ``) when the name contains no backtick.
 * Falls back to escaped plain text (via escapeLabel) when the name contains
 * a backtick — a code span would break out of itself on that character.
 *
 * @param {string} name
 * @returns {string}
 */
function nameSpan(name) {
  if (!name.includes('`')) {
    return '`' + name + '`';
  }
  return escapeLabel(name);
}

// ── Fence-width calculator ────────────────────────────────────────────────────

/**
 * Compute the minimum tilde fence width for a fragment.
 *
 * N = max(4, 1 + longest run of '~' characters at the start of any line).
 * A fragment with no tildes at any line start uses the floor of 4.
 * A fragment whose longest leading-tilde run is K uses K + 1.
 *
 * @param {string} fragment  Verbatim LF-separated excerpt.
 * @returns {number}
 */
function fenceWidth(fragment) {
  let maxRun = 0;
  for (const line of fragment.split('\n')) {
    let run = 0;
    while (run < line.length && line[run] === '~') run++;
    if (run > maxRun) maxRun = run;
  }
  return Math.max(4, maxRun + 1);
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Build one entry per node from a FlowChart, in `chart.nodes` array order.
 *
 * No re-sort: feature-003 guarantees ascending `order` with no gaps, and a
 * second sort would create a second ordering authority that could silently
 * disagree with the chart.
 *
 * No de-duplication: the one-to-one node-to-entry mapping is the shape AC-1 checks.
 * Two nodes that cite the same range produce two entries.
 *
 * @param {import('../flow-graph/model.mjs').FlowChart} chart
 * @returns {import('../flow-graph/model.mjs').FlowNode[]}
 */
export function buildEntries(chart) {
  return chart.nodes.slice();
}

/**
 * Render the complete `## Source fragments` section for a list of node entries.
 *
 * Deterministic: calling this function twice on the same entries array returns
 * identical strings.  Output uses LF line endings only and is LF-terminated.
 *
 * @param {import('../flow-graph/model.mjs').FlowNode[]} entries
 * @returns {string}
 */
export function renderFragmentList(entries) {
  const parts = [];

  parts.push('## Source fragments');
  parts.push('');
  parts.push('Every node in the chart above, in chart order, with the exact `canonical/` text it was derived from.');
  parts.push('');

  for (let i = 0; i < entries.length; i++) {
    const node = entries[i];
    const { id, name, label, kind, terminal, provenance, detail } = node;
    const { file, startLine, endLine, excerpt } = provenance;

    const anchor = lineAnchor(startLine, endLine);
    const url = blobUrl(file, startLine, endLine);
    const title = file + anchor;
    const escapedLabel = escapeLabel(label);

    // Exit marker: reads terminal.advanceType only; handoff is deliberately omitted.
    const exitMarker = terminal !== null ? ` · ${terminal.advanceType}` : '';

    // Lead-in paragraph: inline anchor on same line as text so CommonMark parses
    // it as inline HTML inside a paragraph, not as an HTML block.
    // Position comes from node.order (the model integer), not the loop index.
    parts.push(`<a id="fragment-${id}"></a>**${node.order} · ${nameSpan(name)}** — ${escapedLabel} · _${kind}_${exitMarker}`);
    parts.push('');

    // Tilde-fenced verbatim block: title= before wrap (SPEC order); no escaping.
    const N = fenceWidth(excerpt);
    const fence = '~'.repeat(N);
    parts.push(`${fence}plaintext title="${title}" wrap`);
    parts.push(excerpt);
    parts.push(fence);
    parts.push('');

    // Link line: Source link plus optional detail link, joined on one line with ` · `.
    let linkLine = `[Source: \`${title}\`](${url})`;
    if (detail !== null) {
      const detailAnchor = lineAnchor(detail.startLine, detail.endLine);
      const detailUrl = blobUrl(detail.file, detail.startLine, detail.endLine);
      const detailTitle = detail.file + detailAnchor;
      linkLine += ` · [full step: \`${detailTitle}\`](${detailUrl})`;
    }
    parts.push(linkLine);

    parts.push('');
  }

  return parts.join('\n');
}
