// provenance-deep-link.test.mjs — unit tests for lib/provenance/deep-link.mjs
//
// Covers: lineAnchor (both forms), blobUrl (exact output), and the three
// path-guard rejections.  Each guard rejection uses an input that triggers
// only that one guard.

import { describe, it, expect } from 'vitest';
import { GITHUB_BLOB_BASE } from '../skills/paths.mjs';
import { lineAnchor, blobUrl } from '../lib/provenance/deep-link.mjs';

// ── lineAnchor ────────────────────────────────────────────────────────────────

describe('lineAnchor — single-line form', () => {
  it('returns #L<n> when startLine === endLine', () => {
    expect(lineAnchor(5, 5)).toBe('#L5');
  });

  it('non-vacuity: result starts with #L and has a digit bound', () => {
    const a = lineAnchor(12, 12);
    expect(a).toBe('#L12');
    expect(a.length).toBeGreaterThan(2);
  });
});

describe('lineAnchor — range form', () => {
  it('returns #L<start>-L<end> when startLine !== endLine', () => {
    expect(lineAnchor(3, 7)).toBe('#L3-L7');
  });

  it('non-vacuity: both line numbers appear in the output', () => {
    const a = lineAnchor(10, 20);
    expect(a).toBe('#L10-L20');
    expect(a.includes('10')).toBe(true);
    expect(a.includes('20')).toBe(true);
  });
});

// ── blobUrl — exact equality ──────────────────────────────────────────────────

describe('blobUrl — exact output', () => {
  it('constructs the correct URL for a single-line range', () => {
    const file = 'canonical/skills/aid-foo/SKILL.md';
    expect(blobUrl(file, 7, 7)).toBe(
      'https://github.com/AndreVianna/aid-methodology/blob/master' +
      '/canonical/skills/aid-foo/SKILL.md' +
      '#L7'
    );
  });

  it('constructs the correct URL for a multi-line range', () => {
    const file = 'canonical/skills/aid-foo/SKILL.md';
    expect(blobUrl(file, 3, 11)).toBe(
      'https://github.com/AndreVianna/aid-methodology/blob/master' +
      '/canonical/skills/aid-foo/SKILL.md' +
      '#L3-L11'
    );
  });

  it('uses GITHUB_BLOB_BASE as its prefix (imported constant, not hardcoded)', () => {
    const file = 'canonical/skills/aid-bar/SKILL.md';
    const url = blobUrl(file, 1, 1);
    expect(url.startsWith(GITHUB_BLOB_BASE + '/')).toBe(true);
  });

  // Written out literally rather than as GITHUB_BLOB_BASE + '/' + file + anchor:
  // that form re-computes the implementation from the same two functions under
  // test, so a consistent mutation of both would leave it green.
  it('output equals base + "/" + file + anchor exactly, third data point', () => {
    expect(blobUrl('canonical/skills/aid-baz/SKILL.md', 4, 9)).toBe(
      'https://github.com/AndreVianna/aid-methodology/blob/master' +
      '/canonical/skills/aid-baz/SKILL.md' +
      '#L4-L9'
    );
  });
});

// ── blobUrl — path-guard rejections (three separate cases) ───────────────────

describe('blobUrl — guard: bad character', () => {
  it('throws on a file containing a character outside [A-Za-z0-9._/-]', () => {
    // Only bad character — no ".." segment, no leading "/"
    expect(() => blobUrl('canonical/skills/aid foo/SKILL.md', 1, 1)).toThrow();
  });

  // Asserts the charset guard's own wording, not just the echoed input: an input
  // echo appears in all three messages, so matching it cannot tell them apart.
  it('throw message identifies the charset guard and echoes the input', () => {
    expect(() => blobUrl('path/with space', 1, 1)).toThrow(
      /outside \[A-Za-z0-9\._\/-\]: path\/with space/
    );
  });
});

describe('blobUrl — guard: ".." segment', () => {
  it('throws on a file containing a ".." segment', () => {
    // Characters are all legal; only violation is the ".." segment
    expect(() => blobUrl('canonical/../etc/passwd', 1, 1)).toThrow();
  });

  // `/\.\./` alone would also match the echoed input, so it could not tell this
  // guard from the charset one. Assert the word "segment", which only this
  // message carries.
  it('throw message identifies the ".." segment guard', () => {
    expect(() => blobUrl('canonical/../other', 1, 1)).toThrow(
      /'?"?\.\."? segment: canonical\/\.\.\/other/
    );
  });
});

describe('blobUrl — guard: leading "/"', () => {
  it('throws on a file with a leading "/"', () => {
    // Characters are all legal; no ".."; only violation is the leading "/"
    expect(() => blobUrl('/canonical/skills/aid-foo/SKILL.md', 1, 1)).toThrow();
  });

  it('throw message identifies the leading-slash guard', () => {
    expect(() => blobUrl('/absolute/path', 1, 1)).toThrow(
      /leading "\/": \/absolute\/path/
    );
  });
});

// ── Guard non-interference: a clean path must not throw ──────────────────────

describe('blobUrl — clean path accepted', () => {
  it('does not throw for a well-formed repo-relative POSIX path', () => {
    expect(() =>
      blobUrl('canonical/skills/aid-create-api/SKILL.md', 1, 50)
    ).not.toThrow();
  });
});
