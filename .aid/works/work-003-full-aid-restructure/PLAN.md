# Plan -- Conversational AID Restructure

All nine features ship as AID v4.0.0, in 14 deliveries built in order on the `work-003` branch.
The maintainer set the shape in the work `STATE.yml` `qa` Q111-Q116.

- Each delivery leaves the repository consistent, with the full suite green.
- Feature ids cite `REQUIREMENTS.md` § 11. Criteria cite § 9 `AC-N`.
- Sample ids name files under `tests/conversation/samples/`.
- Static-check ids name the groups each feature's Testing section defines.
- Q116: the cross-feature review of Feature 002's shared contracts runs in this plan's REVIEW.
- **Waves** in each stanza are groups of work in dependency order. A later wave needs the one before
  it; work inside one wave has no order. `/aid-detail` turns them into task `**Depends on:**` lines.

## Common Gate (G0)

Every delivery's gate ends with G0. G0 holds when all of these are true:

- `HOME="$(mktemp -d)" bash tests/run-all.sh` exits 0, and the site `npm test` passes, both run
  locally. The canonical lane does not run on feature branches (`test-landscape.md` § CI Lanes and
  Where They Run).
- Running `python .claude/skills/generate-profile/scripts/run_generator.py` leaves no diff under
  `profiles/`.
- The `installer-tests.yml` lane, which includes the Windows PowerShell twins, is green on the pushed
  `work-003` branch. (AC-25)
- Every earlier delivery's static-check group still passes. For a split feature (Q113, Q115), its
  suite holds one group per part, and each group is added in the delivery that lands its part.
- Every skill or artifact name the delivery adds is a verb, or KB plus a verb, with no acronym.
  (AC-22)
- Every slash name the delivery retires has its row in the old -> new table in
  `.aid/knowledge/backlog.md` § Next Release. (AC-24)
- The KB documents the delivery's spec lists are updated with no work id, and `INDEX.md` is
  regenerated. From delivery-005 on, `kb.html` is also re-rendered by `render-kb-view.sh`.
- `tests/coverage-baseline.tsv` and `tests/cost-baseline.tsv` are re-recorded, and every removed
  assertion has its row in `tests/coverage-accepted-removals.tsv`.
- Every conversation sample the stanza names passes 3 runs of 3 (NFR-T). Every sample still waiting
  has a row in `tests/conversation/deferred.tsv` naming what it waits for.

## Deliverables

### delivery-001: Ask in plain words
- **What it delivers:** A user states a request in plain words; the agent reads it by meaning, checks it against the skill guide, the KB and the code, and proposes the matching workflow. Project questions are answered from the KB with sources. Works record their intent and their own sources.
- **Features:** feature-001-plain-language-requests
- **Depends on:** --
- **Priority:** Must

**Objective:** This delivery lays the foundation every later delivery edits:

- the `## Handling a request` section and the `## Skill guide` in `rules.md`;
- the on-demand `/aid-orchestrate` skill;
- the work's `intent:` and `sources:` keys;
- the conversation test suite that every later gate runs.

It is a distinct unit because nothing else in the work can be built before it.

**Scope:**
- `canonical/aid/rules.md`:
  - `## Handling a request`, at most 20 lines, replaces `## Workflow`;
  - a new `## Skill guide` lists today's skills, with the `<kind>` expansion for families;
  - one new summary bullet;
  - the stale state-file wording is fixed (KI-001).
  (AC-1, AC-2, AC-3, AC-5, AC-6)
- The new `canonical/skills/aid-orchestrate/` and its five references: start or resume, check intent,
  size and route, external sources, feedback routing. Until delivery-010, it runs the close minimum
  itself. (AC-4, AC-7, AC-14)
- Every skill's `description:` uses the what/when shape, including the doorway builder's template.
  (AC-21)
- `intent:` and `sources:` are added to the work-state template. `ticket_ref` is removed from every
  template. `aid-update-ticket` gains the `attachment` part. (AC-29)
- `aid-triage`, the `aid-orchestrator` agent and `.aid/design/skill-routing.md` retire. `aid-monitor`
  is re-pointed. (AC-23)
- New `tests/canonical/test-skill-guide.sh` (SG-01 to SG-06) and the conversation suite
  `tests/conversation/` (`run.py`, the simulated user, the judge). (AC-21, NFR-T)

**Out of scope:**
- The question protocol and the step rules (delivery-002).
- The `ticket_ref` -> `sources:` migration of existing works (delivery-008).

**Waves:**
1. Re-run the spec's stated searches (triage, orchestrator and `ticket_ref` sites) and reconcile the edit list.
2. The rules sections, the templates (`intent:`, `sources:`, no `ticket_ref`) and the conversation-suite harness.
3. `/aid-orchestrate` and its references, the re-pointed skills and the retirements, which need the rules sections and templates.
4. Skill descriptions, the builder template, the site and KB edits, and the static suite.
5. The delivery's conversation samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `tests/canonical/test-skill-guide.sh` SG-01 to SG-06 pass. `## Handling a request` counts at most 20 lines. The guide names exactly the skills in `canonical/skills/`, both ways. No `aid-triage` and no `aid-orchestrator` exist. Every skill is installed for all five tools. (AC-6, AC-21, AC-23)
- [ ] Samples `001-01` to `001-16` each pass 3 of 3 through `tests/conversation/run.py --feature 001`. (AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14, AC-29)
- [ ] `canonical/aid/templates/work-state-template.yml` carries `intent:` and `sources:` in block style. `git grep ticket_ref -- canonical/aid/templates` finds nothing. (AC-29)
- [ ] `canonical/aid/rules.md` § Tracking discipline names the work state file `STATE.yml`, not `STATE.md`. (KI-001)
- [ ] G0 passes.

### delivery-002: One work record and one set of step rules (Feature 002, engine)
- **What it delivers:** Every work gets a record -- type, running skill, step -- from the moment it is created, every skill writes its step before working, and any session resumes exactly where the record says; the phase names become Definition, Specification, Planning, Building, CI everywhere; the question protocol, the step rules and the approval and merge rules are written once.
- **Features:** feature-002-step-by-step-decisions (engine part)
- **Depends on:** delivery-001
- **Priority:** Must

**Objective:** This delivery puts in place the contract every later phase skill is rebuilt on:

- `question-protocol.md` and `skill-steps.md`;
- the writer modes;
- the work record, created only by the gate, kept current by every skill, and the only thing that
  decides where a work resumes.

Q115 limits the engine to "protocol, skill-steps.md, writer modes, work record, gate". Two edits that
touch today's skills are taken into the engine as well:

- the per-skill record keeping;
- the new phase names at every site, the dashboard included.

The writer refuses old phase names, and the gate routes only by the record. Both hold only when every
writer, every skill and both readers change in the same delivery (Notes).

**Scope:**
- **Shared rules:**
  - new `canonical/aid/templates/question-protocol.md`;
  - new `canonical/aid/templates/skill-steps.md`, including § The work record and § When approvals
    happen, with the never-merges rule;
  - new `project-state-template.yml`.
  (AC-8, AC-10, AC-11)
- **The writer:** `writeback-state.sh` gains the modes `--create`, `--step`, `--handoff`,
  `--handoff-return`, `--reroute`, `--check`, `--repair`, `--ask` and `--answer`.
  - New exits 7, 8 and 9; every write is atomic.
  - Only the new phase names are accepted. The dashboard fork follows with the new names and keeps
    `Deploy`.
  (AC-37, AC-38)
- **The work record:**
  - The gate's § 3a runs `--create`, and every allocation point goes through it.
  - `aid-describe --reset` is removed.
  - § 3b routes by the record only: the resume table, `--check` with a confirmed `--repair`, and the
    legacy block.
  - The starters' continuation lines change to match.
  - Every skill's § State Detection only shapes the entry step, or validates the saved step.
  - Every skill with a Dispatch table cites `skill-steps.md` for step entry.
  - The seven kept finishers finish through the writer.
  - `/aid-orchestrate` starts, resumes and cancels works. The `rules.md` bullets name
    `question-protocol.md` and the merge rule.
  (AC-11, AC-37)
- **Phase sites:**
  - the nine `--field Phase --value` writes and the two literal seeds;
  - the gate;
  - `aid-deploy` `references/state-idle.md`;
  - both readers' `Phase` enum and old-name map, inside `legacy-phase-map` markers;
  - `home.html`: `PHASE_ORDER`, `PRE_EXEC_STEPS`, and one stage rail per work drawn from
    `intent.phases`, which replaces the lite rail (Q75).
  (AC-41)
