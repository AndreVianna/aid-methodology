#!/usr/bin/env node
// build-table-src.mjs -- the producer for the table-only page's own multi-source
// authoring layout (task-033, feature-007-graph-view-shell + feature-009).
//
// WHAT THIS FILE IS, AND WHAT IT IS NOT
//   It reads the ONE input this view is allowed (relationships.md, same as
//   build-graph-src.mjs's own FR-3/AC-10), and the shipped template/script files,
//   fills every placeholder table-view-skeleton.html declares, and writes the
//   `.aid/.temp/graph/table-src/` layout the REUSED assembler
//   (`.cursor/aid/scripts/summarize/assemble.sh`) already validates for
//   existence and non-emptiness. It never assembles the final page itself and
//   never re-implements assemble.sh's concatenation or validation, for the same
//   reason build-graph-src.mjs gives: that would be exactly the fork AC-17/FR-12/
//   C-4 forbid. `render-table-view.sh` in this same directory calls this file and
//   then calls the real assemble.sh.
//
//   A SIBLING producer, not an edit to build-graph-src.mjs: that file's split
//   markers are keyed on graph-skeleton.html, a concurrent task's own in-flight
//   file. This file keys on table-view-skeleton.html instead, which task-033
//   owns outright, so the two producers can evolve with zero risk of one
//   colliding with the other's edits.
//
// SPLIT POINTS (verified against table-view-skeleton.html on disk, not assumed):
//   skeleton-head.html   bytes before  '<main id="top" class="graph-page">'
//   sections/00-table-shell.html
//                        the ENTIRE '<main ...> ... </main>' block, inclusive --
//                        one logical section, exactly like the graph page's own
//                        single-shell layout.
//   skeleton-foot.html   bytes from just after '</main>' through the closing
//                        '</script>' of the page's one inline module block
//                        (the line after 'bootTableView();')
//   post-script.html     everything after that: the reused theme/lightbox
//                        <script> (theme-toggle only, on this page -- see the
//                        skeleton's own comment) and the closing </body></html>.
//
// PLACEHOLDERS FILLED HERE:
//   {{LANG}} {{PROJECT_NAME}} {{GENERATION_DATE}} {{SOURCE_STAMP}} {{INLINE_CSS}}
//   {{PREREQUISITES}} {{RELATIONSHIPS_BASE64}} {{INLINE_COVERAGE_PREDICATE}}
//   {{INLINE_TABLE_VIEW_JS}} {{INLINE_LIGHTBOX_JS}}
//   No {{SCALE_CEILING_NOTE}}: a node-count ceiling bounds what the DRAWING
//   rendering can draw; this page has no drawing rendering, so that fact has no
//   subject here and the skeleton declares no placeholder for it.
//
// THE BUNDLE, AND WHY graph-canvas.js IS NEVER IN IT
//   graph-model.js, graph-controls.js and graph-table.js -- ALWAYS, in that
//   order, then this task's own table-view-shell.js last. graph-canvas.js is
//   never appended: unlike build-graph-src.mjs's `viewFileOrder`, which
//   auto-detects the drawing rendering because graph.html sometimes carries it,
//   this page draws nothing and never will, so there is no flag to flip here --
//   the omission is unconditional rather than a switch this task could leave
//   the wrong way.
//
// USAGE
//   node build-table-src.mjs [--relationships PATH] [--src DIR] [--repo-root DIR]
//                            [--project-name NAME] [--generation-date DATE]
//
// EXIT CODES (read by render-table-view.sh, itself read the same way
// render-graph-view.sh's exit codes are read by state-render.md)
//   0  the table-src layout was written
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
				process.stdout.write('Usage: node build-table-src.mjs [--relationships PATH] [--src DIR] '
					+ '[--repo-root DIR] [--project-name NAME] [--generation-date DATE]\n');
				process.exit(0);
				break;
			default:
				process.stderr.write('Unknown argument: ' + a + '\n');
				process.exit(2);
		}
	}
	out.relationships = out.relationships || path.join(out.repoRoot, '.aid/knowledge/relationships.md');
	out.src = out.src || path.join(out.repoRoot, '.aid/.temp/graph/table-src');
	return out;
}

function fail(code, message) {
	process.stderr.write('build-table-src.mjs: ' + message + '\n');
	process.exit(code);
}

function readOrFail(p, code, label) {
	try {
		return fs.readFileSync(p, 'utf8');
	} catch (error) {
		fail(code, label + ' could not be read (' + p + '): ' + (error && error.message ? error.message : error));
	}
}

