# Plan proposal -- Conversational AID Restructure (work-003, v4.0.0)

This is `aid-plan` FIRST-RUN steps 1 and 2, done for the **whole** sequence at once so the maintainer
can see the full shape before anything is written. It is a proposal: no `PLAN.md` and no
`deliveries/` folder exist yet, and none is created until the maintainer agrees.

Inputs read: `REQUIREMENTS.md` §§ 1-10 and the nine `### Feature NNN` sections of § 11 (each with its
`#### Technical Specification`); `known-issues.md` (KI-001 to KI-005); the work `STATE.yml` `qa`
(Q1-Q110); the KB through `.aid/knowledge/INDEX.md` (`architecture.md`, `module-map.md`,
`tech-debt.md`, `test-landscape.md`).

**How spec anchors read.** `F002 › 1. Files and layout` means the subsection with that heading inside
Feature 002's `#### Technical Specification` in `REQUIREMENTS.md` § 11. Text in quotation marks is copied
verbatim and can be found with `grep -F`.

---

## 1. Dependency map

### 1.1 Per feature

| Feature | Needs | Enables | Touches (main files and areas) | Known issues |
|---|---|---|---|---|
| **F001** Ask for Work in Plain Language | Nothing. §10: "Feature 001 leads -- everything else hangs off it". It reuses the existing gate and `enumerate-works.sh` without changing them. | **F002**: `start-or-resume.md`, `rules.md` § Handling a request, the conversation suite. **F003**: `size-and-route.md`, the kind hook in `check-intent.md`. **F004/F005**: `sources:` and the read seam. **F006**: the final place of `intent:`/`sources:` and the `ticket_ref` migration. **F007**: the depth table and the interim close. **F008**: replaces the close minimum and uses the per-sample `bin/` stand-ins. **F009**: the kind hook and the `<kind>` guide lines. | `canonical/aid/rules.md` (Handling a request, Skill guide, summary bullet); new `canonical/skills/aid-orchestrate/` with 5 references; every `SKILL.md` `description:`; `build-shortcut-skills.py`. Templates: `intent:`/`sources:` added, `ticket_ref` removed. `aid-update-ticket`, `aid-monitor`. Deletes `aid-triage`, the `aid-orchestrator` agent and `.aid/design/skill-routing.md`. New `tests/canonical/test-skill-guide.sh` and `tests/conversation/`; the summary-count suites; triage sites in `docs/` and `site/`; KB. | **KI-001** is fixed here. **KI-002**: its samples are already block style. |
| **F002** Clear, Step-by-Step Decisions | **F001**. `F002 › 1. Files and layout` edits "`canonical/skills/aid-orchestrate/references/start-or-resume.md` (Feature 001)" and `rules.md` § Handling a request. `F002 › 2. Work state layout`: the gate reads the work's "type with `/aid-orchestrate`'s `check-intent.md`". `F002 › 8. Testing` builds on F001's `tests/conversation/` (NFR-T: "Feature 001 builds the suite"). | **Every later feature.** It supplies `skill-steps.md`, `question-protocol.md`, the writer modes (`--create`, `--step`, `--handoff`, `--ask`, ...), the work record and the gate's `--create`, the shared exempt list, the deferred-tests list, the approvals table and the never-merges test. **F006** owns the planning part of the work file (Q34). | New `question-protocol.md`, `skill-steps.md`, `project-state-template.yml`. Deletes `state-machine-chaining.md` and `aid-interviewer`. `writeback-state.sh` (nine modes, new phase names) and its dashboard fork; `work-initiation-gate.md` § 3a/§ 3b; every allocation point. Banners and advance words in every hand-authored skill, plus `shortcut-engine.md` and `design-lifecycle.md`. The reviewer agent and every brief; `agent-boilerplate.md`. Dashboard readers (Python and Node), `server.py`, `home.html`; `site/scripts/lib/flow-graph/advance.mjs`. New suites: `test-skill-steps.sh`, `test-never-merges.sh`, `test-deferred-tests.sh`, `deferred.tsv`. | Fixes **KI-002** (block-style rule, SS-08) and **KI-003** (one question record). **KI-005**: NM-01 is written with the `merge-parent.sh` exception (Q85). Accepted at B+ by Q43, not A+ (see §3, P5). |
| **F003** Shape an Idea or Ticket | **F001** and **F002**. Its spec follows "FR-17, FR-18 and FR-20 as Features 001 and 002 define them". It needs the gate's `--create` and the phase `Definition` (F002), the writer fields and the gate's legacy block (F002), and the `size-and-route.md` and `check-intent.md` rows (F001). | **F004**: the KB-update branch of FINISH, plus the `KB change` approval row it owes. **F005**: reads drafts at START, and the deletion rule fires at its approval. **F007**: deletion at the `lite` confirmation; the side idea from Building. **F008**: no draft in the pull request's final content. **F009**: `kind-catalog.yml` grows to v2. | `aid-brainstorm` rewritten with 6 references. Deletes `aid-describe`, `aid-design` and every `aid-design-*` (22 folders today, measured). New `kind-catalog.yml` and `canonical/aid/scripts/works/idea-drafts.sh`. `design-seed.md`, the design-folder README, `shortcut-catalog.yml`, writer `--pipeline` fields, the gate's legacy rows, the `aid-orchestrate` references, the dashboard empty state. Suites `test-idea-shaping.sh` and `test-idea-drafts.sh`. | Fixes **KI-004 (High)**. |
| **F004** Self-Maintaining KB | **F001-F003**. Its spec follows those FRs "as Features 001-003 define" them. It edits "`canonical/skills/aid-brainstorm/references/finish.md` (Feature 003)", reuses F002's § The work record for the KB build record, and deletes `design-lifecycle.md`, which F003 had trimmed. | **F005**: the `--review` mode, the KB-call target and the No-KB rule. **F006**: format 6. **F007**: `pipeline.parent_branch`, the KB check after each task, `kb-commit.sh`. **F008**: the `cleanup-classify.sh` hand-over, the re-render on a collision, the close of `aid-kb-update`. **F009**: no `create`/`update` kind for a KB document. | Moves `aid-discover` to `aid-kb-build`, `aid-update-kb` to `aid-kb-update` and `aid-ask` to `aid-kb-query`; adds `aid-kb-show`. Deletes `aid-summarize`, `aid-housekeep`, the 14 KB `create`/`update` skills, `summarize/` and `design-lifecycle.md`. New `render-kb-view.sh`, `kb-commit.sh`, `kb-state-template.yml`. Writer `--kb` modes; the gate's § 3a new-project step; the `worktree-lifecycle.sh` base branch. `bin/aid`, `bin/aid.ps1` and `lib/` move to format 6 with a KB step. The dashboard KB card; the root `package.json`; the workflows. **This repository's own KB state file and `kb.html`.** | None registered. Resolves tech-debt L6, SY-7 and W4-5; hands SY-1 to F008. |
| **F005** Specification | **F001-F004**. Its spec follows "FR-20 as Features 001-004 define them". The writer change "Extends Feature 004's `--review` mode to the work file". START resolves drafts with `idea-drafts.sh path` (F003). The KB call targets `/aid-kb-update` (F004). | **F006**: reads both document shapes; the reads of `features` go; the KB call at the `PLAN.md` approval; the migration drops `interview`/`features`/`review_history`. **F007**: the KB call at the confirmation; the REVISE `CALL`; the unsplit slice. **F009**: the engine's CAPTURE and SPEC states go; `design.md` reads the catalog. | `aid-specify` rewritten with 9 references; deletes `aid-define` and the `specs/` template. `requirements-template.md` and `requirements.md` in the two-part shape. Writer: `--review` on the work file and `"Effort Check"`. `slice-requirements.sh`, `skill-steps.md`, `reviewer-dispatch.md` (Guard 2), the ledger schema, `aid-architect`. `test-specify.sh`. | None registered. Reads `known-issues.md` through `design.md`. |
| **F006** Planning by Deliveries and Waves | **F001-F005**. See "**Owed to this feature by Features 001-005, and where each is met:**". Its migration is "(Feature 004's format; no format 7)". | **F007**: task files, `tasks_lifecycle`, `deliveries`, `--plan-sync`, `/aid-plan` REVISE and the Q73 combined approval. **F009**: the engine's PLAN and DETAIL states go. | `aid-plan` rewritten. Deletes `aid-detail`, the delivery and task state templates, and `delivery-plans/`. New `plan-template.md`; `task-detail-template.md` rewritten. Writer gets the single layout, `--plan-sync`, the re-render and exit 11 (plus the fork). `derive-waves.sh --plan`; the gate's legacy block is removed; `shortcut-engine.md` PLAN/DETAIL; `aid-deploy`. The format-6 work-state step in `bin/aid` and `bin/aid.ps1`; the dashboard reads one layout. `test-plan.sh`, `test-work-state-migration.sh`. | None registered. Narrows tech-debt W5-5 (the task-state half), SY-5 and SY-6. |
| **F007** Hands-Off Building | **F001-F006**. See "**Owed to this feature by Features 001-006, and where each is met:**". | **F008**: the collect, push and correction calls; the `feedback` writer modes; `milestone.md` and `finish.md`. **F009**: APPROVAL-HALT and `IMPEDIMENT.md` go; `test.md` reads the catalog. | `aid-execute` rewritten: 13 references created, 7 deleted. New `simplify-guard.sh`. Writer: the building fields, `--full-suite`, `--feedback*`, the derived delivery state (plus the fork and writer parity). `derive-waves.sh --delivery`, `complexity-score.sh`, `compute-block-radius.sh`. Deletes `delivery-issues.md`. `aid-plan` `revise.md`; `shortcut-engine.md` APPROVAL-HALT; `aid-developer`. The format-6 building part; the dashboard. `test-execute.sh`, `test-simplify-guard.sh`. | **KI-001** follow-up: the tracking line in `rules.md` names EXECUTE, which becomes BUILD (`F007 › 6. Risks`). |
| **F008** Pull Requests Kept on Track | **F001-F004** and **F007**. See "**Owed to this feature by Features 001-007, and where each is met:**". Its rows for F005 and F006 read "Nothing addressed here". | **F009**: the finishing skills pass to the close; `/aid-fix` reads the ledger from the main folder; `close.md`, `cleanup-classify.sh --work`. | New `aid-monitor-pipeline` with 11 references. New `pipeline/push-approved.sh`, `merge-parent.sh`, `close-work.sh`; `cleanup-classify.sh` moved. Writer `--pull-request`. `settings.yml` `work_folders`; the gate's § 3b row 1; `consumption-protocol.md`. The finish of `aid-research`, `aid-review`, `aid-report` and `aid-deploy`; `aid-operator`; `delete-pipeline.sh`; the dashboard CI card. New suites and `tests/conversation/stand-ins/`. | Implements the settled **KI-005**. |
| **F009** One Obvious Skill for Each Need | **F001-F008**. See "**Owed to this feature by Features 001-008, and where each is met:**". | Nothing: it is the last feature ("This is the last feature"). It empties the deferred list and both exempt lists. | Action skills `aid-create`, `aid-update`, `aid-fix`, `aid-refactor`, `aid-document`, `aid-test`, `aid-prototype`; `aid-config` renamed `aid-configure`. New `action-start.md` and the two ticket procedures; `kind-catalog.yml` v2. Deletes the remaining wrapper skills, the shortcut engine, its catalog and scaffolding, `feedback-artifacts/` and `build-shortcut-skills.py`. Writer `--kind`; catalog readers in specify, plan and execute. The site generator rewrite; the dashboard legacy markers; the identity statement. **The final documentation pass** over `docs/`, `site/src/content/docs/`, `README.md` and `examples/` (Q104). | None. |

