#!/usr/bin/env node
// sync-docs.mjs — Manifest-driven docs migration transform (feature-005).
//
// Reads four source docs/*.md files, strips the leading H1, injects frontmatter,
// rewrites cross-doc links and images, writes to site/src/content/docs/, and copies
// referenced images to site/src/assets/. Emits .synced-manifest.json.
//
// Run: node scripts/sync-docs.mjs
// Wired as: prebuild / predev in package.json

import { readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync } from 'node:fs';
import { resolve, dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../');
const DOCS_DIR = join(REPO_ROOT, 'docs');
const SITE_ROOT = join(__dirname, '..');
const CONTENT_DOCS = join(SITE_ROOT, 'src', 'content', 'docs');
const ASSETS_DIR = join(SITE_ROOT, 'src', 'assets');
const MANIFEST_PATH = join(__dirname, '.synced-manifest.json');

// GitHub repo base URL for out-of-scope cross-doc links
const GITHUB_BLOB_BASE = 'https://github.com/AndreVianna/aid-methodology/blob/master';

// ── Manifest ──────────────────────────────────────────────────────────────────
//
// The canonical mapping: source doc → dest slug + injected frontmatter.
// Changing a destination: update this table only.

const MANIFEST = [
  {
    src: 'aid-methodology.md',
    dest: 'concepts/methodology.md',
    slug: 'concepts/methodology',
    frontmatter: {
      title: 'The AID Methodology',
      description: 'How AID works — pipeline, philosophy, Knowledge Base, phases, agents, feedback loops.',
      sourceDoc: 'docs/aid-methodology.md',
    },
  },
  {
    src: 'faq.md',
    dest: 'concepts/faq.md',
    slug: 'concepts/faq',
    frontmatter: {
      title: 'FAQ',
      description: 'Frequently asked questions about adopting and running AID.',
      sourceDoc: 'docs/faq.md',
    },
  },
  {
    src: 'repository-structure.md',
    dest: 'reference/repository-structure.md',
    slug: 'reference/repository-structure',
    frontmatter: {
      title: 'Repository Structure',
      description: 'How the AID repository is laid out and where things live.',
      sourceDoc: 'docs/repository-structure.md',
    },
  },
  {
    src: 'glossary.md',
    dest: 'reference/glossary.md',
    slug: 'reference/glossary',
    frontmatter: {
      title: 'Glossary',
      description: 'Definitions of AID concepts, phases, artifacts, and install terms.',
      sourceDoc: 'docs/glossary.md',
    },
  },
];

// Build a lookup: source filename → { slug, dest }
const srcToSlug = Object.fromEntries(
  MANIFEST.map((e) => [e.src, { slug: e.slug, dest: e.dest }])
);

// ── YAML frontmatter serializer ───────────────────────────────────────────────

function serializeFrontmatter(fm) {
  const lines = ['---'];
  for (const [key, val] of Object.entries(fm)) {
    // Simple scalar serialization; values are all strings here
    const escaped = val.replace(/'/g, "''");
    lines.push(`${key}: '${escaped}'`);
  }
  lines.push('---');
  return lines.join('\n') + '\n';
}

// ── Fence-aware line processor ────────────────────────────────────────────────
//
// Tracks whether we are inside a fenced code block. Lines inside fences are
// treated as literal text and are NOT subject to heading or link rewrites (D5).

function isFenceOpener(line) {
  return /^```/.test(line);
}

// ── H1 strip (fence-aware) ────────────────────────────────────────────────────
//
// Removes the FIRST H1 found outside a fence block (line that starts with '# ').
// Returns the content with the H1 removed.

function stripLeadingH1(text) {
  const lines = text.split('\n');
  let inFence = false;
  let h1Removed = false;
  const result = [];

  for (const line of lines) {
    if (isFenceOpener(line)) {
      inFence = !inFence;
    }
    if (!h1Removed && !inFence && /^# /.test(line)) {
      h1Removed = true;
      // Skip this line (the H1 title)
      continue;
    }
    result.push(line);
  }

  return result.join('\n');
}

// ── Link / Image rewriter ─────────────────────────────────────────────────────
//
// Applies rewrite rules from the SPEC's "Link / Anchor / Image Rewrite Rules":
//
//   [text](glossary.md)                 → [text](/reference/glossary)
//   [text](aid-methodology.md#anchor)   → [text](/concepts/methodology#anchor)
//   [text](#anchor)                     → [text](#anchor)  (unchanged)
//   [text](install.md)                  → GitHub blob URL
//   [text](../CONTRIBUTING.md)          → GitHub blob URL
//   ![alt](images/3-ironman.png)        → ![alt](../../assets/3-ironman.png)
//   [text](https://...)                 → unchanged

function rewriteLinks(text, destSlug, imageRewrites) {
  // Process line by line, tracking fence state.
  const lines = text.split('\n');
  let inFence = false;
  const out = [];

  for (const line of lines) {
    if (isFenceOpener(line)) {
      inFence = !inFence;
    }
    if (inFence) {
      out.push(line);
      continue;
    }
    out.push(rewriteLinksInLine(line, destSlug, imageRewrites));
  }
  return out.join('\n');
}

function rewriteLinksInLine(line, destSlug, imageRewrites) {
  // Match markdown links/images: ![alt](target) or [text](target)
  // Capture group 1: '!' for images (optional), group 2: label, group 3: target
  return line.replace(/(!?)\[([^\]]*)\]\(([^)]+)\)/g, (match, bang, label, target) => {
    // Split target into file part and anchor
    const [filePart, anchor] = target.split('#');
    const anchorSuffix = anchor != null ? `#${anchor}` : '';

    // External links: leave unchanged
    if (/^https?:\/\//i.test(filePart)) {
      return match;
    }

    // Same-doc anchor (#anchor only): leave unchanged
    if (!filePart && anchor != null) {
      return match;
    }

    // Image reference: rewrite to relative path from content page
    if (bang === '!') {
      const imgFile = basename(filePart);
      const imgEntry = imageRewrites.find((r) => r.srcFile === imgFile);
      if (imgEntry) {
        const relPath = computeRelativeAssetPath(destSlug, imgFile);
        return `![${label}](${relPath})`;
      }
      return match;
    }

    // Cross-doc link: look up in manifest
    const fileName = basename(filePart);
    if (srcToSlug[fileName]) {
      const targetSlug = srcToSlug[fileName].slug;
      return `[${label}](/${targetSlug}${anchorSuffix})`;
    }

    // Out-of-scope cross-doc link or relative path to repo root files
    // (e.g. ../CONTRIBUTING.md, install.md, release.md)
    if (filePart.endsWith('.md') || filePart.includes('/')) {
      // Normalize to a repo-relative path
      let repoRelPath = filePart;
      if (repoRelPath.startsWith('../')) {
        repoRelPath = repoRelPath.replace(/^\.\.\//, '');
      } else if (!repoRelPath.startsWith('/')) {
        repoRelPath = 'docs/' + repoRelPath;
      }
      const githubUrl = `${GITHUB_BLOB_BASE}/${repoRelPath}`;
      console.log(`[sync-docs] External rewrite: "${filePart}" → ${githubUrl}`);
      return `[${label}](${githubUrl}${anchorSuffix})`;
    }

    return match;
  });
}

// Compute relative path from a content page to an asset in src/assets/
// The content pages live at src/content/docs/{destSlug}.md
// The assets live at src/assets/{imgFile}
// e.g. destSlug='concepts/methodology':
//   file: src/content/docs/concepts/methodology.md
//   directory: src/content/docs/concepts/
//   to reach src/: go up 3 times (content/, docs/, concepts/)
//   so: ../../../assets/3-ironman.png
//
// Formula: directory depth from src/ = 2 (fixed: content/ and docs/) + (slugDepth - 1)
//          where slugDepth-1 is the directory segments of the slug (all but the filename part)
function computeRelativeAssetPath(destSlug, imgFile) {
  const slugSegments = destSlug.split('/');
  // number of directory levels (exclude the filename = last segment)
  const slugDirDepth = slugSegments.length - 1;
  // total depth from src/: content/ + docs/ + slug dirs
  const totalDepth = 2 + slugDirDepth;
  const ups = Array(totalDepth).fill('..').join('/');
  return `${ups}/assets/${imgFile}`;
}

// ── Image handling ────────────────────────────────────────────────────────────

function findImageReferences(text) {
  const refs = [];
  const re = /!\[[^\]]*\]\(([^)]+)\)/g;
  let m;
  while ((m = re.exec(text)) != null) {
    const target = m[1].split('#')[0];
    if (!target.startsWith('http')) {
      refs.push({ srcRelPath: target, srcFile: basename(target) });
    }
  }
  return refs;
}