- **New suites:**
  - `tests/canonical/test-skill-steps.sh` engine group (E): SS-02 for the citations only, SS-08,
    SS-11, SS-12, SS-14;
  - `skill-steps-exempt.tsv`;
  - `test-never-merges.sh` NM-01 to NM-04;
  - `test-deferred-tests.sh` DT-01 and DT-02, with `tests/conversation/deferred.tsv`;
  - `dashboard/server/tests/test_home_stage_rails.mjs`.

**Out of scope:**
- Banners and advance words.
- Deleting `state-machine-chaining.md`.
- Adopting the protocol in each asking skill, and dropping the host question pickers.
- The question-record sites (KI-003).
- The interviewer.
- Review focus.
- The dashboard's new work fields.

All of these are delivery-003.

**Waves:**
1. Re-run the spec's stated searches: phase sites (SS-11 forms), allocation points (SS-14), finishers (SS-12). Reconcile the edit list.
2. The writer modes, the phase-name enum and the dashboard fork. Then `question-protocol.md`, `skill-steps.md`, `project-state-template.yml` and the work-state template. Both groups only add, and the next wave consumes them.
3. The gate's § 3a and § 3b and `/aid-orchestrate`, which need the writer's `--create`, `--check` and `--repair`.
4. Every allocation point, continuation line, State Detection section, step-entry citation, finisher, phase write site and both readers' phase sites. These need the converted gate and the new names.
5. Suites (group E, NM, DT, the stage-rail test, writer and gate units), the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-skill-steps.sh` group E passes:
  - every `SKILL.md` with a Dispatch table, plus `shortcut-engine.md` and `design-lifecycle.md`, cites `skill-steps.md`;
  - both templates parse through the dashboard reader with no warning;
  - no old phase name appears as data or logic;
  - no hand-written `lifecycle: Completed` or `Canceled` exists outside the exempt list;
  - only the gate creates a work's `STATE.yml`.
  (AC-37)
- [ ] `test-never-merges.sh` NM-01 to NM-04 pass, and only the `aid-housekeep` and `aid-execute` exemptions fire. (AC-11)
- [ ] `test-writeback-state.sh` passes for every new mode:
  - `--create` exits 5, 4 or 8 on a bad call;
  - a failed write leaves the file byte-for-byte unchanged;
  - `--check` exits 9 or 0;
  - `--handoff-return` resolves nested calls newest first, and exits 7 with no open call.
  `test-work-initiation-gate.sh` has a passing `--check` fixture for each resume-table row. (AC-37, AC-38)
- [ ] Both dashboard readers map old and new phase names to the five new members, and pass parity. `test_home_stage_rails.mjs` marks the Building stage for a work without Definition that is at `Building`. (AC-41)
- [ ] Samples `002-05`, `002-20` and `002-21` each pass 3 of 3. Every other Feature 002 sample has a `deferred.tsv` row, and DT-01 passes. (AC-11, AC-37)
- [ ] G0 passes.

**Notes:**
- Adjusted from Q115. The engine takes the per-skill record keeping and the phase-name change at every
  site, the readers included. Each one is needed for the engine to stand alone:
  - § 3b resumes "`active_skill` at its saved `step`". If today's skills did not write their step on
    entry, a resumed work would land at its creation step.
  - The writer refuses old names. Every write site and both readers must change with it, or writes
    fail and the dashboard shows `Unknown`.
  The sweep keeps everything the user sees and every cleanup.

### delivery-003: Questions one topic at a time, no banners (Feature 002, sweep)
- **What it delivers:** No state banner or "you are here" map anywhere; every skill that asks the user follows the one question protocol in plain text in all five tools; every question is recorded in one place; the interviewer agent retires; the dashboard shows each work's step, its open questions, an open call and a record warning.
- **Features:** feature-002-step-by-step-decisions (sweep part)
- **Depends on:** delivery-002
- **Priority:** Must

**Objective:** Finish Feature 002 by sweeping today's skills, agents and dashboard onto the rules
delivery-002 wrote. Its suite group needs every asking skill converted, so this is a separate unit
from the engine.

**Scope:**
- Banners and "you are here" maps are removed from every hand-authored skill and the two shared
  engines.
- Advance words are translated one for one: `PAUSE-FOR-USER-DECISION` -> `ASK`,
  `PAUSE-FOR-USER-ACTION` -> `WAIT`.
- `state-machine-chaining.md` is deleted, with every citation of it.
- `site/scripts/lib/flow-graph/advance.mjs` learns the new words, and the flows are regenerated.
  (AC-37)
- Every asking skill carries the protocol line, and `AskUserQuestion` leaves every `allowed-tools`.
  `aid-describe`'s envelope points at the protocol. (AC-8, AC-9, AC-28)
- Every question-record site writes through `--ask` and `--answer`, and no skill names
  `## Cross-phase Q&A` (KI-003). The AD13 ceilings in `test-artifact-discipline.sh` drop to the new
  measured counts. (AC-28)
- `canonical/agents/aid-interviewer/` is deleted. `agent-boilerplate.md` gains
  `## Talking with the user`. The escalation lines record through `--ask`. Every interviewer site is
  re-pointed. (AC-40)
- `### What to report` is added to the reviewer agent, `reviewer-dispatch.md` and every
  `reviewer-brief.md`. (AC-46)
- Both readers, `server.py` and `home.html` show `step`, `step_detail`, `open_call`, work-level `qa`
  on every layout, `record_status` and the card lines. `chat-node/` stays untouched. (AC-41)
- `test-skill-steps.sh` sweep group (S): SS-01, SS-02 (the chaining file absent and cited nowhere),
  SS-03, SS-04, SS-05, SS-06, SS-07, SS-09, SS-10, SS-13.

**Out of scope:** The `PASS` and `CALL` edges of the rebuilt phase skills (deliveries 004-013).

**Waves:**
1. Re-run the spec's stated searches: SS-01 and SS-03 forms, interviewer sites, question-record sites, `AskUserQuestion` users, `reviewer-brief.md` files. Reconcile the edit list.
2. `agent-boilerplate.md`'s new section and the advance-word table in `advance.mjs`. The agent and flow edits depend on these.
3. The sweep over skills, shared engines, agents and briefs (banners, advance words, the protocol line, question-record sites, the interviewer removed, `### What to report`), together with the dashboard work fields. These two groups do not depend on each other.
4. Suites (group S, dashboard and site tests), the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-skill-steps.sh` group S passes, and group E still passes:
  - no banner form appears;
  - `state-machine-chaining.md` is absent and cited nowhere;
  - every `**Advance:**` word is one of `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL`, `HALT`;
  - no `AskUserQuestion` appears;
  - the word `interviewer` appears nowhere in scope;
  - no delivery-level `qa` write exists;
  - every asking skill has a sample or a `skill:` row;
  - every reviewer file has `### What to report`.
  (AC-8, AC-28, AC-37, AC-40, AC-46)
- [ ] Samples `002-01` to `002-04` and `002-14` to `002-19` each pass 3 of 3, and the judge applies `tests/conversation/protocol-checks.md` to each. (AC-8, AC-28)
- [ ] Dashboard fixtures show the card lines for a work at each phase, during a call, and with a missing and an inconsistent record. Both readers pass parity. (AC-41)
- [ ] `site/scripts/__tests__/flow-advance.test.mjs` passes on the new advance words. (AC-37)
- [ ] G0 passes.

### delivery-004: Shape an idea into a draft that survives
- **What it delivers:** `/aid-brainstorm` talks an idea through as a conversation the user ends, keeping a living idea draft in the main folder that survives across sessions and works; a typed kind and the same kind in plain words reach the same rules; `/aid-describe`, `/aid-design` and every `/aid-design-<kind>` retire.
- **Features:** feature-003-work-definition
- **Depends on:** delivery-003
- **Priority:** Must

**Objective:** Deliver the Definition phase on the new step rules and close the High known issue,
KI-004. With it closed, a draft written in one work can be found by the next.

**Scope:**
- `aid-brainstorm` is rewritten with the steps START, CONVERSE, CHECK and FINISH, plus parking and
  side ideas. (AC-17)
- New `canonical/aid/scripts/works/idea-drafts.sh`, with the deletion rule in `skill-steps.md`. The
  writer gains the `"Idea Draft"` and `"Side Idea"` fields. (AC-17)
- New `kind-catalog.yml` (v1). `aid-describe`, `aid-design` and every `aid-design-*` retire. The
  `verb: design` rows leave the shortcut catalog. (AC-43)
