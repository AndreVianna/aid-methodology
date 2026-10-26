# task-038: Build and link tests and the narrowed vitest.config.mjs

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

**Source:** feature-005-machinery-cut -> delivery-004 -> AC-1, AC-2, AC-5, AC-6

**Depends on:** task-035

**Scope:**
- Feature 005 § Feature Flow step 7, as § Layers & Components specifies:
  - Create `site/tests/build.test.mjs`, group (a), cases B1-B5 of the build-test table, one test each, named
    `B1 ...` to `B5 ...`; each reads the existing `dist/` (no build inside the test); B1 derives the expected URL
    set from the files under `src/content/docs/` (extension dropped, trailing `index` dropped, `index.mdx` gives
    `/`) and compares it with the non-redirect `builtPages()` URLs minus `/404.html`, naming each missing or
    extra page; B3 reads `VERSION` with `readFileSync(join(REPO,'VERSION'),'utf8').trim().replace(/^v/,'')`;
    B5 counts directories of `dist/skills/` against `REPO/canonical/skills`.
  - Create `site/tests/links.test.mjs`, group (b): L1 `findBrokenLinks()` on the real `dist/` equals `[]`
    (vitest prints the whole list on failure); L2 builds the fixture of the links table in a folder made by
    `mkdtempSync(join(tmpdir(), 'aid-links-test-'))` (`tmpdir` from `node:os`; the prefix `aid-links-test-` is
    fixed so the teardown check below can find a leak), removed in `afterAll` with
    `rmSync(dir, { recursive: true, force: true })`, and expects exactly
    `['/ -> /missing/ (no such page)', '/ -> /a/#nothere (no such anchor)']`.
  - Rewrite `site/vitest.config.mjs` to exactly the three-statement block of the spec
    (`include: ['tests/**/*.test.mjs']`, `environment: 'node'`, `testTimeout: 60000`), replacing the old comment
    block.
  - Both test files import their paths and helpers from `./dist.mjs` (`SITE`, `REPO`, `DIST`, `builtPages`,
    `findBrokenLinks`), which stays exactly as delivery-001 wrote it (Feature 005 step 7 keeps it).
- Run from `site/`: `npm run build`, then `npx vitest run tests/build.test.mjs tests/links.test.mjs`.
- A failing B or L1 case caused by a page, component or `astro.config.mjs` (for example a broken link) is NOT
  fixed here (PLAN.md delivery-004 Notes, item 2): record it in this task's `STATE.yml` `notes:`
  (`B1-B5, L1-L2 <p>/7 pass; failing: <case> <detail>` or `failing: none`); that `notes:` line is the only
  record task-039 reads (a task has no review ledger of its own). task-039 fixes it. A failure caused by these files deviating from their spec is fixed here; a defect in
  `tests/dist.mjs` is reported against it, not patched around.
- Test names and strings never contain `flow-graph`, `provenance`, `node-panel` or `sync-docs` (AC-5 grep).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no edit under `site/src/`, to
  `site/astro.config.mjs`, `site/package.json` or `site/tests/dist.mjs`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is neither edited nor run here.

**Acceptance Criteria:**

Run from `site/` after `npm run build` unless stated.

- [ ] Config exact: `diff vitest.config.mjs <(printf "%s\n" "import { defineConfig } from 'vitest/config';" "export default defineConfig({" "  test: { include: ['tests/**/*.test.mjs'], environment: 'node', testTimeout: 60000 }," "});")`
  prints nothing.
- [ ] Cases present: `npx vitest run tests/build.test.mjs tests/links.test.mjs` reports exactly 7 tests, named
  B1 to B5, L1 and L2, and `npx vitest run tests/links.test.mjs -t 'L2'` exits 0 (the checker can fail: AC-6).
- [ ] L2 exact: `grep -cF "'/ -> /missing/ (no such page)'" tests/links.test.mjs` and
  `grep -cF "'/ -> /a/#nothere (no such anchor)'" tests/links.test.mjs` each print `1`.
- [ ] B1 can fail by name: with an empty file `src/content/docs/zz-probe.md` temporarily created (no rebuild),
  `npx vitest run tests/build.test.mjs -t 'B1'` exits non-zero and its output contains `/zz-probe/`; after
  `rm src/content/docs/zz-probe.md`, B1's result is the same as before the probe.
- [ ] B5 is AC-2's second half: `grep -c "canonical/skills\|'canonical', 'skills'" tests/build.test.mjs` prints
  at least `1`, and `grep -cE "\b(37|38)\b" tests/build.test.mjs` prints `0` (no literal skill count).
- [ ] Real-tree result recorded: this task's `STATE.yml` `notes:` holds `B1-B5, L1-L2 <p>/7 pass` and every
  failing case with its detail (or `failing: none`).
- [ ] Vitest is narrowed to `tests/`: `npx vitest list --filesOnly 2>/dev/null | sort -u` (or, if that flag is
  absent in the installed vitest, the file list printed by `npx vitest run`) names only files under `tests/`,
  and `find . -path ./node_modules -prune -o -name '*.test.*' -print | grep -v '^./tests/'` prints nothing.
- [ ] `tests/dist.mjs` unchanged: before this task's commit, `git status --porcelain tests/dist.mjs` prints nothing.
- [ ] Deterministic, clean setup and teardown (TEST default): two consecutive runs of the two files give the
  same results; `grep -cF "'aid-links-test-'" tests/links.test.mjs` prints `1`; afterwards
  `ls -d "$(node -p "require('os').tmpdir()")"/aid-links-test-* 2>/dev/null | wc -l` prints `0`, and
  `git status --porcelain --untracked-files=all .` (from `site/`) lists only `tests/build.test.mjs`,
  `tests/links.test.mjs` and `vitest.config.mjs`.
- [ ] AC-5 words: `grep -cE "flow-graph|provenance|node-panel|sync-docs" tests/build.test.mjs tests/links.test.mjs vitest.config.mjs`
  prints `0` for each file.
- [ ] Scope (AC-13, NFR-5): from the repo root,
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; `git tag --points-at HEAD`
  prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
