# task-034: Keyboard check and responsive screenshots recorded in the audit

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

**Source:** feature-004-look-and-layout, feature-005-machinery-cut -> delivery-003 -> AC-9, AC-11 (Feature 004
§ UI Specs); the manual `mailto:` submit and the contact-request audit sentence (Feature 005 § Data Model 4,
first bullet)

**Depends on:** task-033

**Scope:**
- On the final look (every file of delivery-003 that changes `site/src/` or `astro.config.mjs` is done), run
  Feature 004 § UI Specs "AC-9, manual keyboard check" and "AC-11, screenshots", and the one manual submit of the
  contact form that Feature 005 § Data Model 4 (first bullet) asks the audit to record. Preview from `site/`:
  `npm run build && npm run preview` (`http://localhost:4321/`, local only).
- Method, chosen in this order (AC-9 allows "a recorded Playwright script or a manual checklist in the audit"):
  - **Path A, recorded script (agent).** Only when a Playwright library and a browser binary are already on the
    machine: no `npx playwright install`, no download, and no change to `site/package.json`. The script is
    `.aid/works/work-005-site-rework/checks/ac9-ac11.mjs` (work folder, outside `site/`, so it is neither a site
    test nor counted by AC-4). It (1) opens `/` and `/skills/aid-define/` at 1280 x 800, presses Tab from the
    top until focus reaches "Report a problem with this page on GitHub", and for each stop records the focused
    element's accessible name (at 1280 px the brand link's name is "AID AI Integrated Development", because the
    `aid-brand-long` span is visible above 50rem; it is recorded as it is) and whether its computed
    `outline-style` is not `none` with `outline-width` of at least 3px; (2) checks Enter on "Skip to content" moves focus to the `h1`, and Enter/Escape on "Search" opens and
    closes the dialog; (3) for each page, width 320 and 1280 (height 800) and theme Light and Dark (set through
    the theme select, or at 320 px, where it sits in the menu, by `localStorage['starlight-theme']` plus a
    reload, which is what the select stores), saves a viewport screenshot named
    `<home|aid-define>-<320|1280>-<light|dark>.png` into `.aid/works/work-005-site-rework/screenshots/` and
    prints `document.documentElement.scrollWidth <= window.innerWidth`; (4) submits the `contact-request` form
    with a body containing spaces and records the `mailto:` URL the browser navigates to (intercepted, nothing
    sent).
  - **Path B, manual checklist (maintainer).** When no browser can be launched without a download, the
    executor writes the checklist into the audit (below) with every cell of the "Keyboard check (AC-9)" and
    "Screenshots (AC-11)" tables exactly `awaiting maintainer run`; adds "Manual mailto submit: awaiting
    maintainer run." to the `contact-request` row's Correction cell; adds under each of the two tables the note
    `AC-9 and AC-11 are unproven: awaiting maintainer run.`; sets this task's `STATE.yml`
    `notes: AC-9/AC-11 unproven, awaiting maintainer run (Path B)`; and ends the task `Done`. Path B is a
    planned, non-failing outcome: it does not block task-035, and the open AC-9/AC-11 status is carried by
    task-035 into the delivery's final report. The maintainer later runs the checklist in a desktop browser
    exactly as Feature 004 § UI Specs states it, saves the eight screenshots and fills the rows; the Path A
    criteria below are then the check of those rows. Nothing is recorded as observed that was not observed.
- What to write into `.aid/works/work-005-site-rework/site-audit.md`:
  - "Keyboard check (AC-9)" table, one row per page (`/`, `/skills/aid-define/`): "Tab order observed" = the
    observed stops in order, comma-separated, in the form `Skip to content, Casulo AI Labs, AID AI Integrated
    Development, GitHub, Select theme, Search, sidebar (<n> stops), On this page (<n> stops, or none), content
    (<n> stops), Previous, Next, Report a problem with this page on GitHub` (the first six stops by their
    accessible names at 1280 px; a manual run that reads the visible text writes the brand stop `AID` or
    `AID AI Integrated Development`, both accepted; a page with no previous or next link omits that stop);
    "Focus ring visible each step" = `yes (<n>/<n> stops)`;
    "Result" = `pass` or `fail: <stop>`, followed by the method and date (`Playwright, checks/ac9-ac11.mjs,
    <YYYY-MM-DD>` or `manual, maintainer, <browser and version>, <YYYY-MM-DD>`). Path B: under the table, the
    checklist (the preview commands, the two URLs, a line starting `Expected stops` that copies the stop order
    of Feature 004 § UI Specs, "focus ring visible, no trap"), the unproven note, and every one of the six
    cells `awaiting maintainer run`.
  - "Screenshots (AC-11)" table: each of the eight cells = `<file name>, scrollWidth <= innerWidth: true` (or
    `false`); Path B: every one of the eight cells `awaiting maintainer run` and, under the table, the
    screenshot steps of Feature 004 § UI Specs and the unproven note.
  - The `src/content/docs/contact/contact-request.mdx` row: one sentence with the observed `mailto:` URL (or, by
    hand, the subject line seen in the mail client), showing `subject=AID%3A%20request%20for%20a%20conversation`
    or the subject text with spaces, not `+`; Path B: the sentence "Manual mailto submit: awaiting maintainer
    run." added to the row's Correction cell.
