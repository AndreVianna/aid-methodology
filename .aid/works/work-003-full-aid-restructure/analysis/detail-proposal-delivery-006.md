# Detail proposal -- delivery-006: The KB grows and stays current (Feature 004, second part)

This is `aid-detail` FIRST-RUN for **delivery-006**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-006/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-005's task-139.
- **General rules.** The rules G1-G6 from the light reviews of deliveries 001-004 apply from the start.

**Inputs read:**
- the delivery-005 and delivery-006 stanzas of `PLAN.md` (Q117 split of Feature 004), Common Gate G0,
  "Testing before the resync" and "Toolchain and Branching";
- `REQUIREMENTS.md` § 11 Feature 004 (all eight subsections);
- the delivery-001 to delivery-005 task files, for what they leave to this delivery.

**Measured at base `ea753c7b`** (the task files of deliveries 001-005 describe the tree this delivery starts
from; task-140 re-measures):
- The 14 KB `create`/`update` skills are single hand-authored `SKILL.md` files, each a `repurpose: true`
  row of `shortcut-catalog.yml`. Outside themselves and the design skills delivery-004 retires, they are
  named by `aid-config`'s `knowledge` row and by the catalog. `design-lifecycle.md` is cited only by them
  (after delivery-004).
- `worktree-lifecycle.sh` defaults `--base` to `master` (line 538).
- `canonical/aid/templates/knowledge-base/` holds 14 templates; `test-kb-template-authoring-standard.sh`
  AS06 counts them. `synth_default_seed` emits only the files its ownership map names.
- No KB document carries `approved_at_commit:`.
- `git worktree list` registers the main folder (`master`, no works) and the `work-003` worktree.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-140 | Delivery-006 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-141 | worktree-lifecycle.sh: new works branch from the main folder's checked-out branch | IMPLEMENT | 2 | 2 | task-140 |
| task-142 | Writer --create --parent-branch, and the work-state key pipeline.parent_branch | IMPLEMENT | 2 | 2 | task-140 |
| task-143 | kb-commit.sh --new-project | IMPLEMENT | 2 | 2 | task-140 |
| task-144 | KB document templates roadmap.md (with its MVP section) and backlog.md | IMPLEMENT | 2 | 2 | task-140 |
| task-145 | aid-kb-update: new-document.md and START's removed-KB check | IMPLEMENT | 2 | 3 | task-142, task-144 |
| task-146 | The gate's new-project step and parent branch, and the new-project route | IMPLEMENT | 3 | 3 | task-141, task-142, task-143 |
| task-147 | aid-orchestrate: the drift check at work start, and the next backlog item | IMPLEMENT | 3 | 3 | task-144 |
| task-148 | Format 6: the baselines step, in bash and PowerShell | IMPLEMENT | 3 | 2 | task-140 |
| task-149 | Format 6: the parent-branch step, in bash and PowerShell | IMPLEMENT | 3 | 3 | task-142, task-148 |
| task-150 | The gate's legacy row for old works of the KB create/update skills | IMPLEMENT | 4 | 4 | task-145, task-146 |
| task-151 | The 14 KB create/update skills and design-lifecycle.md retired | IMPLEMENT | 4 | 5 | task-144, task-145, task-147, task-150 |
| task-152 | Unit cases: the parent branch (Q60) | TEST | 5 | 3 | task-141, task-142 |
| task-153 | Unit case: test-kb-commit.sh --new-project | TEST | 5 | 3 | task-143 |
| task-154 | Unit cases: test-kb-state-migration.sh, baselines and parent branch | TEST | 5 | 4 | task-148, task-149 |
| task-155 | test-kb-skills.sh group K2 | TEST | 5 | 6 | task-144, task-146, task-147, task-151 |
| task-156 | Samples 004-05, 004-06, 004-08 and 004-09 (run at this gate), and 003-11's row | TEST | 5 | 6 | task-147, task-151 |
| task-157 | Samples 004-10, 004-11 and 004-12 (deferred) and their deferred rows | TEST | 5 | 7 | task-146, task-156 |
| task-158 | KB conventions, roadmap, backlog, schemas and tech debt for the growing KB | DOCUMENT | 4 | 6 | task-142, task-144, task-148, task-151 |
| task-159 | KB architecture and navigation documents for the growing KB | DOCUMENT | 4 | 6 | task-146, task-147, task-149, task-151 |
| task-160 | KB test landscape for the growing KB, and the regenerated index | DOCUMENT | 5 | 8 | task-152, task-153, task-154, task-155, task-156, task-157, task-158, task-159 |

That is 21 tasks. The resync follows task-160. Its `aid update` back-fills this repository's KB baselines and
fills `pipeline.parent_branch` for this work; `INDEX.md` and `kb.html` are then rendered (§ 4, S7).

---

## 2. Rules every task carries

Each task file carries the blocks of delivery-005:

- the Execution protocol;
- the same-task rule (Q106) and its ledger rows;
- the findings bullet (`research/delivery-006-sites.md`);
- the standard test step, with step 5's site `npm test` for any change under `canonical/skills/`,
  `canonical/agents/` or `canonical/aid/templates/` (G5);
- **for every IMPLEMENT task:**
  - site regeneration, including the generators' hard-coded counts (G1);
  - the hand check of later static patterns over its own files (G3);
- **for the deletion task (151):** the suites that read what it removes, from a grep of its path and
  folder (G6);
