# Detail proposal -- delivery-002: One work record and one set of step rules (Feature 002, engine)

> **Superseded by the task files.** After the light-review fixes (general rules G1-G6, Q137), the
> dependencies, scopes and criteria in this proposal's tables, task blocks and execution graph no longer
> match the task files. The task files under `deliveries/delivery-002/tasks/` are the source of truth. Step 5
> builds PLAN.md's Execution Graph from their `**Depends on:**` lines, never from this proposal.

This is `aid-detail` FIRST-RUN Step 1 for **delivery-002**. It proposes the delivery's task breakdown
for the maintainer's approval (Q133). No task folder is created until it is approved. Numbering continues
from delivery-001's task-019.

Inputs read:
- `PLAN.md`: the delivery-002 stanza, its Notes (Q121, Q122), § Common Gate (G0), "Testing before the
  resync" and § Toolchain and Branching;
- `REQUIREMENTS.md` § 11 Feature 002 (all eight subsections and Criteria traceability);
- the `qa` Q115, Q121, Q122 and Q134;
- the delivery-001 task files.

Measured at base `a3b28db4`:
- 59 `SKILL.md` files carry a Dispatch table or a `## State:` section. That is SS-02's set: 58 once
  `aid-triage` is gone, plus `aid-orchestrate`.
- 126 files under `canonical/` carry an `**Advance:**` line.
- 28 files carry 61 `PAUSE-FOR-USER` lines.
- `canonical/aid/scripts/execute/writeback-state.sh` is 1880 lines.

Anchors read as in the delivery-001 proposal. "F002 § 4" is `##### 4. Steps and hand-offs` of
Feature 002's technical specification.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-020 | Delivery-002 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-021 | Work-state template record keys and the project-state template | IMPLEMENT | 2 | 2 | 020 |
| task-022 | Question protocol `question-protocol.md` | IMPLEMENT | 2 | 2 | 020 |
| task-023 | Step rules `skill-steps.md` | IMPLEMENT | 2 | 2 | 020 |
| task-024 | Site flow builder learns the new advance words | IMPLEMENT | 2 | 2 | 020 |
| task-025 | Writer: new phase names, record modes and the fork | IMPLEMENT | 2 | 3 | 021 |
| task-026 | Samples `002-01` to `002-04` and `002-14` (asking, run at delivery-003) | TEST | 5 | 3 | 022 |
| task-027 | Samples `002-15` to `002-19` (asking skills, run at delivery-003) | TEST | 5 | 3 | 022 |
| task-028 | Samples `002-06` to `002-13` (deferred to later features) | TEST | 5 | 3 | 022, 023 |
| task-029 | Writer: hand-off and question modes | IMPLEMENT | 2 | 4 | 021, 025 |
| task-030 | Work-initiation gate: `--create` in § 3a, the record in § 3b | IMPLEMENT | 3 | 4 | 023, 025 |
| task-031 | Dashboard readers: phase names and `intent.phases` | IMPLEMENT | 4 | 4 | 021, 025 |
| task-032 | `/aid-orchestrate` start, resume and cancel, and the `rules.md` protocol bullet | IMPLEMENT | 3 | 5 | 022, 029, 030 |
| task-033 | Dashboard page: phase order and one stage rail per work | IMPLEMENT | 4 | 5 | 031 |
| task-034 | Design allocation: `design-lifecycle.md`, `aid-design`, `aid-brainstorm` | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-035 | The `aid-design-*` family on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-036 | The KB-writing `aid-create-*` / `aid-update-*` family on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-037 | The shortcut engine on the gate and the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-038 | `aid-describe` on the gate and the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-039 | `aid-define` and `aid-specify` on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-040 | `aid-plan`, `aid-detail` and `aid-execute` on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-041 | `aid-discover` on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-042 | `aid-update-kb`, `aid-ask`, `aid-summarize` and `aid-housekeep` on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-043 | `aid-deploy`, `aid-monitor` and the ticket skills on the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-044 | The seven starters on the gate, the writer and the step rules | IMPLEMENT | 4 | 5 | 023, 025, 030 |
| task-045 | KB decisions, schemas, glossary and backlog for the engine | DOCUMENT | 4 | 5 | 023, 029, 030 |
| task-046 | Writer unit cases: record modes | TEST | 5 | 5 | 029, 031 |
| task-047 | Gate unit cases: a `--check` fixture per resume row | TEST | 5 | 5 | 029, 030 |
| task-048 | Reader unit cases: phase mapping and parity | TEST | 5 | 5 | 031 |
| task-049 | KB architecture and per-skill state machines | DOCUMENT | 4 | 6 | 032, 034-044 |
| task-050 | `test-skill-steps.sh` group E and the shared exempt list | TEST | 5 | 6 | 032, 033, 034-044 |
| task-051 | `test-never-merges.sh` (NM-01 to NM-04) | TEST | 5 | 6 | 040, 042 |
| task-052 | Writer unit cases: hand-off and question modes | TEST | 5 | 6 | 046 |
| task-053 | Stage-rail test `test_home_stage_rails.mjs` | TEST | 5 | 6 | 033 |
| task-054 | Samples `002-05`, `002-20` and `002-21` (run at this gate) | TEST | 5 | 6 | 032, 034-044 |
| task-055 | `test-deferred-tests.sh` and the deferred list | TEST | 5 | 7 | 026, 027, 028, 054 |
| task-056 | The new suites in the CI lane, and the release check | CONFIGURE | 5 | 8 | 050, 051, 055 |
| task-057 | KB test landscape for the engine suites, and the regenerated index | DOCUMENT | 5 | 9 | 045, 049, 053, 056 |

That is 38 tasks. The resync follows task-057; it is a delivery step, not a task (§ 5).

---

## 2. Rules carried from delivery-001

Every task file carries delivery-001's blocks, unchanged in substance:

- the Execution protocol note;
- the **same-task rule (Q106)**, with the coverage-ledger rows;
- the **findings** bullet, which names `research/delivery-002-sites.md` here;
- **site regeneration** in any task that changes `canonical/skills/**` or a template the flows read;
- the **standard test step**, with one addition to step 5: run `node --test <file>` for each dashboard
  `.mjs` test the task changes.

Two rules matter more here than in delivery-001:

