# Content Migration: Reuse Existing docs/*.md as the Single Source

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR11), §7, §8, §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR11 Content reuse)
- REQUIREMENTS.md §7 (Constraints — content reuse), §8 (Assumptions — frontmatter migration),
  §10 (Priority — Must)

## Description

Establish the repeatable, low-drift migration of the repo's existing Markdown into Starlight
content. Four existing `docs/*.md` files — `aid-methodology.md`, `faq.md`,
`repository-structure.md`, `glossary.md` — are brought into Starlight's content
directory with the required YAML frontmatter added, kept as the single source where feasible to
minimize duplication and drift, with internal relative links and anchors fixed for the new IA and
Mermaid diagrams rendering correctly. `docs/install.md` is deliberately **excluded**: it is a
SOURCE consumed by features 004/006/008 as hand-authored pages (`guides/installation.mdx`,
`reference/cli.mdx`, install-command version injection), not migrated by this feature. This
feature owns the migration mechanism and the faithful transfer of the four source files; the
content-bearing features (Concepts, Reference) consume the migrated pages and arrange them into
the site map. Isolating the migration/transform step lets it be built and validated (no content
loss, links resolve, diagrams render) independently of page-layout decisions.

## User Stories

- As a returning user, I want the existing docs (methodology, repo structure, FAQ,
  glossary) to appear on the site with no content loss so that nothing I relied on disappears.
- As a returning user, I want internal links to resolve under the new structure so that I never
  hit a broken cross-reference.
- As an evaluator, I want Mermaid diagrams from the methodology to render so that the
  architecture is communicated visually, not as raw code.
- As a maintainer, I want a single source for migrated docs (with frontmatter added by a
  one-time, scriptable migration) so that ongoing maintenance has minimal duplication and drift.

## Priority

Must

## Acceptance Criteria

- [ ] Given the four migrated `docs/*.md` (methodology, repository-structure, faq, glossary; NOT
  `install.md`, which is a source consumed by features 004/006/008), when migrated, then each
  appears in Starlight content with no content loss (AC5).
- [ ] Given migrated pages, when built, then required YAML frontmatter (incl. `title`) is present
  and the pages live in Starlight's content directory (§8).
- [ ] Given migrated pages containing Mermaid, when built, then the diagrams render correctly
  (AC5).
- [ ] Given internal relative links and anchors in the source files, when re-grouped under the
  new IA, then they resolve with no broken internal links (AC5; §6 CI link-check where practical).
- [ ] Given the migration, when re-run, then it is scriptable/repeatable so the source `docs/`
  remains the single source where feasible (FR11, §8).

---

## Technical Specification

### Overview & Approach

This feature owns the **migration transform**: the repeatable, low-drift mechanism that turns
a defined subset of the repo's existing `docs/*.md` into Starlight-consumable content under
`site/src/content/docs/`. It migrates exactly **four** source docs —
`docs/aid-methodology.md`, `docs/faq.md`, `docs/repository-structure.md`, and
`docs/glossary.md`. It does **not** own the page information architecture — the
content-bearing siblings (feature-006 Concepts & Reference) decide which migrated page lands in
which section and how it is grouped in the sidebar. This feature
guarantees five things about the transform: (AC5) no content loss, required YAML frontmatter
present, Mermaid diagrams survive and render, internal links/anchors resolve under the new
routes, and the whole step is **scriptable and repeatable** so `docs/` stays the single source.

**`docs/install.md` is explicitly NOT migrated by this feature.** It is a **SOURCE** consumed by
feature-004 (which OWNS the hand-authored `guides/installation.mdx` with tabbed/version-injected
UX), feature-006 (CLI reference, hand-authored `reference/cli.mdx`), and feature-008 (install
commands / FR15 version injection). Auto-migrating it to `guides/installation.md` would collide at
the `guides/installation` slug with feature-004's `.mdx` page and lose the tabbed/version-injected
UX — so it is left out of the manifest entirely.

