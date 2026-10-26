# task-049: Delivery-004 gate run and final AC-1 to AC-15 sweep

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

**Source:** feature-001-content-audit, feature-002-canonical-facts, feature-003-accessible-diagrams, feature-004-look-and-layout, feature-005-machinery-cut, feature-006-workflow-and-safety -> delivery-004 -> AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15

**Depends on:** task-036, task-037, task-038, task-039, task-040, task-041, task-042, task-043, task-044, task-045, task-046, task-047, task-048

**Scope:**
- Run, on a clean install and build of the finished branch, every Gate Criterion of PLAN.md delivery-004 in the
  order listed there except the graded-ledger half of its last line, then the final sweep of REQUIREMENTS.md § 9
  AC-1 to AC-15 (each AC either has its own check below or maps to a gate line), and record the result of each.
- The graded ledger `.aid/.temp/review-pending/execute-delivery-004.md` and its grade are produced by the
  delivery gate that `aid-execute` runs after every task of delivery-004, this one included, is Done; they are
  outside this task, which neither requires that file to exist nor grades it. This task runs the mechanical
  project checks it can run itself (the last criterion below).
- Commands only: from `site/`, `npm ci`, `npm run build`, `npm test`, `npx vitest run ...`,
  `node scripts/gen-facts.mjs --check` and the checks below; from the repo root, the KB checks, the docs.yml static
  checks, the AC-13 checks, `bash tests/canonical/select-suites.sh --since site-aid --run` and
  `bash .aid/runtime/scripts/config/read-setting.sh`. AC-9, AC-11 and AC-12 are verified from their recorded
  results (audit tables, delivery-002 gate), not re-run, unless a delivery-004 commit changed a page they cover.
- AC-9 and AC-11 open status (binding decision): when the audit's AC-9 and AC-11 tables hold
  `awaiting maintainer run` (no browser could be started without a download, task-034 or task-040 Path B), those
  two ACs are recorded as `open: awaiting maintainer run (unproven)`, neither pass nor fail; they do not make this
  task `Failed`, and the open status is carried into the final report (this task's `notes:` and the results file).
- Output: the result of each criterion (command, expected, observed, pass/fail/open) as a one-line summary in this
  task's `STATE.yml` `notes:` (`N/M gate checks pass; open: <ids or none>; failing: <ids or none>`), and the full
  table in `.aid/.temp/delivery-004-final-check.md` (git-ignored scratch, not a review ledger; the delivery gate
  reviewer may read it). A task has no review ledger of its own.
- A failing check is not fixed here: it is reported with the task (and file) that owns it, and the task ends
  `Failed`, so the orchestrator routes the fix to that owner (and task-048 is re-run after any new commit).
- The AC-13 checks follow PLAN.md delivery-004 Notes item 4: a non-empty `git status --porcelain` from task and
  delivery `STATE.yml` writes under `.aid/works/work-005-site-rework/` is expected and does not fail AC-13.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`; no `release.sh`, no workflow run (`docs.yml` is
    checked statically only), no `gh` command.
  - No network use other than `npm ci` / `npm install` run from `site/` and the one read-only
    `git ls-remote --heads origin work-005` that AC-13 names (PLAN.md delivery-004 Notes, item 3); without network
    or permission for it, record `remote check not run` and rely on task-048's record.
  - No edit under `canonical/`; no edit to any file under `site/`, `.aid/knowledge/` or to `site-audit.md`; this
    task writes only its own `STATE.yml` and `.aid/.temp/delivery-004-final-check.md`.
  - No change to any path outside the delivery-004 AC-13 allowed set.

**Acceptance Criteria:**

Run from `site/` unless stated, after `rm -rf dist && npm ci && npm run build`. Let
`A=../.aid/works/work-005-site-rework/site-audit.md` and `V=$(tr -d '[:space:]' < ../VERSION | sed 's/^v//')`.

- [ ] AC-1: `npm ci && npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] AC-5: `npm test` exits 0 and Vitest lists exactly `tests/build.test.mjs`, `tests/links.test.mjs`,
  `tests/facts.test.mjs`, `tests/a11y.test.mjs` and `tests/contrast.test.mjs`; from the repo root,
  `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules`
  prints nothing.
- [ ] AC-6: `npx vitest run tests/links.test.mjs` passes, with L1 returning `[]` and L2 returning exactly the two
  expected broken links.
- [ ] AC-7 and AC-10: in the `npm test` run every per-page test of `tests/a11y.test.mjs` passes (A1 and S1-S4
  report nothing, S5-S9 too) and T1-T11 pass.
- [ ] AC-8: in that run U1-U7 pass on every page and the final test finds a `figure.diagram` total of at least
  `ls src/components/diagrams | wc -l`.
- [ ] AC-15: `find dist -name '*.html' -size +150k` prints nothing, and every line of
  `grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' | sort -u` is in the audit's "Scripts on built pages
  (AC-15)" table with a purpose of search, theme or navigation (the `diff` of task-041 prints nothing); W3 and W4 pass.
- [ ] Feature 004 contrast: K1-K5 of `tests/contrast.test.mjs` pass.
- [ ] AC-2: `node scripts/gen-facts.mjs --check` exits 0, build case B5 passes, and
  `find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` equals `ls ../canonical/skills | wc -l`.
