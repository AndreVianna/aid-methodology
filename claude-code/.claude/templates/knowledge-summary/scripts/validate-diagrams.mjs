#!/usr/bin/env node
// validate-diagrams.mjs — extract every <pre class="mermaid"> block from an HTML
// file and validate that each parses (D1) and renders (D2) correctly.
//
// Usage: node validate-diagrams.mjs <html-file> [--fast]
//
// Flags:
//   --fast    Skip all render checks; run D1 regex-only. For development.
//   -h, --help  Print this header and exit.
//
// Validation strategy:
//   D1 — parse check (always runs):
//     1. Regex sanity checks (always active).
//     2. mermaid.parse() via jsdom + inlined Mermaid library (preferred).
//        Falls back to regex-only if jsdom not installed.
//
//   D2 — render check (skipped in --fast mode):
//     mermaid.render() via jsdom + inlined Mermaid library.
//     Asserts: SVG > 500 bytes, contains <g> or <path>, no error-block markers.
//     Falls back to "D2: jsdom not installed — falling back to parse-only (D2=pass-trivial)"
//     if jsdom is unavailable.
//
// Exit codes:
//   0 — all diagrams pass D1 (and D2 when applicable)
//   1 — one or more diagrams failed
//   2 — invocation error (file missing, etc.)

import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const args = process.argv.slice(2);
if (args.length < 1 || args[0] === '--help' || args[0] === '-h') {
	console.error('Usage: validate-diagrams.mjs <html-file> [--fast]');
	process.exit(2);
}

const htmlPath = args[0];
const fastMode = args.includes('--fast');

let html;
try {
	html = await fs.readFile(htmlPath, 'utf-8');
} catch (e) {
	console.error(`❌ Cannot read ${htmlPath}: ${e.message}`);
	process.exit(2);
}

// ---------------------------------------------------------------------------
// Extract Mermaid diagram blocks
// ---------------------------------------------------------------------------