- **in the research task:** the "baseline, re-recorded at the gate" owner class, and a skill owner table
  built from a full listing (G2).

Every needed order is a dependency edge (G4). Two tasks that edit the same function or file in one wave are
ordered by an edge: task-149 after task-148 (`_aid_migrate_repo`'s CONVERT-STATE step), task-150 after
task-146 (`work-initiation-gate.md`), task-157 after task-156 (`deferred.tsv`).

---

## 3. Tasks

`Source` reads `feature-004-kb-management -> delivery-006 -> AC-...`.

### task-140: Delivery-006 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-15, AC-18, AC-25, AC-39.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-006-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout` and `##### 7. Migration`):
    - **R1** the 14 KB `create`/`update` skills (`aid-create-*` and `aid-update-*` for `architecture`,
      `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog` and `mvp`) and `design-lifecycle.md`, over
      every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`, `.github/` and
      `.aid/knowledge/`;
    - **R2** the rows and comments of `shortcut-catalog.yml` that name those skills, and every suite or site
      test that counts catalog rows, `repurpose: true` rows, doorways or skills
      (`test-deploy-monitor-repurpose.sh` DMR33, `test-catalog-dirs-parity.sh`, `test-shortcut-builder-invariants.sh`
      SBI05, `test-doc-counts.sh`, the site's skill-count tests);
    - **R3** the rows of `tests/canonical/skill-steps-exempt.tsv` whose owner is Feature 004, the SG-04
      exempt rows of `test-skill-guide.sh`, and the rows of `tests/conversation/deferred.tsv` that name a
      retiring skill, `003-11` or a Feature 004 sample;
    - **R4** the Q60 sites: `master` and `--base` in `worktree-lifecycle.sh`, `worktree-lifecycle.md` and
      `work-initiation-gate.md` § 3a; every caller of `worktree-lifecycle.sh create`; every reader of
      `pipeline.parent_branch`;
    - **R5** the new-project sites: `type: greenfield`, the callers of `recon-classify.sh`, the `Growing`
      case of `aid-kb-show`, the rows of `size-and-route.md`, and the modes `kb-commit.sh` has;
    - **R6** the drift and baseline sites: the callers of `kb-freshness-check.sh`, the writers of
      `approved_at_commit:` (`migrate-kb-frontmatter.sh` among them), and the CONVERT-STATE step's KB step
      in `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1`;
    - **R7** the readers of `backlog.md` and `roadmap.md` under `canonical/`, and every consumer of
      `canonical/aid/templates/knowledge-base/` (`synth_default_seed`, `domain-doc-matrix.md`, the site
      reference manifest, `test-kb-template-authoring-standard.sh` AS06);
    - **R8** the Q106 suite map for every file on the edit list, including the dashboard tests and the
      site's skill lists.
  - Give each hit exactly one owner:
    - a task of delivery-006 (task-141 to task-160; see
      `.aid/works/work-003-full-aid-restructure/analysis/detail-proposal-delivery-006.md`);
    - "Feature 009 (delivery-012)" for the dashboard readers' legacy skill maps, which Feature 009 puts
      inside `legacy-skill-names` markers;
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
  - [ ] Each of R1-R8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-141: worktree-lifecycle.sh: new works branch from the main folder's checked-out branch [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-140.
- **Source:** AC-15, AC-18.
- **Scope:**
  - `canonical/aid/scripts/works/worktree-lifecycle.sh` (Q60; REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`):
    - `create` without `--base` takes the branch checked out in the main folder (the first entry of
      `git worktree list`), not `master`;
    - with no branch checked out there (a detached head), it says so in one plain line, exits 2, and creates
      no branch and no worktree;
    - `--base <ref>` keeps working as today;
    - the header, the usage text and every comment that names `master` as the default follow.
  - `canonical/aid/templates/worktree-lifecycle.md`: its `master` lines name the main folder's checked-out
    branch.
  - `work-initiation-gate.md` § 3a, which runs `create`, is task-146's. The Q60 unit cases are task-152.
  - Suites to update in this same task: the existing `test-worktree-lifecycle.sh` assertions that assume a
    `master` default, and any suite the findings' R4 or R8 assigns here (for example
    `test-downstream-worktree-entry.sh`, where it asserts these lines).
- **Acceptance criteria:**
  - [ ] On a scratch repository with `master` and a branch `dev` checked out in the main folder, `create` without `--base` makes a worktree whose first commit is `dev`'s tip. On a detached head it exits 2, and `git worktree list` and `git branch` are unchanged.
  - [ ] `grep -nE 'BASE_REF="master"|default: master|off master' canonical/aid/scripts/works/worktree-lifecycle.sh canonical/aid/templates/worktree-lifecycle.md` prints nothing.
  - [ ] `test-worktree-lifecycle.sh` passes live.

