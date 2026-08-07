// graph-view-model.mjs -- the headless half of the graph-view suite: the shell's
// projection and the table rendering's row set, order, emphasis and unlisted-node
// derivation, asserted with NO DOM at all.
//
// WHY THIS HALF EXISTS SEPARATELY FROM THE DOM HALF
//   `project()` is pure by contract and the table rendering's row/order/encoding
//   path is pure too -- it reads maps and returns records. So the majority of the
//   view's behaviour is assertable in a bare Node process with no browser, no
//   jsdom and no layout. That matters because jsdom is NOT a repository
//   dependency: everything provable here keeps running on a machine that has
//   nothing but Node, and only what genuinely needs a document is deferred to
//   graph-view-dom.mjs, which SKIPS LOUDLY when jsdom is absent.
//
// PROTOCOL
//   One tab-separated line per outcome on stdout:
//     GV \t PASS|FAIL|SKIP|NOTE \t <label>
//   The bash suite turns each into a real assert.sh pass/fail/skip, so the
//   counters, the failure list and the coverage-parity inventory all see them.
//
// USAGE
//   node graph-view-model.mjs <bundle.mjs> [--expect-fail ID,ID,...]
//
//   Plain mode exits 0 when every assertion passed, 1 otherwise.
//
//   --expect-fail is the NON-VACUITY MODE and it is the answer to the defect this
//   project keeps finding -- a suite whose assertions all pass a wrong
//   implementation. The bash suite mutates a COPY of the four view files, one
//   defect at a time, and runs this file against the mutated bundle asserting
//   that the named assertions FAIL. An assertion that cannot fail is not an
//   assertion, and this is how each class proves it can.
//   In that mode the exit code is 0 iff every named id failed AND no un-named id
//   failed for an unrelated reason is not required -- collateral failures are
//   reported as NOTEs, because one defect legitimately breaks several classes.

import { pathToFileURL } from 'node:url';

const bundlePath = process.argv[2];
if (!bundlePath) {
	process.stdout.write('GV\tFAIL\tGT00 harness — no bundle path was passed\n');
	process.exit(1);
}
let expectFail = null;
const efIndex = process.argv.indexOf('--expect-fail');
if (efIndex !== -1) expectFail = String(process.argv[efIndex + 1] || '').split(',').filter(Boolean);

const results = [];
function emit(kind, label) {
	results.push({ kind, label });
	if (expectFail === null) process.stdout.write('GV\t' + kind + '\t' + label + '\n');
}
function ok(id, label, condition, detail) {
	const text = id + ' ' + label + (detail === undefined || detail === null || detail === '' ? '' : ' [' + detail + ']');
	emit(condition ? 'PASS' : 'FAIL', condition ? text : text + ' — assertion did not hold');
	return !!condition;
}
function note(text) { emit('NOTE', text); }
const ids = (list) => Array.from(new Set(list)).sort();
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// ---------------------------------------------------------------------------
// Load the view under test, and the fixture
// ---------------------------------------------------------------------------
let M;
try {
	M = await import(pathToFileURL(bundlePath).href);
} catch (error) {
	// A load failure is a FAILURE and never a skip: the bundle is built by the
	// suite from files that are present by construction.
	emit('FAIL', 'GT00 the four view files load as one module — ' + (error && error.message ? error.message : error));
	process.stdout.write('GV\tFAIL\tGT00 the four view files load as one module\n');
	process.exit(1);
}
// Resolved relative to THIS module's own URL, so the suite's working directory
// does not matter.
const FX = await import('./graph-view-fixture.mjs');

const model = M.parseRelationships(FX.FIXTURE);
const store = M.createStore(model, M.INITIAL_LENS);
const vm = () => store.getViewModel();
const reset = () => store.setLens(M.INITIAL_LENS);

/** The rows the table lists, in the order it lists them. Built from the two
 *  exported units the rendering itself uses. */
function listed(viewModel, sort) {
	const records = M.tblRowRecords(viewModel);
	const s = sort || { column: M.TBL_FILE_ORDER, direction: 'asc' };
	records.sort((a, b) => M.tblCompareRows(a, b, s.column, s.direction));
	return records;
}
const listedRows = (viewModel, sort) => listed(viewModel, sort).map((r) => r.row);
const unlistedIds = (viewModel) => M.tblUnlistedNodes(viewModel).map((n) => n.id);
const collapsedRows = (viewModel) => viewModel.visibleEdges
	.filter((e) => viewModel.edgeFold.get(e.key) === 'collapsed').map((e) => e.row);

