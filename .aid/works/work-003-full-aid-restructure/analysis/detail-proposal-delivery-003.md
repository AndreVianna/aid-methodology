# Detail proposal -- delivery-003: Questions one topic at a time, no banners (Feature 002, sweep)

This is `aid-detail` FIRST-RUN Step 1 for **delivery-003**. It proposes the delivery's task breakdown
for the maintainer's approval (Q133). No task folder is created until it is approved. Numbering continues
from delivery-002's task-057.

**Inputs read:**
- the delivery-003 stanza of `PLAN.md`, with its wave 4 as amended under Q135 D1;
- `REQUIREMENTS.md` § 11 Feature 002 (§ 1, § 3, § 4 Review focus, § 6, § 7 and § 8);
- `known-issues.md` KI-003;
- the delivery-002 task files.

**Measured at base `a3b28db4`:**
- `AskUserQuestion` appears in 13 files under `canonical/`.
- `state-machine-chaining.md` is cited by 19 `canonical/` files (itself excluded), plus
  `test-pipeline-status-walkthrough.sh` and the two baselines.
- `## Cross-phase Q&A` appears in 9 skill files.
- `interviewer` appears in 18 files across `canonical/`, `docs/`, `examples/` and `site/src/content/`.
- There are 6 `reviewer-brief.md` files.

Anchors read as in the earlier proposals.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-058 | Delivery-003 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-059 | `agent-boilerplate.md` § Talking with the user | IMPLEMENT | 2 | 2 | 058 |
| task-060 | Sweep: the design family (`design-lifecycle.md`, `aid-design`, `aid-brainstorm`, 21 `aid-design-*`) | IMPLEMENT | 3 | 2 | 058 |
| task-061 | Sweep: the KB-writing `aid-create-*` / `aid-update-*` family | IMPLEMENT | 3 | 2 | 058 |
| task-062 | Sweep: the shortcut engine | IMPLEMENT | 3 | 2 | 058 |
| task-063 | Sweep: `aid-describe`, with its question records and envelope | IMPLEMENT | 3 | 2 | 058 |
| task-064 | Sweep: `aid-define` and `aid-specify` | IMPLEMENT | 3 | 2 | 058 |
| task-065 | Sweep: `aid-plan`, `aid-detail` and `aid-execute` | IMPLEMENT | 3 | 2 | 058 |
| task-066 | Sweep: `aid-discover` | IMPLEMENT | 3 | 2 | 058 |
| task-067 | Sweep: `aid-update-kb`, `aid-ask`, `aid-summarize` and `aid-housekeep` | IMPLEMENT | 3 | 2 | 058 |
| task-068 | Sweep: `aid-deploy`, `aid-monitor`, the ticket and connector skills, and `aid-config` | IMPLEMENT | 3 | 2 | 058 |
| task-069 | Sweep: the seven starters and `/aid-orchestrate` | IMPLEMENT | 3 | 2 | 058 |
| task-070 | Dashboard readers: step, call, questions and record status | IMPLEMENT | 3 | 2 | 058 |
| task-071 | Conversation runner gives the judge `protocol-checks.md` | IMPLEMENT | 3 | 2 | 058 |
| task-072 | Agents: interviewer retired, questions recorded, "What to report" | IMPLEMENT | 3 | 3 | 059 |
| task-073 | Dashboard page: the work card lines and the record warning | IMPLEMENT | 3 | 3 | 070 |
| task-074 | `state-machine-chaining.md` deleted | IMPLEMENT | 3 | 3 | 062-068 |
| task-075 | Judge checklist `protocol-checks.md` | TEST | 4 | 3 | 071 |
| task-076 | User documents and site pages without the interviewer | DOCUMENT | 3 | 4 | 063, 064, 072 |
| task-077 | KB: interviewer retired, questions in one place, chaining rule gone | DOCUMENT | 3 | 4 | 063, 065, 067, 072, 074 |
| task-078 | `test-skill-steps.sh` group S, the `skill:` rows and the AD13 ceilings | TEST | 4 | 4 | 060-069, 072, 074 |
| task-079 | Dashboard cases: card lines, call and record status, parity | TEST | 4 | 4 | 073 |
| task-080 | The ten Feature 002 asking samples: smoke run, then their deferred rows go | TEST | 4 | 5 | 075, 078 |
| task-081 | KB test landscape for group S and the judge checks, and the regenerated index | DOCUMENT | 4 | 6 | 077, 078, 079, 080 |

