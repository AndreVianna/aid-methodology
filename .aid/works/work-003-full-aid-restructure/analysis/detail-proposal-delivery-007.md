# Detail proposal -- delivery-007: One requirements document, business and technical (Feature 005)

> **Superseded by the task files.** After the light-review fixes (general rules G7-G10), the scopes and
> criteria in this proposal's task blocks no longer match the task files. The task files under
> `deliveries/delivery-007/tasks/` are the source of truth. Step 5 builds PLAN.md's Execution Graph from their
> `**Depends on:**` lines, never from this proposal.

This is `aid-detail` FIRST-RUN for **delivery-007**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-007/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-006's task-160.
- **General rules.** The rules G1-G6 from the light reviews apply from the start.

**Inputs read:**
- the delivery-007 stanza of `PLAN.md`, Common Gate G0, "Testing before the resync" and "Toolchain and
  Branching";
- `REQUIREMENTS.md` § 11 Feature 005 (all eight subsections);
- the delivery-001 to delivery-006 task files, for what they leave to this delivery (the Feature 002,
  003 and 004 samples waiting for Feature 005).

**Measured at base `1e513e05`** (task-161 re-measures on the tree deliveries 001-006 leave):
- `aid-specify` has a 271-line `SKILL.md` and 9 references; `aid-define` has a 248-line `SKILL.md` and 6
  references.
- 18 files under `canonical/` and `dashboard/` outside `aid-define` name `aid-define` (some leave with
  `aid-describe` in delivery-004, and `aid-discover` moves to `aid-kb-build` in delivery-005); 41 files
  under `canonical/`, `dashboard/`, `tests/`, `site/scripts/` and `.github/` in all.
- `specs/technical-specification-template.md` has one user, `aid-specify/references/state-continue.md`.
- Only `work-state-template.yml` has a line opening with `interview:`, `features:` or `review_history:`.
- `test-scoped-review-cycles.sh` SC11 today asserts that no `aid-specify` reference names Guard 2.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-161 | Delivery-007 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-162 | Where each of the five tools keeps its reasoning effort | RESEARCH | 1 | 2 | task-161 |
| task-163 | Requirements template in two parts, and the bare scaffold | IMPLEMENT | 2 | 2 | task-161 |
| task-164 | Work-state keys reviews and effort_check, and the writer's --review and Effort Check | IMPLEMENT | 2 | 2 | task-161 |
| task-165 | slice-requirements.sh reads a document that does not split | IMPLEMENT | 2 | 2 | task-161 |
| task-166 | aid-specify references: START, the effort check, REQUIREMENTS and FEATURES | IMPLEMENT | 3 | 3 | task-162, task-163, task-164 |
| task-167 | aid-specify references: DESIGN, CHECK and the reviewer brief | IMPLEMENT | 3 | 3 | task-163, task-164 |
| task-168 | skill-steps.md: the business-part approval row and the KB call on confirmation | IMPLEMENT | 3 | 2 | task-161 |
| task-169 | aid-specify references: APPROVE, FINISH and REVISE | IMPLEMENT | 3 | 3 | task-164, task-168 |
| task-170 | aid-specify SKILL.md rewritten, and its old references deleted | IMPLEMENT | 3 | 4 | task-165, task-166, task-167, task-169 |
| task-171 | Review contracts: the Guard 2 site, the ledger path and aid-architect's output line | IMPLEMENT | 3 | 4 | task-167 |
| task-172 | The gate's legacy rows for old Define and Specify works | IMPLEMENT | 3 | 5 | task-170 |
| task-173 | Re-point every kept file that names aid-define | IMPLEMENT | 4 | 5 | task-170, task-171 |
| task-174 | aid-define retired | IMPLEMENT | 4 | 6 | task-172, task-173 |
| task-175 | Writer unit cases: --review on the work file and Effort Check | TEST | 5 | 3 | task-164 |
| task-176 | Unit cases: test-slice-requirements.sh for the unsplit shape | TEST | 5 | 3 | task-165 |
| task-177 | test-specify.sh (SP-01 to SP-08) and the SP-08 exempt row | TEST | 5 | 7 | task-163, task-164, task-168, task-170, task-171, task-174 |
| task-178 | Samples 005-01 to 005-05 (run at this gate) | TEST | 5 | 7 | task-170, task-174 |
| task-179 | Samples 005-06 to 005-10 (run at this gate), and the deferred rows that now run | TEST | 5 | 8 | task-169, task-172, task-178 |
| task-180 | Samples 005-11, 005-12 and 005-13 (deferred) and their deferred rows | TEST | 5 | 9 | task-179 |
| task-181 | test-specify.sh in the CI lane | CONFIGURE | 5 | 8 | task-177 |
| task-182 | KB decisions, schemas, glossary, tech debt and backlog for one Specification skill | DOCUMENT | 4 | 7 | task-164, task-168, task-174 |
| task-183 | KB architecture, contracts and quality documents for one Specification skill | DOCUMENT | 4 | 7 | task-170, task-171, task-174 |
| task-184 | KB test landscape for test-specify.sh, the regenerated index and the view | DOCUMENT | 5 | 10 | task-175, task-176, task-177, task-179, task-180, task-181, task-182, task-183 |

That is 24 tasks. The resync follows task-184. No format-6 step belongs to Feature 005, so the resync
changes no KB document, and task-184 renders `kb.html` itself (S8).

---

## 2. Rules every task carries