**No fix-first delivery is needed.** No known issue is Critical. The only High one, KI-004, is fixed by
its owning feature (F003), and nothing before F003 depends on drafts surviving.

### 1.2 Dependency graph

```text
F001 -> F002 -> F003 -> F004 -> F005 -> F006 -> F007 -> F008 -> F009
```

These are the direct edges each spec declares (all transitive along the chain):

- F002 needs F001.
- F003 needs F001 and F002.
- F004 needs F001 to F003.
- F005 needs F001 to F004.
- F006 needs F001 to F005.
- F007 needs F001 to F006.
- F008 needs F001 to F004 and F007.
- F009 needs F001 to F008.

**There is no cycle.** Each spec does name later features, but only in three forms, and none of them is
needed to build or test the earlier feature:

- **Deferred samples.** Example: F002's `002-13` waits for F004 and F007.
- **Exempt-list rows owned by a later feature.** Example: NM-03 exempts `aid-housekeep` until F004.
- **Allow-listed paths that do not exist yet.** Examples: NM-01's `merge-parent.sh`, and KB-03's
  `aid-monitor-pipeline/`.

The chain also fixes the order completely. No two features can swap places, so the only free choices
are how to group the features and which toolchain builds them (§3).

### 1.3 Gaps between features that the specs accept

