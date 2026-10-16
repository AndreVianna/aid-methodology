# Detail proposal -- delivery-013: `/aid-configure` and room beyond software (Feature 009c)

This is `aid-detail` FIRST-RUN for **delivery-013**, under Q136. Decisions are settled by recommendation, the task
files are written at once, and the light review is the check.

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-338 | Delivery-013 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-339 | aid-config renamed aid-configure: the skill, its guide line and its lists | IMPLEMENT | 2 | 2 | task-338 |
| task-340 | aid-config renamed everywhere else: settings, bin/aid and the dashboard comments | IMPLEMENT | 2 | 3 | task-339 |
| task-341 | The catalog's domain field, and the reserved fields set on none | IMPLEMENT | 2 | 2 | task-338 |
| task-342 | The action layer worded with no software term | IMPLEMENT | 2 | 4 | task-339, task-340, task-341, task-344 |
| task-343 | The identity statement outside the KB: software first, not software only | DOCUMENT | 2 | 4 | task-338, task-340 |
| task-344 | The merged catalog's second source: .aid/kinds/, the precedence and the skip rule | IMPLEMENT | 2 | 3 | task-338, task-341 |
| task-345 | Install cases: a user's .aid/kinds/ survives aid update and aid remove | TEST | 2 | 4 | task-340, task-344 |
| task-346 | Any skill may take a kind: the kind hooks of aid-review, aid-research and aid-report | IMPLEMENT | 3 | 4 | task-341, task-344 |
| task-347 | Conversation runner: a fixture with no repository | TEST | 4 | 2 | task-338 |
| task-348 | test-actions.sh group C | TEST | 4 | 5 | task-339, task-340, task-341, task-342, task-344, task-346 |
| task-349 | Samples 009-15, 009-18 and 009-19 (run at this gate) | TEST | 4 | 5 | task-339, task-340, task-342, task-344, task-346, task-347 |
| task-350 | KB: the identity decision, Beyond software, the release note and the identity lines | DOCUMENT | 4 | 5 | task-339, task-343 |
| task-351 | KB: the kind's domain, the user's kinds folder and /aid-configure | DOCUMENT | 4 | 6 | task-340, task-341, task-344, task-350 |
| task-352 | KB test landscape for domain readiness, the regenerated index and the view | DOCUMENT | 4 | 7 | task-345, task-347, task-348, task-349, task-350, task-351 |

That is 15 tasks (task-338 to task-352). The resync follows the run's pause at the delivery-013 MILESTONE approval
(§ 4).

---

## 2. Inputs, measurements and the rules every task carries

- **Source of truth.** The task files under `deliveries/delivery-013/tasks/` (after delivery-008's migration,
  `tasks/task-NNN/DETAIL.md`, G15). The task blocks in § 3 are rendered from the same data.
- **Numbering** continues from delivery-012's task-337.
- **Inputs read:** the delivery-013 stanza of `PLAN.md`; G0; "Testing before the resync"; "Toolchain and Branching";
  `REQUIREMENTS.md` § 11 Feature 009 (§ 3 The catalog, § 5 Components with Domain readiness, § 8 Migration, § 9
  Testing); `STATE.yml` `qa` Q104, Q108-Q110, Q111-Q137; the delivery-011 and delivery-012 task files.
- **Measured at base `9068ed22`** (task-338 re-measures):
  - the identity search finds `.aid/knowledge/README.md`, `architecture.md`, `capability-inventory.md`, `CLAUDE.md`,
    `README.md`, `canonical/aid/templates/kb-authoring/concern-model.md`, `domain-doc-matrix.md`,
    `packages/pypi/README.md`, `docs/aid-methodology.md` and four site pages, as the spec lists;
  - `aid-config` is named under `canonical/` (the skill, `settings.yml`, the KB-authoring and discover/housekeep
    references; several of these files are retired or rewritten by earlier deliveries), `bin/`, `dashboard/`, `tests/`,
    `site/`, `docs/` and `examples/`;
  - `test-shared-prune.sh` and `test-shared-remove.sh` are copy-reading, and the second already proves `.aid/design/`
    survives `aid remove`.
- **How this delivery is built: the new `/aid-execute`**, as deliveries 010-012.
- **Blocks every task carries:** site regeneration and G3 for IMPLEMENT tasks; the same-task rule and the findings
  bullet (G9); the research task's owner classes, its G2 table and its site-fixture search; the KB-coexistence block in
  every DOCUMENT task; G14 for `aid-configure` (task-339 moves the folder with its `SKILL.md` and roster entry); the
  site-fixture rule in the tasks that rename or rewrite a skill (339, 346).