- `design-seed.md`, the folder README and `design-lifecycle.md` are trimmed. Two rows are added to the
  gate's legacy block. The `aid-orchestrate` routing rows are added. The dashboard's empty state is
  updated.
- New `test-idea-shaping.sh` (ID-01 to ID-07) and `test-idea-drafts.sh`.

**Out of scope:** The KB-update branch's own skill (delivery-005).

**Waves:**
1. Re-run the spec's stated re-pointing searches for `aid-describe`, `aid-design` and `.aid/design/`, and reconcile the edit list.
2. `idea-drafts.sh`, the writer fields, `kind-catalog.yml`, `design-seed.md` and the README template.
3. `aid-brainstorm` and its references, the `skill-steps.md` deletion rule, the routing rows and the gate's legacy rows. These need wave 2.
4. The retirements and re-pointing, which need the new skill in place.
5. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-idea-shaping.sh` ID-01 to ID-07 pass:
  - `aid-describe`, `aid-design` and `aid-design-*` are absent;
  - no `verb: design` row remains;
  - only `idea-drafts.sh` commits under `.aid/design/`;
  - the brainstorm step table is START, CONVERSE, CHECK, FINISH.
  (AC-17, AC-43)
- [ ] `test-idea-drafts.sh` passes:
  - `keep` commits only the draft's path on the work branch;
  - `delete` of a loose draft makes no commit;
  - exits 2, 3, 4 and 5 change nothing;
  - the script has no `git push`.
  (AC-17, KI-004)
- [ ] The writer accepts `"Idea Draft"` and `"Side Idea"` with `--` or a valid identity, and exits 4 on anything else. Each new legacy row has a passing `--check` fixture. (AC-17, AC-37)
- [ ] Samples `003-01` to `003-05` each pass 3 of 3, and `001-08` passes again. (AC-17, AC-28, AC-43)
- [ ] G0 passes.

### delivery-005: The four KB skills on one KB state file (Feature 004, first part)
- **What it delivers:** The KB is built, queried, updated and shown through `/aid-kb-build`, `/aid-kb-query`, `/aid-kb-update` and `/aid-kb-show`, run by the agent's own judgment; `kb.html` is rendered by a script, the same bytes for the same KB, at every build and update; KB state lives in `.aid/knowledge/STATE.yml`; summarize and housekeep retire.
- **Features:** feature-004-kb-management (KB skills, renderer and state file)
- **Depends on:** delivery-004
- **Priority:** Must

**Objective:** Move the KB onto its four skills and its new state file in one step.

- The new skills read and write only `.aid/knowledge/STATE.yml`.
- Every skill writing today's `STATE.md` (discover, update-kb, housekeep, summarize, ask) is replaced
  in this same delivery.
- The KB step of format 6 converts existing projects, this repository among them, at this delivery's
  dogfood resync.

Q115 placed the state file, format 6 and the dashboard in the second part. They are brought into this
part because the skills cannot run without them (Notes).

**Scope:**
- **Skill moves and the new skill:** `aid-discover` becomes `aid-kb-build`, `aid-update-kb` becomes
  `aid-kb-update`, `aid-ask` becomes `aid-kb-query`, and `aid-kb-show` is new. Their step tables,
  references and descriptions follow the spec. `aid-kb-update` runs in the modes `change`, `sweep` and
  `refresh` on existing documents. (AC-15)
- **The view and commits:** new `render-kb-view.sh` and `kb-commit.sh` (every mode but
  `--new-project`). `build-kb-index.sh` loses its timestamps. (AC-15)
- **The state file:**
  - new `kb-state-template.yml` and the writer's `--kb` modes, plus `--kb-update-log` and
    `kb_updates`;
  - the KB build record and the two KB approval rows in `skill-steps.md`;
  - the "Where" bullet in `question-protocol.md`.
  (AC-15)
- **Retired:**
  - `aid-summarize` and `aid-housekeep`;
  - `summarize/`, the housekeep scripts except `cleanup-classify.sh`, `discover-preflight.sh`;
  - the dropped `knowledge-summary/` files;
  - the root `package.json` and the workflow steps that ran the view's Playwright check.
  NM-03's `aid-housekeep` exemption goes. (AC-15)
- **Format 6:** every carrier reads 6; STEP 0 accepts `STATE.yml`; the KB step converts `STATE.md`,
  in bash and PowerShell. This repository's KB is converted and its `kb.html` re-rendered. (AC-25)
- **Dashboard:** both readers read `STATE.yml`, with a `legacy-kb-state` block for `STATE.md`. They
  use the new KB status waterfall, including `Growing`, and the KB card. `knowledge.source` and
  `knowledge.last_update` are no longer read; `complexity-score.sh` stops reading KB state.
- **Orchestration:**
  - `aid-orchestrate` offers to resume a build and routes open KB questions;
  - the knowledge-update row of `size-and-route.md` names `/aid-kb-update`, and it offers the build first when there is no KB;
  - `feedback-routing.md`;
  - the KB-update branch of brainstorm's FINISH;
  - the `rules.md` tracking and connectors lines.
- **Re-pointing** applies to every retired or moved name of this part.
- **Suites:** `test-kb-skills.sh` group K1 (KB-01 and KB-02 for this part's names, KB-03, KB-04,
  KB-05, KB-06 for build resume and knowledge-update routing, KB-08); `test-render-kb-view.sh`;
  `test-kb-commit.sh`; `test-kb-state-migration.sh` for the KB step.

**Out of scope:** Delivery-006 adds:

- KB documents created by `/aid-kb-update`;
- the 14 KB `create`/`update` skills and `design-lifecycle.md` retired;
- the roadmap and backlog templates;
- the new-project skeleton;
- the drift check at work start, with its baselines;
- the parent branch (Q60).

**Waves:**
1. Re-run the spec's stated re-pointing searches for the retired names, the moved references and `.aid/knowledge/STATE.md`, and reconcile the edit list.
2. `kb-state-template.yml`, the writer's `--kb` modes, `kb-commit.sh`, `render-kb-view.sh` and `build-kb-index.sh`.
3. The four skills, the `skill-steps.md` and `question-protocol.md` edits, and the orchestration and brainstorm edits. These need wave 2's writer and scripts.
4. The format-6 KB step (bash and PowerShell, which needs the template) and both dashboard readers (which need the file shape). Then the retirements and re-pointing.
5. Suites, the delivery's samples, then the dogfood resync. The resync converts this repository's KB; then `kb.html` is rendered.

**Gate Criteria:**
- [ ] `test-kb-skills.sh` group K1 passes:
  - the four KB skills exist;
  - `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`, `aid-housekeep`, `summarize/` and
    `discovery-state-template.md` are absent and named nowhere outside the exemptions;
  - `aid-kb-show` and `aid-kb-query` have no `Write` or `Edit`;
  - no kept file names `.aid/knowledge/STATE.md`.
  (AC-15)
- [ ] `test-render-kb-view.sh` passes:
  - two renders give identical bytes;
  - no `src` or `href` starts with a scheme;
  - `--check` exits 0, 1 and 3 and writes nothing.
  This repository's `.aid/knowledge/kb.html` passes `render-kb-view.sh --check` with exit 0. (AC-15)
- [ ] `test-kb-state-migration.sh` passes for the KB step, with bash and PowerShell byte-identical and a second run changing nothing. This repository has `.aid/knowledge/STATE.yml` and no `STATE.md`. (AC-25)
- [ ] Dashboard fixtures for each KB status, a `Growing` skeleton and a legacy `STATE.md` pass in both readers, including the parity tests. (AC-15)
- [ ] Samples `004-01`, `004-02`, `004-03`, `004-04` and `004-07` each pass 3 of 3, and `001-05` and `001-15` pass again. (AC-15, AC-28)
- [ ] G0 passes.

**Notes:**
- Adjusted from Q115. The KB state file, the format-6 KB step and the dashboard's KB reads move here
  from the second part, for three reasons:
  - The four skills write every state change through `--kb`. For the build the spec says
    "every state write goes through `--kb`", and the same holds for the update and query skills.
  - Today's `STATE.md` is written by the very skills this part replaces.
  - Under the spec's "No KB: one rule", a KB exists only when `STATE.yml` says `Approved` or
    `Growing`. Without its conversion, this repository would have no KB for the new skills from this
    delivery's resync onward.
  The second part keeps a coherent, testable unit: the KB grows and stays current.

### delivery-006: The KB grows and stays current (Feature 004, second part)
- **What it delivers:** `/aid-kb-update` creates and registers new KB documents, so the KB `create`/`update` skills retire; roadmap and backlog are ordinary documents ("work on the next backlog item" works); a new project starts with a committed `Growing` KB skeleton and records facts as they are decided or built; at work start the agent offers to fix documents that drifted from the code; new works branch from the main folder's current branch.
- **Features:** feature-004-kb-management (growth, roadmap and backlog, drift, parent branch)
- **Depends on:** delivery-005
- **Priority:** Must

**Objective:** Finish Feature 004 with everything that makes the KB grow and stay current, on top of
the skills and state file delivery-005 installed. It stands alone: after delivery-005 a new document
can still be written by today's KB `create` skills, and this delivery replaces them.

**Scope:**
- `aid-kb-update` gains `references/new-document.md`. The 14 KB `create`/`update` skills
  (architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp) and `design-lifecycle.md`
  retire, along with their shortcut-catalog rows and their rows on the shared exempt list. (AC-39)
- New `knowledge-base/roadmap.md`, with its `## MVP` section, and `knowledge-base/backlog.md`.
  `check-intent.md` reads `backlog.md` and records it as a work source. (AC-39)
