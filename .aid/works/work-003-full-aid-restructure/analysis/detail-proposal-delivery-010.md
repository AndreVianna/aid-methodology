# Detail proposal -- delivery-010: Pull requests to a mergeable state, never merged (Feature 008)

This is `aid-detail` FIRST-RUN for **delivery-010**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-010/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-009's task-253.
- **General rules.** G1-G13 apply from the start.

**Inputs read:**
- the delivery-010 stanza of `PLAN.md`, Common Gate G0 (its lane item carried by the milestone push), "Testing
  before the resync" (the driver), "Toolchain and Branching" ("How deliveries 010-014 are built", the resync rule
  with item 6, the switch rows for delivery-010's START, gate session and milestone);
- `REQUIREMENTS.md` § 11 Feature 008 (all eight subsections), and Feature 007's Flow for how the new builder runs a
  task.

**Measured at base `1e513e05`** (task-254 re-measures on the tree deliveries 001-009 leave):
- `canonical/aid/scripts/housekeep/` holds `cleanup-classify.sh` (the other two scripts leave with delivery-005).
- Outside the KB skills and housekeep, no kept file runs `git push`; `cleanup-classify.sh` names it in its
  self-check.
- `test-housekeep-classify.sh`, `test-housekeep-deletion-split.sh`, `test-housekeep-workfolder-safety.sh` and
  `test-delete-pipeline.sh` exist.

**How this delivery is built: the new `/aid-execute`** (PLAN.md, How deliveries 010-014 are built). It runs each
task's BUILD, TEST, VERIFY, SIMPLIFY, REVERIFY and NEXT, then DELIVERY and MILESTONE's collect and corrections,
and pauses at MILESTONE's approval question; the resync and the gate are sessions of their own. Three things in
the task files follow from that:
- **The Execution protocol note** is Feature 006's `task-detail-template.md` note, word for word, with the task's
  id in place of `NNN` (S1).
- **`BASE`** in the test step is the task's recorded `base` (`tasks_lifecycle.task-NNN.base`, written by BUILD on
  the first round): the new builder makes no state-only commit (S2).
- **The same failure after three fix rounds** is a real blocker (`references/blocker.md`), the new builder's rule,
  not a hand-off to the maintainer (S2).
The test step's split into a scratch half and a live half stays: TEST runs each copy-reading suite in a scratch copy
(PLAN.md). FINAL does not run in this delivery; it runs at delivery-014, with the recorded `full_suite.command`,
which names the driver from delivery-010's gate session on.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-254 | Delivery-010 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-255 | push-approved.sh: the only push, checked against the approval | IMPLEMENT | 2 | 2 | task-254 |
| task-256 | merge-parent.sh: the only merge | IMPLEMENT | 2 | 2 | task-254 |
| task-257 | cleanup-classify.sh moved to pipeline/, reading the work file | IMPLEMENT | 2 | 2 | task-254 |
| task-258 | close-work.sh: the local clean-up of one closed work | IMPLEMENT | 2 | 3 | task-257 |
| task-259 | The pull_request key and the writer's --pull-request, with the duplicate-ref rule | IMPLEMENT | 2 | 2 | task-254 |
| task-260 | The work_folders setting | IMPLEMENT | 2 | 2 | task-254 |
| task-261 | The gh and glab stand-ins for the conversation suite | TEST | 2 | 2 | task-254 |
| task-262 | aid-monitor-pipeline references: START, COLLECT, reaching the host | IMPLEMENT | 3 | 3 | task-259, task-260 |
| task-263 | aid-monitor-pipeline references: PUSH and PARENT | IMPLEMENT | 3 | 3 | task-255, task-256, task-259 |
| task-264 | aid-monitor-pipeline references: REVIEW, REACT, WATCH and the brief | IMPLEMENT | 3 | 3 | task-259 |
| task-265 | aid-monitor-pipeline reference: CLOSE | IMPLEMENT | 3 | 4 | task-256, task-258 |
| task-266 | aid-monitor-pipeline SKILL.md, its guide line and its lists | IMPLEMENT | 3 | 5 | task-262, task-263, task-264, task-265 |
| task-267 | Contracts for the CI phase: approvals, the gate's row 1, the publish seam, the worktree teardown | IMPLEMENT | 3 | 2 | task-254 |
| task-268 | The finishing skills pass to the close | IMPLEMENT | 3 | 6 | task-266 |
| task-269 | The interim close retired, and Building's calls named | IMPLEMENT | 3 | 6 | task-263, task-266 |
| task-270 | Every other push removed, and the housekeep and origin/master re-pointing | IMPLEMENT | 4 | 6 | task-257, task-266, task-267 |
| task-271 | delete-pipeline.sh without --force | IMPLEMENT | 4 | 2 | task-254 |
| task-272 | Dashboard readers and server: the pull request and merged work folders | IMPLEMENT | 4 | 3 | task-259 |
| task-273 | Dashboard page: the CI card lines | IMPLEMENT | 4 | 7 | task-270, task-272 |
| task-274 | test-push-approved.sh | TEST | 5 | 3 | task-255, task-259 |
| task-275 | test-merge-parent.sh | TEST | 5 | 3 | task-256 |
| task-276 | test-close-work.sh, and the cleanup-classify cases | TEST | 5 | 4 | task-257, task-258 |
| task-277 | Writer unit cases: --pull-request and the duplicate ref | TEST | 5 | 3 | task-259 |
| task-278 | Dashboard cases: draft, failing pipeline, idle watch, connection, merged-in folder | TEST | 5 | 8 | task-272, task-273 |
| task-279 | test-never-merges.sh: NM-01 narrowed, NM-03 with no exemption, NM-05 and NM-06 | TEST | 5 | 7 | task-255, task-256, task-258, task-265, task-268, task-270, task-271 |
| task-280 | test-monitor-pipeline.sh (MP-01 to MP-05) | TEST | 5 | 7 | task-259, task-260, task-266, task-267, task-268, task-269, task-270 |
| task-281 | Samples 008-01 to 008-07 (run at this gate) | TEST | 5 | 7 | task-261, task-266, task-268, task-269, task-270 |
| task-282 | Samples 008-08 to 008-14 (run at this gate) | TEST | 5 | 8 | task-281 |
| task-283 | Samples 008-15 to 008-18, and the deferred rows | TEST | 5 | 9 | task-282 |
| task-284 | The four new suites in the CI lane | CONFIGURE | 5 | 8 | task-274, task-275, task-276, task-280 |
| task-285 | KB decisions, schemas, glossary and tech debt for the CI phase | DOCUMENT | 5 | 7 | task-259, task-260, task-270 |
| task-286 | KB architecture, contracts and integration documents for the CI phase | DOCUMENT | 5 | 7 | task-266, task-270, task-271 |
| task-287 | KB test landscape for the CI suites, the regenerated index and the view | DOCUMENT | 5 | 10 | task-277, task-278, task-279, task-283, task-284, task-285, task-286 |

