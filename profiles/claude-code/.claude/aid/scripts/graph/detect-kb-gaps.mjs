#!/usr/bin/env node
// detect-kb-gaps.mjs -- the knowledge-base gap ledger for one /aid-graph run.
//
// Purpose:
//   Join the enumerated source-artifact inventory to the final relationship
//   table, ask the one shared coverage predicate which of those artifacts no
//   knowledge-base node accounts for, and report the answer three ways: as a
//   seven-column reviewer ledger, as the durable `kb_gaps` record in the table's
//   own frontmatter, and as a routing block on stdout. It repairs nothing, files
//   nothing, and never fails because gaps exist.
//
// Usage:
//   node detect-kb-gaps.mjs --table PATH --nodes PATH --output PATH [--previous PATH]
//   node detect-kb-gaps.mjs --explain NODE_ID --table PATH --nodes PATH
//   node detect-kb-gaps.mjs --help
//
// Flags:
//   --table PATH       the final post-extraction relationship table. Read in both
//                      modes; in write mode its frontmatter `kb_gaps:` key is
//                      rewritten, which is the only write outside --output
//   --nodes PATH       the enumerated source-artifact inventory: TSV, no header
//   --output PATH      where the gap ledger is written (write mode only)
//   --previous PATH    the previous run's ledger, for the Status transitions.
//                      Optional, and a path that does not exist means cycle 1
//   --explain NODE_ID  read-only mode: print the table rows naming that artifact,
//                      the relation toward it on each, and the coverage verdict.
//                      This is the recheck every ledger row's Evidence cell spells
//                      out, so it writes nothing at all
//   -h, --help         print the usage block and exit 0
//
//   Every path arrives through a flag: there is no baked-in default anywhere, no
//   flag for the media-node stream (not an input to this detector -- a detector
//   that could read it is a detector that could enumerate from it), and no
//   vocabulary flag (the coverage-bearing set is a constant inside the shared
//   predicate module, and passing a second copy in at run time would create a way
//   for the two to disagree).
//
// Exit codes:
//   0 -- success, whatever the gap count. Reporting never gates: a run that finds
//        five hundred gaps exits 0 exactly like a run that finds none. --explain
//        and --help also exit 0
//   2 -- usage, argument or input-contract error. No other code is defined,
//        because no other outcome exists. A candidate row of another kind, or a
//        qualifier outside the four-value enum, is a scanner bug: it aborts with
//        no ledger written rather than degrading into a defaulted severity
//
// Output:
//   stdout -- the routing block (gap count and severity breakdown, the
//             no-relationship slice, the cluster line, the extension-relation
//             counter, the ledger path with its retention statement, and the two
//             skills that own knowledge-base repair), or the --explain report
//   stderr -- diagnostics only, every line prefixed `detect-kb-gaps.mjs: `
//
// Three rules for a later editor, each of which a past defect paid for:
//   1. the coverage predicate is NOT implemented here and must never be. This
//      file imports the one shared module and calls it; two runtimes execute
//      those same bytes, which is what makes this ledger and the view's Coverage
//      lens agree structurally instead of by two prose readings matching;
//   2. a node's kind is read as DATA -- from the inventory's `node_kind` field
//      and from the table's own two Kind columns -- and is never recovered from
//      an id prefix. The single prefix test below is lexical: an id of the
//      path-bearing form IS its repo-relative path with the prefix removed, which
//      is what the ledger's Doc cell needs. That is a question about spelling,
//      not about class;
//   3. this file is text-processed when the profile generator renders it, so it
//      carries no install-tree path reference and none of the three filename
//      placeholders. Nothing here needs one.

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

// A sibling in this same directory, so the specifier is a plain relative path
// with no resolution machinery behind it and the `.mjs` extension alone makes it
// resolve -- no package marker file is needed here or above. Exactly two names
// are bound: the predicate for the gap set, and the core relation keys for the
// extension-relation counter.
import { detectArtifactGaps, RELATION_CATEGORY } from './coverage-predicate.mjs';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const SCRIPT = 'detect-kb-gaps.mjs';

// The inventory record's field map, bound once. "Reading a field by name" cannot
// mean "looking it up in a header", because the stream has none; it means every
// read goes through this one map, so a rename upstream is a one-line change and
// no field index appears at a call site.
//
// Two entries are deliberately never read. `artifact_class` is absent from every
// decision here -- severity is a total function of `qualifier` alone, and a
// per-class carve-out would break that totality. `evidence_provenance` is the
// enumerator's own invariant (a candidate only a reading would qualify is never
// emitted as a node), so re-testing it here would be a second, weaker copy of
// another component's rule.
const NODE_FIELDS = Object.freeze({
	node_id: 0, name: 1, artifact_class: 2, qualifier: 3,
	evidence: 4, evidence_provenance: 5, node_kind: 6,
});

const NODE_FIELD_COUNT = 7;

