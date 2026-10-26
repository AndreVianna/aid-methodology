# Plan -- Product Site Rework

## Deliverables

### delivery-001: Site facts from canonical/
- **What it delivers:** the skill pages, the skills index, the agents page and the settings-keys page come from `canonical/` through one checked script, and no build regenerates or fetches anything any more.
- **Features:** feature-002-canonical-facts, feature-005-machinery-cut (Feature Flow step 1 only)
- **Depends on:** --
- **Priority:** Must

**Objective:** Replace the output of the four old generators with `site/scripts/gen-facts.mjs` and its
committed pages, and in the same delivery stop `prebuild`/`predev` from rerunning the old generators,
which would otherwise overwrite those pages on every build. This is the foundation: it settles the
facts every later page links to (the audit rows for generated pages can only take `ok` once `--check`
passes), and it removes the build-time network fetch. The site stays fully usable; only the source of
the generated pages changes.

**Scope:**
- Feature 002 in full: `site/scripts/gen-facts.mjs` (Data Model, Feature Flow steps 1-9, Layers &
  Components), its committed output under `site/src/content/docs/` (`skills/*.md`, `skills/index.md`,
  `reference/agents.md`, `reference/settings.md`), and `site/tests/facts.test.mjs` (cases C1-C5) (AC-2).
- Feature 005 Feature Flow step 1: the `scripts` block of `site/package.json` replaced by the Data
  Model 1 block (`facts`, `facts:check` added; `sync:docs`, `gen:reference`, `gen:skills`,
  `fetch:release`, `prebuild`, `predev` removed) (AC-1).
- `site/tests/dist.mjs`, written exactly as Feature 005 § Layers & Components specifies, because the
  facts test imports `SITE` and `REPO` from it (see Notes).

**Out of scope:** deleting the old generators, libraries and their tests (Feature 005 step 4,
delivery-003); `dependencies`/`devDependencies` (Feature 005 step 6, delivery-003); the
`vitest.config.mjs` rewrite (Feature 005 step 7, delivery-004); the CI step that runs `--check`
(Feature 006, delivery-004); any hand-written page.

**Gate Criteria** -- the ordered rubric the delivery gate evaluates; each concrete and
independently testable, each naming an observable (see
`.aid/runtime/templates/requirements/requirements-template.md § Verifiable Acceptance Criteria`):

- [ ] AC-2, first half: from `site/`, `node scripts/gen-facts.mjs --check` exits 0 and prints `gen-facts: <count> pages up to date`.
- [ ] AC-2, second half: from `site/`, after `npm run build`, `find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` equals `ls ../canonical/skills | wc -l`.
- [ ] Feature 002 tests: from `site/`, `npx vitest run tests/facts.test.mjs` exits 0 with cases C1-C5 passing (C2 and C3 assert `status === 1`, C4 asserts `status === 2`, C5 asserts `wrote <canonical skill count + 3>`).
- [ ] Feature 002 size cap: `wc -l site/scripts/gen-facts.mjs` prints at most 300.
- [ ] AC-1: from `site/`, `npm ci && npm run build` exits 0 and `dist/index.html` exists.
- [ ] Feature 005 step 1: `node -p "Object.keys(require('./package.json').scripts).join(' ')"` (from `site/`) prints exactly `facts facts:check build dev preview astro check test`, and `node -p "require('./package.json').scripts.test"` prints `npm run build && vitest run`.
- [ ] No regeneration at build time: after `npm run build`, `git status --porcelain src/content/docs` (from `site/`) prints nothing.
- [ ] Project quality gates (`.aid/knowledge/quality-gates.md` § The Delivery Gate and § Mechanical Gates Run by the Orchestrator; the template's "section-6 quality gates", not this work's REQUIREMENTS.md § 6 NFRs, which the AC criteria of each delivery gate): `bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/execute-delivery-001.md` prints a grade at or above `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; from the repo root, `bash tests/canonical/select-suites.sh --since site-aid --run`, `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.

**Notes:**
- Order inside the delivery: (1) Feature 005 step 1 (the `scripts` block), committed no later than
  the first committed output of `gen-facts.mjs`, so no build between them reruns the old generators
  (Feature 005 § Feature Flow, step 1); (2) `site/tests/dist.mjs`; (3) `site/scripts/gen-facts.mjs`
  and its committed pages; (4) `site/tests/facts.test.mjs`. The site must build after each.
