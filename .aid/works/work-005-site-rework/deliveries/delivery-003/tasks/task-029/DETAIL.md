# task-029: Skill node panel and Mermaid source-cache files removed

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

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-1, AC-4

**Depends on:** task-028

**Scope:**
- Feature 005 § Feature Flow step 3 (it needs Feature 003, landed in delivery-002, which already removed the
  Mermaid integration, its `head` entry and the fences; this task does not touch those lines):
  - In `site/astro.config.mjs`, remove only the `Head` entry of the `components` map and its comment. The map is
    then exactly Feature 004's final block: `Header: './src/components/overrides/Header.astro'` and
    `Footer: './src/components/Footer.astro'`. No other key.
  - Delete with `git rm` the node panel and the Mermaid workaround files of Feature 005 § Migration Plan:
    `site/src/components/overrides/Head.astro`, `site/src/lib/skill-node-panel.ts`,
    `site/public/skill-node-panel.css`, `site/public/skill-node-panel.mjs` and
    `site/src/scripts/mermaid-source-cache.js` (the `src/scripts/` folder empties and is removed from disk).
- Type: IMPLEMENT, not REFACTOR (task-030 is the REFACTOR, because its built site is byte-identical): here the
  built skill pages change on purpose (the node panel and its script leave the output, Feature 005 step 3), so
  "same behaviour" does not hold. The change adds no public method, so the IMPLEMENT unit-test default has
  nothing new to cover (see the last criterion).
- No stylesheet is edited (Feature 005 step 3; `casulo.css` already left in task-024).
- Not touched: `src/lib/__tests__/`, `src/data/skill-flows/` and everything under `site/scripts/` (task-030,
  Feature 005 step 4); `package.json` (task-033). The legacy tests that import the deleted files stay red until
  task-030 deletes them (PLAN.md Cross-Cutting Risks, row 1).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than the five deleted files and
  `site/astro.config.mjs`.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Files gone: `for p in src/components/overrides/Head.astro src/lib/skill-node-panel.ts public/skill-node-panel.css public/skill-node-panel.mjs src/scripts; do test -e "$p" && echo "present: $p"; done`
  prints nothing; `ls public | LC_ALL=C sort` prints exactly three lines, `CNAME`, `favicon.svg`, `robots.txt` (FR-9 files kept unchanged:
  `git diff --name-only site-aid...HEAD -- public/CNAME public/favicon.svg public/robots.txt` from the repo root
  prints nothing).
- [ ] Components map: `grep -c "Head:" astro.config.mjs` prints `0`;
  `grep -cE "^\s*(Header: './src/components/overrides/Header.astro'|Footer: './src/components/Footer.astro'),?$" astro.config.mjs`
  prints `2` and `grep -cE "^\s*[A-Za-z]+: '\./src/components/" astro.config.mjs` prints `2`.
- [ ] No remaining user: `grep -rn 'skill-node-panel\|mermaid-source-cache\|overrides/Head' src astro.config.mjs --exclude-dir=__tests__`
  prints nothing.
- [ ] Build (AC-1): `npm run build` exits 0 and `test -f dist/index.html` exits 0; the panel left the output:
  `grep -rl 'skill-node-panel\|aid-flow-data' dist --include='*.html'` prints nothing and
  `test -e dist/skill-node-panel.mjs` exits 1.
- [ ] Links: after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site` lists only the five deleted files and
  `site/astro.config.mjs`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. No new public code, so no new
  unit test; the legacy Vitest suite is not a criterion (PLAN.md Cross-Cutting Risks, row 1).