// The candidate class, asserted on every inventory row. This is the whole reason
// the gap class is a kind and not a prefix: the path-bearing prefix also spans
// in-repo images, and an unreferenced picture is not undocumented project source
// -- it carries no significance qualifier for a severity to derive from.
const CANDIDATE_KIND = 'source-artifact';

// The prefix an enumerated artifact's id carries. Read for exactly one thing:
// stripping it yields the repo-relative path the Doc cell must be openable at.
const ID_PATH_PREFIX = 'int:';

// Severity derives from the four-value significance qualifier -- derivable, never
// judged, and total over the enum. `entry-point` and `public-surface` are one
// significance clause with two values and carry the same consequence, so the
// function is constant there. Two severities are never assigned: `[CRITICAL]` is
// reserved for what breaks tooling, and a documentation gap breaks nothing at run
// time; `[MINOR]` would let a reviewer sort the whole ledger to the bottom of
// their queue, and no gap is cosmetic. A qualifier outside this enum is exit 2,
// never a defaulted rank.
const SEVERITY_BY_QUALIFIER = Object.freeze({
	'entry-point': 'HIGH',
	'public-surface': 'HIGH',
	'depended-upon': 'MEDIUM',
	'named-unit': 'LOW',
});

// Reporting order for the severity breakdown, stated explicitly so no output
// depends on object key iteration order.
const SEVERITY_ORDER = Object.freeze(['HIGH', 'MEDIUM', 'LOW']);

// The six cells of the ten-column row this file consumes, read by name out of the
// table's own header row and never by a hardcoded index. Four build the
// predicate's edge record; the two relation cells carry the direction rule and
// feed the extension-relation counter. The contract is asserted on exactly the
// cells that are consumed -- the remaining four columns are another component's
// to validate.
const TABLE_COLUMNS = Object.freeze([
	'Source Id', 'Source Kind', 'Target Id', 'Target Kind', 'S2T Relation', 'T2S Relation',
]);

// The heading the table's parse contract starts from: the first non-blank line
// after it is the header row, and the table ends at the first line that is not a
// table row. A parser obeying both never reads the coverage notes below it.
const TABLE_HEADING = '# Relationships';

// The project-wide reviewer-ledger shape. Seven columns, one table, nothing else
// in the file -- no frontmatter, no heading, no summary section, no narrative.
const LEDGER_HEADER_ROW = '| # | Severity | Status | Doc | Line | Description | Evidence |';
const LEDGER_DELIMITER_ROW = '|---|---|---|---|---|---|---|';
const LEDGER_CELL_COUNT = 7;

// The Line cell, always. Source-code granularity is fixed at the whole artifact,
// so there is no line to name and inventing one would contradict that. Written as
// its code point, so this file stays pure ASCII like the module beside it.
const EM_DASH = String.fromCharCode(0x2014);

// The three Status values a generator may write. The schema's other three --
// Accepted, OOS and Invalid -- are human-cycle values whose actors are an
// orchestrator, a reviewer, or a user authorization; a generator is none of
// those, so a previous row already carrying one is preserved untouched rather
// than recomputed.
const GENERATOR_STATUS = Object.freeze(new Set(['Pending', 'Fixed', 'Recurred']));

// The core vocabulary's relation names. A row typed by anything outside this set
// is a project extension, and the coverage-bearing set is a compile-time constant
// that an extension cannot widen -- so such a row may make an artifact look
// undocumented when it is not. That blind spot is reported as a count rather than
// described as a caveat. Built as a Set of own keys on purpose: `in` would answer
// true for inherited names such as `constructor`.
const CORE_RELATIONS = new Set(Object.keys(RELATION_CATEGORY));

// ---------------------------------------------------------------------------
// Small utilities
// ---------------------------------------------------------------------------

/**
 * The one failure this script defines: a usage, argument or input-contract
 * error. Carried as a thrown value rather than an immediate `process.exit`, for
 * two reasons that both matter. Node's stdout and stderr are asynchronous when
 * they are a pipe on POSIX and when they are a terminal on Windows, so exiting
 * inside a deep call can truncate the very message that explains the exit; and a
 * throw genuinely unwinds, which makes the code after every call site
 * unreachable in fact and not only by convention.
 */
class InputError extends Error {}

/**
 * Abort with a usage, argument or input-contract error. Every call site is
 * reached before any file is written, so an aborted run leaves no ledger behind.
 *
 * @param {string} message actionable, with the resolved path for a file error
 * @returns {never}
 */
function fail(message) {
	throw new InputError(message);
}

/**
 * Split text into lines, tolerating a stray carriage return so a CRLF checkout
 * produces a clear verdict rather than a baffling one about a field value ending
 * in an invisible character.
 *
 * @param {string} raw
 * @returns {string[]}
 */
function splitLines(raw) {
	return raw.split('\n').map((line) => (line.endsWith('\r') ? line.slice(0, -1) : line));
}

/**
 * Compare two strings by UTF-16 code unit, ascending. Locale-independent, so a
 * sorted output is byte-stable across machines; `localeCompare` would not be.
 *
 * @param {string} a
 * @param {string} b
 * @returns {number}
 */
