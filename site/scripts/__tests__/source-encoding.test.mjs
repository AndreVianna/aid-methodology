// source-encoding.test.mjs — Repo-hygiene guard: no byte-order marks in tracked sources.
//
// Why this file exists.
//
// Twice during delivery-003 a UTF-8 BOM was prepended to a source file by a write
// path that nobody inspected — Windows PowerShell's `Set-Content`/`Out-File` emit
// UTF-8 *with* BOM by default, and Python's `read_text(encoding='utf-8')` reads an
// existing BOM as a literal `\ufeff` character and writes it straight back. The
// second time, two files were committed that way.
//
// Node strips a leading BOM before parsing, so nothing failed: the full suite stayed
// green, the generator produced byte-identical output, and no functional test could
// have caught it. Only `git status` noticed. That is the defect class this file
// closes — a side effect invisible to the test runner, which no amount of mutation
// coverage on functional behaviour will surface.
//
// Scoped to `site/` and driven off `git ls-files`, so it covers files that exist
// rather than a hard-coded list, and a newly added file is covered on arrival.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');

const BOM = 0xfeff;
const TEXT_EXT = /\.(mjs|js|cjs|ts|tsx|astro|json|md|mdx|css|yml|yaml)$/;

/**
 * Tracked text files under site/, as repo-relative paths.
 *
 * Uses `git ls-files` rather than a directory walk so that generated-but-ignored
 * output and `node_modules` are excluded without maintaining a skip list.
 *
 * @returns {string[]}
 */
function trackedTextFiles() {
  const out = execFileSync('git', ['ls-files', '--', '.'], {
    cwd: SITE_ROOT,
    encoding: 'utf8',
    maxBuffer: 32 * 1024 * 1024,
  });
  return out.split('\n').filter((p) => p !== '' && TEXT_EXT.test(p));
}

describe('source encoding: no byte-order marks', () => {
  const files = trackedTextFiles();

  it('finds a non-trivial set of tracked text files to check', () => {
    // Non-vacuity. If `git ls-files` fails or the filter is wrong, every assertion
    // below would pass over an empty list.
    expect(files.length).toBeGreaterThan(50);
    expect(files).toContain('scripts/gen-skills.mjs');
    expect(files).toContain('scripts/lib/flow-graph/advance.mjs');
  });

  it('no tracked text file under site/ begins with a UTF-8 BOM', () => {
    const withBom = files.filter((rel) => {
      const text = readFileSync(join(SITE_ROOT, rel), 'utf8');
      return text.charCodeAt(0) === BOM;
    });

    // Name every offender — a count alone would not say which write path to fix.
    expect(withBom).toEqual([]);
  });

  it('detects a BOM when one is present', () => {
    // Proves the check above can fail. Reading through the same `utf8` decode path
    // the real assertion uses, since that decode is where the subtlety lives:
    // 'utf8' surfaces the BOM as U+FEFF rather than stripping it.
    const withBom = Buffer.concat([
      Buffer.from([0xef, 0xbb, 0xbf]),
      Buffer.from('// leading comment\n', 'utf8'),
    ]);
    expect(withBom.toString('utf8').charCodeAt(0)).toBe(BOM);

    const withoutBom = Buffer.from('// leading comment\n', 'utf8');
    expect(withoutBom.toString('utf8').charCodeAt(0)).not.toBe(BOM);
  });
});
