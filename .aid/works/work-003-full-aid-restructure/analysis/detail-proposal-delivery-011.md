# Detail proposal -- delivery-011: Action skills and one catalog of kinds (Feature 009a)

This is `aid-detail` FIRST-RUN for **delivery-011**, under Q136. Decisions are settled by recommendation, the task
files are written at once, and the light review is the check.

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-288 | Delivery-011 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-289 | The kind catalog, version 2: actions, the new fields and the new kinds | IMPLEMENT | 2 | 2 | task-288 |
| task-290 | The merged catalog and the kind hook in check-intent.md, and the action routing | IMPLEMENT | 2 | 3 | task-288, task-289 |
| task-291 | Writer: --kind on --create and --reroute, and the reading investigation | IMPLEMENT | 2 | 2 | task-288 |
| task-292 | Recording the kind: intent.kind in the template, and the gate's --kind | IMPLEMENT | 2 | 3 | task-291 |
| task-293 | action-start.md: the one START of every action skill | IMPLEMENT | 3 | 4 | task-289, task-290, task-292 |
| task-294 | aid-create and aid-update hand-authored, and their catalog rows gone | IMPLEMENT | 3 | 5 | task-293 |
| task-295 | aid-fix and aid-refactor hand-authored with the findings reference, and their catalog rows gone | IMPLEMENT | 3 | 6 | task-294 |
| task-296 | aid-document rewritten as an action skill | IMPLEMENT | 3 | 5 | task-293 |
| task-297 | aid-test rewritten as an investigation, with its references | IMPLEMENT | 3 | 5 | task-293 |
| task-298 | aid-prototype rewritten as an investigation, with its references | IMPLEMENT | 3 | 6 | task-297 |
| task-299 | Specification reads the kind: aid-specify's catalog fields | IMPLEMENT | 4 | 4 | task-289, task-290 |
| task-300 | Planning, Building and Definition read the kind | IMPLEMENT | 4 | 4 | task-289, task-290 |
| task-301 | The close moves the test ledger and the prototype folder to the main folder | IMPLEMENT | 4 | 7 | task-297, task-298 |
| task-302 | The skill guide's lines for the seven action skills | IMPLEMENT | 4 | 7 | task-294, task-295, task-296, task-297, task-298 |
| task-303 | Conversation runner: the typed and the plain form of one sample | TEST | 5 | 2 | task-288 |
| task-304 | Writer unit cases: --kind and the reading investigation | TEST | 5 | 4 | task-291, task-292 |
| task-305 | test-actions.sh group A | TEST | 5 | 8 | task-289, task-290, task-292, task-293, task-294, task-295, task-296, task-297, task-298, task-299, task-300, task-301 |
| task-306 | Samples 009-01 to 009-04 (typed runs and 009-03, 009-04 at this gate) | TEST | 5 | 7 | task-290, task-294, task-295, task-299, task-303 |
| task-307 | Samples 009-05, 009-07, 009-13 and 009-17, and the deferred rows | TEST | 5 | 8 | task-297, task-300, task-301, task-302, task-306 |
| task-308 | test-actions.sh in the CI lane | CONFIGURE | 5 | 9 | task-305 |
| task-309 | KB schemas, glossary and contracts for the action skills and the kind catalog | DOCUMENT | 5 | 8 | task-289, task-291, task-292, task-293, task-295, task-296, task-298, task-301 |
| task-310 | KB test landscape for the action suites, the regenerated index and the view | DOCUMENT | 5 | 10 | task-303, task-304, task-305, task-307, task-308, task-309 |

That is 23 tasks (task-288 to task-310). The resync follows the run's pause at the delivery-011 MILESTONE approval
(§ 4).

---

## 2. Inputs, measurements and the rules every task carries

- **Source of truth.** The task files under `deliveries/delivery-011/tasks/` are the source of truth. The task
  blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-010's task-287.
- **Inputs read:** the delivery-011 stanza of `PLAN.md` with its Notes (Q121), Common Gate G0, "Testing before the
  resync", "Toolchain and Branching" ("How deliveries 010-014 are built", the resync rule with item 6);
  `REQUIREMENTS.md` § 11 Feature 009 in full (its build split in three by Q113 and Q121); `STATE.yml` `qa` Q104 and
  Q111-Q137.
