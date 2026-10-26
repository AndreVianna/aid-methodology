# task-039: Page and component fixes for the findings of the site suite

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

**Source:** feature-004-look-and-layout, feature-005-machinery-cut -> delivery-004 -> AC-5, AC-6, AC-7, AC-8, AC-10, AC-15

**Depends on:** task-036, task-037, task-038

**Scope:**
- Input: the failures recorded in the `STATE.yml` `notes:` of task-036 (per-page S1-S9, U1-U7, W1-W4, A1),
  task-037 (K3, K4) and task-038 (B1-B5, L1) (those `notes:` lines are the only record; no task has a review
  ledger of its own), plus a fresh run: from `site/`, `npm test`.
- First action, before any edit: record the base commit in this task's `STATE.yml` `notes:` as
  `base: <sha>`, the `<sha>` being the output of `git rev-parse HEAD` at that moment. task-040 and the
  criteria below diff against it.
- PLAN.md delivery-004 Notes, item 2: fix each failure in the page, component, stylesheet or
  `site/astro.config.mjs` that causes it, under the rule of the spec that owns that file (Feature 001 rules
  P1-P9 for page text, Feature 003 § UI Specs markup contract for diagrams, Feature 004 Data Model 1 and
  § UI Specs for tokens and `site.css` (a colour value only in `tokens.css`; a new token keeps the K-table
  pairs), Feature 005 Data Models 4 and 5 for `ReportForm.astro` and `Footer.astro`). In `astro.config.mjs`
  only the key whose owner the fix belongs to changes (PLAN.md Cross-Cutting Risks, row 2).
- For every page whose source changes, update its row in `.aid/works/work-005-site-rework/site-audit.md`
  § Pages in the same change: verdict `corrected` (or the existing final verdict kept) and one sentence in the
  Correction cell naming the fix and the check that found it.
- A failure that is a test defect (the test deviates from its spec) is not fixed here: it goes back to the
  test's owning task (task-036, task-037 or task-038), which ends `Failed` and is re-run.
- If there is no failure, nothing changes and `notes:` says `no findings`.
- Record for task-040, in this task's `STATE.yml` `notes:`: `src-touched: yes (<paths>)` when any file under
  `site/src/` or `site/astro.config.mjs` changed, else `src-touched: no`.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/` (a wrong generated fact is a finding
  for the owner, recorded in its audit row, never patched in the page); no hand edit of a generated page
  (`skills/*.md`, `skills/index.md`, `reference/agents.md`, `reference/settings.md`); no edit to
  `site/package.json`, `site/package-lock.json`, `site/scripts/gen-facts.mjs` or any file under `site/tests/`
  or to `site/vitest.config.mjs`; no change to any path outside the AC-13 allowed set (`site/`,
  `.github/workflows/docs.yml`, the FR-10 KB documents, `.aid/works/work-005-site-rework/`);
  `.github/workflows/docs.yml` is neither edited nor run here.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] AC-5: `npm test` exits 0 and Vitest lists exactly `tests/build.test.mjs`, `tests/links.test.mjs`,
  `tests/facts.test.mjs`, `tests/a11y.test.mjs` and `tests/contrast.test.mjs`.
- [ ] AC-7, AC-10: in that run every per-page test of `tests/a11y.test.mjs` passes (A1 and S1-S9 report nothing)
  and T1-T11 pass.
- [ ] AC-8: in that run U1-U7 pass on every page and the final diagram-total test passes.
- [ ] Contrast: K1-K5 of `tests/contrast.test.mjs` pass in that run.
- [ ] AC-6: L1 returns `[]` and L2 passes in that run.
- [ ] AC-15, size half: `find dist -name '*.html' -size +150k` prints nothing (W1 agrees).
- [ ] AC-2 still holds: `node scripts/gen-facts.mjs --check` exits 0 and B5 passes.
- [ ] Generated pages untouched: before this task's commit,
  `git status --porcelain src/content/docs/skills src/content/docs/reference/agents.md src/content/docs/reference/settings.md`
  prints nothing.
- [ ] Audit rows follow the pages: before this task's commit, for every path `p` printed by
  `git status --porcelain src/content/docs src/pages | awk '{print $2}' | sed 's#^site/##'`,
  `grep -cF "| \`$p\` " ../.aid/works/work-005-site-rework/site-audit.md` prints `1` and that row's verdict is one
  of `ok`, `corrected`, `removed`, `new`.
- [ ] Tokens only: `grep -rn -- '--casulo-' src` prints nothing, and K4 passes (no colour literal outside
  `tokens.css`).
- [ ] `notes:` of this task's `STATE.yml` holds a `base:` line with a 40-hex sha (`git cat-file -t` of it prints
  `commit`) and `src-touched: yes (...)` or `src-touched: no`; with `B` set to that sha, the `src-touched:` value
  agrees with `git diff --name-only "$B" HEAD -- src astro.config.mjs` after this task's commit (empty exactly
  when `no`; the paths listed exactly when `yes`).
- [ ] All existing tests still pass and the build passes (IMPLEMENT default): covered by `npm test` above, which
  builds first; `npm run build` exits 0 on its own too.
- [ ] Scope (AC-13, NFR-5): from the repo root,
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit
  `git status --porcelain --untracked-files=all site/tests site/package.json site/package-lock.json site/scripts site/vitest.config.mjs`
  prints nothing; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