It builds on the feature-001 anchor and does not contradict it: the `docs` content collection,
the `config.ts` schema (`docsSchema()` extended with `sourceDoc?: string` and
`reportIssue: boolean = true`), the five sections (`get-started/`, `guides/`, `concepts/`,
`reference/`, `releases/`), and `astro-mermaid` for client-side Mermaid rendering are all
inherited as-is. This feature supplies the **populated** versions of the placeholder pages that
feature-001 stubbed for the four migrated docs (e.g. `concepts/methodology.md`,
`reference/repository-structure.md`).

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| **D1 — Single source: keep `docs/*.md`, sync at build** | `docs/*.md` remains the canonical source of truth. A build-time sync script (`site/scripts/sync-docs.mjs`) copies + transforms each source doc into `site/src/content/docs/<section>/<page>.md`, injecting frontmatter and rewriting links. Run as an npm `prebuild` (and explicitly in CI before `astro build`). | Directly satisfies the NFR "reuse a single source from `docs/` where feasible; minimize duplication and drift." A one-time move would fork every file into two editable copies and immediately start drifting (the exact failure REQUIREMENTS §7 / §10 calls out). Build-time sync means a maintainer edits `docs/` only and the site re-derives — no second copy to keep in step. Matches the §8 assumption ("a one-time, scriptable migration") in *spirit* but upgrades it to *every build* for durability. |
| **D2 — Generated pages are committed; a CI drift-check guards them** | The synced page tree produced from `docs/` is **committed** to the repo (not git-ignored), and CI re-runs the sync and asserts no diff (see *Single-Source / Sync Mechanism* and *Sync drift-check* below). This matches this repo's existing **render-drift** convention (canonical → profiles is committed and drift-checked): `docs/` is source, the synced pages under `site/src/content/docs/` are committed derived output, and CI runs `sync-docs` then `git diff --exit-code` to assert no drift. **Ownership boundary:** feature-001 ships *stub* placeholder pages at these same paths (so nav works pre-migration); feature-005's committed sync output is **authoritative** and supersedes the stub at each managed path. Pages carry `sourceDoc` frontmatter (and are listed in the manifest) as the "derived — do not hand-edit" marker. | A committed tree gives at-a-glance diffing and a clean checkout that builds without a pre-step, while the CI drift-check removes the only real downside (silent drift): any `docs/` edit not re-synced fails CI. Because the pages are committed, there is **no path collision** with feature-001's committed placeholders — the sync output simply overwrites the stub content at the shared path, and the manifest records exactly which paths feature-005 owns. |
| **D3 — `.md` not `.mdx` for migrated pages** | Migrated pages keep the `.md` extension. | The only risk to `.md` would be bare angle-bracket tokens **outside** code fences (MDX/JSX would mis-parse them); inspection confirms every such token (`<tool>`, `<command>`, `<version>`, `<hex>`, `<id>`) lives **inside** code fences, so `.md` is safe. Using `.md` (CommonMark) avoids MDX's stricter JSX parsing, which would choke on any stray `{}`/`<>` and is unnecessary here since no Astro components are embedded in body content. (Pages that need MDX components — tabbed installs in feature-004 — are authored separately as `.mdx`, not produced by this transform.) |
| **D4 — Keep large source docs as single pages; do not auto-split** | `aid-methodology.md` (1430 lines, 10 numbered H2 sections) migrates to **one** `concepts/methodology.md` page. The transform does not split by heading. | Splitting requires editorial IA decisions that belong to the consuming feature (006), not the transform. A single faithful page guarantees AC5 "no content loss" and preserves the doc's own in-page ToC anchors (`#1-the-pipeline`, …) which stay valid only while the doc is one page. |
| **D5 — Heading-fence awareness in the transform** | The sync script must treat `#`-prefixed lines **inside fenced code blocks** as literal text, never as document headings. | `aid-methodology.md` embeds template snippets in ```` ```markdown ```` fences that contain lines like `# Requirements`, `# Knowledge Base — {Project Name}`, `# task-NNN`. A naive line-based H1 detector would mis-read these as real headings (and, e.g., a naive multi-page splitter would shatter the page). The transform parses fence state; the only real H1 is line 1. |
| **D6 — Images relocated to `src/assets/`, references rewritten** | `docs/images/3-ironman.png` is copied to `site/src/assets/3-ironman.png` and the Markdown image reference is rewritten to a **relative** path from the content page (e.g. `../../assets/3-ironman.png` from `concepts/methodology.md`). | Starlight optimizes images in `.md` pages via Astro's content image pipeline only when referenced by a **relative** path — relative refs are resolved and optimized at build, whereas a root-relative `/…` (public/) path ships the file unoptimized. `.md` cannot use ESM `import`, but it does not need to: the relative reference is sufficient. One image today, but the rule is general. |