- **Same-file order is an edge (G4, G12):** `test-actions.sh` (341 -> 344 -> 342, then 348); `rules.md` and the guide
  suite (339 -> 340 -> 342); `bin/aid` and its install suites (340 -> 345); the identity wording (343 -> 350); the KB
  (350 -> 351 -> 352). The one `g12scan.py` hit left (339 / 346) is `SKILL.md` of different skills.

---

## 3. Tasks

`Source` reads `feature-009-one-skill-per-need -> delivery-013 -> AC-...`. Domain readiness answers no criterion of
its own (F009, Criteria traceability); its tasks cite the criterion the checked behaviour serves (AC-30 for the
catalog, AC-45 for the identity statement's pre-release check).

### task-338: Delivery-013 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-22, AC-31.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Domain readiness, and `##### 8. Migration`):
    - **C1** the identity search of REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Domain readiness, item 7, verbatim:
      `git grep -lIiE 'building software|software-development lifecycle|AI Integrated Software Development|methodology for software development|kind of digital work' -- . ':!.aid/works' ':!site/src/data' ':!.aid/knowledge/kb.html' ':!.aid/runtime' ':!tests' ':!**/tests/**' ':!**/__tests__/**'`; each hit with its owner (task-343 for the files outside the KB, `docs/` and the site pages;
      task-350 for the KB; delivery-014 for `docs/` and `site/src/content/docs/`);
    - **C2** every mention of `aid-config` as a name: `git grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)' -- . ':!.aid/works'`,
      each hit classed by REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration` (the rename in approved features; Suites, Unchanged; Dashboard):
      renamed here (the skill, the settings rows, `settings.yml`, `bin/aid`, `bin/aid.ps1`, the dashboard comments,
      sample `002-02`'s `skills:` line, every kept file under `canonical/`, `.claude/skills/generate-profile/` and
      `scripts/checks/`), kept as written (the approved specs; the synthetic old-style settings fixtures in
      `test-aid-cli-parity.sh`, `test_reader.py`, `test_server_node.mjs`, `test_task012_consuming_round_trips.py`), or
      delivery-014's (`docs/`, `site/src/content/docs/`, `README.md`, `examples/`);
    - **C3** every reader of `kind-catalog.yml` and of `check-intent.md` § The merged catalog, and every suite that
      asserts the catalog's fields or the merged catalog's one-source wording;
    - **C4** how `aid update` and `aid remove` treat a user folder under `.aid/` (`bin/aid`, `bin/aid.ps1`, the
      install manifest), with the `.aid/design/` cases of `test-shared-prune.sh` and `test-shared-remove.sh`;
    - **C5** the AS-10 terms (`code`, `codebase`, `repository`, `commit`, `branch`, `pull request`, whole words, any case) over the action layer: the action skills'
      `description:` lines, their skill-guide lines, the catalog's `actions` entries and `action-start.md`;
    - **C6** the gate calls and catalog reads of `aid-review`, `aid-research` and `aid-report`, and every suite that
      asserts their `SKILL.md`;
    - **C7** the SG-04 description exempt list, `tests/conversation/deferred.tsv` and the SS-09 coverage of
      `aid-config`.
  - **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
    test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
    `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
    site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
    the task that changes that file, which re-points the test in the same task.
  - Give each hit exactly one owner:
    - a task of delivery-013 (task-339 to task-352; see the task files under
      `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
    - delivery-014, for a hit under `docs/`, `site/src/content/docs/` (outside the generated pages), `README.md`
      (outside its identity line) or `examples/`;
    - "installed copy (resync)";
    - "history, left as is";
    - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
      site pages generated from `.aid/settings.yml` (`reference/settings.md`), which this resync changes when the
      "Managed by" line reaches the installed settings (G8).
  - In a delta section, list each suite assigned to two independent tasks, with the order to run them.
  - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
  - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
    text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
    that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
    through the builder").
- **Acceptance criteria:**
  - [ ] Each of C1-C7 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-339: aid-config renamed aid-configure: the skill, its guide line and its lists [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-338.
- **Source:** AC-22, AC-31.
- **Scope:**
  - Move `canonical/skills/aid-config/` to `canonical/skills/aid-configure/` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`, Move +
    edit): `name: aid-configure`; its `description:` in the what/when shape (Feature 001; today's description,
    reworded); every mention of itself inside the skill, including the settings rows Features 004 and 008 edited (Q30,
    NFR-N).
  - **G14:** this first task that writes in `canonical/skills/aid-configure/` moves the folder with its `SKILL.md` and
    gives it its site roster entry (`site/scripts/skills/curated-roster.mjs`, `groups.mjs` and their `__tests__`), so
    the site accepts the folder at this task's end.
  - **Lists and counts that follow a renamed skill**, in this same task:
    - its `canonical/aid/rules.md` § Skill guide line: `` - `/aid-configure` -- set up or change this project's AID
      settings `` (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`);
    - the `aid-config` row of the SG-04 description exempt list in `tests/canonical/test-skill-guide.sh` goes, and the
      list ends empty (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Lists);
    - any `skill:aid-config` row of `tests/conversation/deferred.tsv` follows the new name;
    - sample `002-02`'s `skills:` line names `aid-configure` (the rename in approved features);
    - the skill count does not change; the doc phrases that name the skill are delivery-014's.
  - **Site fixtures (G11, extended).** The site tests that load a skill this task rewrites or renames as a fixture, by path
    or by name (the findings' site-fixture search), are re-pointed in this same task.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -d canonical/skills/aid-config` fails; `canonical/skills/aid-configure/SKILL.md` has `name: aid-configure` and a what/when `description:`; over the skill, `grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)'` prints nothing.
  - [ ] The SG-04 exempt list is empty, `AID_RELEASE_CHECK=1 bash tests/canonical/test-skill-guide.sh` passes SG-04 where the test step puts it, and `test-skill-guide.sh` passes there; the site `npm test` passes after regeneration.

### task-340: aid-config renamed everywhere else: settings, bin/aid and the dashboard comments [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-339.
- **Source:** AC-22, AC-31.
- **Scope:**
  - Every other mention of `aid-config` that the rename covers (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Re-pointing and the rename in
    approved features; the findings' C2):
    - `canonical/aid/templates/settings.yml`: "Managed by `/aid-configure`";
    - `bin/aid` and `bin/aid.ps1`: the "Run `/aid-config`" line names `/aid-configure`; the two lines stay
      byte-identical;
    - `dashboard/home.html` and `dashboard/reader/parsers.py`: their `aid-config` comments name `aid-configure`;
    - every other kept file under `canonical/`, `.claude/skills/generate-profile/` and `scripts/checks/` (outside
      `canonical/aid/scripts/migrate/`);
    - `test-connector-skills-structural.sh`'s comments name `aid-configure`.
  - Kept as written: the approved specs, and the synthetic old-style settings fixtures the spec lists as unchanged.
  - Suites to update in this same task: `test-aid-cli-parity.sh` and `test-settings-schema-check.sh` where they assert
    the changed lines, and any suite the findings' C2 assigns here.
- **Acceptance criteria:**
  - [ ] Over `canonical/` (except `canonical/aid/scripts/migrate/`), `.claude/skills/generate-profile/`, `scripts/checks/`, `bin/aid`, `bin/aid.ps1`, `dashboard/home.html`, `dashboard/reader/*.py`, `dashboard/server/*.mjs` and `dashboard/server/*.py`, `git grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)'` finds nothing outside `legacy-skill-names` markers (AS-02 and AS-07 for `aid-config`).
  - [ ] `test-aid-cli-parity.sh` passes in the scratch copy, the other suites the findings name pass where the test step puts them, and the site `npm test` passes after `gen:reference`.

### task-341: The catalog's domain field, and the reserved fields set on none [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-338.
- **Source:** AC-30.
- **Scope:**
  - `canonical/aid/templates/kind-catalog.yml` (REQUIREMENTS.md § 11 Feature 009 `##### 3. The catalog`; Domain readiness items 2 and 4):
    `domain: software` on every shipped kind; `risk`, `limits`, `sign_off` and `release` set on no kind; the file's
    header comment names the reserved fields and says readers ignore and keep a field they do not know.
  - No pack and no non-software kind ships (Q109).
  - Suites to update in this same task: `test-actions.sh` group A where AS-03 reads the kinds, and any suite the
    findings' C3 assigns here.
- **Acceptance criteria:**
  - [ ] A check run from this task's scratch area finds `domain: software` on every kind of `kind-catalog.yml` and none of `risk`, `limits`, `sign_off`, `release` on any kind (AS-03's domain and reserved-field clauses, ahead of group C).
  - [ ] `test-actions.sh` and `test-idea-shaping.sh` pass where the test step puts them.

### task-342: The action layer worded with no software term [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-339, task-340, task-341, task-344.
- **Source:** AC-30.
- **Scope:**
  - REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Descriptions and guide lines (Q109; AS-10): the action skills' `description:` lines,
    their skill-guide lines, the catalog's `actions` entries and `action-start.md` contain none of `code`, `codebase`, `repository`, `commit`, `branch`, `pull request` (whole
    words, any case); a kind's name in backticks is a kind, not a term of the layer. Whatever is specific to software
    lives in the software kinds.
  - Delivery-011 wrote this layer to the rule (its S12); this task rewords every hit the findings' C5 still finds, and
    changes nothing else.
  - Suites to update in this same task: `test-skill-guide.sh` and `test-actions.sh` where they assert the reworded
    lines.
- **Acceptance criteria:**
  - [ ] The AS-10 search of the findings' C5, re-run at this task's end, finds nothing.
  - [ ] `test-skill-guide.sh` and `test-actions.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-343: The identity statement outside the KB: software first, not software only [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-338, task-340.
- **Source:** AC-45.
- **Scope:**
  - In every file the identity search finds (the findings' C1) outside `.aid/knowledge/`, `docs/` and
    `site/src/content/docs/` (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Domain readiness, item 7; Q108): the root `README.md`,
    `CLAUDE.md` (its `## Project` lines, outside the AID markers), `canonical/aid/templates/kb-authoring/concern-model.md`,
    `domain-doc-matrix.md` and `packages/pypi/README.md` today -- the same statement: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet. No file says "kind of
    digital work".
  - The KB files are task-350's; `docs/` and the site pages are delivery-014's final pass; `kb.html` follows by its
    render.
  - Only the identity lines change.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `git grep -lIiE 'building software|software-development lifecycle|AI Integrated Software Development|methodology for software development|kind of digital work' -- . ':!.aid/works' ':!site/src/data' ':!.aid/knowledge/kb.html' ':!.aid/runtime' ':!tests' ':!**/tests/**' ':!**/__tests__/**'` lists, outside `.aid/knowledge/`, `docs/` and `site/src/content/docs/`, only files that contain "software first, not software only"; the same search finds "kind of digital work" in none of them.
  - [ ] `test-dogfood-byte-identity.sh` passes in the scratch copy, and the site `npm test` passes.

### task-344: The merged catalog's second source: .aid/kinds/, the precedence and the skip rule [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-338, task-341.
- **Source:** AC-30.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/check-intent.md` § The merged catalog (REQUIREMENTS.md § 11 Feature 009 `##### 3. The catalog`,
    Sources, precedence and unknown fields; Q109):
    - the second source: each `*.yml` in the project's `.aid/kinds/`, read after the shipped file, in name order, with
      the same shape (a `kinds` list; a user file adds no action);
    - `.aid/kinds/` is the user's, like `.aid/connectors/` and `.aid/design/`: not in the install manifest;
    - **additive only**: kind names are unique across every source, so a user kind never replaces a shipped one;
    - **the skip rule**: an entry with a `kind` outside the name form, a `kind` already defined, or a missing `kind`,
      `about` or `taken_by` is dropped when the catalog is read, with one notice line naming its file and entry, and is
      never matched, offered or recorded;
    - readers ignore and keep a field they do not know.
  - The section stays the one statement every other reader cites; the reference stays within 120 lines.
  - Suites to update in this same task: `test-actions.sh` group A where AS-09 reads the section's one-source wording, and
    any suite the findings' C3 assigns here.
