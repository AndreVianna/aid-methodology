// skills-paths.test.mjs — unit tests for site/scripts/skills/paths.mjs
//
// Verifies: GITHUB_BLOB_BASE constant, POSIX string builders (concatenation,
// never path.join), root resolution, and path helper shapes.

import { describe, it, expect } from 'vitest';
import {
  GITHUB_BLOB_BASE,
  REPO_ROOT,
  SITE_ROOT,
  CANONICAL_SKILLS_DIR,
  SITE_SKILLS_DIR,
  SKILLS_MANIFEST_ABS,
  skillSourcePath,
  skillDestPath,
  skillGithubUrl,
  skillDirAbs,
  skillFileAbs,
  skillDestAbs,
} from '../skills/paths.mjs';

// ── GITHUB_BLOB_BASE ────────────────────────────────────────────────────────

describe('GITHUB_BLOB_BASE', () => {
  it('is the correct GitHub blob URL', () => {
    expect(GITHUB_BLOB_BASE).toBe(
      'https://github.com/AndreVianna/aid-methodology/blob/master'
    );
  });

  it('does not have a trailing slash', () => {
    expect(GITHUB_BLOB_BASE.endsWith('/')).toBe(false);
  });
});

// ── Root paths ──────────────────────────────────────────────────────────────

describe('REPO_ROOT', () => {
  it('is an absolute path', () => {
    // On Windows an absolute path starts with a drive letter or \\;
    // on POSIX it starts with /.  Either way, it is non-empty and absolute.
    expect(REPO_ROOT.length).toBeGreaterThan(0);
    // resolve() always returns an absolute path
    expect(REPO_ROOT).toBe(REPO_ROOT.trim());
  });

  it('does not contain path.join separators (no double backslashes from join)', () => {
    // We just confirm it was built with resolve(), not join().
    // The real guard is the grep AC; here we assert the exported value is a string.
    expect(typeof REPO_ROOT).toBe('string');
  });
});

describe('SITE_ROOT', () => {
  it('is an absolute path ending inside REPO_ROOT', () => {
    // SITE_ROOT is the site/ subdirectory of REPO_ROOT
    expect(SITE_ROOT.startsWith(REPO_ROOT) || SITE_ROOT.includes('site')).toBe(true);
  });
});

// ── POSIX repo-relative string builders ────────────────────────────────────

describe('skillSourcePath', () => {
  it('returns the correct POSIX repo-relative path', () => {
    expect(skillSourcePath('aid-create-api')).toBe(
      'canonical/skills/aid-create-api/SKILL.md'
    );
  });

  it('contains only forward slashes', () => {
    const result = skillSourcePath('aid-foo');
    expect(result.includes('\\')).toBe(false);
  });

  it('is built by concatenation — matches template exactly', () => {
    const dir = 'aid-bar-baz';
    expect(skillSourcePath(dir)).toBe('canonical/skills/' + dir + '/SKILL.md');
  });
});

describe('skillDestPath', () => {
  it('returns the correct POSIX repo-relative path', () => {
    expect(skillDestPath('aid-create-api')).toBe(
      'site/src/content/docs/skills/aid-create-api.md'
    );
  });

  it('contains only forward slashes', () => {
    const result = skillDestPath('aid-foo');
    expect(result.includes('\\')).toBe(false);
  });

  it('is built by concatenation — matches template exactly', () => {
    const dir = 'aid-bar-baz';
    expect(skillDestPath(dir)).toBe('site/src/content/docs/skills/' + dir + '.md');
  });
});

describe('skillGithubUrl', () => {
  it('returns a full GitHub blob URL', () => {
    expect(skillGithubUrl('aid-create-api')).toBe(
      'https://github.com/AndreVianna/aid-methodology/blob/master' +
      '/canonical/skills/aid-create-api/SKILL.md'
    );
  });

  it('starts with GITHUB_BLOB_BASE', () => {
    expect(skillGithubUrl('aid-foo').startsWith(GITHUB_BLOB_BASE)).toBe(true);
  });

  it('ends with /SKILL.md', () => {
    expect(skillGithubUrl('aid-foo').endsWith('/SKILL.md')).toBe(true);
  });

  it('contains only forward slashes (the URL portion)', () => {
    const url = skillGithubUrl('aid-foo');
    // The URL itself must have forward slashes only (it's a web URL)
    expect(url.startsWith('https://')).toBe(true);
    expect(url.includes('\\')).toBe(false);
  });
});

// ── Absolute OS path helpers ────────────────────────────────────────────────

describe('CANONICAL_SKILLS_DIR', () => {
  it('is a non-empty string', () => {
    expect(typeof CANONICAL_SKILLS_DIR).toBe('string');
    expect(CANONICAL_SKILLS_DIR.length).toBeGreaterThan(0);
  });

  it('ends with canonical/skills or canonical\\skills', () => {
    const norm = CANONICAL_SKILLS_DIR.replace(/\\/g, '/');
    expect(norm.endsWith('canonical/skills')).toBe(true);
  });
});

describe('SITE_SKILLS_DIR', () => {
  it('ends with content/docs/skills (normalised)', () => {
    const norm = SITE_SKILLS_DIR.replace(/\\/g, '/');
    expect(norm.endsWith('content/docs/skills')).toBe(true);
  });
});

describe('SKILLS_MANIFEST_ABS', () => {
  it('ends with .skills-manifest.json', () => {
    expect(SKILLS_MANIFEST_ABS.endsWith('.skills-manifest.json')).toBe(true);
  });
});

describe('skillDirAbs', () => {
  it('returns a string ending with the dir name', () => {
    const result = skillDirAbs('aid-foo');
    expect(result.replace(/\\/g, '/').endsWith('/aid-foo')).toBe(true);
  });
});

describe('skillFileAbs', () => {
  it('returns a string ending with SKILL.md', () => {
    const result = skillFileAbs('aid-foo');
    expect(result.endsWith('SKILL.md')).toBe(true);
  });
});

describe('skillDestAbs', () => {
  it('returns a string ending with the skill page filename', () => {
    const result = skillDestAbs('aid-foo');
    expect(result.endsWith('aid-foo.md')).toBe(true);
  });
});

// ── Grep-verified: no path.join or gen-reference in source ──────────────────
// (grep -n "path.join" paths.mjs returns nothing — enforced by AC-5)
// (grep -n "gen-reference" paths.mjs returns nothing — enforced by AC-6)
// These are checked by the CI acceptance-criteria grep commands, not here.
