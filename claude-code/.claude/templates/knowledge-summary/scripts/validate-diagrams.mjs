#!/usr/bin/env node
// validate-diagrams.mjs — extract every <pre class="mermaid"> block from an HTML
// file and validate that each parses and renders correctly.
//
// Usage: node validate-diagrams.mjs <html-file> [--fast]
//
// Validation strategy (in order of preference):
//   1. mmdc (mermaid-cli) — official tool, full parse + render. Slower first run.
//   2. Lightweight regex sanity check — fallback when mmdc is unavailable.
//      Only catches the patterns documented in mermaid-examples.md, not all
//      possible syntax errors. Sufficient for D1 (parse) but not D2 (render).
//
// Exit codes:
//   0 — all diagrams pass
//   1 — one or more diagrams failed (details on stderr)
//   2 — invocation error (file missing, etc.)
//
// --fast flag: skip mmdc and use only regex fallback. For development; do NOT
// use for grading runs.

import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';

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

// Extract every <pre class="mermaid">...</pre> block
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
	blocks.push({
		index: blocks.length + 1,
		source: decodeHtml(m[1]).trim(),
	});
}

if (blocks.length === 0) {
	console.error(`⚠️  No <pre class="mermaid"> blocks found in ${htmlPath}`);
	process.exit(0);
}

console.log(`Validating ${blocks.length} Mermaid diagram(s)...`);

/* ---------- Layer 1: regex sanity check (always runs) ---------- */

function regexCheck(source, index) {
	const issues = [];

	// Check 1: HTML-tag-like tokens in labels (other than <b>, <br>, <br/>)
	// Look for patterns like <word> or </word> that aren't <b> or <br>
	const htmlTagRe = /<\/?([a-zA-Z][a-zA-Z0-9]*)(?:\s[^<>]*)?\s*\/?>/g;
	let tm;
	while ((tm = htmlTagRe.exec(source)) !== null) {
		const tagName = tm[1].toLowerCase();
		if (tagName !== 'b' && tagName !== 'br' && tagName !== 'i' &&
			tagName !== 'strong' && tagName !== 'em') {
			issues.push({
				severity: 'error',
				message: `Likely HTML-tag-like token in diagram: <${tm[1]}>. ` +
					`Mermaid will treat this as HTML. Use {${tm[1]}} or [${tm[1]}] instead.`,
				snippet: tm[0],
			});
		}
	}

	// Check 2: Dotted arrow with label but no spaces: -.text.->
	// Should be: -. text .->
	const dottedRe = /-\.[^\s.][^.]*\.->/g;
	let dm;
	while ((dm = dottedRe.exec(source)) !== null) {
		// Skip if it's already correctly spaced (heuristic: starts with space)
		if (!/-\. /.test(dm[0])) {
			issues.push({
				severity: 'warn',
				message: `Dotted-arrow label may need spaces: '${dm[0]}'. ` +
					`Use '-. text .->' (with spaces).`,
				snippet: dm[0],
			});
		}
	}

	// Check 3: Continuation arrow with no source on a new line
	// e.g. "    --> NextNode" by itself is valid in modern Mermaid but fragile.
	// We don't flag this as error — modern Mermaid handles it.

	// Check 4: Unclosed quotes in node labels
	// Count " inside [ ] groups; should be even.
	const labelRe = /\[([^\]]+)\]/g;
	let lm;
	while ((lm = labelRe.exec(source)) !== null) {
		const labelContent = lm[1];
		const quoteCount = (labelContent.match(/"/g) || []).length;
		if (quoteCount % 2 !== 0) {
			issues.push({
				severity: 'error',
				message: `Unbalanced quotes in node label: ${lm[0]}`,
				snippet: lm[0],
			});
		}
	}

	// Check 5: Empty diagram (just the directive)
	const lines = source.split('\n').filter(l => l.trim() && !l.trim().startsWith('%%'));
	if (lines.length < 2) {
		issues.push({
			severity: 'error',
			message: 'Diagram is empty or contains only a directive.',
			snippet: source,
		});
	}

	// Check 6: Valid diagram type keyword present
	const validTypes = [
		'flowchart', 'graph', 'erDiagram', 'sequenceDiagram', 'classDiagram',
		'stateDiagram', 'gantt', 'pie', 'journey', 'gitGraph', 'mindmap',
		'timeline', 'sankey', 'xychart', 'block-beta', 'requirementDiagram',
	];
	const firstLine = lines[0] || '';
	const firstWord = firstLine.trim().split(/[\s-]/)[0];
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

/* ---------- Layer 2: mmdc (mermaid-cli) — full parse + render ---------- */

function checkMmdcAvailable() {
	if (fastMode) return false;
	// Try mmdc directly
	try {
		const r = spawnSync('mmdc', ['--version'], { encoding: 'utf-8', stdio: 'pipe' });
		if (r.status === 0) return 'mmdc';
	} catch (e) {}
	// Try via npx
	try {
		const r = spawnSync('npx', ['--yes', '@mermaid-js/mermaid-cli', '--version'], {
			encoding: 'utf-8', stdio: 'pipe', timeout: 60000,
		});
		if (r.status === 0) return 'npx';
	} catch (e) {}
	return false;
}

async function mmdcValidate(blocks) {
	const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'aid-summarize-'));
	const failures = [];
	const tool = checkMmdcAvailable();
	if (!tool) {
		console.warn('⚠️  mmdc not available; falling back to regex-only validation.');
		console.warn('    Install with: npm install -g @mermaid-js/mermaid-cli');
		console.warn('    Or use --fast to suppress this warning.');
		return null; // signals fallback
	}

	console.log(`  Using ${tool === 'mmdc' ? 'mmdc' : 'npx @mermaid-js/mermaid-cli'} for validation...`);

	for (const b of blocks) {
		const inFile = path.join(tmpDir, `diagram-${b.index}.mmd`);
		const outFile = path.join(tmpDir, `diagram-${b.index}.svg`);
		await fs.writeFile(inFile, b.source, 'utf-8');

		const cmd = tool === 'mmdc' ? 'mmdc' : 'npx';
		const cmdArgs = tool === 'mmdc'
			? ['-i', inFile, '-o', outFile, '--quiet']
			: ['--yes', '@mermaid-js/mermaid-cli', '-i', inFile, '-o', outFile, '--quiet'];

		const r = spawnSync(cmd, cmdArgs, {
			encoding: 'utf-8', stdio: 'pipe', timeout: 120000,
		});

		if (r.status !== 0) {
			failures.push({
				index: b.index,
				error: (r.stderr || r.stdout || 'mmdc exited non-zero').slice(0, 800),
				source: b.source,
			});
			continue;
		}

		// Verify SVG was produced and isn't empty
		try {
			const stat = await fs.stat(outFile);
			if (stat.size < 200) {
				failures.push({
					index: b.index,
					error: `mmdc produced an empty/tiny SVG (${stat.size} bytes).`,
					source: b.source,
				});
			}
		} catch (e) {
			failures.push({
				index: b.index,
				error: `mmdc completed but no SVG was written.`,
				source: b.source,
			});
		}
	}

	// Cleanup
	try { await fs.rm(tmpDir, { recursive: true, force: true }); } catch (e) {}
	return failures;
}

