# task-023: Delivery-002 gate run: content, page set and diagrams verified

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

**Source:** feature-001-content-audit, feature-003-accessible-diagrams -> delivery-002 -> AC-3, AC-8, AC-12

**Depends on:** task-005, task-006, task-007, task-008, task-009, task-010, task-011, task-012, task-013, task-014, task-015, task-016, task-017, task-018, task-019, task-020, task-021, task-022

**Scope:**
- Run, on a clean build of the finished delivery, every Gate Criterion of PLAN.md delivery-002 in the order
  listed there, plus the per-page text-equivalent count of Feature 003 (U1 by command; the automated U1-U7
  test is delivery-004's), and record the result of each.
- Commands only: from `site/`, `npm ci` (once, if `node_modules` is absent), `npm run build`, the checks
  below, and `node scripts/gen-facts.mjs --check`; from the repo root, the KB lints,
  `bash tests/canonical/select-suites.sh --since site-aid --run` and
  `bash .aid/runtime/scripts/config/read-setting.sh` (to print the minimum grade for the record).
- The graded delivery ledger (`.aid/.temp/review-pending/execute-delivery-002.md`) and its grade belong to
  the delivery gate that `aid-execute` runs after every task of delivery-002, this one included, is `Done`
  (`aid-execute/references/state-delivery-gate.md`). That ledger does not exist while this task runs and is
  outside this task: no criterion here reads it or `grade.sh`. The PLAN.md gate line "Project quality
  gates" is split: its mechanical half (select-suites and the two KB lints) runs here, its grade half runs
  at the delivery gate.
- Output: the result of each criterion (command, expected, observed, pass/fail) written to this task's
  `STATE.yml` `notes:` as a one-line summary (`N/N gate checks pass` or the failing check ids), and the
  full table into the task's review ledger as the reviewer protocol requires.
- A failing check is not fixed here: it is reported with the task (and page or file) that owns it, and the
  task ends `Failed`, so the orchestrator routes the fix to that owner.
- Not in this task: no edit to any file under `site/` or to `site-audit.md`; no test file is created
  (Feature 005 fixes the test set; delivery-004 adds the tests); the legacy Vitest suite and `npm test` are
  not run as criteria (PLAN.md Cross-Cutting Risks, row 1); no `<Tabs>` check (Tabs stay until delivery-003).
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`; no `release.sh`, no workflow run.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`); this task writes only its own `STATE.yml` and the
    review ledger under `.aid/.temp/review-pending/`.

**Acceptance Criteria:**

Run from `site/` unless stated, after `rm -rf dist && npm run build`. Set
`links() { node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"; }`.

- [ ] Build and interim Releases entry: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `grep -c "link: '/releases/changelog'" astro.config.mjs` prints `1` and
  `grep -c "slug: 'releases/changelog'" astro.config.mjs` prints `0`.
- [ ] Links and glossary anchors: `links` prints nothing.
- [ ] AC-3, all but the changelog rows: the AC-3 completeness check of Feature 001 § Data Model, piped
  through `grep -v 'releases/changelog'`, prints nothing. And
  `sed -n '/^## Redirects/,/^## /p' ../.aid/works/work-005-site-rework/site-audit.md | grep -c '| planned |'`
  prints `0`.
- [ ] Redirects: each command prints `1`:
  `grep -cE 'http-equiv="refresh"[^>]*url=/get-started/overview/' dist/get-started/index.html`,
  `grep -cE 'http-equiv="refresh"[^>]*url=/concepts/methodology/' dist/concepts/index.html`,
  `grep -cE 'http-equiv="refresh"[^>]*url=/concepts/methodology/' dist/concepts/overview/index.html`,
  `grep -cE 'http-equiv="refresh"[^>]*url=/reference/overview/' dist/reference/index.html`,
  `grep -cE 'http-equiv="refresh"[^>]*url=/skills/' dist/reference/skills/index.html`.
