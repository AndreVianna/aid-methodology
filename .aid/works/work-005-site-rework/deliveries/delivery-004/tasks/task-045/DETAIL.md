# task-045: KB stack and infrastructure documents match the simplified site (technology-stack, infrastructure, integration-map)

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
- Feature 006 § Feature Flow steps 2 and 5 for `.aid/knowledge/technology-stack.md`,
  `.aid/knowledge/infrastructure.md` and `.aid/knowledge/integration-map.md` only.
- Step 2: read B2 (`node -p "JSON.stringify(require('./site/package.json').scripts, null, 1)"`), B3
  (`node -p "const p=require('./site/package.json'); JSON.stringify({d:p.dependencies, dev:p.devDependencies, o:p.overrides}, null, 1)"`)
  and B4 (`grep -rlF "new URL('../VERSION'" site/src site/astro.config.mjs`, which must print exactly
  `site/astro.config.mjs`; any other output: stop, end `Failed`, owner task-028 of delivery-003, which wrote the version read).
- Step 5, before writing each file: resolve its review criteria per `.aid/knowledge/authoring-conventions.md`
  (global G-01 to G-16, type `kb-doc` KB-01 to KB-18, plus the file's own `review-criteria:` frontmatter) and
  comply; the ones these edits can break: No Work References, G-02, G-01, KB-07, KB-11.
- Step 5, the edits of Feature 006 § Layers & Components, pasted as written with `{B<n>}` filled:
  - *`technology-stack.md`*: § Languages, the **JavaScript (Node)** row's "and the site's build-time generators"
    -> "and the site's facts script (`site/scripts/gen-facts.mjs`)"; the **TypeScript** row's version from B3 (row
    deleted if `typescript` is absent); § Frameworks & Tooling, the Astro and @astrojs/starlight versions from B3;
    the astro-mermaid, marked and sanitize-html rows deleted where absent from B3; block K9 first row after
    @astrojs/starlight; § Build Commands, the `npm ci && npm run build` line -> the given line; § Lint Commands,
    `npm run check` and its CONFIRMED clause kept only if B2 has `check` (it does, per Feature 005 Data Model 1),
    otherwise deleted as described; § Test Commands, the `# Site data tests — from site/` comment and its
    `npm test` line -> the three K9 lines (`{B2 test}` = the `test` script of B2); § Key Dependencies, the site
    rows' versions from B3, rows of removed packages deleted, K9 second row added.
  - *`infrastructure.md`*: the workflow table's `.github/workflows/docs.yml` row -> block K10; § The Documentation
    Site, the whole paragraph -> block K11 (`{B4}` = `site/astro.config.mjs`).
  - *`integration-map.md`*: the integrations table's GitHub `gh` CLI row, Notes cell -> "`release.sh`
    cuts/uploads releases"; § GitHub (gh CLI, Releases, Actions), the `gh` CLI paragraph: the sentence "The site's
    `gen-reference.mjs` also shells out to `gh`." and the trailing "; `site/scripts/gen-reference.mjs`" of its
    CONFIRMED line deleted; the `docs.yml` (Docs) row's Trigger and Purpose cells -> the given text; the sentence
    "its `build` job runs the site vitest suite plus the build, ..." -> the given sentence.
- No `objective:`, `summary:` or `tags:` value changes; `INDEX.md` is not touched here.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use; no edit
  under `canonical/`; no edit to any file other than the three named; no change to any path outside the
  delivery-004 AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, `.aid/knowledge/` documents listed in the
  audit's FR-10 table, `.aid/works/work-005-site-rework/`); `.github/workflows/docs.yml` is not run.

**Acceptance Criteria:**

Run from the repo root. Let `TS=.aid/knowledge/technology-stack.md`, `IN=.aid/knowledge/infrastructure.md`,
`IM=.aid/knowledge/integration-map.md`, and `v() { node -p "const p=require('./site/package.json'); ({...p.dependencies,...p.devDependencies})['$1']"; }`.