That is 24 tasks. The resync follows task-081 (§ 4).

---

## 2. Rules carried forward

Every task file carries delivery-002's blocks unchanged:

- the Execution protocol note;
- the same-task rule (Q106) and its coverage-ledger rows;
- the findings bullet, which names `research/delivery-003-sites.md`;
- site regeneration wherever skill text changes;
- the standard test step, including step 5's `node --test`.

The sweep tasks (task-060 to task-069) cover the same disjoint skill groups as delivery-002's
task-034 to task-044. They differ in two ways:
- the connector skills, `aid-config` and the never-asks skills join task-068;
- `/aid-orchestrate` joins task-069.

Each sweep task applies, to its own files only, the conversions (a) to (f) below. Then it regenerates
the site, and updates the suites task-058's search assigns, `test-describe-full-only.sh` included.

- **(a) Banners.** Remove every SS-01 form: `[State: X] -- ...` entry lines, "you are here" maps,
  "-> Advancing to [State: X]", "[State N] Dispatching ...", "[Resolved: ...]" and "Re-run `/aid-...` to
  continue". `[State: X]` stays only as an `**Advance:**` target (F002 § 4, What the user sees).
- **(b) Chaining citations.** Every citation of `state-machine-chaining.md` becomes `skill-steps.md`.
- **(c) Protocol line.** Every asking `SKILL.md` carries "Talking with the user: follow
  `.aid/runtime/templates/question-protocol.md`." The generated doorways get it through
  `shortcut-engine.md`. Every `AskUserQuestion` leaves `allowed-tools` and the body.
- **(d) Question records.** Every question-record site writes through `--ask` / `--answer` to the work's
  `qa`. None names `## Cross-phase Q&A`, and none writes a delivery-level `qa` (KI-003, SS-06).
- **(e) Interviewer.** Every interviewer mention in the group is re-pointed: the main conversation asks,
  through the protocol.
- **(f) Review focus.** Every `reviewer-brief.md` in the group gains `### What to report`, with F002 § 4's
  rule (AC-46).

---

## 3. Tasks

`Source` reads `feature-002-step-by-step-decisions -> delivery-003 -> AC-...`.

### task-058: Delivery-003 site search and reconciled edit list [RESEARCH]

- **Depends on:** --.
- **Source:** AC-8, AC-28, AC-37, AC-40, AC-46.
- **Scope:** creates `research/delivery-003-sites.md`, with the same shape and owner classes as task-020.
  It re-runs these searches:
  - **Q1** the SS-01 banner forms;
  - **Q2** the interviewer sites: `interviewer` in any case, over SS-05's scope plus `tests/` and the KB;
  - **Q3** the question-record sites: `## Cross-phase Q&A` and delivery-level `qa` writers;
  - **Q4** `AskUserQuestion`. This includes the `canonical/aid/scripts/connectors/write-connector.sh`
    mention; the task decides whether it is a picker use or text;
  - **Q5** the `reviewer-brief.md` files;
  - **Q6** chaining-file citations;
  - **Q7** the asking skills against F002 § 8's coverage table;
  - **Q8** the Q106 suite map;
  - **Q9** today's AD13 counts.
- **Acceptance criteria:**
  - [ ] Each search shows its command, and re-running it at the named base reproduces it.
  - [ ] Every hit has exactly one owner among task-059 to task-081 (or resync or history), and no owner
    cell is empty.
  - [ ] Q7 lists each asking skill with its sample id or the `skill:` row task-078 adds. RESEARCH
    defaults are overridden as in task-001.