- [ ] Page weight: `find dist -name '*.html' -size +150k` prints nothing.
- [ ] AC-8, Mermaid gone: from the repo root,
  `grep -rln '^```mermaid' site/src/content/docs --include='*.md*' | grep -v '/skills/'` prints nothing and
  `grep -n 'mermaid' site/astro.config.mjs` prints nothing; from `site/`,
  `grep -rlE 'class="mermaid|data-language="mermaid"' dist --include='*.html'` prints nothing.
- [ ] `node:fs` import removed (Cross-Cutting Risk 2): `grep -c "from 'node:fs'" astro.config.mjs` prints `0`.
- [ ] AC-8, every diagram placed:
  `for p in index.html concepts/pipeline/index.html concepts/methodology/index.html concepts/knowledge-base/index.html concepts/agents/index.html concepts/feedback-loops/index.html concepts/aid-and-sdd/index.html guides/maintainer/index.html guides/pipeline/index.html; do echo "$p $(grep -o '<figure class="diagram' "dist/$p" | wc -l)"; done`
  prints `index.html 1`, `concepts/pipeline/index.html 2`, `concepts/methodology/index.html 1`,
  `concepts/knowledge-base/index.html 2`, `concepts/agents/index.html 1`, `concepts/feedback-loops/index.html 1`,
  `concepts/aid-and-sdd/index.html 1`, `guides/maintainer/index.html 1` and `guides/pipeline/index.html 1`,
  one per line in that order; and
  `grep -rho '<figure class="diagram' dist --include='*.html' | wc -l` prints `11`.
- [ ] AC-8, a text equivalent per diagram (U1 by command): for every built page,
  `for f in $(grep -rl '<figure class="diagram' dist --include='*.html'); do a=$(grep -o '<figure class="diagram' "$f" | wc -l); b=$(grep -oE 'class="diagram-text[ "]' "$f" | wc -l); [ "$a" = "$b" ] || echo "$f: $a figures, $b text equivalents"; done`
  prints nothing; and `ls src/components/diagrams/*.astro | wc -l` prints `10`.
- [ ] Raster removed: from the repo root, `grep -rn '3-ironman' site/src` prints nothing and
  `test -e site/src/assets/3-ironman.png` exits 1.
- [ ] Feature 003 size cap: `wc -l src/components/Diagram.astro src/components/diagrams/*.astro | tail -n 1`
  prints a total of at most 1500.
- [ ] No leftover probe: `test -e src/content/docs/dg-probe.mdx` exits 1 and `test -e dist/dg-probe` exits 1.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] AC-12 (judged by the reviewer, Feature 001 § Feature Flow step 7): reading `src/content/docs/index.mdx`
  and the four Get Started pages (`get-started/{overview,install}.md`, `get-started/{first-work,lite-path}.mdx`),
  the first paragraph of each is one sentence of purpose, and every glossary term
  (`grep '^### ' src/content/docs/reference/glossary.md`) is linked to `/reference/glossary/#<anchor>` on its
  first use on each page. The reviewer lists each term found and its first-use line; one unlinked first use
  fails this criterion.
- [ ] Project quality gates, the mechanical half this task can run itself (`.aid/knowledge/quality-gates.md`
  § Mechanical Gates Run by the Orchestrator), from the repo root:
  `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`
  prints a grade letter, recorded in the result table for the delivery gate;
  `bash tests/canonical/select-suites.sh --since site-aid --run`,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. The grade of the
  delivery ledger is the delivery gate's, after this task (Scope).
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical '*.sh' '*.ps1' '*.psm1'` prints nothing;
  `git tag --points-at HEAD` prints nothing; this task leaves `git status --porcelain site` empty.
- [ ] Tests are deterministic, with clean setup and teardown (TEST default): a second full run of every
  command above, after `rm -rf dist && npm run build`, gives the same results, and the run creates no file
  outside `site/dist/`, `.aid/.temp/` and this task's `STATE.yml`.
- [ ] All acceptance criteria from the source features covered (TEST default): every Gate Criterion line of
  PLAN.md delivery-002 maps to one criterion above, except the grade half of "Project quality gates",
  which the result table lists as `delivery gate` (run after this task); the table lists every other line
  with pass or fail.