function copyImages(imageRefs, srcDocDir) {
  mkdirSync(ASSETS_DIR, { recursive: true });
  for (const ref of imageRefs) {
    const srcPath = resolve(srcDocDir, ref.srcRelPath);
    const destPath = join(ASSETS_DIR, ref.srcFile);
    if (existsSync(srcPath)) {
      copyFileSync(srcPath, destPath);
      console.log(`[sync-docs] Copied image: ${ref.srcFile} → src/assets/`);
    } else {
      console.warn(`[sync-docs] WARNING: Image not found: ${srcPath}`);
    }
  }
}

// ── Per-entry transform ───────────────────────────────────────────────────────

function syncEntry(entry) {
  const srcPath = join(DOCS_DIR, entry.src);
  const destPath = join(CONTENT_DOCS, entry.dest);

  const raw = readFileSync(srcPath, 'utf8');

  // Find image references (before stripping H1, to not miss any)
  const imageRefs = findImageReferences(raw);

  // Copy images to assets/
  copyImages(imageRefs, DOCS_DIR);

  // Strip leading H1 (fence-aware)
  let body = stripLeadingH1(raw);

  // Rewrite links and images (fence-aware)
  body = rewriteLinks(body, entry.slug, imageRefs);

  // Trim leading blank lines from the body
  body = body.replace(/^\n+/, '');

  // Build the final page content
  const frontmatter = serializeFrontmatter(entry.frontmatter);
  const page = frontmatter + '\n' + body;

  // Write (overwrite stubs from feature-001 — this is D2's ownership boundary)
  mkdirSync(dirname(destPath), { recursive: true });
  writeFileSync(destPath, page, 'utf8');
  console.log(`[sync-docs] Wrote: ${entry.dest}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

function main() {
  console.log('[sync-docs] Starting docs migration...');

  const generatedPaths = [];

  for (const entry of MANIFEST) {
    syncEntry(entry);
    generatedPaths.push(`site/src/content/docs/${entry.dest}`);
  }

  // Also record the assets directory as owned
  generatedPaths.push('site/src/assets/');

  // Emit the manifest JSON (outside the collection root)
  const manifest = {
    generator: 'site/scripts/sync-docs.mjs',
    entries: MANIFEST.map((e) => ({
      src: `docs/${e.src}`,
      dest: `site/src/content/docs/${e.dest}`,
      slug: e.slug,
    })),
    generatedPaths,
  };

  writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log('[sync-docs] Wrote: scripts/.synced-manifest.json');
  console.log('[sync-docs] Done.');
}

main();
