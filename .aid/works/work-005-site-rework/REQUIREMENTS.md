# Requirements

- **Name:** Product Site Rework
- **Description:** Rework the AID product site so every page matches the current skills, the layout and diagrams look modern and accessible, and the site's build machinery shrinks to what a static documentation site needs.

## 1. Objective

Rework the product site in `site/` (published at aid.casuloailabs.com) completely, so that:

- every page is true to the skills and processes currently in this repository (stale or wrong content fixed);
- the diagrams and the whole layout look modern and professional, and stay accessible to developers of every level and to screen-reader and keyboard users;
- the site's machinery (generators, scripts, tests) is cut down to what a static documentation site needs.

Nothing is deployed or published as part of this work.

## 2. Problem Statement

The site is an Astro Starlight project that has grown a large build apparatus around a small amount of content:

- 4 generator scripts (about 1,500 lines) plus helper libraries (`scripts/lib/flow-graph`, `scripts/lib/provenance`, `scripts/skills`), run before every build.
- 37 per-skill `*.flow.json` files and a Mermaid-based diagram pipeline with an interactive node panel, a source-cache workaround and an ELK layout plugin.
- About 50 test files that mostly test the generators themselves, not the site's behaviour.
- A `sync-docs.mjs` step that copies files from `docs/`.

Consequences: pages drift from the skills in `canonical/` (the skills pages are generated, but the hand-written pages are not checked); diagrams are hard to read and are not reliably accessible (Mermaid output is SVG with little text alternative); the layout carries many overrides and workaround comments; and the machinery is costly to maintain for what is a static documentation site.

## 3. Users & Stakeholders

| Who | Need |
|---|---|
| Developers new to AID (any level) | Plain-language path from "what is this" to a first working run. |
| Experienced developers and tech leads | Accurate reference: skills, agents, settings, artifacts, CLI. |
| Screen-reader users | Every page and diagram understandable without sight; proper headings, landmarks, text alternatives. |
| Keyboard-only users | Every control reachable and usable; visible focus; no traps; skip link. |
| Maintainers of this repo (owner: Andre Vianna) | A site that is cheap to change and cannot silently drift from `canonical/`. |

## 4. Scope

### In Scope

- Every page under `site/src/content/docs/` and `site/src/pages/`: audit against the current skills (`canonical/skills/`), agents, settings, CLI and process docs in this repository; fix or remove what is wrong or stale.
- Visual redesign of the layout (header, navigation, typography, colour, spacing, light and dark themes) and of all diagrams.
- Accessibility to WCAG 2.2 level AA for pages and diagrams.
- Simplification of `site/scripts/`, `site/src/lib/`, `site/src/data/`, `site/public/` scripts and `site/**/__tests__`: keep only what a static documentation site needs.
- Updating `.github/workflows/docs.yml` and every Knowledge Base statement about the site's machinery, only as far as the simplification requires (steps removed, paths kept consistent, statements made true).

### Out of Scope

- Deploying or publishing anything (no push to Pages, no tag, no release, no DNS change).
- Changing `canonical/`, `profiles/`, the CLI, or the installers.
- Changing the domain, hosting platform or the `CNAME`.
- Adding user accounts, analytics, or any third-party runtime service.
- Replacing Astro Starlight with another framework.

## 5. Functional Requirements

Priority key: **Must** / **Should** / **Could**.

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | Audit every page against the repository (skills list and behaviour, agents, settings keys, CLI commands, artifact shapes, process phases) and correct each inaccurate or stale statement. Record each correction in a short audit table kept in this work's folder. | Must |
| FR-2 | Facts that exist in `canonical/` (skill names and descriptions, agent roster, settings keys) come from one small script reading `canonical/`, so they cannot drift. The script is at most 300 lines, with no per-skill hand data. It has a `--check` flag: it writes nothing and exits 0 only when the committed generated pages equal what `canonical/` produces now. Everything else is hand-written Markdown. | Must |
| FR-3 | Redraw all diagrams as accessible, static diagrams: inline SVG or HTML/CSS authored by hand or from a single small renderer. Each diagram has a title, a text description, and a text-equivalent (ordered list or table) that carries the same information. No diagram depends on JavaScript to be understood. | Must |
| FR-4 | New visual design: consistent type scale, spacing, colour tokens, light and dark themes following the system setting with a manual toggle, responsive from 320 px wide to desktop. | Must |
| FR-5 | Keyboard and screen-reader support: skip-to-content link, one `h1` per page, ordered headings, landmark regions, visible focus indicator, link text that makes sense out of context, `lang` set, reduced-motion respected. | Must |
| FR-6 | Plain-language writing for newcomers: each page opens with one sentence saying what it is for; jargon is explained at first use or links to the glossary; a clear "start here" path from the home page to the first run. | Must |
| FR-7 | Remove the generators, libraries, data files and scripts that FR-2 does not need (flow-graph engine, provenance, node panel, Mermaid source-cache workaround, per-skill `*.flow.json`, `sync-docs.mjs` if `docs/` content is moved into `site/`), together with their tests. | Must |
| FR-8 | Keep tests only where they earn their place, in four groups: (a) the build succeeds; (b) no broken internal links; (c) the FR-2 script's `--check` passes; (d) automated checks on built pages: an accessibility rule engine (such as axe-core) plus structure assertions (one `h1`, heading order, one `main`, `lang`, every diagram has a title, a description and a text equivalent). Delete tests of removed code. | Must |
| FR-9 | Keep working: search (Pagefind), sitemap, favicon, `CNAME`, `robots.txt`, version display, contact/feedback pages. Drop any of these only if found broken or unused, and say so in the audit table. | Should |
| FR-10 | Update `.github/workflows/docs.yml` (edited, never run) and every statement about the site's generators, scripts and tests in the Knowledge Base (`.aid/knowledge/test-landscape.md` and any other KB document whose site statement becomes false) so they describe the simplified site accurately. | Should |
| FR-11 | Dependencies pruned to those still used (for example `astro-mermaid`, `@mermaid-js/layout-elk`, `marked`, `sanitize-html`, `jsdom` are removed if nothing uses them); lockfile regenerated. | Should |
| FR-12 | Content sources: pages now copied from `docs/` by `sync-docs.mjs` become the site's own Markdown (the `docs/` originals stay untouched). The changelog page no longer fetches from the network; it shows the version from the `VERSION` file and links to the GitHub Releases page. No step of the build uses the network. | Must |

## 6. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-1 | Accessibility: WCAG 2.2 AA. Text contrast at least 4.5:1 (3:1 for large text and UI parts) in both themes. |
| NFR-2 | Performance: no client-side JavaScript on a page except search, theme toggle and navigation controls. Each built page, excluding images, is at most 150 KB transferred. |
| NFR-3 | Maintainability: site-specific code (`scripts/`, `src/lib/`, `src/data/`, `src/scripts/`, `src/components/`, `public/*.mjs`, `public/*.css` and all tests) is smaller than today by at least 60% in lines, measured with the stated command in AC-4 before and after. |
| NFR-4 | Reproducibility: `npm ci && npm run build` in `site/` needs the network only for `npm ci`; no step of the build fetches anything. |
| NFR-5 | Rules of this repository still hold: ASCII-only shipped PowerShell and LF-only `.sh` are untouched; the KB names no work id; changes stay inside `site/`, `.github/workflows/docs.yml`, the KB documents named in FR-10, and this work's folder. |

## 7. Constraints

- Stay on Astro and Starlight (versions pinned in `site/package.json`; upgrades only if needed to build).
- Node >= 22.12 (as in `site/package.json`).
- The work happens on branch `work-005`; no push, no PR merge, no deploy, no release.
- The site URL structure should be kept where a page survives, so existing links keep working; a removed or renamed page gets a redirect.
- All file edits follow the review criteria in `.aid/knowledge/authoring-conventions.md` and the project card's rules.

## 8. Assumptions & Dependencies

- The skills in `canonical/skills/` (37 today) are the current truth for skills; the 38th file in `site/src/content/docs/skills/` is the index page.
- `docs/` at the repo root holds source text that `sync-docs.mjs` copies into the site; after this work the site copy is the only one (the `docs/` originals stay in place, untouched, because they are outside scope).
- The release-data fetch (`fetch-release-data.mjs`) needs the network and is removed (FR-12). The repository has no changelog file, so the changelog page shows the `VERSION` value and links to GitHub Releases.
- `npm ci` can reach the npm registry in the build environment.
- An accessibility rule engine such as axe-core can be installed as a dev dependency; the exact tool is chosen at Specify.
- The audit table and the "before" figures live in this work's folder; they are the only files outside the paths allowed by NFR-5 that this work adds.

## 9. Acceptance Criteria

Run from `site/` unless stated.

| ID | Criterion | How to check |
|---|---|---|
| AC-1 | The site builds. | `npm ci && npm run build` exits 0 and produces `dist/index.html`. |
| AC-2 | No stale skill facts. | The FR-2 script run with `--check` exits 0, and the number of skill pages in `dist/skills/` (excluding the index) equals `ls ../canonical/skills \| wc -l`. |
| AC-3 | Audit complete. | The audit table in this work's folder lists every page under `src/content/docs/` and `src/pages/` with the verdict "ok" or the correction made; no page is missing. |
| AC-4 | Machinery reduced. | The total from `find scripts src/lib src/data src/scripts src/components public -type f \( -name '*.mjs' -o -name '*.js' -o -name '*.ts' -o -name '*.astro' -o -name '*.css' -o -name '*.json' \) -not -name 'package*.json' \| xargs wc -l`, run from `site/`, is at least 60% lower than the "before" figure recorded in the audit table; the same command with `tests` added to the folder list (the new tests live in `site/tests/`) must also be at least 60% lower than its own "before" figure. `scripts/` holds at most 2 files of at most 300 lines each. |
| AC-5 | Tests earn their place. | `npm test` exits 0 and runs only the four groups in FR-8 (a to d); no test of removed code remains (`grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules` prints nothing). |
| AC-6 | Links are sound. | The link check test reports 0 broken internal links across `dist/`. |
| AC-7 | Accessibility checker passes. | The automated check on every built page reports 0 violations of WCAG 2.2 AA rules. |
| AC-8 | Diagrams are accessible. | Every diagram in `dist/` has a `<title>` and `<desc>` (or `figcaption`) plus a text-equivalent list or table next to it; a test counts diagrams and text-equivalents and they match. |
| AC-9 | Keyboard use. | On the home page and one skill page, pressing Tab from the top reaches: skip link first, then header links, theme toggle, search, sidebar links, content links, in a logical order, with a visible focus ring each time (checked with a recorded Playwright script or a manual checklist in the audit). |
| AC-10 | Screen-reader structure. | Each built page has exactly one `h1`, no skipped heading levels, one `main` landmark, and `lang="en"` on `html` (checked by test). |
| AC-11 | Responsive and themed. | Screenshots at 320 px and 1280 px wide in light and dark themes show no horizontal scroll and no clipped text (reviewer inspects 4 screenshots for the home page and 4 for one skill page). |
| AC-12 | Newcomer readability. | Every page's first paragraph is one sentence stating its purpose; every term in the glossary is linked on first use on the Get Started pages (checked by a reviewer reading the Get Started section). |
| AC-13 | Nothing deployed, nothing outside scope changed. | From the repo root: `git diff --name-only site-aid...HEAD` (the branch this work started from) lists only paths under `site/`, `.github/workflows/docs.yml`, `.aid/knowledge/` documents that the audit table lists as edited under FR-10, and `.aid/works/work-005-site-rework/`; `git tag --points-at HEAD` prints nothing; and the branch was never pushed (`git ls-remote --heads origin work-005` prints nothing). |
| AC-14 | Repo checks still pass. | `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`, `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and `bash tests/canonical/test-kb-no-work-ids.sh` exit 0. |
| AC-15 | Light pages. | From `site/`: `find dist -name '*.html' -size +150k` prints nothing, and `grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' \| sort -u` lists only the scripts of search, the theme toggle and navigation controls (the list is written into the audit table and each entry is named for its purpose). |

## 10. Priority

1. Correct content (FR-1, FR-2): a wrong page is worse than an ugly one.
2. Accessibility and structure (FR-3, FR-5, FR-6).
3. New look (FR-4).
4. Machinery cut (FR-7, FR-8, FR-11, FR-12), done together with 1 and 2 because the generators are what is being replaced.
5. Housekeeping (FR-9, FR-10).

## 11. Features

Suggested build order (Plan decides): 002, then 003 and 001, then 004, then 005, then 006. Feature 005 deletes code, so it follows 002 and 003; Feature 004 adds the accessibility check that Feature 005 then keeps.

### Feature 001 — Content Audit and Plain-Language Rewrite

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-6
- **Criteria:** AC-3, AC-12

#### Description

Every page is checked against the skills, agents, settings, CLI and process docs in this repository. Each stale or wrong statement is corrected, and the corrections are recorded in an audit table. Every page opens with one sentence saying what it is for, and jargon is explained or linked to the glossary.

#### User Stories

- As a developer new to AID, I want each page to say plainly what it is for, so that I can find my way from the home page to a first run.
- As an experienced developer, I want the pages to match the current skills and commands, so that I can trust them.

#### Technical Specification

##### Data Model

No database. This feature owns three file shapes.

**1. The audit file**, `.aid/works/work-005-site-rework/site-audit.md` (scaffold created at Specify). Its sections:

| Section | Content | Filled by |
|---|---|---|
| Baseline figures | AC-4 line total and `scripts/` file count, AC-2 skill count; before, after, target | Before: Specify (53944 lines in 138 files; 79 files in `scripts/`; 37 skills). After: Feature 005 |
| Sources of truth | the codes used in the Source column (SK, AG, SC, ST, TPL, RULES, CLI, INS, REL, GEN, DASH, DOC, REPO, VER, FACTS) | Specify |
| Pages | one row per page: `Page` (path under `site/` plus its URL), `Source of truth` (codes), `Verdict`, `Correction` | this feature |
| Redirects | old URL, new URL, status | this feature |
| Kept site functions (FR-9) | one row per FR-9 function, how the build test proves it, status | Feature 005 |
| Scripts on built pages (AC-15) | each script `src` and its purpose | Feature 004 |
| Keyboard check (AC-9), Screenshots (AC-11) | manual results for `/` and `/skills/aid-define/` | Feature 004 |
| Knowledge Base documents edited (FR-10) | document, statement made true | Feature 006 |
| Leads found at Specify | suspected errors to confirm or dismiss | Specify; emptied as each lead lands in its page row |

`Verdict` takes exactly one of: `pending` (not yet audited), `ok` (no change), `corrected` (the Correction
cell says what changed, in one sentence per change, naming the source that proved it), `removed` (the
Correction cell names the redirect target), `new` (page created by this work). AC-3 holds when no row is
`pending` and every file under `site/src/content/docs/` and `site/src/pages/` has a row. A removed page keeps
its row. Rows for generated pages (the skill pages, the skills index, `reference/agents`, `reference/settings`)
take `ok` only after `node scripts/gen-facts.mjs --check` exits 0 (Feature 002) and the page's hand-written
intro, if any, has been checked.

**AC-3 completeness check** (from `site/`, no script file; it prints nothing when AC-3 holds):

```bash
A=../.aid/works/work-005-site-rework/site-audit.md
rows=$(sed -n '/^## Pages/,/^## /p' "$A" | grep -oE '^\| `src/[^`]+`' | cut -c4- | tr -d '`' | sort)
files=$(find src/content/docs src/pages -type f 2>/dev/null | sort)
comm -23 <(echo "$files") <(echo "$rows") | sed 's/^/no row: /'
comm -13 <(echo "$files") <(echo "$rows") | while read -r p; do
  grep -F "| \`$p\` " "$A" | grep -q '| removed |' || echo "row for a missing file not marked removed: $p"; done
sed -n '/^## Pages/,/^## /p' "$A" | awk -F'|' '/^\| `src\//{v=$4; gsub(/^ +| +$/,"",v);
  if (v !~ /^(ok|corrected|removed|new)$/) print "verdict " v ": " $2}'
```

Line 4 finds a file with no row, line 5 a row whose file is gone but whose verdict is not `removed`, and
line 7 any verdict other than the four final ones (so `pending` and `new (planned)` fail). Expected result
when AC-3 holds: no output at all. Run against the scaffold at Specify (2026-10-26: 67 files, 74 rows), it
prints `no row: src/content/docs/concepts/methodology.md` (the scaffold already names the renamed `.mdx`),
a "not marked removed" line for each of the eight planned files, and a `verdict pending` or
`verdict new (planned)` line for every row, so the check can fail.

**2. Page frontmatter for hand-written pages** (schema in `site/src/content.config.ts`):

| Key | Rule |
|---|---|
| `title` | required; plain words, at most about 6 words; becomes the page `h1` |
| `description` | required; the same one sentence that opens the body (rule P1 below) |
| `sidebar.order`, `sidebar.label` | only on pages in an autogenerated sidebar group (Get Started) |
| `reportIssue` | optional, as today (`false` on the four contact pages) |
| `sourceDoc` | not used. Feature 005 (Feature Flow step 4) removes it from the schema and from the four pages that carry it; this feature adds it nowhere |

**3. Glossary anchors.** `reference/glossary.md` keeps its `##` group headings and turns each term into an
`###` heading whose text is the term alone (for example `### Knowledge Base`, with "(KB)" moved into the
definition). The anchor is the id Starlight generates from that heading (`knowledge-base`). Links to a term
use `/reference/glossary/#<anchor>`. Feature 005's link test (FR-8 group b) checks that every such anchor
exists. The glossary page sets `tableOfContents: { maxHeadingLevel: 2 }` in its frontmatter so the table of
contents lists groups, not every term.

##### Feature Flow

1. **Baseline (done at Specify).** The AC-4 "before" figure is in the audit file's Baseline table, taken at
   commit `71b16c35f`.
2. **Per page, list the claims.** Read the page and list every checkable claim: skill names, what a skill
   does, how it is called, phase names and order, agent names and tiers, settings keys, CLI commands, flags
   and exit codes, install commands, artifact names and paths, URLs.
