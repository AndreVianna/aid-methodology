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

/**
 * The ` — <label>` half of the lead-in, or '' when the label adds nothing.
 *
 * Without this, every entry whose derived label equals its node name reads
 * `**3 · \`CONTINUATION\`** — CONTINUATION`, saying the same word twice. That is
 * not a rare shape — it is the majority of skills, because a label the extractor
 * derives from the name frequently reduces back to the name — so the collapse is
 * a whole-corpus concern rather than a special case. The label exists to carry
 * meaning the name does not; when it repeats the name it is noise a reader has to
 * look past, and this list is already dense. No occurrence count is stated: it
 * would drift with the corpus and nothing here guards it.
 *
 * Same rule and same case-insensitive comparison as `nodeLabel` in
 * render-mermaid.mjs, which collapsed `INTAKE<br/>INTAKE` for the same reason —
 * one rule, applied in both places a label is rendered. Case-insensitive
 * because the extractors title-case a derived label while a state name is
 * upper-case: comparing exactly would leave `ENTRY — Entry` and `EXIT — Exit`
 * in place, which to a reader are the same word.
 *
 * @param {string} name   Node name, unescaped.
 * @param {string} label  Derived label, unescaped.
 * @returns {string}      Either '' or ' — <escaped label>'.
 */
function labelPart(name, label) {
  if (label.trim().toLowerCase() === name.trim().toLowerCase()) return '';
  return ' — ' + escapeLabel(label);
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

    // Exit marker: reads terminal.advanceType only; handoff is deliberately omitted.
    const exitMarker = terminal !== null ? ` · ${terminal.advanceType}` : '';

    // Lead-in paragraph: inline anchor on same line as text so CommonMark parses
    // it as inline HTML inside a paragraph, not as an HTML block.
    // Position comes from node.order (the model integer), not the loop index.
    parts.push(
      `<a id="fragment-${id}"></a>**${node.order} · ${nameSpan(name)}**` +
      labelPart(name, label) +
      ` · _${kind}_${exitMarker}`
    );
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