- Feature 005 is split across deliveries; its spec orders its steps so the site builds after each one
  (Feature 005 § Feature Flow, opening paragraph). Here: step 1. delivery-003: steps 2, 3, 4, 5 and 6.
  delivery-004: steps 7 and 8.
- `site/tests/dist.mjs` is owned by Feature 005 but lands here, exactly as specified, under the rule
  Feature 004 § Migration Plan states for its own test ("if Feature 005 has not yet written it, this
  feature's change adds it exactly as Feature 005 specifies, and Feature 005 keeps it"). Feature 005
  step 7 keeps it unchanged.
- `vitest.config.mjs` is still the old one; its default include finds `tests/facts.test.mjs`, so the
  facts test runs by path. The legacy suite under `site/scripts/__tests__/` and `site/src/**/__tests__/`
  is not part of this gate (Cross-Cutting Risk 1).
- The generated `/skills/aid-experiment/` page reads "/aid- execute" by design (Feature 002 § Data
  Model, "Frontmatter subset"); it is a finding for the owner, recorded by Feature 001 in delivery-002.

### delivery-001 Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001, task-002 |
| task-004 | task-002, task-003 |

| Can Be Done In Parallel |
|------------------------|
| (none: the tasks form a single chain) |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002
wave 3: task-003
wave 4: task-004
```

### delivery-002: Correct content and accessible diagrams
- **What it delivers:** every hand-written page is audited against the repository and rewritten in plain language, the methodology page is split into focused Concepts pages with redirects, and every diagram is a static, accessible SVG with a text equivalent instead of Mermaid.
- **Features:** feature-001-content-audit, feature-003-accessible-diagrams
- **Depends on:** delivery-001
- **Priority:** Must

**Objective:** Make the site true and readable, the first priority of REQUIREMENTS.md § 10. Feature 001
and Feature 003 travel together because Feature 003's Concepts diagrams can only land on the `.mdx`
hosts that Feature 001's split creates, and Feature 001's audit covers the diagrams' words; shipping
either alone would leave pages half-migrated. It follows delivery-001 because the audit rows for the
generated pages need `--check` to pass, and because deleting `reference/skills.md` is only safe once
no `prebuild` regenerates it. After this delivery the site has its final page set, its final
redirects and no Mermaid.

**Scope:**
- Feature 001 in full except the final completion of the two changelog rows (see Notes): the per-page
  audit (Feature Flow steps 2-5), the page-set migration and redirects (step 6 and § Migration Plan:
  `concepts/methodology.md` renamed to `.mdx` with `git mv` and split into `concepts/{pipeline,knowledge-base,agents,feedback-loops,aid-and-sdd}.mdx`
  and `concepts/case-studies.md`; the five stub/merged pages removed; the `redirects` object and the
  `sidebar` array in `site/astro.config.mjs`), the glossary anchors, and the AC-12 review (step 7) (AC-3 partial, AC-12).
- Feature 003 in full: `site/src/components/Diagram.astro`, the ten components D1-D10 under
  `site/src/components/diagrams/`, their placement on the hosts, deletion of `site/src/assets/3-ironman.png`,
  and the Mermaid removal in `site/astro.config.mjs` (import, integration, source-cache `head` entry,
  their comments, and the `readFileSync` import) (AC-8, build-level part).

**Out of scope:** the U1-U7 markup assertions as automated tests (Feature 004 tests, delivery-004);
deleting `site/src/scripts/mermaid-source-cache.js` and the Mermaid packages (Feature 005 steps 3 and 6,
delivery-003); the `.mermaid` CSS rules (Feature 004, delivery-003); converting `<Tabs>` to sections
(Feature 004, delivery-003); the changelog page and contact form (Feature 005, delivery-003);
`sourceDoc:`/`generatedFrom:` removal (Feature 005 step 4, delivery-003).

**Gate Criteria**

- [ ] Build: from `site/`, `npm run build` exits 0 and `dist/index.html` exists, with the Releases sidebar entry still the interim link: `grep -c "link: '/releases/changelog'" site/astro.config.mjs` prints `1` and `grep -c "slug: 'releases/changelog'" site/astro.config.mjs` prints `0` (see Notes).
- [ ] Links and glossary anchors: from `site/`, after the build, `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"` prints nothing (Feature 005 § Layers & Components, `findBrokenLinks(dist = DIST)`, which also checks `/reference/glossary/#<anchor>` fragments and follows redirect pages).
- [ ] AC-3, all but the changelog rows: from `site/`, the AC-3 completeness check in Feature 001 § Data Model, piped through `grep -v 'releases/changelog'`, prints nothing.
- [ ] Redirects: `dist/get-started/index.html`, `dist/concepts/index.html`, `dist/concepts/overview/index.html`, `dist/reference/index.html` and `dist/reference/skills/index.html` each hold a `meta http-equiv="refresh"` whose target is the URL in Feature 001 § Migration Plan.
- [ ] Page weight before restyling (Feature 001 § Migration Plan, "at most 150 KB"): from `site/`, `find dist -name '*.html' -size +150k` prints nothing.
- [ ] AC-8, Mermaid gone: from the repo root, `grep -rln '^```mermaid' site/src/content/docs --include='*.md*' | grep -v '/skills/'` prints nothing and `grep -n 'mermaid' site/astro.config.mjs` prints nothing.
- [ ] Feature 003 `node:fs` import removed (Cross-Cutting Risk 2): `grep -c "from 'node:fs'" site/astro.config.mjs` prints `0`.
- [ ] AC-8, every diagram placed: `grep -o '<figure class="diagram' site/dist/<page>/index.html | wc -l` gives `index.html` 1, `concepts/pipeline` 2, `concepts/methodology` 1, `concepts/knowledge-base` 2, `concepts/agents` 1, `concepts/feedback-loops` 1, `concepts/aid-and-sdd` 1, `guides/maintainer` 1, `guides/pipeline` 1 (total 11, Feature 003 § Feature Flow, verification table).
- [ ] Feature 003 raster removed: `grep -rn '3-ironman' site/src` prints nothing and `test -e site/src/assets/3-ironman.png` exits 1.
- [ ] Feature 003 size cap: `wc -l site/src/components/Diagram.astro site/src/components/diagrams/*.astro` prints a total of at most 1500.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` still exits 0.
- [ ] AC-12: a reviewer reading the home page and every Get Started page confirms the first paragraph is one sentence of purpose and every glossary term is linked to `/reference/glossary/#<anchor>` on its first use (Feature 001 § Feature Flow, step 7).
- [ ] Project quality gates, as in delivery-001, on `.aid/.temp/review-pending/execute-delivery-002.md`: grade at or above the `--skill execute` `minimum_grade`; `bash tests/canonical/select-suites.sh --since site-aid --run` and the two KB lints exit 0.

**Notes:**
- Order inside the delivery: Feature 001's split and `git mv` first (Feature 003 edits only `.mdx`
  hosts that exist after it), then the Feature 003 diagrams, then Feature 003's Mermaid removal in
  `astro.config.mjs` once the last fence is gone. Feature 001's rewrite of each page and Feature 003's
  diagram placement on it may land in either order, but the audit row of a host page is finalised
  only after its diagram is in place.