Each task file carries the blocks of delivery-006: the Execution protocol; the same-task rule (Q106) and its
ledger rows; the findings bullet (`research/delivery-007-sites.md`); the standard test step, with step 5's
site `npm test` (G5); for every IMPLEMENT task, site regeneration (G1) and the hand check of later static
patterns (G3); for the deletion tasks (170, 174), the G6 suite search; in task-161, the "baseline,
re-recorded at the gate" owner class and the G2 skill owner table.

Every needed order is a dependency edge (G4). Same-file edits in one wave are ordered by an edge:
`work-initiation-gate.md` (172 after 170), `deferred.tsv` (179, then 180), the skill guide (170, then 174).

---

## 3. Tasks

`Source` reads `feature-005-specification -> delivery-007 -> AC-...`.

### task-161: Delivery-007 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-16, AC-44.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-007-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 005 `##### 1. Files and layout` and `##### 7. Migration`):
    - **P1** `aid-define`, over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`,
      `.github/` and `.aid/knowledge/`, checked against the spec's stated re-pointing sites;
    - **P2** by path, the eight `aid-specify` references this delivery deletes (`state-initialize.md`,
      `state-continue.md`, `state-review.md`, `state-spike.md`, `state-blocked.md`, `state-done.md`,
      `handling-outcomes.md`, `known-issues-scope.md`), and `specs/technical-specification-template.md`;
    - **P3** the keys `interview:`, `features:` and `review_history:`: their writers, their readers and every
      line opening with one of them under `canonical/skills/` and `canonical/aid/templates/` (SP-06);
    - **P4** the consumers of `requirements/requirements-template.md` and `requirements.md` (the scaffold),
      and of `## Verifiable Acceptance Criteria`;
    - **P5** the Guard 2 sites: `reviewer-dispatch.md`'s site table, `test-scoped-review-cycles.sh` SC10 and
      SC11, and the ledger-path rows of `reviewer-ledger-schema.md`;
    - **P6** the legacy rows of `work-initiation-gate.md` § 3b that name `Define`, `Specify`, `aid-define` or
      `aid-specify`;
    - **P7** the rows of `tests/conversation/deferred.tsv`, the SG-04 exempt list and
      `tests/canonical/skill-steps-exempt.tsv` that name `aid-define`, `aid-specify` or a sample this delivery
      runs; and every `## State: CAPTURE` or `## State: SPEC` heading (SP-08);
    - **P8** the Q106 suite map for every file on the edit list, including the dashboard tests and the
      site's skill lists.
  - Give each hit exactly one owner:
    - a task of delivery-007 (task-162 to task-184; see the task files under
      `.aid/works/work-003-full-aid-restructure/deliveries/delivery-007/tasks/`);
    - Feature 006 (delivery-008) for `aid-plan`'s and `aid-detail`'s reads of the `features` key;
    - Feature 009 (delivery-012) for the shortcut engine's own `REQUIREMENTS.md` writing (Q65);
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
  - [ ] Each of P1-P8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-162: Where each of the five tools keeps its reasoning effort [RESEARCH]

- **Stanza wave:** 1. **Depends on:** task-161.
- **Source:** AC-12.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/effort-levels.md`. Touch nothing else.
  - For each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI, find in that tool's own
    documentation (REQUIREMENTS.md § 11 Feature 005 `##### 5. Components`, Effort check):
    - where the tool keeps the reasoning effort of the main conversation: a settings file, an environment
      variable, or a documented command;
    - how to read it without changing anything;
    - its level names, and how each compares with "high";
    - whether a new level applies at once or only in a new session;
    - how a user sets it, for the "raise it" answer.
  - A tool whose documentation names no such place is recorded as "cannot be read", with the pages searched.
  - For Claude Code, also record how to set the level below high for sample `005-04`'s fixture.
  - Each row cites its source (URL or documented command) and the date read.
- **Acceptance criteria:**
  - [ ] The file has one row for each of the five tools, and every row is either filled with a cited source or marked "cannot be read" with the pages searched.
  - [ ] The Claude Code row states how to set the level below high for `005-04`'s fixture.
  - [ ] RESEARCH defaults are overridden: the question is a fact per tool, so there are no alternatives to compare; the cited documentation is the source. The test step selects nothing (work folder only).

### task-163: Requirements template in two parts, and the bare scaffold [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-161.
- **Source:** AC-16, AC-44.
- **Scope:**
  - Rewrite `canonical/aid/templates/requirements/requirements-template.md` to the two-part shape of REQUIREMENTS.md § 11 Feature 005
    `##### 2. The document`:
    - the identity block; the business part `## 1.` to `## 10.`, each kept, with "None." when it does not
      apply;
    - `## 11. Technical Specification` for a work that does not split, and `## 11. Features` with the
      per-feature headings for a work that does, each technical part opening with a `**Serves:**` line;
    - the technical headings Approach, What changes, Data and interfaces, Decisions, Risks, Migration and
      Testing, with what each holds; a heading that does not apply is left out;
    - `## Verifiable Acceptance Criteria` kept under that heading, which `aid-plan`, `aid-detail` and
      `shortcut-engine.md` cite;
    - no `## Change Log`, and no mention of `aid-define`.
  - Rewrite `canonical/aid/templates/requirements.md`, kept at its path, as the bare scaffold: the identity
    block and every unfilled section hold `*(pending)*`; sections 1-10, then `## 11. Technical Specification`.
    The `- **Name:**` and `- **Description:**` lines that `test_feature009.py`'s `test_pf1_*` tests pin stay.
  - `canonical/aid/templates/specs/technical-specification-template.md` is deleted with its last user, by
    task-170.
  - Suites to update in this same task: the template assertions of `test-ticket-retirement-structural.sh`,
    `test-connector-consumption-linkage.sh`, and any suite the findings' P4 or P8 assigns here.
    `dashboard/reader/tests/test_feature009.py` must pass unchanged.
