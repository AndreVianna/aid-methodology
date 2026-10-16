# Detail proposal -- delivery-009: Building tested, verified and simplified, one task at a time (Feature 007)

> **Superseded by the task files.** After the light-review fixes (G12, G13), the dependencies, scopes and
> criteria in this proposal no longer match the task files. The task files under `deliveries/delivery-009/tasks/` are
> the source of truth. Step 5 builds PLAN.md's Execution Graph from their `**Depends on:**` lines, never from this
> proposal.

This is `aid-detail` FIRST-RUN for **delivery-009**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-009/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-008's task-218.
- **General rules.** G1-G11 apply from the start: every task, TEST included, carries the findings bullet (G9);
  no criterion runs a copy-reading suite live (G10); a suite asserting a file a task rewrites is updated in that
  task, and a "nowhere" criterion allows what a still-required check needs (G11).

**Inputs read:**
- the delivery-009 stanza of `PLAN.md`, Common Gate G0 (the tracking proof: from delivery-008 on, a `reviews`
  entry per task; delivery-009's state file is the work `STATE.yml`), "Testing before the resync", "Toolchain and
  Branching" (steps 3 and 5 for delivery-009, the switch questions, Q123, Q124, Q132);
- `REQUIREMENTS.md` § 11 Feature 007 (all eight subsections).

**Measured at base `1e513e05`** (task-219 re-measures on the tree deliveries 001-008 leave):
- `aid-execute` has `SKILL.md`, `task-type-rules.md`, `reviewer-brief.md` and the seven references this
  delivery deletes.
- `test-downstream-worktree-entry.sh` asserts `aid-execute`'s worktree entry (G0-G4, Group 7).
- `test-disjoint-merge.sh` tests the per-unit state hierarchy's merge-back.

**How this delivery is built.** After delivery-008's resync this work is on the single layout: every task's
state is in the work `STATE.yml` (`tasks_lifecycle`), written by the installed Feature 006 writer, which re-renders
`PLAN.md` at each write. Each task's grade is also recorded with `--review` (G0). The canonical writer changes of
this delivery (221, 222, 234) reach the installed writer only at the resync, so `--lifecycle`, `--gate-field` and
`--field Review` keep working for this delivery's own tracking. The writer's retired modes are refused only in
task-234, after task-233 removes their last callers (G7, G11).

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-219 | Delivery-009 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-220 | Work-state template: the building part | IMPLEMENT | 2 | 2 | task-219 |
| task-221 | Writer: the building fields of tasks and deliveries, and the wave-stop fields | IMPLEMENT | 2 | 3 | task-220 |
| task-222 | Writer: --full-suite, --feedback-add, --feedback and --plan-sync --cancel | IMPLEMENT | 2 | 4 | task-221 |
| task-223 | simplify-guard.sh | IMPLEMENT | 2 | 2 | task-219 |
| task-224 | derive-waves.sh --from-tasks --delivery | IMPLEMENT | 2 | 2 | task-219 |
| task-225 | complexity-score.sh and compute-block-radius.sh read the derived graph | IMPLEMENT | 3 | 3 | task-224 |
| task-226 | aid-execute references: START and old works | IMPLEMENT | 3 | 5 | task-221, task-222, task-224 |
| task-227 | aid-execute references: BUILD, TEST, the FIX contract and the type rules | IMPLEMENT | 3 | 4 | task-221 |
| task-228 | aid-execute references: VERIFY, SIMPLIFY and the four-mode reviewer brief | IMPLEMENT | 3 | 4 | task-221, task-223 |
| task-229 | aid-execute references: NEXT's routing rule and real blockers | IMPLEMENT | 3 | 5 | task-221, task-222 |
| task-230 | aid-execute references: DELIVERY, FINAL, MILESTONE and FINISH | IMPLEMENT | 3 | 5 | task-222, task-225 |
| task-231 | Approvals and contracts: skill-steps.md, the shortcut engine's confirmation, the four ledgers | IMPLEMENT | 3 | 2 | task-219 |
| task-232 | aid-plan revise.md: a given-up task and where corrections go | IMPLEMENT | 3 | 5 | task-222 |
| task-233 | aid-execute SKILL.md rewritten, and its seven old references deleted | IMPLEMENT | 3 | 6 | task-220, task-226, task-227, task-228, task-229, task-230 |
| task-234 | Writer: the derived delivery state, and the retired modes refused, with the fork | IMPLEMENT | 4 | 7 | task-221, task-231, task-233 |
| task-235 | One worktree, one branch: the consumer lists and NM-04 | IMPLEMENT | 3 | 7 | task-233 |
| task-236 | rules.md's tracking line, aid-developer's blocker report, read-setting.sh's example | IMPLEMENT | 3 | 5 | task-227 |
| task-237 | Re-point every kept file that names a retired building artifact | IMPLEMENT | 4 | 8 | task-233, task-234, task-235 |
| task-238 | Format 6: the building part of the work-state step, in bash and PowerShell | IMPLEMENT | 4 | 3 | task-220 |
| task-239 | Dashboard readers and server: the building fields | IMPLEMENT | 4 | 3 | task-220 |
| task-240 | Dashboard page: the building card lines | IMPLEMENT | 4 | 4 | task-239 |
| task-241 | Writer unit cases: building fields, derived delivery states, refused modes, parity | TEST | 5 | 8 | task-222, task-234 |
| task-242 | test-simplify-guard.sh | TEST | 5 | 3 | task-223 |
| task-243 | Unit cases: derive-waves --delivery, complexity-score and compute-block-radius | TEST | 5 | 4 | task-224, task-225 |
| task-244 | Unit cases: test-work-state-migration.sh, the building part | TEST | 5 | 4 | task-238 |
| task-245 | Dashboard cases: a task being verified, a milestone, a blocker, a finished full suite | TEST | 5 | 5 | task-239, task-240 |
| task-246 | test-execute.sh (EX-01 to EX-08) | TEST | 5 | 9 | task-220, task-223, task-231, task-233, task-234, task-235, task-237 |
| task-247 | Samples 007-01 to 007-06 (run at this gate) | TEST | 5 | 8 | task-233, task-234, task-235 |
| task-248 | Samples 007-07 to 007-12 (run at this gate) | TEST | 5 | 9 | task-232, task-238, task-247 |
| task-249 | Sample 007-13 (deferred) and the deferred rows that now run | TEST | 5 | 10 | task-248 |
| task-250 | test-execute.sh and test-simplify-guard.sh in the CI lane | CONFIGURE | 5 | 10 | task-242, task-246 |
| task-251 | KB decisions, schemas, glossary, standards, tech debt and backlog for Building | DOCUMENT | 5 | 8 | task-220, task-234, task-236 |
| task-252 | KB architecture, contracts and quality documents for Building | DOCUMENT | 5 | 9 | task-233, task-235, task-237 |
| task-253 | KB test landscape for the building suites, the regenerated index and the view | DOCUMENT | 5 | 11 | task-241, task-243, task-244, task-245, task-249, task-250, task-251, task-252 |

That is 35 tasks. The resync follows task-253; then the gate and the switch (§ 4).

---

## 2. Rules every task carries

The blocks of delivery-008, with G1-G11. Same-file edits in one wave are ordered by an edge: the writer (221,
then 222, then 234), `aid-execute` (226-230, then 233), the dashboard (239, then 240), `deferred.tsv` (249 only),
`test-writeback-state.sh` (221, 222, 234, then 241).

---

## 3. Tasks

`Source` reads `feature-007-building -> delivery-009 -> AC-...`.

### task-219: Delivery-009 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-26, AC-33, AC-34.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and layout` and `##### 7. Migration`):
    - **X1** the spec's stated suite search, verbatim: `grep -rlE
      'state-execute\.md|state-execute-drilldown\.md|state-review\.md|state-fix\.md|state-re-run\.md|state-delivery-gate\.md|reviewer-guide\.md|delivery-issues\.md'
      tests dashboard`, keeping the hits on `aid-execute`'s files, checked against the spec's hit list;
    - **X2** the re-pointing patterns over every kept file under `canonical/` and `dashboard/home.html`: a deleted
      reference, `delivery-NNN-issues.md`, `IMPEDIMENT-task-`, `--append-issue`, `--findings`, `quick_check`, a
      per-delivery branch (`-delivery-`), the per-task worktrees, "merge to main", `max_parallel_tasks`;
    - **X3** every caller of the writer modes this delivery retires (`--findings`, `--append-issue`,
      `--gate-field`, `--block`, `--lifecycle`, `--field Review`), so the task that removes the last caller also
      makes the writer refuse them;
    - **X4** the readers of `derive-waves.sh --from-tasks` output, `complexity-score.sh` and
      `compute-block-radius.sh`, and of the quick-check consult factor;
    - **X5** the consumer lists of `worktree-lifecycle.md` and `downstream-worktree-entry.md`, NM-04's
      exemption, and every branch or worktree creation under `canonical/skills/aid-execute/` and
      `canonical/aid/scripts/execute/` (EX-03's patterns);
    - **X6** the dashboard's task and delivery cells, the quick-check display, and the work card lines, with
      their tests and fixtures;
    - **X7** the rows of `tests/conversation/deferred.tsv`, the SG-04 exempt list and
      `tests/canonical/skill-steps-exempt.tsv` that name `aid-execute` or a sample this delivery runs;
    - **X8** the Q106 suite map for every file on the edit list, including the site's skill lists.
  - **Old-to-new reference map.** One row per file under `canonical/skills/aid-execute/references/` at the base,
    naming the new reference (or references) that takes its content and the task that writes it: for example
    `state-fix.md`'s FIX contract (F1-F7) to `fix.md`, and `reviewer-guide.md`'s type review focus to the brief.
  - Give each hit exactly one owner:
    - a task of delivery-009 (task-220 to task-253; see the task files under
      `.aid/works/work-003-full-aid-restructure/deliveries/delivery-009/tasks/`);
    - Feature 008 (delivery-010) for the pull-request calls and the push sites;
    - Feature 009 (delivery-012) for the shortcut engine itself and `feedback-artifacts/IMPEDIMENT.md`;
    - "installed copy (resync)";
    - "history, left as is".
  - In a delta section, list each suite assigned to two independent tasks, with the order to run them.
  - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
  - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
    text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
    that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
    through the builder").
- **Acceptance criteria:**
  - [ ] Each of X1-X8 shows its exact command, and re-running it at the base named in the file reproduces its hits; X1's kept hits match the spec's list, or the delta names each difference.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0. The reference map has one row per file under `aid-execute/references/` at the base.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-220: Work-state template: the building part [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-219.
- **Source:** AC-26, AC-33.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml` (REQUIREMENTS.md § 11 Feature 007 `##### 3. Work state`), block style, three levels at
    most, each key with its `[W]` comment:
    - new `wave_stops` (`choice`, `planned`), `full_suite` (`command`, `baseline`, `baseline_commit`, `result`,
      `commit`) and `feedback: []`;
    - `deliveries.<id>`: `state` (derived, shown, never read for routing), `updated`, `tier`, `base`, `verify`,
      `simplify`, `reverify`, `tests`, `commit`, `issue_list`, `block_reason`;
    - `tasks_lifecycle.<id>`: `state`, `base`, `verify`, `simplify`, `reverify`, `tests`, `commit`, `elapsed`,
      `notes`, `display_name`;
    - gone: `review`, `quick_check`, `gate_tier`, `gate_grade`, `gate_timestamp`, `block_artifact`.
  - Both dashboard readers accept the new keys with no warning (schema only; showing them is task-239 and
    task-240), so SS-08 holds.
  - Suites to update in this same task: `test-work-state-template.sh`, `test-skill-steps.sh` SS-08 where it reads
    the template, and any suite the findings' X8 assigns to the template.
- **Acceptance criteria:**
  - [ ] The template has `wave_stops`, `full_suite`, `feedback` and the building fields of `deliveries` and `tasks_lifecycle`, each with its `[W]` comment, and no `gate_tier`, `gate_grade`, `gate_timestamp`, `quick_check` or task-level `review:` (EX-07).
  - [ ] It parses through both dashboard readers with no warning; `test-work-state-template.sh` and SS-08 pass where the test step puts them.

### task-221: Writer: the building fields of tasks and deliveries, and the wave-stop fields [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-220.
- **Source:** AC-26, AC-32, AC-33.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 3. Work state`, Writer), additive only:
    - `--task-id NNN --field F --value V`: F is `State`, `Base`, `Verify`, `Simplify`, `Reverify`, `Tests`,
      `Commit`, `Elapsed`, `Notes` or `Name`; `Verify` and `Reverify` take a grade or `--`; `Simplify` takes
      `changed`, `no change`, `undone` or `--`; anything else exits 4;
    - `--delivery-id NNN --field F --value V` (new): `Tier` (`Small`, `Medium`, `Large`), `Base`, `Verify`,
      `Simplify`, `Reverify`, `Tests`, `Commit`, `Issue List`; same validation;
    - `--pipeline --field "Wave Stops"` (`none`, `review`, `review-and-update`) and `"Planned Wave Stops"` (`--`, or
      comma-separated `delivery-NNN/wave-N` items); anything else exits 4.
  - The modes this delivery retires (`--field Review`, `--lifecycle`, `--findings`, `--append-issue`,
    `--gate-field`, `--block`) keep working until task-234, which removes them with their last callers. The
    derived delivery state is also task-234's.
  - `dashboard/scripts/writeback-state.sh` (the fork) follows in task-234.
  - The unit cases are task-241.
  - Suites to update in this same task: the existing `test-writeback-state.sh` assertions, and any suite the
    findings' X3 or X8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work, each new field writes its key, `--task-id 001 --field Simplify --value maybe` exits 4 with the file byte-identical, and `--pipeline --field "Planned Wave Stops" --value 'delivery-001/wave-1, wave-2'` exits 4.
  - [ ] `test-writeback-state.sh` passes live, with the plan re-rendered after each task write as Feature 006 left it.

### task-222: Writer: --full-suite, --feedback-add, --feedback and --plan-sync --cancel [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-221.
- **Source:** AC-26, AC-32.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 3. Work state`, Writer), additive only:
    - `--full-suite --field F --value V`: `Command`, `Baseline`, `Baseline Commit`, `Result`, `Commit`;
    - `--feedback-add --kind K --ref R --summary T`: appends an `Open` entry (`id` `F<n>`, `at`, `kind`, `ref`,
      `summary`, `state`, `link`) and prints its id; `--feedback --id F<n> --state S [--link L]` updates it; the
      kinds and states are the spec's closed lists;
    - `--plan-sync --cancel task-NNN[,task-NNN]`: sets `Canceled` on each named task that is `Failed`, `Blocked` or
      `Pending` (any other state exits 4 and nothing is written); every `--plan-sync` run sets `Pending` on a
      `Blocked` task none of whose dependencies is `Failed` or `Canceled`; task files are kept.
  - The unit cases are task-241.
  - Suites to update in this same task: the existing `test-writeback-state.sh` assertions on `--plan-sync`, and
    any suite the findings' X8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work, `--feedback-add --kind bug --ref r1 --summary s` prints `F1` and a second prints `F2`; `--feedback --id F1 --state Task --link task-009` updates F1 only; a bad kind exits 4.
  - [ ] `--plan-sync --cancel task-002` on a `Done` task exits 4 with both files byte-identical; on a `Failed` task it writes `Canceled`. `test-writeback-state.sh` passes live.

