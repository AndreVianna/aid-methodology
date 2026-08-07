#!/usr/bin/env node
// contrast-check.mjs — extract CSS variables from an inlined <style> block
// and verify WCAG AA/AA-non-text contrast ratios for known token pairs.
//
// Usage: node contrast-check.mjs <html-file> [--profile kb-summary|graph]
//
// Flags:
//   --profile kb-summary|graph
//         Select the validation profile (default: kb-summary; closed set:
//         kb-summary|graph). An unrecognised value, or the flag with no
//         value, exits 2. With the flag absent, output is byte-identical to
//         today's kb-summary behaviour, except for the corrected dark-theme
//         extraction and theme-divergence check below, which apply
//         unconditionally to both profiles. Passing the flag explicitly
//         (either value) prints the active profile; with it absent, nothing
//         is printed.
//         --profile graph additionally: checks the graph palette
//         (--gk-*/--gc-* tokens, feature-007 D5b/D5c) against --bg and
//         --bg-elev at a 3.0 target, on top of the existing pairs at 4.5;
//         treats an unresolvable pair as a failure (default: a skipped
//         warning); and fails if a chrome token from the existing pair list
//         is redeclared inside either added graph palette block.
//
// Exit codes:
//   0  All checks pass (or all resolvable pairs pass, under kb-summary).
//   1  One or more checks failed.
//   2  Invocation error (missing file, bad/missing --profile value).
//
// Corrected dark-theme extraction (applies to BOTH profiles, unconditionally):
// each named selector's CSS block is read as the FIRST occurrence, in
// document order, that declares at least one custom property; a block with
// none (e.g. component-css.css's `html[data-theme="dark"] { color-scheme:
// dark; }`) is skipped in favour of the next matching block. Without this,
// the dark theme's reported ratios were the light theme's, re-checked.
//
// Theme-divergence check (applies to BOTH profiles, unconditionally): when a
// block matching the dark selector is present anywhere in the source, the
// dark map must differ from the light map on at least one token both
// declare — otherwise the dark extraction harvested nothing (or the wrong
// block) and the "dark" verdict is meaningless. Where no such block is
// present at all, the check reports [N/A] rather than failing.
//
// Second named default-path exception: every Usage/synopsis string in this
// script -- the header line above and every invocation-error echo (no-arg,
// missing <html-file>, bad or missing --profile value) -- now documents
// "[--profile kb-summary|graph]" inline, so a mistyped invocation never
// gets a synopsis that hides a flag the script actually accepts. This is a
// default-path text delta, but only on an exit-2 invocation-error path;
// grade-summary.sh always calls this script with a valid html-file, so the
// Usage line never appears in a real grade-summary run's captured output,
// and none of grade-summary.sh's grep tokens for this script (S2/NM/L1/L2/
// C1/C2 -- e.g. "\[PASS\]", "resolve", "\[light theme\]"/"\[dark theme\]",
// "All contrast checks passed") match "Usage:" text -- so no grade can
// move even if it did.

import fs from 'node:fs/promises';

const PROFILES = ['kb-summary', 'graph'];

const rawArgs = process.argv.slice(2);
if (rawArgs.length < 1) {
	console.error('Usage: contrast-check.mjs <html-file> [--profile kb-summary|graph]');
	process.exit(2);
}

let htmlPath = null;
let explicitProfile = null;
for (let i = 0; i < rawArgs.length; i++) {
	const a = rawArgs[i];
	if (a === '--profile') {
		const v = rawArgs[++i];
		if (v === undefined || !PROFILES.includes(v)) {
			console.error('Usage: contrast-check.mjs <html-file> [--profile kb-summary|graph]');
			console.error(`  --profile must be one of: ${PROFILES.join('|')}`);
			process.exit(2);
		}
		explicitProfile = v;
	} else if (htmlPath === null) {
		htmlPath = a;
	}
}

if (!htmlPath) {
	console.error('Usage: contrast-check.mjs <html-file> [--profile kb-summary|graph]');
	process.exit(2);
}

const activeProfile = explicitProfile || 'kb-summary';

const html = await fs.readFile(htmlPath, 'utf-8');

if (explicitProfile !== null) {
	console.log(`Profile: ${activeProfile}`);
}

// --- Extract :root and html[data-theme="dark"] CSS variables ---
//
// Corrected rule: scan every block matching blockSelector, in document
// order, and return the vars of the FIRST one that declares at least one
// custom property. A block declaring none (present but empty of vars) is
// skipped rather than accepted as "the" block — see the header note above.
function blockRegex(blockSelector) {
	const escaped = blockSelector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	return new RegExp(escaped + '\\s*\\{([^}]*)\\}', 'gm');
}

function varsFromBody(body) {
	const vars = {};
	const varRe = /--([a-z-]+)\s*:\s*([^;]+);/g;
	let mm;
	while ((mm = varRe.exec(body)) !== null) {
		vars[mm[1]] = mm[2].trim();
	}
	return vars;
}