### task-059: `agent-boilerplate.md` § Talking with the user [IMPLEMENT]

- **Depends on:** task-058.
- **Source:** AC-40.
- **Scope:** `canonical/aid/templates/agent-boilerplate.md` gains `## Talking with the user` (F002 § 3):
  - a sub-agent never asks the user;
  - it records its open questions with `--ask`, left `Pending`, and lists them in its report;
  - the main conversation asks them.
  The file carries no frontmatter block (TO-01).
- **Acceptance criteria:**
  - [ ] The heading exists, and its text names `--ask`, the report, and the main conversation.
  - [ ] `grep -c '^---$'` on the file is unchanged (no frontmatter added). Every `AGENT.md` still includes
    `{{include:agent-boilerplate}}`.

### task-060 to task-069: the sweep [IMPLEMENT]

Each depends on task-058 and applies (a) to (f) of § 2 to its group. Its acceptance criteria are:

- [ ] Over its files, the SS-01 forms, `state-machine-chaining`, `AskUserQuestion`,
  `## Cross-phase Q&A` and `interviewer` each find nothing. The exception is a chaining citation that
  task-074 owns, if task-058 assigned it there.
- [ ] Every asking `SKILL.md` in the group carries the protocol line (SS-04 by hand), plus the group
  criterion below.
- [ ] The group's suites pass where the test step puts them, and the site `npm test` passes after
  regeneration.

| Task | Group | Group-specific sites | Group criterion | Source |
|---|---|---|---|---|
| task-060 | `design-lifecycle.md`, `aid-design`, `aid-brainstorm`, the 21 `aid-design-*` | banners and the protocol line only | (a) and (c) hold in all 24 files | AC-8, AC-37 |
| task-061 | the 14 KB-writing `aid-create-*` / `aid-update-*` | banners and the protocol line only | (a) and (c) hold in all 14 | AC-8, AC-37 |
| task-062 | `canonical/aid/templates/shortcut-engine.md` | banners; the chaining citation; the protocol line for every generated doorway | `test-shortcut-engine-contract.sh` passes in the scratch copy | AC-8, AC-37 |
| task-063 | `aid-describe` | the interviewer in its Dispatch and `advisor-stance.md`; the envelope section becomes a pointer to the protocol, and its "Not applicable" option goes; `## Cross-phase Q&A` in `SKILL.md`, `elicitation-engine.md`, `move-playbook.md`, `advisor-stance.md`, `state-describe-seed.md` and `state-q-and-a.md` | `test-describe-full-only.sh` passes live | AC-8, AC-28, AC-37, AC-40 |
| task-064 | `aid-define`, `aid-specify` | the interviewer in `aid-define` `state-feature-decomposition.md`, `state-cross-reference.md` and `reviewer-brief.md`, and in `aid-specify`'s "not an interviewer" line; `## Cross-phase Q&A`; `### What to report` in both briefs | both briefs have the heading | AC-28, AC-37, AC-40, AC-46 |
| task-065 | `aid-plan`, `aid-detail`, `aid-execute` | delivery-level `qa` writers (`aid-plan` § Feedback Loops, `aid-execute` `state-delivery-gate.md` § Non-CODE issues); `aid-detail` `task-decomposition.md` § Feedback Loops; three briefs | SS-06 by hand finds nothing; three briefs have the heading | AC-28, AC-37, AC-46 |
| task-066 | `aid-discover` | banners across its references; the chaining citations in `SKILL.md`, `state-elicit.md` and `state-generate.md`; its brief | the brief has the heading | AC-37, AC-46 |
| task-067 | `aid-update-kb`, `aid-ask`, `aid-summarize`, `aid-housekeep` | `aid-ask` § Target-file resolution writes the work `qa`; `AskUserQuestion` in `aid-summarize` (`state-approval.md`, `state-fix.md`, `state-manual-checklist.md`) and `aid-housekeep` `state-cleanup.md` | `AskUserQuestion` finds nothing in the four | AC-8, AC-28, AC-37 |
| task-068 | `aid-deploy`, `aid-monitor`, `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket`, `connectors/ticket-resolution.md`, `aid-config`, `aid-set-connector` (with `question-sets.md`), `aid-unset-connector`, `aid-chat`, `canonical/aid/scripts/connectors/write-connector.sh` | `AskUserQuestion` out of every `allowed-tools`; the setup skills record in `.aid/STATE.yml` through `--ask --project`; `aid-chat` and `aid-unset-connector` get no protocol line (never-asks) | `AskUserQuestion` finds nothing in the group | AC-8, AC-28, AC-37 |
| task-069 | `aid-research`, `aid-review`, `aid-test`, `aid-prototype`, `aid-report`, `aid-create-document`, `aid-update-document`, `aid-orchestrate` | banners and the protocol line; `aid-orchestrate` keeps its line caps | (a) and (c) hold in all 8 | AC-8, AC-28, AC-37 |

