// graph-view-fixture.mjs -- the self-built relationship file the graph-view suites
// project. Imported by graph-view-model.mjs and graph-view-dom.mjs.
//
// SELF-BUILT AND SELF-DESCRIBING. It depends on no work folder and on no real
// repository content, so pruning a shipped work folder cannot break it. Every
// expectation the suites assert is DERIVED from the row list below (see
// FIXTURE_ROWS) rather than re-typed beside it, so a change to a row cannot leave
// an expectation stale.
//
// WHAT EACH PROPERTY OF THIS FIXTURE EXISTS FOR -- the fixture is the reason the
// assertions have teeth, so each shape is deliberate:
//
//   * THE PREFIX ORACLE. Two `ext:` ids with DIFFERENT kinds -- one `web-page`,
//     one `image` -- must receive different encodings while sharing a prefix; and
//     an in-repo `image` and an external `image` must receive the SAME encoding.
//     No implementation that derives a node's class from its identifier prefix
//     can satisfy both halves. `ext:` is the decisive prefix because it is the
//     one place a kind is unrecoverable from the id.
//   * A DOCUMENT WHOSE EVERY ROW THE FOLD COLLAPSES (`kb:beta.md`), whose degree
//     is 1 and not 0. Under `grouping: 'document'` its only row collapses, so the
//     graph draws it and no listed row names it. A `degree === 0` test for "which
//     nodes has no listed row named" misses it entirely.
//   * A ZERO-ROW SOURCE ARTIFACT reaching the page only through `kb_gaps`
//     (`int:src/unreferenced-loader.mjs`), degree 0 -- the sharpest gap class.
//   * A SELECTABLE NODE WHOSE EVERY ROW A FILTER REMOVES (`kb:gamma.md`), which
//     is the third population and also the empty-listed-table case.
//   * A UNIFORM COLUMN (Observation, empty on every row) and a MULTI-VALUED one
//     (Provenance: declared/derived/inferred), plus FOUR rows sharing one Source
//     Id, so both directions of the tie-break are observable and so is the
//     difference between a sorted column that discriminates and one that cannot.
//   * ONE `fact` DISPLAY NAME PAST THE 32-CHARACTER LABEL BUDGET, so the
//     shortened-label contract has a subject.
//   * EXACTLY ONE UNCOVERED SOURCE ARTIFACT IN THE TABLE, so the Coverage lens's
//     two classes are both non-empty and disjoint, and `kb_gaps` agrees with the
//     view's own recomputation (status `verified`, no integrity alarm).
//   * BOTH A CHAIN ROW AND A NON-CHAIN ROW, so the Provenance lens marks some
//     rows and dims others rather than all or nothing.

const H = '| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |';
const D = '|---|---|---|---|---|---|---|---|---|---|';

const FACT_NAME = 'alpha.md § the renderer choice is d3-force plus PixiJS and is settled';

// Rows are written in the file's normalised orientation -- Source Id sorts before
// Target Id by code unit on every row -- which is why several read from the
// artifact side. The comment on each row is its file row index, which is the
// index the view carries as `row` and emits as `data-row`.
const rows = [
	/*  1 */ `| ext:mdn-webgl | web-page | mdn-webgl | kb:alpha.md#overview | section | alpha.md § Overview | cross-referenced-by | cross-references | declared |   |`,
	/*  2 */ `| ext:wcag-contrast-figure | image | wcag-contrast-figure | kb:alpha.md#overview | section | alpha.md § Overview | illustrates | illustrated-by | inferred |   |`,
	/*  3 */ `| int:docs/media/table-view.png | image | docs/media/table-view.png | kb:alpha.md#overview | section | alpha.md § Overview | illustrates | illustrated-by | declared |   |`,
	/*  4 */ `| int:src/reader.mjs | source-artifact | src/reader.mjs | kb:alpha.md | document | alpha.md | documented-by | documents | declared |   |`,
	/*  5 */ `| int:src/reader.mjs | source-artifact | src/reader.mjs | kb:alpha.md#fact:renderer-choice | fact | ${FACT_NAME} | cited-as-evidence-by | cites-as-evidence | declared |   |`,
	/*  6 */ `| int:src/reader.mjs | source-artifact | src/reader.mjs | kb:alpha.md#overview | section | alpha.md § Overview | cited-as-evidence-by | cites-as-evidence | derived |   |`,
	/*  7 */ `| int:tests/orphan-check.sh | source-artifact | tests/orphan-check.sh | kb:alpha.md | document | alpha.md | mentioned-in | mentions | derived |   |`,
	/*  8 */ `| kb:alpha.md | document | alpha.md | kb:alpha.md#fact:renderer-choice | fact | ${FACT_NAME} | has-part | part-of | declared |   |`,
	/*  9 */ `| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | has-part | part-of | declared |   |`,
	/* 10 */ `| kb:alpha.md | document | alpha.md | kb:concept:graph-view | concept | graph view | defines | defined-by | declared |   |`,
	/* 11 */ `| kb:alpha.md | document | alpha.md | kb:gamma.md | document | gamma.md | cross-references | cross-referenced-by | declared |   |`,
	/* 12 */ `| kb:beta.md | document | beta.md | kb:beta.md#decision-log | section | beta.md § Decision log | has-part | part-of | declared |   |`,
	/* 13 */ `| kb:concept:graph-view | concept | graph view | kb:lens@alpha.md | concept | lens | related-concept | related-concept | derived |   |`,
];

