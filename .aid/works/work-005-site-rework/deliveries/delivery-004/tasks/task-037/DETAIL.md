# task-037: Token contrast test tests/contrast.test.mjs

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

**Source:** feature-004-look-and-layout -> delivery-004 -> AC-7

**Depends on:** task-035

**Scope:**
- Create `site/tests/contrast.test.mjs`, FR-8 group (d), exactly as Feature 004 § Layers & Components,
  "`tests/contrast.test.mjs`", specifies:
  - Node built-ins and `vitest` only; at most 90 lines; paths built from `SITE` imported from `./dist.mjs`
    (Feature 005's helper, not edited here).
  - `luminance(hex)` with the WCAG 2.x channel formula and weights given there; `ratio(fg, bg)` =
    `(Lmax + 0.05) / (Lmin + 0.05)`; `readTokens(cssText)` returning `{ dark, light, mapping }` from the two
    rule blocks of `src/styles/tokens.css` (Data Model 1).
  - The `PAIRS` constant = Feature 004 § Data Model 2 "Contrast pairs", every row, including the eight pairs of
    Feature 003 § UI Specs, Accessibility, in their Starlight variable names, resolved through the mapping;
    each pair checked in both themes.
  - Cases K1-K5, one test each, named `K1 ...` to `K5 ...`, with the assertions of the K table; a K3 failure
    lists `<theme> <fg> on <bg>: <ratio> < <min> (<used for>)`; K4 reads `src/styles/site.css`, every
    `<style>` block of `src/components/**/*.astro`, and the whole of `src/components/Diagram.astro` and
    `src/components/diagrams/*.astro` (markup included), and does not read `public/favicon.svg` or content
    pages.
- Run by path, from `site/`: `npx vitest run tests/contrast.test.mjs` (no build needed).
- A K3 or K4 failure caused by `tokens.css`, `site.css` or a component (for example a hex value left in
  `ReportForm.astro`) is NOT fixed here (PLAN.md delivery-004 Notes, item 2): record each failure line in this
  task's `STATE.yml` `notes:` (`K1-K5 <p>/5 pass; failing: <lines>` or `failing: none`); that `notes:` line is
  the only record task-039 reads (a task has no review ledger of its own). task-039 fixes it. A failure caused by this file deviating from its spec is fixed here.
- The only file created is `site/tests/contrast.test.mjs`. No test name or string contains `flow-graph`,
  `provenance`, `node-panel` or `sync-docs` (AC-5 grep).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no edit under `site/src/`, to
  `site/astro.config.mjs`, `site/package.json`, `site/tests/dist.mjs` or `site/vitest.config.mjs`; no change to
  any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is neither edited nor run here.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Size and imports: `wc -l < tests/contrast.test.mjs` prints at most `90`;
  `grep -E "^import" tests/contrast.test.mjs | grep -vE "from '(node:[a-z]+|vitest|\./dist\.mjs)'"` prints nothing.
- [ ] Every pair of the spec is present: each of `accent-strong`, `on-accent`, `border-strong`, `focus`,
  `caution-bg`, `--sl-color-accent-low`, `--sl-color-gray-3` and `--sl-color-gray-6` occurs in the file
  (`grep -cF` prints at least `1` for each).
- [ ] K5 and the cases run: `npx vitest run tests/contrast.test.mjs` reports exactly 5 tests named K1 to K5, and
  `npx vitest run tests/contrast.test.mjs -t 'K5'` exits 0.
- [ ] K3 can fail: with the light `--aid-color-text-muted` in `src/styles/tokens.css` temporarily set to
  `#a3b1c6`, `npx vitest run tests/contrast.test.mjs -t 'K3'` exits non-zero and its output contains
  `light text-muted on bg:`; after `git checkout -- src/styles/tokens.css` the K3 result is the same as before
  the probe.
- [ ] K4 can fail: with the line `a { color: #ffffff; }` temporarily appended to `src/styles/site.css`,
  `npx vitest run tests/contrast.test.mjs -t 'K4'` exits non-zero naming `site.css`; after
  `git checkout -- src/styles/site.css` the K4 result is the same as before the probe.
- [ ] Real-tree result recorded: this task's `STATE.yml` `notes:` holds `K1-K5 <p>/5 pass` and every failure
  line of K1-K4 on the real tree (or `failing: none`).
- [ ] Deterministic, clean setup and teardown (TEST default): two consecutive runs give the same results; after
  the probes, `git status --porcelain --untracked-files=all .` (from `site/`) lists only
  `tests/contrast.test.mjs`.
- [ ] AC-5 words: `grep -cE "flow-graph|provenance|node-panel|sync-docs" tests/contrast.test.mjs` prints `0`.
- [ ] Scope (AC-13, NFR-5): from the repo root,
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's
  commit, `git status --porcelain --untracked-files=all site` lists only `site/tests/contrast.test.mjs`;
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
