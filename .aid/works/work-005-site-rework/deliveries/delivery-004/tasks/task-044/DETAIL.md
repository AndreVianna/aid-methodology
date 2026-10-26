# task-044: KB structure documents describe the facts script (module-map, architecture, project-structure)

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
- Feature 006 § Feature Flow steps 2 and 5 for `.aid/knowledge/module-map.md`, `.aid/knowledge/architecture.md`
  and `.aid/knowledge/project-structure.md` only.
- Step 2: read B1 (`git ls-files site | grep -E '\.test\.(mjs|ts)$'`, its folders for the K8 rows).
- Step 5, before writing each file: resolve its review criteria per `.aid/knowledge/authoring-conventions.md`
  (global G-01 to G-16, type `kb-doc` KB-01 to KB-18, plus the file's own `review-criteria:` frontmatter) and
  comply; the ones these edits can break: No Work References, G-02 (no bare line-number citations), G-01 (no
  hand-written counts), KB-07 (no diagram blocks), KB-11 (exit codes inline).
- Step 5, the edits of Feature 006 § Layers & Components, pasted as written:
  - *`module-map.md`*: frontmatter `review-criteria:` F-03 (new `criterion` and `why` text; `id`, `kind`,
    `severity` unchanged); § Module Inventory, the `site/` row -> block K4; the five rows `site/scripts/gen-skills.mjs`
    + `site/scripts/skills/*` (12), `site/scripts/lib/flow-graph/*` (14), `site/scripts/gen-reference.mjs`,
    `site/scripts/skills/skill-counts.mjs`, `site/public/skill-node-panel.mjs` (runtime) + ... -> deleted, block K5
    in their place; § Dependency Graph, the code-block lines from `site/                       -> canonical/skills/, canonical/agents/,`
    through `(generators read the toolkit at build time)` -> block K6 (the line
    `site/ -> (independent of the CLI: bin/, lib/, install.sh)` stays); same section, from
    "**`site/` DOES consume `canonical/` — this was a non-dependency and is no longer.**" through the paragraph
    ending "turns the site build red by design." -> block K7.
  - *`architecture.md`*: § Entry Points item 7 -> the given item; § Gotchas, the bullet
    "**Heavy CI gates run only on `master`**" -> the given bullet.
  - *`project-structure.md`*: § Directory Tree, the `src/` and `scripts/` lines under `site/` -> the two given
    lines; § Top-Level Directory Purposes, the `site/` row's second cell -> the given text (last cell unchanged);
    § Entry Points item 6 -> the given item; § Test Directories, the `site/scripts/__tests__/` and
    `site/src/data/__tests__/` rows -> one block K8 row per B1 folder; § Unusual Structure Notes item 3 -> the
    given item.
- No `objective:`, `summary:` or `tags:` value changes; `INDEX.md` is not touched here.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use; no edit
  under `canonical/`; no edit to any file other than the three named; no change to any path outside the
  delivery-004 AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, `.aid/knowledge/` documents listed in the
  audit's FR-10 table, `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is not run.

**Acceptance Criteria:**

Run from the repo root. Let `M=.aid/knowledge/module-map.md`, `R=.aid/knowledge/architecture.md`,
`P=.aid/knowledge/project-structure.md`.

- [ ] module-map K4/K5: ``grep -cF '| `site/scripts/gen-facts.mjs` | Observation | **Site facts script.**' $M`` prints `1`;
  ``grep -cF 'generated from `canonical/` by `site/scripts/gen-facts.mjs` and committed**' $M`` prints at least `1`;
  ``grep -cE '^\| `site/(scripts/(gen-skills|gen-reference|lib/flow-graph|skills/skill-counts)|public/skill-node-panel)' $M``
  prints `0`.
- [ ] module-map K6/K7 and F-03: `grep -cF 'site/scripts/gen-facts.mjs  -> canonical/skills/, canonical/agents/,' $M`
  prints `1`; `grep -cE 'site/ +-> \(independent of the CLI: bin/, lib/, install\.sh\)' $M` prints `1`; ``grep -cF '**`site/` depends on `canonical/` through one script, and the dependency is checked.**' $M``
  prints `1`; `grep -c 'DOES consume' $M` prints `0`; `grep -cF 'whose --check fails docs.yml and the site suite when the committed pages drift' $M`
  prints `1`; F-03 keeps its `kind:` and `severity:`:
  `diff <(git show site-aid:.aid/knowledge/module-map.md | grep -A4 'id: F-03' | grep -E '^ +(kind|severity):') <(grep -A4 'id: F-03' $M | grep -E '^ +(kind|severity):')`
  prints nothing, and `grep -A4 'id: F-03' $M | grep -E '^ +(kind|severity):' | sed 's/^ *//'` prints exactly the two
  lines `kind: validate` and `severity: MEDIUM`.
- [ ] architecture: ``grep -cF 'the build itself reads no `canonical/` file' $R`` prints `1`;
  ``grep -cF 'and the site gate (`docs.yml`) runs on `master` and on pull requests to it' $R`` prints `1`;
  `grep -cE 'gen-reference|gen-skills|sync-docs' $R` prints `0`.
- [ ] project-structure: `grep -cF '# gen-facts.mjs: skill, agent and settings pages from canonical/' $P` prints `1`;
  `grep -cF '# Astro content, pages and components' $P` prints `1`;
  `grep -cE 'site/scripts/__tests__|site/src/data/__tests__' $P` prints `0`; one block K8 row exists per B1
  folder: `grep -cF '| The site suite (vitest): the build, internal links' $P` equals
  `git ls-files site | grep -E '\.test\.(mjs|ts)$' | xargs -n1 dirname | sort -u | wc -l`, and for each folder `f`
  printed by `git ls-files site | grep -E '\.test\.(mjs|ts)$' | xargs -n1 dirname | sort -u`,
  ``grep -F "| \`$f/\` |" $P | grep -cF '| The site suite (vitest):'`` prints `1`;
  ``grep -cF '**The website (`site/`) is a separate build, not a separate source.**' $P``
  prints `1`; `grep -cE 'prebuild|gen-reference' $P` prints `0`.
- [ ] No placeholder or stale term: `grep -c '{B[0-9]\|{folder}' $M $R $P` prints `0` for each;
  `grep -nE "gen-skills|gen-reference|sync-docs|sync:docs|fetch-release|skill-counts|curated-roster|flow-graph|skill-node-panel|node panel|astro-mermaid|layout-elk|mermaid-source-cache|Skill Explorer|vitest suite|site data tests|Releases API for version|docs/\*\*|~2765 vitest|build-time generators|prebuild syncs" $M $R $P`
  prints nothing.
- [ ] KB rules on the added lines: `git diff -U0 site-aid -- $M $R $P | grep '^+[^+]' | grep -cE 'work-[0-9]{3}|\.aid/works/|\b(FR|NFR|AC)-[0-9]+\b|\b(feature|task|delivery)-[0-9]{3}\b|\.[a-z]{2,4}:[0-9]+\b|^\+```mermaid'`
  prints `0`; `git diff -U0 site-aid -- $M $R $P | grep -E '^[-+](objective|summary|tags):'` prints nothing.
- [ ] AC-14 for these files: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`,
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and
  `bash tests/canonical/test-kb-no-work-ids.sh` exit 0.
- [ ] Accuracy verified against the current tree (DOCUMENT default): every path named in the new text exists
  (`site/scripts/gen-facts.mjs`, `.github/workflows/docs.yml`, `tests/canonical/test-doc-counts.sh`, each B1
  folder: `test -e` succeeds for each), and the K5 exit codes match `node site/scripts/gen-facts.mjs --bogus`
  exiting 2 and `node site/scripts/gen-facts.mjs --check` exiting 0.
- [ ] Scope (AC-13, NFR-5): before this task's commit `git status --porcelain --untracked-files=all` lists only the
  three files and task/delivery `STATE.yml` files under `.aid/works/work-005-site-rework/`;
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; `git tag --points-at HEAD` prints nothing.