// ===========================================================================
// GT1x  The shell's loader and projection -- the ground both renderings stand on
// ===========================================================================
ok('GT10', 'the fixture parses to the row count it declares',
	model.rowCount === FX.FIXTURE_ROWS.length && model.rowCount > 0, model.rowCount + ' rows');
ok('GT10b', 'no identifier carries two kinds or two names in the fixture',
	model.kindConflicts.length === 0 && model.nameConflicts.length === 0);
ok('GT10c', 'the recomputed gap set agrees with the recorded one (status verified, no alarm)',
	model.integrity.status === 'verified' && model.integrity.viewOnly.length === 0
	&& model.integrity.ledgerOnly.length === 0, model.integrity.status);

const zero = model.nodes.get(FX.ZERO_ROW_NODE);
ok('GT11', 'the zero-row artifact reaches the page from the recorded gaps as a COMPLETE node record',
	!!zero && zero.kind === 'source-artifact' && zero.degree === 0
	&& vm().nodeLabels.get(FX.ZERO_ROW_NODE).endsWith('— no recorded relationships'),
	zero ? zero.kind + ', degree ' + zero.degree : 'absent');

ok('GT12', 'coverageGaps.artifactUndocumented equals the ledger ids -- the class AC-15 binds',
	same(ids(vm().coverageGaps.artifactUndocumented), ids(FX.LEDGER_IDS)),
	ids(vm().coverageGaps.artifactUndocumented).join(','));
ok('GT12b', 'coverageGaps.kbUnbacked is non-empty and shares no id with the ledger -- the lens-only class',
	vm().coverageGaps.kbUnbacked.length > 0
	&& vm().coverageGaps.kbUnbacked.every((id) => !FX.LEDGER_IDS.includes(id)),
	ids(vm().coverageGaps.kbUnbacked).join(','));

function commensurable(label) {
	const c = vm().counts;
	return ok('GT13', 'the two count pairs partition the loaded whole (' + label + ')',
		c.nodes + c.hiddenNodes === model.nodes.size && c.edges + c.hiddenEdges === model.rowCount,
		JSON.stringify(c));
}
commensurable('initial');
store.setLens({ grouping: 'document' });
commensurable('grouping=document');
reset();

let noFilterKey = true;
for (const patch of Object.values(M.PRESETS)) {
	if (Object.keys(patch).some((k) => k.indexOf('filters.') === 0)) noFilterKey = false;
}
ok('GT14', 'no preset patch touches the filters namespace, so a filter composes rather than resets',
	noFilterKey && Object.keys(M.PRESETS).length === 4);
ok('GT15', 'INITIAL_LENS states all fifteen fields (task-034 adds filters.hiddenIds), with sort at the file order',
	M.LENS_KEYS.length === 15 && M.LENS_KEYS.every((k) => Object.prototype.hasOwnProperty.call(M.INITIAL_LENS, k))
	&& same(M.INITIAL_LENS['sort'], { column: 'row', direction: 'asc' })
	&& same(M.INITIAL_LENS['filters.hiddenIds'], []));

// ===========================================================================
// GT2x  THE PREFIX ORACLE -- a class is never derived from an identifier
//
// A prefix is correct about WHERE a node came from and wrong about WHAT CLASS it
// belongs to: one kind is spelled with either of two prefixes and one prefix
// spans four kinds. The two halves below cannot both hold for any implementation
// that reads a prefix, and GT23 proves that rather than asserting it.
// ===========================================================================
const [extWeb, extImg] = FX.PREFIX_ORACLE.sameProxyDifferentKind;
const [intImg, extImg2] = FX.PREFIX_ORACLE.differentProxySameKind;
const enc = (id) => vm().nodeEncoding.get(id);
ok('GT20', 'two ext: ids of DIFFERENT kinds receive different colour tokens and different glyphs',
	enc(extWeb).colourToken !== enc(extImg).colourToken && enc(extWeb).glyph !== enc(extImg).glyph,
	enc(extWeb).colourToken + '/' + enc(extWeb).glyph + ' vs ' + enc(extImg).colourToken + '/' + enc(extImg).glyph);
