#!/usr/bin/env node
// validate-diagram-content.mjs -- assert kb.html diagrams contain their REQUIRED
// content and none of the FORBIDDEN/stale tokens, per a diagram-content manifest.
//
// Complements validate-visuals.mjs: that gate checks a diagram RENDERS well (readable
// text, no overlap, correct layout); this gate checks a diagram SAYS the right thing
// (its labels are factually current -- phase names, skill/agent/profile counts, etc.).
//
// The manifest is the machine-readable companion to docs/diagram-content-reference.md.
//
// Usage:
//   node validate-diagram-content.mjs <kb.html> <manifest.json>
// Exit: 0 = all diagrams match · 1 = content violation · 2 = usage/parse error.
//
// Manifest shape:
//   {
//     "diagrams": [
//       { "id": "pipeline",
//         "match": "6-phase pipeline",          // substring of the diagram's aria-label/text
//         "requires": ["Discover", "Describe"], // every token MUST appear in the diagram
//         "forbids":  ["Interview"] },          // no token may appear in the diagram
//       ...
//     ],
//     "globalForbids": ["Thirteen", "aid-interview"]  // must not appear in ANY diagram
//   }

import { readFileSync } from 'node:fs';

const [, , htmlPath, manifestPath] = process.argv;
if (!htmlPath || !manifestPath) {
  console.error('Usage: validate-diagram-content.mjs <kb.html> <manifest.json>');
  process.exit(2);
}

let html, manifest;
try { html = readFileSync(htmlPath, 'utf8'); }
catch (e) { console.error(`cannot read ${htmlPath}: ${e.message}`); process.exit(2); }
try { manifest = JSON.parse(readFileSync(manifestPath, 'utf8')); }
catch (e) { console.error(`cannot read/parse ${manifestPath}: ${e.message}`); process.exit(2); }

// Decode the few entities our labels use, so manifest tokens can be written plainly.
const decode = (s) => s
  .replace(/&#8594;|&rarr;/g, '->')
  .replace(/&mdash;/g, '--')
  .replace(/&middot;/g, '.')
  .replace(/&amp;/g, '&');

// Extract every <svg>...</svg> block with its aria-label + visible <text>/<tspan> content.
// (Scoping to <svg> blocks deliberately skips the #kb-md-export base64 payload and prose.)
const svgs = [];
const re = /<svg\b[^>]*>([\s\S]*?)<\/svg>/g;
let m;
while ((m = re.exec(html)) !== null) {
  const block = m[0];
  const aria = decode((block.match(/aria-label="([^"]*)"/) || [, ''])[1]);
  const text = decode(
    (block.match(/<(?:text|tspan)\b[^>]*>([\s\S]*?)<\/(?:text|tspan)>/g) || [])
      .map((t) => t.replace(/<[^>]*>/g, ''))
      .join(' ')
  );
  svgs.push({ aria, text, haystack: `${aria} ${text}` });
}

// Neutralize the protected agent token so an "Interview"/"aid-interview" forbid does not
// false-positive on "aid-interviewer" / "Interviewer".
const clean = (s) => s.replace(/aid-interviewer/g, 'AGENT').replace(/Interviewer/g, 'AGENT');

let failures = 0;
const results = [];

for (const d of manifest.diagrams || []) {
  const found = svgs.find((s) => s.haystack.includes(d.match));
  if (!found) {
    results.push(`  [FAIL] ${d.id}: no diagram matching "${d.match}" found`);
    failures++;
    continue;
  }
  const hay = clean(found.haystack);
  const missing = (d.requires || []).filter((tok) => !hay.includes(tok));
  const present = (d.forbids || []).filter((tok) => hay.includes(clean(tok)));
  if (missing.length === 0 && present.length === 0) {
    results.push(`  [PASS] ${d.id}: ${(d.requires || []).length} required token(s) present, 0 forbidden`);
  } else {
    failures++;
    if (missing.length) results.push(`  [FAIL] ${d.id}: MISSING required: ${missing.join(', ')}`);
    if (present.length) results.push(`  [FAIL] ${d.id}: contains FORBIDDEN: ${present.join(', ')}`);
  }
}

const allText = clean(svgs.map((s) => s.haystack).join(' '));
for (const tok of manifest.globalForbids || []) {
  if (allText.includes(clean(tok))) {
    failures++;
    results.push(`  [FAIL] GLOBAL: a diagram contains forbidden token "${tok}"`);
  }
}

console.log(`Diagram-content check (${svgs.length} diagram(s) in ${htmlPath.split('/').pop()}):`);
results.forEach((r) => console.log(r));
if (failures === 0) {
  console.log(`\nPASS -- all ${(manifest.diagrams || []).length} diagram(s) match the content manifest.`);
  process.exit(0);
}
console.log(`\nFAIL -- ${failures} diagram-content violation(s). Reconcile against ${manifestPath} / docs/diagram-content-reference.md.`);
process.exit(1);
