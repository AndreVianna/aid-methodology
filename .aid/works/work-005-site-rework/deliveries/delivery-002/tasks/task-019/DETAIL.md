# task-019: Case studies and FAQ pages audited and rewritten

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

**Depends on:** task-018

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for the last two Concepts pages, under `site/src/content/docs/concepts/`:
  - `case-studies.md` (/concepts/case-studies/), split from the old § 8 by task-005; source DOC
    `docs/aid-methodology.md` § 8. It hosts no diagram and stays `.md`;
  - `faq.md` (/concepts/faq/), sources DOC `docs/faq.md`, SK, CLI, INS. It holds the Anti-Patterns text of
    the old Adoption Guide, merged by task-005.
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3
  (skills against SK, CLI commands and flags with `bash bin/aid -h` and `bash bin/aid <command> -h` under a
  throwaway `HOME`, install commands against INS, phases against `canonical/aid/rules.md` § Workflow);
  correct each false or stale claim and delete one no source can prove; bring the page in line with rules
  P1-P9. DOC is a starting text, not a source of truth (Feature 001 § Feature Flow step 3): on
  `case-studies.md`, every claim about AID itself (skills, phases, artifacts, agents) is checked against
  SK, RULES, TPL or AG like any other page's; a claim about a case that DOC § 8 does not state is deleted.
  An FAQ answer that states a fact owned by another page links to it (P9). The first use of a glossary term
  links to its anchor (P2).
- Anti-Patterns (in `faq.md`): its claims are checked like the rest; its headings follow P8 within the page.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`:
  - `concepts/case-studies.md` takes `new`; its Correction cell says it was split from the old § 8 and lists
    each correction with its source;
  - `concepts/faq.md` takes `ok` or `corrected`, one sentence per change naming the source that proved it,
    and names the Anti-Patterns text merged from the old Adoption Guide.
  - No lead of § Leads found at Specify names these two URLs; none is touched.
- The `sourceDoc:` frontmatter line of `faq.md` stays: Feature 005 step 4 removes it in delivery-003.
  `docs/faq.md` and `docs/aid-methodology.md` outside `site/` are read, never edited.
- Not in this task:
  - Every other page; no component under `site/src/components/`.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
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
P='concepts/case-studies.md concepts/faq.md'
U='/concepts/case-studies/ /concepts/faq/'
```

- [ ] Audit rows final: `row concepts/case-studies.md new` and `row concepts/faq.md` print nothing, and
  `grep -F 'concepts/case-studies.md' "$A" | grep -c '(planned)'` prints `0`.
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
- [ ] Merged text kept: `grep -c 'Anti-Patterns' $D/concepts/faq.md` prints at least `1`, and
  `grep -F 'concepts/faq.md' "$A" | grep -c 'Anti-Patterns'` prints `1`. `grep -c '^sourceDoc:' $D/concepts/faq.md`
  prints `1`. From the repo root, `git status --porcelain docs` prints nothing.
- [ ] CLI commands exist: every `aid <command>` in a code block of `faq.md` names a command that
  `bash ../bin/aid -h` lists (run with `HOME=$(mktemp -d)`); the reviewer lists them with
  `grep -ohE '^\s*aid [a-z-]+' $D/concepts/faq.md | sort -u` and checks each against that help output.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/concepts/case-studies dist/concepts/faq -name '*.html' -size +150k` prints nothing;
  `links | grep -E '^/concepts/(case-studies|faq)/ '` prints nothing.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page with the checks of Feature 001 § Feature Flow step 3; on `case-studies.md`, every
  case claim the reviewer samples is present in `docs/aid-methodology.md` § 8. A claim that a source
  contradicts, or a case claim DOC does not state, fails this criterion.
- [ ] P2, P3 and P9 (judged by the reviewer against Feature 001 rules P2, P3 and P9): glossary terms linked
  on first use or explained in the same sentence; short active sentences addressed to "you"; no fact
  restated that another page owns.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical docs` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/concepts/case-studies.md` and `site/src/content/docs/concepts/faq.md`.
  - `git tag --points-at HEAD` prints nothing.