ok('GT21', 'an int: image and an ext: image receive the SAME colour token and glyph',
	enc(intImg).colourToken === enc(extImg2).colourToken && enc(intImg).glyph === enc(extImg2).glyph,
	enc(intImg).colourToken + '/' + enc(intImg).glyph);

// The table's own consumption path, not just the projection it reads.
const endpointOf = (id) => {
	for (const record of listed(vm())) {
		if (record.source.id === id) return record.source;
		if (record.target.id === id) return record.target;
	}
	return null;
};
const eWeb = endpointOf(extWeb);
const eImg = endpointOf(extImg);
const eInt = endpointOf(intImg);
ok('GT22', 'the table\'s own cell values carry the same split: kind text, glyph and colour class',
	!!eWeb && !!eImg && !!eInt
	&& eWeb.kind !== eImg.kind && eWeb.glyph !== eImg.glyph && eWeb.kindClass !== eImg.kindClass
	&& eInt.kind === eImg.kind && eInt.glyph === eImg.glyph && eInt.kindClass === eImg.kindClass,
	eWeb ? [eWeb.kind + '/' + eWeb.kindClass, eImg.kind + '/' + eImg.kindClass, eInt.kind + '/' + eInt.kindClass].join('  ') : 'endpoint missing');

// NON-VACUITY, IN THE SUITE: a prefix-keyed reference implementation -- the exact
// defect a sibling shipped -- gets BOTH halves wrong on this fixture. So GT20-GT22
// cannot be satisfied by an implementation that reads the id, and the fixture is
// proven to discriminate rather than assumed to.
const PREFIX_KIND = { kb: 'document', int: 'source-artifact', ext: 'web-page' };
const prefixDerived = (id) => M.KIND_ENCODING[PREFIX_KIND[String(id).slice(0, String(id).indexOf(':'))]];
ok('GT23', 'a prefix-deriving implementation would collide the different-kind pair AND split the same-kind pair',
	prefixDerived(extWeb).glyph === prefixDerived(extImg).glyph
	&& prefixDerived(intImg).glyph !== prefixDerived(extImg2).glyph,
	'prefix-derived: ' + prefixDerived(extWeb).glyph + '==' + prefixDerived(extImg).glyph
	+ ', ' + prefixDerived(intImg).glyph + '!=' + prefixDerived(extImg2).glyph);
ok('GT24', 'a colour TOKEN NAME maps to the shared stylesheet class, and a non-palette token maps to nothing',
	M.tblTokenClass('--gk-image') === 'k-image' && M.tblTokenClass('--gc-taxonomy') === 'c-taxonomy'
	&& M.tblTokenClass('--accent') === '' && M.tblTokenClass(null) === '');

// ===========================================================================
// GT3x  Membership and order -- a permutation of the unfolded rows, never a
//       selection, and never a row the fold collapsed
// ===========================================================================
function membership(label) {
	const viewModel = vm();
	const expected = viewModel.visibleEdges
		.filter((e) => viewModel.edgeFold.get(e.key) !== 'collapsed').map((e) => e.row).sort((a, b) => a - b);
	const got = listedRows(viewModel).sort((a, b) => a - b);
	const collapsed = collapsedRows(viewModel);
	// The non-emptiness clause is not decoration: a set equality between two EMPTY
	// sets is satisfied by an implementation that lists nothing at all, which is
	// exactly the vacuous pass this project keeps finding. The one state where an
	// empty listing IS the correct answer is asserted separately, by GT62.
	const held = ok('GT30', 'listed rows equal the unfolded rows, set equality BOTH directions (' + label + ')',
		same(got, expected) && expected.length > 0,
		'listed=' + got.join(',') + ' expected=' + expected.join(','));
	ok('GT31', 'nothing is listed for a collapsed fold entry (' + label + ')',
		collapsed.every((row) => !got.includes(row)), collapsed.length + ' collapsed');
	return held;
}
membership('initial');
store.setLens({ grouping: 'document' });
const foldedCollapsed = collapsedRows(vm());
membership('grouping=document');
ok('GT31b', 'the folding dimension actually collapses rows, so GT31 has a subject',
	foldedCollapsed.length > 0, 'collapsed rows ' + foldedCollapsed.join(','));
for (const preset of Object.keys(M.PRESETS)) { store.applyPreset(preset); membership('preset ' + preset); }
reset();