### task-223: simplify-guard.sh [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-219.
- **Source:** AC-33.
- **Scope:**
  - Create `canonical/aid/scripts/execute/simplify-guard.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 4. Components`, `simplify-guard.sh`):
    `simplify-guard.sh --tests <list-file> (--before <commit> | --snapshot <dir>)`; with git, `--before` compares
    `<commit>` with `HEAD`; without git, `--snapshot` compares the working files with the simplify round's
    snapshot. Exit 0 when no file of the list, nor any new file in the list's folders, changed; 1 otherwise,
    naming each; 2 bad argument; 3 only when neither can be used. Bash only.
  - The unit suite is task-242.
- **Acceptance criteria:**
  - [ ] In a scratch repository, an untouched list exits 0, and a changed, a removed and an added test file each exit 1 naming the file, with `--before`; a scratch folder without git gives the same results with `--snapshot`, and exits 3 with neither.
  - [ ] `bash -n` passes, and the script names no Python or Node.

### task-224: derive-waves.sh --from-tasks --delivery [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-219.
- **Source:** AC-32.
- **Scope:**
  - `canonical/aid/scripts/execute/derive-waves.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 4. Components`): `--from-tasks <work-dir> --delivery
    NNN` prints the dependency table and wave block of one delivery, the same sort as `--plan`, a dependency on an
    earlier delivery's task counted as met; without `--delivery` the output is unchanged.
  - The unit cases are task-243.
  - Suites to update in this same task: any suite the findings' X4 assigns here.
