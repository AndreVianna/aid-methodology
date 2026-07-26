// skills-catalog.test.mjs — Unit tests for site/scripts/skills/catalog.mjs
//
// Covers:
//  - File-order preservation (inline fixture in non-sorted order)
//  - Three throw cases: no name, no verb, duplicate name
//  - byName completeness against rows
//  - No repurpose filtering (all rows participate)
//  - Real-file integration: rows.length equals independently-computed name count

import { describe, it, expect, afterAll } from 'vitest';
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { loadShortcutCatalog } from '../skills/catalog.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const CATALOG_PATH = resolve(REPO_ROOT, 'canonical/aid/templates/shortcut-catalog.yml');

// ── Inline fixture harness ────────────────────────────────────────────────────
//
// Every fixture is driven through the REAL `loadShortcutCatalog`, by writing the
// YAML into a throwaway repo root laid out the way the function expects and
// pointing it there. Nothing about the parser or its throw rules is
// reimplemented here.
//
// That is deliberate and it is the whole point of this harness. An earlier
// version of this file re-implemented the parser and all three throws inline "to
// keep the test pure", which meant every throw assertion verified the COPY — the
// copy and the tests could agree perfectly while the shipped module diverged,
// and no test would notice. A temp directory is a much smaller price than a
// suite that cannot fail.

const tempRoots = [];

/** Write `raw` as the catalog inside a temp repo root and load it for real. */
function parseFixture(raw) {
  const root = mkdtempSync(resolve(tmpdir(), 'aid-catalog-'));
  tempRoots.push(root);
  const dir = resolve(root, 'canonical', 'aid', 'templates');
  mkdirSync(dir, { recursive: true });
  writeFileSync(resolve(dir, 'shortcut-catalog.yml'), raw, 'utf8');
  return loadShortcutCatalog(root);
}

afterAll(() => {
  for (const root of tempRoots) rmSync(root, { recursive: true, force: true });
  tempRoots.length = 0;
});

// ── File-order preservation ───────────────────────────────────────────────────

describe('catalog: file-order preservation', () => {
  // Row names are in non-sorted order: zap, alpha, middle.
  // Sorted order would be: alpha, middle, zap.
  // The parser must return them in file order.
  const FIXTURE = `\
version: 1
shortcuts:
  - name: aid-zap
    verb: zap
    artifact: ""
    alias_of: null
    group: G1
    intent: "Zap something."
  - name: aid-alpha
    verb: alpha
    artifact: ""
    alias_of: null
    group: G1
    intent: "Alpha something."
  - name: aid-middle
    verb: middle
    artifact: ""
    alias_of: null
    group: G1
    intent: "Middle something."
`;

  it('returns rows in file order, not sorted order', () => {
    const { rows } = parseFixture(FIXTURE);
    expect(rows.map((r) => r.name)).toEqual(['aid-zap', 'aid-alpha', 'aid-middle']);
  });

  it('byName covers every row', () => {
    const { rows, byName } = parseFixture(FIXTURE);
    for (const row of rows) {
      expect(byName.has(row.name)).toBe(true);
      expect(byName.get(row.name)).toBe(row);
    }
  });

  it('byName size equals rows length', () => {
    const { rows, byName } = parseFixture(FIXTURE);
    expect(byName.size).toBe(rows.length);
  });
});

// ── No repurpose filtering ────────────────────────────────────────────────────

describe('catalog: no repurpose filtering', () => {
  const FIXTURE_WITH_REPURPOSE = `\
version: 1
shortcuts:
  - name: aid-deploy
    verb: deploy
    artifact: ""
    alias_of: null
    group: G9
    intent: "Deploy something."
    repurpose: true
  - name: aid-monitor
    verb: monitor
    artifact: ""
    alias_of: null
    group: G10
    intent: "Monitor something."
    repurpose: true
  - name: aid-fix
    verb: fix
    artifact: ""
    alias_of: null
    group: G6
    intent: "Fix something."
`;

  it('rows.length equals the number of - name: entries (repurpose rows not filtered)', () => {
    const { rows } = parseFixture(FIXTURE_WITH_REPURPOSE);
    // Count "  - name:" occurrences in the fixture independently
    const nameCount = (FIXTURE_WITH_REPURPOSE.match(/^  - name:/gm) || []).length;
    expect(rows.length).toBe(nameCount);
    expect(rows.length).toBe(3);
  });

  it('repurpose: true rows are present in rows', () => {
    const { rows } = parseFixture(FIXTURE_WITH_REPURPOSE);
    const names = rows.map((r) => r.name);
    expect(names).toContain('aid-deploy');
    expect(names).toContain('aid-monitor');
  });

  it('repurpose: true rows are present in byName', () => {
    const { byName } = parseFixture(FIXTURE_WITH_REPURPOSE);
    expect(byName.has('aid-deploy')).toBe(true);
    expect(byName.get('aid-deploy').repurpose).toBe('true');
  });
});

// ── Throw: no name ────────────────────────────────────────────────────────────