const blockRegex = /<pre\s+class="mermaid"[^>]*>([\s\S]*?)<\/pre>/g;
const decodeHtml = (s) => s
	.replace(/&lt;/g, '<')
	.replace(/&gt;/g, '>')
	.replace(/&quot;/g, '"')
	.replace(/&#39;/g, "'")
	.replace(/&amp;/g, '&');

const blocks = [];
let m;
while ((m = blockRegex.exec(html)) !== null) {
	blocks.push({ index: blocks.length + 1, source: decodeHtml(m[1]).trim() });
}

if (blocks.length === 0) {
	console.error(`⚠️  No <pre class="mermaid"> blocks found in ${htmlPath}`);
	process.exit(0);
}

console.log(`Validating ${blocks.length} Mermaid diagram(s)...`);

// ---------------------------------------------------------------------------
// D1 Layer 1: regex sanity checks (always run)
// ---------------------------------------------------------------------------

function regexCheck(source) {
	const issues = [];

	// HTML-tag-like tokens in labels (other than allowed inline formatting)
	const htmlTagRe = /<\/?([a-zA-Z][a-zA-Z0-9]*)(?:\s[^<>]*)?\s*\/?>/g;
	let tm;
	while ((tm = htmlTagRe.exec(source)) !== null) {
		const tagName = tm[1].toLowerCase();
		if (!['b', 'br', 'i', 'strong', 'em'].includes(tagName)) {
			issues.push({
				severity: 'error',
				message: `Likely HTML-tag-like token in diagram: <${tm[1]}>. ` +
					`Use {${tm[1]}} or [${tm[1]}] instead.`,
				snippet: tm[0],
			});
		}
	}

	// Dotted arrow label without surrounding spaces: -.text.->
	const dottedRe = /-\.[^\s.][^.]*\.->/g;
	let dm;
	while ((dm = dottedRe.exec(source)) !== null) {
		if (!/-\. /.test(dm[0])) {
			issues.push({
				severity: 'warn',
				message: `Dotted-arrow label may need spaces: '${dm[0]}'. Use '-. text .->'`,
				snippet: dm[0],
			});
		}
	}

	// Literal backslash-n in a label — Mermaid does NOT interpret \n as a line
	// break in ANY diagram type (flowchart, stateDiagram, etc.). It renders the
	// two characters literally. Use <br/> for line breaks. D1 (parse) and D2
	// (render) both pass with a literal \n — only this regex catches it.
	const backslashNRe = /\\n/g;
	let bm;
	while ((bm = backslashNRe.exec(source)) !== null) {
		const ctx = source.slice(Math.max(0, bm.index - 25), bm.index + 5).replace(/\n/g, ' ');
		issues.push({
			severity: 'error',
			message: 'Literal "\\n" in a Mermaid label — it renders as the two ' +
				'characters, NOT a line break. Use <br/> instead.',
			snippet: '...' + ctx + '...',
		});
	}

	// Unclosed quotes in node labels
	const labelRe = /\[([^\]]+)\]/g;
	let lm;
	while ((lm = labelRe.exec(source)) !== null) {
		const quoteCount = (lm[1].match(/"/g) || []).length;
		if (quoteCount % 2 !== 0) {
			issues.push({
				severity: 'error',
				message: `Unbalanced quotes in node label: ${lm[0]}`,
				snippet: lm[0],
			});
		}
	}

	// Empty diagram
	const lines = source.split('\n').filter(l => l.trim() && !l.trim().startsWith('%%'));
	if (lines.length < 2) {
		issues.push({
			severity: 'error',
			message: 'Diagram is empty or contains only a directive.',
			snippet: source,
		});
	}

	// Valid diagram type keyword
	const validTypes = [
		'flowchart', 'graph', 'erDiagram', 'sequenceDiagram', 'classDiagram',
		'stateDiagram', 'gantt', 'pie', 'journey', 'gitGraph', 'mindmap',
		'timeline', 'sankey', 'xychart', 'block-beta', 'requirementDiagram',
	];
	const firstLine = lines[0] || '';
	const matched = validTypes.find(t => firstLine.trim().startsWith(t));
	if (!matched) {
		issues.push({
			severity: 'error',
			message: `Diagram type not recognized. First line: '${firstLine.slice(0, 60)}'. ` +
				`Expected one of: ${validTypes.slice(0, 6).join(', ')}, etc.`,
			snippet: firstLine,
		});
	}

	return issues;
}

// ---------------------------------------------------------------------------
// D1+D2 Layer 2: jsdom + inlined Mermaid render
// ---------------------------------------------------------------------------

// Extract the inlined Mermaid <script> source from the HTML
function extractInlinedMermaid(html) {
	// The Mermaid library is inlined as a large <script> block.
	// Heuristic: find the largest <script> block that contains 'mermaid' (case-insensitive).
	const scriptRe = /<script(?:\s[^>]*)?>[\s\S]*?<\/script>/gi;
	let bestMatch = null;
	let bestLen = 0;
	let sm;
	while ((sm = scriptRe.exec(html)) !== null) {
		const content = sm[0];
		if (/mermaid/i.test(content) && content.length > bestLen) {
			bestLen = content.length;
			bestMatch = content;
		}
	}
	if (!bestMatch) return null;
	// Strip opening/closing tags to get just the JS
	const inner = bestMatch.replace(/^<script[^>]*>/i, '').replace(/<\/script>$/i, '');
	return inner;
}

// Check if jsdom is available
async function getJsdom() {
	// Resolve jsdom from the project tree (multiple search locations)
	const searchDirs = [
		path.join(__dirname, '..', '..', '..', 'node_modules'),      // project root
		path.join(__dirname, '..', '..', 'node_modules'),
		path.join(__dirname, '..', 'node_modules'),
		path.join(__dirname, 'node_modules'),
	];
	for (const dir of searchDirs) {
		try {
			const { JSDOM } = await import(path.join(dir, 'jsdom', 'lib', 'jsdom.js').replace(/\\/g, '/'));
			return JSDOM;
		} catch (e) {
			// try next
		}
	}
	// Try bare specifier (works if jsdom is globally installed or in PATH node_modules)
	try {
		const { JSDOM } = await import('jsdom');
		return JSDOM;
	} catch (e) {}
	return null;
}

async function jsdomValidate(blocks, mermaidSource, JSDOM) {
	const d1Failures = [];
	const d2Failures = [];

	for (const b of blocks) {
		// Build a minimal HTML page that loads Mermaid and exposes parse/render
		const pageHtml = `<!DOCTYPE html>
<html><head><meta charset="utf-8"></head>
<body>
<script>${mermaidSource}</script>
</body></html>`;

		let dom;
		try {
			dom = new JSDOM(pageHtml, {
				runScripts: 'dangerously',
				resources: 'usable',
				pretendToBeVisual: true,
			});
		} catch (e) {
			// jsdom setup failure — treat as a tooling error, not a diagram error
			console.warn(`  ⚠️  jsdom init failed: ${e.message} — falling back to regex-only for block ${b.index}`);
			continue;
		}

		const { window } = dom;

		// Give scripts a moment to execute (synchronous in jsdom, but just in case)
		await new Promise(r => setTimeout(r, 0));

		// Locate mermaid on window
		const mermaid = window.mermaid;
		if (!mermaid) {
			console.warn(`  ⚠️  mermaid not found on window after loading inline script (block ${b.index}) — skipping jsdom check`);
			continue;
		}

		// --- D1: parse check ---
		try {
			if (typeof mermaid.parse === 'function') {
				const parseResult = mermaid.parse(b.source);
				// mermaid.parse returns a promise in newer versions
				if (parseResult && typeof parseResult.then === 'function') {
					await parseResult;
				}
			}
		} catch (e) {
			d1Failures.push({
				index: b.index,
				error: `mermaid.parse() threw: ${e.message || String(e)}`,
				source: b.source,
			});
			// Don't attempt D2 if D1 failed
			continue;
		}

		// --- D2: render check (skip in --fast mode) ---
		if (!fastMode && typeof mermaid.render === 'function') {
			try {
				const id = `mermaid-d2-check-${b.index}`;
				let svgOutput = null;

				const renderResult = mermaid.render(id, b.source);
				if (renderResult && typeof renderResult.then === 'function') {
					const resolved = await renderResult;
					// mermaid v10+ returns { svg: '...' }
					svgOutput = (typeof resolved === 'string') ? resolved : (resolved && resolved.svg);
				} else if (typeof renderResult === 'string') {
					svgOutput = renderResult;
				} else if (renderResult && typeof renderResult === 'object' && renderResult.svg) {
					svgOutput = renderResult.svg;
				}

				if (svgOutput === null || svgOutput === undefined) {
					d2Failures.push({
						index: b.index,
						error: 'mermaid.render() returned no SVG output.',
						source: b.source,
					});
				} else if (svgOutput.length < 500) {
					d2Failures.push({
						index: b.index,
						error: `SVG output too small: ${svgOutput.length} bytes (minimum 500).`,
						source: b.source,
					});
				} else if (!/<g[\s>]|<path[\s>]/i.test(svgOutput)) {
					d2Failures.push({
						index: b.index,
						error: 'SVG contains no <g> or <path> elements — likely empty or trivial render.',
						source: b.source,
					});
				} else if (/mermaid-error|Syntax error in graph/i.test(svgOutput)) {
					d2Failures.push({
						index: b.index,
						error: 'SVG contains Mermaid error-block marker (mermaid-error class or "Syntax error in graph").',
						source: b.source,
					});
				}
				// else: render passed
			} catch (e) {
				d2Failures.push({
					index: b.index,
					error: `mermaid.render() threw: ${e.message || String(e)}`,
					source: b.source,
				});
			}
		}

		// Cleanup DOM
		window.close();
	}

	return { d1Failures, d2Failures };
}

// ---------------------------------------------------------------------------
// D2 Layer 3: mmdc fallback (when jsdom unavailable, non-fast mode)
// ---------------------------------------------------------------------------

function checkMmdcAvailable() {
	if (fastMode) return false;
	// shell: true is REQUIRED on Windows — npm global bins are .cmd shims that
	// Node's spawnSync cannot resolve via PATHEXT without a shell.
	try {
		const r = spawnSync('mmdc', ['--version'], { encoding: 'utf-8', stdio: 'pipe', shell: true });
		if (r.status === 0) return 'mmdc';
	} catch (e) {}
	try {
		const r = spawnSync('npx', ['--no', '@mermaid-js/mermaid-cli', '--version'], {
			encoding: 'utf-8', stdio: 'pipe', timeout: 60000, shell: true,
		});
		if (r.status === 0) return 'npx';
	} catch (e) {}
	return false;
}

async function mmdcValidate(blocks) {
	const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'aid-diagrams-'));
	const failures = [];
	const tool = checkMmdcAvailable();

	if (!tool) return null; // signal: mmdc unavailable

	console.log(`  Using ${tool === 'mmdc' ? 'mmdc' : 'npx @mermaid-js/mermaid-cli'} for D2 render validation...`);

	for (const b of blocks) {
		const inFile = path.join(tmpDir, `diagram-${b.index}.mmd`);
		const outFile = path.join(tmpDir, `diagram-${b.index}.svg`);
		await fs.writeFile(inFile, b.source, 'utf-8');

		const cmd = tool === 'mmdc' ? 'mmdc' : 'npx';
		// Quote file paths — with shell: true the args are joined into a command
		// line, so any space in a temp path would otherwise split the argument.
		const qIn = `"${inFile}"`;
		const qOut = `"${outFile}"`;
		const cmdArgs = tool === 'mmdc'
			? ['-i', qIn, '-o', qOut, '--quiet']
			: ['--no', '@mermaid-js/mermaid-cli', '-i', qIn, '-o', qOut, '--quiet'];

		// shell: true is REQUIRED on Windows — see checkMmdcAvailable().
		const r = spawnSync(cmd, cmdArgs, { encoding: 'utf-8', stdio: 'pipe', timeout: 120000, shell: true });

		if (r.status !== 0) {
			failures.push({
				index: b.index,
				error: (r.stderr || r.stdout || 'mmdc exited non-zero').slice(0, 800),
				source: b.source,
			});
			continue;
		}

		try {
			const stat = await fs.stat(outFile);
			if (stat.size < 500) {
				failures.push({
					index: b.index,
					error: `mmdc produced a tiny SVG (${stat.size} bytes, minimum 500).`,
					source: b.source,
				});
			}
			// Check SVG content
			const svgContent = await fs.readFile(outFile, 'utf-8');
			if (!/<g[\s>]|<path[\s>]/i.test(svgContent)) {
				failures.push({
					index: b.index,
					error: 'mmdc SVG contains no <g> or <path> elements.',
					source: b.source,
				});
			} else if (/mermaid-error|Syntax error in graph/i.test(svgContent)) {
				failures.push({
					index: b.index,
					error: 'mmdc SVG contains Mermaid error-block marker.',
					source: b.source,
				});
			}
		} catch (e) {
			failures.push({
				index: b.index,
				error: 'mmdc completed but no SVG was written.',
				source: b.source,
			});
		}
	}

	try { await fs.rm(tmpDir, { recursive: true, force: true }); } catch (e) {}
	return failures;
}

