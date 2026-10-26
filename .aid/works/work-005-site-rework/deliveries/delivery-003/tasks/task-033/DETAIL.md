# task-033: Site dependencies pruned and lockfile regenerated

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

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-1, AC-5

**Depends on:** task-032

**Scope:**
- Feature 005 § Feature Flow step 6, in its order, from `site/`:
  1. Precondition: `grep -rn '@fontsource' src` prints nothing (task-024 deleted `casulo.css`). If it prints
     anything, stop and end `Failed`.
  2. `npm uninstall astro-mermaid marked sanitize-html @mermaid-js/layout-elk @types/sanitize-html @fontsource/inter`
  3. `npm install --save-dev --save-exact axe-core@4.14.0 jsdom@29.1.1`
  4. Delete the `dompurify` entry from `overrides` in `site/package.json`, then run `npm install` to regenerate
     `site/package-lock.json`.
- Result: the `scripts`, `dependencies`, `devDependencies` and `overrides` of `site/package.json` equal the
  Feature 005 § Data Model 1 block; `name`, `description`, `version`, `private` and `engines` are unchanged.
- These npm runs are the only network use of the delivery (PLAN.md delivery-003 Notes, last item); they run on
  the maintainer's machine, never inside the build.
- Not touched: any file under `site/src/`, `site/tests/`, `vitest.config.mjs`.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than the npm commands of step 6 above and `npm ci` (the install family, run from `site/`); no `.npmrc` or token
  written; no edit under `canonical/`; no change to any path outside the AC-13 allowed set (`site/`,
  `.github/workflows/docs.yml`, the FR-10 KB documents, `.aid/works/work-005-site-rework/`), and inside it no file
  other than `site/package.json` and `site/package-lock.json`.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Precondition recorded: `grep -rn '@fontsource' src` printed nothing before the first npm command (noted in
  this task's `STATE.yml` `notes:`).
- [ ] Data Model 1 block (FR-11): `node -e "const p=require('./package.json'); const want={scripts:{facts:'node scripts/gen-facts.mjs','facts:check':'node scripts/gen-facts.mjs --check',build:'astro build',dev:'astro dev',preview:'astro preview',astro:'astro',check:'astro check',test:'npm run build && vitest run'},dependencies:{'@astrojs/sitemap':'3.7.3','@astrojs/starlight':'0.39.3',astro:'6.4.6'},devDependencies:{'@astrojs/check':'0.9.9','axe-core':'4.14.0',jsdom:'29.1.1',typescript:'6.0.3',vitest:'^4.1.8'},overrides:{yaml:'^2.8.3',esbuild:'^0.28.1'}}; console.log(Object.keys(want).every(k=>JSON.stringify(p[k])===JSON.stringify(want[k])))"`
  prints `true`; `node -p "const p=require('./package.json'); [p.name,p.version,p.private,p.engines.node].join(' ')"`
  prints `aid-product-site 0.0.1 true >=22.12.0`.
- [ ] Removed packages (FR-11): `npm ls mermaid marked sanitize-html` output contains `(empty)`;
  `grep -c '"node_modules/mermaid"' package-lock.json` prints `0`; `grep -c '"node_modules/@fontsource/inter"' package-lock.json`
  prints `0`; `grep -c '"node_modules/dompurify"' package-lock.json` prints `0`.
- [ ] Added packages: `node -p "require('axe-core/package.json').version"` prints `4.14.0` and
  `node -p "require('jsdom/package.json').version"` prints `29.1.1`.
- [ ] AC-1: `npm ci && npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Suite green: `npm test` exits 0 and its Vitest output lists exactly `tests/facts.test.mjs`.
- [ ] Configuration is idempotent (CONFIGURE default): a second `npm install` leaves
  `git status --porcelain package.json package-lock.json` exactly as after the first.
- [ ] No plaintext secrets (CONFIGURE default): `test -e .npmrc` exits 1 and
  `grep -ciE '_authToken|password' package.json package-lock.json` prints `0` for each file.
- [ ] Facts and links: `node scripts/gen-facts.mjs --check` exits 0; after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site` lists only `site/package.json` and `site/package-lock.json`;
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
