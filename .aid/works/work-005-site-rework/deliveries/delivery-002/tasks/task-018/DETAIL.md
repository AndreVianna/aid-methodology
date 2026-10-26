# task-018: Concepts feedback loops and AID-and-SDD pages audited and rewritten

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

**Source:** feature-001-content-audit -> delivery-002 -> AC-3

**Depends on:** task-010, task-017

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for two Concepts pages, under `site/src/content/docs/concepts/`:
  - `feedback-loops.mdx` (/concepts/feedback-loops/), split from the old § 6 by task-005; sources SK,
    `canonical/aid/templates/feedback-artifacts/`. It hosts D7 `<FeedbackLoops />` (task-010) and keeps its
    prose explanation of the loops;
  - `aid-and-sdd.mdx` (/concepts/aid-and-sdd/), split from the old § 9 by task-005; source DOC
    `docs/aid-methodology.md` § 9 as a starting text, and for every claim about AID the checks of Feature 001
    § Feature Flow step 3 (phase names and order against `canonical/aid/rules.md` § Workflow, skills against
    SK). It hosts D8 `<AidVsSdd />` (task-010).
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3;
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. The first use of a glossary term links to its anchor (P2). Facts owned by another page are linked,
  not restated (P9).
- D7 loop table (Feature 003 § Data Model, D7 "Source": the table "after Feature 001's audit of that
  section"). Each row of the `<table>` in the `slot="text"` of
  `site/src/components/diagrams/FeedbackLoops.astro` (L1-L11: Loop | From | To | When) is checked against
  SK (the skill that sends the work back and the skill it returns to). A wrong From, To or When cell is
  corrected in that file, inside the table only, and only in its words: this is the documentation half
  of D7 (Feature 003 hands the table's content to "Feature 001's audit of that section"), so the task
  stays one type, DOCUMENT. No tag, attribute, element, expression or line of the drawing changes; the
  component's code and markup stay task-010's. A loop that must be added or removed changes the drawing
  (badges and arcs), which Feature 003 specifies: it is not done here, but recorded in the row and raised
  as a Q&A entry in the work's `STATE.yml` (`qa:`).
- D8 words: check D8's `title`, `desc`, `caption` and text equivalent against `canonical/aid/rules.md`
  § Workflow and the skill descriptions; record the result in the `aid-and-sdd.mdx` row, including the
  correction "AI-Assisted Development" to "AI Integrated Development" made by D8 (Feature 003, D8). A D8
  word that a source contradicts is recorded and raised as a `qa:` entry; `AidVsSdd.astro` is not edited.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`:
  - `concepts/feedback-loops.mdx` takes `new`; its Correction cell says it was split from the old § 6, that
    the loop table moved into D7, and lists each correction (page or table cell) with its source;
  - `concepts/aid-and-sdd.mdx` takes `new`; its Correction cell says it was split from the old § 9 and lists
    each correction with its source.
  - No lead of § Leads found at Specify names these two URLs; none is touched.
- MDX: a literal `{`, `}` or `<` outside code stays escaped (`\{`, `\}`, `&lt;`).
- Not in this task:
  - Every other page; no component other than the table cells of `FeedbackLoops.astro`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the two pages, `FeedbackLoops.astro` and the audit file change; the executor may
    also append a `qa:` entry to the work's `STATE.yml` as stated above.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='concepts/feedback-loops.mdx concepts/aid-and-sdd.mdx'
U='/concepts/feedback-loops/ /concepts/aid-and-sdd/'
F=src/components/diagrams/FeedbackLoops.astro
```

- [ ] Audit rows final: `row concepts/feedback-loops.mdx new` and `row concepts/aid-and-sdd.mdx new` print
  nothing, and `grep -F 'concepts/feedback-loops.mdx' "$A" | grep -c '(planned)'` and the same for
  `concepts/aid-and-sdd.mdx` each print `0`.
- [ ] P1, one sentence of purpose equal to `description` (compared as plain text: a Markdown or `<a>`
  link counts as its link text and `**`, `__` and backticks are ignored, so a rule-P2 glossary link in
  the sentence is allowed): `for f in $P; do p1 "$D/$f"; done` prints nothing.
- [ ] P4, no hand-written counts: `for f in $P; do p4 "$D/$f"; done` prints nothing.
- [ ] P5, no change history and no internal ids outside code: `for f in $P; do p5 "$D/$f"; done` prints
  nothing.
- [ ] P7, link text names the destination and no bare URL: `for f in $P; do p7 "$D/$f"; done` prints nothing.
- [ ] P8, body headings start at `##`, skip no level, and no hand-written table of contents:
  `for f in $P; do p8 "$D/$f"; done` prints nothing.
- [ ] No link to a removed URL (P7, P9; the redirects of task-006 are a safety net, not a target):
  `for f in $P; do olds "$D/$f"; done` prints nothing.
- [ ] Every `/aid-...` command named on the pages and in the D7 table is a skill or a shortcut-catalog row:
  `cmds $(for f in $P; do echo "$D/$f"; done) $F` prints nothing.
- [ ] Leads settled: `for u in $U; do leads "$u"; done` prints nothing.
- [ ] D7 still holds the loops once, with the drawing unchanged: `grep -cE '<th scope="row">L([1-9]|1[01])</th>' $F`
  prints `11`; `grep -cE '^\| L([1-9]|1[01]) \|' $D/concepts/feedback-loops.mdx` prints `0`; and
  `git diff HEAD -- $F | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)' | grep -vE '<t[dh]|</t[dh]>|^[-+]\s*$'`
  prints nothing before the commit (only table-cell lines changed, if any). The markup is unchanged and
  only words between tags differ: with `sk() { tr -d '\n' | sed -E 's/>[^<]*</></g'; }`,
  `diff <(git show HEAD:site/$F | sk) <(sk < $F)` prints nothing.
- [ ] Diagrams kept: `grep -c '<FeedbackLoops' $D/concepts/feedback-loops.mdx` and
  `grep -c '<AidVsSdd' $D/concepts/aid-and-sdd.mdx` each print `1`; `grep -c 'AI-Assisted' $D/concepts/aid-and-sdd.mdx`
  prints `0`; `grep -F 'concepts/aid-and-sdd.mdx' "$A" | grep -c 'AI Integrated Development'` prints `1`;
  `grep -F 'concepts/feedback-loops.mdx' "$A" | grep -c 'D7'` prints `1`.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/concepts/feedback-loops dist/concepts/aid-and-sdd -name '*.html' -size +150k` prints nothing;
  `links | grep -E '^/concepts/(feedback-loops|aid-and-sdd)/ '` prints nothing. After the build,
  `for f in dist/concepts/feedback-loops/index.html dist/concepts/aid-and-sdd/index.html; do echo "$f $(grep -o '<figure class="diagram' "$f" | wc -l)"; done`
  prints each of the two paths followed by ` 1`.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it; the reviewer re-checks every one of the
  eleven D7 rows against SK and at least five unchanged claims on `aid-and-sdd.mdx` with the checks of
  Feature 001 § Feature Flow step 3. A claim or loop row that a source contradicts fails this criterion.
- [ ] P2, P3 and P9 (judged by the reviewer against Feature 001 rules P2, P3 and P9): glossary terms linked
  on first use or explained in the same sentence; short active sentences addressed to "you"; the loop
  facts written once (in D7's table), the page's prose explaining them without restating the table.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/concepts/feedback-loops.mdx`, `site/src/content/docs/concepts/aid-and-sdd.mdx`
    and, if a table cell was corrected, `site/src/components/diagrams/FeedbackLoops.astro`.
  - `git tag --points-at HEAD` prints nothing.
