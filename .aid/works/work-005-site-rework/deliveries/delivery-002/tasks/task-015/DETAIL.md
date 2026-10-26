# task-015: Guides pages audited and rewritten

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

**Depends on:** task-008, task-010, task-014

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for the four Guides pages, under `site/src/content/docs/guides/`:
  - `installation.mdx` (/guides/installation/), sources INS, CLI, VER;
  - `pipeline.mdx` (/guides/pipeline/), sources SK (the phase skills), TPL, RULES;
  - `dashboard.mdx` (/guides/dashboard/), sources DASH, CLI;
  - `maintainer.mdx` (/guides/maintainer/), sources REL, GEN.
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3
  (CLI commands and flags with `bash bin/aid -h` and `bash bin/aid <command> -h` under a throwaway `HOME`;
  release steps against `docs/release.md`, `release.sh` and `.claude/skills/release-aid/SKILL.md`; dashboard
  behaviour against `dashboard/README.md`); correct each false or stale claim and delete one no source can
  prove; bring the page in line with rules P1-P9. Guides give steps; a fact owned by a Concepts or
  Reference page is linked, not restated (P9). The first use of a glossary term links to its anchor (P2).
- Diagram hosts: the words around `<TaskLoop />` (D10, under `### Phase 6 — Execute` in `pipeline.mdx`) and
  `<ReleaseFlow />` (D9, in `maintainer.mdx`) are this task's; the components are not edited (tasks 008 and
  010). These rows are final only now, after their diagrams are in place (PLAN.md delivery-002 Notes).
  The "pipeline at a glance" section of `pipeline.mdx` keeps its link to `/concepts/pipeline/`.
- Diagram words: Feature 001's audit row covers the words of the diagrams on its page (Feature 003 § Data
  Model, "Feature 001's audit row for the host page covers the diagram's words like any other text on
  it"). Check the `title`, `desc`, `caption` and text equivalent of D10 (`TaskLoop.astro`) against the
  sources Feature 003 cites for it (`canonical/skills/aid-execute/SKILL.md` § State Detection and
  § Dispatch; `references/state-delivery-gate.md`, opening paragraph) and record the result in the
  `guides/pipeline.mdx` row, naming D10. Check those of D9 (`ReleaseFlow.astro`) against
  `.github/workflows/release.yml` (trigger, jobs, `needs:`, `if:`) and the release steps of
  `docs/release.md` and `release.sh`, and record the result in the `guides/maintainer.mdx` row, naming
  D9. The components are not edited here: a diagram word that a source contradicts is recorded in the
  row and raised as a Q&A entry in the work's `STATE.yml` (`qa:`), because Feature 003 specifies those
  words.
- The `<Tabs>` blocks stay: Feature 004 turns them into sections in delivery-003.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`: the four rows of § Pages take `ok` or
  `corrected`, one sentence per change naming the source that proved it. Remove `/guides/pipeline/` and
  `/guides/maintainer/` from the Page cells of § Leads found at Specify after moving each lead into its
  page row; a lead row left with no page is deleted.
- Not in this task:
  - Every other page; no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change.
  - Nothing is run from the maintainer steps: `release.sh`, tags and publishing are read, never run.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the four pages and the audit file change; the executor may also append a `qa:`
    entry to the work's `STATE.yml` as stated above.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='guides/installation.mdx guides/pipeline.mdx guides/dashboard.mdx guides/maintainer.mdx'
U='/guides/installation/ /guides/pipeline/ /guides/dashboard/ /guides/maintainer/'
```

- [ ] Audit rows final: `for f in $P; do row "$f"; done` prints nothing.
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
- [ ] Leads settled: `for u in $U; do leads "$u"; done` prints nothing.
- [ ] Diagrams kept in place: `grep -c '<TaskLoop' $D/guides/pipeline.mdx` and
  `grep -c '<ReleaseFlow' $D/guides/maintainer.mdx` each print `1`;
  `awk '/^### Phase 6/{f=1;next} /^#/{f=0} f&&/<TaskLoop/' $D/guides/pipeline.mdx | wc -l` prints `1`;
  `grep -c '](/concepts/pipeline/' $D/guides/pipeline.mdx` prints at least `1`.
- [ ] Diagram words checked and recorded (the rows read `pending` with an empty Correction cell before
  this task, so both commands print `0` before it): `grep -F 'src/content/docs/guides/pipeline.mdx' "$A" | grep -c 'D10'`
  and `grep -F 'src/content/docs/guides/maintainer.mdx' "$A" | grep -c 'D9'` each print `1` (each path
  occurs in one line of the audit file, its § Pages row). The
  reviewer re-checks the D9 and D10 words named in those rows against the sources above; a word a source
  contradicts and that is neither recorded in the row nor raised in `qa:` fails this criterion.
- [ ] CLI commands exist: every `aid <command>` in a code block of these pages names a command that
  `bash ../bin/aid -h` lists (run with `HOME=$(mktemp -d)`); the reviewer lists the commands found with
  `grep -ohE '^\s*aid [a-z-]+' $D/guides/*.mdx | sort -u` and checks each against that help output.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/guides -name '*.html' -size +150k` prints nothing; `links | grep '^/guides/'` prints nothing.
  After the build, `grep -o '<figure class="diagram' dist/guides/pipeline/index.html | wc -l` and the same
  for `dist/guides/maintainer/index.html` each print `1`.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts fails this criterion.
- [ ] P2, P3 and P6 (judged by the reviewer against Feature 001 rules P2, P3 and P6): the first use of each
  glossary term links to `/reference/glossary/#<anchor>` or is explained in the same sentence; short
  active sentences addressed to "you"; every command in a code block, copyable, exactly as the CLI or
  SKILL.md defines it.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only the four
    pages under `site/src/content/docs/guides/`.
  - `git tag --points-at HEAD` prints nothing.
