# task-016: Concepts landing and pipeline pages audited and rewritten

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

**Depends on:** task-008, task-009, task-015

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for two Concepts pages, under `site/src/content/docs/concepts/`:
  - `methodology.mdx` (/concepts/methodology/), renamed by task-005; sources SK, AG, SC, TPL, RULES; DOC
    `docs/aid-methodology.md` as a starting text only. It is the Concepts landing page: a short intro that
    links to each Concepts page, then § 2 Philosophy, which hosts D3 `<ReviewLoop />` (task-009);
  - `pipeline.mdx` (/concepts/pipeline/), split from the old §§ 1 and 4 by task-005; sources SK, SC, RULES.
    It hosts D1 `<Pipeline />` and D2 `<TwoPaths />` (task-008).
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3
  (phase names and order against `canonical/aid/rules.md` § Workflow; a skill's states, agents and outputs
  against its SKILL.md state table; shortcut verbs and groups against SC); correct each false or stale
  claim and delete one no source can prove; bring the page in line with rules P1-P9. Concepts pages
  explain; facts owned by a Reference page or a generated page are linked, not restated (P9). The first use
  of a glossary term links to its anchor (P2).
- Diagram words: Feature 001's audit row covers the words of the diagrams on its page (Feature 003 § Data
  Model, "Content of each diagram"). Check the `title`, `desc`, `caption` and text equivalent of D1, D2 and
  D3 against the sources Feature 003 cites for each, and record the result in the host row. The diagram
  components are not edited here: a diagram word that a source contradicts is recorded in the row and
  raised as a Q&A entry in the work's `STATE.yml` (`qa:`), because Feature 003 specifies those words.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`:
  - `concepts/methodology.mdx` takes `corrected` (it was renamed and cut down), one sentence per change
    naming the source; the "planned: ..." text of its Correction cell is replaced by what was done;
  - `concepts/pipeline.mdx` takes `new`; its Correction cell says it was split from the old §§ 1 and 4 and
    lists each correction with its source.
  - Remove `/concepts/methodology/` from the Page cells of § Leads found at Specify after moving each lead
    into the page row; a lead row left with no page is deleted, with one exception below.
  - The task-state lead ("Says a task's review history lives in its own `STATE.md`") is confirmed or
    dismissed against SK `aid-execute` and TPL `task-state-template.yml`, and applied to the sentences of
    both pages here (after task-005's split they sit in `concepts/pipeline.mdx`: Phase 5 and Phase 6
    outputs, the work-folder tree). The same claim also moved, with the old § 7, into
    `reference/artifacts.md` (the `STATE.md (task area)` and `STATE.md (delivery area)` rows of Core
    Artifacts and the review-history sentence under that table), which task-021 audits. So this lead row
    is not deleted: its Page cell becomes `/reference/artifacts/` and its Lead text gains the verdict
    reached here and the source that proved it, so task-021 applies the same verdict there.
- MDX: a literal `{`, `}` or `<` outside code stays escaped (`\{`, `\}`, `&lt;`). The `sourceDoc:` line of
  `methodology.mdx` stays (Feature 005 step 4 removes it in delivery-003).
- Not in this task:
  - Every other page; no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the two pages and the audit file change; the executor may also append a `qa:`
    entry to the work's `STATE.yml` as stated above.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='concepts/methodology.mdx concepts/pipeline.mdx'
U='/concepts/methodology/ /concepts/pipeline/'
```

- [ ] Audit rows final: `row concepts/methodology.mdx` and `row concepts/pipeline.mdx new` print nothing,
  and `grep -F 'concepts/methodology.mdx' "$A" | grep -c 'planned:'` prints `0`.
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
- [ ] Task-state lead handed on, not lost (before this task the row's Page cell is `/concepts/methodology/`,
  so this prints `0`): `sed -n '/^## Leads found at Specify/,$p' "$A" | grep -F "review history lives in its own" | grep -c '^| /reference/artifacts/ |'`
  prints `1`.
- [ ] Landing intro and diagrams kept: for each `p` in `pipeline knowledge-base agents feedback-loops
  case-studies aid-and-sdd`, `grep -c "](/concepts/$p/" $D/concepts/methodology.mdx` prints at least `1`;
  `grep -c '<ReviewLoop' $D/concepts/methodology.mdx`, `grep -c '<Pipeline' $D/concepts/pipeline.mdx` and
  `grep -c '<TwoPaths' $D/concepts/pipeline.mdx` each print `1`.
- [ ] Diagram words checked: the rows of both pages each name D1, D2 or D3 as checked
  (`grep -F 'concepts/pipeline.mdx' "$A" | grep -cE 'D1|D2'` and
  `grep -F 'concepts/methodology.mdx' "$A" | grep -c 'D3'` each print `1`).
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/concepts/methodology dist/concepts/pipeline -name '*.html' -size +150k` prints nothing;
  `links | grep -E '^/concepts/(methodology|pipeline)/ '` prints nothing. After the build,
  `grep -o '<figure class="diagram' dist/concepts/methodology/index.html | wc -l` prints `1` and the same for
  `dist/concepts/pipeline/index.html` prints `2`.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least ten
  unchanged claims across the two pages with the checks of Feature 001 § Feature Flow step 3. A claim that a
  source contradicts fails this criterion.
- [ ] P2, P3 and P9 (judged by the reviewer against Feature 001 rules P2, P3 and P9): glossary terms linked
  on first use or explained in the same sentence; short active sentences addressed to "you"; no fact
  restated that a Reference or generated page owns.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/concepts/methodology.mdx` and `site/src/content/docs/concepts/pipeline.mdx`.
  - `git tag --points-at HEAD` prints nothing.