- `site/astro.config.mjs` keys touched here: `sidebar` (except the Skills group) and `redirects`
  (Feature 001); the Mermaid lines and the `node:fs` import (Feature 003). No other key.
- Feature 001's final `sidebar` is applied with one exception: the Releases entry stays
  `{ label: 'Changelog', link: '/releases/changelog' }`, as in today's `astro.config.mjs`, because
  `releases/changelog.mdx` does not exist until Feature 005 step 2 creates it in delivery-003 (a `slug:`
  to a missing doc fails the build). Feature 001 § Migration Plan states this interim form; delivery-003
  switches the entry to `slug: 'releases/changelog'`.
- The rows for `src/pages/releases/changelog.astro` and `src/content/docs/releases/changelog.mdx`
  stay non-final here, because Feature 005 step 2 creates and deletes those files in delivery-003;
  delivery-004 completes AC-3.
- `reference/artifacts.md` keeps its "Sync manifest" and "Reference manifest" rows here; Feature 005
  step 4 deletes them in delivery-003 and updates that page's audit row.
- The legacy suite remains outside the gate (Cross-Cutting Risk 1).

### delivery-002 Execution Graph

| Task | Depends On |
|------|-----------|
| task-005 | task-004 |
| task-006 | task-005 |
| task-007 | task-004 |
| task-008 | task-005, task-007 |
| task-009 | task-005, task-007 |
| task-010 | task-005, task-007 |
| task-011 | task-006, task-008, task-009, task-010 |
| task-012 | task-006 |
| task-013 | task-008, task-012 |
| task-014 | task-012, task-013 |
| task-015 | task-008, task-010, task-014 |
| task-016 | task-008, task-009, task-015 |
| task-017 | task-009, task-016 |
| task-018 | task-010, task-017 |
| task-019 | task-018 |
| task-020 | task-019 |
| task-021 | task-020 |
| task-022 | task-021 |
| task-023 | task-005, task-006, task-007, task-008, task-009, task-010, task-011, task-012, task-013, task-014, task-015, task-016, task-017, task-018, task-019, task-020, task-021, task-022 |