- **Measured at base `9068ed22`** (task-288 re-measures on the tree deliveries 001-010 leave):
  - `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` are generated doorways (`GENERATED` marker, 17 lines
    each) with non-`repurpose` rows in `shortcut-catalog.yml`; `aid-document`, `aid-test` and `aid-prototype` are
    hand-authored `repurpose: true` rows (`aid-document` delegates to `aid-create-document`);
  - the catalog has 94 rows; DMR30-DMR35 of `test-deploy-monitor-repurpose.sh` assert those totals; the site's
    `groups.mjs` stops on a skill that is neither curated nor a catalog row;
  - of the suites a delivery-011 task updates, `test-deploy-monitor-repurpose.sh`,
    `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`, `test-change-refactor-family-scaffold.sh`
    and `test-work-state-template.sh` are copy-reading (their text matches the driver's pattern `P`);
    `test-doc-counts.sh`, `test-work-initiation-gate.sh`, `test-state-review-surface.sh`,
    `test-connector-consumption-linkage.sh` and `test-writeback-state.sh` are not. Criteria name no place for a
    suite that is not yet on disk: they say "where the test step puts it" (G10);
  - `tests/conversation/run.py` (Feature 001) runs one opening per sample; it has no way to run "each typed and plain
    sample twice, once with each form" (F009 § 9), nor to run one form at a gate (S3).
- **How this delivery is built: the new `/aid-execute`**, as delivery-010: the Execution protocol note is Feature
  006's template note with the task's id; `BASE` is the task's recorded `base`; the same failure after three fix
  rounds is a real blocker; the test step keeps its scratch half and live half.
- **Blocks every task carries** (G1-G13): site regeneration and the hand check of later static patterns (G3) for
  every IMPLEMENT task; the same-task rule (Q106) and the findings bullet (G9) for every non-RESEARCH task; the count
  re-sync (Q134 D5) in the two tasks that remove catalog rows; the research task's owner classes "baseline,
  re-recorded at the gate" and "rendered after the resync (gate step)", and its G2 skill owner table. No task of
  this delivery deletes, moves or renames a file, so no G6 block is needed.
- **Same-file and cross-assert order is an edge (G4, G12):** `test-work-initiation-gate.sh` (292, 293, 297, 298);
  `shortcut-catalog.yml`, the counting suites, the site roster and the doc counts (294, then 295);
  `test-idea-shaping.sh` (289, then 300); `test-writeback-state.sh` (291, then 304); `deferred.tsv` (294, 295, then
  307 through 306). The remaining `g12scan.py` hits are basename collisions between different files (`SKILL.md`,
  `check.md`, `start.md`, `reviewer-brief.md` of different skills) or a file one task only names.

---

## 3. Tasks

`Source` reads `feature-009-one-skill-per-need -> delivery-011 -> AC-...`.

### task-288: Delivery-011 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-20, AC-30.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 8. Migration`, Suites):
    - **Z1** the second, targeted search of REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration` ("Suites over the files this feature
      rewrites"), verbatim, read hit by hit: which hit asserts text that a delivery-011 rewrite changes (the action
      skills, `action-start.md`, the kind catalog, `close.md`, `cleanup-classify.sh`, `close-work.sh`);
    - **Z2** every reader and suite of `kind-catalog.yml` and its v1 fields (`test-idea-shaping.sh` ID-03 and ID-04,
      `check-intent.md`'s kind hook, `aid-brainstorm`'s `start.md`, the dashboard), with what each needs from v2;
    - **Z3** every suite, site module and document that counts `shortcut-catalog.yml` rows or doorways, or reads the
      `GENERATED` marker: `test-deploy-monitor-repurpose.sh` (DMR24, DMR30-DMR36), `test-shortcut-builder-invariants.sh`,
      `test-catalog-dirs-parity.sh`, `test-doc-counts.sh` and the phrases it asserts in `README.md` and `docs/`,
      `site/scripts/skills/` (`skill-counts.mjs`, `groups.mjs`, `curated-roster.mjs`, `catalog.mjs`),
      `site/scripts/gen-reference.mjs`, `site/scripts/lib/flow-graph/classify.mjs`, and
      `.claude/skills/generate-profile/SKILL.md`; each count with its value at the base and its value once the rows of
      `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` are gone;
    - **Z4** the writer's `--create`, `--reroute` and `--reading` options and their readers (tests, both dashboard
      readers, `dashboard/scripts/writeback-state.sh`), and the work-state template's `intent` block and `initiator`
      comment;
    - **Z5** the assertions of the six family-scaffold suites and of `test-deploy-monitor-repurpose.sh` on
      `aid-create`, `aid-update`, `aid-fix`, `aid-refactor`, `aid-document`, `aid-test` and `aid-prototype`: which
      one a delivery-011 rewrite breaks (owned here), and which waits for its file's deletion (delivery-012);
    - **Z6** `test-work-initiation-gate.sh` Group G (its starter list, `STARTER_ALLOC_ANCHOR`, `STARTER_COVERAGE_ID`,
      the GG00 count) and its reconciliation group's `aid-prototype` checks;
    - **Z7** the rows of `tests/conversation/deferred.tsv`, the SG-04 description exempt list and
      `tests/canonical/skill-steps-exempt.tsv` that name an action skill or a generated doorway, and how SS-09 covers
      each of the seven action skills at the base;
    - **Z8** the `canonical/aid/rules.md` § Skill guide lines of the seven action skills, and the `<kind>` lines
      (which stay until delivery-012);
    - **Z9** the catalog readers of REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Who reads the catalog, as they stand at the base
      (`aid-specify`, `aid-plan`, `aid-execute`, `aid-brainstorm`), each with the field AS-09 needs it to cite.
  - Give each hit exactly one owner:
    - a task of delivery-011 (task-289 to task-310; see the task files under
      `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
    - delivery-012, for a hit on a file it deletes or on the TICKET step (the wrappers, `shortcut-engine.md`,
      `shortcut-catalog.yml`, the scaffolding, `IMPEDIMENT.md`, the builder, the ticket skills);
    - delivery-013, for a hit on `aid-config`, `.aid/kinds/`, the `domain` field, or the kind hooks of
      `aid-review`, `aid-research` and `aid-report`;
    - "installed copy (resync)";
    - "history, left as is";
    - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
      site pages generated from `.aid/settings.yml` (`reference/settings.md`), which the resync could change (G8).
  - In a delta section, list each suite assigned to two independent tasks, with the order to run them.
  - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
  - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
    text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
    that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
    through the builder").
- **Acceptance criteria:**
  - [ ] Each of Z1-Z9 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-289: The kind catalog, version 2: actions, the new fields and the new kinds [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-288.
- **Source:** AC-20, AC-30.
- **Scope:**
  - `canonical/aid/templates/kind-catalog.yml` becomes `version: 2` (REQUIREMENTS.md § 11 Feature 009 `##### 3. The catalog`), block style, every
    value one line, lists inside a value as one comma-separated string:
    - an `actions` list: `create` (new capability), `update` (change), `fix` (bug fix), `refactor` (refactor),
      `document` (document), each `next: Specification`; `test` and `prototype` (investigation, `next: own`); each
      with its `about` and `rules`;
    - every kind gains `taken_by`, and the fields `ask`, `design`, `tasks`, `checks`, `tests` and `update` where
      the spec's table gives them; `shape` and `then` stay on the kinds `brainstorm` takes;
    - the new kinds, by the spec's "Taken by" table: removal, deprecation, migration; defect, regression, incident,
      vulnerability; general, decision, guideline, standard, runbook, tutorial, changelog, diagram; functional,
      security, performance, data-quality, model-evaluation, experiment;
    - the content comes from today's scaffolding files: `create.md`'s slots, conditional sections and task chains
      become `ask`, `design` and `tasks`; `change-refactor.md` becomes the `update` notes and the change kinds;
      `fix.md`, `document.md`, `prototype.md` and `test-experiment.md` become their kinds' fields.
  - Not in this task: the `ticket` kind (delivery-012, with the TICKET step), `domain` and the reserved fields
    (delivery-013). No kind that names a KB document, and not `document`, is taken by `create` or `update`.
  - Suites to update in this same task: `test-idea-shaping.sh` ID-04, which now asks `shape` and `then` only of the
    kinds `brainstorm` takes (Feature 009 § 6, the row owed to Feature 003), and any suite the findings' Z2 assigns
    here.
- **Acceptance criteria:**
  - [ ] `python3 -c "import yaml,sys; d=yaml.safe_load(open('canonical/aid/templates/kind-catalog.yml')); sys.exit(0 if d['version']==2 else 1)"` exits 0; the file holds the seven actions, each with `action`, `reading`, `about`, `next` and `rules`, and every kind of the spec's table except `ticket`.
  - [ ] A check run from this task's scratch area (the AS-03 rule ahead of its suite) finds every `kind` unique and of lowercase letters, digits and hyphens, every kind with `about` and `taken_by` naming only `brainstorm` or an existing action skill, and no KB kind and not `document` taken by `create` or `update`.
  - [ ] `test-idea-shaping.sh` passes where the test step puts it.

### task-290: The merged catalog and the kind hook in check-intent.md, and the action routing [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-288, task-289.
- **Source:** AC-30.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/check-intent.md` (REQUIREMENTS.md § 11 Feature 009 `##### 3. The catalog`, Sources, precedence and
    unknown fields, and `##### 5. Components`, Routing):
    - new § The merged catalog, stated once: in this delivery its one source is the shipped
      `.aid/runtime/templates/kind-catalog.yml` (delivery-013 adds `.aid/kinds/`); readers ignore a field they do not
      know;
    - the kind hook reads the merged catalog's actions and kinds; asked by a skill, it matches a request against the
      `about` of the kinds whose `taken_by` names that skill, and returns one kind or `--`; several kinds with
      different rules give one question with a recommendation (FR-4);
    - an action match hands the request to the action skill **before** any work is created.
  - `canonical/skills/aid-orchestrate/references/size-and-route.md`: the investigation row of the phase table (the
    investigating skill, then the close); the routing rows name the action skills.
  - Each reference stays within 120 lines.
  - Suites to update in this same task: `test-skill-guide.sh` where it reads these references, and any suite the
    findings' Z1 or Z2 assigns here.
- **Acceptance criteria:**
  - [ ] `check-intent.md` has a `## The merged catalog` section naming `kind-catalog.yml` and the shipped-first read, and its kind hook names `taken_by` and the calling skill (AS-09's catalog clauses for this part).
  - [ ] `size-and-route.md` has an investigation row naming `aid-test`, `aid-prototype` and the close; each file is at most 120 lines.

### task-291: Writer: --kind on --create and --reroute, and the reading investigation [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-288.
- **Source:** AC-30.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 009 `##### 4. Work state`, Writer), keeping Feature 002's lock,
    quoting, atomic rename and exit codes:
    - `--create ... [--kind K]` writes `intent.kind`; with no `--kind`, `--`;
    - `--reroute --reading R [--depth D] [--kind K] --why W` changes `intent.kind` only when `--kind` is given;
    - K is `--` or lowercase letters, digits and hyphens; anything else exits 4 with the file unchanged; the writer
      does not read the catalog;
    - `--reading` accepts `investigation`; every other value as before.
  - `dashboard/scripts/writeback-state.sh` (the fork) is not changed: Feature 009 § 1 names only the canonical writer.
  - The unit cases are task-304.
  - Suites to update in this same task: the existing `test-writeback-state.sh` assertions on `--create`, `--reroute`
    and the reading list, and any suite the findings' Z4 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch work, `--create ... --kind api` writes `intent.kind: api`, `--reroute --reading change --kind deprecation --why x` changes it, and `--kind 'Bad Kind'` exits 4 with the file byte-identical.
  - [ ] `--reading investigation` is accepted on `--create` and `--reroute`; `test-writeback-state.sh` passes where the test step puts it.

### task-292: Recording the kind: intent.kind in the template, and the gate's --kind [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-291.
- **Source:** AC-30.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml` (REQUIREMENTS.md § 11 Feature 009 `##### 4. Work state`): `intent.kind` with its `[W]` comment
    ("a kind from kind-catalog.yml, or --; read by every skill after the action's START"), inside Feature 001's
    `intent` block, block style (KI-002); the reading list gains `investigation`; the `initiator` comment names no
    shortcut skill.
  - `canonical/aid/templates/work-initiation-gate.md` § 3a: it takes the kind its caller passes and forwards it as
    `--create ... --kind <kind>`; with none, `--kind` is left out (the writer's `--`).
  - Both dashboard readers accept `intent.kind` and the reading `investigation` with no warning (schema only).
  - Suites to update in this same task: `test-work-state-template.sh`, `test-skill-steps.sh` SS-08,
    `test-work-initiation-gate.sh` where it asserts § 3a's `--create` line, the reader suites where they list the
    `intent` keys, and any suite the findings' Z4 assigns here.
- **Acceptance criteria:**
  - [ ] The template has `intent.kind` with its `[W]` comment and the reading `investigation`, and parses through both dashboard readers with no warning.
  - [ ] `work-initiation-gate.md` § 3a names `--kind` on its `--create` line (AS-04's gate clause); `test-work-initiation-gate.sh`, `test-work-state-template.sh` and SS-08 pass where the test step puts them.

### task-293: action-start.md: the one START of every action skill [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-289, task-290, task-292.
- **Source:** AC-30.
- **Scope:**
  - Create `canonical/aid/templates/action-start.md`, type `template-own`, at most 120 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`,
    START, steps 1-6): the words (a bare command asks "What do you want to <action>?", an intake question); the kind
    (typed first word when it names a kind that this action takes, else `check-intent.md`'s kind hook called with the
    skill's own name; several fit, one question with a recommendation; none, `--`; a typed kind is a hint, checked like
    any reading); the reading (the action's `reading`, checked by `check-intent.md`, a different checked reading said
    in one line and recorded); the work (the gate's § 3a with the words, the skill's name, step `START`, the reading,
    `--kind` and the depth from `size-and-route.md`; § 3b on continuation); next by the recorded reading (knowledge
    update, operational, investigation, a problem not clear yet, otherwise `aid-specify`), with the exact `--handoff`
    lines of the spec; a resume skips each step whose answer the record holds.
  - The ticket branch (step 4) is delivery-012's, with the TICKET step.
  - The action layer names no software term (AS-10 lands in delivery-013; write it so now): "something" or "a work
    product", never `code`, `codebase`, `repository`, `commit`, `branch` or `pull request`.
  - Suites to update in this same task: `test-work-initiation-gate.sh` Group G gains
    `canonical/aid/templates/action-start.md` under its own coverage ID (`-consults` names `work-initiation-gate.md`;
    `-create-mention` names the gate's § 3a; the § 3a line comes before its first `writeback-state.sh` line); the
    count assertions (G, GG00) take the new list's length; any suite the findings' Z6 assigns here.
- **Acceptance criteria:**
  - [ ] `action-start.md` exists, at most 120 lines, and names `--kind`, `intent.kind`, `check-intent.md`, `aid-specify`, `aid-brainstorm` and `aid-kb-update` (AS-04's `action-start.md` clause).
  - [ ] Over `action-start.md`, `grep -niwE 'code|codebase|repository|commit|branch|pull request'` prints nothing.
  - [ ] `test-work-initiation-gate.sh` passes where the test step puts it, with the new Group G entry.

### task-294: aid-create and aid-update hand-authored, and their catalog rows gone [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-293.
- **Source:** AC-20, AC-30.
- **Scope:**
  - Rewrite `canonical/skills/aid-create/SKILL.md` and `canonical/skills/aid-update/SKILL.md` by hand, each at most 80
    lines (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`, `##### 2. Flow` and `##### 5. Components`): the `GENERATED` marker goes;
    the step table has START (`action-start.md`, main conversation, `PASS` by the recorded reading); `skill-steps.md`,
    `question-protocol.md`, `action-start.md` and the catalog cited; the spec's `description:`;
    `argument-hint: "[<kind>] <what to create>"` and `"[<kind>] <what to change>"`. The TICKET row and its `CHAIN`
    come with delivery-012.
  - **Rows leave the shortcut catalog in this same task (Q121; PLAN.md delivery-011 Notes).**
    - Remove the `aid-create` and `aid-update` rows from `canonical/aid/templates/shortcut-catalog.yml`. No other row changes.
    - `python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` passes with the rows gone, and
      the builder writes no file for the two skills any more.
    - The suites that count catalog rows or doorways take the new counts here, as the findings' Z3 lists them:
      `test-deploy-monitor-repurpose.sh` DMR30-DMR35 (and DMR33's `repurpose` count where the rows carried no
      `repurpose` key), `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`,
      `test-doc-counts.sh`, and the site's `skill-counts.test.mjs`, `skills-catalog.test.mjs` and
      `skills-groups.test.mjs`.
    - The site roster: the two skills are no longer catalog rows, so `site/scripts/skills/curated-roster.mjs` and
      `groups.mjs` name them in their group (`groups.mjs` stops with "unassignable skill" otherwise); then
      the site regeneration below.
    - Any count of catalog rows that `.claude/skills/generate-profile/SKILL.md` states and a suite asserts follows.
  - **SS-09:** each skill now cites the protocol itself. When no row of `tests/conversation/deferred.tsv` covers it
    (the findings' Z7), a `skill:aid-create` or `skill:aid-update` row waits until task-306's samples (task-307
    removes it).
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
- **Acceptance criteria:**
  - [ ] Neither `SKILL.md` carries the `GENERATED` marker; each is at most 80 lines and cites `action-start.md`, `kind-catalog.yml`, `skill-steps.md` and `question-protocol.md`.
  - [ ] `build-shortcut-skills.py --check` passes with the two rows gone, and `grep -cE '^  - name: aid-(create|update)$' canonical/aid/templates/shortcut-catalog.yml` prints 0.
  - [ ] The counting suites pass where the test step puts them (DMR30-DMR35, `test-shortcut-builder-invariants.sh` and `test-catalog-dirs-parity.sh` in the scratch copy; `test-doc-counts.sh` live), and the site `npm test` passes after `sync:docs` and regeneration.

### task-295: aid-fix and aid-refactor hand-authored with the findings reference, and their catalog rows gone [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-294.
- **Source:** AC-14, AC-20, AC-30.
- **Scope:**
  - Rewrite `canonical/skills/aid-fix/SKILL.md` and `canonical/skills/aid-refactor/SKILL.md` by hand, each at most 80
    lines (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 2. Flow`): the `GENERATED` marker goes; step START only;
    the same citations as task-294; the spec's `description:`; `argument-hint: "[<kind>] <what is wrong>"` and
    `"<what to restructure>"`. `/aid-refactor` takes no kind.
  - Create `canonical/skills/aid-fix/references/findings.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`, `/aid-fix`):
    run inside START, after step 5; the ledgers in the **main folder's** `.aid/.temp/review-pending/`
    (`<work>-review.md`, `<work>-test.md`), the main folder resolved as `worktree-lifecycle.sh` does, from any
    worktree; the chosen ledger as a `sources:` entry (`kind: file`, its main-folder path); one `Findings` question
    when several rows are open, recommending every `[CRITICAL]` and `[HIGH]` row; the kind from the findings or the
    symptoms.
  - **Rows leave the shortcut catalog in this same task (Q121; PLAN.md delivery-011 Notes).**
    - Remove the `aid-fix` and `aid-refactor` rows from `canonical/aid/templates/shortcut-catalog.yml`. No other row changes.
    - `python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` passes with the rows gone, and
      the builder writes no file for the two skills any more.
    - The suites that count catalog rows or doorways take the new counts here, as the findings' Z3 lists them:
      `test-deploy-monitor-repurpose.sh` DMR30-DMR35 (and DMR33's `repurpose` count where the rows carried no
      `repurpose` key), `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`,
      `test-doc-counts.sh`, and the site's `skill-counts.test.mjs`, `skills-catalog.test.mjs` and
      `skills-groups.test.mjs`.
    - The site roster: the two skills are no longer catalog rows, so `site/scripts/skills/curated-roster.mjs` and
      `groups.mjs` name them in their group (`groups.mjs` stops with "unassignable skill" otherwise); then
      the site regeneration below.
    - Any count of catalog rows that `.claude/skills/generate-profile/SKILL.md` states and a suite asserts follows.
  - **SS-09:** as task-294, with `skill:aid-fix` and `skill:aid-refactor` rows when needed.
  - Suites to update in this same task: `test-fix-family-scaffold.sh` and `test-change-refactor-family-scaffold.sh`
    where they assert the two doorways (FFS14, CRF13e and the like; the suites themselves retire with the
    scaffolding in delivery-012); `test-connector-consumption-linkage.sh`'s `aid-fix` seam, following
    `consumption-protocol.md`'s table; any suite the findings' Z1 or Z5 assigns here.
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
- **Acceptance criteria:**
  - [ ] Neither `SKILL.md` carries the `GENERATED` marker; each is at most 80 lines; `findings.md` exists, at most 120 lines, and names the main folder and `.aid/.temp/review-pending/` (AS-06's findings half).
  - [ ] `build-shortcut-skills.py --check` passes with the two rows gone; `grep -lr GENERATED canonical/skills/aid-{create,update,fix,refactor}/SKILL.md` prints nothing.
  - [ ] The counting suites pass where the test step puts them, and the site `npm test` passes after `sync:docs` and regeneration.

### task-296: aid-document rewritten as an action skill [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-293.
- **Source:** AC-30.
- **Scope:**
  - Rewrite `canonical/skills/aid-document/SKILL.md`, at most 80 lines (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and
    `##### 2. Flow`, `/aid-document`): step START only; the citations of task-294; the spec's `description:`;
    `argument-hint: "[<kind>] <what to document, or which document to revise>"`; a new document or a revision, the
    target path named in the technical part's What changes, a `DOCUMENT` task built by `aid-tech-writer`; a fact about
    the project re-routed to `/aid-kb-update`, said in one line. It no longer delegates to `aid-create-document`.
  - Its `shortcut-catalog.yml` row stays until the catalog goes (delivery-012).
  - Suites to update in this same task: `test-document-family-scaffold.sh` where it asserts `aid-document`'s body, and
    any suite the findings' Z1 or Z5 assigns here.
- **Acceptance criteria:**
  - [ ] `aid-document/SKILL.md` is at most 80 lines, cites `action-start.md`, `kind-catalog.yml`, `skill-steps.md` and `question-protocol.md`, and names neither `aid-create-document` nor `shortcut-engine.md`.
  - [ ] The suites the findings name pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-297: aid-test rewritten as an investigation, with its references [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-293.
- **Source:** AC-14, AC-30, AC-36.
- **Scope:**
  - Rewrite `canonical/skills/aid-test/SKILL.md`, at most 100 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`, `/aid-test`): the step table
    START, RUN, CHECK, PRESENT, FINISH with the spec's references, workers and advance words; the citations of
    task-294; the spec's `description:`; `argument-hint: "[<kind>] <what to check>"`; read-only on the project.
  - Create `canonical/skills/aid-test/references/run.md`, `check.md`, `present.md`, `finish.md` and `reviewer-brief.md`,
    each at most 120 lines: RUN (what the kind names, never changing the project; the tool and command from the KB;
    raw output to `.aid/.temp/test/<work>/`; an experiment needing new code is a `/aid-create` work first); CHECK (one
    clean-context `aid-reviewer` pass, the ledger `.aid/.temp/review-pending/<work>-test.md`, the kind's `checks`, no
    grade, RUN again once for a finding with no evidence); PRESENT (chunks, the final-result approval, the `Findings`
    question); FINISH (`--handoff --to aid-monitor-pipeline --step START --returns no --phase CI --why 'test done'`,
    close mode `nothing`); the brief with `### What to report` (SS-13).
  - Suites to update in this same task (Q106): `test-work-initiation-gate.sh` Group G drops `aid-test` (with its
    `STARTER_ALLOC_ANCHOR` and `STARTER_COVERAGE_ID` entries) and gains the check that `aid-test/SKILL.md` cites
    `action-start.md` and names no `worktree-lifecycle.sh create` of its own; `test-test-experiment-family-scaffold.sh`
    where it asserts `aid-test`'s body; `test-state-review-surface.sh`, whose glob finds the new brief; any suite the
    findings' Z1, Z5 or Z6 assigns here.
- **Acceptance criteria:**
  - [ ] `SKILL.md` is at most 100 lines with the five steps; the five references exist, each at most 120 lines; `finish.md` names `aid-monitor-pipeline` and `--phase CI` (AS-05's `aid-test` clause); the brief has `### What to report`.
  - [ ] Over `canonical/skills/aid-test/`, `git grep -nE 'git (commit|push|add)|worktree-lifecycle.sh create'` finds nothing.
  - [ ] `test-work-initiation-gate.sh` and `test-state-review-surface.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-298: aid-prototype rewritten as an investigation, with its references [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-297.
- **Source:** AC-14, AC-30, AC-36.
- **Scope:**
  - Rewrite `canonical/skills/aid-prototype/SKILL.md`, at most 100 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`, `/aid-prototype`): the
    same table as `/aid-test` with BUILD in place of RUN; the citations of task-294; the spec's `description:`;
    `argument-hint: "[<kind>] <the direction to try>"`.
  - Create `canonical/skills/aid-prototype/references/build.md`, `check.md`, `present.md`, `finish.md` and
    `reviewer-brief.md`, each at most 120 lines: BUILD (`aid-architect`; a throwaway model written only under
    `.aid/.temp/prototype/<work>/`, never committed, never in the project's own files; the kind's `ask` shapes what
    the model shows); CHECK (one light `aid-reviewer` pass, no grade); PRESENT (what was learned, the final-result
    approval, the build-it question); FINISH (`PASS` to the close, mode `nothing`, which moves the folder to the main
    folder); the brief with `### What to report`.
  - Suites to update in this same task (Q106): `test-work-initiation-gate.sh` Group G drops `aid-prototype` and gains
    the check that `aid-prototype/SKILL.md` cites `action-start.md` and names no `worktree-lifecycle.sh create`; the
    reconciliation group's two `aid-prototype` checks are rewritten (`references/build.md` names `.aid/.temp/prototype/`
    as the only place the model is written; no file of the skill opens a worktree: no "opt-in git worktree" sentence,
    no `git worktree add`), its `aid-research` and `aid-review` checks unchanged; `test-prototype-family-scaffold.sh`
    where it asserts `aid-prototype`'s body; any suite the findings' Z1, Z5 or Z6 assigns here.
- **Acceptance criteria:**
  - [ ] `SKILL.md` is at most 100 lines with START, BUILD, CHECK, PRESENT and FINISH; the five references exist, each at most 120 lines; `finish.md` names `aid-monitor-pipeline` and `--phase CI`, and `build.md` names `.aid/.temp/prototype/` (AS-05's `aid-prototype` clauses).
  - [ ] Over `canonical/skills/aid-prototype/`, `git grep -nE 'git worktree add|opt-in git worktree|git (commit|push)'` finds nothing.
  - [ ] `test-work-initiation-gate.sh` passes where the test step puts it, with Group G and the rewritten reconciliation checks, and the site `npm test` passes after regeneration.

### task-299: Specification reads the kind: aid-specify's catalog fields [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-289, task-290.
- **Source:** AC-30.
- **Scope:**
  - One line each, citing the field and `check-intent.md` § The merged catalog (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Who reads the
    catalog), in `canonical/skills/aid-specify/references/`:
    - `start.md`: `intent.kind`, and the draft's `## Kind` when the work came from `/aid-brainstorm` and
      `intent.kind` is `--`;
    - `requirements.md`: the kind's `ask` (asked only when the evidence does not settle it, Q65) and the action's
      `rules`, the action being the one whose `reading` the record holds;
    - `design.md`: the kind's `design` headings, under Data and interfaces (or Migration); the `update` note when the
      reading is `change`;
    - `check.md`: the kind's `checks`.
  - A reader with no value for its field applies the action's `rules` alone. Each reference stays within its limit.
  - Suites to update in this same task: `test-specify.sh` where it asserts these references, and any suite the
    findings' Z9 assigns here.
- **Acceptance criteria:**
  - [ ] `requirements.md` names `ask`, `design.md` names `design`, `check.md` names `checks`, and each of the four names `The merged catalog` (AS-09's Specification clauses).
  - [ ] `test-specify.sh` passes where the test step puts it, and the site `npm test` passes after regeneration.

### task-300: Planning, Building and Definition read the kind [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-289, task-290.
- **Source:** AC-30.
- **Scope:**
  - One line each, citing the field and `check-intent.md` § The merged catalog (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Who reads the
    catalog):
    - `canonical/skills/aid-plan/references/breakdown.md`: the kind's `tasks`, the first the main one;
    - `canonical/skills/aid-execute/references/test.md` and `task-type-rules.md`: the kind's `tests`;
    - `canonical/skills/aid-execute/references/reviewer-brief.md`, task mode: the kind's `checks`;
    - `canonical/skills/aid-brainstorm/references/start.md`: asks the kind hook, with its own name, for the kinds whose
      `taken_by` names `brainstorm`, only to propose the draft's `## Kind`; it passes no `--kind` to the gate, and the
      work keeps `intent.kind: --`.
  - Suites to update in this same task: `test-plan.sh`, `test-execute.sh` and `test-idea-shaping.sh` where they assert
    these references, and any suite the findings' Z9 assigns here.
- **Acceptance criteria:**
  - [ ] `breakdown.md` names `tasks`, `test.md` names `tests`, the brief names `checks`, each citing `The merged catalog`; `aid-brainstorm`'s `start.md` names the kind hook with `brainstorm` and `## Kind`, and `grep -c -- '--kind' canonical/skills/aid-brainstorm/references/start.md` prints 0 (AS-09's clauses for this part).
  - [ ] `test-plan.sh`, `test-execute.sh` and `test-idea-shaping.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-301: The close moves the test ledger and the prototype folder to the main folder [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-297, task-298.
- **Source:** AC-14, AC-36.
- **Scope:**
  - REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`, the Feature 008 row, and `##### 2. Flow`, FINISH:
    - `canonical/aid/scripts/pipeline/cleanup-classify.sh --work` lists `.aid/.temp/prototype/<work>/` as one more item
      of the work;
    - `canonical/skills/aid-monitor-pipeline/references/close.md` passes `--move-to-main` for the test ledger
      (`.aid/.temp/review-pending/<work>-test.md`, already an item) and for that folder; the leftovers scan offers
      neither once moved;
    - `canonical/aid/scripts/pipeline/close-work.sh` accepts a folder for `--move-to-main` as it accepts a file.
  - Suites to update in this same task (Q106): `test-close-work.sh` (a folder moved to the main folder, then gone from the
    worktree), the `cleanup-classify.sh` suites (`--work` lists the prototype folder), `test-monitor-pipeline.sh` where
    it asserts `close.md`, and any suite the findings' Z1 assigns here.
- **Acceptance criteria:**
  - [ ] `close.md` names `<work>-test.md` and `.aid/.temp/prototype/`, and `cleanup-classify.sh --work` lists `.aid/.temp/prototype/<work>/` on a scratch work holding it (AS-05's close clauses).
  - [ ] On a scratch repository, `close-work.sh --mode nothing --move-to-main .aid/.temp/prototype/<work>` leaves the folder in the main folder; `test-close-work.sh`, the classify suites and `test-monitor-pipeline.sh` pass where the test step puts them.

### task-302: The skill guide's lines for the seven action skills [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-294, task-295, task-296, task-297, task-298.
- **Source:** AC-30.
- **Scope:**
  - `canonical/aid/rules.md` § Skill guide (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Descriptions and guide lines): one line per
    action skill, with the spec's text (`/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`,
    `/aid-test`, `/aid-prototype`). The `<kind>` lines stay until delivery-012, and `/aid-config` until delivery-013.
  - Every guide line stays within SG-03's limit; the action lines name no software term.
  - Suites to update in this same task: `test-skill-guide.sh`, and any suite the findings' Z8 assigns here.
- **Acceptance criteria:**
  - [ ] Each of the seven action skills has exactly one guide line with the spec's text, and `test-skill-guide.sh` passes where the test step puts it (the scratch copy: it is copy-reading).
  - [ ] Over those seven lines, `grep -niwE 'code|codebase|repository|commit|branch|pull request'` prints nothing.

### task-303: Conversation runner: the typed and the plain form of one sample [TEST]

- **Stanza wave:** 5. **Depends on:** task-288.
- **Source:** AC-30.
- **Scope:**
  - `tests/conversation/run.py` (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, Conversation samples: "Each typed and plain sample runs twice,
    once with each form, and its checks hold for both"):
    - a sample's `## User` may hold two openings, `typed:` and `plain:`; such a sample runs once per form, and its
      checks and judge hold for each run;
    - new option `--form typed|plain|both` (default `both`), so a gate can run one form; a sample with one opening
      ignores it;
    - each run folder names its form; the result counts each form's 3 runs on their own.
  - `tests/canonical/test-conversation-runner.sh` (Q134 D10) gains the cases, with no agent call (the runner's dry
    path).
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-303`.
- **Acceptance criteria:**
  - [ ] `test-conversation-runner.sh` passes where the test step puts it, with named cases for a two-form sample under `--form typed`, `--form plain` and `both`, and for a one-form sample.
  - [ ] `python3 tests/conversation/run.py --help` lists `--form`; the cases are deterministic and use temporary fixtures only.

### task-304: Writer unit cases: --kind and the reading investigation [TEST]

- **Stanza wave:** 5. **Depends on:** task-291, task-292.
- **Source:** AC-30.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, Unit tests): `--create --kind` and
    `--reroute --kind` write `intent.kind`; a malformed kind exits 4 with the file unchanged; `--reading investigation`
    is accepted; every file written parses through the dashboard reader with no warning.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-304`.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-305: test-actions.sh group A [TEST]

- **Stanza wave:** 5. **Depends on:** task-289, task-290, task-292, task-293, task-294, task-295, task-296, task-297, task-298, task-299, task-300, task-301.
- **Source:** AC-20, AC-30.
- **Scope:**
  - Create `tests/canonical/test-actions.sh`, a bash harness on `tests/lib/assert.sh` with `# COVERS:` lines and a group
    filter (T6), holding group A (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`; PLAN.md delivery-011 Scope):
    - AS-03 for the shipped catalog, without its `domain` and reserved-field clauses;
    - AS-04 without its `aid-deploy` / `aid-monitor` clause;
    - AS-05;
    - AS-06 for the findings half;
    - AS-09 without its `.aid/kinds/`, skip-rule and review/research/report clauses.
  - Groups B and C are added by deliveries 012 and 013 (Q113).
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-305`.
- **Acceptance criteria:**
  - [ ] `test-actions.sh` passes where the test step puts it, with a named assertion per check.
  - [ ] Each check fails its own mutation in a scratch copy: a duplicate `kind`; a kind taken by `aid-nothing`; `architecture` taken by `create`; an action skill without `action-start.md`; `finish.md` without `--phase CI`; `findings.md` without the main folder; `breakdown.md` without `tasks`; `--kind` added to `aid-brainstorm`'s `start.md`.
  - [ ] It is deterministic, reads files only, and finishes within the 300-second budget.

### task-306: Samples 009-01 to 009-04 (typed runs and 009-03, 009-04 at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-290, task-294, task-295, task-299, task-303.
- **Source:** AC-5, AC-28, AC-30.
- **Scope:**
  - Create under `tests/conversation/samples/feature-009/`, with frontmatter `skills:` the action skill, fixtures and the
    checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`: `009-01-create-api-typed-and-plain` and `009-02-deprecation-typed-and-plain`
    (each with a `typed:` and a `plain:` opening), `009-03-kind-contradicted-by-code`, `009-04-fix-from-test-findings`
    (a finished test work's ledger in the main folder's `.aid/.temp/review-pending/`).
  - Smoke run (Q134 D8): `009-03`, `009-04`, and the typed form of `009-01` and `009-02`, once each, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-306`.
- **Acceptance criteria:**
  - [ ] There are four files, each `covers` matches the spec's sample table, `009-01` and `009-02` each hold both openings, and no `## Answer sheet` names a skill.
  - [ ] Each smoke run has its result reported.

### task-307: Samples 009-05, 009-07, 009-13 and 009-17, and the deferred rows [TEST]

- **Stanza wave:** 5. **Depends on:** task-297, task-300, task-301, task-302, task-306.
- **Source:** AC-14, AC-15, AC-28, AC-30, AC-36.
- **Scope:**
  - Create `009-05-refactor-typed-and-plain`, `009-07-security-test-typed-and-plain` (each with both openings),
    `009-13-kb-kind-is-not-an-action` and `009-17-update-asks-the-kind` under `tests/conversation/samples/feature-009/`,
    with the checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`.
  - Update `tests/conversation/deferred.tsv` (Feature 009 § 8, Lists; DT-01, SS-09):
    - the temporary `skill:` rows of task-294 and task-295 go (covered by `009-01`, `009-02`, `009-04` and `009-05`);
    - `skill:aid-test` goes (covered by `009-07`, whose typed run passes at this gate);
    - one row each for `009-01`, `009-02` and `009-07`, `waiting_for` Feature 009 part b, naming the plain run (Q121;
      PLAN.md delivery-011 Notes); `009-05` runs both forms at this gate and gets no row;
    - `skill:aid-prototype` and `skill:aid-document` stay until delivery-012's samples.
  - Smoke run (Q134 D8): `009-13`, `009-17`, both forms of `009-05`, and the typed form of `009-07`, once each, in a
    scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-307`.
- **Acceptance criteria:**
  - [ ] There are four new files; DT-01 and SS-09 pass with no `skill:aid-test` row and no temporary row of task-294 or task-295 left, and the three plain-run rows (`009-01`, `009-02`, `009-07`) present.
  - [ ] Each smoke run has its result reported.

### task-308: test-actions.sh in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-305.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-actions`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's text.
- **Acceptance criteria:**
  - [ ] `test-actions` appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-309: KB schemas, glossary and contracts for the action skills and the kind catalog [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-289, task-291, task-292, task-293, task-295, task-296, task-298, task-301.
- **Source:** AC-20, AC-30.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB), for what this delivery lands:
    `artifact-schemas.md` (`intent.kind`, the reading `investigation`, `kind-catalog.yml` version 2 with `actions` and
    the kind fields); `domain-glossary.md` (action, kind, catalog, investigation); `pipeline-contracts.md` (the action
    skills' entry through `action-start.md`, and the investigation path to the close); `module-map.md` and
    `capability-inventory.md` (`action-start.md`, the seven action skills, `aid-fix`'s `findings.md`).
  - The engine, the shortcut catalog, the doorways and `decisions.md`'s new decision stay as they are until
    delivery-012 removes what they describe.
  - No retired skill: nothing joins the old -> new table (AC-24).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Each edited document names what the scope lists, and each statement matches `canonical/` as this delivery's tasks leave it.
  - [ ] No work id, and the citation and frontmatter lints pass.

### task-310: KB test landscape for the action suites, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-303, task-304, task-305, task-307, task-308, task-309.
- **Source:** AC-25, AC-30.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-actions.sh` group A and its lane; the writer's `--kind` cases; the
    runner's two forms (`--form`); the Feature 009 samples and their deferred plain runs; the counting suites as the
    catalog now stands.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync changes no
    KB document.
  - Name no work and no work folder.
  - **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
    them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
    except the resync itself.
    1. **The run pauses** at the delivery-011 MILESTONE approval question, written `Pending` with `--ask`; the main
       conversation ends the session there.
    2. **Resync session:** the resync (`delivery-011: resync`), committed alone. Then the session ends.
    3. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
       `--plan` when stale; `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated
       page (`reference/settings.md` from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB
       is not changed by this resync.
    4. **The gate:** the stanza's criteria, the samples (`009-03`, `009-04`, `009-05`, `009-13`, `009-17`, and
       `run.py --form typed` for `009-01`, `009-02` and `009-07`, each 3 of 3) and G0 on the head, G0's lane item
       carried by the milestone push. Then `/aid-execute` resumes and asks the open approval first; a yes is recorded
       with `--answer --commit <head>`, and the push question follows.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `test-actions.sh` group A, its lane and the runner's `--form`.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-create`, `aid-update`, `aid-fix`, `aid-refactor` hand-authored; their four rows leave the catalog with the counting suites (Q121); `build-shortcut-skills.py --check`; no `GENERATED` marker | 294, 295 |
| `aid-document`, `aid-test`, `aid-prototype` rewritten with their references | 296, 297, 298 |
| `action-start.md`; `kind-catalog.yml` v2; `check-intent.md` § The merged catalog (one source) | 293; 289; 290 |
| Writer `--kind` and `investigation`; the gate's `--kind`; `intent.kind` in the template | 291, 304; 292 |
| Catalog readers: `aid-specify`; `aid-plan`, `aid-execute`, `aid-brainstorm` | 299; 300 |
| `aid-fix` `findings.md`; the close moves the ledger and the prototype folder | 295; 301 |
| The skill guide's action lines (the `<kind>` lines stay) | 302 |
| `test-actions.sh` group A, in `SUITES` | 305, 308 |
| Samples `009-03`, `009-04`, `009-05`, `009-13`, `009-17`, and the typed runs of `009-01`, `009-02`, `009-07` | 303, 306, 307 |
| G0: KB documents; `INDEX.md`; `kb.html` (no AC-24 row: no skill retires) | 309, 310 |

**Steps that are not tasks** (PLAN.md, How deliveries 010-014 are built). Task-310 carries them in its
"Gate-session steps" block (G13):
1. **The run.** `/aid-execute` builds the tasks, then DELIVERY and MILESTONE's collect and corrections; the
   MILESTONE approval question is written `Pending` with `--ask`, and the run pauses there.
2. **The resync session** (resync rule 1): `delivery-011: resync`, committed alone; the session ends.
3. **The gate session** (resync rule 2): the installed `derive-waves.sh --plan --check` (with `--plan` when stale);
   `(cd site && npm run gen:reference)` and the site `npm test`, a no-op unless the resync changed
   `.aid/settings.yml`; the KB is not changed by this resync. Then the stanza's criteria, the samples (`009-03`,
   `009-04`, `009-05`, `009-13`, `009-17`, and `run.py --form typed` for `009-01`, `009-02`, `009-07`) and G0; then
   `/aid-execute` resumes with the open approval and, on a yes, the push question.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-288
wave 2: task-289, task-291, task-303
wave 3: task-290, task-292
wave 4: task-293, task-299, task-300, task-304
wave 5: task-294, task-296, task-297
wave 6: task-295, task-298
wave 7: task-301, task-302, task-306
wave 8: task-305, task-307, task-309
wave 9: task-308
wave 10: task-310
```

Step 5 writes the table under `### delivery-011 Execution Graph`, one task per row, from the task files'
`**Depends on:**` lines.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The Execution protocol note and the test step. | As delivery-010 (Feature 006's template note; the recorded `base`; a real blocker after three rounds). | Settled by recommendation (Q136); delivery-010 S1, S2. |
| S2 | How the four generated skills become hand-authored. | Two tasks, `aid-create` + `aid-update` (294) then `aid-fix` + `aid-refactor` with `findings.md` (295). Each removes its own rows and re-records the counting suites in the same task, as the stanza asks; the edge 294 -> 295 orders the shared catalog, suites, roster and doc counts. | Settled by recommendation (Q136); stanza wave 3; one session per task. |
| S3 | Running "each typed and plain sample twice", and a typed-only run at this gate. | A TEST task (303) gives `run.py` two openings per sample and `--form typed|plain|both`, with its cases in `test-conversation-runner.sh`. The gate runs `--form typed` for `009-01`, `009-02` and `009-07`. | Settled by recommendation (Q136): F009 § 9 states the two runs; PLAN gate 011 runs the typed ones alone; the harness is test infrastructure, not product scope. |
| S4 | Which Feature 009 samples this delivery writes. | Those its gate runs: `009-01` to `009-05`, `009-07`, `009-13`, `009-17`. Delivery-012 writes `009-06`, `009-08` to `009-12`, `009-14`, `009-16`; delivery-013 writes `009-15`, `009-18`, `009-19`. | Settled by recommendation (Q136); as deliveries 005-006 and 010 did. |
| S5 | The deferred list while plain runs wait. | One `deferred.tsv` row each for `009-01`, `009-02` and `009-07`, naming the plain run, `waiting_for` Feature 009 part b. `009-05` runs both forms now (PLAN gate 011), so it has none. | Settled by recommendation (Q136); DT-01 (a sample row names an existing file); Q121. |
| S6 | SS-09 coverage of the four newly hand-authored asking skills. | A temporary `skill:aid-<name>` row where no row covers the skill (294, 295), removed by 307 once the samples exist; `skill:aid-test` goes at 307 (`009-07`'s typed run); `skill:aid-prototype` and `skill:aid-document` stay for delivery-012. | Settled by recommendation (Q136); delivery-010 S5. |
| S7 | `test-work-initiation-gate.sh` Group G in this delivery. | `action-start.md` joins (293); `aid-test` and `aid-prototype` leave with their rewrites (297, 298). `shortcut-engine.md`, `aid-create-document` and `aid-update-document` leave with their deletions in delivery-012. | Settled by recommendation (Q136); F009 § 8 Re-pointed; Q106. |
| S8 | `aid-create` and `aid-update`'s TICKET step, and the `ticket` kind. | Both wait for delivery-012 (stanza Out of scope); the two skills have START only here. | PLAN delivery-011 Out of scope. |
| S9 | The rows of `aid-document`, `aid-test` and `aid-prototype` in `shortcut-catalog.yml`. | They stay until the catalog is deleted (delivery-012); only the four rows leave (Q121). | PLAN delivery-011 Scope. |
| S10 | The dashboard writer fork and `--kind`. | Not changed: F009 § 1 names only the canonical writer, and no fork caller passes a kind. | Settled by recommendation (Q136). |
| S11 | The KB in this delivery. | Schemas, glossary, contracts, module map and capability inventory for what lands here (309), and the test landscape (310). `decisions.md`'s new decision, which supersedes D20 (the engine), and the engine's removal from the KB wait for delivery-012. | Settled by recommendation (Q136): the KB states the current tree. |
| S12 | The action layer's wording. | Written with no software term from the start (293, 302); AS-10 checks it in delivery-013. | F009 § 5; avoids a second edit. |

---

## 7. Flagged for the maintainer

None. S3 adds a harness option the spec's sample rule needs but its Files and layout table does not list; it changes
no product file and no approved criterion.
