# task-027: Tabs turned into plain sections on the five pages that use them

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

**Type:** IMPLEMENT

**Source:** feature-004-look-and-layout -> delivery-003 -> AC-10, AC-15

**Depends on:** task-026

(Ordered after task-026, not run beside task-024: every task of this delivery builds into the same `site/dist`
and checks that the working tree lists only its own files, so no two of them may run at once in one worktree.
The `<Tabs>` edits themselves need nothing from tasks 024-026.)

**Scope:**
- Apply Feature 004 § Layers & Components, "**Tabs.**", to every `<Tabs>` in
  `site/src/content/docs/index.mdx`, `site/src/content/docs/reference/cli.mdx`,
  `site/src/content/docs/guides/maintainer.mdx` and `site/src/content/docs/guides/installation.mdx`: each
  `<TabItem label="X">` becomes a Markdown heading `X` one level below the heading of the section that holds
  the tabs, followed by its content unchanged; the `<Tabs ...>` / `</Tabs>` and `</TabItem>` lines go. Where a
  `<Tabs>` sits inside a `<Steps>` list item (`guides/installation.mdx`), the headings and content stay inside
  that list item, indented with it, so `<Steps>` still wraps one ordered list. Content that was indented only
  to sit inside a `TabItem` may be dedented; no word, command or component changes.
- Remove `Tabs` and `TabItem` from the `@astrojs/starlight/components` import of those four pages and from the
  unused import in `site/src/content/docs/guides/pipeline.mdx`; the other imported names stay. An import line
  left with no name is deleted.
- Headings follow Feature 001 rule P8 (start at `##`, never skip a level); a literal `{`, `}` or `<` added
  outside code in `.mdx` is escaped (Feature 001 § Migration Plan, "File extensions").
- In `.aid/works/work-005-site-rework/site-audit.md` § Pages, update the row of each of the five pages in the
  same change (PLAN.md Cross-Cutting Risks, row 3; Feature 001 § Data Model, "Verdict"): add the sentence
  "Tabs turned into plain sections, so every panel is readable without JavaScript (Feature 004)." to the
  Correction cell (`pipeline.mdx`: "Unused Tabs import removed (Feature 004)."), and set a verdict of `ok` to
  `corrected`; a `corrected` or `new` verdict stays.
- Type: IMPLEMENT, not REFACTOR, because the built pages change on purpose (tab widgets and their script leave,
  panels become headings; Feature 004 § Layers & Components). The change adds no public method, so the
  IMPLEMENT unit-test default has nothing new to cover; the rule's automated test is S8 (delivery-004).
