# task-036: Accessibility and structure test tests/a11y.test.mjs

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** feature-004-look-and-layout, feature-003-accessible-diagrams -> delivery-004 -> AC-7, AC-8, AC-10, AC-15

**Depends on:** task-035

**Scope:**
- Create `site/tests/a11y.test.mjs`, FR-8 group (d), exactly as Feature 004 § Technical Specification specifies:
  - § Data Model 3 ("Page check records"): the constants `PURPOSES`, `FORBIDDEN`, `BANNED_LINK_TEXT` and
    `LIMIT` as written there; every check returns `string[]` problems of the form `<check id> <detail>` (for
    example `S2 found 2 h1`); a page passes when the concatenated list is empty.
  - § Layers & Components, "`tests/a11y.test.mjs`": imports `JSDOM` and `VirtualConsole` from `jsdom`, `axe`
    from `axe-core`, and `builtPages`, `DIST`, `SITE` from `./dist.mjs` (Feature 005's helper, written in
    delivery-001; not edited here); Node built-ins otherwise (`node:fs`, `node:path`, `node:zlib`); Vitest's
    `node` environment, no `// @vitest-environment` docblock; at most 250 lines.
  - Self-tests T1-T11 first (fixture HTML strings in the file, no file written), each asserting the exact
    problem of its row of the self-test table (T2 names `h4`, T6 "no purpose", T7 names `image-alt`, T9 one U6
    problem for the first figure and none for the second, T11 names `x`). Test names start with their id
    (`T1 ...`).
  - Then one test per built page (`it.each(pages)` over `builtPages()`, pages with a non-null `redirectTo`
    skipped): the page parsed once with jsdom, scripts not run; checks S1-S9 as in the per-page table; U1-U7
    implemented as written in Feature 003 § UI Specs, "Markup contract" (inside `main`; for U4 an `svg` inside
    an element with `aria-hidden="true"` counts as hidden); W1 (HTML file at most `LIMIT` bytes), W2 (gzip of
    the HTML plus every local stylesheet, modulepreload and `script src` file, at most `LIMIT`), W3 (every
    `<script>` except `type="application/json"` / `"application/ld+json"` matches a `PURPOSES` marker and no
    `FORBIDDEN` marker; a `src` script judged by its file under `dist/`), W4 (no off-site `script src` or
    stylesheet `href`, `/^(https?:)?\/\//`); A1 with the axe-core setup block of the spec verbatim (the
    `JSDOM` options, `dom.window.eval(axe.source)`, `runOnly` tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`,
    `wcag22aa`, `color-contrast` disabled, `resultTypes: ['violations']`, one problem per violation
    `A1 <id>: <targets>`). Problems are joined into one failure message per page.
  - A final test: the total of `figure.diagram` across all checked pages is at least the number of files in
    `src/components/diagrams/` (AC-8), and `console.info` prints each distinct script `src` with its
    purposes (task-041 copies that list into the audit).
- Run by path after a build, from `site/`: `npm run build && npx vitest run tests/a11y.test.mjs`. Whether
  `vitest.config.mjs` is still the old one or already task-038's rewrite, the path run finds this file.
- A per-page failure caused by a page, component or `astro.config.mjs` is NOT fixed here (PLAN.md delivery-004
  Notes, item 2): record each failing page URL with its problem ids in this task's `STATE.yml` `notes:` (one
  line: `per-page <p>/<n> pass; failing: <url> <ids>; ...`); that `notes:` line is the only record task-039
  reads (a task has no review ledger of its own; the delivery gate's ledger is written after every task is
  Done). task-039 fixes them. A failure caused by this file deviating from its spec is fixed here.
- The only file created is `site/tests/a11y.test.mjs`. No test name or string contains `flow-graph`,
  `provenance`, `node-panel` or `sync-docs` (AC-5 grep).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no edit under `site/src/`, to
  `site/astro.config.mjs`, `site/package.json`, `site/tests/dist.mjs` or `site/vitest.config.mjs`; no change to
  any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is neither edited nor run here.

**Acceptance Criteria:**

Run from `site/` after `npm run build` unless stated.

- [ ] Size and imports: `wc -l < tests/a11y.test.mjs` prints at most `250`;
  `grep -E "^import" tests/a11y.test.mjs | grep -vE "from '(node:[a-z]+|vitest|jsdom|axe-core|\./dist\.mjs)'"`
  prints nothing; `grep -c "from './dist.mjs'" tests/a11y.test.mjs` prints `1`;
  `grep -c "@vitest-environment" tests/a11y.test.mjs` prints `0`.
- [ ] Constants as specified: `grep -c "150 \* 1024" tests/a11y.test.mjs` prints at least `1`, and each of
  `'starlight-tabs'`, `'aid-flow-data'`, `'rf-submit'`, `'click here'`, `'sl-sidebar-restore'`,
  `'StarlightThemeProvider'` occurs in the file (`grep -cF` prints at least `1` for each).
- [ ] axe setup verbatim: `grep -cF "'wcag22aa'" tests/a11y.test.mjs`, `grep -cF "'color-contrast': { enabled: false }" tests/a11y.test.mjs`,
  `grep -cF "resultTypes: ['violations']" tests/a11y.test.mjs` and `grep -cF "runScripts: 'outside-only'" tests/a11y.test.mjs`
  each print `1`.
- [ ] Self-tests prove each check can fail (AC-7, AC-10): `npx vitest run tests/a11y.test.mjs -t '\bT([1-9]|1[01]) '`
  exits 0 and reports exactly 11 passed tests, T1 to T11.
- [ ] Per-page run executed and recorded: `npx vitest run tests/a11y.test.mjs` runs one test per page of
  `builtPages()` with `redirectTo === null` plus the final AC-8 test (the count of reported tests equals 11 +
  that page count + 1, the page count from
  `node --input-type=module -e "import { builtPages } from './tests/dist.mjs'; console.log(builtPages().filter((p) => !p.redirectTo).length)"`);
  this task's `STATE.yml` `notes:` holds `per-page <p>/<n> pass` with `<n>` equal to that page count, and lists
  every failing page with its problem ids (or `failing: none`).
- [ ] AC-15 list printed: the run's output holds one `console.info` line per distinct script `src` with its
  purposes, or a line stating that no page has a `script src`.
- [ ] Reads, never writes (TEST: deterministic, clean setup and teardown): two consecutive runs of
  `npx vitest run tests/a11y.test.mjs` give the same pass/fail list; afterwards
  `git status --porcelain --untracked-files=all .` (from `site/`) lists only `tests/a11y.test.mjs`.
- [ ] AC-5 words: `grep -cE "flow-graph|provenance|node-panel|sync-docs" tests/a11y.test.mjs` prints `0`.
- [ ] Scope (AC-13, NFR-5): from the repo root,
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's
  commit, `git status --porcelain --untracked-files=all site` lists only `site/tests/a11y.test.mjs`;
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