| Can Be Done In Parallel |
|------------------------|
| task-005, task-007 |
| task-008, task-009, task-010 |

```wave-map
delivery: 002
wave 1: task-005, task-007
wave 2: task-006, task-008, task-009, task-010
wave 3: task-011, task-012
wave 4: task-013
wave 5: task-014
wave 6: task-015
wave 7: task-016
wave 8: task-017
wave 9: task-018
wave 10: task-019
wave 11: task-020
wave 12: task-021
wave 13: task-022
wave 14: task-023
```

### delivery-003: New look and machinery cut
- **What it delivers:** a new token-based light and dark design with an accessible one-row header, no JavaScript beyond search, theme and navigation, a no-JavaScript contact form, a network-free version and changelog, and a site code base stripped of the old generators, node panel, Mermaid and their tests.
- **Features:** feature-004-look-and-layout (everything except its two test files), feature-005-machinery-cut (Feature Flow steps 2, 3, 4, 5 and 6)
- **Depends on:** delivery-002
- **Priority:** Must

**Objective:** Deliver the new visual design and remove the machinery it replaces, in the one order the
specs allow: Feature 004's styles, header and config first; then Feature 005 steps 2 to 6, where step 2
re-adds the `node:fs` import that Feature 003 removed in delivery-002, step 5 rewrites the footer and
form with Feature 004's tokens, and step 6 uninstalls `@fontsource/inter` only after Feature 004 has
deleted `casulo.css`, and installs `axe-core` and `jsdom` for the tests of delivery-004. The two
features are one delivery because neither leaves a coherent site alone: Feature 004's config drops
keys whose files Feature 005 deletes, and Feature 005's rewritten components need Feature 004's tokens.
After this delivery the legacy suite is gone and `npm test` is green again.

**Scope:**
- Feature 004, all of it except `site/tests/a11y.test.mjs` and `site/tests/contrast.test.mjs`:
  `site/src/styles/tokens.css` and `site/src/styles/site.css` (new), `casulo.css` and `shell.css`
  deleted, `Header.astro` rewritten, `PageTitle.astro` deleted, the `customCss`, `social`,
  `expressiveCode` and `components` keys in `site/astro.config.mjs`, and every `<Tabs>` turned into
  plain sections; the AC-9 keyboard check and the AC-11 screenshots, recorded in the audit (AC-9, AC-11,
  AC-15 size part).
- Feature 005 step 2 (version read in `astro.config.mjs`, `src/data/version.ts`, the new
  `src/content/docs/releases/changelog.mdx`, deletion of `changelog.astro`, `Banner.astro`,
  `src/lib/release-data.ts`, the `Banner` key and the `.release-data.json` lines of `site/.gitignore`);
  step 3 (the `Head` key, the node panel and `mermaid-source-cache.js` files); step 4 (the rest of
  the § Migration Plan delete list, `sourceDoc`/`generatedFrom` out of `src/content.config.ts` and
  the pages, `reference/kb.md` made hand-written, the two manifest rows out of `reference/artifacts.md`);
  step 5 (`ReportForm.astro` and `Footer.astro`); step 6 (dependencies and lockfile) (AC-1, AC-4
  `scripts/` part, AC-5 grep part).

**Out of scope:** `site/tests/a11y.test.mjs` and `site/tests/contrast.test.mjs` (delivery-004);
`tests/build.test.mjs`, `tests/links.test.mjs` and the `vitest.config.mjs` rewrite (Feature 005 step 7,
delivery-004); the AC-4 measurement (Feature 005 step 8, delivery-004); `.github/workflows/docs.yml` and
the KB (Feature 006, delivery-004).

**Gate Criteria**