### task-142: Writer --create --parent-branch, and the work-state key pipeline.parent_branch [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-140.
- **Source:** AC-15, AC-18.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 004 `##### 2. The KB state file`, The work's parent
    branch):
    - `--create` takes `--parent-branch <branch>` and writes it to `pipeline.parent_branch`. The value is a
      branch name that passes `git check-ref-format --branch`, or `--` (no git). Anything else exits 4 and
      writes nothing;
    - `--create` without `--parent-branch` writes `--`;
    - no other mode writes `pipeline.parent_branch`: it is written once and never changed;
    - the header documents the flag.
  - `canonical/aid/templates/work-state-template.yml`: `pipeline.parent_branch: --` with its `[W]` comment,
    in block style.
  - Both dashboard readers (`dashboard/reader/` and `dashboard/server/reader.mjs`) accept the key with no
    warning. They do not display it.
  - The gate's call with `--parent-branch` is task-146's. The unit cases are task-152.
  - Suites to update in this same task: the existing `test-writeback-state.sh` and `test-work-state-template.sh`
    assertions, `test-skill-steps.sh` SS-08 where it reads the template, the dashboard parity tests, and any
    suite the findings' R4 or R8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work, `--create ... --parent-branch dev` writes `pipeline.parent_branch: dev`, and `--parent-branch 'a..b'` exits 4 with the file not created.
  - [ ] The template parses through `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs` with no warning, and `test-skill-steps.sh` SS-08 passes in the scratch copy.
  - [ ] `test-writeback-state.sh` and `test-work-state-template.sh` pass where the test step puts them.

### task-143: kb-commit.sh --new-project [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-140.
- **Source:** AC-18.
- **Scope:**
  - `canonical/aid/scripts/kb/kb-commit.sh` gains `--new-project --message M` (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`,
    `kb-commit.sh`):
    - it commits `.aid/settings.yml` and `.aid/knowledge/`, and nothing else: `git add -- <paths>`, then
      `git commit --only -- <paths>`, so other staged files stay staged;
    - it takes no `--with-settings`, `--build` or `--finish` (exit 2);
    - its exits are those of the other modes (0, 2, 3, 4, 6), and it never pushes;
    - the header documents the mode.
  - The unit case is task-153.
  - Suites to update in this same task: the existing `test-kb-commit.sh` assertions, where one asserts that
    `--new-project` is refused, and any suite the findings' R5 or R8 assigns here.
- **Acceptance criteria:**
  - [ ] In a scratch repository with another file staged, `kb-commit.sh --new-project --message m` commits exactly `.aid/settings.yml` and the files under `.aid/knowledge/`, and the other file is still staged.
  - [ ] `--new-project --build` exits 2 and commits nothing. `grep -c 'git push' canonical/aid/scripts/kb/kb-commit.sh` prints 0.
  - [ ] `test-kb-commit.sh` passes live.

### task-144: KB document templates roadmap.md (with its MVP section) and backlog.md [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-140.
- **Source:** AC-39.
- **Scope:**
  - Create `canonical/aid/templates/knowledge-base/roadmap.md` and `backlog.md`, type `template-payload`
    (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout` and `##### 5. Components`, Roadmap, backlog and MVP):
    - `roadmap.md` takes its shape from `aid-create-roadmap` (frontmatter, title, preamble, `## Contents`,
      `## Now`, `## Next`, `## Later`) and carries the `## MVP` section itself: the MVP is a section of the
      roadmap (Q16), with no skill of its own;
    - `backlog.md` takes its shape from `aid-create-backlog`, including how an item is ordered and how it is
      updated once the work that took it is built (Feature 007 reads that rule);
    - both follow the seed-template standard (frontmatter with `kb-category` and `intent`, `## Contents`, no
      change log, no work id, no diagram fence).
  - Neither template enters the default document set: `synth_default_seed`'s ownership map and
    `domain-doc-matrix.md`'s default rows stay as they are. A KB gains these documents only when
    `/aid-kb-update` records a fact in them (FR-10, FR-14).
  - Suites to update in this same task: `test-kb-template-authoring-standard.sh` (AS06's template count and
    its header), the site reference generator's manifest and its `__tests__`, and any suite the findings' R7
    or R8 assigns here (for example `test-domain-doc-matrix.sh` and `test-doc-set-read.sh`, where they count
    the templates).
- **Acceptance criteria:**
  - [ ] Both files exist; `roadmap.md` has a `## MVP` heading and `backlog.md` exists (KB-07). `test-kb-template-authoring-standard.sh` passes live with AS06 counting both.
  - [ ] `synth_default_seed` and `domain-doc-matrix.md` name neither file (`grep -cE 'roadmap\.md|backlog\.md'` over both prints 0, or only the counts the findings' R7 recorded at the base).
  - [ ] The site `npm test` passes after `gen:reference`.

### task-145: aid-kb-update: new-document.md and START's removed-KB check [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-142, task-144.
- **Source:** AC-15, AC-18, AC-39.
- **Scope:**
  - Create `canonical/skills/aid-kb-update/references/new-document.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 004 `##### 3. Flows`,
    `/aid-kb-update` step 4):
    - a fact whose document does not exist yet: the document is created from
      `.aid/runtime/templates/knowledge-base/<doc>.md` when a template exists, or else with the fields
      `kb-authoring/frontmatter-schema.md` requires;
    - the document is chosen by the concern model (`kb-authoring/concern-model.md`);
    - it is registered in `.aid/settings.yml` `knowledge.doc_set` and in `README.md`, as the retiring
      `create` skills' register step does today, and the commit passes `kb-commit.sh --with-settings`;
    - in a new project (`Growing`), the skeleton already exists, so this only adds documents.
  - `references/apply.md` and the `SKILL.md` step table's APPLY row name `new-document.md` for a new document.
  - `references/start.md`, the own-job no-KB case (Q60): when `.aid/knowledge/STATE.yml` exists at
    `git merge-base <work branch> <pipeline.parent_branch>`, the agent says the KB was removed since the work
    began and offers to cancel the work. Otherwise, and with `pipeline.parent_branch: --`, it keeps task-117's
    "not built yet" path.
  - Suites to update in this same task: every suite the findings' R8 assigns to these files (for example
    `test-update-kb-scope-fidelity.sh`, where it reads `apply.md`).
