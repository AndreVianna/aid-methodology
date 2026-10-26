# task-030: Old generators, libraries, flow data and legacy tests deleted

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

**Type:** REFACTOR

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-4, AC-5

**Depends on:** task-029

**Scope:**
- Feature 005 § Feature Flow step 4, first part: delete with `git rm` the rest of the § Migration Plan delete
  list (all under `site/`):
  - `scripts/sync-docs.mjs`, `scripts/.synced-manifest.json`;
  - `scripts/gen-skills.mjs`, `scripts/.skills-manifest.json`, `scripts/skills/`;
  - `scripts/gen-reference.mjs`, `scripts/.reference-manifest.json`;
  - `scripts/fetch-release-data.mjs`;
  - `scripts/lib/` (`flow-graph/`, `provenance/`);
  - `scripts/__tests__/` (including `source-encoding.test.mjs`, which belongs to no FR-8 group);
  - `src/lib/` (what is left: `__tests__/`; the folder is removed from disk);
  - `src/data/skill-flows/` and `src/data/__tests__/`.
  `scripts/gen-facts.mjs` and `src/data/version.ts` stay.
- Feature 005 step 4, schema bullet: in `site/src/content.config.ts`, remove the `sourceDoc` and
  `generatedFrom` fields and their comments; keep `reportIssue: z.boolean().default(true)` and the `zod` import
  as it is (Data Model 1, last paragraph).
- Behaviour is unchanged: no build reads these files any more (task-001 removed `prebuild`/`predev`;
  task-029 removed their last runtime user), and the schema fields feed no rendered output.
- Not touched: the page frontmatter lines `sourceDoc:` / `generatedFrom:` and `reference/artifacts.md`
  (task-031); `vitest.config.mjs` (delivery-004, Feature 005 step 7); `site/tests/`; `package.json` (task-033).
  The three files outside `site/` that still name deleted scripts are out of scope (Feature 005 § Migration
  Plan, "Outside `site/`") and are not edited.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`, `docs/` or `.claude/`; no change to
  any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than the deleted paths and
  `site/src/content.config.ts`.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] No behaviour change (REFACTOR default, measured on the built site): before the change,
  `npm run build && rm -rf ../.aid/.temp/task-030-dist && mkdir -p ../.aid/.temp && cp -r dist ../.aid/.temp/task-030-dist`;
  after the change, `npm run build` exits 0 and `diff -r ../.aid/.temp/task-030-dist dist` prints nothing; then
  `rm -rf ../.aid/.temp/task-030-dist`.
- [ ] AC-4, `scripts/` clause: `find scripts -type f` prints exactly `scripts/gen-facts.mjs`.
- [ ] Deleted: `find src scripts -name __tests__` prints nothing;
  `for p in src/lib src/data/skill-flows src/data/__tests__; do test -e "$p" && echo "present: $p"; done` prints
  nothing; `ls src/data` prints exactly `version.ts`.
- [ ] AC-5, no test of removed code: from the repo root,
  `grep -rl "flow-graph\|provenance\|node-panel\|sync-docs" site --include='*.test.*' --exclude-dir=node_modules`
  prints nothing.
- [ ] Schema: `grep -c 'sourceDoc\|generatedFrom' src/content.config.ts` prints `0`;
  `grep -c 'reportIssue: z.boolean().default(true)' src/content.config.ts` prints `1`.
- [ ] FR-12 / NFR-4 (full delivery-003 command, now that the fetch script is gone):
  `grep -rnE "fetch\(|node:https?|https?\.get\(|process\.env" scripts src/components src/data astro.config.mjs`
  prints nothing.
- [ ] Suite green again (delivery-003 gate): `npm test` exits 0, and its Vitest output lists exactly one test file,
  `tests/facts.test.mjs` (the old `vitest.config.mjs` has no `include`, so its default pattern finds only that file;
  PLAN.md delivery-001 Notes).
- [ ] Facts and links: `node scripts/gen-facts.mjs --check` exits 0; after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical docs .claude` prints nothing; before this
  task's commit, `git status --porcelain --untracked-files=all site | grep -vE '^ ?D  ?site/(scripts|src/lib|src/data)/'`
  lists only `site/src/content.config.ts`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Tests before and after
  (REFACTOR default): before, the legacy suite is known red (PLAN.md Cross-Cutting Risks, row 1), so the
  before/after equality is the `diff -r` of the built site above; after, `npm test` is green.
