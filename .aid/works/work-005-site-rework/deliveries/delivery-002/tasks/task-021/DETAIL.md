# task-021: Reference artifacts and repository structure pages audited and rewritten

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

**Depends on:** task-020

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for the last two hand-written Reference pages, under
  `site/src/content/docs/reference/`:
  - `artifacts.md` (/reference/artifacts/), sources TPL, SK (`aid-define`, `aid-plan`, `aid-detail`,
    `aid-execute`). It holds the old § 7 Artifacts Reference, merged by task-005 with each template excerpt
    replaced by a link to the template under
    `https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/`. Each artifact name
    and path is checked against `work-state-template.yml`, `task-state-template.yml`,
    `delivery-state-template.yml`, `requirements/requirements-template.md`, `task-detail-template.md` and
    the SKILL.md that writes it; each template link names a file that exists under `canonical/aid/templates/`;
  - `repository-structure.md` (/reference/repository-structure/), sources DOC `docs/repository-structure.md`
    as a starting text, REPO (`git ls-files` at the top level and `.aid/knowledge/project-structure.md`).
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3;
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. Reference pages list facts; explanations are linked to the Concepts page that owns them (P9). The
  first use of a glossary term links to its anchor (P2). Rule P5 binds in full on `artifacts.md` (a Specify
  lead names `/reference/artifacts/`); an example argument in a command stays allowed.
- Task-state lead on `artifacts.md`. The lead "Says a task's review history lives in its own `STATE.md`"
  reaches this page through task-016, which settled it for the Concepts pages and re-pointed its Page cell
  to `/reference/artifacts/` with its verdict and source. The claim came here with the old § 7: the
  `STATE.md (task area)` and `STATE.md (delivery area)` rows of Core Artifacts and the sentence under that
  table saying the review history is recorded in the task's own `STATE.md`. Each is checked against SK
  `aid-execute` (it names `deliveries/delivery-NNN/tasks/task-NNN/STATE.yml` for the task state) and TPL
  `task-state-template.yml` and `delivery-state-template.yml`, and corrected; the page's existing
  `STATE.yml` rows are the ones kept, so no artifact is listed twice.
- `artifacts.md` keeps its "Sync manifest" and "Reference manifest" rows unchanged (PLAN.md delivery-002
  Notes): Feature 005 step 4 deletes them in delivery-003 and updates this row then.
- The `sourceDoc:` frontmatter line of `repository-structure.md` stays: Feature 005 step 4 removes it in
  delivery-003. `docs/repository-structure.md` outside `site/` is read, never edited.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`: the two rows of § Pages take `ok` or
  `corrected`, one sentence per change naming the source that proved it; the "planned: absorbs methodology
  § 7" text of the `reference/artifacts.md` row is replaced by what was done. Remove `/reference/artifacts/`
  from the Page cells of § Leads found at Specify after moving the lead into its page row; a lead row left
  with no page is deleted.
- Not in this task:
  - Every other page; no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`. Template links are checked against
    the local `canonical/aid/templates/` tree, never fetched.
  - No edit under `canonical/` or `docs/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the two pages and the audit file change.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='reference/artifacts.md reference/repository-structure.md'
U='/reference/artifacts/ /reference/repository-structure/'
```

- [ ] Audit rows final: `for f in $P; do row "$f"; done` prints nothing, and
  `grep -F 'reference/artifacts.md' "$A" | grep -c 'planned:'` prints `0`.
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
- [ ] Every `/aid-...` command named on the pages is a skill or a shortcut-catalog row:
  `cmds $(for f in $P; do echo "$D/$f"; done)` prints nothing.
- [ ] Leads settled: `for u in $U; do leads "$u"; done` prints nothing (this includes the task-state lead
  that task-016 re-pointed here).
- [ ] Task-state claim corrected on `artifacts.md` (after task-005's merge these patterns match the § 7
  rows and sentence, so this prints at least `1` before this task):
  `grep -cE 'STATE\.md \((task|delivery) area\)|task-NNN/STATE\.md|task.s own .?STATE\.md' $D/reference/artifacts.md`
  prints `0`, and ``grep -F "| \`$D/reference/artifacts.md\` " "$A" | grep -c 'STATE.yml'`` prints `1`
  (the page row, matched the way `row` matches it, records the correction and its source).
- [ ] Template links resolve locally: the loop
  `grep -oE 'canonical/aid/templates/[A-Za-z0-9_./-]+' $D/reference/artifacts.md | sort -u | while read -r t; do test -e "../$t" || echo "no template: $t"; done`
  prints nothing, and `grep -cE '^## [0-9]+\. (Objective|Problem Statement)' $D/reference/artifacts.md`
  prints `0`.
- [ ] Manifest rows kept for delivery-003: `grep -c 'Sync manifest' $D/reference/artifacts.md` and
  `grep -c 'Reference manifest' $D/reference/artifacts.md` each print at least `1`, and
  `git diff site-aid -- $D/reference/artifacts.md | grep -E '^[-+]' | grep -E '(Sync|Reference) manifest'`
  prints nothing (those rows are byte-for-byte as on `site-aid`).
- [ ] Repository layout true: every top-level path the page names as a folder or file in a layout table or
  tree exists; the reviewer lists them and checks each with `git -C .. ls-files | cut -d/ -f1 | sort -u`.
  `grep -c '^sourceDoc:' $D/reference/repository-structure.md` prints `1`; from the repo root,
  `git status --porcelain docs` prints nothing.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/reference/artifacts dist/reference/repository-structure -name '*.html' -size +150k` prints
  nothing; `links | grep -E '^/reference/(artifacts|repository-structure)/ '` prints nothing.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page (artifact paths against TPL and the writing SKILL.md, layout against REPO) with
  the checks of Feature 001 § Feature Flow step 3. A claim that a source contradicts fails this criterion.
- [ ] P2, P3 and P9 (judged by the reviewer against Feature 001 rules P2, P3 and P9): glossary terms linked
  on first use or explained in the same sentence; short active sentences addressed to "you"; explanations
  linked to their Concepts page.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical docs` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/reference/artifacts.md` and `site/src/content/docs/reference/repository-structure.md`.
  - `git tag --points-at HEAD` prints nothing.
