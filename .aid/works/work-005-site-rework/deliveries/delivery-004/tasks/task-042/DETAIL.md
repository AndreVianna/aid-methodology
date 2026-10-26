# task-042: Docs workflow docs.yml edited for the simplified site (never run)

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

**Source:** feature-006-workflow-and-safety -> delivery-004 -> AC-13

**Depends on:** task-041

**Scope:**
- Feature 006 § Feature Flow step 1 (preconditions, the entry check of PLAN.md delivery-004 Notes item 1): from
  the repo root `node site/scripts/gen-facts.mjs --check` exits 0, and from `site/` `npm test` and
  `npm run build` exit 0. If any fails, stop: the task ends `Failed` and nothing is edited.
- Feature 006 § Feature Flow step 3: edit `.github/workflows/docs.yml` exactly as § Layers & Components, "CI
  layer", items 1-3 give it:
  1. Header comment: delete the sentence "After a release, refresh the release-bound content with a
     workflow_dispatch on master."; after the paragraph ending "so a tag/release ref is rejected." insert the
     four comment lines given there (`#`, then "No step after `npm ci` uses the network. ...").
  2. The `on:` block replaced by the one given (both `paths` lists `site/**`, `canonical/**`, `VERSION`,
     `.github/workflows/docs.yml`, with their comments; `docs/**` removed; `workflow_dispatch` kept).
  3. The `build` job's `steps:` replaced by the one given (checkout, setup-node, configure-pages, the facts
     check step with its comment, `npm ci`, the "Test (site suite)" step with its comment, the build step,
     upload-pages-artifact; action SHAs and version comments exactly as written). This removes the fetch step
     with its `GITHUB_TOKEN` / `GITHUB_REPOSITORY` env, the long `AID_*` comment on the test step and the build
     step's `env:` block.
  Every other line, including `permissions:`, `concurrency:`, the `pull_request` comment lines and the whole
  `deploy` job, stays byte for byte.
- Feature 006 § Feature Flow step 4: run the six static checks of its table and record the results in this
  task's `STATE.yml` `notes:` as one line, `preconditions: facts-check <0|1|2>, npm test <exit>, build <exit>;
  static checks <p>/6 pass; failing: <ids>` (or `failing: none`). A task has no review ledger of its own; the
  delivery gate's ledger is written after every task is Done.
- The workflow is edited only, never run: no push, no `workflow_dispatch`, no `gh workflow run`, no `act` or other
  local runner.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other than
  `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no edit to any other file, under `site/`
  or the KB included; no change to any path outside the AC-13 allowed set (`site/`,
  `.github/workflows/docs.yml`, the FR-10 KB documents, `.aid/works/work-005-site-rework/`).

**Acceptance Criteria:**

Run from the repo root.

- [ ] Preconditions held: `node site/scripts/gen-facts.mjs --check` exits 0; from `site/`, `npm test` and
  `npm run build` exit 0 (run before the edit); this task's `STATE.yml` `notes:` holds the `preconditions:`
  line of the Scope with `facts-check 0, npm test 0, build 0` and `static checks 6/6 pass; failing: none`.
- [ ] Steps in order:
  `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/docs.yml')); print([s.get('name') or s['uses'].split('@')[0] for s in d['jobs']['build']['steps']])"`
  prints `['actions/checkout', 'actions/setup-node', 'actions/configure-pages', 'Check site facts against canonical/', 'Install deps (reproducible)', 'Test (site suite)', 'Build Astro Starlight site', 'actions/upload-pages-artifact']`.
- [ ] Path filters:
  `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/docs.yml'))[True]; print(d['push']['paths'] == d['pull_request']['paths'] == ['site/**','canonical/**','VERSION','.github/workflows/docs.yml'])"`
  prints `True`.
- [ ] Fetch gone: `grep -cE "fetch-release-data|GITHUB_ENV|AID_VERSION|AID_LATEST_RELEASE_JSON|AID_RELEASES_JSON|docs/\*\*" .github/workflows/docs.yml`
  prints `0`.
- [ ] Deploy job untouched:
  `diff <(git show site-aid:.github/workflows/docs.yml | sed -n '/^  deploy:/,$p') <(sed -n '/^  deploy:/,$p' .github/workflows/docs.yml)`
  prints nothing and exits 0.
- [ ] Permissions and concurrency untouched:
  `diff <(git show site-aid:.github/workflows/docs.yml | sed -n '/^permissions:/,/^jobs:/p') <(sed -n '/^permissions:/,/^jobs:/p' .github/workflows/docs.yml)`
  prints nothing and exits 0.
- [ ] The site reads no `docs/`:
  `grep -rlE "(\.\./)+docs/" site --include='*.mjs' --include='*.ts' --include='*.astro' --exclude-dir=node_modules --exclude-dir=dist`
  prints nothing.
- [ ] Header comment: `grep -c "release-bound" .github/workflows/docs.yml` prints `0` (it prints `2` on the
  unedited file: header line 8 and the old `workflow_dispatch` comment, both replaced by items 1 and 2) and
  `grep -c "After a release" .github/workflows/docs.yml` prints `0`, and
  ``grep -cF 'No step after `npm ci` uses the network.' .github/workflows/docs.yml`` prints `1`.
- [ ] No plaintext secrets, idempotent (CONFIGURE default): `git diff site-aid -- .github/workflows/docs.yml | grep '^+' | grep -ciE 'token|secret|password'`
  prints `0`; applying the edit a second time changes nothing (`git diff --stat` after a re-application shows
  only this one file with the same counts).
- [ ] Never run: no `gh` invocation in this task's commands; `git tag --points-at HEAD` prints nothing;
  `git rev-parse --abbrev-ref work-005@{upstream}` fails.
- [ ] Scope (AC-13, NFR-5): `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; before this task's commit `git status --porcelain --untracked-files=all` lists only
  `.github/workflows/docs.yml` and task/delivery `STATE.yml` files under `.aid/works/work-005-site-rework/`;
  `git diff --name-only site-aid...HEAD -- canonical '*.sh' '*.ps1' '*.psm1'` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task --
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