// ---------------------------------------------------------------------------
// Run validation
// ---------------------------------------------------------------------------

// Layer 1: regex (always)
const regexIssues = [];
for (const b of blocks) {
	for (const issue of regexCheck(b.source)) {
		if (issue.severity === 'error') {
			regexIssues.push({ index: b.index, error: issue.message, source: b.source, snippet: issue.snippet });
		}
	}
}

// If regex already found D1 failures, report immediately without attempting render
if (regexIssues.length > 0) {
	const failedIndices = new Set(regexIssues.map(i => i.index));
	console.error('');
	console.error(`❌ D1: ${failedIndices.size} of ${blocks.length} diagram(s) failed regex sanity check (${regexIssues.length} issues)`);
	for (const f of regexIssues) {
		console.error(`--- Figure ${f.index} ---`);
		console.error(`Error: ${f.error}`);
		if (f.snippet) console.error(`Snippet: ${f.snippet}`);
		console.error(`Source (first 400 chars): ${f.source.slice(0, 400)}`);
		console.error('');
	}
	console.error('See templates/knowledge-summary/mermaid-examples.md "Common failure patterns" for fixes.');
	process.exit(1);
}

// Layer 2: jsdom + inlined Mermaid (D1 parse + D2 render)
let d1JsdomFailed = false;
let d2Checked = false;
let d2JsdomFailed = false;