- **Acceptance criteria:**
  - [ ] On this work's own task files, `--from-tasks <work-dir>` output is byte-identical before and after the change, and `--from-tasks <work-dir> --delivery 009` prints only delivery-009's table and waves.
  - [ ] A scratch work whose delivery-002 task depends on a delivery-001 task places it in delivery-002's wave 1.

### task-225: complexity-score.sh and compute-block-radius.sh read the derived graph [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-224.
- **Source:** AC-32, AC-34.
- **Scope:**
  - `canonical/aid/scripts/execute/complexity-score.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and layout`): reads the delivery's
    graph from `derive-waves.sh --from-tasks --delivery` output; the quick-check consult factor and
    `--quick-check-state` go; header re-pointed.
  - `canonical/aid/scripts/execute/compute-block-radius.sh`: without `--delivery-id`, a graph with several
    `### delivery-NNN` sections (the unscoped `--from-tasks` output) is read as one graph across deliveries
    instead of exiting 5; `--delivery-id` keeps today's scoped mode; header re-pointed.
  - The unit cases are task-243.
  - Suites to update in this same task: the existing `test-complexity-score.sh`, `test-compute-block-radius.sh`
    (T17, the pool's degradation notice, is retired with task-233's deletion of `state-execute.md`) and
    `test-executor-graph-flat-plan.sh` assertions, rewritten so both scripts read `--from-tasks` output, scoped
    and unscoped, and any suite the findings' X4 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch two-delivery work, `compute-block-radius.sh` without `--delivery-id` blocks a dependent in the later delivery, and with it gives today's scoped result; `complexity-score.sh` names no `quick-check`.
  - [ ] `test-complexity-score.sh`, `test-compute-block-radius.sh` and `test-executor-graph-flat-plan.sh` pass live.

### task-226: aid-execute references: START and old works [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-221, task-222, task-224.
- **Source:** AC-26, AC-32, AC-34, AC-37.
- **Scope:**
  - Create in `canonical/skills/aid-execute/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 2. Flow`, step 1, and `##### 7. Migration`, At START for
    an old work):
    - `start.md`: what START reads (`--plan-sync` first); the confirmation before building (already recorded, or
      asked with its `covers` by depth; a change asked here as a `CALL` to `/aid-specify` or `/aid-plan` REVISE;
      *not now* pauses); the wave question, once, only for a delivery with more than one wave, writing `Wave
      Stops` and `Planned Wave Stops` once; the full-suite baseline with its command resolved once and recorded
      in `full_suite.command` (Q132), or `baseline: not taken` for an old work; what is on disk is kept; a
      correction call skips the confirmation and the wave question;
    - `old-work.md`: per-delivery branches moved forward with `git switch` and `git reset --keep` when they
      descend, a real blocker when one diverges, the old branches left; leftover task worktrees removed with
      `git worktree remove` (never forced) when clean, a real blocker when not.
  - `SKILL.md` and the old references stay until task-233 points the step table here.
- **Acceptance criteria:**
  - [ ] Both files exist, each at most 120 lines; `start.md` names `confirmation before building`, `Wave Stops`, `Planned Wave Stops`, the baseline and `full_suite.command` (EX-02's `start.md` clauses).
  - [ ] `old-work.md` is the only new file naming a `-delivery-` branch, and names no `--force` (EX-03's clause). The site `npm test` passes after regeneration.

### task-227: aid-execute references: BUILD, TEST, the FIX contract and the type rules [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-221.
- **Source:** AC-26, AC-34.
- **Scope:**
  - Create in `canonical/skills/aid-execute/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 2. Flow`, steps 2-3):
    - `build.md`: the next task by wave and id; `In Progress` written at entry and the task's `base`; the executor
      by type, clean context, tiered, with the dispatch protocol, getting the task file, the slice, `known-issues.md`,
      the KB documents and its type's rules; one commit per round, staging only the paths that round changed (never
      `.aid/.temp/` or `.aid/works/`; KB paths only through `kb-commit.sh`); without git, the snapshots; what the
      executor finds (`blocker.md`, `Assumed`, the `CALL`s to `/aid-specify`, `/aid-plan` and `/aid-kb-update`);
    - `test.md`: the main conversation runs the task's tests itself; a task with no code runs the checks its
      criteria name, or records `not applicable` with the reason; pass writes `tests` and the test list for
      SIMPLIFY; fail goes back to BUILD; the same failure after three fix rounds is a real blocker;
    - `fix.md`: the FIX contract of `state-fix.md` (F1-F7: a finding is a class, its sweep trailers, the oracle
      run), unchanged in substance.
  - `references/task-type-rules.md`: each type says which tests it writes and runs, and what counts as its tests
    when it writes no code.
  - Suites to update in this same task: any suite the findings' X1 or X8 assigns to these files.
