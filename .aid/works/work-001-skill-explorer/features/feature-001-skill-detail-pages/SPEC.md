# Skill Detail Pages


> **§7 AMENDED — read before the §7 references below (2026-07-30, delivery-006).**
> This document was authored while REQUIREMENTS §7 froze `gen-reference.mjs`. The **second
> amendment to §7** (work-level Q4, recorded at `REQUIREMENTS.md` § Constraints) lifted that
> freeze so delivery-006 could **hollow out** `reference/skills.md` — shedding the duplicated
> roster and keeping only the shortcut-engine narrative. Every "§7 freezes/forbids" and "terse
> family summary" statement below was TRUE WHEN WRITTEN and is kept as the design record; none
> of them describes the repository today. What replaced the freeze is a bound, not a free hand:
> `agents.md`/`kb.md`/`settings.md` byte-unchanged, all 111 skill detail pages and sidecars
> byte-unchanged, generator idempotent — see `deliveries/delivery-006/BLUEPRINT.md § Gate
> Criteria`. The grouping divergence this document reasons about did not vanish; it moved from
> a competing PAGE to the curated roster, and is now derived rather than hard-coded (KI-010).

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §4, §5 (FR-1), §6 (NFR-4), §7, §9 (AC-1/2/6) | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |
| 2026-07-25 | Review fix round 1 — OQ-1 closed (test + CI fixes in scope), body-slot range and generatedFrom attribution corrected | /aid-specify |

## Source

- REQUIREMENTS.md §4 Scope (delivery vehicle, coverage), §5 FR-1, §6 NFR-4, §7 Constraints,
  §9 AC-1, AC-2, AC-6

## Description

Every skill in `canonical/skills/` gets its own published page under a new `/skills/` section
of the docs site, generated at build time by a sibling of `gen-reference.mjs` that follows the
same conventions: reads `canonical/` only, stamps "generated — do not edit", records a
manifest, throws when the generated page set diverges from the on-disk skill set, and runs from
`prebuild`/`predev`.

The page header renders the skill's frontmatter **completely** — every key present in that
`SKILL.md`, including list-valued keys such as `allowed-tools` that the existing minimal parser
drops — so the page is a faithful front matter of the source. The body is a slot at this stage;
features 003 and 004 fill it.

This feature also carries the standing constraint that the existing `gen-reference.mjs` drift
guard, the four existing reference pages, and the vitest suites keep passing untouched.

## User Stories

- As an **AID maintainer**, I want a stable per-skill URL that shows me a skill's declared
  contract (name, description, allowed-tools, argument-hint, and anything else it carries) so I
  can check a skill's surface without opening `canonical/`.
- As a **contributor**, I want a new skill I add to `canonical/skills/` to appear on the site
  automatically so I never have to remember a second place to register it.
- As an **AID maintainer**, I want the build to fail loudly if the page set and the skill set
  disagree, so the catalog can never silently rot.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-1 — Coverage.** Given every directory under `canonical/skills/`, when the generator
      runs, then each has a generated detail page; and when the generated page set diverges
      from the on-disk skill set, the generator throws (same guard shape `gen-reference.mjs`
      already applies).
- [ ] **AC-2 — Header completeness.** Given a skill's `SKILL.md`, when its detail page is
      rendered, then every frontmatter key present in that file appears in the header; no key
      is silently dropped.
- [ ] **AC-6 — Idempotence.** Given an unchanged `canonical/`, when the generator runs twice in
      succession, then the output is byte-identical.