- The new-project step in the gate's § 3a:
  - `type: greenfield`;
  - `--kb --field Status --value Growing`;
  - `kb-commit.sh --new-project`;
  - the new-project row of `size-and-route.md`;
  - the `Growing` case of `aid-kb-show`.
  (AC-18)
- The drift check in `start-or-resume.md` (Q57). Format 6 gains the step that back-fills
  `approved_at_commit:` baselines. (AC-15)
- Q60:
  - `worktree-lifecycle.sh` `create` uses the main folder's checked-out branch;
  - `--create --parent-branch`;
  - `pipeline.parent_branch`;
  - format 6 fills it for existing works;
  - `aid-kb-update` START's removed-KB safety net.
- `test-kb-skills.sh` group K2 (KB-01 and KB-02 for this part's names, KB-06 for drift, new project
  and backlog, KB-07). `test-worktree-lifecycle.sh` gets its Q60 cases.

**Out of scope:** The KB calls made by Specification and Building (deliveries 007 and 009).

**Waves:**
1. Re-run the spec's stated searches for the KB `create`/`update` skills and `design-lifecycle.md`, and reconcile the edit list.
2. Two independent groups: `worktree-lifecycle.sh` with `--create --parent-branch` and the work-state key; and `kb-commit.sh --new-project`, `new-document.md` and the two document templates.
3. The new-project step in the gate, the drift check, the `check-intent.md` backlog read, and the format-6 baselines and parent-branch steps. These need wave 2.
4. The retirements and re-pointing.
5. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-kb-skills.sh` group K2 passes, and group K1 still passes:
  - no KB `create`/`update` skill and no `design-lifecycle.md` exists;
  - `knowledge-base/roadmap.md` has `## MVP`;
  - the gate's § 3a runs the new-project step before creating the worktree;
  - `start-or-resume.md` names `kb-freshness-check.sh`.
  (AC-18, AC-39)
- [ ] `test-worktree-lifecycle.sh` passes. With the main folder on a branch other than `master`, `create` branches from that branch; with no branch checked out, it exits 2. `test-kb-commit.sh --new-project` commits only `.aid/settings.yml` and the KB skeleton. (AC-18)
- [ ] `test-kb-state-migration.sh` passes for baselines and `pipeline.parent_branch`, in the main folder and in a registered worktree, with a re-run changing nothing and bash and PowerShell byte-identical. (AC-25)
- [ ] Samples `004-05`, `004-06`, `004-08`, `004-09` and `003-11` each pass 3 of 3. `skill-steps-exempt.tsv` holds no row whose owner is Feature 004. (AC-15, AC-39)
- [ ] G0 passes.

### delivery-007: One requirements document, business and technical
- **What it delivers:** One `/aid-specify` writes the whole work's `REQUIREMENTS.md` with a business part and a technical part, splits into features only when the work delivers several capabilities, checks the effort level once per work, revises approved requirements on request, and records approved project decisions in the KB through one call.
- **Features:** feature-005-specification
- **Depends on:** delivery-006
- **Priority:** Must

**Objective:** Deliver the Specification phase: today's define and specify merged, on the new step
rules and the KB call.

**Scope:**
- `aid-specify` is rewritten with the steps START, REQUIREMENTS, FEATURES, DESIGN, CHECK, APPROVE,
  FINISH and REVISE, and nine references. `aid-define` and `templates/specs/` are deleted. (AC-16)
- The two-part `requirements-template.md` and the bare `requirements.md` scaffold. (AC-16, AC-44)
- `effort-check.md`, with one row per tool. (AC-12)
- Writer: `--review` on the work file and `"Effort Check"`. The template drops `interview`,
  `features` and `review_history`. (AC-44)
- `slice-requirements.sh` reads the unsplit shape.
- `skill-steps.md`: the business-part row and the KB call on confirmation.
- The Guard 2 site moves to `aid-specify` CHECK. The ledger schema, the legacy rows and the
  `aid-architect` agent are updated.
- New `test-specify.sh` (SP-01 to SP-08). The shared exempt list gains the `shortcut-engine.md` SP-08
  row.

**Out of scope:** `aid-plan` reading the unsplit shape (delivery-008). This leaves the gap the spec
accepts in Feature 005's § 2: "No release carries that gap, since every feature ships in v4.0.0".

**Waves:**
1. Re-run the spec's stated `aid-define` re-pointing sites and reconcile the edit list.
2. The templates, the writer's `--review` and `"Effort Check"`, and `slice-requirements.sh`.
3. `aid-specify` and its references, the `skill-steps.md` rows, `reviewer-dispatch.md`, the ledger schema and the legacy rows. These need wave 2.
4. Retire `aid-define`, re-point, and update the KB.
5. Suites, the delivery's samples and the deferred samples that now run, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-specify.sh` SP-01 to SP-08 pass:
  - `aid-define` and `templates/specs/` are absent;
  - the template has `## 1.` to `## 10.`, both forms of § 11, and a `**Serves:**` line;
  - the step table is complete;
  - `check.md` names fix, accept and keep reviewing, and the `Accepted` status.
  (AC-16, AC-44)
- [ ] `effort-check.md` has a row for each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI, and states the "cannot be read" path. No file under `aid-kb-build/` cites it. (AC-12)
- [ ] `test-slice-requirements.sh` prints `## 11. Technical Specification` for an unsplit document, and its output for a split document is unchanged. The writer appends a work `reviews` entry, and exits 4 on a bad grade. (AC-44)
- [ ] Samples `005-01` to `005-10` each pass 3 of 3, and so do `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09` and `004-10`. `001-08` and `001-09` pass again. (AC-9, AC-10, AC-12, AC-16, AC-18, AC-44)
- [ ] G0 passes.

### delivery-008: The plan as a generated checklist on one state file
- **What it delivers:** One `/aid-plan` breaks requirements into atomic tasks grouped into deliveries, keeps `PLAN.md` as a checklist generated from the task files and the work's single `STATE.yml`, and revises the plan on request; no delivery or task state file remains; existing works migrate to the single layout, `ticket_ref` becoming `sources:`.
- **Features:** feature-006-planning
- **Depends on:** delivery-007
- **Priority:** Must

**Objective:** Deliver the Planning phase and the single work layout, plan and detail merged. This is
also the delivery at which this work migrates its own state to the single layout (Q111; see
Toolchain and Branching).

**Scope:**
- `aid-plan` is rewritten with the steps START, BREAKDOWN, CHECK, APPROVE, FINISH and REVISE.
  `aid-detail`, the delivery and task state templates and `delivery-plans/` are deleted. (AC-19)
- New `plan-template.md`; `task-detail-template.md` is rewritten. `derive-waves.sh --plan`. The
  writer gets the single layout, `--plan-sync`, the re-render and exit 11, plus the fork. (AC-19)
- The gate's legacy block is removed and replaced by the old-layout check. The allocation points pass
  `--depth`. `shortcut-engine.md` PLAN and DETAIL use `--plan-sync`. `aid-deploy` reads
  `deliveries`.
- The format-6 work-state step in `bin/aid` and `bin/aid.ps1`, byte-identical. (AC-19)
- The dashboard reads one layout and diagnoses an old one. It shows the depth badge and the path line.
  (AC-41)
- New `test-plan.sh` (PL-01 to PL-07) and `test-work-state-migration.sh`. The shared exempt list gains
  the `aid-execute` PL-04 row and the PL-06 mark.