- [ ] AC-1: from `site/`, `npm ci && npm run build` exits 0 and `dist/index.html` exists.
- [ ] Suite green again: from `site/`, `npm test` exits 0 (at this point it builds and runs `tests/facts.test.mjs` only).
- [ ] AC-5, no test of removed code: from the repo root, `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules` prints nothing.
- [ ] AC-4, `scripts/` clause: from `site/`, `find scripts -type f` prints exactly `scripts/gen-facts.mjs`.
- [ ] FR-7: from `site/`, `grep -rln "sourceDoc\|generatedFrom\|release-data\|skill-flows" src astro.config.mjs` prints nothing.
- [ ] FR-12 / NFR-4: from `site/`, `grep -rnE "fetch\(|node:https?|https?\.get\(|process\.env" scripts src/components src/data astro.config.mjs` prints nothing.
- [ ] FR-11: from `site/`, `npm ls mermaid marked sanitize-html` prints `(empty)`, `grep -c '"node_modules/mermaid"' package-lock.json` prints `0`, `node -p "require('axe-core/package.json').version"` prints `4.14.0`, and the `scripts`, `dependencies`, `devDependencies` and `overrides` of `package.json` equal Feature 005's Data Model 1 block.
- [ ] Version source: from `site/`, `grep -c "from 'node:fs'" astro.config.mjs` prints `1`, and `dist/index.html` and `dist/releases/changelog/index.html` both contain `v` followed by the repo-root `VERSION` value (leading `v` stripped).
- [ ] Feature 004 tokens only: from `site/`, `grep -rn -- '--casulo-' src` and `grep -rn '@fontsource' src` print nothing.
- [ ] Feature 004 Tabs gone: from `site/`, `grep -rlE '<Tabs|<TabItem|import \{[^}]*Tabs' src/content/docs` (today it lists the five Feature 004 pages) and `grep -rl 'starlight-tabs' dist --include='*.html'` print nothing.
- [ ] Files deleted and created (Feature 004 § Layers & Components, Feature 005 § Migration Plan): from `site/`, `for p in src/styles/casulo.css src/styles/shell.css src/components/overrides/PageTitle.astro src/components/overrides/Head.astro src/components/Banner.astro src/pages src/lib src/data/skill-flows src/data/__tests__ src/scripts/mermaid-source-cache.js public/skill-node-panel.css public/skill-node-panel.mjs; do test -e "$p" && echo "present: $p"; done` prints nothing, `find src scripts -name __tests__` prints nothing, and `test -f src/styles/tokens.css && test -f src/styles/site.css && test -f src/content/docs/releases/changelog.mdx` exits 0.
- [ ] Releases sidebar entry switched: `grep -c "slug: 'releases/changelog'" site/astro.config.mjs` prints `1` and `grep -c "link: '/releases/changelog'" site/astro.config.mjs` prints `0`.
- [ ] Links and glossary anchors: from `site/`, after the build, `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"` prints nothing.
- [ ] AC-15, size half: from `site/`, `find dist -name '*.html' -size +150k` prints nothing.
- [ ] AC-9: the manual keyboard check on `/` and `/skills/aid-define/` (Feature 004 § UI Specs, "AC-9, manual keyboard check") gives the expected stop order with a visible focus ring at every stop; the result is in the audit's "Keyboard check (AC-9)" table.
- [ ] AC-11: the eight screenshots `<home|aid-define>-<320|1280>-<light|dark>.png` exist in `.aid/works/work-005-site-rework/screenshots/`, and `document.documentElement.scrollWidth <= window.innerWidth` printed `true` for each; recorded in the audit's "Screenshots (AC-11)" table.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Project quality gates, as in delivery-001, on `.aid/.temp/review-pending/execute-delivery-003.md`: grade at or above the `--skill execute` `minimum_grade`; `bash tests/canonical/select-suites.sh --since site-aid --run` and the two KB lints exit 0.

**Notes:**
- Order inside the delivery: (1) Feature 004 tokens, `site.css`, header, Tabs and config keys;
  (2) Feature 005 step 2; (3) step 3; (4) step 4; (5) step 5; (6) step 6, whose first check is
  `grep -rn '@fontsource' src` printing nothing. The site must build after each.