/* ---------- Run validation ---------- */

const allIssues = [];

// Layer 1: regex check (always)
for (const b of blocks) {
	const issues = regexCheck(b.source, b.index);
	for (const issue of issues) {
		if (issue.severity === 'error') {
			allIssues.push({ index: b.index, error: issue.message, source: b.source, snippet: issue.snippet });
		}
	}
}

// Layer 2: mmdc (preferred)
let mmdcFailures = null;
if (!fastMode) {
	try {
		mmdcFailures = await mmdcValidate(blocks);
	} catch (e) {
		console.warn(`⚠️  mmdc validation aborted: ${e.message}`);
	}
}

if (mmdcFailures && mmdcFailures.length > 0) {
	for (const f of mmdcFailures) {
		// Skip if regex already flagged this index
		if (!allIssues.some(i => i.index === f.index)) {
			allIssues.push(f);
		}
	}
}

if (allIssues.length === 0) {
	if (!mmdcFailures && !fastMode) {
		console.log(`✅ All ${blocks.length} diagrams pass regex sanity check (mmdc unavailable — D2 not verified).`);
		console.log(`   For full validation, install: npm install -g @mermaid-js/mermaid-cli`);
	} else {
		console.log(`✅ All ${blocks.length} diagrams parse and render cleanly.`);
	}
	process.exit(0);
}

// Report failures (de-duplicated by figure index for the count)
const failedIndices = new Set(allIssues.map(i => i.index));
console.error('');
console.error(`❌ ${failedIndices.size} of ${blocks.length} diagram(s) failed validation (${allIssues.length} issues)`);
console.error('');
for (const f of allIssues) {
	console.error(`--- Figure ${f.index} ---`);
	console.error(`Error: ${f.error}`);
	if (f.snippet) console.error(`Snippet: ${f.snippet}`);
	console.error(`Source (first 400 chars):`);
	console.error(f.source.slice(0, 400));
	console.error('');
}
console.error(`See references/mermaid-examples.md "Common failure patterns" for fixes.`);
process.exit(1);