// Parity with the fixture's own rows: EXACT at grouping none.
const CATEGORY_RELATIONS = { structure: ['has-part', 'part-of'], evidence: ['cites-as-evidence', 'cited-as-evidence-by'] };
const fixtureRowsFor = (cats) => FX.FIXTURE_ROWS
	.filter((r) => cats.some((c) => CATEGORY_RELATIONS[c].includes(r.s2t))).map((r) => r.row).sort((a, b) => a - b);
store.setLens({ 'filters.categories': ['structure'] });
const exact = fixtureRowsFor(['structure']);
ok('GT32', 'at grouping=none a single-category filter lists EXACTLY the fixture rows carrying that category',
	same(listedRows(vm()).sort((a, b) => a - b), exact) && exact.length > 0 && exact.length < FX.FIXTURE_ROWS.length,
	'listed=' + listedRows(vm()).sort((a, b) => a - b).join(',') + '  fixture=' + exact.join(','));
ok('GT32b', 'and the drawn row count the caption reports equals it', vm().counts.edges === exact.length,
	vm().counts.edges + ' vs ' + exact.length);
let composed = true;
for (const preset of Object.keys(M.PRESETS)) {
	store.applyPreset(preset);
	if (!same(store.getLens()['filters.categories'], ['structure'])) composed = false;
}
ok('GT32c', 'every preset composes with that filter rather than resetting it', composed);

// Under a FOLDING dimension the equality is ill-posed once a same-group row
// exists, so the shortfall is QUANTIFIED and no stronger claim is made.
for (const cats of [['structure'], ['structure', 'evidence']]) {
	store.setLens(Object.assign({}, M.INITIAL_LENS, { 'filters.categories': cats, grouping: 'document' }));
	const fixture = fixtureRowsFor(cats);
	const collapsed = collapsedRows(vm());
	const got = listedRows(vm()).sort((a, b) => a - b);
	ok('GT33', 'under grouping=document the listed set is the fixture\'s category rows MINUS the collapsed ones (' + cats.join('+') + ')',
		same(got, fixture.filter((r) => !collapsed.includes(r))),
		'fixture=' + fixture.join(',') + ' collapsed=' + collapsed.join(',') + ' listed=' + (got.join(',') || '(none)'));
	note('GT33 shortfall under a folding dimension, ' + cats.join('+') + ': ' + collapsed.length + ' of '
		+ fixture.length + ' fixture rows collapse, so parity with relationships.md is ill-posed here and is not claimed');
}
reset();

// The comparator.
const fileOrder = listedRows(vm());
ok('GT34', 'the file order is ascending by file row index',
	same(fileOrder, fileOrder.slice().sort((a, b) => a - b)) && fileOrder.length > 1);
const asc = listedRows(vm(), { column: 'provenance', direction: 'asc' });
const desc = listedRows(vm(), { column: 'provenance', direction: 'desc' });
ok('GT34b', 'each order is a permutation of one row multiset -- never an addition or a removal',
	same(asc.slice().sort((a, b) => a - b), fileOrder.slice().sort((a, b) => a - b))
	&& same(desc.slice().sort((a, b) => a - b), fileOrder.slice().sort((a, b) => a - b)));
const ascValues = listed(vm(), { column: 'provenance', direction: 'asc' }).map((r) => r.values['provenance']);
ok('GT35', 'over a multi-valued column the two directions differ, and ascending is by code unit',
	!same(asc, desc) && same(ascValues, ascValues.slice().sort()) && new Set(ascValues).size > 1,
	ascValues.join(','));
const uniformAsc = listedRows(vm(), { column: 'observation', direction: 'asc' });
const uniformDesc = listedRows(vm(), { column: 'observation', direction: 'desc' });
const uniformValues = new Set(listed(vm()).map((r) => r.values['observation']));
ok('GT36', 'over a UNIFORM column both directions equal the file order -- D2\'s tie-break, not a defect',
	same(uniformAsc, fileOrder) && same(uniformDesc, fileOrder) && uniformValues.size === 1,
	'distinct values ' + uniformValues.size);
function ties(direction) {
	return listed(vm(), { column: 'source-id', direction: direction })
		.filter((r) => r.values['source-id'] === 'kb:alpha.md').map((r) => r.row);
}
const tAsc = ties('asc');
const tDesc = ties('desc');
ok('GT37', 'rows tying on the sorted column order by file row ASCENDING in both directions',
	tAsc.length > 1 && same(tAsc, tAsc.slice().sort((a, b) => a - b)) && same(tDesc, tDesc.slice().sort((a, b) => a - b)),
	'asc=' + tAsc.join(',') + ' desc=' + tDesc.join(','));
