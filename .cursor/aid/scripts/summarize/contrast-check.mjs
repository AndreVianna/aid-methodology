#!/usr/bin/env node
// contrast-check.mjs — extract CSS variables from an inlined <style> block
// and verify WCAG AA contrast ratios for known token pairs.
//
// Usage: node contrast-check.mjs <html-file>
// Exit 0 if all pairs pass, 1 if any fail.

import fs from 'node:fs/promises';

const args = process.argv.slice(2);
if (args.length < 1) {
	console.error('Usage: contrast-check.mjs <html-file>');
	process.exit(2);
}

const html = await fs.readFile(args[0], 'utf-8');

// --- Extract :root and html[data-theme="dark"] CSS variables ---
function extractVars(html, blockSelector) {
	// Find a CSS block that opens with the given selector
	const re = new RegExp(blockSelector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*\\{([^}]*)\\}', 'm');
	const m = html.match(re);
	if (!m) return {};
	const body = m[1];
	const vars = {};
	const varRe = /--([a-z-]+)\s*:\s*([^;]+);/g;
	let mm;
	while ((mm = varRe.exec(body)) !== null) {
		vars[mm[1]] = mm[2].trim();
	}
	return vars;
}

const lightVars = extractVars(html, ':root, html[data-theme="light"]');
const lightFallback = extractVars(html, ':root');
const darkVars = extractVars(html, 'html[data-theme="dark"]');

// Merge fallbacks
const light = { ...lightFallback, ...lightVars };
const dark = { ...light, ...darkVars };

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

function checkTheme(name, vars) {
	console.log(`\n[${name} theme]`);
	let pass = 0, fail = 0;
	const failures = [];
	for (const p of pairs) {
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
			console.log(`  ⚠️  ${p.label}: cannot resolve colors (${p.fg}=${fgRaw}, ${p.bg}=${bgRaw})`);
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

const lightResult = checkTheme('light', light);
const darkResult = checkTheme('dark', dark);

console.log('');
const totalFail = lightResult.fail + darkResult.fail;
if (totalFail === 0) {
	console.log(`✅ All contrast checks passed: ${lightResult.pass}/${lightResult.total} (light) + ${darkResult.pass}/${darkResult.total} (dark)`);
	process.exit(0);
}
console.error(`❌ ${totalFail} contrast check(s) failed.`);
console.error('   Adjust the offending CSS variables in component-css.css to meet WCAG AA.');
process.exit(1);