At each of these boundaries the test suite is green, but a **new** work's path from start to end is
broken until the next feature lands. Each spec accepts this because no release ships in between.

| After | Gap | Spec anchor |
|---|---|---|
| F005 | A new work that does not split can be specified, but today's `aid-plan` cannot plan it. | `F005 › 2. The document`: "No release carries that gap, since every feature ships in v4.0.0" |
| F006 | A work planned by the new `/aid-plan` cannot be built by today's `aid-execute`. | `F006 › 7. Risks`: "No bridge is built: no release ships between the two features" |
| F007 | The close runs through `/aid-orchestrate` until F008 lands. | `F007 › 6. Risks`: "Feature 006's precedent: no bridge, no release between them" |

For other users these gaps are harmless. **For this work they are not**: the pipeline that builds
work-003 is the pipeline work-003 changes (§3, P1). The F006 -> F007 gap is the one that decides the
grouping.

---

## 2. Proposed deliveries

Every feature is **Must** (§10). The proposal has nine deliveries:

- one per feature;
- F006 and F007 joined into one delivery (P2);
- F009 split in two, as Q104 binds.

No feature is deferred. Each delivery depends on the one before it.

### G0 -- the common gate (every delivery)

Every stanza ends with "G0 passes". G0 means all of the following:

- **The full suite is green locally:** `HOME="$(mktemp -d)" bash tests/run-all.sh`, plus the site
  `npm test`. The canonical lane does not run on feature branches (`test-landscape.md` § CI Lanes and
  Where They Run).
- **Render drift is clean** after `run_generator.py`.
- **The Windows lane is green** on the pushed `work-003` branch (`installer-tests.yml`). This covers
  every PowerShell twin. (AC-25)
- **Names follow AC-22:** every new skill or artifact name is a verb, or KB plus a verb, with no acronym.
- **Old -> new rows (AC-24):** every slash name the delivery retires has its row in `.aid/knowledge/backlog.md`
  § Next Release.
- **The KB is current:** the delivery's KB edits are made, with no work id, and `INDEX.md` is
  regenerated (and `kb.html` rendered, from delivery-004 on).
- **Coverage records follow:** `tests/coverage-baseline.tsv` and `tests/cost-baseline.tsv` are
  re-recorded, and removed assertions are listed in `tests/coverage-accepted-removals.tsv`.
- **Samples pass:** every conversation sample the delivery's spec marks "now", and every re-run it
  names, passes 3 runs of 3 (NFR-T). Every sample still waiting has a `deferred.tsv` row.

### delivery-001: Ask in plain words -- F001

- **Features:** feature-001 (Ask for Work in Plain Language)
- **Depends on:** -- (foundation)
- **Priority:** Must
- **What it delivers:** A user states a request in plain words and the agent routes it through the
  skill guide in `rules.md` to the right skill, which is still one of today's skills at this point. A
  project question is answered from the KB with sources and starts no work. A work records its reading,
  depth and phases (`intent:`) and its own sources (`sources:`). `/aid-triage` and the orchestrator
  agent retire. The conversation test suite exists.
- **Why grouped:** F001 alone. It is the foundation every later spec edits: `rules.md`,
  `/aid-orchestrate` and the work's `intent:`/`sources:`. It also ships the conversation suite that every
  later gate runs.
