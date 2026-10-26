# task-043: KB test-landscape.md describes the site suite and its CI lane; glossary and project card updated

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

**Depends on:** task-042

**Scope:**
- Feature 006 § Feature Flow steps 2 and 5 for `.aid/knowledge/test-landscape.md`,
  `.aid/knowledge/domain-glossary.md` and `.aid/knowledge/PROJECT.md` only (the glossary and card edits sit here,
  not in task-046, so that the last KB task holds only `tech-debt.md` and the whole-KB sweeps).
- Step 2: read binding value B1 with its command (`git ls-files site | grep -E '\.test\.(mjs|ts)$'`); `{B1 folders}`
  is the set of folders of those files, each in a code span with a trailing `/` (expected: `site/tests/`). Also
  read B6 (`test -f site/src/components/VersionBadge.astro; echo $?` and `grep -rl "CardGrid" site/src/content/docs`)
  and B7 (`git ls-files site | grep 'Diagram.astro$'`).
- Step 5, before writing each file: resolve its review criteria per `.aid/knowledge/authoring-conventions.md`
  (global G-01 to G-16; type `kb-doc` KB-01 to KB-18 for `test-landscape.md` and `domain-glossary.md`, type
  `kb-card` PC-01 to PC-03 for `PROJECT.md`; plus each file's own `review-criteria:` frontmatter) and
  comply; the ones these edits can break: No Work References (no work id, work-folder path, feature, task,
  delivery, FR or AC id), G-02 (no bare line-number citations), G-01 (no hand-written counts), KB-07 (no diagram
  blocks), KB-11 (exit codes inline).
- Step 5, the edits of Feature 006 § Layers & Components, "*`test-landscape.md`*" table, each anchored by its
  section and string, replacement text pasted as written with `{B1 folders}` filled:
  1. § Test Framework Inventory, row "Astro / TypeScript tests" -> block K1.
  2. § CI Lanes and Where They Run, the paragraph containing "`docs.yml` is the exception" -> the given text (the
     opening sentence "AID has five GitHub Actions workflows." stays).
  3. Same section, the `.github/workflows/docs.yml` (Docs) row -> the given Trigger and Jobs cells; last cell
     unchanged.
  4. Same section, the sentence beginning "CONFIRMED by the `on:` blocks of each workflow" -> the given sentence
     (the dated line-range citation goes).
  5. Same section, the paragraph beginning "**The site is the exception, and it is a PR gate.**" -> the given
     paragraph.
  6. § Coverage Assessment, row "Astro site" -> block K2.
  7. § Test Commands, the comment `# Astro site build (the docs.yml gate)` and the command under it -> block K3.
- Step 5, the edits of Feature 006 § Layers & Components for the other two files, pasted as written:
  - *`domain-glossary.md`*, § Lexicon — UI Components and Identity: `VersionBadge` kept if B6 says the file exists,
    else deleted; `CardGrid / Card Grid` Source set to the B6 page path, or the row deleted if no page uses it;
    `PipelineDiagram` -> block K15 with `{B7}` filled.
  - *`PROJECT.md`*: block K16 inserted after the "Build" line of § Commands. No "Rules that never bend" rule is
    added (owner decision in the spec).
- No `objective:`, `summary:` or `tags:` value changes (so `INDEX.md` stays fresh); `INDEX.md` is not touched here.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use; no edit
  under `canonical/`; no edit to any file other than `.aid/knowledge/test-landscape.md`,
  `.aid/knowledge/domain-glossary.md` and `.aid/knowledge/PROJECT.md`; no change to any path
  outside the delivery-004 AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, `.aid/knowledge/` documents
  listed in the audit's FR-10 table, `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is not run.

**Acceptance Criteria:**

Run from the repo root. Let `T=.aid/knowledge/test-landscape.md`, `G=.aid/knowledge/domain-glossary.md`,
`C=.aid/knowledge/PROJECT.md`.

- [ ] K1: `grep -c '^| Vitest (site) | Build and page checks |' $T` prints `1` and its row names `site/tests/` (the B1
  folder); `grep -c 'Astro / TypeScript tests' $T` prints `0`.
- [ ] CI lane text: `grep -cF "its \`build\` job runs the site's facts check and test suite" $T` prints `1`;
  `grep -cF "CONFIRMED by the \`on:\` blocks of each workflow; the \`on:\` block of \`.github/workflows/docs.yml\`" $T`
  prints `1`; `grep -c 're-verified 2026-07-30' $T` prints `0`; `grep -cF "Second, that check, not the build, catches a \`canonical/\` edit" $T`
  prints `1`; `grep -c 'AID has five GitHub Actions workflows.' $T` prints `1`.
- [ ] Docs row: the `.github/workflows/docs.yml` row of § CI Lanes contains both the facts check and the bold
  site-suite step (``grep -F '.github/workflows/docs.yml' $T | grep -F 'node site/scripts/gen-facts.mjs --check' | grep -cF '**`npm test` (site suite)**'``
  prints `1`), and `grep -c 'docs/\*\*' $T` prints `0`.
- [ ] K2 and K3: `grep -cF '| Astro site | Moderate | the site suite (' $T` prints `1`;
  `grep -cF '# Site gate, as docs.yml runs it (from the repo root)' $T` prints `1`;
  `grep -cF 'cd site && npm ci && npm test && npm run build' $T` prints `1`;
  `grep -c 'Astro site build (the docs.yml gate)' $T` prints `0`.
- [ ] Glossary: `grep -c 'PipelineDiagram' $G` prints `0`; `grep -cF "| Diagram | Site component rendering a static, accessible SVG diagram" $G`
  prints `1` and that row names `site/src/components/Diagram.astro` (B7); `grep -c 'site/.astro/data-store.json' $G`
  prints `0`; `grep -c '^| VersionBadge |' $G` prints `1` when B6's `test -f` printed `0`, else `0`.
- [ ] Project card: ``grep -cF -- '- Site facts (after a `canonical/` skill, agent or settings change): `node site/scripts/gen-facts.mjs`' $C``
  prints `1` (it prints `0` before the edit), on the line right after the "- Build" line
  (`grep -A1 '^- Build' $C | tail -1 | grep -c '^- Site facts'` prints `1`);
  `sed -n '/^## Rules that never bend/,/^## /p' $C | grep -cE '^[0-9]+\. '` prints `8`; `wc -l < $C` prints at
  most `60` (PC-01).
- [ ] No placeholder or stale term: `grep -c '{B[0-9]' $T $G $C` prints `0` for each;
  `grep -nE "gen-skills|gen-reference|sync-docs|sync:docs|fetch-release|skill-counts|curated-roster|flow-graph|skill-node-panel|node panel|astro-mermaid|layout-elk|mermaid-source-cache|Skill Explorer|vitest suite|site data tests|Releases API for version|docs/\*\*|~2765 vitest|build-time generators|prebuild syncs" $T`
  prints nothing.
- [ ] KB rules on the added lines: `git diff -U0 site-aid -- $T $G $C | grep '^+[^+]' | grep -cE 'work-[0-9]{3}|\.aid/works/|\b(FR|NFR|AC)-[0-9]+\b|\b(feature|task|delivery)-[0-9]{3}\b|\.[a-z]{2,4}:[0-9]+\b|^\+```mermaid'`
  prints `0`; `git diff -U0 site-aid -- $T $G $C | grep -E '^[-+](objective|summary|tags):'` prints nothing.
- [ ] AC-14 for these files: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`,
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and
  `bash tests/canonical/test-kb-no-work-ids.sh` exit 0.
- [ ] Accuracy verified against the current tree (DOCUMENT default): each replaced statement matches the file it
  describes -- the Jobs cell matches the step names printed by the task-042 step-order command, and the B1 folder
  matches `git ls-files site | grep -E '\.test\.(mjs|ts)$' | xargs -n1 dirname | sort -u`; every path named in
  the new glossary row exists (`test -e site/src/components/Diagram.astro` succeeds), and the card's commands
  run: `node site/scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5): before this task's commit `git status --porcelain --untracked-files=all` lists only
  `.aid/knowledge/test-landscape.md`, `.aid/knowledge/domain-glossary.md`, `.aid/knowledge/PROJECT.md` and
  task/delivery `STATE.yml` files under `.aid/works/work-005-site-rework/`;
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; `git tag --points-at HEAD` prints nothing.
