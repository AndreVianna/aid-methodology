# task-047: Site audit completed: final Pages table and the FR-10 KB table

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

**Source:** feature-001-content-audit, feature-006-workflow-and-safety -> delivery-004 -> AC-3, AC-13

**Depends on:** task-046

**Scope:**
- Only `.aid/works/work-005-site-rework/site-audit.md` is written.
- Feature 006 § Feature Flow step 8 (Data Model 3): fill § Knowledge Base documents edited (FR-10) with one row per
  KB document actually changed, i.e. per path printed by `git diff --name-only site-aid...HEAD -- .aid/knowledge`:
  first cell the file name in a code span as named under `.aid/knowledge/` (for example `module-map.md`), second
  cell the one-sentence "Statement made true" of the spec's Work-folder layer table, third cell `done`. Add an
  `INDEX.md` row only if task-046's `notes:` says `INDEX.md regenerated`. The `pending` placeholder row goes. A
  listed document with no change, or a changed one with no row, is not allowed.
- PLAN.md delivery-004 Scope, "The audit's Pages table made final (AC-3)": run the AC-3 completeness check of
  Feature 001 § Data Model and make it print nothing: every file under `site/src/content/docs/` and `site/src/pages/`
  has a row, a row for a missing file is `removed`, and every verdict is `ok`, `corrected`, `removed` or `new`.
  The rows of `src/content/docs/releases/changelog.mdx` (`new`) and `src/pages/releases/changelog.astro`
  (`removed`) are checked closed. A verdict is never set without the evidence the Feature 001 flow requires; a
  row that still needs a page change is reported (task ends `Failed`, naming the page's owning task), not papered
  over.
- Close the other audit tables left open: § Redirects statuses final (each verified by its
  `meta http-equiv="refresh"` target in `site/dist/`), and § Leads found at Specify emptied (each lead moved into
  its page row, per Feature 001 § Feature Flow step 5).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other than
  `npm ci` / `npm install` run from `site/`; no edit under `canonical/`, `site/` or `.aid/knowledge/`; no change to
  any path outside the delivery-004 AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, `.aid/knowledge/`
  documents listed in the audit's FR-10 table, `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml`
  is not run.

**Acceptance Criteria:**

Let `A=.aid/works/work-005-site-rework/site-audit.md` (from the repo root; `../$A` from `site/`).

- [ ] AC-3: from `site/`, the AC-3 completeness check in Feature 001 § Data Model prints nothing.
- [ ] Changelog rows closed: ``grep -F '| `src/content/docs/releases/changelog.mdx` ' $A | grep -c '| new |'`` and
  ``grep -F '| `src/pages/releases/changelog.astro` ' $A | grep -c '| removed |'`` each print `1`.
- [ ] FR-10 table matches the KB diff (AC-13 loop of Feature 006 step 10), from the repo root:
  `for f in $(git diff --name-only site-aid...HEAD -- .aid/knowledge); do grep -qF "| \`${f#.aid/knowledge/}\` |" $A || echo "unlisted: $f"; done`
  prints nothing; and the reverse,
  `sed -n '/^## Knowledge Base documents edited (FR-10)/,/^## /p' $A | grep -oE '^\| `[^`]+`' | sed 's/^| `//; s/`$//' | while read d; do git diff --quiet site-aid...HEAD -- ".aid/knowledge/$d" && echo "listed, unchanged: $d"; done`
  prints nothing; every row's Status is `done`.
- [ ] No open placeholder in any table this task owns: `sed '/^## Keyboard check (AC-9)/,/^## Knowledge Base/{/^## Knowledge Base/!d}' $A | grep -nE '\| *(pending|planned|awaiting[^|]*) *\|'`
  prints nothing (the AC-9 and AC-11 tables are excluded: they are task-034's and task-040's, and may hold
  `awaiting maintainer run` when no browser could be started; task-049 reports that status), and
  `sed -n '/^## Leads found at Specify/,$p' $A | grep -c '^| /'` prints `0`.
- [ ] Redirects verified: for each row of § Redirects, `site/dist/<old>/index.html` holds a
  `meta http-equiv="refresh"` whose target is the row's new URL (reviewer runs `grep -o 'url=[^"]*'` on each file).
- [ ] Accuracy verified against the current tree (DOCUMENT default): each FR-10 sentence describes the change visible
  in `git diff site-aid...HEAD -- .aid/knowledge/<doc>` (reviewer judgment, one sentence per document).
- [ ] Scope (AC-13, NFR-5): before this task's commit `git status --porcelain --untracked-files=all` lists only `$A`
  and task/delivery `STATE.yml` files under `.aid/works/work-005-site-rework/`;
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task --
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