### task-070: Dashboard readers: step, call, questions and record status [IMPLEMENT]

- **Depends on:** task-058.
- **Source:** AC-41.
- **Scope:** F002 § 6, in both readers:
  - **Python:** `models.py` gains `step`, `step_detail` and `open_call`. `parsers.py` reads them, and `qa`
    on every layout (open means `Pending` + `Skipped`).
  - **Merging:** `reader.py` merges work-level `qa` on the full layout too, and still merges delivery
    `qa`.
  - **Record status:** both readers compute `record_status` (`ok`, `missing` or `inconsistent`) with
    `--check`'s field rules.
  - **Serialization:** `server.py` `_ser_work` adds `step`, `step_detail`, `open_call` and
    `record_status`. `reader.mjs` does the same in every place it builds a work, and `server.mjs` passes
    the work through.
  - `chat-node/` is untouched.
- **Acceptance criteria:**
  - [ ] A work file with an open call serializes `open_call` (to, why, return phase) identically from
    both readers.
  - [ ] A work with no `intent.reading` serializes `record_status: missing`. A finished work with a saved
    skill serializes `inconsistent`.
  - [ ] The parity suites pass. `git diff "$BASE" -- chat-node/` is empty.

### task-071: Conversation runner gives the judge `protocol-checks.md` [IMPLEMENT]

- **Depends on:** task-058.
- **Source:** AC-8, AC-28.
- **Scope:** `tests/conversation/run.py` adds `tests/conversation/protocol-checks.md` to the judge's
  input for every sample whose `covers` holds AC-8 or AC-28 (F002 § 8). A missing checklist is an
  invocation error, exit 2, for such a sample.
- **Acceptance criteria:**
  - [ ] With a stub `claude`, an AC-28 sample's judge input contains the checklist text, and an AC-11
    sample's does not.
  - [ ] An AC-28 sample with no checklist file exits 2. `test-conversation-runner.sh` gains these cases
    and passes in the scratch copy.

### task-072: Agents: interviewer retired, questions recorded, "What to report" [IMPLEMENT]

- **Depends on:** task-059.
- **Source:** AC-40, AC-46.
- **Scope:**
  - Deletes `canonical/agents/aid-interviewer/`.
  - `aid-architect` drops "that's the Interviewer". The "When to Escalate" lines of `aid-architect`,
    `aid-researcher` and `aid-reviewer` record through `--ask`.
  - `aid-reviewer` `AGENT.md` and `canonical/aid/templates/reviewer-dispatch.md` gain
    `### What to report`.
  - The interviewer row of `agent-dispatch-tiering.md` § Per-agent defaults goes.
  - The agent-count phrases are re-synced (Q134 D5), and `sync:docs` runs.
- **Acceptance criteria:**
  - [ ] `test -e canonical/agents/aid-interviewer` fails, and `git grep -il interviewer --
    canonical/agents canonical/aid/templates` finds nothing (AC-40).
  - [ ] No `AGENT.md` contains `AskUserQuestion` or "ask the user" (SS-10 by hand). The reviewer agent
    and `reviewer-dispatch.md` have `### What to report` (AC-46).
  - [ ] `test-doc-counts.sh` passes live with the new agent count.