3. **Check each claim against the row's sources**, with these checks:

   | Claim | Check (from the repo root) |
   |---|---|
   | a skill exists | `test -d canonical/skills/<name>` |
   | what a skill does, how it is called | the `description:` and `argument-hint:` of `canonical/skills/<name>/SKILL.md` |
   | a skill's states, agents, outputs | that SKILL.md's state table and `references/state-*.md` |
   | phase names and order | `canonical/aid/rules.md` § Workflow |
   | shortcut verbs, kinds, groups | `canonical/aid/templates/shortcut-catalog.yml` (`name`, `verb`, `artifact`, `group`) and `canonical/aid/templates/shortcut-engine.md` § State Machine |
   | an agent and its tier | `name:` and `tier:` in `canonical/agents/<name>/AGENT.md` |
   | a settings key and its default | `canonical/aid/templates/settings.yml` |
   | a CLI command, flag or exit code | `bash bin/aid -h` and `bash bin/aid <command> -h` (run with a throwaway `HOME`, as the project card's test command does) |
   | an install command | `install.sh`, `install.ps1`, `docs/install.md`; package names in `packages/npm/package.json` and `packages/pypi/pyproject.toml` |
   | an artifact name or path | the templates in `canonical/aid/templates/` (`work-state-template.yml`, `task-state-template.yml`, `delivery-state-template.yml`, `requirements/requirements-template.md`, `task-detail-template.md`) and the SKILL.md that writes it |
   | release and maintainer steps | `docs/release.md`, `release.sh`, `.claude/skills/release-aid/SKILL.md`, `.claude/skills/generate-profile/SKILL.md` |
   | dashboard behaviour | `dashboard/README.md` and `bash bin/aid dashboard -h` |
   | repository layout | `git ls-files` at the top level and `.aid/knowledge/project-structure.md` |
   | the current version | the repo-root `VERSION` file |

   A page copied from `docs/` (code DOC) is a starting text, not a source of truth: its claims are checked
   like any other page's.
4. **Correct and rewrite.** Fix each false or stale claim, and bring the page in line with the plain-language
   rules below. Delete a claim that no source can prove rather than guess.
5. **Record.** Set the row's verdict and write the correction. When a lead from the "Leads found at Specify"
   table is settled, move it into its page row and delete the lead.
6. **Apply the page-set changes** (Migration Plan below) in the same change as the redirects.
7. **Check AC-12.** A reviewer reads every Get Started page and the home page: first paragraph is one
   sentence of purpose; every glossary term is linked on its first use.

Plain-language rules (FR-6). They bind every hand-written page; AC-12 checks P1 everywhere and P2 on the
Get Started pages.

| Rule | Statement |
|---|---|
| P1 | The first paragraph under the `h1` is one sentence that says what the page is for and who it helps ("This page shows you how to install AID on Linux, macOS or Windows."). It is the same sentence as `description`. |
| P2 | The first use of a glossary term on a page links to its glossary anchor. A term not in the glossary is either explained in the same sentence or added to the glossary. |
| P3 | Short sentences: aim for 25 words or fewer, one idea each, active voice, address the reader as "you". |
| P4 | No hand-written counts that change when the repository changes (number of skills, catalog rows, agents, KB documents). Say "every skill" and link to the generated page that shows the number. |
| P5 | Describe what is true now. No change history ("no longer", "formerly", "was retired"), and no internal ids of works, features, tasks, deliveries, requirements or known issues. An example argument in a command (`/aid-execute work-001 task-001`) is allowed. |
| P6 | Commands are in code blocks, copyable, and exactly as the CLI or SKILL.md defines them. |
| P7 | Link text names the destination ("the Installation guide"); never "here", "click here" or a bare URL. |
| P8 | Body headings start at `##` and never skip a level; no hand-written table of contents (Starlight renders one). |
| P9 | Each fact is stated on one page; other pages link to it. Concepts pages explain; Reference pages list facts; Guides give steps. |

##### Layers & Components

All paths are under `site/` unless stated.

| Layer | Files this feature changes | Change |
|---|---|---|
| Content | every hand-written page under `src/content/docs/` (the rows in the audit file not marked FACTS) | corrected and rewritten per the flow and rules above |
| Content (new) | `src/content/docs/concepts/{pipeline,knowledge-base,agents,feedback-loops,aid-and-sdd}.mdx` and `src/content/docs/concepts/case-studies.md` | split from `concepts/methodology.md` (Migration Plan) |
| Content (renamed) | `src/content/docs/concepts/methodology.md` becomes `concepts/methodology.mdx`, same URL | it hosts diagram D3 (Feature 003) |
| Content (removed) | `src/content/docs/{get-started,concepts,reference}/index.md`, `src/content/docs/concepts/overview.md`, `src/content/docs/reference/skills.md` | deleted; URLs redirected |
| Config | `astro.config.mjs`: the `sidebar` array and a new top-level `redirects` object | per the map below |
| Work folder | `.aid/works/work-005-site-rework/site-audit.md` | filled in |

Boundaries with the other features:
- Generated pages (skill pages, skills index, `reference/agents.md`, `reference/settings.md`) are written by
  Feature 002's script. This feature edits none of their text; a wrong fact there is fixed in the script or in
  `canonical/` (out of scope: then recorded in the audit as a finding for the owner). One such finding is
  already a lead in the audit file: the `description` of `canonical/skills/aid-experiment/SKILL.md` is a
  folded block that breaks `/aid-` and `execute` across two lines, so the generated `/skills/aid-experiment/`
  page reads "/aid- execute". The row for that page records it as a finding for the owner (§4 keeps
  `canonical/` out of scope); its verdict is `ok` once `--check` passes, because the page states the source
  faithfully.
- Diagrams on any page are Feature 003's. When a section with a diagram moves to a new page, the diagram moves
  with it, and Feature 003 redraws it there.
- The changelog page and the contact form are Feature 005's; this feature audits their words only.
- `astro.config.mjs` is edited by Features 003, 004 and 005 too. This feature owns only `sidebar` (except the
  Skills group, which Feature 002 owns) and `redirects`.

##### Migration Plan

**Why the methodology page splits.** `concepts/methodology.md` is 113,634 bytes of Markdown today, so its
built page would very likely break the 150 KB limit (NFR-2, AC-15) once the site chrome is added, and its ten
sections each answer a different question. Its URL stays and becomes the Concepts landing page.

**File extensions.** A page that hosts a diagram imports an Astro component, which only MDX can do, so
every diagram host is `.mdx` (Feature 003 lists the hosts). The split therefore creates
`concepts/{pipeline,knowledge-base,agents,feedback-loops,aid-and-sdd}.mdx` and renames
`concepts/methodology.md` to `concepts/methodology.mdx` (`git mv`, in the same change as the split).
`concepts/case-studies.md` hosts no diagram and stays `.md`. Starlight routes by slug, so no URL changes, and
no slug has two files. In every `.mdx` page, a literal `{`, `}` or `<` outside code is escaped (`\{`,
`\}`, `&lt;`), because MDX parses them. Feature 003 adds its components to these files after the split.

| Today | After the rework |
|---|---|
| `concepts/methodology.md` § Table of Contents | deleted (P8) |
| §§ 1 The Pipeline and 4 The Phases | new `concepts/pipeline.mdx` |
| § 2 Philosophy | stays in `concepts/methodology.mdx` (renamed), under a short intro that links to each Concepts page |
| § 3 The Knowledge Base | new `concepts/knowledge-base.mdx` |
| § 5 The Agent Model | new `concepts/agents.mdx` (the idea of tiers and dispatch; the roster stays on `reference/agents`) |
| § 6 Feedback Loops | new `concepts/feedback-loops.mdx` |
| § 7 Artifacts Reference | merged into `reference/artifacts.md`; the template excerpts are replaced by links to `canonical/aid/templates/` on GitHub |
| § 8 Case Studies | new `concepts/case-studies.md` |
| § 9 Comparison with SDD | new `concepts/aid-and-sdd.mdx` |
| § 10 Adoption Guide | brownfield and greenfield starts merged into `get-started/first-work.mdx`; anti-patterns into `concepts/faq.md`; "Getting AID onto your machine" dropped (the install pages hold it) |
| `concepts/overview.md` | removed; its pointers are now the intro of `concepts/methodology.mdx` |
| `reference/skills.md` (titled "Shortcut engine") | removed; the engine text merged into `get-started/lite-path.mdx`, which already explains the engine (P9) |
| `get-started/index.md`, `concepts/index.md`, `reference/index.md` | removed (each is a one-line "see Overview" stub) |
| `src/pages/releases/changelog.astro` | replaced by `src/content/docs/releases/changelog.mdx` (Feature 005), same URL |

Every new or kept page must build to at most 150 KB (Feature 004's check); a page that does not is split
again along its `##` sections.

Redirects, added to `astro.config.mjs` as a top-level `redirects` object, in the same change that deletes
the pages (Astro rejects a redirect whose source is still a page):

```js
redirects: {
  '/get-started': '/get-started/overview/',
  '/concepts': '/concepts/methodology/',
  '/concepts/overview': '/concepts/methodology/',
  '/reference': '/reference/overview/',
  '/reference/skills': '/skills/',
},
```

`/reference/skills/` points at the skills roster because that is what its URL names. Astro writes each
redirect as a small HTML page with a `meta http-equiv="refresh"`; Feature 004's page checks skip such
pages and Feature 005's link test follows them.

Final sidebar (replaces the `sidebar` array in `astro.config.mjs`; the Skills group is Feature 002's and is
shown only for position). Until Feature 005 step 2 creates `releases/changelog.mdx`, the Releases entry keeps
today's `link: '/releases/changelog'`; that step switches it to the `slug:` form shown:

```js
sidebar: [
  { label: 'Home', slug: '' },
  { label: 'Get Started', items: [{ autogenerate: { directory: 'get-started' } }] },
  { label: 'Guides', items: [
    { label: 'Installation', slug: 'guides/installation' },
    { label: 'Working the pipeline', slug: 'guides/pipeline' },
    { label: 'Web dashboard', slug: 'guides/dashboard' },
    { label: 'Maintainer', slug: 'guides/maintainer' },
  ] },
  { label: 'Concepts', items: [
    { label: 'The methodology', slug: 'concepts/methodology' },
    { label: 'The pipeline', slug: 'concepts/pipeline' },
    { label: 'Knowledge Base', slug: 'concepts/knowledge-base' },
    { label: 'Agents', slug: 'concepts/agents' },
    { label: 'Feedback loops', slug: 'concepts/feedback-loops' },
    { label: 'Case studies', slug: 'concepts/case-studies' },
    { label: 'AID and spec-driven development', slug: 'concepts/aid-and-sdd' },
    { label: 'FAQ', slug: 'concepts/faq' },
  ] },
  { label: 'Reference', items: [
    { label: 'Overview', slug: 'reference/overview' },
    { label: 'CLI commands', slug: 'reference/cli' },
    { label: 'Agents', slug: 'reference/agents' },
    { label: 'Knowledge Base documents', slug: 'reference/kb' },
    { label: 'Settings keys', slug: 'reference/settings' },
    { label: 'Artifacts', slug: 'reference/artifacts' },
    { label: 'Repository structure', slug: 'reference/repository-structure' },
    { label: 'Glossary', slug: 'reference/glossary' },
  ] },
  // Skills group: Feature 002
  { label: 'Releases', items: [{ label: 'Changelog', slug: 'releases/changelog' }] },
  { label: 'Contact Us', items: [
    { label: 'Report a site problem', slug: 'contact/site-issue' },
    { label: 'Report an AID bug', slug: 'contact/methodology-bug' },
    { label: 'Ask or give feedback', slug: 'contact/feedback' },
    { label: 'Request a conversation', slug: 'contact/contact-request' },
  ] },
],
```

Get Started order and labels come from each page's frontmatter: `overview` (order 1, label "What is AID?"),
`install` (2, "Install"), `first-work` (3, "Your first work"), `lite-path` (4, "Small changes with
shortcuts"). The four contact pages get short titles that match their sidebar labels.

The "start here" path (FR-6): the home page's first link after its purpose sentence is "Start here: What is
AID?" to `/get-started/overview/`; the four Get Started pages then follow each other in sidebar order, and
Starlight's previous/next links at the foot of each page carry the reader from "What is AID?" to "Small
changes with shortcuts". The home page keeps the install commands and the version badge (Feature 005).

### Feature 002 — Site Facts from `canonical/`

- **Priority:** Must
- **Requirements:** §5 FR-2
- **Criteria:** AC-2

#### Description

One small script (with a `--check` flag) reads `canonical/` and produces the skill pages and the agent, skill and settings facts of the site, so they cannot drift. It replaces the output of the four old generators. Deleting the old generators, their helper libraries and their tests is Feature 005's job; this feature only builds the replacement. Everything else on the site is hand-written Markdown.

#### User Stories

- As a maintainer, I want skill and agent facts to come from `canonical/`, so that the site cannot go stale when a skill changes.
- As an experienced developer, I want one page per skill that matches the skill itself, so that I can look up exactly what it does.

#### Technical Specification

##### Data Model

No database or schema. The feature adds one script, `site/scripts/gen-facts.mjs`, which reads four
inputs under `canonical/` and writes Markdown pages that are committed to git.

**Inputs (read-only).**

| Input | What is read | Parse rule |
|---|---|---|
| `canonical/skills/*/SKILL.md` (one per directory) | frontmatter keys `name`, `description`, `argument-hint` (optional), `allowed-tools` | top-level frontmatter only; see "Frontmatter subset" below |
| `canonical/agents/*/AGENT.md` | frontmatter keys `name`, `description`, `tier`, `tools` | same parser; nested blocks such as `review-criteria:` are skipped |
| `canonical/aid/templates/shortcut-catalog.yml` | each row's `name`, `group`, `kind_of` | line-based: a row opens at `  - name: <v>`; its fields are the `    <key>: <v>` lines after it; full-line `#` comments and trailing ` #` comments are ignored; quotes are stripped |
| `canonical/aid/templates/settings.yml` | every key, its starting value and its comment | see "Settings template parse" below |

The settings page now documents the shipped template (what a new install starts with), not this
repository's own `.aid/settings.yml` that `gen-reference.mjs` (`SETTINGS_FILE`) reads today. That
file carries this repository's runtime values (`knowledge.doc_set`, `knowledge.term_exclusions`),
which are not reference facts.

**Frontmatter subset** (`readFrontmatter(text, file)`). The file must start with a `---` line, and the
block ends at the next `---` line. CRLF is normalised to LF first. Each column-0 line
`^([A-Za-z][\w-]*):\s*(.*)$` starts a key:
- value `>` or `>-`: folded block. The indented lines that follow are trimmed and joined with one space.
- value `|`: literal block. The indented lines that follow are joined with `\n`.
- empty value: a nested block. Its indented lines are skipped and the key is not recorded.
- `"..."`: quotes stripped, `\"` and `\\` unescaped. `'...'`: quotes stripped, `''` becomes `'`.
  Any other value is trimmed and kept as written.

All recorded values are strings. The folded form is the same one YAML produces, so a source
line break inside a word stays visible. Today `aid-experiment` renders as "/aid- execute": the
script renders the fact faithfully. Feature 001 records it as a finding for the owner (its Layers &
Components, Boundaries, and the audit file's "Leads found at Specify" table), because fixing
`canonical/` is out of scope (§4).

**Settings template parse** (`parseSettings(text)`), one pass over the lines:
- A blank line resets the pending block comment and the "last key" pointer.
- A **column-0 comment** (`^#`) is appended to the pending block comment.
- A **key line** is `^(\s*)([a-z_][a-z0-9_]*):(.*)$`. It is a **commented key** when it has the form
  `^(\s+)#\s*([a-z_][a-z0-9_]*):(.*)$`, which is only accepted when indented, so the column-0 line
  `# knowledge: KB baseline ...` stays a block comment. The rest of the line splits at the first
  `\s+#\s`: the left part is the value and the right part is the comment. The column of that `#`
  is saved as `commentCol`.
- A comment line whose `#` sits exactly at the last key's `commentCol` continues that key's comment.
- A column-0 key with an empty value is a **section**. Its description is the pending block
  comment, with a leading `<key>:` removed. The indented keys below it get the path `<section>.<key>`.
- If the parse finds zero keys, the script exits 2. A parser that reads nothing must not
  report "up to date".

**In-memory shapes** (JSDoc typedefs in the script):

```js
/** @typedef {{ name: string, purpose: string, rest: string, argumentHint: string|null,
 *              allowedTools: string[], order: number, group: Group }} Skill
 *  purpose = first sentence of `description`; rest = the remaining sentences ('' if none). */
/** @typedef {{ id: string, label: string, anchor: string, blurb: string, ordered: boolean,
 *              fixed: string[]|null, skills: Skill[] }} Group
 *  fixed = skill names for a fixed group; null for a catalog group (id is a catalog code). */
/** @typedef {{ name: string, description: string, tier: 'large'|'medium'|'small',
 *              tools: string[] }} Agent */
/** @typedef {{ key: string, value: string, description: string,
 *              kind: 'key'|'section'|'unseeded' }} SettingRow */
/** @typedef {Map<string, string>} PageSet  // out-relative POSIX path -> exact file content */
```

**The group table** (`GROUPS`, the only hand data in the script; it is per group, never per skill),
in index order:

| `id` | `label` (heading, and the anchor on `/skills/`) | Membership |
|---|---|---|
| `full-path` | Full path | fixed, `ordered: true`: `aid-discover`, `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute` (pipeline order, as in the Workflow rule of `canonical/aid/rules.md`) |
| `G3` | Explore and design | catalog rows with `group: G3` |
| `G4` | Create | `group: G4` |
| `G5` | Change | `group: G5` |
| `G6` | Fix | `group: G6` |
| `G7` | Test and experiment | `group: G7` |
| `G8` | Document | `group: G8` |
| `G9` | Deploy | `group: G9` |
| `G10` | Monitor | `group: G10` |
| `G11` | Investigate and review | `group: G11` |
| `kb` | Knowledge Base upkeep | fixed: `aid-summarize`, `aid-housekeep`, `aid-update-kb` |
| `support` | Setup and support | fixed: `aid-config`, `aid-triage`, `aid-chat`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket` |

Only **family rows** (rows without `kind_of`) assign a skill to a catalog group, because a kind row
has no directory. Inside a catalog group, skills follow the order of their rows in the catalog file.
Each group also carries a one-sentence `blurb`, written in the table constant:

| `id` | `blurb` |
|---|---|
| `full-path` | The phases of a full AID run, in the order you call them. |
| `G3` | Shape an idea before you build it. |
| `G4` | Add something new to the project. |
| `G5` | Change, restructure, remove, deprecate or migrate something that exists. |
| `G6` | Find and correct a defect. |
| `G7` | Run tests and checks, or run an experiment. |
| `G8` | Write a document outside the Knowledge Base. |
| `G9` | Package finished work into a release. |
| `G10` | Watch production and route what you find. |
| `G11` | Answer questions, research options, analyse data and review work. |
| `kb` | Keep the Knowledge Base current and readable. |
| `support` | Configure AID, connect tools and trackers, and pick the right skill. |

The anchor is `label.toLowerCase().replace(/[^a-z0-9 -]/g, '').trim().replace(/ +/g, '-')`. For
these ASCII labels it equals the id Starlight gives the `## <label>` heading (for example `full-path`
or `investigate-and-review`).

**Why the fixed list is wider than "full-path skills".** 18 of the 37 skill directories have no
catalog family row: the 7 full-path skills plus 11 helpers (Knowledge Base upkeep, setup, connectors,
tickets). With only the full-path list, those 11 would make the script fail by design. So the fixed
part holds three groups instead of one.

**Outputs (committed, generated).** Paths are relative to `site/src/content/docs/`:

| Page | Count today | Route |
|---|---|---|
| `skills/<name>.md` | one per `canonical/skills/*` directory (37) | `/skills/<name>/` |
| `skills/index.md` | 1 | `/skills/` |
| `reference/agents.md` | 1 | `/reference/agents/` |
| `reference/settings.md` | 1 | `/reference/settings/` |

Every output is UTF-8 with LF line ends and one trailing newline. Each starts with YAML frontmatter,
then the marker line
`<!-- generated by site/scripts/gen-facts.mjs from <source> - do not edit -->`. `<source>` is the
repo-relative input: `canonical/skills/<name>/SKILL.md`; `canonical/skills/*/SKILL.md and canonical/aid/templates/shortcut-catalog.yml`
for the index; `canonical/agents/*/AGENT.md`; or `canonical/aid/templates/settings.yml`. The
frontmatter uses only Starlight's own keys (`title`, `description`, `sidebar`). The project
extensions in `site/src/content.config.ts` (`generatedFrom`, `sourceDoc`) are not used, so this
feature does not depend on whether Feature 005 keeps them.

Not generated by this script, although `gen-reference.mjs` generates both today:
- `reference/kb.md` (the KB document types page) stays as a hand-written page, per the owner decision.
  Feature 005 (Feature Flow step 4) removes its `generatedFrom:` line and its generated marker.
- `reference/skills.md` (the shortcut-engine narrative) is deleted by Feature 001, which moves its text
  into `get-started/lite-path.mdx` and redirects the URL to `/skills/`.

##### Feature Flow

`node site/scripts/gen-facts.mjs [--check] [--canonical <dir>] [--out <dir>]`. It can run from any
working directory: default paths resolve from the script's own location
(`fileURLToPath(import.meta.url)`). `--canonical` defaults to `<repo>/canonical` and `--out` to
`<repo>/site/src/content/docs`. The two path options exist so the tests can point the script at
fixtures. An unknown argument exits 2 with a usage line.

1. **Load skills.** List the directories of `<canonical>/skills` in sorted (code-unit) order. For each
   one, read `SKILL.md`. Exit 2 if the file is missing, if `name` or `description` is missing, or if
   `name` differs from the directory name. Split `allowed-tools` on `/[\s,]+/`. To get `purpose` and
   `rest`, split `description` at the first match of ``/[.!?]\s+(?=[A-Z\/`(])/``. Against today's
   descriptions this splits `aid-create` after "...or a document." and leaves "test...)" and
   "REQUIREMENTS.md" whole.
2. **Load the catalog.** Keep the family rows. Exit 2 if a family row has no skill directory, or if
   its `group` code has no `GROUPS` entry.
3. **Assign groups.** A skill goes to the fixed group that names it, or to the catalog group of its
   family row. Exit 2, naming the skill, when:
   - it is in both (`<name> is in fixed group <id> and in the catalog`);
   - it is in neither (`<name> has no group: add a catalog row or a GROUPS entry in site/scripts/gen-facts.mjs`);
   - a fixed list names a skill with no directory.
   A group with no skills is left out of the output. Number the skills 1..N in index order (group
   order, then order within the group). That number becomes the page's `sidebar.order`.
4. **Load agents.** Read the directories of `<canonical>/agents` in sorted order. Exit 2 if `name`,
   `description` or `tier` is missing, if `name` differs from the directory name, or if `tier` is
   not one of `large`, `medium`, `small`. Split `tools` on `/[\s,]+/`.
5. **Load settings.** Run `parseSettings` on `<canonical>/aid/templates/settings.yml`.
6. **Render** the PageSet (layouts under Layers & Components).
7. **Compare** with `<out>`. For each PageSet path, the file is *missing* or *stale* when it is absent
   or its bytes differ. Every `<out>/skills/*.md` file not in the PageSet is *extra*.
8. **`--check`** writes nothing. It prints one line per problem to stderr
   (`gen-facts: stale|missing|extra: <out-relative path>`), then
   `gen-facts: <n> page(s) out of date; run: node site/scripts/gen-facts.mjs`, and exits 1. With no
   problems it prints `gen-facts: <count> pages up to date` and exits 0.
9. **Write mode** (no flag) writes only missing or stale files (`mkdirSync(..., {recursive: true})`).
   It deletes an *extra* file only when the file holds the generated marker. An extra file without the
   marker exits 2 (`<path> is not generated; move it out of skills/`), so hand-written content is never
   deleted. It prints `gen-facts: wrote <w>, removed <r>, unchanged <u>` and exits 0.

**Exit codes:** `0` up to date or written; `1` drift (`--check` only, and nothing else ever exits 1);
`2` input or usage error, or an unexpected error (a crash). Messages go to stderr and start with
`gen-facts:`. So a caller can tell the two failures apart: exit 1 means "run
`node site/scripts/gen-facts.mjs` and commit its output"; exit 2 means "read the message, the input or the
script is wrong".

**When it runs.** The script is **not** chained into `prebuild`, so `astro build` renders exactly the
committed pages. What a pull request shows is what gets deployed, and the check stays meaningful:
a build that regenerated the pages first would make a later `--check` pass vacuously. It runs:
- by hand, after a `canonical/` change, through `npm run facts` (`node scripts/gen-facts.mjs`), with
  the output committed in the same change. This is the same discipline as the `run_generator.py`
  resync for `profiles/`;
- as FR-8 group (c), through `npm run facts:check` (`node scripts/gen-facts.mjs --check`), inside
  `npm test`;
- in `.github/workflows/docs.yml` before `npm ci` (the step is specified in Feature 006).

Feature 005 owns the final `scripts` block of `site/package.json` and adds the `facts` and
`facts:check` entries above.

##### Layers & Components

The script is one file, `site/scripts/gen-facts.mjs`, at most 300 lines including comments (FR-2,
AC-4). The design target is 265 lines, which leaves 35 lines of headroom under the cap. It imports
only `node:fs`, `node:path`, `node:url` and `node:process`, and nothing from the old
`scripts/skills/*` or `scripts/lib/*` modules. Its sections, in file order, with a line budget for
each (every line of the file belongs to one row):

| Section | Exports or functions | Budget |
|---|---|---|
| Header comment: purpose, usage, exit codes | — | 10 |
| Imports (four lines, one per built-in module) | — | 4 |
| JSDoc typedefs (Data Model, "In-memory shapes") | — | 12 |
| Paths, `GROUPS` (12 entries with their blurbs), `TIERS = ['large','medium','small']`, `BLOB = 'https://github.com/AndreVianna/aid-methodology/blob/master'` | constants | 30 |
| `class InputError extends Error {}` | — | 1 |
| Argument parsing | `parseArgs(argv) -> {check, canonical, out}` | 12 |
| Parsers | `readFrontmatter(text, file)`, `parseCatalog(text)`, `parseSettings(text)` | 62 |
| Markdown helpers | `yamlStr(s)` (single-quoted, `'` doubled); `md(s)` (backslash-escapes backslash, backtick, `*`, `_`, `[`, `]`, `<`, `>` and the pipe character); `code(s)` (fence one backtick longer than the longest run inside); `cell(s)` (escapes the pipe character with a backslash, for table cells) | 10 |
| Loaders | `loadSkills(dir)`, `assignGroups(skills, rows)`, `loadAgents(dir)` | 40 |
| Renderers | `skillPage(skill)`, `skillIndex(groups, total)`, `agentsPage(agents)`, `settingsPage(rows)`, `buildPages(canonical) -> PageSet` | 58 |
| Main | `main()`: compare, check or write, the one `try`/`catch`, exit code | 24 |
| Direct-run guard | `if (process.argv[1] === fileURLToPath(import.meta.url)) main();` | 2 |
| **Total** | | **265** |

A section that runs over its budget takes lines from the 35-line headroom, never from another section's
behaviour; `wc -l site/scripts/gen-facts.mjs` must print at most 300.

Input errors are thrown as `class InputError extends Error`. `main()` wraps its whole body in one
`try`/`catch`: an `InputError` prints `gen-facts: <message>`; any other error prints
`gen-facts: internal error` and the stack. Both then set `process.exitCode = 2`, so a crash can never
look like drift (exit 1). The file exports nothing and runs `main()` only when executed directly
(`process.argv[1] === fileURLToPath(import.meta.url)`).

**Page layouts.** All examples use today's data. The text in `md()` is escaped. In each case the first
paragraph is one sentence stating the page's purpose (FR-6, AC-12). No page carries a script, an
`h1` in the body, a diagram or an HTML block (AC-15, AC-10).

*Skill page* (`skills/aid-fix.md`):

```markdown
---
title: 'aid-fix'
description: 'Diagnose and correct a defect or regression. Plans the work; /aid-execute builds it.'
sidebar:
  order: 17
---

<!-- generated by site/scripts/gen-facts.mjs from canonical/skills/aid-fix/SKILL.md - do not edit -->

Diagnose and correct a defect or regression.

Plans the work; /aid-execute builds it.

## Facts

- **Group:** [Fix](/skills/#fix)
- **Command:** `/aid-fix`
- **Arguments:** `[description]  -- what to fix; runs straight to a graded flattened Lite work`
- **Allowed tools:** `Read`, `Glob`, `Grep`, `Bash`, `Shell`, `Terminal`, `Write`, `Edit`, `Agent`
- **Source:** [SKILL.md for aid-fix on GitHub](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-fix/SKILL.md)
```

- `description` (frontmatter) is the whole description, verbatim. The first paragraph is `purpose`.
  The second paragraph is `rest`, left out when `rest` is empty.
- With no `argument-hint` (today `aid-deploy` and `aid-monitor`), the line reads
  `- **Arguments:** none declared`.
- No flow diagram, no copy of the skill body, and no other frontmatter key: only the facts in the
  owner decision.

*Skills index* (`skills/index.md`). This feature owns the Skills group of the sidebar (Feature 001's
map shows it only for position) and keeps it exactly as `site/astro.config.mjs` has it today: an
`All skills` item (`slug: 'skills'`) followed by a collapsed `Every skill` group autogenerated from
`skills/`. Because the index has its own item, it keeps `sidebar.hidden: true`, so the autogenerated
group does not list it a second time.

```markdown
---
title: 'All skills'
description: 'Every AID skill, grouped by what it is for, with one line on each.'
sidebar:
  hidden: true
---

<!-- generated by site/scripts/gen-facts.mjs from canonical/skills/*/SKILL.md and canonical/aid/templates/shortcut-catalog.yml - do not edit -->

This page lists every AID skill, grouped by what it is for.

AID has 37 skills. Each name below opens that skill's page.

## Full path

The phases of a full AID run, in the order you call them.

1. [aid-discover](/skills/aid-discover/): Build the Knowledge Base from an existing codebase: architecture, conventions and patterns.
2. [aid-describe](/skills/aid-describe/): Gather requirements through an adaptive interview and write REQUIREMENTS.md.
...

## Explore and design

Shape an idea before you build it.

- [aid-prototype](/skills/aid-prototype/): Build a throwaway low-fidelity model, such as a UI, to test a direction.
...
```

An `ordered: true` group renders an ordered list and the others render bullet lists. Each entry
shows `purpose` only. The count (37) is computed from the directory listing.

*Agents page* (`reference/agents.md`):

```markdown
---
title: 'Agents'
description: 'The agents AID skills dispatch, with the default model tier, tools and definition of each.'
---

<!-- generated by site/scripts/gen-facts.mjs from canonical/agents/*/AGENT.md - do not edit -->

This page lists the agents that AID skills dispatch, with each agent's default model tier, tools and definition file.

AID has 9 agents: 1 in the large tier, 7 in the medium tier and 1 in the small tier. The tier is the model size an agent gets by default; a dispatch can choose a larger model for a harder task, as set out in [the agent dispatch tiering rules](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/agent-dispatch-tiering.md).

## Large tier

### aid-architect

Transforms requirements, SPEC, and KB into design output — ...

- **Tools:** `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`
- **Definition:** [AGENT.md for aid-architect on GitHub](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/agents/aid-architect/AGENT.md)

## Medium tier
...
```

Tiers appear in `TIERS` order, and an empty tier is left out. Agents sort by name inside a tier.
The counts are computed. The description is verbatim, `md()`-escaped. The page uses sections, not a
wide table, so it reads at 320 px (Feature 004).

*Settings page* (`reference/settings.md`):

```markdown
---
title: 'Settings keys'
description: 'Every key in .aid/settings.yml, the value a new install starts with, and what it does.'
---

<!-- generated by site/scripts/gen-facts.mjs from canonical/aid/templates/settings.yml - do not edit -->

This page lists every key in a project's `.aid/settings.yml`, with the value a new install starts with and what the key does.

Run `/aid-config` to see every value, or `/aid-config <key>` to view and change one key. The defaults below come from [the settings template on GitHub](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/settings.yml).

| Key | Starts as | What it does |
|---|---|---|
| `format_version` | `5` | schema stamp — machine-written, do not hand-edit. `aid` reads it to decide whether this file needs migrating to a newer layout. |
| `name` | `<project-name>` | set during /aid-config INIT |
| `type` | `brownfield` | brownfield \| greenfield |
| `knowledge` | group of keys | KB baseline + discovery inputs. `source` is the branch ... (not seeded here). |
| `knowledge.source` | `master` | branch compared for KB freshness (set to your main branch) |
| `knowledge.last_update` | not set | ISO-8601 datetime of the last KB build vs source |
...
```

The `Starts as` cell is `code(value)` for `kind: 'key'`, `group of keys` for a section, and `not set`
for `kind: 'unseeded'`. The description cell is the comment text as written: its backticks are kept
as Markdown code, and `cell()` escapes only `|`. The second paragraph matches the `/aid-config`
`argument-hint` ("(none) view all | <key> view+update one"), which retires today's stale
`review.minimum_grade` wording.

**Tests (FR-8 group c).** Feature 005 fixes the file name and its place among the four groups. The
content is specified here, because a check that never fails proves nothing. `npm test` runs vitest
with `site/` as its working directory, so the test builds every path from the `SITE` and `REPO`
exports of `tests/dist.mjs` (Feature 005) and never from a relative string. Each case runs
`spawnSync(process.execPath, [join(SITE, 'scripts/gen-facts.mjs'), ...args], { cwd: SITE, encoding: 'utf8' })`.
In the table, `site/...` means `join(SITE, ...)` and `canonical/...` means `join(REPO, 'canonical', ...)`:

| Case | Setup | Expected |
|---|---|---|
| C1 committed pages are current | `--check` | exit 0; stdout or stderr matches `/pages up to date/` |
| C2 a stale page is caught | copy `site/src/content/docs/{skills,reference/agents.md,reference/settings.md}` into a `mkdtempSync` dir and append a line to `skills/aid-fix.md`; `--check --out <tmp>` | exit 1; stderr names `stale: skills/aid-fix.md` |
| C3 an extra page is caught | same copy, plus `skills/aid-gone.md`; `--check --out <tmp>` | exit 1; stderr names `extra: skills/aid-gone.md` |
| C4 an ungrouped skill fails | copy `canonical/skills`, `canonical/agents` and the two templates into a temp `canonical` tree and add `skills/aid-orphan/SKILL.md` (with `name: aid-orphan` and a `description`); `--check --canonical <tmp>` | exit 2; stderr contains `aid-orphan has no group` |
| C5 write mode reproduces the committed bytes | `--out <tmp>` into an empty temp dir, then `--check --out <tmp>` | first run exit 0 with `wrote 40`; second run exit 0 |

The tests never write inside `site/src/content/docs/`. Every fixture lives in a temp directory that
is removed in `afterAll`, which avoids the hazard of tests writing into the tracked content tree.
C5's `40` is computed in the test as `readdirSync(join(REPO, 'canonical/skills')).length + 3`, not
written as a literal. The exit-code assertions are exact (`status === 1` for C2 and C3, `status === 2`
for C4), so a crash (exit 2) can never pass a drift case.

**Verification for AC-2** (from `site/`): `node scripts/gen-facts.mjs --check` exits 0, and after
`npm run build`, `find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` equals
`ls ../canonical/skills | wc -l`.

**Dependencies on other features.** Feature 005 deletes the old generators and their tests, wires
the `facts` scripts and removes `gen:skills` and `gen:reference` from `prebuild`. Feature 006 adds the
CI step and the KB statements. Feature 004's accessibility check covers these pages like any other.
Feature 001's audit lists the generated pages and checks them against the same sources.

### Feature 003 — Accessible Diagrams

- **Priority:** Must
- **Requirements:** §5 FR-3
- **Criteria:** AC-8

#### Description

All diagrams are redrawn as static, accessible diagrams. Each has a title, a text description and a text equivalent (an ordered list or table) carrying the same information. No diagram needs JavaScript to be understood.

#### User Stories

- As a screen-reader user, I want every diagram to have a text equivalent, so that I get the same information as a sighted reader.
- As a developer new to AID, I want clear, uncluttered diagrams, so that I can see how the phases fit together.

#### Technical Specification

##### Data Model

No data store and no generated data. A diagram is an Astro component: hand-drawn SVG shapes plus
a hand-written text equivalent, rendered to static HTML at build time. The component's props are
the only interface (see Layers & Components).

**The diagram set.** Today the hand-written pages hold 10 Mermaid fences and 1 raster diagram:
`index.mdx` § The pipeline at a glance, `guides/pipeline.mdx` § The pipeline at a glance,
`guides/maintainer.mdx` § How releases work, and `concepts/methodology.md` § 1. The Pipeline,
§ 3. The Knowledge Base, § Context Feeding Strategy — RAG by Convention, § The Lite Path:
Direct-Entry Shortcuts, § 5. The Agent Model, § 6. Feedback Loops and § Where We Diverge (each the
`` ```mermaid `` fence under that heading), plus the PNG `src/assets/3-ironman.png` used in
`concepts/methodology.md` § The Iron Man Model: Human-in-the-Middle. (The 37 skill pages also hold one fence each; Feature 002 regenerates
them with no diagram.) Paths here are under `site/src/content/docs/` unless they start with `site/`.
The three pipeline overviews (index, guides/pipeline, methodology § 1. The Pipeline) say the same thing, so
they merge into one diagram. One diagram is new: D10 takes the "build, review, fix" loop that today
appears only as a footnote line inside the PNG, and shows it on its own.

| Id | Component (`site/src/components/diagrams/`) | Host page after Feature 001's migration | Replaces |
|---|---|---|---|
| D1 | `Pipeline.astro` | `index.mdx`; `concepts/pipeline.mdx` | fences in `index.mdx` § The pipeline at a glance and `methodology.md` § 1. The Pipeline; the fence in `guides/pipeline.mdx` § The pipeline at a glance is deleted and its section links to `/concepts/pipeline/` (Feature 001's rule P9) |
| D2 | `TwoPaths.astro` | `concepts/pipeline.mdx` | the fence in `methodology.md` § The Lite Path: Direct-Entry Shortcuts |
| D3 | `ReviewLoop.astro` | `concepts/methodology.mdx` | the PNG in `methodology.md` § The Iron Man Model: Human-in-the-Middle |
| D4 | `KbStructure.astro` | `concepts/knowledge-base.mdx` | the fence in `methodology.md` § 3. The Knowledge Base |
| D5 | `ContextLoading.astro` | `concepts/knowledge-base.mdx` | the fence in `methodology.md` § Context Feeding Strategy — RAG by Convention |
| D6 | `AgentTiers.astro` | `concepts/agents.mdx` | the fence in `methodology.md` § 5. The Agent Model |
| D7 | `FeedbackLoops.astro` | `concepts/feedback-loops.mdx` | the fence in `methodology.md` § 6. Feedback Loops and the loop table in § The Eleven Loops |
| D8 | `AidVsSdd.astro` | `concepts/aid-and-sdd.mdx` | the fence in `methodology.md` § Where We Diverge |
| D9 | `ReleaseFlow.astro` | `guides/maintainer.mdx` | the fence in `maintainer.mdx` § How releases work |
| D10 | `TaskLoop.astro` | `guides/pipeline.mdx`, under `### Phase 6 — Execute` | new (from the PNG's footnote) |

**Host file extension.** A Markdown page cannot import a component, so every host in the table above is
`.mdx`. `index.mdx`, `guides/pipeline.mdx` and `guides/maintainer.mdx` already are. The five new
Concepts hosts and the rename of `concepts/methodology.md` to `.mdx` are Feature 001's split (its
Migration Plan, "File extensions", which also states the MDX escaping rule), so this feature's
Concepts diagrams land after that split and edit only `.mdx` files.

**Content of each diagram.** For each one: the `title` (the SVG `<title>`), the `desc` (the SVG
`<desc>`), the `caption` (the visible `<figcaption>`), the source of truth the content was checked
against, the drawing, and the text equivalent. The text equivalent is normative: the drawing shows
the same steps and links and nothing else. Every fact below was checked against the cited source.
Feature 001's audit row for the host page covers the diagram's words like any other text on it.
No diagram states a count that changes when the repository changes (Feature 001's rule P4).

**D1 — The AID pipeline** (`id="pipeline"`, viewBox 400 x 720)
- Sources: `canonical/aid/rules.md` § Workflow; the `description` of `aid-config`, `aid-discover`,
  `aid-triage`, `aid-execute`, `aid-deploy`, `aid-monitor` and `aid-housekeep` in their SKILL.md;
  `canonical/aid/templates/shortcut-engine.md` § State Machine.
- desc: "AID starts with a one-time setup and, on an existing codebase, a Knowledge Base build. Work
  then reaches /aid-execute by the full path of separate phases or by a shortcut that plans the work
  in one run. Deploy and Monitor are optional steps after Execute."
- caption: "How a piece of work moves through AID, from setup to delivery."
- Drawing: a top-down column. `/aid-config` above `/aid-discover`, above a fork. The left branch
  holds the five full-path phases in accent boxes, stacked. The right branch holds one box,
  "Shortcut engine", entered from a box `/aid-<verb>`, with a dashed `/aid-triage` box above both
  branches and the note "suggests". Both branches join into `/aid-execute`. Below it, two dashed boxes
  "/aid-deploy (optional)" and "/aid-monitor (optional)". A dashed arrow runs from Monitor back to
  the fork with the note "bugs, change requests". A dashed box "/aid-housekeep (when drifted)" sits
  beside `/aid-discover`, with a dashed arrow into it.
- Text equivalent (`<ol>`):
  1. Set AID up once with `/aid-config`.
  2. On an existing codebase, build the Knowledge Base with `/aid-discover`.
  3. Choose a path. If you are not sure, `/aid-triage` suggests one; it writes nothing.
     - Full path, for broad, new or unclear work: run `/aid-describe`, `/aid-define`,
       `/aid-specify`, `/aid-plan` and `/aid-detail`, in that order. You approve each phase before
       the next one starts.
     - Shortcut path, for one known change: a shortcut such as `/aid-fix` runs the shortcut engine,
       which writes the same plan in one run and stops once for your approval.
  4. Build and review the planned tasks with `/aid-execute`.
  5. Optional: package a release with `/aid-deploy`, and watch production with `/aid-monitor`.
     Monitor sends bugs to `/aid-fix` and change requests to `/aid-triage`.
  6. When the project has drifted, `/aid-housekeep` re-syncs the Knowledge Base.

**D2 — Full path and shortcut path** (`id="two-paths"`, viewBox 400 x 560)
- Sources: `canonical/aid/templates/shortcut-engine.md` § Design Notes (the bullet "Autonomous, non-interactive authoring") and § State
  Machine; `canonical/skills/aid-triage/references/state-suggest.md`.
- desc: "Both paths end at /aid-execute. The full path runs Describe, Define, Specify, Plan and Detail
  as separate phases with your approval after each. The shortcut engine runs CAPTURE, SPEC, PLAN and
  DETAIL in one run, grades every document at GATE, and stops once for your approval."
- caption: "The two ways from an idea to /aid-execute."
- Drawing: two columns under a shared `/aid-triage` box (dashed, "suggests one"). Left column, titled
  "Full path": `/aid-describe` → `/aid-define` → `/aid-specify` → `/aid-plan` → `/aid-detail`, each
  followed by a small "you approve" tick mark. Right column, titled "Shortcut path": CAPTURE → SPEC →
  PLAN → DETAIL → GATE → APPROVAL-HALT. Each row lines up with its full-path counterpart, and both
  columns end in one `/aid-execute` box.
- Text equivalent (`<table>`, header row Step | Full path | Shortcut path):

  | Step | Full path | Shortcut path |
  |---|---|---|
  | Use it for | broad, new or unclear work | one known change |
  | Start with | `/aid-describe` | a shortcut, `/aid-<verb>[-<artifact>]` |
  | Requirements | `/aid-describe`, then `/aid-define` | CAPTURE |
  | Specification | `/aid-specify` | SPEC |
  | Plan | `/aid-plan` | PLAN |
  | Tasks | `/aid-detail` | DETAIL |
  | Quality check | each phase is reviewed and graded | GATE grades every document |
  | Your approval | after every phase | once, at APPROVAL-HALT |
  | Then | `/aid-execute` | `/aid-execute` |

  Below the table: `<p>` "Not sure which path fits? `/aid-triage` suggests one and writes nothing."

**D3 — Propose, discuss, write, review** (`id="review-loop"`, viewBox 400 x 420)
- Sources: `canonical/aid/templates/shortcut-engine.md` § Design Notes, the string
  "the full path's per-phase Propose/Discuss/Write/Review loops"; the text of `concepts/methodology.md` § The Iron Man Model.
- desc: "On the full path each phase runs a four-step loop: the agent proposes, you and the agent
  discuss, the agent writes, and a reviewer grades the result. The loop repeats until the grade
  meets the project's minimum, and then you approve the next phase."
- caption: "The loop inside every full-path phase: the AI does the work, you steer."
- Drawing: four boxes on a ring, clockwise from the top: Propose, Discuss, Write, Review. Solid arrows
  follow the ring. A dashed arrow from Review back to Propose carries the note "grade below minimum".
  A solid arrow leaves Review to a box "You approve the next phase". Each box has one 14-unit
  sub-line saying who acts: "agent", "you and agent", "agent", "reviewer".
- Text equivalent (`<ol>`):
  1. Propose: the agent suggests a solution grounded in the Knowledge Base and the code.
  2. Discuss: you and the agent refine it; you challenge, adjust and decide.
  3. Write: the agent writes the result to a file straight away.
  4. Review: a reviewer grades the result. If the grade is below the project's minimum, the loop
     goes back to step 1.
  5. When the grade is met, you approve, and only then does the next phase start.
- `site/src/assets/3-ironman.png` (224,076 bytes) is deleted in the same change. Nothing else
  references it (`grep -rn 3-ironman site/src` finds only the image line in `methodology.md` § The Iron Man Model: Human-in-the-Middle).

**D4 — What the Knowledge Base holds** (`id="kb-structure"`, viewBox 400 x 440)
- Sources: `canonical/aid/templates/knowledge-base/` (the standard document templates);
  `canonical/aid/templates/project-card.md` (frontmatter `source: hand-authored`); the `knowledge`
  block of `canonical/aid/templates/settings.yml` (`doc_set` "runtime-written by aid-discover");
  `canonical/skills/aid-discover/SKILL.md` (it regenerates `README.md` and `INDEX.md`) and
  `references/agent-prompts.md` (`project-index.md`); `canonical/aid/rules.md` (`STATE.md`).
- desc: "The Knowledge Base is the folder .aid/knowledge/. It holds a project card, the documents
  chosen at discovery, and three meta-documents that index and track them. The generated file
  inventory lives outside it, in .aid/generated/."
- caption: "The parts of the Knowledge Base and who writes each one."
- Drawing: a root box `.aid/knowledge/` at the top, with tree lines to four boxes below it: "Project
  card", "Documents", "Meta-documents", and a dashed "Extensions (optional)". A separate "File
  inventory" box (note "in .aid/generated/") sits below the tree, outside the root's tree lines. A
  dashed arrow labelled "writes" runs from an `/aid-discover` box at the side to Documents,
  Meta-documents and File inventory.
- Text equivalent (`<table>`, header row Part | Files | Written by):

  | Part | Files | Written by |
  |---|---|---|
  | Project card | `PROJECT.md`, optional, read first in every session | you, from the project card template |
  | Documents | one file per topic, such as `architecture.md`, `coding-standards.md` and `test-landscape.md`; the full list is on the Knowledge Base documents page | `/aid-discover`, from the standard templates |
  | Meta-documents | `INDEX.md` (one line per document), `README.md` (completeness), `STATE.md` (grade and open questions) | `/aid-discover`; every phase adds its questions to `STATE.md` |
  | File inventory | `project-index.md`, kept in `.aid/generated/`, outside the knowledge folder | `/aid-discover`, before its writers start |
  | Extensions (optional) | documents only your project needs | added to the document set when you confirm it at discovery |

  "the Knowledge Base documents page" links to `/reference/kb/`.

**D5 — How an agent finds what it needs** (`id="context-loading"`, viewBox 400 x 300)
- Source: `canonical/aid/rules.md` § Summary, the bullet "Read the project card".
- desc: "An agent reads the one-page project card first, opens the Knowledge Base index only to find
  a specific document, and then loads just that document."
- caption: "An agent loads the least context that answers its question."
- Drawing: three stacked boxes joined by downward arrows, widening from top to bottom: `PROJECT.md`
  ("first, if present"), `INDEX.md` ("only to find a document"), "one KB document" ("only the one
  needed").
- Text equivalent (`<ol>`):
  1. The agent reads the project card, `.aid/knowledge/PROJECT.md`, first, when the project has one.
  2. It opens `.aid/knowledge/INDEX.md` only to find a specific document.
  3. It loads that one document, not the whole Knowledge Base.
- This corrects today's diagram, which shows `INDEX.md` as "always loaded" and has no project card.
  The diagram also drops the "exact path:line" tier, because nothing in `canonical/` states it.
  Feature 001 records both in the audit row for `concepts/knowledge-base.mdx`.

**D6 — Agent model tiers** (`id="agent-tiers"`, viewBox 400 x 360)
- Sources: `canonical/aid/templates/agent-dispatch-tiering.md` § The rubric (work classes) and § Rules
  (the bullet "Reviewer tier ≥ executor tier — escalate both together"); `canonical/skills/aid-execute/SKILL.md`
  § Dispatch (the REVIEW and DELIVERY-GATE rows), `references/state-review.md` § Step 1.5: QUICK CHECK
  and `references/state-delivery-gate.md` § Tier Selection.
- What the sources say about reviewer tiers, and why the page words it as below: the tiering rule asks
  that when a task is hard enough to need the large tier, the reviewer of its output takes the large
  tier too. `/aid-execute` applies two different rules of its own. Its per-task quick-check runs the
  reviewer on the small tier, computes no grade and only flags critical and high issues early. The
  graded review of its tasks is the delivery gate, whose reviewer tier is chosen from the delivery's
  complexity score. So the page states the tiering rule as a rule for hard work, and names the
  quick-check as the one deliberate small-tier review; it does not claim that every review runs at or
  above its executor's tier.
- desc: "Each agent runs on a large, medium or small model, chosen by how hard the work is. Most
  work runs on medium. When work is hard enough for the large tier, its reviewer moves to the large
  tier too."
- caption: "The three model tiers and the work each one gets."
- Drawing: three horizontal bands stacked top to bottom, Large, Medium (accent, with the note
  "default"), Small, each with a one-line note of its work. A dashed arrow on the right, from a note
  "hard work" in the Large band to a note "its reviewer" in the same band, reads "same tier". Agent
  names are left out: the roster is generated (Feature 002), and a hand-drawn copy would drift.
- Text equivalent (`<table>`, header row Tier | Work it gets | Examples):

  | Tier | Work it gets | Examples |
  |---|---|---|
  | Large | hard and frontier work | complex reasoning, cross-cutting changes, a full design review, hard architecture |
  | Medium (default) | routine and retrieval-heavy work | a scoped change, a normal document, research, Knowledge Base writing |
  | Small | mechanical work | extracting, formatting, looking things up |

  Below the table, `<p>`: "When work is hard enough for the large tier, the reviewer of that work
  runs on the large tier too. One review is small on purpose: during `/aid-execute`, a quick check
  on the small tier looks at each finished task for serious problems before the graded review of the
  whole delivery. The [agents reference](/reference/agents/) shows each agent's default tier."

**D7 — Feedback loops** (`id="feedback-loops"`, viewBox 480 x 640)
- Source: the loop table in `concepts/methodology.md` § 6, under § The Eleven Loops, after Feature 001's audit
  of that section. The audit row for `concepts/feedback-loops.mdx` records the check.
- desc: "Development runs forward from Discover to Execute, but each phase can send work back to an
  earlier one when it finds a gap. Monitor sends production findings to /aid-fix or /aid-triage, and
  any phase can ask for a targeted re-discovery."
- caption: "Where each feedback loop sends work back to."
- Drawing: the phases in a left column, top to bottom: Discover, Describe and Define, Specify, Plan,
  Detail, Execute, then dashed Deploy and Monitor. `/aid-fix` and `/aid-triage` boxes sit at the
  bottom right. Each loop is one dashed arc on the right side, from its source phase up to its
  target, with a badge `L1` … `L11` on the arc. L11 starts from a dashed bracket spanning every
  phase. Arcs are spaced 16 units apart so that no two badges overlap. Only the badge is drawn: the
  meaning is in the table.
- Text equivalent: the loop table itself (`<table>`, header row Loop | From | To | When). It moves
  out of the page Markdown into this slot, so the facts are written once. The page keeps its prose
  explanation of the loops.

**D8 — AID compared with spec-driven development** (`id="aid-vs-sdd"`, viewBox 400 x 600)
- Sources: `canonical/aid/rules.md` § Workflow; the skill descriptions cited for D1.
- desc: "Spec-driven development goes from a spec straight to AI-written code and a human review.
  AID adds a Knowledge Base that every phase from Discover on reads, separate planning phases,
  reviews that grade each phase, your approval at each phase of the full path, and loops back to
  the phase that caused a problem."
- caption: "Spec-driven development and AID, step by step."
- Drawing: two columns. The left column is titled "Spec-driven development": Write spec → AI writes
  code → Human review → Ship, with a dashed arrow from review back to "Write spec" ("re-spec"). The
  right column is titled "AID (AI Integrated Development)": the D1 phases in one column, with a
  cylinder "Knowledge Base" beside it joined by a short arrow to each phase from `/aid-discover`
  on (the arrow points into the KB at `/aid-discover`, which builds it, and into the phase for the
  others, which read it; `/aid-config` does not touch it).
- Text equivalent (`<table>`, header row Step | Spec-driven development | AID):

  | Step | Spec-driven development | AID |
  |---|---|---|
  | Before the work | nothing | `/aid-config` once; on an existing codebase, `/aid-discover` builds the Knowledge Base |
  | Requirements and spec | one spec, written up front | `/aid-describe`, `/aid-define`, `/aid-specify` |
  | Planning | none | `/aid-plan`, `/aid-detail` |
  | Building | an AI agent writes the code | `/aid-execute` builds and reviews each task |
  | Review | a person reviews the result | a reviewer grades each phase; on the full path you approve each phase before the next |
  | When something is wrong | rewrite the spec | a feedback loop returns to the phase that caused it |
  | Memory between sessions | the spec | the Knowledge Base, built by `/aid-discover` and read by every later phase |
  | After shipping | nothing | optional `/aid-deploy` and `/aid-monitor` |

- Today's diagram titles the AID column "AI-Assisted Development". The product name is "AI
  Integrated Development" (`.aid/knowledge/PROJECT.md`). Feature 001 records the correction.

**D9 — How a release is published** (`id="release-flow"`, viewBox 400 x 520)
- Source: `.github/workflows/release.yml`: the trigger `tags: ['v*']`, and the jobs `gate:`,
  `github-release:` (`needs: [gate]`, runs `release.sh` in its step "Build release artifacts +
  SHA256SUMS + GitHub Release (release.sh)"), `npm-publish:` (`needs: [gate, github-release]`, its
  `if:` on `vars.NPM_ENABLED == 'true'`) and `pypi-publish:` (its `if:` on
  `vars.PYPI_ENABLED == 'true'`).
- desc: "Pushing a version tag starts the release workflow. A gate job re-runs the checks; only if it
  passes does the GitHub Release get built. npm and PyPI publishing follow, each only when its
  repository switch is on."
- caption: "From a pushed tag to published packages."
- Drawing: a top-down chain of boxes. "Maintainer pushes tag v<VERSION>" → "release.yml starts" →
  "gate" → "github-release (release.sh)", then a fork into two dashed boxes "npm-publish (if
  NPM_ENABLED)" and "pypi-publish (if PYPI_ENABLED)".
- Text equivalent (`<ol>`):
  1. The maintainer pushes a version tag: `git push origin v$(cat VERSION)`.
  2. The tag starts the `release.yml` workflow.
  3. The `gate` job re-runs version-sync, render-drift and the test suites on the tagged commit.
     If it fails, nothing is published.
  4. The `github-release` job runs `release.sh`, which builds the release files and creates the
     GitHub Release.
  5. The `npm-publish` job then publishes to npm, only when the repository variable `NPM_ENABLED` is
     `true` and the version is not a pre-release.
  6. The `pypi-publish` job publishes to PyPI, only when the repository variable `PYPI_ENABLED` is
     `true`.

**D10 — The task loop in /aid-execute** (`id="task-loop"`, viewBox 400 x 420)
- Source: `canonical/skills/aid-execute/SKILL.md`, the table under § State Detection and the
  state table under § Dispatch; `references/state-delivery-gate.md`, the opening paragraph under
  `# State: DELIVERY-GATE` ("runs **once per delivery**").
- desc: "Each task is built, then reviewed. If the review lists issues, the task is fixed and
  reviewed again. When every task of a delivery is done, a delivery gate grades the whole delivery."
- caption: "How /aid-execute builds and checks each task."
- Drawing: EXECUTE → REVIEW → DONE in a column, a FIX box to the right of REVIEW with arrows REVIEW →
  FIX ("issues found") and FIX → REVIEW. Below DONE, "DELIVERY-GATE (after all tasks)", with a dashed
  arrow back to FIX labelled "grade below minimum".
- Text equivalent (`<ol>`):
  1. EXECUTE: the agent for the task's type does the work.
  2. REVIEW: a reviewer checks the result.
  3. FIX: if the review lists issues, they are fixed and the task goes back to REVIEW.
  4. DONE: the task is complete.
  5. DELIVERY-GATE: when every task of the delivery is done, a reviewer grades the whole delivery.
     Below the minimum grade, the work goes back to FIX.

##### Feature Flow

Everything happens at build time. No diagram runs code in the browser.

1. A host page (`.mdx`) imports a diagram component, for example
   `import Pipeline from '../../../components/diagrams/Pipeline.astro';` from a page under
   `concepts/`, or `'../../components/diagrams/Pipeline.astro'` from `index.mdx`. It renders
   `<Pipeline />` where the old fence or image was.
2. The diagram component (`Pipeline.astro`) renders `<Diagram>` with its `id`, `title`, `desc`,
   `caption`, `width` and `height`. Its SVG shapes go in the default slot and its text equivalent in
   `slot="text"`.
3. `Diagram.astro` checks its props and fails the build on a bad one (see Layers & Components).
   It then writes the `<figure>` markup, with the shapes inside the `<svg>` and the text equivalent
   after it.
4. `astro build` writes static HTML. Colours are CSS custom properties, so the SVG follows the light
   or dark theme with no script. The browser repaints when Starlight's theme select changes
   `data-theme`.
5. Feature 004's page check (FR-8 group d) reads `site/dist/**/*.html` and enforces the markup
   contract under UI Specs. Feature 005's link test (group b) checks the links in the text
   equivalents.

Removal of Mermaid, in this feature's change. This feature is the only owner of these
`astro.config.mjs` edits; Feature 005 does not touch these lines. Once the last hand-written fence is
replaced:
- `site/astro.config.mjs`: delete `import mermaid from 'astro-mermaid';`, the whole `mermaid({...})`
  entry in `integrations`, the `head` entry whose `attrs` is `{ 'data-aid': 'mermaid-source-cache' }`,
  and every comment line that describes them (the integration-order note at the top of the file, the
  comments inside and above the `mermaid({...})` entry, and the KI-018 comment above `head`).
  Delete `import { readFileSync } from 'node:fs';` too: the `head` entry's `content: readFileSync(...)`
  is its only use today. Feature 005 adds that import back for its `VERSION` read (its Feature Flow
  step 2), which lands after this feature.
- Not here: Feature 005 deletes `site/src/scripts/mermaid-source-cache.js` and removes `astro-mermaid`
  and `@mermaid-js/layout-elk` from `site/package.json` and the lockfile (FR-11). Feature 004 drops
  the `.mermaid` rules from `site/src/styles/casulo.css` (the blocks under the comments "Mermaid / diagram
  horizontal scroll" and "Mermaid edge legibility, per theme") when it rewrites the
  styles. The build order (003 before 005) keeps the build green: the config stops reading the file
  before the file is deleted.

Verification for this feature (from the repo root):

| Check | Expected |
|---|---|
| `grep -rln '^```mermaid' site/src/content/docs --include='*.md*' \| grep -v '/skills/'` | prints nothing (skill pages: Feature 002) |
| `grep -n 'mermaid' site/astro.config.mjs` | prints nothing |
| `grep -rn '3-ironman' site/src` and `test -e site/src/assets/3-ironman.png` | grep prints nothing; `test` exits 1 |
| `cd site && npm run build` | exits 0 |
| `grep -o '<figure class="diagram' site/dist/<page>/index.html \| wc -l`, for each host | `index.html` 1; `concepts/pipeline` 2; `concepts/methodology` 1; `concepts/knowledge-base` 2; `concepts/agents` 1; `concepts/feedback-loops` 1; `concepts/aid-and-sdd` 1; `guides/maintainer` 1; `guides/pipeline` 1. Total 11 |
| `wc -l site/src/components/Diagram.astro site/src/components/diagrams/*.astro` | total at most 1,500 lines (this feature's share of the AC-4 budget) |

##### Layers & Components

Files this feature adds or changes (all under `site/`):

| File | Change |
|---|---|
| `src/components/Diagram.astro` | new, at most 110 lines |
| `src/components/diagrams/{Pipeline,TwoPaths,ReviewLoop,KbStructure,ContextLoading,AgentTiers,FeedbackLoops,AidVsSdd,ReleaseFlow,TaskLoop}.astro` | new, one per diagram, each at most 150 lines (`FeedbackLoops.astro` at most 200) |
| the host pages in the Data Model table | fence or image replaced by the import and the component (the `.mdx` files exist after Feature 001's split) |
| `src/assets/3-ironman.png` | deleted |
| `astro.config.mjs` | Mermaid integration and source-cache `head` entry removed (Feature Flow) |

**`Diagram.astro`.** The props are a contract: every diagram file passes all six.

```astro
---
/**
 * Diagram: one static, accessible diagram (FR-3). No JavaScript.
 * Default slot: SVG shapes in a `width` x `height` viewBox. Slot "text": the text
 * equivalent, an <ol> or a <table>, optionally followed by a <p>.
 * Colours come from Starlight's theme variables, so both themes work.
 */
interface Props {
  id: string;      // kebab-case, unique on the page; prefixes every element id
  title: string;   // short name -> <title>
  desc: string;    // one to three sentences on what the diagram shows -> <desc>
  caption: string; // visible caption -> <figcaption>
  width: number;   // viewBox width in user units, at most 480
  height: number;  // viewBox height in user units
}
const { id, title, desc, caption, width, height } = Astro.props;
if (!/^[a-z][a-z0-9-]*$/.test(id)) throw new Error(`Diagram: bad id "${id}"`);
if (!(width > 0 && width <= 480 && height > 0)) throw new Error(`Diagram ${id}: bad size`);
if (!title.trim() || !desc.trim() || !caption.trim()) throw new Error(`Diagram ${id}: empty text`);
if (!Astro.slots.has('text')) throw new Error(`Diagram ${id}: no text equivalent`);
const titleId = `dg-${id}-title`;
const descId = `dg-${id}-desc`;
---
<figure class="diagram" id={`dg-${id}`}>
  <figcaption>{caption}</figcaption>
  <svg role="img" aria-labelledby={titleId} aria-describedby={descId}
       viewBox={`0 0 ${width} ${height}`} width={width} height={height}
       data-pagefind-ignore>
    <title id={titleId}>{title}</title>
    <desc id={descId}>{desc}</desc>
    <defs>
      <marker id={`dg-${id}-arrow`} viewBox="0 0 10 10" refX="9" refY="5"
              markerWidth="8" markerHeight="8" orient="auto-start-reverse">
        <path d="M0 0 L10 5 L0 10 z" class="dg-arrowhead" />
      </marker>
    </defs>
    <slot />
  </svg>
  <div class="diagram-text">
    <p class="diagram-text-lead">The same information as text:</p>
    <slot name="text" />
  </div>
</figure>
<style>/* below */</style>
```

`data-pagefind-ignore` keeps the SVG labels out of the search index, because the text equivalent
already carries them and would otherwise give double hits.

**Style** (in the component's `<style>`). Slotted shapes are compiled with the diagram file's scope,
not with `Diagram.astro`'s, so the rules that target them use `:global()` under `.diagram`.

```css
.diagram {
  --dg-ink: var(--sl-color-white);         /* labels */
  --dg-muted: var(--sl-color-gray-2);      /* notes, edge labels, lead line */
  --dg-line: var(--sl-color-gray-3);       /* edges, outlines, arrowheads */
  --dg-surface: var(--sl-color-gray-6);    /* node fill */
  --dg-accent-surface: var(--sl-color-accent-low);
  --dg-accent-line: var(--sl-color-accent);
  --dg-bg: var(--sl-color-bg);
  margin-block: 1.5rem;
}
.diagram figcaption { font-weight: 600; color: var(--dg-ink); margin-block-end: 0.5rem; }
.diagram svg { display: block; max-inline-size: 100%; block-size: auto; }
.diagram :global(text) { font-family: var(--sl-font); fill: var(--dg-ink); }
.diagram :global(.dg-label) { font-size: 16px; }
.diagram :global(.dg-note) { font-size: 14px; fill: var(--dg-muted); }
.diagram :global(.dg-node) { fill: var(--dg-surface); stroke: var(--dg-line); stroke-width: 1.5; }
.diagram :global(.dg-accent) { fill: var(--dg-accent-surface); stroke: var(--dg-accent-line); }
.diagram :global(.dg-optional) { fill: var(--dg-bg); stroke-dasharray: 6 4; }
.diagram :global(.dg-group) { fill: none; stroke: var(--dg-line); stroke-width: 1; }
.diagram :global(.dg-edge) { fill: none; stroke: var(--dg-line); stroke-width: 2; }
.diagram :global(.dg-edge.dg-optional) { stroke-dasharray: 6 4; }
.diagram :global(.dg-label-bg) { fill: var(--dg-bg); }
.diagram :global(.dg-arrowhead) { fill: var(--dg-line); }
.diagram-text { border-inline-start: 3px solid var(--dg-accent-line); padding-inline-start: 1rem; }
.diagram-text-lead { color: var(--dg-muted); font-size: var(--sl-text-sm); }
@media (forced-colors: active) {
  .diagram :global(.dg-node), .diagram :global(.dg-edge), .diagram :global(.dg-group) { stroke: CanvasText; }
  .diagram :global(.dg-node), .diagram :global(.dg-label-bg) { fill: Canvas; }
  .diagram :global(text), .diagram :global(.dg-arrowhead) { fill: CanvasText; }
}
```

The diagrams reference only Starlight's theme variables. Feature 004 sets those variables from its
design tokens in its one token file, so the diagrams follow any token change and need no colour of
their own. There is no colour literal in any diagram file; Feature 004's check K4 fails one.

**Diagram file pattern** (`ContextLoading.astro`, abridged). The other nine follow the same shape.

```astro
---
import Diagram from '../Diagram.astro';
const id = 'context-loading';
const arrow = `url(#dg-${id}-arrow)`;
---
<Diagram id={id} width={400} height={300}
  title="How an agent finds what it needs"
  desc="An agent reads the one-page project card first, opens the Knowledge Base index only to find a specific document, and then loads just that document."
  caption="An agent loads the least context that answers its question.">
  <rect class="dg-node dg-accent" x="120" y="16" width="160" height="56" rx="6" />
  <text class="dg-label" x="200" y="40" text-anchor="middle">PROJECT.md</text>
  <text class="dg-note" x="200" y="60" text-anchor="middle">always, first</text>
  <path class="dg-edge" d="M200 72 V108" marker-end={arrow} />
  <!-- INDEX.md box, edge, "one KB document" box -->
  <ol slot="text">
    <li>The agent reads the project card, <code>.aid/knowledge/PROJECT.md</code>, first, when the project has one.</li>
    <li>It opens <code>.aid/knowledge/INDEX.md</code> only to find a specific document.</li>
    <li>It loads that one document, not the whole Knowledge Base.</li>
  </ol>
</Diagram>
```

**Drawing rules** (all ten files):
- Coordinates sit on an 8-unit grid. Boxes use `rx="6"`. Edges are `<path>` or `<line>` with
  `marker-end={arrow}`, and they never cross a label.
- Labels are `<text>`, with `<tspan x=… dy="1.25em">` for a second line. A box holds at most two
  lines. Plan for about 9 units per character at 16 px, so a 160-unit box takes about 16 characters
  per line.
- An edge label sits on a `rect.dg-label-bg` drawn just before it, so that the line under it does
  not cut through the text.
- Optional steps use `.dg-optional` (dashed) **and** the word "optional" or "(if …)" in the label.
  The accent fill is only emphasis. No meaning depends on colour alone (WCAG 1.4.1).
- Allowed SVG elements: `g`, `rect`, `circle`, `ellipse`, `path`, `line`, `polyline`, `polygon`,
  `text`, `tspan`, `defs`, `marker`, `title`, `desc`. No `<a>`, `<foreignObject>`, `<image>`, `<script>`, `<style>`,
  `<animate>`, and no `style`, `fill`, `stroke` or `color` attribute: colour comes only from the
  `.diagram` classes. Nothing inside the SVG can take focus, so a keyboard user tabs straight past it
  into the text equivalent's links. U6 and U7 (UI Specs) check this in the built HTML.
- Text equivalents are plain HTML: `<code>` for commands and file names, and `<a href="/…/">` with
  link text that names the destination (Feature 001's rule P7). Commands are written exactly as the
  SKILL.md `argument-hint` defines them.

Boundaries with other features:
- Feature 001 owns the words around a diagram, the page split, the redirects and the audit rows.
  The diagram's own words are specified here, and Feature 001's audit checks them.
- Feature 002 owns the skill pages; they carry no diagram.
- Feature 004 owns the tokens and the page check that enforces the markup contract below; this
  feature owns the contract.
- Feature 005 owns deleting files and dependencies (Feature Flow).

##### UI Specs

**Markup contract** (what the built HTML must hold; Feature 004's FR-8(d) test asserts each line on
every page in `site/dist/**/*.html` except redirect pages, inside `main`):

| # | Assertion | Proves |
|---|---|---|
| U1 | `figure.diagram` count equals the count of `figure.diagram > .diagram-text` that contain at least one `ol` or `table` with at least 2 `li` or body `tr` | AC-8 "counts match" |
| U2 | each `figure.diagram` has exactly one child `figcaption` with non-empty text, and exactly one child `svg[role="img"]` | FR-3 visible caption |
| U3 | that SVG's `aria-labelledby` names the id of a non-empty `title` that is a child of the SVG; its `aria-describedby` names the id of a non-empty `desc` child | FR-3 title and description, AC-8 |
| U4 | every `svg` inside `main` that is not in a `figure.diagram` has `aria-hidden="true"` or an `aria-label` (an icon, not a diagram) | no diagram escapes U1-U3 |
| U5 | no element in the page has class `mermaid`, and none has `data-language="mermaid"` | Mermaid gone |
| U6 | no `figure.diagram` contains a `script` or an element with `tabindex`, and no `figure.diagram svg` has a descendant `a` or `foreignObject`. Links inside `.diagram-text` are allowed (D4 and D6 have them) | FR-3 "no JavaScript"; nothing in the drawing is focusable |
| U7 | every element inside `figure.diagram svg` has a local name in the allowed list of the drawing rules (`g`, `rect`, `circle`, `ellipse`, `path`, `line`, `polyline`, `polygon`, `text`, `tspan`, `defs`, `marker`, `title`, `desc`), and none has a `style`, `fill`, `stroke` or `color` attribute | the drawing rules; colours come only from the `.diagram` classes, so both themes work |

Feature 005 fixes the test file name. Duplicate ids (the `dg-<id>-…` ids in a diagram, or one that
clashes with a heading id) are caught by Feature 004's structure check S9; its axe-core run selects
only `duplicate-id-aria`, which sees an id only when an ARIA attribute references it. The axe run
covers `svg-img-alt`.
Contrast is not checked by axe here (jsdom has no layout, so Feature 004 switches `color-contrast`
off); the pairs under Accessibility are checked by Feature 004's contrast test K3. The source files
are checked too: Feature 004's K4 fails any colour literal anywhere in `src/components/Diagram.astro`
or `src/components/diagrams/*.astro`.

**Layout and responsive behaviour.**
- Order inside the figure: caption, drawing, text equivalent. The text equivalent is always visible:
  no `<details>`, no toggle, no `hidden`. It sits directly below the drawing at every width, because
  Starlight's content column (about 45rem) is too narrow for side-by-side.
- The SVG renders at its natural size (`width` attribute) and only scales down
  (`max-inline-size: 100%`, `block-size: auto`), so the page never scrolls sideways (AC-11). At 320 px
  the content column is about 296 px wide (Feature 004's narrow-screen padding of 0.75rem each side).
  A 400-unit diagram (all but D7) scales to 0.74: 16-unit labels show at about 12 px and 14-unit notes
  at about 10 px. D7, the one 480-unit diagram, scales to 0.62: labels at about 10 px, notes and its
  `L1` … `L11` badges at about 9 px. So at 320 px the drawing is an overview, not the place to read
  details, and this is by design, not a defect: under WCAG 1.4.10 the drawing is content that needs a
  two-dimensional layout, and the always-visible text equivalent directly below it carries every fact at
  body size and reflows. Browser zoom enlarges the drawing too. No rule of this spec depends on the
  drawing's labels being readable at 320 px.
- No animation and no transition, so `prefers-reduced-motion` needs no rule.

**Accessibility.**
- Screen readers announce the figure by its caption, then the SVG as one image named by `<title>`
  and described by `<desc>`. The SVG's inner `<text>` is not read, because `role="img"` makes the
  children presentational. They then reach the text equivalent as an ordinary list or table, which
  can be navigated item by item and cell by cell. No information is read twice, and none exists only
  in the drawing.
- Tables in text equivalents have a header row (`<th scope="col">`). The first column's cells use
  `<th scope="row">`.
- Element ids are prefixed `dg-<id>-`, and each diagram appears at most once per page, so ids stay
  unique. A future second use on one page needs a second `id` prop value. Feature 004's check S9
  fails any page with a duplicated id.
- Colour contrast. These pairs must hold in both themes. Feature 004's contrast test computes them
  from the token values it maps onto these Starlight variables:

  | Foreground | Background | Minimum | Used for |
  |---|---|---|---|
  | `--sl-color-white` | `--sl-color-bg` | 4.5:1 | labels and caption on the page |
  | `--sl-color-white` | `--sl-color-gray-6` | 4.5:1 | labels in a neutral box |
  | `--sl-color-white` | `--sl-color-accent-low` | 4.5:1 | labels in an accent box |
  | `--sl-color-gray-2` | `--sl-color-bg` | 4.5:1 | notes, edge labels, the lead line |
  | `--sl-color-gray-2` | `--sl-color-gray-6` | 4.5:1 | sub-lines inside a neutral box |
  | `--sl-color-gray-2` | `--sl-color-accent-low` | 4.5:1 | sub-lines and notes inside an accent box (D1, D3, D5) |
  | `--sl-color-gray-3` | `--sl-color-bg` | 3:1 | edges, outlines, arrowheads (WCAG 1.4.11) |
  | `--sl-color-accent` | `--sl-color-bg` | 3:1 | accent box outline, text-equivalent rule |

- Windows high-contrast mode: the `forced-colors` block draws every shape in system colours.
- Keyboard: nothing in a diagram's drawing is focusable (U6). The links in a text equivalent follow the
  page's normal tab order and use Feature 004's focus ring.

### Feature 004 — New Look and Accessible Layout

- **Priority:** Must
- **Requirements:** §5 FR-4, FR-5
- **Criteria:** AC-7, AC-9, AC-10, AC-11, AC-15

#### Description

A new visual design: type scale, spacing, colour tokens, light and dark themes with a manual toggle, responsive from 320 px. The layout supports keyboard and screen-reader use: skip link, heading order, landmarks, visible focus, clear link text and reduced motion. This feature also adds the accessibility and structure check on built pages (FR-8 group d) that proves AC-7 and AC-10, and keeps pages light (no extra scripts, at most 150 KB each).

#### User Stories

- As a keyboard-only user, I want a skip link, a logical tab order and a visible focus ring, so that I can use every control.
- As a screen-reader user, I want proper headings and landmarks on every page, so that I can navigate by structure.
- As any reader, I want a clean, modern, readable layout in light or dark, so that reading the docs is comfortable on any device.

#### Technical Specification

##### Data Model

No database. This feature owns one token file, one stylesheet, one component override and two test
files. Their data shapes follow.

**1. Design tokens: `site/src/styles/tokens.css`** (new; the only file under `site/src/styles/` and
`site/src/components/` that holds a colour value, which check K4 enforces). One file elsewhere in `site/` holds
colours by design: `public/favicon.svg` keeps its two brand colours (`#0a0e1a`, `#d4a853`) as SVG `fill`
attributes, because the browser loads a favicon outside the page, where CSS variables do not reach. Feature 005
keeps it unchanged and it is not tokenised. Page content generated from `canonical/` is not a style file and
is out of K4's reach too.
It has exactly two rule blocks, each with one declaration per line, in the form
`  --aid-color-<name>: #rrggbb;` (lower-case, 6-digit hex; no `rgb()`, `hsl()`, alpha or named colour, so
the contrast test can read every value):

- `:root { ... }` holds the dark-theme colours, every non-colour token, and the Starlight mapping below.
- `:root[data-theme='light'] { ... }` holds the light-theme colours, and nothing else.

Both blocks are unlayered, so they beat Starlight's `@layer starlight.base` palette in both themes, and the
mapping, written once in `:root`, resolves against whichever `--aid-color-*` value wins on `html`. Dark is the
`:root` default because Starlight's `Page.astro` writes `data-theme="dark"` into the HTML until its theme
script runs.

Colour tokens. The values were checked at Specify with the WCAG formula that the contrast test uses (ratios
below, under 2):

| Token `--aid-color-` | Dark | Light | Role |
|---|---|---|---|
| `bg` | `#0a0e1a` | `#ffffff` | page background |
| `nav` | `#111827` | `#f8fafc` | header, sidebar, mobile menu |
| `surface` | `#1a2035` | `#f1f5f9` | inline code, table header row, cards, diagram boxes |
| `text` | `#e2e8f0` | `#1e293b` | body text |
| `text-strong` | `#f8fafc` | `#0f172a` | headings, strong text, labels |
| `text-muted` | `#a3b1c6` | `#475569` | secondary text: group labels, captions, footer |
| `accent` | `#d4a853` | `#7a5814` | links, the current-page marker, brand gold |
| `accent-strong` | `#e6bc6a` | `#5c420f` | link hover |
| `accent-soft` | `#2b2414` | `#f7efdc` | tinted backgrounds (version badge, accent diagram box) |
| `on-accent` | `#0a0e1a` | `#ffffff` | text on an `accent` background (skip link, current sidebar item, primary button) |
| `border` | `#2d3748` | `#e2e8f0` | hairlines and dividers (decorative) |
| `border-strong` | `#718096` | `#64748b` | borders that identify a control: inputs, select, search button (WCAG 1.4.11) |
| `focus` | `#e6bc6a` | `#7a5814` | the focus ring |
| `note`, `note-bg` | `#93c5fd`, `#172554` | `#1e40af`, `#eff6ff` | "note" aside title and links, its background |
| `tip`, `tip-bg` | `#d8b4fe`, `#2e1065` | `#6b21a8`, `#faf5ff` | "tip" aside |
| `caution`, `caution-bg` | `#fcd34d`, `#3b2a06` | `#92400e`, `#fffbeb` | "caution" aside |
| `danger`, `danger-bg` | `#fca5a5`, `#450a0a` | `#991b1b`, `#fef2f2` | "danger" aside, invalid form field |

Non-colour tokens (in `:root` only):

| Group | Tokens |
|---|---|
| Type scale (ratio about 1.25 from a 16 px body) | `--aid-text-xs: 0.8125rem` (13 px, the smallest text on the site), `--aid-text-sm: 0.875rem`, `--aid-text-base: 1rem`, `--aid-text-lg: 1.125rem`, `--aid-text-xl: 1.375rem`, `--aid-text-2xl: 1.75rem`, `--aid-text-3xl: 2.25rem`; `--aid-leading-body: 1.7`, `--aid-leading-heading: 1.25` |
| Spacing | `--aid-space-1: 0.25rem`, `-2: 0.5rem`, `-3: 0.75rem`, `-4: 1rem`, `-5: 1.5rem`, `-6: 2rem`, `-7: 3rem` |
| Radius | `--aid-radius-sm: 0.25rem`, `--aid-radius-md: 0.5rem`, `--aid-radius-lg: 0.75rem` |
| Focus | `--aid-focus-width: 3px`, `--aid-focus-offset: 2px` |
| Layout | `--aid-content-width: 46rem` |

No web font: the site uses Starlight's system font stacks (`--sl-font-system`, `--sl-font-system-mono`), so a
page downloads no font file (NFR-2).

Starlight mapping (in `:root`; each value is `var(--aid-...)` and nothing else):

| Starlight variable | Token |
|---|---|
| `--sl-color-bg`, `--sl-color-black` | `bg` |
| `--sl-color-bg-nav`, `--sl-color-bg-sidebar`, `--sl-color-gray-7` | `nav` |
| `--sl-color-bg-inline-code`, `--sl-color-gray-6` | `surface` |
| `--sl-color-text`, `--sl-color-gray-2` | `text` |
| `--sl-color-white`, `--sl-color-gray-1` | `text-strong` |
| `--sl-color-gray-3` | `text-muted` |
| `--sl-color-gray-4` | `border-strong` |
| `--sl-color-gray-5`, `--sl-color-hairline`, `--sl-color-hairline-light`, `--sl-color-hairline-shade` | `border` |
| `--sl-color-accent`, `--sl-color-text-accent`, `--sl-color-bg-accent` | `accent` |
| `--sl-color-accent-high` | `accent-strong` |
| `--sl-color-accent-low` | `accent-soft` |
| `--sl-color-text-invert` | `on-accent` |
| `--sl-color-blue`, `--sl-color-blue-high` / `--sl-color-blue-low` | `note` / `note-bg` (same for `purple` and `tip`, `orange` and `caution`, `red` and `danger`) |
| `--sl-text-h1` ... `--sl-text-h5` | `--aid-text-3xl`, `-2xl`, `-xl`, `-lg`, `-base` |
| `--sl-text-xs`, `--sl-text-2xs` | `--aid-text-sm`, `--aid-text-xs` |
| `--sl-line-height`, `--sl-line-height-headings` | `--aid-leading-body`, `--aid-leading-heading` |
| `--sl-content-width` | `--aid-content-width` |

Feature 003's diagrams use only Starlight variables (its `.diagram` style block), so they follow these tokens
with no colour of their own.

**2. Contrast pairs** (the `PAIRS` constant of the contrast test). A side is a token name or a Starlight
variable; a Starlight variable is resolved through the mapping above. Each pair is checked in both themes.

| Foreground | Background | Minimum | Used for | Dark / light at Specify |
|---|---|---|---|---|
| `text` | `bg`, `nav`, `surface` | 4.5 | body text, sidebar text, text in a table header or card | 15.62 / 14.63 lowest pair 13.08 / 13.35 |
| `text-strong` | `bg`, `surface`, `accent-soft` | 4.5 | headings, diagram labels | 18.40 / 17.85 lowest 14.70 / 15.59 |
| `text-muted` | `bg`, `nav`, `surface` | 4.5 | group labels, captions, footer | 8.86 / 7.58 lowest 7.42 / 6.92 |
| `accent` | `bg`, `nav`, `surface`, `accent-soft` | 4.5 | links | 8.73 / 6.49 lowest 6.98 / 5.67 |
| `accent-strong` | `bg` | 4.5 | link hover | 10.79 / 9.37 |
| `on-accent` | `accent` | 4.5 | skip link, current sidebar item | 8.73 / 6.49 |
| `border-strong` | `bg`, `nav`, `surface` | 3 | control borders (WCAG 1.4.11) | 4.80 / 4.76 lowest 4.02 / 4.34 |
| `focus` | `bg`, `nav`, `surface` | 3 | focus ring (WCAG 2.4.7, 1.4.11) | 10.79 / 6.49 lowest 9.04 / 5.93 |
| `note`, `tip`, `caution`, `danger` | its own `-bg` | 4.5 | aside titles and links | lowest 8.15 / 6.84 |
| `text-strong` | `note-bg`, `tip-bg`, `caution-bg`, `danger-bg` | 4.5 | aside body text (Starlight sets it to `--sl-color-white`) | lowest 13.21 / 16.32 |
| the eight pairs of Feature 003's UI Specs, Accessibility, in its Starlight variable names | | as stated there | diagram labels, notes, edges | all pass with the values above (the lowest text pair, `--sl-color-gray-2` on `--sl-color-accent-low`, is 12.48 / 12.77) |

Syntax colours inside code blocks are not tokens: Expressive Code raises every token colour to at least
5.5:1 against its block background (`minSyntaxHighlightingColorContrast`, default 5.5, in
`@expressive-code/core`), and this feature keeps that default.

**3. Page check records** (in-memory, in `tests/a11y.test.mjs`). Each check returns `string[]` problems, one
per finding, in the form `<check id> <detail>` (for example `S2 found 2 h1`). A page passes when the
concatenated list is empty. Pages come from Feature 005's `builtPages()` (`tests/dist.mjs`); a page with a
non-null `redirectTo` is skipped, as Feature 001 requires.

```js
/** Script purposes for AC-15 and NFR-2. A script is classified by the markers its text contains
 *  (inline content, or the file under dist/ that its src names). Minified code keeps string literals. */
const PURPOSES = {
  search:     ['site-search', 'data-open-modal', 'pagefind'],
  theme:      ['starlight-theme-select', 'StarlightThemeProvider', 'starlight-theme'],
  navigation: ['starlight-menu-button', 'starlight-toc', 'mobile-starlight-toc',
               'sl-sidebar-state', 'sl-sidebar-restore', '_starlightScrollRestore'],
};
/** Markers that fail a script even when it also carries an allowed marker. */
const FORBIDDEN = ['starlight-tabs', 'mermaid', '.expressive-code .copy', 'aid-banner',
                   'aid-flow-data', 'rf-submit'];
const BANNED_LINK_TEXT = ['here', 'click here', 'read more', 'more', 'link', 'this', 'this page'];
const LIMIT = 150 * 1024;   // bytes; AC-15 and NFR-2
```

##### Feature Flow

1. **Build.** `astro build` loads `customCss` in order `tokens.css`, then `site.css`. Starlight renders every
   page with its own components except `Header` (this feature's override) and `Footer` (Feature 005's
   rewrite). Expressive Code renders code blocks without a copy button, so it ships no script.
2. **First paint.** Starlight's inline `ThemeProvider` script reads `localStorage['starlight-theme']`; when it
   is empty ("Auto"), it reads `matchMedia('(prefers-color-scheme: light)')` and sets `html[data-theme]`
   before the body paints. The tokens switch with that attribute. Without JavaScript the page stays dark
   (Starlight's server default); both themes meet NFR-1, so nothing is lost but the system match.
3. **Theme change.** The reader picks Dark, Light or Auto in Starlight's theme select (a native `<select>`
   named "Select theme"). Its module script stores the choice and resets `data-theme`; in Auto it also
   follows a later system change.
4. **Keyboard.** Tab from the top: "Skip to content" (Starlight's `SkipLink`, visible on focus, target
   `#_top`, the `h1`), then the header in visual order, then the sidebar, the "On this page" list, the
   content, and the footer (UI Specs, Accessibility, has the exact sequence). Every stop shows the focus ring.
5. **Check.** `npm test` runs `npm run build && vitest run` (Feature 005's `scripts` block). Vitest runs
   `tests/a11y.test.mjs`: the self-tests T1 to T11 first, then one test per built page. Each page is parsed
   once with jsdom (scripts not run, so the page is checked as a no-JavaScript reader gets it) and goes
   through the structure checks S1 to S9, Feature 003's diagram checks U1 to U7, the script checks W3 and
   W4, the weight checks W1 and W2, and axe-core (A1). A final test asserts the AC-8 total and prints the
   AC-15 script list. `tests/contrast.test.mjs` runs K1 to K5 on `src/styles/tokens.css` and on the
   component styles.

##### Layers & Components

All paths are under `site/` unless stated.

| File | Change | Budget |
|---|---|---|
| `src/styles/tokens.css` | new (Data Model 1) | at most 135 lines: 109 declarations (21 colour tokens in each block, 22 non-colour tokens, 45 mapping lines), 4 brace lines, and at most 22 lines of comments and blank lines |
| `src/styles/site.css` | new: the rules listed under UI Specs | at most 130 lines |
| `src/styles/casulo.css`, `src/styles/shell.css` | deleted; nothing in them survives except what `site.css` restates with tokens (Migration Plan) | -657 lines |
| `src/components/overrides/Header.astro` | rewritten (below) | at most 60 lines with its `<style>` |
| `src/components/overrides/PageTitle.astro` | deleted: Starlight's own `PageTitle` renders the `h1`; the breadcrumb and eyebrow repeated the sidebar | -51 lines |
| `astro.config.mjs` | `customCss`, `components`, `social` and a new `expressiveCode` key (below) | |
| `src/content/docs/index.mdx`, `reference/cli.mdx`, `guides/maintainer.mdx`, `guides/installation.mdx`, and the unused `Tabs, TabItem` import in `guides/pipeline.mdx` | every `<Tabs>` becomes plain sections (below) | |
| `package.json`, `package-lock.json` | not edited here. This feature needs `axe-core` and `jsdom` at exact versions and stops importing `@fontsource/inter`; Feature 005 owns the file, and its Data Model 1 block and Feature Flow step 6 add the two and remove the third. That step needs this feature's `casulo.css` replacement first, so Plan orders: this feature's styles, then Feature 005's step 6, then this feature's tests | |
| `tests/a11y.test.mjs`, `tests/contrast.test.mjs` | new (FR-8 group d; names fixed by Feature 005) | at most 250 and 90 lines |

**`astro.config.mjs`** (only these keys; the others belong to Features 001, 002, 003 and 005):

```js
customCss: ['./src/styles/tokens.css', './src/styles/site.css'],
social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/AndreVianna/aid-methodology' }],
expressiveCode: { frames: { showCopyToClipboardButton: false } },
components: {
  Header: './src/components/overrides/Header.astro',
  Footer: './src/components/Footer.astro',
},
```

The Casulo AI Labs entry leaves `social` because the header logo already links to casuloailabs.com. The copy
button goes because its script is none of the three kinds NFR-2 allows; a command stays copyable by
selection. `PageTitle` leaves the map here; `Banner` and `Head` leave it in Feature 005's change.

**`Header.astro`.** Why an override is kept at all: Starlight's own header puts search before the links and
the theme select, and it shows the full site title, which is clipped at 320 px. This one keeps every
Starlight part and only changes order and the brand:

```astro
---
// Header override: Starlight's header parts in the order of AC-9, with a brand that fits 320 px.
import Search from '@astrojs/starlight/components/Search.astro';
import SocialIcons from '@astrojs/starlight/components/SocialIcons.astro';
import ThemeSelect from '@astrojs/starlight/components/ThemeSelect.astro';
import logo from '../../assets/casulo-ai-labs.png';
---
<div class="aid-header">
  <a class="aid-logo" href="https://casuloailabs.com">
    <img src={logo.src} width={logo.width} height={logo.height} alt="Casulo AI Labs" />
  </a>
  <a class="aid-brand" href="/">AID<span class="aid-brand-long"> AI Integrated Development</span></a>
  <div class="aid-header-end">
    <div class="sl-hidden md:sl-flex aid-prefs print:hidden"><SocialIcons /><ThemeSelect /></div>
    <div class="print:hidden"><Search /></div>
  </div>
</div>
<style>/* flex row; logo 30px high; .aid-brand-long hidden below 50rem; tokens only */</style>
```

The logo link carries no `target="_blank"`. Below 50rem the social links and the theme select are hidden in
the header and appear in the mobile menu (Starlight's `MobileMenuFooter`), as in Starlight's own header.

**Tabs.** Starlight's `Tabs` ship a script (`starlight-tabs`) and, without it, hide every panel but the first
(its `rehype-tabs` sets `hidden` at build time), so they break NFR-2 and hide content from a no-JavaScript
reader. Each `<TabItem label="X">` becomes a heading `X` one level below the section that holds the tabs,
followed by its content unchanged; the `Tabs, TabItem` import is removed. Feature 001's rewrite of the same
pages keeps this shape. Check S8 fails any page that still has a tab list.

**`tests/a11y.test.mjs`** imports `JSDOM` and `VirtualConsole` from `jsdom`, `axe` from `axe-core`, and
`builtPages`, `DIST`, `SITE` from `./dist.mjs`. It runs in Vitest's `node` environment and builds each DOM
itself, so it needs no environment docblock.

*Why jsdom.* axe-core supports jsdom and documents it; the lighter DOMs (linkedom, happy-dom) are not
supported targets and lack parts of the DOM API axe calls. jsdom cannot lay out or cascade CSS, so the
`color-contrast` rule is switched off here and replaced by the contrast test; rules that need layout
(`target-size`, `scrollable-region-focusable`) come back as "incomplete", never as false violations.

Per page (`it.each(pages)`, one test per page, problems joined into one message):

| Id | Check |
|---|---|
| S1 | `html` has `lang="en"` |
| S2 | exactly one `h1` in the document, and it is inside `main` |
| S3 | exactly one `main`, and no other element has `role="main"` |
| S4 | inside `main`, the first heading is the `h1`, and each later heading's level is at most the previous level plus one |
| S5 | the first `a[href]` in `body` has `href="#_top"`, and `#_top` is the `h1` (skip link) |
| S6 | exactly one `header` outside `main`, `aside`, `nav`, `article` and `section` (the banner landmark); every `nav` has an accessible name (`aria-label`, or `aria-labelledby` naming non-empty text) |
| S7 | no `a[href]` whose text (its `aria-label`, else its text with spaces collapsed and trailing arrows and punctuation removed), lower-cased, is in `BANNED_LINK_TEXT` |
| S8 | no `starlight-tabs` element and no `[role="tablist"]` |
| S9 | no two elements in the document share an `id` (the problem names each duplicated id). The A1 tags select axe's `duplicate-id-aria` (only ids that an ARIA attribute references) but not `duplicate-id` or `duplicate-id-active`, which axe tags `wcag2a-obsolete` and `deprecated`; so this check is the one that catches every duplicate, including a heading id that clashes with a diagram id |
| U1-U7 | Feature 003's markup contract (its UI Specs), implemented as written there. For U4, an `svg` inside an element with `aria-hidden="true"` counts as hidden: Starlight's heading anchor links put their icon `svg` inside `span.sl-anchor-icon[aria-hidden="true"]` (`integrations/heading-links.ts` in the Starlight package) |
| W1 | the HTML file is at most `LIMIT` bytes (AC-15's `find dist -name '*.html' -size +150k` prints nothing exactly then) |
| W2 | gzip size (`zlib.gzipSync`) of the HTML plus every local file named by `<link rel="stylesheet">`, `<link rel="modulepreload">` and `<script src>` is at most `LIMIT` (NFR-2 "transferred"; each shared file is counted on every page, which overstates) |
| W3 | every `<script>` except `type="application/json"` and `type="application/ld+json"` matches at least one `PURPOSES` marker and no `FORBIDDEN` marker; a `src` script is judged by the file it names |
| W4 | no `<script src>` and no stylesheet `href` points off-site (`/^(https?:)?\/\//`) |
| A1 | `axe.run` finds no violation (options below) |

axe-core setup, per page:

```js
const dom = new JSDOM(page.html, { url: 'https://aid.casuloailabs.com' + page.url,
  runScripts: 'outside-only', virtualConsole: new VirtualConsole() });
dom.window.eval(axe.source);
const r = await dom.window.axe.run(dom.window.document, {
  runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] },
  rules: { 'color-contrast': { enabled: false } },
  resultTypes: ['violations'],
});
// problem per violation: `A1 ${v.id}: ${v.nodes.map((n) => n.target.join(' ')).join(', ')}`
```

After the pages: the total of `figure.diagram` across `dist/` is at least the number of files in
`src/components/diagrams/` (every diagram is used and passed U1 to U7; AC-8), and the test prints, with
`console.info`, each distinct script `src` with its purposes, which the implementer copies into the audit.

Self-tests (they prove each check can fail; fixture HTML strings in the file, no files written):

| Case | Fixture | Expected |
|---|---|---|
| T1 | two `h1` in `main` | S2 problem |
| T2 | `h1`, `h2`, `h4` in `main` | S4 problem naming `h4` |
| T3 | `<html>` without `lang` | S1 problem |
| T4 | a `figure.diagram` with no `.diagram-text` | U1 problem |
| T5 | an `svg` in `main` with no `aria-hidden` and no `aria-label` | U4 problem |
| T6 | an inline `<script>console.log(1)</script>` | W3 problem "no purpose" |
| T7 | a page with `<img src="a.png">` and no `alt` | A1 problem naming `image-alt` |
| T8 | a link with the text "click here →" | S7 problem |
| T9 | a `figure.diagram` whose `svg` holds an `a`; and a second one with the `a` only inside `.diagram-text` | U6 problem for the first; none for the second |
| T10 | a `figure.diagram` whose `svg` holds `<rect fill="#ffffff">` | U7 problem |
| T11 | two elements with `id="x"` | S9 problem naming `x` |

**`tests/contrast.test.mjs`** (Node built-ins only):

```js
/** WCAG 2.x relative luminance and contrast ratio. */
function luminance(hex) /* '#rrggbb' -> number */;   // channel c/255; c <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)**2.4; 0.2126 R + 0.7152 G + 0.0722 B
function ratio(fg, bg) /* -> number */;               // (Lmax + 0.05) / (Lmin + 0.05)
function readTokens(cssText) /* -> { dark: Map, light: Map, mapping: Map } */;
```

| Case | Assertion |
|---|---|
| K1 | `tokens.css` has the two blocks; both define the same set of `--aid-color-*` names; every value matches `/^#[0-9a-f]{6}$/` |
| K2 | every `--sl-*` declaration in `tokens.css` is `var(--aid-...)` naming a defined token, and every Starlight variable in the mapping table is declared |
| K3 | every `PAIRS` entry meets its minimum in both themes; a failure lists `<theme> <fg> on <bg>: <ratio> < <min> (<used for>)` |
| K4 | no colour literal (`/#[0-9a-f]{3,8}\b\|rgba?\(\|hsla?\(/i`) in `src/styles/site.css`, in a `<style>` block of `src/components/**/*.astro`, or anywhere in `src/components/Diagram.astro` and `src/components/diagrams/*.astro` (markup included). By design K4 does not read `public/favicon.svg` (see Data Model 1) or the content pages |
| K5 | `ratio('#000000', '#ffffff')` is 21; `ratio('#767676', '#ffffff')` is at least 4.5; `ratio('#777777', '#ffffff')` is below 4.5 (the function can fail) |

**Dependencies on other features.** Feature 005 owns `tests/dist.mjs`, `vitest.config.mjs`, `site/package.json`
(its Data Model 1 block lists this feature's two devDependencies) and the `npm install` run, and rewrites `Footer.astro` and `ReportForm.astro` with `--aid-*` tokens only
(K4 fails a hex value left in `ReportForm.astro`, such as today's `.rf-invalid` red; use `danger`). Feature
005's table "Components and config after the cut" keeps `src/assets/casulo-ai-labs.png`, which this header
uses. Feature 003 owns the diagram markup that U1 to U7 enforce.

##### UI Specs

**Layout** (Starlight's breakpoints; all colours and sizes from tokens):

| Width | Header (height 3.5rem, `nav` background, `border` bottom line) | Body |
|---|---|---|
| below 50rem (320 px included) | logo, "AID", then the search icon button and Starlight's menu button | one column; sidebar, social links and theme select inside the menu; "On this page" as Starlight's drop-down above the content |
| 50rem to 72rem | logo, "AID AI Integrated Development", GitHub, theme select, search button | sidebar on the left, content; "On this page" drop-down |
| 72rem and wider | same | sidebar, content (at most 46rem), "On this page" column on the right |

**`site.css` rules** (in this order, each using tokens only):

1. Focus: `:where(a, button, select, input, textarea, summary, [tabindex]):focus-visible { outline:
   var(--aid-focus-width) solid var(--aid-color-focus); outline-offset: var(--aid-focus-offset); }`. The
   outline always sits outside the element, so on the current sidebar item (accent background) it is drawn on
   the `nav` background (pair `focus`/`nav`).
2. Reduced motion: `@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation-duration:
   0.01ms !important; animation-iteration-count: 1 !important; transition-duration: 0.01ms !important;
   scroll-behavior: auto !important; } }`.
3. Content text: links underlined (`text-underline-offset: 0.2em`; 2px thick on hover), so a link never
   depends on colour alone (WCAG 1.4.1); `:is(p, td, th, dd)` get `overflow-wrap: break-word` and inline `code`
   gets `overflow-wrap: anywhere`, so long paths wrap at 320 px instead of widening the page.
4. Inline code: `surface` background, `--aid-radius-sm`, padding `0.1em 0.35em`.
5. Tables: header row `surface`, cell borders `border`, padding `--aid-space-2 --aid-space-3`. A wide table
   scrolls inside its own box (Starlight sets `display: block; overflow: auto` on content tables), which WCAG
   1.4.10 allows for data tables; the page itself never scrolls sideways.
6. Code blocks, cards and asides: `--aid-radius-md`; cards get a 1px `border` line.
7. Headings: `h2` gets `margin-top: var(--aid-space-6)`; weight 700 for `h1`, 600 below.
8. `.version-badge`: `accent` text on `accent-soft`, 1px `border-strong` border, `--aid-radius-sm`.
9. `.aid-report-issue` (the paragraph that holds the footer's report link; Feature 005's rewritten
   `Footer.astro` must keep this class name, as today's `Footer.astro` has it):
   `text-muted`, `--aid-text-sm`, a 1px `border` top line, `--aid-space-5` above it.
10. Narrow screens: `@media (max-width: 30rem) { :root { --sl-content-pad-x: var(--aid-space-3); } }`.

**Look.** Calm and typographic: one gold accent on neutral slate surfaces, generous line height, a 46rem
reading column, no gradients, glows, blur or shadows except Starlight's own on the search dialog. The brand
gold is kept in dark; in light it is darkened to `#7a5814` so links pass 4.5:1 on every light surface.

**Accessibility** (WCAG 2.2 AA; how each requirement is met and checked):

| Requirement | How | Checked by |
|---|---|---|
| Skip link (2.4.1) | Starlight's `SkipLink`, first in `body`, "Skip to content", target `#_top` | S5; AC-9 manual check |
| One `h1`, ordered headings (1.3.1, 2.4.6) | Starlight's `PageTitle` (or `Hero`) renders the only `h1`; page bodies start at `##` (Feature 001, rule P8) | S2, S4 (AC-10) |
| Landmarks (1.3.1) | Starlight's `header`, `nav` "Main" (sidebar), `aside` ("On this page"), one `main` | S3, S6 (AC-10) |
| `lang` (3.1.1) | `defaultLocale: 'en'` in `astro.config.mjs` | S1 (AC-10) |
| Visible focus (2.4.7, 2.4.11) | `site.css` rule 1, 3px ring with at least 3:1 contrast | K3; AC-9 manual check |
| Link purpose (2.4.4) | link text names the destination (Feature 001, rule P7) | S7, axe `link-name` |
| Contrast (1.4.3, 1.4.11) | token pairs | K3; axe for everything else |
| Reflow at 320 px (1.4.10) | header brand shortens, text wraps, tables and code scroll in their own box | AC-11 manual check |
| Reduced motion (2.3.3 is AAA; FR-5 asks for it) | `site.css` rule 2 | review |
| Theme control operable | native `<select>` with the accessible name "Select theme"; arrow keys change the value | axe `select-name`; AC-9 |
| No JavaScript except search, theme, navigation (NFR-2) | no Tabs, no copy button, no banner, no form script | W3, AC-15 |

**AC-9, manual keyboard check** (record the result in the audit's "Keyboard check (AC-9)" table). From `site/`:
`npm run build && npm run preview`, then open `http://localhost:4321/` and
`http://localhost:4321/skills/aid-define/` in a desktop browser window 1280 px wide, click the address bar,
and press Tab. Expected stops, in order: "Skip to content" (appears; Enter moves to the `h1`), the Casulo
AI Labs logo link, the "AID" home link, GitHub, "Select theme", "Search" (Enter opens the dialog, Escape
closes it), the sidebar group toggles and links from top to bottom, the "On this page" links (when the page
has them), the links in the content, then the footer's previous and next links and "Report a problem with this
page on GitHub". The focus ring must be visible at every stop, and no stop may trap focus. AC-9's list does not
name the "On this page" links; they sit between the sidebar and the content because Starlight places that
`aside` before `main`.

**AC-11, screenshots.** With the same preview, in the browser's responsive mode, take a viewport screenshot of
`/` and `/skills/aid-define/` at 320 x 800 and 1280 x 800, once with the theme select on Light and once on
Dark: 8 files named `<home|aid-define>-<320|1280>-<light|dark>.png` in
`.aid/works/work-005-site-rework/screenshots/`. For each, run
`document.documentElement.scrollWidth <= window.innerWidth` in the console; it must print `true` (no page
scroll sideways). Record the eight results in the audit's "Screenshots (AC-11)" table.

**AC-15, script list.** After `npm run build`, run AC-15's `grep -rho '<script[^>]*src="[^"]*"' dist
--include='*.html' | sort -u` from `site/` and write each line into the audit's "Scripts on built pages
(AC-15)" table with the purpose that W3 assigned (search, theme or navigation). Expected purposes only:
Starlight's search (`site-search`), theme select (`starlight-theme-select`), and navigation (menu button,
"On this page" highlighting, sidebar state). Astro inlines small scripts, so some of these may appear only
inline; W3 checks those too.

##### Migration Plan

| Today | After |
|---|---|
| `casulo.css`: `--casulo-*` brand tokens, dark mapping, light accent, Inter imports, Mermaid rules, version badge, release page, banner, report link | tokens to `tokens.css` (renamed `--aid-*`, both themes fully defined); version badge and report link to `site.css` (rules 8 and 9); Inter, Mermaid, release and banner rules dropped |
| `shell.css`: two-row header, section tabs, sidebar and TOC restyling, breadcrumb | dropped; Starlight's default sidebar and TOC styles with token colours; the section tabs go (the sidebar groups are the navigation) |
| `Header.astro` override (two rows, tabs derived from the sidebar) | one row, Starlight parts reordered (Layers & Components) |
| `PageTitle.astro` override (breadcrumb, eyebrow) | deleted |
| `Tabs` on four pages | plain sections |
| `@fontsource/inter` | its imports go with `casulo.css`; the package leaves `package.json` in Feature 005's step 6 |

Order: this feature lands after Features 002, 003 and 001 and before Feature 005's test step, as REQUIREMENTS.md
§ 11 suggests. `tests/a11y.test.mjs` needs `tests/dist.mjs`; if Feature 005 has not yet written it, this
feature's change adds it exactly as Feature 005 specifies, and Feature 005 keeps it. Feature 005 edits no stylesheet;
the Mermaid and banner rules leave with `casulo.css` here. The check
`grep -rn -- '--casulo-' src` (from `site/`) prints nothing after this feature.

### Feature 005 — Machinery Cut and Lean Tests

- **Priority:** Must
- **Requirements:** §5 FR-7, FR-8, FR-9, FR-11, FR-12
- **Criteria:** AC-1, AC-4, AC-5, AC-6

#### Description

Remove the generators, libraries, data files, scripts and dependencies that the new site does not need, together with their tests. Keep four groups of test (FR-8): the build succeeds, no broken internal links, the facts script's `--check` passes, and the accessibility and structure checks added by Feature 004. Move the pages that `sync-docs.mjs` copied from `docs/` into the site as its own Markdown, and replace the release-data fetch with the `VERSION` value plus a link to GitHub Releases, so the build uses no network. Keep search, sitemap, favicon, `CNAME`, `robots.txt`, version display and contact pages working. The feature's priority is Must because FR-7, FR-8 and FR-12 are Must; FR-9 and FR-11 are Should within it.

#### User Stories

- As a maintainer, I want far less site code and fewer tests to maintain, so that changing the site is cheap.
- As a maintainer, I want the remaining tests to catch real breakage (a failed build, a dead link, stale facts, an accessibility regression), so that they earn their place.

#### Technical Specification

##### Data Model

No database. Unless a path says otherwise, it is under `site/`. This feature owns five shapes.

**1. `package.json` after the cut.** It shows the final `scripts`, `dependencies`, `devDependencies` and
`overrides`. Every other key (`name`, `description`, `version`, `private`, `engines`) is unchanged.

```json
"scripts": {
  "facts": "node scripts/gen-facts.mjs",
  "facts:check": "node scripts/gen-facts.mjs --check",
  "build": "astro build",
  "dev": "astro dev",
  "preview": "astro preview",
  "astro": "astro",
  "check": "astro check",
  "test": "npm run build && vitest run"
},
"dependencies": {
  "@astrojs/sitemap": "3.7.3",
  "@astrojs/starlight": "0.39.3",
  "astro": "6.4.6"
},
"devDependencies": {
  "@astrojs/check": "0.9.9",
  "axe-core": "4.14.0",
  "jsdom": "29.1.1",
  "typescript": "6.0.3",
  "vitest": "^4.1.8"
},
"overrides": {
  "yaml": "^2.8.3",
  "esbuild": "^0.28.1"
}
```

The scripts `sync:docs`, `gen:reference`, `gen:skills`, `fetch:release`, `prebuild` and `predev` are removed.
With no `prebuild`, `astro build` renders exactly the committed pages, as Feature 002 requires. `test` builds
first, so the tests of groups (a), (b) and (d) always read a fresh `dist/`. Feature 002 specifies `facts` and
`facts:check`. Because `npm test` now builds, the separate build step in `.github/workflows/docs.yml` repeats
the build; Feature 006 keeps the separate build step (its Layers & Components, CI layer).

| Package | Decision | Reason (checked in `package-lock.json` and with grep over `site/src`, `site/scripts`, `astro.config.mjs`) |
|---|---|---|
| `astro`, `@astrojs/starlight`, `@astrojs/sitemap` | keep | the framework, plus the sitemap (FR-9) |
| `@fontsource/inter` | remove | only `src/styles/casulo.css` imports it, and Feature 004 deletes that file and uses system fonts |
| `@astrojs/check`, `typescript` | keep | `npm run check` |
| `vitest` | keep | runs the four test groups |
| `astro-mermaid`, `@mermaid-js/layout-elk` | remove | Mermaid is gone (Feature 003 redraws the diagrams) |
| `marked`, `sanitize-html`, `@types/sanitize-html` | remove | used only by `src/pages/releases/changelog.astro`, which is deleted |
| `jsdom` | keep, pinned exactly to `29.1.1` (today `^29.1.1`) | the DOM for Feature 004's `tests/a11y.test.mjs` (FR-8 group d); its users today are deleted tests |
| `axe-core` | add, pinned exactly to `4.14.0` | the rule engine of Feature 004's `tests/a11y.test.mjs` (FR-8 group d) |
| override `dompurify` | remove | the lockfile shows `mermaid` as its only consumer |
| overrides `yaml`, `esbuild` | keep | they are still used by `vite`, `@astrojs/yaml2ts` and `astro` |

The `zod` import in `src/content.config.ts` resolves through `astro`, which depends on `zod`. This feature
leaves that import as it is.

**2. The version value.** There is one source and one path from it to the page:

| Step | Where | Shape |
|---|---|---|
| source | repo-root `VERSION` (today `3.1.3`) | one line, optional leading `v` |
| read once, at config load | `astro.config.mjs`: `const AID_VERSION = readFileSync(new URL('../VERSION', import.meta.url), 'utf8').trim().replace(/^v/, '');` followed by `if (!/^\d+\.\d+\.\d+/.test(AID_VERSION)) throw new Error('astro.config.mjs: ../VERSION is not a version: ' + AID_VERSION);` | string |
| passed into the bundle | `defineConfig({ ..., vite: { define: { __AID_VERSION__: JSON.stringify(AID_VERSION) } } })` | compile-time constant |
| exposed | `src/data/version.ts`: `declare const __AID_VERSION__: string;` then `export const VERSION: string = __AID_VERSION__;`. `VERSION_TAG`, `InstallChannel` and `installCommands` stay as they are. `channelLabels`, which nothing imports, and the `release-data` import are removed | `VERSION`, `VERSION_TAG`, `installCommands` |
| shown | `src/components/VersionBadge.astro` (unchanged) on `/` and on `/releases/changelog/`. `src/components/InstallCommand.astro` (unchanged) on `/` and on `/guides/installation/` | `v3.1.3` |

The value is read from `astro.config.mjs` because that file always runs in Node at its real path. Today
`src/lib/release-data.ts` tries three candidate paths to find `VERSION`, because `import.meta.url` moves when
Vite bundles the module. A missing or malformed `VERSION` now fails the build loudly. The old code fell back
to an empty string. No environment variable is read, and nothing is fetched.

**3. The changelog page.** The new file `src/content/docs/releases/changelog.mdx` replaces
`src/pages/releases/changelog.astro` and keeps the URL `/releases/changelog/`. It is the whole page:

```mdx
---
title: Changelog
description: This page shows the current AID version and where to read the notes of every release.
---

import VersionBadge from '../../../components/VersionBadge.astro';

This page shows the current AID version and where to read the notes of every release.

## Current version

The current version is <VersionBadge />.

## Release notes

Every release, with its notes and its download bundles, is listed on
[the AID releases page on GitHub](https://github.com/AndreVianna/aid-methodology/releases).
```

The wording follows Feature 001's rules P1 and P7, and Feature 001's audit checks it. The sidebar entry is
Feature 001's (`slug: 'releases/changelog'`).

**4. The contact form, without JavaScript.** `src/components/ReportForm.astro` is rewritten as a plain HTML
form. Its client `<script>` is removed: NFR-2 allows no page script except search, the theme toggle and
navigation. The audit lead "/contact/* ... form works only with JavaScript" is settled here. The `Props`
interface stays (`kind: 'site' | 'bug' | 'feedback' | 'contact'`). One constant drives the markup:

| `kind` | `<form method="get" action=...>` | Hidden fields | Visible fields (each with a `<label for>`) | Submit text |
|---|---|---|---|---|
| `site` | `https://github.com/AndreVianna/aid-methodology/issues/new` | `labels=site issue` | `title` (text, `required`, starts as `[Site] `), `body` (textarea, `required`, starts as `**Page:** ` + blank line + `**Problem:** `) | Continue on GitHub |
| `bug` | same | `labels=bug` | `title` (starts as `[Bug] `), `body` (starts as `**What happened:**`, `**What I expected:**`, `**AID version and environment:**`, separated by blank lines) | Continue on GitHub |
| `feedback` | same | `labels=feedback` | `title` (starts as `[Feedback] `), `body` (empty, `required`) | Continue on GitHub |
| `contact` | `mailto:andre.vianna.rj@hotmail.com` | `subject=AID: request for a conversation` | `body` (textarea, `required`, label "What would you like to talk about?") | Open your email app |

- The GitHub forms send the query parameters `title`, `body` and `labels` to the new-issue page. That page
  honours them, because `.github/ISSUE_TEMPLATE/config.yml` sets `blank_issues_enabled: true`. For the
  `mailto:` form (GET, no `enctype`), the HTML Standard's "mail with headers" submission rule applies: it
  serialises `subject` and `body` as `application/x-www-form-urlencoded` and then replaces every `+` with
  `%20`, so spaces reach the mail client as spaces (a typed `+` was already encoded as `%2B`). The form must
  not set `enctype="text/plain"`, which switches to the "mail as body" rule and drops `subject`. Build case
  B4 asserts both. A browser that ignores the rule would show `+` for spaces; the audit's row for
  `/contact/contact-request/` records one manual submit in a current browser, with the subject line seen
  in the mail client.
- One sentence above each form says where it leads. For the three GitHub forms: "Continue on GitHub opens a
  new issue with your text filled in; nothing is sent until you submit it there, with a free GitHub
  account." For the contact form: "Open your email app starts an email to the maintainer with your text
  filled in; nothing is sent until you send it."
- Two things go away: the separate name and email fields (GitHub or the mail client identifies the sender),
  and the client-side `?page=` prefill.
- No `target="_blank"`. Required fields use the native `required` attribute. Styling is a short scoped
  `<style>` that uses Feature 004's tokens.

**5. The "Report an issue" footer link.** The site-issue form can no longer read `?page=`. So
`src/components/Footer.astro` builds the GitHub link itself, at build time, from the page it renders on.
The whole file:

```astro
---
// Footer override: Starlight's footer, then a per-page "report a problem" link to a prefilled GitHub issue.
import Default from '@astrojs/starlight/components/Footer.astro';

const { entry } = Astro.locals.starlightRoute;
const reportIssue = entry.data.reportIssue ?? true;
const pageTitle = entry.data.title ?? '';
const pageUrl = new URL(Astro.url.pathname, Astro.site).href;
const issueUrl = 'https://github.com/AndreVianna/aid-methodology/issues/new?' + new URLSearchParams({
  labels: 'site issue',
  title: `[Site] ${pageTitle}`,
  body: `**Page:** ${pageUrl}\n\n**Problem:**\n`,
}).toString();
---
<Default {...Astro.props}><slot /></Default>
{reportIssue && (
  <p class="aid-report-issue"><a href={issueUrl}>Report a problem with this page on GitHub</a></p>
)}
```

- `pageTitle` and `pageUrl` are read as today's `Footer.astro` reads them: the title from
  `Astro.locals.starlightRoute.entry.data.title`, the absolute URL from `Astro.url.pathname` against
  `Astro.site`.
- Starlight's own `Footer` (`Default`: previous/next links, edit link) still renders first.
- The paragraph keeps the class `aid-report-issue`, which Feature 004's `site.css` rule 9 styles.
- The `reportIssue` frontmatter switch stays: it is `false` on the four contact pages, and the schema keeps its
  default of `true`.

##### Feature Flow

The cut is ordered so that the site builds after every step. A step that removes a producer comes after the
step that stops its use.

1. **Stop the regeneration (first, and no later than Feature 002's first committed output).** Replace the
   `scripts` block (Data Model 1). As long as `prebuild` runs `gen:skills` and `gen:reference`, every build
   overwrites the pages that `gen-facts.mjs` wrote. Plan must schedule this step with Feature 002, or before
   it.
2. **Version and changelog.** Add the `AID_VERSION` read and `vite.define` to `astro.config.mjs`. The read
   needs `import { readFileSync } from 'node:fs';` at the top of the file: Feature 003, which lands before
   this step, deletes that import together with the Mermaid `head` entry, so this step adds it back (if the
   line is still there, it is left as is; `grep -c "from 'node:fs'" astro.config.mjs` must print `1`). Rewrite
   `src/data/version.ts`. Create `src/content/docs/releases/changelog.mdx`. Delete
   `src/pages/releases/changelog.astro`, `src/components/Banner.astro` and `src/lib/release-data.ts`. Remove
   the `Banner` key from the `components` map. Remove the three `.release-data.json` lines (the comment and
   the entry) from `site/.gitignore`.
3. **Mermaid and the node panel.** This step needs Feature 003 to have landed: it replaces every fenced
   `mermaid` block in the hand-written pages and removes the Mermaid integration, its `head` entry and their
   comments from `astro.config.mjs` (Feature 003, Feature Flow, "Removal of Mermaid"); this feature does not
   touch those lines. The skill pages lose their fences when Feature 002 regenerates them. In
   `astro.config.mjs`, this step removes only the `Head` key of the `components` map and its comment. Delete
   the files listed under Migration Plan. No stylesheet is edited here: Feature 004 deletes `casulo.css`,
   with its Mermaid and `.aid-banner` rules (its Migration Plan), and a leftover rule matches nothing in
   the meantime.
4. **Generators, libraries, data, old tests.** Delete the rest of the Migration Plan list. Then make the pages
   these tools wrote into hand-written pages:
   - In `src/content.config.ts`, remove the `sourceDoc` and `generatedFrom` fields. Keep `reportIssue`.
   - Remove the `sourceDoc:` line from the four pages that `sync-docs.mjs` copied from `docs/`:
     `concepts/methodology.mdx` (`.md` until Feature 001's split renames it), `concepts/faq.md`, `reference/repository-structure.md` and
     `reference/glossary.md`. They are already committed in git. Once the copy step is gone, the site copy is
     the only one the site uses. The `docs/` originals and `docs/images/3-ironman.png` stay untouched. Feature
     001 audits and rewrites their text.
   - In `reference/kb.md`, remove the `generatedFrom:` line and the comment line
     `<!-- generated — do not edit; ... -->`. The page becomes hand-written, as the owner decided. Feature 001
     audits its text.
   - In `reference/artifacts.md`, delete the "Sync manifest" and "Reference manifest" table rows. They name
     `site/scripts/.synced-manifest.json` and `site/scripts/.reference-manifest.json`, which no longer exist.
     Feature 001 records this in that page's audit row.
5. **Contact form and footer.** Rewrite `ReportForm.astro` and `Footer.astro` (Data Model 4 and 5).
6. **Dependencies.** First confirm that no stylesheet still imports Inter: `grep -rn '@fontsource' src`
   prints nothing (Feature 004 has replaced `casulo.css`). Then, from `site/`:

   ```
   npm uninstall astro-mermaid marked sanitize-html @mermaid-js/layout-elk @types/sanitize-html @fontsource/inter
   npm install --save-dev --save-exact axe-core@4.14.0 jsdom@29.1.1
   ```

   Delete the `dompurify` override from `package.json`, then run `npm install` to regenerate
   `package-lock.json`. These runs are the only network use, and they happen on the maintainer's machine, not
   in the build. Checks: `package.json` equals the Data Model 1 block in those four keys;
   `npm ls mermaid` prints `(empty)`; `grep -c '"node_modules/mermaid"' package-lock.json` prints `0`; and
   `node -p "require('axe-core/package.json').version"` prints `4.14.0`.
7. **Tests.** Write the group (a) and (b) files and the shared helper (Layers & Components). Rewrite
   `vitest.config.mjs`.
8. **Measure and record.** Run the AC-4 command and the same command with `tests` added (both are in the
   header of `.aid/works/work-005-site-rework/site-audit.md`, under Baseline figures). Fill in the "After"
   column of that table, the status column of "Kept site functions (FR-9)", and mark the "Release banner" row
   as removed.

**Verification** (from `site/` unless stated):

| Criterion | Command | Expected |
|---|---|---|
| AC-1 | `npm ci && npm run build` | exit 0. `dist/index.html` exists |
| AC-4 | the AC-4 command, and the same with `tests` added | both totals at most 21577. The kept components and `src/data/version.ts` measure 498 lines today; `gen-facts.mjs` adds at most 300 |
| AC-4 | `find scripts -type f` | prints exactly `scripts/gen-facts.mjs` (1 file, at most 300 lines) |
| AC-5 | `npm test` | exit 0. Vitest lists exactly the files of the four groups (Layers & Components) |
| AC-5 | from the repo root: `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules` | prints nothing |
| AC-6 | `npx vitest run tests/links.test.mjs` after a build | case L1 passes with 0 broken links |
| FR-12 / NFR-4 | `grep -rnE "fetch\(\|node:https?\|https?\.get\(\|process\.env" scripts src/components src/data astro.config.mjs` | prints nothing |
| FR-11 | `npm ls mermaid marked sanitize-html` | `(empty)` |
| FR-7 | `grep -rln "sourceDoc\|generatedFrom\|release-data\|skill-flows" src astro.config.mjs` | prints nothing |

##### Layers & Components

**The four test groups (FR-8).** Every test lives in the new folder `site/tests/`. Vitest is configured to
pick up only `tests/**/*.test.mjs`. `scripts/` then holds only `gen-facts.mjs`, so AC-4's "at most 2 files"
holds. The AC-4 command does not list `tests/`, but NFR-3 counts "all tests", so the audit records the total
with `tests` added as well (Feature Flow, step 8), and the 60% target applies to both totals.

| Group | File | Owner of its content | What it proves |
|---|---|---|---|
| (a) the build succeeds | `tests/build.test.mjs` | this feature | B1 to B5 below |
| (b) no broken internal links | `tests/links.test.mjs` | this feature | L1 and L2 below (AC-6) |
| (c) the facts script's `--check` passes | `tests/facts.test.mjs` | Feature 002 (cases C1 to C5) | AC-2, first half |
| (d) checks on built pages | `tests/a11y.test.mjs` and `tests/contrast.test.mjs` | Feature 004 (axe-core, structure, AC-15 weight and scripts, token contrast), with Feature 003's diagram assertions (AC-8) | AC-7, AC-8, AC-10, AC-15 |
| shared helper, not a test | `tests/dist.mjs` | this feature | below |

No other test file exists. `scripts/__tests__/source-encoding.test.mjs` is a BOM guard for the repository
and belongs to none of the four groups, so it is deleted together with the rest.

**`tests/dist.mjs`** (Node built-ins only). All four groups import it (group c for `SITE` and `REPO` only):

```js
export const SITE;   // absolute path of site/, from fileURLToPath(new URL('..', import.meta.url))
export const REPO;   // the parent of SITE
export const DIST;   // join(SITE, 'dist')
/** @typedef {{ file: string, url: string, html: string, redirectTo: string|null }} BuiltPage
 *  url: '/' for dist/index.html, '/a/b/' for dist/a/b/index.html, '/404.html' for dist/404.html.
 *  redirectTo: the url of a <meta http-equiv="refresh" content="N;url=..."> (Astro's redirect pages), else null. */
export function builtPages(dist = DIST) /* -> BuiltPage[] */;
export function findBrokenLinks(dist = DIST) /* -> string[] */;
```

- `builtPages` walks `dist/**/*.html` in sorted order. If `dist/index.html` is missing, it throws
  `dist/index.html is missing: run npm run build first`. Feature 004's checks skip pages whose `redirectTo`
  is not null, as Feature 001 requires.
- `findBrokenLinks` reads every `href="..."` and `src="..."` attribute value (single or double quotes) on
  every built page, plus every meta-refresh target. It decodes `&amp;`, `&#38;` and `&quot;`. It skips a
  value that starts with a scheme (`/^[a-z][a-z0-9+.-]*:/i`, so `https:`, `mailto:` and `data:` are skipped)
  or with `//`. It resolves everything else against the page URL
  (`new URL(value, 'http://site.invalid' + page.url)`) and drops the query. The path, after
  `decodeURIComponent`, is found when one of these exists: `dist<path>index.html` for a path ending in `/`,
  the file `dist<path>`, or `dist<path>/index.html`. A fragment is found when the target HTML holds
  `id="<fragment>"` or `name="<fragment>"`. When the target is a redirect page, the fragment is checked on the
  page it redirects to, followed once. Each broken link is one string,
  `<page url> -> <value> (no such page)` or `<page url> -> <value> (no such anchor)`, in page order.
  Feature 001's glossary links (`/reference/glossary/#<term>`) are checked by this anchor rule.

**`tests/build.test.mjs`** (group a). Each case reads the output of the build that `npm test` has just run:

| Case | Assertion |
|---|---|
| B1 | `dist/index.html` and `dist/404.html` exist, and the set of `url`s of the pages from `builtPages()` whose `redirectTo` is null, minus `/404.html`, equals the set of URLs derived from the files under `src/content/docs/` (each `.md`/`.mdx` path without its extension, a trailing `index` dropped, wrapped in `/…/`; `index.mdx` gives `/`). A missing or an extra page fails by name; redirect pages are checked by L1, which follows each one |
| B2 | FR-9 kept functions: `dist/pagefind/pagefind.js` exists, `dist/sitemap-index.xml` exists, `dist/favicon.svg` exists, `dist/robots.txt` contains `Sitemap: https://aid.casuloailabs.com/sitemap-index.xml`, and `dist/CNAME` trimmed equals `aid.casuloailabs.com` |
| B3 | version display: with `v = readFileSync(join(REPO,'VERSION'),'utf8').trim().replace(/^v/,'')`, both `dist/index.html` and `dist/releases/changelog/index.html` contain `v${v}`. The changelog also contains `href="https://github.com/AndreVianna/aid-methodology/releases"` |
| B4 | contact pages: each of `dist/contact/{site-issue,methodology-bug,feedback,contact-request}/index.html` contains exactly one `<form` with `method="get"` and no `enctype` attribute. The first three have `action="https://github.com/AndreVianna/aid-methodology/issues/new"`; `contact-request` has `action="mailto:andre.vianna.rj@hotmail.com"` and a hidden `subject` input |
| B5 | AC-2, second half: the number of directories in `dist/skills/` equals the number of directories in `REPO/canonical/skills` |

These rows give the "How it is checked" column of the audit's FR-9 table. A leftover Mermaid fence is
not a build case: Feature 003's markup assertion U5, run on every page by Feature 004's page check, fails it. Test names and strings must not
contain the words of the AC-5 grep (`flow-graph`, `provenance`, `node-panel`, `sync-docs`).

**`tests/links.test.mjs`** (group b):

| Case | Setup | Expected |
|---|---|---|
| L1 | `findBrokenLinks()` on the real `dist/` | `[]`. On failure, vitest prints the whole list |
| L2 | in a `mkdtempSync` folder: `index.html` links to `/a/`, `/missing/`, `/a/#there`, `/a/#nothere`, `/old/#there`, `https://example.com/x` and `mailto:x@example.com`; `a/index.html` holds `id="there"`; `old/index.html` is a meta refresh to `/a/` | exactly `['/ -> /missing/ (no such page)', '/ -> /a/#nothere (no such anchor)']`. The folder is removed in `afterAll` |

L2 shows that the checker can fail. A link check that never fails proves nothing.

**`vitest.config.mjs`** (rewritten; it replaces today's long comment block):

```js
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: { include: ['tests/**/*.test.mjs'], environment: 'node', testTimeout: 60000 },
});
```

Every file runs in the `node` environment. Feature 004's `tests/a11y.test.mjs` builds its own DOM with jsdom, so no file needs a `// @vitest-environment` docblock.

**Components and config after the cut** (who edits what):

| File | State | Owner of the change |
|---|---|---|
| `astro.config.mjs` | `Banner` and `Head` keys removed; `import { readFileSync } from 'node:fs'`, `AID_VERSION` and `vite.define` added | this feature (Feature 003 removes the Mermaid integration, its `head` entry and their comments; Feature 001 owns `sidebar` and `redirects`, Feature 002 the Skills group, Feature 004 `customCss` and `components`) |
| `src/content.config.ts` | `sourceDoc` and `generatedFrom` removed | this feature |
| `src/data/version.ts` | rewritten (Data Model 2) | this feature |
| `src/components/ReportForm.astro`, `src/components/Footer.astro` | rewritten (Data Model 4 and 5) | this feature; styling uses Feature 004's tokens |
| `src/components/VersionBadge.astro`, `src/components/InstallCommand.astro` | kept unchanged | — |
| `src/components/overrides/Header.astro` | rewritten; `src/components/overrides/PageTitle.astro` deleted | Feature 004 |
| `src/components/Diagram.astro` | new | Feature 003 |
| `src/styles/casulo.css`, `src/styles/shell.css` | deleted, replaced by `tokens.css` and `site.css` | Feature 004 |
| `public/CNAME`, `public/favicon.svg`, `public/robots.txt` | kept unchanged (FR-9) | — |
| `src/assets/casulo-ai-labs.png` | kept (the header logo) | — |
| `tsconfig.json`, `.nvmrc` | unchanged | — |

##### Migration Plan

**Delete** (all under `site/`, with git; the counts are from `find <dir> -type f | wc -l` at the baseline
commit):

| Path | Files | Why it goes |
|---|---|---|
| `scripts/sync-docs.mjs`, `scripts/.synced-manifest.json` | 2 | the copy from `docs/` ends (FR-12); the four pages are now the site's own |
| `scripts/gen-skills.mjs`, `scripts/.skills-manifest.json`, `scripts/skills/` | 1 + 1 + 12 | replaced by `scripts/gen-facts.mjs` (Feature 002) |
| `scripts/gen-reference.mjs`, `scripts/.reference-manifest.json` | 2 | agents and settings pages move to `gen-facts.mjs`; `reference/kb.md` becomes hand-written; `reference/skills.md` is removed (Feature 001) |
| `scripts/fetch-release-data.mjs` | 1 | it needs the network (FR-12) |
| `scripts/lib/flow-graph/`, `scripts/lib/provenance/` | 14 + 4 | they existed only for the per-skill flow diagrams and their source links (FR-7) |
| `scripts/__tests__/` | 42 | tests of removed code, plus two vitest-environment self-tests and a BOM guard (none is in an FR-8 group) |
| `src/lib/` (`release-data.ts`, `skill-node-panel.ts`, `__tests__/` with 6 files) | 8 | release data and the node panel are removed |
| `src/data/skill-flows/` | 37 | the per-skill `*.flow.json` files (FR-7) |
| `src/data/__tests__/` | 2 | tests of the old version layer and of page source text |
| `src/scripts/mermaid-source-cache.js` | 1 | the workaround for Mermaid's source cache |
| `src/components/Banner.astro` | 1 | the release banner needs release data. It is not in FR-9 and it adds an inline script |
| `src/components/overrides/Head.astro` | 1 | it existed only to mount the node panel |
| `src/pages/releases/changelog.astro` (the `src/pages/` folder empties) | 1 | replaced by `src/content/docs/releases/changelog.mdx` at the same URL |
| `public/skill-node-panel.css`, `public/skill-node-panel.mjs` | 2 | the node panel |

That is 79 of the 79 files in `scripts/`, and all 50 test files. **Kept:** everything in the "Components and
config after the cut" table, plus `src/content/docs/**`, which Feature 001 rewrites and Feature 002 regenerates
in part. The `docs/` folder at the repository root is not touched (§4).

**Outside `site/`, out of scope, still naming deleted files.** These are not changed by this work (§4, NFR-5).
They are recorded here so the owner can decide:
- `.claude/skills/generate-profile/SKILL.md`, in its verification step, runs
  `node -e "import('./site/scripts/skills/skill-counts.mjs')..."`. That command fails once `scripts/skills/` is
  deleted.
- the comment block above `alias_of` in `canonical/aid/templates/shortcut-catalog.yml` names
  `site/scripts/skills/skill-counts.mjs`, `site/scripts/skills/catalog.mjs` and `site/scripts/gen-reference.mjs`.
- `docs/diagram-content-reference.md` tells the reader to run `node site/scripts/sync-docs.mjs`.

### Feature 006 — Workflow, KB Entry and Safety

- **Priority:** Should
- **Requirements:** §5 FR-10
- **Criteria:** AC-13, AC-14

#### Description

Update `.github/workflows/docs.yml` (edited, never run) and every Knowledge Base statement about the site's generators, scripts and tests (`.aid/knowledge/test-landscape.md` and any other KB document that becomes false), so they describe the simplified site accurately. Confirm that nothing was deployed or published, that changes stayed within the allowed paths, and that the repository checks still pass.

#### User Stories

- As a maintainer, I want the workflow and the KB to describe the real site build, so that CI and the docs do not mislead.
- As the repository owner, I want proof that nothing was published, so that I decide when the site goes live.

#### Technical Specification

##### Data Model

No database or schema. This feature edits one workflow file and a set of Knowledge Base documents, and
fills one section of the audit file. It runs last in the build order: it describes what Features 002 to
005 left on disk, so it reads its variable facts from that disk rather than from their specs.

**1. Binding values.** These facts are decided by other features. Read each one from the tree once
Features 002 to 005 are merged, and use it wherever the KB text below shows `{B<n>}`. Run every command
from the repo root.

| Id | Value | Decided by | Read with |
|---|---|---|---|
| B1 | the site test files and their folders | Feature 005 | `git ls-files site \| grep -E '\.test\.(mjs\|ts)$'` |
| B2 | the `scripts` block of `site/package.json` | Feature 005 | `node -p "JSON.stringify(require('./site/package.json').scripts, null, 1)"` |
| B3 | `dependencies`, `devDependencies` and `overrides`, with versions | Feature 005 (its Data Model 1 block) | `node -p "const p=require('./site/package.json'); JSON.stringify({d:p.dependencies, dev:p.devDependencies, o:p.overrides}, null, 1)"` |
| B4 | the file that reads the repo-root `VERSION` at build time | Feature 005 | `grep -rlF "new URL('../VERSION'" site/src site/astro.config.mjs` (prints exactly one path, `site/astro.config.mjs`; any other output means Feature 005's Data Model 2 was not followed, so stop) |
| B5 | whether the home page still shows a pipeline diagram | Feature 003 | `grep -cE '<Pipeline[[:space:]/>]' site/src/content/docs/index.mdx` (Feature 003 renders D1 there as `<Pipeline />`, imported from `../../components/diagrams/Pipeline.astro`; 0 means no) |
| B6 | whether `VersionBadge.astro` survives, and which pages use `CardGrid` | Features 004, 005 | `test -f site/src/components/VersionBadge.astro; echo $?` and `grep -rl "CardGrid" site/src/content/docs` |
| B7 | the path of the diagram component | Feature 003 | `git ls-files site \| grep 'Diagram.astro$'` |

**2. The KB edit inventory.** Found with this search, which matches every KB statement about the site's
generators, scripts, tests, dependencies or Mermaid:

```
grep -rnE "site/|mermaid|Mermaid|vitest|sync-docs|gen-skills|gen-reference|fetch-release|flow-graph|skill-counts|node panel|node-panel|Skill Explorer|prebuild|docs\.yml|Releases API" .aid/knowledge --include='*.md'
```

Each hit was read and sorted into one of three classes:

| Class | Documents | Action |
|---|---|---|
| Made false by this work | `test-landscape.md`, `module-map.md`, `architecture.md`, `project-structure.md`, `technology-stack.md`, `infrastructure.md`, `integration-map.md`, `tech-debt.md`, `domain-glossary.md` | edit as listed under Layers & Components |
| Missing a new fact a reader needs | `PROJECT.md` (the project card) | add one command line and one rule |
| Left unchanged | `STATE.md` (type `state`, never edited: run history); `release-tracking.md` (its own criterion F-01 excludes shipped entries from current-state checks); `decisions.md` (D26 names `site/` TypeScript and `vitest --coverage`, both still true; the Mermaid entries concern `kb.html`); `authoring-conventions.md`, `artifact-schemas.md` (their Mermaid mentions concern KB docs and `kb.html`); `pipeline-contracts.md`, `quality-gates.md`, `kb.html`, `INDEX.md`, `README.md` (their site statements stay true; `kb.html` names no removed script) | none |

`kb.html` is the generated KB tour. It is not hand-edited. Its site statements ("Astro-based docs site",
"TypeScript + Starlight theme") stay true, so it needs no regeneration for this feature.

**3. The audit section.** `.aid/works/work-005-site-rework/site-audit.md` § Knowledge Base documents edited
(FR-10), created by Feature 001. There is one row per KB document this feature changes. The first cell
is the file name in a code span, exactly as it is named under `.aid/knowledge/` (for example
`module-map.md`); the second is the statement made true, in one sentence; the third is `done`. AC-13
compares the changed KB files with this table (Feature Flow step 10).

##### Feature Flow

1. **Preconditions.** Features 002 to 005 are merged into the branch. From the repo root,
   `node site/scripts/gen-facts.mjs --check` exits 0, and from `site/`, `npm test` and `npm run build`
   exit 0. If any of these fails, stop: this feature describes the finished site, not a broken one.
2. **Read the binding values** B1 to B7 (Data Model, table 1).
3. **Edit `.github/workflows/docs.yml`** as given under Layers & Components. The workflow is edited only,
   never run: no push and no `workflow_dispatch`.
4. **Check the workflow statically.** All commands run from the repo root and must give the stated result:

   | Check | Command | Expected |
   |---|---|---|
   | it parses, and the build steps are in order | `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/docs.yml')); print([s.get('name') or s['uses'].split('@')[0] for s in d['jobs']['build']['steps']])"` | `['actions/checkout', 'actions/setup-node', 'actions/configure-pages', 'Check site facts against canonical/', 'Install deps (reproducible)', 'Test (site suite)', 'Build Astro Starlight site', 'actions/upload-pages-artifact']` |
   | the path filters | `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/docs.yml'))[True]; print(d['push']['paths'] == d['pull_request']['paths'] == ['site/**','canonical/**','VERSION','.github/workflows/docs.yml'])"` | `True` |
   | the fetch and its variables are gone | `grep -cE "fetch-release-data\|GITHUB_ENV\|AID_VERSION\|AID_LATEST_RELEASE_JSON\|AID_RELEASES_JSON\|docs/\*\*" .github/workflows/docs.yml` | `0` |
   | the deploy job is untouched | `diff <(git show site-aid:.github/workflows/docs.yml \| sed -n '/^  deploy:/,$p') <(sed -n '/^  deploy:/,$p' .github/workflows/docs.yml)` | no output, exit 0 |
   | permissions and concurrency are untouched | `diff <(git show site-aid:.github/workflows/docs.yml \| sed -n '/^permissions:/,/^jobs:/p') <(sed -n '/^permissions:/,/^jobs:/p' .github/workflows/docs.yml)` | no output, exit 0 |
   | the site no longer reads `docs/` (why the filter drops it) | `grep -rlE "(\.\./)+docs/" site --include='*.mjs' --include='*.ts' --include='*.astro' --exclude-dir=node_modules --exclude-dir=dist` | no output |

   The PyYAML key `True` is how PyYAML reads the bare `on:` key. PyYAML 6.0.1 is present on this host.
5. **Edit the KB documents** as listed under Layers & Components. Before writing each one, resolve its review
   criteria (`.aid/knowledge/authoring-conventions.md`): global G-01 to G-16, type `kb-doc` (KB-01 to KB-18)
   or `kb-card` (PC-01 to PC-03 for `PROJECT.md`), plus the file's own `review-criteria:`. The ones these
   edits can break:
   - **No Work References** and `test-kb-no-work-ids.sh`: no work id, work path, feature, task, delivery,
     FR or AC id in KB prose;
   - **G-02**: no bare line-number citations;
   - **G-03**: a resolved debt row is deleted, with no closure note;
   - **G-01**: no hand-written counts;
   - **KB-07**: no diagram blocks;
   - **KB-11**: exit codes are stated inline.

   Do not change any `objective:`, `summary:` or `tags:` value, so `INDEX.md` stays fresh.
6. **Sweep.** Both commands must print nothing. `STATE.md` (run history) and `release-tracking.md`
   (shipped entries) are excluded because this feature leaves them unchanged (Data Model 2):

   ```
   grep -rnE "gen-skills|gen-reference|sync-docs|sync:docs|fetch-release|skill-counts|curated-roster|flow-graph|skill-node-panel|node panel|astro-mermaid|layout-elk|mermaid-source-cache|Skill Explorer|vitest suite|site data tests|Releases API for version|docs/\*\*" .aid/knowledge --include='*.md' | grep -vE '^\.aid/knowledge/(STATE|release-tracking)\.md:'
   grep -rnE "~2765 vitest|build-time generators|prebuild syncs" .aid/knowledge --include='*.md'
   ```
7. **Repository checks (AC-14).** From the repo root, all exit 0:

   ```
   bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge
   bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge
   bash tests/canonical/test-kb-no-work-ids.sh
   ```

   All three exited 0 on the base commit `71b16c35f` when run at Specify (2026-10-26, read-only, from the
   repo root). Also run the `test.yml` INDEX
   freshness check:

   ```
   out=$(mktemp); bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output "$out"
   filt='AUTO-GENERATED|Generated at:|: Generated$'; diff <(grep -vE "$filt" .aid/knowledge/INDEX.md) <(grep -vE "$filt" "$out")
   ```

   This must print nothing. If it prints a difference, regenerate `INDEX.md` with the project card's
   command and add an `INDEX.md` row to the audit section.
8. **Fill the audit section** (Data Model 3): one row per KB document actually changed.
9. **Commit locally.** No push, no tag.
10. **Safety proof (AC-13 and NFR-5).** From the repo root, after the last commit, and before anything else
    is written:

    | Check | Command | Expected |
    |---|---|---|
    | everything is committed | `git status --porcelain` | no output |
    | only allowed paths changed | `git diff --name-only site-aid...HEAD \| grep -vE '^(site/\|\.github/workflows/docs\.yml$\|\.aid/works/work-005-site-rework/\|\.aid/knowledge/)'` | no output |
    | every changed KB file is in the audit table | the loop below | no output |
    | no shell or PowerShell file touched | `git diff --name-only site-aid...HEAD -- '*.sh' '*.ps1' '*.psm1'` | no output |
    | no tag | `git tag --points-at HEAD` | no output |
    | no upstream, no remote branch | `git rev-parse --abbrev-ref work-005@{upstream}` and `git ls-remote --heads origin work-005` | first fails (no upstream), second prints nothing |

    ```
    for f in $(git diff --name-only site-aid...HEAD -- .aid/knowledge); do
      grep -qF "| \`${f#.aid/knowledge/}\` |" .aid/works/work-005-site-rework/site-audit.md || echo "unlisted: $f"
    done
    ```

    `git ls-remote` reads the remote and changes nothing. It is the only check that needs the network. If
    the network is not available, record the two local checks and say that the remote check was not run.
    Pages deploys only from `master`, so this branch's content can be published only after its commits
    reach the remote. The last row therefore also proves that nothing from this work was deployed.
11. **Record the outcome.** Only after step 10, write its commands and their output to the work's
    STATE.yml. This write is not part of the step-10 checks: afterwards `git status --porcelain` lists
    that one file, and the work's closing commit carries it.

##### Layers & Components

**CI layer: `.github/workflows/docs.yml`.** These are the only changes. Every other line, including the
`permissions:` and `concurrency:` blocks, the `pull_request` comment lines and the whole `deploy` job,
stays byte for byte.

1. Header comment: delete the sentence "After a release, refresh the release-bound content with a
   workflow_dispatch on master." because nothing release-bound is fetched any more. After the paragraph
   that ends "so a tag/release ref is rejected.", insert:

   ```yaml
   #
   # No step after `npm ci` uses the network.  The version the site shows is read
   # from the repo-root VERSION file at build time; the skill, agent and settings
   # pages are committed output of site/scripts/gen-facts.mjs, checked below.
   ```
2. The `on:` block becomes:

   ```yaml
   on:
     push:
       branches: [master]
       paths:                      # only rebuild when site inputs change
         - 'site/**'
         - 'canonical/**'          # gen-facts.mjs --check compares the committed
                                   # skill, agent and settings pages with it, so a
                                   # canonical-only commit must still be checked
         - 'VERSION'               # read at build time for the version display
         - '.github/workflows/docs.yml'
     pull_request:                 # M2: gate PRs to master — build-validate site inputs before merge
       branches: [master]          # (the `deploy` job is skipped on PRs; build only)
       paths:
         - 'site/**'
         - 'canonical/**'
         - 'VERSION'
         - '.github/workflows/docs.yml'
     workflow_dispatch:            # manual re-deploy
   ```

   `docs/**` is removed from both filters because, after Feature 005, no file under `site/` reads `docs/`
   (Feature Flow step 4 checks this). `canonical/**` stays because the facts check reads it. `VERSION`
   stays because the build reads it (B4).
3. The `build` job's steps become:

   ```yaml
       steps:
         - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

         - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
           with:
             node-version-file: 'site/.nvmrc'
             cache: 'npm'
             cache-dependency-path: 'site/package-lock.json'

         - uses: actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d # v6.0.0

         # The skill, agent and settings pages under site/src/content/docs/ are
         # committed output of gen-facts.mjs. --check writes nothing. Exit 1: a page
         # differs from what canonical/ produces now; fix by running
         # `node site/scripts/gen-facts.mjs` and committing its output. Exit 2: an
         # input error (such as a skill with no group) or a crash; read the message.
         # Node built-ins only, so it runs before `npm ci` and fails fast.
         - name: Check site facts against canonical/
           run: node site/scripts/gen-facts.mjs --check

         - name: Install deps (reproducible)
           working-directory: site
           run: npm ci

         # Gate on the site suite: the build, internal links, the facts check, and
         # accessibility + structure checks on every built page. After `npm ci`
         # because the test tools are devDependencies; before the build step so a
         # red suite never produces a Pages artifact.
         - name: Test (site suite)
           working-directory: site
           run: npm test

         - name: Build Astro Starlight site
           working-directory: site
           run: npm run build

         - uses: actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9 # v5.0.0
           with:
             path: site/dist
   ```

   This removes:
   - the step "Fetch build-time release data (VERSION + Releases API)", with its comment and its
     `GITHUB_TOKEN` / `GITHUB_REPOSITORY` env;
   - the long comment on the test step about `AID_*` variables;
   - the build step's `env:` block (`AID_VERSION`, `AID_LATEST_RELEASE_JSON`, `AID_RELEASES_JSON`).

   The facts check takes the place of the fetch step. `npm test` builds `dist/` itself (Features 004 and
   005), so the job builds twice. The separate build step stays, as the owner decided, so the uploaded
   artifact always comes from a plain `npm run build`. The second build is an accepted cost. The workflow's
   permissions do not change: `contents: read` is still enough, and no step needs the token any more.

**KB layer.** Each change is anchored by section heading and by a string to grep for. "Row" means the
table row that starts with the quoted cell. Replacement text is given in full; a replacement that holds
Markdown code spans is given as a numbered block (K1, K2, ...) after its table, to be pasted as written.
`{B<n>}` is filled from Data Model table 1.

*`test-landscape.md`*

| Where | Replacement |
|---|---|
| § Test Framework Inventory, the row whose first cell is "Astro / TypeScript tests" | block K1 |
| § CI Lanes and Where They Run, the paragraph containing "`docs.yml` is the exception" | "The **canonical** correctness gates (`test.yml`) run on `master` and release tags only, so a branch with no open PR gets the installer matrix instead. **`docs.yml` is the exception**: it also gates pull requests to `master`, and its `build` job runs the site's facts check and test suite. Read the per-lane rows below rather than generalising from this sentence." (The opening sentence "AID has five GitHub Actions workflows." stays.) |
| same section, the row whose first cell is `.github/workflows/docs.yml` (Docs) | Trigger cell: "push **and `pull_request`** to `master`, both path-filtered to `site/**`, `canonical/**`, `VERSION`, or the workflow; `workflow_dispatch`". Jobs cell: "`node site/scripts/gen-facts.mjs --check` → `npm ci` → **`npm test` (site suite)** → `npm run build`; then GitHub Pages deploy (`deploy` job skipped on PRs)". Last cell unchanged. |
| same section, the sentence beginning "CONFIRMED by the `on:` blocks of each workflow" | "CONFIRMED by the `on:` blocks of each workflow; the `on:` block of `.github/workflows/docs.yml` (`push`, `pull_request`, `workflow_dispatch`) has no `release:` key." This drops a dated line-range citation that this feature's edit moves. |
| same section, the paragraph beginning "**The site is the exception, and it is a PR gate.**" | "**The site is the exception, and it is a PR gate.** `docs.yml` also triggers on `pull_request` to `master`, so the facts check, the site suite **and** the Astro build validate every PR that touches `site/**`, `canonical/**` or `VERSION`. Only the `deploy` job is master-only. Two consequences a maintainer needs. First, a **canonical-only** commit still runs the job, because `node site/scripts/gen-facts.mjs --check` compares the committed skill, agent and settings pages under `site/src/content/docs/` with `canonical/`. Second, that check, not the build, catches a `canonical/` edit whose site pages were not regenerated. The build never reads `canonical/`, so after such an edit, run `node site/scripts/gen-facts.mjs` and commit its output in the same change." |
| § Coverage Assessment, the row whose first cell is "Astro site" | block K2 |
| § Test Commands, the comment `# Astro site build (the docs.yml gate)` and the command under it | block K3 |

```markdown
K1
| Vitest (site) | Build and page checks | {B1 folders} | Run by `npm test` in `site/`, on its own toolchain: the build succeeds; no internal link in `dist/` is broken; `site/scripts/gen-facts.mjs --check` passes; axe-core plus structure assertions (one `h1`, heading order, one `main`, `lang`, every diagram has a title, a description and a text equivalent) pass on every built page. |

K2
| Astro site | Moderate | the site suite ({B1 folders}); `gen-facts.mjs --check` also runs as its own `docs.yml` step; there are no unit tests of components, by design |

K3
# Site gate, as docs.yml runs it (from the repo root)
node site/scripts/gen-facts.mjs --check
cd site && npm ci && npm test && npm run build
```

*`module-map.md`*

| Where | Replacement |
|---|---|
| frontmatter `review-criteria:` F-03 | criterion: "site/ is described as taking its skill, agent and settings facts from canonical/ through site/scripts/gen-facts.mjs, whose --check fails docs.yml and the site suite when the committed pages drift". why: "It is why a canonical change can turn the site's CI red, which is otherwise a surprising failure". `id`, `kind` and `severity` are unchanged. |
| § Module Inventory, the row whose first cell is `site/` | block K4 |
| same table, the five rows whose first cells are `site/scripts/gen-skills.mjs` + `site/scripts/skills/*` (12), `site/scripts/lib/flow-graph/*` (14), `site/scripts/gen-reference.mjs`, `site/scripts/skills/skill-counts.mjs`, and `site/public/skill-node-panel.mjs` (runtime) + ... | delete all five; insert block K5 in their place |
| § Dependency Graph, the code-block lines from `site/                       -> canonical/skills/, canonical/agents/,` through `(generators read the toolkit at build time)` | block K6. The line `site/ -> (independent of the CLI: bin/, lib/, install.sh)` stays. |
| same section, from the line "**`site/` DOES consume `canonical/` — this was a non-dependency and is no longer.**" through the paragraph ending "turns the site build red by design." | block K7 |

```markdown
K4
| `site/` | Observation | Astro marketing + docs website. Its skill, agent and settings pages are **generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed**; every other page is hand-written Markdown. | own `package.json`; the repo-root `VERSION` at build time | medium | tested (the site suite: build, internal links, facts check, accessibility and structure of `dist/`) | Independent of the CLI (`bin/`, `lib/`). Separate `node_modules`/`dist`. The build reads no `canonical/` file; only the facts script does. |

K5
| `site/scripts/gen-facts.mjs` | Observation | **Site facts script.** Writes one page per `canonical/skills/*` directory, plus the skills index, the agents page and the settings-keys page, under `site/src/content/docs/`; each page carries a "generated - do not edit" marker. `--check` writes nothing. It exits 0 when every page is current, 1 when a committed page differs from what `canonical/` produces now, and 2 on an input or usage error (for example a skill directory with neither a catalog family row nor a `GROUPS` entry) or an internal error. | `canonical/skills/*/SKILL.md`, `canonical/agents/*/AGENT.md`, `canonical/aid/templates/shortcut-catalog.yml`, `canonical/aid/templates/settings.yml`; Node built-ins only | small | tested (the facts group of the site suite) | Not run by `npm run build`. Run it by hand (`npm run facts` in `site/`) after a `canonical/` change and commit its output. |

K6
site/scripts/gen-facts.mjs  -> canonical/skills/, canonical/agents/,
                               canonical/aid/templates/{shortcut-catalog.yml,settings.yml}
                               (run by hand and as a CI check; not part of the build)
site/ (astro build)         -> site/ , VERSION
```

Block K7:

~~~markdown
**`site/` depends on `canonical/` through one script, and the dependency is checked.**

```
site/  ->  canonical/       (through site/scripts/gen-facts.mjs; checked, not built)
```

The skill pages, the skills index, the agents page and the settings-keys page restate facts from the
toolkit, so `site/scripts/gen-facts.mjs` writes them from `canonical/` and they are committed like any
other page. The build does not run the script, so `astro build` renders exactly the committed pages.

- `node site/scripts/gen-facts.mjs --check` exits 1 when a committed page differs from what
  `canonical/` produces now, and 2 on an input error (for example a skill directory with neither a
  catalog family row nor an entry in the script's `GROUPS` table) or an internal error. It runs as its own step in `.github/workflows/docs.yml` and
  inside the site suite.
- `.github/workflows/docs.yml` lists `canonical/**` on both path filters, so a canonical-only commit
  still runs the check.
- `tests/canonical/test-doc-counts.sh` compares the counts stated in the public-facing docs (root
  `README.md`, `docs/`, the profile READMEs) against a derivation rooted in `canonical/`. Counts
  stated elsewhere are governed by criterion `G-01` instead of by a guard.

**Consequence for any change:** some `canonical/` changes are `site/` changes too. These are: adding,
removing or renaming a skill or an agent; editing a skill's `description`, `argument-hint` or
`allowed-tools`; editing an agent's `description`, `tier` or `tools`; changing a catalog family row's
`group`; and editing a key or comment of the settings template. After any of them, run
`node site/scripts/gen-facts.mjs` and commit its output in the same change. A new skill directory with
neither a catalog family row nor a `GROUPS` entry fails the check by name.
~~~

*`architecture.md`*

| Where | Replacement |
|---|---|
| § Entry Points, item 7 ("The website — `site/`") | "7. The website — `site/` (Astro build; independent of the CLI. Its skill, agent and settings pages are generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed; the build itself reads no `canonical/` file — see module-map.md § Dependency Graph)." |
| § Gotchas, the bullet "**Heavy CI gates run only on `master`**" | "- **Heavy CI gates run only on `master`** (`tests/run-all.sh`), and the site gate (`docs.yml`) runs on `master` and on pull requests to it; a feature branch with no open PR skips both. Run `tests/run-all.sh` (HOME-pinned) and the site gate (`test-landscape.md` § Test Commands) locally before claiming green. (Project memory: master-ci-only-on-master.)" This bullet already contradicted `test-landscape.md` (KB-09); it is fixed here because both describe the site gate. |

*`project-structure.md`*

| Where | Replacement |
|---|---|
| § Directory Tree, the `src/` and `scripts/` lines under `site/` | `│   ├── src/                  # Astro content, pages and components` and `│   ├── scripts/              # gen-facts.mjs: skill, agent and settings pages from canonical/` |
| § Top-Level Directory Purposes, the row whose first cell is `site/` | second cell: "An Astro website (marketing + docs). Separate build from the CLI/toolkit; its skill, agent and settings pages are generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed, and every other page is hand-written." (last cell unchanged) |
| § Entry Points, item 6 | "6. **Website** — `site/` builds via Astro on its own toolchain (hand-written pages, plus pages generated from `canonical/` and committed)." |
| § Test Directories, the rows for `site/scripts/__tests__/` and `site/src/data/__tests__/` | one block K8 row per B1 folder |
| § Unusual Structure Notes, item 3 ("The website (`site/`) is a separate build, not a separate source.") | "3. **The website (`site/`) is a separate build, not a separate source.** It has its own `package.json`, `node_modules`, and `dist/`, and is not part of the CLI/toolkit build. Its skill, agent and settings pages are generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed. So a `canonical/` change that the committed pages do not reflect fails `node site/scripts/gen-facts.mjs --check` (a `docs.yml` step, and part of `npm test`), not the build. CONFIRMED (`site/scripts/gen-facts.mjs`; `.github/workflows/docs.yml`)." |

```markdown
K8
| `{folder}/` | The site suite (vitest): the build, internal links, the facts check, and accessibility and structure of the built pages. Run with `npm test` in `site/`. |
```

*`technology-stack.md`*

| Where | Replacement |
|---|---|
| § Languages table, the row whose first cell is **JavaScript (Node)** | in the third cell, replace "and the site's build-time generators" with "and the site's facts script (`site/scripts/gen-facts.mjs`)" |
| the row whose first cell is **TypeScript** | version from B3. If `typescript` is not in B3, delete the row. |
| § Frameworks & Tooling, rows Astro, @astrojs/starlight | versions from B3 (today `astro` is `6.4.6`, while the doc says `6.4.4`) |
| same table, rows astro-mermaid, marked, sanitize-html | delete each row whose package is absent from B3 (FR-11 removes all three) |
| same table, new row after @astrojs/starlight | block K9, first row |
| § Build Commands, the `npm ci && npm run build` line | `npm ci && npm run build    # 'build' = 'astro build'; nothing is generated or fetched at build time` |
| § Lint Commands, `npm run check` and its CONFIRMED clause | keep only if B2 has `check`; otherwise delete the comment line, the command line, and the clause "and `site/package.json` (search: `"check": "astro check"`)" |
| § Test Commands, the comment `# Site data tests — from site/` and the `npm test` line under it | block K9, the three lines after the rows |
| § Key Dependencies, site rows (astro, typescript, vitest, yaml override) | each version from B3; a row whose package or override is gone is deleted; add block K9, second row |

```markdown
K9
| **axe-core** | **{B3}** (site dev dep) | Accessibility rule engine for the site's checks on built pages. CONFIRMED `site/package.json`. |
| axe-core | {B3} | `site/` dev | Site accessibility checks. |

# Site suite — from site/ (build, internal links, facts check, accessibility and structure)
npm test                          # = '{B2 test}'
node scripts/gen-facts.mjs --check   # facts only; needs no npm ci
```

*`infrastructure.md`*

| Where | Replacement |
|---|---|
| the workflow table, the row whose first cell is `.github/workflows/docs.yml` | block K10 |
| § The Documentation Site, the whole paragraph | block K11 |

```markdown
K10
| `.github/workflows/docs.yml` | push **and PR** to `master`, path-filtered to `site/**`, `canonical/**`, `VERSION` (or `workflow_dispatch`) | Facts check (`gen-facts.mjs --check`) + site test suite + Astro build on both; deploy to GitHub Pages on push (unless `DOCS_DEPLOY_PAUSED` is `'true'`) or `workflow_dispatch` |
```

K11:

> A standalone Astro Starlight site under `site/` (separate build, own `package.json` / `node_modules` /
> `dist/`), deployed to **GitHub Pages at https://aid.casuloailabs.com**. `docs.yml`'s `build` job runs
> `node site/scripts/gen-facts.mjs --check` → `npm ci` → **`npm test` (the site suite)** → `npm run build`,
> then `deploy` publishes via `actions/deploy-pages`. No step after `npm ci` uses the network: the
> version the site shows is read from the repo-root `VERSION` file at build time (`{B4}`), and the
> changelog page links to the GitHub Releases page instead of fetching it. The test step is the point,
> not a detail: it makes `docs.yml` the site's **pull-request gate**, since the same job runs on
> `pull_request` to `master`. It is decoupled from `release.yml`. Pages deploys only from `master` (push
> or manual `workflow_dispatch`) — the `github-pages` environment permits master-ref deploys only, so a
> tag/release ref is rejected. A push deploys only while the repository variable `DOCS_DEPLOY_PAUSED` is
> not `'true'`; setting it keeps docs for unreleased work on master from going live before the release
> that installs it, while the push still builds and tests the site. A manual `workflow_dispatch` always
> deploys. CONFIRMED in `.github/workflows/docs.yml`.

*`integration-map.md`*

| Where | Replacement |
|---|---|
| the integrations table, the row whose first cell is GitHub `gh` CLI | Notes cell: "`release.sh` cuts/uploads releases" (drops "site fetches release data") |
| § GitHub (gh CLI, Releases, Actions), the `gh` CLI paragraph | delete the sentence "The site's `gen-reference.mjs` also shells out to `gh`." and the trailing "; `site/scripts/gen-reference.mjs`" of its CONFIRMED line. That sentence was already false: the script never called `gh`. |
| same section, the row whose first cell is `docs.yml` (Docs) | Trigger cell: "push + PR to `master` under `site/`, `canonical/`, `VERSION`". Purpose cell: "checks the site facts, tests and builds the Astro site (both events); deploys on push only". |
| same section, the sentence "its `build` job runs the site vitest suite plus the build, so a PR touching `site/`, `docs/`, `canonical/` or `VERSION` is gated on it" | "its `build` job runs the facts check, the site test suite and the build, so a PR touching `site/`, `canonical/` or `VERSION` is gated on it" |

*`tech-debt.md`*

| Where | Change |
|---|---|
| third Debt Inventory table, rows **W1-1**, **W1-3**, **W1-5**, **W1-6**, **W1-7**, **W1-8**, **W1-12**, **W1-13**, **W1-14**, **W1-15**, **W1-17** | delete (G-03). Each one describes code or a dependency that Feature 005 removes: astro-mermaid, the ELK layout, the flow extractor, the curated roster, the node panel, and the drift-guard test. Before deleting, confirm that the cited thing is gone: `git ls-files site \| grep -E "flow-graph\|curated-roster\|skill-node-panel\|gen-skills"` prints nothing, and `astro-mermaid` and `@mermaid-js/layout-elk` are absent from B3. Rows W1-9, W1-10, W1-11 and the ID-rule note rows stay unchanged; W1-2 stays, edited (next row). |
| same table, row **W1-2** | its debt (hand-measured shape populations in `module-map.md` § Skill Structural Shapes) is still true, but its remedy names a generator Feature 005 deletes. Replace the whole sentence from "The live figures belong in the generator's `shapeCounts` manifest entry" through "or lose its numbers." (the row's only mention of `gen-skills`, so the step-6 sweep then prints nothing for it) with: "The figures should be derived from a scan of `canonical/skills/` when the section is next edited, or dropped from the prose." |
| first Debt Inventory table, row **L9** | if B5 is not 0 (the expected case: Feature 003 puts `<Pipeline />` on the home page), replace it with block K12. If B5 is 0, delete the row. Either way, the parser half of L9 (`parseFlow` and its suite) is resolved, because Feature 005 deletes it. |
| the whole subsection `### Skill Explorer — open known issues`, from its heading to the line before `## Detailed Debt Items` | delete. Its subject is deleted. The rows it introduced are deleted above or keep their own text, and the rest of it is closure prose for resolved items, which G-03 forbids. |
| § Missing Test Coverage, the row whose first cell is "Astro site components" | block K13 |
| § Gotchas, the bullet starting "**Master-only heavy gates — with one exception that matters.**", from "**`docs.yml` is NOT master-only.**" to its end | "**`docs.yml` is NOT master-only.** It triggers on `push` *and* `pull_request` to `master`, both path-filtered to `site/**`, `canonical/**`, `VERSION` or the workflow itself, and its `build` job runs **`node site/scripts/gen-facts.mjs --check`, `npm test` (the site suite) and the Astro build**. Only the `deploy` job is master-only. It has **no `release:`/tag trigger at all** — the `github-pages` environment rejects a non-master ref, so a manual re-deploy is a `workflow_dispatch` on master. Two consequences. A **`canonical/`-only** commit still runs the job, and fails it when the committed site pages were not regenerated (`node site/scripts/gen-facts.mjs`). And a PR touching those paths is genuinely gated on the site suite." |
| first Debt Inventory table, new row after **W5-23** | block K14. The id follows the table's own ID rule: the highest `W5-` id in the document is W5-23. |

```markdown
K12
| **L9** | Unguarded drift | **Nothing checks the repo-root README's mermaid diagram against the site home page's pipeline diagram.** They answer different questions (README's is a "Start Here" onboarding flow; the home page shows the technical pipeline), so they share no topology. They must share vocabulary, though: a phase or skill renamed in one and not the other is a plain error, and nothing notices it. | `README.md` (the mermaid block); `site/src/content/docs/index.mdx` (the `Pipeline` diagram component, `site/src/components/diagrams/Pipeline.astro`) | **Low** | S | **P3** |

K13
| Astro site | build, link, facts, accessibility and structure checks on built pages | unit tests of components (none, by design) | Low — the site holds little logic of its own; the page checks cover what readers see |

K14
| **W5-24** | Stale pointers to removed site scripts, outside `site/` | **Files outside `site/` still describe site machinery that no longer exists, and each is a pointer an agent follows.** `.claude/skills/generate-profile/SKILL.md` derives the skill counts by importing the site's old skill-count helper modules, which are deleted, so that documented command now fails. The comment above `alias_of` in `canonical/aid/templates/shortcut-catalog.yml` names the same deleted helpers as consumers of that field. `canonical/skills/aid-execute/references/state-fix.md` names a copy step from `docs/` into the site that no longer runs. `.claude/skills/release-aid/SKILL.md` says the changelog page is sourced from GitHub Releases. `docs/diagram-content-reference.md` tells maintainers to run the deleted docs-copy script and lists Mermaid blocks on site pages. Fix each at its source; for `canonical/`, resync afterwards. | `.claude/skills/generate-profile/SKILL.md`; `canonical/aid/templates/shortcut-catalog.yml`; `canonical/skills/aid-execute/references/state-fix.md`; `.claude/skills/release-aid/SKILL.md`; `docs/diagram-content-reference.md` | **Medium** | S | **P2** |
```

K14 names only files that exist; the deleted helpers and scripts are described in words, so the KB
holds no dead path and the step-6 sweep needs no exclusion for it. Before writing W5-24, confirm that it
is still true. This command must list exactly the files in the row's location cell (it lists all of them
at Specify, on the base commit):

```
git grep -lE "skill-counts\.mjs|sync-docs|sync:docs|changelog\.astro" -- ':!site' ':!.aid/knowledge' ':!.aid/works' ':!profiles' ':!.agents' ':!.claude/skills/aid-*' ':!.aid/runtime'
```

`test -e site/scripts/skills/skill-counts.mjs` must fail. Drop any file from the row (its sentence and its
location entry) that no longer matches.

*`domain-glossary.md`*, § Lexicon — UI Components and Identity:

| Row | Change |
|---|---|
| `VersionBadge` | keep if B6 says the file exists; otherwise delete |
| `CardGrid / Card Grid` | its Source cell names `site/.astro/data-store.json`, a file that is not in the repository. If B6 lists a page using `CardGrid`, set Source to that page's path; otherwise delete the row. |
| `PipelineDiagram` | replace with block K15. No `PipelineDiagram` component exists, and the row's only source is a test that Feature 005 deletes. |

*`PROJECT.md`* (type `kb-card`; PC-01 limits it to about 60 lines, and it has 52 today):

| Where | Addition |
|---|---|
| § Commands, after the "Build" line | block K16 |

```markdown
K15
| Diagram | Site component rendering a static, accessible SVG diagram with a visible caption and a text equivalent (list or table) | `{B7}` |

K16
- Site facts (after a `canonical/` skill, agent or settings change): `node site/scripts/gen-facts.mjs`; check: `node site/scripts/gen-facts.mjs --check`; site tests: `cd site && npm ci && npm test`
```

This addition goes beyond correcting statements. It is included because the facts script adds a new
duty to every `canonical/` change: before this work the build regenerated those pages, and now a person
must run the script. A duty that is missing from the card is a trap (KB-13), and the card is the one
page every session reads. **Owner decision (recorded here): the command line is added; no new
"Rules that never bend" rule 9 is added**, because the `docs.yml` check step already enforces the duty
and the module-map and test-landscape text record it.

**Work-folder layer.** Fill `.aid/works/work-005-site-rework/site-audit.md` § Knowledge Base documents edited
(FR-10). Expected rows, each with Status `done`:

| Document | Statement made true |
|---|---|
| `test-landscape.md` | The site suite, its CI lane and its commands describe the facts check plus the four test groups, with no generators, no fetch and no `docs/**` filter. |
| `module-map.md` | The site depends on `canonical/` through `gen-facts.mjs`, checked by `--check`, not through build-time generators. |
| `architecture.md` | The website entry point and the CI gotcha name the facts script and the PR-gated site job. |
| `project-structure.md` | The site's tree, purpose, entry point, test folders and structure note match the simplified site. |
| `technology-stack.md` | The site's languages, frameworks, commands and dependencies match `site/package.json`. |
| `infrastructure.md` | The Docs workflow row and the site section describe a build with no network step. |
| `integration-map.md` | The site no longer uses `gh` or GitHub release data, and the Docs workflow row matches its filters. |
| `tech-debt.md` | Debt rows about removed site code are deleted, L9 is updated, and stale pointers outside `site/` are recorded as W5-24. |
| `domain-glossary.md` | The site component terms name components that exist. |
| `PROJECT.md` | The card gives the site facts and test commands and the regeneration rule. |

Add an `INDEX.md` row only if Feature Flow step 7 required regenerating it.
