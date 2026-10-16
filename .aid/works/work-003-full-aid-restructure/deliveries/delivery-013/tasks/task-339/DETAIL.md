# task-339: aid-config renamed aid-configure: the skill, its guide line and its lists

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 339 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-013 -> AC-22, AC-31

**Depends on:** task-338

**Scope:**
- Move `canonical/skills/aid-config/` to `canonical/skills/aid-configure/` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`, Move +
  edit): `name: aid-configure`; its `description:` in the what/when shape (Feature 001; today's description,
  reworded); every mention of itself inside the skill, including the settings rows Features 004 and 008 edited (Q30,
  NFR-N).
- **G14:** this first task that writes in `canonical/skills/aid-configure/` moves the folder with its `SKILL.md` and
  gives it its site roster entry (`site/scripts/skills/curated-roster.mjs`, `groups.mjs` and their `__tests__`), so
  the site accepts the folder at this task's end.
- **Lists and counts that follow a renamed skill**, in this same task:
  - its `canonical/aid/rules.md` § Skill guide line: `` - `/aid-configure` -- set up or change this project's AID
    settings `` (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`);
  - the `aid-config` row of the SG-04 description exempt list in `tests/canonical/test-skill-guide.sh` goes, and the
    list ends empty (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Lists);
  - any `skill:aid-config` row of `tests/conversation/deferred.tsv` follows the new name;
  - sample `002-02`'s `skills:` line names `aid-configure` (the rename in approved features);
  - the skill count does not change; the doc phrases that name the skill are delivery-014's.
- **Site fixtures (G11, extended).** The site tests that load a skill this task rewrites or renames as a fixture, by path
  or by name (the findings' site-fixture search), are re-pointed in this same task.
- **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
  build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
  list does not come from the findings' map alone. Every suite it finds is updated in this same task
  (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
  criterion is scoped so it holds without the row.
- **KB `sources:` citations (G17).** Every `.aid/knowledge/` document whose frontmatter `sources:` cites a file or
  folder this task deletes, moves or renames is fixed in this same task (`git grep -n -e '<path>' -e '<folder>/' --
  .aid/knowledge/` at this task's base): the entry follows a moved file, and goes when the file is gone. Only the
  `sources:` entries change here; the prose stays for the delivery's DOCUMENT task. So `test-artifact-discipline.sh`
  AD14 (every `sources:` citation resolves) holds at this task's end. The KB lines are committed as the delivery
  commits KB paths (through `kb-commit.sh` once it exists, as Feature 007's BUILD requires).
- **The retired skill's site pages (G18).** Before regenerating, `git rm` what the generators no longer produce for each
  skill folder this task deletes or renames away: its page under `site/src/content/docs/skills/` and its
  `site/src/data/skill-flows/<name>.flow.json` (the generators never delete; `gen-skills.mjs`'s drift check names any
  orphan with its `git rm` remedy). Then the site regeneration below.
- **Site generator sources (G19).** Every site script source outside `__tests__` that hard-codes the name of a skill
  this task retires or renames (`git grep -nE 'aid-<name>([^a-z-]|$)' -- site/scripts/ ':!site/scripts/__tests__'`,
  for example the settings-page intro in `gen-reference.mjs` or a name list in `lib/flow-graph/extract-residual.mjs`)
  is fixed in this same task, before it regenerates: the name follows the rename, or the retired skill's mention
  goes. A generated page is never edited by hand to hide a stale generator.
- **Site regeneration (G1, G5).** When this task adds, deletes, renames or edits anything under
  `canonical/skills/`, `canonical/agents/` or `canonical/aid/templates/`, it runs
  `(cd site && npm run gen:skills && npm run gen:reference)` in this same task and commits the output:
  the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md`,
  `reference/agents.md` and `scripts/.skills-manifest.json`.
  - It also updates any hard-coded count or name list in a site generator, for example the agent count
    in `site/scripts/gen-reference.mjs`, so the generators' drift checks pass at this task's end.
  - A generated site page is never edited by hand.
- **Later checks on this task's files (G3).** Before `Done`, run by hand, over the files this task
  writes, every static-check pattern that this delivery's own suites or an earlier delivery's suites apply
  to those files, and fix every hit here. Repo-wide criteria in this file are scoped to what this task
  owns.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` assigns to `task-339`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-339.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-339`.
       That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
     - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
     - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
     - Run `rm -rf "$S"` before step 4.
     - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
  4. **Live half.**
     - When `LIVE` is every suite outside `COPY`, run `HOME="$(mktemp -d)" bash tests/run-all.sh` and
       drop the `COPY` suites' results by name.
     - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
  5. **Outside `run-all.sh`.**
     - Run `(cd site && npm test)` when this task changes anything under `canonical/skills/`,
       `canonical/agents/` or `canonical/aid/templates/`, or under `docs/` or `site/` (G5). Run `npm ci`
       there first if `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] `test -d canonical/skills/aid-config` fails; `canonical/skills/aid-configure/SKILL.md` has `name: aid-configure` and a what/when `description:`; over the skill, `grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)'` prints nothing.
- [ ] The SG-04 exempt list is empty, `AID_RELEASE_CHECK=1 bash tests/canonical/test-skill-guide.sh` passes SG-04 where the test step puts it, and `test-skill-guide.sh` passes there; the site `npm test` passes after regeneration.
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] No page under `site/src/content/docs/skills/` and no `site/src/data/skill-flows/*.flow.json` is left for a skill folder this task deletes or renames away, and `npm run gen:skills` reports no orphan (G18).
- [ ] Over `site/scripts/` outside `__tests__`, no source names a skill this task retires, and none names a renamed skill by its old name (G19).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