- **Acceptance criteria:**
  - [ ] `## The merged catalog` names `.aid/kinds/`, the shipped-first name order, additive-only, and each skip case (name form, duplicate, missing field) with its notice line (AS-09's `.aid/kinds/` and skip-rule clauses, ahead of group C).
  - [ ] `check-intent.md` is at most 120 lines, and `test-actions.sh` passes where the test step puts it.

### task-345: Install cases: a user's .aid/kinds/ survives aid update and aid remove [TEST]

- **Stanza wave:** 2. **Depends on:** task-340, task-344.
- **Source:** AC-25.
- **Scope:**
  - `tests/canonical/test-shared-prune.sh` and `tests/canonical/test-shared-remove.sh` each gain a case (REQUIREMENTS.md § 11 Feature 009
    `##### 8. Migration`, Suites, Domain readiness): a file under `.aid/kinds/` is unchanged after `aid update` and after
    `aid remove`, as `.aid/design/` is.
  - The folder is outside the install manifest, so today's `bin/aid` should keep it; a failing case is a real blocker
    that names the install code, not something this task changes.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` assigns to `task-345`.
- **Acceptance criteria:**
  - [ ] Both suites pass in the scratch copy (both are copy-reading), each with the new named case.
  - [ ] Each new case fails when, in a scratch copy, the install code is changed to remove `.aid/kinds/`.

### task-346: Any skill may take a kind: the kind hooks of aid-review, aid-research and aid-report [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-341, task-344.
- **Source:** AC-30.
- **Scope:**
  - `canonical/skills/aid-review/SKILL.md`, `aid-research/SKILL.md` and `aid-report/SKILL.md` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and
    layout`; `##### 5. Components`, Routing and Who reads the catalog; Q109): each asks `check-intent.md`'s kind hook,
    with its own name, for the kinds whose `taken_by` names it; passes the result to the gate as `--kind`, before the
    gate; reads that kind's `ask` and `checks`; and cites § The merged catalog. None ships a kind for them (the
    shipped catalog has none).
  - Suites to update in this same task: `test-work-initiation-gate.sh` where it asserts these skills' gate calls, and any
    suite the findings' C6 assigns here.
  - **Site fixtures (G11, extended).** The site tests that load a skill this task rewrites or renames as a fixture, by path
    or by name (the findings' site-fixture search), are re-pointed in this same task.
- **Acceptance criteria:**
  - [ ] Each of the three `SKILL.md` files names the kind hook with its own name, `--kind` before its gate line, `ask`, `checks` and `The merged catalog` (AS-09's review/research/report clauses, ahead of group C).
  - [ ] The suites the findings name pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-347: Conversation runner: a fixture with no repository [TEST]

- **Stanza wave:** 4. **Depends on:** task-338.
- **Source:** AC-14, AC-36.
- **Scope:**
  - `tests/conversation/run.py` (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, sample `009-18`: "a folder with no git"): a sample whose
    `fixture` says it has no repository gets a fixture folder with no `git init`, with AID installed from the staged
    bundle as for any fixture; `files.diff` is taken the same way.
  - `tests/canonical/test-conversation-runner.sh` gains the case, with no agent call (the runner's dry path).
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` assigns to `task-347`.
- **Acceptance criteria:**
  - [ ] `test-conversation-runner.sh` passes where the test step puts it, with a named case showing a no-repository fixture has no `.git` and holds the installed files.
  - [ ] The case is deterministic and uses temporary fixtures only.

### task-348: test-actions.sh group C [TEST]

- **Stanza wave:** 4. **Depends on:** task-339, task-340, task-341, task-342, task-344, task-346.
- **Source:** AC-22, AC-30, AC-31.
- **Scope:**
  - `tests/canonical/test-actions.sh` gains group C (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`; PLAN.md delivery-013 Scope): AS-01's
    `aid-configure` clause; AS-02 and AS-07 for `aid-config`; AS-03's `domain`, reserved-field and user-file clauses;
    AS-09's `.aid/kinds/`, skip-rule and review/research/report clauses; AS-10. Groups A and B stay.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` assigns to `task-348`.
- **Acceptance criteria:**
  - [ ] `test-actions.sh` passes where the test step puts it, groups A, B and C, with a named assertion per check.
  - [ ] Each new check fails its own mutation in a scratch copy: `canonical/skills/aid-config/` restored; `/aid-config` in a kept reference; a shipped kind without `domain`; `risk:` on a shipped kind; `.aid/kinds/` removed from § The merged catalog; `aid-review` without `--kind`; `code` in an action skill's `description:`.

### task-349: Samples 009-15, 009-18 and 009-19 (run at this gate) [TEST]

- **Stanza wave:** 4. **Depends on:** task-339, task-340, task-342, task-344, task-346, task-347.
- **Source:** AC-8, AC-14, AC-22, AC-28, AC-30, AC-36.
- **Scope:**
  - Create under `tests/conversation/samples/feature-009/`, with fixtures and the checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`:
    `009-15-configure` (`skills: aid-configure`), `009-18-budget-sheet-no-repository` (a folder with no git, through
    task-347) and `009-19-user-kind-for-review` (`.aid/kinds/contracts.yml` with `contract-review` and the bad entry
    `Budget_Sheet`).
  - Smoke run (Q134 D8): `009-15`, `009-18`, `009-19` and `002-02` (now on `/aid-configure`), once each, in a scratch
    copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-013-sites.md` assigns to `task-349`.
- **Acceptance criteria:**
  - [ ] There are three files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill; DT-01 and SS-09 pass.
  - [ ] Each smoke run has its result reported.

### task-350: KB: the identity decision, Beyond software, the release note and the identity lines [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-339, task-343.
- **Source:** AC-24, AC-45.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB; Q108, Q110):
    - `decisions.md` gains "software first, not software only" (Q108), in the summary table and its section;
    - `roadmap.md` `## Later` gains one entry, "Beyond software" (Q110), listing in this order: the pack format and its
      sharing, with a review before install; high-stakes handling (sign-off, `full` depth forced, health and law packs
      off by default); a release close for work outside software; work that lives outside git; privacy classes; a
      checking task type; the first packs, lowest risk first; samples per pack, refusal samples included; KB rows for
      the new areas. `## Contents` stays in step with the headings;
    - `README.md`, `capability-inventory.md`, `architecture.md`: the identity statement, worded as task-343's;
    - `backlog.md` § Next Release: the `/aid-config` -> `/aid-configure` row (AC-24).
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Acceptance criteria:**
  - [ ] `roadmap.md` `## Later` has "Beyond software" with the nine items in the stated order, and `## Contents` lists it; `decisions.md` has the decision in its table and section; `backlog.md` § Next Release has the `/aid-configure` row.
  - [ ] The identity search lists the three KB files, each containing "software first, not software only"; no work id, and the citation and frontmatter lints pass.

### task-351: KB: the kind's domain, the user's kinds folder and /aid-configure [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-340, task-341, task-344, task-350.
- **Source:** AC-22, AC-30.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB): `artifact-schemas.md` (the `domain`
    field, the reserved fields, `.aid/kinds/` and the skip rule); `project-structure.md` (`.aid/kinds/`, the user's
    folder, outside the install manifest); `domain-glossary.md` (domain); `integration-map.md` (its `sources:` entry and
    the host-tool table name `aid-configure`); `coding-standards.md` (settings are "managed by `/aid-configure`").
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE '(^|[^a-z-])aid-config([^a-z-]|$)'` finds nothing, and `artifact-schemas.md` names `domain`, the four reserved fields and `.aid/kinds/`.
  - [ ] Each statement matches `canonical/` as this delivery leaves it; no work id, and the lints pass.

### task-352: KB test landscape for domain readiness, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-345, task-347, task-348, task-349, task-350, task-351.
- **Source:** AC-22, AC-30.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-actions.sh` group C; the `.aid/kinds/` cases of `test-shared-prune.sh` and
    `test-shared-remove.sh`; the runner's no-repository fixture; the samples `009-15`, `009-18`, `009-19`; the description
    exempt list now empty.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0).
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
  - **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
    them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
    except the resync itself.
    1. **The run pauses** at the delivery-013 MILESTONE approval question, written `Pending` with `--ask`; the main
       conversation ends the session there.
    2. **Resync session:** the resync (`delivery-013: resync`), committed alone. Its `aid update` removes `aid-config`
       and installs `aid-configure` through the install manifest. Then the session ends.
    3. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
       `--plan` when stale; `(cd site && npm run gen:reference)` and the site `npm test`, committing the regenerated
       `reference/settings.md` when the resync brought the "Managed by `/aid-configure`" line into `.aid/settings.yml`; the
       KB is not changed by this resync.
    4. **The gate:** the stanza's criteria (the identity search run without the release flag; the description exempt
       list empty), the samples (`009-15`, `009-18`, `009-19`, and `002-02` on `/aid-configure`, each 3 of 3) and G0 on
       the head, G0's lane item carried by the milestone push. Then `/aid-execute` resumes and asks the open approval
       first; a yes is recorded with `--answer --commit <head>`, and the push question follows.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names group C and the `.aid/kinds/` cases.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| The rename: the skill, its guide line, the SG-04 row (the list ends empty), sample `002-02` | 339 |