describe('catalog: throws on row with no name', () => {
  // A row-opener with a quoted empty string: the regex matches "''" (two chars),
  // but stripScalar strips the quotes, leaving an empty string that is falsy.
  const FIXTURE_NO_NAME = `\
version: 1
shortcuts:
  - name: ''
    verb: fix
    artifact: ""
    alias_of: null
    group: G6
    intent: "A row with an empty name."
`;

  it("throws with message matching '[gen-skills] catalog parse:'", () => {
    expect(() => parseFixture(FIXTURE_NO_NAME)).toThrow('[gen-skills] catalog parse:');
  });

  it('error message identifies the offending row', () => {
    expect(() => parseFixture(FIXTURE_NO_NAME)).toThrow('has no name');
  });
});

// ── Throw: no verb ────────────────────────────────────────────────────────────

describe('catalog: throws on row with no verb', () => {
  const FIXTURE_NO_VERB = `\
version: 1
shortcuts:
  - name: aid-good
    verb: fix
    artifact: ""
    alias_of: null
    group: G6
    intent: "A well-formed row."
  - name: aid-bad
    artifact: ""
    alias_of: null
    group: G6
    intent: "This row is missing the verb field."
`;

  it("throws with message matching '[gen-skills] catalog parse:'", () => {
    expect(() => parseFixture(FIXTURE_NO_VERB)).toThrow('[gen-skills] catalog parse:');
  });

  it('error message names the offending row', () => {
    expect(() => parseFixture(FIXTURE_NO_VERB)).toThrow('aid-bad');
  });

  it('error message mentions "has no verb"', () => {
    expect(() => parseFixture(FIXTURE_NO_VERB)).toThrow('has no verb');
  });
});

// ── Throw: duplicate name ─────────────────────────────────────────────────────

describe('catalog: throws on duplicate name', () => {
  const FIXTURE_DUPLICATE = `\
version: 1
shortcuts:
  - name: aid-fix
    verb: fix
    artifact: ""
    alias_of: null
    group: G6
    intent: "First occurrence."
  - name: aid-fix
    verb: fix
    artifact: ""
    alias_of: null
    group: G6
    intent: "Duplicate — must throw."
`;

  it("throws with message matching '[gen-skills] catalog parse:'", () => {
    expect(() => parseFixture(FIXTURE_DUPLICATE)).toThrow('[gen-skills] catalog parse:');
  });

  it('error message mentions "duplicate name"', () => {
    expect(() => parseFixture(FIXTURE_DUPLICATE)).toThrow('duplicate name');
  });

  it('error message identifies the duplicate name', () => {
    expect(() => parseFixture(FIXTURE_DUPLICATE)).toThrow('aid-fix');
  });
});

// ── Real-file integration ─────────────────────────────────────────────────────

describe('catalog: real file integration', () => {
  it('loadShortcutCatalog(repoRoot) does not throw', () => {
    expect(() => loadShortcutCatalog(REPO_ROOT)).not.toThrow();
  });

  it('rows.length equals the number of "  - name:" lines in the real catalog', () => {
    const { rows } = loadShortcutCatalog(REPO_ROOT);
    // Count independently from the raw file — do NOT hard-code the number.
    const raw = readFileSync(CATALOG_PATH, 'utf8');
    const nameLineCount = (raw.match(/^  - name:/gm) || []).length;
    expect(rows.length).toBe(nameLineCount);
  });

  it('byName covers every row in the real catalog', () => {
    const { rows, byName } = loadShortcutCatalog(REPO_ROOT);
    expect(byName.size).toBe(rows.length);
    for (const row of rows) {
      expect(byName.has(row.name)).toBe(true);
    }
  });

  it('every row in the real catalog has a name', () => {
    const { rows } = loadShortcutCatalog(REPO_ROOT);
    for (const row of rows) {
      expect(typeof row.name).toBe('string');
      expect(row.name.length).toBeGreaterThan(0);
    }
  });

  it('every row in the real catalog has a verb', () => {
    const { rows } = loadShortcutCatalog(REPO_ROOT);
    for (const row of rows) {
      expect(typeof row.verb).toBe('string');
      expect(row.verb.length).toBeGreaterThan(0);
    }
  });

  it('real catalog rows are in file order (not re-sorted)', () => {
    const { rows } = loadShortcutCatalog(REPO_ROOT);
    // Read the raw file and extract names in order; they must match rows[].name.
    const raw = readFileSync(CATALOG_PATH, 'utf8');
    const namePattern = /^  - name:\s*(.+)$/gm;
    const fileOrderNames = [];
    let m;
    while ((m = namePattern.exec(raw)) !== null) {
      // Strip quotes and inline comments the same way the parser does.
      let val = m[1].trim();
      const ci = val.indexOf(' #');
      if (ci !== -1) val = val.slice(0, ci).trim();
      val = val.replace(/^['"]|['"]$/g, '');
      fileOrderNames.push(val);
    }
    expect(rows.map((r) => r.name)).toEqual(fileOrderNames);
  });
});