- `site/astro.config.mjs` keys touched here: `customCss`, `social`, `expressiveCode` and `components`
  (Feature 004 removes only `PageTitle` from `components`); the `Banner` key (Feature 005 step 2); the
  `Head` key (step 3); the `node:fs` import, `AID_VERSION`, `vite.define` and the sidebar Releases entry
  (step 2, next note). Feature 004 leaves
  the `Banner` and `Head` keys for Feature 005 to remove.
- Feature 005 step 2, in the same change that creates `releases/changelog.mdx` and deletes
  `changelog.astro`, switches the sidebar Releases entry from the interim `link: '/releases/changelog'`
  kept by delivery-002 to Feature 001's `slug: 'releases/changelog'`.
- Feature 005 step 2 creates `releases/changelog.mdx`; this delivery sets its audit row and the removed
  row for `changelog.astro` (Feature 001 § Data Model, "Verdict"), so AC-3 can close in delivery-004.
  Feature 005 step 4's edits to `reference/artifacts.md` and the four `sourceDoc` pages update those
  pages' audit rows.
- AC-9 and AC-11 are taken here because the look is final at the end of this delivery; delivery-004's
  planned scope edits no file under `site/src/` and no `astro.config.mjs` key. If a delivery-004 test
  forces a fix there, delivery-004 re-runs and re-records them (its Notes).
- Step 6 needs the npm registry; it runs on the maintainer's machine, never in the build.

### delivery-003 Execution Graph

| Task | Depends On |
|------|-----------|
| task-024 | task-023 |
| task-025 | task-024 |
| task-026 | task-025 |
| task-027 | task-026 |
| task-028 | task-026, task-027 |
| task-029 | task-028 |
| task-030 | task-029 |
| task-031 | task-030 |
| task-032 | task-031 |
| task-033 | task-032 |
| task-034 | task-033 |
| task-035 | task-024, task-025, task-026, task-027, task-028, task-029, task-030, task-031, task-032, task-033, task-034 |

| Can Be Done In Parallel |
|------------------------|
| (none: the tasks form a single chain) |

```wave-map
delivery: 003
wave 1: task-024
wave 2: task-025
wave 3: task-026
wave 4: task-027
wave 5: task-028
wave 6: task-029
wave 7: task-030
wave 8: task-031
wave 9: task-032
wave 10: task-033
wave 11: task-034
wave 12: task-035
```

### delivery-004: Lean tests, workflow and safety proof
- **What it delivers:** the four test groups the site keeps, the measured machinery reduction, a CI workflow and Knowledge Base that describe the simplified site, and the proof that nothing was deployed or changed outside scope.
- **Features:** feature-004-look-and-layout (its two test files), feature-005-machinery-cut (Feature Flow steps 7 and 8), feature-006-workflow-and-safety
- **Depends on:** delivery-003
- **Priority:** Must

**Objective:** Close the work. Feature 004's accessibility and contrast tests need `axe-core` and
`jsdom`, which delivery-003 installed; Feature 005 step 7 completes the four groups and narrows Vitest
to `tests/`; step 8 measures the reduction against the baseline. Feature 006 runs last because it reads
its binding values B1-B7 from the finished tree, and its safety proof must be the final act on the
branch. This delivery holds every criterion that needs the whole site: the complete audit (AC-3), the
reduction (AC-4), the full test suite (AC-5 to AC-8, AC-10, AC-15) and the final safety checks (AC-13,
AC-14). It is Must because it carries Must requirements (FR-8); Feature 006 within it is Should.

**Scope:**
- Feature 004: `site/tests/a11y.test.mjs` (T1-T11, S1-S9, U1-U7, W1-W4, A1, the AC-8 total and the AC-15
  script list) and `site/tests/contrast.test.mjs` (K1-K5); the AC-15 script table in the audit (AC-7,
  AC-8, AC-10, AC-15).
- Feature 005 step 7 (`tests/build.test.mjs` B1-B5, `tests/links.test.mjs` L1-L2, `tests/dist.mjs`
  kept as written in delivery-001, `vitest.config.mjs` rewritten) and step 8 (the "After" figures,
  the FR-9 table, the "Release banner" row) (AC-4, AC-5, AC-6).
- Feature 006 in full: `.github/workflows/docs.yml` edited (never run), the KB edits in its § Layers &
  Components, the audit's "Knowledge Base documents edited (FR-10)" table, a local commit, and the
  safety proof (AC-13, AC-14).
- The audit's Pages table made final (AC-3).

