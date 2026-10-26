# task-041: Reduction measured and audit figures recorded (AC-4, FR-9, AC-15)

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

**Type:** DOCUMENT

**Source:** feature-005-machinery-cut, feature-004-look-and-layout -> delivery-004 -> AC-4, AC-15

**Depends on:** task-039, task-040

**Scope:**
- Feature 005 § Feature Flow step 8, on the final tree (after `npm run build` from `site/`), writing only
  `.aid/works/work-005-site-rework/site-audit.md`:
  - § Baseline figures, column "After", every row: the AC-4 total (`<lines> lines in <files> files`, from the
    first command under the table), the total with `tests` added (second command; `find` warnings for folders
    that no longer exist are expected, read the `total` line), the `scripts/` file count with the line count of
    each file, the test-file count (`find . -name '*.test.*' -not -path './node_modules/*' | wc -l`), and the
    AC-2 skill pages (`find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` against
    `ls ../canonical/skills | wc -l`). Each cell names the date of measurement.
  - § Kept site functions (FR-9): "How it is checked" set to the build case that proves each row (B2 for
    search, sitemap, favicon, `CNAME`, `robots.txt`; B3 for the version display; B4 for the contact pages); the
    Status of each function row `kept`, after `npx vitest run tests/build.test.mjs` passes; the "Release banner"
    row's Status `removed` (Feature 005 § Migration Plan, `src/components/Banner.astro`).
- Feature 004 § UI Specs, "AC-15, script list": run
  `grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' | sort -u` and write one row per output line into
  § Scripts on built pages (AC-15): the Script cell is that line in one code span, the Purpose cell is
  `search`, `theme` or `navigation`, as W3 assigned it in the `console.info` list of `tests/a11y.test.mjs`. If
  the command prints nothing (Astro inlined every script), the table holds the single row
  `| none (every script is inline; W3 checks them) | -- |`. The `pending` placeholder row goes.
- A figure above target (AC-4 total over 21577, `scripts/` holding more than `gen-facts.mjs`) or a script with
  no allowed purpose is recorded as measured and the task ends `Failed`, naming the owning task; no number is
  adjusted.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other than
  `npm ci` / `npm install` run from `site/`; no edit under `canonical/` or `site/`; no change to any path outside
  the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `site-audit.md`;
  `.github/workflows/docs.yml` is neither edited nor run here. The Pages table and the FR-10 table are task-047's.

**Acceptance Criteria:**

Run from `site/` after `npm run build`. Let `A=../.aid/works/work-005-site-rework/site-audit.md`. "The AC-4
command" and "the same command with `tests` added" are the two code blocks under § Baseline figures of `$A`,
copied unchanged.

- [ ] AC-4, measured: the AC-4 command of the audit header prints a `total` of at most `21577`, and the same command
  with `tests` added prints a `total` of at most `21577`; each `total` equals the number written in the matching
  "After" cell.
- [ ] AC-4, `scripts/` clause: `find scripts -type f` prints exactly `scripts/gen-facts.mjs`, and
  `wc -l < scripts/gen-facts.mjs` prints at most `300`; the "After" cell of the `scripts/` row says `1`.
- [ ] Baseline table final: `sed -n '/^## Baseline figures/,/^## /p' $A | grep -c pending` prints `0`, and the test-file
  "After" cell equals `find . -name '*.test.*' -not -path './node_modules/*' | wc -l`, which prints `5`.
- [ ] FR-9 table final: `sed -n '/^## Kept site functions (FR-9)/,/^## /p' $A | grep -c pending` prints `0`; the
  "Release banner" row's Status is `removed`; every other row's Status is `kept` and names B2, B3 or B4; and
  `npx vitest run tests/build.test.mjs` exits 0.
- [ ] AC-15 table equals the built pages:
  `diff <(grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' | sort -u) <(sed -n '/^## Scripts on built pages (AC-15)/,/^## /p' $A | grep -oE '^\| `[^`]+`' | sed 's/^| `//; s/`$//' | sort -u)`
  prints nothing (or, when the `grep -rho` prints nothing, the table holds exactly the single `none` row); every
  Purpose cell is `search`, `theme` or `navigation`; `grep -c '^| pending |' <(sed -n '/^## Scripts on built pages (AC-15)/,/^## /p' $A)`
  prints `0`.
- [ ] Accuracy verified against the current tree (DOCUMENT default): re-running each command above gives the
  same numbers as the cells.
- [ ] Scope (AC-13, NFR-5): from the repo root,
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; before this task's commit `git status --porcelain --untracked-files=all` lists only
  `.aid/works/work-005-site-rework/site-audit.md` and task/delivery `STATE.yml` files under
  `.aid/works/work-005-site-rework/`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
