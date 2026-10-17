# task-116: aid-kb-build: the move, START, ELICIT and GENERATE

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

**Source:** feature-004-kb-management -> delivery-005 -> AC-15, AC-28, AC-37

**Depends on:** task-105, task-110

**Scope:**
- Move `canonical/skills/aid-discover/` to `canonical/skills/aid-kb-build/` (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and
  layout` and `##### 3. Flows`).
- `SKILL.md` is rewritten, at most 150 lines:
  - its step table, as the spec's `/aid-kb-build` table;
  - `skill-steps.md` and `question-protocol.md` cited;
  - the opening check (plan mode, `recon-classify.sh`, a rebuild confirmed with one question);
  - `--reset`, `--grade`, § Targeted Discovery and the state map go;
  - the dispatch-visibility checklist stays as a pointer to `long-wait-protocol.md`.
- References:
  - new `references/start.md` (at most 120 lines): the rebuild clear (`--kb --clear-build`), the
    existing-KB check moved from `generate.md` Step 0, the domain and the document set, `Domain` and
    `Triage`;
  - `state-elicit.md` becomes `elicit.md`, writing `Elicitation`;
  - `state-generate.md` becomes `generate.md`; its Step 7 goes;
  - `document-expectations.md` loses its `greenfield: true` mode;
  - every state write goes through `--kb`, and every question through `--ask --kb`.
- The REVIEW to FINISH references are task-123. Their files are renamed here, and only their contents
  change there. This task's criteria cover only the files it writes; every other moved reference has the
  content owner the findings' table names (task-123 or task-129) (G7).
- `SKILL.md`'s aggregate-step note "then a single `git commit` + `git push`" goes: the build commits once,
  at FINISH, through `kb-commit.sh`, and pushes nothing (F004 Flows step 6).
- Delete `canonical/aid/templates/discovery-state-template.md`, whose last user this was.
- **Lists and counts that follow a moved or new skill**, in this same task:
  - its `canonical/aid/rules.md` § Skill guide line, with the spec's text (`##### 5. Components`);
  - its `description:` in the spec's what/when shape (the four KB skills are not SG-04-exempt);
  - the old name's rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`;
  - the old name's `skill:` row in `tests/conversation/deferred.tsv`, which becomes a `skill:` row for
    the new name until task-135's samples land (DT-01, SS-09);
  - the site skill lists and their `__tests__`;
  - the counted phrases, if the skill count changes (Q134 D5).
- Suites to update in this same task: the suites that follow the text into the new skill
  (`test-kb-review-surface.sh`, `test-state-review-surface.sh`, `test-doc-set-*.sh`,
  `test-discovery-doc-ownership.sh`, `test-connector-set-unset-lifecycle.sh`, `test-cutover-no-dangling.sh`,
  and any suite the findings' K1, K2 or K7 assigns here).
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md` assigns to `task-116`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-116: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-116`.
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
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `test -d canonical/skills/aid-discover` fails, and `canonical/skills/aid-kb-build/` holds `SKILL.md` of at most 150 lines and `references/start.md`, `elicit.md` and `generate.md`.
- [ ] Over the files this task writes (`SKILL.md`, `references/start.md`, `elicit.md`, `generate.md` and `document-expectations.md`), `git grep -nE 'STATE\.md|discovery-state-template|--reset|--grade|knowledge\.(source|last_update)|git (commit|push)'` finds nothing, and every state write in them names `--kb` (G3, G7).
- [ ] SG-02, SG-04, DT-01, SS-09 and the suites above pass where the test step puts them.
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] No page under `site/src/content/docs/skills/` and no `site/src/data/skill-flows/*.flow.json` is left for a skill folder this task deletes or renames away, and `npm run gen:skills` reports no orphan (G18).
- [ ] Over `site/scripts/` outside `__tests__`, no source names a skill this task retires, and none names a renamed skill by its old name (G19).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