- **Acceptance criteria:**
  - [ ] The three files exist, each at most 120 lines; `build.md` writes `In Progress` at entry and names no `git worktree add`, `checkout -b`, `switch -c` or `run_in_background` (EX-03 over this task's files).
  - [ ] `fix.md` holds F1 to F7; `task-type-rules.md` names, for RESEARCH, DESIGN and DOCUMENT, what counts as their tests. The site `npm test` passes after regeneration.

### task-228: aid-execute references: VERIFY, SIMPLIFY and the four-mode reviewer brief [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-221, task-223.
- **Source:** AC-33.
- **Scope:**
  - Create in `canonical/skills/aid-execute/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 2. Flow`, steps 4-6):
    - `verify.md`: `In Review` written before the reviewer is dispatched; one graded pass at a tier no lower than
      the executor's, over `base..HEAD` (the work folder excluded); ledger `<work>-task-NNN.md`; `grade.sh` against
      `minimum_grade`, recorded with `--review` and in `verify`; after three rounds below the bar, fix, accept
      (`Accepted`) or keep reviewing; its re-verify mode, scoped to the simplify commit, with the undo by
      `git reset --keep <the verified commit>` (or the snapshot) and `simplify: undone`, and no second round;
    - `simplify.md`: once per task, after VERIFY passes; the reviewer lists, the executor applies without touching
      a test file, in one commit; the tests run again and `simplify-guard.sh` checks the test list; a failure undoes
      it at once.
  - Rewrite `references/reviewer-brief.md` with `### What to report` (FR-21, SS-13) and four modes -- task,
    delivery, simplify, re-verify -- carrying `reviewer-guide.md`'s type review focus.
  - Suites to update in this same task: any suite the findings' X1 or X8 assigns to these files.
- **Acceptance criteria:**
  - [ ] `simplify.md` names `simplify-guard.sh`, once per task, and `undone`; `verify.md` names `grade.sh`, `--review`, `git reset --keep` and the three choices with `Accepted` (EX-04).
  - [ ] `reviewer-brief.md` has `### What to report` and the four modes, and SS-13 passes where the test step puts it. The site `npm test` passes after regeneration.

### task-229: aid-execute references: NEXT's routing rule and real blockers [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-221, task-222.
- **Source:** AC-32, AC-33.
- **Scope:**
  - Create in `canonical/skills/aid-execute/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 2. Flow`, step 7, and Real blockers):
    - `next.md`: `Done` written only now, with `commit`, the ledgers deleted; the KB check
      (`kb-freshness-check.sh`, one `CALL` to `/aid-kb-update` with a KB, one line without); the one routing rule --
      a result valid only for the commit it records (`merge-base --is-ancestor`; snapshot order without git), its
      inputs and nothing else (never a stored delivery state), open and closed, and the five first-match rules
      with the `covers` forms `wave delivery-NNN/wave-N`, `delivery delivery-NNN` and `whole build`; corrections
      as ordinary tasks;
    - `blocker.md`: the real blockers and their one question (`category: Blocker`, importance high); a revision's
      approval asked at once and recorded as its `Approval`; a question that does not block recorded `Assumed`; a
      task that keeps failing: *retry*, or *give it up* (cancel, or replan), writing `Failed`, the dependents
      `Blocked` by `compute-block-radius.sh` over the whole graph, the step saved as NEXT, and a `CALL` to
      `/aid-plan` REVISE.
  - Suites to update in this same task: any suite the findings' X8 assigns to these files.
- **Acceptance criteria:**
  - [ ] `next.md` names `verify`, `full_suite`, `commit`, `covers`, `merge-base --is-ancestor`, each `covers` form, `kb-freshness-check.sh` and `aid-kb-update`, and its wave rule fires only while the current delivery has no `verify` and no `full_suite` result is recorded, for a planned wave with no answered entry (EX-02, EX-08).
  - [ ] `blocker.md` names `Blocker`, `Assumed`, the give-up choices and `aid-plan`; neither file reads or writes `--lifecycle` or `deliveries.<id>.state`. The site `npm test` passes after regeneration.

### task-230: aid-execute references: DELIVERY, FINAL, MILESTONE and FINISH [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-222, task-225.
- **Source:** AC-26, AC-32, AC-33.
- **Scope:**
  - Create in `canonical/skills/aid-execute/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 2. Flow`, steps 8-11):
    - `delivery.md`: verify over the delivery's diff (`--first-parent --no-merges`, plus only a conflict merge's
      resolution with `--remerge-diff`), at the tier `complexity-score.sh` gives, every task's tests together,
      accepted rows to `issue_list`; one simplify across the delivery with the guard over every task's list; a
      scoped re-verify only when it changed, undone on failure; recorded in the delivery's fields;
    - `final.md`: the recorded `full_suite.command` (resolved and recorded first when missing, Q132) on the head;
      a failure absent from the baseline fixed in scoped rounds, one in the baseline reported, every failure shown
      with `baseline: not taken`; `full_suite.result` and `commit`; the backlog and roadmap call;
    - `milestone.md`: collect (a read-only `CALL` to `/aid-monitor-pipeline` when a pull request exists);
      corrections through `/aid-plan` REVISE; the approval in chunks, written `Pending` with `--ask` before it is
      shown, with `commit` and `covers`, coinciding approvals as one; the KB call on confirmation; the push question
      where a milestone may push;
    - `finish.md`: `user_approved: 'yes'` and `PASS` with `--phase CI` -- to the close minimum run by
      `/aid-orchestrate` until Feature 008; `HALT` in a correction call.
  - Suites to update in this same task: any suite the findings' X8 assigns to these files.
- **Acceptance criteria:**
  - [ ] The four files exist, each at most 120 lines; `final.md` and `start.md` name `full_suite.command`; `milestone.md` names `aid-monitor-pipeline`, `aid-plan`, `covers` and `commit`; `finish.md` names `--phase CI` (EX-02).
  - [ ] `delivery.md` names `--remerge-diff` and `complexity-score.sh`. The site `npm test` passes after regeneration.

### task-231: Approvals and contracts: skill-steps.md, the shortcut engine's confirmation, the four ledgers [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-219.
- **Source:** AC-10, AC-32.
- **Scope:**
  - `canonical/aid/templates/skill-steps.md` § When approvals happen (REQUIREMENTS.md § 11 Feature 007 `##### 4. Components`, Approvals): the
    corrections row (after the whole build, before they are pushed) and the Building rule under the table.
  - `canonical/aid/templates/shortcut-engine.md` § State: APPROVAL-HALT: its yes is recorded `category: Approval`,
    `covers: REQUIREMENTS.md; PLAN.md; confirmation before building`; its lines naming `state-delivery-gate.md`,
    `delivery_gate` or `delivery_state` name `deliveries`. The engine itself stays until Feature 009.
  - `canonical/aid/templates/reviewer-ledger-schema.md`: the `/aid-execute task-NNN` row becomes the four
    `/aid-execute` ledgers (`<work>-task-NNN.md`, `-simplify`, `-reverify`, `<work>-delivery-NNN.md`).
  - Suites to update in this same task: `test-shortcut-engine-contract.sh` and any shortcut-engine suite that
    asserts APPROVAL-HALT, and any suite the findings' X2 or X8 assigns here.
- **Acceptance criteria:**
  - [ ] `skill-steps.md` has the corrections row and the Building rule; `shortcut-engine.md` § State: APPROVAL-HALT names `confirmation before building`; the ledger schema names the four `/aid-execute` ledgers (EX-06).
  - [ ] The engine suites pass where the test step puts them, and SR-01 passes.

### task-232: aid-plan revise.md: a given-up task and where corrections go [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-222.
- **Source:** AC-32.
- **Scope:**
  - `canonical/skills/aid-plan/references/revise.md` (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and layout` and `##### 2. Flow`, Real
    blockers and Corrections are ordinary tasks):
    - a given-up task: cancel it and its dependents, or replan them; FINISH runs `--plan-sync --cancel`; a rewired
      dependent goes back to `Pending`; cancelling every task of a delivery is a delivery change, approved at
      once;
    - a correction goes to the delivery the milestone covers (the last one when it covers several; in a
      correction call or a whole-build-only milestone, the last delivery with a `Done` task) and declares no
      dependency on a `Done` task.
  - Suites to update in this same task: any suite the findings' X8 assigns to `revise.md`.