- On Path A, a failing stop, a clipped text or a `false` is not fixed here: the task ends `Failed`, naming the
  task that owns the cause (task-024 styles, task-025 header, task-032 footer/form). That is a real defect,
  unlike Path B.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other than
  `npm ci` / `npm install` run from `site/` (the preview server is local); no edit under `canonical/` or `site/`;
  no change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB
  documents, `.aid/works/work-005-site-rework/`), and inside it no file other than `site-audit.md`, the eight
  screenshots and (Path A) `checks/ac9-ac11.mjs`.

**Acceptance Criteria:**

Run from the repo root (bash) unless stated. Let `A=.aid/works/work-005-site-rework/site-audit.md`,
`S=.aid/works/work-005-site-rework/screenshots`,
`KB() { sed -n '/^## Keyboard check (AC-9)/,/^## /p' "$A"; }` and `SH() { sed -n '/^## Screenshots (AC-11)/,/^## /p' "$A"; }`.
In the audit-row patterns, each `.` around a path stands for the backtick the audit row puts there.

- [ ] Path recorded: this task's `STATE.yml` `notes:` names the path taken, `Path A` or `Path B`:
  `grep -oE 'Path [AB]' .aid/works/work-005-site-rework/deliveries/delivery-003/tasks/task-034/STATE.yml | sort -u | wc -l`
  prints `1`. Exactly the criteria group of that path applies below, and every criterion of it holds.

Path A (a browser was available; AC-9 and AC-11 proven):

- [ ] Screenshots (AC-11): `for p in home aid-define; do for w in 320 1280; do for t in light dark; do test -s $S/$p-$w-$t.png || echo "missing: $p-$w-$t"; done; done; done`
  prints nothing, and `ls $S | wc -l` prints `8`.
- [ ] No sideways scroll recorded: `SH | grep -o 'scrollWidth <= innerWidth: true' | wc -l` prints `8`, and
  `SH | grep -cE 'false|pending|awaiting'` prints `0`.
- [ ] No clipped text (AC-11, judged by the reviewer): the reviewer opens each of the eight screenshots and
  confirms no text is cut off and no horizontal scrollbar shows; at 320 px the header shows the logo, "AID",
  the search button and the menu button only (Feature 004 § UI Specs, "Layout"). Any finding names the file.
- [ ] Keyboard (AC-9), stop order, equal focus counts, pass, method and date in one pattern (the brand stop is
  accepted as `AID` or as its 1280 px accessible name `AID AI Integrated Development`; `\3` requires the two
  numbers of `yes (n/n stops)` to be equal):
  `KB | grep -cE '^\| /(skills/aid-define/)? \| Skip to content, Casulo AI Labs, AID( AI Integrated Development)?, GitHub, Select theme, Search, .*Report a problem with this page on GitHub \| yes \(([0-9]+)/\3 stops\) \| pass[,;] (Playwright, checks/ac9-ac11\.mjs|manual, maintainer, [^|]+), [0-9]{4}-[0-9]{2}-[0-9]{2} \|$'`
  prints `2`, and `KB | grep -cE 'pending|awaiting'` prints `0`.
- [ ] Recorded script (when the agent ran it): `test -f .aid/works/work-005-site-rework/checks/ac9-ac11.mjs` exits
  0, and running it again with `node` against a fresh preview prints the same stop lists and eight `true` values
  (deterministic, TEST default). Skipped only when the Result cells say `manual, maintainer`.
- [ ] Contact submit recorded:
  `grep -E '^\| .src/content/docs/contact/contact-request\.mdx. ' $A | grep -cE 'subject=AID%3A%20request|AID: request for a conversation'`
  prints `1`.

Path B (no browser could be started without a download; the task ends `Done`, AC-9 and AC-11 unproven):

- [ ] Keyboard table awaiting: `KB | grep -cE '^\| /(skills/aid-define/)? \|( awaiting maintainer run \|){3}$'`
  prints `2`, and `KB | grep -c 'Expected stops'` prints at least `1` (the checklist is under the table).
- [ ] Screenshots table awaiting: `SH | grep -cE '^\| /(skills/aid-define/)? \|( awaiting maintainer run \|){4}$'`
  prints `2`.
- [ ] Unproven note: `grep -cF 'AC-9 and AC-11 are unproven: awaiting maintainer run.' $A` prints `2`;
  `grep -E '^\| .src/content/docs/contact/contact-request\.mdx. ' $A | grep -cF 'Manual mailto submit: awaiting maintainer run.'`
  prints `1`; `grep -c 'AC-9/AC-11 unproven, awaiting maintainer run (Path B)' .aid/works/work-005-site-rework/deliveries/delivery-003/tasks/task-034/STATE.yml`
  prints `1`.
- [ ] Nothing claimed as observed: `test -e $S` exits 1 or `ls $S | wc -l` prints `0`;
  `SH | grep -c 'scrollWidth <= innerWidth: true'` prints `0`; `KB | grep -cE '\| (pass|fail)'` prints `0`.

Both paths:
- [ ] Clean setup and teardown (TEST default): the preview server is stopped at the end (`curl -s -o /dev/null http://localhost:4321/`
  fails); `git status --porcelain site` prints nothing; nothing was written outside `$A`, `$S/`,
  `.aid/works/work-005-site-rework/checks/`, `.aid/.temp/` and this task's `STATE.yml`.
- [ ] All acceptance criteria from the source features covered (TEST default): AC-9 (both pages) and AC-11 (eight
  screenshots) as Feature 004 § UI Specs states them, plus the Data Model 4 manual submit of Feature 005 -- on
  Path A each is proven by the Path A group; on Path B each is recorded as unproven by the Path B group (no
  other outcome is allowed).
- [ ] Scope (AC-13, NFR-5): `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task --
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
