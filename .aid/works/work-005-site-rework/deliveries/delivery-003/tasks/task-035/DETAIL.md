# task-035: Delivery-003 gate run: new look and machinery cut verified

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

**Type:** TEST

**Source:** feature-004-look-and-layout, feature-005-machinery-cut -> delivery-003 -> AC-1, AC-4, AC-5, AC-9, AC-11, AC-15

**Depends on:** task-024, task-025, task-026, task-027, task-028, task-029, task-030, task-031, task-032, task-033, task-034

**Scope:**
- Run, on a clean install and build of the finished delivery, every Gate Criterion of PLAN.md delivery-003 in
  the order listed there, and record the result of each.
- Commands only: from `site/`, `npm ci`, `npm run build`, `npm test`, the checks below and
  `node scripts/gen-facts.mjs --check`; from the repo root, the KB lints,
  `bash tests/canonical/select-suites.sh --since site-aid --run` and, printed for the record,
  `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`.
  AC-9 and AC-11 are verified from what task-034 recorded; they are not re-run here.
- Outside this task: the graded delivery ledger `.aid/.temp/review-pending/execute-delivery-003.md` and its
  grade are produced by the delivery gate that `aid-execute` runs after every task of this delivery is `Done`
  (PLAN.md delivery-003 Gate Criteria, "Project quality gates"). This task neither requires that ledger to exist
  nor grades it.
- AC-9 / AC-11 open status: if task-034 took Path B (no browser without a download), its audit cells read
  `awaiting maintainer run` and task-034 ended `Done`. That is not a failure here: this task checks the Path B
  record is complete and writes `AC-9 and AC-11 unproven: awaiting maintainer run` into its `notes:` summary,
  which is the line the delivery's final report carries forward.
- Output: the result of each criterion (command, expected, observed, pass/fail) written to this task's
  `STATE.yml` `notes:` as a one-line summary (`N/N gate checks pass`, or the failing check ids, plus the AC-9 /
  AC-11 open-status line when it applies).
- A failing check is not fixed here: it is reported with the task (and file) that owns it, and the task ends
  `Failed`, so the orchestrator routes the fix to that owner.
