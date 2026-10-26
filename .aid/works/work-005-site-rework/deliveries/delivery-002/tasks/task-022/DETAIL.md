# task-022: Contact pages audited, and audit rows of the generated pages settled

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

**Depends on:** task-021

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for the four contact pages, under `site/src/content/docs/contact/`
  (Feature 001 audits their words only; the form is Feature 005's, Feature 001 § Layers & Components,
  Boundaries):
  - `site-issue.mdx` (/contact/site-issue/), `methodology-bug.mdx` (/contact/methodology-bug/) and
    `feedback.mdx` (/contact/feedback/), source: the form's GitHub link;
  - `contact-request.mdx` (/contact/contact-request/), source: the form's mailto link.
  - Each `title` becomes its sidebar label from Feature 001's final sidebar (§ Migration Plan): "Report a site
    problem", "Report an AID bug", "Ask or give feedback", "Request a conversation". Each `description` is the
    page's P1 sentence. `reportIssue: false` and the `<ReportForm ... />` line with its import stay unchanged.
  - The words around the form are checked against what the form does today (`site/src/components/ReportForm.astro`
    and the link it builds), corrected per rules P1-P9.
  - The lead "/contact/* ... form works only with JavaScript" stays in § Leads found at Specify: Feature 005
    settles it in delivery-003.
- Audit rows of the generated pages (Feature 001 § Data Model 1, "Verdict"; Feature 002 owns their text, and
  this task edits none of it):
  - `skills/index.md`, every `skills/<name>.md`, `reference/agents.md` and `reference/settings.md`.
  - Each row takes `ok` once `node scripts/gen-facts.mjs --check` exits 0 and the page's intro (the text
    `gen-facts.mjs` writes above its table or cards) has been checked against the row's sources (SK, SC,
    AG, ST) with the checks of Feature 001 § Feature Flow step 3.
  - A skill page that exists under `site/src/content/docs/skills/` with no row (a skill added to
    `canonical/skills/` since Specify) gets a row in the same form, sources `FACTS; SK <name>`.
  - Leads settled into rows, then deleted from § Leads found at Specify:
    - `/reference/settings/`: confirmed at Specify and fixed by Feature 002 (the page now reads ST); the row
      records it;
    - `/skills/aid-experiment/`: recorded in that row as a finding for the owner (the folded `description`
      in `canonical/skills/aid-experiment/SKILL.md` renders "/aid- execute"); verdict `ok`, because the page
      states its source faithfully (Feature 001 § Layers & Components, Boundaries).
  - An intro claim that a source contradicts is not fixed here (that is `gen-facts.mjs` or `canonical/`): it
    is recorded in the row and raised as a Q&A entry in the work's `STATE.yml` (`qa:`), and that row stays
    `pending`, so this task fails its row criterion until the owner decides.
- Not in this task:
  - No generated page, `gen-facts.mjs`, `ReportForm.astro` or `Footer.astro` edited.
  - The two changelog rows (`src/pages/releases/changelog.astro`, `src/content/docs/releases/changelog.mdx`)
    stay non-final (PLAN.md delivery-002 Notes).
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`. No form is submitted.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the four contact pages and the audit file change; the executor may also append a
    `qa:` entry to the work's `STATE.yml` as stated above.

**Acceptance Criteria:**

Every check runs from `site/` after this set-up. The helpers (`D`, `A`, `code`, `row`, `p1`, `p4`, `p5`,
`p7`, `p8`, `olds`, `cmds`, `leads`, `links`) are defined once, in
`.aid/works/work-005-site-rework/audit-checks.sh`, which task-012 writes (its content is stated in
task-012's Scope); a fix to a helper is made in that file only, never copied here.

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='contact/site-issue.mdx contact/methodology-bug.mdx contact/feedback.mdx contact/contact-request.mdx'
U='/reference/settings/ /skills/aid-experiment/'
G="skills/index.md reference/agents.md reference/settings.md $(cd $D && ls skills/aid-*.md)"
```