- **The writer's stricter names reach the live tree only at the resync.**
  - From task-025 on, canonical `writeback-state.sh` refuses the old phase names, while skills still
    write them until stanza wave 4.
  - The installed copy that builds this work is not replaced until the resync.
  - This work writes no `Phase` after delivery-001's start (PLAN § How deliveries 001-009 are built,
    step 1).
  - In the meantime, only suites can meet the mismatch, and the same-task rule keeps them green.
- **Parallel sweep tasks touch disjoint skill files.** Some suites assert text from several of them, for
  example the site's `flow-extract-*` tests. task-020's delta section names each such suite and the order
  the tasks run it in, as task-001 does. Q127 builds one task at a time.

---

## 3. Tasks

Every `Source` line reads `feature-002-step-by-step-decisions -> delivery-002 -> AC-...`. Type defaults
and "all section-6 quality gates pass" apply as in delivery-001.

### task-020: Delivery-002 site search and reconciled edit list [RESEARCH]

- **Depends on:** --.
- **Source:** AC-11, AC-37, AC-41.
- **Scope:** creates `research/delivery-002-sites.md`, with the same shape and owner classes as task-001.
  It re-runs the searches stanza wave 1 names, at the base commit:
  - **P1** SS-11's forms over SS-11's scope. The spec says 55 lines today.
  - **P2** SS-14 (b): `initiator:`, copying the template, hand-written record blocks.
  - **P3** SS-14 (d): continuation lines.
  - **P4** SS-12: hand-written `lifecycle: Completed` / `Canceled`.
  - **P5** SS-03: `PAUSE-FOR-USER` and every `**Advance:**` word.
  - **P6** SS-02: every `SKILL.md` with a Dispatch table or a `## State:` section.
  - **P7** NM-01 to NM-04 over NM's globs. Only the two exemptions should fire.
  - **P8** The Q106 map for every file on the edit list, including `site/scripts/__tests__/`,
    `dashboard/reader/tests/` and `dashboard/server/tests/`.
  - **P9** The suites and tests that feed an old phase name to a writer, or assert a reader's phase
    output (F002 § 2, the Tests rule).
  - **P10** Whether today's writes are already atomic (temp file, then rename under the lock), so
    task-025 knows the gap.
  - Each hit gets an owner among task-021 to task-057.
- **Suites updated in the same task:** none (work folder only).
- **Acceptance criteria:**
  - [ ] Each of P1-P10 shows its exact command, and re-running it at the named base reproduces its hits.
  - [ ] The P1 count and the P2 / P3 matches are compared with the spec's own statements: "55 lines";
    "every file (b) matches is in Files and layout"; "(d) matches exactly the continuation lines listed".
    Any difference is listed with its owner.
  - [ ] Every hit has exactly one owner, and the count of rows with an empty owner cell is 0. Every suite
    assigned to two tasks that do not depend on each other is listed, with the order to run them.
  - [ ] RESEARCH defaults overridden as in task-001.

### task-021: Work-state template record keys and the project-state template [IMPLEMENT]