- **Stands alone and is tested alone:** The skill guide lists today's skills, with the `<kind>`
  expansion for families. Routing reaches skills that exist, and `/aid-orchestrate` runs the close
  minimum itself. SG-01 to SG-06 and samples `001-01` to `001-16` run with nothing from later features.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-skill-guide.sh` SG-01 to SG-06 pass. `## Handling a request` is at most 20
    lines. The guide matches `canonical/skills/` both ways. No `aid-triage` and no `aid-orchestrator`
    remain; `aid-developer` and `aid-tech-writer` are present. Every skill installs in all five tools.
    (AC-6, AC-21, AC-23)
  - [ ] `tests/conversation/run.py --feature 001` runs, and samples `001-01` to `001-16` each pass 3
    of 3. (AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14)
  - [ ] `work-state-template.yml` carries `intent:` and `sources:` in block style, and no template
    carries `ticket_ref`. Samples `001-11` to `001-13` show a work source applied and written back on
    request. (AC-29)
  - [ ] The `rules.md` tracking section names the work state file `STATE.yml`, not `STATE.md`. (KI-001)
  - [ ] G0 passes.

### delivery-002: One question protocol and one set of step rules -- F002

- **Features:** feature-002 (Clear, Step-by-Step Decisions)
- **Depends on:** delivery-001
- **Priority:** Must
- **What it delivers:**
  - Every question follows one protocol: one topic, its reason, a recommendation, an importance label,
    grouped with breaks.
  - Every skill follows `skill-steps.md`: no banners, the current step always saved, pass and call
    hand-offs.
  - The work record decides where a work resumes, with a confirmed repair when it is missing.
  - Approvals and the merge boundary are stated once.
  - The interviewer agent retires.
  - The dashboard shows the new phase names and one stage rail per work.
- **Why grouped:** F002 alone. Its rules are the contract every later phase skill is rebuilt on.
  Its single static suite (SS-01 to SS-14) asserts the feature as a whole (see P4).
- **Stands alone and is tested alone:**
  - Today's skills keep working under it. Its scope says
    "today's skills change only where a rule must hold for every skill now", and the nine phase writes
    move to the new names in the same delivery.
  - Writer units, gate `--check` fixtures and the dashboard parity tests need nothing later.
  - The samples that do need later features are listed in `deferred.tsv`.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-skill-steps.sh` SS-01 to SS-14 pass. `state-machine-chaining.md` and
    `aid-interviewer` are gone. No `AskUserQuestion` appears in any `allowed-tools`. The reviewer agent
    and every brief carry `### What to report`. (AC-37, AC-40, AC-46)
  - [ ] `tests/canonical/test-never-merges.sh` NM-01 to NM-04 pass, with only the two named exemptions
    firing. (AC-11)
  - [ ] `test-writeback-state.sh` covers `--create`, `--step`, `--handoff` (call and pass),
    `--handoff-return` (nested), `--check`, `--repair`, `--ask` and `--answer`. It also checks atomic
    writes and exits 4, 5, 7, 8 and 9. The gate has a `--check` fixture for each resume-table row.
    (AC-37, AC-38)
  - [ ] Both dashboard readers pass parity on the new phase names, `record_status` and the stage rail
    built from `intent.phases`. SS-07 holds for `chat-node/`. (AC-41)
  - [ ] Samples `002-01` to `002-05` and `002-14` to `002-21` each pass 3 of 3. DT-01 passes on
    `deferred.tsv`. (AC-8, AC-11, AC-28, AC-37)
  - [ ] G0 passes.

### delivery-003: Shape an idea into a draft that survives -- F003

- **Features:** feature-003 (Shape an Idea or Ticket into a Clear Work Definition)
- **Depends on:** delivery-002
- **Priority:** Must
- **What it delivers:**
  - `/aid-brainstorm` is a conversation the user ends. It keeps a living idea draft in the main
    folder's `.aid/design/` and can be paused, parked or taken up as a side idea.
  - A typed kind and the same kind in plain words reach the same catalog rules.
  - `/aid-describe`, `/aid-design` and every `/aid-design-*` retire.
  - Drafts are committed only when the user asks.