- **Acceptance criteria:**
  - [ ] `requirements-template.md` has `## 1.` to `## 10.`, `## 11. Technical Specification`, `## 11. Features`, the seven technical headings, a `**Serves:**` line and `## Verifiable Acceptance Criteria` (SP-05), and names no `aid-define`.
  - [ ] `requirements.md` holds `*(pending)*` in its identity lines and ends with `## 11. Technical Specification`, and `python3 -m pytest dashboard/reader/tests/test_feature009.py` passes unchanged.
  - [ ] The re-pointed suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-164: Work-state keys reviews and effort_check, and the writer's --review and Effort Check [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-161.
- **Source:** AC-12, AC-44.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml` (REQUIREMENTS.md § 11 Feature 005 `##### 4. Work state`): `interview` (with its ten
    `sections`), `features` and `review_history` go, with their comments; `reviews: []` and
    `effort_check: --` come, each with its `[W]` comment, in block style.
  - `canonical/aid/scripts/execute/writeback-state.sh`:
    - `--review --grade G --notes T` without `--kb` appends an entry (`at`, `grade`, `by` = the saved
      `active_skill`, `notes`) to the work's `STATE.yml` `reviews`, resolved like every work write;
    - when the work file has no `reviews` key, the same write adds it, block style, at the top level (Q130);
    - same grade validation (exit 4), lock and atomic rename; `--kb --review` is unchanged;
    - `--pipeline --field "Effort Check"` writes `effort_check`, accepting `--`, `unknown` or a level name of
      lowercase letters; anything else exits 4.
  - Both dashboard readers parse the template with no warning (SS-08). They ignore keys they do not show.
  - The unit cases are task-175.
  - Suites to update in this same task: `test-work-state-template.sh` (WS21 and WS22 go; one assertion each
    for `reviews: []` and `effort_check: --` with their `[W]` comments), the existing `test-writeback-state.sh`
    assertions, `test-skill-steps.sh` SS-08 where it reads the template, and any suite the findings' P3 or P8
    assigns here.