### Single-Source / Sync Mechanism (D1, D2)

**Mechanism.** `site/scripts/sync-docs.mjs` is a Node ESM script with no runtime deps beyond
Node's stdlib (it reads `docs/*.md`, transforms text, writes into the content dir). It is driven
by an explicit **manifest** (the mapping table below, encoded as a JS array) so adding/retargeting
a source doc is a one-line change. For each manifest entry it:

1. Reads the source file from the repo's top-level `docs/`.
2. Strips the source's own leading H1 (the page title is carried in frontmatter instead, so
   Starlight does not render a duplicate `<h1>`), preserving everything below it verbatim.
3. Prepends the injected YAML frontmatter (`title`, `description`, `sourceDoc`; `reportIssue`
   left to its schema default of `true`).
4. Applies the link/anchor/image rewrites (next section).
5. Writes the result to the destination path under `site/src/content/docs/`, creating section
   dirs as needed. (The destination path may already hold a feature-001 stub; the sync output is
   authoritative and overwrites it — see D2 ownership boundary.)
6. Copies referenced images into `site/src/assets/` (idempotently).

**Wiring (package.json scripts).** Owned here, added to the feature-001 `package.json`:

```json
{
  "scripts": {
    "sync:docs": "node scripts/sync-docs.mjs",
    "predev":    "npm run sync:docs",
    "prebuild":  "npm run sync:docs",
    "build":     "astro build"
  }
}
```

