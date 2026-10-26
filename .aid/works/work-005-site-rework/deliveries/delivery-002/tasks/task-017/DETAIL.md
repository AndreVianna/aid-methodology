# task-017: Concepts Knowledge Base and Agents pages audited and rewritten

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

**Depends on:** task-009, task-016

**Scope:**
- Feature 001 § Feature Flow steps 2-5 for two Concepts pages, under `site/src/content/docs/concepts/`:
  - `knowledge-base.mdx` (/concepts/knowledge-base/), split from the old § 3 by task-005; sources SK
    (`aid-discover`, `aid-housekeep`, `aid-update-kb`), TPL `knowledge-base/`, ST. It hosts D4
    `<KbStructure />` and D5 `<ContextLoading />` (task-009);
  - `agents.mdx` (/concepts/agents/), split from the old § 5 by task-005; sources AG, SK (Dispatch tables),
    `canonical/aid/templates/agent-dispatch-tiering.md`. It hosts D6 `<AgentTiers />` (task-009). It explains
    tiers and dispatch; the agent roster stays on the generated `reference/agents` page and is linked, not
    restated (P9).
- Per page: list every checkable claim; check each with the checks of Feature 001 § Feature Flow step 3 (KB
  document types against TPL `knowledge-base/`; settings keys and defaults against ST; an agent and its
  tier against `name:` and `tier:` in `canonical/agents/<name>/AGENT.md`; a skill's states and outputs
  against its SKILL.md); correct each false or stale claim and delete one no source can prove; bring the
  page in line with rules P1-P9. Concepts pages explain; facts owned by a Reference page or a generated
  page are linked, not restated (P9). The first use of a glossary term links to its anchor (P2).
- Diagram words: Feature 001's audit row covers the words of the diagrams on its page (Feature 003 § Data
  Model, "Content of each diagram"). Check the `title`, `desc`, `caption` and text equivalent of D4, D5 and
  D6 against the sources Feature 003 cites for each, and record the result in the host row. The diagram
  components are not edited here: a diagram word that a source contradicts is recorded in the row and
  raised as a Q&A entry in the work's `STATE.yml` (`qa:`), because Feature 003 specifies those words.
- Record, in `.aid/works/work-005-site-rework/site-audit.md`:
  - `concepts/knowledge-base.mdx` takes `new`; its Correction cell says it was split from the old § 3,
    lists each correction with its source, and records the two D5 corrections named by task-009 (the old
    drawing's "INDEX.md always loaded" fixed and the project card added; the "exact path:line" tier
    dropped);
  - `concepts/agents.mdx` takes `new`; its Correction cell says it was split from the old § 5 and lists each
    correction with its source.
  - No lead of § Leads found at Specify names these two URLs; none is touched.
- MDX: a literal `{`, `}` or `<` outside code stays escaped (`\{`, `\}`, `&lt;`).
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
P='concepts/knowledge-base.mdx concepts/agents.mdx'
U='/concepts/knowledge-base/ /concepts/agents/'
```

- [ ] Audit rows final: `row concepts/knowledge-base.mdx new` and `row concepts/agents.mdx new` print nothing,
  and `grep -F 'concepts/knowledge-base.mdx' "$A" | grep -c '(planned)'` and the same for
  `concepts/agents.mdx` each print `0`.
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
- [ ] Diagrams kept: `grep -c '<KbStructure' $D/concepts/knowledge-base.mdx`,
  `grep -c '<ContextLoading' $D/concepts/knowledge-base.mdx` and `grep -c '<AgentTiers' $D/concepts/agents.mdx`
  each print `1`; after this task's commit, `git show --name-only --format= HEAD -- src/components` prints
  nothing (no diagram component edited).
- [ ] Diagram words checked: `grep -F 'concepts/knowledge-base.mdx' "$A" | grep -cE 'D4.*D5|D5.*D4'` and
  `grep -F 'concepts/agents.mdx' "$A" | grep -c 'D6'` each print `1`; the knowledge-base row names the
  project card (`grep -F 'concepts/knowledge-base.mdx' "$A" | grep -ci 'project card'` prints `1`).
- [ ] Roster not restated (P9): `grep -c '](/reference/agents/' $D/concepts/agents.mdx` prints at least `1`,
  and the reviewer, listing the agent names on the page with
  `grep -oE 'aid-(architect|clerk|developer|interviewer|operator|orchestrator|researcher|reviewer|tech-writer)' $D/concepts/agents.mdx | sort -u`,
  confirms no table or list pairs every agent with its tier (that roster is `reference/agents`).
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/concepts/knowledge-base dist/concepts/agents -name '*.html' -size +150k` prints nothing;
  `links | grep -E '^/concepts/(knowledge-base|agents)/ '` prints nothing. After the build,
  `grep -o '<figure class="diagram' dist/concepts/knowledge-base/index.html | wc -l` prints `2` and the same
  for `dist/concepts/agents/index.html` prints `1`.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in a Correction cell names a source that proves it, and the reviewer re-checks at least five
  unchanged claims per page with the checks of Feature 001 § Feature Flow step 3. A claim that a source
  contradicts fails this criterion.
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
    `site/src/content/docs/concepts/knowledge-base.mdx` and `site/src/content/docs/concepts/agents.mdx`.
  - `git tag --points-at HEAD` prints nothing.
