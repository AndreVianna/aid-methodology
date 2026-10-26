# task-020: Reference overview, CLI commands and KB documents pages audited and rewritten

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

**Depends on:** task-019

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for three Reference pages, under `site/src/content/docs/reference/`:
  - `overview.md` (/reference/overview/), source: the Reference pages themselves. It is the target of the
    `/reference` redirect (task-006); it describes each Reference page in one line and links to it, and
    links to the generated `/skills/` and `/reference/agents/` pages for anything they list;
  - `cli.mdx` (/reference/cli/), sources CLI, INS. Every command, flag and exit code is checked with
    `bash bin/aid -h` and `bash bin/aid <command> -h`, run from the repo root with `HOME=$(mktemp -d)`;
  - `kb.md` (/reference/kb/), sources TPL `knowledge-base/`, ST. Each document type row is checked against
    the files in `canonical/aid/templates/knowledge-base/`; the `discovery.doc_set` claim against ST.
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3;
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. Reference pages list facts; explanations are linked to the Concepts page that owns them (P9). The
  first use of a glossary term links to its anchor (P2). The hand-written skill and catalog counts of
  `overview.md` go (P4; a Specify lead names `/reference/overview/`), and so does "14 standard documents" on
  `kb.md` (P4: "every standard document", with no number).
- `kb.md` stays hand-written content with its `generatedFrom:` frontmatter line and its
  `<!-- generated — do not edit; ... -->` comment line kept verbatim, because Feature 005 step 4 deletes both
  in delivery-003. So that rule P1 holds, the comment line sits directly after the page's first (purpose)
  paragraph, not before it.
- `cli.mdx`: the `<Tabs>` blocks stay (Feature 004 turns them into sections in delivery-003).
- Record, in `.aid/works/work-005-site-rework/site-audit.md`: the three rows of § Pages take `ok` or
  `corrected`, one sentence per change naming the source that proved it; the "planned: hand-written" text of
  the `reference/kb.md` row is replaced by what was done. Remove `/reference/overview/` from the Page cells
  of § Leads found at Specify after moving the lead into its page row; a lead row left with no page is
  deleted.
- Not in this task:
  - Every other page; no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
  - No `aid` command that writes outside the throwaway `HOME` is run; only `-h` help output is read.
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
P='reference/overview.md reference/cli.mdx reference/kb.md'
U='/reference/overview/ /reference/cli/ /reference/kb/'
```

- [ ] Audit rows final: `for f in $P; do row "$f"; done` prints nothing, and
  `grep -F 'reference/kb.md' "$A" | grep -c 'planned:'` prints `0`.
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
- [ ] Overview links every Reference page: for each `p` in `cli agents kb settings artifacts
  repository-structure glossary`, `grep -c "](/reference/$p/" $D/reference/overview.md` prints at least `1`,
  and `grep -c '](/skills/' $D/reference/overview.md` prints at least `1`.
- [ ] CLI commands exist: with `H=$(mktemp -d)`, every command name listed by
  `grep -ohE '^\s*aid [a-z-]+' $D/reference/cli.mdx | awk '{print $2}' | sort -u` appears in
  `HOME=$H bash ../bin/aid -h`; the loop
  `for c in $(grep -ohE '^\s*aid [a-z-]+' $D/reference/cli.mdx | awk '{print $2}' | sort -u); do HOME=$H bash ../bin/aid -h | grep -qw -- "$c" || echo "no command: $c"; done`
  prints nothing. The reviewer checks each documented flag against `bash ../bin/aid <command> -h`.
- [ ] KB document types match the templates: the type names in the table of `kb.md` equal the template
  file stems, i.e.
  `diff <(grep -oE '^\| `[a-z-]+` ' $D/reference/kb.md | tr -d '|` ' | sort) <(ls ../canonical/aid/templates/knowledge-base/*.md | xargs -n1 basename | sed 's/\.md$//' | sort)`
  prints nothing, or every difference is named in the `reference/kb.md` row as a template that is not a
  standard document type, with its source.
- [ ] `kb.md` keeps what Feature 005 step 4 removes later: `grep -c '^generatedFrom:' $D/reference/kb.md` and
  `grep -c '<!-- generated' $D/reference/kb.md` each print `1`.
- [ ] `<Tabs>` kept on `cli.mdx`: `grep -c '<Tabs' $D/reference/cli.mdx` prints the same number as
  `git show site-aid:site/$D/reference/cli.mdx | grep -c '<Tabs'`.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/reference/overview dist/reference/cli dist/reference/kb -name '*.html' -size +150k` prints
  nothing; `links | grep -E '^/reference/(overview|cli|kb)/ '` prints nothing.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page (CLI flags and exit codes against the help output, KB types against TPL,
  settings keys against ST) with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts fails this criterion.
- [ ] P2, P3, P6 and P9 (judged by the reviewer against Feature 001 rules P2, P3, P6 and P9): glossary terms
  linked on first use or explained in the same sentence; short active sentences addressed to "you"; every
  command in a code block exactly as the CLI defines it; explanations linked to their Concepts page.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/reference/overview.md`, `site/src/content/docs/reference/cli.mdx` and
    `site/src/content/docs/reference/kb.md`.
  - `git tag --points-at HEAD` prints nothing.
