// graph-view-mutate.mjs -- build the view bundle, optionally with ONE deliberate
// defect injected, so the suite can prove that each assertion class can actually
// fail.
//
// WHY THIS FILE EXISTS
//   A sibling feature shipped nineteen assertions that all passed a wrong
//   implementation. "The assertions pass" is therefore not evidence; "the
//   assertions fail when the implementation is wrong" is. So the suite runs the
//   headless half against a MUTATED COPY of the four view files, one defect at a
//   time, and requires the named assertions to fail. Nothing under canonical/ is
//   touched: every mutation is applied to a string in memory and written to a
//   temporary bundle.
//
//   Each mutation reproduces a defect that is either real (one was found and
//   fixed in the table rendering by reading its own rendered output) or is the
//   exact class a specification clause exists to forbid.
//
// PATTERN-MATCHED, NEVER LINE-NUMBERED
//   Every mutation is an exact-string replacement and this file FAILS LOUDLY when
//   the pattern is absent or occurs more than once. A sibling suite once applied
//   negative fixtures with `sed '13s/.../.../'` against a file whose lines had
//   shifted: both runs reported pass while testing nothing. A mutation that
//   silently did not apply would turn a non-vacuity proof into exactly that.
//
// USAGE
//   node graph-view-mutate.mjs <repo-root> <out-bundle.mjs> [mutation-id]
//   Exit 0 on success; 2 when a mutation pattern did not apply exactly once.

import fs from 'node:fs';
import path from 'node:path';

const repo = process.argv[2];
const out = process.argv[3];
const mutation = process.argv[4] || 'none';

if (!repo || !out) {
	process.stderr.write('usage: graph-view-mutate.mjs <repo-root> <out-bundle.mjs> [mutation-id]\n');
	process.exit(2);
}

// The manifest order the page itself concatenates in: the shared predicate first,
// then the view's own files. Anything else would not be the bundle under test.
const FILES = [
	['predicate', 'canonical/aid/scripts/graph/coverage-predicate.mjs'],
	['model', 'canonical/aid/templates/knowledge-graph/graph-model.js'],
	['controls', 'canonical/aid/templates/knowledge-graph/graph-controls.js'],
	['table', 'canonical/aid/templates/knowledge-graph/graph-table.js'],
];

/**
 * The mutation catalogue: which file, what to replace, and which defect it is.
 * `expect` is documentation here -- the suite passes the same ids to the
 * assertion helper, and the two are kept beside each other deliberately.
 */