That is 34 tasks. The resync follows the run's pause at the delivery-010 MILESTONE approval (§ 4).

---

## 2. Rules every task carries

The blocks of delivery-009, with the three adaptations above, and G1-G13. Same-file edits are ordered by a direct
dependency edge, never by the waves (G12): `test-never-merges.sh` (256, then 265, then 279), `deferred.tsv` (266,
then 283), `test-kb-skills.sh` (263, then 269), `home.html` (270, then 273). The steps after the resync and before
the gate are written into task-287's text (G13). The new skill adds one to the skill count: task-266 re-syncs the counted numbers
and runs `sync:docs`.

---

## 3. Tasks

`Source` reads `feature-008-cicd-integration-monitoring -> delivery-010 -> AC-...` (the old Source form, which
Feature 006 keeps readable).

### task-254: Delivery-010 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-11, AC-35, AC-36.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout` and `##### 7. Migration`):
    - **Y1** `housekeep/cleanup-classify.sh`, the `aid-housekeep` teardown, and `origin/master` as a merge target,
      over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/` and `.github/`;
    - **Y2** the interim close: `/aid-orchestrate`'s close minimum, and every line that marks a work `Completed`
      by hand (`aid-research`, `aid-review`, `aid-report`, `aid-deploy`, `aid-orchestrate`, `aid-kb-update`,
      `aid-execute`);
    - **Y3** every executed or written `git push`, `git merge`, `git pull`, `gh pr create`, `glab mr create`,
      `git branch -D` and `git worktree remove --force` under `canonical/` and `dashboard/scripts/` (NM-01, NM-03,
      NM-05, NM-06), each with the task that removes it or the exception that keeps it;
    - **Y4** the readers of `pull_request`, `work_folders`, `feedback` and the dashboard's CI card lines;
    - **Y5** the consumer rows of `worktree-lifecycle.md` § Step 3, `consumption-protocol.md`'s wired-seam
      table, and the gate's § 3b row 1;
    - **Y6** this repository's own `.gitignore` entries for `.aid/works/` (the ignored-folder question at the
      first push of this work, Risks);
    - **Y7** the rows of `tests/conversation/deferred.tsv` and the SG-04 exempt list that name a sample or skill
      this delivery runs or adds;
    - **Y8** the Q106 suite map for every file on the edit list, including the site's skill lists.
  - Give each hit exactly one owner:
    - a task of delivery-010 (task-255 to task-287; see the task files under
      `.aid/works/work-003-full-aid-restructure/deliveries/delivery-010/tasks/`);
    - Feature 009 (delivery-012) for the skills it rebuilds that finish a work (`create`, `update`, `document`,
      `test`, `prototype`);
    - "installed copy (resync)";
    - "history, left as is".
  - **Content owner of the moved file (G7):** `cleanup-classify.sh` moves to `canonical/aid/scripts/pipeline/`, and
    task-257 owns both the move and its content.
  - In a delta section, list each suite assigned to two independent tasks, with the order to run them.
  - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
  - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
    text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
    that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
    through the builder").
- **Acceptance criteria:**
  - [ ] Each of Y1-Y8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-255: push-approved.sh: the only push, checked against the approval [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-35, AC-42.
- **Scope:**
  - Create `canonical/aid/scripts/pipeline/push-approved.sh` (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, `push-approved.sh`):
    `--work-dir W [--check]`; reads the work file (the newest `Approval` answered yes with a `commit`,
    `pipeline.parent_branch`, `idea_draft`, `pull_request.remote`, `pull_request.work_folder`; either of the last
    two at `--` exits 9); what may reach the remote (the approved commit and its ancestors, then each following
    commit that changes only this work's folder with `work_folder: push` or only deletes this work's idea draft);
    the final-content check (AC-35); `git push <remote> <head>:refs/heads/<work branch>`, never forced, refusing the
    parent branch, `main` or `master`; exits 0, 2-9; `--check` writes and pushes nothing.
  - The unit suite is task-274.
- **Acceptance criteria:**
  - [ ] In a scratch repository with a local bare remote, the script pushes exactly the approved commit, and `--check` changes neither the repository nor the remote.
  - [ ] `grep -nE 'push .*(-f|--force)|\+refs' canonical/aid/scripts/pipeline/push-approved.sh` prints nothing, and a work branch named `main` exits 7.

### task-256: merge-parent.sh: the only merge [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-11, AC-34.
- **Scope:**
  - Create `canonical/aid/scripts/pipeline/merge-parent.sh` (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, `merge-parent.sh`):
    `start --work-dir W --from parent|own` (refuses unless on the work's own branch, which is not the parent,
    `main` or `master`, with no merge in progress; fetches; `git merge --no-ff --no-commit`; prints the conflicted
    paths; exit 0, 1, 2, 3, 4); `finish` (refuses a conflict marker or an unmerged path; a fixed message; prints
    the commit); `abort`; `fast-forward --from own` (`--ff-only`). Never pushes, never checks out another branch.
  - The unit suite is task-275.
  - Suites to update in this same task: `test-never-merges.sh` where NM-01 reads this path (F002's NM-01 already
    names it as the one exception).
- **Acceptance criteria:**
  - [ ] In a scratch repository, `start --from parent` on the parent branch exits 4 and changes nothing; on the work branch it merges and lists the conflicted paths.
  - [ ] `grep -nE 'git (push|checkout|switch)' canonical/aid/scripts/pipeline/merge-parent.sh` prints nothing, and `test-never-merges.sh` passes live.

### task-257: cleanup-classify.sh moved to pipeline/, reading the work file [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-36.
- **Scope:**
  - Move `canonical/aid/scripts/housekeep/cleanup-classify.sh` to `canonical/aid/scripts/pipeline/cleanup-classify.sh`
    and rewrite it (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, `cleanup-classify.sh`): the signals read the work file's YAML (merged:
    `pull_request.state: merged`, or the work branch's tip contained in `<remote>/<pipeline.parent_branch>`, never
    `origin/master`; concluded: `lifecycle: Completed` or `Canceled`); the `## Deploy Status` and `> **Status:**`
    reads go (tech-debt SY-1); new `--work <work-id>`, one record per item of that work, each with whether it is safe
    to remove; the project scan (S1-S6) stays, S1 offering a temporary path only when no open work owns it;
    read-only, its safety self-check kept.
  - The emptied `canonical/aid/scripts/housekeep/` folder goes.
  - Suites to update in this same task: `test-housekeep-classify.sh`, `test-housekeep-deletion-split.sh` and
    `test-housekeep-workfolder-safety.sh` follow the script to its new path and the YAML signals (their
    `origin/master` fixtures become a parent-branch fixture); the new `--work` cases are task-276.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -e canonical/aid/scripts/housekeep` fails and `canonical/aid/scripts/pipeline/cleanup-classify.sh` exists; over it, `git grep -nE 'origin/master|Deploy Status'` finds nothing.
  - [ ] The three housekeep suites pass live on the new path, with a parent branch other than `master` in their fixtures.

### task-258: close-work.sh: the local clean-up of one closed work [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-257.
- **Source:** AC-36.
- **Scope:**
  - Create `canonical/aid/scripts/pipeline/close-work.sh` (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, `close-work.sh`): `--work-dir W
    --main M --mode merged|no-pr|nothing|no-git [--move-to-main P]...`; acts only on `cleanup-classify.sh --work`'s
    items: this work's temporary files (with `--move-to-main` first); the local work branch only when nothing is
    unpushed; old delivery branches only when contained; the worktree with `git worktree remove` (never forced),
    from the main folder; the work folder by `work_folder` (`push`, `keep-local` moved and listed in
    `.git/info/exclude`, `delete`), settled before the worktree is removed; `no-pr` keeps branch and worktree.
    Never `git push`, a remote ref or `--force`; a safety self-check; exits 0, 2, 3, 4.
  - The unit suite is task-276.
- **Acceptance criteria:**
  - [ ] In a scratch repository with a local bare remote, `--mode merged` deletes the local branch and the worktree and leaves the remote branch; a branch with an unpushed commit is kept and named on stderr.
  - [ ] `grep -nE '^[^#]*git (push|worktree remove --force)' canonical/aid/scripts/pipeline/close-work.sh` prints nothing.

### task-259: The pull_request key and the writer's --pull-request, with the duplicate-ref rule [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-35, AC-42.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml`: the `pull_request` key (`host`, `via`, `remote`, `number`,
    `link`, `state`, `head`, `pipeline`, `checked`, `watch_until`, `review`, `work_folder`) with its `[W]` comment
    (REQUIREMENTS.md § 11 Feature 008 `##### 3. Work state`). Both dashboard readers accept it with no warning (schema only).
  - `canonical/aid/scripts/execute/writeback-state.sh`: `--pull-request --field F --value V` (the twelve fields;
    `State`, `Pipeline`, `Host` and `Work Folder` validated against their lists, anything else exits 4);
    `--feedback-add` with a `ref` already present writes nothing and prints that entry's id, exit 0.
  - `dashboard/scripts/writeback-state.sh` (the fork): the same duplicate-`ref` rule; it keeps `Deploy`.
  - The unit cases are task-277.
  - Suites to update in this same task: `test-work-state-template.sh`, the existing `test-writeback-state.sh`
    assertions, `test-skill-steps.sh` SS-08, and any suite the findings' Y4 assigns here.
