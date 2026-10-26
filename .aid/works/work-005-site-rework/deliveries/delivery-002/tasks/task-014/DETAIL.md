# task-014: Your first work and shortcuts pages audited and rewritten

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

**Source:** feature-001-content-audit -> delivery-002 -> AC-3, AC-12

**Depends on:** task-012, task-013

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for the last two Get Started pages, under `site/src/content/docs/`:
  - `get-started/first-work.mdx` (/get-started/first-work/), sources SK (`aid-config` to `aid-execute`), TPL,
    RULES; DOC `docs/aid-methodology.md` § 10 as a starting text only;
  - `get-started/lite-path.mdx` (/get-started/lite-path/), sources SC and SK (`aid-triage` and the shortcut
    doorways).
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3;
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. P2 binds here in full: the first use of each glossary term (an `###` heading of
  `reference/glossary.md`, task-012) links to `/reference/glossary/#<anchor>`, or the term is explained in
  the same sentence.
- Merged text (moved here by task-005, Feature 001 § Migration Plan):
  - `first-work.mdx` holds the brownfield and greenfield starts of the old Adoption Guide, plus its
    "Using the Direct-Entry Shortcuts" and "Adopting Incrementally" text. Rule P9 applies: shortcut facts
    are stated on `lite-path.mdx`, and `first-work.mdx` links to that page instead of repeating them.
  - `lite-path.mdx` holds the shortcut-engine text of the removed `reference/skills.md`. The duplicate
    wording is removed, so each engine fact is stated once on the page.
- Get Started frontmatter (§ Migration Plan): `first-work.mdx` gets `sidebar.order` 3 and `sidebar.label`
  "Your first work"; `lite-path.mdx` gets order 4 and label "Small changes with shortcuts". Each title is
  plain, at most about six words, and each `description` is the page's P1 sentence.
- Commands are written exactly as the SKILL.md `argument-hint` or the shortcut catalog defines them (P6).
- Record, in `.aid/works/work-005-site-rework/site-audit.md`: the two rows of § Pages take `ok` or
  `corrected`, one sentence per change naming the source that proved it; the "planned: absorbs ..." text
  of their Correction cells is replaced by what was actually done. Remove `/get-started/lite-path/` from
  the Page cells of § Leads found at Specify after moving the lead into the page row; a lead row left with
  no page is deleted.
- Not in this task:
  - Every other page, and no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
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
P='get-started/first-work.mdx get-started/lite-path.mdx'
U='/get-started/first-work/ /get-started/lite-path/'
```

- [ ] Audit rows final: `for f in $P; do row "$f"; done` prints nothing, and
  `grep -F 'get-started/' "$A" | grep -c 'planned: absorbs'` prints `0`.
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
- [ ] Get Started order and labels: in `$D/get-started/first-work.mdx`,
  `grep -cE "^  label: ['\"]?Your first work['\"]?$"` and `grep -c '^  order: 3$'` each print `1`; in
  `$D/get-started/lite-path.mdx`, `grep -cE "^  label: ['\"]?Small changes with shortcuts['\"]?$"` and
  `grep -c '^  order: 4$'` each print `1`.
- [ ] Merged text kept and not repeated: `grep -cE '^#+ .*(Brownfield|Greenfield)' $D/get-started/first-work.mdx`
  prints `2`; `grep -c '](/get-started/lite-path/' $D/get-started/first-work.mdx` prints at least `1`;
  `grep -ci 'shortcut engine' $D/get-started/lite-path.mdx` prints at least `1`, and
  `grep '^#' $D/get-started/lite-path.mdx | sort | uniq -d` prints nothing.
- [ ] P2, glossary links present: `for f in $P; do grep -q '](/reference/glossary/#' "$D/$f" || echo "no glossary link: $f"; done`
  prints nothing. The reviewer then judges, for each glossary `###` term used on these pages
  (`grep '^### ' $D/reference/glossary.md`), that its first use links to its anchor or is explained in the
  same sentence (Feature 001 rule P2).
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/get-started -name '*.html' -size +150k` prints nothing;
  `links | grep -E '^/get-started/(first-work|lite-path)/ '` prints nothing.
- [ ] Previous/next path: `grep -oE '<a [^>]*rel="next"[^>]*>' dist/get-started/install/index.html | grep -c 'href="/get-started/first-work/"'`
  prints `1`, and `grep -oE '<a [^>]*rel="next"[^>]*>' dist/get-started/first-work/index.html | grep -c 'href="/get-started/lite-path/"'`
  prints `1`.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page (phase order against RULES § Workflow, shortcut names, verbs and groups against
  SC, artifact paths against TPL) with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts fails this criterion.
- [ ] P3 and P6 (judged by the reviewer against Feature 001 rules P3 and P6): short active sentences
  addressed to "you"; every command in a code block, copyable, exactly as the SKILL.md or catalog defines it.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/get-started/first-work.mdx` and `site/src/content/docs/get-started/lite-path.mdx`.
  - `git tag --points-at HEAD` prints nothing.