CI (feature-002's workflow) must run `npm run sync:docs` **before** `astro build` explicitly as
well (belt-and-suspenders, since some CI invokes `astro build` directly rather than the `build`
script). The script is **idempotent and deterministic**: re-running it on a clean tree produces
byte-identical output, so it is safe to run on every dev/build and to assert "no diff" in CI.

**Sync drift-check (D2).** Because the generated pages are **committed**, CI can verify the
committed tree matches a fresh sync — this is both the idempotency proof and the drift guard,
mirroring this repo's render-drift convention. In CI, after `npm run sync:docs`:

```sh
git diff --exit-code -- site/src/content/docs/ site/src/assets/ site/scripts/.synced-manifest.json
```

A non-empty diff means a `docs/` edit was not re-synced (drift) or the script is non-deterministic;
either fails the build. **Ownership:** the generated paths are enumerated by the manifest —
`sync-docs.mjs` emits `site/scripts/.synced-manifest.json` (deliberately **outside** the
`site/src/content/docs/` collection root so docsLoader's glob never picks it up as a page) listing
exactly the files it owns. Every generated page also carries `sourceDoc` in frontmatter as a
secondary "derived — do not edit by hand" marker. Feature-001's stub pages at the same paths are
authored once so nav resolves pre-migration; feature-005's committed sync output supersedes them.
Hand-authored sibling pages that are **not** in the manifest (e.g. section `index`/overview pages)
are committed and maintained normally and are never touched by the sync.

### Mapping Table (source → destination)

This is the manifest. "Section" is the inherited feature-001 section; the **consuming feature**
column records who arranges the page in the IA (this feature only produces it).

| Source file | Lines | Dest path (`site/src/content/docs/`) | Section | Injected frontmatter (`title` / `description` / `sourceDoc`) | Consuming feature | Notes |
|-------------|-------|--------------------------------------|---------|--------------------------------------------------------------|-------------------|-------|
| `docs/aid-methodology.md` | 1430 | `concepts/methodology.md` | concepts | `title: "The AID Methodology"` · desc: "How AID works — pipeline, philosophy, Knowledge Base, phases, agents, feedback loops." · `sourceDoc: "docs/aid-methodology.md"` | feature-006 (Concepts & Reference) | Single page (D4). 7 Mermaid blocks (AC5). In-page ToC anchors preserved. Contains 1 image (D6). |
| `docs/faq.md` | 153 | `concepts/faq.md` | concepts | `title: "FAQ"` · desc: "Frequently asked questions about adopting and running AID." · `sourceDoc: "docs/faq.md"` | feature-006 (Concepts & Reference) | Has cross-doc links into methodology (rewritten). |
| `docs/repository-structure.md` | 122 | `reference/repository-structure.md` | reference | `title: "Repository Structure"` · desc: "How the AID repository is laid out and where things live." · `sourceDoc: "docs/repository-structure.md"` | feature-006 (Concepts & Reference) | Contains 1 cross-repo link to `../CONTRIBUTING.md` (see link rules). |
| `docs/glossary.md` | 148 | `reference/glossary.md` | reference | `title: "Glossary"` · desc: "Definitions of AID concepts, phases, artifacts, and install terms." · `sourceDoc: "docs/glossary.md"` | feature-006 (Concepts & Reference) | No internal links/anchors/images. Lowest-risk migration. |

`docs/install.md` is intentionally **not** in this feature's manifest. It is a **SOURCE consumed
by features 004/006/008 as hand-authored pages, not migrated by this feature.** feature-004 OWNS
the hand-authored `guides/installation.mdx` (tabbed, version-injected install UX), feature-006 OWNS
the hand-authored `reference/cli.mdx` (CLI reference), and feature-008 owns FR15 version injection
into the install commands. Auto-migrating `install.md` to `guides/installation.md` would collide at
the `guides/installation` slug with feature-004's `.mdx` page and lose the tabbed/version-injected
UX. The four migrated pages above are this feature's complete output; nothing in `guides/` is
produced by the sync.

`docs/release.md` is also intentionally **not** in this feature's manifest. Like `docs/install.md`,
it is a **SOURCE consumed by feature-007** (which OWNS the hand-authored `guides/maintainer.mdx`),
**not migrated by this feature.** The sync transform does not produce a page from it, and
`docs/release.md` does not appear in the manifest now or in any future extension of it — feature-007
hand-authors its maintainer guide from `docs/release.md` as a source, exactly as feature-004 does
with `docs/install.md`. Nothing in `guides/` is produced by this feature's sync.

### Link / Anchor / Image Rewrite Rules

The transform classifies every Markdown link target and applies a rule. Rewrites are computed
from the **manifest** (source path → dest slug), so they stay correct if a destination moves.

| Link pattern (in source) | Example | Rewrite rule | Result |
|--------------------------|---------|--------------|--------|
| **Cross-doc, file only** | `](glossary.md)` | Look up source in manifest → emit the dest **route** (slug, no extension, leading `/`). | `](/reference/glossary)` |
| **Cross-doc, file + anchor** | `](aid-methodology.md#9-comparison-with-sdd)` | Resolve file to its route; **preserve the anchor** (Starlight slugifies headings the same GitHub way, so `#9-comparison-with-sdd` stays valid on the single migrated page). | `](/concepts/methodology#9-comparison-with-sdd)` |
| **Same-doc anchor** | `](#9-comparison-with-sdd)` | Leave unchanged — same-page anchors resolve as-is once the doc is one Starlight page. | unchanged |
| **Cross-doc, target not in scope** | `](install.md)`, `](../CONTRIBUTING.md)` | Not a migrated page (`install.md` is owned hand-authored by feature-004; `CONTRIBUTING.md` lives in repo root). Rewrite to the **absolute GitHub blob URL** (e.g. `https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md` — the repo default branch is `master`; a commit-pinned permalink is also acceptable); flag in build log as an external rewrite for review. (Once feature-004 ships `guides/installation.mdx`, a consuming feature may instead re-point such links to `/guides/installation`, but that is not this feature's transform.) | GitHub URL |
| **Image** | `![…](images/3-ironman.png)` | Copy file to `site/src/assets/3-ironman.png`; rewrite the reference to a **relative** path from the content page so Astro's content image pipeline optimizes it (e.g. `../../assets/3-ironman.png` from `concepts/methodology.md`). `.md` cannot use ESM `import` but a relative ref needs none. Alt text preserved verbatim. | optimized image, same alt |
| **External `http(s)`** | any absolute URL | Leave unchanged. | unchanged |

**Anchor-slug fidelity.** Starlight (via `rehype-slug`/GitHub-style slugging) generates the same
heading slugs as the source docs' hand-written ToC anchors (lowercase, spaces→hyphens, punctuation
dropped, leading number kept). The transform therefore does **not** rewrite anchors on
single-page migrations; it only verifies (see CI) that each referenced anchor exists. If a future
multi-page split is introduced by a consumer, that consumer owns re-pointing the affected anchors.

**Broken-internal-link check (CI, "where practical" — NFR/§6).** After `astro build`, CI runs a
link checker over the built `dist/` HTML (e.g. `lychee --offline` or `linkinator` scoped to
internal links) and fails on any unresolved internal `href`/anchor. This is the objective AC5
guard ("internal links resolve"). The check is owned operationally by feature-002's CI but its
**rules** (internal-only, anchors included) are specified here so the rewrite logic and the check
agree. External links are not failed (only reported) to avoid flaky network gating.

### Mermaid Handling (AC5)

`docs/aid-methodology.md` contains **7** fenced ```` ```mermaid ```` blocks; the other three
migrated source docs contain none. The transform copies these fences **verbatim** — it must not reflow,
re-indent, or HTML-escape fenced content. Because feature-001 added `astro-mermaid` (its own D6,
not this spec's image D6) as an integration that transforms ```` ```mermaid ```` fences at build into client-side-rendered
diagrams, the migrated `concepts/methodology.md` renders all 7 diagrams with **no extra work in
this feature** beyond fence-faithfulness. Validation (see AC coverage): build the site, load the
methodology page, confirm all 7 diagrams render as SVG (not raw code) and are horizontally
scrollable on narrow viewports (the feature-001 Mermaid contract). The feature-001
`mermaid-smoke.md` page already proves the pipeline; this feature proves it at production scale.

### File / Directory Tree (added by this feature)

```
site/
├── scripts/
│   ├── sync-docs.mjs                  # the migration transform (manifest-driven)
│   └── .synced-manifest.json          # generated: paths owned by sync (committed; OUTSIDE the collection root)
├── package.json                       # + sync:docs / predev / prebuild scripts (edit)
└── src/
    ├── assets/
    │   └── 3-ironman.png              # committed; copied from docs/images/ by sync (derived)
    └── content/docs/
        ├── concepts/
        │   ├── methodology.md         # committed; generated from docs/aid-methodology.md
        │   └── faq.md                 # committed; generated from docs/faq.md
        └── reference/
            ├── repository-structure.md# committed; generated from docs/repository-structure.md
            └── glossary.md            # committed; generated from docs/glossary.md
```

(`guides/installation.mdx` is **not** produced here — it is hand-authored and owned by feature-004;
this feature writes nothing under `guides/`.) All four generated pages, the copied image, and
`.synced-manifest.json` are **committed** derived output per D2; CI re-runs the sync and
`git diff --exit-code` to assert no drift. The hand-authored artifacts of this feature are
`sync-docs.mjs`, the `package.json` edit, and the manifest data embedded in the script. The
manifest sits in `site/scripts/` — outside `site/src/content/docs/` — so docsLoader's glob never
treats it as a content page. No `site/.gitignore` rule is added for generated pages.)

### Feature Boundaries

| Concern | Owner | This feature does |
|---------|-------|-------------------|
| Content collection, schema (`sourceDoc`, `reportIssue`), sections, `astro-mermaid` | feature-001 | Inherits, does not modify |
| Page IA / sidebar grouping / which content shows where | feature-006 | Produces the four migrated pages it arranges |
| `docs/install.md` content → site pages | features 004/006/008 | **Not migrated here**; `install.md` is a SOURCE they consume as hand-authored pages (`guides/installation.mdx`, `reference/cli.mdx`, install-command injection) |
| CI workflow (runs `sync:docs` + link check) | feature-002 | Specifies the rules the CI must enforce |
| FR15 version injection into install commands | feature-008 | Out of scope; install content not migrated here |
| `docs/release.md` content → site pages | feature-007 | **Not migrated here**; `docs/release.md` is a SOURCE feature-007 consumes as a hand-authored page (`guides/maintainer.mdx`) |
| Net-new content (tutorials, skills/agents/KB reference) | features 003/006 | Not a migration; out of scope |

### Acceptance Criteria Coverage

| Scaffold AC | How this feature satisfies it |
|-------------|-------------------------------|
| No content loss (AC5) | Transform copies everything below the source H1 verbatim; single-page (D4) avoids editorial drops; CI byte-diff idempotency proves stability. |
| Frontmatter present incl. `title` (§8) | `sync-docs` injects `title`/`description`/`sourceDoc` per the manifest; `docsSchema()` validation at build fails if any is malformed. |
| Mermaid renders (AC5) | 7 fences copied verbatim; `astro-mermaid` (feature-001) renders them client-side; validated on the built methodology page. |
| Internal links/anchors resolve (AC5, §6) | Manifest-driven rewrite rules + post-build internal link/anchor checker in CI. |
| Scriptable/repeatable, `docs/` single source (FR11, §8) | `sync-docs.mjs` is deterministic and idempotent; run on every dev/build/CI; generated tree is committed and CI asserts `git diff --exit-code` after a fresh sync, so any un-synced `docs/` edit fails the build and `docs/` stays canonical. |

### Assumptions & Open Questions

- **A1 (single-page over split):** `aid-methodology.md` migrates as a single page (D4). This is
  the safe default for "no content loss" and preserves its ToC anchors, but if the consuming
  feature (006) decides the methodology should be split per-H2 across several Concepts pages, that
  split is **their** transform/IA decision — anchors into those sections would then need
  re-pointing. Spot-check: confirm reviewers accept single-page methodology for MVP.
- **A1b (`install.md` not migrated):** `docs/install.md` is deliberately excluded from this
  feature's manifest. It is a SOURCE consumed by feature-004 (hand-authored
  `guides/installation.mdx` with tabbed/version-injected UX), feature-006 (hand-authored
  `reference/cli.mdx`), and feature-008 (FR15 install-command version injection). Migrating it to
  `guides/installation.md` would collide with feature-004's `.mdx` page at the `guides/installation`
  slug and lose the tabbed/version-injected UX. Spot-check: confirm reviewers agree install content
  is owned by 004/006/008, not migrated here.