- **Acceptance criteria:**
  - [ ] The template has `pull_request` with its `[W]` comment (MP-04's clause) and parses through both readers with no warning.
  - [ ] On a scratch work, a second `--feedback-add` with the same `ref` prints the first id and leaves the file byte-identical, in both writers; `--pull-request --field State --value pending` exits 4.
  - [ ] `test-work-state-template.sh`, `test-writeback-state.sh` and SS-08 pass where the test step puts them.

### task-260: The work_folders setting [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-35, AC-36.
- **Scope:**
  - `canonical/aid/templates/settings.yml`: `work_folders: push` with its comment (`push`, `keep-local`, `delete`;
    M4) (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout`).
  - `canonical/skills/aid-config/SKILL.md`: the settings row that sets it.
  - Suites to update in this same task: `test-settings-schema-check.sh`, `test-read-setting.sh` and any suite the
    findings' Y4 assigns here.
- **Acceptance criteria:**
  - [ ] `settings.yml` has `work_folders: push` (MP-04's clause), and `read-setting.sh --key work_folders --default push` prints `push` on a scratch project.
  - [ ] The settings suites pass where the test step puts them, and the site `npm test` passes after `gen:reference`.

### task-261: The gh and glab stand-ins for the conversation suite [TEST]

- **Stanza wave:** 2. **Depends on:** task-254.
- **Source:** AC-13, AC-27, AC-42.
- **Scope:**
  - Create `tests/conversation/stand-ins/gh` and `tests/conversation/stand-ins/glab` (REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`,
    Conversation samples): scripts a sample copies into its fixture's `bin/`; each answers the operations of
    `hosts.md` from the sample's `host.json` (create, ready, edit, state and mergeability, comments and verdicts,
    checks and a failed job's log, reply, reopen), refuses every call when `host.json` says the host is unreachable,
    and logs every call to `host-calls.log`.
  - Neither offers a merge or a branch deletion.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-261`.
- **Acceptance criteria:**
  - [ ] A scratch `host.json` with one open pull request and one failing check gives the expected answers to `gh pr view`, `gh pr checks` and `glab ci status`, and each call is appended to `host-calls.log`.
  - [ ] `gh pr merge` and `glab mr merge` exit non-zero and change nothing; the stand-ins are deterministic and need no network.

### task-262: aid-monitor-pipeline references: START, COLLECT, reaching the host [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-259, task-260.
- **Source:** AC-13, AC-42.
- **Scope:**
  - Create in `canonical/skills/aid-monitor-pipeline/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 008 `##### 2. Flow`, steps 1-2, and `##### 4. Components`, Reaching
    the host):
    - `start.md`: what START reads; a collect or push call by its `--why`; a typed start before the whole build is
      approved passes back; the host and remote resolved and written; nothing to land, no git, no remote, no pull
      request yet (the create question, Q94); a host other than GitHub or GitLab; a draft marked ready; an open pull
      request adopted, never duplicated;
    - `collect.md`: read-only; each new item one `feedback` entry by its kind; commits others added on the host;
      `HALT` in a collect call;
    - `connect.md`: finding the failing piece; the sign-in steps (`gh auth login`, `glab auth login`); the plug-in
      route with `/aid-set-connector`; the workarounds with a recommendation (Q32), recorded `category: Connection`;
    - `hosts.md`: one row per operation, the plug-in route and the command; no merge operation and no branch deletion.
  - `SKILL.md` is task-266.