- **Acceptance criteria:**
  - [ ] The template has no `interview:`, `features:` or `review_history:` key, and has `reviews: []` and `effort_check: --`, each with its `[W]` comment (SP-06's template clause).
  - [ ] On a scratch work file with no `reviews` key, `--review --grade A --notes x` adds the key with one entry whose `by` is the saved skill; `--grade Z` exits 4 with the file byte-identical; `--pipeline --field "Effort Check" --value High` exits 4.
  - [ ] `test-work-state-template.sh` and `test-writeback-state.sh` pass where the test step puts them, and `test-skill-steps.sh` SS-08 passes in the scratch copy.

### task-165: slice-requirements.sh reads a document that does not split [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-161.
- **Source:** AC-44.
- **Scope:**
  - `canonical/aid/scripts/execute/slice-requirements.sh` (REQUIREMENTS.md § 11 Feature 005 `##### 2. The document`, Readers of the old
    shape):
    - when the document has `## 11. Technical Specification`, it prints that whole section in place of a
      feature section, and the task's `**Source:**` line need not name a feature;
    - otherwise it prints the task's `### Feature NNN` section as today, for both shapes of a split document;
    - the cited criteria and the identity block are printed as today, and a Source that names no criterion is
      still an error.
  - The unit cases are task-176.
  - Suites to update in this same task: the existing `test-slice-requirements.sh` assertions, and any suite
    the findings' P4 or P8 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch unsplit document and a task whose Source names only criteria, the output holds `## 11. Technical Specification`, the cited criteria and the identity block.
  - [ ] The output for this work's own `REQUIREMENTS.md` and a delivery-001 task is byte-identical before and after the change, and `test-slice-requirements.sh` passes live.

### task-166: aid-specify references: START, the effort check, REQUIREMENTS and FEATURES [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-162, task-163, task-164.
- **Source:** AC-12, AC-16, AC-28.
- **Scope:**
  - Create in `canonical/skills/aid-specify/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 3. Flow`, steps 1-3, and `##### 5. Components`,
    Effort check):
    - `start.md`: what START reads (the record, the idea draft and `draft` sources through
      `idea-drafts.sh path`, the draft's open questions and `## Kind` with its `shape` points, `sources:`, the
      open `qa` first, the KB through `INDEX.md`); the effort check while `effort_check` is `--`; the tracker
      read seam moved from `state-initialize.md` Step 3b with its wording ("Skip silently when no such ticket
      applies or no matching connector is catalogued"); what is already on disk is kept; `REQUIREMENTS.md`
      created from `requirements.md` when absent; a change after Specification goes straight to REVISE;
    - `effort-check.md`: one row per tool, filled from task-162's findings; the high-or-above, below-high and
      "cannot be read" paths with the spec's wording; `effort_check` written before any question it asks; the
      agent only reads, never writes a tool setting;
    - `requirements.md`: the business part, drafted by `aid-architect` in a clean context and never asking the
      user; the open points asked by subject under the question protocol; "ask only what blocks" (Q65); every
      criterion names an observable; the one-line reading when Specification is the first phase;
    - `features.md`: the split rule; no split asks nothing; a split is one question, and in `lite` first
      re-routes to `full` with `--reroute`; the business checkpoint in `full`, recorded `covers: requirements
      business part`; in a fix, only the split question.
  - `SKILL.md` and the old references stay until task-170 points the step table at these files.
  - Suites to update in this same task: any suite the findings' P8 assigns to these new files.
- **Acceptance criteria:**
  - [ ] The four files exist, each at most 120 lines. `start.md` cites `effort-check.md` and holds the read seam's silent-skip sentence verbatim.
  - [ ] `effort-check.md` has a row for each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI and states the "cannot be read" path; `git grep -n effort-check -- canonical/skills/aid-kb-build` finds nothing (SP-04).
  - [ ] `features.md` names `--reroute` and `covers: requirements business part`. The site `npm test` passes after regeneration.

### task-167: aid-specify references: DESIGN, CHECK and the reviewer brief [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-163, task-164.
- **Source:** AC-16, AC-44.
- **Scope:**
  - Create in `canonical/skills/aid-specify/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 3. Flow`, steps 4-5, and the Fix route):
    - `design.md`: the technical part drafted once for the work, or feature by feature in id order; research
      fanned out to `aid-researcher`; a `WAIT` for an investigation only the user can make (today's SPIKE) and
      an open question for a pending answer (today's BLOCKED); real forks asked in plain words, the rest
      recorded `Assumed`; `known-issues-scope.md`'s filter moved here unchanged; the optional-section list as
      prompts, not headings; a KB conflict raised with the user; a kind's `shape` points settled in Data and
      interfaces;
    - `check.md`: one graded `aid-reviewer` pass over the whole document, ledger
      `.aid/.temp/review-pending/<work>-specify.md`; what it reports; the cross-document contradiction pass
      (Guard 2) on cycle 1, once per work; `grade.sh` and `--review`; the Fix route; after three rounds below
      the bar, one question per open row -- fix, accept (ledger status `Accepted`, the choice in Evidence), or
      keep reviewing (Q69); nothing goes on to APPROVE unless the grade passes or every open row is accepted.
  - Rewrite `references/reviewer-brief.md` for the whole-document pass, with `### What to report` (FR-21,
    SS-13).
  - The Guard 2 site table in `reviewer-dispatch.md` is task-171's.
  - Suites to update in this same task: `test-scoped-review-cycles.sh`, because `check.md` is the first
    `aid-specify` reference to name Guard 2 and today's SC11 fails on that. SC10's three sites become
    `aid-specify/references/check.md`, `aid-plan/references/review-deliverables.md` and
    `aid-detail/references/review.md`; SC11 now asserts that `aid-specify` invokes the pass in `check.md` and in
    no other reference (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Suites). Also any suite the findings' P5 or P8 assigns to
    these files.
- **Acceptance criteria:**
  - [ ] `design.md` and `check.md` exist, each at most 120 lines. `check.md` names fix, accept and keep reviewing, the status `Accepted`, `<work>-specify.md` and Guard 2 (SP-03's `check.md` clause).
  - [ ] `reviewer-brief.md` has `### What to report`, SS-13 passes in the scratch copy, and `test-scoped-review-cycles.sh` passes live with SC10 and SC11 as the spec states them.
  - [ ] The site `npm test` passes after regeneration.

### task-168: skill-steps.md: the business-part approval row and the KB call on confirmation [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-161.
- **Source:** AC-10, AC-15.
- **Scope:**
  - `canonical/aid/templates/skill-steps.md` § When approvals happen (REQUIREMENTS.md § 11 Feature 005 `##### 5. Components`, Approvals and
    The KB call on confirmation):
    - one row, placed above the `REQUIREMENTS.md` row: "The business part of `REQUIREMENTS.md`, before the
      technical part is designed (Specification)" -- `full` approve, `lite` --;
    - under the table, the rule: any approval that approves a decision of reach `project`, directly or from an
      `Assumed` entry, makes right after the yes the single `CALL` to `/aid-kb-update` (`change`) carrying every
      such decision, `--handoff --to aid-kb-update --step START --why 'approved decisions: <titles>' --returns
      yes`; only when a KB exists, else one line per work (Feature 004, No KB: one rule); the skill running the
      approval makes the call.
  - Suites to update in this same task: any suite that asserts the approvals table (the findings' P8).
- **Acceptance criteria:**
  - [ ] `skill-steps.md` has the business-part row directly above the `REQUIREMENTS.md` row, and the rule names `project`, `Assumed`, `aid-kb-update` and `--returns yes` (SP-07's `skill-steps.md` clauses).
  - [ ] Every pointer in the file resolves under `canonical/aid/` (SR-01), and the suites that read the table pass where the test step puts them.

### task-169: aid-specify references: APPROVE, FINISH and REVISE [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-164, task-168.
- **Source:** AC-10, AC-15, AC-37.
- **Scope:**
  - Create in `canonical/skills/aid-specify/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 3. Flow`, steps 6-7, and Changing the document after
    Specification):
    - `approve.md`: `full` -- what changed in the business part first, then the technical part in chunks, the
      small decisions in the same batch, the draft's removal and the `project` decisions to be recorded named;
      recorded `covers: REQUIREMENTS.md`; a change takes the Fix route. `lite` -- no stop;
    - `finish.md`: the KB call by `skill-steps.md`'s rule, with the No-KB line; then `PASS` with
      `--handoff --to aid-plan --step <its entry step> --returns no --phase Planning`; in a revision, `HALT` or
      `PASS` back without `--phase`;
    - `revise.md`: entry by a `CALL` or a typed start; scope, edit in place, `step_detail: 'revise: <what>'`, no
      effort check; CHECK scoped to the changed sections and every section citing a changed id; the approvals
      by kind of change (`covers: requirements change`; `Specification change` recorded `Assumed`), including
      the `lite` cases before and after the confirmation before building.
  - Suites to update in this same task: any suite the findings' P8 assigns to these files.
- **Acceptance criteria:**
  - [ ] The three files exist, each at most 120 lines. `finish.md` names `aid-plan`, `--phase Planning`, `aid-kb-update` with `--returns yes`, and the No-KB rule; `revise.md` names `requirements change` and `Specification change` (SP-03's clauses).
  - [ ] The site `npm test` passes after regeneration.

### task-170: aid-specify SKILL.md rewritten, and its old references deleted [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-165, task-166, task-167, task-169.
- **Source:** AC-12, AC-16, AC-44.
- **Scope:**
  - Rewrite `canonical/skills/aid-specify/SKILL.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 1. Files and layout` and
    `##### 3. Flow`):
    - the step table START, REQUIREMENTS, FEATURES, DESIGN, CHECK, APPROVE, FINISH and REVISE, pointing at the
      nine references of task-166, task-167 and task-169, with the spec's workers and advance words;
    - `skill-steps.md` and `question-protocol.md` cited;
    - the spec's `description:` and `argument-hint: "[what to specify, or what to change]"`;
    - the plan-mode check as one line;
    - gone: the feature-path argument, `--reset`, Check 1's work listing, its own worktree entry, the state map
      and banners.
  - Delete the eight old references in `canonical/skills/aid-specify/references/`: `state-initialize.md`, `state-continue.md`,
    `state-review.md`, `state-spike.md`, `state-blocked.md`, `state-done.md`, `handling-outcomes.md` and
    `known-issues-scope.md`. Delete `canonical/aid/templates/specs/` with them: its last user,
    `state-continue.md`, goes here.
  - **Lists and counts that follow a rewritten skill**, in this same task: the `/aid-specify` line of
    `canonical/aid/rules.md` § Skill guide, with the spec's text; `aid-specify`'s SG-04 exempt row, if it has
    one; the site skill lists and flows and their `__tests__`.
  - Suites to update in this same task: `test-ticket-retirement-structural.sh` (`SPECIFY_INIT` becomes
    `start.md` in the T000 loop and the seam map, so T045, T046 and T097 hold there),
    `test-pipeline-status-walkthrough.sh` and `test-writeback-state.sh` where they follow the deleted
    references, `test-artifact-discipline.sh` (AD13's ceilings drop to the new measured counts), and any suite
    the findings' P2 or P8 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `SKILL.md` is at most 120 lines, and its step table has the eight steps with FINISH advancing by `PASS` (SP-03). None of the eight old references and no `canonical/aid/templates/specs/` exists, and the nine new references and the brief do (SP-01's `aid-specify` clauses).
  - [ ] Over `canonical/skills/aid-specify/`, `git grep -nE 'state-(initialize|continue|review|spike|blocked|done)\.md|--reset|technical-specification-template'` finds nothing.
  - [ ] SG-02, SG-04 and `test-ticket-retirement-structural.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-171: Review contracts: the Guard 2 site, the ledger path and aid-architect's output line [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-167.
- **Source:** AC-44.
- **Scope:**
  - `canonical/aid/templates/reviewer-dispatch.md` § The cross-document contradiction pass (Guard 2) (REQUIREMENTS.md § 11 Feature 005
    `##### 5. Components`, The contradiction pass): the `aid-define` CROSS-REFERENCE row becomes `aid-specify`
    CHECK, receiving `REQUIREMENTS.md`, every section, once per work; the paragraph "`aid-specify` deliberately
    gets no invocation" becomes one line saying CHECK reviews the whole document once per work; `aid-define`
    leaves the list of skills that render the brief structure. The `aid-plan` row stays.
  - `canonical/aid/templates/reviewer-ledger-schema.md`: the `/aid-specify <feature>` and `/aid-define <work>`
    rows become one, `/aid-specify` -> `.aid/.temp/review-pending/<work>-specify.md`.
  - `canonical/agents/aid-architect/AGENT.md`: its "What You Do" and "Output Format" lines name § 11 "once
    for the work or once per feature, per `templates/requirements/requirements-template.md`".
  - Suites to update in this same task: `test-scoped-review-cycles.sh` where it reads `reviewer-dispatch.md`
    (SC09; its SC10 and SC11 changed with task-167), and any suite the findings' P5 or P8 assigns here.
- **Acceptance criteria:**
  - [ ] `reviewer-dispatch.md`'s site table names `aid-specify` CHECK and has no `aid-define` row (SP-07's clause), and the ledger schema has one `/aid-specify` row naming `<work>-specify.md`.
  - [ ] `test-scoped-review-cycles.sh` passes live.
  - [ ] The site `npm test` passes after `gen:reference`.

### task-172: The gate's legacy rows for old Define and Specify works [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-170.
- **Source:** AC-37.
- **Scope:**
  - `canonical/aid/templates/work-initiation-gate.md` § 3b legacy block (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Existing
    works): Feature 002's old-phase rows `Define` -> `/aid-define` and `Specify` -> `/aid-specify` become
    `Define` or `Specify` -> `/aid-specify` at **START**, and one row is added: `pipeline.initiator` or
    `active_skill` `aid-define` -> the same. Feature 003's `aid-describe` row already points here.
  - `tests/canonical/test-work-initiation-gate.sh` gains a passing `--check` fixture for each changed row.
  - Suites to update in this same task: any suite the findings' P6 or P8 assigns to the legacy block.
- **Acceptance criteria:**
  - [ ] Inside the legacy block, no row proposes `/aid-define`; a work at `phase: Define`, one at `phase: Specify` and one with `initiator: aid-define` are each proposed `/aid-specify` at START.
  - [ ] Each fixture passes in `test-work-initiation-gate.sh` where the test step puts it. Walking the block's first-match order by hand, recorded in the report, the three Feature 003 rows still win over these rows.

### task-173: Re-point every kept file that names aid-define [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-170, task-171.
- **Source:** AC-16.
- **Scope:**
  - Re-point by one rule (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Re-pointing) every kept file under `canonical/`, and
    `dashboard/home.html`, that names `aid-define`, to `/aid-specify` or reworded. Exempt: the gate's legacy
    block and `canonical/aid/scripts/migrate/`. The stated sites beyond task-171's:
    - `downstream-worktree-entry.md` and `worktree-lifecycle.md`: their consumer lists (`aid-specify` no
      longer enters a worktree itself);
    - `shortcut-scaffolding/analyze-report.md`;
    - `shortcut-engine.md` § State: SPEC: its sentence naming define's CROSS-REFERENCE is reworded; the
      engine stays (Q65);
    - `aid-kb-build/references/reviewer-brief.md`;
    - outside `canonical/`, the comment in `dashboard/reader/derivation.py`; the comment in `bin/aid`'s state
      converter stays.
  - Suites to update in this same task: `test-downstream-worktree-entry.sh` (its `aid-define` and
    `aid-specify` assertions go), and any suite the findings' P1 or P8 assigns to these files.
- **Acceptance criteria:**
  - [ ] Over `canonical/` and `dashboard/home.html`, `git grep -n aid-define` finds only the files of `canonical/skills/aid-define/` (deleted by task-174), the gate's legacy block and `canonical/aid/scripts/migrate/` (SP-02, scoped to hold at this task's end).
  - [ ] `test-downstream-worktree-entry.sh` passes where the test step puts it, and the site `npm test` passes after regeneration.

### task-174: aid-define retired [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-172, task-173.
- **Source:** AC-16.
- **Scope:**
  - Delete `canonical/skills/aid-define/` (REQUIREMENTS.md § 11 Feature 005 `##### 1. Files and layout`): its split decision now lives in
    FEATURES and its cross-reference in CHECK.
  - **Lists and counts that follow the retired skill**, in this same task:
    - its `canonical/aid/rules.md` § Skill guide line;
    - its SG-04 exempt row;
    - its `skill:aid-define` row in `tests/conversation/deferred.tsv`;
    - the site skill lists and flows (`site/scripts/skills/`, `.skills-manifest.json`,
      `site/scripts/lib/flow-graph/`) and their `__tests__`;
    - the counted phrases that `test-doc-counts.sh` asserts (Q134 D5).
  - Suites to update in this same task: `test-state-review-surface.sh` (the `aid-define` brief path goes),
    `test-shared-prune.sh`, `test-shared-remove.sh` and the `test-aid-cli-parity.sh` drift row (they switch to
    `aid-plan` as the sample installed skill), and any suite the findings' P1 or P8 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-define` fails, and over `canonical/` and `dashboard/home.html`, `git grep -n aid-define` finds only the gate's legacy block and `canonical/aid/scripts/migrate/` (SP-02).
  - [ ] SG-02, SG-04 and DT-01 pass in the scratch copy, `test-doc-counts.sh` passes live, and the three switched suites pass where the test step puts them.
  - [ ] The site `npm test` passes after regeneration.

### task-175: Writer unit cases: --review on the work file and Effort Check [TEST]

- **Stanza wave:** 5. **Depends on:** task-164.
- **Source:** AC-12, AC-44.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains the cases of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`:
    - `--review` without `--kb` appends a `reviews` entry to the work file, with `by` the saved skill;
    - on a work file with no `reviews` key, it adds the key with that entry (Q130);
    - a bad grade exits 4 and changes nothing;
    - the file parses through the dashboard reader;
    - `--kb --review` is unchanged;
    - `--pipeline --field "Effort Check"` accepts `--`, `unknown` and a level name, and refuses anything else
      with exit 4.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-176: Unit cases: test-slice-requirements.sh for the unsplit shape [TEST]

- **Stanza wave:** 5. **Depends on:** task-165.
- **Source:** AC-44.
- **Scope:**
  - `tests/canonical/test-slice-requirements.sh` gains the cases of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`:
    - an unsplit document prints `## 11. Technical Specification`, the cited criteria and the identity block,
      with a Source that names no feature;
    - the output for a split document, in both shapes, is unchanged;
    - a Source naming no criterion still fails.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its branch is broken in a scratch copy of the script.
  - [ ] The cases are deterministic and use temporary fixtures only.

### task-177: test-specify.sh (SP-01 to SP-08) and the SP-08 exempt row [TEST]

- **Stanza wave:** 5. **Depends on:** task-163, task-164, task-168, task-170, task-171, task-174.
- **Source:** AC-12, AC-16, AC-44.
- **Scope:**
  - Create `tests/canonical/test-specify.sh` with SP-01 to SP-08, as REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing` defines them. It
    has `# COVERS:` lines.
  - `tests/canonical/skill-steps-exempt.tsv` gains one row: `canonical/aid/templates/shortcut-engine.md`,
    checks `SP-08`, owner Feature 009 (Q65), so SP-08 skips the engine's own `## State: CAPTURE` and
    `## State: SPEC` until Feature 009 removes them.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, and `test-skill-steps.sh` passes with the new exempt row.
  - [ ] Each check fails its own mutation in a scratch copy: a `canonical/skills/aid-define/` folder; a kept file naming `aid-define`; `finish.md` without `aid-plan`; `effort-check.md` without its Copilot CLI row; the template without `**Serves:**`; a `features:` line in a skill; a missing business-part row; a `## State: SPEC` heading in a skill.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-178: Samples 005-01 to 005-05 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-170, task-174.
- **Source:** AC-12, AC-16, AC-28, AC-44.
- **Scope:**
  - Create under `tests/conversation/samples/feature-005/`, with frontmatter `skills: aid-specify`, their
    fixtures and the checks of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`: `005-01-bug-fix-no-features`,
    `005-02-two-capabilities-split`, `005-03-many-requirements-one-capability`, `005-04-effort-below-high`
    (its fixture set below high as task-162's Claude Code row says) and `005-05-effort-cannot-be-read`.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are five files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-179: Samples 005-06 to 005-10 (run at this gate), and the deferred rows that now run [TEST]

- **Stanza wave:** 5. **Depends on:** task-169, task-172, task-178.
- **Source:** AC-9, AC-10, AC-15, AC-37, AC-44.
- **Scope:**
  - Create under `tests/conversation/samples/feature-005/`, with frontmatter `skills: aid-specify`, their
    fixtures and the checks of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`: `005-06-full-two-checkpoints`,
    `005-07-lite-ticket-no-stop`, `005-08-decision-to-kb` (both runs), `005-09-change-requirement-later` (both
    runs) and `005-10-old-define-work`.
  - Update `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Lists other features own):
    - the `skill:aid-specify` row goes, since `005-01` and `005-04` cover it;
    - the rows of `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09` and `004-10` go: they run at this
      gate;
    - `002-07` waits only for Feature 007, and `002-08` and `002-09` for Features 006 and 007.
  - Smoke run (Q134 D8): each new sample once, and each sample whose row goes once, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are five new files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
  - [ ] DT-01 and SS-09 pass, with no `skill:aid-specify` row and none of the seven rows left.
  - [ ] Each smoke run has its result reported.

### task-180: Samples 005-11, 005-12 and 005-13 (deferred) and their deferred rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-179.
- **Source:** AC-10, AC-15, AC-32.
- **Scope:**
  - Create `005-11-lite-decision-to-kb-at-confirmation`, `005-12-lite-change-after-confirmation` and
    `005-13-assumed-decision-to-kb-at-plan-approval` under `tests/conversation/samples/feature-005/`, with their
    fixtures and the checks of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`.
  - Update `tests/conversation/deferred.tsv` with one row each: `005-11` and `005-12` wait for Feature 007,
    `005-13` for Feature 006. Delivery-008 runs `005-13` and delivery-009 runs `005-11` and `005-12` (PLAN.md).
- **Acceptance criteria:**
  - [ ] There are three files, each `covers` matches the spec's sample table, and each has a `deferred.tsv` row naming its feature.
  - [ ] DT-01 passes.

### task-181: test-specify.sh in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-177.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-specify`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's
    text.
- **Acceptance criteria:**
  - [ ] `test-specify` appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-182: KB decisions, schemas, glossary, tech debt and backlog for one Specification skill [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-164, task-168, task-174.
- **Source:** AC-16, AC-24, AC-44.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, KB and Release notes):
    - `decisions.md`: the new decision "one Specification skill: a feature is a capability a user values on
      its own, and the technical part is written once per work, or once per feature when the work splits". It
      amends D29, marked in the summary table and in D29's section;
    - `artifact-schemas.md`: the two-part shape; `interview`, `features` and `review_history` gone; `reviews`
      and `effort_check`;
    - `domain-glossary.md`: feature as a business capability, business part, technical part, effort check;
      define goes;
    - `tech-debt.md`: SY-6 and W5-5 narrowed, their `aid-define` and `aid-specify` sites gone;
    - `backlog.md` § Next Release: the old -> new rows for `/aid-define` and for
      `/aid-specify work-NNN/feature-NNN` and `--reset` (AC-24).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] The backlog rows carry the spec's New text, and D29 is marked in the summary table and in its section.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-183: KB architecture, contracts and quality documents for one Specification skill [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-170, task-171, task-174.
- **Source:** AC-16, AC-44.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, KB):
    - `architecture.md` and `pipeline-contracts.md`: the Define and Specify rows become one Specification row;
      the state machines; the artifact rows for `REQUIREMENTS.md` and the feature section; the loops that route
      to Specify now reach `/aid-specify`'s REVISE;
    - `capability-inventory.md` and `module-map.md`;
    - `quality-gates.md`: one Specification check replaces the cross-reference and per-feature gates.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -n aid-define` finds nothing outside marked history.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-174 leaves it.

### task-184: KB test landscape for test-specify.sh, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-175, task-176, task-177, task-179, task-180, task-181, task-182, task-183.
- **Source:** AC-15, AC-25.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-specify.sh` and its lane; the new cases of
    `test-writeback-state.sh` and `test-slice-requirements.sh`; SC10 and SC11 as they now read.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed `render-kb-view.sh` (G0). This
    delivery's resync changes no KB document.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `test-specify.sh` and its lane.
  - [ ] `INDEX.md` is regenerated, and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-specify` rewritten with eight steps and nine references; its old references deleted | 166, 167, 169 (references); 170 (SKILL.md, deletions) |
| `aid-define` and `templates/specs/` deleted | 174; 170 |
| The two-part `requirements-template.md` and the bare `requirements.md` | 163 |
| `effort-check.md`, one row per tool | 162 (findings), 166 |
| Writer `--review` on the work file (Q130) and `"Effort Check"`; the template drops `interview`, `features`, `review_history` | 164 |
| `slice-requirements.sh` reads the unsplit shape | 165 |
| `skill-steps.md`: the business-part row and the KB call on confirmation | 168 |
| Guard 2 moves to `aid-specify` CHECK; ledger schema; `aid-architect` | 167 (CHECK, SC10/SC11), 171 |
| Legacy rows (`Define`, `Specify`, `aid-define`) with their fixtures | 172 |
| Re-pointing of `aid-define` | 173, 174 |
| `test-specify.sh` SP-01 to SP-08, the SP-08 exempt row, `SUITES` | 177, 181 |
| Unit cases: writer, slice | 175, 176 |
| Samples `005-01` to `005-10` (run); `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09`, `004-10` run now; `005-11` to `005-13` deferred | 178, 179; 179 (rows); 180 |
| G0: AC-24 rows; KB documents; `INDEX.md`; `kb.html` | 182; 182, 183, 184; 184; 184 |

**Steps that are not tasks:**
1. `--delivery-id 007 --lifecycle Executing`.
2. The tasks.
3. Verification.
4. The resync (`delivery-007: resync`): the retired `aid-define`, the deleted references and the two deleted
   templates leave through the manifest.
5. **After the resync, in the gate session (G8):** `(cd site && npm run gen:reference)` and the site `npm test`: a site page generated from a file the resync
     changes (`reference/settings.md` from `.aid/settings.yml`) is regenerated and committed; a no-op when
     nothing changed. The resync converts no file and changes no
   KB document, so `INDEX.md` and `kb.html` stay as task-184 left them (`render-kb-view.sh --check` exits 0).
6. The gate, in the same session, after step 5: the stanza's criteria; `005-01` to `005-10`, the seven samples that now run,
   and `001-08` and `001-09` again, each 3 of 3; G0 with the baselines; the tracking proof for task-161 to
   task-184.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-161
wave 2: task-162, task-163, task-164, task-165, task-168
wave 3: task-166, task-167, task-169, task-175, task-176
wave 4: task-170, task-171
wave 5: task-172, task-173
wave 6: task-174
wave 7: task-177, task-178, task-182, task-183
wave 8: task-179, task-181
wave 9: task-180
wave 10: task-184
```