- Not touched: `astro.config.mjs`, styles, components; any other page; the wording of the pages beyond the
  headings (Feature 001's text stays).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than the five pages and `site-audit.md`.

**Acceptance Criteria:**

Run from `site/` (bash) unless stated. Let
`P='src/content/docs/index.mdx src/content/docs/reference/cli.mdx src/content/docs/guides/maintainer.mdx src/content/docs/guides/installation.mdx src/content/docs/guides/pipeline.mdx'`,
`T=../.aid/.temp/task-027` and
`counts() { for f in $P; do echo "$f fences=$(awk '/^[[:space:]]*\140\140\140/{n++} END{print n+0}' "$f") install=$(grep -c '<InstallCommand' "$f") steps=$(grep -c '<Steps>' "$f")"; done; }`
(`\140` is awk's octal escape for the backtick, so the pattern counts code-fence lines). Built page of a source
page: `out() { case "$1" in src/content/docs/index.mdx) echo dist/index.html ;; *) echo "dist/$(echo "$1" | sed -E 's#^src/content/docs/##; s#\.mdx$##')/index.html" ;; esac; }`.

- [ ] Labels and counts kept. Before editing:
  `mkdir -p "$T" && counts > "$T/counts.before" && for f in $P; do grep -o 'TabItem label="[^"]*"' "$f" | sed -E 's/^TabItem label="(.*)"$/\1/' > "$T/$(echo "$f" | tr / _).labels"; done`,
  and copy `counts.before` and the label lists into this task's `STATE.yml` `notes:`. After editing:
  `counts | diff "$T/counts.before" -` prints nothing (code fences, `<InstallCommand` and `<Steps>` counts
  unchanged per page), and
  `for f in $P; do sort "$T/$(echo "$f" | tr / _).labels" | uniq -c | while read -r n l; do h=$(grep -E '^[[:space:]]*#{2,6} ' "$f" | sed -E 's/^[[:space:]]*#+ //' | grep -cxF -- "$l"); [ "$h" -ge "$n" ] || echo "$f: '$l' $h/$n"; done; done`
  prints nothing (every label is a heading line on its page at least as often as it was a tab label). The
  label lists stay in `$T` until the built-page check below, then `rm -rf "$T"`.
- [ ] Tabs gone from the source (delivery-003 gate): `grep -rlE '<Tabs|<TabItem|import \{[^}]*Tabs' src/content/docs`
  prints nothing.
- [ ] Content unchanged apart from the tabs: before this task's commit, from the repo root,
  `git diff -w -U0 -- site/src/content/docs | grep -E '^-[^-]' | grep -vE '<Tabs|</Tabs>|<TabItem|</TabItem>|^-import \{'`
  prints nothing.
- [ ] Heading order (P8, S4 by command; code fences skipped):
  `for f in $P; do awk '/^[[:space:]]*\140\140\140/{c=!c} !c && /^[[:space:]]*##+ /{n=length($1); if (p && n>p+1) print FILENAME": "$0; p=n}' "$f"; done`
  prints nothing.
- [ ] Build: `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] No tab markup or script in the output (S8, NFR-2): `grep -rl 'starlight-tabs' dist --include='*.html'`
  prints nothing and `grep -rl 'role="tablist"' dist --include='*.html'` prints nothing; `grep -rl 'role="tabpanel"' dist --include='*.html'`
  prints nothing (no panel is hidden at build time); every recorded label is the text of a heading in its built
  page:
  `for f in $P; do sort "$T/$(echo "$f" | tr / _).labels" | uniq -c | while read -r n l; do e=$(printf '%s' "$l" | sed 's/&/\&amp;/g'); h=$(grep -oE '<h[2-6][^>]*>[^<]*</h[2-6]>' "$(out "$f")" | sed -E 's/<[^>]*>//g' | grep -cxF -- "$e"); [ "$h" -ge "$n" ] || echo "$(out "$f"): '$l' $h/$n"; done; done`
  prints nothing; then `rm -rf "$T"`.
- [ ] One `h1` per edited page (AC-10 by command):
  `for f in $P; do echo "$(out "$f") $(grep -o '<h1' "$(out "$f")" | wc -l)"; done | grep -cE ' 1$'` prints `5`.
- [ ] Links and anchors: after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing; `find dist -name '*.html' -size +150k` prints nothing.
- [ ] Audit rows (in the patterns, each `.` around a path stands for the backtick the audit row puts there):
  `A=../.aid/works/work-005-site-rework/site-audit.md; for p in index reference/cli guides/maintainer guides/installation; do grep -E "^\| .src/content/docs/$p\.mdx. " "$A" | grep -c 'Tabs turned into plain sections'; done`
  prints `1` four times; `grep -E '^\| .src/content/docs/guides/pipeline\.mdx. ' "$A" | grep -c 'Unused Tabs import removed'`
  prints `1`; `for p in index reference/cli guides/maintainer guides/installation guides/pipeline; do grep -E "^\| .src/content/docs/$p\.mdx. " "$A"; done | grep -cE '\| (ok|pending) \|'`
  prints `0`.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site .aid/works/work-005-site-rework/site-audit.md` lists only
  the five pages and `site-audit.md`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Unit tests: the tab rule's
  automated check is S8 of delivery-004's `tests/a11y.test.mjs`; the legacy Vitest suite is not a criterion
  (PLAN.md Cross-Cutting Risks, row 1).