- **Acceptance criteria:**
  - [ ] The four files exist, each at most 120 lines; `connect.md` names `/aid-set-connector`, `gh auth login` and `glab auth login`, and `hosts.md` names no `pr merge`, `mr merge` or branch deletion (MP-03).
  - [ ] The site `npm test` passes after regeneration.

### task-263: aid-monitor-pipeline references: PUSH and PARENT [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-255, task-256, task-259.
- **Source:** AC-11, AC-35, AC-42.
- **Scope:**
  - Create in `canonical/skills/aid-monitor-pipeline/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 008 `##### 2. Flow`, steps 3-4):
    - `push.md`: step 0 (the remote; the ignored-folder question; the freeze of `work_folder`), then the Every-way-in
      check (`push-approved.sh --check`, one approval, `covers: KB change` or `final result`, yes / a change / not
      now), then steps 1-7 (others' commits first, never pushed alone; a parent conflict to PARENT; the record
      commit; `push-approved.sh`; the pull request as a draft while Building, its body; record and reply; `HALT` in
      a push call);
    - `parent.md`: `merge-parent.sh start --from parent`; KB files kept both sides, then `build-kb-index.sh` and
      `render-kb-view.sh`, and one `/aid-kb-update` sweep call; other conflicts by `aid-developer`; the full suite
      by `full_suite.command`; `finish`; the conflict check by `remerge-diff`; the approval `covers: conflict merge`.
  - Suites to update in this same task: `test-kb-skills.sh` KB-03, whose named exception for this skill's files these
    references now use (G11).
- **Acceptance criteria:**
  - [ ] `push.md` names `push-approved.sh`, `draft` and the record commit; `parent.md` names `merge-parent.sh`, `render-kb-view.sh`, `build-kb-index.sh`, `remerge-diff` and `conflict merge` (MP-02).
  - [ ] `test-kb-skills.sh` passes in the scratch copy, and the site `npm test` passes after regeneration.

### task-264: aid-monitor-pipeline references: REVIEW, REACT, WATCH and the brief [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-259.
- **Source:** AC-27.
- **Scope:**
  - Create in `canonical/skills/aid-monitor-pipeline/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 008 `##### 2. Flow`, steps 5-7):
    - `review.md`: the three lenses in one pass, once, gated by `pull_request.review`; rows become `feedback`;
    - `react.md`: `bug`, `correction` and `pipeline failure` corrected as a build (`/aid-plan` REVISE, `Assumed`,
      then a correction `CALL` to `/aid-execute`, then PUSH); a change against the KB as a question; a failure the
      parent also has, or an unstable one; the three-attempt stop as a `Blocker`; suggestions and comments as
      grouped questions, a reply only on the user's yes;
    - `watch.md`: REVIEW first; COLLECT every 2 minutes within a 30-minute window; `WAIT` when idle; the
      closed-unmerged question.
  - Create `references/reviewer-brief.md` with `### What to report` (SS-13) and two modes: the three-lens review and
    the conflict check.
- **Acceptance criteria:**
  - [ ] `react.md` names `aid-plan`, `aid-execute`, `Assumed` and the three-attempt stop (MP-02); `reviewer-brief.md` has `### What to report` and both modes.
  - [ ] SS-13 passes where the test step puts it, and the site `npm test` passes after regeneration.

### task-265: aid-monitor-pipeline reference: CLOSE [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-256, task-258.
- **Source:** AC-36.
- **Scope:**
  - Create `canonical/skills/aid-monitor-pipeline/references/close.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 008 `##### 2. Flow`, step 8): the write-back offer before
    anything is removed (`work_folders: delete` and a ticket source); `--pipeline --field Lifecycle --value Completed`;
    leaving the worktree (`ExitWorktree`, or one line); `close-work.sh` by mode, `--move-to-main` for a review work's
    ledger; the leftovers question (`cleanup-classify.sh --root`); one closing line, which may name the pull command
    for the user to run.
  - Suites to update in this same task: `test-never-merges.sh` NM-01 gains the instruction-only exception for this
    file's one line naming `git pull` (F008 § 8, NM-01 as narrowed; G11).
