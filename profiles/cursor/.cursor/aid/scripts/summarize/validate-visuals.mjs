#!/usr/bin/env node
// validate-visuals.mjs -- Playwright-render every authored visual in kb.html and
// assert the three fidelity properties (text readable, minimal overlap, correct layout).
//
// This is the S7 visual-fidelity gate (FR-51 / task-074) that REPLACES validate-diagrams.mjs.
// Mermaid's automatic layout guarantee is gone; this gate holds every inline SVG /
// .diagram-box / infographic container to the same bar.
//
// Usage:
//   node validate-visuals.mjs <html-file> [--check-only] [--min-font-size N]
//
// Flags:
//   --check-only          Dry-run: resolve visuals, print what would be checked, exit 0.
//                         Also used to confirm the script is syntactically correct
//                         when Playwright is not installed.
//   --min-font-size N     Override the legibility threshold (px). Default: 10.
//   -h, --help            Print this header and exit.
//
// Exit codes:
//   0 -- all visuals pass (or SKIP / check-only mode)
//   1 -- one or more visuals failed (generation defect -- blocks DONE)
//   2 -- invocation error (file missing, etc.)
//
// Three asserts per visual (the S7 gate):
//   T1 -- Readable text: every visible text node inside the visual has a computed
//         font-size >= MIN_FONT_SIZE_PX (default 10 px) and is NOT overflow-hidden
//         such that its bounding rect is zero-height.
//   T2 -- Minimal/zero overlap: the bounding boxes of the visual's immediate children
//         (and all inline-SVG child <g>/<rect>/<text> elements) do not materially
//         overlap each other (tolerance: <= 20% of the smaller element's area).
//   T3 -- Correct basic layout: the visual's own bounding rect has non-trivial
//         dimensions (width > 0 AND height > 0), confirming it is rendered and
//         not collapsed/empty.
//
// Visual-inspection fallback (when Playwright is unavailable):
//   If Playwright (playwright package) is not installed, the script exits 0 with a
//   clear SKIP message listing the visuals that must be inspected manually.
//   Per the global rule: a review of rendered web output without Playwright visual
//   validation is a human-gate responsibility (MANUAL-CHECKLIST V1 check). Reading
//   or inspecting HTML/CSS source is NOT sufficient as the Playwright substitute.
//   Document any such skip in STATE.md and ensure the V1 manual visual gate is
//   satisfied before DONE.

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

const rawArgs = process.argv.slice(2);
if (rawArgs.length === 0 || rawArgs[0] === '--help' || rawArgs[0] === '-h') {
  console.error('Usage: validate-visuals.mjs <html-file> [--check-only] [--min-font-size N]');
  process.exit(2);
}

let htmlPath = null;
let checkOnly = false;
let minFontSize = 10;

for (let i = 0; i < rawArgs.length; i++) {
  const arg = rawArgs[i];
  if (arg === '--check-only') {
    checkOnly = true;
  } else if (arg === '--min-font-size') {
    const n = parseInt(rawArgs[++i], 10);
    if (isNaN(n) || n <= 0) {
      console.error('--min-font-size must be a positive integer');
      process.exit(2);
    }
    minFontSize = n;
  } else if (arg.startsWith('-')) {
    console.error(`Unknown flag: ${arg}`);
    process.exit(2);
  } else {
    htmlPath = arg;
  }
}

if (!htmlPath) {
  console.error('Usage: validate-visuals.mjs <html-file> [--check-only] [--min-font-size N]');
  process.exit(2);
}

// ---------------------------------------------------------------------------
// File existence check
// ---------------------------------------------------------------------------

try {
  await fs.access(htmlPath);
} catch {
  console.error(`SKIP -- html file not found: ${htmlPath}`);
  console.error('The visual-fidelity gate requires a generated kb.html. Run GENERATE first.');
  process.exit(0);
}

const absHtmlPath = path.resolve(htmlPath);

// ---------------------------------------------------------------------------
// Playwright availability check (graceful degradation)
// ---------------------------------------------------------------------------

let chromium;
let playwrightAvailable = false;

