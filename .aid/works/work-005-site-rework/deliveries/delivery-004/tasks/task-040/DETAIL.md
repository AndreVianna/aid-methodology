# task-040: Keyboard check and screenshots re-recorded after markup fixes

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

**Source:** feature-004-look-and-layout, feature-005-machinery-cut -> delivery-004 -> AC-9, AC-11

**Depends on:** task-039

**Scope:**
- PLAN.md delivery-004 Notes, item 2: when a delivery-004 fix touched `site/src/` or `site/astro.config.mjs`,
  the AC-9 keyboard check and the eight AC-11 screenshots are re-run and their audit tables re-recorded before
  Feature 006 starts.
- Decide from task-039's `STATE.yml` `notes:` (`src-touched: yes (...)` or `src-touched: no`), cross-checked
  from the repo root with `git diff --name-only "$B" HEAD -- site/src site/astro.config.mjs`, where `B` is the
  sha of the `base:` line task-039 wrote into its `notes:` before its first edit.
  - **`src-touched: no`:** nothing is re-run or written; this task's `notes:` reads
    `AC-9/AC-11 re-run not needed: no site/src or astro.config.mjs change in delivery-004`.
  - **`src-touched: yes`:** re-run Feature 004 § UI Specs "AC-9, manual keyboard check" and "AC-11,
    screenshots" exactly as task-034 ran them (same method rules):
    - **Path A** (the work-folder script `.aid/works/work-005-site-rework/checks/ac9-ac11.mjs`), only when
      Playwright and a browser are already on the machine, with no download and no change to
      `site/package.json`: overwrite the eight files in `.aid/works/work-005-site-rework/screenshots/` and
      rewrite the "Keyboard check (AC-9)" and "Screenshots (AC-11)" tables of `site-audit.md` in the forms
      task-034 defines, with the new date.
    - **Path B** (no browser can be started without a download): the task is NOT marked `Failed`. Write the
      maintainer's manual checklist under each of the two tables (as task-034 defines it), set every data cell
      of both tables (the Page column excepted) to exactly `awaiting maintainer run`, and keep (task-034 Path B
      put it there) or add, under EACH of the two tables, the line
      `AC-9 and AC-11 are unproven: awaiting maintainer run.` (two lines in all); this task's `notes:`
      reads `AC-9/AC-11 awaiting maintainer manual run (unproven)`, and the task ends `Done`. task-049 carries
      that open status into the final report.
  - **Contact submit, when `src-touched: yes` and the diff above lists `site/src/components/ReportForm.astro` or
    a file under `site/src/content/docs/contact/`:** re-run the contact-request submit that task-034 records
    (Path A, step 4 of its script: read the link's `href`) and rewrite the Correction cell of the
    `src/content/docs/contact/contact-request.mdx` row of § Pages with the newly observed `mailto:` URL and the
    new date. On Path B, append to that cell the sentence `Re-check after a form change awaiting maintainer run
    (unproven).`, leaving the earlier observation in place. When neither file changed, the row is untouched.
  - Preview from `site/`: `npm run build && npm run preview` (local only).
- A failing stop, a clipped text or a `false` (Path A) is not fixed here: the task ends `Failed`, naming
  task-039 as the owner of the regression.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other than
  `npm ci` / `npm install` run from `site/` (the preview server is local); no edit under `canonical/` or `site/`;
  no change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB
  documents, `.aid/works/work-005-site-rework/`), and inside it no file other than `site-audit.md`, the eight
  screenshots and (Path A) `checks/ac9-ac11.mjs`; `.github/workflows/docs.yml` is neither edited nor run here.

**Acceptance Criteria:**

Run from the repo root. Let `A=.aid/works/work-005-site-rework/site-audit.md`,
`S=.aid/works/work-005-site-rework/screenshots`, `B` the sha on the `base:` line of task-039's `STATE.yml`
`notes:`, and `C=$(git log -1 --format=%H "$B"..HEAD -- site/src site/astro.config.mjs)` (the last commit of
task-039 that touched them; empty when `src-touched: no`).