- **Acceptance criteria:**
  - [ ] `new-document.md` exists, is at most 120 lines, and names `knowledge-base/`, `frontmatter-schema.md`, `concern-model.md`, `knowledge.doc_set`, `README.md` and `--with-settings`.
  - [ ] `apply.md` and the `SKILL.md` APPLY row name `new-document.md`. `start.md` names `merge-base` and `pipeline.parent_branch`, and both no-KB paths.
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-146: The gate's new-project step and parent branch, and the new-project route [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-141, task-142, task-143.
- **Source:** AC-15, AC-18.
- **Scope:**
  - `canonical/aid/templates/work-initiation-gate.md` § 3a (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`, A new project):
    - **The new-project step**, before § 3a creates the worktree, when the main folder has no
      `.aid/knowledge/STATE.yml` and `recon-classify.sh` finds no code. Working in the main folder, it:
      - sets `type: greenfield` in `.aid/settings.yml`, as `/aid-config` writes that key;
      - makes the KB skeleton: `writeback-state.sh --kb --field Status --value Growing`, a `README.md` with
        an empty completeness table, and an `INDEX.md` from `build-kb-index.sh`, both holding no document;
      - commits them with `kb-commit.sh --new-project`, and pushes nothing;
      - without git, makes the skeleton in place and commits nothing.
      A project with code and no KB gets no skeleton (the build is offered, Feature 001).
    - **The parent branch** (Q60): § 3a reads the main folder's checked-out branch, passes it to
      `--create --parent-branch <branch>` (`--` without git), and runs `worktree-lifecycle.sh create` with no
      `--base`.
  - `canonical/skills/aid-orchestrate/references/size-and-route.md`: the new-project row
    ("A new project (no code, no KB)": no Preparation; the gate's new-project step commits the skeleton, and
    the KB grows through `/aid-kb-update`), and the new-project case before its `--create` (REQUIREMENTS.md § 11 Feature 004
    `##### 5. Components`, `/aid-orchestrate`).
  - `canonical/skills/aid-kb-show/SKILL.md`: its `Growing` case (written by task-119) is checked against the
    skeleton this step makes. It is edited here only if its message differs from the spec's text.
  - Suites to update in this same task: `test-work-initiation-gate.sh`, `test-kb-skills.sh` group K1 (KB-03's
    § 3a exception and KB-06), `test-skill-steps.sh` SS-14, and any suite the findings' R4, R5 or R8 assigns
    here.
- **Acceptance criteria:**
  - [ ] In § 3a, the new-project step's first line comes before the `worktree-lifecycle.sh create` line, and the step names `type: greenfield`, `--kb --field Status --value Growing`, `build-kb-index.sh` and `kb-commit.sh --new-project`. § 3a names no `git push`.
  - [ ] § 3a's `--create` line names `--parent-branch`, and its `create` line has no `--base`. `size-and-route.md` has the new-project row.
  - [ ] `test-kb-skills.sh` group K1 and `test-skill-steps.sh` pass in the scratch copy, and `test-work-initiation-gate.sh` passes where the test step puts it.

### task-147: aid-orchestrate: the drift check at work start, and the next backlog item [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-144.
- **Source:** AC-15, AC-28, AC-39.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/start-or-resume.md` gains **the drift check** (Q57; REQUIREMENTS.md § 11 Feature 004
    `##### 5. Components`, `/aid-orchestrate`), after the work's open questions and before its first new
    question:
    - **what runs:** `kb-freshness-check.sh --doc <doc> --format tsv` for each KB document `check-intent.md`
      read for this request;
    - **a `suspect` row:** one question, `category: Knowledge Base`, importance medium, with the spec's
      wording and the recommendation yes;
    - **yes:** `--handoff --to aid-kb-update --step START --why 'KB drift: <docs>' --returns yes`; the update
      runs in `sweep` mode and returns to the work's step (Q59);
    - **no:** the answer is recorded, and the same documents are not raised again in this work;
    - **`current` or `unknown`:** nothing is said;
    - **skipped** with no KB (No KB: one rule) or no git.
  - `canonical/skills/aid-orchestrate/references/check-intent.md`, **"work on the next backlog item"**
    (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`, Roadmap, backlog and MVP): it reads `.aid/knowledge/backlog.md`, names the top
    item in the agent's one-line reading, and records `backlog.md` as a work source (Feature 001's
    `sources:`, kind `document`). The top item is read by the order `backlog.md`'s template defines.
  - Suites to update in this same task: every suite the findings' R6, R7 or R8 assigns to these two files
    (for example `test-kb-freshness-check.sh`, where it lists the script's callers).
- **Acceptance criteria:**
  - [ ] `start-or-resume.md` names `kb-freshness-check.sh`, `--format tsv`, `--returns yes`, `sweep`, and the skip with no KB or no git (KB-06's drift clause).
  - [ ] `check-intent.md` names `backlog.md` and records it as a source of kind `document` (KB-06's backlog clause).
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-148: Format 6: the baselines step, in bash and PowerShell [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-140.
- **Source:** AC-15, AC-25.
- **Scope:**
  - `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the baselines step after the KB step
    (Q57; REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, Format 6, Baselines):
    - every hand-authored primary or extension KB document without `approved_at_commit:` gets
      `git log -1 --format=%H -- <doc>`. The documents are chosen as `kb-freshness-check.sh` chooses them
      (no `kb-category: meta`, no `source: generated`, not `INDEX.md`, `README.md` or the state file);
    - the key is placed where the canonical frontmatter order puts it, as `migrate-kb-frontmatter.sh` inserts
      it;
    - with no git, or a document never committed, the key stays absent;
    - a document that already carries the key is not touched, so a re-run changes nothing;
    - the step is detection-driven and runs on a repository already stamped format 6 (PLAN.md Cross-Cutting
      Risks, row 5).
  - Files: `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, whichever hold the
    step. Bash and PowerShell output are byte-identical, PowerShell 5.1-safe and ASCII.
  - `tests/windows/Test-AidInstaller.ps1` gains a baselines case (Q126).
  - The unit cases are task-154.
  - Suites to update in this same task: the existing `test-kb-state-migration.sh` cases whose fixtures hold
    KB documents in a git repository, and any migration suite the findings' R6 or R8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch git repository already at format 6, with two KB documents (one with `approved_at_commit:`, one without), the step stamps only the second with its last commit, and a second run changes nothing (`sha256sum` unchanged).
  - [ ] Bash and PowerShell give byte-identical documents for the same fixture under `pwsh`, and `test-ps51-compat.sh` and `test-ascii-only.sh` pass.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-149: Format 6: the parent-branch step, in bash and PowerShell [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-142, task-148.
- **Source:** AC-25.
- **Scope:**
  - `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the parent-branch step (Q60; REQUIREMENTS.md § 11 Feature 004
    `##### 7. Migration`, Format 6, Parent branch):
    - every work `STATE.yml`, in the main folder and in each worktree `git worktree list` registers, that has
      no `pipeline.parent_branch` or has it empty gets the branch old works were made from: `master` when a
      local `master` exists, otherwise the main folder's current branch, and `--` with no git;
    - the key is written where the template puts it (task-142);
    - a value already there is not touched, so a re-run changes nothing;
    - it runs on a repository already stamped format 6.
  - Files: as task-148. Bash and PowerShell output are byte-identical, PowerShell 5.1-safe and ASCII.
  - `tests/windows/Test-AidInstaller.ps1` gains a parent-branch case (Q126).
  - The unit cases are task-154.
  - Suites to update in this same task: any migration suite the findings' R4 or R8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch repository already at format 6, with a work in the main folder and one in a registered worktree, both get `pipeline.parent_branch: master` when `master` exists, and the main folder's branch when it does not. A work that already names a branch keeps it, and a second run changes nothing.
  - [ ] Bash and PowerShell give byte-identical `STATE.yml` files for the same fixture under `pwsh`, and `test-ps51-compat.sh` and `test-ascii-only.sh` pass.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-150: The gate's legacy row for old works of the KB create/update skills [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-145, task-146.
- **Source:** AC-37, AC-39.
- **Scope:**
  - `canonical/aid/templates/work-initiation-gate.md` § 3b legacy block gains one row (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`,
    Existing works): a work whose `pipeline.initiator` is a deleted KB `create`/`update` skill is proposed
    `/aid-kb-update` at START, `change` mode. Its old seed is found and collected with `idea-drafts.sh list` /
    `collect` (Feature 003) and read as the work's draft.
  - The row sits inside the legacy block, which KB-02 exempts.
  - `tests/canonical/test-work-initiation-gate.sh` gains a passing `--check` fixture for the row, as for
    Feature 003's legacy rows.
  - Suites to update in this same task: any suite the findings' R8 assigns to the legacy block.
- **Acceptance criteria:**
  - [ ] The legacy block has the row, naming `aid-kb-update`, `START`, `change` and `idea-drafts.sh`.
  - [ ] The new fixture, a work with `initiator: aid-create-roadmap`, is proposed `/aid-kb-update` at START, and `test-work-initiation-gate.sh` passes where the test step puts it.

### task-151: The 14 KB create/update skills and design-lifecycle.md retired [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-144, task-145, task-147, task-150.
- **Source:** AC-39.
- **Scope:**
  - Delete the 14 KB `create`/`update` skill folders under `canonical/skills/` (`aid-create-*` and
    `aid-update-*` for `architecture`, `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog` and `mvp`),
    and `canonical/aid/templates/design-lifecycle.md` (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`).
  - `canonical/aid/templates/shortcut-catalog.yml`: their 14 rows go, with every comment that names them.
  - **Re-pointing** by Feature 004's one rule (`##### 7. Migration`, Re-pointing): every other kept file under
    `canonical/`, and `dashboard/home.html`, that names one of them or `design-lifecycle.md` is re-pointed to
    `/aid-kb-update`, the roadmap or backlog document, or reworded (for example `aid-config`'s `knowledge`
    row). Exempt: the gate's legacy block and `canonical/aid/scripts/migrate/`. The dashboard readers' legacy
    skill maps are Feature 009's (findings' R1).
  - **Lists and counts that follow the retired skills**, in this same task:
    - every row of `tests/canonical/skill-steps-exempt.tsv` whose owner is Feature 004 (the 14 skills and
      `design-lifecycle.md`, with their SS and ID codes);
    - their rows in the SG-04 exempt list of `test-skill-guide.sh`;
    - their `skill:` rows in `tests/conversation/deferred.tsv`;
    - the skill guide: the `<kind>` expansion follows the catalog, so SG-02 holds with the folders and the
      rows gone together;
    - the site skill lists and their `__tests__`;
    - the counted phrases and counts (Q134 D5): DMR33, `test-catalog-dirs-parity.sh`, SBI05,
      `test-doc-counts.sh` and the site's skill counts.
  - The G6 search below runs for each of the 14 folders and for `design-lifecycle.md`, which
    `test-skill-steps.sh`'s SS-02 clause names.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] None of the 14 folders and no `design-lifecycle.md` exists, and `grep -cE 'aid-(create|update)-(architecture|stack|testing-strategy|cicd|roadmap|backlog|mvp)\b' canonical/aid/templates/shortcut-catalog.yml` prints 0.
  - [ ] Over `canonical/` and `dashboard/home.html`, `git grep -nE 'aid-(create|update)-(architecture|stack|testing-strategy|cicd|roadmap|backlog|mvp)\b|design-lifecycle'` finds nothing outside the gate's legacy block and `canonical/aid/scripts/migrate/`.
  - [ ] `grep -c 'Feature 004' tests/canonical/skill-steps-exempt.tsv` prints 0. SG-02, SG-04, DT-01 and `test-skill-steps.sh` pass in the scratch copy, `test-doc-counts.sh` passes live, and `build-shortcut-skills.py --check` exits 0.
  - [ ] The site `npm test` passes after regeneration.

### task-152: Unit cases: the parent branch (Q60) [TEST]

- **Stanza wave:** 5. **Depends on:** task-141, task-142.
- **Source:** AC-15, AC-18.
- **Scope:**
  - `tests/canonical/test-worktree-lifecycle.sh` gains the Q60 cases of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    - with the main folder on a branch other than `master`, and `master` also present, `create` without
      `--base` makes the worktree from the checked-out branch: its first commit is that branch's tip, not
      `master`'s;
    - with no branch checked out, `create` exits 2 and creates nothing.
  - `tests/canonical/test-writeback-state.sh` gains the `--create --parent-branch` cases: the value is written
    to `pipeline.parent_branch`; `--` is accepted; an invalid name exits 4 and creates nothing; no other mode
    changes the key.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the script or the writer.
  - [ ] The cases are deterministic, use temporary repositories only, pin `HOME`, and clean up.

### task-153: Unit case: test-kb-commit.sh --new-project [TEST]

- **Stanza wave:** 5. **Depends on:** task-143.
- **Source:** AC-18.
- **Scope:**
  - `tests/canonical/test-kb-commit.sh` gains the `--new-project` case of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    `--new-project` commits `.aid/settings.yml` and the KB skeleton, and nothing else; another staged file
    stays staged; a combination with `--build` exits 2 and commits nothing.
- **Acceptance criteria:**
  - [ ] The case is a named assertion that passes on a throwaway git fixture, and fails when the mode also commits a file outside its two paths in a scratch copy of the script.
  - [ ] It is deterministic, cleans up its fixture and pins `HOME`.

### task-154: Unit cases: test-kb-state-migration.sh, baselines and parent branch [TEST]

- **Stanza wave:** 5. **Depends on:** task-148, task-149.
- **Source:** AC-25.
- **Scope:**
  - `tests/canonical/test-kb-state-migration.sh` gains the cases of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    - baselines are filled only where absent, and skipped without git;
    - `pipeline.parent_branch` is filled for works in the main folder and in a registered worktree: `master`
      when it exists, the current branch when it does not, `--` without git; an existing value is kept;
    - a re-run changes nothing;
    - each fixture starts at format 6 (PLAN.md Cross-Cutting Risks, row 5);
    - bash and PowerShell give the same bytes, with the PowerShell half under `pwsh`.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, with each case named.
  - [ ] Changing one byte of the PowerShell output in a scratch copy fails the byte-identity case, and the suite is deterministic.

### task-155: test-kb-skills.sh group K2 [TEST]

- **Stanza wave:** 5. **Depends on:** task-144, task-146, task-147, task-151.
- **Source:** AC-15, AC-18, AC-39.
- **Scope:**
  - `tests/canonical/test-kb-skills.sh` gains group K2, as REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing` defines it:
    - KB-01 and KB-02 for this delivery's names: the KB `create`/`update` skills and `design-lifecycle.md`
      are absent, no `shortcut-catalog.yml` row names one, and no kept file names one outside the
      exemptions;
    - KB-06 for the drift check (`start-or-resume.md` names `kb-freshness-check.sh`), the new project (§ 3a
      runs the new-project step, with `type: greenfield` and `kb-commit.sh --new-project`, before it creates
      the worktree) and the backlog (`check-intent.md` names `backlog.md` and records it as a work source);
    - KB-07.
    The group filter runs K1, K2 or both, and the `# COVERS:` lines name the new files.
- **Acceptance criteria:**
  - [ ] Groups K1 and K2 pass in the scratch copy.
  - [ ] Each K2 check fails its own mutation in a scratch copy: a `canonical/skills/aid-create-roadmap/` folder; a kept file naming `design-lifecycle.md`; `start-or-resume.md` without `kb-freshness-check.sh`; the new-project step moved after the `create` line; `check-intent.md` without `backlog.md`; `roadmap.md` without `## MVP`.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-156: Samples 004-05, 004-06, 004-08 and 004-09 (run at this gate), and 003-11's row [TEST]

- **Stanza wave:** 5. **Depends on:** task-147, task-151.
- **Source:** AC-15, AC-28, AC-39, AC-43.
- **Scope:**
  - Create `004-05-drift-yes`, `004-06-drift-no`, `004-08-next-backlog-item` and `004-09-roadmap-idea-parked`
    under `tests/conversation/samples/feature-004/`, with their fixtures and the checks of REQUIREMENTS.md § 11 Feature 004
    `##### 8. Testing`.
  - Update `tests/conversation/deferred.tsv`: the `003-11` row goes, since it runs at this gate (PLAN.md
    delivery-006 gate).
  - Smoke run (Q134 D8): each new sample once, and `003-11` once, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are four new files, and each `covers` matches the spec's sample table. No `## Answer sheet` names a skill.
  - [ ] DT-01 and SS-09 pass, and `deferred.tsv` has no `003-11` row.
  - [ ] Each smoke run has its result reported.

### task-157: Samples 004-10, 004-11 and 004-12 (deferred) and their deferred rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-146, task-156.
- **Source:** AC-18, AC-39.
- **Scope:**
  - Create `004-10-new-project-first-decision`, `004-11-new-project-first-build` and `004-12-backlog-item-done`
    under `tests/conversation/samples/feature-004/`, with their fixtures and the checks of REQUIREMENTS.md § 11 Feature 004
    `##### 8. Testing`. `004-12` continues the work `004-08` starts, so it reuses `004-08`'s fixture.
  - Update `tests/conversation/deferred.tsv` with one row each: `004-10` waits for Feature 005, `004-11` and
    `004-12` for Feature 007 (Feature 004's deferred samples, `##### 7. Migration`, Lists other features own).
    Delivery-007 runs `004-10` and delivery-009 runs `004-11` and `004-12` (PLAN.md).
- **Acceptance criteria:**
  - [ ] There are three files, each `covers` matches the spec's sample table, and each has a `deferred.tsv` row naming its feature.
  - [ ] DT-01 passes.

### task-158: KB conventions, roadmap, backlog, schemas and tech debt for the growing KB [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-142, task-144, task-148, task-151.
- **Source:** AC-15, AC-24, AC-39.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, KB and Release notes), for this
    delivery's part:
    - `authoring-conventions.md`: the `state` row of the type registry and criterion G-04 retire, since
      `.aid/knowledge/STATE.md` was the last in-scope `STATE.md`; the resolution example and the count of
      expressible rows follow; the view exception names `render-kb-view.sh`;
    - `roadmap.md` § MVP: the delivered roadmap, MVP and backlog skills are retired;
    - `backlog.md` § Next Release: the old -> new rows for the 14 retired slash names, with the spec's New
      text (AC-24);
    - `artifact-schemas.md`: `pipeline.parent_branch`, the KB skeleton of a new project, and the two document
      templates;
    - `tech-debt.md`: W4-5's baseline half (no document carried `approved_at_commit:`) is resolved by the
      format-6 baselines step.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `git ls-files '*STATE.md'` lists no file the type registry would resolve to `state`, and the registry has no `state` row and no G-04.
  - [ ] Each of the 14 retired slash names appears in a § Next Release row of `backlog.md`, and `roadmap.md` § MVP names no live `create`/`update` skill.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-159: KB architecture and navigation documents for the growing KB [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-146, task-147, task-149, task-151.
- **Source:** AC-15, AC-18, AC-39.
- **Scope:**
  - Edit these documents under `.aid/knowledge/`, for this delivery's part (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, KB):
    - `architecture.md`, `module-map.md`, `pipeline-contracts.md` and `capability-inventory.md`: the KB
      `create`/`update` skills go; `/aid-kb-update` creates documents; a new project's `Growing` skeleton; the
      drift check at work start; a work's parent branch;
    - `domain-glossary.md` and `project-structure.md`, where they name a retired skill or `design-lifecycle.md`.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'aid-(create|update)-(architecture|stack|testing-strategy|cicd|roadmap|backlog|mvp)\b|design-lifecycle'` finds nothing outside marked history.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-151 leaves it.

### task-160: KB test landscape for the growing KB, and the regenerated index [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-152, task-153, task-154, task-155, task-156, task-157, task-158, task-159.
- **Source:** AC-15, AC-25.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: group K2 of `test-kb-skills.sh`, the Q60 cases of
    `test-worktree-lifecycle.sh` and `test-writeback-state.sh`, the `--new-project` case of
    `test-kb-commit.sh`, and the baselines and parent-branch cases of `test-kb-state-migration.sh`.
  - Then regenerate `INDEX.md`. `kb.html` is rendered after this delivery's resync, whose baselines step
    changes the documents' frontmatter (proposal S7).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names group K2 and each new case group.
  - [ ] `INDEX.md` is regenerated; no work id, and the lints pass.
---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `new-document.md`; the 14 KB `create`/`update` skills and `design-lifecycle.md` retired, with their catalog rows and exempt-list rows | 145; 151 |
| `knowledge-base/roadmap.md` with `## MVP`, and `backlog.md`; `check-intent.md` reads `backlog.md` and records it as a source | 144; 147 |
| The new-project step in § 3a (`type: greenfield`, `Growing`, `kb-commit.sh --new-project`), the new-project row of `size-and-route.md`, `aid-kb-show`'s `Growing` case | 146 (with 143) |
| The drift check in `start-or-resume.md` (Q57); format 6's baselines step | 147; 148 |
| Q60: `worktree-lifecycle.sh create`, `--create --parent-branch`, `pipeline.parent_branch`, format 6's parent-branch step with its `Test-AidInstaller.ps1` case, `aid-kb-update` START's removed-KB check | 141, 146; 142; 149; 145 |
| The gate's legacy row for old works of the retired skills (F004 § 7, Existing works) | 150 |
| Group K2 (KB-01, KB-02 for this part's names; KB-06 drift, new project, backlog; KB-07); K1 still passes | 155 (K1 kept by 146, 151) |
| `test-worktree-lifecycle.sh` Q60 cases; `test-kb-commit.sh --new-project`; `test-kb-state-migration.sh` baselines and parent branch | 152; 153; 154 |
| Samples `004-05`, `004-06`, `004-08`, `004-09` (run), `003-11` (runs now); `004-10` to `004-12` deferred | 156; 157 |
| `skill-steps-exempt.tsv` holds no Feature 004 row | 151 |
| G0: AC-24 rows; KB documents; `INDEX.md`; `kb.html` | 158; 158, 159, 160; 160; after the resync (S7) |

**Steps that are not tasks:**
1. `--delivery-id 006 --lifecycle Executing`.
2. The tasks.
3. Verification.
4. The resync (`delivery-006: resync`):
   - `aid update` runs format 6's new steps on this repository, already at format 6: the baselines step
     stamps `approved_at_commit:` in this repository's KB documents, and the parent-branch step fills this
     work's `pipeline.parent_branch` with `master` (PLAN.md switch table);
   - the retired skills leave through the manifest;
   - then `INDEX.md` is regenerated and `kb.html` rendered with the installed scripts, as a KB commit (not
     resync-relevant), as delivery-005 does (S7).
5. The gate, in a new session:
   - the stanza's criteria;
   - the four samples and `003-11` at 3 of 3;
   - G0 with the baselines;
   - the tracking proof for task-140 to task-160.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-140
wave 2: task-141, task-142, task-143, task-144, task-148
wave 3: task-145, task-146, task-147, task-149, task-152, task-153
wave 4: task-150, task-154
wave 5: task-151
wave 6: task-155, task-156, task-158, task-159
wave 7: task-157
wave 8: task-160
```

Step 5 writes each delivery's table under `### delivery-006 Execution Graph`, one task per row. It builds
the table from the task files' `**Depends on:**` lines, never from this proposal.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The re-pointing of the 14 skills' names. | It goes in the retirement task (151), not a task of its own: at the base only `aid-config`'s `knowledge` row and the catalog name them outside themselves. task-140's R1 re-measures; a larger hit list stays with task-151 under the same rule. | F004 § 7, Re-pointing; base measurement. |
| S2 | Format 6 gains two steps in the same function. | Two tasks (148 baselines, 149 parent branch), each with both twins and its own `Test-AidInstaller.ps1` case, ordered by an edge. Each fixture starts at format 6. | AC-25; Q126; PLAN Cross-Cutting Risks row 5. |
| S3 | The drift check and the backlog read are both `aid-orchestrate` references. | One task (147). | Same skill, same type, one session. |
| S4 | `new-document.md` and START's removed-KB check are both `aid-kb-update`. | One task (145), after the work-state key (142) and the templates (144). | Same skill, same type. |
| S5 | `aid-kb-show`'s `Growing` case is in the stanza, but delivery-005's task-119 already writes it. | task-146 checks it against the skeleton and edits it only when it differs. | No double ownership. |
| S6 | The two new templates and the default document set. | They do not enter `synth_default_seed` or `domain-doc-matrix.md`'s default rows: a KB gains them only when a fact is recorded in them. | FR-10, FR-14; "No facts up front". |
| S7 | Rendering `kb.html`. | After the resync, since its baselines step changes the documents' frontmatter, and with `INDEX.md` again; task-160 regenerates `INDEX.md` only. | G0; delivery-005 S7. |
| S8 | No CI-lane task. | This delivery adds no suite file: K2 is a group of `test-kb-skills.sh`, and the other cases extend suites already listed or outside `SUITES`. | G0 (`SUITES` gains new suites only). |
| S9 | `004-10` to `004-12` are Feature 004's deferred samples. | Written here with their `deferred.tsv` rows (157), as delivery-004 wrote `003-06` to `003-11`. Delivery-007 and delivery-009 run them. | F004 § 7, Lists; PLAN delivery-006 Out of scope. |
| S10 | AC for the Q60 tasks. | AC-15 and AC-18: Q60 exists so that every work sees the KB commits made in the main folder. | Q60 context. |
| S11 | Unit cases, samples and the test landscape. | TEST tasks; one smoke run per sample; `test-landscape.md` last. | Q134 D2, D8; Q135 R1, R3. |

---

## 7. Flagged for the maintainer

- **F-1 (delivery-005, task-136).** It marks tech-debt W4-5 resolved ("leave no trace"). W4-5 has two halves:
  the index timestamps (closed by task-107) and the missing `approved_at_commit:` baselines, closed only by
  this delivery's format-6 baselines step at its resync. Recommendation: task-136 resolves the index half;
  task-158 resolves the baseline half, as written.
- **F-2 (delivery-005, task-114).** It says "Create `tests/canonical/test-build-kb-index.sh`", but that suite
  exists at the base. Recommendation: "extend".

Neither changes scope or a maintainer decision.