**Out of scope:** running `docs.yml`, pushing, tagging, releasing or deploying (REQUIREMENTS.md § 4 Out
of Scope); the three out-of-scope files outside `site/` that still name deleted scripts (Feature 005 §
Migration Plan, "Outside `site/`"), which Feature 006 records as debt row W5-24 only.

**Gate Criteria**

- [ ] AC-5: from `site/`, `npm test` exits 0 and Vitest lists exactly `tests/build.test.mjs`, `tests/links.test.mjs`, `tests/facts.test.mjs`, `tests/a11y.test.mjs` and `tests/contrast.test.mjs`; from the repo root, `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules` prints nothing.
- [ ] AC-6: from `site/`, after a build, `npx vitest run tests/links.test.mjs` passes, with L1 returning `[]` and L2 returning exactly the two expected broken links.
- [ ] AC-7 and AC-10: in that run, every per-page test of `tests/a11y.test.mjs` passes (A1 axe-core and S1-S4 report nothing), and self-tests T1-T11 pass.
- [ ] AC-8: in that run, U1-U7 pass on every page and the final test finds a `figure.diagram` total of at least the number of files in `src/components/diagrams/`.
- [ ] AC-15: from `site/`, `find dist -name '*.html' -size +150k` prints nothing, and every line of `grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' | sort -u` is in the audit's "Scripts on built pages (AC-15)" table with a purpose of search, theme or navigation (W3 and W4 pass).
- [ ] Feature 004 contrast: `tests/contrast.test.mjs` cases K1-K5 pass.
- [ ] AC-2 still holds: `node scripts/gen-facts.mjs --check` exits 0 and build case B5 passes.
- [ ] AC-4: from `site/`, the AC-4 command and the same command with `tests` added each total at most 21577 (60% below the baseline in the audit's "Baseline figures" table), `find scripts -type f` prints exactly `scripts/gen-facts.mjs`, and the "After" column is filled.
- [ ] AC-3: from `site/`, the AC-3 completeness check in Feature 001 § Data Model prints nothing.
- [ ] Feature 006 workflow: the six static checks of Feature 006 § Feature Flow step 4 give their stated results (step list, path filters `True`, fetch count `0`, `deploy` job and `permissions`/`concurrency` diffs empty, no `docs/` read under `site/`).
- [ ] Feature 006 KB sweep: both commands of Feature 006 § Feature Flow step 6 print nothing.
- [ ] AC-14: from the repo root, `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`, `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and `bash tests/canonical/test-kb-no-work-ids.sh` exit 0, and the INDEX freshness diff of Feature 006 step 7 prints nothing.
- [ ] AC-13 (REQUIREMENTS.md § 9; no clean-`git status` demand at gate time): from the repo root, after the commit described in Notes, `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'` prints nothing; the unlisted-KB-file loop of Feature 006 step 10 prints nothing; `git diff --name-only site-aid...HEAD -- '*.sh' '*.ps1' '*.psm1'` prints nothing; `git tag --points-at HEAD` prints nothing; `git rev-parse --abbrev-ref work-005@{upstream}` fails and `git ls-remote --heads origin work-005` prints nothing.
- [ ] Project quality gates, as in delivery-001, on `.aid/.temp/review-pending/execute-delivery-004.md`: grade at or above the `--skill execute` `minimum_grade`; `bash tests/canonical/select-suites.sh --since site-aid --run` and the two KB lints exit 0.

**Notes:**
- Order inside the delivery: Feature 005 step 7 and Feature 004's two tests (either order, both after
  delivery-003's step 6); then Feature 005 step 8; then Feature 006 steps 1-11 in order. Feature 006
  step 1 (preconditions) is the entry check: `--check`, `npm test` and `npm run build` must all pass
  before any KB or workflow edit.
- A failing per-page check found here (a W1 weight, an S4 heading skip, an A1 violation) is fixed in
  the page or component that causes it, and the page's audit row is updated, before Feature 006 starts.
  This is the only page markup delivery-004 may touch: no spec of delivery-004 edits `site/src/` (Feature
  004's tests, Feature 005 steps 7-8 and Feature 006 write `site/tests/`, `site/vitest.config.mjs`,
  `docs.yml`, the KB and the audit only). When such a fix touches `site/src/` or `astro.config.mjs`, the AC-9
  keyboard check and the eight AC-11 screenshots are re-run and their audit tables re-recorded before
  Feature 006 starts.
- `git ls-remote` is the only network use in the gate; without network, Feature 006 step 10 records the
  two local checks and states that the remote check was not run.
- Feature 006 step 11 writes the safety-proof output to the work's STATE.yml after step 10, outside the
  step-10 checks.
- The AC-13 gate criterion does not require `git status --porcelain` to be empty: `aid-execute` writes
  task and delivery `STATE.yml` files (In Review, Gated) during the gate. Those files are under
  `.aid/works/work-005-site-rework/`, a path § 9 AC-13 allows, so they never fail the
  `git diff --name-only site-aid...HEAD` filter whether or not they are committed: the diff lists only
  committed paths, and any of these files that are committed sit inside the allowed folder.

### delivery-004 Execution Graph

| Task | Depends On |
|------|-----------|
| task-036 | task-035 |
| task-037 | task-035 |
| task-038 | task-035 |
| task-039 | task-036, task-037, task-038 |
| task-040 | task-039 |
| task-041 | task-039, task-040 |
| task-042 | task-041 |
| task-043 | task-042 |
| task-044 | task-042 |
| task-045 | task-042 |
| task-046 | task-043, task-044, task-045 |
| task-047 | task-046 |
| task-048 | task-047 |
| task-049 | task-036, task-037, task-038, task-039, task-040, task-041, task-042, task-043, task-044, task-045, task-046, task-047, task-048 |

| Can Be Done In Parallel |
|------------------------|
| task-036, task-037, task-038 |
| task-043, task-044, task-045 |

```wave-map
delivery: 004
wave 1: task-036, task-037, task-038
wave 2: task-039
wave 3: task-040
wave 4: task-041
wave 5: task-042
wave 6: task-043, task-044, task-045
wave 7: task-046
wave 8: task-047
wave 9: task-048
wave 10: task-049
```

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | From delivery-001 to Feature 005 step 4 in delivery-003, the legacy Vitest suite (`site/scripts/__tests__/`, `site/src/**/__tests__/`) still exists while the generated pages it compares against now come from `gen-facts.mjs`, so `npm test` is expected to be red in that window (the `docs.yml` test step too, were it run). | M | The gates of delivery-001 and delivery-002 run targeted commands (`--check`, `tests/facts.test.mjs`, the build, the Feature 003 checks), not `npm test`; delivery-003 restores `npm test` to green as a gate criterion; nothing is pushed, so no CI run sees the red window. |
| 2 | `site/astro.config.mjs` is edited by Features 001, 003, 004 and 005 across delivery-002 and delivery-003; a later edit can undo an earlier one (the `node:fs` import that Feature 003 removes and Feature 005 re-adds is the sharpest case). | M | Each delivery's Notes list the keys it touches; each feature edits only the keys its spec owns; the delivery-002 gate checks `grep -n 'mermaid' astro.config.mjs` (empty) and `grep -c "from 'node:fs'" astro.config.mjs` (`0`), the delivery-003 gate checks the same count is `1` and the Releases sidebar entry's `slug:` form, and every delivery builds. |
| 3 | The same pages are edited by several features: Feature 001 and Feature 003 in delivery-002, Feature 004 (Tabs) and Feature 005 step 4 (`sourceDoc`, `reference/kb.md`, `reference/artifacts.md`) in delivery-003. A later edit can break a plain-language rule or leave an audit row stale. | M | The audit row of an edited page is updated in the same change; the AC-3 check is a gate in delivery-002 (all but the changelog rows) and in delivery-004 (complete). |
| 4 | Page-structure, weight and accessibility checks (S1-S9, W1-W4, A1, U1-U7) only become automated in delivery-004, so a defect introduced in delivery-002 or delivery-003 surfaces late. | M | delivery-002 and delivery-003 gate on the 150 KB `find` check, the `findBrokenLinks` link and anchor check, and (delivery-002) the Feature 003 diagram counts; delivery-004's Notes route each finding back to its page or component before Feature 006 starts, so the final safety proof runs on a clean tree. |
| 5 | Between delivery-001 and delivery-003 the old node panel (`Head.astro`, `src/data/skill-flows/`) and the release-data layer (`src/lib/release-data.ts` with no fetched `.release-data.json`) still run against the new generated skill pages. | L | delivery-001's gate builds the site and counts `dist/skills/`; Feature 005 steps 2 and 3 remove both layers in delivery-003. |