**Out of scope:** `aid-execute` reading the single layout (delivery-009, Q114).

**Waves:**
1. Re-run the spec's stated searches for `aid-detail`, the deleted templates, `deliveries/delivery-NNN/` paths and per-task `STATE.yml`, and reconcile the edit list.
2. The templates, the writer's single layout and `--plan-sync`, `derive-waves.sh --plan` and `slice-requirements.sh`.
3. Two independent groups that both need wave 2: `aid-plan` and its references with the gate, allocation, engine, `aid-deploy` and `aid-architect` edits; and the dashboard's one-layout reading.
4. The format-6 work-state step (bash, then its PowerShell twin, with fixtures written first). It needs the final single layout.
5. Retire `aid-detail` and re-point. Then the suites and the delivery's samples. Then the dogfood resync, whose `aid update` migrates this work's own state.

**Gate Criteria:**
- [ ] `test-plan.sh` PL-01 to PL-07 pass:
  - `aid-detail`, both state templates and `delivery-plans/` are absent;
  - no kept file names `deliveries/delivery-` or `pipeline.path` outside the markers and exemptions;
  - the gate has no `legacy-phase-map` block and names `aid update`.
  (AC-19)
- [ ] `test-derive-waves.sh` passes:
  - `--plan` is byte-identical on a second run;
  - `--check` exits 0, 1, 2 and 3;
  - a cycle exits 2 with the plan untouched;
  - a malformed graph written through the writer exits 11 with both files unchanged.
  (AC-19)
- [ ] `test-work-state-migration.sh` passes on nested, old lite and single-layout fixtures, with bash and PowerShell byte-identical and a second run changing nothing. After the resync, this work's own state shows the migration on disk:
  - `.aid/works/work-003-full-aid-restructure/` has no `deliveries/delivery-*/STATE.yml`;
  - every task has `tasks/task-NNN/DETAIL.md` and a `tasks_lifecycle` entry;
  - `derive-waves.sh --plan --check` exits 0 on its `PLAN.md`.
  (AC-19)
- [ ] Samples `006-01` to `006-05`, `006-07`, `006-08` and `005-13` each pass 3 of 3. `005-07` runs through Planning, and `001-07` passes again. (AC-19, AC-28)
- [ ] G0 passes.

**Notes:**
- Today's `/aid-execute` builds this delivery's tasks except the last. The last task is the dogfood
  resync, which migrates this work. That task and the delivery gate are run by the main conversation
  directly, because after the migration today's `/aid-execute` finds none of its per-task state files.
  See Toolchain and Branching.

### delivery-009: Building tested, verified and simplified, one task at a time
- **What it delivers:** One `/aid-execute` builds the whole plan one task at a time on the work's one branch -- build, test, verify, simplify once, re-verify only when the simplification changed something -- with a full-suite baseline, the confirmation before building, and approval stops only at milestones and real blockers.
- **Features:** feature-007-building
- **Depends on:** delivery-008
- **Priority:** Must

**Objective:** Deliver the Building phase on the single layout. Per Q114, this delivery is built by
the main conversation directly, task by task, with no `/aid-execute` run (see Toolchain and
Branching).

**Scope:**
- **The skill:** `aid-execute` is rewritten with the steps START, BUILD, TEST, VERIFY, SIMPLIFY,
  REVERIFY, NEXT, DELIVERY, FINAL, MILESTONE and FINISH. Thirteen references are created, seven are
  deleted, and `task-type-rules.md` is edited. (AC-26, AC-32, AC-33)
- **Scripts:**
  - new `simplify-guard.sh`;
  - `derive-waves.sh --from-tasks --delivery`;
  - `complexity-score.sh` and `compute-block-radius.sh` read that output;
  - `delivery-issues.md` is deleted.
  (AC-33)
- **The writer:**
  - the building fields, `--full-suite`, `--feedback-add` and `--feedback`;
  - the derived delivery state, identical in the dashboard fork;
  - the retired modes refused.
  (AC-32, AC-33)
- **Approvals:** `skill-steps.md` gains the corrections row and the Building rule. `shortcut-engine.md`
  APPROVAL-HALT records the confirmation. `aid-plan` `revise.md` handles a task that is given up.
  (AC-10, AC-32)
- **One worktree, one branch:** no per-delivery branch, no per-task worktree, no "merge to main". The
  consumer lists in `worktree-lifecycle.md` and `downstream-worktree-entry.md` are updated.
  NM-04's exemption goes. (AC-34)
- **Format 6:** the building part, in bash and PowerShell. The dashboard reads the building fields.
  (AC-41)
- **Suites:** new `test-execute.sh` (EX-01 to EX-08) and `test-simplify-guard.sh`. The `aid-execute`
  PL-04 row leaves the shared exempt list.

**Out of scope:** The pull-request calls made at milestones, which need delivery-010. Until then, the
close runs through `/aid-orchestrate`.

**Waves:**
1. Re-run the spec's stated search (`state-execute.md|...|delivery-issues.md` over `tests` and `dashboard`) and the re-pointing sites, and reconcile the edit list.
2. The writer's building part with its fork and parity case, `simplify-guard.sh`, `derive-waves.sh --delivery`, and the work-state template.
3. `aid-execute` and its references, `complexity-score.sh` and `compute-block-radius.sh`, `skill-steps.md`, the shortcut engine's APPROVAL-HALT, `aid-plan` `revise.md` and `aid-developer`. These need wave 2.
4. The format-6 building step (bash and PowerShell) and the dashboard's building fields, which need the template. Then the re-pointing.
5. Suites, the delivery's samples and the deferred samples that now run. Then the dogfood resync, which installs the new `/aid-execute` and migrates this work's building fields.

**Gate Criteria:**
- [ ] `test-execute.sh` EX-01 to EX-08 pass:
  - the step table is complete;
  - no file under `aid-execute/` or `scripts/execute/` creates a branch or worktree, or names
    `run_in_background`, `max_parallel_tasks` or "merge to main";
  - `next.md` routes by states plus commits.
  (AC-26, AC-32, AC-34)
- [ ] `test-simplify-guard.sh` passes with git and without git. `test-writeback-state.sh` derives each of the seven delivery states, identical in the canonical writer and the dashboard fork. `test-never-merges.sh` passes with NM-04's exemption gone. (AC-33, AC-34)
- [ ] Samples `007-01` to `007-12` each pass 3 of 3. So do `002-07`, `002-08`, `002-09`, `002-13`, `003-07`, `003-10`, `004-11`, `004-12`, `005-11`, `005-12` and `006-06`. `001-07`, `001-16` and `006-01` pass again. (AC-10, AC-26, AC-32, AC-33, AC-34)
- [ ] Every task of this delivery has a terminal state in this work's `tasks_lifecycle`. Its history shows `In Progress`, then `In Review`, then `Done` or `Failed`, each written by the writer. A reviewer ledger at or above `minimum_grade` exists for every `Done` task. (Q114, tracking discipline)
- [ ] G0 passes.

### delivery-010: Pull requests to a mergeable state, never merged
- **What it delivers:** `/aid-monitor-pipeline` creates or updates the work's one pull request only on the user's yes, pushes only approved commits, corrects reported bugs and pipeline failures as ordinary builds, brings suggestions to the user, brings in the parent branch only to resolve a conflict with that merge approved first, and after a person merges closes the work locally without deleting any remote branch.
- **Features:** feature-008-cicd-integration-monitoring
- **Depends on:** delivery-009
- **Priority:** Must

**Objective:** Deliver the CI phase and the real close of every work. This replaces the interim close
that `/aid-orchestrate` has run since delivery-001.

**Scope:**
- **The skill:** new `aid-monitor-pipeline` with the steps START, COLLECT, PUSH, PARENT, REVIEW, REACT,
  WATCH and CLOSE, and eleven references, including `connect.md` and `hosts.md`. (AC-13, AC-27, AC-42)
- **Scripts:** new `pipeline/push-approved.sh`, `merge-parent.sh` and `close-work.sh`.
  `cleanup-classify.sh` is moved and reads YAML. (AC-11, AC-35, AC-36)
- **State and settings:**
  - writer `--pull-request` and the duplicate-`ref` rule, plus the fork;
  - the `pull_request` key;
  - `work_folders: push` in the settings;
  - the conflict-merge row in `skill-steps.md`;
  - row 1 of the gate's § 3b treats merged work folders as finished.
  (AC-35, AC-36)