/** Mirrors build-graph-src.mjs's own frontmatterScalar -- one top-level scalar,
 *  first match wins, one quote layer stripped. Reading relationships.md's OWN
 *  frontmatter for its OWN attribution is not a second extraction path. Kept
 *  as a second, byte-identical function rather than a shared import: this
 *  script has no relative-module dependency on build-graph-src.mjs, so the two
 *  producers stay fully independent siblings. */
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
	const templatesDir = path.join(repoRoot, '.cursor/aid/templates/knowledge-graph');
	const summaryTemplatesDir = path.join(repoRoot, '.cursor/aid/templates/knowledge-summary');
	const predicatePath = path.join(repoRoot, '.cursor/aid/scripts/graph/coverage-predicate.mjs');
	const skeletonPath = path.join(templatesDir, 'table-view-skeleton.html');

	// --- The one input (FR-3/AC-10, same rule as the graph page) -----------
	let relText;
	try {
		relText = fs.readFileSync(args.relationships, 'utf8');
	} catch (error) {
		fail(1, 'the one input, relationships.md, could not be read at ' + args.relationships
			+ ': ' + (error && error.message ? error.message : error));
	}
	if (relText.trim() === '') fail(1, 'relationships.md is empty at ' + args.relationships);

	// --- Shipped files this producer depends on, never forked --------------
	const viewFiles = ['graph-model.js', 'graph-controls.js', 'graph-table.js', 'table-view-shell.js'];
	for (const p of [skeletonPath, predicatePath,
		path.join(templatesDir, 'graph-css.css'),
		path.join(summaryTemplatesDir, 'component-css.css'),
		path.join(summaryTemplatesDir, 'lightbox.js'),
	].concat(viewFiles.map((f) => path.join(templatesDir, f)))) {
		if (!fs.existsSync(p)) fail(2, 'a shipped file this producer depends on is missing: ' + p);
	}

	const skeleton = readOrFail(skeletonPath, 2, 'table-view-skeleton.html');

	// --- Split the skeleton at its three real boundaries --------------------
	const mainOpenMarker = '<main id="top" class="graph-page">';
	const mainCloseMarker = '</main>';
	const moduleCloseMarker = 'bootTableView();\n</script>\n';

	const mainOpenAt = skeleton.indexOf(mainOpenMarker);
	if (mainOpenAt === -1) fail(2, 'table-view-skeleton.html no longer contains the <main> opening tag this splitter keys on');
	const mainCloseAt = skeleton.indexOf(mainCloseMarker, mainOpenAt);
	if (mainCloseAt === -1) fail(2, 'table-view-skeleton.html no longer contains a matching </main>');
	const sectionEnd = mainCloseAt + mainCloseMarker.length;
	const moduleCloseAt = skeleton.indexOf(moduleCloseMarker, sectionEnd);
	if (moduleCloseAt === -1) fail(2, 'table-view-skeleton.html no longer contains the module block this splitter keys on (bootTableView();\\n</script>\\n)');
	const footEnd = moduleCloseAt + moduleCloseMarker.length;

	let head = skeleton.slice(0, mainOpenAt);
	const section = skeleton.slice(mainOpenAt, sectionEnd);
	let foot = skeleton.slice(sectionEnd, footEnd);
	const postScript = skeleton.slice(footEnd); // no placeholders live past this point except INLINE_LIGHTBOX_JS

	const inlineTableViewJs = viewFiles.map((f) => readOrFail(path.join(templatesDir, f), 2, f)).join('\n');

	// --- The remaining substitution values -----------------------------------
	const projectName = args.projectName || defaultProjectName(repoRoot);
	const generationDate = args.generationDate || new Date().toISOString().slice(0, 10);
	const generator = frontmatterScalar(relText, 'generator');
	const sourceStamp = generator ? ('<code>' + generator + '</code>') : 'an unrecorded generator';

	// This page's own prerequisite facts. Three, not the graph page's four: no
	// WebGL fact (there is no drawing surface to need one), and companion files
	// (feature-012 D6/task-023's vendored bundles) travel with graph.html alone
	// -- this page needs none of them, so "no companion files" is unconditional
	// rather than a directory check. Network and build-output are stated for
	// the same reason build-graph-src.mjs states them for the graph page: they
	// are true for this run and this page makes the same two claims.
	const prerequisiteFacts = [
		'No network access is required and none is made.',
		'No companion files travel with this page; everything it needs lives inside it.',
		'This page is itself a build output: it was assembled once, at generation time, by '
			+ '<code>build-table-src.mjs</code> and the reused assembler — never rebuilt in the '
			+ 'reader’s browser, and no separate build step is required to open it.',
	];
	const prerequisites = prerequisiteFacts.map((f) => '\t\t<li>' + f + '</li>').join('\n');

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
		'{{RELATIONSHIPS_BASE64}}': relationshipsBase64,
		'{{INLINE_COVERAGE_PREDICATE}}': coveragePredicate,
		'{{INLINE_TABLE_VIEW_JS}}': inlineTableViewJs,
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

	// No placeholder may survive assembly (AC-10's structural half, same rule
	// build-graph-src.mjs applies to its own four parts).
	for (const [name, text] of [['skeleton-head.html', head], ['sections/00-table-shell.html', section],
		['skeleton-foot.html', foot], ['post-script.html', finalPostScript]]) {
		const leftover = text.match(/\{\{[A-Z_]+\}\}/g);
		if (leftover) fail(2, name + ' still carries unsubstituted placeholders: ' + leftover.join(', '));
	}

	// --- Write the table-src layout ------------------------------------------
	const sectionsDir = path.join(args.src, 'sections');
	fs.mkdirSync(sectionsDir, { recursive: true });
	fs.writeFileSync(path.join(args.src, 'skeleton-head.html'), head);
	fs.writeFileSync(path.join(sectionsDir, '00-table-shell.html'), section);
	fs.writeFileSync(path.join(args.src, 'skeleton-foot.html'), foot);
	fs.writeFileSync(path.join(args.src, 'post-script.html'), finalPostScript);
	fs.writeFileSync(path.join(args.src, 'section-manifest.txt'),
		'# section-manifest.txt -- generated by build-table-src.mjs; do not edit by hand.\n'
		+ '# The table page is one shell, not a per-document section list, so this manifest\n'
		+ '# names exactly one section (assemble.sh still requires a non-empty manifest).\n'
		+ '00-table-shell.html\n');

	process.stdout.write('Wrote table-src layout to ' + args.src + '\n');
	process.stdout.write('  view files inlined: ' + viewFiles.join(', ') + '\n');

	process.stdout.write('Runtime prerequisites for the page this layout will assemble into:\n');
	for (const fact of prerequisiteFacts) {
		process.stdout.write('  - ' + fact.replace(/<[^>]+>/g, '') + '\n');
	}
	process.exit(0);
}

main();