- **Acceptance criteria:**
  - [ ] `close.md` names `close-work.sh`, `cleanup-classify.sh` and `Completed` (MP-02), and runs no `git pull`.
  - [ ] `test-never-merges.sh` passes live with the one exception, and the site `npm test` passes after regeneration.

### task-266: aid-monitor-pipeline SKILL.md, its guide line and its lists [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-262, task-263, task-264, task-265.
- **Source:** AC-14, AC-21, AC-36.
- **Scope:**
  - Create `canonical/skills/aid-monitor-pipeline/SKILL.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout`,
    `##### 2. Flow` and `##### 4. Components`): the step table START, COLLECT, PUSH, PARENT, REVIEW, REACT, WATCH and
    CLOSE, with only START's `**Advance:**` having a `PASS`; `skill-steps.md` and `question-protocol.md` cited; the
    spec's `description:` and `argument-hint`; the plan-mode check as one line.
  - **Lists and counts that follow a new skill**, in this same task: its `canonical/aid/rules.md` § Skill guide line
    with the spec's text; its `description:` (not SG-04-exempt); a `skill:aid-monitor-pipeline` row in
    `tests/conversation/deferred.tsv` until task-283's samples cover it (DT-01, SS-09); the site skill lists and
    their `__tests__`.
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
- **Acceptance criteria:**
  - [ ] `SKILL.md` exists, at most 120 lines, with the eight steps, and only START's `**Advance:**` names `PASS` (MP-01).
  - [ ] SG-02, SG-04, DT-01 and SS-09 pass where the test step puts them, `test-doc-counts.sh` passes live with the skill count raised by one, and the site `npm test` passes after `sync:docs` and regeneration.

### task-267: Contracts for the CI phase: approvals, the gate's row 1, the publish seam, the worktree teardown [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-254.
- **Source:** AC-11, AC-36.
- **Scope:**
  - `canonical/aid/templates/skill-steps.md` § When approvals happen: the conflict-merge row; the never-merges
    sentence narrowed as AC-11 now reads (Q85) (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, Approvals).
  - `canonical/aid/templates/work-initiation-gate.md` § 3b row 1: a work folder committed on a branch other than its
    own, with no registered worktree on its own branch, counts as finished (Q95); without git the rule does not apply.
  - `canonical/aid/templates/connectors/consumption-protocol.md`: the wired-seam row for `aid-monitor-pipeline` (role
    *publish*); the header's reads-only sentence scoped to ticket seams (Q93).
  - `canonical/aid/templates/worktree-lifecycle.md` § Step 3 and the header of `worktree-lifecycle.sh`: the
    `aid-housekeep` teardown consumer becomes the close (`close-work.sh`).
  - Suites to update in this same task: `test-work-initiation-gate.sh` (a fixture for the merged-folder row),
    `test-worktree-lifecycle.sh`, the connector consumption suites, and any suite the findings' Y5 assigns here.
- **Acceptance criteria:**
  - [ ] `skill-steps.md` has the conflict-merge row; the gate's § 3b row 1 names a folder on another branch; `consumption-protocol.md` has the `aid-monitor-pipeline` row (MP-04's clauses).
  - [ ] A fixture work folder committed on `master` with no worktree on its own branch is shown finished by the gate's `--check` path; the suites pass where the test step puts them.

### task-268: The finishing skills pass to the close [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-266.
- **Source:** AC-14, AC-36.
- **Scope:**
  - Q96 (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout` and `##### 4. Components`, The finishing skills):
    - `aid-research`, `aid-review` and `aid-report` (each § State: DONE): the work is no longer marked done by hand;
      `PASS` to `aid-monitor-pipeline` (`--phase CI`, `--why '<skill> done'`); `aid-review`'s findings ledger is moved
      to the main folder at close;
    - `aid-deploy` `SKILL.md`, `references/state-packaging.md` and `references/state-done.md`: its finish passes to the
      close; "PR-based: create pull request" becomes "the release's pull request is opened by the close, on the
      user's yes";
    - `canonical/agents/aid-operator/AGENT.md`: the "Create pull requests" lines go.
  - Suites to update in this same task (G11): every suite asserting these files' finish or pull-request lines (for
    example `test-deploy-monitor-repurpose.sh`), and any suite the findings' Y2 or Y8 assigns here.
- **Acceptance criteria:**
  - [ ] The four skills name `aid-monitor-pipeline` in their finish and write no `Completed`; `aid-operator` names no pull-request creation (MP-05's first clause).
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-269: The interim close retired, and Building's calls named [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-263, task-266.
- **Source:** AC-14, AC-42.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/size-and-route.md`: the phase table row "Every work" says CI closes
    every work through `/aid-monitor-pipeline`; the interim close minimum goes (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout`).
  - `canonical/skills/aid-kb-update/references/finish.md` and `canonical/skills/aid-execute/references/finish.md`:
    their `PASS` to the close names `aid-monitor-pipeline` with `--phase CI`; the interim lines go.
  - `canonical/skills/aid-execute/references/milestone.md`: the collect call passes `--why 'collect: <covers>'`, the push
    call `--why 'push: <commit>'`.
  - Suites to update in this same task (G11): `test-execute.sh` and `test-kb-skills.sh` where they assert these
    lines, and any suite the findings' Y2 assigns here.