- [ ] technology-stack, removed packages: `grep -cE '^\| \*\*(astro-mermaid|marked|sanitize-html)\*\*' $TS` prints `0`;
  `grep -c 'build-time generators\|prebuild syncs' $TS` prints `0`;
  `grep -cF "the site's facts script (\`site/scripts/gen-facts.mjs\`)" $TS` prints `1`.
- [ ] technology-stack, versions equal B3: `grep -cF "| **Astro** | **$(v astro)** |" $TS`,
  `grep -cF "| **@astrojs/starlight** | **$(v @astrojs/starlight)** |" $TS`,
  `grep -cF "| **TypeScript** | **$(v typescript)** " $TS`, `grep -cF "| **axe-core** | **$(v axe-core)** (site dev dep) |" $TS`,
  `grep -cF "| astro | $(v astro) |" $TS`, `grep -cF "| axe-core | $(v axe-core) |" $TS` and
  `grep -cF "| vitest | $(v vitest) |" $TS` each print `1`; every `| yaml (override) |` row shows the B3
  `overrides.yaml` value.
- [ ] technology-stack, commands: `grep -cF "# 'build' = 'astro build'; nothing is generated or fetched at build time" $TS`
  prints `1`; `grep -cF '# Site suite — from site/ (build, internal links, facts check, accessibility and structure)' $TS`
  prints `1`; `grep -cF "npm test                          # = 'npm run build && vitest run'" $TS` prints `1`;
  `grep -c '# Site data tests' $TS` prints `0`; `grep -c "npm run check" $TS` prints at least `1` (B2 has `check`).
- [ ] infrastructure: ``grep -cF 'Facts check (`gen-facts.mjs --check`) + site test suite + Astro build on both' $IN`` prints `1`;
  ``grep -cF '(`site/astro.config.mjs`)' $IN`` prints `1` (it prints `0` before the edit); `grep -cE 'Releases API|fetch-release|site vitest|docs/\*\*' $IN`
  prints `0`; `grep -cF "No step after \`npm ci\` uses the network" $IN` prints `1`.
- [ ] integration-map: `grep -cE 'gen-reference|site fetches release data|site vitest suite' $IM` prints `0`;
  ``grep -cF 'its `build` job runs the facts check, the site test suite and the build, so a PR touching `site/`, `canonical/` or `VERSION` is gated on it' $IM``
  prints `1`; `grep -cF 'checks the site facts, tests and builds the Astro site (both events); deploys on push only' $IM`
  prints `1`.
- [ ] No placeholder or stale term: `grep -c '{B[0-9]' $TS $IN $IM` prints `0` for each;
  `grep -nE "gen-skills|gen-reference|sync-docs|sync:docs|fetch-release|skill-counts|curated-roster|flow-graph|skill-node-panel|node panel|astro-mermaid|layout-elk|mermaid-source-cache|Skill Explorer|vitest suite|site data tests|Releases API for version|docs/\*\*|~2765 vitest|build-time generators|prebuild syncs" $TS $IN $IM`
  prints nothing.
- [ ] KB rules on the added lines: `git diff -U0 site-aid -- $TS $IN $IM | grep '^+[^+]' | grep -cE 'work-[0-9]{3}|\.aid/works/|\b(FR|NFR|AC)-[0-9]+\b|\b(feature|task|delivery)-[0-9]{3}\b|\.[a-z]{2,4}:[0-9]+\b|^\+```mermaid'`
  prints `0`; `git diff -U0 site-aid -- $TS $IN $IM | grep -E '^[-+](objective|summary|tags):'` prints nothing.
- [ ] AC-14 for these files: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`,
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` and
  `bash tests/canonical/test-kb-no-work-ids.sh` exit 0.
- [ ] Accuracy verified against the current tree (DOCUMENT default): the B4 command prints exactly
  `site/astro.config.mjs`; the K10/K11 step order matches the step-order command of task-042; no package named in
  a site row of `$TS` is absent from B3.
- [ ] Scope (AC-13, NFR-5): before this task's commit `git status --porcelain --untracked-files=all` lists only the
  three files and task/delivery `STATE.yml` files under `.aid/works/work-005-site-rework/`;
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
  prints nothing; `git tag --points-at HEAD` prints nothing.