if (!fastMode) {
	const JSDOM = await getJsdom();

	if (JSDOM) {
		console.log('  D1: using jsdom + inlined Mermaid for parse check');
		const mermaidSource = extractInlinedMermaid(html);

		if (mermaidSource) {
			console.log('  D2: using jsdom + inlined Mermaid for render check');
			d2Checked = true;

			let jsdomResult;
			try {
				jsdomResult = await jsdomValidate(blocks, mermaidSource, JSDOM);
			} catch (e) {
				console.warn(`  ⚠️  jsdom validation aborted: ${e.message}`);
				jsdomResult = null;
			}

			if (jsdomResult) {
				const { d1Failures, d2Failures } = jsdomResult;

				if (d1Failures.length > 0) {
					d1JsdomFailed = true;
					const failedIndices = new Set(d1Failures.map(i => i.index));
					console.error('');
					console.error(`❌ D1: ${failedIndices.size} of ${blocks.length} diagram(s) failed mermaid.parse() (${d1Failures.length} issues)`);
					for (const f of d1Failures) {
						console.error(`--- Figure ${f.index} ---`);
						console.error(`Error: ${f.error}`);
						console.error(`Source (first 400 chars): ${f.source.slice(0, 400)}`);
						console.error('');
					}
					console.error('See templates/knowledge-summary/mermaid-examples.md for fixes.');
					process.exit(1);
				}

				if (d2Failures.length > 0) {
					d2JsdomFailed = true;
					const failedIndices = new Set(d2Failures.map(i => i.index));
					console.error('');
					console.error(`❌ D2: ${failedIndices.size} of ${blocks.length} diagram(s) failed render check (${d2Failures.length} issues)`);
					for (const f of d2Failures) {
						console.error(`--- Figure ${f.index} ---`);
						console.error(`Error: ${f.error}`);
						console.error(`Source (first 400 chars): ${f.source.slice(0, 400)}`);
						console.error('');
					}
					process.exit(1);
				}

				// All passed jsdom checks
				console.log(`✅ D1: All ${blocks.length} diagrams parse cleanly (mermaid.parse() via jsdom).`);
				console.log(`✅ D2: All ${blocks.length} diagrams render non-trivial SVG (mermaid.render() via jsdom).`);
				process.exit(0);
			}
		} else {
			console.warn('  ⚠️  Could not extract inlined Mermaid source from HTML; skipping jsdom parse/render checks.');
		}
	} else {
		// jsdom not available — try mmdc for D2.
		// IMPORTANT: do NOT print "pass-trivial" here — that verdict is only
		// correct if mmdc ALSO turns out to be unavailable (handled below).
		// Emitting it early poisons grade.sh's D2 log parser.
		console.warn('  D2: jsdom not installed — attempting mmdc fallback for render check');
		console.warn('      (install jsdom for in-process render validation: npm install jsdom)');

		const mmdcFailures = await mmdcValidate(blocks).catch(e => {
			console.warn(`  ⚠️  mmdc D2 check aborted: ${e.message}`);
			return null;
		});

		if (mmdcFailures !== null) {
			// mmdc was available and ran
			d2Checked = true;
			if (mmdcFailures.length > 0) {
				d2JsdomFailed = true;
				const failedIndices = new Set(mmdcFailures.map(i => i.index));
				console.error('');
				console.error(`❌ D2: ${failedIndices.size} of ${blocks.length} diagram(s) failed mmdc render check`);
				for (const f of mmdcFailures) {
					console.error(`--- Figure ${f.index} ---`);
					console.error(`Error: ${f.error}`);
					console.error(`Source (first 400 chars): ${f.source.slice(0, 400)}`);
					console.error('');
				}
				process.exit(1);
			}
			console.log(`✅ D1: All ${blocks.length} diagrams pass regex sanity check.`);
			console.log(`✅ D2: All ${blocks.length} diagrams render cleanly (mmdc).`);
		} else {
			// Neither jsdom nor mmdc — D2 trivially passes with a note
			console.log(`✅ D1: All ${blocks.length} diagrams pass regex sanity check.`);
			console.log(`   D2: pass-trivial (jsdom and mmdc both unavailable — install jsdom for real render check).`);
		}
		process.exit(0);
	}
}

// fast mode or jsdom/mermaid-source unavailable: regex-only summary
if (fastMode) {
	console.log(`✅ D1: All ${blocks.length} diagrams pass regex sanity check (--fast mode; parse/render skipped).`);
} else {
	console.log(`✅ D1: All ${blocks.length} diagrams pass regex sanity check (jsdom/Mermaid extraction unavailable).`);
	console.log(`   D2: pass-trivial (jsdom not installed — install for real render check).`);
}

process.exit(0);