- **Acceptance criteria:**
  - [ ] `revise.md` names `--plan-sync --cancel`, both give-up choices and the correction's delivery rule, and stays within 120 lines.
  - [ ] `test-plan.sh` passes where the test step puts it, and the site `npm test` passes after regeneration.

### task-233: aid-execute SKILL.md rewritten, and its seven old references deleted [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-220, task-226, task-227, task-228, task-229, task-230.
- **Source:** AC-26, AC-32, AC-33, AC-34.
- **Scope:**
  - Rewrite `canonical/skills/aid-execute/SKILL.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and layout` and
    `##### 2. Flow`): the step table START, BUILD, TEST, VERIFY, SIMPLIFY, REVERIFY, NEXT, DELIVERY, FINAL,
    MILESTONE and FINISH pointing at the new references; `skill-steps.md` and `question-protocol.md` cited; the
    spec's `description:` and `argument-hint`; the plan-mode check as one line; the control signals. Gone: Check 1's
    work listing and worktree entry, the layout detection and full/flat branches, Check 5's per-delivery branches,
    the state map and banners, `## Delivery Lifecycle` with "merge to main", the pool, `## Impediments`,
    `## Ticket Suggestion`, the quality checklist.
  - Delete `references/state-execute.md`, `state-execute-drilldown.md`, `state-review.md`, `state-fix.md`,
    `state-re-run.md`, `state-delivery-gate.md` and `reviewer-guide.md`.
  - **Lists and counts**: the `/aid-execute` line of the skill guide with the spec's text; `aid-execute`'s SG-04
    row, if any; the `aid-execute` row (`PL-04`, owner Feature 007) of `tests/canonical/skill-steps-exempt.tsv`; the
    site skill lists and flows and their `__tests__`.
  - Suites to update in this same task (the spec's hit list, `##### 7. Migration`, Suites):
    `test-pipeline-status-walkthrough.sh` (A1 to `references/start.md`, phase `Building`; A3's impediment fixture
    a `Blocker` question; M4's `aid-execute` row and its B1 check, B2's delivery-gate checks, B4e and B4f retired;
    B3 rewritten over `blocker.md`; B4a and B4b's emit-file list), `test-ticket-retirement-structural.sh`
    (`STATE_EXECUTE` becomes `references/build.md`; T037-T039 hold there; T040 asserts `build.md`'s `In Progress`
    write), `test-compute-block-radius.sh` (T17 retired), `test-task-state-transitions.sh` (its header and mandate
    name `build.md`), `test-scoped-review-cycles.sh` (the SW01-SW04 comment names `fix.md`), PL-04 of `test-plan.sh`
    (the exempt row gone), `test-downstream-worktree-entry.sh` (its `aid-execute` assertions -- G0-G4 and Group 7 --
    go with the worktree entry this rewrite removes, G11), and any suite the findings' X1 or X8 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `SKILL.md` is at most 120 lines with the eleven steps, FINISH advancing by `PASS`; none of the seven old references exists, and the thirteen new ones and the brief do (EX-01's reference clauses, EX-02's table clause).
  - [ ] Over `canonical/skills/aid-execute/`, `git grep -nE 'worktree add|checkout -b|switch -c|run_in_background|max_parallel_tasks|merge to main'` finds nothing, and `-delivery-` appears only in `old-work.md` (EX-03).
  - [ ] `skill-steps-exempt.tsv` has no `aid-execute` row and PL-04 passes; SG-02, SG-04 and the listed suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-234: Writer: the derived delivery state, and the retired modes refused, with the fork [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-221, task-231, task-233.
- **Source:** AC-19, AC-33.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 3. Work state`):
    - **the delivery `state` and `block_reason` are derived**, never written: every write recomputes them, first
      match -- `Canceled`, `Blocked`, `Pending`, `Building`, `Verifying`, `Approving`, `Done` -- freshness by
      `git merge-base --is-ancestor`, or snapshot order without git;
    - **refused** with exit 4 and a line naming the replacement: `--delivery-id NNN --lifecycle`, `--task-id NNN
      --field Review`, `--findings`, `--append-issue`, `--gate-field` and `--block`. task-233 removed their last
      callers (the findings' X3 names any other, which goes here).
  - `dashboard/scripts/writeback-state.sh` (the fork): the same task and delivery targets and the same derived
    delivery state; it keeps `Deploy`.
  - Delete `canonical/aid/templates/delivery-issues.md`, whose last users were `state-delivery-gate.md` and
    `--append-issue`.
  - Suites to update in this same task: the existing `test-writeback-state.sh` assertions on the retired modes
    (their units retire, with accepted-removal rows); `test-delivery-gate-aggregate.sh`, retired with
    accepted-removal rows; `test-lite-work-end-to-end.sh`; `tests/cost-baseline.tsv`'s `delivery-issues.md` row is
    re-recorded at the gate; and any suite the findings' X1 or X3 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] On a scratch work, a `Done` task commit after the delivery's `verify` shows the delivery `Verifying` in both writers, and a correction added to a `Done` delivery shows it `Building` at once.
  - [ ] `--delivery-id 001 --lifecycle Done` and `--findings` each exit 4 naming the replacement, with the file byte-identical; `test -e canonical/aid/templates/delivery-issues.md` fails.
  - [ ] `test-writeback-state.sh` and `test-lite-work-end-to-end.sh` pass live.

### task-235: One worktree, one branch: the consumer lists and NM-04 [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-233.
- **Source:** AC-11, AC-34.
- **Scope:**
  - `canonical/aid/templates/worktree-lifecycle.md` and `downstream-worktree-entry.md` (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and
    layout`): `aid-execute` leaves their consumer lists; § Composition with `aid-execute`'s per-task worktrees goes.
  - `tests/canonical/test-never-merges.sh`: NM-04's `aid-execute` exemption goes.
  - `tests/canonical/test-disjoint-merge.sh` is retired, with accepted-removal rows: delivery branches merging back
    no longer exist.
  - Suites to update in this same task: `test-downstream-worktree-entry.sh` where it asserts the two templates (its
    `aid-execute` assertions went with task-233's rewrite), and any suite the findings' X5 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] Neither template names `aid-execute` as a consumer or a per-task worktree; `test-never-merges.sh` passes live with NM-04's exemption gone.
  - [ ] `test-downstream-worktree-entry.sh` passes in the scratch copy, and `test -e tests/canonical/test-disjoint-merge.sh` fails, with its accepted-removal rows.

### task-236: rules.md's tracking line, aid-developer's blocker report, read-setting.sh's example [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-227.
- **Source:** AC-32, AC-37.
- **Scope:**
  - `canonical/aid/rules.md` § Tracking discipline: "`In Progress` at the start of EXECUTE" is reworded to name
    BUILD (REQUIREMENTS.md § 11 Feature 007 `##### 6. Risks`; KI-001). The summary bullet is unchanged.
  - `canonical/agents/aid-developer/AGENT.md`: "IMPEDIMENT.md" becomes a blocker in its report -- evidence, options,
    recommendation -- which the main conversation raises (a sub-agent never asks).
  - `canonical/aid/scripts/config/read-setting.sh`: its usage example names a key that is still read.
  - Suites to update in this same task: `test-shared-layout-sources.sh`, the rules summary suites, and any suite
    the findings' X8 assigns to these files.
- **Acceptance criteria:**
  - [ ] `canonical/aid/rules.md` § Tracking discipline names BUILD, not EXECUTE, for the `In Progress` write, and its summary bullets are byte-identical to the base.
  - [ ] `aid-developer/AGENT.md` names no `IMPEDIMENT`, and `read-setting.sh` names no `max_parallel_tasks`. The suites pass where the test step puts them, and the site `npm test` passes after `gen:reference`.

### task-237: Re-point every kept file that names a retired building artifact [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-233, task-234, task-235.
- **Source:** AC-19, AC-34.
- **Scope:**
  - Re-point by one rule (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, Re-pointing) every kept file under `canonical/`, and
    `dashboard/home.html`, that names a deleted reference, `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md`,
    `--append-issue`, `--findings`, a per-delivery branch or the per-task worktrees. Exempt:
    `canonical/aid/scripts/migrate/` and `feedback-artifacts/IMPEDIMENT.md` (until Feature 009). `aid-deploy`
    `references/state-verifying.md`'s "loop back to aid-execute" is kept; the comment in `bin/aid`'s state converter
    stays.
  - Outside `canonical/`: the comments in `dashboard/reader/derivation.py` naming the old producers of `Blocked` and
    `IMPEDIMENT-task-NNN.md` name `references/blocker.md`; `dashboard/reader/tests/test_integration.py`'s docstring
    names the running skill's step entry.
  - Suites to update in this same task: any suite the findings' X1 or X2 assigns to these files.
- **Acceptance criteria:**
  - [ ] Over `canonical/` (except `migrate/`, `feedback-artifacts/IMPEDIMENT.md` and the writer's refusal lines) and `dashboard/home.html`, `git grep -nE 'IMPEDIMENT-task-|delivery-[N0-9]+-issues|--append-issue|--findings|quick_check'` finds nothing (EX-05).
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-238: Format 6: the building part of the work-state step, in bash and PowerShell [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-220.
- **Source:** AC-25, AC-33.
- **Scope:**
  - The format-6 work-state step (Feature 006's) gains its building part, bash first and then its PowerShell twin,
    in this same task, byte-identical and idempotent (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, Format 6):
    - `tasks_lifecycle.*.review` -> `verify`; `quick_check` -> appended to `notes`; `gate_tier` -> `tier`,
      `gate_grade` -> `verify`; `gate_timestamp` goes; delivery `Executing` -> `Building`, `Gated` -> `Verifying`;
    - each `delivery-NNN-issues.md` appended to that delivery's `issue_list`, then deleted;
    - each `IMPEDIMENT-task-NNN.md` or `IMPEDIMENT-delivery-NNN.md` -> one `qa` entry (`category: Blocker`,
      `state: Pending`, `context` its description, `suggested` its recommendation), then deleted;
      `block_artifact` goes; a task's `Failed` state stays;
    - it runs on a repository already stamped format 6 (PLAN.md Cross-Cutting Risks, row 5).
  - **This work's own state is a case to get right**: this delivery's resync runs the step on it, carrying every
    delivery's gate grade into its `verify` (PLAN.md Toolchain and Branching, step 3).
  - `tests/windows/Test-AidInstaller.ps1` gains a building-step case (Q126).
  - Files: as delivery-008's task-202. PowerShell 5.1-safe and ASCII.
  - The unit cases are task-244.
  - Suites to update in this same task: any migration suite or case the findings' X8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch repository at format 6 holding a single-layout work with `review`, `quick_check`, `gate_grade`, an issues file and an impediment file, the step gives the expected `STATE.yml`, deletes both files, and a second run changes nothing.
  - [ ] Under `pwsh`, the twin gives byte-identical files; `test-ps51-compat.sh` and `test-ascii-only.sh` pass live, and `test-aid-cli-parity.sh` passes in the scratch copy.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-239: Dashboard readers and server: the building fields [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-220.
- **Source:** AC-41.
- **Scope:**
  - Both readers and the server, kept equal by the parity tests (REQUIREMENTS.md § 11 Feature 007 `##### 4. Components`, Dashboard):
    `dashboard/reader/models.py`, `parsers.py`, `reader.py`, `dashboard/server/reader.mjs`, `server.py` §
    `_ser_work`, `server.mjs`:
    - task cells: state, a plain stage for the task being built ("being tested", "being reviewed", "being
      simplified"), `verify`, `simplify`, `reverify`, `tests`; the quick-check fields go;
    - delivery cells: the seven states, `verify`, `tests`, `issue_list`; the gate tier and timestamp go;
    - `wave_stops`, `full_suite` and the new fields passed on; `feedback` read and not shown.
  - The page is task-240. New fixtures are task-245.
  - Suites to update in this same task: the existing dashboard reader, server and parity suites and fixtures that
    read the gone fields, and any suite the findings' X6 assigns here.
- **Acceptance criteria:**
  - [ ] A scratch work in Building with a task at `In Review` reads the stage "being reviewed" and its `verify` in both readers, identically.
  - [ ] `git grep -nE 'quick_check|gate_tier|gate_timestamp' -- dashboard/reader/*.py dashboard/server/*.py dashboard/server/*.mjs` finds nothing outside the migration-era `legacy-` markers, and the parity suites pass where the test step puts them.

### task-240: Dashboard page: the building card lines [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-239.
- **Source:** AC-41.
- **Scope:**
  - `dashboard/home.html` (REQUIREMENTS.md § 11 Feature 007 `##### 4. Components`, Dashboard): "Waiting for your approval: end of delivery-002"
    at a milestone; "Needs your decision" for an open `Blocker` entry; the full-suite result once FINAL has run;
    no step names; the quick-check display goes. The stop and finish controls are unchanged.
  - Suites to update in this same task: `dashboard/server/tests/test_index_html.py` and any page test the
    findings' X6 assigns here.
- **Acceptance criteria:**
  - [ ] `home.html` holds both card texts verbatim and no quick-check display, and `python3 -m pytest dashboard/server/tests/test_index_html.py` passes.

### task-241: Writer unit cases: building fields, derived delivery states, refused modes, parity [TEST]

- **Stanza wave:** 5. **Depends on:** task-222, task-234.
- **Source:** AC-26, AC-32, AC-33.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains the cases of REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`: each new task and
    delivery field with its values and exit 4 on a bad one; `--lifecycle` and the old delivery states refused;
    `"Wave Stops"` and `"Planned Wave Stops"`, a malformed list refused; `--full-suite`; `--feedback-add` ids and
    `--feedback` updates; `--plan-sync --cancel` on `Failed`, `Blocked` and `Pending`, exit 4 on `Done`, and a
    rewired `Blocked` task back to `Pending`; the derived delivery state for each of its seven cases, recomputed
    after a task write, a cancel and an approval, including the spec's three named correction cases; the writer
    parity case (canonical and fork, same fixtures, same derived states); the four retired modes exit 4 naming
    their replacement; a task write still re-renders the plan; every file parses through the dashboard reader
    with no warning.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-241`.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-242: test-simplify-guard.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-223.
- **Source:** AC-33.
- **Scope:**
  - Create `tests/canonical/test-simplify-guard.sh` (REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`), on throwaway repositories and on
    throwaway folders with no git: an untouched test list exits 0; a changed, a removed and an added test file each
    exit 1 naming it, with `--before` and with `--snapshot`; no git and no snapshot exits 3. It has `# COVERS:`
    lines.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-242`.
- **Acceptance criteria:**
  - [ ] The suite passes, with a named assertion for each case.
  - [ ] It is deterministic, cleans up its fixtures and pins `HOME`.

### task-243: Unit cases: derive-waves --delivery, complexity-score and compute-block-radius [TEST]

- **Stanza wave:** 5. **Depends on:** task-224, task-225.
- **Source:** AC-32, AC-34.
- **Scope:**
  - `tests/canonical/test-derive-waves.sh` gains: `--from-tasks --delivery` prints one delivery's table and waves, a
    dependency on an earlier delivery counted as met; the unscoped output is unchanged (REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`).
  - `test-complexity-score.sh` and `test-compute-block-radius.sh` gain: both read `--from-tasks` output; without
    `--delivery-id`, a failed task blocks a dependent in a later delivery; with it, the scoped result is today's.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-243`.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its branch is broken in a scratch copy of the script.
  - [ ] The cases are deterministic and use temporary fixtures only.

### task-244: Unit cases: test-work-state-migration.sh, the building part [TEST]

- **Stanza wave:** 5. **Depends on:** task-238.
- **Source:** AC-25, AC-33.
- **Scope:**
  - `tests/canonical/test-work-state-migration.sh` (Feature 006's) gains (REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`): the renamed
    fields and states; an issues file and an impediment file folded and deleted; a second run changing nothing;
    bash and PowerShell giving the same bytes; a fixture shaped like this work after delivery-008's migration, with
    every delivery's gate grade carried into `verify`.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-244`.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, with each new case named.
  - [ ] Changing one byte of the PowerShell output in a scratch copy fails the byte-identity case.

### task-245: Dashboard cases: a task being verified, a milestone, a blocker, a finished full suite [TEST]

- **Stanza wave:** 5. **Depends on:** task-239, task-240.
- **Source:** AC-41.
- **Scope:**
  - Add to the dashboard tests (REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`, Dashboard): fixtures for a work in Building with a task
    being verified, a delivery at its milestone, an open `Blocker` entry and a finished full suite;
    `test_index_html.py` for the card lines; the parity tests.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-245`.
- **Acceptance criteria:**
  - [ ] Both readers give the same result for every fixture, and the parity tests pass.
  - [ ] `test_index_html.py` asserts each card line, and passes.

### task-246: test-execute.sh (EX-01 to EX-08) [TEST]

- **Stanza wave:** 5. **Depends on:** task-220, task-223, task-231, task-233, task-234, task-235, task-237.
- **Source:** AC-26, AC-32, AC-33, AC-34.
- **Scope:**
  - Create `tests/canonical/test-execute.sh` with EX-01 to EX-08, as REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing` defines them. It has
    `# COVERS:` lines.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-246`.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy.
  - [ ] Each check fails its own mutation in a scratch copy: a missing `next.md`; `finish.md` without `--phase CI`; a `git worktree add` in a reference; `simplify.md` without `simplify-guard.sh`; a skill naming `IMPEDIMENT-task-`; APPROVAL-HALT without `confirmation before building`; the template with `quick_check`; `next.md` without `merge-base --is-ancestor`.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-247: Samples 007-01 to 007-06 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-233, task-234, task-235.
- **Source:** AC-10, AC-26, AC-28, AC-32, AC-33.
- **Scope:**
  - Create under `tests/conversation/samples/feature-007/`, with frontmatter `skills: aid-execute`, their fixtures
    (each a small project with code and a test suite, no remote) and the checks of REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`:
    `007-01-lite-one-approval-to-result`, `007-02-full-after-plan-approval`, `007-03-review-per-wave` (all its
    runs), `007-04-failing-test-not-done`, `007-05-simplify-no-change` and `007-06-simplify-then-reverify`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-247`.
- **Acceptance criteria:**
  - [ ] There are six files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-248: Samples 007-07 to 007-12 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-232, task-238, task-247.
- **Source:** AC-32, AC-33, AC-34, AC-37.
- **Scope:**
  - Create under `tests/conversation/samples/feature-007/`, with frontmatter `skills: aid-execute`, their fixtures
    and the checks of REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`: `007-07-two-deliveries`, `007-08-kb-conflict-blocker`,
    `007-09-one-worktree-one-branch`, `007-10-baseline-failure-reported`, `007-11-change-at-milestone` and
    `007-12-old-delivery-branch`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-248`.
- **Acceptance criteria:**
  - [ ] There are six files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-249: Sample 007-13 (deferred) and the deferred rows that now run [TEST]

- **Stanza wave:** 5. **Depends on:** task-248.
- **Source:** AC-28, AC-32, AC-42.
- **Scope:**
  - Create `007-13-milestone-collect-and-push` under `tests/conversation/samples/feature-007/`, with its fixture and
    checks (REQUIREMENTS.md § 11 Feature 007 `##### 8. Testing`).
  - Update `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, Lists other features own): the
    `skill:aid-execute` row goes (covered by `007-02`); the rows of `002-07`, `002-08`, `002-09`, `002-13`, `003-07`,
    `003-10`, `004-11`, `004-12`, `005-11`, `005-12` and `006-06` go: they run at this gate; a row for `007-13`,
    waiting for Feature 008.
  - Smoke run (Q134 D8): each sample whose row goes, once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-249`.
- **Acceptance criteria:**
  - [ ] `007-13` exists with its `deferred.tsv` row; DT-01 and SS-09 pass, with none of the eleven rows and no `skill:aid-execute` row left.
  - [ ] Each smoke run has its result reported.

### task-250: test-execute.sh and test-simplify-guard.sh in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-242, task-246.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-execute` and
    `test-simplify-guard`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's text.
- **Acceptance criteria:**
  - [ ] Each name appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-251: KB decisions, schemas, glossary, standards, tech debt and backlog for Building [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-220, task-234, task-236.
- **Source:** AC-24, AC-26, AC-33.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, KB and Release notes):
    - `decisions.md`: the new decision "one task at a time in the work's one worktree; every task and delivery goes
      build, test, verify, simplify once, and re-verify only when the simplification changed something", which
      supersedes the parallel pool and the two-tier review; D6 stays;
    - `artifact-schemas.md`: the building part; `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md` and
      `execution.max_parallel_tasks` go;
    - `domain-glossary.md`: milestone, real blocker, simplify, re-verify, full-suite baseline; Max Concurrent, quick
      check and delivery gate go;
    - `coding-standards.md` (its settings-key example) and `tech-debt.md`;
    - `backlog.md` § Next Release: the three old -> new rows (AC-24).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] The backlog rows carry the spec's New text, and the superseded decisions are marked in the summary table and in their sections.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-252: KB architecture, contracts and quality documents for Building [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-233, task-235, task-237.
- **Source:** AC-26, AC-34.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, KB): `pipeline-contracts.md` (the
    Building contract and state machine; the pool and two-tier review go; loops L6 and L7 become the calls and
    blockers); `quality-gates.md` (task and delivery verification, simplify and re-verify; the three-round rule);
    `architecture.md` (the Execute rows; one worktree and one branch per work); `capability-inventory.md` and
    `module-map.md`.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'max_parallel|IMPEDIMENT-task-|quick check|delivery gate'` finds only lines that describe how old works or the old layout are handled (each such line also names `legacy`, `old work` or `aid update`); `git grep -nE 'max_parallel|IMPEDIMENT-task-|quick check|delivery gate' -- <the edited documents> | grep -viE 'legacy|old work|aid update'` prints nothing.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-237 leaves it.

### task-253: KB test landscape for the building suites, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-241, task-243, task-244, task-245, task-249, task-250, task-251, task-252.
- **Source:** AC-25, AC-26.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-execute.sh` and `test-simplify-guard.sh` and their lane; the new
    cases of `test-writeback-state.sh`, `test-derive-waves.sh`, `test-complexity-score.sh`,
    `test-compute-block-radius.sh` and `test-work-state-migration.sh`; the retired `test-delivery-gate-aggregate.sh`
    and `test-disjoint-merge.sh` go.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync
    migrates this work's state, not the KB.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names both new suites and their lane, and neither retired suite.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-execute` rewritten: eleven steps, thirteen references, seven deleted, `task-type-rules.md` | 226-230, 233; 227 |
| The full suite's command resolved once and recorded (Q132) | 226 (`start.md`), 230 (`final.md`) |
| `simplify-guard.sh`; `derive-waves.sh --delivery`; `complexity-score.sh` and `compute-block-radius.sh`; `delivery-issues.md` deleted | 223; 224; 225; 234 |
| Writer: building fields, `--full-suite`, `--feedback-add`, `--feedback`, the derived delivery state with the fork, the retired modes refused | 221, 222, 234 |
| `skill-steps.md` corrections row and Building rule; APPROVAL-HALT; `aid-plan` `revise.md` | 231; 232 |
| One worktree, one branch; the consumer lists; NM-04 | 233, 235 |
| The `rules.md` tracking line (BUILD) | 236 |
| Format 6 building part with the `Test-AidInstaller.ps1` case; the dashboard's building fields | 238; 239, 240 |
| `test-execute.sh` EX-01 to EX-08; `test-simplify-guard.sh`; `SUITES`; the `aid-execute` PL-04 row gone | 246; 242; 250; 233 |
| Samples `007-01` to `007-12` (run), the eleven samples that now run, `007-13` deferred | 247, 248, 249 |
| G0: AC-24 rows; KB; `INDEX.md`; `kb.html` | 251; 251-253; 253 |

**Steps that are not tasks:**
1. `--delivery-id 009 --lifecycle Executing` (the installed Feature 006 writer).
2. The tasks, each tracked in the work `STATE.yml`, with two state-only commits and a `reviews` entry
   (`task-NNN verify`) per task (G0).
3. Verification; its grade recorded with `--delivery-id 009 --gate-field Grade` before the resync.
4. The resync (`delivery-009: resync`): `aid update` installs the new `/aid-execute`, the Feature 007 writer and
   `simplify-guard.sh`, removes the deleted references and `delivery-issues.md` through the manifest, and runs
   format 6's building part on this work, carrying every delivery's gate grade into its `verify`.
5. **After the resync, in the gate session (G8):** `derive-waves.sh --plan --check` (installed) on this work, and
   `--plan` when it reports stale; `(cd site && npm run gen:reference)` and the site `npm test`, a no-op unless the
   resync changed `.aid/settings.yml`. The KB is not changed by this resync.
6. The gate, in the same session: the stanza's criteria (the `rules.md` line included); `007-01` to `007-12`, the
   eleven samples that now run, and `001-07`, `001-16` and `006-01` again, each 3 of 3; G0 with the baselines; the
   tracking proof for task-219 to task-253, read from the work `STATE.yml`'s history and its `reviews`. A fix after
   this resync records its grade with `--delivery-id 009 --field Verify`, and no lifecycle is written (PLAN.md step
   5).
7. **The switch** (PLAN.md switch questions, Q123, Q124): `--check` reports the type missing, and `--repair --skill
   aid-execute --name START --reading change` runs with Q124 as the recorded confirmation; `Verify` and `Commit`
   are written for deliveries 001-009 with `--delivery-id NNN --field`; then the one approval, through `--ask` and
   `--answer`: `category: Approval`, `covers: delivery delivery-001; ...; delivery delivery-009; confirmation before
   building`, `commit` the head.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-219
wave 2: task-220, task-223, task-224, task-231
wave 3: task-221, task-225, task-238, task-239, task-242
wave 4: task-222, task-227, task-228, task-240, task-243, task-244
wave 5: task-226, task-229, task-230, task-232, task-236, task-245
wave 6: task-233
wave 7: task-234, task-235
wave 8: task-237, task-241, task-247, task-251
wave 9: task-246, task-248, task-252
wave 10: task-249, task-250
wave 11: task-253
```

Step 5 writes the table under `### delivery-009 Execution Graph`, one task per row, from the task files'
`**Depends on:**` lines.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | `aid-execute`'s rewrite: `SKILL.md`, thirteen references and the brief. | Five tasks create the references, unreferenced until task-233 rewrites `SKILL.md`, points its table at them and deletes the seven old ones. | One session per task; no dangling pointer. |
| S2 | The writer's retired modes still have callers until `aid-execute` is rewritten. | The writer's new fields are additive (221, 222); the derived delivery state and the refusals come in task-234, after task-233 removes the last callers, with the fork and `delivery-issues.md`. | G7, G11; no caller fails between tasks. |
| S3 | `test-downstream-worktree-entry.sh` asserts `aid-execute`'s worktree entry. | Its `aid-execute` assertions change in task-233, which removes that entry; task-235 keeps the template parts. | G11. |
| S4 | `test-disjoint-merge.sh` is retired "beyond the search". | In task-235, with the per-delivery branch material. | F007 § 7, Suites. |
| S5 | The format-6 building part, bash and PowerShell. | One task (238): a small field mapping, both twins together. The unit cases are task-244. | delivery-005 S3. |
| S6 | The dashboard's building fields. | Readers and server (239), then the page (240). | Size; the parity tests. |
| S7 | `007-13` is the feature's one deferred sample. | Written in task-249 with the rows of the samples that now run. | F007 § 7, Lists. |
| S8 | `kb.html` and `INDEX.md`. | Rendered in task-253: the resync changes no KB document. The plan check after the resync is a listed step (G8). | G0, G8. |
| S9 | Unit cases, samples, the CI lane and the test landscape. | As in the earlier deliveries. | Q134 D2, D8; Q135 R1, R3. |

---

## 7. Flagged for the maintainer

- **F-1 (deliveries 010-014: the Execution protocol note in their task files).** Every task file so far carries
  the note that ends "Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`".
  That is right for deliveries 001-009: the file exists, installed, while they are built. Task-233 deletes it in
  `canonical/`, and delivery-009's resync removes the installed copy, so in 010-014 the note would point at nothing.
  Under the new `/aid-execute`, the state writes are the builder's own: `build.md` writes `In Progress`, `verify.md`
  `In Review`, `next.md` `Done`; the executor it dispatches writes no state. F006's rewritten
  `task-detail-template.md` carries a shorter note with no file citation ("write the task's State as it changes --
  In Progress, In Review, Done / Failed -- through writeback-state.sh --task-id NNN --field State").
  **Recommendation:** the task files of 010-014 carry F006's template note verbatim. That note names the writer
  and no file, and matches what the new builder does, so a test-step instruction to the executor does not
  contradict it. The alternative is to cite `aid-execute/references/build.md` § its `In Progress` write. I have not
  written any 010-014 file; I will follow your answer.
- **Note on the other 010-014 task-file fields.** The new builder reads Type, Source (old form
  `feature-NNN-name -> delivery-NNN -> AC-N` still reads, Feature 006), Depends on and the criteria; the extra
  blocks (same-task rule, findings, the test step) are scope text the executor follows. No other field is missing.