### task-073: Dashboard page: the work card lines and the record warning [IMPLEMENT]

- **Depends on:** task-070.
- **Source:** AC-41.
- **Scope:** `dashboard/home.html` work card (F002 § 6):
  - the phase;
  - one plain line from `step_detail`;
  - "Waiting for your answer (N)" when open questions exist;
  - "Away in /aid-... -- back to <phase> after" while a call is open;
  - the record warning text for any `record_status` other than `ok`.
  No step names and no maps.
- **Acceptance criteria:**
  - [ ] The page holds the three card strings and the warning text verbatim from F002 § 6.
  - [ ] `test_index_html.py` asserts them and passes. `test_home_stage_rails.mjs` still passes.

### task-074: `state-machine-chaining.md` deleted [IMPLEMENT]

- **Depends on:** task-062 to task-068, which remove their citations.
- **Source:** AC-37.
- **Scope:**
  - Deletes `canonical/aid/templates/state-machine-chaining.md`, and any citation task-058 assigns here.
  - `test-pipeline-status-walkthrough.sh` group B2 moves to `skill-steps.md`'s `ASK` handler (F002 § 7).
  - Removed assertions get their ledger rows.
- **Acceptance criteria:**
  - [ ] The file is absent, and `git grep -l state-machine-chaining -- canonical tests/canonical site/scripts`
    finds nothing. The baselines are re-recorded at the gate.
  - [ ] `test-pipeline-status-walkthrough.sh` passes live with B2 asserting `skill-steps.md`.

### task-075: Judge checklist `protocol-checks.md` [TEST]

- **Depends on:** task-071.
- **Source:** AC-8, AC-28.
- **Scope:** creates `tests/conversation/protocol-checks.md`: one check per FR-17 rule, plus the
  importance label (F002 § 8). It states the intake-question exception, so the judge does not fail
  `002-14`, `002-16` and `002-18` on it (F002 § 3).
- **Acceptance criteria:**
  - [ ] The checklist has one numbered check per FR-17 rule (rules 1-10) plus the importance label, and
    names the intake exception.
  - [ ] It contains no skill name. Each check names the transcript evidence a judge reads.

### task-076: User documents and site pages without the interviewer [DOCUMENT]

- **Depends on:** task-063, task-064, task-072.
- **Source:** AC-40.
- **Scope:** small edits; AC-45's pass is delivery-014's.
  - `docs/aid-methodology.md` and `docs/diagram-content-reference.md`;
  - `examples/brownfield-lite-path/README.md` (its CONDENSED-INTAKE walk-through) and
    `examples/greenfield/README.md`;
  - the hand-written site pages `reference/agents.md` and `concepts/methodology.md` (synced pages through
    `sync:docs`). `skills/aid-describe.md` is regenerated by task-063.
  - `canonical/aid/scripts/summarize/validate-diagram-content.mjs` stays (F002 § 7).
