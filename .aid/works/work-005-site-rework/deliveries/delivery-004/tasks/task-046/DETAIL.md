# task-046: KB debt register updated, then the KB sweep and repository checks

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

**Source:** feature-006-workflow-and-safety -> delivery-004 -> AC-14

**Depends on:** task-043, task-044, task-045

**Scope:**
- Feature 006 § Feature Flow steps 2 and 5 for `.aid/knowledge/tech-debt.md` only, then steps 6 and 7 over the
  whole KB (this is the last KB edit task; tasks 043-045 are done). The `domain-glossary.md` and `PROJECT.md`
  edits of the spec are task-043's.
- Step 2: read B5 (`grep -cE '<Pipeline[[:space:]/>]' site/src/content/docs/index.mdx`).
- Step 5, before writing: resolve the file's review criteria per `.aid/knowledge/authoring-conventions.md`
  (global G-01 to G-16, type `kb-doc` KB-01 to KB-18, plus the file's own `review-criteria:`) and comply; the
  ones these edits can break: No Work References, G-02, G-03 (a resolved debt row is deleted, with no closure
  note), G-01, KB-07, KB-11.
- Step 5, the edits of Feature 006 § Layers & Components, pasted as written:
  - *`tech-debt.md`*: first confirm `git ls-files site | grep -E "flow-graph|curated-roster|skill-node-panel|gen-skills"`
    prints nothing and `astro-mermaid` / `@mermaid-js/layout-elk` are absent from B3; then delete rows W1-1, W1-3,
    W1-5, W1-6, W1-7, W1-8, W1-12, W1-13, W1-14, W1-15, W1-17 (W1-9, W1-10, W1-11 and the ID-rule note rows stay);
    W1-2's sentence from "The live figures belong in the generator's `shapeCounts` manifest entry" through "or lose
    its numbers." -> the given sentence; row L9 -> block K12 if B5 is not 0, deleted if B5 is 0; the subsection
    `### Skill Explorer — open known issues` deleted from its heading to the line before `## Detailed Debt Items`;
    § Missing Test Coverage, row "Astro site components" -> block K13; § Gotchas, the "Master-only heavy gates"
    bullet from "**`docs.yml` is NOT master-only.**" to its end -> the given text; block K14 (W5-24) as a new row
    after W5-23, after confirming it with the spec's `git grep -lE "skill-counts\.mjs|sync-docs|sync:docs|changelog\.astro" -- ...`
    command (drop from the row any file it no longer lists) and `test -e site/scripts/skills/skill-counts.mjs`
    failing.
- Step 6: run both sweep commands over `.aid/knowledge`; both must print nothing. A hit in a file of task 043-045
  is reported against that task (it ends `Failed` and is re-run), not fixed here.
- Step 7: run the three AC-14 commands and the `test.yml` INDEX freshness check (the `build-kb-index.sh` to a
  `mktemp` file plus the filtered `diff`). If the diff prints anything, regenerate `INDEX.md` with the project
  card's command (`bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`),
  re-run the diff (now empty), and write `INDEX.md regenerated` into this task's `notes:` so task-047 adds its
  audit row; otherwise `INDEX.md fresh`.
- No `objective:`, `summary:` or `tags:` value changes.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use; no edit
  under `canonical/` (W5-24 records the stale pointers; it does not fix them); no edit to any file other than
  `.aid/knowledge/tech-debt.md` and, only when step 7 requires it, `.aid/knowledge/INDEX.md`; no change to any path outside the
  delivery-004 AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, `.aid/knowledge/` documents listed in the
  audit's FR-10 table, `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is not run.

**Acceptance Criteria:**

Run from the repo root. Let `D=.aid/knowledge/tech-debt.md`.

- [ ] Debt rows: `grep -cE '^\| \*\*W1-(1|3|5|6|7|8|12|13|14|15|17)\*\* \|' $D` prints `0`;
  `grep -cE '^\| \*\*W1-(2|9|10|11)\*\* \|' $D` prints `4`; `grep -c 'shapeCounts' $D` prints `0`;
  ``grep -cF 'The figures should be derived from a scan of `canonical/skills/` when the section is next edited, or dropped from the prose.' $D``
  prints `1`; `grep -c 'Skill Explorer' $D` prints `0`.
- [ ] L9: when B5 is not 0, ``grep -cF 'the `Pipeline` diagram component, `site/src/components/diagrams/Pipeline.astro`' $D``
  prints `1` and `grep -c 'parser with no consumer' $D` prints `0`; when B5 is 0, `grep -c '^| \*\*L9\*\*' $D` prints `0`.
- [ ] W5-24, K13 and gotcha: `grep -c '^| \*\*W5-24\*\* |' $D` prints `1`, and every path in its location cell is
  listed by the spec's `git grep -lE` confirmation command, and that command lists no file missing from the cell;
  `grep -cF '| Astro site | build, link, facts, accessibility and structure checks on built pages |' $D` prints `1`;
  ``grep -cF 'its `build` job runs **`node site/scripts/gen-facts.mjs --check`, `npm test` (the site suite) and the Astro build**' $D``
  prints `1`; `grep -c 'docs/\*\*' $D` prints `0`.
- [ ] Step 6 sweep: both commands of Feature 006 § Feature Flow step 6 print nothing.
- [ ] Step 7 / AC-14: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`,
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and
  `bash tests/canonical/test-kb-no-work-ids.sh` exit 0; the INDEX freshness `diff` prints nothing; `notes:` says
  `INDEX.md regenerated` or `INDEX.md fresh`, and `git status --porcelain .aid/knowledge/INDEX.md` is empty exactly
  when it says `fresh`.
- [ ] KB rules on the added lines: `git diff -U0 site-aid -- $D | grep '^+[^+]' | grep -cE 'work-[0-9]{3}|\.aid/works/|\b(FR|NFR|AC)-[0-9]+\b|\b(feature|task|delivery)-[0-9]{3}\b|\.[a-z]{2,4}:[0-9]+\b|^\+```mermaid'`
  prints `0`; `git diff -U0 site-aid -- .aid/knowledge | grep -E '^[-+](objective|summary|tags):'` prints nothing
  (whole KB, after tasks 043-046); `grep -c '{B[0-9]' $D` prints `0`.
- [ ] Accuracy verified against the current tree (DOCUMENT default): every path named in the new rows exists
  (`test -e` succeeds for `site/src/components/diagrams/Pipeline.astro` when K12 is used, and for each W5-24
  location).
- [ ] Scope (AC-13, NFR-5): before this task's commit `git status --porcelain --untracked-files=all` lists only
  `.aid/knowledge/tech-debt.md`, optionally `.aid/knowledge/INDEX.md`, and task/delivery `STATE.yml` files under
  `.aid/works/work-005-site-rework/`; `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; `git tag --points-at HEAD`
  prints nothing.