function compareText(a, b) {
	if (a < b) return -1;
	if (a > b) return 1;
	return 0;
}

/**
 * Read a text file, or abort naming the resolved absolute path.
 *
 * @param {string} pathValue the value the flag carried
 * @param {string} label what the file is, for the message
 * @returns {string}
 */
function readTextFile(pathValue, label) {
	try {
		return readFileSync(pathValue, 'utf8');
	} catch (error) {
		return fail(`cannot read the ${label} at ${resolve(pathValue)} (${error.code || error.message})`);
	}
}

/**
 * Is this line part of a markdown pipe table?
 *
 * @param {string} line
 * @returns {boolean}
 */
function isTableLine(line) {
	return line.trim().startsWith('|');
}

/**
 * Split one pipe-table row into trimmed cells.
 *
 * A bare split on `|` would break exactly the rows most likely to need care: the
 * schema escapes a literal pipe inside a cell as `\|`, and a display name
 * reproducing a quoted anchor may legitimately carry one. A well-formed row opens
 * and closes with a delimiter, so the empty fragments at either end are not cells.
 *
 * @param {string} line
 * @returns {string[]}
 */
function splitRow(line) {
	const text = line.trim();
	const parts = [];
	let current = '';
	for (let i = 0; i < text.length; i += 1) {
		if (text[i] === '\\' && text[i + 1] === '|') {
			current += '|';
			i += 1;
		} else if (text[i] === '|') {
			parts.push(current);
			current = '';
		} else {
			current += text[i];
		}
	}
	parts.push(current);
	if (parts.length >= 2 && parts[0].trim() === '' && parts[parts.length - 1].trim() === '') {
		return parts.slice(1, -1).map((part) => part.trim());
	}
	return parts.map((part) => part.trim());
}

/**
 * Is this the delimiter row under a table header?
 *
 * @param {string[]} cells
 * @returns {boolean}
 */
function isDelimiterRow(cells) {
	return cells.length > 0 && cells.every((cell) => /^:?-+:?$/.test(cell));
}

/**
 * Escape a value for a markdown table cell, per the schema's pipe rule.
 *
 * @param {string} value
 * @returns {string}
 */
function escapeCell(value) {
	return value.replace(/\|/g, '\\|');
}

/**
 * Quote a value for the restricted YAML the frontmatter carries.
 *
 * @param {string} value
 * @returns {string}
 */
