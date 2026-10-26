# task-004: Facts check test suite tests/facts.test.mjs

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

**Source:** feature-002-canonical-facts -> delivery-001 -> AC-2

**Depends on:** task-002, task-003

**Scope:**
- Create `site/tests/facts.test.mjs`, FR-8 group (c), with exactly the cases C1-C5 of Feature 002
  § Layers & Components, "Tests (FR-8 group c)", in a single vitest `describe`:
  - C1 `--check` on the committed pages: exit 0, output matches `/pages up to date/`.
  - C2 copy `site/src/content/docs/{skills,reference/agents.md,reference/settings.md}` into a `mkdtempSync`
    folder, append a line to `skills/aid-fix.md`, `--check --out <tmp>`: `status === 1`, stderr names
    `stale: skills/aid-fix.md`.
  - C3 same copy plus `skills/aid-gone.md`, `--check --out <tmp>`: `status === 1`, stderr names
    `extra: skills/aid-gone.md`.
  - C4 copy `canonical/skills`, `canonical/agents` and the two templates (`aid/templates/shortcut-catalog.yml`,
    `aid/templates/settings.yml`) into a temp `canonical` tree, add `skills/aid-orphan/SKILL.md` with
    `name: aid-orphan` and a `description`, `--check --canonical <tmp>`: `status === 2`, stderr contains
    `aid-orphan has no group`.
  - C5 `--out <empty tmp>`: exit 0 with `wrote <expected>`, where `<expected>` is computed in the test as
    `readdirSync(join(REPO, 'canonical/skills')).length + 3` (never a literal); then `--check --out <tmp>`:
    exit 0.
- Test titles: each case is one `it('...', ...)` call whose title is a single-quoted string starting with
  its label and a space, using Feature 002's case names: `'C1 committed pages are current'`,
  `'C2 a stale page is caught'`, `'C3 an extra page is caught'`, `'C4 an ungrouped skill fails'`,
  `'C5 write mode reproduces the committed bytes'`. No other `it`/`test` call exists in the file.
- Every path is built from `SITE` and `REPO` imported from `./dist.mjs` (task-002), never from a relative
  string; every case runs
  `spawnSync(process.execPath, [join(SITE, 'scripts/gen-facts.mjs'), ...args], { cwd: SITE, encoding: 'utf8' })`.
- Fixtures live only in temp folders created with `mkdtempSync(join(tmpdir(), 'aid-facts-test-'))` (that
  exact prefix, for every temp folder) and removed in
  `afterAll`; the test never writes inside `site/src/content/docs/`. Exit-code assertions are exact
  (`toBe(1)`, `toBe(2)`, `toBe(0)`), so a crash (exit 2) cannot pass a drift case.
- Run it by path (`npx vitest run tests/facts.test.mjs`): `site/vitest.config.mjs` is still the old one, and
  its default include finds `tests/facts.test.mjs`; it is not edited here (Feature 005 step 7,
  delivery-004). The legacy suite and `npm test` are not part of this task (PLAN.md Cross-Cutting Risks,
  row 1).
- This is the closing task of delivery-001. The graded ledger
  (`.aid/.temp/review-pending/execute-delivery-001.md` and its `grade.sh` grade) is produced by the
  delivery gate that `aid-execute` runs after all four tasks are Done; it is outside this task, which runs
  only the mechanical checks it can run itself (last criterion).
- The only file created is `site/tests/facts.test.mjs`. If a case fails because `gen-facts.mjs` deviates
  from Feature 002, the fix belongs to task-003's file and is reported, not patched around in the test.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside
  the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`). No test name or string contains `flow-graph`, `provenance`,
  `node-panel` or `sync-docs` (AC-5 grep).

**Acceptance Criteria:**
- [ ] From `site/`, `npx vitest run tests/facts.test.mjs --reporter=verbose` exits 0, reports 5 passed tests
  and no failed or skipped test, and its output holds the five titles of the Scope.
- [ ] Titles: `grep -oE "it\('C[1-5] " site/tests/facts.test.mjs | sort -u | wc -l` prints `5`, and
  `grep -cE "(^|[^.a-zA-Z])(it|test)(\.[a-z]+)?\(" site/tests/facts.test.mjs` prints `5` (exactly five cases,
  none skipped or added).
- [ ] Exact exit codes: `grep -cE "toBe\(1\)" site/tests/facts.test.mjs` prints at least `2` (C2, C3),
  `grep -cE "toBe\(2\)" site/tests/facts.test.mjs` prints at least `1` (C4), and
  `grep -cE "toBeGreaterThan|not\.toBe\(0\)" site/tests/facts.test.mjs` prints `0`;
  `grep -c "length + 3" site/tests/facts.test.mjs` prints at least `1` and
  `grep -cE "wrote 4[0-9]" site/tests/facts.test.mjs` prints `0` (no literal count).
- [ ] Paths: `grep -c "from './dist.mjs'" site/tests/facts.test.mjs` prints `1`, and
  `grep -nE "['\"]\.\.?/(src|scripts|\.\./canonical)" site/tests/facts.test.mjs` prints nothing (no path
  resolved against the working directory; `join(SITE, ...)` / `join(REPO, ...)` forms are the expected ones).
- [ ] The test can fail (it detects real drift): with one line temporarily appended to
  `site/src/content/docs/skills/aid-fix.md`, `npx vitest run tests/facts.test.mjs` exits non-zero with C1
  failing; after `git checkout -- src/content/docs/skills/aid-fix.md` it exits 0 again.
- [ ] Deterministic, clean setup and teardown: three consecutive runs of `npx vitest run tests/facts.test.mjs`
  all exit 0; after them, from `site/`, `git status --porcelain src/content/docs` prints nothing, and
  `ls -d "$(node -p "require('os').tmpdir()")"/aid-facts-test-* 2>/dev/null | wc -l` prints `0`, and
  `grep -c "aid-facts-test-" site/tests/facts.test.mjs` prints at least `1` (the prefix is the one in use).
- [ ] All acceptance criteria of the source feature covered: AC-2 first half by C1 (and C2-C5 prove the
  check can fail); AC-2 second half is task-003's build count and stays green: from `site/`, after
  `npm run build`, `find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` equals
  `ls ../canonical/skills | wc -l`.
- [ ] AC-5 words: `grep -cE "flow-graph|provenance|node-panel|sync-docs" site/tests/facts.test.mjs` prints `0`.
- [ ] Scope (AC-13, NFR-5): from the repo root, `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; before this task's commit, `git status --porcelain --untracked-files=all site` lists only
  `site/tests/facts.test.mjs`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash tests/canonical/select-suites.sh --since site-aid --run`,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0, and
  `bash .aid/runtime/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A` prints a
  grade letter, recorded in the task's report for the delivery gate. No criterion here needs the graded
  delivery ledger (see Scope).