- **Acceptance criteria:**
  - [ ] `aid-orchestrate`, `aid-kb-update` and `aid-execute` name no interim close (MP-05's second clause), and `milestone.md` names `collect:` and `push:`.
  - [ ] `test-execute.sh` and `test-kb-skills.sh` pass in the scratch copy, and the site `npm test` passes after regeneration.

### task-270: Every other push removed, and the housekeep and origin/master re-pointing [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-257, task-266, task-267.
- **Source:** AC-11, AC-36.
- **Scope:**
  - Every kept file under `canonical/` that still runs `git push` loses that line: the KB is committed, never pushed
    (Feature 004), and `push-approved.sh` is the only push (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout`).
  - Re-pointing (REQUIREMENTS.md § 11 Feature 008 `##### 7. Migration`): every kept file under `canonical/`, and `dashboard/home.html`, that names
    `housekeep/cleanup-classify.sh`, the `aid-housekeep` teardown, `origin/master` as a merge target, or the interim
    `/aid-orchestrate` close.
  - Suites to update in this same task: any suite the findings' Y1 or Y3 assigns to these files.
- **Acceptance criteria:**
  - [ ] Over `canonical/` (except `pipeline/push-approved.sh`, the comment and quoted-pattern lines of the two safety self-checks, and the one instruction line of `aid-kb-build/references/finish.md`), `git grep -nE '^[^#]*git push'` finds nothing (NM-05, scoped to hold at this task's end).
  - [ ] Over `canonical/` and `dashboard/home.html`, `git grep -nE 'housekeep/cleanup-classify|origin/master'` finds nothing (MP-05's last clause). The suites pass where the test step puts them.

### task-271: delete-pipeline.sh without --force [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-254.
- **Source:** AC-34, AC-36.
- **Scope:**
  - `dashboard/scripts/delete-pipeline.sh` (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout`): its `git worktree remove --force` loses
    `--force`; for a dedicated worktree, in order: (1) a locked worktree or an uncommitted change outside this work's
    folder exits 3 and touches nothing; (2) only this work's folder changes are discarded (`git checkout --` and
    `git clean -fdq --` scoped to `.aid/works/<work_id>`); (3) `git worktree remove` without force. The main and shared
    cases keep today's folder-only removal.
  - `tests/canonical/test-delete-pipeline.sh`, in this same task: unit 8 (a committed folder) exits 0 with the worktree
    gone and the branch kept; unit 12 (a locked worktree) exits 3 with everything in place; a new unit, another
    uncommitted file in the worktree, exits 3 with everything in place.
- **Acceptance criteria:**
  - [ ] `grep -n -- '--force' dashboard/scripts/delete-pipeline.sh` prints nothing.
  - [ ] `test-delete-pipeline.sh` passes live with units 8, 12 and the new unit.

### task-272: Dashboard readers and server: the pull request and merged work folders [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-259.
- **Source:** AC-36, AC-41.
- **Scope:**
  - Both readers and the server, kept equal by the parity tests (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, Dashboard and Merged work
    folders): `pull_request` read and passed on by `_ser_work` and `reader.mjs`; `feedback` counted by state;
    `merged_in` computed (`yes` for a work folder committed on a branch other than its own with no registered
    worktree on its own branch, read with `git rev-parse --abbrev-ref HEAD` and `git ls-files`), such a work shown
    done; without git the rule does not apply.
  - The page is task-273. New fixtures are task-278.
  - Suites to update in this same task: the existing reader, server and parity suites and fixtures, and any suite the
    findings' Y4 assigns here.
- **Acceptance criteria:**
  - [ ] A scratch work folder committed on `master` with no worktree on its own branch reads `merged_in: yes` and done in both readers; a running work in its worktree reads `merged_in: no`.
  - [ ] The parity suites pass where the test step puts them.

### task-273: Dashboard page: the CI card lines [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-270, task-272.
- **Source:** AC-41.
- **Scope:**
  - `dashboard/home.html` (REQUIREMENTS.md § 11 Feature 008 `##### 4. Components`, Dashboard): at CI, "Pull request #42 -- pipeline passing" (or
    running, failing) with its link; "2 review comments being corrected"; "Waiting for your answer (N)" for `Asked`
    entries; "Waiting for the merge -- merging is yours" at an idle watch; "Can't reach GitHub -- needs your help" while
    a `Connection` question is open; "Pull request not created yet" while paused at START. No step names.
  - Suites to update in this same task: `dashboard/server/tests/test_index_html.py`.
- **Acceptance criteria:**
  - [ ] `home.html` holds each card text verbatim, and `python3 -m pytest dashboard/server/tests/test_index_html.py` passes.

### task-274: test-push-approved.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-255, task-259.
- **Source:** AC-35, AC-42.
- **Scope:**
  - Create `tests/canonical/test-push-approved.sh` with every case of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`, on throwaway repositories
    with a local bare repository as the remote, the first-push case included. It has `# COVERS:` lines.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-274`.
- **Acceptance criteria:**
  - [ ] The suite passes, with a named assertion for each listed case.
  - [ ] It is deterministic, needs no network, cleans up and pins `HOME`.

### task-275: test-merge-parent.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-256.
- **Source:** AC-11.
- **Scope:**
  - Create `tests/canonical/test-merge-parent.sh` with every case of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`. It has `# COVERS:`
    lines.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-275`.
- **Acceptance criteria:**
  - [ ] The suite passes, with a named assertion for each listed case.
  - [ ] It is deterministic, needs no network, cleans up and pins `HOME`.

### task-276: test-close-work.sh, and the cleanup-classify cases [TEST]

- **Stanza wave:** 5. **Depends on:** task-257, task-258.
- **Source:** AC-36.
- **Scope:**
  - Create `tests/canonical/test-close-work.sh` with every case of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`. It has `# COVERS:` lines.
  - The `cleanup-classify.sh` suites gain the YAML signals, the parent-branch comparison (a parent other than
    `master`) and `--work`.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-276`.
- **Acceptance criteria:**
  - [ ] Both suites pass, with a named assertion for each listed case.
  - [ ] They are deterministic, need no network, clean up and pin `HOME`.

### task-277: Writer unit cases: --pull-request and the duplicate ref [TEST]

- **Stanza wave:** 5. **Depends on:** task-259.
- **Source:** AC-42.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains (REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`): the `--pull-request` fields and
    refusals; a repeated `--feedback-add` ref writes nothing, in both writers; every file written parses through the
    dashboard reader with no warning.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-277`.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-278: Dashboard cases: draft, failing pipeline, idle watch, connection, merged-in folder [TEST]

- **Stanza wave:** 5. **Depends on:** task-272, task-273.
- **Source:** AC-36, AC-41.
- **Scope:**
  - Add to the dashboard tests (REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`, Dashboard): fixtures for a work at CI with a draft, an open
    pull request with a failing pipeline, an idle watch, a `Connection` question, and a merged-in work folder
    (`merged_in: yes`, shown done); `test_index_html.py` for the card lines; the parity tests.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-278`.
- **Acceptance criteria:**
  - [ ] Both readers give the same result for every fixture, and the parity tests pass.
  - [ ] `test_index_html.py` asserts each card line, and passes.

### task-279: test-never-merges.sh: NM-01 narrowed, NM-03 with no exemption, NM-05 and NM-06 [TEST]

- **Stanza wave:** 5. **Depends on:** task-255, task-256, task-258, task-265, task-268, task-270, task-271.
- **Source:** AC-11, AC-34, AC-36.
- **Scope:**
  - `tests/canonical/test-never-merges.sh` (REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`, Never-merges test): NM-01 as narrowed (its
    `close.md` exception came with task-265); NM-03 with no exemption; new NM-05 (an executed `git push` only in
    `push-approved.sh`, with the text-only and instruction-only exceptions) and NM-06 (`git branch -D` only in
    `close-work.sh`; no `git worktree remove --force` anywhere).
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-279`.
- **Acceptance criteria:**
  - [ ] The suite passes live.
  - [ ] Each new check fails its own mutation in a scratch copy: a `git push` in a skill reference; a forced push in `push-approved.sh`; `git branch -D` in another script; `--force` back in `delete-pipeline.sh`.

### task-280: test-monitor-pipeline.sh (MP-01 to MP-05) [TEST]

- **Stanza wave:** 5. **Depends on:** task-259, task-260, task-266, task-267, task-268, task-269, task-270.
- **Source:** AC-11, AC-13, AC-27, AC-36.
- **Scope:**
  - Create `tests/canonical/test-monitor-pipeline.sh` with MP-01 to MP-05, as REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing` defines them. It
    has `# COVERS:` lines.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-280`.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy.
  - [ ] Each check fails its own mutation in a scratch copy: a missing `watch.md`; a `PASS` on another step's `**Advance:**`; `push.md` without `push-approved.sh`; `gh pr merge` in `hosts.md`; the template without `pull_request`; `aid-research` writing `Completed`.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-281: Samples 008-01 to 008-07 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-261, task-266, task-268, task-269, task-270.
- **Source:** AC-11, AC-27, AC-28, AC-42.
- **Scope:**
  - Create under `tests/conversation/samples/feature-008/`, with frontmatter `skills: aid-monitor-pipeline`, fixtures (a
    small project with code, a test suite and a local bare remote; the stand-ins copied into `bin/`, answering from
    `host.json`) and the checks of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`: `008-01` to `008-07`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-281`.
- **Acceptance criteria:**
  - [ ] There are seven files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-282: Samples 008-08 to 008-14 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-281.
- **Source:** AC-13, AC-14, AC-27, AC-35, AC-36.
- **Scope:**
  - Create `008-08` to `008-14` under `tests/conversation/samples/feature-008/`, as task-281 does, with the checks of
    REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-282`.
- **Acceptance criteria:**
  - [ ] There are seven files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-283: Samples 008-15 to 008-18, and the deferred rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-282.
- **Source:** AC-13, AC-27, AC-35, AC-36, AC-42.
- **Scope:**
  - Create `008-15-live-hosts`, `008-16`, `008-17` and `008-18` under `tests/conversation/samples/feature-008/`, with the
    checks of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`.
  - Update `tests/conversation/deferred.tsv`: the `skill:aid-monitor-pipeline` row task-266 added goes; the rows of
    `002-10` and `007-13` go (they run at this gate); `008-15` gets a row waiting for the integration run before
    release (delivery-014).
  - Smoke run (Q134 D8): `008-16` to `008-18`, `002-10` and `007-13` once each, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` assigns to `task-283`.
- **Acceptance criteria:**
  - [ ] There are four new files; `008-15` has its `deferred.tsv` row; DT-01 and SS-09 pass with no `skill:aid-monitor-pipeline`, `002-10` or `007-13` row left.
  - [ ] Each smoke run has its result reported.

### task-284: The four new suites in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-274, task-275, task-276, task-280.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-monitor-pipeline`,
    `test-push-approved`, `test-merge-parent` and `test-close-work`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's text.
- **Acceptance criteria:**
  - [ ] Each name appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-285: KB decisions, schemas, glossary and tech debt for the CI phase [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-259, task-260, task-270.
- **Source:** AC-11, AC-35, AC-36.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 008 `##### 7. Migration`, KB): `decisions.md` gains "the CI phase ends
    at a person's merge: AID pushes only approved work, merges only the parent branch into the work branch to resolve
    a conflict, cleans up locally and never deletes a remote branch"; `artifact-schemas.md` (`pull_request`,
    `work_folders`, the `feedback` states); `domain-glossary.md` (pull request phase, parent branch, close, conflict
    merge, work-folder setting); `tech-debt.md` (SY-1 resolved).
  - No retired skill: nothing joins the old -> new table (AC-24).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] The new decision is in the summary table and its section, and SY-1 leaves no trace in `tech-debt.md`.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-286: KB architecture, contracts and integration documents for the CI phase [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-266, task-270, task-271.
- **Source:** AC-11, AC-13, AC-36.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 008 `##### 7. Migration`, KB): `pipeline-contracts.md` (the CI phase
    contract and its steps); `architecture.md` (the CI row; the only merge AID makes); `integration-map.md` (GitHub
    and GitLab through the plug-in or `gh` / `glab`; the push); `capability-inventory.md`, `module-map.md`,
    `project-structure.md` (the `pipeline/` scripts).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'housekeep/cleanup-classify|origin/master'` finds nothing, and `project-structure.md` names `canonical/aid/scripts/pipeline/`.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-270 leaves it.

### task-287: KB test landscape for the CI suites, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-277, task-278, task-279, task-283, task-284, task-285, task-286.
- **Source:** AC-25, AC-36.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-monitor-pipeline.sh`, `test-push-approved.sh`, `test-merge-parent.sh` and
    `test-close-work.sh` and their lane; NM-05 and NM-06; the stand-ins; the housekeep suites under their new subject.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync changes no
    KB document.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names the four new suites and their lane.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-monitor-pipeline`: eight steps, eleven references with `connect.md` and `hosts.md`, the brief | 262-266 |
| `push-approved.sh`, `merge-parent.sh`, `close-work.sh`; `cleanup-classify.sh` moved, reading YAML | 255, 256, 258; 257 |
| Writer `--pull-request` and the duplicate `ref`, with the fork; the `pull_request` key; `work_folders: push` | 259; 260 |
| The conflict-merge row; the gate's row 1 (merged work folders); the publish seam; the worktree teardown | 267 |
| The finishing skills, `aid-operator`; the interim close gone; `milestone.md`'s calls; every other `git push` gone | 268; 269; 270 |
| `delete-pipeline.sh` without `--force`; the dashboard CI card | 271; 272, 273 |
| `test-monitor-pipeline.sh`, `test-push-approved.sh`, `test-merge-parent.sh`, `test-close-work.sh`; the stand-ins; NM-01, NM-03, NM-05, NM-06; `SUITES` | 280, 274, 275, 276; 261; 256, 265, 279; 284 |
| Samples `008-01` to `008-14`, `008-16` to `008-18` (run), `002-10`, `007-13` run now, `008-15` waiting for the integration run | 281, 282, 283 |
| G0: KB documents; `INDEX.md`; `kb.html` (no AC-24 row: no skill retires) | 285, 286, 287 |

**Steps that are not tasks** (PLAN.md, How deliveries 010-014 are built; the switch rows). Task-287 carries them
in its "Gate-session steps" block (G13):
1. **The run.** `/aid-execute` resumes this work at `START`: `--check` passes, the confirmation is recorded (the
   Q123 approval), it asks only the wave question ("No stop per wave") and records the full-suite baseline as
   `not taken`. Then the tasks, DELIVERY, and MILESTONE's collect and corrections (no pull request yet). The
   MILESTONE approval question is written `Pending` with `--ask`, and the run pauses there.
2. **The resync session** (resync rule 1): `delivery-010: resync`, committed alone; the session ends.
3. **The gate session** (resync rule 2):
   - before resuming `/aid-execute`: `full-suite.sh` saved in the work folder and committed alone, then recorded with
     `--full-suite --field Command --value 'bash .aid/works/work-003-full-aid-restructure/full-suite.sh'`;
   - **after the resync (G8, resync rule 6):** `derive-waves.sh --plan --check` on this work, with `--plan` when
     stale; `(cd site && npm run gen:reference)` and the site `npm test`, a no-op unless the resync changed
     `.aid/settings.yml`; the KB is not changed by this resync, so `INDEX.md` and `kb.html` stay as task-287 left
     them;
   - the stanza's criteria, the samples (`008-01` to `008-14`, `008-16` to `008-18`, `002-10`, `007-13`, `001-16`, each
     3 of 3) and G0 on the head, except G0's lane item;
   - then `/aid-execute` resumes and asks the open approval first: a yes is recorded with `--answer --commit
     <head>`, and the push question follows -- the first one, "Create or update the pull request now?"; a yes opens
     the draft v4.0.0 pull request through `/aid-monitor-pipeline` and starts G0's lane check. A failed gate or a
     change asked becomes correction tasks, and the resync and gate sessions repeat.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-254
wave 2: task-255, task-256, task-257, task-259, task-260, task-261, task-267, task-271
wave 3: task-258, task-262, task-263, task-264, task-272, task-274, task-275, task-277
wave 4: task-265, task-276
wave 5: task-266
wave 6: task-268, task-269, task-270
wave 7: task-273, task-279, task-280, task-281, task-285, task-286
wave 8: task-278, task-282, task-284
wave 9: task-283
wave 10: task-287
```