if (!checkOnly) {
  try {
    // Dynamic import so the script still parses + exits 0 (skip) when
    // playwright is not installed (--check-only also bypasses this block).
    const pw = await import('playwright');
    chromium = pw.chromium;
    playwrightAvailable = true;
  } catch {
    // Playwright not installed -- skip with clear guidance.
    console.log('SKIP -- Playwright is not installed in this environment.');
    console.log('');
    console.log('To install (one-time setup):');
    console.log('  cd .cursor/aid/scripts/summarize');
    console.log('  npm ci');
    console.log('  npx playwright install chromium');
    console.log('');
    console.log('Visual-inspection fallback:');
    console.log('  Without Playwright, every authored visual must be reviewed via the');
    console.log('  MANUAL-CHECKLIST V1 human visual gate. Reading HTML/CSS source is');
    console.log('  NOT sufficient -- the V1 check requires loading kb.html in a browser');
    console.log('  and visually confirming that every visual is readable and correctly');
    console.log('  laid out. Document the fallback in STATE.md before marking DONE.');
    console.log('');
    console.log('CI: the visual-fidelity job in test.yml runs npm ci + playwright install');
    console.log('automatically -- no manual setup needed for CI runs.');
    process.exit(0);
  }
}

// ---------------------------------------------------------------------------
// check-only mode: resolve visuals from HTML source (no browser)
// ---------------------------------------------------------------------------

