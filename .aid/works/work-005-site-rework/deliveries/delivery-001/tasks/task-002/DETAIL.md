# task-002: Shared built-site test helper tests/dist.mjs

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

**Type:** IMPLEMENT

**Source:** feature-005-machinery-cut -> delivery-001 -> AC-6

**Depends on:** task-001

**Scope:**
- Create `site/tests/dist.mjs` (new folder `site/tests/`) exactly as Feature 005 § Layers & Components,
  "`tests/dist.mjs`", specifies; Feature 005 keeps it unchanged later (step 7). It lands in delivery-001
  because task-004's facts test imports `SITE` and `REPO` from it (PLAN.md delivery-001 Notes, order item 2).
- Exports, and nothing else: `SITE` (absolute path of `site/`, from
  `fileURLToPath(new URL('..', import.meta.url))`), `REPO` (the parent of `SITE`), `DIST`
  (`join(SITE, 'dist')`), the `BuiltPage` JSDoc typedef, `builtPages(dist = DIST)` and
  `findBrokenLinks(dist = DIST)`, with the behaviour of the two spec bullets under that heading: sorted
  walk of `dist/**/*.html`; the `dist/index.html is missing: run npm run build first` throw; `url` and
  `redirectTo` derivation; `href`/`src` (single or double quotes) plus meta-refresh targets; decoding of
  `&amp;`, `&#38;`, `&quot;`; scheme and `//` skips; resolution against `http://site.invalid` + page URL,
  query dropped, `decodeURIComponent`; the three page-existence forms; `id=`/`name=` anchor match; one
  redirect hop for fragments; the two exact message forms, in page order.
- Node built-ins only (`node:fs`, `node:path`, `node:url`); no npm package.
- Its unit test is case L2 of `site/tests/links.test.mjs`, which Feature 005 step 7 writes in delivery-004.
  No test file is added here (Feature 005: "No other test file exists"); this task proves the same L2
  fixture by command instead (criteria below). It is not a test file itself: its name does not end in
  `.test.mjs`, so the current `site/vitest.config.mjs` does not collect it.
- The only file created or changed is `site/tests/dist.mjs`. `site/vitest.config.mjs` is not touched
  (Feature 005 step 7, delivery-004).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside
  the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `site/tests/dist.mjs`. No test name
  or string contains `flow-graph`, `provenance`, `node-panel` or `sync-docs` (AC-5 grep).

**Acceptance Criteria:**
- [ ] Paths: from `site/`, `node --input-type=module -e "import {SITE,REPO,DIST} from './tests/dist.mjs'; console.log([SITE,REPO,DIST].map(p=>p.replace(/\/$/,'')).join('\n'))"`
  prints three lines equal to `$(pwd)`, `$(dirname $(pwd))` and `$(pwd)/dist`.
- [ ] Built-ins only: `grep -E "^import" site/tests/dist.mjs` lists only `node:` specifiers, and
  `grep -cE "flow-graph|provenance|node-panel|sync-docs" site/tests/dist.mjs` prints `0`.
- [ ] L2 fixture (Feature 005 § Layers & Components, `tests/links.test.mjs` case L2): a `node --input-type=module -e`
  script that writes, in a `mkdtempSync` folder, `index.html` linking to `/a/`, `/missing/`, `/a/#there`,
  `/a/#nothere`, `/old/#there`, `https://example.com/x` and `mailto:x@example.com`, `a/index.html` holding
  `id="there"`, and `old/index.html` as a meta refresh to `/a/`, then prints `JSON.stringify(findBrokenLinks(dir))`
  and removes the folder, prints exactly `["/ -> /missing/ (no such page)","/ -> /a/#nothere (no such anchor)"]`.
- [ ] Spec behaviours beyond L2 (Feature 005 § Layers & Components, the `builtPages` and `findBrokenLinks`
  bullets): a `node --input-type=module -e` script run from `site/` writes, in a `mkdtempSync` folder `D`,
  exactly these files (paths relative to `D`, one file per line, content after the colon):

  ```text
  index.html:     <a href='/c'>c</a> <img src='/file.txt'> <a href="/b%20c/">b</a> <a href="/p&amp;q/?x=1&amp;y=2#named">p</a> <a href="/p&#38;q/">p2</a> <a href='/r&quot;s/'>r</a> <script src="//cdn.example.com/x.js"></script> <img src="data:image/png;base64,AAAA">
  a/index.html:   <a href="../missing2/">m</a>
  b c/index.html: <p>b</p>
  c/index.html:   <p>c</p>
  file.txt:       x
  old/index.html: <meta http-equiv="refresh" content="0;url=/gone/">
  p&q/index.html: <a name="named"></a>
  r"s/index.html: <p>r</p>
  ```

  then prints `JSON.stringify(findBrokenLinks(D))` on one line and
  `JSON.stringify(builtPages(D).map(p => [p.url, p.redirectTo]))` on the next, and removes `D`. Expected,
  exactly:
  `["/a/ -> ../missing2/ (no such page)","/old/ -> /gone/ (no such page)"]` and
  `[["/a/",null],["/b c/",null],["/c/",null],["/",null],["/old/","/gone/"],["/p&q/",null],["/r\"s/",null]]`.
  Each link on `index.html` is found only if its behaviour is implemented (single quotes; file form
  `/file.txt`; `decodeURIComponent` of `%20` and of the `%22` that URL resolution gives `"`; decoding of
  `&amp;`, `&#38;`, `&quot;`; query dropped; `name=` anchor; `//` and `data:` skipped), so a missing behaviour
  adds an entry to the first line. The second line proves the sorted walk (the fixture's names share no
  prefix, so per-directory and whole-path sorting give the same order), the `url` derivation and
  `redirectTo`; `/old/ -> /gone/` proves meta-refresh targets are checked as links, and `../missing2/` proves
  resolution against the page URL, with the raw value in the message.
- [ ] Missing build: from `site/`,
  `node --input-type=module -e "import {builtPages} from './tests/dist.mjs'; import {mkdtempSync,rmSync} from 'node:fs'; import {tmpdir} from 'node:os'; import {join} from 'node:path'; const d=mkdtempSync(join(tmpdir(),'dist-probe-')); try { builtPages(d); console.log('no throw') } catch (e) { console.log(e.message) } finally { rmSync(d,{recursive:true}) }"`
  prints exactly `dist/index.html is missing: run npm run build first`.
- [ ] Real build: from `site/`, after `npm run build` exits 0, `builtPages().length` equals
  `find dist -name '*.html' | wc -l`; the entry for `dist/index.html` has `url` `/`, the one for
  `dist/404.html` has `url` `/404.html`; every entry whose file holds `http-equiv="refresh"` has a non-null
  `redirectTo`; and `findBrokenLinks()` returns an array without throwing (its contents are not a criterion
  here: AC-6 is gated in delivery-004).
- [ ] The site still builds (AC-1): from `site/`, `npm run build` exits 0 and `git status --porcelain src/content/docs`
  prints nothing afterwards. The legacy Vitest suite is not a criterion (PLAN.md Cross-Cutting Risks, row 1).
- [ ] Scope (AC-13, NFR-5): from the repo root, `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; before this task's commit, `git status --porcelain --untracked-files=all site` lists only
  `site/tests/dist.mjs`; and
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