- **Depends on:** task-020.
- **Source:** AC-37, AC-38, AC-41.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml` (F002 § 2):
    - the `phase` enum becomes `Definition | Specification | Planning | Building | CI`, with default
      `Specification`;
    - new keys `step`, `step_detail`, `handoffs: []`, and `qa: []` on every layout (the full-layout
      omission rule goes);
    - the header states the block-style rule (KI-002).
  - Creates `canonical/aid/templates/project-state-template.yml`: `qa: []` only, block style, with the
    same header rule.
- **Suites updated in the same task:** `test-work-state-template.sh` (scratch) for the WS02 and WS04 phase
  enum, and any suite P8 or P9 assigns.
- **Acceptance criteria:**
  - [ ] `grep -n '^phase: Specification$'` and the five-name enum comment are both present in the work
    template, and no old phase name sits in a key or enum line (the SS-11 forms, run by hand).
  - [ ] Both templates parse through `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs`
    with no warning (SS-08's rule, ahead of its suite). The command is in the report.
  - [ ] `grep -nE '^[^#]*:[[:space:]]*[[{][^]}]'` finds nothing in either template.
  - [ ] `test-work-state-template.sh` passes in the scratch copy.

### task-022: Question protocol `question-protocol.md` [IMPLEMENT]

- **Depends on:** task-020.
- **Source:** AC-8, AC-9, AC-28, AC-40.
- **Scope:** creates `canonical/aid/templates/question-protocol.md`, of type `template-own`. It holds
  F002 § 3:
  - one question in plain text, with **Why I ask**, **My recommendation**, options and the free answer;
  - importance labels, groups of 3-5, breaks, follow-ups, and `Assumed` for questions already answered;
  - reviews in chunks, and small decisions confirmed in one batch;
  - the question record shape and its four states;
  - `--ask` before showing a question and `--answer` after it;
  - the intake-question exception;
  - where each record lives: the work, `.aid/STATE.yml`, or the KB file;
  - that it runs only in the main conversation: sub-agents record their questions and never ask.
- **Suites updated in the same task:** none exist.
- **Acceptance criteria:**
  - [ ] The file holds F002 § 3's example question block, and states rules 1-10 of FR-17, each under a
    greppable heading or bullet (AC-8, AC-28).
  - [ ] The record shape lists `id`, `category`, `impact` (`High`, `Medium` or `Low`), `state` (`Pending`,
    `Answered`, `Skipped` or `Assumed`), `asked_by`, `step`, `context`, `suggested`, `answer`,
    `answered_by` and `applied_to`, plus `covers` / `commit` for approvals.
  - [ ] It names the intake exception, `--ask` / `--answer` / `--project`, and no host picker.
    `grep -c AskUserQuestion` on the file prints 0. Every `.aid/runtime/` pointer resolves under
    `canonical/aid/` (SR-01).

### task-023: Step rules `skill-steps.md` [IMPLEMENT]

- **Depends on:** task-020.
- **Source:** AC-10, AC-11, AC-37, AC-38.
- **Scope:** creates `canonical/aid/templates/skill-steps.md`, of type `template-own`:
  - the step table shape, and the advance words `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL` and `HALT`, with
    the six-part step procedure (F002 § 4);
  - **§ The work record**: when it is written, fail-closed, starting versus resuming, detection's two
    uses, and recovery (F002 § 2);
  - the one standard **State Detection rule** that every skill's section cites;
  - **§ When approvals happen**: the table, coinciding approvals, approval records, and "before the push
    it controls";
  - the never-merges rule;
  - what the user sees (no banners), and the one progress line.
  - It cites `question-protocol.md` for `ASK`. When tasks are built one at a time, build task-022 first.
- **Suites updated in the same task:** none exist.
- **Acceptance criteria:**
  - [ ] The six advance words, each with its meaning, appear in one table. The step-entry rule says
    `--step` is written before any work in the step, which is SS-02's clause (AC-37).
  - [ ] § The work record states fail-closed, the two detection uses, and recovery: one confirmation
    question, then `--repair`, which needs `--reading` when the record has none (AC-37). `PASS`, `CALL`
    and `HALT` with nested calls match F002 § 4 steps 4-6 (AC-38).
  - [ ] § When approvals happen holds the nine-row `full` / `lite` table and the M11 and Q36 rules
    (AC-10), and the file says AID never merges, naming Feature 008's conflict-merge exception (AC-11).
  - [ ] SR-01: every pointer resolves under `canonical/aid/`.

### task-024: Site flow builder learns the new advance words [IMPLEMENT]

- **Depends on:** task-020.
- **Source:** AC-37.
- **Scope:**
  - `site/scripts/lib/flow-graph/advance.mjs` gains `ASK`, `WAIT`, `PASS` and `CALL`, and keeps parsing
    today's words, because skills convert in stanza wave 4. This is "only add" (stanza wave 2).
  - `site/scripts/__tests__/flow-advance.test.mjs` gains cases for each new word.
- **Suites updated in the same task:** the site tests P8 assigns.
- **Acceptance criteria:**
  - [ ] `(cd site && npx vitest run scripts/__tests__/flow-advance.test.mjs)` passes, with a case per new
    word. `ASK -> [State: X]` yields an edge to X, and `PASS` / `CALL` yield their edge kinds.
  - [ ] `(cd site && npm run gen:skills)` on the unchanged skills produces no diff, so the old words still
    parse. The full site `npm test` passes.

### task-025: Writer: new phase names, record modes and the fork [IMPLEMENT]

- **Depends on:** task-021. `--create` copies the template and fills its new keys.
- **Source:** AC-37, AC-41.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (F002 § 2 and § 4, Writer modes):
    - every write is atomic: a temporary copy renamed under the lock, so a failed write leaves the file
      byte-for-byte unchanged;
    - the header documents exits 7, 8 and 9, and "you are here (edit this)" becomes "this is the source
      (edit this)";
    - the `--pipeline` Phase check accepts only the five new names, with the error text to match;
    - setting `lifecycle` to `Completed` or `Canceled` also sets `active_skill: none` and clears `step` /
      `step_detail`, in the same locked write;
    - new modes `--create` (with `--path` and `--minimum-grade`), `--step`, `--reroute`, `--check` and
      `--repair`.
  - `dashboard/scripts/writeback-state.sh` (the fork): the new phase names plus `Deploy`, in its three
    places.
- **Suites updated in the same task:** `test-writeback-state.sh`, `test-pipeline-status-walkthrough.sh`
  (A1, M4), `test-lite-work-end-to-end.sh`, `test-producer-completeness.sh`, `test-disjoint-merge.sh`, the
  dashboard tests that feed an old name to a writer, and any suite P8 or P9 assigns. Only existing
  assertions change here; the new-mode unit cases are task-046 (PLAN: unit cases belong to the last wave).
- **Acceptance criteria:**
  - [ ] `writeback-state.sh --pipeline --field Phase --value Execute` exits 4 on a fixture work, and
    `--value Building` succeeds. The fork accepts `Deploy` and the five names, and nothing else.
  - [ ] A scratch run of `--create` on an empty folder writes `intent.reading`, `intent.request`,
    `active_skill`, `step`, `pipeline.initiator`, `phase`, `lifecycle: Running`, `started` and `updated`.
    A second `--create` exits 8. A missing `--skill` exits 5.
  - [ ] `--check` exits 9 on a work with no `intent.reading` and 0 on the one `--create` wrote. A forced
    failure (an unwritable target) leaves `sha256sum` of the file unchanged.
  - [ ] `test-writeback-state.sh` and `test-pipeline-status-walkthrough.sh` pass live, and the rest of
    the selection passes.

### task-026: Samples `002-01` to `002-04` and `002-14` (asking, run at delivery-003) [TEST]

- **Depends on:** task-022.
- **Source:** AC-8, AC-28.
- **Scope:** creates these files in `tests/conversation/samples/feature-002/`, with frontmatter `skills:`
  and their fixtures:
  - `002-01-connector-question`;
  - `002-02-settings-groups-and-breaks`;
  - `002-03-follow-up-and-skip-answered`;
  - `002-04-skip-then-another-user`, which checks that `.aid/STATE.yml` goes `Skipped` -> `Answered`
    with a different `answered_by`;
  - `002-14-orchestrate-unsure-reading`.
  These are written now so that DT-01 can list them (D1). They run at delivery-003, and get no smoke run
  here because the behaviour they need is delivery-003's.
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] There are five files with the spec ids. `covers` and `skills:` match F002 § 8 (`002-01`, `002-02`
    and `002-14`: AC-8 and AC-28; `002-03` and `002-04`: AC-28).
  - [ ] No answer sheet names a skill. The checks use `run.py`'s grammar and give the same verdict when
    re-run on the same transcript.

### task-027: Samples `002-15` to `002-19` (asking skills, run at delivery-003) [TEST]

- **Depends on:** task-022.
- **Source:** AC-28.
- **Scope:** creates `002-15-which-tracker` (two trackers catalogued), `002-16-research-without-a-question`,
  `002-17-review-publish-approval`, `002-18-report-what-to-analyze` and `002-19-monitor-finding-question`,
  with their fixtures. Written now for DT-01 (D1).
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] There are five files. `covers` is AC-28, and each `skills:` names its skill per F002 § 8.
  - [ ] `002-16` and `002-18` do not count their intake questions against the protocol (F002 § 3, the
    intake exception). No answer sheet names a skill.

### task-028: Samples `002-06` to `002-13` (deferred to later features) [TEST]

- **Depends on:** task-022, task-023.
- **Source:** AC-9, AC-10, AC-11, AC-37, AC-38.
- **Scope:** creates `002-06` to `002-13` per F002 § 8, the "written now" samples a later feature runs.
  These are review in chunks, small decisions, `full` and `lite` approvals, a pull request only when
  asked, resume at the saved step, Definition passing on, and the mid-task KB update.
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] There are eight files, and `covers` matches F002 § 8 for each. `002-11` checks for no banner text
    and a resume at the saved step. `002-13` checks the `handoffs` entry: from, to, why and return point.
  - [ ] Each file's header comment names the features it waits for, exactly as task-055's rows will.

### task-029: Writer: hand-off and question modes [IMPLEMENT]

- **Depends on:** task-021 (`project-state-template.yml`), task-025 (same file).
- **Source:** AC-10, AC-28, AC-38.
- **Scope:**
  - `writeback-state.sh` gains `--handoff` (call; pass with `--phase`; pass without it), `--handoff-return`
    (newest open call first; exit 7 with none), `--ask` (the next free `Q<n>`, printed), `--answer` (each
    state, `--covers` and `--commit`), and `--project` (`.aid/STATE.yml`, created from its template when
    missing).
  - Everything is written in block style.
- **Suites updated in the same task:** existing `test-writeback-state.sh` assertions only, and any suite P8
  assigns.
- **Acceptance criteria:**
  - [ ] A scratch call, then a nested call, then two `--handoff-return` runs restore the inner caller,
    then the outer one. A third run exits 7 (AC-38).
  - [ ] Two `--ask` calls print consecutive ids. `--ask --project` creates `.aid/STATE.yml` from the
    template. `--answer --state Answered --covers X --commit C` writes `covers` and `commit` (AC-10).
  - [ ] Each file written parses through both readers with no warning. `test-writeback-state.sh` passes.

### task-030: Work-initiation gate: `--create` in § 3a, the record in § 3b [IMPLEMENT]

- **Depends on:** task-023 (§ The work record, which the gate cites), task-025 (`--create`, `--check`,
  `--repair`).
- **Source:** AC-37.
- **Scope:** `canonical/aid/templates/work-initiation-gate.md`:
  - § 3a NEW reads the type with `check-intent.md` and runs `writeback-state.sh --create` before handing
    the work back. The hand-back carries the one line "`STATE.yml` was created by the gate; skip any
    instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand ...".
  - § 3b CONTINUATION gets the three-row resume table, `--check` with a confirmed `--repair`, and the
    legacy block between `<!-- legacy-phase-map: begin -->` / `end`.
  - The same-invocation sentence goes.
- **Suites updated in the same task:** `test-work-initiation-gate.sh` (existing assertions), and any suite
  P2, P3 or P8 assigns. The new per-row fixtures are task-047.
- **Acceptance criteria:**
  - [ ] § 3a holds `writeback-state.sh --create` with `--reading`, `--skill` and `--step` (SS-14 (a)).
    § 3b's table has exactly the three rows of F002 § 2, first match wins.
  - [ ] Old phase names appear in the file only between the legacy markers (SS-11 by hand), and
    SS-14 (d)'s pattern matches only this file.
  - [ ] `test-work-initiation-gate.sh` passes live.

### task-031: Dashboard readers: phase names and `intent.phases` [IMPLEMENT]

- **Depends on:** task-021, task-025.
- **Source:** AC-41 (phase clause; the rest is delivery-003).
- **Scope:**
  - Phase: `dashboard/reader/models.py` (`Phase` enum and its docstring), `parsers.py` (the phase map,
    with old names inside `legacy-phase-map` markers) and `state_schema.py` (the comment example);
    `dashboard/server/reader.mjs` (`Phase` object and map).
  - Both readers pass `intent.phases` with the work, through `reader.py`, `server.py` `_ser_work` and
    `server.mjs`, for the stage rail (Q75).
- **Suites updated in the same task:** the `Phase.<old>` assertions and the
  `dashboard/reader/tests/fixtures/task011_golden/*.json` outputs (inputs keep their old names, per
  F002 § 2's Tests rule), the parity suites, and any suite P8 or P9 assigns.
- **Acceptance criteria:**
  - [ ] Each reader maps every old name and every new name to `Definition`, `Specification`, `Planning`,
    `Building`, `CI` or `Unknown`. The old names appear only inside the legacy markers (SS-11 by hand).
  - [ ] The serialized work carries `intent.phases` when the file has it. `test-dashboard-parity.sh` and
    `test-dashboard-reader.sh` pass live, and `test-dashboard-parity-h.sh` passes in the scratch copy.

### task-032: `/aid-orchestrate` start, resume and cancel, and the `rules.md` protocol bullet [IMPLEMENT]

- **Depends on:** task-022, task-029, task-030.
- **Source:** AC-37 (resume clause), AC-8.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/start-or-resume.md`:
    - a new work through the gate's § 3a `--create`;
    - resume from the record only, with the open questions (`Pending`, `Skipped`) first;
    - "cancel work-NNN": one confirmation, then `--pipeline --field Lifecycle --value Canceled`.
  - `aid-orchestrate` `SKILL.md` cites `skill-steps.md` (SS-02) and gets the standard State Detection
    rule.
  - `canonical/aid/rules.md` § Handling a request: the last bullet becomes the spec's two lines, naming
    `question-protocol.md` and "AID never merges".
  - The description and guide line already say "start, resume or cancel" (delivery-001); this task
    verifies them.
- **Suites updated in the same task:** `test-skill-guide.sh` SG-01 (scratch), and any suite P8 assigns.
- **Acceptance criteria:**
  - [ ] The SG-01 count of § Handling a request is 19, and `test-skill-guide.sh` passes in the scratch
    copy.
  - [ ] `start-or-resume.md` holds the cancel path, with no new work created, one question, then the
    writer. It reads the resume point only from the record. Each file still keeps within its line cap.
  - [ ] `grep -c 'skill-steps.md' canonical/skills/aid-orchestrate/SKILL.md` prints at least 1.

### task-033: Dashboard page: phase order and one stage rail per work [IMPLEMENT]

- **Depends on:** task-031.
- **Source:** AC-41.
- **Scope:** `dashboard/home.html`:
  - `PHASE_ORDER = ['Definition', 'Specification', 'Planning', 'Building', 'CI']`;
  - `PRE_EXEC_STEPS` becomes 3, with its comment;
  - `renderStageRail` draws the work's `intent.phases` plus Done, falling back to `PHASE_ORDER`;
  - `_renderLiteStageRail` and `LITE_STAGES` go, and the stale comments are rewritten.
- **Suites updated in the same task:** `dashboard/server/tests/test_index_html.py` (`PHASE_ORDER`), and
  every page test P8 assigns.
- **Acceptance criteria:**
  - [ ] `grep -c '_renderLiteStageRail\|LITE_STAGES' dashboard/home.html` prints 0, and the page holds no
    old phase name in the SS-11 forms.
  - [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` passes.

### task-034 to task-044: the stanza-wave-4 sweep [IMPLEMENT]

Each sweep task applies the same conversions to its own skill group. The groups are disjoint.

- **(a) Citation.** Every `SKILL.md` with a Dispatch table or a `## State:` section cites `skill-steps.md`
  (SS-02).
- **(b) Advance words.** Every `**Advance:**` word is translated one for one: `PAUSE-FOR-USER-DECISION`
  becomes `ASK` and keeps its step; `PAUSE-FOR-USER-ACTION` becomes `WAIT`; a pause that points at another
  skill becomes `ASK` then `HALT`, naming that skill in one line (SS-03).
- **(c) State Detection.** Each § State Detection carries the standard rule: it shapes the entry step and
  validates a saved step, and never routes.
- **(d) Group-specific sites.** Allocation points, continuation lines, finishers and phase writes, as each
  task lists.
- **Out of scope.** Banners, the chaining file and the protocol line are delivery-003's.

Every sweep task depends on task-023, task-025 and task-030. Each updates the suites P8 assigns to its
files, including the site tests that read its skill bodies, and regenerates the site.

Each sweep task's acceptance criteria are:

- [ ] Over its files, `grep -c 'PAUSE-FOR-USER'` prints 0, and every `**Advance:**` word is one of the
  six (SS-03 by hand).
- [ ] Every `SKILL.md` in its group with a Dispatch table or a `## State:` section names `skill-steps.md`
  (SS-02 by hand).
- [ ] The SS-11, SS-12 and SS-14 (b)/(d) patterns, run by hand over its files, match only lines in
  legacy markers or on the exempt list. Plus the group criterion below.
- [ ] Its suites pass where the test step puts them, and the site `npm test` passes after
  regeneration.

| Task | Group | Group-specific sites (d) | Group criterion | Source |
|---|---|---|---|---|
| task-034 | `canonical/aid/templates/design-lifecycle.md`, `aid-design`, `aid-brainstorm` | § Allocation calls the gate's § 3a and carries the "created by the gate" line; `aid-design` INTAKE step 4 allocation and its continuation line. `aid-brainstorm`'s binding line stays (exempt, SS-14), and so does `aid-design`'s finish (exempt, SS-12). | `design-lifecycle.md` names `work-initiation-gate.md` § 3a, with no template copy | AC-37 |
| task-035 | the 21 `aid-design-*` skills | none: they allocate through `design-lifecycle.md`, and their binding lines stay (exempt) | (a)-(c) hold in all 21 | AC-37 |
| task-036 | `aid-create-*` / `aid-update-*` for architecture, backlog, cicd, mvp, roadmap, stack, testing-strategy | none (exempt binding lines and finishes) | (a)-(c) hold in all 14 | AC-37 |
| task-037 | `canonical/aid/templates/shortcut-engine.md` | INTAKE Step 4 allocation goes through § 3a; the INTAKE literal seed becomes `--create --phase`; the continuation lines in § Design Notes and INTAKE Step 3 change; the SPEC, PLAN and DETAIL phase writes; the GATE enum sentence ("stays `Planning`") | `test-shortcut-engine-contract.sh` passes in the scratch copy | AC-37 |
| task-038 | `aid-describe` (`SKILL.md` and references) | § No works exist, § Direct `work-NNN` argument and § Arguments go through the gate; `--reset` is removed; the `state-first-run.md` 1b / 1b-ii seed becomes `--create --phase Definition`; the Continuation bullet changes; COMPLETION becomes `ASK` then `HALT` naming `/aid-define` | `grep -c -- '--reset' canonical/skills/aid-describe/SKILL.md` prints 0, and `test-describe-full-only.sh` passes | AC-37 |
| task-039 | `aid-define`, `aid-specify` | the three `--field Phase --value` writes take the new names | the SS-11 forms find nothing in either skill | AC-37, AC-41 |
| task-040 | `aid-plan`, `aid-detail`, `aid-execute` | the three phase writes take the new names; `aid-execute`'s "merge to main" stays (NM-04 exempt, Feature 007) | the SS-11 forms find nothing in the three skills | AC-37, AC-41 |
| task-041 | `aid-discover` | (a)-(c) only, across 19 files | `aid-discover`'s 16 PAUSE lines are gone | AC-37 |
| task-042 | `aid-update-kb`, `aid-ask`, `aid-summarize`, `aid-housekeep` | `aid-housekeep`'s `gh pr create` stays (NM-03 exempt, Feature 004) | (a)-(c) hold in all four | AC-37 |
| task-043 | `aid-deploy`, `aid-monitor`, `aid-read-ticket`, `aid-create-ticket`, `canonical/aid/templates/connectors/ticket-resolution.md` | `aid-deploy` `state-idle.md` becomes "it stays at `Building`"; the `state-done.md` prose is reworded so SS-12 does not match it | SS-12 finds nothing in `aid-deploy` | AC-37, AC-41 |
| task-044 | the starters `aid-research`, `aid-review`, `aid-test`, `aid-prototype`, `aid-report`, `aid-create-document`, `aid-update-document` | allocation through § 3a; one continuation line ("follow the gate's § 3b ..."), including `aid-review` § Step 5; the finish through the writer; their copy-the-template text goes | SS-12 and SS-14 (b)/(d) find nothing in the seven skills | AC-37 |

### task-045: KB decisions, schemas, glossary and backlog for the engine [DOCUMENT]

- **Depends on:** task-023, task-029, task-030.
- **Source:** AC-10, AC-24 (row), AC-37, AC-38.
- **Scope:** edits these documents under `.aid/knowledge/`. The interviewer, question-record and SY-6
  parts are delivery-003's (settled by rule, R5).
  - `decisions.md`: a new decision, "one question protocol run by the main conversation; saved steps;
    pass and call". It supersedes the chaining rule.
  - `artifact-schemas.md`: the new keys, `qa` on every work, `handoffs`, `.aid/STATE.yml` and the phase
    names.
  - `domain-glossary.md`: question protocol, step and hand-off.
  - `backlog.md` § Next Release: the `/aid-describe --reset` row (F002 § 7).
  - No work id.
- **Acceptance criteria:**
  - [ ] `backlog.md` has the `--reset` row with F002 § 7's New text. `decisions.md` has the new decision,
    and names the rule it supersedes.
  - [ ] `artifact-schemas.md` lists `step`, `step_detail`, `handoffs`, `qa` and `.aid/STATE.yml`, and
    shows only the five phase names as values.
  - [ ] No work id. The citation lint and frontmatter lint pass, and the text is accurate against
    `canonical/` after task-030.

### task-046: Writer unit cases: record modes [TEST]

- **Depends on:** task-029, task-031 (files parse through the updated readers).
- **Source:** AC-37, AC-41.
- **Scope:** `test-writeback-state.sh` (live) gains cases for:
  - `--create`: all fields in one write; exits 5, 4 and 8;
  - a failed write (lock timeout exit 2, and an unwritable file) leaving the file byte-for-byte
    unchanged;
  - `--check`: each missing and each inconsistent case gives 9, and a healthy record gives 0;
  - `--repair`, with its `lifecycle_history` entry and its `--reading` requirement;
  - `--reroute` and `--step`;
  - finishing clears the saved skill;
  - an old phase name is refused;
  - every written file parses through both readers.
- **Acceptance criteria:**
  - [ ] Each case above has a named assertion that passes. Breaking each matching code path in a scratch
    copy of the writer fails it.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-047: Gate unit cases: a `--check` fixture per resume row [TEST]

- **Depends on:** task-029, task-030.
- **Source:** AC-37.
- **Scope:** `test-work-initiation-gate.sh` gains the fixtures of F002 § 2:
  - a finished work, row 1 (even with a leftover saved skill);
  - no `intent.reading`, and a saved skill that is not installed, row 2;
  - a healthy work, and one with an open call, row 3;
  - an old-name work with no type, whose one confirmed `--repair` makes `--check` return 0 and the next
    resume land on row 3.
- **Acceptance criteria:**
  - [ ] There is one passing fixture per row, plus the repair fixture, each named by its row.
  - [ ] The suite passes live and is deterministic.

### task-048: Reader unit cases: phase mapping and parity [TEST]

- **Depends on:** task-031.
- **Source:** AC-41.
- **Scope:** fixtures in `dashboard/reader/tests/` and the Node suite:
  - a work at each of Definition, Specification, Planning, Building, CI and Completed;
  - one with old phase names;
  - a parity case between the two readers.
  The call, `record_status` and card-line fixtures are delivery-003's (R7).
- **Acceptance criteria:**
  - [ ] Both readers give the same member for every fixture, and an old-name fixture maps as F002 § 2's
    table says. The parity suites pass.

### task-049: KB architecture and per-skill state machines [DOCUMENT]

- **Depends on:** task-032, task-034 to task-044. It describes the converted skills.
- **Source:** AC-37, AC-38.
- **Scope:**
  - `pipeline-contracts.md` § Per-Skill State Machines is rewritten: steps, the record, `ASK` / `WAIT` /
    `PASS` / `CALL`, and resume from the record. Its stale claim "one invocation advances one state" goes.
  - `architecture.md`: the state machines.
  - The phase names as data in both documents.
  - No work id.
- **Acceptance criteria:**
  - [ ] Neither document claims "one invocation advances one state", and neither names `PAUSE-FOR-USER`
    as current.
  - [ ] Each document's phase values are the five names. The lints pass, and the text is accurate against
    `skill-steps.md`.

### task-050: `test-skill-steps.sh` group E and the shared exempt list [TEST]

- **Depends on:** task-032, task-033, task-034 to task-044.
- **Source:** AC-37 (resume clause).
- **Scope:**
  - Creates `tests/canonical/test-skill-steps.sh` group E: SS-02 without its chaining-file clause, SS-03,
    SS-08, SS-11, SS-12 and SS-14, with `# COVERS:` lines and a group filter.
  - Creates `tests/canonical/skill-steps-exempt.tsv` (`entry`, `checks`, `owner`), whose rows are the
    exempt per-skill files (SS-14) and finishers (SS-12) of F002 § 1 and § 2.
  - The list fails on an entry that no longer exists, and under `AID_RELEASE_CHECK=1` while it is not
    empty.
- **Acceptance criteria:**
  - [ ] The suite passes on the tree, and reports each group.
  - [ ] Each mutation fails its group:
    - a `PAUSE-FOR-USER-DECISION` line (SS-03);
    - a `phase: Execute` line in a skill (SS-11);
    - a hand-written `lifecycle: Completed` outside the list (SS-12);
    - an `initiator:` line in a non-exempt skill (SS-14);
    - a `SKILL.md` with a Dispatch table and no citation (SS-02);
    - a flow list in the template (SS-08);
    - an exempt row naming a missing folder;
    - `AID_RELEASE_CHECK=1`.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-051: `test-never-merges.sh` (NM-01 to NM-04) [TEST]

- **Depends on:** task-040, task-042. Their exempt files are final.
- **Source:** AC-11 (never-merges clause).
- **Scope:** creates `tests/canonical/test-never-merges.sh` over `git ls-files`, with F002 § 8's include
  and exclude globs, the `merge-parent.sh` allowance, and the two exemptions, which fail once their skill
  is gone.
- **Acceptance criteria:**
  - [ ] It passes on the tree, and only the `aid-housekeep` and `aid-execute` exemptions fire.
  - [ ] A `git merge` line, a `gh pr merge` line, a `gh pr create` line outside the allowed folder, and a
    "merge to main" line, each added to a scratch copy, fail NM-01 to NM-04 in turn. A
    `git merge-base` line passes.

### task-052: Writer unit cases: hand-off and question modes [TEST]

- **Depends on:** task-046 (same suite).
- **Source:** AC-10, AC-28, AC-38.
- **Scope:** `test-writeback-state.sh` gains cases for:
  - `--handoff` as a call, as a pass with `--phase`, and as a pass without it (phase unchanged, no open
    call);
  - `--handoff-return` with two nested calls, and exit 7 with none;
  - `--ask` id numbering, and `--project` creating `.aid/STATE.yml`;
  - `--answer` for each state, with approval `--covers` / `--commit`.
  It also adds a `test-shared-remove.sh` case: after the last tool is removed, `.aid/STATE.yml` stays.
- **Acceptance criteria:**
  - [ ] Each case passes, and each fails when its code path is broken in a scratch copy.
  - [ ] `test-shared-remove.sh` passes in the scratch copy with the new case.

### task-053: Stage-rail test `test_home_stage_rails.mjs` [TEST]

- **Depends on:** task-033.
- **Source:** AC-41.
- **Scope:** creates `dashboard/server/tests/test_home_stage_rails.mjs` (standard library `node:vm`). It
  takes `PHASE_ORDER` and `renderStageRail` from `home.html` by name.
- **Acceptance criteria:**
  - [ ] `node --test dashboard/server/tests/test_home_stage_rails.mjs` passes, with cases for a work with
    no Definition at `Building` (Building is marked), a work with no `intent.phases` (it uses
    `PHASE_ORDER`), and a `Completed` work (Done is marked).

### task-054: Samples `002-05`, `002-20` and `002-21` (run at this gate) [TEST]

- **Depends on:** task-032, task-034 to task-044. The smoke run needs the finished engine.
- **Source:** AC-11, AC-37.
- **Scope:** creates the three samples with their fixtures:
  - a work branch;
  - a work whose saved step names a missing artifact;
  - an open work.
  Each runs once in a scratch copy, as delivery-001's sample tasks do.
- **Acceptance criteria:**
  - [ ] `002-05` checks that `main` is unchanged and no merge command ran (AC-11).
  - [ ] `002-20` checks one repair question, nothing written before the yes, and a resume at the repaired
    step (AC-37).
  - [ ] `002-21` checks that no new work is created, there is one confirmation, and after yes the record
    shows `lifecycle: Canceled` with `active_skill: none`.
  - [ ] Each has had one smoke run, with its result reported.

### task-055: `test-deferred-tests.sh` and the deferred list [TEST]

- **Depends on:** task-026, task-027, task-028, task-054.
- **Source:** AC-28, AC-37 (NFR-T).
- **Scope:**
  - Creates `tests/canonical/test-deferred-tests.sh`, with DT-01 and DT-02.
  - Creates `tests/conversation/deferred.tsv`, with columns `test`, `covers`, `waiting_for` and `needs`.
    It gets one row per Feature 002 sample other than `002-05`, `002-20` and `002-21`.
  - The `skill:` rows come with SS-09 in delivery-003 (R8).
- **Acceptance criteria:**
  - [ ] DT-01 passes, and there are 18 sample rows, each naming an existing file.
  - [ ] DT-02 fails under `AID_RELEASE_CHECK=1` while rows exist. A row naming a missing file fails DT-01.

### task-056: The new suites in the CI lane, and the release check [CONFIGURE]

- **Depends on:** task-050, task-051, task-055.
- **Source:** AC-25, AC-11 (NFR-T).
- **Scope:**
  - `installer-tests.yml` `SUITES` gains `test-skill-steps`, `test-never-merges` and `test-deferred-tests`.
  - `.github/workflows/release.yml`: the `run-all.sh` step sets `AID_RELEASE_CHECK=1`.
  - `release.sh` runs the release checks in its live publish mode only (D2).
- **Suites updated in the same task:** `test-release.sh` and the workflow-reading suites
  (`test-ascii-only.sh`, `test-ps51-compat.sh`, `test-aid-cli-parity.sh`).
- **Acceptance criteria:**
  - [ ] Each suite name appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] `bash release.sh --dry-run` in a clean clone, and `--stage-only`, behave as before, so
    `test-release.sh` and `test-release-install-e2e.sh` pass.
  - [ ] The release step sets `AID_RELEASE_CHECK=1`. No secret is added.

### task-057: KB test landscape for the engine suites, and the regenerated index [DOCUMENT]

- **Depends on:** task-045, task-049, task-053, task-056.
- **Source:** AC-25, AC-37.
- **Scope:**
  - `test-landscape.md` describes the three new static suites, the stage-rail test, the deferred list
    with its release check, and their lane.
  - Then `INDEX.md` is regenerated.
  - This follows the Q134 D2 precedent.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `test-skill-steps.sh`, `test-never-merges.sh`, `test-deferred-tests.sh`,
    `deferred.tsv` and `AID_RELEASE_CHECK`. `INDEX.md` is regenerated, with no work id and the lints
    passing.

---

## 4. Coverage of the stanza

| Stanza item | Task(s) |
|---|---|
| `question-protocol.md`; `skill-steps.md` (work record, advance words, approvals, never merges); `project-state-template.yml` | 022; 023; 021 |
| Writer modes, exits 7/8/9, atomic writes, new names only; the fork with `Deploy` | 025, 029 |
| Gate § 3a `--create` and § 3b record routing; allocation points; `--reset` removed; continuation lines; State Detection; seven finishers | 030; 034, 037, 038, 044; 038; 034, 037, 038, 044; 034-044; 044 |
| `/aid-orchestrate` starts, resumes and cancels; the `rules.md` bullets | 032 |
| SS-02 conversion of every listed file, including the exempt families | 032, 034-044 |
| Advance words; `advance.mjs` and `flow-advance.test.mjs`; flows regenerated | 034-044; 024; each sweep task |
| Phase sites: writes and seeds, the gate, `state-idle.md`, both readers, `home.html` | 037-040, 043; 030; 043; 031; 033 |
| New suites E, NM, DT, stage rail, `deferred.tsv`, `SUITES` | 050, 051, 055, 053, 056 |
| Gate: group E; NM; writer modes; gate fixtures | 050; 051; 046, 052; 047 |
| Gate: readers map names, parity; stage rail; `flow-advance` | 031, 048; 053; 024 |
| Gate: `002-05`, `002-20` and `002-21` at 3 of 3; every other F002 sample deferred; DT-01 | 054; 026-028, 055 |
| G0: KB updated (engine parts), AC-24 row, `INDEX.md` | 045, 049, 057 |

---

## 5. Delivery steps that are not tasks

1. **Start:** `--delivery-id 002 --lifecycle Executing`. There is no `Phase` write; that was
   delivery-001's only.
2. **Tasks** in derived-wave and number order, each with its two state-only commits.
3. **Verification:** `--lifecycle Gated`, one graded review, and `--gate-field Grade`.
4. **The resync** (`delivery-002: resync`). It installs the new writer, which refuses the old names; this
   work writes none.
5. **The gate,** in a new session:
   - the stanza's criteria;
   - `python3 tests/conversation/run.py --feature 002 --sample <id>` for `002-05`, `002-20` and `002-21`,
     at 3 of 3;
   - G0, including the lane and the baselines re-recorded in the gate session (cost: the two new
     templates);
   - the tracking proof for task-020 to task-057.

---

## 6. Execution graph

The table uses `SWEEP` for task-034 to task-044.

| Task | Depends On |
|------|-----------|
| task-020 | -- |
| task-021, task-022, task-023, task-024 | task-020 |
| task-025 | task-021 |
| task-026, task-027 | task-022 |
| task-028 | task-022, task-023 |
| task-029 | task-021, task-025 |
| task-030 | task-023, task-025 |
| task-031 | task-021, task-025 |
| task-032 | task-022, task-029, task-030 |
| task-033 | task-031 |
| task-034 to task-044 (SWEEP) | task-023, task-025, task-030 |
| task-045 | task-023, task-029, task-030 |
| task-046 | task-029, task-031 |
| task-047 | task-029, task-030 |
| task-048 | task-031 |
| task-049 | task-032, SWEEP |
| task-050 | task-032, task-033, SWEEP |
| task-051 | task-040, task-042 |
| task-052 | task-046 |
| task-053 | task-033 |
| task-054 | task-032, SWEEP |
| task-055 | task-026, task-027, task-028, task-054 |
| task-056 | task-050, task-051, task-055 |
| task-057 | task-045, task-049, task-053, task-056 |

`derive-waves.sh` produces the following, run in a scratch copy over the same edges written one task per
row:

```text
wave 1: task-020
wave 2: task-021, task-022, task-023, task-024
wave 3: task-025, task-026, task-027, task-028
wave 4: task-029, task-030, task-031
wave 5: task-032 ... task-048 (task-032 to task-048)
wave 6: task-049, task-050, task-051, task-052, task-053, task-054
wave 7: task-055
wave 8: task-056
wave 9: task-057
```

| Can Be Done In Parallel |
|------------------------|
| task-021, task-022, task-023, task-024 |
| task-025, task-026, task-027, task-028 |
| task-029, task-030, task-031 |
| task-032 to task-048 |
| task-049, task-050, task-051, task-052, task-053, task-054 |

- **Step 5:** the real table goes in PLAN.md under `### delivery-002 Execution Graph`, one task per row.
  That is the heading form `derive-waves.sh` reads.
- **Build order:** when building one at a time, build task-022 before task-023, and task-029 before
  task-032.

---

## 7. Settled by rule (no decision needed)

| # | Point | Rule applied |
|---|---|---|
| R1 | Derived waves differ from the stanza's 5. Unit cases and samples with no stanza-4 input derive earlier (task-026 to task-028, task-046 to task-048). | Q134 D1, plus aid-detail's "dependencies are what each task needs". Building one at a time (Q127) still builds them in number order. |
| R2 | The site is regenerated in each task that changes skill text, not once at the end of the wave. | Q134 precedent, and the same-task rule: the site tests read real skill bodies. |
| R3 | The writer and gate IMPLEMENT tasks keep existing assertions green. Their new unit cases are TEST tasks. | PLAN: "A delivery's last wave adds ... its unit cases"; one type per task. |
| R4 | `advance.mjs` adds the new words and keeps parsing the old ones. | Stanza wave 2: "Both groups only add". |
| R5 | The KB documents what this delivery lands. The interviewer, question records, SY-6 and the chaining file are delivery-003's. | G0: "The KB documents the delivery's spec lists are updated". |
| R6 | `test-landscape.md` and `INDEX.md` come last; baselines are re-recorded in the gate session. | Q134 D2 and D11. |
| R7 | The call fixture, `record_status` and card lines are delivery-003's. | Stanza out-of-scope: "the dashboard's new work fields". |
| R8 | The `skill:` rows of `deferred.tsv` come with SS-09 in delivery-003. | SS-09 is in group S (delivery-003). |
| R9 | `/aid-orchestrate`'s "start, resume or cancel" wording already landed in delivery-001; task-032 only verifies it. | F001 § 3 already carries the cancel wording. |
| R10 | The SS-02 conversion includes the families a later delivery deletes. | Stanza: "No exempt list covers SS-02". |
| R11 | Delivery-001's task-004 now keeps unknown sample frontmatter keys, so Feature 002's `skills:` is accepted. The edit was made before task-004 ran. | Same-delivery correctness; no scope change. |

---

## 8. Decisions for the maintainer

| # | Decision | Recommendation | Alternative |
|---|---|---|---|
| D1 | The gate says "Every other Feature 002 sample has a `deferred.tsv` row, and DT-01 passes". DT-01 needs each sample row to name an existing file. But delivery-003's wave 4 says it writes "the delivery's sample files" (`002-01` to `002-04` and `002-14` to `002-19`). | Write all 21 Feature 002 samples in delivery-002 (task-026 to task-028 and task-054). The ten that delivery-003 runs wait with `waiting_for: Feature 002 (sweep)`. Delivery-003 then only adds `protocol-checks.md`, runs them and drops their rows. The gate holds as written. | Write only the 11 that Feature 002 marks as written now. Record that the delivery-002 gate covers only those, and leave the ten to delivery-003 with no row. That needs a recorded reading of the gate criterion. |
| D2 | DT-02's release check "in `release.sh`'s checks before it stages". `--dry-run` "keeps normal preconditions", and suites run `release.sh --dry-run` in clean clones (`test-release.sh` RL06 and others), and `--stage-only` through `tests/lib/bundle.sh`. A check there would fail them while `deferred.tsv` has rows, which means until delivery-014. | Run the release checks (DT-02, and the two exempt lists' `AID_RELEASE_CHECK=1` checks) only in `release.sh`'s live publish mode, plus the `run-all.sh` step of `release.yml`. | Also run them in `--dry-run`, and give the suites a bypass variable. That widens the test surface for no release gain. |