const MUTATIONS = {
	// The defect a sibling canvas shipped: encoding keyed on the identifier
	// prefix. A prefix says where an id came from, not what class a node is.
	'prefix-encoding': {
		file: 'model',
		from: 'const encoding = KIND_ENCODING[node.kind];',
		to: "const encoding = KIND_ENCODING[{kb:'document',int:'source-artifact',ext:'web-page'}[node.prefix]];",
		defect: 'node encoding derived from the identifier prefix instead of the Kind cell',
		expect: 'GT20,GT21,GT22',
	},
	// The defect the table rendering's own author found by reading the rendered
	// coverage lens: `dimmed` taken from either map unconditionally, so a row
	// carrying a gap badge is also dimmed and the complement stops holding.
	'dimmed-either-map': {
		file: 'table',
		from: `	record.dimmed = !record.marked
		&& (record.edgeEmphasis === 'dimmed'
			|| record.source.emphasis === 'dimmed'
			|| record.target.emphasis === 'dimmed');`,
		to: `	record.dimmed = record.edgeEmphasis === 'dimmed'
		|| record.source.emphasis === 'dimmed'
		|| record.target.emphasis === 'dimmed';`,
		defect: 'dimmed taken from either map unconditionally, so a badged row is dimmed too',
		expect: 'GT50,GT50b',
	},
	// Consumer rule 7 violated: listing a row the fold marked collapsed.
	'list-collapsed': {
		file: 'table',
		from: "		if (!fold || fold === 'collapsed') continue;\n		records.push(",
		to: '		if (!fold) continue;\n		records.push(',
		defect: 'rows the fold collapsed are listed anyway',
		expect: 'GT30,GT31',
	},
	// The unlisted set selected on `degree === 0`, which misses a group head whose
	// every incident row the fold collapsed.
	'unlisted-by-degree': {
		file: 'table',
		from: '	// The drawn node set is already in ascending identifier order, so this\n'
			+ '	// filter preserves a deterministic order without sorting again.\n'
			+ '	return viewModel.visibleNodes.filter((node) => !named.has(node.id));',
		to: '	return viewModel.visibleNodes.filter((node) => node.degree === 0);',
		defect: 'the unlisted set selected on degree === 0 rather than over the fold',
		expect: 'GT61b,GT63',
	},
	// The tie-break made direction-sensitive, which is what "row ascending in BOTH
	// directions" forbids.
	'tiebreak-direction': {
		file: 'table',
		from: '	if (primary !== 0) return primary;\n	return a.row < b.row ? -1 : (a.row > b.row ? 1 : 0);',
		to: '	if (primary !== 0) return primary;\n	const t = a.row < b.row ? -1 : (a.row > b.row ? 1 : 0);\n'
			+ "	return direction === 'desc' ? -t : t;",
		defect: 'the tie-break reversed with the primary direction',
		expect: 'GT37',
	},
	// Half-honouring a rejected sort value: the column falls back to the file
	// order while the direction that came with the rejected column is kept.
	'sortof-keeps-direction': {
		file: 'table',
		from: "	if (!held || !TBL_SORT_COLUMNS.has(held.column)) return { column: TBL_FILE_ORDER, direction: 'asc' };\n"
			+ "	return { column: held.column, direction: held.direction === 'desc' ? 'desc' : 'asc' };",
		to: "	const column = held && TBL_SORT_COLUMNS.has(held.column) ? held.column : TBL_FILE_ORDER;\n"
			+ "	const direction = held && held.direction === 'desc' ? 'desc' : 'asc';\n"
			+ '	return { column: column, direction: direction };',
		defect: 'an out-of-domain sort column answered with a reversed file order',
		expect: 'GT39',
	},
	// Not a defect: a duplicated top-level name, which is a SyntaxError in the
	// page's single module scope. Used to prove the concatenation oracle bites.
	'duplicate-name': {
		file: 'table',
		append: '\nconst el = 1;\n',
		defect: 'a top-level name already declared by an earlier file in the shared scope',
		expect: '(node --check must reject the bundle)',
	},
	// Not a defect either: a colour literal, to prove the colour-literal grep bites.
	'colour-literal': {
		file: 'table',
		append: "\nconst tblPoison = '#1E3A8A';\n",
		defect: 'a hex colour literal in a file that must declare none',
		expect: '(the colour-literal grep must reject the file)',
	},
};

if (mutation !== 'none' && !MUTATIONS[mutation]) {
	process.stderr.write('graph-view-mutate: unknown mutation id: ' + mutation + '\n');
	process.stderr.write('known: none, ' + Object.keys(MUTATIONS).join(', ') + '\n');
	process.exit(2);
}

const parts = new Map();
for (const [key, rel] of FILES) {
	const file = path.join(repo, rel);
	if (!fs.existsSync(file)) {
		process.stderr.write('graph-view-mutate: view file missing: ' + file + '\n');
		process.exit(2);
	}
	parts.set(key, fs.readFileSync(file, 'utf8'));
}

if (mutation !== 'none') {
	const spec = MUTATIONS[mutation];
	const body = parts.get(spec.file);
	if (spec.append !== undefined) {
		parts.set(spec.file, body + spec.append);
	} else {
		// Exactly one occurrence, or this is not the mutation it claims to be.
		const count = body.split(spec.from).length - 1;
		if (count !== 1) {
			process.stderr.write('graph-view-mutate: pattern for "' + mutation + '" occurs ' + count
				+ ' time(s) in ' + spec.file + ', expected exactly 1. The source moved under the mutation; '
				+ 'fix the pattern rather than the count.\n');
			process.exit(2);
		}
		parts.set(spec.file, body.split(spec.from).join(spec.to));
	}
}

const bundle = FILES.map(([key]) => parts.get(key)).join('\n');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, bundle);

const lines = bundle.split('\n').length;
process.stdout.write('bundle=' + out + ' mutation=' + mutation + ' lines=' + lines + '\n');
if (mutation !== 'none') process.stdout.write('defect=' + MUTATIONS[mutation].defect + '\n');