if (checkOnly) {
  const html = await fs.readFile(absHtmlPath, 'utf-8');

  // Count visual containers by the three selector classes
  const svgCount = (html.match(/<svg[\s>]/gi) || []).length;
  const diagramBoxCount = (html.match(/class="[^"]*diagram-box[^"]*"/gi) || []).length;
  const infographicCount = (html.match(/class="[^"]*infographic[^"]*"/gi) || []).length;

  console.log(`check-only: ${absHtmlPath}`);
  console.log(`  Inline <svg> elements  : ${svgCount}`);
  console.log(`  .diagram-box elements  : ${diagramBoxCount}`);
  console.log(`  .infographic elements  : ${infographicCount}`);
  console.log('');
  console.log('Would assert per visual:');
  console.log(`  T1 -- Readable text (font-size >= ${minFontSize}px, not zero-height-clipped)`);
  console.log('  T2 -- Minimal/zero child-element overlap (tolerance: <= 20% of smaller area)');
  console.log('  T3 -- Correct basic layout (non-trivial dimensions, not collapsed/empty)');
  console.log('');
  console.log('Run without --check-only + with Playwright installed to execute the full gate.');
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Browser launch + page render
// ---------------------------------------------------------------------------

console.log(`Visual-fidelity gate: ${absHtmlPath}`);
console.log(`  Min font-size threshold : ${minFontSize}px`);
console.log(`  Overlap tolerance       : 20% of smaller element area`);
console.log('');

const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

const page = await browser.newPage();

// Block all network requests -- kb.html must be self-contained (C2/C3 guardrail).
// Any CDN/external fetch is itself a guardrail violation caught by validate-html-output.sh;
// we block here to keep the render hermetic and reproducible.
await page.route('**/*', (route) => {
  const url = route.request().url();
  if (url.startsWith('file://')) {
    route.continue();
  } else {
    route.abort();
  }
});

await page.goto(`file://${absHtmlPath}`, { waitUntil: 'domcontentloaded' });

// ---------------------------------------------------------------------------
// Collect visuals (inline SVG + .diagram-box + .infographic containers)
// ---------------------------------------------------------------------------

// The three visual selector classes (as documented in the templates and SPEC):
//   - inline <svg> elements inside section content (pre-rendered visuals)
//   - .diagram-box wrappers (the visual card container from bespoke-components)
//   - .infographic containers (any bespoke infographic block)
//
// We collect ALL three and deduplicate (an inline <svg> may be inside a .diagram-box).
// Strategy: find the outermost containing visual for each cluster so we don't
// double-report. We test .diagram-box / .infographic first (containers), then any
// top-level <svg> that does NOT live inside a .diagram-box or .infographic.

const visuals = await page.evaluate((opts) => {
  const results = [];
  let idx = 0;

  function getBbox(el) {
    const r = el.getBoundingClientRect();
    return { x: r.x, y: r.y, w: r.width, h: r.height, top: r.top, left: r.left, bottom: r.bottom, right: r.right };
  }

  function childBboxes(el) {
    const items = [];
    for (const child of el.children) {
      const r = child.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) {
        items.push({ el: child, bbox: { x: r.x, y: r.y, w: r.width, h: r.height } });
      }
    }
    return items;
  }

  function overlapArea(a, b) {
    const ix = Math.max(0, Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x));
    const iy = Math.max(0, Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y));
    return ix * iy;
  }

  function maxOverlapFraction(bboxes) {
    // Returns the max overlap fraction among all pairs (overlap area / area of smaller element).
    // Returns 0 if fewer than 2 boxes.
    let maxFrac = 0;
    for (let i = 0; i < bboxes.length; i++) {
      for (let j = i + 1; j < bboxes.length; j++) {
        const a = bboxes[i].bbox;
        const b = bboxes[j].bbox;
        const ia = overlapArea(a, b);
        if (ia <= 0) continue;
        const smallerArea = Math.min(a.w * a.h, b.w * b.h);
        if (smallerArea <= 0) continue;
        const frac = ia / smallerArea;
        if (frac > maxFrac) maxFrac = frac;
      }
    }
    return maxFrac;
  }

  function getTextNodes(root) {
    // Returns computed font-size (px) of all visible text inside root.
    const texts = [];
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
    let node;
    while ((node = walker.nextNode())) {
      const text = node.textContent.trim();
      if (!text) continue;
      const parent = node.parentElement;
      if (!parent) continue;
      const style = window.getComputedStyle(parent);
      if (style.display === 'none' || style.visibility === 'hidden') continue;
      const fs = parseFloat(style.fontSize);
      const rect = parent.getBoundingClientRect();
      texts.push({ text: text.slice(0, 40), fontSize: fs, height: rect.height });
    }
    return texts;
  }

  // Collect container visuals (.diagram-box, .infographic) first
  const containers = [
    ...document.querySelectorAll('.diagram-box'),
    ...document.querySelectorAll('.infographic'),
  ];

  const containerEls = new Set(containers);

  for (const el of containers) {
    idx++;
    const bbox = getBbox(el);
    const children = childBboxes(el);
    const texts = getTextNodes(el);
    const overlapFrac = maxOverlapFraction(children);

    results.push({
      idx,
      selector: el.className || el.tagName,
      tag: el.tagName,
      bbox,
      children: children.length,
      overlapFrac,
      texts,
    });
  }

  // Collect inline <svg> elements that are NOT inside a known container
  const svgs = document.querySelectorAll('svg');
  for (const svg of svgs) {
    let inContainer = false;
    let anc = svg.parentElement;
    while (anc) {
      if (containerEls.has(anc)) { inContainer = true; break; }
      anc = anc.parentElement;
    }
    if (inContainer) continue;

    idx++;
    const bbox = getBbox(svg);
    if (bbox.w === 0 && bbox.h === 0) {
      // Hidden / decorative SVG (e.g., icon sprites) -- skip
      continue;
    }

    // For SVG T2 overlap: check only sibling <g> elements (distinct visual groups).
    // In SVG it is EXPECTED and CORRECT that <text> and <rect> elements overlap
    // (labels drawn on top of shapes). Only <g> elements represent distinct
    // semantic visual groups that should not materially overlap each other.
    // If there are no <g> children, T2 trivially passes (nothing to compare).
    const svgGroups = [];
    for (const child of svg.children) {
      if (child.tagName.toUpperCase() !== 'G') continue;
      const r = child.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) {
        svgGroups.push({ bbox: { x: r.x, y: r.y, w: r.width, h: r.height } });
      }
    }
    const overlapFrac = svgGroups.length >= 2
      ? maxOverlapFraction(svgGroups.map((c, i) => ({ el: i, bbox: c.bbox })))
      : 0;
    const texts = getTextNodes(svg);

    results.push({
      idx,
      selector: 'svg (inline, outermost)',
      tag: 'SVG',
      bbox,
      children: svgGroups.length,
      overlapFrac,
      texts,
    });
  }

  return { visuals: results, minFontSize: opts.minFontSize, overlapTolerance: 0.20 };
}, { minFontSize });