ok('GT38', 'the header cycle is ascending, descending, then the file order',
	same(M.tblNextSort({ column: 'row', direction: 'asc' }, 'provenance'), { column: 'provenance', direction: 'asc' })
	&& same(M.tblNextSort({ column: 'provenance', direction: 'asc' }, 'provenance'), { column: 'provenance', direction: 'desc' })
	&& same(M.tblNextSort({ column: 'provenance', direction: 'desc' }, 'provenance'), { column: 'row', direction: 'asc' }));
const ariaFor = (sort) => M.TBL_COLUMNS.map((c) => M.tblAriaSort(sort, c.token));
ok('GT38b', 'aria-sort is none on all six (task-034 slims TBL_COLUMNS from ten) at the file order and non-none on EXACTLY one otherwise',
	ariaFor({ column: 'row', direction: 'asc' }).every((v) => v === 'none')
	&& ariaFor({ column: 'provenance', direction: 'desc' }).filter((v) => v !== 'none').length === 1
	&& ariaFor({ column: 'provenance', direction: 'desc' }).includes('descending')
	&& M.TBL_COLUMNS.length === 6);
ok('GT39', 'an out-of-domain sort column normalises to the file order ascending, not to a reversed file order',
	same(M.tblSortOf({ sort: { column: 'not-a-column', direction: 'desc' } }), { column: 'row', direction: 'asc' })
	&& same(M.tblSortOf({}), { column: 'row', direction: 'asc' })
	&& M.TBL_SORT_COLUMNS.size === 7);
ok('GT40', 'no sort changes the listed row SET',
	same(ids(asc.map(String)), ids(fileOrder.map(String))) && same(ids(desc.map(String)), ids(fileOrder.map(String))));

// ===========================================================================
// GT5x  Emphasis -- and `dimmed` as the COMPLEMENT of the marked set
//
// This is the defect the table's own author found by reading the rendered output:
// taking `dimmed` from either map unconditionally dims a row that carries a gap
// badge, because under the Coverage lens every non-gap node is dimmed. Then "this
// row carries no text badge" stops being what the de-emphasis means -- and that
// equivalence is the whole of the no-colour-only argument.
// ===========================================================================
store.applyPreset('coverage');
const covRecords = listed(vm());
const marked = covRecords.filter((r) => r.marked);
const dimmed = covRecords.filter((r) => r.dimmed);
ok('GT50', 'under the Coverage lens the marked and dimmed row sets PARTITION the listed rows',
	marked.length > 0 && dimmed.length > 0
	&& marked.length + dimmed.length === covRecords.length
	&& covRecords.length === vm().counts.edges
	&& covRecords.every((r) => !(r.marked && r.dimmed)),
	marked.length + ' marked + ' + dimmed.length + ' dimmed = ' + covRecords.length);
ok('GT50b', 'a row carrying a gap badge is never in the dimmed remainder',
	marked.every((r) => !r.dimmed) && marked.some((r) => r.source.emphasis === 'artifact-undocumented'
		|| r.target.emphasis === 'artifact-undocumented' || r.source.emphasis === 'kb-unbacked'
		|| r.target.emphasis === 'kb-unbacked'));
const emphasisValues = new Set(Array.from(vm().nodeEmphasis.values()));
ok('GT51', 'every drawn node carries exactly one of the five emphasis values',
	vm().nodeEmphasis.size === vm().visibleNodes.length
	&& Array.from(emphasisValues).every((v) => ['normal', 'dimmed', 'kb-unbacked', 'artifact-undocumented', 'focus'].includes(v)),
	Array.from(emphasisValues).sort().join(','));
const badgedGap = ids(vm().visibleNodes.filter((n) => vm().nodeEmphasis.get(n.id) === 'artifact-undocumented').map((n) => n.id));
const badgedUnbacked = ids(vm().visibleNodes.filter((n) => vm().nodeEmphasis.get(n.id) === 'kb-unbacked').map((n) => n.id));
ok('GT52', 'the two gap classes land on exactly the two coverage sets, and are distinct sets',
	same(badgedGap, ids(vm().coverageGaps.artifactUndocumented))
	&& same(badgedUnbacked, ids(vm().coverageGaps.kbUnbacked))
	&& badgedGap.length > 0 && badgedUnbacked.length > 0
	&& badgedGap.every((id) => !badgedUnbacked.includes(id)),
	badgedGap.length + ' undocumented, ' + badgedUnbacked.length + ' unbacked');