| The rename elsewhere: the settings rows and `settings.yml`, `bin/aid` and `bin/aid.ps1`, the dashboard comments, every kept file | 339, 340 |
| `.aid/kinds/` in § The merged catalog, the precedence, the skip rule; the install cases | 344; 345 |
| Any skill may take a kind (review, research, report) | 346 |
| `domain: software` on every kind; no reserved field set | 341 |
| The action layer with no software term (AS-10) | 342 (011 wrote it to the rule) |
| The identity statement; `decisions.md` (Q108); `roadmap.md` § Later "Beyond software" (Q110) | 343, 350 |
| Samples `009-15`, `009-18`, `009-19`; `002-02` again | 347, 349 |
| `test-actions.sh` group C | 348 |
| G0: AC-24 row; KB documents; `INDEX.md`; `kb.html` | 350; 350, 351; 352 |

**Steps that are not tasks:** task-352's "Gate-session steps" block -- the pause at the MILESTONE approval; the
resync (`aid update` removes `aid-config` and installs `aid-configure`); the gate session (`derive-waves.sh --plan
--check`; `gen:reference` and the site `npm test`, committing `reference/settings.md` when the "Managed by" line
reaches `.aid/settings.yml`; then the criteria, the samples and G0).

---

## 5. Execution graph