- **Acceptance criteria:**
  - [ ] `git grep -il interviewer -- docs examples site/src/content` finds nothing (SS-05's scope).
  - [ ] `sync:docs` leaves no diff, the site `npm test` passes, and `test-doc-counts.sh` passes.

### task-077: KB: interviewer retired, questions in one place, chaining rule gone [DOCUMENT]

- **Depends on:** task-063, task-065, task-067, task-072, task-074.
- **Source:** AC-24 (row), AC-28, AC-40.
- **Scope:** edits these documents under `.aid/knowledge/`, with no work id:
  - `decisions.md`: D15's agent count;
  - `domain-glossary.md`: the interviewer goes;
  - `backlog.md` § Next Release: the agent `aid-interviewer` old -> new row;
  - `tech-debt.md`: SY-6 narrowed, because the question-record slice is resolved;
  - `architecture.md`: the agent table and the chaining file;
  - `module-map.md`: the agents row;
  - `pipeline-contracts.md`: the interviewer.
- **Acceptance criteria:**
  - [ ] The backlog row exists with F002 § 7's New text, and `git grep -il interviewer -- .aid/knowledge`
    finds only `release-tracking.md` and `kb.html` (left as is).
  - [ ] SY-6 no longer lists the question-record sites. No work id, and the citation and frontmatter lints
    pass.

### task-078: `test-skill-steps.sh` group S, the `skill:` rows and the AD13 ceilings [TEST]

- **Depends on:** task-060 to task-069, task-072, task-074.
- **Source:** AC-8, AC-28, AC-37, AC-40, AC-46.
- **Scope:**
  - Adds group S to `tests/canonical/test-skill-steps.sh`: SS-01, the SS-02 chaining clause, SS-04 (with
    its never-asks list `aid-chat` and `aid-unset-connector`), SS-05, SS-06, SS-07, SS-09, SS-10 and SS-13.
  - Adds the `skill:` rows of F002 § 8's coverage table to `tests/conversation/deferred.tsv`.
  - Lowers the AD13 ceilings in `test-artifact-discipline.sh` to the new measured counts.
- **Acceptance criteria:**
  - [ ] Groups S and E both pass. Each S check fails its own mutation in a scratch copy: a banner line, a
    chaining citation, an `AskUserQuestion`, the word interviewer, a `## Cross-phase Q&A`, a `.aid/works`
    line in `chat-node/`, an asking skill with neither a sample nor a row, an agent that asks the user,
    and a brief without the heading.
  - [ ] DT-01 passes with the `skill:` rows. `test-artifact-discipline.sh` passes in the scratch copy,
    with each AD13 ceiling equal to its measured count.

### task-079: Dashboard cases: card lines, call and record status, parity [TEST]

- **Depends on:** task-073.
- **Source:** AC-41.
- **Scope:**
  - Fixtures in `dashboard/reader/tests/` and the Node suite: a work at each phase, Building during a
    call, a missing record, and an inconsistent record.
  - A parity case for each.
  - `test_index_html.py` card-line cases.
- **Acceptance criteria:**
  - [ ] Both readers give equal `step`, `step_detail`, `open_call`, `qa` and `record_status` for each
    fixture, and the card shows the expected line for each. The parity suites pass.

### task-080: The ten Feature 002 asking samples: smoke run, then their deferred rows go [TEST]

- **Depends on:** task-075, task-078. task-078 edits the same `deferred.tsv`.
- **Source:** AC-8, AC-28.
- **Scope:**
  - Runs `002-01` to `002-04` and `002-14` to `002-19` (written in delivery-002, Q135 D1) once each in a
    scratch copy, with the judge applying `protocol-checks.md`.
  - Fixes any defect in a sample, and reports any defect in the product.
  - Removes their ten `deferred.tsv` rows.
  - The 3-of-3 runs are the gate's.
- **Acceptance criteria:**
  - [ ] Each of the ten has one smoke run reported, with the judge's checklist applied.
  - [ ] `deferred.tsv` holds no row for the ten, and DT-01 passes.

### task-081: KB test landscape for group S and the judge checks, and the regenerated index [DOCUMENT]

- **Depends on:** task-077, task-078, task-079, task-080.
- **Source:** AC-25, AC-28.
- **Scope:**
  - `test-landscape.md` gains group S, the judge's `protocol-checks.md` and the dashboard cases.
  - Then `INDEX.md` is regenerated.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names group S's checks and `protocol-checks.md`.
  - [ ] `INDEX.md` is regenerated; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item | Task(s) |
|---|---|
| Banners removed; chaining file deleted with every citation | 060-069; 074 |
| Protocol line; `AskUserQuestion` gone; `aid-describe` envelope | 060-069, 068; 063 |
| Question-record sites through `--ask` / `--answer`; AD13 ceilings | 063, 064, 065, 067, 068; 078 |
| Interviewer deleted; boilerplate section; escalation lines; every site re-pointed | 072; 059; 072; 063, 064, 076, 077 |
| `### What to report` in the agent, dispatch template and every brief | 072, 064, 065, 066 |
| Dashboard work fields and card lines; `chat-node/` untouched | 070, 073 |
| Group S; samples at 3 of 3 with `protocol-checks.md` | 078; 071, 075, 080 |
| Dashboard fixtures and parity; SS-07 | 079; 078 |
| G0: KB, AC-24 row, `INDEX.md` | 077, 081 |

**Steps that are not tasks**, as in delivery-002:
1. `--delivery-id 003 --lifecycle Executing`.
2. The tasks, each with its two state-only commits.
3. Verification.
4. The resync (`delivery-003: resync`). `aid update` removes the installed interviewer agent through the
   manifest.
5. The gate, in a new session:
   - the stanza's criteria;
   - the ten samples at 3 of 3, through `run.py --feature 002`;
   - G0, including the baselines (cost: the deleted agent and template);
   - the tracking proof for task-058 to task-081.

---

## 5. Execution graph

| Task | Depends On |
|------|-----------|
| task-058 | -- |
| task-059 to task-071 (each) | task-058 |
| task-072 | task-059 |
| task-073 | task-070 |
| task-074 | task-062, task-063, task-064, task-065, task-066, task-067, task-068 |
| task-075 | task-071 |
| task-076 | task-063, task-064, task-072 |
| task-077 | task-063, task-065, task-067, task-072, task-074 |
| task-078 | task-060 to task-069, task-072, task-074 |
| task-079 | task-073 |
| task-080 | task-075, task-078 |
| task-081 | task-077, task-078, task-079, task-080 |

`derive-waves.sh` produces the following, run in a scratch copy over the same edges written one task per
row:

```text
wave 1: task-058
wave 2: task-059 to task-071
wave 3: task-072, task-073, task-074, task-075
wave 4: task-076, task-077, task-078, task-079
wave 5: task-080
wave 6: task-081
```

Step 5 writes the table under `### delivery-003 Execution Graph`, one task per row.

---

## 6. Settled by rule (no decision needed)

| # | Point | Rule applied |
|---|---|---|
| R1 | The skill sweep derives into wave 2, next to the boilerplate. Only the agent edits need the boilerplate. | Stanza wave 2: "The agent edits depend on it"; Q135 R1 (dependencies are real needs). |
| R2 | The sweep is split by the same disjoint skill groups as delivery-002, each group doing all six conversions. Concerns are not split, because that would have several tasks editing one file. | Q134 / Q135 precedent; one session and one review per task. |
| R3 | The chaining file is deleted in its own task, after every group has dropped its citation. | Nothing may cite a missing file (SR-01); same-task rule. |
| R4 | `run.py` feeding the checklist to the judge is an IMPLEMENT task in stanza wave 3. The checklist itself is TEST content in wave 4. | One type per task; PLAN: the last wave adds tests and samples only. |
| R5 | The ten samples get one smoke run in task-080 before their rows go. The gate runs 3 of 3. | Q134 D8 and Q135 D1. |
| R6 | The interviewer is removed from `docs/`, `examples/` and the site now, with small edits. | SS-05's scope includes them; AC-45's full pass stays delivery-014's. |
| R7 | The agent-count phrases are re-synced by the task that deletes the agent. | Q134 D5. |
| R8 | The `skill:` rows of `deferred.tsv` arrive with SS-09 in task-078. | Q135 R8. |
| R9 | `test-landscape.md` and `INDEX.md` come last, and the baselines are re-recorded in the gate session. | Q134 D2 and D11. |

---

## 7. Decisions for the maintainer

None. Every open point above follows from the specification, the plan or an earlier answer (Q134,
Q135).

Under Q136, the proposal does not wait for approval:
- R1-R9 are settled by recommendation (Q136);
- the task files are written directly;
- the light review after this delivery, and the full review at the end, are the check.

If the maintainer wants a different split of the sweep (R2), that is the one choice that would change
the task count.