// TV07's TRUE behaviour. The SPEC clause -- feature-009 SPEC.md:536 and its TV07
// row -- says the listed row set is "untouched" when a gap endpoint is then
// selected. Against the frozen upstream that is FALSE: project() restricts
// visibleEdges to the focus ball, so a selection MOVES MEMBERSHIP. The true
// behaviour is asserted here and the false clause is deliberately not encoded.
const beforeSelect = listedRows(vm()).length;
store.setLens({ 'focus.nodeId': 'int:tests/orphan-check.sh' });
const afterSelect = listedRows(vm()).length;
ok('GT53', 'selecting a gap endpoint marks THAT id focus and leaves every other gap id its own class',
	vm().nodeEmphasis.get('int:tests/orphan-check.sh') === 'focus'
	&& ids(vm().visibleNodes.filter((n) => vm().nodeEmphasis.get(n.id) === 'artifact-undocumented').map((n) => n.id))
		.every((id) => id !== 'int:tests/orphan-check.sh'));
ok('GT53b', 'and a selection DOES move the listed row set -- the projection restricts rows to the focus ball',
	afterSelect !== beforeSelect && afterSelect > 0, beforeSelect + ' rows -> ' + afterSelect + ' rows');
note('GT53b feature-009 SPEC.md:536 and TV07 state that the listed row set is "untouched" when a gap endpoint '
	+ 'is selected. Measured against the frozen graph-model.js it goes ' + beforeSelect + ' -> ' + afterSelect
	+ ' rows, because project() drops every row with an endpoint outside the focus ball. That clause needs '
	+ 're-wording (or a depth high enough to cover the graph); the true behaviour is what GT53b asserts.');
let focusWins = true;
for (const emphasis of ['none', 'coverage', 'provenance-chain']) {
	store.setLens(Object.assign({}, M.INITIAL_LENS, { emphasis: emphasis, 'focus.nodeId': 'kb:concept:graph-view' }));
	if (vm().nodeEmphasis.get('kb:concept:graph-view') !== 'focus') focusWins = false;
}
ok('GT54', 'the selection takes the emphasis slot under every emphasis value -- so the reveal\'s trigger always exists',
	focusWins);
reset();
store.applyPreset('provenance');
const chainRecords = listed(vm());
ok('GT55', 'the Provenance lens marks the chain rows and dims the rest -- both sets non-empty',
	chainRecords.some((r) => r.edgeEmphasis === 'chain') && chainRecords.some((r) => r.edgeEmphasis === 'dimmed')
	&& chainRecords.every((r) => ['chain', 'dimmed', 'normal'].includes(r.edgeEmphasis)),
	chainRecords.filter((r) => r.edgeEmphasis === 'chain').length + ' chain, '
	+ chainRecords.filter((r) => r.edgeEmphasis === 'dimmed').length + ' dimmed');
reset();

// ===========================================================================
// GT6x  The unlisted-nodes set -- derived over the FOLD, never over `degree`
// ===========================================================================
function everyNodeNamed(label) {
	const viewModel = vm();
	const named = ids(listed(viewModel).flatMap((r) => [r.source.id, r.target.id]).concat(unlistedIds(viewModel)));
	const expect = ids(viewModel.visibleNodes.map((n) => n.id));
	const missing = expect.filter((id) => !named.includes(id));
	return ok('GT63', 'every drawn node is named in the table region (' + label + ')',
		missing.length === 0 && expect.length > 0, missing.length ? 'missing=' + missing.join(',') : expect.length + ' drawn');
}
everyNodeNamed('initial');
ok('GT60', 'population 1 -- the zero-row artifact is in the unlisted set',
	unlistedIds(vm()).includes(FX.ZERO_ROW_NODE), unlistedIds(vm()).join(','));

