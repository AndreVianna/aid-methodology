#!/usr/bin/env node
// build-graph-src.mjs -- the missing producer for graph.html's multi-source
// authoring layout (task-013, feature-007-graph-view-shell).
//
// WHAT THIS FILE IS, AND WHAT IT IS NOT
//   It reads the ONE input this view is allowed (relationships.md, FR-3/AC-10)
//   and the shipped template/script files, fills every skeleton placeholder, and
//   writes the `.aid/.temp/graph/graph-src/` layout the REUSED assembler
//   (`.claude/aid/scripts/summarize/assemble.sh`) already validates for
//   existence and non-emptiness. It never assembles the final page itself and
//   never re-implements assemble.sh's concatenation or validation -- that would
//   be exactly the fork AC-17/FR-12/C-4 forbid. `render-graph-view.sh` in this
//   same directory calls this file and then calls the real assemble.sh.
//
// SPLIT POINTS (verified against graph-skeleton.html on disk, not assumed):
//   skeleton-head.html   bytes before  '<main id="top" class="graph-page">'
//   sections/00-graph-shell.html
//                        the ENTIRE '<main ...> ... </main>' block, inclusive.
//                        There is exactly one logical section here -- this page
//                        is one shell, not a per-document section list like
//                        kb.html's -- so the section-manifest names it alone.
//   skeleton-foot.html   bytes from just after '</main>' through the closing
//                        '</script>' of the page's one inline module block
//                        (the line after 'bootGraphView();')
//   post-script.html     everything after that: the reused lightbox <script>
//                        and the closing </body></html>
//
// PLACEHOLDERS FILLED HERE (ten named in task-013's DETAIL, plus the payload):
//   {{LANG}} {{PROJECT_NAME}} {{GENERATION_DATE}} {{SOURCE_STAMP}} {{INLINE_CSS}}
//   {{PREREQUISITES}} {{SCALE_CEILING_NOTE}} {{RELATIONSHIPS_BASE64}}
//   {{INLINE_COVERAGE_PREDICATE}} {{INLINE_LIGHTBOX_JS}}
//   {{INLINE_GRAPH_JS}} is filled from whatever view files are ACTUALLY present
//   on disk (graph-model.js, graph-controls.js, graph-table.js today; this file
//   auto-detects graph-canvas.js and appends it the day feature-008/task-017
//   ships it -- no edit owed here on that day).
//
// USAGE
//   node build-graph-src.mjs [--relationships PATH] [--src DIR] [--repo-root DIR]
//                            [--project-name NAME] [--generation-date DATE]
//
// EXIT CODES (read by render-graph-view.sh, itself read by state-render.md)
//   0  the graph-src layout was written
//   1  relationships.md is missing, unreadable, or empty -- no input, no layout
//   2  a shipped template/script this file depends on is missing on disk, or the
//      CLI was invoked with a bad flag -- an invocation error, not a data defect

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_REPO_ROOT = path.resolve(HERE, '..', '..', '..', '..');

function parseArgs(argv) {
	const out = {
		repoRoot: DEFAULT_REPO_ROOT,
		relationships: null,
		src: null,
		projectName: null,
		generationDate: null,
	};
	for (let i = 0; i < argv.length; i += 1) {
		const a = argv[i];
		const next = () => argv[++i];
		switch (a) {
			case '--repo-root': out.repoRoot = next(); break;
			case '--relationships': out.relationships = next(); break;
			case '--src': out.src = next(); break;
			case '--project-name': out.projectName = next(); break;
			case '--generation-date': out.generationDate = next(); break;
			case '-h': case '--help':
				process.stdout.write('Usage: node build-graph-src.mjs [--relationships PATH] [--src DIR] '
					+ '[--repo-root DIR] [--project-name NAME] [--generation-date DATE]\n');
				process.exit(0);
				break;
			default:
				process.stderr.write('Unknown argument: ' + a + '\n');
				process.exit(2);
		}
	}
	out.relationships = out.relationships || path.join(out.repoRoot, '.aid/knowledge/relationships.md');
	out.src = out.src || path.join(out.repoRoot, '.aid/.temp/graph/graph-src');
	return out;
}

function fail(code, message) {
	process.stderr.write('build-graph-src.mjs: ' + message + '\n');
	process.exit(code);
}

function readOrFail(p, code, label) {
	try {
		return fs.readFileSync(p, 'utf8');
	} catch (error) {
		fail(code, label + ' could not be read (' + p + '): ' + (error && error.message ? error.message : error));
	}
}