function quoteYaml(value) {
	return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

/**
 * The usage block. Every flag it documents is parsed and used below -- a help
 * text advertising a flag its script ignores is a lie the reader cannot check.
 *
 * @returns {string[]}
 */
function usageLines() {
	return [
		`Usage: node ${SCRIPT} --table PATH --nodes PATH --output PATH [--previous PATH]`,
		`       node ${SCRIPT} --explain NODE_ID --table PATH --nodes PATH`,
		`       node ${SCRIPT} --help`,
		'',
		'  --table PATH       the final relationship table. Read in both modes; in write',
		'                     mode its frontmatter kb_gaps: key is rewritten',
		'  --nodes PATH       the enumerated source-artifact inventory (TSV, no header)',
		'  --output PATH      where the seven-column gap ledger is written (write mode)',
		"  --previous PATH    the previous run's ledger, for the Status transitions.",
		'                     Optional; a path that does not exist means cycle 1',
		'  --explain NODE_ID  read-only: print the table rows naming that artifact, the',
		'                     relation toward it on each, and the coverage verdict',
		'  -h, --help         print this block and exit 0',
		'',
		'Exit 0 whatever the gap count -- this reports, it does not gate. Exit 2 for a',
		'usage, argument or input-contract error, with no ledger written.',
	];
}

/**
 * Parse the command line into one of the two modes, or into the help request
 * that is neither. Every path is null until a flag supplies it, which is what
 * "no baked-in default" means in code rather than in prose.
 *
 * @param {string[]} argv
 * @returns {{mode: ('write'|'explain'|'help'), table: string|null, nodes: string|null, output: string|null, previous: string|null, explain: string|null}}
 */
function parseArgs(argv) {
	const options = { table: null, nodes: null, output: null, previous: null, explain: null };
	// A Map, not an object literal: a lookup on an object would answer `--toString`
	// with an inherited member and report an unknown flag as a repeated one.
	const valueFlags = new Map([
		['--table', 'table'], ['--nodes', 'nodes'], ['--output', 'output'],
		['--previous', 'previous'], ['--explain', 'explain'],
	]);

	for (let i = 0; i < argv.length; i += 1) {
		const arg = argv[i];
		if (arg === '-h' || arg === '--help') {
			usageLines().forEach((line) => console.log(line));
			return { mode: 'help', ...options };
		}
		const key = valueFlags.get(arg);
		if (key === undefined) fail(`unknown argument "${arg}" -- run with --help for the two supported modes`);
		if (options[key] !== null) fail(`${arg} given more than once`);
		const value = argv[i + 1];
		// A flag in a value position is a missing value, not a path: no input this
		// script takes is spelled with a leading dash, so reading one as a filename
		// would turn a usage slip into a confusing missing-file error one step later.
		if (value === undefined || value.startsWith('-')) fail(`${arg} requires a value`);
		options[key] = value;
		i += 1;
	}

	if (options.explain !== null) {
		if (options.output !== null) fail('--output is a write-mode flag and --explain writes nothing');
		if (options.previous !== null) fail('--previous is a write-mode flag and --explain writes nothing');
		if (options.table === null || options.nodes === null) {
			fail('--explain requires --table PATH and --nodes PATH, both explicit -- no path has a default');
		}
		return { mode: 'explain', ...options };
	}

	if (options.table === null || options.nodes === null || options.output === null) {
		usageLines().forEach((line) => console.error(line));
		fail('write mode requires --table PATH, --nodes PATH and --output PATH');
	}
	return { mode: 'write', ...options };
}

// ---------------------------------------------------------------------------
// The candidate inventory
// ---------------------------------------------------------------------------

/**
 * Read the enumerated inventory, asserting the input contract on every field
 * this script consumes.
 *
 * The kind assertion is what turns "correct because the stream happens to hold
 * one kind" into "correct because the kind is checked": the constant is carried
 * as data by the producer precisely so a consumer can test it, and this is the
 * consumer that makes that carriage pay.
 *
 * @param {string} nodesPath the value --nodes carried
 * @param {string} raw file contents
 * @returns {{ids: string[], byId: Map<string, {id: string, name: string, path: string, qualifier: string, evidence: string}>}}
 */
function parseNodes(nodesPath, raw) {
	const byId = new Map();
	const ids = [];
	const lines = splitLines(raw);

	for (let i = 0; i < lines.length; i += 1) {
		const line = lines[i];
		if (line.trim() === '') continue;
		const at = `${nodesPath} line ${i + 1}`;
		const fields = line.split('\t');
		if (fields.length !== NODE_FIELD_COUNT) {
			fail(`${at}: ${fields.length} tab-separated fields, the node record declares ${NODE_FIELD_COUNT}`);
		}

		const id = fields[NODE_FIELDS.node_id];
		const kind = fields[NODE_FIELDS.node_kind];
		const qualifier = fields[NODE_FIELDS.qualifier];
		const name = fields[NODE_FIELDS.name];
		const evidence = fields[NODE_FIELDS.evidence];

		if (id === '') fail(`${at}: field node_id is empty`);
		if (kind !== CANDIDATE_KIND) {
			fail(`${at}: field node_kind is "${kind}" for "${id}" -- every candidate row must carry node_kind "${CANDIDATE_KIND}"`);
		}
		if (!id.startsWith(ID_PATH_PREFIX) || id.length === ID_PATH_PREFIX.length) {
			// Lexical, not a class test: the Doc cell is this id with the prefix
			// removed, which is undefined for an id not spelled that way and empty
			// for an id that is nothing but the prefix.
			fail(`${at}: field node_id is "${id}", which is not "${ID_PATH_PREFIX}" followed by a repo-relative path -- the ledger's Doc cell is that id with the prefix removed`);
		}
		if (!Object.prototype.hasOwnProperty.call(SEVERITY_BY_QUALIFIER, qualifier)) {
			fail(`${at}: field qualifier is "${qualifier}" for "${id}" -- severity is a total function of ${Object.keys(SEVERITY_BY_QUALIFIER).join(', ')} and is never defaulted`);
		}
		if (name === '') fail(`${at}: field name is empty for "${id}"`);
		if (evidence === '') fail(`${at}: field evidence is empty for "${id}"`);
		if (byId.has(id)) fail(`${at}: node_id "${id}" appears more than once -- it is the record's primary key`);

		byId.set(id, { id, name, path: id.slice(ID_PATH_PREFIX.length), qualifier, evidence });
		ids.push(id);
	}

	return { ids, byId };
}

// ---------------------------------------------------------------------------
// The relationship table
// ---------------------------------------------------------------------------

/**
 * Read the final table into the edge records the predicate consumes, plus the
 * two counts and one index the report needs.
 *
 * Both Kind cells come from the table's own kind columns and from nowhere else.
 * An edge carrying no kind for an endpoint can never satisfy the predicate's
 * second condition, so inferring one from an id would not merely be a shortcut:
 * it would silently decide coverage from the spelling of a string.
 *
 * @param {string} tablePath the value --table carried
 * @param {string} raw file contents
 * @returns {{edges: object[], extensionRows: number, endpointIds: Set<string>, frontmatter: {start: number, end: number}|null, lines: string[]}}
 */
function parseTable(tablePath, raw) {
	const lines = splitLines(raw);

	// Frontmatter bounds, located here so write mode can reject a table with
	// nowhere to record kb_gaps before it writes anything at all.
	let frontmatter = null;
	if (lines.length > 0 && lines[0].trim() === '---') {
		for (let i = 1; i < lines.length; i += 1) {
			if (lines[i].trim() === '---') {
				frontmatter = { start: 0, end: i };
				break;
			}
		}
	}

	let cursor = lines.findIndex((line) => line.trim() === TABLE_HEADING);
	if (cursor < 0) fail(`${tablePath}: no "${TABLE_HEADING}" heading, so the table's parse contract has no starting point`);

	cursor += 1;
	while (cursor < lines.length && lines[cursor].trim() === '') cursor += 1;
	if (cursor >= lines.length || !isTableLine(lines[cursor])) {
		fail(`${tablePath} line ${cursor + 1}: expected the table header row, the first non-blank line after "${TABLE_HEADING}"`);
	}

	const header = splitRow(lines[cursor]);
	const columnAt = {};
	for (const name of TABLE_COLUMNS) {
		const index = header.indexOf(name);
		if (index < 0) fail(`${tablePath} line ${cursor + 1}: the table header is missing the required column "${name}"`);
		columnAt[name] = index;
	}
	const width = header.length;

	cursor += 1;
	if (cursor >= lines.length || !isTableLine(lines[cursor]) || !isDelimiterRow(splitRow(lines[cursor]))) {
		fail(`${tablePath} line ${cursor + 1}: expected the delimiter row under the table header`);
	}

	const edges = [];
	const endpointIds = new Set();
	let extensionRows = 0;

	// The table ends at the first line that is not a table row. That is the whole
	// reason the coverage notes below can carry tables of their own without ever
	// reaching the graph.
	for (cursor += 1; cursor < lines.length && isTableLine(lines[cursor]); cursor += 1) {
		const at = `${tablePath} line ${cursor + 1}`;
		const cells = splitRow(lines[cursor]);
		if (cells.length !== width) fail(`${at}: ${cells.length} cells, the header declares ${width}`);
		for (const name of TABLE_COLUMNS) {
			if (cells[columnAt[name]] === '') fail(`${at}: required column "${name}" is empty`);
		}
		const edge = {
			sourceId: cells[columnAt['Source Id']],
			sourceKind: cells[columnAt['Source Kind']],
			targetId: cells[columnAt['Target Id']],
			targetKind: cells[columnAt['Target Kind']],
			s2t: cells[columnAt['S2T Relation']],
			t2s: cells[columnAt['T2S Relation']],
			row: cursor + 1,
		};
		edges.push(edge);
		endpointIds.add(edge.sourceId);
		endpointIds.add(edge.targetId);
		if (!CORE_RELATIONS.has(edge.s2t) || !CORE_RELATIONS.has(edge.t2s)) extensionRows += 1;
	}

	return { edges, extensionRows, endpointIds, frontmatter, lines };
}

// ---------------------------------------------------------------------------
// The previous ledger
// ---------------------------------------------------------------------------

/**
 * Read the previous run's ledger, if there is one.
 *
 * An absent file is not an error: it means this is cycle 1 and every row starts
 * Pending -- which, until ledger retention past skill DONE lands, is every run.
 *
 * @param {string|null} previousPath
 * @returns {{rows: object[], highestNumber: number}}
 */
function parsePreviousLedger(previousPath) {
	if (previousPath === null || !existsSync(previousPath)) return { rows: [], highestNumber: 0 };

	const rows = [];
	let highestNumber = 0;
	const lines = splitLines(readTextFile(previousPath, 'previous ledger'));

	for (let i = 0; i < lines.length; i += 1) {
		if (!isTableLine(lines[i])) continue;
		const cells = splitRow(lines[i]);
		if (cells[0] === '#') continue;
		if (isDelimiterRow(cells)) continue;
		const at = `${previousPath} line ${i + 1}`;
		if (cells.length !== LEDGER_CELL_COUNT) {
			fail(`${at}: ${cells.length} cells, the reviewer-ledger schema declares ${LEDGER_CELL_COUNT}`);
		}
		if (!/^[0-9]+$/.test(cells[0])) fail(`${at}: row number "${cells[0]}" is not a positive integer`);
		const number = Number.parseInt(cells[0], 10);
		highestNumber = Math.max(highestNumber, number);
		rows.push({
			number,
			severity: cells[1],
			status: cells[2],
			doc: cells[3],
			line: cells[4],
			description: cells[5],
			evidence: cells[6],
		});
	}

	return { rows, highestNumber };
}

// ---------------------------------------------------------------------------
// The gap set and the ledger
// ---------------------------------------------------------------------------

/**
 * The fixed Description sentence. "node", not "document": the predicate accepts a
 * covering edge from any of the four knowledge-base kinds, so naming one of them
 * would describe a narrower class than the mechanism tests.
 *
 * @param {string} id
 * @param {string} qualifier
 * @param {boolean} hasRows whether any table row names this artifact
 * @returns {string}
 */
function gapDescription(id, qualifier, hasRows) {
	const tail = hasRows ? '' : '; no relationships in the table';
	return `no Knowledge Base node covers ${id} (qualified as ${qualifier}${tail})`;
}

/**
 * The Evidence cell: the qualification anchor the enumerator recorded, then the
 * coverage recheck.
 *
 * The recheck carries every argument --explain requires, echoed from the flags
 * this run received rather than written as literals. A cell carrying only the id
 * would exit 2 on a usage error for every reviewer who pasted it, and literals
 * would be false of any invocation but one.
 *
 * @param {{evidence: string, id: string}} record
 * @param {string} tablePath
 * @param {string} nodesPath
 * @returns {string}
 */
function gapEvidence(record, tablePath, nodesPath) {
	return `${record.evidence}; coverage recheck: node ${SCRIPT} --explain ${record.id} --table ${tablePath} --nodes ${nodesPath}`;
}

/**
 * Decide the gap set and decorate each member from the same inventory.
 *
 * The candidate set is the enumerated inventory, never the table's node column.
 * An artifact the project considers significant with nothing said about it
 * anywhere is the sharpest instance of the defect this ledger reports, not an
 * exception to it, and computing over table rows alone would make exactly that
 * finding invisible.
 *
 * @param {object} inventory
 * @param {object} table
 * @param {{table: string, nodes: string}} paths
 * @returns {object[]} decorated gaps, ascending by id
 */
function collectGaps(inventory, table, paths) {
	return detectArtifactGaps({ nodeIds: inventory.ids, edges: table.edges }).map((id) => {
		const record = inventory.byId.get(id);
		const hasRows = table.endpointIds.has(id);
		return {
			id,
			name: record.name,
			path: record.path,
			qualifier: record.qualifier,
			severity: SEVERITY_BY_QUALIFIER[record.qualifier],
			hasRows,
			description: gapDescription(id, record.qualifier, hasRows),
			evidence: gapEvidence(record, paths.table, paths.nodes),
		};
	});
}

/**
 * Build the ledger's rows against the previous cycle's.
 *
 * Existing rows keep their number, severity, description and evidence -- the
 * schema's append-only rule means only Status moves across cycles. A row whose
 * node is still uncovered stays where it is; one now covered becomes Fixed; one
 * that was Fixed and is uncovered again becomes Recurred. A row already carrying
 * a human-cycle Status is left exactly as it is.
 *
 * @param {object[]} gaps
 * @param {{rows: object[], highestNumber: number}} previous
 * @returns {object[]}
 */
function buildLedgerRows(gaps, previous) {
	const gapByPath = new Map(gaps.map((gap) => [gap.path, gap]));
	const carried = new Set();
	const rows = [];

	for (const row of previous.rows) {
		let status = row.status;
		if (GENERATOR_STATUS.has(row.status)) {
			if (gapByPath.has(row.doc)) {
				status = row.status === 'Fixed' ? 'Recurred' : row.status;
			} else {
				status = 'Fixed';
			}
		}
		carried.add(row.doc);
		rows.push({ ...row, status });
	}

	let next = previous.highestNumber;
	for (const gap of gaps) {
		if (carried.has(gap.path)) continue;
		next += 1;
		rows.push({
			number: next,
			severity: `[${gap.severity}]`,
			status: 'Pending',
			doc: gap.path,
			line: EM_DASH,
			description: gap.description,
			evidence: gap.evidence,
		});
	}

	return rows;
}

/**
 * Render the ledger: one seven-column table and nothing else in the file.
 *
 * @param {object[]} rows
 * @returns {string}
 */
function renderLedger(rows) {
	const out = [LEDGER_HEADER_ROW, LEDGER_DELIMITER_ROW];
	for (const row of rows) {
		const cells = [
			String(row.number), row.severity, row.status, row.doc, row.line, row.description, row.evidence,
		];
		out.push(`| ${cells.map(escapeCell).join(' | ')} |`);
	}
	return `${out.join('\n')}\n`;
}

/**
 * Write the ledger, creating its directory if the run supplied one that does not
 * exist yet.
 *
 * @param {string} outputPath
 * @param {string} content
 * @returns {void}
 */
function writeLedger(outputPath, content) {
	try {
		mkdirSync(dirname(resolve(outputPath)), { recursive: true });
		writeFileSync(outputPath, content, 'utf8');
	} catch (error) {
		fail(`cannot write the ledger at ${resolve(outputPath)} (${error.code || error.message})`);
	}
}

// ---------------------------------------------------------------------------
// The durable carrier
// ---------------------------------------------------------------------------

/**
 * Record the gap set in the table's frontmatter.
 *
 * This is a recorded result, not a second source of truth: it is written from the
 * same call the ledger rows are built from, so the two cannot diverge within a
 * run. It is what survives skill DONE while the ledger does not, and it is a
 * generator-written key in the same class as the other generated frontmatter --
 * the knowledge-base linters validate named fields only and emit nothing for a
 * key they do not recognise.
 *
 * @param {string} tablePath
 * @param {string[]} lines the table file's lines, as read
 * @param {{start: number, end: number}} frontmatter
 * @param {object[]} gaps
 * @returns {void}
 */
function writeKbGaps(tablePath, lines, frontmatter, gaps) {
	const block = [];
	if (gaps.length === 0) {
		block.push('kb_gaps: []');
	} else {
		block.push('kb_gaps:');
		for (const gap of gaps) {
			block.push(`  - id: ${quoteYaml(gap.id)}`);
			block.push(`    name: ${quoteYaml(gap.name)}`);
			block.push(`    severity: ${quoteYaml(gap.severity)}`);
			block.push(`    qualifier: ${quoteYaml(gap.qualifier)}`);
		}
	}

	// Replace in place when the key is already there, so a re-run rewrites the
	// same region and the rest of the file keeps its bytes and its key order.
	let start = -1;
	for (let i = frontmatter.start + 1; i < frontmatter.end; i += 1) {
		if (/^kb_gaps:/.test(lines[i])) {
			start = i;
			break;
		}
	}

	let end;
	if (start < 0) {
		start = frontmatter.end;
		end = frontmatter.end;
	} else {
		end = start + 1;
		while (end < frontmatter.end && /^[ \t]/.test(lines[end])) end += 1;
	}

	const updated = [...lines.slice(0, start), ...block, ...lines.slice(end)];
	try {
		writeFileSync(tablePath, updated.join('\n'), 'utf8');
	} catch (error) {
		fail(`cannot write kb_gaps into ${resolve(tablePath)} (${error.code || error.message})`);
	}
}

// ---------------------------------------------------------------------------
// The routing block
// ---------------------------------------------------------------------------

/**
 * The two-segment path prefix a Doc cell groups under, or null for a file with no
 * directory above it. A directory artifact's trailing separator is removed first,
 * and the prefix is never the path itself -- a file is not a subtree.
 *
 * @param {string} docPath
 * @returns {string|null}
 */
function clusterKey(docPath) {
	const path = docPath.endsWith('/') ? docPath.slice(0, -1) : docPath;
	const segments = path.split('/');
	const depth = Math.min(2, segments.length - 1);
	if (depth < 1) return null;
	return `${segments.slice(0, depth).join('/')}/`;
}

/**
 * The one deterministic cluster line: the path prefix holding the most rows, and
 * its count. Omitted when no group holds more than one row, because a cluster of
 * one is not a cluster. Nothing is aggregated away and nothing is suppressed --
 * suppressing a cluster is the first form of the pressure to loosen the
 * significance rule until the gaps stop appearing.
 *
 * @param {object[]} gaps
 * @returns {string|null}
 */
function clusterSummary(gaps) {
	const counts = new Map();
	for (const gap of gaps) {
		const key = clusterKey(gap.path);
		if (key === null) continue;
		counts.set(key, (counts.get(key) || 0) + 1);
	}
	let best = null;
	// Key order is imposed here rather than inherited from insertion, so a tie
	// resolves to the same prefix on every run.
	for (const key of Array.from(counts.keys()).sort(compareText)) {
		const count = counts.get(key);
		if (best === null || count > best.count) best = { key, count };
	}
	if (best === null || best.count < 2) return null;
	return `most in one subtree: ${best.key} (${best.count})`;
}

/**
 * The gap the suggested targeted instruction names: the most consequential one,
 * so a reader acting on a single line acts on the row that matters most.
 *
 * @param {object[]} gaps
 * @returns {object}
 */
function mostConsequential(gaps) {
	for (const severity of SEVERITY_ORDER) {
		const found = gaps.find((gap) => gap.severity === severity);
		if (found !== undefined) return found;
	}
	return gaps[0];
}

/**
 * The routing block. Findings leave here and reach the skills that already own
 * knowledge-base repair; this script invokes none of them, files nothing, and
 * modifies no knowledge-base content.
 *
 * @param {object} args
 * @returns {string[]}
 */
function routingBlock({ gaps, ledgerPath, tablePath, extensionRows }) {
	const counts = new Map(SEVERITY_ORDER.map((severity) => [severity, 0]));
	for (const gap of gaps) counts.set(gap.severity, counts.get(gap.severity) + 1);
	const breakdown = SEVERITY_ORDER
		.filter((severity) => counts.get(severity) > 0)
		.map((severity) => `${counts.get(severity)} ${severity}`)
		.join(', ');
	const zeroRow = gaps.filter((gap) => !gap.hasRows).length;

	let head = `KB gaps: ${gaps.length}`;
	if (breakdown !== '') head += ` (${breakdown})`;
	// A zero for this slice says nothing about rows that are already in the
	// ledger, so it is omitted rather than printed.
	if (zeroRow > 0) head += ` ${EM_DASH} ${zeroRow} with no relationships at all`;

	const out = [head];
	const cluster = clusterSummary(gaps);
	if (cluster !== null) out.push(`         ${cluster}`);
	out.push(`Ledger:  ${ledgerPath}   (not graded; the run succeeded)`);
	out.push('         NOT RETAINED past skill DONE until the ledger-retention change lands (D-6).');
	out.push(`         Durable copy of the findings: kb_gaps: in ${tablePath}`);
	out.push('         Reproduce the ledger:  /aid-graph --reset');
	// Printed even at zero, and that is the difference from the slice above: a
	// zero here is an affirmative statement that coverage was evaluated over the
	// core vocabulary alone and nothing on this project was typed by anything
	// else -- which is what tells a reader whether the blind spot is live.
	out.push(`Rows typed by a project-extension relation: ${extensionRows}   (coverage is evaluated over the core vocabulary only)`);

	if (gaps.length > 0) {
		out.push('');
		out.push(`Route onward ${EM_DASH} /aid-graph does not fix gaps:`);
		out.push('  Targeted, one gap or a named few:');
		out.push(`    /aid-update-kb "document ${mostConsequential(gaps).path} in module-map.md"`);
		out.push('  Broad sweep, many gaps or a whole subsystem:');
		out.push('    /aid-housekeep          # KB-DELTA re-discovers drifted docs against the repo');
	}

	return out;
}

// ---------------------------------------------------------------------------
// Modes
// ---------------------------------------------------------------------------

/**
 * The recheck a ledger row's Evidence cell invokes: every table row naming the
 * artifact, the relation toward it on each, and the verdict.
 *
 * The verdict comes from the same predicate that built the ledger, over a
 * one-element candidate set, so the two can never disagree. The relation printed
 * is the one naming the direction toward the artifact -- which for a
 * knowledge-base endpoint is the reading the predicate's third condition tests --
 * and the other endpoint's kind is printed beside it as the data it is, so a
 * reader can see why a row does or does not count.
 *
 * @param {object} inventory
 * @param {object} table
 * @param {string} nodeId
 * @param {string} nodesPath
 * @returns {void}
 */
function explain(inventory, table, nodeId, nodesPath) {
	console.log(`node: ${nodeId}`);
	const record = inventory.byId.get(nodeId);
	if (record === undefined) {
		console.log(`inventory: not an enumerated candidate in ${nodesPath}`);
	} else {
		console.log(`inventory: qualified as ${record.qualifier} (evidence: ${record.evidence})`);
	}

	const naming = table.edges.filter((edge) => edge.sourceId === nodeId || edge.targetId === nodeId);
	console.log(`rows naming this artifact: ${naming.length}   (relation read toward the artifact)`);
	for (const edge of naming) {
		if (edge.sourceId === nodeId && edge.targetId === nodeId) {
			console.log(`  row ${edge.row}: ${nodeId} to itself : S2T ${edge.s2t}, T2S ${edge.t2s}`);
		} else if (edge.targetId === nodeId) {
			console.log(`  row ${edge.row}: ${nodeId} <- ${edge.sourceId} (${edge.sourceKind}) : ${edge.s2t}`);
		} else {
			console.log(`  row ${edge.row}: ${nodeId} <- ${edge.targetId} (${edge.targetKind}) : ${edge.t2s}`);
		}
	}

	const uncovered = detectArtifactGaps({ nodeIds: [nodeId], edges: table.edges }).length > 0;
	console.log(`verdict: ${uncovered ? 'uncovered' : 'covered'}`);
}

/**
 * The write mode: record the gap set, emit the ledger, print the route onward.
 *
 * @param {object} options
 * @param {object} inventory
 * @param {object} table
 * @returns {void}
 */
function report(options, inventory, table) {
	if (table.frontmatter === null) {
		fail(`${options.table}: no frontmatter block, so there is nowhere to record kb_gaps`);
	}

	const gaps = collectGaps(inventory, table, { table: options.table, nodes: options.nodes });
	const previous = parsePreviousLedger(options.previous);

	writeKbGaps(options.table, table.lines, table.frontmatter, gaps);
	writeLedger(options.output, renderLedger(buildLedgerRows(gaps, previous)));

	routingBlock({
		gaps,
		ledgerPath: options.output,
		tablePath: options.table,
		extensionRows: table.extensionRows,
	}).forEach((line) => console.log(line));
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.mode === 'help') return;

	const table = parseTable(options.table, readTextFile(options.table, 'relationship table'));
	const inventory = parseNodes(options.nodes, readTextFile(options.nodes, 'node inventory'));

	if (options.mode === 'explain') {
		explain(inventory, table, options.explain, options.nodes);
	} else {
		report(options, inventory, table);
	}
}

// Exit 0 whatever the gap count, and 2 for the one failure this script defines.
// The success status is independent of the finding count by construction: gating
// on knowledge-base completeness would fail the tool for reasons outside its own
// control and would create a standing incentive to loosen the significance rule
// until the gaps stopped appearing.
//
// The status is set rather than forced, and never by a `process.exit` after a
// write to stdout or stderr: those streams are asynchronous when they are a pipe
// on POSIX and when they are a terminal on Windows, so exiting immediately after
// printing can truncate the output -- which for the routing block would drop the
// route onward, and for a diagnostic would drop the reason for the exit. Letting
// the process end on its own flushes both.
try {
	main();
} catch (error) {
	if (!(error instanceof InputError)) throw error;
	console.error(`${SCRIPT}: ${error.message}`);
	process.exitCode = 2;
}
