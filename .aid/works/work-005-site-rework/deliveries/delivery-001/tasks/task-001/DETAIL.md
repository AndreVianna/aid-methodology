# task-001: Site package scripts without build-time regeneration

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

**Type:** CONFIGURE

**Source:** feature-005-machinery-cut -> delivery-001 -> AC-1

**Depends on:** --

**Scope:**
- Feature 005 § Feature Flow step 1 ("Stop the regeneration") only: replace the `scripts` object of
  `site/package.json` with the `scripts` block of Feature 005 § Data Model, "1. `package.json` after the
  cut", in exactly that key order: `facts`, `facts:check`, `build`, `dev`, `preview`, `astro`, `check`,
  `test` (values verbatim from the spec; `test` is `npm run build && vitest run`).
- This removes `sync:docs`, `gen:reference`, `gen:skills`, `fetch:release`, `prebuild` and `predev`, so no
  later build or dev run rewrites `site/src/content/docs/` or fetches release data.
- The only file changed is `site/package.json`, and in it only the `scripts` key. `dependencies`,
  `devDependencies`, `overrides` and every other key stay byte-for-byte as they are (Feature 005 step 6 is
  delivery-003). `site/package-lock.json` is not changed (scripts are not recorded in it).
- `facts` and `facts:check` point at `scripts/gen-facts.mjs`, which task-003 creates; until then they are
  not run. Nothing in this task runs them.
- This change must be committed before any commit that contains output of `site/scripts/gen-facts.mjs`
  (PLAN.md delivery-001 Notes, order item 1).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside
  the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `site/package.json`.
- Known and accepted: the legacy Vitest suite under `site/scripts/__tests__/` and `site/src/**/__tests__/`
  may fail once generated pages change (PLAN.md Cross-Cutting Risks, row 1); `npm test` is not a criterion
  of this task or delivery.

**Acceptance Criteria:**
- [ ] From `site/`: `node -p "Object.keys(require('./package.json').scripts).join(' ')"` prints exactly
  `facts facts:check build dev preview astro check test`.
- [ ] From `site/`: `node -p "require('./package.json').scripts.test"` prints `npm run build && vitest run`;
  `node -p "require('./package.json').scripts.facts"` prints `node scripts/gen-facts.mjs`;
  `node -p "require('./package.json').scripts['facts:check']"` prints `node scripts/gen-facts.mjs --check`.
- [ ] Only `scripts` changed: `git diff site-aid -- site/package.json` shows changed lines only inside the
  `"scripts": { ... }` object, and `git diff --name-only site-aid -- site/package-lock.json` prints nothing.
- [ ] AC-1: from `site/`, `npm ci && npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] No regeneration at build time: from `site/`, after that build, `git status --porcelain src/content/docs`
  prints nothing, and `npm run build 2>&1 | grep -cE 'prebuild|sync-docs|gen-reference|gen-skills|fetch-release'`
  prints `0`.
- [ ] Configuration is idempotent: re-running `npm run build` a second time exits 0 and leaves
  `git status --porcelain src/content/docs` empty. No plaintext secrets: the diff adds no token, key or URL
  with credentials.
- [ ] Scope (AC-13, NFR-5): from the repo root, `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing, and `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