store.setLens({ grouping: 'document' });
everyNodeNamed('grouping=document');
const foldOnlyDegree = model.nodes.get(FX.FOLD_ONLY_NODE).degree;
const byDegree = ids(vm().visibleNodes.filter((n) => n.degree === 0).map((n) => n.id));
ok('GT61', 'population 2 -- a document whose every row the fold collapsed is in the unlisted set',
	unlistedIds(vm()).includes(FX.FOLD_ONLY_NODE), unlistedIds(vm()).join(','));
ok('GT61b', 'and a degree===0 rule would MISS it, which is why the derivation is over the fold',
	foldOnlyDegree > 0 && !byDegree.includes(FX.FOLD_ONLY_NODE),
	FX.FOLD_ONLY_NODE + ' degree ' + foldOnlyDegree + '; degree-rule set = ' + byDegree.join(','));
reset();

store.setLens(Object.assign({}, M.INITIAL_LENS, { 'filters.categories': ['structure'], 'focus.nodeId': FX.FILTERED_OUT_NODE }));
everyNodeNamed('a selected node whose every row a filter removed');
ok('GT62', 'population 3 -- the selected node with no surviving row is in the unlisted set, and the listed set is empty',
	unlistedIds(vm()).includes(FX.FILTERED_OUT_NODE) && listedRows(vm()).length === 0,
	'unlisted=' + unlistedIds(vm()).join(',') + ' listed=' + listedRows(vm()).length);
reset();
ok('GT64', 'a node whose rows were merely FILTERED out is not in the unlisted set -- it is not drawn at all',
	(() => {
		store.setLens({ 'filters.categories': ['structure'] });
		const drawn = new Set(vm().visibleNodes.map((n) => n.id));
		const out = !drawn.has('ext:mdn-webgl') && !unlistedIds(vm()).includes('ext:mdn-webgl');
		reset();
		return out;
	})());

// ===========================================================================
// GT7x  Each preset changes what the table renders (AC-7 table side)
// ===========================================================================
const snapshot = () => JSON.stringify({
	rows: listedRows(vm()), unlisted: unlistedIds(vm()), counts: vm().counts,
	summary: vm().lensSummary,
	emphasis: listed(vm()).map((r) => [r.source.emphasis, r.target.emphasis, r.edgeEmphasis]),
});
const initialSnapshot = snapshot();
for (const preset of Object.keys(M.PRESETS)) {
	reset();
	// Impact keeps the current selection and PROMPTS for one when unset, so from a
	// pristine state its patch differs from INITIAL_LENS only on `focus.depth`,
	// which with no selection reaches no ViewModel field at all: the projection,
	// the caption and the rows are then byte-identical. Its parity is therefore
	// asserted WITH a selection present -- the shell's prompt behaviour, not the
	// table's. TV01 read literally cannot hold for `impact` from a pristine state.
	if (preset === 'impact') store.setLens({ 'focus.nodeId': 'kb:alpha.md' });
	const base = preset === 'impact' ? snapshot() : initialSnapshot;
	store.applyPreset(preset);
	ok('GT70', 'preset ' + preset + ' visibly changes what the table renders', snapshot() !== base);
}
reset();
note('GT70 the `impact` preset is compared against a state WITH a selection: its patch differs from INITIAL_LENS '
	+ 'only on focus.depth, which reaches no ViewModel field while focus.nodeId is null, so from a pristine state '
	+ 'the rendered table is byte-identical. TV01 needs that qualifier.');

// ===========================================================================
// Verdict
// ===========================================================================
const failed = results.filter((r) => r.kind === 'FAIL');
if (expectFail !== null) {
	// Non-vacuity mode: report which of the named assertion ids failed.
	const failedIds = new Set(failed.map((r) => r.label.split(' ')[0]));
	const missing = expectFail.filter((id) => !failedIds.has(id));
	const collateral = Array.from(failedIds).filter((id) => !expectFail.includes(id)).sort();
	for (const id of expectFail) {
		process.stdout.write('GV\t' + (failedIds.has(id) ? 'PASS' : 'FAIL')
			+ '\t' + id + ' fails against the mutated implementation'
			+ (failedIds.has(id) ? '' : ' — it did NOT fail, so the assertion cannot detect this defect') + '\n');
	}
	if (collateral.length > 0) {
		process.stdout.write('GV\tNOTE\tone defect also broke: ' + collateral.join(', ') + '\n');
	}
	process.exit(missing.length === 0 ? 0 : 1);
}
process.exit(failed.length === 0 ? 0 : 1);