- [ ] Decision recorded: this task's `STATE.yml` `notes:` holds exactly one of the "not needed" sentence, the
  Path A result, or `AC-9/AC-11 awaiting maintainer manual run (unproven)`; it is the "not needed" sentence
  exactly when `git diff --name-only "$B" HEAD -- site/src site/astro.config.mjs` prints nothing, which agrees
  with task-039's `src-touched:` value.
- [ ] When `src-touched: no`: before this task ends, `git status --porcelain $A $S` prints nothing (nothing
  re-recorded).
- [ ] When `src-touched: yes`, Path A, AC-9: `sed -n '/^## Keyboard check (AC-9)/,/^## /p' $A` holds two rows (`/`,
  `/skills/aid-define/`), each with the expected stop order of Feature 004 § UI Specs, `yes (<n>/<n> stops)` with
  equal numbers, Result `pass` with a method and a `YYYY-MM-DD` date not earlier than
  `git log -1 --format=%cs "$C"`, and no `pending` or `awaiting`.
- [ ] When `src-touched: yes`, Path A, AC-11: with `T=$(git log -1 --format=%ct "$C")`,
  `for f in home-320-light home-320-dark home-1280-light home-1280-dark aid-define-320-light aid-define-320-dark aid-define-1280-light aid-define-1280-dark; do test -s "$S/$f.png" && [ "$(stat -c %Y "$S/$f.png")" -gt "$T" ] || echo "stale or missing: $f"; done`
  prints nothing, and
  `sed -n '/^## Screenshots (AC-11)/,/^## /p' $A | grep -o 'scrollWidth <= innerWidth: true' | wc -l` prints `8`;
  the reviewer opens each of the eight screenshots and finds no clipped text and no horizontal scrollbar.
- [ ] When `src-touched: yes`, Path A, the AC-9 and AC-11 tables are final:
  `sed -n '/^## Keyboard check (AC-9)/,/^## Knowledge Base/p' $A | grep -cE 'pending|awaiting|false'` prints `0`.
- [ ] When `src-touched: yes`, Path B: every data cell is the open marker --
  `sed -n '/^## Keyboard check (AC-9)/,/^## Knowledge Base/p' $A | grep -E '^\| /' | grep -vcE '^\| /(skills/aid-define/)? \|( awaiting maintainer run \|)+$'`
  prints `0` and the same pipeline without the last `grep -v` (`... | grep -cE '^\| /'`) prints `4`;
  `grep -cF 'AC-9 and AC-11 are unproven: awaiting maintainer run.' $A` prints `2` (one under each table, as
  task-034 Path B and task-035 expect); this task's `State` is
  `Done`, not `Failed`.
- [ ] Contact submit follows the form: when `git diff --name-only "$B" HEAD -- site/src/components/ReportForm.astro site/src/content/docs/contact`
  prints a path (and `src-touched: yes`), on Path A
  `grep -F '| `src/content/docs/contact/contact-request.mdx` ' $A | grep -cE 'subject=AID%3A%20request|AID: request for a conversation'`
  prints `1` and that row names a date not earlier than `git log -1 --format=%cs "$C"`; on Path B the same row
  contains `Re-check after a form change awaiting maintainer run (unproven).`. When that diff prints nothing,
  before this task's commit `git diff -U0 -- $A | grep -c '^[-+].*contact-request.mdx'` prints `0`.
- [ ] Deterministic, clean setup and teardown (TEST default): the preview server is stopped at the end
  (`curl -s -o /dev/null http://localhost:4321/` fails), and the run creates no file outside `site/dist/`,
  `site/node_modules/`, `$S`, `$A`, `.aid/works/work-005-site-rework/checks/` and this task's `STATE.yml`.
- [ ] All acceptance criteria from the source feature covered (TEST default): AC-9 and AC-11 each map to one
  Path A criterion above and to the Path B criterion, and the Feature 005 Data Model 4 submit to the contact
  criterion.
- [ ] Scope (AC-13, NFR-5): `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; this task leaves `git status --porcelain site` empty; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task --
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