- **Finishing:** `aid-research`, `aid-review`, `aid-report` and `aid-deploy` pass to the close. The
  interim close goes from `aid-orchestrate`, `aid-kb-update` and `aid-execute`. The publish seam is
  added to `consumption-protocol.md`. Every `git push` outside `push-approved.sh` goes. (AC-14, AC-36)
- **Other edits:** `delete-pipeline.sh` loses `--force`. The dashboard gets the CI card.
- **Suites:** new `test-monitor-pipeline.sh` (MP-01 to MP-05), `test-push-approved.sh`,
  `test-merge-parent.sh`, `test-close-work.sh`, and the `gh`/`glab` stand-ins. NM-01 is narrowed,
  NM-03 loses its exemptions, and NM-05 and NM-06 are added.

**Out of scope:** The live-host run (`008-15`), which is part of the integration run in delivery-014.

**Waves:**
1. Re-run the spec's stated re-pointing sites (`housekeep/cleanup-classify.sh`, `origin/master`, the interim close, every `git push`) and reconcile the edit list.
2. The three new scripts and the moved `cleanup-classify.sh`, the writer's `--pull-request`, the template, settings and the stand-ins.
3. `aid-monitor-pipeline` and its references, the gate row, `skill-steps.md`, the finishing skills, `aid-operator`, `consumption-protocol.md` and the `milestone.md` and `finish.md` edits. These need wave 2.
4. `delete-pipeline.sh`, the dashboard CI card and the re-pointing.
5. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-monitor-pipeline.sh` MP-01 to MP-05 pass. `test-never-merges.sh` passes:
  - NM-01 allows a `git merge` only in `merge-parent.sh`;
  - NM-03 has no exemption;
  - NM-05 allows an executed `git push` only in `push-approved.sh`;
  - NM-06 finds no `git worktree remove --force`.
  (AC-11, AC-34)
- [ ] `test-push-approved.sh` passes against a local bare remote:
  - only the approved commit and the commits verified after it are pushed;
  - exit 5 for a committed `.aid/.temp/` file, another work's folder, or an added idea draft;
  - exit 7 when the work branch is `main`;
  - nothing is ever forced.
  (AC-35, AC-42)
- [ ] `test-merge-parent.sh` and `test-close-work.sh` pass. `merged` deletes the local branch and the worktree and keeps the remote branch. A branch with an unpushed commit is kept. Each `work_folders` setting behaves as specified. (AC-11, AC-36)
- [ ] Samples `008-01` to `008-14` and `008-16` to `008-18` each pass 3 of 3, and `002-10`, `007-13` and `001-16` pass. (AC-13, AC-27, AC-35, AC-36, AC-42)
- [ ] G0 passes.

### delivery-011: Action skills and one catalog of kinds (Feature 009a)
- **What it delivers:** Seven action skills -- `/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`, `/aid-test`, `/aid-prototype` -- each starting from one shared START, reading a kind typed or said in plain words from one merged catalog that also holds the project's own `.aid/kinds/`; `/aid-test` and `/aid-prototype` run as investigations that land nothing in the project.
- **Features:** feature-009-one-skill-per-need (part a: action skills and the kind catalog)
- **Depends on:** delivery-010
- **Priority:** Must

**Objective:** Add the action layer and the catalog every phase skill reads. Nothing is retired here
yet, so the old wrapper skills keep working beside the new ones until delivery-012 removes them.

**Scope:**
- **Generated skills to hand-authored:** `aid-create`, `aid-update`, `aid-fix` and `aid-refactor`
  become hand-authored, and their four rows leave `shortcut-catalog.yml` (Notes).
- **The three rewritten skills:** `aid-document`, `aid-test` and `aid-prototype` are rewritten, with
  their references. (AC-30)
- **START and the catalog:**
  - new `action-start.md`;
  - `kind-catalog.yml` v2 with `actions`, the new kind fields and the new kinds;
  - `check-intent.md` § The merged catalog, with `.aid/kinds/`, the precedence and the skip rule.
  (AC-30)
- **Recording the kind:** writer `--kind` and the reading `investigation`; the gate forwards `--kind`;
  `intent.kind` is added to the template.
- **Catalog readers:**
  - `aid-specify` (`start.md`, `requirements.md`, `design.md`, `check.md`);
  - `aid-plan` `breakdown.md`;
  - `aid-execute` (`test.md`, `task-type-rules.md`, the brief);
  - `aid-brainstorm` `start.md`;
  - the kind hook in `aid-review`, `aid-research` and `aid-report`.
  (AC-30)
- **Findings and close:** `aid-fix` `references/findings.md`. The close moves the test ledger and the
  prototype folder to the main folder. (AC-14, AC-36)
- **Skill guide and suites:**
  - the skill guide gains one line per action skill (the `<kind>` lines stay until delivery-012);
  - `test-shared-prune.sh` and `test-shared-remove.sh` get their `.aid/kinds/` cases;
  - `test-actions.sh` group A: AS-03 without its `domain` and reserved-field clauses, AS-04 without
    its `aid-deploy`/`aid-monitor` clause, AS-05, AS-06 for the findings half, AS-09.

**Out of scope:**
- The ticket kind and the retirements (delivery-012).
- The rename and the domain field (delivery-013).

**Waves:**
1. Re-run the spec's stated searches over the files this part rewrites (the second search in Feature 009 § 8), and reconcile the edit list.
2. `kind-catalog.yml` v2, `check-intent.md` § The merged catalog, writer `--kind` and `investigation`, the gate's `--kind` and the template.
3. `action-start.md` and the seven action skills, which need wave 2.
4. The catalog readers in the phase and supporting skills, the close moves, the skill guide, and removing the four rows from the shortcut catalog. These need the skills of wave 3.
5. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-actions.sh` group A passes:
  - every action names an existing skill and an accepted reading;
  - every kind has a unique `kind`, an `about` and a `taken_by` naming existing skills;
  - no KB kind is taken by `create` or `update`;
  - every action skill cites `action-start.md`, the catalog, `skill-steps.md` and
    `question-protocol.md`;
  - every catalog reader cites its field.
  (AC-20, AC-30)
- [ ] `build-shortcut-skills.py --check` passes with the four rows removed. None of `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` carries the `GENERATED` marker. (AC-30)
- [ ] `test-writeback-state.sh` passes for `--kind` and `--reading investigation`. `test-shared-prune.sh` and `test-shared-remove.sh` keep a file under `.aid/kinds/` unchanged. (AC-30)
- [ ] Samples `009-03`, `009-04`, `009-05`, `009-13`, `009-17` and `009-19` each pass 3 of 3. The typed runs of `009-01`, `009-02`, `009-06`, `009-07`, `009-08`, `009-09` and `009-10` each pass 3 of 3. (AC-28, AC-30)
- [ ] G0 passes.

