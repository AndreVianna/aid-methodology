// catalog.mjs — One-way shortcut-catalog reader for the skills/ cluster.
//
// Exports a single pure function: loadShortcutCatalog(repoRoot).
// This is the only catalog reader in the skills/ cluster; imported one-way by
// gen-skills.mjs and by the feature-002 AC-8 test suite.
//
// Parsing mirrors the row opener (/^  - name:\s*(.+)$/), the field line
// (/^    ([a-zA-Z_]+):\s*(.*)$/), and stripYamlScalar from the reference
// generator — re-implemented, never imported (the reference generator calls
// main() unconditionally at module scope; importing it would regenerate all
// four reference pages as a side effect).
//
// No import-time side effect; all work happens inside the exported function.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// ── Internal helpers ────────────────────────────────────────────────────────

/**
 * Strip trailing YAML inline comment and surrounding quotes from a scalar value.
 * Implementation mirrors the reference generator's stripYamlScalar exactly.
 * @param {string} raw
 * @returns {string}
 */
function stripYamlScalar(raw) {
  let val = raw.trim();
  const commentIdx = val.indexOf(' #');
  if (commentIdx !== -1) val = val.slice(0, commentIdx).trim();
  return val.replace(/^['"]|['"]$/g, '');
}

/**
 * Parse the raw YAML text of shortcut-catalog.yml into an ordered array of row
 * objects.  Mirrors the reference generator's two regexes and scalar strip,
 * but adds validation: rows without a name, rows without a verb, and duplicate
 * names each throw.
 *
 * @param {string} raw  UTF-8 text of shortcut-catalog.yml
 * @returns {import('./catalog.mjs').CatalogRow[]}
 */
function parseShortcutCatalog(raw) {
  const rows = [];
  let current = null;

  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    // Row opener: /^  - name:\s*(.+)$/
    const rowStart = line.match(/^  - name:\s*(.+)$/);
    if (rowStart) {
      if (current) rows.push(current);
      current = { name: stripYamlScalar(rowStart[1]) };
      continue;
    }

    if (!current) continue; // before the `shortcuts:` list (version:, headers, ...)

    // Field line: /^    ([a-zA-Z_]+):\s*(.*)$/
    const field = line.match(/^    ([a-zA-Z_]+):\s*(.*)$/);
    if (field) {
      current[field[1]] = stripYamlScalar(field[2]);
    }
  }
  if (current) rows.push(current);
  return rows;
}

// ── Public API ─────────────────────────────────────────────────────────────

/**
 * @typedef {{ name: string, verb: string, artifact: string, alias_of: string,
 *             group: string, intent: string, repurpose?: string }} CatalogRow
 */

/**
 * Load and parse `canonical/aid/templates/shortcut-catalog.yml`.
 *
 * Returns rows in **file order** — load-bearing for feature-002's family
 * ordering, which derives verb-family order from catalog first appearance.
 *
 * No `repurpose` filtering: every row participates.  The reference generator
 * restricts its family table to non-repurpose rows because it only generates
 * directories for those; this index cards every skill directory, and every
 * catalog row has one, so all rows participate.
 *
 * Throws `[gen-skills] catalog parse: <detail>` for:
 *   - a row with no `name` field (impossible from the row-opener regex, but
 *     guarded defensively)
 *   - a row with no `verb` field
 *   - a duplicate `name` (the reference generator silently overwrites; we cannot)
 *
 * @param {string} repoRoot  Absolute path to the repository root.
 * @returns {{ rows: CatalogRow[], byName: Map<string, CatalogRow> }}
 */
export function loadShortcutCatalog(repoRoot) {
  const catalogPath = join(repoRoot, 'canonical', 'aid', 'templates', 'shortcut-catalog.yml');
  const raw = readFileSync(catalogPath, 'utf8');
  const parsed = parseShortcutCatalog(raw);

  /** @type {Map<string, CatalogRow>} */
  const byName = new Map();
  /** @type {CatalogRow[]} */
  const rows = [];

  for (const row of parsed) {
    // Defensive: row opener always sets name, but validate anyway.
    if (!row.name) {
      throw new Error('[gen-skills] catalog parse: row has no name: ' + JSON.stringify(row));
    }
    if (!row.verb) {
      throw new Error('[gen-skills] catalog parse: row "' + row.name + '" has no verb');
    }
    if (byName.has(row.name)) {
      throw new Error('[gen-skills] catalog parse: duplicate name "' + row.name + '"');
    }
    byName.set(row.name, row);
    rows.push(row);
  }

  return { rows, byName };
}