- Not in this task: no edit to any file under `site/` or to `site-audit.md`; no test file is created
  (`tests/a11y.test.mjs`, `tests/contrast.test.mjs`, `tests/build.test.mjs`, `tests/links.test.mjs` and the
  `vitest.config.mjs` rewrite are delivery-004's).
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`; no `release.sh`, no workflow run.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB
    documents, `.aid/works/work-005-site-rework/`); this task writes only its own `STATE.yml` (and scratch
    files under `.aid/.temp/`).

**Acceptance Criteria:**

Run from `site/` unless stated, after `rm -rf dist && npm ci && npm run build`. Set
`links() { node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"; }`,
`V=$(tr -d '[:space:]' < ../VERSION | sed 's/^v//')` and `A=../.aid/works/work-005-site-rework/site-audit.md`.

- [ ] AC-1: `npm ci && npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Suite green again: `npm test` exits 0 and its Vitest output lists only `tests/facts.test.mjs`.
- [ ] AC-5, no test of removed code: from the repo root,
  `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules`
  prints nothing.
- [ ] AC-4, `scripts/` clause: `find scripts -type f` prints exactly `scripts/gen-facts.mjs`.
- [ ] FR-7: `grep -rln "sourceDoc\|generatedFrom\|release-data\|skill-flows" src astro.config.mjs` prints nothing.
- [ ] FR-12 / NFR-4: `grep -rnE "fetch\(|node:https?|https?\.get\(|process\.env" scripts src/components src/data astro.config.mjs`
  prints nothing.
- [ ] FR-11: `npm ls mermaid marked sanitize-html` output contains `(empty)`;
  `grep -c '"node_modules/mermaid"' package-lock.json` prints `0`;
  `node -p "require('axe-core/package.json').version"` prints `4.14.0`; and the `scripts`, `dependencies`,
  `devDependencies` and `overrides` of `package.json` equal Feature 005's Data Model 1 block (the `node -e`
  comparison of task-033 prints `true`).
- [ ] Version source: `grep -c "from 'node:fs'" astro.config.mjs` prints `1`; `grep -c "v$V" dist/index.html` and
  `grep -c "v$V" dist/releases/changelog/index.html` each print at least `1`.
- [ ] Feature 004 tokens only: `grep -rn -- '--casulo-' src` and `grep -rn '@fontsource' src` print nothing.
- [ ] Feature 004 Tabs gone: `grep -rlE '<Tabs|<TabItem|import \{[^}]*Tabs' src/content/docs` and
  `grep -rl 'starlight-tabs' dist --include='*.html'` print nothing.
- [ ] Files deleted and created:
  `for p in src/styles/casulo.css src/styles/shell.css src/components/overrides/PageTitle.astro src/components/overrides/Head.astro src/components/Banner.astro src/pages src/lib src/data/skill-flows src/data/__tests__ src/scripts/mermaid-source-cache.js public/skill-node-panel.css public/skill-node-panel.mjs; do test -e "$p" && echo "present: $p"; done`
  prints nothing; `find src scripts -name __tests__` prints nothing;
  `test -f src/styles/tokens.css && test -f src/styles/site.css && test -f src/content/docs/releases/changelog.mdx`
  exits 0.
- [ ] Releases sidebar entry switched: `grep -c "slug: 'releases/changelog'" astro.config.mjs` prints `1` and
  `grep -c "link: '/releases/changelog'" astro.config.mjs` prints `0`.
- [ ] Links and glossary anchors: `links` prints nothing.
- [ ] AC-15, size half: `find dist -name '*.html' -size +150k` prints nothing.
- [ ] AC-9 and AC-11, from task-034's record (its criteria re-run here, from `site/`). Let
  `KB() { sed -n '/^## Keyboard check (AC-9)/,/^## /p' "$A"; }`, `SH() { sed -n '/^## Screenshots (AC-11)/,/^## /p' "$A"; }`
  and `S=../.aid/works/work-005-site-rework/screenshots`. Exactly one of these holds:
  - Proven (task-034 Path A, or the maintainer has since filled the rows):
    `KB | grep -cE '^\| /(skills/aid-define/)? \| Skip to content, Casulo AI Labs, AID( AI Integrated Development)?, GitHub, Select theme, Search, .*Report a problem with this page on GitHub \| yes \(([0-9]+)/\3 stops\) \| pass[,;] (Playwright, checks/ac9-ac11\.mjs|manual, maintainer, [^|]+), [0-9]{4}-[0-9]{2}-[0-9]{2} \|$'`
    prints `2`; `for p in home aid-define; do for w in 320 1280; do for t in light dark; do test -s $S/$p-$w-$t.png || echo "missing: $p-$w-$t"; done; done; done`
    prints nothing; `SH | grep -o 'scrollWidth <= innerWidth: true' | wc -l` prints `8`; and
    `cat <(KB) <(SH) | grep -cE 'false|pending|awaiting'` prints `0`.
  - Open (task-034 Path B): `KB | grep -cE '^\| /(skills/aid-define/)? \|( awaiting maintainer run \|){3}$'` prints `2`,
    `SH | grep -cE '^\| /(skills/aid-define/)? \|( awaiting maintainer run \|){4}$'` prints `2` and
    `grep -cF 'AC-9 and AC-11 are unproven: awaiting maintainer run.' "$A"` prints `2`; then this task's
    `STATE.yml` `notes:` contains `AC-9 and AC-11 unproven: awaiting maintainer run`
    (`grep -c 'AC-9 and AC-11 unproven: awaiting maintainer run' ../.aid/works/work-005-site-rework/deliveries/delivery-003/tasks/task-035/STATE.yml`
    prints `1`), and the check counts as passed with that open status carried to the final report.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Project mechanical checks this task can run itself (`.aid/knowledge/quality-gates.md` § Mechanical Gates Run
  by the Orchestrator), from the repo root: `bash tests/canonical/select-suites.sh --since site-aid --run`,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0; and
  `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A` exits 0 and
  prints one grade, recorded in `notes:` for the delivery gate. The graded ledger
  `execute-delivery-003.md` is the delivery gate's, after this task (Scope), and is not a criterion here.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical '*.sh' '*.ps1' '*.psm1'` prints nothing;
  `git tag --points-at HEAD` prints nothing; this task leaves `git status --porcelain site` empty.
- [ ] Tests are deterministic, with clean setup and teardown (TEST default): a second full run of every command
  above, after `rm -rf dist && npm run build`, gives the same results, and the run creates no file outside
  `site/dist/`, `site/node_modules/`, `.aid/.temp/` and this task's `STATE.yml`.
- [ ] All acceptance criteria from the source features covered (TEST default): every Gate Criterion line of
  PLAN.md delivery-003 maps to one criterion above, except the graded-ledger half of "Project quality gates",
  which the delivery gate runs after this task; the `notes:` summary lists every criterion with pass or fail
  (and, on task-034 Path B, the AC-9 / AC-11 open status).