**Notes:**
- Adjusted from Q113: two changes keep this part standalone.
  - `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` are generated today from
    `shortcut-catalog.yml` rows. Rewriting them by hand means removing those four rows, which changes
    the counts in the suites that count catalog rows and doorways (`test-deploy-monitor-repurpose.sh`
    DMR30-DMR35, the site's skill-count tests, `test-doc-counts.sh`). Those counts are re-recorded
    here, the same mechanical edit every earlier delivery makes to `test-doc-counts.sh`. The suites
    themselves retire in delivery-012.
  - Plain-word runs of the "typed and plain" samples are deferred to delivery-012. Until the wrappers
    retire, a plain request such as "create an API endpoint for orders" fits both `/aid-create` and
    `/aid-create-api`, so the plain form cannot pass 3 of 3 reliably.

### delivery-012: One obvious skill for each need (Feature 009b)
- **What it delivers:** Every action-and-kind wrapper skill, the shortcut engine, its catalog and scaffolding and the impediment file retire; tickets become a kind of `/aid-create` and `/aid-update`; free-form text after `/aid-deploy` or `/aid-monitor` is a plain request; the site generator models the new skill set; old works of retired skills migrate to the action skills with their kind.
- **Features:** feature-009-one-skill-per-need (part b: retirements, engine, site generator)
- **Depends on:** delivery-011
- **Priority:** Must

**Objective:** Remove everything the action layer replaces, so each need has exactly one skill. This
delivery also empties the lists that wait on Feature 009.

**Scope:**
- **Retired skills:** every remaining `aid-create-*`, `aid-update-*`, `aid-document-*` and
  `aid-test-*`, plus `aid-prototype-ui`, `aid-remove`, `aid-deprecate`, `aid-migrate`,
  `aid-experiment`, `aid-create-diagram`, `aid-create-document`, `aid-update-document`,
  `aid-create-ticket` and `aid-update-ticket`. (AC-20, AC-31)
- **Retired templates and builder:** `shortcut-engine.md`, `shortcut-catalog.yml`,
  `shortcut-scaffolding/`, `feedback-artifacts/` and `build-shortcut-skills.py`.
  `generate-profile/SKILL.md` counts skills from `canonical/skills/`. (AC-20)
- **Tickets:** the TICKET step of `/aid-create` and `/aid-update`, with
  `connectors/ticket-create.md` and `ticket-update.md`. (AC-30)
- **Free-form text:** `aid-deploy` and `aid-monitor` Step 0 hand free-form text to the intake.
- **No impediment file:** `aid-research`, `aid-review` and `aid-report` use the per-row choice.
- **Format 6:** the doorway rows (`intent.kind`, the record fill, the type), with
  `legacy-skill-names` markers in `bin/aid` and `bin/aid.ps1`. The dashboard maps sit inside markers.
  (AC-31, AC-37)
- **Site:** the generator rewrite, the retired flows and pages deleted, the pages regenerated. (AC-31)
- **Skill guide:** the `<kind>` lines go, and SG-02 has no expansion. (AC-31)
- **Suites:** the retired and rewritten suites from Feature 009 § 8.
- **Lists:**
  - the shared exempt list loses its `shortcut-engine.md` row and ends empty;
  - the Feature 009 `skill:` rows leave `deferred.tsv`.
- **Re-pointing** applies to every retired name except `aid-config`.
- `test-actions.sh` group B: AS-01 without its `aid-configure` clause, AS-02 and AS-07 without
  `aid-config`, AS-04's `aid-deploy`/`aid-monitor` clause, AS-06's ticket half, AS-08.

**Out of scope:** The `aid-config` rename (delivery-013).

**Waves:**
1. Re-run the spec's stated suite searches (both `git grep` commands of Feature 009 § 8) and the re-pointing sites, and reconcile the edit list.
2. The ticket procedures and the TICKET step, the `aid-deploy` and `aid-monitor` free-form edit, and the per-row choice in research, review and report. These replace what the engine, the ticket skills and `IMPEDIMENT.md` did, so they come before the deletions.
3. Delete the wrapper skills, the engine, the shortcut catalog, the scaffolding, `feedback-artifacts/` and the builder. Then the format-6 doorway rows and the dashboard markers.
4. The site generator rewrite and the retired, rewritten and re-pointed suites. These need the deletions.
5. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-actions.sh` group B passes, and group A still passes:
  - no folder matches `aid-(create|update|design|document|test|prototype)-`;
  - no engine, shortcut catalog, scaffolding, `IMPEDIMENT.md` or builder exists;
  - no retired name appears outside the exemptions and `legacy-skill-names` markers;
  - the skill guide has no `<kind>` placeholder.
  (AC-20, AC-31)
- [ ] The site `npm test` passes on the rewritten generator. `site/scripts/gen-skills.mjs` regenerates the pages with no retired skill. (AC-31)
- [ ] `test-work-state-migration.sh` maps old doorway works as specified:
  - an `aid-create-api` work at `Specify` reaches `/aid-specify` with `kind: api`;
  - an `aid-test-security` work reaches `/aid-test` with type investigation;
  - every row naming a retired skill sits inside the markers;
  - bash and PowerShell are byte-identical.
  (AC-30, AC-37)
- [ ] The plain-word runs of `009-01`, `009-02`, `009-06`, `009-07`, `009-08`, `009-09` and `009-10` each pass 3 of 3, as do `009-14` and `009-16`. `001-01`, `001-07`, `003-02` and `008-14` pass again. `skill-steps-exempt.tsv` is empty. (AC-28, AC-30)
- [ ] G0 passes.

### delivery-013: `/aid-configure` and room beyond software (Feature 009c)
- **What it delivers:** `/aid-config` becomes `/aid-configure`, so every skill name is a verb; the catalog's kinds carry a `domain` (all `software`) and reserve the fields later works will use; the action layer names no software term; every file that says what AID is says "software first, not software only"; the roadmap records the later "Beyond software" works.
- **Features:** feature-009-one-skill-per-need (part c: the rename and domain readiness)
- **Depends on:** delivery-012
- **Priority:** Must

**Objective:** Finish Feature 009's product changes.

- The rename every earlier feature named `aid-config` for.
- The domain-readiness changes of Q108-Q110 that remain after delivery-011 added `.aid/kinds/`.

**Scope:**
- **The rename:** `aid-config` becomes `aid-configure`. It covers every mention of `aid-config`:
  - the settings rows edited by Features 004 and 008, and `settings.yml`'s "Managed by" line;
  - `bin/aid` and `bin/aid.ps1`, whose "Run" line stays byte-identical across the two;
  - the dashboard comments;
  - sample `002-02`'s `skills:` line.
  (AC-22, AC-31)
- **Catalog fields:** `domain: software` on every shipped kind, and the reserved fields `risk`,
  `limits`, `sign_off` and `release` set on none.
- **Wording:** the action layer is worded with no software term (AS-10).
- **Identity statement:** "software first, not software only" in every file the identity search
  finds, except the files under `docs/` and `site/src/content/docs/`, which the final pass rewrites.
  `decisions.md` records Q108. `roadmap.md` § Later gains "Beyond software" (Q110).
- **Sample:** `009-18-budget-sheet-no-repository`.
- **Lists:** `test-actions.sh` group C: AS-01's `aid-configure` clause, AS-02 and AS-07 for
  `aid-config`, AS-03's `domain` and reserved-field clauses, AS-10. The description exempt list ends
  empty.

**Out of scope:** The user documentation (delivery-014).

**Waves:**
1. Re-run the identity search of Feature 009 § 5 and a search for `aid-config`, and reconcile the edit list.
2. The rename, the catalog's `domain` field, the action-layer wording and the identity statement. These four groups do not depend on each other.
3. Suites, the delivery's samples, then the dogfood resync.

**Gate Criteria:**
- [ ] `test-actions.sh` group C passes, and groups A and B still pass:
  - `aid-configure` exists and `aid-config` does not;
  - `aid-config` is named nowhere outside the exemptions;
  - every shipped kind has `domain: software` and no reserved field;
  - the action layer has none of the AS-10 terms.
  (AC-22, AC-31)
- [ ] Samples `009-15` and `009-18` each pass 3 of 3, and `002-02` passes on `/aid-configure`. (AC-14, AC-22, AC-28, AC-36)
- [ ] Run without the release flag, the identity search of Feature 009 § 5 finds "software first, not software only" in every file outside `docs/` and `site/src/content/docs/`. The description exempt list of `test-skill-guide.sh` is empty. (Q108, NFR-T)
- [ ] G0 passes.

### delivery-014: Final documentation pass and release readiness
- **What it delivers:** The user documentation describes the finished product -- the phases, the skills, the old -> new table -- and every release check passes with all lists empty and the full integration suite green, so the work is ready for the v4.0.0 pull request.
- **Features:** feature-009-one-skill-per-need (final documentation pass, AC-45; Q104)
- **Depends on:** delivery-013
- **Priority:** Must

**Objective:** Run AC-45's one documentation pass. The criterion places it
"After all features are built", so it can only be judged against the finished product. Then run the end-of-work checks that
make the branch releasable.

**Scope:**
- `aid-tech-writer` rewrites `docs/`, `site/src/content/docs/`, `README.md` and `examples/`. The old
  -> new table sits between `legacy-skill-names` markers. Generated pages are regenerated, never
  edited by hand. (AC-45, AC-24)
- `tests/canonical/test-doc-names.sh` (DN-01, DN-02, DN-03) and `tests/canonical/retired-names.txt`.
  (AC-24, AC-45)
- The full integration suite runs: every sample of every feature 3 of 3, plus `008-15` (live GitHub
  and GitLab) and `009-11` and `009-12` (live tracker).

**Out of scope:**
- Tagging and publishing v4.0.0. That is an operational work of its own (FR-7).
- Merging the v4.0.0 pull request, which is a human act (FR-6).

**Waves:**
1. Re-run DN-01 and DN-03 without the release flag to list every hit, and reconcile the documents to rewrite.
2. `retired-names.txt` and `test-doc-names.sh`, then the documentation rewrite and the site regeneration.
3. The release checks under `AID_RELEASE_CHECK=1`, then the full integration suite, then the dogfood resync.

**Gate Criteria:**
- [ ] With `AID_RELEASE_CHECK=1`, DN-01, DN-02 and DN-03 pass:
  - no file under `docs/`, `site/src/content/` or `examples/`, nor `README.md`, names a retired skill
    or an old phase name outside the markers;
  - every name in `retired-names.txt` has a row in `backlog.md` § Next Release.
  (AC-24, AC-45)
- [ ] With `AID_RELEASE_CHECK=1`, DT-02 and both exempt-list release checks pass, with `deferred.tsv` and both exempt lists empty. (NFR-T)
- [ ] The full integration suite passes. Every sample under `tests/conversation/samples/` passes 3 of 3, including `008-15`, `009-11` and `009-12`. (AC-13, AC-27, AC-29, AC-30, AC-36)
- [ ] `site/scripts/gen-skills.mjs` regenerates the site with no diff after the pass, and the Astro build succeeds. (AC-31, AC-45)
- [ ] G0 passes.

## Delivery Order

The deliveries form one chain, each depending on the one before:

```text
delivery-001 -> delivery-002 -> delivery-003 -> delivery-004 -> delivery-005 -> delivery-006 -> delivery-007
  -> delivery-008 -> delivery-009 -> delivery-010 -> delivery-011 -> delivery-012 -> delivery-013 -> delivery-014
```

The order follows the feature specs. Each feature needs every earlier one, and Feature 008 needs
Features 004 and 007. The splits of Features 002, 004 and 009 keep that order inside each feature.

## Toolchain and Branching

This repository installs AID into itself.

- `run_generator.py` ends by resyncing the dogfood install through `sync_dogfood.py`, which runs
  `aid update --from-bundle` on this repository.
- `tests/canonical/test-dogfood-byte-identity.sh` requires the installed trees to equal
  `canonical/`.

So every delivery that passes G0 replaces the skills and scripts that build this work. From
delivery-005 on, it also runs format-6 migrations over this work's own state. These rules keep the
toolchain stable while each delivery is built.

**Planning (Q111).** Once this plan is approved, today's `/aid-detail` writes the task files of all 14
deliveries up front. Its FIRST-RUN covers every delivery and its task numbering is global, so the
later migration of this work meets no duplicate task id.

- Every delivery's first wave re-runs its spec's stated searches.
- From delivery-009 on, any change to a later delivery's tasks goes through the new `/aid-plan`
  REVISE.

**The resync is the last task of every delivery (Q111).** A delivery is built on the toolchain it
started with. Tasks before the resync check their own suites, not `test-dogfood-byte-identity.sh`.
After the resync task:

- the delivery's gate runs from the freshly installed skills, in a new session, so that no skill text
  read before the resync is acted on;
- G0's full suite runs then.

**Branching (Q112).** Every delivery is built directly on `work-003` and advances it. Today's
`/aid-execute` Check 5 (a branch `aid/{work}-delivery-NNN` per delivery) and its "merge to main"
ending are not used for this work. Nothing reaches `master` before the v4.0.0 pull request, which a
person merges. While today's `/aid-execute` builds, its pool cannot work on the same branch: each
parallel task checks out the delivery branch in a worktree of its own, and git refuses to check out
`work-003` a second time. So those deliveries run serially, with `execution.max_parallel_tasks: 1`.

**Which toolchain builds each delivery:**

| Delivery | Builder | What changes at its end |
|---|---|---|
| 001-007 | Today's `/aid-execute`, as installed by the previous delivery's resync. | Each resync installs that delivery's skills. Delivery-002's makes the writer refuse old phase names (today's skills are converted in the same delivery). Delivery-005's converts this repository's KB state file. |
| 008 | Today's `/aid-execute` for every task but the last. The last task (the resync) and the delivery gate are run by the main conversation directly. | The resync's `aid update` migrates this work to the single layout. Today's `/aid-detail` and `/aid-plan` are gone, and today's `/aid-execute` can no longer read this work. |
| 009 | The main conversation directly, task by task, with no `/aid-execute` run (Q114). | The resync installs the new `/aid-execute` and the building part of format 6. |
| 010-014 | The new `/aid-execute`, resumed on this work. | Each resync installs that delivery's skills, at a delivery milestone. |

**How delivery-009 is built (Q114).** The main conversation runs each task in wave order, with
`AID_STATE_FILE` exported for this work. Each task goes through these steps:

1. Write `In Progress` with `writeback-state.sh --task-id NNN --field State`.
2. Dispatch the executor for the task's type (`aid-developer`, or `aid-tech-writer` for DOCUMENT), in
   a clean context, tiered by `agent-dispatch-tiering.md`, with the task file and its requirements
   slice.
3. Run the task's tests.
4. Write `In Review`.
5. Dispatch `aid-reviewer` in a clean context, at a tier no lower than the executor's. It writes a
   7-column ledger, and the ledger is graded with `grade.sh` against `minimum_grade`.
6. Fix rounds. The same failure after three rounds is raised to the maintainer.
7. Write `Done` once the tests pass and the grade meets the bar, or `Failed` otherwise.

Each task ends with one commit on `work-003`. The delivery gate is one `aid-reviewer` pass over the
delivery's diff, plus G0.

**Resuming in the new `/aid-execute` (deliveries 010-014).** Expect these, once each:

- one confirmation question to repair this work's record (its type);
- the confirmation before building, with the wave question;
- the full-suite baseline recorded `not taken`;
- a milestone approval for each delivery built before the switch. None was recorded in the new
  `covers` form, so each is asked once.

From delivery-010's resync on, milestones offer to create or update the pull request through
`/aid-monitor-pipeline`. After delivery-014, the work reaches CI through `/aid-monitor-pipeline`,
which opens the v4.0.0 pull request on the maintainer's yes.

**Tracking until delivery-009.** Today's skills do not export `AID_STATE_FILE` or `AID_WORK_DIR`
(tech-debt W5-5), so their state writes fail silently. Every session that builds this work exports
both for this work, and confirms each task transition in the state file.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The pipeline building this work is the product being changed. A resync in the middle of a delivery changes skills and the writer under a running task. The resync of delivery-008 migrates this work's own state. | H | Toolchain and Branching: tasks detailed up front, the resync always last, the gate run from fresh skills, and one planned switch at delivery-008/009. |
| 2 | Delivery-009 is built by hand. Without `/aid-execute`, the per-task state writes and reviews depend on the main conversation following the procedure, and a missed write leaves a task at `Pending` while it runs. | H | The stated per-task procedure. Delivery-009's gate requires every task's state history, written by the writer, and a passing ledger per `Done` task. |
| 3 | The same files are edited in most deliveries: `writeback-state.sh` and its dashboard fork, `work-state-template.yml`, the twin dashboard readers, the `rules.md` skill guide, `skill-steps.md`, and `bin/aid` with `bin/aid.ps1`. | M | Strictly sequential deliveries. Every gate runs the writer, template, reader-parity and shell-parity suites in full. Every new state key follows the block-style rule (KI-002), checked by SS-08. |
| 4 | The task files are written up front, but earlier deliveries move and rename files that later task files name. Each spec's site lists were also measured before this work began. | M | Every delivery's first wave re-runs its spec's stated searches and reconciles the edit list. From delivery-009 on, task changes go through `/aid-plan` REVISE. |
| 5 | Format 6 is assembled across five deliveries, while this repository is migrated after each one:<br>- 005: the carriers and the KB step;<br>- 006: baselines and the parent branch;<br>- 008: work state;<br>- 009: building fields;<br>- 012: doorway rows. Later steps arrive on a repository already stamped 6. | M | Each step is detection-driven and idempotent, with a fixture of a repository already at format 6. The branch is pushed after each such delivery, so the Windows lane checks the PowerShell twin. |
| 6 | Three suites are split (Q113, Q115). A group added before its part lands turns the full suite red, and an earlier group broken by a later part goes unnoticed if only the new group is run. | M | Each group is added in the delivery that lands its part. G0 runs the whole `run-all.sh`, so every earlier group runs at every gate. |
| 7 | The conversation suite is costly and noisy. It needs 3 runs of 3, an LLM judge, and Claude Code on the maintainer's machine, never CI. All 14 gates run samples, and delivery-014 re-runs every one plus the live hosts and tracker. | M | Each gate runs only its own and its re-run samples, so the final run is a re-run. `deferred.tsv` is kept current at every gate. |
| 8 | Between delivery-011 and delivery-012, a new action skill and an old wrapper both fit some plain requests. | L | Plain-word sample runs wait for delivery-012. Typed runs gate delivery-011. |