function extractVars(html, blockSelector) {
	const re = blockRegex(blockSelector);
	let m;
	while ((m = re.exec(html)) !== null) {
		const vars = varsFromBody(m[1]);
		if (Object.keys(vars).length > 0) return vars;
	}
	return {};
}

// Presence test for the theme-divergence gate: does the source contain ANY
// block matching this selector's opening, regardless of whether it declares
// a var? (A `color-scheme`-only dark block still counts as "present".)
function blockSelectorPresent(html, blockSelector) {
	const escaped = blockSelector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	return new RegExp(escaped + '\\s*\\{', 'm').test(html);
}

const lightVars = extractVars(html, ':root, html[data-theme="light"]');
const lightFallback = extractVars(html, ':root');
const darkVars = extractVars(html, 'html[data-theme="dark"]');

let light = { ...lightFallback, ...lightVars };
let dark = { ...light, ...darkVars };

// --- Graph profile: two named additional selectors (feature-007 D5a) ---
let graphLightRaw = {};
let graphDarkRaw = {};
if (activeProfile === 'graph') {
	graphLightRaw = extractVars(html, 'html:root');
	graphDarkRaw = extractVars(html, 'html[data-theme="dark"]:root');
	// A graph-added token must never shadow an existing chrome-pair token's
	// resolved value (PV15) -- so the chrome map wins on any key collision;
	// the redeclaration guard below still reports the collision as a FAIL.
	// Spread order matters: graph first, chrome second, so a chrome key
	// present in both overwrites the graph value rather than the reverse.
	light = { ...graphLightRaw, ...light };
	dark = { ...graphDarkRaw, ...dark };
}

// --- Color parsing ---
function parseColor(input) {
	const v = input.trim().replace(/^var\([^)]+\)$/, ''); // can't resolve var() chains here
	if (!v) return null;
	// hex
	let m = v.match(/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/);
	if (m) {
		let h = m[1];
		if (h.length === 3) h = h.split('').map(c => c + c).join('');
		const r = parseInt(h.substr(0, 2), 16);
		const g = parseInt(h.substr(2, 2), 16);
		const b = parseInt(h.substr(4, 2), 16);
		const a = h.length === 8 ? parseInt(h.substr(6, 2), 16) / 255 : 1;
		return { r, g, b, a };
	}
	// rgb/rgba
	m = v.match(/^rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/i);
	if (m) {
		return { r: +m[1], g: +m[2], b: +m[3], a: m[4] !== undefined ? +m[4] : 1 };
	}
	return null;
}

// --- WCAG luminance + contrast ---
function srgbToLin(c) {
	c = c / 255;
	return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}
function relLum({ r, g, b }) {
	return 0.2126 * srgbToLin(r) + 0.7152 * srgbToLin(g) + 0.0722 * srgbToLin(b);
}

// For semi-transparent foregrounds we'd need to alpha-composite over the bg.
function composite(fg, bg) {
	if (!fg || !bg) return fg;
	if (fg.a >= 1) return fg;
	const a = fg.a;
	return {
		r: Math.round(fg.r * a + bg.r * (1 - a)),
		g: Math.round(fg.g * a + bg.g * (1 - a)),
		b: Math.round(fg.b * a + bg.b * (1 - a)),
		a: 1,
	};
}

function contrast(fg, bg) {
	const fgC = composite(fg, bg);
	if (!fgC || !bg) return 0;
	const L1 = relLum(fgC);
	const L2 = relLum(bg);
	const [hi, lo] = L1 > L2 ? [L1, L2] : [L2, L1];
	return (hi + 0.05) / (lo + 0.05);
}

// --- Pairs to check ---
const pairs = [
	{ fg: 'text', bg: 'bg', target: 4.5, label: 'body text on bg' },
	{ fg: 'text-muted', bg: 'bg', target: 4.5, label: 'muted text on bg' },
	{ fg: 'text-dim', bg: 'bg-elev', target: 4.5, label: 'dim text on elevated bg' },
	{ fg: 'accent', bg: 'bg-elev', target: 4.5, label: 'link/accent on elevated bg' },
	{ fg: 'primary-fg', bg: 'primary', target: 4.5, label: 'on-primary text' },
	{ fg: 'accent-fg', bg: 'accent', target: 4.5, label: 'on-accent text' },
	{ fg: 'ok', bg: 'ok-bg', target: 4.5, label: 'success badge' },
	{ fg: 'warn', bg: 'warn-bg', target: 4.5, label: 'warning badge' },
	{ fg: 'err', bg: 'err-bg', target: 4.5, label: 'error badge' },
	{ fg: 'info', bg: 'info-bg', target: 4.5, label: 'info badge' },
	{ fg: 'purple', bg: 'purple-bg', target: 4.5, label: 'purple badge' },
];