Step 5 writes the table under `### delivery-010 Execution Graph`, one task per row, from the task files'
`**Depends on:**` lines.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The Execution protocol note in the task files of deliveries 010-014. | Feature 006's `task-detail-template.md` note, word for word, naming the writer and no file, with the task's id in place of `NNN`. | Settled by recommendation (Q136, follows F006's template); the maintainer's answer to the delivery-009 flag. |
| S2 | The test step under the new builder. | `BASE` is the task's recorded `base`; the same failure after three fix rounds is a real blocker. The scratch-half and live-half split stays. | F007 Flow (BUILD's `base`; TEST's M7 limit); PLAN.md "Testing before the resync". |
| S3 | `aid-monitor-pipeline`'s eleven references and `SKILL.md`. | Four tasks write the references, unreferenced until task-266 writes `SKILL.md` and adds the skill's lists. | One session per task. |
| S4 | NM-01's `close.md` exception and KB-03's use by `parent.md`. | Each in the task that writes the file that needs it (265, 263); NM-05 and NM-06 come with task-279. | G11. |
| S5 | The new skill's sample coverage before its samples exist. | A temporary `skill:aid-monitor-pipeline` row in `deferred.tsv` (266), removed by task-283. | DT-01, SS-09. |
| S6 | The stand-ins. | A TEST task of their own (261), before the samples. | F008 § 8. |
| S7 | `008-15` needs the live hosts. | Written with a `deferred.tsv` row waiting for the integration run before release (delivery-014). | F008 § 7, Lists; PLAN delivery-014. |
| S8 | `kb.html` and `INDEX.md`. | Rendered in task-287: the resync changes no KB document. | G0, G8. |
| S9 | Unit cases, samples, the CI lane and the test landscape. | As in the earlier deliveries. | Q134 D2, D8; Q135 R1, R3. |

---

## 7. Flagged for the maintainer

None.