- **A2 (anchor-slug parity):** assumes Starlight's heading-slug algorithm matches the source
  docs' hand-written ToC anchors (GitHub-style). True for the patterns observed
  (`#9-comparison-with-sdd`, `#npm-channel`); the CI anchor check is the backstop if any edge
  case (e.g. duplicate headings) diverges.
- **A3 (committed generated tree + drift-check):** D2 commits the generated tree and CI asserts
  `git diff --exit-code` after a fresh `sync:docs` run (idempotency + drift detection), matching
  this repo's render-drift convention. This makes a clean checkout build without a pre-step and
  supersedes feature-001's committed stub pages at the shared paths with no collision. Spot-check:
  confirm reviewers are comfortable that `docs/` edits must be re-synced and committed (CI enforces
  it).
- **A4 (image pipeline path for `.md`):** assumes a **relative** asset reference from `.md`
  (e.g. `../../assets/3-ironman.png`) resolves through Astro's content image optimization. This is
  the documented Starlight/Astro behavior for `.md` (no ESM `import` needed). Spot-check during
  implementation that the optimized image renders.
- **A5 (`CONTRIBUTING.md` external rewrite):** assumes `../CONTRIBUTING.md` should point at the
  GitHub blob rather than become a site page (it is contributor-facing, not product docs). If a
  Contributing page is later added to the site, the manifest gains an entry and the rule flips to
  an internal route.