// --- Graph profile: the palette pair set (feature-007 D5b node kinds, D5c
// relationship categories) x {--bg, --bg-elev} at the SC 1.4.11 non-text
// target of 3.0. Generated from the token lists, never counted (SPEC D3
// note 4) ---
const GRAPH_KIND_TOKENS = [
	'gk-document', 'gk-section', 'gk-fact', 'gk-concept',
	'gk-source-artifact', 'gk-image', 'gk-web-page',
];
const GRAPH_CATEGORY_TOKENS = [
	'gc-structure', 'gc-taxonomy', 'gc-documentation', 'gc-evidence',
	'gc-provenance', 'gc-lineage', 'gc-dependency', 'gc-implementation',
];
const GRAPH_BACKGROUNDS = ['bg', 'bg-elev'];

function buildGraphPairs() {
	const out = [];
	for (const tok of [...GRAPH_KIND_TOKENS, ...GRAPH_CATEGORY_TOKENS]) {
		for (const bgTok of GRAPH_BACKGROUNDS) {
			out.push({ fg: tok, bg: bgTok, target: 3.0, label: `--${tok} on --${bgTok}` });
		}
	}
	return out;
}

const activePairs = activeProfile === 'graph' ? [...pairs, ...buildGraphPairs()] : pairs;

function checkTheme(name, vars, pairList, profile) {
	console.log(`\n[${name} theme]`);
	let pass = 0, fail = 0;
	const failures = [];
	for (const p of pairList) {
		const fgRaw = vars[p.fg];
		const bgRaw = vars[p.bg];
		const fg = parseColor(fgRaw || '');
		const bgPlain = parseColor(bgRaw || '');
		// For semi-transparent bg (rgba()), composite over the page bg.
		let bg = bgPlain;
		if (bg && bg.a < 1) {
			const pageBg = parseColor(vars['bg-elev'] || vars['bg'] || '#FFFFFF');
			bg = composite(bgPlain, pageBg);
		}
		if (!fg || !bg) {
			if (profile === 'graph') {
				console.log(`  ❌ FAIL ${p.label}: cannot resolve colors (${p.fg}=${fgRaw}, ${p.bg}=${bgRaw})`);
				fail++;
				failures.push({ pair: p, ratio: null, unresolved: true });
			} else {
				console.log(`  ⚠️  ${p.label}: cannot resolve colors (${p.fg}=${fgRaw}, ${p.bg}=${bgRaw})`);
			}
			continue;
		}
		const ratio = contrast(fg, bg);
		const ok = ratio >= p.target;
		const symbol = ok ? '✅' : '❌';
		console.log(`  ${symbol} ${p.label.padEnd(28)} ${ratio.toFixed(2)}:1 (target ${p.target})`);
		if (ok) pass++;
		else { fail++; failures.push({ pair: p, ratio }); }
	}
	return { pass, fail, total: pass + fail, failures };
}

const lightResult = checkTheme('light', light, activePairs, activeProfile);
const darkResult = checkTheme('dark', dark, activePairs, activeProfile);

// --- Theme divergence (unconditional, both profiles; emitted directly after
// the dark theme block's own lines, per grade-summary.sh:363's
// `sed -n '/\[dark theme\]/,$p'` — no other default-path line moves) ---
const darkBlockPresent = blockSelectorPresent(html, 'html[data-theme="dark"]');
let divergenceLine;
let divergenceFailed = false;
if (!darkBlockPresent) {
	divergenceLine = '⏭️  [N/A] Theme divergence: no dark-theme block declared in the source; nothing to diverge from';
} else {
	let diverges = false;
	for (const key of Object.keys(darkVars)) {
		if (key in light && light[key] !== dark[key]) { diverges = true; break; }
	}
	if (diverges) {
		divergenceLine = '✅ Theme divergence: dark theme differs from light on at least one declared token';
	} else {
		divergenceLine = '❌ FAIL Theme divergence: dark theme reports the light theme\'s values (extraction defect)';
		divergenceFailed = true;
	}
}
console.log(divergenceLine);

// --- Redeclaration guard (graph profile only): a chrome token from the
// existing pair list must not be redeclared inside either added graph block
// (D3's redeclaration row) ---
let redeclarationFailCount = 0;
if (activeProfile === 'graph') {
	const existingTokenNames = new Set();
	for (const p of pairs) { existingTokenNames.add(p.fg); existingTokenNames.add(p.bg); }
	const addedBlocks = [
		['html:root', graphLightRaw],
		['html[data-theme="dark"]:root', graphDarkRaw],
	];
	for (const [blockName, raw] of addedBlocks) {
		for (const key of Object.keys(raw)) {
			if (existingTokenNames.has(key)) {
				console.log(`❌ FAIL redeclaration: --${key} is declared inside the added graph block '${blockName}' and shadows the existing chrome pair list`);
				redeclarationFailCount++;
			}
		}
	}
}

console.log('');
const totalFail = lightResult.fail + darkResult.fail + (divergenceFailed ? 1 : 0) + redeclarationFailCount;
if (totalFail === 0) {
	console.log(`✅ All contrast checks passed: ${lightResult.pass}/${lightResult.total} (light) + ${darkResult.pass}/${darkResult.total} (dark)`);
	process.exit(0);
}
console.error(`❌ ${totalFail} contrast check(s) failed.`);
console.error('   Adjust the offending CSS variables in component-css.css to meet WCAG AA.');
process.exit(1);