```text
wave 1: task-338
wave 2: task-339, task-341, task-347
wave 3: task-340, task-344
wave 4: task-342, task-343, task-345, task-346
wave 5: task-348, task-349, task-350
wave 6: task-351
wave 7: task-352
```

Step 5 writes the table under `### delivery-013 Execution Graph`, one task per row.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The protocol note and the test step. | As deliveries 010-012. | Settled by recommendation (Q136). |
| S2 | The rename in two tasks. | 339 moves the skill with its lists (G14), 340 renames every other mention; AS-02 and AS-07 for `aid-config` hold at 340's end. User documents and examples are delivery-014's. | One session per task; F009 § 8. |
| S3 | The identity statement's type and split. | DOCUMENT tasks: 343 for the files outside the KB (README, `CLAUDE.md`'s Project lines, two KB-authoring templates, the PyPI README), 350 for the three KB files with `decisions.md`; `docs/` and the site pages wait for delivery-014, as the stanza says. | Settled by recommendation (Q136); the statement is prose. |
| S4 | The `.aid/kinds/` install cases. | A TEST task (345). The folder is outside the manifest, so no install code should change; a failing case is a real blocker naming the install code. | One type per task; F009 § 8. |
| S5 | `009-18`'s fixture with no repository. | A TEST task (347) gives `run.py` a no-repository fixture, with its runner case, before the sample. | Settled by recommendation (Q136), as delivery-011's S3: test infrastructure the spec's sample needs. |
| S6 | The action-layer wording. | A task (342) that rewords only what the AS-10 search still finds; delivery-011 wrote the layer to the rule. | Stanza wave 2. |
| S7 | Sources for the domain-readiness tasks. | AC-30 for the catalog and its readers, AC-45 for the identity statement (DN-03 is its pre-release check). | F009 Criteria traceability. |
| S8 | KB `sources:` citations and retired skills' site pages (delivery-012 light review rows 1 and 8). | G17: every task that deletes, moves or renames a file fixes the KB `sources:` entries that cite it in the same task (AD14), with a criterion; the DOCUMENT tasks keep the prose. G18: every task that retires or renames a skill `git rm`s its generated page and flow before regenerating, with a criterion. The research task searches `.aid/knowledge/` `sources:` too. | G17, G18 (general rules). |
| S9 | Delivery-013 light review. | Row 1: task-339 moves `integration-map.md`'s `sources:` entry (G17). Row 2: G19 -- task-339 fixes `gen-reference.mjs`'s settings-page intro and any other site script naming `aid-config`; C2 classes them. Row 3: task-343 depends on 340 (both edit `concern-model.md`). Row 4: 351 and 352 already reach 339 through 340 and 351, so no edge. Row 5: task-343 carries the KB block for a task that edits no KB document. Row 6: task-351 owns F009 § 8's new KB bullet (every KB document naming `aid-config` as a current skill). | Light review of delivery-013; G12, G17, G19. |

---

## 7. Flagged for the maintainer

- G16 (the research task's output) stays open; task-338 is written in the form of tasks 254, 288 and 311 until it is
  decided.
