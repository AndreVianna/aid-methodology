# Detail proposal -- delivery-008: The plan as a generated checklist on one state file (Feature 006)

This is `aid-detail` FIRST-RUN for **delivery-008**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-008/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-007's task-184.
- **General rules.** G1-G10 apply from the start (G7 and G8 from the delivery-005 light review, G9 and G10
  from delivery-006's): every task, TEST included, carries the findings bullet, and no criterion runs a
  copy-reading suite live.

**Inputs read:**
- the delivery-008 stanza and Notes of `PLAN.md`, Common Gate G0 (the tracking proof and "Which file holds the
  task's state"), "Testing before the resync" and "Toolchain and Branching" (the switch table's delivery-008
  row; Q119, Q127, Q129);
- `REQUIREMENTS.md` § 11 Feature 006 (all nine subsections);
- this work's own `STATE.yml` and a delivery `STATE.yml`, for the Q129 shape the resync migrates.

**Measured at base `1e513e05`** (task-185 re-measures on the tree deliveries 001-007 leave):
- `aid-plan` has 3 references; `aid-detail` has `SKILL.md` and 5 references; `delivery-plans/` holds one
  file.
- This work's `STATE.yml` is nested (`pipeline.path: full`, 14 `deliveries/delivery-NNN/STATE.yml` files) and
  also carries the flattened `delivery_state`, `gate_*`, `delivery_lifecycle` and `delivery_gate` keys (Q129),
  plus `interview`, `features`, `review_history`, `ticket_ref: --` at every level, and every per-task `STATE.yml`
  has `quick_check` and an empty `dispatch_log`.
- `test-aid-cli-parity.sh` runs `__migrate-repo` in both twins on its own fixtures.

**This delivery's end, as the plan sets it.** Every task of this delivery tracks its state in its per-task
`STATE.yml` through the installed (old) writer; none straddles the file switch (G0, "Which file holds the task's
state"). The resync installs the new writer and runs the format-6 work-state step on this work: the nested data
wins and the flattened keys go (Q129), the task files move to `tasks/task-NNN/DETAIL.md`, every task state lands
in `tasks_lifecycle`, and the record is filled from `phase: Execute` as `aid-execute` at `START`, type empty
(Q74). The delivery gate's grade, recorded with `--gate-field` before the resync, is carried into
`deliveries.delivery-008`. task-189 and task-201 make this work's own shapes explicit cases (its plan's sibling
`### delivery-NNN Execution Graph` sections; its nested-plus-flattened `STATE.yml`).

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-185 | Delivery-008 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-186 | Plan template and the rewritten task-detail template | IMPLEMENT | 2 | 2 | task-185 |
| task-187 | Work-state template: the planning part and the single layout | IMPLEMENT | 2 | 2 | task-185 |
| task-188 | Writer: one layout for every task and delivery write, and the fork | IMPLEMENT | 2 | 3 | task-187 |
| task-189 | derive-waves.sh --plan: the generated checklist | IMPLEMENT | 2 | 2 | task-185 |
| task-190 | Writer: --plan-sync and the checklist re-render (exit 11) | IMPLEMENT | 2 | 4 | task-188, task-189 |
| task-191 | slice-requirements.sh: the task file at the work root and the new Source forms | IMPLEMENT | 2 | 2 | task-185 |
| task-192 | aid-plan references: START and BREAKDOWN | IMPLEMENT | 3 | 3 | task-186, task-189 |
| task-193 | aid-plan references: CHECK and the reviewer brief | IMPLEMENT | 3 | 3 | task-189 |
| task-194 | aid-plan references: APPROVE, FINISH and REVISE, and the Q73 rule | IMPLEMENT | 3 | 5 | task-190 |
| task-195 | aid-plan SKILL.md rewritten, and its old references deleted | IMPLEMENT | 3 | 6 | task-192, task-193, task-194 |
| task-196 | Review contracts: the plan's Guard 2 site, the ledger path and aid-architect's lines | IMPLEMENT | 3 | 4 | task-193 |
| task-197 | Gate, allocation points and the shortcut engine on one layout; --path retired | IMPLEMENT | 3 | 5 | task-190 |
| task-198 | aid-deploy reads deliveries and tasks_lifecycle | IMPLEMENT | 3 | 4 | task-188 |
| task-199 | Dashboard readers: one layout, lanes per delivery, the old-layout diagnosis | IMPLEMENT | 3 | 3 | task-187 |
| task-200 | Dashboard server and page: depth badge, path line and the old-layout card | IMPLEMENT | 3 | 4 | task-199 |
| task-201 | Format 6 work-state step: fixtures and expected results, written first | TEST | 4 | 3 | task-187 |
| task-202 | Format 6 work-state step, part 1: the layout conversion, in bash and PowerShell | IMPLEMENT | 4 | 4 | task-188, task-201 |
| task-203 | Format 6 work-state step, part 2: every work's sources, keys, phases, record and type | IMPLEMENT | 4 | 5 | task-202 |
| task-204 | The gate's legacy block removed, and the old-layout check | IMPLEMENT | 4 | 6 | task-197, task-203 |
| task-205 | Re-point every kept file that names aid-detail, a deleted template or a per-unit state path | IMPLEMENT | 5 | 7 | task-195, task-196 |
| task-206 | aid-detail retired, with the delivery and task state templates and delivery-plans/ | IMPLEMENT | 5 | 8 | task-204, task-205 |
| task-207 | Writer unit cases: one layout, --plan-sync, the re-render and exit 11 | TEST | 5 | 6 | task-190, task-197 |
| task-208 | Unit cases: test-derive-waves.sh for --plan | TEST | 5 | 3 | task-189 |
| task-209 | Unit cases: test-slice-requirements.sh for the new Source forms | TEST | 5 | 3 | task-191 |
| task-210 | test-work-state-migration.sh | TEST | 5 | 6 | task-203 |
| task-211 | Dashboard cases: Planning, Building with two deliveries, an old nested work | TEST | 5 | 5 | task-199, task-200 |
| task-212 | test-plan.sh (PL-01 to PL-07) and the exempt-list rows | TEST | 5 | 9 | task-186, task-194, task-196, task-197, task-198, task-200, task-204, task-206 |
| task-213 | Samples 006-01 to 006-05 (run at this gate) | TEST | 5 | 9 | task-195, task-197, task-206 |
| task-214 | Samples 006-06 to 006-08 and the deferred rows | TEST | 5 | 10 | task-198, task-203, task-204, task-213 |
| task-215 | test-plan.sh and test-work-state-migration.sh in the CI lane | CONFIGURE | 5 | 10 | task-210, task-212 |
| task-216 | KB decisions, schemas, glossary, tech debt and backlog for the plan and one state file | DOCUMENT | 5 | 9 | task-187, task-190, task-206 |
| task-217 | KB architecture, contracts and quality documents for the plan and one state file | DOCUMENT | 5 | 9 | task-195, task-199, task-203, task-206 |
| task-218 | KB test landscape for the plan suites, the regenerated index and the view | DOCUMENT | 5 | 11 | task-207, task-208, task-209, task-211, task-214, task-215, task-216, task-217 |

That is 34 tasks. The resync follows task-218 (§ 4).

---

## 2. Rules every task carries

The blocks of delivery-007: the Execution protocol; Q106 and its ledger rows; the findings bullet
(`research/delivery-008-sites.md`); the standard test step with the site `npm test` (G5); for every IMPLEMENT
task, G1 and G3; the G6 search in the deletion tasks (195, 206); in task-185, the baseline owner class and the
G2 owner table.

- **G4.** Same-file edits in one wave are ordered by an edge: the writer (188, then 190, then 197), the gate
  (197, then 204), `reviewer-dispatch.md` (196, then 205), `deferred.tsv` (206, then 214), the CONVERT-STATE step
  (202, then 203).
- **G7.** No move task here; the format-6 step moves files only at the resync. Each new reference's content
  criteria sit in the task that writes it (192-194), and task-195's greps cover only `aid-plan`'s files.
- **G8.** The resync migrates this work's state, so its `PLAN.md` checklists, which the migration does not
  render, are rendered after it (§ 4, step 5). The KB and the site are not changed by this resync.

---

## 3. Tasks

`Source` reads `feature-006-planning -> delivery-008 -> AC-...`.

### task-185: Delivery-008 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-19.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout` and `##### 8. Migration`):
    - **L1** `aid-detail`, over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`,
      `.github/` and `.aid/knowledge/`, checked against the spec's stated re-pointing sites;
    - **L2** the deleted templates and references by path: `delivery-state-template.yml`,
      `task-state-template.yml`, `delivery-plans/`, `aid-plan/references/first-run-loop.md` and
      `review-deliverables.md`, and every file of `aid-detail/`;
    - **L3** every PL-04 pattern: `deliveries/delivery-`, a per-task `STATE.yml`, `AID_TASK_STATE_FILE`,
      `AID_DELIVERY_STATE_FILE`, `pipeline.path`, `Pipeline Path`, `Spike Needed`, and in the dashboard files
      `work_path`;
    - **L4** every caller of `--create --path` and every allocation point (Feature 002's list), and the
      `delivery_lifecycle`, `tasks_lifecycle` and `--lifecycle Specified` writes in `shortcut-engine.md`;
    - **L5** every user of `derive-waves.sh`'s `<plan.md> --write|--check` table modes, of the `wave-map`
      block and of `parse_execution_graph`;
    - **L6** the dashboard's layout code: `_detect_hierarchy`, `_read_work_hierarchical`, `_detect_flat`,
      `_declared_work_path`, `parse_task_state_md`, the delivery-file parse and the delivery `qa` merge, with
      their Node twins, fixtures and tests;
    - **L7** the format-6 CONVERT-STATE step and `migrate-work-hierarchy.sh`/`.ps1` in `bin/aid`, `bin/aid.ps1`
      and `lib/`, and every suite or `Test-AidInstaller.ps1` case that runs `__migrate-repo` or `aid update` on
      a fixture holding a work;
    - **L8** the rows of `tests/conversation/deferred.tsv`, the SG-04 exempt list and
      `tests/canonical/skill-steps-exempt.tsv` that name `aid-plan`, `aid-detail` or `aid-deploy`, or a sample
      this delivery runs; and the Q106 suite map for every file on the edit list, including the dashboard
      tests and the site's skill lists.
  - Give each hit exactly one owner:
    - a task of delivery-008 (task-186 to task-218; see the task files under
      `.aid/works/work-003-full-aid-restructure/deliveries/delivery-008/tasks/`);
    - Feature 007 (delivery-009) for `aid-execute`'s own layout reads, exempt from PL-04 until then;
    - Feature 009 (delivery-012) for the shortcut engine's PLAN and DETAIL states;
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
  - [ ] Each of L1-L8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-186: Plan template and the rewritten task-detail template [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-185.
- **Source:** AC-19.
- **Scope:**
  - Create `canonical/aid/templates/plan-template.md`, type `template-own` (REQUIREMENTS.md § 11 Feature 006 `##### 2. The plan and the task
    file`, The plan): the title, the comment saying each checklist is generated by `derive-waves.sh` from the task
    files and `STATE.yml` and a hand edit inside the markers is overwritten, and one stanza with **Delivers:**,
    **After:**, **Acceptance criteria:** (ids only) and the `<!-- checklist: begin -->` / `end` markers. No other
    sections.
  - Rewrite `canonical/aid/templates/task-detail-template.md` (The task file): the title rule, the Execution
    protocol note naming `writeback-state.sh --task-id NNN --field State`, **Type:**, both **Source:** forms
    (unsplit: `delivery-NNN -> FR-N -> AC-N`; split: `feature-NNN -> delivery-NNN -> FR-N -> AC-N`),
    **Depends on:** (same or earlier delivery only), **Scope:** and **Acceptance Criteria:**. No `STATE` note, no
    `ticket_ref`, no "Spike Needed".
  - `delivery-plans/` and the two state templates are deleted by task-206, with their last users.
  - Suites to update in this same task: any suite the findings' L2 or L8 assigns to these two templates (for
    example `test-ticket-retirement-structural.sh` or `test-connector-consumption-linkage.sh`, where they read
    the task template).
- **Acceptance criteria:**
  - [ ] `plan-template.md` has the stanza lines and the checklist markers and no `## Cross-Cutting Risks` or `## Deferred`; `task-detail-template.md` has both Source forms and no `ticket_ref` or `Spike Needed`.
  - [ ] The registry resolves `plan-template.md` to `template-own` (authoring-conventions.md), and the suites the findings assign pass where the test step puts them.
  - [ ] The site `npm test` passes after `gen:reference`.

### task-187: Work-state template: the planning part and the single layout [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-185.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml` (REQUIREMENTS.md § 11 Feature 006 `##### 4. Work state`):
    - `deliveries:` (one entry per delivery: `state`, `updated`, `gate_tier`, `gate_grade`, `gate_timestamp`,
      `block_reason`, `block_artifact`, `issue_list`) and `tasks_lifecycle:` (today's fields and the
      `quick_check` text value), each with its `[W]` comment, block style, three levels at most;
    - gone: `pipeline.path`, the top-level `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`,
      `delivery_lifecycle` and `delivery_gate`;
    - the header's zone, "derived view" and full-layout-omission paragraphs become a short statement of the
      single layout.
  - Both dashboard readers accept the `deliveries` key with no warning (their schema only; reading the one
    layout is task-199), so SS-08 holds.
  - Suites to update in this same task: `test-work-state-template.sh`, `test-skill-steps.sh` SS-08 where it
    reads the template, and any suite the findings' L3 or L8 assigns to the template.
- **Acceptance criteria:**
  - [ ] The template has `deliveries:` and `tasks_lifecycle:`, each with its `[W]` comment, and none of `pipeline.path`, `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `delivery_lifecycle`, `delivery_gate` (PL-05's template clause).
  - [ ] It parses through `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs` with no warning; `test-work-state-template.sh` passes where the test step puts it and SS-08 passes in the scratch copy.

### task-188: Writer: one layout for every task and delivery write, and the fork [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-187.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 4. Work state`, Writer):
    - `--task-id NNN --field F` and `--task-id NNN --findings` write `tasks_lifecycle.task-NNN.*`;
      `--delivery-id NNN --lifecycle`, `--gate-field` and `--block` write `deliveries.delivery-NNN.*`; all in the
      work file, resolved like every work write (`AID_STATE_FILE`). `--delivery-id` beside `--task-id` is accepted
      and has no effect;
    - the nested-layout resolution, layout detection and the `AID_TASK_STATE_FILE` / `AID_DELIVERY_STATE_FILE`
      overrides go;
    - `--lifecycle` accepts `Pending | Executing | Gated | Done | Blocked`; `Pending-Spec` and `Specified` exit 4.
  - `dashboard/scripts/writeback-state.sh` (the fork): the same single-layout targets for its task writes
    (rename, notes); it keeps `Deploy`.
  - `--create --path` and the `"Pipeline Path"` field go with their callers, in task-197. `--plan-sync` and the
    re-render are task-190. The unit cases are task-207.
  - Suites to update in this same task: the existing assertions of `test-writeback-state.sh`,
    `test-disjoint-merge.sh`, `test-delivery-gate-aggregate.sh`, `test-lite-work-end-to-end.sh`,
    `test-task-state-transitions.sh` (its fixture converted: no `pipeline.path`, no top-level `delivery_state`, a
    `deliveries.delivery-001` entry), `test-producer-completeness.sh` (its nested fixture converted; the null lane
    produced by a dependency cycle in the task files), and any suite the findings' L3 or L8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch single-layout work, `--task-id 001 --field State --value Done` writes `tasks_lifecycle.task-001.state`, and `--delivery-id 001 --lifecycle Gated` writes `deliveries.delivery-001.state`; `--lifecycle Specified` exits 4 with the file byte-identical.
  - [ ] `git grep -nE 'AID_TASK_STATE_FILE|AID_DELIVERY_STATE_FILE|deliveries/delivery-' -- canonical/aid/scripts/execute/writeback-state.sh dashboard/scripts/writeback-state.sh` finds nothing (PL-04 over this task's files).
  - [ ] The listed suites pass where the test step puts them.

### task-189: derive-waves.sh --plan: the generated checklist [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-185.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/scripts/execute/derive-waves.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 2. The plan and the task file`, Waves):
    - new `--plan <work-dir>`: reads every task file (id from its folder, delivery from Source, dependencies) and
      the work file's task states, and writes each delivery's checklist between its markers -- wave headings,
      then one line per task: checkbox (`[x]` when Done), `[task-NNN](tasks/task-NNN/DETAIL.md)`, title, type,
      `after:` and its state when neither `Pending` nor `Done` -- through a temporary file renamed into place; a
      byte-identical no-op when nothing changed;
    - the same Kahn sort per delivery; a dependency on an earlier delivery's task is met;
    - exits: 0 written or current; 2 a malformed graph (a cycle, an undefined task, a dependency on a later
      delivery's task) with the plan untouched; 3 no `PLAN.md`. `--plan <dir> --check` writes nothing: 0, 1, 2, 3;
    - a delivery with tasks and no stanza gets a bare `### delivery-NNN` heading and its checklist at the end;
    - **old plans**: on the first run in a stanza with no markers, the stanza's execution-graph section
      (`#### Execution Graph`, a sibling `### delivery-NNN Execution Graph` section, or an old lite plan's
      `## Execution Graph`) and its `wave-map` block are replaced with the checklist; authored lines are never
      rewritten;
    - the `<plan.md> [--write|--check]` table modes go; `--from-tasks` is unchanged; bash and awk only.
  - **This work's own plan shape is a case to get right**: this delivery's resync migrates this work, and its
    gate runs `--plan --check` on its `PLAN.md` (PLAN.md delivery-008 gate). Its stanzas are `### delivery-NNN:
    Name`, each followed by a sibling `### delivery-NNN Execution Graph` section with a table and a `wave-map`
    block; its task Sources use the old form `feature-NNN-name -> delivery-NNN -> AC-N`.
  - The unit cases are task-208.
  - Suites to update in this same task: the existing `test-derive-waves.sh` assertions on the table modes,
    `test-executor-graph-flat-plan.sh`, and any suite the findings' L5 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work with two deliveries, `--plan` writes both checklists, each task line's link resolves to its `DETAIL.md` from the plan's folder, and a second run is byte-identical; a dependency on a later delivery's task exits 2 with `PLAN.md` byte-identical.
  - [ ] On a scratch copy of this work's `PLAN.md` and task files laid out at the work root (as the migration leaves them), `--plan` replaces each `### delivery-NNN Execution Graph` section and its `wave-map` with a checklist, keeps every authored stanza line, and `--plan --check` then exits 0.
  - [ ] `--from-tasks` output on this work is byte-identical before and after the change, and the listed suites pass where the test step puts them.

### task-190: Writer: --plan-sync and the checklist re-render (exit 11) [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-188, task-189.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 4. Work state`, Writer):
    - **`--plan-sync`**, one locked write: reads the task files (ids, and each one's delivery from Source) and the
      plan's stanzas (delivery ids; from Source alone with no plan), adds a `Pending` entry for every delivery
      and task that has none, and sets `Canceled` on a `Pending` task whose file is gone; a task file gone for a
      task in any other state exits 4 and writes nothing;
    - **the re-render**: after `--plan-sync`, and after every task or delivery state write, when the work has a
      `PLAN.md`, the writer runs `derive-waves.sh --plan` under the same lock, computes the checklist first and
      writes both files only if that succeeds; a malformed graph writes nothing and exits **11**, documented in
      the header.
  - The unit cases are task-207.
  - Suites to update in this same task: any existing suite whose fixture has a `PLAN.md` and now sees it
    re-rendered on a state write (the findings' L5 and L8).
- **Acceptance criteria:**
  - [ ] On a scratch work with two task files and a `PLAN.md`, `--plan-sync` adds two `Pending` task entries and one delivery entry and renders the checklist; a second run changes nothing.
  - [ ] A state write on a work whose task files hold a cycle exits 11, with `STATE.yml` and `PLAN.md` both byte-identical; with no `PLAN.md`, a state write renders nothing.
  - [ ] The suites the findings assign pass where the test step puts them.

### task-191: slice-requirements.sh: the task file at the work root and the new Source forms [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-185.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/scripts/execute/slice-requirements.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout` and The task file):
    - it finds a task file at `tasks/task-NNN/DETAIL.md` only;
    - it reads both new Source forms (`delivery-NNN -> FR-N -> AC-N`, and `feature-NNN -> delivery-NNN -> ...`),
      slicing an unsplit Source to `## 11. Technical Specification` and a split one to its feature section
      (Feature 005); the old form `feature-NNN-{name} -> delivery-NNN -> AC-N` still reads.
  - The unit cases are task-209.
  - Suites to update in this same task: the existing `test-slice-requirements.sh` assertions on the nested
    path, and any suite the findings' L3 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work, an unsplit Source slices to `## 11. Technical Specification` and a split Source to its feature; an old-form Source still slices as before.
  - [ ] `git grep -n 'deliveries/delivery-' canonical/aid/scripts/execute/slice-requirements.sh` finds nothing, and `test-slice-requirements.sh` passes live.

### task-192: aid-plan references: START and BREAKDOWN [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-186, task-189.
- **Source:** AC-19, AC-28.
- **Scope:**
  - Create in `canonical/skills/aid-plan/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 006 `##### 3. Flow`, steps 1-2):
    - `start.md`: what START reads (the record, `REQUIREMENTS.md` in either shape, `known-issues.md`, `sources:`,
      the open `qa` first, the KB through `INDEX.md`); what is on disk is kept; an old plan is not converted; a
      change after Planning goes straight to REVISE;
    - `breakdown.md`: `aid-architect` writes the task files and stanzas, delivery by delivery on a large work,
      never asking the user, then `derive-waves.sh --plan` runs; atomic tasks; the eight types, their default
      criteria and the type-separation rule moved from `aid-detail`'s `task-decomposition.md` unchanged;
      deliveries by Q72 (one, or one per feature; an extra one asked in `full`, `Assumed` in `lite`); no new
      design decision (a `CALL` to `/aid-specify` REVISE); ask only what blocks.
  - `SKILL.md` and the old references stay until task-195 points the step table here.
  - Suites to update in this same task: any suite the findings' L8 assigns to these new files.
- **Acceptance criteria:**
  - [ ] Both files exist, each at most 120 lines; `breakdown.md` holds the eight types with their default criteria and names `derive-waves.sh --plan` and `aid-specify`.
  - [ ] The site `npm test` passes after regeneration.

### task-193: aid-plan references: CHECK and the reviewer brief [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-189.
- **Source:** AC-19.
- **Scope:**
  - Create `canonical/skills/aid-plan/references/check.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 006 `##### 3. Flow`, step 3): one graded
    `aid-reviewer` pass over the plan, every task file and `REQUIREMENTS.md`; ledger
    `.aid/.temp/review-pending/<work>-plan.md`; what it reports, including `derive-waves.sh --plan --check`
    exiting 2; Guard 2 on cycle 1, once per work; `grade.sh` and `--review`; after three rounds below the bar, fix,
    accept (`Accepted`) or keep reviewing (Q69).
  - Rewrite `references/reviewer-brief.md` for that pass, with `### What to report` (FR-21, SS-13).
  - Suites to update in this same task: any suite the findings' L8 assigns to these files.
- **Acceptance criteria:**
  - [ ] `check.md` exists, at most 120 lines, and names fix, accept and keep reviewing, `Accepted`, `<work>-plan.md` and Guard 2 (PL-03's `check.md` clause).
  - [ ] `reviewer-brief.md` has `### What to report`, and SS-13 passes in the scratch copy.

### task-194: aid-plan references: APPROVE, FINISH and REVISE, and the Q73 rule [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-190.
- **Source:** AC-10, AC-19.
- **Scope:**
  - Create in `canonical/skills/aid-plan/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 006 `##### 3. Flow`, steps 4-5, and Changing the plan after
    Planning):
    - `approve.md`: `full` -- the plan in chunks, one question: *approve and start building* (recorded `covers:
      PLAN.md; confirmation before building`) or *approve, build later* (`covers: PLAN.md`); `lite` -- no stop;
    - `finish.md`: `--plan-sync`; the KB call by `skill-steps.md`'s rule; `PASS` with `--handoff --to aid-execute
      --step <its entry step> --returns no --phase Building`; after *approve, build later*, the hand-off written,
      the work paused (`pause_reason: 'Plan approved; building not started'`) and one line on how to start;
    - `revise.md`: entry by `CALL` or typed start; a `Done` task never edited or removed; approvals by kind
      (`covers: plan change`; `Plan change` recorded `Assumed`), with the `lite` cases.
  - `canonical/aid/templates/skill-steps.md` § When approvals happen gains the Q73 rule under the table (REQUIREMENTS.md § 11 Feature 006
    `##### 5. Components`, Approvals).
  - Suites to update in this same task: any suite that asserts the approvals table (the findings' L8).
- **Acceptance criteria:**
  - [ ] The three files exist, each at most 120 lines; `finish.md` names `aid-execute`, `--phase Building`, `--plan-sync` and `aid-kb-update` with `--returns yes`; `approve.md` names `confirmation before building`; `revise.md` names `plan change` and `Plan change` (PL-03).
  - [ ] `skill-steps.md` states the Q73 rule with `covers: PLAN.md; confirmation before building` (PL-07's clause), and SR-01 passes.

### task-195: aid-plan SKILL.md rewritten, and its old references deleted [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-192, task-193, task-194.
- **Source:** AC-19.
- **Scope:**
  - Rewrite `canonical/skills/aid-plan/SKILL.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout` and
    `##### 3. Flow`): the step table START, BREAKDOWN, CHECK, APPROVE, FINISH and REVISE pointing at the new
    references; `skill-steps.md` and `question-protocol.md` cited; the spec's `description:` and
    `argument-hint`; the plan-mode check as one line. Gone: Check 1's work listing and worktree entry, Check 2 and
    its `features` `Ready` gate, `--reset`, the state map and banners, `## Feedback Loops`.
  - Delete `references/first-run-loop.md` and `references/review-deliverables.md`.
  - **Lists and counts**: the `/aid-plan` line of the skill guide with the spec's text; `aid-plan`'s SG-04 row, if
    any; the site skill lists and flows and their `__tests__`.
  - Suites to update in this same task: `test-scoped-review-cycles.sh` (SC10's plan site becomes
    `aid-plan/references/check.md`), `test-pipeline-status-walkthrough.sh` (the `aid-plan` rows of A1, M4 and B1
    re-point to `start.md` and `breakdown.md` with phase `Planning`), and any suite the findings' L1, L2 or L8
    assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `SKILL.md` is at most 120 lines with the six steps and FINISH advancing by `PASS`; `first-run-loop.md` and `review-deliverables.md` are absent (PL-01's and PL-03's `aid-plan` clauses).
  - [ ] Over `canonical/skills/aid-plan/`, `git grep -nE 'Ready|--reset|Spike Needed|deliveries/delivery-'` finds nothing.
  - [ ] SG-02, SG-04 and `test-scoped-review-cycles.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-196: Review contracts: the plan's Guard 2 site, the ledger path and aid-architect's lines [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-193.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/templates/reviewer-dispatch.md` (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout`): Guard 2's `aid-plan` row
    becomes `aid-plan` CHECK over the plan, every task file and `REQUIREMENTS.md`, covering Planning's own output;
    the `aid-detail` row goes, and `aid-detail` leaves the list of skills that render the brief structure.
  - `canonical/aid/templates/reviewer-ledger-schema.md`: the `/aid-plan` and `/aid-detail` rows become one,
    `/aid-plan` -> `.aid/.temp/review-pending/<work>-plan.md`.
  - `canonical/agents/aid-architect/AGENT.md`: "What You Do" and "Output Format" say task files each declare
    their `**Depends on:**` and their delivery, and the plan's shape is `plan-template.md`.
  - Suites to update in this same task: `test-scoped-review-cycles.sh` where it reads `reviewer-dispatch.md`, and
    any suite the findings' L1 or L8 assigns here.
- **Acceptance criteria:**
  - [ ] `reviewer-dispatch.md` names `aid-plan` CHECK and no `aid-detail` row; the ledger schema names `<work>-plan.md` and no `/aid-detail` row (PL-07's clauses).
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after `gen:reference`.

### task-197: Gate, allocation points and the shortcut engine on one layout; --path retired [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-190.
- **Source:** AC-19.
- **Scope:**
  - `canonical/aid/templates/work-initiation-gate.md` § 3a passes no `--path` (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and
    layout`).
  - Every allocation point that passes `--path` to the gate's `--create` (the findings' L4): `--path lite` becomes
    `--depth lite`; `--path full` is dropped (Q11).
  - `canonical/aid/templates/shortcut-engine.md` § State: PLAN Step 3, § State: DETAIL Steps 3-4 and its
    `pipeline.path` lines: the direct edits of `delivery_lifecycle` and `tasks_lifecycle` and the `--lifecycle
    Specified` write become one `writeback-state.sh --plan-sync`; `pipeline.path: lite` becomes `intent.depth`
    `lite`. The states themselves stay until Feature 009.
  - `canonical/aid/scripts/execute/writeback-state.sh`: `--create --path` and the `"Pipeline Path"` field go, in
    this same task as their last callers, so no caller fails between tasks.
  - Suites to update in this same task: `test-work-initiation-gate.sh` where it asserts `--path`,
    `test-writeback-state.sh` where it asserts `--create --path`, the shortcut-engine suites
    (`test-shortcut-engine-contract.sh` and any the findings' L4 assigns), and any suite the findings' L3 or L8
    assigns here.
- **Acceptance criteria:**
  - [ ] Over `canonical/`, `git grep -nE -- '--path (lite|full)|Pipeline Path|pipeline\.path'` finds nothing outside `canonical/aid/scripts/migrate/` and the files of `aid-execute` (Feature 007's, exempt from PL-04).
  - [ ] `writeback-state.sh --create ... --path lite` exits 4 and creates nothing; the engine's PLAN and DETAIL states name `--plan-sync`.
  - [ ] The listed suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-198: aid-deploy reads deliveries and tasks_lifecycle [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-188.
- **Source:** AC-19.
- **Scope:**
  - `canonical/skills/aid-deploy/SKILL.md` and `references/state-selecting.md` (REQUIREMENTS.md § 11 Feature 006 `##### 5. Components`,
    `aid-deploy`): each delivery's state from the work file's `deliveries`, each task's from `tasks_lifecycle`,
    the delivery names from the plan's stanzas; the `deliveries/delivery-NNN/` workspace lines go. Its `deploy`
    key and its steps are unchanged.
  - Suites to update in this same task: `test-deploy-monitor-repurpose.sh` where it asserts these lines, and
    any suite the findings' L3 or L8 assigns here.
- **Acceptance criteria:**
  - [ ] Over `canonical/skills/aid-deploy/`, `git grep -nE 'deliveries/delivery-|STATE\.yml.*tasks/task-'` finds nothing, and both files name `deliveries` and `tasks_lifecycle`.
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-199: Dashboard readers: one layout, lanes per delivery, the old-layout diagnosis [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-187.
- **Source:** AC-19, AC-41.
- **Scope:**
  - Both readers, kept equal by the parity tests (REQUIREMENTS.md § 11 Feature 006 `##### 5. Components`, Dashboard): `dashboard/reader/
    models.py`, `parsers.py`, `reader.py`, `derivation.py`, `state_schema.py` (its docstring example names
    `intent.depth`), and `dashboard/server/reader.mjs`:
    - tasks from `tasks/task-NNN/DETAIL.md` (title, type, delivery from Source, dependencies); task cells from
      `tasks_lifecycle`; delivery cells from `deliveries`; delivery names from the plan's `### delivery-NNN:`
      headings;
    - lanes derived per delivery from the task files (`_derive_lanes_from_details` and its Node twin, grouped by
      delivery); the `wave-map` parse goes;
    - gone: `_detect_hierarchy`, `_read_work_hierarchical`, `_detect_flat`, `_declared_work_path`,
      `parse_task_state_md`, the delivery-file parse and the delivery `qa` merge;
    - an old-layout work (a `deliveries/` folder, a top-level `delivery_state`, or a `pipeline.path`) is not
      parsed: `layout_status: old`, the detection lines inside `legacy-layout: begin` / `end` markers;
    - work fields `depth` (from `intent.depth`) and `phases` (from `intent.phases`) replace `work_path`;
      `features` goes.
  - The server and page are task-200. New fixtures are task-211.
  - Suites to update in this same task: the existing dashboard reader and parity suites and fixtures (hierarchy
    and `wave-map` fixtures among them; an old nested fixture stays where it now checks the diagnosis),
    `test-dashboard-parity-h.sh`, and any suite the findings' L6 assigns here.
- **Acceptance criteria:**
  - [ ] A scratch single-layout work with two deliveries reads with lanes per delivery and delivery names from the plan in both readers; a nested fixture reads `layout_status: old` in both.
  - [ ] Over `dashboard/reader/*.py` and `dashboard/server/reader.mjs`, `git grep -nE 'deliveries/delivery-|pipeline\.path|work_path|parse_execution_graph'` finds nothing outside the `legacy-layout` markers (PL-04 over this task's files).
  - [ ] The reader and parity suites pass where the test step puts them.

### task-200: Dashboard server and page: depth badge, path line and the old-layout card [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-199.
- **Source:** AC-19, AC-41.
- **Scope:**
  - `dashboard/server/server.py` § `_ser_work` and `server.mjs` pass `depth`, `phases` and `layout_status`, and no
    `work_path` or `features` (REQUIREMENTS.md § 11 Feature 006 `##### 5. Components`, Dashboard).
  - `dashboard/home.html`: the badge shows the depth ("Full" / "Lite"); the path line becomes "{Full|Lite}: N
    deliveries -> M tasks (K done)", "[planning]" before any task exists, with no feature count; the features
    disclosure goes; an old-layout work's card says "This work uses an older layout: run `aid update` in this
    project". The stage rail stays Feature 002's.
  - Suites to update in this same task: `dashboard/server/tests/test_index_html.py`, the server tests, and any
    suite the findings' L6 assigns here.
- **Acceptance criteria:**
  - [ ] `home.html` holds the old-layout line verbatim and no `work_path` or features disclosure; `grep -n 'work_path' dashboard/server/server.py dashboard/server/server.mjs dashboard/home.html` prints nothing.
  - [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` and the server suites pass.

### task-201: Format 6 work-state step: fixtures and expected results, written first [TEST]

- **Stanza wave:** 4. **Depends on:** task-187.
- **Source:** AC-19, AC-25.
- **Scope:**
  - Create `tests/canonical/lib/work-state-migration-fixtures.sh` (sourced, not run by `run-all.sh`), which builds
    each case of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing` (`test-work-state-migration.sh`) in a temporary main folder with a
    registered worktree, and the expected file and tree for each, under `tests/canonical/fixtures/work-state-migration/`:
    - a nested work; an old lite work; a single-layout work;
    - **a nested work that also carries the flattened delivery keys (Q129)**, shaped like this work's own
      `STATE.yml`: `pipeline.path: full`, the top-level `delivery_state`, `gate_*`, `delivery_lifecycle` and
      `delivery_gate`, `interview`, `features` and `review_history`, a top-level `qa`, `ticket_ref: --` at every
      level, phase `Execute` and `active_skill: aid-execute`, and per-task `STATE.yml` files with `quick_check`
      and `dispatch_log` (its expected result follows proposal F-1);
    - `ticket_ref` at each level; delivery `qa`; each legacy record row and the Q74 type rows; the named cases
      (an `aid-describe` work at `Detail`; `aid-design-api` and `aid-create-roadmap` works at `phase: Describe`;
      a halted `aid-refactor` work at `Detail`; `active_skill: aid-deploy` at `Execute`; a `--create`-made work at
      `Definition`); a duplicate task id; an unknown file;
    - every repository fixture starts at format 6 (PLAN.md Cross-Cutting Risks, row 5).
  - The suite that runs them is task-210.
- **Acceptance criteria:**
  - [ ] The builder makes every case in a temporary folder and cleans up; each case has its expected tree on disk, and the Q129 case's expected `STATE.yml` keeps the nested delivery data and has none of the flattened keys.
  - [ ] The builder is deterministic (two runs build byte-identical fixtures) and needs no network.

### task-202: Format 6 work-state step, part 1: the layout conversion, in bash and PowerShell [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-188, task-201.
- **Source:** AC-19, AC-25.
- **Scope:**
  - `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the work-state step's layout part, run
    after `migrate-work-hierarchy.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, Format 6), over every work `STATE.yml` in the
    main folder and in each worktree `git worktree list` registers:
    - **nested works**: each `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` moves to `tasks/task-NNN/DETAIL.md`
      (a task id found twice stops the step for that work, with a warning and nothing changed); task cells become
      `tasks_lifecycle.task-NNN` (with `quick_check` as one text value); delivery cells become
      `deliveries.delivery-NNN` (`Pending-Spec` and `Specified` -> `Pending`; `delivery_gate.issue_list` -> one
      text value); a per-task `dispatch_log`, which the spec's `tasks_lifecycle` shape does not carry, is dropped,
      with a warning when it is not empty (proposal F-1, pending the maintainer's confirmation); each delivery's `qa` is appended to the work's `qa` under the next free ids, its `context`
      opening with the old place; the per-unit state files are deleted, then the folders left empty; an unknown
      file is kept, with a warning;
    - **old lite works**: the flattened keys become `deliveries.delivery-001`;
    - **a nested work that also carries the flattened keys** (Q129): the nested data wins; the flattened keys are
      dropped and never mapped.
    - Bash first, then its PowerShell twin, in this same task: the twins are never split across tasks
      (delivery-005 S3), so parity holds at this task's end.
  - `tests/windows/Test-AidInstaller.ps1` gains a case for this part (Q126).
  - Files: `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, whichever hold the step.
    Byte-identical, PowerShell 5.1-safe and ASCII.
  - Suites to update in this same task: `test-aid-migrate.sh`, `test-migrate-hierarchy.sh` and any suite or case
    the findings' L7 assigns here.
- **Acceptance criteria:**
  - [ ] On task-201's nested, old lite and Q129 fixtures, the bash step's tree equals the expected tree, and a second run changes nothing (`sha256sum` of every file unchanged).
  - [ ] Under `pwsh`, the PowerShell twin gives byte-identical trees for the same fixtures; `test-ps51-compat.sh` and `test-ascii-only.sh` pass live, and `test-aid-cli-parity.sh` passes in the scratch copy.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-203: Format 6 work-state step, part 2: every work's sources, keys, phases, record and type [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-202.
- **Source:** AC-19, AC-25, AC-37.
- **Scope:**
  - The work-state step gains, for **every work**, in bash and its PowerShell twin in this same task (REQUIREMENTS.md § 11 Feature 006
    `##### 8. Migration`, Every work):
    - every `ticket_ref` (work, delivery, task) becomes a `sources:` entry -- `ref`, `kind: ticket`, `added` the
      work's `started`, `phase: --`, `effect: 'from ticket_ref (<level>)'` -- one per distinct ref; a `--` value
      adds none;
    - `intent.depth`, when missing, takes `pipeline.path`'s value; then `pipeline.path` goes;
    - `interview`, `features` and `review_history` go;
    - the old phase names are rewritten (Feature 002's mapping);
    - **the record** of every open work whose resume fields are missing or incomplete, by rules 1-5 in order,
      written at the skill's entry step (`START`, `IDLE` for `aid-deploy`); a work with complete resume fields is
      never touched; a finished work gets no record;
    - **the type (Q74)** only where the starting skill makes it certain; otherwise left empty.
    - Era marker: the step runs on any work that still has a `deliveries/` folder, a top-level `delivery_state`,
      a `pipeline.path`, a `ticket_ref` or a dropped key.
  - `tests/windows/Test-AidInstaller.ps1` gains a case for this part (Q126).
  - Files and rules for the twins: as task-202.
  - Suites to update in this same task: any suite or case the findings' L7 assigns here.
- **Acceptance criteria:**
  - [ ] On task-201's fixtures, each named record case gets the spec's skill and step (the Q129 fixture: `aid-execute` at `START`, type empty, `intent.depth: full`), and a second run changes nothing, the records included.
  - [ ] Under `pwsh`, the twin gives byte-identical files for every fixture; `test-ps51-compat.sh` and `test-ascii-only.sh` pass live, and `test-aid-cli-parity.sh` passes in the scratch copy.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally.

### task-204: The gate's legacy block removed, and the old-layout check [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-197, task-203.
- **Source:** AC-19, AC-37.
- **Scope:**
  - `canonical/aid/templates/work-initiation-gate.md` § 3b (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, The gate's legacy block): the
    `legacy-phase-map` block goes, its rows living on in the migration code; recovery gains one check in its
    place: a work with an old layout is not repaired, and the agent says in one line that the work predates this
    version and to run `aid update` in the project.
  - `tests/canonical/test-work-initiation-gate.sh`: its legacy-block fixtures (Features 002-005, the KB create/update
    row of delivery-006 included) are replaced by one old-layout fixture, with accepted-removal rows.
  - Suites to update in this same task: any suite the findings' L8 assigns to the legacy block (for example
    `test-skill-steps.sh` or `test-idea-shaping.sh`, where they read it).
- **Acceptance criteria:**
  - [ ] `work-initiation-gate.md` has no `legacy-phase-map` block and names `aid update` in § 3b (PL-05's gate clause).
  - [ ] An old-layout fixture gets the `aid update` line and no repair, and `test-work-initiation-gate.sh` passes where the test step puts it.

### task-205: Re-point every kept file that names aid-detail, a deleted template or a per-unit state path [IMPLEMENT]

- **Stanza wave:** 5. **Depends on:** task-195, task-196.
- **Source:** AC-19.
- **Scope:**
  - Re-point by one rule (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, Re-pointing) every kept file under `canonical/`, and
    `dashboard/home.html`, that names `aid-detail`, a deleted template or reference, a `deliveries/delivery-NNN/`
    path or a per-task `STATE.yml`. Exempt: `canonical/aid/scripts/migrate/`. The stated sites:
    `downstream-worktree-entry.md` and `worktree-lifecycle.md` (consumer lists), `connectors/consumption-protocol.md`,
    `reviewer-dispatch.md` (where a ledger may sit), `aid-monitor/SKILL.md` (task-file paths), `complexity-score.sh`
    (its full-layout path), `aid-execute/SKILL.md` (its one `aid-detail` mention; the rest is Feature 007's),
    `aid-kb-build/references/elicit.md`, and the comment in `dashboard/reader/derivation.py`.
  - Suites to update in this same task: `test-downstream-worktree-entry.sh`, `test-connector-consumption-linkage.sh`,
    `test-complexity-score.sh`, and any suite the findings' L1, L2, L3 or L8 assigns to these files.
- **Acceptance criteria:**
  - [ ] Over `canonical/` and `dashboard/home.html`, `git grep -nE 'aid-detail|deliveries/delivery-|task-state-template|delivery-state-template|delivery-plans/'` finds only the files of `canonical/skills/aid-detail/` and the two templates task-206 deletes, `canonical/aid/scripts/migrate/` and the files of `aid-execute` (PL-02 and PL-04, scoped to hold at this task's end).
  - [ ] The listed suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-206: aid-detail retired, with the delivery and task state templates and delivery-plans/ [IMPLEMENT]

- **Stanza wave:** 5. **Depends on:** task-204, task-205.
- **Source:** AC-19.
- **Scope:**
  - Delete `canonical/skills/aid-detail/` (its breakdown moved to BREAKDOWN, its review to CHECK;
    `execution-graph-generation.md` goes), `canonical/aid/templates/delivery-state-template.yml`,
    `task-state-template.yml` and `delivery-plans/` (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout`).
  - **Lists and counts that follow the retired skill**, in this same task: its skill-guide line; its SG-04 row;
    its `skill:aid-detail` row in `deferred.tsv`; SS-14 (b)'s template exceptions lose the two deleted templates;
    the site skill lists and flows and their `__tests__`; the counted phrases (Q134 D5).
  - Suites to update in this same task: `test-scoped-review-cycles.sh` (SC10's detail site goes; its sites are
    `aid-specify` CHECK and `aid-plan` CHECK), `test-state-review-surface.sh` (SR17's `aid-detail` brief path
    retired; its old-shape fixtures stay), `test-pipeline-status-walkthrough.sh` (the `aid-detail` rows retired),
    `test-artifact-discipline.sh` (AD13's ceilings drop to the measured counts), and any suite the findings' L1 or
    L2 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-detail` fails, and none of the two templates and `delivery-plans/` exists (PL-01's clauses).
  - [ ] Over `canonical/` and `dashboard/home.html`, `git grep -n aid-detail` finds nothing outside `canonical/aid/scripts/migrate/` (PL-02).
  - [ ] SG-02, SG-04, DT-01 and `test-skill-steps.sh` pass in the scratch copy, `test-doc-counts.sh` passes live, and the site `npm test` passes after regeneration.

### task-207: Writer unit cases: one layout, --plan-sync, the re-render and exit 11 [TEST]

- **Stanza wave:** 5. **Depends on:** task-190, task-197.
- **Source:** AC-19.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains the cases of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`: `--task-id` and
    `--findings` write `tasks_lifecycle` in the work file, with or without `--delivery-id`; the `--delivery-id`
    modes write `deliveries.<id>`; `--lifecycle Pending-Spec` exits 4; `--plan-sync` adds `Pending` entries,
    cancels a `Pending` task whose file is gone, exits 4 and writes nothing for a gone task in another state, and
    changes nothing on a second run; a state write re-renders the checklist; a malformed graph exits 11 with both
    files unchanged; no `PLAN.md`, no render; `--create --path` and `"Pipeline Path"` are refused; every file
    written parses through the dashboard reader with no warning.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-208: Unit cases: test-derive-waves.sh for --plan [TEST]

- **Stanza wave:** 5. **Depends on:** task-189.
- **Source:** AC-19.
- **Scope:**
  - `tests/canonical/test-derive-waves.sh` gains the cases of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`: `--plan` writes each
    delivery's checklist and a second run is byte-identical; `--check` returns 0, 1, 2 and 3 and writes nothing;
    a dependency on a later delivery's task, a cycle and an undefined task each exit 2 with the plan unchanged;
    a delivery with no stanza gets one appended; a dependency on an earlier delivery is met; every task line's
    link resolves; an old stanza's `#### Execution Graph` and `wave-map` are replaced and its authored lines
    kept, and so is a sibling `### delivery-NNN Execution Graph` section; the marks follow the work file;
    `--from-tasks` output is unchanged.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its branch is broken in a scratch copy of the script.
  - [ ] The cases are deterministic and use temporary fixtures only.

### task-209: Unit cases: test-slice-requirements.sh for the new Source forms [TEST]

- **Stanza wave:** 5. **Depends on:** task-191.
- **Source:** AC-19.
- **Scope:**
  - `tests/canonical/test-slice-requirements.sh` gains the cases of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`: both new Source
    forms slice as Feature 005 says, from a task file at `tasks/task-NNN/DETAIL.md`; the old form still reads.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its branch is broken in a scratch copy of the script.
  - [ ] The cases are deterministic and use temporary fixtures only.

### task-210: test-work-state-migration.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-203.
- **Source:** AC-19, AC-25.
- **Scope:**
  - Create `tests/canonical/test-work-state-migration.sh`, which runs every case task-201 builds, as REQUIREMENTS.md § 11 Feature 006
    `##### 9. Testing` lists them, in bash and in PowerShell under `pwsh`: each converts to its expected file and
    tree; the Q129 case keeps its nested delivery data and loses the flattened keys; a second run changes nothing,
    the records included, also for a work whose type the first run left empty; bash and PowerShell give the same
    bytes. It has `# COVERS:` lines.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, with each case named.
  - [ ] Changing one byte of the PowerShell output in a scratch copy fails the byte-identity case; the suite is deterministic and cleans up.

### task-211: Dashboard cases: Planning, Building with two deliveries, an old nested work [TEST]

- **Stanza wave:** 5. **Depends on:** task-199, task-200.
- **Source:** AC-19, AC-41.
- **Scope:**
  - Add to the dashboard tests (REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`, Dashboard): fixtures for a single-layout work at Planning
    (task files, no entries yet), at Building with two deliveries (lanes per delivery, delivery names from the
    plan), and an old nested work (`layout_status: old`, the card line); the depth badge and path line in
    `test_index_html.py`; the parity tests.
- **Acceptance criteria:**
  - [ ] Both readers give the same result for every fixture, and the parity tests pass.
  - [ ] `test_index_html.py` asserts the badge, the path line and the old-layout line, and passes.

### task-212: test-plan.sh (PL-01 to PL-07) and the exempt-list rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-186, task-194, task-196, task-197, task-198, task-200, task-204, task-206.
- **Source:** AC-19.
- **Scope:**
  - Create `tests/canonical/test-plan.sh` with PL-01 to PL-07, as REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing` defines them. It has
    `# COVERS:` lines.
  - `tests/canonical/skill-steps-exempt.tsv`: the `shortcut-engine.md` row's `checks` gain `PL-06` (owner Feature
    009); a new row, `aid-execute`, checks `PL-04`, owner Feature 007.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, and `test-skill-steps.sh` passes with the changed exempt list.
  - [ ] Each check fails its own mutation in a scratch copy: a `canonical/skills/aid-detail/` folder; a kept file naming `aid-detail`; `finish.md` without `--plan-sync`; a skill naming `deliveries/delivery-`; the template with `delivery_state`; a `## State: DETAIL` heading in a skill; `skill-steps.md` without the Q73 rule.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-213: Samples 006-01 to 006-05 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-195, task-197, task-206.
- **Source:** AC-10, AC-19, AC-28.
- **Scope:**
  - Create under `tests/conversation/samples/feature-006/`, with frontmatter `skills: aid-plan`, their fixtures and
    the checks of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`: `006-01-bug-fix-one-delivery`, `006-02-split-work-delivery-per-feature`,
    `006-03-lite-no-stop`, `006-04-reshape-the-plan` and `006-05-extra-delivery-for-a-migration`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are five files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-214: Samples 006-06 to 006-08 and the deferred rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-198, task-203, task-204, task-213.
- **Source:** AC-19, AC-28, AC-37.
- **Scope:**
  - Create `006-06-plan-change-during-building` (deferred: Feature 007), `006-07-deploy-selects-deliveries`
    (`skills: aid-deploy`) and `006-08-old-work-after-migration` under `tests/conversation/samples/feature-006/`,
    with their fixtures and the checks of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing`.
  - Update `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, Lists other features own): the
    `skill:aid-plan` and `skill:aid-deploy` rows go (covered by `006-01` and `006-07`); `005-13` runs now; `002-08`
    and `002-09` wait only for Feature 007; a row for `006-06`, waiting for Feature 007.
  - Smoke run (Q134 D8): `006-07`, `006-08` and `005-13` once each, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are three new files, each `covers` matches the spec's sample table, and `006-06` has its `deferred.tsv` row.
  - [ ] DT-01 and SS-09 pass, with no `skill:aid-plan`, `skill:aid-detail`, `skill:aid-deploy` or `005-13` row left.
  - [ ] Each smoke run has its result reported.

### task-215: test-plan.sh and test-work-state-migration.sh in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-210, task-212.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-plan` and
    `test-work-state-migration`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's text.
- **Acceptance criteria:**
  - [ ] Each name appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-216: KB decisions, schemas, glossary, tech debt and backlog for the plan and one state file [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-187, task-190, task-206.
- **Source:** AC-19, AC-24.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, KB and Release notes):
    - `decisions.md`: the new decision "one state file per work; the plan is a generated checklist of deliveries,
      derived waves and atomic tasks whose task files are the only source". It amends D29, marked in the summary
      table and in D29's section;
    - `artifact-schemas.md`: the single layout, `deliveries`, `tasks_lifecycle`, the plan and the task file; the
      delivery and task state files and the derived views go;
    - `domain-glossary.md`: delivery, wave and the plan checklist; Detail and the stored execution graph go;
    - `tech-debt.md`: W5-5's task-state half and SY-5, SY-6 narrowed;
    - `backlog.md` § Next Release: the three old -> new rows (AC-24).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] The backlog rows carry the spec's New text, and D29 is marked in the summary table and in its section.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-217: KB architecture, contracts and quality documents for the plan and one state file [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-195, task-199, task-203, task-206.
- **Source:** AC-19.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, KB): `pipeline-contracts.md` and
    `architecture.md` (Plan and Detail become one Planning row; the work layout; the loops that reach the plan
    now reach `/aid-plan` REVISE); `capability-inventory.md`, `module-map.md`, `project-structure.md`;
    `quality-gates.md` (one plan check replaces the plan and detail gates and the per-delivery review).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'aid-detail|deliveries/delivery-'` finds nothing outside marked history.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-206 leaves it.

### task-218: KB test landscape for the plan suites, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-207, task-208, task-209, task-211, task-214, task-215, task-216, task-217.
- **Source:** AC-19, AC-25.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-plan.sh` and `test-work-state-migration.sh` and their lane; the new
    cases of `test-writeback-state.sh`, `test-derive-waves.sh` and `test-slice-requirements.sh`; the dashboard
    cases.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed `render-kb-view.sh` (G0). This delivery's
    resync migrates this work's state, not the KB.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names both new suites and their lane.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-plan` rewritten (six steps, six references and the brief); `aid-detail`, both state templates and `delivery-plans/` deleted | 192, 193, 194, 195; 206 |
| `plan-template.md`; `task-detail-template.md` rewritten | 186 |
| `derive-waves.sh --plan`; the writer's single layout, `--plan-sync`, the re-render and exit 11, plus the fork | 189; 188, 190, 197 |
| The gate's legacy block replaced by the old-layout check; allocation points pass `--depth`; the engine's PLAN and DETAIL use `--plan-sync`; `aid-deploy` reads `deliveries` | 204; 197; 197; 198 |
| The format-6 work-state step in both twins, fixtures first, with the `Test-AidInstaller.ps1` cases | 201, 202, 203 |
| The dashboard's one layout, the old-layout diagnosis, the depth badge and the path line | 199, 200 |
| `test-plan.sh` PL-01 to PL-07; `test-work-state-migration.sh` (incl. the Q129 fixture); the exempt-list rows; `SUITES` | 212; 210 (201); 212; 215 |
| `test-derive-waves.sh` gate cases | 208 |
| Samples `006-01` to `006-05`, `006-07`, `006-08`, `005-13` (run); `006-06` deferred | 213, 214 |
| G0: AC-24 rows; KB; `INDEX.md`; `kb.html` | 216; 216, 217, 218; 218; 218 |

**Steps that are not tasks:**
1. `--delivery-id 008 --lifecycle Executing`.
2. The tasks, each tracked in its per-task `STATE.yml`.
3. Verification; its grade recorded with `--delivery-id 008 --gate-field Grade` before the resync (PLAN.md
   delivery-008 Notes).
4. The resync (`delivery-008: resync`): `aid update` installs the new writer and `derive-waves.sh`, removes
   `aid-detail` and the deleted templates through the manifest, and runs the format-6 work-state step on this
   work (Q129, Q119, Q127).
5. **After the resync, in the gate session (G8):** `derive-waves.sh --plan` (installed) renders this work's
   `PLAN.md` checklists, replacing each `### delivery-NNN Execution Graph` section and its `wave-map`; committed
   as a work-folder change, not resync-relevant. Also `(cd site && npm run gen:reference)` and the site `npm test`: a site page generated from a file the resync
     changes (`reference/settings.md` from `.aid/settings.yml`) is regenerated and committed; a no-op when
     nothing changed. The KB is not changed by this resync, so
   `INDEX.md` and `kb.html` stay as task-218 left them.
6. The gate, in the same session, after step 5:
   - the stanza's criteria, including this work's migrated state: no `deliveries/delivery-*/STATE.yml`, every
     task with `tasks/task-NNN/DETAIL.md` and a `tasks_lifecycle` entry, and `derive-waves.sh --plan --check`
     exiting 0 on its `PLAN.md`;
   - `006-01` to `006-05`, `006-07`, `006-08` and `005-13` at 3 of 3, `005-07` through Planning, `001-07` again;
   - G0 with the baselines; the tracking proof for task-185 to task-218, read from each per-task file's history
     (`git log -- <its path>`).

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-185
wave 2: task-186, task-187, task-189, task-191
wave 3: task-188, task-192, task-193, task-199, task-201, task-208, task-209
wave 4: task-190, task-196, task-198, task-200, task-202
wave 5: task-194, task-197, task-203, task-211
wave 6: task-195, task-204, task-207, task-210
wave 7: task-205
wave 8: task-206
wave 9: task-212, task-213, task-216, task-217
wave 10: task-214, task-215
wave 11: task-218
```

Step 5 writes the table under `### delivery-008 Execution Graph`, one task per row, from the task files'
`**Depends on:**` lines.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | "bash, then its PowerShell twin, with fixtures written first" (wave 4), and a step too big for one task. | Fixtures first (201, a TEST task: a sourced builder and the expected trees). Then two IMPLEMENT tasks by part -- the layout conversion (202), then every work's rules (203) -- each writing bash first and then its twin, so the twins are never split across tasks and parity holds at every task's end (delivery-005 S3). Then the suite (210). | PLAN wave 4; delivery-005 S3; `test-aid-cli-parity.sh` runs both twins. |
| S2 | The writer's changes in three tasks. | 188 (one layout, `--lifecycle`, the fork); 190 (`--plan-sync`, the re-render, exit 11; needs `--plan`); 197 removes `--create --path` and `"Pipeline Path"` in the same task as their last callers. | G7-like: no caller fails between tasks. |
| S3 | `aid-plan`'s rewrite. | Three tasks create the new references, unreferenced until task-195 rewrites `SKILL.md` and deletes the two old ones (as delivery-007 S1). | One session and one review per task. |
| S4 | The state templates and `delivery-plans/` still have users (`aid-detail`). | Deleted with `aid-detail` in task-206. | G6. |
| S5 | The gate's legacy block "goes once the step exists". | Task-204, after the format-6 step (203) and after the gate's `--path` edit (197). | F006 § 8. |
| S6 | This work's own shapes. | Explicit cases: its plan's sibling `### delivery-NNN Execution Graph` sections (189, 208) and its nested-plus-flattened `STATE.yml` (201, 203). | PLAN delivery-008 gate; Q129. |
| S7 | The gate's `--plan --check` on this work needs a render the migration does not do. | A listed step after the resync, in the gate session (§ 4 step 5). | G8. |
| S8 | `006-06` is the feature's one deferred sample. | Written in task-214 with its row. | F006 § 8, Lists. |
| S9 | Unit cases, samples, the CI lane and the test landscape. | As in the earlier deliveries. | Q134 D2, D8; Q135 R1, R3. |

---

## 7. Flagged for the maintainer

- **F-1 (spec gap, F006 § 8).** The migration maps a per-task state file's cells to `tasks_lifecycle` "with
  today's fields and its `quick_check` text value", but says nothing of the per-task `dispatch_log` list.
  Recommendation: drop it, with a warning when it is not empty. It is a dispatch record, not task state, and this
  work's are all empty. Tasks 201 and 202 are written on that recommendation, marked as pending your
  confirmation.
- **Forward note for deliveries 010-014 (not this delivery).** Every task file so far carries the Execution
  protocol note citing `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`, which
  delivery-009 deletes; F006's rewritten template words that note differently. When detailing 010-014 I will flag
  the note's wording rather than guess.