/** Mirrors graph-model.js's own frontmatterScalar -- one top-level scalar, first
 *  match wins, one quote layer stripped. Reading relationships.md's OWN
 *  frontmatter for its OWN attribution is not a second extraction path. */
function frontmatterScalar(text, key) {
	const lines = text.split('\n');
	if (lines[0] && lines[0].trim() !== '---') return null;
	const prefix = key + ':';
	for (let i = 1; i < lines.length; i += 1) {
		if (lines[i].trim() === '---') break;
		if (lines[i].indexOf(prefix) === 0) {
			const v = lines[i].slice(prefix.length).trim();
			if (v.length >= 2 && ((v[0] === '"' && v[v.length - 1] === '"') || (v[0] === "'" && v[v.length - 1] === "'"))) {
				return v.slice(1, -1);
			}
			return v;
		}
	}
	return null;
}

function defaultProjectName(repoRoot) {
	try {
		const settings = fs.readFileSync(path.join(repoRoot, '.aid/settings.yml'), 'utf8');
		const m = settings.match(/^name:\s*(.+)\s*$/m);
		if (m) return m[1].trim();
	} catch { /* fall through */ }
	return 'This project';
}

function main() {
	const args = parseArgs(process.argv.slice(2));
	const repoRoot = path.resolve(args.repoRoot);
	const templatesDir = path.join(repoRoot, '.claude/aid/templates/knowledge-graph');
	const summaryTemplatesDir = path.join(repoRoot, '.claude/aid/templates/knowledge-summary');
	const predicatePath = path.join(repoRoot, '.claude/aid/scripts/graph/coverage-predicate.mjs');
	const scaleCeilingPath = path.join(repoRoot, '.claude/aid/templates/graph/scale-ceiling.yml');
	const skeletonPath = path.join(templatesDir, 'graph-skeleton.html');

	// --- The one input (FR-3, AC-10) ---------------------------------------
	let relText;
	try {
		relText = fs.readFileSync(args.relationships, 'utf8');
	} catch (error) {
		fail(1, 'the one input, relationships.md, could not be read at ' + args.relationships
			+ ': ' + (error && error.message ? error.message : error));
	}
	if (relText.trim() === '') fail(1, 'relationships.md is empty at ' + args.relationships);

	// --- Shipped files this producer depends on, never forked -------------
	for (const p of [skeletonPath, predicatePath,
		path.join(templatesDir, 'graph-css.css'),
		path.join(summaryTemplatesDir, 'component-css.css'),
		path.join(summaryTemplatesDir, 'lightbox.js'),
		path.join(templatesDir, 'graph-model.js'),
		path.join(templatesDir, 'graph-controls.js')]) {
		if (!fs.existsSync(p)) fail(2, 'a shipped file this producer depends on is missing: ' + p);
	}

	const skeleton = readOrFail(skeletonPath, 2, 'graph-skeleton.html');

	// --- Split the skeleton at its three real boundaries -------------------
	const mainOpenMarker = '<main id="top" class="graph-page">';
	const mainCloseMarker = '</main>';
	const moduleCloseMarker = 'bootGraphView();\n</script>\n';

	const mainOpenAt = skeleton.indexOf(mainOpenMarker);
	if (mainOpenAt === -1) fail(2, 'graph-skeleton.html no longer contains the <main> opening tag this splitter keys on');
	const mainCloseAt = skeleton.indexOf(mainCloseMarker, mainOpenAt);
	if (mainCloseAt === -1) fail(2, 'graph-skeleton.html no longer contains a matching </main>');
	const sectionEnd = mainCloseAt + mainCloseMarker.length;
	const moduleCloseAt = skeleton.indexOf(moduleCloseMarker, sectionEnd);
	if (moduleCloseAt === -1) fail(2, 'graph-skeleton.html no longer contains the module block this splitter keys on (bootGraphView();\\n</script>\\n)');
	const footEnd = moduleCloseAt + moduleCloseMarker.length;

	let head = skeleton.slice(0, mainOpenAt);
	let section = skeleton.slice(mainOpenAt, sectionEnd);
	let foot = skeleton.slice(sectionEnd, footEnd);
	const postScript = skeleton.slice(footEnd); // no placeholders live past this point except INLINE_LIGHTBOX_JS

	// --- The view files actually present on disk today ---------------------
	// AUTO-DETECTED, not a hard-coded list: the day graph-canvas.js (feature-008,
	// task-017) lands, it is picked up here with no edit to this file.
	const viewFileOrder = ['graph-model.js', 'graph-controls.js', 'graph-table.js', 'graph-canvas.js'];

	/**
	 * TEMPORARY, AND THE OWNER'S EXPLICIT DECISION -- 2026-08-06.
	 *
	 * The table rendering is excluded from the page. Set this to `false` to put it
	 * back; nothing else has to change, because the shell already tolerates the
	 * table's absence by design (`graph-controls.js` mounts it behind
	 * `if (mountTableFn)`, and `resolveMount` yields null when the module is not in
	 * the bundle). `graph-table.js` STAYS ON DISK and stays fully tested --
	 * `test-graph-table-view.sh` reads the file directly rather than through this
	 * bundle -- so this hides the rendering, it does not retire it.
	 *
	 * WHY: this repo's own extraction run enumerated thousands of candidate
	 * relationships, and a table of that size dominates the page it is supposed to
	 * support.
	 *
	 * WHAT IT COSTS, recorded here because it is not a cosmetic change. The canvas
	 * is deliberately visual-only and builds NO DOM proxy layer; the table was the
	 * conforming alternate version that carried WCAG AA for the whole artifact
	 * (`graph-table.js`'s own header: "THIS is the surface that carries the
	 * accessibility standard"). With it excluded the graph has no accessible
	 * equivalent at all, and every acceptance criterion resting on the table --
	 * feature-009's whole set, plus the table halves of AC-9 and AC-15 -- no longer
	 * holds for the rendered page. The owner was shown this consequence and a
	 * row-capped alternative that would have preserved it, and chose removal for
	 * now. Tracked as debt rather than left implicit.
	 */
	const OWNER_EXCLUDES_TABLE_RENDERING = true;

	const viewFiles = viewFileOrder
		.filter((f) => !(OWNER_EXCLUDES_TABLE_RENDERING && f === 'graph-table.js'))
		.filter((f) => fs.existsSync(path.join(templatesDir, f)));
	const inlineGraphJs = viewFiles.map((f) => readOrFail(path.join(templatesDir, f), 2, f)).join('\n');

	// --- The vendored companion bundles (feature-012 D6, task-023) ----------
	// AUTO-DETECTED, exactly like the view-file list above: absent until task-023
	// vendors .claude/aid/templates/knowledge-graph/vendor/, present after, no
	// edit owed here on that day either way. Companion, never inlined (D6's own
	// choice) and never a CDN reference, so each tag is a bare relative path --
	// this is what keeps validate-html-output.sh's S2 a recorded no-op. Classic
	// <script src> tags execute in document order before a deferred/module
	// script, so placing them in <head> guarantees `d3`/`PIXI` are already
	// global by the time bootGraphView()'s module block runs (feature-007
	// SPEC :1602). Injected here, into the in-memory `head` string, rather than
	// as a static <script> block in graph-skeleton.html -- that file carries no
	// vendor-specific markup, so a tree with none of these five files vendored
	// still renders a valid (degraded, mode: 'unavailable') page with no dead
	// <script src> pointing at a file that does not exist.
	const VENDOR_DIR = path.join(templatesDir, 'vendor');
	// Dependency order matters (rendering-decision-record.md Part 10): the three
	// d3-force dependencies must load before d3-force itself; pixi.js has no
	// ordering dependency on any of them.
	const vendorOrder = [
		['d3-quadtree', 'd3-quadtree.min.js'],
		['d3-dispatch', 'd3-dispatch.min.js'],
		['d3-timer', 'd3-timer.min.js'],
		['d3-force', 'd3-force.min.js'],
		['pixi.js', 'pixi.min.js'],
	];
	const vendorFiles = vendorOrder.filter(([dir, file]) => fs.existsSync(path.join(VENDOR_DIR, dir, file)));
	// Relative to graph.html itself (FR-9/A-4: companions travel beside it),
	// under the same graph-assets/ subdirectory kb-write-fence.sh already
	// allowlists -- render-graph-view.sh is what actually copies the bytes there.
	const vendorScriptTags = vendorFiles
		.map(([dir, file]) => '<script src="graph-assets/vendor/' + dir + '/' + file + '"></script>')
		.join('\n');
	if (vendorFiles.length > 0) {
		const headCloseAt = head.indexOf('</head>');
		if (headCloseAt === -1) fail(2, 'graph-skeleton.html no longer contains the </head> tag this producer keys on for vendor script injection');
		head = head.slice(0, headCloseAt) + vendorScriptTags + '\n' + head.slice(headCloseAt);
	}

	// --- The remaining substitution values ----------------------------------
	const projectName = args.projectName || defaultProjectName(repoRoot);
	const generationDate = args.generationDate || new Date().toISOString().slice(0, 10);
	const generator = frontmatterScalar(relText, 'generator');
	const sourceStamp = generator ? ('<code>' + generator + '</code>') : 'an unrecorded generator';

	// --- AC-6's four runtime-prerequisite facts: ONE authoring site read by
	// BOTH carriers this generator owns -- the footer's {{PREREQUISITES}} <li>
	// list below and the console summary printed near the end of main(). This
	// lives in build-graph-src.mjs, not render-graph-view.sh: this file already
	// computes the network/companion facts from disk state and already holds
	// graph-skeleton.html's raw text, which is where the WebGL fact is READ
	// FROM below rather than re-authored. Splitting fact computation across the
	// bash driver and this file would be a second authoring site -- exactly the
	// defect this task exists to close.
	//
	// The code this replaces was a TERNARY: network-required XOR companion-
	// files, as if a page could only ever need one. It cannot -- graph-assets/,
	// when it exists, is a *local* companion of a page that still makes no
	// network request (rendering-decision-record.md Part 13, facts 2 and 3 both
	// hold at once for this project's own vendored packaging shape). Both facts
	// are therefore always stated below, each with its own true-for-this-run
	// content.
	//
	// BUILD-OUTPUT RULING (recorded here, not left implicit): the skeleton's
	// existing "builds both renderings ... at load time" sentence (the
	// JavaScript-required <li> just above {{PREREQUISITES}} in the markup) is
	// about the page's OWN script building its DOM at READ time -- a different
	// fact from AC-6's "whether a build output is involved", which the
	// decision record's Part 13 fact 4 states as "no build step at open time":
	// graph.html itself is produced ONCE, at GENERATION time, by this script
	// and the reused assembler, never recompiled by the reader. That is not
	// discharged by the existing sentence, so a distinct one is authored below.
	const graphAssetsDir = path.join(path.dirname(args.relationships), 'graph-assets');
	const graphAssetsPresent = fs.existsSync(graphAssetsDir) && fs.readdirSync(graphAssetsDir).length > 0;

	// The WebGL fact's WORDING lives in graph-skeleton.html alone -- its own
	// static <li>, the one GV23a checks directly against the file on disk -- so
	// it is extracted here rather than re-authored a second time. Editing that
	// one sentence in the skeleton moves both carriers together exactly like
	// the other three facts below do.
	const prereqsListAt = skeleton.indexOf('<ul class="prereqs">');
	if (prereqsListAt === -1) fail(2, 'graph-skeleton.html no longer contains the runtime-prerequisites <ul> this producer keys on');
	const jsRequiredLiAt = skeleton.indexOf('<li>JavaScript is required', prereqsListAt);
	if (jsRequiredLiAt === -1) fail(2, 'graph-skeleton.html no longer contains the JavaScript-required <li> this producer keys on');
	const stripTags = (s) => s.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
	const webglFact = stripTags(skeleton.slice(prereqsListAt, jsRequiredLiAt));

	const prerequisiteFacts = [
		webglFact,
		'No network access is required and none is made.',
		graphAssetsPresent
			? 'Companion files under <code>graph-assets/</code> must travel with this page.'
			: 'No companion files travel with this page; everything it needs lives inside it.',
		'This page is itself a build output: it was assembled once, at generation time, by '
			+ '<code>build-graph-src.mjs</code> and the reused assembler — never rebuilt in the '
			+ 'reader’s browser, and no separate build step is required to open it.',
	];

	// The footer's own WebGL <li> is graph-skeleton.html's static text (never
	// substituted -- see above), so {{PREREQUISITES}} carries the remaining
	// three: network, companion files, build output -- always all three,
	// never a subset.
	const prerequisites = prerequisiteFacts.slice(1)
		.map((f) => '\t\t<li>' + f + '</li>')
		.join('\n');

	let scaleCeilingNote = '\t<p class="prereqs">No node-count ceiling is declared for this project.</p>';
	if (fs.existsSync(scaleCeilingPath)) {
		const ceilingText = fs.readFileSync(scaleCeilingPath, 'utf8');
		const m = ceilingText.match(/^node_ceiling:\s*(.*)$/m);
		const value = m ? m[1].trim() : '';
		if (value !== '') {
			scaleCeilingNote = '\t<p class="prereqs">This project declares a node-count ceiling of ' + value + '.</p>';
		}
	}

	const inlineCss = readOrFail(path.join(summaryTemplatesDir, 'component-css.css'), 2, 'component-css.css')
		+ '\n\n' + readOrFail(path.join(templatesDir, 'graph-css.css'), 2, 'graph-css.css');
	const relationshipsBase64 = Buffer.from(relText, 'utf8').toString('base64');
	const coveragePredicate = readOrFail(predicatePath, 2, 'coverage-predicate.mjs');
	const lightboxJs = readOrFail(path.join(summaryTemplatesDir, 'lightbox.js'), 2, 'lightbox.js');

	const subsHead = {
		'{{LANG}}': 'en',
		'{{PROJECT_NAME}}': projectName,
		'{{INLINE_CSS}}': inlineCss,
	};
	const subsFoot = {
		'{{GENERATION_DATE}}': generationDate,
		'{{SOURCE_STAMP}}': sourceStamp,
		'{{PREREQUISITES}}': prerequisites,
		'{{SCALE_CEILING_NOTE}}': scaleCeilingNote,
		'{{RELATIONSHIPS_BASE64}}': relationshipsBase64,
		'{{INLINE_COVERAGE_PREDICATE}}': coveragePredicate,
		'{{INLINE_GRAPH_JS}}': inlineGraphJs,
	};
	const subsPost = {
		'{{INLINE_LIGHTBOX_JS}}': lightboxJs,
	};

	function applyAll(text, subs, label) {
		let out = text;
		for (const [key, val] of Object.entries(subs)) {
			if (!out.includes(key)) fail(2, label + ' no longer contains the placeholder ' + key + ' this producer fills');
			out = out.split(key).join(val);
		}
		return out;
	}

	head = applyAll(head, subsHead, 'skeleton-head.html');
	foot = applyAll(foot, subsFoot, 'skeleton-foot.html');
	const finalPostScript = applyAll(postScript, subsPost, 'post-script.html');

	// No placeholder of the ten may survive assembly (AC-10's structural half).
	for (const [name, text] of [['skeleton-head.html', head], ['sections/00-graph-shell.html', section],
		['skeleton-foot.html', foot], ['post-script.html', finalPostScript]]) {
		const leftover = text.match(/\{\{[A-Z_]+\}\}/g);
		if (leftover) fail(2, name + ' still carries unsubstituted placeholders: ' + leftover.join(', '));
	}

	// --- Write the graph-src layout -----------------------------------------
	const sectionsDir = path.join(args.src, 'sections');
	fs.mkdirSync(sectionsDir, { recursive: true });
	fs.writeFileSync(path.join(args.src, 'skeleton-head.html'), head);
	fs.writeFileSync(path.join(sectionsDir, '00-graph-shell.html'), section);
	fs.writeFileSync(path.join(args.src, 'skeleton-foot.html'), foot);
	fs.writeFileSync(path.join(args.src, 'post-script.html'), finalPostScript);
	fs.writeFileSync(path.join(args.src, 'section-manifest.txt'),
		'# section-manifest.txt -- generated by build-graph-src.mjs; do not edit by hand.\n'
		+ '# The graph page is one shell, not a per-document section list, so this manifest\n'
		+ '# names exactly one section (assemble.sh still requires a non-empty manifest).\n'
		+ '00-graph-shell.html\n');

	process.stdout.write('Wrote graph-src layout to ' + args.src + '\n');
	process.stdout.write('  view files inlined: ' + viewFiles.join(', ') + '\n');

	// AC-6/GV23's SECOND carrier (feature-007 SPEC :1604-1608, :1817): the same
	// four facts authored once above, now printed to the run's own console
	// summary rather than re-authored a second time. render-graph-view.sh (the
	// documented entry point) never redirects this file's stdout and never
	// pipes it into anything else -- it flows straight through to whoever
	// invoked the driver, which is what "the run's console summary" means here.
	process.stdout.write('Runtime prerequisites for the page this layout will assemble into:\n');
	for (const fact of prerequisiteFacts) {
		process.stdout.write('  - ' + stripTags(fact) + '\n');
	}
	process.exit(0);
}

main();