/** Every row of the fixture as a record, parsed from the emitted text itself. */
export const FIXTURE_ROWS = rows.map((line, index) => {
	const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
	return {
		row: index + 1,
		sourceId: cells[0], sourceKind: cells[1], sourceName: cells[2],
		targetId: cells[3], targetKind: cells[4], targetName: cells[5],
		s2t: cells[6], t2s: cells[7], provenance: cells[8], observation: cells[9],
	};
});

/** The header literal, so a suite can assert the rendered header against the
 *  file's own rather than against a second copy of the ten column names. */
export const HEADER = H;

/** The one display name past the label budget. */
export const LONG_FACT_NAME = FACT_NAME;

/** The two recorded gap ids, in the frontmatter's own order. */
export const LEDGER_IDS = ['int:tests/orphan-check.sh', 'int:src/unreferenced-loader.mjs'];

/** The decisive encoding triple: [same prefix / different kind], and the pair
 *  that must AGREE across two prefixes. Named here so both suites read one
 *  definition of the oracle. */
export const PREFIX_ORACLE = Object.freeze({
	sameProxyDifferentKind: ['ext:mdn-webgl', 'ext:wcag-contrast-figure'],
	differentProxySameKind: ['int:docs/media/table-view.png', 'ext:wcag-contrast-figure'],
});

/** The node the `document` fold leaves drawn with no listed row, and its degree
 *  -- which is NOT zero, and that is the whole point. */
export const FOLD_ONLY_NODE = 'kb:beta.md';

/** The zero-row artifact that reaches the page only through the recorded gaps. */
export const ZERO_ROW_NODE = 'int:src/unreferenced-loader.mjs';

/** A node whose every row one category filter removes. */
export const FILTERED_OUT_NODE = 'kb:gamma.md';

export const FIXTURE = `---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: A self-built fixture for the graph view suites.
kb_gaps:
  - id: "int:tests/orphan-check.sh"
    name: "tests/orphan-check.sh"
    severity: "HIGH"
    qualifier: "entry-point"
  - id: "int:src/unreferenced-loader.mjs"
    name: "src/unreferenced-loader.mjs"
    severity: "HIGH"
    qualifier: "entry-point"
tags: [C2, relationships, graph]
owner: architect
---
<!-- AUTO-GENERATED -- do not edit. -->

# Relationships

${H}
${D}
${rows.join('\n')}

## Coverage notes

### Node kinds

| Kind | Carrier convention | Status | Nodes |
|------|--------------------|--------|-------|
| document | KB documents under \`.aid/knowledge/\` | present | 3 |
| concept | definition marker under a level-3+ heading | present | 2 |
| fact | checkable source anchor | present | 1 |
| section | ATX headings, levels 2-6 | present | 2 |
| source-artifact | project source, per significance | present | 3 |
| image | image files in-repo; external image keys | present | 2 |
| web-page | entries in the external-sources file | present | 1 |

### Enumeration exclusions

| Exclusion | Applied | Note |
|-----------|---------|------|
| generated/derived trees | yes | unconditional |
| vendored third-party code | yes | unconditional |
| ignore list | no | setting absent |
`;
