# task-337: KB test landscape for one skill per need, the regenerated index and the view

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 337 --field State.

**Type:** DOCUMENT

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-20, AC-31

**Depends on:** task-324, task-330, task-331, task-332, task-334, task-335, task-336

**Scope:**
- `.aid/knowledge/test-landscape.md`: `test-actions.sh` group B; the retired suites (the engine contract, the builder
  invariants, the catalog parity, the six family scaffolds) go; the rewritten and re-pointed suites; the migration
  cases; the doorway and `alias_of` counts go.
- Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync changes no
  KB document.
- Name no work and no work folder.
- **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
  delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
  itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
  it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
  it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
  text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
  commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
  them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
  except the resync itself.
  1. **The run pauses** at the delivery-012 MILESTONE approval question, written `Pending` with `--ask`; the main
     conversation ends the session there.
  2. **Resync session:** the resync (`delivery-012: resync`), committed alone. Its `aid update` removes the retired
     skills, the engine, the catalog, the scaffolding and `feedback-artifacts/` through the install manifest, and its
     format-6 step runs the doorway rows (no work of this repository is a doorway work). Then the session ends.
  3. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
     `--plan` when stale; `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated
     page (`reference/settings.md` from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB
     is not changed by this resync.
  4. **The gate:** the stanza's criteria, the samples (the plain form of `009-01`, `009-02` and `009-07`; `009-06`,
     `009-08`, `009-09`, `009-10`, `009-14`, `009-16`; again `001-01`, `001-07`, `003-02`, `008-14`; each 3 of 3) and
     G0 on the head, G0's lane item carried by the milestone push. Then **the hold** (PLAN.md "How deliveries 010-014
     are built", The hold): with `AID_WORK_DIR` exported for this work, the main conversation runs
     `write-control-signal.sh --task-id NNN --action stop` for every wave-1 task of delivery-013 (the wave-1 tasks that `derive-waves.sh --from-tasks <work-dir> --delivery NNN` prints from the task files; PLAN.md's `wave-map` blocks are re-rendered into the checklist from delivery-008's resync on, so they are not the source). Then `/aid-execute` resumes and asks the open approval first; a yes is recorded with
     `--answer --commit <head>`, and the push question follows. NEXT's routing then reaches delivery-013's first
     BUILD, whose step entry finds the task's `.stop` file and pauses the run before any dispatch (Feature 007 § 2,
     Control signals).
  5. **Research for delivery-013 (Q139)**, after this delivery's milestone yes is recorded. `aid-researcher` writes
     `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` from the brief below, in a clean
     context. `aid-reviewer` grades it in a clean context with `grade.sh` against `minimum_grade`, against the brief's
     criteria; fix rounds follow as for a task, and the same failure after three rounds goes to the maintainer. The
     file is then committed alone (a work-folder file, not resync-relevant). Delivery-013's run starts only after
     that commit: the main conversation then runs `write-control-signal.sh --task-id NNN --action resume` for each
     task the hold stopped (step 4), and resumes `/aid-execute`. A gate failure or a change asked at the approval
     keeps the stops in place: the corrections are built in this delivery, and the research waits for the yes.
     **Brief:**
     - Create `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md`. The step touches nothing else.
     - Re-run these searches at the head the gate session leaves, and record that commit in the file
       (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Domain readiness, and `##### 8. Migration`):
       - **C1** the identity search of REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Domain readiness, item 7, verbatim:
         `git grep -lIiE 'building software|software-development lifecycle|AI Integrated Software Development|methodology for software development|kind of digital work' -- . ':!.aid/works' ':!site/src/data' ':!.aid/knowledge/kb.html' ':!.aid/runtime' ':!tests' ':!**/tests/**' ':!**/__tests__/**'`; each hit with its owner (task-343 for the files outside the KB, `docs/` and the site pages;
         task-350 for the KB; delivery-014 for `docs/` and `site/src/content/docs/`);
       - **C2** every mention of `aid-config` as a name: `git grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)' -- . ':!.aid/works'`,
         each hit classed by REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration` (the rename in approved features; Suites, Unchanged; Dashboard):
         renamed here (the site generator sources under `site/scripts/`, G19, with task-339; the skill, the settings rows, `settings.yml`, `bin/aid`, `bin/aid.ps1`, the dashboard comments,
         sample `002-02`'s `skills:` line, every kept file under `canonical/`, `.claude/skills/generate-profile/` and
         `scripts/checks/`), kept as written (the approved specs; the synthetic old-style settings fixtures in
         `test-aid-cli-parity.sh`, `test_reader.py`, `test_server_node.mjs`, `test_task012_consuming_round_trips.py`), or
         delivery-014's (`docs/`, `site/src/content/docs/`, `README.md`, `examples/`);
       - **C3** every reader of `kind-catalog.yml` and of `check-intent.md` § The merged catalog, and every suite that
         asserts the catalog's fields or the merged catalog's one-source wording;
       - **C4** how `aid update` and `aid remove` treat a user folder under `.aid/` (`bin/aid`, `bin/aid.ps1`, the
         install manifest), with the `.aid/design/` cases of `test-shared-prune.sh` and `test-shared-remove.sh`;
       - **C5** the AS-10 terms (`code`, `codebase`, `repository`, `commit`, `branch`, `pull request`, whole words, any case) over the action layer: the action skills'
         `description:` lines, their skill-guide lines, the catalog's `actions` entries and `action-start.md`;
       - **C6** the gate calls and catalog reads of `aid-review`, `aid-research` and `aid-report`, and every suite that
         asserts their `SKILL.md`;
       - **C7** the SG-04 description exempt list, `tests/conversation/deferred.tsv` and the SS-09 coverage of
         `aid-config`.
     - **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
       test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
       `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
       site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
       the task that changes that file, which re-points the test in the same task.
     - **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
       `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
       renames it, which fixes the entry in the same task (AD14).
     - **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
       skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
     - Give each hit exactly one owner:
       - a task of delivery-013 (task-339 to task-352; see the task files under
         `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
       - delivery-014, for a hit under `docs/`, `site/src/content/docs/` (outside the generated pages), `README.md`
         (outside its identity line) or `examples/`;
       - "installed copy (resync)";
       - "history, left as is";
       - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
         site pages generated from `.aid/settings.yml` (`reference/settings.md`), which this resync changes when the
         "Managed by" line reaches the installed settings (G8).
     - In a delta section, list each suite assigned to two independent tasks, with the order to run them.
     - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
       `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
     - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
       text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
       that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
       through the builder").
     **Criteria:**
     - [ ] Each of C1-C7 shows its exact command, and re-running it at the base named in the file reproduces its hits.
     - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
     - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-337`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-337.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-337`.
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
- [ ] `test-landscape.md` names group B and no retired suite.
- [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