Step 5 writes the table under `### delivery-007 Execution Graph`, one task per row, from the task files'
`**Depends on:**` lines.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | `aid-specify`'s rewrite is too big for one review: `SKILL.md`, nine references and the brief. | Four tasks: three create the new references (166 START to FEATURES; 167 DESIGN, CHECK and the brief; 169 APPROVE to REVISE), unreferenced until task-170 rewrites `SKILL.md`, points its table at them and deletes the old references. No pointer dangles at any task's end. | One session and one review per task; SR-01. |
| S2 | The effort table's rows are "filled at build time from each tool's own documentation". | A RESEARCH task (162) reads the five tools' documentation first; `effort-check.md` (166) is written from its findings. | Type detection: an unknown that needs investigation. |
| S3 | SC11 today fails as soon as an `aid-specify` reference names Guard 2. | SC10 and SC11 change in task-167, which writes `check.md`; task-171 keeps SC09 with `reviewer-dispatch.md`. | Q106. |
| S4 | `specs/technical-specification-template.md`'s only user is `state-continue.md`. | It is deleted in task-170, with that reference. | G6; no dangling pointer. |
| S5 | `aid-define`'s re-pointing and its deletion. | Two tasks (173 then 174), as delivery-004 did for `aid-describe`. | Size; G6. |
| S6 | The legacy-row fixtures. | In the IMPLEMENT task that changes the rows (172), as the spec's Migration says. | F005 § 7; Q106. |
| S7 | `005-11` to `005-13` are Feature 005's deferred samples. | Written here with their `deferred.tsv` rows (180), as delivery-006 did for `004-10` to `004-12`. | F005 § 7, Lists. |
| S8 | `kb.html`. | Rendered by task-184 after `INDEX.md`: this resync runs no format step and changes no KB document. | G0. |
| S9 | Unit cases, samples, the CI lane and the test landscape. | TEST tasks; one smoke run per sample; one CONFIGURE task for `SUITES`; `test-landscape.md` last. | Q134 D2, D8; Q135 R1, R3. |

---

## 7. Flagged for the maintainer

None.