- **Why grouped:** F003 alone. It is the Definition phase, and it closes KI-004, the High issue.
- **Stands alone and is tested alone:**
  - Brainstorm runs end to end and finishes with a `PASS` to today's `aid-specify`, which still
    exists.
  - The KB-update branch reaches today's `aid-update-kb` and leaves the work open, as `F003 › 3. Flow`
    states.
  - `idea-drafts.sh` is unit-tested on throwaway repositories.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-idea-shaping.sh` ID-01 to ID-07 pass: no `aid-describe`, `aid-design` or
    `aid-design-*`, and no `verb: design` row. (AC-43)
  - [ ] `tests/canonical/test-idea-drafts.sh` passes:
    - `dir`, `path`, `list`, `collect`, `keep`, `release` and `delete` behave as specified;
    - only the draft's own path is ever committed;
    - nothing is pushed;
    - exits 2, 3, 4 and 5 change nothing. (AC-17, KI-004)
  - [ ] The writer accepts `"Idea Draft"` and `"Side Idea"` and refuses anything else with exit 4. The
    gate's legacy block has the two new rows, each with a `--check` fixture. (AC-17, AC-37)
  - [ ] Samples `003-01` to `003-05` each pass 3 of 3, and `001-08` passes again. (AC-17, AC-28, AC-43)
  - [ ] G0 passes.

### delivery-004: A KB that keeps itself current -- F004

- **Features:** feature-004 (Self-Maintaining KB with an Always-Current Web View)
- **Depends on:** delivery-003
- **Priority:** Must
- **What it delivers:**
  - Four KB skills -- build, query, update, show -- run by the agent's own judgment.
  - A script renders `kb.html` from the documents, with the same bytes for the same KB.
  - The KB state moves to YAML.
  - KB changes are committed inside works.
  - A new project grows its KB from a skeleton.
  - Roadmap and backlog become ordinary documents.
  - The summarize and housekeep skills retire, along with the 14 KB `create`/`update` skills.
  - Format 6 begins, and this repository's own KB is converted.
- **Why grouped:** F004 alone. It is one coherent ownership change: every write to the KB goes through
  `/aid-kb-update` or the build. Its format-6 carriers have to move together.
- **Stands alone and is tested alone:**
  - The KB loop works with today's Specification and Planning.
  - The calls F005 and F007 will make are rows in `F004 › 6. What other features must provide`. They
    wait, and their samples are on the deferred list.
  - The renderer, `kb-commit.sh` and the migration are unit-tested on fixtures.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-kb-skills.sh` KB-01 to KB-08 pass:
    - the four KB skills exist;
    - the retired skills, `summarize/` and `design-lifecycle.md` are absent;
    - the re-pointing rule holds. (AC-15, AC-39)
  - [ ] `tests/canonical/test-render-kb-view.sh` passes: two renders give identical bytes, there is no
    external link, and `--check` exits 0, 1 and 3. This repository's `kb.html` is produced by the
    script. (AC-15)
  - [ ] `tests/canonical/test-kb-state-migration.sh` passes, with bash and PowerShell byte-identical.
    This repository's `.aid/knowledge/STATE.yml` exists and `STATE.md` is gone. Every format-6 carrier
    reads 6. (AC-25)
  - [ ] `test-kb-commit.sh` and `test-worktree-lifecycle.sh` pass. A new work branches from the main
    folder's current branch (Q60), and no KB path is committed outside `kb-commit.sh`. (AC-15, AC-18)
  - [ ] Samples `004-01` to `004-09` and `003-11` each pass 3 of 3. `001-05` and `001-15` pass again.
    (AC-15, AC-28, AC-39)
  - [ ] G0 passes.

### delivery-005: One requirements document, business and technical -- F005

- **Features:** feature-005 (Specification with Both Business and Technical Detail)
- **Depends on:** delivery-004
- **Priority:** Must
- **What it delivers:**
  - One `/aid-specify` for the whole work: today's define and specify merged.
  - It writes `REQUIREMENTS.md` with a business part and a technical part.
  - It splits into features only when the work delivers several capabilities.
  - It checks the effort level once per work.
  - It has a REVISE path for changes made later.
  - Its approved project decisions reach the KB through one call.
