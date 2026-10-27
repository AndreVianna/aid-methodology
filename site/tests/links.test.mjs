// Internal link checks (L1-L2). L1 reads the existing dist/; run `npm run build` first.
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterAll, describe, expect, it } from 'vitest';
import { findBrokenLinks } from './dist.mjs';

const dir = mkdtempSync(join(tmpdir(), 'aid-links-test-'));
afterAll(() => rmSync(dir, { recursive: true, force: true }));

describe('internal links', () => {
  it('L1 the built site has no broken internal link', () => {
    expect(findBrokenLinks()).toEqual([]);
  });

  it('L2 the checker reports a missing page and a missing anchor', () => {
    mkdirSync(join(dir, 'a'));
    mkdirSync(join(dir, 'old'));
    const links = ['/a/', '/missing/', '/a/#there', '/a/#nothere', '/old/#there', 'https://example.com/x', 'mailto:x@example.com'];
    writeFileSync(join(dir, 'index.html'), links.map((l) => `<a href="${l}">x</a>`).join('\n'));
    writeFileSync(join(dir, 'a', 'index.html'), '<h2 id="there">there</h2>');
    writeFileSync(join(dir, 'old', 'index.html'), '<meta http-equiv="refresh" content="0;url=/a/">');
    expect(findBrokenLinks(dir)).toEqual(['/ -> /missing/ (no such page)', '/ -> /a/#nothere (no such anchor)']);
  });
});