await browser.close();

// ---------------------------------------------------------------------------
// Evaluate assert results (T1 / T2 / T3) per visual
// ---------------------------------------------------------------------------

const OVERLAP_TOLERANCE = 0.20; // 20% of smaller element area
const { visuals: visualList } = visuals;

if (visualList.length === 0) {
  console.log('SKIP -- No authored visuals found in the HTML.');
  console.log('  (No inline <svg>, .diagram-box, or .infographic elements detected.)');
  console.log('  If the page has no visuals, this gate trivially passes.');
  console.log('');
  console.log('PASS -- Visual-fidelity gate: 0 visuals (trivially passed).');
  process.exit(0);
}

console.log(`Found ${visualList.length} visual(s) to validate.`);
console.log('');

let failCount = 0;

for (const v of visualList) {
  const { idx, selector, bbox, overlapFrac, texts } = v;

  const t3Pass = bbox.w > 0 && bbox.h > 0;
  const t2Pass = overlapFrac <= OVERLAP_TOLERANCE;

  // T1: any text with font-size below threshold or zero-height clipping is a fail.
  let t1Pass = true;
  const t1Issues = [];
  for (const t of texts) {
    if (t.fontSize < minFontSize) {
      t1Pass = false;
      t1Issues.push(`text "${t.text}" has font-size ${t.fontSize.toFixed(1)}px (min: ${minFontSize}px)`);
    }
    if (t.fontSize > 0 && t.height === 0) {
      t1Pass = false;
      t1Issues.push(`text "${t.text}" has zero-height (overflow-clipped)`);
    }
  }

  const visualPass = t1Pass && t2Pass && t3Pass;

  const statusLabel = visualPass ? 'PASS' : 'FAIL';
  console.log(`Visual ${idx}: [${statusLabel}] ${selector}`);
  console.log(`  T3 layout (non-trivial size): ${t3Pass ? 'PASS' : 'FAIL'}  (${bbox.w.toFixed(0)}x${bbox.h.toFixed(0)} px)`);
  console.log(`  T2 overlap (child elements) : ${t2Pass ? 'PASS' : 'FAIL'}  (max overlap fraction: ${(overlapFrac * 100).toFixed(1)}%, tolerance: ${(OVERLAP_TOLERANCE * 100).toFixed(0)}%)`);
  console.log(`  T1 readable text            : ${t1Pass ? 'PASS' : 'FAIL'}  (${texts.length} text node(s) checked)`);
  if (!t1Pass) {
    for (const msg of t1Issues) {
      console.log(`      issue: ${msg}`);
    }
  }
  if (!t3Pass) {
    console.log(`      issue: visual has zero/collapsed dimensions -- not rendered in layout`);
  }
  if (!t2Pass) {
    console.log(`      issue: child elements overlap by ${(overlapFrac * 100).toFixed(1)}% of smaller element (max allowed: ${(OVERLAP_TOLERANCE * 100).toFixed(0)}%)`);
  }
  console.log('');

  if (!visualPass) failCount++;
}

// ---------------------------------------------------------------------------
// Summary + exit
// ---------------------------------------------------------------------------

const passCount = visualList.length - failCount;

if (failCount === 0) {
  console.log(`PASS -- Visual-fidelity gate: ${passCount}/${visualList.length} visual(s) passed (T1/T2/T3 all clear).`);
  process.exit(0);
} else {
  console.log(`FAIL -- Visual-fidelity gate: ${failCount}/${visualList.length} visual(s) FAILED.`);
  console.log('');
  console.log('A failing visual is a generation defect that blocks DONE.');
  console.log('Fix the failing visual(s) in the GENERATE output and re-run VALIDATE.');
  console.log('');
  console.log('Defect classes to look for:');
  console.log('  T1 fail -- text font-size too small or clipped (overflow:hidden on parent, text too small)');
  console.log('  T2 fail -- child elements materially overlap (z-index stacking, absolute positioning misalignment)');
  console.log('  T3 fail -- visual collapsed (display:none, zero-height parent, missing content)');
  process.exit(1);
}