- [ ] **Build integration (REQUIREMENTS.md §7, amended 2026-07-25).** Given the existing site
      build, when this feature lands, then all four of the following hold:
      **(a) existing behaviour preserved** — `gen-reference.mjs` is byte-unmodified, its
      throw-on-drift guard still passes, and its four generated reference pages are byte-unchanged
      after a full `prebuild`;
      **(b) stale assertions corrected** — every stale roster assertion in
      `site/scripts/__tests__/gen-reference.test.mjs` is replaced by a check derived from
      `canonical/skills/` and `shortcut-catalog.yml`, so the file carries no hard-coded corpus
      count (§8);
      **(c) suite green** — `npm test` in `site/` exits 0 on a clean `npm ci` install, for the
      whole suite and not only the corrected file;
      **(d) suite running in CI** — `.github/workflows/docs.yml`'s `build` job runs that suite, so
      a red suite fails the pull request.
      Scope and the exact assertions are specified under
      [Build-integration scope](#build-integration-scope-amended-7).

---

## Technical Specification

> Scope note: this feature builds the **generator harness** that features 002–006 extend.
> Everything under "Generator harness contract" below is a published interface those SPECs
> are written against; changing it is a cross-feature change, not a local one.

### Data Model

**No schema changes.** This feature adds no database, no persisted record type, and no change
to the Astro content-collection schema.

Specifically, `site/src/content.config.ts` is **not modified**. The generated pages reuse the
`generatedFrom` optional field the `docsSchema` extension already declares, plus Starlight's
built-in `title` and `description`. No new `zod` field is required.

> **Read the comment on `content.config.ts:14` carefully.** It says
> `// feature-006: generated reference pages provenance`. That is **a previous work's
> feature-006** — the delivery that built the site's generated reference pages — and **not this
> work's feature-006**, which is the interactive node panel and touches neither this file nor
> this field. The two are unrelated despite the identical label. The same collision appears on
> lines 12 and 16 of that file (`feature-005`, `feature-006`) and in `astro.config.mjs`'s
> reserved-slot comments (`feature-008`/`009`/`010`): every `feature-NNN` reference inside
> `site/` numbers a **previous** work's features, never this one's.

The only new persisted artifact is a build manifest JSON (`.skills-manifest.json`), whose shape
is specified under [Manifest contract](#manifest-contract). Its schema deliberately mirrors
`site/scripts/.reference-manifest.json` rather than inventing a second shape.

Two in-memory shapes are introduced and are part of the harness contract — `Field` and
`SkillRecord`, specified under [The `SkillRecord`](#the-skillrecord).

### Feature Flow

Generation is a **pure build-time transform**: `canonical/skills/**` in, markdown pages +
manifest out. There is no request path, no service, and no runtime component.

```
npm run build            (or npm run dev)
  └─ prebuild / predev   (package.json, single chained line)
       ├─ sync:docs          → docs/*.md            → src/content/docs/{concepts,reference}/*.md
       ├─ gen:reference      → canonical/ + settings → src/content/docs/reference/{4 pages}.md
       ├─ gen:skills   ← NEW → canonical/skills/*   → src/content/docs/skills/<skill>.md  (one per dir)
       └─ fetch:release      → VERSION + GH API     → .release-data.json
  └─ astro build
       └─ docsLoader() picks up src/content/docs/** (incl. the new skills/ pages)
       └─ astro-mermaid transforms ```mermaid fences  (consumed later by features 003/004)
       └─ Pagefind indexes the new pages
```

Inside `gen:skills`, one pass, in this fixed order:

```
1. DISCOVER   readdirSync(canonical/skills) → directory names, .sort()
2. PARSE      per directory: read SKILL.md, parse frontmatter → Field[] (source order)
                 ├ throw on: missing SKILL.md, missing/unterminated frontmatter fence,
                 │           unclassifiable line, duplicate key, `name` ≠ directory name
3. RECORD     build SkillRecord[] (fields + body text + line anchors + paths)
4. RENDER     per record: page frontmatter + generated marker + Frontmatter section
                          + body slot (empty in this feature)
5. WRITE      mkdir -p src/content/docs/skills/ ; writeFileSync each page (utf8, LF)
6. MANIFEST   write scripts/.skills-manifest.json
7. GUARD      compare {on-disk skill dirs} vs {pages written} vs {*.md now on disk}
                 └ throw on either mismatch  (AC-1)
```

The guard runs **after** the write so it also sees pages left over from a deleted skill. A
failure is an uncaught `throw`, so the process exits non-zero, `npm run build` fails, and the
`docs.yml` pull-request build gate (which runs on PRs to `master` touching `site/**`) goes red.

### Layers & Components

This is a scripts-only feature. It adds no Astro component, no page route file, no style, and
no client-side JavaScript. Everything lives under `site/scripts/`.

#### Module layout

`site/scripts/` today is flat: `sync-docs.mjs`, `gen-reference.mjs`, `fetch-release-data.mjs`,
plus `__tests__/`. This feature keeps the **entrypoint flat** (so it reads as a peer of its
three siblings) and puts the cluster's internals in a namespaced subdirectory, because features
003–005 will add roughly six more modules here (shape classifier, two extractors, engine
derivation, well-formedness validator, provenance builder). Feature-006 adds nothing to this
cluster — it is browser-side, not build-side.

| File | Owner | Purpose |
|------|-------|---------|
| `site/scripts/gen-skills.mjs` | feature-001 | Entrypoint. Header block, `main()`, guards, manifest write. Mirrors `gen-reference.mjs`'s shape. |
| `site/scripts/skills/frontmatter.mjs` | feature-001 | `parseSkillFrontmatter()` — the complete parser (see below). No other module parses YAML. |
| `site/scripts/skills/discover.mjs` | feature-001 | Enumerates `canonical/skills/`, builds `SkillRecord[]`. |
| `site/scripts/skills/render-page.mjs` | feature-001 | Assembles one page: page frontmatter → marker → Frontmatter section → body slot. |
| `site/scripts/skills/render-value.mjs` | feature-001 | `renderFrontmatterValue()` — the code-span-aware escaper (see below). |
| `site/scripts/skills/body.mjs` | feature-001 (seam) | `renderSkillBody()` + the `BODY_PROVIDERS` / `BODY_APPENDERS` registries. Ships empty. **Features 003–005 extend this file only** — 003/004 add a `BODY_PROVIDERS` entry each, 005 adds a `BODY_APPENDERS` entry. **Feature-006 has no entry here**: it ships browser JavaScript, not page markdown, so it attaches at the site level (see [Output contract](#output-contract)). |
| `site/scripts/skills/paths.mjs` | feature-001 | Repo-root resolution + the POSIX path builders + `GITHUB_BLOB_BASE`. |
| `site/scripts/.skills-manifest.json` | feature-001 (generated) | Build manifest. |
| `site/scripts/__tests__/gen-skills.test.mjs` | feature-001 | vitest suite. Mirrors `gen-reference.test.mjs`'s organisation. |

Conventions followed, per `coding-standards.md` §JavaScript / Node and the three sibling
scripts: ESM `.mjs`, `#!/usr/bin/env node`, `node:`-prefixed builtins only, kebab-case
filenames, a `Purpose / Usage / Wired as / Exit codes` header block on the entrypoint, results
to stdout and diagnostics to stderr, failure via non-zero exit.

Two deliberate divergences, both recorded:

- **Indentation is 2 spaces, not tabs.** `coding-standards.md` records a tab rule for `.mjs`,
  but that rule was mined from `canonical/aid/scripts/summarize/*.mjs`. Every file in
  `site/scripts/` is space-indented; matching the directory you are in beats matching a rule
  derived from a different directory.
- **The modules export pure functions and only the entrypoint has a side effect at import
  time.** `gen-reference.mjs` calls `main()` unconditionally at module scope, which is why its
  test suite can only exercise it by shelling out with `execSync`. `gen-skills.mjs` instead
  follows `fetch-release-data.mjs`'s guard —
  `if (import.meta.url === pathToFileURL(process.argv[1]).href) main()` — so the parser, the
  value renderer and the page renderer are directly unit-testable. This is what makes AC-2
  testable at fixture granularity rather than by grepping the whole rendered corpus.

#### npm wiring

Add one script key and thread it into both existing chains:

```json
"gen:skills": "node scripts/gen-skills.mjs",
"prebuild": "npm run sync:docs && npm run gen:reference && npm run gen:skills && npm run fetch:release",
"predev":   "npm run sync:docs && npm run gen:reference && npm run gen:skills && npm run fetch:release"
```

This is the **only** edit to `package.json`, and it is additive. The existing assertions in
`gen-reference.test.mjs` — that `prebuild` contains `sync:docs`, contains `gen:reference`,
contains `&&`, and that the file has exactly one `"prebuild"` key — all still hold.

`gen:skills` runs **after** `gen:reference`: the two write disjoint outputs and neither reads
the other's, so ordering is a diagnostics choice — the older, better-understood drift error
should be the first one a maintainer sees. It runs **before** `fetch:release` because
`fetch:release` reaches the network and should stay last in the chain.

No new dependency. `yaml` is **not resolvable** from `site/` — it appears only under
`overrides`, which constrains transitive resolution and neither declares nor installs it
(`import('yaml')` from `site/` fails `ERR_MODULE_NOT_FOUND`) — so the parser is hand-rolled,
which is what §7 requires and what all three sibling scripts already do.
Node is pinned at 22 by `site/.nvmrc` and `>=22.12.0` by `engines`.

#### Build-integration scope (amended §7)

*Added at review fix round 1.* REQUIREMENTS.md §7 was amended by owner decision on 2026-07-25:
the site vitest suite must be **green and running in CI** by the end of this work, and both
remedies land in feature-001 because it owns build integration. `gen-reference.mjs` itself stays
frozen — everything below touches a **test file** and a **workflow file** only.

##### Part A — correct the stale roster assertions

The reviewer's finding named two assertions. **There are more, in the same class**, and a
two-number swap would leave the suite red. The full inventory of stale roster state in
`site/scripts/__tests__/gen-reference.test.mjs`, each verified against the tree on 2026-07-25:

> The figures in the "Measured reality" column are **dated diagnostics, not a contract, and must
> not be transcribed into the test.** They exist to show which items are stale and why a numeric
> swap is insufficient. §8 forbids hard-coding a corpus count, so the corrected assertions
> specified below carry no literal at all — they re-derive from source on every run.

| # | Location | Stale content | Measured reality |
|---|----------|---------------|------------------|
| 1 | `:101-116` `CURATED_SKILL_NAMES` | 18 names; comment describes "16 classic + `aid-triage`" and "the remaining … 76 catalog-driven shortcuts" | The generator's `SKILL_GROUPS` curates **21**. The three the constant is missing are exactly `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket`. |
| 2 | `:119` `it(...)` title | "94 on-disk skill dirs = 18 curated sections + 76 catalog shortcuts" | The arithmetic no longer holds in any form — the page renders 21 individual sections and a 64-row family table, and the remainder is deliberately unlisted. |
| 3 | `:123` `expect(skillDirs).toHaveLength(94)` | 94 | 111 directories. **Fails today.** |
| 4 | `:126` `expect(shortcutDirs).toHaveLength(76)` | 76 | 90 with the corrected roster (93 with the stale one). **Fails today, and the reviewer's ledger did not name it** — it is masked because assertion 3 short-circuits the `it` block first. |
| 5 | `:132` `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)` | Resolves to 18 | The page renders **21** `` ### `aid-…` `` sections. **Latent** — masked by 3, and repaired for free once item 1 is corrected. |
| 6 | `:138-139` comment | "the 76 catalog rows that emit a skill directory (80-row catalog minus 4 `repurpose: true` rows)" | The catalog has 94 rows, 30 of them `repurpose: true`, so 64 emit. |
| 7 | `:140` — the `toMatch` regex over the family table's `**Total**` row | Hard-codes `76` | The page's Total row reads 64. **Fails today.** |
| 8 | `:135` `it(...)` title | `'skills.md: has a "Direct-entry shortcuts" section totalling all 76 shortcuts'` — hard-codes `76` in the title string | The family table totals **64**. Cosmetic only (a description string, not an assertion), so it does not affect pass/fail — but it is the same stale inventory and must not be left behind. |

So three assertions fail now, one more fails the moment the first is fixed, and one constant plus
two comments and **two titles** (`:119` and `:135`) are wrong. **Correct all eight together** —
fixing only the two named in the ledger produces a still-red suite and a second review round.

**Replace literals with source-derived checks, do not swap the numbers.** §8 forbids hard-coded
counts, and a hard-coded count is precisely the defect that produced KI-005; swapping `94`→`111`
and `76`→`64` would re-arm the same trap for the next contributor who adds a skill. The test
should re-derive its expectations from the same two sources the generator derives its own from —
the `canonical/skills/` directory listing and `shortcut-catalog.yml`:

```js
// Local 10-line catalog reader mirroring gen-reference.mjs's two row/field regexes
// (`/^  - name:\s*(.+)$/`, `/^    ([a-zA-Z_]+):\s*(.*)$/`) and its scalar strip.
// Re-implemented, NOT imported: gen-reference.mjs runs main() at module scope, so
// importing anything from it would execute the other generator.
const catalogRows   = parseCatalogRows(readFileSync(SHORTCUT_CATALOG_FILE, 'utf8'));
const catalogNames  = catalogRows.map((r) => r.name);
const emittingNames = catalogRows.filter((r) => r.repurpose !== 'true').map((r) => r.name);
```

| Replaces | Derived assertion | Invariant it pins |
|----------|-------------------|-------------------|
| `:123` | `expect(catalogNames.filter((n) => !skillDirs.includes(n))).toEqual([])` | Every catalog row has a directory on disk. |
| `:126` | `expect(shortcutDirs.slice().sort()).toEqual(catalogNames.filter((n) => !CURATED_SKILL_NAMES.includes(n)).slice().sort())` | Every non-curated directory is catalog-backed, and vice versa — set equality, no count. |
| — (new) | `expect(CURATED_SKILL_NAMES.filter((n) => !skillDirs.includes(n))).toEqual([])` | No curated name has lost its directory. |
| — (new, **the clamp**) | `expect(skillDirs.filter((d) => !catalogNames.includes(d) && !CURATED_SKILL_NAMES.includes(d))).toEqual([])` | No hand-authored skill exists that the roster does not know about. |
| `:132` | unchanged — `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)` | Correct once item 1 lands, and kept correct by the clamp. |
| `:140` | see the snippet below — the count in the regex becomes `emittingNames.length` | The family total equals the count of non-`repurpose` catalog rows. |

The `:140` replacement, kept out of the table above because its regex contains a pipe:

```js
const totalRow = skillsContent.split('\n').find((l) => l.includes('**Total**'));
expect(totalRow).toMatch(
  new RegExp(String.raw`\*\*Total\*\*\s*\|\s*\*\*${emittingNames.length}\*\*`)
);
```

**The clamp is the anti-staleness mechanism, and it is the point of this rework.** Adding the
three ticket skills is what silently broke this file; with the clamp in place that same change
fails with a message naming `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket` instead of
drifting unnoticed. `CURATED_SKILL_NAMES` stays an explicit hand-maintained list — *which skills
get their own section* is a curatorial choice living in `SKILL_GROUPS`, not a filesystem fact, so
deriving it would only make the test tautological with the generator — but it is now self-policing
rather than trusted.

Both `it` titles and both comments must lose their embedded numbers; describe the invariant
("every catalog row has a directory", "the family total matches the catalog's emitting rows")
rather than a quantity.

**Recommended, not required, while in the file:** `:137`'s
`expect(skillsContent).toContain('## Direct-entry shortcuts')` passes only as a *substring* of the
actual `### Direct-entry shortcuts` — the generator nests that section at H3
(`generateShortcutFamiliesSection(catalog, 3)`). Tightening it to `'### Direct-entry shortcuts'`
removes a false positive one line above an assertion already being edited.

##### Part B — run the suite in CI

`.github/workflows/docs.yml`'s `build` job currently runs `npm ci` then `npm run build` and
nothing else. Insert one step **between** them:

```yaml
      - name: Install deps (reproducible)
        working-directory: site
        run: npm ci

      - name: Test (site vitest suite)          # ← NEW
        working-directory: site
        run: npm test

      - name: Build Astro Starlight site
        working-directory: site
        # env: unchanged (AID_VERSION / AID_LATEST_RELEASE_JSON / AID_RELEASES_JSON)
        run: npm run build
```

- **After `npm ci`** because `vitest` is a devDependency and does not exist before it.
- **Before `npm run build`** to fail fast: the suite runs in seconds, the Astro build does not,
  and a red suite should never produce a Pages artifact. Rejected: placing it after the build
  (slower feedback, and it would let a broken suite ship an artifact on a `workflow_dispatch`).
- **No trigger change is needed.** The `build` job already runs on `push: master` **and**
  `pull_request: master` with a `site/**` path filter, so the step gates pull requests
  automatically. The `deploy` job's `if: github.event_name != 'pull_request'` is untouched.
- **Deliberately no `env:` block on the test step.** The build step exports `AID_VERSION` /
  `AID_LATEST_RELEASE_JSON` / `AID_RELEASES_JSON`; the test step should not, so the suite
  exercises the `.release-data.json` fallback path deterministically rather than a CI-only
  environment. `site/.release-data.json` already exists by then — `fetch-release-data.mjs` runs
  earlier in the job, before `npm ci`, and needs no dependencies. Note that
  `src/data/__tests__/ac13-version-injection.test.ts` sets and restores `process.env.AID_VERSION`
  itself, so inheriting a workflow value would fight its own fixture.

##### Part C — verify before wiring, and a residual risk to close

**`npm test` must be confirmed green on a complete install before Part B lands**, because Part A
fixes only what is provably stale in one file, and no CI run has ever exercised the other seven.
Two categories of noise will appear on a first local run and must not be mistaken for defects:

- **Five TypeScript suites report `[TSCONFIG_ERROR] Tsconfig not found`** and load zero tests
  (`src/lib/__tests__/*.ts`, `src/data/__tests__/*.ts`). Cause: `site/tsconfig.json` does
  `"extends": "astro/tsconfigs/strict"`, which esbuild cannot resolve when `node_modules/astro`
  is absent. Confirmed **environmental**: that directory is missing from this work's git worktree
  but present in the main checkout, where `astro/tsconfigs/` resolves. A clean `npm ci` fixes it;
  CI always runs `npm ci`.
- **Two `git diff`-based idempotency tests fail** (`gen-reference.test.mjs`,
  `sync-docs.test.mjs`). Cause: this worktree's `.git` file points at a WSL path that Windows
  `git` rejects. Confirmed **environmental and not a generator defect** — re-running both
  generators left every tracked output byte-identical. Both pass wherever `git` resolves the
  checkout, which CI's `actions/checkout` guarantees.

**Residual risk, stated rather than assumed:** because those five TypeScript suites have never
run in CI and cannot load in this worktree, their assertions are **unverified**. Part A's
inventory is complete for `gen-reference.test.mjs`, but the five TS suites may surface further
staleness of the same kind once they can load. Whoever implements this must run the full suite on
a clean `npm ci` install **first**, triage anything beyond the seven items above, and only then
add the CI step — otherwise Part B turns an invisible problem into a permanently red pipeline.
Anything found there is new information for the plan, not silent scope for the implementer.

---

#### Generator harness contract

Everything from here to "Body slot" is the interface features 002–006 consume.

##### Route and path derivation

| Thing | Value |
|-------|-------|
| Section root | `/skills/` — index page owned by **feature-002** at `src/content/docs/skills/index.md` |
| Detail route | `/skills/<dir>/` |
| Detail source | `site/src/content/docs/skills/<dir>.md` |
| Derivation | **identity** — the `canonical/skills/` directory name *is* the slug |

Verified across every directory under `canonical/skills/` (measured 2026-07-25): all names match
`^[a-z0-9]+(-[a-z0-9]+)*$`, all carry the `aid-` prefix, there are no case collisions, and every
directory's frontmatter `name` equals its directory name (zero mismatches). Identity derivation
therefore needs no slugification step — and *must not* have one, because a lossy slugifier is how
two skills silently collide onto one page. The generator instead **throws** if a directory name
fails that pattern, so the day a non-conforming name appears it is a build error rather than a
lost page.

`name` ≠ directory name is likewise a throw: the page's identity, feature-002's card keying, and
feature-005's source links all assume they agree.

Rejected: deriving the slug from the frontmatter `name`. It is the same string today, but it is
authored text rather than a filesystem fact, so the drift guard (which reads directories) and the
page set could disagree without either being wrong.

##### Output contract

Each page is a **`.md`** file, not `.mdx`. Three reasons, all measured against the actual corpus:

1. Skill frontmatter values contain `{`/`}` (`aid-describe`'s description carries
   `{greenfield: ... ->}`), which MDX parses as a JSX expression. Feature-005 will additionally
   put *verbatim* prompt fragments on these pages, where braces are common.
2. All four existing generated reference pages are `.md`; `.mdx` in this repo is reserved for
   hand-authored pages that import components.
3. `astro-mermaid` transforms fenced `mermaid` code blocks in plain markdown, so features 003/004
   need nothing MDX gives them.

Consequence handed to **feature-006**: because these are `.md`, per-page component imports are
not available. Its custom JavaScript must arrive through a site-level mechanism — a Starlight
component override or a `head` entry in `astro.config.mjs` — scoped to the `/skills/` route.

Page shape (in order):

```markdown
---
title: 'aid-create-api'
description: 'Direct-entry Lite-path shortcut (Create an API endpoint / middleware …'
generatedFrom: 'canonical/skills/aid-create-api/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-create-api/SKILL.md -->

## Frontmatter

- **`name`** — aid-create-api
- **`description`** — Direct-entry Lite-path shortcut (…) …
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — [description]  -- what to create; …

[Definition: `canonical/skills/aid-create-api/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-api/SKILL.md)

<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->
```

- The **generated marker** is byte-for-byte the same sentence the four existing pages carry —
  `<!-- generated — do not edit; source: … -->` — with the em-dash, so the existing suite's
  `toContain('generated — do not edit')` idiom transfers unchanged to the new suite.
- Page `title` is the directory name. Page `description` is the **first sentence** of the skill's
  `description` field (text up to and including the first `. `), hard-cut at the last word
  boundary ≤ 157 characters with a trailing `…` if longer, falling back to
  `AID skill <dir> — declared frontmatter contract, generated from canonical/.` when the skill
  carries no `description`. Rejected: emitting the whole `description` — the longest is 1096
  characters (`aid-update-ticket`) and it becomes the page's `<meta name="description">`.
- Page frontmatter is serialized in the siblings' single-quoted style with `'` → `''` escaping
  (`serializeFrontmatter` in both `gen-reference.mjs` and `sync-docs.mjs`). That helper is
  re-implemented in `skills/render-page.mjs`, not imported — `gen-reference.mjs` runs `main()`
  on import, so importing anything from it would run the other generator. Accepted duplication,
  forced by §7's "do not modify the existing generator".
- **No `sidebar:` key is emitted.** That slot is reserved for **feature-002**, in the same spirit
  as `astro.config.mjs`'s reserved `components:` slots.
- The `[Definition: …]` source link uses the same `GITHUB_BLOB_BASE`
  (`https://github.com/AndreVianna/aid-methodology/blob/master`) literal `gen-reference.mjs`
  uses, redeclared in `skills/paths.mjs`. **Feature-005** builds its `#L<a>-L<b>` deep links on
  this same constant.

##### Manifest contract

`site/scripts/.skills-manifest.json` — sibling of `.reference-manifest.json` and
`.synced-manifest.json`, and like them it lives in `scripts/`, **outside** the content-collection
root so `docsLoader()` never sees it. Same three-key shape:

```json
{
  "generator": "site/scripts/gen-skills.mjs",
  "entries": [
    { "src": "canonical/skills/aid-add/SKILL.md",
      "dest": "site/src/content/docs/skills/aid-add.md" }
  ],
  "generatedPaths": ["site/src/content/docs/skills/aid-add.md"]
}
```

- `entries` is ordered by `src`, ascending — the same order as the sorted directory scan.
- **No `generatedAt` field**, and no wall-clock value anywhere. The existing suite asserts this
  absence explicitly as a determinism guard; the new suite asserts the same.
- All paths are **repo-relative POSIX strings built by concatenation**, never by `path.join`,
  which yields backslashes on Windows and would make the manifest platform-dependent. This
  mirrors what `gen-reference.mjs` does (its `generatedPaths` are hard-coded POSIX literals) and
  is load-bearing for AC-6 on a Windows checkout.
- Serialized as `JSON.stringify(manifest, null, 2) + '\n'`, matching both siblings.
- **Feature-002 adds its index page as one more `entries` row in this same manifest**, produced
  by this same generator run. There is no second manifest and no second generator for `/skills/`.

##### Frontmatter parser contract

`parseSkillFrontmatter(text, sourcePath) → Field[]`

```js
/** @typedef {{ key: string, kind: 'scalar'|'list', value: string|string[], line: number }} Field */
```

AC-2 says *no key is silently dropped*. The operative word is **silently**: the contract is not
"handle every YAML construct" but "**never skip anything without failing the build**". The
existing parser in `gen-reference.mjs` cannot satisfy that, and this is the reason a new one is
written rather than the old one retrofitted (§7 forbids touching it in any case).

Concretely, the existing parser's `if (!m) { i++; continue; }` is a silent skip, and it also:
drops any key containing a digit or a dot (its key regex is `[a-zA-Z_-]+`); handles only `>` and
not `|`, `>-`, `|-`, `>+`, `|+`; drops block sequences entirely (`key:` followed by `  - a` lines
yields `''` and the items vanish — *this is exactly the "list-valued key" failure mode the
feature description anticipates*); truncates a folded block at the first blank line, because
`/^\s/.test('')` is false; overwrites on duplicate keys because it accumulates into a plain
object; and requires LF at the fence (`/^---\n…/`), so a CRLF checkout drops the whole block.

Empirical note, so the implementer is not surprised (measured 2026-07-25): **today** the corpus is
uniform — every `SKILL.md` carries exactly `name`, `description`, `allowed-tools`,
`argument-hint`, and only `aid-deploy` and `aid-monitor` omit `argument-hint`; `description` is
always a `>` folded scalar; `allowed-tools` is a **plain comma-separated scalar, not a YAML
list**; no file has CRLF; no folded block contains a blank line. So the existing parser does not
in fact drop anything *right now* — it simply never renders anything but `description`, which is
what the page must change. The list-valued and block-sequence
cases below are therefore **durability requirements**, not present-day bugs. AC-2 is a promise
about the next skill someone writes.

The new parser MUST handle:

| Construct | Behaviour |
|-----------|-----------|
| Fence | `^---\r?\n … \r?\n---` — CRLF-tolerant. Missing or unterminated → throw. |
| Key line | `^([^\s:#][^:]*):(?:[ \t]+(.*))?$` at indent 0. Accepts digits, dots, uppercase — anything but a leading space, colon or `#`. |
| Plain scalar | Trimmed. No `#`-comment stripping (a `#` inside a description is content). |
| Single-quoted scalar | Outer quotes removed, `''` → `'`. |
| Double-quoted scalar | Outer quotes removed, `\"` `\\` `\n` `\t` unescaped. |
| Empty value | `key:` with nothing following and no indented continuation → `''`, **kept as a field**. |
| Folded block (`>`, `>-`, `>+`) | Continuation = any line indented deeper than the key **or blank**. Lines joined with a space; a blank line becomes a paragraph break. Chomping indicator respected. |
| Literal block (`\|`, `\|-`, `\|+`) | Same continuation rule; newlines preserved verbatim. |
| Block sequence | `key:` followed by `^\s+-[ \t]+(.*)$` lines → `kind: 'list'`. Each item scalar-decoded by the rules above. |
| Flow sequence | `key: [a, b, c]` → `kind: 'list'`, split on commas outside quotes. |
| Blank line / `#` comment between fields | Skipped — the only two constructs that may be skipped. |
| Duplicate key | **Throw.** (An object-keyed parser loses one silently; `Field[]` plus this check cannot.) |
| Anything else at indent 0 | **Throw**, naming file, 1-based line number and the offending text. Covers nested mappings, anchors/aliases/tags, and multi-document streams — none present today, all of which would otherwise be a silent drop. |

`Field[]` is an **ordered array, not an object**. Source order is preserved and is the render
order, which serves AC-2 (fidelity to the file) and AC-6 (no dependence on JS object key
ordering) at once.

##### Header rendering

`renderFrontmatterValue(field) → string`, applied uniformly — the rule is keyed on `Field.kind`,
never on the key's name, because AC-2 must hold for a key nobody has written yet.

- `kind: 'list'` → items joined `` `a`, `b`, `c` `` (each in a code span).
- `kind: 'scalar'` → the text, with **`&` → `&amp;` and `<` → `&lt;` applied only outside the
  author's own code spans.**

That last clause is load-bearing, not defensive. Measured on the corpus 2026-07-25: **39
frontmatter values contain `<` followed by a letter or `/`** (placeholder syntax like
`<dotted.key>`, `<connector>`,
`<ticket-id>`), and several of those sit *inside* an authored inline-code span — e.g.
`aid-read-ticket`'s description contains `` `aid-read-ticket [<connector>:]<ticket-id>` ``.
Escaping blindly prints a literal `&lt;` to the reader, because entities are not decoded inside
code spans; not escaping at all lets markdown swallow `<connector>` as an HTML tag. So the
renderer tokenizes the value into code-span runs and text runs using CommonMark's backtick-run
rule, escapes text runs only, and passes code-span runs through byte-identical.

Also measured, and the reason the header is **not** a markdown table: **8 frontmatter values
contain a `|`**
(`aid-update-ticket`'s description carries the enum `` `description | comment | status` ``),
which would break a two-column table and require a second escaping layer that mangles the
verbatim text. A bullet list needs no pipe escaping at all. Rejected: the `| Key | Value |` table
shape used elsewhere on the site.

Values are otherwise emitted **as authored** — these descriptions are already written as prose
with their own inline code spans, and rendering them as prose is what makes the page "a faithful
front matter of the source".

##### The `SkillRecord`

Built once by `skills/discover.mjs` and passed to every renderer and every downstream feature.
The fields beyond the obvious ones exist because 003/004/005 need them and should not each
re-read and re-scan `SKILL.md`.

```js
/**
 * @typedef {object} SkillRecord
 * @property {string}   dirName        'aid-create-api' — also the slug
 * @property {string}   sourcePath     'canonical/skills/aid-create-api/SKILL.md'  (POSIX, repo-relative)
 * @property {string}   route          '/skills/aid-create-api/'
 * @property {string}   destPath       'site/src/content/docs/skills/aid-create-api.md' (POSIX, repo-relative)
 * @property {Field[]}  fields         frontmatter, source order
 * @property {(k:string)=>Field|undefined} field   convenience lookup
 * @property {string}   body           SKILL.md text after the closing fence
 * @property {number}   bodyStartLine  1-based line of body[0] within SKILL.md
 * @property {number}   lineCount      total lines in SKILL.md
 * @property {string|null} referencesDir  'canonical/skills/aid-describe/references' | null
 */
```

- `bodyStartLine` + `lineCount` are what **feature-005** needs to emit `#L<a>-L<b>` deep links and
  to verify a recorded range actually exists in the cited file.
- `referencesDir` is non-null for directories that carry a `references/` subtree, and is how
  **feature-003** reaches the `references/state-*.md` workers of a fat pipeline skill.
- The record carries **no `shape` field**. Classification is **feature-003**'s, per its SPEC, and
  must inspect the body — never the catalog's `repurpose` flag (`module-map.md` §Skill Structural
  Shapes; `aid-review` and `aid-test-security` are both `repurpose: true` and structurally
  opposite).
- The record deliberately carries **no count of anything**. Population sizes per shape are
  classifier outputs (§8), not inputs.

##### Body slot

The seam features 003–005 target — **feature-006 does not use it**, because it contributes browser
JavaScript rather than page markdown and attaches at the site level instead (see
[Output contract](#output-contract)). Two registries in `site/scripts/skills/body.mjs`, both plain
array literals:

```js
/** First match wins — the chart. Feature-003 and feature-004 each add one entry. */
export const BODY_PROVIDERS = [];   // Array<{ id: string, applies(skill): boolean, render(skill): string }>

/** All run, in array order, each appended below the provider's output. Feature-005 adds one. */
export const BODY_APPENDERS = [];   // Array<{ id: string, render(skill): string }>

/** @returns {string} markdown, or '' for no body. */
export function renderSkillBody(skill) { /* first matching provider, then every appender */ }
```

Rules that make this seam safe:

- **Static array literals only.** No directory globbing, no dynamic `import()`, no registration
  side effects. Filesystem enumeration order is not guaranteed and would put AC-6 at the mercy of
  the OS.
- **First-match-wins by array position**, so 003 (authored-flow shapes) and 004 (doorway shapes)
  compose without either knowing about the other — they add entries, they do not edit each
  other's.
- Every `render()` returns markdown, LF-terminated, or `''`. Returning `''` from all providers is
  the state this feature ships in.
- `render-page.mjs` inserts the result verbatim after the `[Definition: …]` link, separated by one
  blank line. When the result is `''` it emits the `<!-- body slot: … -->` comment instead — never
  an empty heading — so a body-less page is still visibly a page with an unfilled slot rather than
  a page that looks broken.
- Providers own their own headings (`## Flow`, `## Steps`, …). `render-page.mjs` imposes none, so
  003/004 are not boxed into a structure chosen before their charts existed.

In this feature both registries are empty, `renderSkillBody()` returns `''` for every skill, and
every page carries the slot comment.

##### Drift guard (AC-1)

After the write pass, three sorted string sets:

```js
expected = <directories under canonical/skills/>                      // .sort()
written  = <basenames of the pages this run wrote>                    // .sort()
onDisk   = <*.md under src/content/docs/skills/, minus index.md>      // .sort(), basename w/o .md
```

Throw if `written ≠ expected` (a skill produced no page) **or** if `onDisk ≠ expected` (a page
survives a deleted or renamed skill). `index.md` is excluded because feature-002 owns it.

The error message reports the two **set differences**, each sorted, under `missing pages:` and
`orphan pages:` labels. `gen-reference.mjs` dumps both full lists into its message; at this
corpus's scale that is unreadable, so this generator deliberately reports only the delta.

**The generator never deletes.** An orphan page is thrown on and named with the `git rm` remedy,
not silently removed. Auto-pruning would keep the build green and convert AC-1's loud coverage
failure into exactly the silent rot the criterion exists to prevent — and neither `sync-docs.mjs`
nor `gen-reference.mjs` deletes anything, so there is no precedent for a build script removing a
tracked content file.

Per-skill guards, all throws, all named with the offending directory: missing `SKILL.md`; a
directory name failing `^[a-z0-9]+(-[a-z0-9]+)*$`; frontmatter `name` ≠ directory name; and every
parser guard above.

##### Idempotence (AC-6)

Two consecutive runs are byte-identical because every input to the byte stream is a pure function
of `canonical/` on disk:

1. **Ordering.** The directory scan is `.sort()`ed (UTF-16 code-unit order, locale-independent —
   the same call `gen-reference.mjs` makes). Frontmatter fields render in source order from
   `Field[]`. Manifest `entries` follow the sorted scan. Body providers/appenders run in
   declaration order.
2. **No clock, no environment, no randomness.** No `generatedAt`, no `Date`, no `process.env` and
   no package version reaches the output.
3. **Stable serialization.** Pages are built from `'\n'`-joined strings and written with
   `writeFileSync(path, content, 'utf8')`; the manifest via
   `JSON.stringify(m, null, 2) + '\n'`. No `os.EOL`.
4. **Platform-independent paths.** Every path that reaches a page or the manifest is a POSIX
   string built by concatenation, never `path.join`.
5. **No object-key iteration** over parsed data — `Field[]` throughout, so no reliance on
   JavaScript property ordering.

Verified by the test suite as a byte comparison of run 1 against run 2 (see below), not by
`git diff`.

---

#### Test layer

`site/scripts/__tests__/gen-skills.test.mjs`, organised like its neighbour and run by the site's
existing runner (`npm test` → `vitest run`). Because the modules are importable, most of it is
real unit testing rather than output grepping.

| Group | Covers |
|-------|--------|
| Parser — fixtures | Every row of the parser table, each as a small inline fixture string: block sequence, flow sequence, `\|` literal, `>-`/`\|+` chomping, blank line inside a folded block, CRLF fence, dotted/digit keys, empty value, quoted-escape forms. **AC-2's real test.** |
| Parser — guards | Duplicate key, unclassifiable line, missing fence, `name` mismatch each throw with the file and line in the message. |
| Value rendering | `<` and `&` escaped outside code spans; `<` inside an authored code span passes through unescaped (fixture drawn from `aid-read-ticket`'s real description); `\|` needs no escaping. |
| Corpus coverage (AC-1) | One page exists for every directory under `canonical/skills/`; no page exists without one. Derived from the live directory listing — **no literal count is asserted** (§8). |
| Header completeness (AC-2) | For every skill, every key its `SKILL.md` carries appears in its page's Frontmatter section. Driven off the parser, so it stays true as the corpus changes. |
| Drift guard (AC-1) | With a synthetic orphan page present, the generator throws and names it. |
| Idempotence (AC-6) | Read the bytes of all outputs, re-run the generator, compare bytes. **No `git` dependency** — byte comparison is the property AC-6 actually states, and it survives environments where `git` cannot resolve the checkout (observed in this work's own worktree, whose `.git` pointer holds a WSL path Windows `git` rejects, which reds the existing suite's `git diff --exit-code` idempotency test for reasons unrelated to the generator). The existing test is left exactly as it is. |
| Marker + manifest | `generated — do not edit` present on every page; manifest has `generator`, one `entries` row per page, and **no** `generatedAt`. |
| Isolation | The four `reference/*.md` pages and `.reference-manifest.json` are unchanged after `gen:skills` runs. |

**CI enforcement is in scope for this feature** (amended §7 — see
[Build-integration scope](#build-integration-scope-amended-7) Part B). `docs.yml` today runs
`npm ci` + `npm run build` only, so nothing runs vitest; this feature adds the `npm test` step
that makes the table above — and features 003–005's AC-4/AC-5 suites — actually enforceable on a
pull request. Until that step lands the `prebuild` throw is the only CI gate.

The corrected sibling suite (`gen-reference.test.mjs`, Part A) is **not** merged into
`gen-skills.test.mjs`; the two files stay separate, each owning its own generator, and the new
suite's "Isolation" row is what asserts the two do not interfere.

### Telemetry & Tracking

*Activated:* AC-1 is a build-time diagnostic requirement — "the generator throws" is only useful
if what it throws is legible — and features 002–006 will read this generator's output when their
own guards fire.

No product analytics, no runtime instrumentation, no new network call. The site has none today
and this adds none. "Telemetry" here means build-console behaviour, which is a contract because
CI logs are the only place a maintainer sees it.

| Channel | Contract |
|---------|----------|
| Prefix | Every line starts `[gen-skills] `, matching `[gen-reference] ` / `[sync-docs] `. |
| stdout | Progress and results. Exactly four lines per successful run: start, `parsed N skills`, `wrote N pages → src/content/docs/skills/`, `wrote scripts/.skills-manifest.json`. |
| stderr | Warnings and diagnostics only (`coding-standards.md` §Logging and Output). A successful run writes nothing to stderr. |
| Per-page logging | **None.** `gen-reference.mjs` logs one line per page, which is right for four pages and 111 lines of noise here. The summary count replaces it. |
| Counts in output | Computed from the live scan, never a literal (§8). |
| Failures | `throw new Error('[gen-skills] <guard>: <detail>')`, uncaught. Guard names are stable strings — `skills drift`, `frontmatter parse`, `duplicate key`, `name mismatch`, `invalid slug`, `missing SKILL.md` — so a log can be grepped and a test can assert on them. |
| Exit codes | `0` success; `1` any guard failure (uncaught throw). No `2`: the script takes no arguments, so there is no usage-error path. Matches `coding-standards.md` §Exit Codes. |
| Blast radius | A throw fails `prebuild`, which fails `npm run build`, which reds the `docs.yml` PR gate on any PR to `master` touching `site/**`. That is the enforcement path for AC-1. |

### Migration Plan

*Activated:* this feature must land a second generator alongside an existing one that has its own
manifest, its own drift guard and its own test suite, under a §7 constraint that none of them may
change. How the two coexist is a decision, not an implementation detail.

**Ownership boundaries.** The two generators are disjoint in both directions:

| | `gen-reference.mjs` (existing, frozen) | `gen-skills.mjs` (new) |
|---|---|---|
| Reads | `canonical/skills/*/SKILL.md`, `canonical/agents/`, KB templates, `.aid/settings.yml`, `shortcut-catalog.yml` | `canonical/skills/*/SKILL.md` (+ `references/` presence) |
| Writes | `src/content/docs/reference/{skills,agents,kb,settings}.md`, `scripts/.reference-manifest.json` | `src/content/docs/skills/*.md`, `scripts/.skills-manifest.json` |
| Guard | on-disk `canonical/skills/` **vs** curated ∪ catalog rows | on-disk `canonical/skills/` **vs** the emitted page set |

The write sets do not intersect. The guards share a left-hand side but compare it to different
right-hand sides, so they cannot contradict each other: a new skill directory added without a
catalog row still throws in `gen-reference` (existing behaviour, unchanged) while `gen-skills`
emits a page for it. Neither generator imports the other.

**What is touched, exhaustively.** Four things:

1. `site/package.json` — one new script key, `gen:skills` inserted into the two existing chains.
2. New files under `site/scripts/` — the generator, its `skills/` cluster, its manifest, its suite.
3. `site/scripts/__tests__/gen-reference.test.mjs` — the seven stale roster items, corrected to
   source-derived checks (amended §7, Part A). **Test file only.**
4. `.github/workflows/docs.yml` — one `npm test` step in the `build` job (amended §7, Part B).

Nothing else. In particular **not** `gen-reference.mjs` itself (frozen by §7), not
`astro.config.mjs`, not `src/content.config.ts`, not `sync-docs.mjs`, and not any existing
generated page or manifest.

Items 3 and 4 were out of scope in the first draft of this SPEC and were added by owner decision
at the Specify review; they are the reason the fourth acceptance criterion was rewritten.

**Divergence carried forward, not resolved.** Per FR-5 and §7, `reference/skills.md` keeps
grouping `aid-triage`, `aid-deploy` and `aid-monitor` the old way while `/skills/` will use the
corrected taxonomy. That inconsistency is accepted and recorded in REQUIREMENTS.md; this feature
does nothing about it, and `SKILL_GROUPS` in the existing generator is not read by the new one.

**Duplication accepted, and why.** `serializeFrontmatter`, `GITHUB_BLOB_BASE` and the
skill-directory enumeration are re-implemented rather than shared. The clean move — extracting
them into a module both generators import — is precisely the retrofit §7 forbids, and it is
blocked anyway by `gen-reference.mjs` executing `main()` at import time. Recorded as debt to
resolve when that constraint lifts; the alternative (importing from `gen-reference.mjs`) would
run the other generator as a side effect of importing a constant.

**Generated pages are committed**, like the four `reference/*.md` pages and the four `sync-docs`
outputs. Cost: one tracked file per skill directory, and a skill-description edit produces a
two-file diff. Benefit: consistency with every other generated page in the repo, and the page a reader will see
is visible in review. Rejected: adding `src/content/docs/skills/` to `site/.gitignore` (the
`.release-data.json` precedent) — that precedent covers a *fetched* artifact that varies by
environment, not a deterministic render of committed source. They are not registered in
`canonical/aid/templates/generated-files.txt`, which is scoped to `.aid/generated/` and is read by
`/aid-discover`, not by the site build.

**Rollback** of the generator is removing `gen:skills` from the two chains, deleting
`site/scripts/gen-skills.mjs` and `site/scripts/skills/`, and deleting
`src/content/docs/skills/` plus `scripts/.skills-manifest.json`.

The two build-integration items roll back **independently and should not be reverted with it**:
the corrected assertions and the CI step fix defects that predate this work (KI-005, KI-006) and
are correct whether or not `/skills/` ships. Reverting the generator while keeping them leaves the
repo strictly better off than it started; that separability is deliberate, and it is why they can
land early in the delivery sequence rather than behind the generator.

**Build-cost note.** One additional page per skill directory enters the Astro content collection
and the Pagefind index — roughly an order of magnitude more pages than the site carries today.
Both scale linearly and neither is gated on a budget, but this is the first change that
multiplies the page count, so it is worth reading the `docs.yml` build time on the first run.

### Open Questions

**None open.** OQ-1 was answered by the owner at the Specify review and is retained below as a
closed record.

- ~~**OQ-1 — §7's "existing vitest suites keep passing" is not satisfiable as written, because two
  of them already fail.**~~ **CLOSED 2026-07-25 — owner decision at Specify review.**

  *The question was:* `site/scripts/__tests__/gen-reference.test.mjs` asserts a 94-directory
  corpus and a 76-shortcut family total against a real 111 and 64, so it fails before this work
  touches anything (KI-005). Does this feature correct those assertions, or do they become a
  separate ticket with the fourth acceptance criterion re-worded to "introduces no *new*
  failures"?

  *The owner chose **both** remedies, and went further than the question asked.* Beyond correcting
  the assertions, the owner also brought the missing CI wiring (KI-006) into scope: `docs.yml`
  runs only `npm ci` and `npm run build`, so no workflow runs the site suite at all. REQUIREMENTS
  §7 was amended accordingly and now reads: **the site vitest suite must be green and running in
  CI by the end of this work.** Both remedies land in feature-001 because it owns build
  integration.

  *Rationale on record.* Correcting the assertions alone would have produced a green suite that
  nothing runs — AC-2, AC-4 and AC-6 are all specified as vitest tests, so leaving CI unwired
  would have left this work's central quality claims unenforced on every pull request, and would
  have let the same silent staleness recur. Wiring CI alone would have produced a permanently red
  pipeline. The two remedies are only useful together, which is why the amendment states the
  outcome ("green **and** running") rather than the two tasks.

  *Where it landed in this SPEC.* Scope and exact assertions:
  [Build-integration scope](#build-integration-scope-amended-7), Parts A, B and C. Verifiable
  outcome: the rewritten fourth acceptance criterion, clauses (a)–(d). Files added to the touch
  list: Migration Plan § "What is touched, exhaustively", items 3 and 4.

  *One thing the decision did not anticipate, surfaced while specifying it.* The stale class in
  that test file is **seven items, not two** — a stale roster constant, two `it` titles, two
  comments, and three numeric assertions, one of which is currently masked by another's
  short-circuit. Correcting only the two named in the review ledger yields a still-red suite.
  Part A carries the full inventory. This is specification detail, not a reopened question.