- **Why grouped:** F005 alone. It is the whole Specification phase.
- **Stands alone and is tested alone:**
  - Specification runs from a request or a draft through approval and the KB call, and finishes with a
    pass to `aid-plan`.
  - Past that pass, today's `aid-plan` stops on a document that does not split (§1.3). The samples
    that go further wait on the deferred list.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-specify.sh` SP-01 to SP-08 pass: `aid-define` and `specs/` are gone; the
    two-part template exists; the step table and the three choices after three rounds are present.
    (AC-16, AC-44)
  - [ ] `effort-check.md` has a row for each of the five tools and states the "cannot be read" path.
    `aid-kb-build` does not cite it. (AC-12)
  - [ ] `test-slice-requirements.sh` slices the unsplit shape and both split shapes. The writer appends
    work `reviews` and accepts `"Effort Check"`. (AC-44)
  - [ ] Samples `005-01` to `005-10` each pass 3 of 3, together with the deferred samples that now run:
    `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09` and `004-10`. `001-08` and `001-09`
    pass again. (AC-9, AC-10, AC-12, AC-16, AC-18, AC-44)
  - [ ] G0 passes.

### delivery-006: Plan and build on one state file -- F006 + F007

- **Features:** feature-006 (Planning by Deliveries and Waves) and feature-007 (Hands-Off Building)
- **Depends on:** delivery-005
- **Priority:** Must
- **What it delivers:**
  - One `/aid-plan`, today's plan and detail merged. It writes `PLAN.md` as a generated checklist of
    deliveries, waves and tasks. Task files are the only source, and there is one `STATE.yml` per work.
  - One `/aid-execute` that builds one task at a time. Each task goes build, test, verify, simplify,
    and re-verify only when the simplification changed something.
  - It has a full-suite baseline and stops for approval only at milestones.
  - It uses one worktree and one branch.
  - The format-6 work-state migration, in bash and PowerShell.
  - **This work's own state is migrated, and from this delivery on it is built by the new
    `/aid-execute`** (P1).
- **Why grouped:** These two are joined because between them nothing can build anything:
  - After F006 alone, today's `aid-execute` cannot build what the new `/aid-plan` writes (§1.3).
  - For this work, the dogfood resync's `aid update` would already have moved work-003 to the single
    layout.
  - So the delivery that builds F007 would have no builder (P1, P2).
- **Stands alone and is tested alone:**
  - Plan and build work end to end. The close runs through `/aid-orchestrate` until delivery-007.
  - The migration is unit-tested in both shells.
  - The deferred samples that waited for Planning and Building run here.
- **Draft gate criteria:**
  - [ ] `test-plan.sh` PL-01 to PL-07 and `test-execute.sh` EX-01 to EX-08 pass.
    - No `deliveries/` folder, delivery state file or task state file is written.
    - `derive-waves.sh --plan --check` exits 0 on a fresh plan.
    - No skill creates a branch or a worktree.
    - (AC-19, AC-34)
  - [ ] `tests/canonical/test-work-state-migration.sh` passes on nested, old lite and single-layout
    fixtures, with bash and PowerShell byte-identical and a second run changing nothing. After the
    re-seat, this work's own state passes `writeback-state.sh --check` and resumes in `/aid-execute`.
    (AC-19, AC-37)
  - [ ] `test-simplify-guard.sh` passes. The writer derives the seven delivery states, equal in the
    canonical writer and the dashboard fork. NM-04's exemption is gone. (AC-33, AC-34, AC-11)
  - [ ] Samples `006-01` to `006-05`, `006-07`, `006-08` and `007-01` to `007-12` each pass 3 of 3,
    together with the deferred samples that now run: `002-07`, `002-08`, `002-09`, `002-13`, `003-07`,
    `003-10`, `004-11`, `004-12`, `005-11`, `005-12`, `005-13` and `006-06`. (AC-10, AC-19, AC-26,
    AC-32, AC-33)
  - [ ] G0 passes.

### delivery-007: Pull requests to a mergeable state, never merged -- F008

- **Features:** feature-008 (Pull Requests Kept on Track Through Reviews and Pipeline Failures)
- **Depends on:** delivery-006
- **Priority:** Must
- **What it delivers:**
  - `/aid-monitor-pipeline` creates or updates the one pull request only on the user's yes, and
    pushes only approved commits.
  - It corrects bugs and pipeline failures as ordinary builds, and asks about suggestions.
  - It brings in the parent branch only for a conflict, with that merge approved before it is pushed.
  - After a human merges, it closes the work locally.
  - The work-folder setting applies, and the interim close goes.
- **Why grouped:** F008 alone. It is the CI phase, and the only skill that touches the pull request.
- **Stands alone and is tested alone:**
  - Every work now ends at a real close.
  - `push-approved.sh`, `merge-parent.sh` and `close-work.sh` are unit-tested against a local bare
    remote.
  - The conversation samples use the `gh`/`glab` stand-ins. The live-host run waits for the final
    integration suite.
- **Draft gate criteria:**
  - [ ] `test-monitor-pipeline.sh` MP-01 to MP-05 pass. `test-never-merges.sh` passes with NM-01
    narrowed, NM-03 holding no exemption, and NM-05 and NM-06 added. (AC-11, AC-34)
  - [ ] `test-push-approved.sh`, `test-merge-parent.sh` and `test-close-work.sh` pass:
    - only approved commits are pushed;
    - the final-content check refuses `.aid/.temp/`, another work's folder and an added draft;
    - no remote branch is deleted;
    - nothing is forced. (AC-35, AC-36, AC-42)
  - [ ] `aid-research`, `aid-review`, `aid-report` and `aid-deploy` pass to the close and write no
    `Completed` themselves. No interim close remains (MP-05). (AC-14, AC-36)
  - [ ] Samples `008-01` to `008-14` and `008-16` to `008-18` each pass 3 of 3. `002-10`, `007-13` and
    `001-16` run and pass. (AC-13, AC-27, AC-35, AC-36, AC-42)
  - [ ] G0 passes.

### delivery-008: One skill per action, one catalog of kinds -- F009 (first part)

- **Features:** feature-009 (One Obvious Skill for Each Need), everything except its final
  documentation pass
- **Depends on:** delivery-007
- **Priority:** Must
- **What it delivers:**
  - Seven action skills -- create, update, fix, refactor, document, test, prototype -- replace every
    action-and-kind wrapper. Each kind is typed or said in plain words.
  - One merged kind catalog, which includes the user's own `.aid/kinds/`.
  - `/aid-configure`.
  - The shortcut engine and its catalog retire.
  - Domain readiness, with no pack shipped.
  - The site generator learns the new skill set.
  - The deferred list and both exempt lists are emptied, except for the integration-run rows.
- **Why grouped:** Everything F009 changes in the product goes here. Deleting the engine, the shortcut
  catalog and the site's doorway model only works as one change, because each half is red without the
  other.
- **Stands alone and is tested alone:**
  - Every user path now runs on the final skill set.
  - AS-01 to AS-10 and the migration rows are static and unit checks.
  - The samples run with no live connection; the tracker samples wait for the integration run.
- **Draft gate criteria:**
  - [ ] `tests/canonical/test-actions.sh` AS-01 to AS-10 pass:
    - no folder matches `aid-(create|update|design|document|test|prototype)-`;
    - `aid-configure` exists and `aid-config` does not;
    - the shipped catalog has the specified shape, and the action layer uses no software term.
    - (AC-20, AC-22, AC-30, AC-31)
  - [ ] `shortcut-engine.md`, `shortcut-catalog.yml`, `shortcut-scaffolding/`, `feedback-artifacts/`
    and `build-shortcut-skills.py` are absent. The dashboard names no retired skill outside the
    `legacy-skill-names` markers (AS-07). (AC-20, AC-31)
  - [ ] `test-work-state-migration.sh` maps old doorway works to the new skills and kinds. Every row
    that names a retired skill sits inside the markers, and bash and PowerShell are byte-identical.
    (AC-30, AC-37)
  - [ ] Samples `009-01` to `009-10` and `009-13` to `009-19` each pass 3 of 3. `001-01`, `001-07`,
    `002-02`, `003-02` and `008-14` pass again. (AC-28, AC-30)
  - [ ] Both exempt lists are empty. `deferred.tsv` holds only the rows that wait for the integration
    run (`008-15`, `009-11`, `009-12`). (NFR-T)
  - [ ] G0 passes.

### delivery-009: Final documentation pass and release readiness -- F009 (last part, Q104)

- **Features:** feature-009, its final documentation pass (AC-45) and the end-of-work checks
- **Depends on:** delivery-008
- **Priority:** Must
- **What it delivers:**
  - The user documentation -- `docs/`, `site/src/content/docs/`, `README.md`, `examples/` -- is
    rewritten by the tech-writer agent against the finished product. Its old -> new table sits inside
    `legacy-skill-names` markers.
  - The identity statement is the same everywhere.
  - The release checks pass with every list empty.
  - The full integration suite is green, live hosts and trackers included.
- **Why grouped:** Q104 makes this F009's last delivery. AC-45 places the one pass
  "After all features are built". It can only be judged against the finished product.
- **Stands alone and is tested alone:** It changes only user documentation and generated site pages,
  and it is checked by DN-01 to DN-03 and the release checks.
- **Out of scope:** tagging and publishing v4.0.0. That is an operational work of its own (FR-7).
- **Draft gate criteria:**
  - [ ] With `AID_RELEASE_CHECK=1`, DN-01, DN-02 and DN-03 pass:
    - no user document names a retired skill or an old phase name outside the markers;
    - every name in `retired-names.txt` has its old -> new row;
    - every file found by the identity search says "software first, not software only".
    - (AC-24, AC-45)
  - [ ] With `AID_RELEASE_CHECK=1`, DT-02 and both exempt-list release checks pass: every list is
    empty. (NFR-T)
  - [ ] The full integration suite passes 3 of 3: every sample of every feature, plus `008-15` (live
    GitHub and GitLab) and `009-11` and `009-12` (live tracker). (AC-13, AC-27, AC-29, AC-30, AC-36)
  - [ ] The site's generated pages come from `site/scripts/gen-skills.mjs` with no hand edit, and the
    site builds. (AC-45, AC-31)
  - [ ] G0 passes.

### Assignment check

| Feature | Delivery |
|---|---|
| F001 | delivery-001 |
| F002 | delivery-002 |
| F003 | delivery-003 |
| F004 | delivery-004 |
| F005 | delivery-005 |
| F006 | delivery-006 |
| F007 | delivery-006 |
| F008 | delivery-007 |
| F009 | delivery-008 and delivery-009 |

Deferred: none.

---

## 3. Points the maintainer must decide

### P1. Which pipeline builds this work

**Why this is a decision.** This repository installs AID into itself:

- `run_generator.py` ends by "Resyncing dogfood install", through `sync_dogfood.py`, which runs
  `aid update --from-bundle` on this repository.
- `test-dogfood-byte-identity.sh` requires the installed trees to equal `canonical/`:
  "a stale installed copy fails here".

So a delivery that leaves the suite green has replaced the skills and scripts that run this pipeline.
From F004 on, it has also run format-6 migrations over **this work's own state**. F006's step:
"It reaches every work `STATE.yml` in the main folder and in each worktree `git worktree list` registers".

The toolchain changes at these points:

| Delivery | What changes for this work |
|---|---|
| delivery-002 (F002) | The writer refuses old phase names; today's skills are edited to match. |
| delivery-004 (F004) | The KB state file is converted, and the format-6 stamp is applied. |
| delivery-006 (F006 and F007) | Today's `/aid-detail` and `/aid-execute` are gone, and work-003 moves to the single layout. |

**Options:**

- **(a) Re-seat once, at the Building rebuild. Recommended.**
  - Today's `/aid-detail` writes the task files of every delivery up front. Its FIRST-RUN already
    covers every delivery, and "Task numbering is global".
  - In every delivery, the dogfood resync is the **last task**, so a delivery runs on the toolchain it
    started with. Earlier tasks check their own suites, not the byte-identity test.
  - Deliveries 001-005 run on today's pipeline. Each spec keeps today's skills working, for example
    F002 changes them "only where a rule must hold for every skill now".
  - delivery-006's last task migrates work-003. Its delivery verification, and deliveries 007-009,
    then run on the new `/aid-execute` through its old-work path.
  - Cost: one record-repair question at the switch. The new builder will also ask once for the
    milestone approval of each delivery built before the switch, because none was recorded in the new
    `covers` form.
- **(b) Freeze today's pipeline for the whole work.** Not recommended. Skills load from where the session
  starts, but today's `/aid-execute` does "Locate + enter the work's worktree". From then on, every
  `bash .aid/runtime/scripts/...` call resolves inside the worktree. The writer changes of F002, F006
  and F007 would reach the frozen skills anyway, unless a hand-kept copy of the runtime outside the
  repository is used for every call.
- **(c) One delivery for the whole work.** It avoids switches between deliveries, but still needs (a)'s
  resync-last rule. It also gives up every checkpoint, and no reviewer can grade it in one pass.

### P2. F006 and F007: one delivery or two

- **(a) One delivery. Recommended.** It is the only grouping in which some builder exists at every
  moment of this work (P1). Cost: the largest delivery of the plan. Each task is still reviewed on its
  own, and the delivery gate stays an aggregate.
- **(b) Two deliveries,** with the F007 delivery built by the main conversation directly, task by task,
  writing every state through the writer as the rules' tracking discipline requires. Smaller
  deliveries, but F007 then gets no per-task review from `/aid-execute`.
- **(c) Two deliveries, with a temporary bridge** that lets today's `aid-execute` read the single
  layout. This contradicts `F006 › 7. Risks`: "No bridge is built".

### P3. The delivery branches today's `/aid-execute` creates (deliveries 001-005, and 006 up to the re-seat)

Today's skill builds each delivery on "Branch name: `aid/{work}-delivery-NNN`" and its lifecycle ends
with "→ merge to main". For v4.0.0 nothing may reach `master` before the whole work's pull request.

- **(a) Recommended:** After each delivery's gate, the maintainer fast-forwards `work-003` to the
  delivery branch. There is no merge commit and `master` is untouched, so the next delivery branches
  from a `work-003` that holds everything. At the re-seat, F007's old-work path (Q80) then finds nothing
  that diverges.
- **(b)** Leave the delivery branches chained, and let F007's `references/old-work.md` move `work-003`
  forward at the re-seat. That path is untested until the re-seat itself, and a branch that diverges
  becomes a blocker.
- **(c)** Tell today's `/aid-execute` to build directly on `work-003` and skip its Check 5. This
  anticipates FR-6, but departs from the skill as it is installed.

### P4. Splitting a feature across deliveries

- **(a) Recommended: keep one feature per delivery,** except the joins and splits above (F006 + F007;
  F009 in two, by Q104). Each feature ships one static suite that asserts the whole feature (SS-*,
  KB-*, PL-*, EX-*, AS-*). Half a feature leaves its own suite red, which breaks G0, unless the suite
  is cut in two as well.
- **(b) Split F002** into "engine" and "sweep":
  - engine: the protocol, `skill-steps.md`, the writer modes, the work record, the gate;
  - sweep: banners and advance words across today's skills, the interviewer, the dashboard.
  The SS groups would be re-cut to match.
- **(c) Split F004** into "the four KB skills and the renderer" and "the state file, format 6 and the
  dashboard". This needs the same kind of re-cut of KB-01 to KB-08.

### P5. Where Planning does Q43's cross-feature review of F002

Q43 approved F002 at B+ after 17 rounds. It relied on "the cross-feature review at Planning catch
remaining edge cases".

- **(a) Recommended:** Run it in this plan's REVIEW. The reviewer brief adds one pass that checks F002's
  shared contracts against every use of them in F003-F009 (writer modes and exit codes, the
  `skill-steps.md` approval rows, the work record, the deferred and exempt lists). Spec fixes then land
  before any task is detailed.
- **(b)** Make it a RESEARCH task at the start of delivery-002. This is later and cheaper, but a finding
  then reopens a spec in the middle of building.
- **(c)** Fold it into `/aid-detail`'s whole-list review. That review grades the task files, not the
  specs, so it is the wrong lens.

---

## 4. Cross-cutting risks

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | **The pipeline building the work is the product being changed** (P1). A dogfood resync in the middle of a delivery changes the skills and the writer under a running task. A resync after F006 migrates this work's own state. | H | P1 (a): the resync is the last task of each delivery; tasks are detailed up front; one planned re-seat at delivery-006; P2 (a); P3 (a). |
| 2 | **The same files are edited in almost every delivery:**<br>- `writeback-state.sh` and its dashboard fork (F002-F009);<br>- `work-state-template.yml` (all nine);<br>- the twin dashboard readers (F002, F004, F006-F009);<br>- `rules.md` § Skill guide (all nine);<br>- `skill-steps.md` (F002-F008);<br>- `bin/aid` and `bin/aid.ps1` (F004, F006, F007, F009). | M | Strictly sequential deliveries, none in parallel. Every gate runs the writer, template and parity suites in full. Every new state key follows the block-style rule (KI-002), which SS-08 checks. |
| 3 | **Format 6 is assembled across four deliveries** while this repository is migrated after each one. F004 states: "Feature 006 adds its work-state step to the **same** format 6, so there is no format 7." Later steps therefore arrive on a repository already stamped 6. | M | Each step stays detection-driven and idempotent, as F006 requires. Each migration suite gets a fixture of a repository already at format 6. The branch is pushed after every delivery that edits `bin/aid*`, so the Windows lane checks the PowerShell twin. |
| 4 | **Spec site lists go stale.** Each spec lists its edit sites as they stood before this work began ("The sites today", "Run on today's tree"). Earlier deliveries move and rename files, for example F004 moves `aid-discover` to `aid-kb-build`. | M | The first task of each delivery re-runs that spec's stated searches (F007 and F009 give re-runnable `grep` commands) on the current tree, and reconciles the edit list before any edit. |
| 5 | **Today's skills write state silently** (tech-debt W5-5). Until the rebuilt skills fail closed, today's `--pipeline` and task-state writes fail unless `AID_STATE_FILE` and `AID_WORK_DIR` are exported. Tracking then breaks without any error while deliveries 001-006 are built. | M | Every session that builds this work exports both variables for work-003 until the re-seat, and confirms the task state in `STATE.yml` after each transition. |
| 6 | **The conversation suite is costly and noisy.** It needs 3 runs of 3, an LLM judge, Claude Code on the maintainer's machine and never CI (Q33). The final run covers every sample plus the live hosts and trackers. Any sample still failing blocks the release (F009 risks). | M | Run each delivery's samples at its own gate, as the spec requires ("run on demand at each feature's end"), so the final run is a re-run. Keep `deferred.tsv` current at every gate. |
| 7 | **"Green" on a feature branch is a local claim.** The full `run-all.sh` lane runs only on `master` and on tags. | M | G0 requires a local `run-all.sh` with `HOME` pinned, the site `npm test`, and the Windows lane on the pushed branch. |

---

## 5. What blocks planning

Nothing blocks this proposal. Two answers are needed before `PLAN.md` is written, because they set its
shape:

- **P1 and P2.** They decide whether F006 and F007 share delivery-006.
- **P5.** If (a) is chosen, it adds a pass to this plan's REVIEW.

Two observations, neither blocking:

- `STATE.yml` records F002 at grade B+, while the other eight features are at A+. Q43 approved it as
  Ready.
- This work runs on today's full layout. With P1 (a), task numbering stays global across deliveries, so
  F006's migration of work-003 meets no duplicate task id.