- [ ] Contact rows final: `for f in $P; do row "$f"; done` prints nothing.
- [ ] Generated rows final: `node scripts/gen-facts.mjs --check` exits 0, then `for f in $G; do row "$f" ok; done`
  prints nothing (exactly one row per generated page, verdict `ok`).
- [ ] Every skill page has a row: `ls $D/skills/aid-*.md | wc -l` equals `ls ../canonical/skills | wc -l`, and
  the row loop above covered that many skill pages.
- [ ] P1, one sentence of purpose equal to `description` (compared as plain text: a Markdown or `<a>`
  link counts as its link text and `**`, `__` and backticks are ignored, so a rule-P2 glossary link in
  the sentence is allowed): `for f in $P; do p1 "$D/$f"; done` prints nothing.
- [ ] P4, no hand-written counts: `for f in $P; do p4 "$D/$f"; done` prints nothing.
- [ ] P5, no change history and no internal ids outside code: `for f in $P; do p5 "$D/$f"; done` prints
  nothing.
- [ ] P7, link text names the destination and no bare URL: `for f in $P; do p7 "$D/$f"; done` prints nothing.
- [ ] P8, body headings start at `##`, skip no level, and no hand-written table of contents:
  `for f in $P; do p8 "$D/$f"; done` prints nothing.
- [ ] No link to a removed URL: `for f in $P; do olds "$D/$f"; done` prints nothing.
- [ ] Every `/aid-...` command named on the contact pages is a skill or a shortcut-catalog row:
  `cmds $(for f in $P; do echo "$D/$f"; done)` prints nothing.
- [ ] Leads settled: `for u in $U; do leads "$u"; done` prints nothing;
  `grep -F 'skills/aid-experiment.md' "$A" | grep -c '/aid- execute'` prints `1`; the `/contact/*` lead is
  still present (`sed -n '/^## Leads found at Specify/,$p' "$A" | grep -c '^| /contact/\*'` prints `1`).
- [ ] Contact titles match the sidebar labels: `grep -cE "^title: ['\"]?Report a site problem['\"]?$" $D/contact/site-issue.mdx`,
  `grep -cE "^title: ['\"]?Report an AID bug['\"]?$" $D/contact/methodology-bug.mdx`,
  `grep -cE "^title: ['\"]?Ask or give feedback['\"]?$" $D/contact/feedback.mdx` and
  `grep -cE "^title: ['\"]?Request a conversation['\"]?$" $D/contact/contact-request.mdx` each print `1`.
- [ ] Form untouched: for each contact page, `grep -c '^reportIssue: false$'` prints `1` and the `<ReportForm`
  line is byte-for-byte as on `site-aid`
  (`for f in $P; do diff <(git show site-aid:site/$D/$f | grep '<ReportForm') <(grep '<ReportForm' $D/$f) >/dev/null || echo "form changed: $f"; done`
  prints nothing).
- [ ] Generated pages not edited: `git status --porcelain $D/skills $D/reference/agents.md $D/reference/settings.md scripts`
  prints nothing.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/contact dist/skills dist/reference/agents dist/reference/settings -name '*.html' -size +150k`
  prints nothing; `links | grep -E '^/(contact|skills)/|^/reference/(agents|settings)/ '` prints nothing (a
  broken link on a generated page is raised as a `qa:` entry, not fixed here).
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a contact Correction cell names a source; for the generated pages, the reviewer checks each
  intro (skills index, agents, settings) and at least five skill pages' descriptions and argument hints
  against SK, AG and ST with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts and is not recorded as a finding fails this criterion.
- [ ] P3 (judged by the reviewer against Feature 001 rule P3): the contact pages use short active sentences
  addressed to "you".
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only the four
    files under `site/src/content/docs/contact/`.
  - `git tag --points-at HEAD` prints nothing.