- [ ] AC-4: the AC-4 command and the same command with `tests` added (the two code blocks under § Baseline figures
  of `$A`) each print a `total` of at most `21577`; `find scripts -type f` prints exactly `scripts/gen-facts.mjs`;
  `sed -n '/^## Baseline figures/,/^## /p' $A | grep -c pending` prints `0`.
- [ ] AC-3: the AC-3 completeness check in Feature 001 § Data Model prints nothing.
- [ ] Feature 006 workflow, from the repo root: the six static checks of Feature 006 § Feature Flow step 4 give
  their stated results (step list as given, path filters `True`, fetch count `0`, `deploy` job and
  `permissions`/`concurrency` diffs empty, no `docs/` read under `site/`).
- [ ] Feature 006 KB sweep, from the repo root: both commands of Feature 006 § Feature Flow step 6 print nothing.
- [ ] AC-14, from the repo root: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`,
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and `bash tests/canonical/test-kb-no-work-ids.sh`
  exit 0, and the INDEX freshness diff of Feature 006 step 7 prints nothing.
- [ ] AC-13, from the repo root (no clean-`git status` demand at gate time):
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; the unlisted-KB-file loop of Feature 006 step 10 prints nothing;
  `git diff --name-only site-aid...HEAD -- '*.sh' '*.ps1' '*.psm1'` prints nothing; `git tag --points-at HEAD`
  prints nothing; `git rev-parse --abbrev-ref work-005@{upstream}` fails and `git ls-remote --heads origin work-005`
  prints nothing (or `remote check not run` is recorded); the work `STATE.yml` holds task-048's
  `Safety proof (AC-13)` entry, and with `K` set to the sha on that entry's `checked:` line,
  `git diff --name-only "$K"..HEAD | grep -v '^\.aid/works/work-005-site-rework/'` prints nothing (HEAD is the
  checked commit, or a later one that touches only the work folder).
- [ ] AC-9 (recorded): either (proven) `sed -n '/^## Keyboard check (AC-9)/,/^## /p' $A` holds the two rows (`/`,
  `/skills/aid-define/`), each with `yes (<n>/<n> stops)` with equal numbers, Result `pass` with a method and date,
  and no `pending` or `awaiting`; or (open) every data cell of those two rows is exactly `awaiting maintainer run`
  and `grep -cF 'AC-9 and AC-11 are unproven: awaiting maintainer run.' $A` prints at least `1`, in which case AC-9
  is recorded `open: awaiting maintainer run (unproven)` in `notes:` and the results file. Any other content
  (a `pending`, a `fail`, a mix) fails this criterion.
- [ ] AC-11 (recorded): either (proven) the eight files
  `for f in home-320-light home-320-dark home-1280-light home-1280-dark aid-define-320-light aid-define-320-dark aid-define-1280-light aid-define-1280-dark; do test -s "../.aid/works/work-005-site-rework/screenshots/$f.png" || echo "missing: $f"; done`
  prints nothing and `sed -n '/^## Screenshots (AC-11)/,/^## /p' $A | grep -o 'scrollWidth <= innerWidth: true' | wc -l`
  prints `8`; or (open) every data cell of the Screenshots table is exactly `awaiting maintainer run`, recorded
  `open: awaiting maintainer run (unproven)` as for AC-9. Any other content fails this criterion.
- [ ] AC-12 (recorded): the delivery-002 gate ledger records AC-12 as passed; if any file of the home page or the
  Get Started pages changed after it (`git log --format=%H -- src/content/docs/index.mdx src/content/docs/get-started`
  shows a commit later than that gate), the reviewer re-reads those pages and confirms the first paragraph is one
  sentence of purpose equal to `description`, and every glossary term links to `/reference/glossary/#<anchor>` on
  its first use.
- [ ] Version still from `VERSION`: `grep -c "v$V" dist/index.html` and `grep -c "v$V" dist/releases/changelog/index.html`
  each print at least `1`.
- [ ] Project mechanical checks this task can run itself (the graded ledger is the delivery gate's, see Scope),
  from the repo root: `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`
  prints one grade letter, recorded in the results file for the gate (`minimum_grade: <letter>`);
  `bash tests/canonical/select-suites.sh --since site-aid --run`,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. No criterion of this task
  reads `.aid/.temp/review-pending/execute-delivery-004.md`.
- [ ] Tests are deterministic, with clean setup and teardown (TEST default): a second full run of every command
  above, after `rm -rf dist && npm run build`, gives the same results, and the run creates no file outside
  `site/dist/`, `site/node_modules/`, `.aid/.temp/` and this task's `STATE.yml`; `git status --porcelain site .aid/knowledge`
  prints nothing at the end.
- [ ] All acceptance criteria covered (TEST default): every Gate Criterion line of PLAN.md delivery-004 and every
  AC-1 to AC-15 of REQUIREMENTS.md § 9 maps to one criterion above (the graded-ledger half of the last Gate
  Criterion maps to the delivery gate, named as such); the table in `.aid/.temp/delivery-004-final-check.md` lists
  all of them with pass, fail or (AC-9, AC-11 only) open, and `notes:` holds the one-line summary of the Scope.
