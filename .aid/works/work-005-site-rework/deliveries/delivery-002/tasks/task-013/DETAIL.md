# task-013: Home, What is AID and Install pages audited and rewritten

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

**Depends on:** task-008, task-012

**Scope:**
- Feature 001 § Feature Flow steps 2-5, and the "start here" path of § Migration Plan, for three pages under
  `site/src/content/docs/`:
  - `index.mdx` (/), sources SK, SC, RULES, CLI, INS, VER;
  - `get-started/overview.md` (/get-started/overview/), sources SK, RULES, INS;
  - `get-started/install.md` (/get-started/install/), sources INS, CLI.
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3;
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. P2 binds here in full: the first use of each glossary term (an `###` heading of
  `reference/glossary.md`, task-012) links to `/reference/glossary/#<anchor>`, or the term is explained in
  the same sentence.
- Home page (`index.mdx`), per § Migration Plan, "start here" path:
  - its purpose sentence is followed by the link "Start here: What is AID?" to `/get-started/overview/`,
    the first link after the purpose sentence (§ Migration Plan: "the home page's first link after its
    purpose sentence"). The purpose sentence itself may hold rule-P2 glossary links; the P1 check compares
    it as plain text;
  - it keeps the install commands (`<InstallCommand>`) and the version badge (`<VersionBadge>`); their
    components are Feature 005's and are not edited;
  - the D1 diagram placed by task-008 is not edited; the words around it are this task's;
  - the hand-written skill and catalog counts go (P4; a Specify lead names `/`);
  - the `<Tabs>` block stays: Feature 004 turns it into sections in delivery-003.
- Get Started frontmatter (§ Migration Plan): `overview.md` gets `sidebar.order` 1 and `sidebar.label`
  "What is AID?"; `install.md` gets order 2 and label "Install". Each title is plain, at most about six
  words, and each `description` is the page's P1 sentence.
- `install.md` states the install facts once and links to the Installation guide for the full steps (P9).
- Record, in `.aid/works/work-005-site-rework/site-audit.md`: the three rows of § Pages take `ok` or
  `corrected`, one sentence per change naming the source that proved it. Remove `/` and
  `/get-started/overview/` from the Page cells of § Leads found at Specify after moving each lead into its
  page row; a lead row left with no page is deleted.
- Not in this task:
  - The other Get Started pages (task-014) and every other page.
  - No component under `site/src/components/` edited, no `site/astro.config.mjs` edit, no `<Tabs>` change.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the three pages and the audit file change.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='index.mdx get-started/overview.md get-started/install.md'
U='/ /get-started/overview/ /get-started/install/'
```

- [ ] Audit rows final: `for f in $P; do row "$f"; done` prints nothing (exactly one row per page, verdict
  `ok` or `corrected`, a `corrected` row with a non-empty Correction cell).
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
- [ ] Home "start here" link, the first link after the purpose paragraph (frontmatter and `import` lines
  skipped; the first remaining paragraph is the purpose sentence):
  `node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8"); const ps=s.replace(/^---\n[\s\S]*?\n---\n/,"").split(/\n\s*\n/).map(x=>x.trim()).filter(x=>x&&!/^import\s/.test(x)); const m=ps.slice(1).join("\n\n").match(/\[[^\]]*\]\([^)]*\)|href="[^"]*"/); console.log(m?m[0]:"no link");' $D/index.mdx`
  prints `[Start here: What is AID?](/get-started/overview/)`.
- [ ] Home keeps the install commands and the version badge: `grep -c '<InstallCommand' $D/index.mdx` and
  `grep -c '<VersionBadge' $D/index.mdx` each print at least `1`, and `grep -c '<Pipeline' $D/index.mdx`
  prints `1`.
- [ ] Get Started order and labels: in `$D/get-started/overview.md`, `grep -cE "^  label: ['\"]?What is AID\?['\"]?$"`
  and `grep -c '^  order: 1$'` each print `1`; in `$D/get-started/install.md`,
  `grep -cE "^  label: ['\"]?Install['\"]?$"` and `grep -c '^  order: 2$'` each print `1`.
- [ ] P2, glossary links present: `for f in $P; do grep -q '](/reference/glossary/#' "$D/$f" || echo "no glossary link: $f"; done`
  prints nothing. The reviewer then judges, for each glossary `###` term used on these pages
  (`grep '^### ' $D/reference/glossary.md`), that its first use links to its anchor or is explained in the
  same sentence (Feature 001 rule P2).
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/index.html dist/get-started/overview dist/get-started/install -name '*.html' -size +150k`
  prints nothing; `links | grep -E '^/(get-started/(overview|install)/)? '` prints nothing.
- [ ] Previous/next path: `grep -oE '<a [^>]*rel="next"[^>]*>' dist/get-started/overview/index.html | grep -c 'href="/get-started/install/"'`
  prints `1`, and `grep -c '>What is AID?<' dist/index.html` prints at least `1` (the sidebar label).
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page (install commands against INS, CLI commands against `bash bin/aid -h`, skill
  descriptions against SK) with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts fails this criterion.
- [ ] P3 and P6 (judged by the reviewer against Feature 001 rules P3 and P6): short active sentences
  addressed to "you"; every command in a code block, copyable, exactly as the CLI or SKILL.md defines it.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/index.mdx`, `site/src/content/docs/get-started/overview.md` and
    `site/src/content/docs/get-started/install.md`.
  - `git tag --points-at HEAD` prints nothing.
